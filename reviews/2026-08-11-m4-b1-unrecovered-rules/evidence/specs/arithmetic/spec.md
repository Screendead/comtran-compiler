# Family: SET, ADD, result storage and TR()

The expression compiler of M4-10. Every word count below was taken by octal
subtraction on the LOC column of `test/fixtures/90.05-object-listing.target`
and checked twice. All LOC values in this file are octal, as printed.

Scale notation: `S(x)` is the compile-time scale of `x`, in powers of ten. For
a data item `S(x) = ItemSemantics.fractionDigits`. For a written literal
`S(lit)` is the count of digits after the decimal point as keyed. The pool word
for a literal holds the literal times 10^S(lit) as an integer.

Register notation: AC is the accumulator, MQ the multiplier-quotient. Every
shape below tracks which of the two holds the live value, because that choice
alone selects `STO` against `STQ` and selects whether an `XCA` is emitted.

---

## 0. Facts the generator needs, and where it gets them

| Fact | Source in `lib/src/data/data_map.dart` |
|---|---|
| scale of an operand or target | `ItemSemantics.fractionDigits` |
| digit capacity | `ItemSemantics.digits` |
| whether the operand is binary already | `ItemSemantics.fieldClass == FieldClass.internalDecimal` |
| whether the operand needs a MOVPAK convert | `fieldClass` in {`externalDecimal`, `edited`, `alphameric`, `floatingPoint`, `scientificDecimal`} |
| whether the operand needs a base locator | `RecordInfo.located` of the operand's record |
| word displacement inside a located record | `ItemSemantics.word` |

Nothing else in `ItemSemantics` is read by this family.

---

## 1. Shape A1 — the additive chain

**Trigger.** A `SET` right-hand side, or an `ADD` source, whose top node is a
sum or difference of two or more terms. Selected in preference to every other
shape whenever the top operator is `+` or `-`.

**Word sequence.** The chain accumulates in the AC. Operands are taken in
written order.

```
<prep of operand 1>
CLA    <operand 1>
<prep of operand 2>
ADD    <operand 2>          (SUB for a subtracted term)
...
<prep of operand n>
ADD    <operand n>
<store, shape A5>
```

**Operand prep.** Each operand is one of five kinds. Only kinds (c), (d) and
(e) consume an RS cell.

| Kind | Test | Prep words |
|---|---|---|
| (a) plain, working storage, `fieldClass == internalDecimal`, `fractionDigits` equal to the chain scale | — | 0 |
| (b) as (a) but in a located record | `RecordInfo.located` | 2, shape A0 |
| (c) a product or quotient term | top operator of the term is `*` or `/` | shape A3 then a park, shape A2 |
| (d) a parenthesized sub-chain | the term is itself a sum or difference | shape A1 recursively then a park, shape A2 |
| (e) any operand whose scale is below the chain scale, or whose `fieldClass` is not `internalDecimal` | — | shape A4 or shape A6 then a park, shape A2 |

**Chain scale.** The chain scale is the maximum `fractionDigits` over the
operands. Every lesser-scaled operand is raised to it by shape A4. The chain is
never downscaled. This is M4-10's stated rule and it is attested: statement
203's literal `20` is multiplied by 100 at run time rather than folded to 2000.

**Word count.**

```
W(A1) = 1                      # the CLA
      + (n - 1)                # one ADD or SUB per further operand
      + sum over operands of P # the prep table above
```

`P` is 0, 2, or the sub-shape's own count plus one park word.

**Sites.**

| LOC | Statement | Shape |
|---|---|---|
| 00625–00626 | 203,00 THEN | n = 2, both operands parked |
| 00722–00732 | 207,00 | n = 6, one located operand |
| 01177–01201 | 211,00 second command | n = 2, `ADD ... TO`, shape A7 |
| 01207–01213 | 212,00 | outer n = 2, inner sub-chain n = 2 |
| 01227–01230 | 215,00 first command | n = 2, second operand parked |
| 01265–01272 | 218,00 | two `ADD ... TO` targets |
| 01307–01311 | 220,00 THEN | n = 2, both plain |
| 01363–01365 | 221,00 | `ADD ... TO`, source parked after a convert |
| 00733–00770, 01565–01617 | 208,00, 228,00 | `ADD CORRESPONDING`, shape A8 |

