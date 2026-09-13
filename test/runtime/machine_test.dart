/// The machine assembly (RT-1): the dispatch rule, the step budget, the
/// 1962 sample over its input tapes, one program run end to end, and
/// the `--run` flag that carries it to the command line, outcome by
/// outcome.
library;

import 'dart:io';

import 'package:comtran/comtran_io.dart';
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

/// Writes the two input tapes the sample reads: one master record and
/// one detail record, whose employee number is the lower of the two.
/// The comparison then takes LOW.DETAIL, which files an error record at
/// the sample's first FILE ([J 90.05] statement 196).
void _sampleTapes(Directory tapes) {
  tapeImage(tapes, 'D1', <List<int>>[
    // MASTER is 15 words, and only its employee number is read on that
    // path. The rest reads as the BCD zeros of an untouched field.
    <int>[characters('992222'), ...List<int>.filled(14, 0)],
  ]);
  tapeImage(tapes, 'C2', <List<int>>[
    // DETAIL is the employee number, the date, and the hours.
    <int>[characters('111111'), characters('010161'), characters('400000')],
  ]);
}

/// The print lines of the image unit [unit] holds in [tapes] (M5-11).
/// The lister runs to the file mark, so it also proves the close wrote
/// one.
List<String> _report(Directory tapes, String unit) =>
    listTape(File('${tapes.path}/$unit.tap').readAsBytesSync()).toList();

/// Compiles the 90.05 job deck with [options].
ProcessResult _compileSample(List<String> options) => Process.runSync(
  Platform.resolvedExecutable,
  ['run', 'comtran:comtranc', jobDeckPath, ...options],
);

