# Numeric moves and edited stores — generated-code specification

Family scope: every MOVE whose source or target is an external-decimal (XD),
edited (EF) or internal-decimal (ID) field. Seven shapes, N1 to N7. The
alphameric movers (SYS)239 to SYS)242), the figurative fills (SYS)243 to
SYS)245) and the arithmetic tails belong to other families.

Word counts are stated as formulas over `ItemSemantics` and `Pictorial`
facts, then cross-checked by octal LOC subtraction. Every LOC in this
document is octal.

## 0. Notation and the two-line ledger this spec keeps

Names used below, all reachable from `lib/src/data/data_map.dart` unless the
"Accessors this spec needs" section says otherwise:

| Name | Meaning | Where it comes from |
|---|---|---|
| `S` | the move's source item | resolved operand |
| `T` | the move's target item | resolved operand |
| `T.digitCount` | count of `9`, `8`, `*` and overpunched-digit positions in the whole target pictorial | `Pictorial.digitCount` |
| `T.fractionDigits` | fraction positions | `Pictorial.fractionDigits` |
| `T.intDigits` | `T.digitCount - T.fractionDigits` | derived; see §7 |
| `T.leadingSuppress` | length of the leading run of `8` or `*` positions | **new accessor**, §7 |
| `byte` | `startChar % 6` | `ItemSemantics.byte` |

Two labels are used, and the difference is the point of the document:

- **Derived** — the rule follows from [J 90.02.xx] text or from a binding
  decision record, and the sample agrees.
- **Pinned at the diff** — the rule is read off the 1962 object listing and
  nothing in either manual states it. It reproduces the listing; it is not
  known to be the 1962 compiler's rule.

## 1. Shape N1 — the edited store from the accumulator (SYS)267)

The dominant shape. 25 sites, every one of the sample's SYS)180 calls.

### Trigger

`S` is internal decimal (the value is already in the AC as a binary integer,
either loaded by a `CLA` or left there by an expression), and
`T.fieldClass` is edited field. Selected ahead of every step-list family
because no source *character* field exists to walk.

### Word sequence

```
CLA    S                       ; omitted when the value is already in the AC
LRS    35                      ; shape N2, conditional — see §2
DVP    CP)+t                   ; shape N2, conditional
TSX    SYS)180,4
PZE    T,,T.byte
TXI    SYS)267,1,editControl   ; or TRA SYS)267,0,0 — see "the zero variant"
OCT    controlWord
AXT    T.digitCount,1
```

Operands, all from the target:

- `PZE T,,T.byte` — `T`'s symbol, and the decrement is `T.byte`, the
  character offset inside its word. **Derived** from [J 90.02.15]
  (`SYS)180` takes a TARGET-ADDRESS-REFERENCE) and [J 90.02.11]
  (`PZE LOC,,BYTE`). Verified 8/8 against the PAYRECORD layout: HRS starts
  at character 35 and prints `,,5`; GROSS at 43 prints `,,1`; WHT 53 `,,5`;
  FICA 63 `,,3`; BONDEDUCTION 72 `,,0`; INS.PREM 81 `,,3`; RET.PREM 90
  `,,0`; NETPAY 100 `,,4`.

- `editControl` — the TARGET-EDIT-CONTROL bit set of [J 90.02.17] Note 1,
  OR-ed over the target pictorial: `01` asterisks, `02` comma(s), `04`
  decimal point, `10` dollar sign, `20` blank-when-zero. Those five values
  are **octal**, and **the assembler operand prints in decimal**: LOC 01146
  prints `TXI SYS)267,1,12` and punches decrement octal `00014` — dollar
  (`10`) plus decimal point (`04`) for the target `$8889.99`. Emit the
  decimal rendering of the octal bit set. **Derived**, and the 01146 site
  is the one that separates the two readings.

- `controlWord` — the TARGET-CONTROL-WORD of [J 90.02.17] Note 2, one
  36-bit word printed as 12 octal digits:

  | Field | Octal digits | Content |
  |---|---|---|
  | Prefix | 1 | 0 with no comma in the target; otherwise digits left of the first comma |
  | Decrement | 2–6 | `T.intDigits` — count of `8`, `9`, `*` left of the real or implied point |
  | Tag | 7 | TARGET-SIGN-CONVENTION: 0 none, 1 overpunch minus, 2 overpunch plus, 3 right minus, 4 right plus, 5 left minus, 6 left plus |
  | Address | 8–12 | `T.leadingSuppress` — count of leading `*` or `8` |

  Three distinct words occur, and all three decode exactly:
  `000005000004` = prefix 0, decrement 5, tag 0, address 4, for `88889.99`;
  `000004000003` for `8889.99` and for `8889.9`; `000003000001` for
  `899V99`. **Derived.**

