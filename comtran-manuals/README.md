# COMTRAN Manuals — Markdown Conversion

Faithful Markdown conversions of the two scanned IBM Commercial Translator
(COMTRAN) manuals, produced for later language-definition work. Each manual's
directory contains its source PDF alongside the conversion.
Both source PDFs are 400-dpi grayscale page scans with no text layer; they were
OCRed (ocrmypdf/Tesseract) and then corrected chunk-by-chunk against the page
images before conversion.

## Contents

| Manual | Index | Pages | What it is |
|---|---|---|---|
| **F28-8043** (June 1960) | [F28-8043/F28-8043.md](F28-8043/F28-8043.md) | 124 | *General Information Manual* — typeset language introduction: language structure, procedure statements (verbs/commands), data description, complete payroll example, reserved-word list, glossary. |
| **J28-6169-1** (Jan 1962) | [J28-6169/J28-6169.md](J28-6169/J28-6169.md) | 221 | *709/7090 Processor Preliminary Reference Manual* — typewriter-set implementation reference: the definitive statement/data/environment/I-O reference (Section 02), loader, supervisor, operating and maintenance procedures, generated-code appendix, complete error-message list, compiled sample program. |

Each manual directory contains one Markdown file per chapter/section (see its
index file for the full map) plus an `images/` directory holding a PNG of **every**
source page (`page-NNN.png`, NNN = zero-padded PDF page number, 150 dpi).

## Citation / page markers

Every source page begins with a visible marker plus an HTML comment carrying the
PDF page number:

- **F28-8043** uses printed page numbers: `**[page 42]**` / `<!-- page 42 | PDF 47 -->`
- **J28-6169** has no ordinary page numbers; each page carries an IBM section code
  (top-right header): `**[02.05.05]**` / `<!-- 02.05.05 | PDF 100 -->`

So a citation like "J28-6169 02.04.03" or "F28-8043 p. 75" can be located by
search, and the `images/page-NNN.png` scan can always be pulled up for
verification.

## Coverage and quality

- **All 345 pages are covered** — every page appears exactly once as a marker;
  verified mechanically (marker monotonicity, no gaps/duplicates, all image links
  resolve).
- **Text quality:** both scans were clean and nearly all body text, tables, syntax
  general-forms, and program samples are fully transcribed. Program text and
  syntax notation were verified character-by-character against the scans during
  conversion; a sampled adversarial QA pass (~50 pages compared to scans by
  independent reviewers) surfaced only minor defects, which were fixed.
- **Fidelity policy:** original text is preserved verbatim, including authentic
  1960s spellings ("alphameric", "imbedded") and genuine typewriter typos in
  J28-6169 ("Mimimum", "dinsity", "alwyas", "standart", …) — each suspected typo
  was checked against the scan and kept only if the original prints it that way.
  Overpunched digits (printed with an overbar) are rendered with a Unicode
  combining overline, e.g. `9̅`.
- **Images:** figures, flowcharts, coding-form facsimiles, and complex ruled
  tables are embedded as page images at the point they occur, usually alongside a
  best-effort text transcription. Complex tables reproduced as Markdown also embed
  the scan below them for verification.
- **Left as images (with partial transcription):** the landscape line-printer
  listings of Appendix 90.05 in J28-6169 (PDF pages 187–217, the compiled sample
  program) are embedded page-by-page as images; the COMTRAN source-listing pages
  are additionally transcribed in fenced code blocks, while storage-map /
  object-code dump pages get a one-line description only.
- **Known limitations:** the literal-delimiting quotation-mark character of the
  1960s card code is rendered as a straight apostrophe `'`; multi-line spanning
  braces in syntax boxes are approximated in fixed-width blocks; each converted
  file ends with a `<!-- conversion notes: ... -->` comment describing any
  page-specific fallbacks, uncertain notation, and OCR corrections applied in
  that chunk.

## Provenance

Do not edit the source PDFs (`F28-8043/F28-8043_CommercialTranslatorGenInfMan_Ju60.pdf`
and `J28-6169/J28-6169-1_CommercialTranslator_Jan62.pdf`). The conversion pipeline (OCR → per-page correction
against scans by parallel agents → assembly → mechanical validation → sampled
adversarial QA → typo authentication) was run on 2026-08-01.
