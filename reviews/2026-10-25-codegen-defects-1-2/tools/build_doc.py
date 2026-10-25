"""Build index.html for review/2026-10-25-codegen-defects-1-2.

Reads the two probe captures in evidence/ and the crops in crops/, and
writes a standalone index.html beside this directory. Every image is a
data: URI. Run: python3 tools/build_doc.py (from the record directory or
anywhere).
"""

import base64
import html
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

TODAY_SHA = "ace4ee0"
ALIGN_SHA = "0223ddf"
ALIGN_FULL = "0223ddfbf0e4e943f5ca27eae2d2bbaf4678ddc4"

today = json.load(open(os.path.join(REC, "evidence", "today-ace4ee0.json")))
align = json.load(open(os.path.join(REC, "evidence", "align-0223ddf.json")))

D1_REFUSAL = "a move of unequal scales (no sample instance)"
D2_REFUSAL = "an ADD pair of unequal scales (notes section 7)"

# One row per probe program. scale is the fraction digits of the field the
# probe reads; None means an edited field read as characters.
CASES = [
    dict(id="P1a-up", defect=1, field="EDT", scale=None, chars=8,
         title="Internal source of lesser scale, into an edited field",
         decl="NUM  IR 999 (set to 123);  EDT  $8889.99",
         stmt="MOVE NUM TO EDT", right=" $123.00",
         why="F p. 42: align on the point."),
    dict(id="P1a-up-split", defect=1, field="ED5", scale=None, chars=5,
         title="Internal source of lesser scale, wider than its edited field",
         decl="BIG  IR 9(5) (set to 1234);  ED5  889.9",
         stmt="MOVE BIG TO ED5", right="234.0",
         why="F p. 43 row 5: 99999 01234 into 999V9 gives 2340. The alignment "
             "adds a digit and the existing split drops the leading one."),
    dict(id="P1a-down", defect=1, field="EDS", scale=None, chars=4,
         title="Internal source of greater scale, into an edited field",
         decl="AMT  IR 99V99 (set to 12.34);  EDS  89.9",
         stmt="MOVE AMT TO EDS", right="12.3",
         why="F p. 43 row 2: 99V99 1234 into 99V9 gives 123."),
    dict(id="P1b-up", defect=1, field="INT", scale=2,
         title="External source of lesser scale, into an internal field",
         decl="EXT  E 999 (holds 040);  INT  IR 99V99",
         stmt="MOVE EXT TO INT", right="40.00",
         why="F p. 42: the excess positions are replaced by zeros."),
    dict(id="P1b-down", defect=1, field="INT", scale=1,
         title="External source of greater scale, into an internal field",
         decl="EXT  E 99V99 (holds 1234);  INT  IR 99V9",
         stmt="MOVE EXT TO INT", right="12.3",
         why="F p. 42: low-order digits are dropped, not rounded."),
    dict(id="P2-up", defect=2, field="TOT", scale=2,
         title="Edited source of lesser scale",
         decl="ED3  899 (holds 037);  TOT  IR 999V99 (set to 1.25)",
         stmt="ADD ED3 TO TOT", right="38.25",
         why="1.25 + 37."),
    dict(id="P2-down", defect=2, field="TOT", scale=0,
         title="Edited source of greater scale",
         decl="ED3  899V99 (holds 03750);  TOT  IR 9999 (set to 100)",
         stmt="ADD ED3 TO TOT",
         right="138, or 137 under TRUNCATED",
         why="F p. 45: SET rounds unless TRUNCATED; F p. 47: TRUNCATED is "
             "&ldquo;equally applicable&rdquo; to ADD. That ADD rounds is an "
             "inference from the two."),
    dict(id="P2-plain-up", defect=2, field="TOT", scale=2,
         title="Internal source of lesser scale (the sibling path, for comparison)",
         decl="SRC  IR 999 (set to 37);  TOT  IR 999V99 (set to 1.25)",
         stmt="ADD SRC TO TOT", right="38.25",
         why="1.25 + 37. Today this path refuses; it is not defect 2."),
]


