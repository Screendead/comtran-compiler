#!/usr/bin/env python3
"""Cut the round-two crops from the J28-6169 page scans.

Usage: python3 tools/make_crops.py <repository root>
Boxes are in scan pixels (150 dpi, 1275 x 1650), read off the full pages.
"""
import os
import sys
from PIL import Image

ROOT = sys.argv[1]
REC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CROPS = {
    "j-p116-indicies.png": (116, (240, 598, 990, 652)),
    "j-p116-synonomous.png": (116, (290, 1288, 1010, 1346)),
    "j-p171-in-not-used.png": (171, (150, 620, 1090, 700)),
}
for name, (page, box) in CROPS.items():
    im = Image.open(os.path.join(ROOT, "comtran-manuals/J28-6169/images", f"page-{page:03d}.png"))
    im.crop(box).save(os.path.join(REC, "crops", name))
    print(name, page, box)
