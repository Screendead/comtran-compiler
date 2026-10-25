"""Assemble the deck-reading walkthrough for item 2 of the 2026-09-14 record.

Run it from anywhere: python3 -I build_doc.py
It reads only the files under ../evidence and ../crops, and writes
../index.html. The page is standalone: the crops and every datum are
embedded, so it renders with no network and no server.

Every fact on the page comes from an evidence file, a manual crop, or a
repository path at commit f1dc820. The checks below stop the build if the
evidence disagrees with itself.
"""

import base64
import html
import json
import os
import re
from collections import Counter, OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
EV = os.path.join(REC, "evidence")
OUT = os.path.join(REC, "index.html")
BASE = "f1dc820"


def read(name):
    with open(os.path.join(EV, name), encoding="utf-8") as fh:
        return fh.read()


def esc(s):
    return html.escape(s, quote=False)


# --- the deck: canon decode, checked against the mirror -----------------

with open(os.path.join(EV, "f-payroll.ctd"), "rb") as fh:
    CANON = fh.read()
assert CANON[:6] == b"CTDECK", "magic"
COUNT = int.from_bytes(CANON[8:12], "big")
assert len(CANON) == 12 + 120 * COUNT, "length"
MIRROR = read("f-payroll.ct").split("\n")
if MIRROR and MIRROR[-1] == "":
    MIRROR.pop()
assert len(MIRROR) == COUNT == 191, (len(MIRROR), COUNT)


def columns(card):
    """The 80 12-bit column values, deck-format.md section 2.2."""
    bits = int.from_bytes(card, "big")
    return [(bits >> (960 - 12 * (c + 1))) & 0xFFF for c in range(80)]


CARDS = []
PATTERN = {}
for i in range(COUNT):
    cols = columns(CANON[12 + 120 * i: 12 + 120 * (i + 1)])
    text = MIRROR[i].ljust(80)
    for c, v in enumerate(cols):
        ch = text[c]
        if ch == " ":
            assert v == 0, (i + 1, c + 1)
        else:
            assert v != 0, (i + 1, c + 1)
            PATTERN.setdefault(ch, set()).add(v)
    CARDS.append({"n": i + 1, "t": MIRROR[i], "p": "".join(f"{v:03x}" for v in cols)})
# One punch pattern per character, and the row order of section 2.2:
# bit 11 is row 12, bit 8 is row 1. 'A' is 12 + 1.
assert all(len(v) == 1 for v in PATTERN.values()), PATTERN
assert PATTERN["A"] == {(1 << 11) | (1 << 8)}, PATTERN["A"]
assert PATTERN["1"] == {1 << 8}

# --- the listing: statement numbers by card serial ----------------------

LISTING = read("f-payroll.listing")
SERIAL_STMT = {}
current = None
for line in LISTING.split("\n"):
    m = re.match(r"^ {8}(\d{5}) +(\d+,\d\d)?", line)
    if m:
        if m.group(2):
            current = m.group(2)
        SERIAL_STMT[m.group(1)] = current
for card in CARDS:
    serial = card["t"][:5]
    card["s"] = SERIAL_STMT.get(serial) if serial.isdigit() else None

# --- the 55 messages: --explain joined to the listing's NUMBER column ---

ERR = read("run.stderr").split("\n")
EXPLAIN = []
for line in ERR:
    m = re.match(r"^(\d+,\d\d) (\d) (.*)$", line)
    if m:
        EXPLAIN.append({"id": m.group(1), "sev": int(m.group(2)), "text": m.group(3)})
    elif line.startswith(" ") and EXPLAIN:
        EXPLAIN[-1]["text"] += "\n" + line
for e in EXPLAIN:
    m = re.search(r" \(card (\d+)(?:, column (\d+))?\)$", e["text"])
    assert m, e
    e["card"] = int(m.group(1))
    e["col"] = int(m.group(2)) if m.group(2) else None
    e["text"] = e["text"][: m.start()]
REFUSAL = [l for l in ERR if l.startswith("error:")]
assert REFUSAL == [
    "error: job 1: unrecovered shape: a GET record on 0 input files (no sample instance)"
], REFUSAL

block = LISTING.split("NUMBER   CODE   MESSAGE", 1)[1]
LISTED = []
for line in block.split("\n"):
    m = re.match(r"^ *(\d+,\d\d) +(\d) +(.*)$", line)
    if m:
        LISTED.append({"num": m.group(1), "sev": int(m.group(2)), "text": m.group(3)})
    elif line.startswith("                    ") and LISTED:
        LISTED[-1]["text"] += "\n" + line
assert len(LISTED) == len(EXPLAIN) == 55, (len(LISTED), len(EXPLAIN))
for a, b in zip(EXPLAIN, LISTED):
    assert a["sev"] == b["sev"], (a, b)
    assert " ".join(a["text"].split()) == " ".join(b["text"].split()), (a, b)
    a["num"] = b["num"]
MESSAGES = EXPLAIN

TEMPLATE = OrderedDict([
    ("108,00", "'NAME.1' IS AN UNDEFINED SYMBOL."),
    ("101,00", "'NAME.1' IS AN IMPROPERLY QUALIFIED NAME."),
    ("166,00", "'NAME.1' IS NOT UNIQUE IN THIS SECTION."),
    ("19,00", "RECORD 'NAME.2' MUST BE ON AN OUTPUT -FILE- CARD. CHECK ENVIRONMENT DESCRIPTION OR NAME."),
    ("9,00", "RECORD 'NAME.2' MUST BE ON A -FILE- CARD. CHECK ENVIRONMENT DESCRIPTION."),
    ("21,00", "'NAME.1' IS NOT A FILE. CHECK ENVIRONMENT DESCRIPTION."),
    ("175,00", "NO -STOP RUN- IN PROGRAM."),
    ("110,00", "-COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM."),
    ("906,00", "DATA DESCRIPTION CARD CODING CONFLICTS WITH ITS TYPE CODE. (NON-HISTORICAL.)"),
    ("81,00", "CONFLICT BETWEEN LEVEL AS GIVEN BY ORIGINAL DEFINITION AND -REDEF-."),
    ("80,00", "CONFLICT BETWEEN JUSTIFICATION AS GIVEN BY ORIGINAL DEFINITION AND -REDEF-."),
    ("206,00", "'NAME.1' HAS INEFFICIENT FORMAT FOR SUBSCRIPT VARIABLE."),
])
KINDS = Counter(m["id"] for m in MESSAGES)
assert set(KINDS) == set(TEMPLATE), KINDS
assert sorted(KINDS.values(), reverse=True) == [26, 7, 6, 4, 3, 3, 1, 1, 1, 1, 1, 1], KINDS
SEVS = Counter(m["sev"] for m in MESSAGES)
KIND_SEV = {}
for m in MESSAGES:
    KIND_SEV.setdefault(m["id"], set()).add(m["sev"])
assert all(len(v) == 1 for v in KIND_SEV.values()), KIND_SEV
MAXSEV = max(SEVS)
assert MAXSEV == 4 and 5 not in SEVS
assert LISTING.rstrip().endswith("SEVERITY LIMIT WAS NOT REACHED")

