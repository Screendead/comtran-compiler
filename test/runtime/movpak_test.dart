/// The non-edited MOVPAK members (RT-4): the pointer cells, the
/// external-decimal convert, the edited-field convert, and the four
/// character movers, each against its [J 90.02] contract.
library;

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

import '../support/deck_fixtures.dart';
import 'runtime_support.dart';

void main() {
  group('the pointer cells (J 90.02.11)', () {
    test('SYS)180 stores its in-line address word in the target cell', () {
      // The decrement is the byte and byte 0 is the word's high-order
      // character, so one blank lands where the address word points.
      for (final byte in <int>[0, 3]) {
        final Machine subject = machine(<int, int>{
          start: tsx(180),
          start + 1: pze(targetArea, byte),
          start + 2: txi(243, 1),
          start + 3: endOfJob,
          targetArea: characters('000000'),
        });
        expect(subject.run(maxSteps: 20).outcome, RunOutcome.endOfJob);
        expect(subject.state.read(targetCell), pze(targetArea, byte));
        expect(
          subject.state.read(targetArea),
          characters(byte == 0 ? ' 00000' : '000 00'),
          reason: 'byte $byte',
        );
      }
    });
    test('SYS)180 adds an MZE reference to its base locator', () {
      // `MZE BL)NN,,CP)+NN`: the locator holds the record's first word
      // and the constant the displacement, the sum the in-line `CAL /
      // ACL / SLW` builds (J 90.02.11 Case 2; J 90.02.14 Case 2).
      const int base = start + 0x40;
      const int displacement = start + 0x41;
      final Machine subject = machine(<int, int>{
        start: tsx(180),
        start + 1: Word36.signBit | pze(base, displacement),
        start + 2: txi(243, 1),
        start + 3: endOfJob,
        base: pze(targetArea, 0),
        displacement: pze(1, 3),
        targetArea + 1: characters('000000'),
      });
      expect(subject.run(maxSteps: 20).outcome, RunOutcome.endOfJob);
      expect(subject.state.read(targetCell), pze(targetArea + 1, 3));
      expect(subject.state.read(targetArea + 1), characters('000 00'));
    });
  });

  group('SYS)186, 187 and 188, internal to external decimal (J 90.02.18)', () {
    /// The store the generator emits, `TSX SYS)180,4 / PZE target,,0 /
    /// TXI SYS)entry,1,count`, over an accumulator of [sign] and
    /// [magnitude], into a target of asterisks.
    Machine develop(int entry, int count, int magnitude, {int sign = 0}) {
      final Machine subject = machine(<int, int>{
        start: tsx(180),
        start + 1: pze(targetArea, 0),
        start + 2: txi(entry, count),
        start + 3: endOfJob,
        targetArea: characters('******'),
      });
      subject.state
        ..acMagnitude = magnitude
        ..acSign = sign;
      expect(subject.run(maxSteps: 20).outcome, RunOutcome.endOfJob);
      expect(subject.state.xrRead(1), junkCount);
      return subject;
    }

    test('SYS)186 writes the digits and no sign', () {
      expect(glyphsAt(develop(186, 4, 123), targetArea, 6), '0123**');
      expect(glyphsAt(develop(186, 4, 123, sign: 1), targetArea, 6), '0123**');
    });

    test('SYS)187 overpunches a minus and leaves a plus digit plain', () {
      // `L` is 3 over an 11 punch (D0.6).
      expect(glyphsAt(develop(187, 3, 123), targetArea, 3), '123');
      expect(glyphsAt(develop(187, 3, 123, sign: 1), targetArea, 3), '12L');
    });

    test('SYS)188 overpunches both signs', () {
      // `C` is 3 over a 12 punch.
      expect(glyphsAt(develop(188, 3, 123), targetArea, 3), '12C');
      expect(glyphsAt(develop(188, 3, 123, sign: 1), targetArea, 3), '12L');
    });

    test('an overpunched zero is the 11-0 or the 12-0 punch', () {
      expect(codeAt(develop(187, 2, 10, sign: 1), targetArea, 1), octal('52'));
      expect(codeAt(develop(188, 2, 10), targetArea, 1), octal('32'));
    });

    test('a longer value drops its high-order digits and arms nothing', () {
      final Machine subject = develop(186, 3, 12345);
      expect(glyphsAt(subject, targetArea, 4), '345*');
      expect(subject.state.read(conditionCell), 0);
    });
  });

  group('SYS)184, external decimal to internal decimal (J 90.02.16)', () {
    Machine convert(int image, int count) =>
        dispatch(words: <int>[txi(184, count)], sourceImage: <int>[image]);

    test('digits convert to a positive binary value', () {
      final Machine subject = convert(characters('123   '), 3);
      expect(subject.state.acMagnitude, 123);
      expect(subject.state.acSign, 0);
      expect(subject.state.read(conditionCell), 0);
    });

    test('leading blanks are leading zeros', () {
      // "Numeric external fields may contain leading blanks which are
      // treated as leading zeros" (J 02.05.05 note 3).
      final Machine subject = convert(characters('  3   '), 3);
      expect(subject.state.acMagnitude, 3);
      expect(subject.state.read(conditionCell), 0);
    });

    test('the overpunch on the low-order digit carries the sign', () {
      // Zone 1 is the 12 punch and zone 2 the 11 punch (D0.6, D8.1):
      // `A` is 1 over a 12 and `J` is 1 over an 11.
      expect(convert(characters('12A   '), 3).state.acSign, 0);
      final Machine minus = convert(characters('12J   '), 3);
      expect(minus.state.acSign, 1);
      expect(minus.state.acMagnitude, 121);
    });

    test('an 11-0 low-order character is a minus zero', () {
      final Machine subject = convert(bcdWord(<int>[0x2A, 0, 0, 0, 0, 0]), 1);
      expect(subject.state.acSign, 1);
      expect(subject.state.acMagnitude, 0);
    });

    test('an invalid character arms SYS)131 and contributes four bits', () {
      // D4.3: no exception and no stop; the low four bits of `.`
      // (octal 33) are the digit 11.
      final Machine subject = convert(characters('1.3   '), 3);
      expect(subject.state.acMagnitude, 213);
      expect(subject.state.read(conditionCell), isNot(0));
    });

    test('more than ten digits is unimplemented', () {
      expect(
        () => dispatch(words: <int>[txi(184, 11)]),
        throwsA(
          isA<UnimplementedRuntimeEntry>().having(
            (UnimplementedRuntimeEntry e) => e.number,
            'number',
            184,
          ),
        ),
      );
    });
  });

  group('SYS)268, 269 and 275, an edited field to a register (J 90.02.30)', () {
    test('the attested five-digit fetch lands in the accumulator', () {
      // The one site: `TXI SYS)268,1,1 / TXI SYS)269,1,5 /
      // TXI SYS)275,1,5 / STO` over a five-digit source ([J 90.05]).
      final Machine subject = dispatch(
        words: <int>[txi(268, 1), txi(269, 5), txi(275, 5)],
        sourceImage: <int>[characters('12345 ')],
      );
      expect(subject.state.acMagnitude, 12345);
      expect(subject.state.acSign, 0);
    });

    test('an asterisk is a counted digit position worth zero', () {
      // The target control word counts the asterisks beside the 8's and
      // the 9's (J 90.02.17 Note 2), so a reader takes one for a digit.
      final Machine subject = dispatch(
        words: <int>[txi(268, 1), txi(269, 5), txi(275, 5)],
        sourceImage: <int>[characters('**123 ')],
      );
      expect(subject.state.acMagnitude, 123);
      expect(subject.state.read(conditionCell), 0);
    });

    test('an insertion character is stepped over and not counted', () {
      final Machine subject = dispatch(
        words: <int>[txi(268, 1), txi(269, 4), txi(275, 4)],
        sourceImage: <int>[characters('1,234 ')],
      );
      expect(subject.state.acMagnitude, 1234);
      expect(subject.state.read(conditionCell), 0);
    });

    test('an overpunch in the step is an improper data condition', () {
      // SYS)269 carries no sign note (RT-4): `J` is 1 over an 11.
      final Machine subject = dispatch(
        words: <int>[txi(268, 1), txi(269, 3), txi(275, 3)],
        sourceImage: <int>[characters('12J   ')],
      );
      expect(subject.state.acSign, 0);
      expect(subject.state.acMagnitude, 121);
      expect(subject.state.read(conditionCell), isNot(0));
    });

    test('more than ten digits is unimplemented', () {
      expect(
        () => dispatch(words: <int>[txi(268, 1), txi(269, 0), txi(275, 11)]),
        throwsA(
          isA<UnimplementedRuntimeEntry>().having(
            (UnimplementedRuntimeEntry e) => e.number,
            'number',
            275,
          ),
        ),
      );
    });
  });

  group('the character movers (J 90.02.23 to J 90.02.26)', () {
    test('SYS)239 moves equal lengths across both word boundaries', () {
      final Machine subject = dispatch(
        words: <int>[txi(239, 8)],
        sourceByte: 2,
        sourceImage: <int>[characters('QQABCD'), characters('EFGHQQ')],
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(subject.state.read(targetArea), characters('ABCDEF'));
      expect(subject.state.read(targetArea + 1), characters('GHZZZZ'));
    });

    test('SYS)240 and SYS)241 fill the excess with trailing blanks', () {
      // "The low-order positions of the receiving area, i.e., the
      // excess positions, will be filled with blanks" (F p. 42).
      final Machine subject = dispatch(
        words: <int>[txi(240, 4), txi(241, 4)],
        sourceByte: 2,
        targetByte: 4,
        sourceImage: <int>[characters('QQABCD')],
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(subject.state.read(targetArea), characters('ZZZZAB'));
      expect(subject.state.read(targetArea + 1), characters('CD    '));
    });

    test('SYS)243 writes blanks', () {
      final Machine subject = dispatch(
        words: <int>[txi(243, 8)],
        targetByte: 2,
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(subject.state.read(targetArea), characters('ZZ    '));
      expect(subject.state.read(targetArea + 1), characters('    ZZ'));
    });

    test('SYS)244 writes the character zero, not a zero word', () {
      final Machine subject = dispatch(
        words: <int>[txi(244, 8)],
        targetByte: 2,
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(subject.state.read(targetArea), characters('ZZ0000'));
      expect(subject.state.read(targetArea + 1), characters('0000ZZ'));
    });

    test('SYS)245 fills from its OCT word and cycles past six', () {
      final Machine exact = dispatch(
        words: <int>[txi(245, 6), characters('((((((')],
        targetImage: <int>[characters('ZZZZZZ')],
      );
      expect(exact.state.read(targetArea), characters('(((((('));
      final Machine cycled = dispatch(
        words: <int>[txi(245, 8), characters('ABCDEF')],
        targetByte: 2,
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(cycled.state.read(targetArea), characters('ZZABCD'));
      expect(cycled.state.read(targetArea + 1), characters('EFABZZ'));
    });
  });

  group('a compiled program reaches the members (M4-17)', () {
    test('the movers write their characters into storage', () {
      // `SRC` sits at byte 2 of its group, so every mover here crosses a
      // word boundary. HIGH.VALUE is the native `(` (D8.1).
      final (JobCompilation job, Machine subject) = compiled(<String>[
        '      *DATA',
        dataCard(name: 'G', level: '1'),
        dataCard(name: 'PAD', level: '2', description: 'A(2)'),
        dataCard(name: 'SRC', level: '2', description: 'A(6)'),
        dataCard(name: 'TGT', level: '1', description: 'A(6)'),
        dataCard(name: 'WIDE', level: '1', description: 'A(12)'),
        dataCard(name: 'ZED', level: '1', description: 'A(8)'),
        '      *PROCEDURE',
        '      START.  MOVE HIGH.VALUE TO SRC,',
        '            MOVE SRC TO TGT,',
        '            MOVE SRC TO WIDE,',
        '            MOVE ZEROS TO ZED,',
        '            MOVE BLANKS TO PAD.',
        '            STOP RUN.',
        '      *FINISH',
      ]);
      final int group = addressOf(job, 'G');
      final int wide = addressOf(job, 'WIDE');
      expect(subject.state.read(group), characters('  (((('));
      expect(subject.state.read(group + 1), characters('((0000'));
      expect(subject.state.read(addressOf(job, 'TGT')), characters('(((((('));
      expect(subject.state.read(wide), characters('(((((('));
      expect(subject.state.read(wide + 1), characters('      '));
      expect(subject.state.read(addressOf(job, 'ZED')), characters('000000'));
    });

    test('the converts leave their values in internal-decimal fields', () {
      // A literal into a group primes each numeric subfield: the group is
      // alphameric, so the move is the in-line mask insert.
      final (JobCompilation job, Machine subject) = compiled(<String>[
        '      *DATA',
        dataCard(name: 'G1', level: '1'),
        dataCard(name: 'EXT', level: '2', mode: 'E', description: '999'),
        dataCard(name: 'G2', level: '1'),
        dataCard(name: 'EDT', level: '2', description: '8,889'),
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
          description: '9999',
        ),
        '      *PROCEDURE',
        "      START.  MOVE '123' TO G1,",
        "            MOVE '1,234' TO G2,",
        '            MOVE EXT TO NUM,',
        '            ADD EDT TO TOT.',
        '            STOP RUN.',
        '      *FINISH',
      ]);
      expect(subject.state.read(addressOf(job, 'NUM')), 123);
      expect(subject.state.read(addressOf(job, 'TOT')), 1234);
    });
  });
}
