import '../chars/char_code.dart';
import 'card_image.dart';

/// The text-mirror format (`.deck`).
///
/// Implements §3 of `docs/design/deck-format.md` (decision D0.5): one line
/// per card — a Set H glyph line when every column carries a source-set
/// character, a `!`-prefixed punch line otherwise. [mirrorToDeck] accepts
/// normal-form text only, so mirror → canon → mirror is the identity.

/// Renders [deck] as mirror text.
String deckToMirror(List<CardImage> deck) {
  final buffer = StringBuffer();
  for (final card in deck) {
    buffer
      ..write(_cardToLine(card))
      ..write('\n');
  }
  return buffer.toString();
}

/// Parses normal-form mirror text into a deck.
///
/// Throws a [FormatException] naming the offending card for any deviation
/// from normal form (spec §3.3).
List<CardImage> mirrorToDeck(String text) {
  if (text.isEmpty) {
    return [];
  }
  if (text.contains('\r')) {
    throw const FormatException('mirror text contains a CR character');
  }
  if (!text.endsWith('\n')) {
    throw const FormatException('mirror text does not end with a newline');
  }
  final List<String> lines = text.substring(0, text.length - 1).split('\n');
  final deck = <CardImage>[];
  for (var i = 0; i < lines.length; i++) {
    final String line = lines[i];
    final int cardNumber = i + 1;
    final CardImage card = line.startsWith('!')
        ? _parsePunchLine(line, cardNumber)
        : _parseGlyphLine(line, cardNumber);
    final String rendered = _cardToLine(card);
    if (rendered != line) {
      throw FormatException(
        'card $cardNumber is not in normal form '
        '(re-rendering gives "$rendered")',
      );
    }
    deck.add(card);
  }
  return deck;
}

String _cardToLine(CardImage card) {
  var isGlyphCard = true;
  for (var column = 1; column <= CardImage.columnCount; column++) {
    if (!isGlyphColumn(card.punchesAt(column))) {
      isGlyphCard = false;
      break;
    }
  }
  if (isGlyphCard) {
    final buffer = StringBuffer();
    for (var column = 1; column <= CardImage.columnCount; column++) {
      buffer.write(glyphFromBcd(bcdFromPunches(card.punchesAt(column))!));
    }
    var line = buffer.toString();
    while (line.endsWith(' ')) {
      line = line.substring(0, line.length - 1);
    }
    return line;
  }
  final buffer = StringBuffer('!');
  for (var column = 1; column <= CardImage.columnCount; column++) {
    final int punches = card.punchesAt(column);
    if (punches != 0) {
      buffer.write(' $column:${cardCodeFromPunches(punches)}');
    }
  }
  return buffer.toString();
}

CardImage _parseGlyphLine(String line, int cardNumber) {
  if (line.length > CardImage.columnCount) {
    throw FormatException(
      'card $cardNumber: glyph line longer than ${CardImage.columnCount} '
      'columns',
    );
  }
  final columns = List<int>.filled(CardImage.columnCount, 0);
  for (var i = 0; i < line.length; i++) {
    final String glyph = line[i];
    final int? bcd = bcdFromGlyph(glyph);
    if (bcd == null) {
      throw FormatException(
        'card $cardNumber, column ${i + 1}: "$glyph" is not a source-set '
        'glyph',
      );
    }
    columns[i] = punchesFromBcd(bcd)!;
  }
  return CardImage.fromColumns(columns);
}

CardImage _parsePunchLine(String line, int cardNumber) {
  final columns = List<int>.filled(CardImage.columnCount, 0);
  final List<String> fields = line.split(' ');
  if (fields[0] != '!' || fields.length < 2) {
    throw FormatException('card $cardNumber: malformed punch line');
  }
  var lastColumn = 0;
  for (final String field in fields.skip(1)) {
    final int colon = field.indexOf(':');
    if (colon <= 0) {
      throw FormatException('card $cardNumber: malformed punch field "$field"');
    }
    final int? column = int.tryParse(field.substring(0, colon), radix: 10);
    final int? punches = punchesFromCardCode(field.substring(colon + 1));
    if (column == null ||
        column < 1 ||
        column > CardImage.columnCount ||
        punches == null) {
      throw FormatException('card $cardNumber: malformed punch field "$field"');
    }
    if (column <= lastColumn) {
      throw FormatException(
        'card $cardNumber: punch fields out of ascending column order',
      );
    }
    lastColumn = column;
    columns[column - 1] = punches;
  }
  return CardImage.fromColumns(columns);
}
