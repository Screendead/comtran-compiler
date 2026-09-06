# Edited-field rendering: SYS)185, SYS)190, SYS)267

Design input for the M5 MOVPAK edited-target handlers. Read-only pass; no
repository file was changed. Every claim cites `file:line`, a LOC in the
90.05 listing, or a page scan. Inference is marked **(inference)**.

Sources used: `comtran-manuals/J28-6169/90.02-generated-code.md` (scan
`images/page-156.png`, `images/page-169.png`), the compiled sample
`comtran-manuals/J28-6169/90.05-sample-program.md`, the report output
`comtran-manuals/J28-6169/images/page-217.png`, the source mirror
`test/fixtures/90.05-payroll-job.ct`, the encoder
`lib/src/codegen/procedure.dart`, the pictorial measurement
`lib/src/data/pictorial.dart`, the object-code notes
`test/fixtures/90.05-object-code-notes.md`, and
`docs/comtran-language-definition.md`.

---

## 0. The attested inventory, and what it proves

### 0.1 Parameter definitions (scan-confirmed)

`images/page-156.png` (J 90.02.17) prints, letter for letter as transcribed
at `90.02-generated-code.md:822-849`:

- TARGET-EDIT-CONTROL, in the head word's **decrement**: `00001` asterisks,
  `00002` comma(s), `00004` decimal point, `00010` dollar sign, `00020`
  Blank When Zero. The digits are octal.
- TARGET-CONTROL-WORD: **Prefix** `= 0 if no target field commas; otherwise
  = number of digits to the left of first comma`; **Address** `= number of
  leading *'s, or 8's in pictorial`; **Decrement** `= number of 8's, 9's,
  *'s, to the left of the real or implied decimal point in target
  pictorial`; **Tag** `= TARGET-SIGN-CONVENTION`, 0 no sign, 1 overpunch
  minus, 2 overpunch plus, 3 right minus, 4 right plus, 5 left minus, 6
  left plus.

`images/page-169.png` (J 90.02.30) prints the SYS)267 sequence exactly as
transcribed at `90.02-generated-code.md:1657-1665`:
`TXI SYS)267,1,TARGET-EDIT-CONTROL` / `OCT TARGET-CONTROL-WORD-BITS` /
`AXT NUMBER-OF-DIGITS-TO-CONVERT,1`, with "the same form as described under
SYS)185". No glyph on either page is doubtful.

Word field layout of the `OCT` word, 12 octal digits over 36 bits: digit 1 =
prefix (bits 33-35), digits 2-6 = decrement (bits 18-32), digit 7 = tag
(bits 15-17), digits 8-12 = address (bits 0-14). The encoder builds it that
way at `lib/src/codegen/procedure.dart:2073-2082`:
`(digitsBeforeComma << 33) | (digitsBeforePoint << 18) | (_signCode(sign) << 15) | leadingProtected`.

### 0.2 The 25 SYS)267 sites

The listing holds **25** `SYS)267` call sites, not 26; the 26th `grep` hit is
the prose of the conversion note at `90.05-sample-program.md:1930`. The
count agrees with `test/fixtures/90.05-object-code-notes.md:547-553`, "The
25 edited-store sites".

Every site is the constant five-word call `TSX SYS)180,4` / `PZE T,,byte` /
`TXI SYS)267,1,editControl` / `OCT controlWord` / `AXT digits,1`
(`90.05-object-code-notes.md:543-545`).

| # | LOC | 90.05 line | Target | Pictorial (mirror line) | Edit ctrl | OCT control word | prefix/dec/tag/addr | AXT |
|---|---|---|---|---|---|---|---|---|
| 1 | 00376 | 963 | `2)GROSS` PAYRECORD | `88889.99` (:69) | 4 | 000005000004 | 0/5/0/4 | 7 |
| 2 | 00404 | 969 | `2)WHT` | `88889.99` (:71) | 4 | 000005000004 | 0/5/0/4 | 7 |
| 3 | 00412 | 975 | `2)FICA` | `8889.99` (:73) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 4 | 00420 | 981 | `2)BONDEDUCTION` | `8889.99` (:75) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 5 | 00430 | 989 | `1)NETPAY` (divide) | `8889.99` (:81) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 6 | 00436 | 995 | `HRS` | `8889.9` (:67) | 4 | 000004000003 | 0/4/0/3 | 5 |
| 7 | 00444 | 1013 | `INS.PREM` | `8889.99` (:77) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 8 | 00452 | 1019 | `RET.PREM` | `8889.99` (:79) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 9 | 00511 | 1050 | `2)BONDENOMINATION` | `88889.99` (:83) | 4 | 000005000004 | 0/5/0/4 | 7 |
| 10 | 01073 | 1369 | `2)GROSS` | `88889.99` | 4 | 000005000004 | 0/5/0/4 | 7 |
| 11 | 01101 | 1375 | `2)FICA` | `8889.99` | 4 | 000004000003 | 0/4/0/3 | 6 |
| 12 | 01107 | 1381 | `2)WHT` | `88889.99` | 4 | 000005000004 | 0/5/0/4 | 7 |
| 13 | 01117 | 1389 | `1)NETPAY` (divide) | `8889.99` | 4 | 000004000003 | 0/4/0/3 | 6 |
| 14 | 01146 | 1412 | `AMOUNT` CHECK (divide) | `$8889.99` (:65) | **12** (`00014`) | 000004000003 | 0/4/0/3 | 6 |
| 15 | 01276 | 1524 | `2)BONDEDUCTION` | `8889.99` | 4 | 000004000003 | 0/4/0/3 | 6 |
| 16 | 01327 | 1560 | `3)BONDENOMINATION` BONDORDER | `899V99` (:112) | **0** (`TRA` form) | 000003000001 | 0/3/0/1 | 5 |
| 17 | 01477 | 1689 | `2)HOURS` DEPARTMENT.TOTAL | `8889.9` (:88) | 4 | 000004000003 | 0/4/0/3 | 5 |
| 18 | 01505 | 1695 | `3)GROSS` | `88889.99` (:90) | 4 | 000005000004 | 0/5/0/4 | 7 |
| 19 | 01513 | 1701 | `3)WHT` | `88889.99` (:92) | 4 | 000005000004 | 0/5/0/4 | 7 |
| 20 | 01521 | 1707 | `3)FICA` | `8889.99` (:94) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 21 | 01527 | 1713 | `3)BONDEDUCTION` | `8889.99` (:96) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 22 | 01535 | 1719 | `2)INSURANCE` | `8889.99` (:98) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 23 | 01543 | 1725 | `2)RETIREMENT` | `8889.99` (:100) | 4 | 000004000003 | 0/4/0/3 | 6 |
| 24 | 01551 | 1731 | `2)NETPAY` | `88889.99` (:102) | 4 | 000005000004 | 0/5/0/4 | 7 |
| 25 | 01557 | 1737 | `1)BONDPURCHASES` | `88889.99` (:104) | 4 | 000005000004 | 0/5/0/4 | 7 |

