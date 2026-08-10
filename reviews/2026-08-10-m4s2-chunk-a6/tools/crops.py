"""Cut the plates for the chunk A6 review record.

Every crop is taken from the page scan in `comtran-manuals/`, deskewed by the
angle its own reader measured and reported, and nothing else is altered. Run it
from anywhere; it writes into `crops/` beside this directory.

    python3 tools/crops.py
"""

import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(REC))
SCANS = os.path.join(REPO, "comtran-manuals", "J28-6169", "images")
OUT = os.path.join(REC, "crops")

# Each reader reported its own deskew angle and its own character grid. These
# are those numbers, not a fresh fit, so a plate here shows what the reader saw.
PAGES = {
    208: dict(deskew=1.078, origin=442.198, advance=9.28245, pitch=15.2096),
    210: dict(deskew=1.2658, origin=437.374, advance=9.2666, pitch=15.1844),
}


def deskewed(page):
    im = Image.open(os.path.join(SCANS, f"page-{page}.png")).convert("L")
    return im.rotate(PAGES[page]["deskew"], resample=Image.BICUBIC, fillcolor=255)


def x_of(page, column):
    """Left edge of a print column, in the deskewed image.

    The reported origin is the left edge of column 0, not its centre. Checked
    on page 208 against the ink: its first content line starts at x = 443 and
    its operand field at x = 963, which is 56.0 advances further right.
    """
    g = PAGES[page]
    return g["origin"] + g["advance"] * column


def save(im, name, scale):
    im = im.resize((im.width * scale, im.height * scale), Image.LANCZOS)
    im.save(os.path.join(OUT, name))
    print(f"{name}  {im.width}x{im.height}")


def text_bands(page, im):
    """Row runs of printed text, in page order.

    The form rules print ink in both margins, where no text prints, and every
    reader on this listing uses that to tell a rule from a line. A run-length
    filter does not: the dashed rules print in 6 px dashes.
    """
    a = 255 - np.asarray(im, dtype=float)
    text = a[:, 430:1290].sum(axis=1)
    left = a[:, 310:410].sum(axis=1)
    right = a[:, 1330:1460].sum(axis=1)
    rule = (left > 200) & (right > 200)
    on = (text > text.max() * 0.02) & ~rule
    bands, y = [], 0
    while y < len(on):
        if on[y]:
            s = y
            while y < len(on) and on[y]:
                y += 1
            if y - s >= 6:                      # a text line is 10 to 15 rows
                bands.append((s, y - 1, text[s:y].sum()))
        else:
            y += 1
    return bands


def main():
    os.makedirs(OUT, exist_ok=True)

    # ---- Item A: the wrapped instruction on listing page 19, PDF p. 210 ----
    im210 = deskewed(210)

    # a1: the four printed lines around it, so the wrap reads in context.
    save(im210.crop((430, 795, 1290, 895)), "a1-wrapped-line.png", 2)

    # a2: the same rows at the scan's own resolution. This is the plate that
    # would mislead: at 1x the wrapped line reads as a smudge under the label,
    # and it carries 0.30 of the page's median line ink where the next
    # faintest line carries 0.75.
    save(im210.crop((430, 795, 1290, 895)), "a2-wrapped-line-1x.png", 1)

    # a3: the wrapped instruction alone, against the mnemonic and operand
    # columns of the two lines that bracket it.
    save(im210.crop((int(x_of(210, 44)), 800, int(x_of(210, 72)), 880)),
         "a3-wrapped-columns.png", 4)

    # ---- Item B: BL)3,2 or 8L)3,2 on listing page 17, PDF p. 208 ----
    im208 = deskewed(208)
    bands = text_bands(208, im208)
    head = bands[0]
    # The disputed glyph sits on the page's first content line, which is the
    # first band whose ink looks like a body line rather than the head.
    body = [b for b in bands if b[0] > head[1] + 20]
    first = body[0]
    print(f"page 208 head rows {head[0]}-{head[1]}, first content rows {first[0]}-{first[1]}")

    save(im208.crop((430, first[0] - 6, 1290, first[1] + 6)),
         "b1-disputed-line.png", 2)

    # b2: the disputed glyph beside a certain 8 and a certain B, both cut from
    # this page's own head, at one magnification.
    #   head columns: 10/18/61 starts at 5, so its 8 is column 9;
    #   PUBLICATIONS starts at 62, so its B is column 64.
    def cell(page, im, column, top, bottom):
        return im.crop((int(x_of(page, column)), top,
                        int(x_of(page, column + 1)), bottom))

    # A form rule prints just above the head, so the head cells start inside it.
    disputed = cell(208, im208, 56, first[0] - 2, first[1] + 2)
    eight = cell(208, im208, 9, head[0] + 1, head[1] + 3)
    bee = cell(208, im208, 64, head[0] + 1, head[1] + 3)

    height = max(c.height for c in (disputed, eight, bee))
    strip = Image.new("L", (disputed.width * 3 + 24, height), 255)
    for i, c in enumerate((disputed, eight, bee)):
        strip.paste(c, (i * (disputed.width + 12), 0))
    save(strip, "b2-glyph-compare.png", 10)


main()
