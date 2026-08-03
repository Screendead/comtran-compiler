/// Parses the two manual conversions into the manual map — the single
/// routine shared by the map generator (`tool/generate_manual_map.dart`)
/// and its golden byte-comparison test (`test/manual_map_test.dart`).
///
/// The map answers one question: given a citation, which converted file,
/// which line, which anchor, and which page scan hold it? Two citation
/// forms exist, and the conversions carry a marker for each (see
/// `comtran-manuals/README.md`):
///
/// - **J28-6169** cites an IBM section code. Each page carries
///   `**[02.05.05]**`, preceded by `<!-- 02.05.05 | PDF 31 -->`. A
///   two-component code (`02.05`) names a whole section and appears only
///   as a heading, `## 02.05 Data Description ...`. Both forms produce a
///   key, `J:02.05.05` and `J:02.05`. An appendix heading names its code
///   after `APPENDIX` or `SECTION`; that prefix is allowed, so that
///   `## APPENDIX 90.02` also produces a key.
/// - **F28-8043** cites a printed page. Each page carries
///   `**[page 42]**`, preceded by `<!-- page 42 | PDF 47 -->`. The key is
///   `F:42`.
///
/// Four rules govern the parse:
///
/// 1. A fenced code block holds transcribed 1962 text, never markup. Skip
///    every line inside one.
/// 2. `pdfPage` is the page in effect at the line — the last `PDF n`
///    comment at or before it. A marker takes the page of its own comment;
///    a heading takes the page it starts on. Front matter before the first
///    comment has no page.
/// 3. A level-1 heading is the conversion's file title, not a heading of
///    the manual. It anchors an entry but never produces a code.
/// 4. A key holds its first occurrence, in file-path order. `repeatedCodes`
///    lists every occurrence dropped that way.
library;

import 'dart:convert';
import 'dart:io';

/// The repository-relative directory of the F28-8043 conversion.
const String fManualDir = 'comtran-manuals/F28-8043';

/// The repository-relative directory of the J28-6169 conversion.
const String jManualDir = 'comtran-manuals/J28-6169';

/// One markdown heading: its 1-based `line`, its `#` depth, its display
/// `text`, and the final (deduplicated) GitHub anchor `slug`.
typedef ManualHeading = ({int line, int level, String text, String slug});

/// One citable point: the `key` (`J:02.05.05`, `F:42`), the
/// repository-relative `file`, the 1-based `line` of the marker or
/// heading, the anchor `slug` and `heading` text of the nearest heading at
/// or before it, and the PDF page and page scan when known.
typedef ManualEntry = ({
  String key,
  String file,
  int line,
  String slug,
  String heading,
  int? pdfPage,
  String? scan,
});

/// The parse of one converted file.
typedef ManualFile = ({
  List<ManualHeading> headings,
  List<ManualEntry> entries,
});

final RegExp _fence = RegExp('^ {0,3}```');
final RegExp _heading = RegExp(r'^(#{1,6}) +(.*)$');
final RegExp _pageComment = RegExp(
  r'^<!--\s*(?:.*?\s*\|\s*)?PDF\s*(\d+)\s*-->$',
);
final RegExp _marker = RegExp(r'^\*\*\[(.+)\]\*\*');
final RegExp _sectionCode = RegExp(r'^\d\d(?:\.\d\d){1,3}$');
final RegExp _printedPage = RegExp(r'^page (\d+)$');
final RegExp _headingCode = RegExp(
  r'^(?:appendix |section )?(\d\d\.\d\d)(?:[ :]|$)',
  caseSensitive: false,
);
final RegExp _slugStrip = RegExp(r'[^\p{L}\p{N}_ -]', unicode: true);
final RegExp _escape = RegExp(r'\\([!-/:-@\[-`{-~])');

/// The GitHub anchor of one heading [text], before deduplication:
/// lowercase, everything except a letter, a digit, an underscore, a
/// space or a hyphen removed, then every space turned into a hyphen.
String slugify(String text) =>
    text.toLowerCase().replaceAll(_slugStrip, '').replaceAll(' ', '-');

/// Assigns the final anchor of each heading of one file. A repeated
/// anchor takes the suffix `-1`, `-2`, … in order of appearance, and a
/// suffixed candidate that collides with an existing anchor advances the
/// counter until the anchor is free — the exact github-slugger rule, so
/// `Example`, `Example`, `Example 1` give `example`, `example-1`,
/// `example-1-1`.
class Slugger {
  final Map<String, int> _occurrences = <String, int>{};

  /// The anchor of [text], unique within this file.
  String slug(String text) {
    final String base = slugify(text);
    var result = base;
    while (_occurrences.containsKey(result)) {
      _occurrences[base] = (_occurrences[base] ?? 0) + 1;
      result = '$base-${_occurrences[base]}';
    }
    _occurrences[result] = 0;
    return result;
  }
}

/// The display text of a heading: the markdown emphasis, code ticks and
/// backslash escapes removed. The conversions escape a leading `*` in a
/// card name (`\*FILE Card`); the reader sees `*FILE Card`.
String plainHeading(String text) => text
    .replaceAll(RegExp(r'#+$'), '')
    .trim()
    .replaceAllMapped(_escape, (Match m) => m[1]!)
    .replaceAll('`', '')
    .replaceAll('**', '')
    .trim();

/// The repository-relative page scan of PDF page [pdfPage] of the manual
/// under [manualDir].
String scanPath(String manualDir, int pdfPage) =>
    '$manualDir/images/page-${pdfPage.toString().padLeft(3, '0')}.png';