- `AXT T.digitCount,1` — NUMBER-OF-DIGITS-TO-CONVERT, [J 90.02.30]. The
  count rides in the AXT **address** field, not the decrement: LOC 01150
  prints `AXT 6,1` and punches `0774 00 1 00006`. The value is the target
  pictorial's total digit-position count, integer plus fraction —
  equivalently the control word's decrement plus `T.fractionDigits`.
  **Derived**, and pinned hard by the one site that separates it from the
  control-word decrement: LOC 00437–00440 stores into PAYRECORD HRS
  (`8889.9`), where the control word is `000004000003` but the AXT is `5`,
  not `6`. Every other target in the sample has 2 fraction digits.

### The zero variant (LOC 01327)

When `editControl` computes to 0 — the target is a numeric-edited field
with no asterisk, comma, point, dollar or blank-when-zero, which for
`899V99` means the point is implied by `V` — the compiler emits a real
`TRA`, not a `TXI` with a zero decrement:

```
TRA    SYS)267,0,0
```

The octal decides this and it is not a printing convention: LOC 01327
punches `0020 00 0 00413` (opcode 0020, TRA) while LOC 00376 punches
`1 00004 1 00413` (prefix 1, TXI). Same address, different instruction.
The word count is unchanged.

**Pinned at the diff.** [J 90.02.30] writes the `TXI` form only. One site.

### Word count

```
N1 = load + downscale + 5
  load      = 1 when the value must be loaded (CLA S), 0 when an expression
              left it in the AC
  downscale = 2 when shape N2 applies (§2), else 0
```

The five-word call — `TSX`, `PZE`, `TXI`/`TRA`, `OCT`, `AXT` — is constant.
It does not vary with the pictorial, with the edit control, or with the
zero variant. Cross-checks: LOC 00373 to 00401 is 6 words
(0o401 − 0o373 = 6); LOC 00423 to 00433 is 8 (0o433 − 0o423 = 8).

### Sites

| LOC | Statement | Source → target | edit | OCT | AXT | N2 |
|---|---|---|---|---|---|---|
| 00373–00400 | 199 CORRESPONDING | GRAND.TOTALS GROSS `IR9(5)V99` → PAYRECORD GROSS `88889.99` | 4 | …5…4 | 7 | no |
| 00401–00406 | 199 CORRESPONDING | GRAND.TOTALS WHT → PAYRECORD WHT `88889.99` | 4 | …5…4 | 7 | no |
| 00407–00414 | 199 CORRESPONDING | GRAND.TOTALS FICA `IR9(4)V99` → PAYRECORD FICA `8889.99` | 4 | …4…3 | 6 | no |
| 00415–00422 | 199 CORRESPONDING | GRAND.TOTALS BONDEDUCTION → PAYRECORD BONDEDUCTION `8889.99` | 4 | …4…3 | 6 | no |
| 00423–00432 | 199 CORRESPONDING | GRAND.TOTALS NETPAY `IR9(5)V99` → PAYRECORD NETPAY `8889.99` | 4 | …4…3 | 6 | **yes** |
| 00433–00440 | 199 explicit | GRAND.TOTALS HOURS `IR9(4)V9` → PAYRECORD HRS `8889.9` | 4 | …4…3 | **5** | no |
| 00441–00446 | 199 explicit | GRAND.TOTALS INSURANCE → PAYRECORD INS.PREM `8889.99` | 4 | …4…3 | 6 | no |
| 00447–00454 | 199 explicit | GRAND.TOTALS RETIREMENT → PAYRECORD RET.PREM `8889.99` | 4 | …4…3 | 6 | no |
| 00506–00513 | 199 explicit | GRAND.TOTALS BONDPURCHASES → PAYRECORD BONDENOMINATION `88889.99` | 4 | …5…4 | 7 | no |
| 01070–01075 | 208 CORRESPONDING | WORKING GROSS → PAYRECORD GROSS | 4 | …5…4 | 7 | no |
| 01076–01103 | 208 CORRESPONDING | WORKING FICA → PAYRECORD FICA | 4 | …4…3 | 6 | no |
| 01104–01111 | 208 CORRESPONDING | WORKING WHT → PAYRECORD WHT | 4 | …5…4 | 7 | no |
| 01112–01121 | 208 CORRESPONDING | WORKING NETPAY `IR9(5)V99` → PAYRECORD NETPAY `8889.99` | 4 | …4…3 | 6 | **yes** |
| 01141–01150 | 208 explicit | WORKING NETPAY → CHECK AMOUNT `$8889.99` | **12** | …4…3 | 6 | **yes** |
| 01273–01300 | **219** | MASTER BONDEDUCTION `IR99V99` → PAYRECORD BONDEDUCTION `8889.99` | 4 | …4…3 | 6 | no |
| 01324–01331 | 221 CORRESPONDING | MASTER BONDENOMINATION `IR999V99` → BONDORDER BONDENOMINATION `899V99` | **0** | …3…1 | 5 | no |
| 01474–01501 | 228 CORRESPONDING | INTERNAL.TOTALS HOURS `IR9999V9` → DEPARTMENT.TOTAL HOURS `8889.9` | 4 | …4…3 | **5** | no |
| 01502–01507 | 228 | INTERNAL.TOTALS GROSS → DEPARTMENT.TOTAL GROSS `88889.99` | 4 | …5…4 | 7 | no |
| 01510–01515 | 228 | INTERNAL.TOTALS WHT → DEPARTMENT.TOTAL WHT | 4 | …5…4 | 7 | no |
| 01516–01523 | 228 | INTERNAL.TOTALS FICA → DEPARTMENT.TOTAL FICA `8889.99` | 4 | …4…3 | 6 | no |
| 01524–01531 | 228 | INTERNAL.TOTALS BONDEDUCTION → DEPARTMENT.TOTAL BONDEDUCTION | 4 | …4…3 | 6 | no |
| 01532–01537 | 228 | INTERNAL.TOTALS INSURANCE → DEPARTMENT.TOTAL INSURANCE | 4 | …4…3 | 6 | no |
| 01540–01545 | 228 | INTERNAL.TOTALS RETIREMENT → DEPARTMENT.TOTAL RETIREMENT | 4 | …4…3 | 6 | no |
| 01546–01553 | 228 | INTERNAL.TOTALS NETPAY `IR9(5)V99` → DEPARTMENT.TOTAL NETPAY `88889.99` | 4 | …5…4 | 7 | no |
| 01554–01561 | 228 | INTERNAL.TOTALS BONDPURCHASES → DEPARTMENT.TOTAL BONDPURCHASES `88889.99` | 4 | …5…4 | 7 | no |

