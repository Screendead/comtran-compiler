# Chunk B1 — the program frame: DO, sections, END, STOP, GO TO, and the I/O calling sequences

Scope: the shapes M4-12 to M4-15 name. Word counts are the deliverable; every
count below was taken twice by octal subtraction of the LOC column of the
scan-verified object listing (`test/fixtures/90.05-object-listing.target`).

The task text named the scratch directory `undefined/structure`, an
uninterpolated orchestrator variable. It is resolved here to
`<session scratchpad>/structure/`.

Two words are used precisely throughout:

- **Attested** — a site in the 1962 object listing exhibits it.
- **Pinned at the diff** — the answer key shows it and no manual text or design
  record derives it. Every such rule is labelled. Do not read a pinned rule as
  a derivation.

---

## 0. Sizing preliminaries

### 0.1 What consumes a word

A generated line consumes one word of the location counter if and only if it
carries an octal word in the OCTAL column. These consume **zero** words and
must not be counted when sizing a unit:

| Line kind | Sample sites |
|---|---|
| `EQU` | LOC 01741, 01405, 01742, 01743 |
| `USE n` | listing head, and the two lines around the `USE 2` block |
| a label-only line (a name with no instruction) | LOC 00165, 00232, 00241, 00370, 00702, 01217, 01472 |
| the instruction continuation under an over-long label | LOC 01220 |

### 0.2 Two names on one word

When two names land on the same word, the **first** prints on a line of its own
carrying only the name, and the **second** prints in the label column of the
instruction line. Both lines print the same LOC. Attested six times:

| LOC | label-only line | instruction line |
|---|---|---|
| 00165 | `GN)000` | `START TSX SYS)175,4` |
| 00232 | `GN)061` | `GET.DETAIL TXH …` |
| 00241 | `GN)063` | `COMPARE.EMPLOYEE.NUMBERS LAC BL)3,1` |
| 00370 | `GN)069` | `END.OF.RUN AXT *+3,7` |
| 01217 | `GN)076` | `GN)077 TRA* FICA.ROUTINE` |
| 01472 | `GN)082` | `SEARCH.END TRA* SEARCH` |

LOC 00702 is a seventh label-only line but not an instance of this rule: only
one name (`GN)075`) lands on that word, and what pushes it onto its own line is
the `GN)088 EQU` line interleaved after it, which claims the label column of
the next printed line (§9). Whether `GN)075` would otherwise have printed on
the `AXT` line cannot be decided from this listing.

A label longer than the label column pushes its instruction to the next printed
line instead (LOC 01220, `WITHOLDING.TAX.ROUTINE`). Citation: M4-8, M4-8.1.
Neither line changes any word count.

### 0.3 The relative-offset column

The `+n` column counts **printed lines since the last line that carried a name
in the label column**, not words. A label-only line and an `EQU` line each reset
it, and the line after a label-only line prints `+1` at the same LOC (00702).
Attested throughout. Citation: M4-8. Sizing must never read this column.

### 0.4 Operand-order conventions in the printed text

- `PZE a,,d` — `a` is the address field, `d` the decrement. Verified:
  `PZE CP)+26,,CP)+27` assembles `0 01727 0 01726`.
- `TXH a,t,d` — address, tag, decrement. Verified: `TXH CP)+22,0,CP)+19`
  assembles `3 01717 0 01722`.
- `TXI a,t,d` with a zero decrement prints as `TXI a,t`. Verified:
  `TXI IOC)40,0` assembles `1 00000 0 00050`.
- `SYS)n` and `IOC)n` each assemble to absolute address `n`. Verified:
  `IOC)8`→00010, `IOC)9`→00011, `IOC)40`→00050, `SYS)177`→00261,
  `SYS)294`→00446.
- `BL)n` and `PI)n` are **1-based**: `BL) BSS 3` at 01666 gives BL)1=01666,
  BL)2=01667, BL)3=01670; `PI) BSS 3` at 01671 gives PI)1=01671. Verified
  against `ORG BL)1` at 01666 and `STO PI)1` assembling 01671.
- A file name assembles to `04000 + k`, k the 1-based ordinal of the file's
  declaration in the ENVIRONMENT DIVISION. Verified: INPUTMASTER 04001,
  OUTPUTMASTER 04002, DETAILFILE 04003, CHECKFILE 04004, PAYFILE 04005,
  BONDORDERFILE 04006 (implied), ERRORFILE 04007. The symbolic operand is
  the file name; the generator needs no encoding.

### 0.5 Record length

