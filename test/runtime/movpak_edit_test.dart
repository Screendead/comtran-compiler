/// The edited-field members (RT-5): the renderer against every attested
/// rendering, the seven sign conventions, Blank When Zero, and the three
/// edited moves a compiled program reaches.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';
import '../support/deck_fixtures.dart';
import 'movpak_support.dart';

/// TARGET-CONTROL-WORD ([J 90.02.17] Note 2): the digits ahead of the
/// first comma, the digits ahead of the real or implied point, the sign
/// convention, and the leading run of `8` or `*` positions.
int control({
  required int integer,
  int prefix = 0,
  int convention = 0,
  int protected = 0,
}) => typeA(prefix, decrement: integer, tag: convention, address: protected);

/// The five-word SYS)267 call the generator emits, over an accumulator
/// value ([J 90.05] listing, LOC 01145).
Machine store(
  int edit,
  int word,
  int count, {
  int magnitude = 0,
  int sign = 0,
}) {
  final Machine subject = machine(<int, int>{
    start: tsx(180),
    start + 1: pze(targetArea, 0),
    start + 2: txi(267, edit),
    start + 3: word,
    start + 4: axt(count),
    start + 5: endOfJob,
    for (var i = 0; i < 3; i++) targetArea + i: characters('ZZZZZZ'),
  });
  subject.state
    ..acMagnitude = magnitude
    ..acSign = sign;
  expect(subject.run(maxSteps: 30).outcome, RunOutcome.endOfJob);
  return subject;
}

/// An edit run behind `TSX SYS)182,4`: the head, its control word, the
/// steps, and the terminator ([J 90.05] listing, LOC 00605).
Machine editRun(List<int> words, {List<int> sourceImage = const <int>[]}) {
  final Machine subject = machine(<int, int>{
    sourceCell: pze(sourceArea, 0),
    targetCell: pze(targetArea, 0),
    start: tsx(182),
    for (var i = 0; i < words.length; i++) start + 1 + i: words[i],
    start + 1 + words.length: endOfJob,
    for (var i = 0; i < sourceImage.length; i++) sourceArea + i: sourceImage[i],
    for (var i = 0; i < 3; i++) targetArea + i: characters('ZZZZZZ'),
  });
  expect(subject.run(maxSteps: 40).outcome, RunOutcome.endOfJob);
  return subject;
}

/// The image the renderer wrote: the target's characters up to the fill
/// no member touched.
String image(Machine subject) =>
    glyphsAt(subject, targetArea, 18).replaceFirst(RegExp(r'Z+$'), '');

