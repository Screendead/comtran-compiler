"""Assemble the M5 stage-3 review page.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: the four crops are embedded as `data:` URIs,
so the file renders from any location with no network and no server.

Every repository link is built from the one commit hash below, so the record
outlives the branch it was written beside. Set `RECORD_HEAD` in the environment
to build the links from another commit.
"""

import base64
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

RECORD_HEAD = os.environ.get("RECORD_HEAD", "b9e95a4")
GH = f"https://github.com/Screendead/comtran-compiler/blob/{RECORD_HEAD}"
STAGE2 = (
    "https://github.com/Screendead/comtran-compiler/tree/6492c9a/"
    "reviews/2026-09-12-m5s2-get-design"
)


def link(path, lines=None, text=None):
    """A repository link at RECORD_HEAD. `lines` is "346" or "165-174"."""
    fragment = ""
    if lines:
        first, _, last = lines.partition("-")
        fragment = f"#L{first}" + (f"-L{last}" if last else "")
    shown = text or (f"{path}:{lines}" if lines else path)
    return f'<a href="{GH}/{path}{fragment}"><code>{shown}</code></a>'


def quote(body, cite):
    """A block quotation and its citation line."""
    return f'<blockquote>{body}</blockquote>\n<p class="cite">{cite}</p>'


def plate(text):
    """A monospace plate, for a calling sequence or a listing excerpt."""
    return f'<div class="plate"><pre>{text}</pre></div>'


def crop(name):
    """The crop as a `data:` URI, so the page needs no second file."""
    with open(os.path.join(REC, "crops", name), "rb") as fh:
        return "data:image/png;base64," + base64.b64encode(fh.read()).decode("ascii")


def figure(name, alt, caption):
    """A crop, its alternative text and its caption."""
    return (
        "<figure>\n"
        f'<div class="scan"><img src="{crop(name)}" alt="{alt}"></div>\n'
        f"<figcaption>{caption}</figcaption>\n"
        "</figure>"
    )


# --- shared links ------------------------------------------------------

GENCODE = "comtran-manuals/J28-6169/90.02-generated-code.md"
COMPILER = "comtran-manuals/J28-6169/02-compiler.md"
SAMPLE = "comtran-manuals/J28-6169/90.05-sample-program.md"
CODE = "test/goldens/90.05-payroll.code"
LOADER_GOLD = "test/goldens/90.05-payroll.loader"
M5IO = "docs/design/m5-io.md"
DECISIONS = "docs/design/decisions.md"
IOCS = "lib/src/runtime/iocs.dart"
MACHINE = "lib/src/runtime/machine.dart"
COMTRANC = "bin/comtranc.dart"
BINDER = "lib/src/data/binder.dart"
DATAMSG = "lib/src/data/data_messages.dart"
SEVERITIES = "lib/src/lexer/severities.dart"
TAPE = "lib/src/runtime/tape.dart"
IOCS_TEST = "test/runtime/iocs_test.dart"
MACHINE_TEST = "test/runtime/machine_test.dart"
TAPE_TEST = "test/runtime/tape_test.dart"

# --- 1 -----------------------------------------------------------------

ITEM1 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>1 · IOC)9 is the IOCS WRITE routine</h2></div>

<h3>The evidence</h3>

<p>The manual names the entry in one line:</p>

{quote(
    "<p><strong>IOC)9</strong> The entry point to the IOCS WRITE subroutine.</p>",
    "J 90.02.08 (" + link(GENCODE, "342", "90.02-generated-code.md:342") + ")",
)}

<p>The manual prints the sequence in its card form, where a terminator names the
routine that reports a filing error on card equipment:</p>

{quote(
    plate("""TSX      IOC)9, 4
PZE      FILENAME, , SYS)291
IOCDN*   *+1, , 24""")
    + "<p>SYS)291 appears only in Write sequences to File a record on card"
    " equipment (Locating Mode). The routine, when entered, prints an error"
    " message and exits to the CT Monitor.</p>",
    "J 90.02.33 (" + link(GENCODE, "1857-1867", "90.02-generated-code.md:1857-1867") + ")",
)}

<p>The sample writes to tape, and its sequence is two parameter words with a
zero decrement in the first. The plain form files a record from a reserved area
({link(CODE, "167-169")}):</p>

{plate("""00273  TSX     IOC)9,4
00274  PZE     ERRORFILE,,0
00275  IOST    ERROROUT,,4""")}

<p>The located form patches the <code>IOST</code> word before the call
({link(CODE, "606-611")}):</p>

{plate("""01157  LXA     BL)2,4
01160  SXA     GN)089,4
01161  TSX     IOC)9,4
01162  PZE     OUTPUTMASTER,,0
01163  GN)089  IOST    MASTER,,15
01164  TRA     GET.MASTER""")}

