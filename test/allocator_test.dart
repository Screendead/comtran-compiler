import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

void main() {
  test('--pedantic changes no allocation of 90.05 (D11.4)', () {
    DictionaryAllocation allocate({required bool pedantic}) => runSemantics(
      runParser(runFrontEnd(loadPayrollDeck(), pedantic: pedantic)),
      pedantic: pedantic,
    ).allocation!;
    final DictionaryAllocation plain = allocate(pedantic: false);
    final DictionaryAllocation pedantic = allocate(pedantic: true);
    expect(pedantic.annotations.locByCard, plain.annotations.locByCard);
    expect(pedantic.annotations.nameByCard, plain.annotations.nameByCard);
  });
}
