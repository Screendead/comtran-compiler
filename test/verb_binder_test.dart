/// The M3 stage-2 I/O verb binding map (M3-18): the GET, FILE, OPEN,
/// and CLOSE sites, the FILE-card names that need the data map, the
/// POOL and GROUP buffer minimums, the LABEL and variable-array rows,
/// and the base-locator counter (D9.7).
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// One FILE card, its options split across continuation cards when
/// they overrun the 41-column option field.
List<String> _fileCards(String name, List<String> options) {
  final chunks = <String>[];
  for (final option in options) {
    if (chunks.isNotEmpty && chunks.last.length + option.length + 2 <= 41) {
      chunks[chunks.length - 1] = '${chunks.last},$option';
    } else {
      chunks.add(option);
    }
  }
  return [
    for (final (int i, String chunk) in chunks.indexed)
      environmentCard(
        name: i == 0 ? name : '',
        type: i == 0 ? 'FILE' : '',
        options: i == chunks.length - 1 ? chunk : '$chunk,',
        continued: i < chunks.length - 1,
      ),
  ];
}

/// The standard FILE card of one direction: BCD tape, blocksize 5,
/// with [records] and their per-record options between.
List<String> _inputFile(String name, List<String> records) =>
    _fileCards(name, ['INPUT', 'BCD', 'TAPE', ...records, 'BLOCKSIZE 5']);

List<String> _outputFile(String name, List<String> records) =>
    _fileCards(name, ['OUTPUT', 'BCD', 'TAPE', ...records, 'BLOCKSIZE 5']);

/// One record entry with one field — the least a FILE card can bind.
List<String> _record(String name, {String description = 'A(6)'}) => [
  dataCard(name: name, level: '1', type: 'RECORD'),
  dataCard(name: '${name}F', level: '2', description: description),
];

/// The environment cards of the compiled job, in source order.
List<EnvironmentCard> _cards(SemanticResult result) => [
  for (final ParsedGroup group in result.parse.groups)
    if (group is ParsedEnvironmentGroup) ...group.cards,
];

