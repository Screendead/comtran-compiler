"""Assemble the M6 stage-2 chunk-2a review page.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: the two crops are embedded as `data:` URIs,
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

RECORD_HEAD = os.environ.get("RECORD_HEAD", "1892093")
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
    """A monospace plate, for a card image or a listing excerpt."""
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

ACCEPT = "docs/design/m6-acceptance.md"
HANDOVER = "docs/HANDOVER.md"
DEFN = "docs/comtran-language-definition.md"
NOTES = "test/fixtures/f-payroll-deck-notes.md"
VERB_CT = "test/fixtures/f-payroll.ct"
VERB_GOLD = "test/goldens/f-payroll.listing"
APPL_GOLD = "test/goldens/f-payroll-j.listing"
CORPUS_TEST = "test/f_corpus_test.dart"
PROC = "lib/src/codegen/procedure.dart"
MAPPER = "lib/src/data/mapper.dart"
PARSER_MSG = "lib/src/parser/parser_messages.dart"
SEVERITIES = "lib/src/lexer/severities.dart"
F_DATA = "comtran-manuals/F28-8043/04-data-description.md"
J_SYSOP = "comtran-manuals/J28-6169/05-systems-operation.md"

# --- 1 -----------------------------------------------------------------

ITEM1 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>1 · Chunk 2b takes the 1960 program to the 1962 sample's own form</h2></div>

<h3>Where the generator stops, and what it cannot reach</h3>

<p>The applied deck compiles clean, then the code generator refuses its first
unattested shape, <code>FILE MASTER IN ERROR.FILE</code> at statement 131,00
({link(CORPUS_TEST, "52-60", "f_corpus_test.dart:52-60")}). A job stops at its
first refusal, so the run shows one shape and the generator's source shows the
other six:</p>

<ul>
<li><code>FILE record IN file</code>, three times
({link(PROC, "1849-1850", "procedure.dart:1849")});</li>
<li>every arithmetic sentence: each SET target, ADD operand, comparand and DO
index is external decimal, which the generator does not recover ({link(PROC, "996-1002", "procedure.dart:996")});</li> <li>the withholding-tax and FICA tests, each a comparison of an
expression;</li>
<li><code>(DETAIL HOURS - 40) * MASTER RATE * 1.5</code>, a product of a
product ({link(PROC, "2780-2782", "procedure.dart:2780")});</li>
<li><code>DO SEARCH FOR INDEX = 1(1)12</code>, an index that is external and
located in a record ({link(PROC, "1523-1527", "procedure.dart:1523")});</li>
<li><code>MOVE PAYRECORD NETPAY TO CHECK AMOUNT</code>, whose
<code>$88889.99-</code> source holds five integer digits and whose
<code>$***9.99</code> target holds four: an edit run that bypasses source digits
({link(PROC, "2074-2075", "procedure.dart:2074")});</li>
<li><code>TABLE.ITEM RATE (INDEX)</code>, 11 characters, whose stride truncates
to one word with no refusal (item 5).</li>
</ul>

<h3>The decision</h3>

<p>Chunk 2b applies the remaining rows of the definition's §9.8 divergence
table, in the form the 1962 sample itself used: arithmetic staged in a WORKING
area of internal fields; the master's numerics retyped internal-decimal in a
binary file; a dedicated error record and a plain <code>FILE</code>; 24
per-field constants for the six table literals; explicit MOVEs where the
qualifier chains differ; INDEX in WORKING. The 1960 records and flow stay. M6-8
holds it ({link(ACCEPT, "319-379", "m6-acceptance.md:319-379")}).</p>

<p>Three facts leave one option open, which is what the CLAUDE.md section 12
standing rule acts on. The roadmap's words for stage 2 are this course: F's
payroll example "with the documented F/J divergences applied". The 1962
processor applied those rows to this program, so every replacement is attested.
And the alternative has no oracle: no shape of it has a listing behind it.</p>

<h3>The rejected courses and their costs</h3>

<div class="scroll">
<table>
<tr><th>Course</th><th>What it would build</th><th>What it costs</th></tr>

<tr><td><strong>A.</strong> Recover the 1960 shapes</td>
<td>External-decimal arithmetic from the convert members of J 90.02 — SYS)184
in, SYS)186 to 188 out — then the other six shapes above. The compiler would gain
the largest part of the language the sample never touches, and codegen defects 1
to 4 would get sites.</td>
<td>An order of magnitude more work, every piece of it a design with no listing
to check it against, and it walks the 11-character table item straight into the
codegen defect of item 5. Parked in HANDOVER as a stage of its own; whether to
schedule it is Jack's
({link(HANDOVER, "516-522", "HANDOVER.md:516-522")}).</td></tr>

<tr><td><strong>B(ii).</strong> The chosen course, but keeping the 1960
master's fields external</td>
<td>The same WORKING staging, over the 1960 master as printed.</td>
<td>Two shapes stay unbuilt. The master's year-to-date fields stay external, so
updating them from WORKING needs SYS)186, a runtime member the sample never
attests; and the check amount's edit run still bypasses source digits. Retyping
the master internal-decimal and making its file binary removes both, and it is
what the 1962 sample did.</td></tr>
</table>
</div>

<h3>What follows from taking it</h3>

<p>The table items become two whole words, so the 1962 processor's RET.PREM-
equals-INS.PREM defect reproduces here by the same word-granular rule it
reproduces in the sample, and the sample's report becomes a value-level oracle
for this corpus (M6-4). This decision is taken, not asked: Jack can overturn
it, and silence lets it stand.</p>
</section>
"""

