/// The two layering rules no build catches: the browser bundle reaches no
/// `dart:io`, and the runtime reaches no code generator.
///
/// `dart compile wasm` compiles a `dart:io` import, and the loader and the
/// code generator ship in one package, so neither rule can fail a build.
/// These two walks are the whole enforcement.
library;

import 'dart:io';

import 'package:test/test.dart';

/// An `import` or `export` directive's URI. No library under `lib/` writes
/// a conditional import, so the first URI of a directive is its only one.
/// The character class takes both quote forms, so the walk stands on its
/// own instead of leaning on `prefer_single_quotes` to catch a
/// double-quoted directive.
final RegExp _dependency = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

const String _packageRoot = 'package:comtran/';

/// The repository-relative path of [library], which a walk reaches either
/// as a `package:comtran/` URI or as a path relative to its entry point.
String _file(Uri library) => library.scheme == 'package'
    ? 'lib/${library.toString().substring(_packageRoot.length)}'
    : '$library';

/// Every library a directive names from [root] outward, against the trail
/// that first reached it. The walk opens the files of this package only,
/// so a foreign package that imported `dart:io` would pass unseen.
Map<Uri, String> _reachable(Uri root) {
  final trails = <Uri, String>{root: _file(root)};
  final queue = <Uri>[root];
  while (queue.isNotEmpty) {
    final Uri library = queue.removeAt(0);
    final String source = File(_file(library)).readAsStringSync();
    for (final RegExpMatch match in _dependency.allMatches(source)) {
      final Uri target = library.resolve(match.group(1)!);
      if (trails.containsKey(target)) {
        continue;
      }
      trails[target] = '${trails[library]} -> ${_file(target)}';
      if (target.scheme.isEmpty || target.toString().startsWith(_packageRoot)) {
        queue.add(target);
      }
    }
  }
  return trails;
}

void main() {
  test('the browser bundle reaches no library that imports dart:io', () {
    final Map<Uri, String> trails = _reachable(Uri.parse('web/main.dart'));
    // `procedure.dart` is no export of the barrel, so reaching it proves
    // the walk follows a relative import past the export list.
    expect(trails.keys.map(_file), contains('lib/src/codegen/procedure.dart'));
    expect(<String>[
      for (final MapEntry<Uri, String> hop in trails.entries)
        if (hop.key.toString() == 'dart:io') hop.value,
    ], isEmpty);
  });

  test('the runtime reaches no library under lib/src/codegen/', () {
    final Map<Uri, String> trails = _reachable(
      Uri.parse('lib/src/runtime/machine.dart'),
    );
    // `object_deck.dart` is two hops out, through `loader.dart`, so
    // reaching it proves the walk recurses instead of reading the root.
    expect(trails.keys.map(_file), contains('lib/src/loader/object_deck.dart'));
    expect(<String>[
      for (final MapEntry<Uri, String> hop in trails.entries)
        if (_file(hop.key).startsWith('lib/src/codegen/')) hop.value,
    ], isEmpty);
  });
}
