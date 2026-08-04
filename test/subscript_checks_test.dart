/// The M3 stage-2 subscript reference checks (M3-20): the dimension
/// rows, the subscript-variable format rows (F p. 31; D9.11), the
/// 1-origin literal rule (J 02.04.07.01), and the two D9.7 counters.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

SemanticResult _resolve(
  List<String> data, {
  List<String> procedure = const [],
  bool tableLimits = true,
}) {
  final lines = [
    '      *DATA',
    ...data,
    if (procedure.isNotEmpty) '      *PROCEDURE',
    ...procedure,
  ];
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return runSemantics(runParser(runFrontEnd(deck)), tableLimits: tableLimits);
}

List<String> _ids(SemanticResult result) => [
  for (final Diagnostic d in result.semanticDiagnostics) d.message.number,
];

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

SemanticResult _move(String subscripted) =>
    _resolve(_fields(), procedure: ['            MOVE $subscripted TO NUM.']);

void main() {
  group('subscript references (M3-20)', () {
    test('a matching subscript count draws nothing', () {
      final SemanticResult result = _move('TAB CELL (IDX)');
      expect(_ids(result), isEmpty);
    });

    test('an unsubscripted array reference draws nothing', () {
      final SemanticResult result = _resolve(
        _fields(),
        procedure: ['            MOVE ALPHA TO ALPHA.'],
      );
      expect(_ids(result), isEmpty);
    });

    test('a subscripted reference to a flat item draws 98,00', () {
      final SemanticResult result = _resolve(
        _fields(),
        procedure: ['            MOVE ALPHA (IDX) TO ALPHA.'],
      );
      expect(_ids(result), ['98,00']);
      // The site is inside clause 1 (M2-6).
      expect(result.semanticDiagnostics.single.clause, 1);
      expect(result.semanticDiagnostics.single.operands, ['ALPHA']);
    });

    test('a subscript count above the dimension count draws 70,00', () {
      final SemanticResult result = _move('TAB CELL (IDX, IDX)');
      expect(_ids(result), ['70,00']);
      expect(result.semanticDiagnostics.single.operands, ['TAB CELL']);
    });

    test('a subscripted subscript variable draws 71,00', () {
      final SemanticResult result = _move('TAB CELL (TAB CELL (IDX))');
      expect(_ids(result), ['71,00']);
      // NAME.1 is the array, not the variable (J 90.04).
      expect(result.semanticDiagnostics.single.operands, ['TAB CELL']);
    });

    test('a condition-name subscript draws 71,00', () {
      final SemanticResult result = _resolve(
        [
          ..._fields(),
          dataCard(name: 'STATUS', level: '1', description: 'A'),
          dataCard(name: 'WED', level: '2', type: 'COND', description: "'M'"),
        ],
        procedure: ['            MOVE TAB CELL (WED) TO NUM.'],
      );
      expect(_ids(result), ['71,00']);
    });

    test('an alphameric subscript variable draws 79,00', () {
      final SemanticResult result = _move('TAB CELL (ALPHA)');
      expect(_ids(result), ['79,00']);
      expect(result.semanticDiagnostics.single.operands, ['ALPHA']);
    });

    test('a fractional subscript variable draws 31,00', () {
      final SemanticResult result = _move('TAB CELL (FRAC)');
      expect(_ids(result), ['31,00']);
    });

    test('a zero, negative, or fractional literal draws 182,00', () {
      final SemanticResult result = _resolve(
        _fields(),
        procedure: [
          '            MOVE TAB CELL (0) TO NUM.',
          '            MOVE TAB CELL (-1) TO NUM.',
          '            MOVE TAB CELL (1.5) TO NUM.',
        ],
      );
      expect(_ids(result), ['182,00', '182,00', '182,00']);
    });

    test('a whole positive literal subscript draws nothing', () {
      final SemanticResult result = _move('TAB CELL (3)');
      expect(_ids(result), isEmpty);
    });

    test('an external decimal subscript variable draws 206,00', () {
      final SemanticResult result = _move('TAB CELL (EXT)');
      expect(_ids(result), ['206,00']);
      expect(messageSeverities['206,00'], 1);
    });
  });

  group('the subscript counters (D9.7)', () {
    test('the 91st positional indicator draws 184,00', () {
      final List<String> procedure = [
        for (var i = 1; i <= 91; i++) '            MOVE TAB CELL ($i) TO NUM.',
      ];
      final SemanticResult capped = _resolve(_fields(), procedure: procedure);
      expect(_ids(capped), ['184,00']);
      expect(capped.stopped, isTrue);
      final SemanticResult lifted = _resolve(
        _fields(),
        procedure: procedure,
        tableLimits: false,
      );
      expect(_ids(lifted), isEmpty);
      expect(lifted.stopped, isFalse);
    });

    test('one array read two ways is two indicators (J 02.04.07)', () {
      final SemanticResult result = _resolve(
        _fields(),
        procedure: [
          '            MOVE TAB CELL (IDX) TO NUM.',
          '            MOVE TAB CELL (IDX) TO NUM.',
          '            MOVE TAB CELL (IDX + 1) TO NUM.',
        ],
      );
      // Two distinct notations over one array, so the repeat of the
      // first costs nothing; without the pair key all three would.
      expect(_ids(result), isEmpty);
    });

    test('the 51st index expression draws 183,00', () {
      final List<String> procedure = [
        for (var i = 1; i <= 51; i++)
          '            MOVE TAB CELL (IDX + $i) TO NUM.',
      ];
      final SemanticResult capped = _resolve(_fields(), procedure: procedure);
      expect(_ids(capped), ['183,00']);
      expect(capped.stopped, isTrue);
      final SemanticResult lifted = _resolve(
        _fields(),
        procedure: procedure,
        tableLimits: false,
      );
      expect(_ids(lifted), isEmpty);
      expect(lifted.stopped, isFalse);
    });
  });
}
