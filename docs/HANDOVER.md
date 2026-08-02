# Handover — COMTRAN project state

*Updated 2026-08-02. Audience: the next agent (or Jack) picking this repository up. Project history lives in git and in `docs/research-2026-08-01-interrupted.md`; this file holds only what the next stretch of work needs.*

## Where things stand

The language-recovery phase is **done**: `docs/comtran-language-definition.md` is a complete, fully cited, adversarially verified definition of COMTRAN, with its §8.5 ambiguity catalog and Open Questions list current (8 of 74 resolved, 10 narrowed; the rest are implementation decisions or genuinely unrecoverable). The manual conversions in `comtran-manuals/` are read-only ground truth. **There is no compiler code yet.** See `README.md` for orientation.

## Rules that bind future work

- **J28-6169 outranks F28-8043** wherever they diverge. Correct the definition only against the manuals or their page scans — never against COBOL knowledge or modern expectation. External period evidence is admissible for what the manuals delegate, always labeled `(external: …)`.
- §8.5 and Open Questions are living lists: annotate entries in place with evidence and date; never delete.
- The definition stays design-free. Compiler design goes in new documents (suggested: `docs/design/`).
- Conversions stay read-only. One erratum candidate awaits Jack's explicit authorization before touching them: the 90.05 transcription renders the *CTEND card's date as `10/18/61` where the card prints `101861` (recorded in §8.5.8).
- Cite as `(F p. N)` / `(J xx.xx.xx)` / `(J 90.05 listing, PDF p. NNN)`. The page scans (`comtran-manuals/*/images/page-NNN.png`) are ground truth for any disputed reading.

## Residual caveats (honest confidence)

- Every §8.5 "Resolution" is a labeled judgment call — a default to design against, not a fact.
- Per-message severity values (§8.4) are unrecoverable; assigning them is our design decision (Open Question 65).
- Of the five collating specials, four names are period-confirmed; "lozenge" remains inference (§8.5.8). Q26/Q28 residuals are annotated in place.
- Prose-claim citations beyond the verified sample, and the original build's ~120 correction edits, never got a further independent pass; risk is low but nonzero.

## The mission: the compiler — roadmap

**First concrete task (before or alongside M0): re-key the 90.05 sample deck.** Type the payroll program out of the 90.05 transcription (source listing, `comtran-manuals/J28-6169/90.05-sample-program.md`, PDF pp. 192–197) into a clean card-image file under `tests/` — program lines only, faithful column layout, checked against the page scans. It is the only surviving COMTRAN program with known-correct output (the printed report, PDF p. 217), so it makes every milestone below immediately testable. No design decisions involved.

- **M0 — Commitments** (`docs/design/decisions.md`). Target language: **J**, with F-only features documented-but-unimplemented (the definition's recommendation). Walk §8.5 end to end, one recorded decision per entry; §8.4's diagnostic-implied rules serve as the conformance list. Jack's calls, up front: implementation language; backend strategy (emit C / LLVM / interpreter-first); fidelity level (recommended: behavioral decimal-and-BCD semantics, bit-faithful only where the definition makes machine behavior observable — collating, truncation/rounding, overflow, DO non-reentrancy); character-set representation and both §1.1 collating sequences; how tape files, labels, and PATTERN map onto modern files.
- **M1 — Card reader, lexer, listing.** Column model (serials 1–6, procedure-name margin 7–12, text 13–72, continuation), reserved words (F App. 2 + J key-word lists), compound names, literals; first observable output is the compilation listing. Test input: the re-keyed deck.
- **M2 — Parser + diagnostics** for all three divisions plus control cards; statement numbering (`n,cc`); the 90.04 message catalog as the diagnostic vocabulary.
- **M3 — Data Description semantics**: levels, pictorials, type codes, storage mapping (definition §3, corroborated by the 90.05 layout evidence), REDEF, QUANTITY.
- **M4 — Core-verb code generation**: MOVE/SET/IF/WHEN/GO TO/DO — DO per the verified Q40 return-cell semantics (including non-reentrancy), arithmetic per §4.3 and the Q26–28 annotations.
- **M5 — I/O runtime**: OPEN/CLOSE/GET/FILE, buffering and locate mode, AT END/ON ERROR per Q41, labels per Q45/Q46 at the M0-chosen fidelity, DISPLAY and report output.
- **M6 — Acceptance**: compile and run the 90.05 payroll sample end to end and reproduce its printed report output (PDF p. 217); second corpus, F's payroll example with the documented F/J divergences applied (§9.8).

## Pointers

- Definition: `docs/comtran-language-definition.md` — §8.5 catalog; §8.5.8 transcription cautions; Open Questions (74 items; 12, 23, 40, 45, 46, 47, 50, 73 resolved; 26–28, 31, 41, 42, 53, 58, 70, 72 narrowed, 2026-08-01/02).
- Manuals: `comtran-manuals/{F28-8043,J28-6169}/`; conventions in `comtran-manuals/README.md`. Sample program: `comtran-manuals/J28-6169/90.05-sample-program.md`.
- Research archive (raw drafts, adversarial verdicts, scout maps of external manuals): `docs/research-2026-08-01-interrupted.md`.
- External period scans used (all bitsavers, re-downloadable): C28-6100-2 (709/7090 IOCS), 22-6528-4 (7090 reference), A22-6506-0 (705 reference), 22-6642-0 (705 pocket code card), A24-1403-5 (1401 reference), J28-6166 (9PAC Part 1).
