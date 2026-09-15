"""Assemble the M6 stage-2 review page for Jack's rule of 2026-09-14.

Run it from anywhere; it writes `index.html` into the record directory above
this one. The page is standalone: the five crops are embedded as `data:` URIs,
so the file renders from any location with no network and no server.

This record carries no repository hyperlink. The design entries it explains sit
on branch `m6s2-rule`, whose tip was not fixed when the record was built, and a
record may not point at a branch name. Every path below is given as a path, and
every quotation is printed in full, so the document stands on its own.
"""

import base64
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")


def quote(body, cite):
    """A block quotation and its citation line."""
    return f'<blockquote>{body}</blockquote>\n<p class="cite">{cite}</p>'


def plate(text, cite=None):
    """A monospace plate, for a card image or a listing excerpt."""
    block = f'<div class="plate"><pre>{text}</pre></div>'
    if cite:
        block += f'\n<p class="cite">{cite}</p>'
    return block


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


RULE = (
    "if it would compile in 1962, it should compile. If it wouldn't, it"
    " shouldn't. If it's ambiguous, I need to see it with argumentation both"
    " ways and a recommendation, and I'll make a call."
)

# --- 1 -----------------------------------------------------------------

ITEM1 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>1 &middot; The reading rule, and six verdicts</h2></div>

<p>Jack ruled on 2026-09-14, in conversation:</p>

{quote(f"<p>{RULE}</p>", "Jack, 2026-09-14")}

<p>The 1962 processor is the one J28-6169 describes. Two locked decisions
already carry that. <strong>D0.1</strong> makes J the target language:
&ldquo;The implemented language is J28-6169 (January 1962 field-test language).
F-only features are documented-but-unimplemented. Where F and J diverge, J
governs&rdquo;. <strong>D0.8</strong> makes the field-test compiler as attested
the reconstruction target: where J documents lenient behaviour, the default mode
reproduces it.</p>

<p>The code generator refuses six shapes of the 1960 payroll program. This item
answers the rule for all six. Each one compiled in 1962. The entry is M6-9 in
<code>docs/design/m6-acceptance.md</code> on branch <code>m6s2-rule</code>.</p>

<h3>The reading rule</h3>

<p>J names its two core sections after what they do to F:</p>

{plate(
    "## 02.04 Procedure Description Clarification and Amplification\n"
    "## 02.05 Data Description Amplification and Clarification",
    "The two section headings of"
    " <code>comtran-manuals/J28-6169/02-compiler.md</code>.",
)}

<p>Where J revokes an F form, it revokes it in words. This is the model:</p>

{quote(
    "<p>The verb is described incorrectly in the Commercial Translator General"
    " Information manual and the definition given in the last paragraph on page"
    " 39 of the manual should be replaced with:</p>",
    "J 02.07.04",
)}

<p>Appendix 90.01 is the enumerated list of what the field-test processor did
not do. Each item names itself. The COPY deferral reads in full:</p>

{quote("<p>Implementation of COPY has been deferred.</p>", "J 90.01.03 b.i")}

<p>So the rule reads: a form that F admits, that J does not contradict, and that
Appendix 90.01 does not defer, compiled in 1962.</p>

<h3>The reading against it, in full</h3>

<p>J's conditional-statement section states six rules. Every one of them is
about fields. The first reads:</p>

{quote(
    "<p>Comparisons may not be made between numeric and alphameric fields. If"
    " ABC is described as three position alphameric field (AAA) and DEF as a"
    " three position numeric field (999) the following IF statement represents"
    " an invalid comparison:</p>",
    "J 02.04.06 C.1",
)}

<p>The other five govern unequal lengths, edited fields, non-format fields,
variable length fields, and the sign of zero. None of the six names an
expression. J therefore never says that a comparand may be an expression.</p>

<p>The message catalogue carries a message that could be the diagnostic for
one:</p>

{plate("107,00     0    ILLEGAL COMPARISON STRUCTURE.", "J 90.04.01")}

<p>No text anywhere states what fires 107,00. On this reading J's silence
withdraws F's form, and the message is the proof that it does. The same
argument extends to the other five shapes: J restates none of them either.</p>

<h3>Why the reading against loses</h3>

<p>D0.1 settles it. An F-only feature is one that J withdraws, or one that
Appendix 90.01 defers. It is not one that J leaves unrestated. J restates very
little of F. Its own title is a clarification and an amplification, not a
replacement. Under the reading against, F's MOVE, its record structure, its
files and its DO verb would all fall with the expression comparand, because J
restates none of them either. Almost nothing of the language would survive.</p>

<p>We therefore reject it. Jack can take it instead. Item 3 states what that
costs.</p>

<h3>The six verdicts</h3>

<p>Each verdict names a sentence of the applied deck,
<code>test/fixtures/f-payroll-j.ctd</code>. The statement numbers are the
listing's, after the STOP correction of item 4. Each refusal site is in
<code>lib/src/codegen/procedure.dart</code>.</p>

<h3>1. Arithmetic on external-decimal record fields</h3>

<p>M6-9 gives this shape no single statement number, because the shape is every
arithmetic sentence of the program. The first in source order is statement
141,00:</p>

{plate(
    "141,00   71421 COMPUTE.PAY.  IF DETAIL HOURS IS GREATER THAN 40 THEN SET DETAIL\n"
    "                      GROSS = (DETAIL HOURS - 40) * MASTER RATE * 1.5.",
    "<code>test/goldens/f-payroll-j.listing</code>. DETAIL GROSS, DETAIL HOURS"
    " and MASTER RATE are all bare pictorials in records, so all three are"
    " external decimal.",
)}

<p>The decisive quotation:</p>

{quote(
    "<p>The operands of a SET instruction which are used in an arithmetic"
    " expression may be fields of any format except alphameric (the result"
    " field may be alphameric, however, and a statement of the form SET"
    " alpha.field.1 = alpha.field.2 is allowed since no arithmetic expression"
    " is specified). Appropriate conversion is performed in all cases although"
    " arithmetic operations are considerably less efficient when performed on"
    " fields having dissimilar formats.</p>",
    "J 02.04.05 #6",
)}

<p>External decimal is a format, and it is not alphameric. J does not merely
permit the shape. It prints it as good practice. Its worked example on
efficiency declares six fields, and only one of them is internal:</p>

{figure(
    "j-p015-data-desc.png",
    "Six data description lines: A, B, C, D and E each at level 01 with a bare"
    " pictorial of 999 or 99, and X at level 01 with the pictorial IR999.",
    "The worked example's Data Description, cut from"
    " <code>comtran-manuals/J28-6169/images/page-015.png</code>, box"
    " (220, 1200, 830, 1445), enlarged two times. A to E carry no mode letter,"
    " so each is external decimal. X alone carries IR, internal right"
    " justified.",
)}

