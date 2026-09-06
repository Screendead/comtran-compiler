"""Assemble the emulator-reuse review page.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: it embeds no images, because this record
argues from source text and measurements rather than from page scans, and the
listing excerpts ship beside it in `evidence/`.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

GH = (
    "https://github.com/Screendead/comtran-compiler/blob/"
    "8251b4a9d4588572705ff0fd85a4b73a10e905de"
)


def plate(text, caption):
    body = (
        text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    )
    return (
        f'<figure><div class="plate"><pre>{body}</pre></div>'
        f"<figcaption>{caption}</figcaption></figure>"
    )


CT_PLATE = plate(
    """$CMPLE MOVPAK  LIST,DICT,SUB                          CT0500   07/15/63
               ENTER CRYPT
* 7090 COMM. TRAN. (OBJECT SUBROUTINE) VERSION 5      JULY 15, 1963
*                 THIS SUBROUTINE IS EMPLOYED TO
*              MOVE FIELDS FROM ONE LOCATION TO
*              ANOTHER
       SYS     179                 MOVPAK
MOVPAK SXA     SAVE2,2
       AXT     2,2
       TRA     *+4
       SYS     180                 MVPAK1
MVPAK1 STO     SAVACC""",
    "CT/ct.job lines 57878-57889. MOVPAK is the runtime move-and-convert "
    "package our glossary names from [J 90.02.10]. SYS 179 and SYS 180 are "
    "the cells our generated code calls.",
)

LST_PLATE = plate(
    """ 13505   0634 00 2 13611     9  MOVPAK SXA     SAVE2,2""",
    "CT/ct.lst line 64417. Location 13505 holds 0634 00 2 13611: opcode 0634 "
    "is SXA, tag 2, address 13611. The octal column is populated, so this is "
    "assembled machine code and not source alone.",
)

CELLS_PLATE = plate(
    """MOVOVF EQU     SYS)130
MOVERR EQU     SYS)131
       VFD     O6/23,30/BLERR      SYS)294 (BL NOT LOADED ERR)
