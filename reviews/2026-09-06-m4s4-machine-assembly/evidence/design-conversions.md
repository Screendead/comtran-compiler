# The non-edited MOVPAK handlers and the step-list protocol

Stage 4 design. Scope: the calling-sequence protocol every MOVPAK member obeys,
the two dispatch entries the generator emits, and the four non-edited members
`SYS)184`, `SYS)268`/`269`/`275`, and the movers `SYS)239`–`245`. The edit
algorithm of `SYS)185`, `190`, `193`, `198`, `211`, `212`, `214`, `216`, `225`,
`226` and `267` is another design's; this record fixes only their protocol shape
(which words each owns, where it resumes, what it leaves in index register 1).

**Contamination caveat**, carried from `s4-contracts-b1.md:5`. MOVPAK is the one
runtime deck the D0.9 seal no longer fully covers: `docs/design/decisions.md:332`
lists 28 read lines in the boundary. Nothing below comes from them. Every claim
is from the manual conversions, the repository, or is marked as inference.

**What stage 4 must implement**, and nothing more (CLAUDE.md §11). Entries
`SYS)180`, `182`. Family heads `184`, `185`, `190`, `268`. Steps `193`, `198`,
`211`, `212`, `214`, `216`, `269`. Terminators `225`, `226`, `275`. Movers
`239`, `240`, `241`, `243`, `244`, `245`. The edited store `267`. `SYS)179` and
`SYS)181` have no emitter and no sample site (`s4-contracts-b1.md:106`, `:134`);
do not write them.

---

## A. The step-list protocol

### A.1 The machine facts the protocol rests on

| Fact | Where |
|---|---|
| `TSX Y,T`: `XR(T) ← (0x8000 − location) & 0x7FFF`; `IC ← Y`; the address takes no index modification | `lib/src/emulator/cpu.dart:219–223` |
| `TXI Y,T,D`: `XR(T) ← XR(T) + D` (15-bit wrap); `IC ← Y`, unmodified | `lib/src/emulator/cpu.dart:228–234`; `lib/src/emulator/decode.dart:85` |
| `AXT Y,T`: `XR(T) ← the instruction's own address field` | `lib/src/emulator/cpu.dart:245–246` |
| `TRA Y`: `IC ← effective address`; with tag 0 no register is read | `lib/src/emulator/cpu.dart:213–214` |
| An effective address **subtracts** the index register | `s4-emulator.md`, cited in the task brief |
| The dispatcher decides before `Cpu.step()`: if `state.ic` is a registered entry, run the Dart handler, else step the CPU | `s4-emulator.md`; `docs/design/m4-codegen.md:893–899` |

Calling-sequence addressing follows from the first row. With `TSX` at address
`t`, `xr4 = (0x8000 − t) & 0x7FFF`, so word `k` of the calling sequence
(`k = 0` being the `TSX` itself) sits at `(k − xr4) & 0x7FFF`. That is the
`1,4` / `2,4` / `3,4` of `J 90.02.14`–15 read literally, and it is the rule
`docs/design/m4-codegen.md:479–482` and `:893–896` already record.

### A.2 Session state

The dispatcher holds at most one MOVPAK session while a move runs:

- `cursor` — the absolute address of the calling-sequence word the CPU is about
  to execute, or has just executed to reach the handler now running.
- `source`, `target` — byte cursors (word address, byte 0–5) copied out of the
  `SYS)132` and `SYS)133` memory cells at entry (§B.2).
- family state — the head's number, and for an edited target the edit-control
  bits and the control word.

The cursor is the Dart stand-in for whatever cell the 1962 MOVPAK kept. It is
not a register: index registers 2 and 4 are spoken for (§A.6), and index
register 1 carries the count.

### A.3 The entry handler (`SYS)180`, `SYS)182`)

1. The CPU has already executed `TSX SYS)nnn,4`, so `xr4` is set and `IC` is the
   entry's dispatch address. The handler does not re-derive the link.
2. `SYS)182` takes no parameter word: `cursor = (1 − xr4) & 0x7FFF`.
   `SYS)180` takes one: read `(1 − xr4) & 0x7FFF`, decode it (§B.1), store it
   into the `SYS)133` cell, then `cursor = (2 − xr4) & 0x7FFF`.
3. `state.xrWrite(1, 0)`.
4. Copy both pointer cells into the session's byte cursors, uninterpreted
   (§B.3 says why both, even under `SYS)180`).
5. `state.ic = cursor` and return.

**Off-by-one, stated.** The entry handler leaves `IC` **on** the family head
word and does not execute it. The CPU executes it next.

Entering `SYS)180` or `SYS)182` while a session is already active is a broken
object program: throw. No emitted sequence nests a dispatch.

### A.4 A step or head handler

The CPU executes the word at `cursor`. For `TXI SYS)nnn,1,c` that means
`XR1 += c` (and `XR1` was 0, so `XR1 == c`) and `IC = nnn`'s dispatch address.
The dispatcher then calls the handler for `nnn`, with the session's `cursor`
still pointing at that word.

