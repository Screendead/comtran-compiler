import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

void main() {
  group('specification assembly', () {
    test('splits options on commas and blanks', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([
          environmentCard(
            name: 'INPUTMASTER',
            type: 'FILE',
            options: 'INPUT,BINARY,BLOCKSIZE 300',
          ),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      final EnvironmentSpec spec = scan.specs.single;
      expect(spec.name, 'INPUTMASTER');
      expect(spec.typeText, 'FILE');
      expect(
        [for (final Token t in spec.optionTokens) t.text],
        [
          'INPUT', ',', 'BINARY', ',', 'BLOCKSIZE', '300', //
        ],
      );
      expect(spec.optionTokens.last.kind, TokenKind.numericLiteral);
    });

    test('a quoted unit literal is one token', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([
          environmentCard(type: 'SPECIF', options: "PAYFILE, UNIT1 'D3',OPENW"),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      final List<Token> tokens = scan.specs.single.optionTokens;
      expect(tokens[3].kind, TokenKind.alphamericLiteral);
      expect(tokens[3].text, 'D3');
    });

    test('a specification continues across cards', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([
          environmentCard(
            name: 'PAYFILE',
            type: 'FILE',
            options: 'OUTPUT,PAYRECORD,',
            continued: true,
          ),
          environmentCard(options: 'BLOCKSIZE 20'),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      final EnvironmentSpec spec = scan.specs.single;
      expect(spec.cards, hasLength(2));
      expect(
        [for (final Token t in spec.optionTokens) t.text],
        [
          'OUTPUT', ',', 'PAYRECORD', ',', 'BLOCKSIZE', '20', //
        ],
      );
    });

    test('a first card without a legal type is deleted with 144,00', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([environmentCard(name: 'STRAY', options: 'INPUT')]),
      );
      expect(scan.specs, isEmpty);
      expect(scan.diagnostics.single.message, msgIllegalEnvironmentType);
      expect(scan.diagnostics.single.severity, 3);
    });

    test('FILE and COND cards without names draw 1,00 and 88,00', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([
          environmentCard(type: 'FILE', options: 'INPUT'),
          environmentCard(type: 'COND', options: "'77'"),
        ]),
      );
      expect(scan.diagnostics.map((Diagnostic d) => d.message), [
        msgFileCardLacksName,
        msgCondCardLacksName,
      ]);
    });

    test('a name continues across cards and compresses its blanks', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([
          environmentCard(
            name: 'DEPARTMENT.TOTAL',
            type: 'FILE',
            options: 'OUTPUT,',
            continued: true,
          ),
          environmentCard(name: '.FILE', options: 'BLOCKSIZE 20'),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      expect(scan.specs.single.name, 'DEPARTMENT.TOTAL.FILE');
      final EnvironmentScan blanks = scanEnvironment(
        sourceCards([
          environmentCard(name: 'PAY ROLL', type: 'FILE', options: 'INPUT'),
        ]),
      );
      // Imbedded blanks are eliminated (J 02.03.01, section 2.b).
      expect(blanks.specs.single.name, 'PAYROLL');
    });

    test('an over-30 compressed name draws 901,00', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([
          environmentCard(
            name: 'A' * 16,
            type: 'FILE',
            options: 'INPUT,',
            continued: true,
          ),
          environmentCard(name: 'B' * 16, options: 'BLOCKSIZE 3'),
        ]),
      );
      expect(scan.diagnostics.single.message, msgNameTooLong);
      expect(scan.specs.single.name.length, 32);
    });

    test('columns 23-24 belong to no field (J 02.06.01.01)', () {
      // A machine special in the never-scanned columns 23-24 draws no
      // 134,00 on the first card and no 186,00 on a continuation card.
      List<int> columns(String name, String type, String options) {
        final list = List<int>.filled(80, 0);
        void punch(int column, String text) {
          for (var i = 0; i < text.length; i++) {
            if (text[i] != ' ') {
              list[column - 1 + i] = punchesFromBcd(bcdFromGlyph(text[i])!)!;
            }
          }
        }

        punch(7, name);
        punch(25, type);
        punch(31, options);
        return list;
      }

      final List<int> first = columns('F', 'FILE', 'INPUT,');
      first[71] = punchesFromBcd(bcdFromGlyph('X')!)!; // continuation
      first[22] = punchesFromBcd(0x3A)!; // record mark, column 23
      final List<int> second = columns('', '', 'BLOCKSIZE 3');
      second[23] = punchesFromBcd(0x3A)!; // record mark, column 24
      final EnvironmentScan scan = scanEnvironment([
        SourceCard(CardImage.fromColumns(first), 1),
        SourceCard(CardImage.fromColumns(second), 2),
      ]);
      expect(scan.diagnostics, isEmpty);
      expect(scan.specs.single.typeText, 'FILE');
    });

    test('type content on a continuation card draws 186,00', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([
          environmentCard(
            name: 'F',
            type: 'FILE',
            options: 'INPUT,',
            continued: true,
          ),
          environmentCard(type: 'FILE', options: 'BLOCKSIZE 3'),
        ]),
      );
      expect(scan.specs.single.optionTokens.map((Token t) => t.text), [
        'INPUT', ',', 'BLOCKSIZE', '3', //
      ]);
      expect(scan.diagnostics.single.message, msgFixedFieldOnContinuation);
    });

    test('an unclosed literal draws 167,00', () {
      final EnvironmentScan scan = scanEnvironment(
        sourceCards([
          environmentCard(name: 'F', type: 'FILE', options: "UNIT1 'D3"),
        ]),
      );
      expect(scan.diagnostics.single.message, msgSecondQuoteMissing);
    });
  });

  group('the character gate (D9.10)', () {
    test('a record mark in a continuation name field draws 134,00', () {
      final List<int> columns1 = blankColumns();
      punchGlyphs(columns1, 7, 'PAYFILE');
      punchGlyphs(columns1, 25, 'FILE');
      columns1[71] = punchesFromBcd(bcdFromGlyph('X')!)!; // continuation
      final List<int> columns2 = blankColumns();
      columns2[6] = punchesFromBcd(0x3A)!; // record mark, column 7
      final EnvironmentScan scan = scanEnvironment([
        SourceCard(CardImage.fromColumns(columns1), 1),
        SourceCard(CardImage.fromColumns(columns2), 2),
      ]);
      final Diagnostic d = scan.diagnostics.single;
      expect(d.message, msgIllegalCharacterReplaced);
      expect(d.column, 7);
      expect(scan.specs.single.name, 'PAYFILE0');
    });

    test('a record mark in an option run draws 134,00', () {
      final List<int> columns = blankColumns();
      punchGlyphs(columns, 7, 'F');
      punchGlyphs(columns, 25, 'FILE');
      punchGlyphs(columns, 31, 'ABC');
      columns[31] = punchesFromBcd(0x3A)!; // record mark, column 32
      final EnvironmentScan scan = scanEnvironment([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      final Diagnostic d = scan.diagnostics.single;
      expect(d.message, msgIllegalCharacterReplaced);
      expect(d.column, 32);
      expect(scan.specs.single.optionTokens.single.text, 'A0C');
    });

    test('a punch with no read-out inside a literal draws 134,00 '
        '(D9.10 layer a)', () {
      final List<int> columns = blankColumns();
      punchGlyphs(columns, 7, 'F');
      punchGlyphs(columns, 25, 'FILE');
      punchGlyphs(columns, 31, "UNIT1 'A");
      columns[38] = rowBit12 | rowBit11; // no BCD readout, column 39
      punchGlyphs(columns, 40, "B'");
      final EnvironmentScan scan = scanEnvironment([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      final Diagnostic d = scan.diagnostics.single;
      expect(d.message, msgIllegalCharacterReplaced);
      expect(d.column, 39);
      expect(scan.specs.single.optionTokens[1].text, 'A0B');
    });

    test('a record mark inside a literal is legal, read as ? (layer c)', () {
      final List<int> columns = blankColumns();
      punchGlyphs(columns, 7, 'F');
      punchGlyphs(columns, 25, 'FILE');
      punchGlyphs(columns, 31, "UNIT1 'A");
      columns[38] = punchesFromBcd(0x3A)!; // record mark, column 39
      punchGlyphs(columns, 40, "B'");
      final EnvironmentScan scan = scanEnvironment([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      expect(scan.diagnostics, isEmpty);
      expect(scan.specs.single.optionTokens[1].text, 'A?B');
    });
  });

  group('the 90.05 deck', () {
    test('scans to exactly 14 specifications with no diagnostics', () {
      final program = SourceProgram.fromDeck(loadPayrollDeck());
      final EnvironmentScan scan = scanEnvironment(
        program.cardsOf(Division.environment),
      );
      expect(scan.diagnostics, isEmpty);
      expect(scan.specs, hasLength(14));
      expect(
        scan.specs.where((EnvironmentSpec s) => s.typeText == 'FILE'),
        hasLength(7),
      );
      expect(
        scan.specs.where((EnvironmentSpec s) => s.typeText == 'SPECIF'),
        hasLength(7),
      );
      final EnvironmentSpec payfile = scan.specs.firstWhere(
        (EnvironmentSpec s) => s.name == 'PAYFILE',
      );
      expect(payfile.cards, hasLength(2));
      expect([
        for (final Token t in payfile.optionTokens) t.text,
      ], containsAllInOrder(['PAYRECORD', ',', 'DEPARTMENT.TOTAL']));
      final EnvironmentSpec specif = scan.specs[1];
      expect(specif.typeText, 'SPECIF');
      expect(specif.name, isEmpty);
      expect(specif.optionTokens.first.text, 'INPUTMASTER');
    });
  });
}
