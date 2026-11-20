#!/usr/bin/env python3
"""Render a call storyboard (JSON) to a narrated 1280x720 MP4.

  python3 pitch/video/render.py pitch/calls/<id>.json --out DIR [--frames-only]

--frames-only writes the PNG frames and reports text that does not fit; it
needs no audio, so it runs inside the sandbox. A full render calls macOS
`say`, which the sandbox blocks.
"""
import json, os, subprocess, sys, textwrap, argparse
from PIL import Image, ImageDraw, ImageFont

W, H = 1280, 720
C = dict(bg="#f4f5f2", ink="#1c221f", muted="#5b6560", line="#d4d9d4", card="#efe7cf",
         cardink="#6b5a2c", accent="#1f5a8a", accsoft="#e2edf6", rec="#2f6b4a", recsoft="#e1efe6",
         warn="#8b2d3a", code="#ffffff")
SF = "/System/Library/Fonts/"
FONTS = {
    "head": (SF + "Supplemental/Georgia Bold.ttf", 0),
    "body": (SF + "Avenir Next.ttc", 5),
    "bold": (SF + "Avenir Next.ttc", 2),
    "mono": (SF + "Menlo.ttc", 0),
}
_cache = {}
def font(kind, size):
    k = (kind, size)
    if k not in _cache:
        path, idx = FONTS[kind]
        _cache[k] = ImageFont.truetype(path, size, index=idx)
    return _cache[k]

class Overflow(Exception):
    pass

