"""Build index.html for review/2026-11-02-literal-subscripts.

Reads the captures in evidence/, the crops in crops/ and house.css, and
writes a standalone index.html beside this directory. Every image is a
data: URI. Run: python3 tools/build_doc.py (from anywhere).
"""

import base64
import html
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

MASTER = "dba709d"
CODE = "1378b8c"
RECORD = "e7a95d7"
TESTS = 1609
BLOB = f"https://github.com/Screendead/comtran-compiler/blob/{RECORD}"
# The addendum of 2026-11-02 cites the commits after the record.
MERGE = "75aead9"
EVERY = "69be2c5"
ROUND1 = "dc0a60d"
COMMIT = "https://github.com/Screendead/comtran-compiler/commit"

CSS = open(os.path.join(HERE, "house.css")).read()
e = html.escape


def img(name):
    data = base64.b64encode(open(os.path.join(REC, "crops", name), "rb").read()).decode()
    return f'<img src="data:image/png;base64,{data}" alt="">'


def ev(name):
    return open(os.path.join(REC, "evidence", name)).read()


def last(text):
    return text.rstrip().splitlines()[-1]


def code_lines(name, wanted):
    return "\n".join(l for l in ev(name).splitlines() if any(w in l for w in wanted))


PROBES = [
    ("literal", "MOVE NUM TO CELL (2)", "27,00"),
    ("expression", "SET I = 1, MOVE NUM TO CELL (I + 1)", "28,00"),
    ("step", "SET K = 0, SET K = K + 2, MOVE NUM TO CELL (K + 1)", "29,00"),
    ("do-for", "DO RTN FOR I = 3(1)5, summing A (I)", "27,00"),
]
rows = "".join(
    f'<tr><td class="mono">{e(src)}</td>'
    f'<td class="mono">{e(last(ev(f"{n}-master-{MASTER}.txt")))}</td>'
    f'<td class="mono">{e(last(ev(f"{n}-branch-{CODE}.txt")))}</td>'
    f'<td class="mono">{e(passes)}</td></tr>'
    for n, src, passes in PROBES
)
counter2 = code_lines(f"literal-branch-{CODE}.code", ["USE\t2", "ORG\t", "PZE\tIOC)29", "PZE\tCELL", "PI)\tBSS"])
counter2_master = code_lines(f"literal-master-{MASTER}.code", ["USE\t2", "ORG\t", "PZE\tIOC)29", "PZE\tCELL", "PI)\tBSS"])

page = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Literal and expression subscripts</title>
<style>{CSS}
a {{ color:var(--ink); text-decoration-color:var(--rule); }}
.lst {{ font-family:var(--mono); font-size:.74rem; line-height:1.45; margin:.4rem 0 1rem;
        border:1px solid var(--hair); padding:.5rem .7rem; background:var(--raised);
        white-space:pre; overflow-x:auto; }}
blockquote {{ margin:.3rem 0 .9rem; padding:.1rem 0 .1rem 1rem; border-left:3px solid var(--rule); }}
td.mono, .mono {{ font-family:var(--mono); font-size:.78rem; }}
table {{ border-collapse:collapse; width:100%; }}
td, th {{ border-bottom:1px solid var(--rule); padding:.35rem .5rem; vertical-align:top; text-align:left; }}
.opt {{ margin:.2rem 0 .8rem; }}
.opt strong {{ font-family:var(--mono); font-size:.8rem; }}
.scroll {{ overflow-x:auto; }}
</style>
</head>
<body>
<main>

<header>
<button id="theme" type="button" aria-label="Switch light or dark">Light / dark</button>
<p class="eyebrow">Review record &middot; codegen defect 9, the open sentence &middot; evidence 2026-11-02 &middot; master at {MASTER} &middot; branch <code>literal-subscripts</code> at {RECORD}</p>
<h1>A literal or expression subscript now sets its indicator</h1>
<p class="standfirst">Two kinds of subscript compiled with no message and then stopped the run at the base-locator guard.
The manuals settle both, so this is decided under the section 12 standing rule. You can overturn it; silence lets it stand.</p>
</header>

