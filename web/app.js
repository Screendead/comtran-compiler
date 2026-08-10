// The public website (roadmap W1).
//
// This file holds no compiler knowledge. It hands the typed text to the
// compiled compiler and prints what comes back, so a later milestone fills
// these panels with no change here. Everything it says about a stage is
// caption text, and every caption names where its claim comes from.

import { compile, instantiate, invoke } from './main.mjs';
import { SAMPLE } from './sample.js';

const CARD_COLUMNS = 80;

// One entry per --emit stage, in the order the compiler runs them. `kind`
// picks the evidence style: what a manual states, what we derived from the
// sources, and what nothing attests (docs/design/web-copy.md, rule C2).
const STAGES = {
  cards: {
    caption:
      'The program exactly as punched, one line to a card. Everything below ' +
      'is derived from these eighty columns, and nothing is added that is ' +
      'not here.',
    kind: 'manual',
    label: 'The manual says',
    evidence:
      'The compiler reads the body of a source card from columns 7 to 72, ' +
      'and it does not check the serial number in columns 1 to 6 ' +
      '(J 02.02.01; J 02.03.01).',
  },
  scan: {
    caption:
      'Cards read into statements. Each statement is given a number — the ' +
      'line, then the clause — and that number is the thread running ' +
      'through every stage after this one.',
    kind: 'chosen',
    label: 'Nobody knows, we chose',
    evidence:
      'No 1962 artifact shows a dump of this stage, so its shape is ours. ' +
      'The statement numbers inside it are the manual’s, in the form the ' +
      'listing prints.',
  },
  parse: {
    caption:
      'Statements resolved into the structures the manual describes: data ' +
      'items with their level, mode, justification and picture; procedure ' +
      'sentences with their verbs and operands.',
    kind: 'chosen',
    label: 'Nobody knows, we chose',
    evidence:
      'The manual describes the grammar and never a tree. This tree is a ' +
      'reconstruction, and it says so on its own first line.',
  },
  semantics: {
    caption:
      'Names bound to storage. Every item is given an address and a machine ' +
      'word, and constants are laid down in octal — base eight, three bits ' +
      'to a digit, so a 36-bit word prints as twelve digits.',
    kind: 'derived',
    label: 'We worked this out from',
    evidence:
      'The surviving listing prints the address of every name. The storage ' +
      'section here is checked row by row against the addresses printed on ' +
      'the 1962 page.',
  },
  listing: {
    caption:
      'What the compiler printed: 55 lines to a page, under a head line ' +
      'carrying date, time, account, identification and page number, at ' +
      'column positions measured off the page scan.',
    kind: 'manual',
    label: 'The manual says',
    evidence:
      'This is the one stage a printed 1962 page attests from end to end. ' +
      'The output here is compared against that page byte for byte, and the ' +
      'comparison is a test that must pass before any change is merged.',
  },
  code: {
    caption:
      'The assembled text: address, symbol, operation, octal word and ' +
      'control field. Today the compiler lays down the data — the constants ' +
      'and the space each record needs. It generates no procedure code yet.',
    kind: 'derived',
    label: 'We worked this out from',
    evidence:
      'The manual prints this program’s assembled text in full (J 90.05). ' +
      'That printed text is the target the code generator is measured ' +
      'against, and the distance between this panel and it is the work in ' +
      'progress.',
  },
};

// Styling keyed to this class keeps every no-JavaScript reader on the plain
// version of the page rather than a half-built one.
document.documentElement.classList.add('js');

const el = (id) => document.getElementById(id);
const source = el('source');
const gutter = el('gutter');
const ruler = el('ruler');
const rulerWrap = ruler.parentElement;
const out = el('out');
const panel = el('panel');
const caption = el('caption');
const evidence = el('evidence');
const evidenceLabel = el('evidence-label');
const evidenceText = el('evidence-text');
const refusal = el('refusal');
const verdict = el('verdict');
const panelFoot = el('panel-foot');
const deckSize = el('deck-size');
const where = el('where');
const tabs = [...document.querySelectorAll('[role="tab"]')];

let stage = 'listing';
let latest = null;
let ready = false;

// The card-column ruler, in the form a card-oriented editor has always
// printed it: a mark every five columns, the tens digit every ten.
ruler.textContent = Array.from({ length: CARD_COLUMNS }, (_, i) => {
  const column = i + 1;
  if (column % 10 === 0) return String((column / 10) % 10);
  return column % 5 === 0 ? '+' : '-';
}).join('');

function lineCount(text) {
  return text.length === 0 ? 1 : text.split('\n').length;
}

function drawGutter() {
  const lines = lineCount(source.value);
  const numbers = [];
  for (let i = 1; i <= lines; i++) numbers.push(String(i).padStart(4));
  gutter.textContent = numbers.join('\n');
  gutter.scrollTop = source.scrollTop;
  // The gutter numbers every line the cursor can reach. The count below it
  // is the number of cards those lines punch, which drops the blank line a
  // trailing return leaves — the same rule punchText applies.
  const cards = source.value.replace(/\s+$/, '').split('\n').length;
  const punched = source.value.trim() === '' ? 0 : cards;
  deckSize.textContent = `${punched} ${punched === 1 ? 'card' : 'cards'}`;
}

