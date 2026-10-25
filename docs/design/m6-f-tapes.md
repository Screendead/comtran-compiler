# M6 stage 2, chunk 2b: the input tapes of the 1960 deck

*Created 2026-10-25. This record holds the tape decisions of chunk 2b.
It folds into M6-9 of `docs/design/m6-acceptance.md` later. Until then,
this file is the record of these decisions.*

## Charter

Chunk 2b ends with a run of the applied deck, `f-payroll-j.ctd`, over
two tapes. M6-1 as amended fixes the input: the sample's source table,
`tool/sample_tapes_source.dart`, written in the corpus's own layouts.
It also requires this chunk to state which tape values it chose. This
record states them.

## Decisions

- **F-T1. The tapes carry the sample's table, in the 1960 layouts.
  Decided under the section 12 standing rule; Jack can overturn it.**
  M6-1 as amended names the source and the layouts, so one course is
  open. The generator imports the sample's table and adds no value of
  its own to it. Each record is the 80 characters of the data
  division's MASTER or DETAIL entry. Each file is `BCD` with
  `BLOCKSIZE 14`, so a block holds one record and four blank
  characters. `test/fixtures/f-payroll-tapes-notes.md` gives the
  column, the pictorial and the source of every field.

  The rejected option is a second, independent table for the 1960
  program. It would let the two tapes drift apart, and the sample's
  report would then no longer be an oracle for the corpus.

- **F-T2. A detail carries the master's name, exemptions and bond
  deduction. Decided under the section 12 standing rule; Jack can
  overturn it.** The 1962 detail holds the number, the date and the
  hours. The 1960 detail declares 13 more fields. The 1960 manual says
  that the records "contain other data, such as employee name,
  department, information to be used in performing withholding tax,
  FICA, bond deduction and other computations" ([F p. 87]). The table
  holds those values on the master, so a matched detail takes them from
  its master. An unmatched detail takes blank and zeros.

  The program reads only the bond deduction of the three. The net-pay
  sentence, statement 145,00, subtracts DETAIL BONDEDUCTION. The
  rejected option, zero, would raise the net pay of four lines by the
  deduction that the sample's report prints.

- **F-T3. Every other numeric field the table cannot supply is zero,
  and every other character field is blank. Decided under the section
  12 standing rule; Jack can overturn it.** The fields are:

  | Record | Fields | Value |
  |---|---|---|
  | both | ERRORCODE, the unnamed filler, the four characters after the record | blank |
  | MASTER | DATE | blank, as in the 1962 table |
  | MASTER | GROSS, RETIREMENT, INSURANCE, WHT | zero, as in the 1962 table |
  | DETAIL | GROSS, RETIREMENT, INSURANCE, FICA, WHT | zero |
  | DETAIL | BONDACCUMULATION, BONDENOMINATION | zero |

  M6-1 as amended names zero in DETAIL GROSS, INSURANCE and RETIREMENT
  as the condition of the gross-pay checks, because the program adds
  into all three. DETAIL FICA and DETAIL WHT are set in both arms of
  their sentences, so their tape value reaches no result. A zero field
  holds the digit `0` in each position. J reads blanks there as leading
  zeros ([J 02.05.05], note 3), but digits keep the tapes independent
  of that rule.

- **F-T4. DETAIL BONDENOMINATION is zero, and the bond column differs
  on one line. Decided under the section 12 standing rule; Jack can
  overturn it.** The bond routine moves the ordered bond into PAYRECORD
  BONDENOMINATION (statement 162,00). Then `MOVE CORRESPONDING DETAIL
  TO PAYRECORD` (statements 146,00 and 149,00) moves DETAIL
  BONDENOMINATION into the same field, and the second move wins. So
  the column prints the tape value.

  | Option | What prints | Lines that differ from the sample |
  |---|---|---|
  | Zero (chosen) | zero on every line | 1: WOO prints zero, the sample 37.50 |
  | The master's denomination | 18.75 on three lines, 37.50 on WOO's | 3: SOBEK, REYNOLDS, WILLIAMS |
  | The bond the sample orders | 37.50 on WOO's line only | 0, but the check is empty |

  The third option takes the value from the report that the run must
  reproduce, so the check would test nothing. Zero puts no report value
  on a tape and gives one difference. The difference is the 1960
  program's own, a defect of M6-1 cause 3.

