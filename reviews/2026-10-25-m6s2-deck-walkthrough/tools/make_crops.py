"""Cut the record's scan crops and enlarge each two times (Lanczos).

Usage: python3 -I make_crops.py <repo root>
The boxes are the measured ink boxes of tools/measure.py with a margin added.
"""

import os
import sys
from PIL import Image

ROOT = sys.argv[1]
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "crops")
CROPS = {
    "j-p010-nodeck.png": (10, (290, 1028, 1062, 1260)),
    "j-p011-load.png": (11, (274, 240, 1120, 492)),
    "j-p186-severity.png": (186, (225, 256, 1082, 605)),
    "j-p181-may-vary.png": (181, (228, 230, 1082, 370)),
    "j-p181-msg21-22.png": (181, (268, 932, 935, 961)),
    "j-p185-msg195.png": (185, (148, 301, 820, 344)),
    "j-p185-trailer.png": (185, (120, 542, 388, 570)),
}
os.makedirs(OUT, exist_ok=True)
for name, (page, box) in CROPS.items():
    im = Image.open(f"{ROOT}/comtran-manuals/J28-6169/images/page-{page:03d}.png").convert("L")
    c = im.crop(box)
    c = c.resize((c.width * 2, c.height * 2), Image.LANCZOS)
    c.save(os.path.join(OUT, name), optimize=True)
    print(name, page, box, c.size)
