/// The I/O verb binding map (M3 stage 2, design note M3-18).
///
/// The stage-1 binder kept every per-card check; these rows need the
/// resolved program. The verb walk runs after name resolution, so a
/// record or file operand is looked up in the stage-1 binder's tables
/// rather than resolved again. The entry also carries the FILE-card
/// options that need the data map, the POOL and GROUP buffer minimums
/// (J 02.06.13–14), the LABEL area cap (J 02.05.03), the field-after-
/// a-variable-array rule (J 90.01.04), and the base-locator counter
/// (D9.7).
library;

import '../ast/data_ast.dart';
import '../ast/environment_ast.dart';
import '../ast/procedure_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/messages.dart';
import '../lexer/token.dart';
import 'binder.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'dictionary.dart';
import 'mapper.dart';
import 'resolver.dart';

/// Checks the GET, FILE, OPEN, and CLOSE sites of one job against its
/// environment description.
final class VerbBinder extends ClauseWalk {
  VerbBinder(
    super.diagnostics,
    this.mapper,
    this.resolver,
    this.binder, {
    required this.tableLimits,
  });

  final DataMapper mapper;
  final NameResolver resolver;
  final EnvironmentBinder binder;

  /// False under `--no-table-limits` (D9.7): the base-locator counter
  /// stays silent.
  final bool tableLimits;

  @override
  Set<Sentence> get deletedSentences => resolver.deletedSentences;

  /// The files a verb processed a record of (msg 198).
  final Set<FileCard> _processed = Set.identity();

  /// Whether the job carries a GET or a FILE verb at all (msg 198).
  bool _processesRecords = false;

  /// The file-and-option pairs msgs 117, 118, and 121 already spoke
  /// for: the row is one per file, however many GET RECORD FROMs name
  /// it.
  final Set<(FileCard, Message)> _reportedOptions = {};

  void check(
    List<EnvironmentCard> cards,
    List<List<Sentence>> procedureGroups,
  ) {
    _liveFiles(cards).forEach(_checkFileCardNames);
    _checkBuffers(cards);
    _checkLabelAreas();
    _checkFieldsAfterVariableArrays();
    walkClauses(procedureGroups, _checkClause);
    for (final FileCard file in _liveFiles(cards)) {
      // The row names a file the program forgot among the files it
      // uses. A job with no GET and no FILE verb processes no record
      // at all, and one row per file of it says nothing the absent
      // verbs do not (ours: M3-18 states the trigger, not the scope).
      if (_processesRecords &&
          file.direction != FileDirection.checkpoint &&
          !_processed.contains(file)) {
        diagnostics.reportAt(
          msgNoRecordsProcessed,
          file.spec.cards.first,
          operands: [file.spec.name],
        );
      }
    }
    _countLocatedRecords();
  }

  /// The FILE cards whose bindings stand: a card msg 931 rejected
  /// binds nothing, so no row below speaks for it (stage 1's reading).
  Iterable<FileCard> _liveFiles(List<EnvironmentCard> cards) => cards
      .whereType<FileCard>()
      .where((FileCard file) => !binder.rejectedFiles.contains(file));

  // ── The verb sites (M3-18) ───────────────────────────────────────

  void _checkClause(Clause clause) {
    switch (clause) {
      case GetClause(:final name, recordFrom: true):
        _processesRecords = true;
        _checkGetRecordFrom(name);
      case GetClause(:final name):
        _processesRecords = true;
        _checkGet(name);
      case final FileClause clause:
        _processesRecords = true;
        _checkFile(clause);
      case OpenClause(:final files) || CloseClause(:final files):
        for (final file in files) {
          _file(file, absent: msgNameIsNotFile);
        }
      default:
        break;
    }
  }

  void _checkGet(NameReference name) {
    final RecordInfo? record = _record(name);
    if (record == null) {
      return;
    }
    if (record.inputFiles.isEmpty) {
      _reportRecord(
        record.outputFiles.isEmpty
            ? msgRecordNotOnFileCard
            : msgRecordNotOnInputFile,
        name,
        record.name,
      );
      return;
    }
    _processed.addAll(_filesBinding(record, FileDirection.input));
  }

  void _checkGetRecordFrom(NameReference name) {
    final FileCard? file = _file(name, absent: msgGetRecordFromNotFile);
    if (file == null) {
      return;
    }
    _processed.add(file);
    if (file.direction != FileDirection.input) {
      report(msgGetRecordFromNotInput, name.anchor, operands: [name.text]);
      return;
    }
    final List<FileRecordClause> clauses = file.records;
    if (clauses.isEmpty || binder.rejectedFiles.contains(file)) {
      return; // The card drew msg 13 or msg 931 already.
    }
    if (!_lengthDeterminable(file, clauses)) {
      report(msgGetRecordFromLength, name.anchor);
    }
    _checkOptionUniformity(file, clauses, name);
  }