# --- the other run artifacts -------------------------------------------

RUN_CODE = read("run.code").rstrip("\n")
RUN_OBJECT = read("run.object").rstrip("\n")
RUN_XXD = read("run.deck.xxd.txt").rstrip("\n")
RUN_EXIT = read("run.exit").strip()
assert RUN_EXIT == "exit=1"
with open(os.path.join(EV, "run.deck.ctd"), "rb") as fh:
    DECK_OUT = fh.read()
assert DECK_OUT[:6] == b"CTDECK" and len(DECK_OUT) == 12
assert int.from_bytes(DECK_OUT[8:12], "big") == 0
GET_GUARD = read("procedure-get-guard.dart.txt").rstrip("\n")
FILE_GUARD = read("procedure-file-guard.dart.txt").rstrip("\n")
SHAPE_DOC = read("procedure-unrecovered-shape.dart.txt").rstrip("\n")
FILE_IN_TEST = read("codegen-refusal-file-in.dart.txt").rstrip("\n")

DATA = {
    "cards": CARDS,
    "msgs": [
        {k: m[k] for k in ("id", "sev", "text", "card", "col", "num")} for m in MESSAGES
    ],
    "kinds": [
        {"id": k, "count": KINDS[k], "sev": next(iter(KIND_SEV[k])), "t": TEMPLATE[k]}
        for k in sorted(TEMPLATE, key=lambda k: (-KINDS[k], list(TEMPLATE).index(k)))
    ],
}


# --- page pieces --------------------------------------------------------


def crop(name):
    with open(os.path.join(REC, "crops", name), "rb") as fh:
        return "data:image/png;base64," + base64.b64encode(fh.read()).decode("ascii")


def figure(name, alt, caption):
    return (
        "<figure>\n"
        f'<div class="scan"><img src="{crop(name)}" alt="{alt}"></div>\n'
        f"<figcaption>{caption}</figcaption>\n"
        "</figure>"
    )


def quote(body, cite):
    return f'<blockquote>{body}</blockquote>\n<p class="cite">{cite}</p>'


def plate(text, cite=None):
    block = f'<div class="plate"><pre>{esc(text)}</pre></div>'
    if cite:
        block += f'\n<p class="cite">{cite}</p>'
    return block


RULE = (
    "if it would compile in 1962, it should compile. If it wouldn't, it"
    " shouldn't. If it's ambiguous, I need to see it with argumentation both"
    " ways and a recommendation, and I'll make a call."
)

sev_rows = "".join(
    f'<tr><td>{s}</td><td>{SEVS.get(s, 0)}</td>'
    f'<td><span class="bar" style="width:{SEVS.get(s, 0) * 0.32:.2f}rem"></span></td></tr>'
    for s in range(1, 6)
)

kind_rows = "".join(
    f"<tr><td>{KINDS[k]}</td><td><code>{k}</code></td><td>{next(iter(KIND_SEV[k]))}</td>"
    f'<td class="mono">{esc(TEMPLATE[k])}</td></tr>'
    for k in [d["id"] for d in DATA["kinds"]]
)

