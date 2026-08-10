"""Compare a blind reader's rebuilt page against the target, slot by slot.

Usage: python3 compare.py <listing-page> <reader-file>

The target page runs from its own head line to the line before the next head.
A disagreement prints both lines with a caret row marking every differing
column, so a one-column shift is visible as a shift and not as a rewrite.
"""

import sys

TARGET = (
    "/Users/jacklusher/development/comtran-compiler/"
    "test/fixtures/90.05-object-listing.target"
)


def target_page(page: int) -> list[str]:
    lines = open(TARGET).read().split("\n")
    head = next(i for i, l in enumerate(lines) if l.rstrip().endswith(f"PAGE  {page}"))
    end = next(
        (i for i in range(head + 1, len(lines)) if lines[i].startswith("DATE ")),
        len(lines),
    )
    return [l.rstrip() for l in lines[head:end]]


def marks(a: str, b: str) -> str:
    width = max(len(a), len(b))
    a, b = a.ljust(width), b.ljust(width)
    return "".join("^" if a[i] != b[i] else " " for i in range(width)).rstrip()


def main() -> int:
    page = int(sys.argv[1])
    got = [l.rstrip() for l in open(sys.argv[2]).read().split("\n")]
    while got and not got[-1]:
        got.pop()
    want = target_page(page)
    while want and not want[-1]:
        want.pop()

    print(f"listing page {page}: reader {len(got)} slots, target {len(want)} slots")
    printed = sum(1 for l in got if l), sum(1 for l in want if l)
    print(f"  printed rows: reader {printed[0]}, target {printed[1]}")
    print(f"  blank slots:  reader {len(got) - printed[0]}, "
          f"target {len(want) - printed[1]}")

    # The blank run after the head is the one difference the target expects,
    # so it is reported as a count and removed before the content compares.
    # Otherwise one extra blank shifts every line and hides a real change.
    def split(page: list[str]) -> tuple[str, int, list[str]]:
        body = 1
        while body < len(page) and not page[body]:
            body += 1
        return page[0], body - 1, page[body:]

    got_head, got_blanks, got_body = split(got)
    want_head, want_blanks, want_body = split(want)
    print(f"  blanks after head: reader {got_blanks}, target {want_blanks}"
          f"{'  <-- differs' if got_blanks != want_blanks else ''}")

    got = [got_head] + got_body
    want = [want_head] + want_body

    disagreements = 0
    for slot in range(max(len(got), len(want))):
        a = got[slot] if slot < len(got) else "<no slot>"
        b = want[slot] if slot < len(want) else "<no slot>"
        if a != b:
            disagreements += 1
            print(f"\nslot {slot}:")
            print(f"  reader |{a}|")
            print(f"  target |{b}|")
            print(f"         |{marks(a, b)}|")
    print(f"\n{disagreements} disagreement(s)")
    return 1 if disagreements else 0


if __name__ == "__main__":
    sys.exit(main())