`…5…4` abbreviates `000005000004`; `…4…3` is `000004000003`; `…3…1` is
`000003000001`.

One correction to M4-9. Its case 3 reads "the sample varies `edit` between 4
and 12 while the `AXT` holds 6". That is true only of the two sites it
compares — LOC 01273 (statement 219) and LOC 01141 (CHECK AMOUNT), which do
both hold 6. Across the 25 sites the AXT takes 5, 6 and 7, and it tracks
`T.digitCount`. Do not carry "the AXT holds 6" into the implementation as a
rule.

Two corrections to the site list this task was given. LOC 01273–01300 is
**statement 219**, `MOVE M.BND.DED TO PAYRECORD BONDEDUCTION`; statement 218
is the two ADDs at LOC 01262–01272. M4-9 also names statement 218 for this
site and should be corrected with it. And LOC 00373–00454 is not all
CORRESPONDING: the expansion is LOC 00373–00432, five pairs, 32 words —
which is exactly the figure M4-9 already records — and LOC 00433–00454 is
statement 199's three explicit MOVEs of HOURS, INSURANCE and RETIREMENT.

Block cross-checks: statement 199's expansion 0o432 − 0o373 + 1 = 32 words;
statement 208's expansion 0o1121 − 0o1070 + 1 = 26 words (three plain plus
one with the downscale); statement 228's expansion 0o1561 − 0o1474 + 1 = 54
words, exactly nine plain stores.

## 2. Shape N2 — the digit-count split divide

```
LRS    35
DVP    CP)+t
```

Two words, emitted between the load and the `TSX SYS)180,4` of shape N1.

### Trigger

`S.shape.digitCount > T.shape.digitCount`. **Derived** — decision record
D4.1(c) already binds this ("When the value stored has more digits than the
target pictorial can hold… Codegen must key the divide on the digit-count
comparison, never on a scale difference"), and the sample confirms it
without exception: 3 sites have the pair and all three move a 7-digit source
into a 6-digit target; the other 22 sites all have `S.digitCount <=
T.digitCount` and none has the pair. The widening case is in the sample too
— LOC 01273 moves a 4-digit `IR99V99` into a 6-digit `8889.99` with no pair.

`CP)+t` holds `10^T.digitCount`. **Derived** from D4.1(c), which states the
constant as `10^(target digit count)` and requires the pool to place
1,000,000 at CP)+24 (`OCT 000003641100`, which is exactly 10^6). All three
sites share that one pool word.