# --- 2 -----------------------------------------------------------------

ITEM2 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>2 · The applied deck takes five divergences and no more</h2></div>

<p><code>test/fixtures/f-payroll-j.ctd</code> is the 1960 program with five
changes applied. Each is a row of the §9.8 divergence table, and each is a
change the 1962 front end demands: without it the program draws a diagnostic.
Everything else stays 1960 — external fields, arithmetic in the records,
<code>FILE … IN ERROR.FILE</code>, the six table literal cards, INDEX inside
CURRENT, and the edited pictures. M6-7 holds it
({link(ACCEPT, "273-317", "m6-acceptance.md:273-317")}); the deck notes hold
every card that differs
({link(NOTES, "172-212", "f-payroll-deck-notes.md:172-212")}).</p>

<div class="scroll">
<table>
<tr><th>What was applied</th><th>The alternative, and its cost</th></tr>

<tr><td><strong>1. An environment division, in J's order.</strong> The deck
orders its divisions <code>*DATA</code>, <code>*ENVIRONMENT</code>,
<code>*PROCEDURE</code> (D2.2). Eleven new cards declare five BCD tape files, named after the 1960 prose the
way ERROR.FILE is: MASTER.FILE and DETAIL.FILE in; REPORT.FILE, CHECK.FILE and
ERROR.FILE out. ERROR.FILE carries MASTER, DETAIL and BONDORDER, because the
program files its bond orders there. Each BLOCKSIZE is the word count of that file's longest record, and each tape
unit is the 1962 sample's for the like file. No file receives an updated master:
the 1960 introduction promises one (F p. 87) and the program files MASTER only
in error.</td>
<td>Keep F's order and append the environment division at the end: D2.2
permits it, but names DATA → ENVIRONMENT → PROCEDURE the canonical order for
our fixtures. Taking the 1962 sample's <em>file names</em> was rejected for
the opposite reason: names are 1960 content, not a front-end
requirement.</td></tr>

<tr><td><strong>2. CALL old names qualified, synonyms unqualified.</strong> The
1962 sample's pattern, five pairs: <code>(MASTER EMPLOYEE.NUMBER)
M.EMPLOYNO</code>, <code>(DETAIL EMPLOYEE.NUMBER) D.EMPLOYNO</code>, and
<code>M.BONDEDUCT</code>, <code>M.BONDENOM</code>, <code>M.BONDACCUM</code> for
MASTER's bond fields. Every other renamed reference is written in full. DPT is
dropped, because every use of it qualifies a field.</td>
<td>Drop the CALL sentence and write every name in full, losing the construct
the corpus exercises; or keep one synonym per pair used, which re-creates the
collision — six of the seven 1960 pairs name a field in more than one record,
which D4.13 rejects with message 166,00.</td></tr>