**Worked check — statement 207,00, the six-operand equal-scale chain.**
Source: `SET WORKING NETPAY = WORKING GROSS - WORKING FICA - WORKING WHT -
WORKING RETIREMENT - WORKING INSURANCE - M.BND.DED.` Scales, from the
pictorials: `IR9(5)V99`, `IR9(4)V99`, `IR9(5)V99`, `IR9(4)V99`, `IR9(4)V99`,
`IR99V99` — all 2; target `WORKING NETPAY IR9(5)V99` is 2. So no alignment and
no store tail.

```
00722  CLA    4)GROSS
00723  SUB    4)FICA
00724  SUB    4)WHT
00725  SUB    3)RETIREMENT
00726  SUB    3)INSURANCE
00727  LAC    BL)2,1          <- shape A0, M.BND.DED is in the MASTER buffer
00730  TXL    SYS)294,1,0
00731  SUB    1)BONDEDUCTION,1
00732  STO    3)NETPAY        <- shape A5, plain store, value in the AC
```

01732 - 01722 in octal is 10, so 8 decimal, so 9 words. The formula gives
1 + 5 + 2 + 1 = 9. The five equal-scale operands after the first cost exactly
one word each. **This is the equal-scale chain count: one word per operand
after the first, one for the load, one for the store, plus two for each
base-locator load the chain still needs.**

**Citation.** M4-10 ("Equal-scale chains compile direct"); [J 90.02.03] for the
RS references; the counts are read off the listing.

---

## 2. Shape A0 — the base-locator prep

**Trigger.** An operand or target whose record has `RecordInfo.located` true,
where index register `i` does not already hold that base locator on every path
that reaches the reference.

**Word sequence.**

```
LAC    BL)b,i
TXL    SYS)294,i,0
```

**Word count.** 2, or 0 when the register is already live.

**Sites in this family.** 00637–00640 (203,00 OTHERWISE), 00661–00662 (205,00),
00727–00730 (207,00), 01175–01176 (211,00), 01222–01223 (215,00), 01263–01264
(218,00), 01301–01302 (220,00).

**Register liveness — pinned at the diff.** The sample reloads at a label, at a
section entry, and after any MOVPAK calling sequence, and reuses the register
inside a straight run. Two clear reuses: 00760 `CLA 1)GROSS,1` reuses the
register loaded at 00727 one statement earlier; 01256 `CLA 1)WHT,1` reuses
01222. One clear reload for clobber: 01300 `AXT 6,1` is part of the preceding
MOVPAK sequence and destroys XR1, so 01301 reloads. The exact invalidation set
is **not derivable from one program** and is pinned at the diff. The shape
itself and the `TXL SYS)294` guard are M4-9's, cited here only because they
enter this family's word counts.

---

## 3. Shape A2 — the RS park

**Trigger.** A chain operand of kind (c), (d) or (e) in shape A1. That is: the
operand's value must be computed before the chain can run, so it cannot stay in
a register while the chain's other operands are computed.

**Word sequence.** One word.

```
STQ    <cell>      when the computed value is in the MQ (it came from MPY)
STO    <cell>      when the computed value is in the AC (a sub-chain, or a
                   MOVPAK convert that returns in the AC)
```

**Cell name.** `RS)m` in section 0; `k.RS)m` in section k, k above 0. The
period is part of the printed name. Section numbers run 0 for the main body and
increase by 1 for each `BEGIN SECTION` in source order ([J 90.02.03]).

**Cell number m — derived from four sites, thin.** `m` is the count of chain
operands that follow this operand in **source** order.

| Site | Chain in source order | Parked operand | m | Printed |
|---|---|---|---|---|
| 203,00 | `HOURS*1.5`, `20` | `HOURS*1.5` | 1 | `RS)1+0` |
| 203,00 | same | `20` | 0 | `RS)0` |
| 212,00 | `WORKING FICA`, `(MASTER FICA - 144.00)` | the parenthesis | 0 | `1.RS)0` |
| 215,00 | `WORKING GROSS`, `13*EXEMPTIONS` | the product | 0 | `2.RS)0` |
| 221,00 | `BONDORDER BONDENOMINATION`, `INTERNAL.TOTALS BONDPURCHASES` | the source | 1 | `3.RS)1` |

Statement 221 is the site that forces the rule: an `ADD a TO b` chain must be
ordered `a` then `b` in source order for `a` to land in cell 1, even though the
emitted code loads `b` first. Only statement 203 has two cells live at once, so
the rule rests on one discriminating site. **Label: derived from the diff, one
discriminating site.**

