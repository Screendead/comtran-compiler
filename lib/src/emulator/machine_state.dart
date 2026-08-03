import 'dart:typed_data';

import 'word.dart';

/// The programmer-visible state of one 7090 CPU.
///
/// Implements §3 of `docs/design/emulator.md`. Registers follow 22-6528-4
/// pp. 7–11 (external): a 32,768-word core, the AC (S, Q, P, 1–35), the MQ,
/// the sense-indicator register, three 15-bit index registers with tags
/// 1/2/4, a 15-bit instruction counter, and the overflow and divide-check
/// indicators.
final class MachineState {
  /// Words of core storage (22-6528-4 p. 7, external).
  static const int memoryWords = 32768;

  /// Mask of the AC's 37-bit magnitude: Q = bit 36, P = bit 35,
  /// positions 1–35 = bits 34–0.
  static const int acMagnitudeMask = (1 << 37) - 1;

  /// The P-position bit inside [acMagnitude].
  static const int acPBit = 1 << 35;

  /// The Q-position bit inside [acMagnitude].
  static const int acQBit = 1 << 36;

  /// Core storage; each cell holds one 36-bit word.
  ///
  /// Cells start at +0: a recorded decision (ED-6), because the CT Loader
  /// fills every program-relevant cell before execution and no source
  /// attests a power-on value.
  final Uint64List memory = Uint64List(memoryWords);

  /// AC sign: 0 = plus, 1 = minus.
  int acSign = 0;

  /// AC magnitude, 37 bits: Q, P, 1–35 (22-6528-4 pp. 8–9, external).
  int acMagnitude = 0;

  /// The multiplier-quotient register, one 36-bit word (S, 1–35).
  int mq = 0;

  /// The sense-indicator register. SI position 0 is bit 35, so LDI and STI
  /// are bit-for-bit word moves (22-6528-4 pp. 9, 51, external).
  int si = 0;

  /// The instruction counter, 15 bits.
  int ic = 0;

  /// Overflow indicator (22-6528-4 p. 11, external).
  bool overflow = false;

  /// Divide-check indicator (22-6528-4 p. 11, external).
  bool divideCheck = false;

  /// Index registers 1, 2, 4 in tag-bit order.
  final Uint16List _xr = Uint16List(3);

  /// The AC as a sign-magnitude word (S, 1–35); P and Q drop out. This is
  /// what STO stores (22-6528-4 p. 33, external).
  int get acWord => (acSign << 35) | (acMagnitude & Word36.magnitudeMask);

  /// The AC's logical word (P, 1–35); P takes the S position. This is what
  /// SLW stores (22-6528-4 p. 33, external).
  int get acLogicalWord => acMagnitude & Word36.wordMask;

  /// Reads the index registers named by [tag] (0–7): the logical OR of every
  /// named register; 0 with tag 0 (22-6528-4 p. 10, external).
  int xrRead(int tag) {
    RangeError.checkValueInInterval(tag, 0, 7, 'tag');
    var value = 0;
    if (tag & 1 != 0) {
      value |= _xr[0];
    }
    if (tag & 2 != 0) {
      value |= _xr[1];
    }
    if (tag & 4 != 0) {
      value |= _xr[2];
    }
    return value;
  }

  /// Loads [value] (masked to 15 bits) into every index register named by
  /// [tag]; a no-operation with tag 0 (22-6528-4 pp. 10, 45, external).
  void xrWrite(int tag, int value) {
    RangeError.checkValueInInterval(tag, 0, 7, 'tag');
    final int masked = value & Word36.fieldMask15;
    if (tag & 1 != 0) {
      _xr[0] = masked;
    }
    if (tag & 2 != 0) {
      _xr[1] = masked;
    }
    if (tag & 4 != 0) {
      _xr[2] = masked;
    }
  }

  /// Reads the word at [location] (15-bit, checked).
  int read(int location) {
    RangeError.checkValueInInterval(location, 0, memoryWords - 1, 'location');
    return memory[location];
  }

  /// Writes [word] (checked to 36 bits) at [location].
  void write(int location, int word) {
    RangeError.checkValueInInterval(location, 0, memoryWords - 1, 'location');
    if (word < 0 || word > Word36.wordMask) {
      throw ArgumentError.value(word, 'word', 'must fit in 36 bits');
    }
    memory[location] = word;
  }
}