<tr><td><strong>3. <code>STOP RUN</code> for <code>STOP 1234</code></strong>
(D2.7), which serial 02011 of the verbatim deck reads.</td>
<td>None. D2.7 makes STOP RUN mandatory; without one a program draws message
175,00. <code>STOP 1234</code> is legal and stays in the verbatim deck, but it
cannot stand alone.</td></tr>

<tr><td><strong>4. GRAND.TOTAL written out.</strong> Serial 09012 reads
<code>GRAND.TOTAL 1COPY DEPARTMENT.TOTAL</code>; the applied deck writes it out
in ten cards, as a RECORD carrying DEPARTMENT.TOTAL's nine entries and its
justification code <code>L</code>, under the F p. 76 rule quoted in item 4.</td>
<td>Write a plain level-1 group, the way the 1962 sample's own GRAND.TOTALS is
written. Rejected because the rule copies the entry whole but for name and
level, so the type and the <code>L</code> come across with it. The <code>L</code>
changes no output; the deck keeps it because the rule says to.</td></tr>

<tr><td><strong>5. The bare REDEF card.</strong> Serial 10008 punches a level
<code>1</code> before <code>REDEF</code>; the applied deck blanks column 24.
TABLE.ITEM moves from level 2 to level 1, keeps its quantity 12, and its three
fields move from level 3 to level 2 (D3.4; D3.6).</td>
<td>None. D3.4 requires the first entry after a REDEF to sit at the redefined
item's level, and makes a level on the REDEF line a warned form. The verbatim
deck keeps the 1960 coding and draws all three messages.</td></tr>
</table>
</div>

<p>The applied deck holds 215 cards. Its listing draws three 206,00 messages,
one per use of INDEX in the SEARCH sentence at statement 165,00, and closes
SEVERITY LIMIT WAS NOT REACHED
({link(APPL_GOLD, "236-242", "f-payroll-j.listing:236-242")}).</p>
</section>
"""

# --- 3 -----------------------------------------------------------------

ITEM3 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>3 · Stage 2 is chunked, its oracle is values, and its goldens take a fixed
page head</h2></div>

<p>M6-1 as amended 2026-09-14 ({link(ACCEPT, "31-53", "m6-acceptance.md:31-53")})
changes three things about the second stage. Each was taken under the same
standing rule.</p>

<ul>
<li><strong>The stage is chunked</strong>, into chunk 2a — this work — and
chunk 2b. The precedent is M4 stage 2, chunked on Jack's call of 2026-08-09, for
the same reason: the stage is too large to review in one piece.</li>
<li><strong>Its input is not the 1962 sample's tapes.</strong> The 1960 records
are 80-character external images of a different shape, so chunk 2b writes the
same source table, <code>tool/sample_tapes_source.dart</code>, out again in
this corpus's layouts.</li>
<li><strong>Its oracle is the values the sample's report prints, not its
bytes.</strong> A different record layout prints different columns, so a
byte-for-byte diff against the sample's report golden would fail on formatting
alone and say nothing about the program.</li>
</ul>

<p>Both listing goldens are compiled with
<code>--date=06/01/60 --time=1.00</code>
({link(CORPUS_TEST, "16-19", "f_corpus_test.dart:16-19")}). A listing's page
head prints the run's date and time, and the 1960 manual prints no page head, so
neither survives. Both values are arbitrary and claim nothing about when this
program was compiled; F28-8043 is dated June 1960, which is where the date came
from ({link(NOTES, "103-107", "f-payroll-deck-notes.md:103-107")}). Without
them the compiler prints today's date and no golden can hold.</p>

<p>The alternative is to strip the head line before comparing. Rejected: the
head is compiler output, the 1962 sample's golden carries its own, and a golden
that holds everything but one line cannot catch a change to that line.</p>
</section>
"""

