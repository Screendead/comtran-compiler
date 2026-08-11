# Figurative-constant moves — generated-code specification

Family: `MOVE`/`SET` whose source operand is BLANK(S), ZERO(S), HIGH.VALUE(S)
or LOW.VALUE(S). Routes through MOVPAK entry `SYS)182` and one of the three
fill subroutines `SYS)243`, `SYS)244`, `SYS)245`.

Grounding: [J 90.02.11] (the SYS)132/SYS)133 pointer cells and their three
in-line setter forms), [J 90.02.24]–[J 90.02.26] (SYS)182, SYS)243, SYS)244,
SYS)245), [J 02.04.02] (the figurative-constant target chart and the
HIGH/LOW.VALUE collating values), M4-9 case 1, D4.11, D4.6/D9.9, D0.6.

---

## 1. The unit, and the two independent axes

Every figurative-constant move compiles to one **unit per target**. A unit has
three parts, in this order:

1. a **target-descriptor prologue** that leaves `PZE LOC,,BYTE` in the target
   pointer cell `SYS)133`;
2. `TSX SYS)182,4` — the MOVPAK entry taken when the pointers are already set
   in line ([J 90.02.24]);
3. a **fill call**: one `TXI` naming the fill subroutine and carrying the
   character count, plus — for `SYS)245` only — one in-line `OCT` word.

The prologue length and the fill length vary **independently**:

| Axis | Chosen by | Grounded in |
|---|---|---|
| prologue: 2, 3 or 6 words | where the target field *lives* | [J 90.02.11] cases 1–3 |
| fill: 1 or 2 words | *which* figurative constant | [J 90.02.25]–[J 90.02.26] |

**Read this before the site list.** In the 1962 sample the only `SYS)245`
sites (statements 197, 198) are also the only located-record sites, so the
object listing alone cannot tell "HIGH.VALUE takes `CAL/ACL/SLW`" from
"a located target takes `CAL/ACL/SLW`". The manual breaks the confound:
[J 90.02.11] states the three setter forms as a property of the *data item's
storage*, for any move whatever, and [J 90.02.26] states the `OCT` word as a
property of the *subroutine*. The two axes are therefore independently
grounded, and an implementer must not couple them.

No `SYS)132` (source pointer) store appears at any site. A figurative constant
has no source field, so only the target pointer is set. `SYS)182`'s
documentation speaks of both pointers being preset; here the fill routine
supplies the source itself.

Trigger note: the family covers **`SET` as well as `MOVE`**. [J 02.04.02] c
says "Figurative constants may be used as source fields by both MOVE and SET",
and both `SYS)245` sites are `SET` statements.

---

## 2. Shape A — target-descriptor prologue

### A1. `descriptor-working-storage` (2 words)

**Trigger.** The target's space root is a program storage area — i.e. the
owning `RecordInfo.located` is false, or the target is not in a record at all
(a `WORKING`-style level-1 area). [J 90.02.11] case 1: "When the data item is
working storage".

```
LDI    CP)+<k>
STI    SYS)133
```

`CP)+<k>` is a constant-pool word `PZE <target word address>,,<target byte>`,
i.e. `PZE` of `ItemSemantics.word` and `ItemSemantics.byte` for the target.
The assembler resolves the address from the field's symbol, so the emitter
writes the symbol, not a number.

### A2. `descriptor-simple-base-locator` (3 words)

**Trigger.** The target's owning record has `RecordInfo.located == true`, and
the record's base locator is *simple* — [J 90.02.11] defines simple as "one
that always has byte+0", which holds when the record begins on a word boundary
in its buffer.

```
CAL    BL)<b>
ACL    CP)+<k>
SLW    SYS)133
```

`BL)<b>` is the base-locator cell bound to the target's located record.
`CP)+<k>` here is `PZE <word displacement within the record>,,<byte>` —
[J 90.02.11] case 2 says so verbatim: "PZE WORD-DISPLACEMENT,,BYTE". The `ACL`
adds the run-time buffer word address into the address field; the byte field
passes through unchanged.

### A3. `descriptor-complex-base-locator` (6 words) — **no sample site**

**Trigger.** Located record whose base locator may carry byte 1–5.

