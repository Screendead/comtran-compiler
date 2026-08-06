import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The 90.05 sample program survives twice: as the canon deck, keyed column
/// by column from the page scans, and as the manual conversion, transcribed
/// as text. This test holds the two consistent on the one thing both record
/// — the blank runs between the words of a card.
///
/// It is a regression gate. It is not evidence. Both artifacts derive from
/// one scanned copy of one manual, and the same reader settled the text in
/// each, so a green run shows that they agree and never that either is
/// right (`docs/opportunities.md`, O1).
const String _conversionPath =
    'comtran-manuals/J28-6169/90.05-sample-program.md';

/// The conversion pages that hold the source listing: printed listing pages
/// 1 to 6. PDF 198 onward is the generated-code listing, which no card of
/// the source deck produces.
const int _firstListingPage = 192;
const int _lastListingPage = 197;

/// Environment and Procedure cards in the deck. The Data Description cards
/// are out of scope: the listing prints those entries in its own fixed
/// columns, so a blank run there records the printer and not a punch
/// (`docs/design/m1-front-end.md`, M1-15).
const int _cardsInScope = 112;

/// Blank runs the two artifacts both attest. Raise this only with the
/// conversion edit that adds the words, and say which site in the commit
/// message.
const int _gapsInScope = 438;

/// The first column of an Environment card's options field. Columns 7–22
/// hold the name and 25–30 the type code, both padded to fixed columns by
/// the printer (definition §1.9.3; J 02.06.01).
const int _environmentOptionsColumn = 31;

/// The last column of a Procedure card's name margin (F p. 37). A word that
/// starts at or before it, and starts with a letter, is a margin name; the
/// printer pads the field, so the blank run that follows is not a punch.
const int _procedureMarginLast = 12;

typedef _Word = ({String text, int column});

/// The card's punched words, each with its 1-based start column.
List<_Word> _words(String line) => RegExp(r'\S+')
    .allMatches(line)
    .map((Match m) => (text: m.group(0)!, column: m.start + 1))
    .toList();

/// The blank run before each word after the first.
List<int> _gaps(List<_Word> words) => <int>[
  for (var i = 1; i < words.length; i++)
    words[i].column - (words[i - 1].column + words[i - 1].text.length),
];

/// One line per card, columns 1 to 80, for the whole canon deck.
List<String> _deckCardText() =>
    deckToMirror(loadPayrollDeck()).split('\n')
      ..removeWhere((String line) => line.isEmpty);

/// The lines of every fenced listing block on the source-listing pages.
List<String> _conversionListingLines() {
  final marker = RegExp(r'^<!-- 90\.05 listing \| PDF (\d+) -->$');
  final List<String> source = File(_conversionPath).readAsLinesSync();
  final lines = <String>[];
  for (var i = 0; i < source.length; i++) {
    final RegExpMatch? m = marker.firstMatch(source[i]);
    if (m == null) {
      continue;
    }
    final int page = int.parse(m.group(1)!);
    if (page < _firstListingPage || page > _lastListingPage) {
      continue;
    }
    var j = i;
    while (j < source.length && source[j] != '```') {
      j++;
    }
    for (j++; j < source.length && source[j] != '```'; j++) {
      lines.add(source[j]);
    }
  }
  return lines;
}

/// The punched part of a listing line: the statement number and the
/// sequence number dropped, and a generated name split off the first word.
///
/// A generated name fills the six columns of the name margin exactly, so
/// the printer sets it hard against text that starts in column 13 —
/// `GN)000CALL` is `GN)000` and then the punched `CALL`.
List<_Word>? _conversionBody(String line) {
  final List<_Word> words = _words(line);
  if (words.isEmpty) {
    return null;
  }
  var drop = 0;
  if (RegExp(r'^\d+,\d\d$').hasMatch(words[drop].text)) {
    drop++;
  }
  if (drop < words.length && RegExp(r'^7\d{4}$').hasMatch(words[drop].text)) {
    drop++;
  }
  final List<_Word> body = words.sublist(drop);
  if (body.isEmpty) {
    return null;
  }
  final RegExpMatch? glued = RegExp(
    r'^GN\)\d{3}(.+)$',
  ).firstMatch(body.first.text);
  if (glued == null) {
    return body;
  }
  final String punched = glued.group(1)!;
  return <_Word>[
    (
      text: punched,
      column: body.first.column + body.first.text.length - punched.length,
    ),
    ...body.skip(1),
  ];
}