# --- 4 -----------------------------------------------------------------

ITEM4 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>4 · The verbatim deck is the compiler's first diagnostic corpus</h2></div>

<p>The 1962 processor never compiled the 1960 program. Ours does, and because
the 1962 sample compiles clean, this is the first fixture to exercise the
diagnostic machinery. The front end prints 55 messages of 12 kinds and closes
SEVERITY LIMIT WAS NOT REACHED
({link(VERB_GOLD, "207-276", "f-payroll.listing:207-276")}).</p>

<div class="scroll">
<table>
<tr><th>Count</th><th>Id</th><th>Message</th></tr>
<tr><td>26</td><td>108,00</td><td>'NAME.1' IS AN UNDEFINED SYMBOL.</td></tr>
<tr><td>7</td><td>101,00</td><td>'NAME.1' IS AN IMPROPERLY QUALIFIED NAME.</td></tr>
<tr><td>6</td><td>166,00</td><td>'NAME.1' IS NOT UNIQUE IN THIS SECTION.</td></tr>
<tr><td>4</td><td>19,00</td><td>RECORD 'NAME.2' MUST BE ON AN OUTPUT -FILE- CARD.</td></tr>
<tr><td>3</td><td>9,00</td><td>RECORD 'NAME.2' MUST BE ON A -FILE- CARD.</td></tr>
<tr><td>3</td><td>21,00</td><td>'NAME.1' IS NOT A FILE. CHECK ENVIRONMENT DESCRIPTION.</td></tr>
<tr><td>1</td><td>175,00</td><td>NO -STOP RUN- IN PROGRAM.</td></tr>
<tr><td>1</td><td>110,00</td><td>-COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM.</td></tr>
<tr><td>1</td><td>906,00</td><td>DATA DESCRIPTION CARD CODING CONFLICTS WITH ITS TYPE CODE. (NON-HISTORICAL.)</td></tr>
<tr><td>1</td><td>81,00</td><td>CONFLICT BETWEEN LEVEL AS GIVEN BY ORIGINAL DEFINITION AND -REDEF-.</td></tr>
<tr><td>1</td><td>80,00</td><td>CONFLICT BETWEEN JUSTIFICATION AS GIVEN BY ORIGINAL DEFINITION AND -REDEF-.</td></tr>
<tr><td>1</td><td>206,00</td><td>'NAME.1' HAS INEFFICIENT FORMAT FOR SUBSCRIPT VARIABLE.</td></tr>
</table>
</div>

<p>Three causes account for all 55. The CALL sentence renames seven names that
each appear in more than one record, so six are rejected as not unique and every
reference through a synonym never made is undefined or improperly qualified
(D4.13). There is no environment division, so no <code>*FILE</code> card carries
a record and ERROR.FILE is not a file name. The rest is the 1960 coding of STOP,
COPY, the REDEF line and INDEX, one message each; 906,00 is ours, not a 1962
number ({link(PARSER_MSG, "222", "parser_messages.dart:222")};
{link(SEVERITIES, "631", "severities.dart:631")}).</p> <p>The generator then refuses the first GET, at statement 3,00: <code>a GET
record on 0 input files (no sample instance)</code>. No <code>*FILE</code> card
lists MASTER, so the statement has no input file. A listing cannot carry a
refusal, so the corpus test pins the string
({link(CORPUS_TEST, "44-50", "f_corpus_test.dart:44-50")}).</p>

<h3>Three observations, none of them a defect</h3>

<p><strong>The absent environment division draws nothing.</strong> No message
names it and the compiler completes. The 1962 manual says:</p>

{quote(
    "<p>Unless a catastrophic error occurs (e.g., the omission of a division"
    " header), compilation will be completed regardless of the number of errors"
    " encountered. If a catastrophic error occurs, a standard end-of-job message"
    " will be printed and control will be passed to the CTM supervisor.</p>",
    "J 05.06.01 (" + link(J_SYSOP, "246", "05-systems-operation.md:246") + ")",
)}

