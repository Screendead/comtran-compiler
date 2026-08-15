"""Assemble the chunk B1 review page, inlining each listing excerpt from crops/.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: every excerpt is read from `crops/` and
written into the page, so the page and the shipped files cannot drift, and the
file renders from any location with no network.

This record carries no images. The object listing is a text artifact here, so
the excerpts are plain text and take no `data:` URI.
"""

import html
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

GH = (
    "https://github.com/Screendead/comtran-compiler/blob/"
    "fd6efd687d929fce8f6feb6965d34959166d0efb"
)


def listing(name, caption):
    with open(os.path.join(REC, "crops", name)) as fh:
        text = fh.read().rstrip("\n")
    return (
        f'<figure><div class="listing"><pre>{html.escape(text)}</pre></div>'
        f"<figcaption>{caption}</figcaption></figure>"
    )


HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Chunk B1 &mdash; two rules the listing does not give up</title>
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

/* The answer block, set like the head of the listing it describes. */
.answer {{ background:var(--raised); border:1px solid var(--hair);
           border-left:3px solid var(--ink); padding:1.15rem 1.3rem; }}
.answer ol {{ margin:0; padding-left:1.2rem; }}
.answer li {{ margin-bottom:.5rem; }}

.chip {{ font-family:var(--mono); font-size:.66rem; letter-spacing:.14em;
         text-transform:uppercase; padding:.24em .6em; border-radius:2px;
         border:1px solid currentColor; white-space:nowrap; }}
.chip.call {{ color:var(--stamp); background:var(--stamp-soft); }}
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

/* The text analogue of a scan plate. The listing here is a text artifact, so
   it takes the reader's theme; only a scan keeps a forced white ground. */
figure {{ margin:1rem 0 1.2rem; }}
.listing {{ background:var(--raised); border:1px solid var(--rule); padding:.7rem .8rem;
            overflow-x:auto; }}
.listing pre {{ margin:0; font-family:var(--mono); font-size:.74rem; line-height:1.55;
                white-space:pre; }}
figcaption {{ font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
              margin-top:.5rem; }}

.rulings {{ border:2px solid var(--settled); padding:1rem 1.2rem; }}
.rulings .label {{ font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
                   text-transform:uppercase; color:var(--settled); display:block;
                   margin-bottom:.4rem; }}
.rulings p {{ margin:0 0 .55rem; }}
.rulings p:last-child {{ margin:0; }}

.ask {{ background:var(--stamp-soft); border:1px solid var(--stamp); padding:.9rem 1.1rem;
        margin:.9rem 0 0; }}
.ask p {{ margin:0 0 .5rem; }}
.ask p:last-child {{ margin:0; }}
.ask .label {{ font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
               text-transform:uppercase; color:var(--stamp); display:block; margin-bottom:.3rem; }}

.opt {{ border-left:3px solid var(--rule); padding:.15rem 0 .15rem 1rem; margin:0 0 1rem; }}
.opt.pick {{ border-left-color:var(--stamp); }}
.opt h3 {{ margin:0 0 .25rem; }}
.opt p {{ margin:0 0 .35rem; }}
.opt p:last-child {{ margin:0; }}
.consequence {{ font-size:.92rem; color:var(--muted); }}
.note {{ font-size:.92rem; color:var(--muted); }}
footer {{ border-top:1px solid var(--rule); padding-top:1.2rem; font-size:.85rem;
          color:var(--muted); }}
@media (prefers-reduced-motion:reduce) {{ * {{ animation:none!important; transition:none!important; }} }}
</style>
</head>
<body>

