'use strict';

// Exercises `activate()` against a stub of the `vscode` module: the
// `comtran.newDeck` command it registers, and the one-time notice that a
// `.deck` file is a generated mirror.

const assert = require('node:assert/strict');
const Module = require('node:module');
const path = require('node:path');
const test = require('node:test');

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

function makeUri(scheme, fsPath, fragment = '') {
  return {
    scheme,
    fsPath,
    path: fsPath,
    fragment,
    with: (change) => makeUri(scheme, fsPath, change.fragment ?? fragment),
    toString: () =>
      `${scheme}://${fsPath}${fragment === '' ? '' : `#${fragment}`}`,
  };
}

const memory = new Map();
/** @type {Map<string, (...args: unknown[]) => unknown>} */
const registeredCommands = new Map();
/** @type {Array<(document: { languageId: string }) => void>} */
const documentOpenListeners = [];
let savedDialogUri;
let executed = [];

const vscodeStub = {
  EventEmitter,
  Uri: {
    file: (p) => makeUri('file', p),
  },
  commands: {
    registerCommand: (id, handler) => {
      registeredCommands.set(id, handler);
      return { dispose: () => {} };
    },
    executeCommand: async (id, ...args) => {
      executed.push({ id, args });
    },
  },
  window: {
    registerCustomEditorProvider: () => ({ dispose: () => {} }),
    showSaveDialog: async () => savedDialogUri,
    showInformationMessage: async () => undefined,
  },
  workspace: {
    fs: {
      writeFile: async (uri, data) => {
        memory.set(uri.toString(), Uint8Array.from(data));
      },
    },
    onDidOpenTextDocument: (listener) => {
      documentOpenListeners.push(listener);
      return { dispose: () => {} };
    },
    workspaceFolders: undefined,
  },
  languages: {
    registerDocumentLinkProvider: () => ({ dispose: () => {} }),
    registerHoverProvider: () => ({ dispose: () => {} }),
  },
};

const load = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'vscode') {
    return vscodeStub;
  }
  return load.call(this, request, parent, isMain);
};

const { activate } = require('../out/extension.js');
const { decodeCanon } = require('../out/canonCodec.js');

function fakeContext() {
  return {
    subscriptions: [],
    extensionUri: vscodeStub.Uri.file(path.join(__dirname, '..')),
  };
}

function fireOpen(languageId) {
  for (const listener of documentOpenListeners) {
    listener({ languageId });
  }
}

test('activate registers the new-deck command', () => {
  activate(fakeContext());
  assert.ok(registeredCommands.has('comtran.newDeck'));
});

test('the new-deck command writes a valid one-card deck and opens it', async () => {
  activate(fakeContext());
  const target = vscodeStub.Uri.file('/new.ctdeck');
  savedDialogUri = target;
  executed = [];
  await registeredCommands.get('comtran.newDeck')();

  const written = memory.get(target.toString());
  assert.ok(written);
  const deck = decodeCanon(written);
  assert.equal(deck.length, 1);
  assert.equal(deck[0].every((c) => c === 0), true);

  assert.equal(executed.length, 1);
  assert.equal(executed[0].id, 'vscode.openWith');
  assert.equal(executed[0].args[0], target);
  assert.equal(executed[0].args[1], 'comtran.punchcard');
});

test('the new-deck command does nothing when the user cancels the dialog', async () => {
  activate(fakeContext());
  savedDialogUri = undefined;
  executed = [];
  await registeredCommands.get('comtran.newDeck')();
  assert.equal(executed.length, 0);
});

test('opening a .deck file shows the mirror notice once per session', () => {
  documentOpenListeners.length = 0;
  const messages = [];
  vscodeStub.window.showInformationMessage = async (text) => {
    messages.push(text);
    return undefined;
  };
  activate(fakeContext());

  fireOpen('plaintext');
  assert.equal(messages.length, 0);

  fireOpen('comtran-deck');
  assert.equal(messages.length, 1);
  assert.match(messages[0], /generated mirror/);

  fireOpen('comtran-deck');
  assert.equal(messages.length, 1, 'the notice does not repeat');
});
