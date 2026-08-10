# page-202: measurement and judgment record

Source: `comtran-manuals/J28-6169/images/page-202.png`, 1650 x 1275, 8-bit grey,
150 dpi. No other file was opened.

All pixel coordinates below are in the **deskewed frame**: the source rotated
0.935 degrees counter-clockwise about the image centre (PIL `Image.rotate`,
bicubic, white fill). The frame keeps the source's 1650 x 1275 size.

## 1. Deskew

| Item | Value |
|---|---|
| Angle applied | 0.935 deg counter-clockwise |
| Page tilt | 0.935 deg clockwise |

Method: maximise the variance of the row-ink profile (`grey < 160`) of the
rotated image over y in [100, 1090], x in [430, 1320]. Searched -2.00 to +2.00
deg in 0.01 deg steps, then 0.80 to 1.10 deg in 0.005 deg steps. The optimum was
the same, 0.92 to 0.93 deg, in three independent x windows: the full width, the
text window x in [430, 1320], and a narrow mid window x in [600, 1000]. The fine
pass settled on 0.935.

## 2. Character grid

| Item | Value |
|---|---|
| Character advance | 9.26708 px |
| Origin, centre of column 0 | x = 438.290 px |
| Fit residual, rms | 0.432 px |
| Fit residual, max | 1.926 px |
| Glyph edges used | 2006 (of 2060 candidates) |
| Column range covered | 0 to 98 |

Method: for every printed row, take the runs of ink columns; keep every run 4 to
8 px wide (one glyph, not a merged pair); take its centre. Fit centre = origin +
k * advance by least squares on k = round((centre - origin) / advance), iterated
with rejection at |residual| > 2 px. The fit converged after one rejection pass,
dropping 54 of 2060 centres.

**Independent anchor.** Content row 51 (location 00347) prints its machine word
twice, once in the octal field and once as the operand. The first location
digit's ink starts at x = 435 and the last operand digit's ink starts at
x = 1056: 621 px over 67 advances = 9.269 px. By glyph centres, 437.5 and
1059.0: 621.5 over 67 = 9.276 px. Both agree with the least-squares 9.26708.

**Drift check.** Mean residual by column decade: 0-9 -0.13, 10-19 +0.07, 20-29
+0.10, 30-39 +0.03, 40-49 +0.15, 50-59 -0.05, 60-69 -0.16, 70-79 +0.09. No
monotonic trend. Decades 80-89 and 90-99 hold only 6 and 4 samples and are not
evidence either way.

## 3. Line grid

| Item | Value |
|---|---|
| Line pitch | 15.2145 px |
| Content row 0, centre | y = 233.519 px |
| Fit residual, rms | 0.432 px |
| Fit residual, max | 1.093 px |
| Rows fitted | 55 |

The form's dashed rules sit at 30.387 px (942 px over 31 intervals, first centre
118.5, last 1060.5). That is 2.00 line pitches, so **a dashed rule coincides
with every second printed row**. The 0.04 px per interval difference makes the
rule cross a different part of the row down the page: near the baseline at the
top, through the glyph bodies further down. This is the page's main hazard and
section 6 records what it cost.

## 4. Row census

State: **58 print row slots**, of which **56 carry values** and **2 are blank**.

| Slot index | Rows (px) | Content |
|---|---|---|
| -3 | 183-193 | page head, 1 row with values |
| -2 | 198-208 | blank |
| -1 | 213-223 | blank |
| 0 to 54 | 229-239 to 1050-1060 | body, 55 rows, all with values |

- Head: 1 row, with values.
- Blank between head and first content line: **2 rows**.
- Body: **55 rows, every one carries values. 0 blank rows fall inside the
  body.**

**Blank sweep.** Ink counted over x in [430, 1400] at four thresholds, on every
row of each slot's +/- 5.5 px window:

| Slot | Rows | ink < 160 | ink < 170 | ink < 200 | ink < 215 |
|---|---|---|---|---|---|
| -2 | 198-208 | 0 | 0 | 0 | 0 |
| -1 | 213-223 | 0 | 0 | 0 | 0 |

Neither window contains a rule row, so no row was dropped from either sweep: the
rules nearest these slots sit at y = 211 (in the gap between the two windows)
and y = 241. Threshold 215 is close to paper white, so a faint or half-struck
line would have shown.

