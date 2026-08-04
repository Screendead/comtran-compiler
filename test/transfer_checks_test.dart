/// The M3 stage-2 transfer, DO, and function checks: the procedure
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
  dataCard(name: 'IDX', level: '1', mode: 'I', justify: 'R', description: '99'),
  dataCard(
    name: 'FRAC',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '9V9',
  ),
  dataCard(name: 'ALPHA', level: '1', description: 'A(4)'),
  dataCard(name: 'ARG', level: '1', mode: 'I', justify: 'R', description: '99'),
  dataCard(name: 'T', level: '1', mode: 'I', justify: 'R', description: '99'),
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
        data: [
          dataCard(
            name: 'SCALED',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '999SSS',
          ),
        ],
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

    test('matching USING and GIVING lists draw nothing', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: section(' USING ARG GIVING T.', 'DO S USING IDX GIVING T.'),
      );
      expect(ids(result), isEmpty);
    });

    test('too many USING arguments draw 72,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: section(' USING ARG.', 'DO S USING IDX, FRAC.'),
      );
      expect(ids(result), ['72,00']);
    });

    test('too few USING arguments draw 73,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: section(' USING ARG, T.', 'DO S USING IDX.'),
      );
      expect(ids(result), ['73,00']);
    });

    test('too many GIVING results draw 74,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: section(' GIVING ARG.', 'DO S GIVING IDX, FRAC.'),
      );
      expect(ids(result), ['74,00']);
    });

    test('too few GIVING results draw 75,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: section(' GIVING ARG, T.', 'DO S GIVING IDX.'),
      );
      expect(ids(result), ['75,00']);
    });

    test('a bare DO of a USING or GIVING section draws nothing '
        '(F p. 33)', () {
      // The values already in the parameter and function fields serve;
      // both clauses are optional on the DO.
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: section(' USING ARG GIVING T.', 'DO S.'),
      );
      expect(ids(result), isEmpty);
    });

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
    test('an alphameric FOR index draws 76,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: [
          "      RTN.        DISPLAY 'A'.",
          '            DO RTN FOR ALPHA = 1(1)9.',
        ],
      );
      expect(ids(result), ['76,00']);
      expect(result.semanticDiagnostics.single.operands, ['ALPHA']);
    });

    test('an alphameric loop parameter draws 77,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: [
          "      RTN.        DISPLAY 'A'.",
          '            DO RTN FOR IDX = 1(1)ALPHA.',
        ],
      );
      expect(ids(result), ['77,00']);
      expect(result.semanticDiagnostics.single.operands, ['ALPHA']);
    });

    test('a fractional literal loop parameter draws 78,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: [
          "      RTN.        DISPLAY 'A'.",
          '            DO RTN FOR IDX = 1(0.5)9.',
        ],
      );
      expect(ids(result), ['78,00']);
      // NAME.1 is the loop control variable (J 90.04).
      expect(result.semanticDiagnostics.single.operands, ['IDX']);
    });

    test('a whole numeric loop control draws nothing', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: [
          "      RTN.        DISPLAY 'A'.",
          '            DO RTN FOR IDX = 1(1)ARG.',
        ],
      );
      expect(ids(result), isEmpty);
    });
  });

  group('functions (M3-19)', () {
    List<String> program(String declaration, String call) => [
      '      S.          BEGIN SECTION USING ARG$declaration',
      '            END S.',
      '            MOVE $call TO T.',
    ];

    test('a name no GIVING clause lists draws 191,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: program('.', 'IDX ((ARG))'),
      );
      expect(ids(result), ['191,00']);
      expect(result.semanticDiagnostics.single.operands, ['IDX']);
    });

    test('a matching argument count draws nothing', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: program(' GIVING IDX.', 'IDX ((ARG))'),
      );
      expect(ids(result), isEmpty);
    });

    test('too few arguments draw 30,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: program(', FRAC GIVING IDX.', 'IDX ((ARG))'),
      );
      expect(ids(result), ['30,00']);
    });

    test('too many arguments draw 68,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: program(' GIVING IDX.', 'IDX ((ARG, FRAC))'),
      );
      expect(ids(result), ['68,00']);
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
