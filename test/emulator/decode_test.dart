import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'asm.dart';

void main() {
  // Opcode octal values: attested by the J 90.05 listing's opcode column
  // and 22-6528-4 instruction descriptions (external); design doc §5.
  group('decode: type B subset', () {
    const Map<int, Op> codes = {
      0x140: Op.cla, // +0500
      0x940: Op.cal, // -0500
      0x100: Op.add, // +0400
      0x102: Op.sub, // +0402
      0x0F1: Op.acl, // +0361
      0x080: Op.mpy, // +0200
      0x091: Op.dvp, // +0221
      0x181: Op.sto, // +0601
      0x182: Op.slw, // +0602
      0x980: Op.stq, // -0600
      0x170: Op.ldq, // +0560
      0x059: Op.xca, // +0131
      0x1F0: Op.com, // +0760 (sub-operation checked at execution)
      0x8D0: Op.ana, // -0320
      0x0D0: Op.ans, // +0320
      0x982: Op.ors, // -0602
      0x0E0: Op.cas, // +0340
      0x8E0: Op.las, // -0340
      0x010: Op.tra, // +0020
      0x050: Op.tpl, // +0120
      0x03C: Op.tsx, // +0074
      0x1F1: Op.nop, // +0761
      0x1FC: Op.axt, // +0774
      0x19C: Op.sxa, // +0634
      0x15C: Op.lxa, // +0534
      0x15D: Op.lac, // +0535
      0x1EC: Op.pxa, // +0754
      0x9DC: Op.pdx, // -0734
      0x121: Op.ldi, // +0441
      0x184: Op.sti, // +0604
      0x02D: Op.sir, // +0055
      0x02F: Op.rir, // +0057
      0x02C: Op.rft, // +0054
      0x1F7: Op.als, // +0767
      0x1F9: Op.ars, // +0771
      0x1F5: Op.lrs, // +0765
      0x9F3: Op.lgl, // -0763
      0x9F5: Op.lgr, // -0765
      0x9FB: Op.rql, // -0773
    };

    test('every subset opcode decodes to its Op', () {
      codes.forEach((int operation, Op op) {
        expect(
          Instruction.decode(typeB(operation, address: 5)).op,
          op,
          reason: Word36.operationOctal(operation),
        );
      });
    });
  });

  group('decode: type A subset', () {
    test('prefixes +1, +3, -3 decode; +2, -2, -1 do not', () {
      // 22-6528-4 pp. 34, 39-40 (external).
      expect(Instruction.decode(typeA(1)).op, Op.txi);
      expect(Instruction.decode(typeA(3)).op, Op.txh);
      expect(Instruction.decode(typeA(7)).op, Op.txl);
      expect(Instruction.decode(typeA(2)).op, Op.unknown); // TIX
      expect(Instruction.decode(typeA(6)).op, Op.unknown); // TNX
      expect(Instruction.decode(typeA(5)).op, Op.unknown); // STR
    });

    test('type-A fields', () {
      final inst = Instruction.decode(
        typeA(7, decrement: 5, tag: 4, address: 0x123),
      );
      expect(inst.op, Op.txl);
      expect(inst.decrement, 5);
      expect(inst.tag, 4);
      expect(inst.address, 0x123);
      expect(inst.operationOctal, '-3');
    });
  });

  group('decode: convert sub-format', () {
    test('CVR is +0114 with the count in positions 10-17', () {
      // 22-6528-4 p. 56 (external): the operation is S,1-9; positions
      // 10-11 belong to the count and overlap the 12-bit field.
      final plain = Instruction.decode(typeB(0x04C, address: 9));
      expect(plain.op, Op.cvr);
      expect(plain.count, 0);
      final counted = Instruction.decode(typeB(0x04C, address: 9) | (6 << 18));
      expect(counted.op, Op.cvr);
      expect(counted.count, 6);
    });

    test('CAQ (-0114) stays outside the subset', () {
      expect(Instruction.decode(typeB(0x84C)).op, Op.unknown);
    });
  });

  group('decode: non-subset words', () {
    test('an executed parameter word (+0000, PZE shape) is unknown', () {
      expect(Instruction.decode(0).op, Op.unknown);
      expect(Instruction.decode(0).operationOctal, '+0000');
    });

    test('an MZE word (-0) is unknown', () {
      final inst = Instruction.decode(1 << 35);
      expect(inst.op, Op.unknown);
      expect(inst.operationOctal, '-0000');
    });

    test('a non-subset opcode reports its signed octal', () {
      // XEC is +0522 (22-6528-4 p. 36, external): 0o0522 = 0x152.
      final inst = Instruction.decode(typeB(0x152));
      expect(inst.op, Op.unknown);
      expect(inst.operationOctal, '+0522');
    });
  });
}
