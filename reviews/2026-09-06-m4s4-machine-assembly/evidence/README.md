# The evidence directory

These nine files are the working documents M4 stage 4 was built from. They are
left exactly as their authors wrote them, on 2026-09-06. That means they carry
absolute scratch-directory paths, agent-to-agent phrasing, and the pre-branch
line numbers the code held at the time. Nothing here was tidied for a reader.
The record cites them for what they said when the work was done.

Two kinds of document sit here.

## The seven reader reports

Seven agents read the repository and the manuals before any handler was
written. Each answered one question and wrote one report.

| File | What it holds |
|---|---|
| `s4-emulator.md` | The CPU core: what `lib/src/emulator/` already provides, what it does not, and what a machine assembly above it has to add. |
| `s4-loader.md` | The loader: what `loadDeck` returns, and which of its fields a run would read. |
| `s4-codegen-calls.md` | Every `SYS)` and `IOC)` reference the code generator can emit, traced back to the call site in `lib/src/codegen/procedure.dart` that emits it. |
| `s4-decisions.md` | Every decision record in `docs/design/decisions.md` that binds a runtime handler, quoted and indexed by entry number. |
| `s4-contracts-a.md` | The manual contract of the cells and flags SYS)128 to 134 and the scaling, exponent and comparison routines SYS)155 to 173, entry by entry, with a quality grade. |
| `s4-contracts-b1.md` | The same for the MOVPAK entries and members SYS)179 to 218. Line 87 states the grading key the record quotes. |
| `s4-contracts-b2.md` | The same for SYS)219 to 258 and SYS)267 to 282. |

The grade on each entry says how much of the algorithm the manual prints:
`FULL`, `PARTIAL` or `NAME-ONLY`. Item 1 of the record uses those grades to
price the wider handler set it did not build.

## The two design passes

Two further agents settled the algorithms before a handler was written. Both
passes were read-only: neither changed a file in the repository.

| File | What it holds |
|---|---|
| `design-edited-fields.md` | The edited-field renderer: the control-word encoding, the derived character length, the suppression rule, the floating dollar, and the sign conventions. It became RT-5 of `docs/design/runtime.md`. |
| `design-conversions.md` | The non-edited MOVPAK members: the pointer cells, the external-decimal convert, the character movers, and the edited-source reader. It became RT-4. Its section G.8 is where defect 4 of the record was first written down. |

## What is not here

There is no `crops/` directory beside this one. Stage 4 puts no question to a
page scan, so the record has no image to embed. Every measurement it cites
comes from a file in the repository or from a compiler run, not from ink.
