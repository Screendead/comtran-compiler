"""Build index.html for review/2026-10-25-codegen-defects-8-11.

Reads the two probe captures in evidence/ and the crops in crops/, and
writes a standalone index.html beside this directory. Every image is a
data: URI. Run: python3 tools/build_doc.py (from anywhere).
"""

import base64
import html
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

TODAY_SHA = "fca3157"
HANDLE_SHA = "8eb359a"
HANDLE_FULL = "8eb359a4aae938ae4db64acd12b28370b08435bb"
ALIGN12 = "bebe2ab"
TESTS = 1455
BLOB = f"https://github.com/Screendead/comtran-compiler/blob/{TODAY_SHA}"

today = json.load(open(os.path.join(REC, "evidence", f"today-{TODAY_SHA}.json")))
handle = json.load(open(os.path.join(REC, "evidence", f"handle-{HANDLE_SHA}.json")))

R8 = "a subscripted internal-decimal target (no sample instance)"
R8E = "a subscripted edited-store target (no sample instance)"
R9 = "a SET or ADD into a subscript variable (no sample instance)"
R10 = "a subscript-store base inside a word (no sample instance)"
R11 = "a sub-chain in a chain after a parked term (no sample instance)"

# One row per probe program. right maps each reported field to the value
# a correct program leaves there.
CASES = [
    dict(id="D8-int-int", defect=8,
         title="Internal source into a subscripted internal target",
         decl="TAB: 3 elements of CELL IR 999; I IR 9 moved to 2; NUM IR 999 set to 7",
         stmt="MOVE NUM TO CELL (I)",
         right={"TAB": 0, "TAB+1": 7, "TAB+2": 0},
         why="Element 2 takes the 7. Today element 1 takes it.",
         refuse=R8),
    dict(id="D8-ext-int", defect=8,
         title="External source into a subscripted internal target",
         decl="EXT E 999 holds 007; the rest as above",
         stmt="MOVE EXT TO CELL (I)",
         right={"TAB": 0, "TAB+1": 7, "TAB+2": 0},
         why="The convert is right today; only the store address is wrong.",
         refuse=R8),
    dict(id="D8-int-edited", defect=8,
         title="Internal source into a subscripted edited target",
         decl="ETAB: 3 elements of EDT 888889; I moved to 2; NUM set to 7",
         stmt="MOVE NUM TO EDT (I)",
         right={"ETAB": "000000", "ETAB+1": "     7"},
         why="Element 2 takes the edited 7. Today element 1 takes it. Both options refuse this arm: "
             "SYS)180 takes its target from an in-line PZE word that no site builds from an indicator.",
         refuse=R8E, built_refusal=True),
    dict(id="D9-set", defect=9,
         title="SET of a value into the index",
         decl="A: 3 elements, E 9(6), holding 1, 2, 3; I IR 9 moved to 1",
         stmt="SET I = 3, then MOVE A (I) TO WA",
         right={"I": 3, "WA": 3},
         why="I is 3, so A (I) is element 3. Today the indicator stays on element 1.",
         refuse=R9),
    dict(id="D9-add", defect=9,
         title="ADD into the index",
         decl="as above; TWO IR 9 set to 2",
         stmt="ADD TWO TO I, then MOVE A (I) TO WA",
         right={"I": 3, "WA": 3},
         why="1 + 2 = 3.",
         refuse=R9),
    dict(id="D9-increment", defect=9,
         title="SET K = K + c, the manual's own example shape",
         decl="as above",
         stmt="SET I = I + 2, then MOVE A (I) TO WA",
         right={"I": 3, "WA": 3},
         why="J 02.04.07.01 names SET K=K+2 as the store that updates the indicators.",
         refuse=R9),
    dict(id="D10-one", defect=10,
         title="A store driving one indicator, over a field at byte 2",
         decl="TAB: 12 items of A 99, B 9999, C 9(6) (two words); item k holds B = k; IDX moved to 3",
         stmt="MOVE B (IDX) TO NB",
         right={"NB": 3},
         why="Today the pointer reads from byte 0: A's 03 and B's first 00, so 300.",
         refuse=R10),
    dict(id="D10-two", defect=10,
         title="A store driving two indicators, the sample's shape",
         decl="TABLE.ITEM: RATE 9(6), INSPREM 9V99 at byte 0, RETPREM 9V99 at byte 3; item 3 holds 3.11 and 3.22; POS moved to 3",
         stmt="MOVE INSPREM (POS) TO WI, MOVE RETPREM (POS) TO WR",
         right={"WI": 311, "WR": 322},
         why="This is M6-4 finding 1 in a small program. Every option that keeps the golden leaves it wrong.",
         refuse=None),
    dict(id="D11-sum", defect=11,
         title="A sub-chain as a term",
         decl="NUM IR 999 set to 5; X IR 9(5)",
         stmt="SET X = NUM * 2 + (NUM * 3 + 1)",
         right={"X": 26},
         why="10 + 16. Today both products park in RS)1: 15 + 16 = 31.",
         refuse=R11),
    dict(id="D11-product", defect=11,
         title="A sub-chain inside a product",
         decl="as above",
         stmt="SET X = NUM * 2 + (NUM * 3 + 1) * 2",
         right={"X": 42},
         why="10 + 32. Today 15 + 32 = 47.",
         refuse=R11),
]