**Not separable from the sample**: every DVP site has source and target
fraction counts equal at 2, so the sample cannot tell "total digit positions
exceed" from "integer digit positions exceed". D4.1(c) settles it in favour
of total digits, and this spec follows the decision record, not the diff.
Likewise, all three sites have `T.digitCount == 6`, so the sample alone
cannot separate `10^T.digitCount` from the literal constant 10^6; D4.1(c)
supplies the exponent.

**Not grounded in either manual**: what the split is *for*. D4.1(c) records
it — the divide leaves the digits that fit as the remainder in the AC and the
excess as the quotient in the MQ, and the runtime takes no action on the
excess. Open Question 28 carries the same note. Do not present the mechanism
as manual-derived.

### Sites

LOC 00424–00425 (statement 199, GRAND.TOTALS NETPAY → PAYRECORD NETPAY);
LOC 01113–01114 (statement 208, WORKING NETPAY → PAYRECORD NETPAY);
LOC 01142–01143 (statement 208, WORKING NETPAY → CHECK AMOUNT).

### Word count

`N2 = 2`, and 0 when the trigger is false. Never any other value.

## 3. The step-list families — the shared frame

Shapes N3 to N6 all move a *character* source (XD or EF) through the MOVPAK
step machinery. Their common frame:

```
<target-pointer preamble>       ; only when the target is a storage field
<source-pointer preamble>
TSX    SYS)182,4
<run>
STO    result                   ; only when the target is the AC-MQ
```

### Family selection

One table, from [J 90.02.15] to [J 90.02.19] and [J 90.02.30]. Keyed on the
source's field class and the target's:

| source | target | head | in sample |
|---|---|---|---|
| XD | XD | SYS)183 | no |
| XD | EF | SYS)185 | **yes** (N5) |
| XD | ID register | SYS)184 | **yes** (N3) |
| EF | XD | SYS)189 | no |
| EF | EF | SYS)190 | **yes** (N6) |
| EF | ID register | SYS)268 | **yes** (N4) |
| ID register | XD | SYS)186 / 187 / 188 by target sign convention | no |
| ID register | EF | SYS)267 | **yes** (N1) |

The XD-versus-EF distinction on the source is what picks SYS)184 over
SYS)268 and SYS)185 over SYS)190, and the sample separates them cleanly:
DETAIL HOURS `99V9` and TABLE.ITEM INSPREM `9V99` are pure `9` runs and take
the XD heads; BONDORDER BONDENOMINATION `899V99` carries an `8` and takes
the EF heads. `Pictorial.hasEditCharacters` is the existing predicate.
**Derived.**

### Pointer preambles

[J 90.02.11] gives three forms, and the entry chosen decides which pointers
must be preset. `SYS)182` presets both, so both preambles are emitted;
`SYS)180` carries the target in its calling sequence, so shape N1 emits
neither.

| Case | Sequence | Words | In sample |
|---|---|---|---|
| 1, working storage | `LDI CP)+nn / STI SYS)132\|133` | 2 | LOC 00577–00600, 01366–01371, 01433–01434, 01452–01453 |
| 1', positional indicator | `LDI PI)n / STI SYS)132` | 2 | LOC 01435–01436, 01445–01446, 01454–01455, 01464–01465 |
| 2, simple base locator | `CAL BL)n / ACL CP)+nn / SLW SYS)132\|133` | 3 | LOC 00571–00573, 00601–00603 |
| 3, complex base locator | `CAL BL)n / ACL CP)+nn1 / PDX 0,4 / TXL *2,4,5 / ACL CP)+nn2 / SLW SYS)132\|133` | 6 | no site |

Case 1' — reading a positional indicator cell through the case-1 `LDI`/`STI`
form — is **pinned at the diff**. [J 90.02.15] Case 3 gives a positional
indicator the form `MON PI)NN,,0` in a SYS)179 calling sequence; the inline
preset of SYS)132 from a PI cell is not written anywhere. Four sites.

**Pinned at the diff**: the target pointer (SYS)133) is set before the source
pointer (SYS)132) when both are emitted. 4/4 sites. Nothing states an order.

### Run shape

```
head word                       ; TXI SYS)18n,1,<control>
OCT  controlWord                ; only for an edited target — SYS)185, 190
<step words>                    ; one per contiguous run of like target positions
terminator                      ; TXI SYS)22n,1,<target numeric length>
```

The head, the OCT and the terminator are fixed per family. The step words
are the variable part, and the run length question reduces entirely to how
many of them there are.

