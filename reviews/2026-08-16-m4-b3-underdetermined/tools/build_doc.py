"""Assemble the chunk B3 underdetermined-rules record page.

Run it from anywhere; it writes `index.html` into the record directory
above this one. The page is standalone: the listing excerpts are inlined,
and the full files ship alongside in `evidence/`.
"""

import html
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

GH = (
    "https://github.com/Screendead/comtran-compiler/blob/"
    "1cdcb37ca4ba132fdee2215683543b9f31b4670a"
)


def pre(path, first=None, last=None):
    with open(os.path.join(REC, path), encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    if first is not None or last is not None:
        lines = lines[first:last]
    body = html.escape("\n".join(lines))
    return (
        f'<figure><div class="plate"><pre>{body}</pre></div>'
        f"<figcaption>{html.escape(path)}</figcaption></figure>"
    )


HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Chunk B3 — three rules one program cannot settle</title>
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
<p class="eyebrow">Review record · 2026-08-16 · chunk B3 · commit 1cdcb37</p>
<h1>Three rules one program cannot settle</h1>
<p class="standfirst">Chunk B3 is the arithmetic generator: it fills the
mnemonic, operand and OCTAL columns of every SET, every ADD, every truth
function and every subscript recomputation the 1962 payroll sample
compiles, and every line it fills matches the listing byte for byte. Six
rules carry it. Three rest on several sites. Three do not — one program
attests each, and a rival formulation fits the same ink. All three are
taken under the section 12 standing rule, and silence lets them
stand.</p>
</header>

<section class="answer">
<h2>What was decided, in five lines</h2>
<ol>
<li><strong>A computed operand parks in the result-storage cell that its
later operands count</strong> — the count of the statement's operands
written after it — in the sub-block of the section the walk is in. Four
park sites, one of them discriminating.</li>
<li><strong>The <code>+0</code> suffix is emitted on an <code>STQ</code>
to a cell above cell 0.</strong> It appears once in the whole program,
at LOC 00621, and the object-code notes already record it as
unrecovered. The generator carries a predicate that reproduces the ink,
not a rule that explains it.</li>
<li><strong>ADD CORRESPONDING emits its target list backwards</strong>,
and keeps the matcher's order inside one target. One clause attests it,
and the one plain multi-target ADD goes the other way.</li>
<li>Each rejected formulation reproduces the 1962 listing exactly as
well. They part on inputs the one surviving program never contains, so
no evidence can choose between them and no further scan work would
help.</li>
<li>Each is one commit to overturn, in
<code>lib/src/codegen/procedure.dart</code>, and nothing outside that
file depends on any of them.</li>
</ol>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>1 · Which result-storage cell a computed operand parks in</h2></div>

<p><strong>The decision.</strong> Number the statement's operands in
written order. A computed operand parks in the cell numbered by how many
operands follow it. For a SET the operands are the chain's terms; for an
ADD they are the source and then the targets. <code>_resultCell</code> in
<a href="{GH}/lib/src/codegen/procedure.dart">procedure.dart</a> takes the
number and the section, and M4-10 item (b) records it.</p>

<p><strong>Why the number matters.</strong> M4-4 as amended reserves the
cells as constants of the sample — 3, 2, 3 and an undivided 7 — on Jack's
ruling of 2026-08-15. A cell number is therefore not free: it decides
whether a program fits its section's reservation or refuses.</p>

<p><strong>The evidence.</strong> Four sites park, in four different
sections. Statement 203 is the only one that parks twice, and it is
what makes the rule readable: the chain
<code>(WORKING HOURS * 1.5 - 20)</code> has two terms, the first parks in
<code>RS)1</code> and the second in <code>RS)0</code>. Statement 221
parks once, and it parks in cell 1 rather than cell 0 — its
<code>ADD</code> has one source and one target, so one operand follows
the parked one:</p>
{pre("evidence/result-storage-parks.txt", 0, 33)}
<p>The whole file, including the two references that are compare scratch
rather than parks and the section bases the parks imply, ships in
<code>evidence/</code>.</p>