<main>
<div class="rulings">
  <span class="label">Jack's rulings &middot; 15 August 2026</span>
  <p>&ldquo;Adopt the fitted rule, and run the bounded search on
  <code>RS)</code>.&rdquo; Both recommendations are adopted as put.</p>
  <p><strong>The clause digits:</strong> option A. The fitted rule enters the
  compiler labelled fitted, in the code and in the design record.</p>
  <p><strong>Result storage:</strong> option A. The bounded decode is authorized
  and runs before any ruling on the 30. If it lands, <code>RS)</code> takes the
  derived rule; if it fails, the choice between freezing 30 and any other course
  returns to Jack with the search recorded.</p>
  <p>Under the review-cycle rule, this answer also authorizes the chunk B1 pull
  request. The items below stand as they were put; this banner is the only
  addition.</p>
</div>
<header>
  <p class="eyebrow">M4 stage 2 &middot; chunk B1 &middot; prepared 11 August 2026</p>
  <h1>Two rules the listing does not give up</h1>
  <p class="standfirst">Chunk B1 cannot derive them, and its oracle cannot close
  without them. Both are the <code>TS) BSS 7</code> situation in shape, and
  neither is the same in substance. One asks you for a ruling now; the other
  asks you only whether to spend one bounded decode before you rule.</p>
</header>

<section>
  <div class="answer">
    <ol>
      <li><strong>Two numbers chunk B1 must emit have no derivation, and both are
      yours.</strong> Every other shape in the chunk's catalogue is settled.</li>
      <li><strong>The clause digits of the statement stamp: adopt the fitted rule,
      and label it fitted.</strong> The sample itself needs three different values,
      so some rule is required for the oracle to close at all. One rule reproduces
      five sites out of five.</li>
      <li><strong>The per-section maximum of result storage: let one bounded decode
      run before you rule.</strong> Six sections, four constraints, one named
      hypothesis. If it fails, freezing 30 stays available.</li>
      <li><strong>Neither is a peer collision.</strong> No two authorities in the
      repository require different things here. Both are gaps in the evidence.</li>
    </ol>
  </div>
</section>

