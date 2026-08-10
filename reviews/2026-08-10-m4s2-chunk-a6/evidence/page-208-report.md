# Page 208 of J28-6169 - blind scan reading

Source, and the only source used: `comtran-manuals/J28-6169/images/page-208.png`
(1650 x 1275, 8-bit grey). Working directory:
`/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/c9073b01-107a-4886-92e7-76ee79dd7c35/scratchpad/a6/page-208`.

The page holds one page head and 55 content lines of a 709/7090 object listing.
First LOC 00772, last LOC 01060. First offset +40, last +94.

---

## 1. Slot frame

The body is a comb of line slots at one pitch. The page head is slot 0.

| Quantity | Value |
|---|---|
| Line pitch | 15.2096 px |
| Empty slots between the head and the first content line | 2 (slots 1 and 2) |
| First content line | slot 3 |
| Content lines | 55 |
| Last content line | slot 57 |
| Empty slots inside the body | none |

How the frame was fitted. 1900 glyph-sized connected components (height 6-14 px,
width 2-14 px, area >= 8) were clustered on their deskewed y-centroid. The
clustering returned 56 clusters, gaps between clusters 14.5-15.7 px, never a gap
near 30 px. A straight-line fit of the 55 body cluster centres against their
index gives pitch 15.2096 px, residual RMS 0.358 px, worst residual 0.830 px.
The head cluster sits 46.32 px above the first body line, which is 3.046 pitches:
within one worst-case residual of exactly 3, so the head is slot 0 and slots 1
and 2 are empty. Measured on cap-top (component ymin) rather than centroid, the
figure is the same 3.046, so the head/body difference in glyph mix is not what
produces the 0.046.

**Blank-slot proof.** For each candidate slot the band `y_centre-5 .. y_centre+7`
was swept across the printed x-range 430-1345 in the deskewed image, counting
pixels darker than each of four thresholds.

| Slot | y centre | dark px < 100 | < 140 | < 180 | < 200 |
|---|---|---|---|---|---|
| 1 | 204.3 | 0 | 0 | 5 | 20 |
| 2 | 219.5 | 0 | 0 | 0 | 0 |
| 3 (control) | 234.7 | 923 | 1193 | 1492 | 1649 |
| 57 (control) | 1056.0 | 769 | 1002 | 1263 | 1433 |
| 58 | 1071.2 | 0 | 0 | 0 | 0 |
| 59 | 1086.5 | 0 | 0 | 0 | 0 |
| 60 | 1101.7 | 0 | 0 | 0 | 0 |

The 5 and 20 pixels in slot 1 at the two loosest thresholds are all in image rows
210-211, which is the top edge of the dashed form rule whose core is at row 212.5;
that rule prints in both page margins, where no text prints. Slot 1 carries no
glyph ink at any threshold. Slot 2 is empty at every threshold.

Above the head there are three form rules (rows ~120, ~151, ~182) and no text:
rows 100-183 carry ink only where those three rules run, and the head's own
glyphs start at row 184.

---

## 2. Grid

Fitted on this page alone, from intensity-weighted ink centroids, over the whole
printed width.

| Quantity | Value |
|---|---|
| Character advance | 9.28245 px |
| originX (left edge of print column 0) | 442.198 px |
| Deskew | 1.078 deg (content descends to the right; corrected by rotating that much counter-clockwise about (800, 640)) |
| Line pitch | 15.2096 px |
| Centroids fitted | 1884 |
| Residual RMS | 0.552 px |
| Baseline | print columns 0 to 90, i.e. the full printed width including the page head's `PAGE  17` at columns 83-90 |

Method, and the trap avoided. Every glyph-sized component's centroid was
weighted by ink intensity, never by its left edge. The advance was fitted by
maximising the circular concentration of `x_centroid mod advance` over the whole
1884-centroid population, then refined by least squares on the assigned column
indices; both agree to 0.0004 px. Fitting a residual-versus-x line gives a slope
of -1.9e-5 per px, i.e. an advance correction of -0.00018 px - no measurable
drift across the page. The twelve-digit machine-word field alone spans only
columns 7-21 and was **not** used as the baseline.

