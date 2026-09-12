"""Assemble the M5 stage-2 review page.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: the one crop is embedded as a `data:` URI, so
the file renders from any location with no network and no server.

Every repository link is built from the one commit hash below, so the record
outlives the branch it was written beside. Set `RECORD_HEAD` in the environment
to build the links from another commit.
"""

import base64
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

RECORD_HEAD = os.environ.get("RECORD_HEAD", "aebcc3b")
GH = f"https://github.com/Screendead/comtran-compiler/blob/{RECORD_HEAD}"


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


# --- shared links ------------------------------------------------------

GENCODE = "comtran-manuals/J28-6169/90.02-generated-code.md"
COMPILER = "comtran-manuals/J28-6169/02-compiler.md"
LOADER_MD = "comtran-manuals/J28-6169/03-loader.md"
SAMPLE = "comtran-manuals/J28-6169/90.05-sample-program.md"
CODE = "test/goldens/90.05-payroll.code"
LOADER = "lib/src/loader/loader.dart"
MACHINE = "lib/src/runtime/machine.dart"
SUPPORT = "test/runtime/runtime_support.dart"
MACHINE_TEST = "test/runtime/machine_test.dart"

# --- 1 -----------------------------------------------------------------

ITEM1 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>1 · IOC)8 is the IOCS READ routine</h2></div>

<h3>The evidence</h3>

<p>The manual names the entry in one line:</p>

{quote(
    "<p><strong>IOC)8</strong> The entry point to the IOCS READ subroutine.</p>",
    "J 90.02.08 (" + link(GENCODE, "346") + ")",
)}

<p>The manual gives the calling sequence and says what the routine does to the
base locator:</p>

{quote(
    plate("""TSX      IOC)8,4
PZE      FILENAME,,SYS)260
PZE      END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE
IOCDN*   BL)2,,14""")
    + "<p>This sequence of instructions fills in the cell BL)2 with the location"
    " of the first word of a 14 word record which is in an input buffer.</p>",
    "J 90.02.04 (" + link(GENCODE, "165-174") + ")",
)}

<p>The IOCS manual gives the READ sequence the COMTRAN one is built on, word for
word:</p>

{quote(
    plate("""        TSX     READ,4
        PZE     FILE,,EOB
        PZE     EOF,,ERR
        IOXY    A,,m""")
    + "<p>where FILE is the file designation, EOB is the end of buffer switch,"
    " EOF is the end of file exit, and ERR is the error exit. The command list is"
    " terminated by the first IOXT, IOCD, IOXTN or IOCDN command encountered.</p>",
    "(external: C28-6100-2, PDF p. 23 / printed p. 15)",
)}

{quote(
    "<p>IOCS determines whether a non-transmitting command is intended to locate"
    " or to skip information, in accordance with the end of buffer (EOB) switch"
    " specified in the calling sequence for READ and WRITE. If EOB = 0, the command"
    " is interpreted as a skip, and if EOB ≠ 0, it is interpreted as an attempt to"
    " locate information.</p>",
    "(external: C28-6100-2, PDF p. 21 / printed p. 13)",
)}

{quote(
    "<p>If the command is non-transmitting, the system supplies the location of"
    " the next available word in the buffer. Normally, the location replaces the"
    " address of the command. However, if the non-transmitting command is"
    " indirectly addressed, the location of the next available word replaces the"
    " address of the cell specified in the address of the IOCS command.</p>",
    "(external: C28-6100-2, PDF p. 19 / printed p. 11)",
)}

<p>The three correspondences follow. SYS)260 in the decrement of word 2 is the
EOB switch. It is not zero, so the call locates. The AT END label and SYS)283 in
word 3 are EOF and ERR. <code>IOCTN* BL)n,,len</code> is one indirect
count-control command that terminates the list, so the normal return is the word
after it. That is <code>resume(4)</code>, which M5-5 already fixes.</p>

<p>The two terminators are described, and neither message text is printed
anywhere:</p>

{quote(
    "<p>The SYS)260 subroutine prints an error message indicating processing"
    " terminated due to record length error.</p>",
    "J 90.02.28 (" + link(GENCODE, "1588", "90.02-generated-code.md:1588") + ")",
)}

{quote(
    "<p>Record length errors (referred to as EOB errors in the IOCS manual)"
    " generally arise when information in a block does not conform with the"
    " blocking conventions described by the programmer in the Environment"
    " Description. […] Record length errors are totally unrecoverable by IOCS or"
    " the programmer and cause immediate termination of object program execution."
    " An error message is given on the on-line printer.</p>",
    "J 02.07.06 (" + link(COMPILER, "1587-1591") + ")",
)}

{quote(
    "<p>SYS)283 prints a message concerning the GET error and exits to the CT"
    " Monitor.</p>",
    "J 90.02.32 (" + link(GENCODE, "1827", "90.02-generated-code.md:1827") + ")",
)}

<p>The sample has four GET sites, three on INPUTMASTER and one on DETAILFILE.
All four have this shape ({link(CODE, "108-112")}):</p>

