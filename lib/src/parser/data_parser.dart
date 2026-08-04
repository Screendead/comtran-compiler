/// The Data Description parser (M2).
///
/// Turns the M1 scan's entries into [DataItem]s: recognizes the type
/// code (J 02.05.02–03), splits the description field into its ordered
/// clauses (F p. 79; J 02.05.06), checks the per-card structure rules,
/// and builds the level hierarchy by the nearest-lower-preceding rule
/// (F p. 68). Field-type classification and storage semantics are M3's
/// (design note M2-3).
library;

import '../ast/data_ast.dart';
import '../lexer/data_lexer.dart';
import '../lexer/diagnostic.dart';
import '../lexer/reserved_words.dart';
import '../lexer/token.dart';
import 'parser_messages.dart';

/// The type codes the 7090 language recognizes (J 02.05.02–03).
const Map<String, DataTypeCode> _typeCodes = {
  '': DataTypeCode.none,
  'RECORD': DataTypeCode.record,
  'COND': DataTypeCode.cond,
  'REDEF': DataTypeCode.redef,
  'COPY': DataTypeCode.copy,
  'LABEL': DataTypeCode.label,
  'RCDMRK': DataTypeCode.rcdmrk,
};

/// A run of format characters only reads as a pictorial; a run with any
/// other character reads as a name (J 02.05.06). The J 02.05.05 chart's
/// format characters: the letters A X V S F, the digits 9 and 8, the
/// edit specials, and digits inside a parenthesized (n) count — bare
/// 0-7 are name characters (review DATA-8). One exception: a single
/// trailing zone letter A–R after all-numeric format characters stays
/// in the run — at punch level it is an overpunched digit, the sign
/// form the chart writes 9̅ (M2-3 amendment 2026-08-04; design note
/// M3-5, `m3-data.md`). The class matches the scanner's
/// (`data_lexer.dart`).
final RegExp _formatShaped = RegExp(
  r'^([AXVSF89*.$,+\-]|\([0-9]+\))+$'
  r'|^([VS89*.$,+\-]|\([0-9]+\))+[A-R]$',
);

/// Parses one data group's [scan] into items with the hierarchy wired,
/// appending to [diagnostics]. The returned list is flat, in source
/// order; roots are the items with no parent. [pedantic] escalates the
/// D3.4 named-REDEF-line warning (918) to its own error (921), issuing
/// one or the other, never both (decision D11.4); the discarded name
/// is unchanged in both modes.
List<DataItem> parseDataGroup(
  DataScan scan,
  List<Diagnostic> diagnostics, {
  bool pedantic = false,
}) {
  final items = <DataItem>[];
  final stack = <DataItem>[];
  for (final DataEntry entry in scan.entries) {
    final DataItem item = _parseEntry(entry, diagnostics, pedantic: pedantic);
    if (item.typeCode == DataTypeCode.record) {
      // "When the type code RECORD is recognized the previous data
      // organization is always terminated" (J 02.05.01): the record
      // roots a new hierarchy whatever its level number.
      stack.clear();
    }
    final int? level = entry.level;
    if (level == null) {
      // No level: a REDEF marker or a diagnosed entry. It attaches at
      // the current position and opens no group of its own.
      item.parent = stack.isEmpty ? null : stack.last;
    } else {
      // Each entry subdivides the nearest preceding entry with a lower
      // level number (F p. 68).
      while (stack.isNotEmpty &&
          (stack.last.entry.level == null ||
              stack.last.entry.level! >= level)) {
        stack.removeLast();
      }
      item.parent = stack.isEmpty ? null : stack.last;
      stack.add(item);
    }
    item.parent?.children.add(item);
    items.add(item);
  }
  return items;
}

