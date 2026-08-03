import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

List<SourceCard> _cards(List<String> lines) {
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return [for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1)];
}

String _card({
  String name = '',
  String type = '',
  String options = '',
  bool continued = false,
}) {
  final line =
      '${' ' * 6}${name.padRight(16)}${' ' * 2}${type.padRight(6)}'
      '${options.padRight(41)}${continued ? 'X' : ' '}';
  return line.trimRight();
}

void main() {
  group('specification assembly', () {
    test('splits options on commas and blanks', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(
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
        _cards([_card(type: 'SPECIF', options: "PAYFILE, UNIT1 'D3',OPENW")]),
      );
      expect(scan.diagnostics, isEmpty);
      final List<Token> tokens = scan.specs.single.optionTokens;
      expect(tokens[3].kind, TokenKind.alphamericLiteral);
      expect(tokens[3].text, 'D3');
    });

    test('a specification continues across cards', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(
            name: 'PAYFILE',
            type: 'FILE',
            options: 'OUTPUT,PAYRECORD,',
            continued: true,
          ),
          _card(options: 'BLOCKSIZE 20'),
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
        _cards([_card(name: 'STRAY', options: 'INPUT')]),
      );
      expect(scan.specs, isEmpty);
      expect(scan.diagnostics.single.message, msgIllegalEnvironmentType);
      expect(scan.diagnostics.single.severity, 3);
    });

    test('FILE and COND cards without names draw 1,00 and 88,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(type: 'FILE', options: 'INPUT'),
          _card(type: 'COND', options: "'77'"),
        ]),
      );
      expect(scan.diagnostics.map((Diagnostic d) => d.message), [
        msgFileCardLacksName,
        msgCondCardLacksName,
      ]);
    });

    test('a name continues across cards and compresses its blanks', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(
            name: 'DEPARTMENT.TOTAL',
            type: 'FILE',
            options: 'OUTPUT,',
            continued: true,
          ),
          _card(name: '.FILE', options: 'BLOCKSIZE 20'),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      expect(scan.specs.single.name, 'DEPARTMENT.TOTAL.FILE');
      final EnvironmentScan blanks = scanEnvironment(
        _cards([_card(name: 'PAY ROLL', type: 'FILE', options: 'INPUT')]),
      );
      // Imbedded blanks are eliminated (J 02.03.01, section 2.b).
      expect(blanks.specs.single.name, 'PAYROLL');
    });

    test('type content on a continuation card draws 186,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(name: 'F', type: 'FILE', options: 'INPUT,', continued: true),
          _card(type: 'FILE', options: 'BLOCKSIZE 3'),
        ]),
      );
      expect(scan.specs.single.optionTokens.map((Token t) => t.text), [
        'INPUT', ',', 'BLOCKSIZE', '3', //
      ]);
      expect(scan.diagnostics.single.message, msgFixedFieldOnContinuation);
    });

    test('an unclosed literal draws 167,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(name: 'F', type: 'FILE', options: "UNIT1 'D3")]),
      );
      expect(scan.diagnostics.single.message, msgSecondQuoteMissing);
    });
  });

  group('the 90.05 deck', () {
    test('scans to exactly 14 specifications with no diagnostics', () {
      final SourceProgram program = SourceProgram.fromDeck(
        decodeCanon(File('tests/90.05-payroll.ctdeck').readAsBytesSync()),
      );
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