{plate("""00200  TSX     IOC)8,4
00201  PZE     INPUTMASTER,,SYS)260
00202  PZE     GN)058,,SYS)283
00203  IOCTN*  BL)2,,15
00204  TRA     GN)059""")}

<p>The base locator cells start at zero and the program reads them three ways
({link(CODE, "898-907")}; the sites are in the evidence file
<a href="evidence/s2-runtime-codegen.md"><code>s2-runtime-codegen.md</code></a>,
section 6):</p>

<ul>
<li><code>LAC BL)2,1</code> loads the two's complement of the address into an
index register.</li>
<li><code>CAL BL)2 / ACL CP)+45 / SLW SYS)133</code> adds the whole word to a
pool word and stores it as a MOVPAK byte pointer.</li>
<li><code>LXA BL)2,4 / SXA GN)089,4</code> patches the IOST word of
<code>FILE MASTER</code> (LOC 01157).</li>
</ul>

<p>The second way binds the shape of the word the handler writes:</p>

{quote(
    "<p>The form of a Base Locator word is: <code>PZE LOC,,BYTE</code> where LOC"
    " is the word address of the first word of the data organization, and BYTE is"
    " the position in that word (0-5) of the first data item. By definition, a"
    " 'simple' Base Locator is one with BYTE always 0. Input records are located by"
    " 'simple' Base Locators.</p>",
    "J 90.02.05 (" + link(GENCODE, "209-215", "90.02-generated-code.md:209-215") + ")",
)}

<h3>The decision</h3>

<ul>
<li>The handler at address 8 reads its three parameter words through index
register 4, as every entry does (RT-1). Word 1: the file ordinal is its address
field less 2048 (LD-3). Word 2: its address field is the AT END exit. Word 3: its
address field is the base locator cell and its decrement the record extent in
words.</li>
<li>On a normal return the handler writes the record's address into the address
field of the cell. Prefix, tag and decrement stay zero. Then it resumes four
words on.</li>
<li>On AT END the handler sets the instruction counter to the address field of
word 2. It writes nothing.</li>
<li>SYS)260 and SYS)283 are two handlers of one shape: one display line, then
the <code>errorExit</code> outcome, as SYS)294 does today
({link("lib/src/runtime/monitor.dart", "62-69")}).</li>
<li>Index register 4 survives every exit. The statement stamp
<code>TXH CP)+a,0,CP)+b</code> sits two words before the link on every site
(M4-14), and a terminator that names the statement would read it from there.
Index registers 1 and 2 and the accumulator are not written. IOCS leaves a
history word in the accumulator; no compiled word reads it, so section 11 bans
writing it.</li>
<li>The message texts are ours. No manual prints one; <code>J 05.06.04</code>
only says they go to the on-line printer. The texts follow SYS)294's line, name
the file from word 1, and add the block ordinal on the tape:
<ul>
<li>SYS)260: <code>RECORD LENGTH ERROR ON INPUTMASTER, BLOCK 3</code></li>
<li>SYS)283: <code>GET ERROR ON INPUTMASTER, BLOCK 3</code></li>
</ul>
</li>
</ul>

<h3>What a later reader must not be misled about</h3>

<p>The IOCS manual never uses the words "locate mode" (external: C28-6100-2,
whole text; the evidence file
<a href="evidence/s2-iocs-read.md"><code>s2-iocs-read.md</code></a>, section 1).
It has transmitting and non-transmitting commands, and the EOB switch selects
between skip and locate. The COMTRAN manual coined "locate mode" over that
mechanism (<code>J 02.07.02</code>). Our handler implements the mechanism and
uses the COMTRAN name.</p>

<h3>Cost to reverse</h3>

