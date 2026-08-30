# 2026-08-30 · M4 stage 3, the object deck and the CT Loader

Stage 3 is commit 87fe6ca3809343a5cd4a4e1d6777e9568d33417b on
`m4s3-deck-loader`. It punches the object deck — the `*FILE` and `*SPEC`
control cards, `*CTEXT`, the relative binary text section, and `*CTEND` —
and reads it back with our CT Loader at a chosen origin. It also grows
`--emit-object` to the whole printed document after the source pages, so
`test/goldens/90.05-payroll.storage-map` is now PDF pp. 198 to 216
entire. `docs/design/loader.md`, entries LD-1 to LD-4, is the design
record these decisions landed in.

Eleven items. Seven are DECIDED under the CLAUDE.md section 12 standing
rule, and silence lets them stand. One is YOUR CALL: authorization to
correct one character of the PDF p. 198 transcription. It blocks nothing.
Three are SETTLED and ask nothing.

The stage-3 pull request opens under Jack's standing authorization of
2026-08-16 and merges under the EXTERNAL-REVIEW.md charter.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone; every crop is embedded, so it opens anywhere. |
| `crops/p198-head-message.png` | PDF p. 198: the page head and the message line, with the computed print-column ruler. |
| `crops/p198-page.png` | PDF p. 198: the whole page body, at page magnification. Item 5 reads the frame off it; item 8 shows it as the view that misleads. |
| `crops/p198-file01.png` | PDF p. 198: the `*FILE 01` and `*SPEC 01` lines, with the ruler. |
| `crops/p198-file06.png` | PDF p. 198: the `*FILE 05` through `*SPEC 07` lines enlarged, with the ruler. |
| `crops/spec06.png` | The same six lines without the ruler, the plate item 8 turns on. |
| `crops/p198-ctext.png` | PDF p. 198: the `*CTEXT` card, with the ruler. |
| `crops/p216-closing.png` | PDF p. 216: the end-of-text line, the message, `*CTEND` and `DONE`, with the ruler. |
| `evidence/p198-cols.txt` | `tools/cols.py` output for PDF p. 198: the deskew, the pitch, and every ink line's slot and column runs. |
| `evidence/p216-cols.txt` | The same for PDF p. 216. |
| `evidence/p198-transcription.txt` | The PDF p. 198 listing block of `comtran-manuals/J28-6169/90.05-sample-program.md`, verbatim. Item 8 asks about its twelfth card. |
| `evidence/p198-golden.txt` | The first twenty lines of `test/goldens/90.05-payroll.storage-map` at 87fe6ca: listing page 7 as the compiler prints it. |
| `evidence/loader.md` | `docs/design/loader.md` at 87fe6ca, entries LD-1 to LD-4. |
| `tools/build_doc.py` | Writes `index.html`, embedding each crop as a data URI. Edit this, not the HTML. |
| `tools/cols.py` | Deskews a page scan, drops the tractor-feed dashes, solves the character pitch from DATE and PAGE, and prints every line's slot and column runs. |
| `tools/ruler.py` | Draws the solved print-column ruler under a crop. Every plate here carries it. |
| `tools/lines.py` | The earlier line-finder that produced the line bands the column pass consumes. |

Each page is calibrated on its own: PDF p. 198 deskews 0.500° at 9.253 px
a column, PDF p. 216 deskews 1.150° at 9.2651 px, and their registration
differs by 6 px. Every column claim in the record is measured from the
150-dpi scan, never read off the indentation of a transcription
(CLAUDE.md section 9).
