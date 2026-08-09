"""Measure the 90.05 page head on all five scanned pages, and draw the images
that let a reader check the result by eye.

Print column 0 is the D of DATE, which is M1-15's definition of D. Only the
spacing between the head's fields is in question, so anchoring on DATE is not
circular. Each page is deskewed and has its own pitch fitted on its own ink.

The form's dashed guide rule crosses the head line on page 212. Its rows
carry one horizontal ink run of 381 px, where the worst glyph row carries 7,
so deleting those rows clears the rule and leaves every glyph edge intact.
"""
import json
import numpy as np
from PIL import Image, ImageDraw

OUT = 'review-page-heads'
FIELDS = ['DATE', 'the date value', 'TIME', 'the time value', 'ACCOUNT',
          'ID.', 'the identifier', 'PAGE', 'the page number']
MEASURED = [0, 5, 15, 21, 27, 55, 59, 83, 89]
GROUPS = {
    195: ('listing pages 1-6', [0, 5, 16, 22, 29, 56, 60, 83, 90]),
    196: ('listing pages 1-6', [0, 5, 16, 22, 29, 56, 60, 83, 90]),
    198: ('listing page 7', [0, 5, 16, 21, 28, 60, 64, 88, 93]),
    199: ('listing pages 8-16', [0, 5, 16, 21, 28, 55, 59, 80, 85]),
    212: ('listing pages 17-25', [0, 5, 15, 21, 27, 60, 64, 87, 93]),
}
XA, XB = 150, 1500


def vruns(ink, n=4):
    """Pixels inside a vertical ink run of at least n rows, dilated back."""
    keep = ink.copy()
    for d in range(1, n):
        keep &= np.roll(ink, -d, axis=0)
    grown = keep.copy()
    for d in range(1, n):
        grown |= np.roll(keep, d, axis=0)
    return grown & ink


def prepare(page):
    src = Image.open(f'comtran-manuals/J28-6169/images/page-{page}.png').convert('L')

    def var_of(a):
        return (np.asarray(a, dtype=np.int16) < 128)[:, XA:XB].sum(axis=1).astype(float).var()

    ang = max(((a, var_of(src.rotate(a, Image.BICUBIC, fillcolor=255)))
               for a in np.arange(-1.6, 1.61, 0.04)), key=lambda t: t[1])[0]
    im = src.rotate(ang, Image.BICUBIC, fillcolor=255)
    ink = np.asarray(im, dtype=np.int16) < 128
    # A guide-rule row carries one horizontal ink run far longer than any
    # glyph: 381 px against a worst glyph row of 7. Delete the whole row.
    for y in range(ink.shape[0]):
        row = ink[y]
        x, longest = 0, 0
        while x < len(row):
            if row[x]:
                a = x
                while x < len(row) and row[x]:
                    x += 1
                longest = max(longest, x - a)
            else:
                x += 1
        if longest >= 25:
            ink[y] = False
    stems = vruns(ink)
    text = ink.astype(np.int32)
    return im, float(ang), stems.astype(np.int32), text


def text_lines(v):
    H = v.shape[0]
    r = v[:, XA:XB].sum(axis=1)
    frag, y = [], 0
    while y < H:
        if r[y] > 10:
            s = y
            while y < H and r[y] > 10:
                y += 1
            frag.append([s, y - 1])
        else:
            y += 1
    out = []
    for s, e in frag:
        if out and s - out[-1][1] <= 3 and e - out[-1][0] <= 15:
            out[-1][1] = e
        else:
            out.append([s, e])
    return [tuple(l) for l in out if 8 <= l[1] - l[0] <= 17]


def runs(arr, s, e, gap=3, minw=2):
    W = arr.shape[1]
    col = arr[s:e + 1].sum(axis=0)
    out, x = [], 0
    while x < W:
        if col[x] > 0:
            a = x
            while x < W and col[x] > 0:
                x += 1
            out.append([a, x - 1])
        else:
            x += 1
    m = []
    for q in out:
        if m and q[0] - m[-1][1] <= gap:
            m[-1][1] = q[1]
        else:
            m.append(q)
    return [(a, b) for a, b in m if b - a >= minw]


record = {}
for page in (195, 196, 198, 199, 212):
    im, ang, stems, text = prepare(page)
    lines = text_lines(stems)
    # The head is the topmost text line on every one of the five pages.
    s, e = lines[0]
    rs = runs(text, s, e)
    D0 = rs[0][0]

    body = [l for l in lines if l[0] > e + 20]
    prof = np.zeros(text.shape[1], dtype=float)
    for a, b in body:
        prof += stems[a:b + 1].sum(axis=0)
    d = prof[200:1400] - prof[200:1400].mean()
    ac = np.correlate(d, d, mode='full')[len(d) - 1:]
    P = max(((p, ac[np.round(np.arange(1, 60) * p).astype(int)].sum())
             for p in np.arange(8.8, 9.9, 0.0002)), key=lambda t: t[1])[0]

    inside = [q for q in rs if q[0] < D0 + 95 * P]
    span = (inside[-1][0] - D0) / 89.0
    cols = [round((q[0] - D0) / P, 2) for q in inside]
    record[page] = dict(deskew=round(ang, 2), pitch=round(P, 4),
                        pitch_from_head_span=round(span, 4), date_x=D0,
                        head_rows=[s, e], run_columns=cols)
    print(f'p{page}: deskew {ang:+.2f}  pitch {P:.4f}  head-span pitch {span:.4f}  '
          f'{len(inside)} runs  y{s}-{e}')

    Z, PAD = 2, 40
    x0, x1 = D0 - 30, D0 + int(96 * P)
    crop = im.crop((x0, s - 13, x1, e + 13)).convert('RGB')
    w, h = crop.size
    can = Image.new('RGB', (w * Z, h * Z + PAD), 'white')
    can.paste(crop.resize((w * Z, h * Z), Image.LANCZOS), (0, 0))
    dr = ImageDraw.Draw(can)
    for col, tcol in zip(MEASURED, GROUPS[page][1]):
        xm = (D0 + col * P - x0) * Z
        dr.line([(xm, 0), (xm, h * Z)], fill=(215, 0, 0), width=2)
        xt = (D0 + tcol * P - x0) * Z
        for yy in range(0, h * Z, 9):
            dr.line([(xt, yy), (xt, yy + 5)], fill=(0, 140, 0), width=2)
    for c in range(0, 96, 5):
        xc = (D0 + c * P - x0) * Z
        dr.line([(xc, h * Z + 3), (xc, h * Z + (11 if c % 10 else 18))], fill=(120, 120, 120))
        if c % 10 == 0:
            dr.text((xc + 3, h * Z + 21), str(c), fill=(50, 50, 50))
    can.save(f'{OUT}/page-{page}-head.png')

json.dump(record, open(f'{OUT}/measurements.json', 'w'), indent=2)
print('wrote', OUT)