## 4. The step-word rule — the answer to the run-length question

Walk the target's digit positions from the high-order end to the low-order
end. Emit one word per contiguous stretch of positions that get the same
treatment. With `Si`/`Sf` the source's integer and fraction digit counts and
`Ti`/`Tf` the target's:

| Condition | Step word (SYS)185 family / SYS)190 family) | Decrement |
|---|---|---|
| `Ti > Si` | `TXI SYS)212` / `SYS)214` — leading zeros to insert | `Ti - Si` |
| `Si > Ti` | `TXI SYS)201` / `SYS)196` — characters to test for overflow, then `TXI SYS)206` / `SYS)202` — characters to bypass | `Si - Ti` each |
| always | `TXI SYS)193` / `SYS)198` — characters to move | see below |
| `Tf > Sf` | `TXI SYS)211` / `SYS)216` — trailing zeros to insert | `Tf - Sf` |
| `Sf > Tf` | `TXI SYS)206` / `SYS)202` — characters to bypass | `Sf - Tf` |
| SET store, low-order digits discarded, no TRUNCATED | `TRA SYS)220` / `SYS)222` — round | — |

A MOVE never emits the round step (D4.1(d), Jack's call, 2026-08-04).

So, for a MOVE, define the step-word count:

```
steps = (Ti > Si ? 1 : 0)           ; leading zeros
      + (Si > Ti ? 2 : 0)           ; overflow test + high bypass
      + 1                           ; move — always present
      + (Tf > Sf ? 1 : 0)           ; trailing zeros
      + (Sf > Tf ? 1 : 0)           ; low bypass
```

and the run around it:

```
run = 2 + steps + 1                 ; edited target: head + OCT … terminator
run = 1 + steps + 1                 ; register target: head … terminator, no OCT
```

`steps` is 2 at every sample site — the leading-zero word and the move word —
because every sample site has `Ti > Si` and `Tf == Sf`. Its floor is 1. So an
edited-target run is 4 at minimum and 5 everywhere in this program, and a
register-target run is 3 (SYS)268). SYS)184 is outside this formula: it is a
one-word call by definition, with no head-plus-terminator structure.

Decrements: the terminator carries `T.digitCount` (TARGET-NUMERIC-LENGTH).
The move word carries the source's character count.

### What is derived and what is pinned here

**Derived** — the step vocabulary, the per-step decrement meanings, the
family-to-step mapping, and the fact that the terminator is the
target-numeric-length word. All of it is printed in [J 90.02.16] for
SYS)183, [J 90.02.17] for SYS)185, [J 90.02.19] for SYS)189 and SYS)190, and
[J 90.02.30] for SYS)268. M4-9 already states the same rule.

**Derived from 4/4 sites** — the order: leading zeros, then move, then
terminator. The sample never prints two step words that could contest an
ordering, so the general high-order-first walk is an inference. [J 90.02.16]
calls the printed lists menus, not orderings ("two or more of the
following"), and D4.1(d) already treats them that way.

**Unobserved, and stated as a derivation** — the omission of the leading-zero
word when `Ti == Si`. All four sample runs have `Ti > Si` strictly, so the
conditional has never been seen to take its false branch. The rule follows
from the step's own meaning (a count of zero inserts nothing) and from
[J 90.02.16]'s "two or more", which is the manual's own signal that the list
varies. It is not attested.

**Unobserved, no site at all** — the trailing-zero, bypass, overflow-test,
sign-scan and round steps. The sample contains no move where the target has
fewer digits than the source on either end (D4.1's 2026-08-04 pass confirms:
none of the 51 MOVPAK calls discards a low-order digit), no `S` filler
anywhere, and no comma'd or signed target pictorial. Their existence, their
mnemonics and their decrement meanings are manual facts; their *emission
conditions* are this spec's construction from those meanings.

**Three readings, one number** — the move word's decrement. At every observed
site the source's `storageChars`, its `digitCount`, and
`min(Si,Ti) + min(Sf,Tf)` are the same integer: 3 for `99V9`, 5 for
`899V99`, 3 for `9V99`. Nothing in the sample separates them, because no
source carries a comma, a point, an `S` or a sign, and no source is wider
than its target. Use `min(Si,Ti) + min(Sf,Tf)` — it is the only one of the
three that stays correct when a bypass step is present, and it agrees with
the other two on the whole sample.

### What evidence would settle the unobserved cases

Nothing in the two manuals will. The step-emission conditions are simply not
written; [J 90.02.16] to [J 90.02.19] print menus. Only a second compiled
listing — a program that moves a wide numeric field into a narrow one, or a
field with a comma'd or signed pictorial — would decide them. No such
listing survives in this repository.

## 5. Shapes N3 to N6 — the four attested step-list moves

### N3 — external decimal to internal decimal (SYS)184)

Trigger: `S` is external decimal, the target is a register (the MOVE feeds
arithmetic, or the target is an ID field reached through the hub).

```
<source-pointer preamble>
TSX    SYS)182,4
TXI    SYS)184,1,S.storageChars
STO    result                   ; when an ID field receives the value
```

Run length is 1, always. [J 90.02.16] writes SYS)184 as a complete one-word
call with the character count in its own decrement; there is no OCT (no
target field to describe) and no terminator. **Derived.**

