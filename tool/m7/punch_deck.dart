// Prints an object deck one card a line, so that a 1963 punch tape and a
// deck of ours compare with diff (M7-9 in docs/design/m7-diff.md).
//
// Usage: dart run tool/m7/punch_deck.dart DECK [-o OUT.ctd]
//   DECK is an s709 punch tape (.bin) of the CT processor, or a canon deck,
//   such as the output of comtranc --emit-deck. A canon deck opens with
//   CTDECK; the first byte of an s709 image has bit 0200 set. With -o, the tool
//   also writes the cards of a punch tape as a canon deck.
//
// The CT processor builds each card in the 28-word buffer BWAR (CE068060)
// and writes it with IORT BWAR,,28 (CE067770). Each word holds three
// columns, twelve bits a column, row 12 in the high bit: the layout of the
// J 90.03 binary card. HBC (CE066580) converts characters to this form,
// three columns a word; it fills a symbolic card, and words 24 to 27 of a
// binary card with columns 73 to 84 (CE067700 to CE067720). Thus a record
// is columns 1 to 84. On the tapes of M7-8, columns 81 to 84 are blank on a
// symbolic card and hold a 0 punch on a binary card.
//
// Each line holds the card number from 1, then one of:
// - TEXT and columns 1 to 80, when every column holds a character;
// - BIN, the deck type, the word count, the sequence, the checksum test
//   (J 90.03.01), each word from word 3 to the last the count names in
//   octal, and the text of columns 73 to 80. On a text card (deck type 4)
//   each data word carries its control group, /gg in octal (J 90.03.03).
import 'dart:io';
import 'dart:typed_data';

import 'package:comtran/src/cards/canon_codec.dart';
import 'package:comtran/src/cards/card_image.dart';
import 'package:comtran/src/chars/char_code.dart';
import 'package:comtran/src/loader/object_deck.dart';

const _recordChars = 168;

// The cards of an s709 BIN image. Each byte holds one 6-bit character,
// and bit 0200 marks the first character of a record. A file mark is a
// record of one character; the tool prints it as a line of its own. So is
// any other record shorter than a card, as its characters.
List<Object?> _tapeCards(Uint8List bytes) {
  final List<int> starts = [
    for (var i = 0; i < bytes.length; i++)
      if (bytes[i] & 0x80 != 0) i,
    bytes.length,
  ];
  final cards = <Object?>[];
  for (var r = 0; r + 1 < starts.length; r++) {
    final int s = starts[r];
    final int length = starts[r + 1] - s;
    if (length == 1) {
      cards.add(null);
      continue;
    }
    if (length < _recordChars) {
      cards.add(
        [
          for (var i = s; i < s + length; i++) glyphFromBcd(bytes[i] & 0x3f)!,
        ].join(),
      );
      continue;
    }
    if (length != _recordChars) {
      stderr.writeln('record ${r + 1}: $length characters, not 168');
      exit(1);
    }
    int column(int c) =>
        ((bytes[s + 2 * c] & 0x3f) << 6) | (bytes[s + 2 * c + 1] & 0x3f);
    for (var c = 80; c < 84; c++) {
      if (column(c) != 0 && column(c) != 0x200) {
        stderr.writeln('record ${r + 1}: column ${c + 1} is punched');
        exit(1);
      }
    }
    cards.add(CardImage.fromColumns([for (var c = 0; c < 80; c++) column(c)]));
  }
  return cards;
}

String _glyph(int punches) =>
    isGlyphColumn(punches) ? glyphFromBcd(bcdFromPunches(punches)!)! : '?';

String _text(CardImage card, int from, int to) =>
    [for (var c = from; c <= to; c++) _glyph(card.punchesAt(c))].join();

String _octal(int word) => word.toRadixString(8).padLeft(12, '0');

String _line(int number, CardImage card) {
  final bool symbolic = [
    for (var c = 1; c <= CardImage.columnCount; c++) card.punchesAt(c),
  ].every(isGlyphColumn);
  if (symbolic) {
    return '$number TEXT ${_text(card, 1, 80).trimRight()}';
  }
  final List<int> words = cardWords(card);
  final int header = words[0];
  final int count = wordCountOf(header);
  final sum = logicalSum([header, ...words.sublist(2)]) == words[1];
  final int type = deckTypeOf(header);
  final List<int> body = words.sublist(2, 2 + count);
  final List<String> fields;
  if (type == textDeckType && count >= 3) {
    final List<int> groups = unpackControlGroups(body.sublist(0, 3));
    fields = [
      for (final int w in body.sublist(0, 3)) _octal(w),
      for (final (int i, int w) in body.sublist(3).indexed)
        '${_octal(w)}/${groups[i].toRadixString(8).padLeft(2, '0')}',
    ];
  } else {
    fields = [for (final int w in body) _octal(w)];
  }
  return '$number BIN type=$type count=$count '
      'seq=${sequenceOf(header)} sum=${sum ? 'ok' : 'BAD'} '
      '${fields.join(' ')} [${_text(card, 73, 80).trimRight()}]';
}

void main(List<String> args) {
  final int o = args.indexOf('-o');
  if (args.isEmpty || (o >= 0 && (o != 1 || args.length != 3))) {
    stderr.writeln('usage: punch_deck.dart DECK [-o OUT.ctd]');
    exit(64);
  }
  final Uint8List bytes = File(args[0]).readAsBytesSync();
  final canon = String.fromCharCodes(bytes.take(6)) == 'CTDECK';
  final List<Object?> cards = canon ? decodeCanon(bytes) : _tapeCards(bytes);
  var number = 0;
  for (final card in cards) {
    stdout.writeln(switch (card) {
      null => '-- file mark',
      final String text =>
        '-- record of ${text.length} characters: ${text.trimRight()}',
      _ => _line(++number, card as CardImage),
    });
  }
  if (o >= 0) {
    File(
      args[2],
    ).writeAsBytesSync(encodeCanon(cards.whereType<CardImage>().toList()));
  }
}
