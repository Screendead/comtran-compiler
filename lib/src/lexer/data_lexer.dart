/// The fixed-form scanner for the Data Description division.
///
/// Implements definition §1.9.2: name in columns 7–22, level 23–24, type
/// 25–30, quantity 31–35, mode 36, justification 37, description 38–71,
/// continuation flag 72 (F p. 65). Text is read through column 71 only;
/// column 72 is the continuation flag and is blanked before scanning
/// (decision D2.6; J 02.03.01, §2.c). Only the name and description
/// fields continue onto continuation cards; the other fields "are not
/// scanned on continuation cards" (J 02.03.01, §2.d).
library;

import 'diagnostic.dart';
import 'messages.dart';
import 'source_card.dart';
import 'token.dart';

/// One data description entry, assembled from its card group.
final class DataEntry {
  DataEntry._({
    required this.cards,
    required this.name,
    required this.levelText,
    required this.level,
    required this.typeText,
    required this.quantityText,
    required this.quantity,
    required this.modeText,
    required this.justifyText,
    required this.descriptionTokens,
  });

  /// The entry's cards: the first card and its continuation cards.
  final List<SourceCard> cards;

  /// The name, compressed from the name fields of all the entry's cards
  /// with every blank eliminated (J 02.03.01, §2.b); empty when unnamed.
  final String name;

  /// The raw level field, columns 23–24 of the first card.
  final String levelText;

  /// The level number 1–99, or `null` when the field is blank or not a
  /// number.
  final int? level;

  /// The type code, columns 25–30 of the first card, trimmed; empty when
  /// blank. Codes are validated semantically at M3.
  final String typeText;

  /// The raw quantity field, columns 31–35 of the first card, trimmed.
  final String quantityText;

  /// The quantity as a number, or `null` when blank or not a number.
  final int? quantity;

  /// The mode character, column 36; empty when blank.
  final String modeText;

  /// The justification character, column 37; empty when blank.
  final String justifyText;

  /// The description-field tokens of the whole entry: unclassified runs
  /// and quoted constants, in source order.
  final List<Token> descriptionTokens;
}

/// The result of scanning a data division's cards.
final class DataScan {
  DataScan._(this.entries, this.diagnostics);

  /// The entries in source order.
  final List<DataEntry> entries;

  /// The diagnostics issued during the scan.
  final List<Diagnostic> diagnostics;
}

/// Scans data description [cards] into entries. An entry is one card
/// plus every following card claimed by a punched continuation column
/// (F p. 84; J 02.03.02, §3.b: "Data and Environment entries are
/// considered complete when column 72 is blank").
///
/// Diagnostics go to [sink] when one is given — the compilation's
/// [DiagnosticSink], whose severity-5 throw stops the scan at the point
/// of detection (D9.1) — and the scan's own [DataScan.diagnostics]
/// holds only this scan's rows either way. [pedantic] adds message 919
/// when a quoted constant continues across cards (decision D1.1;
/// D11.4); it changes no scanned value.
DataScan scanDataDescription(
  List<SourceCard> cards, {
  List<Diagnostic>? sink,
  bool pedantic = false,
}) {
  final entries = <DataEntry>[];
  final List<Diagnostic> diagnostics = sink ?? <Diagnostic>[];
  final int first = diagnostics.length;
  for (final List<SourceCard> group in continuationGroups(cards)) {
    entries.add(_scanEntry(group, diagnostics, pedantic: pedantic));
  }
  return DataScan._(entries, diagnostics.sublist(first));
}

/// The description field spans columns 38–71 (F p. 65).
const int _descriptionFirst = 38;

/// Text ends at column 71; column 72 is the continuation flag (D2.6).
const int _textLast = 71;

