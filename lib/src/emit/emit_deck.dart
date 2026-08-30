/// The `--emit-deck` and `--emit-loader` dumps (M4-19,
/// `docs/design/emit-stages.md`): the punch-level object deck of every
/// job, and the symbolic control cards of every job as text.
///
/// Both are attested forms. The deck is the [J 90.03] card image in the
/// canon container (`docs/design/deck-format.md` section 2.3), so it
/// carries no marker line: a job that produced no object program adds
/// no cards. The loader dump prints one `* JOB n` section per job with
/// the cards' text, or the job's marker line (D10.2; M4-2 as amended).
library;

import 'dart:typed_data';

import '../cards/canon_codec.dart';
import '../cards/card_image.dart';
import '../codegen/codegen.dart';
import '../driver/driver.dart';
import '../listing/listing.dart';
import '../loader/object_deck.dart';
import 'common.dart';

/// The deck of [job], or `null` when the job produced no object
/// program: the compile card gives the deck.name and the secondary
/// identifier, [options] the date and time the `*CTEXT` and `*CTEND`
/// cards stamp ([J 03.02.09]).
JobDeck? jobDeck(JobCompilation job, ListingOptions options) {
  final CodegenResult? codegen = job.codegen;
  if (codegen == null || codegen.stopped) {
    return null;
  }
  return objectDeck(
    codegen,
    deckName: job.parse?.compileCard?.deckName ?? '',
    secondaryIdentifier: job.parse?.compileCard?.secondaryIdentifier ?? '',
    date: options.date,
    time: options.time,
  );
}

/// The canon bytes of every job's deck on [deck], in deck order.
Uint8List emitDeck(DeckCompilation deck, ListingOptions options) =>
    encodeCanon(<CardImage>[
      for (final JobCompilation job in deck.jobs)
        ...?jobDeck(job, options)?.cards,
    ]);

/// The symbolic control cards of every job on [deck], as text.
String emitLoader(DeckCompilation deck, ListingOptions options) {
  final out = StringBuffer();
  for (final (int index, JobCompilation job) in deck.jobs.indexed) {
    if (index > 0) {
      out.writeln();
    }
    out.writeln(jobHeader(index + 1));
    final JobDeck? cards = jobDeck(job, options);
    if (cards == null) {
      out.writeln(
        job.codegen == null
            ? codeStageMarker(job.unrecovered?.shape)
            : stageStopped,
      );
      continue;
    }
    cards.symbolicCards.forEach(out.writeln);
  }
  return out.toString();
}