Mirror line numbers are `test/fixtures/90.05-payroll-job.ct`. Sites 1-9 are
statement 199, 10-14 statement 208, 15 statement 219, 16 statement 221,
17-25 statement 228.

### 0.3 The three SYS)185 sites and the one SYS)190 site

| LOC | 90.05 lines | Target (pointer word) | Target pictorial | Source | Source pictorial | Ctrl | OCT | Steps | Terminator |
|---|---|---|---|---|---|---|---|---|---|
| 00605 | 1122-1126 | `HRS` via `CP)+53 = PZE HRS,,5` (:1856) | `8889.9` | DETAIL `1)HOURS` via `CP)+52 = PZE 1)HOURS,,0` (:1855) | `99V9` (:36) | 4 | 000004000003 | `212,1,2` `193,1,3` | `225,1,5` |
| 01440 | 1646-1650 | `INS.PREM` via `CP)+60 = PZE INS.PREM,,3` (:1863) | `8889.99` | `PI)2` table element | `9V99` (:178) | 4 | 000004000003 | `212,1,3` `193,1,3` | `225,1,6` |
| 01457 | 1661-1665 | `RET.PREM` via `CP)+61 = PZE RET.PREM,,0` (:1864) | `8889.99` | `PI)3` table element | `9V99` (:179) | 4 | 000004000003 | `212,1,3` `193,1,3` | `225,1,6` |
| 01373 | 1596-1600 | PAYRECORD `2)BONDENOMINATION` via `CP)+55` (:1858) | `88889.99` | BONDORDER `3)BONDENOMINATION` via `CP)+59` (:1862) | `899V99` | 4 | 000005000004 | `214,1,2` `198,1,5` | `226,1,7` |

The pointer identities are attested, not inferred: the constant-pool words
are printed at `90.05-sample-program.md:1855-1864`. `SYS)133` is the target
pointer and `SYS)132` the source pointer — at LOC 01354-01357 the
edited-to-register convert `SYS)268` sets `SYS)132` only
(`90.05-sample-program.md:1581-1584`), and a register target needs no
target pointer.

### 0.4 What the control-word fields encode — proved from the sites

Read each field against the pictorial that the byte offsets pin (0.5):

- **Decrement = digit positions left of the real or implied point.**
  `8889.9` → 4; `88889.99` → 5; `899V99` → 3. Sites 6/17 and 1/2 separate
  the two values against the same address, and site 16 shows the *implied*
  point (`V`) counts exactly like a written one.
- **Address = the leading run of `8` or `*`.** `8889.9` → 3, `88889.99` →
  4, `899V99` → 1, `$8889.99` → 3. Site 16's `OCT 000003000001` is the
  proof that the address is the *leading* run and not the digit count: the
  pictorial has one 8 and four 9s.
- **Decrement and address are independent.** Site 6 (`8889.9`, dec 4, addr
  3, AXT 5) against site 3 (`8889.99`, dec 4, addr 3, AXT 6):
  `90.05-object-code-notes.md:559-562` records the same separation.
- **Prefix = 0 at all 29 sites**, because no pictorial in the program holds
  a comma. The comma bit `00002` is never set.
- **Tag = 0 at all 29 sites.** No target pictorial carries `+`, `-`, or an
  overpunch. Sign conventions 1-6 are **unattested**.
- **The edit control is octal.** LOC 01146 punches decrement `00014` and
  the assembler prints `TXI SYS)267,1,12`: dollar (`00010`) plus point
  (`00004`) (`90.05-object-code-notes.md:564-568`).
- **Edit control 0 is legal and changes the opcode.** Site 16 punches
  `0020 00 0 00413`, a `TRA`, where site 1 punches a `TXI` to the same
  address (`90.05-sample-program.md:1560`;
  `90.05-object-code-notes.md:570-573`). `899V99` sets no bit: `V` is not
  the `.` of bit `00004` (`lib/src/data/pictorial.dart:132-136`).
- **`AXT` = the target's digit positions** — 5, 6 and 7 across the sites,
  never a constant (`90.05-object-code-notes.md:557-562`).
- **The terminator's TARGET-NUMERIC-LENGTH = the target's digit
  positions** — 5, 6 and 7 at the four step-list sites, and always equal to
  (leading zeros inserted + characters moved + trailing zeros inserted).

### 0.5 The character-length proof (this settles section B's hardest question)

No parameter word carries the target's character length. It is derivable,
and the derivation is verified byte for byte against the record layouts,
because the `PZE T,,byte` word of each call names the target's (word, byte)
address and the byte offsets can only come out right if every field is
exactly as long as the derivation says.

