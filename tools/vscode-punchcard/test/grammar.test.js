'use strict';

// The generated `.deck` grammar: the committed file must match the builder,
// and the column-anchored regexes must slice mirror lines at the shared
// field boundaries.

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const { buildGrammar } = require('../out/grammar.js');
const { configurationDefaults } = require('../out/columns.js');

const COMMITTED = path.join(
  __dirname,
  '..',
  'syntaxes',
  'comtran-deck.tmLanguage.json',
);

const PACKAGE_JSON = path.join(__dirname, '..', 'package.json');

const grammar = buildGrammar();
const repo = grammar.repository;

// Places `text` at 1-based card `column` on one mirror line.
function lineWith(parts) {
  let line = '';
  for (const [column, text] of parts) {
    line = line.padEnd(column - 1) + text;
  }
  return line;
}

test('the committed grammar file matches the builder', () => {
  const committed = JSON.parse(fs.readFileSync(COMMITTED, 'utf8'));
  assert.deepEqual(committed, grammar, 'run: npm run grammar');
});

test('the committed configurationDefaults match the column tables', () => {
  const pkg = JSON.parse(fs.readFileSync(PACKAGE_JSON, 'utf8'));
  assert.deepEqual(
    pkg.contributes.configurationDefaults,
    configurationDefaults(),
    'run: npm run grammar',
  );
});

test('the data card rule slices at the shared field boundaries', () => {
  const rule = repo['data-division'].patterns[1];
  const line = lineWith([
    [8, 'HOURS'],
    [24, '2'],
    [36, 'IR'],
    [38, '9(4)V9'],
  ]);
  const m = line.match(new RegExp(rule.match));
  assert.ok(m);
  assert.equal(m[1], '      '); // serial 1-6
  assert.equal(m[2].trim(), 'HOURS'); // name 7-22
  assert.equal(m[3].trim(), '2'); // level 23-24
  assert.equal(m[4].trim(), ''); // type 25-30
  assert.equal(m[5].trim(), ''); // quantity 31-35
  assert.equal(m[6], 'I'); // mode 36
  assert.equal(m[7], 'R'); // justify 37
  assert.equal(m[8], '9(4)V9'); // description 38-71
  assert.equal(m[9] ?? '', ''); // no continuation
});

test('the data card rule catches the continuation column', () => {
  const rule = repo['data-division'].patterns[1];
  const line = lineWith([
    [11, 'EMPLOYEE.NUM'],
    [24, '3'],
    [72, 'X'],
  ]);
  assert.equal(line.length, 72);
  const m = line.match(new RegExp(rule.match));
  assert.ok(m);
  assert.equal(m[2].trim(), 'EMPLOYEE.NUM');
  assert.equal(m[9], 'X'); // continuation flag, column 72
});

test('the environment card rule slices name, type and options', () => {
  const rule = repo['environment-division'].patterns[1];
  const line = lineWith([
    [7, 'INPUTMASTER'],
    [25, 'FILE'],
    [31, 'INPUT,BINARY,TAPE,MASTER,BLOCKSIZE 300'],
  ]);
  const m = line.match(new RegExp(rule.match));
  assert.ok(m);
  assert.equal(m[2].trim(), 'INPUTMASTER'); // name 7-22
  assert.equal(m[3].trim(), 'FILE'); // type field 23-30
  assert.ok(m[4].startsWith('INPUT,BINARY')); // options 31-71
});

test('the procedure label rule takes the leading margin word', () => {
  const rule = repo['procedure-division'].patterns[1];
  const m = lineWith([[7, 'START'], [18, 'OPEN ALL FILES.']]).match(
    new RegExp(rule.match),
  );
  assert.ok(m);
  assert.equal(m[2], 'START');
  const unlabeled = lineWith([[13, 'MOVE BLANKS.']]).match(
    new RegExp(rule.match),
  );
  assert.equal(unlabeled, null);
});

test('the terminator rule needs the period-blank and takes commentary', () => {
  const terminator = repo['procedure-division'].patterns
    .map((p) => p.match)
    .find((m) => typeof m === 'string' && m.includes('\\.'));
  const re = new RegExp(terminator);
  const m = 'STOP RUN. END OF JOB'.match(re);
  assert.ok(m);
  assert.equal(m[1], '.');
  assert.equal(m[2], 'END OF JOB');
  assert.equal('MOVE 1.5 TO X'.match(re), null); // decimal point, no blank
  const bare = 'GO TO START.'.match(re);
  assert.equal(bare[1], '.');
  assert.equal(bare[2], undefined);
});

test('the punch line rule matches deck-format §3.2 lines', () => {
  const re = new RegExp(repo['punch-line'].match);
  assert.ok(re.test('! 1:12-11-0-1-2-3-4-5-6-7-8-9 72:9'));
  assert.ok(re.test('! 40:12-5-8'));
  assert.equal(re.test('!1:12'), false); // missing field separator
  assert.equal(re.test('      *DATA'), false);
});

test('division regions open on exact header lines only', () => {
  const begin = new RegExp(repo['data-division'].begin);
  assert.ok(begin.test('      *DATA'));
  assert.equal(begin.test('       *DATA'), false); // column 8
  assert.equal(begin.test('      *DATA EXTRA'), false);
  const end = new RegExp(repo['data-division'].end);
  assert.ok(end.test('      *ENVIRONMENT'));
  assert.ok(end.test('      *FINISH'));
  assert.equal(end.test('      INPUTMASTER       FILE'), false);
});
