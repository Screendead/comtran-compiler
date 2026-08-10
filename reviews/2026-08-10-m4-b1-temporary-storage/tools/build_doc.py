"""Assemble the temporary-storage review page, embedding each crop as a data URI.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: every image is embedded, so the file renders
from any location, and the crops ship alongside it as separate materials.
"""

import base64
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

GH = (
    "https://github.com/Screendead/comtran-compiler/blob/"
    "caf93223e67b209cc414591252cd03d81f4f3452"
)


def img(name, alt, caption):
    with open(os.path.join(REC, "crops", name), "rb") as fh:
        b64 = base64.b64encode(fh.read()).decode("ascii")
    return (
        f'<figure><div class="plate"><img src="data:image/png;base64,{b64}" '
        f'alt="{alt}"></div><figcaption>{caption}</figcaption></figure>'
    )


HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Temporary storage has no rule left to find</title>
<style>
:root {{
  --paper:#F7F8F6; --raised:#FFFFFF; --ink:#14171A; --muted:#5C6560;
  --rule:#C9CFC8; --hair:#E1E5DF; --stamp:#B3261E; --stamp-soft:#FBEAE8;
  --settled:#40685A; --settled-soft:#EAF1ED;
  --serif:"Iowan Old Style","Palatino Linotype",Palatino,"Book Antiqua",Georgia,serif;
  --mono:ui-monospace,"SF Mono",SFMono-Regular,Menlo,Consolas,monospace;
}}
@media (prefers-color-scheme:dark) {{
  :root:not([data-theme="light"]) {{
    --paper:#141715; --raised:#1C201D; --ink:#E7EBE5; --muted:#9AA69D;
    --rule:#3A423C; --hair:#2A302C; --stamp:#FF7A6B; --stamp-soft:#33201D;
    --settled:#7FB8A2; --settled-soft:#1B2A24;
  }}
}}
:root[data-theme="dark"] {{
  --paper:#141715; --raised:#1C201D; --ink:#E7EBE5; --muted:#9AA69D;
  --rule:#3A423C; --hair:#2A302C; --stamp:#FF7A6B; --stamp-soft:#33201D;
  --settled:#7FB8A2; --settled-soft:#1B2A24;
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
blockquote {{ margin:.9rem 0; padding:.1rem 0 .1rem 1rem; border-left:2px solid var(--rule);
              color:var(--muted); }}
blockquote p {{ margin:0 0 .5rem; }}
blockquote p:last-child {{ margin:0; }}
.eyebrow {{ font-family:var(--mono); font-size:.7rem; letter-spacing:.16em;
            text-transform:uppercase; color:var(--muted); margin:0 0 .7rem; }}
header {{ border-bottom:2px solid var(--ink); padding-bottom:1.4rem; }}
header p.standfirst {{ font-size:1.06rem; color:var(--muted); margin:.75rem 0 0; }}
section {{ display:flex; flex-direction:column; gap:.2rem; }}

.answer {{ background:var(--raised); border:1px solid var(--hair);
           border-left:3px solid var(--ink); padding:1.15rem 1.3rem; }}
.answer ol {{ margin:0; padding-left:1.2rem; }}
.answer li {{ margin-bottom:.5rem; }}

.rulings {{ border:1px solid var(--settled); border-left:3px solid var(--settled);
            background:var(--settled-soft); padding:1.15rem 1.3rem; }}
.rulings h2 {{ margin:0 0 .7rem; color:var(--settled); }}
.rulings p {{ margin:0 0 .7rem; }}
.rulings p:last-child {{ margin:0; }}

.correction {{ border-left:3px solid var(--stamp); background:var(--stamp-soft);
               padding:.9rem 1.1rem; margin:0 0 1.15rem; }}
.correction p {{ margin:0 0 .7rem; }}
.correction p:last-child {{ margin:0; font-size:.92rem; color:var(--muted); }}

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

figure {{ margin:1rem 0 1.2rem; }}
.plate {{ background:#FFFFFF; border:1px solid var(--rule); padding:.55rem;
          overflow-x:auto; }}
.plate img {{ display:block; max-width:100%; height:auto; image-rendering:crisp-edges; }}
figcaption {{ font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
              margin-top:.5rem; }}

.ask {{ background:var(--stamp-soft); border:1px solid var(--stamp); padding:.9rem 1.1rem;
        margin:.9rem 0 0; }}
.ask p {{ margin:0; }}
.ask .label {{ font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
               text-transform:uppercase; color:var(--stamp); display:block; margin-bottom:.3rem; }}

.opt {{ border-left:3px solid var(--rule); padding:.15rem 0 .15rem 1rem; margin:0 0 1rem; }}
.opt.pick {{ border-left-color:var(--stamp); }}
.opt h3 {{ margin:0 0 .25rem; }}
.opt p {{ margin:0 0 .35rem; }}
.opt p:last-child {{ margin:0; }}
.consequence {{ font-size:.92rem; color:var(--muted); }}
footer {{ border-top:1px solid var(--rule); padding-top:1.2rem; font-size:.85rem;
          color:var(--muted); }}
@media (prefers-reduced-motion:reduce) {{ * {{ animation:none!important; transition:none!important; }} }}
</style>
</head>
<body>

<main>
<header>
  <p class="eyebrow">M4 stage 2 &middot; chunk B1 &middot; prepared 10 August 2026</p>
  <h1>Temporary storage has no rule left to find</h1>
  <p class="standfirst">The address spine of the 90.05 object program now closes to
  the word. Four of its five storage blocks have a sizing rule this project can
  state. The fifth, <code>TS)</code>, is reserved by the 1962 compiler and touched
  by nothing, and no source this project holds says how it got its size.</p>
</header>

<section class="rulings">
  <h2>Jack's ruling, 10 August 2026</h2>
  <p><strong>Option A. <code>TS)</code> takes the attested 7 as a constant, and no
  rule is invented for it.</strong> In his words: &ldquo;Agreed &mdash; 7 as
  constant. It&rsquo;s the best we can do.&rdquo;</p>
  <p>The ruling followed an eleven&#8209;agent hunt over both manuals, run after
  this record was first pushed. It refuted seven readings of the number &mdash;
  among them the operator&#8209;switch reading, which turned out to name a real
  mechanism the sample never uses &mdash; and left two, a fixed block the compiler
  always lays down and a pessimistic sizing pass the generator never drew on. One
  sample cannot separate them. The hunt also produced the correction above, and one
  finding that decides the option on its own: no word of the object program
  addresses any of the seven cells, so a compiler that sized temporary storage by
  what the code uses would have printed <code>TS) BSS 0</code>. Every rule that
  could be derived from the calling sequences is refuted by the one program that
  can check it.</p>
  <p><code>docs/design/m4-codegen.md</code> M4&#8209;4 as amended carries the
  decision, its basis, and an explicit instruction not to implement one cell per
  file, sections&#8209;plus&#8209;one, or any other rule that returns 7. No code
  carries the constant yet: all four block sizes enter <code>blockWords</code>
  together in chunk B1, because <code>originOf</code> sums the blocks declared
  ahead of its argument and sizing <code>TS)</code> while <code>RS)</code> is still
  absent would put <code>BL)1</code> at 01630 rather than the attested 01666.</p>
  <p>One artifact overturns it: the storage map of a second compiled COMTRAN
  listing. Nothing else will, and no further scan work on PDF p.&nbsp;215 can help
  &mdash; two readers have already read it independently and both print
  <code>TS) BSS 7</code>. The ink was never the question.</p>