<p>The published IOCS manual prints the sequence the COMTRAN one is built on.
Our two words are that sequence with one command in the list:</p>

{figure(
    "iocs-p16-write.png",
    "The IOCS WRITE calling sequence on a coding form: TSX WRITE,4 then "
    "PZE FILE,,EOB then IOXY A,,m, with the command list braced at the right.",
    "The WRITE calling sequence, cut from printed page 16 of C28-6100-2, PDF"
    " page 24. The form reads <code>TSX WRITE,4 / PZE FILE,,EOB / IOXY A,,m</code>."
    " Under it: “The command list must be terminated by an IOXT, IOCD, IOXTN or"
    " IOCDN command. The EOB switch functions exactly as described under READ.”"
    " The printed page number 16 stands at the foot. (external)",
)}

<p>The COMTRAN manual settles what a FILE does on a file that is not open:</p>

{quote(
    "<p>If a file has not been OPENed or has been CLOSEd when a FILE command is"
    " encountered at execution time, the command acts as a NOP. No error message is"
    " given.</p>",
    "J 02.07.08 §2b (" + link(COMPILER, "1629", "02-compiler.md:1629") + ")",
)}

<p>The sample's own blocking note settles the packing, and it is the sentence
D6.7 was built on:</p>

{figure(
    "j-90-05-04-payfile-blocking.png",
    "The Environment Description paragraph for the PAYFILE, describing "
    "BLOCKSIZE 20 and the shorter DEPARTMENT.TOTAL records.",
    "The PAYFILE Environment Description, cut from"
    " comtran-manuals/J28-6169/images/page-191.png, the scan of J 90.05.04. It"
    " reads: “The shorter records, DEPARTMENT.TOTAL, will be written with proper"
    " length, and will always begin a new buffer. If this short record was only 10"
    " words long, it would be necessary to specify BEGIN in the File Card to avoid"
    " grouping of the short records.” The transcription is at"
    f" {link(SAMPLE, '194-198', '90.05-sample-program.md:194-198')}.",
)}

<h3>The decision</h3>

<p>M5-9 ({link(M5IO, "397", "m5-io.md:397")}) gives IOC)9 two parameter words
and four rules, and the code is <code>_write</code>
({link(IOCS, "92-126", "iocs.dart:92-126")}). Word 1 names the file in its
address field and an end-of-buffer exit in its decrement. Word 2 is the
<code>IOST</code> word: the record's first address and its extent in words. The
rules run in this order.</p>

<ol>
<li>A file that is not open takes nothing. The entry resumes three words on and
writes nothing (J 02.07.08).</li>
<li>A record longer than the file's BLOCKSIZE ends the run with a fault that
names the file. No word of the sequence carries an exit for it: the decrement of
word 1 is zero at every tape site, and the card-file terminator SYS)291 has no
emitter. A compiled program can still reach this rule, because the compiler's
own diagnostic does not stop the job. See the paragraph below.</li>
<li>A block with fewer unused words than the extent is written to the tape
first, as one frame, and the block empties. That is D6.7.</li>
<li>The entry copies the extent's words from the <code>IOST</code> address into
the block and resumes three words on. A block filled exactly waits for the next
FILE or for the close.</li>
</ol>

<p>Index register 4 survives. Index registers 1 and 2 and the accumulator keep
what the program left in them. IOCS leaves a history word in the accumulator at
each WRITE exit (external: C28-6100-2, printed p. 17, the page in
<code>evidence/c28-6100-2-printed-p17.png</code>), and no compiled word reads
it, so section 11 bans writing it.</p>

<p><strong>Rule 2 is reachable, and that is why it exists.</strong> The compiler
does see the record: the binder compares each record's words against its file's
BLOCKSIZE and draws message 5,00, "RECORD LENGTH 24 OF 'NAME.2' EXCEEDS
'NAME.1' -BLOCKSIZE- 12. -FILE- CARD MUST HAVE -SPANS-."
({link(BINDER, "238-242", "binder.dart:238-242")};
{link(DATAMSG, "13-16", "data_messages.dart:13-16")}). That message carries
severity 4 ({link(SEVERITIES, "45", "severities.dart:45")}), and only severity 5
stops a job ({link("lib/src/lexer/diagnostic.dart", "68-71",
"diagnostic.dart:68-71")}). The deck is punched, the program runs, and the FILE
reaches IOC)9 with a record the block cannot hold. Message 209,
"'NAME.1' HAS INSUFFICIENT BLOCKSIZE. BLOCKSIZE USED IS", is a different
condition: an input card file whose BLOCKSIZE is under the 24-word minimum
({link(DATAMSG, "459-462", "data_messages.dart:459-462")}).</p>

