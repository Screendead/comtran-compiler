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

  group('the product of a product (M6-9)', () {
    /// The words of [statement] up to its STOP RUN, with NUM and TOT at
    /// `999` and FRAC at `9V9`.
    List<String> product(String statement) {
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
            name: 'TOT',
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

    test('the next factor multiplies the MQ with no XCA', () {
      expect(product('            SET NUM = NUM * TOT * 2.'), [
        'LDQ TOT',
        'MPY NUM',
        'MPY CP)+2',
        'STQ NUM',
      ]);
    });

    test('a parenthesised product multiplies the MQ with no XCA', () {
      expect(product('            SET NUM = (NUM * TOT) * 2.'), [
        'LDQ TOT',
        'MPY NUM',
        'MPY CP)+2',
        'STQ NUM',
      ]);
    });

    test('a literal counts the digits of its value', () {
      // 00000001 holds one digit, so the inner product holds 7. Its
      // eight keyed digits would count 14 and refuse.
      expect(product('            SET NUM = NUM * TOT * 00000001 * 2.'), [
        'LDQ TOT',
        'MPY NUM',
        'MPY CP)+1',
        'MPY CP)+2',
        'STQ NUM',
      ]);
    });

    test('the shape of statement 141,00 scales back once at the store', () {
      // (FRAC - 4) is at scale 1, so the product is at 1 + 0 + 1 = 2,
      // and the tail divides by 10 into FRAC with the half-adjust 5.
      // The pool holds 4, then 1.5, then the 10 the alignment and the
      // divide share.
      expect(product('            SET FRAC = (FRAC - 4) * NUM * 1.5.'), [
        'LDQ CP)+2',
        'MPY CP)+4',
        'STQ RS)0',
        'CLA FRAC',
        'SUB RS)0',
        'XCA ',
        'MPY NUM',
        'MPY CP)+3',
        'XCA ',
        'ACL CP)+5',
        'LRS 35',
        'DVP CP)+4',
        'STQ FRAC',
      ]);
    });

    test('a truth function inside the inner product compiles', () {
      final List<String> words = product(
        '            SET NUM = TR (NUM GT 1) * TOT * NUM.',
      );
      expect(words.sublist(words.length - 4), [
        'XCA ',
        'MPY TOT',
        'MPY NUM',
        'STQ NUM',
      ]);
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

    test('a nonzero literal of equal scale loads its pool word', () {
      expect(compare('            IF 5 GT NUM THEN STOP RUN.'), [
        'CLA CP)+2',
        'CAS NUM',
        'TRA *+3',
        'TRA GN)001',
        'TRA GN)001',
      ]);
    });

    test('two literals of equal scale take the same load', () {
      expect(compare('            IF 4 LT 5 THEN STOP RUN.'), [
        'CLA CP)+2',
        'CAS CP)+3',
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

  group('the comparison of an expression (M6-9)', () {
    /// The words of [statement] up to its STOP RUN, with FICA, GROSS and
    /// EXEMPTIONS external at the applied deck's pictorials, and NUM and
    /// FRAC internal at `999` and `9V9`.
    List<String> compare(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'FICA', level: '1', mode: 'E', description: '999V99'),
          dataCard(
            name: 'GROSS',
            level: '1',
            mode: 'E',
            description: '99999V99',
          ),
          dataCard(
            name: 'EXEMPTIONS',
            level: '1',
            mode: 'E',
            description: '99',
          ),
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
          dataCard(
            name: 'BIG',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '9(8)',
          ),
        ],
        procedure: [statement, '            STOP RUN.'],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      // The procedure begins past the six one-word data cells.
      final int start = words.indexOf('BSS 0') + 7;
      return words.sublist(start, words.indexOf('TSX SYS)178,4'));
    }

    // The fetches of FICA and GROSS come first, into TS)1 and TS)2.
    const fetches = <String>[
      'LDI CP)+11',
      'STI SYS)132',
      'TSX SYS)182,4',
      'TXI SYS)184,1,5',
      'STO TS)1',
      'LDI CP)+12',
      'STI SYS)132',
      'TSX SYS)182,4',
      'TXI SYS)184,1,7',
      'STO TS)2',
    ];

    test('statement 152 parks the upscaled literal, then the chain', () {
      // The chain is at scale 4, so 144.00 is upscaled by 100 into TS)3.
      // LT takes the less slot, which falls into the THEN arm.
      expect(
        compare(
          '            IF FICA + 0.03 * GROSS IS LESS THAN 144.00 THEN '
          'STOP RUN.',
        ),
        [
          ...fetches,
          'LDQ CP)+3',
          'MPY CP)+4',
          'STQ TS)3',
          'LDQ TS)1',
          'MPY CP)+4',
          'STQ RS)1+0',
          'LDQ CP)+2',
          'MPY TS)2',
          'STQ RS)0',
          'CLA RS)1',
          'ADD RS)0',
          'CAS TS)3',
          'TRA GN)001',
          'TRA GN)001',
        ],
      );
    });

    test('an expression on the right mirrors the vector', () {
      // 144.00 GT the chain is the chain LT 144.00, the less slot again.
      final List<String> words = compare(
        '            IF 144.00 GT FICA + 0.03 * GROSS THEN STOP RUN.',
      );
      expect(words.sublist(words.length - 3), [
        'CAS TS)3',
        'TRA GN)001',
        'TRA GN)001',
      ]);
    });

    test('statement 156 upscales the product in the MQ', () {
      // 13 * EXEMPTIONS is at scale 0 and GROSS at scale 2.
      expect(
        compare(
          '            IF 13 * EXEMPTIONS IS LESS THAN GROSS THEN STOP RUN.',
        ),
        [
          'LDI CP)+10',
          'STI SYS)132',
          'TSX SYS)182,4',
          'TXI SYS)184,1,2',
          'STO TS)1',
          'LDI CP)+11',
          'STI SYS)132',
          'TSX SYS)182,4',
          'TXI SYS)184,1,7',
          'STO TS)2',
          'LDQ CP)+2',
          'MPY TS)1',
          'MPY CP)+3',
          'XCA ',
          'CAS TS)2',
          'TRA GN)001',
          'TRA GN)001',
        ],
      );
    });

    test('a chain below the other side aligns its terms', () {
      // The chain takes scale 1 from FRAC, so each term parks upscaled.
      expect(compare('            IF NUM + 1 LT FRAC THEN STOP RUN.'), [
        'LDQ NUM',
        'MPY CP)+2',
        'STQ RS)1+0',
        'LDQ CP)+1',
        'MPY CP)+2',
        'STQ RS)0',
        'CLA RS)1',
        'ADD RS)0',
        'CAS FRAC',
        'TRA GN)001',
        'TRA GN)001',
      ]);
    });

    test('two expressions park the right one first', () {
      expect(compare('            IF NUM + 1 = FRAC * 2 THEN STOP RUN.'), [
        'LDQ CP)+2',
        'MPY FRAC',
        'STQ TS)1',
        'LDQ NUM',
        'MPY CP)+3',
        'STQ RS)1+0',
        'LDQ CP)+1',
        'MPY CP)+3',
        'STQ RS)0',
        'CLA RS)1',
        'ADD RS)0',
        'CAS TS)1',
        'TRA GN)001',
        'TRA *+2',
        'TRA GN)001',
      ]);
    });

    test('an expression of equal scale compares with no park', () {
      expect(compare('            IF NUM - 1 GT NUM THEN STOP RUN.'), [
        'CLA NUM',
        'SUB CP)+1',
        'CAS NUM',
        'TRA *+3',
        'TRA GN)001',
        'TRA GN)001',
      ]);
    });

    test('a truth function inside the expression parks above it', () {
      final List<String> words = compare(
        '            IF TR (FRAC + 1 GT 1) * 1 + FRAC GT 1 THEN STOP RUN.',
      );
      // The outer park of the upscaled 1 is TS)1, so the inner one takes
      // TS)2. The inner chain reads its RS)0 before the outer chain parks
      // its first term in RS)1.
      expect(words, [
        'LDQ CP)+1',
        'MPY CP)+2',
        'STQ TS)1',
        'RIR 777777',
        'LDQ CP)+1',
        'MPY CP)+2',
        'STQ TS)2',
        'LDQ CP)+1',
        'MPY CP)+2',
        'STQ RS)0',
        'CLA FRAC',
        'ADD RS)0',
        'CAS TS)2',
        'TRA *+3',
        'TRA *+3',
        'TRA *+2',
        'SIR 000001',
        'PXA 0,0',
        'RFT 000001',
        'CLA CP)+1',
        'XCA ',
        'MPY CP)+1',
        'MPY CP)+2',
        'STQ RS)1+0',
        'CLA RS)1',
        'ADD FRAC',
        'CAS TS)1',
        'TRA *+3',
        'TRA GN)001',
        'TRA GN)001',
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

  group('the external-decimal store (M6-9)', () {
    /// The words from the first word after the GET to the end of
    /// [statement]. EXT is external `999`, EXM `99R` and EXP `99I`
    /// overpunched, EXF external `9V9`; NUM is internal `999` and FRAC
    /// internal `9V9`; IFLD is a field of a located input record and
    /// EDT an edited field.
    List<String> store(String statement) {
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
          dataCard(
            name: 'FRAC',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '9V9',
          ),
          dataCard(name: 'EXT', level: '1', mode: 'E', description: '999'),
          dataCard(name: 'EXM', level: '1', mode: 'E', description: '99R'),
          dataCard(name: 'EXP', level: '1', mode: 'E', description: '99I'),
          dataCard(name: 'EXF', level: '1', mode: 'E', description: '9V9'),
          dataCard(name: 'EDT', level: '1', description: r'$889'),
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

    const fetchExt = <String>[
      'LDI CP)+7',
      'STI SYS)132',
      'TSX SYS)182,4',
      'TXI SYS)184,1,3',
      'STO TS)1',
    ];

    test('an unsigned target takes SYS)186 behind the SYS)180 call', () {
      expect(store('            SET EXT = NUM.'), [
        'CLA NUM',
        'TSX SYS)180,4',
        'PZE EXT,,0',
        'TXI SYS)186,1,3',
      ]);
    });

    test('a minus overpunch takes SYS)187 and a plus one SYS)188', () {
      expect(store('            SET EXM = NUM.').last, 'TXI SYS)187,1,3');
      expect(store('            SET EXP = NUM.').last, 'TXI SYS)188,1,3');
    });

    test('a located target takes the MZE address reference', () {
      expect(store('            SET IFLD = NUM.'), [
        'CLA NUM',
        'TSX SYS)180,4',
        'MZE BL)2,,CP)+7',
        'TXI SYS)186,1,3',
      ]);
    });

    test('a value in the MQ moves to the accumulator first', () {
      expect(store('            SET EXF = NUM * FRAC.'), [
        'LDQ FRAC',
        'MPY NUM',
        'XCA ',
        'TSX SYS)180,4',
        'PZE EXF,,0',
        'TXI SYS)186,1,2',
      ]);
    });

    test('the scaling tail ends in the store, not in STQ', () {
      expect(store('            SET EXF = FRAC * FRAC.'), [
        'LDQ FRAC',
        'MPY FRAC',
        'XCA ',
        'ACL CP)+4',
        'LRS 35',
        'DVP CP)+5',
        'XCA ',
        'TSX SYS)180,4',
        'PZE EXF,,0',
        'TXI SYS)186,1,2',
      ]);
    });

    test('a SET reads the target through its fetch, then stores it', () {
      expect(store('            SET EXT = EXT + NUM.'), [
        ...fetchExt,
        'CLA TS)1',
        'ADD NUM',
        'TSX SYS)180,4',
        'PZE EXT,,0',
        'TXI SYS)186,1,3',
      ]);
    });

    test('an ADD target converts, adds, and stores back', () {
      expect(store('            ADD NUM TO EXT.'), [
        ...fetchExt,
        'CLA TS)1',
        'ADD NUM',
        'TSX SYS)180,4',
        'PZE EXT,,0',
        'TXI SYS)186,1,3',
      ]);
    });

    test('an ADD to two targets converts both ahead of the first', () {
      expect(store('            ADD NUM TO EXT, EXM.'), [
        ...fetchExt,
        'LDI CP)+8',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'STO TS)2',
        'CLA TS)1',
        'ADD NUM',
        'TSX SYS)180,4',
        'PZE EXT,,0',
        'TXI SYS)186,1,3',
        'CLA TS)2',
        'ADD NUM',
        'TSX SYS)180,4',
        'PZE EXM,,0',
        'TXI SYS)187,1,3',
      ]);
    });

    test('a field added to itself takes one cell', () {
      expect(store('            ADD EXT TO EXT.'), [
        ...fetchExt,
        'CLA TS)1',
        'ADD TS)1',
        'TSX SYS)180,4',
        'PZE EXT,,0',
        'TXI SYS)186,1,3',
      ]);
    });

    test('an edited ADD source parks before the target converts', () {
      final List<String> words = store('            ADD EDT TO EXT.');
      expect(words.indexOf('STO RS)1'), lessThan(words.indexOf('STO TS)1')));
      expect(words.sublist(words.indexOf('STO TS)1')), [
        'STO TS)1',
        'CLA TS)1',
        'ADD RS)1',
        'TSX SYS)180,4',
        'PZE EXT,,0',
        'TXI SYS)186,1,3',
      ]);
    });
  });

  test('ADD CORRESPONDING stores an external-decimal pair (M6-9)', () {
    final SemanticResult semantics = runJob(
      data: [
        dataCard(name: 'SRC', level: '1'),
        dataCard(
          name: 'X',
          level: '2',
          mode: 'I',
          justify: 'R',
          description: '999',
        ),
        dataCard(name: 'Y', level: '2', mode: 'E', description: '999'),
        dataCard(name: 'DST', level: '1'),
        dataCard(name: 'X', level: '2', mode: 'E', description: '999'),
        dataCard(name: 'Y', level: '2', mode: 'E', description: '999'),
      ],
      procedure: [
        '            ADD CORRESPONDING SRC TO DST.',
        '            STOP RUN.',
      ],
    );
    expect(ids(semantics), isEmpty);
    final List<String> words = [
      for (final AssemblyUnit u in runCodegen(semantics).units)
        '${u.operation} ${u.operand}',
    ];
    // Each pair converts its fields, adds, and stores through SYS)186.
    expect(
      words.sublist(words.indexOf('BSS 1') + 1, words.indexOf('TSX SYS)178,4')),
      [
        'LDI CP)+6',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'STO TS)1',
        'CLA TS)1',
        'ADD 1)X',
        'TSX SYS)180,4',
        'PZE 2)X,,0',
        'TXI SYS)186,1,3',
        'LDI CP)+7',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'STO TS)1',
        'LDI CP)+8',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,3',
        'STO TS)2',
        'CLA TS)2',
        'ADD TS)1',
        'TSX SYS)180,4',
        'PZE 2)Y,,3',
        'TXI SYS)186,1,3',
      ],
    );
  });

  group('the scaling store of a chain value (M6-9)', () {
    /// The words of [statement] up to its STOP RUN. NUM is internal
    /// `999`, FRAC internal `9V9`, EXT external `999` and EXM external
    /// `99R`.
    List<String> chain(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          for (final (String name, String picture) in [
            ('NUM', '999'),
            ('FRAC', '9V9'),
          ])
            dataCard(
              name: name,
              level: '1',
              mode: 'I',
              justify: 'R',
              description: picture,
            ),
          dataCard(name: 'EXT', level: '1', mode: 'E', description: '999'),
          dataCard(name: 'EXM', level: '1', mode: 'E', description: '99R'),
        ],
        procedure: [statement, '            STOP RUN.'],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      // The procedure begins past the four one-word data cells.
      final int start = words.indexOf('BSS 0') + 5;
      return words.sublist(start, words.indexOf('TSX SYS)178,4'));
    }

    test('a chain takes the tail with no XCA', () {
      expect(chain('            SET NUM = FRAC + FRAC.'), [
        'CLA FRAC',
        'ADD FRAC',
        'ACL CP)+2',
        'LRS 35',
        'DVP CP)+3',
        'STQ NUM',
      ]);
    });

    test('a one-term chain takes the same tail', () {
      expect(chain('            SET NUM = FRAC.'), [
        'CLA FRAC',
        'ACL CP)+2',
        'LRS 35',
        'DVP CP)+3',
        'STQ NUM',
      ]);
    });

    test('TRUNCATED drops the half-adjust', () {
      expect(chain('            SET NUM = FRAC + FRAC TRUNCATED.'), [
        'CLA FRAC',
        'ADD FRAC',
        'LRS 35',
        'DVP CP)+2',
        'STQ NUM',
      ]);
    });

    test('the shape of statement 142,00 divides by its alignment word', () {
      // NUM aligns by 100 to the scale of the product, and the tail
      // divides by the same pool word, as CP)+31 serves both at 00623
      // and 00646.
      expect(chain('            SET NUM = NUM + FRAC * FRAC.'), [
        'LDQ NUM',
        'MPY CP)+2',
        'STQ RS)1+0',
        'LDQ FRAC',
        'MPY FRAC',
        'STQ RS)0',
        'CLA RS)1',
        'ADD RS)0',
        'ACL CP)+3',
        'LRS 35',
        'DVP CP)+2',
        'STQ NUM',
      ]);
    });

    test('an external target takes the quotient back with XCA', () {
      expect(chain('            SET EXT = FRAC + FRAC.'), [
        'CLA FRAC',
        'ADD FRAC',
        'ACL CP)+2',
        'LRS 35',
        'DVP CP)+3',
        'XCA ',
        'TSX SYS)180,4',
        'PZE EXT,,0',
        'TXI SYS)186,1,3',
      ]);
      expect(chain('            SET EXM = FRAC - 4.').last, 'TXI SYS)187,1,3');
    });

    test('a located target loads its base ahead of the half-adjust', () {
      // Statement 142,00's DETAIL GROSS: the base load and its guard
      // come after the chain and before the tail.
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'IREC', level: '1', type: 'RECORD'),
          dataCard(
            name: 'IGRS',
            level: '2',
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
          '            SET IGRS = FRAC + FRAC.',
          '      RTN.  STOP RUN.',
        ],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      final int start = words.indexOf('TRA RTN') + 1;
      expect(words.sublist(start, words.indexOf('TSX SYS)178,4')), [
        'CLA FRAC',
        'ADD FRAC',
        'LAC BL)2,1',
        'TXL SYS)294,1,0',
        'ACL CP)+4',
        'LRS 35',
        'DVP CP)+5',
        'STQ IGRS,1',
      ]);
    });
  });

  group('the edited store of a chain value (M6-9)', () {
    /// The words of [statement] up to its STOP RUN. EXA is external
    /// `99999V99` and EXB external `999V99`; NUM is internal `999`, FRC
    /// internal `9V99` and FR3 internal `9V999`; NET is edited
    /// `$88889.99-`, PAYRECORD NETPAY's pictorial.
    List<String> chain(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          for (final (String name, String picture) in [
            ('NUM', '999'),
            ('FRC', '9V99'),
            ('FR3', '9V999'),
          ])
            dataCard(
              name: name,
              level: '1',
              mode: 'I',
              justify: 'R',
              description: picture,
            ),
          dataCard(name: 'EXA', level: '1', mode: 'E', description: '99999V99'),
          dataCard(name: 'EXB', level: '1', mode: 'E', description: '999V99'),
          dataCard(name: 'NET', level: '1', description: r'$88889.99-'),
        ],
        procedure: [statement, '            STOP RUN.'],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      // The procedure begins past the six data cells.
      final int start = words.indexOf('BSS 0') + 7;
      return words.sublist(start, words.indexOf('TSX SYS)178,4'));
    }

    /// The shape of GROSS's edited store at LOC 00374 to 00400. The
    /// dollar adds 8 to the edit control, and the trailing minus puts
    /// sign convention 3 in the control word's tag.
    const call = <String>[
      'TSX SYS)180,4',
      'PZE NET,,0',
      'TXI SYS)267,1,12',
      'OCT 000005300004',
      'AXT 7,1',
    ];

    test('the shape of statement 145,00 stores the chain through SYS)267', () {
      expect(chain('            SET NET = EXA - EXB - EXB.'), [
        'LDI CP)+6',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,7',
        'STO TS)1',
        'LDI CP)+7',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,5',
        'STO TS)2',
        'CLA TS)1',
        'SUB TS)2',
        'SUB TS)2',
        ...call,
      ]);
    });

    test('a product in the MQ moves to the accumulator first', () {
      expect(chain('            SET NET = NUM * FRC.'), [
        'LDQ FRC',
        'MPY NUM',
        'XCA ',
        ...call,
      ]);
    });

    test('a chain above the target scale takes the tail, then XCA', () {
      expect(chain('            SET NET = FR3 + FR3.'), [
        'CLA FR3',
        'ADD FR3',
        'ACL CP)+2',
        'LRS 35',
        'DVP CP)+3',
        'XCA ',
        ...call,
      ]);
    });
  });

  group('the edit run that drops high-order digits (M6-9)', () {
    /// The words of [statement] up to its STOP RUN. NET is edited
    /// `$88889.99-` and AMT edited `$***9.99`, statement 146,00's pair;
    /// EXF is external `99999` and EDF edited `999.9`, F p. 43's row with
    /// an edited receiver.
    List<String> run(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'NET', level: '1', description: r'$88889.99-'),
          dataCard(name: 'AMT', level: '1', description: r'$***9.99'),
          dataCard(name: 'EXF', level: '1', mode: 'E', description: '99999'),
          dataCard(name: 'EDF', level: '1', description: '999.9'),
        ],
        procedure: [statement, '            STOP RUN.'],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      final int start = words.indexOf('TSX SYS)182,4') - 4;
      return words.sublist(start, words.indexOf('TSX SYS)178,4'));
    }

    test('the shape of statement 146,00 tests one digit under SYS)204', () {
      expect(run('            MOVE NET TO AMT.'), [
        'LDI CP)+6',
        'STI SYS)133',
        'LDI CP)+7',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)190,1,13',
        'OCT 000004000003',
        'TXI SYS)204,1,1',
        'TXI SYS)198,1,6',
        'TXI SYS)226,1,6',
      ]);
    });

    test('the F p. 43 row tests two digits under SYS)201', () {
      expect(run('            MOVE EXF TO EDF.'), [
        'LDI CP)+6',
        'STI SYS)133',
        'LDI CP)+7',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)185,1,4',
        'OCT 000003000000',
        'TXI SYS)201,1,2',
        'TXI SYS)193,1,3',
        'TXI SYS)211,1,1',
        'TXI SYS)225,1,4',
      ]);
    });
  });

  group('the external-to-external move (M6-9)', () {
    /// The words from the first word after the GET to the end of
    /// [statement]. IFLD is `999V99` in a located input record, the
    /// source of statement 162,00; EXT is external `999V99`, EXM
    /// `999V9R` and EXP `999V9I` overpunched.
    List<String> move(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'IREC', level: '1', type: 'RECORD'),
          dataCard(name: 'IFLD', level: '2', description: '999V99'),
          dataCard(name: 'EXT', level: '1', mode: 'E', description: '999V99'),
          dataCard(name: 'EXM', level: '1', mode: 'E', description: '999V9R'),
          dataCard(name: 'EXP', level: '1', mode: 'E', description: '999V9I'),
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

    test('the shape of statement 162,00 takes the SYS)183 run', () {
      expect(move('            MOVE IFLD TO EXT.'), [
        'LDI CP)+7',
        'STI SYS)133',
        'CAL BL)2',
        'ACL CP)+8',
        'SLW SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)183,1,0',
        'TXI SYS)191,1,5',
        'TXI SYS)223,1,5',
      ]);
    });

    test('the target sign picks the convention', () {
      expect(move('            MOVE EXT TO EXM.')[5], 'TXI SYS)183,1,1');
      expect(move('            MOVE EXT TO EXP.')[5], 'TXI SYS)183,1,2');
    });

    test('a signed source moves under SYS)227', () {
      expect(move('            MOVE EXM TO EXP.').sublist(4), [
        'TSX SYS)182,4',
        'TXI SYS)183,1,2',
        'TXI SYS)227,1,5',
        'TXI SYS)223,1,5',
      ]);
    });
  });

  group('the comparison of a field across a word boundary (M6-9)', () {
    /// The words from the first word after the GET to the end of
    /// [statement]. IF4 is `A(6)` at byte 4 of a located input record,
    /// the shape of DETAIL EMPLOYEE.NUMBER at statement 130,00; WF4 is
    /// the same field unlocated, and WF1 an `A(6)` at byte 1.
    List<String> compare(String statement) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'IREC', level: '1', type: 'RECORD'),
          dataCard(level: '2', description: 'AAAA'),
          dataCard(name: 'IF4', level: '2', description: 'A(6)'),
          dataCard(name: 'WG4', level: '1'),
          dataCard(level: '2', description: 'AAAA'),
          dataCard(name: 'WF4', level: '2', description: 'A(6)'),
          dataCard(name: 'WG1', level: '1'),
          dataCard(level: '2', description: 'A'),
          dataCard(name: 'WF1', level: '2', description: 'A(6)'),
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

    test('each field takes its next word into the MQ', () {
      expect(compare('            IF WF4 = WF1 THEN STOP RUN.'), [
        'CAL WF4',
        'LDQ WF4+1',
        'LGL 24',
        'ANA CP)+4',
        'SLW RS)0',
        'CAL WF1',
        'LDQ WF1+1',
        'LGL 6',
        'ANA CP)+4',
        'LAS RS)0',
        'TRA GN)006',
        'TRA *+2',
        'TRA GN)006',
      ]);
    });

    test('a located field reads its next word through the base', () {
      expect(compare('            IF IF4 = WF1 THEN STOP RUN.'), [
        'LAC BL)2,1',
        'TXL SYS)294,1,0',
        'CAL IF4,1',
        'LDQ IF4+1,1',
        'LGL 24',
        'ANA CP)+4',
        'SLW RS)0',
        'CAL WF1',
        'LDQ WF1+1',
        'LGL 6',
        'ANA CP)+4',
        'LAS RS)0',
        'TRA GN)006',
        'TRA *+2',
        'TRA GN)006',
      ]);
    });

    test('a field against HIGH.VALUE spills the constant', () {
      expect(compare('            IF IF4 = HIGH.VALUE THEN STOP RUN.'), [
        'CAL CP)+4',
        'SLW RS)0',
        'LAC BL)2,1',
        'TXL SYS)294,1,0',
        'CAL IF4,1',
        'LDQ IF4+1,1',
        'LGL 24',
        'ANA CP)+5',
        'LAS RS)0',
        'TRA GN)006',
        'TRA *+2',
        'TRA GN)006',
      ]);
    });
  });

  group('the external-decimal DO FOR index (M6-9)', () {
    /// The units of `DO RTN FOR index = [bounds]` over CELL (index).
    /// EXI is external `99`, EXM external `9R` (two digits), and NUM and CELL
    /// internal `999`.
    List<AssemblyUnit> units(String index, String bounds) {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'TAB', level: '1', quantity: '12'),
          for (final String name in ['CELL', 'NUM'])
            dataCard(
              name: name,
              level: name == 'CELL' ? '2' : '1',
              mode: 'I',
              justify: 'R',
              description: '999',
            ),
          dataCard(name: 'EXI', level: '1', mode: 'E', description: '99'),
          dataCard(name: 'EXM', level: '1', mode: 'E', description: '9R'),
        ],
        procedure: [
          '            DO RTN FOR $index = $bounds.',
          '            STOP RUN.',
          '      RTN.  BEGIN SECTION.',
          '            IF NUM LT TAB CELL ($index) THEN STOP RUN.',
          '            END RTN.',
        ],
      );
      expect(ids(semantics), ['206,00']);
      return runCodegen(semantics).units;
    }

    /// The words of the loop, from its AXT to its TPL.
    List<String> loop(String index, String bounds) {
      final List<String> words = [
        for (final AssemblyUnit u in units(index, bounds))
          '${u.operation} ${u.operand}',
      ];
      final int start = words.indexWhere((w) => w.startsWith('AXT GN)'));
      return words.sublist(
        start,
        words.indexWhere((w) => w.startsWith('TPL '), start) + 1,
      );
    }

    test('the loop stores, steps and tests the index through its cell', () {
      expect(loop('EXI', '1(1)12'), [
        'AXT GN)005,4',
        'SXA RTN,4',
        'CLA CP)+1',
        'TSX SYS)180,4',
        'PZE EXI,,0',
        'TXI SYS)186,1,2',
        'CLA GN)007',
        'STO PI)1',
        'EQU RTN+1',
        'TRA RTN+1',
        'LDI CP)+10',
        'STI SYS)132',
        'TSX SYS)182,4',
        'TXI SYS)184,1,2',
        'STO TS)1',
        'CLA TS)1',
        'ADD CP)+1',
        // The stride words reuse the accumulator, so the stepped value
        // parks for the exit test.
        'STO TS)1',
        'TSX SYS)180,4',
        'PZE EXI,,0',
        'TXI SYS)186,1,2',
        'CLA CP)+1',
        'ADD PI)1',
        'STO PI)1',
        'CLA CP)+2',
        'SUB TS)1',
        'TPL GN)004',
      ]);
    });

    test('the back edge enters the increment block on the convert', () {
      final AssemblyUnit head = units(
        'EXI',
        '1(1)12',
      ).firstWhere((AssemblyUnit u) => u.labels.contains('GN)005'));
      expect('${head.operation} ${head.operand}', 'LDI CP)+10');
    });

    test('a minus-overpunched index stores through SYS)187', () {
      expect(loop('EXM', '1(1)9').where((w) => w.startsWith('TXI SYS)18')), [
        'TXI SYS)187,1,2',
        'TXI SYS)184,1,2',
        'TXI SYS)187,1,2',
      ]);
    });
  });

  group('a DO FOR driving several indicators (M6-9)', () {
    /// An internal `999` item at level [level].
    String cell(String name, String level) => dataCard(
      name: name,
      level: level,
      mode: 'I',
      justify: 'R',
      description: '999',
    );

    /// The loop of `DO RTN FOR IDX = 1(1)12` over [data], whose body
    /// compares NUM with each of [cells] subscripted by IDX: the
    /// table-base EQUs ahead of the AXT, then every word to the TPL.
    /// An EQU prints as its label and its operand.
    List<String> indicatorLoop(List<String> data, List<String> cells) {
      final SemanticResult semantics = runJob(
        data: [...data, cell('NUM', '1'), cell('IDX', '1')],
        procedure: [
          '            DO RTN FOR IDX = 1(1)12.',
          '            STOP RUN.',
          '      RTN.  BEGIN SECTION.',
          for (final String each in cells)
            '            IF NUM LT $each (IDX) THEN STOP RUN.',
          '            END RTN.',
        ],
      );
      expect(ids(semantics), isEmpty);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          u.operation == 'EQU'
              ? '${u.labels.single} EQU ${u.operand}'
              : '${u.operation} ${u.operand}',
      ];
      final int axt = words.indexWhere((w) => w.startsWith('AXT GN)'));
      final int start =
          words.lastIndexWhere((w) => !w.contains(' EQU '), axt - 1) + 1;
      return words.sublist(
        start,
        words.indexWhere((w) => w.startsWith('TPL '), axt) + 1,
      );
    }

    test('two tables each take a base, a pair of names, and a stride', () {
      expect(
        indicatorLoop(
          [
            dataCard(name: 'TAB', level: '1', quantity: '12'),
            cell('CELL', '2'),
            dataCard(name: 'TAB2', level: '1', quantity: '12'),
            cell('CEL2', '2'),
            cell('PAD2', '2'),
          ],
          ['CELL', 'CEL2'],
        ),
        [
          // 004 is never bound, 005 and 006 are the body entry and the
          // increment, and each indicator takes a pair: 007 and 008,
          // then 009 and 010, the second name bound.
          'GN)008 EQU CP)+11',
          'GN)010 EQU CP)+12',
          'AXT GN)006,4',
          'SXA RTN,4',
          'CLA CP)+1',
          'STO IDX',
          'CLA GN)008',
          'STO PI)1',
          'CLA GN)010',
          'STO PI)2',
          'GN)005 EQU RTN+1',
          'TRA RTN+1',
          'CLA IDX',
          'ADD CP)+1',
          'STO IDX',
          'CLA CP)+1',
          'ADD PI)1',
          'STO PI)1',
          // TAB2's element is two words, so its stride is its own entry.
          'CLA CP)+3',
          'ADD PI)2',
          'STO PI)2',
          'CLA CP)+2',
          'SUB IDX',
          'TPL GN)005',
        ],
      );
    });

    test('three fields of one table share its stride', () {
      final List<String> data = [
        dataCard(name: 'TAB', level: '1', quantity: '12'),
        cell('A', '2'),
        cell('B', '2'),
        cell('C', '2'),
      ];
      expect(indicatorLoop(data, ['A', 'B', 'C']), [
        'GN)009 EQU CP)+12',
        'GN)011 EQU CP)+13',
        'GN)013 EQU CP)+14',
        'AXT GN)007,4',
        'SXA RTN,4',
        'CLA CP)+1',
        'STO IDX',
        'CLA GN)009',
        'STO PI)1',
        'CLA GN)011',
        'STO PI)2',
        'CLA GN)013',
        'STO PI)3',
        'GN)006 EQU RTN+1',
        'TRA RTN+1',
        'CLA IDX',
        'ADD CP)+1',
        'STO IDX',
        // The element is three words, one pool entry for all three.
        'CLA CP)+3',
        'ADD PI)1',
        'STO PI)1',
        'CLA CP)+3',
        'ADD PI)2',
        'STO PI)2',
        'CLA CP)+3',
        'ADD PI)3',
        'STO PI)3',
        'CLA CP)+2',
        'SUB IDX',
        'TPL GN)006',
      ]);
    });
  });

  group('the stride of part of a word (M6-9)', () {
    /// The shape of statements 144,00 and 166,00: TAB is twelve packed
    /// items of 11 characters, R `99V999`, I and T `9V99`, all external
    /// decimal, and IDX an external `99`. Each line is a label, a tab,
    /// and the word.
    List<String> lines() {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'TAB', level: '1', quantity: '12'),
          dataCard(name: 'R', level: '2', description: '99V999'),
          dataCard(name: 'I', level: '2', description: '9V99'),
          dataCard(name: 'T', level: '2', description: '9V99'),
          dataCard(name: 'MAS', level: '1', description: '99V999'),
          dataCard(name: 'TOT', level: '1', description: '9V99'),
          dataCard(name: 'IDX', level: '1', description: '99'),
        ],
        procedure: [
          '            DO RTN FOR IDX = 1(1)12.',
          '            STOP RUN.',
          '      RTN.  BEGIN SECTION.',
          '            IF MAS GT TAB R (IDX) THEN STOP RUN.',
          '            ADD TAB I (IDX) TO TOT.',
          '            END RTN.',
        ],
      );
      expect(ids(semantics), ['206,00', '206,00']);
      return [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.labels.join(' ')}\t${u.operation} ${u.operand}',
      ];
    }

    List<String> between(List<String> all, String first, String last) {
      final int start = all.indexOf(first);
      return all.sublist(start, all.indexOf(last, start) + 1);
    }

    test('each indicator steps its byte and carries at six', () {
      expect(between(lines(), '\tCLA CP)+3', '\tTPL GN)004'), [
        '\tCLA CP)+3',
        '\tADD PI)1',
        '\tSUB CP)+4',
        '\tTPL *+2',
        '\tADD CP)+4',
        '\tSTO PI)1',
        '\tCLA CP)+3',
        '\tADD PI)2',
        '\tSUB CP)+4',
        '\tTPL *+2',
        '\tADD CP)+4',
        '\tSTO PI)2',
        '\tCLA CP)+2',
        '\tSUB TS)1',
        '\tTPL GN)004',
      ]);
    });

    test('the stride, the carry and the bases carry a byte', () {
      final List<String> all = lines();
      // One word and five characters; six characters less one word.
      expect(all, containsAll(['\tOCT 000005000001', '\tOCT 000005777777']));
      expect(all, containsAll(['\tPZE R+0', '\tPZE I+0,,5']));
    });

    test('a whole-word stride keeps three words and the byte of its base', () {
      final SemanticResult semantics = runJob(
        data: [
          dataCard(name: 'TAB', level: '1', quantity: '12'),
          dataCard(name: 'A', level: '2', description: '99'),
          dataCard(name: 'B', level: '2', description: '9999'),
          dataCard(name: 'C', level: '2', description: '9(6)'),
          dataCard(name: 'TOT', level: '1', description: '9999'),
          dataCard(name: 'IDX', level: '1', description: '99'),
        ],
        procedure: [
          '            DO RTN FOR IDX = 1(1)12.',
          '            STOP RUN.',
          '      RTN.  BEGIN SECTION.',
          '            ADD TAB B (IDX) TO TOT.',
          '            END RTN.',
        ],
      );
      expect(ids(semantics), ['206,00']);
      final List<String> all = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.labels.join(' ')}\t${u.operation} ${u.operand}',
      ];
      // B starts at byte 2 of the item's first word.
      expect(all, contains('\tPZE B+0,,2'));
      final int step = all.indexOf('\tADD PI)1');
      expect(all.sublist(step - 1, step + 2), [
        '\tCLA CP)+3',
        '\tADD PI)1',
        '\tSTO PI)1',
      ]);
    });

    test('the readers set SYS)132 from the indicator', () {
      expect(between(lines(), 'RTN\tAXT 0', '\tTXI SYS)186,1,3'), [
        'RTN\tAXT 0',
        '\tLDI CP)+14',
        '\tSTI SYS)132',
        '\tTSX SYS)182,4',
        '\tTXI SYS)184,1,5',
        '\tSTO TS)1',
        // The subscripted fetch of LOC 01445 to 01450, into a cell.
        '\tLDI PI)1',
        '\tSTI SYS)132',
        '\tTSX SYS)182,4',
        '\tTXI SYS)184,1,5',
        '\tSTO TS)2',
        '\tCLA TS)1',
        '\tCAS TS)2',
        '\tTRA *+3',
        '\tTRA GN)001',
        '\tTRA GN)001',
        '\tTSX SYS)178,4',
        '\tPZE CP)+9,,CP)+10',
        '\tPZE CP)+7,,CP)+8',
        '\tTSX SYS)177,4',
        '\tPZE IOC)1',
        '\tTXI IOC)40,0',
        'GN)001\tLDI PI)2',
        '\tSTI SYS)132',
        '\tTSX SYS)182,4',
        '\tTXI SYS)184,1,3',
        '\tSTO TS)1',
        '\tLDI CP)+15',
        '\tSTI SYS)132',
        '\tTSX SYS)182,4',
        '\tTXI SYS)184,1,3',
        '\tSTO TS)2',
        '\tCLA TS)2',
        '\tADD TS)1',
        '\tTSX SYS)180,4',
        '\tPZE TOT,,0',
        '\tTXI SYS)186,1,3',
      ]);
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

  group('the subscript store and the subscripted target (M6-9)', () {
    String internal(String name, String pic, {String level = '1'}) => dataCard(
      name: name,
      level: level,
      mode: 'I',
      justify: 'R',
      description: pic,
    );

    /// Two words ahead of every table keep each base `NAME-n` at or above
    /// address zero.
    final List<String> pad = [internal('P1', '9'), internal('P2', '9')];

    /// The units of [procedure] over [data], from START on, each a label,
    /// a tab, and the word.
    List<String> lines(List<String> data, List<String> procedure) {
      final SemanticResult semantics = runJob(data: data, procedure: procedure);
      expect(ids(semantics), isEmpty);
      final List<AssemblyUnit> units = runCodegen(semantics).units;
      final int start = units.indexWhere(
        (AssemblyUnit u) => u.labels.contains('START'),
      );
      return [
        for (final AssemblyUnit u in units.skip(start))
          '${u.labels.join(' ')}\t${u.operation} ${u.operand}',
      ];
    }

    List<String> upTo(List<String> all, String last) =>
        all.sublist(0, all.indexOf(last) + 1);

    final List<String> cells = [
      ...pad,
      dataCard(name: 'TAB', level: '1', quantity: '3'),
      internal('CELL', '999', level: '2'),
      internal('I', '9'),
      internal('NUM', '999'),
    ];

    test('an internal-decimal target stores through its indicator', () {
      // The comparand's prologue of 01410-01411, then STO where 01412
      // has CAS.
      expect(
        upTo(
          lines(cells, [
            '      START.  MOVE NUM TO TAB CELL (I).',
            '            STOP RUN.',
          ]),
          '\tSTO 0,1',
        ),
        [
          'GN)000 START\tCLA NUM',
          '\tLAC PI)1,1',
          '\tTXL SYS)294,1,0',
          '\tSTO 0,1',
        ],
      );
    });

    test('an external-decimal source converts, then stores the same way', () {
      final List<String> all = lines(
        [...cells, dataCard(name: 'EXT', level: '1', description: '999')],
        ['      START.  MOVE EXT TO TAB CELL (I).', '            STOP RUN.'],
      );
      expect(upTo(all, '\tSTO 0,1').sublist(3), [
        '\tTXI SYS)184,1,3',
        '\tLAC PI)1,1',
        '\tTXL SYS)294,1,0',
        '\tSTO 0,1',
      ]);
    });

    test('a SET into a subscript variable recomputes its indicator', () {
      final List<String> all = lines(cells, [
        '      START.  SET I = 2.',
        '            IF NUM GT TAB CELL (I) THEN STOP RUN.',
        '            STOP RUN.',
      ]);
      // The five words of 01421-01425 behind the store.
      expect(upTo(all, '\tSTO PI)1'), [
        'GN)000 START\tCLA CP)+2',
        '\tSTO I',
        'GN)002\tEQU CP)+9',
        '\tLDQ I',
        '\tMPY CP)+1',
        '\tXCA ',
        '\tADD GN)002',
        '\tSTO PI)1',
      ]);
    });

    test('a constant increment adds the stride to the indicator', () {
      final List<String> all = lines(cells, [
        '      START.  SET I = I + 2.',
        '            IF NUM GT TAB CELL (I) THEN STOP RUN.',
        '            STOP RUN.',
      ]);
      // The shape of J 90.02.05, `CLA CP)+1 / ADD PI)6 / STO PI)6`. Two
      // elements of one word each are 2 words, the pool word of the 2.
      expect(upTo(all, '\tSTO PI)1'), [
        'GN)000 START\tCLA I',
        '\tADD CP)+2',
        '\tSTO I',
        '\tCLA CP)+2',
        '\tADD PI)1',
        '\tSTO PI)1',
      ]);
    });

    test('an external index takes the constant increment too', () {
      // The step reads no binary index, so the external-decimal refusal
      // of the recomputation does not apply.
      final SemanticResult semantics = runJob(
        data: [
          ...pad,
          dataCard(name: 'TAB', level: '1', quantity: '3'),
          internal('CELL', '999', level: '2'),
          dataCard(name: 'I', level: '1', mode: 'E', description: '9'),
          internal('NUM', '999'),
        ],
        procedure: [
          '      START.  SET I = I + 1.',
          '            IF NUM GT TAB CELL (I) THEN STOP RUN.',
          '            STOP RUN.',
        ],
      );
      expect(ids(semantics), ['206,00']);
      final List<String> words = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          '${u.operation} ${u.operand}',
      ];
      final int step = words.indexOf('ADD PI)1');
      expect(words.sublist(step - 1, step + 2), [
        'CLA CP)+1',
        'ADD PI)1',
        'STO PI)1',
      ]);
    });

    test('an ADD into a subscript variable recomputes its indicator', () {
      final List<String> all = lines(cells, [
        '      START.  ADD NUM TO I.',
        '            IF NUM GT TAB CELL (I) THEN STOP RUN.',
        '            STOP RUN.',
      ]);
      expect(upTo(all, '\tSTO PI)1'), [
        'GN)000 START\tCLA I',
        '\tADD NUM',
        '\tSTO I',
        'GN)002\tEQU CP)+8',
        '\tLDQ I',
        '\tMPY CP)+1',
        '\tXCA ',
        '\tADD GN)002',
        '\tSTO PI)1',
      ]);
    });

    test('the base of one driven indicator carries its byte', () {
      final List<String> all = lines(
        [
          ...pad,
          dataCard(name: 'TAB', level: '1', quantity: '12'),
          dataCard(name: 'A', level: '2', description: '99'),
          dataCard(name: 'B', level: '2', description: '9999'),
          dataCard(name: 'C', level: '2', description: '9(6)'),
          internal('IDX', '99'),
          internal('NUM', '99'),
          internal('NB', '9(6)'),
        ],
        [
          '      START.  MOVE NUM TO IDX.',
          '            MOVE TAB B (IDX) TO NB.',
          '            STOP RUN.',
        ],
      );
      expect(all, contains('\tPZE B-2,,2'));
    });

    test('the bases of several driven indicators keep the sample words', () {
      // RETPREM sits at byte 3 of the element's second word. The one
      // site with two indicators drops it (M6-4 finding 1), and this
      // shape keeps that site's words.
      final SemanticResult semantics = runJob(
        data: [
          ...pad,
          dataCard(name: 'TABLE.ITEM', level: '1', quantity: '3'),
          dataCard(name: 'RATE', level: '2', description: '9(6)'),
          dataCard(name: 'INSPREM', level: '2', description: '9V99'),
          dataCard(name: 'RETPREM', level: '2', description: '9V99'),
          internal('POS', '9'),
          internal('WI', '9V99'),
          internal('WR', '9V99'),
        ],
        procedure: [
          '      START.  MOVE POS TO POS.',
          '            MOVE INSPREM (POS) TO WI.',
          '            MOVE RETPREM (POS) TO WR.',
          '            STOP RUN.',
        ],
      );
      final List<AssemblyUnit> pool = [
        for (final AssemblyUnit u in runCodegen(semantics).units)
          if (u.operand.endsWith('PREM-2')) u,
      ];
      expect([for (final u in pool) u.operand], ['RETPREM-2', 'INSPREM-2']);
      expect(pool.first.word, pool.last.word);
    });

    test('a sub-chain parks clear of the outer chain', () {
      final List<String> all = lines(
        [internal('NUM', '999'), internal('X', '9(5)')],
        [
          '      START.  SET X = NUM * 2 + (NUM * 3 + 1).',
          '            STOP RUN.',
        ],
      );
      // NUM * 2 parks in RS)1, so the inner chain's first park takes the
      // next free cell, RS)2, not RS)1.
      expect(upTo(all, '\tSTO X'), [
        'GN)000 START\tLDQ CP)+2',
        '\tMPY NUM',
        '\tSTQ RS)1+0',
        '\tLDQ CP)+3',
        '\tMPY NUM',
        '\tSTQ RS)2+0',
        '\tCLA RS)2',
        '\tADD CP)+1',
        '\tSTO RS)0',
        '\tCLA RS)1',
        '\tADD RS)0',
        '\tSTO X',
      ]);
    });
  });
}