/// Characters that can form a field pictorial: the format characters
/// `A X 9 8 * V . S $ , + - F` with parenthesized repetition counts
/// (F p. 80; J 02.05.05).
// The J 02.05.05 chart's legitimate format characters: the letters
// A X V S F, the digits 9 and 8, the edit specials, and a digit run
// only inside a parenthesized (n) count. Bare 0-7 are name characters
// (J 02.05.06 e; review DATA-8). A single trailing zone letter A–R
// after all-numeric format characters stays in the run — at punch
// level it is an overpunched digit, the chart's 9̅ (M2-3 amendment
// 2026-08-04; design note M3-5). The class matches the parser's
// (`data_parser.dart`).
final RegExp _formatChars = RegExp(
  r'^([AXVSF89*.$,+\-]|\([0-9]+\))+$'
  r'|^([VS89*.$,+\-]|\([0-9]+\))+[A-R]$',
);

DataEntry _scanEntry(
  List<SourceCard> group,
  List<Diagnostic> diagnostics, {
  bool pedantic = false,
}) {
  final SourceCard first = group.first;

  void gate(SourceCard card, int from, int to) {
    for (final int column in card.unreadableColumns(from, to)) {
      diagnostics.reportAt(msgIllegalCharacterReplaced, card, column: column);
    }
  }

  // Name: all cards' name fields, blanks eliminated (J 02.03.01, §2.b).
  final nameBuffer = StringBuffer();
  for (final card in group) {
    gate(card, 7, 22);
    nameBuffer.write(card.internalText(7, 22).replaceAll(' ', ''));
  }
  final name = nameBuffer.toString();
  if (name.length > 30) {
    diagnostics.reportAt(msgNameTooLong, first, operands: [name]);
  }

  // Fixed fields, first card only (J 02.03.01, §2.d).
  gate(first, 23, 37);
  final String levelText = first.internalText(23, 24);
  int? level = int.tryParse(levelText.trim());
  if (level != null && (level < 1 || level > 99)) {
    level = null; // "Any numbers 01-99 may be used" (J 02.05.01).
  }
  final String typeText = first.internalText(25, 30).trim();
  if (level == null && name.isNotEmpty && typeText != 'REDEF') {
    // A named entry without a level draws 194,00. An unnamed one does
    // not: the sample's unnamed REDEF entry (statement 168,00) has a
    // blank level field and compiled clean (J 90.05 listing). A named
    // REDEF line is D3.4's case: its name is discarded with the
    // parser's own warning, so it takes no level and no 194,00.
    diagnostics.reportAt(msgDataNameLacksLevel, first);
  }
  final String quantityText = first.internalText(31, 35).trim();
  final int? quantity = quantityText.isEmpty
      ? null
      : int.tryParse(quantityText);
  final String modeText = first.internalText(36, 36).trim();
  if (modeText.isNotEmpty && modeText != 'I' && modeText != 'E') {
    diagnostics.reportAt(msgIllegalMode, first, column: 36);
  }
  final String justifyText = first.internalText(37, 37).trim();
  if (justifyText.isNotEmpty && justifyText != 'L' && justifyText != 'R') {
    diagnostics.reportAt(msgIllegalJustification, first, column: 37);
  }

  // Fixed-field content on a continuation card: not scanned, but
  // diagnosed (J 90.04, message 186,00).
  for (final SourceCard card in group.skip(1)) {
    if ([for (var c = 23; c <= 37; c++) card.isPunched(c)].contains(true)) {
      diagnostics.reportAt(msgFixedFieldOnContinuation, card);
    }
  }

  return DataEntry._(
    cards: List.unmodifiable(group),
    name: name,
    levelText: levelText,
    level: level,
    typeText: typeText,
    quantityText: quantityText,
    quantity: quantity,
    modeText: modeText,
    justifyText: justifyText,
    descriptionTokens: _scanDescription(group, diagnostics, pedantic: pedantic),
  );
}

