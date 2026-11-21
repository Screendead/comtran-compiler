import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

void main() {
  late DictionaryAllocation allocation;

  setUpAll(() {
    allocation = runSemantics(
      runParser(runFrontEnd(loadPayrollDeck())),
    ).allocation!;
  });

  group('the dictionary allocator over 90.05 (M3-8)', () {
    test('takes the word counts the listing attests', () {
      // GN)001 to GN)057, the GN)000 entry at 71460 that never prints,
      // the five CALL lines, and the nineteen printed label words.
      expect(allocation.generatedNames.values, hasLength(57));
      expect(allocation.programEntryWord, int.parse('71460', radix: 8));
      expect(allocation.synonymWords, hasLength(5));
      expect(allocation.labelWords, hasLength(19));
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