<section>
<div class="answer">
<ol>
<li><strong>Decided: a literal subscript is a load-time constant.</strong> <code>CELL (2)</code> gets its pointer word under
Location Counter 2, beside the base locators. J 02.04.07 calls it &ldquo;a load-time constant&rdquo;; J 90.02.01 says counter 2
initializes pointer words with pre-determined constants.</li>
<li><strong>Decided: an index expression moves with its variable.</strong> A store into I updates <code>CELL (I + 1)</code> and
<code>CELL (2 * I - 1)</code>, with the attested five words and different constants. J 02.04.07.01 names
<code>A(J, K+1)</code> as updated by <code>SET K=K+2</code>.</li>
<li><strong>Decided, found on the way: a DO FOR now starts at FROM and steps by BY.</strong> It set element 1 and stepped one
element whatever the loop said. <code>DO RTN FOR I = 3(1)5</code> summed A(1..3) on master.</li>
<li><strong>Decided: a subscript outside <code>a * VARIABLE &plusmn; b</code> refuses</strong>, with a named message. <code>CELL (I + J)</code>
compiled and stopped at the guard; F p. 31 does not admit it.</li>
<li><strong>Left open, recorded in HANDOVER item 9:</strong> two indicators over one array still refuse; a two- or three-subscript
indicator with a variable is never set; a name subscript that nothing stores into (F p. 30's <code>MIAMI</code>) is never set.</li>
<li><strong>Cost:</strong> {TESTS} tests pass; <code>test/goldens/90.05-payroll.code</code> is byte-identical, because the sample has
no literal or expression subscript and its DO FOR is <code>1(1)12</code>.</li>
</ol>
</div>
</section>

<section class="item" id="runs">
<div class="itemhead"><span class="chip done">Settled</span><h2>Before and after</h2></div>
<p>Four probe programs (<code>tools/probe.dart</code>). Each stops at its last <code>STOP RUN</code> (the &ldquo;pass&rdquo; column) when the
element is right, and at an earlier one when it is wrong. Same decks, compiled by master and by the branch, run with <code>--run</code>.</p>
<div class="scroll"><table>
<tr><th>Probe</th><th>Master {MASTER}</th><th>Branch {CODE}</th><th>Pass at</th></tr>
{rows}
</table></div>
<p>The literal probe's counter-2 words on the branch (from <code>--emit-code</code>). TAB sits at word 2, so element 2 is word 3:</p>
<pre class="lst">{e(counter2)}</pre>
<p>On master the same program has no word for the indicator:</p>
<pre class="lst">{e(counter2_master)}</pre>
</section>

<section class="item" id="evidence">
<div class="itemhead"><span class="chip done">Settled</span><h2>The evidence</h2></div>
<figure><div class="scan">{img("j-02.04.07-subscripting.png")}</div>
<figcaption>J 02.04.07, PDF p. 25. &ldquo;A positional indicator with constant subscripts such as A(2,3) may be a load-time constant
or may change in value if the dimensions or base location of the array vary during the execution of the object program.&rdquo;</figcaption></figure>
<figure><div class="scan">{img("j-02.04.07.01-set-k.png")}</div>
<figcaption>J 02.04.07.01, PDF p. 26. <code>SET K=K+2</code> updates <code>A(J, K+1)</code> as well as <code>A(J, K)</code>.</figcaption></figure>
<figure><div class="scan">{img("j-90.02.01-counter-2.png")}</div>
<figcaption>J 90.02.01, PDF p. 139. Counter 1 holds the routines that update pointer words; counter 2 initializes pointer words
with pre-determined constants.</figcaption></figure>
<figure><div class="scan">{img("j-90.02.05-pi.png")}</div>
<figcaption>J 90.02.05, PDF p. 143. A positional indicator is a pointer word, its block follows the base locators, and its
update is <code>CLA / ADD PI) / STO PI)</code>.</figcaption></figure>
<figure><div class="scan">{img("f-p31-subscript-form.png")}</div>
<figcaption>F p. 31, PDF p. 37. A subscript is a name, a literal, or <code>a * VARIABLE &plusmn; b</code>.</figcaption></figure>
<p>Why the &ldquo;may change&rdquo; case never applies here: an input record that holds an array transmits (J 90.01.01; the binder,
<a href="{BLOB}/lib/src/data/binder.dart#L150">binder.dart:150</a>), only input records locate, and the binder bars a
variable-length array. So no array base moves at run time.</p>
</section>

