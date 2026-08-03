'use strict';

// Exercises the document and the webview message flow against a stub of the
// `vscode` module, so the edit, undo and save paths are covered outside VS Code.

const assert = require('node:assert/strict');
const fs = require('node:fs');
const Module = require('node:module');
const path = require('node:path');
const test = require('node:test');

// --- the vscode stub ------------------------------------------------------

class EventEmitter {
  constructor() {
    this.listeners = [];
    this.event = (listener) => {
      this.listeners.push(listener);
      return { dispose: () => {} };
    };
  }
  fire(value) {
    for (const listener of this.listeners.slice()) {
      listener(value);
    }
  }
  dispose() {
    this.listeners = [];
  }
}

function makeUri(scheme, fsPath) {
  return {
    scheme,
    fsPath,
    path: fsPath,
    toString: () => `${scheme}://${fsPath}`,
  };
}

const memory = new Map();

const vscodeStub = {
  EventEmitter,
  Uri: {
    file: (p) => makeUri('file', p),
    parse: (s) => {
      const i = s.indexOf('://');
      return makeUri(s.slice(0, i), s.slice(i + 3));
    },
    joinPath: (uri, ...parts) =>
      makeUri(uri.scheme, path.join(uri.fsPath, ...parts)),
  },
  workspace: {
    fs: {
      readFile: async (uri) => {
        const key = uri.toString();
        if (memory.has(key)) {
          return memory.get(key);
        }
        return new Uint8Array(fs.readFileSync(uri.fsPath));
      },
      writeFile: async (uri, data) => {
        memory.set(uri.toString(), Uint8Array.from(data));
      },
      delete: async (uri) => {
        memory.delete(uri.toString());
      },
    },
  },
  window: {
    registerCustomEditorProvider: () => ({ dispose: () => {} }),
  },
};

const load = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'vscode') {
    return vscodeStub;
  }
  return load.call(this, request, parent, isMain);
};

const { blankCard, decodeCanon, encodeCanon } = require('../out/canonCodec.js');
const { PunchcardDocument } = require('../out/punchcardDocument.js');
const { PunchcardEditorProvider } = require('../out/punchcardEditor.js');
const { punchesFromCardCode } = require('../out/charCode.js');

const NO_CANCEL = { isCancellationRequested: false };

function deckOf(cards) {
  return encodeCanon(cards);
}

async function openDeck(name, cards) {
  const uri = vscodeStub.Uri.file(`/${name}.ctdeck`);
  memory.set(uri.toString(), deckOf(cards));
  return { uri, document: await PunchcardDocument.create(uri, undefined) };
}

// --- document -------------------------------------------------------------

test('a document loads the deck from its file', async () => {
  const card = blankCard();
  card[0] = punchesFromCardCode('12-1');
  const { document } = await openDeck('load', [card, blankCard()]);
  assert.equal(document.cardCount, 2);
  assert.equal(document.card(0)[0], punchesFromCardCode('12-1'));
});

test('an untitled document starts with one blank card', async () => {
  const uri = makeUri('untitled', '/new.ctdeck');
  const document = await PunchcardDocument.create(uri, undefined);
  assert.equal(document.cardCount, 1);
  assert.equal(document.card(0).every((c) => c === 0), true);
});

test('a document tolerates a 0-byte canon file as an empty deck', async () => {
  const uri = vscodeStub.Uri.file('/zero-byte.ctdeck');
  memory.set(uri.toString(), new Uint8Array(0));
  const document = await PunchcardDocument.create(uri, undefined);
  assert.equal(document.cardCount, 0);
});

test('saving a deck that started at 0 bytes writes a valid empty-deck header', async () => {
  const uri = vscodeStub.Uri.file('/zero-byte-save.ctdeck');
  memory.set(uri.toString(), new Uint8Array(0));
  const document = await PunchcardDocument.create(uri, undefined);
  await document.save(NO_CANCEL);
  const written = memory.get(uri.toString());
  assert.equal(written.length, 12);
  assert.equal(decodeCanon(written).length, 0);
});

