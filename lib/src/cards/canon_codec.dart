import 'dart:typed_data';

import 'card_image.dart';

/// The canon container format (`.ctdeck`).
///
/// Implements §2 of `docs/design/deck-format.md` (decision D0.5): a 12-byte
/// header (magic `CTDECK`, version, flags, big-endian card count) followed by
/// one 120-byte record per card, columns packed two-per-three-bytes.

/// The current canon format version.
const int canonFormatVersion = 1;

const List<int> _magic = [0x43, 0x54, 0x44, 0x45, 0x43, 0x4B]; // 'CTDECK'
const int _headerLength = 12;
const int _recordLength = 120;

/// Encodes [deck] as canon bytes.
Uint8List encodeCanon(List<CardImage> deck) {
  final bytes = Uint8List(_headerLength + _recordLength * deck.length);
  bytes.setRange(0, _magic.length, _magic);
  bytes[6] = canonFormatVersion;
  bytes[7] = 0; // Flags, reserved.
  ByteData.sublistView(bytes).setUint32(8, deck.length);
  var offset = _headerLength;
  for (final CardImage card in deck) {
    final Uint16List columns = card.toColumnList();
    for (var i = 0; i < CardImage.columnCount; i += 2) {
      final int a = columns[i];
      final int b = columns[i + 1];
      bytes[offset] = a >> 4;
      bytes[offset + 1] = ((a & 0xF) << 4) | (b >> 8);
      bytes[offset + 2] = b & 0xFF;
      offset += 3;
    }
  }
  return bytes;
}

/// Decodes canon bytes into a deck.
///
/// Throws a [FormatException] on a bad magic, an unknown version, nonzero
/// flags, or a length that is not exactly a header plus whole card records
/// matching the header's count (spec §2.1).
List<CardImage> decodeCanon(Uint8List bytes) {
  if (bytes.length < _headerLength) {
    throw const FormatException('canon file shorter than the 12-byte header');
  }
  for (var i = 0; i < _magic.length; i++) {
    if (bytes[i] != _magic[i]) {
      throw const FormatException('bad magic: not a CTDECK file');
    }
  }
  if (bytes[6] != canonFormatVersion) {
    throw FormatException('unknown canon format version ${bytes[6]}');
  }
  if (bytes[7] != 0) {
    throw FormatException('reserved flags byte is nonzero (${bytes[7]})');
  }
  final int count = ByteData.sublistView(bytes).getUint32(8);
  final int expected = _headerLength + _recordLength * count;
  if (bytes.length != expected) {
    throw FormatException(
      'file length ${bytes.length} does not match $count cards '
      '(expected $expected bytes)',
    );
  }
  final deck = <CardImage>[];
  var offset = _headerLength;
  final columns = Uint16List(CardImage.columnCount);
  for (var card = 0; card < count; card++) {
    for (var i = 0; i < CardImage.columnCount; i += 2) {
      final int b0 = bytes[offset];
      final int b1 = bytes[offset + 1];
      final int b2 = bytes[offset + 2];
      columns[i] = (b0 << 4) | (b1 >> 4);
      columns[i + 1] = ((b1 & 0xF) << 8) | b2;
      offset += 3;
    }
    deck.add(CardImage.fromColumns(columns));
  }
  return deck;
}
