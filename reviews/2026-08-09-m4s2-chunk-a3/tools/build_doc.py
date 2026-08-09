"""Assemble the chunk A3 review page, embedding each crop as a data URI.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: every image is embedded, so the file renders
from any location, and the crops ship alongside it as separate materials.
"""

import base64
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")


def img(name, alt, caption):
    with open(os.path.join(REC, "crops", name), "rb") as fh:
        b64 = base64.b64encode(fh.read()).decode("ascii")
    return (
        f'<figure><div class="plate"><img src="data:image/png;base64,{b64}" '
        f'alt="{alt}"></div><figcaption>{caption}</figcaption></figure>'
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
main { max-width:47rem; margin:0 auto; display:flex; flex-direction:column; gap:2.4rem; }
h1 { font-size:clamp(1.7rem,4.2vw,2.4rem); line-height:1.16; margin:0; text-wrap:balance;
     letter-spacing:-0.015em; }
h2 { font-size:1.32rem; margin:0 0 .2rem; text-wrap:balance; letter-spacing:-0.01em; }
h3 { font-size:1.02rem; margin:1.6rem 0 .3rem; }
p, li { margin:0 0 .85rem; }
li:last-child { margin-bottom:0; }
ul, ol { padding-left:1.15rem; margin:0 0 .85rem; }
a { color:var(--ink); text-decoration-color:var(--rule); text-underline-offset:.16em; }
a:hover { text-decoration-color:var(--stamp); }
a:focus-visible { outline:2px solid var(--stamp); outline-offset:2px; border-radius:2px; }
code { font-family:var(--mono); font-size:.87em; background:var(--hair);
       padding:.08em .3em; border-radius:2px; }
pre { font-family:var(--mono); font-size:.78rem; line-height:1.55; background:var(--raised);
      border:1px solid var(--hair); padding:.8rem .9rem; overflow-x:auto; margin:.6rem 0 1rem; }
pre code { background:none; padding:0; font-size:1em; }
.eyebrow { font-family:var(--mono); font-size:.7rem; letter-spacing:.16em;
           text-transform:uppercase; color:var(--muted); margin:0 0 .7rem; }
header { border-bottom:2px solid var(--ink); padding-bottom:1.4rem; }
header p.standfirst { font-size:1.06rem; color:var(--muted); margin:.75rem 0 0; }
section { display:flex; flex-direction:column; gap:.2rem; }

/* The answer block, set like the head of the listing it describes. */
.answer { background:var(--raised); border:1px solid var(--hair);
          border-left:3px solid var(--ink); padding:1.15rem 1.3rem; }
.answer ol { margin:0; padding-left:1.2rem; }
.answer li { margin-bottom:.5rem; }

.chip { font-family:var(--mono); font-size:.66rem; letter-spacing:.14em;
        text-transform:uppercase; padding:.24em .6em; border-radius:2px;
        border:1px solid currentColor; white-space:nowrap; }
.chip.call { color:var(--stamp); background:var(--stamp-soft); }
.chip.ocr { color:var(--stamp); background:var(--stamp-soft); }
.chip.done { color:var(--settled); }
.itemhead { display:flex; gap:.75rem; align-items:baseline; flex-wrap:wrap;
            margin-bottom:.35rem; }
.item { border-top:1px solid var(--rule); padding-top:1.3rem; }
.item.needs { border-top:2px solid var(--stamp); }

table { border-collapse:collapse; width:100%; font-size:.87rem; }
.scroll { overflow-x:auto; margin:.5rem 0 1rem; }
th, td { text-align:left; padding:.42rem .7rem .42rem 0; border-bottom:1px solid var(--hair);
         vertical-align:top; }
th { font-family:var(--mono); font-size:.68rem; letter-spacing:.11em; text-transform:uppercase;
     color:var(--muted); font-weight:400; border-bottom:1px solid var(--rule); }
td.num { font-family:var(--mono); font-variant-numeric:tabular-nums; white-space:nowrap; }
tr.print td { font-weight:600; }

figure { margin:1rem 0 1.2rem; }
.plate { background:#FFFFFF; border:1px solid var(--rule); padding:.55rem;
         overflow-x:auto; }
.plate img { display:block; max-width:100%; height:auto; image-rendering:crisp-edges; }
figcaption { font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
             margin-top:.5rem; }

.ask { background:var(--stamp-soft); border:1px solid var(--stamp); padding:.9rem 1.1rem;
       margin:.9rem 0 0; }
.ask p { margin:0; }
.ask .label { font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
              text-transform:uppercase; color:var(--stamp); display:block; margin-bottom:.3rem; }

.opt { border-left:3px solid var(--rule); padding:.15rem 0 .15rem 1rem; margin:0 0 1rem; }
.opt.pick { border-left-color:var(--stamp); }
.opt h3 { margin:0 0 .25rem; }
.opt p { margin:0 0 .35rem; }
.opt p:last-child { margin:0; }
.consequence { font-size:.92rem; color:var(--muted); }
footer { border-top:1px solid var(--rule); padding-top:1.2rem; font-size:.85rem;
         color:var(--muted); }
.rulings { border:1px solid var(--settled); border-left:3px solid var(--settled);
           padding:1.15rem 1.3rem; background:var(--raised); }
.rulings .label { font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
                  text-transform:uppercase; color:var(--settled); display:block;
                  margin-bottom:.55rem; }
.rulings ul { margin:0; padding-left:1.15rem; }
.rulings li { margin-bottom:.42rem; }
.rulings p.note { margin:.75rem 0 0; font-size:.9rem; color:var(--muted); }

/* Provenance, for a record assembled after the fact. Never a ruling. */
.provenance { border:1px solid var(--rule); border-left:3px solid var(--rule);
              padding:1rem 1.2rem; background:var(--raised); font-size:.92rem;
              color:var(--muted); }
.provenance .label { font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
                     text-transform:uppercase; color:var(--muted); display:block;
                     margin-bottom:.45rem; }
.provenance p:last-child { margin:0; }
@media (prefers-reduced-motion:reduce) { * { animation:none!important; transition:none!important; } }
"""

BODY = f"""
<main>
<header>
  <p class="eyebrow">M4 stage 2 &middot; chunk A3 &middot; measured 9 August 2026</p>
  <h1>Three object pages, and the frame they share</h1>
  <p class="standfirst">Listing pages 8, 9 and 10 &mdash; PDF pp. 199 to 201 of
  J28&#8209;6169. Every image here is the scan's own ink, deskewed and cropped. Nothing is
  redrawn.</p>
</header>

<section>
  <div class="provenance"><span class="label">Provenance</span>
  <p>This document was assembled on 10 August 2026 from the orphan branch
  <code>evidence-pages-199-201</code>, commit
  <code>129a6c9adebf9bf318b3c7ce9e1e5ea6c6632efa</code>, when the review&#8209;record
  process became the repository's standard. No review document existed when the work was
  done. The three decisions below were put to Jack in pull request&nbsp;#88 and merged
  there, so nothing is an open question and there is no rulings banner.</p>
  <p>The original branch README is preserved word for word at
  <code>evidence/original-README.md</code>. Every number and every crop here comes from it
  or from <code>evidence/measurements.json</code>.</p></div>
</section>

<section>
  <div class="answer">
    <ol>
      <li><strong>No content changed.</strong> All 162 lines across the three pages already
      agreed with the target, field for field.</li>
      <li><strong>Three pages carry more blank lines after the head than the conversion
      does.</strong> Page 8 prints three, pages 9 and 10 print two; the conversion holds one
      on each.</li>
      <li><strong>The page body is a frame of 57 line slots.</strong> On all four pages
      verified by then, the last content line sits in slot 57.</li>
    </ol>
  </div>
</section>

<section>
  <h2>What changed in the repository</h2>
  <div class="scroll">
  <table>
    <thead><tr><th>File</th><th>Change</th></tr></thead>
    <tbody>
      <tr><td><code>test/fixtures/90.05-object-listing.target</code></td><td>+4 blank lines, nothing else</td></tr>
      <tr><td><code>tool/object_listing_target_source.dart</code></td><td>3 entries in the measured-blanks map</td></tr>
      <tr><td><code>test/object_listing_target_test.dart</code></td><td>blank counts for 4 pages; a new frame test</td></tr>
      <tr><td><code>test/fixtures/90.05-object-listing-notes.md</code></td><td>the three page records</td></tr>
      <tr><td><code>docs/design/m4-codegen.md</code>, <code>m1-front-end.md</code></td><td>the frame, one amendment each</td></tr>
      <tr><td><code>docs/HANDOVER.md</code></td><td>four erratum candidates, chunk state, test count</td></tr>
      <tr><td><code>test/doc_weight_test.dart</code></td><td>m4-codegen budget 9000 &rarr; 10000</td></tr>
    </tbody>
  </table>
  </div>
  <p>The whole change to the target, with the head and header lines shortened to fit this
  page:</p>
<pre><code> DATE 10/18/61  TIME  2.45  ACCOUNT ... PAGE  8

+
+
  LOC        OCTAL        CNTRL        SYMBOLIC
@@
 DATE 10/18/61  TIME  2.45  ACCOUNT ... PAGE  9

+
 00060  2 00000 0 00001   00001                   BSS    1
@@
 DATE 10/18/61  TIME  2.45  ACCOUNT ... PAGE  10

+
 00200  0074 00 4 00010   10010          +11      TSX    IOC)8,4</code></pre>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>Decision 1 &mdash; the blank lines after each page head</h2></div>
  <p><strong>Page 8 gets three, pages 9 and 10 get two. The conversion holds one on
  each.</strong></p>
  <p>In the plates below, a blue line and <code>text</code> mean the printer used that line
  slot. A red line and <code>EMPTY</code> mean it did not. The only ink in a red slot is a
  form guide rule.</p>

  <h3>PDF p. 199 &mdash; listing page 8</h3>
  {img("page-199-gap.png", "The gap between the head and the first content line on PDF page 199",
       "Three empty slots, then the column header, then one more empty slot, then the "
       "first listing line. This is the only page in the listing that prints the column "
       "header, and the only page so far that does not print two blanks.")}

  <h3>PDF p. 200 &mdash; listing page 9</h3>
  {img("page-200-gap.png", "The gap between the head and the first content line on PDF page 200",
       "Two empty slots, then the first listing line.")}

  <h3>PDF p. 201 &mdash; listing page 10</h3>
  {img("page-201-gap.png", "The gap between the head and the first content line on PDF page 201",
       "Two empty slots, then the first listing line.")}

  <p><strong>Why I believe it.</strong> Each page was read by one agent that had the page
  scan and nothing else &mdash; no conversion, no target, no golden, no other page. Page 8
  breaks the pattern, so a second agent measured that page's line spacing alone, with no
  access to the first one's work, and returned the same four empty slots. The script in
  this record is a third measurement and agrees again.</p>

  <div class="scroll">
  <table>
    <thead><tr><th>PDF page</th><th>Line pitch</th><th>Empty slots</th>
    <th>Shortest printed row</th><th>Tallest empty slot</th></tr></thead>
    <tbody>
      <tr><td class="num">199</td><td class="num">15.165 px</td><td class="num">1, 2, 3, 5</td>
      <td class="num">10 rows of ink</td><td class="num">1 row</td></tr>
      <tr><td class="num">200</td><td class="num">15.215 px</td><td class="num">1, 2</td>
      <td class="num">9 rows</td><td class="num">0 rows</td></tr>
      <tr><td class="num">201</td><td class="num">15.305 px</td><td class="num">1, 2</td>
      <td class="num">10 rows</td><td class="num">0 rows</td></tr>
    </tbody>
  </table>
  </div>
  <p>The last two columns are the separation. A printed character stands 9 to 11 rows tall;
  what survives in an &ldquo;empty&rdquo; slot is at most one row of rule fringe.</p>
  <p><strong>What would reverse it.</strong> A page scan showing ink in one of those slots.
  Each was swept at multiple thresholds and none was found.</p>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>Decision 2 &mdash; the body is a frame of 57 line slots</h2></div>
  <p><strong>Recorded in <code>m4-codegen.md</code> M4&#8209;8 and
  <code>m1-front-end.md</code> M1&#8209;16, with its scope stated.</strong></p>
  <p>Each map numbers every line slot down the left margin. Red means empty.</p>

  {img("page-199-slots.png", "Slot map of PDF page 199",
       "PDF p. 199, listing page 8. Slots 1 to 3 blank, the column header in slot 4, "
       "slot 5 blank, then 52 content lines ending in slot 57.")}
  {img("page-200-slots.png", "Slot map of PDF page 200",
       "PDF p. 200, listing page 9. Slots 1 and 2 blank, then 55 content lines ending in "
       "slot 57.")}
  {img("page-201-slots.png", "Slot map of PDF page 201",
       "PDF p. 201, listing page 10. Slots 1 and 2 blank, then 55 content lines ending in "
       "slot 57.")}

  <div class="scroll">
  <table>
    <thead><tr><th>Listing page</th><th>Slots 1&ndash;2</th><th>Slot 3</th><th>Slots 4&ndash;5</th>
    <th>Content lines</th><th>Last slot</th></tr></thead>
    <tbody>
      <tr><td class="num">8</td><td>blank</td><td>blank</td><td>header, blank</td>
      <td class="num">52</td><td class="num">57</td></tr>
      <tr><td class="num">9</td><td>blank</td><td>text</td><td>text</td>
      <td class="num">55</td><td class="num">57</td></tr>
      <tr><td class="num">10</td><td>blank</td><td>text</td><td>text</td>
      <td class="num">55</td><td class="num">57</td></tr>
      <tr><td class="num">21 (chunk A2)</td><td>blank</td><td>text</td><td>text</td>
      <td class="num">55</td><td class="num">57</td></tr>
    </tbody>
  </table>
  </div>
  <p>Page 8 spends three slots on furniture the others do not print, and prints three fewer
  lines. That is why the count differs, and it answers the question the page 21 pass left
  open about M1&#8209;16's flat &ldquo;55 content lines&rdquo;.</p>
  <p><strong>What would reverse it.</strong> Fourteen pages were unverified when this was
  written. The transcription of listing page 19, PDF p. 210, holds 54 content lines, which
  the frame forbids unless that page prints an interior blank. That falsifier went into the
  design record rather than leaving the claim unqualified.</p>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>Decision 3 &mdash; no content changed</h2></div>
  <p>A plain&#8209;code comparator parsed the target back into its six fields by the
  M4&#8209;8 columns and diffed each against the reader's transcription:</p>
