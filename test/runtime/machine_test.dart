/// The machine assembly (RT-1): the dispatch rule, the step budget, the
/// 1962 sample at the runtime boundary, one program run end to end, and
/// the `--run` flag that carries it to the command line, outcome by
/// outcome.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';
import '../support/deck_fixtures.dart';
import 'runtime_support.dart';

const ListingOptions _options = ListingOptions(date: '10/18/61', time: '2.45');

/// An I/O-free program: one `SET` over two internal-decimal fields, then
/// `STOP RUN`.
final List<String> _source = <String>[
  '      *DATA',
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(
    name: 'TOT',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  SET TOT = NUM + 1.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program whose entry point is a labelled section (D2.1). The `GO TO`
/// ahead of the section runs only if the entry lands on `GN)000`.
final List<String> _section = <String>[
  '      *DATA',
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '            GO TO WRAP.UP.',
  '      PROGRAM.START.  BEGIN SECTION.',
  '            SET NUM = NUM + 1.',
  '            STOP RUN.',
  '            END PROGRAM.START.',
  '      WRAP.UP.  STOP RUN.',
  '      *FINISH',
];

/// A program that never reaches its `STOP RUN`.
final List<String> _loop = <String>[
  '      *DATA',
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  GO TO START.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that trips the base-locator guard: the comparison loads
/// `IDX`'s positional indicator, which nothing has set (RT-2).
final List<String> _guard = <String>[
  '      *DATA',
  dataCard(name: 'TAB', level: '1', quantity: '12'),
  dataCard(
    name: 'CELL',
    level: '2',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(name: 'IDX', level: '1', mode: 'I', justify: 'R', description: '99'),
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  IF NUM GT CELL (IDX) THEN GO TO RTN.',
  '      RTN.  STOP RUN.',
  '      *FINISH',
];

/// Punches [source] into a temporary deck and compiles it with `--run`.
ProcessResult _compileAndRun(List<String> source) {
  final Directory directory = Directory.systemTemp.createTempSync(
    'comtran-run',
  );
  addTearDown(() => directory.deleteSync(recursive: true));
  final path = '${directory.path}/job.ctd';
  File(
    path,
  ).writeAsBytesSync(encodeCanon(mirrorToDeck('${source.join('\n')}\n')));
  return Process.runSync(Platform.resolvedExecutable, [
    'run',
    'comtran:comtranc',
    path,
    '--run',
  ]);
}

void main() {
  group('the dispatch rule', () {
    test('an entry with no handler names itself', () {
      // `TSX IOC)8,4`, the GET of M5 (M4-17).
      expect(
        () => machine({start: tsx(8)}).run(maxSteps: 4),
        throwsA(
          isA<UnimplementedRuntimeEntry>().having(
            (UnimplementedRuntimeEntry e) => e.toString(),
            'toString',
            'unimplemented runtime entry IOC)8',
          ),
        ),
      );
    });

    test('the budget bounds a program that never stops', () {
      // D5.1 as amended: the emulator reproduces non-termination, so
      // the cap is the caller's and the run returns.
      final RunResult result = machine({
        start: typeB(0x010, address: start), // TRA *
      }).run(maxSteps: 50);
      expect(result.outcome, RunOutcome.stepLimit);
    });
  });

  group('the 90.05 sample', () {
    test('loads at the origin and stops at the first entry M4 lacks', () {
      final JobCompilation job = compileDeck(loadJobDeck()).jobs.single;
      final subject = Machine.load(jobDeck(job, _options)!.cards);
      expect(subject.program.words, hasLength(936));
      expect(subject.program.origin, Machine.programOrigin);
      expect(subject.program.entry, Machine.programOrigin + octal('165'));
      expect(subject.state.ic, subject.program.entry);
      // The sample calls open-all, which finds an empty file list while
      // M5 owns IOC)1 (RT-2), fills its work areas through MOVPAK, and
      // then reads its first record. IOC)8 is the GET, and it is the M4
      // to M5 boundary (M4-17).
      expect(
        () => subject.run(maxSteps: 1000),
        throwsA(
          isA<UnimplementedRuntimeEntry>().having(
            (UnimplementedRuntimeEntry e) => e.number,
            'number',
            8,
          ),
        ),
      );
    });

    test('comtranc --run fails on the entry M4 lacks', () {
      final ProcessResult run = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'comtran:comtranc',
        jobDeckPath,
        '--run',
      ]);
      expect(run.exitCode, 1);
      expect(run.stderr, contains('error: job 1: unimplemented runtime entry'));
    });
  });

  group('an I/O-free program', () {
    test('runs to STOP RUN and stores its result', () {
      final JobCompilation job = compileDeck(
        mirrorToDeck('${_source.join('\n')}\n'),
      ).jobs.single;
      final subject = Machine.load(jobDeck(job, _options)!.cards);
      final RunResult result = subject.run(maxSteps: 1000);
      expect(result.outcome, RunOutcome.endOfJob);
      expect(result.display, <String>['AT 4,00 STOP RUN']);
      final AssemblyUnit total = job.codegen!.units.firstWhere(
        (AssemblyUnit unit) => unit.labels.contains('TOT'),
      );
      // `SET TOT = NUM + 1` generates CLA, ADD, STO with no MOVPAK, and
      // NUM's reserved cell reads +0 (ED-6).
      expect(subject.state.read(Machine.programOrigin + total.location!), 1);
    });

    test('comtranc --run prints the display after the listing', () {
      final ProcessResult run = _compileAndRun(_source);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(run.stdout, contains('AT 4,00 STOP RUN'));
    });

    test('a labelled section runs from the entry point it takes', () {
      // `test/codegen_test.dart` pins the entry word on PROGRAM.START.
      // NUM reads 1 only if the run entered the section: the `GO TO`
      // ahead of it reaches STOP RUN over an untouched cell (ED-6).
      final (JobCompilation job, Machine subject) = compiled(_section);
      expect(subject.state.read(addressOf(job, 'NUM')), 1);
    });
  });

  group('the --run exit status', () {
    test('an exhausted budget names the budget and fails the job', () {
      final ProcessResult run = _compileAndRun(_loop);
      expect(run.exitCode, 1);
      expect(
        run.stderr,
        contains('error: job 1: still running after 1000000 steps'),
      );
    });

    test('an error exit fails the job on the monitor message alone', () {
      final ProcessResult run = _compileAndRun(_guard);
      expect(run.exitCode, 1);
      expect(run.stdout, contains('BASE LOCATOR NOT LOADED'));
      expect(run.stderr, isNot(contains('error:')));
    });
  });
}