def value_of(case, run):
    if "refusal" in run:
        return None
    raw = run["values"][case["field"]]
    if case["scale"] is None:
        return raw
    s = case["scale"]
    neg = raw < 0
    digits = str(abs(raw)).rjust(s + 1, "0")
    text = digits if s == 0 else f"{digits[:-s]}.{digits[-s:]}"
    return ("-" if neg else "") + text


def procedure_words(run):
    words = run.get("words")
    if not words:
        return []
    i = 1
    while i < len(words) and words[i].split(" ")[0] in ("BSS", "OCT"):
        i += 1
    return words[i:]


def view(case, src):
    run = src[case["id"]]
    return dict(
        words=procedure_words(run),
        value=value_of(case, run),
        refusal=run.get("refusal", "").replace("unrecovered shape: ", "") or None,
    )


DATA = []
for c in CASES:
    t = view(c, today)
    a = view(c, align)
    if c["defect"] == 1:
        refuse = dict(words=[], value=None, refusal=D1_REFUSAL, proposed=True)
    elif c["id"] == "P2-plain-up":
        refuse = dict(t)  # Today this path already refuses.
    else:
        refuse = dict(words=[], value=None, refusal=D2_REFUSAL, proposed=False)
    DATA.append(dict(
        id=c["id"], defect=c["defect"], title=c["title"], decl=c["decl"],
        stmt=c["stmt"], right=c["right"], why=c["why"],
        today=t, refuse=refuse, align=a,
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
<button type="button" data-defect="{defect}" data-view="align" aria-pressed="false">Align ({ALIGN_SHA})</button>
</div>
<div class="cases" id="cases{defect}"></div>"""


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
body { background:var(--paper); color:var(--ink); font-family:var(--serif);
  font-size:17px; line-height:1.62; margin:0;
  padding:clamp(1.5rem,4vw,4rem) clamp(1rem,5vw,2rem); }
main > *, section > * { min-width:0; }
main { max-width:52rem; margin:0 auto; display:flex; flex-direction:column; gap:2.4rem; }
h1 { font-size:clamp(1.7rem,4.2vw,2.4rem); line-height:1.16; margin:0; text-wrap:balance;
     letter-spacing:-0.015em; }
h2 { font-size:1.32rem; margin:0 0 .2rem; text-wrap:balance; letter-spacing:-0.01em; }
h3 { font-size:1.02rem; margin:1.4rem 0 .3rem; }
p, li { margin:0 0 .85rem; }
li:last-child { margin-bottom:0; }
ul, ol { padding-left:1.15rem; margin:0 0 .85rem; }
code { font-family:var(--mono); font-size:.87em; background:var(--hair);
       padding:.08em .3em; border-radius:2px; overflow-wrap:anywhere; }
.mono { font-family:var(--mono); font-size:.8rem; }
.eyebrow { font-family:var(--mono); font-size:.7rem; letter-spacing:.16em;
           text-transform:uppercase; color:var(--muted); margin:0 0 .7rem; padding-right:8rem; }
header { border-bottom:2px solid var(--ink); padding-bottom:1.4rem; position:relative; }
header p.standfirst { font-size:1.06rem; color:var(--muted); margin:.75rem 0 0; }
section { display:flex; flex-direction:column; gap:.2rem; }
.answer { background:var(--raised); border:1px solid var(--hair);
          border-left:3px solid var(--ink); padding:1.15rem 1.3rem; }
.answer ol { margin:0; padding-left:1.2rem; }
.answer li { margin-bottom:.5rem; }
.ask { background:var(--stamp-soft); border:1px solid var(--stamp); padding:.9rem 1.1rem; }
.ask p { margin:0 0 .5rem; }
.ask p:last-child { margin:0; }
.ask .label { font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
              text-transform:uppercase; color:var(--stamp); display:block; margin-bottom:.3rem; }
.chip { font-family:var(--mono); font-size:.66rem; letter-spacing:.14em;
        text-transform:uppercase; padding:.24em .6em; border-radius:2px;
        border:1px solid currentColor; white-space:nowrap; }
.chip.call { color:var(--stamp); background:var(--stamp-soft); }
.chip.done { color:var(--settled); }
.itemhead { display:flex; gap:.75rem; align-items:baseline; flex-wrap:wrap; margin-bottom:.35rem; }
.item { border-top:1px solid var(--rule); padding-top:1.3rem; }
.item.needs { border-top:2px solid var(--stamp); }
.inferred { font-family:var(--mono); font-size:.62rem; letter-spacing:.12em;
            text-transform:uppercase; color:var(--muted); border:1px dashed var(--muted);
            padding:.05em .4em; border-radius:2px; white-space:nowrap; }
figure { margin:1rem 0 1.2rem; }
.scan { background:#fff; border:1px solid var(--rule); padding:.55rem; }
.scan img { display:block; max-width:100%; height:auto; margin:0 auto; }
figcaption { font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
             margin-top:.5rem; }
.scroll { overflow-x:auto; margin:.5rem 0 1rem; }
table { border-collapse:collapse; font-size:.9rem; font-variant-numeric:tabular-nums; width:100%; }
th, td { text-align:left; padding:.35rem .7rem .35rem 0; vertical-align:top;
         border-bottom:1px solid var(--hair); }
th { font-family:var(--mono); font-size:.68rem; letter-spacing:.1em; text-transform:uppercase;
     color:var(--muted); font-weight:normal; border-bottom:1px solid var(--rule); }
.opt { border-left:3px solid var(--rule); padding:.15rem 0 .15rem 1rem; margin:0 0 1rem; }
.opt.pick { border-left-color:var(--stamp); }
.opt h3 { margin:0 0 .25rem; }
.opt p { margin:0 0 .35rem; }
.consequence { font-size:.92rem; color:var(--muted); }
button { font-family:var(--mono); font-size:.74rem; background:var(--raised);
         color:var(--ink); border:1px solid var(--rule); padding:.3rem .6rem;
         border-radius:2px; cursor:pointer; }
button:hover { border-color:var(--ink); }
button:focus-visible { outline:2px solid var(--stamp); outline-offset:2px; }
button[aria-pressed="true"] { border-color:var(--stamp); color:var(--stamp);
         background:var(--stamp-soft); }
#theme { position:absolute; right:0; top:0; }
.toggle { display:flex; flex-wrap:wrap; gap:.4rem; margin:.8rem 0 .6rem;
          position:sticky; top:0; background:var(--paper); padding:.4rem 0; z-index:3; }
.cases { display:flex; flex-direction:column; gap:1rem; }
.case { background:var(--raised); border:1px solid var(--rule); padding:.8rem .9rem; }
.case h4 { margin:0 0 .2rem; font-size:.98rem; }
.case .decl { font-family:var(--mono); font-size:.74rem; color:var(--muted); margin:0 0 .5rem; }
.pair { display:grid; grid-template-columns:minmax(0,1.3fr) minmax(0,1fr); gap:.9rem; }
.words { font-family:var(--mono); font-size:.76rem; line-height:1.5; margin:0;
         border:1px solid var(--hair); padding:.45rem .6rem; background:var(--paper);
         white-space:pre; overflow-x:auto; min-height:3rem; }
.words .new { color:var(--settled); font-weight:bold; }
.k { font-family:var(--mono); font-size:.64rem; letter-spacing:.12em; text-transform:uppercase;
     color:var(--muted); display:block; margin:0 0 .15rem; }
.val { font-family:var(--mono); font-size:1.15rem; white-space:pre; }
.val.bad { color:var(--stamp); }
.val.good { color:var(--settled); }
.val.stop { color:var(--muted); font-size:.82rem; white-space:normal; }
.right { font-family:var(--mono); font-size:.9rem; }
.why { font-size:.82rem; color:var(--muted); margin:.3rem 0 0; }
.pick label { display:block; border:1px solid var(--rule); background:var(--raised);
              padding:.55rem .8rem; margin:0 0 .45rem; cursor:pointer; }
.pick label:hover { border-color:var(--ink); }
.pick input { margin-right:.5rem; }
fieldset { border:none; padding:0; margin:0 0 1rem; }
legend { font-weight:bold; margin-bottom:.4rem; }
textarea { width:100%; min-height:4.5rem; font-family:var(--mono); font-size:.8rem;
           background:var(--raised); color:var(--ink); border:1px solid var(--rule); padding:.5rem; }
pre#aout { font-family:var(--mono); font-size:.76rem; white-space:pre-wrap; margin:0;
           background:var(--raised); border:1px solid var(--rule); padding:.55rem; }
footer { border-top:1px solid var(--rule); padding-top:1rem; font-size:.85rem; color:var(--muted); }
@media (max-width:700px) { .pair { grid-template-columns:minmax(0,1fr); } }
@media (prefers-reduced-motion:reduce) { * { transition:none!important; } }
"""

ATTESTED = """
<div class="scroll"><table>
<thead><tr><th>Words the prototype adds</th><th>Where</th><th>Where the 1962 sample has them (<code>test/goldens/90.05-payroll.code</code> at ace4ee0)</th></tr></thead>
<tbody>
<tr><td><code>LDQ src / MPY 10^d / XCA</code></td><td>defect 1, internal source upscaled</td>
<td>LOC 00641&ndash;00643 <code>LDQ 1)RATE,1 / MPY 3)HOURS / XCA</code>; the zero build, LOC 00656&ndash;00660 <code>LDQ CP)+0 / MPY CP)+31 / XCA</code>. The same three words PR #143 uses for a comparison.</td></tr>
<tr><td><code>XCA / MPY 10^d / XCA</code></td><td>defect 1, external source upscaled after its convert</td>
<td>LOC 00626&ndash;00631 <code>SUB RS)0 / XCA / MPY 1)RATE,2 / XCA</code>: a value in the accumulator moved to the MQ, multiplied, and moved back.</td></tr>
<tr><td><code>LRS 35 / DVP 10^d</code></td><td>defect 1, external source downscaled</td>
<td>LOC 00423&ndash;00425 <code>CLA 5)NETPAY / LRS 35 / DVP CP)+24</code>: a divide of an accumulator value.</td></tr>
<tr><td><code>STQ target</code> after <code>DVP</code></td><td>defect 1, the same</td>
<td>LOC 00634&ndash;00635 <code>DVP CP)+33 / STQ 4)GROSS</code>. The sample's <code>ACL</code> half-adjust ahead of it (00632) is SET's rounding (F p. 45). F p. 42 says a MOVE drops low-order digits, so the prototype omits it.</td></tr>
<tr><td><code>LDQ src / MPY 10^d / STQ RS)0 / CLA tgt / ADD RS)0 / STO tgt</code></td><td>defect 2, and the plain ADD pair</td>
<td>LOC 00622&ndash;00626 <code>LDQ CP)+7 / MPY CP)+31 / STQ RS)0 / CLA RS)1 / SUB RS)0</code>: the chain's alignment of a term, parked. At ace4ee0, <code>SET TOT = TOT + SRC</code> already compiles to these six words (probe S3-set-add-up in <code>evidence/</code>).</td></tr>
</tbody></table></div>
<p class="mono">CP)+31 is octal 144, that is 100 (LOC 01733). Each operation is in the sample, but several joins between them are not:
<code>TXI SYS)184</code> then <code>XCA</code> or <code>LRS 35</code> (the sample never follows a convert with arithmetic),
<code>XCA</code> then <code>TSX SYS)180,4</code> or <code>STO</code>, and <code>LDQ</code> of a result cell (the sample reads its cells with
<code>CLA</code>). <span class="inferred">inferred</span> The register effect of each word does not depend on the word before it, so the
probe runs are the test of each join.</p>
"""

SAMPLE_HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MOVE and ADD scales</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<button id="theme" type="button" aria-label="Switch light or dark">Light / dark</button>
<p class="eyebrow">Review record &middot; codegen defects 1 and 2 &middot; evidence 2026-10-25 &middot; master at {TODAY_SHA} &middot; prototype at {ALIGN_SHA}</p>
<h1>A MOVE and an ADD across unequal scales: refuse them, or align them</h1>
<p class="standfirst">Two shapes compile today and store the wrong number without a word. You choose,
for each, between a refusal and an alignment. The alignment is built, tested and pushed.</p>
</header>

<section>
<div class="answer">
<ol>
<li><strong>Today both defects print wrong numbers, silently.</strong> On our machine at {TODAY_SHA},
<code>MOVE NUM TO EDT</code> with NUM = 123 renders <code>$1.23</code>, and
<code>ADD ED3 TO TOT</code> with 1.25 and 37 stores 1.62. Thirteen probe programs captured; eight shown below, the rest cited where they bear.</li>
<li><strong>You decide one thing per defect: refuse the shape, or align it.</strong> HANDOVER left this call to you.</li>
<li><strong>Align is built</strong> on <code>defects-1-2-align</code> at <code>{ALIGN_SHA}</code>. Every added word is in the
1962 sample. The same probes now give <code>$123.00</code> and 38.25. 1348 tests pass, and the sample's object code is byte for byte unchanged.</li>
<li><strong>Three shapes stay refused under align</strong>, each with no attested word sequence: an edited store that drops fraction
digits, an ADD into a target of lesser scale, and an aligned MOVE past 10 digits.</li>
<li><strong>Recommendation: align both.</strong> F p. 42&ndash;43 makes unequal-scale MOVEs its own examples, so by M6-9 the shape compiled in
1962. The ADD alignment is the six words <code>SET TOT = TOT + SRC</code> already compiles to.</li>
<li><strong>Neither choice touches a known program.</strong> The 1962 sample has no such MOVE or ADD (measured). The 1960 payroll program has none either (by inspection).</li>
</ol>
</div>
</section>

<section>
<div class="ask"><span class="label">What you are deciding</span>
<p>For defect 1 (MOVE) and for defect 2 (ADD), separately: <strong>refuse</strong> (the compiler stops with a named shape) or
<strong>align</strong> (merge the prototype's words). The answer box is at the end. Your answer also authorizes the pull request
that carries it (review-records rule 7).</p>
</div>
</section>

<section class="item needs" id="d1">
<div class="itemhead"><span class="chip call">Your call</span><h2>Defect 1. A MOVE does not align scales on two paths</h2></div>
<p>Two MOVE paths ignore the decimal point. The internal-to-edited store (<code>_editedStore</code>,
<code>lib/src/codegen/procedure.dart</code>:2279 at {TODAY_SHA}) compares digit counts only. It splits on digit count with
<code>LRS 35 / DVP</code> and renders the remainder. The external-to-internal path (:2155) converts and stores with no comparison at
all. A third path, internal to internal, already refuses the mismatch (:2342, <code>an internal-decimal move off its trigger</code>).
External to edited takes the aligning edit run and is not defective.</p>
{img("f-p42-numeric.png", "F p. 42, Numeric Information: the data is aligned with respect to the decimal point", "F p. 42 (PDF 48), the editing feature of MOVE. Scan crop.")}
{img("f-p43-table.png", "F p. 43 MOVE examples table", "F p. 43 (PDF 49). Rows 2, 3 and 5 move between unequal scales: 99V99 to 99V9, 9V9 to 99V99, 99999 to 999V9. Scan crop.")}
<p>Toggle the view. Each card is one probe program, compiled and run on our machine. The words are the whole procedure; the
added words are in bold green. <span class="inferred">source</span> <code>tools/probe.dart</code>,
<code>evidence/today-ace4ee0.json</code>, <code>evidence/align-0223ddf.json</code>.</p>
{toggle(1)}

<h3>The options</h3>
<div class="opt">
<h3>Refuse</h3>
<p>Both paths stop with a new shape, proposed as <code>{D1_REFUSAL}</code> <span class="inferred">proposed text, not built</span>.
It stops every MOVE between unequal scales on these two paths, including the F p. 43 examples rows 2, 3 and 5 when the fields
take these modes.</p>
<p class="consequence">Breaks nothing known: no corpus program has the shape. Leaves the F p. 42 rule unbuilt on two paths. A later reader
sees a refusal of a shape that F uses as its own example, which M6-9 says compiled in 1962. To reverse: delete the check and build the
alignment, one commit, no golden moves.</p>
</div>
<div class="opt pick">
<h3>Align (recommended)</h3>
<p>Merge the prototype. Internal to edited: <code>LDQ / MPY 10^d / XCA</code> replaces <code>CLA</code> when the target has more fraction
digits; the existing split then drops leading digits, as F p. 43 row 5 does (probe P1a-up-split: today <code>123.4</code>, aligned <code>234.0</code>). External to internal: <code>XCA / MPY 10^d / XCA</code> after the
convert to add digits, <code>LRS 35 / DVP 10^d</code> then <code>STQ</code> to drop them.</p>
<p>Still refused: an internal source of greater scale into an edited field (<code>an edited store that drops source fraction digits
(no sample instance)</code>). SYS)180 renders the accumulator, and the quotient of the divide is in the MQ. Moving it across
takes <code>DVP</code> then <code>XCA</code>, which no site shows. The external-to-edited edit run refuses the same drop today
(<code>an edit run that bypasses source digits</code>). Also refused: an aligned MOVE past 10 digits (RT-4). The ADD path has no
such guard, as SET's chain has none today.</p>
<p class="consequence">Breaks nothing: 1348 tests pass and every golden is byte-identical. Adds a reconstruction that M7 will measure against
the 1962 processor; the evidence exists and is sealed until M7. To reverse: revert one commit.</p>
</div>
<p><strong>Recommendation: align.</strong> The shape is F's own example, J does not revoke it, and 90.01 does not defer it, so under
M6-9 it compiled in 1962. Each word is attested. The one sub-case without an attested sequence stays refused, which matches the
edit run beside it.</p>
</section>

<section class="item needs" id="d2">
<div class="itemhead"><span class="chip call">Your call</span><h2>Defect 2. An edited ADD source is not scale-aligned</h2></div>
<p>The plain ADD pair refuses unequal scales (<code>_addPair</code>, :2728 at {TODAY_SHA}, <code>{D2_REFUSAL}</code>). The edited-source
branch of <code>_add</code> (:2662) converts, parks in <code>RS)1</code>, and adds without that check. So the sibling refuses and the edited
path computes a wrong sum.</p>
{img("f-p47-add.png", "F p. 47, the ADD command", "F p. 47 (PDF 53). ADD shares SET's TRUNCATED and ON OVERFLOW. The third example adds into RATE with TRUNCATED, a shape where the source can carry more fraction digits than the target. Scan crop.")}
{toggle(2)}

<h3>The options</h3>
<div class="opt">
<h3>Refuse</h3>
<p>The edited branch takes <code>_addPair</code>'s check and its text, <code>{D2_REFUSAL}</code>. That text is real: it is what
<code>ADD SRC TO TOT</code> prints today (probe P2-plain-up).</p>
<p class="consequence">Breaks nothing known. Makes the two ADD paths agree on a refusal. Leaves every unequal-scale ADD refused, though
<code>SET TOT = TOT + SRC</code> with the same fields compiles and runs right today. To reverse: one commit.</p>
</div>
<div class="opt pick">
<h3>Align (recommended)</h3>
<p>Both ADD paths, edited and plain, align a source of lesser scale with the chain's own words:
<code>LDQ src / MPY 10^d / STQ RS)0 / CLA tgt / ADD RS)0 / STO tgt</code>. For the plain pair these are exactly the words
<code>SET TOT = TOT + SRC</code> compiles to at {TODAY_SHA}; a test pins the equality.</p>
<p>Still refused: a source of greater scale (<code>an ADD into a target of lesser scale (no sample instance)</code>). The sum then needs
a scaling store of an accumulator value, which SET refuses too (<code>a scaling store of a chain value</code>, probe S4). It also needs
a rounding rule for ADD: F p. 45 rounds SET, and F p. 47 extends TRUNCATED to ADD, so ADD probably rounds <span class="inferred">inferred</span>.</p>
<p class="consequence">Breaks nothing: same gate. Aligning the edited branch alone would flip the inconsistency, so the prototype aligns the
plain pair too, and the old <code>{D2_REFUSAL}</code> pin becomes the narrower refusal above. To reverse: revert one commit.</p>
</div>
<p><strong>Recommendation: align.</strong> ADD is the increment SET already performs, F p. 47 gives the shape, and the alignment reuses
SET's attested chain words with no new form.</p>
</section>

