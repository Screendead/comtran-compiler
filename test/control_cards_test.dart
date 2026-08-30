/// The loader symbolic control cards (M4-16; LD-1): the `*FILE` and
/// `*SPEC` field derivations of [J 90.08], the `*CTEXT` and `*CTEND`
/// form of [J 03.02.09], and the two options with no attested column
/// character, which refuse.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The control cards of one environment division over a record `REC`.
List<String> _cards(List<String> environment, {String compile = ''}) {
  final SemanticResult result = runJob(
    data: [
      dataCard(name: 'REC', level: '1', type: 'RECORD'),
      dataCard(name: 'F', level: '2', description: 'A(6)'),
    ],
    environment: environment,
    procedure: const ['            STOP RUN.'],
    compile: compile,
  );
  // A SPECIF option list past the fixture's 41 columns truncates
  // silently and draws a format diagnostic; no test here may rest on
  // one.
  expect(result.parse.parserDiagnostics, isEmpty);
  return controlCards(result.parse);
}

String _file(String options) =>
    environmentCard(name: 'INF', type: 'FILE', options: options);

/// A SPECIF card naming `INF`, continued over one card per chunk of
/// [options].
List<String> _specif(List<String> options) => [
  for (final (int i, String chunk) in options.indexed)
    environmentCard(
      type: 'SPECIF',
      options: i == 0 ? 'INF,$chunk' : chunk,
      continued: i + 1 < options.length,
    ),
];

