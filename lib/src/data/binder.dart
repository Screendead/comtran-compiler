/// The environment binder (M3 stage 1, design note M3-11): records
/// bind to files before storage is final.
///
/// Stage 1 covers what needs no procedure walk: FILE-card record
/// resolution, the BLOCKSIZE checks (D7.1; D10.8), SPECIF file
/// resolution, the BCD-output mode check, and the located-or-
/// transmitted classification (J 02.07.03; J 02.07.05). The
/// procedure-referencing binder rows (msgs 9, 10, 17, 19, 195, 198)
/// and the POOL/GROUP buffer minimums land with stage 2's resolution.
library;

import '../ast/data_ast.dart';
import '../ast/environment_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/token.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'mapper.dart';

/// Binds one job's environment cards to its mapped data division.
final class EnvironmentBinder {
  EnvironmentBinder(this.diagnostics, this.mapper);

  final List<Diagnostic> diagnostics;
  final DataMapper mapper;

  /// One entry per RECORD-typed item, source order.
  final List<RecordInfo> records = [];

  final Map<String, RecordInfo> _recordByName = {};
  final Map<String, FileCard> _fileByName = {};

  /// Files whose FILE card the binder rejected (msg 931): their
  /// bindings are void.
  final Set<FileCard> _rejected = Set.identity();

  void bind(List<EnvironmentCard> cards) {
    for (final DataItem item in mapper.items) {
      if (item.typeCode == DataTypeCode.record) {
        final record = RecordInfo(item, item.entry.name);
        records.add(record);
        // Record names must be unique (D2.5); uniqueness itself is
        // stage 2's check, so the first declaration wins here.
        _recordByName.putIfAbsent(record.name, () => record);
      }
    }
    final List<FileCard> files = cards.whereType<FileCard>().toList();
    for (final file in files) {
      if (file.spec.name.isNotEmpty) {
        _fileByName.putIfAbsent(file.spec.name, () => file);
      }
    }
    files.forEach(_bindFile);
    for (final SpecifCard specif in cards.whereType<SpecifCard>()) {
      final Token? fileName = specif.fileName;
      if (fileName != null && !_fileByName.containsKey(fileName.text)) {
        // A SPECIF modifies one FILE card (J 02.06.08).
        diagnostics.report(
          msgNameIsNotFile,
          fileName,
          operands: [fileName.text],
        );
      }
    }
    _classifyRecords(files);
    for (final file in files) {
      _checkBlocksizeFit(file);
      _checkOutputMode(file);
    }
  }

  /// The records a FILE card's clauses bound, per card.
  final Map<FileCard, List<RecordInfo>> _bound = Map.identity();

  void _bindFile(FileCard file) {
    _bound[file] = [];
    final int? blocksize = file.blocksize;
    if (blocksize != null && blocksize > 9999) {
      // "Maximum blocksize is 9999 words" (J 02.06.04); no message
      // is attested for the excess (D7.1).
      diagnostics.reportAt(msgBlocksizeOverMaximum, file.spec.cards.first);
      _rejected.add(file);
      return;
    }
    if (file.records.isEmpty && file.direction != FileDirection.checkpoint) {
      diagnostics.reportAt(
        msgFileCardLacksRecord,
        file.spec.cards.first,
        operands: [file.spec.name],
      );
    }
    for (final FileRecordClause clause in file.records) {
      final RecordInfo? record = _recordByName[clause.name.text];
      if (record == null) {
        if (mapper.itemsNamed(clause.name.text).isNotEmpty) {
          diagnostics.report(
            msgFileNameNotRecord,
            clause.name,
            operands: [file.spec.name, clause.name.text],
          );
        } else {
          diagnostics.report(
            msgFileRecordUndeclared,
            clause.name,
            operands: [file.spec.name],
          );
        }
        continue;
      }
      _bound[file]!.add(record);
      switch (file.direction) {
        case FileDirection.input:
          if (record.inputFiles.isNotEmpty) {
            diagnostics.report(
              msgRecordOnTwoInputFiles,
              clause.name,
              operands: [file.spec.name, record.name],
            );
          }
          record.inputFiles.add(file.spec.name);
        case FileDirection.output:
          record.outputFiles.add(file.spec.name);
        case FileDirection.checkpoint:
          break;
      }
    }
  }

