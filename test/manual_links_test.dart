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

/// A two-entry map, enough to exercise the skip rules.
final ManualMap sampleMap = (
  targets: <String, ManualTarget>{
    'J:02.03.02': (
      file: 'comtran-manuals/J28-6169/02-compiler.md',
      slug: 'a-use-of-coding-forms',
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
        expect(text, contains('[$label]'), reason: '$path: $label');
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

  test('a citation stays plain where it may be verbatim manual text', () {
    const verbatim = '''
`J 02.03.02` sits in a code span.
"A quotation of J 02.03.02 and of F p. 42."
> A blockquote of J 02.03.02.
“A curly quotation of J 02.03.02.”
A table of contents entry: [7.2 The card of J 02.03.02](#7-2).
''';
    expect(sweep(verbatim), verbatim);
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

  test('a citation before the closer of an earlier quotation stays plain', () {
    const inside = 'continues J 02.03.02 here" and ends.\n';
    expect(sweep(inside), startsWith('continues J 02.03.02 here"'));
  });

  test('a citation inside a fenced code block stays plain', () {
    const fenced = '''
```text
J 02.03.02 and F p. 42 are punched here.
```
''';
    expect(sweep(fenced), fenced);
  });

  test('a citation the map cannot resolve stays plain', () {
    const unresolved = 'J 90.06, J28-6169 02.01 and Appendix 90.04.\n';
    expect(sweep(unresolved), unresolved);
  });

  test('a page list stays plain; a page range links whole', () {
    expect(sweep('F pp. 42, 115 lists two pages.\n'), startsWith('F pp. 42,'));
    expect(
      sweep('F pp. 42-44 names a range.\n'),
      startsWith('[F pp. 42-44] names a range.\n'),
    );
  });

  test('a bracket that would build a link definition is not added', () {
    const definition = 'J 02.03.02: the coding form.\n';
    expect(sweep(definition), definition);
    const inline = 'J 02.03.02(a) names a subsection.\n';
    expect(sweep(inline), inline);
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

  test('a definition target is relative to the citing file', () {
    expect(relativePath('', 'comtran-manuals/x.md'), 'comtran-manuals/x.md');
    expect(
      relativePath('docs', 'comtran-manuals/x.md'),
      '../comtran-manuals/x.md',
    );
    expect(
      relativePath('docs/design', 'comtran-manuals/x.md'),
      '../../comtran-manuals/x.md',
    );
    expect(directoryOf('docs/design/decisions.md'), 'docs/design');
    expect(directoryOf('README.md'), '');
  });

  test('definitions sort by manual, then number by number', () {
    final labels = <String>[
      'J 02.05.05',
      'F p. 10',
      'J 02.05',
      'F p. 2',
      'F pp. 2-3',
    ]..sort(compareCitationLabels);
    expect(labels, <String>[
      'F p. 2',
      'F pp. 2-3',
      'F p. 10',
      'J 02.05',
      'J 02.05.05',
    ]);
  });
}