Take `charLength = digits + (point ? 1 : 0) + commas + (dollar ? 1 : 0) +
(sign occupies a position ? 1 : 0)`. Walk PAYRECORD from
`test/fixtures/90.05-payroll-job.ct:51-83`, six characters to a word, byte
0 high-order:

| Field | Chars | Range | Word.byte | Attested `PZE` |
|---|---|---|---|---|
| `HRS` `8889.9` | 6 | 35-40 | 5.5 | `PZE HRS,,5` LOC 00435 |
| `GROSS` `88889.99` | 8 | 43-50 | 7.1 | `PZE 2)GROSS,,1` LOC 00375 |
| `WHT` | 8 | 53-60 | 8.5 | `PZE 2)WHT,,5` LOC 00403 |
| `FICA` `8889.99` | 7 | 63-69 | 10.3 | `PZE 2)FICA,,3` LOC 00411 |
| `BONDEDUCTION` | 7 | 72-78 | 12.0 | `PZE 2)BONDEDUCTION,,0` LOC 00417 |
| `INS.PREM` | 7 | 81-87 | 13.3 | `PZE INS.PREM,,3` LOC 00443 |
| `RET.PREM` | 7 | 90-96 | 15.0 | `PZE RET.PREM,,0` LOC 00451 |
| `NETPAY` `8889.99` | 7 | 100-106 | 16.4 | `PZE 1)NETPAY,,4` LOC 00427 |
| `BONDENOMINATION` | 8 | 109-116 | 18.1 | `PZE 2)BONDENOMINATION,,1` LOC 00510 |

117 characters, 20 words — and the write is `IOST PAYRECORD,,20`
(LOC 00516). DEPARTMENT.TOTAL (`:84-104`) repeats the exercise: `HOURS`
35-40 → `PZE 2)HOURS,,5` (LOC 01476), `GROSS` 43-50 → `,,1`, `WHT` 53-60 →
`,,5`, `FICA` 63-69 → `,,3`, `BONDEDUCTION` 72-78 → `,,0`, `INSURANCE`
81-87 → `,,3`, `RETIREMENT` 90-96 → `,,0`, `NETPAY` 99-106 → `,,3`,
`BONDPURCHASES` 109-116 → `,,1`, 117 characters, `IOST
DEPARTMENT.TOTAL,,20` (LOC 01564). CHECK `AMOUNT` `$8889.99` = 6 digits + 1
point + 1 dollar = 8 characters at 85-92 → word 14 byte 1 → `PZE
AMOUNT,,1` (LOC 01145). BONDORDER `BONDENOMINATION` `899V99` = 5 digits, no
point (the `V` reserves nothing) at 24-28 → `PZE 3)BONDENOMINATION,,0`
(LOC 01326), total 36 characters → `IOST BONDORDER,,6` (LOC 01402).

Four independent record geometries, 23 field placements, no exception. The
`V`/`.` distinction, the single `$` position and the digit count are all
confirmed by arithmetic that would break at the next field if any were
wrong.

### 0.6 The rendering oracle, `images/page-217.png`

Read directly. What is legible, and what it fixes:

- **CHECKFILE prints `$294.12`, `$364.16`, `$363.10`.** The target is
  `$8889.99`, 8 characters, 4 integer digit positions, and all three values
  have 3 integer digits. A **fixed** dollar would print `$␢294.12` — a gap
  between the sign and the digits. The scan shows no gap. **The dollar
  floats.** This is the one decisive rendering fact the page yields, and it
  matches F p. 80 exactly: the `$` floats when followed by `8`.
- **PAYFILE hours print `40.0`, `20.0`, `31.0`, `32.5`, `156.0`, `389.5`**
  into `8889.9`. Value 0040.0 → the two leading `8` positions blank, the
  third `8` prints `4`, the `9` prints `0`. Leading-zero suppression is
  confirmed, and it stops at the first significant digit.
- **Zero amounts print `0.00`, not blank**, into `8889.99` (three leading
  `8`, then a `9`). The `9` position always prints. No field in the sample
  carries BLANK WHEN ZERO, so the report cannot show that rule.
- **BONDORDERFILE prints `3750`** into `899V99` (value 37.50). One leading
  `8` blanked, no decimal point in the image, 5 characters. This is the
  edit-control-zero site 16 rendering.
- **BONDEDUCTION and BONDENOMINATION columns are blank on several detail
  lines.** That is `MOVE BLANKS TO PAYRECORD BONDEDUCTION, PAYRECORD
  BONDENOMINATION` (`test/fixtures/90.05-payroll-job.ct:245-246`) through
  the figurative-constant mover `SYS)243`, not the editor.
- **Not legible, because the program never produces them:** a comma, an
  asterisk fill, any sign character, any negative value, BLANK WHEN ZERO,
  an `S` position, a fixed dollar. The `- -` on the GT line is the
  PAYRECORD `DATE` group with blank month/day/year around its two `'-'`
  constants, not an edited field.

---

## A. The character model

One row per pictorial character, with what it contributes to the edited
image. Source: F p. 80's repertoire, quoted at
`docs/comtran-language-definition.md:1170-1186`; the J edited-field row of
the J 02.05.05 chart at `:1200`; the measurement code
`lib/src/data/pictorial.dart`.

