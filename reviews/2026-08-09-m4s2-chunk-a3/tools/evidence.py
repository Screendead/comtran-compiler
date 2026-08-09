"""Builds the review images for the chunk A3 page verification.

Run from the repository root:  python3 review-pages-199-201/evidence.py

Every image is a crop of the page scan, deskewed by the angle the reader
of that page measured, with a line-slot ruler drawn over it. Nothing is
redrawn or reconstructed: the ink is the scan's own.
"""

import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

SCANS = "comtran-manuals/J28-6169/images"
OUT = "review-pages-199-201"

# The deskew angle each page's reader measured, as a PIL rotate() argument,
# with the character grid it fitted. Column 0 is the first digit of LOC.
PAGES = {
    199: {"deskew": -0.34, "origin": 411.38, "pitch": 9.2718, "listing": 8},
    200: {"deskew": 0.25, "origin": 439.98, "pitch": 9.2447, "listing": 9},
    201: {"deskew": -0.77, "origin": 394.9, "pitch": 9.321, "listing": 10},
}

INK = 160          # a pixel darker than this is ink
ROW = 5            # rows of unbroken ink in a column that make a slot printed
BODY = (400, 1300)  # the x range the listing text occupies
FULL = (305, 1465)  # the x range a form rule spans

RED = (200, 30, 30)
BLUE = (30, 90, 200)
GREY = (140, 140, 140)