<p>Small. The handler is about forty lines and touches no compiled word.</p>
</section>
"""

# --- 2 -----------------------------------------------------------------

ITEM2 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>2 · One buffer per input file, above the program</h2></div>

<h3>The evidence</h3>

<p>The object program reserves no buffer and no file block. The storage map
prints no area for the two input records
({link("test/fixtures/90.05-storage-section.tsv", "23")}: "MASTER and DETAIL are
located records and print no area"). The only I/O cells the compiler allocates
are the three <code>BL)</code> words at relative 01666 to 01670
({link(CODE, "898-907")}). The manual says who reserves the buffers:</p>

{quote(
    "<p>The Loader reserves a portion of core storage for use by the I/O system"
    " as operating storage. This storage area is subdivided into buffers into which"
    " all input blocks of data are read and from which all output blocks of data"
    " are written.</p>",
    "J 02.07.02 (" + link(COMPILER, "1452", "02-compiler.md:1452") + ")",
)}

<p>The loader chapter prints the core layout at execution time. The crop
<a href="crops/j-03-03-01-core-layout.png"><code>crops/j-03-03-01-core-layout.png</code></a>
is the chart, cut from
{link("comtran-manuals/J28-6169/images/page-081.png")}.</p>

<figure>
<div class="scan"><img src="{crop("j-03-03-01-core-layout.png")}" alt="Chart of core storage at execution time, from the basic monitor at 0 to customer storage at 32256."></div>
<figcaption>The core layout at execution time. Cut from
comtran-manuals/J28-6169/images/page-081.png, the scan of J 03.03.01.</figcaption>
</figure>

<p>Read from the bottom: Basic Monitor at 0, IOEX at 350, CTM at 1400, IOBS at
1856, File Block at 3840, then File Lists, the Define and Attach calling
sequences, the transfer to program start, <strong>Program</strong>, Secondary
Object Time Subroutines, <strong>Buffer Pools</strong>, the loading routines the
pools overlay, the primary subroutines, and customer storage from 32256. The
note under the chart reads "The core addresses shown above are approximate."
(<code>J 03.03.01</code>, {link(LOADER_MD, "396-417")})</p>

<p>The file blocks sit below the program. The buffer pools sit above it. Our
runtime already puts the file table below the program, in Dart, at the addresses
IOC)1 and the dispatch cells claim (RT-1; M5-3). The buffer therefore goes
above.</p>

<p>The IOCS manual gives the buffer's size rule and the minimum count:</p>

{quote(
    "<p>BUFFER SIZE — The maximum number of data words which a buffer can hold."
    " This restricts output blocks to that maximum length and determines the"
    " maximum number of words which can be read from an input block.</p>",
    "(external: C28-6100-2, PDF p. 83 / printed p. 75)",
)}

{quote(
    "<p>Input files (I) — each input file requires at least one buffer at all"
    " times.</p>",
    "(external: C28-6100-2, PDF p. 14 / printed p. 6)",
)}

<p>The sample proves the size rule from the COMTRAN side. DETAILFILE declares
BLOCKSIZE 3 and its tape blocks are 14 words long:</p>

{quote(
    "<p>Only the 3-word record is to be brought into storage and processed, and"
    " the specification BLOCKSIZE 3 on the DETAILFILE FILE cards accomplishes this"
    " aim. Alternatively, BEGIN and BLOCKSIZE 14 might have been specified on the"
    " FILE card which would have enabled correct processing but allowed the full"
    " 14-word block to enter core.</p>",
    "J 90.05.03 (" + link(SAMPLE, "121-125") + ")",
)}

<p>The program's extent is not yet a loader output.
<code>LoadedProgram.words</code> holds placed words only, and "Reservations place
nothing" ({link(LOADER, "113-115")}). The loader walks <code>PTW</code>
reservations as control groups ({link(LOADER, "305")}), so it
can track the extent. The sample's last placed word is relative 01771, absolute
5113 ({link(CODE, "969")}).</p>

<h3>The decision</h3>

<ul>
<li><code>LoadedProgram</code> gains <code>extent</code>: the first address above
the last placed or reserved word. The loader tracks it as it walks origins,
placements and <code>PTW</code> reservations.</li>
<li>At load, the machine gives each input file a buffer of BLOCKSIZE words, in
<code>*FILE</code> order, from <code>extent</code> upward. BLOCKSIZE comes from
the <code>*SPEC</code> card, which the loader already parses and nothing reads
yet ({link(LOADER, "194-205", "loader.dart:194-205")}).</li>
<li>Output files get no buffer at stage 2. An unread field is banned (CLAUDE.md
section 11). Stage 3 adds the branch for IOC)9.</li>
<li>A buffer is never reassigned. It belongs to its file until the run ends.</li>
<li>A program whose buffers do not fit below 32768 is refused at load with a
message. The sample needs 303 words above 5114. <code>ponytail:</code> no pool
sharing and no second buffer; add them when a program needs them.</li>
</ul>

<h3>The rejected options and their costs</h3>

<div class="scroll">
<table>
<tr><th>Option</th><th>What breaks or misleads</th><th>Cost to reverse</th></tr>

<tr><td>Below the program, in the runtime region</td>
<td>Contradicts the <code>J 03.03.01</code> order. A later reader takes our
layout for the attested one. Room is bounded by the dispatch cells at 1 to 296
and the program origin at 4096.</td>
<td>One constant.</td></tr>

<tr><td>A block held in Dart, with each record copied into a fixed core area per
file</td>
<td>Transmit mode wearing locate mode's numbers. <code>J 02.07.02</code> says a
located GET "determines the position of the record within the buffer area". The
printed report would still match, so the lie would be invisible in the oracle.
Stage 3's <code>FILE MASTER</code> reads the record from the buffer through the
patched IOST word.</td>
<td>Rewrite the handler and the stage-3 FILE path.</td></tr>

<tr><td>The top of core, downward from 32767</td>
<td>No evidence. A reader would ask why.</td>
<td>One constant.</td></tr>

<tr><td>Two buffers per file, after <code>J 02.06.14</code>'s "at least 2 buffers
to each file"</td>
<td>The second buffer is read-ahead. A sequential emulation never observes it, so
the field is unread and section 11 bans it.</td>
<td>Add a field.</td></tr>
</table>
</div>

<h3>What a later reader must not be misled about</h3>

<p>IOCS says that after the EOF exit "there is no information for the file in any
buffer" (external: C28-6100-2, PDF p. 24 / printed p. 16), and its pool may
reassign the buffer. The sample writes <code>HIGH.VALUE</code> through BL)2 after
that exit, at LOC 00342 to 00346, and the 1962 run printed a correct report. The
buffer was therefore not reused in that run. Our design reproduces the result by
being safer than IOCS was: the buffer is never reassigned. The design record says
so in those words.</p>
</section>
"""