```
CAL    BL)<b>
ACL    CP)+<k1>          displacement constant
PDX    0,4
TXL    *2,4,5
ACL    CP)+<k2>          OCT 777772000000
SLW    SYS)133
```

Transcribed from [J 90.02.11] case 3, with `SYS)132` replaced by `SYS)133`
per that section's own instruction that SYS)133 "is set … by means of in-line
coding of the same form as described under SYS)132". Nothing in the sample
exercises it.

---

## 3. Shape B — fill call

### B1. `fill-blanks` — `SYS)243` (1 word)

**Trigger.** Source constant is BLANK/BLANKS, and the target's chart cell
stores blanks: alphameric, external decimal, edited field, scientific decimal
([J 02.04.02] chart, BLANK row), or a **group** (see §4).

```
TXI    SYS)243,1,<n>
```

### B2. `fill-zeros` — `SYS)244` (1 word)

**Trigger.** Source constant is ZERO/ZEROS and the target class is alphameric,
external decimal, internal decimal, floating point, or a group.

```
TXI    SYS)244,1,<n>
```

**Excluded, leaves this family:** ZEROS into an **edited** or **scientific
decimal** target. The chart's cell reads "0's Edited", not "0's" — the stored
image must carry the pictorial's punctuation, which a character fill cannot
produce. M4-9 routes those two cells through the numeric edited-store path
(`TSX SYS)180,4` / `TXI SYS)267,…`). No sample site.

### B3. `fill-characters` — `SYS)245` (2 words)

**Trigger.** Source constant is HIGH.VALUE(S) or LOW.VALUE(S), and the target
class is alphameric, external decimal, edited field, scientific decimal, or a
group. Internal decimal and floating point are **Illegal** in the chart, so
`SYS)245` never fires for them.

```
TXI    SYS)245,1,<n>
OCT    <six copies of the fill character's 6-bit BCD code>
```

[J 90.02.26]: "This MOVPAK subroutine moves characters to an alphabetic field.
The second word contains 6 characters of the type to be moved."

**Why only this route carries the extra word.** `SYS)243` and `SYS)244` name
their fill character in the subroutine number — the manual's own one-line
descriptions are "moves blanks to an alphabetic field" and "moves zeros to an
alphabetic field". `SYS)245` is the *general* fill and has no character of its
own, so the caller supplies one in line. This is a routine property, not a
statement property; nothing about HIGH.VALUE as such lengthens the unit.

**The fill word's value.** From [J 02.04.02] a and the D0.6 BCD table
(`lib/src/chars/char_code.dart`, glyph index = BCD code):

| Collating sequence | HIGH.VALUE | LOW.VALUE |
|---|---|---|
| native 709/7090 (default) | `(` = 0o74 → `OCT 747474747474` | `0` = 0o00 → `OCT 000000000000` |
| Commercial (`COLLATE COM`) | `9` = 0o11 → `OCT 111111111111` | blank = 0o60 → `OCT 606060606060` |

Only the first cell is attested (statements 197 and 198 both emit
`OCT 747474747474`). The other three are **derived from the collating
sequence** — [J 02.04.02] a fixes the glyph, the D0.6 table fixes its code —
and have no sample site. That is a stronger grade than pinned-at-the-diff.

---

## 4. `<n>` — the TXI decrement

**`<n>` is the target's `ItemSemantics.storageChars`: the characters of
storage the target occupies, not the digits its pictorial represents.**

For a leaf the two coincide, and five sites show it directly:

| Target | Pictorial | Characters | `<n>` |
|---|---|---|---|
| PAYRECORD NAME | `A(15)` | 15 | 15 |
| PAYRECORD EMPLOYEE | `AAAA` | 4 | 4 |
| PAYRECORD MONTH / DAY / YEAR | `AA` | 2 | 2 |
| PAYRECORD BONDEDUCTION | `8889.99` | 7 | 7 |
| PAYRECORD BONDENOMINATION | `88889.99` | 8 | 8 |

The decrement is written in **decimal**, unlike the LOC column. `A(15)`
emitting `,15` settles it: read as octal that would be 13 characters, one
short of the field. Every count below assumes decimal.

