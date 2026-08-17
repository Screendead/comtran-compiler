/// The refusal sites of chunks B1 through B6 (M4-2 as amended
/// 2026-08-15):
/// a valid shape the sample never reaches has no attested generated
/// form, so the sizers throw [UnrecoveredShape] rather than invent one.
/// Every site a valid program reaches is pinned here, one program per
/// site; the driver's per-job scoping of the refusal is in
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

  group('the B2 refusal sites (M4-9)', () {
    test('an in-line address word for a located item', () {
      expect(
        _refuses(
          ['            MOVE NUM TO IEDT.'],
          data: [
            ..._data(),
            dataCard(name: 'IREC', level: '1', type: 'RECORD'),
            dataCard(name: 'IEDT', level: '2', description: r'$889.99'),
          ],
          environment: [
            environmentCard(
              name: 'TAPE1',
              type: 'FILE',
              options: 'INPUT,BCD,TAPE,IREC,BLOCKSIZE 5',
            ),
          ],
        ),
        'an in-line address word for a located item (catalogue 4.3)',
      );
    });

    test('two positional indicators over one array', () {
      expect(
        _refuses(
          [
            '            MOVE ETAB ECEL (IDX) TO EDT.',
            '            MOVE ETAB ECEL (IDY) TO EDT.',
          ],
          data: [
            ..._data(),
            dataCard(name: 'ETAB', level: '1', quantity: '12'),
            dataCard(name: 'ECEL', level: '2', mode: 'E', description: '999'),
          ],
        ),
        'two positional indicators over one array (no sample instance)',
      );
    });

    test('an edit run that bypasses source digits', () {
      expect(
        _refuses(
          ['            MOVE WIDE TO EDT.'],
          data: [
            ..._data(),
            dataCard(name: 'WIDE', level: '1', mode: 'E', description: '99999'),
          ],
        ),
        'an edit run that bypasses source digits (no sample instance)',
      );
    });

    test('an edited field with eight digits before its first comma', () {
      expect(
        _refuses(
          ['            MOVE EXT TO BIGEDT.'],
          data: [
            ..._data(),
            dataCard(name: 'BIGEDT', level: '1', description: '99999999,99'),
          ],
        ),
        'an edited field with eight digits before its first comma',
      );
    });

    test('the LOW.VALUE fill word', () {
      expect(
        _refuses(['            MOVE LOW.VALUE TO ALF.']),
        'the LOW.VALUE fill word (notes 6.1 item 20)',
      );
    });
  });

  group('the B3 refusal sites (M4-10)', () {
    test('a scaling store of a chain value', () {
      // The tail opens on `XCA`, which reads the MQ half, and a chain
      // finishes in the accumulator.
      expect(
        _refuses(['            SET NUM = FRAC + FRAC.']),
        'a scaling store of a chain value (no sample instance)',
      );
    });

    test('a scale alignment of a sub-chain', () {
      // The sub-chain's scale is below the chain's, and no one word
      // aligns a value the accumulator holds.
      expect(
        _refuses(['            SET FRAC = FRAC + (NUM + TOT).']),
        'a scale alignment of a sub-chain (no sample instance)',
      );
    });

    test('a product of a product', () {
      // The `XCA` step reads the complex factor in the accumulator, and
      // a product finishes in the MQ.
      expect(
        _refuses(['            SET NUM = NUM * TOT * IDX.']),
        'a product of a product (no sample instance)',
      );
    });

    test('a result-storage cell past the section reservation', () {
      // Section 0 reserves three cells and this chain parks four.
      expect(
        _refuses([
          '            SET NUM = NUM * TOT + NUM * TOT + NUM * TOT + NUM',
          '            * TOT.',
        ]),
        'result-storage cell 3 of section 0 (M4-10)',
      );
    });

    test('result storage past the last reserved section', () {
      // The reservation covers sections 0 to 3; the fourth has none.
      expect(
        _refuses([
          for (var i = 1; i <= 3; i++) ...[
            '      ${'S$i.'.padRight(12)}BEGIN SECTION.',
            '            END S$i.',
          ],
          '      ${'S4.'.padRight(12)}BEGIN SECTION.',
          '            SET NUM = NUM * TOT + NUM.',
          '            END S4.',
        ]),
        'result storage in section 4 (no sample instance)',
      );
    });
  });

  group('the B4 refusal sites (M4-11)', () {
    test('a nonzero literal comparand', () {
      expect(
        _refuses(['            IF 5 GT NUM THEN STOP RUN.']),
        'a nonzero literal comparand (no sample instance)',
      );
    });

    test('a subscripted accumulator comparand', () {
      expect(
        _refuses(['            IF TAB CELL (IDX) GT NUM THEN STOP RUN.']),
        'a subscripted accumulator comparand (no sample instance)',
      );
    });

    test('an unscaled zero comparand', () {
      // Both attested zero builds scale; an integer storage operand
      // leaves no scale to build.
      expect(
        _refuses(['            IF NUM = 0 THEN STOP RUN.']),
        'an unscaled zero comparand (no sample instance)',
      );
    });

    test('a subscripted alphameric comparand', () {
      expect(
        _refuses(['            IF ATAB ACEL (IDX) = ALF THEN STOP RUN.']),
        'a subscripted alphameric comparand (no sample instance)',
      );
    });

    test('an unequal-length alphameric comparison', () {
      // The D3.3 fold and the D5.3 truncation each wait for a site.
      expect(
        _refuses(['            IF ALF = SEVEN THEN STOP RUN.']),
        'an unequal-length alphameric comparison (no sample instance)',
      );
    });

    test('a comparison past one word', () {
      expect(
        _refuses(['            IF LONG = LONG THEN STOP RUN.']),
        'a comparison past one word (M4-11, the SYS)162 boundary)',
      );
    });
  });

  group('the B5 refusal sites (M4-12, M4-13)', () {
    test('a GO TO naming a DO-called procedure', () {
      // Msg 128 says the 1962 compiler bypassed the transfer, and no
      // listing site shows the bypass's object form, so the shape
      // stays unrecovered behind the message.
      expect(
        _refuses(
          ['            DO RTN.', '            GO TO RTN.'],
          flagged: ['128,00'],
        ),
        'a GO TO naming a celled procedure (M4-12)',
      );
    });

    test('a GO TO naming a section', () {
      // A section carries a cell even with no DO, and this shape
      // reaches the sizers with no diagnostic at all.
      expect(
        _refuses([
          '            GO TO SEC.',
          '      SEC.  BEGIN SECTION.',
          '            SET NUM = NUM + NUM.',
          '            END SEC.',
        ]),
        'a GO TO naming a celled procedure (M4-12)',
      );
    });

    test('a section beginning inside an open section', () {
      expect(
        _refuses([
          '      S1.   BEGIN SECTION.',
          '            SET NUM = NUM + NUM.',
          '      S2.   BEGIN SECTION.',
          '            SET NUM = NUM + NUM.',
          '            END S2.',
        ]),
        'a section beginning inside an open section (no sample instance)',
      );
    });

    test('an END inside an open paragraph and an open section', () {
      expect(
        _refuses([
          '      SEC.  BEGIN SECTION.',
          '            DO INNER.',
          '      INNER.  SET NUM = NUM + NUM.',
          '            END SEC.',
        ]),
        'an END inside an open paragraph and an open section '
        '(no sample instance)',
      );
    });

    test('an unnamed section', () {
      expect(
        _refuses(['            BEGIN SECTION.']),
        'an unnamed section (no sample instance)',
      );
    });

    test('a DO FOR index with no data definition', () {
      expect(
        _refuses(['            DO RTN FOR ZZZ = 1(1)12.'], flagged: ['108,00']),
        'a DO FOR index with no data definition (no sample instance)',
      );
    });

    test('a located DO FOR index', () {
      expect(
        _refuses(
          ['            DO RTN FOR LIDX = 1(1)12.'],
          data: [
            ..._data(),
            dataCard(name: 'LREC', level: '1', type: 'RECORD'),
            dataCard(
              name: 'LIDX',
              level: '2',
              mode: 'I',
              justify: 'R',
              description: '99',
            ),
          ],
          environment: [
            environmentCard(
              name: 'TAPE1',
              type: 'FILE',
              options: 'INPUT,BCD,TAPE,LREC,BLOCKSIZE 5',
            ),
          ],
        ),
        'a located DO FOR index (no sample instance)',
      );
    });

    test('a DO FOR driving two indicators', () {
      expect(
        _refuses(
          [
            '            IF NUM = TAB CELL (IDX) THEN STOP RUN.',
            '            IF NUM = TAB2 CEL2 (IDX) THEN STOP RUN.',
            '            DO RTN FOR IDX = 1(1)12.',
          ],
          data: [
            ..._data(),
            dataCard(name: 'TAB2', level: '1', quantity: '12'),
            dataCard(
              name: 'CEL2',
              level: '2',
              mode: 'I',
              justify: 'R',
              description: '999',
            ),
          ],
        ),
        'a DO FOR driving two indicators (M4-6; no sample instance)',
      );
    });

    test('a transfer to an undefined procedure', () {
      // Msg 127 says the 1962 compiler bypassed the transfer; the
      // deferred binder would punch address 0 instead.
      expect(
        _refuses(['            GO TO AWAY.'], flagged: ['127,00']),
        'a transfer or call to an undefined procedure '
        '(behind msgs 127 and 188)',
      );
    });

    test('a call of an undefined procedure', () {
      expect(
        _refuses(['            DO AWAY.'], flagged: ['188,00']),
        'a transfer or call to an undefined procedure '
        '(behind msgs 127 and 188)',
      );
    });

    test('a two-word procedure reference', () {
      // The D2.5 section-qualified form is valid upstream
      // (transfer_checks_test.dart) but the binder holds single-word
      // labels only.
      expect(
        _refuses([
          '            GO TO S X.',
          '      S.    BEGIN SECTION.',
          '      X.    SET NUM = NUM + NUM.',
          '            END S.',
        ]),
        'a two-word procedure reference (D2.5; no sample instance)',
      );
    });

    test('a procedure name defined twice', () {
      // D2.5 scopes the two X labels to their sections; the flat
      // binder would keep only the later address.
      expect(
        _refuses([
          '      S1.   BEGIN SECTION.',
          '      X.    SET NUM = NUM + NUM.',
          '            END S1.',
          '      S2.   BEGIN SECTION.',
          '      X.    SET NUM = NUM + TOT.',
          '            END S2.',
        ]),
        'a procedure name defined twice (no sample instance)',
      );
    });

    test('a label bound to no word', () {
      // NOTE emits no word, so a trailing labelled NOTE never reaches
      // the binder; no _tail, whose words would take the label.
      final SemanticResult semantics = runJob(
        data: _data(),
        procedure: [
          '            GO TO X.',
          '            STOP RUN.',
          '      X.    NOTE DONE.',
        ],
      );
      expect(ids(semantics), isEmpty);
      expect(semantics.stopped, isFalse);
      try {
        runCodegen(semantics);
        fail('generated code without refusing');
      } on UnrecoveredShape catch (refusal) {
        expect(refusal.shape, 'a label bound to no word (no sample instance)');
      }
    });

    test('a procedure open at the end of the text', () {
      // No _tail here: its label would close the paragraph.
      final SemanticResult semantics = runJob(
        data: _data(),
        procedure: [
          '            DO PARA.',
          '            STOP RUN.',
          '      PARA.  SET NUM = NUM + NUM.',
        ],
      );
      expect(ids(semantics), isEmpty);
      expect(semantics.stopped, isFalse);
      try {
        runCodegen(semantics);
        fail('generated code without refusing');
      } on UnrecoveredShape catch (refusal) {
        expect(
          refusal.shape,
          'a procedure open at the end of the text (no sample instance)',
        );
      }
    });
  });

  group('the B6 refusal sites (M4-2 as amended)', () {
    test('STOP n', () {
      expect(_refuses(['            STOP 5.']), 'STOP n (notes section 7)');
    });

    test('an OPEN naming files', () {
      expect(
        _refuses(
          ['            OPEN TAPE1.'],
          data: _records(),
          environment: [_input()],
        ),
        'an OPEN naming files (notes section 7)',
      );
    });

    test('a CLOSE naming files', () {
      expect(
        _refuses(
          ['            CLOSE TAPE1.'],
          data: _records(),
          environment: [_input()],
        ),
        'a CLOSE naming files (notes section 7)',
      );
    });

    test('GET RECORD FROM', () {
      expect(
        _refuses(
          ['            GET RECORD FROM TAPE1, AT END RTN.'],
          data: _records(),
          environment: [_input()],
        ),
        'GET RECORD FROM (no sample instance)',
      );
    });

    test('a GET with no AT END', () {
      expect(
        _refuses(
          ['            GET IREC.'],
          data: _records(),
          environment: [_input()],
        ),
        'a GET with no AT END (notes section 7)',
      );
    });

    test('a GET of a name no FILE card lists', () {
      expect(
        _refuses(
          ['            GET NUM, AT END RTN.'],
          data: _records(),
          environment: [_input()],
          flagged: ['16,00', '198,00'],
        ),
        'a GET of a name no FILE card lists (no sample instance)',
      );
    });

    test('a GET record on two input files', () {
      expect(
        _refuses(
          ['            GET IREC, AT END RTN.'],
          data: _records(),
          environment: [
            _input(),
            environmentCard(
              name: 'TAPE3',
              type: 'FILE',
              options: 'INPUT,BCD,TAPE,IREC,BLOCKSIZE 5',
            ),
          ],
          flagged: ['11,00'],
        ),
        'a GET record on 2 input files (no sample instance)',
      );
    });

    test('a GET of a transmitted record', () {
      // CARD forces the transmit mode (J 02.07.03).
      expect(
        _refuses(
          ['            GET IREC, AT END RTN.'],
          data: _records(),
          environment: [
            environmentCard(
              name: 'TAPE1',
              type: 'FILE',
              options: 'INPUT,BCD,CARD,IREC,BLOCKSIZE 24',
            ),
          ],
        ),
        'a GET of a transmitted record (no sample instance)',
      );
    });

    test('a GET from a file declaring ON ERROR', () {
      expect(
        _refuses(
          ['            GET IREC, AT END RTN.'],
          data: _records(),
          environment: [
            environmentCard(
              name: 'TAPE1',
              type: 'FILE',
              options: 'INPUT,IREC,BLOCKSIZE 5,ON ERROR RTN',
            ),
          ],
        ),
        'a GET from a file declaring ON ERROR (notes section 7)',
      );
    });

    test('a GET where two FILE cards share a name', () {
      expect(
        _refuses(
          ['            GET IREC, AT END RTN.'],
          data: _records(),
          environment: [
            _input(),
            environmentCard(
              name: 'TAPE1',
              type: 'FILE',
              options: 'OUTPUT,BCD,TAPE,IREC,BLOCKSIZE 5',
            ),
          ],
          flagged: ['198,00'],
        ),
        'a GET where two FILE cards share a name (no sample instance)',
      );
    });

    test('FILE record IN file', () {
      expect(
        _refuses(
          ['            FILE OREC IN TAPE2.'],
          data: _records(),
          environment: [_output()],
        ),
        'FILE record IN file (no sample instance)',
      );
    });

    test('a FILE of a name no FILE card lists', () {
      expect(
        _refuses(
          ['            FILE NUM.'],
          data: _records(),
          environment: [_output()],
          flagged: ['16,00', '198,00'],
        ),
        'a FILE of a name no FILE card lists (no sample instance)',
      );
    });

    test('a FILE record on no output file', () {
      expect(
        _refuses(
          ['            FILE IREC.'],
          data: _records(),
          environment: [_input()],
          flagged: ['19,00', '198,00'],
        ),
        'a FILE record on 0 output files (no sample instance)',
      );
    });

    test('a FILE where two FILE cards share a name', () {
      expect(
        _refuses(
          ['            FILE OREC.'],
          data: _records(),
          environment: [
            _output(),
            environmentCard(
              name: 'TAPE2',
              type: 'FILE',
              options: 'INPUT,BCD,TAPE,OREC,BLOCKSIZE 5',
            ),
          ],
          flagged: ['198,00'],
        ),
        'a FILE where two FILE cards share a name (no sample instance)',
      );
    });
  });
}

/// Two one-field records and a flat item, for the input-output probes.
List<String> _records() => [
  dataCard(name: 'IREC', level: '1', type: 'RECORD'),
  dataCard(name: 'FLD', level: '2', description: 'A(6)'),
  dataCard(name: 'OREC', level: '1', type: 'RECORD'),
  dataCard(name: 'OFLD', level: '2', description: 'A(6)'),
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
];

String _input() => environmentCard(
  name: 'TAPE1',
  type: 'FILE',
  options: 'INPUT,BCD,TAPE,IREC,BLOCKSIZE 5',
);

String _output() => environmentCard(
  name: 'TAPE2',
  type: 'FILE',
  options: 'OUTPUT,BCD,TAPE,OREC,BLOCKSIZE 5',
);