<section class="item needs">
  <div class="itemhead"><span class="chip call">Your call</span>
  <h2>The clause digits of the statement stamp</h2></div>

  <h3>What the print shows</h3>
  <p>A GET and a STOP RUN each carry a statement stamp: two constant&#8209;pool
  words, the first the statement number in BCD, the second a comma, two digits,
  and three blanks. Five sites, all of them:</p>
  <div class="scroll">
  <table>
    <thead><tr><th>Object LOC</th><th>Statement</th><th>First cell</th>
    <th>Second cell</th><th>Second cell's BCD</th></tr></thead>
    <tbody>
      <tr><td class="num">00177</td><td class="num">188</td><td class="num">CP)+14</td>
      <td class="num">CP)+15</td><td class="num">,02&nbsp;&nbsp;&nbsp;</td></tr>
      <tr><td class="num">00221</td><td class="num">190</td><td class="num">CP)+18</td>
      <td class="num">CP)+19</td><td class="num">,00&nbsp;&nbsp;&nbsp;</td></tr>
      <tr><td class="num">00232</td><td class="num">191</td><td class="num">CP)+20</td>
      <td class="num">CP)+19</td><td class="num">,00&nbsp;&nbsp;&nbsp;</td></tr>
      <tr><td class="num">00276</td><td class="num">194</td><td class="num">CP)+22</td>
      <td class="num">CP)+19</td><td class="num">,00&nbsp;&nbsp;&nbsp;</td></tr>
      <tr><td class="num">00522</td><td class="num">199</td><td class="num">CP)+26</td>
      <td class="num">CP)+27</td><td class="num">,14&nbsp;&nbsp;&nbsp;</td></tr>
    </tbody>
  </table>
  </div>

  {listing("statement-stamp-sites.txt",
           "The five sites, verbatim from the scan-verified target fixture. The "
           "first four are the TXH form of a GET; the fifth is the PZE form of a "
           "STOP RUN. Each names two pool cells.")}

  {listing("statement-stamp-pool-words.txt",
           "The eight pool words those sites name. 60 is a blank and 73 is a "
           "comma, so 730002606060 reads ',02   ' and 730104606060 reads ',14   '. "
           "The three ,00 sites share one word, CP)+19.")}

  <p><code>J 90.02.29</code> names the two quantities <code>STATEMENT-NUMBER</code>
  and <code>SUB-STATEMENT-NUMBER</code> and defines neither.</p>
  <p class="note">One correction to the evidence shipped with this record: the
  structure specification cites this passage as <code>J 90.02.28</code>. The page
  scan <code>images/page-168.png</code> prints <code>90.02.29</code> in its head
  and carries the <code>SYS)264</code> block, so the section code is
  <code>90.02.29</code>. Nothing else changes.</p>

  <h3>Why it stops chunk B1</h3>
  <p>The pool holds one entry per distinct word, so the three <code>,00</code>
  sites share <code>CP)+19</code>. Those equality classes fix the machine&#8209;word
  sub&#8209;pool at 23 entries, which fixes <code>CP)+37</code> at index 37, which
  is the location the <code>GN)088 EQU CP)+37</code> line prints in its LOC
  column. Two more <code>EQU</code> lines print <code>CP)+38</code> and
  <code>CP)+39</code> the same way. B1 matches the LOC column line for line, so it
  cannot close without the digits.</p>

  {listing("constant-pool-equ-lines.txt",
           "The three EQU lines. CP) sits at 01674, so CP)+37 is 01741, CP)+38 is "
           "01742 and CP)+39 is 01743 — exactly what the LOC column prints. Lose "
           "one pool entry and all three print wrong.")}

  <h3>The two positions the analysts took</h3>
  <p>They disagree on whether to fit a rule at all.</p>
  <p><strong>Do not fit one.</strong> No counting rule reproduces both non&#8209;zero
  values. Counting the commas of the source text gives 14 for statement 199, which
  is right, and 3 for statement 188, which is wrong. Counting one clause per verb
  gives 2 for statement 188, which is right, and 10 for statement 199, which is
  wrong. This is the <code>TS) BSS 7</code> case, and a fitted rule would be worse
  than an honest gap.</p>
  <p><strong>Fit this one.</strong> MM is the zero&#8209;based ordinal of the clause
  inside its statement, where each target of a multi&#8209;target MOVE counts as
  its own clause, <code>OPEN ALL FILES</code> is not counted, and
  <code>CLOSE ALL FILES</code> is. It reproduces all five sites. Its author
  rejected the comma count by reading the page scan of PDF p. 195 and confirming
  the comma after <code>INTERNAL.TOTALS</code> is present, and labelled the rule
  fitted rather than derived.</p>

  <h3>The options</h3>

  <div class="opt pick">
    <h3>A. Adopt the fitted rule, and label it fitted in the code and the record</h3>
    <p class="consequence">B1 closes. The compiler emits a value for every program,
    right for the sample and unverifiable anywhere else. Two of its parameters
    &mdash; excluding OPEN, including CLOSE &mdash; rest on one site each.
    Reversing it costs one function.</p>
  </div>

  <div class="opt">
    <h3>B. Take the five attested pairs as a table, the way <code>TS)</code> takes 7</h3>
    <p class="consequence">B1 closes for the sample. Nothing generalises: a table
    keyed by statement number gives a new program no value at all, so the compiler
    would have to refuse or invent one anyway. This is weaker than
    <code>TS) BSS 7</code>, where a constant at least answers for every program.</p>
  </div>

  <div class="opt">
    <h3>C. Emit one constant for every stamp</h3>
    <p class="consequence">The sample itself needs three different values, so the
    oracle fails on statements 188 and 199. Not viable.</p>
  </div>

  <div class="ask"><span class="label">Recommendation &mdash; A</span>
  <p><code>TS) BSS 7</code> and this are not the same case, and the difference is
  what decides it. A constant answers <code>TS)</code> because the sample shows one
  value. Here the sample shows three values, so some rule is required for the
  oracle to close at all; the only question is which.</p>
  <p>The fitted rule reproduces five sites out of five, and the honest response is
  to adopt it with the label attached, not to decline to have a rule. The label is
  what protects a later reader.</p></div>
