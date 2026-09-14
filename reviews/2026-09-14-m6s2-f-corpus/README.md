# 2026-09-14 · M6 stage 2, chunk 2a: the 1960 corpus and the course of chunk 2b

Chunk 2a keys the 1960 payroll program of F28-8043 Appendix 1 as two card decks
— the program as printed, and the same program with the five divergences the
1962 front end demands — and pins both listings as goldens. The date of the
evidence is 2026-09-14. Every repository link points at commit `1892093`, the
head of branch `m6s2-f-corpus`.

Six items. Three are DECIDED under the CLAUDE.md section 12 standing rule: the
course of the next chunk, the five divergences the applied deck takes, and the
three amendments to M6-1 with the goldens' fixed page head. Three are SETTLED:
the 55-message diagnostic corpus the verbatim deck produces, a seventh codegen
defect the corpus found, and what this chunk changed in the language definition.
No item waits for Jack. Silence lets each one stand, and he can overturn any of
them.

The record was built after the work landed. The decks and goldens are commit
`ae37940`, the design entries and the definition rows `2647141`, and the
decision of item 1 `1892093`. No review document existed before them, which is
the route section 12 opens for a decision with one viable option.

Chunk 2a lands as one pull request on branch `m6s2-f-corpus`. It changes two
files under `test/goldens/`, so it merges on external-review convergence under
the charter. Opening it is under Jack's standing authorization of 2026-08-16.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone: the two crops are embedded, so it needs no network and no server. Open it anywhere. |
| `tools/build_doc.py` | Writes `index.html`. Edit this, not the HTML. |
| `tools/measure.py`, `tools/measure2.py` | The two scripts the keying pass ran over the page scans of F28-8043 to measure card columns. The first finds the text rows and the character groups on a page; the second fits a character pitch and prints each group's column. |
| `crops/` | The two images the record shows. |
| `evidence/` | The inventory the record's first item was built from. `evidence/README.md` says what it is. |

`tools/build_doc.py` builds every repository link from one commit hash at the top
of the file, commit `1892093`. Set `RECORD_HEAD` in the environment to rebuild
against another. A record outlives the branch it was written beside, so no link
may point at a branch.

Both crops come from `comtran-manuals/F28-8043/images/page-109.png`, the scan of
the machine listing at printed page 104. `crops/crop-10001-10007.png` shows
serials 10001 to 10007 with their level column; `crops/crop-table-lit.png` shows
the same six constant lines enlarged, each with its own pair of quote marks.
Item 6 rests the definition's "Table initialization" correction on them.

## Correction

Correction, 2026-09-14, appended after commit 1ca6711 on m6s2-f-corpus. Item 6 said chunk 2b owes the fix of the §9.8 “Table initialization” row. A crop of the page-100 form (images/page-105.png) shows serials 02 to 07 each at level 2 with their own quote marks and an empty CONT column, so the row is corrected in this pull request instead. The F conversion’s note that reads the six cards as one continued literal is a new erratum candidate in HANDOVER. M6-6’s card count now reads “187 source cards and two division headers”.

Correction, 2026-09-14, appended after commit 14085fe on m6s2-f-corpus, the answer to round 1 of the external review. The Anthropic reviewer showed that the 1960 cards carry their serial in columns 1 to 5 (F p. 65: the digits “must be punched in each card”; J 02.02.01: the listing’s first column is the card sequence number), and the verbatim deck now punches them; the applied deck carries none, as a deck in the 1962 form. The seven CALL synonyms moved from column 40, the conversion’s spacing, to column 37, the scan’s. Item 2 and item 4 describe the deck as it was before that commit.

## Answer

Answer, 2026-09-14. Jack authorized both erratum candidates, in these words:
"Both errata authorised". The F conversion's note after the page-100 form is
corrected in commit `a68e185` on branch `errata-p217-table`, pull request 136.
The note now reads serials 02 to 07 as six unnamed level-2 entries, each with
its own quoted 22-character literal and an empty continuation column, and
TABLE.ITEM at serial 08 lays its twelve 11-character entries over the 132
characters. The J conversion's note on PDF p. 217, which item 6 leaves open, is
corrected in commit `c023111` of the same pull request; the review record of
2026-09-13 carries that answer. The answer is appended under item 6.
