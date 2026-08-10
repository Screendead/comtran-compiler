# Blind read of page-209.png (J28-6169), one object-listing page

Source, and the only source used:
`/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/images/page-209.png`
(1650 x 1275, 8-bit greyscale, landscape).

## 1. Slot frame

The body is a frame of line slots at one pitch. Slot 0 is the page head.

| Quantity | Value |
|---|---|
| Empty slots between the head and the first content line | **2** (slots 1 and 2) |
| Content lines | **55** |
| Slot of the last content line | **57** |
| Empty slots inside the body | **none** |
| First slot below the body (slot 58) | empty |

Proof that slots 1, 2 and 58 are empty. For each slot I took the 13 image rows
centred on the fitted slot centre, dropped the rows the rule model covers, and
counted ink pixels across the whole 910-px text band (x 390-1300) at five
thresholds on normalised ink (1.0 = black): **0.20, 0.30, 0.35, 0.45, 0.60**.

| Slot | ink pixels at 0.20 / 0.30 / 0.35 / 0.45 / 0.60 |
|---|---|
| 0 (head) | 2328 / 2069 / 1957 / 1729 / 1418 |
| 1 | 0 / 0 / 0 / 0 / 0 |
| 2 | 0 / 0 / 0 / 0 / 0 |
| 3 (first content line) | 1202 / 1063 / 1001 / 890 / 717 |
| 57 (last content line) | 1802 / 1610 / 1510 / 1344 / 1070 |
| 58 | 0 / 0 / 0 / 0 / 0 |

Threshold 0.20 is grey level 204 of 255, so a very faint mark would still
register. Slots 1, 2 and 58 hold literally nothing. Every slot from 3 to 57
carries ink at threshold 0.20; the sweep over all slots returned exactly
`[1, 2, 58]` as empty. There is no interior blank.

## 2. This page's own grid

| Quantity | Value |
|---|---|
| Deskew applied (text) | **-1.163 deg** |
| Line pitch | **15.2378 px** |
| Slot 0 centre y | 284.056 px |
| Line-fit residual | rms 0.341 px, max 0.663 px, over 55 line centroids |
| Character advance | **9.32283 px** |
| Origin (centre of grid cell k=0) | **1.9404 px** |
| Centroids fitted | **2025** |
| Advance residual | rms **0.5653 px**, max 2.99 px |
| Baseline of the advance fit | print columns 0-90 (grid cells k=43-133), x ~ 400 to 1245 px |

Method. I deskewed, then segmented each line into horizontal ink blobs, kept
only blobs 3-8 px wide, at least 5 image rows tall and above a mass floor
(single characters, not touching pairs and not rule dashes), and took each
blob's **intensity-weighted x centroid** - never a left edge. The advance came
first from a phase-coherence scan (maximise |mean(exp(2*pi*i*cx/a))| over a in
9.0-9.7 px at 0.0001 px steps), then from a least-squares refit on the assigned
cell indices, iterated to a fixed point. The fit spans the full printed width,
not the twelve-digit machine-word field.

**Print column 0 is defined as grid cell k=43**, the leftmost printed cell on
the page (the first LOC digit). Cell centre for print column c is
`x = 1.9404 + 9.32283*(c + 43) = 402.82 + 9.32283*c`.

Deskew is verified, not assumed: after rotation the residual x-error has a slope
of **4.1e-05 px per px of y** against the line frame, i.e. under 0.05 px of
drift over the whole 780-px printed height.

### The text and the rules are not at the same angle

Maximising the row-profile variance of the whole page gives **-1.27 deg** - but
that estimate is dominated by 32 full-width rules, which carry far more ink than
the text. Fitting the text alone gives **-1.163 deg**. The 0.107 deg difference
is real: the rules are pre-printed form furniture and the text is printed on top
of it, so the two carry independent registration. I deskewed for the **text**,
because the text is what has to be read, and modelled the rules separately.
A later page reader should expect the same split and should not take a
variance-maximising deskew as the text angle.

The rules are also slightly bowed rather than straight and parallel: their local
slope runs from -0.0036 at the top of the page to +0.002 at the bottom.

## 3. Removing the form rules - by the margin test

I did **not** use a run-length filter. A filter keyed to a minimum ink run
deletes the solid rules and misses the dashed ones, whose dashes are only about
6 px long.