**Off-by-one, stated.** When any step handler runs, `cursor` is the address of
**its own** `TXI` word, never the next one.

Each handler, in order:

1. **Check.** `session != null` and
   `Word36.address(state.read(cursor)) == state.ic`. Either failure is a broken
   object program — a jump into the middle of a calling sequence, or a cursor
   left un-advanced by the previous step. Throw a Dart error. This is not a
   D4.3 data condition: `decisions.md:682` forbids a Dart exception for
   *improper data*, and says nothing about an impossible instruction stream.
2. **Count.** `count = state.xrRead(1)`.
3. `state.xrWrite(1, 0)`.
4. **Read the data words it owns** (never execute them): the `OCT` after `185`,
   `190`, `245` and `267`; the `AXT`'s address field for `267`.
5. **Advance.** `cursor += 1 + ownedDataWords`.
6. **Work**, then `state.ic = cursor`.

`MachineState.xrWrite` with a compound tag writes several registers silently
(`lib/src/emulator/machine_state.dart:85–98`): pass 1, never 3, 5, 6 or 7.

### A.5 Word shapes, exhaustively

`c` is the cursor when the handler runs. `p` is the number of words the handler
reads as data. Resume is `c + 1 + p` unless the row says otherwise.

| Shape | Members | `p` | Resume | XR1 at resume | Ends the move |
|---|---|---|---|---|---|
| bare step `TXI SYS)nnn,1,count` | 193, 198, 211, 212, 214, 216, 269 | 0 | `c+1` | 0 | no |
| head + control word | 185, 190 | 1 (`OCT`) | `c+2` | 0 | no |
| terminator | 225, 226, 275 | 0 | `c+1` | 0 | **yes** |
| one-word convert or mover | 184, 239, 243, 244 | 0 | `c+1` | 0 | **yes** |
| mover pair, first word | 240 | 0 | `c+1` | 0 | no |
| mover pair, last word | 241 | 0 | `c+1` | 0 | **yes** |
| fill with characters | 245 | 1 (`OCT`) | `c+2` | 0 | **yes** |
| edited store | 267 | 1 (`OCT`) + the `AXT` read but not consumed | `c+2`, the `AXT` | 0 at resume; the CPU's `AXT` then loads the digit count | **yes** |

Attested resumes, each the word after the last word of the call:
`TXI SYS)225,1,5` at LOC 00611 → `CLA 3)HOURS` at 00612
(`comtran-manuals/J28-6169/90.05-sample-program.md:1126–1127`);
`TXI SYS)275,1,5` at 01361 → `STO 3.RS)1` at 01362 (`:1586–1587`);
`TXI SYS)226,1,7` at 01377 → `TSX IOC)9,4` at 01400 (`:1600–1601`);
`TXI SYS)239,1,15` at 01353 → `LDI CP)+59` at 01354 (`:1580–1581`);
`TXI SYS)245,1,6 / OCT 747474747474` at 00346–00347 → `TRA* END.OF.MASTERS` at
00350 (`:924–926`).

### A.6 `TRA SYS)267,0,0`

One of the 26 `SYS)267` sites punches a real transfer, not the step's `TXI`,
because its edit control computes to zero: `0020 00 0 00413` at LOC 01327
(`90.05-sample-program.md:1560`; `lib/src/codegen/procedure.dart:2127–2141`
emits both forms, the operand text at `:2136`). The CPU executes it as `TRA` with tag 0: no index register is
read or written, so `XR1` is still the 0 the entry handler wrote, and the
handler reads control 0 — the same value the `TXI` form would have produced.

*Inference, marked.* This site does not **prove** the zeroing rule: `TXI …,1,0`
and `TRA` are equal in effect whatever `XR1` holds. It shows only that the 1962
compiler treated the two as interchangeable, which the zeroing rule makes
exactly true and any accumulating rule makes true only by accident.

### A.7 `SYS)267`'s `AXT`: resume at it, do not consume it

**Recommendation: resume at `c+2` and let the CPU execute the `AXT`.** The
handler still *reads* `Word36.address(state.read(c + 2))` for the digit count,
because it needs the count before the CPU runs the word.

Reason. `lib/src/codegen/procedure.dart:355–359` builds the whole register-cache
model on the claim that a MOVPAK sequence's trailing `AXT n,1` "is the only
register write". Letting the CPU execute it makes that claim literally true in
the emulator instead of simulated by a handler-side `xrWrite`, and it is one
line less code. Program-invisible either way: `XR1` ends at the digit count and
`IC` at `c+3` under both. See §F.9 for the rejected alternative.

### A.8 Register contract

- A MOVPAK entry or step handler writes **index register 1 only**, and leaves it
  0, except `SYS)267` where the CPU's `AXT` leaves the digit count.
- **XR2 must survive.** `_assignRegister` hands out registers 1 and 2 and
  refuses a third (`lib/src/codegen/procedure.dart:993–1001`), and
  `_movpakClears()` drops register 1 alone from the cache
  (`:1044–1050`), so generated code addresses `NAME,2` across a dispatch and
  never re-emits the `LAC BL)n,i` load.
