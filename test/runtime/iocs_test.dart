/// The GET and the FILE (M5-8 to M5-10): IOC)8 and IOC)9 against the
/// calling sequences the generator emits, the buffer one reads a tape
/// block into and the other builds a block in, and the two terminators
/// the GET's sequence names.
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

/// One output file on unit `D1`, whose block holds [blocksize] words.
List<LoaderFile> _oneOutput(int blocksize) => <LoaderFile>[
  loaderFile(1, type: 'P', unit: 'D1', blocksize: blocksize),
];

/// The three record areas of the D6.7 example, each above the deepest
/// buffer the tests below give a file.
const int _rec1 = start + 0x200;
const int _rec2 = start + 0x300;
const int _rec3 = start + 0x400;

/// `TSX IOC)9,4` at [at] and its two parameter words: file [file] with
/// the end-of-buffer exit our generator punches zero, and the `IOST`
/// word of a record of [extent] words at [record] (M4-15; M5-9).
Map<int, int> _fileCall(
  int at, {
  required int record,
  required int extent,
  int file = 1,
}) => <int, int>{
  at: tsx(9),
  at + 1: typeA(0, address: _reference(file)),
  at + 2: typeA(7, decrement: extent, address: record),
};

/// A program that opens its files, runs [calls], closes them, and ends
/// the job.
Map<int, int> _writer(Map<int, int> calls) => <int, int>{
  start: tsx(175),
  start + 1: typeA(0, address: 1), // PZE IOC)1
  ...calls,
  start + 2 + calls.length: tsx(177),
  start + 3 + calls.length: typeA(0, address: 1),
  start + 4 + calls.length: endOfJob,
};

/// `LXA BL)n,4`, which loads a base locator's address into index
/// register 4 ahead of a located FILE ([J 90.02.05]; statement 208).
int _lxa(int cell) => typeB(0x15C, address: cell, tag: 4);

/// `SXA IOST,4`, which writes that address over the zero the generator
/// punched in the `IOST` word (M5-6).
int _sxa(int at) => typeB(0x19C, address: at, tag: 4);

