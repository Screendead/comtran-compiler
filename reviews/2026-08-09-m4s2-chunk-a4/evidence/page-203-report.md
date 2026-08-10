# Page 203 (J28-6169) — measurement report

Source: `comtran-manuals/J28-6169/images/page-203.png`, 1650 x 1275, 8-bit
grey, 150 dpi. No other file was opened.

## 1. Deskew

**Angle: 0.855 degrees clockwise.** The page is tilted counter-clockwise;
rotating the image 0.855 degrees clockwise levels it. In PIL terms this is
`Image.rotate(-0.855, resample=BICUBIC)` about the image centre.

Method: maximise the variance of the row-ink profile. The profile was taken
over rows 150-1250 and columns 380-1120 only — that band holds the printed
text and excludes the margins, where the pre-printed form rules print. A
coarse sweep of -2.00 to +2.00 degrees in 0.05 steps peaked at -0.85. A fine
sweep of -0.95 to -0.75 in 0.005 steps peaked at -0.855 (variance 7997.5,
against 7984.0 at -0.860 and 7994.1 at -0.850).

All measurements below are on the deskewed image.

## 2. Line pitch and slot origin

**Line pitch: 15.203 px. First content line at y = 318.25.**

Method: a 55-tooth comb, each tooth a 10-row window, scanned over pitch
15.05-15.40 in 0.001 steps and phase 314.0-322.0 in 0.05 steps, maximising
the summed ink of non-rule rows in columns 385-1250.

The head sits exactly three slots above the first content line:
318.25 - 3 x 15.203 = 272.64, and the head's glyph band measures rows
272-281. The head is therefore on the same slot grid as the body.

## 3. Character grid

**Advance: 9.31916 px. Origin: centre of column 0 at x = 398.838**
(so column 0 spans x 394.2 to 403.5).

Fit: least squares over **2026 intensity-weighted blob centroids** — every
ink blob 3 to 9 px wide on all 56 printed rows — with the column index of
each blob re-assigned and the fit re-run until it converged. The blobs span
**columns 0 to 90**.

- RMS residual **0.585 px** (0.063 of a cell).
- Worst single residual 2.65 px, on a 2-px fragment of a rule-broken glyph.
- Largest |centroid - nearest column| over whole glyphs: **0.25 cell**. The
  single worse case, 0.37 cell, is a 2-px fragment of the `N` in `GN)068`
  on line 7, where the form rule removed the lower rows of the glyph.

Centroids, not left edges, were fitted: the left edge of a cell depends on
the glyph (a `3` starts further right than a `0`), which biases a left-edge
fit by more than a pixel.

**67-advance self-check.** Line 12 of the body (`00366`) prints its machine
word twice, once unspaced in the octal field and once as the operand. The
predicted centre of column 67 is 398.838 + 67 x 9.31916 = 1023.22; the last
operand digit measures at column 67.00. The first location digit of the same
line measures at column 0.04. Measured span 66.96 advances against 67
expected.

## 4. Form furniture, excluded from the transcription

The page carries tractor-feed form rules — solid and dashed — and pre-printed
line-count numbers in both margins. **None of it is printer output and none
of it is in `page-203.txt`.**

- The rules run at **30.36 px** intervals (centres 300.0 to 1150.0, 28
  intervals), which is **1.997 line pitches** — exactly twice the pitch, so a
  rule falls on every second line slot. 150 image rows are rule rows.
