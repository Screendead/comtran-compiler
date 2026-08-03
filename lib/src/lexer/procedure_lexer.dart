/// The free-form scanner for the Procedure division.
///
/// Implements definition §1.9.1 (the procedure form), §1.9.4 (statement
/// termination and commentary), §1.3 (word formation), §1.7 (literals),
/// and §1.8.2 (punctuation and spacing). The scanner works card by card:
/// each word or literal must be complete upon a line, "since the processor
/// assumes a blank following column 72 of Procedure lines" (J 02.03.01,
/// §2.c); continuation is implicit — "no continuation character is used"
/// (J 02.03.01, §2.a). Procedure text reads through column 72 (decision
/// D2.6).
///
/// The character gate of decision D9.10 runs here: an illegal column is
/// diagnosed with message 134 once, reads as the digit zero in the
/// internal text the scanner consumes, and reads as the dollar sign in
/// the external listing text. Inside an alphameric literal any column
/// with a defined BCD read-out except the quote is legal (D9.10 layer c).
/// Commentary after the terminating period is not scanned and is not
/// gated — a recorded M1 design decision.
library;

import 'diagnostic.dart';
import 'messages.dart';
import 'source_card.dart';
import 'token.dart';

/// One procedure sentence: an optional margin name and the tokens up to
/// (not including) the terminating period.
final class ProcedureSentence {
  ProcedureSentence._({
    required this.label,
    required this.labelColumn,
    required this.labelHadPeriod,
    required this.tokens,
    required this.terminated,
    required this.cards,
  });

  /// The procedure-name written in the name margin, or `null` for an
  /// unnamed sentence.
  final String? label;

  /// The 1-based column the label starts at, when there is one.
  final int? labelColumn;

  /// Whether the label carried its terminating period (F p. 37 requires
  /// it; its absence is accepted silently, J 90.01.03, A.1.a.ix — the
  /// repair is recorded here so `--pedantic` can warn, decision D9.4).
  final bool labelHadPeriod;

  /// The sentence body tokens in source order.
  final List<Token> tokens;

  /// Whether the sentence ended with a period followed by a blank (or a
  /// period in column 72). `false` means message 62,00 was issued and a
  /// period was assumed.
  final bool terminated;

  /// The cards the sentence occupies, in deck order.
  final List<SourceCard> cards;
}

/// The result of scanning a procedure division's cards.
final class ProcedureScan {
  ProcedureScan._(this.sentences, this.diagnostics);

  /// The sentences in source order.
  final List<ProcedureSentence> sentences;

  /// The diagnostics issued during the scan.
  final List<Diagnostic> diagnostics;
}

/// Scans procedure [cards] into sentences.
///
/// Diagnostics go to [sink] when one is given — the compilation's
/// [DiagnosticSink], whose severity-5 throw stops the scan at the point
/// of detection (D9.1) — and the scan's own
/// [ProcedureScan.diagnostics] holds only this scan's rows either way.
ProcedureScan scanProcedure(List<SourceCard> cards, [List<Diagnostic>? sink]) =>
    _ProcedureScanner(cards, sink ?? <Diagnostic>[]).scan();

/// The leftmost body column (the start of the name margin).
const int _marginFirst = 7;

/// The last column of the name margin (F p. 37).
const int _marginLast = 12;

/// Procedure text reads through column 72 (decision D2.6).
const int _textLast = 72;

bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

bool _isLetter(String c) => c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x5A;

bool _isWordChar(String c) => _isLetter(c) || _isDigit(c);

final class _ProcedureScanner {
  _ProcedureScanner(this.cards, this.diagnostics)
    : _firstDiagnostic = diagnostics.length;

  final List<SourceCard> cards;

  final List<ProcedureSentence> sentences = [];
  final List<Diagnostic> diagnostics;
  final int _firstDiagnostic;

  // The open sentence, if any.
  bool _open = false;
  String? _label;
  int? _labelColumn;
  bool _labelHadPeriod = false;
  List<Token> _tokens = [];
  List<SourceCard> _sentenceCards = [];
  bool _inNote = false;

