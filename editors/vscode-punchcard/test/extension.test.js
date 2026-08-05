'use strict';

// Exercises `activate()` against a stub of the `vscode` module: the
// `comtran.newDeck` command it registers, the one-time notice on opening a
// `.ct` mirror, and the save sync that keeps a deck and its mirror fresh
// together (`node:child_process` is stubbed — CI has no Dart SDK).

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
/** @type {Array<(document: object) => void>} */
const documentSaveListeners = [];
let registeredProvider;
let savedDialogUri;
let executed = [];
let warnings = [];
let errors = [];

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
    registerCustomEditorProvider: (_viewType, provider) => {
      registeredProvider = provider;
      return { dispose: () => {} };
    },
    showSaveDialog: async () => savedDialogUri,
    showInformationMessage: async () => undefined,
    showWarningMessage: async (text) => {
      warnings.push(text);
      return undefined;
    },
    showErrorMessage: async (text) => {
      errors.push(text);
      return undefined;
    },
    tabGroups: { all: [] },
  },
  workspace: {
    fs: {
      writeFile: async (uri, data) => {
        memory.set(uri.toString(), Uint8Array.from(data));
      },
      readFile: async (uri) => memory.get(uri.toString()) ?? Uint8Array.of(),
    },
    onDidOpenTextDocument: (listener) => {
      documentOpenListeners.push(listener);
      return { dispose: () => {} };
    },
    onDidSaveTextDocument: (listener) => {
      documentSaveListeners.push(listener);
      return { dispose: () => {} };
    },
    textDocuments: [],
    workspaceFolders: undefined,
  },
  languages: {
    registerDocumentLinkProvider: () => ({ dispose: () => {} }),
    registerHoverProvider: () => ({ dispose: () => {} }),
  },
};

let execCalls = [];
let execResult = { error: null, stdout: '', stderr: '' };
// In manual mode a run stays pending until the test fires its callback,
// so a test can hold the pair busy or edit state mid-run.
let execMode = 'auto';
let pendingExecs = [];

const load = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'vscode') {
    return vscodeStub;
  }
  if (request === 'node:child_process') {
    return {
      execFile: (command, args, options, callback) => {
        execCalls.push({ command, args, options });
        if (execMode === 'manual') {
          pendingExecs.push(callback);
          return;
        }
        process.nextTick(() =>
          callback(execResult.error, execResult.stdout, execResult.stderr),
        );
      },
    };
  }
  return load.call(this, request, parent, isMain);
};

const { activate } = require('../out/extension.js');
const { blankCard, decodeCanon, encodeCanon } = require('../out/canonCodec.js');

// A pair inside the real repository, so the repo-root walk finds the
// pubspec.yaml. The files never exist; every read and write is stubbed.
const repoRoot = path.resolve(__dirname, '..', '..', '..');
const mirrorPath = path.join(__dirname, 'fixtures', 'sample.ct');
const canonPath = path.join(__dirname, 'fixtures', 'sample.ctd');

function fakeContext() {
  return {
    subscriptions: [],
    extensionUri: vscodeStub.Uri.file(path.join(__dirname, '..')),
  };
}

function freshActivate() {
  documentOpenListeners.length = 0;
  documentSaveListeners.length = 0;
  executed = [];
  warnings = [];
  errors = [];
  execCalls = [];
  execResult = { error: null, stdout: '', stderr: '' };
  execMode = 'auto';
  pendingExecs = [];
  vscodeStub.window.tabGroups.all = [];
  vscodeStub.workspace.textDocuments = [];
  activate(fakeContext());
}

function fireOpen(languageId) {
  for (const listener of documentOpenListeners) {
    listener({ languageId });
  }
}

function fireSave(document) {
  for (const listener of documentSaveListeners) {
    listener(document);
  }
}

async function flush() {
  await new Promise((resolve) => setImmediate(resolve));
  await new Promise((resolve) => setImmediate(resolve));
}

test('activate registers the new-deck command', () => {
  freshActivate();
  assert.ok(registeredCommands.has('comtran.newDeck'));
});

