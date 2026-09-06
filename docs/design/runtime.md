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
open-all, which finds an empty file list while M5 owns IOC)1 (RT-2). It
then fills its work areas through MOVPAK (RT-3) and reaches IOC)8, the
GET, which throws.

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

## RT-3. The MOVPAK step-list protocol

`lib/src/runtime/movpak.dart` holds the two dispatch entries and the
members under them. One MOVE that MOVPAK carries out is one session. The
entry opens the session, each member does one part of the work, and one
member ends it.

### The calling sequence

`TSX SYS)180,4` or `TSX SYS)182,4` opens a call ([J 90.02.15]). The
`TSX` writes the link into index register 4, so parameter word k of the
sequence sits at `k,4`. The entry returns to the parameter-word count
plus one, which is the convention M4-17 records.

The words after the entry are the step list. Each step is
`TXI SYS)nnn,1,count`. The CPU executes it: index register 1 takes the
count and the instruction counter takes nnn. The dispatcher then calls
the handler for nnn.

**The CPU executes the step list. Design decision.** The other reading
is an entry that reads each word through its own cursor and never lets
the CPU see it. Both readings are invisible to the program, because
`_movpakClears()` drops index register 1 from the register cache after
every call. The execute model reuses the CPU's `TXI` and the
dispatcher's address test, and it needs no second interpreter.

### The session

The session holds five things:

- the cursor, which is the address of the calling-sequence word in hand;
- one byte cursor over the source and one over the target, each copied
  from a pointer cell at the entry (RT-4);
- the member that opened a two-word run;
- the digits converted so far;
- the sign of those digits.

The cursor stands in for whatever cell the 1962 MOVPAK kept. No unsealed
evidence survives (D0.9). The cursor is not an index register: registers
2 and 4 are spoken for, and register 1 carries the count.

A second entry inside an open session is a broken object program. No
emitted sequence nests a call, so the entry throws.

### The off-by-one

The entry leaves the instruction counter on the family head word. The
entry does not execute that word. The CPU executes it next.

A step handler runs with the cursor on its own `TXI` word, never on the
next word. Each handler does this, in order:

1. Check that a session is open, and that the cursor word's address
   field names this entry. Either failure is a broken object program, so
   the handler throws a Dart error. This is not a D4.3 data condition,
   which never throws.
2. Take the count from index register 1, then clear that register.
3. Read the data words it owns. It never executes them.
4. Advance the cursor by one word plus the data words.
5. Do the work, then set the instruction counter to the cursor.

### The word shapes

`c` is the cursor when the handler runs. Index register 1 is 0 at every
resume, except SYS)267.

| Shape | Members | Data words | Resume | Ends the move |
|---|---|---|---|---|
| bare step | 193, 198, 211, 212, 214, 216, 268, 269 | 0 | c+1 | no |
| head and control word | 185, 190 | 1 | c+2 | no |
| terminator | 225, 226, 275 | 0 | c+1 | yes |
| one-word convert or mover | 184, 239, 243, 244 | 0 | c+1 | yes |
| mover pair, first word | 240 | 0 | c+1 | no |
| mover pair, last word | 241 | 0 | c+1 | yes |
| fill with characters | 245 | 1 | c+2 | yes |
| edited store | 267 | 1 | c+2 | yes |

The sample attests the resume of each shape it carries. `TXI SYS)225,1,5`
at LOC 00611 is followed by `CLA 3)HOURS` at 00612. `TXI SYS)245,1,6`
with its `OCT 747474747474` at 00346 is followed by
`TRA* END.OF.MASTERS` at 00350 ([J 90.05] listing).

A handler that owns a data word reads it after the advance, at
`cursor - 1`. SYS)267 owns one `OCT` word there and reads its `AXT` word
at `cursor`.

### SYS)267 and its AXT word

The edited store is `TXI SYS)267,1,edit / OCT control / AXT digits,1`
([J 90.05] listing). The handler reads the `AXT` word's address field
for the digit count. It then returns to that word.