BASE = re.compile(r"^PZE [A-Z0-9.]+-\d")


def view(case, run):
    if "refusal" in run:
        return dict(words=[], pool=[], values=None,
                    refusal=run["refusal"].replace("unrecovered shape: ", ""))
    vals = run["values"]
    return dict(
        words=run["words"],
        pool=[p for p in run.get("pool", []) if BASE.match(p)],
        values=vals,
        ok=all(vals.get(k) == v for k, v in case["right"].items()),
        refusal=None,
    )


DATA = []
for c in CASES:
    t = view(c, today[c["id"]])
    h = view(c, handle[c["id"]])
    if c["refuse"] is None:
        r = dict(t, note="Refuse keeps the sample's words here: the sample has this shape.")
    elif c.get("built_refusal"):
        r = dict(h)
    else:
        r = dict(words=[], pool=[], values=None, refusal=c["refuse"], proposed=True)
    DATA.append(dict(
        id=c["id"], defect=c["defect"], title=c["title"], decl=c["decl"],
        stmt=c["stmt"], right=c["right"], why=c["why"],
        today=t, refuse=r, handle=h,
    ))


def img(name, alt, caption):
    with open(os.path.join(REC, "crops", name), "rb") as fh:
        b64 = base64.b64encode(fh.read()).decode("ascii")
    return (
        f'<figure><div class="scan"><img src="data:image/png;base64,{b64}" '
        f'alt="{html.escape(alt)}"></div><figcaption>{caption}</figcaption></figure>'
    )


def toggle(defect):
    return f"""
<div class="toggle" role="group" aria-label="Defect {defect} view">
<button type="button" data-defect="{defect}" data-view="today" aria-pressed="true">Today ({TODAY_SHA})</button>
<button type="button" data-defect="{defect}" data-view="refuse" aria-pressed="false">Refuse</button>
<button type="button" data-defect="{defect}" data-view="handle" aria-pressed="false">Handle ({HANDLE_SHA})</button>
</div>
<div class="cases" id="cases{defect}"></div>"""


CSS = open(os.path.join(HERE, "house.css")).read() + """
.pool { font-family:var(--mono); font-size:.72rem; color:var(--muted); margin:.35rem 0 0; white-space:pre; overflow-x:auto; }
a { color:var(--ink); text-decoration-color:var(--rule); }
.settle td:first-child { font-family:var(--mono); min-width:9rem; }
"""

ANSWER_DEFECTS = [
    ("d8", "Defect 8, subscripted MOVE target"),
    ("d9", "Defect 9, SET or ADD into a subscript variable"),
    ("d11", "Defect 11, sub-chain cells"),
]

overrides = "\n".join(f"""<fieldset class="pick"><legend>{label}</legend>
<label><input type="radio" name="{n}" value="follow" checked> Follow the combined answer.</label>
<label><input type="radio" name="{n}" value="handle"> <strong>Handle</strong> (the prototype).</label>
<label><input type="radio" name="{n}" value="refuse"> <strong>Refuse.</strong></label>
</fieldset>""" for n, label in ANSWER_DEFECTS)

