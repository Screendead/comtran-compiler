"""Cut the eleven page crops of this record from the J28-6169 scans.

Run it from a checkout where this record directory sits inside the repository:
it reads the scans through `../../comtran-manuals/`.

The four overlay plates of item 7 are not cut here. `tools/scan/` holds the
scripts that measured the columns and drew them.

The deskewed plate rotates the whole page by -1.83 degrees about its centre,
the angle `tools/scan/deskew.py` fitted, so a rotated box and the ink columns
of `evidence/results.txt` share one frame. Every crop keeps the white ground:
the scans are black ink on white paper.
"""

import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
SCANS = os.path.join(REC, "..", "..", "comtran-manuals", "J28-6169", "images")
OUT = os.path.join(REC, "crops")

ANGLE = -1.83


def page(number):
    return Image.open(os.path.join(SCANS, f"page-{number}.png")).convert("L")


def cut(name, image, box, scale, resample=Image.LANCZOS):
    part = image.crop(box)
    wide, high = part.size
    part.resize((wide * scale, high * scale), resample).save(
        os.path.join(OUT, name)
    )
    return name, part.size, scale


REPORT = page(217)
DESKEWED = REPORT.rotate(ANGLE, resample=Image.BICUBIC, fillcolor=255)
BLOCK = (285, 290, 1620, 640)

CUTS = [
    cut("payfile-raw.png", REPORT, BLOCK, 1),
    cut("payfile-deskewed.png", DESKEWED, BLOCK, 1),
    cut("prem-columns.png", DESKEWED, (1085, 300, 1270, 640), 2),
    cut("gt-net.png", REPORT, (1240, 545, 1380, 600), 6, Image.NEAREST),
    cut("errorfile-mocre.png", REPORT, (1060, 750, 1410, 1050), 2),
    cut("mocre-glyphs.png", REPORT, (1075, 955, 1260, 995), 6, Image.NEAREST),
    cut("check-bond-woo.png", REPORT, (300, 866, 980, 1030), 3),
    cut("payfile-woo.png", REPORT, (295, 578, 660, 620), 4),
    cut("lookup-p213.png", page(213), (380, 355, 1150, 592), 2),
    cut("pool-p216.png", page(216), (380, 518, 1180, 905), 2),
    cut("sys267-p169.png", page(169), (120, 218, 1140, 325), 2),
]

for name, size, scale in CUTS:
    print(f"{name}: {size[0]}x{size[1]} at {scale}x")
