# Page-head columns review record — 9 August 2026

This directory is the complete record of one measurement: the correction of the
25 page heads in the conversion of J28-6169 Appendix 90.05, and the scan
evidence behind it. It is orphan-committed, so it stays in git history and never
enters the working tree.

## Provenance

The record was assembled on 10 August 2026 from the orphan branch
`evidence-90.05-page-heads`, commit
`96dc6fa836b71d8d0ecb424939d48133cb5bec51`, when the review-record process
became the repository's standard. No review document existed when the work was
done. The correction was put to Jack in pull request #82 and merged there, so
nothing here is an open question.

The original branch README is preserved word for word at
`evidence/original-README.md`. Its "Untracked. Delete this directory" line was
true of the branch it lived on and is not true of this one.

## What to open

`index.html`. It is standalone — every crop is embedded — so it renders from any
location, with no network and no local server.

## What is here

| Path | What it holds |
|---|---|
| `index.html` | The review document |
| `crops/` | The five annotated head crops the document shows, as separate files |
| `evidence/measurements.json` | Every glyph's measured column, for all five pages |
| `evidence/original-README.md` | The branch README, verbatim |
| `tools/evidence.py` | Re-measures the five pages and redraws the crops |
| `tools/rewrite_heads.py` | Rewrites the 25 heads; already applied, so a no-op |
| `tools/build_doc.py` | Builds `index.html` |

## What was decided

1. All 25 heads carry one spacing, measured from the print. It is byte-identical
   to the head the compiler emits in `test/goldens/90.05-payroll.listing`.
2. The left margin is untouched. The conversion flattens the head-to-body margin
   by design, and M1-15 records that.
3. The column header was held as a separate erratum candidate here, then
   authorized and applied in pull request #83.

## To reproduce

Run the scripts from the repository root, where they expect to find
`comtran-manuals/`. Each writes into the directory named by its own `OUT`
constant, which still names the branch directory this record replaced; create
that directory, or point `OUT` at this record's `crops/`. The scripts are
shipped exactly as they ran. They need PIL and NumPy and nothing else.

## What the repository holds instead

`docs/design/m1-front-end.md` M1-15 and M1-16 carry the head geometry and the
scope of the correction. This directory carries the primary material those
records summarize.
