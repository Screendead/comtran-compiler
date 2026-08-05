/**
 * The single source of the card column boundaries, shared by every view: the
 * field ruler and the card list of the punchcard editor (`cardView.ts` and
 * `media/punchcard.js`, via the state message) and the generated TextMate
 * grammar for `.ct` mirror files (`grammar.ts`). Change boundaries here
 * only; no view holds its own copy, so the views cannot drift.
 *
 * Column sources: serial 1-6, name margin 7-12, text 13-72, identification
 * 73-80 (definition §1.9.1, F p. 37); data description fields (definition
 * §1.9.2, F p. 65); environment fields (definition §1.9.3, J 02.06.01).
 */

/** A card column field. */
export interface DeckField {
  /** First column, 1-based. */
  start: number;
  /** Last column, 1-based and inclusive. */
  end: number;
  /** Short label for the ruler. */
  label: string;
  /** Full name for the status area. */
  name: string;
  /** CSS class suffix the card-list pane uses (`f-<css>`). */
  css: string;
  /** TextMate scope the generated `.ct` grammar uses; null = unscoped. */
  scope: string | null;
  /** Whether the field's text carries tokens (literals, numbers). */
  tokens?: boolean;
}

const SERIAL: DeckField = {
  start: 1,
  end: 6,
  label: 'SERIAL',
  name: 'serial (ctl 1-3, serial 4-6)',
  css: 'serial',
  scope: 'comment.serial.comtran-deck',
};

const IDENT: DeckField = {
  start: 73,
  end: 80,
  label: 'IDENT',
  name: 'identification',
  css: 'ident',
  scope: 'comment.identification.comtran-deck',
};

const CONTINUATION: DeckField = {
  start: 72,
  end: 72,
  label: 'C',
  name: 'continuation flag',
  css: 'cont',
  scope: 'constant.character.escape.continuation.comtran-deck',
};

/** The generic card form: control cards, loose cards, the punch grid ruler. */
export const GENERIC_FIELDS: DeckField[] = [
  SERIAL,
  {
    start: 7,
    end: 12,
    label: 'NAME',
    name: 'name margin',
    css: 'name',
    scope: null,
  },
  { start: 13, end: 72, label: 'TEXT', name: 'text', css: 'text', scope: null },
  IDENT,
];

/** Data description card fields (definition §1.9.2, F p. 65). */
export const DATA_FIELDS: DeckField[] = [
  SERIAL,
  {
    start: 7,
    end: 22,
    label: 'NAME',
    name: 'name field',
    css: 'name',
    scope: 'entity.name.function.data-name.comtran-deck',
  },
  {
    start: 23,
    end: 24,
    label: 'LV',
    name: 'level',
    css: 'level',
    scope: 'constant.numeric.level.comtran-deck',
  },
  {
    start: 25,
    end: 30,
    label: 'TYPE',
    name: 'type code',
    css: 'type',
    scope: 'storage.type.comtran-deck',
  },
  {
    start: 31,
    end: 35,
    label: 'QTY',
    name: 'quantity',
    css: 'quantity',
    scope: 'constant.numeric.quantity.comtran-deck',
  },
  {
    start: 36,
    end: 36,
    label: 'M',
    name: 'mode',
    css: 'mode',
    scope: 'storage.modifier.mode.comtran-deck',
  },
  {
    start: 37,
    end: 37,
    label: 'J',
    name: 'justification',
    css: 'justify',
    scope: 'storage.modifier.justification.comtran-deck',
  },
  {
    start: 38,
    end: 71,
    label: 'DESCRIPTION',
    name: 'description',
    css: 'desc',
    scope: null,
    tokens: true,
  },
  CONTINUATION,
  IDENT,
];

/**
 * Environment card fields (definition §1.9.3, J 02.06.01). The type field
 * spans columns 23-30; the code itself sits in 25-30 (J 02.06.01.01).
 */
export const ENVIRONMENT_FIELDS: DeckField[] = [
  SERIAL,
  {
    start: 7,
    end: 22,
    label: 'NAME',
    name: 'name field',
    css: 'name',
    scope: 'entity.name.function.environment-name.comtran-deck',
  },
  {
    start: 23,
    end: 30,
    label: 'TYPE',
    name: 'type field (code in 25-30)',
    css: 'type',
    scope: 'storage.type.comtran-deck',
  },
  {
    start: 31,
    end: 71,
    label: 'OPTIONS',
    name: 'options',
    css: 'desc',
    scope: null,
    tokens: true,
  },
  CONTINUATION,
  IDENT,
];

/** Procedure card fields (definition §1.9.1, F p. 37). */
export const PROCEDURE_FIELDS: DeckField[] = [
  SERIAL,
  {
    start: 7,
    end: 12,
    label: 'NAME',
    name: 'name margin',
    css: 'name',
    scope: 'entity.name.function.label.comtran-deck',
  },
  {
    start: 13,
    end: 72,
    label: 'TEXT',
    name: 'text',
    css: 'text',
    scope: null,
    tokens: true,
  },
  IDENT,
];

/** The three division names. */
export type DivisionName = 'data' | 'environment' | 'procedure';

/**
 * Division header words, asterisk in column 7, nothing else in the body
 * (F p. 27; F p. 65; all three headers of the compiled sample sit in
 * column 7, scan-checked 2026-08-03).
 */
export const DIVISION_HEADERS: Record<DivisionName, string> = {
  data: '*DATA',
  environment: '*ENVIRONMENT',
  procedure: '*PROCEDURE',
};

/** The field table of each division. */
export const DIVISION_FIELDS: Record<DivisionName, DeckField[]> = {
  data: DATA_FIELDS,
  environment: ENVIRONMENT_FIELDS,
  procedure: PROCEDURE_FIELDS,
};

/**
 * Vertical-ruler columns for the generic card form: the column just before
 * each field after the first (the boundary between it and its predecessor),
 * plus the card's last column.
 */
export function rulerColumns(fields: DeckField[] = GENERIC_FIELDS): number[] {
  const rulers: number[] = [];
  for (let i = 1; i < fields.length; i++) {
    rulers.push(fields[i].start - 1);
  }
  rulers.push(fields[fields.length - 1].end);
  return rulers;
}

/**
 * The `contributes.configurationDefaults` block for the `comtran-deck`
 * language, built from this file's field tables so the rulers cannot drift
 * from the ones the grammar and the card list use. `generateGrammar.ts`
 * writes this into `package.json`; `test/grammar.test.js` fails while the
 * committed value is stale.
 */
export function configurationDefaults(): Record<string, unknown> {
  return {
    '[comtran-deck]': {
      'editor.rulers': rulerColumns(),
      'editor.wordWrap': 'off',
      'editor.fontFamily': 'monospace',
      // Keep a saved mirror in normal form (deck-format.md §3.3): LF
      // endings, a final newline, and no trailing spaces — the save sync's
      // to-canon rejects anything else.
      'files.eol': '\n',
      'files.insertFinalNewline': true,
      'files.trimTrailingWhitespace': true,
    },
  };
}
