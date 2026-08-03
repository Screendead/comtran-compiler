# The 7090 CPU emulator core

*Status: **draft at M1**; hardens at M4 when codegen, the loader, and the
runtime connect to it. Records the design of `lib/src/emulator/` under
decision D0.3 (real 7090 object code on our own emulator). Instruction
semantics come from the period reference manual, IBM 7090 Data Processing
System Reference Manual, form A22-6528-4, March 1962 (external; cited below as
"M p. N"). The instruction subset comes from the code that the COMTRAN
compiler generates, harvested from J 90.02 and the J 90.05 compilation
listing. Every unattested choice is labeled `ED-n` (emulator design decision)
and is amendable by an explicit edit to this file.*

## 1. Scope

The core executes the CPU instructions that appear in COMTRAN-generated
object code. It does not execute the SYS)/IOC) runtime: those routines are
high-level Dart handlers at the documented entry points (D0.3). The caller
(the M4 machine assembly) intercepts control before the CPU enters a runtime
entry address. Inside generated code, the calling-sequence parameter words
(PZE, MZE, OCT, IOST, IOCTN data words) are data for those handlers; the CPU
never executes them. If the instruction counter ever reaches one, the CPU
throws (§7) — there is no silent wrong path.

## 2. Word representation (ED-1)

- A **storage word** is 36 bits, sign-magnitude: position S (the algebraic
  sign; 0 = plus, 1 = minus) and magnitude positions 1–35 (M p. 7). The
  emulator holds one word as one Dart `int`, value `0 .. 2^36 - 1`, with
  position S at bit 35 and position 35 at bit 0. Position *n* (1 ≤ n ≤ 35)
  is bit `35 - n`.
- The **AC** holds 37 magnitude bits plus a sign: S, Q, P, 1–35 (M pp. 8–9).
  The emulator stores it as a sign (`int`, 0 or 1) plus a 37-bit magnitude
  `int` (Q = bit 36, P = bit 35, positions 1–35 = bits 34–0). A carry out of
  position 1 enters P and turns the overflow indicator on; a carry out of P
  enters Q; carries out of Q are lost (M pp. 8–9, 11).
- Why this is safe in Dart: the Dart VM `int` is a 64-bit integer. All stored
  register and word values stay at or below 38 bits. The only intermediates
  that exceed 63 bits are the 70-bit MPY product and the 72-bit DVP dividend;
  those two instructions use `BigInt` internally and convert back (ED-1).
  No shift is applied to an unmasked value that could exceed 63 bits: long
  shifts execute stepwise (ED-5).

## 3. Machine state

| Element | Width | Notes |
|---|---|---|
| AC | S + 37 bits (Q, P, 1–35) | M pp. 8–9 |
| MQ | 36 bits (S, 1–35) | M p. 9 |
| SI (sense indicators) | 36 bits (positions 0–35) | M p. 9; position 0 = bit 35 of the stored `int`, so LDI/STI are bit-for-bit word moves |
| XR 1, 2, 4 | 15 bits each | tags; M p. 9 |
| IC | 15 bits | wraps: the highest location and location zero are consecutive (M p. 9) |
| Overflow indicator | 1 bit | M p. 11 |
| Divide-check indicator | 1 bit | M p. 11 |
| Memory | 32,768 × 36-bit words | M p. 7 |

