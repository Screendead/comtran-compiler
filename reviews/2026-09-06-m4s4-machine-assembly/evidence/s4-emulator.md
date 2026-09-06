# 1. PUBLIC API

Four files, all exported from the package root (`lib/comtran.dart:64-67`: `export 'src/emulator/cpu.dart';` … `word.dart`), so `Cpu`, `MachineState`, `UnimplementedOpcode7090`, `Instruction`, `Op`, `Word36` are all public.

## `lib/src/emulator/machine_state.dart` — `final class MachineState`

Constructor: implicit, no arguments. No reset method, no clear, no copy.

| Member | Line | Text |
|---|---|---|
| `static const int memoryWords = 32768` | 14 | "Words of core storage (22-6528-4 p. 7, external)." |
| `static const int acMagnitudeMask = (1 << 37) - 1` | 18 | "Mask of the AC's 37-bit magnitude: Q = bit 36, P = bit 35, positions 1–35 = bits 34–0." |
| `static const int acPBit = 1 << 35` | 21 | "The P-position bit inside [acMagnitude]." |
| `static const int acQBit = 1 << 36` | 24 | "The Q-position bit inside [acMagnitude]." |
| `final Uint64List memory = Uint64List(memoryWords)` | 31 | public field; "Cells start at +0: a recorded decision (ED-6)" (28) |
| `int acSign = 0` | 34 | "AC sign: 0 = plus, 1 = minus." |
| `int acMagnitude = 0` | 37 | "AC magnitude, 37 bits: Q, P, 1–35" |
| `int mq = 0` | 40 | "The multiplier-quotient register, one 36-bit word (S, 1–35)." |
| `int si = 0` | 44 | "The sense-indicator register. SI position 0 is bit 35, so LDI and STI are bit-for-bit word moves" (42-43) |
| `int ic = 0` | 47 | "The instruction counter, 15 bits." |
| `bool overflow = false` | 50 | "Overflow indicator (22-6528-4 p. 11, external)." |
| `bool divideCheck = false` | 53 | "Divide-check indicator (22-6528-4 p. 11, external)." |
| `final Uint16List _xr = Uint16List(3)` | 56 | **private**; "Index registers 1, 2, 4 in tag-bit order." |
| `int get acWord` | 60 | `(acSign << 35) \| (acMagnitude & Word36.magnitudeMask)` — "This is what STO stores" |
| `int get acLogicalWord` | 64 | `acMagnitude & Word36.wordMask` — "This is what SLW stores" |
| `int xrRead(int tag)` | 68 | "the logical OR of every named register; 0 with tag 0" |
| `void xrWrite(int tag, int value)` | 85 | "Loads [value] (masked to 15 bits) into every index register named by [tag]" |
| `int read(int location)` | 100 | "Reads the word at [location] (15-bit, checked)." |
| `void write(int location, int word)` | 106 | "Writes [word] (checked to 36 bits) at [location]." |

**How the registers are read and written.** `acSign`, `acMagnitude`, `mq`, `si`, `ic`, `overflow`, `divideCheck` are plain public mutable fields — no setter, no validation, no masking. A handler that writes `ic` past 15 bits gets no wrap; the next `step()` calls `state.read(location)` (`cpu.dart:49`) and that throws `RangeError`. XR1/2/4 are reachable **only** through `xrRead`/`xrWrite` by tag bit (1, 2, 4): `_xr` is private and there is no per-register accessor. Memory is reachable two ways: `read`/`write`, which validate, and the public `memory` field (line 31), which does not — a direct `memory[i] = w` bypasses the 36-bit check at lines 108-110.

**Validation and throws.** `RangeError.checkValueInInterval(tag, 0, 7, 'tag')` in `xrRead` (69) and `xrWrite` (86); `RangeError.checkValueInInterval(location, 0, memoryWords - 1, 'location')` in `read` (101) and `write` (107); `write` also throws `ArgumentError.value(word, 'word', 'must fit in 36 bits')` (109).

## `lib/src/emulator/cpu.dart`

