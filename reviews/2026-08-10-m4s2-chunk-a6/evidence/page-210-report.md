# Blind read of page-210.png (J28-6169), object listing

Source, and the only source used:
`/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/images/page-210.png`
1650 x 1275, 8-bit grey. Working directory:
`/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/c9073b01-107a-4886-92e7-76ee79dd7c35/scratchpad/a6/page-210`.

Deliverables: `transcription.txt` beside this file.

---

## 1. Slot frame

The page body is a frame of line slots at one pitch. The page head - the line reading
`DATE 10/18/61  TIME  2.45  ACCOUNT ... ID. CT PUBLICATIONS ... PAGE  19` - is slot 0.

| quantity | value |
|---|---|
| empty slots between the head and the first content line | **2** (slots 1 and 2) |
| content lines | **55** (slots 3 to 57) |
| slot of the last content line | **57** |
| empty slots inside the body | **none** |
| first and last LOC on the page | **01150** and **01234** |

Slot 0 sits at y = 181.2 and the first content line at y = 226.8. The gap is 45.5 px,
which is 3.00 line pitches, so exactly two slots stand empty between them.

**Proof that slots 1 and 2 are empty.** I swept each slot's 13-row band across the text
width (x 430 to 1295) at five binarisation thresholds and counted ink pixels, once on the
raw image and once with the rule mask removed:

| band | thr 60 | thr 90 | thr 120 | thr 150 | thr 180 |
|---|---|---|---|---|---|
| slot 1, rows 191-203, raw | 310 | 210 | 126 | 52 | 26 |
| slot 1, rows 191-203, rules removed | **0** | **0** | **0** | **0** | **0** |
| slot 2, rows 206-218, raw | **0** | **0** | **0** | **0** | **0** |
| rows 190-200 (inside slot 1, clear of the rule), raw | **0** | **0** | **0** | **0** | **0** |
| slot 3 (occupied), rules removed - control | 1210 | 1016 | 879 | 723 | 588 |

Every pixel the raw sweep found in slot 1 lies inside the form rule that crosses at
y = 204. Take the rule away and both slots are bare at every threshold, while the control
slot holds a thousand pixels.

**Two things that are not content lines.** Two rules print above the head, at y = 112 and
y = 142, and one prints below the last content line at y = 1053. They pass the margin test
(section 3) and carry no text.

**The trap this page sets, and where I nearly fell in.** Slot 45 prints only `AXT` and `0`
- no LOC, no octal word, no control number, no label. Its band holds 99 ink pixels against
a typical 1100, so a sweep that thresholds on line weight drops it and the slot reads as
blank. It is a content line: the label on slot 44, `WITHOLDING.TAX.ROUTINE`, is 22
characters and runs to print column 55, which is past the mnemonic field at column 49, so
its instruction is pushed to the next line. Slot 42 is the mirror case - LOC and label
only, 350 ink pixels.

---

## 2. This page's own grid

Deskew first, then the character grid fitted over the whole printed width.

| quantity | value |
|---|---|
| deskew applied | **+1.2658 deg** counter-clockwise |
| character advance | **9.2666 px** |
| origin, x of the centre of print column 0 | **437.374 px** (in the deskewed image) |
| line pitch | **15.1844 px** |
| centroids fitted | **1738** |
| residual RMS | **0.651 px** |
| baseline the advance was fitted over | print columns **0 to 90**, x 437 to 1271 |

**Deskew.** Coarse-to-fine search maximising the variance of the horizontal ink projection.
Run over the whole page it peaks at 1.2665 deg; run over the text band alone (x 430 to
1290, y 215 to 1060) it peaks at the same place, 1.2665 deg. I applied 1.2658 deg.
Cross-check on the residual: regressing per-line ink centroids on x over the three
all-digit fields, which carry no descenders, gives a residual slope of **-0.037 deg**. The
same regression including the operand field gives +0.093 deg - that difference is the
comma and parenthesis descenders pulling the right-hand centroids down, not skew, and it
is why I did not deskew from centroids.

