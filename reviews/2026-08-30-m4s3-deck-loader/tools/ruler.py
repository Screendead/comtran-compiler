"""Crops of the 1962 scans with a computed print-column ruler under each.

Usage: ruler.py <page.png> <angle> <date_x> <pitch> <out.png> <y0> <y1> <x0> <x1> [<scale>]
The ruler ticks every print column from the LOC column (0), labels every 5.
"""
import sys
from PIL import Image, ImageDraw, ImageFont
path, ang, date_x, pitch, out, y0, y1, x0, x1 = sys.argv[1:10]
scale = int(sys.argv[10]) if len(sys.argv) > 10 else 3
ang, date_x, pitch = float(ang), float(date_x), float(pitch)
y0, y1, x0, x1 = map(int, (y0, y1, x0, x1))
img = Image.open(path).convert('L').rotate(ang, resample=Image.BICUBIC, fillcolor=255)
crop = img.crop((x0, y0, x1, y1)).resize(((x1 - x0) * scale, (y1 - y0) * scale), Image.LANCZOS)
W, H = crop.size
canvas = Image.new('RGB', (W, H + 28 * scale), 'white')
canvas.paste(crop.convert('RGB'), (0, 0))
d = ImageDraw.Draw(canvas)
font = ImageFont.load_default()
col = int((x0 - date_x) / pitch) - 1
while True:
    x = (date_x + col * pitch - x0) * scale
    if x > W: break
    if x >= 0:
        tall = col % 5 == 0
        d.line([(x, H), (x, H + (14 if tall else 7) * scale)], fill='red', width=1)
        if tall:
            d.text((x - 6, H + 15 * scale), str(col), fill='red', font=font)
    col += 1
canvas.save(out)
print(out, canvas.size)