def wrap(d, text, f, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if d.textlength(t, font=f) <= width:
            cur = t
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines

def para(d, xy, text, kind, size, width, fill, max_y, gap=1.3):
    x, y = xy
    f = font(kind, size)
    for ln in wrap(d, text, f, width):
        if y + size > max_y:
            raise Overflow(text[:60])
        d.text((x, y), ln, font=f, fill=fill)
        y += int(size * gap)
    return y

def frame(scene, meta, i, n):
    im = Image.new("RGB", (W, H), C["bg"])
    d = ImageDraw.Draw(im)
    # top strip: eyebrow and progress
    d.text((60, 32), f"CALL {meta['number']} OF {meta['of']}  ·  {meta['short'].upper()}", font=font("bold", 17), fill=C["cardink"])
    d.rectangle((60, 62, W - 60, 64), fill=C["line"])
    d.rectangle((60, 62, 60 + int((W - 120) * (i + 1) / n), 64), fill=C["accent"])
    cap_top = H - 112
    # caption band: the narration, for muted viewing
    d.rectangle((0, cap_top, W, H), fill=C["ink"])
    cf = 21
    while True:
        lines = wrap(d, scene["say"], font("body", cf), W - 120)
        if len(lines) <= 3 or cf <= 16:
            break
        cf -= 1
    if len(lines) > 3:
        raise Overflow("narration too long for captions: " + scene["say"][:60])
    y = cap_top + (112 - len(lines) * int(cf * 1.3)) // 2
    for ln in lines:
        d.text((60, y), ln, font=font("body", cf), fill=C["bg"])
        y += int(cf * 1.3)
    top, bottom, L, R = 92, cap_top - 24, 60, W - 60
    t = scene["type"]
    if t == "title":
        y = para(d, (L, 190), scene["heading"], "head", 50, R - L, C["ink"], bottom, 1.2)
        if scene.get("sub"):
            para(d, (L, y + 24), scene["sub"], "body", 27, R - L - 100, C["muted"], bottom)
        return im
    y = para(d, (L, top), scene["heading"], "head", 34, R - L, C["ink"], bottom, 1.2) + 18
    if t == "points":
        for b in scene["bullets"]:
            d.ellipse((L, y + 11, L + 10, y + 21), fill=C["accent"])
            y = para(d, (L + 28, y), b, "body", 27, R - L - 28, C["ink"], bottom) + 14
    elif t == "code":
        lines = scene["lines"]
        size = 22
        while size > 14 and max((d.textlength(l, font=font("mono", size)) for l in lines), default=0) > R - L - 40:
            size -= 1
        hl = set(scene.get("highlight", []))
        box_h = len(lines) * int(size * 1.45) + 32
        if y + box_h > bottom - (40 if scene.get("caption") else 0):
            raise Overflow("code block too tall: " + scene["heading"][:40])
        d.rectangle((L, y, R, y + box_h), fill=C["code"], outline=C["line"])
        yy = y + 16
        for k, l in enumerate(lines):
            if k in hl:
                d.rectangle((L + 1, yy - 3, R - 1, yy + int(size * 1.45) - 3), fill="#fbf0b8")
            if d.textlength(l, font=font("mono", size)) > R - L - 40:
                raise Overflow("code line too wide: " + l[:40])
            d.text((L + 20, yy), l, font=font("mono", size), fill=C["ink"])
            yy += int(size * 1.45)
        if scene.get("caption"):
            para(d, (L, y + box_h + 12), scene["caption"], "body", 22, R - L, C["muted"], bottom)
    elif t == "options":
        opts = scene["options"]
        gap = 20
        cw = (R - L - gap * (len(opts) - 1)) // len(opts)
        for k, o in enumerate(opts):
            x = L + k * (cw + gap)
            rec = o.get("rec")
            d.rectangle((x, y, x + cw, bottom), fill=C["recsoft"] if rec else C["code"], outline=C["rec"] if rec else C["line"], width=3 if rec else 1)
            yy = y + 16
            if rec:
                d.text((x + 16, yy), "RECOMMENDED", font=font("bold", 15), fill=C["rec"])
                yy += 26
            yy = para(d, (x + 16, yy), o["label"], "bold", 24, cw - 32, C["ink"], bottom - 8) + 10
            fs = 20 if len(opts) <= 2 else 18
            yy = para(d, (x + 16, yy), o["see"], "body", fs, cw - 32, C["ink"], bottom - 8) + 8
            if o.get("cost"):
                para(d, (x + 16, yy), o["cost"], "body", fs, cw - 32, C["warn"], bottom - 8)
    elif t == "image":
        src = Image.open(scene["_image_file"]).convert("RGB")
        cap_h = 40 if scene.get("caption") else 0
        mw, mh = R - L, bottom - y - cap_h
        s = min(mw / src.width, mh / src.height, 2.5)
        src = src.resize((int(src.width * s), int(src.height * s)), Image.LANCZOS)
        im.paste(src, (L + (mw - src.width) // 2, y))
        d.rectangle((L + (mw - src.width) // 2 - 1, y - 1, L + (mw + src.width) // 2, y + src.height), outline=C["line"])
        if scene.get("caption"):
            para(d, (L, y + src.height + 10), scene["caption"], "body", 22, R - L, C["muted"], bottom + 20)
    elif t == "recommend":
        d.rectangle((L, y, R, bottom), fill=C["recsoft"], outline=C["rec"], width=3)
        d.text((L + 24, y + 18), "RECOMMENDED", font=font("bold", 16), fill=C["rec"])
        yy = para(d, (L + 24, y + 46), scene["label"], "head", 30, R - L - 48, C["ink"], bottom - 10, 1.2) + 14
        for b in scene.get("reasons", []):
            d.ellipse((L + 26, yy + 10, L + 34, yy + 18), fill=C["rec"])
            yy = para(d, (L + 50, yy), b, "body", 24, R - L - 76, C["ink"], bottom - 10) + 10
    else:
        raise ValueError("unknown scene type " + t)
    return im

def git_extract(ref_path, out_dir):
    ref, path = ref_path.split(":", 1)
    dst = os.path.join(out_dir, os.path.basename(path))
    with open(dst, "wb") as fh:
        fh.write(subprocess.run(["git", "show", f"{ref}:{path}"], check=True, capture_output=True).stdout)
    return dst

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("storyboard")
    ap.add_argument("--out", required=True)
    ap.add_argument("--frames-only", action="store_true")
    ap.add_argument("--voice", default="Daniel")
    ap.add_argument("--rate", default="182")
    a = ap.parse_args()
    sb = json.load(open(a.storyboard))
    meta, scenes = sb["meta"], sb["scenes"]
    os.makedirs(a.out, exist_ok=True)
    problems = []
    for i, sc in enumerate(scenes):
        if sc["type"] == "image":
            sc["_image_file"] = git_extract(sc["image"], a.out)
        try:
            frame(sc, meta, i, len(scenes)).save(os.path.join(a.out, f"s{i:02d}.png"))
        except Overflow as e:
            problems.append(f"scene {i} ({sc['type']}): does not fit: {e}")
    words = sum(len(s["say"].split()) for s in scenes)
    print(f"{len(scenes)} scenes, {words} narration words (~{words / 2.9:.0f} s)")
    if problems:
        print("\n".join(problems))
        sys.exit(1)
    if a.frames_only:
        return
    segs = []
    for i, sc in enumerate(scenes):
        aiff = os.path.join(a.out, f"s{i:02d}.aiff")
        subprocess.run(["say", "-v", a.voice, "-r", a.rate, "-o", aiff, sc["say"]], check=True)
        seg = os.path.join(a.out, f"s{i:02d}.mp4")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-loop", "1", "-framerate", "10", "-i", os.path.join(a.out, f"s{i:02d}.png"),
                        "-i", aiff, "-af", "apad=pad_dur=0.7", "-c:v", "libx264", "-tune", "stillimage", "-pix_fmt", "yuv420p",
                        "-r", "10", "-c:a", "aac", "-b:a", "96k", "-ar", "44100", "-shortest", seg], check=True)
        segs.append(seg)
    lst = os.path.join(a.out, "list.txt")
    with open(lst, "w") as fh:
        fh.writelines(f"file '{os.path.abspath(s)}'\n" for s in segs)
    final = os.path.join(a.out, meta["id"] + ".mp4")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", "-movflags", "+faststart", final], check=True)
    print("wrote", final)

if __name__ == "__main__":
    main()
