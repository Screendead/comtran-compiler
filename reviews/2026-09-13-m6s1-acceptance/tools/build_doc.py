"""Assemble the M6 stage-1 review page.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: the fifteen crops are embedded as `data:`
URIs, so the file renders from any location with no network and no server.

Every repository link is built from the one commit hash below, so the record
outlives the branch it was written beside. Set `RECORD_HEAD` in the environment
to build the links from another commit.
"""

import base64
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

RECORD_HEAD = os.environ.get("RECORD_HEAD", "d5dd932")
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


def figure(name, alt, caption):
    """A crop, its alternative text and its caption."""
    return (
        "<figure>\n"
        f'<div class="scan"><img src="{crop(name)}" alt="{alt}"></div>\n'
        f"<figcaption>{caption}</figcaption>\n"
        "</figure>"
    )


def report(name, heading):
    """One report of a `--list-tapes` file in `evidence/`, as its lines."""
    lines = []
    keep = False
    with open(os.path.join(REC, "evidence", name)) as fh:
        for line in fh.read().splitlines():
            if line.endswith(" REPORT"):
                keep = line == heading
            elif keep and line:
                lines.append(line)
    return lines


# --- shared links ------------------------------------------------------

SAMPLE = "comtran-manuals/J28-6169/90.05-sample-program.md"
GENCODE = "comtran-manuals/J28-6169/90.02-generated-code.md"
M6 = "docs/design/m6-acceptance.md"
M4CODE = "docs/design/m4-codegen.md"
RUNTIME = "docs/design/runtime.md"
CODE = "test/goldens/90.05-payroll.code"
REPORT_GOLD = "test/goldens/90.05-payroll.report"
PAGE_READING = "test/fixtures/90.05-report-page-217.txt"
TAPES_NOTES = "test/fixtures/90.05-tapes-notes.md"
DECK = "test/fixtures/90.05-payroll.ct"
ACCEPT = "test/acceptance_test.dart"
TAPES_TEST = "test/sample_tapes_test.dart"
MACHINE_TEST = "test/runtime/machine_test.dart"
PROTOCOL_TEST = "test/runtime/movpak_protocol_test.dart"
GENERATOR = "tool/generate_sample_tapes.dart"
SOURCE_TABLE = "tool/sample_tapes_source.dart"

# --- 1 -----------------------------------------------------------------

OURS = report("90.05-payroll.report", "PAYFILE REPORT")
PAGE = report("90.05-report-page-217.txt", "PAYFILE REPORT")


def marked(lines, cell):
    """The block, with the grand-total cell marked."""
    body = list(lines)
    body[-1] = body[-1].replace(cell, f"<mark>{cell}</mark>")
    return plate("\n".join(body))


ITEM1 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>1 · The run reproduces the page up to four findings</h2></div>

<p>The sample compiled from its deck, loaded, and ran over the two reconstructed
tapes. It wrote five output tapes. Four of them carry a report, and the page
prints those four. The run prints 22 check lines, 19 PAYFILE lines, one bond
order and 17 error lines.</p>

<h3>The PAYFILE block, ours and the page</h3>

<p>Our report first
({link(REPORT_GOLD, "28-46", "90.05-payroll.report:28-46")}):</p>

{marked(OURS, "2183.83")}

<p>Then the reading of the page
({link(PAGE_READING, "12-30", "90.05-report-page-217.txt:12-30")}):</p>

{marked(PAGE, "2180.63")}

<p>Eighteen of the 19 lines are identical, character for character. The marked
cell is the only difference, and item 4 holds it.</p>

<h3>The other three reports</h3>

<table>
<tr><th>Report</th><th>Ours</th><th>The page</th><th>Result</th></tr>
<tr><td>CHECKFILE</td><td>11 checks, 22 lines</td><td>3 checks, 6 lines</td>
<td>The three the page prints are our last three, identical</td></tr>
<tr><td>BONDORDERFILE</td><td>1 order</td><td>1 order</td>
<td>Identical but one letter: <code>WOO J</code> against <code>WCO J</code></td></tr>
<tr><td>ERRORFILE</td><td>17 lines</td><td>17 lines</td>
<td>Identical</td></tr>
</table>

<p>The page prints its CHECKFILE block under the heading "CHECKFILE REPORT
(partial)". Nothing on the page stands for the eight checks it omits.</p>

<h3>The four findings</h3>

<table>
<tr><th>#</th><th>The difference</th><th>Class</th><th>Item</th></tr>
<tr><td>1</td><td>RET.PREM equals INS.PREM on every line, here and on the
page</td><td>The 1962 processor's defect, corroborated by its own
output</td><td>3</td></tr>
<tr><td>2</td><td>The grand-total net pay: 2183.83 here, 2180.63 on the
page</td><td>Not settled. Evidence exists and is sealed until M7
(D0.9)</td><td>4</td></tr>
<tr><td>3</td><td>The bond order's name: <code>WOO J</code> here,
<code>WCO J</code> on the page</td><td>A print artifact of the
page</td><td>5</td></tr>
<tr><td>4</td><td>The bond order's employee number printed as six zeros in our
first run</td><td>Ours, fixed</td><td>6</td></tr>
</table>

