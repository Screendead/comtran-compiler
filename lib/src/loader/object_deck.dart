/// The relative binary program deck ([J 90.03]; M4-16; LD-2): the
/// columnar binary card, the text card's header, checksum and control
/// groups, and the deck of one job — the symbolic control cards, then
/// `*CTEXT`, the text section, `*CTEND`.
///
/// The text section is the only binary section punched: no debugging
/// dictionary, no control break table, no file check table (D7.10).
library;

import 'dart:math' as math;

import '../cards/card_image.dart';
import '../cards/text_codec.dart';
import '../chars/char_code.dart';
import '../codegen/codegen.dart';
import '../codegen/control_cards.dart';
import '../codegen/text_model.dart';
import '../emulator/word.dart';

/// Data words per text card ([J 90.03.03]): the count the `*CTEND`
/// serial attests, 51 cards for the sample's 961 words.
const int textCardWords = 19;

/// The deck type of a text card, word 1 bits 5 to 7 ([J 90.03.01]).
const int textDeckType = 4;

/// Word 1 of a binary card ([J 90.03.01]): the relative-deck mark in
/// positions S and 1, the checksum-control bit clear, the Commercial
/// Translator bit, the deck type, the `01010` mark, the word count from
/// word 3, and the card's sequence in its section.
int cardHeader({
  required int deckType,
  required int count,
  required int sequence,
}) =>
    (3 << 34) |
    (1 << 32) |
    (deckType << 28) |
    (0x0A << 23) |
    (count << 18) |
    (sequence & Word36.fieldMask15);

/// Whether [header] carries the fixed marks of [J 90.03.01]: the
/// relative-deck indicator, the Commercial Translator bit, and `01010`.
bool isRelativeCardHeader(int header) =>
    (header >> 34) & 3 == 3 &&
    (header >> 32) & 1 == 1 &&
    (header >> 23) & 0x1F == 0x0A;

/// Word 1 bit 2: set when the loader is not to verify the checksum.
bool skipsChecksum(int header) => (header >> 33) & 1 == 1;

/// Word 1 bits 5 to 7.
int deckTypeOf(int header) => (header >> 28) & 7;

/// Word 1 bits 13 to 17: the words from word 3 on.
int wordCountOf(int header) => (header >> 18) & 0x1F;

/// Word 1 bits 21 to 35.
int sequenceOf(int header) => header & Word36.fieldMask15;

/// The logical sum of [words] ([J 90.03.01] word 2): 36-bit addition
/// with the carry out of position S returned to position 35, the
/// `ACL` rule. The sum covers word 1 and every word from word 3 to the
/// last the count names, control words included (LD-2).
int logicalSum(Iterable<int> words) {
  var sum = 0;
  for (final word in words) {
    sum += word;
    if (sum > Word36.wordMask) {
      sum = (sum & Word36.wordMask) + 1;
    }
  }
  return sum;
}

/// Groups per control word: seven five-bit groups below the unused sign.
const int _groupsPerWord = 7;

/// Words 3 to 5 of a text card: [groups] packed seven to a word from
/// position 1 down, the sign bits unused ([J 90.03.03]).
List<int> packControlGroups(List<int> groups) => [
  for (var w = 0; w < 3; w++)
    [
      for (var g = 0; g < _groupsPerWord; g++)
        if (w * _groupsPerWord + g < groups.length)
          groups[w * _groupsPerWord + g] << (30 - 5 * g),
    ].fold(0, (int word, int field) => word | field),
];

/// The twenty-one groups of control words [words].
List<int> unpackControlGroups(List<int> words) => [
  for (final int word in words)
    for (var g = 0; g < _groupsPerWord; g++) (word >> (30 - 5 * g)) & 0x1F,
];

/// The twenty-four words of text card [sequence] holding [entries]: the
/// header, the checksum, three control words, the data words, and zero
/// words to the end of the card. An `00000` end-of-card group follows
/// the last data word's group ([J 90.03.04]).
List<int> textCard(int sequence, List<({int word, int control})> entries) {
  assert(
    entries.isNotEmpty && entries.length <= textCardWords,
    'a text card holds 1 to $textCardWords words',
  );
  final List<int> controls = packControlGroups([
    for (final entry in entries) entry.control,
    0,
  ]);
  final data = <int>[for (final entry in entries) entry.word];
  final int header = cardHeader(
    deckType: textDeckType,
    count: controls.length + data.length,
    sequence: sequence,
  );
  return [
    header,
    logicalSum([header, ...controls, ...data]),
    ...controls,
    ...data,
    ...List<int>.filled(textCardWords - data.length, 0),
  ];
}

/// [words] punched three columns a word from column 1, position S in
/// row 12 of a word's first column (`docs/design/deck-format.md`
/// section 2.3), and [serial] as digits ending at column 80 (LD-2).
CardImage binaryCard(List<int> words, {String serial = ''}) {
  final columns = List<int>.filled(CardImage.columnCount, 0);
  for (final (int i, int word) in words.indexed) {
    columns[3 * i] = (word >> 24) & 0xFFF;
    columns[3 * i + 1] = (word >> 12) & 0xFFF;
    columns[3 * i + 2] = word & 0xFFF;
  }
  for (final (int i, String digit) in serial.split('').indexed) {
    columns[CardImage.columnCount - serial.length + i] = punchesFromBcd(
      bcdFromGlyph(digit)!,
    )!;
  }
  return CardImage.fromColumns(columns);
}

/// The twenty-four words of columns 1 to 72 of [card].
List<int> cardWords(CardImage card) => [
  for (var i = 0; i < 24; i++)
    (card.punchesAt(3 * i + 1) << 24) |
        (card.punchesAt(3 * i + 2) << 12) |
        card.punchesAt(3 * i + 3),
];

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

/// The deck of [codegen]: the control cards, `*CTEXT`, the text
/// section at [textCardWords] words a card, `*CTEND` ([J 03.01.02]).
///
/// One serial counts every card of the deck, symbolic and binary alike,
/// and punches as decimal digits ending at column 80: the sample's
/// `*CTEXT` is card 15 and its `*CTEND` card 67, with 51 text cards
/// between them (LD-2). The `$LOAD` card and the end-of-file card are
/// not the compiler's ([J 03.01.02]).
JobDeck objectDeck(
  CodegenResult codegen, {
  required String deckName,
  required String secondaryIdentifier,
  required String date,
  required String time,
}) {
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
    deckName: deckName,
    secondaryIdentifier: secondaryIdentifier,
    date: date,
    time: time,
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
