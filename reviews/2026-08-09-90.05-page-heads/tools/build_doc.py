"""Assemble the page-head review page, embedding each crop as a data URI.

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
  <p class="eyebrow">90.05 conversion &middot; page heads &middot; measured 9 August 2026</p>
  <h1>Twenty&#8209;five page heads, measured against five scans</h1>
  <p class="standfirst">The conversion of J28&#8209;6169 Appendix 90.05 carried four
  different spacings across its 25 page heads. None of them was the print's. This is the
  evidence behind the correction: five deskewed head crops, 190 glyph readings, and the
  two scripts that produced them.</p>
</header>

<section>
  <div class="provenance"><span class="label">Provenance</span>
  <p>This document was assembled on 10 August 2026 from the orphan branch
  <code>evidence-90.05-page-heads</code>, commit
  <code>96dc6fa836b71d8d0ecb424939d48133cb5bec51</code>, when the review&#8209;record
  process became the repository's standard. No review document existed when the work was
  done. The correction itself was put to Jack in pull request&nbsp;#82 and merged there,
  so nothing below is an open question and there is no rulings banner.</p>
  <p>The original branch README is preserved word for word at
  <code>evidence/original-README.md</code>. Every number and every crop here comes from
  it or from <code>evidence/measurements.json</code>.</p></div>
</section>

<section>
  <div class="answer">
    <ol>
      <li><strong>All 25 heads now carry one spacing, and it is the print's.</strong> It is
      byte&#8209;identical to the head the compiler prints in
      <code>test/goldens/90.05-payroll.listing</code>.</li>
      <li><strong>The transcription held four spacings, none of them right.</strong> Only
      <code>DATE</code> at column 0 and the date value at column 5 were correct in all
      four.</li>
      <li><strong>190 glyph readings back it.</strong> Every one lands within a quarter of
      a cell of an integer column, which is the check that the pitch and the anchor are
      right.</li>
      <li><strong>Two things were deliberately left alone</strong> &mdash; the left margin,
      which the conversion flattens by design, and the column header, which was a separate
      candidate and was authorized later.</li>
    </ol>
  </div>
</section>

<section>
  <h2>How to read the plates</h2>
  <p>Each plate is a crop of the page head from the deskewed page scan, at 2&times;, with a
  column ruler underneath. Column&nbsp;0 is the <code>D</code> of <code>DATE</code>, which
  is M1&#8209;15's definition of D.</p>
  <ul>
    <li><strong>Solid red</strong> &mdash; the measured column, now applied to the
    conversion.</li>
    <li><strong>Dashed green</strong> &mdash; the column that <em>that page's own
    transcribed head</em> put the field at, before this change.</li>
  </ul>
  <p>Where a red line lands on the left edge of a glyph, the measurement is right. Where a
  green line lands in white space or inside a letter, the transcription was wrong there.
  Where the two coincide, that page's transcription was already correct for that field.</p>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>The five pages</h2></div>

  <h3>PDF p. 195 &mdash; source listing, listing page 4</h3>
  {img("page-195-head.png", "Head of PDF page 195 with measured and transcribed column rulers",
       "Green misses at TIME, the time value, ACCOUNT, ID., the identifier and the page "
       "number. Green matches at DATE, the date value and PAGE.")}

  <h3>PDF p. 196 &mdash; source listing, listing page 5</h3>
  {img("page-196-head.png", "Head of PDF page 196 with measured and transcribed column rulers",
       "The same six misses. This is the second page of the group that the compiler's own "
       "head template was copied from.")}

  <h3>PDF p. 198 &mdash; loader control cards, listing page 7</h3>
  {img("page-198-head.png", "Head of PDF page 198 with measured and transcribed column rulers",
       "This page is its own spacing group of one, and it was not measured before this "
       "pass. Green matches at the time value and misses at TIME by one and at ACCOUNT by "
       "one, then runs four and five columns adrift at ID., the identifier, PAGE and the "
       "page number.")}

  <h3>PDF p. 199 &mdash; object listing, listing page 8</h3>
  {img("page-199-head.png", "Head of PDF page 199 with measured and transcribed column rulers",
       "Green matches at the time value, ID. and the identifier, misses at TIME and "
       "ACCOUNT by one, and falls short at PAGE and the page number by three and four. "
       "The single digit 8 sits at column 89.")}

  <h3>PDF p. 212 &mdash; object listing, listing page 21</h3>
  {img("page-212-head.png", "Head of PDF page 212 with measured and transcribed column rulers",
       "Green matches through ACCOUNT and then misses at every field to the right. The two "
       "digits of 21 sit at columns 89 and 90, which is what settles the page number as "
       "left-aligned at 89 rather than right-aligned ending at 90.")}

  <p>The form's dashed guide rule crosses the head on PDF p. 212. It is visible in that
  crop because the crop is the untouched scan; the measurement deleted the rule rows
  first.</p>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>What the transcription held</h2></div>
  <p>Four different spacings across the 25 heads, none of them the print's. Columns are
  relative to <code>DATE</code>.</p>
  <div class="scroll">
  <table>
    <thead><tr><th>Heads</th><th>TIME</th><th>time</th><th>ACCOUNT</th><th>ID.</th>
    <th>identifier</th><th>PAGE</th><th>number</th></tr></thead>
    <tbody>
      <tr class="print"><td>the print</td><td class="num">15</td><td class="num">21</td>
      <td class="num">27</td><td class="num">55</td><td class="num">59</td>
      <td class="num">83</td><td class="num">89</td></tr>
      <tr><td>listing pages 1&ndash;6</td><td class="num">16</td><td class="num">22</td>
      <td class="num">29</td><td class="num">56</td><td class="num">60</td>
      <td class="num">83</td><td class="num">90</td></tr>
      <tr><td>listing page 7</td><td class="num">16</td><td class="num">21</td>
      <td class="num">28</td><td class="num">60</td><td class="num">64</td>
      <td class="num">88</td><td class="num">93</td></tr>
      <tr><td>listing pages 8&ndash;16</td><td class="num">16</td><td class="num">21</td>
      <td class="num">28</td><td class="num">55</td><td class="num">59</td>
      <td class="num">80</td><td class="num">85</td></tr>
      <tr><td>listing pages 17&ndash;25</td><td class="num">15</td><td class="num">21</td>
      <td class="num">27</td><td class="num">60</td><td class="num">64</td>
      <td class="num">87</td><td class="num">93</td></tr>
    </tbody>
  </table>
  </div>
  <p><code>DATE</code> at 0 and the date value at 5 were right in all four.</p>

  <h3>The change, one line per group</h3>
<pre><code>p1-6   -        DATE 10/18/61   TIME  2.45   ACCOUNT                    ID. CT PUBLICATIONS        PAGE   1
       +        DATE 10/18/61  TIME  2.45  ACCOUNT                     ID. CT PUBLICATIONS         PAGE  1

p7     -DATE 10/18/61   TIME 2.45   ACCOUNT                         ID. CT PUBLICATIONS         PAGE 7
       +DATE 10/18/61  TIME  2.45  ACCOUNT                     ID. CT PUBLICATIONS         PAGE  7

p8-16  -DATE 10/18/61   TIME 2.45   ACCOUNT                    ID. CT PUBLICATIONS      PAGE 8
       +DATE 10/18/61  TIME  2.45  ACCOUNT                     ID. CT PUBLICATIONS         PAGE  8

p17-25 -    DATE 10/18/61  TIME  2.45  ACCOUNT                          ID. CT PUBLICATIONS        PAGE  17
       +    DATE 10/18/61  TIME  2.45  ACCOUNT                     ID. CT PUBLICATIONS         PAGE  17</code></pre>
</section>

<section class="item">
  <div class="itemhead"><span class="chip done">Settled</span>
  <h2>The column header &mdash; held here, authorized later</h2></div>
  <p>When this evidence was put to Jack it carried one open ask. The line
  <code>LOC OCTAL CNTRL SYMBOLIC</code> is the only column header in the file. It was
  transcribed at columns 0, 11, 26 and 54; the scan measures 1, 12, 25 and 58. That was a
  separate erratum candidate and this change did not touch it.</p>
  <div class="rulings"><span class="label">Resolved</span>
    <p>Jack authorized it separately. It was applied in pull request&nbsp;#83, &ldquo;Correct
    the object listing column header in the 90.05 conversion&rdquo;. The measured columns
    1, 12, 25 and 58 were checked again by eye on PDF p. 199 during chunk A3, by a reader
    that had not seen the correction.</p>
  </div>
</section>

<section>
  <h2>What was not changed</h2>
  <p><strong>The left margin.</strong> The four groups still start 8, 0, 0 and 4 spaces in
  from the left. The conversion flattens the head&#8209;to&#8209;body margin, M1&#8209;15
  records that, and this change does not touch it. You still may not read an absolute
  column out of the transcription &mdash; only the spacing between the head's own fields is
  now true.</p>
</section>

<section>
  <h2>Method</h2>
  <p>Per page: deskew by the angle that maximises the variance of the row profile; delete
  the guide&#8209;rule rows, which carry a horizontal ink run of up to 381&nbsp;px where the
  worst glyph row carries 7; fit the character pitch by autocorrelation of the page's own
  body ink; read each glyph's left edge.</p>
  <p>Registration differs page to page, so each page is anchored on its own
  <code>DATE</code> and fitted on its own pitch &mdash; never on another page's.</p>
  <div class="scroll">
  <table>
    <thead><tr><th>PDF page</th><th>Deskew</th><th>Pitch px</th><th>Glyph runs read</th></tr></thead>
    <tbody>
      <tr><td class="num">195</td><td class="num">&minus;0.44&deg;</td><td class="num">9.3306</td><td class="num">39</td></tr>
      <tr><td class="num">196</td><td class="num">+0.56&deg;</td><td class="num">9.3050</td><td class="num">38</td></tr>
      <tr><td class="num">198</td><td class="num">+0.52&deg;</td><td class="num">9.2430</td><td class="num">35</td></tr>
      <tr><td class="num">199</td><td class="num">&minus;0.32&deg;</td><td class="num">9.2736</td><td class="num">38</td></tr>
      <tr><td class="num">212</td><td class="num">+0.96&deg;</td><td class="num">9.2412</td><td class="num">40</td></tr>
    </tbody>
  </table>
  </div>
  <p><code>evidence/measurements.json</code> holds every glyph's measured column for all
  five pages.</p>
</section>

<footer>
  <p>To reproduce, run both scripts from the repository root, where they expect to find
  <code>comtran-manuals/</code>. Each writes into the directory named by its own
  <code>OUT</code> constant, which still names the branch directory this record replaced;
  create that directory, or point <code>OUT</code> at this record's <code>crops/</code>.
  The scripts are shipped exactly as they ran. They need PIL and NumPy and nothing
  else.</p>
  <p><code>tools/evidence.py</code> re&#8209;measures the five pages and redraws these
  plates. <code>tools/rewrite_heads.py</code> rewrites the 25 heads; it is already applied,
  so it is a no&#8209;op now.</p>
</footer>
</main>
"""

HTML = (
    '<!DOCTYPE html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
    '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    "<title>Page heads &mdash; twenty-five heads measured against five scans</title>\n"
    f"<style>{CSS}</style>\n</head>\n<body>\n{BODY}\n</body>\n</html>\n"
)

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