<section class="item" id="words">
<div class="itemhead"><span class="chip done">Settled</span><h2>The source of every added word</h2></div>
{ATTESTED}
</section>

<section class="item" id="rule">
<div class="itemhead"><span class="chip done">Settled</span><h2>M6-9 bears on both calls, argued both ways</h2></div>
<p>Your rule of 2026-09-14: &ldquo;if it would compile in 1962, it should compile. If it wouldn't, it shouldn't.&rdquo;
(<code>docs/design/m6-acceptance.md</code>, M6-9.)</p>
<h3>For align</h3>
<ul>
<li>M6-9's reading rule: a form F admits, that J does not contradict, and that 90.01 does not defer, compiled in 1962. F p. 42 states the
alignment and F p. 43 gives three unequal-scale examples. J's MOVE sections say nothing on alignment (a search of the J 02 conversion
for &ldquo;decimal point&rdquo; and &ldquo;align&rdquo; finds no MOVE rule). 90.01 lists no such restriction.</li>
<li>So a refusal is stricter than the 1962 processor, which is the case M6-9 forbids.</li>
<li>PR #143 settled the same question for comparisons the same way, with the same three words.</li>
</ul>
<h3>For refuse</h3>
<ul>
<li>M6-9 says whether a shape compiled, not which words it compiled to. The sample has no unequal-scale MOVE or ADD, so the 1962 words
for these shapes are unknown. The evidence exists and is sealed until M7.</li>
<li>Our refusals are labelled &ldquo;no sample instance&rdquo;, not as 1962 diagnostics. A refusal states the gap honestly; it is not a claim
that 1962 refused (M4-2 as amended).</li>
<li>The ADD rounding question shows that the reconstruction is not fully determined by the manuals.</li>
</ul>
<p>The two readings meet on the sub-cases: align builds only where every word is attested, and refuses where the sequence is not.</p>
</section>