CSS = """
:root {
  --paper:#F7F8F6; --raised:#FFFFFF; --ink:#14171A; --muted:#5C6560;
  --rule:#C9CFC8; --hair:#E1E5DF; --stamp:#B3261E; --stamp-soft:#FBEAE8;
  --settled:#40685A;
  --serif:"Iowan Old Style","Palatino Linotype",Palatino,"Book Antiqua",Georgia,serif;
  --mono:ui-monospace,"SF Mono",SFMono-Regular,Menlo,Consolas,monospace;
}
@media (prefers-color-scheme:dark) {
  :root:not([data-theme="light"]) {
    --paper:#141715; --raised:#1C201D; --ink:#E7EBE5; --muted:#9AA69D;
    --rule:#3A423C; --hair:#2A302C; --stamp:#FF7A6B; --stamp-soft:#33201D;
    --settled:#7FB8A2;
  }
}
:root[data-theme="dark"] {
  --paper:#141715; --raised:#1C201D; --ink:#E7EBE5; --muted:#9AA69D;
  --rule:#3A423C; --hair:#2A302C; --stamp:#FF7A6B; --stamp-soft:#33201D;
  --settled:#7FB8A2;
}
* { box-sizing:border-box; }
body {
  background:var(--paper); color:var(--ink); font-family:var(--serif);
  font-size:17px; line-height:1.62; margin:0;
  padding:clamp(1.5rem,4vw,4rem) clamp(1rem,5vw,2rem);
}
main > *, section > * { min-width:0; }
main { max-width:52rem; margin:0 auto; display:flex; flex-direction:column; gap:2.4rem; }
h1 { font-size:clamp(1.7rem,4.2vw,2.4rem); line-height:1.16; margin:0; text-wrap:balance;
     letter-spacing:-0.015em; }
h2 { font-size:1.32rem; margin:0 0 .2rem; text-wrap:balance; letter-spacing:-0.01em; }
h3 { font-size:1.02rem; margin:1.6rem 0 .3rem; }
p, li { margin:0 0 .85rem; }
li:last-child { margin-bottom:0; }
ul, ol { padding-left:1.15rem; margin:0 0 .85rem; }
code { font-family:var(--mono); font-size:.87em; background:var(--hair);
       padding:.08em .3em; border-radius:2px; overflow-wrap:anywhere; }
.mono { font-family:var(--mono); font-size:.8rem; }
header .eyebrow { padding-right:8rem; }
.eyebrow { font-family:var(--mono); font-size:.7rem; letter-spacing:.16em;
           text-transform:uppercase; color:var(--muted); margin:0 0 .7rem; }
header { border-bottom:2px solid var(--ink); padding-bottom:1.4rem; position:relative; }
section { display:flex; flex-direction:column; gap:.2rem; }
.answer { background:var(--raised); border:1px solid var(--hair);
          border-left:3px solid var(--ink); padding:1.15rem 1.3rem; }
.answer ol { margin:0 0 .85rem; padding-left:1.2rem; }
.answer li { margin-bottom:.5rem; }
.answer p:last-child { margin-bottom:0; }
.note { color:var(--muted); font-size:.92rem; margin:0; }
.chip { font-family:var(--mono); font-size:.66rem; letter-spacing:.14em;
        text-transform:uppercase; padding:.24em .6em; border-radius:2px;
        border:1px solid currentColor; white-space:nowrap; }
.chip.call { color:var(--stamp); background:var(--stamp-soft); }
.chip.done { color:var(--settled); }
.itemhead { display:flex; gap:.75rem; align-items:baseline; flex-wrap:wrap;
            margin-bottom:.35rem; }
.item { border-top:1px solid var(--rule); padding-top:1.3rem; }
.item.needs { border-top:2px solid var(--stamp); }
.step { font-family:var(--mono); font-size:.7rem; letter-spacing:.14em; color:var(--muted);
        text-transform:uppercase; }
blockquote { margin:.2rem 0 .2rem; border-left:3px solid var(--rule);
             padding:.1rem 0 .1rem 1rem; }
blockquote p { margin:0 0 .6rem; }
blockquote p:last-child { margin:0; }
p.cite { font-family:var(--mono); font-size:.71rem; line-height:1.5;
         color:var(--muted); margin:.4rem 0 1rem 1rem; }
p.cite code { background:none; padding:0; }
figure { margin:1rem 0 1.2rem; }
.plate { background:var(--raised); border:1px solid var(--rule); padding:.55rem;
         overflow-x:auto; }
.plate pre, pre.plain { margin:0; font-family:var(--mono); font-size:.76rem; line-height:1.5; }
.scan { background:#fff; border:1px solid var(--rule); padding:.55rem; }
img { max-width:100%; height:auto; }
.scan img { display:block; margin:0 auto; }
figcaption { font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
             margin-top:.5rem; }
.scroll { overflow-x:auto; margin:.5rem 0 1rem; }
table { border-collapse:collapse; font-size:.92rem; margin:.6rem 0 1rem;
       font-variant-numeric:tabular-nums; }
th, td { text-align:left; padding:.3rem .7rem .3rem 0; vertical-align:top;
        border-bottom:1px solid var(--hair); }
td:first-child, td > code:only-child { white-space:nowrap; }
th { font-family:var(--mono); font-size:.7rem; letter-spacing:.1em;
    text-transform:uppercase; color:var(--muted); font-weight:normal; }
.opt { border-left:3px solid var(--rule); padding:.15rem 0 .15rem 1rem; margin:0 0 1rem; }
.opt.pick { border-left-color:var(--stamp); }
.opt .name { font-family:var(--mono); font-size:.75rem; letter-spacing:.08em;
             text-transform:uppercase; }
.ask { background:var(--stamp-soft); border:1px solid var(--stamp); padding:.9rem 1.1rem;
       margin:.9rem 0 0; }
.ask p { margin:0 0 .5rem; }
.ask .label { font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
              text-transform:uppercase; color:var(--stamp); display:block; margin-bottom:.3rem; }
footer { border-top:1px solid var(--rule); padding-top:1rem; font-size:.85rem;
         color:var(--muted); }
.inferred { font-family:var(--mono); font-size:.62rem; letter-spacing:.12em;
            text-transform:uppercase; color:var(--muted); border:1px dashed var(--muted);
            padding:.05em .4em; border-radius:2px; white-space:nowrap; }
button, .btn { font-family:var(--mono); font-size:.74rem; background:var(--raised);
         color:var(--ink); border:1px solid var(--rule); padding:.3rem .6rem;
         border-radius:2px; cursor:pointer; }
button:hover { border-color:var(--ink); }
button[aria-pressed="true"] { border-color:var(--stamp); color:var(--stamp);
         background:var(--stamp-soft); }
#theme { position:absolute; right:0; top:0; }
nav.steps { position:sticky; top:0; z-index:5; background:var(--paper);
            border-bottom:1px solid var(--rule); padding:.5rem 0; display:flex;
            flex-wrap:wrap; gap:.4rem; }
nav.steps a { font-family:var(--mono); font-size:.7rem; color:var(--ink);
              text-decoration:none; border:1px solid var(--rule); padding:.2rem .5rem;
              border-radius:2px; }
nav.steps a:hover { border-color:var(--stamp); }
/* deck viewer */
.deck { display:grid; grid-template-columns:minmax(0,1fr); gap:.8rem; }
.decklist { max-height:22rem; overflow:auto; border:1px solid var(--rule);
            background:var(--raised); }
.cardrow { display:grid; grid-template-columns:3rem 3.6rem minmax(0,1fr) 2.2rem; gap:.4rem;
           font-family:var(--mono); font-size:.72rem; line-height:1.55; padding:0 .4rem;
           cursor:pointer; white-space:pre; border-bottom:1px solid var(--hair); }
.cardrow:hover { background:var(--hair); }
.cardrow.sel { outline:2px solid var(--stamp); outline-offset:-2px; }
.cardrow .n, .cardrow .s { color:var(--muted); text-align:right; }
.cardrow .t { overflow:hidden; text-overflow:ellipsis; }
.cardrow .b { color:var(--stamp); text-align:right; }
.punch { background:#F4EBCF; border:1px solid var(--rule); padding:.4rem; overflow-x:auto; }
.punch svg { display:block; min-width:640px; width:100%; height:auto; }
.controls { display:flex; flex-wrap:wrap; gap:.5rem; align-items:center; margin:.4rem 0; }
.controls label { font-family:var(--mono); font-size:.74rem; }
.oncard { margin:.4rem 0 0; padding:0; list-style:none; }
.oncard li { font-family:var(--mono); font-size:.74rem; margin:0 0 .25rem; }
/* messages */
details.kind { border-top:1px solid var(--hair); }
details.kind summary { cursor:pointer; display:grid;
  grid-template-columns:2.2rem 4.2rem 2.4rem 1fr; gap:.5rem; padding:.35rem 0;
  font-variant-numeric:tabular-nums; list-style:none; }
details.kind summary::-webkit-details-marker { display:none; }
details.kind summary .t { font-family:var(--mono); font-size:.74rem; }
details.kind summary .c { font-weight:bold; }
details.kind[open] summary { color:var(--stamp); }
.occ { display:flex; flex-wrap:wrap; gap:.3rem; padding:.2rem 0 .7rem 2.7rem; }
.occ button { font-size:.68rem; }
.inspect { background:var(--raised); border:1px solid var(--rule);
           border-left:3px solid var(--stamp); padding:.7rem .9rem; margin:.6rem 0 0; }
.inspect pre { margin:.3rem 0; font-family:var(--mono); font-size:.74rem; overflow-x:auto; }
.sevtab td:nth-child(3) { width:60%; }
.bar { display:inline-block; height:.7rem; background:var(--stamp); vertical-align:middle; }
/* gate */
.gate { display:grid; grid-template-columns:repeat(3,1fr); gap:.6rem; margin:.6rem 0; }
.gate div { background:var(--raised); border:1px solid var(--rule); padding:.6rem .7rem; }
.gate .k { font-family:var(--mono); font-size:.66rem; letter-spacing:.12em;
           text-transform:uppercase; color:var(--muted); display:block; }
.gate .v { font-size:1.05rem; font-weight:bold; }
.gate .v.no { color:var(--stamp); }
.gate .v.yes { color:var(--settled); }
.gate .w { font-family:var(--mono); font-size:.66rem; color:var(--muted); display:block; }
/* fork */
.fork { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:1rem; margin:.6rem 0; }
.panel { background:var(--raised); border:1px solid var(--rule); padding:.9rem 1rem; }
.panel.rec { border:2px solid var(--stamp); }
.panel h3 { margin-top:0; }
.panel dl { margin:0; }
.panel dt { font-family:var(--mono); font-size:.66rem; letter-spacing:.12em;
            text-transform:uppercase; color:var(--muted); margin-top:.6rem; }
.panel dd { margin:0; font-size:.93rem; }
.sub { border-top:1px dashed var(--rule); margin-top:.8rem; padding-top:.5rem; }
/* answer */
.pick label { display:block; border:1px solid var(--rule); background:var(--raised);
              padding:.6rem .8rem; margin:0 0 .5rem; cursor:pointer; }
.pick label:hover { border-color:var(--ink); }
.pick input { margin-right:.5rem; }
textarea { width:100%; min-height:4.5rem; font-family:var(--mono); font-size:.8rem;
           background:var(--raised); color:var(--ink); border:1px solid var(--rule);
           padding:.5rem; }
@media (max-width:700px) {
  .fork, .gate { grid-template-columns:minmax(0,1fr); }
  table { font-size:.82rem; }
  .cardrow { grid-template-columns:2.4rem 3.2rem minmax(0,1fr) 1.8rem; }
}
"""