**A printed-form variant with no explanation.** Statement 203's park of cell 1
prints `RS)1+0`, with the assembler's `symbol+offset` suffix; the park of cell 0
on the next line prints `RS)0`, and every other park in the program prints the
bare form, including `3.RS)1` which is also a cell above 0. The scan pass
verified `RS)1+0` letter by letter (`test/fixtures/90.05-object-listing-notes.md`
and Open Question 28 both quote it). **Pinned at the diff: emit `RS)1+0` at LOC
00621 and the bare form everywhere else. No rule accounts for it.**

**Sites.** 00621, 00624 (203,00); 01211 (212,00); 01226 (215,00); 01362
(221,00). The compare generator also parks in RS cells — 00532 `SLW RS)0` and
00537 `LAS RS)0` at statement 200,00 — so RS cells are shared between this
family and M4-11's mask extract.

**Citation.** [J 90.02.03]; D4.8 for the two-word cell; M4-10.

---

## 4. Shape A9 — the RS area and its `BSS`

**Trigger.** Always, once per program, after the last procedure word.

**Word sequence.**

```
       USE    1
RS)    BSS    N
```

Omitted when no section used a result storage ([J 90.02.03]).

**What is proved by the sample.** `RS) BSS 30` sits at LOC 01621 and `TS) BSS 7`
at 01657; 01657 - 01621 is 36 octal, 30 decimal, so the reservation is exactly
30 words and the sections are packed with no gap. The five referenced cells give
these absolute addresses and so these word offsets from the base:

| Reference | LOC | Offset from 01621 |
|---|---|---|
| `RS)0` | 01621 | 0 |
| `RS)1` | 01623 | 2 |
| `1.RS)0` | 01627 | 6 |
| `2.RS)0` | 01633 | 10 |
| `3.RS)1` | 01643 | 18 |

Two facts follow and are safe:

1. **A cell is two words.** `RS)1` sits two words above `RS)0`, so
   `address(k.RS)m) = base(k) + 2m`. D4.8 records the same inference. The width
   carries a double-precision value even where single-precision code stores one
   word.
2. **Section blocks are laid out in section-number order and are contiguous.**
   `base(0) = 0`, `base(1) = 6`, `base(2) = 10`, `base(3) = 16` (from
   `3.RS)1` at 18).

**What is not derivable — say so plainly.** [J 90.02.03] says only that "N is
the sum of maximum Result Storage used in each section". The sample reserves
more than it references, and by an amount that does not follow one rule:

| Section | Cells referenced | Highest index | Cells reserved |
|---|---|---|---|
| 0, main body | `RS)0`, `RS)1` | 1 | 3 (6 words) |
| 1, FICA.ROUTINE | `1.RS)0` | 0 | 2 (4 words) |
| 2, WITHOLDING.TAX.ROUTINE | `2.RS)0` | 0 | 3 (6 words) |
| 3, BOND.ROUTINE | `3.RS)1` | 1 | unknown |
| 4, SEARCH; 5, DEPARTMENT.END | none | — | unknown |

Sections 3, 4 and 5 share the remaining 14 words, 7 cells, in an unknown split.
"Highest index used plus one spare cell" fits sections 0 and 1 and fails
section 2 by one cell. No candidate rule I tested fits all three: neither
"operands in the largest chain", nor "non-leaf nodes in the largest statement",
nor "non-leaf nodes minus one" survives statement 207,00, whose six-operand
chain needs no cell at all. **Label: pinned at the diff.** Implement the total
as a compile-time-computed sum of per-section maxima, keep the per-section
maximum behind one function, and expect to tune that function until the golden
listing prints `BSS 30` with the four attested section bases.

---

## 5. Shape A3 — the multiplicative step

**Trigger.** A `*` node. Products accumulate scale and are never downscaled
mid-expression (M4-10).

**Word sequence.** Three entry forms, selected by where the left value already
is.

| Form | Precondition | Words |
|---|---|---|
| A3-load | nothing live; the left operand is a memory word | `LDQ left` then `MPY right` — 2 |
| A3-fromAC | the left value is in the AC, from a chain or a sub-chain | `XCA` then `MPY right` — 2 |
| A3-chain | the left value is already the MQ half of a previous product | `MPY right` — 1 |