**The CPU executes the trailing `AXT`. Design decision.**
`lib/src/codegen/procedure.dart` builds its register-cache model on the
claim that the trailing `AXT` is the call's only register write. To let
the CPU execute the word makes that claim true in the emulator. The
choice is invisible to the program: index register 1 ends at the digit
count, and the instruction counter ends at `c+3`, under both readings.

One of the 26 SYS)267 sites punches `TRA SYS)267,0,0` instead of the
step, because its edit control computes to zero ([J 90.05] listing, LOC
01327). The CPU executes that word with tag 0, so index register 1 keeps
the 0 the entry wrote, and the handler reads control 0.

### The register contract

- A MOVPAK entry or member writes index register 1 only, and leaves it
  0. SYS)267 is the exception, because the CPU's `AXT` then loads the
  digit count.
- Index register 2 must survive a call. `_assignRegister` hands out
  registers 1 and 2 and refuses a third, and `_movpakClears()` drops
  register 1 alone, so generated code addresses `NAME,2` across a call.
- Index register 4 must survive the link the `TSX` wrote. Every resume
  address is computed from it.
- The run frame of RT-2 and the IOCS calls take a full cache clear after
  them, so they may write any register. That licence stops at MOVPAK.

`test/runtime/movpak_protocol_test.dart` holds one case per row of the
table above. Each case preloads junk into registers 1 and 2, then
asserts the resume address, register 1, register 2, the link in register
4, and whether the session is still open. Two negative cases assert the
two broken-program throws.

### Rejected readings

| Reading | What refutes it |
|---|---|
| A step handler reads its count from its own `TXI` word | A `TXI` writes no link, so the routine has no address for that word |
| Index register 1 is not cleared, and each step subtracts the last count | The sample's step counts run both up and down, so no difference rule recovers them |
| The terminator's count is the target's character length | `TXI SYS)226,1,7` stands against the 8-character target `88889.99` ([J 90.05] listing) |
| SYS)241 writes its blanks ahead of the moved characters | [J 02.04.03] left-justifies the data and blanks the excess low-order positions |
| SYS)244 writes zero words | Its entry moves zeros "to an alphabetic field" ([J 90.02.26]), and the count 54 is a character count |
| The SYS)180 address word may be `MZE` or `MON` | `_pze` refuses a located item, and no emitter builds a positional-indicator form |
| SYS)184's result carries the pictorial's scale | The calling sequence carries one count and no scale ([J 90.02.16]) |
| An improper data condition throws | D4.3 forbids a Dart exception and a stop |

## RT-4. The pointer cells and the non-edited members

### The pointer cells

`SYS)132` holds the source pointer and `SYS)133` the target pointer
([J 90.02.11]). Each cell holds the word `PZE LOC,,BYTE`: the address
field is the word address, and the decrement is the byte, 0 to 5
([J 90.02.14]). Byte 0 is the word's high-order character.

The cells are core storage, not handler state. Generated code writes
them with `STI SYS)132` and `SLW SYS)133` ([J 90.05] listing), so a
handler reads them through memory at the addresses the resolver gives
them.

- `SYS)182` takes no parameter word, because both cells are already set.
- `SYS)180` takes one `PZE LOC,,BYTE` and stores it into `SYS)133`
  ([J 90.02.15]). Its source is a machine register, so `SYS)132` is
  stale.

The entry copies both cells into the session and reads neither as a
source or a target. The family head decides which side is a register.

**The handler decodes `PZE` only. Design decision.** The manual also
prints `MZE BL)NN,,CP)+NN` ([J 90.02.14]) and `MON PI)NN,,0`
([J 90.02.15]). Our generator emits neither, because `_pze` refuses a
located item before it reads anything. A prefix test would duplicate
that refusal, and CLAUDE.md section 11 bars a branch no run reaches.

**The advanced pointers are not written back. Design decision.** No
source says whether MOVPAK returns them. Every emitted site presets both
cells before the next call, so no emitted word can see the difference.
No unsealed evidence survives (D0.9).

### SYS)184, external decimal to internal decimal

