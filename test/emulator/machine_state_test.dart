// TSTC-06: `machine_state.dart` had no test file. Line coverage on the
// guard clauses overstated the truth (`RangeError.checkValueInInterval`
// runs on every CPU step and so counts as hit whether or not it throws).
// This file states the throw behavior directly, plus the tag-0
// no-operation rule and the register accessors that the CPU opcode tests
// only ever exercise indirectly (through STO and SLW).
import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  late MachineState m;

  setUp(() {
    m = MachineState();
  });

  group('index register guards', () {
    test('xrRead throws for a tag outside 0-7', () {
      expect(() => m.xrRead(8), throwsRangeError);
    });

    test('xrWrite throws for a tag outside 0-7', () {
      expect(() => m.xrWrite(8, 1), throwsRangeError);
    });

    test('tag 0 is a no-operation on write and reads zero', () {
      // 22-6528-4 p. 10 (external): a store under tag 0 stores zeros; the
      // CPU tests exercise this rule but never state it on its own.
      m
        ..xrWrite(1, 0x123)
        ..xrWrite(0, 0x456);
      expect(m.xrRead(0), 0);
      expect(m.xrRead(1), 0x123); // Unaffected by the tag-0 write.
    });
  });

  group('memory guards', () {
    test('read throws for a location outside 0-32767', () {
      expect(() => m.read(32768), throwsRangeError);
    });

    test('write throws for a location outside 0-32767', () {
      expect(() => m.write(32768, 0), throwsRangeError);
    });

    test('write throws ArgumentError for a word wider than 36 bits', () {
      expect(() => m.write(0, 1 << 36), throwsArgumentError);
    });

    test('write accepts the widest legal 36-bit word', () {
      m.write(0, (1 << 36) - 1);
      expect(m.read(0), (1 << 36) - 1);
    });
  });

  group('AC word accessors', () {
    test('acWord is S,1-35; P and Q drop out', () {
      // This is what STO stores (22-6528-4 p. 33, external); the CPU
      // tests exercise it only through that opcode.
      m
        ..acSign = 1
        ..acMagnitude = MachineState.acQBit | MachineState.acPBit | 5;
      expect(m.acWord, (1 << 35) | 5);
    });

    test('acLogicalWord is P,1-35; P takes the stored S position', () {
      // This is what SLW stores (22-6528-4 p. 33, external).
      m.acMagnitude = MachineState.acQBit | MachineState.acPBit | 5;
      expect(m.acLogicalWord, (1 << 35) | 5);
    });
  });
}