```
N3 = sourcePreamble + 1 + 1 + (store ? 1 : 0)
```

Sites, all three with a store:

- LOC 00571–00576, statement 202 (`MOVE DETAIL HOURS TO WORKING HOURS`,
  `99V9` → `IR99V9`). Preamble 3, total 6 words: 0o577 − 0o571 = 6 ✓.
- LOC 01445–01451, statement 225 (INSPREM `9V99` → WORKING INSURANCE).
  Preamble 2, total 5 words: 0o1452 − 0o1445 = 5 ✓.
- LOC 01464–01470, statement 225 (RETPREM `9V99` → WORKING RETIREMENT).
  Preamble 2, total 5 words: 0o1471 − 0o1464 = 5 ✓.

### N4 — edited field to internal decimal (SYS)268)

Trigger: `S` is an edited field, target is a register.

```
<source-pointer preamble>
TSX    SYS)182,4
TXI    SYS)268,1,1
TXI    SYS)269,1,S.storageChars      ; characters to convert
TXI    SYS)275,1,<numeric length>    ; terminator
STO    result
```

The head's decrement is the literal 1 ([J 90.02.30] writes
`TXI SYS)268,1,1`). No OCT word: the target is a register, so there is no
target control word. **Derived.**

```
N4 = sourcePreamble + 1 + run + (store ? 1 : 0),  run = 1 + steps + 1
```

`steps` is the §4 count, drawn here from the SYS)269 to SYS)273 and SYS)276
to SYS)282 menu. With a register target there is no target pictorial, so the
zero-insert and bypass conditions cannot fire and `steps` is 1 — the convert
word alone.

One site: LOC 01354–01362, statement 221 (BONDORDER BONDENOMINATION `899V99`
into the AC, then `STO 3.RS)1` for the following ADD). Preamble 2, run 3,
total 7 words: 0o1363 − 0o1354 = 7 ✓.

The SYS)275 decrement is 5, which equals both `S.digitCount` and
`S.storageChars` for `899V99`. [J 90.02.30] calls it
TARGET-DECIMAL-NUMERIC-LENGTH; with a register target the two readings
cannot be separated. **Pinned at the diff** at one site; use
`S.digitCount`.

### N5 — external decimal to edited field (SYS)185)

Trigger: `S` external decimal, `T` edited field.

```
<target-pointer preamble>
<source-pointer preamble>
TSX    SYS)182,4
TXI    SYS)185,1,editControl
OCT    controlWord
<step words>
TXI    SYS)225,1,T.digitCount
```

`editControl` and `controlWord` are computed exactly as in shape N1 §1 —
[J 90.02.17] is the single home of both formats and [J 90.02.30] refers
SYS)267 back to it. **Derived.**

```
N5 = targetPreamble + sourcePreamble + 1 + run,  run = 2 + steps + 1
```

Three sites, all with run 5:

- LOC 00577–00611, statement 202: DETAIL HOURS `99V9` → PAYRECORD HRS
  `8889.9`. `TXI SYS)185,1,4` / `OCT 000004000003` /
  `TXI SYS)212,1,2` (Ti 4 − Si 2) / `TXI SYS)193,1,3` /
  `TXI SYS)225,1,5`. Preambles 2 + 3, total 11 words:
  0o612 − 0o577 = 11 ✓.
- LOC 01433–01444, statement 225: TABLE.ITEM INSPREM `9V99` → PAYRECORD
  INS.PREM `8889.99`. `TXI SYS)212,1,3` (Ti 4 − Si 1) /
  `TXI SYS)193,1,3` / `TXI SYS)225,1,6`. Preambles 2 + 2, total 10 words:
  0o1445 − 0o1433 = 10 ✓.
- LOC 01452–01463, statement 225: RETPREM `9V99` → PAYRECORD RET.PREM
  `8889.99`. Identical shape, 10 words: 0o1464 − 0o1452 = 10 ✓.

