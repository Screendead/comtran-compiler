import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

void main() {
  test('--pedantic changes no allocation and no code of 90.05 (D11.4)', () {
    final DeckCompilation quiet = compileDeck(loadJobDeck());
    final DeckCompilation noted = compileDeck(loadJobDeck(), pedantic: true);
    ListingAnnotations annotations(DeckCompilation deck) =>
        deck.jobs.single.semantics!.allocation!.annotations;
    expect(annotations(noted).locByCard, annotations(quiet).locByCard);
    expect(annotations(noted).nameByCard, annotations(quiet).nameByCard);
    expect(emitCode(noted), emitCode(quiet));
  });
}
