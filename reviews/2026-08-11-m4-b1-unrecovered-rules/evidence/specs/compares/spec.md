# Comparisons, skip vectors, and the later-pass names

Derived from the 90.05 object listing (`test/fixtures/90.05-object-listing.target`),
J28-6169 Appendix 90.02, and `docs/design/m4-codegen.md` entries M4-6 and M4-11.
Every word count below was checked twice by octal subtraction of LOC values.

Two corrections to `docs/design/m4-codegen.md` fall out of the diff. They are
stated in §6.

---

## 1. The machine primitive

`CAS` (octal 0340, algebraic) and `LAS` (octal 4340, logical) each compare the
accumulator against one storage word and leave control at one of three **fixed
one-word slots**:

| slot | address | taken when |
|---|---|---|
| slot 1 | compare + 1 | AC **greater than** storage |
| slot 2 | compare + 2 | AC **equal to** storage |
| slot 3 | compare + 3 | AC **less than** storage |

The order greater / equal / less is not an inference from the sample. It is the
documented order of the three return words of the out-of-line comparison
subroutine, `HIGH RETURN / EQUAL RETURN / LOW RETURN` [J 90.02.12], and the
in-line skip vector reproduces it word for word.

Because the slots are at fixed displacements, **the vector can only shrink from
the end.** Dropping slot 2 would put the following code at compare+2, and the
"less" outcome would then land at compare+3, one word *inside* that code. Only
slot 3 can be given up, and only to code that the "less" outcome may legally
enter. This is the whole derivation of the elision rule in §3.

---

## 2. The comparison shapes

### 2.1 Which operand goes into the accumulator

The slot-to-outcome map, and therefore the elision predicate and the word count,
depend on which source operand the generator loads. Decide it in this order:

1. **A materialized operand must be in AC.** An operand that is produced by a
   computation rather than named by an address goes into AC and the other
   operand becomes the storage operand. Two producers are attested:
   - a **zero** operand (`ZERO` or the literal `0`) in a numeric compare, built
     by `LDQ CP)+0 / MPY CP)+scale / XCA` — three words (statements 205, 215);
   - the **second** of two operands that both need sub-word extraction; the
     first is spilled to a Result Storage cell and becomes the storage operand
     (statement 200).
2. **A figurative constant goes into AC** in an equality or inequality compare
   (`HIGH.VALUE` at statements 197 and 198: `CAL CP)+23`, with the record field
   on the `LAS`). *Pinned at the diff.* Two sites, one construct. A written
   numeric literal is **not** covered — `40.0` and `144.00` stay on the storage
   side as pool words (statements 203, 212).
3. **Otherwise AC takes the left source operand** and storage the right
   (statements 192 both clauses, 203, 212, 220, 225).

With the placement fixed, map each machine outcome to the truth of the source
relation by substitution. Example, statement 220 `MASTER BONDENOMINATION NOT GT
M.BND.ACC`: rule 3 puts BONDENOMINATION in AC, so greater = "left GT right" =
relation false, equal and less = true.

**This is load-bearing for chunk B1.** For an asymmetric relation, swapping AC
and storage swaps which outcome is "less", which changes the elision predicate
of §3, which changes the vector from three words to two. The AC=left default is
what makes statements 203, 212 and 225 come out at three vector words.

### 2.2 Operand prologue `P(x)` — index-register setup

A field of a record that is not at a fixed address (`RecordInfo.located` false —
a record read through an input buffer, or an item located through a positional
indicator) is addressed through an index register:

```
LAC    BL)k,t          (or  LAC PI)n,t)
TXL    SYS)294,t,0
```

`P(x) = 2` words. `SYS)162`'s neighbour `SYS)294` is the documented
base-locator-not-loaded trap, and the two-word pair is the manual's own form
[J 90.02.23; J 90.02.04]. `t` is 1 for the first such operand of the compare and
2 for the second.

`P(x) = 0` for a working-storage item, a located record's field, and a constant
pool word.

