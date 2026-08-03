'use strict';

// Exercises the DocumentLinkProvider and HoverProvider from
// `src/manualLinks.ts` against a stub of the `vscode` module and a small
// fixture manual map — the same style of stub as `test/extension.test.js`.

const assert = require('node:assert/strict');
const Module = require('node:module');
const os = require('node:os');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

class Position {
  constructor(line, character) {
    this.line = line;
    this.character = character;
  }
}

class Range {
  constructor(start, end) {
    this.start = start;
    this.end = end;
  }
}

class MarkdownString {
  constructor() {
    this.value = '';
  }
  appendMarkdown(text) {
    this.value += text;
    return this;
  }
}

class DocumentLink {
  constructor(range, target) {
    this.range = range;
    this.target = target;
  }
}

class Hover {
  constructor(contents, range) {
    this.contents = contents;
    this.range = range;
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

let workspaceFolders;

const vscodeStub = {
  Position,
  Range,
  MarkdownString,
  DocumentLink,
  Hover,
  Uri: {
    file: (p) => makeUri('file', p),
  },
  workspace: {
    get workspaceFolders() {
      return workspaceFolders;
    },
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

const {
  ManualCitationLinkProvider,
  ManualCitationHoverProvider,
  findManualsRoot,
  loadManualMap,
} = require('../out/manualLinks.js');

const FIXTURE_MAP = {
  sections: {
    'J:02.03.02': {
      file: 'comtran-manuals/J28-6169/02-compiler.md',
      line: 125,
      slug: 'a-use-of-coding-forms',
      heading: 'A. Use of Coding Forms',
      pdfPage: 14,
      scan: 'comtran-manuals/J28-6169/images/page-014.png',
    },
    'F:42': {
      file: 'comtran-manuals/F28-8043/03-procedure-description.md',
      line: 67,
      slug: 'commands',
      heading: 'Commands',
      pdfPage: 42,
      // No scan: exercises the hover's "no scan link" path.
    },
  },
};

/** A fake TextDocument over one line of text, enough for offsetAt /
 * positionAt / getText. */
function fakeDocument(text) {
  return {
    getText: () => text,
    positionAt: (offset) => new Position(0, offset),
    offsetAt: (position) => position.character,
  };
}

let workspaceRoot;

test.before(() => {
  workspaceRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'manual-links-'));
  fs.mkdirSync(path.join(workspaceRoot, 'comtran-manuals'));
  workspaceFolders = [{ uri: makeUri('file', workspaceRoot) }];
});

test.after(() => {
  fs.rmSync(workspaceRoot, { recursive: true, force: true });
});

test('findManualsRoot finds the workspace folder holding comtran-manuals', () => {
  assert.equal(findManualsRoot(), workspaceRoot);
});

test('findManualsRoot returns undefined with no matching folder', () => {
  const saved = workspaceFolders;
  workspaceFolders = [{ uri: makeUri('file', os.tmpdir()) }];
  try {
    assert.equal(findManualsRoot(), undefined);
  } finally {
    workspaceFolders = saved;
  }
});

test('loadManualMap fails soft when manual-map.json is missing', () => {
  const missingContext = { extensionUri: makeUri('file', workspaceRoot) };
  assert.equal(loadManualMap(missingContext), undefined);
});

test('the link provider links a resolvable J citation to its marker line', () => {
  const provider = new ManualCitationLinkProvider(FIXTURE_MAP);
  const document = fakeDocument('See J 02.03.02 for the rule.');
  const [link] = provider.provideDocumentLinks(document);
  assert.ok(link);
  assert.equal(link.tooltip, 'A. Use of Coding Forms');
  assert.equal(
    link.target.fsPath,
    path.join(workspaceRoot, 'comtran-manuals/J28-6169/02-compiler.md'),
  );
  assert.equal(link.target.fragment, 'L125');
  assert.equal(link.range.start.character, 4);
  assert.equal(link.range.end.character, 14);
});

test('the link provider gives no link to a citation the map has no entry for', () => {
  const provider = new ManualCitationLinkProvider(FIXTURE_MAP);
  const document = fakeDocument('See J 90.06 for the deferral list.');
  assert.deepEqual(provider.provideDocumentLinks(document), []);
});

test('the link provider gives no links with no manual map loaded', () => {
  const provider = new ManualCitationLinkProvider(undefined);
  const document = fakeDocument('See J 02.03.02 for the rule.');
  assert.deepEqual(provider.provideDocumentLinks(document), []);
});

test('the link provider gives no links outside a comtran-manuals workspace', () => {
  const saved = workspaceFolders;
  workspaceFolders = undefined;
  try {
    const provider = new ManualCitationLinkProvider(FIXTURE_MAP);
    const document = fakeDocument('See J 02.03.02 for the rule.');
    assert.deepEqual(provider.provideDocumentLinks(document), []);
  } finally {
    workspaceFolders = saved;
  }
});

test('the hover provider shows the heading and an "open text" link', () => {
  const provider = new ManualCitationHoverProvider(FIXTURE_MAP);
  const document = fakeDocument('See J 02.03.02 for the rule.');
  const hover = provider.provideHover(document, new Position(0, 6));
  assert.ok(hover);
  assert.match(hover.contents.value, /A\. Use of Coding Forms/);
  assert.match(hover.contents.value, /\[open text\]/);
  assert.match(hover.contents.value, /\[open scan\]/);
});

test('the hover omits "open scan" when the map entry carries no scan', () => {
  const provider = new ManualCitationHoverProvider(FIXTURE_MAP);
  const document = fakeDocument('See F p. 42 for the table.');
  const hover = provider.provideHover(document, new Position(0, 6));
  assert.ok(hover);
  assert.match(hover.contents.value, /Commands/);
  assert.match(hover.contents.value, /\[open text\]/);
  assert.doesNotMatch(hover.contents.value, /\[open scan\]/);
});

test('the hover provider returns undefined outside any citation', () => {
  const provider = new ManualCitationHoverProvider(FIXTURE_MAP);
  const document = fakeDocument('See J 02.03.02 for the rule.');
  assert.equal(provider.provideHover(document, new Position(0, 0)), undefined);
});