`final class UnimplementedOpcode7090 implements Exception` (line 10). Constructor `UnimplementedOpcode7090(this.operation, this.location, this.word)` (11). Fields: `final String operation` (15) — "The signed octal operation code (`+0522`, `-2`, or a 0760-family sub-operation such as `+0760 address 00007`)" (13-14); `final int location` (18) — "The location (IC value) of the instruction."; `final int word` (21). `toString()` (24-27) renders `'Unimplemented 7090 operation $operation at <octal loc> (word <12 octal digits>)'`.

`final class Cpu` (36). Constructor `Cpu(this.state)` (37). One public field: `final MachineState state` (40). One public method:

```
void step()   // cpu.dart:47
```

Returns `void`. No step count, no status, no "ran a handler" signal. Body (47-68): `final int location = state.ic;` → `state.read(location)` → `Instruction.decode(word)` → throw if `Op.unknown` → the +0760 sub-operation check → `state.ic = (location + 1) & Word36.fieldMask15;` (66) → `_execute(inst, location)` (67). Doc comment (42-46): "Executes one instruction at the current IC. … Throws [UnimplementedOpcode7090] — before any state change — for a word outside the subset."

Everything else in `Cpu` is private: `_effectiveAddress`, `_execute`, `_shiftCount`, `_addSigned`.

**How a halt or an error surfaces.** There is no halt. HTR and HPR are not in the subset — `emulator.md:229-231`: "**Halts (HTR, HPR) and console devices** (ENK, sense switches/lights): STOP compiles to SYS)178/SYS)177/IOC)40 calls, not to halt instructions (D2.7); an executed +0000 word signals a broken program and throws." A run ends only by an exception or by the caller stopping. The complete exception inventory reachable from `step()`:

- `UnimplementedOpcode7090` — any word outside the 43-opcode subset, including `+0000` (a PZE parameter word), and `+0760` with a modified address other than 6 (`cpu.dart:51-65`).
- `RangeError` — from `read`/`write`/`xrRead`/`xrWrite` as above.
- `ArgumentError` — from `write` (36-bit check) and from `Word36.fromSignMagnitude` (`word.dart:36, 39`), which MPY, DVP and LRS call.
- `StateError('unknown op reached _execute')` (`cpu.dart:387`), commented "Unreachable: step() throws before execution."

## `lib/src/emulator/decode.dart`

`enum Op` (8-159): 43 subset members plus `unknown` — cla, cal, add, sub, acl, mpy, dvp, sto, slw, stq, ldq, xca, ana, ans, ors, com, cas, las, tra, tpl, tsx, nop, txi, txh, txl, axt, sxa, lxa, lac, pxa, pdx, ldi, sti, sir, rir, rft, als, ars, lrs, lgl, lgr, rql, cvr.

`final class Instruction` (165). `Instruction.decode(this.word)` (168) — "Never throws: words outside the subset decode to [Op.unknown] and fail only on execution (decision ED-4)" (166-167). Fields/getters: `final int word` (171), `final Op op` (173), `int get decrement` (176), `int get tag` (178), `int get address` (180), `bool get flagged` (183), `int get count` (186), `int get rightHalf` (189), `String get operationOctal` (193). Private `static Op _decodeOp(int word)` (202).

## `lib/src/emulator/word.dart`

`abstract final class Word36` (7) — a static namespace. Constants: `bits = 36` (9), `wordMask = (1 << 36) - 1` (12), `magnitudeMask = (1 << 35) - 1` (15), `signBit = 1 << 35` (18), `fieldMask15 = (1 << 15) - 1` (21), `fieldMask18 = (1 << 18) - 1` (25). Static methods: `sign(int)` (28), `magnitude(int)` (31), `fromSignMagnitude(int sign, int magnitude)` (34, throws `ArgumentError` on either range), `prefix(int)` (48), `decrement(int)` (51), `tag(int)` (54), `address(int)` (57), `flagged(int)` (61), `operationField(int)` (67), `count(int)` (70), `rightHalf(int)` (73), `octal(int)` (76), `operationOctal(int operationField)` (81).

# 2. HOW A DISPATCH LAYER CAN INTERCEPT