`TXI SYS)184,1,NUMBER-OF-CHARACTERS-TO-CONVERT` converts the source and
leaves the value in the accumulator ([J 90.02.16]). The value is the
digit string as a binary integer. The handler is told no scale, and the
sample's three sites give source and target the same scale, so the
emitted `LRS` and `DVP` tails of D4.1 carry every alignment.

The characters are read one at a time:

- A digit 0 to 9 contributes its value.
- A blank contributes 0, in any position. The chart admits leading
  blanks in an external decimal field ([J 02.05.05] note 3).
- The low-order character alone may carry an overpunch sign. Zone 1 is
  the 12 punch and means plus. Zone 2 is the 11 punch and means minus.
  12-0 is a plus zero and 11-0 a minus zero (D0.6).
- Every other character is an improper data condition (D4.3). The
  handler sets `SYS)131` non-zero, takes the low four bits as the digit,
  and continues. It never throws.

A minus-overpunched zero gives the machine's minus zero: the sign bit is
set and the magnitude is 0.

### SYS)268, SYS)269 and SYS)275, an edited field to a register

The call is `TXI SYS)268,1,1`, then one or more steps, then
`TXI SYS)275,1,TARGET-DECIMAL-NUMERIC-LENGTH` ([J 90.02.30]). The one
attested site converts five digits and stores the result with `STO`
([J 90.05] listing, LOC 01356 to 01362).

**SYS)268's decrement is read and ignored.** Every sibling family head
carries a sign convention or an edit control. This one carries a bare 1,
and no source says what it means. No unsealed evidence survives (D0.9).

**SYS)269 counts digit positions, not storage characters. Design
decision.** Codegen passes the source's digit count, and the same rule
governs the SYS)198 move step. The one site cannot separate the two
readings, because its source `899V99` has five digits and five
characters. Under the character reading our own generator would
under-consume a source such as `$8,889.99`.

The handler has no source control word, because the calling sequence
carries a target control word only ([J 90.02.17]). It therefore
classifies each character as it reads it:

- A digit contributes its value.
- A blank or an asterisk is a suppressed digit position worth 0. It is
  counted, and it arms nothing.
- An insertion character — the point, the comma, the dollar sign, the
  plus and the minus — is stepped over and is not counted.
- Anything else is an improper data condition (D4.3), as under SYS)184.

**The asterisk is a digit position, not an insertion character. Design
decision.** The target control word counts the asterisks beside the 8's
and the 9's ([J 90.02.17] Note 2), and the chart's edited row calls the
asterisk positions suppressed positions ([J 02.05.05]). The choice is
unobservable at the one attested site, whose source holds no asterisk.

**SYS)275's length is the digit count of the value delivered.** Two
lines of evidence agree. The terminator's count is the target's digit
count at every attested site, not its character count. The step counts
of each edit run sum to the terminator's count.

### More than ten digits

The AC-MQ pair holds a value of more than 10 digits ([J 02.05.06]). The
SYS)166 entry fixes the order: the high-order part goes in the MQ and
the low-order part in the AC ([J 90.02.12]). D4.1(c) records that order.
Nothing fixes the radix of the split, and no unsealed evidence survives
(D0.9).

**Codegen refuses more than 10 digits on both paths, and the handler
throws. Design decision.** The SYS)184 path and the edited fetch each
park the result with one `STO`, which stores the accumulator alone. The
refusals are in the M4-9 and M4-10 records. SYS)184 and SYS)275 throw
`UnimplementedRuntimeEntry` on a count above 10, so the untaken shape
cannot pass silently.

### The character movers

| Member | What it writes | Citation |
|---|---|---|
| SYS)239 | the count in characters, source to target | [J 90.02.25] |
| SYS)240 | the source's characters, then leaves SYS)241 the excess | [J 90.02.25] |
| SYS)241 | blanks over the target's excess positions | [J 90.02.25] |
| SYS)243 | blanks over the whole target | [J 90.02.25] |
| SYS)244 | the character `0`, BCD 00, over the whole target | [J 90.02.26] |
| SYS)245 | the six characters of its in-line `OCT` word | [J 90.02.26] |