<p>Three tests carry the result, and 1308 tests pass.
{link(TAPES_TEST, None, "sample_tapes_test.dart")} regenerates the two tape
images and compares the bytes. The 90.05 group of
{link(MACHINE_TEST, None, "machine_test.dart")} runs the sample and compares
what <code>--list-tapes</code> prints with the golden.
{link(ACCEPT, "38-70", "acceptance_test.dart:38-70")} compares the golden with
the reading of the page, report by report. It passes only at the differences
above. A new difference fails it, and so does the disappearance of a recorded
one. M6-4 holds the record ({link(M6, "143-192", "m6-acceptance.md:143-192")}).</p>
</section>
"""

# --- 2 -----------------------------------------------------------------

ITEM2 = f"""
<section class="item needs">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>2 · Authorize the erratum: the stagger note on PDF p. 217</h2></div>

<p>The reading of the page is settled. The scan outranks a manual conversion
(CLAUDE.md section 9), and M6-2 records the reading
({link(M6, "50-105", "m6-acceptance.md:50-105")}). What waits for Jack is
narrower: the conversion is read-only, and only he authorizes a change to it
(CLAUDE.md section 9). Nothing in this pull request touches the conversion.</p>

<h3>The evidence</h3>

<p>Here is the PAYFILE block as the scan holds it. Each line rises to the right.
The right-hand amount fields of a line therefore stand level with the row above
its left-hand text:</p>

{figure(
    "payfile-raw.png",
    "The PAYFILE block of the printed report, cut from the page scan without "
    "rotation. Every line of print rises to the right across the block.",
    "The PAYFILE block, cut from <code>page-217.png</code> at its own scale,"
    " no rotation. The rise is about one line height across the block width.",
)}

<p>Here is the same box, after the page is rotated &minus;1.83 degrees about its
centre. That is the angle item 7 measures. Every line now sits on one row:</p>

{figure(
    "payfile-deskewed.png",
    "The same PAYFILE block after the page is rotated minus 1.83 degrees. "
    "Each line of print now sits on one horizontal row.",
    "The same box of the same page, rotated &minus;1.83&deg; about the page"
    " centre with bicubic resampling. The first line reads"
    " <code>01 1010 BLUT H … 2.00 2.00 112.20</code> and its bond denomination"
    " is blank.",
)}

<h3>What the conversion says</h3>

{quote(
    "<p>The illustrative run of the sample program (source listed on the"
    " preceding pages) produced the following output. Column headings were not"
    " printed by the sample program; figures are reproduced exactly as printed,"
    " including the printer's practice of carrying the last few amount fields"
    " of a detail or totals line on the print position immediately above the"
    " identifying line.</p>",
    "J 90.05 (" + link(SAMPLE, "1877", "90.05-sample-program.md:1877") + ")",
)}

<p>No such printer practice exists. The sentence describes a skew, and the code
block below it carries the skew into the text. Here are its first five
lines:</p>

{plate("""PAYFILE REPORT

                                                              2.00    2.00    112.20
01 1010 BLUT H          10-06-61   40.0    136.00   19.80   0.00           2.00    2.00    112.20    0.00
         DEPARTMENT 01 TOTALS      40.0    136.00   19.80   0.00   0.00    3.00    3.00     80.60""")}

<p class="cite">{link(SAMPLE, "1882-1886", "90.05-sample-program.md:1882-1886")}</p>

<p>The first row of amounts belongs to no line at all. BLUT H's line then takes
the amounts of the department 01 total, and the department 01 total takes
CASPERIAN's. Each line's own amounts sit one row above it, all the way down the
block.</p>

<h3>The arithmetic decides it</h3>

<p>Read along the baselines, BLUT H's line is
<code>40.0 136.00 19.80 0.00 2.00 2.00 112.20</code>. Net pay is gross less
every deduction:</p>

{plate("136.00 - 0.00 - 19.80 - 2.00 - 2.00 = 112.20")}

<p>The identity holds on all twelve detail lines and on all seven department
totals. Under the transcription's row assignment the first line has no net pay
to check, and the amounts above it belong to no line. The transcription's own
figures therefore refute its note.</p>

<h3>The request</h3>

<div class="ask">
<span class="label">Authorization asked</span>
<p><strong>(a)</strong> Remove the sentence about the printer's practice, from
"including" to "identifying line".</p>
<p><strong>(b)</strong> Reflow the code block under it, so each line's
right-hand amount fields sit on that line's own row.</p>
</div>

<div class="opt pick"><span class="name">Option 1 — authorize both. Recommended.</span>
<p>The conversion then says what the page says. A later reader who works from
the text gets the same lines the scan gives. Cost: one edit to a read-only
conversion, cited to the scan and to M6-2. To reverse it is one revert of one
file.</p></div>

<div class="opt"><span class="name">Option 2 — authorize (a) only.</span>
<p>The false claim goes, and the staggered block stays. A later reader sees
amounts on rows that own no line, with nothing to explain them. The gap is worse
than the wrong note, because the note at least warned the reader.</p></div>

