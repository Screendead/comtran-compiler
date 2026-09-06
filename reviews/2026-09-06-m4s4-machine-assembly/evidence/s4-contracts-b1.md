# MOVPAK contracts, SYS)179 – SYS)218, from [J 90.02]

Source of every quote below unless marked otherwise: `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/90.02-generated-code.md`. Scan checks: `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/images/page-154.png`, `page-155.png`, `page-156.png`, `page-157.png`, `page-159.png` (PDF pages 154–159 = sections 90.02.15–90.02.20).

**Contamination caveat.** MOVPAK is the one runtime deck the D0.9 seal no longer fully covers. `docs/design/decisions.md:332` lists in the boundary "28 lines of MOVPAK, which include a prologue, a loop entry, and a conditional error transfer", and `decisions.md:342` says "MOVPAK is partly contaminated: 28 lines of its logic were read. … Treat both as contaminated at M7". Nothing from those lines is used or reproduced here; everything below is from the manual and the repository records.

---

## MOVPAK STRUCTURE

### What the manual says MOVPAK is

`90.02-generated-code.md:386`: "Many of the SYS Reference numbers are concerned with subroutines to move fields at object time. The interaction of various of these 'MOVE' subroutine made it desirable to package several of them together into one subroutine (called MOVPAK)."

The class abbreviations the entries use are defined at `:388`–`:402`: **AF** "Alphameric Field (pictorial contains only A's and X's)"; **XD** "External Decimal (pictorial contains only 9's, S's, V and 9⁺ or 9̅)"; **ID** "Internal Decimal (pictorial contains only 9's, S's, V; R given as mode and justification)"; **IDnj** "Internal Decimal not justified"; **EF** "Edited Field (pictorial contains one or more of the following characters: 8 + - . , \* or the clause Blank When Zero"; **SD** Scientific Decimal; **FP** Floating Point; **BL/ZE/HV/LV** the figurative constants.

### How an entry is selected — **not** SYS)179+n

There is no `SYS)179+n` dispatch. Two mechanisms compose:

1. **Which of four TSX entry points is called** (SYS)179–182) is decided *only* by which of the two pointer cells the calling sequence must set. All four run the same package.
2. **Which move is performed** is named by the *address field of an in-line `TXI` word* that follows the `TSX`. The family head (SYS)183–190, plus 246–258, 267–268 outside this range) names the source→target class pair; the step words (SYS)191–218 and 219–238) name one counted operation each. The count rides in the `TXI` **decrement**, and every step word is tagged **index register 1**.

`TXI` machine semantics, from the repository's emulator: `lib/src/emulator/decode.dart:85` — "TXI. XR(T) ← XR(T) + D; IC ← Y. Octal +1, type A (M p. 39)."; `lib/src/emulator/cpu.dart:228`–`234` implements `state.xrWrite(inst.tag, (state.xrRead(inst.tag) + inst.decrement) & Word36.fieldMask15); state.ic = inst.address;`. So a step word both *adds its count into XR1* and *transfers into the named routine*. The manual never says XR1 is zero on entry to a step — see GAPS.

### Return-skip convention

Stated per entry, and only as the address MOVPAK resumes at:

| Entry | Parameter words | Manual's resume text | Line |
|---|---|---|---|
| SYS)179 | 2 (source + target address references) | "the instructions beginning at 3,4 are executed to actually perform the moving operation" | `:670` |
| SYS)180 | 1 (target address reference) | "the specific MOVE instructions beginning at 2,4 are executed" | `:709` |
| SYS)181 | 1 (source address reference) | "the specific Move instructions beginning at 2,4 are executed" | `:719` |
| SYS)182 | 0 | "The specific Move instructions are executed beginning at 1,4." | `:728` |

Scan-verified for 180/181/182 on `page-154.png`. The rule the generator uses is recorded at `docs/design/m4-codegen.md:479`–`482`: "The MOVPAK dispatch entries and their return-skip convention: SYS)179 (both descriptors in the calling sequence, resume 3,4), SYS)180 (target only, 2,4), SYS)181 (source only, 2,4), SYS)182 (both preset, 1,4) — resume offset is parameter-word count plus one ([J 90.02.14]–15)." `docs/design/m4-codegen.md:893`–`895` binds handlers to it: "a TSX-linked handler reads its calling sequence through XR4, honors the resume convention (parameter-word count plus one), and returns control".

Nothing in the manual states where a *step* subroutine (183–218) returns to, nor where control goes after the terminator word.

### Parameter words and their fields

**Address-reference words** (three forms, `:672`–`:698`, scan `page-154.png` for Case 3):

- Case 1, working storage: `PZE  LOC,,BYTE` — "where LOC is the first word address and BYTE is the first byte of either the source or target field" (`:678`).
- Case 2, base locator: `MZE  BL)NN,,CP)+NN` — "where BL)NNN is the location of the Base Locator and CP)+NN is a constant that is the displacement distance of the data item from the base" (`:690`).
- Case 3, positional indicator: `MON  PI)NN,,0` — "where PI)NN is the Positional Indicator which locates the data item" (`:698`).

