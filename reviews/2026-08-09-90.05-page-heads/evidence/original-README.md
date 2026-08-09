# Page-head columns — evidence for review

**Untracked. Delete this directory when you are done with it.**

This is the evidence behind the 25-line change to
`comtran-manuals/J28-6169/90.05-sample-program.md`. Every claim below is
checkable by eye in the images.

## How to read the images

Each image is a crop of the page head from the deskewed page scan, at 2x,
with a column ruler underneath. Column 0 is the D of `DATE`, which is M1-15's
definition of D.

- **Solid red** — the measured column, now applied to the conversion.
- **Dashed green** — the column that *that page's own transcribed head* put
  the field at, before this change.

Where a red line lands on the left edge of a glyph, the measurement is right.
Where a green line lands in white space or inside a letter, the transcription
was wrong there. Where the two coincide, that page's transcription was already
correct for that field.

## The five pages

### PDF p. 195 — source listing, listing page 4

![page 195 head](page-195-head.png)

Green misses at `TIME`, the time value, `ACCOUNT`, `ID.`, the identifier and
the page number. Green matches at `DATE`, the date value and `PAGE`.

### PDF p. 196 — source listing, listing page 5

![page 196 head](page-196-head.png)

The same six misses. This is the second page of the group that the compiler's
own head template was copied from.

### PDF p. 198 — loader control cards, listing page 7

![page 198 head](page-198-head.png)

This page is its own spacing group of one, and it was not measured before
today. Green matches at the time value and misses at `TIME` by one and at
`ACCOUNT` by one, then runs four and five columns adrift at `ID.`, the
identifier, `PAGE` and the page number.

### PDF p. 199 — object listing, listing page 8

![page 199 head](page-199-head.png)

Green matches at the time value, `ID.` and the identifier, misses at `TIME`
and `ACCOUNT` by one, and falls short at `PAGE` and the page number by three
and four. The single digit `8` sits at column 89.

### PDF p. 212 — object listing, listing page 21

![page 212 head](page-212-head.png)

Green matches through `ACCOUNT` and then misses at every field to the right.
The two digits of `21` sit at columns 89 and 90, which is what settles the
page number as left-aligned at 89 rather than right-aligned ending at 90.

The form's dashed guide rule crosses this head. It is visible in the crop
because the crop is the untouched scan; the measurement deleted it first.

## What the transcription held

Four different spacings across the 25 heads, none of them the print's.
Columns are relative to `DATE`.

| Heads | `TIME` | time | `ACCOUNT` | `ID.` | identifier | `PAGE` | number |
|---|---|---|---|---|---|---|---|
| **the print** | 15 | 21 | 27 | 55 | 59 | 83 | 89 |
| listing pages 1–6 | 16 | 22 | 29 | 56 | 60 | 83 | 90 |
| listing page 7 | 16 | 21 | 28 | 60 | 64 | 88 | 93 |
| listing pages 8–16 | 16 | 21 | 28 | 55 | 59 | 80 | 85 |
| listing pages 17–25 | 15 | 21 | 27 | 60 | 64 | 87 | 93 |

`DATE` at 0 and the date value at 5 were right in all four.

## The change, one line per group

```
p1-6   -        DATE 10/18/61   TIME  2.45   ACCOUNT                    ID. CT PUBLICATIONS        PAGE   1
       +        DATE 10/18/61  TIME  2.45  ACCOUNT                     ID. CT PUBLICATIONS         PAGE  1

p7     -DATE 10/18/61   TIME 2.45   ACCOUNT                         ID. CT PUBLICATIONS         PAGE 7
       +DATE 10/18/61  TIME  2.45  ACCOUNT                     ID. CT PUBLICATIONS         PAGE  7

p8-16  -DATE 10/18/61   TIME 2.45   ACCOUNT                    ID. CT PUBLICATIONS      PAGE 8
       +DATE 10/18/61  TIME  2.45  ACCOUNT                     ID. CT PUBLICATIONS         PAGE  8

p17-25 -    DATE 10/18/61  TIME  2.45  ACCOUNT                          ID. CT PUBLICATIONS        PAGE  17
       +    DATE 10/18/61  TIME  2.45  ACCOUNT                     ID. CT PUBLICATIONS         PAGE  17
```

All 25 heads now carry one spacing, and it is byte-identical to the head the
compiler prints in `test/goldens/90.05-payroll.listing`.

## What was not changed

**The left margin.** The four groups still start 8, 0, 0 and 4 spaces in from
the left. The conversion flattens the head-to-body margin, M1-15 records that,
and this change does not touch it. You still may not read an absolute column
out of the transcription — only the spacing between the head's own fields is
now true.

**The column header.** `LOC OCTAL CNTRL SYMBOLIC` on line 672 is the only one
in the file. It is transcribed at 0, 11, 26 and 54; the scan measures 1, 12,
25 and 58. That is a separate erratum candidate and I have not touched it.
Say the word and it is a one-line change with the measurement already done.

## Method

Per page: deskew by the angle that maximises the variance of the row profile;
delete the guide-rule rows, which carry a horizontal ink run of up to 381 px
where the worst glyph row carries 7; fit the character pitch by
autocorrelation of the page's own body ink; read each glyph's left edge.

Registration differs page to page, so each page is anchored on its own `DATE`
and fitted on its own pitch — never on another page's.

| Page | Deskew | Pitch px | Glyph runs read |
|---|---|---|---|
| 195 | −0.44° | 9.3306 | 39 |
| 196 | +0.56° | 9.3050 | 38 |
| 198 | +0.52° | 9.2430 | 35 |
| 199 | −0.32° | 9.2736 | 38 |
| 212 | +0.96° | 9.2412 | 40 |

`measurements.json` holds every glyph's measured column for all five pages.
Across 190 glyph readings, every one lands within a quarter of a cell of an
integer column, which is the check that the pitch and the anchor are right.

## To reproduce

Both scripts sit in this directory. Run them from the repository root, which
is where they expect to find `comtran-manuals/` and write their output:

```sh
python3 review-page-heads/evidence.py       # re-measures the five pages and redraws these images
python3 review-page-heads/rewrite_heads.py  # rewrites the 25 heads; already applied, so a no-op now
```

They need PIL and NumPy and nothing else.
