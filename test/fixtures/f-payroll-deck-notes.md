# test/fixtures/f-payroll.ct — provenance and reconstruction notes

*Created 2026-09-14. These are the two card decks of the 1960 sample payroll
program, F28-8043 Appendix 1. The 1962 processor never compiled this program.
Both decks are diagnostic corpora, not oracles (`docs/design/m6-acceptance.md`,
M6-6 and M6-7).*

## What these files are

| File | What it holds |
|---|---|
| `f-payroll.ctd` | The 1960 program, keyed as printed. 191 cards. |
| `f-payroll-j.ctd` | The same program with five divergences applied. 215 cards. |
| `f-payroll.ct`, `f-payroll-j.ct` | The generated text mirrors (decision D0.5). |

Card counts of `f-payroll.ctd`:

| Cards | Content |
|---|---|
| 1 | `*COMPILE LIST` control card |
| 2–82 | `*PROCEDURE` header + 80 procedure cards (serials 01001–04022) |
| 83–190 | `*DATA` header + 107 data description cards (serials 05001–10015) |
| 191 | `*FINISH` control card |

Card counts of `f-payroll-j.ctd`:

| Cards | Content |
|---|---|
| 1 | `*COMPILE LIST` control card |
| 2–119 | `*DATA` header + 117 data description cards |
| 120–131 | `*ENVIRONMENT` header + 11 environment cards |
| 132–214 | `*PROCEDURE` header + 82 procedure cards |
| 215 | `*FINISH` control card |

The `*COMPILE LIST` and `*FINISH` cards are reconstructions. The 1960 listing
prints neither, and a complete job needs both. M6-6 counts the 187 source
cards between them, so the two division headers of the verbatim deck stay
outside that count.

## Sources and method

- **Character content** comes from the machine listing at [F p. 101] to
  p. 104, PDF pages 106 to 109. The conversion is
  `comtran-manuals/F28-8043/a1-programming-example.md`.
- **Column layout** comes from the page scans
  `comtran-manuals/F28-8043/images/page-106.png` to `page-109.png`. Every
  column claim below is a scan measurement. The conversion's own indentation
  decides no column (CLAUDE.md section 9).
- The listing prints the card serial in its first column ([J 02.02.01]). It
  runs 01001 to 10015. **Serial 07006 does not appear.** The listing skips it
  between `NAME` of BONDORDER and the `CHECK` record header.

## Layout facts established from the scans

- **Columns 1 to 5 carry the card serial, and column 6 is blank.** The CTL box
  of the coding form is columns 1 to 3. It holds the page number times ten:
  `010` on page 1 (`page-096.png`) to `100` on page 10 (`page-105.png`). The
  SERIAL box is columns 4 to 6, and this program uses columns 4 and 5 for the
  line number. [F p. 37] says of the field: "The right-most space of this
  field, i.e., Column 6, is usually left blank or else made zero so that
  subsequent inserts can be numbered sequentially." [F p. 65] says of the same
  field: "Although these digits must be punched in each card, it is sufficient
  to write them once in the CTL box, instead of repeating them on each line."
  The listing's first column is the card sequence number ([J 02.02.01]). The
  187 source cards and the two division headers carry the serial the listing
  prints. `*COMPILE LIST` and `*FINISH` are ours, and they carry none.
- Data description fields: the level is right-justified in column 24; the type
  starts at column 25; the quantity field is columns 31 to 35; the
  justification code is column 37; the description starts at column 38
  ([F p. 65]).
- The program punches one quantity. `TABLE.ITEM` carries `12`, right-justified
  in the quantity field, so in columns 34 and 35.
- The program punches one continuation of a data name, serial 09008,
  `RETIREMENT.` and `PREM`. Its continuation mark measures at column 73 on the
  scan. The print drifts right at the page edge, so the deck punches the mark
  in column 72, which is the only column the language reads ([F p. 84]). The
  continuation card carries the picture `9999V99` from column 38, and columns
  23 to 37 of that card stay blank.
- Procedure text starts in one of these columns, measured per card:

  | Card | Text column |
  |---|---|
  | A named sentence | name at 7 |
  | The first line of an unnamed sentence | 15 |
  | A continuation line | 13 |
  | The `CALL` verb line | 13 |
  | A `CALL` operand line | 18 |
  | An `END` sentence | 13 |

- Word gaps inside a card body come from the conversion, not from the scan.
  Each carries one to three columns of uncertainty. No gap is significant to
  the compiler. The one exception is the `CALL` synonym column. All seven
  synonyms start at column 37, measured on `page-106.png`.
- The listing separates its statements with blank lines. The deck punches no
  card for a blank line.

## Readings confirmed on the scan