| Char | Reserves | In the edited image | Reaches the handler as |
|---|---|---|---|
| `9` | 1 char | one digit; **always prints**, a leading zero included | counted in the decrement (if left of the point) and in the numeric length |
| `8` | 1 char | one digit; "replaced automatically by a blank whenever it is a non-significant zero" (F p. 80) | counted in the decrement; a **leading** run is the control word's address |
| `*` | 1 char | one digit; "replaced automatically by an asterisk whenever it is a non-significant zero" (F p. 80) | as `8`, and sets edit-control bit `00001` |
| `.` | 1 char | the point character, BCD 0o33; never suppressed | edit-control bit `00004`; splits digits at the decrement |
| `V` | **0** | nothing — the point is implied | not a bit; still splits digits at the decrement (site 16) |
| `,` | 1 char | the comma, BCD 0o73; "may be replaced by a blank, asterisk, or dollar sign, if the operation of a preceding 8 or * has resulted in the elimination of non-significant zeros to the left" (F p. 80) | edit-control bit `00002`; the control word's prefix locates the **first** comma only |
| `$` | 1 char | the dollar, BCD 0o53; fixed at the indicated position "provided it is not followed by the symbol 8. In the latter case, the dollar sign will 'float' — i.e., it will be placed immediately to the left of the first significant digit remaining" (F p. 80) | edit-control bit `00010`; float-or-fixed is recovered from the address field (B.3) |
| `+` | 1 char if written by itself, **0** as an overpunch | "Plus or minus sign, one of which will always be placed in the space reserved for it" (F p. 80) — so a sign character always prints | tag 2 (overpunch plus), 4 (right plus), 6 (left plus) |
| `-` | 1 char if written by itself, **0** as an overpunch | minus "when the value is negative; when the value is positive, the space will be left blank" (F p. 80) | tag 1 (overpunch minus), 3 (right minus), 5 (left minus) |
| `S` | **0** | a represented digit that occupies no character position (F p. 80: `999SSS` covers 000,000 to 999,000) | **nothing**. See F.3 — this is the one repertoire member the parameter set cannot express |
| `F`, `A`, `X` | — | not legal in an edited field (J 02.05.05 chart) | — |
| `(n)` | — | repetition only | — |
| trailing zone letter | 0 | an overpunched sign on the rightmost digit (`8̅ 9̅ 8⁺ 9⁺`, J 02.05.05 note 2) | tag 1 or 2 |

**There is no `Z`.** COBOL's zero-suppression character does not exist in
COMTRAN; `8` carries that job and `*` the check-protection job. The F p. 80
repertoire quoted at `docs/comtran-language-definition.md:1170-1186` is
complete, and `Pictorial.tryParse`
(`lib/src/data/pictorial.dart:316-330`) accepts exactly
`A X 9 8 * V S . , $ + - F`.

**BLANK WHEN ZERO** is not a pictorial character. It is a Description-field
clause (D3.2, `docs/design/decisions.md:560-566`) and it arrives as
edit-control bit `00020`: "the field is to be replaced with blanks when it
becomes zero" (J 02.05.07, quoted at
`docs/comtran-language-definition.md:1808`).

### A.1 The BCD codes to write

Reuse `lib/src/chars/char_code.dart`. Its glyph table (`:142-143`) is the
authority; do not restate it. `bcdFromGlyph` (`:153-161`) gives blank
`' '` = 0o60, `'.'` = 0o33, `','` = 0o73, `'$'` = 0o53, `'*'` = 0o54,
`'+'` = 0o20, `'-'` = 0o40, and digit `d` = `d`. Six characters to a word,
byte 0 in the high six bits — the packing `_bcdWord` uses at
`lib/src/codegen/procedure.dart:1213-1219`.

