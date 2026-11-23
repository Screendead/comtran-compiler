import 'dart:io';

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

/// One run of the CLI: its arguments, the exit status it must give, the
/// text its two streams must hold, and what it must leave on disk.
typedef _Case = ({
  String name,
  List<String> args,
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
    // A mistyped command in a hook or a CI step must fail, not pass.
    (
      name: 'an unknown command is a usage error',
      args: ['no-such-command'],
      exit: 2,
      out: [],
      err: ['Usage:'],
      after: null,
    ),
    (
      name: 'check reports ok, stale and orphan files together',
      args: ['check', p('mixed')],
      exit: 1,
      out: ['OK: ${p('mixed/a.ctd')}'],
      err: ['stale mirror', 'mirror without a canon file'],
      after: null,
    ),
    (
      name: 'check fails an empty directory',
      args: ['check', p('empty')],
      exit: 1,
      out: [],
      err: ['no canon or mirror files'],
      after: null,
    ),
    (
      name: 'to-text writes the mirror to stdout for git textconv',
      args: ['to-text', p('fresh/a.ctd')],
      exit: 0,
      out: [],
      err: [],
      after: () => expect(
        results['to-text writes the mirror to stdout for git textconv']!.stdout,
        mirrorText,
      ),
    ),
    (
      name: 'to-canon writes the canon file and its sibling mirror (MCP-11)',
      args: ['to-canon', p('fresh/a.ct'), p('out/file.ctd')],
      exit: 0,
      out: [],
      err: [],
      after: () {
        expect(File(p('out/file.ctd')).readAsBytesSync(), canonBytes);
        expect(File(p('out/file.ct')).readAsStringSync(), mirrorText);
      },
    ),
    (
      name: 'to-canon rejects malformed mirror text and writes nothing',
      args: ['to-canon', p('bad.ct'), p('out/bad.ctd')],
      exit: 1,
      out: [],
      err: ['error:', 'normal form'],
      after: () => expect(File(p('out/bad.ctd')).existsSync(), isFalse),
    ),
    (
      name: 'regen rewrites a stale mirror found in a directory',
      args: ['regen', p('stale')],
      exit: 0,
      out: ['regenerated ${p('stale/a.ct')}'],
      err: [],
      after: () => expect(File(p('stale/a.ct')).readAsStringSync(), mirrorText),
    ),
  ];

  setUpAll(() async {
    writePair(p('fresh/a.ctd'), mirrorText);
    writePair(p('mixed/a.ctd'), mirrorText);
    writePair(p('mixed/b.ctd'), 'STALE\n', mirror: 'TAMPERED\n');
    File(p('mixed/c.ct')).writeAsStringSync('ORPHAN\n');
    writePair(p('stale/a.ctd'), mirrorText, mirror: 'TAMPERED\n');
    Directory(p('empty')).createSync();
    Directory(p('out')).createSync();
    File(p('bad.ct')).writeAsStringSync('TRAILING SPACE \n');

    Future<void> run(_Case c) async {
      results[c.name] = await Process.run(Platform.resolvedExecutable, [
        'run',
        'comtran:deckconv',
        ...c.args,
      ]);
    }

    // The first run builds the snapshot `dart run` caches; the others then
    // start from it at once instead of each compiling the CLI again.
    await run(cases.first);
    await Future.wait(cases.skip(1).map(run));
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

  test('a directory named directly is searched though it starts with a dot, '
      'and a hidden directory found below it is skipped', () {
    writePair(p('.hidden/decks/h.ctd'), mirrorText);
    File(p('.hidden/decks/.git/objects/x.ctd'))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    expect(findDeckFiles([p('.hidden/decks')], canonExtension), [
      p('.hidden/decks/h.ctd'),
    ]);
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