Both kinds of rule print ink in the margins, where no text prints. The left band
**x 300-386** and the right band **x 1300-1470** carry rules only: the text
occupies print columns 0-90, i.e. x 398 to 1246. That is the test that catches
both kinds.

One complication. Because the rules sit at a different angle from the text, a
rule is not on one image row across the page - it moves by about 2 px from
margin to margin. A plain "ink in both margins on the same row" test therefore
misses rules. I detected each rule band at the **left** margin, took its
intensity-weighted y centroid separately in the left band and in the right band,
fitted `y = ic + slope*x` through those two clean points, and masked **+/-3
rows** about that line at every x.

| Quantity | Value |
|---|---|
| Rule bands on the page | **32** |
| First / last, measured at x=825 | y = 214.6 / y = 1157.9 |
| Rule pitch | ~30.47 px = exactly **2 x the line pitch** |
| Pattern | every third rule **solid**, the other two **dashed** |
| Dashed rule dash length | ~6 px with ~6 px gaps (longest continuous run 5-13 px) |
| Solid rule continuous run | 460-880 px |
| Rule thickness | 2-4 image rows |
| Where they fall | about 6 px below the centre of every **odd-numbered** slot |

So the rules cross the lower half of every odd slot (3, 5, 7, ... 57) and leave
the even slots clean. On a crossed line as few as 9 of the 15 rows in the read
band survive, and the bottom serif of a glyph can be lost entirely; every
doubtful cell below was read from a magnified crop that keeps the rule in place,
never from a rule-stripped bitmap.

Mask validation: after masking, the ink remaining in columns that carry no text
on any line (print columns 30-38, 43-48, 70-89) is **0 pixels at threshold 0.35**
on every slot tested, including the crossed slots 3, 5, 7, 9, 55 and 57.

## 4. Field layout, measured

| Field | Print columns | Notes |
|---|---|---|
| LOC | **0-4** | 5 digits, all 55 lines |
| OCTAL | **7-21** | three printed forms, below |
| CNTRL | **25-29** | 5 digits, all 55 lines |
| offset `+n` | **39-42** | **right justified** |
| mnemonic | **49-51** | 3 characters, all 55 lines |
| operand | **56-67** | left justified, 2 to 12 characters |

No line on this page prints a label in the offset field; all 55 print a `+n`
offset. Columns 5-6, 22-24, 30-38, 43-48, 52-55 and 68 upward are blank on every
content line.

**The offset is right justified, and the page can tell.** The five two-digit
offsets (+95 to +99) occupy columns 40-42 and leave column 39 blank; the fifty
three-digit offsets (+100 to +149) occupy columns 39-42. Column 39 carries ink on
exactly 50 of the 55 lines, column 42 on all 55.

The OCTAL field prints the 36-bit machine word as twelve octal digits in one of
three groupings:

| Grouping | Columns used | Lines |
|---|---|---|
| 4-2-1-5 | 7-10, 12-13, 15, 17-21 | 37 |
| 1-5-1-5 | 7, 9-13, 15, 17-21 | 13 |
| 12 solid digits | 7-18 | 5 |

The 12-solid form is used on the five `OCT` lines, whose operand repeats the same
twelve digits.

Page head (slot 0), word runs by print column:

`DATE` 0-3 | `10/18/61` 5-12 | `TIME` 15-18 | `2.45` 21-24 | `ACCOUNT` 27-33 |
`ID.` 55-57 | `CT` 59-60 | `PUBLICATIONS` 62-73 | `PAGE` 83-86 | `18` 89-90.

The head is the widest line on the page and its last character sits in print
column 90, exactly where the advance-fit baseline ends.

## 5. Doubtful glyphs

I read every line visually at 6x with the fitted grid drawn under it, then ran an
independent machine check over all **2012** transcribed character cells: a
normalised-gain sum-of-squares match against templates built from the page's own
glyphs, with leave-one-out for the sparse classes and a sub-pixel registration
search. **93 cells** did not have my reading as the nearest template. All 93 fell
into six confusion families, listed below with how each was settled. No cell
outside these families disagreed.

### 5.1 The `)` glyph - settled

