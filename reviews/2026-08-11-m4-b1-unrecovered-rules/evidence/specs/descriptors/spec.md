# Descriptor setup and MOVPAK dispatch

The specification of one code-generation family: the words that fill the move
source cell `SYS)132` and the move target cell `SYS)133`, and the words that
enter MOVPAK through `SYS)179`, `SYS)180`, `SYS)181` or `SYS)182`.

Scope note. The words after the dispatch — the specific-move subroutine call
(`SYS)183`, `SYS)239`, `SYS)267`, and their step lists) — belong to the
alphameric, numeric and figurative families. This document sizes them at zero
and only names them where the choice of dispatch entry depends on them.

Every LOC in this document is octal, as the listing prints it.

---

## 1. The three questions this family answers

For one move of a source operand S to a target operand T, a generator must
settle:

1. **Which cells to set.** Does the move need `SYS)133`, `SYS)132`, both, or
   neither?
2. **How to set each cell.** One of four in-line forms, costing 2, 3, 6 or 2
   words.
3. **Which dispatch entry to call.** One of four, costing 1 or 2 words.

Answer 1 first, then 2, then 3. The word count is the sum.

---

## 2. Total word count

```
familyWords(S, T) =
    2                                     when sourceIsRegister(S)
    setup(T) + setup(S) + 1               otherwise
```

where

```
setup(operand) =
    0    when the mover does not read that operand's cell (§3)
    2    Case 1  — fixed-location operand
    3    Case 2  — operand in a record located by a simple base locator
    6    Case 3  — operand in a record located by a complex base locator
    2    Case P  — operand located by a positional indicator
```

The `2` on the first branch is the `SYS)180` dispatch: one `TSX` word plus one
in-line target address word. No cell is set in line at all on that branch.

Verified against all 51 dispatch sites in the sample; §7 lists every one. The
family's total cost in the 90.05 procedure text is 155 words: 79 of in-line
setup and 76 of dispatch, inside a procedure text of 796 words.

---

## 3. Which cells the move needs

A cell is set in line if, and only if, the specific-move subroutine that
follows the dispatch reads it. Three groups:

| Group | The mover reads | Cells set in line |
|---|---|---|
| Memory to memory | both | `SYS)133` then `SYS)132` |
| Memory to register | source only | `SYS)132` |
| Register to memory | target only | none — the target rides in the `SYS)180` calling sequence |

The group follows from the specific-move family, which the numeric and
alphameric families choose:

- **Source is a machine register** — `SYS)186`, `SYS)187`, `SYS)188`,
  `SYS)246`, `SYS)267`. Only `SYS)267` occurs in the sample, 25 times.
  [J 90.02.30] for `SYS)267`; [J 90.02.18] for 186 to 188.
- **Target is a machine register** — `SYS)184`, `SYS)247`, `SYS)268`, and the
  scientific and floating families from `SYS)248` on. `SYS)184` (3 sites) and
  `SYS)268` (1 site) occur. [J 90.02.16], [J 90.02.30].
- **Neither** — everything else: `SYS)185`, `SYS)190`, `SYS)239`, `SYS)240`,
  `SYS)243`, `SYS)244`, `SYS)245` in the sample.

A **figurative constant or in-line literal source** sets no source cell. The
value travels in the specific-move word itself (`SYS)243` blanks count,
`SYS)244` zeros count) or in an in-line `OCT` word (`SYS)245`). 13 of the 26
`SYS)182` sites are of this kind. Grounded on [J 90.02.25] and [J 90.02.26],
which describe 243, 244 and 245 as moving blanks, zeros or characters *to* a
field, naming no source.

Counting closure over the sample, as a check on the rule: 26 `SYS)182`
dispatches; `SYS)133` set in line 22 times, `SYS)132` 13 times; 9 sites set
both, 13 target only, 4 source only. 22 + 13 − 26 = 9.

---

## 4. The four in-line setup shapes

### Shape D1 — Case 1, fixed-location operand

**Trigger.** The operand's containing record has `RecordInfo.located == false`,
or the operand sits in a `*DATA` working-storage area with no record at all.
These are the items the assembler can address directly, so their word and byte
are known at compile time.

**Words.** Two.

```
LDI    CP)+nn
STI    SYS)133          the target cell
```
or
```
LDI    CP)+nn
STI    SYS)132          the source cell
```

