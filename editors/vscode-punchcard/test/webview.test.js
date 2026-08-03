'use strict';

// Executes media/punchcard.js in a real DOM (jsdom), against the extension's
// own generated webview HTML, so the client-side script carries actual
// regression protection: the cursor/keyboard model (onKey), rendering
// (render, fillRow, fillProcedureRow), zoom, and vscode.getState/setState
// persistence. Before this file, only test/editor.test.js's "every element
// the webview script looks up exists in the html" test touched this file,
// and it never executed the script.

const assert = require('node:assert/strict');
const fs = require('node:fs');
const Module = require('node:module');
const path = require('node:path');
const test = require('node:test');

const { JSDOM } = require('jsdom');

// --- a minimal vscode stub, just enough to render the webview's own HTML --

function makeUri(scheme, fsPath) {
  return {
    scheme,
    fsPath,
    path: fsPath,
    toString: () => `${scheme}://${fsPath}`,
  };
}

const vscodeStub = {
  EventEmitter: class {
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
  },
  Uri: {
    file: (p) => makeUri('file', p),
    joinPath: (uri, ...parts) =>
      makeUri(uri.scheme, path.join(uri.fsPath, ...parts)),
  },
  workspace: {
    fs: {
      readFile: async (uri) => new Uint8Array(fs.readFileSync(uri.fsPath)),
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

const { PunchcardEditorProvider } = require('../out/punchcardEditor.js');
const { blankCard } = require('../out/canonCodec.js');
const {
  MARKER_NONE,
  MARKER_SPECIAL,
  MARKER_UNATTESTED,
  readCard,
} = require('../out/cardView.js');
const {
  bcdFromGlyph,
  punchesFromBcd,
} = require('../out/charCode.js');
const {
  DATA_FIELDS,
  ENVIRONMENT_FIELDS,
  GENERIC_FIELDS,
  PROCEDURE_FIELDS,
} = require('../out/columns.js');

/** The webview's own generated HTML: real markup, real inlined CSS and JS. */
async function webviewHtml() {
  const provider = new PunchcardEditorProvider({
    extensionUri: vscodeStub.Uri.file(path.join(__dirname, '..')),
    subscriptions: [],
  });
  const panel = {
    webview: {
      options: {},
      html: '',
      postMessage: () => Promise.resolve(true),
      onDidReceiveMessage: () => ({ dispose: () => {} }),
    },
    onDidDispose: () => ({ dispose: () => {} }),
  };
  await provider.resolveCustomEditor({}, panel, {});
  return panel.webview.html;
}

/** Opens the webview HTML in a real DOM and runs its inline script. */
async function openWebview() {
  const html = await webviewHtml();
  const posted = [];
  const saved = { current: undefined };
  const api = {
    // structuredClone: the script runs in the jsdom window's own realm, so
    // its object literals have a different Object.prototype than ours;
    // clone into a same-realm plain object so assert.deepEqual can compare
    // structure instead of tripping over that.
    postMessage: (message) => {
      posted.push(structuredClone(message));
      return Promise.resolve(true);
    },
    getState: () => saved.current,
    setState: (state) => {
      saved.current = state;
    },
  };
  const dom = new JSDOM(html, {
    runScripts: 'dangerously',
    url: 'https://example.org/',
    beforeParse(window) {
      window.acquireVsCodeApi = () => api;
    },
  });
  return { dom, window: dom.window, document: dom.window.document, posted, saved };
}

/** Fires the webview's `window.addEventListener('message', ...)` handler. */
function postToWebview(window, data) {
  window.dispatchEvent(new window.MessageEvent('message', { data }));
}

/** A `type: 'state'` message shaped like `punchcardEditor.ts`'s `send`. */
function stateMessage(overrides) {
  const card = overrides.card ?? blankCard();
  return Object.assign(
    {
      type: 'state',
      cardCount: 1,
      index: 0,
      previews: [''],
      preview: null,
      columns: Array.from(card),
      readout: readCard(card),
      cursor: null,
      kinds: ['blank'],
      tables: {
        generic: GENERIC_FIELDS,
        data: DATA_FIELDS,
        environment: ENVIRONMENT_FIELDS,
        procedure: PROCEDURE_FIELDS,
      },
      fields: GENERIC_FIELDS,
      markers: {
        special: MARKER_SPECIAL,
        unattested: MARKER_UNATTESTED,
        none: MARKER_NONE,
      },
    },
    overrides,
  );
}

function punch(card, column, glyph) {
  card[column - 1] = punchesFromBcd(bcdFromGlyph(glyph));
}

test('the script builds the grid and reports ready on load', async () => {
  const { document, posted } = await openWebview();
  assert.equal(document.querySelectorAll('.cell').length, 12 * 80);
  assert.equal(document.querySelectorAll('.ic').length, 80);
  assert.deepEqual(posted, [{ type: 'ready' }]);
});

test('a state message punches the grid and the interpreted row', async () => {
  const { window, document } = await openWebview();
  const card = blankCard();
  punch(card, 1, '1');
  postToWebview(window, stateMessage({ card, cardCount: 1, previews: ['1'] }));

  const onCells = document.querySelectorAll('.cell.on');
  assert.equal(onCells.length, 1);
  assert.equal(onCells[0].dataset.c, '1');
  assert.equal(onCells[0].dataset.r, '3'); // row index of digit 1.
  assert.equal(document.querySelectorAll('.ic')[0].textContent, '1');
});

test('the deck-empty message hides the card and shows the empty notice', async () => {
  const { window, document } = await openWebview();
  postToWebview(
    window,
    stateMessage({ cardCount: 0, previews: [], columns: [], readout: [], kinds: [] }),
  );
  assert.equal(document.getElementById('card').classList.contains('hidden'), true);
  assert.equal(document.getElementById('empty').classList.contains('hidden'), false);
  assert.match(document.getElementById('status').textContent, /empty/);
});

test('arrow keys move the cursor and Enter posts a toggle at that cell', async () => {
  const { window, document, posted } = await openWebview();
  postToWebview(window, stateMessage({}));

  document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'ArrowRight' }));
  document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'ArrowDown' }));
  posted.length = 0;
  document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Enter' }));

  assert.equal(posted.length, 1);
  assert.deepEqual(posted[0], { type: 'toggle', index: 0, column: 2, row: 4 });
});

