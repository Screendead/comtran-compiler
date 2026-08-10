"""Assemble the chunk A6 review page, embedding each crop as a data URI.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: every image is embedded, so the file renders
from any location, and the crops ship alongside it as separate materials.
"""

import base64
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

# A commit, never a branch: a topic branch is deleted when its pull request
# merges and a blob/<branch>/... link 404s from that moment on.
GH = (
    "https://github.com/Screendead/comtran-compiler/blob/"
    "701afb04f7c4f37bac23ffccdb8e8156b9553d2e"
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
<title>Chunk A6 — the 1962 printer wrapped a line, and the conversion joined it back</title>
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
pre {{ font-family:var(--mono); font-size:.78rem; line-height:1.45; background:var(--raised);
       border:1px solid var(--hair); padding:.8rem 1rem; overflow-x:auto; margin:.6rem 0 1rem; }}
pre code {{ background:none; padding:0; font-size:1em; }}
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
.plate {{ background:#FFFFFF; border:1px solid var(--rule); padding:.55rem; overflow-x:auto; }}
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
.opt h4 {{ margin:0 0 .25rem; font-size:.98rem; }}
.opt p {{ margin:0 0 .4rem; }}
.opt .cost {{ color:var(--muted); font-size:.92rem; }}
.rulings {{ border:1px solid var(--settled); border-left:3px solid var(--settled);
            padding:1.15rem 1.3rem; background:var(--raised); }}
.rulings .label {{ font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
                   text-transform:uppercase; color:var(--settled); display:block;
                   margin-bottom:.55rem; }}
.rulings ul {{ margin:0; padding-left:1.15rem; }}
.rulings li {{ margin-bottom:.42rem; }}
.rulings p.note {{ margin:.75rem 0 0; font-size:.9rem; color:var(--muted); }}
footer {{ border-top:1px solid var(--rule); padding-top:1.2rem; color:var(--muted);
          font-size:.9rem; }}
</style>
</head>
<body>
<main>

<header>
  <p class="eyebrow">Review record &middot; 10 August 2026 &middot; M4 stage 2, chunk A6</p>
  <h1>The 1962 printer wrapped a line, and the conversion joined it back together</h1>
  <p class="standfirst">Three blind readers took listing pages 17, 18 and 19 of the
  90.05 object listing, PDF pp. 208 to 210. Two questions come back to you: one
  authorization to change a manual conversion, and one glyph the ink does not
  settle.</p>
</header>

<section>
  <div class="rulings"><span class="label">Rulings &middot; 10 August 2026</span>
    <ul>
      <li><strong>The conversion carries the two lines the page prints.</strong>
      Item A, option 1. Jack: fidelity to the PDFs is paramount. He also
      confirmed from the scan that no form rule separates the two rows; the
      nearest rules are above the label and below the wrapped instruction.</li>
      <li><strong><code>BL)3,2</code> stands.</strong> Item B, option 1. It
      rests on name structure and on the prefix's attestation across the
      listing, and on nothing in this page's ink, which leans the other
      way.</li>
      <li><strong>The <code>B</code> against <code>8</code> ambiguity is a
      class, not a cell.</strong> Four sites are now known across three pages,
      and the ruling covers all of them. This print chain does not separate the
      two shapes at 150 dpi.</li>
    </ul>
    <p class="note">The chips below record what each item asked for when the
    document was put to Jack. They are left as they were, so the record shows
    the question as well as the answer.</p>
  </div>
</section>

<section class="answer">
  <p class="eyebrow">In short</p>
  <ol>
    <li><strong>Listing page 19 prints 55 lines, not the 54 the conversion holds.</strong>
    The label <code>WITHOLDING.TAX.ROUTINE</code> is 22 characters and overruns its
    field, so the printer put its instruction, <code>AXT 0</code>, on the next
    line. The conversion joined the two back into one. <strong>This needs your
    authorization</strong>, because it changes a conversion's content and not
    only its spacing.</li>
    <li>It is the only site of its kind in the whole eighteen-page object listing.
    Three other labels reach the mnemonic column, and each of the three stands
    alone on its line with no instruction to displace.</li>
    <li><strong>One glyph needs your eye.</strong> On listing page 17 the operand
    reads <code>BL)3,2</code> or <code>8L)3,2</code>. Its reader measured three ways
    and leaned <code>8</code>, then said plainly that the ink does not settle it.
    The reader of the next page leaned <code>B</code> on the same prefix.</li>
    <li>Everything else on the three pages agrees with the transcription, field
    for field. The blank counts are corrected under your option B and need
    nothing from you.</li>
  </ol>