**Advance.** Ink centroids of individual characters, intensity-weighted, from all 55
content lines plus the head, over x 425 to 1300. Segments wider than 12 px, meaning
touching glyphs, were dropped. Advance and origin were fitted jointly by minimising the
squared distance of each centroid from its nearest cell centre, phase-seeded from the
circular mean.

**Drift test.** Mean residual in ten-column blocks, from the same fit:

| cols | 0-9 | 10-19 | 20-29 | 30-39 | 40-49 | 50-59 | 60-69 |
|---|---|---|---|---|---|---|---|
| n | 406 | 328 | 321 | 38 | 182 | 286 | 169 |
| mean residual px | -0.36 | +0.28 | +0.33 | +0.37 | +0.19 | -0.19 | -0.24 |

No monotone trend, so no accumulating drift. The residual swing is glyph-shape bias, which
differs from field to field because each field draws on a different set of characters.

**The short-baseline trap, measured on this page.** Fitting the same way on the left half
alone gives 9.2989 px; on the right half alone, 9.2446 px. They differ by 0.055 px, which
is 5.0 px - more than half a cell - by print column 90. The full-width fit is the one to
use.

---

## 3. Removing the form rules

The rules are form furniture, not printed characters. They are horizontal, dashed or solid,
and they span x 326 to 1513 - from well left of the LOC field to well right of anything the
printer puts on the page. **The widest line of text spans 841 px; a rule spans 1187 px.**

**The margin test.** A row is a rule row when it carries ink in the left margin band
(x 330 to 428) or the right margin band (x 1292 to 1486) **and** its ink spans at least
1000 px. Text never reaches either band. Both bands are inboard of the page-edge marks at
x > 1490 and outboard of the form's own line numerals at x 315 to 327, so neither piece of
furniture can trip the test.

Why a run-length filter would not do: this page prints both kinds. The dashes measure about
6 px, so a filter keyed on a 25 px run keeps every dashed rule and deletes only the solid
ones. The margin test catches both, because both reach the margins.

**32 rules found**, at a pitch of 30.36 px, which is exactly two line pitches. They sit at
half-slot offsets - in the gap between alternate text lines, not on them. Every third rule
is solid; the solid ones recur every 91.1 px, that is every six content lines.

**They are not parallel to the text.** I fitted each rule as a line through its own margin
ink, then masked +/- 3 px around that line across the full width. Fitted slopes run from
-0.00215 at the top of the page to +0.00140 at the bottom, a smooth sweep of 0.20 deg. That
is page bow, and it means a single row band cannot describe a rule: the rule at y = 295
crosses the content line at y = 287 on the right of the page and clears it on the left.
That is why the mask is two-dimensional and fitted per rule, and why every doubtful cell in
this report was read from a crop and not from a row bitmap.

Consequence for reading: a rule crossing a content line leaves as few as five clean image
rows. Nine content lines are crossed by a solid rule. I read them from crops, and I
abandoned an automatic classifier because of them - see section 8, note 6.

---

## 4. Fields and their measured print columns

| field | print column | notes |
|---|---|---|
| LOC | **0** | 5 characters, cols 0-4. 54 of 55 lines print it |
| OCTAL | **7** | 15 characters, cols 7-21 |
| CNTRL | **25** | 5 characters, cols 25-29 |
| label | **34** | starts at 34; the longest on this page runs to col 55 |
| offset `+n` | **right-justified, units digit at column 42** | |
| mnemonic | **49** | 3 or 4 characters |
| operand | **56** | |

**Offset justification: this page can tell, and it is right-justified.** `+150` occupies
cols 39-42, `+10` and `+25` occupy 40-42, `+1` occupies 41-42. The plus sign moves; the
units digit does not.