# --- 3 -----------------------------------------------------------------

ITEM3 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>3 · The read rules</h2></div>

<p>These rules are ours. The manuals delegate them to IOCS
(<code>J 90.02.08</code>: "A knowledge of the 7090 IOCS is necessary in
understanding most of the IOC Numbers"), and each rule cites the IOCS sentence it
follows.</p>

<h3>The evidence</h3>

{quote(
    "<p>In general, each file is treated as a continuous string of words. For"
    " example, if thirteen words were \"read\" by one IOCS command, the next command"
    " given for the file will start to \"read\" the 14th word, etc.</p>",
    "(external: C28-6100-2, PDF p. 19 / printed p. 11)",
)}

{quote(
    "<p>Clearly, locating words within the buffers adds restrictions to file"
    " design and to the IOCS command sequences. For example, one cannot locate a"
    " logical record that overlaps a physical block, since the record will not"
    " occupy consecutive memory cells.</p>",
    "(external: C28-6100-2, PDF p. 21 / printed p. 13)",
)}

{quote(
    "<p>If EOB ≠ 0, all information located will be retained until the next"
    " reference to the file by any IOCS routine. Further, since information located"
    " by a single IOCS command must be in sequential cells, the execution of a count"
    " command interrupted by the end of buffer condition is discontinued, and EOB"
    " itself is used as the exit of transfer address. Otherwise, transition to a new"
    " buffer is automatic, and the interpretation of the command sequence"
    " continues.</p>",
    "(external: C28-6100-2, PDF p. 24 / printed p. 16)",
)}

<p>The execution table gives the two cases of a count-control locate. With n
words requested and m unread words in the buffer: n ≤ m locates n words; n &gt; m
locates only m, holds the buffer, and takes the EOB exit with MQ code 2
(external: C28-6100-2, PDF p. 81 / printed p. 73).</p>

{quote(
    "<p>EOF is the location to which transfer is made when an end of file"
    " condition occurs. For a labeled file, the condition is recognized from the"
    " trailer label. For an unlabeled file, any EOF mark is recognized as end of"
    " file. For any file, recognition of the EOF mark suspends buffering, so that"
    " there is no information for the file in any buffer when the EOF exit is taken."
    " Buffering will be restarted when the next READ (if any) is given for the"
    " file.</p>",
    "(external: C28-6100-2, PDF p. 24 / printed p. 16)",
)}

{quote(
    "<p>An unlabeled file which is contained on one reel of tape may have any"
    " number of EOF marks. The detection, during reading, of each EOF mark"
    " temporarily suspends buffering on that reel. When an EOF is detected by the"
    " READ routine, the EOF exit is given. If the file is again referred to by a"
    " READ calling sequence, buffering will continue until the next EOF mark is"
    " encountered.</p>",
    "(external: C28-6100-2, PDF p. 34 / printed p. 26)",
)}

<p>The abnormal-conditions table: READ on a "File never opened" and on a "File
already closed" both take the "EOF exit" (external: C28-6100-2, PDF p. 79 /
printed p. 71). D6.5 already decides the COMTRAN side: a GET on a file that is
not open takes that GET's own AT END exit with no message.</p>

<p>The sample requires the base locator untouched after AT END. END.OF.MASTERS
runs <code>CAL BL)2 / ACL CP)+45 / SLW SYS)133</code> and then a MOVPAK store of
six <code>74</code> characters, at LOC 00342 to 00347
({link(SAMPLE, "920-926")}). That is <code>SET M.EMP.NO = HIGH.VALUE</code>
written into the last located MASTER record, after the end of file.
END.OF.DETAILS does the same through BL)3.</p>

<p>The file mark is ours by M5-2: a record of length zero.</p>

<h3>The decision</h3>

