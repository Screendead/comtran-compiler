/// Our CT Loader (D0.3; M4-16; LD-3): the round trip — emit the 90.05
/// deck, load it, compare memory against the listing's word image — at
/// relative location zero and at a chosen origin, and every deck the
/// loader refuses.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

int _octal(String digits) => int.parse(digits, radix: 8);

const ListingOptions _options = ListingOptions(date: '10/18/61', time: '2.45');

/// The raw 15-bit code, so a loaded word at origin zero is the listing's.
int _raw(SystemReference reference) => reference.code;

/// System routines at 70000 octal, file blocks at 60000 octal.
int _table(SystemReference reference) =>
    (reference.file ? _octal('60000') : _octal('70000')) + reference.number;

List<CardImage> _symbolic(List<String> lines) =>
    mirrorToDeck('${lines.join('\n')}\n');

CardImage _text(int sequence, List<({int word, int control})> entries) =>
    binaryCard(textCard(sequence, entries));

/// The end-of-text entry with the entry point at relative zero.
final ({int word, int control}) _endOfText = (
  word: counterWord(CounterOp.relativeOrigin, 0),
  control: ControlGroup.endOfText,
);

/// A one-word program: `OCT 7` at relative 0, entry 0.
final List<CardImage> _minimal = [
  ..._symbolic(['      *CTEXT']),
  _text(0, [(word: 7, control: ControlGroup.constantWord), _endOfText]),
  ..._symbolic(['      *CTEND']),
];

Matcher _loadError(String fragment) => throwsA(
  isA<LoadError>().having(
    (LoadError e) => e.message,
    'message',
    contains(fragment),
  ),
);

