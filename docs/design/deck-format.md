# Card deck file formats — canon and mirror

*Status: **frozen at M1** (2026-08-03). Governed by decisions D0.5 and D0.6 in
`docs/design/decisions.md`. An amendment requires: a new format version byte,
regeneration of every canon file in the repository, and a dated entry in
`decisions.md`.*

This document defines the two file formats for card decks:

1. **Canon** (`.ctdeck`) — a binary punch-level card-image file. Canon files
   are the authoritative program sources. The compiler reads canon only.
2. **Mirror** (`.deck`) — a text rendering of a canon file. Mirrors are
   generated artifacts, committed for review, search, and diffs. No build step
   reads a mirror.

The `deckconv` tool converts between the two forms and checks that committed
mirrors are fresh (see §6).

## 1. Terms

- **Card** — one punched card: 80 **columns**, each with 12 **punch rows**.
- **Punch rows**, top to bottom on the physical card: `12`, `11`, `0`, `1`,
  `2`, … `9`. Rows 12 and 11 are the upper **zone** rows; row 0 serves as both
  a zone row and a digit row.
- **Card code** — the set of punched rows in one column, written as row names
  joined by hyphens in top-to-bottom order, e.g. `12-8-5`. A column with no
  punches is **blank**.
- **BCD readout** — the 6-bit character code that a column yields under the
  read rules of §4. The codes in this document are the 709/7090 **core
  storage** codes (external: 22-6528-4 p. 80), not the tape codes; the two
  differ only in the zone bits, by a fixed table (§4.4).

## 2. Canon format (`.ctdeck`)

A canon file is a header followed by zero or more fixed-size card records.

### 2.1 Header — 12 bytes

| Offset | Size | Content |
|---|---|---|
| 0 | 6 | Magic: the ASCII bytes `CTDECK` |
| 6 | 1 | Format version: `0x01` |
| 7 | 1 | Flags: `0x00` (reserved; readers must reject a nonzero value) |
| 8 | 4 | Card count, unsigned, big-endian |

The file length must equal exactly `12 + 120 × count` bytes. A reader must
reject any other length, a bad magic, or an unknown version.

### 2.2 Card record — 120 bytes

Each card stores 80 columns × 12 bits = 960 bits, **column-major**: column 1
first, column 80 last. Each column is a 12-bit value; bit 11 (most
significant) is row 12, bit 10 is row 11, bit 9 is row 0, then rows 1–9 down
to bit 0 (row 9).

Columns pack two-per-three-bytes, most significant bit first, with no padding:

```
byte 0:  column 1, rows 12 11 0 1 2 3 4 5
byte 1:  column 1, rows 6 7 8 9   column 2, rows 12 11 0 1
byte 2:  column 2, rows 2 3 4 5 6 7 8 9
...
```

80 columns fill the 120 bytes exactly. A blank card is 120 zero bytes.

### 2.3 What canon can hold

Any punch pattern is representable, deliberately (D0.5):

- **Source decks** — BCD columns per §4.
- **Object decks** — the 22-word columnar binary form of J 90.03: 24 words of
  36 bits in columns 1–72, three columns per word.
- **Illegal punch combinations** — patterns outside §4's read table, which
  the msg-134 lexer tests need.

Canon carries no metadata beyond the card count. Provenance notes live in a
sibling `*-notes.md` file.

## 3. Mirror format (`.deck`)

A mirror is UTF-8 text restricted to ASCII, LF line endings, one line per
card, in deck order. A mirror of an empty deck is an empty file. Every
non-empty mirror ends with a final LF.

Each line has one of two forms:

### 3.1 Glyph line

Used when **every** column of the card is either blank or the canonical card
code (§4) of one of the 48 source-set characters:

```
A–Z   0–9   blank   +  -  *  /  (  )  ,  .  $  =  '
```

The line gives the Set H glyph of columns 1–80 with **all trailing blanks
removed**. A blank card is an empty line. A glyph line never has trailing
spaces and is at most 80 characters long.

### 3.2 Punch line

Used for every other card. The line is `!` followed by one field per punched
column, in ascending column order, each field preceded by one space:

```
! <col>:<rows> <col>:<rows> ...
```

`<col>` is the column number (1–80, no leading zeros); `<rows>` is the card
code (§1), e.g. `! 1:12-11-0-1-2-3-4-5-6-7-8-9 72:9`. A card whose columns
punch only source-set characters never uses this form; a card with no punches
is always the empty line.

