# Handover — COMTRAN project state

*Updated 2026-08-02. Audience: the next agent (or Jack) picking this repository up. Project history lives in git and in `docs/research-2026-08-01-interrupted.md`; this file holds only what the next stretch of work needs.*

## Where things stand

The language-recovery phase is **done**: `docs/comtran-language-definition.md` is a complete, fully cited, adversarially verified definition of COMTRAN, with its §8.5 ambiguity catalog and Open Questions list current (8 of 74 resolved, 10 narrowed; the rest are implementation decisions or genuinely unrecoverable). The manual conversions in `comtran-manuals/` are read-only ground truth. **M0 is done**: `docs/design/decisions.md` holds the locked D0 slate, the verified D1–D9 walk (84 records), and Jack's calls on the items that needed them (one deliberate deferral: D4.1, decide by M4). The punch-level deck format is frozen (`docs/design/deck-format.md`), the T1 converter (`deckconv`) is built, and the 90.05 canon file (`tests/90.05-payroll.ctdeck`) is authoritative with its text mirror CI-slaved. **M1 is done (2026-08-03)**: the card reader, the three division scanners, statement numbering, and the compilation listing exist (`lib/src/lexer/`, `lib/src/listing/`; M1-specific decisions in `docs/design/m1-front-end.md`); `dart run comtran:comtranc tests/90.05-payroll.ctdeck` prints the listing, numbered 1,00–229,00 exactly as the 1962 compile numbered it, golden-tested. Parallel tracks delivered on open PRs: the T3 MCP server + skill (PR #8), the T2 VS Code punchcard editor (PR #9), and an early M4 7090 emulator core (43 harvested opcodes, PR #10). See `README.md` for orientation.

## Rules that bind future work

- **J28-6169 outranks F28-8043** wherever they diverge. Correct the definition only against the manuals or their page scans — never against COBOL knowledge or modern expectation. External period evidence is admissible for what the manuals delegate, always labeled `(external: …)`.
- §8.5 and Open Questions are living lists: annotate entries in place with evidence and date; never delete.
- The definition stays design-free. Compiler design goes in new documents (suggested: `docs/design/`).
- Conversions stay read-only. Erratum candidates awaiting Jack's explicit authorization before touching them: (1) the 90.05 transcription renders the *CTEND card's date as `10/18/61` where the card prints `101861` (recorded in §8.5.8); (2) statement 43,00's data name is punched `CNTRLCHARSECLIN` (15 chars, level 02 abutting at cols 23–24), not `CNTRLCHARSECLINE`, and statement 203 prints `1.5 -20)` not `1.5 - 20)` — both scan-verified during the deck re-keying; details and minor spacing normalizations in `tests/90.05-payroll-deck-notes.md`; (3) on the transcription of PDF p. 197 the statement numbers of 218,00–221,00 and 228,00 sit one line low (printer half-line stagger); the scan-correct grouping is recorded in `docs/design/m1-front-end.md` M1-14 and asserted by the M1 tests.
- Cite as `(F p. N)` / `(J xx.xx.xx)` / `(J 90.05 listing, PDF p. NNN)`. The page scans (`comtran-manuals/*/images/page-NNN.png`) are ground truth for any disputed reading.

## Residual caveats (honest confidence)

- Every §8.5 "Resolution" is a labeled judgment call — a default to design against, not a fact.
- Per-message severity values (§8.4) are unrecoverable; assigning them is our design decision (Open Question 65).
- Of the five collating specials, four names are period-confirmed; "lozenge" remains inference (§8.5.8). Q26/Q28 residuals are annotated in place.
- Prose-claim citations beyond the verified sample, and the original build's ~120 correction edits, never got a further independent pass; risk is low but nonzero.

## The mission: the compiler — roadmap

**First concrete task — DONE (2026-08-02): the 90.05 sample deck is re-keyed** as `tests/90.05-payroll.deck` (293 cards, program lines only, column layout measured from the page scans line by line; provenance, layout facts, reconstruction decisions, and residual ±1-space caveats in `tests/90.05-payroll-deck-notes.md`). It is the only surviving COMTRAN program with known-correct output (the printed report, PDF p. 217), so it makes every milestone below immediately testable.

