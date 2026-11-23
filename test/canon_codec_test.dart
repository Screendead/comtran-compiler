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

    test('rejects a malformed file', () {
      Uint8List header(int index, int value) =>
          encodeCanon([])..[index] = value;
      final Uint8List oneCard = encodeCanon([CardImage.blank()]);
      final Map<String, Uint8List> files = {
        'short': Uint8List(5),
        'bad magic': header(0, 0x58),
        'unknown version': header(6, 2),
        'nonzero flags': header(7, 1),
        'truncated card': Uint8List.sublistView(oneCard, 0, oneCard.length - 1),
        'padded card': Uint8List(oneCard.length + 1)..setAll(0, oneCard),
      };
      files.forEach((String name, Uint8List bytes) {
        expect(
          () => decodeCanon(bytes),
          throwsA(isA<FormatException>()),
          reason: name,
        );
      });
    });
  });
}