<section class="item" id="stops">
<div class="itemhead"><span class="chip done">Settled</span><h2>Which programs each option stops</h2></div>
<div class="scroll"><table>
<thead><tr><th>Program</th><th>Unequal-scale MOVE or ADD</th><th>Refuse stops it</th><th>Align changes it</th><th>How known</th></tr></thead>
<tbody>
<tr><td>1962 sample (J 90.05)</td><td>none</td><td>no</td><td>no: <code>90.05-payroll.code</code> byte-identical</td><td>measured: HANDOVER 2026-09-07; the golden test on {ALIGN_SHA}</td></tr>
<tr><td>1960 payroll, applied deck</td><td>none</td><td>no</td><td>no</td><td>inspection of every pair, <code>evidence/corpus-pairs.md</code>; the compile stops earlier, at 141,00</td></tr>
<tr><td>1960 payroll, as printed</td><td>none</td><td>no</td><td>no</td><td>the same inspection</td></tr>
<tr><td>Any program outside the corpus with these shapes</td><td>&mdash;</td><td>yes, at compile time</td><td>compiles; right value</td><td>the probes</td></tr>
</tbody></table></div>
<p>Two neighbouring refusals stay under either option and are outside this question: <code>MOVE FRAC TO NUM</code> internal to
internal (<code>an internal-decimal move off its trigger</code>), and <code>SET INT = NUM</code> into a target of greater scale
(<code>a store below the target scale</code>, probes S1 and S2). Under align, <code>MOVE EXT TO INT</code> compiles while
<code>SET INT = EXT</code> still refuses. That asymmetry is a follow-up, not part of this call.</p>
</section>