For a **group** the two diverge, and the divergence is the whole rule.
`MOVE ZEROS TO INTERNAL.TOTALS` emits `TXI SYS)244,1,54`. Summing the group's
nine pictorials gives **57**, not 54:

```
HOURS         IR9999V9    5
GROSS         IR9(5)V99   7
WHT           IR9(5)V99   7
FICA          IR9(4)V99   6
BONDEDUCTION  IR9(4)V99   6
INSURANCE     IR9(4)V99   6
RETIREMENT    IR9(4)V99   6
NETPAY        IR9(5)V99   7
BONDPURCHASES IR9(5)V99   7
                        ---
                         57
```

Every one of the nine is internal decimal, so each takes a whole word.
`test/fixtures/90.05-storage-section.tsv` line 89 records the area as
`00113 bss 9 INTERNAL.TOTALS` — nine words. 9 × 6 = **54**. GRAND.TOTALS is
the same nine-word shape (tsv line 90, `bss 9`) and also emits 54, though its
pictorials also sum to 57. The decrement counts storage extent, including
interior alignment; it does not count digits, and it is not the pictorial sum
rounded up (57 rounds to 60, which no site emits).

The two alphameric group targets confirm the same rule with no alignment gap:
MASTER EMPLOYEE.NUMBER and DETAIL EMPLOYEE.NUMBER each hold `AA` + `AAAA`,
storage extent 6, and each emits `,6`.

**Limits.** `<n>` is capped at 32766 (D4.6, D9.9); a longer target draws
msg 181 and generates no code for that target. A whole variable-length array
target is illegal ([J 02.04.02] c.i).

**Two edges with no ground.**
- *Interior alignment inside a group.* Every attested group is gap-free
  (nine word-aligned internals; two packed alphamerics). "Extent including
  interior alignment" is `storageChars`' own definition in
  `lib/src/data/data_map.dart`, not a fact any sample site proves. A group
  with a real gap would test it, and none exists.
- *Subscripted and repeated targets.* [J 02.04.02] c.i explicitly permits
  `MOVE BLANKS TO FIELD(3)`. No sample site does it. Whether `<n>` is one
  element's `storageChars` (near-certain, since it is one element being
  filled) and how the descriptor carries the subscript are **unattested**;
  `extentChars` versus `storageChars` for a `quantity > 1` target is likewise
  undecided by the diff.

---

## 5. Word count — the B1 sizing formula

```
words(unit) = D + 2 + F

D = 2   target in program storage                  ([J 90.02.11] case 1)
  = 3   target in a located record, simple locator ([J 90.02.11] case 2)
  = 6   target in a located record, complex locator([J 90.02.11] case 3)

F = 1   HIGH.VALUE or LOW.VALUE (SYS)245 in-line OCT)
  = 0   BLANK or ZERO
```

**The unit size is independent of `<n>`.** No part of the unit grows with the
target's length. A one-character blank fill and a 32766-character blank fill
are both four words. B1 can therefore size every unit from two booleans —
"is the target in a located record" and "is the constant a value constant" —
before any field length is known.

| D | F | words | status |
|---|---|---|---|
| 2 | 0 | **4** | attested, eleven units |
| 3 | 1 | **6** | attested, two units |
| 2 | 1 | 5 | forms grounded in [J 90.02.11] case 1 and [J 90.02.26]; **combination has no site** |
| 3 | 0 | 5 | forms grounded in [J 90.02.11] case 2 and [J 90.02.25]; **combination has no site** |
| 6 | 0 | 8 | [J 90.02.11] case 3; **no site, and case 3 itself has no site** |
| 6 | 1 | 9 | [J 90.02.11] case 3; **no site, and case 3 itself has no site** |

### Multi-target sizing

A `MOVE`/`SET` of a figurative constant to *t* targets emits *t* complete,
independent units, in **source order**, with **no sharing of any kind** —
each target gets its own descriptor prologue, its own `TSX SYS)182,4` and its
own fill call, even when several targets sit in the same record.

```
words(statement) = Σ over targets of (D_i + 2 + F_i)
```