/// The frames the image of [unit] holds, up to its file mark (M5-2).
List<List<int>> _frames(Directory tapes, String unit) {
  final reader = TapeReader(File('${tapes.path}/$unit.tap').readAsBytesSync());
  final frames = <List<int>>[];
  for (List<int>? frame = reader.read(); frame != null; frame = reader.read()) {
    frames.add(frame);
  }
  return frames;
}

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
      // (M5-4 as amended). J forbids this reopen, and D6.3 records the
      // result as unreliable; the test pins what the runtime does. The
      // second frame is no record, and the GET that reaches it names
      // frame 2 only if the first four words entered the buffer twice.
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
          loaderFile(2, type: 'I', unit: 'C2'),
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

  group('IOC)9, the WRITE subroutine (J 90.02.08)', () {
    test("J's own example packs the records into blocks (D6.7)", () {
      // [J 02.07.09] to [J 02.07.10] Example 1: records of 64, 128 and
      // 192 words on a file of BLOCKSIZE 256, filed REC1 REC1 REC2 REC1
      // REC2 REC3 REC1. J's own answer is three blocks of 256, 192 and
      // 256 words, in that order (M5-9).
      final Directory tapes = tempDirectory('comtran-tapes');
      const filed = <(int, int)>[
        (_rec1, 64),
        (_rec1, 64),
        (_rec2, 128),
        (_rec1, 64),
        (_rec2, 128),
        (_rec3, 192),
        (_rec1, 64),
      ];
      final Machine subject = machine(
        <int, int>{
          ..._writer(<int, int>{
            for (var i = 0; i < filed.length; i++)
              ..._fileCall(
                start + 2 + i * 3,
                record: filed[i].$1,
                extent: filed[i].$2,
              ),
          }),
          // One marker word a record, so a frame names the records in it.
          _rec1: 1,
          _rec2: 2,
          _rec3: 3,
        },
        files: _oneOutput(256),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 30).outcome, RunOutcome.endOfJob);
      final List<List<int>> frames = _frames(tapes, 'D1');
      expect(frames.map((List<int> frame) => frame.length), <int>[
        256,
        192,
        256,
      ]);
      expect(
        <int>[frames[0][0], frames[0][64], frames[0][128]],
        <int>[1, 1, 2],
      );
      expect(<int>[frames[1][0], frames[1][64]], <int>[1, 2]);
      expect(<int>[frames[2][0], frames[2][192]], <int>[3, 1]);
    });

    test('a block that fills exactly waits for the FILE that needs it', () {
      // A full block leaves the buffer only when the next record wants
      // its words. The run takes no close, so the image holds nothing
      // but what IOC)9 itself wrote (M5-9).
      final Directory tapes = tempDirectory('comtran-tapes');
      final Machine subject = machine(
        <int, int>{
          start: tsx(175),
          start + 1: typeA(0, address: 1), // PZE IOC)1
          ..._fileCall(start + 2, record: _rec1, extent: 4),
          start + 5: endOfJob,
          _rec1: 8,
        },
        files: _oneOutput(4),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 10).outcome, RunOutcome.endOfJob);
      expect(subject.files.single.held, 4);
      expect(File('${tapes.path}/D1.tap').readAsBytesSync(), isEmpty);
    });

    test('a FILE on a file that is not open writes nothing', () {
      // [J 02.07.08]: it "acts as a NOP. No error message is given."
      // The run ends on the word three on, so the entry resumed (M5-5).
      final Directory tapes = tempDirectory('comtran-tapes');
      final Machine subject = machine(
        <int, int>{
          ..._fileCall(start, record: _rec1, extent: 2),
          start + 3: endOfJob,
          _rec1: 7,
        },
        files: _oneOutput(4),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 4).outcome, RunOutcome.endOfJob);
      // The record never enters the buffer, so nothing is left to write.
      expect(subject.files.single.held, 0);
      expect(File('${tapes.path}/D1.tap').existsSync(), isFalse);
      expect(subject.printed, isEmpty);
    });

    test('a record longer than the BLOCKSIZE ends the run', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      final Machine subject = machine(
        _writer(_fileCall(start + 2, record: _rec1, extent: 5)),
        files: _oneOutput(4),
        tapes: tapes,
      );
      expect(
        () => subject.run(maxSteps: 10),
        throwsA(
          isA<RecordTooLong>().having(
            (RecordTooLong e) => e.toString(),
            'toString',
            'record of 5 words exceeds the BLOCKSIZE 4 of file FILE1',
          ),
        ),
      );
    });

    test('the LXA/SXA pair patches the IOST word, and the close '
        'writes the block it still holds', () {
      // A located record's address is zero until the pair ahead of the
      // call writes the base locator over it (M5-6; statement 208). The
      // close then writes the two words and the tape mark (M5-10).
      final Directory tapes = tempDirectory('comtran-tapes');
      final Machine subject = machine(
        <int, int>{
          ..._writer(<int, int>{
            start + 2: _lxa(_locator),
            start + 3: _sxa(start + 6),
            ..._fileCall(start + 4, record: 0, extent: 2),
          }),
          _locator: pzeWord(address: _rec1),
          _rec1: 11,
          _rec1 + 1: 12,
        },
        files: _oneOutput(4),
        tapes: tapes,
      );
      expect(subject.run(maxSteps: 10).outcome, RunOutcome.endOfJob);
      expect(_frames(tapes, 'D1'), <List<int>>[
        <int>[11, 12],
      ]);
    });

    test('with no host image the block fills and the write is dropped', () {
      // The run names no tape directory and declares no input file, so
      // it runs as it did at stage 1 (M5-10; M5-3 as amended).
      final Machine subject = machine(<int, int>{
        ..._writer(_fileCall(start + 2, record: _rec1, extent: 2)),
        _rec1: 5,
      }, files: _oneOutput(4));
      expect(subject.run(maxSteps: 10).outcome, RunOutcome.endOfJob);
      expect(subject.state.read(bufferBase), 5);
    });
  });

  group('the buffers (M5-10)', () {
    test('a file with no BLOCKSIZE is refused at load', () {
      // An output file takes a buffer too, so the refusal covers it
      // (M5-7 as amended).
      expect(
        () => machine(
          const <int, int>{},
          files: <LoaderFile>[
            loaderFile(1, type: 'P', unit: 'D1', blocksize: null),
          ],
        ),
        throwsA(
          isA<NoBlocksize>().having(
            (NoBlocksize e) => e.toString(),
            'toString',
            'no BLOCKSIZE for file FILE1',
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
            'no room above the program for the buffer of file FILE1',
          ),
        ),
      );
    });
  });
}