  /// Whether one J 02.07.04 condition holds. PATTERN, its fifth
  /// condition, cannot rescue a file until its syntax lands (D9.12).
  bool _lengthDeterminable(FileCard file, List<FileRecordClause> clauses) {
    if (file.begin) {
      return true; // Condition b.
    }
    final List<RecordInfo> records = binder.boundRecords[file] ?? const [];
    // The length compared is the record's own extent: a record REDEF'd
    // onto another owns no storage space, so the space table holds no
    // length for it (J 02.07.05 c-iii keeps both records located).
    if (records.length == clauses.length &&
        records.every((RecordInfo r) => !r.variable) &&
        records
                .map((RecordInfo r) => mapper.semantics[r.item]!.extentChars)
                .toSet()
                .length ==
            1) {
      return true; // Condition a: fixed and equal length.
    }
    if (clauses.every((FileRecordClause c) => c.blockControl)) {
      return true; // Condition d.
    }
    // Condition c: the standard variable length form, which neither
    // BLOCK CONTROL nor a length field of the programmer's replaces.
    return records.length == clauses.length &&
        records.every((RecordInfo r) => r.variable) &&
        clauses.every(
          (FileRecordClause c) => !c.blockControl && c.findLengthIn == null,
        );
  }

  void _checkOptionUniformity(
    FileCard file,
    List<FileRecordClause> clauses,
    NameReference at,
  ) {
    void row(Message message, bool Function(FileRecordClause) taken) {
      final int taking = clauses.where(taken).length;
      if (taking == 0 ||
          taking == clauses.length ||
          !_reportedOptions.add((file, message))) {
        return;
      }
      report(message, at.anchor, operands: [file.spec.name]);
    }

    row(
      msgFindLengthNotUniform,
      (FileRecordClause c) => c.findLengthIn != null,
    );
    row(
      msgPlaceLengthNotUniform,
      (FileRecordClause c) => c.placeLengthIn != null,
    );
    row(msgBlockControlNotUniform, (FileRecordClause c) => c.blockControl);
  }

  void _checkFile(FileClause clause) {
    final RecordInfo? record = _record(clause.record);
    final NameReference? inFile = clause.inFile;
    if (inFile == null) {
      if (record == null) {
        return;
      }
      if (record.outputFiles.isEmpty) {
        _reportRecord(msgRecordNotOnOutputFile, clause.record, record.name);
        return;
      }
      final List<FileCard> files = _filesBinding(
        record,
        FileDirection.output,
      ).toList();
      // "If the record carries the option PRIMARY in one or more of
      // the output files to which it is associated ... it is only
      // filed in those files wherein it is so classified"
      // (J 02.07.07).
      final List<FileCard> primary = files
          .where((FileCard file) => _statesPrimary(file, record))
          .toList();
      _processed.addAll(primary.isEmpty ? files : primary);
      return;
    }
    final FileCard? file = _file(inFile, absent: msgNameIsNotFile);
    if (file == null) {
      return;
    }
    _processed.add(file);
    if (file.direction != FileDirection.output) {
      report(msgFileIsNotOutput, inFile.anchor, operands: [inFile.text]);
      return;
    }
    if (record != null &&
        !(binder.boundRecords[file] ?? const []).any(
          (RecordInfo bound) => identical(bound, record),
        )) {
      report(
        msgFileCardLacksThisRecord,
        inFile.anchor,
        operands: [file.spec.name, record.name],
      );
    }
  }

  /// The [direction] FILE cards whose clauses bound [record]. The
  /// binding is read back by card identity: a file name reaches no
  /// card when the card carries none (msg 1) and reaches the wrong one
  /// when two cards punch the same name.
  Iterable<FileCard> _filesBinding(
    RecordInfo record,
    FileDirection direction,
  ) => binder.boundRecords.keys.where(
    (FileCard file) =>
        file.direction == direction &&
        binder.boundRecords[file]!.any(
          (RecordInfo bound) => identical(bound, record),
        ),
  );

  bool _statesPrimary(FileCard file, RecordInfo record) => file.records.any(
    (FileRecordClause clause) =>
        clause.name.text == record.name && clause.primary,
  );