Column 0 is defined as the leftmost printed column on the page. The head's `DATE`
and the body's LOC field both start there. Absolute printer column numbers cannot
be recovered from a photographic reproduction, so print column 0 is this page's
own leftmost column.

The rules and the text are at very nearly the same angle (rules 1.085 deg,
text 1.078 deg), but the rules are not exactly parallel to the text: the rule
pitch measured in the left margin is 30.361 px and in the right margin 30.516 px,
so a rule that is 2.1 px below its neighbouring text line at the left of the page
is 2.7 px above it at the right. That is why the bottom rule cuts into the last
content line's band on the right-hand half of the page only.

---

## 3. Removing the form rules

The rules were found by the margin test, not by a run-length filter. A rule is a
row that carries ink in the left margin (x 150-420) **and** in the right margin
(x 1330-1620), where no text prints. 32 rules were found, from y ~120 to y ~1064,
at a pitch of about 30.4 px - one rule every two text slots.

**Why a run-length filter fails here, measured.** On a dashed rule the longest
horizontal ink run is 4-7 px (medians 4 or 5, 90th percentile 5 or 6, maximum 7).
On a solid rule the longest run reaches 328, 546 and 348 px on the three solid
rules at y 182, 273 and 912. A filter that deletes rows whose longest run reaches
25 px therefore deletes exactly the solid rules and keeps every dashed one. The
margin test catches both kinds, because both print in the margins and both span
far more of the page width than the widest line of text (which ends at column 91,
x ~1287).

Because the rules are not exactly parallel to the text, the mask was built per
rule as a straight line interpolated between that rule's measured centre in the
left margin (x = 285) and its centre in the right margin (x = 1475), thickened
by +/- 2 px. That mask covers 12.5 per cent of the page.

Rules cross text. The worst case on this page is the last content line, slot 57,
where the bottom rule enters the line's 13-row band from column 44 rightward.
Every doubtful cell was read from its own crop, never from a whole-row bitmap.

---

## 4. Fields

Every content line prints the same six-field skeleton. Start columns, measured
from the glyph centroids and confirmed by the per-cell occupancy map:

| Field | Start column | Extent |
|---|---|---|
| LOC | 0 | 5 digits, columns 0-4 |
| OCTAL machine word | 7 | 12 digits, columns 7-21 |
| CNTRL | 25 | 5 digits, columns 25-29 |
| label or +n offset | 40 | `+` at 40, digits at 41-42 |
| mnemonic | 49 | 3 letters, columns 49-51 |
| operand | 56 | variable, longest ends at column 74 |

The octal word prints in two sub-layouts, both twelve digits:

* **4-2-1-5** on 54 lines: digits at columns 7-10, 12-13, 15, 17-21.
* **1-5-1-5** on the one TXL line (LOC 00773): prefix digit at column 7,
  decrement at columns 9-13, tag at column 15, address at columns 17-21.
  Column 11 carries ink on that line and on no other, which is what pins the
  decrement to columns 9-13 and therefore the prefix digit to column 7.

Two lines (LOC 01010 and LOC 01030, mnemonic COM) print no operand at all. Every
other line prints one.

**No line on this page prints a label** in the fourth field; all 55 print a `+n`
offset. Columns 30-39 and 43-48 are blank on every content line.

**Justification of the offset: this page cannot tell.** All 55 offsets are
two digits (+40 through +94), the `+` sits in column 40 on all 55 lines and the
two digits in 41 and 42. With no one-digit and no three-digit offset anywhere on
the page there is no evidence that separates left- from right-justification.

The page head prints at:
`DATE` 0, `10/18/61` 5, `TIME` 15, `2.45` 21, `ACCOUNT` 27, `ID.` 55, `CT` 59,
`PUBLICATIONS` 62, `PAGE` 83, `17` 89.

---

## 5. Doubtful glyphs

Every cell was cross-checked by template correlation against templates built from
this page's own glyphs, with the cell under test excluded from its own template.
The checks below are the cells where the ink itself is genuinely equivocal.

### 5.1 Line at LOC 00772, column 56 - read `8`, alternative `B` NOT settled

