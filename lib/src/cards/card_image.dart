import 'dart:typed_data';

/// One punched card at punch level: 80 columns × 12 punch rows.
///
/// Implements §1 of `docs/design/deck-format.md` (decision D0.5). Each column
/// is a 12-bit value; bit 11 is row 12 (top), bit 10 row 11, bit 9 row 0,
/// bits 8–0 rows 1–9. Instances are immutable.
final class CardImage {
  /// A card with no punches.
  CardImage.blank() : _columns = Uint16List(columnCount);

  /// A card from 80 column values, copied.
  CardImage.fromColumns(Iterable<int> columns)
    : _columns = Uint16List(columnCount) {
    var i = 0;
    for (final c in columns) {
      // Validate before storing: Uint16List would silently truncate.
      if (c < 0 || c > 0xFFF) {
        throw ArgumentError.value(c, 'columns', 'a column holds 12 bits');
      }
      if (i >= columnCount) {
        throw ArgumentError.value(
          columns,
          'columns',
          'a card has exactly $columnCount columns',
        );
      }
      _columns[i++] = c;
    }
    if (i != columnCount) {
      throw ArgumentError.value(
        i,
        'columns',
        'a card has exactly $columnCount columns',
      );
    }
  }

  /// Columns per card.
  static const int columnCount = 80;

  final Uint16List _columns;

  /// The punch pattern of [column] (1-based, 1–80).
  int punchesAt(int column) {
    if (column < 1 || column > columnCount) {
      throw RangeError.range(column, 1, columnCount, 'column');
    }
    return _columns[column - 1];
  }

  /// Whether no column is punched.
  bool get isBlank => _columns.every((int c) => c == 0);

  /// The column values as a fresh list (index 0 = column 1).
  Uint16List toColumnList() => Uint16List.fromList(_columns);

  @override
  bool operator ==(Object other) {
    if (other is! CardImage) {
      return false;
    }
    for (var i = 0; i < columnCount; i++) {
      if (_columns[i] != other._columns[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_columns);
}