<div class="opt"><span class="name">Option 3 — refuse, and leave a HANDOVER note.</span>
<p>The conversion keeps a claim the scan refutes. Every future reader of the
text must find M6-2 first. Nothing breaks in the code: the repository already
reads the scan. Cost: the erratum stays open, as it has since M4.</p></div>

<p>The recommendation is option 1. The evidence is closed, the two edits are
small, and both are reversible.</p>

<h3>Jack's answer, 2026-09-14</h3>

<div class="answer">
<p><strong>Authorized.</strong> Jack answered on 2026-09-14, in these words:
&ldquo;Both errata authorised&rdquo;. The answer takes option 1, both parts. It
also authorizes the second candidate, the note after the page-100 form of the
1960 manual, which the review record of 2026-09-14 raises.</p>

<p>The correction landed on 2026-09-14, in commit <code>c023111</code> on branch
<code>errata-p217-table</code>, pull request 136. The sentence about the
printer's practice is deleted, from &ldquo;including&rdquo; to
&ldquo;identifying line&rdquo;, and the note now states the skew. Both report
blocks are reflowed. Each line's fields now sit on that line's own baseline.</p>

<p>The reflow opened a new erratum candidate, which this authorization does not
cover. Deskewed, the page prints <code>0.00</code> in the FICA column of the
DEPARTMENT 09 TOTALS line, where the transcription reads <code>5.21</code>. The
GT line prints <code>5.21</code> in its FICA column and <code>36.00</code> in
its bond-deduction column. The transcription holds neither figure. The column
sums confirm all three cells. To key them changes values, not the note, so the
three cells are a new candidate. It is open in
<a href="https://github.com/Screendead/comtran-compiler/blob/c023111/docs/HANDOVER.md"><code>docs/HANDOVER.md</code></a>
and it waits for Jack.</p>
</div>
</section>
"""

# --- 3 -----------------------------------------------------------------

ITEM3 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>3 · RET.PREM equals INS.PREM: the 1962 processor's own defect</h2></div>

<h3>What the page prints</h3>

{figure(
    "prem-columns.png",
    "The insurance-premium and retirement-premium columns of the PAYFILE "
    "block. The two values are equal on every line.",
    "The INS.PREM and RET.PREM columns of the PAYFILE block, deskewed frame,"
    " 2&times;. The pair is equal on all twelve detail lines, on all seven"
    " department totals, and on the GT line.",
)}

<h3>What the source says</h3>

<p>The program looks both premiums up in one table. Each row holds a rate, an
insurance premium and a retirement premium, and the two premiums differ in every
row. Three rows of the twelve, from the generated mirror of the canon deck:</p>

{plate("""                       2           IR9(5) '00999'
                       2             '080060'
                       ...
                       2           IR9(5) '03499'
                       2             '200120'
                       ...
                       2           IR9(5) '99999'
                       2             '300500'""")}

<p class="cite">{link(DECK, "151-152", "90.05-payroll.ct:151-152")},
{link(DECK, "161-162", "90.05-payroll.ct:161-162")} and
{link(DECK, "173-174", "90.05-payroll.ct:173-174")}. The redefinition names the
three fields <code>RATE</code>, <code>INSPREM</code> and <code>RETPREM</code>
({link(DECK, "176-179", "90.05-payroll.ct:176-179")}).</p>

<p>BLUT H's rate is 3.400 an hour, which falls in the <code>'03499'</code> row.
That row gives an insurance premium of 2.00 and a retirement premium of 1.20.
The page prints 2.00 and 2.00.</p>

<h3>Why the object program does that</h3>

<p>The lookup builds one pointer word for each premium. Both start from a base
word, and the two base words are the same word:</p>

{figure(
    "lookup-p213.png",
    "The compiled lookup at locations 01421 to 01432, with the two EQU lines "
    "for GN)091 and GN)093 above it.",
    "LOC 01417 to 01432, PDF p. 213. <code>GN)091 EQU CP)+38</code> and"
    " <code>GN)093 EQU CP)+39</code> print their locations 01742 and 01743."
    " Each pointer is POS &times; <code>CP)+13</code> plus a base word:"
    " <code>ADD GN)091 / STO PI)3</code>, then"
    " <code>ADD GN)093 / STO PI)2</code>.",
)}

{figure(
    "pool-p216.png",
    "The constant pool at locations 01740 and after. Locations 01742 and 01743 "
    "both print 0 00000 0 00134.",
    "The constant pool, PDF p. 216. <code>+38 PZE RETPREM-2</code> and"
    " <code>+39 PZE INSPREM-2</code> both print <code>0 00000 0 00134</code>:"
    " the same address, and a zero decrement on both. The decrement column is"
    " live on the same page: <code>+60 PZE INS.PREM,,3</code> prints"
    " <code>0 00003 0 00035</code>.",
)}

<p>Our generator reproduces both words
({link(CODE, "946-947", "90.05-payroll.code:946-947")}) and the whole lookup
({link(CODE, "770-779", "90.05-payroll.code:770-779")}), byte for byte.</p>

<p>The mechanism is plain. A table word holds three characters of insurance
premium and three of retirement premium. The two base words name the same word
and select no byte within it, because both decrements are zero. The two step
lists that read the pointers are identical as well, word for word:</p>

{plate("""01440  TXI     SYS)185,1,4        01457  TXI     SYS)185,1,4
01441  OCT     000004000003       01460  OCT     000004000003
01442  TXI     SYS)212,1,3        01461  TXI     SYS)212,1,3
01443  TXI     SYS)193,1,3        01462  TXI     SYS)193,1,3
01444  TXI     SYS)225,1,6        01463  TXI     SYS)225,1,6""")}

<p class="cite">The insurance move at LOC 01440 to 01444 and the retirement move
at LOC 01457 to 01463, PDF p. 213
({link(SAMPLE, "1640-1663", "90.05-sample-program.md:1640-1663")}). Each list
converts the first three characters of the word its pointer names.</p>

<p>Both moves therefore read the first three characters, which are the insurance
premium. The 1962 processor compiled <code>RETPREM (POS)</code> as
<code>INSPREM (POS)</code>. Every net pay on the page subtracts the insurance
premium twice.</p>

<h3>What changed in the design record</h3>

<p>M4-20 (a) read the pool words in 2026-08-05 and drew the wrong consequence
from them:</p>

{quote(
    "<p>The EQU'd subscript-base words are therefore byte-blind; the byte"
    " selection lives in the generated lookup code, and the pool prints the two"
    " identical words.</p>",
    link(M4CODE, "973-976", "m4-codegen.md:973-976"),
)}

<p>The amendment withdraws that clause
({link(M4CODE, "978-983", "m4-codegen.md:978-983")}). No byte selection exists
anywhere. The pool words stay as printed, the lookup stays as printed, and the
object golden does not move.</p>

<p>This is the first artifact of the project that shows a defect of the 1962
compiler in the output of a compiled program. Every earlier finding showed one
in the text the compiler printed. What the 1963 processor did here is inside the
sealed archive
of D0.9. The seal ends when M7 opens, and the defect is one thing to look
for.</p>
</section>
"""

