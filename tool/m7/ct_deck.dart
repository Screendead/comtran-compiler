// Prints each card of an object deck: a 1963 CT punch tape (SYSPP1), or a
// canon deck of ours. A Hollerith card prints its text, columns 1 to 80. A
// binary card prints the fields of word 1 (J 90.03.01) and whether the
// checksum of word 2 verifies. A text card then prints one line for each
// data word: the location, the control group and the word in octal.
//
// Usage: dart run tool/m7/ct_deck.dart DECK...
//   A file that starts with CTDECK is a canon deck. Any other file is an
//   s709 BIN tape image.
import 'dart:io';
import 'dart:typed_data';

import 'package:comtran/comtran.dart';

// A punch record holds 28 column-binary words, 168 characters, three
// columns to a word and two characters to a column (M7-8). Characters 0 to
// 159 hold columns 1 to 80; the last eight are filler for the off-line
// punch. Bit 0200 marks the first character of a record, and bit 0100 is
// parity.
const _recordChars = 168;

List<CardImage> _tapeCards(Uint8List bytes) {
  final starts = <int>[
    for (var i = 0; i < bytes.length; i++)
      if (bytes[i] & 0x80 != 0) i,
  ];
  return [
    for (var k = 0; k < starts.length; k++)
      if ((k + 1 < starts.length ? starts[k + 1] : bytes.length) - starts[k] ==
          _recordChars)
        CardImage.fromColumns([
          for (var c = starts[k]; c < starts[k] + 160; c += 2)
            (bytes[c] & 0x3f) << 6 | bytes[c + 1] & 0x3f,
        ]),
  ];
}

// A column with no Set H glyph prints `?`.
String _text(CardImage card) => [
  for (var c = 1; c <= 80; c++)
    switch (bcdFromPunches(card.punchesAt(c))) {
      final int bcd => glyphFromBcd(bcd) ?? '?',
      null => '?',
    },
].join();

String _octal(int value, int digits) =>
    value.toRadixString(8).padLeft(digits, '0');

void _printDeck(List<CardImage> cards) {
  var location = 0;
  for (final (int n, CardImage card) in cards.indexed) {
    final String number = '${n + 1}'.padLeft(4);
    // A binary card has the 7-9 punch in column 1.
    if (card.punchesAt(1) & 5 != 5) {
      stdout.writeln('$number H ${_text(card).trimRight()}');
      continue;
    }
    final List<int> words = cardWords(card);
    final int count = wordCountOf(words[0]);
    final List<int> data = words.sublist(2, 2 + count);
    final sumOk = logicalSum([words[0], ...data]) == words[1];
    final String serial = _text(card).substring(72);
    stdout.writeln(
      '$number B type ${deckTypeOf(words[0])} seq ${sequenceOf(words[0])} '
      'count $count sum ${_octal(words[1], 12)} '
      '${sumOk ? 'ok' : 'BAD'}'
      '${skipsChecksum(words[0]) ? ' (not checked)' : ''}'
      '  73-80 "$serial"',
    );
    if (deckTypeOf(words[0]) != textDeckType) {
      for (var i = 0; i < data.length; i += 6) {
        final Iterable<int> line = data.skip(i).take(6);
        stdout.writeln('       ${line.map((w) => _octal(w, 12)).join(' ')}');
      }
      continue;
    }
    // A text card: words 3 to 5 hold the control groups (J 90.03.03).
    final List<int> groups = unpackControlGroups(data.sublist(0, 3));
    for (var i = 0; i < count - 3; i++) {
      final int word = data[3 + i];
      final int group = groups[i];
      final placed = group & 0x10 != 0;
      stdout.writeln(
        '       ${placed ? _octal(location, 5) : '     '}  '
        '${controlColumn(group)}  ${_octal(word, 12)}',
      );
      if (placed) {
        location++;
      } else if (group == ControlGroup.locationCounter) {
        // PZE and MON set an origin; PTW and PTH reserve (J 90.03.04).
        final int op = Word36.prefix(word);
        location = op == 0 || op == 5
            ? Word36.address(word)
            : location + Word36.address(word);
      }
    }
  }
}

void main(List<String> args) {
  for (final path in args) {
    final Uint8List bytes = File(path).readAsBytesSync();
    final canon = String.fromCharCodes(bytes.take(6)) == 'CTDECK';
    final List<CardImage> cards = canon
        ? decodeCanon(bytes)
        : _tapeCards(bytes);
    stdout.writeln('* $path  ${cards.length} cards');
    _printDeck(cards);
  }
}
