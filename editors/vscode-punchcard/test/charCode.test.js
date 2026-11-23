'use strict';

// test/charCodeVectors.test.js holds every read-out and every canonical
// punch of the TypeScript codec to the Dart one. These two cover the
// inverses the vectors do not carry.

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  bcdFromGlyph,
  bcdFromPunches,
  cardCodeFromPunches,
  glyphFromBcd,
  punchesFromCardCode,
} = require('../out/charCode.js');

test('each of the 48 source characters types the code it reads from', () => {
  let glyphs = 0;
  for (let bcd = 0; bcd <= 0o77; bcd++) {
    const glyph = glyphFromBcd(bcd);
    if (glyph === null) {
      continue;
    }
    glyphs++;
    assert.equal(bcdFromGlyph(glyph), bcd, `'${glyph}'`);
  }
  assert.equal(glyphs, 48);
  assert.equal(bcdFromPunches(0), bcdFromGlyph(' '));
});

test('a card code parses back to its punches, and a malformed one is refused', () => {
  for (let p = 1; p <= 0xfff; p++) {
    assert.equal(punchesFromCardCode(cardCodeFromPunches(p)), p, `punches ${p}`);
  }
  for (const bad of ['8-12', '12-12', '13', '']) {
    assert.equal(punchesFromCardCode(bad), null, bad);
  }
});