Each `MPY`'s operand gets shape A0 first if its record is located.

**Word count.** `W(A3) = 2` for A3-load and A3-fromAC, `1` for A3-chain, plus
2 per base-locator load required.

**Resulting scale.** `S(product) = S(left) + S(right)`. The value is left in the
MQ; the AC holds the high half of the 70-bit product and is discarded.

**Sites.**

| LOC | Statement | Form |
|---|---|---|
| 00617–00620 | 203,00 | A3-load, `LDQ CP)+6 / MPY 3)HOURS` (1.5 x HOURS) |
| 00622–00623 | 203,00 | A3-load, the alignment multiply of shape A4 |
| 00627–00630 | 203,00 | A3-fromAC, `XCA / MPY 1)RATE,2` |
| 00641–00642 | 203,00 OTHERWISE | A3-load, `LDQ 1)RATE,1 / MPY 3)HOURS` |
| 00656–00657 | 205,00 | A3-load, the alignment multiply of shape A4 |
| 01166–01167 | 211,00 | A3-load, `LDQ CP)+9 / MPY 4)GROSS` (.03 x GROSS) |
| 01221–01225 | 215,00 | A3-load then A3-chain: `LDQ CP)+12 / MPY EXEMPTIONS,1 / MPY CP)+31` |
| 01231–01232 | 215,00 | A3-fromAC, `XCA / MPY CP)+11` (x 0.18) |
| 01241–01242 | 215,00 | A3-load, the alignment multiply of shape A4 |
| 01253–01254 | 215,00 | A3-fromAC, `XCA / MPY 4)WHT` (the TR product) |

**Citation.** M4-10; Open Question 28 in `docs/comtran-language-definition.md`
records the same three rules from the same lines.

---

## 6. Shape A4 — the scale alignment of an additive operand

**Trigger.** An additive operand, in a chain or in a comparison, whose scale is
below the chain scale. `k = chainScale - S(operand)`, `k` above 0.

**Word sequence.** The alignment is a real multiply, never a folded constant.

```
<A3-load or A3-chain over the operand>
MPY    CP)+p        where the pool word at p holds 10^k
<disposition>
```

The disposition is one word: `STQ <RS cell>` when the value must park (shape
A2), or `XCA` when the value is needed in the AC immediately, which happens when
it becomes the accumulator operand of a `CAS`.

**Word count.** `W(A4) = W(A3 entry form) + 1 + 1` — that is 3 for the common
`LDQ CP)+lit / MPY CP)+10^k / (STQ|XCA)`, and 4 when the operand is itself a
product that has just finished (`MPY CP)+10^k` chains onto it).

**Sites.**

| LOC | Statement | Text | k |
|---|---|---|---|
| 00622–00624 | 203,00 | `LDQ CP)+7 / MPY CP)+31 / STQ RS)0` — the literal 20 to scale 2 | 2 |
| 00656–00660 | 205,00 | `LDQ CP)+0 / MPY CP)+31 / XCA` — the literal ZERO to scale 2, for the `CAS` against `M.BND.DED IR99V99` | 2 |
| 01225 | 215,00 | `MPY CP)+31` chained onto `MPY EXEMPTIONS,1` — the integer product to `WORKING GROSS`'s scale 2 | 2 |
| 01241–01243 | 215,00 | `LDQ CP)+0 / MPY CP)+31 / XCA` — the literal 0 inside `TR(WORKING WHT GT 0)` | 2 |

**The consequence for comparisons, and it is load-bearing.** When a comparison's
literal needs alignment, the aligned value ends in the AC, so the literal
becomes the `CAS` accumulator operand and the field becomes the storage operand
— the reverse of the usual order. M4-11's skip vector then reads greater,
equal, less against the **literal**, so the vector's arms are mirrored. Both
attested sites do this: 205,00 (`NOT EQUAL`, two slots, `TRA *+2` for greater
into the THEN arm) and 215,00's `TR` (two slots, the true outcome falling
through to `SIR`). When the literal needs no alignment, the field is loaded and
the literal is the storage operand, and the vector reads in the normal sense:
statement 203,00 `CLA 3)HOURS / CAS CP)+5` with `CP)+5` = 400, which is 40.0 at
`WORKING HOURS`'s scale 1, and statement 212,00 `CLA 1)FICA,1 / CAS CP)+10`
with `CP)+10` = 14400, which is 144.00 at scale 2. **A generator that ignores
this will emit correct-looking code with inverted branches.**

