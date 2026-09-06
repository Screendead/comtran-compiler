# Design records — index

*This directory holds the design of the compiler. The language itself lives in
`docs/comtran-language-definition.md`, which stays design-free. Project state
and the roadmap live in `docs/HANDOVER.md`.*

## Where to start

1. Read `decisions.md`. It is the slate every other file in this directory
   builds on. Start at its Contents table, then read D0, then the records the
   task at hand cites.
2. Read the file for the component you work on, from the table below.
3. Read `docs/HANDOVER.md` for the current milestone and the next task.

`docs/HANDOVER.md` holds the glossary of the codename prefixes (`D`, `M`, `T`,
`Q`, `C`, `ED`). Look there first for a prefix you do not recognize.

## The files

| File | What it governs |
|---|---|
| `decisions.md` | The D-number decision slate. Every record binds the compiler, the emulator, or the runtime. It carries an index and a status per record. |
| `deck-format.md` | The card-deck file formats: the binary canon file, its text mirror, the `deckconv` workflow, and the one-time git settings a fresh clone needs. Frozen at M1 under D0.5 and D0.6. |
| `m1-front-end.md` | The M1 front end: `lib/src/lexer/` and `lib/src/listing/`. Holds the `M1-n` entries, the choices M1 had to make where a source is silent. |
| `m2-parser.md` | The M2 parser: `lib/src/parser/` and `lib/src/ast/`. Holds the `M2-n` entries, in the same shape as the M1 note. |
| `emulator.md` | The 7090 CPU core in `lib/src/emulator/`. Holds the `ED-n` entries. Draft until M4 connects codegen, the loader, and the runtime to it. |
| `runtime.md` | The machine assembly and the SYS)/IOC) handlers in `lib/src/runtime/`. Holds the `RT-n` entries: the addresses, the dispatch rule, the run loop, and each handler's contract. |
| `emit-stages.md` | The requirement that every compilation stage is dumpable behind a flag, with attested stages oracled against their evidence. Recorded 2026-08-04; M4 adopts or amends it. |
| `severity-notes.md` | The severity assigned to every 90.04 message, under D9.2. Every value is our design decision, not recovered history. |
| `web-copy.md` | The register and the copy rules for the public website (the W track). Proposed 2026-08-10; Jack has approved the register and the tiebreak, not the rule list. |
| `message-checklist.tsv` | The per-message conformance checklist required by D9.3: one row per message id, with its class, disposition, component, B.2 rule, and test. |

## Rules for this directory

- A design record holds design only. It adds no language claims. Where a source
  leaves a gap, the record closes it and says so.
- Amend a record by an explicit edit to it, never silently. Cite the manual
  evidence in the amendment.
- Mark any unattested choice as a design decision, and never present it as
  historical fact.
- Add a row to the table above when you add a file here.