<p>The manual does not say whether a division absent whole is that omission, or
only a header missing from in front of its cards (D2.3).</p>

<p><strong><code>DPT HOURS</code> draws 101,00, and the question behind it is
open.</strong> DPT is the one synonym the CALL sentence does make, and every
use of it qualifies a field through it. D4.13 diagnoses "a qualified reference
whose last name is a synonym" and says plainly that the rule is ours: "That
prohibition is a design decision under D0.4, amendable — … Open Question 56
leaves the question open in terms". That question asks it directly: "May it be
qualified at all?" ({link(DEFN, "4488", "comtran-language-definition.md:4488")}). The applied deck avoids the form rather than resting
on an answer.</p>

<p><strong>An expanded COPY entry is a RECORD.</strong> The rule behind item 2's
fourth divergence:</p>

{quote(
    "<p>The processor will then obtain the original data description and copy"
    " it in its entirety, except for the following modifications: (1) The"
    " original name will be replaced by the new name. (2) If a new level"
    " number has been specified for the new name, the level numbers … will be"
    " adjusted …</p>",
    "F p. 76 (" + link(F_DATA, "551-553", "04-data-description.md:551-553") + ";"
    " the conversion breaks the sentence after “entirety”)",
)}

<p>Only the name and the level are modified, so DEPARTMENT.TOTAL's type
<code>RECORD</code> and code <code>L</code> come across with its nine
entries.</p>

