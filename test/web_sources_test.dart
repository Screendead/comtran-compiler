import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

import '../tool/web_sources_source.dart';
import 'support/quoted_titles.dart';

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

final RegExp _tag = RegExp('<[^>]*>');

/// Spans of a reference page whose em dashes D5 leaves alone: code, a block
/// quotation, and a table cell that holds the mark alone as "none".
final List<RegExp> _keptBlocks = <RegExp>[
  RegExp('<pre>.*?</pre>', dotAll: true),
  RegExp('<code>.*?</code>', dotAll: true),
  RegExp('<blockquote>.*?</blockquote>', dotAll: true),
  RegExp(r'<td>\s*—\s*</td>'),
];

/// The end of a block of text in the rendered HTML.
final RegExp _blockEnd = RegExp('</(?:p|li|td|th|dt|dd|div|nav)>');

/// A quotation inside a line of prose.
final RegExp _quotation = RegExp('"[^"\n]*"|“[^”\n]*”');

/// A citation inside a parenthesis: a manual page or section, a listing
/// statement, or an external source.
final RegExp _citation = RegExp(
  r'\b[FJ] (?:pp?\. |st\. |\d\d\.)|\bexternal: |\bPDF pp?\. ',
);

/// [text] with every tag removed and the entities the renderer writes
/// turned back into characters.
String _plain(String text) => text
    .replaceAll(_tag, '')
    .replaceAll('&quot;', '"')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

/// Whether offset [at] of [line] lies inside a parenthesis that holds a
/// citation. The language definition keeps the dashes there, because a
/// change of punctuation could move what the citation attaches to.
bool _inCitation(String line, int at) {
  var depth = 0;
  for (int i = at - 1; i >= 0; i--) {
    if (line[i] == ')') {
      depth++;
    } else if (line[i] == '(') {
      if (depth > 0) {
        depth--;
        continue;
      }
      var end = at;
      var inner = 0;
      while (end < line.length) {
        if (line[end] == '(') {
          inner++;
        } else if (line[end] == ')') {
          if (inner == 0) {
            break;
          }
          inner--;
        }
        end++;
      }
      if (_citation.hasMatch(line.substring(i, end))) {
        return true;
      }
    }
  }
  return false;
}

/// The em dashes of the reference page [html] that no rule keeps, each with
/// its line, and the count of those a citation parenthesis keeps.
({List<String> stray, int cited}) _dashes(String html) {
  var text = html;
  for (final RegExp kept in _keptBlocks) {
    text = text.replaceAll(kept, '');
  }
  // One line per block, so a quotation that runs across a line break in
  // its paragraph stays one quotation.
  text = text
      .replaceAll('\n', ' ')
      .replaceAllMapped(_blockEnd, (Match m) => '${m[0]}\n');
  final stray = <String>[];
  var cited = 0;
  for (String line in _plain(text).split('\n')) {
    line = unquoted(line);
    line = line.replaceAllMapped(_quotation, (Match m) => ' ' * m[0]!.length);
    for (int at = line.indexOf('—'); at >= 0; at = line.indexOf('—', at + 1)) {
      if (_inCitation(line, at)) {
        cited++;
      } else {
        stray.add(line.trim());
      }
    }
  }
  return (stray: stray, cited: cited);
}

/// The em dashes the language reference keeps inside citation parentheses,
/// counted across its built pages. Like the en dash cap, this is a ratchet:
/// lower it as citations lose their dashes, and never raise it without a
/// ruling.
const int citationDashCap = 42;

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

  test('every occurrence of a listed typo carries [sic], and nothing else '
      'does (web-copy.md, rule E3)', () {
    // A typo the list leaves out cannot fail here: the list in
    // tool/web_sources_source.dart is the one record of which words are
    // typos. A mark goes on transcribed prose only, so notes, code and tags
    // come out before the count.
    final skip = RegExp(
      r'<!--.*?-->|<pre\b.*?</pre>|<code\b.*?</code>|<[^>]*>',
      dotAll: true,
    );
    final unmarked = <String>[];
    final seen = <String>{};
    for (final MapEntry<String, String> page in site.pages.entries) {
      final String id = page.key.substring(sourcesDir.length + 1).split('/')[0];
      final List<String> words = typos[id] ?? const <String>[];
      if (words.isEmpty) {
        expect(sicMark.allMatches(page.value), isEmpty, reason: page.key);
        continue;
      }
      final String prose = page.value
          .replaceAll(sicMark, '')
          .replaceAll(skip, '');
      var marked = 0;
      for (final word in words) {
        final pattern = RegExp(
          '(?<![A-Za-z])${RegExp.escape(word)}(?![A-Za-z])',
        );
        final int printed = pattern.allMatches(prose).length;
        final int hits = '$word$sicMark'.allMatches(page.value).length;
        if (hits != printed) {
          unmarked.add('${page.key}: $word printed $printed, marked $hits');
        }
        if (hits > 0) {
          seen.add('$id $word');
        }
        marked += hits;
      }
      expect(
        sicMark.allMatches(page.value),
        hasLength(marked),
        reason: page.key,
      );
    }
    expect(unmarked, isEmpty, reason: unmarked.join('\n'));
    expect(seen, <String>{
      for (final MapEntry<String, List<String>> entry in typos.entries)
        for (final word in entry.value) '${entry.key} $word',
    });
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
    // The transcriptions are quotations, which E2 keeps verbatim, and the
    // reference test above holds the reference text to D5. This test holds
    // the frame around both. The frames add no en dash either, so the
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
  test('the language reference holds no stray em dash (web-copy.md, D5)', () {
    final pages = <String, String>{
      for (final MapEntry<String, String> page in site.pages.entries)
        if (page.key.startsWith('$sourcesDir/reference/')) page.key: page.value,
    };
    expect(pages, contains('$sourcesDir/reference/index.html'));
    final stray = <String>[];
    var cited = 0;
    for (final MapEntry<String, String> page in pages.entries) {
      final ({List<String> stray, int cited}) found = _dashes(page.value);
      stray.addAll(found.stray.map((String line) => '${page.key}: $line'));
      cited += found.cited;
    }
    expect(stray, isEmpty, reason: stray.take(20).join('\n'));
    expect(
      cited,
      lessThanOrEqualTo(citationDashCap),
      reason: 'citation parentheses hold $cited em dashes',
    );
  });

  test('the reference dash check keeps only what the rules keep', () {
    expect(_dashes('<p>A rule — and a reason.</p>').stray, hasLength(1));
    expect(_dashes('<p>As printed "a — b" here.</p>').stray, isEmpty);
    expect(_dashes('<p>See (<a href="x">F p. 3</a> — the form).</p>').cited, 1);
    expect(_dashes('<p>A (side note — no source).</p>').stray, hasLength(1));
    expect(_dashes('<p><code>a — b</code></p>').stray, isEmpty);
    expect(_dashes('<h3>3.1 Files — the hierarchy</h3>').stray, hasLength(1));
    expect(_dashes('<table><tr><td>—</td></tr></table>').stray, isEmpty);
  });
}