  // Per-card scan state.
  late SourceCard _card;
  late String _body;
  late Set<int> _illegal;

  ProcedureScan scan() {
    for (final SourceCard card in cards) {
      _scanCard(card);
    }
    if (_open) {
      // The division ended with the sentence still open (D9.4: the next
      // card is a header, control card, or end of deck). Report against
      // the sentence's own last card.
      diagnostics.add(
        Diagnostic(
          msgPeriodAssumed,
          _sentenceCards.isNotEmpty ? _sentenceCards.last : cards.last,
        ),
      );
      _close(terminated: false);
    }
    return ProcedureScan._(sentences, diagnostics.sublist(_firstDiagnostic));
  }

  void _scanCard(SourceCard card) {
    _card = card;
    _body = card.internalText(_marginFirst, _textLast);
    _illegal = card.unreadableColumns(_marginFirst, _textLast).toSet();
    var i = 0;
    while (i < _body.length && _body[i] == ' ') {
      i++;
    }
    if (i == _body.length) {
      return; // Nothing punched in the body.
    }
    // The margin trigger needs a name — a letter-initial word in the
    // name margin (D9.4: the next card "carries a name in the name
    // margin"). Other margin content continues an open sentence.
    final bool marginName =
        i + _marginFirst <= _marginLast && _isLetter(_body[i]);
    if (_open && marginName) {
      // A new statement begins while the previous sentence is open
      // (D9.4 trigger; J 90.04, message 62,00).
      diagnostics.add(Diagnostic(msgPeriodAssumed, card));
      _close(terminated: false);
    }
    if (!_open) {
      _open = true;
      _sentenceCards = [card];
      _tokens = [];
      if (marginName) {
        i = _scanLabel(i);
      }
    } else {
      _sentenceCards.add(card);
    }
    _scanTokens(i);
  }

  /// Issues message 134 for each illegal column consumed in
  /// [fromIndex]..[toIndex) outside a literal (decision D9.10).
  void _gate(int fromIndex, int toIndex) {
    for (var i = fromIndex; i < toIndex; i++) {
      final int column = i + _marginFirst;
      if (_illegal.remove(column)) {
        diagnostics.add(
          Diagnostic(msgIllegalCharacterReplaced, _card, column: column),
        );
      }
    }
  }

  /// Scans the margin procedure-name and its period (F p. 37; the period
  /// and blank are required by F but their absence is accepted without a
  /// diagnostic, J 90.01.03, A.1.a.ix; decisions D1.3, D9.4).
  int _scanLabel(int start) {
    final int end = _wordEnd(start);
    _gate(start, end);
    _label = _body.substring(start, end);
    _labelColumn = start + _marginFirst;
    _checkNameLength(_label!, _labelColumn!);
    if (end < _body.length && _body[end] == '.') {
      _labelHadPeriod = true;
      return end + 1;
    }
    _labelHadPeriod = false;
    return end;
  }

