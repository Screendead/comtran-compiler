/// The M3 stage-2 reference legality checks (M3-10; M3-21): the MOVE
/// table (J 02.04.03 c), CORRESPONDING pairing (D4.12), the comparison
/// rules (J 02.04.07), the arithmetic-operand rule (J 02.04.05 §6), and
/// the figurative-constant chart (J 02.04.02; D4.6, D4.11).
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

SemanticResult _check(
  List<String> data, {
  List<String> procedure = const [],
  bool pedantic = false,
}) {
  final lines = [
    '      *DATA',
    ...data,
    if (procedure.isNotEmpty) '      *PROCEDURE',
    ...procedure,
  ];
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return runSemantics(runParser(runFrontEnd(deck)), pedantic: pedantic);
}

List<String> _ids(SemanticResult result) => [
  for (final Diagnostic d in result.semanticDiagnostics) d.message.number,
];

/// The matched names of the one CORRESPONDING clause of [result],
/// source name and target name per pair.
List<(String, String)> _pairs(SemanticResult result) => [
  for (final (DataItem from, DataItem to)
      in result.correspondingPairs.values.single)
    (from.entry.name, to.entry.name),
];

/// One alphameric field, one external decimal field, one internal
/// decimal field, and one edited field, all elementary.
List<String> _fields() => [
  dataCard(name: 'ALPHA', level: '1', description: 'A(4)'),
  dataCard(name: 'ALPHA2', level: '1', description: 'A(4)'),
  dataCard(name: 'EXTNUM', level: '1', mode: 'E', description: '999'),
  dataCard(
    name: 'INTNUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(name: 'EDIT', level: '1', description: '8889.99'),
];

/// J 02.04.04 example a: two hierarchies whose qualifier chains agree.
List<String> _exampleA() => [
  dataCard(name: 'DATA.1', level: '1'),
  dataCard(name: 'GROUP.1', level: '2'),
  dataCard(name: 'ITEM', level: '3'),
  dataCard(name: 'FIELD.1', level: '4', description: 'A(2)'),
  dataCard(name: 'FIELD.2', level: '4', description: 'A(2)'),
  dataCard(name: 'DATA.2', level: '1'),
  dataCard(name: 'GROUP.1', level: '2'),
  dataCard(name: 'ITEM', level: '3'),
  dataCard(name: 'FIELD.1', level: '4', description: 'A(2)'),
  dataCard(name: 'FIELD.2', level: '4', description: 'A(2)'),
];

void main() {
  group('the MOVE table (M3-21; J 02.04.03 c)', () {
    test('an alphameric source moved to a numeric target draws '
        '84,00', () {
      final SemanticResult result = _check(
        _fields(),
        procedure: ['            MOVE ALPHA TO EXTNUM.'],
      );
      expect(_ids(result), ['84,00']);
      expect(result.semanticDiagnostics.single.text, contains("FROM 'ALPHA'"));
      expect(result.semanticDiagnostics.single.clause, 1);
    });

    test('a group source is alphameric-class (D3.3)', () {
      final List<String> data = [
        ..._fields(),
        dataCard(name: 'GRP', level: '1'),
        dataCard(name: 'PART', level: '2', description: 'A(2)'),
      ];
      expect(
        _ids(_check(data, procedure: ['            MOVE GRP TO INTNUM.'])),
        ['84,00'],
      );
      expect(
        _ids(_check(data, procedure: ['            MOVE GRP TO ALPHA.'])),
        isEmpty,
      );
    });

    test('a quoted literal source is alphameric-class', () {
      expect(
        _ids(_check(_fields(), procedure: ["            MOVE 'AB' TO EDIT."])),
        ['84,00'],
      );
    });

    test('every type may be moved to an alphameric field', () {
      final SemanticResult result = _check(
        _fields(),
        procedure: [
          '            MOVE EXTNUM TO ALPHA,',
          '            MOVE EDIT TO ALPHA2.',
        ],
      );
      expect(_ids(result), isEmpty);
    });
  });

  group('CORRESPONDING (D4.12; J 02.04.04)', () {
    test('pairs match at the lowest level and are recorded for M4', () {
      final SemanticResult result = _check(
        _exampleA(),
        procedure: ['            MOVE CORRESPONDING DATA.1 TO DATA.2.'],
      );
      expect(_ids(result), isEmpty);
      expect(_pairs(result), [('FIELD.1', 'FIELD.1'), ('FIELD.2', 'FIELD.2')]);
    });

    test('correspondence sees through an unnamed level (D4.12)', () {
      // An unnamed entry contributes no qualifier, so the chains below
      // the roots are identical.
      final List<String> data = [
        dataCard(name: 'DATA.1', level: '1'),
        dataCard(level: '2'),
        dataCard(name: 'FIELD.1', level: '3', description: 'A(2)'),
        dataCard(name: 'DATA.2', level: '1'),
        dataCard(name: 'FIELD.1', level: '2', description: 'A(2)'),
      ];
      const procedure = ['            MOVE CORRESPONDING DATA.1 TO DATA.2.'];
      final SemanticResult result = _check(
        data,
        procedure: procedure,
        pedantic: true,
      );
      expect(_ids(result), isEmpty);
      expect(_pairs(result), [('FIELD.1', 'FIELD.1')]);
    });

    test('a group pairs against an elementary field (example c)', () {
      List<String> data(String description) => [
        dataCard(name: 'DATA.1', level: '1'),
        dataCard(name: 'GROUP.1', level: '2'),
        dataCard(name: 'ITEM', level: '3'),
        dataCard(name: 'FIELD.1', level: '4', description: 'A(2)'),
        dataCard(name: 'FIELD.2', level: '4', description: 'A(2)'),
        dataCard(name: 'DATA.2', level: '1'),
        dataCard(name: 'GROUP.1', level: '2'),
        dataCard(name: 'ITEM', level: '3', description: description),
      ];
      const procedure = ['            MOVE CORRESPONDING DATA.1 TO DATA.2.'];
      final SemanticResult legal = _check(data('A(4)'), procedure: procedure);
      expect(_ids(legal), isEmpty);
      expect(_pairs(legal), [('ITEM', 'ITEM')]);
      // "If DATA.2 GROUP ITEM is a field into which alphameric
      // information may not be legally moved, an error will be noted."
      final SemanticResult illegal = _check(data('9999'), procedure: procedure);
      expect(_ids(illegal), ['84,00']);
    });

    test('an operand that is elementary or unresolved draws 97,00', () {
      expect(
        _ids(
          _check(
            _exampleA(),
            procedure: ['            MOVE CORRESPONDING FIELD.1 TO DATA.2.'],
          ),
        ),
        // The bare FIELD.1 is ambiguous before it is judged elementary.
        ['166,00', '97,00'],
      );
      expect(
        _ids(
          _check(
            _exampleA(),
            procedure: ['            MOVE CORRESPONDING DATA.1 TO NOSUCH.'],
          ),
        ),
        ['108,00', '97,00'],
      );
    });

    test('a missing qualifier breaks correspondence; --pedantic notes '
        'it with 944,00 (example b)', () {
      final List<String> data = [
        dataCard(name: 'DATA.1', level: '1'),
        dataCard(name: 'GROUP.1', level: '2'),
        dataCard(name: 'ITEM', level: '3'),
        dataCard(name: 'FIELD.1', level: '4', description: 'A(2)'),
        dataCard(name: 'DATA.2', level: '1'),
        dataCard(name: 'ITEM', level: '3'),
        dataCard(name: 'FIELD.1', level: '4', description: 'A(2)'),
      ];
      const procedure = ['            MOVE CORRESPONDING DATA.1 TO DATA.2.'];
      final SemanticResult plain = _check(data, procedure: procedure);
      expect(_ids(plain), isEmpty);
      expect(_pairs(plain), isEmpty);
      final SemanticResult noted = _check(
        data,
        procedure: procedure,
        pedantic: true,
      );
      expect(_ids(noted), ['944,00']);
      expect(_pairs(noted), isEmpty);
    });

    test('an alphameric ADD CORRESPONDING pair draws 120,00', () {
      final SemanticResult result = _check(
        [
          dataCard(name: 'SRC', level: '1'),
          dataCard(name: 'X', level: '2', description: 'A(2)'),
          dataCard(name: 'DST', level: '1'),
          dataCard(name: 'X', level: '2', mode: 'E', description: '99'),
        ],
        procedure: ['            ADD CORRESPONDING SRC TO DST.'],
      );
      expect(_ids(result), ['120,00']);
      expect(_pairs(result), [('X', 'X')]);
    });
  });

  group('comparisons (J 02.04.07)', () {
    test('a numeric operand compared to an alphameric operand draws '
        '107,00', () {
      expect(
        _ids(
          _check(
            _fields(),
            procedure: ['            IF ALPHA = EXTNUM THEN STOP RUN.'],
          ),
        ),
        ['107,00'],
      );
    });

    test('an edited operand compares as numeric (rule 3)', () {
      expect(
        _ids(
          _check(
            _fields(),
            procedure: ['            IF EDIT = ALPHA THEN STOP RUN.'],
          ),
        ),
        ['107,00'],
      );
      expect(
        _ids(
          _check(
            _fields(),
            procedure: ['            IF EDIT = INTNUM THEN STOP RUN.'],
          ),
        ),
        isEmpty,
      );
    });

    test('a variable length item in a comparison draws 123,00 '
        '(rule 5)', () {
      final SemanticResult result = _check(
        [
          ..._fields(),
          dataCard(
            name: 'CNT',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '99',
          ),
          dataCard(name: 'VGROUP', level: '1'),
          dataCard(
            name: 'VAR',
            level: '2',
            quantity: '5',
            description: 'A(6) QUANTITY IN CNT',
          ),
        ],
        procedure: ['            IF VAR = ALPHA THEN STOP RUN.'],
      );
      expect(_ids(result), ['123,00']);
    });
  });

  group('arithmetic operands (J 02.04.05 §6)', () {
    test('an alphameric operand inside an expression draws 25,00', () {
      final SemanticResult result = _check(
        _fields(),
        procedure: ['            SET EXTNUM = ALPHA + 1.'],
      );
      expect(_ids(result), ['25,00']);
    });

    test('a pure copy SET of one alphameric field to another is '
        'legal', () {
      final SemanticResult result = _check(
        _fields(),
        procedure: ['            SET ALPHA = ALPHA2.'],
      );
      expect(_ids(result), isEmpty);
    });

    test('an alphameric ADD source or target draws 120,00', () {
      expect(
        _ids(
          _check(_fields(), procedure: ['            ADD ALPHA TO EXTNUM.']),
        ),
        ['120,00'],
      );
      expect(
        _ids(
          _check(_fields(), procedure: ['            ADD EXTNUM TO ALPHA.']),
        ),
        ['120,00'],
      );
    });
  });

  group('figurative constants (J 02.04.02 chart)', () {
    test('HIGH.VALUE moved to an internal decimal field draws '
        '82,00', () {
      expect(
        _ids(
          _check(
            _fields(),
            procedure: ['            MOVE HIGH.VALUE TO INTNUM.'],
          ),
        ),
        ['82,00'],
      );
    });

    test('HIGH.VALUE compared to a numeric field draws 82,00 '
        '(J 02.04.01 b)', () {
      expect(
        _ids(
          _check(
            _fields(),
            procedure: ['            IF EXTNUM = HIGH.VALUE THEN STOP RUN.'],
          ),
        ),
        ['82,00'],
      );
      expect(
        _ids(
          _check(
            _fields(),
            procedure: ['            IF ALPHA = HIGH.VALUE THEN STOP RUN.'],
          ),
        ),
        isEmpty,
      );
    });

    test('ZERO moves and compares everywhere silently', () {
      final SemanticResult result = _check(
        _fields(),
        procedure: [
          '            MOVE ZEROS TO INTNUM,',
          '            MOVE ZEROS TO ALPHA.',
          '            IF ZERO = EXTNUM THEN STOP RUN.',
        ],
      );
      expect(_ids(result), isEmpty);
    });

    test('a figurative constant moved to a variable length field '
        'draws 180,00', () {
      final List<String> data = [
        dataCard(
          name: 'CNT',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: '99',
        ),
        dataCard(name: 'VGROUP', level: '1'),
        dataCard(
          name: 'VAR',
          level: '2',
          quantity: '5',
          description: 'A(6) QUANTITY IN CNT',
        ),
      ];
      expect(
        _ids(_check(data, procedure: ['            MOVE BLANKS TO VAR.'])),
        ['180,00'],
      );
      // "However, figurative constants may be moved to a particular
      // element of a variable length array."
      expect(
        _ids(_check(data, procedure: ['            MOVE BLANKS TO VAR(2).'])),
        isEmpty,
      );
    });

    test('a figurative constant moved to a field over 32766 '
        'characters draws 181,00 (D4.6)', () {
      expect(
        _ids(
          _check(
            [
              dataCard(
                name: 'HUGE',
                level: '1',
                quantity: '4',
                description: 'A(9999)',
              ),
            ],
            procedure: ['            MOVE BLANKS TO HUGE.'],
          ),
        ),
        ['181,00'],
      );
    });

    test('--pedantic notes a doubtful BLANK move with 943,00 '
        '(D4.11)', () {
      const procedure = ['            MOVE BLANKS TO EXTNUM.'];
      expect(_ids(_check(_fields(), procedure: procedure)), isEmpty);
      expect(_ids(_check(_fields(), procedure: procedure, pedantic: true)), [
        '943,00',
      ]);
    });

    test('BLANKS moved to an edited field is silent by default and '
        'draws 943,00 under --pedantic (D4.11)', () {
      const procedure = ['            MOVE BLANKS TO EDIT.'];
      expect(_ids(_check(_fields(), procedure: procedure)), isEmpty);
      expect(_ids(_check(_fields(), procedure: procedure, pedantic: true)), [
        '943,00',
      ]);
    });
  });
}