<p><strong>What would mislead.</strong> Both parks of statement 203
happen in term order, so that statement cannot separate counting
operands from counting parks. Statement 221 looks like it settles the
question and does not: with two operands and one park, a counter that
starts at one below the operand count also returns 1.</p>

<p><strong>The rejected options.</strong></p>
<div class="opt">
<p><span class="name">A — a counter that descends once per park</span><br>
Start at one below the operand count and decrement at each park rather
than at each operand. Cost: it agrees with all four attested sites. It
parts from the taken rule on a chain whose parked term is not the first
— <code>A + B*C + D</code> puts the product in cell 1 under the taken
rule and in cell 2 under this one. Neither answer can be checked, and
the second makes the cell number depend on how many earlier terms
happened to need no cell, which no reader could predict from the
source.</p>
</div>
<div class="opt">
<p><span class="name">B — a counter that ascends from cell 0</span><br>
Refuted by the ink, and worth stating because it is the obvious
allocator. Statement 203's first park would take cell 0 and the listing
prints <code>RS)1</code>; statement 221's only park would take cell 0
and the listing prints <code>3.RS)1</code>.</p>
</div>
<div class="opt pick">
<p><span class="name">C — count the operands that follow (taken)</span><br>
It reads off the source alone, it gives the same answer at every attested
site, and it makes the section reservation a statement about the source
rather than about the generator's bookkeeping. <strong>To
overturn:</strong> one commit at <code>_resultCell</code>'s two call
sites; the oracle re-checks all four parks. <strong>What overturns
it:</strong> a compiled listing with a chain whose parked term is not
its first.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>2 · When a result-storage reference prints <code>+0</code></h2></div>

<p><strong>The decision.</strong> Print the suffix on an
<code>STQ</code> whose cell is above cell 0, and the bare form
everywhere else. <code>_park</code> passes the flag and
<code>_resultCell</code> prints it. M4-10 item (d) records it, and says
in the same sentence that it is a predicate and not an explanation.</p>

<p><strong>The evidence, which is one word of the program.</strong>
<code>STQ RS)1+0</code> at LOC 00621 is the only reference in the whole
object program that carries a suffix. The object-code notes already
carry it twice: as item 20 of the pinned-at-the-diff list and as item 4
of the unrecovered list, where the instruction is to print it at LOC
00621 and the bare form everywhere else, because no rule accounts for
it.</p>

<p><strong>The three sites that constrain a predicate.</strong> Every
other park is bare, and three of them each kill a simpler predicate:</p>
<div class="scroll"><table>
<tr><th>Site</th><th>Cell</th><th>Register</th><th>Prints</th><th>Kills</th></tr>
<tr><td class="num">00621</td><td class="num">1</td><td>MQ</td>
<td class="num">RS)1+0</td><td>the empty predicate</td></tr>
<tr><td class="num">00624</td><td class="num">0</td><td>MQ</td>
<td class="num">RS)0</td><td>"every <code>STQ</code>"</td></tr>
<tr><td class="num">01362</td><td class="num">1</td><td>AC</td>
<td class="num">3.RS)1</td><td>"every cell above 0"</td></tr>
<tr><td class="num">01226</td><td class="num">0</td><td>MQ</td>
<td class="num">2.RS)0</td><td>"every park in a later section"</td></tr>
</table></div>

<p><strong>What would mislead.</strong> A cell is two words, so
<code>RS)1+0</code> reads naturally as the first word of a two-word cell,
written out. That reading is attractive and it is wrong as a rule: it
would put <code>+0</code> on every park, including
<code>STQ RS)0</code> two words later in the same statement.</p>

