/**
 * The read-out view of a card: what each column means under the §4 read rules,
 * and which source field each column belongs to.
 *
 * The extension host computes this and sends it to the webview. The webview
 * holds no copy of the character code, so the Dart reference stays the single
 * source of truth.
 */

import { Card, COLUMN_COUNT } from './canonCodec';
import {
  bcdFromPunches,
  cardCodeFromPunches,
  glyphFromBcd,
  machineSpecialName,
} from './charCode';

/** A card column field (definition §1.9.1, F p. 37). */
export interface Field {
  /** First column, 1-based. */
  start: number;
  /** Last column, 1-based and inclusive. */
  end: number;
  /** Short label for the ruler. */
  label: string;
  /** Full name for the status area. */
  name: string;
}

/** The four card fields of the Procedure Description form. */
export const FIELDS: Field[] = [
  { start: 1, end: 6, label: 'SERIAL', name: 'serial (ctl 1-3, serial 4-6)' },
  { start: 7, end: 12, label: 'NAME', name: 'name margin' },
  { start: 13, end: 72, label: 'TEXT', name: 'text' },
  { start: 73, end: 80, label: 'IDENT', name: 'identification' },
];

/** The field that contains `column` (1-based). */
export function fieldAt(column: number): Field {
  for (const f of FIELDS) {
    if (column >= f.start && column <= f.end) {
      return f;
    }
  }
  return FIELDS[FIELDS.length - 1];
}

/** What kind of read-out a column has. */
export type ReadoutKind =
  | 'blank'
  | 'glyph'
  | 'special'
  | 'unattested'
  | 'none';

/** Marker shown for a machine special (no Set H glyph). */
export const MARKER_SPECIAL = '¤';

/** Marker shown for a readable but unattested code. */
export const MARKER_UNATTESTED = '~';

/** Marker shown for a column with no read-out at all. */
export const MARKER_NONE = '!';

/** The read-out of one column. */
export interface Readout {
  /** The character to show in the interpreted row. */
  ch: string;
  kind: ReadoutKind;
  /** The card code, e.g. `12-5-8`; empty for a blank column. */
  code: string;
  /** The BCD code in octal, or an empty string when there is no read-out. */
  octal: string;
  /** A short description for the tooltip and the status area. */
  name: string;
}

/** Reads one column's punch pattern under the §4 rules. */
export function readColumn(punches: number): Readout {
  const code = cardCodeFromPunches(punches);
  const bcd = bcdFromPunches(punches);
  if (bcd === null) {
    return {
      ch: MARKER_NONE,
      kind: 'none',
      code,
      octal: '',
      name: 'no read-out (illegal combination)',
    };
  }
  const octal = bcd.toString(8).padStart(2, '0');
  if (punches === 0) {
    return { ch: ' ', kind: 'blank', code, octal, name: 'blank' };
  }
  const glyph = glyphFromBcd(bcd);
  if (glyph !== null) {
    return { ch: glyph, kind: 'glyph', code, octal, name: `'${glyph}'` };
  }
  const special = machineSpecialName(bcd);
  if (special !== null) {
    return { ch: MARKER_SPECIAL, kind: 'special', code, octal, name: special };
  }
  return {
    ch: MARKER_UNATTESTED,
    kind: 'unattested',
    code,
    octal,
    name: 'unattested code',
  };
}

/** Reads every column of `card`. */
export function readCard(card: Card): Readout[] {
  const out: Readout[] = [];
  for (let i = 0; i < COLUMN_COUNT; i++) {
    out.push(readColumn(card[i]));
  }
  return out;
}

/** A one-line preview of `card` for the card list, trailing blanks removed. */
export function previewOf(card: Card): string {
  let text = '';
  for (let i = 0; i < COLUMN_COUNT; i++) {
    text += readColumn(card[i]).ch;
  }
  return text.replace(/ +$/, '');
}

/** Whether every column of `card` is blank or a Set H glyph column. */
export function isGlyphCard(card: Card): boolean {
  for (let i = 0; i < COLUMN_COUNT; i++) {
    const kind = readColumn(card[i]).kind;
    if (kind !== 'blank' && kind !== 'glyph') {
      return false;
    }
  }
  return true;
}
