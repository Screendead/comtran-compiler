/// The run frame (RT-2): each handler against its [J 90.02] contract,
/// reached through the dispatcher by the calling sequence the generator
/// emits.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';
import 'runtime_support.dart';

void main() {
  group('SYS)178, the STOP display (J 90.02.14)', () {
    test('prints the sample line and resumes at 3,4', () {
      // The attested site, LOC 00521-00523 with pool words CP)+26 to
      // +29 ([J 90.05] listing): the statement stamp, then the words
      // ' STOP ' and ' RUN  ' (M4-14).
      final Machine subject = machine({
        start: tsx(178),
        start + 1: typeA(0, decrement: start + 0x101, address: start + 0x100),
        start + 2: typeA(0, decrement: start + 0x103, address: start + 0x102),
        start + 0x100: octal('606060011111'),
        start + 0x101: octal('730104606060'),
        start + 0x102: octal('606263464760'),
        start + 0x103: octal('605164456060'),
      });
      final RunResult result = subject.run(maxSteps: 2);
      expect(result.display, <String>['AT 199,14 STOP RUN']);
      expect(subject.state.ic, start + 3);
      expect(result.outcome, RunOutcome.stepLimit);
    });
  });

  group('SYS)175 and SYS)177, open and close all files (J 90.02.14)', () {
    test('an empty file list does nothing and resumes at 2,4', () {
      for (final entry in <int>[175, 177]) {
        final Machine subject = machine({
          start: tsx(entry),
          start + 1: typeA(0, address: 1), // PZE IOC)1
        });
        final RunResult result = subject.run(maxSteps: 2);
        expect(result.outcome, RunOutcome.stepLimit, reason: 'SYS)$entry');
        expect(subject.state.ic, start + 2, reason: 'SYS)$entry');
        expect(result.display, isEmpty, reason: 'SYS)$entry');
      }
    });

    test('a file in the list is M5', () {
      final Machine subject = machine({
        start: tsx(175),
        start + 1: typeA(0, address: 1),
        // IOC)1, the cell `PZE L,,N` ([J 90.02.10]), listing one file.
        1: typeA(0, decrement: 1, address: start + 0x100),
      });
      expect(
        () => subject.run(maxSteps: 2),
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
      final Machine subject = machine({
        start: typeB(0x15D, address: start + 2, tag: 1),
        start + 1: typeA(7, tag: 1, address: 294),
      });
      final RunResult result = subject.run(maxSteps: 4);
      expect(result.outcome, RunOutcome.errorExit);
      expect(result.display, <String>['BASE LOCATOR NOT LOADED']);
      expect(subject.state.ic, 294);
    });
  });

  group('IOC)40, the end-of-job return point (J 90.02.10)', () {
    test('ends the job where the transfer lands', () {
      final Machine subject = machine({
        start: typeA(1, address: 40), // TXI IOC)40,0
      });
      final RunResult result = subject.run(maxSteps: 5);
      expect(result.outcome, RunOutcome.endOfJob);
      expect(subject.state.ic, 40);
    });
  });
}
