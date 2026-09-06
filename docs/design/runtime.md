# The machine assembly and the run frame

*Recorded 2026-09-06, M4 stage 4. This record holds the design of
`lib/src/runtime/`: the machine that runs a loaded object program, and
the handlers that stand in for the SYS)/IOC) library under it.
`m4-codegen.md` M4-17 charters both, `emulator.md` holds the CPU core,
and `loader.md` holds the deck the machine loads. The prefix is `RT-n`.
Every entry binds the code.*

## RT-1. The machine

`lib/src/runtime/machine.dart` holds one class. `Machine` writes a
`LoadedProgram` into a fresh `MachineState`, enters at the program's
entry point (D2.1), and runs.

### The addresses

The machine resolves every system reference to its own 15-bit code
([J 90.03.05]). `SYS)n` and `IOC)n` both take address n. A file
reference k takes address 2048 + k. The runtime area is therefore
addresses 0 to 4095.

The 1962 listing attests the rule for the entries. `TSX SYS)175,4`
assembles as `0074 00 4 00257`, and 0257 octal is 175
([J 90.05] listing, LOC 00165). `TXI IOC)40,0` assembles as
`1 00000 0 00050`, and 050 octal is 40.

`SYS)n` and `IOC)n` share one number space. The object deck marks both
with reference type `0000` and carries no discriminator
([J 90.03.05]). The two ranges do not collide: [J 90.02.10] gives 1 to
127 to the monitor-resident Type 1 entries, and every number above 127
to the Type 2 entries the loader brings in.

**The program loads at address 4096. Design decision.** No manual
states an origin. 4096 is the first address above the runtime area, so
one comparison separates a runtime entry from the program's own text.
The 90.05 sample then holds addresses 4096 to 5031, and its entry point
is 4213.

### The dispatch rule

The CPU core does not execute the runtime library (`emulator.md` §1;
D0.3). The machine therefore decides before each instruction:

- An address below 4096 is a runtime entry. The machine runs the Dart
  handler registered for it.
- Every other address is the program's own text. The machine calls
  `Cpu.step()`.

A handler reads its calling sequence through index register 4 and
returns to the parameter-word count plus one (M4-17). `Machine`
supplies both operations, and `MachineState` supplies nothing else the
handlers need.

Registration is a map merge. `monitor.dart` returns the run frame, and
each later family returns its own entries in the same shape.

### The run loop and its outcomes

`Machine.run` takes a step budget and returns a `RunResult`: the
outcome, the step count, and the display lines. A step is one
instruction or one runtime entry, so the budget bounds every run.
Three outcomes end a run:

| Outcome | What produced it |
|---|---|
| `endOfJob` | IOC)40, "the end of job return point" ([J 90.02.10]) |
| `errorExit` | SYS)294, which "exits back to the CT Monitor" ([J 90.02.33]) |
| `stepLimit` | The budget ran out |

**The budget belongs to the caller, and an exhausted budget is not an
error. Design decision.** D5.1 as amended makes a non-terminating loop
a reproduced result, not a diagnostic. The machine therefore returns
`stepLimit` and never throws for it.

### The unimplemented-entry rule

An address below 4096 with no handler throws
`UnimplementedRuntimeEntry`. The exception names the entry: `SYS)` above
127 and `IOC)` at or below it, per the Type 1 and Type 2 ranges of
[J 90.02.10]. A handler that meets work it does not do throws the same
exception with a reason.

This is the M4 to M5 boundary in one line. The 90.05 sample calls
open-all, which finds an empty file list while M5 owns IOC)1 (RT-2),
then reaches a MOVPAK entry and throws. When MOVPAK lands, the sample
reaches IOC)8 and throws there instead.

### What exercises the runtime

`comtranc --run` loads and runs each job whose deck the compiler
punched, and prints the display lines after the listing. CLAUDE.md
section 11 asks for a caller, and that flag is it. An unimplemented
entry prints its message and fails the run.

## RT-2. The run frame

`lib/src/runtime/monitor.dart` holds the entries an I/O-free program
reaches. The cells SYS)132, SYS)133, IOC)1 and IOC)29 need no handler:
they are memory, and generated code reads and writes them with ordinary
instructions ([J 90.02.10]).

### SYS)178, the STOP display

The calling sequence is `TSX SYS)178,4`, then `PZE CP)+NN1,,CP)+NN2`
and `PZE CP)+NN3,,CP)+NN4` ([J 90.02.14]). The four constant-pool words
hold, in BCD, the statement stamp and the type of the STOP (M4-14). The
handler reads the four words in address-then-decrement order, prints one
line, and returns to `3,4`.

The attested site is LOC 00521 to 00523 of the sample, with the pool
words `CP)+26` to `CP)+29` ([J 90.05] listing). They decode to
`   199`, `,14   `, ` STOP ` and ` RUN  `.

**The line reads `AT 199,14 STOP RUN`. Design decision.**
[J 05.06.04] gives the form "AT xxxxx,yy STOP nnnnnn" and no spacing
rule for the pool words' blank padding. The handler drops the padding:
it joins what is left of the twenty-four characters with one blank
each, after the word `AT`. No unsealed evidence survives (D0.9).

### SYS)175 and SYS)177, open all and close all

The calling sequence of each is the entry and one word, `PZE IOC)1`
([J 90.02.14]). IOC)1 is the cell `PZE L,,N`, which "locates (L) a list
of files, and designates the number (N) of files in the list"
([J 90.02.10]). The handler reads N from the cell's decrement.

- N is zero. The handler opens and closes nothing, and returns to `2,4`.
- N is not zero. Files are M5's. The handler throws
  `UnimplementedRuntimeEntry` and names the count.

Nothing writes IOC)1 at load time. Core starts at +0 (ED-6), so an
I/O-free program's N is already zero, and M5 owns the cell.

### SYS)294, the base-locator guard

`LAC BL)NN,N` then `TXL SYS)294,N,0` reaches this entry with no calling
sequence ([J 90.02.33]). The `LAC` loads 2^15 minus the base locator's
address field. The `TXL` fires when that index register is zero, which
is when the address field is zero. [J 90.02.33] says the routine
"prints an error message whenever a reference is made to a Base Locator
before the locator has been loaded, and exits back to the CT Monitor".

The handler prints one line and ends the run at `errorExit`. It leaves
the instruction counter where the transfer put it, because control does
not return.

**The line reads `BASE LOCATOR NOT LOADED`. Design decision.** Neither
manual prints the message text, and [J 90.04] has no object-time entry
for it. No unsealed evidence survives (D0.9). The Open Questions list of
the language definition records the gap.

### IOC)40, the end-of-job return point

`TXI IOC)40,0` transfers to "the end of job return point in the CT
Monitor communication area for all CT jobs" ([J 90.02.10]). The handler
ends the run at `endOfJob`. Control does not return, so the entry takes
no calling sequence and reads no parameter word.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 05.06.04]: ../../comtran-manuals/J28-6169/05-systems-operation.md#b-loader-1
[J 90.02.10]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.33]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.03.05]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#3-standard-word
[J 90.04]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.05]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
