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

This record does not settle the finding. The tapes do not change it:
no tape value reaches a field that no statement writes. The run will
show it, and the fold into M6-9 must classify it under M6-4. The
compiler applies J's rule, and J outranks F (CLAUDE.md section 8), so
the expected class is a defect of the 1960 program.

## The generator

| File | Generator |
|---|---|
| `test/fixtures/f-payroll-tapes/D1.tap` and `C2.tap` | `dart run tool/generate_f_tapes.dart` |

The row belongs in the generated-files table of CLAUDE.md section 10,
beside the sample's tapes. CLAUDE.md is a governance file, so this
change does not edit it.

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

## What waits

The run waits for the last item of chunk 2b. The generator stops at
the external-decimal store of statement 141,00, so the applied deck
does not compile to the end, and no run over these tapes is possible
yet. When the deck compiles, the run diffs its values against
`test/goldens/90.05-payroll.report`, column by column, as M6-1 as
amended says.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 87]: ../../comtran-manuals/F28-8043/a1-programming-example.md#appendix-1-programming-example
[J 02.04.04]: ../../comtran-manuals/J28-6169/02-compiler.md#3-move
[J 02.05.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