<p>The order of rules 2 and 3 is load-bearing. Test the fit first and a record
longer than the whole block passes rule 3 on an empty block, because an empty
block has nothing to write out. The copy of rule 4 then runs past the buffer's
end and into the next file's buffer. The fault must come first.</p>

<p>The entry reads no base locator. For a located record the
<code>LXA</code>/<code>SXA</code> pair ahead of the call writes the base
locator's address over the zero the generator punched, so the CPU patches the
<code>IOST</code> word before the entry reads it (statement 208; M4-15).</p>

<h3>The rejected options and their costs</h3>

<div class="scroll">
<table>
<tr><th>Option</th><th>What breaks or misleads</th><th>Cost to reverse</th></tr>

<tr><td>Split a record across two blocks, as the IOCS end-of-buffer rule for a
zero switch says</td>
<td>Contradicts D6.7, which is locked, and J's own worked example. The
DEPARTMENT.TOTAL records would not "always begin a new buffer". The printed
report would differ from PDF page 217 wherever a block boundary fell inside a
record. Item 4 holds the evidence for the gap.</td>
<td>One branch in IOC)9, and a lister that joins the split halves.</td></tr>

<tr><td>Truncate a record that is too long, silently</td>
<td>The run prints a wrong report and says nothing. The oracle is the printed
report, so a silent truncation attacks the one thing M6 measures.</td>
<td>Nil to reverse, but the wrong report is the cost.</td></tr>

<tr><td>An IOCS-style error exit for the record that is too long</td>
<td>No word of the sequence carries a field for it. Inventing one changes the
attested object text, which the generator must keep byte for byte.</td>
<td>Remove the invented word, and regenerate the golden.</td></tr>

<tr><td>Read the base locator inside IOC)9 for a located record</td>
<td>Two paths for one address. The CPU already patches the <code>IOST</code>
word through the <code>LXA</code>/<code>SXA</code> pair, and a second path could
disagree with it.</td>
<td>Delete the read.</td></tr>
</table>
</div>

<h3>Cost to reverse</h3>

<p>Small. The four rules are one function,
{link(IOCS, "92-126", "iocs.dart:92-126")}. The tests pin each rule, and the
D6.7 oracle is J's own Example 1: records of 64, 128 and 192 words on a file of
BLOCKSIZE 256 ({link(IOCS_TEST, "385-431", "iocs_test.dart:385-431")}).</p>
</section>
"""

# --- 2 -----------------------------------------------------------------

ITEM2 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>2 · Every file takes one buffer above the program, and the close writes the
last block</h2></div>

<h3>The evidence</h3>

<p>Stage 2 put an input file's buffer above the program, on the row order of the
core chart of J 03.03.01. The
<a href="{STAGE2}">stage 2 record</a> holds that chart as its one crop, and this
record does not repeat it. Stage 2 also wrote its own exception, in M5-7: an
output file takes no buffer, because nothing read one before stage 3 (CLAUDE.md
section 11). Stage 3 is the reader, and M5-7 now carries the amendment that
lifts the exception ({link(M5IO, "309-310", "m5-io.md:309-310")}).</p>

<p>The sample's seven <code>*SPEC</code> cards give the seven block depths, and
every one of them carries the same close code:</p>

{plate("""*SPEC  01  300    N R
*SPEC  02  300    N R
*SPEC  03    3    N R
*SPEC  04   20    N R
*SPEC  05   20    N R
*SPEC  06    6    N R
*SPEC  07    6    N R""")}

<p class="cite">{link(LOADER_GOLD, "3-15", "90.05-payroll.loader:3-15")}</p>

<p>Those depths sum to 655 words. The program's last placed word is relative
01771, absolute 5113, so the buffers run from 5114 to 5768.</p>

<h3>The decision</h3>

<p>M5-10 ({link(M5IO, "456", "m5-io.md:456")}): every file takes BLOCKSIZE words
above the program's extent, in <code>*FILE</code> card order. The allocator is
<code>_fileTable</code> ({link(MACHINE, "205-232", "machine.dart:205-232")}),
and the two load refusals of stage 2, a file with no BLOCKSIZE and a set of
buffers that runs past core, now cover every file. DETAILFILE's buffer moves
from 5414 to 5714, because OUTPUTMASTER's 300 words now stand between. The seven
addresses are asserted at
{link(MACHINE_TEST, "210-219", "machine_test.dart:210-219")}.</p>

<p>An output file's block is the first words of its buffer, as many as the FILEs
since the last write put there. IOC)9 writes a full block, and close-all writes
the block a file still holds and then the tape mark
({link(MACHINE, "384-399", "machine.dart:384-399")}). An empty block writes
nothing, at IOC)9 and at the close: a frame of zero length is a tape mark by
M5-2, and a file must not hold one. The second close-all that the sample's STOP
RUN emits finds every file closed and does nothing.</p>

<p>With no host image the block still fills and every write is dropped, so a run
that names no <code>--tapes</code> directory and declares no input file behaves
as it did at stage 1: each file opens, closes, and writes nothing.</p>

<p>The frame is the encoding M5-2 fixed: a four-byte little-endian length, six
bytes a word with the most significant six bits first, and the length again. The
test support has built that frame since stage 1. The library now owns the one
encoder, <code>tapeRecord</code>
({link(TAPE, "34-38", "tape.dart:34-38")}); one test pins its bytes, and the
support calls it.</p>

<h3>The rejected options and their costs</h3>

<div class="scroll">
<table>
<tr><th>Option</th><th>What breaks or misleads</th><th>Cost to reverse</th></tr>

<tr><td>Hold an output block in Dart, outside core</td>
<td>No compiled word reads an output buffer, so the emulation could hold the
block outside core and nothing would observe it. It makes two rules where one
serves, and it departs from the J 03.03.01 chart that stage 2 rested the
placement on.</td>
<td>Small. Nothing observable changes.</td></tr>

<tr><td>A fixed area per file below the program, or the top of core</td>
<td>Below the program contradicts the J 03.03.01 order, and the top of core has
no evidence at all. Stage 2 rejected both for those reasons, and reversing one
of them now would split the input and output rules.</td>
<td>One constant.</td></tr>

<tr><td>Keep the input-only rule and add a separate allocator for output
buffers</td>
<td>Two allocators for one idea, and two places for the load refusals to
disagree.</td>
<td>Delete one allocator.</td></tr>
</table>
</div>

<h3>Cost to reverse</h3>

<p>One conditional in <code>_fileTable</code> and the address assertions in
{link(MACHINE_TEST, "210-219", "machine_test.dart:210-219")}.</p>
</section>
"""

