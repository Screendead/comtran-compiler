# Chunk A4 blind reader prompt (one per page)

Substitute NNN = 202, 203, 204. Three independent readers, no shared context.

---

You are verifying one page of a 1962 IBM 7090 assembly listing against its page
scan. You are the only reader of this page. Your measurement becomes the
evidence of record, so nothing may reach you except the scan itself.

**Your only source is the page scan**, at
`comtran-manuals/J28-6169/images/page-NNN.png`, 150 dpi, in the repository at
/Users/jacklusher/development/comtran-compiler.

**Open nothing else in this repository. No orientation reads of any kind.**
That one PNG is your whole permitted input. Do not read a transcription, a
design document, a test fixture, a golden, a handover, or another page scan.
Several of those state, in words, the very numbers this task exists to measure
independently, so a single orientation read destroys a pass that costs hours.

You may write files, and you may run Python against the scan. You may not read
repository text. If you find yourself about to check a reading against
something written down, stop: that is the one thing this task forbids.

## What the page is

A printer page from a compiled program listing. It prints a page head line,
then a run of blank line slots, then a body of printed lines. Every body line
places its tokens at fixed print columns. The fields, left to right:

1. a five-digit octal location;
2. a twelve-digit octal machine word, sometimes printed in spaced groups;
3. a five-digit binary control group;
4. either a symbolic label or a `+n` offset;
5. a mnemonic of three or more characters;
6. an operand.

Any field may be blank on any line, and some lines print only one or two of
them. Names may hold `)` and `.` inside them. A long name can run past its own
field into the columns right of it.

## Method

1. **Deskew first.** Rotate by the angle that maximises the variance of the
   row-ink profile. Pages in this range can carry up to a degree of tilt, and
   an unrotated row profile never separates the lines.
2. **Find the text rows** by row-wise ink count. The page carries dashed
   tractor-feed form rules, which are not text. They print 6 px dashes, so a
   filter that deletes a row whose longest horizontal ink run reaches 25 px
   removes the solid rules only and leaves the dashed ones. Two discriminators
   do work on the dashed rules: a rule prints ink in the left and right
   margins, where no text prints, and a rule covers a far wider fraction of the
   page width than the widest line of text.
3. **Fit the character grid on this page's own ink.** Every page has its own
   horizontal registration; two neighbouring pages have differed by 25 px.
   Never carry an origin over from another page. Fit the advance by least
   squares over as many glyph left edges as the page offers, or by
   autocorrelating the body's column-ink profile. Do not fit on a short
   baseline: an error of 0.06 px per column is half a cell by column 89. The
   longest baseline the page offers is a line that prints its machine word
   twice, once in the octal field and once as the operand; on such a line the
   first location digit and the last operand digit are 67 advances apart.
   **Caution:** the octal field by itself spans only 22 columns and is far too
   short to fit a pitch on.
4. **Read every glyph.** `O` and `0` print the same shape in this chain.
   Separate them by field: letters in mnemonics, labels and the head, digits in
   the location, octal, control and offset fields. Where a glyph is doubtful,
   crop its rows at high zoom, compare it against a certain print of the same
   glyph elsewhere on this page, and say in your report what decided it. A
   faded stroke, a broken stem and a form rule crossing a glyph have each
   caused a misreading before.
5. **Count rows before you transcribe**, and record blank slots as well as
   printed ones. The first content line sits directly under the head's blank
   run; do not calibrate on the head and then start below the first line.
6. **Run a self-check where the page offers one.** A line that prints its
   machine word twice must agree digit for digit between the two printings.
   The location sequence should be octally continuous, including across any
   storage-reservation skip.

Do not assume how many blank slots or content lines this page prints. That
count is one of the things being measured, and a guess recorded as a
measurement is worse than no measurement.

## Deliverables

Write both files before you finish, under
`/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/d6c713c7-bc43-47d2-8289-cc7836f092ba/scratchpad/a4/`:

**(a) `page-NNN.txt`** — the page rebuilt as plain text at its true print
columns. Line 1 is the page head. Then one line for every print row slot
through the last printed line: an empty line for a blank slot, and for a
printed slot the characters at their measured print columns. Column 0 is the
leftmost print column of the body, which is the location field's first digit.
Put the page head on that same grid. Use spaces, never tabs, and do not pad
past the last glyph on a line.

This is the file's shape. **Every value in it is invented, and so is every
column position in it.** No line below appears on any real page, and this page's
true columns are yours to measure from ink. Copy the shape, never the numbers:

```
DATE 99/99/99            ZZZZZZ ID.                          PAGE  99
<-- an empty line for each blank slot, one line per slot -->
77777 777777777777 11111 ZZ.FAKE.LABEL  ZZZ  ZZZ)9,9,9
77776 777777777776 11110           +1   ZZZ  77776
77775                                   ZZZ
                                        ZZZ  ZZZ)9
```

The four body lines show the four shapes that matter to the file's format: a
labelled line, an offset line, a line whose operand is absent, and a line whose
location, machine word and control group are all absent. A blank slot is an
empty line, never a line of spaces.

**(b) `page-NNN-report.md`** — your measurements and your judgments:

- the deskew angle;
- the character advance and the origin, with the fit's residual and the number
  of edges it used;
- the line pitch;
- how many blank slots sit between the head and the first content line, and the
  ink sweep that proves each is empty — say which thresholds you swept and what
  rows;
- the number of content lines, and whether any blank slot falls *inside* the
  body;
- every doubtful glyph, and what resolved it;
- every self-check you ran and its result;
- anything you could not read.

State every count as rows, and say separately how many rows carried values and
how many were blank. A count that mixes the two has been wrong before.

Your final message is a short summary: pitch, origin, deskew angle, blank
count, content-line count, doubtful-glyph count, and anything unreadable.
