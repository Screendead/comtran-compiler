'use strict';

// Exercises the deckSync helpers: pair-path derivation, the repository-root
// walk, and the promise wrapper around the `deckconv` child process (with
// `node:child_process` stubbed — CI has no Dart SDK).

const assert = require('node:assert/strict');
const fs = require('node:fs');
const Module = require('node:module');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

let execCalls = [];
let execResult = { error: null, stdout: '', stderr: '' };

const load = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'node:child_process') {
    return {
      execFile: (command, args, options, callback) => {
        execCalls.push({ command, args, options });
        process.nextTick(() =>
          callback(execResult.error, execResult.stdout, execResult.stderr),
        );
      },
    };
  }
  return load.call(this, request, parent, isMain);
};

const {
  canonPathFor,
  mirrorPathFor,
  pairBusy,
  repoRootFor,
  runDeckconv,
  withPair,
} = require('../out/deckSync.js');

test('mirrorPathFor swaps .ctd for .ct and rejects anything else', () => {
  assert.equal(mirrorPathFor('/a/b/deck.ctd'), '/a/b/deck.ct');
  assert.equal(mirrorPathFor('/a/b/deck.ct'), null);
  assert.equal(mirrorPathFor('/a/b/deck.txt'), null);
});

test('canonPathFor swaps .ct for .ctd and rejects anything else', () => {
  assert.equal(canonPathFor('/a/b/deck.ct'), '/a/b/deck.ctd');
  assert.equal(canonPathFor('/a/b/deck.ctd'), null);
  assert.equal(canonPathFor('/a/b/deck'), null);
});

test('repoRootFor finds the nearest ancestor with a pubspec.yaml', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'decksync-'));
  fs.writeFileSync(path.join(root, 'pubspec.yaml'), 'name: sample\n');
  const nested = path.join(root, 'test', 'fixtures');
  fs.mkdirSync(nested, { recursive: true });
  assert.equal(repoRootFor(path.join(nested, 'deck.ctd')), root);
  fs.rmSync(root, { recursive: true });
});

test('repoRootFor returns null outside a Dart package', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'decksync-'));
  assert.equal(repoRootFor(path.join(dir, 'deck.ctd')), null);
  fs.rmSync(dir, { recursive: true });
});

test('runDeckconv runs dart from the given root and reports success', async () => {
  execCalls = [];
  execResult = { error: null, stdout: 'regenerated x.ct\n', stderr: '' };
  const result = await runDeckconv('/repo', ['regen', '/repo/x.ctd']);
  assert.deepEqual(result, { ok: true, detail: '' });
  assert.equal(execCalls.length, 1);
  assert.equal(execCalls[0].command, 'dart');
  assert.deepEqual(execCalls[0].args, [
    'run',
    'comtran:deckconv',
    'regen',
    '/repo/x.ctd',
  ]);
  assert.equal(execCalls[0].options.cwd, '/repo');
});

test('a failing run reports the stderr text', async () => {
  execCalls = [];
  execResult = {
    error: new Error('exit 1'),
    stdout: '',
    stderr: 'error: card 3, column 2: "x" is not a source-set glyph\n',
  };
  const result = await runDeckconv('/repo', ['to-canon', 'a.ct', 'a.ctd']);
  assert.equal(result.ok, false);
  assert.match(result.detail, /card 3/);
});

test('a spawn failure with no stderr reports the error message', async () => {
  execCalls = [];
  execResult = { error: new Error('spawn dart ENOENT'), stdout: '', stderr: '' };
  const result = await runDeckconv('/repo', ['regen', 'x.ctd']);
  assert.deepEqual(result, { ok: false, detail: 'spawn dart ENOENT' });
});

test('withPair serializes runs on one pair and pairBusy tracks them', async () => {
  const order = [];
  let releaseFirst;
  const first = withPair('/a.ctd', () => {
    order.push('first-start');
    return new Promise((resolve) => {
      releaseFirst = () => {
        order.push('first-end');
        resolve('one');
      };
    });
  });
  const second = withPair('/a.ctd', async () => {
    order.push('second');
    return 'two';
  });
  assert.equal(pairBusy('/a.ctd'), true);
  assert.equal(pairBusy('/b.ctd'), false);
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(order, ['first-start'], 'the second run waits');
  releaseFirst();
  assert.deepEqual([await first, await second], ['one', 'two']);
  assert.deepEqual(order, ['first-start', 'first-end', 'second']);
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(pairBusy('/a.ctd'), false);
});
