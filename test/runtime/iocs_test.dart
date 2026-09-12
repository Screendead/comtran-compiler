/// The GET (M5-7; M5-8): IOC)8 against the calling sequence the
/// generator emits, the buffer it reads a tape block into, and the two
/// terminators the sequence names.
library;

import 'dart:io';

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';
import 'runtime_support.dart';

/// The base locators of the programs below, `BL)2` and `BL)3` (M4-15).
const int _locator = start + 0x40;
const int _locator2 = start + 0x41;

/// The AT END exit every GET below names.
const int _atEnd = start + 0x20;

/// A free address the two exit tests plant their own end of job at, in
/// place of a terminator.
const int _planted = start + 0x30;

/// The address field of a file reference, `2048 + the ordinal`
/// ([J 90.03.05]).
int _reference(int ordinal) =>
    SystemReference(file: true, number: ordinal).code;

/// `TSX IOC)8,4` at [at] and its three parameter words: file [file],
/// the AT END exit, and the base locator [cell] of a record of [extent]
/// words (M4-15). [lengthExit] and [errorExit] are the two decrements
/// the sample plants SYS)260 and SYS)283 in (M5-5).
Map<int, int> _get(
  int at, {
  required int cell,
  required int extent,
  int file = 1,
  int lengthExit = 260,
  int errorExit = 283,
}) => <int, int>{
  at: tsx(8),
  at + 1: typeA(0, decrement: lengthExit, address: _reference(file)),
  at + 2: typeA(0, decrement: errorExit, address: _atEnd),
  at + 3: typeA(5, decrement: extent, tag: 6, address: cell),
};

/// A program that opens its files and then runs [gets], ending at
/// `TXI IOC)40,0` on the word after the last one and at its AT END
/// exit.
Map<int, int> _program(Map<int, int> gets) => <int, int>{
  start: tsx(175),
  start + 1: typeA(0, address: 1), // PZE IOC)1
  ...gets,
  start + 2 + gets.length: endOfJob,
  _atEnd: endOfJob,
};

/// One input file on unit `D1`, reading [blocksize] words of a block.
List<LoaderFile> _oneFile(int blocksize) => <LoaderFile>[
  loaderFile(1, type: 'I', unit: 'D1', blocksize: blocksize),
];

