# Chunk A6 review record, 10 August 2026

M4 stage 2, phase A, chunk A6: the blind scan pass over listing pages 17, 18
and 19 of the 90.05 object listing, PDF pp. 208 to 210.

`index.html` is the record. It is standalone: every plate is embedded as a
data URI, so the file renders from any location with no network and no server.

## What it asks Jack

| Item | Status | Question |
|---|---|---|
| A | Your call | Listing page 19 prints 55 lines where the conversion holds 54, because the printer wrapped an instruction under an over-long label. May the conversion change? |
| B | Human OCR | Listing page 17 prints `BL)3,2` or `8L)3,2`. The ink does not settle it, and two readers on adjacent pages leaned opposite ways. |
| C | Settled | Three blank counts, corrected under Jack's option B of 9 August 2026. |
| D | Settled | Everything else agrees field for field, and the 57-slot frame now holds on thirteen pages of thirteen. |

## What each directory holds

| Path | Contents |
|---|---|
| `crops/` | Each plate as a PNG, at the magnification the document shows |
| `evidence/page-2NN-report.md` | What each reader wrote about its own page |
| `evidence/page-2NN.txt` | Each reader's transcription, one record per line slot |
| `evidence/reader-results.json` | The three structured results, including each reader's own statement that it opened no banned file |
| `evidence/reader-prompt.md` | The prompt all three readers were given |
| `tools/crops.py` | Cuts every plate from the page scans |
| `tools/measure.py` | Measures every line-ink figure item A quotes, and names each band by the print columns its ink occupies |
| `tools/compare.py` | Compares each transcription against the target, field by field. Plain code, never a reader |

## Jack's rulings, 10 August 2026

Both items are answered, and the banner at the top of `index.html` holds them.

- **Item A.** The conversion carries the two lines the page prints. Fidelity to
  the PDFs governs. He also confirmed from the scan that no form rule separates
  the two rows.
- **Item B.** `BL)3,2` stands, on name structure and on the prefix's
  attestation across the listing, against the lean of this page's ink. The
  ruling covers the whole `B` against `8` class, which is now four sites across
  three pages.

Pull request #97 applies both.

## One correction, 10 August 2026

The first version of this record quoted the wrong line's ink and misread its
own band count. Both errors came from naming a line by how much ink it carries
instead of by where that ink sits. `tools/measure.py` now prints the field
columns of every band, and the footer of `index.html` states what changed.
Jack authorized replacing the branch; no ruling had been given against the
earlier version.

## How to rebuild it

```sh
python3 tools/crops.py
python3 tools/build_doc.py
```

`tools/compare.py` reads the readers' working directories, which are session
scratch and are not preserved here. The transcriptions in `evidence/` are the
same files it read.

## The method these three readers followed

Each reader had one page scan and nothing else. The prompt named the files it
must not open: the target, the verification record, both target generators, the
90.05 conversion, the M4 and M1 design records, everything under
`test/goldens/`, and every page scan but its own. Each worked in a directory of
its own, because two readers in chunk A4 shared one and a working file
collided. Six readers ran at once across chunks A5 and A6, and none collided.
