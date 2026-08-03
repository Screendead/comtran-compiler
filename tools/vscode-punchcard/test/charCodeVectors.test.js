'use strict';

// Checks the committed cross-language parity fixtures
// (test/fixtures/char-code-*-vectors.csv) against the TypeScript codec that
// generated them. See test/fixtures/README.md for the file format this
// parses. A future Dart-side consumer compares the same files against
// lib/src/chars/char_code.dart (review finding VSC-5); until then this test
// guards against src/charCode.ts drifting from the committed fixture.

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const {
  bcdFromPunches,
  cardCodeFromPunches,
  glyphFromBcd,
  isGlyphColumn,
  machineSpecialName,
  punchesFromBcd,
} = require('../out/charCode.js');

const FIXTURES = path.join(__dirname, 'fixtures');
const PUNCH_VECTORS = path.join(FIXTURES, 'char-code-punch-vectors.csv');
const BCD_VECTORS = path.join(FIXTURES, 'char-code-bcd-vectors.csv');

/**
 * Parses one line of the fixture's format: every field double-quoted, `""`
 * escaping an internal quote, fields comma-separated.
 */
function parseCsvLine(line) {
  const fields = [];
  let i = 0;
  while (i < line.length) {
    if (line[i] !== '"') {
      throw new Error(`field ${fields.length} of ${JSON.stringify(line)} is not quoted`);
    }
    i++;
    let field = '';
    while (i < line.length) {
      if (line[i] === '"') {
        if (line[i + 1] === '"') {
          field += '"';
          i += 2;
        } else {
          i++;
          break;
        }
      } else {
        field += line[i];
        i++;
      }
    }
    fields.push(field);
    if (line[i] === ',') {
      i++;
    }
  }
  return fields;
}

/** Reads a fixture file into an array of `{ column: value }` row objects. */
function readCsv(filePath) {
  const text = fs.readFileSync(filePath, 'utf8');
  const lines = text.split('\n').filter((line) => line.length > 0);
  const header = parseCsvLine(lines[0]);
  return lines.slice(1).map((line) => {
    const values = parseCsvLine(line);
    assert.equal(values.length, header.length, `column count in ${JSON.stringify(line)}`);
    const row = {};
    header.forEach((name, i) => {
      row[name] = values[i];
    });
    return row;
  });
}

test('the committed punch-pattern vectors match the TypeScript codec', () => {
  const rows = readCsv(PUNCH_VECTORS);
  assert.equal(rows.length, 4096, 'run: npm run vectors');
  rows.forEach((row, i) => {
    const punches = Number(row.punches);
    assert.equal(punches, i, 'the fixture is sorted by ascending punches');
    const bcd = bcdFromPunches(punches);
    assert.equal(row.bcd, bcd === null ? '' : String(bcd), `punches ${punches}`);
    assert.equal(row.card_code, cardCodeFromPunches(punches), `punches ${punches}`);
    assert.equal(
      row.is_glyph_column,
      isGlyphColumn(punches) ? 'true' : 'false',
      `punches ${punches}`,
    );
  });
});

test('the committed BCD vectors match the TypeScript codec', () => {
  const rows = readCsv(BCD_VECTORS);
  assert.equal(rows.length, 64, 'run: npm run vectors');
  rows.forEach((row, i) => {
    const bcd = Number(row.bcd);
    assert.equal(bcd, i, 'the fixture is sorted by ascending bcd');
    const punches = punchesFromBcd(bcd);
    assert.equal(row.punches, punches === null ? '' : String(punches), `bcd ${bcd}`);
    assert.equal(row.glyph, glyphFromBcd(bcd) ?? '', `bcd ${bcd}`);
    assert.equal(row.machine_special, machineSpecialName(bcd) ?? '', `bcd ${bcd}`);
  });
});

test('the BCD vectors carry the literal comma glyph correctly quoted', () => {
  const rows = readCsv(BCD_VECTORS);
  const commaRow = rows.find((row) => row.glyph === ',');
  assert.ok(commaRow, 'no row has glyph ","');
  assert.equal(Number(commaRow.bcd), 59);
});
