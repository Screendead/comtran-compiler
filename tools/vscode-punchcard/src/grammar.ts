/**
 * Builds the TextMate grammar for `.deck` mirror files from the shared column
 * tables in `columns.ts`. `generateGrammar.ts` writes the result to
 * `syntaxes/comtran-deck.tmLanguage.json`; the committed file must match the
 * builder (`npm run grammar` regenerates it, `test/grammar.test.js` checks).
 *
 * The mirror format is `docs/design/deck-format.md` §3: one line per card,
 * card column N = line character N, trailing blanks trimmed, `!` punch lines
 * for cards outside the source set. Division context crosses lines, so the
 * grammar models each division as a begin/end region that opens on its header
 * line and closes on a lookahead to the next header or `*FINISH` — the same
 * rules as the compiler's deck splitter (`lib/src/lexer/source_program.dart`).
 */

import {
  DATA_FIELDS,
  DeckField,
  DIVISION_HEADERS,
  DivisionName,
  ENVIRONMENT_FIELDS,
  GENERIC_FIELDS,
  PROCEDURE_FIELDS,
} from './columns';

type Rule = Record<string, unknown>;

const SERIAL_SCOPE = GENERIC_FIELDS[0].scope as string;
const SERIAL_WIDTH = GENERIC_FIELDS[0].end;

/** An alphameric literal; the delimiter is the straight apostrophe (F p. 12). */
const LITERAL: Rule = {
  match: "'[^']*(?:'|$)",
  name: 'string.quoted.single.comtran-deck',
};

/** A J floating-point literal, e.g. `20.F+01`, `5FF` (J 02.04.03). */
const FLOATING: Rule = {
  match: '\\b[0-9]+(?:\\.[0-9]*)?FF?(?:[+-]?[0-9]+)?\\b',
  name: 'constant.numeric.floating.comtran-deck',
};

const NUMERIC: Rule = {
  match: '\\b[0-9]+(?:\\.[0-9]+)?\\b',
  name: 'constant.numeric.comtran-deck',
};

/**
 * The sentence terminator — a period followed by a blank or the card end —
 * and after it the rest of the card, which is unscanned commentary
 * (J 02.04.01).
 */
const TERMINATOR: Rule = {
  match: '(\\.)(?: (.*))?$',
  captures: {
    '1': { name: 'keyword.operator.terminator.comtran-deck' },
    '2': { name: 'comment.line.commentary.comtran-deck' },
  },
};

/** Tokens of the data description, environment options and control fields. */
const FIELD_TOKENS: Rule[] = [LITERAL, FLOATING, NUMERIC];

/** Tokens of free-form procedure text. */
const PROCEDURE_TOKENS: Rule[] = [LITERAL, TERMINATOR, FLOATING, NUMERIC];

function escapeHeader(word: string): string {
  return word.replace(/\*/g, '\\*');
}

/**
 * Zero-width end match: the region closes when the next line is a division
 * header or a `*FINISH` card, so the root patterns get that line.
 */
const END_BEFORE_HEADER = `^(?=.{${SERIAL_WIDTH}}(?:${[
  ...Object.values(DIVISION_HEADERS),
  '*FINISH',
]
  .map(escapeHeader)
  .join('|')})$)`;

/**
 * One line-anchored match per card, one capture per field of `fields`, each
 * `(.{0,width})` so short (right-trimmed) mirror lines still match.
 */
function cardLineRule(fields: DeckField[], tokens: Rule[]): Rule {
  let match = '^';
  const captures: Record<string, Rule> = {};
  fields.forEach((field, i) => {
    const width = field.end - field.start + 1;
    if (i === 0) {
      match += `(.{${width}})`;
    } else if (i === fields.length - 1) {
      match += '(.*)$';
    } else {
      match += `(.{0,${width}})`;
    }
    const capture: Rule = {};
    if (field.scope !== null) {
      capture.name = field.scope;
    }
    if (field.tokens === true) {
      capture.patterns = tokens;
    }
    if (Object.keys(capture).length > 0) {
      captures[String(i + 1)] = capture;
    }
  });
  return { match, captures };
}