<p>One limit on all of this: the goldens have no 1962 oracle. The sample's
listing carries no message, so the layout of a listing with messages is
decision-conformance only. The goldens pin only that it does not change
silently.</p>
</section>
"""

# --- 5 -----------------------------------------------------------------

ITEM5 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>5 · Codegen defect 7: a table item that is not a whole number of words
strides too short</h2></div>

<p>The 1960 table item is 11 characters wide: TABLE.ITEM holds RATE
<code>99V999</code>, INSURANCE.PREM <code>9V99</code> and RETIREMENT.PREM
<code>9V99</code> — five characters and three and three
({link(VERB_CT, "184-187", "f-payroll.ct:184-187")}). A 7090 word is six
characters, so the item spans two words.</p>

<p>The generator computes a subscript's stride in whole words:</p>

{plate("""  int _strideWords(DataItem table) {
    for (DataItem? each = table; each != null; each = each.parent) {
      final ItemSemantics sem = _sem(each);
      if (sem.quantity > 1) {
        return sem.strideChars ~/ 6;""")}

<p class="cite">{link(PROC, "1706-1710", "lib/src/codegen/procedure.dart:1706-1710")}</p>

<p><code>strideChars</code> is the group's extent in characters, set by the data
mapper from the item's start and end:</p>

{plate("""    final int extent = frame.endChar - frame.startChar;
    …
    sem
      ..storageChars = extent
      ..strideChars = extent""")}

<p class="cite">{link(MAPPER, "880-886", "lib/src/data/mapper.dart:880-886")}</p>

<p>Eleven divided by six is one. An 11-character item therefore strides one word
where it should stride two, and every subscripted reference past the first
element reads the wrong place. Nothing refuses it, and nothing warns.</p>

<p>No run reaches it: the 1962 sample's items are two whole words, and this
corpus's applied deck refuses at statement 131,00 long before its SEARCH
sentence generates anything. It is recorded as the seventh of HANDOVER's
codegen defects ({link(HANDOVER, "192-197", "HANDOVER.md:192-197")}), found on
2026-09-14, and is not fixed here. Whether such a site refuses the shape or
handles it is Jack's call, as for the other six, and any fix must leave
<code>test/goldens/90.05-payroll.code</code> byte for byte as it stands. Chunk
2b removes the site rather than the defect: its table items are two whole
words.</p>
</section>
"""

# --- 6 -----------------------------------------------------------------

ITEM6 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>6 · What this chunk changed in the language definition, and what it still
owes</h2></div>

<h3>§9.7 corrected, on Jack's instruction of 2026-09-14</h3>

<p>The paragraph on the report's printer artifacts used to open "The
transcription preserves printer artifacts of the original (half-line staggering
of trailing columns; …)". There is no stagger: the page is skewed, every line
rising to the right by about one line height, and a line's arithmetic holds only
when it is read along its own tilted baseline. M6-2 holds the measurement, and
the paragraph now cites it
({link(DEFN, "4248", "comtran-language-definition.md:4248")}).</p>

<h3>Five rows added to the §9.8 divergence table</h3>

<p>Keying the program surfaced five differences the table did not hold
({link(DEFN, "4267-4271", "comtran-language-definition.md:4267-4271")}):</p>

<div class="scroll">
<table>
<tr><th>Topic</th><th>F sample (1960)</th><th>J sample (compiled 1961/62)</th><th>Authority</th></tr>
<tr><td>FICA cap</td>
<td>tests, then adds: <code>IF MASTER FICA + 0.03 * DETAIL GROSS IS LESS THAN
144.00 THEN SET DETAIL FICA = 0.03 * DETAIL GROSS OTHERWISE SET DETAIL FICA =
144.00 - MASTER FICA</code> (serials 03016–03018)</td>
<td>adds, then caps: <code>ADD WORKING FICA TO MASTER FICA. IF MASTER FICA GT
144.00 THEN SET WORKING FICA = WORKING FICA - (MASTER FICA - 144.00), SET MASTER
FICA = 144.00</code></td>
<td>F p. 93; J 90.05 listing</td></tr>
<tr><td>Bond orders</td>
<td>filed into the error file: <code>FILE BONDORDER IN ERROR.FILE</code> (serial
04014)</td>
<td>filed into its own BONDORDERFILE: <code>FILE BONDORDER</code></td>
<td>F p. 94; J 90.05</td></tr>
<tr><td>The updated master</td>
<td>the introduction promises an updated master file as output; the program
files MASTER only in error</td>
<td>every matched master is filed to OUTPUTMASTER: <code>FILE MASTER</code></td>
<td>F pp. 87, 91, 93; J 90.05</td></tr>
<tr><td>The last department's totals</td>
<td>department totals print on a department change only, so the last
department's never print; END.OF.RUN moves GRAND.TOTAL straight to PAYRECORD
(serials 02009–02010, 03005–03010)</td>
<td>END.OF.RUN does DEPARTMENT.END first</td>
<td>F pp. 92–93; J 90.05</td></tr>
<tr><td>INDEX and the department key</td>
<td><code>INDEX</code> declared <code>99</code> inside the RECORD CURRENT,
DEPARTMENT beside it (serials 10013–10015)</td>
<td><code>INDEX</code> and <code>POS</code> are <code>IR99</code> in WORKING;
<code>CURRENT.DEPT</code> is <code>AA</code> in DEPARTMENT.TOTAL</td>
<td>F p. 100; J 90.05</td></tr>
</table>
</div>

<h3>Two rows chunk 2b must add</h3>

<p>Both are rows chunk 2b will apply, so it writes them as it applies them: the
overtime formula, which the 1962 sample rearranged to
<code>(HOURS * 1.5 - 20) * RATE</code>; and the master's typing,
internal-decimal fields in a binary file.</p>

<h3>One row chunk 2b must correct</h3>

<p>The existing "Table initialization" row describes the 1960 side as "one
132-char alphameric literal, 6 continuation cards"
({link(DEFN, "4261", "comtran-language-definition.md:4261")}). The deck is not
that. It is six level-2 entries, each carrying its own quote-delimited
22-character literal, on six cards that continue nothing:</p>

{plate("""      TABLE            1            L
                       2             '0099908006001499100060'
                       2             '0199912009002499150090'
                       2             '0299915012003499200120'
                       2             '0399920015004499250150'
                       2             '0499930018006499300250'
                       2             '0799930035099999300500'""")}

<p class="cite">{link(VERB_CT, "176-182", "f-payroll.ct:176-182")}</p>

{figure(
    "crop-10001-10007.png",
    "Seven lines of the 1960 machine listing: serial 10001 TABLE at level 1 "
    "with justification L, then serials 10002 to 10007 each at level 2 with a "
    "quoted digit string.",
    "Serials 10001 to 10007, cut from"
    " <code>comtran-manuals/F28-8043/images/page-109.png</code>. The level"
    " column reads <code>2</code> on each constant line; a continuation card"
    " carries no level.",
)}

{figure(
    "crop-table-lit.png",
    "The same six constant lines at high magnification, each digit string "
    "opening and closing with a quote mark.",
    "The same six lines enlarged: each string opens and closes with its own"
    " quote mark, so each is a separate literal of 22 characters. Six times 22"
    " is 132, which is where the row's figure came from — but that is not one"
    f" 132-character literal ({link(NOTES, '87-91', 'f-payroll-deck-notes.md:87-91')}).",
)}

<p>The scan outranks the definition (CLAUDE.md sections 7 and 9), so this is a
rank-governed correction, not a collision. It surfaced while this record was
written, after the branch was committed, so chunk 2b makes it beside the two
rows above.</p>

<h3>The conversion's own note still waits for Jack</h3>

<p>§9.7 is corrected, but the transcription of PDF p. 217 still carries the note
that the printer carried "the last few amount fields of a detail or totals line
on the print position immediately above the identifying line", and still assigns
those fields to the row above. A conversion is read-only and needs Jack's
authorization, so that erratum candidate — item 2 of the review record of
2026-09-13 — stays open
({link(HANDOVER, "296-308", "HANDOVER.md:296-308")}).</p>

<h3>Jack's answer, 2026-09-14</h3>

<div class="answer">
<p><strong>Both conversions are authorized.</strong> Jack answered on
2026-09-14, in these words: &ldquo;Both errata authorised&rdquo;. The answer
covers the F conversion's note after the page-100 form, which the correction at
the foot of this record opened, and the J conversion's note on PDF p. 217, which
the subsection above leaves open.</p>

<p>The page-100 note landed on 2026-09-14, in commit <code>a68e185</code> on
branch <code>errata-p217-table</code>, pull request 136. The note now reads
serials 02 to 07 as six unnamed level-2 entries. Each entry carries its own
quoted 22-character literal, and the form's continuation column is empty on all
six. TABLE.ITEM at serial 08 lays its twelve 11-character entries over the 132
characters the six literals occupy.</p>

<p>The p. 217 note landed the same day, in commit <code>c023111</code> of the
same pull request. Item 2 of the review record of 2026-09-13 carries that
answer. The reflow of the report blocks opened a new erratum candidate on three
cells, and that candidate waits for Jack.</p>
</div>
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
.itemhead { display:flex; gap:.75rem; align-items:baseline; flex-wrap:wrap;
            margin-bottom:.35rem; }
.item { border-top:1px solid var(--rule); padding-top:1.3rem; }
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
footer { border-top:1px solid var(--rule); padding-top:1rem; font-size:.85rem;
         color:var(--muted); }
"""

HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>M6 stage 2, chunk 2a: the 1960 corpus and the course of chunk 2b</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<p class="eyebrow">Review record · M6 stage 2, chunk 2a · evidence 2026-09-14 · head {RECORD_HEAD}</p>
<h1>M6 stage 2, chunk 2a: the 1960 corpus and the course of chunk 2b</h1>
</header>

<section class="answer">
<h2>The answer</h2>
<ol>
<li><strong>DECIDED.</strong> Chunk 2b applies the remaining divergence rows in
the 1962 sample's own form: arithmetic staged in WORKING, the master's numerics
retyped internal-decimal in a binary file, a dedicated error record and a plain
<code>FILE</code>, 24 per-field constants, explicit MOVEs, INDEX in WORKING.
Recovering the 1960 shapes instead is a parked stage of its own.</li>
<li><strong>DECIDED.</strong> The applied deck takes exactly five front-end
divergences: an environment division in J's order, CALL old names qualified,
<code>STOP RUN</code>, GRAND.TOTAL written out, the bare REDEF card.</li>
<li><strong>DECIDED.</strong> Stage 2 is chunked, its input is not the 1962
sample's tapes, and its oracle is the values the sample's report prints, not its
bytes. Both listing goldens take a fixed page head.</li>
<li><strong>SETTLED.</strong> The verbatim 1960 deck draws 55 diagnostic
messages of 12 kinds and one refusal: the compiler's first diagnostic corpus.
Three observations recorded, none a defect.</li>
<li><strong>SETTLED.</strong> A seventh codegen defect: a table item that is not
a whole number of words strides too short, silently. Found by this corpus, not
fixed here; no run reaches it.</li>
<li><strong>SETTLED.</strong> The language definition's §9.7 is corrected and
five divergence rows added. Chunk 2b owes two more rows and one correction, and
the read-only conversion's own note still waits for Jack.</li>
</ol>
<p>No item waits for Jack. Every one is DECIDED or SETTLED, so silence lets each
stand, and he can overturn any of them.</p>
<p><strong>Provenance.</strong> The work landed before this record existed: the
decks and goldens in commit <code>ae37940</code>, the design entries and the
definition rows in <code>2647141</code>, the decision of item 1 in
<code>{RECORD_HEAD}</code>. This record was built from all three in one
autonomous run — the route CLAUDE.md section 12 opens for a decision with one
viable option. It explains decisions made; it does not put a question.</p>
</section>

<section>
<p class="note"><strong>Citation forms:</strong> <code>J 05.06.01</code> cites
the 1962 processor manual, J28-6169, by IBM section code; <code>F p. 76</code>
the 1960 manual, F28-8043, by printed page. <code>D4.13</code> is a record on
the locked decision slate, <code>M6-7</code> an entry in the M6 acceptance
design record, <code>§9.8</code> a section of the language definition.
<code>166,00</code> is a message number, <code>131,00</code> a statement number.
“The verbatim deck” is the 1960 program as printed; “the applied deck” is the
same program with the five divergences of item 2.</p>
</section>
{ITEM1}{ITEM2}{ITEM3}{ITEM4}{ITEM5}{ITEM6}
<footer>
<p>Record built 2026-09-14 on branch
<code>review/2026-09-14-m6s2-f-corpus</code>. Every repository link points at
commit {RECORD_HEAD}, the head of branch <code>m6s2-f-corpus</code>, never at a
branch name. <code>tools/build_doc.py</code> writes this page; edit it, not the
HTML. <code>README.md</code> says what each directory holds. Chunk 2a lands as
one pull request on <code>m6s2-f-corpus</code>; it changes two files under
<code>test/goldens/</code>, so it merges on external-review convergence under
the charter. Opening it is under Jack's standing authorization of
2026-08-16.</p>
</footer>

</main>
<section id="correction"><h2>Correction</h2><p>Correction, 2026-09-14, appended after commit 1ca6711 on m6s2-f-corpus. Item 6 said chunk 2b owes the fix of the §9.8 “Table initialization” row. A crop of the page-100 form (images/page-105.png) shows serials 02 to 07 each at level 2 with their own quote marks and an empty CONT column, so the row is corrected in this pull request instead. The F conversion’s note that reads the six cards as one continued literal is a new erratum candidate in HANDOVER. M6-6’s card count now reads “187 source cards and two division headers”.</p></section>
<section id="correction-2"><h2>Correction 2</h2><p>Correction, 2026-09-14, appended after commit 14085fe on m6s2-f-corpus, the answer to round 1 of the external review. The Anthropic reviewer showed that the 1960 cards carry their serial in columns 1 to 5 (F p. 65: the digits “must be punched in each card”; J 02.02.01: the listing’s first column is the card sequence number), and the verbatim deck now punches them; the applied deck carries none, as a deck in the 1962 form. The seven CALL synonyms moved from column 40, the conversion’s spacing, to column 37, the scan’s. Item 2 and item 4 describe the deck as it was before that commit.</p></section>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
