# The constant pool `CP)` — generated-code specification

Family: the 62 pool entries at LOC 01674–01771 of the 90.05 object listing.
Scope: how the pool is sized, ordered, keyed, and printed. The *content* of a
descriptor word or a mask word is specified only as far as the pool needs it to
key and count entries; the shapes that consume them belong to other families.

Written to `/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/c3b08b06-7069-4268-8989-8c4ea6618e24/scratchpad/pool/spec.md`.

---

## 0. The ordering answer (asked for first)

**M4-4's claim is wrong as a global rule, and right as a within-group rule.**
The pool is ordered **by kind, and then by first need within a kind** — except
that the first kind is ordered by first appearance in the **source**, not by
first need in the generated stream.

The pool is four sub-pools, filled independently and concatenated in a fixed
order at layout time:

| Sub-pool | Indices | Count | What it holds | Order within |
|---|---|---|---|---|
| S1 literals | 0–13 | 14 | the values written in the PROCEDURE source, plus one subscript stride | source order (see below) |
| S2 machine words | 14–36 | 23 | masks, BCD statement stamps, BCD verb text, figurative fill, scale/round constants | first need in the generated stream |
| S3 subscript bases | 37–39 | 3 | `PZE symbol±offset`, no decrement | first need in the generated stream |
| S4 descriptors | 40–61 | 22 | `PZE symbol,,byte` | first need in the generated stream |

14 + 23 + 3 + 22 = 62.

### Evidence that the pool is not in first-need order

The very first generated statement (188) references `CP)+40`, `CP)+14` and
`CP)+15`, never `CP)+0`. Under first-need allocation the first constant used
would be `CP)+0`.

### Evidence that each of S2, S3, S4 *is* in first-need order

Reading the listing in **emission order** (the printed line order, which is not
LOC order — `EQU` lines and the `USE` excursions break LOC monotonicity), the
first reference to each entry falls in strictly ascending index order inside
each sub-pool. First-reference emission positions, as answer-key line numbers:

- S2: 14/15 (107), 16 (116), 17 (122), 18/19 (125), 20 (135), 21 (157),
  22 (173), 23 (201), 24 (261), 25 (285), 26/27 (322), 28/29 (323), 30 (329),
  31 (387), 32 (394), 33 (396), 34 (404), 35 (537), 36 (541). Strictly
  ascending.
- S3: 37 (435), 38 (774), 39 (775). Strictly ascending.
- S4: 40 (99), 41 (103), 42 (162), 43 (165), 44 (186), 45 (210), 46 (225),
  47 (290), 48 (294), 49 (298), 50 (302), 51 (306), 52 (362), 53 (367),
  54 (426), 55 (430), 56 (584), 57 (588), 58 (730), 59 (737), 60 (786),
  61 (801). Strictly ascending.

Merging any two of these three lists destroys the ordering (40 and 41 are
needed at lines 99 and 103, ahead of 14/15 at line 107), so the segregation is
real and is not an artifact of the sample's shape.

### Evidence that S1 is in source order, not first-need order

Two independent inversions, each a case where the generated stream needs one
constant before another but the pool holds them the other way round:

1. **Statement 215.** The source writes `SET WORKING WHT = 0.18 * (WORKING
   GROSS - 13 * MASTER EXEMPTIONS)`. `0.18` is written first and takes
   `CP)+11`; `13` is written second and takes `CP)+12`. The generated code
   evaluates the inner parenthesis first: `LDQ CP)+12` at 01221 precedes
   `MPY CP)+11` at 01232. Source order explains the indices; emission order
   inverts them.
2. **The stride.** `CP)+13` (octal `000000000002`, the TABLE.ITEM stride of two
   words) is first emitted at 00714 (line 447), ahead of `CP)+8` (the literal
   `12`) at 00717 (line 450). Under first need the stride would take the lower
   index. It takes the higher one, because it enters at statement 225's
   subscripted references (`INSPREM (POS)`, `RETPREM (POS)`), the last
   constant-bearing statement in the source.

Reconstruction of S1 from the source, in statement order, which reproduces
indices 2–13 exactly:

| Index | Word | Written as | Statement |
|---|---|---|---|
| 2 | 446060606060 | `'M'` | 193 |
| 3 | 246060606060 | `'D'` | 196 |
| 4 | 276360606060 | `'GT'` | 199 |
| 5 | 000000000620 | `40.0` | 203 |
| 6 | 000000000017 | `1.5` | 203 |
| 7 | 000000000024 | `-20` | 203 |
| 8 | 000000000014 | `12` | 206 |
| 9 | 000000000003 | `.03` | 211 |
| 10 | 000000034100 | `144.00` | 212 |
| 11 | 000000000022 | `0.18` | 215 |
| 12 | 000000000015 | `13` | 215 |
| 13 | 000000000002 | (stride, implied by `INSPREM (POS)` / `RETPREM (POS)`) | 225 |

