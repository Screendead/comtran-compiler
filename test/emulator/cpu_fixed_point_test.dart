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

  /// Places [word] at 0x100, points the IC at it, and executes it.
  void runOne(int word) {
    m
      ..write(0x100, word)
      ..ic = 0x100;
    cpu.step();
  }

  // CLA: 22-6528-4 p. 20 (external).
  group('CLA', () {
    test('loads sign and magnitude; clears P and Q', () {
      m
        ..acMagnitude = MachineState.acQBit | MachineState.acPBit | 7
        ..write(0x200, data(5, negative: true));
      runOne(typeB(0x140, address: 0x200)); // +0500
      expect(m.acSign, 1);
      expect(m.acMagnitude, 5);
    });

    test('loads minus zero as minus zero', () {
      m.write(0x200, data(0, negative: true));
      runOne(typeB(0x140, address: 0x200));
      expect(m.acSign, 1);
      expect(m.acMagnitude, 0);
    });

    test("CLA* indirects through the indirect word's own tag", () {
      // TSTC-07: indirect addressing is tested only on TRA. This pins it
      // for a load. The indirect shape mirrors the TRA* test
      // (test/emulator/cpu_transfer_index_test.dart).
      m
        ..xrWrite(1, 3)
        ..write(0x300, typeA(0, tag: 1, address: 0x403)) // Indirect word.
        ..write(0x400, data(9)); // 0x403 - XR1(3) = 0x400.
      runOne(typeB(0x140, address: 0x300, flag: true)); // CLA*
      expect(m.acSign, 0);
      expect(m.acMagnitude, 9);
    });
  });

  // CAL: 22-6528-4 p. 20 (external): the sign of Y appears in position P.
  group('CAL', () {
    test('routes the S bit of Y into P and forces a plus sign', () {
      m
        ..acSign = 1
        ..acMagnitude = MachineState.acQBit
        ..write(0x200, data(5, negative: true));
      runOne(typeB(0x940, address: 0x200)); // -0500
      expect(m.acSign, 0);
      expect(m.acMagnitude, MachineState.acPBit | 5);
    });
  });

  // ADD/SUB: 22-6528-4 pp. 20-21 (external), Figure 21.
  group('ADD', () {
    test('like signs add magnitudes', () {
      m
        ..acSign = 1
        ..acMagnitude = 5
        ..write(0x200, data(3, negative: true));
      runOne(typeB(0x100, address: 0x200)); // +0400
      expect(m.acSign, 1);
      expect(m.acMagnitude, 8);
      expect(m.overflow, isFalse);
    });

    test('unlike signs, larger AC: magnitude difference, AC sign', () {
      m
        ..acMagnitude = 5
        ..write(0x200, data(3, negative: true));
      runOne(typeB(0x100, address: 0x200));
      expect(m.acSign, 0);
      expect(m.acMagnitude, 2);
    });

    test('unlike signs, larger Y: Q carry reverses the AC sign', () {
      m
        ..acMagnitude = 3
        ..write(0x200, data(5, negative: true));
      runOne(typeB(0x100, address: 0x200));
      expect(m.acSign, 1);
      expect(m.acMagnitude, 2);
    });

    test('equal magnitudes, unlike signs: zero with the original AC sign', () {
      // "Numbers of the same magnitude but different signs give a
      // resultant sign the same as the sign of the original AC" (p. 20).
      m
        ..acMagnitude = 5
        ..write(0x200, data(5, negative: true));
      runOne(typeB(0x100, address: 0x200));
      expect(m.acSign, 0); // +0
      expect(m.acMagnitude, 0);

      m
        ..acSign = 1
        ..acMagnitude = 5
        ..write(0x200, data(5));
      runOne(typeB(0x100, address: 0x200));
      expect(m.acSign, 1); // -0
      expect(m.acMagnitude, 0);
    });

    test('carry out of position 1 enters P and turns overflow on', () {
      m
        ..acMagnitude = Word36.magnitudeMask
        ..write(0x200, data(1));
      runOne(typeB(0x100, address: 0x200));
      expect(m.acMagnitude, MachineState.acPBit);
      expect(m.overflow, isTrue);
    });

    test('carry propagates from P into Q', () {
      m
        // P and 1-35 all ones.
        ..acMagnitude = (1 << 36) - 1
        ..write(0x200, data(1));
      runOne(typeB(0x100, address: 0x200));
      expect(m.acMagnitude, MachineState.acQBit);
      expect(m.overflow, isTrue);
    });

    test('carries out of Q are lost', () {
      // 22-6528-4 p. 9 (external): "Carries from Q are lost."
      m
        ..acMagnitude = MachineState.acMagnitudeMask
        ..write(0x200, data(1));
      runOne(typeB(0x100, address: 0x200));
      expect(m.acMagnitude, 0);
      expect(m.acSign, 0);
    });
  });

  group('SUB', () {
    test('reverses the sign of Y, then adds', () {
      m
        ..acMagnitude = 3
        ..write(0x200, data(5));
      runOne(typeB(0x102, address: 0x200)); // +0402
      expect(m.acSign, 1);
      expect(m.acMagnitude, 2);
      expect(m.overflow, isFalse); // Unlike effective signs: ED-2.
    });

    test('equal magnitudes give zero with the original AC sign', () {
      m
        ..acSign = 1
        ..acMagnitude = 5
        ..write(0x200, data(5, negative: true));
      runOne(typeB(0x102, address: 0x200));
      expect(m.acSign, 1); // -0
      expect(m.acMagnitude, 0);
    });

    test('subtracting a negative can overflow', () {
      m
        ..acMagnitude = Word36.magnitudeMask
        ..write(0x200, data(1, negative: true));
      runOne(typeB(0x102, address: 0x200));
      expect(m.acMagnitude, MachineState.acPBit);
      expect(m.overflow, isTrue);
    });
  });

  // ACL: 22-6528-4 pp. 21-22 (external): logical add with end-around
  // carry from P into position 35; S and Q are not affected.
  group('ACL', () {
    test('adds the S bit of Y at the P position', () {
      m.write(0x200, data(0, negative: true));
      runOne(typeB(0x0F1, address: 0x200)); // +0361
      expect(m.acMagnitude, MachineState.acPBit);
      expect(m.acSign, 0);
    });

    test('carry out of P wraps to position 35; S and Q untouched', () {
      m
        ..acSign = 1
        ..acMagnitude = MachineState.acQBit | Word36.wordMask
        ..write(0x200, data(1));
      runOne(typeB(0x0F1, address: 0x200));
      expect(m.acMagnitude, MachineState.acQBit | 1);
      expect(m.acSign, 1);
      expect(m.overflow, isFalse);
    });
  });

  // MPY: 22-6528-4 p. 22 (external).
  group('MPY', () {
    test('35 high product bits to AC, 35 low bits to MQ', () {
      m
        ..mq = data(3)
        ..write(0x200, data(5));
      runOne(typeB(0x080, address: 0x200)); // +0200
      expect(m.acSign, 0);
      expect(m.acMagnitude, 0);
      expect(m.mq, data(15));
    });

    test('a full 70-bit product splits across AC and MQ', () {
      // (2^35 - 1)^2 = (2^35 - 2) * 2^35 + 1.
      m
        ..mq = data(Word36.magnitudeMask)
        ..write(0x200, data(Word36.magnitudeMask));
      runOne(typeB(0x080, address: 0x200));
      expect(m.acMagnitude, Word36.magnitudeMask - 1);
      expect(m.mq, data(1));
    });

    test('unlike factor signs make both results negative', () {
      m
        ..mq = data(3, negative: true)
        ..write(0x200, data(5));
      runOne(typeB(0x080, address: 0x200));
      expect(m.acSign, 1);
      expect(m.mq, data(15, negative: true));
    });

    test('a zero factor of unlike sign yields minus zero in AC and MQ', () {
      // p. 22: a zero C(Y) clears AC and MQ, then the sign rule applies.
      m
        ..mq = data(7)
        ..write(0x200, data(0, negative: true));
      runOne(typeB(0x080, address: 0x200));
      expect(m.acSign, 1);
      expect(m.acMagnitude, 0);
      expect(m.mq, data(0, negative: true));
    });
  });

  // DVP: 22-6528-4 p. 24 (external).
  group('DVP', () {
    test('quotient to MQ, remainder to AC, signs per the rule', () {
      m
        // Dividend sign.
        ..acSign = 1
        ..acMagnitude = 0
        ..mq = data(35)
        ..write(0x200, data(8));
      runOne(typeB(0x091, address: 0x200)); // +0221
      expect(m.mq, data(4, negative: true)); // - / + gives a minus quotient.
      expect(m.acSign, 1); // The remainder keeps the dividend sign.
      expect(m.acMagnitude, 3);
      expect(m.divideCheck, isFalse);
    });

    test('uses the 70-bit dividend across AC and MQ', () {
      m
        ..acMagnitude = 1
        ..mq = data(5)
        ..write(0x200, data(3));
      runOne(typeB(0x091, address: 0x200));
      const int dividend = (1 << 35) + 5;
      expect(m.mq, data(dividend ~/ 3));
      expect(m.acMagnitude, dividend % 3);
    });

    test('|Y| equal to |AC| turns the divide check on and proceeds', () {
      m
        ..acMagnitude = 8
        ..mq = data(1)
        ..write(0x200, data(8));
      runOne(typeB(0x091, address: 0x200));
      expect(m.divideCheck, isTrue);
      expect(m.acMagnitude, 8); // Dividend unchanged.
      expect(m.mq, data(1));
      expect(m.ic, 0x101); // Proceeds.
    });

    test('a 1 in P forces the divide check', () {
      // p. 24: "if Q or P of the AC contains a 1, the magnitude of the
      // C(Y) is less than the C(AC)".
      m
        ..acMagnitude = MachineState.acPBit
        ..write(0x200, data(Word36.magnitudeMask));
      runOne(typeB(0x091, address: 0x200));
      expect(m.divideCheck, isTrue);
    });

    test('a zero divisor forces the divide check', () {
      // TSTC-08: |C(Y)| = 0 is never greater than |AC|, so any nonzero
      // dividend with a zero divisor turns the check on.
      m
        ..acMagnitude = 5
        ..mq = data(1)
        ..write(0x200, data(0));
      runOne(typeB(0x091, address: 0x200));
      expect(m.divideCheck, isTrue);
      expect(m.acMagnitude, 5); // Dividend unchanged.
    });

    test('a minus dividend and a minus divisor give a plus quotient', () {
      // TSTC-08: only the minus/plus case is covered above. The quotient
      // sign is the exclusive-or of the dividend and divisor signs; the
      // remainder keeps the dividend sign either way (M p. 24).
      m
        ..acSign = 1
        ..acMagnitude = 0
        ..mq = data(35)
        ..write(0x200, data(8, negative: true));
      runOne(typeB(0x091, address: 0x200));
      expect(m.mq, data(4)); // Plus quotient.
      expect(m.acSign, 1); // The remainder keeps the dividend sign.
      expect(m.acMagnitude, 3);
      expect(m.divideCheck, isFalse);
    });
  });

  // COM: 22-6528-4 p. 49 (external).
  group('COM', () {
    test('complements Q, P, 1-35 and keeps the sign', () {
      m
        ..acSign = 1
        ..acMagnitude = 5;
      runOne(typeB(0x1F0, address: 6)); // +0760...00006
      expect(m.acSign, 1);
      expect(m.acMagnitude, MachineState.acMagnitudeMask ^ 5);
    });

    test('address modification can select the sub-operation', () {
      // p. 49: "Address modification may change the instruction itself."
      m
        ..xrWrite(1, 1)
        ..acMagnitude = 0;
      runOne(typeB(0x1F0, address: 7, tag: 1)); // 7 - XR1 = 6: COM.
      expect(m.acMagnitude, MachineState.acMagnitudeMask);
    });

    test('another sub-operation throws before any state change', () {
      m
        ..write(0x100, typeB(0x1F0, address: 7)) // +0760...00007 (ETM).
        ..ic = 0x100;
      expect(
        () => cpu.step(),
        throwsA(
          isA<UnimplementedOpcode7090>().having(
            (UnimplementedOpcode7090 e) => e.operation,
            'operation',
            contains('+0760'),
          ),
        ),
      );
      expect(m.ic, 0x100); // The IC did not advance.
    });
  });
}
