import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

void main() {
  group('the listing', () {
    test('reproduces the committed golden byte for byte', () {
      // The golden carries the M3-8 columns, so the fixture compiles
      // through the semantic layer for the annotations.
      final FrontEndResult result = runFrontEnd(loadPayrollDeck());
      final SemanticResult semantics = runSemantics(runParser(result));
      final String listing = writeListing(
        result,
        const ListingOptions(
          date: '10/18/61',
          time: '2.45',
          title: 'COMPILATION OF SAMPLE PROBLEM',
        ),
        annotations: semantics.allocation!.annotations,
      ).text;
      expect(
        listing,
        File('test/goldens/90.05-payroll.listing').readAsStringSync(),
      );
    });

    test('diagnostics form a block with statement numbers, not ids', () {
      final List<CardImage> deck = mirrorToDeck(
        [
          'STRAY CARD',
          '      *PROCEDURE',
          "            MOVE 'ABC TO X.",
          '      DONE. STOP RUN.',
          '',
        ].join('\n'),
      );
      final FrontEndResult result = runFrontEnd(deck);
      final String listing = writeListing(
        result,
        const ListingOptions(date: '08/03/26', time: '1.00'),
      ).text;
      expect(listing, contains('THE FOLLOWING ERRORS WERE DETECTED'));
      expect(listing, contains('NUMBER   CODE   MESSAGE'));
      // The stray card is not a numbered statement: 9999,99.
      expect(listing, contains('9999,99'));
      // The unclosed literal is in statement 1: its row carries the
      // statement number and the severity, never the message id.
      expect(listing, contains('   1,00    2    ALPHABETIC LITERAL'));
      expect(listing, isNot(contains('168,00')));
      expect(listing, contains('SEVERITY LIMIT WAS NOT REACHED'));
      expect(listing, isNot(contains('NO ERRORS')));
    });

    test('a clean run prints the NO ERRORS line', () {
      final FrontEndResult result = runFrontEnd(
        mirrorToDeck('      *PROCEDURE\n            STOP RUN.\n'),
      );
      final String listing = writeListing(
        result,
        const ListingOptions(date: '08/03/26', time: '1.00'),
      ).text;
      expect(listing, contains('NO ERRORS WERE DETECTED DURING COMPILATION'));
      expect(listing, isNot(contains('SEVERITY LIMIT')));
    });

    test(
      r'a repaired column prints $, an ungated special prints ? (D9.10)',
      () {
        // Card text "MOVE AXB TO 'CXD'." with a record mark over each X: the
        // first, inside the word AXB, is gated (134,00) and prints as the
        // character-gate repair mark; the second, inside the literal 'CXD',
        // is legal and prints as any other unreadable machine character
        // (_externalBody in lib/src/listing/listing.dart).
        final List<int> columns = blankColumns();
        punchGlyphs(columns, 13, "MOVE AXB TO 'CXD'.");
        columns[18] = punchesFromBcd(0x3A)!; // record mark, column 19
        columns[26] = punchesFromBcd(0x3A)!; // record mark, column 27
        final List<CardImage> deck = [
          mirrorToDeck('      *PROCEDURE\n').single,
          CardImage.fromColumns(columns),
        ];
        final FrontEndResult result = runFrontEnd(deck);
        expect(result.diagnostics.single.message, msgIllegalCharacterReplaced);
        expect(result.diagnostics.single.column, 19);
        final String listing = writeListing(
          result,
          const ListingOptions(date: '08/03/26', time: '1.00'),
        ).text;
        expect(listing, contains(r"MOVE A$B TO 'C?D'."));
      },
    );
  });
}
