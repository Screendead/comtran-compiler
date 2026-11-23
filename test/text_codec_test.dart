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

    test('accepts a full 80-column glyph line', () {
      final text = '${'A' * 80}\n';
      expect(deckToMirror(mirrorToDeck(text)), text);
    });

    test('rejects malformed text', () {
      for (final text in [
        'ABC', // no final newline
        'ABC\r\n',
        'ABC \n', // trailing space
        'abc\n', // outside the source set
        'A#B\n',
        '${'A' * 81}\n',
        '! 2:9\n', // a punch line for a glyph-representable card
        '!\n',
        '!  1:12-0\n',
        '! 0:12-0\n',
        '! 81:12-0\n',
        '! 1:8-12\n',
        '! 2:12-0 1:11-0\n',
        '! 1:\n',
      ]) {
        expect(
          () => mirrorToDeck(text),
          throwsA(isA<FormatException>()),
          reason: text,
        );
      }
    });
  });

  test('the committed 90.05 canon and mirror convert into each other', () {
    final Uint8List bytes = File(
      'test/fixtures/90.05-payroll.ctd',
    ).readAsBytesSync();
    final String text = File(
      'test/fixtures/90.05-payroll.ct',
    ).readAsStringSync();
    expect(deckToMirror(decodeCanon(bytes)), text);
    expect(encodeCanon(mirrorToDeck(text)), bytes);
  });
}
