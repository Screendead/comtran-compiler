# Page 204 measurement report

Source: `comtran-manuals/J28-6169/images/page-204.png`, 1650 x 1275, 8-bit grey.
No other file was opened. All numbers below come from that image.

Working image: `deskew.png` in this directory (the source rotated by the angle in
section 1). All pixel coordinates are in that deskewed frame.

## 1. Deskew

**Angle: 0.92 degrees counter-clockwise.**

Found by maximising the variance of the row-ink projection. Ink was taken as
grey < 128 (100 942 pixels). The projection was accumulated with the row index
sheared by tan(angle) about the image centre, so no resampling entered the
search. Sweep: -2.00 to +2.00 degrees in 0.05 steps, then 0.80 to 1.00 in 0.005
steps.

| Window | Best angle |
|---|---|
| whole page | **0.92** (variance 21 394) |
| x 400-1060 (dense body text) | 0.90 |
| x 430-780 (octal and control fields) | 0.87 |
| x 790-1100 (label, mnemonic, operand) | 0.96 |

The page was then rotated by +0.92 degrees (bicubic, white fill). Re-running the
same search on the rotated image gives a best residual angle of **-0.04
degrees**, i.e. the rotation is correct to well under a tenth of a degree.

## 2. Line pitch and the row grid

**Pitch: 15.2924 px.**

The top row of each printed line was located from the row-ink profile, giving 55
line tops. Least squares over all 55:

    y(i) = 223.577 + 15.29242 * i        i = 0 .. 54

* residual rms 0.393 px
* residual max 0.935 px
* 55 tops used

The head line's glyph rows are 177-186. Its top, 177, solves to index
**-3.046**. The head therefore sits three slots above the first content line.

## 3. Form rules

The page carries **32 horizontal form rules**, centres from y = 114.0 to y =
1061.0. Mean spacing **30.548 px = 1.997 x the line pitch**, so a rule falls in
the gap above every second printed line, as warned.

Rules were separated from text by the margin test: a rule prints ink both in
x 310-410 and in x 1250-1490, where no text prints. A rule's ink spans x 313 to
x 1503; the widest content line on the page (00510) spans x 418 to x 1122, a
width of 704 px against the rule's 1190 px.

The rules alternate in weight: every third one prints solid (longest horizontal
ink run 380-750 px), the other two print as 5-6 px dashes. Both kinds fail the
margin test the same way, so both are removed by it.

Each rule sits about 3 px above the glyph box of the line below it. Even so,
rule ink bled into the last row of the glyph-row window on six lines, and every
cell reading was confirmed against a crop rather than an occupancy count.

## 4. Character advance and origin

**Advance: 9.296 px. Origin: the centre of print column 0 is x = 421.97.**

Note that 421.97 is a cell *centre*, not a cell edge. Column 0's ink left edge
is x = 419; the cell's left boundary is x ~ 417.3.

Fit method. Every isolated ink run 3-9 px wide on all 55 content lines was
taken, and its intensity-weighted centroid computed: **2063 glyph edges**. The
advance was chosen to maximise the resultant of the unit phasors
exp(2*pi*i*centroid/advance).

* best advance 9.296 px
* phasor resultant R = **0.9522**
* residual to the fitted comb: rms **0.478 px**, max 3.55 px
* independent check: FFT of the body column-darkness profile over x 410-1130
  peaks at period **9.2985 px**

Short-baseline trap, confirmed empirically. The 12-digit octal field alone gives
104 px / 11 advances = **9.4545 px**. That is 0.16 px per column too large, which
is more than ten cells of error by column 67. The field is far too short to fit
on, exactly as the method warned.

Long-baseline check. Line 00445 prints its machine word twice. First location
digit centroid x = 422.0 (column 0.00); last operand digit centroid x = 1045.5
(column **67.07**). The two are 67 advances apart.

## 5. Measured field columns

All column numbers below were measured from centroids, not assumed.

| Field | Columns | Rows using it |
|---|---|---|
| location, 5 octal digits | 0-4 | 55 |
| machine word, layout A `dddd dd d ddddd` | 7-10, 12-13, 15, 17-21 | 34 |
| machine word, layout B `d ddddd d ddddd` | 7, 9-13, 15, 17-21 | 18 |
| machine word, layout C `dddddddddddd` | 7-18 | 3 |
| control group, 5 binary digits | 25-29 | 55 |
| offset `+nn` | 40-42 | 54 |
| label | 34-47 | 1 |
| mnemonic, 3 characters | 49-51 | 54 |
| mnemonic, 4 characters (`IOST`) | 49-52 | 1 |
| operand, first column | 56 | 54 |