**Citation.** M4-10 ("a generic multiply is emitted, never a folded constant");
Open Question 28.

---

## 7. Shape A5 — the store, plain and scaling

**Trigger.** Every result store of a `SET` or an `ADD`. Two forms, selected by
`e = exprScale - ItemSemantics.fractionDigits(target)`.

### A5-plain, `e == 0`

```
STO    <target>     when the value is in the AC
STQ    <target>     when the value is in the MQ
```

**Word count.** 1, plus shape A0 if the target is located.

### A5-scaling, `e > 0`, the store tail

```
XCA                 # the product's low half from the MQ into the AC
ACL    CP)+h        # h = 10^e / 2 — the half-adjust; omitted under TRUNCATED
LRS    35           # push the adjusted value back down into the MQ
DVP    CP)+d        # d = 10^e — quotient to the MQ, remainder to the AC
STQ    <target>
```

**Word count.** `W(A5-scaling) = 5`, or 4 under `TRUNCATED`, plus shape A0 if
the target is located.

**The `ACL` gate.** The half-adjust is present by default. `TRUNCATED`
suppresses the `ACL` word and nothing else; the `XCA / LRS 35 / DVP` scaling
plan is unchanged. That is D4.1(b), and it is a **design decision, not
attested** — `TRUNCATED` is never written in the sample. Note the consequence a
reader should see: with `ACL` gone, `XCA / LRS 35` is a no-op pair for any value
that fits in 35 bits, so a TRUNCATED store emits two words that do no work. The
record chose that over changing the plan.

**Pool allocation.** `d` and `h` are separate pool words. `d` is shared with any
alignment multiply of the same power — `CP)+31` = 100 serves both as the `MPY`
of shape A4 and as the `DVP` of this tail. `h` gets its own word and is used
nowhere else. Attested pairs: `ACL CP)+32` (500) with `DVP CP)+33` (1000), and
`ACL CP)+34` (50) with `DVP CP)+31` (100).

**Sites, all four scaling tails in the program.**

| LOC | Statement | `e` | `h` / `d` |
|---|---|---|---|
| 00631–00635 | 203,00 THEN | 5 - 2 = 3 | `CP)+32` 500 / `CP)+33` 1000 |
| 00643–00647 | 203,00 OTHERWISE | 4 - 2 = 2 | `CP)+34` 50 / `CP)+31` 100 |
| 01170–01174 | 211,00 | 4 - 2 = 2 | `CP)+34` 50 / `CP)+31` 100 |
| 01233–01237 | 215,00 first command | 4 - 2 = 2 | `CP)+34` 50 / `CP)+31` 100 |

Worked check on the first: `WORKING HOURS IR99V9` scale 1 times `1.5` scale 1
gives 2; minus `20` aligned to 2 stays 2; times `MASTER RATE IR99V999` scale 3
gives 5. Target `WORKING GROSS IR9(5)V99` scale 2. `e = 3`, `d = 1000`,
`h = 500`. The listing prints exactly that.

**Not grounded.** No site downscales a value that is in the AC rather than the
MQ. Every attested `e > 0` follows a multiply. The shape for a downscale after
a pure additive chain is unexercised; the natural reading is that it cannot
arise, because a chain never raises the scale above its own operands' maximum,
and the target of a `SET` may legally have fewer fraction digits than the
chain. **That case is unattested. Label it and expect the diff to be silent on
it.**

**Citation.** D4.1(a) for the tail, D4.1(b) for `TRUNCATED`, M4-10.

---

## 8. Shape A6 — the non-binary operand fetch

**Trigger.** An arithmetic operand whose `fieldClass` is not
`internalDecimal`.

**Word sequence.** The MOVPAK operand-side convert of M4-9, which returns the
value in the AC, then a park (shape A2) or a direct chain use.

**Word count.** The convert's own words, which belong to M4-9, plus 1 for the
park.

**Site.** One only. Statement 221,00: `BONDORDER BONDENOMINATION` has the
external picture `899V99`, so it is `edited`, and it is the source of an `ADD`.

```
01354  LDI    CP)+59
01355  STI    SYS)132
01356  TSX    SYS)182,4
01357  TXI    SYS)268,1,1     <- edited to internal decimal
01360  TXI    SYS)269,1,5
01361  TXI    SYS)275,1,5
01362  STO    3.RS)1          <- this word is A2, the rest is M4-9
```