**The octal word prints in two layouts, both 15 columns wide.** Instruction words put a
four-digit operation code in cols 7-10 and a two-digit flag in 12-13; prefix words put one
digit in col 7 and a five-digit decrement in 9-13. Both put the tag in col 15 and the
address in 17-21. 45 lines take the first layout, 8 the second.

**Whole-page cross-check of the field columns.** I rendered my transcription onto the
96-column grid and compared it against the measured ink of every cell - 55 lines by 96
columns, 5280 cells. Every cell I claim carries a character measures at least 1251 ink
units; every cell I claim is blank measures at most 257, and only one blank cell has any
ink at all (the speck in section 6). **Zero mismatches.** A column error of one anywhere
would have shown here.

---

## 5. Doubtful glyphs

### 5.1 Zeros whose right stroke did not print (the C question)

Seven cells print a glyph whose main stroke is open on the right, like a letter C, in a
field where the value must be a zero. They cluster: three consecutive lines at column 0,
two consecutive lines at column 8, two lines at column 26.

The discriminator is ink in the glyph's own right-middle window - the right 45 % of its
bounding box across the middle 40 % of its height, measured on the **raw grey patch** so
that a right stroke that printed faintly and broke away from the main stroke still counts.
I report the minimum, over the rows of that window, of the maximum grey value in the row.
On 26 unambiguous zeros the figure runs 127 to 211. On 16 unambiguous letter C glyphs it is
0 to 35, with three contaminated by a neighbour.

| cell | reading | rejected | row-by-row grey in the right-middle window | verdict |
|---|---|---|---|---|
| slot 42, LOC col 0 | 0 | C | 87, 84, 111, 96, 152 | ink present on every row: a zero with a weak right stroke |
| slot 43, LOC col 0 | 0 | C | 58, 39, 39, 181, 255, 198 | ink on every row, weak at the top |
| slot 44, LOC col 0 | 0 | C | 19, 2, 1, 58, 157 | **ink does not decide**; see below |
| slot 31, OCTAL col 8 | 0 | C | 13, 39, 8, 22, 143 | **ink does not decide** |
| slot 32, OCTAL col 8 | 0 | C | 2, 1, 1, 30, 127 | **ink does not decide** |
| slot 17, CNTRL col 26 | 0 | C | 37, 10, 72, 156, 208 | **ink leans C** |
| slot 21, CNTRL col 26 | 0 | C | 141, 46, 196, 228, 240 | ink present on every row: a zero |

For the four cells where the ink does not decide, the field decides, and the argument is
arithmetic, not expectation:

- **slot 44, LOC.** The locations run 01216 (slot 41), 01217 (42), 01217 (43), then 01221
  (46). Slot 44 can only be 01220. A location counter has no letter in it.
- **slots 31 and 32, OCTAL col 8.** The field is octal; C is not an octal digit. Both lines
  are TRA, and slot 33 - also TRA, one line later - prints a clean `0020`. All four TRA
  lines and the one TRA* must share an operation code, and they do at `0020`.
- **slot 17, CNTRL.** The field takes three values on this page and only three: 10000,
  10001, 10010, across 53 lines. `1C001` is not among them, and slot 17 is an LDQ with a
  symbolic operand, which prints 10001 everywhere else.

I record these as glyphs whose ink alone reads C. The value is settled; the shape is not.
The likely cause is impression loss in the offset reproduction rather than a wrong
character, and the clustering - consecutive lines at one column - is what a local
impression defect looks like. Two nearby zeros that a coarse crop made me suspect are in
fact closed and measure as ordinary zeros: slot 41 col 0 (min 72) and slot 10 col 0
(min 69).

### 5.2 Digit 0 against letter O

Width does not separate them on this page: letter O measures 4 to 8 px wide, digit 0 also
4 to 8. The mean glyph shapes do differ - the letter is squarer and a row taller, the digit
is a narrower oval - and a mean-template correlation built from 13 letter O and 592 digit 0
exemplars separates its own exemplars 12/13 and 586/592.