PAGE = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Codegen defects 8 to 11</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<button id="theme" type="button" aria-label="Switch light or dark">Light / dark</button>
<p class="eyebrow">Review record &middot; codegen defects 8 to 11 &middot; evidence 2026-10-25 &middot; master at {TODAY_SHA} &middot; prototype at {HANDLE_SHA}</p>
<h1>Four shapes that compiled in 1962 and compute wrong values here: refuse them, or handle them</h1>
<p class="standfirst">Each defect compiles today and stores a wrong number with no message. The handle prototype is built,
tested and pushed. One combined question below would settle every open refuse-or-handle defect, 1 to 11.</p>
</header>

<section>
<div class="answer">
<ol>
<li><strong>All four defects give wrong values today, with no message.</strong> On our machine at {TODAY_SHA}:
<code>MOVE NUM TO CELL (I)</code> with I = 2 writes element 1; <code>SET I = 3</code> leaves A (I) on element 1;
B (IDX) reads 300 for 3; <code>NUM * 2 + (NUM * 3 + 1)</code> gives 31 for 26. Ten probe programs, all captured.</li>
<li><strong>Handle is built</strong> on <code>defects-8-11-handle</code> at <code>{HANDLE_SHA}</code>. Nine of the ten probes now give the
right value; the edited-target probe refuses. {TESTS} tests pass. Every golden is byte-identical, <code>90.05-payroll.code</code>
included, and the 1960 applied deck still compiles to its object deck.</li>
<li><strong>Two parts stay as they are under handle.</strong> A subscripted <em>edited</em> target refuses: no site builds
SYS)180's target word from an indicator. A subscript store that drives <em>several</em> indicators keeps the 1962 words,
which drop the byte. The golden needs those words at LOC 01742 (<code>PZE RETPREM-2</code>).</li>
<li><strong>Recommendation: answer the combined question yes, take the prototype, and take boundary A for defect 10.</strong>
J 02.04.07.01 uses <code>SET K=K+2</code> as its own example of a store that updates indicators, so a refusal of defect 9
refuses the manual's example.</li>
</ol>
</div>
</section>

<section class="item needs" id="combined">
<div class="itemhead"><span class="chip call">Your call</span><h2>The combined question</h2></div>
<div class="ask"><span class="label">One answer for every open defect</span>
<p><strong>Under the 2026-09-14 rule, handle wherever attested words exist, and refuse only where none do &mdash; yes or no?</strong></p>
<p>&ldquo;Attested words&rdquo; means every word of the generated sequence occurs in the 1962 sample listing or in J 90.02, in the same
role. A join between two attested words that the sample never shows is allowed; the probe runs test each join.</p>
</div>

<h3>For yes</h3>
<ul>
<li>Your rule: &ldquo;if it would compile in 1962, it should compile. If it wouldn't, it shouldn't.&rdquo; (<code>docs/design/m6-acceptance.md</code>, M6-9.)
All ten shapes are plain COMTRAN. F and J admit each one. A search of J 90.01 for subscript, positional, array,
parenthes, nest, expression and receiving finds no restriction on any of them. So a refusal is stricter than
the 1962 processor.</li>
<li>Defect 9 is the sharpest case. J 02.04.07.01 says the code for <code>SET K=K+2</code> updates the indicators, and J 90.02.05 prints
the words. M4-10 already orders the update &ldquo;eagerly at the store site&rdquo;. Today's code disagrees with its own design record.</li>
<li>The handled sequences reuse sample words. Precedent: PR #143 (comparisons) and the defects 1 and 2 prototype took the same course.</li>
</ul>
<h3>For no</h3>
<ul>
<li>M6-9 says whether a shape compiled, not which words it compiled to. Where the sample has no instance of the shape, the 1962 words
are unknown. Evidence exists and is sealed until M7. A refusal states that gap honestly; a reconstruction can be wrong in a way M7 then has to measure.</li>
<li>Defect 10 shows the risk. There the attested words <em>are</em> wrong, so &ldquo;attested&rdquo; and &ldquo;right&rdquo; can part.</li>
<li>Defect 11's prototype adds no new operation or form, but the cell choice (skip a parked cell) has no instance anywhere, and
<code>RS)2</code> itself never prints in the sample. It is our design.</li>
</ul>
<p><strong>Recommendation: yes.</strong> No changes the sample or the corpus less than yes does: both leave every golden as it stands. No refuses
about ten shapes that F or J show, among them the manual's own <code>SET K=K+2</code>. Yes keeps a refusal wherever no attested sequence
exists, so the honest-gap argument still holds at those sites.</p>