**Citation.** M4-9 for the MOVPAK families; [J 90.02.15] for the SYS)182
dispatch. The park word is this family's.

---

## 9. Shape A7 — `ADD a TO b`, the accumulate

**Trigger.** The `ADD` verb with an explicit target list. It is not shape A1
with an extra store: the target is both an operand and the destination, and it
is loaded first.

**Word sequence, per target, in written order.**

```
<A0 for the target, if located>
CLA    <target>
<prep of the source, shapes A0 / A2 / A4 / A6>
ADD    <source>
<A5 store into the target>
```

**Word count.**

```
W(A7) = sum over targets of ( 3 + A0(target) + prep(source) + tailExtra )
```

`tailExtra` is 4 when the source scale exceeds the target scale, 0 otherwise.
`prep(source)` is paid once per target as written, not hoisted — see the note
below.

**Sites.**

| LOC | Statement | Targets | Words |
|---|---|---|---|
| 01175–01201 | 211,00 `ADD WORKING FICA TO MASTER FICA` | 1, located | 2 + 3 = 5 |
| 01256–01260 | 215,00 `ADD WORKING WHT TO MASTER WHT` | 1, located, register live | 3 |
| 01263–01272 | 218,00 `ADD M.BND.DED TO M.BND.ACC, INTERNAL.TOTALS BONDEDUCTION` | 2 | 2 + 3 + 3 = 8 |
| 01362–01365 | 221,00 `ADD BONDORDER BONDENOMINATION TO INTERNAL.TOTALS BONDPURCHASES` | 1 | 1 park + 3 = 4 |

**Target order.** Statement 218,00 emits its two targets in **written** order:
`M.BND.ACC` first, at 01265–01267, then `INTERNAL.TOTALS BONDEDUCTION` at
01270–01272. That contradicts shape A8's one site. See A8.

**Not grounded.** No `ADD` in the sample has a source and a target at different
scales, and `TRUNCATED` is never written on an `ADD`. D4.1(d) rules that an
`ADD` result always reaches its store on the arithmetic path of D4.1(a), so
`tailExtra` follows shape A5-scaling; that is a decision, not an attestation.

---

## 10. Shape A8 — `ADD CORRESPONDING`

**Trigger.** The `ADD` verb with `CORRESPONDING`.

**Word sequence.** One shape-A7 body per matched pair, with no shared setup.
Pairs are taken in the **source** group's data-description order (D4.12,
M4-9 item 4).

**Word count.**

```
W(A8) = sum over targets of sum over matched pairs of ( 3 + A0 + tailExtra )
```

**Sites.**

| LOC | Statement | Pairs | Words |
|---|---|---|---|
| 00733–00757 | 208,00, target `INTERNAL.TOTALS` | 7 | 21 |
| 00760–00770 | 208,00, target `MASTER TOTALS` | 3 | 9 |
| 01565–01617 | 228,00, target `GRAND.TOTALS` | 9 | 27 |

Statement 208,00 totals 30 words; statement 228,00 totals 27. Both check by
octal subtraction: 00770 - 00733 = 35 octal = 29, so 30 words; 01617 - 01565 =
32 octal = 26, so 27 words.

