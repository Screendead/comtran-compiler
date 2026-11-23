/// The transfer, DO, and function checks: the procedure
/// target model (D2.5; M3-20), DO substitution and functions (M3-19),
/// loop control (F pp. 49–53), and the per-sentence reference table
/// (D9.7; Open Question 9).
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// A right-justified internal index, a fractional one, an alphameric
/// field, and two numeric fields for the operand slots.
List<String> _fields() => [
  internalCard('IDX', '99'),
  internalCard('FRAC', '9V9'),
  dataCard(name: 'ALPHA', level: '1', description: 'A(4)'),
  internalCard('ARG', '99'),
  internalCard('T', '99'),
];

void main() {
  group('transfer targets (M3-20)', () {
    test('a GO TO target that names nothing draws 127,00', () {
      final SemanticResult result = runJob(
        data: const [],
        procedure: ['            GO TO AWAY.'],
      );
      expect(ids(result), ['127,00']);
      expect(result.semanticDiagnostics.single.operands, ['AWAY']);
      // The site is inside clause 1 (M2-6).
      expect(result.semanticDiagnostics.single.clause, 1);
    });

    test('a GO TO to a DO-addressed name draws 128,00 (Q40)', () {
      final SemanticResult result = runJob(
        data: const [],
        procedure: [
          "      RTN.        DISPLAY 'A'.",
          '            DO RTN.',
          '            GO TO RTN.',
        ],
      );
      expect(ids(result), ['128,00']);
    });

    test('a DO target that names nothing draws 188,00', () {
      final SemanticResult result = runJob(
        data: const [],
        procedure: ['            DO AWAY.'],
      );
      expect(ids(result), ['188,00']);
    });

    test('an AT END bare name that names nothing draws 188,00 '
        '(D6.6)', () {
      // The GET binds a record of an input file, so only the AT END
      // name is at fault (M3-18 speaks for the operand).
      final SemanticResult result = runJob(
        data: [
          dataCard(name: 'MASTER', level: '1', type: 'RECORD'),
          dataCard(name: 'EMP', level: '2', description: 'A(6)'),
        ],
        environment: [
          environmentCard(
            name: 'FIN',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,MASTER,BLOCKSIZE 5',
          ),
        ],
        procedure: ['            GET MASTER, AT END AWAY.'],
      );
      expect(ids(result), ['188,00']);
    });

    test('a GO TO to an AT END bare name draws 128,00 (D6.6; Q40)', () {
      final SemanticResult result = runJob(
        data: [
          dataCard(name: 'MASTER', level: '1', type: 'RECORD'),
          dataCard(name: 'EMP', level: '2', description: 'A(6)'),
        ],
        environment: [
          environmentCard(
            name: 'FIN',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,MASTER,BLOCKSIZE 5',
          ),
        ],
        procedure: [
          "      AWAY.       DISPLAY 'A'.",
          '            GET MASTER, AT END AWAY.',
          '            GO TO AWAY.',
        ],
      );
      expect(ids(result), ['128,00']);
      expect(result.semanticDiagnostics.single.operands, ['AWAY']);
    });

    test('a one-word target takes its own section first (D2.5)', () {
      // The outermost X is DO-addressed; the section's own X is not, so
      // only the transfer that leaves the section is refused.
      List<String> program(String transfer) => [
        "      X.          DISPLAY 'A'.",
        '      S.          BEGIN SECTION.',
        "      X.          DISPLAY 'B'.",
        '            $transfer',
        '            END S.',
        '            DO X.',
      ];
      expect(
        ids(runJob(data: const [], procedure: program('GO TO X.'))),
        isEmpty,
      );
      expect(
        ids(runJob(data: const [], procedure: program('STOP RUN.'))),
        isEmpty,
      );
      final SemanticResult outside = runJob(
        data: const [],
        procedure: [...program('STOP RUN.'), '            GO TO X.'],
      );
      expect(ids(outside), ['128,00']);
    });

    test('a one-word target takes the label of its own section, not '
        "a same-name section's (D2.5)", () {
      // P2's X is DO-addressed, so a transfer that reached it draws
      // 128; P1's GO TO X stays inside P1's S.
      List<String> program(String transfer) => [
        '      P1.         BEGIN SECTION.',
        '      S.          BEGIN SECTION.',
        "      X.          DISPLAY 'A'.",
        '            GO TO X.',
        '            END S.',
        '            END P1.',
        '      P2.         BEGIN SECTION.',
        '      S.          BEGIN SECTION.',
        "      X.          DISPLAY 'B'.",
        '            DO X.',
        '            $transfer',
        '            END S.',
        '            END P2.',
        '            STOP RUN.',
      ];
      expect(
        ids(runJob(data: const [], procedure: program("DISPLAY 'C'."))),
        isEmpty,
      );
      expect(ids(runJob(data: const [], procedure: program('GO TO X.'))), [
        '128,00',
      ]);
    });

    test('a two-word target names a section the qualifier encloses '
        '(D2.5)', () {
      final SemanticResult result = runJob(
        data: const [],
        procedure: [
          '            DO P1 S.',
          '            DO P3 S.',
          '      P1.         BEGIN SECTION.',
          '      S.          BEGIN SECTION.',
          "            DISPLAY 'A'.",
          '            END S.',
          '            END P1.',
          '      P2.         BEGIN SECTION.',
          '      S.          BEGIN SECTION.',
          "            DISPLAY 'B'.",
          '            END S.',
          '            END P2.',
          '            STOP RUN.',
        ],
      );
      expect(ids(result), ['188,00']);
      expect(result.semanticDiagnostics.single.operands, ['P3 S']);
    });

    test('a two-word target is section A label B (D2.5)', () {
      final SemanticResult result = runJob(
        data: const [],
        procedure: [
          '      S.          BEGIN SECTION.',
          "      X.          DISPLAY 'B'.",
          '            END S.',
          '            GO TO S X.',
          '            GO TO OTHER X.',
        ],
      );
      expect(ids(result), ['127,00']);
      expect(result.semanticDiagnostics.single.operands, ['OTHER X']);
    });

    test('an alphameric assigned GO TO index draws 129,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: [
          "      ONE.        DISPLAY 'A'.",
          "      TWO.        DISPLAY 'B'.",
          '            GO TO (ONE, TWO) ON ALPHA.',
        ],
      );
      expect(ids(result), ['129,00']);
    });

    test('a fractional assigned GO TO index draws 130,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: [
          "      ONE.        DISPLAY 'A'.",
          "      TWO.        DISPLAY 'B'.",
          '            GO TO (ONE, TWO) ON FRAC.',
        ],
      );
      expect(ids(result), ['130,00']);
      expect(messageSeverities['130,00'], 1);
    });

    test('a trailing-S scaled assigned GO TO index draws nothing '
        '(F p. 80)', () {
      // `999SSS` stands for values 000,000 to 999,000, all whole, so
      // 130,00 has no fractional part to discard.
      final SemanticResult result = runJob(
        data: [internalCard('SCALED', '999SSS')],
        procedure: [
          "      ONE.        DISPLAY 'A'.",
          "      TWO.        DISPLAY 'B'.",
          '            GO TO (ONE, TWO) ON SCALED.',
        ],
      );
      expect(ids(result), isEmpty);
    });
  });

  group('DO substitution (M3-19)', () {
    List<String> section(String declaration, String call) => [
      '      S.          BEGIN SECTION$declaration',
      '            END S.',
      '            $call',
    ];

    // The values already in the parameter and function fields serve a
    // bare DO; both clauses are optional on it (F p. 33).
    for (final (String declaration, String call, List<String> drawn) in [
      (' USING ARG GIVING T.', 'DO S USING IDX GIVING T.', <String>[]),
      (' USING ARG.', 'DO S USING IDX, FRAC.', ['72,00']),
      (' USING ARG, T.', 'DO S USING IDX.', ['73,00']),
      (' GIVING ARG.', 'DO S GIVING IDX, FRAC.', ['74,00']),
      (' GIVING ARG, T.', 'DO S GIVING IDX.', ['75,00']),
      (' USING ARG GIVING T.', 'DO S.', <String>[]),
    ]) {
      test('$call against$declaration draws $drawn', () {
        final SemanticResult result = runJob(
          data: _fields(),
          procedure: section(declaration, call),
        );
        expect(ids(result), drawn);
      });
    }

    test('a statement target declares none, so any USING draws '
        '72,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: [
          "      RTN.        DISPLAY 'A'.",
          '            DO RTN USING IDX.',
        ],
      );
      expect(ids(result), ['72,00']);
    });
  });

  group('loop control (M3-20)', () {
    // NAME.1 of 78,00 is the loop control variable (J 90.04).
    for (final (String control, List<String> drawn, String? operand) in [
      ('ALPHA = 1(1)9', ['76,00'], 'ALPHA'),
      ('IDX = 1(1)ALPHA', ['77,00'], 'ALPHA'),
      ('IDX = 1(0.5)9', ['78,00'], 'IDX'),
      ('IDX = 1(1)ARG', <String>[], null),
    ]) {
      test('FOR $control draws $drawn', () {
        final SemanticResult result = runJob(
          data: _fields(),
          procedure: [
            "      RTN.        DISPLAY 'A'.",
            '            DO RTN FOR $control.',
          ],
        );
        expect(ids(result), drawn);
        if (operand != null) {
          expect(result.semanticDiagnostics.single.operands, [operand]);
        }
      });
    }
  });

  group('functions (M3-19)', () {
    List<String> program(String declaration, String call) => [
      '      S.          BEGIN SECTION USING ARG$declaration',
      '            END S.',
      '            MOVE $call TO T.',
    ];

    // 191,00 names the function.
    for (final (String declaration, String call, List<String> drawn) in [
      ('.', 'IDX ((ARG))', ['191,00']),
      (' GIVING IDX.', 'IDX ((ARG))', <String>[]),
      (', FRAC GIVING IDX.', 'IDX ((ARG))', ['30,00']),
      (' GIVING IDX.', 'IDX ((ARG, FRAC))', ['68,00']),
    ]) {
      test('$call against$declaration draws $drawn', () {
        final SemanticResult result = runJob(
          data: _fields(),
          procedure: program(declaration, call),
        );
        expect(ids(result), drawn);
        if (drawn case ['191,00']) {
          expect(result.semanticDiagnostics.single.operands, ['IDX']);
        }
      });
    }

    test('a function is checked as a SET value and as an ADD source', () {
      for (final clause in ['SET T = IDX ((ARG)).', 'ADD IDX ((ARG)) TO T.']) {
        final SemanticResult result = runJob(
          data: _fields(),
          procedure: [
            '      S.          BEGIN SECTION USING ARG.',
            '            END S.',
            '            $clause',
          ],
        );
        expect(ids(result), ['191,00'], reason: clause);
        expect(result.semanticDiagnostics.single.operands, ['IDX']);
      }
    });
  });

  group('the sentence table (D9.7)', () {
    List<String> hundredAndOneReferences() {
      final lines = ['            MOVE N0 TO'];
      for (var i = 1; i <= 100; i += 8) {
        final List<String> chunk = [
          for (var n = i; n < i + 8 && n <= 100; n++) 'N$n',
        ];
        lines.add('            ${chunk.join(', ')}${i + 8 > 100 ? '.' : ','}');
      }
      return lines;
    }

    test('the 101st reference draws 177,00 and deletes the '
        'sentence', () {
      final List<String> data = [
        for (var i = 0; i <= 100; i++)
          dataCard(name: 'N$i', level: '1', description: 'A'),
      ];
      final List<String> procedure = hundredAndOneReferences();
      final SemanticResult capped = runJob(data: data, procedure: procedure);
      expect(ids(capped), ['177,00']);
      expect(capped.capacityDeletedSentences, hasLength(1));
      final SemanticResult lifted = runJob(
        data: data,
        procedure: procedure,
        tableLimits: false,
      );
      expect(ids(lifted), isEmpty);
      expect(lifted.capacityDeletedSentences, isEmpty);
    });
  });
}
