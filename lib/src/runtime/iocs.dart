/// The IOCS entries a GET and a FILE reach
/// (`docs/design/m5-io.md` M5-8 to M5-10): IOC)8, the READ subroutine,
/// IOC)9, the WRITE subroutine, and the two terminators the GET's
/// calling sequence names ([J 90.02.08]; [J 90.02.28]; [J 90.02.32]).
///
/// A GET locates its record. The handler reads a tape block into the
/// file's buffer, writes the address of the next record there into the
/// base locator the `IOCTN*` word names, and the program reads the
/// record through that cell ([J 90.02.04]). A FILE runs the other way:
/// the handler copies the record the `IOST` word locates into the
/// file's buffer, and the buffer goes to tape one block at a time.
library;

import 'dart:math' as math;

import '../emulator/word.dart';
import 'machine.dart';
import 'tape.dart';

/// The IOCS entries [machine] dispatches, by system reference number
/// (M4-17).
Map<int, RuntimeEntry> iocs(Machine machine) => _Iocs(machine).entries;

/// What a file reference's address field holds above the file's ordinal
/// ([J 90.03.05]).
const int _fileReference = 0x800;

final class _Iocs {
  _Iocs(this._machine);

  final Machine _machine;

  Map<int, RuntimeEntry> get entries => <int, RuntimeEntry>{
    8: _read,
    9: _write,
    260: () => _terminate('RECORD LENGTH ERROR'),
    283: () => _terminate('GET ERROR'),
  };

  /// The ordinal of the file the calling sequence in hand names. A
  /// terminator reads it too, because index register 4 still holds the
  /// link the GET's `TSX` wrote (M5-5).
  int get _ordinal => Word36.address(_machine.parameter(1)) - _fileReference;

  /// The file of the calling sequence in hand. Ordinal k is
  /// `files[k - 1]` (M5-3).
  RuntimeFile get _file => _machine.files[_ordinal - 1];

  /// IOC)8, the READ subroutine ([J 90.02.08]). Parameter word 1 names
  /// the file and the record-length exit, word 2 the AT END exit and
  /// the error exit, and word 3 the base locator and the record's
  /// extent in words (M5-5).
  ///
  /// The read rules are M5-8's. Index registers 1 and 2 and the
  /// accumulator stay as the program left them: no compiled word reads
  /// what IOCS leaves in them.
  RunOutcome? _read() {
    final int reference = _machine.parameter(1);
    final int exits = _machine.parameter(2);
    final int descriptor = _machine.parameter(3);
    final RuntimeFile file = _file;
    final int extent = Word36.decrement(descriptor);
    if (!file.open) {
      return _exit(Word36.address(exits));
    }
    if (file.unread == 0) {
      final int? exit = _fill(
        file,
        atEnd: Word36.address(exits),
        onError: Word36.decrement(exits),
      );
      if (exit != null) {
        return _exit(exit);
      }
    }
    if (file.unread < extent) {
      return _exit(Word36.decrement(reference));
    }
    // The program does byte arithmetic on the whole cell, so the word
    // is a plain `PZE LOC`: a simple base locator ([J 90.02.05]).
    _machine.state.write(
      Word36.address(descriptor),
      pzeWord(address: file.cursor),
    );
    file
      ..cursor += extent
      ..unread -= extent;
    _machine.resume(4);
    return null;
  }

  /// IOC)9, the WRITE subroutine ([J 90.02.08]). Parameter word 1 names
  /// the file and an end-of-buffer exit, and word 2 is the `IOST` word:
  /// the record's first address and its extent in words (M5-5; M5-9).
  ///
  /// The write rules are M5-9's. Index registers 1 and 2 and the
  /// accumulator stay as the program left them.
  ///
  /// Throws [RecordTooLong] for a record the file's block cannot hold.
  RunOutcome? _write() {
    final RuntimeFile file = _file;
    if (file.open) {
      final int iost = _machine.parameter(2);
      final int extent = Word36.decrement(iost);
      if (extent > file.blocksize) {
        throw RecordTooLong(
          _machine.program.files[_ordinal - 1].name,
          extent,
          file.blocksize,
        );
      }
      if (file.blocksize - file.held < extent) {
        _machine.writeBlock(file);
      }
      final int record = Word36.address(iost);
      for (var i = 0; i < extent; i++) {
        _machine.state.write(
          file.buffer + file.held + i,
          _machine.state.read(record + i),
        );
      }
      file.held += extent;
    }
    _machine.resume(3);
    return null;
  }

  /// Reads the next tape block into [file]'s buffer, which takes at
  /// most BLOCKSIZE words of it ([J 90.05.03]).
  ///
  /// Returns the exit the read takes, or null once the buffer holds
  /// the block: [atEnd] at a file mark, which leaves the buffer spent
  /// so that the next GET reads on past the mark, and [onError] for a
  /// frame that is no record (M5-8).
  int? _fill(RuntimeFile file, {required int atEnd, required int onError}) {
    file.block++;
    final List<int>? block;
    try {
      block = file.reader!.read();
    } on UnreadableRecord {
      return onError;
    }
    if (block == null) {
      return atEnd;
    }
    final int taken = math.min(block.length, file.blocksize);
    for (var i = 0; i < taken; i++) {
      _machine.state.write(file.buffer + i, block[i]);
    }
    file
      ..cursor = file.buffer
      ..unread = taken;
    return null;
  }

  /// Leaves the GET at [address] with index register 4 as the `TSX`
  /// left it, so a terminator reads the same calling sequence (M5-5).
  RunOutcome? _exit(int address) {
    _machine.state.ic = address;
    return null;
  }

  /// SYS)260, the record-length error, and SYS)283, the GET error. Each
  /// prints one line and exits to the CT Monitor ([J 90.02.28];
  /// [J 90.02.32]), as SYS)294 does (RT-2).
  ///
  /// The texts are ours. No manual prints either one, and [J 05.06.04]
  /// says only that a message goes to the on-line printer.
  RunOutcome _terminate(String fault) {
    _machine.display(
      '$fault ON ${_machine.program.files[_ordinal - 1].name}, '
      'BLOCK ${_file.block}',
    );
    return RunOutcome.errorExit;
  }
}