/// Punches [source] into a temporary deck and compiles it with `--run`.
ProcessResult _compileAndRun(List<String> source) {
  final Directory directory = tempDirectory('comtran-run');
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
      // IOC)2 locates the 12-word IOCS file blocks. It has no emitter
      // and stays unbuilt, because the file table is Dart's (M5-3).
      expect(
        () => machine({start: tsx(2)}).run(maxSteps: 4),
        throwsA(
          isA<UnimplementedRuntimeEntry>().having(
            (UnimplementedRuntimeEntry e) => e.toString(),
            'toString',
            'unimplemented runtime entry IOC)2',
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

    test('the display survives an entry the machine lacks', () {
      // No compiled program reaches this in M4: `STOP n` is refused
      // (notes section 7) and `STOP RUN` ends the job.
      final Machine subject = machine({
        start: tsx(178),
        start + 1: typeA(0, decrement: start + 0x101, address: start + 0x100),
        start + 2: typeA(0, decrement: start + 0x103, address: start + 0x102),
        start + 3: tsx(2),
        start + 0x100: octal('606060011111'),
        start + 0x101: octal('730104606060'),
        start + 0x102: octal('606263464760'),
        start + 0x103: octal('605164456060'),
      });
      expect(
        () => subject.run(maxSteps: 4),
        throwsA(isA<UnimplementedRuntimeEntry>()),
      );
      expect(subject.printed, <String>['AT 199,14 STOP RUN']);
    });
  });

  group('the 90.05 sample', () {
    test('reads its two records and runs to the end of the job', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      _sampleTapes(tapes);
      final JobCompilation job = compileDeck(loadJobDeck()).jobs.single;
      final subject = Machine.load(jobDeck(job, _options)!.cards, tapes: tapes);
      expect(subject.program.words, hasLength(936));
      expect(subject.program.origin, Machine.programOrigin);
      expect(subject.program.entry, Machine.programOrigin + octal('165'));
      expect(subject.state.ic, subject.program.entry);
      // IOC)1 counts the seven FILE cards of the sample (M5-3).
      expect(Word36.decrement(subject.state.read(1)), 7);
      // The program's last placed word is relative 01771, so the buffers
      // start at 5114: INPUTMASTER takes 300 words, OUTPUTMASTER the 300
      // above them, and DETAILFILE the three above those (M5-10).
      expect(subject.program.extent, 5114);
      expect(subject.files.map((RuntimeFile file) => file.buffer), <int>[
        5114,
        5414,
        5714,
        5717,
        5737,
        5757,
        5763,
      ]);
      final RunResult result = subject.run(maxSteps: 5000);
      expect(result.outcome, RunOutcome.endOfJob);
      expect(result.display, <String>['AT 199,14 STOP RUN']);
      // CLOSE ALL FILES and the STOP RUN behind it close every file
      // (M5-4).
      expect(
        subject.files.map((RuntimeFile file) => file.open),
        everyElement(isFalse),
      );
      // Each record entered its own buffer. END.OF.DETAILS then wrote
      // HIGH.VALUE over the detail employee number through BL)3, so the
      // date is the word of DETAILFILE's buffer left to read (M5-7).
      expect(subject.state.read(5114), characters('992222'));
      expect(subject.state.read(5715), characters('010161'));
      // LOW.DETAIL files the detail record (196), and its GET's AT END
      // runs END.OF.DETAILS (198) into HIGH.DETAIL (193), which files
      // the master one.
      expect(_report(tapes, 'D4'), <String>[
        'D111111010161400',
        'M992222000000000000000',
      ]);
      // The department total and the grand total reach PAYFILE.
      final List<String> pay = _report(tapes, 'D3');
      expect(pay, hasLength(2));
      expect(pay.first, contains('DEPARTMENT 99 TOTALS'));
      expect(pay.last, startsWith('GT'));
      // OUTPUTMASTER, CHECKFILE and BONDORDERFILE take no record on this
      // path, so the close writes each of them the tape mark alone
      // (M5-10).
      for (final unit in <String>['C1', 'D2', 'C3']) {
        expect(File('${tapes.path}/$unit.tap').readAsBytesSync(), <int>[
          0,
          0,
          0,
          0,
        ]);
      }
    });

    test('an empty master file ends at the base-locator guard', () {
      // The first GET takes its AT END exit into END.OF.MASTERS, which
      // reads the detail record before any GET DETAIL has run. BL)3 is
      // still zero, so the guard fires (RT-2).
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', const <List<int>>[]);
      tapeImage(tapes, 'C2', const <List<int>>[]);
      final JobCompilation job = compileDeck(loadJobDeck()).jobs.single;
      final subject = Machine.load(jobDeck(job, _options)!.cards, tapes: tapes);
      final RunResult result = subject.run(maxSteps: 5000);
      expect(result.outcome, RunOutcome.errorExit);
      expect(result.display, <String>['BASE LOCATOR NOT LOADED']);
    });

    test('a declared input file needs its tape image', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
      ]);
      expect(run.exitCode, 1);
      expect(
        run.stderr,
        contains(
          'error: job 1: no tape image for input file INPUTMASTER at '
          '${tapes.path}/D1.tap',
        ),
      );
    });

    test('comtranc --run carries the sample to the end of the job', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      _sampleTapes(tapes);
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
      ]);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(run.stdout, contains('AT 199,14 STOP RUN'));
    });

    test('comtranc --list-tapes prints the reports after the run', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      _sampleTapes(tapes);
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
        '--list-tapes',
      ]);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      // The whole listing, from the last display line on: the four BCD
      // output files in `*FILE` card order. OUTPUTMASTER punches mode
      // B, so a binary tape stands nowhere in it (M5-11).
      expect(
        run.stdout,
        endsWith(
          'AT 199,14 STOP RUN\n'
          'CHECKFILE REPORT\n'
          '\n'
          '\n'
          'PAYFILE REPORT\n'
          '\n'
          '          DEPARTMENT 99 TOTALS        0.0      0.00      0.00     '
          '0.00     0.00     0.00     0.00      0.00      0.00\n'
          'GT                        -  -        0.0      0.00      0.00     '
          '0.00     0.00     0.00     0.00      0.00      0.00\n'
          '\n'
          'BONDORDERFILE REPORT\n'
          '\n'
          '\n'
          'ERRORFILE REPORT\n'
          '\n'
          'D111111010161400\n'
          'M992222000000000000000\n',
        ),
      );
    });

    test('comtranc --list-tapes lists nothing the run never opened', () {
      // The first run leaves its reports in the directory. Open-all then
      // refuses the second run ahead of the truncation, so every image
      // is the first run's and none is this run's (M5-11).
      final Directory tapes = tempDirectory('comtran-tapes');
      _sampleTapes(tapes);
      final flags = ['--run', '--tapes=${tapes.path}', '--list-tapes'];
      expect(_compileSample(flags).exitCode, 0);
      File('${tapes.path}/C2.tap').deleteSync();
      final ProcessResult run = _compileSample(flags);
      expect(run.exitCode, 1);
      expect(run.stderr, contains('no tape image for input file DETAILFILE'));
      expect(run.stdout, isNot(contains('REPORT')));
    });

    test('comtranc --list-tapes ends a report at the reader fault', () {
      // Two empty input tapes take the run to the base-locator guard,
      // which exits before close-all writes any file mark (M5-11).
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', const <List<int>>[]);
      tapeImage(tapes, 'C2', const <List<int>>[]);
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
        '--list-tapes',
      ]);
      expect(run.exitCode, 1);
      expect(run.stdout, contains('ERRORFILE REPORT\n\n'));
      expect(
        run.stderr,
        contains(
          'error: job 1: ERRORFILE: unreadable tape record: the tape ends '
          'with no file mark',
        ),
      );
    });

    test('comtranc --list-tapes needs a run', () {
      final ProcessResult run = _compileSample(['--list-tapes']);
      expect(run.exitCode, 2);
      expect(run.stderr, startsWith('Usage:'));
    });

    test('comtranc --run refuses the sample with no tape directory', () {
      final ProcessResult run = _compileSample(['--run']);
      expect(run.exitCode, 1);
      expect(
        run.stderr,
        contains(
          'error: job 1: no tape directory for input file INPUTMASTER: '
          'pass --tapes=DIR',
        ),
      );
    });
  });

  group('the --tapes directory', () {
    test('an empty path is a usage error', () {
      final ProcessResult run = _compileSample(['--run', '--tapes=']);
      expect(run.exitCode, 2);
      expect(run.stderr, startsWith('Usage:'));
    });

    test('a directory that is not there names itself', () {
      final missing = '${tempDirectory('comtran-tapes').path}/gone';
      final ProcessResult run = _compileSample(['--run', '--tapes=$missing']);
      expect(run.exitCode, 2);
      expect(run.stdout, isEmpty);
      expect(run.stderr, 'error: no tape directory at $missing\n');
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
