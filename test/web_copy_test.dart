import 'dart:io';

import 'package:test/test.dart';

import '../tool/web_sources_source.dart' show buildSourcesSite, sourcesDir;

/// Build output that the extension filter alone does not exclude.
/// `tool/build_web.dart` also writes `main.wasm`, `main.wasm.map` and
/// `main.mjs`, whose extensions are not in [textExtensions]. No commit holds
/// any of them, so the copy rules do not reach them.
const Set<String> buildOutput = <String>{'main.support.js', 'sample.js'};

/// The directory of generated pages. It is built and never committed, so
/// the scan of committed files below skips it. The manual transcriptions
/// there are quotations, which E2 keeps verbatim; the language reference is
/// this project's own text, and D5 reaches it through the built pages
/// (Jack's ruling of 2026-11-02, web-copy.md, section 6).
const String generatedDir = 'web/sources/';

/// Manual titles the site quotes as the conversions give them. Rule E2
/// outranks D5 for a quotation, and web-copy.md names the F28-8043 title as
/// the one case this exception exists for.
const List<String> quotedTitles = <String>[
  'General Information Manual — IBM Commercial Translator',
];

const Set<String> textExtensions = <String>{
  '.css',
  '.dart',
  '.html',
  '.js',
  '.md',
};

/// The character and the three HTML forms of it.
final RegExp emDash = RegExp('—|&mdash;|&#8212;|&#[xX]2014;');

/// The en dash stays legal under D5, because it is Jack's own register, and
/// it stays minimal. The guard caps it rather than barring it, so that a
/// rewrite cannot obey D5 by turning every em dash into an en dash. To give
/// the site more room, raise [enDashCap] in the same pull request and give
/// the reason in the commit message.
final RegExp enDash = RegExp('–|&ndash;|&#8211;|&#[xX]2013;');

const int enDashCap = 4;

/// The codename series `docs/HANDOVER.md` defines, each of which the roadmap
/// page carries as one station.
const List<String> codenames = <String>[
  'M0',
  'M1',
  'M2',
  'M3',
  'M4',
  'M5',
  'M6',
  'T1',
  'T2',
  'T3',
  'T4',
  'W1',
  'W2',
  'W3',
  'W4',
];

List<File> siteFiles() => Directory('web')
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => textExtensions.any(f.path.endsWith))
    .where((File f) => !buildOutput.contains(f.uri.pathSegments.last))
    .where((File f) => !f.path.replaceAll(r'\', '/').startsWith(generatedDir))
    .toList();

/// [line] with each quoted title removed.
String unquoted(String line) => quotedTitles.fold(
  line,
  (String text, String title) => text.replaceAll(title, ''),
);

final RegExp _heading = RegExp('<h[1-6][^>]*>(.*?)</h[1-6]>', dotAll: true);
final RegExp _tag = RegExp('<[^>]*>');

/// Spans of a reference page whose em dashes D5 leaves alone: a page title,
/// a heading, code, a block quotation, and a table cell that holds the mark
/// alone as "none".
final List<RegExp> _keptBlocks = <RegExp>[
  RegExp('<title>.*?</title>', dotAll: true),
  _heading,
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
/// its line, and the count of those a citation parenthesis keeps. [headings]
/// holds the text of every heading of the reference, so a contents entry or
/// a pager link that repeats a heading keeps it too.
({List<String> stray, int cited}) _dashes(String html, Set<String> headings) {
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
    for (final heading in headings) {
      line = line.replaceAll(heading, '');
    }
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
  test('no file under web/ holds an em dash (web-copy.md, rule D5)', () {
    final List<File> files = siteFiles();
    // A re-layout that emptied the scan would leave the guard passing on
    // nothing, so name the one file the site cannot lose.
    expect(
      files.map((File f) => f.uri.pathSegments.last),
      contains('index.html'),
    );
    for (final file in files) {
      final List<String> lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        expect(
          emDash.hasMatch(unquoted(lines[i])),
          isFalse,
          reason: '${file.path}:${i + 1} holds one: ${lines[i].trim()}',
        );
      }
    }
  });

  test('the language reference holds no stray em dash (web-copy.md, D5)', () {
    final pages = <String, String>{
      for (final MapEntry<String, String> page
          in buildSourcesSite().pages.entries)
        if (page.key.startsWith('$sourcesDir/reference/')) page.key: page.value,
    };
    expect(pages, contains('$sourcesDir/reference/index.html'));
    final headings = <String>{
      for (final String html in pages.values)
        for (final RegExpMatch m in _heading.allMatches(html))
          if (_plain(m[1]!).contains('—')) _plain(m[1]!),
    };
    final stray = <String>[];
    var cited = 0;
    for (final MapEntry<String, String> page in pages.entries) {
      final ({List<String> stray, int cited}) found = _dashes(
        page.value,
        headings,
      );
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
    const headings = <String>{'3.1 Files — the hierarchy'};
    ({List<String> stray, int cited}) check(String html) =>
        _dashes(html, headings);
    expect(check('<p>A rule — and a reason.</p>').stray, hasLength(1));
    expect(check('<p>As printed "a — b" here.</p>').stray, isEmpty);
    expect(check('<p>See (<a href="x">F p. 3</a> — the form).</p>').cited, 1);
    expect(check('<p>A (side note — no source).</p>').stray, hasLength(1));
    expect(check('<p><code>a — b</code></p>').stray, isEmpty);
    expect(
      check('<li><a href="#x">3.1 Files — the hierarchy</a></li>').stray,
      isEmpty,
    );
    expect(check('<table><tr><td>—</td></tr></table>').stray, isEmpty);
  });

  test('each quoted title is printed exactly as quoted', () {
    final String site = siteFiles()
        .map((File f) => f.readAsStringSync())
        .join('\n');
    for (final String title in quotedTitles) {
      expect(site, contains(title), reason: 'no page quotes "$title"');
    }
  });

  test('the en dash stays under its cap (web-copy.md, rule D5)', () {
    final List<File> files = siteFiles();
    var found = 0;
    for (final file in files) {
      found += enDash.allMatches(file.readAsStringSync()).length;
    }
    expect(
      found,
      lessThanOrEqualTo(enDashCap),
      reason: 'web/ holds $found en dashes; the cap is $enDashCap',
    );
  });

  test('the roadmap page carries every codename (web-copy.md, rule H2)', () {
    final String page = File('web/roadmap.html').readAsStringSync();
    for (final String code in codenames) {
      // The element holds the codename and nothing else, so prose that names
      // a milestone in passing does not satisfy the check.
      expect(
        page,
        contains('>$code<'),
        reason: 'web/roadmap.html has no station for $code',
      );
    }
  });
}
