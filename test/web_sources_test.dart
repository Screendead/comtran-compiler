import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

import '../tool/web_sources_source.dart';

final RegExp _link = RegExp('(?:href|src)="([^"]*)"');
final RegExp _external = RegExp('^[a-z]+:');

/// The web path that [href], on the page at web path [from], names.
String _resolve(String from, String href) {
  final int slash = from.lastIndexOf('/');
  return resolveRepoPath(slash < 0 ? '' : from.substring(0, slash), href);
}

/// Every broken link on the page at web path [from], whose text is [html].
/// [built] holds each generated page by web path; [exists] answers for
/// every other web path.
List<String> _brokenLinks(
  String from,
  String html,
  Map<String, String> built,
  bool Function(String) exists,
) {
  final broken = <String>[];
  for (final RegExpMatch match in _link.allMatches(html)) {
    final String href = match[1]!.replaceAll('&amp;', '&');
    if (_external.hasMatch(href)) {
      continue;
    }
    final int hash = href.indexOf('#');
    final String path = hash < 0 ? href : href.substring(0, hash);
    final String fragment = hash < 0 ? '' : href.substring(hash + 1);
    final String target = path.isEmpty ? from : _resolve(from, path);
    final String? page = target == from ? html : built[target];
    if (page == null && !exists(target)) {
      broken.add('$from: $href');
    } else if (fragment.isNotEmpty &&
        page != null &&
        !page.contains('id="${Uri.decodeFull(fragment)}"')) {
      broken.add('$from: $href (no anchor)');
    }
  }
  return broken;
}

