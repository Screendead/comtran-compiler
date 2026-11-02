import 'dart:io';

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

  test('the generated frames hold no dash (web-copy.md, rule D5)', () {
    // Whether D5 reaches the transcriptions and the reference is open
    // (web-copy.md, section 6), so only the frame around them is held to
    // it. The frames add no en dash either, so the cap in
    // test/web_copy_test.dart stays whole.
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
