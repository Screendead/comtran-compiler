/// The compiler behind the public website (roadmap W1, `docs/HANDOVER.md`).
///
/// The site holds no compiler knowledge. It hands this library the text a
/// reader typed and prints what comes back, so a later milestone fills the
/// site's panels with no website work.
///
/// [punchText] turns keyboard text into the mirror normal form
/// `mirrorToDeck` demands (D0.5). [compileText] then runs the same driver
/// and the same six stage dumps `bin/comtranc.dart` runs, and reports a
/// refusal in the site's own words rather than an exception. [punchCard]
/// and [togglePunch] serve the card view, which reads and cuts one card's
/// holes. [canonDeck] hands the reader the deck itself, to take away.
library;

import 'dart:typed_data';

import '../cards/canon_codec.dart';
import '../cards/card_image.dart';
import '../cards/text_codec.dart';
import '../chars/char_code.dart';
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

/// One row of the compiler's diagnostic block, in the listing's own words.
///
/// The site never writes a diagnostic of its own and never rewrites one of
/// these (`docs/design/web-copy.md`, rules E1 and F2).
final class WebDiagnostic {
  const WebDiagnostic(this.number, this.severity, this.text);

  /// The statement number the listing prints in its NUMBER column.
  final String number;

  /// The D9.2 severity; 5 stopped the job.
  final int severity;

  /// The message text with its operands substituted.
  final String text;

  Map<String, Object?> toJson() => {
    'number': number,
    'severity': severity,
    'text': text,
  };
}

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
    required this.diagnostics,
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
      diagnostics = const [],
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

  /// Every diagnostic the deck drew, in the listing's order.
  final List<WebDiagnostic> diagnostics;

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
    'diagnostics': [for (final WebDiagnostic d in diagnostics) d.toJson()],
    'maxSeverity': maxSeverity,
  };
}

/// The twelve punch rows of a card, in the order the card prints them.
///
/// A card reads 12 and 11 at the top, then 0, then 1 to 9 (J 02.03.01). The
/// site never learns this order: it prints the rows it is handed.
final List<int> _rowBits = [
  rowBit12,
  rowBit11,
  rowBit0,
  for (var digit = 1; digit <= 9; digit++) rowBitDigit(digit),
];

/// One card as the punch cut it, for the card view.
final class WebCard {
  const WebCard(this.line, this.rows, this.glyphs);

  /// The card's own mirror text (D0.5). A card every column of which
  /// carries a source-set character is a glyph line; any other card is a
  /// `!` punch line, which is what a hand-punched hole with no character
  /// against it produces.
  final String line;

  /// Twelve strings of eighty characters, `#` for a hole and `.` for solid
  /// card, in the row order [_rowBits] documents.
  final List<String> rows;

  /// The eighty characters printed along the top of the card, blanks
  /// included — what the keypunch prints above the holes it cuts. A column
  /// no character matches prints a blank.
  final String glyphs;

  Map<String, Object?> toJson() => {
    'line': line,
    'rows': rows,
    'glyphs': glyphs,
  };
}

/// Punches one line of typed text as one card, or returns null when the
/// punch could not cut it. A blank line is a blank card, not a failure.
WebCard? punchCard(String typed) {
  final CardImage? card = _cardFrom(typed);
  return card == null ? null : _render(card);
}

/// Cuts or fills one hole and returns the card that results, so that a
/// reader can punch a card by hand and read the text it becomes.
///
/// [row] indexes [_rowBits] — 0 is row 12, 1 is row 11, 2 is row 0, and 3
/// to 11 are the digit rows. [column] is 1-based.
WebCard? togglePunch(String typed, int row, int column) {
  final CardImage? card = _cardFrom(typed);
  if (card == null || row < 0 || row >= _rowBits.length) {
    return null;
  }
  if (column < 1 || column > CardImage.columnCount) {
    return null;
  }
  final List<int> columns = [
    for (var c = 1; c <= CardImage.columnCount; c++) card.punchesAt(c),
  ];
  columns[column - 1] ^= _rowBits[row];
  return _render(CardImage.fromColumns(columns));
}

/// Reads one line of typed text as one card.
CardImage? _cardFrom(String typed) {
  // A punch line is already in the punch's own alphabet, and upper-casing
  // it would corrupt nothing but reading it as typed text would.
  final String first = typed.split('\n').first;
  final String line = first.startsWith('!')
      ? first.trimRight()
      : punchText(first).split('\n').firstOrNull ?? '';
  if (line.contains('\t')) {
    return null;
  }
  try {
    return mirrorToDeck('$line\n').single;
  } on FormatException {
    return null;
  }
}

WebCard _render(CardImage card) {
  final rows = <String>[];
  for (final int bit in _rowBits) {
    final row = StringBuffer();
    for (var column = 1; column <= CardImage.columnCount; column++) {
      row.write(card.punchesAt(column) & bit == 0 ? '.' : '#');
    }
    rows.add(row.toString());
  }
  final glyphs = StringBuffer();
  for (var column = 1; column <= CardImage.columnCount; column++) {
    final int punches = card.punchesAt(column);
    final int? bcd = isGlyphColumn(punches) ? bcdFromPunches(punches) : null;
    glyphs.write(bcd == null ? ' ' : glyphFromBcd(bcd) ?? ' ');
  }
  return WebCard(deckToMirror([card]).trimRight(), rows, glyphs.toString());
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

/// The typed deck as canon bytes, or null when the punch could not cut a
/// card of it.
///
/// The canon file is the deck (D0.5), so a reader who saves one holds what
/// `deckconv`, the compiler and the editor all read. The site encodes
/// nothing itself.
Uint8List? canonDeck(String typed) {
  final String mirror = punchText(typed);
  if (mirror.isEmpty) {
    return null;
  }
  try {
    return encodeCanon(mirrorToDeck(mirror));
  } on FormatException {
    return null;
  }
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
  final diagnostics = <WebDiagnostic>[];
  for (final JobCompilation job in compilation.jobs) {
    listing.write(
      writeListing(
        job.frontEnd,
        webListingOptions,
        diagnostics: job.diagnostics,
        annotations: job.semantics?.allocation?.annotations,
      ).text,
    );
    for (final Diagnostic d in job.diagnostics) {
      diagnostics.add(
        WebDiagnostic(
          diagnosticStatementNumber(job.frontEnd, d),
          d.severity,
          d.text,
        ),
      );
    }
  }
  return WebCompilation(
    cards: deckToMirror(deck),
    scan: emitScan(compilation),
    parse: emitParse(compilation),
    semantics: emitSemantics(compilation),
    listing: listing.toString(),
    code: emitCode(compilation),
    cardCount: deck.length,
    diagnostics: diagnostics,
    maxSeverity: compilation.maxSeverity,
  );
}

/// Capitalizes a codec message and closes it with a full stop, so it reads
/// as one sentence of the site's own prose.
String _sentence(String message) {
  final String text = message[0].toUpperCase() + message.substring(1);
  return text.endsWith('.') ? text : '$text.';
}