# --- 4 -----------------------------------------------------------------

ITEM4 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>4 · The grand-total net pay: the page says 2180.63, its own columns say
2183.83</h2></div>

<h3>The evidence</h3>

{figure(
    "gt-net.png",
    "The net-pay cell of the grand-total line, magnified six times. It reads "
    "2180.63, under the department-09 total 1340.39.",
    "The net-pay cell of the GT line, raw frame, 6&times;. It reads"
    " <code>2180.63</code>, under the department 09 total"
    " <code>1340.39</code>. The glyphs are unambiguous.",
)}

<h3>The page disagrees with itself</h3>

<p>The seven department net-pay totals are on the page. They sum to 2183.83:</p>

{plate("112.20 + 80.60 + 174.28 + 236.52 + 74.08 + 165.76 + 1340.39 = 2183.83")}

<p>The GT line's own columns give the same figure. Net pay is gross less every
deduction, and every one of those cells is on the page:</p>

{plate("2730.39 - 449.35 - 5.21 - 36.00 - 28.00 - 28.00 = 2183.83")}

<p>Every other cell of the GT line is the sum of the column above it. This one
cell is 3.20 below both figures the page itself supplies. Our run prints
2183.83.</p>

<h3>What this is, and what it is not</h3>

<p>Our object program is the 1962 listing, byte for byte. The same object text
ran in 1961 and produced this page. The difference is therefore in the 1961
runtime library, or in something the page does not show. The manuals cannot say
which, and no reading of them will settle it.</p>

<p>Evidence exists and is sealed until M7 (D0.9). The record says that, rather
than that no evidence survives.</p>

