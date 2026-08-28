/// The code generator's diagnostics (M4-18, chunk B8): the eight-class
/// name tally behind msg 942 (M4-5), the pool counter behind msg 172
/// (D9.7), the two `--pedantic` notes 946 and 947 (D5.1; D5.7), and the
/// D10.2 stop shape of the phase (M4-2).
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

JobCompilation _compile(
  List<String> lines, {
  bool pedantic = false,
  bool tableLimits = true,
}) => compileDeck(
  mirrorToDeck('${lines.join('\n')}\n'),
  pedantic: pedantic,
  tableLimits: tableLimits,
).jobs.single;

List<String> _ids(JobCompilation job) => [
  for (final Diagnostic d in job.diagnostics) d.message.number,
];

/// [count] one-character fields, then `STOP RUN.` as the whole text.
List<String> _namesThenStop(int count) => [
  '      *DATA',
  for (var i = 0; i < count; i++)
    dataCard(name: 'N$i', level: '1', description: 'A'),
  '      *PROCEDURE',
  '            STOP RUN.',
  '      *FINISH',
];

/// A section DO'd FOR [index] over a twelve-element table it subscripts
/// — the one DO FOR shape the generator fills (chunk B5).
List<String> _doFor(String index) => [
  '      *DATA',
  dataCard(name: 'TAB', level: '1', quantity: '12'),
  dataCard(
    name: 'CELL',
    level: '2',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(name: 'IDX', level: '1', mode: 'I', justify: 'R', description: '99'),
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  DO RTN FOR IDX = $index.',
  '            GO TO LAST.',
  '      RTN.  BEGIN SECTION.',
  '            MOVE NUM TO TAB CELL (IDX).',
  '            END RTN.',
  '      LAST.  STOP RUN.',
  '      *FINISH',
];

List<String> _procedure(List<String> sentences) => [
  '      *DATA',
  dataCard(name: 'N', level: '1', mode: 'I', justify: 'R', description: '999'),
  '      *PROCEDURE',
  ...sentences,
  '      *FINISH',
];

void main() {
  group('the name tally (M4-5; msg 942)', () {
    // The generator's fixed names: the five block heads, `BL)1`,
    // `IOC)29`, and the two pool seeds — nine, entered ahead of the
    // first sentence. `STOP RUN` then enters its two stamp words, the
    // ` STOP ` and ` RUN  ` words, SYS)178, SYS)177, IOC)1 and IOC)40.
    test('the 3501st name of the program crosses in the generator', () {
      // 3490 programmer names and GN)000 make 3491; the nine fixed
      // names make 3500; the stamp's first word is the 3501st.
      final JobCompilation job = _compile(_namesThenStop(3490));
      expect(_ids(job), ['942,00']);
      final Diagnostic capacity = job.diagnostics.single;
      expect(capacity.card?.cardNumber, 3493, reason: 'the STOP RUN card');
      expect(job.semantics!.stopped, isFalse);
      expect(job.semantics!.nameCount, 3491);
      expect(job.codegen!.stopped, isTrue);
      expect(job.codegen!.units, isEmpty);
      expect(job.codegen!.image, isNull);
      expect(job.unrecovered, isNull);
      expect(job.sink.maxSeverity, 5);
    });

    test('a fixed name crossing the limit reports against no statement', () {
      // 3491 programmer names and GN)000 make 3492: the ninth fixed
      // name is the 3501st, and no statement owns it (D11.3).
      final JobCompilation job = _compile(_namesThenStop(3491));
      expect(_ids(job), ['942,00']);
      expect(job.diagnostics.single.card, isNull);
      expect(job.codegen!.stopped, isTrue);
    });

    test('the allocator crosses on GN)000 and stops the semantic layer', () {
      // 3500 programmer names fill the table; the program entry's own
      // name is the 3501st, entered at the first procedure sentence.
      final JobCompilation job = _compile(_namesThenStop(3500));
      expect(_ids(job), ['942,00']);
      expect(job.diagnostics.single.card?.cardNumber, 3503);
      expect(job.semantics!.stopped, isTrue);
      expect(job.semantics!.allocation, isNull);
      expect(job.codegen, isNull);
    });

    test('--no-table-limits lifts the tally and changes nothing else', () {
      final JobCompilation job = _compile(
        _namesThenStop(3500),
        tableLimits: false,
      );
      expect(job.diagnostics, isEmpty);
      expect(job.semantics!.nameCount, 3501);
      expect(job.codegen!.stopped, isFalse);
      expect(job.codegen!.units, isNotEmpty);
    });

    test('a SYS) or IOC) number counts once, not per use', () {
      // Two STOP RUNs share every generated name but the second's
      // statement-number word: the second frame enters one name, not
      // its eight. 3481 names, GN)000 and the nine fixed names make
      // 3491; the first frame's eight make 3499; the second frame's
      // one makes 3500 and compiles. One more programmer name and the
      // second frame's word is the 3501st.
      List<String> twoStops(int names) => [
        '      *DATA',
        for (var i = 0; i < names; i++)
          dataCard(name: 'N$i', level: '1', description: 'A'),
        '      *PROCEDURE',
        '            STOP RUN.',
        '            STOP RUN.',
        '      *FINISH',
      ];
      final JobCompilation full = _compile(twoStops(3481));
      expect(full.diagnostics, isEmpty);
      expect(full.codegen!.stopped, isFalse);
      final JobCompilation over = _compile(twoStops(3482));
      expect(_ids(over), ['942,00']);
      expect(over.diagnostics.single.card?.cardNumber, 3486);
    });
  });

  group('the constant pool counter (D9.7; msg 172)', () {
    List<String> literals(int count) => [
      '      *DATA',
      dataCard(
        name: 'N',
        level: '1',
        mode: 'I',
        justify: 'R',
        description: '999',
      ),
      '      *PROCEDURE',
      for (var k = 2; k < 2 + count; k++) '            SET N = $k.',
      '            STOP RUN.',
      '      *FINISH',
    ];

    test('the 500th entry compiles and the 501st draws 172,00', () {
      // The seeds 0 and 1, 494 written literals, and STOP RUN's four
      // machine words fill the pool exactly.
      final JobCompilation full = _compile(literals(494));
      expect(full.diagnostics, isEmpty);
      expect(full.codegen!.image!.blockWords[StorageBlock.cp], 500);
      final JobCompilation over = _compile(literals(495));
      expect(_ids(over), ['172,00']);
      final Diagnostic overflow = over.diagnostics.single;
      expect(overflow.severity, 5);
      // The 501st entry is ` RUN  `, inside STOP RUN's one clause.
      expect(overflow.card?.cardNumber, 499);
      expect(overflow.clause, 1);
      expect(over.codegen!.stopped, isTrue);
    });

    test('--no-table-limits lifts the counter', () {
      final JobCompilation job = _compile(literals(495), tableLimits: false);
      expect(job.diagnostics, isEmpty);
      expect(job.codegen!.image!.blockWords[StorageBlock.cp], 501);
    });
  });

  group('the D5.1 note (msg 946; M4-13)', () {
    test('parameters that step from p to r exactly are silent', () {
      for (final index in ['1(1)12', '2(5)12', '12(1)12', '+1(+1)12']) {
        final JobCompilation job = _compile(_doFor(index), pedantic: true);
        expect(job.diagnostics, isEmpty, reason: index);
        expect(job.codegen!.stopped, isFalse, reason: index);
      }
    });

    test('a zero, negative or non-dividing step, or p above r, notes', () {
      for (final index in ['1(0)12', '12(1)1', '1(5)12', '1(2)12']) {
        final JobCompilation job = _compile(_doFor(index), pedantic: true);
        expect(_ids(job), ['946,00'], reason: index);
        final Diagnostic note = job.diagnostics.single;
        expect(note.severity, 1);
        expect(note.card?.cardNumber, 7);
        expect(note.clause, 1);
        expect(note.text, contains("'IDX'"));
        expect(job.codegen!.stopped, isFalse, reason: index);
        expect(_compile(_doFor(index)).diagnostics, isEmpty, reason: index);
      }
    });

    test('a negative step notes ahead of the refusal it then draws', () {
      // The generator refuses a signed bound (no sample instance), so
      // the note is the program's only record of the loop that never
      // terminates; default mode keeps the refusal alone.
      final JobCompilation job = _compile(_doFor('1(-1)12'), pedantic: true);
      expect(_ids(job), ['946,00']);
      expect(job.unrecovered?.shape, startsWith('a DO FOR bound of UnaryExpr'));
      expect(job.codegen, isNull);
      expect(_compile(_doFor('1(-1)12')).diagnostics, isEmpty);
    });

    test('a field-name parameter is not constant and draws nothing', () {
      final JobCompilation job = _compile(_doFor('NUM(1)12'), pedantic: true);
      expect(job.diagnostics, isEmpty);
    });

    test('--pedantic changes nothing but the diagnostics (D11.4)', () {
      final DeckCompilation quiet = compileDeck(
        mirrorToDeck('${_doFor('1(5)12').join('\n')}\n'),
      );
      final DeckCompilation noted = compileDeck(
        mirrorToDeck('${_doFor('1(5)12').join('\n')}\n'),
        pedantic: true,
      );
      expect(emitCode(noted), emitCode(quiet));
      expect(noted.maxSeverity, 1);
      expect(quiet.maxSeverity, 0);
    });
  });

  group('the D5.7 note (msg 947; M4-13)', () {
    test('two paragraphs that DO each other note at both calls', () {
      final List<String> lines = _procedure([
        '      START.  DO P.',
        '            GO TO LAST.',
        '      P.  DO Q.',
        '      Q.  DO P.',
        '      LAST.  STOP RUN.',
      ]);
      final JobCompilation job = _compile(lines, pedantic: true);
      expect(_ids(job), ['947,00', '947,00']);
      expect(
        [for (final Diagnostic d in job.diagnostics) d.card?.cardNumber],
        [6, 7],
      );
      expect(job.diagnostics.first.severity, 2);
      expect(job.diagnostics.first.text, contains("'Q'"));
      expect(job.diagnostics.last.text, contains("'P'"));
      // START's own DO P is outside every DO'd procedure: no note.
      expect(job.codegen!.stopped, isFalse);
      expect(_compile(lines).diagnostics, isEmpty);
      expect(
        emitCode(compileDeck(mirrorToDeck('${lines.join('\n')}\n'))),
        emitCode(
          compileDeck(mirrorToDeck('${lines.join('\n')}\n'), pedantic: true),
        ),
      );
    });

    test('a section that DOes itself from a paragraph inside it notes', () {
      final JobCompilation job = _compile(
        _procedure([
          '      START.  DO S.',
          '            GO TO LAST.',
          '      S.  BEGIN SECTION.',
          '      P.  DO S.',
          '            END S.',
          '      LAST.  STOP RUN.',
        ]),
        pedantic: true,
      );
      expect(_ids(job), ['947,00']);
      expect(job.diagnostics.single.card?.cardNumber, 7);
    });

    test('an AT END DO that re-enters its caller notes', () {
      final JobCompilation job = _compile([
        '      *DATA',
        dataCard(name: 'IREC', level: '1', type: 'RECORD'),
        dataCard(name: 'F', level: '2', description: 'A(6)'),
        '      *ENVIRONMENT',
        environmentCard(
          name: 'TAPE1',
          type: 'FILE',
          options: 'INPUT,BCD,TAPE,IREC,BLOCKSIZE 5',
        ),
        '      *PROCEDURE',
        '      START.  DO P.',
        '            GO TO LAST.',
        '      P.  GET IREC, AT END DO P.',
        '      LAST.  STOP RUN.',
        '      *FINISH',
      ], pedantic: true);
      expect(_ids(job), ['947,00']);
      expect(job.diagnostics.single.card?.cardNumber, 9);
    });

    test('nested non-recursive DOs are silent (D5.7)', () {
      final JobCompilation job = _compile(
        _procedure([
          '      START.  DO P.',
          '            GO TO LAST.',
          '      P.  DO Q.',
          '      Q.  SET N = 1.',
          '      LAST.  STOP RUN.',
        ]),
        pedantic: true,
      );
      expect(job.diagnostics, isEmpty);
    });
  });

  group('the stop shape (D10.2; M4-2)', () {
    test('a generator stop never starves the next job (J 90.04.02)', () {
      final List<String> lines = [
        r'$CMPLE FULL',
        ..._namesThenStop(3490),
        r'$CMPLE GOOD',
        '      *PROCEDURE',
        '            STOP RUN.',
        '      *FINISH',
      ];
      final DeckCompilation deck = compileDeck(
        mirrorToDeck('${lines.join('\n')}\n'),
      );
      expect(deck.jobs, hasLength(2));
      expect(_ids(deck.jobs.first), ['942,00']);
      expect(deck.jobs.first.codegen!.stopped, isTrue);
      expect(deck.jobs.last.diagnostics, isEmpty);
      expect(deck.jobs.last.codegen!.stopped, isFalse);
      expect(deck.maxSeverity, 5);
      // The dump closes the stopped job's empty text with the stopped
      // line and prints the next job whole.
      final String dump = emitCode(deck);
      expect(dump, contains('${jobHeader(1)}\n* TEXT\n$stageStopped\n'));
      expect(dump, contains('${jobHeader(2)}\n* TEXT\n\t\tUSE\t1'));
    });

    test('the sample draws no generator diagnostic in either mode', () {
      final JobCompilation quiet = compileDeck(loadJobDeck()).jobs.single;
      expect(quiet.diagnostics, isEmpty);
      expect(quiet.codegen!.stopped, isFalse);
      final JobCompilation noted = compileDeck(
        loadJobDeck(),
        pedantic: true,
      ).jobs.single;
      expect(_ids(noted), ['943,00', '943,00', '943,00']);
      expect(
        emitCode(compileDeck(loadJobDeck(), pedantic: true)),
        emitCode(compileDeck(loadJobDeck())),
      );
    });
  });
}