- **XR4 must survive** the value the CPU's `TSX` wrote: every resume address and
  the `SYS)180` parameter fetch are computed from it, and codegen never holds a
  locator there.
- The run-frame entries `SYS)175`, `177`, `178` and the IOCS calls are followed
  by a full cache clear (`_callClears()`, `:1076`) and may clobber freely. That
  licence does not extend to MOVPAK.

**Contract test** (`test/emulator/movpak_protocol_test.dart`). Build one program
per row of §A.5 with `test/emulator/asm.dart`'s `typeA(prefix, {decrement, tag,
address})`, `typeB(operation, {address, tag})` and `data(magnitude)`. Preload
`XR2 = 0o7777` and `XR1 = 0o1234` (junk the entry must discard). Run to the
resume and assert, per case:

1. `state.xrRead(2) == 0o7777`;
2. `state.xrRead(4) == (0x8000 − t) & 0x7FFF`, `t` the `TSX`'s address;
3. `state.ic` equals the row's resume address;
4. `state.xrRead(1)` equals the row's XR1 value;
5. the session is closed exactly on the rows marked "ends the move".

Two negative cases in the same file: a step entered with no session, and a step
whose cursor word addresses a different entry. Both throw.

---

## B. `SYS)180` against `SYS)182`, and the pointer cells

### B.1 `PZE LOC,,BYTE`

Address field = the word address; decrement = the byte, 0 to 5
(`90.02-generated-code.md:678`, `:420`, `:467`). Byte 0 is the **high-order**
character of the word: the data-image builder writes character `pos` at
`shift = (5 − pos % 6) * 6` (`lib/src/data/images.dart:480–485`), and the
codegen's shift arithmetic uses `6 * byte` from the left
(`lib/src/codegen/procedure.dart:2395`, `:2411`). Decode with
`Word36.address` and `Word36.decrement`
(`lib/src/emulator/word.dart:51`, `:57`).

### B.2 The cells are machine memory, not Dart state

`SYS)132` and `SYS)133` are words at the addresses the loader's resolver assigns
(`lib/src/loader/loader.dart:55`, `typedef SystemReferenceResolver`). Generated
code writes them with real instructions — `SLW SYS)132` and `STI SYS)133`,
punched as `0602 00 0 00204` and `0604 00 0 00205`
(`90.05-sample-program.md:1112`, `:1117`) — so a handler must read them through
`state.read(resolve(132))`, never from a Dart field. In the sample's load
`SYS)n` resolves to absolute address `n` (00204 = 132, 00205 = 133, 00266 = 182,
00270 = 184, 00413 = 267), which is the natural resolver for us too. Whatever it
is, the dispatcher and the loader must be handed the same one.

`SYS)130` and `SYS)131` are the same kind of word (`90.02-generated-code.md:412`,
`:414`). They stay sticky and are never cleared (D4.2,
`docs/design/decisions.md:661`; D4.3, `:674`). In an I/O-free stage-4 program
`SYS)130` is never armed: none of the reachable handlers carries a counted
overflow-test step (D4.2's arming set is `195`, `196`, `199`, `201`, `203`,
`204`, `270`, `277`, `281`, and codegen emits none of them —
`_editSteps` refuses the bypass case outright,
`lib/src/codegen/procedure.dart:2051`).

### B.3 Which parameter form the generator emits

The manual gives three address-reference forms:
`PZE LOC,,BYTE` (working storage, `:678`), `MZE BL)NN,,CP)+NN` (base-located,
`:690`), `MON PI)NN,,0` (positional indicator, `:698`).

**Our generator emits `PZE` only.** `_pze` refuses a located item before it
reads anything — `if (_located(item)) { _unruled('an in-line address word for a
located item (catalogue 4.3)'); }` (`lib/src/codegen/procedure.dart:579–584`) —
and the comment at `:576–578` records that all 25 sites name a fixed location.
So the handler decodes address and decrement and does not branch on the prefix.
A prefix guard would duplicate a refusal that already stands at the only place
that can produce the word, and §11 bans a branch no run reaches. Judgment call,
recorded: the cost of being wrong is a silent mis-decode of a word the compiler
cannot emit.

### B.4 The register source under `SYS)180`

`90.02-generated-code.md:709`: the source "has been previously stored in
SYS)132, or the source item is in a machine register (AC or MQ)". All 25
`SYS)180` sites are the second case — the edited store
`CLA source / TSX SYS)180,4 / PZE target,,byte / TXI SYS)267,1,edit / OCT
control / AXT digits,1` (`90.05-sample-program.md:962–966`;
`lib/src/codegen/procedure.dart:2105–2147`) — so the `SYS)132` cell is **stale**
under `SYS)180` and must not be interpreted.

The entry handler therefore copies both cells into the session without
interpreting either, and the family head decides which side is a register:
`184` — memory source, register target; `267` — register source, memory target;
`268` — memory source, register target; `239`–`245` — both memory.

---

## C. `SYS)184` — external decimal to internal decimal

`TXI SYS)184,1,NUMBER-OF-CHARACTERS-TO-CONVERT`
(`90.02-generated-code.md:788`). "converts from external decimal to internal
decimal leaving results in the AC or AC-MQ. The sign is assumed over the low
order digit." (`:791`). Three sites, all count 3
(`90.05-sample-program.md:1114`, `:1654`, `:1669`). Codegen emits
`_txi(184, _sem(source).digits)` and stores with one `STO`
(`lib/src/codegen/procedure.dart:2003–2009`).

### C.1 Which codes are digits

From the D0.6 table `lib/src/chars/char_code.dart`:

| BCD | What it is | Where |
|---|---|---|
| `0x00`–`0x09` | the digits `0`–`9` | `char_code.dart:142–143`, `_glyphs` index 0–9 |
| `0x30` | blank | `char_code.dart:20`, `bcdBlank` |
| `0x11`–`0x19` | a 12-punch (zone 1) over digits 1–9 — glyphs `A`–`I` | `char_code.dart:48–56`, `:117–122`, `:142` |
| `0x1A` | 12-0, "plus zero" | `char_code.dart:167–173`; digit part 10 = row 0 under a zone, `:83–84` |
| `0x21`–`0x29` | an 11-punch (zone 2) over digits 1–9 — glyphs `J`–`R` | same |
| `0x2A` | 11-0, "minus zero" | `char_code.dart:167–173` |

The J field-type chart admits "digits and leading blanks" in an external-decimal
field (`docs/comtran-language-definition.md:1198`), so a blank is a leading zero
position. Its low four bits are 0, so the value rule of §C.3 already yields 0
with no special case.

### C.2 The overpunch sign

The sign rides on the rightmost character only: "The only sign specification
which may be used for an external decimal field is an overpunched + or - in the
rightmost position of the field. A + and - may not appear in the character by
itself." (`J 02.05.05` note 1, quoted at
`docs/comtran-language-definition.md:1206` and `:1269`). Zone 1 is the 12 punch
and means **plus**; zone 2 is the 11 punch and means **minus** — the zone
assignment is `char_code.dart:48–56` and D8.1's card codes
(`docs/design/decisions.md:1221`).

