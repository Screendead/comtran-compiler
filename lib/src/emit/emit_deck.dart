/// The deck writer (LD-2) and the `--emit-deck` and `--emit-loader` dumps
/// (M4-19, `docs/design/emit-stages.md`): [jobDeck] punches one job's
/// cards; the dumps print the punch-level object deck of every job, and
/// the symbolic control cards of every job as text.
///
/// Both dumps are attested forms. The deck is the [J 90.03] card image
/// in the canon container (`docs/design/deck-format.md` section 2.3), so
/// it carries no marker line: a job that produced no object program adds
/// no cards. The loader dump prints one `* JOB n` section per job with
/// the cards' text, or the job's marker line (D10.2; M4-2 as amended).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../cards/canon_codec.dart';
import '../cards/card_image.dart';
import '../cards/text_codec.dart';
import '../codegen/codegen.dart';
import '../codegen/control_cards.dart';
import '../codegen/text_model.dart';
import '../driver/driver.dart';
import '../listing/listing.dart';
import '../loader/object_deck.dart';
import 'common.dart';

/// One job's object deck.
final class JobDeck {
  const JobDeck({required this.symbolicCards, required this.cards});

  /// The symbolic control cards' text, deck order, each with its
  /// serial: the `*FILE` and `*SPEC` pairs, `*CTEXT`, then `*CTEND`.
  final List<String> symbolicCards;

  /// Every card of the deck, punch order.
  final List<CardImage> cards;

  /// The cards the loader-card page lists: every symbolic card before
  /// the binary deck, `*CTEXT` last.
  List<String> get cardsBeforeText =>
      symbolicCards.sublist(0, symbolicCards.length - 1);

  /// The `*CTEND` card, which the closing lines print.
  String get lastCard => symbolicCards.last;
}

/// The deck of [job]: the control cards, `*CTEXT`, the text section at
/// [textCardWords] words a card, `*CTEND` ([J 03.01.02]). `null` when
/// the job produced no object program.
///
/// The compile card gives the deck name and the secondary identifier,
/// [options] the date and time the `*CTEXT` and `*CTEND` cards stamp
/// ([J 03.02.09]).
///
/// One serial counts every card of the deck, symbolic and binary alike,
/// and punches as decimal digits ending at column 80: the sample's
/// `*CTEXT` is card 15 and its `*CTEND` card 67, with 51 text cards
/// between them (LD-2). The `$LOAD` card and the end-of-file card are
/// not the compiler's ([J 03.01.02]).
///
/// The text section is the only binary section punched: no debugging
/// dictionary, no control break table, no file check table (D7.10).
JobDeck? jobDeck(JobCompilation job, ListingOptions options) {
  final CodegenResult? codegen = job.codegen;
  if (codegen == null || codegen.stopped) {
    return null;
  }
  final symbolic = <String>[];
  final cards = <CardImage>[];
  var serial = 0;
  void symbolicCard(String text) {
    serial++;
    final line = '${text.padRight(72)}${serial.toString().padLeft(8)}';
    symbolic.add(line);
    cards.add(mirrorToDeck('$line\n').single);
  }

  String bracket(String name) => textBracketCard(
    name,
    deckName: job.parse?.compileCard?.deckName ?? '',
    secondaryIdentifier: job.parse?.compileCard?.secondaryIdentifier ?? '',
    date: options.date,
    time: options.time,
  );
  codegen.controlCards.forEach(symbolicCard);
  symbolicCard(bracket('*CTEXT'));
  final entries = <({int word, int control})>[
    for (final AssemblyUnit unit in codegen.units)
      if (unit.word case final int word when unit.control != null)
        (word: word, control: unit.control!),
  ];
  for (var first = 0, sequence = 0; first < entries.length; sequence++) {
    final int last = math.min(first + textCardWords, entries.length);
    serial++;
    cards.add(
      binaryCard(
        textCard(sequence, entries.sublist(first, last)),
        serial: '$serial',
      ),
    );
    first = last;
  }
  symbolicCard(bracket('*CTEND'));
  return JobDeck(symbolicCards: symbolic, cards: cards);
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