/** A line too short to reach past the serial field. */
const SHORT_LINE: Rule = {
  match: `^(.{1,${SERIAL_WIDTH}})$`,
  captures: { '1': { name: SERIAL_SCOPE } },
};

function divisionRegion(division: DivisionName, patterns: Rule[]): Rule {
  return {
    begin: `^(.{${SERIAL_WIDTH}})(${escapeHeader(
      DIVISION_HEADERS[division],
    )})$`,
    beginCaptures: {
      '1': { name: SERIAL_SCOPE },
      '2': { name: 'keyword.control.division.comtran-deck' },
    },
    end: END_BEFORE_HEADER,
    patterns,
  };
}

/** The complete grammar, ready to serialize. */
export function buildGrammar(): Rule {
  return {
    name: 'COMTRAN Deck Mirror',
    scopeName: 'source.comtran-deck',
    fileTypes: ['deck'],
    patterns: [
      { include: '#punch-line' },
      { include: '#data-division' },
      { include: '#environment-division' },
      { include: '#procedure-division' },
      { include: '#finish-card' },
      { include: '#cmple-card' },
      { include: '#compile-card' },
      { include: '#loose-serial' },
    ],
    repository: {
      'punch-line': {
        match: '^(!)((?: [0-9]+:[0-9-]+)*)$',
        captures: {
          '1': { name: 'keyword.operator.punch.comtran-deck' },
          '2': {
            patterns: [
              {
                match: '([0-9]+)(:)([0-9-]+)',
                captures: {
                  '1': { name: 'constant.numeric.column.comtran-deck' },
                  '2': { name: 'punctuation.separator.comtran-deck' },
                  '3': { name: 'string.unquoted.rows.comtran-deck' },
                },
              },
            ],
          },
        },
      },
      'data-division': divisionRegion('data', [
        { include: '#punch-line' },
        cardLineRule(DATA_FIELDS, FIELD_TOKENS),
        SHORT_LINE,
      ]),
      'environment-division': divisionRegion('environment', [
        { include: '#punch-line' },
        cardLineRule(ENVIRONMENT_FIELDS, FIELD_TOKENS),
        SHORT_LINE,
      ]),
      'procedure-division': divisionRegion('procedure', [
        { include: '#punch-line' },
        {
          match: `^(.{${SERIAL_WIDTH}})([^ ]+)`,
          captures: {
            '1': { name: SERIAL_SCOPE },
            '2': { name: PROCEDURE_FIELDS[1].scope },
          },
        },
        {
          match: `^(.{1,${SERIAL_WIDTH}})`,
          captures: { '1': { name: SERIAL_SCOPE } },
        },
        ...PROCEDURE_TOKENS,
      ]),
      'finish-card': {
        match: `^(.{${SERIAL_WIDTH}})(\\*FINISH)$`,
        captures: {
          '1': { name: SERIAL_SCOPE },
          '2': { name: 'keyword.control.card.comtran-deck' },
        },
      },
      'cmple-card': {
        match: '^(\\$CMPLE)(.*)$',
        captures: {
          '1': { name: 'keyword.control.card.comtran-deck' },
          '2': { patterns: FIELD_TOKENS },
        },
      },
      'compile-card': {
        match: `^(.{${SERIAL_WIDTH}})(\\*COMPILE)(.*)$`,
        captures: {
          '1': { name: SERIAL_SCOPE },
          '2': { name: 'keyword.control.card.comtran-deck' },
          '3': { patterns: FIELD_TOKENS },
        },
      },
      'loose-serial': {
        match: `^(.{1,${SERIAL_WIDTH}})`,
        captures: { '1': { name: SERIAL_SCOPE } },
      },
    },
  };
}