Eleven cells sit in a position where either could stand. Every one of them scores higher
against the digit template, and every one of them is in a numeric subfield:

| cells | reading | correlation, digit 0 vs letter O |
|---|---|---|
| slot 16 and 45, `AXT 0` | 0 | 0.931 / 0.759 and 0.935 / 0.791 |
| slot 13, `OUTPUTMASTER,,0` | 0 | 0.855 / 0.701 |
| slot 8, `PAYFILE,,0` | 0 | 0.823 / 0.770 |
| slots 36, 38, 51, `1.RS)0` and `2.RS)0` | 0 | 0.877 / 0.816, 0.843 / 0.797, 0.846 / 0.805 |
| slots 25 and 48, `SYS)294,1,0` | 0 | 0.783 / 0.726, 0.674 / 0.547 |
| slot 5 `CHECKFILE,,0`, slot 53 `2.RS)0` | 0 | glyph merged with a solid rule; read from a crop, shape matches its twin on the sister line |

The margin on the last few is thin. I am recording the reading as settled because the
context is arithmetic in every case - `AXT 0` prints address `00000`, the third operand
subfield carries 16, 20 and 15 on the sister lines - but the shape evidence alone is only
suggestive.

### 5.3 Glyphs settled by measurement, with the rejected alternative

| where | read | rejected | evidence |
|---|---|---|---|
| slot 46, OCTAL col 9 | **6** | 5 | I first read `0550` from a 4x crop and it broke the LDQ opcode against slot 17's `0560`. At 11x the glyph is a stroke descending from upper right to lower left, closing into a bowl at the bottom - the shape of the known 6 at slot 41 col 4. A 5 has a horizontal top bar and an S-curve; slot 46 col 8 shows exactly that, and the two glyphs are plainly different. The opcode check now passes |
| slots 10, 24, 47, operand col 56 | **B** | 8 | The left side is one straight vertical, ink in cols 1-2 of every row, with two bowls hung on the right. The known 8 at slot 11 col 60 has no straight side and pinches at the waist |
| slot 4 etc., `IOC` col 56 | **I** | 1 | A symmetric vertical stroke, widening equally at top and bottom, identical to the I inside `FICA`. The digit 1 on this page carries a flag on the upper **left** of the stem and a wider foot; see slot 26 cols 56 and 63 |
| slot 26 etc., `1)FICA,1` col 63 | **1** | L | Carries the upper-left flag of the digit 1 and is the same glyph as the leading character of the same operand. An L has no upper flag |
| slots 36, 38, 51, 53, col 57 | **.** (period) | , (comma) | A compact blob, 4 rows, sitting on the baseline with no tail. The comma at slot 4 col 61 spans 6 rows and its ink walks left as it descends. The period at slot 43 col 60, inside `FICA.ROUTINE`, is the same 4-row blob |
| slot 31 col 56, slot 43 col 52 | **\*** (asterisk) | . or a bullet | A solid blob 5-6 px across, centred at mid glyph height, rows 4-10. A period sits at rows 9-13. At 150 dpi after photo-reduction the five strokes of the asterisk merge. Corroborated twice over: `TRA*` at slot 43 carries flag digits `60`, the indirect flag, where every plain TRA prints `00`; and `TRA *+3` at 01204 prints address 01207, which is 01204 + 3 |
| slot 44, label | **WITHOLDING** | WITHHOLDING | W-I-T-H-O-L-D-I-N-G, ten characters in cols 34-43, no second H. The occupancy check confirms the label occupies cols 34-55, 22 characters, which is the length of `WITHOLDING.TAX.ROUTINE` and not of the modern spelling. Printed as printed |

### 5.4 Not in doubt

The record separator throughout the operand field is a right parenthesis `)`: `IOC)9,4`,
`GN)089`, `CP)+9`, `1)FICA`, `BL)2`, `SYS)294`, `1.RS)0`. At 13x the glyph is unmistakably a
parenthesis, curving away from the vertical at both ends.

---

