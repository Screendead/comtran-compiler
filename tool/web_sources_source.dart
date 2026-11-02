/// Builds the sources part of the public website (roadmap W2,
/// `docs/HANDOVER.md`): the language reference, both manual conversions
/// page by page beside their scans, and the copies of the scans and the
/// PDFs. `tool/build_web.dart` writes what this library returns, and
/// `test/web_sources_test.dart` checks the same output in memory.
///
/// Every file it produces lives under `web/sources/`, which is built and
/// never committed. The text comes from two places only:
/// `docs/definition/`, the generated reading copy of the language
/// definition, and the conversions in `comtran-manuals/`. The site holds no
/// third copy of either.
///
/// Three rules govern the conversion of a manual into pages:
///
/// 1. A page starts at its `<!-- … PDF n -->` comment and runs to the next
///    one (`comtran-manuals/README.md`). A comment inside a fenced code
///    block is transcribed text, not a page boundary.
/// 2. The lines of a file before its first comment (the file title) belong
///    to the first page of that file.
/// 3. A heading takes the anchor `tool/manual_map_source.dart` gives it,
///    so a link the linkifier wrote lands on the same heading here.
library;

import 'dart:io';

import 'package:markdown/markdown.dart' as md;

import 'linkify_manual_refs.dart' show citationKey, citationPattern;
import 'manual_map_source.dart'
    show
        ManualEntry,
        Slugger,
        fence,
        manualFiles,
        parseManualFile,
        plainHeading;

/// The repository URL that a link to a file the site does not carry goes
/// to.
const String repositoryBlob =
    'https://github.com/Screendead/comtran-compiler/blob/master';

/// The directory, under `web/`, that holds every generated file.
const String sourcesDir = 'sources';

/// The repository directory of the language definition's reading copy.
const String definitionDir = 'docs/definition';

/// One manual: its form number `id`, its letter in a citation, its
/// conversion directory, its index file, its source PDF and its date.
typedef Manual = ({
  String id,
  String letter,
  String dir,
  String index,
  String pdf,
  String date,
});

const List<Manual> manuals = <Manual>[
  (
    id: 'F28-8043',
    letter: 'F',
    dir: 'comtran-manuals/F28-8043',
    index: 'F28-8043.md',
    pdf: 'F28-8043_CommercialTranslatorGenInfMan_Ju60.pdf',
    date: 'June 1960',
  ),
  (
    id: 'J28-6169',
    letter: 'J',
    dir: 'comtran-manuals/J28-6169',
    index: 'J28-6169.md',
    pdf: 'J28-6169-1_CommercialTranslator_Jan62.pdf',
    date: 'January 1962',
  ),
];

/// Each genuine typo a manual prints, by the form number of the manual, as
/// rule E3 of `docs/design/web-copy.md` names them. The page views put a
/// `[sic]` mark immediately after each occurrence in the transcribed text;
/// the conversions themselves never carry it. Each was checked on its scan:
/// PDF 38 (`at lease`), PDF 46 (`lables`, `dinsity`), PDF 66 (`Parentheis`)
/// and PDF 137 (`Appox-Max`, the misspelt half of the heading "Appox-Max
/// Size"). An authentic period spelling never goes here (rule E4).
const Map<String, List<String>> typos = <String, List<String>>{
  'J28-6169': <String>[
    'at lease',
    'lables',
    'dinsity',
    'Parentheis',
    'Appox-Max',
  ],
};

/// The mark that follows a typo. It is empty: the stylesheet draws `[sic]`
/// as generated content, so a reader who copies the quotation gets IBM's
/// words and nothing else (rule G3).
const String sicMark = '<span class="sic"></span>';

/// One page of a manual: its PDF page number, the label its marker comment
/// gives it (`page 42`, `02.05.05`, `Publications`, or none), the
/// repository path of the file that holds it, and its lines of markdown.
typedef ManualPage = ({
  int pdf,
  String? label,
  String file,
  List<String> lines,
});