</section>

<section>
  <div class="answer">
    <ol>
      <li><strong>The spine closes exactly.</strong> The procedure text runs 00165
      to 01620, 796 words with no gap, and that count alone puts Location
      Counter&nbsp;1 at 01621, which is where the listing prints it. The four
      origins after it then chain, and the constant pool ends on its attested
      last word.</li>
      <li><strong>Nothing in the program touches temporary storage.</strong> Not one
      word of the object program addresses those seven cells, by name or by absolute
      address. <strong>But reserving and never referencing is this compiler's habit,
      not a temporary&#8209;storage peculiarity</strong> &mdash; result storage
      reserves 30 words and only 5 of them are addressed. The corrected table below
      replaces the one this record first printed.</li>
      <li><strong>The manual gives a sizing rule for result storage and none for
      temporary storage.</strong> The gap is specific, and it is not an artifact of
      how hard anyone looked.</li>
      <li><strong>The 7 is a computed number, not padding.</strong> The manual says
      the result-storage line is omitted when no result storage is needed, so the
      compiler drops a block it does not want. It kept this one and wrote 7 in it.</li>
      <li><strong>Nothing is blocked.</strong> B1 continues whichever way you rule.
      What your answer changes is what the compiler claims about itself.</li>
    </ol>
  </div>
</section>

