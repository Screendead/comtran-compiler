import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

FrontEndResult _frontEnd(String mirror) => runFrontEnd(mirrorToDeck(mirror));

void main() {
  group('the 90.05 deck', () {
    late final FrontEndResult result;
    late final ParseResult parse;

    setUpAll(() {
      result = runFrontEnd(loadPayrollDeck());
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
      final data = parse.groups[0] as ParsedDataGroup;
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
      '${dataCard(name: 'A', level: '2', type: 'FUNCT', description: '99')}\n'
      '${dataCard(name: 'B', level: '2', mode: 'Z', description: '99')}\n',
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
    expect(parse.diagnostics.map((Diagnostic d) => d.card!.cardNumber), [
      2,
      3,
      3,
    ]);
    expect(parse.maxSeverity, 4);
  });

  group('the severity-5 stop path (D9.1; D10.2)', () {
    // A Data Description constant over 120 characters draws 148,00 at
    // severity 5 (D7.9).
    final List<String> overLongConstant = [
      dataCard(level: '2', description: "'${'A' * 33}", continued: true),
      dataCard(description: 'B' * 34, continued: true),
      dataCard(description: 'C' * 34, continued: true),
      dataCard(description: "${'D' * 25}'"),
    ];

    test('a front-end severity 5 stops the scan at its point', () {
      final sink = DiagnosticSink();
      final FrontEndResult result = runFrontEnd(
        mirrorToDeck(
          [
            '      *DATA',
            ...overLongConstant,
            // Unscanned after the stop: this pictorial would draw 100,00.
            dataCard(name: 'P', level: '2', description: '9' * 31),
            '      *PROCEDURE',
            '            STOP RUN.',
          ].map((String l) => '$l\n').join(),
        ),
        sink: sink,
      );
      expect(result.stopped, isTrue);
      expect(result.diagnostics.last.message.number, '148,00');
      expect(
        result.diagnostics.map((Diagnostic d) => d.message.number),
        isNot(contains('100,00')),
      );
      // The stopped group and everything after it are unscanned.
      expect(result.groupScans, isEmpty);
      expect(sink.stopped, isTrue);
      expect(sink.maxSeverity, 5);
    });

    test('a parser severity 5 stops the parse and shares the sink', () {
      final lines = <String>['      *PROCEDURE'];
      for (var i = 1; i <= 36; i++) {
        lines
          ..add('      ${'S$i.'.padRight(12)}BEGIN SECTION.')
          ..add('            END S$i.');
      }
      lines.add('            STOP RUN.');
      final sink = DiagnosticSink();
      final FrontEndResult result = runFrontEnd(
        mirrorToDeck('${lines.join('\n')}\n'),
        sink: sink,
      );
      expect(result.stopped, isFalse);
      final ParseResult parse = runParser(result, sink: sink);
      expect(parse.stopped, isTrue);
      expect(parse.parserDiagnostics.single.message.number, '149,00');
      expect(sink.stopped, isTrue);
      expect(sink.maxSeverity, 5);
    });

    test('one sink spans both phases with the running maximum', () {
      final sink = DiagnosticSink();
      final FrontEndResult result = runFrontEnd(
        mirrorToDeck(
          '      *PROCEDURE\n'
          // The front end draws 900,00 (stray period); the parser draws
          // 125,00 (no verb) and 175,00 (no STOP RUN).
          '            GROSS . TO NET.\n',
        ),
        sink: sink,
      );
      final ParseResult parse = runParser(result, sink: sink);
      expect(result.stopped, isFalse);
      expect(parse.stopped, isFalse);
      expect(
        sink,
        hasLength(result.diagnostics.length + parse.parserDiagnostics.length),
      );
      expect(sink.maxSeverity, parse.maxSeverity);
      expect(sink.stopped, isFalse);
    });
  });
}