## A finding for the run

M6-1 as amended expects four columns to check by name: the employee
number, the name, the date and the hours. It also says that `MOVE
CORRESPONDING DETAIL TO PAYRECORD` is "the only writer" of the printed
bond deduction.

J sets the rule of correspondence: "All qualifiers must be present and
identical through the level of the name itself" ([J 02.04.04]). In
DETAIL, the employee number, the name, the date and the amounts sit
under the group `DATA`. PAYRECORD has no `DATA` group. So the semantic
dump of the applied deck (`comtranc --emit-semantics`, the
CORRESPONDING section) pairs two fields only, at statements 146,00 and
149,00:

- DETAIL HOURS to PAYRECORD HOURS;
- DETAIL BONDENOMINATION to PAYRECORD BONDENOMINATION.

Under that rule, no statement fills the employee number, the name,
the date, the gross pay, the withholding tax, the FICA deduction or
the bond deduction of an employee line from the detail record. Of the
PAYFILE columns that M6-1 expects to check on an employee line, the
hours alone get a writer. The totals lines are a separate case.
Statements 138,00 and 148,00 pair GROSS, WHT, FICA, BONDEDUCTION and
NETPAY of the two totals records with PAYRECORD, and statement 148,00
moves blanks into the employee number and the name. M6-1 expects no
total to check, and this finding does not change that. The same rule
pairs no field with CURRENT DEPARTMENT or PAYRECORD DEPARTMENT. The
department break of statement 148,00 therefore compares two fields
that no statement fills from a record.

The definition already settles the class. §8.5.4-l makes J's rule
authoritative. It reads the F sample's moves that match nothing as
"latent defects of 1960 code written against the looser definition".
§9.8 names `MOVE CORRESPONDING DETAIL TO PAYRECORD, CURRENT` among
them. The tapes do not change the finding: no tape value reaches a
field that no statement writes. The run below shows its effect.

## The generator

| File | Generator |
|---|---|
| `test/fixtures/f-payroll-tapes/D1.tap` and `C2.tap` | `dart run tool/generate_f_tapes.dart` |

The generated-files table of CLAUDE.md section 10 holds this row,
beside the sample's tapes.

The code:

- `tool/f_tapes_source.dart` lays the table out in the two records.
- `tool/generate_f_tapes.dart` writes the two images.
- `tool/sample_tapes_source.dart` now exports its word packer,
  `characterWord`, so that both generators pack characters one way.

The tests, in `test/f_tapes_test.dart`:

- the committed images equal the ones the generator writes;
- the tape reader reads 25 and 14 blocks of 14 words, each file to its
  file mark;
- the lister prints one line for each record, and a master, a matched
  detail and an unmatched detail carry their values in the columns
  above.

## The run

**Decided 2026-10-25: the run of the applied deck.** The run reaches
the end of the job. The comparison finds no new compiler defect. Every
difference has one of the causes below.

### The command and the result

```sh
cp -r test/fixtures/f-payroll-tapes <copy>
dart run comtran:comtranc test/fixtures/f-payroll-j.ctd --run \
  --tapes=<copy> --list-tapes
```

The run prints `AT 139,00 STOP 1234`, then `AT 140,00 STOP RUN`, and
exits 0. Codegen defect 12 stopped the first run at statement 130,00.
PR 155 fixed it, and the comparison of employee numbers now matches.
The run writes three reports:

| Report | Lines | The sample's report |
|---|---|---|
| REPORT.FILE | 11 employee lines and one grand-total line | PAYFILE: 11 employee lines, 7 department lines, one grand-total line |
| CHECK.FILE | 11, one for each check | CHECKFILE: 22, two for each check |
| ERROR.FILE | 17 error records and the bond order | ERRORFILE: 17 lines; BONDORDERFILE: one line |

