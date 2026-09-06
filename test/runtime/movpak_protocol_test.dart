/// The MOVPAK step-list protocol (RT-3): one case per word shape, each
/// through the dispatcher, asserting the resume address, index register
/// 1, the two registers a call must preserve, and whether the move is
/// still open.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';
import 'movpak_support.dart';

void main() {
  group('the word shapes of RT-3', () {
    /// Runs [words] behind `TSX SYS)182,4` and asserts the register
    /// contract at the resume. `TXI SYS)243,1,0` follows them: it writes
    /// nothing, and it throws when the move is already closed.
    void shape(
      String name,
      List<int> words,
      int stepWords, {
      required bool ends,
    }) {
      final int resume = start + 1 + words.length;
      final Machine subject = machine(<int, int>{
        start: tsx(182),
        for (var i = 0; i < words.length; i++) start + 1 + i: words[i],
        resume: txi(243, 0),
      })..run(maxSteps: 2 + 2 * stepWords);
      final MachineState state = subject.state;
      expect(state.ic, resume, reason: '$name resume');
      expect(state.xrRead(1), 0, reason: '$name index register 1');
      expect(state.xrRead(2), junkLocator, reason: '$name index register 2');
      expect(state.xrRead(4), link(start), reason: '$name link');
      if (ends) {
        expect(
          () => subject.run(maxSteps: 2),
          throwsA(isA<StateError>()),
          reason: '$name closes the move',
        );
      } else {
        subject.run(maxSteps: 2);
        expect(subject.state.ic, resume + 1, reason: '$name keeps the move');
      }
    }

    test('a one-word convert or mover resumes past itself', () {
      for (final entry in <int>[184, 239, 243, 244]) {
        shape('SYS)$entry', <int>[txi(entry, 0)], 1, ends: true);
      }
    });

    test('a bare step resumes past itself and keeps the move', () {
      for (final entry in <int>[240, 268, 269]) {
        shape('SYS)$entry', <int>[txi(entry, 1)], 1, ends: false);
      }
    });

    test('a terminator resumes past itself and ends the move', () {
      shape('SYS)275', <int>[txi(275, 0)], 1, ends: true);
    });

    test('the mover pair ends on its second word', () {
      shape('SYS)241', <int>[txi(240, 0), txi(241, 0)], 2, ends: true);
    });

    test('a fill with characters resumes past its OCT word', () {
      shape('SYS)245', <int>[txi(245, 0), characters('((((((')], 1, ends: true);
    });

    test('an entry leaves the instruction counter on the family head', () {
      // SYS)180 reads one in-line address word, SYS)182 none, and
      // neither executes the head it lands on ([J 90.02.14]).
      final Machine withTarget = machine(<int, int>{
        start: tsx(180),
        start + 1: pze(start + 0x100, 0),
      })..run(maxSteps: 2);
      final MachineState state = withTarget.state;
      expect(state.ic, start + 2);
      expect(state.xrRead(1), 0);
      expect(state.xrRead(2), junkLocator);
      expect(state.xrRead(4), link(start));
    });
  });

  group('a broken instruction stream throws', () {
    test('a step outside a move', () {
      expect(
        () => machine(<int, int>{start: txi(239, 0)}).run(maxSteps: 4),
        throwsA(isA<StateError>()),
      );
    });

    test('a step the cursor word does not name', () {
      // `TRA` past the entry's cursor: the handler then runs with the
      // cursor still on the transfer.
      expect(
        () => machine(<int, int>{
          start: tsx(182),
          start + 1: typeB(0x010, address: start + 2),
          start + 2: txi(239, 0),
        }).run(maxSteps: 5),
        throwsA(isA<StateError>()),
      );
    });

    test('an entry inside a move', () {
      expect(
        () => machine(<int, int>{
          start: tsx(182),
          start + 1: tsx(182),
        }).run(maxSteps: 4),
        throwsA(isA<StateError>()),
      );
    });

    test('SYS)241 without SYS)240', () {
      expect(
        () => machine(<int, int>{
          start: tsx(182),
          start + 1: txi(241, 1),
        }).run(maxSteps: 4),
        throwsA(isA<StateError>()),
      );
    });
  });
}