final RegExp _pageComment = RegExp(
  r'^<!--\s*(?:(.*?)\s*\|\s*)?PDF\s*(\d+)\s*-->$',
);
final RegExp _atxHeading = RegExp(r'^(#{1,6}) +(.*)$');
final RegExp _headingTag = RegExp(r'^h[1-6]$');
final RegExp _external = RegExp('^[a-z]+:', caseSensitive: false);

/// The site path of the scan of PDF page [pdf].
String scanName(int pdf) => 'page-${pdf.toString().padLeft(3, '0')}.png';

/// The site path of the page view of PDF page [pdf].
String pageName(int pdf) => 'page-${pdf.toString().padLeft(3, '0')}.html';

/// Splits one converted file, at repository path [file], into its pages.
List<ManualPage> splitManualFile(String file, String markdown) {
  final pages = <ManualPage>[];
  final preamble = <String>[];
  List<String>? current;
  var inFence = false;
  for (final String line in markdown.split('\n')) {
    final String trimmed = line.trimRight();
    if (fence.hasMatch(trimmed)) {
      inFence = !inFence;
    } else if (!inFence) {
      final RegExpMatch? comment = _pageComment.firstMatch(trimmed);
      if (comment != null) {
        current = <String>[if (pages.isEmpty) ...preamble];
        pages.add((
          pdf: int.parse(comment[2]!),
          label: comment[1],
          file: file,
          lines: current,
        ));
        continue;
      }
    }
    (current ?? preamble).add(line);
  }
  return pages;
}

/// Every page of [manual], in PDF order.
List<ManualPage> manualPages(Manual manual) => <ManualPage>[
  for (final String file in chapterFiles(manual))
    ...splitManualFile(file, File(file).readAsStringSync()),
]..sort((ManualPage a, ManualPage b) => a.pdf.compareTo(b.pdf));

/// The converted files of [manual] that hold pages: every file but the
/// conversion's own index.
List<String> chapterFiles(Manual manual) => manualFiles(
  manual.dir,
).where((String path) => path != '${manual.dir}/${manual.index}').toList();

/// The heading anchors of one file, assigned in order by the same rule the
/// manual map and the definition mirror use.
List<String> _rawSlugs(List<String> lines, Slugger slugger) {
  final slugs = <String>[];
  var inFence = false;
  for (final line in lines) {
    final String trimmed = line.trimRight();
    if (fence.hasMatch(trimmed)) {
      inFence = !inFence;
      continue;
    }
    final RegExpMatch? head = inFence ? null : _atxHeading.firstMatch(trimmed);
    if (head != null) {
      slugs.add(slugger.slug(plainHeading(head[2]!)));
    }
  }
  return slugs;
}

/// Calls [visit] on every element under [nodes], parents first.
void _walk(List<md.Node>? nodes, void Function(md.Element) visit) {
  for (final md.Node node in nodes ?? const <md.Node>[]) {
    if (node is md.Element) {
      visit(node);
      _walk(node.children, visit);
    }
  }
}

/// Parses [lines] and gives each heading, in order, the next anchor from
/// [slugger]. Headings match by position, so the parser and the raw scan
/// must find the same headings; no source file holds one inside a list or
/// a quotation.
List<md.Node> _parse(List<String> lines, Slugger slugger) {
  final List<md.Node> nodes = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
  ).parseLines(lines);
  final List<String> slugs = _rawSlugs(lines, slugger);
  var next = 0;
  _walk(nodes, (md.Element element) {
    if (_headingTag.hasMatch(element.tag)) {
      element.attributes['id'] = slugs[next++];
    }
  });
  assert(next == slugs.length, 'the parser lost a heading the scan found');
  return nodes;
}