<h3>What each answer settles</h3>
<div class="scroll"><table class="settle">
<thead><tr><th>Defect</th><th>Attested words?</th><th>Yes gives</th><th>No gives</th><th>How known</th></tr></thead>
<tbody>
<tr><td>1 MOVE scales</td><td>yes</td><td>align (prototype <code>{ALIGN12}</code>)</td><td>refuse</td><td>record <code>review/2026-10-25-codegen-defects-1-2</code>, probes</td></tr>
<tr><td>2 edited ADD scales</td><td>yes</td><td>align (same prototype)</td><td>refuse</td><td>the same record</td></tr>
<tr><td>3 S counted as a character</td><td>yes: the same words with the storage count</td><td>handle</td><td>refuse a numeric source with an S</td><td><span class="inferred">inferred</span> from the HANDOVER entry; not probed</td></tr>
<tr><td>4 STO through an overwritten register</td><td>yes: the same words, the base load after the convert</td><td>handle</td><td>refuse</td><td><span class="inferred">inferred</span> from the HANDOVER entry; not probed</td></tr>
<tr><td>5 a leading run of 8 and *</td><td>no: the control word has one address field</td><td>refuse</td><td>refuse</td><td>HANDOVER entry; RT-5 open item</td></tr>
<tr><td>6 reopen after CLOSE ALL FILES</td><td>not a compile question: J forbids it</td><td>the D6.3 diagnostic</td><td>the D6.3 diagnostic</td><td>D6.3 (Locked) already decides it</td></tr>
<tr><td>8 subscripted MOVE target</td><td>yes for an internal target; no for an edited target</td><td>handle two arms, refuse the edited arm</td><td>refuse all three</td><td>probes</td></tr>
<tr><td>9 SET or ADD into an index</td><td>yes</td><td>handle</td><td>refuse</td><td>probes</td></tr>
<tr><td>10 base byte</td><td>yes for one indicator; for several, the attested words drop the byte</td><td>handle one; several stay (boundary below)</td><td>refuse one; several stay</td><td>probes</td></tr>
<tr><td>11 sub-chain cells</td><td>yes: words; the cell choice is ours</td><td>handle</td><td>refuse</td><td>probes</td></tr>
</tbody></table></div>
<p class="consequence">Neither answer settles defect 10's several-indicator stores, because there the attested words are the defect. That boundary is a separate choice in the answer box.
Defects 3 and 4 have no prototype yet; yes means build one under the same test bar. Cost of yes: two prototype branches to merge. They conflict
mechanically in <code>procedure.dart</code> and two test files (<code>git merge-tree</code>), so the second rebases. Each defect is then one revert away.
Cost of no: about ten new refusals, each a one-commit change to reverse later.</p>
</section>

<section class="item needs" id="d8">
<div class="itemhead"><span class="chip call">Your call</span><h2>Defect 8. A subscripted MOVE target loses its subscript</h2></div>
<p><code>_moveUnit</code> (<a href="{BLOB}/lib/src/codegen/procedure.dart#L2232-L2287">procedure.dart:2232</a>) takes
<code>targetSubscripted</code> and passes it to neither internal-decimal arm, nor to the external-to-internal arm. Each emits a plain
<code>STO CELL</code>, so every pass writes element 1. The sample's subscripted moves are sources only.</p>
<p>The words the prototype uses are the comparand's, from the sample (<code>evidence/golden-cited-words.txt</code>):</p>
<pre class="words">01407  CLA 1)RATE,1      the accumulator holds a value
01410  LAC PI)1,2        the indicator into register 2
01411  TXL SYS)294,2,0   the guard on an unset indicator
01412  CAS 0,2           the element the register reaches</pre>
<p>The prototype emits the same prologue and <code>STO 0,r</code> in place of <code>CAS 0,r</code>. <code>LAC</code> and <code>TXL</code> leave the accumulator alone, as 01407&ndash;01412 shows.
For an external source the prologue follows the convert's <code>TXI SYS)184,1,3</code>; that join has no sample instance <span class="inferred">inferred safe</span>, and the probe run tests it.</p>
{toggle(8)}
<h3>The options</h3>
<div class="opt"><h3>Refuse</h3>
<p>The internal and external arms refuse <code>{R8}</code> <span class="inferred">proposed text, not built</span>.</p>
<p class="consequence">Breaks nothing known: no corpus program has the shape. A later reader sees a refusal of a store into an array element,
which every COMTRAN table program needs. To reverse: delete the check, build the store.</p></div>
<div class="opt pick"><h3>Handle (recommended)</h3>
<p>Internal and external sources store through the indicator. The edited target refuses <code>{R8E}</code> under both options.</p>
<p class="consequence">Breaks nothing: {TESTS} tests, goldens byte-identical. Same whole-word limit as the comparand: a stride that is not whole
words refuses (<code>a whole-word read of an element whose stride is n characters (M6-9)</code>). To reverse: revert the hunk in
<code>_moveUnit</code>, <code>_internalMove</code> and the new <code>_elementStore</code>.</p></div>
</section>

