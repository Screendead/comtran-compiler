/// The tape reader (M5-2; M5-8): one input file's host image as the
/// records and file marks IOC)8 reads from it.
///
/// A record frame is a 4-byte little-endian length, that many data
/// bytes, then the same length again. A length of zero is a file mark
/// and carries no second length. The value `0xFFFFFFFF`, or the end of
/// the image, ends the tape.
library;

/// Six bytes to a 36-bit word (M5-2).
const int bytesPerWord = 6;

/// A frame the reader cannot decode, which the GET turns into the IOCS
/// error exit SYS)283 (M5-8).
final class UnreadableRecord implements Exception {
  UnreadableRecord(this.fault);

  /// What about the frame has no record.
  final String fault;

  @override
  String toString() => 'unreadable tape record: $fault';
}

/// One input file's image, read from the front. The whole image sits in
/// memory: a run opens each file once and reads it through.
final class TapeReader {
  TapeReader(this._bytes);

  final List<int> _bytes;

  /// The first byte of the frame the next [read] takes.
  int _at = 0;

  /// The words of the next record, or `null` at a file mark.
  ///
  /// Throws [UnreadableRecord] for a frame that is no record and for a
  /// read past the end of the tape (M5-8).
  List<int>? read() {
    if (_at + 4 > _bytes.length) {
      throw UnreadableRecord('the tape ends with no file mark');
    }
    final int length = _field(_at);
    _at += 4;
    if (length == 0) {
      return null;
    }
    if (length == 0xFFFFFFFF) {
      throw UnreadableRecord('the tape ends with no file mark');
    }
    if (length % bytesPerWord != 0) {
      throw UnreadableRecord('a record of $length bytes is no whole word');
    }
    if (_at + length + 4 > _bytes.length) {
      throw UnreadableRecord('a record of $length bytes runs off the tape');
    }
    final words = <int>[
      for (var i = 0; i < length; i += bytesPerWord) _word(_at + i),
    ];
    _at += length;
    final int trailing = _field(_at);
    if (trailing != length) {
      throw UnreadableRecord('a record of $length bytes ends saying $trailing');
    }
    _at += 4;
    return words;
  }

  /// The four-byte little-endian value at [at].
  int _field(int at) =>
      _bytes[at] |
      (_bytes[at + 1] << 8) |
      (_bytes[at + 2] << 16) |
      (_bytes[at + 3] << 24);

  /// The word of the six bytes at [at], most significant six bits
  /// first. Another emulator's parity rides in the high two bits of a
  /// byte, and the word takes the low six (M5-2).
  int _word(int at) {
    var word = 0;
    for (var i = 0; i < bytesPerWord; i++) {
      word = (word << 6) | (_bytes[at + i] & 0x3F);
    }
    return word;
  }
}