Every mover writes through the target byte cursor and crosses a word
boundary freely. SYS)241's blanks go after the moved characters, because
[J 02.04.03] left-justifies a shorter source and blanks the excess
low-order positions. SYS)241 refuses a session that SYS)240 did not
open.

SYS)244 writes the character zero, not a zero word. A full-word run of
that character is a zero word, so the two readings differ only on a
partial first or last word.

**SYS)245 cycles its six characters. Design decision.** The entry calls
the second word "6 characters of the type to be moved", which is a
pattern and not a positional image. Cycling is the only rule that
answers a count above six without a second parameter. Both attested
sites carry six copies of one character, so they cannot separate
cycling from its rivals. A count other than six is reachable: the
figurative fill passes the target's storage extent. No unsealed evidence
survives (D0.9).

`test/runtime/movpak_test.dart` holds one decision-conformance case per
rule above, and every mover case crosses a word boundary. The same file
runs two compiled programs to the end of the job: one over the four
movers, and one over both converts.

## RT-5. The edited-field renderer

An edited field is a character image of a number: digit positions, and
the insertion characters between them ([J 02.05.05]). Three MOVPAK
members write one — SYS)185 from an external decimal source, SYS)190
from another edited field, and SYS)267 from the accumulator. All three
end in one renderer, `_render` in `lib/src/runtime/movpak.dart`.

### What the renderer is given

| Name | Where from |
|---|---|
| the target pointer | the cell `SYS)133` (RT-4). It carries no length |
| TARGET-EDIT-CONTROL | the family head's decrement: octal 01 asterisk, 02 comma, 04 point, 10 dollar, 20 Blank When Zero ([J 90.02.17] Note 1) |
| TARGET-CONTROL-WORD | the `OCT` word behind the head: prefix the digits ahead of the first comma, decrement the digits ahead of the real or implied point, tag the sign convention, address the leading run of `8` or `*` ([J 90.02.17] Note 2) |
| the digit count | the terminator's TARGET-NUMERIC-LENGTH, or SYS)267's `AXT` address |
| the digits | built by the steps, or converted from the accumulator |
| the sign | the accumulator's, or plus |

### The character length is derived

No parameter word carries the target's character length. The renderer
lays out one cell per character the two words call for, and the count
of those cells is the length:

- one leading sign cell under convention 5 or 6;
- one dollar cell when the dollar bit is set;
- the integer digits, with a comma cell before each digit the prefix
  and the three-digit grouping name;
- one point cell when the point bit is set;
- the fraction digits;
- one trailing sign cell under convention 3 or 4.

The design pass verified that count against 23 field placements in
four record layouts of the 90.05 sample: the byte offset of each
`PZE LOC,,BYTE` pointer only comes out right if every field is as long
as the derivation says. `V` reserves no position and `.` reserves one,
which is why the edit control separates them.

### The suppression rule

Suppression reaches the first significant digit and no further, and the
control word's address field bounds it:

    suppressed = min(address, index of the first non-zero integer digit)

With every integer digit zero the second term is the integer count.
Digit cells below `suppressed` take the fill — an asterisk when the
asterisk bit is set, a blank otherwise ([F p. 80]). A comma cell ahead of
a suppressed digit takes the fill too. The point and the fraction
digits are never suppressed.

The address field is what stops a `9` from suppressing. [F p. 81] gives
`88999` the range 000 to 99999, so its minimum image keeps three
printed zeros, and it gives `$888,888.99` the minimum `$.00` and
`****.99` the minimum `****.00`.

### The floating dollar

The dollar floats to the last filled cell ahead of the first printing
cell when the dollar bit is set, the asterisk bit is clear, and the
address field is not zero. "It will be placed immediately to the left
of the first significant digit remaining" ([F p. 80]). The report page
`images/page-217.png` prints `$294.12` into `$8889.99` with no gap,
which a fixed dollar cannot produce.

