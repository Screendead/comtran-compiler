/**
 * The 6-bit BCD character code and its card codes.
 *
 * A direct port of `lib/src/chars/char_code.dart`, which implements §4 of
 * `docs/design/deck-format.md` (decision D0.6): the read rules from punch
 * pattern to core-storage BCD code, the canonical punch pattern for each code,
 * and the Set H display glyphs. All values are core-storage codes.
 *
 * Keep this file in step with the Dart reference. Change neither without the
 * other, and never "improve" a rule here.
 */

/** Punch-row bit for row 12 (top zone row) in a 12-bit column value. */
export const ROW_BIT_12 = 1 << 11;

/** Punch-row bit for row 11. */
export const ROW_BIT_11 = 1 << 10;

/** Punch-row bit for row 0. */
export const ROW_BIT_0 = 1 << 9;

/** The BCD code of a blank column (octal 60). */
export const BCD_BLANK = 0x30;

/** The BCD code of the group mark (octal 37, card code 12-5-8). */
export const BCD_GROUP_MARK = 0x1f;

/** Punch-row bit for digit row `digit` (1-9). */
export function rowBitDigit(digit: number): number {
  if (!Number.isInteger(digit) || digit < 1 || digit > 9) {
    throw new RangeError(`digit ${digit} is not in the range 1..9`);
  }
  return 1 << (9 - digit);
}

// 12-5-8: row 12 (bit 11), row 5 (bit 4), row 8 (bit 1).
const GM_PUNCHES = 0x800 | 0x010 | 0x002;

function checkPunches(punches: number): void {
  if (!Number.isInteger(punches) || punches < 0 || punches > 0xfff) {
    throw new RangeError(`punches ${punches} is not in the range 0..0xFFF`);
  }
}

function checkBcd(bcd: number): void {
  if (!Number.isInteger(bcd) || bcd < 0 || bcd > 0x3f) {
    throw new RangeError(`bcd ${bcd} is not in the range 0..0x3F`);
  }
}

/**
 * Reads a column's punch pattern as a BCD code, or `null` when the pattern has
 * no readout (spec §4.1).
 */
export function bcdFromPunches(punches: number): number | null {
  checkPunches(punches);
  if (punches === 0) {
    return BCD_BLANK;
  }
  if (punches === GM_PUNCHES) {
    return BCD_GROUP_MARK; // The 705 group-mark translation, spec §4.1.
  }
  const has12 = (punches & ROW_BIT_12) !== 0;
  const has11 = (punches & ROW_BIT_11) !== 0;
  if (has12 && has11) {
    return null;
  }
  let digitRows = punches & ~(ROW_BIT_12 | ROW_BIT_11);
  let zone: number;
  if (has12) {
    zone = 1;
  } else if (has11) {
    zone = 2;
  } else if (digitRows === ROW_BIT_0) {
    return 0x00; // A bare 0 punch is the digit zero.
  } else if ((digitRows & ROW_BIT_0) !== 0) {
    zone = 3; // Row 0 as a zone punch, with a digit part below it.
    digitRows &= ~ROW_BIT_0;
  } else {
    zone = 0;
  }
  const digit = digitValue(digitRows);
  if (digit === null) {
    return null;
  }
  if (zone === 1 && digit === 15) {
    return null; // 12-7-8 has no readout; the group mark is 12-5-8 only.
  }
  return (zone << 4) | digit;
}

/**
 * The digit-part value of `digitRows` (rows 0-9 only), or `null` when the
 * combination is not a legal digit part.
 */
function digitValue(digitRows: number): number | null {
  if (digitRows === 0) {
    return 0;
  }
  if (digitRows === ROW_BIT_0) {
    return 10; // Row 0 as a digit under zone 12 or 11.
  }
  for (let d = 1; d <= 9; d++) {
    if (digitRows === rowBitDigit(d)) {
      return d;
    }
  }
  const rest = digitRows & ~rowBitDigit(8);
  if (rest !== digitRows) {
    for (let d = 2; d <= 7; d++) {
      if (rest === rowBitDigit(d)) {
        return 8 + d;
      }
    }
  }
  return null;
}

/**
 * The canonical punch pattern of BCD code `bcd`, or `null` for octal 35, the
 * one code with no card code (spec §4.3).
 */
