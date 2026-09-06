# Verification notes

Claims the survey made, checked against this repository and against the
candidate repositories directly. Two of them did not survive.

## Corrected: PDF p. 217 is not a plan gap

Three agents reported that J28-6169 PDF p. 217, the sample program's printed
report output, is a period end-to-end oracle that the plan does not name, and
one called it the best finding of the survey. It is wrong.

`docs/HANDOVER.md:442` names it in the roadmap preamble:

> This deck is the only surviving COMTRAN program with known-correct output —
> the printed report, PDF p. 217. It makes every milestone below testable at
> once.

`docs/HANDOVER.md:496-498` makes it the M6 acceptance criterion:

> **M6 — Acceptance**: compile and run the 90.05 payroll sample end to end, and
> reproduce its printed report output (PDF p. 217).

It is also a named oracle in three decision records: `docs/design/decisions.md`
lines 886, 925 and 1257.

The agents read only the stage 4 scope at `docs/HANDOVER.md:88-91`, which
covers I/O-free programs and so does not reach a report. The narrow claim —
that stage 4 itself has no end-to-end behavioural oracle — is true and
uninteresting, because stage 4 is scoped to programs that produce no report.

## Corrected: the lost runtime is not an argument against adoption

Every candidate profile banked "it supplies nothing toward the lost SYS)/IOC)
runtime" as a mark against the candidate. The adversarial review is right that
this is a non-sequitur. The roughly 90 Dart handlers are written from
J28-6169 whichever CPU executes the instructions between them, so the runtime
gap costs the same under every option on the table. It is a zero on the
ledger, not a debit.

## Confirmed: Jack named this option on 2026-08-05

`docs/opportunities.md:511-517`:

> Jack named a second option on 2026-08-05: use an emulator someone else wrote,
> such as the SIMH 7090 simulator, and say plainly that it is not ours. That is
> a real change to D0.3 and it is not free. Several decision records read the
> emulator's behaviour as their own decision — D4.1 on the ACL sign path, the
> DO record on non-termination, the MOVPAK communication cells — and each would
> have to become an observation of somebody else's simulator instead. **Do not
> amend D0.3 without Jack's explicit instruction.**

## Confirmed: the CI gate has no native step

`.github/workflows/` holds three jobs. All three are `runs-on: ubuntu-latest`
(`ci.yml:18`, `pages.yml:23`, `vscode-ext.yml:28`). No macOS runner, no matrix,
no C toolchain step. `ci.yml:36` runs `dart run tool/build_web.dart`, so the
WebAssembly build is inside the gate, not beside it.

## Confirmed: the browser build forbids dart:ffi

`docs/HANDOVER.md:583-584`:

> Any later browser work inherits this finding, the M4 emulator most of all.

The embedding-cost agent compiled a file importing `dart:ffi` with
`dart compile wasm` on the repository's own SDK, 3.12.2, and got
`Error: 'dart:ffi' can't be imported when compiling to Wasm.` `dart:io`'s
`Process` is equally unavailable, so the subprocess shape fails the same way.
`cpu.dart` is not in the web closure today, so nothing breaks now; the cost is
a stated future, not a present capability.

## Confirmed: 52 period IBM diagnostic decks ship with Cornwell's simulator

`gh api repos/rcornwell/sims/contents/I7000/tests/i7090` returns 54 entries, 52
of them `.dck` files: `9a01a.dck`, `9m03a.dck`, `9s01ha.dck` and so on. These
are IBM customer-engineering diagnostics, period artifacts rather than a modern
author's reading, which is what makes them interesting under the section 9
evidence rules.

The repository's own README qualifies the result:

> ## i7090
>    * Working with exceptions.
>    * Known bugs:
>       * DFDP/DFMP     Sometimes off by +/-1 or 2 in least signifigant part of result.
>       * EAD           +n + -n should be -0 is +0
>       * Not all channel skips working for 9P01C.
>       * HTx	Not sure what problems are, does not quite work.
>       * DKx	Sometimes fails diagnostics with missing inhibit of interrupt.
>    * CTSS    works.

Both arithmetic bugs are double-precision floating point, which is outside our
43-opcode subset. The second one is a minus-zero defect, which is the class of
corner a differential test would be run to settle. It does not touch our subset,
and it is a fair warning about what a second implementation is worth.

## Confirmed: the LAS field alignment carries no ED label

`lib/src/emulator/cpu.dart:200-210` implements LAS as a plain integer
comparison:

```dart
case Op.las: // M p. 43: AC(Q,P,1-35) unsigned against C(Y)(S,1-35).
  final int y = state.read(_effectiveAddress(inst, indirectable: true));
  final int skip;
  if (state.acMagnitude > y) {
```

`acMagnitude` is 37 bits with Q at bit 36 and P at bit 35; a storage word is 36
bits with S at bit 35. So the comparison pairs P against S and positions 1-35
against positions 1-35, which is the manual's own field pairing, and lets Q
outrank the whole word. That is the natural reading. What is unrecorded is the
Q consequence: `docs/design/emulator.md:128` states the semantics in one line
and no `ED-n` label covers the ordering. The seven labels in the document are
ED-1 through ED-6 plus ED-2a, at lines 24, 39, 41, 60, 172, 186, 190, 194 and
199.

This is an observation, not a defect. LAS appears five times in the sample
object program.
