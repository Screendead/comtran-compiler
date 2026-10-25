import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

int _octal(String digits) => int.parse(digits, radix: 8);

SemanticResult _payrollSemantics() =>
    compileDeck(loadJobDeck()).jobs.single.semantics!;

void main() {
  group('the assembly text model (M4-3)', () {
    test('one word renders every OCTAL form', () {
      // The three forms space the same twelve octal digits, so the word
      // is the single source the deck, the listing, and the memory
      // image all render.
      final int word = _octal('007400400257');
      expect(octalColumn(word, WordForm.solid), '007400400257');
      expect(octalColumn(word, WordForm.typeB), '0074 00 4 00257');
      expect(octalColumn(word, WordForm.prefix), '0 07400 4 00257');
    });

    test('a location counter control entry carries OP in the prefix', () {
      // J 90.03.04: PTW is a fixed-length BSS whose address holds the
      // length; MON is a relative origin. Both attested in the 90.05
      // storage map: `BSS 2` and `USE 1`.
      expect(
        octalColumn(
          counterWord(CounterOp.fixedReservation, 2),
          WordForm.prefix,
        ),
        '2 00000 0 00002',
      );
      expect(
        octalColumn(
          counterWord(CounterOp.relativeOrigin, _octal('1621')),
          WordForm.prefix,
        ),
        '5 00000 0 01621',
      );
      expect(controlColumn(ControlGroup.locationCounter), '00001');
      expect(controlColumn(ControlGroup.constantWord), '10000');
    });
  });

  group('the program image (M4-4)', () {
    ProgramImage sampleImage() => ProgramImage(
      inlineWords: _octal('1621'),
      blockWords: const <StorageBlock, int>{
        StorageBlock.rs: 30,
        StorageBlock.ts: 7,
        StorageBlock.bl: 3,
        StorageBlock.pi: 3,
      },
    );

    test('every block origin matches the listing, which freezes the order', () {
      // The storage map prints a LOC against each reservation: RS) 30
      // words at 01621, TS) 7 at 01657, BL) 3 at 01666, PI) 3 at 01671.
      // The pool follows at 01674. Asserting all five is what catches a
      // reordering of StorageBlock — asserting only the last two cannot,
      // because summing the blocks above them hides a swap between them.
      final ProgramImage image = sampleImage();
      expect(image.originOf(StorageBlock.rs), _octal('1621'));
      expect(image.originOf(StorageBlock.ts), _octal('1657'));
      expect(image.originOf(StorageBlock.bl), _octal('1666'));
      expect(image.originOf(StorageBlock.pi), _octal('1671'));
      expect(image.originOf(StorageBlock.cp), _octal('1674'));
    });

    test('a generated name counts from one, the pool from zero', () {
      // Attested twice over: `CAL BL)3` assembles 01670, three words
      // into a block whose first word is 01666; `ANA CP)+3` assembles
      // 01677, three past the pool's own first word (D8.8).
      final ProgramImage image = sampleImage();
      expect(image.symbolAddress(StorageBlock.bl, 3), _octal('1670'));
      expect(image.poolAddress(3), _octal('1677'));
    });

    test('the sample needs three base locators', () {
      // One for the IOCS label area, one per located record — the
      // width the listing reserves for BL).
      expect(baseLocatorWords(_payrollSemantics()), 3);
    });

    test('the sample needs three positional indicators', () {
      // RATE (INDEX), INSPREM (POS) and RETPREM (POS), in that order of
      // first reference — the width the listing reserves for PI), and
      // the numbering its PI)1, PI)2 and PI)3 references attest.
      expect(_payrollSemantics().positionalIndicators, hasLength(3));
    });
  });

  group('the object listing geometry (M4-8)', () {
    test('a name of 15 characters prints alone, 14 prints inline', () {
      // The label field is 15 columns, so a 15-character name leaves no
      // space before the operation. The attested 14-character name
      // END.OF.MASTERS prints inline at LOC 00331; INTERNAL.TOTALS, at
      // 15, breaks on PDF p. 200.
      List<String> render(String label) => renderObjectLines(<AssemblyUnit>[
        AssemblyUnit(
          operation: 'OCT',
          operand: '000000000000',
          location: 0,
          labels: <String>[label],
          word: 0,
          control: ControlGroup.constantWord,
        ),
      ]);
      expect(render('ABCDEFGHIJKLMN'), hasLength(1));
      final List<String> broken = render('ABCDEFGHIJKLMNO');
      expect(broken, hasLength(2));
      expect(broken[1].indexOf('OCT'), 49);
    });

    test('two labels on one word print one per line, the word last', () {
      // The attested GN)000 over START at 00165: both lines carry the
      // LOC, and the instruction falls to the second.
      final List<String> lines = renderObjectLines(<AssemblyUnit>[
        AssemblyUnit(
          operation: 'TSX',
          operand: 'SYS)175,4',
          location: _octal('165'),
          labels: const <String>['GN)000', 'START'],
          word: _octal('007400400257'),
          control: 0x12,
          form: WordForm.typeB,
        ),
      ]);
      expect(lines, hasLength(2));
      expect(lines[0], '00165${' ' * 29}GN)000');
      expect(lines[1].indexOf('0074 00 4 00257'), 7);
      expect(lines[1].indexOf('10010'), 25);
      expect(lines[1].indexOf('START'), 34);
      expect(lines[1].indexOf('TSX'), 49);
      expect(lines[1].indexOf('SYS)175,4'), 56);
    });
  });

  group('the object listing (M4-7; M4-8)', () {
    late JobCompilation job;
    late CodegenResult result;

    setUpAll(() {
      job = compileDeck(loadJobDeck()).jobs.single;
      result = runCodegen(job.semantics!);
    });

    test('reproduces the committed golden byte for byte', () {
      // The golden is the whole printed document after the source
      // pages, pages 7 to 25: the loader-card page, the 977
      // scan-verified content rows under the measured page frame, the
      // end-of-text line, and the deck writer's three closing lines
      // (M4-8 as amended; M4-16).
      const options = ListingOptions(date: '10/18/61', time: '2.45');
      final JobDeck deck = jobDeck(job, options)!;
      expect(
        writeObjectListing(
          result.units,
          loaderCards: deck.cardsBeforeText,
          lastCard: deck.lastCard,
          options: options,
          id: listingId(job.frontEnd),
          firstPage: 7,
        ),
        File('test/goldens/90.05-payroll.storage-map').readAsStringSync(),
      );
    });

    test('the phase generates the whole of Location Counter 0', () {
      // The data region and the procedure text: LOC 00000 through 01620.
      expect(result.image!.inlineWords, _octal('1621'));
    });

    test('the +n offset counts units, not addresses', () {
      // M4-20 item d: the word after an unlabelled `BSS 2` prints `+1`,
      // so the offset is a listing artifact. LOC 00010 reserves two
      // words and LOC 00012 is the next printed line.
      final List<String> lines = renderObjectLines(result.units);
      final int reservation = lines.indexWhere(
        (String l) => l.startsWith('00010'),
      );
      expect(lines[reservation], contains('BSS'));
      expect(lines[reservation], isNot(contains('+')));
      expect(lines[reservation + 1].startsWith('00012'), isTrue);
      expect(lines[reservation + 1], contains('+1'));
    });
  });

  group('the code dump (M4-19)', () {
    test('reproduces the committed golden byte for byte', () {
      expect(
        emitCode(compileDeck(loadJobDeck())),
        File('test/goldens/90.05-payroll.code').readAsStringSync(),
      );
    });
  });

  group('the B5 shapes the sample never reaches', () {
    test('AT END with a bare name compiles as DO name (D6.6)', () {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'IREC', level: '1', type: 'RECORD'),
          dataCard(name: 'FLD', level: '2', description: 'A(6)'),
        ],
        environment: [
          environmentCard(
            name: 'TAPE1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,IREC,BLOCKSIZE 5',
          ),
        ],
        procedure: [
          '            GET IREC, AT END WRAP.UP.',
          '            STOP RUN.',
          '      WRAP.UP.  STOP RUN.',
          '            END.',
        ],
      );
      expect(ids(semantics), isEmpty);
      final String text = renderObjectLines(
        runCodegen(semantics).units,
      ).join('\n');
      expect(text, contains('AXT    *+3,7'));
      expect(text, contains('SXA    WRAP.UP,4'));
      expect(text, contains('TRA    WRAP.UP+1'));
      expect(text, contains('WRAP.UP        AXT    0'));
    });

    test('an END with a paragraph open returns through its cell', () {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(
            name: 'NUM',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '999',
          ),
        ],
        procedure: [
          '            DO PARA.',
          '            STOP RUN.',
          '      PARA.  SET NUM = NUM + NUM.',
          '            END.',
        ],
      );
      expect(ids(semantics), isEmpty);
      final String text = renderObjectLines(
        runCodegen(semantics).units,
      ).join('\n');
      expect(text, contains('PARA           AXT    0'));
      expect(text, contains('TRA*   PARA'));
    });
  });

  group('FILE record IN file (M6-9)', () {
    List<AssemblyUnit> compile(List<String> environment, String statement) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'OREC', level: '1', type: 'RECORD'),
          dataCard(name: 'OFLD', level: '2', description: 'A(6)'),
        ],
        environment: environment,
        procedure: [statement, '      RTN.  STOP RUN.'],
      );
      expect(ids(semantics), isEmpty);
      return runCodegen(semantics).units;
    }

    String tape(String name) => environmentCard(
      name: name,
      type: 'FILE',
      options: 'OUTPUT,BCD,TAPE,OREC,BLOCKSIZE 5',
    );

    test('a record on one file compiles as plain FILE', () {
      expect(
        renderObjectLines(
          compile([tape('TAPE2')], '            FILE OREC IN TAPE2.'),
        ),
        renderObjectLines(compile([tape('TAPE2')], '            FILE OREC.')),
      );
    });

    test('a record on two files is filed in the named one', () {
      final List<AssemblyUnit> units = compile([
        tape('TAPE2'),
        tape('TAPE3'),
      ], '            FILE OREC IN TAPE2, FILE OREC IN TAPE3.');
      final List<String> words = [
        for (final AssemblyUnit u in units) '${u.operation} ${u.operand}',
      ];
      final int call = words.indexOf('TSX IOC)9,4');
      expect(words.sublist(call, call + 6), [
        'TSX IOC)9,4',
        'PZE TAPE2,,0',
        'IOST OREC,,1',
        'TSX IOC)9,4',
        'PZE TAPE3,,0',
        'IOST OREC,,1',
      ]);
    });
  });

  group('STOP n (D2.7; M6-9)', () {
    test('calls the display alone, with n right-justified', () {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(
            name: 'NUM',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '999',
          ),
        ],
        procedure: ['            STOP 1234.', '            STOP RUN.'],
      );
      expect(ids(semantics), isEmpty);
      final List<AssemblyUnit> units = runCodegen(semantics).units;
      final List<String> words = [
        for (final AssemblyUnit u in units) '${u.operation} ${u.operand}',
      ];
      final int call = words.indexOf('TSX SYS)178,4');
      // No close-all and no end-of-job: the next word is STOP RUN's.
      expect(words[call + 3], 'TSX SYS)178,4');
      expect(words.where((String w) => w == 'TSX SYS)177,4'), hasLength(1));
      // '  1234' in BCD (D0.6).
      expect(words, contains('OCT 606001020304'));
    });

    test('empties the register cache, like every other call', () {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'IREC', level: '1', type: 'RECORD'),
          dataCard(name: 'FLD', level: '2', description: 'A(6)'),
          dataCard(name: 'HOLD', level: '1', description: 'A(6)'),
        ],
        environment: [
          environmentCard(
            name: 'TAPE1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,IREC,BLOCKSIZE 5',
          ),
        ],
        procedure: [
          '            GET IREC, AT END GO TO RTN.',
          '            MOVE FLD TO HOLD, STOP 5, MOVE FLD TO HOLD.',
          '            STOP RUN.',
          '      RTN.  STOP RUN.',
        ],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      // The located FLD reloads its base after the halt.
      expect(words.where((String w) => w == 'LAC BL)2,1'), hasLength(2));
    });
  });

  group('the comparison of unequal scales (M6-9)', () {
    /// The words of [statement] up to its STOP RUN, with NUM at `999`,
    /// FRAC at `9V9`, and HRS an external `99V9`.
    List<String> compare(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(
            name: 'NUM',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '999',
          ),
          dataCard(
            name: 'FRAC',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '9V9',
          ),
          dataCard(name: 'HRS', level: '1', mode: 'E', description: '99V9'),
        ],
        procedure: [statement, '            STOP RUN.'],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      // The procedure begins past the three one-word data cells.
      final int start = words.indexOf('BSS 0') + 4;
      return words.sublist(start, words.indexOf('TSX SYS)178,4'));
    }

    // The upscaled side holds the accumulator and the other side is the
    // `CAS` operand. GT then takes the less slot when the upscaled side
    // is the right operand, and the greater slot when it is the left.
    test('a literal of lesser scale goes into the accumulator', () {
      expect(compare('            IF FRAC GT 4 THEN STOP RUN.'), [
        'LDQ CP)+2',
        'MPY CP)+3',
        'XCA ',
        'CAS FRAC',
        'TRA GN)001',
        'TRA GN)001',
      ]);
    });

    test('a literal on the left takes the same words', () {
      expect(
        compare('            IF 4 LT FRAC THEN STOP RUN.'),
        compare('            IF FRAC GT 4 THEN STOP RUN.'),
      );
    });

    test('a name of lesser scale is upscaled against a literal', () {
      expect(compare('            IF NUM GT 4.5 THEN STOP RUN.'), [
        'LDQ NUM',
        'MPY CP)+3',
        'XCA ',
        'CAS CP)+2',
        'TRA *+3',
        'TRA GN)001',
        'TRA GN)001',
      ]);
    });

    test('two names compare at the greater scale', () {
      expect(compare('            IF FRAC GT NUM THEN STOP RUN.'), [
        'LDQ NUM',
        'MPY CP)+2',
        'XCA ',
        'CAS FRAC',
        'TRA GN)001',
        'TRA GN)001',
      ]);
    });

    test('a fetched field compares with 40 from its cell', () {
      expect(compare('            IF HRS GT 40 THEN STOP RUN.'), [
        'LDI CP)+10',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'STO TS)1',
        'LDQ CP)+2',
        'MPY CP)+3',
        'XCA ',
        'CAS TS)1',
        'TRA GN)001',
        'TRA GN)001',
      ]);
    });
  });

  group('the alignment of a MOVE and an ADD (F p. 42)', () {
    /// The words of [statement] up to its STOP RUN, with NUM at `999`,
    /// AMT at `99V99`, EXT an external `999`, EXF an external `99V99`,
    /// EDT at `$8889.99`, and ED3 an edited `899`.
    List<String> aligned(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(
            name: 'NUM',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '999',
          ),
          dataCard(
            name: 'AMT',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '99V99',
          ),
          dataCard(name: 'EXT', level: '1', mode: 'E', description: '999'),
          dataCard(name: 'EXF', level: '1', mode: 'E', description: '99V99'),
          dataCard(name: 'EDT', level: '1', description: r'$8889.99'),
          dataCard(name: 'ED3', level: '1', description: '899'),
        ],
        procedure: [statement, '            STOP RUN.'],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      // The procedure begins past the six data reservations.
      final int start = words.indexOf('BSS 0') + 7;
      return words.sublist(start, words.indexOf('TSX SYS)178,4'));
    }

    test('an internal source of lesser scale upscales into the edit', () {
      expect(aligned('            MOVE NUM TO EDT.'), [
        'LDQ NUM',
        'MPY CP)+2',
        'XCA ',
        'TSX SYS)180,4',
        'PZE EDT,,0',
        'TXI SYS)267,1,12',
        'OCT 000004000003',
        'AXT 6,1',
      ]);
    });

    test('an external source of lesser scale upscales its convert', () {
      expect(aligned('            MOVE EXT TO AMT.'), [
        'LDI CP)+7',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'XCA ',
        'MPY CP)+2',
        'XCA ',
        'STO AMT',
      ]);
    });

    test('an external source of greater scale drops its low digits', () {
      expect(aligned('            MOVE EXF TO NUM.'), [
        'LDI CP)+7',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,4',
        'LRS 35',
        'DVP CP)+2',
        'STQ NUM',
      ]);
    });

    test('an ADD source of lesser scale parks as the chain parks', () {
      expect(
        aligned('            ADD NUM TO AMT.'),
        aligned('            SET AMT = AMT + NUM.'),
      );
      expect(aligned('            ADD NUM TO AMT.'), [
        'LDQ NUM',
        'MPY CP)+2',
        'STQ RS)0',
        'CLA AMT',
        'ADD RS)0',
        'STO AMT',
      ]);
    });

    test('an edited ADD source aligns after its park', () {
      expect(aligned('            ADD ED3 TO AMT.'), [
        'LDI CP)+7',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)268,1,1',
        'TXI SYS)269,1,3',
        'TXI SYS)275,1,3',
        'STO RS)1',
        'LDQ RS)1',
        'MPY CP)+2',
        'STQ RS)0',
        'CLA AMT',
        'ADD RS)0',
        'STO AMT',
      ]);
    });
  });

  group('the external-decimal fetch (M6-9)', () {
    /// The words from the first fetch to the end of [statement], with
    /// EXT and EXU external decimal, NUM internal, and IFLD a field of
    /// a located input record.
    List<String> fetch(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'IREC', level: '1', type: 'RECORD'),
          dataCard(name: 'IFLD', level: '2', description: '999'),
          dataCard(
            name: 'NUM',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '999',
          ),
          dataCard(name: 'EXT', level: '1', mode: 'E', description: '999'),
          dataCard(name: 'EXU', level: '1', mode: 'E', description: '999'),
        ],
        environment: [
          environmentCard(
            name: 'TAPE1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,IREC,BLOCKSIZE 5',
          ),
        ],
        procedure: [
          '            GET IREC, AT END GO TO RTN.',
          statement,
          '      RTN.  STOP RUN.',
        ],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      final int start = words.indexOf('TRA RTN') + 1;
      return words.sublist(start, words.indexOf('TSX SYS)178,4'));
    }

    const convertExt = <String>[
      'LDI CP)+7',
      'STI SYS)132',
      'TSX SYS)182,4',
      'TXI SYS)184,1,3',
    ];

    test('a SET operand converts into a temporary cell', () {
      expect(fetch('            SET NUM = EXT + NUM.'), [
        ...convertExt,
        'STO TS)1',
        'CLA TS)1',
        'ADD NUM',
        'STO NUM',
      ]);
    });

    test('a factor reads the cell with MPY', () {
      expect(fetch('            SET NUM = EXT * NUM.'), [
        ...convertExt,
        'STO TS)1',
        'LDQ NUM',
        'MPY TS)1',
        'STQ NUM',
      ]);
    });

    test('two operands take two cells, and a repeat reads its own', () {
      expect(fetch('            SET NUM = EXT + EXU - EXT.'), [
        ...convertExt,
        'STO TS)1',
        'LDI CP)+8',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'STO TS)2',
        'CLA TS)1',
        'ADD TS)2',
        'SUB TS)1',
        'STO NUM',
      ]);
    });

    test('an ADD source converts, then adds from the cell', () {
      expect(fetch('            ADD EXT TO NUM.'), [
        ...convertExt,
        'STO TS)1',
        'CLA NUM',
        'ADD TS)1',
        'STO NUM',
      ]);
    });

    test('an ADD to two targets converts its source once', () {
      expect(fetch('            ADD EXT TO NUM, NUM.'), [
        ...convertExt,
        'STO TS)1',
        'CLA NUM',
        'ADD TS)1',
        'STO NUM',
        'CLA NUM',
        'ADD TS)1',
        'STO NUM',
      ]);
    });

    test('a located comparand sets its pointer from its base', () {
      expect(fetch('            IF IFLD GT NUM THEN STOP RUN.').take(8), [
        'CAL BL)2',
        'ACL CP)+9',
        'SLW SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'STO TS)1',
        'CLA TS)1',
        'CAS NUM',
      ]);
    });

    test('a storage comparand converts ahead of the accumulator load', () {
      expect(fetch('            IF NUM GT EXT THEN STOP RUN.').take(7), [
        'LDI CP)+9',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'STO TS)1',
        'CLA NUM',
        'CAS TS)1',
      ]);
    });

    test('a truth function reads the cell its statement fetched', () {
      final List<String> words = fetch(
        '            SET NUM = TR (EXT GT NUM) * NUM.',
      );
      expect(words.where((String w) => w == 'TSX SYS)182,4'), hasLength(1));
      expect(words.indexOf('STO TS)1'), lessThan(words.indexOf('CLA TS)1')));
    });

    test('each clause fetches again', () {
      final List<String> words = fetch(
        '            SET NUM = EXT + NUM, SET NUM = EXT + NUM.',
      );
      expect(words.where((String w) => w == 'STO TS)1'), hasLength(2));
    });
  });

  group('the entry point (D2.1)', () {
    // Compiles [procedure] over one integer item and asserts that the
    // end-of-text entry names the PROGRAM.START word rather than
    // `GN)000`, which the sample's default path leaves it naming.
    void expectEntryOnProgramStart(List<String> procedure) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(
            name: 'NUM',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '999',
          ),
        ],
        procedure: procedure,
      );
      expect(ids(semantics), isEmpty);
      final List<AssemblyUnit> units = runCodegen(semantics).units;
      final AssemblyUnit end = units.singleWhere(
        (AssemblyUnit u) => u.control == ControlGroup.endOfText,
      );
      final AssemblyUnit labelled = units.singleWhere(
        (AssemblyUnit u) => u.labels.contains('PROGRAM.START'),
      );
      final AssemblyUnit first = units.singleWhere(
        (AssemblyUnit u) => u.labels.contains('GN)000'),
      );
      expect(end.operand, 'PROGRAM.START');
      expect(end.location, labelled.location);
      // GN)000 binds to the first text word, whose LOC is the data
      // extent.
      expect(end.location, greaterThan(first.location!));
      // The loader reads the entry out of the address field, not the
      // LOC column.
      expect(Word36.address(end.word!), end.location);
    }

    test('a labelled statement takes it', () {
      expectEntryOnProgramStart(<String>[
        '            SET NUM = NUM + NUM.',
        '      PROGRAM.START.  SET NUM = NUM + NUM.',
        '            STOP RUN.',
      ]);
    });

    test('a labelled section takes it', () {
      // The section leaves through its own STOP RUN, so the program
      // runs to the end of the job; `test/runtime/machine_test.dart`
      // runs it.
      expectEntryOnProgramStart(<String>[
        '            GO TO WRAP.UP.',
        '      PROGRAM.START.  BEGIN SECTION.',
        '            SET NUM = NUM + 1.',
        '            STOP RUN.',
        '            END PROGRAM.START.',
        '      WRAP.UP.  STOP RUN.',
      ]);
    });
  });
}
