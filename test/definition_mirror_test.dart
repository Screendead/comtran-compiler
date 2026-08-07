import 'dart:io';

import 'package:test/test.dart';

import '../tool/definition_mirror_source.dart';

void main() {
  final Map<String, String> regenerated = buildDefinitionMirror();

  test('the committed mirror equals a fresh generation, byte for byte', () {
    // Run `dart run tool/generate_definition_mirror.dart` after any change
    // to the language definition or to the generator.
    for (final MapEntry<String, String> entry in regenerated.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
      expect(file.readAsStringSync(), entry.value, reason: entry.key);
    }
  });

  test('the mirror directory holds nothing the generator does not write', () {
    final List<String> committed =
        Directory(
            mirrorDirectory,
          ).listSync().whereType<File>().map((File file) => file.path).toList()
          ..sort();
    expect(committed, regenerated.keys.toList());
  });

  test('every part carries the banner and stays under the render limit', () {
    for (final MapEntry<String, String> entry in regenerated.entries) {
      expect(entry.value, startsWith(mirrorBanner), reason: entry.key);
      expect(
        entry.value.length,
        lessThan(512 * 1024),
        reason: '${entry.key} would not render on GitHub',
      );
    }
  });

  test('the index holds the F/J rule, which other documents link to', () {
    final String index = regenerated['$mirrorDirectory/$mirrorIndex']!;
    for (final String heading in indexSections) {
      expect(index, contains('## $heading'));
    }
  });

  test('no anchor link points at a heading the mirror does not hold', () {
    final anchors = RegExp(r'\]\((?:([\w.-]+\.md))?#([^)]+)\)');
    final headings = <String, Set<String>>{};
    for (final MapEntry<String, String> entry in regenerated.entries) {
      headings[entry.key.split('/').last] = _slugsOf(entry.value);
    }
    for (final MapEntry<String, String> entry in regenerated.entries) {
      final String self = entry.key.split('/').last;
      for (final RegExpMatch match in anchors.allMatches(entry.value)) {
        final String file = match[1] ?? self;
        expect(
          headings[file],
          contains(match[2]),
          reason: '${entry.key} links to $file#${match[2]}',
        );
      }
    }
  });
}

/// Every heading anchor in [markdown], by the same rule the generator uses.
Set<String> _slugsOf(String markdown) {
  final heading = RegExp(r'^#{1,6} +(.*)$');
  final fence = RegExp('^ {0,3}```');
  final slugs = <String>{};
  var fenced = false;
  for (final String line in markdown.split('\n')) {
    if (fence.hasMatch(line)) {
      fenced = !fenced;
    } else if (!fenced) {
      final RegExpMatch? match = heading.firstMatch(line);
      if (match != null) {
        slugs.add(slugifyHeading(match[1]!));
      }
    }
  }
  return slugs;
}
