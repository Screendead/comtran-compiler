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

  group('the storage map (M4-7)', () {
    late CodegenResult result;

    setUpAll(() => result = runCodegen(_payrollSemantics()));

    test('reproduces the committed golden byte for byte', () {
      expect(
        '${renderObjectLines(result.units).join('\n')}\n',
        File('test/goldens/90.05-payroll.storage-map').readAsStringSync(),
      );
    });

    test('the phase generates the whole of Location Counter 0', () {
      // The data region and the procedure text: LOC 00000 through 01620.
      expect(result.image.inlineWords, _octal('1621'));
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
}
