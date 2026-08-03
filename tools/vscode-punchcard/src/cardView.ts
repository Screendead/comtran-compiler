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
import {
  DIVISION_FIELDS,
  DIVISION_HEADERS,
  DeckField,
  DivisionName,
  GENERIC_FIELDS,
} from './columns';

/** A card column field (definition §1.9.1, F p. 37). */
export type Field = DeckField;

/** The four card fields of the generic (Procedure Description) form. */
export const FIELDS: Field[] = GENERIC_FIELDS;

/** The field of `fields` that contains `column` (1-based). */
export function fieldAt(column: number, fields: Field[] = FIELDS): Field {
  for (const f of fields) {
    if (column >= f.start && column <= f.end) {
      return f;
    }
  }
  return fields[fields.length - 1];
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

/**
 * What a card is within its deck. Determines the field table that colors it
 * in the card list and the ruler shown when it is current.
 */
export type CardKind =
  | 'blank'
  | 'binary'
  | 'control'
  | 'header-data'
  | 'header-environment'
  | 'header-procedure'
  | 'finish'
  | 'data'
  | 'environment'
  | 'procedure'
  | 'loose';

/** The body of a card: columns 7-72 of `text`, right-trimmed. */
function bodyOf(text: string): string {
  return text.slice(6, 72).replace(/ +$/, '');
}

/**
 * Classifies every card of `deck` by walking the division headers, with the
 * same rules as the compiler's deck splitter (`lib/src/lexer/
 * source_program.dart`): a header has `*` in column 7 and only the header
 * word in the body; `*FINISH` ends the deck; `$CMPLE` in columns 1-6 or
 * `*COMPILE` from column 7 is a control card before the first header.
 */
export function classifyCards(deck: readonly Card[]): CardKind[] {
  let division: DivisionName | null = null;
  let finished = false;

  const classify = (card: Card): CardKind => {
    if (finished) {
      return 'loose';
    }
    let blank = true;
    for (let i = 0; i < COLUMN_COUNT; i++) {
      if (card[i] !== 0) {
        blank = false;
        break;
      }
    }
    if (blank) {
      return 'blank';
    }
    if (!isGlyphCard(card)) {
      return 'binary';
    }
    const text = previewOf(card);
    const body = bodyOf(text);
    if (text[6] === '*') {
      for (const name of Object.keys(DIVISION_HEADERS) as DivisionName[]) {
        if (body === DIVISION_HEADERS[name]) {
          division = name;
          return `header-${name}`;
        }
      }
    }
    if (body.startsWith('*FINISH') && body.slice(7).trim() === '') {
      finished = true;
      return 'finish';
    }
    if (division === null) {
      if (text.slice(0, 6) === '$CMPLE' || body.startsWith('*COMPILE')) {
        return 'control';
      }
      return 'loose';
    }
    return division;
  };

  return deck.map(classify);
}

/** The field table for a card of `kind`. */
export function fieldsFor(kind: CardKind): Field[] {
  switch (kind) {
    case 'data':
    case 'environment':
    case 'procedure':
      return DIVISION_FIELDS[kind];
    default:
      return GENERIC_FIELDS;
  }
}
