/// Deck converter — the T1 tool of `docs/HANDOVER.md`.
///
/// Converts between canon card-image files (`.ctdeck`) and their text
/// mirrors (`.deck`), regenerates mirrors, and checks that committed mirrors
/// are fresh. Formats: `docs/design/deck-format.md`; authority rules: D0.5.
library;

import 'dart:convert';
import 'dart:io';

import 'package:comtran/comtran.dart';

const String _usage = '''
Usage: dart run comtran:deckconv <command> ...

  to-canon <in.deck> <out.ctdeck>   convert a mirror to a canon file, and
                                    write its sibling .deck mirror too
                                    (- reads the mirror from standard input)
  to-text <in.ctdeck> [<out.deck>]  convert a canon file to mirror text
                                    (- or no path given: standard output)
  regen <path>...                   regenerate the .deck mirror next to each
                                    .ctdeck file (directories are searched)
  check <path>...                   verify that each canon file round-trips
                                    and that its committed mirror is fresh
''';

void main(List<String> arguments) {
  // Dart discards main's return value; the exit status must be set explicitly.
  exitCode = _run(arguments);
}

int _run(List<String> arguments) {
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
  final String mirrorText = args[0] == '-'
      ? _readStdin()
      : File(args[0]).readAsStringSync();
  final List<CardImage> deck = mirrorToDeck(mirrorText);
  final String outCanonPath = args[1];
  final String outMirrorPath = mirrorPathFor(outCanonPath);
  final String mirror = deckToMirror(deck);
  writeAtomic(outCanonPath, (File f) => f.writeAsBytesSync(encodeCanon(deck)));
  // Write the sibling mirror too, so to-canon never leaves a canon file with
  // no mirror (MCP-11). mirrorToDeck accepts normal form only, so mirror
  // already equals the input text; this is not a second, different write.
  writeAtomic(outMirrorPath, (File f) => f.writeAsStringSync(mirror));
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
    writeAtomic(args[1], (File f) => f.writeAsStringSync(text));
  }
  return 0;
}

int _regen(List<String> args) {
  if (args.isEmpty) {
    stderr.write(_usage);
    return 2;
  }
  final List<String> canonFiles = findDeckFiles(args, canonExtension);
  if (canonFiles.isEmpty) {
    stderr.writeln('error: no canon files found under: ${args.join(' ')}');
    return 1;
  }
  for (final canonPath in canonFiles) {
    final String mirrorPath = mirrorPathFor(canonPath);
    final String text = deckToMirror(_readCanon(canonPath));
    writeAtomic(mirrorPath, (File f) => f.writeAsStringSync(text));
    stdout.writeln('regenerated $mirrorPath');
  }
  return 0;
}

int _check(List<String> args) {
  if (args.isEmpty) {
    stderr.write(_usage);
    return 2;
  }
  final List<DeckCheckResult> results = checkDeckPaths(args);
  if (results.isEmpty) {
    stderr.writeln(
      'FAIL: no canon or mirror files found under: ${args.join(' ')}',
    );
    return 1;
  }
  var failures = 0;
  for (final result in results) {
    if (result.passed) {
      stdout.writeln(result.message);
    } else {
      stderr.writeln('FAIL: ${result.message}');
      failures++;
    }
  }
  return failures == 0 ? 0 : 1;
}

List<CardImage> _readCanon(String path) =>
    decodeCanon(File(path).readAsBytesSync());

// Stdin has no bulk synchronous read; read byte by byte to end of input,
// so to-canon can take a generated mirror piped in without going async.
String _readStdin() {
  final bytes = <int>[];
  int byte = stdin.readByteSync();
  while (byte != -1) {
    bytes.add(byte);
    byte = stdin.readByteSync();
  }
  return utf8.decode(bytes);
}
