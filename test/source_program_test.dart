import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

SourceProgram _program(List<String> lines) =>
    SourceProgram.fromDeck(mirrorToDeck('${lines.join('\n')}\n'));

void main() {
  group('SourceCard', () {
    test('splits the card into serial, body, and identification', () {
      final SourceCard card = SourceCard(
        mirrorToDeck('123456ABC DEF${' ' * 59}IDENT99\n').single,
        1,
      );
      expect(card.serial, '123456');
      expect(card.body, 'ABC DEF${' ' * 59}');
      expect(card.identification, 'IDENT99 ');
      expect(card.glyphAt(7), 'A');
      expect(card.unreadableColumns(1, 80), isEmpty);
    });

    test('renders unreadable columns as blanks and reports them', () {
      final columns = List<int>.filled(80, 0);
      columns[6] = punchesFromBcd(bcdFromGlyph('A')!)!;
      columns[7] = punchesFromBcd(0x3A)!; // record mark, 0-2-8
      columns[8] = rowBit12 | rowBit11; // no readout
      columns[9] = punchesFromBcd(bcdFromGlyph('B')!)!;
      final SourceCard card = SourceCard(CardImage.fromColumns(columns), 1);
      expect(card.textRange(7, 10), 'A  B');
      expect(card.unreadableColumns(7, 10), [8, 9]);
      expect(card.glyphAt(8), isNull);
    });
  });

  group('SourceProgram.fromDeck', () {
    test('splits the 90.05 deck into its control card and divisions', () {
      final SourceProgram program = SourceProgram.fromDeck(
        decodeCanon(File('tests/90.05-payroll.ctdeck').readAsBytesSync()),
      );
      expect(program.compileCard?.cardNumber, 1);
      expect(program.compileCard?.body, startsWith('*COMPILE'));
      expect(program.finishCard, isNull);
      expect(program.problems, isEmpty);
      expect(program.groups.map((DivisionGroup g) => g.division), [
        Division.data,
        Division.environment,
        Division.procedure,
      ]);
      expect(program.cardsOf(Division.data).length, 177);
      expect(program.cardsOf(Division.environment).length, 15);
      expect(program.cardsOf(Division.procedure).length, 97);
      // The *PROCEDURE header's asterisk sits in column 8 on the real deck.
      expect(program.groups[2].header.glyphAt(8), '*');
    });

    test(r'recognizes the $CMPLE control card in columns 1-6', () {
      final SourceProgram program = _program([
        r'$CMPLE MYDECK  LIST',
        '      *DATA',
        '      A',
      ]);
      expect(program.compileCard?.serial, r'$CMPLE');
      expect(program.groups.single.division, Division.data);
      expect(program.problems, isEmpty);
    });

    test('flags cards before the first header and after *FINISH', () {
      final SourceProgram program = _program([
        'STRAY CARD',
        '      *DATA',
        '      A',
        '      *FINISH',
        'LATE CARD',
      ]);
      expect(program.problems, hasLength(2));
      expect(program.problems[0].card.cardNumber, 1);
      expect(program.problems[0].text, contains('precedes'));
      expect(program.finishCard?.cardNumber, 4);
      expect(program.problems[1].card.cardNumber, 5);
      expect(program.problems[1].text, contains('*FINISH'));
    });

    test('accepts repeated division groups and skips blank cards', () {
      final SourceProgram program = _program([
        '      *DATA',
        '      A',
        '',
        '      *PROCEDURE',
        '      GO TO A.',
        '      *DATA',
        '      B',
      ]);
      expect(program.groups, hasLength(3));
      expect(program.cardsOf(Division.data).length, 2);
      expect(program.cardsOf(Division.procedure).length, 1);
      expect(program.problems, isEmpty);
    });
  });
}