</section>

<section class="item needs">
  <div class="itemhead"><h2>A. Listing page 19 prints a line the conversion does not hold</h2>
  <span class="chip call">Your call</span></div>

  <p>The page scan, deskewed by the 1.2658 degrees its reader measured and
  otherwise untouched. Read the fourth line down, and then the line under it.</p>

  {img("a1-wrapped-line.png", "Four printed lines of the object listing. The fourth carries a long label and no instruction; the line under it carries only AXT and 0.", "PDF p. 210, deskewed, 2x. Rows 795 to 895 of the deskewed image, print columns 0 to 90.")}

  <p>The instruction sits in the ordinary columns. <code>AXT</code> prints in the
  mnemonic column, in line with <code>STO</code>, <code>TRA*</code> and
  <code>LDQ</code>; its operand <code>0</code> prints in the operand column, in
  line with <code>1)FICA,1</code> and <code>FICA.ROUTINE</code>. Only the label
  above it breaks the grid, because it is too long for the field.</p>

  {img("a3-wrapped-columns.png", "The same four lines enlarged, showing AXT aligned with the mnemonics above and below it.", "PDF p. 210, deskewed, 4x, print columns 44 to 72. The label runs in from the left and stops short of the mnemonic column; the instruction it displaced prints on the next line.")}

  <h3>What the conversion holds</h3>
  <p>One line where the print has two:</p>