<ol>
<li>The file is a stream of blocks. The buffer holds one block. A GET locates the
next <code>len</code> words, where <code>len</code> is the decrement of word
3.</li>
<li>At most BLOCKSIZE words of a tape block enter the buffer. The rest of the
block is discarded (<code>J 02.06.04</code>; <code>J 90.05.03</code>).</li>
<li>When the buffer holds no unread word, the GET reads the next block
first.</li>
<li>When the buffer holds fewer unread words than <code>len</code>, and more than
zero, the GET takes SYS)260. The record would straddle a block.</li>
<li>A file mark takes the AT END exit. The base locator keeps its value. The
buffer's unread count becomes zero. The next GET on the file reads on past the
mark.</li>
<li>A GET on a file that is not open takes the AT END exit with no message
(D6.5).</li>
<li>The words of a record stay in the buffer until the next GET on the same file
refills it. Stage 3's FILE reads a located record from there through the patched
IOST word. This is our answer to Open Question 54 for the emulation: the sample
always files the master before the next GET on it. The definition holds no
design, so the answer lives in <code>m5-io.md</code>, with a pointer from the
record to Q54.</li>
<li>The reader decodes a record by M5-2: six bytes per word, the most significant
six bits first, each byte's six bits in its low end. The decoder lands in
<code>lib/src/runtime/tape.dart</code>. The encoder that the tests need lives in
<code>test/runtime/runtime_support.dart</code> until stage 3 writes a record;
then it moves into <code>tape.dart</code>. Stage 1's pull request set this
precedent: it built no codec because nothing read one.</li>
</ol>

<h3>Cost to reverse</h3>

<p>Each rule is a branch in one handler. None is visible outside the run.</p>
</section>
"""

# --- 4 -----------------------------------------------------------------

ITEM4 = f"""
<section class="item needs">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>4 · An unreadable tape record</h2></div>

<h3>The question</h3>

<p>Three conditions present the same face to the reader, and the design needs one
rule for all three:</p>

<ul>
<li>a record frame whose leading and trailing lengths disagree, or whose data is
shorter than the length says;</li>
<li>a data length that is not a multiple of six bytes, so the last word is
partial;</li>
<li>an image that ends with no file mark. M5-2 says the end of the host file ends
the tape. A READ past the end of the tape has nothing to read.</li>
</ul>

<h3>The evidence</h3>

<p>IOCS's error exit is for a record the system cannot read:</p>

{quote(
    "<p>ERR is the location to which transfer is made when any of three types of"
    " error conditions occur: (a) a redundancy which cannot be corrected; (b) check"
    " sum error (binary file); and (c) sequence error. The condition is recognized"
    " at the first reference to a buffer in which it occurs.</p>",
    "(external: C28-6100-2, PDF p. 24 / printed p. 16)",
)}

{quote(
    "<p>SYS)283 prints a message concerning the GET error and exits to the CT"
    " Monitor.</p>",
    "J 90.02.32 (" + link(GENCODE, "1827", "90.02-generated-code.md:1827") + ")",
)}

<p>Stage 1 drew a line for host-side problems found before the run. A missing
input image is a <code>RunFault</code> the tool reports before any word runs, "a
silent empty tape would print a wrong report" (M5-3). Stage 1 built no path for a
problem found during the run, because no word of stage 1 read a record.</p>

<div class="opt pick"><p class="name">Option A, recommended: the IOCS error exit</p>
<p>All three conditions take SYS)283. It prints
<code>GET ERROR ON INPUTMASTER, BLOCK 3</code> and exits to the monitor, and the
run's outcome is <code>errorExit</code>, exit status 1.</p>
<p><strong>Consequences.</strong> D0.7 emulates I/O at the IOCS level, and at
that level a frame the reader cannot decode is a redundancy the system cannot
correct. The discriminator is when the problem is found: before the run, the tool
reports it; during the run, the emulated IOCS reports it. A truncated image fails
visibly, which is M5-3's own argument. SYS)283 lands with a real caller and a
test, and the M5-1 stage table keeps its promise.</p>
<p><strong>What it leaves out.</strong> The display line carries the block
ordinal, not a byte offset. A hand-made image needs the block count to find the
bad frame.</p>
<p><strong>Cost to reverse.</strong> One handler becomes one catch clause.</p>
</div>

<div class="opt"><p class="name">Option B: a run fault</p>
<p>A <code>RunFault</code> of a new type names the image and the byte offset. The
tool prints it as <code>error: job 1: …</code>. SYS)283 stays unbuilt, and
M5-1's stage table is amended to say that no condition of the emulation reaches
it.</p>
<p><strong>Consequences.</strong> The message is precise for a person debugging
an image. The runtime never reproduces the 1962 error exit, and the M5 charter
carries an entry that cannot land. A later reader sees a reconstruction that
stops one step short of the attested behaviour for no evidential reason.</p>
<p><strong>Cost to reverse.</strong> One catch clause becomes one handler.</p>
</div>

<div class="ask"><span class="label">Recommendation</span>
<p>Option A. The line between "before the run" and "during the run" is the line
stage 1 already drew.</p></div>
</section>
"""

# --- 5 -----------------------------------------------------------------

ITEM5 = f"""
<section class="item needs">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>5 · No <code>--tapes</code> directory</h2></div>

<h3>The question</h3>

<p>M5-3 says: "With no directory named, a file has no host image. It opens, it
closes without writing, and the run behaves as it did before stage 1." Before
stage 1 the run stopped at IOC)8. After stage 2 there is no such stop, so the
sentence needs a new ending. What does a GET do on a file with no host image?</p>