All three machine-word layouts print 12 digits. Layouts A and B both fill
columns 7-13 with six digits plus one blank, then column 15, then columns 17-21.
Layout C prints the word unbroken and appears on the three `OCT` lines only
(00445, 00453, 00512).

The longest operand is 20 characters, columns 56-75 (00510). Nothing on the page
prints right of column 75 except the head.

Head columns: `DATE` 0-3, `10/18/61` 5-12, `TIME` 15-18, `2.45` 21-24,
`ACCOUNT` 27-33, `ID.` 55-57, `CT` 59-60, `PUBLICATIONS` 62-73, `PAGE` 83-86,
`13` 89-90.

**Limit of this page.** Every offset on the page is three characters (`+41`
through `+94`), so the page cannot say whether the offset is left- or
right-justified in its field; columns 40-42 is all the ink supports. Likewise
`CHECK.NEW.DEPT` is the only label, so its columns 34-47 fix one name's
placement and not the label field's own extent.

## 6. Row counts

| Row kind | Rows | Carrying values | Blank |
|---|---|---|---|
| page head | 1 | 1 | 0 |
| slots between head and first content line | 2 | 0 | 2 |
| content lines | 55 | 55 | 0 |
| **total row slots written** | **58** | **56** | **2** |

**Blank slots: 2.** Their row bands are 193-202 (slot 1) and 208-217 (slot 2).

Ink sweep proving them empty. Rows 188-222 were counted at three binarisation
thresholds, restricted to x 417-1244, which is print columns 0 through 88 (the
whole body print width plus a margin of 13 columns beyond the widest ink on the
page):

| Threshold | Rows 188-222 with ink |
|---|---|
| grey < 128 | rows 205 (336 px) and 206 (79 px) only; every other row zero |
| grey < 160 | rows 204 (9 px), 205 (419 px), 206 (200 px) only; every other row zero |
| grey < 192 | rows 204-207 (74, 486, 388, 2 px) plus single stray pixels at rows 189, 190 and 193 |

Rows 204-207 are a form rule, not text, on both discriminators of section 3:
that row band prints ink from x = 313 to x = 1503, crossing both margins where
no text prints, and its 1190 px span is 1.7 times the widest content line's
704 px. The three single pixels seen only at the loosest threshold are scan
grain; each is one pixel, and they lie in three different rows.

**No blank slot falls inside the body.** Two proofs. The 54 consecutive
differences between the 55 measured line tops are all 14, 15 or 16 px; none is
near the 30.6 px that a skipped slot would give. And the single-pitch least
squares of section 2 fits all 55 tops with a maximum residual of 0.94 px, which
a hidden extra slot would destroy.

## 7. Doubtful glyphs

Four cells were doubtful. All four are resolved.

**1. 00512, machine word, 4th digit.** Prints as `C`: the right stroke of the
`0` dropped out at mid-height. Resolved by the doubled-word self-check. The same
line's `OCT` operand prints `000005000004` cleanly at columns 56-67, and the two
printings of a word must agree. Both crops were read at 14x; the operand copy is
independently legible, so the check is valid. Read as **0**.

**2. 00465, control group, faint mark right of the last digit.** Judged **not a
printed character**; it is not in `page-204.txt`. Evidence:

* Position. Intensity-weighted centroid x = 697.4, which is column **29.63**.
  Every certain period on this page measures within 0.07 of an integer column:
  00443 col 59.018, 00451 col 59.018, 00527 cols 39.049, 43.070 and 62.989. The
  two commas of 00443 measure 64.029 and 65.036. Digits and letters measure
  about +0.09. The mark is 0.37 to 0.40 of a cell, about 3.5 px, left of where
  column 30 would print.
* Size and density. 2 rows tall, 3 px wide, minimum grey 12. Every certain
  period is 4-5 rows tall, 4-5 px wide, and reaches grey 0.
* Not a rule dash. The nearest form rule is at rows 541-543, four rows below the
  mark. A whole-page connected-component scan found rule bleed only in the last
  row of a glyph box, never at this height.
* Not a comma. The mark's bottom is one row above the digit baseline; commas on
  this page descend to or below it.

Read as an ink flick beside the printed `0`, or a speck on the copy. If a later
reader disagrees, the character it would stand for is a period at column 30.