**There is no hook today.** `cpu.dart` has no callback field, no address table, no listener, no `onStep`. `Cpu` is constructed in exactly one place in the whole repository outside the emulator tests: `grep -rn "Cpu(\|\.step()" lib/ bin/ test/ tool/` excluding `test/emulator` returns only `lib/src/emulator/cpu.dart:37: Cpu(this.state);`. No production code runs the CPU at all.

The one available interception point is that `step()` reads the IC at line 48 (`final int location = state.ic;`) and does not advance it until line 66. So a dispatcher owns the decision **before** calling `step()`: read `state.ic`, look it up in its own table, run the handler or call `cpu.step()`. Nothing inside the CPU has to change.

## `emulator.md` §1, quoted in full (lines 13-22)

> ## 1. Scope
>
> The core executes the CPU instructions that appear in COMTRAN-generated
> object code. It does not execute the SYS)/IOC) runtime: those routines are
> high-level Dart handlers at the documented entry points (D0.3). The caller
> (the M4 machine assembly) intercepts control before the CPU enters a runtime
> entry address. Inside generated code, the calling-sequence parameter words
> (PZE, MZE, OCT, IOST, IOCTN data words) are data for those handlers; the CPU
> never executes them. If the instruction counter ever reaches one, the CPU
> throws (§7) — there is no silent wrong path.

## `emulator.md` §8, quoted in full (lines 218-236)

> ## 8. Out of scope (and why)
>
> - **Data channels, tapes, card units, printer, all I/O instructions**
>   (RDS/WRS/TCO/TEF/IOCP-family, …): D0.7 emulates I/O at the IOCS level;
>   generated CPU code reaches I/O only through SYS)/IOC) entry points, and
>   none of these opcodes appears in the harvest.
> - **Floating point** (FAD/FMP/…): absent from the harvest. COMTRAN
>   floating-point operations route through MOVPAK/SYS) subroutines
>   ([J 90.02.11.01] ff.), which are high-level handlers under D0.3.
> - **Trapping modes, STR, ETM/LTM/TTR, data-channel traps**: no trap
>   instruction is harvested; the CT Monitor boundary is a high-level handler.
> - **Halts (HTR, HPR) and console devices** (ENK, sense switches/lights):
>   STOP compiles to SYS)178/SYS)177/IOC)40 calls, not to halt instructions
>   (D2.7); an executed +0000 word signals a broken program and throws.
> - **Convert CRQ/CAQ, and the rest of the ~200-instruction set**: not
>   harvested; every one decodes to a typed throw, never to silence.
>
> Widening the subset later is additive: one decode-table entry, one execute
> case, one manual citation, one test group.

## What stage 4 must add to run a program

Everything below the CPU boundary is missing today; each item is stated by a record, not invented here.

1. **A run loop.** No loop exists anywhere. `emulator.md:16-18` assigns it to "The caller (the M4 machine assembly)".
2. **Writing loader words into memory.** `loadDeck` (`lib/src/loader/loader.dart:134-138`) returns `LoadedProgram`, whose `final Map<int, int> words` (115) is "Every word the text placed, by absolute address. Reservations place nothing." (113-114). `docs/design/loader.md:145-148`: "No program run reads the result yet: stage 4 reads `origin`, `entry` and `words`"; and 147-149: "The machine assembly stage writes the words into `MachineState` and runs; that is the plan CLAUDE.md section 11 asks for." `HANDOVER.md:94-95` repeats it: "the loader returns the words by address; stage 4 writes them into `MachineState` and enters at the entry point (LD-3)". A reserved (BSS) cell gets nothing, so it reads +0 by ED-6.
3. **Entering at an address.** `LoadedProgram.entry` (`loader.dart:111`, "The absolute entry point (D2.1)") assigned to `state.ic`. Nothing does this today.
4. **A dispatch table and its resolver.** `typedef SystemReferenceResolver = int Function(SystemReference reference);` (`loader.dart:55`) is a required argument of `loadDeck` (136). `loader.md:135-137`: "The dispatch table is M4-17's and the file blocks are M5's, so no address is fixed here." The loader validates whatever the resolver returns through `_fits` (`loader.dart:358-363`): "address $address is outside core".
5. **A step budget.** Nothing bounds a run. `decisions.md:839` makes an unbounded loop a *designed* outcome: "Under the equality reading such a loop does not terminate, and the emulator reproduces that non-termination." An execution test therefore needs a cap that the emulator does not supply.

