/// The free-form scanner for the Procedure division.
///
/// Implements definition §1.9.1 (the procedure form), §1.9.4 (statement
/// termination and commentary), §1.3 (word formation), §1.7 (literals),
/// and §1.8.2 (punctuation and spacing). The scanner works card by card:
/// each word or literal must be complete upon a line, "since the processor
/// assumes a blank following column 72 of Procedure lines" (J 02.03.01,
/// §2.c); continuation is implicit — "no continuation character is used"
/// (J 02.03.01, §2.a).
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
    required this.tokens,
    required this.terminated,
    required this.cards,
  });

  /// The procedure-name written in the name margin, or `null` for an
  /// unnamed sentence.
  final String? label;

  /// The 1-based column the label starts at, when there is one.
  final int? labelColumn;

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
ProcedureScan scanProcedure(List<SourceCard> cards) =>
    _ProcedureScanner(cards).scan();

/// The leftmost body column (the start of the name margin).
const int _marginFirst = 7;

/// The last column of the name margin (F p. 37).
const int _marginLast = 12;

bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

bool _isLetter(String c) => c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x5A;

bool _isWordChar(String c) => _isLetter(c) || _isDigit(c);

final class _ProcedureScanner {
  _ProcedureScanner(this.cards);

  final List<SourceCard> cards;

  final List<ProcedureSentence> sentences = [];
  final List<Diagnostic> diagnostics = [];

  // The open sentence, if any.
  bool _open = false;
  String? _label;
  int? _labelColumn;
  List<Token> _tokens = [];
  List<SourceCard> _sentenceCards = [];
  bool _inNote = false;

  ProcedureScan scan() {
    for (final SourceCard card in cards) {
      _scanCard(card);
    }
    if (_open) {
      // The division ended with the sentence still open.
      diagnostics.add(Diagnostic(msgPeriodAssumed, cards.last));
      _close(terminated: false);
    }
    return ProcedureScan._(sentences, diagnostics);
  }

  void _scanCard(SourceCard card) {
    for (final int column in card.unreadableColumns(_marginFirst, 72)) {
      diagnostics.add(Diagnostic(msgUnreadableColumn, card, column: column));
    }
    final String body = card.textRange(_marginFirst, 72);
    var i = 0;
    while (i < body.length && body[i] == ' ') {
      i++;
    }
    if (i == body.length) {
      return; // Nothing punched in the body.
    }
    final bool inMargin = i + _marginFirst <= _marginLast;
    if (_open && inMargin) {
      // A new statement begins while the previous sentence is open
      // (J 90.04, message 62,00).
      diagnostics.add(Diagnostic(msgPeriodAssumed, card));
      _close(terminated: false);
    }
    if (!_open) {
      _open = true;
      _sentenceCards = [card];
      _tokens = [];
      if (inMargin && _isLetter(body[i])) {
        i = _scanLabel(card, body, i);
      }
    } else {
      _sentenceCards.add(card);
    }
    _scanTokens(card, body, i);
  }

  /// Scans the margin procedure-name and its period (F p. 37; the period
  /// and blank are required by F but their absence is accepted without a
  /// diagnostic, J 90.01.03, A.1.a.ix).
  int _scanLabel(SourceCard card, String body, int start) {
    final int end = _wordEnd(body, start);
    _label = body.substring(start, end);
    _labelColumn = start + _marginFirst;
    _checkNameLength(_label!, card, _labelColumn!);
    if (end < body.length && body[end] == '.') {
      return end + 1;
    }
    return end;
  }

  void _scanTokens(SourceCard card, String body, int start) {
    var i = start;
    while (i < body.length) {
      final String c = body[i];
      if (c == ' ') {
        i++;
        continue;
      }
      if (_inNote) {
        i = _scanNoteText(card, body, i);
        continue;
      }
      if (c == '.') {
        if (i == body.length - 1 || body[i + 1] == ' ') {
          // The sentence terminator: a period followed by a blank, the
          // blank assumed after column 72 (F p. 28, rules 3 and 14). The
          // card remainder is commentary (J 02.03.01, §3.a).
          _close(terminated: true);
          return;
        }
        if (_isDigit(body[i + 1])) {
          i = _scanNumber(card, body, i);
          continue;
        }
        diagnostics.add(
          Diagnostic(msgStrayPeriod, card, column: i + _marginFirst),
        );
        i++;
        continue;
      }
      if (c == "'") {
        i = _scanLiteral(card, body, i);
        continue;
      }
      if (_isDigit(c)) {
        i = _scanNumber(card, body, i);
        continue;
      }
      if (_isLetter(c)) {
        final int end = _wordEnd(body, i);
        final String word = body.substring(i, end);
        _checkNameLength(word, card, i + _marginFirst);
        _tokens.add(Token(TokenKind.word, word, card, i + _marginFirst));
        if (_tokens.length == 1 && word == 'NOTE') {
          // NOTE bodies may contain any characters and end at the first
          // period followed by a blank (F p. 59).
          _inNote = true;
        }
        i = end;
        continue;
      }
      if (c == '*' && i + 1 < body.length && body[i + 1] == '*') {
        _tokens.add(Token(TokenKind.symbol, '**', card, i + _marginFirst));
        i += 2;
        continue;
      }
      if ('+-*/=(),'.contains(c)) {
        _tokens.add(Token(TokenKind.symbol, c, card, i + _marginFirst));
        i++;
        continue;
      }
      diagnostics.add(
        Diagnostic(
          msgIllegalCharacter,
          card,
          column: i + _marginFirst,
          operands: [c],
        ),
      );
      i++;
    }
  }