The literals `0` (statement 205, `NOT EQUAL TO ZERO`, and statement 215,
`TR(WORKING WHT GT 0)`) and `1` (statement 206, `INDEX = 1(1)12`) are **not**
in that sequence. Source order alone would place them at indices 6 and 7,
between `-20` (statement 203) and `12` (statement 206). They sit at indices 0
and 1 instead, ahead of every source literal.

**Rule, pinned-at-the-diff:** the literal sub-pool is seeded with the integer 0
at index 0 and the integer 1 at index 1 before the source scan begins; a source
literal equal to 0 or 1 collapses onto the seed. One sample, two entries, no
manual text. A plausible reason exists (both are needed by machinery that no
source literal produces — `CP)+1` is the `TR` truth value at 01252, statement
215) but it is a reason, not evidence.

`ZEROS` and `BLANKS` (statements 188, 199, 201, 205, 220) are figurative
constants and produce **no** pool entry at all; they compile to `SYS)` fill
calls. `HIGH.VALUE` (statements 197, 198) does produce a word, but in S2, not
S1 (see §4.2.5).

---

## 1. The block

**Placement.** Location Counter 1, last of the four working blocks, after
`RS)`, `TS)`, `BL)`, `PI)` ([J 90.02.06]: "pooled together in a block of
storage immediately following the Positional Indicators"; block order and
origin arithmetic in M4-4). Sample: 01621 + 30 (`RS)`) + 7 (`TS)`) + 3 (`BL)`)
+ 3 (`PI)`) = 01674, and 01674 + 62 − 1 = 01771, the last word of the object
program.

**Print form.** One line per entry. The first entry carries the label `CP)`;
every later entry prints `+n` in the label column, `n` its index (the M4-8
offset counter, reset by the `CP)` label).

```
01674  000000000000      10000    CP)            OCT    000000000000
01675  000000000001      10000           +1      OCT    000000000001
...
01741  0 00000 0 00135   10001          +37      PZE    2)RATE+0
```

- S1 and S2 entries print `OCT` with twelve octal digits, and the object column
  prints the same twelve digits.
- S3 and S4 entries print `PZE` with a symbolic operand, and the object column
  prints the assembled word in prefix / decrement / tag / address fields.
- The flag column is `10000` for every `OCT` entry and for every `PZE` entry
  whose address field is a pure displacement; `10001` for every `PZE` entry
  whose address field is a program location. The correlation is exact over all
  25 `PZE` entries: `10000` on +43, +44, +45, +46, +52, +56 — precisely the six
  displacement words, the six consumed by `ACL` after `CAL BL)n` — and `10001`
  on the other nineteen, every one consumed by `LDI` or by an `EQU`.

**Word count.**

```
words(entry)  = 1                                  for every attested kind
|CP)|         = |S1| + |S2| + |S3| + |S4|          each = distinct keys entered
sample        = 14 + 23 + 3 + 22 = 62 words
```

No entry in the sample occupies more than one word. Nothing else's address
depends on `|CP)|`: the pool is the last block, so chunk B1 may size it last.

---

## 2. Indices are assigned in a layout pass, not during generation

`GN)088 EQU CP)+37` is emitted mid-stream, at answer-key line 435 — after the
label-only `GN)075` line at 00702 and before that location's `AXT GN)086,4`
word (statement 206; the out-of-order line is confirmed ink, M4-20(d)). At that
moment S2 held 21 of its 23 entries: `CP)+35` and `CP)+36` are first needed at
lines 537 and 541, more than a hundred words later. The printed index
37 = |S1| + |S2| = 14 + 23 was therefore **not computable** when that line was
allocated.

**Consequence for the generator.** Emit references as a `(sub-pool, key)`
handle. Resolve every `CP)+NN` number — and every `EQU CP)+NN` line, and the
pool's own LOC values — in a layout pass after generation ends and the four
sub-pools concatenate. A generator that assigns numbers as it goes reproduces
the sample only by luck.

Citation: derived from the listing. [J 90.02.03] fixes only the notation
("In the case of constants (CP references), the designation CP)+NN is used").

---

## 3. The keying rule

> Two constants collapse into one entry exactly when they land in the same
> sub-pool **and** their keys are equal, where the key of an `OCT` entry is its
> 36-bit word value and the key of a `PZE` entry is its printed symbolic
> operand — the qualifier, the name, and the offset or decrement — never the
> assembled bits.

Four attested discriminators:

1. **`OCT` keys on the word, not on the text as written.** Statement 205 writes
   `ZERO` and statement 215 writes `0`. Different source text, same word
   `000000000000`, **one** entry: `CP)+0`, referenced at 00656 and 01241. This
   refines M4-4's "one entry per distinct constant *as written*".
2. **`OCT` merges across statements.** `CP)+31` (`000000000144`, decimal 100)
   is shared by statements 203 (00623, 00646), 205 (00657), 211 (01173) and
   215 (01225, 01236, 01242). `CP)+19` (`730000606060`) is shared by the
   statement stamps of 190, 191 and 194.
