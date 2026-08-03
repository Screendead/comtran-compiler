// TSTC-08: emulator edge cases that no single opcode group covers on its
// own — IC wraparound at the top of memory, a compare/skip crossing that
// boundary, and the stickiness of the overflow and divide-check
// indicators across an instruction that does not itself trip them.
import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'asm.dart';

void main() {
  late MachineState m;
  late Cpu cpu;

  setUp(() {
    m = MachineState();
    cpu = Cpu(m);
  });

  // 22-6528-4 p. 9 (external): "the highest location and location zero are
  // consecutive."
  group('IC wraparound', () {
    test('the IC wraps from the highest location to zero', () {
      m
        ..write(0x7FFF, typeB(0x1F1)) // NOP, at 0o77777.
        ..ic = 0x7FFF;
      cpu.step();
      expect(m.ic, 0);
    });

    test('a CAS skip crosses the wraparound boundary', () {
      m
        ..acMagnitude = 3
        ..write(0x200, data(5)) // AC < Y: skip 2.
        ..write(0x7FFF, typeB(0x0E0, address: 0x200))
        ..ic = 0x7FFF;
      cpu.step();
      expect(m.ic, 2); // (0x7FFF + 1) & 0x7FFF = 0, then + 2.
    });

    test('a LAS skip crosses the wraparound boundary', () {
      m
        ..acMagnitude = 1
        ..write(0x200, data(2)) // AC < Y: skip 2.
        ..write(0x7FFF, typeB(0x8E0, address: 0x200))
        ..ic = 0x7FFF;
      cpu.step();
      expect(m.ic, 2);
    });

    test('an RFT skip crosses the wraparound boundary', () {
      m
        ..si =
            0 // All selected positions off: skip.
        ..write(0x7FFF, typeB(0x02C) | 1) // RFT 000001.
        ..ic = 0x7FFF;
      cpu.step();
      expect(m.ic, 1); // (0x7FFF + 1) & 0x7FFF = 0, then + 1.
    });
  });

  // The subset harvests no instruction that clears these indicators
  // (docs/design/emulator.md §8): once set, they hold until the caller
  // reads them.
  group('sticky indicators', () {
    test('overflow set earlier survives a clean ADD', () {
      m
        ..overflow = true
        ..acMagnitude = 1
        ..write(0x200, data(1))
        ..write(0x100, typeB(0x100, address: 0x200)) // ADD, no overflow.
        ..ic = 0x100;
      cpu.step();
      expect(m.acMagnitude, 2);
      expect(m.overflow, isTrue);
    });

    test('divideCheck set earlier survives a clean DVP', () {
      m
        ..divideCheck = true
        ..acMagnitude = 0
        ..mq = data(8)
        ..write(0x200, data(3)) // |Y| > |AC|: a genuine divide.
        ..write(0x100, typeB(0x091, address: 0x200)) // DVP
        ..ic = 0x100;
      cpu.step();
      expect(m.divideCheck, isTrue);
    });
  });
}
