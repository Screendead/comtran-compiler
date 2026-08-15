/// Chunk B1's refusal sites (M4-2 as amended 2026-08-15): a valid
/// shape the sample never reaches has no attested generated form, so
/// the sizers throw [UnrecoveredShape] rather than invent one. Every
/// site a valid program reaches is pinned here, one program per site;
/// the driver's per-job scoping of the refusal is in
/// `driver_test.dart`.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The shared data division: a twelve-element internal table and an
/// alphameric one, one flat field of each class the cases reference,
/// and a condition name.
List<String> _data() => [
  dataCard(name: 'TAB', level: '1', quantity: '12'),
  dataCard(
    name: 'CELL',
    level: '2',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(name: 'ATAB', level: '1', quantity: '12'),
  dataCard(name: 'ACEL', level: '2', description: 'A(6)'),
  dataCard(name: 'ALF', level: '1', description: 'A(6)'),
  dataCard(name: 'LONG', level: '1', description: 'A(12)'),
  dataCard(name: 'SEVEN', level: '1', description: 'A(7)'),
  dataCard(name: 'IDX', level: '1', mode: 'I', justify: 'R', description: '99'),
  dataCard(name: 'IDY', level: '1', mode: 'I', justify: 'R', description: '99'),
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(
    name: 'TOT',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(
    name: 'FRAC',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '9V9',
  ),
  dataCard(name: 'EXT', level: '1', mode: 'E', description: '999'),
  dataCard(name: 'FLT', level: '1', mode: 'I', description: '9.9F9'),
  dataCard(name: 'EDT', level: '1', description: r'$889.99'),
  dataCard(name: 'STATE', level: '1', description: 'A'),
  dataCard(name: 'MARRIED', level: '2', type: 'COND', description: "'M'"),
  // A two-character field at byte 2 of its group's word, and a
  // two-character field at byte 0: the in-line pair no trigger covers.
  dataCard(name: 'GS', level: '1'),
  dataCard(level: '2', description: 'AA'),
  dataCard(name: 'SRC', level: '2', description: 'AA'),
  dataCard(name: 'TGT2', level: '1', description: 'AA'),
];

/// A target paragraph, so GO TO and DO have somewhere legal to land.
const List<String> _tail = <String>['      RTN.  STOP RUN.'];

/// Compiles one job to its semantics, asserts it reached code
/// generation carrying exactly [flagged] (diagnostics below the stop
/// severity, none by default), and returns the refusal's shape.
String _refuses(
  List<String> statements, {
  List<String>? data,
  List<String> environment = const [],
  List<String> flagged = const [],
}) {
  final SemanticResult semantics = runJob(
    data: data ?? _data(),
    environment: environment,
    procedure: [...statements, ..._tail],
  );
  expect(ids(semantics), flagged, reason: 'the program must reach the sizers');
  expect(semantics.stopped, isFalse);
  try {
    runCodegen(semantics);
  } on UnrecoveredShape catch (refusal) {
    return refusal.shape;
  }
  fail('generated code without refusing');
}

void main() {
  group('the B1 refusal sites (M4-2 as amended)', () {
    test('DISPLAY', () {
      expect(_refuses(['            DISPLAY 45.']), 'DISPLAY ([J 90.01.01])');
    });

    test('the assigned GO TO', () {
      expect(
        _refuses(['            GO TO (RTN, RTN) ON IDX.']),
        'the assigned GO TO (M4-12; no sample instance)',
      );
    });

    test('DO EXACTLY', () {
      expect(
        _refuses(['            DO RTN EXACTLY 5 TIMES.']),
        'DO EXACTLY / USING / GIVING (notes section 7)',
      );
    });

    test('a multi-index DO', () {
      expect(
        _refuses(['            DO RTN FOR IDX = 1(1)2, IDY = 1(1)2.']),
        'a multi-index DO (notes section 7)',
      );
    });

    test('a DO FOR driving no indicator', () {
      expect(
        _refuses(['            DO RTN FOR IDX = 1(1)12.']),
        'a DO FOR driving no indicator',
      );
    });

    test('SET of a condition name', () {
      expect(_refuses(['            SET MARRIED.']), 'SET of a condition name');
    });

    test('SET with a target list', () {
      expect(
        _refuses(['            SET NUM, TOT = NUM + TOT.']),
        'SET with a target list (no sample instance)',
      );
    });

    test('ON OVERFLOW', () {
      expect(
        _refuses(['            SET NUM = NUM + TOT, ON OVERFLOW GO TO RTN.']),
        'ON OVERFLOW (notes section 7)',
      );
    });

    test('ADD TRUNCATED', () {
      expect(
        _refuses(['            ADD NUM TO TOT TRUNCATED.']),
        'ADD TRUNCATED / ON OVERFLOW (notes section 7)',
      );
    });

    test('an ADD of a literal', () {
      expect(
        _refuses(['            ADD 1 TO NUM.']),
        'an ADD of a literal (no sample instance)',
      );
    });

    test('a subscripted ADD source', () {
      expect(
        _refuses(['            ADD TAB CELL (IDX) TO NUM.']),
        'a subscripted ADD source (no sample instance)',
      );
    });

    test('an ADD pair of unequal scales', () {
      expect(
        _refuses(['            ADD FRAC TO NUM.']),
        'an ADD pair of unequal scales (notes section 7)',
      );
    });

    test('a MOVE of a numeric literal', () {
      expect(
        _refuses(['            MOVE 5 TO NUM.']),
        'a MOVE of a numeric literal (no sample instance)',
      );
    });

    test('a subscripted alphameric move', () {
      expect(
        _refuses(['            MOVE ATAB ACEL (IDX) TO ALF.']),
        'a subscripted alphameric move (notes section 7)',
      );
    });

    test('an unattested class pair', () {
      expect(
        _refuses(['            MOVE EDT TO NUM.']),
        startsWith('a move of '),
      );
    });

    test('a subscripted edited-store source', () {
      expect(
        _refuses(['            MOVE TAB CELL (IDX) TO EDT.']),
        'a subscripted edited-store source (no sample instance)',
      );
    });

    test('a subscripted internal-decimal move', () {
      expect(
        _refuses(['            MOVE TAB CELL (IDX) TO NUM.']),
        'a subscripted internal-decimal move (no sample instance)',
      );
    });

    test('an internal-decimal move off its trigger', () {
      expect(
        _refuses(['            MOVE FRAC TO NUM.']),
        'an internal-decimal move off its trigger (catalogue 4.6)',
      );
    });

    test('a subscripted figurative target', () {
      expect(
        _refuses(['            MOVE ZERO TO TAB CELL (IDX).']),
        'a subscripted figurative target (notes section 7)',
      );
    });

    test('an in-line literal past one word', () {
      expect(
        _refuses(["            MOVE 'ABCDEFG' TO SEVEN."]),
        'an in-line literal past one word (notes section 7)',
      );
    });

    test('an alphameric comparison against a literal', () {
      expect(
        _refuses(["            IF ALF = 'ABCDEF' THEN STOP RUN."]),
        startsWith('a comparison of '),
      );
    });

    test('an in-line move outside the four triggers', () {
      expect(
        _refuses(['            MOVE GS SRC TO TGT2.']),
        'an in-line move outside the four triggers (notes 4.5)',
      );
    });

    test('an alphameric mover with the longer source', () {
      expect(
        _refuses(['            MOVE LONG TO ALF.']),
        'an alphameric mover with the longer source (notes 3.3)',
      );
    });

    test('the operator', () {
      expect(
        _refuses(['            SET NUM = NUM / TOT.']),
        startsWith('the operator '),
      );
    });

    test('a subscripted chain operand, one term', () {
      expect(
        _refuses(['            SET NUM = TAB CELL (IDX).']),
        'a subscripted chain operand (no sample instance)',
      );
    });

    test('a subscripted chain operand, several terms', () {
      expect(
        _refuses(['            SET NUM = TAB CELL (IDX) + NUM.']),
        'a subscripted chain operand (no sample instance)',
      );
    });

    test('a chain of a unary minus', () {
      expect(
        _refuses(['            SET NUM = -NUM.']),
        'a chain of UnaryExpr (no sample instance)',
      );
    });

    test('the scale of a unary minus', () {
      expect(
        _refuses(['            SET NUM = -NUM + TOT.']),
        'the scale of UnaryExpr',
      );
    });

    test('a product of two computed factors', () {
      expect(
        _refuses(['            SET NUM = (NUM + TOT) * (TOT + NUM).']),
        'a product of two computed factors (no sample instance)',
      );
    });

    test('a factor of a unary minus', () {
      expect(
        _refuses(['            SET NUM = (-NUM) * TOT.']),
        'a factor of UnaryExpr',
      );
    });

    test('a subscripted factor', () {
      expect(
        _refuses(['            SET NUM = NUM * TAB CELL (IDX).']),
        'a subscripted factor (no sample instance)',
      );
    });

    test('a subscripted SET target', () {
      expect(
        _refuses(['            SET TAB CELL (IDX) = NUM.']),
        'a subscripted SET target (no sample instance)',
      );
    });

    test('a store below the target scale', () {
      expect(
        _refuses(['            SET FRAC = NUM + TOT.']),
        'a store below the target scale (no sample instance)',
      );
    });

    test('a condition-name comparison', () {
      expect(
        _refuses(['            IF MARRIED THEN STOP RUN.']),
        'a compound or condition-name comparison (no sample instance)',
      );
    });

    test('a numeric comparison of an expression', () {
      expect(
        _refuses(['            IF NUM + TOT GT NUM THEN STOP RUN.']),
        startsWith('a comparison of '),
      );
    });

    test('a numeric comparison against an expression', () {
      expect(
        _refuses(['            IF NUM GT TOT + NUM THEN STOP RUN.']),
        startsWith('a comparison of '),
      );
    });

    test('an alphameric comparison of a literal', () {
      expect(
        _refuses(["            IF 'ABC' = ALF THEN STOP RUN."]),
        startsWith('a comparison of '),
      );
    });

    test('a blank figurative alphameric comparison', () {
      expect(
        _refuses(['            IF ALF = BLANKS THEN STOP RUN.']),
        'this figurative comparison (no sample instance)',
      );
    });

    test('a floating literal', () {
      expect(
        _refuses(['            SET NUM = 2.5F1.']),
        'a floating literal operand (no sample instance)',
      );
    });

    test('a floating literal in a comparison', () {
      expect(
        _refuses(['            IF NUM = 2.5F1 THEN STOP RUN.']),
        'a floating literal operand (no sample instance)',
      );
    });

    test('an alphameric literal in arithmetic', () {
      // The parser reports the shape (msg 912) below the stop
      // severity, so the sizers still see it.
      expect(
        _refuses(["            SET NUM = 'AB' + TOT."]),
        'an alphameric literal operand (no sample instance)',
      );
    });

    test('a floating-point chain operand', () {
      expect(
        _refuses(['            SET NUM = FLT + TOT.']),
        'an arithmetic operand of floatingPoint (no sample instance)',
      );
    });

    test('a floating-point SET target', () {
      expect(
        _refuses(['            SET FLT = NUM.']),
        'an arithmetic operand of floatingPoint (no sample instance)',
      );
    });

    test('a floating-point comparison', () {
      expect(
        _refuses(['            IF FLT = NUM THEN STOP RUN.']),
        'an arithmetic operand of floatingPoint (no sample instance)',
      );
    });

    test('a floating-point DO index', () {
      expect(
        _refuses(['            DO RTN FOR FLT = 1(1)12.']),
        'an arithmetic operand of floatingPoint (no sample instance)',
      );
    });

    test('a field-name DO FOR bound', () {
      expect(
        _refuses(['            DO RTN FOR IDX = NUM(1)12.']),
        'a DO FOR bound of NameOperand (no sample instance)',
      );
    });

    test('a negative DO FOR bound', () {
      expect(
        _refuses(['            DO RTN FOR IDX = -5(1)12.']),
        'a DO FOR bound of UnaryExpr (no sample instance)',
      );
    });

    test('an external-decimal chain operand', () {
      expect(
        _refuses(['            SET NUM = EXT + TOT.']),
        'an arithmetic operand of externalDecimal (no sample instance)',
      );
    });

    test('an edited chain operand', () {
      expect(
        _refuses(['            SET NUM = EDT + TOT.']),
        'an arithmetic operand of edited (no sample instance)',
      );
    });

    test('an external ADD source', () {
      expect(
        _refuses(['            ADD EXT TO NUM.']),
        'an arithmetic operand of externalDecimal (no sample instance)',
      );
    });

    test('an external ADD target', () {
      expect(
        _refuses(['            ADD NUM TO EXT.']),
        'an arithmetic operand of externalDecimal (no sample instance)',
      );
    });

    test('a chain of a truth function, several terms', () {
      expect(
        _refuses(['            SET NUM = NUM + TR (NUM GT TOT).']),
        'a chain of TruthExpr (no sample instance)',
      );
    });

    test('a mixed-class alphameric comparison', () {
      expect(
        _refuses(
          ['            IF ALF = NUM THEN STOP RUN.'],
          flagged: ['107,00'],
        ),
        'an alphameric comparison of internalDecimal (no sample instance)',
      );
    });

    test('a third base register in one statement', () {
      // Three input tape files, so one chain touches three located
      // records; M4-9 assigns XR1 and XR2 and stops.
      expect(
        _refuses(
          ['            SET NUM = FA + FB + FC.'],
          data: [
            dataCard(name: 'R1', level: '1', type: 'RECORD'),
            dataCard(
              name: 'FA',
              level: '2',
              mode: 'I',
              justify: 'R',
              description: '999',
            ),
            dataCard(name: 'R2', level: '1', type: 'RECORD'),
            dataCard(
              name: 'FB',
              level: '2',
              mode: 'I',
              justify: 'R',
              description: '999',
            ),
            dataCard(name: 'R3', level: '1', type: 'RECORD'),
            dataCard(
              name: 'FC',
              level: '2',
              mode: 'I',
              justify: 'R',
              description: '999',
            ),
            dataCard(
              name: 'NUM',
              level: '1',
              mode: 'I',
              justify: 'R',
              description: '999',
            ),
          ],
          environment: [
            environmentCard(
              name: 'TAPE1',
              type: 'FILE',
              options: 'INPUT,BCD,TAPE,R1,BLOCKSIZE 5',
            ),
            environmentCard(
              name: 'TAPE2',
              type: 'FILE',
              options: 'INPUT,BCD,TAPE,R2,BLOCKSIZE 5',
            ),
            environmentCard(
              name: 'TAPE3',
              type: 'FILE',
              options: 'INPUT,BCD,TAPE,R3,BLOCKSIZE 5',
            ),
          ],
        ),
        'a third base register in one statement (M4-9)',
      );
    });

    test('a positional indicator with no repeated ancestor', () {
      // The one route in is a program msg 98,00 already flags below
      // the stop severity — a subscripted flat item. The DO FOR must
      // come first: the flagged MOVE has a refusal site of its own.
      expect(
        _refuses(
          [
            '            DO RTN FOR IDY = 1(1)12.',
            '            MOVE STATE (IDY) TO ALF.',
          ],
          flagged: ['98,00'],
        ),
        'a positional indicator with no repeated ancestor',
      );
    });
  });
}