3. **`PZE` does not merge on bits.** `CP)+38` (`PZE RETPREM-2`) and `CP)+39`
   (`PZE INSPREM-2`) both assemble to `0 00000 0 00134` — bit-identical, and
   two entries. The identity is confirmed ink, not a transcription artifact
   (M4-20(a), scan of PDF p. 216).
4. **`PZE` does not merge on bits, harder.** `CP)+43` through `CP)+46` all
   assemble to `0 00000 0 00000` — four identical all-zero words, four entries,
   because their operands are `1)DAT`, `DETAIL`, `1)EMPLOYEE.NUMBER` and
   `2)EMPLOYEE.NUMBER`.

**The sub-pool is part of the key.** No two entries in different sub-pools
share a word in the sample, so the pool never had to decide; a mask that
happened to equal a literal's word is untested. Keeping the sub-pool in the key
is what the layout requires, since a merged entry could not sit in two
sub-pools at once. Labelled: unattested, forced by the layout.

**A useful negative.** The four `10000`-flagged displacement words also show
that keying is not by *value*: `1)DAT` and `1)EMPLOYEE.NUMBER` are the same
displacement in the same record, and stay separate because the compiler wrote
two different names.

---

## 4. The shapes

Every shape below is one word. The "trigger" says which source construct mints
it; the "content" says what the word holds, in terms of `ItemSemantics` fields
(`fieldClass`, `shape`, `justification`, `storageChars`, `digits`,
`fractionDigits`, `quantity`, `startChar`, `word`, `byte`) and
`RecordInfo.located`.

### 4.1 S1 — literal words (indices 0–13, 14 words)

Entered during the source scan, in statement order, ahead of generation. Two
seeds precede them.

#### 4.1.1 Seeded integer (2 words, always)

- **Trigger:** none. Index 0 holds `000000000000`, index 1 holds
  `000000000001`, in every program.
- **Content:** the integers 0 and 1 as full-word positive binary values.
- **Words:** 2.
- **Sites:** `CP)+0` at 00656 (statement 205) and 01241 (215); `CP)+1` at 00704
  and 00712 (206) and 01252 (215).
- **Citation:** none. **Pinned-at-the-diff.**

#### 4.1.2 Numeric literal

- **Trigger:** a numeric literal written in a PROCEDURE statement — a
  comparison operand, an arithmetic operand, a `DO ... FOR` initial / step /
  limit value. Selects this shape rather than the alphameric shape when the
  literal's `fieldClass` is numeric.
- **Content:** the literal's digits **as written with the decimal point
  removed**, as a positive binary integer in one 36-bit word. Formally
  `|value| × 10^fractionDigits(literal)`, where `fractionDigits` is the
  literal's own, not the target field's. Attested: `40.0`→`000000000620` (400),
  `1.5`→`000000000017` (15), `20`→`000000000024`, `12`→`000000000014`,
  `.03`→`000000000003`, `144.00`→`000000034100` (14400),
  `0.18`→`000000000022` (18), `13`→`000000000015`, `0`→zero, `1`→one.
- **Sign:** the pool word holds the magnitude; a written sign is realised by
  the opcode. Statement 203's `-20` gives `CP)+7 = 000000000024` (+20), and the
  subtraction is the instruction's job.
- **Scaling to the target:** not done in the pool. The generated code scales at
  run time (`LDQ CP)+7 / MPY CP)+31` at 00622–00623, statement 203). One
  literal word therefore serves targets of different `fractionDigits`.
- **Words:** 1 per distinct word value.
- **Sites:** +5 at 00613 (203); +6 at 00617 (203); +7 at 00622 (203); +8 at
  00717 (206); +9 at 01166 (211); +10 at 01203, 01210, 01215 (212); +11 at
  01232 (215); +12 at 01221 (215).
- **Citation:** [J 90.02.06] for the block; the literal classes AF / ID / FP
  are named in [J 90.02.09]. The digits-with-the-point-removed encoding is
  **derived from the diff**; the manual does not state it.

#### 4.1.3 Alphameric literal

- **Trigger:** a quoted literal written in a PROCEDURE statement whose
  `fieldClass` is alphameric — `MOVE 'M' TO ERRORTYPE`.
- **Content:** the literal's characters in BCD, **left-justified and padded
  with octal 60 (blank) to six characters**, independent of the target's
  `storageChars` or `justification`. `'M'`→`446060606060`,
  `'D'`→`246060606060`, `'GT'`→`276360606060`. The target's byte selection is
  done by the mask words of §4.2.4, not by the literal word.
- **Words:** 1. Attested only for one- and two-character literals. A literal of
  more than six characters is **unattested**: do not assume `ceil(chars/6)`.
- **Sites:** +2 at 00261 (193); +3 at 00323 (196); +4 at 00460 (199).
- **Citation:** [J 90.02.09] classes literals AF; the packing is derived from
  the diff.

#### 4.1.4 Subscript stride