This is the page's one seriously contested glyph, and the operand it opens is
`8L)3,2` rather than `BL)3,2` - but see the caveat below: the ink favours `8`
without settling it. Three independent measurements were run. The
training sets are semantically certain: the five `B` glyphs come from the words
`PUBLICATIONS` and `NUMBER`, and the 23 `8` glyphs from shift counts whose value
is confirmed by their own octal address field, from `+88` in the offset column,
and from `10/18/61` in the head.

1. Leave-one-out template correlation, centroid-aligned:
   target vs `B` 0.773, vs `8` 0.885. Each known `B` scores 0.857-0.955 on the
   `B` template; the target scores below all of them.
2. Column-profile peak ratio (left lobe peak over right lobe peak): all five
   known `B` glyphs 1.02-1.49, because a `B`'s vertical stem is its heaviest
   stroke; all known `8` glyphs 0.80-0.99. The target is 0.78.
3. Fisher discriminant over the centroid-aligned patch, then repeated over the
   patch binarised at each glyph's own half-maximum so that ink weight cannot
   drive the answer. Binarised: the `B` population projects to +0.88 .. +3.43,
   the `8` population to -4.20 .. -1.64, the target to -2.26 - inside the `8`
   population, nowhere near the `B` population.

**This glyph is not settled by the ink, and I record it as unsettled.** The
upper-left of the glyph printed weakly: its stem is one sample wide in the top
half, against four samples in both reference shapes. All three tests above key on
the left stroke, which is exactly the stroke that degraded, so a `B` whose stem
printed thin would land inside the `8` population under every one of them. Clean
separation between the two training populations says nothing about where a
degraded `B` falls. Binarising at the glyph's own half-maximum does not remove
the confound either, because the surviving stem is thin as well as light.

The one piece of evidence the dropout cannot explain away is the lower bowl,
which printed cleanly: there the left edge bulges outward by one sample (about
0.5 px) at rows 12-14, which is the `8` pattern, while all five reference `B`
glyphs hold a straight left edge through the same rows. That is why the reading
is `8`. But a half-pixel feature is thin ground for the page's most contested
cell, so the alternative `B` stays on the record rather than being dismissed.

I deliberately did **not** consult any document to settle it.

### 5.2 Six zeros that lost their right stroke

Measuring the ink of the middle rows in the right fifth of each cell against the
same measure on the left fifth, the median of all 740 zeros on the page is 0.994
(symmetric) and the 5th percentile is 0.752. Six zeros fall far below that:

| Cell | Field | ratio | Reads as | Settled by |
|---|---|---|---|---|
| LOC 01030, col 7 | first octal digit | 0.080 | `C` | COM is +0760, so digit 1 = 0 |
| LOC 01027, col 7 | first octal digit | 0.170 | `C` | ANS is +0320, so digit 1 = 0 |
| LOC 01041, col 26 | CNTRL digit 2 | 0.312 | `C` | CNTRL holds 10001 / 10000 / 10010 only |
| head, col 6 | `10/18/61` | 0.389 | `C` | date field, `1?/18/61` |
| LOC 01025, col 26 | CNTRL digit 2 | 0.423 | `C` | as above |
| LOC 01056, col 26 | CNTRL digit 2 | 0.480 | `C` | as above |

Shape alone prefers `C` for the two worst: under a Fisher discriminant trained on
this page's 22 real `C` glyphs against its column-7 zeros, the real `C` range is
+0.281 .. +0.430 and the column-7 zero range is -0.482 .. -0.061; LOC 01030's
digit projects to +0.309 and LOC 01027's to +0.213. The octal machine-word field
cannot hold a letter, and each line's mnemonic fixes its own leading digit, so
both are zeros with a dropped right stroke. This is the failure mode the chain is
known for and it is why the reading is stated from the field, not from the shape.

One further zero, the leading digit of LOC 01060 at column 0, lost its **left**
stroke instead (left/right ratio 2.83). The LOC sequence and the five-digit field
fix it as 0.

### 5.3 Shapes this font makes nearly identical, all settled by field type

