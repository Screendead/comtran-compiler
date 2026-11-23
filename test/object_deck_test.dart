/// The relative binary program deck (M4-16; LD-2): the card header and
/// checksum of [J 90.03.01], the control groups of [J 90.03.03], the
/// columnar binary card, and the deck name a `$CMPLE` card gives.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

int _octal(String digits) => int.parse(digits, radix: 8);

String _octalOf(int word) => word.toRadixString(8).padLeft(12, '0');

const ListingOptions _options = ListingOptions(date: '10/18/61', time: '2.45');

void main() {
  group('the binary card (J 90.03.01)', () {
    test('word 1 carries the marks, the type, the count and the sequence', () {
      // S,1 = 11; bit 3 = 1; bits 5-7 = 100 text; bits 8-12 = 01010;
      // bits 13-17 = 22, the "22 word" card; bits 21-35 = 0.
      final int header = cardHeader(deckType: 4, count: 22, sequence: 0);
      expect(_octalOf(header), '650526000000');
      expect(isRelativeCardHeader(header), isTrue);
      expect(skipsChecksum(header), isFalse);
      expect(deckTypeOf(header), 4);
      expect(wordCountOf(header), 22);
      expect(sequenceOf(cardHeader(deckType: 4, count: 5, sequence: 50)), 50);
      expect(isRelativeCardHeader(_octal('250526000000')), isFalse);
      expect(skipsChecksum(_octal('750526000000')), isTrue);
    });

    test('the checksum is the logical sum, carry end-around', () {
      expect(logicalSum([_octal('777777777777'), 1]), 1);
      expect(
        logicalSum([_octal('777777777777'), _octal('777777777777')]),
        _octal('777777777777'),
      );
      expect(logicalSum([3, 4]), 7);
    });

    test('control groups pack seven to a word from position 1', () {
      final groups = <int>[0x10, 0x11, 1, 0x0F, 0x12, 0x15, 0x19, 0x1A];
      final List<int> words = packControlGroups(groups);
      expect(words, hasLength(3));
      expect(_octalOf(packControlGroups([0x10])[0]), '200000000000');
      expect(unpackControlGroups(words), [
        ...groups,
        ...List<int>.filled(13, 0),
      ]);
    });

    test('a word punches three columns, S in row 12 of the first', () {
      final CardImage card = binaryCard([
        _octal('650526000000'),
        _octal('000000000001'),
      ], serial: '16');
      expect(card.punchesAt(1), _octal('6505'));
      expect(card.punchesAt(3), 0);
      expect(card.punchesAt(6), 1);
      expect(cardWords(card).take(2), [
        _octal('650526000000'),
        _octal('000000000001'),
      ]);
      expect(card.punchesAt(79), punchesFromBcd(bcdFromGlyph('1')!));
      expect(card.punchesAt(80), punchesFromBcd(bcdFromGlyph('6')!));
    });

    test('a text card holds its words with a group each and a terminator', () {
      final List<int> words = textCard(3, [
        (word: _octal('500000000000'), control: 1),
        (word: _octal('044100001744'), control: 0x11),
      ]);
      expect(words, hasLength(24));
      expect(wordCountOf(words[0]), 5);
      expect(sequenceOf(words[0]), 3);
      expect(unpackControlGroups(words.sublist(2, 5)).take(3), [1, 0x11, 0]);
      expect(words.sublist(5, 7), [
        _octal('500000000000'),
        _octal('044100001744'),
      ]);
      expect(words[1], logicalSum([words[0], ...words.sublist(2, 7)]));
      expect(words.sublist(7), everyElement(0));
    });
  });

  test(r'a $CMPLE deck punches its deck name in columns 73 to 77', () {
    // "The deck identification comes from columns 8 through 12 of the
    // $CMPLE card", and the sequence number takes 78 to 80
    // ([J 05.05] A). No sample program has a $CMPLE card.
    final lines = <String>[
      r'$CMPLE SAMPLE',
      '      *PROCEDURE',
      '            STOP RUN.',
      '      *FINISH',
    ];
    final JobDeck deck = jobDeck(
      compileDeck(mirrorToDeck('${lines.join('\n')}\n')).jobs.single,
      _options,
    )!;
    expect(deck.cards.length, greaterThan(2));
    for (final (int i, CardImage card) in deck.cards.indexed) {
      final String columns = [
        for (var column = 73; column <= 80; column++)
          glyphFromBcd(bcdFromPunches(card.punchesAt(column))!),
      ].join();
      expect(columns, 'SAMPL${'${i + 1}'.padLeft(3)}');
    }
  });
}