**Both halves of that rule — source order, and no sharing — are
pinned-at-the-diff.** No section of [J 90.02] says a multi-target move expands
to one unit per target, orders the units by source position, or declines to
reuse a prologue between two targets of one record. Statement 199 shows the
1962 compiler did all three: five targets all inside PAYRECORD, all `D = 2`,
five separate `LDI`/`STI` pairs against five separate pool constants,
5 × 4 = 20 words, in the order NAME, EMPLOYEE, MONTH, DAY, YEAR. Nothing
derives it. Statement 188's two targets are two different areas, 2 × 4 = 8
words, also in source order.

---

## 6. The constant-pool operand

Documented:

- Case 1 word: `PZE <absolute LOC>,,<byte>` — [J 90.02.11], "CP)+NN will
  contain the location and byte of the data item".
- Case 2 word: `PZE <word displacement>,,<byte>` — [J 90.02.11] case 2,
  verbatim.

**Pinned-at-the-diff, no manual statement behind either:**

- The pool is **deduplicated by target descriptor across every move family**,
  not just this one. `CP)+40` (`PZE INTERNAL.TOTALS,,0`) serves statements 188
  and 201. `CP)+55` (`PZE 2)BONDENOMINATION,,1`) serves statements 205 and 220
  *and* the non-figurative move at LOC 01366 (statement 221). `CP)+47`
  (`PZE 3)NAME,,2`) serves statement 199 and the non-figurative move at
  LOC 01122 (statement 208). [J 90.02]'s constant-pool section says only that
  constants "are pooled together in a block of storage immediately following
  the Positional Indicators". It states no dedup key.
- Entries are allocated in **first-use order** through the procedure text.
  Read off the pool's own layout against the statement numbers; no section
  states an allocation order.

Byte fields verified against the PAYRECORD layout, character by character:
NAME starts at character 8 → word 1 byte 2 → `PZE 3)NAME,,2`; EMPLOYEE at
character 3 → `,,3`; DAY at 27 → word 4 byte 3 → `,,3`; BONDEDUCTION at 72 →
word 12 byte 0 → `,,0`; BONDENOMINATION at 109 → word 18 byte 1 → `,,1`. All
five match the pool.

---

## 7. Every site in the sample

56 words total, in thirteen units. LOC values are octal.

| Statement | Source clause | Target | Shape | LOC | Words |
|---|---|---|---|---|---|
| 188,00 | `MOVE ZEROS TO INTERNAL.TOTALS, GRAND.TOTALS` | INTERNAL.TOTALS (group, 9 words) | A1 + B2, `CP)+40`, n=54 | 00167–00172 | 4 |
| 188,00 | same | GRAND.TOTALS (group, 9 words) | A1 + B2, `CP)+41`, n=54 | 00173–00176 | 4 |
| 197,00 | `SET M.EMP.NO = HIGH.VALUE` | MASTER EMPLOYEE.NUMBER (group, located) | A2 `BL)2` + B3, `CP)+45`, n=6, `OCT 747474747474` | 00342–00347 | 6 |
| 198,00 | `SET D.EMP.NO = HIGH.VALUE` | DETAIL EMPLOYEE.NUMBER (group, located) | A2 `BL)3` + B3, `CP)+46`, n=6, `OCT 747474747474` | 00361–00366 | 6 |
| 199,00 | `MOVE BLANKS TO PAYRECORD NAME, …` | PAYRECORD NAME `A(15)` | A1 + B1, `CP)+47`, n=15 | 00462–00465 | 4 |
| 199,00 | same | PAYRECORD EMPLOYEE `AAAA` | A1 + B1, `CP)+48`, n=4 | 00466–00471 | 4 |
| 199,00 | same | PAYRECORD MONTH `AA` | A1 + B1, `CP)+49`, n=2 | 00472–00475 | 4 |
| 199,00 | same | PAYRECORD DAY `AA` | A1 + B1, `CP)+50`, n=2 | 00476–00501 | 4 |
| 199,00 | same | PAYRECORD YEAR `AA` | A1 + B1, `CP)+51`, n=2 | 00502–00505 | 4 |
| 201,00 | `MOVE ZEROS TO INTERNAL.TOTALS` | INTERNAL.TOTALS | A1 + B2, `CP)+40`, n=54 | 00547–00552 | 4 |
| 205,00 | `MOVE BLANKS TO PAYRECORD BONDEDUCTION, PAYRECORD BONDENOMINATION` | PAYRECORD BONDEDUCTION `8889.99` (edited) | A1 + B1, `CP)+54`, n=7 | 00672–00675 | 4 |
| 205,00 | same | PAYRECORD BONDENOMINATION `88889.99` (edited) | A1 + B1, `CP)+55`, n=8 | 00676–00701 | 4 |
| 220,00 | `MOVE BLANKS TO PAYRECORD BONDENOMINATION` | PAYRECORD BONDENOMINATION | A1 + B1, `CP)+55`, n=8 | 01313–01316 | 4 |

