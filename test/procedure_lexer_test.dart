import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

ProcedureScan _scan(List<String> lines) {
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return scanProcedure([
    for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1),
  ]);
}

List<String> _texts(ProcedureSentence sentence) => [
  for (final Token t in sentence.tokens) t.text,
];

void main() {
  group('sentences and labels', () {
    test('a named sentence with commentary after the terminator', () {
      final ProcedureScan scan = _scan([
        '      START. MOVE A TO B. COMMENT AFTER.',
      ]);
      expect(scan.diagnostics, isEmpty);
      final ProcedureSentence s = scan.sentences.single;
      expect(s.label, 'START');
      expect(s.labelColumn, 7);
      expect(s.terminated, isTrue);
      expect(_texts(s), ['MOVE', 'A', 'TO', 'B']);
    });

    test('a sentence spans cards; a margin name closes an open one', () {
      final ProcedureScan scan = _scan([
        '            MOVE A',
        '                 TO B',
        '      NEXT. STOP RUN.',
      ]);
      expect(scan.sentences, hasLength(2));
      final ProcedureSentence first = scan.sentences[0];
      expect(first.label, isNull);
      expect(first.terminated, isFalse);
      expect(_texts(first), ['MOVE', 'A', 'TO', 'B']);
      expect(first.cards.map((SourceCard c) => c.cardNumber), [1, 2]);
      expect(scan.diagnostics.single.message, msgPeriodAssumed);
      expect(scan.diagnostics.single.card.cardNumber, 3);
      final ProcedureSentence second = scan.sentences[1];
      expect(second.label, 'NEXT');
      expect(second.terminated, isTrue);
      expect(_texts(second), ['STOP', 'RUN']);
    });

    test('an unterminated sentence at the end of the division', () {
      final ProcedureScan scan = _scan(['            GO TO A']);
      expect(scan.sentences.single.terminated, isFalse);
      expect(scan.diagnostics.single.message, msgPeriodAssumed);
    });

    test('a compound name keeps its imbedded periods', () {
      final ProcedureScan scan = _scan([
        '      BOND.END. GO TO END.OF.MASTERS.',
      ]);
      expect(scan.sentences.single.label, 'BOND.END');
      expect(_texts(scan.sentences.single), ['GO', 'TO', 'END.OF.MASTERS']);
      expect(scan.diagnostics, isEmpty);
    });
  });

  group('literals and numbers', () {
    test('an alphameric literal keeps blanks and periods', () {
      final ProcedureScan scan = _scan(["            MOVE 'AB  C.' TO X."]);
      expect(scan.diagnostics, isEmpty);
      final Token literal = scan.sentences.single.tokens[1];
      expect(literal.kind, TokenKind.alphamericLiteral);
      expect(literal.text, 'AB  C.');
    });

    test('an unclosed literal draws 168,00', () {
      final ProcedureScan scan = _scan(["            MOVE 'ABC"]);
      expect(
        scan.diagnostics.map((Diagnostic d) => d.message),
        contains(msgLiteralAcrossCards),
      );
    });

    test('an over-long literal draws 150,00', () {
      final ProcedureScan scan = _scan(["            MOVE '${'A' * 51}'."]);
      expect(scan.diagnostics.single.message, msgLiteralTooLong);
    });

    test('numeric and floating literals follow the J forms', () {
      final ProcedureScan scan = _scan([
        '            SET X = 1.5 * RATE / 40, Y = 20.F+01, Z = 3.FF2.',
      ]);
      expect(scan.diagnostics, isEmpty);
      final List<Token> tokens = scan.sentences.single.tokens;
      final Map<String, TokenKind> kinds = {
        for (final Token t in tokens) t.text: t.kind,
      };
      expect(kinds['1.5'], TokenKind.numericLiteral);
      expect(kinds['40'], TokenKind.numericLiteral);
      expect(kinds['20.F+01'], TokenKind.floatingLiteral);
      expect(kinds['3.FF2'], TokenKind.floatingLiteral);
    });

    test('a point-free F form is an arithmetic expression, not floating', () {
      final ProcedureScan scan = _scan(['            SET X = 20F+01.']);
      expect(scan.diagnostics, isEmpty);
      expect(_texts(scan.sentences.single), [
        'SET', 'X', '=', '20', 'F', '+', '01', //
      ]);
    });

    test('an F without a following digit draws 53,00', () {
      final ProcedureScan scan = _scan(['            SET X = 20.F TO Y.']);
      expect(scan.diagnostics.single.message, msgIncorrectNumericForm);
    });

    test('two decimal points draw 53,00', () {
      final ProcedureScan scan = _scan(['            SET X = 1.2.3.']);
      expect(scan.diagnostics.single.message, msgIncorrectNumericForm);
      expect(scan.sentences.single.tokens[3].text, '1.2.3');
    });

    test('an over-long numeric literal draws 52,00', () {
      final ProcedureScan scan = _scan(['            SET X = ${'9' * 51}.']);
      expect(scan.diagnostics.single.message, msgNumericLengthExceeded);
    });

    test('a stray period draws 900,00 and is ignored', () {
      final ProcedureScan scan = _scan(['            MOVE .X TO B.']);
      expect(scan.diagnostics.single.message, msgStrayPeriod);
      expect(_texts(scan.sentences.single), ['MOVE', 'X', 'TO', 'B']);
    });

    test('a word over 30 characters draws 901,00', () {
      final ProcedureScan scan = _scan(['            MOVE ${'A' * 31} TO B.']);
      expect(scan.diagnostics.single.message, msgNameTooLong);
    });

    test('a trailing period after a numeral terminates the sentence', () {
      final ProcedureScan scan = _scan(['            SET X = 2.']);
      expect(scan.diagnostics, isEmpty);
      final ProcedureSentence s = scan.sentences.single;
      expect(s.terminated, isTrue);
      expect(s.tokens.last.text, '2');
      expect(s.tokens.last.kind, TokenKind.numericLiteral);
    });
  });

  group('symbols and specials', () {
    test('operators, parentheses, commas, and exponentiation', () {
      final ProcedureScan scan = _scan([
        '            DO PAY FOR X = 1(1)12, SET Y = X ** 2.',
      ]);
      expect(scan.diagnostics, isEmpty);
      expect(_texts(scan.sentences.single), [
        'DO', 'PAY', 'FOR', 'X', '=', '1', '(', '1', ')', '12', ',', //
        'SET', 'Y', '=', 'X', '**', '2',
      ]);
    });

    test('a period in column 72 terminates the sentence', () {
      final ProcedureScan scan = _scan(['            GO TO A${' ' * 52}.']);
      expect(scan.sentences.single.terminated, isTrue);
      expect(scan.diagnostics, isEmpty);
    });

    test('NOTE text is kept raw up to the period-blank', () {
      final ProcedureScan scan = _scan([
        r'            NOTE THIS $ TEXT, (ANY FORM) = OK. MOVE A.',
      ]);
      expect(scan.diagnostics, isEmpty);
      final List<Token> tokens = scan.sentences.single.tokens;
      expect(tokens[0].text, 'NOTE');
      expect(tokens[1].kind, TokenKind.noteText);
      expect(tokens[1].text, r'THIS $ TEXT, (ANY FORM) = OK');
      expect(scan.sentences.single.terminated, isTrue);
    });

    test('a dollar sign in procedure text is a symbol, not an error', () {
      final ProcedureScan scan = _scan([r'            MOVE $ TO X.']);
      expect(scan.diagnostics, isEmpty);
      final Token dollar = scan.sentences.single.tokens[1];
      expect(dollar.kind, TokenKind.symbol);
      expect(dollar.text, r'$');
    });

    test('a machine special in a word draws 134,00 and reads as zero', () {
      final columns = List<int>.filled(80, 0);
      const String text = 'MOVE AXB TO C.';
      for (var i = 0; i < text.length; i++) {
        if (text[i] != ' ') {
          columns[12 + i] = punchesFromBcd(bcdFromGlyph(text[i])!)!;
        }
      }
      columns[18] = punchesFromBcd(0x3A)!; // record mark over the X
      final ProcedureScan scan = scanProcedure([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      final Diagnostic d = scan.diagnostics.single;
      expect(d.message, msgIllegalCharacterReplaced);
      expect(d.column, 19);
      expect(d.severity, 1);
      expect(scan.sentences.single.tokens[1].text, 'A0B');
      expect(scan.sentences.single.terminated, isTrue);
    });

    test('a machine special inside a literal is legal (D9.10 layer c)', () {
      final columns = List<int>.filled(80, 0);
      const String text = "MOVE 'AXB' TO C.";
      for (var i = 0; i < text.length; i++) {
        if (text[i] != ' ') {
          columns[12 + i] = punchesFromBcd(bcdFromGlyph(text[i])!)!;
        }
      }
      columns[19] = punchesFromBcd(0x3A)!; // record mark over the X
      final ProcedureScan scan = scanProcedure([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      expect(scan.diagnostics, isEmpty);
      final Token literal = scan.sentences.single.tokens[1];
      expect(literal.kind, TokenKind.alphamericLiteral);
      expect(literal.text, 'A?B');
    });

    test('a special in commentary after the terminator is not gated', () {
      final columns = List<int>.filled(80, 0);
      const String text = 'GO TO A.';
      for (var i = 0; i < text.length; i++) {
        if (text[i] != ' ') {
          columns[12 + i] = punchesFromBcd(bcdFromGlyph(text[i])!)!;
        }
      }
      columns[40] = punchesFromBcd(0x3A)!; // record mark in commentary
      final ProcedureScan scan = scanProcedure([
        SourceCard(CardImage.fromColumns(columns), 1),
      ]);
      expect(scan.diagnostics, isEmpty);
      expect(scan.sentences.single.terminated, isTrue);
    });
  });

  group('the 90.05 deck', () {
    test('scans to exactly 43 sentences with no diagnostics', () {
      final SourceProgram program = SourceProgram.fromDeck(
        decodeCanon(File('tests/90.05-payroll.ctdeck').readAsBytesSync()),
      );
      final ProcedureScan scan = scanProcedure(
        program.cardsOf(Division.procedure),
      );
      expect(scan.diagnostics, isEmpty);
      expect(scan.sentences, hasLength(43));
      expect(scan.sentences.every((ProcedureSentence s) => s.terminated), true);
      expect(scan.sentences.first.tokens.first.text, 'CALL');
      final Iterable<String?> labels = scan.sentences.map(
        (ProcedureSentence s) => s.label,
      );
      expect(labels, contains('BOND.END'));
      expect(labels, contains('START'));
      expect(labels, contains('COMPARE.EMPLOYEE.NUMBERS'));
    });
  });
}
