/// The fixed-form scanner for the Environment Description division.
///
/// Implements definition §1.9.3: name in columns 7–22, type 25–30,
/// options 31–71, continuation flag 72 (J 02.06.01, form facsimile).
/// The first card of a specification must carry one of the type codes
/// FILE, SPECIF, POOL, GROUP, CONTRL, OPTION, COND; a card that should
/// begin a new specification but lacks a type code is deleted with an
/// error message; a type code on a continuation card is ignored
/// (J 02.06.01.01). A period must not be used to signal the end of a
/// specification (J 02.06.02).
library;

import 'diagnostic.dart';
import 'messages.dart';
import 'source_card.dart';
import 'token.dart';

/// The legal environment type codes (J 02.06.01.01).
const Set<String> environmentTypeCodes = {
  'FILE', 'SPECIF', 'POOL', 'GROUP', 'CONTRL', 'OPTION', 'COND', //
};

/// One environment specification, assembled from its card group.
final class EnvironmentSpec {
  EnvironmentSpec._({
    required this.cards,
    required this.name,
    required this.typeText,
    required this.optionTokens,
  });

  /// The specification's cards: the first card and its continuations.
  final List<SourceCard> cards;

  /// The name, compressed from the name fields of all the
  /// specification's cards with every blank eliminated (J 02.03.01,
  /// §2.b; J 02.06.01.01 permits Name continuation); empty when
  /// unnamed. Environment names are one word only (J 02.03.03, §C).
  final String name;

  /// The type code from columns 25–30 of the first card.
  final String typeText;

  /// The option-field tokens of the whole specification: words, numbers,
  /// quoted literals, and comma separators, in source order.
  final List<Token> optionTokens;
}

/// The result of scanning an environment division's cards.
final class EnvironmentScan {
  EnvironmentScan._(this.specs, this.diagnostics);

  /// The specifications in source order. A first card without a legal
  /// type code is deleted (J 02.06.01.01) and appears here as no spec.
  final List<EnvironmentSpec> specs;

  /// The diagnostics issued during the scan.
  final List<Diagnostic> diagnostics;
}

/// Scans environment [cards] into specifications. Grouping follows the
/// continuation column exactly as in the data division: a specification
/// is complete when column 72 is blank (J 02.03.02, §3.b).
///
/// Diagnostics go to [sink] when one is given — the compilation's
/// [DiagnosticSink], whose severity-5 throw stops the scan at the point
/// of detection (D9.1) — and the scan's own
/// [EnvironmentScan.diagnostics] holds only this scan's rows either
/// way.
EnvironmentScan scanEnvironment(
  List<SourceCard> cards, [
  List<Diagnostic>? sink,
]) {
  final specs = <EnvironmentSpec>[];
  final List<Diagnostic> diagnostics = sink ?? <Diagnostic>[];
  final int first = diagnostics.length;
  for (final List<SourceCard> group in continuationGroups(cards)) {
    final EnvironmentSpec? spec = _scanSpec(group, diagnostics);
    if (spec != null) {
      specs.add(spec);
    }
  }
  return EnvironmentScan._(specs, diagnostics.sublist(first));
}

/// The options field spans columns 31–71 (J 02.06.01).
const int _optionsFirst = 31;

/// Text ends at column 71; column 72 is the continuation flag (D2.6).
const int _textLast = 71;

