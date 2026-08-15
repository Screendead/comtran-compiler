"""Assemble the chunk B1 adversarial-review record page.

Run it from anywhere; it writes `index.html` into the record directory
above this one. The page is standalone: the evidence excerpts are
inlined, and the full files ship alongside in `evidence/`.
"""

import html
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

GH_REVIEWED = (
    "https://github.com/Screendead/comtran-compiler/blob/"
    "c077c28ca19cf9f52e9edfda32ea55edea22e1a5"
)
GH_FIXED = (
    "https://github.com/Screendead/comtran-compiler/blob/"
    "52e32c18422bd9c969164e22b793d2c24b2981ae"
)


def pre(path, first=None, last=None):
    with open(os.path.join(REC, path), encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    if first is not None or last is not None:
        lines = lines[first:last]
    body = html.escape("\n".join(lines))
    return (
        f'<figure><div class="plate"><pre>{body}</pre></div>'
        f'<figcaption>{html.escape(path)}</figcaption></figure>'
    )


HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Chunk B1 review — five findings, one decision taken</title>
<style>
:root {{
  --paper:#F7F8F6; --raised:#FFFFFF; --ink:#14171A; --muted:#5C6560;
  --rule:#C9CFC8; --hair:#E1E5DF; --stamp:#B3261E; --stamp-soft:#FBEAE8;
  --settled:#40685A;
  --serif:"Iowan Old Style","Palatino Linotype",Palatino,"Book Antiqua",Georgia,serif;
  --mono:ui-monospace,"SF Mono",SFMono-Regular,Menlo,Consolas,monospace;
}}
@media (prefers-color-scheme:dark) {{
  :root:not([data-theme="light"]) {{
    --paper:#141715; --raised:#1C201D; --ink:#E7EBE5; --muted:#9AA69D;
    --rule:#3A423C; --hair:#2A302C; --stamp:#FF7A6B; --stamp-soft:#33201D;
    --settled:#7FB8A2;
  }}
}}
:root[data-theme="dark"] {{
  --paper:#141715; --raised:#1C201D; --ink:#E7EBE5; --muted:#9AA69D;
  --rule:#3A423C; --hair:#2A302C; --stamp:#FF7A6B; --stamp-soft:#33201D;
  --settled:#7FB8A2;
}}
* {{ box-sizing:border-box; }}
body {{
  background:var(--paper); color:var(--ink); font-family:var(--serif);
  font-size:17px; line-height:1.62; margin:0;
  padding:clamp(1.5rem,4vw,4rem) clamp(1rem,5vw,2rem);
}}
main {{ max-width:47rem; margin:0 auto; display:flex; flex-direction:column; gap:2.4rem; }}
h1 {{ font-size:clamp(1.7rem,4.2vw,2.4rem); line-height:1.16; margin:0; text-wrap:balance;
     letter-spacing:-0.015em; }}
h2 {{ font-size:1.32rem; margin:0 0 .2rem; text-wrap:balance; letter-spacing:-0.01em; }}
h3 {{ font-size:1.02rem; margin:1.6rem 0 .3rem; }}
p, li {{ margin:0 0 .85rem; }}
li:last-child {{ margin-bottom:0; }}
ul, ol {{ padding-left:1.15rem; margin:0 0 .85rem; }}
a {{ color:var(--ink); text-decoration-color:var(--rule); text-underline-offset:.16em; }}
a:hover {{ text-decoration-color:var(--stamp); }}
a:focus-visible {{ outline:2px solid var(--stamp); outline-offset:2px; border-radius:2px; }}
code {{ font-family:var(--mono); font-size:.87em; background:var(--hair);
        padding:.08em .3em; border-radius:2px; }}
.eyebrow {{ font-family:var(--mono); font-size:.7rem; letter-spacing:.16em;
            text-transform:uppercase; color:var(--muted); margin:0 0 .7rem; }}
header {{ border-bottom:2px solid var(--ink); padding-bottom:1.4rem; }}
header p.standfirst {{ font-size:1.06rem; color:var(--muted); margin:.75rem 0 0; }}
section {{ display:flex; flex-direction:column; gap:.2rem; }}
.answer {{ background:var(--raised); border:1px solid var(--hair);
           border-left:3px solid var(--ink); padding:1.15rem 1.3rem; }}
.answer ol {{ margin:0; padding-left:1.2rem; }}
.answer li {{ margin-bottom:.5rem; }}
.chip {{ font-family:var(--mono); font-size:.66rem; letter-spacing:.14em;
         text-transform:uppercase; padding:.24em .6em; border-radius:2px;
         border:1px solid currentColor; white-space:nowrap; }}
.chip.decided {{ color:var(--stamp); background:var(--stamp-soft); }}
.chip.done {{ color:var(--settled); }}
.itemhead {{ display:flex; gap:.75rem; align-items:baseline; flex-wrap:wrap;
             margin-bottom:.35rem; }}
.item {{ border-top:1px solid var(--rule); padding-top:1.3rem; }}
.item.needs {{ border-top:2px solid var(--stamp); }}
table {{ border-collapse:collapse; width:100%; font-size:.87rem; }}
.scroll {{ overflow-x:auto; margin:.5rem 0 1rem; }}
th, td {{ text-align:left; padding:.42rem .7rem .42rem 0; border-bottom:1px solid var(--hair);
          vertical-align:top; }}
th {{ font-family:var(--mono); font-size:.68rem; letter-spacing:.11em; text-transform:uppercase;
      color:var(--muted); font-weight:400; border-bottom:1px solid var(--rule); }}
td.num {{ font-family:var(--mono); font-variant-numeric:tabular-nums; white-space:nowrap; }}
figure {{ margin:1rem 0 1.2rem; }}
.plate {{ background:var(--raised); border:1px solid var(--rule); padding:.55rem;
          overflow-x:auto; }}
.plate pre {{ margin:0; font-family:var(--mono); font-size:.78rem; line-height:1.5; }}
figcaption {{ font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
              margin-top:.5rem; }}
.opt {{ border-left:3px solid var(--rule); padding:.15rem 0 .15rem 1rem; margin:0 0 1rem; }}
.opt.pick {{ border-left-color:var(--stamp); }}
.opt .name {{ font-family:var(--mono); font-size:.75rem; letter-spacing:.08em;
              text-transform:uppercase; }}
footer {{ border-top:1px solid var(--rule); padding-top:1rem; font-size:.85rem;
          color:var(--muted); }}
</style>
</head>
<body>
<main>

<header>
<p class="eyebrow">Review record · 2026-08-15 · chunk B1 · commit 52e32c1</p>
<h1>The B1 adversarial review: five findings, one decision taken</h1>
<p class="standfirst">An independent reviewer with fresh context read commit
c077c28 against the repository. It confirmed the spine, the goldens and the
word budget, and returned five findings. All five are fixed in 52e32c1 on
<code>m4s2-chunk-b1</code>. One fix carried a design decision, taken without
stopping under the section 12 standing rule; it is item 1, and silence lets
it stand.</p>
</header>

<section class="answer">
<h2>What happened, in five lines</h2>
<ol>
<li>The reviewer verified B1's three headline claims empirically, then found:
an unattested source shape crashed the whole deck; an unread field; the
register-liveness rule missing from its design record; the generated-name
mapping proven by no committed test; and a missing STOP n statement stamp.</li>
<li><strong>DECIDED:</strong> an unattested shape now throws a typed
<code>UnrecoveredShape</code>; the driver stops that job alone, later jobs
compile, and the CLI reports it as this compiler's failure — outside the 1962
severity stream, in no sink and no listing.</li>
<li>Every refusal site a valid program can reach — 39 of the 41 that remain
— is pinned by its own small program in
<code>test/codegen_refusal_test.dart</code>. The two left are
compiler-required default arms, argued in item 3.</li>
<li>The sweep found and closed two silent gaps the reviewer missed: a
subscripted multi-term chain operand and an alphameric comparison against a
literal each generated code no sample attests. Both now refuse, tested.</li>
<li>M4-9 carries the register-liveness composite, M4-2 the refusal boundary,
M4-6 the proven name mapping; the record stands at 9,995 of 10,000 words.
The suite grew from 1,024 to 1,064 tests, all green with the full gate.</li>
</ol>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>1 · Where a refusal stops: the job, outside the 1962 stream</h2></div>

<p><strong>The decision.</strong> A valid source shape the sample never
reaches has no attested generated form, and B1 refuses to invent one. That
refusal is now a typed <code>UnrecoveredShape</code>; the driver catches it
per job, the next job compiles (J 90.04.02's shape), the code dump prints
<code>* NOT RECOVERED: &lt;shape&gt;</code> for the refused job, and
<code>comtranc</code> reports it on stderr and exits 1. It enters no
diagnostic sink and no listing. M4-2 is amended to say so. <strong>To
overturn:</strong> one commit on this branch reroutes the catch; nothing
downstream depends on the boundary yet.</p>

<p><strong>The evidence.</strong> Before the fix, one <code>DISPLAY</code>
clause killed every job after it — the exact invariant the driver asserts
for severity-5 stops:</p>
{pre("evidence/display-crash-pre-fix.txt")}
<p>After the fix, job 1 refuses and job 2 compiles:</p>
{pre("evidence/display-fixed-post-fix.txt")}

<p><strong>The rejected options.</strong></p>
<div class="opt">
<p><span class="name">A — a 1962 diagnostic</span><br>
Report the refusal through the D10.2 sink at severity 5. Cost: the message
catalog is J 90.04's, and the 1962 compiler had code for DISPLAY — a
"cannot compile" message for it fabricates a diagnostic that never existed.
A later reader of a listing would take the invention for period behavior.</p>
</div>
<div class="opt">
<p><span class="name">B — leave the crash</span><br>
Keep the unhandled error. Cost: one refused job starves every job after it,
against the driver's own design (D9.1's job rule, quoted in the CLI's catch
net), and the ~40 refusal branches stay untested, which section 11 bans.</p>
</div>
<div class="opt pick">
<p><span class="name">C — a typed refusal, scoped to the job (taken)</span><br>
The refusal is honest about what it is: this recovery's gap, not the
program's error and not 1962's diagnostic. Rank closed the other two —
fidelity bars A, the design records bar B — which is what made this a
one-viable-option decision under the standing rule.</p>
</div>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>2 · Every reachable refusal site is pinned by a program</h2></div>
<p>The reviewer counted ~25 untested throw sites; the sweep found 42, and
triaged every one. After the fixes 41 remain — two became asserts, one
legality-shadowed arm dissolved, and two new guards arrived (item 4) — and
39 of the 41 each get a minimal valid COMTRAN program in
<code>test/codegen_refusal_test.dart</code> that reaches the site and
asserts its exact message — DISPLAY, the assigned GO TO,
DO EXACTLY, the multi-index DO, SET target lists, ON OVERFLOW, ADD
TRUNCATED, subscripted operands in six positions, the unattested move
class pairs, the expression and comparison defaults, and one site whose only
route in is a program msg 98,00 already flags below the stop severity. The
driver-scoping shape has its own test beside the severity-5 starvation
test in <code>driver_test.dart</code>.</p>
<p>Three sites left the count on principled grounds: the literal-overflow
guard was double-guarded (its caller checks the same bound first) and is now
an assert; the located variable-length guard is barred by the binder's own
1962 rule — an input record containing a variable-length item transmits
(J 02.07.03; J 90.01.01), so a located record can never hold one — and is
now an assert citing that rule; and the non-zero-figurative numeric
comparison arm was legality-shadowed (msg 82,00 bars every route in), so it
dissolved into the tested default refusal with no behavior change.</p>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>3 · Two default arms stay untested, and why that is the floor</h2></div>
<p>Two <code>_unruled</code> arms have no reaching program and remain:</p>
<ul>
<li><strong>The multi-term chain default.</strong> Every exotic term type
hits the scale computation's own refusal first, so the arm cannot fire —
but the switch is over the sealed <code>ArithExpr</code> with three handled
cases, and Dart requires the default for exhaustiveness.</li>
<li><strong>The leaf-operand default.</strong> Its callers pass the operand
they just proved is a leaf, so the default cannot fire — and the same
exhaustiveness rule requires it.</li>
</ul>
<p>Both are one-line throws the compiler forces the function to carry.
The alternative — restructuring the walkers so no default exists — trades
two dead throws for real branching logic with no oracle behind it, which is
the worse side of section 11. Recorded here rather than hidden.</p>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>4 · Two silent inventions the sweep itself caught</h2></div>
<p>Writing a program per site exposed two places that <em>generated</em>
where they should have refused — the exact failure the refusal discipline
exists to stop:</p>
<ul>
<li><strong>A subscripted operand in a multi-term chain</strong> sized as if
unsubscripted: the single-term arm refused it, the multi-term arms did not.
The guard now covers both, tested from both directions.</li>
<li><strong>An alphameric comparison against a literal</strong> sized one
word and pooled nothing — a shape no sample site attests, silently invented.
The spine oracle proves the sample never takes this path (a pooled literal
would shift every EQU address), so it now refuses, tested.</li>
</ul>
<p>STOP n also pools its statement stamp now, conforming to M4-14's own
words ("SYS)178's parameters carry it"); its word count is unchanged and no
sample site attests either way, which the test records.</p>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>5 · The records bind again, inside the budget</h2></div>
<div class="scroll"><table>
<tr><th>Finding</th><th>Fix</th></tr>
<tr><td>The register-liveness composite lived in a fixture addendum</td>
<td>M4-9 as amended carries it: reuse with no words; the cache clears whole
at a labelled word, a section entry and a subroutine call; a register write
kills that register alone, at statement distance, deferred to a
CORRESPONDING expansion's end. The notes now route to M4-9.</td></tr>
<tr><td>M4-6's mapping proven by no committed test</td>
<td>The spine oracle reads the 15-column label field byte for byte on every
line — names and offset alignment both — so the mapping is proven against
the scan-verified target, not the self-generated goldens. M4-6's spent
provisional block is cut; its amendment demand is met and says so.</td></tr>
<tr><td>Two texts overclaimed the refusal away</td>
<td>The codegen doc comment and M4-2 now state the one failure B1 detects
and where it stops; the sink still arrives with chunk B8 (M4-1's table —
both texts previously said B2, against the record's own table).</td></tr>
<tr><td>Unread <code>entry</code> field; dead ternary</td>
<td>Deleted.</td></tr>
</table></div>
<p>The record stands at 9,995 of 10,000 words; the cuts were M4-6's refuted
provisional mechanism, a spent stage-2 promise in M4-10, and tightened
amendment prose. Full suite 1,064 tests, format, analyze
<code>--fatal-infos</code>, deckconv and the sample compile all green.</p>
</section>

<footer>
<p>Corrected 2026-08-15, same day, before any reading: item 5 first
attributed the spent-promise cut to M4-13; the cut sentence sat in M4-10,
the expression compiler.</p>
<p>Reviewed commit:
<a href="{GH_REVIEWED}">c077c28</a> · fix commit
<a href="{GH_FIXED}">52e32c1</a> on <code>m4s2-chunk-b1</code> · the
reviewer's verbatim report and both crash captures ship in
<code>evidence/</code>. Built by <code>tools/build_doc.py</code>. An
all-DECIDED record authorizes no pull request; the B1 pull request waits
for Jack's word.</p>
</footer>

</main>
</body>
</html>
"""

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(HTML)
print(f"wrote {OUT} ({os.path.getsize(OUT)} bytes)")
