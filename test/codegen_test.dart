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
    test("the block order places the sample's attested addresses", () {
      // Location Counter 1 begins at 01621 and reserves RS, TS, BL, PI,
      // then the pool. The listing attests all three results: `ORG
      // BL)1` at 01666, `BGN 2,PI)1` at 01671, and the pool at 01674.
      final image = ProgramImage(
        inlineWords: _octal('1621'),
        blockWords: const <StorageBlock, int>{
          StorageBlock.rs: 30,
          StorageBlock.ts: 7,
          StorageBlock.bl: 3,
          StorageBlock.pi: 3,
        },
      );
      expect(image.symbolAddress(StorageBlock.bl, 1), _octal('1666'));
      expect(image.symbolAddress(StorageBlock.pi, 1), _octal('1671'));
      expect(image.originOf(StorageBlock.cp), _octal('1674'));
      expect(image.poolAddress(0), _octal('1674'));
    });

    test('the sample needs three base locators', () {
      // One for the IOCS label area, one per located record — the
      // width the listing reserves for BL).
      expect(baseLocatorWords(_payrollSemantics()), 3);
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

    test('the phase generates the whole data region and stops for none', () {
      expect(result.stopped, isFalse);
      expect(result.codegenDiagnostics, isEmpty);
      // 117 words: LOC 00000 through 00164.
      expect(result.image.inlineWords, _octal('165'));
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
}