**The two pointer cells** (`:416`–`:467`): `SYS)132` is `PZE LOC,,BYTE`, "This cell points to the first word address (LOC) and first BYTE (0-5) of the source field involved in a Move" (`:420`); `SYS)133` is the same form and "points to the first word address (LOC), and the first BYTE(0-5) of the target field involved in a Move" (`:467`). The three in-line forms that preset them are given at `:427`–`:463` (`LDI CP)+NN / STI SYS)132`; `CAL BL)NN / ACL CP)+NN / SLW SYS)132`; and the complex-base-locator form with `PDX 0,4 / TXL *2,4,5 / ACL CP)+NN2  OCT 777772000000`).

**Length, scaling and sign never appear as words of their own.** Length reaches MOVPAK only as the decrements of the step words and the terminator `TARGET-NUMERIC-LENGTH`. Scaling appears nowhere in this range. Sign appears in three places: the `TARGET-SIGN-CONVENTION` decrement of SYS)183 and SYS)189; the Tag field of the TARGET-CONTROL-WORD; and the "examined for source field sign" notes attached to particular step words.

**TARGET-EDIT-CONTROL** (decrement of SYS)185 and SYS)190; `:822`–`:832`, scan `page-156.png`): "Bits are placed in the decrement which indicate the following characteristics of the target field." — `00001` asterisks, `00002` comma(s), `00004` decimal point, `00010` dollar sign, `00020` Blank When Zero.

**TARGET-CONTROL-WORD** (the `OCT` word after SYS)185 / SYS)190; `:834`–`:849`, scan `page-156.png`):

- "**Prefix** = 0 if no target field commas; otherwise = number of digits to the left of first comma."
- "**Address** = number of leading \*'s, or 8's in pictorial."
- "**Decrement** = number of 8's, 9's, \*'s, to the left of the real or implied decimal point in target pictorial."
- "**Tag** = TARGET-SIGN-CONVENTION" — 0 no sign, 1 overpunch minus, 2 overpunch plus, 3 right minus, 4 right plus, 5 left minus, 6 left plus.

Attested control words in the compiled sample (`comtran-manuals/J28-6169/90.05-sample-program.md`): `OCT 000004000003` at line `1123` (LOC 00606, following `TXI SYS)185,1,4`) and `OCT 000005000004` at line `1597` (LOC 01374, following `TXI SYS)190,1,4`).

### Registers

- **XR4** is the linkage register: every entry is `TSX SYS)nnn,4`. `docs/design/m4-codegen.md:518` (register rules) states "XR4 stays the linkage register ([J 02.08.03] destroys it on located references)".
- **XR1** is the tag of every step word, `TXI SYS)nnn,1,count`.
- **AC / AC-MQ** carries the internal-decimal value: SYS)184 leaves its result there (`:791`), SYS)186–188 read from there (`:862`, `:870`, `:878`). SYS)180/181/182 each admit "a machine register (AC or MQ)" in place of a pointer (`:709`, `:719`, `:728`).
- No entry states which registers survive a call.

### Communication cells the package writes

- `SYS)130` (`:412`): "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects the truncation of significant high order values (i.e. overflow)."
- `SYS)131` (`:414`): "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects an improper data condition."
- `SYS)134` (`:469`): "This cell is set non zero whenever a floating point underflow results from a Move."

No entry in 90.02 reads, tests or clears any of the three — recorded at `docs/design/decisions.md:661`: "No entry in [J 90.02.00]–90.02.33 reads, tests or clears SYS)130."

### Sample coverage

Of the 40 entries in this range, **9 appear in the compiled 90.05 sample**: 180, 182, 184, 185, 190, 193, 198, 212, 214. `docs/design/decisions.md:634` counts the calls: "None of its 51 MOVPAK calls (25 through SYS)180, 26 through SYS)182; re-derived from the octal address fields, LOC 00165–01620 gapless) discards a low-order digit". SYS)179 and SYS)181 have **no** sample site; nor do 183, 186–189, 191, 192, 194–197, 199–211, 213, 215–218.

---

## Entry by entry

Grading key. **FULL** = the entry states its calling sequence, its effect, and where control resumes. **PARTIAL** = class pair and parameter encodings stated, algorithm not. **NAME-ONLY** = the entry body states only the family pairing; the operation exists only as the name of the calling-sequence operand.

Shared facts for SYS)183–218, stated once: none is TSX-linked, so **no skip-return distance applies** — each is reached by an in-line `TXI` word that transfers into it and adds its decrement to XR1. Every one of them takes SYS)132/SYS)133 as its implicit source/target state. None documents an output, a register effect, or a return point.

---

### SYS)179 — MOVPAK entry, both pointers from the calling sequence

Calling sequence, verbatim (`:663`–`:668`):
```
TSX  SYS)179,4
     SOURCE-ADDRESS-REFERENCE
     TARGET-ADDRESS-REFERENCE
                                    Begin specific Move subroutine call
```
Inputs: two address-reference words in the three forms above. Outputs/side effects: sets `SYS)132` and `SYS)133`. Skip-return: **2 parameter words; resume at 3,4**.

Description (`:670`): "This is one entry point to MOVPAK. This entry uses the information in the calling sequence to set up the Move Source Pointer, SYS)132, and the Move Target Pointer, SYS)133. After these data pointers have been set, the instructions beginning at 3,4 are executed to actually perform the moving operation."

Quality: **FULL**. Lines: `:422` (as a setter of SYS)132), `:661` (label), `:664` (sequence), `:709` and `:719` (cross-references from 180/181). No 90.05 site.

### SYS)180 — MOVPAK entry, target pointer only