The pair order in statement 208,00's first block is `GROSS, RETIREMENT,
INSURANCE, FICA, WHT, NETPAY, HOURS` — exactly `WORKING`'s declaration order
(statements 114,00 to 120,00), skipping `INDEX` and `POS`, which
`INTERNAL.TOTALS` does not have. In statement 228,00 the order is `HOURS,
GROSS, WHT, FICA, BONDEDUCTION, INSURANCE, RETIREMENT, NETPAY, BONDPURCHASES`
— exactly `INTERNAL.TOTALS`'s declaration order (124,00 to 132,00). Source
order, both times.

**Target order is reversed here, and that is the one contradiction in this
family.** Statement 208,00 is written `ADD CORRESPONDING WORKING TO MASTER
TOTALS, INTERNAL.TOTALS`. The listing emits `INTERNAL.TOTALS` first
(00733–00757, the `5)` and `4)` qualifiers) and `MASTER TOTALS` second
(00760–00770, the `1)…,1` qualifiers). Statement 218,00, a plain `ADD` with two
targets and the same mix of a located target and a working-storage target,
emits in written order. So the reversal is not "located last" and not a
register effect: the register was already live either way.

Two readings survive, and the sample has one site each:
1. `CORRESPONDING` expansion pushes target blocks and emits them last-in
   first-out, while plain `ADD` walks the list forwards.
2. Something about statement 208,00 that I cannot see reorders it.

**Label: pinned at the diff.** Implement reading 1, because it reproduces both
sites, and record it as unexplained. D4.8's "store order is left-to-right in
written order" is a decision about multi-result `SET`, not about
`CORRESPONDING` targets, so this is not a collision with it — but a reader
should be told the two rules point opposite ways.

**Not grounded.** Every matched pair in both statements has equal scale, so no
`ADD CORRESPONDING` pair in the program exercises the store tail. Checked pair
by pair: `WORKING HOURS IR99V9` to `INTERNAL.TOTALS HOURS IR9999V9`, both
scale 1; every other pair is scale 2 to scale 2.

---

## 11. Shape A10 — `TR( )`, the truth function

**Trigger.** A `TR(condition)` node in an expression. It yields the integer 1 or
0, at scale 0, in the AC.

**Word sequence.** The frame is eight words. The condition's own operand
preparation and skip vector sit inside it.

```
RIR    777777              # 1  clear every sense indicator
<operand prep for the compare, shapes A0 / A4>
CAS    <the other operand> # 1  (LAS for an alphameric or logical compare)
<skip vector, M4-11>       #    one TRA per outcome, the true outcome elided
SIR    000001              # 1  the true outcome sets indicator 1
PXA    0,0                 # 1  AC := 0
RFT    000001              # 1  skip the next word if indicator 1 is off
CLA    CP)+1               # 1  AC := 1
```

The eight fixed words are `RIR`, `CAS`, two vector slots, `SIR`, `PXA`, `RFT`,
`CLA`. The vector slot count is M4-11's, so the fixed count is exact only for a
two-slot vector.

**Word count.**

```
W(A10) = 1                 # RIR
       + prep              # shape A4 or A0 over the compare operands
       + 1                 # CAS or LAS
       + v                 # skip-vector slots, M4-11
       + 1                 # SIR
       + 3                 # PXA, RFT, CLA CP)+1