<p><strong>The rejected options.</strong></p>
<div class="opt">
<p><span class="name">A — a park that is not its statement's last</span><br>
LOC 00621 is the only park in the program followed by another park in the
same statement, so this fits every site too. Cost: none that any evidence
can show. It was not taken because it makes one word's print depend on a
word that has not been generated yet, which the rest of this generator
never does. It parts from the taken rule on a statement whose first park
is an <code>STO</code>.</p>
</div>
<div class="opt">
<p><span class="name">B — print the bare form everywhere</span><br>
Accept one wrong byte and record it. Cost: the golden listing is compared
byte for byte, so LOC 00621 would fail the oracle now and the full
listing diff at chunk B7 later. The project has no mechanism for a
knowingly wrong word in the golden, and inventing one for a single byte
would weaken every other byte's guarantee.</p>
</div>
<div class="opt">
<p><span class="name">C — refuse any park above cell 0</span><br>
Generate nothing where the suffix would be needed, under the M4-2 refusal
doctrine. Cost: statement 203 is in the sample, so the sample would stop
compiling. The doctrine covers shapes the sample never reaches.</p>
</div>
<div class="opt pick">
<p><span class="name">D — an <code>STQ</code> above cell 0 (taken)</span><br>
It reads only the word being emitted, it reproduces the print, and the
design record states plainly that it explains nothing. <strong>To
overturn:</strong> one commit at the <code>offset:</code> argument in
<code>_park</code>. <strong>What overturns it:</strong> a second compiled
listing carrying any second occurrence of the suffix.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>3 · The order ADD CORRESPONDING emits its targets</h2></div>

<p><strong>The decision.</strong> The target list emits backwards, and
the matched pairs inside one target keep the matcher's order, which is
the source record's description order. <code>_addOrder</code> in
procedure.dart implements it, and M4-10 item (e) records it.</p>

<p><strong>The evidence.</strong> Statement 208 writes
<code>ADD CORRESPONDING WORKING TO MASTER TOTALS, INTERNAL.TOTALS</code>.
INTERNAL.TOTALS matches seven of WORKING's fields and fills LOC 00733 to
00757; MASTER TOTALS matches three and fills 00760 to 00770. The second
target written is emitted first:</p>
{pre("evidence/add-corresponding-targets.txt")}
<p>The same excerpt settles the order inside a target, in the other
direction. The listing emits GROSS, RETIREMENT, INSURANCE, FICA, WHT,
NETPAY, HOURS — which is WORKING's description order exactly.
INTERNAL.TOTALS describes HOURS first and GROSS second, so the target's
own order is refuted and the source's is attested.</p>

<p><strong>What would mislead, and what it refutes.</strong> MASTER is a
located record: its three pairs address through XR1 and a base locator,
and INTERNAL.TOTALS is absolute. "Emit the located target last" therefore
fits statement 208 perfectly, and a reader who saw only this statement
would find it the more mechanical explanation. The one plain multi-target
ADD refutes it for the verb as a whole — there the located target goes
first:</p>
{pre("evidence/plain-add-targets.txt")}
<p>So a located-last rule survives only if it is scoped to CORRESPONDING,
which is exactly the scope the taken rule already needs.</p>

<p><strong>The rejected options.</strong></p>
<div class="opt">
<p><span class="name">A — emit the located target last</span><br>
Scoped to CORRESPONDING, it fits the one site. Cost: it makes the emitted
order depend on where a record lives rather than on what the clause says,
so moving a record between working storage and a file would silently
reorder a program. It also has no answer when both targets are located,
or neither, which is most clauses.</p>
</div>
<div class="opt">
<p><span class="name">B — sort by descending matched-pair count</span><br>
Seven pairs before three fits the one site as well. Cost: the same
objection, one step worse. The count is a property of the match, not of
the clause, so adding one field to a record could reverse the emission
order of a statement that did not change.</p>
</div>
<div class="opt">
<p><span class="name">C — refuse a multi-target ADD CORRESPONDING</span><br>
Cost: statement 208 is in the sample, so chunk B3 could not exist. The
refusal doctrine covers shapes the sample never reaches.</p>
</div>
<div class="opt pick">
<p><span class="name">D — reverse the written list (taken)</span><br>
It depends on the clause and nothing else, it is one line, and it states
its own oddity: the plain ADD keeps its order and this one does not, so
the reversal is recorded as belonging to CORRESPONDING alone. <strong>To
overturn:</strong> one commit in <code>_addOrder</code>; the oracle
re-checks statement 208. <strong>What overturns it:</strong> a second
compiled listing with a multi-target ADD CORRESPONDING, or a manual page
describing the expansion. Neither is known to survive.</p>
</div>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>4 · What the chunk verified, and what needs nothing</h2></div>

