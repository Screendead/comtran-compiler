/// Generates `editors/vscode-punchcard/manual-map.json` from the two
/// manual conversions under `comtran-manuals/`. Run from the repository
/// root:
///
///     dart run tool/generate_manual_map.dart
///
/// The map turns a citation into a location: `J 02.05.05` or `F p. 42`
/// gives a converted file, a line, a heading anchor, and a page scan. The
/// punchcard extension links a citation with it; `test/manual_map_test.dart`
/// regenerates the map and compares it byte for byte.
///
/// The output is deterministic — sorted keys, a two-space indent and one
/// trailing newline — so a re-run on a clean tree changes nothing.
library;

import 'dart:convert';
import 'dart:io';

import 'manual_map_source.dart';

void main() {
  final String json = buildManualMap();
  File('editors/vscode-punchcard/manual-map.json').writeAsStringSync(json);

  final map = jsonDecode(json) as Map<String, Object?>;
  final sections = map['sections']! as Map<String, Object?>;
  final headings = map['headings']! as Map<String, Object?>;
  final int lines = headings.values
      .map((Object? v) => (v! as List<Object?>).length)
      .fold(0, (int a, int b) => a + b);
  stdout.writeln(
    'wrote ${sections.length} sections and $lines headings '
    'from ${headings.length} files',
  );
}