Verbatim (`:703`–`:707`):
```
TSX  SYS)180,4
     TARGET-ADDRESS-REFERENCE
                                    Begin specific subroutine call
```
Inputs: one target address reference; source already in `SYS)132` or in AC/MQ. Side effects: sets `SYS)133`. Skip-return: **1 word; resume at 2,4**.

Description (`:709`): "This is an entry to MOVPAK in which either the source address of the data item has been previously stored in SYS)132, or the source item is in a machine register (AC or MQ). In either case, the Target Pointer, SYS)133, is set up using the information in the calling sequence in the same manner as SYS)179, and the specific MOVE instructions beginning at 2,4 are executed."

Quality: **FULL**. Lines: `:427`, `:467`, `:701`, `:704`. Scan `page-154.png`. 90.05 sites (25): lines `961, 967, 973, 979, 987, 993, 1011, 1017, 1048, 1367, 1373, 1379, 1387, 1410, 1522, 1558, 1676, 1693, 1699, 1705, 1711, 1717, 1723, 1729, 1735`.

### SYS)181 — MOVPAK entry, source pointer only

Verbatim (`:713`–`:717`):
```
TSX  SYS)181,4
     SOURCE-ADDRESS-REFERENCE
                                    Begin specific subroutine call
```
Inputs: one source address reference; target already in `SYS)133` or a register. Side effects: sets `SYS)132`. Skip-return: **1 word; resume at 2,4**.

Description (`:719`): "This is an entry to MOVPAK in which the target address of the data item has been previously stored in SYS)133 or the target address is a machine register (AC or MQ). In either case, the Source Pointer is set up using the information in the calling sequence in the same manner as SYS)179, and the specific Move instructions beginning at 2,4 are executed."

Quality: **FULL**. Lines: `:422`, `:711`, `:714`. Scan `page-154.png`. No 90.05 site.

### SYS)182 — MOVPAK entry, both pointers preset

Verbatim (`:723`–`:726`):
```
TSX  SYS)182,4
                                    Begin specific subroutine call
```
Inputs: none. Skip-return: **0 words; resume at 1,4**.

Description (`:728`): "This is an entry to MOVPAK in which both the Source Pointer, SYS)132 and the Target Pointer SYS)133, have been preset by inline instructions; or a machine register is used for either or both source and target. The specific Move instructions are executed beginning at 1,4."

Quality: **FULL**. Lines: `:262` (listing-form example), `:427`, `:721`, `:724`, `:779` (worked example). Scan `page-154.png`. 90.05 sites (26): lines `788, 792, 878, 899, 923, 952, 1029, 1033, 1037, 1041, 1045, 1094, 1113, 1121, 1189, 1193, 1397, 1404, 1539, 1579, 1583, 1595, 1645, 1653, 1660, 1668`.

### SYS)183 — XD → XD (family head, step list)

Verbatim (`:733`):
```
TXI  SYS)183,1,TARGET-SIGN-CONVENTION
```
Description (`:736`): "This MOVPAK subroutine moves external decimal fields to external decimal fields. The TARGET-SIGN-CONVENTION is as follows:" — 0 "no sign", 1 "overpunch minus", 2 "overpunch plus" (`:738`–`:742`).

Its step menu, verbatim (`:747`–`:762`, "Immediately following the TXI instruction will be two or more of the following instructions:"):
```
TXI  SYS)191, 1, NUMBER-OF-CHARACTERS-TO-MOVE
TXI  SYS)199, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
TXI  SYS)205, 1, NUMBER OF-CHARACTERS-TO-BYPASS
TXI  SYS)209, 1, NUMBER OF TRAILING-ZEROS-TO-INSERT
TXI  SYS)210, 1, NUMBER-OF-LEADING-ZEROS-TO-INSERT
TRA  SYS)219               Round current character
TXI  SYS)223, 1, TARGET-NUMERIC-LENGTH
TXI  SYS)227, 1, NUMBER-OF-CHARACTERS-TO-MOVE          *Note 1.
TXI  SYS)231, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
                                                        *Note 1.
TXI  SYS)235, 1, NUMBER-OF-CHARACTERS-TO-BYPASS
                                                        *Note 1.
```
Note 1 (`:764`): "The last character processed under control of this instruction is examined for source field sign." Termination (`:766`–`:770`): "This type of MOVPAK call is always terminated by the instruction / `TXI  SYS)223, 1, TARGET-NUMERIC-LENGTH`". Worked example (`:774`–`:783`), the only printed full XD→XD sequence:
```
LDI  CP)+NN1                       Load Source Pointer
STI  SYS)132
LDI  CP)+NN2                       Load Target Pointer
STI  SYS)133
TSX  SYS)182,4                     Begin moving field
TXI  SYS)183,1,1                   XD to XD
TXI  SYS)191,1,10                  10 characters to a 10 character field
TXI  SYS)223,1,10
```
Quality: **PARTIAL** — missing: what the sign convention *does* to the target character (which position, which zone punch); missing: the ordering and legality rules for the step list; missing: behavior when the counted steps do not span the field. Lines: `:730, :733, :780, :966, :1033, :1084, :1116, :1127, :1204, :1236, :1268, :1303, :1335`. Scans `page-154.png`, `page-155.png`. No 90.05 site.

### SYS)184 — XD → ID convert, result in AC/AC-MQ