<p>Nothing is asked. The acceptance test pins the difference in both directions
({link(ACCEPT, "38-50", "acceptance_test.dart:38-50")}), so the record cannot
rot: a run that stops printing 2183.83 fails, and so does a page reading that
stops printing 2180.63.</p>
</section>
"""

# --- 5 -----------------------------------------------------------------

ITEM5 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>5 · The reconstruction's chosen values</h2></div>

<p>The input tapes do not survive. The report fixes a master field through the
statements that print it, and the rest is chosen. M6-3 holds the rule
({link(M6, "109-139", "m6-acceptance.md:109-139")}) and
{link(TAPES_NOTES, None, "90.05-tapes-notes.md")} holds the derivation of every
field and the table of all 25 masters and 14 details. Eleven masters match a
detail, 14 do not, and three details match no master.</p>

<h3>Derived, and needing no decision</h3>

<p>Five fields follow from the page by arithmetic: the number and name, the rate
as gross divided by hours, the exemptions from the withholding tax, the bond
deduction, and WOO's bond denomination. A FICA year to date that prints 0.00 is
144.00 exactly, because statement 213 caps the master at 144.00. DORR's 2.01
fixes his own at 141.99.</p>

<h3>Decided, with the alternative and its cost</h3>

<h4>The two ERRORFILE names are keyed as the ink reads: <code>MOCRE J</code> and
<code>MOCRE D</code></h4>

{figure(
    "errorfile-mocre.png",
    "The whole ERRORFILE block of the page. Two names print MOCRE, while "
    "BLOODSOE and JONES on the same block print a closed O.",
    "The ERRORFILE block, raw frame, 2&times;. <code>MOCRE J</code> and"
    " <code>MOCRE D</code> stand ten lines below <code>BLOODSOE F</code> and"
    " seven below <code>JONES F</code>, whose O glyphs are closed.",
)}

{figure(
    "mocre-glyphs.png",
    "The two MOCRE lines at six times magnification. The second letter of each "
    "name is a closed O and the third is open at the right.",
    "The same two lines, raw frame, 6&times;. In both names the second letter"
    " closes and the third is open at the right. The ink reads"
    " <code>MOCRE</code>.",
)}

<p>The likely intent is MOORE, and the same page bends an O to a C elsewhere.
Rejected all the same. Cost of the choice made: a later reader may think the
1961 data said MOCRE. Cost of the alternative: the fixture would carry a reading
the page does not show, and the acceptance diff would grow two artifact lines.
No second print of either name exists to compare, which is what separates this
case from the next one.</p>

<h4><code>WOO J</code> is the field; the bond order's <code>WCO J</code> is a
print artifact</h4>

{figure(
    "check-bond-woo.png",
    "The last check line and the bond-order line of the page. The check prints "
    "2WOO J with closed O glyphs; the bond order prints WCO J.",
    "The last check and the bond order, raw frame, 3&times;. The check prints"
    " <code>2WOO J</code> with two closed O glyphs. The bond order prints"
    " <code>WCO J</code>, whose middle glyph is open at the right.",
)}

{figure(
    "payfile-woo.png",
    "The PAYFILE line for employee 091980, printing the name WOO J with two "
    "closed O glyphs.",
    "The same NAME field on the PAYFILE line, raw frame, 4&times;:"
    " <code>09 1980 WOO J</code>. Two of the field's three prints say"
    " <code>WOO</code>.",
)}

<p>One master field prints three times on the page. Two prints say
<code>WOO</code>, so the field is <code>WOO J</code> and the third print is the
artifact. Rejected: keying the master as <code>WCO J</code>, which would then
misprint the other two lines and fail the acceptance diff twice over.</p>

<h4>The four chosen numbers</h4>

<table>
<tr><th>Field</th><th>Chosen</th><th>Why</th></tr>
<tr><td>CASPERIAN's FICA year to date</td><td>0.00</td>
<td>His 3.20 is the full three percent, so the cap never bites. Any value up to
140.80 prints the page. The least one is chosen.</td></tr>
<tr><td>WOO's bond accumulation</td><td>20.50</td>
<td>His order prints, so accumulation plus 17.00 reached 37.50. Any value from
20.50 to 37.49 prints the page. After the order the master holds 0.00.</td></tr>
<tr><td>SOBEK, REYNOLDS and WILLIAMS: denomination</td><td>18.75</td>
<td>Each deducts and orders nothing, so the denomination exceeds accumulation
plus deduction. 18.75 is the price of a $25 US savings bond in the period
(external: period fact, not from the manuals).</td></tr>
<tr><td>The same three: accumulation</td><td>0.00</td>
<td>The least value that orders nothing.</td></tr>
</table>

<h4>Everything the report never prints</h4>

<p>Zero or blank. DATE is blank, because statement 209 overwrites it with the
detail date before anything prints it. TRIGGERS is blank. The four year-to-date
totals for gross, retirement, insurance and withholding tax are zero: the
program adds to them and never prints them. An unmatched master is its number
and its name.</p>

<h4>A detail block is 14 words, not 3</h4>

<p>A detail record "occupies the first portion of tape blocks 14 words long"
({link(SAMPLE, "112-154", "90.05-sample-program.md, J 90.05.03")}). Each block
is therefore the three words of the record and eleven words of blanks, as a
card-to-tape pass leaves them. Rejected: 3-word blocks. Both read the same,
because the <code>*FILE</code> card's BLOCKSIZE 3 brings in three words either
way. 14 is what the manual describes.</p>

<h3>What an overturn costs</h3>

<p>Jack can overturn any value above. The cost is one edit to the table in
{link(SOURCE_TABLE, None, "sample_tapes_source.dart")}, a rerun of
{link(GENERATOR, None, "generate_sample_tapes.dart")}, and a rerun of the report
golden. Two tape images and one golden move. Nothing else does.</p>
</section>
"""

# --- 6 -----------------------------------------------------------------

ITEM6 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>6 · MOVPAK preserves index register 1 and consumes the trailing
<code>AXT</code></h2></div>

<h3>The symptom</h3>

<p>The page prints the bond order's employee number as <code>091980</code>. Our
first run printed <code>000000</code>.</p>

<h3>The object text</h3>

<p>Statement 221 loads MASTER's base into index register 1, and addresses
through that register 11 words later. The edited store of BONDENOMINATION stands
between the two:</p>

{plate("""01320  GN)080  LAC     BL)2,1
01321          TXL     SYS)294,1,0
01322          CAL     1)DATE,1
01323          SLW     5)DATE
01324          CLA     1)BONDENOMINATION,1
01325          TSX     SYS)180,4
01326          PZE     3)BONDENOMINATION,,0
01327          TRA     SYS)267,0,0
01330          OCT     000003000001
01331          AXT     5,1
01332          CAL     5)EMPLOYEE.NUMBER
01333          LDQ     1)EMPLOYEE.NUMBER,1""")}