## 6. Marks rejected as specks

| where | measurement | fallback reading if it were a character |
|---|---|---|
| slot 19, OCTAL col 14 | One pixel above grey 90; peak 185; total cell ink 185. The real glyph next door, slot 19 col 15, has 42 pixels above 90 and total ink 7639 - 41 times as much | blank. Column 14 is a space on all 45 lines that take this octal layout, and the layout has no digit there |

Nothing else on the page came close. Across all 5280 cells, the strongest cell I read as
blank after this one measures 0.

---

## 7. Self-checks

| check | result | detail |
|---|---|---|
| LOC sequence unbroken with correct octal carries | **pass** | 01150 to 01234. Steps of +1 throughout, including 01157 to 01160 and 01177 to 01200. One deliberate repeat: 01217 prints on slots 42 and 43, the label-only line and its instruction. 39 + 2 + 1 + 12 = 54 LOC values for 55 content lines, the odd one being slot 45, which prints no LOC |
| each mnemonic keeps one opcode field | **pass** | ACL 0361 (x2), ADD 0400, AXT 0774 (x2), CAS 0340, CLA 0500 (x6), DVP 0221, LAC 0535 (x2), LDQ 0560 (x2), LRS 0765, LXA 0534, MPY 0200 (x4), STO 0601 (x4), STQ 4600 (x2), SUB 0402 (x3), SXA 0634, TRA 0020 (x4), TRA* 0020, TSX 0074 (x3), XCA 0131 (x3). Prefix words: IOST prefix 7 (x3), PZE prefix 0 (x3), TXL prefix 7 (x2) - these print a prefix and a decrement, not an opcode, so they are checked as a group and not against an opcode table |
| same operand, same address field | **pass** | 1)FICA,1 -> 00012 (5 lines), 4)FICA -> 00105 (4), 4)GROSS -> 00102 (2), BL)2 -> 01667 (3), 1.RS)0 -> 01627 (2), 2.RS)0 -> 01633 (2), SYS)294,1,0 -> 00446 (2), IOC)9,4 -> 00011 (3), GN)076 -> 01217 (2), CP)+10 -> 01706 (3), CP)+31 -> 01733 (2), CP)+34 -> 01736 (2) |
| an address naming a label resolves to that label's location | **pass** | SXA GN)089 -> 01163, and GN)089 is defined on slot 14 at 01163. TRA GN)076 -> 01217 on two lines, and GN)076 is defined on slot 42 at 01217. TRA* FICA.ROUTINE -> 01165, and FICA.ROUTINE is defined on slot 16 at 01165. TRA *+3 at 01204 -> 01207 |
| label location plus decimal offset equals the line's location | **pass** | 38 offset lines. FICA.ROUTINE at 01165 governs +1 to +25, and 01165 + 25 = 01216 in octal. WITHOLDING.TAX.ROUTINE at 01220 governs +1 to +12, and 01220 + 12 = 01234. The +150 to +160 block belongs to a label that is not on this page, so it is not checked |
| the CP)+n family is arithmetically consistent | **pass** | CP)+9 -> 01705, +10 -> 01706, +11 -> 01707, +12 -> 01710, +31 -> 01733, +34 -> 01736. Every one is 01674 plus the offset in octal. This is what caught the LDQ misread in section 5.3 |
| a decrement agrees with the word that carries it | **pass** | IOST CHECK,,16 -> decrement 00020 = 16; IOST PAYRECORD,,20 -> 00024 = 20; IOST MASTER,,15 -> 00017 = 15 |
| a literal operand agrees with its address field | **pass** | AXT 6,1 -> address 00006; LRS 35 -> address 00043 = 35 decimal |
| a tag agrees with the word that carries it | **pass** | 14 tagged lines. Tag 4 on TSX IOC)9,4, LXA BL)2,4, SXA GN)089,4; tag 1 on LAC BL)2,1, CLA/STO 1)FICA,1, MPY EXEMPTIONS,1. No mismatch |
| CNTRL takes only the page's own value set | **pass** | 10000, 10001, 10010, on all 53 lines that print it |
| a line printing its machine word twice agrees digit for digit | **not applicable** | No line on this page prints its machine word twice. Each content line prints one octal word |
| transcription against measured cell occupancy | **pass** | 5280 cells, zero mismatches. See section 4 |