**3. 00510 operand, one `D` or two.** Read as `2)BONDENOMINATION,,1`. Resolved
by cell count before any judgment of spelling: the operand occupies exactly 20
cells, columns 56-75. `2)` + 15 letters + `,,` + `1` = 20. A second `D` would
need 21 cells. A 9x crop confirms one `D`. The line's row band (820-829) is
clear of the rule at 816-818, so the count is not rule-contaminated. The period
spelling is preserved and not corrected.

**4. 00461, machine word, ink inside the column 14 cell.** Column 14 should be
the blank inside layout A. The ink is the right-hand flick of the `0` printed at
column 13, whose right stroke reaches x = 548 while column 14's cell window
begins at x = 547. A 14x crop shows a clean gap. Column 14 carries **no glyph**;
the group is `4602 00 0 00020`.

**Standing judgment: O against 0.** The chain prints the two shapes identically,
so this was decided by field, not by shape. Digits in the location, machine-word,
control and offset fields, and in operand subfields after a comma. Letters in
mnemonics (`COM`, `ORS`, `IOST`, `IOC`) and inside names (`BONDPURCHASES`,
`CURRENT.DEPT`, `CT PUBLICATIONS`). Three operand cases are independently
confirmed by the printed machine word: `RET.PREM,,0` against decrement 00000,
`PAYFILE,,0` against decrement 00000, and `IOC)40,0` against tag 0.

## 8. Self-checks run

**8.1 Doubled machine word — pass.** Three lines print their word twice.

| Line | Machine word | `OCT` operand | Agree |
|---|---|---|---|
| 00445 | 000004000003 | 000004000003 | yes |
| 00453 | 000004000003 | 000004000003 | yes |
| 00512 | 000005000004 | 000005000004 | yes |

**8.2 Location continuity — pass.** 00441 through 00527, +1 octal on all 54
steps. The six octal rollovers were each crop-verified: 00447 to 00450, 00457 to
00460, 00467 to 00470, 00477 to 00500, 00507 to 00510, 00517 to 00520. No
storage-reservation skip occurs on this page.

**8.3 Offset column — pass.** +41 through +94, +1 on all 53 steps across the
first 54 content rows. The 55th row (00527) prints the label
`CHECK.NEW.DEPT` at columns 34-47 in place of an offset, and columns 40-42 of
that row hold `NEW`, which is part of the label.

**8.4 Address cross-check — pass.** Every operand that names an address was
checked by hand against the octal printed on the same line.

* `SYS)180,4` against 00264 (0264 octal = 180 decimal); `SYS)182,4` against
  00266 = 182; `SYS)177,4` against 00261 = 177; `SYS)178,4` against 00262 = 178;
  `SYS)133` against 00205 = 133.
* `SYS)267,1,4` against address 00413 = 267 with decrement 00004 = 4;
  `SYS)243,1,15` against 00363 = 243 with decrement 00017 = 15;
  `SYS)243,1,4` against decrement 00004; `SYS)243,1,2` against decrement 00002.
* `IOC)9,4` against 00011 = 9; `IOC)1` against 00001; `IOC)40,0` against
  00050 = 40 with tag 0.
* `PAYRECORD,,20` against decrement 00024 = 20; `INS.PREM,,3` against decrement
  00003; `RET.PREM,,0` and `PAYFILE,,0` against decrement 00000;
  `2)BONDENOMINATION,,1` against decrement 00001.
* The eleven `CP)` references all resolve against one base of 01674 octal with a
  decimal offset: `CP)+4` = 01700, `CP)+25` = 01725, `CP)+26` = 01726,
  `CP)+27` = 01727, `CP)+28` = 01730, `CP)+29` = 01731, `CP)+47` = 01753,
  `CP)+48` = 01754, `CP)+49` = 01755, `CP)+50` = 01756, `CP)+51` = 01757.

This check is what confirmed the heavily inked `+` in `CP)+4` and `CP)+47`, which
at low zoom could be read as another mark.

**8.5 Mechanical placement diff — pass, 2 explained cells.** `page-204.txt` was
re-rendered onto the measured grid and compared cell by cell against an
ink-occupancy map built from the scan, for all 58 rows. Two cells differ:

* 00465 column 30 — the mark of item 7.2, deliberately omitted.
* 00523 column 54 — the form rule at rows 999-1000 crossing the bottom of the
  glyph box. A 14x crop shows `PZE` at 49-51 and blank at 52-55.

No column slip anywhere on the page.

## 9. Anything unread

Nothing. Every cell on the page resolved to a character or to a measured blank.