<pre><code>01220  0774 00 0 00000   10000    WITHOLDING.TAX.ROUTINE AXT 0
01221  0560 00 0 01710   10001           +1      LDQ    CP)+12</code></pre>

  <h3>What loses the line</h3>
  <p>The line is faint, not smudged. At the scan's own resolution it is
  legible once you know where to look, and it carries about a ninth of the ink
  of a full line, because it prints five characters where a full line prints
  forty. That is what loses it. A pass that keeps a line on its ink weight
  drops this one first, and where the threshold falls decides whether the page
  has 54 content lines or 55.</p>

  {img("a2-wrapped-line-1x.png", "The same region at the scan's own resolution, where the wrapped line is faint.", "PDF p. 210, deskewed, 1x. The same rows as the first plate.")}

  <div class="scroll"><table>
    <thead><tr><th>Measurement, page 210</th><th>Value</th></tr></thead>
    <tbody>
      <tr><td>Median ink over the page's line bands</td><td class="num">247,457</td></tr>
      <tr><td>The wrapped line's ink, over its glyph rows</td><td class="num">27,753 &nbsp;(0.11 &times; median)</td></tr>
      <tr><td>Where that ink sits</td><td class="num">print columns 49 and 56, and nowhere else</td></tr>
      <tr><td>The faintest band a 2% pass keeps</td><td class="num">73,512 &nbsp;(0.30 &times; median)</td></tr>
      <tr><td>Bands at a 2% ink threshold</td><td class="num">55 &nbsp;= the head and 54 content lines</td></tr>
      <tr><td>Bands at a 1% ink threshold</td><td class="num">56 &nbsp;= the head and 55 content lines</td></tr>
      <tr><td>Content lines the conversion holds</td><td class="num">54</td></tr>
    </tbody>
  </table></div>

  <p>Every figure comes from <code>tools/measure.py</code>, which ships beside
  this document and which reads no glyph at all: it tells text from the form
  rules by the two margins, and names each band by the print columns its ink
  occupies. The last three rows are the point. One detector reproduces the
  conversion's 54 content lines at one threshold and the print's 55 at another,
  and the single line that appears between the two is the wrapped one. The
  transcription lost exactly the line a weight-based pass loses.</p>

  <p>The second row is the positive half, and it does not depend on any
  threshold. The ink on those rows sits at print column 49 and print column 56
  and nowhere else on the line. Those are the mnemonic and the operand. A
  speck, a smudge or a rule fragment does not land on two field columns.</p>

  <h3>Why this page and no other</h3>
  <p>The label field runs from print column 34 to column 48, and the mnemonic
  column is 49. A label of 15 characters or more therefore reaches the mnemonic.
  A search of all eighteen object pages returns five lines. One of the five is
  not a label at all, the end-of-text card, which the search catches on its
  spacing. Of the four labels, three stand alone on their line and displace
  nothing:</p>

  <div class="scroll"><table>
    <thead><tr><th>Listing page</th><th>Label</th><th>Carries an instruction</th></tr></thead>
    <tbody>
      <tr><td class="num">8</td><td class="num">DEPARTMENT.TOTAL</td><td>no</td></tr>
      <tr><td class="num">9</td><td class="num">INTERNAL.TOTALS</td><td>no</td></tr>
      <tr><td class="num">10</td><td class="num">COMPARE.EMPLOYEE.NUMBERS</td><td>no</td></tr>
      <tr><td class="num">19</td><td class="num">WITHOLDING.TAX.ROUTINE</td><td><strong>yes, AXT 0</strong></td></tr>
      <tr><td class="num">25</td><td colspan="2">not a label; the end-of-text card</td></tr>
    </tbody>
  </table></div>

  <p>Pages 8, 9 and 10 were verified against their scans by chunk A3, and each
  reader reported its line count with no content correction. So all three
  stand-alone labels are confirmed against the print, and page 19 is the only
  site where the question arises.</p>

  <h3>It also answers a question this project has carried since chunk A2</h3>
  <p>The verification record predicted that every object page prints 55 content
  lines in a frame of 57 slots, and named page 19 as the one page whose
  transcription would break the prediction, at 54 lines. It recorded two
  possible explanations: an interior blank line, or a transcription one line
  short. The scan gives the second, with a cause neither guess supplied. The
  frame holds on page 19, and now on thirteen pages of thirteen.</p>

  <h3>What it means for the code generator</h3>
  <p>M4 stage 2 has to print this page. Whatever you decide about the
  conversion, the generator must wrap an instruction whose label overruns the
  mnemonic column, because the golden listing is the oracle and the print does
  it. One site exercises the rule. Nothing in the recovered documents states it,
  so it goes into the design record as a behaviour read off the artifact.</p>

  <h3>The options</h3>

  <div class="opt pick">
    <h4>1. Authorize the conversion change, and split the line. Recommended.</h4>
    <p><code>comtran-manuals/J28-6169/90.05-sample-program.md</code> gains one line:
    the label keeps its own line, and <code>AXT 0</code> moves to the next at the
    mnemonic and operand columns. The target regenerates from it and page 19
    carries 55 lines.</p>
    <p class="cost">Consequence: a manual conversion changes its content, which
    is the thing section 9 of <code>CLAUDE.md</code> guards. Against that, the
    conversion currently states something the page scan does not show, and every
    downstream artifact inherits it. Reversing costs one commit.</p>
  </div>

  <div class="opt">
    <h4>2. Leave the conversion, and correct the target only.</h4>
    <p>The target is ours to change without asking. Page 19 would carry 55 lines
    and the conversion would keep 54.</p>
    <p class="cost">Consequence: the two disagree permanently, with no record in
    the conversion itself saying why. A later reader who reaches for the
    conversion, which is the document this project presents as the transcription
    of the page, gets the wrong line count. The scan pass exists to stop exactly
    that.</p>
  </div>

  <div class="opt">
    <h4>3. Leave both, and record the finding only.</h4>
    <p>Chunk A6 lands the blank counts and this record holds the measurement.</p>
    <p class="cost">Consequence: the target keeps a line the print does not have,
    so chunk B7's listing diff fails on this page and someone re-derives all of
    this to find out why. It also leaves the frame prediction unresolved in the
    record, when the evidence resolves it.</p>
  </div>

  <div class="ask"><span class="label">What I need from you</span>
  <p>May I add the line to the conversion, under option 1?</p></div>