<p>The three other B3 rules rest on more than one site and are recorded in
M4-10 without a decision behind them. A value carries the register that
holds it: a product finishes in the MQ and a chain in the accumulator, so
a park writes <code>STQ</code> or <code>STO</code>, five sites and no
exception, and the scaling store tail opens on <code>XCA</code>, which
reads the MQ half. The generator addresses M4-4's reserved cells section
by section, and result storage in a fourth section refuses, which is what
keeps the fitted seven-cell tail from overlapping anything. An edited ADD
source converts through MOVPAK and parks, both counts of the call being
the source's digit count.</p>

<p>Five legal COMTRAN shapes the sample never reaches refuse rather than
generate invented text, and <code>test/codegen_refusal_test.dart</code>
pins one program per site: a scaling store of a chain value, a scale
alignment of a sub-chain, a product of a product, a result-storage cell
past its section's reservation, and result storage in a fourth
section.</p>

<p>The empirical state at commit 1cdcb37:</p>
<div class="scroll"><table>
<tr><th>Check</th><th>Result</th></tr>
<tr><td>Generated object lines against the verified target</td>
<td class="num">977 of 977</td></tr>
<tr><td>Lines where a generated mnemonic and operand are compared</td>
<td class="num">709, all equal</td></tr>
<tr><td>Lines where a generated 36-bit word is compared</td>
<td class="num">705, all equal</td></tr>
<tr><td>Columns left for a later chunk</td>
<td>two <code>EQU</code> operands (B5) and one <code>START</code> operand
(stage 3), each excluded by mnemonic</td></tr>
<tr><td>Dart test suite</td><td class="num">1102 pass</td></tr>
</table></div>

<p>The two counts rose from B2's 552 and 550.
<code>test/object_spine_test.dart</code> is monotone by construction: it
counts the lines it read in each column and asserts the count, so a later
chunk that stopped generating a column would fail here rather than pass
unread. Each verb chunk raises the two counts and none may lower one.</p>

<p>The word budget on <code>docs/design/m4-codegen.md</code> is locked at
10,000 words, so this amendment paid for its room by deleting from the
same record: the entry index the section headings already give, the stage
oracles the Oracles section already lists, the <code>RS)</code> constants
M4-4 already states, and argument prose in M4-4, M4-20 and M4-21 whose
evidence lives in HANDOVER, the object-code notes and the definition's
Open Questions list. No ruling and no citation was dropped.</p>
</section>

<footer>
<p>Chunk B3 on <code>m4s2-chunk-b3</code>: the generator at
<a href="{GH}/lib/src/codegen/procedure.dart">1cdcb37</a>, the design
record at <a href="{GH}/docs/design/m4-codegen.md">1cdcb37</a>. The
listing excerpts ship in <code>evidence/</code>. Built by
<code>tools/build_doc.py</code>. All three items are DECIDED, so this
record asks nothing and authorizes nothing; the B3 pull request waits for
Jack under CLAUDE.md section 12.</p>
</footer>

</main>
</body>
</html>
"""

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(HTML)
print(f"wrote {OUT} ({os.path.getsize(OUT)} bytes)")
