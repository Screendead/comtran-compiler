/// The tape reader (M5-2; M5-8): the record frame byte for byte, the
/// file mark, the end of the tape, and every frame that is no record.
library;

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

import 'runtime_support.dart';

/// A word whose six bytes are six different values, so the frame's byte
/// order reads off the octal (M5-2).
final int _word = octal('010203040506');

/// The frame of one [_word] record: the length, the data, the length.
const List<int> _frame = <int>[6, 0, 0, 0, 1, 2, 3, 4, 5, 6, 6, 0, 0, 0];

Matcher _unreadable(String fault) => throwsA(
  isA<UnreadableRecord>().having(
    (UnreadableRecord e) => e.toString(),
    'toString',
    'unreadable tape record: $fault',
  ),
);

void main() {
  group('the record frame (M5-2)', () {
    test('a word is six bytes, the most significant six bits first', () {
      expect(tapeWord(_word), <int>[1, 2, 3, 4, 5, 6]);
      expect(tapeRecord(<int>[_word]), _frame);
    });

    test('a record reads back the words its frame carries', () {
      expect(TapeReader(_frame).read(), <int>[_word]);
    });

    test('the high bits of a byte are another emulator parity bit', () {
      // The `I7000` simulator sets them, and the word takes the low six
      // bits of each byte (M5-2).
      final parity = <int>[6, 0, 0, 0, 0xC1, 2, 3, 4, 5, 6, 6, 0, 0, 0];
      expect(TapeReader(parity).read(), <int>[_word]);
    });

    test('two records read in order', () {
      final reader = TapeReader(<int>[
        ...tapeRecord(<int>[_word, 0]),
        ...tapeRecord(<int>[1]),
      ]);
      expect(reader.read(), <int>[_word, 0]);
      expect(reader.read(), <int>[1]);
    });
  });

  group('the file mark and the end of the tape (M5-2)', () {
    test('a length of zero is a file mark and carries no second length', () {
      expect(TapeReader(tapeField(0)).read(), isNull);
    });

    test('a read after a file mark takes the next record', () {
      final reader = TapeReader(<int>[...tapeField(0), ..._frame]);
      expect(reader.read(), isNull);
      expect(reader.read(), <int>[_word]);
    });

    test('an image that ends with no file mark has nothing to read', () {
      final reader = TapeReader(_frame);
      expect(reader.read(), <int>[_word]);
      expect(reader.read, _unreadable('the tape ends with no file mark'));
    });

    test('the end of tape value ends it as the last byte does', () {
      expect(
        TapeReader(tapeField(0xFFFFFFFF)).read,
        _unreadable('the tape ends with no file mark'),
      );
    });
  });

  group('a frame that is no record (M5-8)', () {
    test('the two lengths disagree', () {
      final wrong = <int>[..._frame.sublist(0, 10), 7, 0, 0, 0];
      expect(
        TapeReader(wrong).read,
        _unreadable('a record of 6 bytes ends saying 7'),
      );
    });

    test('the data is shorter than the length says', () {
      final short = <int>[12, 0, 0, 0, ..._frame.sublist(4)];
      expect(
        TapeReader(short).read,
        _unreadable('a record of 12 bytes runs off the tape'),
      );
    });

    test('the length is no whole number of words', () {
      final partial = <int>[4, 0, 0, 0, 1, 2, 3, 4, 4, 0, 0, 0];
      expect(
        TapeReader(partial).read,
        _unreadable('a record of 4 bytes is no whole word'),
      );
    });
  });
}