  void _scanTokens(int start) {
    var i = start;
    while (i < _body.length) {
      final String c = _body[i];
      if (c == ' ') {
        i++;
        continue;
      }
      if (_inNote) {
        i = _scanNoteText(i);
        continue;
      }
      if (c == '.') {
        if (i == _body.length - 1 || _body[i + 1] == ' ') {
          // The sentence terminator: a period followed by a blank, the
          // blank assumed after column 72 (F pp. 27-28, rules 3 and 14). The
          // card remainder is commentary (J 02.03.01, §3.a) and is not
          // scanned.
          _close(terminated: true);
          return;
        }
        if (_isDigit(_body[i + 1])) {
          i = _scanNumber(i);
          continue;
        }
        diagnostics.add(
          Diagnostic(msgStrayPeriod, _card, column: i + _marginFirst),
        );
        i++;
        continue;
      }
      if (c == "'") {
        i = _scanLiteral(i);
        continue;
      }
      if (_isDigit(c)) {
        i = _scanNumber(i);
        continue;
      }
      if (_isLetter(c)) {
        final int end = _wordEnd(i);
        _gate(i, end);
        final String word = _body.substring(i, end);
        _checkNameLength(word, i + _marginFirst);
        _tokens.add(Token(TokenKind.word, word, _card, i + _marginFirst));
        if (_tokens.length == 1 && word == 'NOTE') {
          // NOTE bodies may contain any characters and end at the first
          // period followed by a blank (F p. 59).
          _inNote = true;
        }
        i = end;
        continue;
      }
      if (c == '*' && i + 1 < _body.length && _body[i + 1] == '*') {
        _tokens.add(Token(TokenKind.symbol, '**', _card, i + _marginFirst));
        i += 2;
        continue;
      }
      // The dollar sign is a source character with no role in procedure
      // text; it is passed through as a symbol for the parser to judge.
      if (r'+-*/=(),$'.contains(c)) {
        _tokens.add(Token(TokenKind.symbol, c, _card, i + _marginFirst));
        i++;
        continue;
      }
      // Unreachable: every Set H character is handled above, and illegal
      // columns read as the digit zero.
      throw StateError(
        'unhandled character "$c" at column '
        '${i + _marginFirst} of card ${_card.cardNumber}',
      );
    }
  }

  /// Scans NOTE free text on one card, ending the sentence at the first
  /// period followed by a blank (F p. 59).
  int _scanNoteText(int start) {
    for (var i = start; i < _body.length; i++) {
      if (_body[i] == '.' && (i == _body.length - 1 || _body[i + 1] == ' ')) {
        _gate(start, i);
        final String text = _body.substring(start, i).trimRight();
        if (text.isNotEmpty) {
          _tokens.add(
            Token(TokenKind.noteText, text, _card, start + _marginFirst),
          );
        }
        _close(terminated: true);
        return _body.length;
      }
    }
    _gate(start, _body.length);
    final String text = _body.substring(start).trimRight();
    if (text.isNotEmpty) {
      _tokens.add(Token(TokenKind.noteText, text, _card, start + _marginFirst));
    }
    return _body.length;
  }

  /// Scans an alphameric literal by columns, because a machine special
  /// inside a literal is legal and carries its BCD value (D9.10 layer c;
  /// D8.1). Such a column renders as `?` in the token text — a recorded
  /// M1 placeholder choice; the data mapper re-reads values from the
  /// card at M3.
  int _scanLiteral(int startIndex) {
    final int openColumn = startIndex + _marginFirst;
    final buffer = StringBuffer();
    int column = openColumn + 1;
    var closed = false;
    while (column <= _textLast) {
      if (!_card.isPunched(column)) {
        buffer.write(' ');
        column++;
        continue;
      }
      if (_card.bcdAt(column) == null) {
        // No read-out: illegal even inside a literal (D9.10 layer a).
        _illegal.remove(column);
        diagnostics.add(
          Diagnostic(msgIllegalCharacterReplaced, _card, column: column),
        );
        buffer.write('0');
        column++;
        continue;
      }
      final String? glyph = _card.glyphAt(column);
      if (glyph == "'") {
        closed = true;
        column++;
        break;
      }
      buffer.write(glyph ?? '?');
      column++;
    }
    if (!closed) {
      // Unclosed on its card: in procedure text the literal would extend
      // across cards (decision D1.1; J 90.04, message 168,00).
      diagnostics.add(
        Diagnostic(msgLiteralAcrossCards, _card, column: openColumn),
      );
    }
    final String text = closed
        ? buffer.toString()
        : buffer.toString().trimRight();
    if (text.length > 50) {
      diagnostics.add(Diagnostic(msgLiteralTooLong, _card, column: openColumn));
    }
    _tokens.add(Token(TokenKind.alphamericLiteral, text, _card, openColumn));
    return column - _marginFirst;
  }