### N6 — edited field to edited field (SYS)190)

Trigger: `S` and `T` both edited fields.

```
<target-pointer preamble>
<source-pointer preamble>
TSX    SYS)182,4
TXI    SYS)190,1,editControl
OCT    controlWord
<step words>                       ; SYS)214 leading zeros, SYS)198 move, …
TXI    SYS)226,1,T.digitCount
```

`N6` has the same formula as `N5`. One site: LOC 01366–01377, statement 221,
BONDORDER BONDENOMINATION `899V99` → PAYRECORD BONDENOMINATION `88889.99`.
`TXI SYS)190,1,4` / `OCT 000005000004` / `TXI SYS)214,1,2` (Ti 5 − Si 3) /
`TXI SYS)198,1,5` / `TXI SYS)226,1,7`. Preambles 2 + 2, total 10 words:
0o1400 − 0o1366 = 10 ✓.

### Reconciling the run lengths this task was given

The four numbers quoted in the task — one word at 00575, five at
00605–00611, four at 01373–01377, five at 01440–01444 — are two different
counts. **Every edited-target run in the sample is 5 words**: head, OCT, and
three TXIs. The "four" at 01373–01377 counted TXI words and skipped the
`OCT 000005000004` at 01374; that run is `TXI SYS)190` / `OCT` /
`TXI SYS)214` / `TXI SYS)198` / `TXI SYS)226`, five words, LOC 01373 to
01377 inclusive. The genuine variation is 1 (SYS)184), 3 (SYS)268), 5 (the
two edited-target families) — and it is explained entirely by whether the
target is a register or a field, not by the pictorials. Within the
edited-target families the pictorials never move the run off 5 anywhere in
this program.

## 6. Shape N7 — the internal-decimal in-line move

```
CLA    S
STO    T
```

Trigger: both operands internal decimal, right justified, equal scale,
single precision. No MOVPAK entry at all.

One site: LOC 01417–01420, statement 225, `MOVE INDEX TO POS`, both `IR99`.

**Family boundary.** This shape is listed here for completeness because it is
a numeric move, but it is the same two words the arithmetic family emits for
a bare store, and D4.2 records that an ID right-justified target "is stored
by a bare `STQ`/`STO` with no MOVPAK call at all". Chunk B1 should count it
once. Recommend the arithmetic family (M4-10) owns it; this spec claims only
the note.

`N7 = 2`.

## 7. Accessors this spec needs that `ItemSemantics` does not have

The generator can reach `fieldClass`, `shape`, `justification`,
`storageChars`, `digits`, `fractionDigits`, `quantity`, `startChar`, `word`,
`byte`, and through `shape` the whole public `Pictorial` surface. Three
facts are not reachable and must be added to `Pictorial`:

1. **`leadingSuppress`** — the length of the leading run of `8` or `*`
   positions. Feeds the control word's address field. `88889.99` → 4,
   `8889.99` → 3, `899V99` → 1.
2. **`digitsBeforeFirstComma`** — 0 when the pictorial holds no comma,
   otherwise the count of digit positions left of the first comma. Feeds the
   control word's prefix. **No sample site**; every target pictorial in the
   program is comma-free, so the accessor's correctness rests on
   [J 90.02.17] Note 2 alone.
3. **Per-character edit flags** — asterisk, comma, period, dollar, and
   blank-when-zero, separately. `hasEditCharacters` is one boolean over the
   whole set and cannot build the five-bit edit control. Only the period,
   the dollar and their absence are exercised; asterisk, comma and
   blank-when-zero have **no site**.

`intDigits` needs no accessor: `shape.digitCount - shape.fractionDigits` is
correct for every pictorial in the sample. It is wrong for a trailing-`S`
scaled integer, where `fractionDigits` is negative by design; guard that
case before using it. No such field appears in the program, so the guard is
unexercised.

`digitCount` versus `digits` for the AXT and the terminator: they differ only
when the pictorial carries `S` fillers, which reserve no storage. No sample
pictorial has one. This spec uses `digitCount` (stored digit positions),
because the AXT counts digits the converter writes into the target field.
**Unattested**; a target with an `S` would decide it.

## 8. The complete ledger of what is not grounded

Each line is a rule this spec states that the manuals do not.

1. **`TRA SYS)267,0,0` replaces the `TXI` when the edit control is 0.**
   Pinned at the diff, one site (LOC 01327), confirmed by the punched
   opcode. [J 90.02.30] prints the `TXI` form only.
2. **The leading-zero step is omitted when `Ti == Si`.** Derivation from the
   step's meaning; no site takes the false branch.