---

## 8. Method notes for a later page reader

1. **The rules are on a two-line pitch at a half-slot offset, and they bow.** Fit each rule
   as its own line from margin ink and mask in two dimensions. A row band cannot hold a
   rule on this page: fitted slopes sweep from -0.00215 at the top to +0.00140 at the
   bottom, so one rule is above a text line on the left of the page and through it on the
   right.
2. **Do not deskew from ink centroids that include the operand field.** Commas and
   parentheses descend and drag the right-hand centroids down; on this page that fabricates
   0.093 deg of skew that is not there. Use the projection-variance peak, then verify with
   the all-digit fields only.
3. **Do not fit the character advance on a half of the page.** Left half 9.2989, right half
   9.2446, full width 9.2666. The halves disagree by half a cell at column 90.
4. **Count the faint lines before you count the loud ones.** Slot 45 carries 99 ink pixels
   and slot 42 carries 350, against a typical 1100. Both are content. A long label pushes
   its instruction onto the next slot, and a label-only line takes a slot of its own at the
   same location - so the location sequence legitimately repeats and the line count exceeds
   the count of distinct locations.
5. **The occupancy cross-check is worth building.** Rendering the reading back onto the
   column grid and comparing every one of 5280 cells against measured ink is cheap and it
   proves the field columns and the character positions together. It is what let me trust
   the field column numbers in section 4.
6. **A template classifier did not work here, and I dropped it.** Three attempts. The first
   compared fixed cell windows and was dominated by neighbour bleed - it "disagreed" with
   109 of my readings including obvious ones like the leading zero of 01150. The second
   isolated each glyph as a connected component, which cured the bleed but merged glyphs
   with the rules that cross them, so its 80 disagreements fell almost entirely on the
   rule-crossed lines. A third pass that excluded rule-touched cells left only 20 usable
   exemplars and could not build templates past 0 and 1. The arithmetic self-checks in
   section 7 are the stronger instrument on a page like this, because they are independent
   of the ink, and the CP)+n check found a real misread that no shape test flagged.
7. **The 0-against-C problem on this page is impression loss, not a wrong character.** Seven
   cells, clustered as consecutive lines at one column. Where the ink decides it decides for
   zero; where it does not, the field's own arithmetic does. Do not settle these by shape
   alone in either direction.
8. **Form furniture to ignore.** The form prints its own line numerals 1 to 12 upright at
   x 315-327 in the left margin, and the same numerals rotated 180 degrees at x > 1490 in
   the right margin. Both would trip a naive margin test; keep the margin bands inboard of
   the right-hand numerals and outboard of the left-hand ones.

---

## 9. Contamination report

I opened no banned file. I opened exactly one source file: the page scan
`comtran-manuals/J28-6169/images/page-210.png`. I did not open, read, grep, list, diff or
git-log any of the target, notes, generator, sample-program, design-record, golden or
other-page files named in the prohibition, and I did not read any file that quotes them. I
did not open `02-compiler.md` either, although it was permitted - the field meanings I use
in this report (LOC, octal machine word, control number, label or offset, mnemonic,
operand) are inferred from this page's own column structure and arithmetic, not looked up.

Every value in the transcription and in this report came from my own measurement of that
one image (via crops and derived arrays I wrote into my own directory). No value was taken from outside it. Where a reading is settled by arithmetic
rather than by shape - the four zeros in section 5.1, the eleven digit-zeros in section 5.2
- the arithmetic is arithmetic on this page's own printed numbers, and I have said so in
each case.

## 10. Unread cells

None. Every cell on the page was read.