DataItem _parseEntry(
  DataEntry entry,
  List<Diagnostic> diagnostics, {
  bool pedantic = false,
}) {
  void conflict() {
    diagnostics.reportAt(msgDataCardCodingConflict, entry.cards.first);
  }

  final DataTypeCode? typeCode = _typeCodes[entry.typeText];
  if (typeCode != DataTypeCode.redef && _isBarredName(entry.name)) {
    // A list-1/list-2 key word declared as a data name: msg 178, the
    // name is kept as a data name, parsing continues (D1.5; D10.8).
    // A REDEF-line name is discarded below and takes msg 918 instead.
    diagnostics.reportAt(msgKeyWordAsDataName, entry.cards.first, column: 7);
  }
  if (typeCode == null) {
    // FUNCT and PARAM are "no longer in the language" (J 02.05.03);
    // anything else was never in it.
    diagnostics.reportAt(
      msgTypeCodeNotInLanguage,
      entry.cards.first,
      column: 25,
      operands: [entry.typeText],
    );
  }

  // The Quantity field: 1–32767 (J 02.05.04), forbidden on a RECORD
  // card (J 02.05.01).
  if (entry.quantityText.isNotEmpty) {
    final int? quantity = entry.quantity;
    if (quantity == null || quantity < 1 || quantity > 32767) {
      diagnostics.reportAt(
        msgQuantityOutOfRange,
        entry.cards.first,
        column: 31,
      );
    } else if (typeCode == DataTypeCode.record) {
      conflict();
    }
  }

  final List<Token> tokens = entry.descriptionTokens;
  switch (typeCode) {
    case DataTypeCode.redef:
      // "No additional coding except a serial number and the name of
      // the item being redefined" (J 02.05.02).
      if (tokens.length != 1 ||
          tokens.first.kind != TokenKind.descriptionItem) {
        conflict();
      }
      if (entry.levelText.trim().isNotEmpty ||
          entry.quantityText.isNotEmpty ||
          entry.modeText.trim().isNotEmpty ||
          entry.justifyText.trim().isNotEmpty) {
        // A level, quantity, mode, or justify punch is additional
        // coding the REDEF line forbids (J 02.05.02).
        conflict();
      }
      final bool named = entry.name.isNotEmpty;
      if (named) {
        // The F-style named REDEF line: warned and discarded, never
        // entered in the dictionary (D3.4). --pedantic issues 921 in
        // place of 918 (D11.4); the name is discarded identically
        // either way.
        diagnostics.reportAt(
          pedantic ? msgRedefNameRejected : msgRedefNameDiscarded,
          entry.cards.first,
          column: 7,
        );
      }
      return DataItem(
        entry: entry,
        typeCode: typeCode,
        targetName:
            tokens.isNotEmpty && tokens.first.kind == TokenKind.descriptionItem
            ? tokens.first
            : null,
        nameDiscarded: named,
        extras: tokens.length > 1 ? tokens.sublist(1) : const [],
      );
    case DataTypeCode.copy:
      // F's form: the original name, optionally `LIBRARY name`. COPY is
      // deferred in J (J 90.01.03; D7.4): parsed, then refused.
      diagnostics.reportAt(msgCopyNotHandled, entry.cards.first);
      var i = 0;
      if (i < tokens.length && tokens[i].text == 'LIBRARY') {
        i++;
      }
      final Token? target =
          i < tokens.length && tokens[i].kind == TokenKind.descriptionItem
          ? tokens[i]
          : null;
      if (target != null) {
        i++;
      }
      if (target == null || i != tokens.length) {
        conflict();
      }
      return DataItem(
        entry: entry,
        typeCode: typeCode,
        targetName: target,
        extras: tokens.sublist(i),
      );
    case DataTypeCode.rcdmrk:
      // No description is required — the compiler supplies the
      // single-A pictorial (J 02.05.03) — but an explicit pictorial is
      // legal: the sample's ENDFRSTLINE card punches `A` and compiled
      // clean (J 90.05 listing, statement 42,00). Anything beyond a
      // pictorial conflicts.
      final DataItem item = _parseOrderedDescription(
        entry,
        typeCode,
        diagnostics,
      );
      if (item.constant != null ||
          item.targetName != null ||
          item.quantityInName != null ||
          item.blankWhenZero ||
          item.extras.isNotEmpty) {
        conflict();
      }
      return item;
    case DataTypeCode.cond:
      // Exactly one quoted constant — the condition value (F pp. 71–72).
      if (tokens.length != 1 ||
          tokens.first.kind != TokenKind.alphamericLiteral) {
        conflict();
      }
      return DataItem(
        entry: entry,
        typeCode: typeCode,
        constant:
            tokens.isNotEmpty &&
                tokens.first.kind == TokenKind.alphamericLiteral
            ? tokens.first
            : null,
        extras: tokens.length > 1 ? tokens.sublist(1) : const [],
      );
    case DataTypeCode.none:
    case DataTypeCode.record:
    case DataTypeCode.label:
    case null:
      return _parseOrderedDescription(entry, typeCode, diagnostics);
  }
}