3. **Step ordering is a high-order-first walk of the target.** Inferred from
   4 sites, each of which prints only one non-terminal step. [J 90.02.16]
   states the lists are menus.
4. **The trailing-zero, bypass, overflow-test and sign-scan steps' emission
   conditions.** Constructed from the mnemonics. Zero sites.
5. **The move word's decrement is `min(Si,Ti) + min(Sf,Tf)`.** Three
   readings agree on every site; this one is chosen because it survives a
   bypass. Unseparated by evidence.
6. **The control word's prefix field (digits left of the first comma).**
   [J 90.02.17] Note 2 only. No comma'd pictorial in the program.
7. **The control word's tag field (sign convention).** Every site prints 0.
   The seven-value table is [J 90.02.17] Note 2 only.
8. **The edit-control bits for asterisk (01), comma (02) and blank-when-zero
   (20).** [J 90.02.17] Note 1 only. Only the decimal point (04) and the
   dollar sign (10) are exercised.
9. **`LDI PI)n / STI SYS)132` as a pointer preamble.** Pinned at the diff, 4
   sites. [J 90.02.15] Case 3 gives a positional indicator the `MON PI)NN,,0`
   form in a SYS)179 sequence instead.
10. **The target pointer is set before the source pointer.** Pinned at the
    diff, 4/4. No text.
11. **SYS)275's decrement is the source's digit count.** One site, where the
    source's `digitCount` and `storageChars` coincide.
12. **The digit-split divide's divisor is `10^T.digitCount`, and the trigger
    is a total-digit comparison.** Both come from decision record D4.1(c),
    not from the manuals; the sample has one divisor value (10^6) and equal
    fraction counts at all three sites, so it separates neither.
13. **An edited store into a buffer-located target.** Every one of the 25
    SYS)267 sites reaches its target through a statically-addressed
    `PZE T,,byte`. Whether a located target would instead preset SYS)133 and
    go through SYS)182 is not attested. Do not assume the fallback.
14. **SYS)179, SYS)181, SYS)183, SYS)186, SYS)187, SYS)188 and SYS)189 have
    no site anywhere in the listing.** Their shapes above are manual
    transcription, nothing more.
15. **Double-precision sources.** Every numeric source in the program fits
    one word, so the single `CLA` load of shape N1 is all the sample shows.
    A source over 10 digits ([J 02.05.06]) would need a second load word and
    that word is unattested.

## 9. Word-count summary for chunk B1

| Shape | Formula | Sample totals |
|---|---|---|
| N1 edited store | `load + N2 + 5` | 6; 8 with the downscale |
| N2 downscale | `2` if `S.digitCount > T.digitCount` else `0` | 2 or 0 |
| N3 XD→ID | `srcPre + 1 + 1 + store` | 6 (srcPre 3); 5 (srcPre 2) |
| N4 EF→ID | `srcPre + 1 + run + store`, `run = 1 + steps + 1` | 7 (2+1+3+1) |
| N5 XD→EF | `tgtPre + srcPre + 1 + run`, `run = 2 + steps + 1` | 11 (2+3+1+5); 10 (2+2+1+5) |
| N6 EF→EF | `tgtPre + srcPre + 1 + run`, `run = 2 + steps + 1` | 10 (2+2+1+5) |
| N7 ID→ID | `2` | 2 |

Preamble: 2 for working storage or a positional indicator, 3 for a simple
base locator, 6 for a complex one, 0 when shape N1 carries the target in its
calling sequence.

`steps` is the §4 count. It is 2 at every edited-target site (leading zeros
plus move) and 1 at the one register-target site (convert alone). Its floor
is 1.

Whole-block cross-checks against the LOC column: statement 199's
CORRESPONDING expansion LOC 00373–00432 is 32 words, five N1 units of which
one carries N2 — 5×6 + 2 = 32 ✓, the figure M4-9 already records. Statement
208's expansion LOC 01070–01121 is 26 words, four N1 units of which one
carries N2 — 3×6 + 8 = 26 ✓. Statement 228's expansion LOC 01474–01561 is 54
words, nine plain N1 units — 9×6 = 54 ✓. The sample holds 25 SYS)180 calls
and 26 SYS)182 calls, of which 8 are this family's step lists; D4.1's
2026-08-04 pass counts the same 51.

The `LAC BL)n,i` / `TXL SYS)294,i,0` locator-load guards are M4-9's
addressing rules and are **not** counted in any formula above; B1 must not
double-count them against this family.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 02.05.06]: ../../../../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 90.02.11]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.15]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.16]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.17]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.19]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.30]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