A comma cell is a candidate landing place. That is the only reading of
[F p. 80]'s remark that a comma "may be replaced by a blank, asterisk, or
dollar sign".

### The eight attested renderings

Every one is reproduced by `test/runtime/movpak_edit_test.dart`.

| Pictorial | Value | Image | Oracle |
|---|---|---|---|
| `8889.9` | 0040.0 | `␢␢40.0` | page-217, the hours column |
| `8889.99` | 0000.00 | `␢␢␢0.00` | page-217, a zero amount |
| `88889.99` | 00037.50 | `␢␢␢37.50` | page-217, the last column |
| `899V99` | 03750 | `␢3750` | page-217, BONDORDERFILE |
| `$8889.99` | 0294.12 | `␢$294.12` | page-217, CHECKFILE |
| `88999` | 00000 | `␢␢000` | [F p. 81] range table |
| `****.99` | 0000.00 | `****.00` | [F p. 81] range table |
| `$888,888.99` | 000000.00 | `␢␢␢␢␢␢␢$.00` | [F p. 81] range table |

### Blank When Zero

The edit control's octal 20 bit is the Description clause (D3.2). "The
field is to be replaced with blanks" ([J 02.05.07]).

**The whole image goes blank, and the test is over the digits. Design
decision.** The manual names the field, not its digit positions, so the
insertion characters go too. No sample site sets the bit, and no
unsealed evidence survives (D0.9).

### The sign conventions

Only convention 0 is attested: no target pictorial in the sample
carries a sign. **The other six are a design decision**, taken from F
p. 80's two rules — a plus position always prints, and a minus position
is blank on a positive value.

| Tag | Cell | Negative | Positive |
|---|---|---|---|
| 0 | none | — | — |
| 1 overpunch minus | none | 11 punch on the last digit | the plain digit |
| 2 overpunch plus | none | 11 punch | 12 punch |
| 3 right minus | after the fraction | `-` | blank |
| 4 right plus | after the fraction | `-` | `+` |
| 5 left minus | before everything | `-` | blank |
| 6 left plus | before everything | `-` | `+` |

An overpunched zero is the 12-0 or 11-0 punch, octal 32 or 52 (D0.6).

**A left sign sits ahead of the dollar, and an overpunch rides the last
digit cell whatever suppression left there. Design decision.** [F p. 80]
leaves both placements open. No unsealed evidence survives (D0.9).

### The heads, the steps and the terminators

The digit string is built left to right, and the terminator renders it
([J 90.02.17], [J 90.02.19]).

| Member | 185 | 190 | What it does |
|---|---|---|---|
| head | 185 | 190 | parks the edit control and the control word |
| leading zeros | 212 | 214 | appends the count in zero digits |
| move | 193 | 198 | appends the count from the source |
| trailing zeros | 211 | 216 | appends the count in zero digits |
| terminator | 225 | 226 | renders, writes, and ends the move |

SYS)193 reads an external decimal source: a digit contributes its
value, a blank contributes 0 ([J 02.05.05] note 3), and anything else
is an improper data condition (D4.3). SYS)198 reads an edited source
through the reader of RT-4, so a blank and an asterisk are digit
positions worth 0 and the insertion characters are stepped over.

**Neither move step reads the source's sign, so a rendered value is
positive. Design decision.** The manual gives the sign-examining steps
their own numbers — SYS)228, SYS)232 and SYS)236 for SYS)185, SYS)230,
SYS)234 and SYS)238 for SYS)190 — and the generator emits none of them.
An overpunch a plain move meets is therefore an improper data
condition.

The terminator's count must equal the digits the steps built. A step
list that misses it is a broken object program, so the handler throws.

### SYS)267, the accumulator to an edited field

`TXI SYS)267,1,edit / OCT control / AXT digits,1` ([J 90.02.30]). The
handler reads the count from the `AXT` word's address field, converts
the accumulator to that many decimal digits, renders, and returns to
the `AXT` for the CPU to execute (RT-3).

