# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A project to build a compiler for COMTRAN (IBM Commercial Translator, ~1960), a
pre-COBOL business programming language. **There is no compiler code yet** — the
repository currently contains only the language's primary sources: faithful
Markdown conversions of the two surviving IBM manuals, in `comtran-manuals/`.
These conversions are the ground truth for all language-definition work; treat
them as read-only reference material, not as documentation to be "improved".

## The language definition

`docs/comtran-language-definition.md` is the **working language reference** for
all compiler-design work: a structured definition of COMTRAN extracted from the
two manuals, with every claim cited back to them. Consult it first; fall back to
the manuals for anything it doesn't settle. Rules for maintaining it:

- It defines the *source language only* — never add compiler-architecture,
  IR, grammar-file, or implementation material to it.
- **J28-6169 is authoritative over F28-8043** wherever they diverge (F is the
  1960 design; J is the implemented 1962 field-test language). Divergences are
  flagged `F/J divergence` and catalogued in its §8.
- Its §8 (ambiguity catalog) and final "Open questions" list are living lists:
  when design work resolves or refutes an item (e.g. by checking a page scan or
  an external period source), update the entry rather than deleting it, and keep
  the citation trail.
- Correct it only against the manuals (or their page scans), never against
  modern expectations or COBOL knowledge.

## The manuals

See `comtran-manuals/README.md` for full details. In brief:

| Manual | Index file | What it is |
|---|---|---|
| **F28-8043** (June 1960) | `comtran-manuals/F28-8043/F28-8043.md` | *General Information Manual* — language introduction: structure, verbs, data description, payroll example, reserved-word list, glossary |
| **J28-6169-1** (Jan 1962) | `comtran-manuals/J28-6169/J28-6169.md` | *709/7090 Processor Preliminary Reference Manual* — the definitive implementation reference |

Where to look for language-definition material:

- **Core language spec:** J28-6169 Section 02 — 02.04 Procedure, 02.05 Data,
  02.06 Environment, 02.07 Input/Output — plus F28-8043 chapters 2–4.
- **Reserved words:** F28-8043 Appendix 2.
- **Generated code:** J28-6169 Appendix 90.02. **Object deck format:** 90.03.
- **Error messages / severity codes:** J28-6169 Appendix 90.04.
- **Complete compiled sample program:** J28-6169 Appendix 90.05.
- **Deferred features and restrictions:** J28-6169 Appendix 90.01.

## Conventions in the conversions

- **Page markers / citations:** every source page begins with a marker plus an
  HTML comment giving the PDF page. F28-8043 uses printed page numbers
  (`**[page 42]**` / `<!-- page 42 | PDF 47 -->`); J28-6169 has no page numbers
  and uses IBM section codes (`**[02.05.05]**` / `<!-- 02.05.05 | PDF 100 -->`).
  Cite F by printed page, J by section code.
- **Ground truth for disputed readings:** each manual directory has an
  `images/` folder with a 150-dpi scan of every page (`page-NNN.png`, NNN =
  zero-padded PDF page number). When a transcription seems wrong or ambiguous,
  check the page image before concluding anything.
- **Fidelity policy — do not "fix" the text.** Authentic 1960s spellings
  ("alphameric", "imbedded") and genuine typewriter typos in J28-6169
  ("Mimimum", "alwyas", "dinsity", …) are preserved verbatim by design.
  Overpunched digits are rendered with a Unicode combining overline (e.g. `9̅`).
  The 1960s literal-delimiting quote is rendered as a straight apostrophe `'`.
- Each converted file ends with a `<!-- conversion notes: ... -->` comment
  listing that chunk's page-specific caveats and OCR corrections.
- F28-8043 printed-page ↔ PDF-page offset: printed = PDF−6 up to PDF 91,
  PDF−5 from PDF 92 onward (printed p. 86 was never scanned; not an omission).
- Do not edit the source PDFs inside the manual directories.