void main() {
  final SourcesSite site = buildSourcesSite();
  final Set<String> copied = site.copies.values.toSet();
  bool exists(String path) =>
      copied.contains(path) || File('web/$path').existsSync();

  group('the manuals, page by page', () {
    for (final Manual manual in manuals) {
      test('${manual.id} has one page for each of its scans', () {
        final List<int> scans =
            Directory('${manual.dir}/images')
                .listSync()
                .map((FileSystemEntity e) => e.uri.pathSegments.last)
                .where((String n) => RegExp(r'^page-\d{3}\.png$').hasMatch(n))
                .map((String n) => int.parse(n.substring(5, 8)))
                .toList()
              ..sort();
        final pages = <int>[
          for (final ManualPage page in manualPages(manual)) page.pdf,
        ];
        expect(pages, scans);
        expect(scans, List<int>.generate(scans.length, (int i) => i + 1));
      });

      test('each page of ${manual.id} shows its scan and its text', () {
        for (final ManualPage page in manualPages(manual)) {
          final String? html =
              site.pages['$sourcesDir/${manual.id}/${pageName(page.pdf)}'];
          expect(html, isNotNull, reason: 'PDF page ${page.pdf}');
          expect(html, contains('<img src="${scanName(page.pdf)}"'));
          expect(
            site.copies['${manual.dir}/images/${scanName(page.pdf)}'],
            '$sourcesDir/${manual.id}/${scanName(page.pdf)}',
          );
          expect(
            page.lines.any((String l) => l.trim().isNotEmpty),
            isTrue,
            reason: '${manual.id} PDF page ${page.pdf} has no transcription',
          );
        }
      });

      test('the contents of ${manual.id} link every page', () {
        final String contents =
            site.pages['$sourcesDir/${manual.id}/index.html']!;
        for (final ManualPage page in manualPages(manual)) {
          expect(contents, contains('href="${pageName(page.pdf)}"'));
        }
      });
    }

    test('a page comment inside a fenced block does not start a page', () {
      final List<ManualPage> pages = splitManualFile('x.md', '''
# Title
<!-- page 1 | PDF 7 -->
**[page 1]**
```
<!-- page 2 | PDF 8 -->
```
<!-- 02.05.05 | PDF 9 -->
text
''');
      expect(pages.map((ManualPage p) => p.pdf), <int>[7, 9]);
      expect(pages.map((ManualPage p) => p.label), <String?>[
        'page 1',
        '02.05.05',
      ]);
      expect(pages.first.lines.first, '# Title');
      expect(pages.first.lines, contains('<!-- page 2 | PDF 8 -->'));
    });

    test('a citation link opens the page it cites', () {
      final String part = site.pages.entries
          .firstWhere(
            (MapEntry<String, String> e) =>
                e.key.startsWith('$sourcesDir/reference/01-'),
          )
          .value;
      // F p. 12 is PDF page 18, one page after the heading that holds it.
      expect(part, contains('<a href="../F28-8043/page-018.html">F p. 12</a>'));
    });
  });

  test('every link in the generated pages lands on a file', () {
    final broken = <String>[
      for (final MapEntry<String, String> entry in site.pages.entries)
        ..._brokenLinks(entry.key, entry.value, site.pages, exists),
    ];
    expect(broken, isEmpty, reason: broken.take(20).join('\n'));
  });

  test('every link on the documents page lands on a file', () {
    const from = 'sources.html';
    final String html = File('web/$from').readAsStringSync();
    expect(_brokenLinks(from, html, site.pages, exists), isEmpty);
    for (final page in <String>[
      '$sourcesDir/reference/index.html',
      for (final Manual manual in manuals) ...<String>[
        '$sourcesDir/${manual.id}/index.html',
        '$sourcesDir/${manual.id}/${manual.pdf}',
      ],
    ]) {
      expect(html, contains('href="$page"'));
    }
  });

  test('each genuine typo is marked [sic] on its page, and nothing else is '
      '(web-copy.md, rule E3)', () {
    // Each page and its typos, checked against the scans of J28-6169.
    const expected = <String, List<String>>{
      'J28-6169/page-038.html': <String>['at lease'],
      'J28-6169/page-046.html': <String>['lables', 'dinsity'],
      'J28-6169/page-066.html': <String>['Parentheis'],
      'J28-6169/page-137.html': <String>['Appox-Max'],
    };
    expect(
      expected.values.expand((List<String> words) => words).toSet(),
      typos['J28-6169']!.toSet(),
    );
    for (final MapEntry<String, String> page in site.pages.entries) {
      final List<String> words =
          expected[page.key.substring(sourcesDir.length + 1)] ??
          const <String>[];
      expect(
        sicMark.allMatches(page.value),
        hasLength(words.length),
        reason: page.key,
      );
      for (final word in words) {
        expect(page.value, contains('$word$sicMark'), reason: page.key);
      }
    }
  });

  test('a conversion note keeps a typo it names unmarked', () {
    final nodes = <md.Node>[
      md.Text('<!-- conversion notes: "Appox-Max" as printed -->'),
      md.Element('p', <md.Node>[md.Text('Appox-Max Size')]),
      md.Element('p', <md.Node>[
        md.Element('code', <md.Node>[md.Text('Appox-Max')]),
      ]),
    ];
    markTypos(nodes, typos['J28-6169']!);
    final String html = md.renderToHtml(nodes);
    expect(sicMark.allMatches(html), hasLength(1));
    expect(html, contains('<p>Appox-Max$sicMark Size</p>'));
    expect(html, contains('"Appox-Max" as printed'));
    expect(html, contains('<code>Appox-Max</code>'));
  });

  test('the generated frames hold no dash (web-copy.md, rule D5)', () {
    // The transcriptions are quotations, which E2 keeps verbatim, and
    // test/web_copy_test.dart holds the reference text to D5. This test
    // holds the frame around both. The frames add no en dash either, so the
    // cap in test/web_copy_test.dart stays whole.
    final Manual manual = manuals.first;
    final List<ManualPage> pages = manualPages(manual);
    final frames = <String>[
      pageView(
        manual: manual,
        page: pages[1],
        count: pages.length,
        previous: pages[0],
        next: pages[2],
        transcription: '',
      ),
      contentsView(
        manual: manual,
        conversionIndex: '',
        pages: const <ManualPage>[],
        chapterTitle: (String file) => file,
      ),
      referenceView(
        title: 't',
        body: '',
        previous: ('a.html', 'a'),
        next: ('b.html', 'b'),
      ),
    ];
    for (final frame in frames) {
      expect(frame, isNot(contains('—')));
      expect(frame, isNot(contains('–')));
    }
  });
}
