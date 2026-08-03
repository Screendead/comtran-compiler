import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/manual_map_source.dart';

/// The generated map, as committed.
const String mapPath = 'editors/vscode-punchcard/manual-map.json';

void main() {
  final String committed = File(mapPath).readAsStringSync();
  final String regenerated = buildManualMap();
  final map = jsonDecode(committed) as Map<String, Object?>;
  final sections = map['sections']! as Map<String, Object?>;
  final headings = map['headings']! as Map<String, Object?>;

  test('the committed map equals a fresh generation, byte for byte', () {
    // Run `dart run tool/generate_manual_map.dart` after any change to a
    // manual conversion or to the generator.
    expect(regenerated, committed);
  });

  test('the map is deterministic: sorted keys, two-space indent, newline', () {
    expect(committed, endsWith('}\n'));
    expect(committed, contains('\n  "sections": {\n'));
    final List<String> keys = sections.keys.toList();
    expect(keys, keys.toList()..sort(compareKeys));
    final List<String> files = headings.keys.toList();
    expect(files, files.toList()..sort());
  });

  test('every scan path in the map exists on disk', () {
    for (final MapEntry<String, Object?> row in sections.entries) {
      final entry = row.value! as Map<String, Object?>;
      final scan = entry['scan'] as String?;
      if (scan == null) {
        continue;
      }
      expect(File(scan).existsSync(), isTrue, reason: '${row.key} -> $scan');
      expect(entry['pdfPage'], isA<int>(), reason: row.key);
    }
  });

  test('every entry names a file that the headings section covers', () {
    for (final MapEntry<String, Object?> row in sections.entries) {
      final entry = row.value! as Map<String, Object?>;
      expect(headings, contains(entry['file']), reason: row.key);
    }
  });

  test('every slug in the map appears in the headings of its file', () {
    for (final MapEntry<String, Object?> row in sections.entries) {
      final entry = row.value! as Map<String, Object?>;
      final file = entry['file']! as String;
      final slugs = <String>{
        for (final Object? heading in headings[file]! as List<Object?>)
          (heading! as Map<String, Object?>)['slug']! as String,
      };
      expect(slugs, contains(entry['slug']), reason: '${row.key} in $file');
    }
  });

  test('a slug is unique within its file, and its line is 1-based', () {
    headings.forEach((String file, Object? rows) {
      final list = rows! as List<Object?>;
      final slugs = <String>[];
      var previous = 0;
      for (final row in list) {
        final heading = row! as Map<String, Object?>;
        final line = heading['line']! as int;
        expect(line, greaterThan(previous), reason: file);
        previous = line;
        slugs.add(heading['slug']! as String);
      }
      expect(slugs.toSet(), hasLength(slugs.length), reason: file);
    });
  });

  test('both manuals are covered, and every citation form resolves', () {
    // Section 02 of J28-6169 is the core language reference; F28-8043
    // chapter 2 starts on printed page 11 (CLAUDE.md section 8).
    for (final key in <String>[
      'J:02.04', 'J:02.05', 'J:02.06', 'J:02.07', 'J:02.08', //
      'J:02.05.05', 'J:90.02', 'J:90.04', 'J:90.05', 'J:90.08',
      'F:11', 'F:42',
    ]) {
      expect(sections, contains(key), reason: key);
    }
    // J 90.06 and 90.07 have no converted file: the manual lacks them.
    expect(sections, isNot(contains('J:90.06')));
    expect(sections, isNot(contains('J:90.07')));
  });

  test('the slugger lowercases, strips, and hyphenates', () {
    expect(slugify('Character Set'), 'character-set');
    expect(slugify('02.05 Data Description'), '0205-data-description');
    expect(
      slugify('What Is a Data Processing System?'), //
      'what-is-a-data-processing-system',
    );
    expect(slugify('*FILE Card'), 'file-card');
    expect(
      slugify('A. The MOVE Statement — Form 1'),
      'a-the-move-statement--form-1',
    );
  });

  test('a repeated slug takes -1, -2 in order of appearance', () {
    final slugger = Slugger();
    expect(slugger.slug('Notes'), 'notes');
    expect(slugger.slug('Notes'), 'notes-1');
    expect(slugger.slug('NOTES'), 'notes-2');
    expect(slugger.slug('Other'), 'other');
  });

  test('a heading loses its markdown escapes and emphasis', () {
    expect(plainHeading(r'A. The \*FILE Card'), 'A. The *FILE Card');
    expect(slugify(plainHeading(r'\*FILE Card')), 'file-card');
    expect(plainHeading('**Bold** heading ##'), 'Bold heading');
  });

  test('a scan path zero-pads the PDF page to three digits', () {
    expect(scanPath(jManualDir, 7), '$jManualDir/images/page-007.png');
    expect(scanPath(fManualDir, 122), '$fManualDir/images/page-122.png');
  });

  test('keys sort by manual, then number by number', () {
    final keys = <String>['J:02.05.05', 'F:10', 'J:02.05', 'F:2']
      ..sort(compareKeys);
    expect(keys, <String>['F:2', 'F:10', 'J:02.05', 'J:02.05.05']);
  });
}
