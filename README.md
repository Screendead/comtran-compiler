# COMTRAN Compiler

A project to build a compiler for **COMTRAN** (IBM Commercial Translator), the 1959–1962 pre-COBOL business programming language — recovered from its two surviving manuals, and rebuilt from there.

## What COMTRAN was

Commercial Translator was IBM's business data-processing language of the immediate pre-COBOL era. It was defined in a June 1960 *General Information Manual* (F28-8043) and implemented as a field-test compiler for the IBM 709/7090, documented in a January 1962 *Preliminary Reference Manual* (J28-6169-1) whose sample listing was compiled on 18 October 1961. Programs are written on card forms in three portions — Procedure, Data Description, and Environment — as English-like imperative sentences (`MOVE`, `SET`, `GET`, `FILE`, `DO`, `GO TO … WHEN …`) over period-joined compound names (`END.OF.MASTERS`), with pictorial data descriptions and tape-oriented file handling. Commercial Translator is generally credited, alongside FLOW-MATIC, as one of the principal inputs to COBOL. It then disappeared: no compiler, and no machine-readable source, survives.

This repository is the recovery-and-rebuild effort: first the language, reconstructed from primary sources under strict citation discipline; next, a working compiler for it.

## What is here

| Path | What it is |
|---|---|
| `comtran-manuals/` | Faithful Markdown conversions of both manuals, with a 150-dpi scan of every page as ground truth. **Read-only.** Citation and fidelity conventions in `comtran-manuals/README.md`. |
| `comtran-manuals/F28-8043/` | *General Information Manual* (June 1960) — the 1960 language design. |
| `comtran-manuals/J28-6169/` | *709/7090 Processor Preliminary Reference Manual* (Jan 1962) — the implemented field-test language. **Authoritative wherever the two manuals diverge.** |
| `docs/comtran-language-definition.md` | The working language reference (~4,250 lines): a structured, fully cited definition of COMTRAN extracted from the manuals. Its §8.5 catalogs every ambiguity and F/J divergence with plausible resolutions; the end-of-file **Open Questions** list tracks what the sources cannot settle, each entry annotated as evidence resolves it. |
| `docs/HANDOVER.md` | Project state, method, confidence assessment, and the compiler roadmap. |
| `docs/research-2026-08-01-interrupted.md` | Raw outputs of the research passes: extraction drafts, adversarial verification verdicts, and scout maps of external period manuals. |

## Method and status

The definition was built by parallel extraction over both manuals, then adversarially verified — every verbatim quote checked character for character, numeric limits and citations re-derived, disputed readings settled at 400–600 dpi against the page scans. Deepening passes then mined the generated-code appendix (J 90.02), the compiled sample-program listing (J 90.05, pixel-verified), and external period sources (the 709/7090 IOCS manual C28-6100-2, the IBM 705 and 1401 references) to settle questions the manuals delegate.

**Status:** the language definition is complete and verified. Of its 74 Open Questions, 8 are resolved and 10 narrowed; the remainder are implementation decisions (e.g. per-message severity values) or genuinely unrecoverable. **There is no compiler code yet** — the roadmap below is the next phase.

## Ground rules

- The manual conversions are ground truth and read-only; when a transcription is doubted, the page scan decides.
- **J28-6169 outranks F28-8043** wherever they diverge (F is the 1960 design; J is the implemented 1962 language).
- The definition is corrected only against the manuals or their scans — never against COBOL knowledge or modern expectations. External period evidence is admitted for what the manuals delegate, always labeled `(external: …)`.
- The definition stays design-free: compiler architecture and implementation decisions live in separate documents.

## Roadmap to a compiler

Detailed in `docs/HANDOVER.md` §3. In brief: **M0** commit to the target language (J) and walk §8.5 recording a semantic decision per entry; **M1** column-aware card reader, lexer, and listing; **M2** parser and diagnostics for all three divisions against the 90.04 message catalog; **M3** Data Description semantics and storage mapping; **M4** code generation for the core verb subset; **M5** the I/O runtime; **M6** acceptance — compile and run the manual's own payroll sample and reproduce its printed report output (J 90.05, PDF p. 217).
