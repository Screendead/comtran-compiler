"""Derive the address spine of the 90.05 object program from the target.

B1's oracle is the target's LOC column, line for line. This script reads that
column back into the units it prints, so the word count of every generated
shape is a measurement and not a guess.

Four line forms carry no word of their own and the parser must know each:
  - a label-only line, which prints a LOC and hands the word to the next line
    (two labels on one word print one per line, the word on the last);
  - a wrapped label, which prints the LOC, OCTAL and CNTRL of its own word and
    pushes the mnemonic to the next line (M4-8.1);
  - that continuation line, which prints nothing but the instruction;
  - an EQU, which prints its equated value in the LOC column, out of order.
"""

import re
from collections import Counter

TARGET = "test/fixtures/90.05-object-listing.target"
MNEMONIC_COLUMN = 49
LABEL_COLUMN = 34
OFFSET = re.compile(r"^\+(\d+)$")


class Line:
    def __init__(self, raw, index):
        self.raw, self.index = raw, index
        self.loc = raw[0:5].strip()
        self.octal = raw[7:22].strip()
        self.control = raw[25:30].strip()
        self.label = self.offset = None
        self.mnemonic = self.operand = ""
        if len(raw) > 48 and raw[48] != " ":
            # The label reaches the mnemonic column, so it owns the rest of
            # the line and its instruction prints on the next one (M4-8.1).
            self.label = raw[LABEL_COLUMN:].split()[0]
            self.wrapped = True
            return
        self.wrapped = False
        middle = raw[30:49].strip()
        if OFFSET.match(middle):
            self.offset = int(middle[1:])
        elif middle:
            self.label = middle
        self.mnemonic = raw[MNEMONIC_COLUMN:56].strip()
        self.operand = raw[56:].strip()

    @property
    def is_continuation(self):
        return not self.loc and not self.label and self.offset is None and self.mnemonic

    def __repr__(self):
        head = self.label or (f"+{self.offset}" if self.offset is not None else "")
        return f"{self.loc:>5} {head:>24} {self.mnemonic:<7} {self.operand}"


def object_lines():
    out, raw = [], open(TARGET).read().split("\n")
    for i, l in enumerate(raw):
        if not l.strip() or l.startswith("DATE "):
            continue
        if l.startswith(" LOC") or l.lstrip().startswith(("THE ", "*CTEND", "DONE")):
            continue
        out.append(Line(l, i + 1))
    return out


def octal(n):
    return format(n, "05o")


def procedure_text(lines):
    """00165 through the last word of Location Counter 0."""
    first = next(i for i, l in enumerate(lines) if l.loc == "00165" and l.mnemonic)
    last = next(
        i for i, l in enumerate(lines) if l.mnemonic == "USE" and l.operand == "2"
    )
    return lines[first:last]


def units_of(lines):
    """A unit is a line that prints no `+n` plus the `+n` run under it.

    An EQU stands alone: it names a value, not a word, and it prints out of
    location order, so it never joins the unit that follows it. A label-only
    line does the opposite — it hands its name to the word on the next line.
    """
    units, current = [], None
    for l in lines:
        if l.is_continuation:
            current["lines"].append(l)
            continue
        if l.offset is None:
            if current:
                units.append(current)
            current = {"labels": [], "lines": [], "equ": l.mnemonic == "EQU"}
        if l.label:
            current["labels"].append(l.label)
        current["lines"].append(l)
    if current:
        units.append(current)

    merged, pending = [], []
    for u in units:
        if u["equ"]:
            merged.append(u)
            continue
        if not any(l.octal for l in u["lines"]):
            pending.extend(u["labels"])
            continue
        u["labels"] = pending + u["labels"]
        pending = []
        merged.append(u)
    return merged


def words_of(unit):
    """Distinct LOC values the unit's lines occupy."""
    return {l.loc for l in unit["lines"] if l.loc and l.octal}


def main():
    lines = object_lines()
    proc = procedure_text(lines)
    print(f"object lines parsed: {len(lines)}")
    print(f"procedure-text lines: {len(proc)}")

    locs = {l.loc for l in proc if l.loc and l.octal}
    lo = min(locs, key=lambda s: int(s, 8))
    hi = max(locs, key=lambda s: int(s, 8))
    span = int(hi, 8) - int(lo, 8) + 1
    print(f"\nprocedure text runs {lo} to {hi}")
    print(f"  span:            {span} words")
    print(f"  distinct LOCs:   {len(locs)} words")
    print(f"  gaps:            {span - len(locs)}")
    print(f"  Location Counter 1 origin: {octal(int(lo, 8) + span)} (attested 01621)")

    print("\n--- block arithmetic, forward from the derived origin ---")
    origin = int(lo, 8) + span
    for name, size, attested in (
        ("RS)", 30, "01621"),
        ("TS)", 7, "01657"),
        ("BL)", 3, "01666"),
        ("PI)", 3, "01671"),
        ("CP)", 62, "01674"),
    ):
        mark = "ok" if octal(origin) == attested else "MISMATCH"
        print(f"  {name} at {octal(origin)}  attested {attested}  {mark}")
        origin += size
    print(f"  pool ends at {octal(origin - 1)}  attested 01771")

    units = units_of(proc)
    total = sum(len(words_of(u)) for u in units)
    print(f"\n--- units ---")
    print(f"units in the procedure text: {len(units)}")
    print(f"words across all units:      {total} (procedure text holds {len(locs)})")

    print("\n--- every unit, in program order ---")
    for u in units:
        w = words_of(u)
        start = min(w, key=lambda s: int(s, 8)) if w else "-----"
        names = " ".join(u["labels"]) or "(unnamed)"
        print(f"  {start}  {len(w):>3}w  {names}")

    print("\n--- unit size histogram ---")
    sizes = Counter(len(words_of(u)) for u in units)
    for n in sorted(sizes):
        print(f"  {n:>3} words: {sizes[n]} units")

    print("\n--- wrapped labels (M4-8.1) ---")
    for l in lines:
        if l.wrapped:
            print(f"  {l.loc}  {l.label}  ({len(l.label)} chars)")

    print("\n--- EQU lines ---")
    for l in lines:
        if l.mnemonic == "EQU":
            print(f"  {l.loc}  {l.label:<10} EQU {l.operand}")

    print("\n--- GN) definitions in print order ---")
    gn = [
        (int(m.group(1)), l)
        for l in lines
        if l.label and (m := re.match(r"^GN\)(\d+)$", l.label))
    ]
    nums = sorted(n for n, _ in gn)
    print(f"  {len(gn)} printed, range GN){nums[0]:03d} to GN){nums[-1]:03d}")
    missing = [n for n in range(nums[0], nums[-1] + 1) if n not in set(nums)]
    print(f"  never printed: {[f'GN){n:03d}' for n in missing]}")
    print("  GN)084 and later:")
    for n, l in sorted(gn):
        if n >= 84:
            print(f"    GN){n:03d}  {l.loc}  {l.mnemonic:<7} {l.operand}")


if __name__ == "__main__":
    main()
