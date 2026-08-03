'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  BCD_BLANK,
  BCD_GROUP_MARK,
  bcdFromGlyph,
  bcdFromPunches,
  cardCodeFromPunches,
  glyphFromBcd,
  isGlyphColumn,
  machineSpecialName,
  punchesFromBcd,
  punchesFromCardCode,
} = require('../out/charCode.js');

/** The 48 source-set characters with their canonical card codes (spec §4.3). */
const SOURCE_SET = [
  ['0', '0'], ['1', '1'], ['2', '2'], ['3', '3'], ['4', '4'],
  ['5', '5'], ['6', '6'], ['7', '7'], ['8', '8'], ['9', '9'],
  ['=', '3-8'], ["'", '4-8'],
  ['+', '12'],
  ['A', '12-1'], ['B', '12-2'], ['C', '12-3'], ['D', '12-4'], ['E', '12-5'],
  ['F', '12-6'], ['G', '12-7'], ['H', '12-8'], ['I', '12-9'],
  ['.', '12-3-8'], [')', '12-4-8'],
  ['-', '11'],
  ['J', '11-1'], ['K', '11-2'], ['L', '11-3'], ['M', '11-4'], ['N', '11-5'],
  ['O', '11-6'], ['P', '11-7'], ['Q', '11-8'], ['R', '11-9'],
  ['$', '11-3-8'], ['*', '11-4-8'],
  [' ', ''],
  ['/', '0-1'],
  ['S', '0-2'], ['T', '0-3'], ['U', '0-4'], ['V', '0-5'], ['W', '0-6'],
  ['X', '0-7'], ['Y', '0-8'], ['Z', '0-9'],
  [',', '0-3-8'], ['(', '0-4-8'],
];

/** The four machine specials with their card codes (spec §4.3). */
const SPECIALS = [
  ['plus zero', '12-0', 0o32],
  ['group mark', '12-5-8', 0o37],
  ['minus zero', '11-0', 0o52],
  ['record mark', '0-2-8', 0o72],
];

function punches(code) {
  return code === '' ? 0 : punchesFromCardCode(code);
}

test('the source set has 48 characters', () => {
  assert.equal(SOURCE_SET.length, 48);
});

test('each source character reads from its card code', () => {
  for (const [glyph, code] of SOURCE_SET) {
    const p = punches(code);
    const bcd = bcdFromPunches(p);
    assert.notEqual(bcd, null, `${code} has no read-out`);
    assert.equal(glyphFromBcd(bcd), glyph, `${code} does not read '${glyph}'`);
  }
});

test('each source character punches its card code', () => {
  for (const [glyph, code] of SOURCE_SET) {
    const bcd = bcdFromGlyph(glyph);
    assert.notEqual(bcd, null, `'${glyph}' has no code`);
    assert.equal(cardCodeFromPunches(punchesFromBcd(bcd)), code);
    assert.equal(isGlyphColumn(punchesFromBcd(bcd)), true);
  }
});

test('a blank column reads octal 60', () => {
  assert.equal(bcdFromPunches(0), BCD_BLANK);
  assert.equal(BCD_BLANK, 0o60);
  assert.equal(glyphFromBcd(BCD_BLANK), ' ');
  assert.equal(punchesFromBcd(BCD_BLANK), 0);
});

test('a bare 0 punch is the digit zero, not a zone', () => {
  assert.equal(bcdFromPunches(punches('0')), 0o00);
  assert.equal(glyphFromBcd(0o00), '0');
});

test('row 0 under a zone is a digit of value ten', () => {
  assert.equal(bcdFromPunches(punches('12-0')), 0o32);
  assert.equal(bcdFromPunches(punches('11-0')), 0o52);
});

test('row 0 above a digit part is the zone', () => {
  assert.equal(bcdFromPunches(punches('0-1')), 0o61);
  assert.equal(bcdFromPunches(punches('0-9')), 0o71);
  assert.equal(bcdFromPunches(punches('0-4-8')), 0o74);
});

test('12-5-8 is the group mark, by the 705 translation', () => {
  assert.equal(bcdFromPunches(punches('12-5-8')), BCD_GROUP_MARK);
  assert.equal(BCD_GROUP_MARK, 0o37);
  assert.equal(glyphFromBcd(BCD_GROUP_MARK), null);
  assert.equal(machineSpecialName(BCD_GROUP_MARK), 'group mark');
});

test('12-7-8 has no read-out', () => {
  assert.equal(bcdFromPunches(punches('12-7-8')), null);
});

test('octal 35 has no card code', () => {
  assert.equal(punchesFromBcd(0o35), null);
});

test('the machine specials keep their names and codes', () => {
  for (const [name, code, octal] of SPECIALS) {
    assert.equal(bcdFromPunches(punches(code)), octal, code);
    assert.equal(machineSpecialName(octal), name);
    assert.equal(glyphFromBcd(octal), null);
  }
});

test('two zone punches have no read-out', () => {
  assert.equal(bcdFromPunches(punches('12-11')), null);
  assert.equal(bcdFromPunches(punches('12-11-0-1-2-3-4-5-6-7-8-9')), null);
});

test('two digit punches without row 8 have no read-out', () => {
  assert.equal(bcdFromPunches(punches('1-2')), null);
  assert.equal(bcdFromPunches(punches('11-3-4')), null);
});

test('the 8-combinations read as the sum of the two punches', () => {
  for (let d = 2; d <= 7; d++) {
    assert.equal(bcdFromPunches(punches(`${d}-8`)), 8 + d);
  }
});

test('every code round-trips through its canonical punches', () => {
  for (let bcd = 0; bcd <= 0o77; bcd++) {
    const p = punchesFromBcd(bcd);
    if (bcd === 0o35) {
      assert.equal(p, null);
      continue;
    }
    assert.equal(bcdFromPunches(p), bcd, `octal ${bcd.toString(8)}`);
  }
});

test('every readable pattern reads a code in range', () => {
  let readable = 0;
  for (let p = 0; p <= 0xfff; p++) {
    const bcd = bcdFromPunches(p);
    if (bcd === null) {
      continue;
    }
    readable++;
    assert.ok(bcd >= 0 && bcd <= 0o77, `pattern ${p} read ${bcd}`);
  }
  // 63 canonical patterns plus the two collisions 12-2-8 and 11-2-8.
  assert.equal(readable, 65);
});

test('card codes are written and parsed top to bottom', () => {
  assert.equal(cardCodeFromPunches(0), '');
  assert.equal(cardCodeFromPunches(0xfff), '12-11-0-1-2-3-4-5-6-7-8-9');
  assert.equal(punchesFromCardCode('12-11-0-1-2-3-4-5-6-7-8-9'), 0xfff);
  assert.equal(punchesFromCardCode('8-12'), null);
  assert.equal(punchesFromCardCode('12-12'), null);
  assert.equal(punchesFromCardCode('13'), null);
  assert.equal(punchesFromCardCode(''), null);
});

test('the two collisions share a code with the zero-punch form', () => {
  assert.equal(bcdFromPunches(punches('12-2-8')), bcdFromPunches(punches('12-0')));
  assert.equal(bcdFromPunches(punches('11-2-8')), bcdFromPunches(punches('11-0')));
  assert.equal(isGlyphColumn(punches('12-2-8')), false);
});