Verbatim (`:788`): `TXI  SYS)184,1,NUMBER-OF-CHARACTERS-TO-CONVERT`

Description (`:791`): "This is a MOVPAK subroutine which converts from external decimal to internal decimal leaving results in the AC or AC-MQ. The sign is assumed over the low order digit."

Inputs: source via `SYS)132`, count in the decrement. Output: AC or AC-MQ. No step list, no terminator — attested in the sample, where the call is `TSX SYS)182,4 / TXI SYS)184,1,3 / STO 3)HOURS` (90.05 lines `1113`–`1115`, LOC 00574–00576).

Quality: **PARTIAL** — missing: what selects AC versus AC-MQ; missing: scale/justification of the result; missing: behavior on a non-digit character. Lines: `:785, :788`. Scan `page-155.png`. 90.05 sites: `1114, 1654, 1669`.

### SYS)185 — XD → EF (family head, step list + control word)

Verbatim (`:795`–`:797`):
```
TXI  SYS)185,1,TARGET-EDIT-CONTROL      *Note 1.
OCT  TARGET-CONTROL-WORD-BITS
```
Description (`:800`, `:805`): "SYS)185 is a MOVPAK subroutine which moves an external decimal field to an edited field." / "The first word is followed by a TARGET-CONTROL-WORD \*Note 2, and two or more of the following instructions:"
```
TXI  SYS)193, 1, NUMBER-OF-CHARACTERS-TO-MOVE
TXI  SYS)201, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
TXI  SYS)206, 1, NUMBER-OF-CHARACTERS-TO-BYPASS
TXI  SYS)211, 1, NUMBER-OF-TRAILING-ZEROS-TO-INSERT
TXI  SYS)212, 1, NUMBER-OF-LEADING-ZEROS-TO-INSERT
TRA  SYS)220               Round current character
TXI  SYS)225, 1, TARGET-NUMERIC-LENGTH   (End of call sequence)
TXI  SYS)228, 1, NUMBER-OF-CHARACTERS-TO-MOVE          *Note 3.
TXI  SYS)232, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
                                                        *Note 3.
TXI  SYS)236, 1, NUMBER-OF-CHARACTERS-TO-BYPASS
                                                        *Note 3.
```
(`:808`–`:819`.) Notes 1, 2, 3 at `:822`–`:851` carry the edit-control bits, the TARGET-CONTROL-WORD layout, and the sign-examination rule; both note tables are reproduced under **Parameter words** above. This entry's notes are the *only* definition of the edit encoding in the manual — SYS)190 refers back to it (`:954`).

Attested sequence in the sample (90.05 lines `1121`–`1126`, LOC 00604–00611): `TSX SYS)182,4 / TXI SYS)185,1,4 / OCT 000004000003 / TXI SYS)212,1,2 / TXI SYS)193,1,3 / TXI SYS)225,1,5`. Note the emitted order — leading-zeros step *before* the move step — is the reverse of the printed menu order.

Quality: **PARTIAL** — missing: the edit algorithm itself (dollar-sign placement and whether it floats, asterisk-fill interaction with commas, the exact Blank When Zero test); missing: the function of the `8` character. Lines: `:793, :796, :800, :954, :985, :1052, :1092, :1135, :1143, :1212, :1252, :1279, :1311, :1343, :1665`. Scans `page-155.png`, `page-156.png`. 90.05 sites: `1122, 1646, 1661`.

### SYS)186 — ID → XD, unsigned

Verbatim (`:859`): `TXI  SYS)186,1,NUMBER-OF-CHARACTERS-TO-DEVELOP`
Description (`:862`): "This is a MOVPAK subroutine which converts from internal decimal in the AC or AC-MQ to unsigned external decimal."
Inputs: AC or AC-MQ; count in the decrement; target via `SYS)133`. Quality: **PARTIAL** — missing: what selects AC versus AC-MQ; missing: what happens to the value's sign; missing: high-order truncation behavior. Lines: `:856, :859`. Scan `page-157.png`. No 90.05 site.

### SYS)187 — ID → XD, overpunch minus

Verbatim (`:867`): `TXI  SYS)187,1,NUMBER-OF-CHARACTERS-TO-DEVELOP`
Description (`:870`): "This is a MOVPAK subroutine which converts from internal decimal in the AC or AC-MQ to external decimal with overpunch minus sign convention."
Quality: **PARTIAL** — same three missing facts as SYS)186, plus: which character position takes the overpunch. Lines: `:864, :867`. Scan `page-157.png`. No 90.05 site.

### SYS)188 — ID → XD, overpunch plus

Verbatim (`:875`): `TXI  SYS)188,1,NUMBER-OF-CHARACTERS-TO-DEVELOP`
Description (`:878`): "This is a MOVPAK subroutine which converts from internal decimal in AC or AC-MQ to external decimal with overpunch plus sign convention." (Note the dropped "the" before "AC", unique among the three.)
Quality: **PARTIAL**, as SYS)187. Lines: `:872, :875`. Scan `page-157.png`. No 90.05 site.

### SYS)189 — EF → XD (family head, step list)