Not represented: the SR and IR (internal buffers, "not a normal object of
concern to the programmer", M p. 9), sense switches, sense lights, panel
keys, the I-O check indicator, data channels (§8).

**Memory starts at +0 in every cell (ED-6).** Real core held junk at power-on.
The CT Loader fills all program-relevant cells before execution, so zeros are
never observable by a correct load; a program that reads an unloaded cell
reads +0. Recorded as a decision because no source attests a power-on value.

**Multiple tags.** A tag field of 3, 5, 6, or 7 names several index
registers. A read under a multiple tag delivers the logical OR of the named
registers (M p. 10). A load under a multiple tag loads all named registers
with the same value (M p. 45). A store under tag 0 stores zeros (M p. 46).
The generated code uses this: `AXT *+3,7` loads XR 1, 2, and 4 at
END.OF.RUN (J 90.05 listing, PDF p. 203).

## 4. Instruction word decode

Two hardware formats (M pp. 8–10, 18):

- **Type A** — prefix (S, 1, 2) with bits 1–2 not both zero; decrement
  (3–17); tag (18–20); address (21–35). Subset members: TXI (+1), TXH (+3),
  TXL (−3). Instructions with a decrement part take no address modification
  and no indirect addressing (M p. 18).
- **Type B** — operation (S, 1–11), read as the signed octal code the manual
  prints (the listing folds the sign into the first octal digit: `4500` =
  −0500); flag F (12–13); tag (18–20); address (21–35).
  - **Sense-indicator right-half sub-format**: SIR, RIR, RFT use the entire
    right half (18–35) as the mask R; no address modification (M p. 10).
  - **Convert sub-format**: CVR carries its count C in positions 10–17 and
    honors only tag bit 20; no address modification (M pp. 10, 56).
  - **Address-as-opcode family**: for +0760 the modified address selects the
    sub-operation; the subset implements only address 00006 = COM (M p. 49).

**Effective address** = (address − OR of tagged XRs) mod 2^15 (two's
complement addition; carries into the sixteenth position are lost; M p. 10).

**Indirect addressing**: flag = 1-bits in *both* positions 12 and 13. The CPU
computes the indirect effective address normally, fetches that word, and uses
*its* tag and address parts to compute the direct effective address — one
level (M p. 11). The subset's generated code uses it only on TRA (`TRA*`,
six sites, J 90.05 listing PDF pp. 202, 211–213), but the emulator honors the
flag on every instruction whose manual diagram carries F.

## 5. The harvested instruction subset

Harvest method: every executed line of the J 90.05 compilation listing was
parsed by its octal opcode column (authoritative over the printed mnemonic),
and every inline-code shape in J 90.02 was collected. Pseudo-operations and
data words (PZE, MZE, OCT, BSS, ORG, BCD, IOST, IOCTN) are loader/runtime
data, not CPU instructions, and are excluded. Listing citations give the
first PDF page and the occurrence count across PDF pp. 198–216.

