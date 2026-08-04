/// The D9.3 conformance-checklist gate: every message id 0,00–209,00
/// plus the 900-series has a disposition in
/// `docs/design/message-checklist.tsv`, every enforced id has a live
/// test, and the checklist cannot drift from the catalog, the severity
/// table, or the compiler's message tables.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

/// One checklist row.
typedef Row = ({
  String id,
  String severityClass,
  String disposition,
  String component,
  String b2,
  String testRef,
  String note,
  String text,
});

/// The messages of ours (900-series), keyed by id.
final Map<String, Message> _ours = {
  for (final Message m in [
    msgStrayPeriod,
    msgNameTooLong,
    msgTextBeforeHeader,
    msgCardAfterFinish,
    msgDuplicateCompileCard,
    msgPatternNotImplemented,
    msgDataCardCodingConflict,
    msgTypeCodeNotInLanguage,
    msgQuantityOutOfRange,
    msgUnknownCompileOption,
    msgSubscriptedConditionName,
    msgAtEndNotTransfer,
    msgAlphamericArithOperand,
    msgUnparenthesizedPower,
    msgTooManySubscripts,
    msgSectionsTooDeep,
    msgDeferredVerb,
    msgFunctionArgumentDropped,
    msgRedefNameDiscarded,
    msgConstantContinuesAcrossCards,
    msgProcedureNamePeriodOmitted,
    msgRedefNameRejected,
    msgAtEndNotTransferRejected,
    msgDeckNameImbeddedBlanks,
    msgInputFileCommaOmitted,
    msgCondKeyUnderLength,
    msgCommaBeforeOtherwise,
    msgAtEndWithoutComma,
    msgTrailingCommaBeforePeriod,
    msgJobClosedByCompileCard,
    msgQuantityNestedTooDeep,
    msgBlocksizeOverMaximum,
    msgRecordsForcedTransmit,
    msgMixedPictorialDowngraded,
    msgQuantityOnUnnamedEntry,
    msgIneffectiveRightJustification,
    msgCallOldNameSubscripted,
    msgPoolBufferCountRaised,
    msgGroupBufferCountRaised,
    msgGroupLacksPool,
    msgLabelAreaTooLong,
    msgFieldAfterVariableArray,
    msgDictionaryCapacity,
    msgDoubtfulFigurativeUsage,
    msgCorrespondingMatchesNothing,
    msgCallOldNameIsRecord,
  ])
    m.number: m,
};

/// D9.15 group (b): media and hardware failures that cannot occur in
/// this implementation.
const Set<String> _unreachable = {
  '85,00',
  '135,00',
  '136,00',
  '137,00',
  '140,00',
};