Decode of the last character: `zone = bcd >> 4`, `digitPart = bcd & 0xF`, and
`digit = digitPart == 10 ? 0 : digitPart` (10 is row 0 read as a digit under a
zone, `char_code.dart:83–84`).

- zone 0, `0x00`–`0x09` → sign plus, that digit.
- zone 1 → sign plus; `0x1A` → plus, digit 0.
- zone 2 → sign minus; `0x2A` → minus, digit 0.
- anything else (zone 3, the row-0 zone: `S`–`Z`, `,`, `(` …) → not a documented
  overpunch: sign plus, D4.3 applies (§C.3).

A minus-overpunched zero yields a 7090 minus zero — `acSign == 1` with
`acMagnitude == 0` (`lib/src/emulator/machine_state.dart:34`, `:37`, `:60`).
The machine represents it and no rule forbids it.

### C.3 Invalid characters (D4.3)

`docs/design/decisions.md:674–682`: no program-level reaction, no object-time
message; the numeric MOVPAK members set `SYS)131` non-zero and continue; "the
low-order four bits of the 6-bit BCD character are taken as the digit value, and
zone bits that are not a documented overpunch sign are ignored"; "do not raise a
Dart exception and do not stop the run".

Taken literally this needs no clamp. Internal decimal is a **binary** integer, so
accumulating `value = value * 10 + (bcd & 0xF)` carries a low-four-bits value of
10 to 15 (from, say, `.` = `0x1B`) straight into the binary result. Only the
sign position needs the `digitPart == 10 → 0` rule of §C.2, because there row 0
means the digit zero and not the value ten.

See §G.2: D4.3's *trigger* as written would also arm on the legal leading blanks
of `:1198`. That is an amendment candidate, not a decision to take here.

### C.4 The result and its scale

The result is the digit string as an unsigned binary integer, with the decoded
sign in `acSign`. **The handler is not told the scale.** No word of the calling
sequence carries one (`s4-contracts-b1.md:389`, GAP 14), and the site confirms
the unscaled reading: `DETAIL HOURS 99V9` (3 digits, scale 1,
`90.05-sample-program.md:250`) converts with count 3 and stores into
`WORKING HOURS IR99V9` (`:363`) — the same scale on both sides, so no
adjustment is possible or needed. Scale alignment is codegen's, in the emitted
`LRS`/`DVP`/`ACL` tails of D4.1(a) and (c) (`docs/design/decisions.md:640–644`).

### C.5 AC against AC-MQ