</section>

<section class="item needs">
  <div class="itemhead"><h2>B. <code>BL)3,2</code> or <code>8L)3,2</code> on listing page 17</h2>
  <span class="chip ocr">Human OCR</span></div>

  <p>The first content line of PDF p. 208. The operand is the last thing on it.</p>

  {img("b1-disputed-line.png", "One line of the object listing, ending in an operand that reads BL)3,2 or 8L)3,2.", "PDF p. 208, deskewed by 1.078 degrees, 2x. LOC 00772, mnemonic LAC, offset +40.")}

  <p>The disputed glyph, beside a certain <code>8</code> and a certain
  <code>B</code> cut from this same page's head, all at one magnification.</p>

  {img("b2-glyph-compare.png", "Three glyphs side by side: the disputed one, a certain 8, and a certain B.", "Left: the disputed glyph, operand column 56. Middle: the 8 of 10/18/61 in the page head. Right: the B of PUBLICATIONS in the page head. PDF p. 208, 10x.")}

  <h3>What the reader measured, and what it could not do</h3>
  <p>Three measurements against training sets cut from the same page, each one
  favouring <code>8</code>:</p>
  <ul>
    <li>Template correlation: 0.885 against <code>8</code>, 0.773 against
    <code>B</code>, below every known <code>B</code>'s own score of 0.857 to 0.955.</li>
    <li>Left-lobe against right-lobe peak ratio: five known <code>B</code> glyphs
    run 1.02 to 1.49, twenty-three known <code>8</code> glyphs run 0.80 to 0.99,
    the target 0.78.</li>
    <li>A Fisher discriminant: the <code>B</code> population +0.88 to +3.43, the
    <code>8</code> population &minus;4.20 to &minus;1.64, the target &minus;2.26.</li>
  </ul>
  <p>Then the reader stated the objection against its own result, which is why
  this item is here. All three measurements key on the left stroke, and this
  glyph's upper left printed weakly, one sample wide in the top half against
  four in both reference shapes. A <code>B</code> with a thin stem lands in the
  <code>8</code> population by construction. The one feature immune to that
  dropout is the lower bowl, whose left edge bulges out by about half a pixel,
  the <code>8</code> pattern. Half a pixel is not a reading.</p>

  <h3>The next page's reader leaned the other way, on the same prefix</h3>
  <p>PDF p. 209 prints <code>BL)2</code> twice. Its reader ran a different method
  and reported <code>B</code>, also without settling it: the two cells form
  their own class distinct from that page's eights, but rendered at 26 times,
  the candidate mean, the eight mean and a certain <code>B</code> are not
  separable by eye. It closed with the same finding as page 17's reader, in the
  other direction. Two readers, two adjacent pages, one prefix, opposite leans.
  That is the state of the ink.</p>

  <h3>What is not in doubt</h3>
  <p><code>BL)</code> is the block prefix, attested across the listing.
  <code>8L)</code> would be the only generated-name prefix in the artifact that
  begins with a digit. You ruled on the identical ambiguity on 9 August 2026,
  for <code>BL)3</code> on listing page 12, and recorded it as the one character
  in the object listing that no reading has settled from the print. This is a
  second instance of that same character class, on a different page.</p>

  <h3>The options</h3>

  <div class="opt pick">
    <h4>1. <code>BL)3,2</code> stands, on name structure. Recommended.</h4>
    <p>The target and the conversion already read <code>BL)3,2</code>, so nothing
    changes. The record notes that page 17's ink leans the other way.</p>
    <p class="cost">Consequence: this project reads one character against the
    lean of the best measurement anyone has made of it, and says so in place.
    Reversing costs one line in the conversion.</p>
  </div>

  <div class="opt">
    <h4>2. <code>8L)3,2</code>, following this page's ink.</h4>
    <p>The conversion and the target change, and the listing gains a
    generated-name prefix that appears nowhere else.</p>
    <p class="cost">Consequence: the code generator must emit a prefix that no
    rule produces, on one line of the program, and a later reader has to be told
    why. It also contradicts your ruling of 9 August on the same character
    class.</p>
  </div>

  <div class="ask"><span class="label">What I need from you</span>
  <p>Look at the three glyphs above. Does the left one read as the right one, a
  <code>B</code>, or as the middle one, an <code>8</code>? If you cannot tell
  either, say so: that is a result, and option 1 is what it selects.</p></div>
