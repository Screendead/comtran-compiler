import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

void main() {
  late FrontEndResult frontEnd;
  late DictionaryAllocation allocation;

  setUpAll(() {
    frontEnd = runFrontEnd(loadPayrollDeck());
    final SemanticResult semantics = runSemantics(runParser(frontEnd));
    allocation = semantics.allocation!;
  });

  /// The numbered (first) card of [statement].
  int cardOf(String statement) => frontEnd.statementNumberByCard.entries
      .firstWhere(
        (MapEntry<int, String> e) =>
            e.value == statement && frontEnd.numberedCards.contains(e.key),
      )
      .key;

  /// Every card of [statement], deck order.
  List<int> cardsOf(String statement) => [
    for (final MapEntry<int, String> e
        in frontEnd.statementNumberByCard.entries)
      if (e.value == statement) e.key,
  ];

  group('the dictionary allocator over 90.05 (M3-8)', () {
    test('starts at the attested base and gives a RECORD two words', () {
      // MASTER prints the base, 71175; DAT follows MASTER's two words.
      expect(allocation.annotations.locByCard[cardOf('1,00')], '71175');
      expect(allocation.annotations.locByCard[cardOf('2,00')], '71177');
      expect(allocation.dataWords.length, 172);
    });

    test('a continued name prints its word on the continuation line', () {
      final List<int> cards = cardsOf('3,00');
      expect(cards, hasLength(2));
      expect(allocation.annotations.locByCard[cards.first], isNull);
      expect(allocation.annotations.locByCard[cards.last], '71200');
      // Statement 107,00 (BONDENOMINATIO/N) the same way.
      final List<int> continued = cardsOf('107,00');
      expect(allocation.annotations.locByCard[continued.first], isNull);
      expect(allocation.annotations.locByCard[continued.last], '71355');
    });

    test('unnamed entries take GN names in source order', () {
      expect(allocation.annotations.nameByCard[cardOf('36,00')], (7, 'GN)001'));
      // The GN-named entry consumes its word without printing it.
      expect(allocation.annotations.locByCard[cardOf('36,00')], isNull);
      expect(allocation.generatedNames.values, hasLength(57));
    });

    test('the REDEF line takes the last data GN name, GN)057', () {
      expect(allocation.annotations.nameByCard[cardOf('168,00')], (
        7,
        'GN)057',
      ));
      expect(allocation.annotations.locByCard[cardOf('168,00')], isNull);
    });

    test('the program entry is GN)000 at word 71460, never printed', () {
      expect(allocation.programEntryWord, int.parse('71460', radix: 8));
      expect(allocation.annotations.nameByCard[cardOf('187,00')], (
        7,
        'GN)000',
      ));
      expect(allocation.annotations.locByCard.values, isNot(contains('71460')));
    });

    test('the five CALL lines print 71461 to 71465', () {
      final List<int> cards = cardsOf('187,00');
      expect(cards, hasLength(5));
      expect(
        [for (final int card in cards) allocation.annotations.locByCard[card]],
        ['71461', '71462', '71463', '71464', '71465'],
      );
      expect(allocation.synonymWords, hasLength(5));
    });

    test('procedure labels interleave with the generated labels', () {
      // The silent AT END pairs and IF joins consume words between the
      // printed label words — every value is the scan-attested one
      // (M3-8 as amended; J 90.05 pp. 192-197 and the symbolic
      // listing).
      expect(allocation.annotations.locByCard[cardOf('188,00')], '71466');
      expect(allocation.annotations.locByCard[cardOf('190,00')], '71471');
      expect(allocation.annotations.locByCard[cardOf('197,00')], '71504');
      expect(allocation.annotations.locByCard[cardOf('207,00')], '71523');
      expect(allocation.annotations.locByCard[cardOf('210,00')], '71524');
      expect(allocation.annotations.locByCard[cardOf('217,00')], '71531');
      expect(allocation.annotations.locByCard[cardOf('223,00')], '71534');
      expect(allocation.annotations.locByCard[cardOf('226,00')], '71540');
      expect(allocation.annotations.locByCard[cardOf('227,00')], '71541');
      expect(allocation.labelWords, hasLength(19));
      // An unlabelled sentence prints nothing.
      expect(allocation.annotations.locByCard[cardOf('189,00')], isNull);
    });

    test('an unlabelled END sentence prints the next generated name', () {
      // GN)077, GN)078, GN)083 close FICA.ROUTINE,
      // WITHOLDING.TAX.ROUTINE, and DEPARTMENT.END; the labelled ENDs
      // (BOND.END., SEARCH.END.) print their own label's word instead.
      expect(allocation.annotations.nameByCard[cardOf('213,00')], (
        7,
        'GN)077',
      ));
      expect(allocation.annotations.nameByCard[cardOf('216,00')], (
        7,
        'GN)078',
      ));
      expect(allocation.annotations.nameByCard[cardOf('229,00')], (
        7,
        'GN)083',
      ));
      expect(allocation.annotations.locByCard[cardOf('213,00')], isNull);
      expect(allocation.annotations.nameByCard[cardOf('223,00')], isNull);
    });

    test('environment entries take no word and print nothing', () {
      for (var statement = 173; statement <= 186; statement++) {
        for (final int card in cardsOf('$statement,00')) {
          expect(allocation.annotations.locByCard[card], isNull);
          expect(allocation.annotations.nameByCard[card], isNull);
        }
      }
    });

    test('--pedantic changes no allocation (D11.4)', () {
      final SemanticResult pedantic = runSemantics(
        runParser(runFrontEnd(loadPayrollDeck(), pedantic: true)),
        pedantic: true,
      );
      expect(
        pedantic.allocation!.annotations.locByCard,
        allocation.annotations.locByCard,
      );
      expect(
        pedantic.allocation!.annotations.nameByCard,
        allocation.annotations.nameByCard,
      );
    });
  });
}