**Overpunch encoding.** A BCD code decomposes as `(zone << 4) | digit`
(`lib/src/chars/char_code.dart:115`), zone 1 = row 12 (plus), zone 2 = row
11 (minus). Digits 1-9 overpunched are therefore `0o21`-`0o31` (A-I,
plus) and `0o41`-`0o51` (J-R, minus). **Digit zero is the exception**:
`machineSpecialName` (`:163-172`) names 0o32 "plus zero" and 0o52 "minus
zero", the 12-0 and 11-0 punches, and the table holds no glyph for either.
So the rule is `zoneBits | (d == 0 ? 10 : d)`, with `zoneBits` 0o20 or
0o40. A bare `'+'` (0o20) and a bare `'-'` (0o40) are *not* overpunched
zeros. **(inference** from the code table; no manual states the overpunched
zero's code, and no site emits one.**)**

---

## B. The rendering algorithm

### B.1 What the renderer is given

At the moment of rendering — the terminator `SYS)225`/`SYS)226`, or the
`AXT` word of a `SYS)267` call — the handler holds:

| Name | Where from |
|---|---|
| `ptr` | the target pointer cell `SYS)133` (185/190) or the `PZE T,,byte` word of the call (267); a `PZE LOC,,BYTE` word — address = word, decrement = byte 0-5. Attested at `90.05-sample-program.md:1855-1864`. **It carries no length.** |
| `E` | the head word's decrement: bit 0o01 asterisk, 0o02 comma, 0o04 point, 0o10 dollar, 0o20 blank-when-zero |
| `p, I, T, P` | prefix, decrement, tag, address of the `OCT` word (0.1) |
| `N` | the terminator's TARGET-NUMERIC-LENGTH, or the `AXT` decrement |
| `digits[0..N-1]` | the digit string, high order first — built by the steps (185/190) or by binary-to-decimal conversion (267) |
| `sign` | `+` or `-`; see B.6 |

Derived once: `fraction = N - I` (digits right of the point).

### B.2 The character length is derived, not carried

```
commas     = (E & COMMA) != 0 ? (I - p) / 3 : 0
signCell   = T in {3,4,5,6} ? 1 : 0          // 1 and 2 are overpunches: no cell
charLength = N + commas + ((E & POINT)!=0 ? 1:0) + ((E & DOLLAR)!=0 ? 1:0) + signCell
```

Section 0.5 verifies this against 23 attested field placements in four
record geometries. Its only failure mode is an `S` position (F.3).

### B.3 The skeleton, then the suppression

```
render(ptr, E, p, I, T, P, N, digits, sign):
  fill  = (E & ASTERISK) != 0 ? '*' : ' '
  float = (E & DOLLAR) != 0 && (E & ASTERISK) == 0 && P > 0

  # 1. lay out the cells, left to right
  cells = []
  if T == 5 or T == 6: cells += [SIGN]
  if E & DOLLAR:       cells += [DOLLAR]
  for k in 0 .. I-1:
      if (E & COMMA) and k > 0 and k >= p and (k - p) % 3 == 0: cells += [COMMA]
      cells += [DIGIT k]
  if E & POINT:        cells += [POINT]
  for k in I .. N-1:   cells += [DIGIT k]
  if T == 3 or T == 4: cells += [SIGN]
  assert cells.length == charLength

  # 2. Blank When Zero wins outright (D3.2; J 02.05.07)
  if (E & BWZ) and every digits[k] == 0:
      store charLength blanks at ptr; return

  # 3. significance
  s = least k in 0 .. I-1 with digits[k] != 0     # null when the integer part is zero
  suppressed = min(P, s ?? I)                     # digit cells 0 .. suppressed-1 go away

  # 4. paint
  image = []
  for cell in cells:
      DIGIT k -> (k < suppressed) ? fill : glyph(digits[k])
      COMMA before DIGIT k -> (k <= suppressed) ? fill : ','
      POINT  -> '.'
      DOLLAR -> '$'
      SIGN   -> see B.6

  # 5. float the dollar
  if float and suppressed > 0:
      j = index of the last cell painted `fill` before the first printing cell
      image[j] = '$'; image[index of DOLLAR cell] = ' '

  # 6. the overpunch
  if T == 1 or T == 2: image[last DIGIT cell] = overpunch(digits[N-1], sign, T)

  store image at ptr, charLength characters
```

`suppressed = min(P, s ?? I)` is the whole zero-suppression rule. `P`
bounds it to the leading `8`/`*` run — a `9` beyond that run always prints
— and `s` stops it at the first significant digit. F p. 80's phrase is
"non-significant zero", so a zero to the *right* of a significant digit
prints; nothing in the sample separates the two readings, but F p. 81's
range table does: `88999` covers "000 to 99999", and the minimum image is
`␢␢000`, which only comes out if the three `9` positions print their zeros.

The point is never suppressed: F p. 81 gives `$888,888.99` the minimum
`$.00`. The fraction digits are never suppressed: `****.99` has minimum
`****.00`.

### B.4 Every attested rendering, reproduced

| Pictorial | Value | Cells | `suppressed` | Image | Oracle |
|---|---|---|---|---|---|
| `8889.9` | 0040.0 | 6 | min(3, 2) = 2 | `␢␢40.0` | page-217 PAYFILE hours |
| `8889.99` | 0000.00 | 7 | min(3, 4) = 3 | `␢␢␢0.00` | page-217 zero amounts |
| `88889.99` | 00037.50 | 8 | min(4, 3) = 3 | `␢␢␢37.50` | page-217 last column |
| `899V99` | 03750 | 5 | min(1, 1) = 1 | `␢3750` | page-217 BONDORDERFILE |
| `$8889.99` | 0294.12 | 8 | min(3, 1) = 1, float | `␢$294.12` | page-217 CHECKFILE |
| `88999` | 00000 | 5 | min(2, 5) = 2 | `␢␢000` | F p. 81 range table |
| `****.99` | 0000.00 | 7 | min(4, 4) = 4 | `****.00` | F p. 81 range table |
| `$888,888.99` | 000000.00 | 11 | min(6, 6) = 6, float | `␢␢␢␢␢␢␢$.00` | F p. 81 range table |

The last row is the strongest check available. It exercises the comma
rule, the float and the "all integer digits gone" case at once, and F p.
80's remark that a comma "may be replaced by a … dollar sign" is only
explicable by a floating `$` landing in a comma cell — which is exactly
what step 5 does for a value like 001234.45 in `$888,888.99`, giving
`␢␢$1,234.45`.

### B.5 How the digit string is built (SYS)185 and SYS)190)

The steps between the head and the terminator each append to the digit
string. Order is the emitted order, not the printed menu order — the menus
are "two or more of the following instructions"
(`90.02-generated-code.md:743`, `:805`) and both attested edited-target
sites put leading zeros before the move
(`test/fixtures/90.05-object-code-notes.md` via
`/private/tmp/.../s4-contracts-b1.md:219, :299`).

| Step | 185 | 190 | Effect |
|---|---|---|---|
| leading zeros to insert, `n` | 212 | 214 | append `n` zero digits |
| move, `n` | 193 | 194/198 | take `n` from the source (B.5.1, D) |
| trailing zeros to insert, `n` | 211 | 216 | append `n` zero digits |
| round current character | 220 | 222 | D4.1(e), `docs/design/decisions.md:648` — not emitted by any sample site |
| overflow test, bypass, scan-for-sign | 201/206/— | 204/208/218 | not emitted by any sample site |
| terminator, `N` | 225 | 226 | render and store |

Invariant at every attested site: leading + moved + trailing = `N`
(2+3=5, 3+3=6, 3+3=6, 2+5=7). Assert it; do not branch on it. `N` is
still needed, because `fraction = N - I` is the only way to place the
point, and because `SYS)267` supplies no steps at all.

**B.5.1 The source digit, and its sign.** For `SYS)185` the source is
external decimal: one BCD character per digit, "digits and leading blanks;
an overpunch with the rightmost digit", and "leading blanks … are treated
as leading zeros" (J 02.05.05 notes, quoted at
`docs/comtran-language-definition.md:1200, 1806`). Blank is 0o60 = zone 3,
digit 0, so taking the low four bits gives 0 and satisfies the note.
Anything else is D4.3's improper data condition: set `SYS)131`, take the
low four bits as the digit, ignore undocumented zone bits, and continue —
"do not raise a Dart exception and do not stop the run"
(`docs/design/decisions.md:671-680`).