  /// Scans NOTE free text on one card, ending the sentence at the first
  /// period followed by a blank (F p. 59).
  int _scanNoteText(SourceCard card, String body, int start) {
    for (var i = start; i < body.length; i++) {
      if (body[i] == '.' && (i == body.length - 1 || body[i + 1] == ' ')) {
        final String text = body.substring(start, i).trimRight();
        if (text.isNotEmpty) {
          _tokens.add(
            Token(TokenKind.noteText, text, card, start + _marginFirst),
          );
        }
        _close(terminated: true);
        return body.length;
      }
    }
    final String text = body.substring(start).trimRight();
    if (text.isNotEmpty) {
      _tokens.add(Token(TokenKind.noteText, text, card, start + _marginFirst));
    }
    return body.length;
  }

  /// Scans an alphameric literal, which must close on its card
  /// (J 02.04.02.01; J 90.04, messages 150,00 and 168,00).
  int _scanLiteral(SourceCard card, String body, int start) {
    final int close = body.indexOf("'", start + 1);
    final String text;
    int next;
    if (close < 0) {
      text = body.substring(start + 1);
      next = body.length;
      diagnostics.add(
        Diagnostic(msgLiteralAcrossCards, card, column: start + _marginFirst),
      );
    } else {
      text = body.substring(start + 1, close);
      next = close + 1;
    }
    if (text.length > 50) {
      diagnostics.add(
        Diagnostic(msgLiteralTooLong, card, column: start + _marginFirst),
      );
    }
    _tokens.add(
      Token(TokenKind.alphamericLiteral, text, card, start + _marginFirst),
    );
    return next;
  }

  /// Scans a numeric or floating point literal (F p. 18; J 02.04.02).
  int _scanNumber(SourceCard card, String body, int start) {
    var i = start;
    var points = 0;
    while (i < body.length) {
      final String c = body[i];
      if (_isDigit(c)) {
        i++;
      } else if (c == '.' &&
          i + 1 < body.length &&
          (_isDigit(body[i + 1]) || body[i + 1] == 'F')) {
        // A decimal point, absorbed when it cannot be the sentence
        // terminator (F p. 28, rule 4; J 02.04.02 requires the point
        // before the F of a floating literal).
        points++;
        i++;
      } else {
        break;
      }
    }
    final int fractionEnd = i;
    var kind = TokenKind.numericLiteral;
    if (points > 0 && i < body.length && body[i] == 'F') {
      // A floating point literal needs the decimal point in its fraction:
      // 20.F+01 is floating, 20F+01 is an arithmetic expression
      // (J 02.04.02, rules a-d). FF signals double precision.
      var j = i + 1;
      if (j < body.length && body[j] == 'F') {
        j++;
      }
      if (j < body.length && (body[j] == '+' || body[j] == '-')) {
        j++;
      }
      final int exponentStart = j;
      while (j < body.length && _isDigit(body[j])) {
        j++;
      }
      if (j > exponentStart) {
        kind = TokenKind.floatingLiteral;
        i = j;
      } else {
        // The F is not followed by a digit (J 02.04.02, rule c).
        diagnostics.add(
          Diagnostic(msgIncorrectNumericForm, card, column: i + _marginFirst),
        );
        i = fractionEnd;
      }
    }
    final String text = body.substring(start, i);
    if (kind == TokenKind.numericLiteral && points > 1) {
      diagnostics.add(
        Diagnostic(msgIncorrectNumericForm, card, column: start + _marginFirst),
      );
    }
    if (text.length > 50) {
      // All literals are limited to 50 characters (F p. 18, rule 1); the
      // 52,00 limit value is unstated (Ambiguity A2) and 50 is ours.
      diagnostics.add(
        Diagnostic(
          msgNumericLengthExceeded,
          card,
          column: start + _marginFirst,
        ),
      );
    }
    _tokens.add(Token(kind, text, card, start + _marginFirst));
    return i;
  }

  /// The end of a word run from [start]: letters, digits, and periods
  /// that connect word characters (F p. 27, rules 1 and 4).
  int _wordEnd(String body, int start) {
    var i = start;
    while (i < body.length) {
      final String c = body[i];
      if (_isWordChar(c)) {
        i++;
      } else if (c == '.' && i + 1 < body.length && _isWordChar(body[i + 1])) {
        i++;
      } else {
        break;
      }
    }
    return i;
  }

  /// Names may contain from 1 to 30 characters (F p. 15, rule 3).
  void _checkNameLength(String word, SourceCard card, int column) {
    if (word.length > 30) {
      diagnostics.add(
        Diagnostic(msgNameTooLong, card, column: column, operands: [word]),
      );
    }
  }

  void _close({required bool terminated}) {
    if (_label != null || _tokens.isNotEmpty) {
      sentences.add(
        ProcedureSentence._(
          label: _label,
          labelColumn: _labelColumn,
          tokens: List.unmodifiable(_tokens),
          terminated: terminated,
          cards: List.unmodifiable(_sentenceCards),
        ),
      );
    }
    _open = false;
    _label = null;
    _labelColumn = null;
    _tokens = [];
    _sentenceCards = [];
    _inNote = false;
  }
}
