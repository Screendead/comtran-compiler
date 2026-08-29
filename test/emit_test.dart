/// The `--emit` stage dumps (`docs/design/emit-stages.md`): the three
/// committed reconstruction goldens, the three attested dumps, and the
/// stopped-stage line.
///
/// Regenerate the goldens with one command, from the repository root:
///
///     dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctd \
///       --date=10/18/61 --time=2.45 \
///       '--title=COMPILATION OF SAMPLE PROBLEM' \
///       --emit-scan=test/goldens/90.05-payroll.scan \
///       --emit-parse=test/goldens/90.05-payroll.parse \
///       --emit-semantics=test/goldens/90.05-payroll.semantics
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// Compiles the 90.05 job deck with the golden listing's fixed page head.
ProcessResult _compile(List<String> options) =>
    Process.runSync(Platform.resolvedExecutable, [
      'run',
      'comtran:comtranc',
      jobDeckPath,
      '--date=10/18/61',
      '--time=2.45',
      '--title=COMPILATION OF SAMPLE PROBLEM',
      ...options,
    ]);

/// The lines under job [number]'s `* JOB n` header in [dump], less the
/// blank line that separates the section from the next job and less the
/// empty tail the dump's closing newline leaves.
List<String> _jobSection(String dump, int number) {
  final List<String> lines = dump.split('\n')..removeLast();
  final int start = lines.indexOf(jobHeader(number)) + 1;
  final int next = lines.indexOf(jobHeader(number + 1));
  return lines.sublist(start, next < 0 ? lines.length : next - 1);
}

/// The rows of the semantics dump's STORAGE section, split on tabs: every
/// line between the section header and the blank line that ends it.
List<List<String>> _storageRows(List<String> dump) {
  final int start = dump.indexOf('* STORAGE') + 1;
  return [
    for (final String line in dump.sublist(start, dump.indexOf('', start)))
      line.split('\t'),
  ];
}