# 3. TSX/XR4 CONVENTION

## The TSX case, quoted (`cpu.dart:219-223`)

```dart
      case Op.tsx: // M p. 39: XR(T) <- 2's complement of the TSX location;
        // IC <- Y. The tag names the target register (M p. 10), so the
        // address takes no modification.
        state.xrWrite(inst.tag, (0x8000 - location) & Word36.fieldMask15);
        state.ic = inst.address;
```

`location` is the IC value captured at `cpu.dart:48` before the advance, so XR(T) receives 2^15 − L where L is the address of the TSX word itself. The destination is `inst.address` **raw** — no indexing, no indirection.

## The effective-address code, quoted (`cpu.dart:75-85`)

```dart
  int _effectiveAddress(Instruction inst, {required bool indirectable}) {
    int ea = (inst.address - state.xrRead(inst.tag)) & Word36.fieldMask15;
    if (indirectable && inst.flagged) {
      final int indirectWord = state.read(ea);
      ea =
          (Word36.address(indirectWord) -
              state.xrRead(Word36.tag(indirectWord))) &
          Word36.fieldMask15;
    }
    return ea;
  }
```

Index modification **subtracts**, per the doc comment at 72-73: "The effective address: instruction address minus the OR of the tagged index registers, mod 2^15 (M p. 10)."

## What a Dart handler must do

At the moment of intercept the dispatcher has not called `step()`, so `state.ic` is the dispatch address and XR4 already holds 2^15 − L, where L is the TSX location in the caller's code. Two consequences, both arithmetic on `state.xrRead(4)`:

- **Read parameter word i** (i = 1 .. n, the words following the TSX): `state.read((i - state.xrRead(4)) & Word36.fieldMask15)` — the same subtraction `_effectiveAddress` performs at line 76, which is why the generated code addresses its own calling sequence as `PZE 1,4`, `2,4`, and so on.
- **Resume**: `state.ic = (n + 1 - state.xrRead(4)) & Word36.fieldMask15;` for a calling sequence of n parameter words. This is exactly `TRA n+1,4` executed by the CPU.

The convention is attested twice. `m4-codegen.md:479-482`: "The MOVPAK dispatch entries and their return-skip convention: SYS)179 (both descriptors in the calling sequence, resume 3,4), SYS)180 (target only, 2,4), SYS)181 (source only, 2,4), SYS)182 (both preset, 1,4) — resume offset is parameter-word count plus one ([J 90.02.14]–15)." Note SYS)182 takes **one** word and resumes at `1,4` — i.e. the word right after the TSX — so "count plus one" holds down to n = 0 as well.

The emulator already proves the arithmetic end to end in `test/emulator/cpu_transfer_index_test.dart:64-75`:

```dart
    test('the calling-sequence return convention works', () {
      // TSX SYS)N,4 ... parameter words ... return TRA 3,4: the effective
      // address 3 - XR4 = the TSX location + 3 (pp. 10, 39).
      m
        ..write(0x100, typeB(0x03C, address: 0x300, tag: 4))
        ..write(0x300, typeB(0x010, address: 3, tag: 4)) // TRA 3,4
        ..ic = 0x100;
      cpu
        ..step()
        ..step();
      expect(m.ic, 0x103);
    });
```

Edge case already pinned (`cpu_transfer_index_test.dart:77-85`): "at location zero, the return index wraps to zero — TSTC-08: 0x8000 - 0 masks to 0, not 0x8000." The subtraction still yields the right target because both sides are mod 2^15.

**The one handler that breaks the pattern** is named by the record itself, `m4-codegen.md:897-901`: "SYS)294 alone breaks the pattern: the guard's conditional `TXL` reaches it with no calling sequence, and it exits to the monitor instead of returning." A TXL (`cpu.dart:239-242`) writes no index register and its tag is the guard's own register, so XR4 at SYS)294 is whatever the last TSX left — not a return link.

# 4. ED-n RULES

Seven labels exist in the whole repository; all are in `emulator.md`.