*              CT SUBROUTINE SYS)177
*              CT SUBROUTINE SYS)178
MVPAK1 EQU     SYS)180""",
    "Cross-references in the recovered source, at ct.job lines 59516, 59517, "
    "31877, 57636, 57837 and 57886 in that order. SYS)130 and SYS)131 are the "
    "two MOVPAK communication cells whose behaviour our decision records "
    "currently settle as our own choice.",
)

SEGMENTS_PLATE = plate(
    """segment  lines           words   what it is
   1       10 -    918     857   709/7090 COMMERCIAL TRANSLATOR MONITOR (VERSION 5)
   2      922 -   5675    4744   709/7090 IOCS VERSION 'C' (SYSTEM COMPONENT FORM)
   3     5679 -  55719    4190   7090 COMMERCIAL TRANSLATOR (CT) VERSION V
                                 + overlays at CTBOVL, debug at CTBDBG
   4    55728 -  66684      --   40 object-time subroutine decks, compiled by CT""",
    "The four job steps of CT/ct.job. Segments 1 to 3 are assembled by IBSFAP; "
    "segment 4 runs under $EXECUTE CT at line 55728. The word counts are the "
    "COUNT cards at lines 15, 925 and 5682.",
)

LAS_PLATE = plate(
    """case Op.las: // M p. 43: AC(Q,P,1-35) unsigned against C(Y)(S,1-35).
  final int y = state.read(_effectiveAddress(inst, indirectable: true));
  final int skip;
  if (state.acMagnitude > y) {""",
    "lib/src/emulator/cpu.dart:200-203. acMagnitude is 37 bits with Q at bit "
    "36 and P at bit 35; a storage word is 36 bits with S at bit 35.",
)

HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Someone else's 7090 — and what the search found instead</title>
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
.chip.call {{ color:var(--stamp); background:var(--stamp-soft); }}
.ruling {{ background:var(--raised); border:1px solid var(--hair);
           border-left:3px solid var(--settled); padding:1.15rem 1.3rem; }}
.ruling p:last-child {{ margin-bottom:0; }}
.ruling .eyebrow {{ color:var(--settled); }}
.chip.done {{ color:var(--settled); }}
.itemhead {{ display:flex; gap:.75rem; align-items:baseline; flex-wrap:wrap;
             margin-bottom:.35rem; }}
.item {{ border-top:1px solid var(--rule); padding-top:1.3rem; }}
.item.needs {{ border-top:2px solid var(--stamp); }}
figure {{ margin:1rem 0 1.2rem; }}
.plate {{ background:var(--raised); border:1px solid var(--rule); padding:.55rem;
          overflow-x:auto; }}
.plate pre {{ margin:0; font-family:var(--mono); font-size:.78rem; line-height:1.5; }}
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
<p class="eyebrow">Review record &middot; 2026-09-06 &middot; M4 stage 4 &middot; commit 8251b4a</p>
<h1>Someone else's 7090 &mdash; and what the search found instead</h1>
<p class="standfirst">You asked whether an existing, maintained 7090 emulator
could save us the work before stage 4 begins. Six projects were surveyed and
ten profiled. The answer on the emulator is no, for reasons that are not the
ones I gave you mid-search. The search also turned up the 1963 Commercial
Translator on a recovered IBSYS tape, with its object-time subroutine library
assembled and listed, and that is worth more than the question that found
it.</p>
</header>

<section class="ruling">
<p class="eyebrow">Corrected &middot; 2026-09-06, before this record was read</p>
<p>Item 2 originally closed with one vague sentence: &ldquo;It also contains
the processor itself, which is the thing this project reconstructs. I have not
looked at what that implies and I am not going to guess in this record.&rdquo;
That left the largest claim in the record unchecked. Roughly 50,000 lines of
<code>ct.job</code> had not been characterised at all when it was written.</p>
<p>They have now been read far enough to say what they are, and the claim
holds: segment 3 is the Commercial Translator compiler, Version V of July 1963.
Item 2 now carries the job's segment map and a line citation in place of the
sentence above. Nothing else changed, and the recommendation is unchanged.</p>
</section>

<section class="answer">
<h2>What happened, in six lines</h2>
<ol>
<li><strong>The emulators are maintained; the 7090 CPUs inside them are
not.</strong> Both SIMH repositories were pushed within the last month, but the
7094 model has had no semantic change since 2011 and the 7090 model none since
2024. That distinction is the direct answer to what you asked.</li>
<li><strong>Keep our Dart core.</strong> Not because it is smaller, and not
because D0.3 is locked. Because embedding any of them destroys the validation
that was the only reason to want them, and because <code>dart:ffi</code> cannot
compile to WebAssembly, which forfeits the browser run target HANDOVER names.</li>
<li><strong>The lost runtime is not an argument against adoption.</strong> I
told you mid-search that it was the decisive fact. It is not: the Dart handlers
cost the same under any CPU, so it is a zero on the ledger. Every candidate
report made the same error.</li>
<li><strong>The Commercial Translator survives on an IBSYS tape.</strong>
<code>CT/ct.job</code> is the 1963 processor in FAP source; <code>ct.lst</code>
carries it assembled with octal. Forty object-time subroutine decks are in it,
MOVPAK among them, using the same SYS) and IOC) cell numbers our compiler
emits.</li>
<li><strong>Reading it would cost the emulator scope you fenced off.</strong>
The library uses floating point, trapping and channel I/O &mdash; the three
families our design record puts out of scope and D0.7 exists to avoid.</li>
<li><strong>One small observation and two corrections</strong> are recorded
below and ask nothing.</li>
</ol>
<p>Items 1 to 3 are <strong>YOUR CALL</strong>. Item 2 in particular is not a
decision I should take under the section 12 standing rule: you named the
emulator option yourself on 2026-08-05 and asked to be consulted, and the
tape find changes a premise of a locked record. Item 4 is
<strong>SETTLED</strong>. Nothing here is committed and nothing is blocked;
stage 4 can start on the current plan the moment you say so.</p>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>1 &middot; Adopt someone else's 7090? No &mdash; keep ours</h2></div>

<p><strong>What was searched.</strong> Four independent sweeps returned
twenty-one names, which deduplicated to six independent codebases. Ten profiles
were built, each answering the same six questions from fetched sources; four of
the profilers built and ran their candidate. The table has seven rows because
Open SIMH carries the same two CPU modules as classic SIMH and is listed
separately.</p>

<div class="scroll">
<table>
<tr><th>Project</th><th>What it is</th><th>Real 7090 mode</th><th>CPU last changed</th><th>Verdict</th></tr>
<tr><td>SIMH <code>I7094</code></td><td>Supnik's 7094 module, in both SIMH forks</td><td>Yes, per-opcode model gate</td><td class="n">2011</td><td>Oracle only</td></tr>
<tr><td>SIMH <code>I7000/i7090</code></td><td>Cornwell's 704/709/7090/7094 module</td><td>Yes, and it is the default</td><td class="n">2024</td><td>Oracle only</td></tr>
<tr><td>Open SIMH</td><td>Community fork; same two modules</td><td>Yes, both</td><td class="n">2023</td><td>Oracle only</td></tr>
<tr><td><code>rcornwell/sims</code></td><td>Cornwell's own upstream</td><td>Yes</td><td class="n">2024</td><td>Oracle only</td></tr>
<tr><td><code>SimH_cpanel</code></td><td>Front-panel fork over a 2017 snapshot</td><td>Yes, inherited</td><td class="n">2017</td><td>Neither</td></tr>
<tr><td><code>s709</code> (Pitts)</td><td>Independent C emulator, MIT</td><td>Yes, enforced at 27 sites</td><td class="n">2023</td><td>Best oracle</td></tr>
<tr><td><code>B7094</code> (Storey)</td><td>Object Pascal, GUI-only, no licence</td><td>Untested by anyone</td><td class="n">2023</td><td>Neither</td></tr>
</table>
</div>

<h3>The answer to what you actually asked</h3>
<p><strong>&ldquo;Maintained&rdquo; is true of the trees and false of the parts
we would use.</strong> <code>simh/simh</code> was pushed on 2026-08-31 and
<code>open-simh/simh</code> on 2026-07-03. But the last change of any substance
to Supnik's 7094 was in 2011, and every commit since is compiler-warning
hygiene; Cornwell's 7090 last changed for a warning cleanup in March 2024, its
last functional fix in November 2023. Nobody is going to fix a 7090 bug we
report. That is the opposite of what &ldquo;battle-tested and maintained&rdquo;
usually buys.</p>

<p><strong>&ldquo;Battle-tested&rdquo; is true and is the real attraction.</strong>
Cornwell's simulator ships 52 IBM customer-engineering diagnostic decks and
boots CTSS, IBSYS and Lisp 1.5. Pitts' <code>s709</code> runs IBSYS with
FORTRAN II, FORTRAN IV, COBOL and Lisp. Against that, our core has one reading
of one manual and about 1,600 lines of tests written from that same reading.
An adversarial review of the survey put it plainly, and it is the strongest
argument on the other side: our CPU is the least-evidenced component in a
repository that is unusually strict about evidence everywhere else.</p>

<h3>Why it still fails</h3>
<p>Four reasons, none of which is &ldquo;ours is smaller&rdquo;.</p>

<p><strong>Embedding destroys the validation.</strong> The diagnostics validate
the whole binary: they load through the card reader, run through the channel
code, and are compared against a checked-in log. <code>sim_instr</code> cannot
be lifted out of that &mdash; it calls <code>chan_proc()</code> from inside the
instruction loop and decrements the framework's own interval counter. Stub
those to build a library and the decks no longer run against what we shipped;
keep the binary whole and it is a subprocess, with a text round trip per
runtime call. So: embed it and lose the pedigree, or keep the pedigree and it
cannot be the production CPU.</p>

<p><strong>It forfeits the browser.</strong> <code>dart compile wasm</code>
rejects <code>dart:ffi</code> outright, and <code>dart:io</code>'s
<code>Process</code> is equally absent, so both shapes are dead in the browser.
<code>ci.yml:36</code> builds the web target on every push and
<code>pages.yml</code> deploys it. <code>cpu.dart</code> is not in the web
closure today, so nothing breaks now &mdash; but HANDOVER names the casualty:
&ldquo;Any later browser work inherits this finding, the M4 emulator most of
all.&rdquo; Adoption means keeping the Dart core anyway, as a second
implementation.</p>

<p><strong>It needs a second octal table.</strong> Codegen encodes through
<code>emulator/decode.dart</code>; 206 references reach it from
<code>procedure.dart</code> and <code>encode.dart</code>. That file's own
header refuses a duplicate in as many words: &ldquo;a second copy of it would
be a second authority for the octal codes the OCTAL column prints&rdquo;. A C
core carries its own table, on the far side of a language boundary, unverifiable
by our encode test &mdash; underneath the byte-exact listing reproduction that
makes this project's central claim credible.</p>

<p><strong>It imports the banned quadrant in bulk.</strong> Vendoring brings
roughly 160 instructions no COMTRAN program reaches plus channel-level I/O that
D0.7 exists to avoid, against section 11's rule on code that is neither
exercised nor tested.</p>

<h3>What I got wrong while you were watching</h3>
<p>Mid-search I told you the decisive fact was that the runtime library is
lost, so no third-party emulator can help. That is a non-sequitur, and the
adversarial review caught it. The roughly ninety Dart handlers are written from
J28-6169 whichever CPU executes the instructions between them, so the runtime
gap costs the same under every option. It is a zero on the ledger, not a mark
against the candidates. Every one of the ten profiles made the same error, and
the conclusion has to stand on the four reasons above instead.</p>
<p>Two other arguments in the research do not survive either, and I am not
resting on them. Line counts say nothing about which implementation reads the
manual correctly. And D0.3's locked status says who decides, not what is
better; citing it as evidence in an analysis commissioned to inform whether it
should be lifted is circular.</p>

<div class="ask">
<span class="label">What I need from you</span>
<p>Confirm that D0.3 stands and <code>lib/src/emulator/</code> stays ours. That
leaves <code>docs/opportunities.md:511</code> as it is, where your 2026-08-05
option is recorded and still awaiting your instruction.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>2 &middot; The 1963 Commercial Translator survives, with its runtime library</h2></div>

<p><strong>This is not what I went looking for.</strong> Dave Pitts distributes
<code>ibsys.tar.gz</code>, 9.8 MB, alongside his emulator. Its readme says the
contents &ldquo;were gleaned from the IBSYS tapes from Paul Pierce's web
site&rdquo; and lists fourteen subsystem directories. One of them is
<code>CT &mdash; Commercial Translator</code>.</p>

<p>I downloaded and read it rather than take the report on trust.
<code>CT/ct.job</code> is 66,684 lines of FAP source headed <code>709/7090
COMMERCIAL TRANSLATOR MONITOR (VERSION 5) 07/15/63</code>. Inside it,
after line 55,774, are forty decks each headed <code>7090 COMM. TRAN. (OBJECT
SUBROUTINE) VERSION 5 JULY 15, 1963</code>. They are the object-time subroutine
library &mdash; the SYS) and IOC) routines our generated code calls.</p>

{CT_PLATE}

<p><strong>And it is assembled, not source alone.</strong> The survey reported
that the octal column was empty for these decks. That is wrong for MOVPAK at
least: <code>ct.lst</code> carries location and instruction word.</p>

{LST_PLATE}

<p>3,351 lines in that region of the listing carry a location and an octal
instruction word. The forty decks are: IOBSMP, IOEXMP, CTMCOM, IBMAP, PRGINT,
UNITAS, INREAD, 2CELLS, EXPERR, EXPDBL, FPTRP, SYSADJ, SYSCOL, SYSCOM, SYSSXY,
SYSSDX, SYSDIV, SYSMPX, EXPSNG, OPEN1, OPEN2, CLOSE1, CLOSE2, STPPRT, MOVPAK,
NJJJNJ, MOVFLT, PATTRN, EOBERR, BCDBIN, BCDERR, GETVLM, UNXEOF, KAPUT, HOLBCD,
WRTEOB, BCDHOL, BLERR, TRAPEM and SRMOVE.</p>

<p><strong>The cell numbers are ours.</strong> Every SYS) cell our compiler
generates a call to appears in this source, with a routine name attached.</p>

{CELLS_PLATE}

<p>SYS)130 and SYS)131 matter most: they are the two MOVPAK communication cells
whose behaviour our decision records currently settle as our own choice rather
than as attested fact.</p>

<h3>What it would cost, honestly</h3>
<p>Three costs, and the first is the one that decides it.</p>

<p><strong>Reading it requires the emulator scope you fenced off.</strong> The
library is written for a whole 7090, not for our 43-opcode subset. Counted in
the object-subroutine region of the source: floating point (FAD 31 times, FMP
11, FDP 7, FSB 2, FRN 3), trapping and halts (TTR 8, TOV 3, ETM 2, LTM 2, HTR
1), and channel-level I/O (IORT 13, IOCP 10, TCH 9, IORP 3, IOCT 2, RDS 1).
Those are exactly the three families <code>docs/design/emulator.md</code>
section 8 puts out of scope, and channel I/O is what D0.7 exists to avoid. Two
dozen further ordinary instructions are outside the subset and heavily used:
TIX 151 times, XEC 109, STA 106, SXD 88, STZ 70, ZET 64, TZE 55, STL 43, LFT
42, XCL 41 and more. Running the real library means roughly doubling the
instruction set.</p>

<p>That collides head-on with your instruction of 2026-08-05, recorded at
<code>docs/opportunities.md:504</code>: <em>&ldquo;This project does not build
a historically accurate 7090 emulator, and no wording here may be read as
asking for one.&rdquo;</em></p>

<p><strong>It is Version 5 of July 1963, not the January 1962 processor we
reconstruct.</strong> J28-6169-1 documents the field-test compiler; this is
eighteen months later. The cell numbering agrees, which is strong, but no
routine body has been compared against J28-6169's documented contracts. I read
headers, the deck table and the cross-references; I read no routine's logic.</p>

<p><strong>The 1962/1963 gap cuts both ways.</strong> Where the two differ, our
target is the manual, and the record would have to say so every time.</p>

<h3>What it is worth anyway</h3>
<p>D0.3 already anticipates this exact event: &ldquo;Any routine is
individually replaceable by real 7090 code if authentic code ever surfaces; the
contracts and tests then validate the find.&rdquo; The find has surfaced. Even
if not one line is executed, the source answers questions our records currently
close by decision &mdash; SYS)130 and SYS)131 among them &mdash; and it is
period IBM evidence, which under section 9 outranks any reading of a manual we
could make on our own.</p>

<p><strong>It also contains the processor itself.</strong> The first version of
this record said so vaguely and admitted it had not looked. It has now looked.
<code>ct.job</code> is one IBSYS job of four steps.</p>

{SEGMENTS_PLATE}

<p>Segment 3 is 50,041 lines headed <code>7090 COMMERCIAL TRANSLATOR (CT)
VERSION V   JULY 15, 1963</code> at <code>ct.job:5683</code>, with origins for
a non-overlayed part, an overlayed part and a debug section
(<code>CTBORG</code>, <code>CTBOVL</code>, <code>CTBDBG</code> at
<code>:5686-5691</code>). It continues through lettered overlay phases &mdash;
CB, CC, CI and more &mdash; each repeating that header. That is the compiler
this project reconstructs, in assembler source. Across the whole listing,
26,409 lines carry a location and an octal instruction word.</p>

<p>I am not going to guess what that implies for the project, and this record
does not propose anything about it. It is reported because a later reader
must not have to rediscover it.</p>

<div class="opt pick">
<p class="name">Recommended &mdash; treat it as evidence, not as code</p>
<p>Do not execute it and do not widen the emulator. Read the forty decks as
period documentation of the runtime contracts, and cite them where they settle
something our records currently decide. Cost: reading time. Reversible at any
point. Leaves stage 4's plan untouched.</p>
</div>
<div class="opt">
<p class="name">Rejected for now &mdash; run the real library</p>
<p>Widen the CPU to roughly ninety opcodes including floating point, trapping
and channel I/O, then load the assembled routines instead of writing Dart
handlers. It contradicts your 2026-08-05 instruction, deletes the reason D0.7
exists, and binds us to a 1963 processor while our target is 1962. Reversing it
means rebuilding the handlers anyway.</p>
</div>
<div class="opt">
<p class="name">Rejected &mdash; ignore it</p>
<p>Cheapest, and it leaves a later reader misled: our records would keep
asserting as our own decision things a surviving period source settles.</p>
</div>

<div class="ask">
<span class="label">What I need from you</span>
<p>Two answers. First, should I open a proper evidence pass on
<code>CT/ct.job</code> &mdash; reading the forty decks against our handler
contracts and recording what they settle? Second, do you want the processor
source itself looked at, separately, or left alone for now? Neither blocks
stage 4.</p>
</div>
</section>

<section class="item needs">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>3 &middot; If we build a differential harness, where does it live?</h2></div>

<p>Rejecting adoption does not reject the second opinion. The cheap version is
to run the same instruction sequences through our core and through a mature
emulator, and treat every disagreement as a question to re-check against the
manual. Pitts' <code>s709</code> is the better reference: it enforces 7090 mode
at 27 instruction sites and halts on a 7094 instruction rather than executing
it silently, it is MIT-licensed naming both authors, and it builds with plain
<code>make</code>.</p>

<p>What it would discriminate is not what I expected. The corners marked as our
own interpretation are mostly the ones a differential test cannot settle:
ED-2's overflow gating and ED-2a's LGL trigger both concern an indicator no
generated code reads, and CVR is a parameter word a Dart handler consumes and
the CPU may never execute. What it would genuinely check is the arithmetic we
are already most confident about &mdash; the wide MPY and DVP intermediates,
subtractive indexing, the multiple-tag OR, shift counts past 36, and
minus-zero results.</p>

<p>Two guards are mandatory either way: set the model explicitly, because
running 7090 code on a 7094 model diverges silently rather than failing; and
filter our own out-of-subset exceptions before diffing, or the report is noise.</p>

<div class="opt pick">
<p class="name">Recommended &mdash; a checked-in tool, run on demand</p>
<p>The harness lives in <code>tool/</code>, pinned, run by a developer at each
subset widening, never in the CI gate. Section 11 permits it: a tool a
developer runs is exercised, and the table allows exercised-but-untested with
caution. Cost: it sits in the format and analyse gate forever, and it depends
on a locally built binary that nothing checks.</p>
</div>
<div class="opt">
<p class="name">Alternative &mdash; scratchpad only, run once</p>
<p>Nothing enters the repository at all. Cheaper and cleaner, and it decays to
zero the first time stage 4 widens the subset, which the design record says is
expected and additive.</p>
</div>
<div class="opt">
<p class="name">Alternative &mdash; do not build it</p>
<p>Defensible. M6 already carries a period end-to-end oracle, so the window
this harness covers is bounded. But M6 is two milestones away and the report
cannot isolate a single instruction's corner.</p>
</div>

<p>A caveat to state plainly, because it limits all three. A disagreement
proves only that two people read the same sentence differently; the page scan
decides, not the simulator. And agreement proves less than it feels like, since
two readers of the same ambiguous sentence can land in the same wrong place.
The reference's own known-bug list includes a minus-zero defect &mdash; in
floating point, outside our subset, but exactly the class of corner one would
run it to settle.</p>

<div class="ask">
<span class="label">What I need from you</span>
<p>Which of the three, if any. It is not urgent and nothing waits on it.</p>
</div>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>4 &middot; Two corrections and one observation</h2></div>

<p><strong>PDF p. 217 is not a plan gap.</strong> Three of the research agents
reported that the sample program's printed report output is an unnamed oracle,
and one called it the survey's best finding. It is already the M6 acceptance
criterion at <code>docs/HANDOVER.md:496</code>, named in the roadmap preamble
at <code>:442</code>, and cited as an oracle in three decision records. They
had read only the stage 4 scope, which covers I/O-free programs and so does not
reach a report. Nothing to change.</p>

<p><strong>The runtime-gap argument is struck</strong>, as item 1 records.</p>

<p><strong>LAS carries an unlabelled reading.</strong> Not a defect, and it
needs no change now.</p>

{LAS_PLATE}

<p>The comparison pairs the accumulator's P against the storage word's sign and
positions 1&ndash;35 against 1&ndash;35, which is the manual's own field
pairing at M p. 43, and lets Q outrank the whole word. That last consequence is
unrecorded: the design record states the semantics in one line at
<code>emulator.md:128</code> and no ED label covers the ordering. LAS appears
five times in the sample object program. It is a candidate for an ED entry
whenever that file is next touched, and it is exactly the kind of corner item 3
would settle.</p>
</section>

<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>How this was searched</h2></div>
<p>Four blind sweeps ran first, each given a different angle and told to
confirm every candidate by fetching its page: the SIMH family, code-hosting
sites, the historical-computing community, and academic and archival sources.
Twenty-one names came back, which deduplicated to six distinct projects. Ten
profiles then answered the same six questions per candidate; four profilers
built and ran their candidate, and one demonstrated the full
trap&ndash;read&ndash;write&ndash;resume cycle we would need. A separate agent
measured the embedding cost against this repository, including benchmarks and
an empirical check that <code>dart:ffi</code> cannot compile to wasm on our own
SDK. Two reviewers were then asked to attack the conclusion and make the
strongest case for adoption; both changed the reasoning and neither changed the
recommendation.</p>
<p>I verified the load-bearing claims myself rather than relying on the
reports, which is how the p. 217 error and the assembled-octal correction were
caught. <code>evidence/verification-notes.md</code> records each check.
The unedited agent output ships in <code>evidence/</code> so a later reader can
see what was claimed as well as what survived.</p>
</section>

<footer>
<p>This record was corrected once, on the day it was written and before it was
read; the banner at the top says what it said before.
Materials: <code>evidence/candidate-profiles.md</code> (ten profiles),
<code>evidence/embedding-cost.md</code>,
<code>evidence/oracle-option.md</code>,
<code>evidence/adversarial-review.md</code>,
<code>evidence/verification-notes.md</code> (my own checks),
<code>evidence/ct-tape-find.md</code> (the Commercial Translator excerpts),
<code>evidence/survey-raw.json</code>.
Repository links point at commit
<a href="{GH}">8251b4a</a>.</p>
</footer>

</main>
</body>
</html>
"""

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(HTML)
print(f"wrote {OUT} ({len(HTML)} bytes)")