Every I/O shape that carries a length carries **the record's length in 36-bit
words**, not the file's BLOCKSIZE.

```
lenWords(record) = number of words the record occupies
                 = ceil(record.storageChars / 6)
```

Proof that it is the record and not the block: ERRORFILE declares
`BLOCKSIZE 6` and its `IOST ERROROUT,,4` says 4, which is ERROROUT's
`BSS 4`. INPUTMASTER declares `BLOCKSIZE 300` and its descriptor says 15.
Cross-checks against the storage map: CHECK 00000–00017 = 16 = `IOST CHECK,,16`;
PAYRECORD 00020–00043 = 20; DEPARTMENT.TOTAL 00044–00067 = 20;
BONDORDER 00070–00075 = 6; DETAIL 6+6+3 chars = 15 chars → 3 words =
`IOCTN* BL)3,,3`.

### 0.6 Base locators

BL)1 is pre-initialized to the IOCS label area and is never referenced by
procedure text. Record locators start at BL)2 and are assigned **one per
buffer-located record**, in record-declaration order: MASTER → BL)2,
DETAIL → BL)3. A record shared by an input and an output file keeps one
locator (MASTER is read through INPUTMASTER and written through OUTPUTMASTER,
both using BL)2). Attested twice; a two-point rule.

`RecordInfo.located` is the selector. In the sample, exactly the records named
by INPUT files are located; every located record is absent from the `*DATA`
storage map.

The initialization block prints after the procedure text:

```
       USE    2
01666  ORG    BL)1
01666  PZE    IOC)29
01667  PZE    0
01670  PZE    0
       USE    1
```

Three words in the initialization location counter, overlaying `BL) BSS 3`.
BL)1 holds `PZE IOC)29`, the 14-word IOCS label-processing area
[J 90.02.09]. `USE`/`ORG` cost no words; the three `PZE` words do.

---

## 1. OPEN ALL FILES

**Trigger.** The source clause `OPEN ALL FILES`.

**Words: 2. Constant.**

```
TSX    SYS)175,4
PZE    IOC)1
```

**Site.** LOC 00165–00166, statement 188. The first word carries the program
entry name `GN)000` (label-only line) and the paragraph label `START`.

**Citation.** [J 90.02.14] SYS)175: "This routine opens all files in the file
list located by IOC)1." M4-15.

**Sibling, no sample site.** `OPEN <file>` is `TSX SYS)174,4 / PZE FILENAME`,
2 words [J 90.02.13]. Manual-grounded, unattested here.

---

## 2. CLOSE ALL FILES

**Trigger.** The source clause `CLOSE ALL FILES`, written explicitly.

**Words: 2. Constant.**

```
TSX    SYS)177,4
PZE    IOC)1
```

**Site.** LOC 00517–00520, statement 199. This pair is the source's own
`CLOSE ALL FILES` clause; the identical pair at 00524–00525 belongs to
STOP RUN's implicit close-all (§7). Two back-to-back SYS)177 pairs are
otherwise unexplained, which is the evidence for the split.

**Citation.** [J 90.02.14] SYS)177. M4-14 states the split.

**Sibling, no sample site.** `CLOSE <file>` is `TSX SYS)176,4 / PZE FILENAME`,
2 words [J 90.02.14]. Manual-grounded, unattested here.

---

## 3. GET

### 3.1 The shape

```
TXH    CP)+a,0,CP)+b                    the statement stamp (§8)
TSX    IOC)8,4
PZE    <file>,,SYS)260
PZE    <atEndBlock>,,SYS)283
IOCTN* BL)<n>,,<lenWords(record)>
TRA    <join>                           emitted only when the block is non-empty
<the AT END block, E words>
<join>:  the next statement's first word
```

Operands in semantic terms:

| Word | Operand | Semantic fact |
|---|---|---|
| 1 | `CP)+a`, `CP)+b` | the two pool cells of §8 |
| 3 addr | the file name | the GET's file |
| 3 dec | `SYS)260` | fixed; the record-length-error handler |
| 4 addr | the AT END block's first word, or `SYS)265` when there is no AT END clause | |
| 4 dec | `SYS)283` when the file's environment has no ON ERROR option; otherwise the ON ERROR procedure | |
| 5 | `BL)n` of the record, `,,lenWords` | §0.5, §0.6 |

### 3.2 The three variants and the word count

```
words(GET) = 1 + 4 + (E > 0 ? 1 : 0) + E
```

| AT END form | E | total | grounding |
|---|---|---|---|
| `AT END DO <p>` | 3 | **9** | attested ×3 |
| `AT END GO TO <p>` | 1 | **7** | attested ×1 |
| absent | 0 | **5** | [J 90.02.29] SYS)265; **no sample site** |