{figure(
    "j-p016-set-sequences.png",
    "The two numbered examples: sequence 1 rewrites SET A = B+C and SET D = A+E"
    " as SET X = B+C and SET D = X+E; sequence 2 rewrites SET A = B+C and"
    " SET D = B+E as MOVE B to X, SET A = X+C and SET D = X+E.",
    "The two SET sequences, cut from"
    " <code>comtran-manuals/J28-6169/images/page-016.png</code>, box"
    " (370, 235, 1130, 835), enlarged two times. The improved form of example 2"
    " still reads <code>SET A = X+C</code>, and A is external. J rewrites the"
    " sequence for speed and keeps an external result field.",
)}

<p>The definition already records what the shape costs at object time:
&ldquo;Every reference to an external-mode operand implies an unpack-and-convert
at object time; every store into an external or edited target implies a
convert-and-edit&rdquo; (definition &sect;4.2.1). The generated members are
attested. A fetch reads the field through SYS)181 or SYS)182 (J 90.02.14).
SYS)184 converts it (J 90.02.16). A store writes it back through SYS)180 with
SYS)186, SYS)187 or SYS)188 (J 90.02.18). Here are the three store
converters:</p>

{figure(
    "j-p157-sys186-188.png",
    "Three appendix entries. SYS)186 converts internal decimal in the AC or"
    " AC-MQ to unsigned external decimal; SYS)187 to external decimal with"
    " overpunch minus; SYS)188 to external decimal with overpunch plus. Each"
    " takes one operand, NUMBER-OF-CHARACTERS-TO-DEVELOP.",
    "SYS)186 to SYS)188, cut from"
    " <code>comtran-manuals/J28-6169/images/page-157.png</code>, box"
    " (110, 220, 1140, 610), enlarged two times. Each entry carries one"
    " parameter and no overflow test step. That gap is the one open point"
    " chunk 2b must decide.",
)}

<p>Appendix 90.01 defers nothing here. The one message that could reject an
operand names a format and not a shape:</p>

{plate(
    "25,00     0    OPERATION IGNORED BECAUSE 'NAME.1' HAS IMPROPER DATA FORMAT",
    "J 90.04.01. The only format J excludes from an arithmetic expression is"
    " alphameric (J 02.04.05 #6).",
)}

<p><strong>The refusal site.</strong> <code>_decimal</code> rejects any operand
class but internal decimal:</p>

{plate(
    "_unruled(\n"
    "  'an arithmetic operand of ${fieldClass.name} (no sample instance)',\n"
    ");",
    "<code>lib/src/codegen/procedure.dart</code>, in"
    " <code>_decimal</code>. For this program the class is"
    " <code>externalDecimal</code>.",
)}

<p><strong>Two things stay open</strong>, and neither touches the verdict. The
overflow behaviour of SYS)186 to SYS)188 is unstated, because the three entries
carry no test step. Rounding is definition &sect;8.5.4-a.</p>

<h3>2. <code>FILE record IN file</code></h3>

{plate(
    "131,00   71406 HIGH.DETAIL.  MOVE 'M' TO MASTER ERRORCODE, FILE MASTER IN\n"
    "                      ERROR.FILE.",
    "<code>test/goldens/f-payroll-j.listing</code>. This is where the run"
    " stops: a job halts at its first refusal.",
)}

{quote(
    "<p><strong>b) FILE record.name IN file.name</strong></p>"
    "<p>This form of the verb provides a means of filing a record in a specific"
    " file when the record.name is associated with several output files.</p>",
    "J 02.07.08 b",
)}

<p>The section's own condition asks that the record be associated with the file
in the Environment Description: &ldquo;In using either form of the FILE command
the record.name must be associated in the Environment Description with the
name(s) of the file(s) into which it is to be filed&rdquo; (J 02.07.08). The
applied deck's ERROR.FILE card lists MASTER, DETAIL and BONDORDER, so the
condition holds.</p>

<p><strong>The refusal site.</strong> The <code>inFile</code> guard of
<code>_file</code>:</p>

{plate(
    "void _file(FileClause clause) {\n"
    "  if (clause.inFile != null) {\n"
    "    _unruled('FILE record IN file (no sample instance)');\n"
    "  }",
    "<code>lib/src/codegen/procedure.dart</code>.",
)}

<p>Each of the three records has one output file, so the code this shape has to
emit equals the code for plain FILE.</p>

<h3>3. INDEX inside a record</h3>

{plate(
    "144,00                 DO SEARCH FOR INDEX = 1(1)12.",
    "<code>test/goldens/f-payroll-j.listing</code>. INDEX is declared"
    " <code>99</code> inside the RECORD CURRENT.",
)}

<p>J states no rule on where a subscript variable is declared. It asks only for
a Data Description entry:</p>

{quote(
    "<p>The name of each data field referenced in Procedure statements or"
    " Environment Descriptions must appear in the name field of a Data"
    " Description entry. Neither storage allocation nor assignment of data"
    " characteristics is made for data fields not so named.</p>",
    "J 02.05.01",
)}

<p>Appendix 90.01's indexing paragraph lists four cautions: avoid repeating a
subscript name, set an array's dimensions before its subscripts, expect a DO
section to run at least once, and expect no object-time bound check
(J 90.01.02 vi). None is about declaration.</p>

<p>The message that fires on this form concedes that the form works:</p>

{plate("206,00     0    'NAME.1' HAS INEFFICIENT FORMAT FOR SUBSCRIPT VARIABLE.", "J 90.04.01")}

<p>An inefficient format is a format that works. The 1962 sample's own INDEX is
<code>IR99</code> in WORKING, a level-1 group with no type code, so the sample
attests the mode and not the place.</p>

<p><strong>The refusal site.</strong> This shape folds into shape 1. M6-8 read
the refusal as a place test, and that line is corrected in M6-8 as amended.
<code>_decimal(indexItem)</code> fires first, on the mode. The place test that
follows it, <code>_located</code>, is false for CURRENT, because CURRENT sits on
no FILE card and has no base locator.</p>

<h3>4. A comparison whose sides are expressions</h3>

{plate(
    "152,00                 IF MASTER FICA + 0.03 * DETAIL GROSS IS LESS THAN 144.00\n"
    "                      THEN SET DETAIL FICA = 0.03 * DETAIL GROSS  OTHERWISE SET\n"
    "                      DETAIL FICA = 144.00 - MASTER FICA.\n"
    "\n"
    "156,00                 IF 13 * MASTER EXEMPTIONS IS LESS THAN DETAIL GROSS THEN\n"
    "                      SET DETAIL WHT = 0.18 * (DETAIL GROSS - 13 * MASTER\n"
    "                      EXEMPTIONS) OTHERWISE SET DETAIL WHT = ZEROS.",
    "<code>test/goldens/f-payroll-j.listing</code>: the FICA test and the"
    " withholding-tax test.",
)}