- **Trigger:** a subscripted reference in the source, `TABLE.ITEM RATE (INDEX)`
  / `INSPREM (POS)` / `RETPREM (POS)`. One entry per distinct stride value.
- **Content:** the table element's length in words — for the sample's
  `TABLE.ITEM`, two, from `quantity` and the element's `storageChars`.
- **Words:** 1.
- **Sites:** `CP)+13` at 00714 (206, the `DO SEARCH FOR` pointer advance) and
  at 01422 and 01427 (225, `POS × stride`).
- **Citation:** none in [J 90.02]. That the stride lands in S1 with the
  literals, while the scale factors 100 / 500 / 1000 / 50 land in S2, rests on
  this single entry. **Pinned-at-the-diff** — it is the weakest seam in the
  sub-pool boundary, and a second listing would settle it.

### 4.2 S2 — machine words (indices 14–36, 23 words)

Minted during generation, first-need order. All print `OCT`.

#### 4.2.1 Statement stamp, word 1 — the statement number

- **Trigger:** a verb whose calling sequence carries a statement
  identification: `GET` (the `TXH CP)+a,0,CP)+b` word ahead of `TSX IOC)8,4`)
  and `STOP` (`PZE CP)+NN1,,CP)+NN2`, [J 90.02.14]).
- **Content:** the statement number in BCD, **right-justified in six
  characters, blank-filled** — `606060011010` is `'   188'`
  (60 60 60 01 10 10).
- **Words:** 1.
- **Sites:** +14 (188) at 00177; +18 (190) at 00221; +20 (191) at 00232;
  +22 (194) at 00276; +26 (199) at 00522.