E is the size of the out-of-line block placed immediately after the descriptor
word. The `TRA <join>` exists only to jump over that block, so it disappears
with it.

**`AT END DO p` block (3 words):**

```
AXT    *+3,7
SXA    <p>,4
TRA    <p>+1
```

This is the §5 plain-DO triple verbatim. Its `*+3` is the join word, so the
paragraph's return (§6) lands on the GET's resume point. Verified:
`AXT *+3,7` at 00205 assembles `0774 00 7 00210`, and 00210 is `GN)059`.

**`AT END GO TO p` block (1 word):** `TRA <p>`.

**No AT END clause:** word 4 becomes `PZE SYS)265,,SYS)283` and nothing follows
the descriptor. [J 90.02.29]: SYS)265 "appears as part of the GET calling
sequence … whenever the 'AT END' option is not used with the GET verb."

### 3.3 The resume label

The join is a generated name attached to the **first word after the block**. It
never owns a word. Three placements, all attested:

- The next statement's first word is otherwise unlabelled → the join prints in
  the label column of that word. LOC 00210 (`GN)059 CAL CP)+16`).
- That word already carries a name → the join prints as a label-only line above
  it (§0.2). LOC 00232, 00241.
- The next statement is a bare `GO TO` → the `TRA` folds onto the join word.
  LOC 00307, `GN)065 TRA COMPARE.EMPLOYEE.NUMBERS` (statement 195). This is
  M4-12's fold.

### 3.4 Generated-name consumption

Each GET burns **two consecutive** generated names, block first, join second:
058/059, 060/061, 062/063, 064/065. Both forms of AT END burn two.

### 3.5 Sites

| LOC | statement | form | words |
|---|---|---|---|
| 00177–00207 | 188 | `GET MASTER, AT END DO END.OF.MASTERS` | 9 |
| 00221–00231 | 190 | `GET MASTER, AT END DO END.OF.MASTERS` | 9 |
| 00232–00240 | 191 | `GET DETAIL, AT END GO TO END.OF.DETAILS` | 7 |
| 00276–00306 | 194 | `GET MASTER, AT END DO END.OF.MASTERS` | 9 |

Arithmetic: 0o207−0o177 = 8, +1 = 9. 0o231−0o221 = 8, +1 = 9.
0o240−0o232 = 6, +1 = 7. 0o306−0o276 = 8, +1 = 9.

### 3.6 The descriptor mnemonic — `IOCTN*`, not `IOCDN*`

The object listing prints `IOCTN*` at all four GET sites. Appendix 90.02 prints
`IOCDN*` seven times — five GET examples [J 90.02.03, 90.02.28, 90.02.29,
90.02.32, and the SYS)287 card-reader sequence] and two card-equipment FILE
examples [SYS)291, SYS)296]. The attested octal decides for `IOCTN*`: the word
assembles `5 00017 6 01667`, prefix 5, and the 709/7090 channel-command prefix
encoding puts IOCD at prefix 0 and the IOCT family at prefix 5
*(external: 7090 channel command prefix encoding)*. The companion FILE word
assembles prefix 7, consistent with the printed `IOST`.

**Emit `IOCTN*`.** Flag the 90.02 conversion's `IOCDN*` to the parent as a
divergence needing a page-scan check of PDF pp. 141, 167, 168, 171 and 172
before anything is amended. Do not amend a conversion here.

### 3.7 Not grounded

The ON ERROR variant. [J 90.02.32] says SYS)283 appears "whenever the 'ON ERROR'
option in not used in the Environment description of the file" (printed
"in not"). All six sample files omit ON ERROR, so what replaces SYS)283, and
whether an ON ERROR clause adds an in-line block of its own, is **unattested**.

---

## 4. FILE

### 4.1 Working-storage record — 3 words

**Trigger.** `FILE <record>` where `RecordInfo.located` is false.

```
TSX    IOC)9,4
PZE    <file>,,0
IOST   <record>,,<lenWords(record)>
```

**Words: 3. Constant.**

The decrement of word 2 is 0 for a tape file with no ON ERROR. [J 90.02.33]
shows `SYS)291` in that decrement for card equipment in locating mode; no
sample site. The 0 for tape is attested seven times and otherwise ungrounded —
**pinned at the diff**.

**Sites** (all 3 words):