<p>F admits the form in terms, and prints an example of exactly this shape:</p>

{quote(
    "<p>These expressions may be used to connect data-names, literals, and"
    " arithmetic expressions. The following examples indicate typical uses of"
    " the relational expressions:</p>"
    '<div class="plate"><pre>BEGINNING.ON.HAND + RECEIPTS - SHIPMENTS IS\n'
    "  LESS THAN REORDER.POINT\n"
    "AGE GT 21\n"
    "A * (B + C) - (D / E) = 500\n"
    "DEPENDENTS NOT = 0\n"
    "A GT B OR A = C</pre></div>",
    "F p. 21",
)}

<p>J does not contradict it. Its six comparison rules are the field rules quoted
above. Its precedence table heads with TR, which is a condition inside an
expression (J 02.04.05.01 b), so J itself mixes the two categories. Appendix
90.01 defers nothing here. The definition's &sect;5.3.2 lists J's tightenings of
F, and operand shape is not among them.</p>

<p><strong>The refusal site.</strong> The default arm of the numeric
comparison, which fires when a side is neither a name nor a literal:</p>

{plate(
    "default:\n"
    "  _unruled('a comparison of ${acc.runtimeType}');",
    "<code>lib/src/codegen/procedure.dart</code>, in"
    " <code>_numericComparison</code>. The storage side carries the same arm.",
)}

<h3>5. A product of a product</h3>

{plate(
    "141,00   71421 COMPUTE.PAY.  IF DETAIL HOURS IS GREATER THAN 40 THEN SET DETAIL\n"
    "                      GROSS = (DETAIL HOURS - 40) * MASTER RATE * 1.5.",
    "<code>test/goldens/f-payroll-j.listing</code>. The same sentence as shape"
    " 1, refused for a second reason.",
)}

<p>J states the association rule and works the case:</p>

{quote(
    "<p>When there are two operators of the same hierarchy, ordering proceeds"
    " from left to right</p><p>For example, the expression</p>"
    '<div class="plate"><pre>A*B*C</pre></div><p>will be taken to mean</p>'
    '<div class="plate"><pre>(A*B)*C</pre></div>',
    "J 02.04.05.01 b. The conversion prints the two expressions as code blocks,"
    " so the sentence reads across them.",
)}

<p>F p. 107 rule 4 states the same. The 1962 sample avoids no shape here: above
40 hours its <code>(WORKING HOURS * 1.5 - 20) * MASTER RATE</code> folds the
1960 program's two sentences into one, which is item 6's third cause. Open
Question 28 asks about intermediate precision in the generated code, not about
legality.</p>

<p><strong>The refusal site.</strong> The product builder, when a factor is
itself a product:</p>

{plate(
    "_unruled('a product of a product (no sample instance)');",
    "<code>lib/src/codegen/procedure.dart</code>.",
)}

<h3>6. An edit run that drops high-order digits</h3>

{plate(
    "146,00                 ADD CORRESPONDING DETAIL TOTALS TO MASTER TOTALS, MOVE\n"
    "                      CORRESPONDING DETAIL TO PAYRECORD, CHECK, MOVE PAYRECORD\n"
    "                      NETPAY TO CHECK AMOUNT.",
    "<code>test/goldens/f-payroll-j.listing</code>. PAYRECORD NETPAY is"
    " <code>$88889.99-</code>, five integer digits. CHECK AMOUNT is"
    " <code>$***9.99</code>, four.",
)}

<p>F states the rule and works the row:</p>

{quote(
    "<p>The data from the sending area is aligned with respect to the decimal"
    " point (assumed or actual) in the receiving area. Such alignment may"
    " involve the dropping of leading digits or low-order digits (or both if"
    " the sending field is larger than the receiving one).</p>",
    "F p. 42",
)}

{plate(
    "Sending Pictorial   Sending Data   Receiving Pictorial   Receiving Data after MOVE\n"
    "99999               01234          999V9                 2340",
    "F p. 43, the fifth row of the editing table. The leading 0 and the digit 1"
    " are both dropped.",
)}

<p>The generated form is attested too. SYS)190's package counts characters to
test for overflow and characters to bypass (J 90.02.19), and at run time the
communication cell records the loss:</p>

{quote(
    "<p><strong>SYS)130</strong> This cell is set non-zero whenever any one of"
    " the numeric move or convert subroutines of MOVPAK detects the truncation"
    " of significant high order values (i.e. overflow).</p>",
    "J 90.02.10",
)}

<p>Definition &sect;8.5.4-b holds the same reading.</p>

<p><strong>The refusal site.</strong> The edit-step builder, when the source is
wider than the target on either side:</p>

{plate(
    "if (sourceInteger > targetInteger || s.fractionDigits > t.fractionDigits) {\n"
    "  _unruled('an edit run that bypasses source digits (no sample instance)');\n"
    "}",
    "<code>lib/src/codegen/procedure.dart</code>, in <code>_editSteps</code>.",
)}

<p>Its own comment says why: no attested site emits the overflow test or the
bypass steps, so the two step numbers the manual offers cannot be told apart.
The SYS)190 notes on
<code>comtran-manuals/J28-6169/images/page-158.png</code> may distinguish them,
and nobody has measured that page. The code and the comment stay as they are,
and chunk 2b carries the check.</p>

<h3>The refusals are stricter than the rule, by design</h3>

<p>The refusal class says so in its own words:</p>

{quote(
    "<p>A refusal of this recovery, not a diagnostic of the program.</p>"
    "<p>The sample never reaches the refusing site, so no generated shape is"
    " attested and none is invented (the notes, section 7). The 1962 compiler"
    " had code for the shape, so no J 90.04 message and no severity fits: the"
    " refusal rides outside the D10.2 stream, enters no sink and no listing.</p>",
    "The doc comment on <code>UnrecoveredShape</code>,"
    " <code>lib/src/codegen/procedure.dart</code>.",
)}

<p>A refusal asks whether the 1962 listing attests the generated form. It never
asked whether the 1962 processor compiled the source. Jack's rule asks the
second question. The two part company here for the first time, which is what
item 2 turns on.</p>

<p>This item is decided, not asked. Jack can overturn the reading rule, or any
one of the six verdicts, and silence lets each stand.</p>
</section>
"""

# --- 2 -----------------------------------------------------------------

ITEM2 = f"""
<section class="item needs">
<div class="itemhead"><span class="chip call">Your call</span>
<h2>2 &middot; Does &ldquo;compile&rdquo; mean the diagnostic listing or the
object deck?</h2></div>