| Label | Line | One-line gloss |
|---|---|---|
| ED-1 | 24 (heading "## 2. Word representation (ED-1)"), restated 39, 41 | One 36-bit word is one Dart `int` in `0 .. 2^36 - 1`, S at bit 35; the AC is a sign plus a 37-bit magnitude; MPY's 70-bit product and DVP's 72-bit dividend go through `BigInt`. |
| ED-2 | 172 "**Overflow gating (ED-2).**" | Overflow is set only when the effective operation is a true addition of like-signed magnitudes carrying out of position 1; the complement path never sets it. |
| ED-2a | 190 "**LGL overflow trigger (ED-2a).**" | "Into or through position P" means a 1 moved from position 1 into P at some step; a 1 that starts in P and leaves toward Q does not trigger. |
| ED-3 | 194 "**0760-family dispatch (ED-3).**" | The +0760 sub-operation is the *modified* address; only 00006 (COM) is implemented, anything else throws naming the sub-operation. |
| ED-4 | 199 "**Fail-loud decode (ED-4).**" | `decode` never throws (a disassembler must render any word); execution of a non-subset word throws `UnimplementedOpcode7090` carrying opcode and IC — +0000 (an executed PZE) included. |
| ED-5 | 186 "**Shifts execute stepwise (ED-5).**" | Every shift runs one register step per count, so counts ≥ 36 and the overflow triggers are correct by construction. |
| ED-6 | 60 "**Memory starts at +0 in every cell (ED-6).**" | Core is all +0 at construction; no source attests a power-on value, and the loader fills every program-relevant cell. |

# 5. UNLABELLED READINGS

First, a correction to the task's line reference: the LAS case is `cpu.dart:200-210`, not 195-215. Lines 195-198 are the tail of the CAS case. The LAS comment is at line 200:

```dart
      case Op.las: // M p. 43: AC(Q,P,1-35) unsigned against C(Y)(S,1-35).
```

A flat "cites M, carries no ED label" list would be nearly every case in the file, so here are the three kinds that differ.

## (a) Labelled in the design record, unlabelled in the code — one case

- **LGL, `cpu.dart:318-333`.** Comment: "M p. 32: AC(Q,P,1-35) and MQ(S,1-35) as one register, left; MQ(S) enters AC(35); overflow when a 1 passes into P." The implementation is ED-2a (`emulator.md:190-193`), but the code cites no label, unlike ARS at line 300 ("decision ED-5") or the +0760 check at line 56 ("decision ED-3").

## (b) Discussed in `emulator.md` §6 but never given a label

- **ADD/SUB minus zero** — `emulator.md:167-171` ("Operands of equal magnitude and different signs give a result sign equal to the original AC sign"); implemented in `_addSigned`, `cpu.dart:404-423`, whose doc comment (395-403) restates the whole rule and carries only "decision ED-2" for the overflow half.
- **MPY with a zero factor** — `emulator.md:180-182` ("so −0 results are possible … Implemented exactly"); code `cpu.dart:112-124`, comment "the signs of AC and MQ take the algebraic sign of the product, so a zero product with unlike factor signs yields minus zero."
- **DVP divide check** — `emulator.md:183-185`; code `cpu.dart:125-146`, comment "Division requires |C(Y)| > |AC| over the full 37-bit AC magnitude". The MQ/AC sign split at 140-141 ("MQ sign: the algebraic sign of the quotient; AC sign: the sign of the dividend (unchanged)") is a semantic choice stated only in the code.
- **CVR** — `emulator.md:204-207`; code `cpu.dart:354-383`, including the Q-survival rule at 366-376 and the tag-bit-20 XR1 write at 380-383.

## (c) Semantic choices carried by an M citation alone, with no §6 entry and no label