| LOC | statement | clause |
|---|---|---|
| 00273–00275 | 193 | `FILE ERROROUT` |
| 00325–00327 | 196 | `FILE ERROROUT` |
| 00514–00516 | 199 | `FILE PAYRECORD` |
| 01151–01153 | 208 | `FILE CHECK` |
| 01154–01156 | 208 | `FILE PAYRECORD` |
| 01400–01402 | 222 | `FILE BONDORDER` |
| 01562–01564 | 228 | `FILE DEPARTMENT.TOTAL` |

### 4.2 Located record — 5 words

**Trigger.** `FILE <record>` where `RecordInfo.located` is true.

```
LXA    BL)<n>,4
SXA    GN)<a>,4
TSX    IOC)9,4
PZE    <file>,,0
GN)<a>:  IOST   <record>,,<lenWords(record)>
```

**Words: 5. Constant.**

The pair loads the record's base locator into IR4 and stores it into the
address field of the `IOST` word, so the write points at the buffer the GET
filled rather than at a fixed address. The generated name labels the `IOST`
word and is consumed by this shape alone (one name).

**Site.** LOC 01157–01163, statement 208, `FILE MASTER`. 0o1163−0o1157 = 4,
+1 = 5. The locator is BL)2, the same one `GET MASTER` fills at 00203.

**Citation.** M4-15 states this shape. The IOCS write entry is IOC)9
[J 90.02.08].

### 4.3 Combined formula

```
words(FILE) = 3 + (record.located ? 2 : 0)
```

---

## 5. DO

### 5.1 Plain DO — 3 words

**Trigger.** `DO <p>` with no FOR and no TIMES clause. Also the `AT END DO`
block of §3.2, which emits the identical triple.

```
AXT    *+3,7
SXA    <p>,4
TRA    <p>+1
```

**Words: 3. Constant.**

The `AXT`/`SXA` pair plants the return address `*+3` — the word after the
`TRA` — into the address field of `p`'s return cell (§6). `AXT` stores the
two's complement, `SXA` un-complements it, so the net is a constant store.
The `TRA` enters the procedure past its cell.

The tag is **7** on the `AXT` and **4** on the `SXA` at every plain-DO site.
Tag 7 loads IR1, IR2 and IR4 together on the 7090, which clobbers the two
index registers the buffer references use; the generated code reloads them
with `LAC BL)n,i` before every buffer reference, so nothing breaks. Why the
compiler wrote 7 rather than 4 is **pinned at the diff** — contrast the DO FOR
patch in §5.2, which writes tag 4 for the same job.

**Sites** (all 3 words):

| LOC | statement | target |
|---|---|---|
| 00370–00372 | 199 | DEPARTMENT.END |
| 00542–00544 | 200 | DEPARTMENT.END |
| 00650–00652 | 204 | FICA.ROUTINE |
| 00653–00655 | 204 | WITHOLDING.TAX.ROUTINE |
| 00666–00670 | 205 | BOND.ROUTINE |
| 00205–00207 | 188 | END.OF.MASTERS (inside the AT END block) |
| 00227–00231 | 190 | END.OF.MASTERS (inside the AT END block) |
| 00304–00306 | 194 | END.OF.MASTERS (inside the AT END block) |

Statement 204's two DOs at 00650–00655 give 6 words for two DOs, confirming 3.

**Citation.** M4-13.

### 5.2 DO FOR — 11 + 5·M words

**Trigger.** `DO <p> FOR <i> = <p0>(<q>)<r>`.

**M** = the number of positional indicators the loop index drives — one per
distinct subscripted array reference whose subscript is the loop index. In the
sample M = 1: PI)1 serves `TABLE.ITEM RATE (INDEX)` inside SEARCH.

```
                                            prologue, emitted once
AXT    GN)<a>,4                             a = the increment block
SXA    <p>,4                                patch p's return cell to it
CLA    CP)+<p0>                             the from-value
STO    <i>
CLA    GN)<c_k>            \  repeated
STO    PI)<k>              /  M times       initial pointer of each indicator
TRA    <p>+1                                enter the procedure body

GN)<a>:                                     the increment block
CLA    <i>
ADD    CP)+<q>
STO    <i>
CLA    CP)+<s_k>           \
ADD    PI)<k>               |  repeated M times
STO    PI)<k>              /
CLA    CP)+<r>                              the exit test
SUB    <i>
TPL    GN)<b>                               b EQU p+1, the back edge
```

**Word count:**

```
words(DO FOR) = 2 (patch) + 2 (index init) + 2·M + 1 (TRA)
              + 3 (index increment) + 3·M + 3 (exit test)
              = 11 + 5·M
```