`CP)+nn` holds one word, `PZE LOC,,BYTE`, where `LOC` is the item's storage
word — `ItemSemantics.word` relative to its area's head, written as the
qualified symbol the listing prints — and `BYTE` is `ItemSemantics.byte`.

**Citation.** [J 90.02.11] Case 1, verbatim. The pool cell's form is
[J 90.02.10] under `SYS)132`.

**Attested pool cells.** `CP)+40 = PZE INTERNAL.TOTALS,,0`,
`CP)+53 = PZE HRS,,5`, `CP)+60 = PZE INS.PREM,,3`, `CP)+61 = PZE RET.PREM,,0`,
and eleven more at LOC 01744 to 01771.

### Shape D2 — Case 2, simple base locator

**Trigger.** The operand's containing record has `RecordInfo.located == true`
and `RecordInfo.variable == false`, and no `QUANTITY IN` array precedes the
operand inside the record. The record's first word address is not known until
run time, so the descriptor is built from the base locator.

**Words.** Three.

```
CAL    BL)n            n the base locator of the operand's record
ACL    CP)+nn
SLW    SYS)133          or SYS)132
```

`CP)+nn` holds `PZE WORD-DISPLACEMENT,,BYTE`: the operand's word displacement
from the head of the located record (`ItemSemantics.word` relative to the
record) and `ItemSemantics.byte`. The listing writes the displacement as the
qualified item symbol, because a symbol inside a located record assembles to
its displacement — `CP)+43 = PZE 1)DAT,,0`, `CP)+56 = PZE 1)NAME,,0`.

**Citation.** [J 90.02.11] Case 2, verbatim, including the constant's form.
The symbol-equals-displacement convention is [J 90.02.05].

**Note on the guard.** `CAL BL)n` reads the locator into the accumulator and
carries **no** `TXL SYS)294` guard. The guard rides only on `LAC BL)n,i`, the
index-register load. Confirmed at all nine `CAL BL)n` sites — LOC 00265, 00312,
00342, 00361, 00571, 00601, 01124, 01133, 01347; consistent with M4-9's
statement of the same rule.

### Shape D3 — Case 3, complex base locator

**Trigger.** As D2, but the operand follows a variable-length array inside the
record, so the base locator's `BYTE` is not always 0 —
`ItemSemantics.variableLength` on a preceding entry, or
`RecordInfo.variable == true`.

**Words.** Six.

```
CAL    BL)n
ACL    CP)+nn1          displacement constant, PZE DISPLACEMENT,,BYTE
PDX    0,4
TXL    *2,4,5
ACL    CP)+nn2          OCT 777772000000
SLW    SYS)133          or SYS)132
```

**Citation.** [J 90.02.11] Case 3, verbatim.

**Unexercised.** The 90.05 sample contains no `PDX` and no `TXL *2` anywhere.
Every count and every operand form for this shape comes from the manual alone;
none is checked against the answer key.

### Shape DP — positional indicator

**Trigger.** The operand is a subscripted reference whose subscript resolves to
a positional indicator — the operand appears in `SemanticResult.positionalIndicators`.

**Words.** Two.

```
LDI    PI)n
STI    SYS)132          or SYS)133
```

A positional indicator is itself a pointer word of the form `PZE LOC,,BYTE`
([J 90.02.05] under `PI`), so it is copied straight into the cell with no
constant-pool cell and no arithmetic.

**Citation and honesty.** **Pinned at the diff.** [J 90.02.11] names three
in-line cases and this is not one of them. Its nearest relative in the manual
is the `MON PI)NN,,0` calling-sequence form of [J 90.02.15] under `SYS)179`,
which is a different mechanism (the subroutine reads the indicator; here the
compiled code copies it). The shape is read off four sites, LOC 01435, 01445,
01454 and 01464, all in statement 225,00. M4-9 does not describe it; M4-9's
sentence "a working-storage field's descriptor is an `LDI CP)+nn / STI
SYS)132|133` pair" needs this fourth form added beside it.

---

## 5. The four dispatch entries

| Entry | Words | Calling sequence | Resume |
|---|---|---|---|
| `SYS)179` | 3 | `TSX SYS)179,4` + source address word + target address word | 3,4 |
| `SYS)180` | 2 | `TSX SYS)180,4` + target address word | 2,4 |
| `SYS)181` | 2 | `TSX SYS)181,4` + source address word | 2,4 |
| `SYS)182` | 1 | `TSX SYS)182,4` | 1,4 |

The resume offset is the address-word count plus one and costs no word of its
own: MOVPAK computes it, the compiler only picks the entry.
[J 90.02.14] and [J 90.02.15].

An address word takes one of three forms ([J 90.02.14], [J 90.02.15]):

```
PZE  LOC,,BYTE            Case 1, working storage
MZE  BL)nn,,CP)+nn        Case 2, base locator
MON  PI)nn,,0             Case 3, positional indicator
```

### The selection rule

```
entry = SYS)180   when sourceIsRegister(S)
        SYS)182   otherwise
