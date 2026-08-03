# Handover — COMTRAN project state

*Updated 2026-08-03. Audience: the next agent, or Jack. This file is the
state document for the project. It holds what the next stretch of work needs.
Update it in the same commit that closes a milestone or a task, and update
`README.md` with it. Git holds the project history.*

## Glossary of the codenames

Every document in this repository uses these prefixes. This table is their one
home.

| Prefix | What it names | Where the series lives |
|---|---|---|
| `M0` to `M6` | A compiler milestone | The roadmap below |
| `T1` to `T4` | A parallel tooling task | The tooling track below |
| `Dn` and `Dn.n` | A binding design decision record | `docs/design/decisions.md` |
| `M1-n`, `M2-n` | A design entry inside one milestone's note | `docs/design/m1-front-end.md`, `docs/design/m2-parser.md` |
| `ED-n` | An emulator design decision | `docs/design/emulator.md` |
| `C1` to `C5` | A diagnostic severity class from D9.2 | `docs/design/severity-notes.md` |
| `Qn` | An Open Question number | The Open Questions list in `docs/comtran-language-definition.md` |
| `§n` and `§8.5.n` | A section of the language definition | `docs/comtran-language-definition.md` |

Terms that appear without expansion:

| Term | What it means |
|---|---|
| `Set H` | The IBM character set whose card codes COMTRAN uses (F p. 12) |
| `n,cc` | A statement number: the statement `n`, then the clause digits `cc` (J 02.02.01) |
| `IOCS` | The 709/7090 Input/Output Control System (J 02.07.01) |
| `SYS)`, `IOC)` | Name prefixes of the runtime library entry points that generated code calls (J 90.02) |
| `MOVPAK` | The runtime move-and-convert subroutine package (J 90.02.10) |
| `90.05` | J28-6169 Appendix 90.05, the compiled sample program |

## Where things stand