<div class="opt pick"><p class="name">Option A, recommended: the file reads as empty</p>
<p>The first GET on a file with no host image takes the AT END exit.</p>
<p><strong>Consequences.</strong> The no-directory run stays a run with no data,
which is what M5-3 defined. IOCS gives the EOF exit to a never-opened file, so an
empty file is IOCS's own answer to "nothing to read". For the sample: the first
GET takes AT END into END.OF.MASTERS, which tests <code>D.EMP.NO</code> through
BL)3 before any <code>GET DETAIL</code> has run ({link(SAMPLE, "911-915")}). BL)3
is zero, <code>TXL SYS)294,1,0</code> fires, and the run prints
<code>BASE LOCATOR NOT LOADED</code> with exit status 1. That is the program's
own behaviour on an empty master. The HANDOVER sentence that says
<code>--run</code> runs the sample "as far as its first GET" is rewritten: the
sample needs <code>--tapes</code> and the reconstructed data of M6.</p>
<p><strong>What it leaves out.</strong> A person who forgets <code>--tapes</code>
gets the program's message, not the tool's.</p>
<p><strong>Cost to reverse.</strong> One branch.</p>
</div>

<div class="opt"><p class="name">Option B: a fault at the first GET</p>
<p>A GET on a file with no host image is a <code>RunFault</code>: "GET on
INPUTMASTER: no tape directory".</p>
<p><strong>Consequences.</strong> Any program with input fails at its first GET
without <code>--tapes</code>, so M5-3's no-directory mode is useless for such
programs. The message is clearer for a person who forgot the flag.</p>
<p><strong>Cost to reverse.</strong> One branch.</p>
</div>

<div class="ask"><span class="label">Recommendation</span>
<p>Option A. It keeps M5-3's mode meaningful and it is what IOCS does with
nothing to read.</p></div>
</section>
"""

# --- 6 -----------------------------------------------------------------

ITEM6 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>6 · The delivery plan</h2></div>

<h3>The branch and the files</h3>

<p>Branch <code>m5s2-get</code> off master, one pull request. It changes files
under <code>lib/</code>, so it merges on external-review convergence under the
charter.</p>

<div class="scroll">
<table>
<tr><th>File</th><th>Change</th></tr>

<tr><td><code>lib/src/runtime/tape.dart</code></td>
<td>New. The record reader over an image's bytes: the M5-2 frame, the file mark,
the end of the tape, the six-byte word decode, and the unreadable-record
condition of item 4.</td></tr>

<tr><td>{link(MACHINE)}</td>
<td><code>RuntimeFile</code> gains the buffer base, BLOCKSIZE, the unread-word
cursor and the reader. The allocator of item 2 runs at load. Open reads the image
bytes; close drops the reader.</td></tr>

<tr><td><code>lib/src/runtime/iocs.dart</code></td>
<td>New. IOC)8, SYS)260 and SYS)283, registered as a third map spread beside the
run frame and MOVPAK ({link(MACHINE, "186-189", "machine.dart:186-189")}).</td></tr>

<tr><td>{link(LOADER)}</td>
<td><code>LoadedProgram.extent</code>.</td></tr>

<tr><td>{link(SUPPORT)}</td>
<td>The tape encoder and a helper that writes an image from a list of
blocks.</td></tr>

<tr><td><code>test/runtime/tape_test.dart</code></td>
<td>New. The decoder against the M5-2 frame.</td></tr>

<tr><td><code>test/runtime/iocs_test.dart</code></td>
<td>New. The protocol tests below.</td></tr>

<tr><td>{link(MACHINE_TEST)}</td>
<td>The boundary flip and two retargets.</td></tr>

<tr><td>{link("docs/design/m5-io.md")}</td>
<td>M5-7 (item 2), M5-8 (items 3 to 5 as decided), amendments to M5-3 and
M5-5.</td></tr>

<tr><td>{link("docs/design/runtime.md")}</td>
<td>RT-1: the stage-2 entries; the sample's span is 4096 to 5113, not
5031.</td></tr>

<tr><td>{link("docs/design/decisions.md")}</td>
<td>D6.5's implementation note says "the third calling-sequence word". It is the
address field of parameter word 2, the third word counting the
<code>TSX</code>.</td></tr>

<tr><td>{link("docs/HANDOVER.md")}</td>
<td>The state row, the next task (stage 3), the <code>--run</code> sentence, the
test baseline.</td></tr>
</table>
</div>

<p>Nothing changes under <code>test/goldens/</code>. A change there means the
generator moved, which stage 2 must not do.</p>

<h3>The tests and their oracles</h3>

<ul>
<li>The decoder: one word to its six bytes and back, a file mark, the end of the
tape, and each unreadable condition of item 4.</li>
<li>The protocol, on a hand-built program through <code>machine()</code> and
<code>loaderFile()</code> with a temporary tape directory
({link(SUPPORT, "29-66", "test/runtime/runtime_support.dart:29-66")}):
<ul>
<li>two records in one block: the cell holds the base after the first GET and
base plus <code>len</code> after the second; the resume address is the
<code>TSX</code> plus four; index register 4 is unchanged;</li>
<li>a third record in a second block: the cell holds the base again;</li>
<li>a 14-word block with BLOCKSIZE 3 and <code>len</code> 3: the second GET reads
the next block, not words 4 to 6;</li>
<li>the GET after the last record: the instruction counter is the AT END address
and the cell is unchanged; a further GET reads on past the mark;</li>
<li>a file that is not open: the AT END exit and no display line (D6.5);</li>
<li>a 20-word block of 15-word records: the second GET prints the SYS)260 line
and the run ends in <code>errorExit</code>;</li>
<li>the item 4 conditions: the SYS)283 line and <code>errorExit</code> (or the
fault, per Jack's call);</li>
<li>no tape directory: AT END at the first GET (or the fault, per Jack's
call);</li>
<li>two files located at once: BL)2 and BL)3 both valid and different.</li>
</ul>
</li>
<li>The boundary flip: the sample with one master record on <code>D1.tap</code>
and one detail record on <code>C2.tap</code> runs past IOC)8 and stops at IOC)9,
<code>UnimplementedRuntimeEntry</code> 9. The cells at absolute 5047 and 5048
hold addresses at or above the extent, and the record words sit there. The
employee numbers pick the path, and the path picks which FILE stops the run. The
sample with no tapes ends in <code>BASE LOCATOR NOT LOADED</code>, under item 5's
recommendation.</li>
<li>Two tests retarget:
{link(MACHINE_TEST, "128-140", "machine_test.dart:128-140")} asserts the exact
string <code>unimplemented runtime entry IOC)8</code> on a bare
<code>TSX IOC)8,4</code>, and moves to another unbuilt entry;
{link(MACHINE_TEST, "218-222", "machine_test.dart:218-222")}, the process test,
fails on IOC)9 after stage 2.</li>
<li>The gate: <code>dart format</code>, <code>dart analyze --fatal-infos</code>,
<code>dart test</code>, <code>deckconv check .</code>. Re-measure the test count
for HANDOVER.</li>
</ul>

<h3>The agents</h3>

<ul>
<li>One implementer, <code>general-purpose</code> on <code>opus</code>, with this
record and the three evidence files as the specification. Stage 1's pull request
is the model for the description.</li>
<li>A gate runner on <code>sonnet</code>.</li>
<li>A ponytail review and an adversarial fresh-context review, both on
<code>opus</code>, before the pull request. The reviewer reads the diff and the
repository, never the plan.</li>
<li>The external loop of <code>EXTERNAL-REVIEW.md</code> after the pull request
opens. Opening waits for Jack's answer to items 4 and 5; that answer authorizes
it.</li>
<li>Fable spend: orchestration only. Stage 1 landed as +552 −109 across 12 files;
stage 2 is of that size.</li>
</ul>
</section>
"""