  /// Scans a numeric or floating point literal (F p. 18; J 02.04.02).
  int _scanNumber(int start) {
    var i = start;
    var points = 0;
    while (i < _body.length) {
      final String c = _body[i];
      if (_isDigit(c)) {
        i++;
      } else if (c == '.' &&
          i + 1 < _body.length &&
          (_isDigit(_body[i + 1]) || _body[i + 1] == 'F')) {
        // A decimal point, absorbed when it cannot be the sentence
        // terminator (F p. 27, rule 4; J 02.04.02 requires the point
        // before the F of a floating literal).
        points++;
        i++;
      } else {
        break;
      }
    }
    final fractionEnd = i;
    TokenKind kind = TokenKind.numericLiteral;
    if (points > 0 && i < _body.length && _body[i] == 'F') {
      // A floating point literal needs the decimal point in its fraction:
      // 20.F+01 is floating, 20F+01 is an arithmetic expression
      // (J 02.04.02, rules a-d). FF signals double precision.
      int j = i + 1;
      if (j < _body.length && _body[j] == 'F') {
        j++;
      }
      if (j < _body.length && (_body[j] == '+' || _body[j] == '-')) {
        j++;
      }
      final exponentStart = j;
      while (j < _body.length && _isDigit(_body[j])) {
        j++;
      }
      if (j > exponentStart) {
        kind = TokenKind.floatingLiteral;
        i = j;
      } else {
        // The F is not followed by a digit (J 02.04.02, rule c).
        diagnostics.add(
          Diagnostic(msgIncorrectNumericForm, _card, column: i + _marginFirst),
        );
        i = fractionEnd;
      }
    }
    _gate(start, i);
    final String text = _body.substring(start, i);
    if (points > 1) {
      // Not more than one decimal point, for floating literals too
      // (F p. 18, rules 2 and 8; J 02.04.02 has a single fraction).
      diagnostics.add(
        Diagnostic(
          msgIncorrectNumericForm,
          _card,
          column: start + _marginFirst,
        ),
      );
    }
    if (text.split('').where(_isDigit).length > 50) {
      // All literals are limited to 50 characters (F p. 18, rule 1); the
      // decimal point and the F occupy no storage and are not counted
      // (F p. 18, rules 2 and 4), and the exponent sign is excluded by
      // decision (D10.3). The choice of message 52 for the over-50
      // numeric case is a recorded design decision (D1.2).
      diagnostics.add(
        Diagnostic(
          msgNumericLengthExceeded,
          _card,
          column: start + _marginFirst,
        ),
      );
    }
    _tokens.add(Token(kind, text, _card, start + _marginFirst));
    return i;
  }

  /// The end of a word run from [start]: letters, digits, and periods
  /// that connect word characters (F p. 27, rules 1 and 4).
  int _wordEnd(int start) {
    var i = start;
    while (i < _body.length) {
      final String c = _body[i];
      if (_isWordChar(c)) {
        i++;
      } else if (c == '.' &&
          i + 1 < _body.length &&
          _isWordChar(_body[i + 1])) {
        i++;
      } else {
        break;
      }
    }
    return i;
  }

  /// Names may contain from 1 to 30 characters (F p. 15, rule 3).
  void _checkNameLength(String word, int column) {
    if (word.length > 30) {
      diagnostics.add(
        Diagnostic(msgNameTooLong, _card, column: column, operands: [word]),
      );
    }
  }

  void _close({required bool terminated}) {
    if (_label != null || _tokens.isNotEmpty) {
      sentences.add(
        ProcedureSentence._(
          label: _label,
          labelColumn: _labelColumn,
          labelHadPeriod: _labelHadPeriod,
          tokens: List.unmodifiable(_tokens),
          terminated: terminated,
          cards: List.unmodifiable(_sentenceCards),
        ),
      );
    }
    _open = false;
    _label = null;
    _labelColumn = null;
    _labelHadPeriod = false;
    _tokens = [];
    _sentenceCards = [];
    _inNote = false;
  }
}