# --- 3 -----------------------------------------------------------------

ITEM3 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>3 · The lister prints a BCD tape as the 1962 printer did</h2></div>

<h3>The evidence</h3>

<p>The four report files are BCD tapes listed off line, and PDF page 217 is the
artifact M6 diffs. The CHECKFILE part of that page shows what the printer put on
paper:</p>

{figure(
    "j-90-05-report-checkfile.png",
    "The CHECKFILE report on page 217: three checks, each of two lines "
    "beginning with the digits 1 and 2, with the employee number and amount "
    "printed on the position above.",
    "The CHECKFILE report, cut from"
    " comtran-manuals/J28-6169/images/page-217.png. Each check prints as two"
    " lines, <code>110-06-61</code> and <code>2WILLIAMS P</code>. The"
    " <code>1</code> and the <code>2</code> in column 1 are the carriage-control"
    " characters that words 1 and 8 of the CHECK record carry. The"
    " <code>091977</code> and <code>$294.12</code> at the right print on the"
    " position above their check, which is the 1962 printer's practice, not the"
    " record's shape. The <code>12</code>, <code>11</code> and <code>10</code> at"
    " the left edge are the page's margin sequence marks, which the conversion"
    " notes call print-form artifacts.",
)}

<p>The record description says where those two characters come from:</p>

{quote(
    "<p>Word 1 — carriage control character; 2 characters for MONTH; a dash; 2"
    " characters for DAY</p>"
    "<p>Word 8 — last 3 characters of EMPLOYEE.NUMBER; record mark; carriage"
    " control character; first character of NAME</p>",
    "J 90.05.03 (" + link(SAMPLE, "146-153", "90.05-sample-program.md:146-153") + ")",
)}

{quote(
    "<p>The two check lines are grouped in one record, separated by a record mark"
    " (signalled by type RCDMRK) for printer control.</p>",
    "J 90.05.03 (" + link(SAMPLE, "140-142", "90.05-sample-program.md:140-142") + ")",
)}

<p>D6.4 already fixed the shape of a print record and drew the line the lister
must not cross:</p>

{quote(
    "<p>One record is one <em>or more</em> print lines. RCDMRK-type one-character"
    " record marks delimit the lines inside a record. […] Line length and carriage"
    " behavior beyond that come from the emulator's printer device, not from the"
    " language.</p>",
    "D6.4 (" + link(DECISIONS, "985", "decisions.md:985") + ")",
)}

<h3>What would mislead a later reader</h3>

