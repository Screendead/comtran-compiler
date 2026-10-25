# test/fixtures/f-payroll-tapes/ — provenance and derivation notes

*Created 2026-10-25, M6 stage 2, chunk 2b. These are the two input tapes
of the applied 1960 payroll deck, `f-payroll-j.ctd`. They carry the
employees and the values of the 1962 sample's tapes, in the record
layouts of the 1960 program (M6-1 as amended). No manual prints a tape
for the 1960 program.*

## What the directory holds

| File | Unit | The deck's file | Content |
|---|---|---|---|
| `D1.tap` | `D1` | MASTER.FILE | 25 MASTER records, one 14-word block each |
| `C2.tap` | `C2` | DETAIL.FILE | 14 DETAIL records, one 14-word block each |

Both are SIMH `.tap` images in the M5-2 frame (`docs/design/m5-io.md`).
`tool/generate_f_tapes.dart` writes them. It takes the table of
`tool/sample_tapes_source.dart` and lays it out with
`tool/f_tapes_source.dart`. Do not edit the images by hand. The golden
test `test/f_tapes_test.dart` regenerates them and compares the bytes.

## The source of the values

Every value comes from the 1962 sample's table. The table, and the
derivation of each of its values from the report on PDF p. 217, are in
`test/fixtures/90.05-tapes-notes.md`. This file adds no employee and
changes no value. It states only how each value enters a 1960 field.

The employees, their order and the three unmatched details are the
sample's. Both files are in ascending employee-number order, as the
1960 program expects ([F p. 87]).

## The record layouts

The data division of `f-payroll-j.ct` declares both records. The
compiler's semantic dump of that deck gives the place of each field
(`comtranc --emit-semantics`, the ITEMS section). A record is a string
of characters with no word alignment. The column below is the
1-based character position in the record, `6 × word + byte + 1`.

Both files are `BCD` and declare `BLOCKSIZE 14`. Each record is 80
characters. Fourteen words hold 84 characters, so a block holds one
record and four more characters. The four are blank, as a card-to-tape
pass leaves them. That is the rule of the 1962 sample's DETAILFILE
blocks too.

No pictorial of either record carries an `S`, so no field holds a
sign, and no value of the table is negative. Each numeric field is
external decimal (mode E), one BCD digit to a character, with the
decimal point implied by the `V`. An amount of the table is in cents
and the rate in mills, so the digits of a value go into the field
unchanged.

### MASTER

| Columns | Field | Pictorial | Value | Source |
|---|---|---|---|---|
| 1 | ERRORCODE | `A` | blank | chosen |
| 2–3 | DEPARTMENT | `99` | first two digits of the number | table |
| 4–7 | EMPLOYEE | `9999` | last four digits of the number | table |
| 8–22 | NAME | `A(15)` | the name, left-justified, blank-filled | table |
| 23–27 | RATE | `99V999` | the rate in mills, five digits | table |
| 28–33 | DATE | `99` `99` `99` | blank | chosen |
| 34–35 | EXEMPTIONS | `99` | the exemptions | table |
| 36–42 | GROSS | `99999V99` | zero | chosen, as in 1962 |
| 43–47 | RETIREMENT | `999V99` | zero | chosen, as in 1962 |
| 48–52 | INSURANCE | `999V99` | zero | chosen, as in 1962 |
| 53–57 | FICA | `999V99` | FICA year to date, cents | table |
| 58–63 | WHT | `9999V99` | zero | chosen, as in 1962 |
| 64–67 | BONDEDUCTION | `99V99` | bond deduction, cents | table |
| 68–72 | BONDACCUMULATION | `999V99` | bond accumulation, cents | table |
| 73–77 | BONDENOMINATION | `999V99` | bond denomination, cents | table |
| 78–80 | (unnamed) | `AAA` | blank | chosen |

Every value fits its field. The longest name is 11 characters
(`CASPERIAN J`, `WICKIWICZ J`). The highest rate is 12000 mills, five
digits. The highest FICA, 14400, fits `999V99`. The highest deduction,
1700, fits `99V99`.

An unmatched master carries its number and its name. Every other
numeric field holds zero digits, as the table holds zero there.

### DETAIL

| Columns | Field | Pictorial | Value | Source |
|---|---|---|---|---|
| 1 | ERRORCODE | `A` | blank | chosen |
| 2–4 | HOURS | `99V9` | the hours, three digits, tenths implied | table |
| 5–6 | DEPARTMENT | `99` | first two digits of the number | table |
| 7–10 | EMPLOYEE | `9999` | last four digits of the number | table |
| 11–25 | NAME | `A(15)` | the matching master's name, or blank | inferred |
| 26–31 | MONTH, DAY, YEAR | `99` `99` `99` | `100661` | table |
| 32–33 | EXEMPTIONS | `99` | the matching master's, or zero | inferred |
| 34–40 | GROSS | `99999V99` | zero | chosen |
| 41–45 | RETIREMENT | `999V99` | zero | chosen |
| 46–50 | INSURANCE | `999V99` | zero | chosen |
| 51–55 | FICA | `999V99` | zero | chosen |
| 56–61 | WHT | `9999V99` | zero | chosen |
| 62–65 | BONDEDUCTION | `99V99` | the matching master's, or zero | inferred |
| 66–70 | BONDACCUMULATION | `999V99` | zero | chosen |
| 71–75 | BONDENOMINATION | `999V99` | zero | chosen |
| 76–80 | (unnamed) | `AAAAA` | blank | chosen |