Eleven four-word units plus two six-word units: 11 × 4 + 2 × 6 = 56, and the
listing carries exactly thirteen `TXI SYS)24x` lines.

Base-locator bindings used above are read off the sample's indexed accesses:
`LAC BL)2,1 … CAL 1)DEPARTMENT,1` binds `BL)2` to MASTER; `LAC BL)3,1 …
CAL 2)DEPARTMENT,1` binds `BL)3` to DETAIL.

---

## 8. What is not grounded

Ranked, strongest doubt last.

1. **Class coverage of the chart.** The sample exercises two of the chart's
   twenty-four cells — BLANK→alphameric and BLANK→edited — plus two
   group-target attestations that the chart does not cover at all
   (ZEROS→group-of-internal, HIGH.VALUE→group-of-alphameric). Every other
   cell's *routine choice* is read off [J 02.04.02]'s chart text and D4.11,
   not off the diff. The chart says what value is stored; it does not say
   which subroutine stores it.

2. **BLANK into internal decimal or floating point.** The chart's cell says
   "0's", not blanks. **Design inference (label it as such):** emit `SYS)244`
   with the target's `storageChars`. It is correct arithmetic, because BCD `0`
   is 0o00, so a character fill of 0o00 leaves binary zero in every word — the
   right value for both an internal-decimal integer and a 7090 floating-point
   zero. This is an inference from the code table, not a documented rule, and
   no site exercises it.

3. **BLANK into external decimal.** D4.11 already routes it through `SYS)243`
   with the target's full character count and marks that a design decision
   under D0.4. Unchanged here; no site.

4. **The complex base locator (A3).** Transcribed from [J 90.02.11] case 3
   with the pointer cell swapped from `SYS)132` to `SYS)133` on that section's
   own authority. The swap is documented; the sequence has no site in any
   family, figurative or otherwise.

5. **Subscripted and repeated targets.** See §4. Legal per [J 02.04.02] c.i,
   entirely unexercised, and the descriptor form for a run-time subscript is
   unknown from this listing.

6. **LOW.VALUE anywhere, and HIGH.VALUE outside a group of alphamerics.** The
   `OCT` fill values are derived from the collating sequence (§3, B3), which
   is a real derivation. That HIGH.VALUE and LOW.VALUE share one code path —
   the same `SYS)245`, differing only in the `OCT` word — rests on
   [J 90.02.26] describing `SYS)245` as the general character fill, plus
   [J 02.04.02]'s chart treating the two rows identically. No LOW.VALUE site
   exists.

### The pinned-at-the-diff rules, gathered

Four rules in this specification have the answer key as their **only**
authority. No manual sentence supports them; they are what the 1962 compiler
was observed to do.

1. One unit per target of a multi-target move (§5).
2. Units emitted in source order (§5).
3. No descriptor, `TSX` or pool-constant sharing between two targets of one
   statement, even inside one record (§5).
4. Constant-pool dedup by target descriptor across all move families, and
   first-use allocation order (§6).

Everything else in §§1–7 has a manual section behind it, with the diff as
confirmation. In particular the rule that came *from* the diff first — that
`<n>` is storage extent, not the pictorial digit sum — is confirmed
independently by the storage map's `BSS 9`, so it is a derivation, not a pin.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 02.04.02]: ../../../../../comtran-manuals/J28-6169/02-compiler.md#1-figurative-constants
[J 90.02]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.11]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.24]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.25]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.26]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
