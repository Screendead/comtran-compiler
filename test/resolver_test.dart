/// The M3 stage-2 dictionary and resolver core: the dictionary build
/// (M3-17), the reference triage (M3-17), the CALL pass (D4.13), the
/// condition-name checks (M3-17), and their diagnostics (M3-21).
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

SemanticResult _resolve(
  List<String> data, {
  List<String> environment = const [],
  List<String> procedure = const [],
  bool pedantic = false,
  bool tableLimits = true,
}) {
  final lines = [
    '      *DATA',
    ...data,
    if (environment.isNotEmpty) '      *ENVIRONMENT',
    ...environment,
    if (procedure.isNotEmpty) '      *PROCEDURE',
    ...procedure,
  ];
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  final ParseResult parse = runParser(runFrontEnd(deck));
  return runSemantics(parse, pedantic: pedantic, tableLimits: tableLimits);
}

List<String> _ids(SemanticResult result) => [
  for (final Diagnostic d in result.semanticDiagnostics) d.message.number,
];

/// The resolved item a reference to [name] landed on.
DataItem _resolved(SemanticResult result, String name) => result
    .dataResolutions
    .values
    .firstWhere((DataItem item) => item.entry.name == name);

String _fileCard(String name, String options) =>
    environmentCard(name: name, type: 'FILE', options: options);