JS = r"""
const D = JSON.parse(document.getElementById('data').textContent);
const $ = (s, r = document) => r.querySelector(s);
const el = (t, a = {}, ...kids) => { const e = document.createElement(t);
  for (const [k, v] of Object.entries(a)) { if (k === 'class') e.className = v;
    else if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else e.setAttribute(k, v); }
  for (const k of kids) e.append(k); return e; };

// theme
(function () {
  const b = $('#theme');
  b.addEventListener('click', () => {
    const r = document.documentElement;
    const dark = r.dataset.theme ? r.dataset.theme === 'dark'
      : matchMedia('(prefers-color-scheme: dark)').matches;
    r.dataset.theme = dark ? 'light' : 'dark';
  });
})();

const byCard = {};
D.msgs.forEach((m, i) => { m.i = i; (byCard[m.card] ||= []).push(m); });

// ---- step 1: the deck ----
const ROWS = ['12', '11', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
function punchSVG(card, markCol) {
  const W = 8, H = 13, X0 = 26, Y0 = 26;
  const ns = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(ns, 'svg');
  const w = X0 + 80 * W + 8, h = Y0 + 12 * H + 8;
  svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', `Card ${card.n}: ${card.t}`);
  const add = (t, a, txt) => { const e = document.createElementNS(ns, t);
    for (const [k, v] of Object.entries(a)) e.setAttribute(k, v);
    if (txt !== undefined) e.textContent = txt; svg.append(e); return e; };
  add('rect', { x: 0, y: 0, width: w, height: h, fill: '#F4EBCF' });
  if (markCol) add('rect', { x: X0 + (markCol - 1) * W - 1, y: 2, width: W + 2,
    height: h - 4, fill: 'none', stroke: '#B3261E', 'stroke-width': 1.5 });
  const text = card.t.padEnd(80);
  for (let c = 0; c < 80; c++) {
    const v = parseInt(card.p.substr(c * 3, 3), 16);
    if (text[c] !== ' ') add('text', { x: X0 + c * W + W / 2, y: 14, 'font-size': 9,
      'text-anchor': 'middle', 'font-family': 'ui-monospace,Menlo,monospace',
      fill: '#14171A' }, text[c]);
    for (let r = 0; r < 12; r++) {
      const bit = (v >> (11 - r)) & 1;
      const x = X0 + c * W + 1.5, y = Y0 + r * H + 2;
      if (bit) add('rect', { x, y, width: W - 3, height: H - 4, fill: '#14171A' });
      else if (r >= 2) add('text', { x: X0 + c * W + W / 2, y: y + 8, 'font-size': 6,
        'text-anchor': 'middle', fill: '#B9AD8C', 'font-family': 'ui-monospace,Menlo,monospace' }, ROWS[r]);
    }
  }
  ROWS.forEach((r, i) => add('text', { x: 4, y: Y0 + i * H + 10, 'font-size': 8,
    fill: '#6B6250', 'font-family': 'ui-monospace,Menlo,monospace' }, r));
  [1, 10, 20, 30, 40, 50, 60, 70, 80].forEach(c => add('text', { x: X0 + (c - 1) * W + W / 2,
    y: h - 1, 'font-size': 6, 'text-anchor': 'middle', fill: '#6B6250',
    'font-family': 'ui-monospace,Menlo,monospace' }, String(c)));
  return svg;
}

const list = $('#decklist');
D.cards.forEach(c => {
  const n = (byCard[c.n] || []).length;
  const row = el('div', { class: 'cardrow', id: 'card-' + c.n, 'data-n': c.n,
      'data-m': n ? '1' : '0', tabindex: 0,
      onclick: () => selectCard(c.n), onkeydown: e => { if (e.key === 'Enter') selectCard(c.n); } },
    el('span', { class: 'n' }, String(c.n)), el('span', { class: 's' }, c.s || ''),
    el('span', { class: 't' }, c.t), el('span', { class: 'b' }, n ? '●' + n : ''));
  list.append(row);
});
$('#onlyflag').addEventListener('change', e => {
  list.querySelectorAll('.cardrow').forEach(r => {
    r.style.display = e.target.checked && r.dataset.m === '0' ? 'none' : ''; });
});
function selectCard(n, col, scroll) {
  const c = D.cards[n - 1];
  list.querySelectorAll('.sel').forEach(r => r.classList.remove('sel'));
  const row = $('#card-' + n); row.classList.add('sel');
  row.scrollIntoView({ block: 'nearest' });
  const ms = byCard[n] || [];
  const mark = col || (ms.length && ms[0].col) || null;
  const box = $('#punch'); box.replaceChildren(punchSVG(c, mark));
  $('#cardcap').textContent = `Card ${n} of 191` + (c.s ? `, statement ${c.s}` : '') +
    (mark ? `. The red frame marks column ${mark}.` : '.') +
    ' Holes decoded from the canon file f-payroll.ctd; the printed line is the mirror f-payroll.ct.';
  const ul = $('#oncard'); ul.replaceChildren();
  if (!ms.length) ul.append(el('li', {}, 'This card draws no message.'));
  ms.forEach(m => ul.append(el('li', {}, `${m.num}  ${m.id}  severity ${m.sev}  ` +
    m.text.replace(/\s+/g, ' ') + (m.col ? `  (column ${m.col})` : ''))));
  if (scroll) $('#step1').scrollIntoView({ behavior: 'smooth' });
}
selectCard(11);

// ---- step 2: the messages ----
let order = 'kind';
function renderMsgs() {
  const host = $('#kinds'); host.replaceChildren();
  const groups = order === 'kind' ? D.kinds.map(k => ({ head: k, items: D.msgs.filter(m => m.id === k.id) }))
    : [{ head: null, items: D.msgs }];
  groups.forEach(g => {
    const occ = el('div', { class: 'occ' });
    g.items.forEach(m => {
      const name = (m.text.match(/'([^']+)'/) || [, ''])[1];
      occ.append(el('button', { onclick: () => inspect(m) },
        `${m.num} · card ${m.card}` + (name ? ` · ${name}` : '') +
        (order === 'listing' ? ` · ${m.id}` : '')));
    });
    if (g.head) {
      const k = g.head;
      host.append(el('details', { class: 'kind' },
        el('summary', {}, el('span', { class: 'c' }, String(k.count)),
          el('span', { class: 'mono' }, k.id), el('span', { class: 'mono' }, 'sev ' + k.sev),
          el('span', { class: 't' }, k.t)), occ));
    } else host.append(occ);
  });
}
function inspect(m) {
  const c = D.cards[m.card - 1];
  const caret = m.col ? ' '.repeat(m.col - 1) + '^' : '';
  const box = $('#inspect'); box.hidden = false;
  box.replaceChildren(
    el('div', { class: 'step' }, `Statement ${m.num} · message ${m.id} · our severity ${m.sev}`),
    el('pre', {}, m.text),
    el('pre', {}, `card ${String(m.card).padStart(3)}  ` + c.t + '\n' + (caret ? '           ' + caret + `  column ${m.col}` : '           (no column: the message names the card as a whole)')),
    el('button', { onclick: () => selectCard(m.card, m.col, true) }, 'Show this card punched, in step 1'));
}
document.querySelectorAll('[data-order]').forEach(b => b.addEventListener('click', () => {
  order = b.dataset.order;
  document.querySelectorAll('[data-order]').forEach(x => x.setAttribute('aria-pressed', x === b));
  renderMsgs();
}));
renderMsgs();

// ---- step 3: the gate ----
function gate(s) {
  document.querySelectorAll('[data-sev]').forEach(b => b.setAttribute('aria-pressed', b.dataset.sev == s));
  const set = (id, ok, txt, why) => { const v = $('#' + id + ' .v');
    v.textContent = txt; v.className = 'v ' + (ok ? 'yes' : 'no'); $('#' + id + ' .w').textContent = why; };
  set('g-compile', s < 5, s < 5 ? 'Completes' : 'Stops', 'J 90.04.02: a code of 5 stops compiling.');
  set('g-deck', s < 5, s < 5 ? 'Punched' : 'Not punched', 'J 02.01.01: if the code is 5, no deck.');
  set('g-run', s <= 1, s <= 1 ? 'May run' : 'Does not run', 'J 90.04.02, J 02.01.02: any code above 1 stops compile-and-go.');
  $('#g-note').textContent = s == 4 ? 'This is our table: the highest code the verbatim deck draws under D7.5 is 4.'
    : s == 5 ? 'Option 3 below: one of the twelve kinds carried a 5 in 1962. No value survives to say so.'
    : 'A what-if. The verbatim deck draws codes up to 4 under our table.';
}
document.querySelectorAll('[data-sev]').forEach(b => b.addEventListener('click', () => gate(+b.dataset.sev)));
gate(4);

// ---- step 6: the answer ----
function answerText() {
  const p = document.querySelector('input[name=opt]:checked');
  const note = $('#anote').value.trim();
  if (!p && !note) return '(pick an option, or write your answer)';
  return 'review/2026-10-25-m6s2-deck-walkthrough, item 2: ' +
    (p ? p.value : 'other') + (note ? '\nNote: ' + note : '');
}
function refresh() { $('#aout').textContent = answerText(); }
document.querySelectorAll('input[name=opt]').forEach(r => r.addEventListener('change', refresh));
$('#anote').addEventListener('input', refresh);
$('#copy').addEventListener('click', async () => {
  try { await navigator.clipboard.writeText(answerText()); $('#copy').textContent = 'Copied'; }
  catch (e) { $('#copy').textContent = 'Copy failed: select the text below'; }
  setTimeout(() => { $('#copy').textContent = 'Copy my answer'; }, 2500);
});
refresh();
"""