<pre><code>== PDF p. 199 (listing page 8)   0 disagreement(s) over 52 target lines
== PDF p. 200 (listing page 9)   0 disagreement(s) over 55 target lines
== PDF p. 201 (listing page 10)  0 disagreement(s) over 55 target lines</code></pre>
  <p>The first run flagged three lines on page 10. That was the comparator's bug, not a
  reading: it split fields on two or more blanks, and the six&#8209;character mnemonic
  <code>IOCTN*</code> leaves only one blank before the operand column.</p>
</section>

<section>
  <h2>The column header, measured again</h2>
  {img("page-199-header.png", "The column header of PDF page 199 with a measured column ruler",
       "Red lines are the columns authorized the day before. The page 8 reader measured "
       "LOC at 1, OCTAL at 12, CNTRL at 25 and SYMBOLIC at 58 without seeing that "
       "correction. This crop is the check by eye.")}
</section>

<section>
  <h2>Readings the agents made that changed nothing</h2>
  <p>These agreed with the transcription, so nothing moved. They are here because each was
  a genuine coin&#8209;toss on the ink.</p>
  <div class="scroll">
  <table>
    <thead><tr><th>Page</th><th>Line</th><th>Read as</th><th>Decided by</th></tr></thead>
    <tbody>
      <tr><td class="num">199</td><td class="num">2</td><td class="num">2,PI)1</td>
      <td>the <code>I</code> has top and bottom serifs; the <code>1</code> two columns right has an upper-left flag and none</td></tr>
      <tr><td class="num">199</td><td class="num">4</td><td class="num">*DATA</td>
      <td>a solid mark at mid glyph height; a period sits on the baseline, a plus is hollow</td></tr>
      <tr><td class="num">199</td><td class="num">49</td><td class="num">+8</td>
      <td>two bowls with rounded left sides, against the straight stem of <code>B</code> in <code>BSS</code></td></tr>
      <tr><td class="num">200</td><td class="num">52&ndash;55</td><td class="num">00174&ndash;00177</td>
      <td>the first digit is faded on its left stroke; a <code>C</code> on that page prints an aperture, these do not</td></tr>
      <tr><td class="num">200</td><td class="num">46</td><td class="num">IOC)1</td>
      <td>the <code>I</code> and the <code>1</code> differ by the top bar, and by 4.31 px against 4.84 px mean width</td></tr>
      <tr><td class="num">201</td><td class="num">17</td><td class="num">TRA, not TKA</td>
      <td>the <code>R</code> prints a faint top bar; matched row for row against the certain <code>R</code> of <code>CURRENT</code></td></tr>
      <tr><td class="num">201</td><td class="num">47, 55</td><td class="num">10001, not 1000C</td>
      <td>the right stroke is a straight stem broken on three rows; the page's 20 <code>C</code> glyphs never print that stem</td></tr>
      <tr><td class="num">201</td><td class="num">22</td><td class="num">ends at 15</td>
      <td>the speck one column past it sits at mid height, not on the baseline, at a quarter of a period's area</td></tr>
    </tbody>
  </table>
  </div>
