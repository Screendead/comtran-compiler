import sys; sys.path.insert(0,'/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/bc4b8978-0f16-4e03-beea-182e219a80ed/scratchpad/agent-scan')
from common import *
import numpy as np

def score(im, box, deg):
    """Sharpness of the row ink profile after rotating the crop by deg."""
    x0,y0,x1,y1 = box
    pad = 40
    sub = im.crop((x0, y0-pad, x1, y1+pad))
    r = sub.rotate(deg, resample=Image.BICUBIC, fillcolor=255, expand=False)
    b = strip_rules(ink(r))
    b = b[pad:b.shape[0]-pad]
    rp = b.sum(1).astype(float)
    return (rp**2).sum()

def best_angle(im, box, lo=-2.0, hi=2.0):
    best=None
    for k in range(int((hi-lo)/0.05)+1):
        d = lo + k*0.05
        s = score(im, box, d)
        if best is None or s>best[1]: best=(d,s)
    d0=best[0]
    for k in range(-10,11):
        d = d0 + k*0.005
        s = score(im, box, d)
        if s>best[1]: best=(d,s)
    return best[0]

if __name__ == "__main__":
    im = load()
    boxes = {
      "PAYFILE":   (290, 300, 1460, 650),
      "CHECKFILE": (300, 760, 830, 900),
      "BONDORDER": (300, 980, 830, 1030),
      "ERRORFILE": (1080, 760, 1280, 1030),
    }
    for n,bx in boxes.items():
        print(n, round(best_angle(im,bx),3))
