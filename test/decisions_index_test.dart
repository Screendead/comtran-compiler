import 'dart:io';

import 'package:test/test.dart';

import '../tool/manual_map_source.dart' show Slugger, plainHeading;

/// The decision slate. Its Contents index is kept by hand under the two
/// maintenance rules it states; this guard checks them.
const String path = 'docs/design/decisions.md';

final RegExp _heading = RegExp(r'^#{1,6} (.+)$');
final RegExp _record = RegExp(r'^### (D\d+\.\d+) — ');
final RegExp _section = RegExp(r'^## (D\d+) — ');
final RegExp _d0Item = RegExp(r'^\*\*(D0\.\d+) ');
final RegExp _status = RegExp(r'^\*\*Status\.\*\* (.+)$');
final RegExp _row = RegExp(r'^\| (\*\*)?\[(D[\d.]+)[^\]]*\]\(#([^)]+)\)');
final RegExp _amendment = RegExp(r'^(?:> )?\*{1,2}Amended');

/// The four statuses of the Contents table.
const List<String> statuses = ['Locked', "Jack's call", 'Amended', 'Deferred'];

/// The status a record's **Status.** line states. A line that names its
/// amendment after the first status (`Locked; amended`, `Jack's call,
/// 2026-08-02; amended`) names a record a later amendment changed, which
/// the Contents table calls Amended.
String statusOf(String line) {
  if (line.contains('; amended')) {
    return 'Amended';
  }
  return statuses.firstWhere(
    (String s) => line.startsWith(s),
    orElse: () => throw StateError('unknown status line: $line'),
  );
}

/// The status an index row states. A parenthesised qualifier after the
/// status names the part it covers, as in `Jack's call (part d)`.
String rowStatusOf(String cell) =>
    cell.replaceFirst(RegExp(r' \(.*\)$'), '').trim();

class _Row {
  _Row(this.id, this.anchor, this.status, {required this.isSection});
  final String id;
  final String anchor;
  final String status;
  final bool isSection;
}

void main() {
  final List<String> lines = File(path).readAsLinesSync();

  final sectionAnchor = <String, String>{};
  final recordAnchor = <String, String>{};
  final recordStatus = <String, String>{};
  final amendedRecords = <String>{};
  final d0Items = <String>[];
  String? d0Status;
  final slugger = Slugger();
  String? current;
  var inContents = false;
  final rows = <_Row>[];

  for (final line in lines) {
    final Match? heading = _heading.firstMatch(line);
    if (heading != null) {
      final String anchor = slugger.slug(plainHeading(heading[1]!));
      inContents = line == '## Contents';
      current = null;
      final Match? record = _record.firstMatch(line);
      final Match? section = _section.firstMatch(line);
      if (record != null) {
        current = record[1];
        recordAnchor[current!] = anchor;
      } else if (section != null) {
        current = section[1];
        sectionAnchor[current!] = anchor;
      }
      continue;
    }
    final Match? row = _row.firstMatch(line);
    if (inContents && row != null) {
      final List<String> cells = line.split('|');
      final String status = cells[cells.length - 2].trim();
      rows.add(_Row(row[2]!, row[3]!, status, isSection: row[1] != null));
      continue;
    }
    final Match? item = _d0Item.firstMatch(line);
    if (current == 'D0' && item != null) {
      d0Items.add(item[1]!);
    }
    if (current != null && current != 'D0' && _amendment.hasMatch(line)) {
      amendedRecords.add(current);
    }
    final Match? status = _status.firstMatch(line);
    if (current != null && status != null) {
      if (current == 'D0') {
        d0Status ??= status[1];
      } else {
        recordStatus.putIfAbsent(current, () => status[1]!);
      }
    }
  }

  final List<_Row> recordRows = rows.where((_Row r) => !r.isSection).toList();

  test('the file is where the guard reads it', () {
    expect(recordAnchor, isNotEmpty);
    expect(d0Items, isNotEmpty);
    expect(recordRows, isNotEmpty);
  });

  test('every record has exactly one index row, and every row a record', () {
    final List<String> ids = recordRows.map((_Row r) => r.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'a record has two rows');
    expect(ids.toSet(), {...d0Items, ...recordAnchor.keys});
  });

  test('every section has one bold index row', () {
    final List<String> ids = rows
        .where((_Row r) => r.isSection)
        .map((_Row r) => r.id)
        .toList();
    expect(ids, sectionAnchor.keys.toList());
  });

  test('every index anchor lands on its own heading', () {
    for (final r in rows) {
      final String? want = r.isSection
          ? sectionAnchor[r.id]
          : r.id.startsWith('D0.')
          ? sectionAnchor['D0']
          : recordAnchor[r.id];
      expect(r.anchor, want, reason: r.id);
    }
  });

  test('every record states its status, and its row agrees', () {
    for (final r in recordRows) {
      if (r.id.startsWith('D0.')) {
        expect(d0Status, startsWith('Every item in this section is locked'));
        expect(r.status, 'Locked', reason: r.id);
        continue;
      }
      final String? line = recordStatus[r.id];
      expect(line, isNotNull, reason: '${r.id} has no Status line');
      expect(rowStatusOf(r.status), statusOf(line!), reason: r.id);
    }
  });

  test('a record with an amendment note says so on its Status line', () {
    expect(amendedRecords, isNotEmpty);
    for (final id in amendedRecords) {
      expect(statusOf(recordStatus[id]!), 'Amended', reason: id);
    }
  });

  test('a section row carries no status', () {
    for (final _Row r in rows.where((_Row r) => r.isSection)) {
      expect(r.status, isEmpty, reason: r.id);
    }
  });
}
