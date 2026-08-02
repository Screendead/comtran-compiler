/// Deck converter — the T1 tool of `docs/HANDOVER.md`.
///
/// Converts between canon card-image files (`.ctdeck`) and their text
/// mirrors (`.deck`), regenerates mirrors, and checks that committed mirrors
/// are fresh. Formats: `docs/design/deck-format.md`; authority rules: D0.5.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:comtran/comtran.dart';

const String _usage = '''
Usage: dart run comtran:deckconv <command> ...

  to-canon <in.deck> <out.ctdeck>   convert a mirror to a canon file
  to-text <in.ctdeck> [<out.deck>]  convert a canon file to mirror text
                                    (standard output when no path is given)
  regen <path>...                   regenerate the .deck mirror next to each
                                    .ctdeck file (directories are searched)
  check <path>...                   verify that each canon file round-trips
                                    and that its committed mirror is fresh
''';

Future<int> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.write(_usage);
    return 2;
  }
  try {
    switch (arguments.first) {
      case 'to-canon':
        return _toCanon(arguments.sublist(1));
      case 'to-text':
        return _toText(arguments.sublist(1));
      case 'regen':
        return _regen(arguments.sublist(1));
      case 'check':
        return _check(arguments.sublist(1));
      default:
        stderr.write(_usage);
        return 2;
    }
  } on FormatException catch (e) {
    stderr.writeln('error: ${e.message}');
    return 1;
  } on FileSystemException catch (e) {
    stderr.writeln('error: ${e.message}: ${e.path}');
    return 1;
  }
}

int _toCanon(List<String> args) {
  if (args.length != 2) {
    stderr.write(_usage);
    return 2;
  }
  final List<CardImage> deck = mirrorToDeck(File(args[0]).readAsStringSync());
  File(args[1]).writeAsBytesSync(encodeCanon(deck));
  return 0;
}

int _toText(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    stderr.write(_usage);
    return 2;
  }
  final String text = deckToMirror(_readCanon(args[0]));
  if (args.length == 1 || args[1] == '-') {
    stdout.write(text);
  } else {
    File(args[1]).writeAsStringSync(text);
  }
  return 0;
}

int _regen(List<String> args) {
  if (args.isEmpty) {
    stderr.write(_usage);
    return 2;
  }
  for (final String canonPath in _findCanonFiles(args)) {
    File(
      _mirrorPathFor(canonPath),
    ).writeAsStringSync(deckToMirror(_readCanon(canonPath)));
    stdout.writeln('regenerated ${_mirrorPathFor(canonPath)}');
  }
  return 0;
}

int _check(List<String> args) {
  if (args.isEmpty) {
    stderr.write(_usage);
    return 2;
  }
  var failures = 0;
  void fail(String message) {
    stderr.writeln('FAIL: $message');
    failures++;
  }

  for (final String canonPath in _findCanonFiles(args)) {
    final Uint8List bytes = File(canonPath).readAsBytesSync();
    final List<CardImage> deck;
    try {
      deck = decodeCanon(bytes);
    } on FormatException catch (e) {
      fail('$canonPath: ${e.message}');
      continue;
    }
    final String text = deckToMirror(deck);
    final Uint8List roundTrip = encodeCanon(mirrorToDeck(text));
    if (!_bytesEqual(roundTrip, bytes)) {
      fail('$canonPath: mirror text does not round-trip to the same bytes');
      continue;
    }
    final mirror = File(_mirrorPathFor(canonPath));
    if (!mirror.existsSync()) {
      fail('$canonPath: mirror ${mirror.path} is missing');
    } else if (mirror.readAsStringSync() != text) {
      fail('${mirror.path}: stale mirror — regenerate with deckconv regen');
    } else {
      stdout.writeln('OK: $canonPath');
    }
  }
  for (final String mirrorPath in _findFiles(args, '.deck')) {
    final String canonPath =
        '${mirrorPath.substring(0, mirrorPath.length - '.deck'.length)}.ctdeck';
    if (!File(canonPath).existsSync()) {
      fail('$mirrorPath: mirror without a canon file');
    }
  }
  return failures == 0 ? 0 : 1;
}

List<CardImage> _readCanon(String path) =>
    decodeCanon(File(path).readAsBytesSync());

String _mirrorPathFor(String canonPath) =>
    '${canonPath.substring(0, canonPath.length - '.ctdeck'.length)}.deck';

List<String> _findCanonFiles(List<String> paths) =>
    _findFiles(paths, '.ctdeck');

List<String> _findFiles(List<String> paths, String extension) {
  final found = <String>[];
  for (final String path in paths) {
    if (FileSystemEntity.isDirectorySync(path)) {
      final Iterable<File> files = Directory(path)
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith(extension));
      found.addAll(files.map((File f) => f.path));
    } else if (path.endsWith(extension)) {
      found.add(path);
    }
  }
  return found..sort();
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