sites = """
<table>
<tr><th>Statements</th><th>What the listing says</th><th>What the deck needs there</th></tr>
<tr><td>3,00 4,00 7,00</td><td><code>9,00</code> &times;3: RECORD 'MASTER' or
'DETAIL' MUST BE ON A -FILE- CARD.</td><td>A GET on a record that no FILE card
carries. The 1962 sample attests the GET call, <code>TSX IOC)8</code>, for a
record on one input file (<code>docs/design/m5-io.md</code>). No text describes
it for a record on none.</td></tr>
<tr><td>6,00 9,00 36,00</td><td><code>21,00</code> &times;3: 'ERROR.FILE' IS NOT A
FILE.</td><td>A <code>FILE record IN ERROR.FILE</code> where ERROR.FILE names no
file. No text describes the call.</td></tr>
<tr><td>13,00 21,00 22,00 23,00</td><td><code>19,00</code> &times;4: RECORD MUST BE
ON AN OUTPUT -FILE- CARD.</td><td>A FILE of PAYRECORD or CHECK, which sit on no
output file. No text describes the call.</td></tr>
<tr><td>5,00 to 40,00</td><td><code>108,00</code> &times;26: IS AN UNDEFINED
SYMBOL.</td><td>An operand for each undefined name. No text says what the 1962
processor put in its place.</td></tr>
<tr><td>13,00 23,00 (reads); 132,00 (card)</td><td><code>110,00</code>: -COPY- AND
-LIBRARY- ARE NOT YET HANDLED BY SYSTEM.</td><td>GRAND.TOTAL. J says only
&ldquo;Implementation of COPY has been deferred&rdquo; (J 90.01.03 b.i). M6-8
reads the entry as left empty. <span class="inferred">our reading</span></td></tr>
</table>
"""

HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>The deck reading, walked through</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<button id="theme" type="button" aria-label="Switch light or dark">Light / dark</button>
<p class="eyebrow">Review record &middot; M6 stage 2 &middot; item 2 of
review/2026-09-14-m6s2-rule &middot; evidence 2026-10-25 &middot; repository at {BASE}</p>
<h1>The deck reading, walked through</h1>
</header>

<section class="answer">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>What you are deciding, and why it matters</h2></div>
<p>Your rule of 2026-09-14 reads: &ldquo;{RULE}&rdquo; The 1960 payroll program,
keyed exactly as printed, is the case that splits the word
&ldquo;compile&rdquo;. Under the 1962 manual's own rules the processor would
have printed a full listing of 55 messages, <em>and</em> punched an object
deck, <em>and</em> refused to run it. We can reproduce the listing to the byte.
No evidence describes what was on the deck. So: does &ldquo;it should
compile&rdquo; mean we must print the listing, or that we must also punch that
deck? The answer fixes how two refusals in the compiler are labelled, and
whether we may ever write code that no evidence describes.</p>
</section>

<section class="answer">
<h2>The 30-second version</h2>
<ol>
<li><strong>The 1962 processor never saw this deck.</strong> Every step below
is what J's letter says it <em>would</em> have done. Nothing here is a record
of a run in 1962.</li>
<li>Our compiler reads the 191 cards and prints the listing: 55 messages of 12
kinds, highest code 4, and <code>SEVERITY LIMIT WAS NOT REACHED</code>.</li>
<li>J's rule: only a code of 5 stops the deck (J 02.01.01). Any code above 1
stops the run (J 90.04.02). So, <strong>under our severity table</strong>, J
punches a deck and does not run it. <strong>No 1962 severity value survives</strong>
(J 90.04.01): the 4 is our choice (D7.5).</li>
<li>Our generator stops at the first GET, statement 3,00, with
<code>a GET record on 0 input files (no sample instance)</code>. It punches an
empty deck: a 12-byte header and no cards.</li>
<li><strong>Recommendation: option 1, the listing.</strong> Keep the refusal and
relabel it &ldquo;1962 punched a deck whose content no evidence
describes&rdquo;. The other options must invent code (against D0.4) or invent
a severity.</li>
<li><strong>New since 2026-09-15:</strong> the FILE-IN decision of 2026-10-24
added a second refusal of the same kind (messages 195,00 and 22,00, our
severity 3). The design record says your answer decides both. No work is
blocked.</li>
</ol>
</section>

