import sys; sys.path.insert(0,'/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/bc4b8978-0f16-4e03-beea-182e219a80ed/scratchpad/agent-scan')
from measure import *
from PIL import ImageDraw, ImageFont
try: F = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 11)
except Exception: F = ImageFont.load_default()

def ruler(path, y0, y1, x0, x1, origin, pitch, marks, scale=6, pad=3, title=""):
    crop = ROT.crop((x0, y0-pad, x1, y1+pad)).convert("RGB")
    w,h = crop.size
    big = crop.resize((w*scale, h*scale), Image.NEAREST)
    out = Image.new("RGB", (w*scale, h*scale+34), (255,255,255))
    out.paste(big,(0,0)); d = ImageDraw.Draw(out)
    bot = h*scale
    c = int((x0-origin)/pitch)+1
    while True:
        left = origin + (c-1.5)*pitch
        if left > x1: break
        if left >= x0:
            X=(left-x0)*scale
            hit = c in marks
            d.line([(X,0),(X,bot+6)], fill=(220,0,0) if hit else (0,150,255), width=1)
            if hit or c%5==0:
                d.text((X+2,bot+6), str(c), fill=(220,0,0) if hit else (0,90,160), font=F)
        c+=1
    if title: d.text((4, bot+20), title, fill=(0,0,0), font=F)
    out.save(path); return path
