/// The data map (design note M3-3): what the semantic layer knows
/// about every data item, area, and record of one job.
library;

import '../ast/data_ast.dart';
import '../lexer/diagnostic.dart';
import '../parser/parser.dart';
import 'pictorial.dart';

/// [item] and every descendant, preorder.
Iterable<DataItem> subtreeOf(DataItem item) sync* {
  yield item;
  for (final DataItem child in item.children) {
    yield* subtreeOf(child);
  }
}

/// The six field types of the J 02.05.05 chart, plus the structural
/// kinds a data entry can be instead of a field.
enum FieldClass {
  /// A field with no pictorial: alphameric, length the sum of its
  /// subfields (D3.3; J 02.05.06).
  group,

  /// A or X positions; also the mixed-pictorial downgrade
  /// (J 90.01.03) and a constant-only entry.
  alphameric,

  /// Digits under mode E: stored BCD (J 02.05.04).
  externalDecimal,

  /// Digits under mode I: stored binary (J 02.05.04).
  internalDecimal,

  /// Edit characters or BLANK WHEN ZERO (J 02.05.05; D3.2).
  edited,

  /// Mode I with F or FF: floating binary.
  floatingPoint,

  /// Mode E with F: the edited form of floating point.
  scientificDecimal,

  /// A COND entry: names a value, reserves no storage.
  condition,

  /// A REDEF marker line: directs the allocator, reserves no storage.
  redefinition,
}

/// A field's effective placement rule (J 02.05.04; D3.5).
enum Justification { left, right, packed }

/// The semantic record one [DataItem] gains (M3-3).
final class ItemSemantics {
  ItemSemantics(this.item);

  final DataItem item;

  FieldClass fieldClass = FieldClass.group;

  /// The measured pictorial, `null` for groups and constant-only
  /// entries.
  Pictorial? shape;

  Justification justification = Justification.packed;

  /// Storage characters of one occurrence: a leaf's reservation, or a
  /// group's end-to-start extent including interior alignment. This is
  /// the D3.3 comparison length (amended 2026-08-04).
  int storageChars = 0;

  /// More than 10 represented digits, or FF (J 02.05.06).
  bool doublePrecision = false;

  /// Digits the field represents, `S` fillers included.
  int digits = 0;

  /// Fraction positions; negative for a trailing-`S` scaled integer.
  int fractionDigits = 0;

  /// The effective repetition count from the Quantity field.
  int quantity = 1;

  /// One element's (word, byte) extent in characters when [quantity]
  /// is above one — whole-structure repetition (M3-6).
  int strideChars = 0;

  /// Whether the entry carries QUANTITY IN (J 02.05.07).
  bool variableLength = false;

  /// The root whose area (or located record) the offsets below are
  /// relative to; a redefinition's items point at the redefined
  /// root's. `null` until allocated, or for an entry with no storage.
  DataItem? spaceRoot;

  /// The offset of the first occurrence, in characters from the
  /// space's head.
  int startChar = 0;

  /// All occurrences: [strideChars] times [quantity] for a repeated
  /// entry, [storageChars] otherwise.
  int extentChars = 0;

  /// Storage word of the first occurrence.
  int get word => startChar ~/ 6;

  /// Byte 0–5 within [word] — the attested descriptor granularity
  /// (J 90.02.05).
  int get byte => startChar % 6;

  /// Set when the entry sits under a formatted field (msg 36): it is
  /// classified but reserves no storage.
  bool dropped = false;

  /// Set when the entry's constant was diagnosed and not stored
  /// (msgs 43, 51, 57, 58).
  bool constantSuppressed = false;
}

/// One transmitted storage area: a top-level data item with program
/// storage, in source order (M3-6; Location Counter 0, J 90.02.01).
final class AreaInfo {
  AreaInfo(this.name, {required this.words});

  /// The punched name; empty for an unnamed entry (its GN name is
  /// stage 3's).
  final String name;

  /// The area's initial words: a 36-bit value where any character is
  /// initialized, `null` for a wholly uninitialized word (M3-7).
  final List<int?> words;

  /// The extent in whole words.
  int get extentWords => words.length;
}

/// A record's binding, from the environment binder (M3-11).
final class RecordInfo {
  RecordInfo(this.item, this.name);

  final DataItem item;
  final String name;

  /// Names of the input and output files whose FILE cards list the
  /// record.
  final List<String> inputFiles = [];
  final List<String> outputFiles = [];

  /// Whether the record is located in buffers: on an input file and
  /// not forced out (J 02.07.05). A located record takes no area.
  bool located = false;

  /// Whether any QUANTITY IN field makes the record variable length
  /// (J 02.07.03).
  bool variable = false;

  /// Whether a REDEF sharing the record's area forced its file's
  /// records to transmit (J 02.07.05; msg 932).
  bool forcedTransmit = false;
}

/// The semantic layer's result over one job (M3-2, M3-3).
final class SemanticResult {
  SemanticResult({
    required this.parse,
    required this.semantics,
    required this.areas,
    required this.records,
    required this.semanticDiagnostics,
    required this.stopped,
  });

  /// The parse the semantics were computed over.
  final ParseResult parse;

  /// The semantic record of every data item, keyed by identity.
  final Map<DataItem, ItemSemantics> semantics;

  /// The transmitted areas, program order.
  final List<AreaInfo> areas;

  /// One entry per RECORD-typed top-level item, source order.
  final List<RecordInfo> records;

  /// The semantic layer's own diagnostics, in detection order.
  final List<Diagnostic> semanticDiagnostics;

  /// Whether a severity-5 diagnostic stopped the phase (D10.2).
  final bool stopped;

  /// Every phase's diagnostics as one block, ordered by card number,
  /// stable within one card (the M2-2 merge rule).
  late final List<Diagnostic> diagnostics = mergeDiagnosticPhases(
    parse.diagnostics,
    semanticDiagnostics,
  );
}