<section class="item needs" id="d9">
<div class="itemhead"><span class="chip call">Your call</span><h2>Defect 9. A SET or ADD into a subscript variable moves no indicator</h2></div>
<p><code>_subscriptRecomputation</code> (<a href="{BLOB}/lib/src/codegen/procedure.dart#L2520">procedure.dart:2520</a>) has one caller, the MOVE.
The manual says the update follows every change of a subscript, and names SET:</p>
{img("j-02.04.07.01-set-k.png", "J 02.04.07.01: Execution of the code generated for SET K=K+2 would cause the positional indicators to be updated", "J 02.04.07.01 (PDF 26). Scan crop.")}
{img("j-90.02.05-pi-step.png", "J 90.02.05: When a CT operation such as SET causes a subscript to change value, the corresponding positional indicator is modified. CLA CP)+1 ADD PI)6 STO PI)6", "J 90.02.05 (PDF 143), section IV. Scan crop.")}
<p>M4-10 (<code>docs/design/m4-codegen.md</code>) already designs it: &ldquo;A SET whose target is a subscript variable updates the affected positional
indicators eagerly at the store site&rdquo;, a constant increment by <code>CLA CP)+n / ADD PI)n / STO PI)n</code>, any other store by the
recomputation of LOC 01421&ndash;01425. The prototype does exactly that, after every SET and every ADD target. The DO FOR's own step at
LOC 00714&ndash;00716 is the constant form. J 90.01.02 says it twice more: &ldquo;When a subscript changes value, all positional
indicators containing that subscript will be re-evaluated&rdquo;, and, after <code>SET I = 3, SET J = 5.</code>, &ldquo;the positional
indicator for A(I,J) is computed when I and J are set&rdquo;.</p>
{toggle(9)}
<h3>The options</h3>
<div class="opt"><h3>Refuse</h3>
<p>SET and ADD into a subscript variable refuse <code>{R9}</code> <span class="inferred">proposed text, not built</span>.</p>
<p class="consequence">Refuses J's own example. Leaves M4-10's design unbuilt while M4-10 says it is the rule. To reverse: one commit.</p></div>
<div class="opt pick"><h3>Handle (recommended)</h3>
<p>Every SET (figurative fill included) and every ADD target is followed by the update. <code>SET K = K + c</code>, with c an integer
literal and K of scale 0, takes the constant form; anything else recomputes.</p>
<p class="consequence">Two changes for an external-decimal index. <code>SET EXI = 3</code> now refuses
<code>an external-decimal subscript variable (M6-9)</code>, as a MOVE into it already did; before, it compiled and moved no indicator.
<code>SET EXI = EXI + 1</code> compiles to the constant form, which reads no binary index. Both are pinned
(<code>codegen_refusal_test.dart</code>, <code>codegen_test.dart</code>). To reverse: delete the calls.</p></div>
</section>