void main() {
  group('the *FILE card (J 90.08.01)', () {
    test('a file no SPECIF card names takes every default', () {
      // No DEFER punches the `*`; the density default is HIGH; BCD is
      // the FILE default; the name lands at column 55, where the 90.05
      // print and J 03.02.02 put it (LD-1).
      expect(
        _cards([_file('INPUT,TAPE,REC,BLOCKSIZE 5')]).first,
        '      *FILE  01 *          I HD                       INF',
      );
    });

    test("the sample's first pair reproduces the page 198 print", () {
      // Listing page 7 (PDF p. 198), measured: `*FILE` at card column
      // 7, the file number at 14, `*D1` at 17, the type at 28, the
      // density and mode at 30 and 31, the name at 55.
      final List<String> cards = _cards([
        _file('INPUT,BINARY,TAPE,REC,BLOCKSIZE 300'),
        ..._specif(["UNIT1 'D1',OPENW,CLOSER"]),
      ]);
      expect(cards, [
        '      *FILE  01 *D1        I HB                       INF',
        '      *SPEC  01  300    N R',
      ]);
    });

    test('the type column reads the FILE usage', () {
      expect(_cards([_file('OUTPUT,TAPE,REC,BLOCKSIZE 5')]).first[27], 'P');
      expect(
        _cards([_file('OUTPUT,TAPE,REC,BLOCKSIZE 5,SPANS')]).first[27],
        'T',
      );
      // No type character is attested for a checkpoint file; the
      // column stays blank and column 35 marks the file (LD-1; D7.2).
      // A checkpoint file "may have no other usage" (J 02.06.03).
      final String checkpoint = _cards([
        _file('CHECKPOINT'),
        ..._specif(['CHECKC']),
      ]).first;
      expect(checkpoint[27], ' ');
      expect(checkpoint[34], 'C');
    });

    test('the SPECIF options fill their columns', () {
      final String card = _cards([
        _file('OUTPUT,TAPE,REC,BLOCKSIZE 5'),
        ..._specif([
          "UNIT1 'A(1)',UNIT2 '*',LOW,DEFER,",
          "OPENF,MULTI,LABELS,SERIAL 'S1234',",
          "REEL '0002',RETAIN 30,LOW",
        ]),
      ]).first;
      expect(card.substring(16, 25), ' A(1)*   ');
      // OPENF on a labeled file: search the label (L); LOW after LABELS
      // is the label density; a quoted literal punches left-aligned and
      // a number right-aligned.
      expect(card.substring(27, 35), 'PLLDL   ');
      expect(card.substring(37, 53), '0002  S1234   30');
    });

    test('reel control and the checkpoint column need both conditions', () {
      // MULTI marks an unlabeled file only; CHECKF needs OUTPUT and a
      // label (D7.2).
      final String multi = _cards([
        _file('OUTPUT,TAPE,REC,BLOCKSIZE 5'),
        ..._specif(['MULTI,CHECKF']),
      ]).first;
      expect(multi[28], 'M');
      expect(multi[34], ' ');
      final String labeled = _cards([
        _file('OUTPUT,TAPE,REC,BLOCKSIZE 5'),
        ..._specif(['MULTI,LABELN,CHECKF']),
      ]).first;
      expect(labeled[28], ' ');
      expect(labeled[31], 'S');
      expect(labeled[34], 'F');
    });

    test('a file name longer than its eighteen columns refuses', () {
      // A name past one card's 16 columns continues on the next card
      // (J 02.03.01, section 2.b).
      List<String> named(String letter, int length) => [
        environmentCard(
          name: letter * 16,
          type: 'FILE',
          options: 'INPUT,TAPE,REC,BLOCKSIZE 5',
          continued: true,
        ),
        environmentCard(name: letter * (length - 16)),
      ];
      expect(
        () => _cards(named('A', 19)),
        throwsA(
          isA<UnrecoveredShape>().having(
            (UnrecoveredShape e) => e.shape,
            'shape',
            contains("file name '${'A' * 19}'"),
          ),
        ),
      );
      expect(_cards(named('B', 18)).first, endsWith(' ${'B' * 18}'));
    });

    test('a unit literal longer than its four columns refuses', () {
      expect(
        () => _cards([
          _file('INPUT,TAPE,REC,BLOCKSIZE 5'),
          ..._specif(["UNIT1 'A(1)',UNIT2 'ABCDE'"]),
        ]),
        throwsA(
          isA<UnrecoveredShape>().having(
            (UnrecoveredShape e) => e.shape,
            'shape',
            contains("UNIT literal 'ABCDE'"),
          ),
        ),
      );
    });

    test('SEQ and CKSUMS refuse: no column character is attested', () {
      for (final option in ['SEQ', 'CKSUMS']) {
        expect(
          () => _cards([
            _file('INPUT,TAPE,REC,BLOCKSIZE 5'),
            ..._specif([option]),
          ]),
          throwsA(
            isA<UnrecoveredShape>().having(
              (UnrecoveredShape e) => e.shape,
              'shape',
              contains(option),
            ),
          ),
          reason: option,
        );
      }
    });
  });

  group('the *SPEC card (J 90.08.02)', () {
    test('the blocksize is right-justified in four columns (D7.1)', () {
      expect(
        _cards([_file('INPUT,TAPE,REC,BLOCKSIZE 1234')])[1],
        '      *SPEC  01 1234    R U',
      );
      // Msg 931 rejects the card and the job goes on (severity 4); the
      // field the value cannot fit stays blank.
      expect(
        _cards([_file('INPUT,TAPE,REC,BLOCKSIZE 10000')])[1],
        '      *SPEC  01         R U',
      );
    });

    test('activity, open and close read the SPECIF options', () {
      // OPENW punches N; CLOSEW punches N; the compiler punches R where
      // J 90.08.02 allows "R or blank", as the attested CLOSER shows.
      expect(
        _cards([
          _file('INPUT,TAPE,REC,BLOCKSIZE 5'),
          ..._specif(['ACTIVITY 7,OPENW,CLOSEW']),
        ])[1],
        '      *SPEC  01    5  7 N N',
      );
      expect(
        _cards([
          _file('INPUT,TAPE,REC,BLOCKSIZE 5'),
          ..._specif(['CLOSER']),
        ])[1],
        '      *SPEC  01    5    R R',
      );
    });
  });

  group('the deck (J 03.01.02)', () {
    test('files number in declaration order, a repeated name once', () {
      final List<String> cards = _cards([
        _file('INPUT,TAPE,REC,BLOCKSIZE 5'),
        environmentCard(
          name: 'OUTF',
          type: 'FILE',
          options: 'OUTPUT,TAPE,REC,BLOCKSIZE 5',
        ),
        _file('INPUT,TAPE,REC,BLOCKSIZE 9'),
      ]);
      expect(cards, hasLength(4));
      expect(cards[2], startsWith('      *FILE  02'));
      expect(cards[2], endsWith('OUTF'));
    });

    test(r'a $CMPLE deck.name punches in columns 1 to 6', () {
      expect(
        _cards([
          _file('INPUT,TAPE,REC,BLOCKSIZE 5'),
        ], compile: r'$CMPLE PAYRL').first,
        startsWith('PAYRL *FILE  01'),
      );
    });

    test('*CTEXT stamps the date and time the print attests', () {
      // `DATE 101861 TIME   2.45` at columns 26 to 48: the separators
      // dropped, the time right-aligned ending at column 48 (page 198,
      // measured).
      expect(
        textBracketCard(
          '*CTEXT',
          deckName: '',
          secondaryIdentifier: 'CT PUBLICATIONS',
          date: '10/18/61',
          time: '2.45',
        ),
        '      *CTEXT             DATE 101861 TIME   2.45      '
        'CT PUBLICATIONS',
      );
      expect(
        textBracketCard(
          '*CTEND',
          deckName: 'PAYRL',
          secondaryIdentifier: '',
          date: '08/30/26',
          time: '14.50',
        ),
        'PAYRL *CTEND             DATE 083026 TIME  14.50',
      );
    });
  });
}