void main() {
  final List<String> lines = File(
    'docs/design/message-checklist.tsv',
  ).readAsLinesSync();
  if (lines.first !=
      'id\tclass\tdisposition\tcomponent\tb2\ttest\tnote\ttext') {
    throw StateError('unexpected checklist header: ${lines.first}');
  }
  final Map<String, Row> rows = {};
  for (final String line in lines.skip(1)) {
    final List<String> cells = line.split('\t');
    if (cells.length != 8) {
      throw StateError('malformed checklist row: $line');
    }
    final ({
      String b2,
      String component,
      String disposition,
      String id,
      String note,
      String severityClass,
      String testRef,
      String text,
    })
    row = (
      id: cells[0],
      severityClass: cells[1],
      disposition: cells[2],
      component: cells[3],
      b2: cells[4],
      testRef: cells[5],
      note: cells[6],
      text: cells[7],
    );
    if (rows.containsKey(row.id)) {
      throw StateError('duplicate checklist row ${row.id}');
    }
    rows[row.id] = row;
  }

  test('covers ids 0,00-209,00 and the 900 series exactly once', () {
    final expected = <String>{
      for (var i = 0; i <= 209; i++) '$i,00',
      ...messageSeverities.keys.where(
        (String id) => int.parse(id.split(',').first) >= 900,
      ),
    };
    expect(rows.keys.toSet(), expected);
  });

  test('every id has a disposition (D9.3 gate)', () {
    for (final Row row in rows.values) {
      expect(
        const {'enforced', 'reserved', 'unreachable'},
        contains(row.disposition),
        reason: '${row.id} has no disposition',
      );
      expect(row.component, isNotEmpty, reason: '${row.id} lacks a component');
    }
  });

  test('texts are the verbatim catalog texts', () {
    for (final Row row in rows.values) {
      final Message? message = messageCatalog[row.id] ?? _ours[row.id];
      expect(message, isNotNull, reason: '${row.id} is not a known message');
      expect(
        row.text.replaceAll(r'\n', '\n'),
        message!.text,
        reason: '${row.id} text differs from the catalog',
      );
    }
  });

  test('classes match the severity table', () {
    for (final Row row in rows.values) {
      expect(
        row.severityClass,
        'C${messageSeverities[row.id]}',
        reason: '${row.id} class differs from severities.dart',
      );
    }
  });

  test('the enforced set equals the compiler message tables', () {
    // A message id is enforced exactly when one of the two message
    // tables binds it to a constant; the next test proves the constant
    // is issued somewhere.
    final tables = <String, String>{
      for (final path in [
        'lib/src/data/data_messages.dart',
        'lib/src/lexer/messages.dart',
        'lib/src/parser/parser_messages.dart',
      ])
        path: File(path).readAsStringSync(),
    };
    final ids = <String>{};
    final idPattern = RegExp(
      r"(?:messageCatalog\['(\d+,\d+)'\]|Message(?:\.ours)?\(\s*'(\d+,\d+)')",
    );
    for (final String source in tables.values) {
      for (final Match m in idPattern.allMatches(source)) {
        ids.add(m.group(1) ?? m.group(2)!);
      }
    }
    final enforced = <String>{
      for (final Row row in rows.values)
        if (row.disposition == 'enforced') row.id,
    };
    expect(
      enforced,
      ids,
      reason: 'the checklist enforced set must match the message tables',
    );
  });

  test('every message-table constant is issued in lib or bin', () {
    final constantPattern = RegExp('Message (msg[A-Za-z0-9]+) =');
    final Iterable<File> sources = [Directory('lib/src'), Directory('bin')]
        .expand(
          (Directory d) => d
              .listSync(recursive: true)
              .whereType<File>()
              .where((File f) => f.path.endsWith('.dart')),
        );
    final Map<String, String> byPath = {
      for (final File f in sources) f.path: f.readAsStringSync(),
    };
    for (final path in [
      'lib/src/data/data_messages.dart',
      'lib/src/lexer/messages.dart',
      'lib/src/parser/parser_messages.dart',
    ]) {
      for (final Match m in constantPattern.allMatches(byPath[path]!)) {
        final String constant = m.group(1)!;
        final bool used = byPath.entries.any(
          (MapEntry<String, String> e) =>
              e.key != path && e.value.contains(constant),
        );
        expect(used, isTrue, reason: '$constant is defined but never issued');
      }
    }
  });

  test('every enforced id names a live test', () {
    for (final Row row in rows.values) {
      if (row.disposition != 'enforced') {
        continue;
      }
      expect(row.testRef, contains(': '), reason: '${row.id} lacks a test');
      final int split = row.testRef.indexOf(': ');
      final String path = row.testRef.substring(0, split);
      final String name = row.testRef.substring(split + 2);
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '${row.id}: $path missing');
      expect(
        file.readAsStringSync(),
        contains(name),
        reason: '${row.id}: test "$name" not found in $path',
      );
    }
  });

  test('exactly msgs 90 and 110 have no B.2 row (D9.3)', () {
    final noB2 = <String>{
      for (final Row row in rows.values)
        if (row.b2 == 'no B.2 row') row.id,
    };
    expect(noB2, {'90,00', '110,00'});
    expect(rows['90,00']!.note, contains('J 90.01.04'));
    expect(rows['110,00']!.note, contains('J 90.01.02'));
    for (final Row row in rows.values) {
      if (int.parse(row.id.split(',').first) >= 900) {
        expect(row.b2, 'ours (D9.7)', reason: row.id);
      } else {
        expect(row.b2, isNotEmpty, reason: '${row.id} lacks a B.2 citation');
      }
    }
  });

  test('the unreachable set is the D9.15 group (b)', () {
    final unreachable = <String>{
      for (final Row row in rows.values)
        if (row.disposition == 'unreachable') row.id,
    };
    expect(unreachable, _unreachable);
    for (final id in unreachable) {
      expect(rows[id]!.note, contains('D9.15'));
    }
  });
}