<p>The rule turns on one word, and the verbatim 1960 deck is the case that
splits it. That deck is the program keyed as printed,
<code>test/fixtures/f-payroll.ctd</code>. Our front end prints 55 diagnostic
messages of 12 kinds and completes. Our generator then refuses its first GET.
Under J's letter the 1962 processor would have gone further: it would have
punched an object deck and refused to run it.</p>

<h3>What the manual says about severity</h3>

{quote(
    "<p>The Severity Codes (values) are numbered 1 through 5. The least severe"
    " errors have a code of 1. The most severe errors have a code of 5. The"
    " ascending sequence, 2, 3, and 4 indicates the degree of severity between"
    " the least and most severe errors, 1 and 5.</p>"
    "<p>An error severity code of 1 does not prevent the running of the object"
    " program immediately after compilation. Any code above 1 does prevent"
    " running of the object program immediately after compilation. That is, the"
    " compiler will not compile and go.</p>"
    "<p>An error severity code of 5 causes the compiler to stop compiling. It"
    " then proceeds to the next job.</p>",
    "J 90.04.02",
)}

<p>Only one value suppresses a deck, and it is the same value that stops the
compilation:</p>

{quote(
    "<p>Normally, an output deck is produced except when a severe error has"
    " been encountered during compilation. The severity value (code) is used to"
    " determine whether a deck will be produced when NODECK is not specified."
    " If the severity code is 5, a deck will not be produced.</p>",
    "J 02.01.01, on the CMPLE card's NODECK option",
)}

<p>Execution is a separate gate, and it is stricter:</p>

{quote(
    "<p>The program will be executed unless the NOGO option has been taken, or"
    " the Compiler has encountered a source program error with a severity code"
    " greater than 1 or an undefined symbol in the code which it has"
    " generated.</p>",
    "J 02.01.02, on the LOAD option",
)}

<p>No printed severity value survives for any message:</p>

{quote(
    "<p>In the following list of error messages the code number is '0' because"
    " the value may vary. One of the severity values 1 through 5 will actually"
    " be printed with the error message.</p>",
    "J 90.04.01",
)}

<h3>What the verbatim deck draws</h3>

<p>Twelve message kinds, 55 messages.
<code>evidence/f-payroll-listing-diagnostics.txt</code> holds the whole
block.</p>

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

<p>None of the twelve is worded as a stop, a deletion or a repair. J holds that
vocabulary and uses it elsewhere:</p>

{plate(
    "  2,00     0    -RUN- DELETED. ITS USE IS RESTRICTED TO PROCESSOR.\n"
    " 25,00     0    OPERATION IGNORED BECAUSE 'NAME.1' HAS IMPROPER DATA FORMAT\n"
    "171,00     0    NUMBER OF OPERATORS IN THIS SENTENCE EXCEEDS MAXIMUM OF 60.\n"
    "                SENTENCE DELETED FROM TEXT.",
    "J 90.04.01. Our own severities are D7.5's design decision, because no"
    " severity table survives (Open Question 65). In this listing they run 1 to"
    " 4 and never 5.",
)}

{plate(
    " 141,00    3    CONFLICT BETWEEN LEVEL AS GIVEN BY ORIGINAL DEFINITION AND -REDEF-.\n"
    " 141,00    2    CONFLICT BETWEEN JUSTIFICATION AS GIVEN BY ORIGINAL DEFINITION AND -REDEF-.\n"
    "\n"
    "SEVERITY LIMIT WAS NOT REACHED",
    "The foot of <code>test/goldens/f-payroll.listing</code>.",
)}

<h3>So under J's letter</h3>

<p>The 1962 processor compiled the 1960 deck as punched, punched an object deck,
and refused to run it. No evidence describes the code in that deck. What the
code had to cover is clear enough: a GET on a record bound to no file, 26
undefined names, and a GRAND.TOTAL left empty because COPY was deferred. Our
generator stops earlier:</p>

{plate(
    "a GET record on 0 input files (no sample instance)",
    "The refusal the corpus test pins, <code>test/f_corpus_test.dart</code>. No"
    " FILE card lists MASTER, so statement 3,00 has no input file.",
)}

<h3>The two arguments</h3>

<div class="opt"><span class="name">For the listing</span>
<p>The listing is the artifact our corpus reproduces, and a golden pins it byte
for byte. Chunk 2a already delivered it whole. The object deck cannot be
recovered at all. No evidence describes the code the 1962 processor generated
for a GET bound to no file, or for 26 undefined names, so to write that code is
to invent it, which D0.4 forbids. On this reading the refusal is a
correct statement about the program: the program had no runnable object form,
and the listing is what compiling it produced.</p></div>

<div class="opt"><span class="name">For the object deck</span>
<p>To compile in 1962 was to punch a deck. J 02.01.01 ties deck production to
the severity code alone, and our severities allow it. A compiler that stops
short of the deck has not compiled the program, whatever it printed on the way.
On this reading the refusal marks a gap in our recovery, not a property of the
program, and the label &ldquo;refused&rdquo; misdescribes what 1962 did.</p></div>

<div class="ask">
<span class="label">Your call</span>
<p>Does &ldquo;compile&rdquo; in your rule of 2026-09-14 mean the diagnostic
listing, or the object deck?</p>
</div>

<h3>The options, and what each costs</h3>

<div class="opt pick"><span class="name">Option 1. The listing. Recommended.</span>
<p>Keep the refusal and relabel it. The honest label is &ldquo;1962 punched a
deck whose content no evidence describes&rdquo;, not &ldquo;1962
refused&rdquo;. Take the listing as the deliverable of that compilation. What
breaks: nothing. What is left unbuilt: the object form of a program that could
never run. What a later reader is misled about: nothing, once the label is
corrected. To reverse it costs one edit to M6-9 and one to the corpus test's
comment.</p></div>

<div class="opt"><span class="name">Option 2. The object deck, and build it.</span>
<p>Treat the refusal as a gap and generate code for the verbatim deck. What
breaks: D0.4, which allows a recorded design decision where evidence is absent
but forbids presenting invention as historical fact. Generating a GET on a
record bound to no file has no evidence behind it at all, not even a shape to
record. What a later reader is misled about: the object deck would look like a
recovery and would be a guess. To reverse it costs the deletion of that code and
of its golden.</p></div>

<div class="opt"><span class="name">Option 3. The object deck, and raise a severity to 5.</span>
<p>Rule that one of the twelve messages carried severity 5 in 1962, so no deck
was punched and our refusal is right for the right reason. What breaks: nothing
in the code, but the claim is unattested. Open Question 65 records that no
severity table survives, and J 90.04.01 prints CODE 0 for every message. What a
later reader is misled about: a severity presented as recovered when it is
chosen. To reverse it costs one edit to the severity table and one golden
rebuild.</p></div>