```

**The one site, statement 215,00, LOC 01240–01252, 11 words.**
Source: `SET WORKING WHT = WORKING WHT * TR(WORKING WHT GT 0)`.

```
01240  RIR    777777
01241  LDQ    CP)+0        <- shape A4: the literal 0 ...
01242  MPY    CP)+31       <- ... upscaled by 100 to WHT's scale 2 ...
01243  XCA                 <- ... and delivered to the AC
01244  CAS    4)WHT
01245  TRA    *+3          <- AC greater: 0 > WHT, so the test is false
01246  TRA    *+2          <- AC equal: 0 = WHT, so the test is false
01247  SIR    000001       <- AC less: 0 < WHT, so WHT GT 0 is true
01250  PXA    0,0
01251  RFT    000001
01252  CLA    CP)+1
```

01252 - 01240 = 12 octal = 10, so 11 words. The formula gives
1 + 3 + 1 + 2 + 1 + 3 = 11.

Two readings a generator must get right. First, the compare is mirrored, for
shape A4's reason: the literal 0 needed a scale multiply, so it ended in the AC
and became the `CAS` accumulator operand, which flips the sense of the three
outcomes. Second, the true outcome's slot is elided because `SIR` is the word
immediately after the vector — M4-11's elision rule, applied to the interior
`TRA *+2` as well, which prints in the relative form.

The product that consumes the truth value follows and is ordinary shape A3
plus shape A5-plain: `01253 XCA / 01254 MPY 4)WHT / 01255 STQ 4)WHT`. Scale
2 + 0 = 2, target scale 2, so `e = 0` and there is no tail.

**Citation.** M4-11's `TR( )` bullet, which quotes this site. **One site only.
Every generalization below the frame is pinned at the diff:** the `LAS`
alternative, a `TR` whose condition needs no scale multiply (the vector would
run in the normal sense and the true outcome would then be the greater arm, so
the elision would move), a `TR` with `AND` / `OR` inside it, and a `TR` used
anywhere other than as a multiplicand.

---

## 12. Adjacent shape worth one line — the eager positional-indicator update

M4-10 puts the subscript-store update in this family. Its only general site,
LOC 01421–01432 at statement 225,00, is reached through a `MOVE`, not a `SET`,
so the store tail and the update are independent: whatever stores a subscript
variable emits the update.

```
LDQ    <subscript variable>
MPY    CP)+stride
XCA
ADD    <the array base word>
STO    PI)n
```

Five words per affected positional indicator; two indicators are updated there,
`PI)3` and `PI)2`, ten words. The constant-increment form of [J 90.02.05],
`CLA CP)+1 / ADD PI)n / STO PI)n`, is attested at LOC 00714–00716 inside
statement 206,00's `DO ... FOR`. Both belong to M4-13's and M3-20's records as
much as to this one; listed here only so a reader of this family does not think
a store is finished at the `STQ`.

---

## 13. Everything in this family that is not grounded

Ordered by how much a wrong guess would cost.

1. **The per-section RS maximum (section 4).** [J 90.02.03] states the sum rule
   and no more. Sections 0, 1 and 2 reserve 3, 2 and 3 cells while referencing
   2, 1 and 1. No rule I tested fits all three. Pinned at the diff.
2. **`ADD CORRESPONDING` target order (section 10).** One site, and it
   disagrees with the one plain-`ADD` site. Pinned at the diff.
3. **The RS cell number (section 3).** "Count of chain operands to the right in
   source order" fits four sites, but only statement 203,00 has two cells live,
   so one site carries the whole rule. Pinned at the diff.
4. **`RS)1+0` against `RS)0` and `3.RS)1` (section 3).** A printed form with no
   rule behind it, scan-verified. Pinned at the diff, one line.
5. **Base-locator register liveness (section 2).** The invalidation set is read
   off seven reload sites and three reuse sites. Pinned at the diff, and it is
   M4-9's to own.
6. **`TRUNCATED` (section 7).** D4.1(b) is a design decision. Never written in
   the sample.
7. **A store tail on an `ADD` or an `ADD CORRESPONDING` pair (sections 9, 10).**
   Every attested pair has equal scale. The shape follows D4.1(d) by decision.
8. **A downscale of a value that is in the AC (section 7).** Unexercised. Every
   attested tail follows a multiply.
9. **`TR( )` beyond its one site (section 11).** The eight-word frame is solid;
   the vector sense, the `LAS` path and every non-multiplicand use are not.
10. **Division, exponentiation, double precision and mode promotion.** No site
    in the sample. M4-10 already labels these reconstructions; this family adds
    nothing to them.
11. **`ON OVERFLOW`.** No site, no manual shape. M4-10 labels it "ours,
    unattested" and that label stands.

---

## 14. The constant pool words this family reads

Verified against the printed pool at LOC 01674 to 01771. Octal to decimal:

| Word | LOC | Octal | Decimal | Read as |
|---|---|---|---|---|
| `CP)+0` | 01674 | 000000000000 | 0 | the literal ZERO, scale 0 |
| `CP)+1` | 01675 | 000000000001 | 1 | the `TR` true value; the `DO` increment |
| `CP)+5` | 01701 | 000000000620 | 400 | `40.0` at scale 1 |
| `CP)+6` | 01702 | 000000000017 | 15 | `1.5` at scale 1 |
| `CP)+7` | 01703 | 000000000024 | 20 | `20` at scale 0 |
| `CP)+9` | 01705 | 000000000003 | 3 | `.03` at scale 2 |
| `CP)+10` | 01706 | 000000034100 | 14400 | `144.00` at scale 2 |
| `CP)+11` | 01707 | 000000000022 | 18 | `0.18` at scale 2 |
| `CP)+12` | 01710 | 000000000015 | 13 | `13` at scale 0 |
| `CP)+31` | 01733 | 000000000144 | 100 | `10^2`, as both multiplier and divisor |
| `CP)+32` | 01734 | 000000000764 | 500 | half of 1000 |
| `CP)+33` | 01735 | 000000001750 | 1000 | `10^3` divisor |
| `CP)+34` | 01736 | 000000000062 | 50 | half of 100 |

A literal enters the pool as its keyed digits scaled by `10^S(lit)`, never
pre-multiplied by an alignment factor. The alignment factor is a separate pool
word and a run-time `MPY`. That is the single strongest structural fact in this
family, and every site obeys it.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02.03]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.05]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.15]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