The selector is the digit count: "Fixed point double precision numbers are
denoted in the Data Description by formats representing more than 10 digits"
(`docs/comtran-language-definition.md:1285`, `:1562`), and the count in the
decrement is the handler's only digit count. Order is fixed and attested —
`SYS)166`: "On entry to the routine, the high order part of the number is in the
MQ and the low order in the AC" (`90.02-generated-code.md:548`), which is
D4.1(c)'s MQ-high / AC-low (`docs/design/decisions.md:642`). *Inference,
marked:* nothing states that the **count** is what selects.

**But the branch is unreachable and must not be written.** The 184 path stores
with a single `STO` and has no digit test
(`lib/src/codegen/procedure.dart:2003–2009`), while `_internalMove` already
refuses double precision on the sibling path
(`:2160–2163`). Recommendation, in order:

1. Codegen refuses a source or target of more than 10 digits on the 184 path
   with `_unruled`, in the shape `:2160–2163` already uses.
2. The handler throws on `count > 10`, asserted by one decision-conformance
   test. That is the "not exercised, tested" quadrant of CLAUDE.md §11, which
   is permitted; the plan for a caller is M5 or later, when a two-word store
   shape exists.
3. The split radix stays open (§G.1).

---

## D. `SYS)268` / `269` / `275` — edited field to a register

Calling sequence: `TXI SYS)268,1,1` (`90.02-generated-code.md:1670`),
"converts an edited field to internal decimal leaving the results in the AC-MQ.
This instruction is followed by two or more of the following instructions:"
(`:1673`), menu at `:1676–1691`, terminator
`TXI SYS)275,1,TARGET-DECIMAL-NUMERIC-LENGTH` (`:1682`).

The one site (`90.05-sample-program.md:1583–1587`):

```
01356  TSX  SYS)182,4
01357  TXI  SYS)268,1,1
01360  TXI  SYS)269,1,5
01361  TXI  SYS)275,1,5
01362  STO  3.RS)1
```

Our emitter is `_editedFetch` (`lib/src/codegen/procedure.dart:2505–2517`),
which passes `_sem(source).digits` to both `269` and `275`.

### D.1 What the source is

`SYS)132` here is `CP)+59 = PZE 3)BONDENOMINATION,,0`
(`90.05-sample-program.md:1862`), i.e. `BONDORDER BONDENOMINATION`, pictorial
**`899V99`** (`:355`, statement 107,00). Five character positions, five digit
positions, no insertion character. An edited field in general holds digits,
suppressed positions (the `8` and `*` positions, which print blank or asterisk),
and the insertion characters `. , $ * + -`
(`docs/comtran-language-definition.md:1200`;
`90.02-generated-code.md:826–832`).

### D.2 What `SYS)269` counts

**Decision (DECIDED, amendable): digit positions, not storage positions.** The
handler walks the source cursor, consumes `count` **digit** positions, and steps
over an insertion character without counting it. A blank is a suppressed digit
worth 0.

Grounds. Codegen emits `_sem(source).digits` at `procedure.dart:2515`, and the
same digit-count rule at `:2058` for the `SYS)198` move step of the EF→EF
family. The site cannot separate the readings: `899V99` has five digits **and**
five characters. Under the storage-character reading, a source such as
`$8,889.99` (6 digits, 9 characters) would be under-consumed by our own
generator. If codegen ever emits storage characters, that is the amendment.

The handler has no source control word to tell it which positions are
insertions — the calling sequence carries a **target** control word only
(`:834`) — so it classifies each character as it reads it. That is a
consequence of the manual's shape, not a choice.

### D.3 What `TARGET-DECIMAL-NUMERIC-LENGTH` means for a register target

It is the digit count of the value delivered. Two independent lines of evidence:

**The terminator's count is digits, not characters.** `TXI SYS)226,1,7` against
target `88889.99` — 8 character positions, 7 digits
(`90.05-sample-program.md:1600`, description at `:315`).
`TXI SYS)225,1,5` against `8889.9` — 6 characters, 5 digits (`:1126`, `:300`).
`TXI SYS)225,1,6` against `8889.99` — 7 characters, 6 digits (`:1650`;
`docs/design/decisions.md:778` identifies the pictorial).

**The step counts sum to it.** Leading zeros plus moved digits equal the
terminator's length at every site: 2 + 3 = 5 (`:1124–1126`), 2 + 5 = 7
(`:1375–1377`), 3 + 3 = 6 (`:1461–1463`), and for the register target
5 = 5 (`:1585–1586`).

So for a register target the length is the value's digit count, and it is the
handler's AC-versus-AC-MQ selector — the run-time analogue of
`CONTROL-WORD-TYPE-ID`'s "Numeric length of value"
(`90.02-generated-code.md:1497`). *Inference, marked.*

The entry says the result is left "in the AC-MQ" (`:1673`) while the site stores
it with `STO`, which stores the accumulator alone (`:1587`;
`s4-contracts-b2.md:318` records the contradiction). Our rule resolves it: at 5
digits the value is in the AC, and `STO` is right. §C.5's ban applies unchanged
— `_editedFetch` parks with one `STO` (`procedure.dart:2486–2489`), so codegen
refuses a source of more than 10 digits and the handler throws.

### D.4 `SYS)268`'s literal decrement `1`