void main() {
  late Directory dumps;
  late ProcessResult run;

  String dump(String stage) => File('${dumps.path}/$stage').readAsStringSync();

  String golden(String name) =>
      File('test/goldens/90.05-payroll.$name').readAsStringSync();

  setUpAll(() {
    dumps = Directory.systemTemp.createTempSync('comtran-emit');
    run = _compile([
      for (final String stage in ['cards', 'scan', 'parse', 'semantics'])
        '--emit-$stage=${dumps.path}/$stage',
      '--emit-listing=${dumps.path}/listing',
      '--emit-object=${dumps.path}/object',
    ]);
  });

  tearDownAll(() => dumps.deleteSync(recursive: true));

  group('the 90.05 dumps', () {
    test('the reconstruction dumps reproduce their goldens', () {
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(dump('scan'), golden('scan'));
      expect(dump('parse'), golden('parse'));
      expect(dump('semantics'), golden('semantics'));
    });

    test('the attested dumps reproduce the mirror and the listings', () {
      expect(
        dump('cards'),
        File('test/fixtures/90.05-payroll-job.ct').readAsStringSync(),
      );
      expect(dump('listing'), golden('listing'));
      expect(run.stdout, golden('listing'));
      // The object pages start at PAGE 8, so this also pins the first
      // page the driver computes after six source pages and the one
      // loader-card page stage 3 will count rather than assume.
      expect(dump('object'), golden('storage-map'));
    });

    test('the flags change neither output stream nor the exit code', () {
      final ProcessResult plain = _compile(const []);
      expect(run.exitCode, plain.exitCode);
      expect(run.stdout, plain.stdout);
      expect(plain.stderr, isEmpty);
      expect(run.stderr, plain.stderr);
    });

    test('the STORAGE section prints the M3-14 fixture rows', () {
      final List<List<String>> printed = _storageRows(
        File('${dumps.path}/semantics').readAsLinesSync(),
      );
      final List<List<String>> fixture = [
        for (final String line in File(
          'test/fixtures/90.05-storage-section.tsv',
        ).readAsLinesSync())
          if (line.isNotEmpty && !line.startsWith('#')) line.split('\t'),
      ];
      expect(printed, hasLength(fixture.length));
      for (var i = 0; i < fixture.length; i++) {
        final List<String> row = fixture[i];
        expect(printed[i].sublist(0, 3), row.sublist(0, 3), reason: row[0]);
        // The fixture leaves the symbol blank on every line the 1962
        // listing printed unlabelled.
        if (row.length > 3 && row[3].isNotEmpty) {
          expect(printed[i][3], row[3], reason: row[0]);
        }
      }
    });
  });

  test('a malformed emit flag is a usage error', () {
    for (final flag in ['--emit-parse=', '--emit-all=x', '-x', '-cx']) {
      final ProcessResult run = _compile([flag]);
      expect(run.exitCode, 2, reason: flag);
      expect(run.stdout, isEmpty, reason: flag);
      expect(run.stderr, startsWith('Usage:'), reason: flag);
    }
  });

  group('the default dump paths', () {
    // Each test gets its own copy of the job deck, so one test's
    // default-named dumps cannot satisfy another's assertions.
    late Directory dir;
    late String deck;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('comtran-emit-default');
      deck = '${dir.path}/payroll.ctd';
      File(jobDeckPath).copySync(deck);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    ProcessResult compile(List<String> options) =>
        Process.runSync(Platform.resolvedExecutable, [
          'run',
          'comtran:comtranc',
          deck,
          '--date=10/18/61',
          '--time=2.45',
          '--title=COMPILATION OF SAMPLE PROBLEM',
          ...options,
        ]);

    test('the -cpsSl bundle writes all five dumps next to the deck', () {
      final ProcessResult run = compile(const ['-cpsSl']);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      for (final stage in ['cards', 'scan', 'semantics', 'listing']) {
        expect(File('${dir.path}/payroll.$stage').existsSync(), isTrue);
      }
      expect(
        File('${dir.path}/payroll.parse').readAsStringSync(),
        golden('parse'),
      );
    });

    test('a bare long flag writes the default file', () {
      final ProcessResult run = compile(const ['--emit-semantics']);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(
        File('${dir.path}/payroll.semantics').readAsStringSync(),
        golden('semantics'),
      );
    });

    test('a default that equals the deck path is refused', () {
      final trap = '${dir.path}/oops.cards';
      File(jobDeckPath).copySync(trap);
      final ProcessResult run = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'comtran:comtranc',
        trap,
        '-c',
      ]);
      expect(run.exitCode, 2);
      expect(run.stderr, contains('the deck itself'));
      expect(File(trap).readAsBytesSync(), File(jobDeckPath).readAsBytesSync());
    });

    test('an explicit path after -A replaces that stage default', () {
      final ProcessResult run = compile([
        '-A',
        '--emit-parse=${dir.path}/custom.tree',
      ]);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(
        File('${dir.path}/custom.tree').readAsStringSync(),
        golden('parse'),
      );
      expect(File('${dir.path}/payroll.parse').existsSync(), isFalse);
      expect(File('${dir.path}/payroll.listing').existsSync(), isTrue);
    });
  });

  test('a stopped job prints the stopped line each stage calls for', () {
    // A Data Description constant over 120 characters stops the first
    // job in the front end (D7.9; D10.2), so neither the parser nor the
    // semantic layer runs over it.
    final List<String> lines = [
      r'$CMPLE BAD',
      '      *DATA',
      dataCard(level: '2', description: "'${'A' * 33}", continued: true),
      dataCard(description: 'B' * 34, continued: true),
      dataCard(description: 'C' * 34, continued: true),
      dataCard(description: "${'D' * 25}'"),
      '      *FINISH',
      r'$CMPLE GOOD',
      '      *PROCEDURE',
      '            STOP RUN.',
      '      *FINISH',
    ];
    final DeckCompilation deck = compileDeck(
      mirrorToDeck('${lines.join('\n')}\n'),
    );
    expect(deck.jobs.first.parse, isNull);
    expect(deck.jobs.first.semantics, isNull);
    final String scan = emitScan(deck);
    final String parse = emitParse(deck);
    final String semantics = emitSemantics(deck);
    for (final dump in [scan, parse, semantics]) {
      expect(dump, startsWith('$reconstructionLabel\n${jobHeader(1)}\n'));
    }

    // The front end discards the group it was scanning when the stop
    // hit, so job 1's scan keeps its compile card and nothing else.
    expect(_jobSection(scan, 1), [r'COMPILE  $CMPLE BAD', stageStopped]);
    expect(_jobSection(parse, 1), [stageNotReached]);
    expect(_jobSection(semantics, 1), [stageNotReached]);

    expect(_jobSection(scan, 2), [
      r'COMPILE  $CMPLE GOOD',
      '*PROCEDURE',
      '1,00  SENTENCE  STOP RUN',
    ]);
    expect(_jobSection(parse, 2), [
      r'compile-card $CMPLE deck GOOD',
      'procedure-group',
      '  1,00 sentence',
      '    1,01 stop-clause RUN',
    ]);
    // Job 2 declares no data, so each semantics section prints its
    // header alone, and no stopped line closes the section.
    expect(_jobSection(semantics, 2).where((String line) => line.isNotEmpty), [
      '* STORAGE',
      '* DICTIONARY',
      '* RECORDS',
      '* ITEMS',
      '* RESOLUTIONS',
      '* CORRESPONDING',
      '* KEYS',
      '* DELETED',
    ]);
  });

  test('a mid-semantics stop closes the section with the stopped line', () {
    // The 24th hierarchy level draws 201,00 at severity 5 (D9.7), a
    // stop inside the semantic layer itself: the phase returns its
    // partial result, so the dump is truncated, not absent.
    final List<String> lines = [
      r'$CMPLE DEEP',
      '      *DATA',
      for (var level = 1; level < 24; level++)
        dataCard(name: 'G$level', level: '$level'),
      dataCard(name: 'FOOT', level: '24', description: 'A'),
      '      *FINISH',
    ];
    final DeckCompilation deck = compileDeck(
      mirrorToDeck('${lines.join('\n')}\n'),
    );
    expect(deck.jobs.single.semantics!.stopped, isTrue);
    expect(_jobSection(emitSemantics(deck), 1).last, stageStopped);
  });

  test('the object dump prints one marker line per dead job', () {
    // Job 1 stops in the front end (D7.9), job 2 reaches the generator
    // and refuses (DISPLAY, [J 90.01.01]), job 3 stops inside the
    // generator (msg 172, the 501st pool entry; D9.7), and job 4
    // compiles. The attested dump takes no job headers, so the three
    // markers print in sequence and job 4 opens with its own page head.
    final List<String> lines = [
      r'$CMPLE BAD',
      '      *DATA',
      dataCard(level: '2', description: "'${'A' * 33}", continued: true),
      dataCard(description: 'B' * 34, continued: true),
      dataCard(description: 'C' * 34, continued: true),
      dataCard(description: "${'D' * 25}'"),
      '      *FINISH',
      r'$CMPLE UGLY',
      '      *PROCEDURE',
      '            DISPLAY 45.',
      '            STOP RUN.',
      '      *FINISH',
      r'$CMPLE FULL',
      '      *DATA',
      dataCard(
        name: 'N',
        level: '1',
        mode: 'I',
        justify: 'R',
        description: '999',
      ),
      '      *PROCEDURE',
      for (var k = 2; k < 497; k++) '            SET N = $k.',
      '            STOP RUN.',
      '      *FINISH',
      r'$CMPLE GOOD',
      '      *PROCEDURE',
      '            STOP RUN.',
      '      *FINISH',
    ];
    final Directory dir = Directory.systemTemp.createTempSync(
      'comtran-emit-object',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final deck = '${dir.path}/jobs.ctd';
    File(
      deck,
    ).writeAsBytesSync(encodeCanon(mirrorToDeck('${lines.join('\n')}\n')));
    final ProcessResult run = Process.runSync(Platform.resolvedExecutable, [
      'run',
      'comtran:comtranc',
      deck,
      '--date=10/18/61',
      '--time=2.45',
      '--emit-object=${dir.path}/object',
    ]);
    // The stop and the refusal each fail the run (J 90.04.02).
    expect(run.exitCode, 1, reason: '${run.stderr}');
    final List<String> dump = File('${dir.path}/object').readAsLinesSync();
    expect(dump[0], stageNotReached);
    expect(dump[1], '* NOT RECOVERED: DISPLAY ([J 90.01.01])');
    expect(dump[2], stageStopped);
    // Job 4's one source page and its loader-card page put its object
    // listing at PAGE 3.
    expect(dump[3], contains('PAGE  3'));
    expect(dump.last, endsWith('START  GN)000'));
  });
}
