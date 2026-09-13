import numpy as np
from PIL import Image

SRC = "/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/images/page-217.png"

def load():
    return Image.open(SRC).convert("L")

def ink(im, thr=150):
    return np.asarray(im, dtype=np.uint8) < thr

def longest_run(b):
    """Longest horizontal ink run per row."""
    h, w = b.shape
    run = np.zeros(h, dtype=np.int32)
    best = np.zeros(h, dtype=np.int32)
    for x in range(w):
        col = b[:, x]
        run = np.where(col, run + 1, 0)
        best = np.maximum(best, run)
    return best

def strip_rules(b, run=25):
    out = b.copy()
    out[longest_run(b) >= run] = False
    return out

def rotate_gray(im, deg):
    return im.rotate(deg, resample=Image.BICUBIC, fillcolor=255, expand=False)

def vrun_filter(b, n=4):
    """Keep only pixels inside a vertical ink run of >= n rows. Kills 1-3px rules."""
    h, w = b.shape
    up = np.zeros_like(b, dtype=np.int32)
    cur = np.zeros(w, dtype=np.int32)
    for y in range(h):
        cur = np.where(b[y], cur + 1, 0)
        up[y] = cur
    keep = np.zeros_like(b)
    cur = np.zeros(w, dtype=np.int32)
    for y in range(h - 1, -1, -1):
        cur = np.where(b[y], cur + 1, 0)
        keep[y] = (up[y] + cur - 1) >= n
    return b & keep