</section>

<section class="item">
  <div class="itemhead"><h2>C. Three more blank counts, corrected under your option B</h2>
  <span class="chip done">Settled</span></div>
  <p>Each of the three pages prints two blank lines between its head and its
  first content line. The conversion held one on listing pages 18 and 19; page
  17 was already corrected to two, by a measurement of 5 August 2026. That is
  the same correction chunks A2 to A5 made on nine pages, and your option B of 9
  August authorizes each chunk's own pages as it lands. Nothing here waits for
  you.</p>
</section>

<section class="item">
  <div class="itemhead"><h2>D. Everything else agrees, and the frame now stands at thirteen of thirteen</h2>
  <span class="chip done">Settled</span></div>

  <div class="scroll"><table>
    <thead><tr><th>Listing page</th><th>PDF page</th><th>Blank slots</th><th>Content lines</th><th>Last slot</th><th>Field disagreements</th></tr></thead>
    <tbody>
      <tr><td class="num">17</td><td class="num">208</td><td class="num">2</td><td class="num">55</td><td class="num">57</td><td class="num">1, item B</td></tr>
      <tr><td class="num">18</td><td class="num">209</td><td class="num">2</td><td class="num">55</td><td class="num">57</td><td class="num">0</td></tr>
      <tr><td class="num">19</td><td class="num">210</td><td class="num">2</td><td class="num">55</td><td class="num">57</td><td class="num">1 line, item A</td></tr>
    </tbody>
  </table></div>

  <p>Every page measured across chunks A2 to A6 puts its last content line in
  slot 57. Twelve print two blank slots and 55 content lines; listing page 8, the
  one page that also prints the column header, prints three blanks and 52 lines.
  The three readers each reported that they opened no banned file, and each
  worked in a directory of its own.</p>

  <p>The comparison against the target is plain code and never a reader:
  <code>tools/compare.py</code>, shipped beside this document.</p>
</section>

<footer>
  <p><strong>Corrected 10 August 2026, before any ruling, and with Jack's
  authorization to replace the branch.</strong> The first version of this
  record quoted the wrong line's ink: it took the faintest band its detector
  kept, 73,512 units, and called that the wrapped line, when that band is the
  label-only line two lines above. It also offered a band count of 55 as
  corroboration of the reader's 55 content lines, when the 55 it found was the
  page head plus 54 content lines and the line it missed was the wrapped one.
  Both errors ran the same way: a band was named from its ink weight instead of
  from where its ink sits. <code>tools/measure.py</code> now names every band by
  its field columns, which is the check that catches it. The finding did not
  move, and the corrected measurement is the stronger of the two.</p>

  <p>Materials beside this file: <code>crops/</code> holds each plate as a PNG,
  <code>evidence/</code> holds the three readers' reports and transcriptions,
  their structured results and the prompt they were given, and
  <code>tools/</code> holds the script that cut the plates, the script that
  measured the line bands, and the script that compared the readings against
  the target. <code>README.md</code> lists them.</p>
  <p>Repository context, at commit <code>701afb0</code>:
  <a href="{GH}/test/fixtures/90.05-object-listing-notes.md">the verification record</a>,
  <a href="{GH}/docs/design/m4-codegen.md">the M4 design record</a>,
  <a href="{GH}/docs/HANDOVER.md">the handover</a>.</p>
</footer>

</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}  ({len(HTML):,} bytes)")