</section>

<section class="item needs">
  <div class="itemhead"><span class="chip call">Your call</span>
  <h2>The per-section maximum of result storage</h2></div>
  <p class="eyebrow">And the recommendation is to let one bounded decode run
  before you rule</p>

  <h3>What the print shows</h3>
  <p><code>RS) BSS 30</code> reserves 30 words. The listing's own addresses give
  the split, at two words per cell:</p>
  <div class="scroll">
  <table>
    <thead><tr><th>Reference</th><th>Object address</th><th>What it fixes</th></tr></thead>
    <tbody>
      <tr><td class="num">RS)0</td><td class="num">01621</td><td>section 0 starts here</td></tr>
      <tr><td class="num">RS)1</td><td class="num">01623</td><td>a cell is two words</td></tr>
      <tr><td class="num">1.RS)0</td><td class="num">01627</td><td>section 0 holds 3 cells</td></tr>
      <tr><td class="num">2.RS)0</td><td class="num">01633</td><td>section 1 holds 2 cells</td></tr>
      <tr><td class="num">3.RS)1</td><td class="num">01643</td><td>section 2 holds 3 cells</td></tr>
    </tbody>
  </table>
  </div>
  <p>Sections 3, 4 and 5 share the remaining 7 cells. Sections 0, 1 and 2 reserve
  3, 2 and 3 cells and reference 2, 1 and 1.</p>

  {listing("result-storage-references.txt",
           "Every reference the program makes to result storage, the reservation "
           "line, and the line the reservation width moves. Octal 36 is 30 "
           "decimal, so RS) BSS 30 is 15 cells.")}

  <p><code>J 90.02.03</code> states a rule: &ldquo;N is the sum of maximum Result
  Storage used in each section.&rdquo; It does not say what &ldquo;maximum
  used&rdquo; counts.</p>

  <h3>Why it stops chunk B1</h3>
  <p><code>RS)</code> is the first block of Location Counter 1, so its width moves
  every origin below it. <code>BGN 2,PI)1</code> prints the address of
  <code>PI)1</code>, and that line is the second content line of the whole
  listing. Get 30 wrong and the oracle fails on line 2.</p>

  <h3>Why this is not the <code>TS)</code> case</h3>
  <p>Three differences, and each cuts the same way.</p>
  <ul>
    <li><strong>The manual states a rule for <code>RS)</code> and states none for
    <code>TS)</code>.</strong> Freezing 30 as a constant contradicts a documented
    rule; freezing 7 filled a documented silence.</li>
    <li><strong>There are four data points, not one.</strong> Sections 0, 1 and 2
    each give a reserved count, and section 3 gives a lower bound of 2.</li>
    <li><strong>A lead exists and has not been run down.</strong> The reserved
    counts 3, 2 and 3 match the number of binary operators in each section's
    largest expression: statement 203's
    <code>(WORKING HOURS * 1.5 -20) * MASTER RATE</code> has three, statement 212's
    <code>WORKING FICA - (MASTER FICA - 144.00)</code> has two, statement 215's
    <code>0.18 * (WORKING GROSS - 13 * MASTER EXEMPTIONS)</code> has three. The
    lead is not clean: statement 207 in section 0 has five operators and compiles
    to no result storage at all, because an equal&#8209;scale chain needs no
    temporary. A count of operators that need a temporary is the shape to
    test.</li>
  </ul>

  <h3>The options</h3>

  <div class="opt pick">
    <h3>A. Run one bounded decode first</h3>
    <p class="consequence">Six sections, four constraints, one named hypothesis. If
    it lands, <code>RS)</code> gets a derived rule and B1 closes with no fitted
    number. If it fails, the answer returns here with the search recorded.</p>
  </div>

  <div class="opt">
    <h3>B. Freeze 30 as a constant now</h3>
    <p class="consequence">B1 closes today. Every other program gets the sample's
    30 words whatever it needs, and the record has to say that a documented rule
    was set aside without being decoded.</p>
  </div>

  <div class="opt">
    <h3>C. Reserve what each section references</h3>
    <p class="consequence">Gives 12 words, not 30. The oracle fails, so this is not
    viable alone.</p>
  </div>

  <div class="ask"><span class="label">Recommendation &mdash; A</span>
  <p>The hunt is bounded by the evidence: six sections and one hypothesis, not the
  eleven&#8209;agent sweep <code>TS)</code> needed. <code>TS)</code> earned its
  constant because both manuals were silent and every reading was refuted.</p>
  <p>Here <code>J 90.02.03</code> states the rule and we have not finished reading
  it. If the decode fails, freezing 30 stays available and the record will then say
  plainly that it was tried.</p></div>