- **LAS, `cpu.dart:200-210`** — the named case. The choice is that the AC's 37-bit magnitude (Q, P, 1-35) is compared against the *whole* 36-bit word including its S bit as a magnitude bit: `if (state.acMagnitude > y)`. §5's table row (`emulator.md:128`) states the same one-liner; §6 says nothing. Tests pin it (`cpu_transfer_index_test.dart:281-296`, "treats the S bit of Y as a magnitude bit", "Q outweighs any 36-bit word").
- **CAS ± zero and reverse-magnitude ordering, `cpu.dart:181-198`** — "Equal requires equal magnitudes and equal signs; a plus zero is algebraically greater than a minus zero." Only `emulator.md:127`'s table cell ("+0 > −0") carries it.
- **TSX takes an unmodified address, `cpu.dart:219-223`** — "The tag names the target register (M p. 10), so the address takes no modification." Stated nowhere in `emulator.md` (§4's "no address modification" list at 79-88 names type A, SIR/RIR/RFT and CVR, not TSX).
- **AXT/SXA/LXA/LAC read `inst.address` raw, `cpu.dart:245-261`** — none of the four calls `_effectiveAddress`; SXA at 249-253 and LXA at 255 and LAC at 259 use `inst.address` directly. §4 does not list them as unmodifiable either.
- **PDX's field extraction, `cpu.dart:265-270`** — "XR(T) <- AC(3-17); AC unchanged", implemented as `((state.acMagnitude & Word36.magnitudeMask) >> 18) & Word36.fieldMask15`, i.e. Q and P are masked off before the shift. That masking is a reading, not a quoted rule.
- **CAL's bit layout, `cpu.dart:94-97`** — the inline comment "Bit layout matches: S of Y lands in P" asserts that storing `y` whole into `acMagnitude` is the manual's behaviour.
- **ACL preserves Q, `cpu.dart:104-111`** — `state.acMagnitude = (state.acMagnitude & MachineState.acQBit) | sum;` implements "S and Q are not affected" by explicitly re-ORing Q back.
- **XCA clears P and Q, `cpu.dart:160-164`** — "AC(S,1-35) and MQ exchanged; P and Q cleared."
- **The shift count, `cpu.dart:391-393`** — `_effectiveAddress(inst, indirectable: false) & 0xFF`, doc "the effective address modulo 400 octal (M p. 31)". Two choices in one line: 0xFF is 400 octal minus one (a mask, not a modulo of an arbitrary value — identical here), and shifts are indexable but never indirect.
- **COM's mask, `cpu.dart:177-178`** — `~state.acMagnitude & MachineState.acMagnitudeMask`, so the complement covers Q, P and 1-35 and the sign is untouched.

# 6. TEST IDIOM

## `test/emulator/asm.dart` — the whole file is three functions

```dart
int typeB(int operation, {int address = 0, int tag = 0, bool flag = false}) =>
    (operation << 24) | (flag ? 3 << 22 : 0) | (tag << 15) | address;      // :9-10

int typeA(int prefix, {int decrement = 0, int tag = 0, int address = 0}) =>
    (prefix << 33) | (decrement << 18) | (tag << 15) | address;            // :14-15

int data(int magnitude, {bool negative = false}) =>
    (negative ? 1 << 35 : 0) | magnitude;                                  // :18-19
```

`typeB`'s `operation` is "the listing's four-digit signed octal, e.g. `0o4500` for −0500" (asm.dart:7-8) — tests pass it as a hex literal with the octal in a trailing comment (`typeB(0x010, address: 0x300)); // +0020`). The file is a `library;` with no exported class; there is no assembler, no symbolic mnemonics, no relocation.

## The pattern one CPU test uses

`test/emulator/cpu_transfer_index_test.dart:1-20` is the whole harness:

```dart
import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'asm.dart';

void main() {
  late MachineState m;
  late Cpu cpu;

  setUp(() {
    m = MachineState();
    cpu = Cpu(m);
  });

  void runOne(int word) {
    m
      ..write(0x100, word)
      ..ic = 0x100;
    cpu.step();
  }
```

Shape, in order: a fresh `MachineState` and `Cpu` per test via `setUp`; **setup** by cascade on `m` writing operand cells and index registers (`m..xrWrite(1, 3)..write(0x300, typeA(0, tag: 1, address: 0x403));`, lines 37-39); **run** either the local `runOne` for one instruction at the fixed location 0x100, or an explicit `..write(...)..ic = ...` followed by `cpu..step()..step()` for a sequence (lines 66-73); **assert** directly on public state — `expect(m.ic, 0x300)`, `expect(m.xrRead(4), (0x8000 - 0x100) & 0x7FFF)`, `expect(m.acMagnitude, 9)`, `expect(Word36.address(m.read(0x200)), 0x77)`.

Two more conventions worth copying. Each `group` carries a manual citation as a comment above it (`// TSX: 22-6528-4 p. 39 (external).`, line 56), and a test that exists because a review asked for it names the finding (`// TSTC-08: 0x8000 - 0 masks to 0, not 0x8000.`, line 79). A local helper narrows the noise where one opcode repeats: `void cas(int address) => runOne(typeB(0x0E0, address: address));` (line 203).

The throw idiom is in `test/emulator/cpu_sense_convert_test.dart:129-149`: `expect(() => cpu.step(), throwsA(isA<UnimplementedOpcode7090>().having((e) => e.operation, 'operation', '+0000').having((e) => e.location, 'location', 0x150)))`.

Nothing in the emulator tests loads a deck, runs a loop, or counts steps — stage-4 execution tests have no existing precedent to copy for those three.

# 7. GAPS

Things stage 4 needs that no file in the repository provides or settles.

1. **No run loop and no run-until.** Confirmed by grep: `Cpu` is constructed only at its own declaration site outside `test/emulator/`. `emulator.md:16-18` assigns the loop to the caller and stops there.
2. **No end-of-run signal.** `step()` returns `void` (`cpu.dart:47`); there is no halt instruction (`emulator.md:229-231`); STOP is a call to SYS)178/177/IOC)40. So "the program finished" has to be manufactured by the STOP handler, and no record says how it reaches the loop. `m4-codegen.md:899-901` says SYS)294 "exits to the monitor instead of returning" without naming any emulator mechanism for exiting.
3. **No step budget or cycle count.** Nothing counts steps. `decisions.md:839` deliberately preserves non-termination ("the emulator reproduces that non-termination"), which makes a cap a test-harness requirement, not an optional nicety.
4. **Dispatch addresses are unallocated.** `loader.md:135-136`: "The dispatch table is M4-17's and the file blocks are M5's, so no address is fixed here." The constraint the loader imposes is only `_fits` (`loader.dart:358-363`, inside 0..32767). The stage-3 round trip used "the raw 15-bit code as each resolved address" (`loader.md:147-149`, "At origin 0 … memory equals the listing's word image: 936 words, entry 00165"), so raw SYS) numbers 128-296 fall *inside* the loaded program's own text at origin 0 — that scheme cannot survive execution, and no record replaces it.
5. **The entry point is `GN)000` for every program.** `HANDOVER.md:96-97`: "a labeled PROGRAM.START does not yet name the entry point: the end-of-text entry names `GN)000` for every program (D2.1; LD-3)."
6. **No `MachineState` reset.** No `clear()`, no `reset()`, no constructor argument. A second run needs a fresh `MachineState`, and `overflow`/`divideCheck` are never cleared by anything in `cpu.dart`.
7. **No bulk memory load.** Writing `LoadedProgram.words` means iterating the `Map<int,int>` and calling `state.write` per entry; nothing in `MachineState` takes a map, a range, or an image. `codegen`'s program image and the emulator share no loading path.
8. **No way to write a register from outside by number.** XR1/2/4 are addressable only by tag bits through `xrRead`/`xrWrite`; a handler wanting "XR4" writes `xrWrite(4, v)`. That works, but there is no guard against a handler passing a multiple tag by accident — `xrWrite(6, v)` silently writes two registers (`machine_state.dart:85-97`).
9. **`ic` is unvalidated on write.** Setting it out of 15-bit range surfaces as a `RangeError` from `read` on the next step (`cpu.dart:49`), attributed to memory, not to the bad IC.
10. **No disassembler for diagnostics.** `Instruction.operationOctal` (`decode.dart:193`) and `Word36.octal` (`word.dart:76`) give octal only; there is no mnemonic rendering to put in a trace when an execution test fails. (`lib/src/codegen/encode.dart` imports `decode.dart` per `m4-codegen.md:487-489` — "so the OCTAL column has one authority" — so the encode table may be the reusable half of this.)
11. **No record settles what happens when a handler is entered other than by TSX.** M4-17 names SYS)294's TXL entry as the single exception; nothing states the general rule for the dispatcher when XR4 is not a valid return link.