Unexplained. Every sibling family head carries a sign convention or an edit
control; this one carries a bare 1 (`90.02-generated-code.md:1670`;
`s4-contracts-b2.md:370`, G10). The handler reads it and ignores it. No
speculation. §G.4.

### D.5 D4.3 for an edited source

A character that is not a digit, not a blank, not one of the insertion
characters, and not (in the last position) a documented overpunch, arms
`SYS)131` and contributes its low four bits, and the run continues
(`docs/design/decisions.md:674–682`). Same accumulation as §C.3.

---

## E. The alphameric movers

All four move through byte cursors and cross word boundaries freely; the target
cursor starts at `SYS)133`'s `LOC,,BYTE` and steps one character at a time.

### E.1 `SYS)239` — equal length

`TXI SYS)239,1,NUMBER-OF-CHARACTERS-TO-MOVE` (`90.02-generated-code.md:1367`),
"moves alphabetic fields to alphabetic fields" (`:1370`). Codegen emits it when
the two storage extents are equal, count = the extent
(`lib/src/codegen/procedure.dart:2431–2440`). Two sites, both count 15
(`90.05-sample-program.md:1398`, `:1580`). Copy `count` characters source to
target.

### E.2 `SYS)240` + `SYS)241` — shorter source, blanks **trailing**

`TXI SYS)240,1,NUMBER-OF-CHARACTERS-TO-MOVE` (`:1375`), "with additional blank
insertion" (`:1378`); `TXI SYS)241,1,NUMBER-OF-BLANKS-TO-INSERT` (`:1383`).
Codegen emits `240` with the source extent and `241` with the difference
(`procedure.dart:2436–2439`); sites at `90.05-sample-program.md:879–880`
(21 then 2) and `:900–901` (15 then 8).

**The blanks go after the moved characters.** `J 02.04.03`, quoted at
`docs/comtran-language-definition.md:1769`: "If the sending area is the smaller,
the data will be left-justified in its new location. The low-order positions of
the receiving area, i.e., the excess positions, will be filled with blanks."
The blank is `bcdBlank`, `0x30` (`lib/src/chars/char_code.dart:20`).

`SYS)240` does not end the session; `SYS)241` does (§A.5). The pair is one
move, and `241`'s handler must throw if the session's head is not `240` — the
same broken-program class as §A.4's check.

### E.3 `SYS)243` — blanks

`TXI SYS)243,1,NUMBER-OF-BLANKS-TO-INSERT` (`90.02-generated-code.md:1411`),
"moves blanks to an alphabetic field" (`:1414`). The count is the target's full
character extent, not its digit count
(`lib/src/codegen/procedure.dart:2245–2258`; D4.11,
`docs/design/decisions.md:778–784`). Eight sites. Write `bcdBlank` `count`
times.

### E.4 `SYS)244` — zeros

`TXI SYS)244,1,NUMBER-OF-ZEROS-TO-INSERT` (`:1422`), "moves zeros to an
alphabetic field" (`:1425`). Three sites, all count 54
(`90.05-sample-program.md:789`, `:793`, `:1095`).

The zero is the **character** `0`, BCD `0x00` —
`lib/src/chars/char_code.dart:142–143` puts `'0'` at index 0, and `:106–107`
punches it as a bare row-0. Write it `count` times. A full-word run of it is
bit-identical to a zero word, so the distinction bites only on a partial first
or last word.

### E.5 `SYS)245` — six characters, cycled

```
TXI     SYS)245, 1, NUMBER-OF-CHARACTERS-TO-INSERT
OCT     CHARACTERS
```
(`90.02-generated-code.md:1430–1431`), "moves characters to an alphabetic field.
The second word contains 6 characters of the type to be moved." (`:1434`). Both
sites are count 6 with `OCT 747474747474`
(`90.05-sample-program.md:924`, `:953`). `0o74 = 0x3C`, which is `(`
(`char_code.dart:142–143`, index 60) — the native-sequence HIGH.VALUE of D8.1
(`docs/design/decisions.md:1221`; `docs/comtran-language-definition.md:407`).

A count other than 6 **is reachable**: `_figurativeFill` passes
`_sem(item).storageChars` (`lib/src/codegen/procedure.dart:2240–2248`), so any
HIGH.VALUE or LOW.VALUE target whose extent is not 6 produces one.

**Decision (DECIDED, amendable): cycle.** Target position `i` takes character
`i mod 6` of the `OCT` word. Grounds: the entry calls the word "6 characters of
the **type** to be moved" — a repeating pattern, not a positional image; cycling
is the only rule that answers `count > 6` without a second parameter; and at
both attested sites (six copies of one character) cycling and every rival agree.
Rejected: (a) take character 0 and ignore the other five — it makes five sixths
of a documented word dead and contradicts "6 characters"; (b) truncate at 6 —
it leaves a longer target partly unwritten and no entry mentions truncation.
The choice is currently unobservable, because `_fillWord` emits six copies of
one character (`procedure.dart:2260–2270`); it becomes observable the day a
mixed fill word is emitted.