test('the new-deck command writes a valid one-card deck and opens it', async () => {
  freshActivate();
  const target = vscodeStub.Uri.file(path.join(__dirname, 'fixtures', 'new.ctd'));
  savedDialogUri = target;
  await registeredCommands.get('comtran.newDeck')();
  await flush();

  const written = memory.get(target.toString());
  assert.ok(written);
  const deck = decodeCanon(written);
  assert.equal(deck.length, 1);
  assert.equal(deck[0].every((c) => c === 0), true);

  assert.equal(executed.length, 1);
  assert.equal(executed[0].id, 'vscode.openWith');
  assert.equal(executed[0].args[0], target);
  assert.equal(executed[0].args[1], 'comtran.punchcard');

  assert.equal(execCalls.length, 1, 'the new deck gets its mirror');
  assert.deepEqual(execCalls[0].args.slice(0, 3), [
    'run',
    'comtran:deckconv',
    'regen',
  ]);
});

test('the new-deck command does nothing when the user cancels the dialog', async () => {
  freshActivate();
  savedDialogUri = undefined;
  await registeredCommands.get('comtran.newDeck')();
  assert.equal(executed.length, 0);
  assert.equal(execCalls.length, 0);
});

test('opening a .ct file shows the save-sync notice once per session', () => {
  freshActivate();
  const messages = [];
  vscodeStub.window.showInformationMessage = async (text) => {
    messages.push(text);
    return undefined;
  };

  fireOpen('plaintext');
  assert.equal(messages.length, 0);

  fireOpen('comtran-deck');
  assert.equal(messages.length, 1);
  assert.match(messages[0], /generated mirror/);
  assert.match(messages[0], /rewrites the deck/);

  fireOpen('comtran-deck');
  assert.equal(messages.length, 1, 'the notice does not repeat');
});

test('saving a deck regenerates its mirror from the repository root', async () => {
  freshActivate();
  const uri = vscodeStub.Uri.file(canonPath);
  await registeredProvider.saveCustomDocument(
    { uri, save: async () => true },
    { isCancellationRequested: false },
  );
  await flush();
  assert.equal(execCalls.length, 1);
  assert.deepEqual(execCalls[0].args.slice(2), ['regen', canonPath]);
  assert.equal(execCalls[0].options.cwd, repoRoot);
  assert.deepEqual(warnings, []);
  assert.deepEqual(errors, []);
});

test('a deck save warns when the open mirror buffer is dirty', async () => {
  freshActivate();
  vscodeStub.workspace.textDocuments = [
    { uri: makeUri('file', mirrorPath), isDirty: true },
  ];
  await registeredProvider.saveCustomDocument(
    { uri: vscodeStub.Uri.file(canonPath), save: async () => true },
    { isCancellationRequested: false },
  );
  await flush();
  assert.equal(execCalls.length, 1, 'the canon is authoritative: regen runs');
  assert.equal(warnings.length, 1);
  assert.match(warnings[0], /now stale/);
});

test('a failed regen surfaces the deckconv stderr', async () => {
  freshActivate();
  execResult = { error: new Error('exit 1'), stdout: '', stderr: 'error: boom' };
  await registeredProvider.saveCustomDocument(
    { uri: vscodeStub.Uri.file(canonPath), save: async () => true },
    { isCancellationRequested: false },
  );
  await flush();
  assert.equal(errors.length, 1);
  assert.match(errors[0], /regen failed: error: boom/);
});

test('saving a mirror rewrites the deck through to-canon', async () => {
  freshActivate();
  fireSave({
    languageId: 'comtran-deck',
    uri: makeUri('file', mirrorPath),
  });
  await flush();
  assert.equal(execCalls.length, 1);
  assert.deepEqual(execCalls[0].args.slice(2), [
    'to-canon',
    mirrorPath,
    canonPath,
  ]);
  assert.deepEqual(errors, []);
});

test('a save of another language or scheme runs nothing', async () => {
  freshActivate();
  fireSave({ languageId: 'plaintext', uri: makeUri('file', mirrorPath) });
  fireSave({ languageId: 'comtran-deck', uri: makeUri('untitled', mirrorPath) });
  await flush();
  assert.equal(execCalls.length, 0);
});

