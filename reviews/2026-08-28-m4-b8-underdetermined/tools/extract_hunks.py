#!/usr/bin/env python3
"""Write the evidence diffs, one file per decision, from the chunk's commits.

Run from the repository root:  python3 reviews/<dir>/tools/extract_hunks.py

Each file holds the hunks of `git show <commit> -- <path>` that carry one
decision. A hunk index counts from 1 inside one file's diff; `all` takes
the whole file. A hunk two decisions share appears in both files. The
seven decision files come from 8219b6f; `1b-fixed-names-fix.diff` comes
from f38ea63, the internal review's correction of item 1's count.
"""
import subprocess
import sys
from pathlib import Path

DECISIONS = "8219b6ff860e95f680bd8626d121564c1fb7e769"
FIX = "f38ea63d887daa81b5476ab44e788522e7f88bb8"
OUT = Path(__file__).resolve().parent.parent / "evidence"

SITES = {
    "1-name-tally.diff": [
        (DECISIONS, "lib/src/data/name_tally.dart", "all"),
        (DECISIONS, "lib/src/data/resolver.dart", "all"),
        (DECISIONS, "lib/src/codegen/procedure.dart",
         [3, 4, 5, 6, 7, 8, 9, 11, 14, 18]),
    ],
    "1b-fixed-names-fix.diff": [
        (FIX, "lib/src/codegen/procedure.dart", "all"),
        (FIX, "test/codegen_diagnostics_test.dart", "all"),
        (FIX, "docs/design/m4-codegen.md", "all"),
    ],
    "2-pool-counter.diff": [
        (DECISIONS, "lib/src/codegen/pool.dart", "all"),
        (DECISIONS, "lib/src/codegen/codegen_messages.dart", "all"),
        (DECISIONS, "lib/src/codegen/procedure.dart", [9]),
    ],
    "3-msg-946.diff": [
        (DECISIONS, "lib/src/codegen/procedure.dart", [15, 16]),
    ],
    "4-msg-947.diff": [
        (DECISIONS, "lib/src/codegen/procedure.dart", [3, 10, 15, 16, 17]),
    ],
    "5-stop-shape.diff": [
        (DECISIONS, "lib/src/codegen/codegen.dart", "all"),
        (DECISIONS, "lib/src/driver/driver.dart", "all"),
        (DECISIONS, "lib/src/emit/emit_code.dart", "all"),
        (DECISIONS, "bin/comtranc.dart", "all"),
    ],
    "6-measuring-pass.diff": [
        (DECISIONS, "lib/src/codegen/procedure.dart", [2]),
        (DECISIONS, "lib/src/codegen/codegen.dart", [2]),
    ],
    "7-allocator-crossing.diff": [
        (DECISIONS, "lib/src/data/allocator.dart", "all"),
        (DECISIONS, "lib/src/data/semantics.dart", "all"),
    ],
}


def file_diff(commit, path):
    text = subprocess.run(
        ["git", "show", commit, "--format=", "--", path],
        check=True, capture_output=True, text=True,
    ).stdout
    lines = text.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.startswith("@@")]
    head = "".join(lines[: starts[0]])
    hunks = [
        "".join(lines[s:e]) for s, e in zip(starts, starts[1:] + [len(lines)])
    ]
    return head, hunks


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, parts in SITES.items():
        commits = sorted({commit for commit, _, _ in parts})
        out = [f"# {name}: hunks of commit {' and '.join(commits)}\n"]
        for commit, path, which in parts:
            head, hunks = file_diff(commit, path)
            picked = hunks if which == "all" else [hunks[i - 1] for i in which]
            out.append(head + "".join(picked))
        (OUT / name).write_text("".join(out))
        print(name, file=sys.stderr)


if __name__ == "__main__":
    main()
