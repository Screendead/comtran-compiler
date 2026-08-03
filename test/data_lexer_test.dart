import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

void main() {
  group('entry assembly', () {
    test('a continued name is compressed across cards', () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(name: 'EMPLOYEE.NUM', level: '3', continued: true),
          dataCard(name: '   BER'),
          dataCard(name: 'NAME', level: '3', description: 'A(15)'),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      expect(scan.entries, hasLength(2));
      final DataEntry first = scan.entries[0];
      expect(first.name, 'EMPLOYEE.NUMBER');
      expect(first.level, 3);
      expect(first.cards.map((SourceCard c) => c.cardNumber), [1, 2]);
      expect(scan.entries[1].descriptionTokens.single.text, 'A(15)');
    });

    test('fixed fields on a continuation card draw 186,00', () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(name: 'LONG.NAME.FIELDX', level: '2', continued: true),
          dataCard(name: 'YZ', level: '3'),
        ]),
      );
      expect(scan.entries.single.name, 'LONG.NAME.FIELDXYZ');
      expect(scan.diagnostics.single.message, msgFixedFieldOnContinuation);
      expect(scan.diagnostics.single.severity, 1);
    });

    test('a named entry without a level draws 194,00; unnamed does not', () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(name: 'ORPHAN'),
          dataCard(type: 'REDEF', description: 'TABLE'),
        ]),
      );
      expect(scan.diagnostics.single.message, msgDataNameLacksLevel);
      expect(scan.diagnostics.single.card.cardNumber, 1);
      final DataEntry redef = scan.entries[1];
      expect(redef.name, isEmpty);
      expect(redef.level, isNull);
      expect(redef.typeText, 'REDEF');
    });

    test('illegal mode and justification characters draw 189,00/190,00', () {
      final DataScan scan = scanDataDescription(
        sourceCards([dataCard(name: 'A', level: '1', mode: 'X', justify: 'Q')]),
      );
      expect(scan.diagnostics.map((Diagnostic d) => d.message), [
        msgIllegalMode,
        msgIllegalJustification,
      ]);
    });

    test('a name over 30 characters compressed across cards draws 901,00', () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(name: 'A' * 16, level: '2', continued: true),
          dataCard(name: 'B' * 16, description: '99'),
        ]),
      );
      expect(scan.diagnostics.single.message, msgNameTooLong);
      expect(scan.entries.single.name.length, 32);
    });
  });

  group('description scanning', () {
    test('runs and constants split on blanks, keeping constant blanks', () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(name: 'V', level: '2', description: "9(5) '00 99'"),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      final List<Token> tokens = scan.entries.single.descriptionTokens;
      expect(tokens, hasLength(2));
      expect(tokens[0].kind, TokenKind.descriptionItem);
      expect(tokens[0].text, '9(5)');
      expect(tokens[1].kind, TokenKind.alphamericLiteral);
      expect(tokens[1].text, '00 99');
    });

    test('a constant continues across cards with no assumed blank', () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(
            name: 'C',
            level: '2',
            description: "'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFG",
            continued: true,
          ),
          dataCard(description: "HIJ'"),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      final Token constant = scan.entries.single.descriptionTokens.single;
      expect(constant.text, 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJ');
    });

    test('an unclosed constant at the entry end draws 167,00, untrimmed', () {
      final DataScan scan = scanDataDescription(
        sourceCards([dataCard(name: 'C', level: '2', description: "'OPEN")]),
      );
      expect(scan.diagnostics.single.message, msgSecondQuoteMissing);
      // The card's unpunched tail does not pad the constant.
      expect(scan.entries.single.descriptionTokens.single.text, 'OPEN');
    });

    test('a short constant joins across cards with no card-tail blanks', () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(name: 'C', level: '2', description: "'AB", continued: true),
          dataCard(description: "CD'"),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      expect(scan.entries.single.descriptionTokens.single.text, 'ABCD');
    });

    test('continuation-card leading blanks never pad a constant (D1.1)', () {
      // The continuation's content starts twelve columns in; the parts
      // still join with no padding or alignment between them.
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(name: 'C', level: '2', description: "'AB", continued: true),
          dataCard(description: "${' ' * 12}CD'"),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      expect(scan.entries.single.descriptionTokens.single.text, 'ABCD');
    });

    test("blanks after a continuation card's first content are kept", () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(name: 'C', level: '2', description: "'AB", continued: true),
          dataCard(description: "C D'"),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      expect(scan.entries.single.descriptionTokens.single.text, 'ABC D');
    });

    test('an over-long pictorial draws 100,00', () {
      final DataScan scan = scanDataDescription(
        sourceCards([dataCard(name: 'P', level: '2', description: '9' * 31)]),
      );
      expect(scan.diagnostics.single.message, msgPictorialTooLong);
    });

    test('a constant longer than 120 characters draws 148,00', () {
      final DataScan scan = scanDataDescription(
        sourceCards([
          dataCard(level: '2', description: "'${'A' * 33}", continued: true),
          dataCard(description: 'B' * 34, continued: true),
          dataCard(description: 'C' * 34, continued: true),
          dataCard(description: "${'D' * 25}'"),
        ]),
      );
      expect(scan.diagnostics.single.message, msgConstantTooLong);
      expect(scan.entries.single.descriptionTokens.single.text.length, 126);
    });

    test('a name-shaped run over 30 characters draws 901,00', () {
      // Unlike the pictorial case above, this run's characters ('B') do
      // not fit the format-character set, so it takes msgNameTooLong
      // rather than msgPictorialTooLong (lib/src/lexer/data_lexer.dart).
      final DataScan scan = scanDataDescription(
        sourceCards([dataCard(name: 'W', level: '2', description: 'B' * 31)]),
      );
      expect(scan.diagnostics.single.message, msgNameTooLong);
      expect(scan.entries.single.descriptionTokens.single.text, 'B' * 31);
    });
  });

  group('the character gate (D9.10)', () {
    test('a record mark in the name field draws 134,00 and reads as 0', () {
      final List<int> columns = blankColumns();
      punchGlyphs(columns, 7, 'NAM');
      columns[7] = punchesFromBcd(0x3A)!; // record mark, column 8
      punchGlyphs(columns, 24, '2'); // level
      punchGlyphs(columns, 38, '99'); // description
      final DataScan scan = scanDataDescription([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      final Diagnostic d = scan.diagnostics.single;
      expect(d.message, msgIllegalCharacterReplaced);
      expect(d.column, 8);
      expect(scan.entries.single.name, 'N0M');
    });

    test('a record mark in the fixed fields draws 134,00 (first card)', () {
      final List<int> columns = blankColumns();
      columns[22] = punchesFromBcd(0x3A)!; // record mark, column 23 (level)
      punchGlyphs(columns, 38, '99'); // description
      final DataScan scan = scanDataDescription([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      final Diagnostic d = scan.diagnostics.single;
      expect(d.message, msgIllegalCharacterReplaced);
      expect(d.column, 23);
      expect(scan.entries.single.level, isNull);
    });

    test('a record mark in a description run draws 134,00', () {
      final List<int> columns = blankColumns();
      punchGlyphs(columns, 38, 'ABC');
      columns[38] = punchesFromBcd(0x3A)!; // record mark, column 39
      final DataScan scan = scanDataDescription([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      final Diagnostic d = scan.diagnostics.single;
      expect(d.message, msgIllegalCharacterReplaced);
      expect(d.column, 39);
      expect(scan.entries.single.descriptionTokens.single.text, 'A0C');
    });

    test('a punch with no read-out inside a constant draws 134,00 '
        '(D9.10 layer a)', () {
      final List<int> columns = blankColumns();
      punchGlyphs(columns, 38, "'A");
      columns[39] = rowBit12 | rowBit11; // no BCD readout, column 40
      punchGlyphs(columns, 41, "B'");
      final DataScan scan = scanDataDescription([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      final Diagnostic d = scan.diagnostics.single;
      expect(d.message, msgIllegalCharacterReplaced);
      expect(d.column, 40);
      expect(scan.entries.single.descriptionTokens.single.text, 'A0B');
    });

    test('a record mark inside a constant is legal, read as ? (layer c)', () {
      final List<int> columns = blankColumns();
      punchGlyphs(columns, 38, "'A");
      columns[39] = punchesFromBcd(0x3A)!; // record mark, column 40
      punchGlyphs(columns, 41, "B'");
      final DataScan scan = scanDataDescription([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      expect(scan.diagnostics, isEmpty);
      expect(scan.entries.single.descriptionTokens.single.text, 'A?B');
    });
  });

  group('the 90.05 deck', () {
    late DataScan scan;

    setUpAll(() {
      final program = SourceProgram.fromDeck(loadPayrollDeck());
      scan = scanDataDescription(program.cardsOf(Division.data));
    });

    test('scans to exactly 172 entries with no diagnostics', () {
      expect(scan.diagnostics, isEmpty);
      expect(scan.entries, hasLength(172));
      final Iterable<DataEntry> twoCard = scan.entries.where(
        (DataEntry e) => e.cards.length == 2,
      );
      expect(twoCard, hasLength(5));
    });

    test('reads the MASTER record entry', () {
      final DataEntry master = scan.entries.first;
      expect(master.name, 'MASTER');
      expect(master.level, 1);
      expect(master.typeText, 'RECORD');
      expect(master.justifyText, 'L');
      expect(master.modeText, isEmpty);
    });

    test('reads the RATE entry with mode and justification', () {
      final DataEntry rate = scan.entries.firstWhere(
        (DataEntry e) => e.name == 'RATE',
      );
      expect(rate.level, 2);
      expect(rate.modeText, 'I');
      expect(rate.justifyText, 'R');
      expect(rate.descriptionTokens.single.text, '99V999');
    });

    test('assembles the continued EMPLOYEE.NUMBER names', () {
      // Statements 3,00 and 103,00 continue the name onto a second card.
      expect(
        scan.entries.where(
          (DataEntry e) => e.name == 'EMPLOYEE.NUMBER' && e.cards.length == 2,
        ),
        hasLength(2),
      );
    });

    test('reads the TABLE region: quantities, constants, REDEF', () {
      final DataEntry tableItem = scan.entries.firstWhere(
        (DataEntry e) => e.name == 'TABLE.ITEM',
      );
      expect(tableItem.quantity, 12);
      final DataEntry redef = scan.entries.firstWhere(
        (DataEntry e) => e.typeText == 'REDEF',
      );
      expect(redef.name, isEmpty);
      expect(redef.level, isNull);
      expect(redef.descriptionTokens.single.text, 'TABLE');
      final Iterable<DataEntry> constants = scan.entries.where(
        (DataEntry e) =>
            e.name.isEmpty &&
            e.descriptionTokens.any(
              (Token t) => t.kind == TokenKind.alphamericLiteral,
            ),
      );
      expect(constants, hasLength(56));
    });
  });
}
