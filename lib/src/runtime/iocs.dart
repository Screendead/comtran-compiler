/// The IOCS entries a GET reaches (`docs/design/m5-io.md` M5-7 and
/// M5-8): IOC)8, the READ subroutine, and the two terminators its
/// calling sequence names ([J 90.02.08]; [J 90.02.28]; [J 90.02.32]).
///
/// A GET locates its record. The handler reads a tape block into the
/// file's buffer, writes the address of the next record there into the
/// base locator the `IOCTN*` word names, and the program reads the
/// record through that cell ([J 90.02.04]).
library;

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

  /// The ordinal of the file the GET in hand names, which a terminator
  /// reports on its line.
  int _ordinal = 0;

  Map<int, RuntimeEntry> get entries => <int, RuntimeEntry>{
    8: _read,
    260: () => _terminate('RECORD LENGTH ERROR'),
    283: () => _terminate('GET ERROR'),
  };

  /// The file of the GET in hand. Ordinal k is `files[k - 1]` (M5-3).
  RuntimeFile get _file => _machine.files[_ordinal - 1];

  /// IOC)8, the READ subroutine ([J 90.02.08]). Parameter word 1 names
  /// the file, word 2 the AT END exit, and word 3 the base locator and
  /// the record's extent in words (M5-5).
  ///
  /// The read rules are M5-8's. Index registers 1 and 2 and the
  /// accumulator stay as the program left them: no compiled word reads
  /// what IOCS leaves in them.
  RunOutcome? _read() {
    final int reference = _machine.parameter(1);
    final int exits = _machine.parameter(2);
    final int descriptor = _machine.parameter(3);
    _ordinal = Word36.address(reference) - _fileReference;
    final int extent = Word36.decrement(descriptor);
    if (!_file.open) {
      return _exit(Word36.address(exits));
    }
    if (_file.unread == 0) {
      final int? exit = _fill(Word36.address(exits));
      if (exit != null) {
        return _exit(exit);
      }
    }
    if (_file.unread < extent) {
      return _exit(260);
    }
    // The program does byte arithmetic on the whole cell, so the word
    // is a plain `PZE LOC`: a simple base locator ([J 90.02.05]).
    _machine.state.write(
      Word36.address(descriptor),
      pzeWord(address: _file.cursor),
    );
    _file
      ..cursor += extent
      ..unread -= extent;
    _machine.resume(4);
    return null;
  }

  /// Reads the next tape block into the file's buffer, which takes at
  /// most BLOCKSIZE words of it ([J 90.05.03]).
  ///
  /// Returns the exit the read takes, or null once the buffer holds
  /// the block: [atEnd] at a file mark, which leaves the buffer spent
  /// so that the next GET reads on past the mark, and SYS)283 for a
  /// frame that is no record (M5-8).
  int? _fill(int atEnd) {
    _file.block++;
    final List<int>? block;
    try {
      block = _file.reader!.read();
    } on UnreadableRecord {
      return 283;
    }
    if (block == null) {
      return atEnd;
    }
    final int held = block.length < _file.blocksize
        ? block.length
        : _file.blocksize;
    for (var i = 0; i < held; i++) {
      _machine.state.write(_file.buffer + i, block[i]);
    }
    _file
      ..cursor = _file.buffer
      ..unread = held;
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