<p>The recommendation is option 1. It states what the evidence supports and
invents nothing.</p>

<p><strong>No work waits on the answer.</strong> Chunk 2b works on the applied
deck, <code>test/fixtures/f-payroll-j.ctd</code>, which has an environment
division and whose GET binds to a file. The answer changes a label and a design
entry, not a line of the compiler.</p>
</section>
"""

# --- 3 -----------------------------------------------------------------

ITEM3 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>3 &middot; M6-8 is overturned in part: course B and the parked stage are
withdrawn</h2></div>

<p>M6-8 decided on 2026-09-14, before the rule, that chunk 2b would take course
B: rewrite the 1960 program into the 1962 sample's own form, staging its
arithmetic in a WORKING area of internal fields. It parked course A, recovering
the 1960 shapes, as a stage of its own with no schedule. Jack's rule of the same
date overturns that. Course A is the course. The parked stage is withdrawn and
becomes the next task in <code>docs/HANDOVER.md</code>.</p>

<p>The reason is item 1. All six shapes compiled in 1962. Course B replaces each
of them with a form the sample used, so course B rewrites source that the 1962
processor accepted. The rule forbids that in terms: if it would compile in 1962,
it should compile.</p>

<h3>Where the reasoning went wrong</h3>

<p>The roadmap's words for stage 2 decided course B. It names the second corpus
as F's payroll example &ldquo;with the documented F/J divergences applied&rdquo;.
Those words were read broad, as every row of the definition's &sect;9.8 table.
The rule reads them narrow: apply the rows that 1962 forces, and record the
rest. The narrow reading costs nothing in fidelity, because the definition
already states what an unapplied row costs at object time, which is an
unpack-and-convert and nothing else (&sect;4.2.1).</p>

<p>Two rows are now recorded and not applied: the overtime formula, and the
master's numeric typing. &sect;9.8 carries both, added on branch
<code>m6s2-rule</code>.</p>

<h3>One line of the inventory is corrected</h3>

<p>M6-8 listed <code>DO SEARCH FOR INDEX = 1(1)12</code> as refused for &ldquo;an
index that is external and lives in a record&rdquo;. Only the first half is
true. The refusal that fires is the mode test, <code>_decimal</code>. The place
test, <code>_located</code>, is false for CURRENT, because CURRENT sits on no
FILE card and has no base locator. The line folds into the arithmetic line above
it, which is why item 1 gives six shapes and not seven.</p>

<h3>The two courses, and what each costs</h3>

<div class="scroll">
<table>
<tr><th>Course</th><th>What it builds</th><th>What it costs</th></tr>
<tr><td><strong>A. Recover the 1960 shapes.</strong> Taken.</td>
<td>External-decimal arithmetic from the convert members of J 90.02: SYS)184 in,
SYS)186 to SYS)188 out. Then <code>FILE record IN file</code>, the expression
comparison, the product chain, the SYS)190 bypass steps and the 11-character
table stride. The compiler gains the largest part of the language the 1962
sample never touches, and codegen defects 1 to 4 get live sites.</td>
<td>An order of magnitude more work than course B. Every piece is a recorded
design decision under D0.4 with no listing oracle behind it. It walks the
11-character table item straight into codegen defect 7, which is now on the
path and not beside it.</td></tr>
<tr><td><strong>B. Apply the remaining &sect;9.8 rows.</strong> Withdrawn.</td>
<td>Arithmetic staged in a WORKING area, the master's numerics retyped internal
decimal in a binary file, a dedicated error record and a plain
<code>FILE</code>, 24 per-field constants, explicit MOVEs, INDEX in WORKING.
Every replacement is attested, because the 1962 sample applied the same rows to
the same program.</td>
<td>It rewrites six shapes that compiled in 1962, which the rule forbids. The
corpus would then measure our recovery of the sample's forms a second time, and
would measure nothing new. Two shapes stayed unbuilt under it in any case: the
internal-to-external move, and the check amount's edit run.</td></tr>
</table>
</div>

<p>Nothing is deleted from M6-8. The costs recorded against course A stand as
the costs of the course now taken, and the costs recorded against course B stand
as the costs of the course refused.</p>

<h3>Chunk 2b's design list</h3>

<p>Each item is a recorded decision under D0.4, with no listing oracle behind
it. M6-9 holds the list:</p>

<ul>
<li>the external-decimal fetch, SYS)181 or SYS)182 with SYS)184;</li>
<li>the external-decimal store, SYS)180 with SYS)186, SYS)187 or SYS)188;</li>
<li><code>FILE record IN file</code>;</li>
<li>a comparison whose sides are expressions;</li>
<li>a product of a product;</li>
<li>the SYS)190 bypass steps, with the page-158 notes measured at build
time;</li>
<li>the 11-character table stride, which carries codegen defect 7 with it;</li>
<li><code>STOP n</code> at run time: the halt and the resume (Open Question
69).</li>
</ul>

<p>This item is decided, not asked. Jack overturned M6-8 himself, so what is
decided here is the reading of his instruction and the scope of the withdrawal.
Silence lets it stand.</p>
</section>
"""

# --- 4 -----------------------------------------------------------------

ITEM4 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>4 &middot; The STOP row was wrong: <code>STOP n</code> is legal</h2></div>

<p>The applied deck replaced <code>STOP 1234.</code> with <code>STOP RUN.</code>
and called that a change the 1962 front end demanded. It is not. J keeps
<code>STOP n</code>, and the two forms do different jobs.</p>

{quote(
    "<p>a. STOP nnnnnn where nnnnnn is any number 6 digits or less. The computer"
    " will stop, and hitting the START key will cause the object program to"
    " continue in execution. (It is hoped that the programmer uses this"
    " instruction sparingly, if at all).</p><p>b. STOP RUN</p><p>This message"
    " means that object-time processing of the job is completed and control has"
    " returned to the CTM supervisor.</p>",
    "J 05.06.04 a and b",
)}

<p>The generated code carries both forms by name:</p>

{quote(
    "<p>This routine displays a message concerning a STOP verb. The CP (Constant"
    " Pool) entries contain the Statement Number of the Stop (in BCD), and the"
    " type of STOP (STOP NNN or STOP RUN).</p>",
    "J 90.02.14, SYS)178",
)}

<p>What J requires is a terminator, and message 175,00 reports its absence:</p>