- The six `TABLE` constants, serials 10002 to 10007, read `'0099908006001499100060'`,
  `'0199912009002499150090'`, `'0299915012003499200120'`,
  `'0399920015004499250150'`, `'0499930018006499300250'` and
  `'0799930035099999300500'`. Each is 22 characters. The scan confirms every
  digit.
- Serial 08023, `PAYRECORD BONDENOMINATION`, reads `$88899.99-`. The scan
  confirms the third `8`, which separates this picture from the `$88889.99-`
  of serial 08022.

## Reconstruction decisions

1. **Column-72 continuation character is `X`** on serial 09008 and on the one
   continued FILE card of the applied deck. The processor replaces column 72
   with a blank in Data and Environment lines ([J 02.03.01], section 2.c), so
   no listing can show which character was punched. Any non-blank character is
   equivalent to the language. The 1962 deck punches `X`.
2. **The page head of each golden is fixed at `--date=06/01/60` and
   `--time=1.00`.** The 1960 listing prints no page head, so no date and no
   time survive. The compiler prints today's date by default, which no golden
   can hold. The two values are arbitrary. They claim nothing about when this
   program was compiled. F28-8043 is dated June 1960.

## The applied deck

`f-payroll-j.ctd` applies the five divergences of M6-7 and no other. Each is a
row of the language definition's section 9.8, and each is a change the 1962
front end demands. Everything else stays 1960.

### Item 1: an environment division, and J's division order

The applied deck orders its divisions `*DATA`, `*ENVIRONMENT`, `*PROCEDURE`
(D2.2). The verbatim deck orders them `*PROCEDURE`, `*DATA`.

Eleven new cards declare five files. Their columns come from
`90.05-payroll-job.ct`: the file name starts at column 7, `FILE` and `SPECIF`
start at column 25, and the option list starts at column 31 (J 02.06.01).
The option field ends at column 71.

| File | FILE options | SPECIF options |
|---|---|---|
| `MASTER.FILE` | `INPUT,BCD,TAPE,MASTER,BLOCKSIZE 14` | `MASTER.FILE, UNIT1 'D1',OPENW,CLOSER,LOW` |
| `DETAIL.FILE` | `INPUT,BCD,TAPE,DETAIL,BLOCKSIZE 14` | `DETAIL.FILE, UNIT1 'C2',OPENW,CLOSER,LOW` |
| `REPORT.FILE` | `OUTPUT,BCD,TAPE,PAYRECORD,BLOCKSIZE 20` | `REPORT.FILE, UNIT1 'D3',OPENW,CLOSER,LOW` |
| `CHECK.FILE` | `OUTPUT,BCD,TAPE,CHECK,BLOCKSIZE 5` | `CHECK.FILE, UNIT1 'D2',OPENW,CLOSER,LOW` |
| `ERROR.FILE` | `OUTPUT,BCD,TAPE,MASTER,DETAIL,BONDORDER,BLOCKSIZE 14` | `ERROR.FILE, UNIT1 'D4',OPENW,CLOSER,LOW` |

`ERROR.FILE` needs 52 columns of options and the field holds 41. The deck
splits it the way `PAYFILE` is split in the 1962 deck: the text
`OUTPUT,BCD,TAPE,MASTER,DETAIL,` fills the first card, an `X` stands in
column 72, and
`BONDORDER,BLOCKSIZE 14` starts in column 31 of the next card.

### Item 2: CALL old names qualified, synonyms dropped

Seven `CALL` cards become five. Their columns come from the 1962 deck's own
`CALL` sentence: `CALL` at column 13, each opening parenthesis at column 18,
and each synonym at column 45.

Every reference the dropped synonyms carried is written out in full. The
`DPT` synonym goes, because each of its uses qualifies a field through it.

### Item 3: `STOP RUN`

Serial 02011 reads `STOP 1234`. The applied deck reads `STOP RUN` (D2.7).

### Item 4: GRAND.TOTAL written out

Serial 09012 reads `GRAND.TOTAL 1COPY DEPARTMENT.TOTAL`. The applied deck
writes the entry out as a RECORD with `DEPARTMENT.TOTAL`'s nine entries, in
ten cards. The rule copies an entry "in its entirety" but for its name and its
level ([F p. 76]). The expanded header therefore keeps the type `RECORD` and
the justification code `L` of `DEPARTMENT.TOTAL`. It takes the level `1` of
the COPY card. The nine entries keep their text and their columns, the
`RETIREMENT.` and `PREM` continuation pair included.

The `L` changes no front-end output. The deck keeps it because the rule copies
the entry whole.

### Item 5: the bare REDEF card

Serial 10008 punches a level `1` before `REDEF`. The applied deck blanks
column 24 and writes nothing else, which is the form the 1962 deck writes.
`TABLE.ITEM` moves from level 2 to level 1 and keeps its quantity `12`. Its
three fields move from level 3 to level 2 (D3.4; D3.6).

