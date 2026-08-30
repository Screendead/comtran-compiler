/// The relative binary program deck (M4-16; LD-2): the card header and
/// checksum of [J 90.03.01], the control groups of [J 90.03.03], the
/// columnar binary card, and the sample's deck — 67 cards, the count
/// its `*CTEND` serial attests.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

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

  group('the 90.05 deck (J 03.01.02)', () {
    late JobDeck deck;

    setUpAll(() {
      deck = jobDeck(compileDeck(loadJobDeck()).jobs.single, _options)!;
    });

    test('punches 67 cards: 15 symbolic, 51 text, *CTEND', () {
      // The print attests the `*CTEXT` serial 15 and the `*CTEND`
      // serial 67 (PDF pp. 198, 216); 961 deck words at 19 a card are
      // the 51 between them.
      expect(deck.cards, hasLength(67));
      expect(deck.symbolicCards, hasLength(16));
      expect(deck.cardsBeforeText.last.substring(6, 12), '*CTEXT');
      expect(deck.cardsBeforeText.last, endsWith('15'));
      expect(deck.lastCard, endsWith('67'));
      expect(deck.lastCard.substring(6, 12), '*CTEND');
    });

    test('every text card is in format, in sequence, and checksummed', () {
      for (var i = 15; i < 66; i++) {
        final List<int> words = cardWords(deck.cards[i]);
        final int header = words[0];
        expect(isRelativeCardHeader(header), isTrue, reason: 'card ${i + 1}');
        expect(deckTypeOf(header), textDeckType);
        expect(sequenceOf(header), i - 15);
        final int count = wordCountOf(header);
        // The last card holds the 11 words past 50 full cards.
        expect(count, i < 65 ? 22 : 14);
        // The span the sum covers is LD-2's decision; the sum itself is
        // pinned above.
        expect(words[1], logicalSum([header, ...words.sublist(2, 2 + count)]));
        expect(
          unpackControlGroups(words.sublist(2, 5))[count - 3],
          0,
          reason: 'end of card',
        );
        final serial = '${i + 1}';
        for (final (int j, String digit) in serial.split('').indexed) {
          expect(
            deck.cards[i].punchesAt(81 - serial.length + j),
            punchesFromBcd(bcdFromGlyph(digit)!),
          );
        }
      }
    });

    test('the text opens with USE 1 and closes with the end-of-text entry', () {
      // The counter head comes first (M4-4): `USE 1` is `MON 01621`.
      final List<int> first = cardWords(deck.cards[15]);
      expect(_octalOf(first[5]), '500000001621');
      expect(unpackControlGroups(first.sublist(2, 5))[0], 1);
      final List<int> last = cardWords(deck.cards[65]);
      final int count = wordCountOf(last[0]);
      expect(_octalOf(last[1 + count]), '500000000165');
      expect(unpackControlGroups(last.sublist(2, 5))[count - 4], 0x0F);
    });

    test('the canon bytes reproduce the committed golden', () {
      expect(
        encodeCanon(deck.cards),
        File('test/goldens/90.05-payroll.deck').readAsBytesSync(),
      );
    });
  });
}