- **Citation:** [J 90.02.14] for the `STOP` pair ("the CP entries contain the
  Statement Number of the Stop (in BCD)"). The `GET` stamp word is **not in
  [J 90.02.04]'s READ sequence** — that sequence is `TSX IOC)8,4 / PZE
  FILENAME,,SYS)260 / PZE END-OF-FILE,,ERROR / IOCDN* BL)n,,len` with no stamp.
  The `TXH` word ahead of it is pinned-at-the-diff (M4-15 territory).

#### 4.2.2 Statement stamp, word 2 — the clause digits

- **Trigger:** allocated together with word 1, taking the next index.
- **Content:** octal 73 (the character the listing prints as `,`), then two BCD
  digits, then three blanks. Attested words: `730002606060` for statement 188,
  `730000606060` for statements 190, 191 and 194, `730104606060` for
  statement 199 — digits `02`, `00`, `00`, `00`, `14`.
- **Words:** 1.
- **Sites:** +15 at 00177 (188); +19 at 00221, 00232, 00276 (190, 191, 194);
  +27 at 00522 (199).
- **Ungrounded, and deliberately not fitted.** The digits are plainly a clause
  ordinal within the statement, but no single counting rule reproduces both
  attested non-zero values. Counting comma-separated clauses gives `03` for
  statement 188 (attested `02`) and `14` for statement 199 (attested `14`);
  counting one clause per verb gives `02` for 188 (attested) and `10` for 199
  (attested `14`). **The rule is unrecovered.** Specify the two words as a
  pair, take the digits from whatever the clause counter yields, and diff. Do
  not invent a rule that returns 02 and 14 — this is the `TS) BSS 7` situation
  (M4-4, amended 2026-08-10), and a fitted rule would be worse than an honest
  gap.

#### 4.2.3 Verb text word

- **Trigger:** `STOP RUN` — the "type of STOP" operand of [J 90.02.14].
- **Content:** the verb text in BCD, six characters per word, one word per six
  characters. `606263464760` = `' STOP '`, `605164456060` = `' RUN  '`. Note
  the leading blank on both.
- **Words:** 2 for `STOP RUN`. `STOP NNN` is unattested.
- **Sites:** +28, +29 at 00523 (199).
- **Citation:** [J 90.02.14].

#### 4.2.4 Character mask

- **Trigger:** a character-level `MOVE` or comparison where the field does not
  fill its word — the clear/extract shape `CAL mask / ANS target / COM / ANA
  literal / ORS target` (00256–00262) and `CAL clear / ANS target / ... / ANA
  extract / ORS target` (00210–00217).
- **Content:** a 36-bit word built from the item's character span, six bits per
  character, from `byte` and `storageChars`. Two forms:
  - **clear mask** — zeros over the span, ones elsewhere;
  - **extract mask** — ones over the span, zeros elsewhere; the exact
    complement of the clear mask.
  Attested pairs: `(byte 3, 2 chars)` → clear `777777000077` (+16), extract
  `000000777700` (+17); `(byte 0, 2 chars)` → clear `000077777777` (+25),
  extract `777700000000` (+30); `(byte 1, 2 chars)` → clear `770000777777`
  (+35), extract `007777000000` (+36); `(byte 0, 1 char)` → clear
  `007777777777` (+21), extract **not allocated** — the generator produced it
  with `COM` from the mask already in the accumulator (00260, 00322).
- **Words:** 1 per distinct mask word actually emitted. A `(byte, storageChars)`
  pair costs 1 word if only one polarity is emitted and 2 if both are.
- **Sites:** +16 at 00210 (189), 00553 (201), 01013 (208); +17 at 00216 (189),
  00561 (201), 01017 (208); +21 at 00256 (193), 00320 (196); +25 at 00455
  (199), 01006 and 01026 (208); +30 at 00531 and 00536 (200); +35 at 01046 and
  01062 (208); +36 at 01052 and 01066 (208).
- **Citation:** [J 90.02.06] gives exactly this usage as its example
  (`CAL CP)+11 / ANA CP)+22`). The mask construction is derived from the diff.

#### 4.2.5 Figurative fill word

- **Trigger:** `HIGH.VALUE` as an operand (`SET M.EMP.NO = HIGH.VALUE`).
- **Content:** octal 74 in all six characters: `747474747474`.
- **Words:** 1.
- **Sites:** +23 at 00332 (197) and 00351 (198).
- **Citation:** [J 90.02.09] names the figurative-constant classes BL, ZE, HV,
  LV. The word 747474747474 for HV is derived from the diff. `BL` (blanks) and
  `ZE` (zeros) produce no pool entry in the sample; `LV` is unattested.

#### 4.2.6 Scale and round constant

- **Trigger:** decimal scaling in the arithmetic shapes — `MPY` / `DVP` to move
  between the literal's `fractionDigits` and the target's, and the `ACL half /
  LRS 35 / DVP scale` rounding tail (M4-13).
- **Content:** a power of ten, or half a power of ten, as a positive binary
  integer: `000000000144` = 100 (+31), `000000000764` = 500 (+32),
  `000000001750` = 1000 (+33), `000000000062` = 50 (+34),
  `000003641100` = 1 000 000 (+24). The pairing is (scale 10^k, half 10^k/2):
  100/50 and 1000/500.
- **Words:** 1 each.
- **Sites:** +24 at 00425 (199), 01114 and 01143 (208); +31 at 00623 and 00646
  (203), 00657 (205), 01173 (211), 01225, 01236 and 01242 (215); +32 at 00632
  (203); +33 at 00634 (203); +34 at 00644 (203), 01171 (211), 01234 (215).
- **Citation:** [J 90.02.16]–[90.02.19]'s upscale/downscale routines take
  `PZE CP)+NN`, "the constant located at CP)+NN", which grounds the kind. D4.1
  already pins +24 and +31 to +34 by index.

### 4.3 S3 — subscript base words (indices 37–39, 3 words)

- **Trigger:** a subscripted reference that needs a run-time base — the
  `DO ... FOR` table walk (statement 206) and each `name (POS)` lookup
  (statement 225). One entry per distinct base expression.
- **Content:** `PZE symbol±offset`, **with no decrement field**, where the
  offset makes the subscript arithmetic one-based:
  `PZE 2)RATE+0` (the walk starts at element 0 and pre-increments),
  `PZE RETPREM-2` and `PZE INSPREM-2` (address = base + POS × stride − stride).
  The offset is `−stride` for a one-based subscript, `+0` for a pointer the
  loop advances itself.
- **The word is byte-blind.** `RETPREM` occupies characters 3–5 of its word and
  `INSPREM` characters 0–2, and both base words print decrement zero — the byte
  selection lives in the generated lookup code (M4-20(a), confirmed on the page
  scan). This is why the two words are bit-identical and still two entries.
- **Words:** 1 each.
- **Sites and consumption:** every S3 entry is reached through an `EQU`, never
  named directly. `GN)088 EQU CP)+37` (emitted at line 435, statement 206),
  used by `CLA GN)088` at 00706. `GN)091 EQU CP)+38` and `GN)093 EQU CP)+39`
  (emitted at lines 774–775, statement 225), used by `ADD GN)091` at 01424 and
  `ADD GN)093` at 01431.
- **Citation:** none in [J 90.02] for the base word itself. M4-6 records the
  three `EQU` assignments. **That S3 sorts ahead of S4 is pinned-at-the-diff:**
  `CP)+37` is first needed at line 435 and `CP)+40` at line 99, so the two
  cannot be one first-need sequence, but only the printed order tells us which
  block comes first.

### 4.4 S4 — descriptor words (indices 40–61, 22 words)

One kind, two contents. The discriminator is `RecordInfo.located` of the item's
record, and it is the *consumer* that differs, not the print form.

- **Trigger:** any `MOVE`, `FILE` or `SET` operand that MOVPAK must be pointed
  at — every field that reaches `SYS)132` (source pointer) or `SYS)133` (target
  pointer). One entry per distinct operand as printed.
- **Content and consumer**, both from [J 90.02.11]:
  - **Working storage** (`RecordInfo.located == false`) — `PZE LOC,,BYTE`,
    `LOC` = `item.word` absolute, `BYTE` = `item.byte`. Consumed by
    `LDI CP)+NN / STI SYS)132|133`. Assembles relocatable, flag `10001`.
    16 entries: +40, +41, +42, +47, +48, +49, +50, +51, +53, +54, +55, +57,
    +58, +59, +60, +61.
  - **Located record** (`RecordInfo.located == true`) — `PZE
    WORD-DISPLACEMENT,,BYTE`, the displacement from the record base. Consumed
    by `CAL BL)n / ACL CP)+NN / SLW SYS)132|133`. Assembles absolute, flag
    `10000`. 6 entries: +43, +44, +45, +46, +52, +56.
- **Print form is identical for both.** `PZE 1)HOURS,,0` (displacement 2 in
  DETAIL, `0 00000 0 00002`, flag 10000) and `PZE INTERNAL.TOTALS,,0`
  (absolute 00113, `0 00000 0 00113`, flag 10001) differ only in the assembled
  address and the relocation flag. The generator must therefore carry the
  located flag on the entry, not infer it from the printed text.
- **Words:** 1 each.
- **Sites:** see the table in §5.
- **Citation:** [J 90.02.11] cases 1 and 2 verbatim; [J 90.02.14] repeats the
  displacement constant under SYS)179 case 2 (`MZE BL)NN,,CP)+NN`, "CP)+NN is a
  constant that is the displacement distance of the data item from the base").
  Case 3 (complex base locator, `ACL CP)+NN1 / PDX / TXL / ACL CP)+NN2` with a
  second constant `OCT 777772000000`) is documented but **unexercised** in the
  sample; the sample's two base locators are both simple.

---

## 5. The 62 entries

`Kind` codes: `SEED` seeded integer, `NUM` numeric literal, `ALF` alphameric
literal, `STR` subscript stride, `STM#` statement stamp word 1, `STM,` statement
stamp word 2, `TEXT` verb text, `MASKC` clear mask, `MASKX` extract mask, `HV`
figurative high value, `SCALE` scale/round constant, `BASE` subscript base,
`PTR` working-storage pointer, `DSPL` located-record displacement.

