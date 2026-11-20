'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const { decodeCanon, encodeCanon } = require('../out/canonCodec.js');
const { previewOf, readCard } = require('../out/cardView.js');

const REPO = path.join(__dirname, '..', '..', '..');
const CANON = path.join(REPO, 'test', 'fixtures', '90.05-payroll.ctd');
const MIRROR = path.join(REPO, 'test', 'fixtures', '90.05-payroll.ct');

const bytes = new Uint8Array(fs.readFileSync(CANON));

test('the 90.05 canon deck round-trips byte for byte', () => {
  const deck = decodeCanon(bytes);
  const again = encodeCanon(deck);
  assert.equal(again.length, bytes.length);
  assert.deepEqual(Buffer.from(again), Buffer.from(bytes));
});

test('the read-out of every card matches the committed mirror', () => {
  const deck = decodeCanon(bytes);
  const text = fs.readFileSync(MIRROR, 'utf8');
  const lines = text.split('\n');
  assert.equal(lines.pop(), '', 'the mirror must end with one LF');
  assert.equal(lines.length, deck.length);
  for (let i = 0; i < deck.length; i++) {
    assert.equal(previewOf(deck[i]), lines[i], `card ${i + 1}`);
  }
});

test('the read-out of a card names every column', () => {
  const deck = decodeCanon(bytes);
  const readout = readCard(deck[0]);
  assert.equal(readout.length, 80);
  for (const entry of readout) {
    assert.equal(typeof entry.ch, 'string');
    assert.equal(entry.ch.length, 1);
    assert.ok(entry.name.length > 0);
  }
});