# --- 7 -----------------------------------------------------------------

ITEM7 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>7 · What stage 2 does not build, and the provenance</h2></div>

<h3>Not built, under RT-1 and section 11</h3>

<div class="scroll">
<table>
<tr><th>Entry or feature</th><th>Why it waits</th></tr>

<tr><td>IOC)2 and the 12-word file blocks</td>
<td>No emitter. The file table is Dart's (M5-3).</td></tr>

<tr><td>IOC)3 to 7: DEFINE, JOIN, ATTACH, named CLOSE and OPEN</td>
<td>No emitter. The generator refuses named OPEN and CLOSE (M4-15 as
amended).</td></tr>

<tr><td><code>*POOL</code> and <code>*GROUP</code> cards, pool sharing, a second
buffer</td>
<td>The loader refuses the cards; D7.3 waits for the shape. Read-ahead has no
observable effect.</td></tr>

<tr><td>SYS)265, the no-AT END terminator</td>
<td>The generator refuses a GET without AT END.</td></tr>

<tr><td>ON ERROR procedures in place of SYS)283</td>
<td>Refused shape (M4-15 as amended).</td></tr>

<tr><td>Transmit mode, SPANS, HOLD, CARD</td>
<td>No emitter. <code>J 02.07.03</code> gives the triggers; no template exists
for the sequence.</td></tr>

<tr><td>Multi-reel files, UNIT2, labels, SEQ, CKSUMS</td>
<td>No site in the sample; D6.2 waits for a label.</td></tr>

<tr><td>The card GET, SYS)286 to 288</td>
<td>No emitter.</td></tr>

<tr><td>The accumulator history word IOCS leaves after READ</td>
<td>No compiled word reads it.</td></tr>

<tr><td>Tape parity</td>
<td>M5-2's <code>ponytail:</code> note stands.</td></tr>

<tr><td>The record encoder in <code>lib/</code></td>
<td>Stage 3 writes the first record. Until then the encoder lives in test
support.</td></tr>