### Every card that differs

The serial column names the verbatim card. A dash means the applied deck adds
a card that no verbatim card answers.

| Serial | Verbatim | Applied | Item |
|---|---|---|---|
| — | — | `*ENVIRONMENT` and eleven file cards | 1 |
| — | division order `*PROCEDURE`, `*DATA` | `*DATA`, `*ENVIRONMENT`, `*PROCEDURE` | 1 |
| 01002–01008 | seven `CALL` operand cards | five `CALL` operand cards | 2 |
| 01012–01014 | `DETAIL EMPLOYNO`, `MASTER EMPLOYNO` | `D.EMPLOYNO`, `M.EMPLOYNO` | 2 |
| 02004–02007 | `DETAIL EMPLOYNO`, `MASTER EMPLOYNO` | `D.EMPLOYNO`, `M.EMPLOYNO` | 2 |
| 02011 | `STOP 1234.` | `STOP RUN.` | 3 |
| 02016 | `MASTER BONDEDUCT` | `M.BONDEDUCT` | 2 |
| 02021 | `BONDEDUCT.` | `BONDEDUCTION.` | 2 |
| 03006–03010 | `PAYRECORD EMPLOYNO`, nine `DPT` references | `PAYRECORD EMPLOYEE.NUMBER`, nine `DEPARTMENT.TOTAL` references, re-flowed onto eight cards | 2 |
| 04008–04011 | `MASTER BONDEDUCT`, `MASTER BONDACCUM`, `MASTER BONDENOM` | `M.BONDEDUCT`, `M.BONDACCUM`, `M.BONDENOM` | 2 |
| 04013–04014 | `BONDORDER BONDENOM`, `DPT BONDPURCHASES`, `PAYRECORD BONDENOM` | full names, re-flowed onto three cards | 2 |
| 04019–04021 | `TABLE.ITEM INSPREM`, `TABLE.ITEM RETPREM` | `TABLE.ITEM INSURANCE.PREM`, `TABLE.ITEM RETIREMENT.PREM` | 2 |
| 09012 | `GRAND.TOTAL 1COPY DEPARTMENT.TOTAL` | `GRAND.TOTAL 1RECORD L` and nine entries in ten cards | 4 |
| 10008 | level `1` before `REDEF` | column 24 blank | 5 |
| 10009–10012 | `TABLE.ITEM` at level 2, fields at level 3 | level 1, fields at level 2 | 5 |

### How a substituted sentence was re-flowed

A longer name can push a card past column 72. Three sentences needed a
re-flow. Each keeps its own first card and its own indentation. The overflow
moves to the next card of the same sentence, word by word, and a new card at
column 13 takes what the last card cannot hold.

| Sentence | Verbatim cards | Applied cards |
|---|---|---|
| serial 03005 to 03010 | 6 | 9 |
| serial 04012 to 04014 | 3 | 4 |
| serial 04018 to 04021 | 4 | 4 |

Two renamed references straddle a card boundary and become one word. Serial
01013 ends `WHEN DETAIL` and serial 01014 opens `EMPLOYNO`; serial 04009 ends
`THAN MASTER` and serial 04010 opens `BONDACCUM`. In each the qualifier moves
down to the next card, and the pair becomes `D.EMPLOYNO` and `M.BONDACCUM`
there.

## Using the decks

Compile either deck with a fixed page head, or the listing will not match its
golden:

```sh
dart run comtran:comtranc test/fixtures/f-payroll.ctd --date=06/01/60 --time=1.00
dart run comtran:comtranc test/fixtures/f-payroll-j.ctd --date=06/01/60 --time=1.00
```

`test/goldens/f-payroll.listing` and `test/goldens/f-payroll-j.listing` hold
those two listings. `test/f_corpus_test.dart` compares each one byte for byte
and pins the refusal that the listing cannot carry.

The verbatim deck draws 55 messages of 12 kinds, and the generator then
refuses `a GET record on 0 input files (no sample instance)` at statement
3,00. The applied deck draws three messages, all severity 1, and the
generator refuses `FILE record IN file (no sample instance)` at statement
131,00. M6-6 and M6-7 hold the reading of both results.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 37]: ../../comtran-manuals/F28-8043/03-procedure-description.md#commands
[F p. 65]: ../../comtran-manuals/F28-8043/04-data-description.md#data-description-format
[F p. 76]: ../../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 84]: ../../comtran-manuals/F28-8043/04-data-description.md#quantities-specified-in-named-fields
[F p. 101]: ../../comtran-manuals/F28-8043/a1-programming-example.md#sample-payroll-program---machine-listing
[J 02.02.01]: ../../comtran-manuals/J28-6169/02-compiler.md#b-finish-card
[J 02.03.01]: ../../comtran-manuals/J28-6169/02-compiler.md#0202-compiler-output
