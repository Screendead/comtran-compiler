/// The column-model view of one source card.
///
/// Implements the card fields of definition §1.9: the serial field in
/// columns 1–6, the body in columns 7–72 — "body of source program cards
/// (columns 7-72)" (J 02.02.01) — and the identification field in columns
/// 73–80. Columns 1–6 and 73–80 are never part of the language text and
/// are never character-gated (decision D9.10).
library;

import '../cards/card_image.dart';
import '../chars/char_code.dart';

/// One source card, decoded from punch level per the read rules of
/// `docs/design/deck-format.md` §4.1.
///
/// Per decision D9.10 the scanners keep two parallel texts: the internal
/// text replaces an illegal character with the digit zero, the external
/// (listing) text replaces it with the dollar sign. This class supplies
/// the per-column readings; the scanners decide legality in context (a
/// machine special is legal inside an alphameric literal, illegal
/// elsewhere — D9.10 layer c).
final class SourceCard {
  /// Decodes [image], the card at 1-based deck position [cardNumber].
  SourceCard(this.image, this.cardNumber)
    : _bcds = List<int?>.generate(
        CardImage.columnCount,
        (int i) => bcdFromPunches(image.punchesAt(i + 1)),
        growable: false,
      );

  /// The punch-level card.
  final CardImage image;

  /// The card's 1-based position in the source deck.
  final int cardNumber;

  final List<int?> _bcds;

  /// The BCD read-out of [column] (1-based), or `null` when the punch
  /// pattern has no readout.
  int? bcdAt(int column) => _bcds[_checkColumn(column) - 1];

  /// The Set H character of [column], or `null` when the column does not
  /// read to a Set H character.
  String? glyphAt(int column) {
    final int? bcd = bcdAt(column);
    return bcd == null ? null : glyphFromBcd(bcd);
  }

  /// Whether [column] has any punch.
  bool isPunched(int column) => image.punchesAt(_checkColumn(column)) != 0;

  /// The columns in [from]..[to] (inclusive) that are punched but do not
  /// read to a Set H character — machine specials, non-source machine
  /// characters, and punch patterns with no readout.
  List<int> unreadableColumns(int from, int to) => [
    for (var c = _checkColumn(from); c <= _checkColumn(to); c++)
      if (isPunched(c) && glyphAt(c) == null) c,
  ];

  /// The text of columns [from]..[to] (inclusive) with unreadable columns
  /// rendered as blanks. For the ungated serial and identification fields
  /// (D9.10: never part of the language text).
  String textRange(int from, int to) => _render(from, to, (int column) => ' ');

  /// The internal scan text of columns [from]..[to]: an unreadable punched
  /// column reads as the digit zero (decision D9.10 — "replace it with the
  /// digit zero in the internal text").
  String internalText(int from, int to) =>
      _render(from, to, (int column) => '0');

  String _render(int from, int to, String Function(int) unreadable) {
    final buffer = StringBuffer();
    for (int c = _checkColumn(from); c <= _checkColumn(to); c++) {
      buffer.write(glyphAt(c) ?? (isPunched(c) ? unreadable(c) : ' '));
    }
    return buffer.toString();
  }

  /// The serial field, columns 1–6 (Ctl. 1–3 + Serial 4–6; F p. 37).
  String get serial => textRange(1, 6);

  /// The card body, columns 7–72 — the language text (J 02.02.01) — as
  /// read for display, unreadable columns blank.
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
