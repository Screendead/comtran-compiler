# Chunk A3 — evidence for review

**Untracked. Delete this directory when you are done with it.**

Branch `m4s2-pages-199-201`, one commit. Three object pages verified against
their scans: listing pages 8, 9 and 10, PDF pp. 199 to 201.

Every image here is the scan's own ink, deskewed and cropped. Nothing is
redrawn. `evidence.py` made them and `measurements.json` holds the numbers.
The script is a fresh measurement, not the readers' — it agrees with them on
every page.

## What changed in the repository

| File | Change |
|---|---|
| `test/fixtures/90.05-object-listing.target` | +4 blank lines, nothing else |
| `tool/object_listing_target_source.dart` | 3 entries in the measured-blanks map |
| `test/object_listing_target_test.dart` | blank counts for 4 pages; a new frame test |
| `test/fixtures/90.05-object-listing-notes.md` | the three page records |
| `docs/design/m4-codegen.md`, `m1-front-end.md` | the frame, one amendment each |
| `docs/HANDOVER.md` | four erratum candidates, chunk state, test count |
| `test/doc_weight_test.dart` | m4-codegen budget 9000 → 10000 |

The whole change to the target, with the head and header lines shortened to
fit this page:

```diff
 DATE 10/18/61  TIME  2.45  ACCOUNT ... PAGE  8
 
+
+
  LOC        OCTAL        CNTRL        SYMBOLIC
@@
 DATE 10/18/61  TIME  2.45  ACCOUNT ... PAGE  9
 
+
 00060  2 00000 0 00001   00001                   BSS    1
@@
 DATE 10/18/61  TIME  2.45  ACCOUNT ... PAGE  10
 
+
 00200  0074 00 4 00010   10010          +11      TSX    IOC)8,4
```

## Decision 1 — the blank lines after each page head

**Decided: page 8 gets three, pages 9 and 10 get two. The conversion holds
one on each.**

Blue line and `text` = the printer used that line slot. Red line and `EMPTY` =
it did not. The only ink in a red slot is a form guide rule.

### PDF p. 199 — listing page 8

![p199 gap](page-199-gap.png)

Three empty slots, then the column header, then one more empty slot, then the
first listing line. This is the only page in the listing that prints the
column header, and the only page so far that does not print two blanks.

### PDF p. 200 — listing page 9

![p200 gap](page-200-gap.png)

### PDF p. 201 — listing page 10

![p201 gap](page-201-gap.png)

**Why I believe it.** Each page was read by one agent that had the page scan
and nothing else — no conversion, no target, no golden, no other page. Page 8
breaks the pattern, so a second agent measured that page's line spacing alone,
with no access to the first one's work, and returned the same four empty
slots. The script in this directory is a third measurement and agrees again.

The numbers, from `measurements.json`:

| PDF page | Line pitch | Empty slots | Shortest printed row | Tallest empty slot |
|---|---|---|---|---|
| 199 | 15.165 px | 1, 2, 3, 5 | 10 rows of ink | 1 row |
| 200 | 15.215 px | 1, 2 | 9 rows | 0 rows |
| 201 | 15.305 px | 1, 2 | 10 rows | 0 rows |

The last two columns are the separation. A printed character stands 9 to 11
rows tall; what survives in an "empty" slot is at most one row of rule fringe.

**What would reverse it.** A page scan showing ink in one of those slots. I
swept each one at multiple thresholds and found none.

## Decision 2 — the body is a frame of 57 line slots

**Decided: recorded in `m4-codegen.md` M4-8 and `m1-front-end.md` M1-16, with
its scope stated.**

Each map numbers every line slot down the left margin. Red = empty.

![p199 slots](page-199-slots.png)

![p200 slots](page-200-slots.png)

![p201 slots](page-201-slots.png)

On all four verified pages the last content line sits in slot 57:

| Listing page | Slots 1–2 | Slot 3 | Slots 4–5 | Content lines | Last slot |
|---|---|---|---|---|---|
| 8 | blank | blank | header, blank | 52 | 57 |
| 9 | blank | text | text | 55 | 57 |
| 10 | blank | text | text | 55 | 57 |
| 21 (chunk A2) | blank | text | text | 55 | 57 |

