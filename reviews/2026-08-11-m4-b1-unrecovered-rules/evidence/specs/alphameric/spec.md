# In-line alphameric moves — generated-code specification

Family: the alphameric-to-alphameric moves the 1962 compiler emitted in line,
without a MOVPAK dispatch. Derived from the 90.05 object listing
(`test/fixtures/90.05-object-listing.target`), its DATA division
(`comtran-manuals/J28-6169/90.05-sample-program.md`), and the constant pool at
LOC 01674–01771.

---

## 0. The headline: word counts

Let, for one move of one elementary alphameric field to one elementary
alphameric field:

| Term | Meaning | `ItemSemantics` source |
|---|---|---|
| `L` | characters moved | `storageChars` (equal on both sides — see §1) |
| `sB` | source byte within its word, 0–5 | `source.byte` |
| `tB` | target byte within its word, 0–5 | `target.byte` |
| `D` | `tB - sB`, the byte displacement | computed |
| `G` | index-register loads the statement newly forces | `RecordInfo.located` + the allocator |

Then the emitted word count is:

| # | Shape | Trigger | Words |
|---|---|---|---|
| A1 | Whole-word move | `sB == 0 && tB == 0 && L % 6 == 0` | `2 * (L / 6)` |
| A2 | COM mask-insert | `tB + L <= 6 && D == 0` | `5` |
| A3 | Shifted mask-insert | `tB + L <= 6 && D != 0 && tB > 0 && tB + L < 6` | `6` |
| A4 | AC shift chain | `tB == 0 && L < 6 && D != 0 && sB + L == 6` | `5` |
| A5 | MQ shift chain | `tB > 0 && tB + L == 6 && D != 0` | `6` |
| A6 | Two-word chain | `sB + L <= 6 && 6 < tB + L <= 12` | `11` |
| A7 | Literal insert | source is an alphameric literal, `tB + L <= 6` | `5` |

**Plus `2 * G`.** Each index-register load takes the guard pair
`LAC BL)n,i` / `TXL SYS)294,i,0` — per load, never per reference (M4-9).

The triggers A2–A5 partition every single-word case with no overlap and no
gap. A2 wins over A4 and A5 whenever `D == 0`.

**The task's question answered directly.** A move costs

- **5** words when it is A2, A7, or A4 and forces no new register load;
- **8** words when it is A3 (6) plus one guard pair (2) — statements 189 and 201;
- **13** words when it is A6 (11) plus one guard pair (2) — statement 208's
  first block.

Shift distances, all in bits, six bits per character:

- `ARS` / `ALS` in A3: `6 * |D|`. `ARS` when `D > 0`, `ALS` when `D < 0`.
- `LGR` / `LGL` in A4 and A5: `6 * (6 - L)`.
- `RQL` in A5: `6 * sB`.
- A6's six distances: see §7.

---

## 1. The in-line / MOVPAK boundary

**Trigger for this family at all.** All four conditions:

1. Both operands resolve to the alphameric field class (`fieldClass`); no
   numeric, edited, or figurative-constant operand.
2. `source.storageChars == target.storageChars`. Unequal lengths need blank
   fill or truncation, which is MOVPAK's job.
3. The source lies wholly inside one word: `source.byte + L <= 6`.
4. The target spans at most two words: `target.byte + L <= 12`.

Otherwise emit the MOVPAK dispatch (not this family).

