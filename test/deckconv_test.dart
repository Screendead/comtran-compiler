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
    canonPath = '${dir.path}/a.ctdeck';
    mirrorPath = '${dir.path}/a.deck';
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
    final Directory empty = Directory('${dir.path}/empty')..createSync();
    expect(_deckconv(['check', empty.path]).exitCode, 1);
  });

  test('to-text writes the mirror to stdout for git textconv', () {
    final ProcessResult r = _deckconv(['to-text', canonPath]);
    expect(r.exitCode, 0);
    expect(r.stdout, File(mirrorPath).readAsStringSync());
  });

  test('to-canon and to-text round-trip through files', () {
    final String canon2 = '${dir.path}/b.ctdeck';
    final String mirror2 = '${dir.path}/b.deck';
    expect(_deckconv(['to-canon', mirrorPath, canon2]).exitCode, 0);
    expect(File(canon2).readAsBytesSync(), File(canonPath).readAsBytesSync());
    File(canon2).deleteSync(); // Leave no orphan pair behind.
    expect(_deckconv(['to-text', canonPath, mirror2]).exitCode, 0);
    expect(
      File(mirror2).readAsStringSync(),
      File(mirrorPath).readAsStringSync(),
    );
  });

  test('regen rewrites a stale mirror', () {
    final String fresh = File(mirrorPath).readAsStringSync();
    File(mirrorPath).writeAsStringSync('TAMPERED\n');
    expect(_deckconv(['regen', canonPath]).exitCode, 0);
    expect(File(mirrorPath).readAsStringSync(), fresh);
  });

  test('regen fails when nothing matches', () {
    final Directory empty = Directory('${dir.path}/empty')..createSync();
    expect(_deckconv(['regen', empty.path]).exitCode, 1);
  });
}