<section class="item needs" id="answer">
<div class="itemhead"><span class="chip call">Your call</span><h2>Your answer</h2></div>
<fieldset class="pick"><legend>Defect 1, MOVE</legend>
<label><input type="radio" name="d1" value="align"> <strong>Align.</strong> Recommended. Merge the prototype's MOVE words.</label>
<label><input type="radio" name="d1" value="refuse"> <strong>Refuse.</strong> Both paths stop on a named shape.</label>
</fieldset>
<fieldset class="pick"><legend>Defect 2, ADD</legend>
<label><input type="radio" name="d2" value="align"> <strong>Align.</strong> Recommended. Edited and plain ADD align a coarser source.</label>
<label><input type="radio" name="d2" value="refuse"> <strong>Refuse.</strong> The edited branch takes the plain pair's refusal.</label>
</fieldset>
<p class="mono">Anything else (a sub-case to treat differently, the ADD rounding rule):</p>
<textarea id="anote" aria-label="Your note"></textarea>
<p><button id="copy" type="button">Copy my answer</button></p>
<pre id="aout"></pre>
<p class="mono">Your answer lands in this record as a dated banner, in a second commit on this branch.</p>
</section>

<footer>
<p>Record built 2026-10-25 on branch <code>review/2026-10-25-codegen-defects-1-2</code>. Master at
<code>{TODAY_SHA}</code>; prototype branch <code>defects-1-2-align</code> at <code>{ALIGN_FULL}</code>.
<code>tools/build_doc.py</code> writes this page from <code>evidence/</code> and <code>crops/</code>; edit it, not the HTML.
<code>tools/probe.dart</code> produced both captures (copy it to <code>probe/</code> in a checkout and run
<code>dart run probe/probe.dart</code>). Every path above is a path at the commit named beside it.</p>
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