<section class="item needs" id="d10">
<div class="itemhead"><span class="chip call">Your call</span><h2>Defect 10. The subscript store's base drops the field's byte</h2></div>
<p>The recomputation adds a base word <code>NAME-n</code> with a zero decrement. A reader through SYS)132 then reads from byte 0 of the word.
The manual says an indicator holds the byte, and gives the base word's form with it:</p>
{img("j-02.04.07-word-and-byte.png", "J 02.04.07: A positional indicator contains the location (word and byte) of the particular element", "J 02.04.07 (PDF 25). Scan crop.")}
{img("j-90.02.05-base-locator.png", "J 90.02.05: The form of a Base Locator word is PZE LOC,,BYTE", "J 90.02.05 (PDF 143). A base locator, not an indicator base; the same pointer-word form. Scan crop.")}
<p>The sample's own site is the problem. In TABLE.ITEM, INSPREM is at byte 0 and RETPREM at byte 3 of the element's second word (measured
from our data map, <code>evidence/sample-table-bytes.txt</code>). The 1962 listing gives both bases the same word, <code>01742 PZE RETPREM-2 000000000134</code> and
<code>01743 PZE INSPREM-2 000000000134</code>. That is M6-4 finding 1, the 1962 processor's own defect, and the golden needs it. A general
fix writes <code>000003000134</code> at 01742 and moves the golden. So a fix needs a boundary.</p>
<p><strong>The prototype's boundary (A):</strong> a store that drives one indicator carries the byte, <code>PZE B-2,,2</code>, the form the DO FOR base
already uses (<code>PZE I+0,,5</code>, M6-9). A store that drives several keeps the 1962 words. The several-indicator block is already
&ldquo;fitted to the one site&rdquo; by M4-6's ordering rule, so the new boundary falls on an existing one. Probe D10-two shows what it costs.</p>
{toggle(10)}
<h3>The options</h3>
<div class="opt pick"><h3>A. One indicator carries the byte; several keep the 1962 words (built, recommended)</h3>
<p class="consequence">Fixes every one-indicator store. A several-indicator store over a field inside a word stays wrong, silently, exactly
as in 1962. A later reader must be told the boundary is fitted; the code comment says so. To reverse: one line.</p></div>
<div class="opt"><h3>B. Refuse one indicator over a field inside a word; several keep the 1962 words</h3>
<p>Refuse <code>{R10}</code> <span class="inferred">proposed text, not built</span>.</p>
<p class="consequence">Turns the fixable case into a refusal and leaves the unfixable case silent. Worse than A on both counts.</p></div>
<div class="opt"><h3>D. Narrower: keep the zero decrement only where the field shares its element word with another field the same store drives</h3>
<p class="consequence">Not built. Keeps the sample (RETPREM shares its word with INSPREM) <span class="inferred">inferred</span>, and fixes several-indicator
stores whose fields sit in separate words. A more fitted rule, guessing at the 1962 mechanism, which is sealed until M7.</p></div>
<div class="opt"><h3>C. Carry the byte everywhere and move the golden</h3>
<p class="consequence">The only right answer for every program, and it breaks the oracle: <code>90.05-payroll.code</code> changes at 01742,
the run's RET.PREM column changes, and M6-4's finding 1 stops reproducing. HANDOVER bars it: &ldquo;each fix must leave
<code>test/goldens/90.05-payroll.code</code> as it stands&rdquo;. Listed for completeness.</p></div>
</section>

<section class="item needs" id="d11">
<div class="itemhead"><span class="chip call">Your call</span><h2>Defect 11. A sub-chain overwrites the outer chain's park</h2></div>
<p>The arm <code>BinaryExpr() when _additive(term)</code> (<a href="{BLOB}/lib/src/codegen/procedure.dart#L3023">procedure.dart:3023</a>) calls
<code>_chain</code>, whose cells start at 0. M4-10 rule b numbers a park by &ldquo;the cell its later operands count&rdquo;. Both chains
apply it from 0, so the inner chain's first park lands on the outer's <code>RS)1</code>. Every word involved is in the sample
(LOC 00621&ndash;00626: <code>STQ RS)1+0 &hellip; STQ RS)0 / CLA RS)1 / SUB RS)0</code>).</p>
<p><strong>The prototype:</strong> a chain numbers its cells by the M4-10 rule, counted over the cells that hold no park of an enclosing chain.
At the top level no cell is parked, so every existing chain keeps its numbering. That is why the golden does not move. In the probe the
inner park goes to <code>RS)2</code>.</p>
<p><strong>Rejected:</strong> offset the inner chain by the outer's term count. Section 0 reserves three cells (<code>resultStorageCells = [3, 2, 3, 7]</code>),
so the probe's inner park would need <code>RS)3</code> and refuse. Also rejected: evaluate sub-chains before the outer terms. That reorders
words against M4-10's source order.</p>
{toggle(11)}
<h3>The options</h3>
<div class="opt"><h3>Refuse</h3>
<p>Refuse <code>{R11}</code> <span class="inferred">proposed text, not built</span>. The truth-function case already refuses this way
(<code>an expression comparison inside a truth function after a parked term</code>).</p>
<p class="consequence">Refuses ordinary parenthesised arithmetic. To reverse: one commit.</p></div>
<div class="opt pick"><h3>Handle (recommended)</h3>
<p class="consequence">No new operation or form. The cell choice is ours and has no sample instance; <code>RS)2</code> never prints in the sample. A deep nest can still run out of a section's cells,
and then refuses <code>result-storage cell n of section s (M4-10)</code> as today. The truth-function refusal is left as it is.
To reverse: revert the hunk in <code>_chain</code> and <code>_park</code>.</p></div>
</section>