void main() {
  group('IOC)8, the READ subroutine (J 90.02.08)', () {
    test('the records of a block locate in turn, then the next block', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', <List<int>>[
        <int>[1, 2, 3, 4],
        <int>[5, 6],
      ]);
      final Machine subject = machine(
        _program(<int, int>{
          ..._get(start + 2, cell: _locator, extent: 2),
          ..._get(start + 6, cell: _locator, extent: 2),
          ..._get(start + 10, cell: _locator, extent: 2),
        }),
        files: _oneFile(4),
        tapes: tapes,
      );
      // Two steps: the open-all call and its handler.
      expect(subject.run(maxSteps: 2).outcome, RunOutcome.stepLimit);
      expect(subject.run(maxSteps: 2).outcome, RunOutcome.stepLimit);
      // A simple base locator, `PZE LOC` with byte zero ([J 90.02.05]).
      expect(subject.state.read(_locator), pzeWord(address: bufferBase));
      expect(subject.state.read(bufferBase), 1);
      expect(subject.state.read(bufferBase + 1), 2);
      // The GET resumes four words on, past its three parameter words,
      // and leaves the link the `TSX` wrote in index register 4 (M5-5).
      expect(subject.state.ic, start + 6);
      expect(subject.state.xrRead(4), link(start + 2));
      expect(subject.run(maxSteps: 2).outcome, RunOutcome.stepLimit);
      expect(subject.state.read(_locator), pzeWord(address: bufferBase + 2));
      // The third record spends the block, so it reads the next one and
      // locates at the base again.
      expect(subject.run(maxSteps: 2).outcome, RunOutcome.stepLimit);
      expect(subject.state.read(_locator), pzeWord(address: bufferBase));
      expect(subject.state.read(bufferBase), 5);
      expect(subject.files.single.block, 2);
    });

    test('a block enters the buffer BLOCKSIZE words deep', () {
      // DETAILFILE declares BLOCKSIZE 3, and its records sit in the
      // first portion of tape blocks 14 words long ([J 90.05.03]).
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', <List<int>>[
        <int>[for (var word = 1; word <= 14; word++) word],
        <int>[100, 101, 102],
      ]);
      final Machine subject = machine(
        _program(<int, int>{
          ..._get(start + 2, cell: _locator, extent: 3),
          ..._get(start + 6, cell: _locator, extent: 3),
        }),
        files: _oneFile(3),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 4).outcome, RunOutcome.stepLimit);
      expect(subject.state.read(_locator), pzeWord(address: bufferBase));
      expect(subject.state.read(bufferBase + 2), 3);
      // The block's other eleven words are discarded, not buffered.
      expect(subject.state.read(bufferBase + 3), 0);
      // The second GET therefore reads the next block, not words 4 to 6.
      expect(subject.run(maxSteps: 2).outcome, RunOutcome.stepLimit);
      expect(subject.state.read(_locator), pzeWord(address: bufferBase));
      expect(subject.state.read(bufferBase), 100);
    });

    test('a second open-all reads the file from its first frame', () {
      // Open rewinds the image, so the buffer must empty with it
      // (M5-4 as amended). The second frame is no record, and the GET
      // that reaches it names frame 2 only if the first four words
      // entered the buffer twice.
      final Directory tapes = tempDirectory('comtran-tapes');
      File('${tapes.path}/D1.tap').writeAsBytesSync(<int>[
        ...tapeRecord(<int>[11, 12, 13, 14]),
        ...tapeField(12),
        ...tapeWord(1),
        ...tapeWord(2),
        ...tapeField(6),
      ]);
      final Machine subject = machine(
        _program(<int, int>{
          ..._get(start + 2, cell: _locator, extent: 2),
          start + 6: tsx(177),
          start + 7: typeA(0, address: 1), // PZE IOC)1
          start + 8: tsx(175),
          start + 9: typeA(0, address: 1),
          ..._get(start + 10, cell: _locator, extent: 4),
          ..._get(start + 14, cell: _locator, extent: 2),
        }),
        files: _oneFile(4),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 20).outcome, RunOutcome.errorExit);
      expect(subject.printed, <String>['GET ERROR ON FILE1, BLOCK 2']);
      // The GET of four words located the whole record at the base.
      expect(subject.state.read(_locator), pzeWord(address: bufferBase));
    });

    test('two files locate a record each, in their own buffers', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', <List<int>>[
        <int>[1, 2],
      ]);
      tapeImage(tapes, 'C2', <List<int>>[
        <int>[3],
      ]);
      final Machine subject = machine(
        _program(<int, int>{
          ..._get(start + 2, cell: _locator, extent: 2),
          ..._get(start + 6, cell: _locator2, extent: 1, file: 2),
        }),
        files: <LoaderFile>[
          loaderFile(1, type: 'I', unit: 'D1', blocksize: 2),
          loaderFile(2, type: 'I', unit: 'C2', blocksize: 1),
        ],
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 10).outcome, RunOutcome.endOfJob);
      // The buffers sit above the program in `*FILE` card order (M5-7).
      expect(subject.state.read(_locator), pzeWord(address: bufferBase));
      expect(subject.state.read(_locator2), pzeWord(address: bufferBase + 2));
      expect(subject.state.read(bufferBase), 1);
      expect(subject.state.read(bufferBase + 2), 3);
    });
  });

  group('the AT END exit (D6.5; D6.6)', () {
    test('a file mark takes it, and the next GET reads on past it', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      File('${tapes.path}/D1.tap').writeAsBytesSync(<int>[
        ...tapeRecord(<int>[1, 2]),
        ...tapeField(0),
        ...tapeRecord(<int>[3, 4]),
        ...tapeField(0),
      ]);
      final Machine subject = machine(
        <int, int>{
          ..._program(<int, int>{
            ..._get(start + 2, cell: _locator, extent: 2),
            ..._get(start + 6, cell: _locator, extent: 2),
            ..._get(start + 10, cell: _locator, extent: 2),
          }),
          // The clause of the second GET runs the third (D6.6).
          _atEnd: typeB(0x010, address: start + 10), // TRA
        },
        files: _oneFile(2),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 4).outcome, RunOutcome.stepLimit);
      expect(subject.state.read(_locator), pzeWord(address: bufferBase));
      expect(subject.run(maxSteps: 2).outcome, RunOutcome.stepLimit);
      // The mark writes no locator and prints nothing.
      expect(subject.state.ic, _atEnd);
      expect(subject.state.read(_locator), pzeWord(address: bufferBase));
      expect(subject.printed, isEmpty);
      expect(subject.run(maxSteps: 3).outcome, RunOutcome.stepLimit);
      expect(subject.state.read(bufferBase), 3);
    });

    test('a GET on a file that is not open takes it and prints nothing', () {
      // D6.5. IOCS gives a file it never opened the end-of-file exit.
      final Machine subject = machine(<int, int>{
        ..._get(start, cell: _locator, extent: 2),
        start + 4: endOfJob,
        _atEnd: endOfJob,
      }, files: _oneFile(2));
      expect(subject.run(maxSteps: 4).outcome, RunOutcome.endOfJob);
      expect(subject.state.read(_locator), 0);
      expect(subject.printed, isEmpty);
    });
  });

  group('the terminators (J 90.02.28; J 90.02.32)', () {
    test('a record that straddles two blocks takes SYS)260', () {
      // Twenty words of fifteen-word records: the second record has
      // five words of its block left (M5-8).
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', <List<int>>[
        <int>[for (var word = 1; word <= 20; word++) word],
      ]);
      final Machine subject = machine(
        _program(<int, int>{
          ..._get(start + 2, cell: _locator, extent: 15),
          ..._get(start + 6, cell: _locator, extent: 15),
        }),
        files: _oneFile(20),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 10).outcome, RunOutcome.errorExit);
      expect(subject.printed, <String>[
        'RECORD LENGTH ERROR ON FILE1, BLOCK 1',
      ]);
    });

    test('the record-length exit is the decrement of parameter 1', () {
      // The sample plants SYS)260 there, and the handler branches where
      // the sequence sends it (M5-5).
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', <List<int>>[
        <int>[for (var word = 1; word <= 20; word++) word],
      ]);
      final Machine subject = machine(
        <int, int>{
          ..._program(<int, int>{
            ..._get(start + 2, cell: _locator, extent: 15),
            ..._get(
              start + 6,
              cell: _locator,
              extent: 15,
              lengthExit: _planted,
            ),
          }),
          _planted: endOfJob,
        },
        files: _oneFile(20),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 10).outcome, RunOutcome.endOfJob);
      expect(subject.printed, isEmpty);
    });

    test('a frame that is no record takes SYS)283', () {
      // `tape_test.dart` holds the four frames the decoder refuses. The
      // handler has one catch, so one of them reaches it here.
      final Directory tapes = tempDirectory('comtran-tapes');
      File('${tapes.path}/D1.tap').writeAsBytesSync(<int>[
        ...tapeField(12),
        ...tapeWord(1),
        ...tapeWord(2),
        ...tapeField(6),
      ]);
      final Machine subject = machine(
        _program(<int, int>{..._get(start + 2, cell: _locator, extent: 2)}),
        files: _oneFile(2),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 6).outcome, RunOutcome.errorExit);
      expect(subject.printed, <String>['GET ERROR ON FILE1, BLOCK 1']);
      expect(subject.state.read(_locator), 0);
    });

    test('the GET error exit is the decrement of parameter 2', () {
      // The sample plants SYS)283 there (M5-5).
      final Directory tapes = tempDirectory('comtran-tapes');
      File('${tapes.path}/D1.tap').writeAsBytesSync(<int>[
        ...tapeField(12),
        ...tapeWord(1),
        ...tapeWord(2),
        ...tapeField(6),
      ]);
      final Machine subject = machine(
        <int, int>{
          ..._program(<int, int>{
            ..._get(start + 2, cell: _locator, extent: 2, errorExit: _planted),
          }),
          _planted: endOfJob,
        },
        files: _oneFile(2),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 6).outcome, RunOutcome.endOfJob);
      expect(subject.printed, isEmpty);
    });
  });

  group('the buffers (M5-7)', () {
    test('an input file with no BLOCKSIZE is refused at load', () {
      expect(
        () => machine(
          const <int, int>{},
          files: <LoaderFile>[loaderFile(1, type: 'I', unit: 'D1')],
        ),
        throwsA(
          isA<NoBlocksize>().having(
            (NoBlocksize e) => e.toString(),
            'toString',
            'no BLOCKSIZE for input file FILE1',
          ),
        ),
      );
    });

    test('a program with no room for a buffer is refused at load', () {
      // The buffer may end on the last word of core and no further.
      const int room = MachineState.memoryWords - bufferBase;
      expect(
        () => machine(const <int, int>{}, files: _oneFile(room)),
        returnsNormally,
      );
      expect(
        () => machine(const <int, int>{}, files: _oneFile(room + 1)),
        throwsA(
          isA<NoBufferRoom>().having(
            (NoBufferRoom e) => e.toString(),
            'toString',
            'no room above the program for the buffer of input file FILE1',
          ),
        ),
      );
    });
  });
}