{quote(
    "<p>A STOP RUN instruction must be included in each program to provide for"
    " transfer of control to the CT Supervisor at conclusion of execution of the"
    " object program. All open files are closed prior to this transfer of"
    " control as if a CLOSE ALL FILES had been supplied.</p>",
    "J 02.04.06 #9",
)}

<p>D2.7 implements both forms. So the 1962 repair adds the terminator. It
replaces nothing. The applied deck now punches both cards:</p>

{plate(
    "      END.OF.RUN.  MOVE CORRESPONDING GRAND.TOTAL TO PAYRECORD, FILE\n"
    "            PAYRECORD, CLOSE ALL FILES.\n"
    "              STOP 1234.\n"
    "              STOP RUN.\n"
    "      COMPUTE.PAY.  IF DETAIL HOURS IS GREATER THAN 40 THEN SET DETAIL",
    "<code>test/fixtures/f-payroll-j.ct</code>, the generated mirror. The new"
    " card is an unnamed sentence, so its text starts in column 15. Full excerpt"
    " in <code>evidence/applied-deck-stop-cards.txt</code>.",
)}

<h3>What moved in the golden</h3>

<div class="scroll">
<table>
<tr><th>Item</th><th>Before</th><th>After</th></tr>
<tr><td>Cards in <code>f-payroll-j.ctd</code></td><td>215</td><td>216</td></tr>
<tr><td>Procedure cards</td><td>82</td><td>83</td></tr>
<tr><td>Statement of <code>STOP 1234.</code></td><td>absent</td><td>139,00</td></tr>
<tr><td>Statement of <code>STOP RUN.</code></td><td>139,00</td><td>140,00</td></tr>
<tr><td>Statements from 140,00 on</td><td>n</td><td>n plus 1</td></tr>
<tr><td>The three 206,00 messages</td><td>165,01 165,03 165,04</td><td>166,01 166,03 166,04</td></tr>
<tr><td>The generator's refusal</td><td>131,00</td><td>131,00, unchanged</td></tr>
</table>
</div>

<p>The refusal does not move, because statement 131,00 stands above the new
card. <code>evidence/f-payroll-j-listing.diff</code> holds the whole golden
change.</p>

<h3>The definition's &sect;9.8 table</h3>

<p>The STOP row read &ldquo;F: <code>STOP 1234</code> (<code>STOP n</code>). J:
<code>STOP RUN</code> (mandatory)&rdquo;, which reads as a replacement. It now
says that J keeps <code>STOP n</code>, that J requires a <code>STOP RUN</code> in
each program, and that the sample replaced one form with the other while J
withdraws neither. Two rows are added beside it, for the divergences chunk 2b
records instead of applying: <strong>overtime pay</strong> (item 6) and
<strong>master numeric typing</strong>, the bare pictorials of the 1960 master
against the sample's <code>IR</code> fields in a binary file.</p>
</section>
"""

# --- 5 -----------------------------------------------------------------

ITEM5 = f"""
<section class="item">
<div class="itemhead"><span class="chip done">Settled</span>
<h2>5 &middot; M6-7's premise restated: four rows repair the punched deck, not
the source text</h2></div>

<p>M6-7 said of its five divergences: &ldquo;Each is a row of the &sect;9.8
table, and each is a change the 1962 front end demands.&rdquo; That overstates
the case. The 1962 processor compiled the verbatim deck as punched, so no row is
a change the front end demands of the source text. Four of the five fix the deck
that compilation punched, which could not run: its GET and its FILE named
records that no file carried. The fifth was simply wrong, and item 4 corrects
it.</p>

<div class="scroll">
<table>
<tr><th>Row</th><th>What it is</th><th>The evidence</th></tr>

<tr><td><strong>1. An environment division</strong>, in J's order DATA,
ENVIRONMENT, PROCEDURE.</td>
<td>Construction, not repair. The row exists because the 1962 GET and FILE bound
to nothing.</td>
<td>Messages 9,00, 19,00 and 21,00 do not stop a compilation. J 05.06.01:
&ldquo;Unless a catastrophic error occurs (e.g., the omission of a division
header), compilation will be completed regardless of the number of errors
encountered.&rdquo; Whether a division absent whole is that omission, or only a
header missing from in front of its cards, is D2.3's open point.</td></tr>

<tr><td><strong>2. CALL old names qualified</strong>, synonyms
unqualified.</td>
<td>Demanded.</td>
<td>J 02.04.05 #5: &ldquo;The (old.name) in a CALL statement must be unique and
may not be subscripted. This requirement is met if the (old.name) appears only
once in the Data Description or if sufficient qualifiers are used to identify it
uniquely.&rdquo; Six of the 1960 program's seven CALL pairs name a field that
appears in more than one record.</td></tr>

<tr><td><strong>3. STOP.</strong></td>
<td>Corrected. The deck keeps <code>STOP 1234</code> and adds
<code>STOP RUN</code> after it.</td>
<td>Item 4 holds it: J 05.06.04 a, SYS)178 at J 90.02.14, J 02.04.06 #9,
D2.7.</td></tr>

<tr><td><strong>4. GRAND.TOTAL written out</strong> as a RECORD with
DEPARTMENT.TOTAL's nine entries.</td>
<td>Demanded.</td>
<td>J 90.01.03 b.i: &ldquo;Implementation of COPY has been deferred.&rdquo; The
hand expansion reconstructs the 1960 intent under F p. 76: the processor
&ldquo;will then obtain the original data description and copy it in its
entirety, except for&rdquo; the name and the level. Only the name and the level
change, so the type RECORD and the justification code <code>L</code> come across
with the nine entries. The result matches what the 1962 sample wrote out by
hand, and no 1962 program equals it.</td></tr>

<tr><td><strong>5. The bare REDEF card</strong>, TABLE.ITEM at level 1 with its
three fields at level 2.</td>
<td>Demanded.</td>
<td>J 02.05.02: &ldquo;When the REDEF type code is used, it should appear on a
line with no additional coding except a serial number and the name of the item
being redefined.&rdquo; Messages 80,00 and 81,00 report the conflict. What the
1962 processor made of the 1960 form is unstated, so our edit takes the rule's
own form (D3.4; D3.6).</td></tr>
</table>
</div>

<p>The deck itself is unchanged by this restatement, except for the STOP card of
item 4. What changes is the claim M6-7 makes about it.</p>
</section>
"""

# --- 6 -----------------------------------------------------------------

ITEM6 = f"""
<section class="item">
<div class="itemhead"><span class="chip decided">Decided</span>
<h2>6 &middot; Three causes separate the corpus's report from the sample's</h2></div>

<p>M6-1 gave the second stage the sample's report as its oracle. Under course A
the two programs no longer print the same values in every column, so the
expectation is stated now, before the run, and the run measures it. Three causes
separate them.</p>

<h3>Cause 1: the 11-character table stride</h3>

