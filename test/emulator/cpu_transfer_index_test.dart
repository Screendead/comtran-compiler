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

  void runOne(int word) {
    m
      ..write(0x100, word)
      ..ic = 0x100;
    cpu.step();
  }

  // TRA: 22-6528-4 p. 36 (external); indirect addressing p. 11.
  group('TRA', () {
    test('sets the IC to the effective address', () {
      runOne(typeB(0x010, address: 0x300)); // +0020
      expect(m.ic, 0x300);
    });

    test('indexes the address', () {
      m.xrWrite(2, 0x10);
      runOne(typeB(0x010, address: 0x300, tag: 2));
      expect(m.ic, 0x2F0);
    });

    test("TRA* takes one level of indirection with the word's own tag", () {
      // The TRA* shape: J 90.05 listing, PDF p. 202, LOC 00350.
      m
        ..xrWrite(1, 3)
        ..write(0x300, typeA(0, tag: 1, address: 0x403)); // Tag 1, addr 0x403.
      runOne(typeB(0x010, address: 0x300, flag: true));
      expect(m.ic, 0x400); // 0x403 - XR1.
    });
  });

  // TPL: 22-6528-4 p. 38 (external).
  group('TPL', () {
    test('transfers on a plus sign, falls through on minus', () {
      runOne(typeB(0x050, address: 0x300)); // +0120
      expect(m.ic, 0x300);
      m.acSign = 1; // A minus zero does not transfer.
      runOne(typeB(0x050, address: 0x300));
      expect(m.ic, 0x101);
    });
  });

  // TSX: 22-6528-4 p. 39 (external).
  group('TSX', () {
    test("places the 2's complement of its location and transfers", () {
      runOne(typeB(0x03C, address: 0x300, tag: 4)); // +0074
      expect(m.ic, 0x300);
      expect(m.xrRead(4), (0x8000 - 0x100) & 0x7FFF);
    });

    test('the calling-sequence return convention works', () {
      // TSX SYS)N,4 ... parameter words ... return TRA 3,4: the effective
      // address 3 - XR4 = the TSX location + 3 (pp. 10, 39).
      m
        ..write(0x100, typeB(0x03C, address: 0x300, tag: 4))
        ..write(0x300, typeB(0x010, address: 3, tag: 4)) // TRA 3,4
        ..ic = 0x100;
      cpu
        ..step()
        ..step();
      expect(m.ic, 0x103);
    });
  });

  // TXI/TXH/TXL: 22-6528-4 pp. 39-40 (external).
  group('type A transfers', () {
    test('TXI adds the decrement and transfers', () {
      m.xrWrite(1, 10);
      runOne(typeA(1, decrement: 6, tag: 1, address: 0x300));
      expect(m.xrRead(1), 16);
      expect(m.ic, 0x300);
    });

    test('TXI wraps at 15 bits', () {
      // 22-6528-4 p. 10 (external): carries into the sixteenth position
      // are lost.
      m.xrWrite(1, 0x7FFF);
      runOne(typeA(1, decrement: 2, tag: 1, address: 0x300));
      expect(m.xrRead(1), 1);
    });

    test('TXH transfers only when XR > D', () {
      m.xrWrite(4, 5);
      runOne(typeA(3, decrement: 4, tag: 4, address: 0x300));
      expect(m.ic, 0x300);
      runOne(typeA(3, decrement: 5, tag: 4, address: 0x300));
      expect(m.ic, 0x101);
    });

    test('TXL transfers when XR <= D', () {
      // The SYS)294 guard shape: LAC BL)N,N / TXL SYS)294,N,0 transfers
      // exactly when the base locator is unloaded (J 90.02.33).
      m.xrWrite(1, 0);
      runOne(typeA(7, tag: 1, address: 0x300));
      expect(m.ic, 0x300);
      m.xrWrite(1, 1);
      runOne(typeA(7, tag: 1, address: 0x300));
      expect(m.ic, 0x101);
    });
  });

  // Index transmission: 22-6528-4 pp. 45-47 (external).
  group('index transmission', () {
    test('AXT loads the literal address; a tag of 7 loads all three', () {
      // AXT *+3,7 at END.OF.RUN (J 90.05 listing, PDF p. 203).
      runOne(typeB(0x1FC, address: 0x123, tag: 7)); // +0774
      expect(m.xrRead(1), 0x123);
      expect(m.xrRead(2), 0x123);
      expect(m.xrRead(4), 0x123);
    });

    test('a multiple-tag read is the OR of the named registers', () {
      // 22-6528-4 p. 10 (external).
      m
        ..xrWrite(1, 0x304) // 0o1404
        ..xrWrite(4, 0x631); // 0o3061
      expect(m.xrRead(5), 0x304 | 0x631);
    });

    test('SXA stores into the address field only; tag 0 stores zeros', () {
      m
        ..write(0x200, data(0x123456789, negative: true))
        ..xrWrite(2, 0x77);
      runOne(typeB(0x19C, address: 0x200, tag: 2)); // +0634
      final int stored = m.read(0x200);
      expect(Word36.address(stored), 0x77);
      expect(stored & ~0x7FFF, data(0x123456789, negative: true) & ~0x7FFF);
      runOne(typeB(0x19C, address: 0x200));
      expect(Word36.address(m.read(0x200)), 0);
    });

    test('LXA loads from the address field of Y', () {
      m.write(0x200, data(0x555));
      runOne(typeB(0x15C, address: 0x200, tag: 1)); // +0534
      expect(m.xrRead(1), 0x555);
    });

    test("LAC loads the 2's complement; CAL DATANAME,T reaches the base", () {
      // The base-locator idiom: LAC BL)2,4 / CAL DATANAME,4 (J 90.02.04).
      m
        ..write(0x200, data(0x400)) // BL)2 holds the base 0x400.
        ..write(0x405, data(9)) // The data item, displacement 5.
        ..write(0x100, typeB(0x15D, address: 0x200, tag: 4)) // LAC
        ..write(0x101, typeB(0x940, address: 5, tag: 4)) // CAL 5,4
        ..ic = 0x100;
      cpu.step();
      expect(m.xrRead(4), (0x8000 - 0x400) & 0x7FFF);
      cpu.step();
      expect(m.acMagnitude, 9); // 5 - (2^15 - 0x400) = 0x405 mod 2^15.
    });

    test('LAC of address zero gives zero', () {
      m.write(0x200, 0);
      runOne(typeB(0x15D, address: 0x200, tag: 1));
      expect(m.xrRead(1), 0);
    });

    test('PXA clears the AC and places the index in the address part', () {
      m
        ..acSign = 1
        ..acMagnitude = MachineState.acQBit | 0x123
        ..xrWrite(1, 0x77);
      runOne(typeB(0x1EC, tag: 1)); // +0754
      expect(m.acSign, 0);
      expect(m.acMagnitude, 0x77);
    });

    test('PDX takes AC positions 3-17; the AC stands', () {
      // The complex base-locator shape: PDX 0,4 / TXL *2,4,5 (J 90.02.11).
      m.acMagnitude = 0x1234 << 18; // Decrement field of S,1-35.
      runOne(typeB(0x9DC, tag: 4)); // -0734
      expect(m.xrRead(4), 0x1234);
      expect(m.acMagnitude, 0x1234 << 18);
    });
  });

  // CAS: 22-6528-4 p. 43 (external): a plus zero is algebraically greater
  // than a minus zero.
  group('CAS', () {
    void cas(int address) => runOne(typeB(0x0E0, address: address));

    test('greater takes the next instruction', () {
      m
        ..acMagnitude = 5
        ..write(0x200, data(3));
      cas(0x200);
      expect(m.ic, 0x101);
    });

    test('equal skips one', () {
      m
        ..acMagnitude = 3
        ..write(0x200, data(3));
      cas(0x200);
      expect(m.ic, 0x102);
    });

    test('less skips two', () {
      m
        ..acMagnitude = 3
        ..write(0x200, data(5));
      cas(0x200);
      expect(m.ic, 0x103);
    });

    test('minus magnitudes compare in reverse', () {
      m
        ..acSign = 1
        ..acMagnitude = 3
        ..write(0x200, data(5, negative: true));
      cas(0x200); // -3 > -5.
      expect(m.ic, 0x101);
    });

    test('+0 is greater than -0; -0 is less than +0; -0 equals -0', () {
      m.write(0x200, data(0, negative: true));
      cas(0x200); // +0 : -0.
      expect(m.ic, 0x101);

      m
        ..acSign = 1
        ..write(0x200, data(0));
      cas(0x200); // -0 : +0.
      expect(m.ic, 0x103);

      m
        ..acSign = 1
        ..write(0x200, data(0, negative: true));
      cas(0x200); // -0 : -0.
      expect(m.ic, 0x102);
    });

    test('a 1 in P makes the AC magnitude larger than any word', () {
      m
        ..acMagnitude = MachineState.acPBit
        ..write(0x200, data(Word36.magnitudeMask));
      cas(0x200);
      expect(m.ic, 0x101);
    });
  });

  // LAS: 22-6528-4 p. 43 (external): unsigned, Q,P,1-35 against S,1-35.
  group('LAS', () {
    void las(int address) => runOne(typeB(0x8E0, address: address));

    test('treats the S bit of Y as a magnitude bit', () {
      m
        ..acMagnitude = MachineState
            .acPBit // 2^35.
        ..write(0x200, data(0, negative: true)); // Also 2^35 unsigned.
      las(0x200);
      expect(m.ic, 0x102); // Equal.
    });

    test('Q outweighs any 36-bit word', () {
      m
        ..acMagnitude = MachineState.acQBit
        ..write(0x200, Word36.wordMask);
      las(0x200);
      expect(m.ic, 0x101); // Greater.
    });

    test('less skips two', () {
      m
        ..acMagnitude = 1
        ..write(0x200, data(2));
      las(0x200);
      expect(m.ic, 0x103);
    });
  });
}