</section>

<section>
  <h2>Judgment calls open to being overturned</h2>
  <div class="scroll">
  <table>
    <thead><tr><th>Call</th><th>Why</th><th>Cost to reverse</th></tr></thead>
    <tbody>
      <tr><td>Raised the <code>m4-codegen.md</code> word budget 9000 &rarr; 10000</td>
      <td>this chunk's amendment took the file to 9040; stage 2 amends that record once per chunk</td>
      <td>one line</td></tr>
      <tr><td>One reader per page, not two</td>
      <td>it is the method chunk A2 set; a second reader was added only for page 8, the page that broke the pattern</td>
      <td>rerun a page, about 210k tokens</td></tr>
      <tr><td>Held all four erratum candidates</td>
      <td>the page 21 record asks for one authorization at the end of the pass</td>
      <td>none; nothing is blocked</td></tr>
      <tr><td>Recorded the frame now, not after A8</td>
      <td>it makes a falsifiable prediction that the next chunks test</td>
      <td>one amendment</td></tr>
    </tbody>
  </table>
  </div>
  <div class="rulings"><span class="label">What happened next</span>
    <p>The held erratum candidates were released on 9 August 2026, at the end of chunk A4.
    Jack authorized the blank&#8209;line corrections and changed the standing rule, so each
    later chunk now authorizes its own pages instead of queueing them. Seven object pages
    were corrected in the conversion at that point.</p>
  </div>
