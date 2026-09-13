import sys; sys.path.insert(0,'/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/bc4b8978-0f16-4e03-beea-182e219a80ed/scratchpad/agent-scan')
from common import *
import numpy as np
from PIL import ImageDraw

ANG = -1.83
IM = load()
ROT = IM.rotate(ANG, resample=Image.BICUBIC, fillcolor=255)
B = ink(ROT)
BV = vrun_filter(B)

def bands(y0, y1, x0, x1, thr=3):
    rp = BV[y0:y1, x0:x1].sum(1)
    ys = np.nonzero(rp > thr)[0]
    if len(ys) == 0: return []
    out = []; s = ys[0]; p = ys[0]
    for y in ys[1:]:
        if y - p > 1: out.append((s + y0, p + y0)); s = y
        p = y
    out.append((s + y0, p + y0))
    return out

def glyphs(y0, y1, x0, x1, minrows=2):
    """Ink runs along x within the line band; require >=minrows ink rows per column."""
    cp = B[y0:y1 + 1, x0:x1 + 1].sum(0)
    on = cp >= minrows
    out = []; i = 0
    while i < len(on):
        if on[i]:
            j = i
            while j + 1 < len(on) and on[j + 1]: j += 1
            out.append((x0 + i, x0 + j))
            i = j + 1
        else: i += 1
    return out

def centers(gl): return [(a + b) / 2.0 for a, b in gl]

def gridfit(cs, plo=9.0, phi=9.8, steps=4000):
    """Snap all glyph centers to an integer grid; return (pitch, phase) minimising squared frac."""
    best = None
    for k in range(steps + 1):
        p = plo + (phi - plo) * k / steps
        # optimal phase from circular mean
        ang = 2 * np.pi * np.array(cs) / p
        z = np.exp(1j * ang).mean()
        ph = np.angle(z) * p / (2 * np.pi)
        r = (np.array(cs) - ph) / p
        cost = ((r - np.round(r)) ** 2).sum()
        if best is None or cost < best[0]: best = (cost, p, ph, abs(z))
    return best

def overlay(path, y0, y1, x0, x1, origin, pitch, labels, scale=5, pad=4):
    crop = ROT.crop((x0, y0 - pad, x1, y1 + pad + 26)).convert("RGB")
    w, h = crop.size
    big = crop.resize((w * scale, h * scale), Image.NEAREST)
    d = ImageDraw.Draw(big)
    top = 0; bot = (y1 - y0 + 2 * pad) * scale
    c = int(np.floor((x0 - origin) / pitch + 1)) - 1
    while True:
        cx = origin + (c - 1.5) * pitch  # left edge of cell c
        if cx > x1: break
        if cx >= x0:
            X = (cx - x0) * scale
            col = (255, 0, 0) if c in labels else (0, 160, 255)
            d.line([(X, top), (X, bot)], fill=col, width=1)
            if c % 5 == 0 or c in labels:
                d.text((X + 2, bot + 2), str(c), fill=col)
        c += 1
    big.save(path)
    return path
