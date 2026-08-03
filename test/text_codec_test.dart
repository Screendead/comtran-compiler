import 'dart:io';
import 'dart:typed_data';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

CardImage _cardFromText(String text) {
  final columns = List<int>.filled(80, 0);
  for (var i = 0; i < text.length; i++) {
    columns[i] = punchesFromBcd(bcdFromGlyph(text[i])!)!;
  }
  return CardImage.fromColumns(columns);
}

void main() {
  group('deckToMirror', () {
    test('renders glyph lines with trailing blanks trimmed', () {
      expect(deckToMirror([_cardFromText('HELLO, 1962.')]), 'HELLO, 1962.\n');
      expect(deckToMirror([CardImage.blank()]), '\n');
      expect(deckToMirror([]), '');
    });

    test('renders a punch line for machine specials and illegal punches', () {
      final columns = List<int>.filled(80, 0);
      columns[0] = punchesFromBcd(0x1A)!; // plus zero, 12-0
      columns[71] = rowBit12 | rowBit11; // an illegal combination
      expect(
        deckToMirror([CardImage.fromColumns(columns)]),
        '! 1:12-0 72:12-11\n',
      );
    });
  });

  group('mirrorToDeck', () {
    test('round-trips glyph and punch lines', () {
      const text = "PAY = RATE * 40.\n! 1:12-0 72:12-11\n\nA'B\n";
      expect(deckToMirror(mirrorToDeck(text)), text);
    });

    test('rejects text without a final newline', () {
      expect(() => mirrorToDeck('ABC'), throwsA(isA<FormatException>()));
    });

    test('rejects CR characters', () {
      expect(() => mirrorToDeck('ABC\r\n'), throwsA(isA<FormatException>()));
    });

    test('rejects trailing spaces', () {
      expect(() => mirrorToDeck('ABC \n'), throwsA(isA<FormatException>()));
    });

    test('rejects glyphs outside the source set', () {
      expect(() => mirrorToDeck('abc\n'), throwsA(isA<FormatException>()));
      expect(() => mirrorToDeck('A#B\n'), throwsA(isA<FormatException>()));
    });

    test('rejects a glyph line longer than 80 columns', () {
      expect(
        () => mirrorToDeck('${'A' * 81}\n'),
        throwsA(isA<FormatException>()),
      );
    });

    test('accepts a full 80-column glyph line', () {
      final text = '${'A' * 80}\n';
      expect(deckToMirror(mirrorToDeck(text)), text);
    });

    test('rejects a punch line for a glyph-representable card', () {
      expect(() => mirrorToDeck('! 2:9\n'), throwsA(isA<FormatException>()));
    });

    test('rejects malformed and out-of-order punch fields', () {
      expect(() => mirrorToDeck('!\n'), throwsA(isA<FormatException>()));
      expect(
        () => mirrorToDeck('!  1:12-0\n'),
        throwsA(isA<FormatException>()),
      );
      expect(() => mirrorToDeck('! 0:12-0\n'), throwsA(isA<FormatException>()));
      expect(
        () => mirrorToDeck('! 81:12-0\n'),
        throwsA(isA<FormatException>()),
      );
      expect(() => mirrorToDeck('! 1:8-12\n'), throwsA(isA<FormatException>()));
      expect(
        () => mirrorToDeck('! 2:12-0 1:11-0\n'),
        throwsA(isA<FormatException>()),
      );
      expect(() => mirrorToDeck('! 1:\n'), throwsA(isA<FormatException>()));
    });
  });

  group('the 90.05 deck', () {
    test('the mirror is normal form and round-trips', () {
      final String text = File('tests/90.05-payroll.deck').readAsStringSync();
      final List<CardImage> deck = mirrorToDeck(text);
      expect(deck.length, 293);
      expect(deckToMirror(deck), text);
    });

    test('columns 73-80 are blank on every card', () {
      final List<CardImage> deck = mirrorToDeck(
        File('tests/90.05-payroll.deck').readAsStringSync(),
      );
      for (final card in deck) {
        for (var column = 73; column <= 80; column++) {
          expect(card.punchesAt(column), 0);
        }
      }
    });

    test('the committed canon file matches the mirror', () {
      final List<CardImage> canon = decodeCanon(
        File('tests/90.05-payroll.ctdeck').readAsBytesSync(),
      );
      expect(
        deckToMirror(canon),
        File('tests/90.05-payroll.deck').readAsStringSync(),
      );
    });

    test('canon to mirror to canon reproduces the bytes exactly', () {
      final Uint8List bytes = File(
        'tests/90.05-payroll.ctdeck',
      ).readAsBytesSync();
      expect(
        encodeCanon(mirrorToDeck(deckToMirror(decodeCanon(bytes)))),
        bytes,
      );
    });
  });
}
