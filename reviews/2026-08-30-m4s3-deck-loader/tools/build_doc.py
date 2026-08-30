"""Assemble the M4 stage-3 review page, embedding each crop as a data URI.

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
    "87fe6ca3809343a5cd4a4e1d6777e9568d33417b"
)


def img(name, alt, caption):
    with open(os.path.join(REC, "crops", name), "rb") as fh:
        b64 = base64.b64encode(fh.read()).decode("ascii")
    return (
        f'<figure><div class="plate scan"><img src="data:image/png;base64,{b64}" '
        f'alt="{alt}"></div><figcaption>{caption}</figcaption></figure>'
    )


HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Stage 3 — eleven rules the deck and the loader had to settle</title>
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
.answer ol {{ margin:0 0 .85rem; padding-left:1.2rem; }}
.answer li {{ margin-bottom:.5rem; }}
.answer p:last-child {{ margin-bottom:0; }}
.chip {{ font-family:var(--mono); font-size:.66rem; letter-spacing:.14em;
         text-transform:uppercase; padding:.24em .6em; border-radius:2px;
         border:1px solid currentColor; white-space:nowrap; }}
.chip.decided {{ color:var(--stamp); background:var(--stamp-soft); }}
.chip.call {{ color:var(--stamp); background:var(--stamp-soft); }}
.chip.done {{ color:var(--settled); }}
.itemhead {{ display:flex; gap:.75rem; align-items:baseline; flex-wrap:wrap;
             margin-bottom:.35rem; }}
.item {{ border-top:1px solid var(--rule); padding-top:1.3rem; }}
.item.needs {{ border-top:2px solid var(--stamp); }}
figure {{ margin:1rem 0 1.2rem; }}
.plate {{ background:var(--raised); border:1px solid var(--rule); padding:.55rem;
          overflow-x:auto; }}
/* Scan plates keep a white ground in both themes: the scans are black ink on
   white paper, and inverting them lies about the artifact. */
.plate.scan {{ background:#FFFFFF; }}
.plate pre {{ margin:0; font-family:var(--mono); font-size:.78rem; line-height:1.5; }}
.plate img {{ display:block; max-width:100%; height:auto; image-rendering:crisp-edges; }}
figcaption {{ font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
              margin-top:.5rem; }}
.scroll {{ overflow-x:auto; margin:.5rem 0 1rem; }}
table {{ border-collapse:collapse; font-size:.92rem; margin:.6rem 0 1rem;
        font-variant-numeric:tabular-nums; }}
th, td {{ text-align:left; padding:.3rem .7rem .3rem 0; vertical-align:top;
         border-bottom:1px solid var(--hair); }}
th {{ font-family:var(--mono); font-size:.7rem; letter-spacing:.1em;
     text-transform:uppercase; color:var(--muted); font-weight:normal; }}
td.n {{ text-align:right; font-family:var(--mono); font-size:.85rem; white-space:nowrap; }}
.opt {{ border-left:3px solid var(--rule); padding:.15rem 0 .15rem 1rem; margin:0 0 1rem; }}
.opt.pick {{ border-left-color:var(--stamp); }}
.opt .name {{ font-family:var(--mono); font-size:.75rem; letter-spacing:.08em;
              text-transform:uppercase; }}
.ask {{ background:var(--stamp-soft); border:1px solid var(--stamp); padding:.9rem 1.1rem;
        margin:.9rem 0 0; }}
.ask p {{ margin:0 0 .5rem; }}
.ask p:last-child {{ margin:0; }}
.ask .label {{ font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
               text-transform:uppercase; color:var(--stamp); display:block; margin-bottom:.3rem; }}
footer {{ border-top:1px solid var(--rule); padding-top:1rem; font-size:.85rem;
          color:var(--muted); }}
</style>
</head>
<body>
<main>

<header>
<p class="eyebrow">Review record &middot; 2026-08-30 &middot; M4 stage 3 &middot; commit 87fe6ca</p>
<h1>Eleven rules the deck and the loader had to settle</h1>
<p class="standfirst">Stage 3 punches the object deck and reads it back. It
writes the <code>*FILE</code>, <code>*SPEC</code>, <code>*CTEXT</code> and
<code>*CTEND</code> cards, the relative binary text section, and the loader
that loads all of it at a chosen origin. It also grows
<code>--emit-object</code> to the whole printed document, so the object golden
is now PDF pp. 198 to 216 entire. Seven rules had one viable reading and were
taken under the section 12 standing rule. One asks for your authorization. Three
are here for the account.</p>
</header>

<section class="answer">
<h2>What happened, in eleven lines</h2>
<ol>
<li><strong>The text-card checksum sums word 1 and words 3 through
2&nbsp;+&nbsp;count</strong>, the three control words included. One loader
routine serves every section.</li>
<li><strong>One deck-wide serial counts every card</strong>, symbolic and binary
alike, punched as decimal digits ending at column 80. The print's 15 and 67
prove the counter crosses the binary cards.</li>
<li><strong>Where [J 90.08.02] allows "R or blank", the compiler punches
<code>R</code>.</strong> The one site is the <code>*SPEC</code> open column, 25,
when OPENW is absent.</li>
<li><strong>SEQ and CKSUMS refuse the job; a CHECKPOINT file's type column stays
blank.</strong> No manual gives a character for any of the three.</li>
<li><strong><code>--emit-object</code> now prints the loader-card page and the
closing lines</strong>, so <code>test/goldens/90.05-payroll.storage-map</code>
is PDF pp. 198 to 216 entire. Pages 8 to 25 are byte-identical to the golden
before it.</li>
<li><strong>The loader dump takes <code>* JOB n</code> headers; the deck dump
takes none.</strong> A dead job adds a marker line to the first and no cards to
the second.</li>
<li><strong>A blocksize past 9999 leaves the <code>*SPEC</code> blocksize field
blank.</strong> Msg 931 has already rejected the card, and four columns cannot
hold five digits.</li>
<li><strong>One transcription correction waits for you.</strong> PDF p. 198,
line 12 reads <code>*SPEC&nbsp;&nbsp;05</code> where the scan reads
<code>06</code>. It does not block the stage-3 pull request.</li>
<li><strong>The <code>*FILE</code> name column is 55, not 54</strong>, and the
<code>*CTEXT</code> date-and-time form is measured. The scan decides J against
itself; no conversion is edited.</li>
<li><strong>The page geometry is measured, not assumed.</strong> DATE at print
column 0 and PAGE at 83 are the ruler on both pages.</li>
<li><strong>A labeled PROGRAM.START still does not name the entry point.</strong>
The end-of-text entry names <code>GN)000</code> for every program; stage 4 lands
the change.</li>
</ol>
<p>Items 1 to 7 are <strong>DECIDED</strong> under the CLAUDE.md section 12
standing rule: silence lets them stand, and each is one commit to overturn.
Item 8 is <strong>YOUR CALL</strong> and blocks nothing. Items 9 to 11 are
<strong>SETTLED</strong> and ask nothing. The stage-3 pull request opens under
your standing authorization of 2026-08-16 and merges under the external-review
charter.</p>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>1 &middot; The text-card checksum sums the control words too</h2></div>

<p><strong>The decision.</strong> Word 2 of a text card holds the logical sum of
word 1 and of words 3 through 2&nbsp;+&nbsp;count, the three control-group words
included. [J 90.03.01] says word 2 is "logical sum of word 1 and all data words
on the card", and the same word-1 format table calls words 3 to 24 "data".
[J 90.03.03] then narrows the term for a text card: words 3, 4 and 5 hold "up to
19 5-bit control groups, one for each following data word on the card", so the
data words proper begin at word 6. Two readings follow, and this record takes
the wider one.</p>

<p><strong>Why the wider reading.</strong> The count in word 1, bits 13 to 17,
is the "word count (beginning with word 3)". A loader that sums the words the
count names needs one routine for every section and no knowledge of which
section a card belongs to. The narrower reading skips words 3 to 5, leaves the
control groups unverified, and needs section-specific loader code, because only
a text card has control-group words to skip. The logical sum is the
<code>ACL</code> rule: 36-bit addition with the carry out of position S returned
to position 35.</p>

<p><strong>The evidence.</strong> The sum and the card:</p>
<figure><div class="plate"><pre>/// The logical sum of [words] ([J 90.03.01] word 2): 36-bit addition
/// with the carry out of position S returned to position 35, the
/// `ACL` rule. The sum covers word 1 and every word from word 3 to the
/// last the count names, control words included (LD-2).
int logicalSum(Iterable&lt;int&gt; words) {{
  var sum = 0;
  for (final word in words) {{
    sum += word;
    if (sum &gt; Word36.wordMask) {{
      sum = (sum &amp; Word36.wordMask) + 1;
    }}
  }}
  return sum;
}}
...
  return [
    header,
    logicalSum([header, ...controls, ...data]),
    ...controls,
    ...data,
    ...List&lt;int&gt;.filled(textCardWords - data.length, 0),
  ];</pre></div>
<figcaption>evidence/loader.md LD-2 &mdash;
<a href="{GH}/lib/src/loader/object_deck.dart#L66-L79"><code>logicalSum</code></a>
and
<a href="{GH}/lib/src/loader/object_deck.dart#L101-L124"><code>textCard</code></a>
in object_deck.dart at 87fe6ca.</figcaption></figure>

<p><strong>What would mislead.</strong> The count reading looks like a second
open question and is not one. A text card the writer fills carries 19 data
words and 3 control words, so the count is 22 and the sum runs to word 24
either way. A short card pads with zero words to the end, so "words 3 to 24"
and "words 3 to 2&nbsp;+&nbsp;count" are the same sum for every card this
compiler punches. Only the control-group question changes a byte.</p>

<p><strong>What is at stake if this is wrong.</strong> No 1962 loader survives
to reject our decks. Our writer and our loader share the rule, so the stage-3
round trip cannot detect a mistake in it, and the record is the only place the
choice is visible.</p>

<p><strong>The rejected option.</strong></p>
<div class="opt">
<p><span class="name">A &mdash; sum word 1 and words 6 onward only</span><br>
[J 90.03.03]'s narrow sense of "data word". Cost: a corrupted control group
loads silently, which is the field the loader trusts to tell a relocatable
address from a constant. The loader also needs a per-section checksum rule,
since a text card is the only section with control words to skip, and no manual
states one.</p>
</div>
<div class="opt pick">
<p><span class="name">B &mdash; sum the words the count names (taken)</span><br>
Word 1's own format table calls words 3 to 24 data, and the count begins at word
3. <strong>To overturn:</strong> one line in
<a href="{GH}/lib/src/loader/object_deck.dart#L118"><code>textCard</code></a>
and one in
<a href="{GH}/lib/src/loader/loader.dart#L271"><code>_textCard</code></a>,
then regenerate <code>test/goldens/90.05-payroll.deck</code>.
<strong>What overturns it:</strong> a surviving 1962 binary deck, or a period
note on the loader's checksum routine.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>2 &middot; One serial counts every card of the deck</h2></div>

<p><strong>The decision.</strong> One counter runs across the whole deck,
symbolic and binary cards alike, and punches as decimal digits ending at column
80. The print gives the two ends of it.</p>

{img("p198-ctext.png", "The *CTEXT line of PDF p. 198 with a print-column ruler",
     "crops/p198-ctext.png &mdash; the last card of listing page 7, with the "
     "computed ruler. The serial 15 sits at print columns 72 and 73. Card "
     "column 7 prints at print column 0, so those are card columns 79 and 80.")}

{img("p216-closing.png", "The closing lines of PDF p. 216 with a print-column ruler",
     "crops/p216-closing.png &mdash; the end-of-text line, a blank, the message, "
     "the *CTEND card with serial 67, and DONE. Measured in "
     "evidence/p216-cols.txt at slots 47, 49, 50 and 51.")}

<p><strong>The arithmetic that proves the counter crosses the binary deck.</strong>
The sample's text section holds 961 data words &mdash; the rows of
<code>test/goldens/90.05-payroll.code</code> that carry a control group.
[J 90.03.03] gives a text card "up to 19" control groups, so 19 words a card. The
serials then close exactly on the print:</p>
<div class="scroll">
<table>
<tr><th>Words a card</th><th>Text cards for 961 words</th><th>Serial of <code>*CTEND</code></th></tr>
<tr><td class="n">18</td><td class="n">54</td><td class="n">70</td></tr>
<tr><td class="n">19 (taken)</td><td class="n">51</td><td class="n">67 &mdash; the print</td></tr>
<tr><td class="n">20</td><td class="n">49</td><td class="n">65</td></tr>
</table>
</div>
<p>15 for the symbolic cards, plus 51 text cards, plus the <code>*CTEND</code>
card, is 67. Neither neighbouring blocking factor lands on it. So the counter
does advance across the 51 binary cards.</p>

<p><strong>What the arithmetic does not prove.</strong> It fixes the count, not
the punch. Whether the 1962 compiler put the digits in columns 73 to 80 of a
binary card is not settled by any surviving artifact, and no byte image of the
deck survives. The writer punches them; the loader reads columns 1 to 72 of a
binary card and never looks at 73 to 80, so the choice costs it nothing either
way.</p>

<figure><div class="plate"><pre>CardImage binaryCard(List&lt;int&gt; words, {{String serial = ''}}) {{
  final columns = List&lt;int&gt;.filled(CardImage.columnCount, 0);
  for (final (int i, int word) in words.indexed) {{
    columns[3 * i] = (word &gt;&gt; 24) &amp; 0xFFF;
    columns[3 * i + 1] = (word &gt;&gt; 12) &amp; 0xFFF;
    columns[3 * i + 2] = word &amp; 0xFFF;
  }}
  for (final (int i, String digit) in serial.split('').indexed) {{
    columns[CardImage.columnCount - serial.length + i] = punchesFromBcd(
      bcdFromGlyph(digit)!,
    )!;
  }}
  return CardImage.fromColumns(columns);
}}</pre></div>
<figcaption><a href="{GH}/lib/src/loader/object_deck.dart#L128-L141"><code>binaryCard</code></a>
in object_deck.dart at 87fe6ca. The serial right-aligns to the last column.</figcaption></figure>

<p><strong>The rejected option.</strong></p>
<div class="opt">
<p><span class="name">A &mdash; leave columns 73 to 80 blank on a binary card</span><br>
Equally unattested, and equally free at load time. Cost: the deck golden then
holds a card whose serial the printed page implies and the deck does not carry,
so a later reader cannot tell the count from the deck alone.</p>
</div>
<div class="opt pick">
<p><span class="name">B &mdash; punch the digits (taken)</span><br>
The counter that the print attests is the counter the deck carries.
<strong>To overturn:</strong> drop the <code>serial:</code> argument at
<a href="{GH}/lib/src/loader/object_deck.dart#L214-L217">the one call site</a>
and regenerate the deck golden. <strong>What overturns it:</strong> a surviving
1962 object deck.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>3 &middot; "R or blank" punches <code>R</code></h2></div>

<p><strong>The decision.</strong> [J 90.08.02] gives two <code>*SPEC</code>
columns the value "R or blank": column 25, the open option, and column 27, the
close option. The compiler punches <code>R</code> at both. The live case is
column 25 with OPENW absent, which the sample does not exercise.</p>

{img("p198-file01.png", "The *FILE 01 and *SPEC 01 lines of PDF p. 198 with a ruler",
     "crops/p198-file01.png &mdash; the first card pair. On the *SPEC line, N "
     "sits at print column 18 and R at print column 20: card columns 25 and 27. "
     "On the *FILE line, the type I is at print 21 (card 28), HB at print 23 to "
     "24 (card 30 to 31), and INPUTMASTER begins at print 48 (card 55).")}

<p><strong>What the sample attests, and what it does not.</strong> All seven of
the sample's files carry OPENW, so column 25 prints <code>N</code> on every
<code>*SPEC</code> line of the page. The attested <code>R</code> is column 27,
under CLOSER, where the same table's words allow a blank and the print gives a
character. The open column is read the same way. So the sample settles the
sibling column and not this one, and that is why the item is here.</p>

<p><strong>The related default.</strong> A file with no SPECIF card at all takes
every default, this one included. [J 02.06.07]: SPECIF cards "are not necessary
for correct compilation of a Commercial Translator program".
<a href="{GH}/lib/src/loader/control_cards.dart#L155">One line</a> of
control_cards.dart carries the rule.</p>

<p><strong>The rejected option.</strong></p>
<div class="opt">
<p><span class="name">A &mdash; leave column 25 blank</span><br>
The loader accepts both, so nothing breaks at load time. Cost: two columns the
manual describes in identical words would then print differently, for no reason
the manual gives, and a later reader has no way to tell the blank from an
unimplemented field.</p>
</div>
<div class="opt pick">
<p><span class="name">B &mdash; punch <code>R</code> (taken)</span><br>
One reading for one phrase. <strong>To overturn:</strong> one character in
<code>lib/src/loader/control_cards.dart</code>, and the loader golden.
<strong>What overturns it:</strong> a period deck or listing that prints a blank
open column.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>4 &middot; SEQ and CKSUMS refuse; a CHECKPOINT file's type column stays blank</h2></div>

<p><strong>The decision.</strong> [J 90.08.01] names column 33 for SEQ and
column 34 for CKSUMS and gives no character for either. Its type row lists
<code>I</code> for INPUT, <code>T</code> for OUTPUT with SPANS and <code>P</code>
for OUTPUT, and nothing for CHECKPOINT. The sample uses none of the three. SEQ
and CKSUMS refuse the job. The CHECKPOINT type column, 28, stays blank.</p>

<p><strong>Why the two cases part.</strong> Refusing a checkpoint file would make
D7.2's <code>C</code> in column 35 unreachable. That character is attested and
its decision is locked: [J 90.08.01] sources it from "FILE CHECKPOINT AND SPECIF
CHKS", so a file that reaches it must be a CHECKPOINT file. Deleting the code
under CLAUDE.md section 11 would then delete work a locked decision requires,
and keeping it under a refusal would leave code no run reaches. A blank type
column keeps both rules satisfied.</p>

<figure><div class="plate"><pre>_unruled('a SPECIF SEQ option (no attested *FILE character; J 90.08.01)');
...
  'a SPECIF CKSUMS option (no attested *FILE character; J 90.08.01)',
...
// A checkpoint file has no type character: [J 90.08.01] lists the
// three characters and gives CHECKPOINT none.
  FileDirection.checkpoint =&gt; '',</pre></div>
<figcaption><a href="{GH}/lib/src/loader/control_cards.dart#L72-L84">control_cards.dart lines 72 to 84</a>
at 87fe6ca. The <code>C</code> of column 35 is D7.2's, at
<a href="{GH}/lib/src/loader/control_cards.dart#L101-L102">lines 101 to 102</a>.</figcaption></figure>

<p><strong>The options.</strong></p>
<div class="opt">
<p><span class="name">A &mdash; invent the three characters</span><br>
The IOCS manual may well hold them. It is not in this repository, and nothing
verifiable supports a guess. Cost: a later reader takes an invented character
for a recovered one, which is the failure mode the whole evidence discipline
exists to prevent.</p>
</div>
<div class="opt pick">
<p><span class="name">B &mdash; refuse (taken for SEQ and CKSUMS)</span><br>
The shape the generator already uses for an unattested construct (M4-2 as
amended). Cost: a program that writes SEQ or CKSUMS gets no object deck. Its
listing still prints, so the front end is unaffected. <strong>To overturn:</strong>
add the character in <code>lib/src/loader/control_cards.dart</code>.</p>
</div>
<div class="opt pick">
<p><span class="name">C &mdash; blank (taken for the CHECKPOINT type column)</span><br>
The only option that leaves D7.2's attested <code>C</code> reachable.
<strong>What overturns either:</strong> the IOCS manual, or a period listing that
prints a *FILE card for a checkpoint file.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>5 &middot; <code>--emit-object</code> grows to the whole printed document</h2></div>

<p><strong>The decision.</strong> <code>--emit-object</code> now writes
everything the 1962 printer put after the source pages: the loader-card page,
the object pages, and the closing lines. So
<code>test/goldens/90.05-payroll.storage-map</code> is PDF pp. 198 to 216
entire &mdash; the span D0.3's oracle names, and the page HANDOVER on
<code>master</code> assigned to this stage.</p>

{img("p198-head-message.png", "The head and message lines of PDF p. 198 with a ruler",
     "crops/p198-head-message.png &mdash; the page head with DATE at print column "
     "0 and PAGE at 83, then the message line beginning at print column &minus;6, "
     "six columns left of the LOC column of the object pages.")}

{img("p198-page.png", "The whole body of PDF p. 198",
     "crops/p198-page.png &mdash; the page frame: the head, two blank lines, the "
     "message, a blank, then fifteen card lines carrying serials 1 to 15.")}

<p><strong>The measured frame.</strong> <code>tools/cols.py</code> reports every
ink line's slot against the head. The body of PDF p. 198 uses them like this:</p>
<div class="scroll">
<table>
<tr><th>Slot</th><th>What prints</th><th>First ink</th></tr>
<tr><td class="n">0</td><td>the page head</td><td class="n">print column 0 (DATE)</td></tr>
<tr><td class="n">1, 2</td><td>blank</td><td class="n">&mdash;</td></tr>
<tr><td class="n">3</td><td><code>THE FOLLOWING LOADER CONTROL CARDS PRECEDE THE BINARY DECK.</code></td><td class="n">&minus;6</td></tr>
<tr><td class="n">4</td><td>blank</td><td class="n">&mdash;</td></tr>
<tr><td class="n">5 to 19</td><td>the fifteen cards, card column 1 at print column &minus;6</td><td class="n">0 (card column 7)</td></tr>
</table>
</div>
<p>The head, two blank lines and 55 content lines is the object pages' own
frame, so page 7 needs no new geometry. The cards' visible ink starts at print
column 0 because columns 1 to 6 hold the deck.name, which a <code>*COMPILE</code>
card leaves blank (D7.11).</p>

<p><strong>The closing lines.</strong> One blank follows the end-of-text line,
then the message at print column &minus;6, the <code>*CTEND</code> card from
&minus;6, and <code>DONE</code> at &minus;5 (M4-8 as amended). They paginate with
the object lines. The p. 216 crop under item 2 is the plate.</p>

<p><strong>The verification.</strong> The golden that stage 2 left held 1034
lines. Every one of them is in the new golden, unmoved:</p>
<div class="scroll">
<table>
<tr><th>Golden lines</th><th>What they hold</th></tr>
<tr><td class="n">1&ndash;20</td><td>listing page 7, PDF p. 198: head, two blanks, message, blank, fifteen cards</td></tr>
<tr><td class="n">21&ndash;1054</td><td>pages 8 to 25, byte-identical to the 1034 lines of the previous golden</td></tr>
<tr><td class="n">1055&ndash;1058</td><td>the closing lines: blank, message, <code>*CTEND</code>, <code>DONE</code></td></tr>
</table>
</div>
<p>Page 7 matches evidence/p198-transcription.txt token for token, with one
exception: the cell item 8 asks you about. evidence/p198-golden.txt holds the
new golden's first twenty lines beside it.</p>

<p><strong>What is unattested.</strong> A program whose control cards overflow
one page continues on a page with its own head. No artifact attests that, and
the pagination is mechanical.</p>

<p><strong>The rejected options.</strong></p>
<div class="opt">
<p><span class="name">A &mdash; print page 7 at the end of the source listing on stdout</span><br>
Cost: it changes <code>test/goldens/90.05-payroll.listing</code>, the front end's
acceptance oracle, for a page the code generator produces. It also splits the
deck writer's output across two dumps, so neither one holds the document the
printer printed.</p>
</div>
<div class="opt">
<p><span class="name">B &mdash; leave the page out; give only <code>--emit-loader</code> the card text</span><br>
Cost: no printed document then holds page 7, so the loader-card page is never
compared against its scan as a page. The page-number arithmetic &mdash; page 7
is the source pages plus one &mdash; stays an assumption no golden tests.</p>
</div>
<div class="opt pick">
<p><span class="name">C &mdash; the whole document, in the object dump (taken)</span><br>
One dump, one document, one oracle span. <strong>To overturn:</strong> the page
and the trailer are separate writers in the object emitter; removing either is
one commit and a golden regeneration. <strong>What overturns it:</strong> a
period listing whose loader-card page sits somewhere else in the print.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>6 &middot; The loader dump takes job headers; the deck dump takes none</h2></div>

<p><strong>The decision.</strong> <code>--emit-loader</code> prints one
<code>* JOB n</code> section per job, holding that job's symbolic cards as text
with their serials, or its marker line. <code>--emit-deck</code> is the canon
container of every job's cards in deck order, and a job that produced no object
program adds no cards.</p>

<p><strong>Why they differ.</strong> One <code>* JOB n</code> section per job is
the emit-stages default. Two dumps depart from it, and each has a named reason:
the cards dump is the whole deck's mirror, and the object dump's job sections
open with their own page heads. The loader dump has neither reason. It also has
a positive one: a deck of two dead jobs would otherwise print two adjacent
marker lines with nothing to say which job each belongs to. The deck dump is
binary, and a binary container holds no marker line, so a dead job leaves no
trace in it.</p>

<p>Both conventions are recorded in
<a href="{GH}/docs/design/emit-stages.md">emit-stages.md</a>, beside the seven
that came before them.</p>

<p><strong>The rejected option.</strong></p>
<div class="opt">
<p><span class="name">A &mdash; no headers in the loader dump either</span><br>
Cost: the dump of a multi-job deck becomes ambiguous exactly where a reader
needs it, at a job that failed. A marker line names the stop, not the job.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>7 &middot; A blocksize past 9999 leaves the field blank</h2></div>

<p><strong>The decision.</strong> The <code>*SPEC</code> blocksize field is four
columns wide, 17 to 20 ([J 90.08.02]; D7.1), and holds the FILE card's value
right-justified. A value past 9999 leaves it blank.</p>

<p><strong>Why nothing else works.</strong> Msg 931, non-historical and severity
4, has already rejected the FILE card in the environment binder:
<code>-BLOCKSIZE- EXCEEDS THE ENVIRONMENT MAXIMUM OF 9999 WORDS. -FILE- CARD
REJECTED. (NON-HISTORICAL.)</code> Severity 4 does not stop the job, so code
generation runs and a card must be punched. Five digits do not fit in four
columns.</p>

<p><strong>The rejected options.</strong></p>
<div class="opt">
<p><span class="name">A &mdash; overrun into column 16</span><br>
Cost: column 16 belongs to another field, so the card the loader reads carries a
digit where a different value is expected. The compiler would emit a card it
knows to be malformed.</p>
</div>
<div class="opt">
<p><span class="name">B &mdash; refuse the whole job</span><br>
Cost: a severity-4 diagnostic would then behave like a severity 5, against
[J 90.04.02] and D7.1's own reading, for a value the listing has already told
the programmer about.</p>
</div>
<div class="opt pick">
<p><span class="name">C &mdash; blank field (taken)</span><br>
The card records what the compiler accepted, and the listing records what it
rejected. <strong>To overturn:</strong>
<a href="{GH}/lib/src/loader/control_cards.dart#L145-L153">one switch arm</a>
in control_cards.dart. <strong>What overturns it:</strong> an attested message
or an attested card for the over-maximum case.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>8 &middot; One character of the p. 198 transcription</h2></div>

<p><strong>What I am asking for.</strong> Authorization to correct
<code>comtran-manuals/J28-6169/90.05-sample-program.md</code>, the PDF p. 198
listing block, line 12: <code>*SPEC&nbsp;&nbsp;05</code> to
<code>*SPEC&nbsp;&nbsp;06</code>. One character. It does not block the stage-3
pull request, and it would land in a later routine pull request.</p>

<p><strong>The view that misleads.</strong> At page magnification the disputed
cell reads as a 5, which is what the transcriber read:</p>

{img("p198-page.png", "The whole body of PDF p. 198 at page magnification",
     "crops/p198-page.png &mdash; the twelfth card, below *FILE 06, reads 05 at "
     "this size. Four *SPEC lines in a row appear to print 05, 05, 05, 07.")}

<p><strong>The view that decides it.</strong> Enlarged, the two glyph classes
separate, and the disputed cell belongs to the 6 class:</p>

{img("spec06.png", "The *FILE 05 through *SPEC 07 lines of PDF p. 198 enlarged",
     "crops/spec06.png &mdash; six lines: *FILE 05, *SPEC 05, *FILE 06, the "
     "disputed *SPEC line, *FILE 07, *SPEC 07. The 5 of the first two lines has "
     "a flat top and a straight upper-left stroke. The 6 of *FILE 06 has a "
     "rounded top whose stroke is weak. The disputed glyph carries that same "
     "weak rounded top.")}

{img("p198-file06.png", "The same six lines with a print-column ruler",
     "crops/p198-file06.png &mdash; the same region with the computed ruler. The "
     "file number occupies print columns 7 and 8, card columns 14 and 15, on "
     "both card types.")}

<p><strong>The corroboration the ink does not need.</strong> The field logic
forces 6 on its own. A <code>*SPEC</code> card pairs with the <code>*FILE</code>
card of the same file number, the <code>*FILE 06</code> line directly above it
is BONDORDERFILE, and the sample's seven files each get one pair (LD-1). A
<code>*SPEC 05</code> there would be a second <code>*SPEC</code> for PAYFILE and
none for BONDORDERFILE. The compiler prints <code>06</code>, and
evidence/p198-golden.txt holds that line.</p>

<p><strong>Why it is still yours.</strong> The conversions are read-only and a
change needs your explicit authorization (CLAUDE.md sections 8 and 9). Nothing
in the code waits on it: the golden is already right, and
<code>docs/HANDOVER.md</code> lists this as the one open erratum candidate, so
the record of the divergence is durable either way.</p>

<div class="ask"><span class="label">What I need from you</span>
<p>Authorize the one-character correction, or overturn my reading. My
recommendation is to authorize: the enlargement is decisive, and the field logic
agrees with it independently.</p>
<p>This item does not block the stage-3 pull request. The other ten items ask
nothing.</p></div>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>9 &middot; The <code>*FILE</code> name column, and the <code>*CTEXT</code> date form</h2></div>

<p><strong>J disagrees with itself about one column.</strong> [J 90.08.01]'s
table row reads <code>| 54-72 | file name | FILE - name field |</code>.
[J 03.02.02] draws the same field from column 55 to column 72. The scan decides:
<code>INPUTMASTER</code> begins at print column 48, and card column 7 prints at
print column 0, so the name starts at card column 55. The code uses 55. Neither
manual conversion is edited &mdash; the divergence is J's own, not a
transcription fault, and CLAUDE.md section 9 has no rank that touches it.</p>

<p>The same crop settles the rest of the <code>*FILE</code> and
<code>*SPEC</code> geometry. The plate is under item 3; these are its measured
columns, from evidence/p198-cols.txt slot 5:</p>
<div class="scroll">
<table>
<tr><th>Field</th><th>Print column</th><th>Card column</th></tr>
<tr><td><code>*FILE</code> / <code>*SPEC</code></td><td class="n">0&ndash;4</td><td class="n">7&ndash;11</td></tr>
<tr><td>file number</td><td class="n">7&ndash;8</td><td class="n">14&ndash;15</td></tr>
<tr><td>unit (<code>*D1</code>)</td><td class="n">10&ndash;12</td><td class="n">17&ndash;19</td></tr>
<tr><td>blocksize (<code>300</code>)</td><td class="n">11&ndash;13</td><td class="n">18&ndash;20</td></tr>
<tr><td>open option (<code>N</code>)</td><td class="n">18</td><td class="n">25</td></tr>
<tr><td>close option (<code>R</code>)</td><td class="n">20</td><td class="n">27</td></tr>
<tr><td>type (<code>I</code>)</td><td class="n">21</td><td class="n">28</td></tr>
<tr><td>density and label (<code>HB</code>)</td><td class="n">23&ndash;24</td><td class="n">30&ndash;31</td></tr>
<tr><td>file name</td><td class="n">48</td><td class="n">55</td></tr>
<tr><td>serial</td><td class="n">73</td><td class="n">80</td></tr>
</table>
</div>
<p>One row is read off the crop rather than off the column pass. A
<code>*FILE</code> line and the <code>*SPEC</code> line below it fall in one ink
band at this line spacing, so the pass cannot part the unit field from the
blocksize field. The two are separable by eye in the plate, and D7.1 states the
blocksize field independently as card columns 17 to 20, right-justified.</p>

<p><strong>The <code>*CTEXT</code> date-and-time form.</strong> [J 03.02.09]
gives columns 26 to 54 to "date.and.time" and no form at all. The print gives
one. Measured from evidence/p198-cols.txt slot 19, against the crop under item
2:</p>
<div class="scroll">
<table>
<tr><th>Field</th><th>Print column</th><th>Card column</th></tr>
<tr><td><code>*CTEXT</code></td><td class="n">0&ndash;5</td><td class="n">7&ndash;12</td></tr>
<tr><td><code>DATE</code></td><td class="n">19&ndash;22</td><td class="n">26&ndash;29</td></tr>
<tr><td><code>101861</code></td><td class="n">24&ndash;29</td><td class="n">31&ndash;36</td></tr>
<tr><td><code>TIME</code></td><td class="n">31&ndash;34</td><td class="n">38&ndash;41</td></tr>
<tr><td><code>2.45</code>, right-aligned</td><td class="n">38&ndash;41</td><td class="n">45&ndash;48</td></tr>
<tr><td>secondary identifier</td><td class="n">48</td><td class="n">55</td></tr>
<tr><td>serial</td><td class="n">72&ndash;73</td><td class="n">79&ndash;80</td></tr>
</table>
</div>
<p>The date prints without separators where the page head prints
<code>10/18/61</code>, and the time right-aligns to end at card column 48. Both
are print facts, not manual facts, and LD-1 records them as such.</p>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>10 &middot; How the columns were measured</h2></div>

<p>Every column in this document comes from the 150-dpi page scan, never from
the indentation of a transcription (CLAUDE.md section 9).
<code>tools/cols.py</code> does the work in three steps. It deskews the page by
maximising the variance of the horizontal ink profile. It then keeps only ink
that sits in a vertical run of four rows or more, which drops the tractor-feed
dashes that run the width of the page. It finds the head line by its long run of
ink, and solves the character pitch from two fields whose columns are fixed:
DATE at print column 0 and PAGE at print column 83.</p>

<div class="scroll">
<table>
<tr><th>Page</th><th>Deskew</th><th>Pitch</th><th>DATE</th><th>PAGE</th></tr>
<tr><td class="n">PDF 198</td><td class="n">0.500&deg;</td><td class="n">9.253 px</td><td class="n">x = 438</td><td class="n">x = 1206</td></tr>
<tr><td class="n">PDF 216</td><td class="n">1.150&deg;</td><td class="n">9.2651 px</td><td class="n">x = 432</td><td class="n">x = 1201</td></tr>
</table>
</div>

<p>The two pages differ by about 6 px in registration and by 0.65&deg; in skew, which
is why each page is calibrated on its own. <code>tools/ruler.py</code> then
draws the solved grid under each crop, so every plate in this document carries
the ruler that measured it rather than a ruler drawn afterwards.
<code>tools/lines.py</code> is the earlier line-finder, kept because it is what
produced the line bands the column pass consumed. evidence/p198-cols.txt and
evidence/p216-cols.txt hold the full output.</p>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>11 &middot; A labeled PROGRAM.START still does not name the entry point</h2></div>

<p>D2.1 says a statement or section labeled PROGRAM.START designates the object
program's entry point, and that the compiler punches that location into the
end-of-text entry, control group <code>01111</code>. The code generator does not
yet honour the label: the entry names <code>GN)000</code>, the generated name of
the first <code>*PROCEDURE</code> sentence, for every program. That is D2.1's
own default path, and it is the path the 1962 sample takes, so no golden is
wrong.</p>

<p>The loader consumes the entry as decided, so stage 3 is complete on its own
terms. The generator change waits for stage 4, the first stage in which a
program runs and an entry point has an observable effect. It is recorded in
<code>docs/HANDOVER.md</code> and in evidence/loader.md at LD-3, on the list of
two items stage 4 inherits.</p>
</section>

<footer>
<p>Record built 2026-08-30 on branch
<code>review/2026-08-30-m4s3-deck-loader</code>. Stage 3 is commit
<a href="https://github.com/Screendead/comtran-compiler/commit/87fe6ca3809343a5cd4a4e1d6777e9568d33417b">87fe6ca</a>
on <code>m4s3-deck-loader</code>; every link and caption above points at that
commit. The design record these decisions landed in is
<a href="{GH}/docs/design/loader.md">docs/design/loader.md</a>, entries LD-1 to
LD-4, shipped here as evidence/loader.md. Items 1 to 7 are DECIDED: silence lets
them stand. Item 8 waits for you and blocks nothing. Items 9 to 11 ask
nothing.</p>
</footer>

</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