/// Puts a [sicMark] after each of [words] in the text of [nodes]. A raw
/// HTML block, such as a conversion note, and a code span keep their text:
/// neither is transcribed prose.
void markTypos(List<md.Node> nodes, List<String> words) {
  if (words.isEmpty) {
    return;
  }
  final pattern = RegExp(
    '(?<![A-Za-z])(?:${words.map(RegExp.escape).join('|')})(?![A-Za-z])',
  );
  void mark(List<md.Node> children) {
    for (var i = 0; i < children.length; i++) {
      final md.Node node = children[i];
      if (node is md.Element) {
        if (node.tag != 'code' && node.tag != 'pre') {
          mark(node.children ?? <md.Node>[]);
        }
        continue;
      }
      if (node is! md.Text || node.text.trimLeft().startsWith('<')) {
        continue;
      }
      final String text = node.text;
      final List<RegExpMatch> hits = pattern.allMatches(text).toList();
      if (hits.isEmpty) {
        continue;
      }
      final parts = <md.Node>[];
      var at = 0;
      for (final hit in hits) {
        parts
          ..add(md.Text(text.substring(at, hit.end)))
          ..add(md.Text(sicMark));
        at = hit.end;
      }
      parts.add(md.Text(text.substring(at)));
      children.replaceRange(i, i + 1, parts);
      i += parts.length - 1;
    }
  }

  mark(nodes);
}

/// Escapes [text] for an HTML text node or attribute.
String escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Resolves the relative [href] against repository directory [dir], and
/// removes each `.` and `..` segment.
String resolveRepoPath(String dir, String href) {
  final segments = <String>[];
  for (final String part in '$dir/$href'.split('/')) {
    if (part == '..') {
      if (segments.isNotEmpty) {
        segments.removeLast();
      }
    } else if (part.isNotEmpty && part != '.') {
      segments.add(part);
    }
  }
  return segments.join('/');
}

/// The path from the site directory `sources/[from]/` to the site file
/// `sources/[to]`.
String relativeSitePath(String from, String to) {
  final int slash = to.indexOf('/');
  return to.substring(0, slash) == from ? to.substring(slash + 1) : '../$to';
}

/// The page label a reader sees: `Page 42`, `02.05.05`, `Publications`, or
/// `PDF page 1` for a page that prints no number.
String pageLabel(ManualPage page) {
  final String? label = page.label;
  if (label == null) {
    return 'PDF page ${page.pdf}';
  }
  return label.startsWith('page ') ? 'Page ${label.substring(5)}' : label;
}

/// The generated site: each HTML file by its path under `web/`, and each
/// copied file, from its repository path to its path under `web/`.
typedef SourcesSite = ({Map<String, String> pages, Map<String, String> copies});

/// Builds the whole sources site in memory.
SourcesSite buildSourcesSite() => _SiteBuilder().build();

class _SiteBuilder {
  /// The site file, under `sources/`, of each anchor of each repository
  /// file, keyed `file#anchor`.
  final Map<String, String> _anchors = <String, String>{};

  /// The site file of the first page of each repository file.
  final Map<String, String> _firstPage = <String, String>{};

  /// The site file of each citation key, `F:42` or `J:02.05.05`.
  final Map<String, String> _citations = <String, String>{};

  /// The site file of each other repository file the site carries.
  final Map<String, String> _carried = <String, String>{};

  final Map<String, String> _pages = <String, String>{};
  final Map<String, String> _copies = <String, String>{};

  SourcesSite build() {
    final parsed = <Manual, List<(ManualPage, List<md.Node>)>>{};
    for (final Manual manual in manuals) {
      parsed[manual] = _indexManual(manual);
    }
    final List<(String, String, List<md.Node>)> parts = _indexDefinition();

    for (final Manual manual in manuals) {
      _writeManual(manual, parsed[manual]!);
    }
    _writeDefinition(parts);
    return (pages: _pages, copies: _copies);
  }