### 3.3 Round trip

- canon → mirror → canon reproduces the canon file byte for byte.
- mirror → canon → mirror reproduces any normal-form mirror byte for byte.
  Normal form is exactly what §3.1–3.2 emit; `deckconv` rejects text that is
  not normal form (trailing spaces, CR, glyphs outside §3.1, out-of-order or
  malformed punch fields).

The 90.05 mirror (`tests/90.05-payroll.deck`) predates this document and is
already in normal form: 293 glyph lines, columns 1–72, ASCII, no trailing
blanks.

## 4. Character code

### 4.1 Read rules (card code → BCD readout)

A column reads as zone bits + digit bits.

**Zone bits** (core storage): no zone punch → `00`; punch 12 → `01`; punch
11 → `10`; punch 0-as-zone → `11`. A blank column reads `110000` (blank is a
character). (External: 22-6528-4 p. 80 — numeric `00`, A–I `01`, J–R `10`,
S–Z `11`.)

**Digit bits**: no digit punch → `0000`; a single punch 1–9 → its binary
value; punch 0 as a digit (alone, or under zone 12 or 11) → `1010`; the
combinations 8-2 … 8-7 → `1010` … `1111` (the sum of the two punches).
(External: 22-6528-4 p. 80 — digits are "their exact values as binary
integers", zero is the `1010` code, altered to `000000` for the bare digit
zero; the 8-3/8-4 pairing for specials, p. 104.)

**One special translation**: `12-5-8` reads `011111` — the 705 group mark.
The 705 character chart puts the group mark at internal `1111`, and IBM's own
1401 note distinguishes this 705 code `12-5-8` from the 1401's `12-7-8`
(external: A22-6506-0 p. 8; 22-6642-0 front panel; A24-1403-5 p. 170 note 1).
COMTRAN's Commercial collating sequence is the 705's, so the 705 translation
governs (definition §8.5.8). Consequence, recorded as a design decision: the
arithmetic value `1101` under zone 12 (octal 35) has no card code, and
`12-7-8` is **not** a legal combination in this system.

**Legal combinations.** A column is BCD-readable when its punches are one
zone part (none, `12`, `11`, or `0`) plus one digit part (none, `0`, `1` …
`9`, `8-2` … `8-7`), with two provisos: `0-0` is impossible (one row cannot
punch twice), and `12-7-8` has **no** readout — its arithmetic value `1111`
under zone 12 is the group mark, whose only card code here is the 705's
`12-5-8` (`7-8`, `11-7-8`, and `0-7-8` keep the arithmetic rule; all three
are unattested rows in §4.3). Every other pattern — e.g. two digit punches
without an 8, or two zone punches — has no readout; a card containing such a
column is not BCD-readable (it is an object-deck or illegal-punch card).

Two collisions are inherent in the code and documented by IBM: `0` and `8-2`
both give digit value `1010`, and (under our 705 rule) nothing gives `1101`
under zone 12. The **canonical card code** column of §4.3 resolves every
collision one way for writing; reading accepts every legal combination.

### 4.2 Verification anchor

J 02.06.16's native 709/7090 collating sequence, scan-resolved in definition
§1.1, lists 51 characters. Sorting the §4.3 table by 6-bit code value
reproduces that list **exactly, character for character**. The 13 codes
absent from J's display are the 12 unattested rows below plus the group
mark, which J lists only in the Commercial sequence. This cross-check is the
evidence that binds the external code table to COMTRAN's manuals.

### 4.3 The 64 codes

Columns: octal code (core storage), canonical card code, Set H glyph (used by
mirrors and listings), alternate period print glyph where attested
(22-6528-4 p. 103 fig. 82 set A; J 02.06.16 Commercial display), and name.
"—" = none. Unattested rows carry no glyph and exist only so the table is
total; they are design-decision rows.

