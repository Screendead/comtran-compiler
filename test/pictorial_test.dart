import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  group('pictorial measurement (M3-5)', () {
    test('V, S, and F reserve no storage (F p. 80)', () {
      expect(Pictorial.tryParse('99V999')!.storageChars, 5);
      expect(Pictorial.tryParse('999SSS')!.storageChars, 3);
      expect(Pictorial.tryParse('899V99')!.storageChars, 5);
      expect(Pictorial.tryParse('+99V9F+99')!.storageChars, 7);
    });

    test('every other format character reserves one position', () {
      expect(Pictorial.tryParse(r'$8889.99')!.storageChars, 8);
      expect(Pictorial.tryParse('88889.99')!.storageChars, 8);
      expect(Pictorial.tryParse(r'$888,888.99')!.storageChars, 11);
      expect(Pictorial.tryParse('A(30)')!.storageChars, 30);
      expect(Pictorial.tryParse('9(4)A(12)')!.storageChars, 16);
    });

    test('fraction positions count digits and S after the V', () {
      expect(Pictorial.tryParse('99V999')!.fractionDigits, 3);
      expect(Pictorial.tryParse('VS9')!.fractionDigits, 2);
      expect(Pictorial.tryParse('9(5)')!.fractionDigits, 0);
    });

    test('exponent digits after the F are not fraction (J 02.04.02)', () {
      expect(Pictorial.tryParse('99V99F+99')!.fractionDigits, 2);
      expect(Pictorial.tryParse('999SSSF+99')!.fractionDigits, -3);
    });

    test('a trailing S run scales an integer (999SSS, F p. 80)', () {
      final Pictorial shape = Pictorial.tryParse('999SSS')!;
      expect(shape.fractionDigits, -3);
      expect(shape.valueDigits, 6);
    });

    test('a trailing zone letter is an overpunched digit (M2-3 amendment)', () {
      final Pictorial minus = Pictorial.tryParse('99R')!;
      expect(minus.sign, SignConvention.overpunchMinus);
      expect(minus.digitCount, 3);
      expect(minus.storageChars, 3);
      expect(Pictorial.tryParse('99I')!.sign, SignConvention.overpunchPlus);
      expect(Pictorial.tryParse('9(4)J')!.sign, SignConvention.overpunchMinus);
    });

    test('a zone letter after A, X, or F keeps the run a name', () {
      expect(Pictorial.tryParse('AAR'), isNull);
      expect(Pictorial.tryParse('9F9R'), isNull);
      expect(Pictorial.tryParse('R'), isNull);
    });

    test('a name is not a pictorial (J 02.05.06)', () {
      expect(Pictorial.tryParse('MASTER'), isNull);
      expect(Pictorial.tryParse('RATE'), isNull);
      expect(Pictorial.tryParse('9B9'), isNull);
    });

    test('free-standing signs place leading or trailing', () {
      expect(Pictorial.tryParse('+999')!.sign, SignConvention.plusLeading);
      expect(Pictorial.tryParse('999-')!.sign, SignConvention.minusTrailing);
    });

    test('a zero count reads as one and is flagged (msg 60)', () {
      final Pictorial shape = Pictorial.tryParse('9(0)')!;
      expect(shape.storageChars, 1);
      expect(shape.zeroCountRepaired, isTrue);
    });

    test('an unclosed count is accepted only when allowed (msg 133)', () {
      expect(Pictorial.tryParse('9(4'), isNull);
      final Pictorial shape = Pictorial.tryParse(
        '9(4',
        allowUnclosedCount: true,
      )!;
      expect(shape.missingRightParen, isTrue);
      expect(shape.storageChars, 4);
    });
  });
}
