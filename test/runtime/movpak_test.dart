/// The non-edited MOVPAK members (RT-4): the pointer cells, the
/// external-decimal convert, the edited-field convert, and the four
/// character movers, each against its [J 90.02] contract.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'movpak_support.dart';

/// The two pointer cells at the addresses the resolver gives them
/// ([J 90.02.11]).
const int _sourceCell = 132;
const int _targetCell = 133;

/// The improper-data condition cell (D4.3).
const int _conditionCell = 131;

const int _source = start + 0x100;
const int _target = start + 0x110;

/// Runs [words] behind `TSX SYS)182,4` with both pointer cells preset,
/// over the source and target images, and ends at `TXI IOC)40,0`.
Machine dispatch({
  required List<int> words,
  int sourceByte = 0,
  int targetByte = 0,
  List<int> sourceImage = const <int>[],
  List<int> targetImage = const <int>[],
}) {
  final Machine subject = machine(<int, int>{
    _sourceCell: pze(_source, sourceByte),
    _targetCell: pze(_target, targetByte),
    start: tsx(182),
    for (var i = 0; i < words.length; i++) start + 1 + i: words[i],
    start + 1 + words.length: endOfJob,
    for (var i = 0; i < sourceImage.length; i++) _source + i: sourceImage[i],
    for (var i = 0; i < targetImage.length; i++) _target + i: targetImage[i],
  });
  expect(subject.run(maxSteps: 30).outcome, RunOutcome.endOfJob);
  return subject;
}

void main() {
  group('the pointer cells (J 90.02.11)', () {
    test('SYS)180 stores its in-line address word in the target cell', () {
      // The decrement is the byte and byte 0 is the word's high-order
      // character, so one blank lands where the address word points.
      for (final byte in <int>[0, 3]) {
        final Machine subject = machine(<int, int>{
          start: tsx(180),
          start + 1: pze(_target, byte),
          start + 2: txi(243, 1),
          start + 3: endOfJob,
          _target: characters('000000'),
        });
        expect(subject.run(maxSteps: 20).outcome, RunOutcome.endOfJob);
        expect(subject.state.read(_targetCell), pze(_target, byte));
        expect(
          subject.state.read(_target),
          characters(byte == 0 ? ' 00000' : '000 00'),
          reason: 'byte $byte',
        );
      }
    });
  });

  group('SYS)184, external decimal to internal decimal (J 90.02.16)', () {
    Machine convert(int image, int count) =>
        dispatch(words: <int>[txi(184, count)], sourceImage: <int>[image]);

    test('digits convert to a positive binary value', () {
      final Machine subject = convert(characters('123   '), 3);
      expect(subject.state.acMagnitude, 123);
      expect(subject.state.acSign, 0);
      expect(subject.state.read(_conditionCell), 0);
    });

    test('leading blanks are leading zeros', () {
      // "Numeric external fields may contain leading blanks which are
      // treated as leading zeros" (J 02.05.05 note 3).
      final Machine subject = convert(characters('  3   '), 3);
      expect(subject.state.acMagnitude, 3);
      expect(subject.state.read(_conditionCell), 0);
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
      expect(subject.state.read(_conditionCell), isNot(0));
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

    test('an insertion character is stepped over and not counted', () {
      final Machine subject = dispatch(
        words: <int>[txi(268, 1), txi(269, 4), txi(275, 4)],
        sourceImage: <int>[characters('1,234 ')],
      );
      expect(subject.state.acMagnitude, 1234);
      expect(subject.state.read(_conditionCell), 0);
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
      expect(subject.state.read(_target), characters('ABCDEF'));
      expect(subject.state.read(_target + 1), characters('GHZZZZ'));
    });

    test('SYS)240 and SYS)241 fill the excess with trailing blanks', () {
      // "The low-order positions of the receiving area, i.e., the
      // excess positions, will be filled with blanks" (J 02.04.03).
      final Machine subject = dispatch(
        words: <int>[txi(240, 4), txi(241, 4)],
        sourceByte: 2,
        targetByte: 4,
        sourceImage: <int>[characters('QQABCD')],
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(subject.state.read(_target), characters('ZZZZAB'));
      expect(subject.state.read(_target + 1), characters('CD    '));
    });

    test('SYS)243 writes blanks', () {
      final Machine subject = dispatch(
        words: <int>[txi(243, 8)],
        targetByte: 2,
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(subject.state.read(_target), characters('ZZ    '));
      expect(subject.state.read(_target + 1), characters('    ZZ'));
    });

    test('SYS)244 writes the character zero, not a zero word', () {
      final Machine subject = dispatch(
        words: <int>[txi(244, 8)],
        targetByte: 2,
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(subject.state.read(_target), characters('ZZ0000'));
      expect(subject.state.read(_target + 1), characters('0000ZZ'));
    });

    test('SYS)245 fills from its OCT word and cycles past six', () {
      final Machine exact = dispatch(
        words: <int>[txi(245, 6), characters('((((((')],
        targetImage: <int>[characters('ZZZZZZ')],
      );
      expect(exact.state.read(_target), characters('(((((('));
      final Machine cycled = dispatch(
        words: <int>[txi(245, 8), characters('ABCDEF')],
        targetByte: 2,
        targetImage: <int>[characters('ZZZZZZ'), characters('ZZZZZZ')],
      );
      expect(cycled.state.read(_target), characters('ZZABCD'));
      expect(cycled.state.read(_target + 1), characters('EFABZZ'));
    });
  });
}
