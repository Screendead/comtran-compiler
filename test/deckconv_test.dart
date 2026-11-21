import 'dart:convert';
import 'dart:io';

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

/// One run of the CLI: its arguments, the exit status it must give, the
/// text its two streams must hold, and what it must leave on disk.
typedef _Case = ({
  String name,
  List<String> args,
  String? input,
  int exit,
  List<String> out,
  List<String> err,
  void Function()? after,
});

void main() {
  final Directory dir = Directory.systemTemp.createTempSync('deckconv_test');
  final String mirrorText = deckToMirror(mirrorToDeck('HELLO\nWORLD 99.\n'));
  final List<int> canonBytes = encodeCanon(mirrorToDeck(mirrorText));
  final results = <String, ProcessResult>{};

  String p(String relative) => '${dir.path}/$relative';

  void writePair(String canonPath, String text, {String? mirror}) {
    final List<CardImage> deck = mirrorToDeck(text);
    File(canonPath)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(encodeCanon(deck));
    File(
      mirrorPathFor(canonPath),
    ).writeAsStringSync(mirror ?? deckToMirror(deck));
  }

  final List<_Case> cases = [
    for (final List<String> args in [
      <String>[],
      ['no-such-command'],
      ['to-canon', 'one-arg-only'],
      ['to-canon', 'a.ct', 'a.ctd', 'extra'],
      ['to-text', 'a.ctd', 'a.ct', 'extra'],
      ['regen'],
      ['check'],
    ])
      (
        name: 'usage error: ${args.join(' ')}',
        args: args,
        input: null,
        exit: 2,
        out: [],
        err: ['Usage:'],
        after: null,
      ),
    (
      name: 'check passes a fresh pair',
      args: ['check', p('fresh')],
      input: null,
      exit: 0,
      out: ['OK: ${p('fresh/a.ctd')}'],
      err: [],
      after: null,
    ),
    (
      name: 'check reports ok, stale and orphan files together',
      args: ['check', p('mixed')],
      input: null,
      exit: 1,
      out: ['OK: ${p('mixed/a.ctd')}'],
      err: ['stale mirror', 'mirror without a canon file'],
      after: null,
    ),
    (
      name: 'check fails an empty directory',
      args: ['check', p('empty')],
      input: null,
      exit: 1,
      out: [],
      err: ['no canon or mirror files'],
      after: null,
    ),
    (
      name: 'to-text writes the mirror to stdout for git textconv',
      args: ['to-text', p('fresh/a.ctd')],
      input: null,
      exit: 0,
      out: [],
      err: [],
      after: () => expect(
        results['to-text writes the mirror to stdout for git textconv']!.stdout,
        mirrorText,
      ),
    ),
    (
      name: 'to-text writes the mirror to a file',
      args: ['to-text', p('fresh/a.ctd'), p('out/text.ct')],
      input: null,
      exit: 0,
      out: [],
      err: [],
      after: () =>
          expect(File(p('out/text.ct')).readAsStringSync(), mirrorText),
    ),
    (
      name: 'to-text reports a missing input file',
      args: ['to-text', p('no-such.ctd')],
      input: null,
      exit: 1,
      out: [],
      err: ['error:', 'no-such.ctd'],
      after: null,
    ),
    (
      name: 'to-canon writes the canon file and its sibling mirror (MCP-11)',
      args: ['to-canon', p('fresh/a.ct'), p('out/file.ctd')],
      input: null,
      exit: 0,
      out: [],
      err: [],
      after: () {
        expect(File(p('out/file.ctd')).readAsBytesSync(), canonBytes);
        expect(File(p('out/file.ct')).readAsStringSync(), mirrorText);
      },
    ),
    (
      name: 'to-canon reads the mirror from standard input',
      args: ['to-canon', '-', p('out/stdin.ctd')],
      input: mirrorText,
      exit: 0,
      out: [],
      err: [],
      after: () =>
          expect(File(p('out/stdin.ctd')).readAsBytesSync(), canonBytes),
    ),
    (
      name: 'to-canon rejects malformed mirror text and writes nothing',
      args: ['to-canon', p('bad.ct'), p('out/bad.ctd')],
      input: null,
      exit: 1,
      out: [],
      err: ['error:', 'normal form'],
      after: () => expect(File(p('out/bad.ctd')).existsSync(), isFalse),
    ),
    (
      name: 'regen rewrites a stale mirror found in a directory',
      args: ['regen', p('stale')],
      input: null,
      exit: 0,
      out: ['regenerated ${p('stale/a.ct')}'],
      err: [],
      after: () => expect(File(p('stale/a.ct')).readAsStringSync(), mirrorText),
    ),
    (
      name: 'regen fails when nothing matches',
      args: ['regen', p('empty')],
      input: null,
      exit: 1,
      out: [],
      err: ['no canon files'],
      after: null,
    ),
  ];

  // Every case reads or writes its own paths, so the CLI runs all at once:
  // one process per case is the cost of each run, not of each test.
  setUpAll(() async {
    writePair(p('fresh/a.ctd'), mirrorText);
    writePair(p('mixed/a.ctd'), mirrorText);
    writePair(p('mixed/b.ctd'), 'STALE\n', mirror: 'TAMPERED\n');
    File(p('mixed/c.ct')).writeAsStringSync('ORPHAN\n');
    writePair(p('stale/a.ctd'), mirrorText, mirror: 'TAMPERED\n');
    Directory(p('empty')).createSync();
    Directory(p('out')).createSync();
    File(p('bad.ct')).writeAsStringSync('TRAILING SPACE \n');

    await Future.wait([
      for (final _Case c in cases)
        () async {
          final Process process = await Process.start(
            Platform.resolvedExecutable,
            ['run', 'comtran:deckconv', ...c.args],
          );
          final Future<String> out = process.stdout
              .transform(utf8.decoder)
              .join();
          final Future<String> err = process.stderr
              .transform(utf8.decoder)
              .join();
          if (c.input != null) {
            process.stdin.write(c.input);
          }
          await process.stdin.close();
          final int code = await process.exitCode;
          results[c.name] = ProcessResult(
            process.pid,
            code,
            await out,
            await err,
          );
        }(),
    ]);
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  for (final c in cases) {
    test(c.name, () {
      final ProcessResult r = results[c.name]!;
      expect(r.exitCode, c.exit, reason: '${r.stderr}');
      for (final String text in c.out) {
        expect(r.stdout, contains(text));
      }
      for (final String text in c.err) {
        expect(r.stderr, contains(text));
      }
      c.after?.call();
    });
  }

  test('check reports a canon file whose mirror is missing', () {
    writePair(p('missing/a.ctd'), mirrorText);
    File(p('missing/a.ct')).deleteSync();
    expect(
      checkDeckPaths([p('missing')]).single.status,
      DeckCheckStatus.mirrorMissing,
    );
  });

  test('a directory named directly is searched though it starts with a dot '
      'or sits under one', () {
    writePair(p('.hidden/decks/h.ctd'), mirrorText);
    expect(findDeckFiles([p('.hidden/decks')], canonExtension), [
      p('.hidden/decks/h.ctd'),
    ]);
  });

  test('a hidden directory found below a named root is skipped', () {
    File(p('skip/.git/objects/x.ctd'))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    writePair(p('skip/a.ctd'), mirrorText);
    expect(findDeckFiles([p('skip')], canonExtension), [p('skip/a.ctd')]);
  });

  test('writeAtomic leaves the original file untouched when write throws', () {
    final String path = p('atomic/atomic.txt');
    File(path)
      ..parent.createSync()
      ..writeAsStringSync('original');
    expect(
      () => writeAtomic(path, (File f) {
        f.writeAsStringSync('partial');
        throw const FormatException('boom');
      }),
      throwsFormatException,
    );
    expect(File(path).readAsStringSync(), 'original');
    expect(Directory(p('atomic')).listSync(), hasLength(1));
  });
}
