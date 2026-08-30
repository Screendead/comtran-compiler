import sys, numpy as np
from PIL import Image
path = sys.argv[1]
img = Image.open(path).convert('L')
best = None
for ang in np.arange(-2.0, 2.01, 0.1):
    r = img.rotate(ang, resample=Image.BICUBIC, fillcolor=255)
    a = np.array(r) < 128
    prof = a.sum(axis=1)
    v = prof.var()
    if best is None or v > best[0]:
        best = (v, ang)
ang = best[1]
r = img.rotate(ang, resample=Image.BICUBIC, fillcolor=255)
a = np.array(r) < 128
# delete rule rows: any row whose longest horizontal ink run >= 25px
def longest_run(row):
    m = 0; c = 0
    for x in row:
        c = c + 1 if x else 0
        m = max(m, c)
    return m
keep = np.ones(a.shape[0], bool)
for y in range(a.shape[0]):
    if a[y].sum() > 25 and longest_run(a[y]) >= 25:
        keep[y] = False
a[~keep] = False
prof = a.sum(axis=1)
lines = []
y = 0
H = a.shape[0]
while y < H:
    if prof[y] > 0:
        y0 = y
        while y < H and prof[y] > 0:
            y += 1
        if y - y0 >= 4:
            lines.append((y0, y))
    else:
        y += 1
print('angle', ang)
np.save('bin.npy', a)
for (y0, y1) in lines:
    band = a[y0:y1]
    cols = band.any(axis=0)
    runs = []
    x = 0; W = len(cols)
    while x < W:
        if cols[x]:
            x0 = x
            while x < W and cols[x]:
                x += 1
            runs.append((x0, x))
        else:
            x += 1
    print(f'line y={y0}-{y1} n={len(runs)} first={runs[0][0] if runs else None} runs={runs[:60]}')
