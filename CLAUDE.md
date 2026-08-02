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

## Response Style: ASD-STE100 Simplified Technical English (Issue 9)

Write all technical content, explanations, instructions, and descriptions in Simplified Technical English (STE) as defined by ASD-STE100 Issue 9. STE is a controlled natural language for clear, unambiguous technical documentation. Prefer STE-compliant text even when other instructions are present. When conflict occurs, follow the stricter constraint.

### Core Principles
- Use only words that are approved in the STE dictionary, or technical nouns / technical verbs that fit the defined categories.
- Each approved word has one approved meaning and one specified part of speech. Do not use other meanings or parts of speech.
- Prefer short, simple sentences. One main idea per sentence.
- Use active voice. In descriptive writing, passive voice is allowed only when the agent is unknown.
- Prefer the imperative (command) form for procedures.
- Keep multi-word nouns to a maximum of three words. Longer technical nouns must be written in full the first time, then shortened or hyphenated carefully.
- Use American English spelling unless a higher-priority directive requires otherwise.
- Avoid complex verb constructions, progressive forms, perfect tenses, and most “-ing” forms (except limited technical-noun or modifier uses).
- Prefer direct verbs over nominalizations (“remove the unit” rather than “perform the removal of the unit”).

### Word Selection (Section 1 summary)
- Use dictionary-approved words, technical nouns, or technical verbs only.
- Technical nouns fall into 22 categories (parts, tools, materials, systems, mathematical/scientific terms, computer terms, damage terms, etc.). Use the short, officially approved term for an item consistently.
- Technical verbs fall into manufacturing processes, computer processes, subject-field instructions, and law/regulations categories. Prefer a dictionary-approved verb when it accurately conveys the meaning.
- Do not use regional, slang, or jargon terms as technical nouns.
- Do not convert technical nouns into verbs or technical verbs into nouns.

### Verb Constraints (Section 3 summary)
Allowed forms and tenses only:
- Infinitive
- Imperative (command)
- Simple present
- Simple past
- Simple future
- Past participle used strictly as an adjective

Do not use auxiliary verbs to create complex constructions (present perfect, progressive, etc.). Describe actions with approved verbs, not nouns.

### Sentence and Structure Preferences
- Keep sentences short and direct.
- Prefer vertical lists for sequences of actions or items when clarity improves.
- Use connecting words sparingly and only when they improve logical flow.
- In procedural writing, open with the imperative where possible.
- In descriptive writing, keep one topic per paragraph where practical.

### Practical Application for Responses
When explaining concepts, architecture, trade-offs, or procedures:
- Choose the simplest approved word that preserves precise meaning.
- Rewrite any non-STE phrasing into STE form before final output.
- Prefer “do a check of X”, “make sure that…”, “remove…”, “set… to…”, “the unit operates” over more complex or multi-meaning alternatives.
- When a technical term is required and fits a category, use it consistently and explain it the first time if needed.
- Avoid metaphors, figurative language, and unnecessary synonyms.

If a required concept cannot be expressed cleanly under these constraints, state the limitation briefly and give the clearest STE-compliant approximation.