<section>
<p class="note"><strong>Provenance.</strong> Item 2 of the record on branch
<code>review/2026-09-14-m6s2-rule</code> (tip <code>ef57893</code>) asked this
question. On 2026-09-15 you answered the other items and kept item 2 open:
its banner records that you asked for a walkthrough of the deck reading
before you decide.
This record is that walkthrough. It re-argues nothing that record decided. Every
repository path below is at commit <code>{BASE}</code> (master, 2026-10-25).
Every run output below is captured in <code>evidence/</code>, not retyped.</p>
<p class="note"><strong>Citation forms.</strong> <code>J 02.01.01</code> cites
J28-6169 (1962) by IBM section code; <code>F p. 101</code> cites F28-8043 (1960)
by printed page. <code>D0.4</code> is a locked decision; <code>M6-9</code> an
entry in <code>docs/design/m6-acceptance.md</code>. <code>108,00</code> is a
message number; <code>5,01</code> in a listing is a statement number.
<span class="inferred">inferred</span> marks a claim that no source states.</p>
</section>

<nav class="steps" aria-label="Steps">
<a href="#step1">1 &middot; Deck in</a><a href="#step2">2 &middot; Listing</a>
<a href="#step3">3 &middot; Severity gate</a><a href="#step4">4 &middot; Deck out</a>
<a href="#step5">5 &middot; The fork</a><a href="#step6">6 &middot; Your answer</a>
</nav>

<section class="item" id="step1">
<p class="step">Step 1 of 6</p>
<h2>The deck goes in</h2>
<p>The deck is <code>test/fixtures/f-payroll.ctd</code>: 191 cards. It is F28-8043
Appendix 1, keyed from the machine listing at F p. 101 to p. 104 (M6-6). It
keeps the 1960 text whole: <code>*PROCEDURE</code> before <code>*DATA</code>,
no environment division, <code>STOP 1234</code>, a <code>COPY</code> entry, and a
level on the REDEF line.</p>
<table>
<tr><th>Cards</th><th>What they are</th></tr>
<tr><td>1</td><td><code>*COMPILE LIST</code>, the control card. A reconstruction:
the 1960 listing prints none (<code>test/fixtures/f-payroll-deck-notes.md</code>).</td></tr>
<tr><td>2</td><td><code>*PROCEDURE</code></td></tr>
<tr><td>3&ndash;82</td><td>80 procedure cards</td></tr>
<tr><td>83</td><td><code>*DATA</code></td></tr>
<tr><td>84&ndash;190</td><td>107 data cards</td></tr>
<tr><td>191</td><td><code>*FINISH</code>, also a reconstruction</td></tr>
</table>
<p>Click a card to see it punched. A red dot counts the messages the card draws.
The holes come from the canon file; the build checks that every column agrees
with the mirror text.</p>
<div class="controls"><label><input type="checkbox" id="onlyflag"> Only cards
that draw a message</label></div>
<div class="deck">
<div class="decklist" id="decklist" role="listbox" aria-label="The 191 cards"></div>
<div>
<div class="punch" id="punch"></div>
<p class="cite" id="cardcap"></p>
<ul class="oncard" id="oncard"></ul>
</div>
</div>
</section>

<section class="item" id="step2">
<p class="step">Step 2 of 6</p>
<h2>The compile reads it and prints the listing</h2>
<p>Run at {BASE}:</p>
{plate("dart run comtran:comtranc test/fixtures/f-payroll.ctd --date=06/01/60 --time=1.00 --explain")}
<p>Standard output is byte for byte <code>test/goldens/f-payroll.listing</code>
(checked with <code>cmp</code>). The listing prints all 187 source cards, then
55 messages. Our severity for each comes from our table
(<code>lib/src/lexer/severities.dart</code>, decisions D7.5 and D9.2). The table
file says it in its own words: &ldquo;EVERY value here is OUR assignment,
non-historical&rdquo;.</p>
<table>
<tr><th>Count</th><th>Id</th><th>Sev</th><th>Message</th></tr>
{kind_rows}
</table>
<p>Click a kind to list its messages. Click a message to see its card, its column
and its statement.</p>
<div class="controls"><span class="mono">Group:</span>
<button data-order="kind" aria-pressed="true">By kind</button>
<button data-order="listing" aria-pressed="false">In listing order</button></div>
<div id="kinds"></div>
<div class="inspect" id="inspect" hidden></div>
<p>The listing closes:</p>
{plate(chr(10).join(LISTING.rstrip().split(chr(10))[-4:]), "The last four lines of <code>test/goldens/f-payroll.listing</code>.")}
<p>The closing line is J's own wording. The manual prints it at the foot of its message listing:</p>
{figure("j-p185-trailer.png", "SEVERITY LIMIT WAS NOT REACHED, as printed.", "J 90.04.01, cut from <code>comtran-manuals/J28-6169/images/page-185.png</code>, box (120, 542, 388, 570), enlarged two times. The opposite wording, for a limit reached, is our decision (D7.6).")}
<details><summary class="mono">The whole listing, as printed (276 lines)</summary>
{plate(LISTING)}
</details>
<p>None of the twelve messages is worded as a stop, a deletion or a repair.
J has that vocabulary and uses it elsewhere: 2,00 &ldquo;-RUN- DELETED.&rdquo;,
171,00 &ldquo;SENTENCE DELETED FROM TEXT.&rdquo; (J 90.04.01). The compiler
completes, as J 05.06.01 says it does &ldquo;unless a catastrophic error
occurs&rdquo;.</p>
</section>