function render(defect, view) {{
  const host = $('#cases' + defect);
  host.innerHTML = '';
  for (const c of D.filter((x) => x.defect === defect)) {{
    const v = c[view];
    const base = view === 'today' ? v.words : c.today.words;
    let val;
    if (v.refusal) {{
      val = '<span class="val stop">compile stops: <code>' + esc(v.refusal) + '</code>' +
        (v.proposed ? ' <span class="inferred">proposed text</span>' : '') + '</span>';
    }} else {{
      const ok = v.value.trim() === c.right.split(',')[0].trim();
      val = '<span class="val ' + (ok ? 'good' : 'bad') + '">' + esc(v.value) + '</span>';
    }}
    const div = document.createElement('div');
    div.className = 'case';
    div.innerHTML =
      '<h4>' + esc(c.title) + '</h4>' +
      '<p class="decl">' + esc(c.decl) + ' &middot; <strong>' + esc(c.stmt) + '</strong> &middot; probe ' + esc(c.id) + '</p>' +
      '<div class="pair"><div><span class="k">Words</span><pre class="words">' + wordsHtml(v.words, base) + '</pre></div>' +
      '<div><span class="k">Field after the run</span>' + val +
      '<span class="k" style="margin-top:.7rem">Right value</span><span class="right">' + esc(c.right) + '</span>' +
      '<p class="why">' + c.why + '</p></div></div>';
    host.append(div);
  }}
  for (const b of document.querySelectorAll('button[data-defect="' + defect + '"]'))
    b.setAttribute('aria-pressed', String(b.dataset.view === view));
}}
for (const b of document.querySelectorAll('button[data-defect]'))
  b.addEventListener('click', () => render(Number(b.dataset.defect), b.dataset.view));
render(1, 'today');
render(2, 'today');

function answerText() {{
  const pick = (n) => (document.querySelector('input[name="' + n + '"]:checked') || {{}}).value || '(no choice)';
  const note = $('#anote').value.trim();
  return 'review/2026-10-25-codegen-defects-1-2\\n' +
    'Defect 1 (MOVE): ' + pick('d1') + '\\n' +
    'Defect 2 (ADD): ' + pick('d2') + (note ? '\\nNote: ' + note : '');
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
    fh.write(SAMPLE_HTML)
print(f"wrote {OUT}")