Verbatim (`:883`): `TXI  SYS)189,1,TARGET-SIGN-CONVENTION      *Note 1.`
Description (`:886`): "This is a MOVPAK subroutine which moves an edited field to an external decimal field. This word is followed by two or more of the following instructions:"
```
TXI  SYS)192, 1, NUMBER-OF-CHARACTERS-TO-MOVE
TXI  SYS)195, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
TXI  SYS)197, 1, NUMBER-OF-CHARACTERS-TO-MOVE
TXI  SYS)200, 1, NUMBER-OF-CHARACTERS-TO-BYPASS
                                                        *Note 2.
TXI  SYS)203, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
TXI  SYS)207, 1, NUMBER-OF-CHARACTERS-TO-BYPASS
TXI  SYS)213, 1, NUMBER-OF-LEADING-ZEROS-TO-INSERT
TXI  SYS)215, 1, NUMBER-OF-TRAILING-ZEROS-TO-INSERT
TXI  SYS)217, 1, NUMBER-OF-CHARACTERS-TO-SCAN-FOR-SIGN
TRA  SYS)221               Round current characters
TXI  SYS)224, 1, TARGET-NUMERIC-LENGTH   (End of call sequence)
TXI  SYS)229, 1, NUMBER-OF-CHARACTERS-TO-MOVE
                                                        *Note 3.
TXI  SYS)233, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
                                                        *Note 3.
TXI  SYS)237, 1, NUMBER-OF-CHARACTERS-TO-BYPASS
                                                        *Note 3.
```
(`:889`–`:906`.) Note 1 (`:909`–`:914`): sign convention 0/1/2 as SYS)183. Note 2 (`:920`): "The first character processed under control of this instruction is examined for source field sign." — attached to SYS)200 alone. Note 3 (`:922`): "The last character processed under control of this instruction is examined for source field sign."

Quality: **PARTIAL** — missing: what distinguishes the two move steps SYS)192 and SYS)197; missing: what a "scan for sign" reads and how it maps a found sign onto the target's convention; missing: what a "bypass" does with the bypassed target positions. Lines: `:880, :883, :977, :1001, :1017, :1041, :1068, :1100, :1151, :1167, :1183, :1220, :1244, :1287, :1319, :1354`. Scan `page-157.png`. No 90.05 site.

### SYS)190 — EF → EF (family head, step list + control word)

Verbatim (`:926`–`:928`):
```
TXI  SYS)190,1,TARGET-EDIT-CONTROL      *Note 1.
OCT  TARGET-CONTROL-WORD-BITS
```
Description (`:931`): "This is a MOVPAK subroutine which moves an edited field to an edited field. The first instruction is followed by a TARGET-CONTROL-WORD, \*NOTE 1, and two or more of the following instructions:"
```
TXI  SYS)194, 1, NUMBER-OF-CHARACTERS-TO-MOVE
TXI  SYS)196, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
TXI  SYS)198, 1, NUMBER-OF-CHARACTERS-TO-MOVE
TXI  SYS)202, 1, NUMBER-OF-CHARACTERS-TO-BYPASS
                                                        *Note 2.
TXI  SYS)204, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
TXI  SYS)208, 1, NUMBER-OF-CHARACTERS-TO-BYPASS
TXI  SYS)214, 1, NUMBER-OF-LEADING-ZEROS-TO-INSERT
TXI  SYS)216, 1, NUMBER-OF-TRAILING-ZEROS-TO-INSERT
TXI  SYS)218, 1, NUMBER-OF-CHARACTERS-TO-SCAN-FOR-SIGN
TRA  SYS)222               Round current character
TXI  SYS)226, 1, TARGET-NUMERIC-LENGTH   (End of call sequence)
TXI  SYS)230, 1, NUMBER-OF-CHARACTERS-TO-MOVE
                                                        *Note 3.
TXI  SYS)234, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
                                                        *Note 3.
TXI  SYS)238, 1, NUMBERS-OF-CHARACTERS-TO-BYPASS
                                                        *Note 3.
```
(`:934`–`:951`.) Note 1 (`:954`): "The TARGET-EDIT-CONTROL and the TARGET-CONTROL-WORD are the same format as described under SYS)185." Notes 2 and 3 as SYS)189 (`:956`, `:958`).

Attested sequence in the sample (90.05 lines `1595`–`1600`, LOC 01372–01377): `TSX SYS)182,4 / TXI SYS)190,1,4 / OCT 000005000004 / TXI SYS)214,1,2 / TXI SYS)198,1,5 / TXI SYS)226,1,7`. This is the only EF→EF site in the sample, and again the leading-zeros step precedes the move step.

Quality: **PARTIAL** — missing: the edit algorithm (inherited from SYS)185's silence); missing: what distinguishes SYS)194 from SYS)198. Lines: `:924, :927, :993, :1009, :1025, :1060, :1076, :1108, :1159, :1175, :1191, :1228, :1260, :1295, :1327, :1362`. 90.05 site: `1596`.

### SYS)191 – SYS)218 — the counted step subroutines

Each entry's whole body is one sentence of the form "This MOVPAK subroutine is used in conjunction with SYS)nnn to move X to Y". None states an algorithm, an output, a side effect, or a return point. All are **NAME-ONLY** by the key above: the operation exists only as the name of the operand in the calling sequence. The missing fact common to all 28: **what the count counts and what the routine writes.**