<section>
  <h2>How the spine was derived</h2>
  <p>The oracle for B1 is the LOC column of the object listing, matched line for
  line. This reads that column back into the units it prints, so every word count
  is a measurement rather than a guess. The <code>+n</code> offset counter does the
  segmenting: it resets at every line that prints no <code>+n</code> of its own, so
  a unit is a headed line and the run beneath it.</p>
  <p>Four line forms carry no word and each had to be handled separately &mdash; a
  label&#8209;only line, which hands its word to the next line; a label long enough
  to reach the mnemonic column, which keeps its own LOC and pushes its instruction
  down a line (M4&#8209;8.1); that continuation line; and an <code>EQU</code>, which
  prints its equated value in the LOC column, out of location order.</p>
  <div class="scroll">
  <table>
    <thead><tr><th>Quantity</th><th>Computed here</th><th>Printed by the listing</th></tr></thead>
    <tbody>
      <tr><td>Procedure text, first word</td><td class="num">00165</td><td class="num">00165</td></tr>
      <tr><td>Procedure text, last word</td><td class="num">01620</td><td class="num">01620</td></tr>
      <tr><td>Procedure text, span</td><td class="num">796 words, 0 gaps</td><td class="num">&mdash;</td></tr>
      <tr><td>Location Counter 1 origin, <code>RS)</code></td><td class="num">01621</td><td class="num">01621</td></tr>
      <tr><td><code>TS)</code> origin</td><td class="num">01657</td><td class="num">01657</td></tr>
      <tr><td><code>BL)</code> origin</td><td class="num">01666</td><td class="num">01666</td></tr>
      <tr><td><code>PI)</code> origin</td><td class="num">01671</td><td class="num">01671</td></tr>
      <tr><td>Constant pool origin</td><td class="num">01674</td><td class="num">01674</td></tr>
      <tr><td>Constant pool, last word</td><td class="num">01771</td><td class="num">01771</td></tr>
    </tbody>
  </table>
  </div>
  <p>Two of those rows deserve to be separated from the rest, because they are not
  all the same kind of claim. The span, 796 words, is counted from the LOC column of
  the procedure text and owes nothing to the block region; adding it to 00165 gives
  01621, and 01621 is where the listing independently prints the first reservation.
  That one is a derivation, and it is the result worth having.</p>
  <p>The four origins below it are a weaker thing, and the table should not be read
  as claiming otherwise. They chain from 01621 using the block sizes the listing
  itself prints, 30, 7, 3 and 3, so they check that the layout order in M4&#8209;4 is
  right and that no block is missing. They do not derive a single one of those four
  sizes. <code>tools/spine.py</code> is the script and
  <code>evidence/spine-derivation.txt</code> its full output.</p>
</section>