<section class="item" id="literal">
<div class="itemhead"><span class="chip done">Decided</span><h2>1. The literal subscript: when and how its indicator is set</h2></div>
<p>Master compiled <code>MOVE NUM TO CELL (2)</code> to <code>LAC PI)1,1 / TXL SYS)294,1,0 / STO 0,1</code>, and nothing ever wrote
<code>PI)1</code>. The run stopped at the guard.</p>
<div class="opt"><strong>A. Load-time word under counter 2 (built).</strong> The counter-2 run continues from the <code>BL)</code> words into
<code>PI)</code>, which follows directly, through the last constant indicator: <code>PZE NAME+w,,b</code> for a constant one, <code>PZE 0</code>
for any other before it, as an empty base locator does. Zero object-time cost. A program with no constant indicator, the
sample included, keeps every attested word. The one unattested word: <code>USE 2</code> still prints <code>PI)1</code>. M4-4 left two
readings of it, and the <code>ORG</code> after it resets the load address, so it cannot change a run. Reverse: one function in
<code>blocks.dart</code>.</div>
<div class="opt"><strong>B. Store the value at program start.</strong> <code>CLA CP)+n / STO PI)n</code> ahead of the first statement. It runs,
but it puts object-time words at the program head that J does not describe, against &ldquo;load-time constant&rdquo;, and it moves
the first statement's address in any program that has one.</div>
<div class="opt"><strong>C. Recompute before every use.</strong> Contradicts J 02.04.07.01: indicators &ldquo;are evaluated when their subscripts
change value&rdquo;. Adds words at every reference.</div>
<div class="opt"><strong>D. An <code>ORG PI)n</code> per constant indicator.</strong> Same effect as A with a second <code>ORG</code> in counter 2, which no
listing shows. A needs none, because <code>PI)</code> follows <code>BL)</code>.</div>
<div class="opt"><strong>E. Refuse with a named message.</strong> Breaks your rule of 2026-09-14: F p. 30 and J 02.04.07 show literal
subscripts, so the 1962 processor compiled them.</div>
</section>

