'use strict';

// Exercises the pure citation logic in `src/manualCitations.ts` directly:
// no `vscode` stub, because the module under test never imports `vscode`.

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  findCitations,
  findCitationAt,
  resolveCitation,
} = require('../out/manualCitations.js');

/** A small fixture map: enough entries to exercise both citation forms,
 * plus the gaps that must resolve to `null`. */
const FIXTURE_MAP = {
  sections: {
    'J:02.03': {
      file: 'comtran-manuals/J28-6169/02-compiler.md',
      line: 108,
      slug: '0203-general-programming-considerations',
      heading: '02.03 General Programming Considerations',
      pdfPage: 13,
      scan: 'comtran-manuals/J28-6169/images/page-013.png',
    },
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
      scan: 'comtran-manuals/F28-8043/images/page-042.png',
    },
    'F:50': {
      file: 'comtran-manuals/F28-8043/03-procedure-description.md',
      line: 608,
      slug: 'the-set-command',
      heading: 'The SET Command',
      pdfPage: 51,
      scan: 'comtran-manuals/F28-8043/images/page-051.png',
    },
  },
};

test('finds a two-component J code', () => {
  const [citation] = findCitations('See J 02.03 for the rule.');
  assert.equal(citation.key, 'J:02.03');
  assert.equal(citation.text, 'J 02.03');
});

test('finds a three-component J code', () => {
  const [citation] = findCitations('See J 02.03.02 for the rule.');
  assert.equal(citation.key, 'J:02.03.02');
  assert.equal(citation.text, 'J 02.03.02');
});

test('a lettered subsection does not match as a prefix of itself', () => {
  // "J 02.07.F" is not a canonical numeric code; it must not be read as
  // "J 02.07" with the ".F" left dangling.
  assert.deepEqual(findCitations('See J 02.07.F for the block.'), []);
});

test('finds an F single page', () => {
  const [citation] = findCitations('See F p. 42 for the table.');
  assert.equal(citation.key, 'F:42');
  assert.equal(citation.text, 'F p. 42');
  assert.deepEqual(citation.pages, { from: 42, to: 42 });
});

test('finds an F en-dash page range, keyed on the first page', () => {
  const [citation] = findCitations('See F pp. 50–51 for the SET command.');
  assert.equal(citation.key, 'F:50');
  assert.equal(citation.text, 'F pp. 50–51');
  assert.deepEqual(citation.pages, { from: 50, to: 51 });
});

test('finds an F hyphen page range, keyed on the first page', () => {
  const [citation] = findCitations('See F pp. 50-51 for the SET command.');
  assert.equal(citation.key, 'F:50');
  assert.deepEqual(citation.pages, { from: 50, to: 51 });
});

test('finds every citation in a line with more than one', () => {
  const citations = findCitations('J 02.03 and F p. 42 both apply.');
  assert.equal(citations.length, 2);
  assert.equal(citations[0].key, 'J:02.03');
  assert.equal(citations[1].key, 'F:42');
});

test('resolves a known J code against the map', () => {
  const entry = resolveCitation(FIXTURE_MAP, 'J:02.03.02');
  assert.equal(entry.heading, 'A. Use of Coding Forms');
});

test('resolves a known F page against the map', () => {
  const entry = resolveCitation(FIXTURE_MAP, 'F:42');
  assert.equal(entry.heading, 'Commands');
});

test('an unknown J code resolves to null', () => {
  assert.equal(resolveCitation(FIXTURE_MAP, 'J:90.06'), null);
});

test('an unknown F page resolves to null', () => {
  assert.equal(resolveCitation(FIXTURE_MAP, 'F:999'), null);
});

test('findCitationAt finds the citation covering an offset', () => {
  const text = 'See J 02.03.02 for the rule.';
  const offset = text.indexOf('02.03.02') + 2;
  const citation = findCitationAt(text, offset);
  assert.equal(citation.key, 'J:02.03.02');
});

test('findCitationAt returns null outside any citation', () => {
  const text = 'See J 02.03.02 for the rule.';
  assert.equal(findCitationAt(text, 0), null);
});