<section class="item needs">
  <div class="itemhead"><span class="chip call">Your call</span>
  <h2>What the compiler does with a block it cannot size</h2></div>

  <p>Here is the block, on PDF p.&nbsp;215. Five reservations, one line each,
  under the <code>USE 1</code> that opens Location Counter&nbsp;1.</p>

  {img("a1-reservations.png", "The five Location Counter 1 reservations on PDF p. 215",
       "PDF p. 215, listing page 24, deskewed &minus;0.90&deg;, cut at 3&times;. "
       "USE 1 with control word 5 00000 0 01621, then RS) BSS 30 at 01621, "
       "TS) BSS 7 at 01657, BL) BSS 3 at 01666, PI) BSS 3 at 01671, and the "
       "pool opening at 01674. The lines above and below are context and are "
       "clipped by the crop.")}

  <p>The 1962 compiler reserved seven words of temporary storage. Then it never
  used them. This is not a reading that needs your eye &mdash; the print is
  unambiguous &mdash; it is a fact about the program that has a consequence for
  ours.</p>

  <div class="scroll">
  <table>
    <thead><tr><th>Block</th><th>Rule in the manual</th><th>Reserved</th>
    <th>Distinct words addressed</th><th>Addressed by nothing</th></tr></thead>
    <tbody>
      <tr><td><code>PI)</code></td><td>exact: &ldquo;the total number of Positional
      Indicators&rdquo;</td><td class="num">3</td><td class="num">3</td><td class="num">0</td></tr>
      <tr><td><code>BL)</code></td><td>derived (M4&#8209;4)</td>
      <td class="num">3</td><td class="num">3</td><td class="num">0</td></tr>
      <tr><td><code>RS)</code></td><td>worst case: &ldquo;the sum of maximum Result
      Storage used in each section&rdquo;</td><td class="num">30</td>
      <td class="num">5</td><td class="num">25</td></tr>
      <tr><td><code>TS)</code></td><td>none</td><td class="num">7</td>
      <td class="num">0</td><td class="num">7</td></tr>
    </tbody>
  </table>
  </div>

  <div class="correction">
  <p><strong>Corrected 2026-08-10, and this weakens the argument above.</strong> The
  table this record first printed counted <em>addressing lines</em> &mdash;
  <code>RS)</code> 12 by name and 14 absolute, <code>BL)</code> 34, <code>PI)</code>
  11 &mdash; beside temporary storage's 0. Read that way, temporary storage looks
  uniquely dead. It is not. Those 14 result&#8209;storage lines reach only
  <strong>5 distinct words of the 30 reserved</strong>, so 25 result&#8209;storage
  words are addressed by nothing either.</p>
  <p>The table is now ordered by how well the manual documents the rule, because that
  is what over&#8209;reservation tracks. Where the rule is exact, the listing matches
  it exactly and every word is used. Where the rule is a worst case, the listing
  over&#8209;reserves by construction, since per&#8209;section maxima are summed
  rather than pooled. Where there is no rule at all, we get seven words and no user.
  <strong>Temporary storage is the undocumented end of a documented spectrum, not an
  anomaly.</strong> The recommendation below is unchanged &mdash; it never rested on
  temporary storage being unique &mdash; but a reader should not be left believing
  that it was.</p>
  <p>This came from a 2026&#8209;08&#8209;10 sweep of both manuals that was told to
  find whatever a temporary&#8209;storage&#8209;focused reader would walk past. The
  distinct&#8209;word counts were then measured independently against the target.</p>
  </div>

  <p>The second check matters as much as the first. A reference could have hidden
  in the assembled address of a word whose operand prints some other way, so every
  word in the listing was tested against the octal span 01657 to 01665. Nothing
  lands in it. <code>evidence/ts-references.txt</code> holds the counts.</p>

  {img("a2-reservations-in-place.png", "The same block with fifteen lines of context",
       "The same block at 2&times; with eight lines above and six below, so the tight "
       "crop above cannot be accused of hiding a neighbouring reference. Above the "
       "reservations: the Location Counter 2 pointer words at 01666 to 01670. Below "
       "them: the constant pool from 01674. Neither region touches temporary storage.")}

  <h3>What the manual says, and what it does not</h3>
  <p>[J 90.02.03] gives result storage a computation rule:</p>
  <blockquote><p>These instructions reserve the necessary cells for all Result
  Storage. N is the sum of maximum Result Storage used in each section.</p></blockquote>
  <p>[J 90.02.04] gives temporary storage its placement, and then this:</p>
  <blockquote><p>Temporary Storage cells are reserved immediately after Result
  Storage cells by the instruction <code>TS) BSS N</code> where N is the total
  number of cells to be reserved.</p></blockquote>
  <p>N is the number of cells to be reserved. The manual defines the symbol and
  declines to define the quantity. The two paragraphs are consecutive sections of
  one appendix, [J 90.02.03] and [J 90.02.04], so the omission is visible on the
  page rather than buried somewhere a reader might have missed.</p>

  <p>One further detail argues that a rule existed. The manual marks the
  result&#8209;storage reservation
  &ldquo;<em>Omitted if no Result Storages are required</em>&rdquo;, so this
  compiler does drop a block it has no use for. It did not drop temporary storage.
  It printed seven. Whatever the 1962 compiler counted to reach seven, it counted
  something this listing does not show.</p>

  <div class="ask"><span class="label">The question</span>
  <p>Does the compiler carry 7 as a number copied from the sample, and say so
  plainly in the design record? Or is there a route you want taken first?</p></div>

  <div class="opt pick">
    <h3>A. Carry 7 as a recorded constant, and record that the rule is unrecoverable</h3>
    <p class="consequence">The 90.05 listing diff closes and B1 has its oracle. Every
    other program compiled by this compiler gets seven words of temporary storage
    whether it wants seventy or none. A later reader is told, in the record and at
    the code, that this one number is copied from one sample and is not a rule.
    Reversing it costs nothing: the day evidence appears, a constant becomes a
    function and no address moves for the sample. M4&#8209;4's original wording
    already anticipated this exact outcome and pre&#8209;authorised it; its
    2026&#8209;08&#8209;05 amendment then replaced that with
    &ldquo;leave each size to the stage that can derive it&rdquo;, which B1 cannot
    do. Choosing A means saying which of the two wordings governs.</p>
  </div>

  <div class="opt">
    <h3>B. Reserve nothing, and let the diff fail on the block</h3>
    <p class="consequence">The compiler would claim nothing it cannot support. It is
    not viable and is listed because a record that shows only the workable options is
    not a record. <code>BL)</code> would land at 01657 instead of 01666, and every
    address after it moves, so the LOC column fails from that point to the end of the
    listing and B1 loses the oracle that defines it.</p>
  </div>

  <div class="opt">
    <h3>C. Derive a rule from the calling sequences and adopt it as a judgment call</h3>
    <p class="consequence">The compiler would behave like a compiler on every program
    rather than on one. Nothing would test it. Any rule has to return exactly 7 for a
    program whose text references temporary storage zero times, so it would be fitted
    to a single data point and then presented as a derivation, which is the one thing
    this project's method exists to prevent. Reversing it is the expensive option,
    because an invented rule spreads into the sizing code and into the design record
    and a later reader cannot easily tell it from a recovered one.</p>
  </div>

  <p><strong>My recommendation is A.</strong> It is the only option that keeps the
  oracle and tells the truth at the same time. The cost is real and it is worth
  naming: at M6 this project takes a second corpus, F's payroll example with the
  documented divergences applied (&sect;9.8), and that is where a copied constant
  will show. It will show visibly, as a wrong reservation on a printed line, which
  is the best way for a known weakness to fail.</p>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>The sparse generated-name counter is much less sparse than it looks</h2></div>
  <p>M4&#8209;6 warns that the generated&#8209;label counter is not dense in the
  print, and that a design assuming otherwise is wrong by construction. Counting the
  object pages alone makes that look severe: 33 names print, and 61 numbers in range
  never appear.</p>
  <p>Fifty&#8209;seven of those 61 are <code>GN)001</code> through
  <code>GN)057</code>, and they are not missing. They print on the source listing
  pages, where the M3 listing extension puts them. The object listing prints exactly
  <code>GN)000</code>, then <code>GN)058</code> through <code>GN)083</code>, then
  <code>GN)085</code>, <code>086</code>, <code>088</code>, <code>089</code>,
  <code>091</code> and <code>093</code>.</p>
  <p>So the sparseness M4&#8209;6 describes is real and it is small: four numbers,
  084, 087, 090 and 092, exactly the four that record names. The rule B1 has to find
  covers four names, not sixty&#8209;one. Nothing here changes a decision; it is
  recorded so the next person to count does not spend the afternoon I nearly
  spent.</p>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>Phase A and Phase B now overlap, on your instruction</h2></div>
  <p>M4&#8209;1 as amended has Phase A verify the whole target before any generator
  runs. You asked for B1 to start on 10 August 2026 while chunks A7 and A8 were still
  reading their page scans. That is the authorization, and M4&#8209;1 takes an
  amendment saying so.</p>
  <p>The reason behind the original order is not damaged by it. That order exists so
  the nineteen&#8209;page pass is not spent twice, and the pass was already running
  and cannot be re&#8209;spent. B1's oracle is the LOC column, and neither kind of
  correction those chunks can produce touches it: a blank&#8209;line count moves no
  address, and even chunk A6's content correction split one printed line into two
  where the second carries no LOC at all.</p>
</section>

<footer>
  <p>The five remaining object pages &mdash; listing pages 20 and 22 to 25 &mdash;
  were being read blind while this was written, two independent readers each. PDF
  p.&nbsp;215 is one of them, so the plate above comes from a page whose full
  reading is still open. The reservation lines are not in doubt, and nothing in this
  record depends on the rest of that page.</p>
  <p>Materials: <code>tools/spine.py</code> derives the spine and
  <code>tools/crops.py</code> cuts the plates.
  <code>evidence/spine-derivation.txt</code> and
  <code>evidence/ts-references.txt</code> are their output. The target the
  derivation reads is
  <a href="{GH}/test/fixtures/90.05-object-listing.target">the object&#8209;listing
  target</a>, built by
  <a href="{GH}/tool/object_listing_target_source.dart">its generator</a> from the
  manual conversion; the design record is
  <a href="{GH}/docs/design/m4-codegen.md">m4&#8209;codegen.md</a>, M4&#8209;4 and
  M4&#8209;6.</p>
</footer>
</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