/// Parses one converted file. [manual] is `F` or `J`, [manualDir] its
/// conversion directory, [file] the repository-relative path of the file,
/// and [markdown] its contents.
ManualFile parseManualFile({
  required String manual,
  required String manualDir,
  required String file,
  required String markdown,
}) {
  final headings = <ManualHeading>[];
  final entries = <ManualEntry>[];
  final slugger = Slugger();
  var inFence = false;
  int? pdfPage;
  ManualHeading? current;

  void add(String key, int line) {
    entries.add((
      key: key,
      file: file,
      line: line,
      slug: current?.slug ?? '',
      heading: current?.text ?? '',
      pdfPage: pdfPage,
      scan: pdfPage == null ? null : scanPath(manualDir, pdfPage),
    ));
  }

  final List<String> lines = markdown.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final String line = lines[i].trimRight();
    final int number = i + 1;
    if (_fence.hasMatch(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) {
      continue;
    }

    final RegExpMatch? comment = _pageComment.firstMatch(line);
    if (comment != null) {
      pdfPage = int.parse(comment[1]!);
      continue;
    }

    final RegExpMatch? head = _heading.firstMatch(line);
    if (head != null) {
      final String text = plainHeading(head[2]!);
      current = (
        line: number,
        level: head[1]!.length,
        text: text,
        slug: slugger.slug(text),
      );
      headings.add(current);
      // A level-1 heading is the conversion's file title, which sits above
      // the first page marker and so carries no page. The manual's own
      // heading for the same section follows it.
      final RegExpMatch? code = manual == 'J' && current.level > 1
          ? _headingCode.firstMatch(text)
          : null;
      if (code != null) {
        add('J:${code[1]}', number);
      }
      continue;
    }

    final RegExpMatch? marker = _marker.firstMatch(line);
    if (marker == null) {
      continue;
    }
    final String content = marker[1]!.trim();
    if (manual == 'J' && _sectionCode.hasMatch(content)) {
      add('J:$content', number);
    } else if (manual == 'F') {
      final RegExpMatch? page = _printedPage.firstMatch(content);
      if (page != null) {
        add('F:${int.parse(page[1]!)}', number);
      }
    }
  }
  return (headings: headings, entries: entries);
}

/// Orders two map keys: F before J, then component by component and
/// number by number, so that `F:2` precedes `F:10` and `J:02.05`
/// precedes `J:02.05.05`.
int compareKeys(String a, String b) {
  final List<String> left = a.split(':');
  final List<String> right = b.split(':');
  if (left[0] != right[0]) {
    return left[0].compareTo(right[0]);
  }
  final List<int> lp = left[1].split('.').map(int.parse).toList();
  final List<int> rp = right[1].split('.').map(int.parse).toList();
  for (var i = 0; i < lp.length && i < rp.length; i++) {
    if (lp[i] != rp[i]) {
      return lp[i].compareTo(rp[i]);
    }
  }
  return lp.length.compareTo(rp.length);
}

/// Every converted markdown file of the manual under [manualDir], in
/// path order.
List<String> manualFiles(String manualDir) =>
    Directory(manualDir)
        .listSync()
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where((String p) => p.endsWith('.md'))
        .toList()
      ..sort();

/// Builds the whole map and renders it as the JSON text of
/// `editors/vscode-punchcard/manual-map.json`: sorted keys, two-space
/// indent, one trailing newline.
String buildManualMap() {
  final sections = <String, ManualEntry>{};
  final headings = <String, List<ManualHeading>>{};
  final duplicates = <String, List<String>>{};

  for (final (String manual, String dir) in <(String, String)>[
    ('F', fManualDir),
    ('J', jManualDir),
  ]) {
    for (final String path in manualFiles(dir)) {
      final ManualFile parsed = parseManualFile(
        manual: manual,
        manualDir: dir,
        file: path,
        markdown: File(path).readAsStringSync(),
      );
      headings[path] = parsed.headings;
      for (final ManualEntry entry in parsed.entries) {
        if (sections.containsKey(entry.key)) {
          duplicates
              .putIfAbsent(entry.key, () => <String>[])
              .add('$path:${entry.line}');
          continue;
        }
        sections[entry.key] = entry;
      }
    }
  }

  final List<String> keys = sections.keys.toList()..sort(compareKeys);
  final map = <String, Object?>{
    'generator': 'dart run tool/generate_manual_map.dart',
    'sections': <String, Object?>{
      for (final String key in keys) key: _entryJson(sections[key]!),
    },
    'headings': <String, Object?>{
      for (final String path in headings.keys.toList()..sort())
        path: <Object?>[
          for (final ManualHeading heading in headings[path]!)
            <String, Object?>{
              'line': heading.line,
              'level': heading.level,
              'text': heading.text,
              'slug': heading.slug,
            },
        ],
    },
    'repeatedCodes': <String, Object?>{
      for (final String key in duplicates.keys.toList()..sort(compareKeys))
        key: duplicates[key],
    },
  };
  return '${const JsonEncoder.withIndent('  ').convert(map)}\n';
}

Map<String, Object?> _entryJson(ManualEntry entry) => <String, Object?>{
  'file': entry.file,
  'line': entry.line,
  'slug': entry.slug,
  'heading': entry.heading,
  if (entry.pdfPage != null) 'pdfPage': entry.pdfPage,
  if (entry.scan != null) 'scan': entry.scan,
};