final class _Comparison {
  int cardsMatched = 0;
  int gapsCompared = 0;
  final List<String> divergences = <String>[];
}

/// Matches every in-scope card to its listing line by word sequence, then
/// compares the blank runs that a punch decides.
///
/// Two conversion lines carry the same words as each other
/// (`GET MASTER, AT END DO END.OF.MASTERS.`, statements 189 and 194); the
/// match is still unambiguous, because their blank runs agree, and the
/// comparison rejects a duplicate whose runs do not.
_Comparison _compare(List<String> conversionLines) {
  final byWords = <String, List<List<_Word>>>{};
  for (final line in conversionLines) {
    final List<_Word>? body = _conversionBody(line);
    if (body != null) {
      byWords
          .putIfAbsent(body.map((_Word w) => w.text).join(' '), () => [])
          .add(body);
    }
  }

  final List<String> cards = _deckCardText();
  final int environmentAt = cards.indexWhere(
    (String c) => c.trim() == '*ENVIRONMENT',
  );
  final int procedureAt = cards.indexWhere(
    (String c) => c.trim() == '*PROCEDURE',
  );
  final result = _Comparison();

  for (int i = environmentAt + 1; i < cards.length; i++) {
    if (i == procedureAt) {
      continue;
    }
    // Column 72 carries the continuation flag, not text (D2.6).
    final List<_Word> card = _words(
      cards[i],
    ).where((_Word w) => !(w.text == 'X' && w.column == 72)).toList();
    if (card.isEmpty) {
      continue;
    }

    final String key = card.map((_Word w) => w.text).join(' ');
    final List<List<_Word>>? hits = byWords[key];
    if (hits == null) {
      result.divergences.add('card ${i + 1} matches no listing line: $key');
      continue;
    }
    final Set<String> runs = hits
        .map((List<_Word> h) => _gaps(h).join(','))
        .toSet();
    if (runs.length > 1) {
      result.divergences.add(
        'card ${i + 1} matches listing lines that disagree: $runs',
      );
      continue;
    }
    result.cardsMatched++;

    final List<int> deckGaps = _gaps(card);
    final List<int> conversionGaps = _gaps(hits.first);
    final bool isEnvironment = i < procedureAt;
    var first = 0;
    if (isEnvironment) {
      while (first + 1 < card.length &&
          card[first].column + card[first].text.length <
              _environmentOptionsColumn) {
        first++;
      }
    } else if (card.first.column <= _procedureMarginLast &&
        RegExp('^[A-Z]').hasMatch(card.first.text)) {
      first = 1;
    }

    for (var g = first; g < deckGaps.length; g++) {
      result.gapsCompared++;
      if (deckGaps[g] != conversionGaps[g]) {
        result.divergences.add(
          'card ${i + 1}, before "${card[g + 1].text}": '
          'the deck punches ${deckGaps[g]} blanks and the conversion '
          'holds ${conversionGaps[g]} — ${cards[i].trimRight()}',
        );
      }
    }
  }
  return result;
}

void main() {
  group('the 90.05 deck against the manual conversion', () {
    late _Comparison result;

    setUpAll(() => result = _compare(_conversionListingLines()));

    test('every Environment and Procedure card reaches a listing line', () {
      expect(result.cardsMatched, _cardsInScope);
    });

    test('the two artifacts agree on every punched blank run', () {
      expect(result.divergences, isEmpty);
      expect(result.gapsCompared, _gapsInScope);
    });

    test('a squeezed blank run in the conversion fails the comparison', () {
      // The error this comparison found on 2026-08-05: the print and the
      // deck hold two blanks after `ERRORTYPE,` in statement 193 and the
      // conversion held one (`90.05-payroll-deck-notes.md`, item 4).
      final List<String> squeezed = _conversionListingLines()
          .map(
            (String l) => l.replaceAll('ERRORTYPE,  MOVE', 'ERRORTYPE, MOVE'),
          )
          .toList();
      final _Comparison regressed = _compare(squeezed);
      expect(regressed.divergences, hasLength(1));
      expect(regressed.divergences.single, contains('the deck punches 2'));
      expect(regressed.divergences.single, contains('the conversion holds 1'));
    });
  });
}