**Nothing above the head, nothing below the body.** Slot -4 (rows 168-178) holds
2 px at < 160 and 48 px at < 215; that is the anti-aliased skirt of the solid
rule at y = 179-180, not text. Slots 55, 56 and 57 (rows 1065-1075, 1081-1091,
1096-1106) hold 0 px at all four thresholds.

**No gap inside the body.** Consecutive content row centres differ by 14.0 to
17.0 px, and the line fit's largest residual is 1.09 px. A skipped slot would
show a 30.4 px step; none occurs.

## 5. Print columns

Measured from the occupied-cell map, not assumed:

| Field | Columns |
|---|---|
| Location | 0-4 |
| Machine word | 7-21, in one of three groupings |
| Control group | 25-29 |
| Symbolic label | starts at 34 |
| `+n` offset | right-justified, last character at 42 |
| Mnemonic | starts at 49 |
| Operand | starts at 56 |

The machine word takes one of three groupings, and each row keeps its own:

- `dddd dd d ddddd` at columns 7-10, 12-13, 15, 17-21 (40 rows);
- `d ddddd d ddddd` at columns 7, 9-13, 15, 17-21 (14 rows);
- 12 contiguous digits at columns 7-18 (content row 51 only, the OCT line).

Page head columns: `DATE` 0, `10/18/61` 5, `TIME` 15, `2.45` 21, `ACCOUNT` 27,
`ID.` 55, `CT` 59, `PUBLICATIONS` 62, `PAGE` 83, `11` 89.

Two long labels reach past the label field but not into the mnemonic:
`END.OF.MASTERS` and `END.OF.DETAILS` each end at column 47, two columns short
of the mnemonic at 49.

**Excluded from the grid.** Numerals print in the left margin (x < 425) and the
right margin (x > 1430). Column 103's centre is x = 1392.8, so both margins lie
outside every print column. Inside the print slots, left-margin ink appears only
on rule rows; the right-margin marks are tall and bleed into neighbouring rows.
They belong to the form, not to any printed line.

## 6. Doubtful glyphs

Seven, all resolved. Nothing was left unread.

**1. Column 0 of content rows 46 to 51 (locations 00342 to 00347) prints as a
`C`.** Read as `0`. At 8x the glyph shows a full top bar, a full bottom bar, a
left stroke, and residual right-stroke ink at the top-right and bottom-right
corners (rows 4-5 and 8-9 of the cell on row 51). The certain `C` on this page,
the `C` of `CAL` at row 53 column 49, carries no right-stroke ink on any row and
its arcs curl inward. The field is the location field, and the location sequence
is continuous.

**2. Content row 29, column 0 (location 00321).** A `0` that dropped its **left**
stroke; the digit classifier ranked `3` first at 0.831 over `0` at 0.717. Read as
`0`: the field is octal, the sequence runs 00320, 00321, 00322 across rows 28 to
30, and a faint left-stroke remnant survives at raw rows 673, columns 3-4.

**3. Content row 48, column 9 (machine word of location 00344). This one I first
read wrong.** At 12x I read `2`, giving `0622`. It is `0`, giving `0602`. Three
lines of evidence:

- *Structure.* In the middle rows the doubtful glyph carries ink only in a
  straight vertical stroke on the right (columns 6-7 of its cell, rows 3 to 7).
  Every certain `3` on this page shows a leftward waist there (row 48 column 61
  runs 5-7, 5-7, 6-8, 7-8, 6-8). Every certain `2` shows a diagonal drifting
  left (row 48 column 10 runs 6-8, 6-7, 5-7, 4-6, 3-4). The broken `0` at row 29
  column 0 runs 6-8, 7-8, 7-8, 7-8, 7-8: the same straight stroke.
- *Correlation, same row where the print quality is the same.* Against the known
  broken `0` at row 29 column 0: **0.886**. Against the two certain `3`s on row
  48: 0.798 and 0.825. Against the two certain `2`s on row 48: 0.597 and 0.576.
- *Cross-check inside the page.* The mnemonic `SLW` prints opcode `0602` on rows
  3 and 24. Row 48 is also `SLW`, and its address 00205 matches its operand
  `SYS)133` exactly as row 21's `STI SYS)133` addresses 00205.

