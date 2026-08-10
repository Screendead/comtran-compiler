/// The compiler behind the public website (roadmap W1, `docs/HANDOVER.md`).
///
/// The site holds no compiler knowledge. It hands this library the text a
/// reader typed and prints what comes back, so a later milestone fills the
/// site's panels with no website work.
///
/// Two jobs live here. [punchText] turns keyboard text into the mirror
/// normal form `mirrorToDeck` demands (D0.5). [compileText] then runs the
/// same driver and the same six stage dumps `bin/comtranc.dart` runs, and
/// reports a refusal in the site's own words rather than an exception.
library;

import '../cards/card_image.dart';
import '../cards/text_codec.dart';
import '../driver/driver.dart';
import '../emit/emit_code.dart';
import '../emit/emit_parse.dart';
import '../emit/emit_scan.dart';
import '../emit/emit_semantics.dart';
import '../lexer/diagnostic.dart';
import '../listing/listing.dart';

/// The page head every browser run prints.
///
/// The values are the sample listing's own (J 90.05, PDF p. 192), not the
/// reader's clock: a fixed head keeps one program's listing identical from
/// run to run and from reader to reader, which is what makes the byte
/// comparison against `test/goldens/90.05-payroll.listing` meaningful in a
/// browser.
const ListingOptions webListingOptions = ListingOptions(
  date: '10/18/61',
  time: '2.45',
  title: 'COMPILATION OF SAMPLE PROBLEM',
);

/// One browser compilation: the six stage dumps, or a refusal.
///
/// [error] is non-null exactly when the deck never reached the driver. A
/// program the compiler rejected is not an error of this kind — it compiles,
/// and its diagnostics print in [listing].
final class WebCompilation {
  const WebCompilation({
    required this.cards,
    required this.scan,
    required this.parse,
    required this.semantics,
    required this.listing,
    required this.code,
    required this.cardCount,
    required this.diagnosticCount,
    required this.maxSeverity,
  }) : error = null;

  /// A deck the site could not punch, described for the reader.
  const WebCompilation.refused(String this.error)
    : cards = '',
      scan = '',
      parse = '',
      semantics = '',
      listing = '',
      code = '',
      cardCount = 0,
      diagnosticCount = 0,
      maxSeverity = 0;

  final String? error;

  /// The deck in mirror form — the `--emit-cards` dump.
  final String cards;

  /// The `--emit-scan` dump: the front end's statements.
  final String scan;

  /// The `--emit-parse` dump: the parse tree.
  final String parse;

  /// The `--emit-semantics` dump: storage, dictionary, and resolutions.
  final String semantics;

  /// The compilation listing, one page sequence per job.
  final String listing;

  /// The `--emit-code` dump: the assembly text model.
  final String code;

  final int cardCount;
  final int diagnosticCount;

  /// The worst severity on the deck (D11.2); 5 stopped a job.
  final int maxSeverity;

  /// The shape the browser reads. The keys are the stage names
  /// `--emit-<stage>` uses, so the site names its panels after the flags.
  Map<String, Object?> toJson() => {
    'error': error,
    'cards': cards,
    'scan': scan,
    'parse': parse,
    'semantics': semantics,
    'code': code,
    'listing': listing,
    'cardCount': cardCount,
    'diagnosticCount': diagnosticCount,
    'maxSeverity': maxSeverity,
  };
}

/// Turns typed text into mirror normal form (`docs/design/deck-format.md`
/// §3.3), which is stricter than anything a text area produces.
///
/// Four differences matter. A browser may send CRLF; the punch has no
/// carriage return. A text area rarely ends in a newline; the mirror always
/// does. Trailing blanks are invisible to the typist and fail the normal-form
/// re-render. The 1962 source set has no lower-case letter (D0.6), so lower
/// case is punched as upper case rather than refused.
///
/// A tab is left in place. Expanding one would move a card column silently,
/// and column position carries meaning on every card.
String punchText(String typed) {
  final List<String> lines = typed
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .toUpperCase()
      .split('\n');
  // A trailing blank card is what the return key at the end of typing
  // leaves behind, never something a reader meant to punch.
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  final buffer = StringBuffer();
  for (final line in lines) {
    buffer
      ..write(line.trimRight())
      ..write('\n');
  }
  return buffer.toString();
}

/// Compiles [typed] and renders every stage the compiler reached.
WebCompilation compileText(String typed) {
  final String mirror = punchText(typed);
  if (mirror.isEmpty) {
    return const WebCompilation.refused(
      'There is no program to compile. Type a program, or load the sample.',
    );
  }
  final List<String> lines = mirror.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('\t')) {
      return WebCompilation.refused(
        'Card ${i + 1} contains a tab. A card has eighty columns and the '
        'punch has no tab key, so type spaces to reach a column.',
      );
    }
  }
  final List<CardImage> deck;
  try {
    deck = mirrorToDeck(mirror);
  } on FormatException catch (e) {
    return WebCompilation.refused(
      '${_sentence(e.message)} Fix that card and compile again.',
    );
  }
  final DeckCompilation compilation;
  try {
    compilation = compileDeck(deck);
  } on StopCompilation {
    // Every phase catches its own stop and returns a partial result. This
    // net keeps a stop from any future phase off the reader's screen
    // (D9.1's job rule: stop, go to the next job).
    return const WebCompilation.refused(
      'The compiler stopped and printed nothing. This is a fault in the '
      'reconstruction, not in the program.',
    );
  }
  final listing = StringBuffer();
  var diagnosticCount = 0;
  for (final JobCompilation job in compilation.jobs) {
    listing.write(
      writeListing(
        job.frontEnd,
        webListingOptions,
        diagnostics: job.diagnostics,
        annotations: job.semantics?.allocation?.annotations,
      ),
    );
    diagnosticCount += job.diagnostics.length;
  }
  return WebCompilation(
    cards: deckToMirror(deck),
    scan: emitScan(compilation),
    parse: emitParse(compilation),
    semantics: emitSemantics(compilation),
    listing: listing.toString(),
    code: emitCode(compilation),
    cardCount: deck.length,
    diagnosticCount: diagnosticCount,
    maxSeverity: compilation.maxSeverity,
  );
}

/// Capitalizes a codec message and closes it with a full stop, so it reads
/// as one sentence of the site's own prose.
String _sentence(String message) {
  final String text = message[0].toUpperCase() + message.substring(1);
  return text.endsWith('.') ? text : '$text.';
}