</section>

<section class="item needs">
  <div class="itemhead"><span class="chip call">Your call</span>
  <h2>The decode ran on 15 August 2026, and it failed</h2></div>

  <p>Two independent decoders ran the search Jack authorized, one from a
  1962-compiler-internals lens and one as a systematic enumeration of counting
  rules, neither knowing of the other. Both returned <strong>refuted</strong>,
  and their refutations converge on one structure. An adversarial verification
  stage stood ready and received no candidate to attack.</p>

  <h3>What the search established</h3>
  <ul>
    <li><strong>The heads are derivable.</strong> Counting the binary operators
    of the largest park&#8209;bearing clause expression, with straight
    equal&#8209;scale chains exempt and a conversion counted as a node,
    reproduces sections 0, 1 and 2 exactly &mdash; 3, 2, 3 &mdash; and lands
    section 3's hard floor of 2. Statement 207's six&#8209;operand chain is
    exempt and charges nothing, which is what saves section 0.</li>
    <li><strong>The tail refutes every untuned rule.</strong> Sections 4 and 5
    &mdash; SEARCH and DEPARTMENT.END &mdash; contain no SET, no park and no
    result&#8209;storage reference. Every head&#8209;compatible counter values
    them at a combined 3 or less, so the tail caps at 5 cells against the
    attested 7.</li>
    <li><strong>The split is unobservable.</strong> Splits as different as
    3&#8239;+&#8239;3&#8239;+&#8239;1, 3&#8239;+&#8239;1&#8239;+&#8239;3 and
    2&#8239;+&#8239;4&#8239;+&#8239;1 each satisfy every hard constraint, and
    nothing in the listing separates them. Any weight that lifts the tail to
    exactly 7 is tuned against the very sum it predicts.</li>
    <li><strong>The manuals do not close the gap.</strong> <code>J 90.02.03</code>
    names no counting basis. The only other &ldquo;result storage&rdquo; in
    either manual, <code>J 90.03.05</code>, is the loader's load&#8209;time
    expression bank &mdash; a fixed roster of cells 0 to 6, a different
    mechanism sharing the name, and its fixed size contradicts section 0's
    attested 3.</li>
  </ul>
  <p class="note">The systematic pass enumerated 24 rule families with the
  single constraint that killed each; the internals pass enumerated 15 and swept
  both manuals for a compiler-side storage model. The full trails, the checks
  behind every number, and the evidence pack the decoders read ship in
  <code>evidence/rs-decode/</code>. File paths under a session scratchpad named
  in those reports died with the session; the pack they name is the copy
  shipped here.</p>

  <h3>The options now</h3>

  <div class="opt pick">
    <h3>A. Pin the attested reservation as a constant of the sample</h3>
    <p class="consequence">Sections 0, 1 and 2 take 3, 2 and 3 cells, each
    attested by a base address the listing prints; the 7&#8209;cell tail is one
    undivided block, because its split is unobservable. Total 30 words. This is
    <code>TS) BSS 7</code>'s treatment: for any program but the sample the
    figure is unverifiable, and the record says so. The head rule is recorded
    as a finding, not implemented &mdash; implementing it would need a tail it
    cannot produce.</p>
  </div>

  <div class="opt">
    <h3>B. Freeze the total 30 with no per-section commitment</h3>
    <p class="consequence">Identical for chunk B1, which needs only the block
    width. But chunk B3 must place park addresses &mdash; the listing prints
    01621, 01627, 01633 and 01641 as section bases &mdash; so the per-section
    figures get pinned then anyway, and this option only defers the same
    decision to a chunk that is worse placed to record it.</p>
  </div>

  <div class="opt">
    <h3>C. Implement the head rule with a fitted tail closure</h3>
    <p class="consequence">Presents a fit as a derivation. Both decoders exhibit
    multiple closures that fit every constraint and contradict each other, so
    the choice among them is arbitrary, and M4-4 as amended forbids exactly this
    move for <code>TS)</code>.</p>
  </div>

  <div class="ask"><span class="label">Recommendation &mdash; A</span>
  <p>The decode was the honest test of <code>J 90.02.03</code>'s sentence, and
  it returned the same verdict twice from two directions. The rule the manual
  gestures at cannot be recovered from one artifact whose last two sections
  never touch the storage they reserve.</p>
  <p>Pin the attested numbers, label them attested, and record the head rule as
  a finding for a second listing to test. One artifact overturns this: the
  storage map of another compiled program.</p></div>