```

`SYS)179` and `SYS)181` are **never generated**. That is the whole rule, and it
is exercised 51 times without a counter-example.

**Pinned at the diff, with the label meant literally.** The rule is not derived
and cannot be derived from [J 90.02.10] to [J 90.02.15]. The manual plainly
permits two cheaper choices that the 1962 compiler declines, 29 words' worth:

- **`SYS)179` at the nine two-cell sites.** [J 90.02.14] fits them exactly:
  both operands are in memory, and each has an address-word form — `PZE` for
  Case 1, `MZE BL)nn,,CP)+nn` for Case 2, `MON PI)nn,,0` for Case P. Three
  words each. The compiler emits 6 at the six Case-1-with-Case-2 sites and 5 at
  the other three. Declined saving: 24 words.
- **`SYS)181` at the four source-only sites.** [J 90.02.15] fits them exactly:
  the target is a machine register. Two words each. The compiler emits 4 at
  LOC 00571 and 3 at the other three. Declined saving: 5 words.

**A gap in the manual, not a declined saving.** The 13 target-only sites have
no source at all, so none of the four entry descriptions covers them:
`SYS)180` requires the source in `SYS)132` or in a register, and `SYS)182`
requires both cells preset. Whether `TSX SYS)180,4 / PZE target,,byte` would
have worked there is a hypothesis about MOVPAK's internals, not a manual
permission, and no word count is claimed for it.

**A motive, offered as motive and not as ground.** `SYS)180` must exist because
the D2 and D3 setups use `CAL`/`ACL`/`SLW`, which destroy an accumulator-held
source. The compiler appears to answer that hazard with a blanket rule keyed on
"source in a register" rather than on the setup shape. This explains why the
entry exists. It does not explain the 29 declined words above, and a generator
should implement the rule, not the motive.

### The `SYS)180` target form

All 25 sites use the Case 1 address word, `PZE LOC,,BYTE`. Every `SYS)180`
target in the sample is a fixed-location item. The `MZE` and `MON` calling-
sequence forms are **unexercised**: no site pairs a register source with a
located-record or subscripted target, so how such a move would be shaped is
open.

The in-line address word is not drawn from the constant pool even when a pool
cell already holds the identical word: LOC 00442 emits `PZE INS.PREM,,3` in
line while `CP)+60` holds the same word for the D1 setup at LOC 01433.

---

## 6. Ordering and reuse — the two rules that change counts

### R1. No reuse, ever

**Every dispatch re-emits, in line, every cell its mover reads, unconditionally.
There is no liveness analysis, no cross-statement reuse, and no reuse between
two moves of one statement.**

This is the rule that most affects the word count, and it is the one a modern
implementer will get wrong by optimising.

Three witnesses:

- LOC 01131 to 01135 re-emits `CAL BL)2 / ACL CP)+56 / SLW SYS)132`, word for
  word identical to LOC 01124 to 01126, seven words earlier in the same
  statement 208,00, with nothing between that touches `SYS)132`.
- LOC 01445 re-emits `LDI PI)2 / STI SYS)132`, set at LOC 01435 in the same
  statement 225,00.
- LOC 00547 re-emits `LDI CP)+40 / STI SYS)133` for the same target the
  statement-188 site at LOC 00167 already used.

**Grounding.** Pinned at the diff. The manual states no reuse rule either way.
The rule is safe as well as attested: `SYS)132` and `SYS)133` are single global
cells and MOVPAK may write them, so a compiler cannot assume they survive a
dispatch.

### R2. Target before source

When both cells are set, the `SYS)133` block precedes the `SYS)132` block.
All nine two-cell sites obey it.

**The untested corner, stated plainly.** All nine have a Case-1 target, two
words. Their sources split six Case 2, one Case 1, two Case P. So the target
block never costs more than the source block: six sites are 2 against 3, three
are 2 against 2. "Target first" and "cheaper block first" never diverge on this
data, and both fit it. No site in the sample pairs a **Case-2 or Case-3
target** with any source setup — the only two Case-2 targets, LOC 00342 and
00361, are figurative-source moves with no source block at all. The rule stated
here is target-first; a later site with a Case-2 target and a Case-1 source
would decide it.

### Consequence for the constant pool

In-line setup never dedupes; constant-pool cells do. One pool cell serves every
site that needs the same descriptor word, across statements and across
sections: `CP)+40` twice, `CP)+42` twice, `CP)+47` twice, `CP)+55` three times,
`CP)+56` three times, `CP)+59` twice.

Pool demand per shape: D1 one cell, D2 one cell, D3 two cells (a displacement
cell and the shared `OCT 777772000000` mask), DP none, `SYS)180` none.

---

## 7. Every site in the sample

`sw` is the in-line setup words, `dw` the dispatch words.

### Two-cell sites (target and source), sw = setup(T) + setup(S)

| LOC range | Statement | Target | Source | sw | dw |
|---|---|---|---|---|---|
| 00263–00270 | 193,00 | D1 `CP)+42` | D2 `BL)2`+`CP)+43` | 5 | 1 |
| 00310–00315 | 196,00 | D1 `CP)+42` | D2 `BL)3`+`CP)+44` | 5 | 1 |
| 00577–00604 | 202,00 | D1 `CP)+53` | D2 `BL)3`+`CP)+52` | 5 | 1 |
| 01122–01127 | 208,00 | D1 `CP)+47` | D2 `BL)2`+`CP)+56` | 5 | 1 |
| 01131–01136 | 208,00 | D1 `CP)+57` | D2 `BL)2`+`CP)+56` | 5 | 1 |
| 01345–01352 | 221,00 | D1 `CP)+58` | D2 `BL)2`+`CP)+56` | 5 | 1 |
| 01366–01372 | 221,00 | D1 `CP)+55` | D1 `CP)+59` | 4 | 1 |
| 01433–01437 | 225,00 | D1 `CP)+60` | DP `PI)2` | 4 | 1 |
| 01452–01456 | 225,00 | D1 `CP)+61` | DP `PI)3` | 4 | 1 |

### Target-only sites (figurative or literal source), sw = setup(T)

| LOC range | Statement | Target | sw | dw | Mover |
|---|---|---|---|---|---|
| 00167–00171 | 188,00 | D1 `CP)+40` | 2 | 1 | `SYS)244` |
| 00173–00175 | 188,00 | D1 `CP)+41` | 2 | 1 | `SYS)244` |
| 00342–00345 | 197,00 | D2 `BL)2`+`CP)+45` | 3 | 1 | `SYS)245` |
| 00361–00364 | 198,00 | D2 `BL)3`+`CP)+46` | 3 | 1 | `SYS)245` |
| 00462–00464 | 199,00 | D1 `CP)+47` | 2 | 1 | `SYS)243` |
| 00466–00470 | 199,00 | D1 `CP)+48` | 2 | 1 | `SYS)243` |
| 00472–00474 | 199,00 | D1 `CP)+49` | 2 | 1 | `SYS)243` |
| 00476–00500 | 199,00 | D1 `CP)+50` | 2 | 1 | `SYS)243` |
| 00502–00504 | 199,00 | D1 `CP)+51` | 2 | 1 | `SYS)243` |
| 00547–00551 | 201,00 | D1 `CP)+40` | 2 | 1 | `SYS)244` |
| 00672–00674 | 205,00 | D1 `CP)+54` | 2 | 1 | `SYS)243` |
| 00676–00700 | 205,00 | D1 `CP)+55` | 2 | 1 | `SYS)243` |
| 01313–01315 | 220,00 | D1 `CP)+55` | 2 | 1 | `SYS)243` |

### Source-only sites (register target), sw = setup(S)

| LOC range | Statement | Source | sw | dw | Mover |
|---|---|---|---|---|---|
| 00571–00574 | 202,00 | D2 `BL)3`+`CP)+52` | 3 | 1 | `SYS)184` |
| 01354–01356 | 221,00 | D1 `CP)+59` | 2 | 1 | `SYS)268` |
| 01445–01447 | 225,00 | DP `PI)2` | 2 | 1 | `SYS)184` |
| 01464–01466 | 225,00 | DP `PI)3` | 2 | 1 | `SYS)184` |

### `SYS)180` sites — register source, sw = 0, dw = 2

All 25 carry a Case 1 `PZE LOC,,BYTE` target word and are followed by
`SYS)267`.

| LOC of `TSX` | Statement | Target word |
|---|---|---|
| 00374 | 199,00 | `PZE 2)GROSS,,1` |
| 00402 | 199,00 | `PZE 2)WHT,,5` |
| 00410 | 199,00 | `PZE 2)FICA,,3` |
| 00416 | 199,00 | `PZE 2)BONDEDUCTION,,0` |
| 00426 | 199,00 | `PZE 1)NETPAY,,4` |
| 00434 | 199,00 | `PZE HRS,,5` |
| 00442 | 199,00 | `PZE INS.PREM,,3` |
| 00450 | 199,00 | `PZE RET.PREM,,0` |
| 00507 | 199,00 | `PZE 2)BONDENOMINATION,,1` |
| 01071 | 208,00 | `PZE 2)GROSS,,1` |
| 01077 | 208,00 | `PZE 2)FICA,,3` |
| 01105 | 208,00 | `PZE 2)WHT,,5` |
| 01115 | 208,00 | `PZE 1)NETPAY,,4` |
| 01144 | 208,00 | `PZE AMOUNT,,1` |
| 01274 | 219,00 | `PZE 2)BONDEDUCTION,,0` |
| 01325 | 221,00 | `PZE 3)BONDENOMINATION,,0` |
| 01475 | 228,00 | `PZE 2)HOURS,,5` |
| 01503 | 228,00 | `PZE 3)GROSS,,1` |
| 01511 | 228,00 | `PZE 3)WHT,,5` |
| 01517 | 228,00 | `PZE 3)FICA,,3` |
| 01525 | 228,00 | `PZE 3)BONDEDUCTION,,0` |
| 01533 | 228,00 | `PZE 2)INSURANCE,,3` |
| 01541 | 228,00 | `PZE 2)RETIREMENT,,0` |
| 01547 | 228,00 | `PZE 2)NETPAY,,3` |
| 01555 | 228,00 | `PZE 1)BONDPURCHASES,,1` |

One caveat outside this family: LOC 01327 prints `TRA SYS)267,0,0` where the
other 24 sites print `TXI SYS)267,1,n`. That word belongs to the numeric
family; M4-20 item (c) already records it as a scan measurement.

### Base locator identities in the sample

`BL)2` is the MASTER record, 15 words, set by `IOCTN* BL)2,,15` at LOC 00203.
`BL)3` is the DETAIL record, 3 words, `IOCTN* BL)3,,3` at LOC 00236. Both are
simple base locators, which is why Case 3 never appears.

---

## 8. What is not grounded

Six items, each labelled honestly.

1. **Shape DP, the `LDI PI)n / STI SYS)13x` form.** Pinned at the diff.
   [J 90.02.11] gives three cases and this is a fourth. Four sites.
2. **The dispatch selection rule.** Pinned at the diff. The manual allows
   `SYS)179` at the nine two-cell sites and `SYS)181` at the four source-only
   sites; the 1962 compiler uses neither and pays 29 extra words to avoid them.
   No derivation is available. The accumulator-clobber motive in §5 explains
   the entry's existence, not the compiler's choice. The 13 target-only sites
   fall outside all four entry descriptions and are a gap in the manual rather
   than evidence either way.
3. **R1, no reuse.** Pinned at the diff, and strongly attested — three
   independent witnesses, no counter-example. The manual says nothing.
4. **R2, target before source.** Pinned at the diff, and **partly** so: nine
   sites agree, but none of them puts a Case-2 or Case-3 target against a
   source setup, so the rival reading "cheaper shape first" survives the data.
5. **Shape D3, Case 3.** Manual only, unexercised. The whole six-word sequence,
   its operands and its trigger come from [J 90.02.11] with no answer-key
   check. The trigger's phrasing in `ItemSemantics` terms —
   `variableLength` on a preceding entry, or `RecordInfo.variable` — is a
   reading of [J 90.02.05]'s "items after a variable length array", not an
   attested mapping.
6. **The `MZE` and `MON` `SYS)180` target forms.** Manual only, unexercised.
   Every `SYS)180` in the sample has a Case 1 target, so a register-source move
   into a located-record or subscripted target has no attested shape.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02.05]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.10]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.11]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.14]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.15]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.16]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.18]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.25]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.26]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.30]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
