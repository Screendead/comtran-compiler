"""Assemble the chunk A4 review page, embedding each crop as a data URI.

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
    "690c490d479fdc1b930d036529c5b6bf47850ff8"
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
<title>Chunk A4 — three listing pages, and what needs your call</title>
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
.chip.ocr {{ color:var(--stamp); background:var(--stamp-soft); }}
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
.rulings {{ border:1px solid var(--settled); border-left:3px solid var(--settled);
            padding:1.15rem 1.3rem; background:var(--raised); }}
.rulings .label {{ font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
                   text-transform:uppercase; color:var(--settled); display:block;
                   margin-bottom:.55rem; }}
.rulings ul {{ margin:0; padding-left:1.15rem; }}
.rulings li {{ margin-bottom:.42rem; }}
.rulings p.note {{ margin:.75rem 0 0; font-size:.9rem; color:var(--muted); }}
@media (prefers-reduced-motion:reduce) {{ * {{ animation:none!important; transition:none!important; }} }}
</style>
</head>
<body>

<main>
<header>
  <p class="eyebrow">M4 stage 2 &middot; chunk A4 &middot; prepared 9 August 2026</p>
  <h1>Three listing pages, measured against their scans</h1>
  <p class="standfirst">Listing pages 11, 12 and 13 &mdash; PDF pp. 202 to 204 of
  J28&#8209;6169. Every reading below comes from the page scans. Three items want
  your eye, and two decisions are yours.</p>
</header>

<section>
  <div class="rulings"><span class="label">Rulings &middot; 9 August 2026</span>
    <ul>
      <li><strong><code>BL)3</code> stands</strong>, provisionally. Jack read the
      plate, built independent arguments for both readings, and could not decide it
      either. It rests on name structure and on the prefix's attestation elsewhere
      in the listing, and on nothing in this page's ink.</li>
      <li><strong>The mark at 00465 is not a period.</strong> Confirmed.</li>
      <li><strong>The mark at 00376 is not a period.</strong> Confirmed.</li>
      <li><strong>Option B on the conversion.</strong> The seven blank-line
      corrections are authorized and applied, and each later chunk now authorizes
      its own pages as it lands rather than waiting for the end of the scan pass.</li>
    </ul>
    <p class="note">The chips below record what each item asked for when the
    document was put to Jack. They are left as they were, so the record shows the
    question as well as the answer.</p>
  </div>
</section>

<section>
  <div class="answer">
    <ol>
      <li><strong>All three pages agree with the target on every content line.</strong>
      165 lines, six fields each, zero disagreements.</li>
      <li><strong>Three readings rest on judgment rather than on ink.</strong> One of
      them I want your own eyes on, because the ink genuinely does not decide it.</li>
      <li><strong>Seven blank-line corrections to the manual conversion are now
      waiting on you.</strong> By the current plan they stay held until the whole
      scan pass ends.</li>
      <li><strong>The branch is pushed and green.</strong> Opening the pull request
      is yours.</li>
    </ol>
  </div>
</section>

<section>
  <h2>How the pages were read</h2>
  <p>Each page went to one reader whose only permitted input was its own 150&#8209;dpi
  scan. No transcription, no target, no design record, no other page. Each fitted
  its own character grid from ink, because every page has its own registration,
  then rebuilt the page as text at the columns it measured. The comparison against
  the target is plain code, never a reader.</p>
  <div class="scroll">
  <table>
    <thead><tr><th>Listing page</th><th>PDF page</th><th>Deskew</th><th>Advance</th>
    <th>Line pitch</th><th>Grid fit</th></tr></thead>
    <tbody>
      <tr><td class="num">11</td><td class="num">202</td><td class="num">0.935&deg;</td>
      <td class="num">9.26708 px</td><td class="num">15.2145 px</td>
      <td>rms 0.432 px over 2006 centroids</td></tr>
      <tr><td class="num">12</td><td class="num">203</td><td class="num">0.855&deg;</td>
      <td class="num">9.31916 px</td><td class="num">15.203 px</td>
      <td>rms 0.585 px over 2026 centroids</td></tr>
      <tr><td class="num">13</td><td class="num">204</td><td class="num">0.920&deg;</td>
      <td class="num">9.29600 px</td><td class="num">15.2924 px</td>
      <td>rms 0.478 px over 2063 centroids</td></tr>
    </tbody>
  </table>
  </div>
  <p>Every page prints two blank lines between its head and its first content line,
  where the manual conversion holds one. Every page prints 55 content lines, with
  the last in slot 57. That is now seven pages of eighteen carrying the same frame.</p>
</section>

<section class="item needs">
  <div class="itemhead"><span class="chip ocr">Human OCR</span>
  <h2>One glyph the ink cannot decide</h2></div>
  <p class="eyebrow">Listing page 12 &middot; PDF p. 203 &middot; location 00361</p>
  <p>The operand of the <code>CAL</code> on line 7 reads <code>?L)3</code>. This print
  chain renders <code>B</code> and <code>8</code> as the same double&#8209;loop form, and
  on this page the two classes do not separate by any test the reader could run.</p>

  {img("a1-bl3-line.png", "Listing page 12 line 7 at four times scale",
       "The whole line at 4&times;. Location 00361, machine word 4500 00 0 01670, "
       "control group 10001, label GN)068, mnemonic CAL, then the operand in question.")}

  {img("a2-bl3-compare.png", "The doubtful glyph beside three certain B and two certain 8 glyphs",
       "At 14&times;: the glyph in question, then every certain B the page prints "
       "(BONDEDUCTION twice, PUBLICATIONS in the head), then two certain 8s "
       "(10/18/61 in the head, GN)068 on this same line). The B glyphs are "
       "double loops too. That is the whole problem.")}

  <p><strong>Why the ink does not settle it.</strong> Normalised cross&#8209;correlation
  puts the doubtful glyph at 0.820&ndash;0.874 against six certain <code>8</code>s and
  0.622&ndash;0.851 against three certain <code>B</code>s. Run the same test between the
  two classes and the certain <code>B</code>s score 0.755&ndash;0.893 against the certain
  <code>8</code>s. The ranges overlap, so the test carries no information. Left&#8209;edge
  straightness fails too, because the <code>B</code> in the page head has a broken outer
  column like an <code>8</code>. Left&#8209;to&#8209;right ink balance gives 0.49, 0.52 and
  0.57 for <code>B</code>, 0.43 to 0.55 for <code>8</code>, and 0.50 for this glyph.</p>

  <p><strong>What decided it, and what corroborates it.</strong> The reader chose
  <code>BL)3</code> on name structure: every other prefix on the page is either all
  letters (<code>SYS</code>, <code>GN</code>, <code>CP</code>) or a single digit
  (<code>1</code>, <code>2</code>, <code>5</code>, <code>6</code>), so <code>8L</code>
  would be unique. Two things it could not see agree. The manual conversion reads
  <code>BL)3</code>, and <code>BL)</code> is the block prefix the rest of the listing
  uses &mdash; listing page 10 prints <code>BL)2,,15</code>, and stage 1 already derives
  <code>BL)</code> for the storage map.</p>

  <div class="ask"><span class="label">What I need from you</span>
  <p>Look at the plate above and say whether you read <code>BL)3</code> or
  <code>8L)3</code>. I have recorded it as <code>BL)3</code> and recorded plainly that
  the ink does not choose. Nothing downstream breaks either way today, but this is the
  one reading in the chunk that a later reader could reasonably overturn, so it is
  worth your eyes now rather than at M6.</p></div>
</section>

<section class="item needs">
  <div class="itemhead"><span class="chip call">Your call</span>
  <h2>A faint mark, judged not to be a character</h2></div>
  <p class="eyebrow">Listing page 13 &middot; PDF p. 204 &middot; location 00465</p>
  <p>A small mark prints just right of the control group. The reader left it out of the
  transcription and recorded why.</p>

  {img("b1-00465-line.png", "The 00465 line at five times scale",
       "The line at 5&times;, from the location field through the control group.")}

  {img("b2-00465-compare.png", "The mark beside two certain periods from the same page",
       "At 16&times;: the mark, then two certain periods from the same page. The "
       "periods are larger, solid black and centred in their cells.")}

  <p><strong>The measurements.</strong> The mark's centroid sits at column 29.63, where
  every certain period on the page lands within 0.07 of an integer column. It is two
  rows tall and three pixels wide, where a certain period is four to five of each, and
  it never reaches solid black. Its bottom sits one row above the digit baseline, and
  this page's commas descend to or below it. The nearest form rule is four rows away,
  so it is not rule bleed.</p>
  <p><strong>The conversion agrees</strong> &mdash; it prints nothing there either, which
  is a second independent reading. The fallback, if you disagree, is a period at
  column 30.</p>

  <div class="ask"><span class="label">What I need from you</span>
  <p>Confirm the mark is not a character, or overturn it. My reading is that the
  measurement is decisive and the record is right as written.</p></div>
</section>

<section class="item needs">
  <div class="itemhead"><span class="chip call">Your call</span>
  <h2>A second mark, where low zoom misleads</h2></div>
  <p class="eyebrow">Listing page 12 &middot; PDF p. 203 &middot; location 00376</p>
  <p>The same class of judgment, and the one place in this chunk where what the eye sees
  at ordinary magnification disagrees with what the ink measures. I am showing both.</p>

  {img("c1-00376-line.png", "The 00376 line at five times scale",
       "At 5&times; the mark after the control group 10010 reads convincingly as a "
       "period. This is the misleading view.")}

  {img("c2-00376-compare.png", "The mark beside two certain periods from the same page",
       "At 16&times; it does not. The mark is grey and roughly half the area of the "
       "two certain periods beside it, which are solid black.")}

  <p><strong>The measurements.</strong> Four ink pixels at a darkest value of 26, where
  every printed period on this page is 11 to 15 pixels and reaches 0. Its centroid sits
  at column 29.80, between cells, where printed periods sit three to seven pixels inside
  their own cell. It occupies two image rows, above the baseline.</p>
  <p><strong>The conversion agrees</strong> here too, and prints nothing.</p>

  <div class="ask"><span class="label">What I need from you</span>
  <p>Same question, and the same recommendation: a speck, not a period. I flag it
  separately because the 5&times; plate is genuinely persuasive the other way, and if
  you only glanced at that one you would rightly disagree with me.</p></div>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>A reading the reader reversed on itself</h2></div>
  <p class="eyebrow">Listing page 11 &middot; PDF p. 202 &middot; location 00344</p>
  <p>Nothing needed from you here. It is in the doc because it is the one reading in the
  chunk that changed, and because the defect behind it will recur on the eleven pages
  still to verify.</p>

  {img("d1-0602-row48.png", "Row 48 of listing page 11 at five times scale",
       "The row at 5&times;, location and machine word.")}

  {img("d2-0602-compare.png", "The broken zero beside two clean zeros from the same page",
       "At 16&times;: the glyph in question, then the same digit position on the two "
       "other rows of this page that print the same instruction. The ring is open on "
       "the right in the first, closed in the other two.")}

  <p>The reader first read the machine word as <code>0622</code> and corrected it to
  <code>0602</code>. This print chain drops one vertical stroke of a <code>0</code>, and
  the broken glyph mimics a <code>3</code> or a <code>2</code>. Three lines of evidence
  reversed it: a certain <code>3</code> on the page carries a leftward waist where this
  glyph carries a straight right stroke; the glyph correlates 0.886 against a provably
  broken <code>0</code> elsewhere on the page, against 0.798 and 0.825 for the two
  certain <code>3</code>s in its own row; and the mnemonic is <code>SLW</code>, which
  prints opcode <code>0602</code> on two other rows of the same page.</p>
</section>

<section class="item needs">
  <div class="itemhead"><span class="chip call">Your call</span>
  <h2>Seven corrections to the manual conversion now wait for you</h2></div>
  <p>The conversions are read&#8209;only and a change needs your authorization. Chunk A4
  takes the open set from four to seven.</p>
  <div class="scroll">
  <table>
    <thead><tr><th>Listing page</th><th>PDF page</th><th>The print</th>
    <th>The conversion</th><th>Measured</th></tr></thead>
    <tbody>
      <tr><td class="num">8</td><td class="num">199</td><td class="num">3 blanks</td>
      <td class="num">1</td><td class="num">chunk A3</td></tr>
      <tr><td class="num">9</td><td class="num">200</td><td class="num">2 blanks</td>
      <td class="num">1</td><td class="num">chunk A3</td></tr>
      <tr><td class="num">10</td><td class="num">201</td><td class="num">2 blanks</td>
      <td class="num">1</td><td class="num">chunk A3</td></tr>
      <tr><td class="num">11</td><td class="num">202</td><td class="num">2 blanks</td>
      <td class="num">1</td><td class="num">chunk A4</td></tr>
      <tr><td class="num">12</td><td class="num">203</td><td class="num">2 blanks</td>
      <td class="num">1</td><td class="num">chunk A4</td></tr>
      <tr><td class="num">13</td><td class="num">204</td><td class="num">2 blanks</td>
      <td class="num">1</td><td class="num">chunk A4</td></tr>
      <tr><td class="num">21</td><td class="num">212</td><td class="num">2 blanks</td>
      <td class="num">1</td><td class="num">chunk A2</td></tr>
    </tbody>
  </table>
  </div>
  <p>Eleven object pages are still unverified, and the conversion holds one blank on
  every one of them except PDF p. 208, where a measurement last week found two. The
  likely end state is that the conversion flattened a two&#8209;line gap across the whole
  object listing.</p>
  <p><strong>Nothing waits on this.</strong> The target already carries the measured
  counts, so the compiler work is unblocked either way. The only cost of holding is
  that the read&#8209;only artifact stays wrong in seven places meanwhile.</p>
</section>

<section>
  <h2>The options on the conversion</h2>

  <div class="opt pick">
    <h3>A. Hold all seven until the scan pass ends, then authorize the set at once</h3>
    <p class="consequence">This is the current plan, written into HANDOVER. One
    authorization covers all eighteen object pages, and you review one coherent set
    instead of six. Reversible at any time. Cost: the conversion stays wrong in seven
    places for the length of chunks A5 to A8.</p>
  </div>

  <div class="opt">
    <h3>B. Authorize these seven now, take the rest as they land</h3>
    <p class="consequence">The conversion becomes right where it has been measured, and
    stays wrong only where it has not. Cost: you review a small set five or six times
    rather than one set once, and each pass carries the same overhead of checking the
    measurement before you sign it.</p>
  </div>

  <div class="opt">
    <h3>C. Authorize now and change the rule, so each chunk authorizes its own pages</h3>
    <p class="consequence">Same as B, plus the standing rule changes and later chunks
    stop queueing candidates. Cost: it drops the one property holding the set together
    &mdash; that a single reviewer sees every page's count side by side and can catch a
    page that disagrees with the pattern.</p>
  </div>

  <p><strong>My recommendation is A.</strong> Nothing is blocked, the measurements are
  all on disk and dated, and the seven counts are more reviewable as one table across
  eighteen pages than as six separate asks. B only becomes right if you expect the pass
  to stall part&#8209;way, in which case the measured pages should not stay hostage to
  the unmeasured ones.</p>
</section>

<section>
  <h2>The other thing that is yours</h2>
  <p>The branch <code>m4s2-pages-202-204</code> is pushed, with four commits: one per
  page and one closing the chunk. All 994 tests pass, the decks are fresh, and the
  sample compiles clean. Opening the pull request is your call, not mine.</p>
  <p>Files it touches:
  <a href="{GH}/test/fixtures/90.05-object-listing-notes.md">the verification record</a>,
  <a href="{GH}/docs/HANDOVER.md">HANDOVER</a>,
  <a href="{GH}/docs/design/m4-codegen.md">the M4 design record</a>,
  <a href="{GH}/tool/object_listing_target_source.dart">the target generator</a>,
  <a href="{GH}/test/object_listing_target_test.dart">its test</a>, and the generated
  target itself.</p>
</section>

<footer>
  <p>Chunk A4 cost about 684&#8239;000 subagent tokens over three readers, at 30 to 45
  minutes each. Chunk A5 takes listing pages 14 to 16, PDF pp. 205 to 207. Eleven
  object pages remain.</p>
  <p>One process fault is recorded in the notes file: two readers ran at once in one
  scratch directory and collided over a working file. No reading is affected, and each
  reader's grid was re&#8209;checked against the page it was asked to read. Later chunks
  give each reader its own directory.</p>
</footer>
</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