export function punchesFromBcd(bcd: number): number | null {
  checkBcd(bcd);
  if (bcd === 0x00) {
    return ROW_BIT_0; // Digit zero.
  }
  if (bcd === BCD_BLANK) {
    return 0;
  }
  if (bcd === BCD_GROUP_MARK) {
    return GM_PUNCHES;
  }
  const zone = bcd >> 4;
  const digit = bcd & 0xf;
  let zonePunch: number;
  switch (zone) {
    case 0:
      zonePunch = 0;
      break;
    case 1:
      zonePunch = ROW_BIT_12;
      break;
    case 2:
      zonePunch = ROW_BIT_11;
      break;
    default:
      zonePunch = ROW_BIT_0;
      break;
  }
  if (zone === 1 && digit === 13) {
    return null; // Octal 35, displaced by the group-mark translation.
  }
  let digitPunch: number;
  if (digit === 0) {
    digitPunch = 0;
  } else if (digit <= 9) {
    digitPunch = rowBitDigit(digit);
  } else if (digit === 10) {
    // Zone specials punch row 0 (12-0, 11-0); zone 0 and no zone punch 8-2.
    digitPunch =
      zone === 1 || zone === 2
        ? ROW_BIT_0
        : rowBitDigit(8) | rowBitDigit(2);
  } else {
    digitPunch = rowBitDigit(8) | rowBitDigit(digit - 8);
  }
  return zonePunch | digitPunch;
}

const GLYPHS =
  "0123456789?='???+ABCDEFGHI?.)???-JKLMNOPQR?$*??? /STUVWXYZ?,(???";

/**
 * The Set H glyph of BCD code `bcd` (a single character; a space for blank), or
 * `null` when the code has no Set H glyph.
 */
export function glyphFromBcd(bcd: number): string | null {
  checkBcd(bcd);
  const g = GLYPHS[bcd];
  return g === '?' ? null : g;
}

/**
 * The BCD code of Set H glyph `glyph`, or `null` when `glyph` is not one of the
 * 48 source-set characters.
 */
export function bcdFromGlyph(glyph: string): number | null {
  if (glyph.length !== 1 || glyph === '?') {
    return null; // '?' marks unassigned slots in the table.
  }
  const i = GLYPHS.indexOf(glyph);
  return i < 0 ? null : i;
}

/**
 * The name of a machine special (spec §4.3), or `null` for other codes. The
 * lozenge is an alternate print of octal 34 and has no code of its own.
 */
export function machineSpecialName(bcd: number): string | null {
  checkBcd(bcd);
  switch (bcd) {
    case 0x1a:
      return 'plus zero';
    case 0x1f:
      return 'group mark';
    case 0x2a:
      return 'minus zero';
    case 0x3a:
      return 'record mark';
    default:
      return null;
  }
}

/**
 * Whether `punches` is the canonical punch pattern of a code with a Set H
 * glyph - i.e. whether a mirror glyph line can carry this column (spec §3.1).
 */
export function isGlyphColumn(punches: number): boolean {
  const bcd = bcdFromPunches(punches);
  if (bcd === null || glyphFromBcd(bcd) === null) {
    return false;
  }
  return punchesFromBcd(bcd) === punches;
}

/** Punch-row names, top to bottom; index 0 is bit 11. */
export const ROW_NAMES = [
  '12',
  '11',
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];

/**
 * The card code of `punches` as row names in top-to-bottom order joined with
 * hyphens, e.g. `12-8-5`; the empty string for no punches.
 */
export function cardCodeFromPunches(punches: number): string {
  checkPunches(punches);
  const rows: string[] = [];
  for (let bit = 11; bit >= 0; bit--) {
    if ((punches & (1 << bit)) !== 0) {
      rows.push(ROW_NAMES[11 - bit]);
    }
  }
  return rows.join('-');
}

/**
 * Parses a card code in strict top-to-bottom row order back to a punch pattern,
 * or `null` when `code` is not a well-formed card code.
 */
export function punchesFromCardCode(code: string): number | null {
  if (code.length === 0) {
    return null;
  }
  let punches = 0;
  let lastBit = 12;
  for (const name of code.split('-')) {
    const i = ROW_NAMES.indexOf(name);
    if (i < 0) {
      return null;
    }
    const bit = 11 - i;
    if (bit >= lastBit) {
      return null; // Out of order or repeated.
    }
    lastBit = bit;
    punches |= 1 << bit;
  }
  return punches;
}
