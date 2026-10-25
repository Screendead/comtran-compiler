"""Print the tight ink box inside each rough region, for the crop table.

Usage: python3 -I measure.py <repo root>
"""

import sys
from PIL import Image

ROOT = sys.argv[1]
ROUGH = {
    "p010-nodeck": (10, (280, 1030, 1070, 1260)),
    "p011-load": (11, (260, 240, 1130, 485)),
    "p186-severity": (186, (220, 250, 1090, 605)),
    "p181-may-vary": (181, (225, 230, 1085, 370)),
    "p181-msg22": (181, (260, 945, 960, 962)),
    "p185-msg195": (185, (140, 298, 830, 336)),
    "p185-trailer": (185, (110, 545, 420, 572)),
}
for key, (page, box) in ROUGH.items():
    im = Image.open(f"{ROOT}/comtran-manuals/J28-6169/images/page-{page:03d}.png").convert("L")
    sub = im.crop(box).point(lambda v: 255 if v < 140 else 0)
    bb = sub.getbbox()
    tight = (box[0] + bb[0], box[1] + bb[1], box[0] + bb[2], box[1] + bb[3])
    print(key, page, "rough", box, "ink", tight)
