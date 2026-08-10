import 'dart:io';

import 'package:test/test.dart';

/// Build output that the extension filter alone does not exclude.
/// `tool/build_web.dart` also writes `main.wasm`, `main.wasm.map` and
/// `main.mjs`, whose extensions are not in [textExtensions]. No commit holds
/// any of them, so the copy rules do not reach them.
const Set<String> buildOutput = <String>{'main.support.js', 'sample.js'};

const Set<String> textExtensions = <String>{
  '.css',
  '.dart',
  '.html',
  '.js',
  '.md',
};

/// The character and the three HTML forms of it.
final RegExp emDash = RegExp('—|&mdash;|&#8212;|&#[xX]2014;');

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
    .toList();

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
          emDash.hasMatch(lines[i]),
          isFalse,
          reason: '${file.path}:${i + 1} holds one: ${lines[i].trim()}',
        );
      }
    }
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
