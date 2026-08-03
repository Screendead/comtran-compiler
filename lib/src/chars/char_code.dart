/// The 6-bit BCD character code and its card codes.
///
/// Implements §4 of `docs/design/deck-format.md` (decision D0.6): the read
/// rules from punch pattern to core-storage BCD code, the canonical punch
/// pattern for each code, and the Set H display glyphs. All values are
/// core-storage codes (external: 22-6528-4 p. 80), cross-checked against the
/// native collating sequence of J 02.06.16.
library;

/// Punch-row bit for row 12 (top zone row) in a 12-bit column value.
const int rowBit12 = 1 << 11;

/// Punch-row bit for row 11.
const int rowBit11 = 1 << 10;

/// Punch-row bit for row 0.
const int rowBit0 = 1 << 9;

/// The BCD code of a blank column (octal 60).
const int bcdBlank = 0x30;

/// The BCD code of the group mark (octal 37, card code 12-5-8).
const int bcdGroupMark = 0x1F;

/// Punch-row bit for digit row [digit] (1–9).
int rowBitDigit(int digit) {
  if (digit < 1 || digit > 9) {
    throw RangeError.range(digit, 1, 9, 'digit');
  }
  return 1 << (9 - digit);
}

// 12-5-8: row 12 (bit 11), row 5 (bit 4), row 8 (bit 1).
const int _gmPunches = 0x800 | 0x010 | 0x002;

/// Reads a column's punch pattern as a BCD code, or `null` when the pattern
/// has no readout (spec §4.1).
int? bcdFromPunches(int punches) {
  if (punches < 0 || punches > 0xFFF) {
    throw RangeError.range(punches, 0, 0xFFF, 'punches');
  }
  if (punches == 0) {
    return bcdBlank;
  }
  if (punches == _gmPunches) {
    return bcdGroupMark; // The 705 group-mark translation, spec §4.1.
  }
  final has12 = punches & rowBit12 != 0;
  final has11 = punches & rowBit11 != 0;
  if (has12 && has11) {
    return null;
  }
  int digitRows = punches & ~(rowBit12 | rowBit11);
  final int zone;
  if (has12) {
    zone = 1;
  } else if (has11) {
    zone = 2;
  } else if (digitRows == rowBit0) {
    return 0x00; // A bare 0 punch is the digit zero.
  } else if (digitRows & rowBit0 != 0) {
    zone = 3; // Row 0 as a zone punch, with a digit part below it.
    digitRows &= ~rowBit0;
  } else {
    zone = 0;
  }
  final int? digit = _digitValue(digitRows);
  if (digit == null) {
    return null;
  }
  if (zone == 1 && digit == 15) {
    return null; // 12-7-8 has no readout; the group mark is 12-5-8 only.
  }
  return (zone << 4) | digit;
}

/// The digit-part value of [digitRows] (rows 0–9 only), or `null` when the
/// combination is not a legal digit part.
int? _digitValue(int digitRows) {
  if (digitRows == 0) {
    return 0;
  }
  if (digitRows == rowBit0) {
    return 10; // Row 0 as a digit under zone 12 or 11.
  }
  for (var d = 1; d <= 9; d++) {
    if (digitRows == rowBitDigit(d)) {
      return d;
    }
  }
  final int rest = digitRows & ~rowBitDigit(8);
  if (rest != digitRows) {
    for (var d = 2; d <= 7; d++) {
      if (rest == rowBitDigit(d)) {
        return 8 + d;
      }
    }
  }
  return null;
}

