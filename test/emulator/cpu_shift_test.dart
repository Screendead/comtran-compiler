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

  // ALS: 22-6528-4 p. 31 (external).
  group('ALS', () {
    test('shifts Q,P,1-35 left; the sign stands', () {
      m
        ..acSign = 1
        ..acMagnitude = 5;
      runOne(typeB(0x1F7, address: 2)); // +0767
      expect(m.acMagnitude, 20);
      expect(m.acSign, 1);
      expect(m.overflow, isFalse);
    });

    test('a 1 moving from position 1 into P turns overflow on', () {
      m.acMagnitude = 1 << 34; // Position 1.
      runOne(typeB(0x1F7, address: 1));
      expect(m.acMagnitude, MachineState.acPBit);
      expect(m.overflow, isTrue);
    });

    test('a shift of 36 pushes position 35 into Q', () {
      m.acMagnitude = 5;
      runOne(typeB(0x1F7, address: 36));
      expect(m.acMagnitude, MachineState.acQBit);
      expect(m.overflow, isTrue); // Both 1-bits passed through P.
    });

    test('a shift of 37 or more clears the 37-bit register', () {
      m.acMagnitude = 5;
      runOne(typeB(0x1F7, address: 37));
      expect(m.acMagnitude, 0);
      expect(m.overflow, isTrue);
    });

    test('the count is the effective address modulo 400 octal', () {
      // p. 31: "Any number larger than 377 is interpreted as modulo 400."
      m.acMagnitude = 5;
      runOne(typeB(0x1F7, address: 0x100)); // 0o400: count 0.
      expect(m.acMagnitude, 5);
      expect(m.overflow, isFalse);
    });

    test('indexing modifies the count', () {
      m
        ..acMagnitude = 1
        ..xrWrite(1, 2);
      runOne(typeB(0x1F7, address: 5, tag: 1)); // 5 - 2 = 3.
      expect(m.acMagnitude, 8);
    });
  });

  // ARS: 22-6528-4 p. 32 (external).
  group('ARS', () {
    test('Q enters P, P enters 1; no indicators', () {
      m.acMagnitude = MachineState.acQBit | MachineState.acPBit;
      runOne(typeB(0x1F9, address: 1)); // +0771
      expect(m.acMagnitude, MachineState.acPBit | (1 << 34));
      expect(m.overflow, isFalse);
    });

    test('a shift of 37 or more clears the register', () {
      m.acMagnitude = MachineState.acMagnitudeMask;
      runOne(typeB(0x1F9, address: 40));
      expect(m.acMagnitude, 0);
    });

    test('matches the closed form over the documented count range', () {
      // EMU-1: ARS now runs the same stepwise loop the other five shifts
      // use, with the dead `n > 36` guard removed. This proves the
      // rewrite changed no observable result: the stepwise loop still
      // agrees with the old guarded closed form at every documented
      // count, including the boundary (36, 37) and the maximum (255,
      // after the modulo-400-octal mask; M p. 31).
      const int initial = MachineState.acMagnitudeMask; // All 37 bits set.
      for (final n in [0, 1, 35, 36, 37, 63, 255]) {
        m.acMagnitude = initial;
        runOne(typeB(0x1F9, address: n));
        final int closedForm = n > 36 ? 0 : initial >> n;
        expect(m.acMagnitude, closedForm, reason: 'n=$n');
        expect(m.overflow, isFalse, reason: 'n=$n');
      }
    });
  });

  // LRS: 22-6528-4 p. 32 (external).
  group('LRS', () {
    test('AC(35) enters MQ(1); the MQ sign takes the AC sign', () {
      m
        ..acSign = 1
        ..acMagnitude = 1
        ..mq = data(0);
      runOne(typeB(0x1F5, address: 1)); // +0765
      expect(m.acMagnitude, 0);
      expect(m.mq, data(1 << 34, negative: true));
    });

    test('a shift of 35 moves AC(1-35) into MQ(1-35)', () {
      m.acMagnitude = 5;
      runOne(typeB(0x1F5, address: 35));
      expect(m.acMagnitude, 0);
      expect(m.mq, data(5));
    });
  });

  // LGL: 22-6528-4 p. 32 (external).
  group('LGL', () {
    test('MQ(S) enters AC(35); MQ(1) enters MQ(S)', () {
      m.mq = data(0, negative: true); // Only the S bit set.
      runOne(typeB(0x9F3, address: 1)); // -0763
      expect(m.acMagnitude, 1);
      expect(m.mq, 0);
      expect(m.overflow, isFalse);
    });

    test('a 1 reaching P turns overflow on', () {
      m.acMagnitude = 1 << 34; // Position 1.
      runOne(typeB(0x9F3, address: 1));
      expect(m.overflow, isTrue);
      expect(m.acMagnitude, MachineState.acPBit);
    });

    test('a long shift drains the MQ through the AC', () {
      m
        ..acMagnitude = 0
        ..mq = data(1); // Position 35 of the MQ.
      runOne(typeB(0x9F3, address: 36)); // Through S and into AC(35).
      expect(m.acMagnitude, 1);
      expect(m.mq, 0);
    });
  });

  // LGR: 22-6528-4 p. 32 (external).
  group('LGR', () {
    test('AC(35) enters MQ(S)', () {
      m.acMagnitude = 1;
      runOne(typeB(0x9F5, address: 1)); // -0765
      expect(m.acMagnitude, 0);
      expect(m.mq, data(0, negative: true));
      expect(m.overflow, isFalse);
    });

    test('bits shifted past MQ(35) are lost', () {
      m.mq = data(1);
      runOne(typeB(0x9F5, address: 1));
      expect(m.mq, 0);
    });
  });

  // RQL: 22-6528-4 p. 32 (external): a circular register; no bits lost.
  group('RQL', () {
    test('rotates S into 35', () {
      m.mq = data(0, negative: true);
      runOne(typeB(0x9FB, address: 1)); // -0773
      expect(m.mq, 1);
    });

    test('a rotation of 36 restores the register', () {
      m.mq = data(0x123456789, negative: true);
      runOne(typeB(0x9FB, address: 36));
      expect(m.mq, data(0x123456789, negative: true));
    });

    test('a rotation of 6 moves whole characters', () {
      // The generated code uses RQL 6 to step through 6-bit bytes
      // (J 90.05 listing, PDF p. 208).
      m.mq = data(0x3F); // One character at positions 30-35.
      runOne(typeB(0x9FB, address: 6));
      expect(m.mq, data(0x3F << 6));
    });
  });

  // TSTC-07: shifts and the 0760 family call
  // `_effectiveAddress(..., indirectable: false)`, so a flagged shift word
  // must ignore the flag, unlike CLA*, STO*, CAS*, and TRA*.
  test('the flag bit is ignored: shift counts are never indirectable', () {
    m
      ..acMagnitude = 1
      // If the flag were honored, the CPU would fetch this word as the
      // indirect word and take its address (0xAA) as the count instead.
      ..write(5, typeA(0, address: 0xAA));
    runOne(typeB(0x1F7, address: 5, flag: true)); // ALS*, count 5 if ignored.
    expect(m.acMagnitude, 1 << 5);
  });
}
