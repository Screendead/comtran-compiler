# Chunk B1 review record — 11 August 2026

This directory is the complete record of one question put to Jack: the two rules
M4 stage 2, chunk B1 cannot derive, the evidence behind them, and a
recommendation on each. It is orphan-committed, so it stays in git history and
never enters the working tree.

The two items are the clause digits of the statement stamp, and the per-section
maximum of result storage. Both are `YOUR CALL`. Jack answered on 15 August
2026 — "Adopt the fitted rule, and run the bounded search on RS)" — and the
rulings banner at the top of `index.html` carries the answer. Both
recommendations were adopted as put.

## What to open

`index.html`. It is standalone and renders from any location, with no network
and no local server.

## No image plates

This record carries no page scans. The object listing is a text artifact here,
not a glyph reading, and the fixture the excerpts come from,
`test/fixtures/90.05-object-listing.target`, is already scan-verified. `crops/`
therefore holds the listing excerpts as plain text, quoted verbatim with their
full columns. Because they are text and not ink, they take the reader's theme in
`index.html` rather than the forced white ground a scan plate keeps.

## What is here

| Path | What it holds |
|---|---|
| `index.html` | The review document |
| `crops/statement-stamp-sites.txt` | The five statement-stamp sites, verbatim from the target fixture |
| `crops/statement-stamp-pool-words.txt` | The eight constant-pool words those sites name, with the BCD reading of each |
| `crops/constant-pool-equ-lines.txt` | The three `EQU` lines whose printed LOC depends on the pool's size |
| `crops/result-storage-references.txt` | The five `RS)` references, the `RS) BSS 30` reservation, and the `BGN 2,PI)1` line its width moves |
| `evidence/specs/<family>/spec.md` | The eight family specifications the catalogue is built from |
| `evidence/reconcile-report.txt` | The ninth pass, which walked the eight specifications against the listing |
| `evidence/answer-key.txt` | The object listing reduced to its LOC and symbolic columns |
| `evidence/source-statements.txt` | The six COMTRAN source statements the counts rest on, from the compilation listing |
| `tools/build_doc.py` | The script that built `index.html`; it reads `crops/` at build time, so page and files cannot drift |

## Two notes on the evidence

**One citation is corrected in the document.** The structure specification cites
`J 90.02.28` for the `SYS)264` passage that names `STATEMENT-NUMBER` and
`SUB-STATEMENT-NUMBER`. The page scan `comtran-manuals/J28-6169/images/page-168.png`
prints `90.02.29` in its head and carries that passage, so the document says
`J 90.02.29` and states the correction in place. Nothing else in either item
changes.

**The specifications shipped here carry a generated manual-link block.** The
reconcile report's section 0 names the working paths the ninth pass read; those
directories are gone. The copies in `evidence/specs/` are the same eight
documents after `tool/linkify_manual_refs.dart` appended the link block. The
report's note that the `specs/figuratives` copy was a shorter, stale draft no
longer applies: that file was replaced by the full copy, which is what this
record ships.

## What the repository holds instead

`test/fixtures/90.05-object-code-notes.md` carries the whole shape catalogue and
both open questions. It is in flight and uncommitted on branch `m4s2-chunk-b1`
at the time of writing, so this record links to no copy of it.