| # | LOC | Printed | Assembled | Kind | Value / meaning | Reference LOCs (statement) |
|---|---|---|---|---|---|---|
| 0 | 01674 | `OCT 000000000000` | 000000000000 | SEED | 0 | 00656 (205), 01241 (215) |
| 1 | 01675 | `OCT 000000000001` | 000000000001 | SEED | 1 | 00704 (206), 00712 (206), 01252 (215) |
| 2 | 01676 | `OCT 446060606060` | — | ALF | `'M'` | 00261 (193) |
| 3 | 01677 | `OCT 246060606060` | — | ALF | `'D'` | 00323 (196) |
| 4 | 01700 | `OCT 276360606060` | — | ALF | `'GT'` | 00460 (199) |
| 5 | 01701 | `OCT 000000000620` | — | NUM | 400 ← `40.0` | 00613 (203) |
| 6 | 01702 | `OCT 000000000017` | — | NUM | 15 ← `1.5` | 00617 (203) |
| 7 | 01703 | `OCT 000000000024` | — | NUM | 20 ← `-20` | 00622 (203) |
| 8 | 01704 | `OCT 000000000014` | — | NUM | 12 | 00717 (206) |
| 9 | 01705 | `OCT 000000000003` | — | NUM | 3 ← `.03` | 01166 (211) |
| 10 | 01706 | `OCT 000000034100` | — | NUM | 14400 ← `144.00` | 01203, 01210, 01215 (212) |
| 11 | 01707 | `OCT 000000000022` | — | NUM | 18 ← `0.18` | 01232 (215) |
| 12 | 01710 | `OCT 000000000015` | — | NUM | 13 | 01221 (215) |
| 13 | 01711 | `OCT 000000000002` | — | STR | table stride, 2 words | 00714 (206), 01422 (225), 01427 (225) |
| 14 | 01712 | `OCT 606060011010` | — | STM# | `'   188'` | 00177 (188) |
| 15 | 01713 | `OCT 730002606060` | — | STM, | `,02` | 00177 (188) |
| 16 | 01714 | `OCT 777777000077` | — | MASKC | clear chars 3–4 | 00210 (189), 00553 (201), 01013 (208) |
| 17 | 01715 | `OCT 000000777700` | — | MASKX | extract chars 3–4 | 00216 (189), 00561 (201), 01017 (208) |
| 18 | 01716 | `OCT 606060011100` | — | STM# | `'   190'` | 00221 (190) |
| 19 | 01717 | `OCT 730000606060` | — | STM, | `,00` | 00221 (190), 00232 (191), 00276 (194) |
| 20 | 01720 | `OCT 606060011101` | — | STM# | `'   191'` | 00232 (191) |
| 21 | 01721 | `OCT 007777777777` | — | MASKC | clear char 0 | 00256 (193), 00320 (196) |
| 22 | 01722 | `OCT 606060011104` | — | STM# | `'   194'` | 00276 (194) |
| 23 | 01723 | `OCT 747474747474` | — | HV | HIGH.VALUE | 00332 (197), 00351 (198) |
| 24 | 01724 | `OCT 000003641100` | — | SCALE | 1 000 000 | 00425 (199), 01114 (208), 01143 (208) |
| 25 | 01725 | `OCT 000077777777` | — | MASKC | clear chars 0–1 | 00455 (199), 01006 (208), 01026 (208) |
| 26 | 01726 | `OCT 606060011111` | — | STM# | `'   199'` | 00522 (199) |
| 27 | 01727 | `OCT 730104606060` | — | STM, | `,14` | 00522 (199) |
| 28 | 01730 | `OCT 606263464760` | — | TEXT | `' STOP '` | 00523 (199) |
| 29 | 01731 | `OCT 605164456060` | — | TEXT | `' RUN  '` | 00523 (199) |
| 30 | 01732 | `OCT 777700000000` | — | MASKX | extract chars 0–1 | 00531 (200), 00536 (200) |
| 31 | 01733 | `OCT 000000000144` | — | SCALE | 100 | 00623, 00646 (203), 00657 (205), 01173 (211), 01225, 01236, 01242 (215) |
| 32 | 01734 | `OCT 000000000764` | — | SCALE | 500 | 00632 (203) |
| 33 | 01735 | `OCT 000000001750` | — | SCALE | 1000 | 00634 (203) |
| 34 | 01736 | `OCT 000000000062` | — | SCALE | 50 | 00644 (203), 01171 (211), 01234 (215) |
| 35 | 01737 | `OCT 770000777777` | — | MASKC | clear chars 1–2 | 01046 (208), 01062 (208) |
| 36 | 01740 | `OCT 007777000000` | — | MASKX | extract chars 1–2 | 01052 (208), 01066 (208) |
| 37 | 01741 | `PZE 2)RATE+0` | 0 00000 0 00135 | BASE | table walk base | via `GN)088`: `CLA GN)088` 00706 (206) |
| 38 | 01742 | `PZE RETPREM-2` | 0 00000 0 00134 | BASE | `RETPREM (POS)` base | via `GN)091`: `ADD GN)091` 01424 (225) |
| 39 | 01743 | `PZE INSPREM-2` | 0 00000 0 00134 | BASE | `INSPREM (POS)` base | via `GN)093`: `ADD GN)093` 01431 (225) |
| 40 | 01744 | `PZE INTERNAL.TOTALS,,0` | 0 00000 0 00113 | PTR | | 00167 (188), 00547 (201) |
| 41 | 01745 | `PZE GRAND.TOTALS,,0` | 0 00000 0 00124 | PTR | | 00173 (188) |
| 42 | 01746 | `PZE INFO,,1` | 0 00001 0 00076 | PTR | | 00263 (193), 00310 (196) |
| 43 | 01747 | `PZE 1)DAT,,0` | 0 00000 0 00000 | DSPL | in MASTER | 00266 (193) |
| 44 | 01750 | `PZE DETAIL,,0` | 0 00000 0 00000 | DSPL | in DETAIL | 00313 (196) |
| 45 | 01751 | `PZE 1)EMPLOYEE.NUMBER,,0` | 0 00000 0 00000 | DSPL | in MASTER | 00343 (197) |
| 46 | 01752 | `PZE 2)EMPLOYEE.NUMBER,,0` | 0 00000 0 00000 | DSPL | in DETAIL | 00362 (198) |
| 47 | 01753 | `PZE 3)NAME,,2` | 0 00002 0 00021 | PTR | | 00462 (199), 01122 (208) |
| 48 | 01754 | `PZE 3)EMPLOYEE,,3` | 0 00003 0 00020 | PTR | | 00466 (199) |
| 49 | 01755 | `PZE 4)MONTH,,0` | 0 00000 0 00024 | PTR | | 00472 (199) |
| 50 | 01756 | `PZE 4)DAY,,3` | 0 00003 0 00024 | PTR | | 00476 (199) |
| 51 | 01757 | `PZE 4)YEAR,,0` | 0 00000 0 00025 | PTR | | 00502 (199) |
| 52 | 01760 | `PZE 1)HOURS,,0` | 0 00000 0 00002 | DSPL | in DETAIL | 00572 (202), 00602 (202) |
| 53 | 01761 | `PZE HRS,,5` | 0 00005 0 00025 | PTR | | 00577 (202) |
| 54 | 01762 | `PZE 2)BONDEDUCTION,,0` | 0 00000 0 00034 | PTR | | 00672 (205) |
| 55 | 01763 | `PZE 2)BONDENOMINATION,,1` | 0 00001 0 00042 | PTR | | 00676 (205), 01313 (220), 01366 (221) |
| 56 | 01764 | `PZE 1)NAME,,0` | 0 00000 0 00001 | DSPL | in MASTER | 01125 (208), 01134 (208), 01350 (221) |
| 57 | 01765 | `PZE 2)NAME,,5` | 0 00005 0 00007 | PTR | | 01131 (208) |
| 58 | 01766 | `PZE 4)NAME,,2` | 0 00002 0 00071 | PTR | | 01345 (221) |
| 59 | 01767 | `PZE 3)BONDENOMINATION,,0` | 0 00000 0 00074 | PTR | | 01354 (221), 01370 (221) |
| 60 | 01770 | `PZE INS.PREM,,3` | 0 00003 0 00035 | PTR | | 01433 (225) |
| 61 | 01771 | `PZE RET.PREM,,0` | 0 00000 0 00037 | PTR | | 01452 (225) |