| Octal | Mnemonic | Semantics (one line) | Evidence |
|---|---|---|---|
| +0500 | CLA | AC(S,1–35) ← C(Y); P,Q ← 0 | J 90.05 PDF 203 (67×); M p. 20 |
| −0500 | CAL | AC(P,1–35) ← C(Y) with S of Y in P; S,Q ← 0 | J 90.05 PDF 201 (37×); M p. 20 |
| +0400 | ADD | AC ← AC + C(Y) algebraically; overflow on carry into P | J 90.05 PDF 207 (28×); M pp. 20–21 |
| +0402 | SUB | AC ← AC − C(Y) algebraically (ADD with Y sign reversed) | J 90.05 PDF 206 (11×); M p. 21 |
| +0361 | ACL | AC(P,1–35) ← AC(P,1–35) + C(Y) logically, end-around carry P→35; S,Q untouched | J 90.05 PDF 202 (13×); M pp. 21–22 |
| +0200 | MPY | AC,MQ ← C(Y) × C(MQ), 70-bit product; signs algebraic | J 90.05 PDF 206 (13×); M p. 22 |
| +0221 | DVP | if |C(Y)| > |AC|: MQ ← quotient, AC ← remainder; else divide-check on, proceed | J 90.05 PDF 203 (7×); M p. 24 |
| +0601 | STO | C(Y) ← AC(S,1–35) | J 90.05 PDF 205 (40×); M p. 33 |
| +0602 | SLW | C(Y) ← AC(P,1–35) | J 90.05 PDF 202 (19×); M p. 33 |
| −0600 | STQ | C(Y) ← C(MQ) | J 90.05 PDF 206 (9×); M p. 33 |
| +0560 | LDQ | MQ ← C(Y) | J 90.05 PDF 206 (17×); M p. 33 |
| +0131 | XCA | AC(S,1–35) ↔ MQ(S,1–35); P,Q ← 0 | J 90.05 PDF 206 (11×); M p. 34 |
| +0760…06 | COM | AC(Q,P,1–35) ← ones-complement; sign unchanged | J 90.05 PDF 201 (5×); M p. 49 |
| −0320 | ANA | AC(P,1–35) ← AC AND C(Y); S,Q ← 0 | J 90.05 PDF 201 (12×); M p. 48 |
| +0320 | ANS | C(Y) ← AC(P,1–35) AND C(Y); AC unchanged | J 90.05 PDF 201 (10×); M p. 48 |
| −0602 | ORS | C(Y) ← AC(P,1–35) OR C(Y); AC unchanged | J 90.05 PDF 201 (10×); M p. 48 |
| +0340 | CAS | algebraic compare AC : C(Y); >, =, < → skip 0, 1, 2; +0 > −0 | J 90.05 PDF 205 (6×); M p. 43 |
| −0340 | LAS | unsigned compare AC(Q,P,1–35) : C(Y)(S,1–35); skip 0, 1, 2 | J 90.05 PDF 201 (5×); M p. 43 |
| +0020 | TRA | IC ← Y (indexable; indirect attested as `TRA*`) | J 90.05 PDF 201 (64×); M p. 36 |
| +0120 | TPL | if AC sign plus: IC ← Y | J 90.05 PDF 207 (1×); M p. 38 |
| +0074 | TSX | XR(T) ← 2^15 − (location of TSX); IC ← Y | J 90.05 PDF 200 (67×); M p. 39 |
| +1 (A) | TXI | XR(T) ← XR(T) + D; IC ← Y | J 90.05 PDF 200 (68×); M p. 39 |
| +3 (A) | TXH | if XR(T) > D: IC ← Y | J 90.05 PDF 200 (4×); M p. 39 |
| −3 (A) | TXL | if XR(T) ≤ D: IC ← Y | J 90.05 PDF 201 (28×); J 90.02.11; M p. 40 |
| +0774 | AXT | XR(T) ← instruction address (no address modification) | J 90.05 PDF 201 (40×); M p. 45 |
| +0634 | SXA | C(Y)(21–35) ← XR(T); rest of Y unchanged; tag 0 stores zeros | J 90.05 PDF 201 (10×); M p. 46 |
| +0534 | LXA | XR(T) ← C(Y)(21–35) | J 90.05 PDF 210 (1×); M p. 45 |
| +0535 | LAC | XR(T) ← 2^15 − C(Y)(21–35) | J 90.05 PDF 201 (20×); J 90.02.04; M p. 45 |
| +0754 | PXA | AC ← 0, then AC(21–35) ← XR(T) | J 90.05 PDF 211 (1×); M p. 47 |
| −0734 | PDX | XR(T) ← AC(3–17) | J 90.02.11 (base-locator case 3); M p. 46 |
| +0441 | LDI | SI ← C(Y) | J 90.05 PDF 200 (26×); J 90.02.11; M p. 51 |
| +0604 | STI | C(Y) ← SI | J 90.05 PDF 200 (26×); J 90.02.11; M p. 51 |
| +0055 | SIR | SI(18–35) ← SI(18–35) OR R | J 90.05 PDF 211 (1×); M p. 52 |
| +0057 | RIR | SI(18–35) ← SI(18–35) AND NOT R | J 90.05 PDF 211 (1×); M p. 52 |
| +0054 | RFT | if all SI positions selected by R are 0: skip 1 | J 90.05 PDF 211 (1×); M p. 55 |
| +0767 | ALS | shift AC(Q,P,1–35) left; overflow if a 1 moves from 1 into P | J 90.05 PDF 209 (1×); M p. 31 |
| +0771 | ARS | shift AC(Q,P,1–35) right; no indicators | J 90.05 PDF 201 (7×); M p. 32 |
| +0765 | LRS | shift AC+MQ(1–35) right; MQ sign ← AC sign | J 90.05 PDF 203 (7×); M p. 32 |
| −0763 | LGL | shift AC(Q,P,1–35)+MQ(S,1–35) left; overflow into/through P | J 90.05 PDF 205 (12×); M p. 32 |
| −0765 | LGR | shift AC(Q,P,1–35)+MQ(S,1–35) right; no indicators | J 90.05 PDF 208 (2×); M p. 32 |
| −0773 | RQL | rotate MQ(S,1–35) left, circular; no bits lost | J 90.05 PDF 208 (7×); M p. 32 |
| +0761 | NOP | no operation | J 90.02.12 (SYS)162 OP word); M p. 35 |
| +0114 | CVR | convert by replacement from the AC, count C, table at Y | J 90.02.12 (SYS)162 OP word); M p. 56 |

Shift counts: the shift magnitude is the effective address modulo 400 octal
(M p. 31).

NOP and CVR are attested as the OP word of the SYS)162 alphabetic-compare
calling sequence (J 90.02.12). Under D0.3 the Dart handler for SYS)162 reads
that word as a parameter, so the CPU itself may never execute a CVR; both are
implemented anyway because they are attested in generated code and fully
documented (M pp. 35, 56), which keeps the core correct if a future runtime
routine executes its OP word.