| Item | State | Where |
|---|---|---|
| Language definition | Complete and verified | `docs/comtran-language-definition.md` |
| M0 design decisions (84 records) | Locked 2026-08-02 | `docs/design/decisions.md` |
| Punch-level deck format | Frozen | `docs/design/deck-format.md` |
| 90.05 canon deck (293 cards) | Authoritative; its mirror is CI-slaved | `tests/90.05-payroll.ctdeck` |
| M1 front end | Done 2026-08-03 | `lib/src/lexer/`, `lib/src/listing/` |
| M2 stage 1 — AST and fixed-form parsers | Merged 2026-08-03 (PR #15) | `lib/src/ast/`, `lib/src/parser/` |
| M2 stage 2 — procedure division | Merged 2026-08-03 (PR #17) | `lib/src/parser/procedure_parser.dart` |
| M2 stage 3 — job stream | **Open. This is the next task.** | — |
| M3 to M6 | Not started | — |
| M4 emulator core (early, 43 harvested opcodes) | Draft (PR #10) | `lib/src/emulator/` |
| T1 deck CLI (`deckconv`) | Done 2026-08-03 | `bin/deckconv.dart` |
| T2 VS Code punchcard editor | Done 2026-08-03 (PR #9) | `tools/vscode-punchcard/` |
| T3 MCP server and skill | Done 2026-08-03 (PR #8) | `bin/deckmcp.dart`, `.claude/skills/comtran-decks/` |
| T4 deck syntax highlighting | Done 2026-08-03 (PR #14) | `tools/vscode-punchcard/` |

One M0 deferral is open: **D4.1**, the MOVPAK round-step emission rule. Decide
it no later than M4.

Test baseline at this state: 401 Dart tests pass, and 73 extension tests pass.
`dart run comtran:comtranc tests/90.05-payroll.ctdeck` compiles the manual's
own payroll sample through the front end and the parser. It prints the
listing, numbered 1,00 to 229,00 exactly as the 1962 compile numbered it, with
zero diagnostics. A golden test guards that listing byte for byte.

## The next task — M2 stage 3, the job stream

`docs/design/m2-parser.md` M2-15 specifies it. Four parts:

- Split a deck at its `*FINISH` cards, and run the front end and the parser
  once per job.
- Print one listing per job. Exit on the worst severity of the whole deck.
- Scan the `$CMPLE` option list, and issue message 132.
- Add the `--pedantic` flag (D0.8). M1 records the repairs it must warn on.

Message 903 (a card after `*FINISH`) then covers the single-job tail only.

## Rules that bind future work

The definition's
[Sources and authority](comtran-language-definition.md#sources-and-authority)
section is the one home for three facts: the F/J authority rule, the fidelity
conventions, and the citation style. Read them there. This list holds only what
binds work outside the definition.

- **J28-6169 outranks F28-8043** wherever they diverge.
- §8.5 and Open Questions are living lists. Annotate an entry in place with the
  evidence and the date. Never delete an entry.
- The definition stays design-free. Compiler design goes in `docs/design/`.
- The conversions stay read-only. Three erratum candidates wait for Jack's
  explicit authorization:
  1. The 90.05 transcription renders the `*CTEND` card's date as `10/18/61`.
     The card prints `101861` (recorded in §8.5.8).
  2. Statement 43,00's data name is punched `CNTRLCHARSECLIN` — 15 characters,
     with level 02 abutting at columns 23–24 — not `CNTRLCHARSECLINE`.
     Statement 203 prints `1.5 -20)`, not `1.5 - 20)`. Both readings come from
     the page scans, measured during the deck re-keying.
     `tests/90.05-payroll-deck-notes.md` holds the details and the minor
     spacing normalizations.
  3. On the transcription of PDF p. 197, the statement numbers of 218,00–221,00
     and 228,00 sit one line low. A printer half-line stagger causes this.
     `docs/design/m1-front-end.md` M1-14 records the scan-correct grouping,
     and the M1 tests assert it.
- The page scans (`comtran-manuals/*/images/page-NNN.png`) are ground truth for
  any disputed reading.
- For any claim about card columns, measure the page scan. Never trust the
  indentation of a transcription.

## Residual caveats (honest confidence)

- Every §8.5 "Resolution" is a labeled judgment call. It is a default to design
  against, not a fact.
- Per-message severity values (§8.4) are unrecoverable. Every value we assign
  is our own design decision (Open Question 65). See
  `docs/design/severity-notes.md`.
- Four of the five collating specials carry period-confirmed names. "Lozenge"
  remains an inference (§8.5.8). The Q26 and Q28 residuals are annotated in
  place.
- Two things never got a further independent pass: the prose-claim citations
  beyond the verified sample, and the original build's approximately 120
  correction edits. The risk is low but not zero.

## The mission: the compiler — roadmap

The first concrete task is done. The 90.05 sample deck is re-keyed as
`tests/90.05-payroll.deck` (2026-08-02): 293 cards, program lines only, with
every column layout measured from the page scans line by line.
`tests/90.05-payroll-deck-notes.md` holds the provenance, the layout facts, the
reconstruction decisions, and the residual one-space caveats. This deck is the
only surviving COMTRAN program with known-correct output — the printed report,
PDF p. 217. It makes every milestone below testable at once.

- **M0 — Commitments** (`docs/design/decisions.md`) — **DONE 2026-08-02.** The
  D0 slate is locked: target language J; implementation in Dart; backend = real
  7090 object code on our own emulator, with a high-level-emulated SYS)/IOC)
  runtime; evidence-bounded bit-faithfulness; punch-level canonical decks with
  generated text mirrors; the 1962 listing diff as the codegen oracle. D1–D9
  record the §8.5 walk and the §8.4 conformance and severity decisions, each one
  drafted, adversarially verified, and repaired. Jack's own calls are recorded in
  place: PATTERN (bind the rules now, adopt the syntax at M5), `deck.name` blanks
  (accept silently; `--pedantic` warns), and table capacities (hard-enforce the
  printed numbers).
- **M1 — Card reader, lexer, listing — DONE 2026-08-03.** The deck splitter
  (control cards, division headers), the free-form procedure scanner (sentences,
  labels, literals, the D9.10 character gate), the fixed-form data and
  environment scanners (entry and specification assembly by column 72, name
  compression, field checks), the tagged reserved-word tables (D1.5), statement
  numbering (one number per sentence, entry, or specification, continuous), and
  the listing (measured 1962 geometry; diagnostics as a statement-number-
  referenced block). The 90.05 deck scans clean: 172 + 14 + 43 statements, zero
  diagnostics, golden listing committed. M1's own decisions:
  `docs/design/m1-front-end.md`.
- **M2 — Parser and diagnostics** for all three divisions plus the control
  cards, with statement numbers of the full `n,cc` form and the 90.04 message
  catalog as the diagnostic vocabulary. **Stages 1 and 2 are merged. Stage 3,
  the job stream, is open.** M2's own decisions:
  `docs/design/m2-parser.md`.
- **M3 — Data Description semantics**: levels, pictorials, type codes, storage
  mapping (definition §3, corroborated by the 90.05 layout evidence), REDEF, and
  QUANTITY.
- **M4 — Core-verb code generation**: MOVE, SET, IF, WHEN, GO TO, and DO. DO
  follows the verified Q40 return-cell semantics, non-reentrancy included.
  Arithmetic follows §4.3 and the Q26–Q28 annotations. The emulator core
  (`docs/design/emulator.md`) hardens here.
- **M5 — I/O runtime**: OPEN, CLOSE, GET, and FILE; buffering and locate mode;
  AT END and ON ERROR per Q41; labels per Q45 and Q46 at the M0-chosen fidelity;
  DISPLAY and report output.
- **M6 — Acceptance**: compile and run the 90.05 payroll sample end to end, and
  reproduce its printed report output (PDF p. 217). Then take a second corpus —
  F's payroll example with the documented F/J divergences applied (§9.8).

## Parallel tooling track

The tooling track shares the compiler's card-image core. It blocks nothing in
M2 to M6.

- **T1 — Deck CLI** (`deckconv`) — **DONE 2026-08-03.** It converts canon to
  text mirror and back, regenerates mirrors, and checks freshness. It is wired
  as the pre-commit hook (`.githooks/`), the CI freshness step, and the git
  textconv driver. `docs/design/deck-format.md` holds the setup.
- **T2 — VS Code punchcard editor** — **DONE 2026-08-03** (PR #9). A custom
  binary editor for `*.ctdeck` in `tools/vscode-punchcard/`: punch grid,
  interpreted Set H row, field rulers, and click- or type-to-punch editing.
  To install it, package the `.vsix` and run
  `code --profile <name> --install-extension`. The profile matters.
- **T3 — MCP server and skill** — **DONE 2026-08-03** (PR #8).
  `bin/deckmcp.dart` serves five deck tools on the official Dart MCP SDK. The
  `.claude/skills/comtran-decks` skill documents the deck workflow.
- **T4 — Deck syntax highlighting** — **DONE 2026-08-03** (PR #14). Both deck
  views color the card fields from one shared column table
  (`tools/vscode-punchcard/src/columns.ts`).
  - A `comtran-deck` language contribution colors `.deck` mirrors from a
    **generated** TextMate grammar (`npm run grammar`; a freshness test guards
    the committed file): column fields, literals, the period-blank terminator
    with its commentary scoped as comment, `!` punch lines, and header and
    control cards. Begin and end regions opened by the header lines track the
    division context, so no semantic-token provider was needed.
  - The punchcard editor's card-list pane colors the same fields. It classifies
    every card with the compiler's deck-splitting rules. The field ruler and the
    status line follow the current card's division.
  - Known limit: a literal that continues across cards highlights per line.

## Pointers

- Definition: `docs/comtran-language-definition.md`. §8.3 catalogs the F/J
  divergences and §8.5 the ambiguities. §8.5.8 holds the transcription cautions.
  The Open Questions list at the end of that file is the only place that states
  its own item count and the resolved and narrowed status of each item. Read the
  count there; no other document repeats it.
- Manuals: `comtran-manuals/{F28-8043,J28-6169}/`. `comtran-manuals/README.md`
  holds the conventions. The sample program is
  `comtran-manuals/J28-6169/90.05-sample-program.md`.
- Archive, provenance only: `docs/research-2026-08-01-interrupted.md` holds raw,
  unverified agent output from the research passes. The definition supersedes it.
  Do not read it for current work.
- External period scans used, all from bitsavers and all re-downloadable:
  C28-6100-2 (709/7090 IOCS), 22-6528-4 (7090 reference), A22-6506-0 (705
  reference), 22-6642-0 (705 pocket code card), A24-1403-5 (1401 reference), and
  J28-6166 (9PAC Part 1).