- **M0 — Commitments** (`docs/design/decisions.md`) — **DONE 2026-08-02.** The D0 slate is locked: target language J; implementation in Dart; backend = real 7090 object code on our own emulator with a high-level-emulated SYS)/IOC) runtime; evidence-bounded bit-faithfulness; punch-level canonical decks with generated text mirrors; the 1962 listing diff as the codegen oracle. The §8.5 walk and §8.4 conformance/severity decisions are recorded as D1–D9 (drafted, adversarially verified, repaired); Jack's calls on PATTERN (bind rules now, syntax at M5), deck.name blanks (accept silently; `--pedantic` warns), and table capacities (hard-enforce the printed numbers) are recorded in place. One deliberate deferral remains: **D4.1, the MOVPAK round-step emission rule — decide no later than M4.**
- **M1 — Card reader, lexer, listing — DONE 2026-08-03.** The deck splitter (control cards, division headers), the free-form procedure scanner (sentences, labels, literals, the D9.10 character gate), the fixed-form data and environment scanners (entry/specification assembly by column 72, name compression, field checks), the tagged reserved-word tables (D1.5), statement numbering (one number per sentence/entry/specification, continuous), and the listing (measured 1962 geometry; diagnostics as a statement-number-referenced block). The 90.05 deck scans clean: 172 + 14 + 43 statements, zero diagnostics, golden listing committed. M1's own recorded decisions: `docs/design/m1-front-end.md`.
- **M2 — Parser + diagnostics** for all three divisions plus control cards; statement numbering (`n,cc`); the 90.04 message catalog as the diagnostic vocabulary.
- **M3 — Data Description semantics**: levels, pictorials, type codes, storage mapping (definition §3, corroborated by the 90.05 layout evidence), REDEF, QUANTITY.
- **M4 — Core-verb code generation**: MOVE/SET/IF/WHEN/GO TO/DO — DO per the verified Q40 return-cell semantics (including non-reentrancy), arithmetic per §4.3 and the Q26–28 annotations.
- **M5 — I/O runtime**: OPEN/CLOSE/GET/FILE, buffering and locate mode, AT END/ON ERROR per Q41, labels per Q45/Q46 at the M0-chosen fidelity, DISPLAY and report output.
- **M6 — Acceptance**: compile and run the 90.05 payroll sample end to end and reproduce its printed report output (PDF p. 217); second corpus, F's payroll example with the documented F/J divergences applied (§9.8).

Parallel tooling track (shares the compiler's card-image core; blocks nothing in M2–M6):

- **T1 — Deck CLI** (`deckconv`) — **DONE 2026-08-03**: converts canon ↔ text mirror, regenerates mirrors, checks freshness; wired as the pre-commit hook (`.githooks/`), the CI freshness step, and the git textconv driver (setup in `README.md`).
- **T2 — VS Code punchcard editor** — **DONE 2026-08-03** (merged PR #9): custom binary editor for `*.ctdeck` in `tools/vscode-punchcard/` — punch grid, interpreted Set H row, field rulers, click- and type-to-punch editing. Install: package the `.vsix` and `code --profile <name> --install-extension` it (the profile matters).
- **T3 — MCP server + skill** — **DONE 2026-08-03** (merged PR #8): `bin/deckmcp.dart` with five deck tools on the official Dart MCP SDK, plus the `.claude/skills/comtran-decks` skill.
- **T4 — Deck syntax highlighting** (requested by Jack, 2026-08-03) — **DONE 2026-08-03** (PR #14): both deck views color the card fields from one shared column table (`tools/vscode-punchcard/src/columns.ts`). (a) A `comtran-deck` language contribution for `.deck` mirrors with a **generated** TextMate grammar (`npm run grammar`; a freshness test guards the committed file) — column fields, literals, the period-blank terminator with commentary scoped as comment, `!` punch lines, header/control cards; division context is tracked with begin/end regions opened by the header lines, so no semantic-token provider was needed. (b) The punchcard editor's card-list pane colors the same fields after classifying every card with the compiler's deck-splitting rules; the field ruler and status line follow the current card's division. Known limit: a literal continuing across cards highlights per line.

## Pointers

- Definition: `docs/comtran-language-definition.md` — §8.5 catalog; §8.5.8 transcription cautions; Open Questions (75 items; 12, 23, 40, 45, 46, 47, 50, 73 resolved; 26–28, 31, 41, 42, 53, 58, 70, 72 narrowed, 2026-08-01/02; 75 — the construct-less key word THROUGH — added 2026-08-03).
- Manuals: `comtran-manuals/{F28-8043,J28-6169}/`; conventions in `comtran-manuals/README.md`. Sample program: `comtran-manuals/J28-6169/90.05-sample-program.md`.
- Research archive (raw drafts, adversarial verdicts, scout maps of external manuals): `docs/research-2026-08-01-interrupted.md`.
- External period scans used (all bitsavers, re-downloadable): C28-6100-2 (709/7090 IOCS), 22-6528-4 (7090 reference), A22-6506-0 (705 reference), 22-6642-0 (705 pocket code card), A24-1403-5 (1401 reference), J28-6166 (9PAC Part 1).