**Grade: pinned at the diff.** [J 90.02] documents the MOVPAK calling
sequences and says nothing about in-line move shapes. The rule is a
generalisation of the answer key. It refines M4-9's own pinned sentence
("in-line when both fields are word-addressable and the move is word-whole or
single-word masked"), which is too narrow: it does not admit A6, and A6 is
attested three times.

Zero counterexamples in the sample. The MOVPAK-side witnesses that fix the
boundary:

| Source → target | Why MOVPAK | Site |
|---|---|---|
| MASTER `DAT` (23 ch) → ERROROUT `INFO` A(23) | 23 chars, 5 words | LOC 00263–00272, stmt 193 |
| DETAIL (15 ch) → ERROROUT `INFO` A(23) | unequal lengths | LOC 00310–00317, stmt 196 |
| MASTER `NAME` A(15) → PAYRECORD `NAME` A(15) | target spans 3 words (word 1 byte 2 through word 3 byte 4) | stmt 208, via `CP)+47 PZE 3)NAME,,2` |
| MASTER `NAME` A(15) → CHECK `NAME` A(18) | unequal lengths | stmt 208, via `CP)+57 PZE 2)NAME,,5` |

---

## 2. A2 / A7 — the COM mask-insert (5 words)

The literal form and the aligned-field form are **one shape**. The compiler
materialises an alphameric literal as a constant-pool word with the literal
characters already sitting at the target's byte offset and BCD blanks (`60`)
elsewhere; that makes `D == 0` by construction, so A7 is A2 with a `CP)` cell
for a source.

```
CAL   CP)clear(tB, L)        ; ones everywhere, zeros in bytes tB .. tB+L-1
ANS   target[,i]             ; target &= clear   — punches the hole
COM                          ; AC = ~clear       — the select mask
ANA   source[,i]             ; AC &= source word — the field, in place
ORS   target[,i]             ; target |= AC
```

Word count **5**. One constant-pool word (`clear`), plus one more for a
literal source. `COM` earns its place: it manufactures the select mask from
the clear mask, so the shape needs no second constant.

Constants confirm the mask geometry exactly:

| Cell | Octal | Bytes zeroed | Field it clears |
|---|---|---|---|
| `CP)+21` | `007777777777` | 0 | ERROROUT `ERRORTYPE`, byte 0, L=1 |
| `CP)+25` | `000077777777` | 0–1 | any 2-char field at byte 0 |
| `CP)+16` | `777777000077` | 3–4 | any 2-char field at byte 3 |
| `CP)+35` | `770000777777` | 1–2 | any 2-char field at byte 1 |

Literal words: `CP)+2 = 446060606060` (`M` at byte 0), `CP)+3 =
246060606060` (`D`), `CP)+4 = 276360606060` (`GT` at bytes 0–1).

**Sites.**

| LOC | Stmt | Move | Form |
|---|---|---|---|
| 00256–00262 | 193 | `'M'` → ERROROUT `ERRORTYPE` (w0 b0 L1) | A7 |
| 00320–00324 | 196 | `'D'` → ERROROUT `ERRORTYPE` | A7 |
| 00455–00461 | 199 | `'GT'` → PAYRECORD `DEPARTMENT` (w0 b0 L2) | A7 |
| 01006–01012 | 208 | DETAIL `MONTH` (w1 b0) → PAYRECORD `MONTH` (w4 b0) | A2 |
| 01026–01032 | 208 | DETAIL `DEPARTMENT` (w0 b0) → PAYRECORD `DEPARTMENT` (w0 b0) | A2 |

**Grade.** Word sequence and count: attested, 5 sites. Mask values: derived
and checked bit for bit. The claim that a literal at `tB > 0` is
pre-positioned at `tB` is **unattested** — both literal targets sit at byte 0.
It is the only reading consistent with the shape, but say so.

**Citation.** M4-9 clause 2 names this shape for the literal case ("the
mask-insert five-word shape `CAL mask / ANS target / COM / ANA literal / ORS
target`", statements 193 and 196). The field-source case (`ANA source[,i]`
in place of `ANA literal`) is **this specification's addition** — M4-9 does
not have it, and it is attested twice.

---

## 3. A3 — the shifted mask-insert (6 words)

```
CAL   CP)clear(tB, L)
ANS   target[,i]
[guard pair, if this reference forces a register load]
CAL   source[,i]
ARS   6 * D                  ; D > 0
ALS   6 * (-D)               ; D < 0
ANA   CP)select(tB, L)       ; zeros everywhere, ones in bytes tB .. tB+L-1
ORS   target[,i]
```

Word count **6**, plus `2 * G`. Two constant-pool words. `COM` cannot serve
here because the accumulator must hold the shifted source, not the mask, so
the select mask is a separate cell — `CP)+17 = 000000777700` pairs with
`CP)+16`, `CP)+36 = 007777000000` pairs with `CP)+35`.

**Sites.**

| LOC | Words | Stmt | Move | `D` | Shift |
|---|---|---|---|---|---|
| 00210–00217 | 8 | 189 | MASTER `DEPARTMENT` (w0 b0 L2) → `CURRENT.DEPT` (w3 b3 L2) | +3 | `ARS 18` |
| 00553–00562 | 8 | 201 | DETAIL `DEPARTMENT` (w0 b0) → `CURRENT.DEPT` (w3 b3) | +3 | `ARS 18` |
| 01013–01020 | 6 | 208 | DETAIL `DAY` (w1 b2) → PAYRECORD `DAY` (w4 b3) | +1 | `ARS 6` |
| 01046–01053 | 6 | 208 | DETAIL `MONTH` (w1 b0) → CHECK `MONTH` (w0 b1) | +1 | `ARS 6` |
| 01062–01067 | 6 | 208 | DETAIL `YEAR` (w1 b4) → CHECK `YEAR` (w1 b1) | −3 | `ALS 18` |

The 8-word pair carries one guard (`LAC BL)2,1` / `TXL SYS)294,1,0` at
00212–00213; `LAC BL)3,1` / `TXL` at 00555–00556). The 6-word trio reuses
index 2, loaded once at 00772.

**Grade.** Fully derived: 5 sites, both shift directions, three distinct
distances, and the two mask constants confirmed against the computed byte
offsets. Every attested A3 target is a static (non-located) field; an indexed
`ANS`/`ORS` is unattested (§9).

---

## 4. A4 — the AC shift chain, target at the word head (5 words)

Trigger: `tB == 0`, `L < 6`, `D != 0`, **and** `sB + L == 6`.

```
CAL   target[,i]
LGR   6 * (6 - L)            ; park the target's trailing 6-L chars in the MQ
CAL   source[,i]             ; overwrite the AC with the source word
LGL   6 * (6 - L)            ; one shift, two jobs: left-align the source
                             ; field to byte 0, and pull the parked chars back
SLW   target[,i]
```

Word count **5**. No constant-pool words at all.

Trace, target `PAYRECORD YEAR` at word 5 bytes 0–1, source `DETAIL YEAR` at
word 1 bytes 4–5, `L = 2`, distance 24 bits = 4 characters:

- `CAL` → AC = `T0 T1 T2 T3 T4 T5`
- `LGR 24` → MQ holds `T2 T3 T4 T5` in its high 24 bits
- `CAL src` → AC = `S0 S1 S2 S3 S4 S5`; MQ untouched
- `LGL 24` → AC = `S4 S5 T2 T3 T4 T5`
- `SLW` → the target word, field replaced, tail preserved

**Why `sB + L == 6` is required, not incidental.** The single `LGL` performs
both the restore and the source's left alignment. The restore distance is
fixed at `6 - L` characters; the alignment distance is `sB - tB = sB`
characters. They must be equal, so `sB = 6 - L`. There is no free register to
align the source separately — the MQ is holding the preserved bytes and the AC
is holding the source. This is a **structural derivation from register
pressure**, not an attestation and not a pin: the shape is arithmetically
incapable of any other source position.

**Site.** LOC 01021–01025, statement 208, 5 words. One site only.

**Grade.** Word sequence: attested once, verified by trace. Shift distance
`6 * (6 - L)`: derived from the trace, but only `L = 2` is attested. The
**selection rule** — that the compiler prefers this over A3's 6 words when
`tB == 0` — is inferred from a single site. When `tB == 0`, `D != 0` and
`sB + L != 6`, fall back to A3.

---

## 5. A5 — the MQ shift chain, target at the word tail (6 words)

Trigger: `tB > 0`, `tB + L == 6`, `D != 0`.

```
LDQ   target[,i]
LGL   6 * (6 - L)            ; = 6 * tB; park the target's leading tB chars in the AC
LDQ   source[,i]             ; overwrite the MQ
RQL   6 * sB                 ; rotate the source field up to MQ byte 0
LGR   6 * (6 - L)            ; drop it to byte tB, pulling the parked chars back
STQ   target[,i]
```

Word count **6**. No constant-pool words — the same word count as A3, but two
fewer constants, which is the only visible motive for choosing it.

Trace, target `CHECK DAY` at word 0 bytes 4–5, source `DETAIL DAY` at word 1
bytes 2–3, `L = 2`, park distance 24 bits, rotate 12 bits:

- `LDQ` → MQ = `T0 T1 T2 T3 T4 T5`
- `LGL 24` → AC low 24 bits hold `T0 T1 T2 T3`
- `LDQ src` → MQ = `S0 S1 S2 S3 S4 S5`
- `RQL 12` → MQ = `S2 S3 S4 S5 S0 S1`
- `LGR 24` → MQ = `T0 T1 T2 T3 S2 S3`
- `STQ` → the target word, field replaced, head preserved

The AC's prior contents are irrelevant: `LGL` only needs its low 24 bits, and
the shape stores from the MQ.

**Site.** LOC 01054–01061, statement 208, 6 words. One site only.

**Grade.** Word sequence: attested once, verified by trace. Unlike A4 this
form aligns the source with its own `RQL`, so it is general in `sB` — but
only `sB = 2`, `L = 2` are attested. The **selection rule** is inferred from a
single site. `RQL 0` for a source already at byte 0 is unattested in this
shape (it *is* attested in A6, §7, which is evidence the compiler emits the
degenerate rotate rather than eliding it).

---

## 6. A1 — the whole-word move (2 words per word)

Trigger: `sB == 0 && tB == 0 && L % 6 == 0`.

```
[guard pair for the source register, if forced]
CAL   source[,i]
[guard pair for the target register, if forced]
SLW   target[,j]
```

Word count `2 * (L / 6)`, plus `2 * G`. Only `L = 6` is attested.

**Sites.**

| LOC | Words | Stmt | Move |
|---|---|---|---|
| 00563–00570 | 6 | 202 | DETAIL `DATE` → MASTER `DATE`; both operands located, so two guard pairs (`LAC BL)3,1`/`TXL` at 00563, `LAC BL)2,2`/`TXL` at 00566) |
| 01320–01323 | 4 | 221 | MASTER `DATE` → BONDORDER `DATE` (word 5); one guard pair at 01320–01321, source indexed, target static |

Statement 202 is the family's only attested **indexed target** (`SLW 1)DATE,2`).

**Grade.** Attested twice, both with `L = 6`. Multi-word (`L = 12`, 18, …)
is unattested; M4-9 already states the per-word rule ("word moves, `CAL source
/ SLW target` per word"), so treat `2 * (L / 6)` as M4-9's claim, not a new
derivation.

**Citation.** M4-9 clause 2, statement 202.

---

## 7. A6 — the two-word chain (11 words)

Trigger: `sB + L <= 6` (source inside one word) and `6 < tB + L <= 12`
(target straddles exactly two words). Necessarily `tB > 0` and `L <= 6`.

Let `n1 = 6 - tB` (characters landing in the first target word) and
`n2 = L - n1` (characters landing in the second).

```
CAL   target                 ; first target word
[guard pair for the source register, if forced]
LDQ   source[,i]
RQL   6 * sB                 ; emitted even when zero
ARS   6 * n1
LGL   6 * n1
SLW   target
LGL   6 * n2
LDQ   target+1
RQL   6 * n2
LGL   6 * (6 - n2)
SLW   target+1
```

Word count **11**, plus `2 * G`. Constant `n1`, `n2`, `sB` — none of them
changes the count. No constant-pool words.

**Sites, all three.**

| LOC | Words | Stmt | Move | `tB` | `L` | `n1` | `n2` | `sB` |
|---|---|---|---|---|---|---|---|---|
| 00771–01005 | 13 | 208 | DETAIL `EMPLOYEE.NUMBER` (w0 b0 L6) → CHECK `EMPLOYEE.NUMBER` (chars 39–44 = w6 b3) | 3 | 6 | 3 | 3 | 0 |
| 01033–01045 | 11 | 208 | DETAIL `EMPLOYEE` (w0 b2 L4) → PAYRECORD `EMPLOYEE` (chars 3–6 = w0 b3) | 3 | 4 | 3 | 1 | 2 |
| 01332–01344 | 11 | 221 | MASTER `EMPLOYEE.NUMBER` (w0 b0 L6) → BONDORDER `EMPLOYEE.NUMBER` (chars 1–6 = w0 b1) | 1 | 6 | 5 | 1 | 0 |

Emitted distances against the formula:

| Site | `RQL 6·sB` | `ARS 6·n1` | `LGL 6·n1` | `LGL 6·n2` | `RQL 6·n2` | `LGL 6·(6−n2)` |
|---|---|---|---|---|---|---|
| 00771 | 0 | 18 | 18 | 18 | 18 | 18 |
| 01033 | 12 | 18 | 18 | 6 | 6 | 30 |
| 01332 | 0 | 30 | 30 | 6 | 6 | 30 |

Every cell matches. The first site carries one guard pair
(`LAC BL)3,2` / `TXL SYS)294,2,0` at 00772–00773), giving 13; the other two
reuse a register already loaded.

Trace for `01033`, target words `A` (bytes 3–5 receive) and `B` (byte 0
receives):

- `CAL A` → AC = `A0 A1 A2 A3 A4 A5`
- `LDQ S` / `RQL 12` → MQ = `S2 S3 S4 S5 S0 S1`
- `ARS 18` → AC = `. . . A0 A1 A2`
- `LGL 18` → AC = `A0 A1 A2 S2 S3 S4`, MQ = `S5 S0 S1 . . .`
- `SLW A` ✓
- `LGL 6` → AC = `A1 A2 S2 S3 S4 S5`
- `LDQ B` / `RQL 6` → MQ = `B1 B2 B3 B4 B5 B0`
- `LGL 30` → AC = `S5 B1 B2 B3 B4 B5`
- `SLW B` ✓

**Grade: the strongest result here.** The formula is confirmed at three sites
with three distinct `(n1, n2, sB)` triples, so the shift distances are
*derived*, not fitted. `RQL 0` appears at two sites, which is what keeps the
count at a constant 11.

**Citation.** None. [J 90.02] does not describe it, and M4-9 does not have
this shape at all — M4-9's pinned bound explicitly excludes it. This section
is new, and is **pinned at the diff** as to selection, derived as to
arithmetic.

**Limit.** Every attested site has the source wholly inside one word and the
target static. A source straddling two words would need a second `LDQ` and is
outside the attested shape; a located target would need `target+1,i`, which is
unattested.

---

## 8. The base-locator guard

`LAC BL)n,i` / `TXL SYS)294,i,0` — 2 words — accompanies each load of a base
locator into an index register, once per load, never per reference (M4-9,
[J 90.02.03]).

Placement, unified from the three distinct positions in the sample: **emit the
guard immediately before the first instruction that references that register.**

| LOC | Shape | Where the guard sits |
|---|---|---|
| 00212–00213 | A3 | after `ANS target`, before `CAL source,1` |
| 00563, 00566 | A1 | before `CAL source,1`; again before `SLW target,2` |
| 00772–00773 | A6 | after `CAL target`, before `LDQ source,2` |
| 01320–01321 | A1 | before the statement's first indexed reference |

Reuse is real and must be modelled: index 2 is loaded once at 00772 and then
serves eight further references through 01067; index 1 is loaded once at
01320 and serves 01324 and 01333. Whether a load is forced is the register
allocator's business, not this family's — M4-9's "XR1 for the first buffer
operand of a statement, XR2 for the second" is the standing rule.

---

## 9. What is not grounded

None of these arises in the 90.05 oracle. Recommend the MOVPAK route as the
out-of-domain default, and record each as an open shape rather than guessing.

1. **Source straddling two words** (`sB + L > 6`). No in-line shape attested.
2. **A4 with `sB + L != 6`** (`tB == 0`, `D != 0`, source not a word suffix).
   Arithmetically impossible in the A4 sequence (§4); presumably falls to A3's
   6 words, but that fallback is not attested.
3. **Literal at `tB > 0`.** The pre-positioned-constant reading is the only
   consistent one; both literal sites have `tB == 0`.
4. **Literal straddling two words.** No shape.
5. **Indexed target in A2, A3, A5, A6.** Every attested mask or chain target
   is a static field in a non-located record. Only A1 attests an indexed
   target (statement 202).
6. **`D == 0` with a two-word target.** A6 emits the full 11 words regardless
   of `sB`; whether a `D == 0` two-word move gets a cheaper form is unknown.
7. **Multi-word A1** (`L = 12`, 18, …). Only `L = 6` attested.
8. **`L = 1`, 3, 4, 5 in A4 and A5.** Only `L = 2` attested in each.
9. **Constant-pool sharing.** Mask cells are pooled by value: `CP)+25` serves
   three separate sites, `CP)+16`/`+17` serve three, `CP)+35`/`+36` serve two.
   The pooling rule itself belongs to the constant-pool family.

---

## 10. Corrections to the site list this task was given

1. **LOC 00263–00272 (statement 193) is not in this family.** It is
   `LDI CP)+42 / STI SYS)133 / CAL BL)2 / ACL CP)+43 / SLW SYS)132 /
   TSX SYS)182,4 / TXI SYS)240,1,21 / TXI SYS)241,1,2` — a MOVPAK dispatch
   with an in-line descriptor build, [J 90.02.11] case 2. It is
   `MOVE MASTER DAT TO ERROROUT INFO`, 23 characters.
2. **LOC 00310–00317 is likewise MOVPAK** (`MOVE DETAIL TO ERROROUT INFO`,
   15 into 23 characters). Only 00320–00324 of the given 00310–00324 range
   belongs here.
3. **Statement 221's guard sits at 01320–01321,** outside the given
   01322–01323. The move itself is the 2-word A1 at 01322–01323; the site is
   4 words with its guard.
4. **Statement 208's given split (00771–01005 / 01006–01067) is not the
   record boundary.** The expansion is nine per-pair blocks, and the two
   receivers interleave:

   | LOC | Target | Source | Shape | Words |
   |---|---|---|---|---|
   | 00771–01005 | CHECK `EMPLOYEE.NUMBER` | DETAIL `EMPLOYEE.NUMBER` | A6 + guard | 13 |
   | 01006–01012 | PAYRECORD `MONTH` | DETAIL `MONTH` | A2 | 5 |
   | 01013–01020 | PAYRECORD `DAY` | DETAIL `DAY` | A3 | 6 |
   | 01021–01025 | PAYRECORD `YEAR` | DETAIL `YEAR` | A4 | 5 |
   | 01026–01032 | PAYRECORD `DEPARTMENT` | DETAIL `DEPARTMENT` | A2 | 5 |
   | 01033–01045 | PAYRECORD `EMPLOYEE` | DETAIL `EMPLOYEE` | A6 | 11 |
   | 01046–01053 | CHECK `MONTH` | DETAIL `MONTH` | A3 | 6 |
   | 01054–01061 | CHECK `DAY` | DETAIL `DAY` | A5 | 6 |
   | 01062–01067 | CHECK `YEAR` | DETAIL `YEAR` | A3 | 6 |

   **Out of family, flagged for the CORRESPONDING family:** the receiver
   order really is CHECK, then PAYRECORD ×5, then CHECK ×3, even though the
   source reads `MOVE CORRESPONDING DETAIL TO PAYRECORD, CHECK`. This is not
   a symbol-numbering misread — the byte geometry of each block matches its
   assigned record independently (PAYRECORD `MONTH` at byte 0 needs no shift;
   CHECK `MONTH` at byte 1 needs `ARS 6`; both appear, and only this
   assignment fits). M4-9 clause 4 says "one ordinary move per pair" in
   data-description order and clause 5 says "one independent sequence per
   target" — neither predicts this interleaving. Do not derive it here.

---

## 11. Provenance

**Byte offsets.** Computed from the DATA division
(`comtran-manuals/J28-6169/90.05-sample-program.md` lines 204–460) at six
characters per word, counting every `GN)nnn` filler. Confirmed independently
against ten MOVPAK descriptor cells in the constant pool, whose decrement
field is the byte offset: `CP)+42 PZE INFO,,1`, `+47 PZE 3)NAME,,2`,
`+48 PZE 3)EMPLOYEE,,3`, `+49 PZE 4)MONTH,,0`, `+50 PZE 4)DAY,,3`,
`+51 PZE 4)YEAR,,0`, `+53 PZE HRS,,5`, `+57 PZE 2)NAME,,5`,
`+58 PZE 4)NAME,,2`, `+43 PZE 1)DAT,,0`. All ten agree. The four mask
constants agree bit for bit with the offsets they mask (§2).

**Symbol prefixes.** `n)NAME` in the object listing is the *n*-th declaration
of that name in DATA-division order, not a level number. Cross-checked on
`DATE` (statement 202 moves `2)DATE` to `1)DATE` = DETAIL to MASTER),
`GROSS` (`4)GROSS` = WORKING, `2)GROSS` = PAYRECORD), `HOURS` (`3)HOURS` =
WORKING), and `DEPARTMENT` (`3)DEPARTMENT` = PAYRECORD, matching statement
199's `MOVE 'GT' TO PAYRECORD DEPARTMENT`).

**Word counts.** By octal subtraction of the LOC column, computed twice.

**What the Dart generator needs.** `ItemSemantics.word`, `.byte`,
`.storageChars`, `.fieldClass`; `RecordInfo.located` to know whether an
operand needs a base locator. Nothing else in §0's formula table reaches
outside those.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.03]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.11]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