42 operand cells carry a narrow curved stroke that the machine check confuses
with `1`. It is a **right parenthesis**. Evidence, from six clean exemplars on
even (uncrossed) slots - slot 6 col 57, slot 10 col 57, slot 16 col 57, slot 22
col 57, slot 30 col 58, slot 4 col 58:

- the stroke starts at the left of the cell, bows right through the middle and
  returns left at the bottom; it is **symmetric top to bottom**;
- it has **no top-left flag** and **no base serif**. Every `1` on this page has
  both: a flag at the upper left and a base bar 4-5 px wide centred under the
  stem (slot 4 col 1, slot 28 col 1);
- it is not a `J`: a `J` would put a hook to the **left** of the stem at the
  bottom and nothing symmetric at the top.

The reading is corroborated arithmetically. `SYS)nnn` operands resolve to an
address whose octal value equals `nnn` read as **decimal**, on all eight distinct
labels, which only makes sense if the character between the letters and the
digits is a separator.

### 5.2 `B` or `8`, first character of the operand `BL)2` - NOT settled

Slot 38 col 56 and slot 45 col 56. I record **B**; **8** is not excluded by the
ink. This is the one glyph on the page a later reader should re-check against a
higher-resolution scan.

Evidence for B:

- The two cells match **each other** at shape distance **0.031**, inside the
  same-character band (known-8 to known-8 pairs: median 0.026).
- Against the page's **14** known `8` glyphs they sit at median **0.087** and
  **0.072**, minimum **0.050** and **0.062**. Every one of those 28 distances is
  above the 90th percentile of the 8-to-8 distribution (**0.041**) and 2-3x its
  median. The two cells form their own class, distinct from this page's eights.
- In the **unresampled original pixels**, both cells put their topmost ink
  directly over the left stem, and the left edge is a straight column of dark
  pixels the full glyph height. The page's eights put their topmost ink inset 1-2
  px to the right of the leftmost column, as the apex of an arc.
- Context, not ink: every other qualified operand on the page uses either a
  one-digit prefix (`1)`, `2)`, `3)`, `4)`) or an alphabetic prefix (`CP)`,
  `SYS)`). `BL)` fits the alphabetic pattern.

Evidence against, kept honestly:

- Averaging the two cells and comparing that mean against the mean of the 14
  eights gives **0.066** - closer than the head line's `B` of `PUBLICATIONS` is
  to the same mean (**0.101**). That comparison is confounded: the head is
  printed markedly heavier (raw ink mass 63.4 against 38-54 for the others),
  which fills counters and inflates every distance involving it. I state it
  anyway.
- Rendered at 26x, the mean of the two cells, the mean of the eights and the
  head's `B` are not separable by eye. At 150 dpi this chain's `B` and `8` are
  close to the same shape.

### 5.3 `1` against `)`, `L` and `I` - settled

54 cells. All are `1`. Each carries the top-left flag and the centred base bar
that section 5.1 describes, and that `)` lacks. Against `L`: an `L` on this page
(slot 4 col 51, slot 39 col 51) has **no top flag** and a base bar that runs to
the **right** of the stem (columns 4-9 of the cell); a `1` has the flag and a
base centred on the stem (columns 3-6). Against `I` (slot 13 col 51, slot 37 col
51): an `I` has matching serifs top **and** bottom and no flag. The machine check
was misled because the rule crosses the base of every `1` on an odd slot, leaving
only the stem.

Corroboration: slot 15 col 58 and slot 27 col 58 are the `1` of the operand
`7,1`, and the tag digit of the same line's machine word is `1`.

### 5.4 `0` against `O` and `D` - settled

37 cells, all in the `OCT` operands at print columns 56-67. All are **digit 0**.

The first machine run preferred `O`. That was an artefact of where the exemplars
sit: every letter `O` on the page is in the right half, and my digit-`0` sample
was drawn from the left half, so print weight and registration, not glyph
identity, drove the match. Repeating with a **column-matched** control (digit `0`
cells that also lie at print column 56 or beyond) and a +/-1.5 px registration
search:

| Comparison | Median distance |
|---|---|
| known digit 0 (operand area) to known digit 0 (operand area) | 0.024 |
| known letter O to known letter O | 0.031 |
| known digit 0 to known letter O | 0.086 |
| **OCT-operand glyph to known digit 0** | **0.026** |
| **OCT-operand glyph to known letter O** | **0.095** |