</section>

<section class="item">
  <h2>What both items share, and what neither is</h2>
  <p>Both are numbers the compiler must emit that rest on one 1962 listing.
  Neither is a peer collision: no two authorities in the repository require
  different things. They are gaps in the evidence, and they stop chunk B1 because
  chunk B1 matches an address column line for line, where a wrong number is
  visible immediately.</p>
  <p>The catalogue behind them is not in doubt. Eight analysts derived the shapes
  independently, a ninth walked all 42 statements against them, and the walk lands
  every statement boundary and sums to the 796 words the location column holds.
  <code>test/fixtures/90.05-object-code-notes.md</code> holds the catalogue, and
  its own &ldquo;What is ours&rdquo; section lists 40 rules that rest on the print
  alone. These two are the only two that stop the work.</p>
  <p class="note">That notes file is in flight and uncommitted, on branch
  <code>m4s2-chunk-b1</code>, so it carries no link here. The eight
  specifications and the ninth pass's report ship in <code>evidence/</code>.</p>
</section>

<footer>
  <p>Every listing excerpt above is quoted from
  <a href="{GH}/test/fixtures/90.05-object-listing.target">the object listing
  target</a>, the repository's scan&#8209;verified transcription, and ships in
  <code>crops/</code> as the same plain text. The two manual passages are
  <a href="{GH}/comtran-manuals/J28-6169/90.02-generated-code.md">Appendix
  90.02</a>. The six source statements the counts above rest on ship in
  <code>evidence/source-statements.txt</code>, quoted from
  <a href="{GH}/comtran-manuals/J28-6169/90.05-sample-program.md">Appendix
  90.05</a>.</p>
  <p>This record carries no image plates. The object listing is a text artifact
  here, not a glyph reading, and the target fixture it is quoted from is already
  scan&#8209;verified. The two page scans the arguments cite are
  <a href="{GH}/comtran-manuals/J28-6169/images/page-195.png">PDF p. 195</a>, for
  the comma after <code>INTERNAL.TOTALS</code>, and
  <a href="{GH}/comtran-manuals/J28-6169/images/page-168.png">PDF p. 168</a>, for
  the section code of <code>SYS)264</code>.</p>
</footer>
</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