test('a punch fires an edit that undoes and redoes', async () => {
  const { document } = await openDeck('punch', [blankCard()]);
  const edits = [];
  const changes = [];
  document.onDidChange((e) => edits.push(e));
  document.onDidChangeContent((c) => changes.push(c));

  document.togglePunch(0, 5, 0); // Row 12 of column 5.
  assert.equal(document.card(0)[4], 1 << 11);
  assert.equal(edits.length, 1);
  assert.equal(changes.length, 1);
  assert.equal(changes[0].structural, false);
  assert.equal(changes[0].cardIndex, 0);

  edits[0].undo();
  assert.equal(document.card(0)[4], 0);
  edits[0].redo();
  assert.equal(document.card(0)[4], 1 << 11);
});

test('setting a column to the value it holds fires no edit', async () => {
  const { document } = await openDeck('same', [blankCard()]);
  const edits = [];
  document.onDidChange((e) => edits.push(e));
  document.setColumn(0, 1, 0);
  assert.equal(edits.length, 0);
});

test('insert and delete are undoable and structural', async () => {
  const { document } = await openDeck('cards', [blankCard()]);
  const edits = [];
  const changes = [];
  document.onDidChange((e) => edits.push(e));
  document.onDidChangeContent((c) => changes.push(c));

  const filled = blankCard();
  filled[0] = punchesFromCardCode('11-4-8');
  document.insertCard(1, filled);
  assert.equal(document.cardCount, 2);
  assert.equal(changes[0].structural, true);
  const afterInsert = document.structureRevision;

  document.deleteCard(0);
  assert.equal(document.cardCount, 1);
  assert.equal(document.card(0)[0], punchesFromCardCode('11-4-8'));
  assert.notEqual(document.structureRevision, afterInsert);

  edits[1].undo(); // Put the deleted card back.
  assert.equal(document.cardCount, 2);
  assert.equal(document.card(0)[0], 0);
  edits[0].undo(); // Remove the inserted card.
  assert.equal(document.cardCount, 1);
});

test('an inserted card is a copy, not an alias', async () => {
  const { document } = await openDeck('copy', [blankCard()]);
  const source = blankCard();
  document.insertCard(1, source);
  source[0] = 0xfff;
  assert.equal(document.card(1)[0], 0);
});

test('a save writes canon bytes that decode to the same deck', async () => {
  const card = blankCard();
  card[71] = punchesFromCardCode('0-4-8');
  const { uri, document } = await openDeck('save', [card, blankCard()]);
  document.togglePunch(1, 1, 3); // Row 1 of column 1 on card 2.
  await document.save(NO_CANCEL);

  const written = memory.get(uri.toString());
  assert.equal(written.length, 12 + 120 * 2);
  const back = decodeCanon(written);
  assert.equal(back.length, 2);
  assert.equal(back[0][71], punchesFromCardCode('0-4-8'));
  assert.equal(back[1][0], punchesFromCardCode('1'));
});

test('a revert reloads the file and drops the edits', async () => {
  const { document } = await openDeck('revert', [blankCard()]);
  document.togglePunch(0, 1, 0);
  assert.notEqual(document.card(0)[0], 0);
  await document.revert();
  assert.equal(document.card(0)[0], 0);
});

test('a backup writes a file that reopens', async () => {
  const { document } = await openDeck('backup', [blankCard()]);
  document.togglePunch(0, 3, 5);
  const destination = vscodeStub.Uri.file('/backup.ctdeck');
  const backup = await document.backup(destination, NO_CANCEL);
  const restored = await PunchcardDocument.create(
    vscodeStub.Uri.file('/backup-target.ctdeck'),
    backup.id,
  );
  assert.equal(restored.card(0)[2], document.card(0)[2]);
  await backup.delete();
  assert.equal(memory.has(destination.toString()), false);
});

test('an untitled document restores from its hot-exit backup', async () => {
  const { document } = await openDeck('untitled-backup', [blankCard()]);
  document.togglePunch(0, 7, 0); // Row 12 of column 7.
  const destination = vscodeStub.Uri.file('/untitled-backup.bak');
  const backup = await document.backup(destination, NO_CANCEL);

  const untitledUri = makeUri('untitled', '/Untitled-1.ctdeck');
  const restored = await PunchcardDocument.create(untitledUri, backup.id);
  assert.equal(restored.cardCount, 1);
  assert.equal(restored.card(0)[6], document.card(0)[6]);
});