| # | Calling sequence, verbatim | Family | Description, quoted | Extra note | Lines (90.02) | 90.05 |
|---|---|---|---|---|---|---|
| 191 | `TXI  SYS)191,1,NUMBER-OF-CHARACTERS-TO-MOVE` | 183, XD→XD | "This is a MOVPAK subroutine used in conjunction with SYS)183 in moving external decimal fields to external decimal fields." | wording differs from all siblings ("used in conjunction … in moving", not "… to move") | `:750, :781, :960, :963` | — |
| 192 | `TXI  SYS)192,1,NUMBER-OF-CHARACTERS-TO-MOVE` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | first of two identical move steps in the family | `:889, :971, :974` | — |
| 193 | `TXI  SYS)193,1,NUMBER-OF-CHARACTERS-TO-MOVE` | 185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | | `:808, :979, :982` | `1125, 1649, 1664` |
| 194 | `TXI  SYS)194,1,NUMBERS-OF-CHARACTERS-TO-MOVE` | 190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | plural **NUMBERS**, scan-confirmed | `:934, :987, :990` | — |
| 195 | `TXI  SYS)195,1,NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | | `:890, :995, :998` | — |
| 196 | `TXI  SYS)196,1,NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | 190, EF→EF | "This MOVPAK subroutine is used in conjuction with SYS)190 to move edited fields to edited fields." | **"conjuction"**, scan-confirmed | `:935, :1003, :1006` | — |
| 197 | `TXI  SYS)197,1,NUMBER-OF-CHARACTERS-TO-MOVE` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | second identical move step; nothing separates it from 192 | `:891, :1011, :1014` | — |
| 198 | `TXI  SYS)198,1,NUMBER-OF-CHARACTERS-TO-MOVE` | 190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | second move step; nothing separates it from 194 | `:936, :1019, :1022` | `1599` |
| 199 | `TXI  SYS)199,1,NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | 183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | | `:751, :1027, :1030` | — |
| 200 | `TXI  SYS)200,1,NUMBER-OF-CHARACTERS-TO-BYPASS` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | carries Note 2: **first** character examined for source field sign (`:893, :920`) | `:892, :1035, :1038` | — |
| 201 | `TXI  SYS)201,1,NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | 185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | | `:809, :1046, :1049` | — |
| 202 | `TXI  SYS)202,1,NUMBER-OF-CHARACTERS-TO-BYPASS` | 190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | carries Note 2: **first** character examined (`:938, :956`) | `:937, :1054, :1057` | — |
| 203 | `TXI  SYS)203,1,NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | second overflow-test step; nothing separates it from 195 | `:894, :1062, :1065` | — |
| 204 | `TXI  SYS)204,1,NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | 190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | second overflow-test step; nothing separates it from 196 | `:939, :1070, :1073` | — |
| 205 | `TXI  SYS)205,1,NUMBER-OF-CHARACTERS-TO-BYPASS` | 183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | | `:752, :1078, :1081` | — |
| 206 | `TXI  SYS)206,1,NUMBER-OF-CHARACTERS-TO-BYPASS` | 185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | | `:810, :1086, :1089` | — |
| 207 | `TXI  SYS)207,1,NUMBER-OF-CHARACTERS-TO-BYPASS` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | second bypass step; carries no note, unlike 200 | `:895, :1094, :1097` | — |
| 208 | `TXI  SYS)208,1,NUMBER-OF-CHARACTERS-TO-BYPASS` | 190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | second bypass step; no note, unlike 202 | `:940, :1102, :1105` | — |
| 209 | `TXI  SYS)209,1,NUMBER-OF-TRAILING-ZEROS-TO-INSERT` | 183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | printed in 183's list as `NUMBER OF TRAILING-ZEROS-TO-INSERT` (`:753`) | `:753, :1110, :1113` | — |
| 210 | `TXI  SYS)210,1,NUMBER-OF-LEADING-ZEROS-TO-INSERT` | 183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | | `:754, :1121, :1124` | — |
| 211 | `TXI  SYS)211,1,NUMBER-OF-TRAILING-ZEROS-TO-INSERT` | 185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | | `:811, :1129, :1132` | — |
| 212 | `TXI  SYS)212,1,NUMBER-OF-LEADING-ZEROS-TO-INSERT` | 185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | | `:812, :1137, :1140` | `1124, 1648, 1663` |
| 213 | `TXI  SYS)213,1,NUMBER-OF-LEADING-ZEROS-TO-INSERT` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | | `:896, :1145, :1148` | — |
| 214 | `TXI  SYS)214,1,NUMBER-OF-LEADING-ZEROS-TO-INSERT` | 190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | | `:941, :1153, :1156` | `1598` |
| 215 | `TXI  SYS)215,1,NUMBER-OF-TRAILING-ZEROS-TO-INSERT` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal." | **"external decimal."** — "fields" dropped, unique among 28 | `:897, :1161, :1164` | — |
| 216 | `TXI  SYS)216,1,NUMBER-OF-TRAILING-ZEROS-TO-INSERT` | 190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | | `:942, :1169, :1172` | — |
| 217 | `TXI  SYS)217,1,NUMBER-OF-CHARACTERS-TO-SCAN-FOR-SIGN` | 189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | the only sign-scan step for EF→XD | `:898, :1177, :1180` | — |
| 218 | `TXI  SYS)218,1,NUMBER-OF-CHARACTERS-TO-SCAN-FOR-SIGN` | 190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | the only sign-scan step for EF→EF | `:943, :1185, :1188` | — |

---

## Printed inconsistencies