M = 1 → 16. **Site: LOC 00702–00721, statement 206.**
0o721−0o702 = 15, +1 = 16. Verified twice.

Detail of the sample's operands, and what each is in semantic terms:

| Word | Printed | Value | Semantic fact |
|---|---|---|---|
| `CLA CP)+1` | 1 | the from-value p0 = 1 | pool cell holding p0 |
| `ADD CP)+1` | 1 | the step q = 1 | pool cell holding q |
| `CLA CP)+13` | 2 | the stride | **words per occurrence** of the subscripted table item |
| `CLA CP)+8` | 12 | the limit r = 12 | pool cell holding r |
| `CLA GN)088` | `PZE 2)RATE+0` | pointer to occurrence 1 | pool pointer word, reached through a generated name (§9) |

The stride of 2 is confirmed independently: `TABLE.ITEM` declares `12`
occurrences (statement 169) of RATE `IR99V999` (1 word) plus INSPREM `9V99`
and RETPREM `9V99` (3+3 chars = 1 word) = 2 words, and TABLE occupies
00135–00164 = 24 words = 12 × 2.

```
stride(indicator) = lenWords(one occurrence of the subscripted item)
```

Positional indicators are `PZE LOC,,BYTE` words with BYTE in the decrement, so
adding a small integer moves only the address field. A whole-word stride is
therefore the only case this shape can express. **A sub-word element stride is
unattested** — no sample instance, no manual text.

**The exit test is a magnitude test.** `CLA r / SUB i / TPL back-edge` forms
r − i and branches on sign: the loop runs while i ≤ r after the increment, a
+0 result (i = r) still transfers, and exit leaves i at the first value past r.
This is the D5.1 decode M4-13 pre-committed; the site is this one.

**The patch is once, before the loop.** `SXA <p>,4` executes only in the
prologue. The back edge re-enters `p+1` directly, so the return cell keeps
pointing at the increment block for the whole loop.

**Generated names consumed:** three — `GN)085` (EQU `SEARCH+1`, the back edge),
`GN)086` (the increment block), `GN)088` (EQU the pool pointer). `GN)084` and
`GN)087` never print anywhere in the listing; their allocation belongs to
M4-6, not here.

**Pinned at the diff, three items:**
1. Tag **4** on this shape's `AXT`, against tag 7 on the plain DO's.
2. The same address is written two ways in one block: `TRA SEARCH+1` at 00710
   prints the address literally, and `TPL GN)085` at 00721 prints the generated
   name EQU'd to it. Both assemble 01405.
3. The pool pointer is reached as `CLA GN)088`, not `CLA CP)+37`, while other
   relocatable pool words are reached directly (`LDI CP)+40`). See §9.

### 5.3 DO variants with no sample site

`DO … EXACTLY n TIMES`, multi-index DO, and USING/GIVING parameter passing are
described by M4-13 and have **no attested shape**. Their word counts are not
derivable from this listing. Do not present M4-13's descriptions of them as
attested.

---

## 6. Return cells and terminal returns

### 6.1 The return cell — 1 word

**Trigger.** A procedure (paragraph or section) that at least one DO names.
The DO may be a plain DO, an `AT END DO`, or a `DO … FOR`.

```
<p>:  AXT    0
```

One word, the **first** word of the procedure. The operand is a bare `0` with
no tag; it is a placeholder patched at run time by the caller's `SXA`.
Assembles `0774 00 0 00000`, CNTRL 10000 (no relocation).

**The decision is call-site-driven, not declaration-driven.** Attested in the
positive direction by END.OF.MASTERS, a plain unlabelled-section paragraph
that gets a cell because three `AT END DO`s name it. Attested in the negative
direction by END.OF.DETAILS (only `AT END GO TO` names it), END.OF.RUN and NET
(only GO TO reaches them) — none has a cell.

**Unattested:** a `BEGIN SECTION` that no DO names. All five sections in the
sample are DO'd, so the listing cannot say whether declaring a section alone
earns a cell. Do not claim it does or does not.

**Sites** (1 word each):

| LOC | procedure | statement | named by |
|---|---|---|---|
| 00331 | END.OF.MASTERS | 197 | AT END DO, statements 188, 190, 194 |
| 01165 | FICA.ROUTINE | 210 | DO, statement 204 |
| 01220 | WITHOLDING.TAX.ROUTINE | 214 | DO, statement 204 |
| 01262 | BOND.ROUTINE | 217 | DO, statement 205 |
| 01404 | SEARCH | 224 | DO FOR, statement 206 |
| 01473 | DEPARTMENT.END | 227 | DO, statements 199 and 200 |