  /// Locate or transmit is a property of the file, not of the record:
  /// its triggers are FILE-card options (J 02.07.03) and a forced
  /// record takes its file-mates with it (J 02.07.05 c-ii). A record
  /// named by two input files is already msg 11 (J 02.07.04), so the
  /// forced mode is not carried on past it (M3-11 reconstruction).
  void _classifyRecords(List<FileCard> files) {
    for (final RecordInfo record in records) {
      // Output-only and unfiled records take program storage.
      record
        ..variable = subtreeOf(record.item).any(
          (DataItem item) => mapper.semantics[item]?.variableLength ?? false,
        )
        ..located = record.inputFiles.isNotEmpty;
    }
    for (final file in files) {
      if (file.direction != FileDirection.input) {
        continue;
      }
      final List<RecordInfo> bound = _bound[file] ?? const [];
      // "The 'transmit' mode is triggered by the selection of the
      // SPANS, HOLD or CARD options on the Environment FILE card"
      // (J 02.07.03), and "all input records containing arrays will
      // be processed in the transmit mode by the field test
      // processor" (J 90.01.01).
      bool transmits =
          file.holdOrSpans || file.card || bound.any(_containsArray);
      if (!transmits && bound.any(_sharedByRedef)) {
        transmits = true;
        for (final record in bound) {
          record.forcedTransmit = true;
        }
        // Only a file that was to be located announces the change
        // (J 02.07.05 c-ii).
        diagnostics.reportAt(
          msgRecordsForcedTransmit,
          file.spec.cards.first,
          operands: [file.spec.name],
        );
      }
      if (!transmits) {
        continue; // "'Locate' is assumed" (J 02.07.03).
      }
      for (final record in bound) {
        record.located = false;
      }
    }
  }

  bool _containsArray(RecordInfo record) =>
      subtreeOf(record.item).any((DataItem item) {
        final ItemSemantics? s = mapper.semantics[item];
        return s != null && (s.quantity > 1 || s.variableLength);
      });

  /// Whether a REDEF shares [record]'s area with data other than
  /// records (J 02.07.05 c-ii). Records REDEF'd together stay
  /// located: the same-file case by J 02.07.05 c-iii, the cross-file
  /// case because its transmission is a deferred feature — "Records
  /// from different files which have been REDEF'd together will not
  /// be automatically transmitted by the field test processor"
  /// (J 90.01.01; SPANS or HOLD is the programmer's duty there).
  bool _sharedByRedef(RecordInfo record) {
    final DataItem? root = mapper.semantics[record.item]!.spaceRoot;
    if (!identical(root, record.item) &&
        (root == null || root.typeCode != DataTypeCode.record)) {
      return true; // The record overlays data other than a record.
    }
    for (final (DataItem target, DataItem head) in mapper.redefLinks) {
      if (!identical(mapper.semantics[target]!.spaceRoot, root)) {
        continue;
      }
      if (head.typeCode != DataTypeCode.record) {
        return true;
      }
    }
    return false;
  }

  void _checkBlocksizeFit(FileCard file) {
    if (_rejected.contains(file)) {
      return;
    }
    int? blocksize = file.blocksize;
    if (blocksize == null) {
      return; // The absence drew msg 89 at M2 (D10.8).
    }
    if (file.card && file.direction == FileDirection.input && blocksize < 24) {
      // "All input card files must have a block size of at lease 24
      // words" (J 02.06.04, spelling as printed); 24 is used.
      diagnostics.reportAt(
        msgInsufficientBlocksize,
        file.spec.cards.first,
        operands: [file.spec.name],
      );
      blocksize = 24;
    }
    if (file.holdOrSpans) {
      return; // Records may span blocks; no fit to check (msg 5).
    }
    for (final RecordInfo record in _bound[file] ?? const <RecordInfo>[]) {
      final int? extent = mapper.rootExtent[record.item];
      if (extent == null) {
        continue;
      }
      final int words = (extent + 5) ~/ 6;
      if (words > blocksize) {
        diagnostics.reportAt(
          msgRecordExceedsBlocksize,
          file.spec.cards.first,
          operands: [file.spec.name, record.name],
        );
      }
    }
  }

  void _checkOutputMode(FileCard file) {
    if (_rejected.contains(file) ||
        file.binary ||
        file.direction != FileDirection.output) {
      return;
    }
    for (final RecordInfo record in _bound[file] ?? const <RecordInfo>[]) {
      final bool binaryContents = subtreeOf(record.item).any((DataItem item) {
        final ItemSemantics? s = mapper.semantics[item];
        return s != null &&
            (s.fieldClass == FieldClass.internalDecimal ||
                s.fieldClass == FieldClass.floatingPoint);
      });
      if (binaryContents) {
        // Internal mode means binary form (J 02.05.04).
        diagnostics.reportAt(msgBinaryDataOnBcdTape, file.spec.cards.first);
      }
    }
  }
}