/// The ordered description grammar (F p. 79): an optional pictorial,
/// an optional constant, then the keyword clauses `QUANTITY IN name`
/// and `BLANK WHEN ZERO` (whose card position no manual fixes —
/// §8.5.3; accepted anywhere after the leading pair) and at most one
/// stray name for M3 to judge. Unclaimed tokens go to
/// [DataItem.extras] undiagnosed (design note M2-3).
DataItem _parseOrderedDescription(
  DataEntry entry,
  DataTypeCode? typeCode,
  List<Diagnostic> diagnostics,
) {
  final List<Token> tokens = entry.descriptionTokens;
  Token? pictorial;
  Token? constant;
  Token? targetName;
  Token? quantityInName;
  var blankWhenZero = false;
  final extras = <Token>[];

  var i = 0;
  if (i < tokens.length &&
      tokens[i].kind == TokenKind.descriptionItem &&
      _formatShaped.hasMatch(tokens[i].text)) {
    pictorial = tokens[i];
    i++;
  }
  if (i < tokens.length && tokens[i].kind == TokenKind.alphamericLiteral) {
    constant = tokens[i];
    i++;
  }
  while (i < tokens.length) {
    final Token token = tokens[i];
    if (token.kind == TokenKind.descriptionItem && token.text == 'QUANTITY') {
      if (i + 2 < tokens.length &&
          tokens[i + 1].text == 'IN' &&
          tokens[i + 2].kind == TokenKind.descriptionItem) {
        quantityInName = tokens[i + 2];
        i += 3;
      } else {
        // `QUANTITY IN` with no following name (F pp. 82–83).
        diagnostics.report(msgDataCardCodingConflict, token);
        i++;
      }
      continue;
    }
    if (token.kind == TokenKind.descriptionItem &&
        token.text == 'BLANK' &&
        i + 2 < tokens.length &&
        tokens[i + 1].text == 'WHEN' &&
        tokens[i + 2].text == 'ZERO') {
      blankWhenZero = true;
      i += 3;
      continue;
    }
    if (token.kind == TokenKind.descriptionItem &&
        targetName == null &&
        !_formatShaped.hasMatch(token.text)) {
      targetName = token;
      i++;
      continue;
    }
    extras.add(token);
    i++;
  }

  return DataItem(
    entry: entry,
    typeCode: typeCode,
    pictorial: pictorial,
    constant: constant,
    targetName: targetName,
    quantityInName: quantityInName,
    blankWhenZero: blankWhenZero,
    extras: extras,
  );
}

/// Whether [name] is a J list-1 or list-2 key word, barred as a Data
/// name (J 02.03.02-03). Compound names never match: the key-word
/// lists hold single words only.
bool _isBarredName(String name) {
  final KeyWordClass? keyWordClass = keyWordClassOf(name);
  return keyWordClass == KeyWordClass.alwaysKey ||
      keyWordClass == KeyWordClass.notDataOrProcedureName;
}
