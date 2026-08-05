import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

ProcessResult _deckconv(List<String> args) => Process.runSync(
  Platform.resolvedExecutable,
  ['run', 'comtran:deckconv', ...args],
);

void main() {
  late Directory dir;
  late String canonPath;
  late String mirrorPath;

  List<CardImage> deckOf(String text) =>
      mirrorToDeck(text.isEmpty || text.endsWith('\n') ? text : '$text\n');

  setUp(() {
    dir = Directory.systemTemp.createTempSync('deckconv_test');
    canonPath = '${dir.path}/a.ctd';
    mirrorPath = '${dir.path}/a.ct';
    final List<CardImage> deck = deckOf('HELLO\nWORLD 99.\n');
    File(canonPath).writeAsBytesSync(encodeCanon(deck));
    File(mirrorPath).writeAsStringSync(deckToMirror(deck));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('usage errors exit 2', () {
    expect(_deckconv([]).exitCode, 2);
    expect(_deckconv(['no-such-command']).exitCode, 2);
    expect(_deckconv(['to-canon', 'one-arg-only']).exitCode, 2);
  });

  test('check passes a fresh pair', () {
    final ProcessResult r = _deckconv(['check', dir.path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('OK'));
  });

  test('check fails a stale mirror', () {
    File(mirrorPath).writeAsStringSync('TAMPERED\n');
    final ProcessResult r = _deckconv(['check', dir.path]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('stale mirror'));
  });

  test('check fails a missing mirror', () {
    File(mirrorPath).deleteSync();
    final ProcessResult r = _deckconv(['check', dir.path]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('missing'));
  });

  test('check fails an orphan mirror', () {
    File(canonPath).deleteSync();
    final ProcessResult r = _deckconv(['check', dir.path]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('mirror without a canon file'));
  });

  test('check fails a corrupt canon file', () {
    File(canonPath).writeAsBytesSync([1, 2, 3]);
    expect(_deckconv(['check', dir.path]).exitCode, 1);
  });

  test('check fails a nonexistent path', () {
    expect(_deckconv(['check', '${dir.path}/no-such-dir']).exitCode, 1);
  });

  test('check fails an empty directory', () {
    final empty = Directory('${dir.path}/empty')..createSync();
    expect(_deckconv(['check', empty.path]).exitCode, 1);
  });

  test('check passes a fresh pair addressed by its mirror path', () {
    final ProcessResult r = _deckconv(['check', mirrorPath]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('OK'));
  });

  test('check reports the real status when a stale pair is addressed by its '
      'mirror path', () {
    File(mirrorPath).writeAsStringSync('TAMPERED\n');
    final ProcessResult r = _deckconv(['check', mirrorPath]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('stale mirror'));
  });

  test('check aggregates several files: ok, stale, and orphan mirror '
      '(TSTT-1)', () {
    final bCanon = '${dir.path}/b.ctd';
    final bMirror = '${dir.path}/b.ct';
    final List<CardImage> bDeck = deckOf('STALE\n');
    File(bCanon).writeAsBytesSync(encodeCanon(bDeck));
    File(bMirror).writeAsStringSync('TAMPERED\n');
    final orphanMirror = '${dir.path}/c.ct';
    File(orphanMirror).writeAsStringSync('ORPHAN\n');

    final ProcessResult r = _deckconv(['check', dir.path]);
    expect(r.exitCode, 1);
    expect(r.stdout, contains('OK: $canonPath'));
    expect(r.stderr, contains('stale mirror'));
    expect(r.stderr, contains('mirror without a canon file'));
  });

  test('check finds a deck named directly under a dot-prefixed directory', () {
    final hidden = Directory('${dir.path}/.hidden/decks')
      ..createSync(recursive: true);
    final hiddenCanon = '${hidden.path}/h.ctd';
    final hiddenMirror = '${hidden.path}/h.ct';
    final List<CardImage> deck = deckOf('HIDDEN\n');
    File(hiddenCanon).writeAsBytesSync(encodeCanon(deck));
    File(hiddenMirror).writeAsStringSync(deckToMirror(deck));
    final ProcessResult r = _deckconv(['check', hidden.path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('h.ctd'));
  });

  test('check skips a hidden directory discovered below a normal root', () {
    final nested = Directory('${dir.path}/.git/objects')
      ..createSync(recursive: true);
    File('${nested.path}/x.ctd').writeAsBytesSync([1, 2, 3]);
    final ProcessResult r = _deckconv(['check', dir.path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, isNot(contains('x.ctd')));
  });

  test('writeAtomic leaves the original file untouched when write throws', () {
    final path = '${dir.path}/atomic.txt';
    File(path).writeAsStringSync('original');
    expect(
      () => writeAtomic(path, (File f) {
        f.writeAsStringSync('partial');
        throw const FormatException('boom');
      }),
      throwsFormatException,
    );
    expect(File(path).readAsStringSync(), 'original');
    final bool hasTmp = Directory(
      dir.path,
    ).listSync().any((FileSystemEntity e) => e.path.endsWith('.tmp'));
    expect(hasTmp, isFalse);
  });

  test('writeAtomic replaces the file only after a successful write', () {
    final path = '${dir.path}/atomic2.txt';
    writeAtomic(path, (File f) => f.writeAsStringSync('new content'));
    expect(File(path).readAsStringSync(), 'new content');
  });

  test('to-text writes the mirror to stdout for git textconv', () {
    final ProcessResult r = _deckconv(['to-text', canonPath]);
    expect(r.exitCode, 0);
    expect(r.stdout, File(mirrorPath).readAsStringSync());
  });

  test('to-canon and to-text round-trip through files', () {
    final canon2 = '${dir.path}/b.ctd';
    final mirror2 = '${dir.path}/b.ct';
    expect(_deckconv(['to-canon', mirrorPath, canon2]).exitCode, 0);
    expect(File(canon2).readAsBytesSync(), File(canonPath).readAsBytesSync());
    // to-canon also writes the sibling mirror, so the pair stays complete
    // (MCP-11).
    expect(
      File(mirror2).readAsStringSync(),
      File(mirrorPath).readAsStringSync(),
    );
    File(canon2).deleteSync();
    File(mirror2).deleteSync(); // Leave no stray pair behind.
    expect(_deckconv(['to-text', canonPath, mirror2]).exitCode, 0);
    expect(
      File(mirror2).readAsStringSync(),
      File(mirrorPath).readAsStringSync(),
    );
  });

  test('to-canon reads the mirror from standard input', () async {
    final canon2 = '${dir.path}/b.ctd';
    final Process process = await Process.start(Platform.resolvedExecutable, [
      'run',
      'comtran:deckconv',
      'to-canon',
      '-',
      canon2,
    ]);
    process.stdin.write(File(mirrorPath).readAsStringSync());
    await process.stdin.close();
    expect(await process.exitCode, 0);
    expect(File(canon2).readAsBytesSync(), File(canonPath).readAsBytesSync());
  });

  test('to-canon rejects the wrong argument count in both directions', () {
    expect(_deckconv(['to-canon', 'one-arg-only']).exitCode, 2);
    expect(_deckconv(['to-canon', mirrorPath, canonPath, 'extra']).exitCode, 2);
  });

  test('to-text rejects the wrong argument count', () {
    expect(_deckconv(['to-text', canonPath, mirrorPath, 'extra']).exitCode, 2);
  });

  test('regen and check reject zero arguments', () {
    expect(_deckconv(['regen']).exitCode, 2);
    expect(_deckconv(['check']).exitCode, 2);
  });

  test('to-canon reports the CLI error path for malformed mirror text', () {
    final badMirror = '${dir.path}/bad.ct';
    File(badMirror).writeAsStringSync('TRAILING SPACE \n');
    final ProcessResult r = _deckconv([
      'to-canon',
      badMirror,
      '${dir.path}/bad.ctd',
    ]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('error:'));
    expect(r.stderr, contains('normal form'));
    expect(File('${dir.path}/bad.ctd').existsSync(), isFalse);
  });

  test('to-canon rejects mirror text with no final newline', () {
    final badMirror = '${dir.path}/bad.ct';
    File(badMirror).writeAsStringSync('HELLO');
    final ProcessResult r = _deckconv([
      'to-canon',
      badMirror,
      '${dir.path}/bad.ctd',
    ]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('newline'));
  });

  test('to-canon rejects a glyph outside the source set', () {
    final badMirror = '${dir.path}/bad.ct';
    File(badMirror).writeAsStringSync('A%B\n');
    final ProcessResult r = _deckconv([
      'to-canon',
      badMirror,
      '${dir.path}/bad.ctd',
    ]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('column 2'));
  });

  test('to-canon reports the CLI error path for a missing input file', () {
    final ProcessResult r = _deckconv([
      'to-canon',
      '${dir.path}/no-such.ct',
      '${dir.path}/bad.ctd',
    ]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('error:'));
    expect(r.stderr, contains('no-such.ct'));
  });

  test('to-text reports the CLI error path for a missing input file', () {
    final ProcessResult r = _deckconv(['to-text', '${dir.path}/no-such.ctd']);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('error:'));
    expect(r.stderr, contains('no-such.ctd'));
  });

  test('regen rewrites a stale mirror', () {
    final String fresh = File(mirrorPath).readAsStringSync();
    File(mirrorPath).writeAsStringSync('TAMPERED\n');
    expect(_deckconv(['regen', canonPath]).exitCode, 0);
    expect(File(mirrorPath).readAsStringSync(), fresh);
  });

  test('regen fails when nothing matches', () {
    final empty = Directory('${dir.path}/empty')..createSync();
    expect(_deckconv(['regen', empty.path]).exitCode, 1);
  });

  test('regen searches a directory of canon files', () {
    final String fresh = File(mirrorPath).readAsStringSync();
    File(mirrorPath).writeAsStringSync('TAMPERED\n');
    final ProcessResult r = _deckconv(['regen', dir.path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('regenerated $mirrorPath'));
    expect(File(mirrorPath).readAsStringSync(), fresh);
  });
}