`docs/design/m4-codegen.md:912` binds handlers to preserve these: "Handlers keep the printed inconsistencies as recorded defects, not silent fixes: SYS)231–234 follow their own entries (overpunch test), not the family lists' overflow naming (D4.2's note)."

1. **SYS)231–234 change meaning between the family list and their own entry.** All four in-range family lists print, e.g., `:758` — "TXI  SYS)231, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW" — while the four entries themselves print `:1300, :1308, :1316, :1324` — "TXI     SYS)231, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH". Already recorded at `docs/design/decisions.md:665`: "Note the printed inconsistency preserved in J: SYS)231–234 occupy the test slot in the family lists but their own entries print NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH; our handlers follow the individual entries (overpunch) and the calling-sequence position is recorded as a printed defect."

2. **The round step for SYS)189 is printed plural, the other three singular.** `:899` — "TRA  SYS)221               Round current characters" — against `:755`, `:813`, `:944` ("Round current character") and against SYS)221's own entry at `:1217` ("Round current character"). Scan-confirmed on `page-157.png`. `docs/design/decisions.md:646` hangs an amendable decision on it: "the appendix gives the step no repetition count and does not state whether its effect is confined to one position, and [J 90.02.18] prints 'Round current characters' (plural) for SYS)221 — the one place the manual hints at a wider scope. The single-position choice is amendable on that hint."

3. **The terminator is printed in the middle of every family menu.** SYS)183's list puts `TXI  SYS)223, 1, TARGET-NUMERIC-LENGTH` at `:756` with three more steps at `:757`–`:761`, then says at `:766`: "This type of MOVPAK call is always terminated by the instruction". SYS)185, 189 and 190 do the same (`:814`, `:900`, `:945`, each annotated "(End of call sequence)" and each followed by three more entries). Recorded at `docs/design/decisions.md:644`: "the printed lists are menus, not orderings — 'Immediately following the TXI instruction will be two or more of the following instructions' ([J 90.02.16]), and the scans print list entries after the terminator line". The sample independently confirms the menus are not orderings: at 90.05 line `1124` the leading-zeros step (SYS)212) precedes the move step (SYS)193), the reverse of the printed order.

4. **Two indistinguishable move steps and two indistinguishable overflow-test steps in each edited-source family.** SYS)189's list carries both `TXI  SYS)192, 1, NUMBER-OF-CHARACTERS-TO-MOVE` (`:889`) and `TXI  SYS)197, 1, NUMBER-OF-CHARACTERS-TO-MOVE` (`:891`), and both SYS)195 (`:890`) and SYS)203 (`:894`) as overflow tests; SYS)190's list repeats the pattern with 194/198 (`:934`, `:936`) and 196/204 (`:935`, `:939`). The entries for all eight are identical apart from the number. The XD-source families (183, 185) have exactly one of each.

5. **SYS)190 points its control word at the wrong note.** `:931` — "The first instruction is followed by a TARGET-CONTROL-WORD, \*NOTE 1" — but SYS)190's Note 1 (`:954`) covers both words by deferring to SYS)185, where the control word is defined under **Note 2** (`:834`). Also the only place in this range that spells the marker "\*NOTE 1" in capitals.

6. **Note 3 loses a word on the SYS)185 page.** `:851` — "The last character processed under control this instruction is examined for source field sign." — against the identical note printed with "of" at `:764` (SYS)183) and `:922` (SYS)189) and `:958` (SYS)190). Scan-confirmed on `page-156.png`.

7. **SYS)194 and SYS)238 print a plural "NUMBERS".** `:990` — "TXI  SYS)194,1,NUMBERS-OF-CHARACTERS-TO-MOVE" — scan-confirmed on `page-159.png`; and `:943`, inside SYS)190's list — "TXI  SYS)238, 1, NUMBERS-OF-CHARACTERS-TO-BYPASS" — against SYS)238's own entry at `:1336`, "NUMBER-OF-CHARACTERS-TO-BYPASS". Every sibling prints the singular.

8. **SYS)196 prints "conjuction".** `:1009` — "This MOVPAK subroutine is used in conjuction with SYS)190 to move edited fields to edited fields." Scan-confirmed on `page-159.png`. All 27 siblings print "conjunction".

9. **SYS)215 drops "fields".** `:1164` — "…to move edited fields to external decimal." — against SYS)192, 195, 197, 200, 203, 207, 213 and 217, all of which end "to external decimal fields."

10. **SYS)179's annotation differs from the other three entries'.** `:668` — "Begin specific Move subroutine call" — against "Begin specific subroutine call" at `:707`, `:717`, `:726`. Scan-confirmed for the latter three on `page-154.png`.

11. **SYS)188's description drops an article.** `:878` — "converts from internal decimal in AC or AC-MQ" — against `:862` and `:870`, both "in the AC or AC-MQ". Scan-confirmed on `page-157.png`.

