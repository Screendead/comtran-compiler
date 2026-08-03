import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

List<SourceCard> _cards(List<String> lines) {
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return [for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1)];
}

// Builds a data card from its fields at the documented columns.
String _card({
  String name = '',
  String level = '',
  String type = '',
  String quantity = '',
  String mode = '',
  String justify = '',
  String description = '',
  bool continued = false,
}) {
  final line =
      '${' ' * 6}${name.padRight(16)}${level.padLeft(2)}${type.padRight(6)}'
      '${quantity.padLeft(5)}${mode.padRight(1)}${justify.padRight(1)}'
      '${description.padRight(34)}${continued ? 'X' : ' '}';
  return line.trimRight();
}

void main() {
  group('entry assembly', () {
    test('a continued name is compressed across cards', () {
      final DataScan scan = scanDataDescription(
        _cards([
          _card(name: 'EMPLOYEE.NUM', level: '3', continued: true),
          _card(name: '   BER'),
          _card(name: 'NAME', level: '3', description: 'A(15)'),
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
        _cards([
          _card(name: 'LONG.NAME.FIELDX', level: '2', continued: true),
          _card(name: 'YZ', level: '3'),
        ]),
      );
      expect(scan.entries.single.name, 'LONG.NAME.FIELDXYZ');
      expect(scan.diagnostics.single.message, msgFixedFieldOnContinuation);
      expect(scan.diagnostics.single.severity, 1);
    });

    test('a named entry without a level draws 194,00; unnamed does not', () {
      final DataScan scan = scanDataDescription(
        _cards([
          _card(name: 'ORPHAN'),
          _card(type: 'REDEF', description: 'TABLE'),
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
        _cards([_card(name: 'A', level: '1', mode: 'X', justify: 'Q')]),
      );
      expect(scan.diagnostics.map((Diagnostic d) => d.message), [
        msgIllegalMode,
        msgIllegalJustification,
      ]);
    });
  });

  group('description scanning', () {
    test('runs and constants split on blanks, keeping constant blanks', () {
      final DataScan scan = scanDataDescription(
        _cards([_card(name: 'V', level: '2', description: "9(5) '00 99'")]),
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
        _cards([
          _card(
            name: 'C',
            level: '2',
            description: "'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFG",
            continued: true,
          ),
          _card(description: "HIJ'"),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      final Token constant = scan.entries.single.descriptionTokens.single;
      expect(constant.text, 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJ');
    });

    test('an unclosed constant at the entry end draws 167,00', () {
      final DataScan scan = scanDataDescription(
        _cards([_card(name: 'C', level: '2', description: "'OPEN")]),
      );
      expect(scan.diagnostics.single.message, msgSecondQuoteMissing);
    });

    test('an over-long pictorial draws 100,00', () {
      final DataScan scan = scanDataDescription(
        _cards([_card(name: 'P', level: '2', description: '9' * 31)]),
      );
      expect(scan.diagnostics.single.message, msgPictorialTooLong);
    });

    test('a constant longer than 120 characters draws 148,00', () {
      final DataScan scan = scanDataDescription(
        _cards([
          _card(level: '2', description: "'${'A' * 33}", continued: true),
          _card(description: 'B' * 34, continued: true),
          _card(description: 'C' * 34, continued: true),
          _card(description: "${'D' * 25}'"),
        ]),
      );
      expect(scan.diagnostics.single.message, msgConstantTooLong);
      expect(scan.entries.single.descriptionTokens.single.text.length, 126);
    });
  });

  group('the 90.05 deck', () {
    late DataScan scan;

    setUpAll(() {
      final SourceProgram program = SourceProgram.fromDeck(
        decodeCanon(File('tests/90.05-payroll.ctdeck').readAsBytesSync()),
      );
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
      expect(constants.length, greaterThanOrEqualTo(23));
    });
  });
}