The source sign is read **only** by a step that carries a note: `SYS)228`,
`232`, `236` for 185 and `SYS)230`, `234`, `238` for 190 examine the last
character processed, `SYS)202` the first, `SYS)218` scans
(`90.02-generated-code.md:815-819, :946-951, :937-938, :943`). The plain
move step `SYS)193`/`SYS)198` carries no note, so it reads no sign. The
sample emits only the plain steps and only target sign convention 0 — the
two facts fit: with no target sign there is nothing to carry, so the
compiler need not spend a sign-examining step. **(inference,** but the note
structure admits no other reading**)**. With target sign 1-6 and no
note-carrying step in the sequence, the value is positive.

### B.6 Sign conventions

Only convention 0 is attested (0.4). The rest follow F p. 80's two rules,
which the seven values partition exactly, and
`docs/comtran-language-definition.md:1819` already records that reading:

| Tag | Cell | Negative | Positive |
|---|---|---|---|
| 0 | none | — | — |
| 1 overpunch minus | none (rides the last digit) | 11-zone on `digits[N-1]` | plain digit |
| 2 overpunch plus | none | 11-zone | 12-zone |
| 3 right minus | one, after the fraction | `-` | blank |
| 4 right plus | one, after the fraction | `-` | `+` |
| 5 left minus | one, before everything | `-` | blank |
| 6 left plus | one, before everything | `-` | `+` |

The minus conventions blank on positive because F p. 80 says of `-`: "when
the value is positive, the space will be left blank". The plus conventions
always print because F p. 80 says of `+`: "one of which will always be
placed in the space reserved for it". **This is a design decision, not a
finding**: conventions 1-6 have no attested site, and the manual gives the
seven values names and nothing else. Record it as such.

Two placements the mapping does not settle, both listed in F: where a left
sign sits relative to a `$`, and what happens when an overpunch must ride a
digit position that suppression has blanked.

---

## C. SYS)267 — internal decimal in the AC-MQ

### C.1 What the register holds

`SYS)267` "converts from internal decimal in the AC-MQ to form an edited
field" (`90.02-generated-code.md:1665`, scan `page-169.png`). Internal
decimal is a **binary integer with a compile-time scale**: "Arithmetic
operations are performed only in the internal (binary) mode" (J 02.03.03,
`docs/comtran-language-definition.md`), and the scale lives in the
pictorial, not in the word. So the register holds an unscaled integer, and
the control word's decrement supplies the point position at render time.

The AC-MQ pair is **MQ high, AC low**. `SYS)166` states it outright: "On
entry to the routine, the high order part of the number is in the MQ and
the low order in the AC" (`90.02-generated-code.md:547`). D4.1(c) binds the
same layout (`docs/design/decisions.md:641`).

### C.2 The handler reads the AC only

Two independent arguments, and they agree:

1. **The stale MQ.** 22 of the 25 sites emit `CLA source / TSX SYS)180,4`
   with no divide (for example LOC 00373-00376). `CLA` writes the AC and
   leaves the MQ holding whatever the last multiply or divide left. A
   handler that read the pair would inject garbage.
2. **The split would be undone.** The three divide sites emit `CLA / LRS 35
   / DVP CP)+24` with `CP)+24 = 1,000,000` (`OCT 000003641100`,
   `90.05-sample-program.md:1827`). `LRS 35` moves the value into the MQ;
   `DVP` then leaves quotient in the MQ and remainder in the AC — the
   excess high-order digits in the MQ, the `t.digits` that fit in the AC.
   D4.1(c): "the digits that fit remain as the remainder in the AC, the
   excess becomes the quotient in the MQ … our runtime performs the split
   as described and takes no action on the excess quotient"
   (`docs/design/decisions.md:641`). Reading the pair would recover the
   untruncated value and defeat the split.

So: `magnitude = state.acMagnitude`, `negative = state.acSign == 1`
(`lib/src/emulator/machine_state.dart:34, :37`; the MQ is `:40`). `DVP` leaves the remainder with the dividend's sign
(`lib/src/emulator/cpu.dart:140-141`), so the AC sign is the value's sign
in both shapes.

`N` is 5, 6 or 7 at every site. A target of more than 10 digits is double
precision (J 02.05.06) and genuinely needs the pair; nothing attests it
(F.2).

### C.3 The digit string

```
digits = decimal(magnitude) left-padded with zeros to N
if magnitude has more than N decimal digits: drop from the left
```
Dropping from the left is the same discard the divide performs, and is what
F p. 42 describes for MOVE: alignment "may involve the dropping of leading
digits". D4.2 makes it silent: no test step, no `SYS)130`
(`docs/design/decisions.md:658-661`).

Then render exactly as B.3, with `sign` from the AC sign bit. `AXT`'s
decrement is `N`; the control word's decrement is `I`; `fraction = N - I`.

### C.4 Is the `AXT` a parameter or an executed instruction?

**The manual says executed.** `SYS)180`: "the specific MOVE instructions
beginning at 2,4 are executed" (`90.02-generated-code.md:706`);
`SYS)182`: "The specific Move instructions are executed beginning at 1,4"
(`:725`). The words after the `TSX` are real instructions on the real
machine: the `TXI SYS)nnn,1,count` adds its count into XR1 and transfers to
the routine, which is why every step word is tagged 1 and why `SYS)267`
ends with an `AXT …,1` that loads XR1 outright.

**It is program-invisible either way.** The only observable difference is
XR1's value on exit, and codegen drops its XR1 hold after every MOVPAK call
— `_movpakClears()` is `_registerHolds.remove(1)`
(`lib/src/codegen/procedure.dart:1045-1051`), called at
`:2008, :2031, :2145`. No generated word reads XR1 across a MOVPAK call.
XR2 and XR4 must survive, and no MOVPAK word writes them.