Page 8 spends three slots on furniture the others do not print, and prints
three fewer lines. That is why the count differs, and it answers the question
the page 21 pass left open about M1-16's flat "55 content lines".

**What would reverse it.** Fourteen pages are unverified. The transcription of
listing page 19, PDF p. 210, holds 54 content lines, which the frame forbids
unless that page prints an interior blank. I wrote that falsifier into the
design record rather than leaving the claim unqualified.

## Decision 3 — no content changed

**Decided: nothing. All 162 lines already agreed.**

A plain-code comparator parsed the target back into its six fields by the
M4-8 columns and diffed each against the reader's transcription:

```
== PDF p. 199 (listing page 8)   0 disagreement(s) over 52 target lines
== PDF p. 200 (listing page 9)   0 disagreement(s) over 55 target lines
== PDF p. 201 (listing page 10)  0 disagreement(s) over 55 target lines
```

The first run flagged three lines on page 10. That was my comparator's bug,
not a reading: it split fields on two or more blanks, and the six-character
mnemonic `IOCTN*` leaves only one blank before the operand column.

## The column header, measured again

![p199 column header](page-199-header.png)

Red lines are the columns you authorized yesterday. The page 8 reader measured
`LOC` at 1, `OCTAL` at 12, `CNTRL` at 25 and `SYMBOLIC` at 58 without seeing
that correction. This crop is the check by eye.

## Readings the agents made that changed nothing

These agreed with the transcription, so nothing moved. They are here because
each was a genuine coin-toss on the ink, and you may want to disagree.

| Page | Line | Read as | Decided by |
|---|---|---|---|
| 199 | 2 | `2,PI)1` | the `I` has top and bottom serifs; the `1` two columns right has an upper-left flag and none |
| 199 | 4 | `*DATA` | a solid mark at mid glyph height; a period sits on the baseline, a plus is hollow |
| 199 | 49 | `+8` | two bowls with rounded left sides, against the straight stem of `B` in `BSS` |
| 200 | 52–55 | `00174`–`00177` | the first digit is faded on its left stroke; a `C` on that page prints an aperture, these do not |
| 200 | 46 | `IOC)1` | the `I` and the `1` differ by the top bar, and by 4.31 px against 4.84 px mean width |
| 201 | 17 | `TRA`, not `TKA` | the `R` prints a faint top bar; matched row for row against the certain `R` of `CURRENT` |
| 201 | 47, 55 | `10001`, not `1000C` | the right stroke is a straight stem broken on three rows; the page's 20 `C` glyphs never print that stem |
| 201 | 22 | operand ends at `15` | the speck one column past it sits at mid height, not on the baseline, at a quarter of a period's area |

## Judgment calls you may want to overturn

| Call | Why | Cost to reverse |
|---|---|---|
| Raised the `m4-codegen.md` word budget 9000 → 10000 | this chunk's amendment took the file to 9040; stage 2 amends that record once per chunk | one line |
| One reader per page, not two | it is the method chunk A2 set; I added a second reader only for page 8, the page that broke the pattern | rerun a page, about 210k tokens |
| Held all four erratum candidates | the page 21 record asks for one authorization at the end of the pass | none; nothing is blocked |
| Recorded the frame now, not after A8 | it makes a falsifiable prediction that the next chunks test | one amendment |

## One flaw in this chunk

My reader prompts carried a wrong calibration hint: I wrote that the location
field to the far end of a twelve-digit octal word spans about 59 columns,
dropping that those 59 columns are to the *operand* copy of the word. The
body's OCTAL field ends at column 21. The page 10 reader caught it, said so,
and fitted its own grid; no reading changed. Chunk A4's prompt must state it
correctly.

## Cost

678k tokens over 42 minutes for the three page readers — 205k, 215k and 258k.
89k over 13 minutes for the second reader on page 8. The chunk A2 calibration
page cost 135k, and its record called that a floor because its grid was
already known. It was.