void main() {
  group('the verb sites (M3-18)', () {
    test('a GET operand that names nothing draws 8,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        procedure: ['            GET NOWHERE.'],
      );
      expect(ids(result), ['8,00']);
      // The site is inside clause 1 (M2-6).
      expect(result.semanticDiagnostics.single.clause, 1);
    });

    test('a GET operand that names a field draws 16,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        procedure: ['            GET R1F.'],
      );
      expect(ids(result), ['16,00']);
    });

    test('a GET through a record synonym binds like the record '
        '(J 02.03.03)', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('FIN', ['R1']),
        procedure: ['            CALL (R1) SYN.', '            GET SYN.'],
      );
      expect(ids(result), isEmpty);
    });

    test('a GET of a condition name draws 8,00', () {
      final SemanticResult result = runJob(
        data: [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'R1F', level: '2', description: 'A(2)'),
          dataCard(name: 'WED', level: '3', type: 'COND', description: "'AB'"),
        ],
        procedure: ['            GET WED.'],
      );
      expect(ids(result), ['8,00']);
    });

    test('a GET of a record on no FILE card draws 9,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        procedure: ['            GET R1.'],
      );
      expect(ids(result), ['9,00']);
    });

    test('a GET of a record on an output file only draws 10,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _outputFile('FOUT', ['R1']),
        procedure: ['            GET R1.', '            FILE R1.'],
      );
      expect(ids(result), ['10,00']);
    });

    test('a FILE of a record on no output file draws 19,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('FIN', ['R1']),
        procedure: ['            GET R1.', '            FILE R1.'],
      );
      expect(ids(result), ['19,00']);
    });

    test('OPEN and CLOSE of a name that is no file draw 21,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        procedure: ['            OPEN NOWHERE.', '            CLOSE NOWHERE.'],
      );
      expect(ids(result), ['21,00', '21,00']);
    });

    test('a FILE IN an input file draws 22,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('FIN', ['R1']),
        procedure: ['            FILE R1 IN FIN.'],
      );
      expect(ids(result), ['22,00']);
    });

    test('a FILE IN a file whose card lacks the record draws 195,00', () {
      final SemanticResult result = runJob(
        data: [..._record('R1'), ..._record('R2')],
        environment: [
          ..._outputFile('FOUT1', ['R1']),
          ..._outputFile('FOUT2', ['R2']),
        ],
        procedure: [
          '            FILE R1 IN FOUT1.',
          '            FILE R1 IN FOUT2.',
        ],
      );
      expect(ids(result), ['195,00']);
      // The text prints NAME.2 before NAME.1; the operands stay in
      // NAME.n order (J 90.04.01).
      expect(
        result.semanticDiagnostics.single.text,
        startsWith("CANNOT FILE RECORD 'R1' IN THIS FILE,\n"),
      );
      expect(result.semanticDiagnostics.single.text, contains("'FOUT2'"));
    });

    test('a file no verb processes draws 198,00', () {
      final SemanticResult result = runJob(
        data: [..._record('R1'), ..._record('R2')],
        environment: [
          ..._inputFile('FIN', ['R1']),
          ..._outputFile('FOUT', ['R2']),
        ],
        procedure: ['            GET R1.'],
      );
      expect(ids(result), ['198,00']);
      expect(result.semanticDiagnostics.single.text, contains("'FOUT'"));
    });

    test('FILE x files only where PRIMARY is stated (J 02.07.07)', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: [
          ..._outputFile('FOUT1', ['R1', 'PRIMARY']),
          ..._outputFile('FOUT2', ['R1']),
        ],
        procedure: ['            FILE R1.'],
      );
      expect(ids(result), ['198,00']);
      expect(result.semanticDiagnostics.single.text, contains("'FOUT2'"));
    });

    test('a GET binds through a FILE card that lacks a name (msg 1,00)', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('', ['R1']),
        procedure: ['            GET R1.'],
      );
      expect(ids(result), isEmpty);
      expect([
        for (final Diagnostic d in result.diagnostics) d.message.number,
      ], contains('1,00'));
    });

    test('a job with no GET and no FILE draws no 198,00 row', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('FIN', ['R1']),
        procedure: ['            STOP RUN.'],
      );
      expect(ids(result), isEmpty);
    });
  });

  group('GET RECORD FROM (M3-18; J 02.07.04)', () {
    List<String> data() => [
      ..._record('R1'),
      ..._record('R2'),
      dataCard(name: 'LEN', level: '1', description: '9(4)'),
    ];

    test('a GET RECORD FROM a name that is no file draws 23,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        procedure: ['            GET RECORD FROM NOWHERE.'],
      );
      expect(ids(result), ['23,00']);
    });

    test('a GET RECORD FROM an output file draws 14,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _outputFile('FOUT', ['R1']),
        procedure: ['            GET RECORD FROM FOUT.'],
      );
      expect(ids(result), ['14,00']);
    });

    test('records of unequal fixed length draw 12,00', () {
      final SemanticResult result = runJob(
        data: [
          ..._record('R1'),
          ..._record('R2', description: 'A(12)'),
        ],
        environment: _inputFile('FIN', ['R1', 'R2']),
        procedure: ['            GET RECORD FROM FIN.'],
      );
      expect(ids(result), ['12,00']);
    });

    test('records of one fixed length are silent (J 02.07.04 a)', () {
      final SemanticResult result = runJob(
        data: [..._record('R1'), ..._record('R2')],
        environment: _inputFile('FIN', ['R1', 'R2']),
        procedure: ['            GET RECORD FROM FIN.'],
      );
      expect(ids(result), isEmpty);
    });

    test('records of one length related by REDEF are silent', () {
      // The overlaying record owns no storage space, so its length is
      // not its space's (J 02.07.05 c-iii relates the two).
      final SemanticResult result = runJob(
        data: [
          ..._record('R1', description: 'A(10)'),
          dataCard(type: 'REDEF', description: 'R1'),
          ..._record('R2', description: 'A(10)'),
        ],
        environment: _inputFile('FIN', ['R1', 'R2']),
        procedure: ['            GET RECORD FROM FIN.'],
      );
      expect(ids(result), isEmpty);
    });

    test('BEGIN rescues unequal lengths (J 02.07.04 b)', () {
      final SemanticResult result = runJob(
        data: [
          ..._record('R1'),
          ..._record('R2', description: 'A(12)'),
        ],
        environment: _inputFile('FIN', ['R1', 'R2', 'BEGIN']),
        procedure: ['            GET RECORD FROM FIN.'],
      );
      expect(ids(result), isEmpty);
    });

    test('FIND LENGTH IN on one record of two draws 117,00', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: _inputFile('FIN', ['R1', 'FIND LENGTH IN LEN', 'R2']),
        procedure: ['            GET RECORD FROM FIN.'],
      );
      expect(ids(result), ['117,00']);
    });

    test('PLACE LENGTH IN on one record of two draws 118,00', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: _inputFile('FIN', ['R1', 'PLACE LENGTH IN LEN', 'R2']),
        procedure: ['            GET RECORD FROM FIN.'],
      );
      expect(ids(result), ['118,00']);
    });

    test('BLOCK CONTROL on one record of two draws 121,00', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: _inputFile('FIN', ['R1', 'BLOCK CONTROL', 'R2']),
        procedure: ['            GET RECORD FROM FIN.'],
      );
      expect(ids(result), ['121,00']);
    });

    test('a non-uniform option is reported once per file', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: _inputFile('FIN', ['R1', 'BLOCK CONTROL', 'R2']),
        procedure: [
          '            GET RECORD FROM FIN.',
          '            GET RECORD FROM FIN.',
        ],
      );
      expect(ids(result), ['121,00']);
    });
  });

  group('FILE-card names (M3-18)', () {
    test('FIND LENGTH IN an alphameric field draws 111,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('FIN', ['R1', 'FIND LENGTH IN R1F']),
        procedure: ['            GET R1.'],
      );
      expect(ids(result), ['111,00']);
    });

    test('FIND LENGTH IN resolves a CALL synonym (J 02.03.03)', () {
      final SemanticResult result = runJob(
        data: [
          ..._record('R1'),
          dataCard(name: 'HDR', level: '1', type: 'RECORD'),
          dataCard(name: 'LEN', level: '2', mode: 'I', description: '99'),
        ],
        environment: _inputFile('FIN', ['R1', 'FIND LENGTH IN M.LEN']),
        procedure: ['            CALL (HDR LEN) M.LEN.', '            GET R1.'],
      );
      expect(ids(result), isEmpty);
    });

    test('PLACE LENGTH IN an alphameric field draws 112,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('FIN', ['R1', 'PLACE LENGTH IN R1F']),
        procedure: ['            GET R1.'],
      );
      expect(ids(result), ['112,00']);
    });

    test('a decimal length field without fraction positions is silent', () {
      final SemanticResult result = runJob(
        data: [
          ..._record('R1'),
          dataCard(name: 'LEN', level: '1', description: '99'),
        ],
        environment: _inputFile('FIN', ['R1', 'FIND LENGTH IN LEN']),
        procedure: ['            GET R1.'],
      );
      expect(ids(result), isEmpty);
    });

    test('an ON ERROR name that names no procedure draws 108,00', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('FIN', ['R1', 'ON ERROR NOWHERE']),
        procedure: ['            GET R1.'],
      );
      expect(ids(result), ['108,00']);
    });

    test('a FOR LABEL name that labels a statement is silent', () {
      final SemanticResult result = runJob(
        data: _record('R1'),
        environment: _inputFile('FIN', ['R1', 'FOR LABEL FIXUP']),
        procedure: ['            GET R1.', '      FIXUP.      STOP RUN.'],
      );
      expect(ids(result), isEmpty);
    });
  });

  group('POOL and GROUP buffers (M3-18; J 02.06.13-14)', () {
    List<String> data() => [..._record('R1'), ..._record('R2')];

    List<String> files() => [
      ..._inputFile('FIN', ['R1']),
      ..._outputFile('FOUT', ['R2']),
    ];

    const procedure = ['            GET R1.', '            FILE R2.'];

    PoolCard pool(SemanticResult result) =>
        _cards(result).whereType<PoolCard>().single;

    GroupCard groupCard(SemanticResult result) =>
        _cards(result).whereType<GroupCard>().single;

    test('a POOL BUFFERCOUNT below its file count draws 937,00 and is '
        'raised', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: [
          ...files(),
          environmentCard(
            name: 'P',
            type: 'POOL',
            options: 'FIN,FOUT,BUFFERCOUNT 1',
          ),
        ],
        procedure: procedure,
      );
      expect(ids(result), ['937,00']);
      expect(pool(result).bufferCount, 2);
    });

    test('a POOL BUFFERCOUNT below its groups draws 937,00', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: [
          ...files(),
          environmentCard(
            name: 'P',
            type: 'POOL',
            options: 'FIN,BUFFERCOUNT 1',
          ),
          environmentCard(type: 'GROUP', options: 'P,BUFFERCOUNT 4,FIN'),
        ],
        procedure: procedure,
      );
      expect(ids(result), ['937,00']);
      expect(pool(result).bufferCount, 4);
    });

    test('a GROUP BUFFERCOUNT below its OPENCOUNT draws 938,00 and is '
        'raised', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: [
          ...files(),
          environmentCard(name: 'P', type: 'POOL', options: 'FIN,FOUT'),
          environmentCard(
            type: 'GROUP',
            options: 'P,OPENCOUNT 2,BUFFERCOUNT 1,FIN,FOUT',
          ),
        ],
        procedure: procedure,
      );
      expect(ids(result), ['938,00']);
      expect(groupCard(result).bufferCount, 2);
    });

    test('the defaulted counts draw nothing (J 02.06.13-14)', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: [
          ...files(),
          environmentCard(name: 'P', type: 'POOL', options: 'FIN,FOUT'),
          environmentCard(type: 'GROUP', options: 'P,FIN,FOUT'),
        ],
        procedure: procedure,
      );
      expect(ids(result), isEmpty);
    });

    test('a defaulted GROUP claims its OPENCOUNT against the pool '
        '(J 02.06.14)', () {
      // The loader's doubled count is an attempt with an express
      // fallback, not a compile-time minimum.
      final SemanticResult result = runJob(
        data: data(),
        environment: [
          ...files(),
          environmentCard(
            name: 'P',
            type: 'POOL',
            options: 'FIN,FOUT,BUFFERCOUNT 2',
          ),
          environmentCard(type: 'GROUP', options: 'P,OPENCOUNT 2,FIN,FOUT'),
        ],
        procedure: procedure,
      );
      expect(ids(result), isEmpty);
    });

    test('a GROUP whose first item is no pool draws 939,00', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: [
          ...files(),
          environmentCard(type: 'GROUP', options: 'FIN,FOUT'),
        ],
        procedure: procedure,
      );
      expect(ids(result), ['939,00']);
    });

    test('a pooled name that is no file draws 21,00', () {
      final SemanticResult result = runJob(
        data: data(),
        environment: [
          ...files(),
          environmentCard(name: 'P', type: 'POOL', options: 'FIN,NOWHERE'),
        ],
        procedure: procedure,
      );
      expect(ids(result), ['21,00']);
    });
  });

  group('the data-division rows (M3-18)', () {
    test('a LABEL area over 14 words draws 940,00 (J 02.05.03)', () {
      final SemanticResult result = runJob(
        data: [
          dataCard(name: 'LBL', level: '1', type: 'LABEL'),
          dataCard(name: 'LBLF', level: '2', description: 'A(96)'),
        ],
      );
      expect(ids(result), ['940,00']);
    });

    test('a LABEL area of exactly 14 words is silent', () {
      final SemanticResult result = runJob(
        data: [
          dataCard(name: 'LBL', level: '1', type: 'LABEL'),
          dataCard(name: 'LBLF', level: '2', description: 'A(84)'),
        ],
      );
      expect(ids(result), isEmpty);
    });

    test('a field after a variable length array draws 941,00 '
        '(J 90.01.04)', () {
      final SemanticResult result = runJob(
        data: [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'CNT', level: '2', description: '99'),
          dataCard(
            name: 'ARR',
            level: '2',
            quantity: '5',
            description: 'A QUANTITY IN CNT',
          ),
          dataCard(name: 'TAIL', level: '2', description: 'A(2)'),
        ],
      );
      expect(ids(result), ['941,00']);
    });

    test('a later field merely sharing the count name draws 941,00', () {
      // Msg 941 yields to the count field itself, not to its name.
      final SemanticResult result = runJob(
        data: [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'CNT', level: '2', description: '99'),
          dataCard(
            name: 'ARR',
            level: '2',
            quantity: '5',
            description: 'A QUANTITY IN CNT',
          ),
          dataCard(name: 'CNT', level: '2', description: '99'),
        ],
      );
      expect(ids(result), ['941,00']);
    });

    test('a field of another hierarchy is silent', () {
      final SemanticResult result = runJob(
        data: [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'CNT', level: '2', description: '99'),
          dataCard(
            name: 'ARR',
            level: '2',
            quantity: '5',
            description: 'A QUANTITY IN CNT',
          ),
          dataCard(name: 'R2', level: '1', type: 'RECORD'),
          dataCard(name: 'TAIL', level: '2', description: 'A(2)'),
        ],
      );
      expect(ids(result), isEmpty);
    });
  });

  group('base locators (D9.7)', () {
    List<String> data(int records) => [
      for (var i = 0; i < records; i++) ..._record('R$i'),
    ];

    List<String> file(int records) =>
        _inputFile('FIN', [for (var i = 0; i < records; i++) 'R$i']);

    test('the 128th located record draws 202,00 and stops; '
        '--no-table-limits lifts it', () {
      final SemanticResult capped = runJob(
        data: data(128),
        environment: file(128),
        procedure: ['            GET R0.'],
      );
      expect(ids(capped), ['202,00']);
      expect(capped.stopped, isTrue);
      final SemanticResult lifted = runJob(
        data: data(128),
        environment: file(128),
        procedure: ['            GET R0.'],
        tableLimits: false,
      );
      expect(ids(lifted), isEmpty);
      expect(lifted.stopped, isFalse);
    });

    test('127 located records stay silent (J 90.01.05 item d)', () {
      final SemanticResult result = runJob(
        data: data(127),
        environment: file(127),
        procedure: ['            GET R0.'],
      );
      expect(ids(result), isEmpty);
    });
  });
}
