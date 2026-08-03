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
DataScan scanDataDescription(List<SourceCard> cards) {
  final entries = <DataEntry>[];
  final diagnostics = <Diagnostic>[];
  var i = 0;
  while (i < cards.length) {
    final group = <SourceCard>[cards[i]];
    while (cards[i].isPunched(72) && i + 1 < cards.length) {
      i++;
      group.add(cards[i]);
    }
    i++;
    entries.add(_scanEntry(group, diagnostics));
  }
  return DataScan._(entries, diagnostics);
}

/// The description field spans columns 38–71 (F p. 65).
const int _descriptionFirst = 38;

/// Text ends at column 71; column 72 is the continuation flag (D2.6).
const int _textLast = 71;

/// Characters that can form a field pictorial: the format characters
/// `A X 9 8 * V . S $ , + - F` with parenthesized repetition counts
/// (F p. 80; J 02.05.05).
final RegExp _formatChars = RegExp(r'^[AXVSF0-9*.$,+\-()]+$');

DataEntry _scanEntry(List<SourceCard> group, List<Diagnostic> diagnostics) {
  final SourceCard first = group.first;

  void gate(SourceCard card, int from, int to) {
    for (final int column in card.unreadableColumns(from, to)) {
      diagnostics.add(
        Diagnostic(msgIllegalCharacterReplaced, card, column: column),
      );
    }
  }

  // Name: all cards' name fields, blanks eliminated (J 02.03.01, §2.b).
  final nameBuffer = StringBuffer();
  for (final SourceCard card in group) {
    gate(card, 7, 22);
    nameBuffer.write(card.internalText(7, 22).replaceAll(' ', ''));
  }
  final String name = nameBuffer.toString();
  if (name.length > 30) {
    diagnostics.add(Diagnostic(msgNameTooLong, first, operands: [name]));
  }

  // Fixed fields, first card only (J 02.03.01, §2.d).
  gate(first, 23, 37);
  final String levelText = first.internalText(23, 24);
  int? level = int.tryParse(levelText.trim());
  if (level != null && (level < 1 || level > 99)) {
    level = null; // "Any numbers 01-99 may be used" (J 02.05.01).
  }
  if (level == null && name.isNotEmpty) {
    // A named entry without a level draws 194,00. An unnamed one does
    // not: the sample's unnamed REDEF entry (statement 168,00) has a
    // blank level field and compiled clean (J 90.05 listing).
    diagnostics.add(Diagnostic(msgDataNameLacksLevel, first));
  }
  final String typeText = first.internalText(25, 30).trim();
  final String quantityText = first.internalText(31, 35).trim();
  final int? quantity = quantityText.isEmpty
      ? null
      : int.tryParse(quantityText);
  final String modeText = first.internalText(36, 36).trim();
  if (modeText.isNotEmpty && modeText != 'I' && modeText != 'E') {
    diagnostics.add(Diagnostic(msgIllegalMode, first, column: 36));
  }
  final String justifyText = first.internalText(37, 37).trim();
  if (justifyText.isNotEmpty && justifyText != 'L' && justifyText != 'R') {
    diagnostics.add(Diagnostic(msgIllegalJustification, first, column: 37));
  }

  // Fixed-field content on a continuation card: not scanned, but
  // diagnosed (J 90.04, message 186,00).
  for (final SourceCard card in group.skip(1)) {
    if ([for (var c = 23; c <= 37; c++) card.isPunched(c)].contains(true)) {
      diagnostics.add(Diagnostic(msgFixedFieldOnContinuation, card));
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
    descriptionTokens: _scanDescription(group, diagnostics),
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
  List<Diagnostic> diagnostics,
) {
  final tokens = <Token>[];

  var inConstant = false;
  final constant = StringBuffer();
  SourceCard? constantCard;
  var constantColumn = 0;

  final run = StringBuffer();
  SourceCard? runCard;
  var runColumn = 0;

  void endRun() {
    if (run.isEmpty) {
      return;
    }
    final String text = run.toString();
    if (text.length > 30) {
      if (_formatChars.hasMatch(text)) {
        // A pictorial is limited to 30 characters (J 90.04, message
        // 100,00).
        diagnostics.add(
          Diagnostic(msgPictorialTooLong, runCard!, column: runColumn),
        );
      } else {
        diagnostics.add(
          Diagnostic(
            msgNameTooLong,
            runCard!,
            column: runColumn,
            operands: [text],
          ),
        );
      }
    }
    tokens.add(Token(TokenKind.descriptionItem, text, runCard!, runColumn));
    run.clear();
  }

  void endConstant() {
    final String text = constant.toString();
    if (text.length > 120) {
      // Our Data Description constant limit is 120 characters (decision
      // D7.9; J 90.04, message 148,00 — the 1962 capacity is unstated).
      diagnostics.add(
        Diagnostic(msgConstantTooLong, constantCard!, column: constantColumn),
      );
    }
    tokens.add(
      Token(TokenKind.alphamericLiteral, text, constantCard!, constantColumn),
    );
    constant.clear();
    inConstant = false;
  }

  for (final SourceCard card in group) {
    for (var column = _descriptionFirst; column <= _textLast; column++) {
      if (inConstant) {
        if (!card.isPunched(column)) {
          constant.write(' ');
          continue;
        }
        final int? bcd = card.bcdAt(column);
        if (bcd == null) {
          // No read-out: illegal even inside a constant (D9.10 layer a).
          diagnostics.add(
            Diagnostic(msgIllegalCharacterReplaced, card, column: column),
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
        diagnostics.add(
          Diagnostic(msgIllegalCharacterReplaced, card, column: column),
        );
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
    } else if (identical(card, group.last)) {
      // The constant never closed and no card follows it (D1.1; J 90.04,
      // message 167,00).
      diagnostics.add(
        Diagnostic(msgSecondQuoteMissing, card, column: constantColumn),
      );
      endConstant();
    }
    // Otherwise the constant continues onto the next card, joined with
    // no assumed blank (D1.1; Open Question 6).
  }
  return tokens;
}