The 1962 detail is three words: the number, the date and the hours.
The 1960 detail holds 13 more fields. The table holds no detail value
for them, so each one below is a decision (D0.4).

## The fields the table cannot supply

The source column of the two tables uses three words:

- **table**: the value is in the 1962 table.
- **inferred**: the value is in the 1962 table, but on the master. A
  manual statement puts it on the detail too.
- **chosen**: the table holds no value. The value is a decision.

### Inferred

The 1960 manual says what a detail record holds: "the number of hours
worked during the current pay period". It then says: "The records also
contain other data, such as employee name, department, information to
be used in performing withholding tax, FICA, bond deduction and other
computations" ([F p. 87]). So a detail carries the employee's name,
the exemptions and the bond deduction. A matched detail takes each of
the three from its master. An unmatched detail has no master, so it
takes blank and zeros.

The bond deduction is the one of the three that the program reads. The
net-pay sentence, statement 145,00, subtracts DETAIL
BONDEDUCTION. With the master's deduction on the detail, the net pay
subtracts the deduction that the sample's report prints.

### Chosen

| Field | Value | Why |
|---|---|---|
| ERRORCODE, both records | blank | The program moves `M` or `D` into it before it files a record in ERROR.FILE (statements 131,00 and 134,00). A blank is what a record carries before the program marks it. |
| MASTER DATE | blank | The 1962 table holds a blank, because statement 209 of the sample overwrites it. No statement of the 1960 program reads or writes it. Blanks in a numeric external field are leading zeros ([J 02.05.05], note 3). |
| MASTER GROSS, RETIREMENT, INSURANCE, WHT | zero | The 1962 table holds zero. The program adds into these four and never prints them. |
| DETAIL GROSS, RETIREMENT, INSURANCE | zero | The program adds into each one: GROSS at statement 142,00, INSURANCE and RETIREMENT in SEARCH. A nonzero start would enter the pay. M6-1 as amended names zero as the value that lets the gross-pay checks hold. |
| DETAIL FICA, WHT | zero | Each sentence sets the field in both of its arms (statements 152,00 and 156,00), so no tape value reaches the result. Zero keeps the period's fields alike. |
| DETAIL BONDACCUMULATION | zero | No statement reads it. The accumulation is the master's running balance, and the detail has no balance of its own. |
| DETAIL BONDENOMINATION | zero | See below. |
| The unnamed fillers | blank | No statement can name them. |
| The four characters after each record | blank | A card-to-tape pass leaves them blank. |

**DETAIL BONDENOMINATION prints.** The bond routine moves the bond it
orders into PAYRECORD BONDENOMINATION (statement 162,00). Later in the
same cycle, `MOVE CORRESPONDING DETAIL TO PAYRECORD` (statements 146,00
and 149,00) moves DETAIL BONDENOMINATION into the same field. The
second move wins. So the column prints the tape's value, not the bond
the routine ordered. Two values were possible:

- **Zero.** A detail carries the period's data, and no bond is bought
  until the program buys one. The column prints zero on every line.
  The sample prints 37.50 on WOO's line, so that line differs.
- **The master's denomination.** The column prints 18.75 on three
  lines where the sample prints nothing, and 37.50 on WOO's line.
  Four lines carry a denomination where the program bought one bond.

Zero is the choice. It puts no value on the tape that only the report
supplies, and it gives one difference instead of three. The difference
is the 1960 program's own (M6-1 cause 3).

## Zero digits, not blanks

Each numeric field the table leaves at zero holds the digit `0` in
every position. J permits blanks there: "Numeric external fields may
contain leading blanks which are treated as leading zeros"
([J 02.05.05], note 3). Digits keep the tapes independent of that rule
until the external-decimal fetch is built.

## The TABLE

The TABLE is in the data division, not on a tape. Its twelve items
carry the same values as the twelve items of the 1962 sample's TABLE.
Each 1960 item is 11 characters: RATE `99V999`, then INSURANCE.PREM
`9V99`, then RETIREMENT.PREM `9V99`. The six constants read, item by
item:

| Item | RATE | INSURANCE.PREM | RETIREMENT.PREM |
|---|---|---|---|
| 1 | 00999 | 080 | 060 |
| 2 | 01499 | 100 | 060 |
| 3 | 01999 | 120 | 090 |
| 4 | 02499 | 150 | 090 |
| 5 | 02999 | 150 | 120 |
| 6 | 03499 | 200 | 120 |
| 7 | 03999 | 200 | 150 |
| 8 | 04499 | 250 | 150 |
| 9 | 04999 | 300 | 180 |
| 10 | 06499 | 300 | 250 |
| 11 | 07999 | 300 | 350 |
| 12 | 99999 | 300 | 500 |

The MASTER RATE field and the TABLE.ITEM RATE field are both `99V999`.
The tape writes the rate in mills, the scale of both, so the rate
comparison of SEARCH needs no conversion. How the program addresses an
11-character item is M6-1 cause 1, and it is not a tape question.

## Using the tapes

The applied deck does not compile to the end yet: the generator stops
at the external-decimal store of statement 141,00. When it compiles,
copy the directory before a run, because the run writes its output
tapes beside the inputs:

```sh
cp -r test/fixtures/f-payroll-tapes /tmp/f-tapes
dart run comtran:comtranc test/fixtures/f-payroll-j.ctd --run --tapes=/tmp/f-tapes --list-tapes
```

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 87]: ../../comtran-manuals/F28-8043/a1-programming-example.md#appendix-1-programming-example
[J 02.05.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
