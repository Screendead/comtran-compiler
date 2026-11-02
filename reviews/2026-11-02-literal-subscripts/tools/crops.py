"""Cut the scan crops this record shows. Run from the repository root:
python3 reviews/2026-11-02-literal-subscripts/tools/crops.py
"""
import os
from PIL import Image

J = "comtran-manuals/J28-6169/images"
F = "comtran-manuals/F28-8043/images"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "crops")
CROPS = {
    # J 02.04.07, PDF p. 25: D. Subscripting and Indexing, both paragraphs.
    "j-02.04.07-subscripting.png": (J, "page-025.png", (210, 1080, 1140, 1525)),
    # J 02.04.07.01, PDF p. 26: SET K=K+2 and the three updated names.
    "j-02.04.07.01-set-k.png": (J, "page-026.png", (290, 220, 1080, 420)),
    # J 90.02.01, PDF p. 139: Location Counters 1 and 2.
    "j-90.02.01-counter-2.png": (J, "page-139.png", (170, 880, 1070, 1165)),
    # J 90.02.05, PDF p. 143: the PI pointer word and PI) BSS N.
    "j-90.02.05-pi.png": (J, "page-143.png", (270, 940, 1050, 1355)),
    # F p. 31, PDF p. 37: the subscript forms.
    "f-p31-subscript-form.png": (F, "page-037.png", (430, 295, 1190, 560)),
}
for name, (d, page, box) in CROPS.items():
    Image.open(os.path.join(d, page)).crop(box).save(os.path.join(OUT, name))
    print(name, box)