/// The canonical punch pattern of BCD code [bcd], or `null` for octal 35,
/// the one code with no card code (spec §4.3).
int? punchesFromBcd(int bcd) {
  _checkBcd(bcd);
  if (bcd == 0x00) {
    return rowBit0; // Digit zero.
  }
  if (bcd == bcdBlank) {
    return 0;
  }
  if (bcd == bcdGroupMark) {
    return _gmPunches;
  }
  final int zone = bcd >> 4;
  final int digit = bcd & 0xF;
  final int zonePunch = switch (zone) {
    0 => 0,
    1 => rowBit12,
    2 => rowBit11,
    _ => rowBit0,
  };
  if (zone == 1 && digit == 13) {
    return null; // Octal 35, displaced by the group-mark translation.
  }
  final int digitPunch;
  if (digit == 0) {
    digitPunch = 0;
  } else if (digit <= 9) {
    digitPunch = rowBitDigit(digit);
  } else if (digit == 10) {
    // Zone specials punch row 0 (12-0, 11-0); zone 0 and no zone punch 8-2.
    digitPunch = zone == 1 || zone == 2
        ? rowBit0
        : rowBitDigit(8) | rowBitDigit(2);
  } else {
    digitPunch = rowBitDigit(8) | rowBitDigit(digit - 8);
  }
  return zonePunch | digitPunch;
}

const String _glyphs =
    r"0123456789?='???+ABCDEFGHI?.)???-JKLMNOPQR?$*??? /STUVWXYZ?,(???";

/// The Set H glyph of BCD code [bcd] (a single character; a space for
/// blank), or `null` when the code has no Set H glyph.
String? glyphFromBcd(int bcd) {
  _checkBcd(bcd);
  final String g = _glyphs[bcd];
  return g == '?' ? null : g;
}

/// The BCD code of Set H glyph [glyph], or `null` when [glyph] is not one of
/// the 48 source-set characters.
int? bcdFromGlyph(String glyph) {
  if (glyph.length != 1 || glyph == '?') {
    return null; // '?' marks unassigned slots in the table.
  }
  final int i = _glyphs.indexOf(glyph);
  return i < 0 ? null : i;
}

/// The name of a machine special (spec §4.3), or `null` for other codes. The
/// lozenge is an alternate print of octal 34 and has no code of its own.
String? machineSpecialName(int bcd) {
  _checkBcd(bcd);
  return switch (bcd) {
    0x1A => 'plus zero',
    0x1F => 'group mark',
    0x2A => 'minus zero',
    0x3A => 'record mark',
    _ => null,
  };
}

/// Whether [punches] is the canonical punch pattern of a code with a Set H
/// glyph — i.e. whether a mirror glyph line can carry this column (spec §3.1).
bool isGlyphColumn(int punches) {
  final int? bcd = bcdFromPunches(punches);
  if (bcd == null || glyphFromBcd(bcd) == null) {
    return false;
  }
  return punchesFromBcd(bcd) == punches;
}

const List<String> _rowNames = [
  '12', '11', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
];

/// The card code of [punches] as row names in top-to-bottom order joined
/// with hyphens, e.g. `12-8-5`; the empty string for no punches.
String cardCodeFromPunches(int punches) {
  if (punches < 0 || punches > 0xFFF) {
    throw RangeError.range(punches, 0, 0xFFF, 'punches');
  }
  final rows = <String>[];
  for (var bit = 11; bit >= 0; bit--) {
    if (punches & (1 << bit) != 0) {
      rows.add(_rowNames[11 - bit]);
    }
  }
  return rows.join('-');
}

/// Parses a card code in strict top-to-bottom row order back to a punch
/// pattern, or `null` when [code] is not a well-formed card code.
int? punchesFromCardCode(String code) {
  if (code.isEmpty) {
    return null;
  }
  var punches = 0;
  var lastBit = 12;
  for (final String name in code.split('-')) {
    final int i = _rowNames.indexOf(name);
    if (i < 0) {
      return null;
    }
    final int bit = 11 - i;
    if (bit >= lastBit) {
      return null; // Out of order or repeated.
    }
    lastBit = bit;
    punches |= 1 << bit;
  }
  return punches;
}

void _checkBcd(int bcd) {
  if (bcd < 0 || bcd > 0x3F) {
    throw RangeError.range(bcd, 0, 0x3F, 'bcd');
  }
}
