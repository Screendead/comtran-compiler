# Chunk A4 review record — 9 August 2026

This directory is the complete record of one human-in-the-loop review: the
questions put to Jack, the evidence behind them, and the rulings he gave. It is
orphan-committed, so it stays in git history and never enters the working tree.

The review covers M4 stage 2, chunk A4: listing pages 11, 12 and 13 of the 90.05
object listing, PDF pp. 202 to 204 of J28-6169.

## What to open

`index.html`. It is standalone — every crop is embedded — so it renders from any
location, with no network and no local server.

## What is here

| Path | What it holds |
|---|---|
| `index.html` | The review document, with the rulings banner added after Jack answered |
| `crops/` | The eight scan crops the document shows, as separate files |
| `evidence/page-20N.txt` | Each page rebuilt as text at its measured print columns, by a reader that saw only the scan |
| `evidence/page-20N-report.md` | Each reader's own measurement and judgment record |
| `evidence/reader-prompt.md` | The prompt all three readers were given |
| `tools/` | The scripts that measured, compared and built the document |

## The rulings

1. `BL)3` stands, provisionally. Neither the blind reader nor Jack could settle
   the glyph from the ink. It rests on name structure and on the prefix's
   attestation elsewhere in the listing.
2. The mark at location 00465 on listing page 13 is not a period.
3. The mark at location 00376 on listing page 12 is not a period.
4. Option B on the manual conversion: the seven blank-line corrections are
   authorized and applied, and each later chunk authorizes its own pages.

## What the repository holds instead

`test/fixtures/90.05-object-listing-notes.md` carries the per-page verification
record and every ruling above. This directory carries the primary material that
record summarizes.