EnvironmentSpec? _scanSpec(
  List<SourceCard> group,
  List<Diagnostic> diagnostics,
) {
  final SourceCard first = group.first;

  void gate(SourceCard card, int from, int to) {
    for (final int column in card.unreadableColumns(from, to)) {
      diagnostics.reportAt(msgIllegalCharacterReplaced, card, column: column);
    }
  }

  // The form assigns columns 23-24 to no field (Name 7-22, Type 25-30;
  // J 02.06.01.01 and the Figure 1 facsimile), so only the two fields
  // are scanned and gated (M1-6: only scanned text is gated).
  gate(first, 7, 22);
  gate(first, 25, 30);
  final String typeText = first.internalText(25, 30).trim();
  if (!environmentTypeCodes.contains(typeText)) {
    // The card is deleted with an error message (J 02.06.01.01; J 90.04,
    // message 144,00). Its continuation cards fall with it.
    diagnostics.reportAt(msgIllegalEnvironmentType, first);
    return null;
  }

  // The name may continue onto subsequent cards, exactly as options may
  // (J 02.06.01.01: "continuation of the options (columns 31-71) or Name
  // on subsequent cards"); all imbedded and leading blanks in the name
  // fields of an entry's cards are eliminated and the non-blank
  // characters compressed to one name (J 02.03.01, §2.b — "Data and
  // Environment Names").
  final nameBuffer = StringBuffer();
  for (final card in group) {
    if (!identical(card, first)) {
      gate(card, 7, 22);
    }
    nameBuffer.write(card.internalText(7, 22).replaceAll(' ', ''));
  }
  final name = nameBuffer.toString();
  if (name.length > 30) {
    // Names may contain 1 to 30 characters (F p. 15, rule 3; J
    // 02.08.02); the compressed name can exceed one card's 16 columns.
    diagnostics.reportAt(msgNameTooLong, first, operands: [name]);
  }
  if (name.isEmpty && typeText == 'FILE') {
    diagnostics.reportAt(msgFileCardLacksName, first);
  }
  if (name.isEmpty && typeText == 'COND') {
    diagnostics.reportAt(msgCondCardLacksName, first);
  }

  // The type field belongs to the first card only; a type code on a
  // continuation card is ignored (J 02.06.01.01) and diagnosed
  // (J 90.04, message 186,00). Columns 23-24 belong to no field and
  // are not checked.
  for (final SourceCard card in group.skip(1)) {
    if ([for (var c = 25; c <= 30; c++) card.isPunched(c)].contains(true)) {
      diagnostics.reportAt(msgFixedFieldOnContinuation, card);
    }
  }

  return EnvironmentSpec._(
    cards: List.unmodifiable(group),
    name: name,
    typeText: typeText,
    optionTokens: _scanOptions(group, diagnostics),
  );
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

bool _isLetter(String c) => c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x5A;

/// Scans the option fields of a specification's cards. Options are
/// separated by commas (J 02.06 samples); blanks separate words inside
/// an option (`BLOCKSIZE 300`); quoted literals carry unit and key
/// settings. A literal left open at a card's end draws 167,00 — the
/// data division's cross-card constant leniency is not extended here
/// (a recorded M1 design decision; D1.1 attests it for the Data
/// Description only).
List<Token> _scanOptions(List<SourceCard> group, List<Diagnostic> diagnostics) {
  final tokens = <Token>[];
  final run = StringBuffer();
  SourceCard? runCard;
  var runColumn = 0;

  void endRun() {
    if (run.isEmpty) {
      return;
    }
    final text = run.toString();
    final TokenKind kind;
    if (text.split('').every(_isDigit)) {
      kind = TokenKind.numericLiteral;
    } else if (_isLetter(text[0])) {
      kind = TokenKind.word;
    } else {
      kind = TokenKind.descriptionItem;
    }
    tokens.add(Token(kind, text, runCard!, runColumn));
    run.clear();
  }

  for (final card in group) {
    int column = _optionsFirst;
    while (column <= _textLast) {
      if (!card.isPunched(column)) {
        endRun();
        column++;
        continue;
      }
      final String? glyph = card.glyphAt(column);
      if (glyph == null) {
        diagnostics.reportAt(msgIllegalCharacterReplaced, card, column: column);
        if (run.isEmpty) {
          runCard = card;
          runColumn = column;
        }
        run.write('0');
        column++;
        continue;
      }
      if (glyph == ',') {
        endRun();
        tokens.add(Token(TokenKind.symbol, ',', card, column));
        column++;
        continue;
      }
      if (glyph == "'") {
        endRun();
        column = _scanLiteral(card, column, tokens, diagnostics);
        continue;
      }
      if (run.isEmpty) {
        runCard = card;
        runColumn = column;
      }
      run.write(glyph);
      column++;
    }
    endRun(); // A blank is assumed at each card's end.
  }
  return tokens;
}

int _scanLiteral(
  SourceCard card,
  int openColumn,
  List<Token> tokens,
  List<Diagnostic> diagnostics,
) {
  final buffer = StringBuffer();
  int column = openColumn + 1;
  var closed = false;
  while (column <= _textLast) {
    if (!card.isPunched(column)) {
      buffer.write(' ');
      column++;
      continue;
    }
    if (card.bcdAt(column) == null) {
      diagnostics.reportAt(msgIllegalCharacterReplaced, card, column: column);
      buffer.write('0');
      column++;
      continue;
    }
    final String? glyph = card.glyphAt(column);
    if (glyph == "'") {
      closed = true;
      column++;
      break;
    }
    buffer.write(glyph ?? '?');
    column++;
  }
  if (!closed) {
    diagnostics.reportAt(msgSecondQuoteMissing, card, column: openColumn);
  }
  final String text = closed
      ? buffer.toString()
      : buffer.toString().trimRight();
  tokens.add(Token(TokenKind.alphamericLiteral, text, card, openColumn));
  return column;
}