test('the document rejects an out-of-range column, row or card', async () => {
  const { document } = await openDeck('range', [blankCard()]);
  assert.throws(() => document.setColumn(0, 0, 0), RangeError);
  assert.throws(() => document.setColumn(0, 81, 0), RangeError);
  assert.throws(() => document.setColumn(1, 1, 0), RangeError);
  assert.throws(() => document.togglePunch(0, 1, 12), RangeError);
  assert.throws(() => document.setColumn(0, 1, 0x1000), RangeError);
});

// --- provider and messages ------------------------------------------------

function fakePanel() {
  const posted = [];
  let receiver = () => {};
  let disposeListener = () => {};
  return {
    posted,
    send: (message) => receiver(message),
    dispose: () => disposeListener(),
    webview: {
      options: {},
      html: '',
      postMessage: (message) => {
        posted.push(message);
        return Promise.resolve(true);
      },
      onDidReceiveMessage: (callback) => {
        receiver = callback;
        return { dispose: () => {} };
      },
    },
    onDidDispose: (callback) => {
      disposeListener = callback;
      return { dispose: () => {} };
    },
  };
}

async function openEditor(name, cards) {
  const uri = vscodeStub.Uri.file(`/${name}.ctdeck`);
  memory.set(uri.toString(), deckOf(cards));
  const provider = new PunchcardEditorProvider({
    extensionUri: vscodeStub.Uri.file(path.join(__dirname, '..')),
    subscriptions: [],
  });
  const document = await provider.openCustomDocument(
    uri,
    { backupId: undefined },
    {},
  );
  const panel = fakePanel();
  await provider.resolveCustomEditor(document, panel, {});
  panel.send({ type: 'ready' });
  return { provider, document, panel };
}

function lastState(panel) {
  for (let i = panel.posted.length - 1; i >= 0; i--) {
    if (panel.posted[i].type === 'state') {
      return panel.posted[i];
    }
  }
  return null;
}

test('the webview html inlines the styles and the script under a nonce', async () => {
  const { panel } = await openEditor('html', [blankCard()]);
  const html = panel.webview.html;
  const nonce = /<style nonce="([A-Za-z0-9]{32})">/.exec(html);
  assert.notEqual(nonce, null);
  assert.ok(html.includes(`script-src 'nonce-${nonce[1]}'`));
  assert.ok(html.includes("default-src 'none'"));
  assert.ok(html.includes('acquireVsCodeApi'));
  assert.ok(html.includes('--cw'));
  assert.ok(!html.includes('http://'));
  assert.ok(!html.includes('https://'));
});

test('every element the webview script looks up exists in the html', async () => {
  const { panel } = await openEditor('ids', [blankCard()]);
  const html = panel.webview.html;
  const script = fs.readFileSync(
    path.join(__dirname, '..', 'media', 'punchcard.js'),
    'utf8',
  );
  const wanted = new Set();
  for (const m of script.matchAll(/\bel\('([A-Za-z]+)'\)/g)) {
    wanted.add(m[1]);
  }
  assert.ok(wanted.size >= 10, 'the script should look up several elements');
  for (const id of wanted) {
    assert.ok(html.includes(`id="${id}"`), `the html has no id="${id}"`);
  }
});

test('a ready message answers with the whole deck state', async () => {
  const card = blankCard();
  card[6] = punchesFromCardCode('12-1'); // 'A' in the name margin.
  const { panel } = await openEditor('ready', [card, blankCard()]);
  const state = lastState(panel);
  assert.equal(state.cardCount, 2);
  assert.equal(state.index, 0);
  assert.equal(state.previews.length, 2);
  assert.equal(state.previews[0], '      A');
  assert.equal(state.readout[6].ch, 'A');
  assert.equal(state.readout[6].code, '12-1');
  assert.equal(state.readout[6].octal, '21');
  assert.equal(state.columns.length, 80);
  assert.equal(state.fields.length, 4);
});

test('a toggle message punches and reports the new state', async () => {
  const { document, panel } = await openEditor('toggle', [blankCard()]);
  panel.send({ type: 'toggle', index: 0, column: 13, row: 0 });
  assert.equal(document.card(0)[12], 1 << 11);
  const state = lastState(panel);
  assert.equal(state.columns[12], 1 << 11);
  assert.equal(state.preview.index, 0);
});

test('typing a glyph punches its code and advances the cursor', async () => {
  const { document, panel } = await openEditor('type', [blankCard()]);
  panel.send({ type: 'typeGlyph', index: 0, column: 13, glyph: 'a' });
  assert.equal(document.card(0)[12], punchesFromCardCode('12-1'));
  assert.equal(lastState(panel).cursor, 14);

  panel.send({ type: 'typeGlyph', index: 0, column: 80, glyph: '$' });
  assert.equal(document.card(0)[79], punchesFromCardCode('11-3-8'));
  assert.equal(lastState(panel).cursor, 80);
});

