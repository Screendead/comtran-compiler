/// The `--emit` stage dumps (`docs/design/emit-stages.md`): the three
/// committed reconstruction goldens, the two attested dumps, and the
/// stopped-stage line.
///
/// Regenerate the goldens with one command, from the repository root:
///
///     dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctdeck \
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

    test('the attested dumps reproduce the mirror and the listing', () {
      expect(
        dump('cards'),
        File('test/fixtures/90.05-payroll-job.deck').readAsStringSync(),
      );
      expect(dump('listing'), golden('listing'));
      expect(run.stdout, golden('listing'));
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

  test('an empty emit path is a usage error', () {
    final ProcessResult run = _compile(const ['--emit-parse=']);
    expect(run.exitCode, 2);
    expect(run.stdout, isEmpty);
    expect(run.stderr, startsWith('Usage:'));
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
}