  /// The record a GET or FILE operand names. Msg 16 speaks for a name
  /// that reaches a file or a plain field; msg 8 for one that reaches
  /// nothing, or a procedure or condition name (M3-18).
  RecordInfo? _record(NameReference reference) {
    final String last = reference.words.last.text;
    final DataItem? synonymItem = resolver.dictionary.synonym(last)?.item;
    if (reference.words.length == 1) {
      final RecordInfo? record = binder.recordByName[last];
      if (record != null) {
        return record;
      }
      if (synonymItem != null) {
        // A CALL synonym of a record binds like the record: the CALL
        // pass precedes the binder for this (M3-17; J 02.03.03).
        final RecordInfo? called = binder.records
            .where((RecordInfo r) => identical(r.item, synonymItem))
            .firstOrNull;
        if (called != null) {
          return called;
        }
      }
    }
    final bool namesField = mapper
        .itemsNamed(last)
        .any((DataItem i) => i.typeCode != DataTypeCode.cond);
    if (namesField ||
        synonymItem != null ||
        binder.fileByName.containsKey(last)) {
      _reportRecord(msgFileNameNotRecord, reference, reference.text);
      return null;
    }
    report(
      msgNeitherRecordNorFile,
      reference.anchor,
      operands: [reference.text],
    );
    return null;
  }

  /// The file an operand names, or `null` after [absent].
  FileCard? _file(NameReference reference, {required Message absent}) {
    final FileCard? file = reference.words.length == 1
        ? binder.fileByName[reference.words.single.text]
        : null;
    if (file == null) {
      report(absent, reference.anchor, operands: [reference.text]);
    }
    return file;
  }

  /// Msgs 9, 10, 16, and 19 print NAME.2 alone; NAME.1 stays empty.
  void _reportRecord(Message message, NameReference at, String name) {
    report(message, at.anchor, operands: ['', name]);
  }

  // ── FILE-card names (M3-18) ──────────────────────────────────────

  void _checkFileCardNames(FileCard file) {
    for (final Token? name in [file.onError, file.forLabel]) {
      if (name != null && !_namesProcedure(name.text)) {
        diagnostics.report(msgUndefinedSymbol, name, operands: [name.text]);
      }
    }
    for (final FileRecordClause clause in file.records) {
      _checkLengthField(clause.findLengthIn, msgFindLengthFormat);
      _checkLengthField(clause.placeLengthIn, msgPlaceLengthFormat);
    }
  }

  bool _namesProcedure(String name) => resolver.dictionary
      .named(name)
      .any(
        (DictionaryEntry e) =>
            e.kind == NameKind.statement || e.kind == NameKind.section,
      );

  /// A length field holds a record length, so its format is ours:
  /// external or internal decimal with no fraction positions (M3-18).
  /// Qualified names are barred here (J 90.01.04), so the name is
  /// matched whole and the M3-17 triage speaks for an ambiguous one.
  void _checkLengthField(Token? name, Message improper) {
    if (name == null) {
      return;
    }
    final DataItem? synonymItem = resolver.dictionary.synonym(name.text)?.item;
    final List<DataItem> candidates = synonymItem != null
        ? [synonymItem]
        : mapper.itemsNamed(name.text);
    if (candidates.isEmpty) {
      diagnostics.report(msgUndefinedSymbol, name, operands: [name.text]);
      return;
    }
    if (candidates.length > 1) {
      diagnostics.report(msgNameNotUnique, name, operands: [name.text]);
      return;
    }
    final ItemSemantics sem = mapper.semantics[candidates.single]!;
    // No fraction and no scale: a scaled field cannot hold an
    // arbitrary length — 999SSS stores a thousandth of its value
    // (F p. 80; M3-18).
    final bool proper =
        (sem.fieldClass == FieldClass.externalDecimal ||
            sem.fieldClass == FieldClass.internalDecimal) &&
        sem.fractionDigits == 0;
    if (!proper) {
      diagnostics.report(improper, name, operands: [name.text]);
    }
  }

  // ── POOL and GROUP buffers (J 02.06.13–14; M3-18) ────────────────

  void _checkBuffers(List<EnvironmentCard> cards) {
    final Map<String, PoolCard> pools = {
      for (final PoolCard pool in cards.whereType<PoolCard>())
        if (pool.spec.name.isNotEmpty) pool.spec.name: pool,
    };
    final Map<PoolCard, int> claimed = Map.identity();
    for (final GroupCard group in cards.whereType<GroupCard>()) {
      final List<Token> names = group.names;
      final PoolCard? pool = names.isEmpty ? null : pools[names.first.text];
      if (names.isNotEmpty && pool == null) {
        diagnostics.report(
          msgGroupLacksPool,
          names.first,
          operands: [names.first.text],
        );
      }
      final List<Token> files = names.skip(1).toList();
      _checkPooledFiles(files);
      // "If no OPENCOUNT is given, the OPENCOUNT will be assumed equal
      // to the number of files in the GROUP". A defaulted buffer count
      // claims only the OPENCOUNT against the pool: the loader's
      // doubled count is an attempt with an express fallback when the
      // POOL BUFFERCOUNT prevents it (J 02.06.14).
      final int openCount = group.openCount ?? files.length;
      int buffers = group.bufferCount ?? openCount;
      if (buffers < openCount) {
        diagnostics.reportAt(msgGroupBufferCountRaised, group.spec.cards.first);
        buffers = openCount;
        group.bufferCount = buffers;
      }
      if (pool != null) {
        claimed[pool] = (claimed[pool] ?? 0) + buffers;
      }
    }
    for (final PoolCard pool in cards.whereType<PoolCard>()) {
      _checkPooledFiles(pool.fileNames);
      final int minimum = [
        pool.fileNames.length,
        claimed[pool] ?? 0,
      ].reduce((int a, int b) => a > b ? a : b);
      if ((pool.bufferCount ?? minimum) < minimum) {
        diagnostics.reportAt(
          msgPoolBufferCountRaised,
          pool.spec.cards.first,
          operands: [pool.spec.name],
        );
        pool.bufferCount = minimum;
      }
    }
  }

