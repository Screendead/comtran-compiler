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
/// other character reads as a name (J 02.05.06). The class matches the
/// scanner's (`data_lexer.dart`).
final RegExp _formatShaped = RegExp(r'^[AXVSF0-9*.$,+\-()]+$');

/// Parses one data group's [scan] into items with the hierarchy wired,
/// appending to [diagnostics]. The returned list is flat, in source
/// order; roots are the items with no parent.
List<DataItem> parseDataGroup(DataScan scan, List<Diagnostic> diagnostics) {
  final items = <DataItem>[];
  final stack = <DataItem>[];
  for (final DataEntry entry in scan.entries) {
    final DataItem item = _parseEntry(entry, diagnostics);
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

DataItem _parseEntry(DataEntry entry, List<Diagnostic> diagnostics) {
  void conflict() {
    diagnostics.add(Diagnostic(msgDataCardCodingConflict, entry.cards.first));
  }

  final DataTypeCode? typeCode = _typeCodes[entry.typeText];
  if (typeCode == null) {
    // FUNCT and PARAM are "no longer in the language" (J 02.05.03);
    // anything else was never in it.
    diagnostics.add(
      Diagnostic(
        msgTypeCodeNotInLanguage,
        entry.cards.first,
        column: 25,
        operands: [entry.typeText],
      ),
    );
  }

  // The Quantity field: 1–32767 (J 02.05.04), forbidden on a RECORD
  // card (J 02.05.01).
  if (entry.quantityText.isNotEmpty) {
    final int? quantity = entry.quantity;
    if (quantity == null || quantity < 1 || quantity > 32767) {
      diagnostics.add(
        Diagnostic(msgQuantityOutOfRange, entry.cards.first, column: 31),
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
      return DataItem(
        entry: entry,
        typeCode: typeCode,
        targetName:
            tokens.isNotEmpty && tokens.first.kind == TokenKind.descriptionItem
            ? tokens.first
            : null,
        extras: tokens.length > 1 ? tokens.sublist(1) : const [],
      );
    case DataTypeCode.copy:
      // F's form: the original name, optionally `LIBRARY name`. COPY is
      // deferred in J (J 90.01.03; D7.4): parsed, then refused.
      diagnostics.add(Diagnostic(msgCopyNotHandled, entry.cards.first));
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
        diagnostics.add(
          Diagnostic(
            msgDataCardCodingConflict,
            token.card,
            column: token.column,
          ),
        );
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
