"""Cut the two J28-6169 scan crops this record shows. Run from the
repository root: python3 reviews/2026-10-25-codegen-defect-6/tools/crops.py
"""
import os
from PIL import Image

IMG = "comtran-manuals/J28-6169/images"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "crops")
CROPS = {
    # J 02.04.06, PDF p. 24: the page head, items 8 (CLOSE ALL FILES) and 9 (STOP RUN).
    "j-02.04.06-close-all-files.png": ("page-024.png", (180, 130, 1080, 790)),
    # J 90.04.01, PDF p. 184: messages 135 to 140 (the page is skewed, so edge rows clip), the only OPEN and CLOSE entries.
    "j-90.04.01-msgs-138-139.png": ("page-184.png", (185, 236, 900, 338)),
}
for name, (page, box) in CROPS.items():
    Image.open(os.path.join(IMG, page)).crop(box).save(os.path.join(OUT, name))
    print(name, box)