`P(x) = 0` also when index register `t` already holds that base. **Liveness rule
(cross-family; belongs to the operand-addressing family, pinned at the diff):**
the generator caches what index registers 1 and 2 hold; the cache is cleared at
any word that carries a label and at any instruction that writes the register.
Attested reuse: LOC 00251–00252 (statement 192's second clause, no intervening
label) and LOC 01202 (statement 212 reusing statement 211's setup at 01175).
Attested reload: LOC 00555 after label `GN)071`, LOC 01301 after `AXT 6,1` at
01300, LOC 01405 after label `SEARCH`.
**The accumulator is never cached.** LOC 00251 re-issues `CAL
2)EMPLOYEE.NUMBER,1` for a value the AC already holds from 00243.

### 2.3 Extraction `E(x)` — alphameric sub-word fields

For an alphameric operand held in part of a word, using `ItemSemantics`
`startChar` (0–5) and `storageChars`:

```
LGL    6*startChar     emitted when startChar > 0
ANA    CP)+mask        emitted when storageChars < 6   (mask = top 6*storageChars bits)
```

`E(x) = (startChar > 0 ? 1 : 0) + (storageChars < 6 ? 1 : 0)`.

Attested at statement 200 only: `CURRENT.DEPT` gives 2 (`LGL 18` = 6×3, then
`ANA CP)+30` = `777700000000`, two characters); `2)DEPARTMENT,1` gives 1 (mask
only, `startChar` 0). The `storageChars == 6` case emits neither word — that is
the behaviour at statements 192, 197 and 198, where the six-character
`EMPLOYEE.NUMBER` is compared whole.

When **both** operands need extraction, the first-evaluated one is spilled:
`SLW <section>.RS)n`, one word, and becomes the storage operand. The manual's
own examples of the idiom are `SLW 1.RS)0` and `LAS 2.RS)2` [J 90.02.03]. The
section prefix is omitted in section 0. The choice of cell number `n` is the
`RS)` scheme — defer to chunk B1.

### 2.4 Shape **CMP-NUM** — numeric compare, in line

**Trigger.** An `IF`, a conditional `GO TO ... WHEN` clause, or a `TR( )`, whose
relational expression compares two operands of numeric `fieldClass` (or a
numeric literal), each holding in one word.

```
[P(A)]                     index setup for the AC operand
CLA    A                   or the 3-word zero build (§2.1 rule 1)
[P(B)]                     index setup for the storage operand
CAS    B
<skip vector>              §3
```

**Word count.**

```
CMP-NUM = P(A) + L(A) + P(B) + 1 + V
  L(A) = 3 when A is a zero operand   (LDQ CP)+0 / MPY CP)+scale / XCA)
       = 1 otherwise                  (CLA A)
  V    = §3
```

The scale constant `CP)+scale` is the arithmetic family's rescale word — defer
to chunk B3.

**Sites.**

| statement | LOC range | P(A) | L(A) | P(B) | V | total |
|---|---|---|---|---|---|---|
| 203 | 00612–00616 | 0 | 1 | 0 | 3 | 5 |
| 205 | 00656–00665 | 0 | 3 | 2 | 2 | 8 |
| 212 | 01202–01206 | 0 | 1 | 0 | 3 | 5 |
| 215 (`TR`) | 01241–01246 | 0 | 3 | 0 | 2 | 6 |
| 220 | 01301–01306 | 2 | 1 | 0 | 2 | 6 |
| 225 | 01405–01415 | 2 | 1 | 2 | 3 | 9 |

**Citation.** Slot order [J 90.02.12]; the `LAC`/`TXL SYS)294` prologue
[J 90.02.23], [J 90.02.04]; the generator's existence, M4-11.

### 2.5 Shape **CMP-ALPHA** — alphameric or logical compare, in line

**Trigger.** The same constructs, with operands of alphameric `fieldClass`, or a
logical compare. Selected by operand mode, not by operator.

```
[P(x1)]
CAL    x1
[E(x1)]                    LGL / ANA
[SLW  RS)n]                only when x2 also needs extraction
[P(x2)]
CAL    x2                  omitted when x1 stays in AC (no spill)
[E(x2)]
LAS    <RS)n or x2>
<skip vector>
```

Read that as: evaluate the first operand into AC; if the second operand also
needs AC, spill the first and load the second; compare. When only one operand
needs AC work, the other is written directly on the `LAS`.

**Word count.**

```
CMP-ALPHA = P(x1) + 1 + E(x1) + S + P(x2) + S*1 + E(x2) + 1 + V
  S = 1 when both operands need extraction (E(x1) > 0 and E(x2) > 0), else 0
```

The `S*1` term is the second `CAL`, which exists only in the spill case. Written
without the shorthand, the two cases are:

- **no spill:** `P(x1) + 1 + E(x1) + P(x2) + E(x2) + 1 + V`
- **spill:** `P(x1) + 1 + E(x1) + 1 + P(x2) + 1 + E(x2) + 1 + V`

**Sites.**

| statement | LOC range | shape | total |
|---|---|---|---|
| 192 clause 1 | 00241–00250 | no spill, no extraction, both operands buffered | 2+1+2+1+2 = 8 |
| 192 clause 2 | 00251–00255 | as above, both prologues suppressed by liveness | 0+1+0+1+3 = 5 |
| 197 | 00332–00340 | AC = pool constant, storage buffered | 1+2+1+3 = 7 |
| 198 | 00351–00357 | as 197 | 7 |
| 200 | 00527–00541 | spill, both operands extracted | 1+2+1 + 2+1+1 + 1+2 = 11 |

**Citation.** [J 90.02.03] for the `SLW`/`LAS` scratch-cell idiom; M4-11.

### 2.6 Shape **CMP-OUT** — the out-of-line comparison

**Trigger.** A field the compiler cannot compare in one word. **No sample site.**

```
TSX    SYS)162,4
OP     SYS)161            CVR under COLLATE COM, NOP otherwise
PZE    LOC(1),T(1),LOCATOR(1)
PZE    LENGTH(1),,6*BYTE(1)
PZE    LOC(2),T(2),LOCATOR(2)
PZE    LENGTH(2),,6*BYTE(2)
HIGH   RETURN
EQUAL  RETURN
LOW    RETURN
```

**Word count: exactly 9, always.** The three return words are part of the
documented calling sequence; there is no elision here, and no relative form is
documented.

`LENGTH(J)` is `storageChars`, `BYTE(J)` is `startChar`, `T(J)` is zero for a
directly addressed field and non-zero for one reached through a pointer word,
in which case `LOC(J)` is the word displacement and `LOCATOR(J)` the pointer.

**Citation.** [J 90.02.12], verbatim. The *trigger* — where the in-line/out-of-line
boundary falls — is M4-11's, and remains unexercised.

### 2.7 Shape **TR** — the truth function

**Trigger.** `TR( <relation> )` used as an arithmetic factor.

```
RIR    777777             clear every sense indicator
<comparison unit>         CMP-NUM or CMP-ALPHA, without its vector
<skip vector>             the TRUE outcome routed to slot 3
SIR    000001             occupies slot 3
PXA    0,0                AC := 0
RFT    000001             skip the next word when indicator 1 is off
CLA    CP)+1              AC := 1
```

`RFT` skips when the tested bits are all zero, so the AC leaves the block
holding 1 when the relation held and 0 when it did not.

**Word count.**

```
TR = 1 + (comparison unit less its vector) + V + 4
```

**Site.** Statement 215, LOC 01240–01252, eleven words:
1 + (3 + 1) + 2 + 4.

**Pinned at the diff, and narrow.** The shape works only because the true
outcome is the *less* outcome, so the one-word `SIR` can occupy slot 3 and the
two false slots elide to relative transfers. At the one attested site that
placement was forced by §2.1 rule 1 — zero had to be built into AC — so the
sample never shows the generator *choosing* an operand order to obtain it.
A relation whose true outcome is `equal` cannot put `SIR` in slot 3 at all, and
no shape for that case is attested. Do not generalise this block beyond a
single-outcome true condition without new evidence.

---

## 3. The skip vector

### 3.1 Word count

```
V = 3 - (continuation(less) is the next word to be emitted ? 1 : 0)
```

That is the whole rule. **At most one slot is ever dropped**, and it is always
slot 3, for the reason in §1.

Verified against all eleven attested vectors — six `CAS`, five `LAS`, the tally
M4-11 records:

| statement | vector LOC | V | `continuation(less)` | next word | elided |
|---|---|---|---|---|---|
| 192 c1 | 00247–00250 | 2 | 00251 | 00251 | yes |
| 192 c2 | 00253–00255 | 3 | `LOW.DETAIL` 00310 | 00256 | no |
| 197 | 00336–00340 | 3 | `GN)066` 00342 | 00341 | no |
| 198 | 00355–00357 | 3 | `GN)068` 00361 | 00360 | no |
| 200 | 00540–00541 | 2 | 00542 | 00542 | yes |
| 203 | 00614–00616 | 3 | `GN)072` 00637 | 00617 | no |
| 205 | 00664–00665 | 2 | 00666 | 00666 | yes |
| 212 | 01204–01206 | 3 | `GN)076` 01217 | 01207 | no |
| 215 | 01245–01246 | 2 | 01247 (`SIR`) | 01247 | yes |
| 220 | 01305–01306 | 2 | 01307 | 01307 | yes |
| 225 | 01413–01415 | 3 | `GN)081` 01417 | 01416 | no |

A two-slot elision (dropping slot 2 as well) is a legal encoding when the equal
continuation is the next word *and* the less continuation is the word after
that. It is not attested. **Do not implement it** — emit at most one elision.

### 3.2 How each emitted slot prints

```
if the generator holds a symbol for this outcome's continuation:
        TRA  <that symbol>
else:
        TRA  *+n      where n = continuationAddress - slotAddress
```

A symbol is held when the continuation is a target the source named (a paragraph
or section name written in a `GO TO`/`WHEN`), or an arm or join label that M3-23
allocated for this statement (a `GN)0nn`). No symbol is held for:

- the THEN arm, which is always laid down immediately after the vector and is
  never labelled;
- the next `WHEN` clause's compare, and the fall-through past the last clause;
- the interior of a `TR( )` block.

`n` is a decimal word count. For a three-slot vector, slot 1 targeting the next
word prints `*+3` and slot 2 prints `*+2`; for a two-slot vector, `*+2` and
`*+1`.

Every slot of every attested vector obeys this:

| statement | slot 1 | slot 2 | slot 3 |
|---|---|---|---|
| 192 c1 | `TRA *+2` → 00251 | `TRA CHECK.NEW.DEPT` | elided |
| 192 c2 | `TRA *+3` → 00256 | `TRA *+2` → 00256 | `TRA LOW.DETAIL` |
| 197 | `TRA GN)066` | `TRA *+2` → 00341 | `TRA GN)066` |
| 198 | `TRA GN)068` | `TRA *+2` → 00360 | `TRA GN)068` |
| 200 | `TRA *+2` → 00542 | `TRA GN)070` | elided |
| 203 | `TRA *+3` → 00617 | `TRA GN)072` | `TRA GN)072` |
| 205 | `TRA *+2` → 00666 | `TRA GN)074` | elided |
| 212 | `TRA *+3` → 01207 | `TRA GN)076` | `TRA GN)076` |
| 215 | `TRA *+3` → 01250 | `TRA *+2` → 01250 | elided (`SIR`) |
| 220 | `TRA GN)079` | `TRA *+1` → 01307 | elided |
| 225 | `TRA *+3` → 01416 | `TRA GN)081` | `TRA GN)081` |

### 3.3 Where each outcome goes

| construct | true outcome | false outcomes |
|---|---|---|
| `IF … THEN … OTHERWISE …` | the THEN arm, laid immediately after the vector | the OTHERWISE arm's own `GN)0nn` — **not** the join |
| `IF … THEN …`, no OTHERWISE | the THEN arm, immediately after the vector | the join `GN)0nn`, the word after the THEN arm |
| `GO TO t WHEN …` | the written target `t` | the word after the vector: the next clause's compare, or the statement after the last clause |
| `TR( … )` | the `SIR 000001` at slot 3 | the word after `SIR` |

The "not the join" point is attested three ways: `GN)072` at statement 203,
`GN)074` at 205, `GN)081` at 225 are each the OTHERWISE arm's own label while a
separate join label follows.

Layout words the vector's addresses depend on, but which are not part of the
vector:

- A THEN arm that does not end in an unconditional transfer gets one trailing
  `TRA <join>` (00545, 00636, 00671, 01312). A THEN arm that *is* a `GO TO`
  gets none (00341, 00360, 01416).
- The OTHERWISE arm carries its label and falls into the join; no trailing word.
- The join label costs no word of its own; it lands on the first word of the
  following statement (`GN)071` at 00547, `GN)075` at 00702, `GN)076` at 01217).

---

## 4. The later-pass generated names

### 4.1 What the sample shows

M3-23 allocates `GN)000` through `GN)083` in source order. The later pass
continues from `GN)084`. Six of the ten names 084–093 are bound and print:

| name | binding | printed at | site |
|---|---|---|---|
| `GN)085` | `EQU SEARCH+1` | 01405 | statement 206 |
| `GN)086` | label on the increment block | 00711 | statement 206 |
| `GN)088` | `EQU CP)+37` (`PZE 2)RATE+0`) | 01741 | statement 206 |
| `GN)089` | label on the patched `IOST` word | 01163 | statement 208 |
| `GN)091` | `EQU CP)+38` (`PZE RETPREM-2`) | 01742 | statement 225 |
| `GN)093` | `EQU CP)+39` (`PZE INSPREM-2`) | 01743 | statement 225 |

`GN)084`, `087`, `090` and `092` appear nowhere in the listing, in neither a
label field nor an operand.

### 4.2 The pass order

The later pass walks the emitted procedure text in **ascending object address**
and gives each machinery site one contiguous run of numbers. The three sites are
at 00702, 01157 and 01421, and their bound names ascend with them. This is firm.

### 4.3 The three sites

**Statement 206, `DO SEARCH FOR INDEX = 1(1)12`, LOC 00702–00721.** Three names
bound out of the run:

- `GN)085 EQU SEARCH+1` — the loop-body entry, used by the back edge
  `TPL GN)085` at 00721. Note that the forward entry at 00710 writes
  `TRA SEARCH+1` literally instead of using the name.
- `GN)086` — the increment block at 00711, used by `AXT GN)086,4` at 00702,
  which patches SEARCH's return cell once before the loop.
- `GN)088 EQU CP)+37` — the table-base pointer constant, loaded by
  `CLA GN)088` at 00706 into `PI)1`.

**Statement 208, `FILE MASTER`, LOC 01157–01163.** One name bound:

- `GN)089` — the label on `IOST MASTER,,15`, whose address field is patched at
  run time by `LXA BL)2,4 / SXA GN)089,4`.

  The trigger for the patch is worth recording: MASTER is read through an input
  buffer, so its address is not a fixed symbol. The two `FILE`s immediately
  before it, `FILE CHECK` (01151–01153) and `FILE PAYRECORD` (01154–01156), are
  fixed-location records and are emitted with no `LXA`/`SXA` pair and no label.

**Statement 225, the two subscripted sources, LOC 01421–01432.** Two names
bound, one to each subscript base:

- `GN)091 EQU CP)+38` (`PZE RETPREM-2`), added at 01424 to form `PI)3`;
- `GN)093 EQU CP)+39` (`PZE INSPREM-2`), added at 01431 to form `PI)2`.

  The two setups are emitted in the reverse of source order — RETPREM's base is
  computed first — while the positional-indicator numbers follow source order,
  `PI)2` to INSPREM (written first) and `PI)3` to RETPREM. Name allocation
  follows the emission order, not the source order.

### 4.4 Why four names never print

**They were never bound, not suppressed.** The listing prints two names on one
word as two separate lines whenever both exist: `GN)076` and `GN)077` both at
01217, `GN)075` at 00702 above the `AXT`, `GN)082` above `SEARCH.END` at 01472,
`GN)063` above `COMPARE.EMPLOYEE.NUMBERS` at 00241. The printer therefore has no
rule that hides a redundant name. Multiple-name printing is the manual's own
documented behaviour, "each name is printed, one name per line" [J 90.02.02].

This **refutes the mechanism** in M4-6's working rule, which explains the gaps by
words that "fall through" or take an in-line form. A name on a fall-through word
would still have printed. The gaps are names the pass reserved and the shape then
did not need.

Note also that the manual's description of the GN class predicts a *dense*
counter — "During compilation it is necessary to give certain instructions names
in order to refer to these instructions from a remote part of the program. Names
are generated and placed on such instructions" [J 90.02.06]. Sparseness is a fact
of the diff, contrary to a plain reading of the manual, and M4-6's headline
finding — a design that assumes a dense counter is wrong by construction — is
confirmed.

### 4.5 The rule that reproduces 084–093 — **fitted, not derived**

Each machinery site reserves a fixed run of names sized by its template, and
binds only the ones the instance uses:

| site | run | bound |
|---|---|---|
| `DO … FOR` (statement 206) | 084, 085, 086, 087, 088 — five | 085, 086, 088 |
| `FILE` of a buffered record (statement 208) | 089, 090 — two | 089 |
| subscripted reference, RETPREM (statement 225) | 091, 092 — two | 091 |
| subscripted reference, INSPREM (statement 225) | 093, 094 — two | 093 |

This reproduces the printed sequence exactly. **Label it fitted at the diff.**
Three sites cannot determine four run lengths, and the model is chosen for
economy, not derived.

What is firm and what is not:

- **Firm.** The run for statement 206 is exactly 084–088. `GN)088` belongs to
  statement 206 and `GN)089` to statement 208, and the pass runs in address
  order, so the boundary between the two runs falls between them; M4-6's "the
  counter continues from 084" fixes the lower end.
- **Not firm — the placement of 090 and 092.** Two groupings fit the print
  equally: `FILE`=2 names and each subscript reference=2 with the first bound
  (the table above); or `FILE`=1 name, RETPREM=(090,091) with the second bound,
  INSPREM=(092,093) with the second bound. Nothing in the sample separates them,
  because 094 and beyond are unobservable — the counter ends.
- **Not firm — the roles of 084 and 087 inside statement 206's run.** Their
  positions are certain; their meanings are inference from what a `DO … FOR`
  template needs and does not bind here. The natural reading, in template order,
  is 084 = the loop prologue's entry label and 087 = the loop exit label: the
  prologue is entered by fall-through from statement 205's join and the exit
  falls through to `NET`, so neither is referred to remotely and neither is
  bound. **This is a guess consistent with the bind pattern, nothing more.** The
  sample offers no way to distinguish it from any other five-symbol template
  whose second, third and fifth members are the body entry, the increment block
  and the table base.
- **Not grounded at all — what the second name of the `FILE` and subscript
  templates would be.** No candidate is offered.

---

## 5. What a generator can reach

Every operand description above resolves to `ItemSemantics` and `RecordInfo`
fields already in `lib/src/data/data_map.dart`:

| decision | field |
|---|---|
| `CAS` versus `LAS` | `fieldClass` |
| whether `P(x)` is 2 or 0 | `RecordInfo.located`, plus the index-register cache |
| `LGL` shift amount | `startChar` |
| `ANA` mask width, `SYS)162` `LENGTH` | `storageChars` |
| `SYS)162` `BYTE` | `startChar` |
| subscript stride | `quantity` and the item's word length |

Two inputs are **not** reachable from `ItemSemantics` and must come from
elsewhere: the rescale constant `CP)+scale` for a zero operand (chunk B3's
arithmetic scaling), and the `RS)n` cell number for a spill (chunk B1's Result
Storage scheme).

---

## 6. Corrections to `docs/design/m4-codegen.md`

**M4-11's relative-form rule is positional and is falsified.** The record says an
interior slot prints the relative form when "its target is the word immediately
after the vector". At statement 215 (LOC 01245, 01246) both slots target 01250,
while the word immediately after the vector is 01247, and both still print
relative — `TRA *+3` and `TRA *+2`. The symbol-based rule of §3.2 covers this
site and all ten others.

The two rules disagree at exactly one site. Every other slot in the sample is
consistent with both, including the case that looks like a counter-example and is
not: at statement 192 clause 2 the relative targets 00256 *carry* the programmer
label `HIGH.DETAIL`, yet both slots print relative — because the generator holds
no symbol for "the fall-through past my own statement", only for the `WHEN`'s
written target. Under the symbol rule that is expected; under a
target-is-unlabelled rule it is a contradiction. The correction rests on one
discriminating site; record it as such.

**M4-11's site attribution is off by one statement.** The record cites
"`TRA *+1` at statement 219, LOC 01306". LOC 01306 belongs to statement 220,
`IF MASTER BONDENOMINATION NOT GT M.BND.ACC`. Statement 219 is a `MOVE` and
generates no compare.

**M4-11's skip-vector rule is otherwise confirmed, site by site**, including the
elision predicate, the "at most one" limit, the three-slot `GT`-with-both-arms
shape, the two-slot `NOT EQUAL` shape, and the two-slot `WHEN =` shape. §3.1 adds
the derivation the record lacked: only slot 3 is droppable, because slots sit at
fixed displacements from the compare.

**M4-6's gap mechanism is refuted; its headline is confirmed.** The record
explains the unprinted names by fall-through and in-line absorption. Co-located
names print on separate lines throughout the sample, so an unprinted name was
never bound. The record's conclusion — that a dense counter is wrong by
construction — stands, and §4.5 supplies a fitted rule that reproduces 084–093
exactly, with the two unresolved placements named.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02.02]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.03]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.04]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.06]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.12]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.23]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
