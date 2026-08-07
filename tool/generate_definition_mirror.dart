/// Generates `docs/definition/` — the rendered mirror of
/// `docs/comtran-language-definition.md`. Run from the repository root:
///
///     dart run tool/generate_definition_mirror.dart
///
/// Canon is one file above GitHub's Markdown rendering limit, so a browser
/// cannot show it. The mirror holds the same text in parts that render.
/// `tool/definition_mirror_source.dart` states the split rules, and
/// `test/definition_mirror_test.dart` regenerates the mirror and compares
/// it byte for byte.
///
/// The generator deletes a mirror file that the split no longer produces,
/// so a renamed section leaves nothing behind.
library;

import 'dart:io';

import 'definition_mirror_source.dart';

void main() {
  final Map<String, String> mirror = buildDefinitionMirror();
  final directory = Directory(mirrorDirectory);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  for (final FileSystemEntity entity in directory.listSync()) {
    if (entity is File && !mirror.containsKey(entity.path)) {
      entity.deleteSync();
    }
  }
  mirror.forEach((String path, String contents) {
    File(path).writeAsStringSync(contents);
  });

  stdout.writeln('wrote ${mirror.length} files to $mirrorDirectory');
}