<tr><td>The tool that rebuilds the sample's input tapes from the printed
report</td>
<td>M6's work. Stage 2's encoder is what it will use.</td></tr>
</table>
</div>

<h3>Provenance</h3>

<ul>
<li>The published 7090 IOCS manual, C28-6100-2, is an external period source. The
definition already cites it under Open Questions 45, 46 and 50. It was downloaded
from bitsavers on 2026-09-12 and read for this record. It is not the sealed
archive of D0.9, which is the recovered 1963 source. Nothing from the archive was
read.</li>
<li>Three reports were written before any design sentence, and they sit in
<code>evidence/</code> as written:
<a href="evidence/s2-manual-get.md"><code>s2-manual-get.md</code></a> (the two
COMTRAN manuals, the definition and the decision slate),
<a href="evidence/s2-runtime-codegen.md"><code>s2-runtime-codegen.md</code></a>
(the runtime, the generator, the goldens and the tests), and
<a href="evidence/s2-iocs-read.md"><code>s2-iocs-read.md</code></a> (the IOCS
manual).</li>
<li>The one crop,
<a href="crops/j-03-03-01-core-layout.png"><code>crops/j-03-03-01-core-layout.png</code></a>,
is cut from {link("comtran-manuals/J28-6169/images/page-081.png")}, the scan of
<code>J 03.03.01</code>. The record's placement decision rests on the row order
of that chart, and the transcription and the scan agree.</li>
<li>Two record defects surfaced and ride in the pull request:
<code>runtime.md</code> RT-1 says the sample holds 4096 to 5031, and the golden's
last placed word is 5113; D6.5's implementation note says "the third
calling-sequence word" for the AT END exit, which is parameter word 2.</li>
</ul>
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
<title>M5 stage 2, GET: the design and the delivery plan</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<p class="eyebrow">Review record · M5 stage 2, GET · evidence 2026-09-12 · head {RECORD_HEAD}</p>
<h1>M5 stage 2, GET: the design and the delivery plan</h1>
</header>

<section class="answer">
<h2>The answer</h2>
<ol>
<li><strong>DECIDED.</strong> IOC)8 is the IOCS READ routine under its COMTRAN
numbers. SYS)260 is its end-of-buffer exit and SYS)283 its error exit. Each
prints one line and exits to the monitor.</li>
<li><strong>DECIDED.</strong> Each input file gets one buffer of BLOCKSIZE words,
placed above the program's last word, where the 1962 loader put the buffer pools.
No buffer is reassigned before the run ends.</li>
<li><strong>DECIDED.</strong> A GET locates the next record in the buffer. It
reads the next tape block when the buffer is spent. A file mark takes AT END and
leaves the base locator as it was. A record that would straddle a block takes
SYS)260.</li>
<li><strong>YOUR CALL.</strong> A tape record the reader cannot read takes the
IOCS error exit, SYS)283. Recommended. The alternative is a run fault outside the
emulation.</li>
<li><strong>YOUR CALL.</strong> With no <code>--tapes</code> directory, every
input file reads as empty. Recommended. The alternative is a fault at the first
GET. Under the recommendation, the sample with no tapes ends in
<code>BASE LOCATOR NOT LOADED</code>, exit status 1.</li>
<li><strong>DECIDED.</strong> One pull request, <code>m5s2-get</code>. One
implementer with this record as the specification. A ponytail review and an
adversarial review before the pull request, then the external loop.</li>
<li><strong>SETTLED.</strong> What stage 2 does not build, and the provenance of
the evidence.</li>
</ol>
<p>A reader who stops here knows the design. Items 4 and 5 wait for Jack. Nothing
else does.</p>
</section>

<section>
<p class="note"><strong>Citation forms:</strong> <code>J 02.07.02</code> is the
1962 processor manual by IBM section code. <code>F p. 40</code> is the 1960
manual by printed page. <code>(external: C28-6100-2, PDF p. N / printed p. M)</code>
is the published 7090 IOCS manual, the source J delegates the I/O system to.
<code>D6.5</code> is a decision record. <code>M5-5</code>, <code>RT-1</code>,
<code>M4-15</code> are design-record entries. <code>LOC 00203</code> is an object
location in the 1962 listing.</p>
</section>
{ITEM1}{ITEM2}{ITEM3}{ITEM4}{ITEM5}{ITEM6}{ITEM7}
<footer>
<p>Record built 2026-09-12 on branch
<code>review/2026-09-12-m5s2-get-design</code>. Every repository link above
points at commit {RECORD_HEAD} on master, never at a branch.
<code>tools/build_doc.py</code> writes this page; edit it, not the HTML. Set
<code>RECORD_HEAD</code> in the environment to build the links from another
commit. <code>evidence/</code> holds the three reports the stage was designed
from, and <code>evidence/README.md</code> says what each one is.
<code>crops/</code> holds one image, the core-layout chart of J 03.03.01, and the
page embeds it.</p>
</footer>

</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