</section>

<section>
  <h2>One flaw in this chunk</h2>
  <p>The reader prompts carried a wrong calibration hint: they said the location field to
  the far end of a twelve&#8209;digit octal word spans about 59 columns, dropping that those
  59 columns are to the <em>operand</em> copy of the word. The body's OCTAL field ends at
  column 21. The page 10 reader caught it, said so, and fitted its own grid; no reading
  changed. Chunk A4's prompt stated it correctly.</p>
</section>

<footer>
  <p>Chunk A3 cost 678k tokens over 42 minutes for the three page readers &mdash; 205k, 215k
  and 258k &mdash; and 89k over 13 minutes for the second reader on page 8. The chunk A2
  calibration page cost 135k, and its record called that a floor because its grid was
  already known. It was.</p>
  <p>To reproduce, run <code>tools/evidence.py</code> from the repository root, where it
  expects to find <code>comtran-manuals/</code>. It writes into the directory named by its
  own <code>OUT</code> constant, which still names the branch directory this record
  replaced; create that directory, or point <code>OUT</code> at this record's
  <code>crops/</code>. The script is shipped exactly as it ran. It needs PIL and NumPy and
  nothing else.</p>
</footer>
</main>
"""

HTML = (
    '<!DOCTYPE html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
    '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    "<title>Chunk A3 &mdash; three object pages, and the frame they share</title>\n"
    f"<style>{CSS}</style>\n</head>\n<body>\n{BODY}\n</body>\n</html>\n"
)

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
