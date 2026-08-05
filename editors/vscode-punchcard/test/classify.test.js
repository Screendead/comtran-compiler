'use strict';

// Card classification: the division walk that colors the card list must
// follow the same deck-splitting rules as the compiler
// (`lib/src/lexer/source_program.dart`).

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const { decodeCanon } = require('../out/canonCodec.js');
const { classifyCards, fieldsFor, reclassifyCard } = require('../out/cardView.js');
const { bcdFromGlyph, punchesFromBcd } = require('../out/charCode.js');
const {
  DATA_FIELDS,
  ENVIRONMENT_FIELDS,
  GENERIC_FIELDS,
  PROCEDURE_FIELDS,
} = require('../out/columns.js');

const REPO = path.join(__dirname, '..', '..', '..');
const CANON = path.join(REPO, 'test', 'fixtures', '90.05-payroll.ctd');

function cardFromText(text) {
  const card = new Uint16Array(80);
  for (let i = 0; i < text.length; i++) {
    if (text[i] !== ' ') {
      card[i] = punchesFromBcd(bcdFromGlyph(text[i]));
    }
  }
  return card;
}

test('the 90.05 deck classifies into its documented card ranges', () => {
  const deck = decodeCanon(new Uint8Array(fs.readFileSync(CANON)));
  const kinds = classifyCards(deck);
  assert.equal(kinds.length, 293);
  // test/fixtures/90.05-payroll-deck-notes.md: card 1 *COMPILE; 2-179 *DATA header +
  // 177 data cards; 180-195 *ENVIRONMENT header + 15 cards; 196-293
  // *PROCEDURE header + 97 cards.
  assert.equal(kinds[0], 'control');
  assert.equal(kinds[1], 'header-data');
  for (let i = 2; i <= 178; i++) {
    assert.equal(kinds[i], 'data', `card ${i + 1}`);
  }
  assert.equal(kinds[179], 'header-environment');
  for (let i = 180; i <= 194; i++) {
    assert.equal(kinds[i], 'environment', `card ${i + 1}`);
  }
  assert.equal(kinds[195], 'header-procedure');
  for (let i = 196; i <= 292; i++) {
    assert.equal(kinds[i], 'procedure', `card ${i + 1}`);
  }
});

test('control, finish and loose cards classify as the splitter would', () => {
  const kinds = classifyCards([
    cardFromText('$CMPLE'),
    cardFromText('      LOOSE TEXT BEFORE A HEADER'),
    cardFromText(''),
    cardFromText('      *PROCEDURE'),
    cardFromText('      *FINISH'),
    cardFromText('      AFTER THE FINISH CARD'),
  ]);
  assert.deepEqual(kinds, [
    'control',
    'loose',
    'blank',
    'header-procedure',
    'finish',
    'loose',
  ]);
});

test('a blank card after *FINISH classifies as loose, not blank', () => {
  // lib/src/lexer/source_program.dart tests finishCard before isBlank, so a
  // blank card after *FINISH is a problem (msgCardAfterFinish), not silently
  // dropped. The classifier must test the same guard in the same order.
  const kinds = classifyCards([
    cardFromText('      *FINISH'),
    cardFromText(''),
    cardFromText('      AFTER THE FINISH CARD'),
  ]);
  assert.deepEqual(kinds, ['finish', 'loose', 'loose']);
});

test('reclassifyCard matches classifyCards for every index (VSC-4 cache)', () => {
  const deck = [
    cardFromText('$CMPLE'),
    cardFromText('      *DATA'),
    cardFromText('      HOURS'),
    cardFromText('      *ENVIRONMENT'),
    cardFromText('      *PROCEDURE'),
    cardFromText('      START OPEN FILE.'),
    cardFromText('      *FINISH'),
    cardFromText(''),
  ];
  const kinds = classifyCards(deck);
  deck.forEach((_, i) => {
    assert.equal(reclassifyCard(deck, kinds, i), kinds[i], `card ${i + 1}`);
  });
});

test('reclassifyCard catches a card whose own kind changed', () => {
  const deck = [cardFromText('      *DATA'), cardFromText('      HOURS')];
  const kinds = classifyCards(deck);
  assert.equal(kinds[1], 'data');
  // Edit card 2 into a second data header: its own kind changes even
  // though nothing before it did.
  deck[1] = cardFromText('      *DATA');
  assert.equal(reclassifyCard(deck, kinds, 1), 'header-data');
  assert.notEqual(reclassifyCard(deck, kinds, 1), kinds[1]);
});

test('a header needs the asterisk in column 7 and a bare body', () => {
  const kinds = classifyCards([
    cardFromText('       *DATA'), // column 8: not a header
    cardFromText('      *DATA EXTRA'), // trailing text: not a header
    cardFromText('      *DATA'),
  ]);
  assert.deepEqual(kinds, ['loose', 'loose', 'header-data']);
});

test('a card with an illegal combination classifies as binary', () => {
  const card = new Uint16Array(80);
  card[0] = 0b000000000011; // rows 8 and 9 together: no read-out
  assert.deepEqual(classifyCards([card]), ['binary']);
});

test('fieldsFor picks the division table', () => {
  assert.equal(fieldsFor('data'), DATA_FIELDS);
  assert.equal(fieldsFor('environment'), ENVIRONMENT_FIELDS);
  assert.equal(fieldsFor('procedure'), PROCEDURE_FIELDS);
  assert.equal(fieldsFor('control'), GENERIC_FIELDS);
  assert.equal(fieldsFor('blank'), GENERIC_FIELDS);
});

test('every field table tiles columns 1 to 80 without gap or overlap', () => {
  for (const fields of [
    GENERIC_FIELDS,
    DATA_FIELDS,
    ENVIRONMENT_FIELDS,
    PROCEDURE_FIELDS,
  ]) {
    let next = 1;
    for (const f of fields) {
      assert.equal(f.start, next, f.name);
      assert.ok(f.end >= f.start, f.name);
      next = f.end + 1;
    }
    assert.equal(next, 81);
  }
});
