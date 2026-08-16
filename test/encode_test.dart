/// The encode direction against the decoder (M4-9).
///
/// `encode.dart` states no octal code of its own: it names the same
/// operations `decode.dart` reads, and these tests hold the two
/// directions together entry by entry, so the OCTAL column the listing
/// prints and the word the emulator executes cannot drift apart.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  group('the type-B table', () {
    test('every entry decodes back to its own operation', () {
      for (final MapEntry<Op, int> entry in operationFields.entries) {
        expect(
          Instruction.decode(typeBWord(entry.key)).op,
          entry.key,
          reason:
              '${mnemonic(entry.key)} encodes to a word the decoder '
              'reads as something else',
        );
      }
    });

    test('the tag and address survive the round trip', () {
      for (final Op op in operationFields.keys) {
        final decoded = Instruction.decode(
          typeBWord(op, tag: 3, address: 0x7FFE),
        );
        expect(decoded.op, op);
        expect(decoded.tag, 3);
        expect(decoded.address, 0x7FFE);
      }
    });

    test('COM carries its sub-operation in the address field', () {
      final decoded = Instruction.decode(
        typeBWord(Op.com, address: comSubOperation),
      );
      expect(decoded.op, Op.com);
      expect(decoded.operationOctal, '+0760');
      expect(decoded.address, comSubOperation);
    });
  });

  group('the type-A table', () {
    test('every entry decodes back to its own operation', () {
      for (final Op op in typeAPrefixes.keys) {
        expect(isTypeA(op), isTrue);
        expect(formOf(op), WordForm.prefix);
        expect(Instruction.decode(typeAWord(op)).op, op);
      }
    });

    test('the decrement, tag and address survive the round trip', () {
      for (final Op op in typeAPrefixes.keys) {
        final decoded = Instruction.decode(
          typeAWord(op, tag: 2, decrement: 0x1234, address: 0x2345),
        );
        expect(decoded.op, op);
        expect(decoded.decrement, 0x1234);
        expect(decoded.tag, 2);
        expect(decoded.address, 0x2345);
      }
    });

    test('a type-B operation takes the type-B form', () {
      for (final Op op in operationFields.keys) {
        expect(isTypeA(op), isFalse);
        if (indicatorOps.contains(op)) {
          continue;
        }
        expect(formOf(op), WordForm.typeB);
      }
    });
  });

  group('the sense-indicator instructions', () {
    test('the mask fills the tag and address fields together', () {
      for (final Op op in indicatorOps) {
        expect(formOf(op), WordForm.indicator);
        expect(Instruction.decode(indicatorWord(op, 0x3FFFF)).op, op);
      }
    });

    test('the OCTAL column prints the attested RIR line', () {
      expect(
        octalColumn(indicatorWord(Op.rir, 0x3FFFF), formOf(Op.rir)),
        '0057 00 777777',
      );
    });
  });

  group('the PZE address word', () {
    test('it carries the calling sequence in the three fields', () {
      final decoded = Instruction.decode(
        pzeWord(decrement: 1, tag: 4, address: 0x0123),
      );
      expect(decoded.decrement, 1);
      expect(decoded.tag, 4);
      expect(decoded.address, 0x0123);
    });

    test('its prefix is zero, so no type-A operation reads it', () {
      expect(Word36.prefix(pzeWord(address: 0x7FFF)) & 3, 0);
    });
  });
}
