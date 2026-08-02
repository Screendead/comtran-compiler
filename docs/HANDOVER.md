# Handover — COMTRAN project state

*Updated 2026-08-02. Audience: the next agent (or Jack) picking this repository up. Project history lives in git and in `docs/research-2026-08-01-interrupted.md`; this file holds only what the next stretch of work needs.*

## Where things stand

The language-recovery phase is **done**: `docs/comtran-language-definition.md` is a complete, fully cited, adversarially verified definition of COMTRAN, with its §8.5 ambiguity catalog and Open Questions list current (8 of 74 resolved, 10 narrowed; the rest are implementation decisions or genuinely unrecoverable). The manual conversions in `comtran-manuals/` are read-only ground truth. **M0 is recorded**: `docs/design/decisions.md` holds the locked D0 slate and the verified D1–D9 walk (84 records; five marked OPEN for Jack). The Dart package (`comtran`) is scaffolded with CI; **no compiler passes exist yet**. See `README.md` for orientation.

## Rules that bind future work

- **J28-6169 outranks F28-8043** wherever they diverge. Correct the definition only against the manuals or their page scans — never against COBOL knowledge or modern expectation. External period evidence is admissible for what the manuals delegate, always labeled `(external: …)`.
- §8.5 and Open Questions are living lists: annotate entries in place with evidence and date; never delete.
- The definition stays design-free. Compiler design goes in new documents (suggested: `docs/design/`).
- Conversions stay read-only. Erratum candidates awaiting Jack's explicit authorization before touching them: (1) the 90.05 transcription renders the *CTEND card's date as `10/18/61` where the card prints `101861` (recorded in §8.5.8); (2) statement 43,00's data name is punched `CNTRLCHARSECLIN` (15 chars, level 02 abutting at cols 23–24), not `CNTRLCHARSECLINE`, and statement 203 prints `1.5 -20)` not `1.5 - 20)` — both scan-verified during the deck re-keying; details and minor spacing normalizations in `tests/90.05-payroll-deck-notes.md`.
- Cite as `(F p. N)` / `(J xx.xx.xx)` / `(J 90.05 listing, PDF p. NNN)`. The page scans (`comtran-manuals/*/images/page-NNN.png`) are ground truth for any disputed reading.

## Residual caveats (honest confidence)

- Every §8.5 "Resolution" is a labeled judgment call — a default to design against, not a fact.
- Per-message severity values (§8.4) are unrecoverable; assigning them is our design decision (Open Question 65).
- Of the five collating specials, four names are period-confirmed; "lozenge" remains inference (§8.5.8). Q26/Q28 residuals are annotated in place.
- Prose-claim citations beyond the verified sample, and the original build's ~120 correction edits, never got a further independent pass; risk is low but nonzero.

## The mission: the compiler — roadmap

**First concrete task — DONE (2026-08-02): the 90.05 sample deck is re-keyed** as `tests/90.05-payroll.deck` (293 cards, program lines only, column layout measured from the page scans line by line; provenance, layout facts, reconstruction decisions, and residual ±1-space caveats in `tests/90.05-payroll-deck-notes.md`). It is the only surviving COMTRAN program with known-correct output (the printed report, PDF p. 217), so it makes every milestone below immediately testable.

- **M0 — Commitments** (`docs/design/decisions.md`) — **DONE 2026-08-02, five OPEN items pending Jack.** The D0 slate is locked: target language J; implementation in Dart; backend = real 7090 object code on our own emulator with a high-level-emulated SYS)/IOC) runtime; evidence-bounded bit-faithfulness; punch-level canonical decks with generated text mirrors; the 1962 listing diff as the codegen oracle. The §8.5 walk and §8.4 conformance/severity decisions are recorded as D1–D9 (drafted, adversarially verified, repaired). OPEN for Jack: D4.1 (MOVPAK round-step emission rule), D6.1/D9.12 (PATTERN reconstruction vs deferral), D7.11 (deck.name-blanks default), D9.7 (table-capacity policy).
- **M1 — Card reader, lexer, listing.** Column model (serials 1–6, procedure-name margin 7–12, text 13–72, continuation), reserved words (F App. 2 + J key-word lists), compound names, literals; first observable output is the compilation listing. Test input: the re-keyed deck. **Exit criteria (D0.5):** the punch-level card-image format is frozen; the T1 converter round-trips it losslessly against the text form; the 90.05 canon file is generated and becomes authoritative, with the text deck re-created as a CI-slaved mirror.
- **M2 — Parser + diagnostics** for all three divisions plus control cards; statement numbering (`n,cc`); the 90.04 message catalog as the diagnostic vocabulary.
- **M3 — Data Description semantics**: levels, pictorials, type codes, storage mapping (definition §3, corroborated by the 90.05 layout evidence), REDEF, QUANTITY.
- **M4 — Core-verb code generation**: MOVE/SET/IF/WHEN/GO TO/DO — DO per the verified Q40 return-cell semantics (including non-reentrancy), arithmetic per §4.3 and the Q26–28 annotations.
- **M5 — I/O runtime**: OPEN/CLOSE/GET/FILE, buffering and locate mode, AT END/ON ERROR per Q41, labels per Q45/Q46 at the M0-chosen fidelity, DISPLAY and report output.
- **M6 — Acceptance**: compile and run the 90.05 payroll sample end to end and reproduce its printed report output (PDF p. 217); second corpus, F's payroll example with the documented F/J divergences applied (§9.8).

Parallel tooling track (shares the compiler's card-image core; blocks nothing in M2–M6):

- **T1 — Deck CLI** (`deckconv`): convert canon ↔ text mirror, validate, diff, regenerate mirrors; doubles as the pre-commit hook, CI freshness check, and git textconv driver. Lands with M1 (it is M1's exit criterion).
- **T2 — VS Code punchcard editor**: webview custom editor over canon files — punch holes per card code, interpreted row, field rulers per division form. Startable any time after the M1 format freeze.
- **T3 — MCP server + skill**: structured read/write of canon decks for agents, wrapping the same core as T1/T2.

## Pointers

- Definition: `docs/comtran-language-definition.md` — §8.5 catalog; §8.5.8 transcription cautions; Open Questions (74 items; 12, 23, 40, 45, 46, 47, 50, 73 resolved; 26–28, 31, 41, 42, 53, 58, 70, 72 narrowed, 2026-08-01/02).
- Manuals: `comtran-manuals/{F28-8043,J28-6169}/`; conventions in `comtran-manuals/README.md`. Sample program: `comtran-manuals/J28-6169/90.05-sample-program.md`.
- Research archive (raw drafts, adversarial verdicts, scout maps of external manuals): `docs/research-2026-08-01-interrupted.md`.
- External period scans used (all bitsavers, re-downloadable): C28-6100-2 (709/7090 IOCS), 22-6528-4 (7090 reference), A22-6506-0 (705 reference), 22-6642-0 (705 pocket code card), A24-1403-5 (1401 reference), J28-6166 (9PAC Part 1).
