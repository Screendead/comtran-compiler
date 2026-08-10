"""Cut the plates for the temporary-storage record from PDF p. 215.

The page carries the four Location Counter 1 reservations. The record needs
them at a magnification that shows the `BSS 7` operand is what the print
holds, and one wider plate that shows where the block sits on the page.

Deskew before anything else: these scans carry a tilt near one degree, and the
row profile never separates the lines until it is removed.
"""

import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(REC))
PAGE = os.path.join(REPO, "comtran-manuals/J28-6169/images/page-215.png")
OUT = os.path.join(REC, "crops")

INK = 128
RULE_RUN = 25


def longest_run(row):
    best = run = 0
    for v in row:
        run = run + 1 if v else 0
        best = max(best, run)
    return best


def deskew(gray):
    """Rotate by the angle that maximises the variance of the row profile."""
    best, angle = None, 0.0
    for candidate in np.arange(-2.0, 2.0, 0.05):
        rotated = gray.rotate(candidate, resample=Image.BILINEAR, fillcolor=255)
        mask = np.asarray(rotated) < INK
        variance = mask.sum(axis=1).var()
        if best is None or variance > best:
            best, angle = variance, candidate
    return gray.rotate(angle, resample=Image.BILINEAR, fillcolor=255), angle


def text_rows(mask):
    """Row bands that hold text, with the form rules deleted."""
    keep = np.array([longest_run(r) < RULE_RUN for r in mask])
    profile = np.where(keep, mask.sum(axis=1), 0)
    threshold = max(2, profile.max() * 0.04)
    bands, start = [], None
    for y, v in enumerate(profile):
        if v > threshold and start is None:
            start = y
        elif v <= threshold and start is not None:
            if y - start >= 4:
                bands.append((start, y))
            start = None
    return bands


def save(image, name, scale=1):
    if scale != 1:
        image = image.resize(
            (image.width * scale, image.height * scale), Image.LANCZOS
        )
    image.save(os.path.join(OUT, name))
    print(f"  {name}  {image.width}x{image.height}")


def main():
    os.makedirs(OUT, exist_ok=True)
    gray = Image.open(PAGE).convert("L")
    straight, angle = deskew(gray)
    print(f"deskew {angle:+.2f} degrees")
    mask = np.asarray(straight) < INK
    bands = text_rows(mask)
    print(f"{len(bands)} text bands")

    # Band 2 is the page head; band 3 is the first content line. The four
    # reservations are content lines 34 to 37, and the `USE 1` that opens
    # Location Counter 1 is the line above them.
    USE_LINE, POOL_LINE = 34, 41
    pad = 10

    def cut(first, last, name, scale):
        top, bottom = bands[first][0] - pad, bands[last][1] + pad
        # Measure the horizontal extent on text rows only. A dashed rule runs
        # into both margins, so including its rows would pad the plate with
        # empty paper and shrink the print.
        band_mask = mask[top:bottom]
        text_only = np.array(
            [r if longest_run(r) < RULE_RUN else np.zeros_like(r) for r in band_mask]
        )
        columns = np.where(text_only.any(axis=0))[0]
        left, right = columns.min() - pad, columns.max() + pad
        save(straight.crop((left, top, right, bottom)), name, scale=scale)

    cut(USE_LINE, POOL_LINE, "a1-reservations.png", 3)
    cut(USE_LINE - 8, POOL_LINE + 6, "a2-reservations-in-place.png", 2)


if __name__ == "__main__":
    main()
