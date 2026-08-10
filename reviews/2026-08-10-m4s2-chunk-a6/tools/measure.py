"""Measure the line bands of PDF p. 210, and name each one by its fields.

Every figure item A quotes comes from here. Run it from anywhere:

    python3 tools/measure.py

**Why it names the bands.** The first version of this record quoted the ink of
the wrong line: it took the faintest band the detector kept and called it the
wrapped instruction, when that band is the label-only line two lines above.
A band is only identifiable by where its ink sits, so this script prints the
field columns of every band it finds and never reasons from ink weight alone.
"""

import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
SCAN = os.path.join(REPO, "comtran-manuals", "J28-6169", "images", "page-210.png")

# The page 210 reader's own deskew and grid, not a fresh fit.
DESKEW, ORIGIN, ADVANCE = 1.2658, 437.374, 9.2666

# The printed text never leaves this span; the margins either side carry the
# form rules and the ruled form's own line numbers, and no text at all.
TEXT = (430, 1290)
LEFT_MARGIN = (310, 410)
RIGHT_MARGIN = (1330, 1460)

# The wrapped instruction, located by eye on the scan and confirmed below.
WRAPPED = (861, 870)

im = Image.open(SCAN).convert("L").rotate(DESKEW, resample=Image.BICUBIC, fillcolor=255)
a = 255 - np.asarray(im, dtype=float)

text = a[:, TEXT[0]:TEXT[1]].sum(axis=1)
left = a[:, LEFT_MARGIN[0]:LEFT_MARGIN[1]].sum(axis=1)
right = a[:, RIGHT_MARGIN[0]:RIGHT_MARGIN[1]].sum(axis=1)
# A form rule prints in both margins. A run-length filter cannot do this job:
# the dashed rules print in 6 px dashes, which no run-length test separates
# from text.
rule = (left > 200) & (right > 200)


def bands(fraction):
    on = (text > text.max() * fraction) & ~rule
    out, y = [], 0
    while y < len(on):
        if on[y]:
            start = y
            while y < len(on) and on[y]:
                y += 1
            if y - start >= 6:              # a text line is 10 to 15 rows
                out.append((start, y - 1, text[start:y].sum()))
        else:
            y += 1
    return out


def fields(y0, y1):
    """The print columns where this band's ink starts."""
    col = a[y0:y1 + 1, 420:1300].sum(axis=0)
    on = col > col.max() * 0.06
    runs, x = [], 0
    while x < len(on):
        if on[x]:
            start = x
            while x < len(on) and on[x]:
                x += 1
            if x - start > 2:
                runs.append([start + 420, x - 1 + 420])
        else:
            x += 1
    if not runs:
        return []
    merged = [runs[0]]
    for start, end in runs[1:]:
        if start - merged[-1][1] < 7:
            merged[-1][1] = end
        else:
            merged.append([start, end])
    return [round((start - ORIGIN) / ADVANCE) for start, _ in merged]


loose, tight = bands(0.02), bands(0.01)
median = float(np.median([b[2] for b in loose]))
wrapped_ink = a[WRAPPED[0]:WRAPPED[1] + 1, TEXT[0]:TEXT[1]].sum()
faintest_kept = min(loose, key=lambda b: b[2])

print(f"median ink over the bands        {median:>12,.0f}")
print(f"the wrapped line, rows {WRAPPED[0]}-{WRAPPED[1]}  {wrapped_ink:>12,.0f}"
      f"   {wrapped_ink / median:.2f} x median")
print(f"  its ink sits at print columns  {fields(*WRAPPED)}"
      "   (the mnemonic and the operand, and nothing else)")
print(f"faintest band a 2% pass keeps    {faintest_kept[2]:>12,.0f}"
      f"   {faintest_kept[2] / median:.2f} x median"
      f"   rows {faintest_kept[0]}-{faintest_kept[1]}, columns {fields(faintest_kept[0], faintest_kept[1])}")

# The band the 1% pass draws around the wrapped line runs one row into the
# form rule below it, so its figure is not the line's ink. Quote the glyph
# rows, which is what WRAPPED bounds.
detected = [b for b in tight if WRAPPED[0] <= b[0] <= WRAPPED[1]]
if detected:
    start, end, ink = detected[0]
    print(f"  the 1% pass draws that band as rows {start}-{end}, ink {ink:,.0f};"
          f" row {end} is the leading edge of the")
    print("  form rule below the line, so the glyph-row figure above is the"
          " line's own ink.")
print()
for fraction, found in ((0.02, loose), (0.01, tight)):
    kept = any(WRAPPED[0] <= s <= WRAPPED[1] for s, _, _ in found)
    print(f"{fraction:.0%} ink threshold: {len(found)} bands = the head and "
          f"{len(found) - 1} content lines; wrapped line kept: {kept}")
print()
print("the six bands around the wrapped line, by their field columns:")
for start, end, ink in tight:
    if 770 <= start <= 890:
        mark = "  <-- the wrapped instruction" if start == WRAPPED[0] else ""
        print(f"  rows {start}-{end}  ink {ink:>9,.0f}  {ink / median:4.2f}x"
              f"  columns {fields(start, end)}{mark}")
