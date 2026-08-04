/// The program dictionary (M3-8; M3-17): every programmer name, with
/// its kind, its declaration, and its encounter number — the
/// sequential numbering behind the object listing's `1)C` / `2)C`
/// (J 90.02.02). GN names never enter it (M3-8); a REDEF line's
/// discarded name never enters it (D3.4).
library;

import '../ast/data_ast.dart';
import '../ast/procedure_ast.dart';

/// What a dictionary name names (M3-17).
enum NameKind {
  /// A data description entry without the RECORD or COND type code.
  data,

  /// A RECORD-typed entry; program-unique, never section-qualified
  /// (D2.5).
  record,

  /// A data COND entry's condition name.
  dataCondition,

  /// An Environment COND card's name — the console-key test
  /// (J 02.06.17).
  keysCondition,

  /// A CALL synonym: a new unique simple name for one field (D4.13).
  synonym,

  /// A statement label, scoped to its section (D2.5).
  statement,

  /// A section name: the label of its BEGIN SECTION sentence.
  section,

  /// An Environment specification name — a file or a pool.
  environment,
}

/// One dictionary name.
final class DictionaryEntry {
  DictionaryEntry(
    this.name,
    this.kind, {
    required this.encounter,
    this.item,
    this.sentence,
    this.section,
  });

  final String name;

  final NameKind kind;

  /// The declaring data item — for [NameKind.data], [NameKind.record],
  /// [NameKind.dataCondition], and the field a [NameKind.synonym]
  /// names. `null` otherwise.
  final DataItem? item;

  /// The declaring sentence, for [NameKind.statement] and
  /// [NameKind.section].
  final Sentence? sentence;

  /// The owning section's name for a section-scoped statement label;
  /// `null` for the outermost scope and for every other kind.
  final String? section;

  /// The 1-based sequence number among identical names, in encounter
  /// order (J 90.02.02).
  final int encounter;
}

/// The dictionary of one job.
final class Dictionary {
  final List<DictionaryEntry> entries = [];

  final Map<String, List<DictionaryEntry>> _byName = {};

  /// Every entry under [name], encounter order.
  List<DictionaryEntry> named(String name) => _byName[name] ?? const [];

  /// The synonym entry under [name], or `null` (synonyms are unique,
  /// D4.13; the first stands when a collision was diagnosed).
  DictionaryEntry? synonym(String name) {
    for (final DictionaryEntry entry in named(name)) {
      if (entry.kind == NameKind.synonym) {
        return entry;
      }
    }
    return null;
  }

  /// Adds a name and returns its entry.
  DictionaryEntry add(
    String name,
    NameKind kind, {
    DataItem? item,
    Sentence? sentence,
    String? section,
  }) {
    final List<DictionaryEntry> siblings = _byName.putIfAbsent(name, () => []);
    final entry = DictionaryEntry(
      name,
      kind,
      item: item,
      sentence: sentence,
      section: section,
      encounter: siblings.length + 1,
    );
    siblings.add(entry);
    entries.add(entry);
    return entry;
  }
}
