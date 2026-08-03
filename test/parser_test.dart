import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

FrontEndResult _frontEnd(String mirror) => runFrontEnd(mirrorToDeck(mirror));

// Builds a data card from its fields at the documented columns.
String _dataCard({
  String name = '',
  String level = '',
  String type = '',
  String mode = '',
  String description = '',
}) {
  final line =
      '${' ' * 6}${name.padRight(16)}${level.padLeft(2)}${type.padRight(6)}'
      '${' ' * 5}${mode.padRight(1)} ${description.padRight(34)}';
  return line.trimRight();
}

void main() {
  group('the 90.05 deck', () {
    late final FrontEndResult result;
    late final ParseResult parse;

    setUpAll(() {
      result = runFrontEnd(
        decodeCanon(File('tests/90.05-payroll.ctdeck').readAsBytesSync()),
      );
      parse = runParser(result);
    });

    test('parses with zero parser diagnostics', () {
      expect(result.diagnostics, isEmpty);
      expect(parse.parserDiagnostics, isEmpty);
      expect(parse.maxSeverity, 0);
    });

    test('yields one parsed group per division', () {
      expect(parse.groups, hasLength(3));
      expect(parse.groups[0], isA<ParsedDataGroup>());
      expect(parse.groups[1], isA<ParsedEnvironmentGroup>());
      expect(parse.groups[2], isA<ParsedProcedureGroup>());
      expect((parse.groups[0] as ParsedDataGroup).items, hasLength(172));
      final ParsedDataGroup data = parse.groups[0] as ParsedDataGroup;
      // The division's twelve level-1 entries: seven records, the four
      // working/total/table groups, and TABLE.ITEM.
      expect(data.roots, hasLength(12));
    });

    test('parses the compile card', () {
      expect(parse.compileCard!.options, ['LIST']);
      expect(parse.compileCard!.secondaryIdentifier, 'CT PUBLICATIONS');
    });

    test('leaves the golden listing unchanged (design note M2-2)', () {
      const options = ListingOptions(date: '10/18/61', time: '2.45');
      expect(
        writeListing(result, options, diagnostics: parse.diagnostics),
        writeListing(result, options),
      );
    });
  });

  test('merged diagnostics order by card number across phases', () {
    // Card 2 draws a parser diagnostic (907, withdrawn type code); card
    // 3 draws a front-end diagnostic (189, illegal mode). The merged
    // block orders them by card, not by phase (design note M2-2).
    final FrontEndResult result = _frontEnd(
      '      *DATA\n'
      '${_dataCard(name: 'A', level: '2', type: 'FUNCT', description: '99')}\n'
      '${_dataCard(name: 'B', level: '2', mode: 'Z', description: '99')}\n',
    );
    expect(result.diagnostics.single.message.number, '189,00');
    final ParseResult parse = runParser(result);
    // The parser adds 907 on card 2 and — the deck has no STOP RUN —
    // 175 on the last card (D2.7).
    expect(parse.diagnostics.map((Diagnostic d) => d.message.number), [
      '907,00',
      '189,00',
      '175,00',
    ]);
    expect(parse.diagnostics.map((Diagnostic d) => d.card.cardNumber), [
      2,
      3,
      3,
    ]);
    expect(parse.maxSeverity, 4);
  });
}
