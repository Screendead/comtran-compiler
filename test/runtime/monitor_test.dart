/// The run frame (RT-2): each handler against its [J 90.02] contract,
/// reached through the dispatcher by the calling sequence the generator
/// emits.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';

int _octal(String digits) => int.parse(digits, radix: 8);

/// Where every calling sequence below sits: the program's first word.
const int _start = Machine.programOrigin;

/// A machine holding [words] at absolute addresses, entered at [_start].
Machine _machine(Map<int, int> words) => Machine(
  LoadedProgram(
    deckName: '',
    origin: Machine.programOrigin,
    entry: _start,
    words: words,
    files: const <LoaderFile>[],
    cardsRead: 0,
  ),
);

/// `TSX SYS)nnn,4`, the linkage every run-frame subroutine takes
/// ([J 90.02.14]).
int _tsx(int entry) => typeB(0x03C, address: entry, tag: 4);

void main() {
  group('SYS)178, the STOP display (J 90.02.14)', () {
    test('prints the sample line and resumes at 3,4', () {
      // The attested site, LOC 00521-00523 with pool words CP)+26 to
      // +29 ([J 90.05] listing): the statement stamp, then the words
      // ' STOP ' and ' RUN  ' (M4-14).
      final Machine machine = _machine({
        _start: _tsx(178),
        _start + 1: typeA(
          0,
          decrement: _start + 0x101,
          address: _start + 0x100,
        ),
        _start + 2: typeA(
          0,
          decrement: _start + 0x103,
          address: _start + 0x102,
        ),
        _start + 0x100: _octal('606060011111'),
        _start + 0x101: _octal('730104606060'),
        _start + 0x102: _octal('606263464760'),
        _start + 0x103: _octal('605164456060'),
      });
      final RunResult result = machine.run(maxSteps: 2);
      expect(result.display, <String>['AT 199,14 STOP RUN']);
      expect(machine.state.ic, _start + 3);
      expect(result.outcome, RunOutcome.stepLimit);
    });
  });

  group('SYS)175 and SYS)177, open and close all files (J 90.02.14)', () {
    test('an empty file list does nothing and resumes at 2,4', () {
      for (final entry in <int>[175, 177]) {
        final Machine machine = _machine({
          _start: _tsx(entry),
          _start + 1: typeA(0, address: 1), // PZE IOC)1
        });
        final RunResult result = machine.run(maxSteps: 2);
        expect(result.outcome, RunOutcome.stepLimit, reason: 'SYS)$entry');
        expect(machine.state.ic, _start + 2, reason: 'SYS)$entry');
        expect(result.display, isEmpty, reason: 'SYS)$entry');
      }
    });

    test('a file in the list is M5', () {
      final Machine machine = _machine({
        _start: _tsx(175),
        _start + 1: typeA(0, address: 1),
        // IOC)1, the cell `PZE L,,N` ([J 90.02.10]), listing one file.
        1: typeA(0, decrement: 1, address: _start + 0x100),
      });
      expect(
        () => machine.run(maxSteps: 2),
        throwsA(
          isA<UnimplementedRuntimeEntry>()
              .having((UnimplementedRuntimeEntry e) => e.number, 'number', 175)
              .having(
                (UnimplementedRuntimeEntry e) => e.toString(),
                'toString',
                'unimplemented runtime entry SYS)175: a file list of 1 (M5)',
              ),
        ),
      );
    });
  });

  group('SYS)294, the base-locator guard (J 90.02.33)', () {
    test('an unloaded locator displays and exits to the monitor', () {
      // `LAC BL)1,1 / TXL SYS)294,1,0`: BL)1's address field is zero, so
      // XR1 is zero and the TXL fires ([J 90.02.33]).
      final Machine machine = _machine({
        _start: typeB(0x15D, address: _start + 2, tag: 1),
        _start + 1: typeA(7, tag: 1, address: 294),
      });
      final RunResult result = machine.run(maxSteps: 4);
      expect(result.outcome, RunOutcome.errorExit);
      expect(result.display, <String>['BASE LOCATOR NOT LOADED']);
      expect(machine.state.ic, 294);
      expect(result.steps, 3);
    });
  });

  group('IOC)40, the end-of-job return point (J 90.02.10)', () {
    test('ends the job where the transfer lands', () {
      final Machine machine = _machine({
        _start: typeA(1, address: 40), // TXI IOC)40,0
      });
      final RunResult result = machine.run(maxSteps: 5);
      expect(result.outcome, RunOutcome.endOfJob);
      expect(result.steps, 2);
      expect(machine.state.ic, 40);
    });
  });
}