void main() {
  group('the 90.05 round trip', () {
    late JobCompilation job;
    late JobDeck deck;

    setUpAll(() {
      job = compileDeck(loadJobDeck()).jobs.single;
      deck = jobDeck(job, _options)!;
    });

    test("at origin zero memory is the listing's word image", () {
      final LoadedProgram program = loadDeck(deck.cards, resolve: _raw);
      final image = <int, int>{
        for (final AssemblyUnit unit in job.codegen!.units)
          if (unit.control case final int control
              when control >= ControlGroup.constantWord)
            unit.location!: unit.word!,
      };
      expect(program.words, image);
      expect(program.words, hasLength(936));
      expect(program.entry, _octal('165'));
      expect(program.origin, 0);
      expect(program.deckName, '');
      expect(program.cardsRead, 67);
    });

    test('at another origin the relative fields move and the system '
        'references resolve', () {
      final int origin = _octal('10000');
      final LoadedProgram program = loadDeck(
        deck.cards,
        origin: origin,
        resolve: _table,
      );
      expect(program.entry, _octal('10165'));
      // LOC 00167 `LDI CP)+40`, control 10001: the address relocates.
      expect(program.words[_octal('10167')], _octal('044100011744'));
      // LOC 00177 `TXH CP)+14,0,CP)+15`, control 10101: both fields.
      expect(program.words[_octal('10177')], _octal('311713011712'));
      // LOC 00165 `TSX SYS)175,4`, control 10010: the table's address.
      expect(program.words[_octal('10165')], _octal('007400470257'));
      // LOC 00201 `PZE INPUTMASTER,,SYS)260`, control 11010: a file
      // reference in the address, a system reference in the decrement.
      expect(program.words[_octal('10201')], _octal('070404060001'));
      // LOC 00274 `PZE ERRORFILE,,0`: file 7.
      expect(program.words[_octal('10274')], _octal('000000060007'));
      // The pointer words under `ORG BL)1`: `PZE IOC)29` at 01666.
      expect(program.words[_octal('11666')], _octal('70035'));
      expect(program.words[_octal('11667')], 0);
    });

    test('reads the *FILE and *SPEC cards', () {
      final LoadedProgram program = loadDeck(deck.cards, resolve: _raw);
      expect(program.files, hasLength(7));
      final LoaderFile first = program.files.first;
      expect(first.number, 1);
      expect(first.name, 'INPUTMASTER');
      expect(first.type, 'I');
      expect(first.mode, 'B');
      expect(first.density, 'H');
      expect(first.unit1, 'D1');
      expect(first.unit2, '');
      expect(first.blocksize, 300);
      expect(first.open, 'N');
      expect(first.close, 'R');
      final LoaderFile detail = program.files[2];
      expect(detail.name, 'DETAILFILE');
      expect(detail.mode, 'D');
      expect(detail.density, 'L');
      expect(detail.blocksize, 3);
    });

    test('a second deck loads from the card after *CTEND', () {
      final List<CardImage> two = [...deck.cards, ..._minimal];
      final LoadedProgram first = loadDeck(two, resolve: _raw);
      final LoadedProgram second = loadDeck(
        two.sublist(first.cardsRead),
        resolve: _raw,
      );
      expect(second.words, {0: 7});
      expect(second.entry, 0);
      expect(second.cardsRead, 3);
    });
  });

  group('the control groups (J 90.03.04)', () {
    test('an absolute origin, a relative origin and a reservation', () {
      final LoadedProgram program = loadDeck(
        [
          ..._symbolic(['      *CTEXT']),
          _text(0, [
            (
              word: counterWord(CounterOp.relativeOrigin, 2),
              control: ControlGroup.locationCounter,
            ),
            (word: 1, control: ControlGroup.constantWord),
            (
              word: counterWord(CounterOp.fixedReservation, 3),
              control: ControlGroup.locationCounter,
            ),
            (word: 2, control: ControlGroup.constantWord),
            (word: counterWord(0, 40), control: ControlGroup.locationCounter),
            (word: 3, control: ControlGroup.constantWord),
            _endOfText,
          ]),
          ..._symbolic(['      *CTEND']),
        ],
        origin: 100,
        resolve: _raw,
      );
      expect(program.words, {102: 1, 106: 2, 40: 3});
      expect(program.entry, 100);
    });

    test('a *SPEC card without its *FILE card is ignored (J 03.02.05)', () {
      final LoadedProgram program = loadDeck([
        ..._symbolic([
          '      *FILE  01 *         I HD                       INF',
          '      *SPEC  02  300    N R',
          'OTHER *SPEC  01  300    N R',
          '      *CTEXT',
        ]),
        _text(0, [(word: 7, control: ControlGroup.constantWord), _endOfText]),
        ..._symbolic(['      *CTEND']),
      ], resolve: _raw);
      expect(program.files.single.blocksize, isNull);
    });
  });

  group('the decks the loader refuses', () {
    test('a control card the compiler never punches', () {
      expect(
        () => loadDeck(_symbolic(['      *POOL  01']), resolve: _raw),
        _loadError('unsupported control card *POOL'),
      );
    });

    test('a deck.name with an imbedded blank (D7.11; J 90.01.05)', () {
      expect(
        () => loadDeck([
          ..._symbolic(['A B   *CTEXT']),
          ..._minimal.sublist(1),
        ], resolve: _raw),
        _loadError('imbedded blank'),
      );
    });

    test('a binary card before *CTEXT, and none after it', () {
      expect(
        () => loadDeck(_minimal.sublist(1), resolve: _raw),
        _loadError('no *CTEXT card'),
      );
      expect(
        () => loadDeck(_minimal.sublist(0, 1), resolve: _raw),
        _loadError('ends without an end-of-text entry'),
      );
      expect(
        () => loadDeck(_minimal.sublist(0, 2), resolve: _raw),
        _loadError('*CTEND does not follow'),
      );
    });

    test('a card out of format, out of sequence, or miscounted', () {
      List<CardImage> deck(CardImage card) => [
        _minimal.first,
        card,
        _minimal.last,
      ];
      expect(
        () => loadDeck(deck(_minimal.first), resolve: _raw),
        _loadError('a symbolic card inside the text'),
      );
      // A card that is binary but not relative: S,1 = 01.
      expect(
        () =>
            loadDeck(deck(binaryCard([_octal('250526000000')])), resolve: _raw),
        _loadError('not a relative binary card'),
      );
      expect(
        () => loadDeck(
          deck(
            _text(1, [
              (word: 7, control: ControlGroup.constantWord),
              _endOfText,
            ]),
          ),
          resolve: _raw,
        ),
        _loadError('sequence 1 where 0 is due'),
      );
      final List<int> words = cardWords(_minimal[1]);
      expect(
        () => loadDeck(deck(binaryCard([...words]..[1] += 1)), resolve: _raw),
        _loadError('checksum fails'),
      );
      // Bit 2 of word 1 waives the check.
      final unchecked = [...words]..[1] += 1;
      unchecked[0] |= 1 << 33;
      expect(loadDeck(deck(binaryCard(unchecked)), resolve: _raw).words, {
        0: 7,
      });
      final table = [...words];
      table[0] = cardHeader(deckType: 3, count: 5, sequence: 0);
      table[1] = logicalSum([table[0], ...table.sublist(2, 7)]);
      expect(
        () => loadDeck(deck(binaryCard(table)), resolve: _raw),
        _loadError('deck type 011 is not text'),
      );
      final short = [...words];
      short[0] = cardHeader(deckType: 4, count: 3, sequence: 0);
      short[1] = logicalSum([short[0], ...short.sublist(2, 5)]);
      expect(
        () => loadDeck(deck(binaryCard(short)), resolve: _raw),
        _loadError('word count 3'),
      );
      // The end-of-card group inside the count, and none after it.
      final List<int> cut = textCard(0, [
        (word: 7, control: ControlGroup.constantWord),
      ]);
      cut[0] = cardHeader(deckType: 4, count: 5, sequence: 0);
      cut[1] = logicalSum([cut[0], ...cut.sublist(2, 7)]);
      expect(
        () => loadDeck(deck(binaryCard(cut)), resolve: _raw),
        _loadError('end of card before its 2 words'),
      );
      final List<int> unterminated = textCard(0, [
        (word: 7, control: ControlGroup.constantWord),
      ]);
      unterminated[2] |= 0x10 << 25;
      unterminated[1] = logicalSum([
        unterminated[0],
        ...unterminated.sublist(2, 6),
      ]);
      expect(
        () => loadDeck(deck(binaryCard(unterminated)), resolve: _raw),
        _loadError('no end-of-card group after word 1'),
      );
    });

    test('a group or a field the compiler never punches', () {
      void refuses(
        ({int word, int control}) entry,
        String fragment, {
        int origin = 0,
      }) {
        expect(
          () => loadDeck(
            [
              _minimal.first,
              _text(0, [entry, _endOfText]),
              _minimal.last,
            ],
            origin: origin,
            resolve: _raw,
          ),
          _loadError(fragment),
          reason: fragment,
        );
      }

      refuses((
        word: counterWord(3, 5),
        control: ControlGroup.locationCounter,
      ), 'variable-length reservation');
      refuses((
        word: counterWord(1, 5),
        control: ControlGroup.locationCounter,
      ), 'location counter control prefix 1');
      refuses((word: 0, control: 0x02), 'control group 00010');
      refuses((word: 0, control: 0x0E), 'control group 01110');
      refuses((word: 0, control: 0x13), 'complex expression');
      refuses((word: 0x1000, control: 0x12), 'system reference type 10');
      refuses((word: 0x7FFF, control: 0x11), 'outside core', origin: 1);
    });

    test('words after the end-of-text entry', () {
      expect(
        () => loadDeck([
          _minimal.first,
          _text(0, [_endOfText, (word: 7, control: ControlGroup.constantWord)]),
          _minimal.last,
        ], resolve: _raw),
        _loadError('words follow the end-of-text entry'),
      );
    });
  });
}