void main() {
  group('the dictionary (M3-17)', () {
    test('names enter with their kind and encounter number '
        '(J 90.02.02)', () {
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'C', level: '2', description: 'A(6)'),
          dataCard(name: 'R2', level: '1', type: 'RECORD'),
          dataCard(name: 'C', level: '2', description: 'A(6)'),
        ],
        environment: [
          _fileCard('FIN', 'INPUT,BCD,TAPE,R1,BLOCKSIZE 5'),
          _fileCard('FOUT', 'OUTPUT,BCD,TAPE,R2,BLOCKSIZE 5'),
        ],
        procedure: ['      LOOP.       DISPLAY R1 C.'],
      );
      expect(_ids(result), isEmpty);
      final Dictionary dictionary = result.dictionary;
      expect(
        [for (final DictionaryEntry e in dictionary.named('C')) e.encounter],
        [1, 2],
      );
      expect(dictionary.named('R1').single.kind, NameKind.record);
      expect(dictionary.named('FIN').single.kind, NameKind.environment);
      expect(dictionary.named('LOOP').single.kind, NameKind.statement);
    });

    test('a discarded REDEF-line name never enters (D3.4)', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'A', level: '1', description: 'A(4)'),
        dataCard(name: 'GHOST', type: 'REDEF', description: 'A'),
        dataCard(name: 'B', level: '1', description: 'A(4)'),
      ]);
      expect(result.dictionary.named('GHOST'), isEmpty);
    });

    test('a duplicate RECORD name draws 166,00 (D2.5)', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'R1', level: '1', type: 'RECORD'),
        dataCard(name: 'A', level: '2', description: 'A(6)'),
        dataCard(name: 'R1', level: '1', type: 'RECORD'),
        dataCard(name: 'B', level: '2', description: 'A(6)'),
      ]);
      expect(_ids(result), ['166,00']);
    });

    test('a duplicate label in one section scope draws 166,00 '
        '(D2.5)', () {
      final SemanticResult result = _resolve(
        const [],
        procedure: [
          "      TWICE.      DISPLAY 'A'.",
          "      TWICE.      DISPLAY 'B'.",
          '            STOP RUN.',
        ],
      );
      expect(_ids(result), ['166,00']);
    });

    test('the same label in two sections is legal (D2.5)', () {
      final SemanticResult result = _resolve(
        const [],
        procedure: [
          '      S1.         BEGIN SECTION.',
          "      HERE.X.     DISPLAY 'A'.",
          '            END S1.',
          '      S2.         BEGIN SECTION.',
          "      HERE.X.     DISPLAY 'B'.",
          '            END S2.',
          '            STOP RUN.',
        ],
      );
      expect(_ids(result), isEmpty);
    });

    test('a label that is a key word draws 61,00', () {
      final SemanticResult result = _resolve(
        const [],
        procedure: ["      RECORD.     DISPLAY 'A'.", '            STOP RUN.'],
      );
      expect(_ids(result), ['61,00']);
    });

    test('a list-3 word as a label draws no 61,00 (J 02.03.03)', () {
      // "may be used as Procedure and Data names providing it is not
      // necessary to reference the ... items in the Environment
      // Division"; msg 152 covers the environment-used case.
      final SemanticResult result = _resolve(
        const [],
        procedure: ["      HOLD.       DISPLAY 'A'.", '            STOP RUN.'],
      );
      expect(_ids(result), isEmpty);
    });

    test('PROGRAM.START as a data name draws 142,00 (D2.1)', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'PROGRAM.START', level: '1', description: 'A(2)'),
      ]);
      expect(_ids(result), ['142,00']);
    });

    test('a name equal to a used list-3 word draws 152,00 (M2-7)', () {
      final List<String> data = [
        dataCard(name: 'R1', level: '1', type: 'RECORD'),
        dataCard(name: 'BLOCKSIZE', level: '2', description: 'A(6)'),
      ];
      final SemanticResult used = _resolve(
        data,
        environment: [_fileCard('FIN', 'INPUT,BCD,TAPE,R1,BLOCKSIZE 5')],
      );
      expect(_ids(used), ['152,00']);
      // Without the word in the Environment Division the name is free
      // (J 02.03.03).
      expect(_ids(_resolve(data)), isEmpty);
    });

    test('a RECORD entry after leading description draws 197,00', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'STRAY', level: '2', description: 'A(6)'),
        dataCard(name: 'R1', level: '1', type: 'RECORD'),
        dataCard(name: 'A', level: '2', description: 'A(6)'),
      ]);
      expect(_ids(result), ['197,00']);
    });

    test('the 3501st name draws 942,00 and stops; --no-table-limits '
        'lifts it (D9.7)', () {
      final List<String> data = [
        for (var i = 0; i < 3501; i++)
          dataCard(name: 'N$i', level: '1', description: 'A'),
      ];
      final SemanticResult capped = _resolve(data);
      expect(_ids(capped), ['942,00']);
      expect(capped.stopped, isTrue);
      final SemanticResult lifted = _resolve(data, tableLimits: false);
      expect(_ids(lifted), isEmpty);
      expect(lifted.stopped, isFalse);
    });
  });

  group('the triage (M3-17)', () {
    test('a reference declared nowhere draws 108,00', () {
      final SemanticResult result = _resolve(
        [dataCard(name: 'T', level: '1', description: 'A(2)')],
        procedure: ['            MOVE MISSING TO T.'],
      );
      expect(_ids(result), ['108,00']);
      // The site is inside clause 1 (M2-6).
      expect(result.semanticDiagnostics.single.clause, 1);
    });

    test('a declared name with a wrong qualifier chain draws '
        '101,00', () {
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'A', level: '1'),
          dataCard(name: 'B', level: '2', description: 'A(2)'),
          dataCard(name: 'T', level: '1', description: 'A(2)'),
        ],
        procedure: ['            MOVE T B TO T.'],
      );
      expect(_ids(result), ['101,00']);
    });

    test('an ambiguous reference draws 166,00; qualification resolves '
        'it (F p. 15)', () {
      final List<String> data = [
        dataCard(name: 'OLDREC', level: '1'),
        dataCard(name: 'MONTH', level: '2', description: '99'),
        dataCard(name: 'NEWREC', level: '1'),
        dataCard(name: 'MONTH', level: '2', description: '99'),
        dataCard(name: 'T', level: '1', description: '99'),
      ];
      final SemanticResult bare = _resolve(
        data,
        procedure: ['            MOVE MONTH TO T.'],
      );
      expect(_ids(bare), ['166,00']);
      final SemanticResult qualified = _resolve(
        data,
        procedure: ['            MOVE OLDREC MONTH TO T.'],
      );
      expect(_ids(qualified), isEmpty);
      expect(_resolved(qualified, 'MONTH').parent!.entry.name, 'OLDREC');
    });

    test('qualification skips intermediate levels (F p. 16)', () {
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'A', level: '1'),
          dataCard(name: 'B', level: '2'),
          dataCard(name: 'C', level: '3', description: 'A(2)'),
          dataCard(name: 'T', level: '1', description: 'A(2)'),
        ],
        procedure: ['            MOVE A C TO T.'],
      );
      expect(_ids(result), isEmpty);
      expect(_resolved(result, 'C').parent!.entry.name, 'B');
    });

    test('qualification is REDEF-blind: the qualified name of H is '
        'A G H (J 02.05.02)', () {
      // EXAMPLE 1 of J 02.05.02, formats added to give leaves length.
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'A', level: '1'),
          dataCard(name: 'B', level: '2'),
          dataCard(name: 'C', level: '3', description: 'A(2)'),
          dataCard(name: 'D', level: '3', description: 'A(2)'),
          dataCard(name: 'E', level: '2'),
          dataCard(name: 'F', level: '3', description: 'A(4)'),
          dataCard(type: 'REDEF', description: 'B'),
          dataCard(name: 'G', level: '2'),
          dataCard(type: 'REDEF', description: 'C'),
          dataCard(name: 'H', level: '3', description: 'A(2)'),
          dataCard(name: 'T', level: '1', description: 'A(2)'),
        ],
        procedure: ['            MOVE A G H TO T.'],
      );
      // The REDEF-between-levels advisory (104,00) fires on the
      // example's own structure per its attested criterion (D9.11);
      // the resolution itself is silent.
      expect(_ids(result).where((String id) => id != '104,00'), isEmpty);
      final DataItem h = _resolved(result, 'H');
      expect(h.parent!.entry.name, 'G');
      expect(h.parent!.parent!.entry.name, 'A');
    });

    test('an environment name at a data site draws 25,00', () {
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'T', level: '2', description: 'A(6)'),
        ],
        environment: [_fileCard('FIN', 'INPUT,BCD,TAPE,R1,BLOCKSIZE 5')],
        procedure: ['            MOVE FIN TO T.'],
      );
      expect(_ids(result), ['25,00']);
    });

    test('a condition name at a data site draws 25,00 (D5.6)', () {
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'STATUS', level: '1', description: 'A'),
          dataCard(name: 'WED', level: '2', type: 'COND', description: "'M'"),
          dataCard(name: 'T', level: '1', description: 'A'),
        ],
        procedure: ['            MOVE WED TO T.'],
      );
      expect(_ids(result), ['25,00']);
    });
  });

  group('the CALL pass (D4.13)', () {
    List<String> callData() => [
      dataCard(name: 'MASTER', level: '1'),
      dataCard(name: 'EMPNO', level: '2', description: '9(5)'),
      dataCard(name: 'DETAIL', level: '1'),
      dataCard(name: 'EMPNO', level: '2', description: '9(5)'),
      dataCard(name: 'T', level: '1', description: '9(5)'),
    ];

    test('a synonym resolves unqualified thereafter (J 02.03.03)', () {
      final SemanticResult result = _resolve(
        callData(),
        procedure: [
          '            CALL (MASTER EMPNO) M.NO.',
          '            MOVE M.NO TO T.',
        ],
      );
      expect(_ids(result), isEmpty);
      final DataItem field = _resolved(result, 'EMPNO');
      expect(field.parent!.entry.name, 'MASTER');
      expect(result.dictionary.synonym('M.NO')!.item, same(field));
    });

    test('a qualified reference ending in a synonym draws 101,00', () {
      final SemanticResult result = _resolve(
        callData(),
        procedure: [
          '            CALL (MASTER EMPNO) M.NO.',
          '            MOVE MASTER M.NO TO T.',
        ],
      );
      expect(_ids(result), ['101,00']);
    });

    test('a non-unique old.name draws 166,00 and defines nothing', () {
      final SemanticResult result = _resolve(
        callData(),
        procedure: ['            CALL (EMPNO) M.NO.'],
      );
      expect(_ids(result), ['166,00']);
      expect(result.dictionary.synonym('M.NO'), isNull);
    });

    test('an undefined old.name draws 108,00', () {
      final SemanticResult result = _resolve(
        callData(),
        procedure: ['            CALL (NOWHERE) M.NO.'],
      );
      expect(_ids(result), ['108,00']);
    });

    test('a subscripted old.name draws 936,00 and drops the pair '
        '(J 90.01.01)', () {
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'ARR', level: '1', quantity: '3', description: '99'),
          dataCard(name: 'T', level: '1', description: '99'),
        ],
        procedure: ['            CALL (ARR(2)) ONE.'],
      );
      expect(_ids(result), ['936,00']);
      expect(result.dictionary.synonym('ONE'), isNull);
    });

    test('a synonym equal to an existing name draws 166,00', () {
      final SemanticResult result = _resolve(
        callData(),
        procedure: ['            CALL (MASTER EMPNO) T.'],
      );
      expect(_ids(result), ['166,00']);
    });

    test('--pedantic notes a record.name old.name with 945,00', () {
      final List<String> data = [
        dataCard(name: 'R1', level: '1', type: 'RECORD'),
        dataCard(name: 'A', level: '2', description: 'A(6)'),
      ];
      final procedure = ['            CALL (R1) SHADOW.'];
      final SemanticResult plain = _resolve(data, procedure: procedure);
      expect(_ids(plain), isEmpty);
      final SemanticResult noted = _resolve(
        data,
        procedure: procedure,
        pedantic: true,
      );
      expect(_ids(noted), ['945,00']);
      // The synonym stands in both modes (D11.4).
      expect(noted.dictionary.synonym('SHADOW'), isNotNull);
      expect(plain.dictionary.synonym('SHADOW'), isNotNull);
    });
  });

  group('condition names (M3-17)', () {
    test('a condition reference resolves to its COND entry', () {
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'STATUS', level: '1', description: 'A'),
          dataCard(name: 'WED', level: '2', type: 'COND', description: "'M'"),
        ],
        procedure: ['            IF WED THEN STOP RUN.'],
      );
      expect(_ids(result), isEmpty);
      expect(result.dataResolutions.values.single.typeCode, DataTypeCode.cond);
    });

    test('an environment COND name is a keys condition '
        '(J 02.06.17)', () {
      final SemanticResult result = _resolve(
        const [],
        environment: [
          environmentCard(name: 'SENSE', type: 'COND', options: "KEYS '77'"),
        ],
        procedure: ['            IF SENSE THEN STOP RUN.'],
      );
      expect(_ids(result), isEmpty);
      expect(result.keysConditions, hasLength(1));
    });

    test('a non-condition in condition position draws 25,00', () {
      final SemanticResult result = _resolve(
        [dataCard(name: 'PLAIN', level: '1', description: '99')],
        procedure: ['            IF PLAIN THEN STOP RUN.'],
      );
      expect(_ids(result), ['25,00']);
    });

    test('SET of a non-condition draws 191,00', () {
      final SemanticResult result = _resolve(
        [dataCard(name: 'PLAIN', level: '1', description: '99')],
        procedure: ['            SET PLAIN.'],
      );
      expect(_ids(result), ['191,00']);
    });

    test('a COND under a formatless variable draws 37,00 '
        '(J 02.05.02)', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'GROUPV', level: '1'),
        dataCard(name: 'ON', level: '2', type: 'COND', description: "'Y'"),
        dataCard(name: 'PAD', level: '2', description: 'A'),
      ]);
      expect(_ids(result), ['37,00']);
    });

    test('a COND constant that cannot match the format draws 37,00 '
        '(J 02.05.07)', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'CODE', level: '1', mode: 'E', description: '999'),
        dataCard(name: 'LOW', level: '2', type: 'COND', description: "'12'"),
      ]);
      expect(_ids(result), ['37,00']);
    });

    test('a matching COND constant is silent', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'CODE', level: '1', mode: 'E', description: '999'),
        dataCard(name: 'LOW', level: '2', type: 'COND', description: "'123'"),
      ]);
      expect(_ids(result), isEmpty);
    });
  });

  group('stray description names (J 02.05.06 e)', () {
    test('an unresolvable stray name draws 185,00', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'X', level: '1', description: 'NOSUCH'),
      ]);
      expect(_ids(result), contains('185,00'));
    });

    test('a stray name that resolves stays silent', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'PRICE.X', level: '1', description: 'A(2)'),
        dataCard(name: 'X', level: '1', description: 'A(2) PRICE.X'),
      ]);
      expect(_ids(result), isEmpty);
    });

    test('a stray name equal only to an environment name draws '
        '185,00', () {
      // "a data, key, or a procedure name" (J 02.05.06 e) — a file
      // name is none of the three.
      final SemanticResult result = _resolve(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'X', level: '2', description: 'A(2) FIN'),
        ],
        environment: [_fileCard('FIN', 'INPUT,BCD,TAPE,R1,BLOCKSIZE 5')],
      );
      expect(_ids(result), ['185,00']);
    });

    test('unclaimed description tokens draw 185,00', () {
      final SemanticResult result = _resolve([
        dataCard(name: 'X', level: '1', description: "A(2) 'AB' 'CD'"),
      ]);
      expect(_ids(result), ['185,00']);
    });
  });
}
