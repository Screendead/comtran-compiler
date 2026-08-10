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
      'Cards read into statements. Each statement is given a number: the ' +
      'line, then the clause. That number is the thread running through ' +
      'every stage after this one.',
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
      'word, and constants are laid down in octal: base eight, three bits ' +
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
      'control field. Today the compiler lays down the data: the constants ' +
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
const card = el('card');
const cardNo = el('card-no');
const compileButton = el('compile');
const linkNote = el('link-note');
const whinges = el('whinges');
const whingeCount = el('whinge-count');
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
  // trailing return leaves. That is the same rule punchText applies.
  const cards = source.value.replace(/\s+$/, '').split('\n').length;
  const punched = source.value.trim() === '' ? 0 : cards;
  deckSize.textContent = `${punched} ${punched === 1 ? 'card' : 'cards'}`;
}

// The row labels down the left edge of a card, in the order the punch
// returns them. The site prints what it is handed and works out no punch
// code of its own.
const ROW_LABELS = ['12', '11', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

let drawn = null;
let cardNumber = 1;
let at = { row: 0, column: 7 };

const cardAt = (number) => source.value.split('\n')[number - 1] ?? '';

function drawCursor() {
  const before = source.value.slice(0, source.selectionStart);
  const newline = before.lastIndexOf('\n');
  cardNumber = before.length === 0 ? 1 : before.split('\n').length;
  const column = Math.min(before.length - newline, CARD_COLUMNS);
  where.textContent = `Card ${cardNumber}, column ${column}`;
  // The card follows the caret, so the column being typed is the column
  // lit on the card.
  at = { row: at.row, column };
  drawCard();
}

// Draws the card the caret sits on. Rebuilding 960 positions on every
// keystroke is wasted work, so the card is rebuilt only when its number or
// its text changes; moving the lit position never rebuilds it.
function drawCard() {
  if (!ready) return;
  const line = cardAt(cardNumber);
  const key = `${cardNumber}\0${line}`;
  if (key === drawn) {
    markActive();
    return;
  }
  drawn = key;

  const total = source.value.replace(/\s+$/, '').split('\n').length;
  cardNo.textContent =
    source.value.trim() === ''
      ? 'No cards'
      : `Card ${cardNumber} of ${total} · IBM 5081`;

  const punched = globalThis.comtranPunch(line);
  if (punched === null || punched === undefined) {
    card.replaceChildren();
    card.setAttribute(
      'aria-label',
      'This line is not a card the punch could cut.',
    );
    return;
  }
  const { rows, glyphs } = JSON.parse(punched);
  card.setAttribute('aria-label', `Card ${cardNumber}: ${glyphs.trimEnd()}`);

  card.replaceChildren(
    cardRow(null, [...glyphs].map((glyph) => cell('g', glyph))),
    ...rows.map((row, r) =>
      cardRow(
        ROW_LABELS[r],
        [...row].map((position, i) => {
          // Rows 12 and 11 carry no printed digit; the digit rows print
          // theirs faintly, the way a blank card comes out of the box.
          const spot = cell('p', r < 2 ? '' : ROW_LABELS[r]);
          spot.id = `p-${r}-${i + 1}`;
          spot.dataset.r = r;
          spot.dataset.c = i + 1;
          if (position === '#') spot.classList.add('on');
          spot.setAttribute(
            'aria-label',
            `Row ${ROW_LABELS[r]}, column ${i + 1}` +
              (position === '#' ? ', punched' : ''),
          );
          return spot;
        }),
      ),
    ),
  );
  markActive();
}

function cell(className, text) {
  const span = document.createElement('span');
  span.className = className;
  span.setAttribute('role', 'gridcell');
  span.textContent = text;
  return span;
}

function cardRow(label, cells) {
  const row = document.createElement('div');
  row.className = 'crow';
  row.setAttribute('role', 'row');
  const rl = document.createElement('span');
  rl.className = 'rl';
  rl.textContent = label ?? '';
  row.append(rl, ...cells);
  return row;
}

// The one position the keyboard acts on. Moving it never rebuilds the card.
function markActive() {
  card.querySelector('.p.at')?.classList.remove('at');
  const spot = card.querySelector(`#p-${at.row}-${at.column}`);
  if (!spot) return;
  spot.classList.add('at');
  card.setAttribute('aria-activedescendant', spot.id);
}

// Cuts or fills one hole, and writes the card the punch produces back into
// the deck text. The compiler decides what that card's text becomes; the
// page only puts the answer where the reader can see it.
function punch(row, column) {
  if (!ready) return;
  const punched = globalThis.comtranToggle(cardAt(cardNumber), row, column);
  if (punched === null || punched === undefined) return;
  const { line } = JSON.parse(punched);
  const lines = source.value.split('\n');
  while (lines.length < cardNumber) lines.push('');
  const start = lines
    .slice(0, cardNumber - 1)
    .reduce((n, text) => n + text.length + 1, 0);
  lines[cardNumber - 1] = line;
  source.value = lines.join('\n');
  const caret = start + Math.min(column - 1, line.length);
  source.setSelectionRange(caret, caret);
  at = { row, column };
  deckChanged();
  drawGutter();
  drawCursor();
  updateCompileState();
  runSoon();
}

card.addEventListener('click', (event) => {
  const spot = event.target.closest('.p');
  if (spot) punch(Number(spot.dataset.r), Number(spot.dataset.c));
});

card.addEventListener('keydown', (event) => {
  const moves = {
    ArrowUp: [-1, 0],
    ArrowDown: [1, 0],
    ArrowLeft: [0, -1],
    ArrowRight: [0, 1],
  };
  if (event.key === ' ' || event.key === 'Enter') {
    event.preventDefault();
    punch(at.row, at.column);
    return;
  }
  const move = moves[event.key];
  if (!move) return;
  event.preventDefault();
  at = {
    row: Math.min(Math.max(at.row + move[0], 0), ROW_LABELS.length - 1),
    column: Math.min(Math.max(at.column + move[1], 1), CARD_COLUMNS),
  };
  markActive();
  card.querySelector('.p.at')?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
});

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

// The compiler's own messages, in its own words and its own order. The
// site adds a statement number and a severity to each and nothing else.
function drawWhinges(result) {
  if (result.error) {
    whingeCount.textContent = '';
    whinges.replaceChildren();
    return;
  }
  const list = result.diagnostics;
  whingeCount.textContent =
    list.length === 0
      ? ''
      : `${list.length} ${list.length === 1 ? 'message' : 'messages'}`;
  if (list.length === 0) {
    const clean = document.createElement('p');
    clean.className = 'whinge-none';
    // The line the 1962 listing itself prints for a clean compilation.
    clean.textContent = 'NO ERRORS WERE DETECTED DURING COMPILATION';
    whinges.replaceChildren(clean);
    return;
  }
  whinges.replaceChildren(
    ...list.map((item) => {
      const row = document.createElement('div');
      row.className = 'whinge';
      if (item.severity >= 5) row.classList.add('stopped');
      const number = document.createElement('span');
      number.className = 'wn';
      number.textContent = item.number;
      const severity = document.createElement('span');
      severity.className = 'ws';
      severity.textContent = item.severity;
      const text = document.createElement('span');
      text.className = 'wt';
      text.textContent = item.text;
      row.append(number, severity, text);
      return row;
    }),
  );
}

function draw(result, milliseconds) {
  latest = result;
  refusal.hidden = !result.error;
  refusal.textContent = result.error ?? '';
  if (result.error) {
    verdict.textContent = 'Not compiled';
    verdict.dataset.state = 'bad';
  } else {
    const errors = result.diagnostics.length;
    const took = `${milliseconds.toFixed(milliseconds < 10 ? 1 : 0)} ms`;
    verdict.textContent =
      errors === 0
        ? `${result.cardCount} cards · no errors · ${took}`
        : `${result.cardCount} cards · ${errors} ` +
          `${errors === 1 ? 'diagnostic' : 'diagnostics'} · ` +
          `worst severity ${result.maxSeverity} · ${took}`;
    verdict.dataset.state = errors === 0 ? 'good' : 'bad';
  }
  drawWhinges(result);
  drawStage();
}

// The text the panels below currently answer to. While it equals what is
// typed, there is nothing to compile and the button says so.
let compiled = null;

function updateCompileState() {
  compileButton.disabled = source.value === compiled;
}

function run() {
  if (!ready) return;
  const started = performance.now();
  const result = JSON.parse(globalThis.comtranCompile(source.value));
  const milliseconds = performance.now() - started;
  compiled = source.value;
  updateCompileState();
  draw(result, milliseconds);
}

// The compiler takes tens of milliseconds on the sample, so typing can
// recompile without a wait; the button stays for anyone who wants one.
let pending = 0;
function runSoon() {
  clearTimeout(pending);
  pending = setTimeout(run, 250);
}

source.addEventListener('input', () => {
  deckChanged();
  drawGutter();
  drawCursor();
  updateCompileState();
  runSoon();
});

for (const event of ['keyup', 'click', 'select']) {
  source.addEventListener(event, drawCursor);
}

source.addEventListener('scroll', () => {
  gutter.scrollTop = source.scrollTop;
  rulerWrap.scrollLeft = source.scrollLeft;
});

compileButton.addEventListener('click', run);

el('load').addEventListener('click', () => {
  source.value = SAMPLE;
  source.focus();
  source.setSelectionRange(0, 0);
  source.scrollTop = 0;
  deckChanged();
  drawGutter();
  drawCursor();
  run();
});

el('clear').addEventListener('click', () => {
  source.value = '';
  source.focus();
  deckChanged();
  drawGutter();
  drawCursor();
  run();
});

// Taking the deck away. The file is the compiler's; the link is the page's,
// and it carries the deck in the address so that no deck is ever stored on a
// server. `d1` is deflated and `d0` is plain, because a browser without
// CompressionStream must still be able to write a link every browser reads.
const LINK = /^#d([01])=([A-Za-z0-9_-]+)$/;

function say(message) {
  linkNote.hidden = message === null;
  linkNote.textContent = message ?? '';
}

function toBase64Url(bytes) {
  // String.fromCharCode takes its arguments on the stack, so a whole deck at
  // once overflows it on a long program.
  let binary = '';
  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

function fromBase64Url(text) {
  const plain = text.replaceAll('-', '+').replaceAll('_', '/');
  const binary = atob(plain + '='.repeat((4 - (plain.length % 4)) % 4));
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function through(bytes, stream) {
  const piped = new Blob([bytes]).stream().pipeThrough(stream);
  return new Uint8Array(await new Response(piped).arrayBuffer());
}

async function linkFor(text) {
  const plain = new TextEncoder().encode(text);
  if (typeof CompressionStream !== 'function') return `#d0=${toBase64Url(plain)}`;
  const squeezed = await through(plain, new CompressionStream('deflate-raw'));
  return `#d1=${toBase64Url(squeezed)}`;
}

async function deckFromLink() {
  const carried = LINK.exec(location.hash);
  if (!carried) return null;
  const bytes = fromBase64Url(carried[2]);
  const plain =
    carried[1] === '0'
      ? bytes
      : await through(bytes, new DecompressionStream('deflate-raw'));
  return new TextDecoder().decode(plain);
}

// An address that describes a deck the reader has since changed is a false
// address, and a note about a deck that has moved on is a false note. Both
// go when the deck goes.
function deckChanged() {
  say(null);
  if (!LINK.test(location.hash)) return;
  history.replaceState(null, '', location.pathname + location.search);
}

el('download').addEventListener('click', () => {
  // The compiler encodes the file, so there is nothing to save until it is
  // there. Without this the click throws and the reader is told nothing.
  if (!ready) {
    say(
      'The compiler has not loaded yet, and it is what encodes the deck ' +
        'file. Try again in a moment.',
    );
    return;
  }
  const bytes = globalThis.comtranCanon(source.value);
  if (bytes === null || bytes === undefined) {
    say(
      'There is no deck file to save. A card here is not one the punch could ' +
        'cut, and the file holds punches. Fix that card and try again.',
    );
    return;
  }
  const url = URL.createObjectURL(new Blob([bytes], { type: 'application/octet-stream' }));
  const link = document.createElement('a');
  link.href = url;
  link.download = 'deck.ctd';
  link.click();
  URL.revokeObjectURL(url);
  say(`Saved deck.ctd, ${bytes.length.toLocaleString('en-GB')} bytes.`);
});

// Chrome leaves a clipboard write pending, neither kept nor refused, while
// the page has no focus. A pending promise leaves the reader with no message
// at all, so the wait is bounded and the page always says how it went.
const CLIPBOARD_WAIT = 1000;

async function copyLink(text) {
  const pending = navigator.clipboard?.writeText(text);
  if (!pending) return 'refused';
  return Promise.race([
    pending.then(() => 'copied', () => 'refused'),
    new Promise((resolve) => setTimeout(resolve, CLIPBOARD_WAIT, 'no answer')),
  ]);
}

const ELSEWHERE = 'The address bar now holds the link, so copy it from there.';

el('share').addEventListener('click', async () => {
  history.replaceState(null, '', await linkFor(source.value));
  const went = await copyLink(location.href);
  if (went === 'copied') {
    say(
      `Link copied, ${location.href.length.toLocaleString('en-GB')} ` +
        'characters. It carries the deck as you typed it.',
    );
  } else if (went === 'refused') {
    say(`This browser would not let the page reach the clipboard. ${ELSEWHERE}`);
  } else {
    say(`The clipboard did not answer. ${ELSEWHERE}`);
  }
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

let carried = null;
try {
  carried = await deckFromLink();
} catch {
  say(
    'The address carried a deck this page could not read, so the sample ' +
      'program is loaded instead.',
  );
}
source.value = carried ?? SAMPLE;
// Assigning to value leaves the caret at the end of the deck; card 1 is
// where a reader starts.
source.setSelectionRange(0, 0);
drawGutter();
drawCursor();
drawStage();
updateCompileState();
out.textContent = 'Loading the compiler…';

try {
  const bytes = await (await fetch('main.wasm')).arrayBuffer();
  invoke(await instantiate(await compile(bytes), {}));
  ready = true;
  drawCursor();
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
