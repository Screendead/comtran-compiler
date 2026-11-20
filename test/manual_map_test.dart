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

  test('every entry lands on a heading of a file the map covers', () {
    for (final MapEntry<String, Object?> row in sections.entries) {
      final entry = row.value! as Map<String, Object?>;
      final file = entry['file']! as String;
      expect(headings, contains(file), reason: row.key);
      final slugs = <String>{
        for (final Object? heading in headings[file]! as List<Object?>)
          (heading! as Map<String, Object?>)['slug']! as String,
      };
      expect(slugs, contains(entry['slug']), reason: '${row.key} in $file');
    }
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

  test('a heading slugs as github-slugger slugs it', () {
    for (final (String heading, String slug) in [
      ('Character Set', 'character-set'),
      ('02.05 Data Description', '0205-data-description'),
      ('What Is a Data Processing System?', 'what-is-a-data-processing-system'),
      ('*FILE Card', 'file-card'),
      ('A. The MOVE Statement — Form 1', 'a-the-move-statement--form-1'),
      ('snake_case name', 'snake_case-name'),
      ('32766 vs 2¹⁵−1', '32766-vs-21'),
      ('Café', 'café'),
      (plainHeading(r'\*FILE Card'), 'file-card'),
    ]) {
      expect(slugify(heading), slug, reason: heading);
    }
    expect(plainHeading(r'A. The \*FILE Card'), 'A. The *FILE Card');
    expect(plainHeading('**Bold** heading ##'), 'Bold heading');
  });

  test(
    'a repeated slug takes the next free suffix, as github-slugger does',
    () {
      final slugger = Slugger();
      expect(
        [
          for (final heading in ['Notes', 'Notes', 'NOTES', 'Other', 'Notes 1'])
            slugger.slug(heading),
        ],
        ['notes', 'notes-1', 'notes-2', 'other', 'notes-1-1'],
      );
    },
  );
}