test('Home and End jump to column 1 and column 80', async () => {
  const { window, document } = await openWebview();
  postToWebview(window, stateMessage({}));

  document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'End' }));
  assert.equal(document.querySelectorAll('.ic.col-cur')[0].dataset.c, '80');

  document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Home' }));
  assert.equal(document.querySelectorAll('.ic.col-cur')[0].dataset.c, '1');
});

test('PageUp and PageDown post a select message', async () => {
  const { window, posted } = await openWebview();
  postToWebview(window, stateMessage({ cardCount: 3, index: 1, previews: ['', '', ''] }));

  posted.length = 0;
  window.document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'PageDown' }));
  assert.deepEqual(posted[0], { type: 'select', index: 2 });

  posted.length = 0;
  window.document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'PageUp' }));
  assert.deepEqual(posted[0], { type: 'select', index: 0 });
});

test('Backspace clears the column to the left and Delete clears the current one', async () => {
  const { window, posted } = await openWebview();
  postToWebview(window, stateMessage({}));

  window.document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'ArrowRight' }));
  posted.length = 0;
  window.document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Backspace' }));
  assert.deepEqual(posted[0], { type: 'setColumn', index: 0, column: 1, punches: 0 });

  posted.length = 0;
  window.document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Delete' }));
  assert.deepEqual(posted[0], { type: 'setColumn', index: 0, column: 1, punches: 0 });
});

test('type-to-punch mode turns a keystroke into a typeGlyph message', async () => {
  const { window, document, posted } = await openWebview();
  postToWebview(window, stateMessage({}));

  const typeModeBox = document.getElementById('typeMode');
  typeModeBox.checked = true;
  typeModeBox.dispatchEvent(new window.Event('change'));

  posted.length = 0;
  document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'a' }));
  assert.deepEqual(posted[0], { type: 'typeGlyph', index: 0, column: 1, glyph: 'a' });

  // Space still punches a blank column outside type mode's normal toggle...
  posted.length = 0;
  document.dispatchEvent(new window.KeyboardEvent('keydown', { key: ' ' }));
  assert.deepEqual(posted[0], { type: 'typeGlyph', index: 0, column: 1, glyph: ' ' });
});

test('space toggles the current cell when not in type mode', async () => {
  const { window, posted } = await openWebview();
  postToWebview(window, stateMessage({}));
  posted.length = 0;
  window.document.dispatchEvent(new window.KeyboardEvent('keydown', { key: ' ' }));
  assert.deepEqual(posted[0], { type: 'toggle', index: 0, column: 1, row: 3 });
});

test('clicking a grid cell moves the cursor there and toggles it', async () => {
  const { window, document, posted } = await openWebview();
  postToWebview(window, stateMessage({}));

  const cell = document.querySelector('.cell[data-c="5"][data-r="1"]');
  assert.ok(cell);
  posted.length = 0;
  cell.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  assert.deepEqual(posted[0], { type: 'toggle', index: 0, column: 5, row: 1 });
});

test('clicking a card-list row selects that card', async () => {
  const { window, document, posted } = await openWebview();
  postToWebview(
    window,
    stateMessage({ cardCount: 2, index: 0, previews: ['FIRST', 'SECOND'] }),
  );

  const rows = document.querySelectorAll('#cardList li');
  assert.equal(rows.length, 2);
  posted.length = 0;
  rows[1].dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  assert.deepEqual(posted[0], { type: 'select', index: 1 });
});

test('a data card in the card list colors its name field', async () => {
  const { window, document } = await openWebview();
  postToWebview(
    window,
    stateMessage({
      cardCount: 1,
      previews: ['      HOURS'],
      kinds: ['data'],
    }),
  );
  const row = document.querySelector('#cardList li .txt');
  assert.ok(row.querySelector('.f-name'));
  assert.equal(row.querySelector('.f-name').textContent, 'HOURS');
});

test('zoom buttons change the column width and persist it', async () => {
  const { window, document, saved } = await openWebview();
  postToWebview(window, stateMessage({}));

  const before = document.documentElement.style.getPropertyValue('--cw');
  document.getElementById('zoomIn').dispatchEvent(new window.MouseEvent('click'));
  const after = document.documentElement.style.getPropertyValue('--cw');
  assert.notEqual(after, before);
  assert.equal(saved.current.cw, parseInt(after, 10));
});

test('a status message flashes then reverts to the column status', async () => {
  const { window, document } = await openWebview();
  postToWebview(window, stateMessage({}));
  postToWebview(window, { type: 'status', text: "'%' is not a Set H source character" });
  assert.equal(
    document.getElementById('status').textContent,
    "'%' is not a Set H source character",
  );
  assert.equal(document.getElementById('status').classList.contains('warn'), true);
});