- A rule prints into the margins; text never does. Text occupies x 394-1091
  in the body (columns 0-74) and reaches column 90 on the head. Every
  rule row carries ink at x < 392 or x > 1300. That is the test used to flag
  rule rows, and it separates the dashed rules as well as the solid ones. (The
  body's widest line, line 2, ends at x 1091, column 74.) The
  longest-run test named in the method (delete a row whose longest run reaches
  25 px) flags 28 rows, all of them solid rules — it misses the dashed ones.
- The margin line-count numbers sit at x 277-291 (left) and x 1465-1484
  (right), i.e. columns -13 and +114. The far-right ink at x 1376-1387 on
  image row 540 is rule fringe, not a character.
- Because rules cross the text, **cell occupancy alone is not trustworthy**:
  the number of usable rows per content line varies from 5 (line 9) to 12.
  Every cell in the transcription was read from a crop, not from an
  occupancy map.

## 5. Row census

| Kind | Rows |
|---|---|
| Head | **1** (carries values) |
| Blank slots between head and first content line | **2** (both empty) |
| Content lines | **55** (all 55 carry values; **0** are blank) |
| Blank slots inside the body | **0** |
| Total slots from head through last printed line | **58** |

### Proof that the two slots are blank

Sweep of the print zone, x 394-1279, at five thresholds — grey < 100, < 128,
< 160, < 192, < 220 — counting ink pixels per row and separating rule rows
from non-rule rows:

- Slot 2 (rows 286-299): **0 ink pixels on any non-rule row at every
  threshold.** The only ink in that row range is the form rule at rows
  297-300, which prints into both margins.
- Slot 3 (rows 301-314): **0 ink pixels on any non-rule row at every
  threshold**, including < 220.
- The whole gap, rows 283-317: the only non-rule row with any ink is row
  317, and only at < 160 (5 px), < 192 (16 px) and < 220 (25 px). Row 317
  is the anti-aliased top edge of the first content line, whose glyph band
  begins at row 318.

### Proof that the body has no interior blank and ends at line 55

Per-slot non-rule ink at grey < 128, over the print zone: every slot from
line 1 to line 55 carries between 364 px (line 14, the short line that prints
only a location and a label) and 1447 px. The head carries 1525 px. Slots
above the head and below line 55 — modelled slots at k = -4, 55, 56, 57, and
the whole tail rows 1151-1274 — carry **0** non-rule ink at every one of the
five thresholds.

## 6. Field columns, measured

| Field | Columns |
|---|---|
| Location | 0-4 |
| Machine word, spaced 1+5+1+5 | 7, 9-13, 15, 17-21 |
| Machine word, spaced 4+2+1+5 | 7-10, 12-13, 15, 17-21 |
| Machine word, unspaced 12 | 7-18 |
| Control group | 25-29 |
| Label | begins at 34 |
| Offset | right-justified, last character at 42 |
| Mnemonic | 49-51 |
| Operand | begins at 56 |

Counts: 33 lines print the 4+2+1+5 word, 14 print the 1+5+1+5 word, 7 print
the unspaced 12-digit word, and 1 line (line 14) prints no word at all.

The offset is right-justified: `+2` occupies columns 41-42 and `+10` occupies
40-42, both ending at 42. Every offset was placed from its measured blob
column, not from a pattern.

One label overflows its field to the right: `END.OF.RUN` on line 15 runs to
column 43, past the offset field, and that line prints no offset. The other
two labels, `GN)068` on line 7 and `GN)069` on line 14, end at column 39.

The head is on the same grid: `DATE` at 0, `10/18/61` at 5, `TIME` at 15,
`2.45` at 21, `ACCOUNT` at 27, `ID.` at 55, `CT` at 59, `PUBLICATIONS` at 62,
`PAGE` at 83, `12` at 89.

## 7. The `O` / `0` policy

`O` and `0` print the same shape in this chain, so they are separated by
field, not by ink. This is a policy, not a glyph reading, and it decides
these cells:

- **Digits** — the location (columns 0-4), the machine word (7-21), the
  control group (25-29) and the offset (40-42) on every line; the numeric
  suffix of a generated name (`GN)068`, `GN)069`, `SYS)294`, `SYS)133`,
  `SYS)180`, `SYS)182`, `SYS)245`, `SYS)267`, `CP)+46`, `CP)+24`); the digit
  prefix of a data name (`1)`, `2)`, `5)`, `6)`); the twelve-digit operand of
  each `OCT` line; and the trailing subfield of a `PZE` or transfer operand,
  such as the final `0` of `2)BONDEDUCTION,,0` and of `SYS)294,1,0`.
- **Letters** — the mnemonics (`OCT` on seven lines); the head (`ACCOUNT`,
  `PUBLICATIONS`); and the alphabetic body of a data name (`EMPLOYEE`,
  `END.OF.RUN`, `GROSS`, `BONDEDUCTION`, `HOURS`).

Two of these are confirmed independently, not merely assumed. The final `0`
of `2)BONDEDUCTION,,0` on line 38 is matched by a decrement of `00000` in
that line's machine word, exactly as `,,5`, `,,3`, `,,1` and `,,4` are matched
by decrements of 5, 3, 1 and 4 on the sibling `PZE` lines. The final `0` of
`SYS)294,1,0` on line 1 is matched by a decrement of `00000` in its word.

## 8. Doubtful glyphs

**One glyph could not be settled by ink. Everything else on the page was
read from the scan.**

### 8.1 Line 7, column 56: `B` or `8` — settled by name structure, not by shape

The operand of the `CAL` on line 7 reads `?L)3`. The first character is a
double-loop form. It is **not** decidable by shape on this page:

- The two certain `B` glyphs in the body — `5)BONDEDUCTION` on line 36 and
  `2)BONDEDUCTION` on line 38 — print as double-loop forms almost identical
  to the certain `8` glyphs in `10/18/61` (head), `GN)068` (line 7 label) and
  `SYS)180,4`.
- Normalised cross-correlation, best of nine +/-1 px alignments: the doubtful
  glyph scores 0.874, 0.855, 0.827, 0.820, 0.825, 0.866 against the six
  certain `8`s, and 0.622, 0.850, 0.851 against the three certain `B`s. Run
  the same test between the classes and it does not separate them either: the
  two body `B`s score 0.755-0.893 against the six certain `8`s, and the head
  `B` scores 0.519-0.864. The ranges overlap; the test carries no
  information.
- Two structural tests also fail to separate the classes. Left-edge
  straightness: the certain `B` in the head has a broken outer column like an
  `8`. Left-half against right-half ink weight: `B` gives 0.49, 0.52, 0.57;
  `8` gives 0.43 to 0.55; the doubtful glyph gives 0.50.

**Decided by name structure.** Every other name prefix on this page is either
all letters (`SYS`, `GN`, `CP`) or a single digit (`1`, `2`, `5`, `6`). A
two-character prefix that mixes a digit and a letter appears nowhere. `BL)3`
follows the letter-prefix pattern; `8L)3` would be unique on the page. The
transcription reads **`BL)3`**. A reader who wants the alternative should know
it is `8L)3` and that the ink does not choose between them.

### 8.2 Line 21, column 30: a speck, not a period

A small mark prints just right of the control group on line 21 (`00376`). It
is **not** a character and is not in the transcription:

- 4 ink pixels, darkest value 26. Every printed period on this page is 11 to
  15 ink pixels with a darkest value of 0 — measured on `2.45` and `ID.` in
  the head, on `END.OF.RUN`, on `HIGH.DETAIL` and on `DEPARTMENT.END`.
- Its centroid sits at column 29.80, between cells, whereas every printed
  period sits at x offsets 3-7 within its cell.
- It occupies image rows 629-630 only, two rows, above the baseline at row
  631.

### 8.3 Three `0` glyphs printed with a broken ring

The chain dropped the right stroke of a `0` on three cells, which at first
sight read as `C` or `)`:

- Line 52 (`00435`), machine word, column 9 — the ring is open on the right
  for six rows.
- Line 54 (`00437`), machine word, column 9.
- Line 55 (`00440`), control group, column 26.

All three are inside a numeric field (machine word or control group), so all
three are `0`. Each was compared at high zoom against a clean `0` on line 1,
column 1, which shows the closed ring these three are missing.

### 8.4 The asterisk on lines 4 and 15

`*+2` (line 4) and `*+3,7` (line 15) begin with a solid blob 5-6 px wide and
6 rows tall, vertically centred and clear of the baseline. It is far larger
than a period (3 rows, at the baseline) and than a comma. The two instances
agree in size and placement. The reading is confirmed arithmetically: line 4
is at `00356` and its machine word addresses `00360` = 00356 + 2; line 15 is
at `00370` and its word addresses `00373` = 00370 + 3.

## 9. Self-checks run

| Check | Result |
|---|---|
| Double-printed machine word, octal field (7-18) against operand (56-67) | 7 lines checked, **7 match digit for digit** |
| Octal location continuity | `00353` to `00440`, **no break**; all seven carries correct (`00357`->`00360`, `00367`->`00370`, `00377`->`00400`, `00407`->`00410`, `00417`->`00420`, `00427`->`00430`, `00437`->`00440`) |
| Location `00370` printed twice | Yes — line 14 prints the location and the label `GN)069` alone, line 15 reprints `00370` with its word. Consistent with a label line that reserves no storage. |
| 67-advance grid check | Predicted column-67 centre 1023.22; measured 1023.0 |
| Transcription against ink, cell by cell | Every one of the 56 printed rows: every measured ink blob falls in a cell that carries a character, and every character sits on a cell that carries ink. The **only** exception is the column-30 speck of section 8.2 |
| Opcode prefix against mnemonic | 11 distinct mnemonics, **no mismatch**: `TRA`/0020, `TSX`/0074, `CLA`/0500, `SLW`/0602, `ACL`/0361, `SXA`/0634, `AXT`/0774, `LRS`/0765, `DVP`/0221, `CAL`/4500, `LAS`/4340; and prefix 7 for `TXL`, 1 for `TXI`, 0 for `PZE` |
| Operand tag and decrement against the machine word | 47 lines carry a checkable tag or decrement, **0 mismatches** |
| Address of line 11 | `00365`, the line's own location. Every other `TXI` on the page addresses `00413`. This is what the ink says: the address field was read twice, and it is not a transcription error |
| Address against label | `TRA GN)068` (lines 3 and 5) addresses `00361`, the location of the `GN)068` label line; `TRA END.OF.RUN` (line 6) addresses `00370`, the location of the `END.OF.RUN` label line; `TRA DEPARTMENT.END+1` addresses `01474`, one past the `01473` of `SXA DEPARTMENT.END`; `ACL CP)+46` addresses `01752` and `DVP CP)+24` addresses `01724`, a difference of 22 words for an operand difference of 22; `LRS 35` addresses `00043`, which is 35 in decimal |

## 10. What could not be read

Nothing was illegible. Every cell on the page was resolved.

Two readings do not rest on the shape of their ink, and a later reader should
know which:

1. `B` in `BL)3` on line 7 — resolved by name structure (section 8.1). This
   is the only such case beyond the systematic `O`/`0` policy.
2. Every `O`/`0` on the page — resolved by field (section 7). The chain
   prints one shape for both.
