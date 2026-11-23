'use strict';

// Executes media/punchcard.js in a real DOM (jsdom), against the extension's
// own generated webview HTML. A DOM costs a tenth of a second to open, so
// the rendering tests share one and the input model runs as one sequence on
// another; node:test runs a file's tests in order.

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

const rendered = openWebview();

// A status flash leaves a timer running; closing the window clears it, so
// the run does not wait it out.
test.after(async () => (await rendered).window.close());

test('the script builds the grid and reports ready on load', async () => {
  const { document, posted } = await rendered;
  assert.equal(document.querySelectorAll('.cell').length, 12 * 80);
  assert.equal(document.querySelectorAll('.ic').length, 80);
  assert.deepEqual(posted, [{ type: 'ready' }]);
});

test('a state message punches the grid and the interpreted row', async () => {
  const { window, document } = await rendered;
  const card = blankCard();
  punch(card, 1, '1');
  postToWebview(window, stateMessage({ card, cardCount: 1, previews: ['1'] }));

  const onCells = document.querySelectorAll('.cell.on');
  assert.equal(onCells.length, 1);
  assert.equal(onCells[0].dataset.c, '1');
  assert.equal(onCells[0].dataset.r, '3'); // row index of digit 1.
  assert.equal(document.querySelectorAll('.ic')[0].textContent, '1');
});

test('a data card in the card list colors its name field', async () => {
  const { window, document } = await rendered;
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

test('the deck-empty message hides the card and shows the empty notice', async () => {
  const { window, document } = await rendered;
  postToWebview(
    window,
    stateMessage({ cardCount: 0, previews: [], columns: [], readout: [], kinds: [] }),
  );
  assert.equal(document.getElementById('card').classList.contains('hidden'), true);
  assert.equal(document.getElementById('empty').classList.contains('hidden'), false);
  assert.match(document.getElementById('status').textContent, /empty/);
});

test('a status message flashes as a warning', async () => {
  const { window, document } = await rendered;
  postToWebview(window, stateMessage({}));
  postToWebview(window, { type: 'status', text: "'%' is not a Set H source character" });
  assert.equal(
    document.getElementById('status').textContent,
    "'%' is not a Set H source character",
  );
  assert.equal(document.getElementById('status').classList.contains('warn'), true);
});

test('zoom buttons change the column width and persist it', async () => {
  const { window, document, saved } = await rendered;
  postToWebview(window, stateMessage({}));

  const before = document.documentElement.style.getPropertyValue('--cw');
  document.getElementById('zoomIn').dispatchEvent(new window.MouseEvent('click'));
  const after = document.documentElement.style.getPropertyValue('--cw');
  assert.notEqual(after, before);
  assert.equal(saved.current.cw, parseInt(after, 10));
});

test('the keyboard and the mouse move the cursor and post each edit', async () => {
  const { window, document, posted } = await openWebview();
  postToWebview(window, stateMessage({ cardCount: 3, index: 1, previews: ['', '', ''] }));
  const key = (k) => () =>
    document.dispatchEvent(new window.KeyboardEvent('keydown', { key: k }));
  const click = (element) => () =>
    element.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  const cursorColumn = () => document.querySelectorAll('.ic.col-cur')[0].dataset.c;

  // The cursor opens on column 1, row index 3 (digit 1).
  for (const [step, actions, message] of [
    ['space outside type mode', [key(' ')], { type: 'toggle', index: 1, column: 1, row: 3 }],
    [
      'arrows, then Enter',
      [key('ArrowRight'), key('ArrowDown'), key('Enter')],
      { type: 'toggle', index: 1, column: 2, row: 4 },
    ],
    [
      'Backspace clears the column to the left',
      [key('Backspace')],
      { type: 'setColumn', index: 1, column: 1, punches: 0 },
    ],
    [
      'Delete clears the current column',
      [key('Delete')],
      { type: 'setColumn', index: 1, column: 1, punches: 0 },
    ],
    ['PageDown', [key('PageDown')], { type: 'select', index: 2 }],
    ['PageUp', [key('PageUp')], { type: 'select', index: 0 }],
    [
      'a click on a grid cell',
      [click(document.querySelector('.cell[data-c="5"][data-r="1"]'))],
      { type: 'toggle', index: 1, column: 5, row: 1 },
    ],
    [
      'a click on a card-list row',
      [click(document.querySelectorAll('#cardList li')[2])],
      { type: 'select', index: 2 },
    ],
  ]) {
    actions.forEach((act) => act());
    assert.deepEqual(posted.at(-1), message, step);
  }

  key('End')();
  assert.equal(cursorColumn(), '80');
  key('Home')();
  assert.equal(cursorColumn(), '1');

  const typeModeBox = document.getElementById('typeMode');
  typeModeBox.checked = true;
  typeModeBox.dispatchEvent(new window.Event('change'));
  for (const glyph of ['a', ' ']) {
    key(glyph)();
    assert.deepEqual(posted.at(-1), { type: 'typeGlyph', index: 1, column: 1, glyph });
  }
  window.close();
});