A whole-page classifier confused `0`/`O`/`D`/`G`/`Q`, `1`/`I`/`)`, `7`/`T`,
`4`/`A`, `5`/`S` and `6`/`N` on 233 of 1939 cells. None of those is a real doubt:
each is a digit in a digit-only field or a letter in a letter-only field. Rerun
against digits only, the digit-field classifier disagreed with the reading on
27 of 1320 cells, all of them `2`/`7`, `5`/`4`, `3`/`1` or `0`/`6`/`8`/`3` pairs.
Every one of those 27 is independently fixed by a page-internal identity: the LOC
sequence, the offset sequence, the mnemonic-to-opcode map, the shift-count
identity, the `CP)+n` base identity, or a repeated data address. None changed a
reading.

---

## 6. Specks rejected

No mark on this page was judged a speck and dropped. The candidates that had to
be dismissed were all rule ink, not specks:

* **Slot 1, image rows 210-211, 5 px at threshold 180 and 20 px at threshold 200.**
  Measurement: the same rows carry 78 and 102 dark pixels in the right page margin
  and are contiguous with the rule core at row 212.5, whose pitch places it in the
  32-rule comb. Fallback reading if it had been text: none - there is no glyph
  shape there, the ink is 1 px tall and runs the page width.
* **Slot 57 (LOC 01060), 28 cells in columns 44-89 showing 4-7 dark pixels each.**
  Measurement: all of that ink lies in image rows 1063-1064, which is the bottom
  dashed rule; the rule sits at rows 1061-1062 in the left margin and 1064-1065 in
  the right, so it enters the line's band only on the right-hand half of the page.
  Dash run length there is 4-6 px, matching every other dashed rule on the page.
  Fallback reading if it had been text: the line would have printed something
  after `LGR  24`, which it does not.
* **Two marks in the left margin at y 764 and 769, and one at y 416 in the right
  margin.** Measurement: they appear in one margin only, so they fail the
  two-margin rule test; they are page-edge printing (small numerals at the left
  edge and their show-through at the right edge), outside the listing entirely.
  They were excluded from the rule list and from every grid fit.

After the rules were masked, a cell-by-cell sweep of all 56 lines x 95 columns
found **zero** disagreements with the transcription: no column read as blank
carries ink, and no column read as a character lacks it.

---

## 7. Self-checks

| Check | Result | Detail |
|---|---|---|
| Machine word printed twice on one line | not applicable | No line on this page prints its word twice. |
| LOC sequence unbroken with correct octal carries | pass | 55 values, 00772 to 01060, each +1 in octal; carries at 00777->01000, 01007->01010, 01017->01020, 01027->01030, 01037->01040, 01047->01050, 01057->01060 all correct. |
| Offset sequence | pass | +40 to +94, each +1, 55 values. |
| LOC against offset | pass | LOC minus offset is the constant 00722 on all 55 lines. |
| Mnemonic agrees with its own opcode | pass | 0 mismatches over 55 lines. Leading 4 is the sign bit: CAL 4500, ANA 4320, ORS 4602, LGL 4763, LGR 4765, RQL 4773 (all negative opcodes); ANS 0320, LDQ 0560, SLW 0602, COM 0760, ARS 0771, LAC 0535 (all positive); TXL prints prefix 7, which is -3. |
| Shift count agrees with the address field | pass | 19 shift instructions, 0 mismatches: ARS 6 / 00006, ARS 18 / 00022, LGL 6 / 00006, LGL 18 / 00022, LGL 24 / 00030, LGL 30 / 00036, LGR 24 / 00030, RQL 0 / 00000, RQL 6 / 00006, RQL 12 / 00014, RQL 18 / 00022. |
| Address that names a label resolves to that label | pass | The six `CP)+n` operands (+16, +17, +25 twice, +35, +36) give addresses 01714, 01715, 01725, 01725, 01737, 01740. Subtracting n converted to octal gives the single base 01674 in all six cases. |
| Tag agrees with the word that carries it | pass | The tag digit at column 15 is 2 on exactly the 10 lines whose operand ends `,2`, plus the TXL line whose operand is `SYS)294,2,0`; it is 0 on the other 44. 0 mismatches. |
| Decrement agrees with the word that carries it | pass | The one line with a decrement, LOC 00773, prints decrement 00000 and operand `SYS)294,2,0`, whose third subfield is 0. |
| Same operand, same address | pass | No operand string on this page maps to two different address fields. |
| Every octal word has twelve digits | pass | All 55. |
| CNTRL is a function of the operand qualifier | pass | qualifier `2)` -> 10000; `3)`, `4)`, `CP)`, `8L)` -> 10001; `SYS)` -> 10010; bare literal operand -> 10000. No exceptions. |