<section class="item" id="expression">
<div class="itemhead"><span class="chip done">Decided</span><h2>2. The index expression: which stores update it</h2></div>
<p>Master matched an indicator to a store by comparing the written subscript text with the stored name, so <code>I + 1</code>
never matched <code>I</code>. Element <code>a&middot;V + b</code> is element b plus <code>a&middot;V</code> strides, so the attested shapes
take it with new constants only:</p>
<ul>
<li>Recompute (attested at statement 225, LOC 01421&ndash;01432): <code>LDQ V / MPY a&middot;stride / XCA / ADD base / STO PI)n</code>, the base now
element b. For a plain V, b is 0 and the base is the attested <code>NAME-n</code>, so the sample's <code>RETPREM-2</code> and
<code>INSPREM-2</code> are unchanged.</li>
<li>Constant step <code>SET V = V + c</code> (J 90.02.05's <code>CLA / ADD PI) / STO PI)</code>): adds <code>a&middot;c</code> strides.</li>
<li>DO FOR: starts each indicator at element <code>a&middot;FROM + b</code> and steps <code>a&middot;BY</code> strides. For the sample's <code>1(1)12</code>
that is <code>NAME+0</code> and one stride, the attested words.</li>
</ul>
<p>The match is now by the resolved data item, not by text. No alternative fits J 02.04.07.01; refusing breaks the 2026-09-14
rule. Reverse: revert <code>_driven</code> in <code>procedure.dart</code>.</p>
</section>

<section class="item" id="refusal">
<div class="itemhead"><span class="chip done">Decided</span><h2>3. A subscript outside F's form refuses</h2></div>
<p><code>CELL (I + J)</code>, <code>CELL (I * J)</code> or <code>CELL (I / 2)</code> are outside <code>a * VARIABLE &plusmn; b</code>. Master compiled them
and the run stopped at the guard. No store can set such an indicator with the attested five words, so the generator refuses
<code>an index expression outside a * VARIABLE &plusmn; b (F p. 31)</code>, pinned in <code>test/codegen_refusal_test.dart</code>. Any order
of the terms is accepted (<code>1 + I</code>, <code>I * 2</code>), and literal terms fold. Alternative: a front-end diagnostic. No 90.04
message names the form, so it would need a new id of ours; the refusal needs none and is cheap to replace later.</p>
</section>

<section class="item" id="open">
<div class="itemhead"><span class="chip done">Settled</span><h2>4. What stays open</h2></div>
<ul>
<li><strong>Two indicators over one array refuse.</strong> The generator keys operands by data item in several places (the
fetch cells, the subscripted sets), so <code>CELL (I)</code> and <code>CELL (I + 1)</code> in one program need a wider change.</li>
<li><strong>A multi-subscript indicator with a variable is never set.</strong> <code>A (J, K)</code> stops at the guard on master and on
the branch. The recompute shape is attested for one subscript only. All-literal <code>A (2, 1)</code> works.</li>
<li><strong>A name subscript nothing stores into is never set,</strong> such as F p. 30's <code>MIAMI</code> constant. Verified by a probe.</li>
<li>MOVE and ADD CORRESPONDING still update no indicator (already in item 9).</li>
</ul>
<p>Records: M6-10 in <a href="{BLOB}/docs/design/m6-acceptance.md">m6-acceptance.md</a> (the M4 record is locked at its word budget, so it
points there), and HANDOVER item 9.</p>
</section>

<section class="item" id="addendum">
<div class="itemhead"><span class="chip done">Decided</span><h2>Addendum, 2026-11-02: every literal indicator takes its word</h2></div>
<p>Added after the record, in the review of pull request #191. The sections above describe the code at {CODE} and stand as
written. The merge of master at <a href="{COMMIT}/{MERGE}">{MERGE}</a> brought pull request #186. It gives each field of a
subscripted CORRESPONDING operand its own indicator, numbered after every written one. The written group keeps its own
indicator too (M6-9).</p>
<p><strong>What broke.</strong> The code at {CODE} set a constant indicator only when a word read it. Nothing reads the group
indicator of <code>MOVE CORRESPONDING G TO TAB (2)</code>, so it stayed <code>PZE 0</code>, unlike its fields. M6-10 defines a constant
indicator by its subscripts, not by its readers. The record outranks the code, so one option was viable.</p>
<p><strong>Decided at <a href="{COMMIT}/{EVERY}">{EVERY}</a>: every indicator whose subscripts are all literals takes its load-time
word, read or not.</strong> M6-10 now says so. The form check still runs at each indicator's first use.</p>
<div class="opt"><strong>Rejected: set the group indicator in the two CORRESPONDING paths.</strong> It fixes this case only. Any other
unread literal indicator would stay empty, and a later reader of M6-10 would find the rule false.</div>
<p><strong>Round 1 of the review, at <a href="{COMMIT}/{ROUND1}">{ROUND1}</a>.</strong> Literal terms that fold below one, such as
<code>CELL (2 - 3)</code>, now draw 182,00, as <code>CELL (0)</code> does (M3-20). The job still compiles. Tests pin the two pointer
refusals that the record did not list: a fractional DO FOR bound, and a subscript count unlike the array dimensions.</p>
</section>

<footer>
<p class="mono">evidence/: the four probe runs on master ({MASTER}) and on the branch ({CODE}); the literal and step probes' <code>--emit-code</code>
dumps on both; the code diff. tools/: build_doc.py writes this page, crops.py cuts the crops, probe.dart writes the decks
(copy to <code>probe/</code> in a checkout, <code>dart run probe/probe.dart OUTDIR</code>), house.css is the house style.
Line links point at {RECORD}.</p>
</footer>
</main>
<script>
(function () {{
  const root = document.documentElement;
  try {{ const t = localStorage.getItem('theme'); if (t) root.dataset.theme = t; }} catch (e) {{}}
  document.querySelector('#theme').addEventListener('click', () => {{
    const dark = root.dataset.theme ? root.dataset.theme === 'dark'
      : matchMedia('(prefers-color-scheme: dark)').matches;
    root.dataset.theme = dark ? 'light' : 'dark';
    try {{ localStorage.setItem('theme', root.dataset.theme); }} catch (e) {{}}
  }});
}})();
</script>
</body>
</html>
"""
open(OUT, "w").write(page)
print(OUT)
