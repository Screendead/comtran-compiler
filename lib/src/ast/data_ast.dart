/// The Data Description AST (M2).
///
/// M2 records the syntactic structure of each entry: the recognized type
/// code, the level hierarchy, and the description field split into its
/// ordered clauses (F p. 79). The meaning of the pieces — field-type
/// classification, sizing, storage — is M3's (design note M2-3,
/// `docs/design/m2-parser.md`).
library;

import '../lexer/data_lexer.dart';
import '../lexer/token.dart';

/// The type codes of the 7090 language (J 02.05.02–03). A blank type
/// field is [none]; F's withdrawn FUNCT and PARAM codes have no member
/// (J 02.05.03: "no longer in the language").
enum DataTypeCode {
  /// A blank type field: an ordinary field or group.
  none,

  /// `RECORD` — a record entry (J 02.05.02).
  record,

  /// `COND` — a condition-name entry (F pp. 71–72; J 02.05.02).
  cond,

  /// `REDEF` — a redefinition marker (J 02.05.02).
  redef,

  /// `COPY` — deferred in J (J 90.01.03); parsed and diagnosed.
  copy,

  /// `LABEL` — the 14-word IOCS label area (J 02.05.03).
  label,

  /// `RCDMRK` — new in J; the compiler supplies the pictorial
  /// (J 02.05.03).
  rcdmrk,
}

/// One parsed data description entry, in its level hierarchy.
final class DataItem {
  /// Creates a parsed item over the M1 [entry].
  DataItem({
    required this.entry,
    required this.typeCode,
    this.pictorial,
    this.constant,
    this.targetName,
    this.quantityInName,
    this.blankWhenZero = false,
    this.nameDiscarded = false,
    this.extras = const [],
  });

  /// The M1 scan entry: cards, name, and fixed fields.
  final DataEntry entry;

  /// The recognized type code, or `null` when the type field holds an
  /// unrecognized or withdrawn code (diagnosed; the raw text stays in
  /// [DataEntry.typeText]).
  final DataTypeCode? typeCode;

  /// The pictorial: the leading description run made of format
  /// characters only (J 02.05.06 — a run with any non-format character
  /// is a name, not a pictorial). `null` when absent. Content
  /// classification is M3's.
  final Token? pictorial;

  /// The quoted constant, when the description carries one (F p. 81).
  final Token? constant;

  /// The data name in the description field — the REDEF or COPY target
  /// (J 02.05.02), or a stray name for M3 to judge.
  final Token? targetName;

  /// The name after `QUANTITY IN`, marking the entry variable-length
  /// (F pp. 82–83; J 02.05.07). `null` when absent.
  final Token? quantityInName;

  /// Whether the description carries `BLANK WHEN ZERO` (J 02.05.07).
  final bool blankWhenZero;

  /// Whether [DataEntry.name] is discarded — an F-style name on a
  /// REDEF line (D3.4): warned, never entered in the dictionary, so
  /// M3's dictionary pass must skip it.
  final bool nameDiscarded;

  /// Description tokens no clause claimed. M2 keeps them for M3 to
  /// judge; it does not diagnose them (design note M2-3).
  final List<Token> extras;

  /// The parent in the level hierarchy, `null` for a top item.
  DataItem? parent;

  /// The children in the level hierarchy, source order.
  final List<DataItem> children = [];
}
