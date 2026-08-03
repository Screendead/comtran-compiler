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
    m.write(0x100, word);
    m.ic = 0x100;
    cpu.step();
  }

  // LDI/STI: 22-6528-4 p. 51 (external): bit-for-bit word moves.
  group('LDI and STI', () {
    test('round-trip a full word through the sense indicators', () {
      m.write(0x200, data(0x123456789, negative: true));
      runOne(typeB(0x121, address: 0x200)); // +0441 LDI
      expect(m.si, data(0x123456789, negative: true));
      runOne(typeB(0x184, address: 0x201)); // +0604 STI
      expect(m.read(0x201), data(0x123456789, negative: true));
    });
  });

  // SIR/RIR/RFT: 22-6528-4 pp. 52, 55 (external). The generated switch
  // idiom uses exactly these masks: SIR 000001, RIR 777777, RFT 000001
  // (J 90.05 listing, PDF p. 211).
  group('SIR, RIR, RFT', () {
    test('SIR sets right-half positions; the left half stands', () {
      m.si = data(0, negative: true); // SI position 0.
      runOne(typeB(0x02D) | 1); // SIR 000001
      expect(m.si, data(1, negative: true));
    });

    test('RIR resets right-half positions only', () {
      m.si = Word36.wordMask;
      runOne(typeB(0x02F) | 0x3FFFF); // RIR 777777
      expect(m.si, Word36.wordMask & ~0x3FFFF);
    });

    test('RFT skips when every selected position is off', () {
      m.si = 0;
      runOne(typeB(0x02C) | 1); // RFT 000001
      expect(m.ic, 0x102); // Skip.
      m.si = 1;
      runOne(typeB(0x02C) | 1);
      expect(m.ic, 0x101); // No skip.
    });

    test("the listing's switch sequence behaves as a resettable flag", () {
      m.si = 0;
      runOne(typeB(0x02D) | 1); // SIR 000001: set the flag.
      runOne(typeB(0x02C) | 1); // RFT 000001: flag on, no skip.
      expect(m.ic, 0x101);
      runOne(typeB(0x02F) | 0x3FFFF); // RIR 777777: clear the right half.
      runOne(typeB(0x02C) | 1); // RFT: flag off, skip.
      expect(m.ic, 0x102);
    });
  });

  // NOP: 22-6528-4 p. 35 (external).
  test('NOP changes nothing but the IC', () {
    m.acMagnitude = 5;
    runOne(typeB(0x1F1)); // +0761
    expect(m.ic, 0x101);
    expect(m.acMagnitude, 5);
  });

  // CVR: 22-6528-4 p. 56 (external), the seven numbered steps.
  group('CVR', () {
    test('one replacement: table lookup, right shift, function into P,1-5', () {
      // AC holds one argument byte 0x3A at positions 30-35; the table
      // word at Y + 0x3A carries the function in S,1-5 and the next table
      // origin in 21-35.
      m.acSign = 1;
      m.acMagnitude = 0x3A;
      m.write(0x200 + 0x3A, (0x25 << 30) | 0x400);
      runOne(typeB(0x04C, address: 0x200) | (1 << 18)); // CVR 0x200, count 1
      expect(m.acSign, 1); // S unchanged.
      expect(m.acMagnitude, 0x25 << 30);
      expect(m.ic, 0x101);
    });

    test('two replacements chain through table origins', () {
      m.acMagnitude = 0x02; // First argument byte.
      m.write(0x202, (0x25 << 30) | 0x400); // Function 0x25, next 0x400.
      m.write(0x400, (0x11 << 30) | 0x500); // Second byte is 0 after shift.
      runOne(typeB(0x04C, address: 0x200) | (2 << 18));
      expect(m.acMagnitude, (0x11 << 30) | (0x25 << 24));
    });

    test('an initial 1 in Q survives in position 5', () {
      // p. 56 step 6: the Q bit shifted to position 5 remains regardless
      // of the table word.
      m.acMagnitude = MachineState.acQBit; // Argument byte 0.
      m.write(0x200, 0x24 << 30); // Function bit for position 5 is 0.
      runOne(typeB(0x04C, address: 0x200) | (1 << 18));
      expect(m.acMagnitude, 0x25 << 30); // 0x24 with position 5 forced on.
    });

    test('a 1 in position 20 places the last table origin in XR 1', () {
      m.acMagnitude = 0;
      m.write(0x200, (0x01 << 30) | 0x654);
      runOne(typeB(0x04C, address: 0x200, tag: 1) | (1 << 18));
      expect(m.xrRead(1), 0x654);
    });

    test('a count of zero with position 20 set loads Y itself', () {
      runOne(typeB(0x04C, address: 0x321, tag: 1));
      expect(m.xrRead(1), 0x321);
      expect(m.acMagnitude, 0);
    });
  });

  // Fail-loud behavior: design decision ED-4.
  group('unimplemented operations', () {
    test('an executed PZE parameter word throws with +0000 and the IC', () {
      m.write(0x150, typeA(0, address: 0x321)); // A PZE calling-sequence word.
      m.ic = 0x150;
      expect(
        () => cpu.step(),
        throwsA(
          isA<UnimplementedOpcode7090>()
              .having(
                (UnimplementedOpcode7090 e) => e.operation,
                'operation',
                '+0000',
              )
              .having(
                (UnimplementedOpcode7090 e) => e.location,
                'location',
                0x150,
              ),
        ),
      );
      expect(m.ic, 0x150); // No state change.
    });

    test('a non-subset type-A prefix names itself', () {
      m.write(0x150, typeA(2, decrement: 1, tag: 1)); // TIX.
      m.ic = 0x150;
      expect(
        () => cpu.step(),
        throwsA(
          isA<UnimplementedOpcode7090>().having(
            (UnimplementedOpcode7090 e) => e.operation,
            'operation',
            '+2',
          ),
        ),
      );
    });

    test('the message carries the octal word and location', () {
      final e = UnimplementedOpcode7090(
        '+0522',
        0x150,
        typeB(0x152, address: 5),
      );
      expect(e.toString(), contains('+0522'));
      expect(e.toString(), contains('00520')); // 0x150 in octal.
    });
  });
}