<p>The crop shows <code>091977</code> and <code>$294.12</code> higher on the
page than the check they belong to, which looks like a second line inside the
record. It is not. The conversion note on the report page says so:</p>

{quote(
    "<p>figures are reproduced exactly as printed, including the printer's"
    " practice of carrying the last few amount fields of a detail or totals line on"
    " the print position immediately above the identifying line.</p>",
    "J 90.05 report output ("
    + link(SAMPLE, "1877", "90.05-sample-program.md:1877")
    + "; the CHECKFILE lines are at "
    + link(SAMPLE, "1909-1913", "90.05-sample-program.md:1909-1913")
    + ")",
)}

<p>The stagger is the 1962 printer's. The lister prints the record's line as one
line, and M6 decides how to diff the stagger.</p>

<h3>The decision</h3>

<p>M5-11 ({link(M5IO, "492", "m5-io.md:492")}) gives the lister these rules. One
block is one print line. A record mark, BCD code octal 72, ends a line and is
not printed. Every other character prints, the carriage-control character in
column 1 included. Trailing blanks are trimmed. A code with no Set H glyph
prints <code>?</code>. The list runs from the tape's first frame to its file
mark, and an image with no mark lists every whole frame it holds before the
reader's fault ends the list, which is why the lister yields its lines one at a
time. A file whose <code>*FILE</code> card punches mode <code>B</code>, binary,
is not listed. <code>comtranc --run --list-tapes</code> then prints, after the
run's display lines, each output file in <code>*FILE</code> card order under a
heading of the file's name and the word <code>REPORT</code>, with one blank line
between two files. The flag needs <code>--run</code> and <code>--tapes</code>.</p>

<p>The rules that turn bytes into lines are <code>listTape</code>
({link(TAPE, "51-71", "tape.dart:51-71")}), pinned by four tests
({link(TAPE_TEST, "130-175", "tape_test.dart:130-175")}) and used by the
sample's own run test ({link(MACHINE_TEST, "124-125",
"machine_test.dart:124-125")}). The rules that choose what to print are
<code>_listTapes</code> ({link(COMTRANC, "408-435", "comtranc.dart:408-435")}),
which the driver calls after the display lines and also after a run fault, so a
crashed run still shows what it wrote.</p>

<p><strong>The lister prints only a file this run opened.</strong> Open-all
validates every file before it truncates any image
({link(MACHINE, "330-377", "machine.dart:330-377")}), so a refused run leaves
the previous run's tapes on disk untouched. Printing those under this job's
headings would hand M6 a report the run never produced. The adversarial review
found that case. The fix is one field on the file's control block,
<code>opened</code>, which stays true after the close
({link(MACHINE, "181-184", "machine.dart:181-184")}), and the test reproduces
the stale-tape run by deleting <code>C2.tap</code> between two runs
({link(MACHINE_TEST, "320-333", "machine_test.dart:320-333")}).</p>

<h3>The rejected options and their costs</h3>

<div class="scroll">
<table>
<tr><th>Option</th><th>What breaks or misleads</th><th>Cost to reverse</th></tr>

<tr><td>Consume column 1 as carriage control and emulate the skips</td>
<td>Fails the diff against page 217, which printed the characters as text. It
also adds a printer model that D6.4 assigns to the emulator's device, and the
sample assigns no PRX or OU unit for one.</td>
<td>One flag on the lister.</td></tr>

<tr><td>Keep the trailing blanks</td>
<td>They are invisible on paper and they make every diff noisy.</td>
<td>Remove one trim.</td></tr>

<tr><td>A separate executable, or a <code>deckconv</code> subcommand</td>
<td>A new binary and a pubspec entry for one function. <code>deckconv</code> is
the card-deck tool, and a tape lister inside it misleads about what it
reads.</td>
<td>Move one call.</td></tr>

<tr><td>Throw on an image with no file mark, and list nothing</td>
<td>Loses the lines a crashed run did write, which are the lines a debugging
reader wants most.</td>
<td>One branch.</td></tr>
</table>
</div>

<h3>Cost to reverse</h3>

