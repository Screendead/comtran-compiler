import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

int _punches(String cardCode) {
  final int? p = punchesFromCardCode(cardCode);
  if (p == null) {
    throw ArgumentError.value(cardCode, 'cardCode');
  }
  return p;
}

void main() {
  group('verification anchor (deck-format.md §4.2)', () {
    test(
      'code order reproduces the native collating sequence of J 02.06.16',
      () {
        // The native display's 51 characters, lowest code to highest, from the
        // scan-resolved reading in definition §1.1. Machine specials appear as
        // their names; they have no Set H glyph.
        final List<String> expected = [
          ...'0123456789'.split(''),
          '=', "'", '+',
          ...'ABCDEFGHI'.split(''),
          'plus zero', '.', ')', '-',
          ...'JKLMNOPQR'.split(''),
          'minus zero', r'$', '*', ' ', '/',
          ...'STUVWXYZ'.split(''),
          'record mark', ',', '(', //
        ];
        final actual = <String>[];
        for (var bcd = 0; bcd < 64; bcd++) {
          if (bcd == bcdGroupMark) {
            // Listed only in the Commercial sequence, not the native display.
            continue;
          }
          final String? label = glyphFromBcd(bcd) ?? machineSpecialName(bcd);
          if (label != null) {
            actual.add(label);
          }
        }
        expect(actual, expected);
      },
    );

    test('exactly 12 codes are unattested', () {
      final unattested = <int>[];
      for (var bcd = 0; bcd < 64; bcd++) {
        if (glyphFromBcd(bcd) == null && machineSpecialName(bcd) == null) {
          unattested.add(bcd);
        }
      }
      expect(unattested, [
        0x0A,
        0x0D,
        0x0E,
        0x0F,
        0x1D,
        0x1E,
        0x2D,
        0x2E,
        0x2F,
        0x3D,
        0x3E,
        0x3F,
      ]);
    });
  });

  group('card codes of the source set', () {
    test('the twelve Set H specials read per F p. 12', () {
      const specials = {
        // Card code -> glyph. Blank is the no-punch column, tested below.
        '12': '+',
        '11': '-',
        '11-4-8': '*',
        '0-1': '/',
        '0-4-8': '(',
        '12-4-8': ')',
        '0-3-8': ',',
        '12-3-8': '.',
        '11-3-8': r'$',
        '3-8': '=',
        '4-8': "'",
      };
      specials.forEach((code, glyph) {
        final int? bcd = bcdFromPunches(_punches(code));
        expect(bcd, isNotNull, reason: code);
        expect(glyphFromBcd(bcd!), glyph, reason: code);
        expect(punchesFromBcd(bcd), _punches(code), reason: code);
      });
    });

    test('a blank column is the blank character', () {
      expect(bcdFromPunches(0), bcdBlank);
      expect(glyphFromBcd(bcdBlank), ' ');
      expect(punchesFromBcd(bcdBlank), 0);
    });

    test('letters and digits', () {
      expect(bcdFromPunches(_punches('12-1')), bcdFromGlyph('A'));
      expect(bcdFromPunches(_punches('12-9')), bcdFromGlyph('I'));
      expect(bcdFromPunches(_punches('11-1')), bcdFromGlyph('J'));
      expect(bcdFromPunches(_punches('11-9')), bcdFromGlyph('R'));
      expect(bcdFromPunches(_punches('0-2')), bcdFromGlyph('S'));
      expect(bcdFromPunches(_punches('0-9')), bcdFromGlyph('Z'));
      expect(bcdFromPunches(_punches('0')), bcdFromGlyph('0'));
      expect(bcdFromPunches(_punches('9')), bcdFromGlyph('9'));
      expect(bcdFromGlyph('0'), 0x00);
      expect(punchesFromBcd(0x00), rowBit0);
    });
  });

  group('machine specials (deck-format.md §4.3)', () {
    test('attested card codes', () {
      expect(bcdFromPunches(_punches('12-0')), 0x1A); // plus zero
      expect(bcdFromPunches(_punches('11-0')), 0x2A); // minus zero
      expect(bcdFromPunches(_punches('0-2-8')), 0x3A); // record mark
      expect(bcdFromPunches(_punches('12-5-8')), bcdGroupMark);
      expect(punchesFromBcd(0x1A), _punches('12-0'));
      expect(punchesFromBcd(0x2A), _punches('11-0'));
      expect(punchesFromBcd(0x3A), _punches('0-2-8'));
      expect(punchesFromBcd(bcdGroupMark), _punches('12-5-8'));
    });

    test('specials have no Set H glyph, so no glyph column', () {
      for (final code in ['12-0', '11-0', '0-2-8', '12-5-8']) {
        expect(isGlyphColumn(_punches(code)), isFalse, reason: code);
      }
      expect(isGlyphColumn(_punches('12-1')), isTrue);
      expect(isGlyphColumn(0), isTrue);
    });
  });

  group('read-rule edges (deck-format.md §4.1)', () {
    test('12-8-2 reads as plus zero; the canonical punch stays 12-0', () {
      expect(bcdFromPunches(_punches('12-2-8')), 0x1A);
      expect(punchesFromBcd(0x1A), _punches('12-0'));
    });

    test('12-7-8 has no readout; 7-8 elsewhere keeps the arithmetic rule', () {
      expect(bcdFromPunches(_punches('12-7-8')), isNull);
      expect(bcdFromPunches(_punches('7-8')), 0x0F);
      expect(bcdFromPunches(_punches('11-7-8')), 0x2F);
      expect(bcdFromPunches(_punches('0-7-8')), 0x3F);
    });

    test('octal 35 has no card code', () {
      expect(punchesFromBcd(0x1D), isNull);
    });

    test('illegal combinations have no readout', () {
      expect(bcdFromPunches(_punches('12-11')), isNull);
      expect(bcdFromPunches(rowBitDigit(1) | rowBitDigit(2)), isNull);
      expect(bcdFromPunches(rowBitDigit(8) | rowBitDigit(1)), isNull);
      expect(bcdFromPunches(0xFFF), isNull);
      expect(
        bcdFromPunches(rowBit12 | rowBit0 | rowBitDigit(1)),
        isNull, // 12-0-1: two digit punches under a zone.
      );
    });

    test('every code with a card code round-trips', () {
      for (var bcd = 0; bcd < 64; bcd++) {
        final int? punches = punchesFromBcd(bcd);
        if (punches != null) {
          expect(
            bcdFromPunches(punches),
            bcd,
            reason: 'octal ${bcd.toRadixString(8)}',
          );
        }
      }
    });
  });

  group('card-code strings', () {
    test('rendering uses top-to-bottom row order', () {
      expect(cardCodeFromPunches(_punches('12-5-8')), '12-5-8');
      expect(cardCodeFromPunches(rowBit12 | rowBit11), '12-11');
      expect(cardCodeFromPunches(0), '');
    });

    test('parsing is strict about order and content', () {
      expect(punchesFromCardCode('8-12'), isNull);
      expect(punchesFromCardCode('12-12'), isNull);
      expect(punchesFromCardCode('10'), isNull);
      expect(punchesFromCardCode(''), isNull);
      expect(punchesFromCardCode('12-0'), rowBit12 | rowBit0);
    });
  });
}
