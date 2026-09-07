/// The run frame (RT-2): each handler against its [J 90.02] contract,
/// reached through the dispatcher by the calling sequence the generator
/// emits.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';
import 'runtime_support.dart';

/// The file-set calling sequences the sample compiles: open-all, then
/// close-all for `CLOSE ALL FILES` and close-all again for STOP RUN
/// (`test/goldens/90.05-payroll.code`:315 to 322; M5-4). Each entry
/// takes one parameter word, `PZE IOC)1`.
final Map<int, int> _openAndCloseTwice = <int, int>{
  start: tsx(175),
  start + 1: typeA(0, address: 1),
  start + 2: tsx(177),
  start + 3: typeA(0, address: 1),
  start + 4: tsx(177),
  start + 5: typeA(0, address: 1),
  start + 6: endOfJob,
};

/// Open-all alone: `TSX SYS)175,4` and its one parameter word.
final Map<int, int> _openAll = <int, int>{
  start: tsx(175),
  start + 1: typeA(0, address: 1),
};

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

    test('every file the cell counts opens, and closes again', () {
      // No tape directory, so no file has a host image and the run is
      // the one M4 stage 4 made (M5-3).
      final Machine subject = machine(
        _openAndCloseTwice,
        files: <LoaderFile>[
          loaderFile(1, type: 'I', unit: 'D1'),
          loaderFile(2, type: 'P', unit: 'C1'),
          loaderFile(3, type: 'P', unit: 'C2'),
        ],
      );
      // Two steps is the open-all call and its handler.
      expect(subject.run(maxSteps: 2).outcome, RunOutcome.stepLimit);
      expect(
        subject.files.map((RuntimeFile file) => file.open),
        everyElement(isTrue),
      );
      expect(subject.run(maxSteps: 10).outcome, RunOutcome.endOfJob);
      expect(
        subject.files.map((RuntimeFile file) => file.open),
        everyElement(isFalse),
      );
    });

    test('close writes one tape mark to each open output file', () {
      final Directory tapes = Directory.systemTemp.createTempSync(
        'comtran-tapes',
      );
      addTearDown(() => tapes.deleteSync(recursive: true));
      // Both images hold a record already, so the run shows what open
      // truncates and what it leaves.
      final input = File('${tapes.path}/D1.tap')
        ..writeAsBytesSync(<int>[2, 0, 0, 0, 60, 60, 2, 0, 0, 0]);
      final output = File('${tapes.path}/C1.tap')
        ..writeAsBytesSync(<int>[2, 0, 0, 0, 60, 60, 2, 0, 0, 0]);
      final Machine subject = machine(
        _openAndCloseTwice,
        files: <LoaderFile>[
          loaderFile(1, type: 'I', unit: 'D1'),
          loaderFile(2, type: 'P', unit: 'C1'),
        ],
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 10).outcome, RunOutcome.endOfJob);
      expect(input.readAsBytesSync(), <int>[2, 0, 0, 0, 60, 60, 2, 0, 0, 0]);
      // The open truncated the output image and the close wrote the
      // tape mark, the four-byte length zero (M5-2). The second
      // close-all found the file closed and wrote nothing (M5-4).
      expect(output.readAsBytesSync(), <int>[0, 0, 0, 0]);
    });

    test('the handler opens the count IOC)1 holds, not the whole table', () {
      final Machine subject = machine(
        _openAll,
        files: <LoaderFile>[
          loaderFile(1, type: 'I', unit: 'D1'),
          loaderFile(2, type: 'P', unit: 'C1'),
          loaderFile(3, type: 'P', unit: 'C2'),
        ],
      );
      // The constructor seeds the cell with the table's own count
      // (M5-3), so only a write after it holds the handler to the cell.
      subject.state.write(1, pzeWord(decrement: 2));
      expect(subject.run(maxSteps: 2).outcome, RunOutcome.stepLimit);
      expect(subject.files.map((RuntimeFile file) => file.open), <bool>[
        true,
        true,
        false,
      ]);
    });

    test('a refused open leaves every image as it found it', () {
      final Directory tapes = Directory.systemTemp.createTempSync(
        'comtran-tapes',
      );
      addTearDown(() => tapes.deleteSync(recursive: true));
      // The output file comes first and the absent input second, so one
      // loop over the table would truncate C1 before it refused.
      const record = <int>[2, 0, 0, 0, 60, 60, 2, 0, 0, 0];
      final output = File('${tapes.path}/C1.tap')..writeAsBytesSync(record);
      final Machine subject = machine(
        _openAll,
        files: <LoaderFile>[
          loaderFile(1, type: 'P', unit: 'C1'),
          loaderFile(2, type: 'I', unit: 'D1'),
        ],
        tapes: tapes,
      );
      expect(() => subject.run(maxSteps: 2), throwsA(isA<MissingTapeImage>()));
      expect(output.readAsBytesSync(), record);
      expect(
        subject.files.map((RuntimeFile file) => file.open),
        everyElement(isFalse),
      );
    });

    test('a file whose direction column is blank has no run', () {
      // Our generator punches column 28 blank for a checkpoint file
      // ([J 02.06.03]), and no record says what one opens (M5-3).
      final Machine subject = machine(
        _openAll,
        files: <LoaderFile>[loaderFile(1, type: '', unit: 'D1')],
      );
      expect(
        () => subject.run(maxSteps: 2),
        throwsA(
          isA<UnrunnableFile>().having(
            (UnrunnableFile e) => e.toString(),
            'toString',
            'no run for file FILE1: its direction column is not I, T or P',
          ),
        ),
      );
    });

    test('a file with no unit has no run under a tape directory', () {
      final Directory tapes = Directory.systemTemp.createTempSync(
        'comtran-tapes',
      );
      addTearDown(() => tapes.deleteSync(recursive: true));
      // Its image path would be the bare suffix, and two such files
      // would share one image (M5-3).
      final Machine subject = machine(
        _openAll,
        files: <LoaderFile>[loaderFile(1, type: 'I', unit: '')],
        tapes: tapes,
      );
      expect(
        () => subject.run(maxSteps: 2),
        throwsA(
          isA<UnrunnableFile>().having(
            (UnrunnableFile e) => e.toString(),
            'toString',
            'no run for file FILE1: it names no unit',
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

  group('IOC)40, the end-of-job return point (J 90.02.09)', () {
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