Statement attribution comes from the label anchors in the object listing:
188 = 00165–00207, 189 = 00210–00220, 190 = 00221–00231, 191 = 00232–00240,
192 = 00241–00255, 193 = 00256–00275, 194 = 00276–00306, 195 = 00307,
196 = 00310–00330, 197 = 00331–00350, 198 = 00351–00367, 199 = 00370–00526,
200 = 00527–00546, 201 = 00547–00562, 202 = 00563–00612, 203 = 00613–00647,
204 = 00650–00655, 205 = 00656–00701, 206 = 00702–00721, 207–209 = 00722–01164,
211 = 01166–01201, 212 = 01202–01216, 215 = 01221–01260, 217–223 = 01262–01403,
225 = 01405–01471, 227–229 = 01473–01620.

The BCD codes used above, all read off attested words: 00–11 = digits 0–9,
24 = D, 27 = G, 44 = M, 45 = N, 46 = O, 47 = P, 51 = R, 60 = blank, 62 = S,
63 = T, 64 = U, 73 = the character printed as `,`.

---

## 6. M4-4's conformance checks

| Check | Verdict |
|---|---|
| statements 203 and 215 share the literal `CP)+31` | **Confirmed**, and understated: `CP)+31` is shared by statements 203 (00623, 00646), 205 (00657), 211 (01173) and 215 (01225, 01236, 01242) — four statements, seven sites. |
| the bit-identical pointer pair `CP)+38` / `CP)+39` stay separate entries | **Confirmed.** Both assemble `0 00000 0 00134`; two entries at 01742 and 01743. |
| the four zero-valued pointer words `CP)+43` to `CP)+46` stay separate entries | **Confirmed.** All four assemble `0 00000 0 00000`; four entries at 01747–01752. |

