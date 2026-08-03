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

  // Store instructions: 22-6528-4 p. 33 (external), Figure 27.
  group('stores', () {
    test('STO stores S,1-35 and drops Q and P', () {
      m
        ..acSign = 1
        ..acMagnitude = MachineState.acQBit | MachineState.acPBit | 5;
      runOne(typeB(0x181, address: 0x200)); // +0601
      expect(m.read(0x200), data(5, negative: true));
      expect(Word36.octal(m.read(0x200)), '400000000005');
    });

    test('SLW stores P,1-35; P lands in the stored S position', () {
      m
        ..acSign = 1
        ..acMagnitude = MachineState.acQBit | MachineState.acPBit | 5;
      runOne(typeB(0x182, address: 0x200)); // +0602
      expect(m.read(0x200), (1 << 35) | 5);
    });

    test('STQ stores a negative MQ word bit-for-bit', () {
      m.mq = data(7, negative: true);
      runOne(typeB(0x980, address: 0x200)); // -0600
      expect(m.read(0x200), data(7, negative: true));
    });
  });

  group('LDQ and XCA', () {
    test('LDQ loads the word unchanged', () {
      // 22-6528-4 p. 33 (external).
      m.write(0x200, data(9, negative: true));
      runOne(typeB(0x170, address: 0x200)); // +0560
      expect(m.mq, data(9, negative: true));
    });

    test('XCA exchanges AC(S,1-35) with MQ and clears P and Q', () {
      // 22-6528-4 p. 34 (external).
      m
        ..acSign = 1
        ..acMagnitude = MachineState.acQBit | MachineState.acPBit | 5
        ..mq = data(9);
      runOne(typeB(0x059)); // +0131
      expect(m.acSign, 0);
      expect(m.acMagnitude, 9);
      expect(m.mq, data(5, negative: true));
    });
  });

  // Logical operations: 22-6528-4 p. 48 (external). The S position of Y
  // corresponds to P of the AC.
  group('ANA, ANS, ORS', () {
    test('ANA masks into the AC and clears S and Q', () {
      m
        ..acSign = 1
        ..acMagnitude = MachineState.acQBit | Word36.wordMask
        ..write(0x200, data(0, negative: true)); // Only the S bit.
      runOne(typeB(0x8D0, address: 0x200)); // -0320
      expect(m.acSign, 0);
      expect(m.acMagnitude, MachineState.acPBit);
    });

    test('ANS stores the AND into Y and keeps the AC', () {
      m
        ..acMagnitude = MachineState.acPBit | 0xF0
        ..write(0x200, data(0xFF, negative: true));
      runOne(typeB(0x0D0, address: 0x200)); // +0320
      expect(m.read(0x200), (1 << 35) | 0xF0);
      expect(m.acMagnitude, MachineState.acPBit | 0xF0);
    });

    test('ORS stores the OR into Y and keeps the AC', () {
      m
        ..acMagnitude = 0x0F
        ..write(0x200, data(0xF0));
      runOne(typeB(0x982, address: 0x200)); // -0602
      expect(m.read(0x200), 0xFF);
      expect(m.acMagnitude, 0x0F);
    });
  });

  // The generated error-flag shape: CAL flag word / ANA mask / ORS target
  // (J 90.05 listing, PDF p. 201, LOC 00323-00324).
  test('the CAL-ANA-ORS masking idiom works end to end', () {
    m
      ..write(0x200, data(0x3F << 6, negative: true)) // Flag source.
      ..write(0x201, data(0x3F << 6)) // Mask.
      ..write(0x202, 0) // Target.
      ..write(0x100, typeB(0x940, address: 0x200)) // CAL
      ..write(0x101, typeB(0x8D0, address: 0x201)) // ANA
      ..write(0x102, typeB(0x982, address: 0x202)) // ORS
      ..ic = 0x100;
    cpu
      ..step()
      ..step()
      ..step();
    expect(m.read(0x202), 0x3F << 6);
    expect(m.ic, 0x103);
  });
}