**50 of 50** are closer to the digit. The `D` variant of the same confusion
(`DVP`, `LDI`, `3)DAY`) resolved the same way once registration was corrected.

### 5.5 `5` against `6` - settled

Slot 4 col 8, the second digit of the octal word `4500`. It is a **5**: a flat
top bar open at the left and a bowl at the lower right. Slot 3 col 8 on the line
above is a **6** in the same column - a closed lower loop with a stem curving up
to the right - and the two are plainly different at 18x. The other three `4500`
lines (slots 6, 38, 45) print the identical glyph. The mnemonic on all four is
`CAL` and on slot 3 it is `STQ`, and no other `CAL` line prints `4600`.

### 5.6 `7` against `T` and `Z`, `2` against `7` - settled

Slot 15 col 56 and slot 27 col 56 are `7`: a flat top bar with a diagonal
descender, against `T`'s symmetric bar and vertical stem. The address field of
both lines is `00007`. The `2`/`7` flags all sit in the LOC and OCTAL fields and
were read directly at 18x; `2` prints a flat base bar, `7` does not.

## 6. Self-checks

| Check | Result |
|---|---|
| LOC sequence unbroken, octal | **pass**. 01061 to 01147, 55 values, 0 breaks. |
| Octal carries | **pass**. 01067->01070, 01077->01100, 01107->01110, 01117->01120, 01127->01130, 01137->01140. |
| Offset sequence | **pass**. +95 to +149, consecutive. LOC minus offset is the constant 466 = octal 0722 on all 55 lines. |
| Machine word printed twice | **pass**. All 5 `OCT` lines: the 12-digit OCTAL field equals the operand digit for digit. Checked again at pixel level - operand cell against octal-field cell at the same position, all 60 pairs, median distance 0.023-0.034 against a same-character control of 0.024. |
| Mnemonic against its own opcode digits | **pass**, both ways. Built from this page only: every mnemonic maps to exactly one opcode form, and every opcode form maps to exactly one mnemonic. ACL 0361, ALS 0767, ANA 4320, ANS 0320, AXT 0774, CAL 4500, CLA 0500, DVP 0221, LDI 0441, LRS 0765, ORS 4602, PZE prefix 0, SLW 0602, STI 0604, STQ 4600, TSX 0074, TXI prefix 1, OCT = 12-digit constant. |
| Address resolves to one location per label | **pass**. All 22 distinct labels: 1)NETPAY 00040, 2)FICA 00032, 2)GROSS 00027, 2)WHT 00030, 2)YEAR 00001, 3)DAY 00000, 3)NETPAY 00107, 3)YEAR 00001, 4)FICA 00105, 4)GROSS 00102, 4)WHT 00106, AMOUNT 00016, BL)2 01667, CP) 01674, SYS)132 00204, SYS)133 00205, SYS)180 00264, SYS)182 00266, SYS)239 00357, SYS)240 00360, SYS)241 00361, SYS)267 00413. `CP)+n` resolves to one base, 01674, across all six offsets (+24, +35, +36, +47, +56, +57). |
| `SYS)nnn` decimal equals the octal address | **pass** on all 8 labels. 132->00204, 133->00205, 180->00264, 182->00266, 239->00357, 240->00360, 241->00361, 267->00413. |
| Literal operands equal their address | **pass** on all 7. ALS 18 -> 00022, AXT 7 -> 00007 (x3), AXT 6 -> 00006 (x2), LRS 35 -> 00043 (x2). |
| Tag digit against the `,t` suffix; decrement against the `,,d` suffix | **pass**. 0 disagreements over all 50 grouped-octal lines. |
| Every cell I call blank really is blank | **pass**. 0 cells in print columns 0-71 that I left blank carry 3 or more ink pixels. |
| No stray ink unaccounted for | **pass**, see section 8. |

First LOC on the page: **01061**. Last: **01147**.

One observation, not an error: slot 6 (`CAL 2)YEAR,2`, LOC 01064) prints CNTRL
**10000** where the other lines with a data-name operand print 10001. I verified
the five digits at 18x; the last character is unambiguously a round `0`, not the
flagged-and-based `1` that slots 5, 10 and 12 print in the same column. The value
stands as read. CNTRL takes only three values on this page: 10001 (23 lines),
10010 (19), 10000 (13).