/// Scans the description fields of an entry's cards: blank-separated
/// runs and quote-delimited constants (F p. 79). A blank is assumed at
/// each card's end (F p. 83, General Note) — except inside a constant,
/// which may continue across the entry's cards and is joined with no
/// assumed blank (attested lenient behavior, J 02.03.01, §2.c; decision
/// D1.1 and Open Question 6).
List<Token> _scanDescription(
  List<SourceCard> group,
  List<Diagnostic> diagnostics, {
  bool pedantic = false,
}) {
  final tokens = <Token>[];

  var inConstant = false;
  final constant = StringBuffer();
  // Blanks inside an open constant are buffered and written only when
  // punched content follows, so a card's unpunched tail never enters
  // the constant: a continued constant is joined with no assumed blank
  // (D1.1; Open Question 6), and an unclosed one is not padded out to
  // column 71.
  var constantBlanks = 0;
  SourceCard? constantCard;
  var constantColumn = 0;

  final run = StringBuffer();
  SourceCard? runCard;
  var runColumn = 0;

  void endRun() {
    if (run.isEmpty) {
      return;
    }
    final text = run.toString();
    final SourceCard card = runCard!;
    if (text.length > 30) {
      if (_formatChars.hasMatch(text)) {
        // A pictorial is limited to 30 characters (J 90.04, message
        // 100,00).
        diagnostics.reportAt(msgPictorialTooLong, card, column: runColumn);
      } else {
        diagnostics.reportAt(
          msgNameTooLong,
          card,
          column: runColumn,
          operands: [text],
        );
      }
    }
    tokens.add(Token(TokenKind.descriptionItem, text, card, runColumn));
    run.clear();
  }

  void endConstant() {
    final text = constant.toString();
    final SourceCard card = constantCard!;
    if (text.length > 120) {
      // Our Data Description constant limit is 120 characters (decision
      // D7.9; J 90.04, message 148,00 — the 1962 capacity is unstated).
      diagnostics.reportAt(msgConstantTooLong, card, column: constantColumn);
    }
    tokens.add(Token(TokenKind.alphamericLiteral, text, card, constantColumn));
    constant.clear();
    constantBlanks = 0;
    inConstant = false;
  }

  for (final card in group) {
    // Leading unpunched columns of a continuation card never join an
    // open constant: both card edges drop their unpunched columns, so
    // the parts join in card order with no padding or alignment between
    // them (D1.1; the card tail is dropped below).
    var beforeCardContent = inConstant;
    for (int column = _descriptionFirst; column <= _textLast; column++) {
      if (inConstant) {
        if (!card.isPunched(column)) {
          if (!beforeCardContent) {
            constantBlanks++;
          }
          continue;
        }
        beforeCardContent = false;
        constant.write(' ' * constantBlanks);
        constantBlanks = 0;
        final int? bcd = card.bcdAt(column);
        if (bcd == null) {
          // No read-out: illegal even inside a constant (D9.10 layer a).
          diagnostics.reportAt(
            msgIllegalCharacterReplaced,
            card,
            column: column,
          );
          constant.write('0');
          continue;
        }
        final String? glyph = card.glyphAt(column);
        if (glyph == "'") {
          endConstant();
        } else {
          constant.write(glyph ?? '?');
        }
        continue;
      }
      final String? glyph = card.glyphAt(column);
      if (!card.isPunched(column)) {
        endRun();
        continue;
      }
      if (glyph == null) {
        // Outside a constant an unreadable column is gated (D9.10).
        diagnostics.reportAt(msgIllegalCharacterReplaced, card, column: column);
        if (run.isEmpty) {
          runCard = card;
          runColumn = column;
        }
        run.write('0');
        continue;
      }
      if (glyph == "'") {
        endRun();
        inConstant = true;
        constantCard = card;
        constantColumn = column;
        continue;
      }
      if (run.isEmpty) {
        runCard = card;
        runColumn = column;
      }
      run.write(glyph);
    }
    if (!inConstant) {
      endRun(); // A blank is assumed at each card's end (F p. 83).
    } else {
      constantBlanks = 0; // The card's unpunched tail never joins.
      if (identical(card, group.last)) {
        // The constant never closed and no card follows it (D1.1;
        // J 90.04, message 167,00).
        diagnostics.reportAt(
          msgSecondQuoteMissing,
          card,
          column: constantColumn,
        );
        endConstant();
      } else if (pedantic) {
        // The constant continues onto the next card, joined with no
        // assumed blank (D1.1; Open Question 6). --pedantic warns
        // (msg 919; D11.4); the join itself is unchanged.
        diagnostics.reportAt(
          msgConstantContinuesAcrossCards,
          card,
          column: constantColumn,
        );
      }
    }
  }
  return tokens;
}