**Fourth check, to add.** Statement 205 writes `ZERO` and statement 215 writes
`0`; both use `CP)+0` (00656 and 01241). This is the check that separates
keying on the assembled word from keying on the text as written, and it is the
one that corrects M4-4's phrase "one entry per distinct constant *as written*".

**Fifth check, to add.** `CP)+8` (the literal 12, statement 206) has a *lower*
index than `CP)+13` (the stride, first referenced at 00714, three words earlier
than 00717). Any implementation that allocates the literal sub-pool in
first-need order fails this.

---

## 7. What is not grounded

Stated plainly, so no reader mistakes a fit for a derivation.

**Pinned-at-the-diff — the sample says so, nothing else does:**

1. The seeded head. Indices 0 and 1 hold the integers 0 and 1 ahead of every
   source literal. Source order alone would put them at 6 and 7.
2. The S1 / S2 boundary. The table stride (2) sits with the literals while the
   scale factors (100, 500, 1000, 50, 10^6) sit with the machine words. One
   entry carries this rule.
3. The concatenation order S1, S2, S3, S4. Each sub-pool's internal order is
   evidenced; the order *between* them is only the printed layout.
4. That the sub-pool is part of the key. No cross-sub-pool bit collision exists
   in the sample, so merging across sub-pools was never tested. The layout
   forces the rule.
5. The `GET` statement stamp itself. [J 90.02.04]'s READ sequence has no
   `TXH CP)+a,0,CP)+b` word; only [J 90.02.14]'s `STOP` pair is documented.

**Unrecovered — do not fit a rule:**

6. The clause digits in stamp word 2. Attested `02` (188), `00` (190, 191,
   194), `14` (199). Comma-counting reproduces 199 and not 188; verb-counting
   reproduces 188 and not 199. No tested rule reproduces both.

**Unattested — outside the sample's reach:**

7. An alphameric literal longer than six characters. Every attested literal is
   one or two characters and takes exactly one word. `ceil(chars/6)` is the
   natural extension and is a guess.
8. `STOP NNN` (only `STOP RUN` occurs), figurative `LOW.VALUE`, and
   [J 90.02.11] case 3's complex base locator with its second constant
   `OCT 777772000000`.
9. The 500-entry pool ceiling behind msg 172 (D9.7). The sample uses 62.
10. Whether the pool is ever empty, and what the listing prints if it is.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.03]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.04]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.06]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.09]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.11]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.14]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.16]: ../../../../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
