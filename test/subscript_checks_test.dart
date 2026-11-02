/// The M3 stage-2 subscript reference checks (M3-20): the dimension
/// rows, the subscript-variable format rows (F p. 31; D9.11), the
/// 1-origin literal rule (J 02.04.07.01), and the two D9.7 counters.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// A twelve-element array of right-justified internal decimal cells, a
/// flat field of each class a subscript variable can take, and a
/// numeric MOVE target.
List<String> _fields() => [
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
    name: 'FRAC',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '9V9',
  ),
  dataCard(name: 'EXT', level: '1', mode: 'E', description: '99'),
  dataCard(name: 'ALPHA', level: '1', description: 'A(4)'),
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
];

SemanticResult _move(String subscripted) => runJob(
  data: _fields(),
  procedure: ['            MOVE $subscripted TO NUM.'],
);

void main() {
  group('subscript references (M3-20)', () {
    test('a matching subscript count draws nothing', () {
      final SemanticResult result = _move('TAB CELL (IDX)');
      expect(ids(result), isEmpty);
    });

    test('an unsubscripted array reference draws nothing', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: ['            MOVE ALPHA TO ALPHA.'],
      );
      expect(ids(result), isEmpty);
    });

    test('a subscripted reference to a flat item draws 98,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: ['            MOVE ALPHA (IDX) TO ALPHA.'],
      );
      expect(ids(result), ['98,00']);
      // The site is inside clause 1 (M2-6).
      expect(result.semanticDiagnostics.single.clause, 1);
      expect(result.semanticDiagnostics.single.operands, ['ALPHA']);
    });

    test('a subscript count above the dimension count draws 70,00', () {
      final SemanticResult result = _move('TAB CELL (IDX, IDX)');
      expect(ids(result), ['70,00']);
      expect(result.semanticDiagnostics.single.operands, ['TAB CELL']);
    });

    test('a subscripted subscript variable draws 71,00', () {
      final SemanticResult result = _move('TAB CELL (TAB CELL (IDX))');
      expect(ids(result), ['71,00']);
      // NAME.1 is the array, not the variable (J 90.04).
      expect(result.semanticDiagnostics.single.operands, ['TAB CELL']);
    });

    test('a condition-name subscript draws 71,00', () {
      final SemanticResult result = runJob(
        data: [
          ..._fields(),
          dataCard(name: 'STATUS', level: '1', description: 'A'),
          dataCard(name: 'WED', level: '2', type: 'COND', description: "'M'"),
        ],
        procedure: ['            MOVE TAB CELL (WED) TO NUM.'],
      );
      expect(ids(result), ['71,00']);
    });

    group('a function call as a subscript term (F p. 31)', () {
      List<String> declared(String declaration, String clause) => [
        '      S.          BEGIN SECTION USING IDX$declaration',
        '            END S.',
        '            $clause',
      ];
      List<String> fields() => [
        ..._fields(),
        dataCard(
          name: 'FN',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: '99',
        ),
      ];

      test('a declared function draws 71,00 alone', () {
        final SemanticResult result = runJob(
          data: fields(),
          procedure: declared(
            ' GIVING FN.',
            'MOVE TAB CELL (FN ((IDX))) TO NUM.',
          ),
        );
        expect(ids(result), ['71,00']);
        // NAME.1 is the array, not the function (J 90.04).
        expect(result.semanticDiagnostics.single.operands, ['TAB CELL']);
      });

      test('a function inside an index expression draws 71,00', () {
        final SemanticResult result = runJob(
          data: fields(),
          procedure: declared(
            ' GIVING FN.',
            'MOVE TAB CELL (FN ((IDX)) + 1) TO NUM.',
          ),
        );
        expect(ids(result), ['71,00']);
      });

      test('a SET or ADD target keeps the function check beside '
          '71,00', () {
        for (final clause in [
          'SET TAB CELL (FN ((IDX))) = 1.',
          'ADD 1 TO TAB CELL (FN ((IDX))).',
        ]) {
          // FN is listed by no GIVING clause, so the function check on
          // the target's subscript draws 191 (M3-19).
          final SemanticResult result = runJob(
            data: fields(),
            procedure: declared('.', clause),
          );
          expect(ids(result), ['71,00', '191,00'], reason: clause);
          expect(result.semanticDiagnostics.last.operands, ['FN']);
        }
      });
    });

    test('the parser, not M3-20, diagnoses an alphameric literal or a '
        'figurative subscript term', () {
      for (final (String subscript, String parserId) in [
        ("TAB CELL ('A')", '912,00'),
        ('TAB CELL (ZERO)', '192,00'),
      ]) {
        final SemanticResult result = _move(subscript);
        expect(ids(result), isEmpty, reason: subscript);
        expect(
          result.parse.diagnostics.map((Diagnostic d) => d.message.number),
          contains(parserId),
          reason: subscript,
        );
      }
    });

    test('an alphameric subscript variable draws 79,00', () {
      final SemanticResult result = _move('TAB CELL (ALPHA)');
      expect(ids(result), ['79,00']);
      expect(result.semanticDiagnostics.single.operands, ['ALPHA']);
    });

    test('a fractional subscript variable draws 31,00', () {
      final SemanticResult result = _move('TAB CELL (FRAC)');
      expect(ids(result), ['31,00']);
    });

    test('a zero, negative, or fractional literal draws 182,00', () {
      final SemanticResult result = runJob(
        data: _fields(),
        procedure: [
          '            MOVE TAB CELL (0) TO NUM.',
          '            MOVE TAB CELL (-1) TO NUM.',
          '            MOVE TAB CELL (1.5) TO NUM.',
        ],
      );
      expect(ids(result), ['182,00', '182,00', '182,00']);
    });

    test('literal terms that fold below one draw 182,00', () {
      // Each term passes alone; the element 2 - 3 names does not exist.
      // A term that draws 182,00 itself speaks for its subscript, and a
      // quotient does not fold.
      for (final (String subscript, List<String> drawn) in [
        ('2 - 3', ['182,00']),
        ('2 * 3 - 6', ['182,00']),
        ('2 + -(3 - 1)', ['182,00']),
        ('3 - 2', <String>[]),
        ('0 - 1', ['182,00']),
        ('2 / 4 - 1', <String>[]),
        ('-(3 - 2)', ['182,00']),
        ('-3', ['182,00']),
      ]) {
        expect(ids(_move('TAB CELL ($subscript)')), drawn, reason: subscript);
      }
    });

    test('a whole positive literal subscript draws nothing', () {
      final SemanticResult result = _move('TAB CELL (3)');
      expect(ids(result), isEmpty);
    });

    test('an external decimal subscript variable draws 206,00', () {
      final SemanticResult result = _move('TAB CELL (EXT)');
      expect(ids(result), ['206,00']);
      expect(messageSeverities['206,00'], 1);
    });

    group('the other format rows', () {
      SemanticResult moveWith(String variable, List<String> declaration) =>
          runJob(
            data: [..._fields(), ...declaration],
            procedure: ['            MOVE TAB CELL ($variable) TO NUM.'],
          );

      test('an edited subscript variable draws 79,00', () {
        final SemanticResult result = moveWith('EDIT', [
          dataCard(name: 'EDIT', level: '1', description: '8889.99'),
        ]);
        expect(ids(result), ['79,00']);
        expect(result.semanticDiagnostics.single.operands, ['EDIT']);
      });

      test('a group subscript variable draws 79,00', () {
        final SemanticResult result = moveWith('GRP', [
          dataCard(name: 'GRP', level: '1'),
          dataCard(name: 'GF', level: '2', description: '99'),
        ]);
        expect(ids(result), ['79,00']);
        expect(result.semanticDiagnostics.single.operands, ['GRP']);
      });

      test('a left-justified internal decimal subscript variable draws '
          '206,00 (D9.11)', () {
        final SemanticResult result = moveWith('LEFT', [
          dataCard(
            name: 'LEFT',
            level: '1',
            mode: 'I',
            justify: 'L',
            description: '99',
          ),
        ]);
        expect(ids(result), ['206,00']);
      });
    });

    test('an undefined subscript variable draws the triage 108,00 '
        'alone', () {
      final SemanticResult result = _move('TAB CELL (NOSUCH)');
      expect(ids(result), ['108,00']);
    });
  });

  group('the subscript counters (D9.7)', () {
    test('the 91st positional indicator draws 184,00', () {
      final List<String> procedure = [
        for (var i = 1; i <= 91; i++) '            MOVE TAB CELL ($i) TO NUM.',
      ];
      final SemanticResult capped = runJob(
        data: _fields(),
        procedure: procedure,
      );
      expect(ids(capped), ['184,00']);
      expect(capped.stopped, isTrue);
      final SemanticResult lifted = runJob(
        data: _fields(),
        procedure: procedure,
        tableLimits: false,
      );
      expect(ids(lifted), isEmpty);
      expect(lifted.stopped, isFalse);
    });

    test('the 91st array-notation pair draws 184,00, repeats free '
        '(J 02.04.07)', () {
      final List<String> fields = [
        ..._fields(),
        dataCard(name: 'TAB2', level: '1', quantity: '12'),
        dataCard(
          name: 'CELL2',
          level: '2',
          mode: 'I',
          justify: 'R',
          description: '999',
        ),
      ];
      // 45 literals shared by two arrays makes 90 distinct pairs: an
      // array-only key collapses each array to one entry, and a
      // notation-only key collapses the shared literals to 45 — either
      // way the 91st distinct pair below would never be reached.
      final List<String> distinct = [
        for (var i = 1; i <= 45; i++) '            MOVE TAB CELL ($i) TO NUM.',
        for (var i = 1; i <= 45; i++)
          '            MOVE TAB2 CELL2 ($i) TO NUM.',
      ];
      final SemanticResult repeated = runJob(
        data: fields,
        procedure: [...distinct, ...distinct],
      );
      // The repeat of all 90 pairs costs nothing: the counter dedups by
      // array-and-notation, not by reference count.
      expect(ids(repeated), isEmpty);

      final SemanticResult capped = runJob(
        data: fields,
        procedure: [
          ...distinct,
          ...distinct,
          '            MOVE TAB CELL (46) TO NUM.',
        ],
      );
      expect(ids(capped), ['184,00']);
    });

    test('the 51st index expression draws 183,00', () {
      final List<String> procedure = [
        for (var i = 1; i <= 51; i++)
          '            MOVE TAB CELL (IDX + $i) TO NUM.',
      ];
      final SemanticResult capped = runJob(
        data: _fields(),
        procedure: procedure,
      );
      expect(ids(capped), ['183,00']);
      expect(capped.stopped, isTrue);
      final SemanticResult lifted = runJob(
        data: _fields(),
        procedure: procedure,
        tableLimits: false,
      );
      expect(ids(lifted), isEmpty);
      expect(lifted.stopped, isFalse);
    });
  });
}
