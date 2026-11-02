import 'dart:io';

import 'package:test/test.dart';

/// Build output that the extension filter alone does not exclude.
/// `tool/build_web.dart` also writes `main.wasm`, `main.wasm.map` and
/// `main.mjs`, whose extensions are not in [textExtensions]. No commit holds
/// any of them, so the copy rules do not reach them.
const Set<String> buildOutput = <String>{'main.support.js', 'sample.js'};

/// The directory of generated pages. It holds the manual transcriptions and
/// the language reference whole. Whether D5 reaches the reference is open
/// (web-copy.md, section 6), so this test reaches neither, and
/// `test/web_sources_test.dart` holds the frame around them to D5.
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