**Recommendation: read all three words through XR4 as parameters, and treat
XR1 as clobbered.** A high-level Dart handler under D0.3 has to read them
as data anyway. Resume at `(p + 1 - xr4) & 0x7FFF` for `p` parameter words
(M4-17), which for `SYS)267` under `SYS)180` is four words after the `TSX`:
`PZE`, `TXI`, `OCT`, `AXT`.

The `TRA`/`TXI` variation at LOC 01327 is consistent with the executed
reading and does not disturb this: `TXI Y,1,0` and `TRA Y` have identical
executed effect, so canonicalizing a zero-decrement `TXI` to a `TRA` is a
compiler's choice, and the emulated handler must read the **decrement** of
that word as the edit control regardless of its opcode — which is zero in
both forms.

---

## D. SYS)190 — edited to edited

### D.1 What an edited source looks like to the reader

The one attested source is BONDORDER `BONDENOMINATION` `899V99`
(`test/fixtures/90.05-payroll-job.ct:111-113`): five characters, five digit
positions, no insertion character, and an implied point. At run time it
holds `␢3750` — one blank from suppression, four digits (page-217
BONDORDERFILE). J 02.05.05 note 3 makes the blank a zero.

So the attested reader is: **five characters, five digits, blank = zero**.
Nothing more is exercised. `SYS)268` at LOC 01357-01361 reads the same
field the same way, `TXI SYS)269,1,5` / `TXI SYS)275,1,5`.

### D.2 How 214 / 198 / 226 read it

At LOC 01373-01377 (`90.05-sample-program.md:1596-1600`):

```
TXI SYS)190,1,4        target edit control: point
OCT 000005000004       prefix 0, decrement 5, tag 0, address 4   -> 88889.99
TXI SYS)214,1,2        two leading zeros                          -> targetInteger 5 - sourceInteger 3
TXI SYS)198,1,5        move five                                  -> the source's five digits
TXI SYS)226,1,7        target numeric length seven                -> 5 integer + 2 fraction
```

The digit string is `00` + `03750` = `0003750`, seven digits, five left of
the point. Render into `88889.99` with `P = 4`: `s = 3`, `suppressed =
min(4,3) = 3`, image `␢␢␢37.50`. The report's rightmost PAYFILE column
prints `37.50`. Confirmed end to end.

**The count is a digit count, not a character count, in the emitted code.**
The encoder punches `_txi(fromEdited ? 198 : 193, s.digits)`
(`lib/src/codegen/procedure.dart:2056`) — the source's *digit* positions.
The manual's word is NUMBER-OF-CHARACTERS-TO-MOVE
(`90.02-generated-code.md:936`). At the one attested site the two are the
same number, 5, so the site cannot separate them.

**Recommended reader**, correct under both readings for every reachable
case: walk the source from its pointer, take a character that is a digit or
a blank as a digit (blank = zero), skip `.` `,` `$` `*` `+` `-`, and stop
when `count` digits have been collected. For an all-digit-position source
this is exactly "move `count` characters".

**The hazard, recorded and not coded around:** a blank left by a suppressed
`8` and a blank left by a suppressed comma are the same character, and
`SYS)190`'s head describes only the **target** — no parameter word carries
the source's pictorial at all. A source that carries insertion characters
therefore cannot be read unambiguously by any rule available to the
handler. No sample site produces one. Under CLAUDE.md section 11 this is an
open item (F.1), not a branch.

---

## E. Rejected readings

**E.1 "The character length is the sum of the step counts."** Refuted
twice. At LOC 00605 the steps sum to 2 + 3 = 5 while the target `8889.9`
occupies 6 characters — the point is missing. And `SYS)267` emits no steps
at all, yet renders an 8-character `$8889.99` at LOC 01146. The step sum is
the *numeric* length, which the terminator repeats.

**E.2 "The pointer cell carries the length."** Refuted by the printed
words: `CP)+53` is `PZE HRS,,5`, `CP)+60` is `PZE INS.PREM,,3`
(`90.05-sample-program.md:1856, 1863`). A `PZE` pointer holds a word
address and a byte index and nothing else. So the length must be derived
(B.2), and section 0.5 shows the derivation is exact.

**E.3 "The control-word address is the digit count."** Refuted by site 16:
`899V99` has five digits and punches address 1. The address is the leading
`8`/`*` run, as the scan says.

**E.4 "The control-word decrement is the character count left of the
point."** Refuted by site 14: `$8889.99` punches decrement 4, and there are
five characters left of the point once the `$` is counted. The decrement
counts `8`, `9` and `*` only, as the scan says.

**E.5 "`V` sets the decimal-point bit."** Refuted by site 16: `899V99`
punches edit control 0 and the report prints `3750` with no point. Bit
`00004` is the *written* point. The measurement already separates them
(`lib/src/data/pictorial.dart:132-136`).

**E.6 "The dollar sign is fixed at the leading position."** Refuted by the
oracle: `$294.12` on page-217 has no gap between the `$` and the `2`, and
the target `$8889.99` has four integer digit positions for a three-digit
value. F p. 80 predicts the float, because the `$` is followed by `8`.

**E.7 "`8` blanks every zero in its run."** Refuted by F p. 81: `88999`
covers "000 to 99999", so the minimum image keeps three printed zeros.
Suppression stops at the first significant digit; F p. 80's word is
"non-significant".

**E.8 "The `9` positions suppress too."** Refuted by the same range, and by
page-217's `0.00` columns in `8889.99` targets.

**E.9 "`SYS)267`'s handler reads the AC-MQ pair as one 72-bit value."**
Refuted by the 22 no-divide sites, where `CLA` leaves the MQ stale
(C.2), and by D4.1(c), which requires the excess quotient to be discarded.