<section class="item" id="open">
<div class="itemhead"><span class="chip done">Settled</span><h2>What the prototype leaves open</h2></div>
<ul>
<li>MOVE CORRESPONDING and ADD CORRESPONDING into a group that holds a subscript variable still move no indicator: both return before
the update. <span class="inferred">inferred from the code</span>; not probed.</li>
<li>The constant increment steps the indicator c strides even when the store truncates the index (a one-digit K at 9, plus 1).
The recomputation would follow the stored value. M4-10 chose the constant form. <span class="inferred">inferred from the code</span>; not probed.</li>
<li>A subscripted internal-decimal <em>source</em> in a MOVE still refuses (<code>a subscripted internal-decimal move</code>), though
<code>CLA 0,r</code> after the same prologue would serve. Outside this record.</li>
<li>The merge PR must amend HANDOVER's defect list and M6-9's sentence &ldquo;A SET or ADD into the index does not reach it, because neither
recomputes an indicator&rdquo;. The prototype holds code and tests only, as the defects 1 and 2 prototype did.</li>
</ul>
</section>

<section class="item needs" id="answer">
<div class="itemhead"><span class="chip call">Your call</span><h2>Your answer</h2></div>
<fieldset class="pick"><legend>The combined question: handle wherever attested words exist, refuse only where none do?</legend>
<label><input type="radio" name="combined" value="yes"> <strong>Yes.</strong> Recommended. Handle 1, 2, 3, 4, 8, 9, 11 and the one-indicator part of 10; refuse 5 and the edited arm of 8.</label>
<label><input type="radio" name="combined" value="no"> <strong>No.</strong> Refuse every shape the sample does not itself compile.</label>
</fieldset>
{overrides}
<fieldset class="pick"><legend>Defect 10, the boundary</legend>
<label><input type="radio" name="d10" value="A"> <strong>A.</strong> Recommended. One indicator carries the byte; several keep the 1962 words (built).</label>
<label><input type="radio" name="d10" value="B"> <strong>B.</strong> Refuse one indicator inside a word; several keep the 1962 words.</label>
<label><input type="radio" name="d10" value="D"> <strong>D.</strong> Keep the zero decrement only for a field that shares its word with another driven field.</label>
<label><input type="radio" name="d10" value="C"> <strong>C.</strong> Carry the byte everywhere and move the golden.</label>
</fieldset>
<p class="mono">Anything else:</p>
<textarea id="anote" aria-label="Your note"></textarea>
<p><button id="copy" type="button">Copy my answer</button></p>
<pre id="aout"></pre>
<p class="mono">Your answer lands in this record as a dated banner, in a second commit on this branch, and authorizes the pull request
that carries it (review-records rule 7).</p>
</section>

<footer>
<p>Record built 2026-10-25 on branch <code>review/2026-10-25-codegen-defects-8-11</code>. Master at <code>{TODAY_SHA}</code>; prototype branch
<code>defects-8-11-handle</code> at <code>{HANDLE_FULL}</code>. <code>tools/build_doc.py</code> writes this page from <code>evidence/</code>,
<code>crops/</code> and <code>tools/house.css</code>; edit it, not the HTML. <code>tools/probe.dart</code> produced both captures (copy it to
<code>probe/</code> in a checkout and run <code>dart run probe/probe.dart</code>). Line links point at {TODAY_SHA}.</p>
</footer>
</main>