LOC 01220's label is 22 characters and pushes `AXT 0` to a continuation line
(§0.2); the word is still one word at 01220.

### 6.2 The terminal return — 1 word

**Trigger.** The end of a procedure that has a return cell.

```
TRA*   <p>
```

One word, indirect through the cell. Assembles `0020 60 0 <cell>`.

**Its label** comes from one of three places:

| Source form | Label | Sites |
|---|---|---|
| `END <p>.` written with a paragraph label | that label | BOND.END (01403, statement 223); SEARCH.END (01472, statement 226) |
| `END <p>.` written with no label | the M3-23 generated name, which the **source** listing prints in the label position | GN)077 (01217, statement 213); GN)078 (01261, statement 216); GN)083 (01620, statement 229) |
| no `END` statement at all — a plain paragraph that a DO names | a generated name allocated by the code pass; it does **not** appear in the source listing | GN)067 (00350) |

The GN)067 case is the interesting one: END.OF.MASTERS is statement 197 alone,
and statement 198 opens a new paragraph. The compiler appended `TRA*
END.OF.MASTERS` at the paragraph's fall-through end, after the last word
statement 197 generated (00347), and named it.

**Exactly one such word per procedure with a cell.** Six cells, six `TRA*`
words. A `GO TO` inside the procedure may leave without returning (00341,
`TRA END.OF.RUN`); that costs nothing extra.

**Citation.** M4-13's "terminal END emits `TRA* P`."

---

## 7. STOP

### 7.1 STOP RUN — 6 words

**Trigger.** `STOP RUN`.

```
TSX    SYS)178,4
PZE    CP)+<a>,,CP)+<b>            statement number, sub-statement number, BCD
PZE    CP)+<c>,,CP)+<d>            " STOP " and " RUN  ", BCD
TSX    SYS)177,4                   the implicit close-all
PZE    IOC)1
TXI    IOC)40,0                    the end-of-job return point
```

**Words: 6. Constant.**

**Site.** LOC 00521–00526, statement 199. 0o526−0o521 = 5, +1 = 6.

No halt instruction is generated. `IOC)40` is "the end of job return point in
the CT Monitor communication area for all CT jobs" [J 90.02.09].

The four pool words, decoded from the sample's OCT lines:

| Cell | LOC | OCT | BCD |
|---|---|---|---|
| CP)+26 | 01726 | 606060011111 | `   199` |
| CP)+27 | 01727 | 730104606060 | `,14   ` |
| CP)+28 | 01730 | 606263464760 | ` STOP ` |
| CP)+29 | 01731 | 605164456060 | ` RUN  ` |

**Citation.** [J 90.02.14] SYS)178 ("The CP entries contain the Statement
Number of the Stop (in BCD), and the type of STOP"), [J 90.02.09] IOC)40,
[J 90.02.14] SYS)177. M4-14 / D2.7.

### 7.2 STOP n — 3 words, no sample site

M4-14 and D2.7 say `STOP n` emits the SYS)178 call with type NNN and neither
the close-all pair nor the monitor transfer, giving 3 words. **No sample site.**
Design-record-grounded, not attested. The manual's SYS)178 entry shows the
3-word calling sequence and does not say what follows it.

---

## 8. The statement stamp

### 8.1 The shape — 1 word

```
TXH    CP)+<a>,0,CP)+<b>
```

A tag-0 `TXH`. IR0 does not exist on the 7090, so a tag-0 transfer-on-index
test never transfers: the word is a no-op that carries two pool addresses.

The stamp is **part of the GET calling sequence and of SYS)178's parameter
list, and nowhere else**. No other verb in the sample emits one. Omitting it
would shift every following address, so it is not optional.

**Words: 1**, added to the GET count in §3.2. STOP RUN carries its pair as two
`PZE` fields rather than a `TXH` word.

### 8.2 The two pool cells

- `CP)+a` — the statement number, right-justified in six BCD characters,
  blank-filled: `   188`, `   190`, `   191`, `   194`, `   199`.
- `CP)+b` — a comma, then the two-digit sub-statement number, then three
  blanks: `,02   `, `,00   `, `,14   `.

Identical cells are shared. `CP)+19` = `,00   ` serves all three of statements
190, 191 and 194. Pool sizing must dedup.

Attested pairs:

| site | statement | CP)+a | CP)+b | decoded |
|---|---|---|---|---|
| 00177 | 188, the GET | +14 (01712) | +15 (01713) | `   188` / `,02   ` |
| 00221 | 190, the GET | +18 (01716) | +19 (01717) | `   190` / `,00   ` |
| 00232 | 191, the GET | +20 (01720) | +19 | `   191` / `,00   ` |
| 00276 | 194, the GET | +22 (01722) | +19 | `   194` / `,00   ` |
| 00522 | 199, the STOP | +26 (01726) | +27 (01727) | `   199` / `,14   ` |

### 8.3 The sub-statement number — fitted, not derived

[J 90.02.28] SYS)264 names the two quantities `STATEMENT-NUMBER` and
`SUB-STATEMENT-NUMBER` and defines neither. The listing gives five data points
and no third-party constraint, so what follows is **pinned at the diff**.

**The rule that fits all five sites:** MM is the 0-based ordinal of the clause
within its statement, where each target of a multi-target MOVE counts as its
own clause, and `OPEN ALL FILES` is not counted.

- Statement 188: MOVE ZEROS→INTERNAL.TOTALS (0), MOVE ZEROS→GRAND.TOTALS (1),
  GET (2) → `,02`.
- Statements 190, 191, 194: the GET is the only clause → `,00`.
- Statement 199: DO (0), MOVE CORRESPONDING (1), HOURS (2), INSURANCE (3),
  RETIREMENT (4), 'GT' (5), BLANKS→NAME (6), →EMPLOYEE (7), →MONTH (8),
  →DAY (9), →YEAR (10), BONDPURCHASES (11), FILE (12), CLOSE ALL FILES (13),
  STOP RUN (14) → `,14`.

**The competing rule, and why it was rejected.** "Count the commas that precede
the clause in the source text" fits statement 199 exactly (14 commas precede
STOP RUN) and the three `,00` sites, and gives 3 for statement 188's GET. It
survives only if statement 188's source has no comma after `INTERNAL.TOTALS`.
The page scan `comtran-manuals/J28-6169/images/page-195.png` was read: the
comma is present. The rule is rejected.

**The residual.** The fitted rule needs `OPEN ALL FILES` excluded and
`CLOSE ALL FILES` included, and the listing offers no second instance of either
to test that against. Two data points constrain a rule with three free
parameters. A generator can reproduce the sample from the table in §8.2
directly. **Do not present the fitted rule as derived.**

---

## 9. The EQU lines

Four `EQU` lines print in the procedure text. Each costs **zero words**, and
its LOC column prints **the equated value, not an address**, so the LOC column
jumps out of order across it.

| Printed between | Line | Equated value | LOC printed | First reference |
|---|---|---|---|---|
| 00701 and 00702 | `GN)088 EQU CP)+37` | CP)+37 = 01741 | 01741 | 00706 `CLA GN)088` |
| 00707 and 00710 | `GN)085 EQU SEARCH+1` | 01404+1 | 01405 | 00721 `TPL GN)085` |
| 01420 and 01421 | `GN)091 EQU CP)+38` | CP)+38 = 01742 | 01742 | 01424 `ADD GN)091` |
| 01420 and 01421 | `GN)093 EQU CP)+39` | CP)+39 = 01743 | 01743 | 01431 `ADD GN)093` |

Each equated value checks out: CP)+0 is 01674, so CP)+37 = 01741 = `PZE
2)RATE+0`, CP)+38 = 01742 = `PZE RETPREM-2`, CP)+39 = 01743 = `PZE INSPREM-2`;
SEARCH is 01404.

**Placement rule (pinned at the diff).** The `EQU` prints immediately before
the first word of the contiguous run of generated words that contains the
first reference to the name, in ascending name order when a run needs more than
one. This reproduces all four sites: GN)088 at the head of the DO FOR prologue
(00702), GN)085 at the head of the loop tail (00710, the `TRA` plus the
increment block), GN)091 and GN)093 at the head of the positional-indicator
recomputation block (01421).

**What is not grounded.** Why the run boundary falls before 00710 rather than
before 00711. And why these three pool pointers are referenced through a name
at all: `CLA GN)088` and `ADD GN)091` go through an EQU, while other
relocatable pool words are referenced directly (`LDI CP)+40`, whose cell 01744
is `PZE INTERNAL.TOTALS,,0`). Every EQU'd cell here is a pointer word used as
an **arithmetic** operand of a positional-indicator computation, and every
directly-referenced one is not — that correlation holds across the whole
listing but explains nothing. State it as a correlation, not a cause.

---

## 10. Sections

**`BEGIN SECTION` generates zero words.** It does two things:

1. It opens a new result-storage section number. Sections are numbered in
   source order of `BEGIN SECTION`, the main body being 0. Attested by the
   qualifiers: `RS)0` and `RS)1` in the main body, `1.RS)0` inside
   FICA.ROUTINE, `2.RS)0` inside WITHOLDING.TAX.ROUTINE, `3.RS)1` inside
   BOND.ROUTINE. SEARCH (4) and DEPARTMENT.END (5) use no result storage, so
   their numbers are inferred from the ordering, not attested.
   Citation: [J 90.02.03].
2. Its paragraph becomes a DO target like any other, and takes a return cell
   under §6.1 if a DO names it.

**`END <p>.` generates exactly one word**, the `TRA* <p>` of §6.2.

---

## 11. GO TO

**Trigger.** An unconditional `GO TO <p>` that is the whole content of a
clause.

```
TRA    <p>
```

**Words: 1. Constant.**

**Site named in the task:** LOC 01164, statement 209, `GO TO GET.MASTER`.
Others: 00220 (189), 00307 (195, folded onto the GET's join label — §3.3),
00330 (196), 00341 and 00360 (197, 198, inside IF), 00367 (198), 01317 (220),
01416 and 01471 (225).

**Citation.** M4-12.

The conditional and assigned forms belong to M4-11's WHEN machinery and to
M4-12's unattested `GO TO (p1,…,pn) ON index`; neither is sized here.

---

## 12. Summary table — every word count in this family

| Shape | Words | Grounding |
|---|---|---|
| OPEN ALL FILES | 2 | attested ×1, [J 90.02.14] |
| OPEN file | 2 | [J 90.02.13], no site |
| CLOSE ALL FILES | 2 | attested ×1, [J 90.02.14] |
| CLOSE file | 2 | [J 90.02.14], no site |
| GET, `AT END DO` | 9 | attested ×3 |
| GET, `AT END GO TO` | 7 | attested ×1 |
| GET, no AT END | 5 | [J 90.02.29], no site |
| FILE, working-storage record | 3 | attested ×7 |
| FILE, located record | 5 | attested ×1 |
| DO (plain, and the AT END DO block) | 3 | attested ×8 |
| DO FOR | 11 + 5·M | attested ×1 at M=1 → 16 |
| DO EXACTLY n TIMES / multi-index / USING-GIVING | unknown | no site, not derivable |
| return cell | 1 | attested ×6 |
| terminal `TRA* p` | 1 | attested ×6 |
| STOP RUN | 6 | attested ×1 |
| STOP n | 3 | M4-14 / D2.7, no site |
| statement stamp (inside GET) | 1 | attested ×4 |
| GO TO | 1 | attested ×10 |
| BEGIN SECTION | 0 | attested ×5 |
| `EQU`, `USE`, `ORG`, label-only line | 0 | attested |
| BL initialization block (`USE 2`) | 3 | attested ×1 |

---

## 13. Everything in this document that is pinned at the diff

Listed together so no reader mistakes one for a derivation.

1. The tag on the plain DO's `AXT` is 7; on the DO FOR patch's `AXT` it is 4.
   No text explains either choice or the difference.
2. `PZE <file>,,0` — the zero decrement of the FILE call for a tape file with
   no ON ERROR.
3. The sub-statement number MM (§8.3), fitted to two informative sites.
4. The placement of the `EQU` lines, and the use of a generated name rather
   than a direct `CP)+n` reference for the three positional-indicator pointer
   constants (§9).
5. `TRA SEARCH+1` and `TPL GN)085` naming the same address two ways inside one
   block.
6. The GET join label's three printing placements (§3.3) — the behaviour is
   attested, the listing rule behind it is M4-8's, not derived here.
7. One base locator per located record, shared across an input and an output
   file; BL numbering starting at BL)2. Two sites.
8. Section numbers 4 and 5 for SEARCH and DEPARTMENT.END, inferred from
   ordering with no result-storage reference to confirm them.

## 14. One item for the parent to route

Appendix 90.02 prints the GET buffer-descriptor mnemonic as `IOCDN*` in seven
places — five GET examples and two card-equipment FILE examples; the object
listing prints `IOCTN*` in all four of its GET sequences, and the attested
octal (prefix 5) supports the listing. This is a conversion-versus-conversion
divergence, and section 9 of CLAUDE.md puts the page scan above both. It needs
a scan check of PDF pp. 141, 167, 168, 171 and 172 before any amendment, and an
amendment to a conversion needs Jack's authorization. Nothing was changed here.
Generated code should emit `IOCTN*`.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02.03]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.08]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#ct-system-subroutines-and-communication-cells
[J 90.02.09]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.13]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.14]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.28]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.29]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.32]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.33]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
