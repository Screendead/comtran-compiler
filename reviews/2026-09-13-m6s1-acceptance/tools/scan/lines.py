import sys; sys.path.insert(0,'/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/bc4b8978-0f16-4e03-beea-182e219a80ed/scratchpad/agent-scan')
from common import *
import numpy as np

def rot(im, deg):
    return im.rotate(deg, resample=Image.BICUBIC, fillcolor=255)

def runs(b, y0, y1, x0, x1, gap=1, minink=1):
    """Glyph ink runs along x for rows [y0,y1] within [x0,x1]. Returns (start,end) inclusive, absolute x."""
    cp = b[y0:y1+1, x0:x1+1].sum(0)
    on = cp >= minink
    out=[]
    i=0
    n=len(on)
    while i<n:
        if on[i]:
            j=i
            while j+1<n and (on[j+1] or (j+1+gap<n and any(on[j+1:j+2+gap]))):
                j+=1
            out.append((x0+i, x0+j))
            i=j+1
        else: i+=1
    return out

def profile(b, y0, y1, x0, x1):
    return b[y0:y1+1, x0:x1+1].sum(0)
