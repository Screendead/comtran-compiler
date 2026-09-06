/// The machine assembly (RT-1): the dispatch rule, the step budget, the
/// 1962 sample at the runtime boundary, and one program run end to end.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';
import '../support/deck_fixtures.dart';

int _octal(String digits) => int.parse(digits, radix: 8);

const ListingOptions _options = ListingOptions(date: '10/18/61', time: '2.45');

const int _start = Machine.programOrigin;

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

void main() {
  group('the dispatch rule', () {
    Machine machine(Map<int, int> words) => Machine(
      LoadedProgram(
        deckName: '',
        origin: Machine.programOrigin,
        entry: _start,
        words: words,
        files: const <LoaderFile>[],
        cardsRead: 0,
      ),
    );

    test('an entry with no handler names itself', () {
      // `TSX IOC)8,4`, the GET of M5 (M4-17).
      expect(
        () => machine({
          _start: typeB(0x03C, address: 8, tag: 4),
        }).run(maxSteps: 4),
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
        _start: typeB(0x010, address: _start), // TRA *
      }).run(maxSteps: 50);
      expect(result.outcome, RunOutcome.stepLimit);
      expect(result.steps, 50);
    });
  });

  group('the 90.05 sample', () {
    test('loads at the origin and stops at the first entry M4 lacks', () {
      final JobCompilation job = compileDeck(loadJobDeck()).jobs.single;
      final machine = Machine.load(jobDeck(job, _options)!.cards);
      expect(machine.program.words, hasLength(936));
      expect(machine.program.origin, Machine.programOrigin);
      expect(machine.program.entry, Machine.programOrigin + _octal('165'));
      expect(machine.state.ic, machine.program.entry);
      // The sample opens all files, then moves data: the second entry
      // it reaches is a MOVPAK member. The boundary moves to IOC)8 once
      // MOVPAK lands (M4-17).
      expect(
        () => machine.run(maxSteps: 1000),
        throwsA(
          isA<UnimplementedRuntimeEntry>().having(
            (UnimplementedRuntimeEntry e) => e.number,
            'number',
            182,
          ),
        ),
      );
    });
  });

  group('an I/O-free program', () {
    test('runs to STOP RUN and stores its result', () {
      final JobCompilation job = compileDeck(
        mirrorToDeck('${_source.join('\n')}\n'),
      ).jobs.single;
      final machine = Machine.load(jobDeck(job, _options)!.cards);
      final RunResult result = machine.run(maxSteps: 1000);
      expect(result.outcome, RunOutcome.endOfJob);
      expect(result.display, <String>['AT 4,00 STOP RUN']);
      final AssemblyUnit total = job.codegen!.units.firstWhere(
        (AssemblyUnit unit) => unit.labels.contains('TOT'),
      );
      // `SET TOT = NUM + 1` generates CLA, ADD, STO with no MOVPAK, and
      // NUM's reserved cell reads +0 (ED-6).
      expect(machine.state.read(Machine.programOrigin + total.location!), 1);
    });
  });
}