<p>The 1962 sample's RET.PREM equals INS.PREM defect rests on table items of two
whole words (M6-4). The 1960 TABLE.ITEM is 11 characters: RATE
<code>99V999</code>, INSURANCE.PREM <code>9V99</code> and RETIREMENT.PREM
<code>9V99</code>. How a positional indicator addresses a stride that is not a
whole number of words is a design chunk 2b must make. No listing attests the
form: <code>MON PI)NN,,0</code> is the printed word, and the character
arithmetic behind it is not printed. Codegen defect 7 lies on that path, where
<code>_strideWords</code> returns <code>strideChars ~/ 6</code> and an
11-character item strides one word instead of two. The insurance premium, the
retirement premium, the net pay and the check amount are therefore expected to
differ, and that design settles them.</p>

<h3>Cause 2: the 1960 program's own defects</h3>

<ul>
<li>The last department's totals never print. Totals print on a department
change only, and END.OF.RUN moves GRAND.TOTAL straight to PAYRECORD.</li>
<li>CURRENT DEPARTMENT carries no value at the first department test, because
the program sets it at the end of the first cycle.</li>
<li><code>MOVE CORRESPONDING DEPARTMENT.TOTAL TO PAYRECORD</code> leaves two
fields unmatched. The totals record names them INSURANCE.PREM and
RETIREMENT.PREM; the print record names them INSURANCE and RETIREMENT.</li>
</ul>

<h3>Cause 3: the overtime sentences</h3>

<p>The two programs agree above 40 hours and disagree below it. The 1960 program
tests for more than 40 hours and pays the premium half only when the test
passes. Its second sentence is unconditional:</p>

{figure(
    "f-p101-overtime.png",
    "Four lines of the 1960 machine listing. Serial 02012 and 02013 read"
    " COMPUTE.PAY, IF DETAIL HOURS IS GREATER THAN 40 THEN SET DETAIL GROSS ="
    " (DETAIL HOURS - 40) * MASTER RATE * 1.5. Serials 02014 and 02015 read SET"
    " DETAIL GROSS = DETAIL GROSS + MASTER RATE * 40, DO FICA.ROUTINE, DO"
    " WITHOLDING.TAX.ROUTINE.",
    "Serials 02012 to 02015, cut from"
    " <code>comtran-manuals/F28-8043/images/page-106.png</code>, box"
    " (370, 1015, 1130, 1125), enlarged two times. That image is printed page"
    " 101 of F28-8043. The sentence at 02014 carries no condition, so it runs"
    " on every line.",
)}

{plate(
    "02012 COMPUTE.PAY.  IF DETAIL HOURS IS GREATER THAN 40 THEN SET DETAIL\n"
    "02013        GROSS = (DETAIL HOURS - 40) * MASTER RATE * 1.5.\n"
    "\n"
    "02014        SET DETAIL GROSS = DETAIL GROSS + MASTER RATE * 40, DO\n"
    "02015        FICA.ROUTINE, DO WITHOLDING.TAX.ROUTINE.",
    "The same four lines as text, from the conversion"
    " <code>comtran-manuals/F28-8043/a1-programming-example.md</code>.",
)}

<p>Below 40 hours the first sentence does not fire, and the second sentence adds
40 hours of pay to the detail record's own GROSS field. The 1960 program
therefore pays a 40-hour week to anyone who worked less than 40 hours. The 1962
sample does not:</p>

{figure(
    "j-p196-stmt203.png",
    "Two statements of the 1962 sample's listing. 202,00 reads COMPUTE.PAY,"
    " MOVE DETAIL DATE TO MASTER DATE, MOVE DETAIL HOURS TO WORKING HOURS,"
    " PAYRECORD HRS. 203,00 reads IF WORKING HOURS GT 40.0 THEN SET WORKING"
    " GROSS = (WORKING HOURS * 1.5 -20) * MASTER RATE OTHERWISE SET WORKING"
    " GROSS = WORKING HOURS * MASTER RATE.",
    "Statements 202,00 and 203,00, cut from"
    " <code>comtran-manuals/J28-6169/images/page-196.png</code>, box"
    " (505, 546, 1295, 626), enlarged two times. One sentence, two arms. The"
    " OTHERWISE arm pays the hours worked.",
)}

{plate(
    "        202,00   71516  COMPUTE.PAY.    MOVE DETAIL DATE TO MASTER DATE,  MOVE DETAIL\n"
    "                                         HOURS TO WORKING HOURS, PAYRECORD HRS.\n"
    "        203,00                          IF WORKING HOURS GT 40.0 THEN SET WORKING GROSS = (WORKING\n"
    "                                         HOURS * 1.5 -20) * MASTER RATE OTHERWISE SET WORKING\n"
    "                                         GROSS = WORKING HOURS * MASTER RATE.",
    "The same five lines as text, from the conversion"
    " <code>comtran-manuals/J28-6169/90.05-sample-program.md</code>.",
)}

<p>No line of the reconstructed tapes exceeds 40 hours, and six of the eleven
detail lines fall below it. Gross pay therefore differs on those six lines, and
the withholding tax, the FICA deduction and the net pay follow it. The row is
added to the definition's &sect;9.8 table as a divergence recorded and not
applied (item 4).</p>

<h3>The columns that still check</h3>

<p>Against <code>test/goldens/90.05-payroll.report</code>:</p>

<div class="scroll">
<table>
<tr><th>Column or block</th><th>Checks</th></tr>
<tr><td>Employee number, name, date, hours</td><td>Every line</td></tr>
<tr><td>Every ERRORFILE line</td><td>Yes</td></tr>
<tr><td>The BONDORDERFILE line</td><td>Yes</td></tr>
<tr><td>Gross pay, withholding tax, FICA deduction</td><td>Only the five lines whose hours are exactly 40.0</td></tr>
<tr><td>Insurance premium, retirement premium, net pay, check amount</td><td>No line, until cause 1's design lands</td></tr>
<tr><td>Department totals and the grand total</td><td>No line, because each sums the lines above it</td></tr>
</table>
</div>

<p>Two more columns rest on a tape decision chunk 2b has not made. The 1960
program adds into the detail record, so each computed field starts at whatever
the tape carried. The table above holds only if the corpus's detail record
arrives with zero in GROSS, FICA, WHT, INSURANCE and RETIREMENT. Bond deduction
checks only if the detail record carries the master's bond deduction, because
<code>MOVE CORRESPONDING DETAIL TO PAYRECORD</code> is the only writer of the
printed field and the bond routine works on the master. Chunk 2b settles the
layout, and it must state which of these it chose.</p>