<p class="cite">{link(CODE, "703-714", "90.05-payroll.code:703-714")}. The
golden is byte-identical to the 1962 print, so this is the 1962 object text.</p>

<p>Our MOVPAK cleared index register 1 at every entry, and returned to the
<code>AXT</code> for the CPU to execute. MASTER's base was then gone from the
register. M6-4 records the result
({link(M6, "183-189", "m6-acceptance.md:183-189")}):</p>

{quote(
    "<p>Our MOVPAK cleared the register at every entry and handed the"
    " <code>AXT</code> back to the CPU, so 01333 read address zero.</p>",
    link(M6, "186-189", "m6-acceptance.md:186-189"),
)}

<h3>What the manual prints</h3>

{figure(
    "sys267-p169.png",
    "The manual's entry for SYS)267: three lines of calling sequence, a TXI, "
    "an OCT and an AXT.",
    "J 90.02.30, PDF p. 169, 2&times;. The entry prints the"
    " <code>TXI</code>, the <code>OCT</code> and the <code>AXT</code> as one"
    " block of three lines. The <code>AXT</code> is a parameter word of the"
    " sequence, not an instruction for the CPU.",
)}

<h3>The decision</h3>

<p>A MOVPAK entry saves the incoming index register 1, and the end of the move
restores it. A call therefore preserves the register. The edited-store member
SYS)267 owns two data words, the <code>OCT</code> and the <code>AXT</code>, so
the resume lands past the <code>AXT</code> at LOC 01332.</p>

<p>RT-3 holds the word-shape table and the register contract
({link(RUNTIME, "354-366", "runtime.md:354-366")} and
{link(RUNTIME, "373-385", "runtime.md:373-385")}). RT-5 holds the SYS)267 rule
({link(RUNTIME, "740-747", "runtime.md:740-747")}).</p>

<h3>The rejected readings</h3>

<div class="opt"><span class="name">Reload the register in generated code before LOC 01333.</span>
<p>Wrong by construction. The object golden is byte-identical to the 1962 print,
so a generator change would move it away from the page. The 1961 run printed the
number from this object text, with no reload in it.</p></div>

<div class="opt"><span class="name">Restore the register, and still let the CPU execute the AXT.</span>
<p>Tried; it fails. The <code>AXT</code> overwrites MASTER's base with 5, so LOC
01333 no longer addresses the master record and the number still prints
zeros.</p></div>

<div class="opt"><span class="name">Consume the AXT, and do not restore the register.</span>
<p>Tried; it fails. The register stays 0 after the move, so MASTER's base is
gone again and the number still prints zeros.</p></div>

<div class="opt pick"><span class="name">Save at entry, restore at the end, and consume the AXT. Taken.</span>
<p>One reading satisfies the page, the manual's three-line print, and the object
text as printed.</p></div>

<h3>What pins it, and what it moved</h3>

<p>{link(PROTOCOL_TEST, None, "movpak_protocol_test.dart")} holds one case per
word shape. Each case preloads a sentinel into registers 1 and 2. It asserts the
sentinel comes back, and that the resume address lands past the
<code>AXT</code>.</p>