**E.10 "The `AXT`, `OCT` and `TXI` words are inert data."** The manual says
they are executed — `SYS)180` transfers to `2,4`, `SYS)182` to `1,4`
(`90.02-generated-code.md:706, :725`). The distinction is program-invisible
here because `_movpakClears()` drops the XR1 hold
(`lib/src/codegen/procedure.dart:1045-1051`), so the recommendation in C.4
stands on convenience, not on the manual.

**E.11 "The compiler's `TRA` at LOC 01327 selects a different routine."**
Refuted by the address field: `0020 00 0 00413` and `1 00004 1 00413` name
the same address 00413. `test/fixtures/90.05-object-code-notes.md:570-573`:
"The count does not change."

**E.12 "The overpunched zero is `zone | 0`."** Refuted by
`lib/src/chars/char_code.dart:163-172`, which names 0o32 "plus zero" and
0o52 "minus zero" — the 12-0 and 11-0 punches. `zone | 0` gives bare `+`
and `-`.

---

## F. Open items

Each is phrased as a decision an implementer must record. None is settled
by any unsealed source.

**F.1 An edited source that carries insertion characters.** `SYS)190`'s
calling sequence describes the target only; the source's pictorial reaches
the handler through nothing. A suppressed comma and a suppressed leading
`8` are the same blank character, so a character-classifying reader
miscounts. The sample's only edited source is all digit positions
(`899V99`). *Decide:* whether the move count is source characters or source
digits, and how the reader tells a suppressed comma from a suppressed
digit. The encoder currently punches digits
(`lib/src/codegen/procedure.dart:2056`). No unsealed evidence survives
(D0.9).

**F.2 An edited target of more than ten digits.** Double precision by J
02.05.06; `SYS)267` then genuinely needs both registers, MQ high and AC
low (`90.02-generated-code.md:547`). Every attested `AXT` is 5, 6 or 7.
*Decide:* the `N > 10` register reading, and whether the divide-based
digit split of D4.1(c) still applies. No unsealed evidence survives (D0.9).

**F.3 An `S` position in an edited target.** `S` reserves no storage
(F p. 80) but counts as a represented digit: `ItemSemantics.digits`
includes `S` fillers (`lib/src/data/data_map.dart:86-87`), and both
`_axt(t.digits, 1)` and the `225`/`226` terminator punch that number
(`lib/src/codegen/procedure.dart:2144, :2030`), while `storageChars`
excludes it (`lib/src/data/pictorial.dart:99-107`). B.2's derived character
length therefore exceeds the field for any edited target with `S`, and
`fractionDigits` goes negative for a trailing-`S` run
(`lib/src/data/pictorial.dart:250-261`). The J 02.05.05 chart admits `S` in
an edited field. No sample site has one. *Decide:* whether
TARGET-NUMERIC-LENGTH counts represented digits or character positions, and
what the renderer does with the difference. This is a compile-side and
run-side pair; it is not fixed here, and this pass changed no encoder line.

**F.4 A non-leading `8` or `*`.** The control word's address is the
*leading* run only, so `999.88` or `99*99` is invisible to the handler.
Every `8` run in the sample is leading. *Decide:* whether the compiler
rejects a non-leading suppression character, or renders it as `9`.

**F.5 Irregular comma grouping.** The prefix is three bits and names the
first comma only; every later comma must be assumed three digits on
(B.2). `99,99,99` has no encoding, and `99999999,99` cannot be written
because `_controlWord` refuses a prefix above 7
(`lib/src/codegen/procedure.dart:2075-2080`). *Decide:* whether grouping is
forced to three, and what diagnostic an irregular pictorial draws.

**F.6 Sign conventions 1 to 6.** Unattested (0.4). B.6's table is a design
decision built on F p. 80's `+`/`-` rules. *Decide:* it explicitly, and
with it the two placements F leaves open — a left sign next to a `$`, and
an overpunch on a digit position that suppression has blanked.

**F.7 The sign of a rendered zero.** J 02.04.07 says "For comparison
purposes zero is considered an unsigned number, even though computational
sequences generated by the compiler may produce negative or positive
zeros". That scopes comparison only. *Decide:* whether a minus zero prints
its sign under conventions 1-6, and whether BLANK WHEN ZERO tests the digit
string or the sign as well.

**F.8 BLANK WHEN ZERO's extent.** J 02.05.07 says "the field is to be
replaced with blanks", which reads as the whole character image, insertion
characters included. No site sets bit `00020`. *Decide:* it, and record
that the zero test is over the `N` digits.

**F.9 Where the edited image is built.** Whether the zero-insert and move
steps write the target directly or fill a work area that the terminator
stores is unstated; the stage-4 contracts pass recorded the same gap. Our
handler builds the digit string in Dart and writes the target once, at the
terminator. *Decide:* it as a runtime-only choice — it emits no code and
listing-diff cannot see it.

**F.10 Rounding inside an edited render.** `SYS)220`/`SYS)222` are entered
by a bare `TRA` with no count, and D4.1(d)-(e) already fix our emission
rule and the half-adjust internals (`docs/design/decisions.md:644-648`). No
sample site emits either. The renderer must accept a round step at the
rounding character position, which under D4.1(e) adjusts the retained
low-order digit and propagates the carry leftward through the digit string,
before B.3 runs.

---

## Summary for the implementer

One renderer serves all three entries. It takes `(E, p, I, T, P, N,
digits, sign)` and writes `charLength` BCD characters at the target
pointer. `SYS)185` and `SYS)190` build `digits` from their step list;
`SYS)267` builds it from the AC magnitude. The character length is derived
from the parameters and matches the declared field exactly, verified
against 23 attested placements. `suppressed = min(P, indexOfFirstNonZero ??
I)` is the whole suppression rule, and it reproduces every rendering the
manuals print — the report page, both F p. 81 range examples, and the
floating dollar.
