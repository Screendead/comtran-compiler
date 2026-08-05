# Handover — COMTRAN project state

*Updated 2026-08-04. Audience: the next agent, or Jack. This file is the
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
| `Set H` | The IBM character set whose card codes COMTRAN uses ([F p. 12]) |
| `n,cc` | A statement number: the statement `n`, then the clause digits `cc` ([J 02.02.01]) |
| `IOCS` | The 709/7090 Input/Output Control System ([J 02.07.01]) |
| `SYS)`, `IOC)` | Name prefixes of the runtime library entry points that generated code calls ([J 90.02]) |
| `MOVPAK` | The runtime move-and-convert subroutine package ([J 90.02.10]) |
| `90.05` | J28-6169 Appendix 90.05, the compiled sample program |

## Where things stand

| Item | State | Where |
|---|---|---|
| Language definition | Complete and verified | `docs/comtran-language-definition.md` |
| M0 design decisions (84 records) | Locked 2026-08-02 | `docs/design/decisions.md` |
| Punch-level deck format | Frozen | `docs/design/deck-format.md` |
| 90.05 canon deck (293 cards) | Authoritative; its mirror is CI-slaved | `test/fixtures/90.05-payroll.ctd` |
| M1 front end | Done 2026-08-03 | `lib/src/lexer/`, `lib/src/listing/` |
| M2 stage 1 — AST and fixed-form parsers | Merged 2026-08-03 (PR #15) | `lib/src/ast/`, `lib/src/parser/` |
| M2 stage 2 — procedure division | Merged 2026-08-03 (PR #17) | `lib/src/parser/procedure_parser.dart` |
| M2 stage 3 — job stream and --pedantic | Merged 2026-08-03 (PRs #47–#49) | `lib/src/driver/` |
| M3 — the semantic layer | **In progress.** Stages 1 and 2 built 2026-08-04; stage 3 is the next task | `docs/design/m3-data.md`, `lib/src/data/` |
| M4 to M6 | Not started | — |
| M4 emulator core (early, 43 harvested opcodes) | Draft (PR #10) | `lib/src/emulator/` |
| T1 deck CLI (`deckconv`) | Done 2026-08-03 | `bin/deckconv.dart` |
| T2 VS Code punchcard editor | Done 2026-08-03 (PR #9) | `editors/vscode-punchcard/` |
| T3 MCP server and skill | Done 2026-08-03 (PR #8) | `bin/deckmcp.dart`, `.claude/skills/comtran-decks/` |
| T4 deck syntax highlighting | Done 2026-08-03 (PR #14) | `editors/vscode-punchcard/` |

The last M0 deferral closed 2026-08-04. **D4.1** part (d), the MOVPAK
round-step emission rule, is locked by Jack's call: a SET store through a
step-list package rounds, a MOVE store truncates.

Test baseline, measured 2026-08-05: 955 Dart tests pass, and 135 extension
tests pass. Both suites must stay green; re-measure the counts, do not trust
them.
`dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctd` compiles the
manual's own payroll sample through the front end, the parser, and the
semantic layer. The job deck is the 293-card artifact plus one reconstructed
*FINISH card (D11.3); the raw artifact alone is an incomplete job and draws
message 132. The compile prints the listing, numbered 1,00 to 229,00 exactly
as the 1962 compile numbered it, with zero diagnostics. Under `--pedantic` it
draws exactly three non-historical 943 notes, the sample's own doubtful
blank-moves (D11.4 as amended). A golden test guards the default listing byte
for byte.

## The next task — M3 stage 3, the listing extension

The M3 decision walk is recorded in `docs/design/m3-data.md` (2026-08-04).
Jack's three calls are locked there: M3 is the full semantic layer in three
staged PRs (M3-1); the listing gains GN)nnn names and the LOC column with a
golden rewrite in stage 3 (M3-8); and the 1962 object listing's `*DATA`
storage section (PDF pp. 199–200) is the stage-1 acceptance oracle (M3-14).

Stage 1 landed 2026-08-04: `lib/src/data/` holds the field classifier, the
pictorial measurement, the storage allocator, the initial images, the
environment binder, and the stage-1 diagnostics, wired into the driver as
`runSemantics`. The M3-14 oracle passes — the mapper reproduces the 1962
`*DATA` storage section exactly. M3-16 records the stage-1 message choices
and the deferrals.

Stage 2 landed 2026-08-04: the dictionary, procedure and environment name
resolution, CALL synonyms, reference legality, CORRESPONDING pairing, the
I/O verb binding map, the subscript and transfer checks, and the capacity
counters. The checklist's M3 rows are enforced — msgs 17 and 205 stay
reserved with notes — and ten non-historical ids were added (936 to 945).
M3-17 to M3-21 record the site readings. The `--no-table-limits` switch
lifts the D9.7 counters.

The next task is stage 3: the listing extension — GN)nnn names and the LOC
column, with the golden rewrite (M3-8). Two standing items to carry in:

- D11.4 lists the --pedantic sites deferred beyond M3 (D5.1, D5.7, D6.1
  among them); each lands with its owning milestone.
- The emit-flag plumbing landed 2026-08-05: five `--emit-<stage>[=<path>]`
  flags on `comtranc` with bundleable one-letter forms (`-cpsSl`, `-A`
  for all) and default dump paths, three committed reconstruction
  goldens, and the storage-value tie to the M3-14 fixture. The surface
  is recorded in `docs/design/emit-stages.md` ("The implemented
  surface"). M4 adds its own stages under the same conventions.

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
     `test/fixtures/90.05-payroll-deck-notes.md` holds the details and the minor
     spacing normalizations.
  3. On the transcription of PDF p. 197, the statement numbers of 218,00–221,00
     and 228,00 sit one line low. A printer half-line stagger causes this.
     `docs/design/m1-front-end.md` M1-14 records the scan-correct grouping,
     and the M1 tests assert it.
  A fourth candidate — the [J 02.05.05] chart's Edited-row overpunch glyphs,
  transcribed `8 or 9 or 8̅ or 9̅` where the scan marks all four — was
  authorized and corrected 2026-08-04. §8.5.8-b records the reading and the
  polarity order.
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
`test/fixtures/90.05-payroll.ct` (2026-08-02): 293 cards, program lines only, with
every column layout measured from the page scans line by line.
`test/fixtures/90.05-payroll-deck-notes.md` holds the provenance, the layout facts, the
reconstruction decisions, and the residual one-space caveats. This deck is the
only surviving COMTRAN program with known-correct output — the printed report,
PDF p. 217. It makes every milestone below testable at once.

- **M0 — Commitments** (`docs/design/decisions.md`) — **DONE 2026-08-02.** The
  D0 slate is locked:
  - The target language is J.
  - The implementation language is Dart.
  - The backend emits real 7090 object code, and our own emulator runs it. The
    SYS) and IOC) runtime is emulated at a high level.
  - Bit-faithfulness is bounded by the evidence.
  - Decks are canonical at punch level, with generated text mirrors.
  - The codegen oracle is the diff against the 1962 listing.

  D1–D9 record the §8.5 walk and the §8.4 conformance and severity decisions.
  Each record was drafted, adversarially verified, and repaired. Jack's own
  calls are recorded in place: PATTERN (bind the rules now, adopt the syntax at
  M5), `deck.name` blanks (accept silently; `--pedantic` warns), and table
  capacities (hard-enforce the printed numbers).
- **M1 — Card reader, lexer, listing — DONE 2026-08-03.** It delivers:
  - the deck splitter — control cards and division headers;
  - the free-form procedure scanner — sentences, labels, literals, and the
    D9.10 character gate;
  - the fixed-form data and environment scanners — entry and specification
    assembly by column 72, name compression, and field checks;
  - the tagged reserved-word tables (D1.5);
  - statement numbering — one number per sentence, entry, or specification,
    continuous across the divisions;
  - the listing — measured 1962 geometry, with the diagnostics as a
    statement-number-referenced block.

  The 90.05 deck scans clean: 172 + 14 + 43 statements, zero diagnostics, and
  the golden listing is committed. M1's own decisions:
  `docs/design/m1-front-end.md`.
- **M2 — Parser and diagnostics — DONE 2026-08-03.** All three divisions plus
  the control cards, with statement numbers of the full `n,cc` form and the
  90.04 message catalog as the diagnostic vocabulary. Stage 3 added the job
  stream — the `lib/src/driver/` splitter and job loop, one listing per job,
  message 132, the D11 records — and the `--pedantic` flag with its eleven
  M2 sites (D11.4). M2's own decisions: `docs/design/m2-parser.md` and the
  D11 section of `docs/design/decisions.md`.
- **M3 — Data Description semantics**: levels, pictorials, type codes, storage
  mapping (definition §3, corroborated by the 90.05 layout evidence), REDEF, and
  QUANTITY.
- **M4 — Core-verb code generation**: MOVE, SET, IF, WHEN, GO TO, and DO. DO
  follows the verified Q40 return-cell semantics, non-reentrancy included.
  Arithmetic follows §4.3 and the Q26–Q28 annotations. The emulator core
  (`docs/design/emulator.md`) hardens here. The msg 942 dictionary counter
  takes the compiler-generated names here too: [J 90.01.05] item a) counts
  them with the programmer names, and M3 counts programmer names alone
  (M3-21).
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
  binary editor for `*.ctd` in `editors/vscode-punchcard/`: punch grid,
  interpreted Set H row, field rulers, and click- or type-to-punch editing.
  To install it, package the `.vsix` and run
  `code --profile <name> --install-extension`. The profile matters.
- **T3 — MCP server and skill** — **DONE 2026-08-03** (PR #8).
  `bin/deckmcp.dart` serves five deck tools on the official Dart MCP SDK. The
  `.claude/skills/comtran-decks` skill documents the deck workflow.
- **T4 — Deck syntax highlighting** — **DONE 2026-08-03** (PR #14). Both deck
  views color the card fields from one shared column table
  (`editors/vscode-punchcard/src/columns.ts`).
  - A `comtran-deck` language contribution colors `.ct` mirrors from a
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
- Archive provenance: commit 8f619e5 preserves the raw research output
  (`docs/research-2026-08-01-interrupted.md`). The language definition
  supersedes it.
- External period scans used, all from bitsavers and all re-downloadable:
  C28-6100-2 (709/7090 IOCS), 22-6528-4 (7090 reference), A22-6506-0 (705
  reference), 22-6642-0 (705 pocket code card), A24-1403-5 (1401 reference), and
  J28-6166 (9PAC Part 1).

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 12]: ../comtran-manuals/F28-8043/02-language-structure.md#underlying-principles
[J 02.02.01]: ../comtran-manuals/J28-6169/02-compiler.md#b-finish-card
[J 02.05.05]: ../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.07.01]: ../comtran-manuals/J28-6169/02-compiler.md#i-cond-environment-card
[J 90.01.05]: ../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02]: ../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.10]: ../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