test('typing a character outside the source set reports a status', async () => {
  const { document, panel } = await openEditor('reject', [blankCard()]);
  panel.send({ type: 'typeGlyph', index: 0, column: 13, glyph: '%' });
  assert.equal(document.card(0)[12], 0);
  const status = panel.posted[panel.posted.length - 1];
  assert.equal(status.type, 'status');
  assert.match(status.text, /not a Set H source character/);
});

test('typing a space punches a blank column', async () => {
  const { document, panel } = await openEditor('space', [blankCard()]);
  panel.send({ type: 'toggle', index: 0, column: 13, row: 3 });
  assert.notEqual(document.card(0)[12], 0);
  panel.send({ type: 'typeGlyph', index: 0, column: 13, glyph: ' ' });
  assert.equal(document.card(0)[12], 0);
});

test('insert, duplicate and delete move the selection with the card', async () => {
  const card = blankCard();
  card[0] = punchesFromCardCode('12-1');
  const { document, panel } = await openEditor('structure', [card]);

  panel.send({ type: 'duplicate', index: 0 });
  assert.equal(document.cardCount, 2);
  assert.equal(document.card(1)[0], punchesFromCardCode('12-1'));
  let state = lastState(panel);
  assert.equal(state.index, 1);
  assert.equal(state.previews.length, 2);

  panel.send({ type: 'insert', index: 1 });
  assert.equal(document.cardCount, 3);
  state = lastState(panel);
  assert.equal(state.index, 2);
  assert.equal(state.previews[2], '');

  panel.send({ type: 'delete', index: 2 });
  assert.equal(document.cardCount, 2);
  state = lastState(panel);
  assert.equal(state.index, 1);
});

test('deleting the last card leaves an empty deck the webview can show', async () => {
  const { document, panel } = await openEditor('empty', [blankCard()]);
  panel.send({ type: 'delete', index: 0 });
  assert.equal(document.cardCount, 0);
  const state = lastState(panel);
  assert.equal(state.cardCount, 0);
  assert.deepEqual(state.columns, []);
  assert.deepEqual(state.previews, []);

  panel.send({ type: 'insert', index: 0 });
  assert.equal(document.cardCount, 1);
  assert.equal(lastState(panel).index, 0);
});

test('an undone edit refreshes the webview', async () => {
  const { document, panel } = await openEditor('undo', [blankCard()]);
  const edits = [];
  document.onDidChange((e) => edits.push(e));
  panel.send({ type: 'toggle', index: 0, column: 1, row: 0 });
  assert.equal(lastState(panel).columns[0], 1 << 11);
  edits[0].undo();
  assert.equal(lastState(panel).columns[0], 0);
});

test('a select message changes the card the webview shows', async () => {
  const a = blankCard();
  a[0] = punchesFromCardCode('12-1');
  const b = blankCard();
  b[0] = punchesFromCardCode('11-2');
  const { panel } = await openEditor('select', [a, b]);
  panel.send({ type: 'select', index: 1 });
  const state = lastState(panel);
  assert.equal(state.index, 1);
  assert.equal(state.readout[0].ch, 'K');
  panel.send({ type: 'select', index: 99 });
  assert.equal(lastState(panel).index, 1);
});

test('a bad message reaches the status line instead of throwing', async () => {
  const { panel } = await openEditor('bad', [blankCard()]);
  panel.send({ type: 'toggle', index: 0, column: 999, row: 0 });
  const status = panel.posted[panel.posted.length - 1];
  assert.equal(status.type, 'status');
  assert.match(status.text, /column 999/);
});

test('closing every panel of a document releases its entry from the panel map', async () => {
  const { provider, document, panel } = await openEditor('leak', [
    blankCard(),
  ]);
  const panel2 = fakePanel();
  await provider.resolveCustomEditor(document, panel2, {});
  assert.equal(provider.panelsByDocument.get(document).size, 2);

  panel.dispose();
  assert.equal(provider.panelsByDocument.get(document).size, 1);

  panel2.dispose();
  assert.equal(provider.panelsByDocument.has(document), false);
});
