import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  // Field layout: 22-6528-4 pp. 7-10 (external); design doc §2, §4.
  group('Word36 fields', () {
    test('sign and magnitude split at position S', () {
      expect(Word36.sign(0), 0);
      expect(Word36.sign(1 << 35), 1);
      expect(Word36.magnitude((1 << 35) | 5), 5);
      expect(Word36.magnitude(Word36.wordMask), Word36.magnitudeMask);
    });

    test('fromSignMagnitude round-trips and validates', () {
      final int minusZero = Word36.fromSignMagnitude(1, 0);
      expect(minusZero, 1 << 35);
      expect(Word36.sign(minusZero), 1);
      expect(Word36.magnitude(minusZero), 0);
      expect(() => Word36.fromSignMagnitude(2, 0), throwsArgumentError);
      expect(() => Word36.fromSignMagnitude(0, 1 << 35), throwsArgumentError);
    });

    test('prefix, decrement, tag, address', () {
      // TXI SYS)245,1,6 shape: prefix +1, decrement 6, tag 1 (J 90.05
      // listing, PDF p. 202).
      const int word = (1 << 33) | (6 << 18) | (1 << 15) | 0x0F5;
      expect(Word36.prefix(word), 1);
      expect(Word36.decrement(word), 6);
      expect(Word36.tag(word), 1);
      expect(Word36.address(word), 0x0F5);
    });

    test('flag needs 1-bits in both positions 12 and 13', () {
      // 22-6528-4 p. 11 (external).
      expect(Word36.flagged(3 << 22), isTrue);
      expect(Word36.flagged(1 << 22), isFalse);
      expect(Word36.flagged(1 << 23), isFalse);
    });

    test('operation field equals the listing print', () {
      // TRA* END.OF.MASTERS prints 0020 60 0 00331 (J 90.05 listing,
      // PDF p. 202). 0o331 = 0xD9.
      const int word = (0x010 << 24) | (3 << 22) | 0xD9;
      expect(Word36.operationField(word), 0x010); // +0020
      expect(Word36.flagged(word), isTrue);
      expect(Word36.address(word), 0xD9);
    });

    test('octal rendering', () {
      expect(Word36.octal((1 << 35) | 5), '400000000005');
      expect(Word36.operationOctal(0x140), '+0500');
      expect(Word36.operationOctal(0x940), '-0500');
    });
  });
}
