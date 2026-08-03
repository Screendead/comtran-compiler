'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  CANON_FORMAT_VERSION,
  COLUMN_COUNT,
  HEADER_LENGTH,
  RECORD_LENGTH,
  blankCard,
  decodeCanon,
  encodeCanon,
} = require('../out/canonCodec.js');

const MAGIC = Buffer.from('CTDECK', 'ascii');

test('the header carries the magic, version, flags and count', () => {
  const bytes = encodeCanon([blankCard(), blankCard(), blankCard()]);
  assert.deepEqual(Buffer.from(bytes.subarray(0, 6)), MAGIC);
  assert.equal(bytes[6], CANON_FORMAT_VERSION);
  assert.equal(bytes[7], 0);
  assert.equal(new DataView(bytes.buffer).getUint32(8, false), 3);
  assert.equal(bytes.length, HEADER_LENGTH + 3 * RECORD_LENGTH);
});

test('an empty deck is a bare header', () => {
  const bytes = encodeCanon([]);
  assert.equal(bytes.length, HEADER_LENGTH);
  assert.deepEqual(decodeCanon(bytes), []);
});

test('a blank card is 120 zero bytes', () => {
  const bytes = encodeCanon([blankCard()]);
  assert.equal(bytes.length, HEADER_LENGTH + RECORD_LENGTH);
  for (let i = HEADER_LENGTH; i < bytes.length; i++) {
    assert.equal(bytes[i], 0, `byte ${i} is not zero`);
  }
});

test('two columns pack into three bytes, most significant bit first', () => {
  const card = blankCard();
  card[0] = 0xabc;
  card[1] = 0x123;
  card[78] = 0xfff;
  card[79] = 0x001;
  const bytes = encodeCanon([card]);
  assert.equal(bytes[HEADER_LENGTH + 0], 0xab);
  assert.equal(bytes[HEADER_LENGTH + 1], 0xc1);
  assert.equal(bytes[HEADER_LENGTH + 2], 0x23);
  const last = HEADER_LENGTH + RECORD_LENGTH - 3;
  assert.equal(bytes[last + 0], 0xff);
  assert.equal(bytes[last + 1], 0xf0);
  assert.equal(bytes[last + 2], 0x01);
});

test('column order is column 1 first, column 80 last', () => {
  const card = blankCard();
  for (let i = 0; i < COLUMN_COUNT; i++) {
    card[i] = (i * 7 + 1) & 0xfff;
  }
  const [back] = decodeCanon(encodeCanon([card]));
  assert.deepEqual(Array.from(back), Array.from(card));
});

test('decode rejects a short file', () => {
  assert.throws(() => decodeCanon(new Uint8Array(11)), /shorter than/);
});

test('decode rejects a bad magic', () => {
  const bytes = encodeCanon([blankCard()]);
  bytes[0] = 0x58;
  assert.throws(() => decodeCanon(bytes), /bad magic/);
});

test('decode rejects an unknown version', () => {
  const bytes = encodeCanon([blankCard()]);
  bytes[6] = 2;
  assert.throws(() => decodeCanon(bytes), /unknown canon format version 2/);
});

test('decode rejects nonzero flags', () => {
  const bytes = encodeCanon([blankCard()]);
  bytes[7] = 1;
  assert.throws(() => decodeCanon(bytes), /reserved flags byte is nonzero/);
});

test('decode rejects a length that the count does not match', () => {
  const bytes = encodeCanon([blankCard(), blankCard()]);
  assert.throws(() => decodeCanon(bytes.subarray(0, bytes.length - 1)), /does not match/);
});

test('encode rejects a card that is not 80 columns', () => {
  assert.throws(() => encodeCanon([new Uint16Array(79)]), /exactly 80 columns/);
});

test('encode rejects a column value wider than 12 bits', () => {
  const card = blankCard();
  card[5] = 0x1000;
  assert.throws(() => encodeCanon([card]), /12 bits/);
});

test('a deck of every 12-bit pattern round-trips', () => {
  const deck = [];
  let value = 0;
  for (let c = 0; c < 52; c++) {
    const card = blankCard();
    for (let i = 0; i < COLUMN_COUNT; i++) {
      card[i] = value & 0xfff;
      value++;
    }
    deck.push(card);
  }
  const back = decodeCanon(encodeCanon(deck));
  assert.equal(back.length, deck.length);
  for (let i = 0; i < deck.length; i++) {
    assert.deepEqual(Array.from(back[i]), Array.from(deck[i]));
  }
});