<script type="application/json" id="data">{json.dumps(DATA)}</script>
<script>
const D = JSON.parse(document.getElementById('data').textContent);
const $ = (s, r = document) => r.querySelector(s);
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}}[c]));

$('#theme').addEventListener('click', () => {{
  const r = document.documentElement;
  const dark = r.dataset.theme ? r.dataset.theme === 'dark'
    : matchMedia('(prefers-color-scheme: dark)').matches;
  r.dataset.theme = dark ? 'light' : 'dark';
}});

function wordsHtml(words, base) {{
  if (!words.length) return '<span class="k">no object code</span>';
  const left = {{}};
  for (const w of base) left[w] = (left[w] || 0) + 1;
  return words.map((w) => {{
    if (left[w]) {{ left[w] -= 1; return esc(w); }}
    return '<span class="new">' + esc(w) + '</span>';
  }}).join('\\n');
}}
const fmt = (o) => Object.entries(o).map(([k, v]) => k + ' = ' + JSON.stringify(v)).join('\\n');

function render(defect, view) {{
  const host = $('#cases' + defect);
  host.innerHTML = '';
  for (const c of D.filter((x) => x.defect === defect)) {{
    const v = c[view];
    const base = view === 'today' ? v.words : c.today.words;
    let val;
    if (v.refusal) {{
      val = '<span class="val stop">compile stops: <code>' + esc(v.refusal) + '</code>' +
        (v.proposed ? ' <span class="inferred">proposed text, not built</span>' : '') + '</span>';
    }} else {{
      val = '<span class="val ' + (v.ok ? 'good' : 'bad') + '">' + esc(fmt(v.values)) + '</span>';
    }}
    const pool = v.pool && v.pool.length ? '<p class="pool">pool: ' + v.pool.map(esc).join('\\n      ') + '</p>' : '';
    const note = v.note ? '<p class="why">' + esc(v.note) + '</p>' : '';
    const div = document.createElement('div');
    div.className = 'case';
    div.innerHTML =
      '<h4>' + esc(c.title) + '</h4>' +
      '<p class="decl">' + esc(c.decl) + ' &middot; <strong>' + esc(c.stmt) + '</strong> &middot; probe ' + esc(c.id) + '</p>' +
      '<div class="pair"><div><span class="k">Words, from START</span><pre class="words">' + wordsHtml(v.words, base) + '</pre>' + pool + '</div>' +
      '<div><span class="k">Fields after the run</span>' + val + note +
      '<span class="k" style="margin-top:.7rem">Right value</span><span class="val right">' + esc(fmt(c.right)) + '</span>' +
      '<p class="why">' + esc(c.why) + '</p></div></div>';
    host.append(div);
  }}
  for (const b of document.querySelectorAll('button[data-defect="' + defect + '"]'))
    b.setAttribute('aria-pressed', String(b.dataset.view === view));
}}
for (const b of document.querySelectorAll('button[data-defect]'))
  b.addEventListener('click', () => render(Number(b.dataset.defect), b.dataset.view));
for (const d of [8, 9, 10, 11]) render(d, 'today');

function answerText() {{
  const pick = (n) => (document.querySelector('input[name="' + n + '"]:checked') || {{}}).value || '(no choice)';
  const note = $('#anote').value.trim();
  return 'review/2026-10-25-codegen-defects-8-11\\n' +
    'Combined (handle where attested, refuse where not): ' + pick('combined') + '\\n' +
    'Defect 8: ' + pick('d8') + '\\nDefect 9: ' + pick('d9') + '\\nDefect 11: ' + pick('d11') + '\\n' +
    'Defect 10 boundary: ' + pick('d10') + (note ? '\\nNote: ' + note : '');
}}
function refresh() {{ $('#aout').textContent = answerText(); }}
for (const i of document.querySelectorAll('input[type="radio"]')) i.addEventListener('change', refresh);
$('#anote').addEventListener('input', refresh);
$('#copy').addEventListener('click', async () => {{
  try {{ await navigator.clipboard.writeText(answerText()); $('#copy').textContent = 'Copied'; }}
  catch (e) {{ $('#copy').textContent = 'Copy failed: select the text below'; }}
  setTimeout(() => {{ $('#copy').textContent = 'Copy my answer'; }}, 2500);
}});
refresh();
</script>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(PAGE)
print(f"wrote {OUT}")
