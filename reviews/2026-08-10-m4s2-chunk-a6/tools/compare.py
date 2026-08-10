"""Compare each chunk A5 reader's blind transcription against the target.

Plain code, never a reader (test/fixtures/90.05-object-listing-notes.md, "The
method"). The target's columns are M4-8's: LOC 0, OCTAL 7, CNTRL 25, label 34,
offset right-justified ending 42, mnemonic 49, operand 56.
"""

import re
import sys

REPO = "/Users/jacklusher/development/comtran-compiler"
SCRATCH = ("/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler"
           "/c9073b01-107a-4886-92e7-76ee79dd7c35/scratchpad/a6")
TARGET = f"{REPO}/test/fixtures/90.05-object-listing.target"

PAGES = [(17, 208), (18, 209), (19, 210)]

FIELDS = ["LOC", "OCTAL", "CNTRL", "LABEL/OFFSET", "MNEMONIC", "OPERAND"]


def squeeze(text):
    return " ".join(text.split())


def target_pages():
    """Return {printed page number: [lines]} keyed off each page head."""
    lines = open(TARGET).read().split("\n")
    pages, current = {}, None
    for line in lines:
        head = re.match(r"^DATE .*PAGE\s+(\d+)\s*$", line)
        if head:
            current = int(head.group(1))
            pages[current] = []
            continue
        if current is not None:
            pages[current].append(line)
    return pages


def target_records(lines):
    """Six fields per content line, and the count of leading blank lines."""
    blanks = 0
    for line in lines:
        if line.strip():
            break
        blanks += 1
    records = []
    for line in lines[blanks:]:
        if not line.strip():
            records.append(("<BLANK LINE INSIDE THE BODY>",) * 6)
            continue
        records.append((
            squeeze(line[0:5]),
            squeeze(line[7:25]),
            squeeze(line[25:34]),
            squeeze(line[34:49]),
            squeeze(line[49:56]),
            squeeze(line[56:]),
        ))
    return blanks, records


SLOT = re.compile(r"^slot\s+(\d+)\s*\|\s*(.*)$")


def reader_records(path):
    """Six fields per content slot, and the count of empty slots before the
    first one. The three readers wrote three layouts of the same record."""
    blanks, records, seen_content = 0, [], False
    for raw in open(path):
        match = SLOT.match(raw.strip())
        if not match:
            continue
        slot, body = int(match.group(1)), match.group(2)
        if slot == 0:
            continue
        # A record that carries the six fields is content, even when one of
        # them reads "(blank)". Only a record with no fields is an empty slot.
        parts = [p.strip() for p in body.split("|")]
        empty = len(parts) < 6 and any(
            word in body.lower() for word in ("blank", "empty", "no ink")
        )
        if empty and not seen_content:
            blanks += 1
            continue
        if empty:
            records.append(("<BLANK SLOT INSIDE THE BODY>",) * 6)
            continue
        seen_content = True
        if len(parts) < 6:
            records.append(("<UNPARSED>",) + (raw.strip(),) * 5)
            continue
        loc, octal, cntrl, tag, mnemonic, operand = parts[:6]
        strip = lambda s, word: squeeze(re.sub(rf"^{word}\s*", "", s))
        blankish = lambda s: "" if s.lower() in {"(blank)", "blank", "-", "(none)"} else s
        records.append((
            blankish(strip(loc, "LOC")),
            blankish(strip(octal, "OCTAL")),
            blankish(strip(cntrl, "CNTRL")),
            blankish(squeeze(tag)),
            blankish(squeeze(mnemonic)),
            blankish(squeeze(operand)),
        ))
    # The frame runs to slot 57 whatever the page prints, so a reader that
    # recorded the empty tail below its last content line recorded the frame,
    # not an interior blank.
    while records and records[-1][0].startswith("<BLANK SLOT"):
        records.pop()
    return blanks, records


def main():
    pages = target_pages()
    total = 0
    for printed, pdf in PAGES:
        t_blanks, t_rows = target_records(pages[printed])
        r_blanks, r_rows = reader_records(f"{SCRATCH}/page-{pdf}/transcription.txt")
        print("=" * 72)
        print(f"listing page {printed}, PDF p. {pdf}")
        print(f"  blank lines before the first content line: "
              f"target {t_blanks}, reader {r_blanks}"
              f"{'' if t_blanks == r_blanks else '   <-- DISAGREE'}")
        print(f"  content lines: target {len(t_rows)}, reader {len(r_rows)}"
              f"{'' if len(t_rows) == len(r_rows) else '   <-- DISAGREE'}")
        disagreements = 0
        for i, (t, r) in enumerate(zip(t_rows, r_rows), start=1):
            for field, tv, rv in zip(FIELDS, t, r):
                if tv != rv:
                    disagreements += 1
                    print(f"  line {i:2d} {field:13s} target {tv!r}  reader {rv!r}")
        print(f"  field disagreements: {disagreements}")
        total += disagreements
    print("=" * 72)
    print(f"TOTAL field disagreements across the three pages: {total}")
    return 0


sys.exit(main())