`test/goldens/f-payroll-j.report` holds the three reports byte for
byte. The test "the applied 1960 deck" in
`test/runtime/machine_test.dart` runs the deck over a copy of the
tapes and compares the result with the golden. `test/f_acceptance_test.dart`
compares the golden with `test/goldens/90.05-payroll.report` and pins
each row of the table below.

### How the lines pair

An employee line of ours prints no number and no name, so the test
pairs the lines by their position. Both programs read the same
employees in the same order, so line *n* of ours is line *n* of the
sample. The hours confirm the pairing: they match on all 11 lines.

### The causes

| Cause | What it is |
|---|---|
| CORR | The CORRESPONDING finding above. J pairs two fields only if all their qualifiers agree ([J 02.04.04]). DETAIL and MASTER hold their fields under the group DATA, so most fields pair with nothing. |
| C1 | M6-1 cause 1, the table lookup. The 1962 page prints RET.PREM equal to INS.PREM (M6-4 finding 1). Our lookup through the 11-character item reads the true RET.PREM. |
| C2 | M6-1 cause 2. Below 40 hours, the 1960 program pays a 40-hour week. |
| C3 | M6-1 cause 3, the 1960 program's own defects. |
| F-T4 | The tape decision F-T4 above: DETAIL BONDENOMINATION is zero. |
| §9.8 | A change that the 1962 sample made to the 1960 program (definition §9.8). |

A field that no statement writes keeps the first value of its record
area. That value is a zero word, because storage starts at zero
(ED-6, `docs/design/emulator.md`). A zero word lists as zero
characters. So each unwritten field prints `0` in every position.

### The classification

The employee lines, 11 of each:

| Column | Result | Cause |
|---|---|---|
| Department and employee number | differ on 11 | CORR |
| Name | differ on 11 | CORR |
| Date | differ on 11 | CORR |
| Hours | match on 11 | — |
| Gross pay | differ on 11 | CORR |
| WHT | differ on 11 | CORR |
| FICA | differ on 11 | CORR |
| Bond deduction | differ on 11 | CORR |
| Insurance premium | differ on 11 | CORR |
| Retirement premium | differ on 11 | CORR |
| Net pay | differ on 11 | C1 on 11; C2 also on 6 |
| Bond purchase | match on 10, differ on 1 | F-T4 on WOO's line |

The department lines: the sample prints 7, and ours prints none. The
cause is CORR. No statement fills PAYRECORD DEPARTMENT or CURRENT
DEPARTMENT, so statement 148,00 compares zero with zero and the test
never passes. M6-1 cause 3 expected the last department's line to
fail only. Under J's rule, every department line fails.

The grand-total line:

| Column | Result | Cause |
|---|---|---|
| The `GT  - -` text | differ | §9.8: END.OF.RUN moves no text into PAYRECORD |
| Hours | match, 389.5 | — |
| Gross pay, WHT, FICA, bond deduction | differ: zero | CORR: statement 149,00 adds HOURS alone into GRAND.TOTAL |
| Insurance and retirement premiums | differ: no writer | C3: INSURANCE.PREM and RETIREMENT.PREM pair with nothing |
| Net pay | differ: zero | C3, a new item: no statement adds a net pay into a totals record |
| Bond purchases | differ: zero | C3, a new item: no statement adds into GRAND.TOTAL BONDPURCHASES, and the field pairs with no PAYRECORD field |

The two new items of C3 are defects of the 1960 program under F's
rule of names too. DETAIL has no NETPAY field. Statement 162,00 adds
the bond into DEPARTMENT.TOTAL only. M6-1 does not list them.

The checks, 11 of each:

| Column | Result | Cause |
|---|---|---|
| Employee number and name | differ on 11 | CORR |
| Date | the sample only | §9.8: the 1960 CHECK record has no date, and the 1962 check takes two lines |
| Amount | differ on 11 | the net pay: C1 on 11, C2 also on 6 |

The amount uses the 1960 picture `$***9.99`, so it prints `$*113.00`.
The value is the net pay of its employee line.

The bond order:

| Column | Result | Cause |
|---|---|---|
| Employee number, name, date | differ | CORR: statement 162,00 pairs BONDENOMINATION alone |
| Denomination | match, 37.50 | — |

