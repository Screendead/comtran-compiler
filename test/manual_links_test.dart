import 'dart:io';

import 'package:test/test.dart';

import '../tool/linkify_manual_refs.dart';

/// The repository-relative path of [target], a definition target read in
/// a file that sits in [directory]. Every `..` step is removed.
String resolveTarget(String directory, String target) {
  final segments = <String>[];
  for (final part in <String>[...directory.split('/'), ...target.split('/')]) {
    if (part.isEmpty || part == '.') {
      continue;
    }
    if (part == '..') {
      segments.removeLast();
    } else {
      segments.add(part);
    }
  }
  return segments.join('/');
}

/// A three-entry map, enough to exercise the skip rules.
final ManualMap sampleMap = (
  targets: <String, ManualTarget>{
    'J:02.03.02': (
      file: 'comtran-manuals/J28-6169/02-compiler.md',
      slug: 'a-use-of-coding-forms',
    ),
    'F:115': (
      file: 'comtran-manuals/F28-8043/a2-supplementary-information.md',
      slug: 'appendix-2-supplementary-information',
    ),
    'F:42': (
      file: 'comtran-manuals/F28-8043/03-procedure-description.md',
      slug: 'data-transmission-commands',
    ),
  },
  headingSlugs: <String, Set<String>>{},
);

String sweep(String markdown) => linkifyMarkdown(
  markdown: markdown,
  directory: 'docs/design',
  map: sampleMap,
);

void main() {
  final ManualMap map = loadManualMap();
  final List<String> files = markdownFiles();

  test('the sweep is fresh: the tool would change no file', () {
    // Run `dart run tool/linkify_manual_refs.dart` after any edit that
    // adds, moves or removes a manual citation.
    for (final path in files) {
      final String text = File(path).readAsStringSync();
      expect(
        linkifyMarkdown(markdown: text, directory: directoryOf(path), map: map),
        text,
        reason: path,
      );
    }
  });

  test('every generated definition names a file and an anchor that exist', () {
    var checked = 0;
    for (final path in files) {
      final String text = File(path).readAsStringSync();
      final Set<String> bracketed = {
        for (final RegExpMatch m in RegExp(r'\[([^\[\]]*)\]').allMatches(text))
          m[1]!,
      };
      linkBlockDefinitions(text).forEach((String label, String target) {
        final List<String> parts = target.split('#');
        expect(parts, hasLength(2), reason: '$path: $label');
        final String file = resolveTarget(directoryOf(path), parts[0]);
        expect(File(file).existsSync(), isTrue, reason: '$path: $label');
        expect(
          map.headingSlugs[file],
          contains(parts[1]),
          reason: '$path: $label',
        );
        expect(bracketed, contains(label), reason: '$path: $label');
        checked++;
      });
    }
    expect(checked, greaterThan(400));
  });

  test('the two manuals are both linked, and the sweep covers the docs', () {
    expect(files, contains('docs/comtran-language-definition.md'));
    expect(files, contains('docs/design/decisions.md'));
    expect(files.where((String p) => p.startsWith('comtran-manuals')), isEmpty);
    final Map<String, String> definitions = linkBlockDefinitions(
      File('docs/design/decisions.md').readAsStringSync(),
    );
    expect(definitions.keys, contains('J 90.05'));
    expect(definitions.keys, contains('F p. 42'));
  });

  test('a citation in running text becomes a shortcut reference link', () {
    expect(
      sweep('See J 02.03.02 and F p. 42.\n'),
      startsWith('See [J 02.03.02] and [F p. 42].\n'),
    );
    const target = '../../comtran-manuals/J28-6169/02-compiler.md';
    expect(
      sweep('See J 02.03.02.\n'),
      contains('[J 02.03.02]: $target#a-use-of-coding-forms\n'),
    );
  });

  test('a citation after the closer of an earlier quotation is linked', () {
    expect(
      sweep('the message says go." (J 02.03.02)\n'),
      contains('go." ([J 02.03.02])'),
    );
    expect(
      sweep('or display medium” (F p. 42).\n'),
      contains('medium” ([F p. 42]).'),
    );
  });

  test('a page range links whole', () {
    expect(
      sweep('F pp. 42-44 names a range.\n'),
      startsWith('[F pp. 42-44] names a range.\n'),
    );
  });

  test('a page list links item by item', () {
    final String once = sweep('F pp. 42, 115–116, 42 lists pages.\n');
    expect(once, startsWith('[F pp. 42], [115–116], [42] lists pages.\n'));
    expect(
      linkBlockDefinitions(once).keys,
      unorderedEquals(<String>['F pp. 42', '115–116', '42']),
    );
    expect(sweep(once), once);
  });

  test('a linked page item the map lacks gets no definition', () {
    final String swept = sweep('[F pp. 42], [116] was linked by hand.\n');
    expect(linkBlockDefinitions(swept).keys, <String>['F pp. 42']);
  });

  test('a second run changes nothing, block and all', () {
    const source = '''
J 02.03.02 opens the sweep, F p. 42 closes it.

A repeat of J 02.03.02 shares one definition.
''';
    final String once = sweep(source);
    expect(sweep(once), once);
    expect(once, endsWith('#a-use-of-coding-forms\n'));
    expect('\n$once'.split('\n$linkBlockMarker'), hasLength(2));
  });

  test('a citation stays plain where it may be verbatim or cannot link', () {
    for (final plain in <String>[
      '`J 02.03.02` sits in a code span.\n',
      '"A quotation of J 02.03.02 and of F p. 42."\n',
      '> A blockquote of J 02.03.02.\n',
      '“A curly quotation of J 02.03.02.”\n',
      'A table of contents entry: [7.2 The card of J 02.03.02](#7-2).\n',
      'continues J 02.03.02 here" and ends.\n',
      '```text\nJ 02.03.02 and F p. 42 are punched here.\n```\n',
      'J 90.06, J28-6169 02.01 and Appendix 90.04.\n',
      'F pp. 42, 116 names an unmapped page.\n',
      'F p. 42, 115 opens with one page.\n',
      'F pp. 42, 115(a) runs into a subsection.\n',
      'F pp. 42, 115, 1960s runs into other text.\n',
      'J 02.03.02: the coding form.\n',
      'J 02.03.02(a) names a subsection.\n',
    ]) {
      expect(sweep(plain), plain, reason: plain);
    }
  });
}