Data-name operands such as `3)EMPLOYEE.NUMBER` point at storage locations that
are not printed on this page, so their addresses cannot be resolved here. What
can be checked page-internally is that they are used consistently, and they are:
`3)EMPLOYEE.NUMBER` 00006 with `3)EMPLOYEE.NUMBER+1` 00007, `3)EMPLOYEE` 00020
with `3)EMPLOYEE+1` 00021, `4)MONTH` and `4)DAY` both 00024, `4)YEAR` 00025,
`3)DEPARTMENT` 00020, `3)MONTH` and `3)DAY` both 00000.

First LOC on the page: 00772. Last LOC: 01060.

---

## 8. Cells that could not be read

None. Every cell on the page was read.

---

## 9. Notes for a later page reader

* **Deskew on the text, then check the rules separately.** On this page the rules
  and the text are within 0.01 deg of each other, so a global projection-variance
  deskew gives the right answer - but the rules' pitch differs by 0.5 per cent
  between the left and right margins, so a rule mask built from a single angle
  drifts by ~3 px across the page and eats into text lines at one end. Build the
  mask per rule from its measured position in each margin.
* **The margin test is the only rule test that works.** Dashes here are 4-7 px;
  solid rules reach 546 px. Any single run-length threshold misses one kind.
* **Do not fit the advance on the machine-word field.** It spans columns 7-21
  only. The head's `PAGE  17` at columns 83-90 is what extends the baseline to
  the full 91 columns; include the head line in the fit.
* **This chain drops strokes, and not only on the right.** Six zeros lost their
  right stroke badly enough to read as `C`, and one lost its left stroke. Decide
  such cells from the field type and the opcode, and record the ratio.
* **The `B`/`8` pair is the real hazard.** Build both training sets from
  semantically certain cells (`PUBLICATIONS`, `NUMBER` for `B`; shift counts whose
  value the address field confirms, for `8`), binarise at each glyph's own
  half-maximum so ink weight cannot drive the discriminant, and report where the
  target lands relative to both populations rather than which template wins.
* **The strongest verification on an object-listing page is arithmetic, not
  shape.** The shift-count-to-address identity and the `CP)+n` base identity
  between them confirmed every digit that the template classifier doubted.
* Scripts, crops and intermediates are in this directory: `s01_stats.py` through
  `s46_write.py`, `deskew.png`, the `L*.png`/`R*.png` reading strips with a fitted
  column ruler drawn on each, and `cmp_B8.png`, `cmp_0C.png`, `cmp_misc.png`.

---

## 10. Contamination report

I opened none of the banned files. I did not open
`test/fixtures/90.05-object-listing.target`,
`test/fixtures/90.05-object-listing-notes.md`,
`tool/object_listing_target_source.dart`,
`tool/generate_object_listing_target.dart`,
`comtran-manuals/J28-6169/90.05-sample-program.md`,
`docs/design/m4-codegen.md`, `docs/design/m1-front-end.md`, anything under
`test/goldens/`, or any page scan other than `images/page-208.png`. I did not
read any file that quotes them, and I did not run any search over the repository.
I also chose not to open `comtran-manuals/J28-6169/02-compiler.md`, which the
task permits, because the only question I might have taken there - what the
operand qualifier `8L)` means - is a question about this page's value.

Every value in this report and in `transcription.txt` came from measuring
`images/page-208.png`. The 709/7090 opcode-to-mnemonic correspondences used in
the self-check (CAL -0500, LDQ +0560, SLW +0602, ANA -0320, ANS +0320, ORS -0602,
LGL -0763, LGR -0765, RQL -0773, ARS +0771, COM +0760, LAC +0535, TXL prefix -3)
are general knowledge of the machine, not taken from any file in this repository;
they are used only as a consistency check on a reading already made from the ink,
and every one of them agreed.