## 6. Semantics notes and recorded decisions

- **ADD/SUB minus zero.** Operands of equal magnitude and different signs
  give a result sign equal to the original AC sign (M p. 20). Signs alike
  add magnitudes; signs unlike run the documented ones-complement
  subtraction with end-around Q carry and recomplement (M p. 20, Figure 21).
  The implementation follows that algorithm literally.
- **Overflow gating (ED-2).** The manual states the trigger as "a carry from
  position 1 to position P" (M pp. 9, 11). In the unlike-signs complement
  path, internal carries can ripple through P even when the algebraic result
  is small (example: 3 − 5). The emulator sets overflow only when the
  effective operation is a true addition of magnitudes (effective signs
  alike) whose sum carries out of position 1. This matches every attested
  use; the complement-path corner is unobservable in the subset (no TOV,
  TNO, or DCT is harvested). Recorded as a decision, not as attested fact.
- **MPY with a zero factor.** If the magnitude of C(Y) is zero, AC and MQ
  are cleared and the sign rule still applies, so −0 results are possible
  (M p. 22). Implemented exactly.
- **DVP divide check.** The check compares against the full 37-bit AC
  magnitude: a 1 in Q or P forces the check (M p. 24). On a check the
  dividend is unchanged, the indicator turns on, and the computer proceeds.
- **Shifts execute stepwise (ED-5).** One register step per shift count,
  exactly as the flow charts describe (M pp. 31–32, Figure 26). This makes
  counts ≥ 36 and the overflow triggers correct by construction; the maximum
  count is 255, so cost is negligible.
- **LGL overflow trigger (ED-2a).** "Into or through position P" (M p. 32)
  is implemented as: a 1 moved from position 1 into P at any step. A 1 that
  starts in P and leaves toward Q does not trigger. Recorded as an
  interpretation of the manual sentence.
- **0760-family dispatch (ED-3).** COM's address 00006 is part of the
  operation code, and the manual warns that address modification may change
  the instruction (M p. 49). The emulator computes the modified address and
  requires 00006; any other value throws `UnimplementedOpcode7090` naming
  the modified sub-operation.
- **Fail-loud decode (ED-4).** `decode` never throws (a disassembler must
  render any word); the CPU throws `UnimplementedOpcode7090` — carrying the
  signed octal opcode and the IC — when asked to *execute* anything outside
  the subset, including +0000 (HTR), which is what an executed PZE parameter
  word would decode to.
- **CVR.** Implemented by the manual's seven numbered steps (M p. 56),
  including the rule that an initial 1 in Q survives in position 5 of the
  AC regardless of the table word, and the tag-bit-20 XR1 update on
  completion.

## 7. Errors

`UnimplementedOpcode7090` (a typed exception) reports: the signed octal
operation code (or type-A prefix, or 0760-family sub-address), the location
of the instruction, and the full instruction word in octal. The CPU throws it
before any state change, so a failed step never half-executes. Address and
tag arithmetic cannot fault (all fields are masked to their hardware widths);
memory indices are always 15-bit, so no out-of-range access exists.

## 8. Out of scope (and why)

- **Data channels, tapes, card units, printer, all I/O instructions**
  (RDS/WRS/TCO/TEF/IOCP-family, …): D0.7 emulates I/O at the IOCS level;
  generated CPU code reaches I/O only through SYS)/IOC) entry points, and
  none of these opcodes appears in the harvest.
- **Floating point** (FAD/FMP/…): absent from the harvest. COMTRAN
  floating-point operations route through MOVPAK/SYS) subroutines
  (J 90.02.11.01 ff.), which are high-level handlers under D0.3.
- **Trapping modes, STR, ETM/LTM/TTR, data-channel traps**: no trap
  instruction is harvested; the CT Monitor boundary is a high-level handler.
- **Halts (HTR, HPR) and console devices** (ENK, sense switches/lights):
  STOP compiles to SYS)178/SYS)177/IOC)40 calls, not to halt instructions
  (D2.7); an executed +0000 word signals a broken program and throws.
- **Convert CRQ/CAQ, and the rest of the ~200-instruction set**: not
  harvested; every one decodes to a typed throw, never to silence.

Widening the subset later is additive: one decode-table entry, one execute
case, one manual citation, one test group.