void main() {
  group('every attested rendering (RT-5)', () {
    /// [edit] and [word] against the pictorial the case names.
    void renders(
      String pictorial,
      String expected, {
      required int edit,
      required int word,
      required int count,
      int magnitude = 0,
    }) => expect(
      image(store(edit, word, count, magnitude: magnitude)),
      expected,
      reason: pictorial,
    );

    test('the report page and both range tables', () {
      // The four columns of `images/page-217.png` (M6's oracle), then
      // the three minimum images F p. 81 prints for its range table.
      renders(
        '8889.9',
        '  40.0',
        edit: 0x04,
        word: control(integer: 4, protected: 3),
        count: 5,
        magnitude: 400,
      );
      renders(
        '8889.99',
        '   0.00',
        edit: 0x04,
        word: control(integer: 4, protected: 3),
        count: 6,
      );
      renders(
        '88889.99',
        '   37.50',
        edit: 0x04,
        word: control(integer: 5, protected: 4),
        count: 7,
        magnitude: 3750,
      );
      renders(
        '899V99',
        ' 3750',
        edit: 0,
        word: control(integer: 3, protected: 1),
        count: 5,
        magnitude: 3750,
      );
      renders(
        r'$8889.99',
        r' $294.12',
        edit: 0x0C,
        word: control(integer: 4, protected: 3),
        count: 6,
        magnitude: 29412,
      );
      renders(
        '88999',
        '  000',
        edit: 0,
        word: control(integer: 5, protected: 2),
        count: 5,
      );
      renders(
        '****.99',
        '****.00',
        edit: 0x05,
        word: control(integer: 4, protected: 4),
        count: 6,
      );
    });

    test('the dollar floats into a comma cell', () {
      // F p. 80 lets a comma be "replaced by a … dollar sign", which
      // only a floating dollar explains.
      final int word = control(prefix: 3, integer: 6, protected: 6);
      renders(r'$888,888.99', r'       $.00', edit: 0x0E, word: word, count: 8);
      renders(
        r'$888,888.99',
        r'  $1,234.45',
        edit: 0x0E,
        word: word,
        count: 8,
        magnitude: 123445,
      );
    });

    test('a value past the digit count drops its high-order digits', () {
      // The same discard the digit-split divide performs, and it arms
      // nothing (D4.2).
      renders(
        '8889.99',
        '9876.54',
        edit: 0x04,
        word: control(integer: 4, protected: 3),
        count: 6,
        magnitude: 129876540 ~/ 10,
      );
    });

    test('Blank When Zero blanks the whole image', () {
      // "The field is to be replaced with blanks" (J 02.05.07; D3.2).
      final int word = control(integer: 4, protected: 3);
      renders('8889.99', '       ', edit: 0x14, word: word, count: 6);
      renders(
        '8889.99',
        '   1.00',
        edit: 0x14,
        word: word,
        count: 6,
        magnitude: 100,
      );
    });
  });

  group('the sign conventions (J 90.02.17 Note 2)', () {
    String signed(int convention, int sign) => image(
      store(
        0,
        control(integer: 3, convention: convention),
        3,
        magnitude: 123,
        sign: sign,
      ),
    );

    test('an overpunch rides the last digit', () {
      // Zone 1 is the 12 punch and zone 2 the 11 punch (D0.6): `L` is
      // 3 over an 11 and `C` is 3 over a 12.
      expect(signed(1, 1), '12L');
      expect(signed(1, 0), '123', reason: 'convention 1 leaves a plus bare');
      expect(signed(2, 1), '12L');
      expect(signed(2, 0), '12C');
    });

    test('a reserved position takes a minus, a plus, or a blank', () {
      // "Plus or minus sign, one of which will always be placed in the
      // space reserved for it"; a minus convention leaves the space
      // blank on a positive value (F p. 80).
      expect(signed(3, 1), '123-');
      expect(signed(3, 0), '123 ');
      expect(signed(4, 0), '123+');
      expect(signed(5, 1), '-123');
      expect(signed(6, 0), '+123');
    });
  });

  group('the edit run builds the digit string (RT-5)', () {
    test('the attested edited-to-edited move renders end to end', () {
      // LOC 01373: `TXI SYS)190,1,4 / OCT 000005000004 /
      // TXI SYS)214,1,2 / TXI SYS)198,1,5 / TXI SYS)226,1,7` over the
      // five-character source `899V99` holding 03750 ([J 90.05]).
      final Machine subject = editRun(
        <int>[
          txi(190, 4),
          control(integer: 5, protected: 4),
          txi(214, 2),
          txi(198, 5),
          txi(226, 7),
        ],
        sourceImage: <int>[characters('03750 ')],
      );
      expect(image(subject), '   37.50');
    });

    test('a suppressed source position is a digit worth zero', () {
      // The edited source reads back the blanks and asterisks its own
      // rendering left (RT-4), and skips the insertion characters.
      final Machine subject = editRun(
        <int>[
          txi(190, 4),
          control(integer: 4, protected: 3),
          txi(198, 6),
          txi(226, 6),
        ],
        sourceImage: <int>[characters('**1,23'), characters('4     ')],
      );
      expect(image(subject), '  12.34');
    });

    test('the trailing zeros land behind the moved digits', () {
      final Machine subject = editRun(
        <int>[
          txi(185, 4),
          control(integer: 5, protected: 4),
          txi(212, 2),
          txi(193, 4),
          txi(211, 1),
          txi(225, 7),
        ],
        sourceImage: <int>[characters('1234  ')],
      );
      expect(image(subject), '  123.40');
    });

    test('an invalid source character arms SYS)131 and renders', () {
      // D4.3: the low four bits of `.` (octal 33) are the digit 11,
      // which prints the code's own glyph. No exception, and no stop.
      final Machine subject = editRun(
        <int>[txi(185, 0), control(integer: 3), txi(193, 3), txi(225, 3)],
        sourceImage: <int>[characters('1.3   ')],
      );
      expect(image(subject), '1=3');
      expect(subject.state.read(conditionCell), isNot(0));
    });
  });

  group('a compiled program renders into storage (M4-17)', () {
    test('the three edited moves write their images', () {
      // A literal into a group primes each subfield, and the two
      // converts then drive SYS)267, SYS)185 and SYS)190 in turn.
      final (JobCompilation job, Machine subject) = compiled(<String>[
        '      *DATA',
        dataCard(name: 'G1', level: '1'),
        dataCard(name: 'EXT', level: '2', mode: 'E', description: '999V9'),
        dataCard(name: 'G3', level: '1'),
        dataCard(name: 'ED3', level: '2', description: '899V99'),
        dataCard(
          name: 'NUM',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: '9(4)V99',
        ),
        dataCard(name: 'EDT', level: '1', description: r'$8889.99'),
        dataCard(name: 'ED2', level: '1', description: '88889.99'),
        dataCard(name: 'ED4', level: '1', description: '88889.99'),
        '      *PROCEDURE',
        "      START.  MOVE '1234' TO G1,",
        "            MOVE '03750' TO G3,",
        '            MOVE EXT TO NUM,',
        '            MOVE NUM TO EDT,',
        '            MOVE EXT TO ED2,',
        '            MOVE ED3 TO ED4.',
        '            STOP RUN.',
        '      *FINISH',
      ]);
      expect(glyphsAt(subject, addressOf(job, 'EDT'), 8), r'  $12.34');
      expect(glyphsAt(subject, addressOf(job, 'ED2'), 8), '  123.40');
      expect(glyphsAt(subject, addressOf(job, 'ED4'), 8), '   37.50');
    });
  });
}