<p>This item is decided, not asked. The expectation is stated before the run, so
the run finds no surprise. Jack can overturn it, and silence lets it stand.</p>
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
<title>M6 stage 2: what would have compiled in 1962</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<p class="eyebrow">Review record &middot; M6 stage 2 &middot; Jack's rule of
2026-09-14 &middot; evidence 2026-09-14</p>
<h1>M6 stage 2: what would have compiled in 1962</h1>
</header>

<section class="answer">
<div class="itemhead"><span class="chip done">Answered</span>
<h2>Jack's ruling, 2026-09-15</h2></div>
<p>Jack answered on 2026-09-15, in these words: &ldquo;verdicts and course A
stand&rdquo;. The six verdicts of item 1 stand, and so does item 3's course A:
chunk 2b recovers the six refused shapes in the 1960 program's own form, and it
is the next task. Items 4, 5 and 6 are unchanged. Pull request 137 carried the
work and merged on external-review convergence the same day.</p>

<p><strong>Item 2 stays open.</strong> Jack asked for a walkthrough of the deck
reading before he decides whether &ldquo;compile&rdquo; means the diagnostic
listing or the object deck. The question is not withdrawn and it is not
answered. No work waits on it: what the code does today is item 2's own
recommendation, which is to keep the refusal, relabel it, and take the listing
as the deliverable. Item 2 keeps its &ldquo;Your call&rdquo; chip.</p>

<p>Everything below this banner is the record as Jack received it, with two
additions: the Correction section at the foot, appended as the second commit of
this branch, and this banner, appended as the third.</p>
</section>

<section class="answer">
<h2>The answer</h2>

<p>Jack ruled on 2026-09-14: &ldquo;{RULE}&rdquo; This record applies that rule
to the six shapes the code generator refuses in the 1960 payroll corpus.</p>

<ol>
<li><strong>DECIDED.</strong> The reading rule, and six verdicts. A form that F
admits, that J does not contradict, and that Appendix 90.01 does not defer,
compiled in 1962. All six refused shapes pass that test, so chunk 2b recovers
them. The reading against is stated in full and rejected under D0.1.</li>
<li><strong>YOUR CALL.</strong> Does &ldquo;compile&rdquo; mean the diagnostic
listing or the object deck? Under J's letter the 1962 processor punched an
object deck for the verbatim 1960 deck and refused to run it, and no evidence
describes what that deck held. The recommendation is to keep our refusal,
relabel it, and take the listing as the deliverable. No work waits on the
answer.</li>
<li><strong>DECIDED.</strong> M6-8 is overturned in part. Course B, rewriting
the program into the 1962 sample's form, is withdrawn, and so is the parked
stage. Course A is the course and becomes the next task.</li>
<li><strong>SETTLED.</strong> The STOP row was wrong. <code>STOP n</code> is
legal, so the applied deck keeps <code>STOP 1234</code> and adds
<code>STOP RUN</code> after it. The deck holds 216 cards and the golden shifts
by one statement from 140,00.</li>
<li><strong>SETTLED.</strong> M6-7's premise is restated. Four of its five rows
repair the deck that 1962 punched, not the source text 1962 accepted.</li>
<li><strong>DECIDED.</strong> Three causes separate the corpus's report from the
sample's: the 11-character table stride, the 1960 program's own defects, and the
overtime sentences. The columns that still check are named.</li>
</ol>

<p><strong>One item waits for Jack.</strong> Item 2 puts the question. Items 1,
3 and 6 are decided under the CLAUDE.md section 12 standing rule, so he can
overturn any of them and silence lets each stand. Items 4 and 5 are recorded for
the account and need nothing.</p>

<p><strong>Provenance.</strong> The design entries this record explains were
written before the record existed, on branch <code>m6s2-rule</code>: M6-9 new,
M6-1 and M6-7 amended, M6-8 overturned in part, with
<code>docs/HANDOVER.md</code>, the definition's &sect;9.8 table and
<code>test/fixtures/f-payroll-deck-notes.md</code> beside them. Jack gave the
rule in conversation on the same day, not through a review document. No review
document existed at the time. This record explains the decisions taken under it
and puts the one question it leaves open.</p>
</section>

<section>
<p class="note"><strong>Citation forms:</strong> <code>J 02.07.08</code> cites
the 1962 processor manual, J28-6169, by IBM section code; <code>F p. 42</code>
the 1960 manual, F28-8043, by printed page. <code>D0.1</code> is a record on the
locked decision slate, <code>M6-9</code> an entry in the M6 acceptance design
record, <code>&sect;9.8</code> a section of the language definition.
<code>107,00</code> is a message number, <code>131,00</code> a statement number,
and <code>SYS)186</code> a member of the 1962 runtime library.
&ldquo;The verbatim deck&rdquo; is the 1960 program keyed as printed; &ldquo;the
applied deck&rdquo; is the same program with five divergences applied.</p>
</section>
{ITEM1}{ITEM2}{ITEM3}{ITEM4}{ITEM5}{ITEM6}
<footer>
<p>Record built 2026-09-14 on branch
<code>review/2026-09-14-m6s2-rule</code>. <code>tools/build_doc.py</code> writes
this page; edit it, not the HTML. <code>README.md</code> says what each
directory holds, and <code>evidence/README.md</code> says where each evidence
file came from.</p>

<p>This record carries no repository hyperlink. A record may not point at a
branch name, because the branch is deleted when its pull request merges, and the
tip of <code>m6s2-rule</code> was not fixed when the record was built. Every
path is given as a path and every quotation is printed in full, so the record
stands without the repository.</p>

<p>The work lands as one pull request on branch <code>m6s2-rule</code>. It
changes a file under <code>test/goldens/</code>, so it merges on external-review
convergence under the charter. Item 2 is a live question, so Jack's answer is
also the authorization to open that pull request, under rule 7 of the
review-records skill. His answer lands as a second commit on this branch.</p>
</footer>

<section id="correction">
<h2>Correction</h2>
<p>Correction, 2026-09-14, appended as the second commit of this branch. It
changes no argument and no verdict. Item 6's crop of the 1962 sample listing was
cut too wide and too deep. Its box was (470, 548, 1440, 634), which left a third
of the frame empty on the right and clipped the first line of statement 204,00
at the foot. The page is 47rem wide, so the crop displayed at about three
quarters of the scan's own scale and the dot-matrix print was hard to read. The
box is now (505, 546, 1295, 626). Both listing figures of item 6 also carry a
monospace plate of the same lines as text, taken from the conversions, so the
comparison of the two overtime sentences reads without the scan.</p>
</section>

</main>
</body>
</html>
"""

with open(OUT, "w") as fh:
    fh.write(HTML)
print(f"wrote {OUT}: {os.path.getsize(OUT) / 1024:.0f} KB")