<section class="item" id="step3">
<p class="step">Step 3 of 6</p>
<h2>The severity gate</h2>
<p>Three passages decide what happens after the listing. First, what the codes
mean:</p>
{figure("j-p186-severity.png", "J 90.04.02, Severity Codes: codes 1 to 5; 1 does not prevent running; any code above 1 prevents running; 5 stops compiling.", "J 90.04.02, cut from <code>comtran-manuals/J28-6169/images/page-186.png</code>, box (225, 256, 1082, 605), enlarged two times.")}
<p>Second, the deck. Only a 5 suppresses it:</p>
{figure("j-p010-nodeck.png", "J 02.01.01, the NODECK option: normally an output deck is produced; if the severity code is 5, a deck will not be produced.", "J 02.01.01, the NODECK option, cut from <code>comtran-manuals/J28-6169/images/page-010.png</code>, box (290, 1028, 1062, 1260), enlarged two times.")}
<p>Third, the run. Two separate bars stop it:</p>
{figure("j-p011-load.png", "J 02.01.02, the LOAD option: the program will be executed unless NOGO, or a source error above severity 1, or an undefined symbol in the generated code.", "J 02.01.02, the LOAD option, cut from <code>comtran-manuals/J28-6169/images/page-011.png</code>, box (274, 240, 1120, 492), enlarged two times.")}
<p>And the catch: the manual prints no severity for any message.</p>
{figure("j-p181-may-vary.png", "J 90.04.01: the code number is 0 because the value may vary; one of the values 1 through 5 will be printed.", "J 90.04.01, cut from <code>comtran-manuals/J28-6169/images/page-181.png</code>, box (228, 230, 1082, 370), enlarged two times. Open Question 65 records that no severity table survives.")}
<h3>Our codes for this deck</h3>
<table class="sevtab"><tr><th>Code</th><th>Messages</th><th></th></tr>{sev_rows}</table>
<p>Pick a highest code to see what J's three passages do with it. Only 5
changes the deck.</p>
<div class="controls"><span class="mono">Highest code:</span>
<button data-sev="1">1</button><button data-sev="2">2</button>
<button data-sev="3">3</button><button data-sev="4">4 (ours)</button>
<button data-sev="5">5</button></div>
<div class="gate">
<div id="g-compile"><span class="k">Compilation</span><span class="v"></span><span class="w"></span></div>
<div id="g-deck"><span class="k">Object deck</span><span class="v"></span><span class="w"></span></div>
<div id="g-run"><span class="k">Run after compile</span><span class="v"></span><span class="w"></span></div>
</div>
<p class="note" id="g-note"></p>
<p><strong>So, under our table, J's letter punches a deck and does not run
it.</strong> That conclusion is only as firm as the 4. If any one of the twelve
kinds carried a 5 in 1962, no deck was punched. No evidence settles that.</p>
<p>Two smaller points. Our control card asks for <code>LIST</code> only, not
<code>LOAD</code>, so it asks for no run in any case; the card is our
reconstruction (D7.12). And J 02.01.02's &ldquo;undefined symbol in the code
which it has generated&rdquo; is a bar on generated code. Message 108,00 reports
an undefined name in the source. Whether the 26 source names became undefined
generated symbols is not stated. <span class="inferred">inferred</span></p>
<p>Open Question 66 already asks the next question: &ldquo;Does a severity 2&ndash;4
error make the punched object deck unreliable, or merely suppress automatic
execution?&rdquo; (<code>docs/comtran-language-definition.md</code>).</p>
</section>

<section class="item" id="step4">
<p class="step">Step 4 of 6</p>
<h2>What the deck would hold</h2>
<h3>What we know</h3>
<ul>
<li>The format. J 90.03 gives the object deck format and J 90.08 the loader
cards. Our deck writer punches the 1962 sample's deck in that format
(<code>docs/HANDOVER.md</code>, M4 stage 3).</li>
<li>The deck exists under our table (step 3), and it is not run.</li>
</ul>
<h3>What no evidence describes</h3>
<p>The listing itself names the sites. Each one needs code that no listing, no
sample and no manual page shows:</p>
{sites}
<p>M6-8's summary of the same ground: &ldquo;It held a GET on a record bound to
no file, 26 undefined names, and a GRAND.TOTAL left empty because COPY was
deferred.&rdquo; The phrase &ldquo;left empty&rdquo; is M6-8's reading, not J's
words.</p>
<h3>Where our generator stops today</h3>
<p>The same run as step 2, with the stage dumps on:</p>
{plate("dart run comtran:comtranc test/fixtures/f-payroll.ctd --date=06/01/60 --time=1.00 \\\n    --explain --emit-code=run.code --emit-object=run.object --emit-deck=run.deck.ctd")}
<p>Standard error ends, and the exit status is 1:</p>
{plate(REFUSAL[0], "<code>evidence/run.stderr</code>, last line; <code>evidence/run.exit</code>.")}
<p>The assembly dump, the object listing and the punched deck, whole:</p>
{plate(RUN_CODE, "<code>evidence/run.code</code>")}
{plate(RUN_OBJECT, "<code>evidence/run.object</code>")}
{plate(RUN_XXD, "<code>evidence/run.deck.ctd</code> through <code>xxd</code>: the magic, the version, and a card count of 0. No cards.")}
<p>The refusal fires at statement 3,00, <code>GET MASTER</code>. No FILE card
lists MASTER, so it has zero input files:</p>
{plate(GET_GUARD, "<code>lib/src/codegen/procedure.dart</code> lines 1905 to 1925 at " + BASE + ".")}
<p>A job stops at its first refusal (M6-8), so the generator never reaches the
later sites in the table above. The refusal class states its own scope:</p>
{plate(SHAPE_DOC, "<code>lib/src/codegen/procedure.dart</code> lines 139 to 155 at " + BASE + ".")}
<p>Note the mismatch. The class says it fires where &ldquo;no J 90.04 message
and no severity fits&rdquo;. Here a message did fire on the same statement:
9,00 at 3,01. The class text fits a shape the 1962 sample never used, not a
program that already drew a diagnostic. M6-9's relabel names the shape label;
on our reading it would reach this comment too.
<span class="inferred">our reading</span></p>
</section>