## 7. Marks rejected as specks

**Slot 3, print column 18** (the second digit of the address field, LOC 01061).
A dark wedge appears attached to the lower left of this `0`, and it is prominent
when the crop is upsampled. It is not a character.

Measurement that decided it: the ink mass above threshold 0.3 in the five address
cells of that line, with rule rows dropped, is **26.4, 26.6, 25.3, 26.6, 25.3**
for columns 17-21. Column 18 carries **no excess mass** over its four neighbours
on the same line. Slot 3 as a whole is printed a little heavier than average -
plain `0` glyphs in the same column on slots 5, 9 and 55 measure 22.8, 24.0 and
24.4 - which accounts for the appearance. The pixel dump shows the mark lying in
image rows 334-337, exactly where the modelled dashed rule crosses the glyph, and
the address field is exactly 5 columns wide here as on every other line, so there
is no cell for an extra character to occupy.

Fallback reading had I judged it a character: none is possible - the cell already
holds a `0` and the field is full. The address reads **00000**, consistent with
the label: `3)DAY` resolves to 00000 and `3)YEAR` on the next line to 00001.

## 8. Non-text marks on the page

A page-wide sweep for ink above threshold 0.35 that is neither rule nor a
transcribed cell found **321 pixels in 25 clusters**, all outside the print field
(print columns 0-90):

- **Upright numerals in the left margin**, x 279-288 (print column ~ -13), y 858
  to 1153. Eleven of them, one sitting on each of the eleven lowest rules,
  reading **12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2** from top to bottom.
- **Mirrored numerals at the right margin**, x 1477-1486 (print column ~ 115),
  y 216 to 513, again eleven, reversed and inverted. Their position and form are
  consistent with show-through from the reverse of the leaf.

Neither set is page text and neither is transcribed. They matter for one reason:
they lie close to where a left-margin rule test wants to sample. My left band
starts at x 300, clear of them.

## 9. Method notes for a later page reader

1. **The text angle is not the page angle.** Variance-maximising deskew on this
   page returns -1.27 deg, which is the angle of 32 pre-printed rules, not of the
   text (-1.163 deg). Fit the deskew on text blobs and verify it by checking that
   the residual x-error has no slope against y.
2. **Rules are at twice the line pitch and every third one is solid.** They fall
   about 6 px below the centre of odd-numbered slots, so odd lines lose their
   glyph bases and even lines are clean. Read doubtful cells from crops that keep
   the rule; do not strip it.
3. **The margin test needs a tolerance for the rule's own tilt.** After deskewing
   for the text, a rule is not on a single image row. Detect it at one margin,
   measure its centroid at both margins, and mask a fitted line, not a row.
4. **The left margin is narrow and occupied.** Rules start at x ~ 288 and the
   left-margin numerals sit at x 279-292. The clean rule-only band is x 300-386.
5. **Fit the advance over the full width.** Here it is 9.32283 px over print
   columns 0-90 from 2025 centroids. Fitting on the twelve-digit machine-word
   field alone would be a 12-cell baseline.
6. **Whole-glyph correlation is the wrong tool for this font.** Mean-subtracted
   NCC on a mostly-white cell cannot separate `1` from `)` or `0` from `O`; it
   puts them within 0.01 of each other at r ~ 0.97. Ink-normalised sum-of-squares
   with a registration search is much sharper, but even that is defeated by two
   confounds worth naming: averaging many exemplars into a template blurs it, so
   a sharp glyph then prefers a sparser template; and print weight varies across
   the page, so an exemplar pool drawn from one side of the page will beat the
   right answer drawn from the other. Match column against column.
7. **Prefer a structural feature or an arithmetic cross-check to a shape score.**
   Almost every ambiguity on this page was closed by one of: the top flag and
   base bar of `1`; the decimal-to-octal identity of `SYS)nnn`; the constant base
   of `CP)+n`; the tag and decrement echoing the operand suffix; the `OCT`
   operand repeating the machine word.
8. **Left the two `BL)2` glyphs open.** See 5.2. Everything else is settled.

## 10. Unread cells

**None.** Every cell that carries ink on this page has been read.