def font(size):
    for path in (
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def deskewed(page):
    im = Image.open(f"{SCANS}/page-{page}.png").convert("L")
    return im.rotate(PAGES[page]["deskew"], resample=Image.BICUBIC, fillcolor=255)


def rule_rows(ink):
    """The form's guide rules, by how much of the page width they span.

    The 25 px run-length test finds the solid rules only. A dashed rule
    prints 6 px dashes, so it is found by coverage instead: it inks most
    of the 20 px bins across the page, where the widest line of text
    inks half of them.
    """
    bins = [(x, x + 20) for x in range(FULL[0], FULL[1], 20)]
    cover = np.array(
        [[ink[y, a:b].any() for a, b in bins] for y in range(ink.shape[0])]
    ).mean(axis=1)
    rule = cover >= 0.80
    for _ in range(3):
        grown = rule.copy()
        for y in np.where(rule)[0]:
            for n in (y - 1, y + 1):
                if 0 <= n < len(rule) and cover[n] >= 0.55:
                    grown[n] = True
        rule = grown
    return rule


def comb(profile):
    """The line pitch and the first line's centre, by fitting a comb.

    Splitting the ink into bands fails where two lines sit four rows
    apart: they merge, and the merged band hides a slot. A comb makes no
    such decision. It slides a fixed-pitch set of narrow windows over the
    profile and keeps the pitch and phase that capture the most ink.
    """
    best = None
    for pitch in np.arange(14.2, 16.4, 0.005):
        for phase in np.arange(150, 150 + pitch, 0.5):
            centres = np.arange(phase, len(profile) - 6, pitch)
            score = sum(
                profile[int(c) - 4: int(c) + 5].sum() for c in centres
            )
            if best is None or score > best[0]:
                best = (score, pitch, phase)
    return best[1], best[2]


def measure(page):
    im = deskewed(page)
    ink = np.array(im) < INK
    rule = rule_rows(ink)
    profile = ink[:, BODY[0]: BODY[1]].sum(axis=1) * ~rule
    pitch, phase = comb(profile.astype(float))
    centres = np.arange(phase, ink.shape[0] - 8, pitch)
    body = ink[:, BODY[0]: BODY[1]] & ~rule[:, None]
    weight = [int(profile[int(c) - 5: int(c) + 6].sum()) for c in centres]
    height = [tallest(body[int(c) - 5: int(c) + 6]) for c in centres]
    # Total ink does not separate the two populations: page 9's `BSS 9`
    # continuation line inks less than the fringe of a form rule. Glyph
    # height does. A printed character is 6 to 11 rows tall in some
    # column; what survives rule removal is 1 to 3.
    printed = [i for i, h in enumerate(height) if h >= ROW]
    first, last = printed[0], printed[-1]
    return {
        "image": im,
        "centres": centres[first:],
        "pitch": float(pitch),
        "weights": weight[first: last + 1],
        "heights": height[first: last + 1],
        "slots": [i - first for i in printed],
        "shortest_row": min(height[i] for i in printed),
        "tallest_empty": max(
            [height[i] for i in range(first, last + 1) if i not in set(printed)] or [0]
        ),
        "rule_rows": int(rule.sum()),
    }


def tallest(window):
    """The tallest unbroken column of ink in a slot's window, in rows."""
    best = 0
    for col in range(window.shape[1]):
        run = 0
        for on in window[:, col]:
            run = run + 1 if on else 0
            best = max(best, run)
    return best


def ruler(page, m, top_slot, bottom_slot, name, note):
    """A crop of the page with every line slot marked and numbered."""
    scale = 2
    y0 = m["centres"][0] + (top_slot - 0.55) * m["pitch"]
    y1 = m["centres"][0] + (bottom_slot + 0.55) * m["pitch"]
    x0, x1 = BODY[0] - 60, BODY[1] - 120
    crop = m["image"].crop((int(x0), int(y0), int(x1), int(y1)))
    crop = crop.resize((crop.width * scale, crop.height * scale), Image.LANCZOS)
    out = Image.new("RGB", (crop.width + 90, crop.height + 34), "white")
    out.paste(crop.convert("RGB"), (90, 34))
    d = ImageDraw.Draw(out)
    d.text((6, 8), f"PDF p. {page} — {note}", font=font(15), fill=(0, 0, 0))
    used = set(m["slots"])
    for s in range(top_slot, bottom_slot + 1):
        y = 34 + (m["centres"][0] + s * m["pitch"] - y0) * scale
        inked = s in used
        d.line([(90, y), (out.width, y)], fill=BLUE if inked else RED, width=1)
        d.text(
            (10, y - 9),
            f"slot {s}  {'text' if inked else 'EMPTY'}",
            font=font(13),
            fill=BLUE if inked else RED,
        )
    out.save(f"{OUT}/{name}")
    return out.size


def slot_map(page, m):
    """The whole page, reduced, with each slot numbered down the margin."""
    scale = 0.62
    im = m["image"].convert("RGB")
    out = Image.new("RGB", (int(im.width * scale) + 60, int(im.height * scale)), "white")
    out.paste(im.resize((out.width - 60, out.height), Image.LANCZOS), (60, 0))
    d = ImageDraw.Draw(out)
    used = set(m["slots"])
    last = max(used)
    for s in range(0, last + 2):
        y = (m["centres"][0] + s * m["pitch"]) * scale
        if y < 4 or y > out.height - 4:
            continue
        inked = s in used
        if s % 5 == 0 or not inked or s == last:
            d.text(
                (4, y - 7),
                f"{s}{'' if inked else ' —'}",
                font=font(12),
                fill=GREY if inked else RED,
            )
        d.line([(52, y), (58, y)], fill=GREY if inked else RED, width=2)
    d.text(
        (64, 4),
        f"PDF p. {page}: text in slots {sorted(used)[0]}"
        f"–{last}, empty at {sorted(set(range(last)) - used)}",
        font=font(13),
        fill=(0, 0, 0),
    )
    out.save(f"{OUT}/page-{page}-slots.png")


def column_ruler(page, m, slot, name, note, columns):
    """A crop of one line with a character-column ruler under it."""
    scale = 3
    g = PAGES[page]
    y = m["centres"][0] + slot * m["pitch"]
    crop = m["image"].crop((int(g["origin"] - 12), int(y - 9), int(g["origin"] + 700), int(y + 9)))
    crop = crop.resize((crop.width * scale, crop.height * scale), Image.LANCZOS)
    out = Image.new("RGB", (crop.width, crop.height + 60), "white")
    out.paste(crop.convert("RGB"), (0, 26))
    d = ImageDraw.Draw(out)
    d.text((4, 4), f"PDF p. {page} — {note}", font=font(15), fill=(0, 0, 0))
    for col, label in columns.items():
        x = (12 + col * g["pitch"]) * scale
        d.line([(x, 26), (x, crop.height + 30)], fill=RED, width=2)
        d.text((x + 3, crop.height + 32), f"{label} @ {col}", font=font(13), fill=RED)
    out.save(f"{OUT}/{name}")


def main():
    summary = {}
    for page, g in PAGES.items():
        m = measure(page)
        used = sorted(set(m["slots"]))
        summary[page] = {
            "listing_page": g["listing"],
            "deskew": g["deskew"],
            "fitted_line_pitch_px": round(m["pitch"], 4),
            "text_rows": len(used),
            "slots_with_text": used,
            "empty_slots_above_last": [s for s in range(used[-1]) if s not in set(used)],
            "last_slot": used[-1],
            "ink_pixels_per_slot": m["weights"],
            "glyph_height_per_slot": m["heights"],
            "shortest_printed_row_height": m["shortest_row"],
            "tallest_empty_slot_height": m["tallest_empty"],
            "rule_scanlines_removed": m["rule_rows"],
        }
        ruler(page, m, 0, 6, f"page-{page}-gap.png", "the head, the gap below it, and the first lines")
        slot_map(page, m)
    column_ruler(
        199,
        measure(199),
        4,
        "page-199-header.png",
        "the column header",
        {1: "LOC", 12: "OCTAL", 25: "CNTRL", 58: "SYMBOLIC"},
    )
    with open(f"{OUT}/measurements.json", "w") as f:
        json.dump(summary, f, indent=2)
    print(json.dumps(summary, indent=2))


main()