function drawCursor() {
  const before = source.value.slice(0, source.selectionStart);
  const newline = before.lastIndexOf('\n');
  const card = before.length === 0 ? 1 : before.split('\n').length;
  where.textContent = `Card ${card}, column ${before.length - newline}`;
}

function drawStage() {
  const meta = STAGES[stage];
  caption.textContent = meta.caption;
  evidence.dataset.kind = meta.kind;
  evidenceLabel.textContent = meta.label;
  evidenceText.textContent = meta.evidence;
  for (const tab of tabs) {
    tab.setAttribute('aria-selected', String(tab.dataset.stage === stage));
  }
  if (!latest) return;
  const text = latest.error ? '' : latest[stage];
  out.textContent = text;
  panel.scrollTop = 0;
  panelFoot.textContent = text
    ? `${lineCount(text) - 1} lines · ${text.length.toLocaleString('en-GB')} characters`
    : '';
}

function draw(result) {
  latest = result;
  refusal.hidden = !result.error;
  refusal.textContent = result.error ?? '';
  if (result.error) {
    verdict.textContent = 'Not compiled';
    verdict.dataset.state = 'bad';
  } else {
    const errors = result.diagnosticCount;
    verdict.textContent =
      errors === 0
        ? `${result.cardCount} cards · no errors`
        : `${result.cardCount} cards · ${errors} ` +
          `${errors === 1 ? 'diagnostic' : 'diagnostics'} · ` +
          `worst severity ${result.maxSeverity}`;
    verdict.dataset.state = errors === 0 ? 'good' : 'bad';
  }
  drawStage();
}

function run() {
  if (!ready) return;
  draw(JSON.parse(globalThis.comtranCompile(source.value)));
}

// The compiler takes tens of milliseconds on the sample, so typing can
// recompile without a wait; the button stays for anyone who wants one.
let pending = 0;
function runSoon() {
  clearTimeout(pending);
  pending = setTimeout(run, 250);
}

source.addEventListener('input', () => {
  drawGutter();
  drawCursor();
  runSoon();
});

for (const event of ['keyup', 'click', 'select']) {
  source.addEventListener(event, drawCursor);
}

source.addEventListener('scroll', () => {
  gutter.scrollTop = source.scrollTop;
  rulerWrap.scrollLeft = source.scrollLeft;
});

el('compile').addEventListener('click', run);

el('load').addEventListener('click', () => {
  source.value = SAMPLE;
  source.focus();
  source.setSelectionRange(0, 0);
  drawGutter();
  drawCursor();
  run();
});

el('clear').addEventListener('click', () => {
  source.value = '';
  source.focus();
  drawGutter();
  drawCursor();
  run();
});

for (const tab of tabs) {
  tab.addEventListener('click', () => {
    stage = tab.dataset.stage;
    drawStage();
  });
  tab.addEventListener('keydown', (event) => {
    const step = event.key === 'ArrowRight' ? 1 : event.key === 'ArrowLeft' ? -1 : 0;
    if (step === 0) return;
    event.preventDefault();
    const next = tabs[(tabs.indexOf(tab) + step + tabs.length) % tabs.length];
    stage = next.dataset.stage;
    drawStage();
    next.focus();
  });
}

// A gloss opens on tap as well as on hover, because a touch screen has no
// hover and this marker exists for the reader who stumbles on one word.
const glosses = [...document.querySelectorAll('.gloss')];
for (const gloss of glosses) {
  gloss.addEventListener('click', () => {
    const open = gloss.getAttribute('aria-expanded') === 'true';
    for (const other of glosses) other.setAttribute('aria-expanded', 'false');
    gloss.setAttribute('aria-expanded', String(!open));
  });
}

document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape') return;
  for (const gloss of glosses) gloss.setAttribute('aria-expanded', 'false');
});

document.addEventListener('click', (event) => {
  if (event.target.closest('.gloss-host')) return;
  for (const gloss of glosses) gloss.setAttribute('aria-expanded', 'false');
});

source.value = SAMPLE;
// Assigning to value leaves the caret at the end of the deck; card 1 is
// where a reader starts.
source.setSelectionRange(0, 0);
drawGutter();
drawCursor();
drawStage();
out.textContent = 'Loading the compiler…';

try {
  const bytes = await (await fetch('main.wasm')).arrayBuffer();
  invoke(await instantiate(await compile(bytes), {}));
  ready = true;
  el('build').textContent =
    `Compiler ${globalThis.comtranVersion} · WebAssembly · ` +
    `sample: 90.05 payroll`;
  run();
} catch (error) {
  out.textContent = '';
  refusal.hidden = false;
  refusal.textContent =
    'The compiler did not load. This page needs a browser with WebAssembly, ' +
    'and it needs to be served over http rather than opened from a file. ' +
    `The browser reported: ${error}`;
  verdict.textContent = 'Compiler not loaded';
  verdict.dataset.state = 'bad';
}