  void _checkPooledFiles(Iterable<Token> names) {
    for (final name in names) {
      if (!binder.fileByName.containsKey(name.text)) {
        diagnostics.report(msgNameIsNotFile, name, operands: [name.text]);
      }
    }
  }

  // ── Data-division rows the binder owns (M3-18) ───────────────────

  /// LABEL entries redefine "the single 14 word label area in the
  /// Input/Output Control System" (J 02.05.03).
  void _checkLabelAreas() {
    for (final DataItem item in mapper.items) {
      if (item.typeCode != DataTypeCode.label) {
        continue;
      }
      final int chars = mapper.semantics[item]!.extentChars;
      if ((chars + 5) ~/ 6 > 14) {
        diagnostics.reportAt(
          msgLabelAreaTooLong,
          item.entry.cards.first,
          operands: [item.entry.name],
        );
      }
    }
  }

  /// "No fields may be described after a variable length array in the
  /// same hierarchy" (J 90.01.04): the field's own position depends on
  /// a length only execution knows. The hierarchy is the top-level
  /// entry (M3-11).
  ///
  /// One row per entry, the attested id first (the M1-8 precedent):
  /// the array's own count field takes msg 105, an entry carrying a
  /// constant takes msg 43 (D3.6), and msg 941 covers the rest — the
  /// gap M3-16 records as having no attested id.
  void _checkFieldsAfterVariableArrays() {
    final Map<DataItem, int> index = Map.identity();
    for (final (int i, DataItem item) in mapper.items.indexed) {
      index[item] = i;
    }
    final Set<DataItem> variableRoots = Set.identity();
    final Set<DataItem> countItems = Set.identity();
    for (final DataItem item in mapper.items) {
      final ItemSemantics sem = mapper.semantics[item]!;
      final DataItem root = ancestorsOf(item).last;
      if (sem.variableLength) {
        // A refused QUANTITY IN (msg 47) leaves a group, not an array.
        if (sem.fieldClass != FieldClass.group) {
          variableRoots.add(root);
          final DataItem? count = _quantityCount(item, index);
          if (count != null) {
            countItems.add(count);
          }
        }
        continue;
      }
      if (sem.dropped ||
          sem.storageChars == 0 ||
          item.constant != null ||
          countItems.contains(item) ||
          sem.fieldClass == FieldClass.group ||
          sem.fieldClass == FieldClass.condition ||
          sem.fieldClass == FieldClass.redefinition ||
          !variableRoots.contains(root)) {
        continue;
      }
      diagnostics.reportAt(
        msgFieldAfterVariableArray,
        item.entry.cards.first,
        operands: [item.entry.name],
      );
    }
  }

  /// The count field the array's QUANTITY IN resolved to — the latest
  /// candidate preceding the array, or the first candidate when none
  /// precedes, the mapper's own rule. The fallback drew msg 105, which
  /// speaks for its placement, so msg 941 yields to it (M3-18).
  DataItem? _quantityCount(DataItem array, Map<DataItem, int> index) {
    final Token? name = array.quantityInName;
    if (name == null) {
      return null;
    }
    final int here = index[array]!;
    final List<DataItem> candidates = mapper.itemsNamed(name.text);
    DataItem? preceding;
    for (final candidate in candidates) {
      if (index[candidate]! < here) {
        preceding = candidate;
      }
    }
    return preceding ?? candidates.firstOrNull;
  }

  void _countLocatedRecords() {
    if (!tableLimits) {
      return;
    }
    var located = 0;
    for (final RecordInfo record in binder.records) {
      if (record.located && ++located == 128) {
        // One base locator per located record, "Appox-Max" 127
        // (J 90.01.05 item d; D9.7 rejects the band above it).
        diagnostics.reportAt(
          msgBaseLocatorCapacity,
          record.item.entry.cards.first,
        );
      }
    }
  }
}
