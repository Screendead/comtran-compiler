"""Crop the chunk A4 judgment calls out of the page scans, at each page's
own measured grid. Every coordinate comes from that page's reader report."""

from PIL import Image, ImageDraw
import os

MAN = "/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/images"
OUT = os.path.dirname(os.path.abspath(__file__))

# page: (rotation for PIL, column-0 centre x, advance, row-0 centre y, pitch)
GRID = {
    202: (0.935, 438.290, 9.26708, 233.519, 15.2145),
    203: (-0.855, 398.838, 9.31916, 318.25 + 5, 15.203),
    204: (0.920, 421.970, 9.29600, 223.577 + 5, 15.2924),
}
_cache = {}


def page(n):
    if n not in _cache:
        im = Image.open(f"{MAN}/page-{n}.png").convert("L")
        _cache[n] = im.rotate(GRID[n][0], resample=Image.BICUBIC, fillcolor=255)
    return _cache[n]


def x_of(n, col):
    _, x0, adv, _, _ = GRID[n]
    return x0 + col * adv


def y_of(n, row):
    _, _, _, y0, pitch = GRID[n]
    return y0 + row * pitch


def crop(n, row, c0, c1, zoom=6, rows=1.4):
    """Columns c0..c1 inclusive on one content row, upscaled."""
    _, _, adv, _, pitch = GRID[n]
    left = int(x_of(n, c0) - adv / 2) - 2
    right = int(x_of(n, c1) + adv / 2) + 2
    top = int(y_of(n, row) - pitch * rows / 2)
    bot = int(y_of(n, row) + pitch * rows / 2)
    box = page(n).crop((left, top, right, bot))
    return box.resize((box.width * zoom, box.height * zoom), Image.LANCZOS)


def strip(cells, zoom=14, gap=14, label_h=34):
    """A labelled comparison strip. cells: [(caption, page, row, col)]."""
    imgs = []
    for cap, n, row, col in cells:
        imgs.append((cap, crop(n, row, col, col, zoom=zoom, rows=1.2)))
    w = sum(i.width for _, i in imgs) + gap * (len(imgs) + 1)
    h = max(i.height for _, i in imgs) + gap * 2 + label_h
    out = Image.new("L", (w, h), 255)
    d = ImageDraw.Draw(out)
    x = gap
    for cap, i in imgs:
        out.paste(i, (x, gap))
        d.text((x, gap + i.height + 8), cap, fill=0)
        x += i.width + gap
    return out


# A. Page 203 line 7 (index 6): the operand the ink cannot decide, in context.
crop(203, 6, 0, 74, zoom=4).save(f"{OUT}/a1-bl3-line.png")

# The same glyph against every certain B and certain 8 the page prints.
strip([
    ("in question", 203, 6, 56),
    ("B  line 36", 203, 35, 58),
    ("B  line 38", 203, 37, 58),
    ("B  head", 203, -3, 64),
    ("8  head", 203, -3, 9),
    ("8  line 7", 203, 6, 39),
]).save(f"{OUT}/a2-bl3-compare.png")

# B. Page 204, location 00465 (row 20): the mark judged not to be a character.
crop(204, 20, 0, 34, zoom=5).save(f"{OUT}/b1-00465-line.png")
strip([
    ("the mark", 204, 20, 30),
    ("period  00443", 204, 2, 59),
    ("period  00527", 204, 54, 39),
], zoom=16).save(f"{OUT}/b2-00465-compare.png")

# C. Page 203, location 00376 (row 20): the 4-pixel speck.
crop(203, 20, 0, 34, zoom=5).save(f"{OUT}/c1-00376-line.png")

# D. Page 202 row 48: the broken 0 the reader first read as 2, with the two
# clean SLW rows (3 and 24) that print the same opcode.
crop(202, 48, 0, 21, zoom=5).save(f"{OUT}/d1-0602-row48.png")
strip([
    ("row 48  in question", 202, 48, 9),
    ("row 3  SLW", 202, 3, 9),
    ("row 24  SLW", 202, 24, 9),
], zoom=16).save(f"{OUT}/d2-0602-compare.png")

for f in sorted(os.listdir(OUT)):
    if f.endswith(".png") and f[0] in "abcd" and f[1] in "12":
        print(f, Image.open(f"{OUT}/{f}").size)
