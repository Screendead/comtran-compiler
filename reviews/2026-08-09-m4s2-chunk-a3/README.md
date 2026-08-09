# Chunk A3 review record — 9 August 2026

This directory is the complete record of one page-verification chunk: listing
pages 8, 9 and 10 of the 90.05 object listing, PDF pp. 199 to 201 of J28-6169,
each read against its own scan. It is orphan-committed, so it stays in git
history and never enters the working tree.

## Provenance

The record was assembled on 10 August 2026 from the orphan branch
`evidence-pages-199-201`, commit
`129a6c9adebf9bf318b3c7ce9e1e5ea6c6632efa`, when the review-record process
became the repository's standard. No review document existed when the work was
done. The three decisions were put to Jack in pull request #88 and merged there,
so nothing here is an open question.

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
| `crops/page-NNN-gap.png` | The gap between the head and the first content line, per page |
| `crops/page-NNN-slots.png` | The slot map of the whole page, per page |
| `crops/page-199-header.png` | The column header with its measured ruler |
| `evidence/measurements.json` | Line pitch, empty slots and ink heights, for all three pages |
| `evidence/original-README.md` | The branch README, verbatim |
| `tools/evidence.py` | Re-measures the three pages and redraws the crops |
| `tools/build_doc.py` | Builds `index.html` |

## What was decided

1. No content changed. All 162 lines already agreed with the target.
2. Listing page 8 prints three blank lines after its head; pages 9 and 10 print
   two. The conversion held one on each.
3. The page body is a frame of 57 line slots, with the last content line always
   in slot 57.

The four erratum candidates this chunk held were released at the end of chunk
A4, on 9 August 2026, when Jack authorized the blank-line corrections and
changed the standing rule so each later chunk authorizes its own pages.

## To reproduce

Run `tools/evidence.py` from the repository root, where it expects to find
`comtran-manuals/`. It writes into the directory named by its own `OUT`
constant, which still names the branch directory this record replaced; create
that directory, or point `OUT` at this record's `crops/`. The script is shipped
exactly as it ran. It needs PIL and NumPy and nothing else.

## What the repository holds instead

`test/fixtures/90.05-object-listing-notes.md` carries the per-page verification
record, and `docs/design/m4-codegen.md` M4-8 carries the frame. This directory
carries the primary material those records summarize.