**4. Four asterisks: row 14 column 54 (`IOCTN*`), row 52 column 52 (`TRA*`), row
16 column 56 (`*+3,7`), row 43 column 56 (`*+2`).** At this reduction the
asterisk fills into a blob and can be taken for `+`. Rows 16 and 43 print the
`+` in the very next cell, so the comparison is exact and same-row: the `+`
narrows to a 3 px stem above the bar and tapers to a 1 px point below it; the
asterisk is widest in the middle and its bottom row is still 5 px wide, with no
stem either side.

**5. The stop after `ID` in the page head, column 57.** Read as `.`, not `,`. It
spans 4 cell rows and ends on the baseline, matching the certain period at row
17 column 59 (inside `END.OF.MASTERS`). The certain comma at row 17 column 70
spans 6 rows and descends below the baseline with a tail. The stop in the head's
`2.45` at column 22 matches the period as well.

**6. Content row 52, column 58, the `D` of `END.OF.MASTERS`.** The letter
classifier preferred `C` at 0.897 over `D` at 0.816; the same dropped-stroke
defect. Read as `D`: it carries a straight full-height left stem at cell columns
2-3 on every row from 1 to 11, which no `C` on this page does, and row 52's word
addresses 00331, the location of row 37, the row labelled `END.OF.MASTERS`.

**7. `O` against `0`, and `1` against `I`.** These print the same shape in this
chain. Separated by field throughout: digits in the location, machine word,
control group, offset and page number; letters in mnemonics, labels, operand
names and the head. `IOC)`, `ERROROUT`, `LOW.DETAIL`, `END.OF.RUN`, `GN)064` and
`OCT` take letters; `PAGE  11` takes digits.

## 7. Self-checks

| Check | Result |
|---|---|
| OCT line, content row 51, two printings of the same word | PASS. Octal field `747474747474`, operand `747474747474`, identical digit for digit, 12 digits each. |
| Location octal continuity | PASS. 00264 to 00352, 55 rows, +1 each row, no skip. |
| Location and machine-word character class | PASS. Every character in 0-7; every machine word exactly 12 digits. |
| Control-group character class | PASS. Every control group exactly 5 characters, each 0 or 1. |
| Offset runs | PASS. +6 to +21 continues from the previous page, then each of the five labelled rows resets the run to +1 and every run is consecutive. |
| Occupancy diff | PASS with one explained residue. 0 transcribed characters sit on a cell with no ink. 39 inked cells carry no transcribed character; all 39 are on content row 48 and a 9x crop shows them to be the dashed form rule running along that row's baseline. |
| Glyph-template consistency, numeric fields | 2 of about 1300 digit cells preferred a different digit. Both are the broken `0` recorded above, at row 29 column 0 and row 48 column 9. |
| Glyph-template consistency, alphabetic fields | 1 of about 460 letter cells preferred a different letter, row 52 column 58, recorded above. |
| Glyph-template consistency, digits inside label and operand fields | 216 cells swept against every class, letters included. All 25 disagreements are the same-shape pairs `1`/`I`, `2`/`Z`, `0`/`D`, `0`/`O` and `7`/`T`, each in a numeric part of an address, a tag or a count, and each settled by position inside the operand. |
| Row 41, the leading `2` of `2)EMPLOYEE.NUMBER,1` | PASS. The only leading digit inside a name on this page, so `2` against `Z` was tested directly: 0.957 against the certain `2` at row 48 column 10, and 0.546 to 0.685 against the four `Z`s of `PZE` at rows 8, 12, 13 and 34. The `Z` prints a straight flat top bar; this glyph prints a top arc that curls down on the right. |
| Page head against body templates | Agrees on all 47 alphanumeric glyphs. The two `/` have no template because no `/` prints in the body; the `A`/`4` and `1`/`I` disagreements are the same-shape pairs, settled by field. |
| Mnemonic against opcode | PASS. Each of the 23 distinct mnemonics maps to one opcode digit group. The digit-template check flagged row 48 column 9; this check then confirmed the corrected reading, because `SLW` prints `0602` on rows 3 and 24 as well. |
| Row 30 operand absent | PASS. Columns 56 to 103 hold 0 ink at thresholds < 170, < 200 and < 215, so `COM` genuinely prints no operand. |

## 8. Unreadable

None. Every inked cell on the page was resolved to a character or to the dashed
form rule.