### E.6 The chars helpers to reuse

`lib/src/chars/char_code.dart` is the whole public surface (D0.6). Its members:

| Member | What it maps | Line |
|---|---|---|
| `rowBit12`, `rowBit11`, `rowBit0`, `rowBitDigit(d)` | punch-row bits in a 12-bit column | `:11`, `:14`, `:17`, `:26` |
| `bcdBlank` = `0x30`, `bcdGroupMark` = `0x1F` | the two named codes | `:20`, `:23` |
| `bcdFromPunches(punches)` | punch pattern → BCD, or null | `:38` |
| `punchesFromBcd(bcd)` | BCD → canonical punch pattern, or null for octal 35 | `:104` |
| `glyphFromBcd(bcd)` | BCD → Set H glyph, or null | `:147` |
| `bcdFromGlyph(glyph)` | Set H glyph → BCD, or null | `:155` |
| `machineSpecialName(bcd)` | `0x1A` plus zero, `0x1F` group mark, `0x2A` minus zero, `0x3A` record mark | `:165` |
| `isGlyphColumn(punches)` | whether a mirror glyph line can carry the column | `:178` |
| `cardCodeFromPunches` / `punchesFromCardCode` | row-name text ↔ punch pattern | `:192`, `:207` |

Handlers need `bcdBlank`, the zone/digit split (arithmetic on the code, as
`:48–66` does), and `glyphFromBcd` in test assertions. **Never write a second
BCD table**; `encode.dart` refuses one.

Nothing public packs or unpacks six characters per word: `_setChar` is private
to the data-image builder (`lib/src/data/images.dart:480–485`) and writes into a
local word list, not `MachineState`. Write one small mutable byte cursor in the
handler file — word address plus byte, `int read()` and `void write(int bcd)`,
both advancing across the word boundary — and give it the several callers above.
Do not add it to `lib/src/chars/`: that library is the code ↔ punch ↔ glyph
table, and a memory cursor is not that.

---

## F. Rejected readings

**F.1 A step handler reads its count from its own `TXI` word in memory, not from
XR1.** Refuted by the machine: a step is entered by a `TXI`, which writes no
link (`cpu.dart:228–234`), so the routine has no address for its own calling
word. Index register 1 is the only channel that can carry the count. Our Dart
cursor is a stand-in for MOVPAK's internal cell, not evidence that the routine
could address the word. The two readings give the same number in every emitted
sequence; the XR1 read is the one that can detect a broken zeroing invariant.

**F.2 XR1 is not zeroed, and each step recovers its count by subtracting the
previous one.** Nothing in a calling sequence tells a step what the previous
count was, and the sample's steps run both up and down — 2 then 3
(`90.05-sample-program.md:1124–1125`), 2 then 5 (`:1375–1376`) — so no
difference rule recovers them. Not refuted by the manual, which is silent
(`s4-contracts-b1.md:376`, GAP 1).

**F.3 MOVPAK interprets its calling sequence and never executes the `TXI` words
at all** — an entry reading each word through its own cursor and dispatching on
the address field internally, leaving XR1 untouched. **Not refuted.** It may be
what the 1963 code does. It is program-invisible here: `_movpakClears()` drops
register 1 from the cache after every sequence
(`lib/src/codegen/procedure.dart:1044–1050`), so no generated word reads XR1
after a MOVPAK call, and `SYS)267`'s trailing `AXT` rewrites it anyway.
Rejected on cost only: the execute model reuses the CPU's `TXI` and the
dispatcher's existing intercept-by-address, and needs no interpreter loop.

**F.4 The terminator's count is the target's character length.** Refuted by the
sample twice over: `TXI SYS)226,1,7` against `88889.99`, 8 characters and 7
digits (`90.05-sample-program.md:1600`, `:315`); `TXI SYS)225,1,5` against
`8889.9`, 6 characters and 5 digits (`:1126`, `:300`). And by the sum rule of
§D.3.

**F.5 `SYS)241`'s blanks lead.** Refuted by `J 02.04.03` as quoted at
`docs/comtran-language-definition.md:1769`: the data is left-justified and "the
low-order positions of the receiving area, i.e., the excess positions, will be
filled with blanks."

**F.6 `SYS)244` writes zero words.** Refuted by its own entry: it "moves zeros
to an **alphabetic field**" (`90.02-generated-code.md:1425`), and the count 54
at `90.05-sample-program.md:789` is a character count on a 54-character target.
The character is BCD `0x00`, whose glyph is `0` (`char_code.dart:142–143`).

**F.7 The `SYS)180` parameter word may be `MZE` or `MON`.** Both forms are
printed (`90.02-generated-code.md:690`, `:698`) and neither is reachable: `_pze`
refuses a located item (`lib/src/codegen/procedure.dart:576–582`) and no
positional-indicator form of the in-line word exists in the emitter. Stage 4
decodes `PZE` only, with no prefix branch (§B.3).