12. **Hyphenation of the parameter names is inconsistent in the printed original, and the conversion normalized some of it.** Section 9 ranks the scan above the conversion, so these are conversion divergences, all semantically null:
   - Preserved as printed: `:752` "NUMBER OF-CHARACTERS-TO-BYPASS" and `:753` "NUMBER OF TRAILING-ZEROS-TO-INSERT" (scan `page-155.png` agrees).
   - Normalized away: `page-157.png` prints `TXI SYS)197, 1, NUMBER-OF-CHARACTERS TO-MOVE` and `TXI SYS)203, 1, NUMBER OF-CHARACTERS-TO-TEST-FOR-OVERFLOW`, rendered fully hyphenated at `:891` and `:894`; `page-157.png` prints `TXI SYS)186,1,NUMBER-OF CHARACTERS-TO-DEVELOP`, rendered `:859`; `page-157.png` prints `TXI SYS)189, 1,TARGET SIGN CONVENTION`, rendered "TARGET-SIGN-CONVENTION" at `:883`; `page-156.png` prints `TXI SYS)193, 1, NUMBER-OF CHARACTERS-TO-MOVE`, rendered `:808`.

13. **Case 3's address-reference glyph.** `page-154.png` prints `MON  PI)NN,,O` where the final character reads as a letter **O**; `:697` renders it as digit `0`. The typewriter's O and 0 are close on this page, so the intended character is **unverified**; the surrounding "If 0" glyphs on the same page are narrower.

---

## GAPS — facts a handler needs that no manual statement settles

1. **How a count reaches a step routine.** `TXI` *adds* its decrement to XR1 (`lib/src/emulator/decode.dart:85`). No 90.02 text says XR1 holds zero when MOVPAK reaches the calling sequence, nor that a step clears XR1 before returning. Without one of those, consecutive steps accumulate.
2. **Where a step returns to, and where the terminator goes.** The manual states only the *entry* resume points (3,4 / 2,4 / 1,4). Nothing says a step returns to the next in-line word, nor where control goes after `TARGET-NUMERIC-LENGTH`.
3. **Step ordering and legality.** "two or more of the following instructions" (`:747`) is the whole rule. Which combinations are legal, in what order, and whether a step may repeat, are unstated. The sample's two edited-target sites order leading-zeros before move; nothing generalizes that.
4. **What "bypass" bypasses.** Source characters or target positions is unstated, as is what (if anything) is written into a bypassed target position.
5. **What "test for overflow" reads.** Whether the count applies to source characters or target positions, and what makes a character "significant", is unstated. `docs/design/decisions.md:661` records the arming rule as a design decision with a live alternative: "Our MOVPAK handlers for the five character-source families SYS)183, 185, 189, 190 and 268 carry the counted overflow-test step … The alternative reading stays on record, and it is the one J's class-wide wording most naturally supports."
6. **Truncation.** Nothing states what happens when the counted steps do not span the field, or when a source is longer than a target. The only statement anywhere is F's, quoted at `docs/design/decisions.md:644`: "[F p. 42] says only that MOVE alignment 'may involve the dropping of leading digits or low-order digits'".
7. **How sign is carried.** Notes 1/2/3 say only which character "is examined for source field sign" (`:764`, `:920`, `:922`). Nothing says how the examined zone becomes the target's sign, what happens when the emitted sequence contains no sign step at all, or what the target looks like under **tag values 3–6** — "right minus", "right plus", "left minus", "left plus" (`:845`–`:849`) — which appear only in the TARGET-CONTROL-WORD and never in the TARGET-SIGN-CONVENTION tables of SYS)183 and SYS)189, both of which stop at 2 (`:738`–`:742`, `:909`–`:914`).
8. **Exact edit-mask semantics.** The control word gives comma position, leading-`*`/`8` count, digits left of the point, and sign convention (`:836`–`:849`), and the edit-control decrement gives five feature bits (`:826`–`:832`). Nothing states where the `$` is written or whether it floats, how asterisk fill interacts with comma suppression, whether the decimal point is written by the mask or by a step, or whether Blank When Zero tests the whole field or only its numeric part.
9. **What the `8` edit character does.** The conversion note at `:470` flags it: the "8" in the EF character list "is transcribed literally as printed (a rounded digit-8 glyph, not a letter B) though its function as a COMTRAN edit character is not independently verified."
10. **AC versus AC-MQ.** SYS)184 leaves its result "in the AC or AC-MQ" (`:791`); SYS)186/187/188 read from "the AC or AC-MQ". No threshold, digit count, or flag selects between them.
11. **Round-step internals.** No algorithm, sign rule, carry rule, or repetition count for SYS)219–222. Recorded as a design decision at `docs/design/decisions.md:646`: "MOVPAK round-step handler internals — design decision under D0.4, no unsealed evidence survives".
12. **Improper-data trigger and substitute value.** SYS)131 is set on "an improper data condition" (`:414`) and the phrase is never defined. `docs/design/decisions.md:674` records both the trigger and the substituted digit as design decisions: "What counts as 'an improper data condition' is unresolved… The value used for an invalid character is fixed by design decision".
13. **Register preservation and cell state after a call.** No entry states which of AC, MQ, XR1, XR2 or the sense indicators survive a MOVPAK call, nor whether `SYS)132`/`SYS)133` are advanced by the move or left as set.
14. **Scaling and decimal alignment between source and target.** No word of a MOVPAK calling sequence carries a scale. The V-point alignment must be implied entirely by the step counts, and the manual never says so.
15. **Where a zero-insert writes.** Whether SYS)209–216 write into the target field directly or into an internal work area, and whether the inserted character is BCD zero or an edited zero, is unstated.
16. **Field length.** No entry states the source field's length. Only the target's is given, and only by the terminator word `TARGET-NUMERIC-LENGTH` (SYS)223–226), whose own entries (`:1233`, `:1241`, `:1249`, `:1257`) say nothing beyond the family pairing.