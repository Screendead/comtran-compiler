import sys, numpy as np
from PIL import Image
path = sys.argv[1]; head_page_col = int(sys.argv[2])
img = Image.open(path).convert('L')
best = None
for ang in np.arange(-2.0, 2.01, 0.05):
    r = img.rotate(ang, resample=Image.BICUBIC, fillcolor=255)
    a = np.array(r) < 128
    v = a.sum(axis=1).var()
    if best is None or v > best[0]:
        best = (v, ang)
ang = best[1]
a = np.array(img.rotate(ang, resample=Image.BICUBIC, fillcolor=255)) < 128
# keep only pixels in a vertical ink run of >= 4 rows
H, W = a.shape
run = np.zeros_like(a, dtype=np.int16)
for y in range(H):
    run[y] = (run[y-1] + 1) * a[y] if y else a[y]
keep = np.zeros_like(a)
for y in range(H-1, -1, -1):
    if y < H-1:
        keep[y] = keep[y+1] & a[y] | (run[y] >= 4)
    else:
        keep[y] = run[y] >= 4
a = keep
prof = a.sum(axis=1)
lines = []
y = 0
while y < H:
    if prof[y] > 0:
        y0 = y
        while y < H and prof[y] > 0: y += 1
        if y - y0 >= 5: lines.append((y0, y))
    else: y += 1
def runs_of(band):
    cols = band.any(axis=0); out = []; x = 0
    while x < W:
        if cols[x]:
            x0 = x
            while x < W and cols[x]: x += 1
            out.append((x0, x))
        else: x += 1
    return out
# head line: the first line with a run near x=1206 (PAGE)
head = None
for (y0, y1) in lines:
    rs = runs_of(a[y0:y1])
    if len(rs) > 20 and rs[0][0] > 400 and rs[0][0] < 480:
        head = (y0, y1, rs); break
y0, y1, rs = head
date_x = rs[0][0]
# PAGE's P: first run at x > 1150
page_x = [r for r in rs if r[0] > 1150][0][0]
pitch = (page_x - date_x) / head_page_col
print('angle', ang, 'head y', y0, y1, 'DATE x', date_x, 'PAGE x', page_x, 'pitch', round(pitch, 4))
line_pitch = None
for (ly0, ly1) in lines:
    rs = runs_of(a[ly0:ly1])
    if not rs: continue
    cols = [round((x0 - date_x) / pitch + 0.3, 1) for (x0, x1) in rs]
    slot = (ly0 - y0) / 15.29
    print(f'y={ly0}-{ly1} slot={slot:.2f} cols={cols[:70]}')