**The source is the accumulator alone, never the AC-MQ pair.** Two
lines of evidence agree. Twenty-two of the twenty-five sites load with
`CLA` and leave the MQ holding whatever the last multiply or divide
left. The other three split the digits with `LRS 35 / DVP`, which
parks the excess in the MQ on purpose (D4.1(c)); to read the pair would
undo the split.

**A value of more digits than the count drops its high-order digits,
and arms nothing.** That is the discard the split performs, and [F p. 42]
describes it for MOVE: alignment "may involve the dropping of leading
digits". D4.2 fixes that no reachable handler arms `SYS)130`.

### What the compiler refuses

Three edited pictorials reach no control word, so codegen refuses them
(`m4-codegen.md` M4-9 item (f)):

- an `S` position, because it is a digit the field represents and does
  not store ([F p. 80]) while every MOVPAK count is a digit count;
- a suppression character behind the leading run, because the address
  field carries the leading run alone;
- irregular comma grouping, because the prefix carries the first
  comma's offset alone.

### Open items

| Item | What no unsealed source settles (D0.9) |
|---|---|
| an edited source carrying insertion characters | no parameter word describes the source, so a suppressed comma and a suppressed digit are the same blank. The reader of RT-4 classifies characters instead |
| a target of more than ten digits | SYS)267 would need the AC-MQ pair, whose split radix is unfixed. No site exceeds seven |
| a leading run mixing `8` and `*` | one address field cannot say which cells take a blank and which an asterisk. The compiler accepts it today |
| the sign of a rendered zero | [J 02.04.07] scopes its unsigned-zero rule to comparison |
| a round step inside a render | SYS)220 and SYS)222 are entered by a bare `TRA`, and no site emits either (D4.1(e)) |
| where the image is built | our renderer builds it in Dart and writes the target once, at the terminator. No emitted word can see the difference |

### Rejected readings

| Reading | What refutes it |
|---|---|
| The character length is the sum of the step counts | LOC 00605 sums to 5 against the 6-character target `8889.9`, and SYS)267 emits no steps at all |
| The pointer cell carries the length | `CP)+53` is `PZE HRS,,5`: a word address and a byte, and nothing else ([J 90.05] listing) |
| The control word's address is the digit count | `899V99` has five digits and punches address 1 (LOC 01327) |
| The control word's decrement counts characters left of the point | `$8889.99` punches decrement 4, and five characters stand left of its point (LOC 01146) |
| `V` sets the decimal-point bit | `899V99` punches edit control 0, and the report prints `3750` with no point |
| The dollar sign is fixed | `$294.12` on page-217 shows no gap ahead of its digits |
| An `8` blanks every zero in its run | [F p. 81] gives `88999` the minimum image `␢␢000` |
| A `9` position suppresses | the same range table, and page-217's `0.00` columns |
| SYS)267 reads the AC-MQ pair as one value | the twenty-two `CLA` sites leave the MQ stale, and D4.1(c) discards the excess quotient |
| The `TRA` form of the store selects another routine | both forms name address 00413 ([J 90.05] listing, LOC 01327) |
| An overpunched zero is the zone over digit 0 | that is a bare `+` or `-`; row 0 carries the zero (D0.6) |

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 42]: ../../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F p. 80]: ../../comtran-manuals/F28-8043/04-data-description.md#format-characters
[F p. 81]: ../../comtran-manuals/F28-8043/04-data-description.md#format-characters
[J 02.04.03]: ../../comtran-manuals/J28-6169/02-compiler.md#2-display
[J 02.04.07]: ../../comtran-manuals/J28-6169/02-compiler.md#c-conditional-statements
[J 02.05.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.06]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.07]: ../../comtran-manuals/J28-6169/02-compiler.md#2-constants
[J 05.06.04]: ../../comtran-manuals/J28-6169/05-systems-operation.md#b-loader-1
[J 90.02.10]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.11]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.12]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.15]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.16]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.17]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.19]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.25]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.26]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.30]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.33]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.03.05]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#3-standard-word
[J 90.04]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.05]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