  List<(ManualPage, List<md.Node>)> _indexManual(Manual manual) {
    final site = '$sourcesDir/${manual.id}';
    _carried['${manual.dir}/${manual.index}'] = '${manual.id}/index.html';
    _carried['${manual.dir}/images'] = '${manual.id}/index.html';
    _carried['${manual.dir}/${manual.pdf}'] = '${manual.id}/${manual.pdf}';
    _copies['${manual.dir}/${manual.pdf}'] = '$site/${manual.pdf}';

    final result = <(ManualPage, List<md.Node>)>[];
    final sluggers = <String, Slugger>{};
    for (final ManualPage page in manualPages(manual)) {
      final target = '${manual.id}/${pageName(page.pdf)}';
      final String scan = scanName(page.pdf);
      _carried['${manual.dir}/images/$scan'] = '${manual.id}/$scan';
      _copies['${manual.dir}/images/$scan'] = '$site/$scan';
      _firstPage.putIfAbsent(page.file, () => target);
      final List<md.Node> nodes = _parse(
        page.lines,
        sluggers.putIfAbsent(page.file, Slugger.new),
      );
      _walk(nodes, (md.Element element) {
        final String? id = element.attributes['id'];
        if (id != null) {
          _anchors['${page.file}#$id'] = target;
        }
      });
      result.add((page, nodes));
    }

    for (final String file in chapterFiles(manual)) {
      final List<ManualEntry> entries = parseManualFile(
        manual: manual.letter,
        manualDir: manual.dir,
        file: file,
        markdown: File(file).readAsStringSync(),
      ).entries;
      for (final entry in entries) {
        final int? pdf = entry.pdfPage;
        if (pdf != null) {
          _citations.putIfAbsent(
            entry.key,
            () => '${manual.id}/${pageName(pdf)}',
          );
        }
      }
    }
    return result;
  }