<section class="item needs" id="step5">
<p class="step">Step 5 of 6</p>
<div class="itemhead"><span class="chip call">Your call</span>
<h2>The fork</h2></div>
<p>Two readings of &ldquo;it should compile&rdquo;. Each is a fair reading of
your rule.</p>
<div class="fork">
<div class="panel rec">
<h3>Compile = the listing</h3>
<p class="opt pick"><span class="name">Option 1 &middot; recommended</span></p>
<dl>
<dt>What it says</dt><dd>To compile is to read the deck and print the
listing. Under J's letter 1962 would have done that, and we do it, to the
byte.</dd>
<dt>What the compiler must do</dt><dd>Nothing new. Keep the refusal. Relabel
it: &ldquo;1962 punched a deck whose content no evidence describes&rdquo;, not
&ldquo;1962 refused&rdquo;.</dd>
<dt>What it must invent</dt><dd>Nothing.</dd>
<dt>What breaks</dt><dd>Nothing.</dd>
<dt>Left unbuilt</dt><dd>The object form of a program that could never run.</dd>
<dt>What a later reader is misled about</dt><dd>Nothing, once the label is
fixed. Today's label is the one thing that misleads.</dd>
<dt>Cost to reverse</dt><dd>One edit to M6-9 and one to the corpus test's
comment (the 2026-09-14 record's costing), plus the refusal class comment on
our reading of step 4.</dd>
</dl>
</div>
<div class="panel">
<h3>Compile = the object deck</h3>
<dl>
<dt>What it says</dt><dd>To compile in 1962 was to punch a deck. J 02.01.01
ties the deck to the severity code alone. A compiler that stops short of the
deck has not compiled.</dd>
</dl>
<div class="sub">
<p class="opt"><span class="name">Option 2 &middot; build the deck</span></p>
<dl>
<dt>What the compiler must do</dt><dd>Generate code for every site of step 4:
GET and FILE on records with no file, FILE IN a name that is no file, 26
undefined names, an empty GRAND.TOTAL.</dd>
<dt>What it must invent, against which decision</dt><dd>All of it. D0.4: where no
evidence survives, behaviour is &ldquo;a recorded design decision &hellip;
never presented as historical fact&rdquo;. Here there is not even a shape to
record.</dd>
<dt>What a later reader is misled about</dt><dd>The deck would look like a
recovery and would be a guess.</dd>
<dt>Cost to reverse</dt><dd>Delete that code and its golden.</dd>
</dl>
</div>
<div class="sub">
<p class="opt"><span class="name">Option 3 &middot; rule a severity of 5</span></p>
<dl>
<dt>What the compiler must do</dt><dd>Raise one of the twelve kinds to 5. Then
J stops the compile, no deck is due, and the refusal is right for the right
reason.</dd>
<dt>What it must invent, against which decision</dt><dd>The 5. J 90.04.01
prints 0 for every message (Open Question 65). D7.5 documents the table
&ldquo;as a recorded design decision, never as recovered historical
fact&rdquo;.</dd>
<dt>What a later reader is misled about</dt><dd>A severity that reads as
recovered and was chosen. The listing would also change: it would close
<code>SEVERITY LIMIT WAS REACHED</code>, a wording that is itself our decision
(D7.6).</dd>
<dt>Cost to reverse</dt><dd>One row of the severity table and one golden
rebuild.</dd>
</dl>
</div>
</div>
</div>

<div class="ask"><span class="label">Recommendation</span>
<p><strong>Option 1.</strong> M6-9: &ldquo;Keep the refusal for the verbatim
deck, and relabel it. The honest label is &lsquo;1962 punched a deck whose
content no evidence describes&rsquo;, not &lsquo;1962 refused&rsquo;. Take the
listing as the deliverable of that deck.&rdquo; The reason: it is the only
option that states what the evidence supports and invents nothing. The deck is
real under J's letter; its content is not recoverable, and saying so is the
finding.</p></div>

<h3>The second case: FILE IN a file the record is not on</h3>
<p>Decided 2026-10-24 (M6-9): the generator compiles <code>FILE record IN
file</code>. Where the Environment Description does not tie the record to that
file, J 02.07.08 2 a is broken, the front end prints a message, and the
generator refuses. These are the two messages:</p>
{figure("j-p185-msg195.png", "Message 195,00: CANNOT FILE RECORD NAME.2 IN THIS FILE, NAME.1, BECAUSE ENVIRONMENT FILE CARD LACKS THIS RECORD NAME.", "J 90.04.01, message 195,00, cut from <code>comtran-manuals/J28-6169/images/page-185.png</code>, box (148, 301, 820, 344), enlarged two times. The page is skewed, so the neighbouring rows show at the edges.")}
{figure("j-p181-msg21-22.png", "Messages 21,00 and 22,00: NAME.1 IS NOT A FILE; NAME.1 IS NOT AN OUTPUT FILE.", "J 90.04.01, messages 21,00 and 22,00, cut from <code>comtran-manuals/J28-6169/images/page-181.png</code>, box (268, 932, 935, 961), enlarged two times. 22,00 fires when the IN file is an input file. The page is skewed, so the neighbouring rows show at the edges.")}
<p>Our severity for both is 3 (<code>severities.dart</code>). The refusal and its test:</p>
{plate(FILE_GUARD, "<code>lib/src/codegen/procedure.dart</code> lines 1968 to 1993 at " + BASE + ".")}
{plate(FILE_IN_TEST, "<code>test/codegen_refusal_test.dart</code> lines 1105 to 1116 at " + BASE + ".")}
<p>M6-9 puts it under this question in terms: &ldquo;At severity 3 the 1962
processor punched a deck and did not run it ([J 90.04.02]). The case is the
verbatim deck's case: a listing exists, and no evidence describes the deck. His
answer decides both refusals.&rdquo;</p>
<table>
<tr><th></th><th>Verbatim 1960 deck</th><th>FILE IN, wrong file</th></tr>
<tr><td>Message</td><td>9,00 at 3,00 (and 54 more)</td><td>195,00 or 22,00</td></tr>
<tr><td>Our highest code</td><td>4</td><td>3</td></tr>
<tr><td>J's letter, under our codes</td><td>deck punched, not run</td><td>deck punched, not run</td></tr>
<tr><td>Our refusal</td><td><code>a GET record on 0 input files</code></td><td><code>FILE record IN a file that is not an output file of the record</code></td></tr>
<tr><td>Option 1</td><td colspan="2">keep both refusals, relabel both</td></tr>
<tr><td>Option 2</td><td colspan="2">invent the call for both</td></tr>
<tr><td>Option 3</td><td>raise one of twelve kinds to 5</td><td>raise 195,00 and 22,00 to 5</td></tr>
</table>
<p>The verbatim deck itself meets a third form at statement 6,00, <code>FILE
MASTER IN ERROR.FILE</code>, where ERROR.FILE is no file at all (21,00, our
severity 3). The generator never gets there today.</p>
</section>

<section class="item needs" id="step6">
<p class="step">Step 6 of 6</p>
<div class="itemhead"><span class="chip call">Your call</span>
<h2>Your answer</h2></div>
<p>Does &ldquo;compile&rdquo; in your rule of 2026-09-14 mean the diagnostic
listing, or the object deck? One answer covers both cases.</p>
<div class="pick">
<label><input type="radio" name="opt" value="Option 1, the listing (keep both refusals, relabel them)">
<strong>Option 1. The listing.</strong> Recommended. Keep both refusals and
relabel them. Nothing is invented.</label>
<label><input type="radio" name="opt" value="Option 2, the object deck: build it">
<strong>Option 2. The object deck: build it.</strong> Generate code for every
site. Breaks D0.4.</label>
<label><input type="radio" name="opt" value="Option 3, the object deck: rule a severity of 5">
<strong>Option 3. The object deck: rule a 5.</strong> Raise a severity so no deck
is due. The 5 is unattested.</label>
</div>
<p class="mono">Anything else (a split between the two cases, or a different
reading):</p>
<textarea id="anote" aria-label="Your note"></textarea>
<div class="controls"><button id="copy" type="button">Copy my answer</button></div>
<div class="plate"><pre id="aout"></pre></div>
<p class="note">Your answer lands in this record as a dated banner, in a second
commit on this branch. It also authorizes the pull request that carries the
relabel or the change (review-records rule 7).</p>
</section>

<footer>
<p>Record built 2026-10-25 on branch
<code>review/2026-10-25-m6s2-deck-walkthrough</code>, from the repository at
<code>{BASE}</code>. <code>tools/build_doc.py</code> writes this page from
<code>evidence/</code> and <code>crops/</code>, and stops if the deck, the
mirror, the listing and the run disagree. Edit it, not the HTML.
<code>README.md</code> says what each directory holds.</p>
<p>This record carries no repository hyperlink. Every path is given as a path
at {BASE}, and every quotation is printed in full.</p>
</footer>

</main>
<script type="application/json" id="data">{json.dumps(DATA, separators=(",", ":")).replace("</", "<\\/")}</script>
<script>{JS}</script>
</body>
</html>
"""

HTML = HTML.replace("<table", '<div class="scroll"><table').replace("</table>", "</table></div>")
assert HTML.count('class="scroll"') == HTML.count("<table")
with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB; "
      f"{len(MESSAGES)} messages, severities {dict(sorted(SEVS.items()))}")