<p>The lister is one generator function, the tool's printer is one loop, and
both carry tests.</p>
</section>
"""

# --- 4 -----------------------------------------------------------------

ITEM4 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>4 · The end-of-buffer gap, and why it is not a collision</h2></div>

<h3>The evidence</h3>

<p>Every FILE site of the sample passes an end-of-buffer exit of zero, which the
plate in item 1 shows as <code>PZE ERRORFILE,,0</code>. The published IOCS
manual says what a zero switch means:</p>

{figure(
    "iocs-p16-eob.png",
    "Three numbered rules from the IOCS manual: the EOF exit, the ERR exit, "
    "and the end of buffer switch with its two cases a and b.",
    "The three rules of the READ discussion, cut from printed page 16 of"
    " C28-6100-2, PDF page 24. Rule 3a reads: “If EOB = 0, truncation of the"
    " buffer and automatic transition to the next one occur; command execution"
    " continues without interruption.” The WRITE section lower on the same page"
    " says the switch “functions exactly as described under READ”. (external)",
)}

<p>Under that sentence, IOCS proper would split a record across two blocks. Two
COMTRAN sources say it does not. D6.7 keeps a record complete within one block
and cites J's own Example 1, where block J+1 holds REC1 and REC2 only, 192 words
of 256, because REC3 does not fit
({link(DECISIONS, "1028", "decisions.md:1028")}). J 90.05.04 says the sample's
shorter records "will always begin a new buffer", which is the crop in item
1.</p>

<h3>Why this is an open item and not a peer collision</h3>

<p>CLAUDE.md section 9 settles it. External period evidence is admissible for
what the manuals delegate, and J does not delegate its own blocking: Example 1
states it, and J 90.05.04 states it again for the sample. What J 90.02.08
delegates is narrower, and it says so in one line: "A knowledge of the 7090 IOCS
is necessary in understanding most of the IOC Numbers". The end-of-buffer
sentence is therefore evidence about IOCS, not about what a COMTRAN FILE does,
and no rank of section 6 has to be invoked. There is nothing for Jack to
settle.</p>

<p>How the 1963 IOC)9 reconciled the two is inside the sealed archive of D0.9,
and the seal ends when M7 opens. The record therefore says that evidence exists
and is sealed, rather than that no evidence survives. M5-9 carries the gap in
those words ({link(M5IO, "447-454", "m5-io.md:447-454")}), and D6.7's amendment
line points at it ({link(DECISIONS, "1036", "decisions.md:1036")}).</p>

<p>Nothing to decide. The item is here because a later reader who reads the IOCS
manual will find the contradiction, and the record must show that we found it
first.</p>
</section>
"""

# --- 5 -----------------------------------------------------------------

ITEM5 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>5 · What stage 3 does not build, the folded advisories, and the delivery
plan</h2></div>

<h3>Not built, under CLAUDE.md section 11</h3>

<div class="scroll">
<table>
<tr><th>Feature</th><th>Why it waits</th></tr>

<tr><td>BEGIN, the option that starts a record on a new block</td>
<td>No <code>*FILE</code> card of the sample carries it, so no rule would read
it. It lands with the program that punches it.</td></tr>

<tr><td>SPANS, for a record longer than a block</td>
<td>Open Question 48, and D6.7 puts it outside this stage. The record that is
too long ends the run instead.</td></tr>

<tr><td>SYS)291, the card-file terminator</td>
<td>It appears "only in Write sequences to File a record on card equipment"
({link(GENCODE, "1857-1867", "90.02-generated-code.md:1857-1867")}), and the
generator emits none. SYS)296 is not a second terminator, a correction the
adversarial review made: it is "a pointer word within subroutine SYS)292 which
locates the buffer to be used in the BCD to hollerith conversion"
({link(GENCODE, "1889-1901", "90.02-generated-code.md:1889-1901")}).</td></tr>

<tr><td>Direct printer output under D6.4</td>
<td>The sample assigns no PRX or OU unit, so no run reaches the path.</td></tr>

<tr><td>The close dispositions of D6.3</td>
<td>Every <code>*SPEC</code> card of the sample punches the same closing
convention, <code>R</code> in column 27, rewind
({link(LOADER_GOLD, "3-15", "90.05-payroll.loader:3-15")}; the <code>N</code> in
column 25 is the opening convention, J 90.08.02). No other close code has a
site.</td></tr>

<tr><td>A new diagnostic text</td>
<td>None. The record that is too long ends the run as a
<code>RunFault</code>, like the stage 1 and stage 2 refusals
({link(MACHINE, "144-159", "machine.dart:144-159")}), not as a 90.04
diagnostic.</td></tr>
</table>
</div>

<h3>The five advisories Cowork left on pull request 130</h3>

<div class="scroll">
<table>
<tr><th>Advisory</th><th>State at {RECORD_HEAD}</th></tr>

<tr><td>Re-measure the test baseline in HANDOVER</td>
<td>Done. The file reads 1298 Dart tests, measured 2026-09-13
({link("docs/HANDOVER.md", "72-74", "HANDOVER.md:72-74")}).</td></tr>

