/// The encode direction against the decoder (M4-9).
///
/// `encode.dart` states no octal code of its own: it names the same
/// operations `decode.dart` reads, and these tests hold the two
/// directions together entry by entry, so the OCTAL column the listing
/// prints and the word the emulator executes cannot drift apart. The
/// sample program reaches only some of the entries.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  test('every type-B entry decodes back with its tag and address', () {
    for (final Op op in operationFields.keys) {
      final decoded = Instruction.decode(
        typeBWord(op, tag: 3, address: 0x7FFE),
      );
      expect(decoded.op, op, reason: mnemonic(op));
      expect(decoded.tag, 3);
      expect(decoded.address, 0x7FFE);
      expect(isTypeA(op), isFalse);
      if (!indicatorOps.contains(op)) {
        expect(formOf(op), WordForm.typeB);
      }
    }
  });

  test('every type-A entry decodes back with its three fields', () {
    for (final Op op in typeAPrefixes.keys) {
      final decoded = Instruction.decode(
        typeAWord(op, tag: 2, decrement: 0x1234, address: 0x2345),
      );
      expect(decoded.op, op, reason: mnemonic(op));
      expect(decoded.decrement, 0x1234);
      expect(decoded.tag, 2);
      expect(decoded.address, 0x2345);
      expect(isTypeA(op), isTrue);
      expect(formOf(op), WordForm.prefix);
    }
  });

  test('a sense-indicator mask fills the tag and address together', () {
    for (final Op op in indicatorOps) {
      expect(formOf(op), WordForm.indicator);
      expect(Instruction.decode(indicatorWord(op, 0x3FFFF)).op, op);
    }
  });
}
