import 'dart:typed_data';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  group('encodeCanon', () {
    test('empty deck is a bare header', () {
      expect(encodeCanon([]), [
        0x43,
        0x54,
        0x44,
        0x45,
        0x43,
        0x4B,
        0x01,
        0x00,
        0,
        0,
        0,
        0,
      ]);
    });

    test('packing golden bytes (deck-format.md §2.2)', () {
      final columns = List<int>.filled(80, 0);
      columns[0] = 0xA00; // Column 1: rows 12 and 0 (plus zero).
      columns[1] = 0x001; // Column 2: row 9.
      columns[79] = 0xFFF; // Column 80: all twelve rows.
      final Uint8List bytes = encodeCanon([CardImage.fromColumns(columns)]);
      expect(bytes.length, 12 + 120);
      expect(bytes.sublist(8, 12), [0, 0, 0, 1]);
      expect(bytes.sublist(12, 15), [0xA0, 0x00, 0x01]);
      expect(bytes.sublist(15, 129), everyElement(0));
      expect(bytes.sublist(129, 132), [0x00, 0x0F, 0xFF]);
    });
  });

  group('decodeCanon', () {
    test('round-trips a deck', () {
      final deck = [
        CardImage.blank(),
        CardImage.fromColumns(
          List<int>.generate(80, (int i) => (i * 37) & 0xFFF),
        ),
      ];
      expect(decodeCanon(encodeCanon(deck)), deck);
    });

    test('rejects a short file', () {
      expect(() => decodeCanon(Uint8List(5)), throwsA(isA<FormatException>()));
    });

    test('rejects a bad magic', () {
      final Uint8List bytes = encodeCanon([]);
      bytes[0] = 0x58;
      expect(() => decodeCanon(bytes), throwsA(isA<FormatException>()));
    });

    test('rejects an unknown version', () {
      final Uint8List bytes = encodeCanon([]);
      bytes[6] = 2;
      expect(() => decodeCanon(bytes), throwsA(isA<FormatException>()));
    });

    test('rejects nonzero flags', () {
      final Uint8List bytes = encodeCanon([]);
      bytes[7] = 1;
      expect(() => decodeCanon(bytes), throwsA(isA<FormatException>()));
    });

    test('rejects a length that does not match the card count', () {
      final Uint8List bytes = encodeCanon([CardImage.blank()]);
      expect(
        () => decodeCanon(Uint8List.sublistView(bytes, 0, bytes.length - 1)),
        throwsA(isA<FormatException>()),
      );
      final Uint8List padded = Uint8List(bytes.length + 1)..setAll(0, bytes);
      expect(() => decodeCanon(padded), throwsA(isA<FormatException>()));
    });
  });
}