<tr><td>Reword "ordinal" for the block number in M5-8, and the two metaphors at
the end of M5-7</td>
<td>Done. M5-8 now says "The block number counts the frames the file reads after
its open" ({link(M5IO, "381-382", "m5-io.md:381-382")}), and M5-7's rejected
placements now read "transmit mode with locate mode's addresses" and "The
printed report would not show the difference"
({link(M5IO, "301-307", "m5-io.md:301-307")}).</td></tr>

<tr><td>The <code>Machine</code> constructor's doc comment on a run with no
tapes directory</td>
<td>Done. It now holds for an output file only
({link(MACHINE, "259-262", "machine.dart:259-262")}).</td></tr>

<tr><td>M5-8 should say that the run ends after the error exit</td>
<td>Done: "After the error exit the run ends, so the reader's position inside
the bad frame is never read again"
({link(M5IO, "386-387", "m5-io.md:386-387")}).</td></tr>

<tr><td>The comment in <code>machine_test.dart</code> cites the wrong
statement</td>
<td>Done. It cites statement 196
({link(MACHINE_TEST, "234", "machine_test.dart:234")}, and the same number at
{link(MACHINE_TEST, "108", "machine_test.dart:108")}).</td></tr>
</table>
</div>

<h3>The delivery plan</h3>

<p>One pull request, on branch <code>m5s3-file</code>, whose head is
{RECORD_HEAD}. It changes files under <code>lib/</code>, so it merges on
external-review convergence under the charter, not on a single review. Opening
it is under Jack's standing authorization of 2026-08-16. The doc-comment and
wording changes above ride in the same pull request, so the loop sees them
too.</p>

<p>The branch lands 869 insertions and 175 deletions across fifteen files: the
state lines of CLAUDE.md and HANDOVER, three design records, the compiler
driver, five files under <code>lib/</code>, and four under <code>test/</code>.
Nothing under <code>test/goldens/</code> changes, because a change there would
mean the generator moved, which this stage must not do.</p>
</section>
"""

# --- the page ----------------------------------------------------------

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
       padding:.08em .3em; border-radius:2px; overflow-wrap:anywhere; }
.eyebrow { font-family:var(--mono); font-size:.7rem; letter-spacing:.16em;
           text-transform:uppercase; color:var(--muted); margin:0 0 .7rem; }
header { border-bottom:2px solid var(--ink); padding-bottom:1.4rem; }
section { display:flex; flex-direction:column; gap:.2rem; }
.answer { background:var(--raised); border:1px solid var(--hair);
          border-left:3px solid var(--ink); padding:1.15rem 1.3rem; }
.answer ol { margin:0 0 .85rem; padding-left:1.2rem; }
.answer li { margin-bottom:.5rem; }
.answer p:last-child { margin-bottom:0; }
.note { color:var(--muted); font-size:.92rem; margin:0; }
.chip { font-family:var(--mono); font-size:.66rem; letter-spacing:.14em;
        text-transform:uppercase; padding:.24em .6em; border-radius:2px;
        border:1px solid currentColor; white-space:nowrap; }
.chip.decided { color:var(--stamp); background:var(--stamp-soft); }
.chip.done { color:var(--settled); }
.chip.call { color:var(--stamp); background:var(--stamp-soft); }
.itemhead { display:flex; gap:.75rem; align-items:baseline; flex-wrap:wrap;
            margin-bottom:.35rem; }
.item { border-top:1px solid var(--rule); padding-top:1.3rem; }
.item.needs { border-top:2px solid var(--stamp); }
blockquote { margin:.2rem 0 .2rem; border-left:3px solid var(--rule);
             padding:.1rem 0 .1rem 1rem; }
blockquote p { margin:0 0 .6rem; }
blockquote p:last-child { margin:0; }
blockquote .plate { margin:0 0 .6rem; }
p.cite { font-family:var(--mono); font-size:.71rem; line-height:1.5;
         color:var(--muted); margin:.4rem 0 1rem 1rem; }
p.cite code { background:none; padding:0; }
figure { margin:1rem 0 1.2rem; }
.plate { background:var(--raised); border:1px solid var(--rule); padding:.55rem;
         overflow-x:auto; }
.plate pre { margin:0; font-family:var(--mono); font-size:.78rem; line-height:1.5; }
.scan { background:#fff; border:1px solid var(--rule); padding:.55rem; }
img { max-width:100%; height:auto; }
.scan img { display:block; margin:0 auto; }
figcaption { font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
             margin-top:.5rem; }
.scroll { overflow-x:auto; margin:.5rem 0 1rem; }
table { border-collapse:collapse; font-size:.92rem; margin:.6rem 0 1rem;
       font-variant-numeric:tabular-nums; }
th, td { text-align:left; padding:.3rem .7rem .3rem 0; vertical-align:top;
        border-bottom:1px solid var(--hair); }
th { font-family:var(--mono); font-size:.7rem; letter-spacing:.1em;
    text-transform:uppercase; color:var(--muted); font-weight:normal; }
.opt { border-left:3px solid var(--rule); padding:.15rem 0 .15rem 1rem; margin:0 0 1rem; }
.opt.pick { border-left-color:var(--stamp); }
.opt .name { font-family:var(--mono); font-size:.75rem; letter-spacing:.08em;
             text-transform:uppercase; }
.ask { background:var(--stamp-soft); border:1px solid var(--stamp); padding:.9rem 1.1rem;
       margin:.9rem 0 0; }
.ask p { margin:0 0 .5rem; }
.ask p:last-child { margin:0; }
.ask .label { font-family:var(--mono); font-size:.68rem; letter-spacing:.14em;
              text-transform:uppercase; color:var(--stamp); display:block; margin-bottom:.3rem; }
footer { border-top:1px solid var(--rule); padding-top:1rem; font-size:.85rem;
         color:var(--muted); }
"""

HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>M5 stage 3, FILE: the design and the delivery plan</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<p class="eyebrow">Review record · M5 stage 3, FILE · evidence 2026-09-13 · head {RECORD_HEAD}</p>
<h1>M5 stage 3, FILE: the design and the delivery plan</h1>
</header>

<section class="answer">
<h2>The answer</h2>
<ol>
<li><strong>DECIDED.</strong> IOC)9 is the IOCS WRITE routine word for word: two
parameter words, a file that is not open takes a NOP, a record that does not fit
the block writes the block first, and a record longer than BLOCKSIZE ends the
run with a fault.</li>
<li><strong>DECIDED.</strong> Every file now takes one BLOCKSIZE buffer above
the program, in <code>*FILE</code> card order. Close-all writes the block a file
still holds, then the tape mark.</li>
<li><strong>DECIDED.</strong> The lister prints a BCD tape as the 1962 off-line
printer did: one block a line, a record mark splits a line, the carriage-control
character prints, and trailing blanks are trimmed.
<code>comtranc --run --list-tapes</code> prints each BCD output file under a
<code>NAME REPORT</code> heading.</li>
<li><strong>SETTLED.</strong> The sample's FILE sequence passes an end-of-buffer
switch of zero, which under the published IOCS manual would split a record. J's
own worked example keeps records whole. Recorded as sealed until M7, not raised
as a collision.</li>
<li><strong>SETTLED.</strong> What stage 3 does not build, which is BEGIN,
SPANS, the card-file terminator SYS)291 and direct printer output; the five
Cowork advisories from pull request 130 folded in; and the delivery plan, one
pull request on <code>m5s3-file</code>, merging on external-review
convergence.</li>
</ol>
<p>No item waits for Jack. Every one is DECIDED or SETTLED, so silence lets each
stand, and he can overturn any one of them.</p>
<p><strong>Provenance.</strong> The design entries were written first, as M5-9
to M5-11 of <code>m5-io.md</code> and the 2026-09-13 amendment lines of D6.4 and
D6.7. A worker then implemented the code against them, and this record was built
from both, in one autonomous run while Jack slept. No review document existed
before the code. That is the route CLAUDE.md section 12 opens for a decision
with one viable option, and this document is the explanation of decisions made,
not a question.</p>
</section>

<section>
<p class="note"><strong>Citation forms:</strong> <code>J 02.07.08</code> is the
1962 processor manual by IBM section code. <code>F p. 40</code> is the 1960
manual by printed page. <code>(external: C28-6100-2, printed p. N)</code> is the
published 7090 IOCS manual, the source J delegates the I/O system to;
<code>evidence/</code> holds the two pages this record cites.
<code>D6.7</code> is a decision record. <code>M5-9</code>, <code>M4-15</code>
and <code>RT-1</code> are design-record entries. <code>LOC 01161</code> is an
object location in the 1962 listing.</p>
</section>
{ITEM1}{ITEM2}{ITEM3}{ITEM4}{ITEM5}
<footer>
<p>Record built 2026-09-13 on branch
<code>review/2026-09-13-m5s3-file-design</code>. Every repository link above
points at commit {RECORD_HEAD}, a commit on branch <code>m5s3-file</code>, never
at a branch name. <code>tools/build_doc.py</code> writes this page; edit it, not
the HTML. Set <code>RECORD_HEAD</code> in the environment to build the links
from another commit. <code>crops/</code> holds the four images the page embeds,
and <code>evidence/</code> holds the two IOCS manual pages and the content brief
the record was built from. <code>evidence/README.md</code> says what each one
is.</p>
</footer>

</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
