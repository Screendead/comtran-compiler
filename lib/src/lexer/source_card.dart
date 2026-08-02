/// The column-model view of one source card.
///
/// Implements the card fields of definition §1.9: the serial field in
/// columns 1–6, the body in columns 7–72 — "body of source program cards
/// (columns 7-72)" (J 02.02.01) — and the identification field in columns
/// 73–80. Columns 1–6 and 73–80 are never part of the language text.
library;

import '../cards/card_image.dart';
import '../chars/char_code.dart';

/// One source card, decoded from punch level to Set H characters.
///
/// Decoding applies the read rules of `docs/design/deck-format.md` §4.1 to
/// every column. A column whose punch pattern reads to a machine special or
/// has no readout at all decodes to `null`; text accessors render such a
/// column as a blank, and callers diagnose them via [unreadableColumns].
final class SourceCard {
  /// Decodes [image], the card at 1-based deck position [cardNumber].
  SourceCard(this.image, this.cardNumber)
    : _glyphs = List<String?>.generate(CardImage.columnCount, (int i) {
        final int? bcd = bcdFromPunches(image.punchesAt(i + 1));
        return bcd == null ? null : glyphFromBcd(bcd);
      }, growable: false);

  /// The punch-level card.
  final CardImage image;

  /// The card's 1-based position in the source deck.
  final int cardNumber;

  final List<String?> _glyphs;

  /// The Set H character of [column] (1-based), or `null` when the column
  /// does not read to a Set H character.
  String? glyphAt(int column) => _glyphs[_checkColumn(column) - 1];

  /// The columns in [from]..[to] (inclusive) that do not read to a Set H
  /// character — machine specials and punch patterns with no readout.
  List<int> unreadableColumns(int from, int to) => [
    for (var c = _checkColumn(from); c <= _checkColumn(to); c++)
      if (_glyphs[c - 1] == null) c,
  ];

  /// The text of columns [from]..[to] (inclusive). A column that does not
  /// read to a Set H character is rendered as a blank; use
  /// [unreadableColumns] to detect and diagnose such columns first.
  String textRange(int from, int to) {
    final buffer = StringBuffer();
    for (var c = _checkColumn(from); c <= _checkColumn(to); c++) {
      buffer.write(_glyphs[c - 1] ?? ' ');
    }
    return buffer.toString();
  }

  /// The serial field, columns 1–6 (Ctl. 1–3 + Serial 4–6; F p. 37).
  String get serial => textRange(1, 6);

  /// The card body, columns 7–72 — the language text (J 02.02.01).
  String get body => textRange(7, 72);

  /// The identification field, columns 73–80 (inert; F p. 37, F p. 84).
  String get identification => textRange(73, 80);

  /// Whether no column is punched.
  bool get isBlank => image.isBlank;

  int _checkColumn(int column) {
    if (column < 1 || column > CardImage.columnCount) {
      throw RangeError.range(column, 1, CardImage.columnCount, 'column');
    }
    return column;
  }
}