  /// Each part of the definition's reading copy: its repository path, its
  /// site file, and its parsed markdown. The README comes first.
  List<(String, String, List<md.Node>)> _indexDefinition() {
    final List<String> files =
        Directory(definitionDir)
            .listSync()
            .whereType<File>()
            .map((File f) => f.path.replaceAll(r'\', '/'))
            .where((String p) => p.endsWith('.md'))
            .toList()
          ..sort((String a, String b) {
            final bool aReadme = a.endsWith('/README.md');
            final bool bReadme = b.endsWith('/README.md');
            return aReadme == bReadme ? a.compareTo(b) : (aReadme ? -1 : 1);
          });
    final parts = <(String, String, List<md.Node>)>[];
    for (final file in files) {
      final String name = file.split('/').last;
      final target = name == 'README.md'
          ? 'reference/index.html'
          : 'reference/${name.replaceAll(RegExp(r'\.md$'), '.html')}';
      _carried[file] = target;
      final List<md.Node> nodes = _parse(
        File(file).readAsStringSync().split('\n'),
        Slugger(),
      );
      parts.add((file, target, nodes));
    }
    return parts;
  }

  /// Rewrites every link and image of [nodes], which come from a file in
  /// repository directory [repoDir] and land in site directory [siteDir].
  void _rewrite(List<md.Node> nodes, String repoDir, String siteDir) {
    _walk(nodes, (md.Element element) {
      if (element.tag == 'a') {
        final String? href = element.attributes['href'];
        if (href != null) {
          element.attributes['href'] = _target(
            href,
            repoDir,
            siteDir,
            element.textContent,
          );
        }
      } else if (element.tag == 'img') {
        final String? src = element.attributes['src'];
        if (src != null) {
          element.attributes['src'] = _target(src, repoDir, siteDir, '');
          element.attributes['loading'] = 'lazy';
        }
      }
    });
  }

  String _target(String href, String repoDir, String siteDir, String text) {
    if (href.startsWith('#') || _external.hasMatch(href)) {
      return href;
    }
    final int hash = href.indexOf('#');
    final String path = hash < 0 ? href : href.substring(0, hash);
    final String fragment = hash < 0 ? '' : href.substring(hash + 1);
    final String repoPath = resolveRepoPath(repoDir, Uri.decodeFull(path));

    String? site;
    var keep = fragment;
    final RegExpMatch? citation = citationPattern.firstMatch(text);
    if (citation != null &&
        citation[0] == text.trim() &&
        _firstPage.containsKey(repoPath)) {
      site = _citations[citationKey(citation)];
      if (site != null) {
        keep = '';
      }
    }
    site ??= fragment.isEmpty ? null : _anchors['$repoPath#$fragment'];
    site ??= _firstPage[repoPath] ?? _carried[repoPath];
    if (site == null) {
      return '$repositoryBlob/$repoPath${fragment.isEmpty ? '' : '#$fragment'}';
    }
    final String relative = relativeSitePath(siteDir, site);
    return keep.isEmpty ? relative : '$relative#$keep';
  }

  void _writeManual(Manual manual, List<(ManualPage, List<md.Node>)> pages) {
    for (var i = 0; i < pages.length; i++) {
      final (ManualPage page, List<md.Node> nodes) = pages[i];
      _rewrite(nodes, manual.dir, manual.id);
      markTypos(nodes, typos[manual.id] ?? const <String>[]);
      _pages['$sourcesDir/${manual.id}/${pageName(page.pdf)}'] = pageView(
        manual: manual,
        page: page,
        count: pages.length,
        previous: i == 0 ? null : pages[i - 1].$1,
        next: i + 1 == pages.length ? null : pages[i + 1].$1,
        transcription: md.renderToHtml(nodes),
      );
    }

    final List<md.Node> index = _parse(
      File('${manual.dir}/${manual.index}').readAsStringSync().split('\n'),
      Slugger(),
    );
    _rewrite(index, manual.dir, manual.id);
    _pages['$sourcesDir/${manual.id}/index.html'] = contentsView(
      manual: manual,
      conversionIndex: md.renderToHtml(index),
      pages: <ManualPage>[for (final (ManualPage p, _) in pages) p],
      chapterTitle: _fileTitle,
    );
  }

  void _writeDefinition(List<(String, String, List<md.Node>)> parts) {
    for (var i = 0; i < parts.length; i++) {
      final (String file, String target, List<md.Node> nodes) = parts[i];
      _rewrite(nodes, definitionDir, 'reference');
      _pages['$sourcesDir/$target'] = referenceView(
        title: i == 0 ? 'The language reference' : _fileTitle(file),
        body: md.renderToHtml(nodes),
        previous: i == 0 ? null : _partLink(parts[i - 1]),
        next: i + 1 == parts.length ? null : _partLink(parts[i + 1]),
      );
    }
  }

  (String, String) _partLink((String, String, List<md.Node>) part) => (
    part.$2.split('/').last,
    part.$2.endsWith('/index.html')
        ? 'The language reference'
        : _fileTitle(part.$1),
  );
}

/// The text of the first heading of the markdown file at [path].
String _fileTitle(String path) => plainHeading(
  File(path)
      .readAsLinesSync()
      .map((String line) => _atxHeading.firstMatch(line.trimRight()))
      .nonNulls
      .first[2]!,
);

/// The width and height of the PNG at [path], from its header.
(int, int) pngSize(String path) {
  final RandomAccessFile file = File(path).openSync();
  final List<int> bytes;
  try {
    bytes = file.readSync(24);
  } finally {
    file.closeSync();
  }
  int word(int at) =>
      (bytes[at] << 24) |
      (bytes[at + 1] << 16) |
      (bytes[at + 2] << 8) |
      bytes[at + 3];
  return (word(16), word(20));
}

/// The frame every generated page shares. Each sits two directories below
/// `web/`.
String shell({
  required String title,
  required String description,
  required String body,
}) =>
    '''
<!doctype html>
<html lang="en-GB">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(title)} &middot; COMTRAN</title>
<meta name="description" content="${escape(description)}">
<link rel="stylesheet" href="../../styles.css">
</head>
<body>

<header class="runner">
  <a href="../../index.html" class="wordmark">COMTRAN Reconstruction</a>
  <nav>
    <a href="../../index.html">The compiler</a>
    <a href="../../sources.html" aria-current="page">The sources</a>
    <a href="../../reading-the-scans.html">How we read the scans</a>
    <a href="../../roadmap.html">What is built</a>
  </nav>
</header>

<main class="sources">
$body
</main>

<footer class="runner">
  <span>Static pages. No server, no tracking, no outbound request.</span>
  <span>Built from the repository at the last deploy</span>
</footer>

</body>
</html>
''';

String _pager(String label, List<String> links) =>
    '<nav class="pager" aria-label="${escape(label)}">\n'
    '${links.map((String l) => '  $l\n').join()}'
    '</nav>';

/// One page of a manual: its scan beside its transcription.
String pageView({
  required Manual manual,
  required ManualPage page,
  required int count,
  required ManualPage? previous,
  required ManualPage? next,
  required String transcription,
}) {
  final String label = pageLabel(page);
  final String scan = scanName(page.pdf);
  final (int, int) size = pngSize('${manual.dir}/images/$scan');
  final dimensions = ' width="${size.$1}" height="${size.$2}"';
  final back = previous == null
      ? '<span class="pager-end">First page</span>'
      : '<a rel="prev" href="${pageName(previous.pdf)}">&larr; '
            '${escape(pageLabel(previous))}</a>';
  final on = next == null
      ? '<span class="pager-end">Last page</span>'
      : '<a rel="next" href="${pageName(next.pdf)}">'
            '${escape(pageLabel(next))} &rarr;</a>';
  final String pager = _pager('Turn the page', <String>[
    back,
    '<a href="index.html">Every page of ${manual.id}</a>',
    on,
  ]);
  final String named = label.startsWith('Page') ? label.toLowerCase() : label;
  return shell(
    title: '${manual.id}, $named',
    description:
        'The scan of PDF page ${page.pdf} of IBM manual ${manual.id} '
        '(${manual.date}), beside the text read off it.',
    body:
        '''
$pager

<header class="folio-head">
  <p class="strip-label">${manual.id} &middot; ${manual.date}</p>
  <h1>${escape(label)}</h1>
  <p class="folio-sub">PDF page ${page.pdf} of $count.
  <a href="${manual.pdf}" download>Download the scanned PDF</a></p>
</header>

<div class="folio">
  <figure class="scan">
    <p class="pane-label">The page as scanned</p>
    <a href="$scan"><img src="$scan"$dimensions alt="The scan of PDF page ${page.pdf} of ${manual.id}"></a>
    <figcaption>Select the scan to open it at full size.</figcaption>
  </figure>
  <article class="transcription doc">
    <p class="pane-label">The text read off it</p>
$transcription
  </article>
</div>

$pager''',
  );
}

/// The contents of one manual: the conversion's own index, then every page
/// in order, grouped by the file that holds it.
String contentsView({
  required Manual manual,
  required String conversionIndex,
  required List<ManualPage> pages,
  required String Function(String) chapterTitle,
}) {
  final groups = StringBuffer();
  String? file;
  for (final page in pages) {
    if (page.file != file) {
      if (file != null) {
        groups.write('</ol>\n');
      }
      file = page.file;
      groups.write(
        '<h3>${escape(chapterTitle(page.file))}</h3>\n<ol class="page-list">\n',
      );
    }
    groups.write(
      '  <li><a href="${pageName(page.pdf)}">${escape(pageLabel(page))}</a></li>\n',
    );
  }
  if (file != null) {
    groups.write('</ol>\n');
  }
  return shell(
    title: manual.id,
    description:
        'Every page of IBM manual ${manual.id} (${manual.date}), each beside '
        'its scan.',
    body:
        '''
<header class="folio-head">
  <p class="strip-label">${manual.id} &middot; ${manual.date}</p>
  <p class="folio-sub">The contents of the conversion, then every page in
  order. Each page opens beside its scan.
  <a href="${manual.pdf}" download>Download the scanned PDF</a></p>
</header>

<section class="doc">
$conversionIndex
</section>

<section class="pages">
<h2>Every page, in order</h2>
$groups</section>''',
  );
}

/// One part of the language reference.
String referenceView({
  required String title,
  required String body,
  required (String, String)? previous,
  required (String, String)? next,
}) {
  final String pager = _pager('Turn the part', <String>[
    if (previous == null)
      '<span class="pager-end">First part</span>'
    else
      '<a rel="prev" href="${previous.$1}">&larr; ${escape(previous.$2)}</a>',
    '<a href="index.html">The contents</a>',
    if (next == null)
      '<span class="pager-end">Last part</span>'
    else
      '<a rel="next" href="${next.$1}">${escape(next.$2)} &rarr;</a>',
  ]);
  return shell(
    title: title,
    description:
        'The language reference for COMTRAN: this project’s own account of '
        'the language, cited to the two IBM manuals.',
    body:
        '''
<p class="reference-note">The language reference is this project&rsquo;s
reading of the two manuals, not IBM&rsquo;s text. Every claim in it cites a
page, and each citation opens that page beside its scan.</p>

$pager

<article class="doc">
$body
</article>

$pager''',
  );
}