<p>Every other output tape of the sample is byte-identical before the change and
after it: C1, D2, D3 and D4. The bond order alone changes, and it changes from
six zeros to the number the page prints.</p>
</section>
"""

# --- 7 -----------------------------------------------------------------

ITEM7 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>7 · The columns were measured on the scan</h2></div>

<p>CLAUDE.md section 9 binds every claim about a card or print column to a
measurement of the page scan. The indentation of a transcription is not
evidence. <code>tools/scan/</code> holds the five scripts that did the work and
<code>evidence/results.txt</code> holds their residuals.</p>

<h3>The fit</h3>

<p>The whole page was rotated by one angle, &minus;1.83 degrees about its
centre. Each pasted block then took its own pitch and origin, fitted by snapping
every glyph centre of the block to an integer grid
(<code>tools/scan/measure.py</code>):</p>

<table>
<tr><th>Block</th><th>Pitch, px per column</th><th>Origin of column 1, px</th></tr>
<tr><td>PAYFILE</td><td>9.3314</td><td>340.90</td></tr>
<tr><td>CHECKFILE</td><td>9.360</td><td>338.84</td></tr>
<tr><td>ERRORFILE</td><td>9.3174</td><td>1089.80</td></tr>
</table>

<h3>Measured against the layout the record gives</h3>

<table>
<tr><th>Block</th><th>Item</th><th>Measured column</th><th>Expected</th><th>Result</th></tr>
<tr><td>PAYFILE</td><td>the department, <code>DEPT-D</code></td><td>10.98</td><td>11</td><td>match</td></tr>
<tr><td>PAYFILE</td><td>the hours, <code>40.0</code></td><td>38.04</td><td>38</td><td>match</td></tr>
<tr><td>PAYFILE</td><td>the gross, <code>136.00</code></td><td>46.02</td><td>46</td><td>match</td></tr>
<tr><td>PAYFILE</td><td>the withholding tax, <code>19.80</code></td><td>57.00</td><td>57</td><td>match</td></tr>
<tr><td>PAYFILE</td><td>the FICA, <code>0.00</code></td><td>67.02</td><td>67</td><td>match</td></tr>
<tr><td>PAYFILE</td><td>the insurance premium, <code>2.00</code></td><td>84.97</td><td>85</td><td>match</td></tr>
<tr><td>PAYFILE</td><td>the retirement premium, <code>2.00</code></td><td>93.98</td><td>94</td><td>match</td></tr>
<tr><td>PAYFILE</td><td>the net pay, <code>112.20</code></td><td>102.07</td><td>102</td><td>match</td></tr>
<tr><td>PAYFILE</td><td>the bond purchases, <code>0.00</code></td><td>114.02</td><td>114</td><td>match</td></tr>
<tr><td>CHECKFILE</td><td>the carriage control, <code>1</code></td><td>1.02</td><td>1</td><td>match</td></tr>
<tr><td>CHECKFILE</td><td>the employee number, <code>091977</code></td><td>40.01</td><td>40</td><td>match</td></tr>
<tr><td>CHECKFILE</td><td>the <code>$</code> of <code>$294.12</code></td><td>41.03</td><td>41</td><td>match</td></tr>
<tr><td>CHECKFILE</td><td>the last digit of <code>$294.12</code></td><td>46.90</td><td>47</td><td>match</td></tr>
<tr><td>ERRORFILE</td><td>the <code>M</code> of <code>M011001</code></td><td>1.02</td><td>1</td><td>match</td></tr>
<tr><td>ERRORFILE</td><td>the <code>D</code> of <code>D061500</code></td><td>0.97</td><td>1</td><td>match</td></tr>
<tr><td>BONDORDER</td><td>the first <code>0</code> of <code>091980</code></td><td>1.34</td><td>2</td><td>offset</td></tr>
<tr><td>BONDORDER</td><td>the <code>3</code> of <code>3750</code></td><td>25.48</td><td>26</td><td>offset</td></tr>
<tr><td>BONDORDER</td><td>the <code>1</code> of <code>100661</code></td><td>30.34</td><td>31</td><td>offset</td></tr>
</table>

<p>Every measured item of the three full blocks lands within a tenth of a column
of the layout. The BONDORDERFILE strip was pasted onto the page with an origin
of its own, a uniform 0.61 of a column off the CHECKFILE grid. Its internal
pitch is the CHECKFILE pitch, and its glyphs stand 24 and 29 columns apart,
which is where the layout puts them. Its column 1 cannot be measured, and the
record says so rather than inventing one.</p>

<h3>The plates</h3>

{figure(
    "pay-l1-wholeline.png",
    "The first PAYFILE line, deskewed, across the full width of the block. "
    "Every field sits on one row.",
    "The first PAYFILE line, deskewed frame, full block width. This is the"
    " line the transcription splits across two rows. Item 2 prints the raw"
    " view of the same block beside the deskewed one.",
)}

{figure(
    "check-294.png",
    "The amount field of a check, with a computed column ruler drawn over it. "
    "The dollar sign falls in column 41.",
    "The <code>$</code> of <code>$294.12</code> against the computed CHECKFILE"
    " ruler. It prints in column 41, next to its first digit, and column 40 is"
    " blank. The edited picture <code>$8889.99</code> floats its dollar sign to"
    " the first digit, which is what MOVPAK's edit does (RT-5).",
)}

{figure(
    "bond-left.png",
    "The left end of the bond-order line with the CHECKFILE ruler drawn over "
    "it. Every glyph falls about six tenths of a column left of a gridline.",
    "The bond order against the CHECKFILE ruler. Every glyph sits about 0.61"
    " of a column left of its line, which is the pasted strip's own origin and"
    " not a layout difference.",
)}

{figure(
    "error-M-line.png",
    "The first ERRORFILE line with its own column ruler drawn over it. The M "
    "falls in column 1.",
    "<code>M011001AJAX T</code> against the computed ERRORFILE ruler. The"
    " <code>M</code> prints in column 1. Every ERRORFILE line starts in one"
    " column.",
)}

<h3>What would mislead</h3>

<p>At page scale the right-hand amount fields look like they belong to the row
above. Item 2 prints that view, because a record that shows only the persuasive
plate is not a record. The transcription was written from that view, and its own
figures refute it.</p>
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
h4 { font-size:.95rem; margin:1.2rem 0 .3rem; font-weight:600; }
p, li { margin:0 0 .85rem; }
li:last-child { margin-bottom:0; }
ul, ol { padding-left:1.15rem; margin:0 0 .85rem; }
a { color:var(--ink); text-decoration-color:var(--rule); text-underline-offset:.16em; }
a:hover { text-decoration-color:var(--stamp); }
a:focus-visible { outline:2px solid var(--stamp); outline-offset:2px; border-radius:2px; }
code { font-family:var(--mono); font-size:.87em; background:var(--hair);
       padding:.08em .3em; border-radius:2px; overflow-wrap:anywhere; }
mark { background:var(--stamp-soft); color:var(--stamp); font-weight:700;
       padding:0 .1em; }
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
.scan { background:#fff; border:1px solid var(--rule); padding:.55rem;
        overflow-x:auto; }
img { max-width:100%; height:auto; }
.scan img { display:block; margin:0 auto; }
figcaption { font-family:var(--mono); font-size:.71rem; line-height:1.5; color:var(--muted);
             margin-top:.5rem; }
table { border-collapse:collapse; font-size:.92rem; margin:.6rem 0 1rem;
       font-variant-numeric:tabular-nums; width:100%; }
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
<title>M6 stage 1, the sample's acceptance</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<p class="eyebrow">Review record · M6 stage 1 · evidence 2026-09-13 · head {RECORD_HEAD}</p>
<h1>M6 stage 1, the sample's acceptance: the reconstruction, the page reading,
and the four findings</h1>
</header>

<section class="answer">
<div class="itemhead"><span class="chip done">Answered</span>
<h2>Jack's ruling, 2026-09-14</h2></div>
<p>Item 2 is authorized. Jack answered &ldquo;Both errata authorised&rdquo;, and
the correction of PDF p. 217 landed the same day, in commit
<code>c023111</code>, pull request 136. The full answer sits under item 2, with
the new erratum candidate the reflow opened. Item 2 keeps its
&ldquo;Your call&rdquo; chip: the record must show the question as well as the
answer. Everything below this banner is the record as Jack received it,
except the dated answer block appended under item 2.</p>
</section>

<section class="answer">
<h2>The answer</h2>
<ol>
<li><strong>SETTLED.</strong> The sample runs end to end over two reconstructed
tapes and reproduces the printed report of PDF p. 217, up to four findings. The
ERRORFILE is the page, all 17 lines. The three checks the page prints are the
last three of our eleven. Eighteen of the 19 PAYFILE lines are the page,
character for character.</li>
<li><strong>YOUR CALL.</strong> The transcription of PDF p. 217 describes a
printer practice that does not exist. The page is skewed. The reading is settled
by the scan; the authorization to edit a read-only conversion is Jack's
alone.</li>
<li><strong>SETTLED.</strong> RET.PREM prints equal to INS.PREM on every line,
on the page and in our run. The 1962 processor compiled the retirement lookup as
the insurance lookup. Its own output corroborates the defect.</li>
<li><strong>SETTLED.</strong> The page's grand-total net pay is 2180.63, and the
page's own columns give 2183.83. Ours prints 2183.83. The manuals cannot settle
it. Evidence exists and is sealed until M7 (D0.9).</li>
<li><strong>DECIDED.</strong> The reconstruction derives every field the report
fixes and chooses the least value that prints the page for the rest. Two names
are keyed as the ink reads.</li>
<li><strong>DECIDED.</strong> A MOVPAK call preserves index register 1, and the
edited store consumes its trailing <code>AXT</code> as a parameter word. Without
the rule the bond order prints six zeros for the employee number.</li>
<li><strong>SETTLED.</strong> Every column claim was measured on the scan, at a
fitted pitch of about 9.33 pixels a column, after one rotation of &minus;1.83
degrees.</li>
</ol>
<p><strong>Item 2 waits for Jack.</strong> Every other item is SETTLED or
DECIDED, so silence lets each one stand. No item blocks the pull request, and
the pull request touches no manual conversion.</p>
<p><strong>Provenance.</strong> The record was built after the code landed. The
design entries M6-1 to M6-5 were written first. A worker then implemented the
code against them. This record was built from both, in one autonomous run. No review
document existed before the code. That is the route CLAUDE.md section 12 opens
for a decision with one viable option. This document is the explanation of
decisions made, and one question.</p>
</section>

<section>
<p class="note"><strong>Citation forms:</strong> <code>J 90.02.30</code> is the
1962 processor manual by IBM section code. <code>F p. 42</code> is the 1960
manual by printed page. <code>PDF p. 217</code> is a page of the J28-6169 scan,
at <code>comtran-manuals/J28-6169/images/page-217.png</code>.
<code>(external: …)</code> marks period evidence that is not from the manuals.
<code>D0.9</code> is a decision record. <code>M6-4</code>, <code>M4-20</code>,
<code>RT-3</code> and <code>RT-5</code> are design-record entries.
<code>LOC 01333</code> is an object location in the 1962 listing.</p>
</section>
{ITEM1}{ITEM2}{ITEM3}{ITEM4}{ITEM5}{ITEM6}{ITEM7}
<footer>
<p>Record built 2026-09-13 on branch
<code>review/2026-09-13-m6s1-acceptance</code>. Every repository link above
points at commit {RECORD_HEAD}, a commit on the topic branch of M6 stage 1,
never at a branch name. <code>tools/build_doc.py</code> writes this page; edit
it, not the HTML. Set <code>RECORD_HEAD</code> in the environment to build the
links from another commit. <code>tools/cut_crops.py</code> cuts the eleven page
crops, and <code>tools/scan/</code> holds the five scripts that measured the
columns and drew the four overlay plates. <code>crops/</code> holds the fifteen
images the page embeds. <code>evidence/</code> holds the content brief, the
measurement residuals, the reading of the page and the report golden.
<code>evidence/README.md</code> says what each one is.</p>
</footer>

</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