**F.8 `SYS)184`'s result carries the pictorial's scale.** Refuted by the calling
sequence, which carries one count and no scale
(`90.02-generated-code.md:788`), and by the site, where source and target share
a scale (§C.4). The alignment is in emitted words, D4.1(a) and (c).

**F.9 `SYS)267`'s `AXT` is a parameter the handler consumes.** Not refuted —
program-invisible, since XR1 ends at the digit count and IC at `c+3` either way.
Rejected because executing it makes `procedure.dart:355–359`'s claim (the
trailing `AXT` "is the only register write") true in the emulator rather than
simulated, and costs one line less.

**F.10 A data condition should throw.** Refuted by D4.3:
`docs/design/decisions.md:682` — "do not raise a Dart exception and do not stop
the run". Only an impossible instruction stream throws (§A.4).

---

## G. Open items — decisions to record

**G.1 The AC / AC-MQ split radix.** `SYS)166` fixes the order — high in the MQ,
low in the AC (`90.02-generated-code.md:548`) — and nothing fixes the radix.
D4.1(c)'s evidence is a `DVP` by `10^t` where `t` varies by site
(`docs/design/decisions.md:642`), which is a truncation trick, not a canonical
layout. No unsealed evidence survives (D0.9). **Recommendation:** codegen
refuses more than 10 digits on the `SYS)184` and `SYS)268` paths, the handler
throws, and stage 4 needs no radix. Revisit when a two-word store shape exists.

**G.2 D4.3's trigger against the J field-type chart.** The chart admits "digits
and leading blanks" for external decimal and blanks plus insertion characters for
edited (`docs/comtran-language-definition.md:1198`, `:1200`), while D4.3's
trigger arms `SYS)131` on "a character that is not a valid digit"
(`docs/design/decisions.md:674`). Read literally, legal data arms the cell.
**Recommendation:** amend D4.3 to exempt the blank and the edit-insertion set.
This is an amendment, not a §6 peer collision: D4.3 marks the trigger amendable
under D0.4 and says the definition of "improper data condition" is unresolved.
D4.3's *value* rule needs no amendment (§C.3).

**G.3 Whether the advanced pointers are written back to `SYS)132` / `SYS)133`.**
Unstated (`s4-contracts-b1.md:388`, GAP 13). **Recommendation:** not written
back; the cells keep what the caller set. Every site presets both cells before
the next call (`90.05-sample-program.md:1344–1352`, `:1366–1372`), so no
emitted word can observe the difference.

**G.4 What `SYS)268`'s literal decrement `1` means.** Read and ignored. No
unsealed evidence survives (D0.9). §D.4.

**G.5 Whether `SYS)269` and `SYS)198` count digit positions or storage
characters.** Chosen: digit positions (§D.2). The one site cannot discriminate:
its source `899V99` has five of each (`90.05-sample-program.md:355`, `:1585`).

**G.6 Whether `SYS)245` cycles its six characters.** Chosen: cycle (§E.5). Both
sites are count 6 (`90.05-sample-program.md:924`, `:953`). No unsealed evidence
survives (D0.9).

**G.7 Whether a blank inside a numeric source is a zero or an improper data
condition.** Chosen: a suppressed digit worth zero, with no arming. Depends on
G.2.

**G.8 Codegen observation, out of scope, no fix here.** The `SYS)184` path calls
`_loadBaseOf(target)` and emits the store *before* `_movpakClears()`
(`lib/src/codegen/procedure.dart:2003–2009`). If the register cache says index
register 1 holds the target record's base locator, `_loadBase` emits nothing
(`:1017–1021`) and the following `STO target,1` runs after the CPU's
`TXI SYS)184,1,n` has overwritten index register 1 with the digit count. No
sample site is located on that path, so listing-diff cannot show it.

---

## Tests this design asks for

| Test | Asserts | Kind |
|---|---|---|
| `movpak_protocol_test`, one case per §A.5 row | XR2 preserved, XR4 = the `TSX` link, IC at the resume, XR1's final value, session closed on the right rows | contract |
| same file, two negative cases | a step with no session throws; a step whose cursor word addresses another entry throws | contract |
| `SYS)180` parameter | `PZE LOC,,BYTE` decodes to word and byte, byte 0 is the high-order character; the cell at `resolve(133)` holds it | decision-conformance |
| `SYS)184` conversion | plain digits; leading blanks as zeros; a 12-punch last character gives plus; an 11-punch gives minus; `0x2A` gives minus zero (`acSign == 1`, magnitude 0); an invalid character arms `SYS)131`, contributes its low four bits, and does not throw | decision-conformance |
| `SYS)184` and `SYS)268` over-length | count > 10 throws | decision-conformance |
| `SYS)268`/`269`/`275` | the attested five-digit fetch reproduces the site's value in the AC; an insertion character in the source is skipped and not counted | decision-conformance + listing-diff for the emitted words |
| movers | `239` equal length; `240`+`241` with trailing blanks; `243` blanks; `244` BCD `0x00`; `245` count 6 exact and count 8 cycling; every case crossing a word boundary | decision-conformance |