test('a failed to-canon surfaces the stderr, which names the card', async () => {
  freshActivate();
  execResult = {
    error: new Error('exit 1'),
    stdout: '',
    stderr: 'error: card 2 is not in normal form (re-rendering gives "A")',
  };
  fireSave({ languageId: 'comtran-deck', uri: makeUri('file', mirrorPath) });
  await flush();
  assert.equal(errors.length, 1);
  assert.match(errors[0], /to-canon failed: .*card 2/);
});

test('a mirror save is skipped while the deck has unsaved punch edits', async () => {
  freshActivate();
  vscodeStub.window.tabGroups.all = [
    {
      tabs: [
        {
          isDirty: true,
          input: {
            viewType: 'comtran.punchcard',
            uri: makeUri('file', canonPath),
          },
        },
      ],
    },
  ];
  fireSave({ languageId: 'comtran-deck', uri: makeUri('file', mirrorPath) });
  await flush();
  assert.equal(execCalls.length, 0);
  assert.equal(warnings.length, 1);
  assert.match(warnings[0], /unsaved punch edits/);
});

test('a successful mirror save reloads the open punchcard editor', async () => {
  freshActivate();
  const canonUri = vscodeStub.Uri.file(canonPath);
  const document = await registeredProvider.openCustomDocument(
    canonUri,
    {},
    { isCancellationRequested: false },
  );
  let reloads = 0;
  document.onDidChangeContent(() => reloads++);
  fireSave({ languageId: 'comtran-deck', uri: makeUri('file', mirrorPath) });
  await flush();
  assert.equal(reloads, 1);
});

test('a mirror save during a deck save is skipped: punch edits win', async () => {
  freshActivate();
  execMode = 'manual';
  await registeredProvider.saveCustomDocument(
    { uri: vscodeStub.Uri.file(canonPath), save: async () => true },
    { isCancellationRequested: false },
  );
  await flush();
  fireSave({ languageId: 'comtran-deck', uri: makeUri('file', mirrorPath) });
  await flush();
  assert.equal(execCalls.length, 1, 'only the regen ran');
  assert.deepEqual(execCalls[0].args.slice(2), ['regen', canonPath]);
  assert.equal(warnings.length, 1);
  assert.match(warnings[0], /not applied/);
  pendingExecs.shift()(null, '', '');
  await flush();
});

test('punch edits made while to-canon runs are kept, not reverted', async () => {
  freshActivate();
  const canonUri = vscodeStub.Uri.file(canonPath);
  const document = await registeredProvider.openCustomDocument(
    canonUri,
    {},
    { isCancellationRequested: false },
  );
  let reloads = 0;
  document.onDidChangeContent(() => reloads++);
  execMode = 'manual';
  fireSave({ languageId: 'comtran-deck', uri: makeUri('file', mirrorPath) });
  await flush();
  vscodeStub.window.tabGroups.all = [
    {
      tabs: [
        {
          isDirty: true,
          input: {
            viewType: 'comtran.punchcard',
            uri: makeUri('file', canonPath),
          },
        },
      ],
    },
  ];
  pendingExecs.shift()(null, '', '');
  await flush();
  assert.equal(reloads, 0);
  assert.equal(warnings.length, 1);
  assert.match(warnings[0], /gained punch edits/);
});

test('an undo or redo from before a reload does not replay', async () => {
  freshActivate();
  const canonUri = vscodeStub.Uri.file(canonPath);
  memory.set(canonUri.toString(), encodeCanon([blankCard()]));
  const document = await registeredProvider.openCustomDocument(
    canonUri,
    {},
    { isCancellationRequested: false },
  );
  const edits = [];
  registeredProvider.onDidChangeCustomDocument((event) => edits.push(event));
  document.setColumn(0, 1, 7);
  assert.equal(document.card(0)[0], 7);
  await document.revert();
  assert.equal(document.card(0)[0], 0);
  edits[0].redo();
  assert.equal(document.card(0)[0], 0, 'a stale redo does not replay');
  edits[0].undo();
  assert.equal(document.card(0)[0], 0, 'a stale undo does not replay');
  memory.delete(canonUri.toString());
});