| Octal | Card code | Set H | Alt | Name / notes |
|---|---|---|---|---|
| 00 | `0` | `0` | — | digit zero (tape stores 12; core 00) |
| 01–11 | `1` … `9` | `1` … `9` | — | digits one through nine |
| 12 | `8-2` | — | — | unattested; the tape-zero code, unreachable from a BCD tape read |
| 13 | `8-3` | `=` | `#` | equal sign |
| 14 | `8-4` | `'` | `@` | quotation mark (the literal delimiter) |
| 15 | `8-5` | — | — | unattested |
| 16 | `8-6` | — | — | unattested |
| 17 | `8-7` | — | — | unattested; equals the tape mark on tape |
| 20 | `12` | `+` | `&` | plus sign |
| 21–31 | `12-1` … `12-9` | `A` … `I` | — | letters A through I |
| 32 | `12-0` | — | ⟨+0⟩ | plus zero (machine special) |
| 33 | `12-8-3` | `.` | — | period / decimal point |
| 34 | `12-8-4` | `)` | ⟨loz⟩ | right parenthesis; prints as the lozenge on 705-set chains |
| 35 | *(none)* | — | — | unattested; displaced by the 705 group-mark translation (§4.1) |
| 36 | `12-8-6` | — | — | unattested |
| 37 | `12-8-5` | — | ⟨gm⟩ | group mark (machine special; 705 card code) |
| 40 | `11` | `-` | — | minus sign |
| 41–51 | `11-1` … `11-9` | `J` … `R` | — | letters J through R |
| 52 | `11-0` | — | ⟨−0⟩ | minus zero (machine special) |
| 53 | `11-8-3` | `$` | — | dollar sign |
| 54 | `11-8-4` | `*` | — | multiplication sign |
| 55 | `11-8-5` | — | — | unattested |
| 56 | `11-8-6` | — | — | unattested |
| 57 | `11-8-7` | — | — | unattested |
| 60 | *(blank)* | blank | — | blank |
| 61 | `0-1` | `/` | — | division sign |
| 62–71 | `0-2` … `0-9` | `S` … `Z` | — | letters S through Z |
| 72 | `0-8-2` | — | ⟨rm⟩ | record mark (machine special) |
| 73 | `0-8-3` | `,` | — | comma |
| 74 | `0-8-4` | `(` | `%` | left parenthesis |
| 75 | `0-8-5` | — | — | unattested |
| 76 | `0-8-6` | — | — | unattested |
| 77 | `0-8-7` | — | — | unattested |

The five machine specials (octal 32, 37, 52, 72, and the lozenge reading of
34) occur in COMTRAN data and collating but have no Set H glyph; a source
card that punches one renders as a punch line (§3.2) in mirrors. Their card
codes are period-attested: plus zero `12-0`, minus zero `11-0`, record mark
`0-2-8`, group mark `12-5-8`, lozenge `12-4-8` (definition §8.5.8; external:
22-6642-0; A22-6506-0 p. 8; A24-1403-5 p. 170).

### 4.4 Core vs. tape zone bits

Tape BCD differs from core only in the zone bits: core `01` (12 zone) is
`11` on tape, and core `11` (0 zone) is `01` on tape; `00` and `10` are
unchanged. Bare zero is `001010` on tape and `000000` in core (external:
22-6528-4 p. 80). Tape-image formats are an M5 concern (D0.7); everything in
this document uses core codes.

## 5. Citations for §4

- 22-6528-4 (709/7090 reference, external): p. 80 — zone alteration table,
  digit values, zero, tape mark; p. 103 — figs. 82 (alternate type-wheel
  characters) and 83 (punched card code); p. 104 — 8-3/8-4 special pairing.
- F p. 12 — the twelve Set H source specials with card codes; the same-code,
  different-glyph note. All twelve agree with fig. 83.
- J 02.06.16 via definition §1.1 — both collating sequences; the §4.2 anchor.
- Definition §8.5.8 — the scan-resolved machine-special names and card codes,
  from A22-6506-0 p. 8, 22-6642-0, and A24-1403-5 p. 170.

## 6. Authority and workflow (D0.5)

- Canon files are authoritative. The compiler and every tool read canon only.
- Each canon file `X.ctdeck` has a committed mirror `X.deck`, generated by
  `deckconv`. A stale or hand-edited mirror fails CI (`deckconv check`).
- The pre-commit hook regenerates mirrors for staged canon files
  (`.githooks/`; enable with `git config core.hooksPath .githooks`).
- Local binary diffs: `.gitattributes` marks `*.ctdeck` with `diff=ctdeck`;
  configure `git config diff.ctdeck.textconv 'dart run comtran:deckconv to-text'`
  to see mirror text in `git diff` / `git log -p`.
- Sequencing, per D0.5: `tests/90.05-payroll.deck` was the working authority
  until this format froze. At M1 the canon `tests/90.05-payroll.ctdeck` is
  generated from it once, the round trip is verified, and the text file
  becomes the generated mirror from then on.