The 1960 program files the bond order in ERROR.FILE (§9.8). It prints
between WUFFE T and ZUGEE W, the place where the run buys the bond.

The error records: all 17 match. Each has the code, the number and
the name of the sample's line, or the code, the number, the date and
the hours. The order is the sample's order. Each record prints the
whole 80 characters of the 1960 record, and a detail holds its hours
before its number. That is the layout of the 1960 record (§9.8).

### The counts

The table compares 233 values:

| Result | Values |
|---|---|
| Match | 77 |
| Differ, CORR | 128 |
| Differ, C1 (12 of them with C2 too) | 22 |
| Differ, C3 | 4 |
| Differ, F-T4 | 1 |
| Differ, §9.8 | 1 |
| Differ, a new compiler defect | 0 |

The counts take 11 employee lines of 12 columns, 10 columns of the
grand total, 11 checks of 3 columns, 4 columns of the bond order and
the 54 values of the 17 error records. The 7 department lines are a
separate difference, CORR. The layouts of the checks and of the error
records are §9.8 differences, and the table does not count them.

### The net pay, and why no compiler defect is suspected

A model of the two programs gives every net pay of both reports to
the cent. The model is the test "a model of both programs gives every
net pay to the cent" in `test/f_acceptance_test.dart`. It reads the
rates, the hours, the exemptions, the FICA to date and the bond
deductions from `tool/sample_tapes_source.dart`, and the TABLE from
the applied deck. It applies the two procedures as written, with the
rounding of D4.1: a SET rounds its result. A model without the
rounding misses three lines by one or two cents.

On the five lines of exactly 40.0 hours, ours minus the sample equals
the sample's RET.PREM minus the table's RET.PREM:

| Employee | Ours | Sample | Difference |
|---|---|---|---|
| BLUT H | 113.00 | 112.20 | +0.80 |
| CABAN R | 74.68 | 74.08 | +0.60 |
| SOBEK W | 95.88 | 95.08 | +0.80 |
| REYNOLDS J | 317.01 | 319.01 | −2.00 |
| RICHARD D | 362.16 | 364.16 | −2.00 |

So on these lines the difference is the page's own defect, M6-4
finding 1. Our run of the 1960 program
prints the correct premium. M6-1 cause 1 expected a difference. The
run shows that the difference is the 1962 processor's, not ours.

On the six lines below 40 hours, C2 adds the pay of the hours not
worked, less its FICA and WHT:

| Employee | Hours | C1 | C2 | Ours | Sample |
|---|---|---|---|---|---|
| CASPERIAN J | 20.0 | +0.50 | +84.26 | 165.36 | 80.60 |
| CATLETT H | 31.0 | −0.50 | +51.66 | 225.44 | 174.28 |
| DORR D | 32.5 | −2.00 | +55.35 | 289.87 | 236.52 |
| SMITH B | 30.0 | +0.30 | +23.78 | 94.76 | 70.68 |
| WILLIAMS P | 37.0 | −2.00 | +24.57 | 316.69 | 294.12 |
| WOO J | 39.0 | −2.00 | +9.84 | 370.94 | 363.10 |

The model leaves no residue. So the SET arithmetic, the FICA cap, the
WHT floor and the lookup through the 11-character item carry no
unexplained difference. The gross pay, the WHT and the FICA of each
line do not print. Their agreement with the model is an inference
from the net pay, not a reading of a printed column.

### What the run changes

- The CORRESPONDING finding above is confirmed. It is now the cause of
  most differences. Its class is a defect of the 1960 program
  (§8.5.4-l).
- M6-1 expected the employee number, the name, the date and the hours
  to check. The hours alone check. M6-1 expected gross pay, WHT and
  FICA to check on the five lines of 40 hours. They do not print.
- M6-1 expected no total to check. The grand-total hours check.
- M6-1 as amended 2026-10-25 points here. The fold into M6-9 must
  carry this classification and the two new items of C3.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 87]: ../../comtran-manuals/F28-8043/a1-programming-example.md#appendix-1-programming-example
[J 02.04.04]: ../../comtran-manuals/J28-6169/02-compiler.md#3-move
[J 02.05.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
