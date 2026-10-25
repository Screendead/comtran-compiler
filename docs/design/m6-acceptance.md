# M6 — The acceptance design and decisions

*Drafted 2026-09-13. This document records the M6-specific design decisions
the way `m5-io.md` records M5's. The language facts come from
`docs/comtran-language-definition.md` (cited by §), the manuals (cited as
`(F p. N)` / `(J xx.xx.xx)`), and the locked decision slate
(`docs/design/decisions.md`, cited as D-numbers). This document adds no
language claims. Every unattested choice is labeled ours and is amendable by
an explicit edit.*

*Entry IDs are append-only. A new entry takes the next free number and goes
in the section it belongs to, and the section headings below are the index.
The code cites these IDs, so no entry is ever renumbered.*

## Charter

M6 is the acceptance milestone. The roadmap gives it one task: compile and
run the 90.05 payroll sample end to end, and reproduce its printed report,
PDF p. 217. The report is the only output of a COMTRAN program that
survives. Every earlier milestone reproduced an artifact of the compiler:
the listing, the object program, the deck. M6 reproduces an artifact of
the compiled program.

The input data does not survive. The manual prints the report and not
the master and detail tapes behind it. M6 therefore reconstructs the two
tapes first, from the report and the record descriptions, and then diffs
the report our run prints against the page.

## Scope and stages

- **M6-1. Two stages, one pull request each.** The first stage is the
  sample. It delivers the two reconstructed tapes and their generator,
  the report golden, the reading of the page, the acceptance test that
  diffs the two, and the record of every difference. The second stage
  is the second corpus the roadmap names: the payroll example of the
  1960 manual, with the documented F/J divergences applied (§9.8). It
  has no printed output to diff, so its oracle is the sample's: the
  same tapes, and the report the sample prints. The second stage waits
  for the first.

  **Amended 2026-09-14.** The second stage is chunked, the way M4 stage
  2 was (Jack's call of 2026-08-09), and M6-6 to M6-9 hold the chunks.
  Its input is not the same tapes. The 1960 records are 80-character
  external images, so the stage writes the same source table,
  `tool/sample_tapes_source.dart`, in the corpus's own layouts. Its
  oracle is the values the sample's report prints, not its bytes.

  **Amended again 2026-09-14, before the run.** The corpus prints its
  own report, and that report does not equal the sample's report in
  every column. Three causes separate them. Each is stated here, so
  the run measures a stated expectation and finds no surprise.

  1. **The table lookup.** The sample's RET = INS defect rests on
     items of two whole words (M6-4). The 1960 TABLE.ITEM is 11
     characters. How a positional indicator addresses a stride that is
     not a whole number of words is a design chunk 2b must make. No
     listing attests the form: `MON PI)NN,,0` is the printed word, and
     the character arithmetic behind it is not printed. Codegen defect
     7 lies on that path (`docs/HANDOVER.md`). The insurance premium,
     the retirement premium, the net pay and the check amount are
     therefore expected to differ, and that design settles them.
  2. **The overtime sentences.** The two programs agree above 40 hours
     and disagree below it. The 1960 program tests for more than 40
     hours. It pays the premium half only when the test passes. It
     then adds 40 hours of pay to the detail record's own GROSS field
     (serials 02012 to 02014). Below 40 hours it pays a 40-hour week.
     The 1962 sample carries an OTHERWISE arm that pays the hours
     worked (definition §9.8). No line of the reconstructed tapes
     exceeds 40 hours, and six of the eleven fall below it. Gross pay
     therefore differs on those six lines, and the withholding tax,
     the FICA deduction and the net pay follow it.
  3. **The 1960 program's own defects.** The last department's totals
     never print. CURRENT DEPARTMENT carries no value at the first
     department test, because the program sets it at the end of the
     first cycle. `MOVE CORRESPONDING DEPARTMENT.TOTAL TO PAYRECORD`
     leaves two fields unmatched: the totals record names them
     INSURANCE.PREM and RETIREMENT.PREM, and the print record names
     them INSURANCE and RETIREMENT.

  These columns still check against
  `test/goldens/90.05-payroll.report`: the employee number, the name,
  the date and the hours. Every ERRORFILE line and the BONDORDERFILE
  line check too. Gross pay, the withholding tax and the FICA
  deduction check on the five lines where the hours are exactly 40.0
  and on no other line. No department total and no grand total checks,
  because each one sums the lines above it.

  Four checked columns rest on a tape decision that chunk 2b has not
  made: gross pay, the withholding tax, the FICA deduction and bond
  deduction. The 1960 program adds into the detail record, so a
  computed field starts at whatever the tape carried. Three fields
  start there: GROSS (serial 02014), INSURANCE and RETIREMENT
  (serials 04019 to 04021). The FICA sentence sets DETAIL FICA in
  both arms (serials 03016 to 03018), and the WHT sentence sets
  DETAIL WHT in both arms (serials 04002 to 04004). No tape value
  reaches those two columns. The gross-pay check above, and the
  withholding-tax and FICA checks with it, therefore hold only if the
  corpus's detail record arrives with zero in GROSS. The insurance
  premium and the retirement premium need zero in INSURANCE and
  RETIREMENT, and cause 1 above already separates them. Bond
  deduction checks only if the detail record carries the master's
  bond deduction, because
  `MOVE CORRESPONDING DETAIL TO PAYRECORD` is the only writer of the
  printed field and the bond routine works on the master. Chunk 2b
  settles the layout, and it must state which of these it chose.

  A difference between our report and the page is a finding, and M6-4
  classifies each one. A finding is one of four things: a defect of
  ours, a defect of the 1962 processor that the page corroborates, a
  print artifact of the page, or a difference the manuals cannot
  settle. The last kind is recorded and left. Evidence for it exists
  and is sealed until M7 (D0.9).

## The page

- **M6-2. The scan is read along its own baselines.** The page is
  `comtran-manuals/J28-6169/images/page-217.png`. The print is skewed:
  every line rises to the right by about one line height across the
  page width. The right-hand amount fields of a PAYFILE line therefore
  sit one row above the line's left-hand text on the page, on one
  straight tilted baseline. The transcription
  (`comtran-manuals/J28-6169/90.05-sample-program.md`, the block at
  PDF p. 217) assigned those fields to the row above and described the
  result as "the printer's practice of carrying the last few amount
  fields of a detail or totals line on the print position immediately
  above the identifying line". The scan shows no such practice. It
  shows a skew. The scan outranks the transcription (CLAUDE.md section
  9), so the reading follows the baselines: the first PAYFILE line ends
  `2.00  2.00  112.20` with a blank bond denomination, and the GT line
  ends `28.00  28.00  2180.63  37.50`.

  The arithmetic of the page confirms the reading. On every PAYFILE
  line, NETPAY = GROSS − FICA − WHT − INS.PREM − RET.PREM −
  BONDEDUCTION holds to the cent under the baseline reading and fails
  under the transcription's. Every department total is the sum of its
  lines, and the GT line is the sum of the department totals in every
  column but one (M6-4).

  Jack authorized the correction on 2026-09-14. The note now states
  the skew, and the block reads each line along its own baseline. The
  reflow left three cells that the scan contradicts. The DEPARTMENT 09
  TOTALS line prints `0.00` in the fourth amount column, where the
  transcription read `5.21`. The GT line prints `5.21` and `36.00` in
  its fourth and fifth columns, and the transcription omitted both. The
  column sums confirm all three: the fourth column of the seven
  department totals sums to 5.21, the fifth to 36.00, and the four
  detail lines of department 09 each print 0.00 in the fourth.

  **Amended 2026-09-15.** Jack authorized the three cells, in these
  words: "authorize the three cells". The conversion now prints them,
  and no erratum candidate is open. The reading was measured again
  first, on the scan
  (`comtran-manuals/J28-6169/images/page-217.png`) deskewed by 1.8
  degrees. No finding of M6-4 moves, and no test and no golden change.
  `test/fixtures/90.05-report-page-217.txt` was keyed from the scan and
  never from the conversion, so it already held the three values, and
  so did `test/goldens/90.05-payroll.report`. Finding 2 stands, and the
  corrected cells are what let the GT line's own arithmetic close:
  2730.39 − 449.35 − 5.21 − 36.00 − 28.00 − 28.00 = 2183.83, where the
  page prints 2180.63.

  The print chain rendered some letters O as C. The BONDORDERFILE line
  prints `WCO J` where the PAYFILE line and the check print the same
  master NAME field as `WOO J`. Two ERRORFILE names print `MOCRE`, with
  no second print to compare. The reading keeps the ink: `WOO J` is the
  field, because two of its three prints say so, and `MOCRE` is keyed
  as printed. `test/fixtures/90.05-report-page-217.txt` holds the
  reading, in the form `--list-tapes` prints and in its order, the
  `*FILE` card order. The page pastes the four reports in a layout of
  its own, two of them side by side, and that layout is no print
  order. Its CHECKFILE block holds the three checks the page prints,
  and nothing stands for the eight it omits.

  We measured the columns on the scan and read none off the
  transcription (CLAUDE.md section 9). We rotated the page 1.83
  degrees to take the skew out, and fitted the character pitch per
  pasted block at about 9.3 pixels a column. Every measured item of
  the PAYFILE block lands on the column the record layout gives it,
  within a tenth of a column: the date at 25, the hours at 38, and so
  on to the bond purchases at 114. On the check, the control character
  sits at column 1, the employee number at 40, and the amount at 41 to
  47: the `$` of `$294.12` prints in column 41, next to its first
  digit, and column 40 is blank. The edited picture `$8889.99`
  therefore floats its dollar sign to the first digit, which is what
  MOVPAK's edit does (RT-5). The BONDORDERFILE strip was pasted with an
  origin of its own, six tenths of a column off the CHECKFILE grid, so
  its column 1 cannot be measured. Its internal pitch is the CHECKFILE
  pitch, and its glyphs stand 24 and 29 columns apart where the layout
  puts them. Every ERRORFILE line starts in one column.

## The reconstruction

- **M6-3. The tapes are derived where the page fixes a field and
  chosen where it does not. Ours.** The program fixes a master field
  through the statements that print it, and
  `test/fixtures/90.05-tapes-notes.md` holds the derivation of each
  one and the table of every record. Five fields are derived exactly:
  the number and name, the rate as GROSS ÷ HOURS, the exemptions from
  WHT, the bond deduction, and WOO's bond denomination. A FICA year to
  date that prints 0.00 is 144.00 exactly, because statement 213 caps
  the master at 144.00 and takes the excess off the pay, and DORR's
  2.01 fixes 141.99. The rest is chosen. Each choice is the least
  value that prints the page:

  - 0.00 for a FICA year to date the cap never reaches;
  - 20.50 for WOO's bond accumulation;
  - 18.75 and 0.00 for the denomination and accumulation of the three
    who deduct and order nothing;
  - zero or blank for every field the report never prints.

  An unmatched master is its number and its name.

  The images take the blocking the manual describes. The master file
  is "twenty 15-word records ... grouped to form 300-word blocks on
  tape, with each record complete within a block" ([J 90.05.02]), so
  25 records make a block of 20 and a block of 5. A detail record
  "occupies the first portion of tape blocks 14 words long"
  ([J 90.05.03]), so each block is the three words of the record and
  eleven words of blanks. The DETAILFILE card's BLOCKSIZE 3 brings the
  three in (M5-2).

  `tool/generate_sample_tapes.dart` writes the two images from the
  table in `tool/sample_tapes_source.dart`, and the golden test
  regenerates them and compares the bytes, the way the message
  catalog is guarded (CLAUDE.md section 10). The images are committed
  because `comtranc --run --tapes=DIR` reads a directory, and a reader
  of the repository runs the sample with no generator step.

## The result

- **M6-4. The run reproduces the page up to four findings.** The
  sample compiled from the deck, loaded, and run over the reconstructed
  tapes prints 22 check lines, 19 PAYFILE lines, one bond order and 17
  error lines. The ERRORFILE is the page. The three checks the page
  prints are the last three of ours. Eighteen of the 19 PAYFILE lines
  are the page. The findings:

  1. **RET.PREM equals INS.PREM on every line, on the page and in our
     run. The 1962 processor's defect, corroborated.** The table gives
     every rate an insurance premium and a retirement premium, and the
     two differ in every row. The page prints them equal on all twelve
     lines, and every net pay subtracts the insurance premium twice.
     The object listing shows why: the lookup at LOC 01421 to 01470
     builds the two pointer words `PI)3` and `PI)2` from base words
     that are identical, `PZE RETPREM-2` and `PZE INSPREM-2` both with
     a zero decrement, and the two step lists that read them are
     identical. The 1962 processor compiled `RETPREM (POS)` as
     `INSPREM (POS)`. Our generator reproduces the listing byte for
     byte, so our object program carries the same defect, and our run
     prints the same page. `m4-codegen.md` M4-20 (a) as amended records
     it. The report is the first artifact that shows a defect of the
     1962 compiler in its output rather than in its text.
  2. **The grand-total net pay on the page is 2180.63; ours is
     2183.83. Not settled.** The seven department totals on the page
     sum to 2183.83, and GROSS − WHT − FICA − BONDEDUCTION − INS.PREM −
     RET.PREM on the GT line itself gives 2183.83. The page disagrees
     with itself by 3.20 in that one cell, and every other cell of the
     GT line is the sum of the column above it. The same object text
     ran in 1961 and runs here, so the difference is in the 1961
     runtime library or in something the page does not show. The
     manuals cannot say which. Evidence exists and is sealed until M7
     (D0.9). Our run prints the consistent sum, and the acceptance test
     pins the difference.
  3. **The bond order prints `WCO J`; ours prints `WOO J`. A print
     artifact.** M6-2 holds the reading. The field prints `WOO J` twice
     elsewhere on the page.
  4. **The bond order's employee number printed as six zeros in our
     first run. Ours, fixed.** The object text loads MASTER's base into
     index register 1 at LOC 01320 and addresses through it again at
     01333, after the edited store of BONDENOMINATION at 01325 to
     01331, whose calling sequence ends `AXT 5,1`. Our MOVPAK cleared
     the register at every entry and handed the `AXT` back to the CPU,
     so register 1 held 5 and 01333 read the zero word at address
     0 − 5. The page prints the number, so the
     1961 library preserved the register and took the `AXT` as the last
     word of the sequence, which is how [J 90.02.30] prints it. The fix
     saves and restores the register around a call and consumes the
     `AXT`. `runtime.md` RT-3 and RT-5 as amended hold the rule.

  Nothing else differs. Every other character of the four reports is
  the page's.

- **M6-5. Three tests carry the result.** `test/sample_tapes_test.dart`
  regenerates the two images and compares the bytes. The 90.05 group of
  `test/runtime/machine_test.dart` runs the sample over a copy of the
  fixture directory and compares what `--list-tapes` prints with
  `test/goldens/90.05-payroll.report`, byte for byte.
  `test/acceptance_test.dart` compares that golden with the reading of
  the page, report by report, and passes only at the differences M6-4
  records: the GT net pay, the one letter of the bond order, and the
  eight checks the page omits. A new difference fails it, and so does
  the disappearance of a recorded one. The golden is under
  `test/goldens/`, so a pull request that moves it merges on
  external-review convergence (CLAUDE.md section 12).

## The second corpus

- **M6-6. The 1960 program is keyed as printed, and its compilation is
  a diagnostic corpus.** `test/fixtures/f-payroll.ctd` holds the sample
  payroll program of F28-8043 Appendix 1, keyed from the typeset machine
  listing at [F p. 101] to p. 104. It holds 187 source cards and two division
  headers between `*COMPILE LIST` and `*FINISH`. That listing prints
  the card image, columns 1 to 72, with the serial of columns 1 to 5
  as the card carries it ([F p. 65]; [J 02.02.01]). The field columns and
  the procedure start columns were measured on the scan (CLAUDE.md
  section 9). The word gaps inside a card come from the conversion,
  with one to three columns of uncertainty, as the notes state.
  `test/fixtures/f-payroll-deck-notes.md` holds
  the measurements and each placement choice. The deck keeps the 1960
  text whole: `*PROCEDURE` before `*DATA`, no environment division,
  `STOP 1234`, `1COPY`, a level on the REDEF line, and `WITHOLDING`.

  The 1962 processor never compiled this program. Ours does, and the
  result is the first fixture that exercises the diagnostic machinery
  on a real program, because the sample compiles clean. The front end
  prints 55 messages of 12 kinds and closes with SEVERITY LIMIT WAS NOT
  REACHED. The generator then refuses the first GET, because no FILE
  card lists MASTER. `test/goldens/f-payroll.listing` pins the listing,
  and the corpus test pins the refusal line, which the listing cannot
  carry. The page head prints the run's date and time, so both goldens
  take `--date=06/01/60 --time=1.00`, two values that claim nothing.
  The golden has no 1962 oracle: the sample's listing carries no
  message, so the layout of a listing with messages is
  decision-conformance only. The messages are these:

  - six 166,00, one for each CALL old name that names a field of
    several records (D4.13), and the 26 108,00 and seven 101,00 that
    follow from the synonyms the CALL never made;
  - three 9,00, four 19,00 and three 21,00 for the records and the file
    that no FILE card carries;
  - 175,00 for the missing STOP RUN (D2.7);
  - 110,00 for COPY, which J defers ([J 90.01.03]);
  - 906,00, 81,00 and 80,00 for the level on the REDEF line and the
    level of TABLE.ITEM (D3.4);
  - one 206,00 for INDEX, an external field inside a record.

  Four observations, none a defect:

  - No message names the missing environment division, and the
    compiler completes. [J 05.06.01] says compilation completes "unless
    a catastrophic error occurs (e.g., the omission of a division
    header)", after which "a standard end-of-job message will be
    printed". The manual does not say whether a division absent whole
    is that omission or only a header absent before its cards (D2.3).
    The 9,00, 19,00 and 21,00 messages are the attested consequence of
    the absent FILE cards.
  - The resolver reports 101,00 on `DPT HOURS`, a synonym used as a
    qualifier. D4.13 speaks of a reference whose last name is a
    synonym. Open Question 56 holds the question, and the applied deck
    avoids the form.
  - The COPY rule copies an entry "in its entirety" but for its name
    and its level ([F p. 76]), so an expanded GRAND.TOTAL is a RECORD.
  - The six TABLE cards are six level-2 entries, each with its own
    quote marks and an empty continuation column. The form ([F p. 100]) and
    the listing show them alike. The §9.8 row that read them as one
    continued literal is corrected. The conversion's note read them the
    same way. Jack authorized the correction on 2026-09-14, and the
    note now describes the six entries.

- **M6-7. The applied deck takes the rows of §9.8 that the front end
  requires, and no other. Ours.** `test/fixtures/f-payroll-j.ctd` is
  the 1960 program with five divergences applied. Each is a row of the
  §9.8 table, and each is a change the 1962 front end demands. The
  applied deck carries no serial. It is a deck in the 1962 form, and
  the 1962 sample carries none; the compiler checks no sequence either
  way (D2.4). The five:

  1. An environment division, and J's order DATA, ENVIRONMENT,
     PROCEDURE (D2.2). Five files, all BCD tape, named after the F
     prose the way ERROR.FILE is: MASTER.FILE and DETAIL.FILE for
     input; REPORT.FILE, CHECK.FILE and ERROR.FILE for output.
     ERROR.FILE carries MASTER, DETAIL and BONDORDER, because the 1960
     program files its bond orders there. Each BLOCKSIZE is the word
     count of the file's longest record: 14, 14, 20, 5 and 14. The
     units are the sample's for the like file, D1, C2, D3, D2 and D4,
     and each SPECIF is OPENW, CLOSER, LOW. No file receives an updated
     master. The introduction promises one ([F p. 87]), and the program
     never files MASTER except in error.
  2. CALL old names qualified to one field, and synonyms unqualified
     (D4.13), the sample's pattern: `(MASTER EMPLOYEE.NUMBER)
     M.EMPLOYNO`, `(DETAIL EMPLOYEE.NUMBER) D.EMPLOYNO`, `(MASTER
     BONDEDUCTION) M.BONDEDUCT`, `(MASTER BONDENOMINATION) M.BONDENOM`
     and `(MASTER BONDACCUMULATION) M.BONDACCUM`. Every other renamed
     reference is written in full, `PAYRECORD EMPLOYEE.NUMBER`,
     `DEPARTMENT.TOTAL HOURS`, `TABLE.ITEM INSURANCE.PREM (INDEX)`. The
     DPT synonym goes, because each of its uses qualifies a field
     through it (M6-6).
  3. `STOP RUN` for `STOP 1234` (D2.7).
  4. GRAND.TOTAL written out as a RECORD with DEPARTMENT.TOTAL's nine
     entries: the COPY expanded by hand under the [F p. 76] rule (M6-6).
  5. The bare REDEF card, TABLE.ITEM at level 1 with its three fields
     at level 2 (D3.4; D3.6).

  Everything else stays 1960: external fields, arithmetic in the
  records, ERRORCODE in the records, `FILE ... IN ERROR.FILE`, the
  six-card TABLE literal, INDEX inside CURRENT, `IS NOT GREATER THAN`,
  and the edited pictures with `*` and a trailing `-`. The deck is the
  base of the next chunk, whichever way M6-8 is decided.

  The deck holds 215 cards. Its listing draws three 206,00, each for
  INDEX in the SEARCH sentence, statement 165,00, and no other message.
  It closes SEVERITY LIMIT WAS NOT REACHED. Two details of the
  keying: the expanded GRAND.TOTAL header carries DEPARTMENT.TOTAL's
  `L`, because the [F p. 76] rule copies the entry whole; and `DPT
  BONDEDUCT` becomes `DEPARTMENT.TOTAL BONDEDUCTION`, the field's own
  name. The notes hold every changed card.

  **Amended 2026-09-14.** The premise above overstates the case. The
  1962 processor compiled the verbatim deck as punched, so no row of
  the five is a change the front end demands of the source text. Four
  of the rows fix the deck that compilation punched. That deck could
  not run: its GET and its FILE named records that no file carried.
  M6-9 holds the reading rule and the evidence for it. Row by
  row:

  1. The environment division is construction, not repair. Messages
     9,00, 19,00 and 21,00 do not stop a compilation. [J 05.06.01] says
     compilation completes "unless a catastrophic error occurs (e.g.,
     the omission of a division header)". Whether a division absent
     whole is that omission is D2.3's open point. The row exists
     because the 1962 GET and FILE bound to nothing.
  2. J's rule requires the CALL row. [J 02.04.05] #5: "The (old.name)
     in a CALL statement must be unique and may not be subscripted."
  3. The STOP row was wrong, and the deck is corrected. `STOP n` is
     attested legal: [J 05.06.04] a says the computer stops, and the
     START key resumes the object program. SYS)178 carries "the type of
     STOP (STOP NNN or STOP RUN)" ([J 90.02.14]), and D2.7 implements
     both forms. Message 175,00 fires on the absence of STOP RUN, which
     [J 02.04.06] #9 requires in each program. The 1962 repair
     therefore adds `STOP RUN` after `STOP 1234`. It replaces nothing.
     `test/fixtures/f-payroll-j.ctd` punches both cards and holds 216
     cards, and the three 206,00 messages move to statement 166,00.
  4. J defers COPY, so the row is required. [J 90.01.03] b.i states
     the deferral. The hand expansion reconstructs the 1960 intent
     under the [F p. 76] rule, and it matches what the 1962 sample
     wrote out. No 1962 program equals it.
  5. J's rule requires the REDEF row. [J 02.05.02]: "When the REDEF
     type code is used, it should appear on a line with no additional
     coding except a serial number and the name of the item being
     redefined."
     Messages 80,00 and 81,00 report the conflict. What the 1962
     processor made of the 1960 form is unstated, so our edit takes the
     rule's own form.

- **M6-8. What the generator cannot recover from the applied deck, and
  the course it leaves. Decided under the section 12 standing rule;
  Jack can overturn it.** The generator refuses the
  applied deck at statement 131,00, `FILE MASTER IN ERROR.FILE`, the
  first shape in source order that the sample never attests (M4-2). A
  job stops at its first refusal, so the run shows one shape and the
  code shows the rest. The static inventory, read from
  `lib/src/codegen/procedure.dart`:

  - `FILE record IN file`, three times;
  - every arithmetic sentence: each SET target, ADD operand, numeric
    comparand and DO index is an external field, and the generator
    recovers internal decimal only;
  - the WHT test and the FICA test, each a comparison of an
    expression;
  - `(DETAIL HOURS - 40) * MASTER RATE * 1.5`, a product of a product;
  - `DO SEARCH FOR INDEX = 1(1)12`, an index that is external and
    lives in a record;
  - `MOVE PAYRECORD NETPAY TO CHECK AMOUNT`, five integer digits into
    four, an edit run that bypasses source digits;
  - `TABLE.ITEM RATE (INDEX)`: the item is 11 characters, and the
    stride truncates to one word with no refusal (`docs/HANDOVER.md`,
    codegen defect 7).

  Two courses lead from here, and they differ in size by an order of
  magnitude:

  - **A. Recover the 1960 shapes.** Build external-decimal arithmetic
    from the convert members of [J 90.02]: SYS)184 in, and SYS)186 to
    188 out, which the sample never attests and RT-3 has not built.
    Then the FILE IN form, the located index, the expression
    comparison, the product chain and the truncating edit run. Each is
    a decision-conformance design with no listing oracle. The compiler
    gains the largest part of the language the sample never touches,
    and the codegen defects 1 to 4 get live sites.
  - **B. Apply the remaining rows of §9.8.** Stage the arithmetic in a
    WORKING area of internal fields, the way the 1962 sample does. Add
    a dedicated error record and plain FILE, 24 per-field constants,
    explicit MOVEs where the qualifier chains differ, and INDEX in
    WORKING. The 1960 records and flow stay. Two shapes stay unbuilt
    even so. The year-to-date fields of the 1960 master are external,
    so their update from WORKING needs the internal-to-external move,
    SYS)186. The second shape is the check amount's edit run. The
    course inside B that needs
    neither is the sample's own: retype the master's numerics IR and
    make MASTER.FILE binary. The check amount then comes from an
    internal source, the attested shape.

  B is the course, in the sample's own form. Three facts leave one
  option open (CLAUDE.md section 12). The roadmap's words are B, "with
  the documented F/J divergences applied". The 1962 sample applied the
  same rows to the same program, so every replacement is attested. And
  A has no oracle for any of its shapes. Each is a design with no
  listing behind it, and it belongs to a stage of its own, which
  `docs/HANDOVER.md` parks. Two rows still need adding to §9.8 when
  chunk 2b applies them: the overtime formula, which the sample
  rearranged to `(HOURS * 1.5 - 20) * RATE`, and the master's typing,
  IR fields in a binary file. Under B the table items are two whole
  words. The RET = INS defect therefore reproduces by the same
  word-granular rule, and the sample's report becomes a value-level
  oracle for the corpus (M6-4). Under A the 11-character items meet
  defect 7 instead.
  The review record holds the rejected courses and their costs.

  **Amended 2026-09-14. Overturned in part, on Jack's instruction of
  that date.** He ruled: "if it would compile in 1962, it should
  compile. If it wouldn't, it shouldn't. If it's ambiguous, I need to
  see it with argumentation both ways and a recommendation, and I'll
  make a call." The 1962 processor is the one J28-6169 describes. Two
  standing decisions already carry the principle. D0.1 makes J the
  target language. D0.8 makes the field-test compiler as attested the
  reconstruction target.

  **Course B is withdrawn, and so is the parked stage.** M6-9 holds
  the evidence: all six shapes of the inventory above compiled in 1962.
  Course B replaces them with the sample's forms, so course B rewrites
  source that the 1962 processor accepted. The rule forbids that.
  Course A is the course. M6-9 gives it its list, and
  `docs/HANDOVER.md` carries it as the next task instead of as a
  parking.

  **Where the reasoning went wrong.** The roadmap's words decided B,
  and they were read broad. "With the documented F/J divergences
  applied" can mean every row of §9.8, or only the rows the 1962
  front end forces. Jack's rule reads them narrow: apply what 1962
  forces, and record the rest. Definition §4.2.1 already states what
  the rest costs, which is an unpack-and-convert at object time and
  nothing else. Two rows are recorded and not applied: the overtime
  formula, and the master's numeric typing. §9.8 now carries both.

  **One line of the inventory is corrected.** `DO SEARCH FOR INDEX =
  1(1)12` is refused for the index's mode, not for its place. The
  refusal that fires is `_decimal(indexItem)`. `_located` is false for
  CURRENT, a record that sits on no FILE card and has no base locator.
  The line folds into the arithmetic line above it.

  Nothing above is deleted. The costs recorded against course A stand
  as the costs of the course now taken, and the costs recorded against
  course B stand as the costs of the course refused.

## What compiles in 1962

- **M6-9. The six refused shapes all compiled in 1962. Decided under
  the section 12 standing rule; Jack can overturn it.** Jack ruled on
  2026-09-14: "if it would compile in 1962, it should compile. If it
  wouldn't, it shouldn't. If it's ambiguous, I need to see it with
  argumentation both ways and a recommendation, and I'll make a call."
  This entry answers the rule for the six shapes M6-8 inventories. Each
  one compiled. The 1962 processor is the one J28-6169 describes (D0.1;
  D0.8).

  **The reading rule.** J names its two core sections after what they
  do to F: "02.04 Procedure Description Clarification and
  Amplification" and "02.05 Data Description Amplification and
  Clarification". Where J revokes an F form, it revokes it in words.
  [J 02.07.04] is the model: "The verb is described incorrectly in
  the Commercial Translator General Information manual and the
  definition ... should be replaced with:".
  Appendix 90.01 is the enumerated list of what the field-test
  processor did not do. So a form that F admits, that J does not
  contradict, and that 90.01 does not defer, compiled in 1962.

  **The reading against it.** J's comparison section states rules for
  fields and says nothing about expressions. Message 107,00 "ILLEGAL
  COMPARISON STRUCTURE." states no trigger, so it could be the
  diagnostic for an expression comparand. On that reading J's silence
  withdraws the form. We reject the reading under D0.1. An F-only
  feature is one that J withdraws, or that 90.01 defers. It is not one
  that J merely does not restate. J restates little of F, so the
  reading against would withdraw most of the language.

  **The six verdicts.** Each refusal named below is a site in
  `lib/src/codegen/procedure.dart`.

  1. **Arithmetic on external-decimal record fields.** [J 02.04.05] #6:
     "The operands of a SET instruction which are used in an arithmetic
     expression may be fields of any format except alphameric ...
     Appropriate conversion is performed in all cases although
     arithmetic operations are considerably less efficient when
     performed on fields having dissimilar formats." [J 02.03.03.01]
     makes the same point by example. It rewrites a sequence for
     speed, and keeps `SET A = X+C` in the improved form. There A to
     E carry no mode letter, and X alone is IR
     (`comtran-manuals/J28-6169/images/page-015.png`).
     Definition §4.2.1 already states the object-time conversion. The
     generated forms are attested. A fetch reads the field into a
     register through SYS)181 or SYS)182 ([J 90.02.15]). SYS)184
     converts it ([J 90.02.16]). A store writes it back through
     SYS)180 ([J 90.02.15]) with SYS)186, 187 or 188
     ([J 90.02.18]). The sample
     exhibits SYS)184's calling sequence at statement 202,00, and the
     SYS)180 skeleton at GROSS's edited store. The refusals are the
     arithmetic arms. No 90.01 restriction covers the shape, and
     message 25,00 rejects
     alphameric operands only. Two things stay open: the overflow
     behaviour of SYS)186 to 188, which carry no test step, and
     rounding (§8.5.4-a).
  2. **`FILE record IN file`.** [J 02.07.08] b: "FILE record.name IN
     file.name — This form of the verb provides a means of filing a
     record in a specific file when the record.name is associated with
     several output files." Its condition a asks that the record be
     associated with the file in the Environment Description. The
     applied deck's ERROR.FILE card lists MASTER, DETAIL and
     BONDORDER, so the condition holds. The refusal is the
     `inFile != null` guard. Each of those three records has one
     output file, so the emitted code equals plain FILE.
  3. **INDEX inside a record.** This shape folds into shape 1, because
     the refusal that fires is the mode test and not a place test.
     Message 206,00 "'NAME.1' HAS INEFFICIENT FORMAT FOR SUBSCRIPT
     VARIABLE." concedes that the form works. The rejecting messages
     are 31,00 and 79,00, and an INDEX of `99` draws neither. Our
     severity for 206,00 and our trigger criterion are both ours
     (D9.11, "CRITERION INVENTED"). J states no rule on where a
     subscript variable is declared. [J 02.05.01] asks only for a Data
     Description entry. [J 90.01.02] vi lists four indexing cautions,
     and none of them is about declaration. The 1962 sample's INDEX
     is `IR99` in WORKING, a level-1 group with no type code, so the
     sample attests the mode and not the place.
  4. **A comparison whose sides are expressions.** [F p. 21] says
     relations "may be used to connect data-names, literals, and
     arithmetic expressions", with the example
     `BEGINNING.ON.HAND + RECEIPTS - SHIPMENTS IS LESS THAN
     REORDER.POINT`. F pp. 105 and 106 formalise it. [J 02.04.06] and
     [J 02.04.07] state six field rules and no grammar, and
     [J 02.04.05.01] b heads
     its precedence table with TR, a condition inside an expression.
     Definition §5.3.2 lists J's tightenings, and operand shape is not
     among them. The sites are statements 152,00 and 156,00 of the
     applied deck, and the refusal is the default arm of the numeric
     comparison.
  5. **A product of a product.** [J 02.04.05.01] b: "the expression
     A*B*C will be taken to mean (A*B)*C".
     [F p. 107], rule 4, states the same.
     The site is statement 141,00. Above 40 hours the 1962 sample's
     `(WORKING HOURS * 1.5 - 20) * MASTER RATE` folds the 1960
     program's two sentences (definition §9.8). It avoids no shape.
     Open Question 28 asks about intermediate precision in the
     generated code, not about legality.
  6. **An edit run that drops high-order digits.** [F p. 42]: "Such
     alignment may involve the dropping of leading digits or low-order
     digits".
     [F p. 43] works a row: `99999` holding `01234` into `999V9` gives
     `2340`. SYS)190's package counts characters to test for overflow
     and characters to bypass ([J 90.02.19]). At run time
     SYS)130 records "the truncation of significant high order values
     (i.e. overflow)" ([J 90.02.10]). Definition §8.5.4-b holds
     the same reading. The site is statement 146,00, `$88889.99-` into
     `$***9.99`. The refusal is the edit-step builder, and its comment
     says the manual's two bypass counts cannot be told apart. The
     SYS)190 notes on
     `comtran-manuals/J28-6169/images/page-158.png` may distinguish
     them, and nobody measured that page. The code and the comment
     stay as they are, and chunk 2b carries the check.

  **The refusals are stricter than Jack's rule, by design.**
  `UnrecoveredShape` says so in its own words: "The 1962 compiler had
  code for the shape, so no [J 90.04] message and no severity fits". A
  refusal asks whether the 1962 listing attests the generated form. It
  never asked whether the 1962 processor compiled the source. The two
  questions part company here for the first time.

  **The severity finding.** [J 90.04.02]: "The Severity Codes (values)
  are numbered 1 through 5 ... An error severity code of 1 does not
  prevent the running of the object program immediately after
  compilation. Any code above 1 does prevent running ... An error
  severity code of 5 causes the compiler to stop compiling."
  [J 02.01.01]: "If the severity code is 5, a deck will not be
  produced." [J 02.01.02] makes execution conditional on no error above
  severity 1 and on no undefined symbol in the generated code.
  [J 90.04.01] prints CODE 0 against every message "because the value
  may vary", so no printed value survives.

  The verbatim deck draws twelve message kinds: 166, 108, 101, 9, 19,
  21, 175, 110, 81, 80, 206, and our own 906. None of the twelve is
  worded as a stop, a deletion or a repair. J holds that vocabulary and
  uses it elsewhere: 2,00 "-RUN- DELETED.", 25,00 "OPERATION IGNORED",
  171,00 "SENTENCE DELETED FROM TEXT." Our severities are D7.5's, and
  they run 1 to 4 and never 5. So `test/goldens/f-payroll.listing`
  closes SEVERITY LIMIT WAS NOT REACHED, and the driver goes on to code
  generation. There the refusal `a GET record on 0 input files (no
  sample instance)` stops it.

  Under J's letter, then, the 1962 processor compiled the 1960 deck as
  punched, punched an object deck, and refused to run it. No evidence
  describes what that deck held. It held a GET on a record bound to no
  file, 26 undefined names, and a GRAND.TOTAL left empty because COPY
  was deferred. The severities that could change this are unattested
  (Open Question 65).

  **The one question for Jack.** Does "compile" in his rule mean the
  diagnostic listing, or the object deck?

  - *For the listing.* The listing is the artifact our corpus
    reproduces and a golden pins, and chunk 2a already delivered it
    whole. The object deck is unreachable: no evidence describes the
    code for a GET bound to no file, and inventing it breaks D0.4.
  - *For the object deck.* To compile in 1962 was to punch a deck.
    [J 02.01.01] ties deck production to the severity code alone, and
    our severities allow it. A compiler that stops short of the deck
    has not compiled. On this reading the refusal marks a gap in our
    recovery and not a property of the program.

  **Recommendation.** Keep the refusal for the verbatim deck, and
  relabel it. The honest label is "1962 punched a deck whose content no
  evidence describes", not "1962 refused". Take the listing as the
  deliverable of that deck. The applied deck is where chunk 2b works,
  so nothing in the repository waits on the answer. The question is
  Jack's call under his rule, and the review record on branch
  `review/2026-09-14-m6s2-rule` carries it to him.

  **Chunk 2b's design list.** Each item is a recorded decision under
  D0.4, with no listing oracle behind it:

  - the external-decimal fetch, SYS)181 or SYS)182 with SYS)184;
  - the external-decimal store, SYS)180 with SYS)186, 187 or 188;
  - `FILE record IN file`;
  - a comparison whose sides are expressions;
  - a product of a product;
  - the SYS)190 bypass steps, with the page-158 notes measured at build
    time;
  - the 11-character table stride, which carries codegen defect 7 with
    it (`docs/HANDOVER.md`);
  - `STOP n` at run time: the halt and the resume (Open Question 69);
  - a numeric comparison of unequal scales, added 2026-10-25 by the
    fetch decision below.
  - a scaling store of a chain value, added 2026-10-25 by the store
    decision below;
  - an external-decimal DO FOR index, added 2026-10-25 by the
    store decision below;
  - a DO FOR driving three indicators, added 2026-10-25 by the DO FOR
    decision below.

  No decision below changes the two listings or
  `test/goldens/90.05-payroll.code`, because each acts on shapes the
  sample does not hold.

  **Decided 2026-10-24: `FILE record IN file`. A design decision
  under D0.4; Jack can overturn it.** This is the third item of the
  list above, and the first item done. The generator now compiles the
  IN form to the call of plain FILE, with the named file in the file
  word:

  ```
  TSX    IOC)9,4
  PZE    file,,0
  IOST   record,,length
  ```

  A located record takes the LXA and SXA pair ahead of the call, the
  same as plain FILE. No listing shows the IN form. The decision rests
  on four facts:

  - The 1962 sample attests the IOC)9 call of plain FILE, and its file
    word names one file.
  - [J 02.07.08] b gives the IN form "a means of filing a record in a
    specific file". The form names that one file, so the call names
    it.
  - PRIMARY does not change the call. [J 02.06.07] binds PRIMARY to
    the plain form: "The 'FILE record.name' command will file records
    belonging to more than one output file only in those files where
    PRIMARY has been specified".
  - The record can sit on several output files. The plain form still
    refuses that case, because no sample attests the order of its
    calls. The IN form makes one call, so it has no order.

  [J 02.07.08] 2 a asks that the record be "associated in the
  Environment Description" with the named file. Where it is not, the
  front end prints message 195,00. The generator then refuses the
  shape `FILE record IN a file that is not an output file of the
  record`. No evidence shows what code the 1962 processor made for it.
  The same refusal covers an IN form that names an input file. The
  front end then prints message 22,00, also at severity 3.

  This refusal falls under the question for Jack above. The message
  says "CANNOT FILE RECORD 'NAME.2' IN THIS FILE". Our severity for it
  is 3 (D7.5), and [J 90.04.01] prints no value. At severity 3 the 1962
  processor punched a deck and did not run it ([J 90.04.02]). The case
  is the verbatim deck's case: a listing exists, and no evidence
  describes the deck. His answer decides both refusals.

  The tests:

  - `test/codegen_test.dart` asserts the call on one file and on two.
  - `test/codegen_refusal_test.dart` pins the new refusal.
  - `test/f_corpus_test.dart` moved the pin to statement 139,00.

  **Decided 2026-10-24: `STOP n`. A design decision under D0.4; Jack
  can overturn it.** This is the last item of the list above, and the
  second item done. The generator builds the reading of D2.7, the
  display call alone:

  ```
  TSX    SYS)178,4
  PZE    CP)+a,,CP)+b
  PZE    CP)+c,,CP)+d
  ```

  CP)+a and CP)+b hold the statement stamp, as for STOP RUN (M4-14).
  CP)+c holds ` STOP `. CP)+d holds n, right-justified in six BCD
  characters with blank fill. No close-all and no end-of-job transfer
  follow, so control goes on to the next word. The evidence:

  - [J 90.02.14]: the pool entries hold "the type of STOP (STOP NNN or
    STOP RUN)". The sample attests the STOP RUN words, ` STOP ` and
    ` RUN  `.
  - The form of n is ours. The one numeric pool word of the sample's
    call is the statement number `   199`, right-justified, so n takes
    that form. The display drops the padding (RT-2), so the printed
    line does not depend on it.
  - [J 05.06.04]: "The computer will stop, and hitting the START key
    will cause the object program to continue in execution."

  The SYS)178 handler does not change. It prints the line, for example
  `AT 139,00 STOP 1234`, and returns to the word after the call. Our
  machine has no operator. It takes the halt as a START pressed at
  once, so the run continues with the next statement. This is the
  resume of [F p. 54], "beginning with the next command in sequence".
  Open Question 69 stays open, because J's words do not say where the
  program continues.

  The call empties the register cache, as every subroutine call does
  (M4-9 as amended). A located field after the halt therefore loads
  its base again and takes the SYS)294 guard.

  The generator refuses an n that is not one to six digits, with the
  shape `STOP n where n is not one to six digits`. The parser keeps a
  longer n under message 192,00 at severity 3, and it takes a decimal
  n such as `1.5` with no message. [F p. 54] says "n is an integer",
  and [J 05.06.04] says "any number 6 digits or less". No evidence
  shows what the 1962 processor punched for either form.

  The tests:

  - `test/codegen_test.dart` asserts the call alone, the pool word,
    and the reload after the halt.
  - `test/codegen_refusal_test.dart` pins the refusal of a long and a
    decimal n.
  - `test/runtime/machine_test.dart` runs a program through a halt.
    The line prints, and the statement after the halt runs.
  - `test/f_corpus_test.dart` moved the pin to the fetch of HOURS at
    statement 141,00.

  **Decided 2026-10-25: the external-decimal fetch. A design decision
  under D0.4; Jack can overturn it.** This is the first item of the
  list above, and the third item done. An external-decimal field is
  now an operand of SET, of ADD, and of a numeric comparison. Before
  the first word of the arithmetic, each such field converts into the
  accumulator and parks in a temporary cell:

  ```
  LDI    CP)+n
  STI    SYS)132
  TSX    SYS)182,4
  TXI    SYS)184,1,digits
  STO    TS)k
  ```

  A field of a located record replaces the first two words with the
  three words `CAL BL)n`, `ACL CP)+n` and `SLW SYS)132`, as at LOC 00571
  to 00573 of the 1962 sample. The arithmetic then reads `TS)k` where
  it read the field: `CLA`, `ADD`, `SUB`, `LDQ`, `MPY` or `CAS`. For
  example, `SET NUM = EXT + NUM` compiles to the five words above, then
  `CLA TS)1`, `ADD NUM` and `STO NUM`. The evidence:

  - The convert is the attested form of statement 202,00, the MOVE of
    an external-decimal field to an internal one, at LOC 00571 to 00575
    of the 1962 sample. Only the source pointer is set, and the target
    is a register.
  - [J 90.02.16]: SYS)184 "converts from external decimal to internal
    decimal leaving results in the AC or AC-MQ". The value has the
    scale of the field (RT-4), so the scale rules of the chain do not
    change.
  - [J 90.02.15]: SYS)182 is the entry where "both the Source Pointer,
    SYS)132 and the Target Pointer SYS)133, have been preset by inline
    instructions; or a machine register is used for either or both".
  - [J 90.02.04]: "Temporary Storage cells are generated by the
    Compiler to temporarily store an item", and they "are not
    section-qualified". The 1962 sample reserves 7 cells and addresses
    none (M4-4 as amended). The cells take the `SYM)n` form, and our
    `SYM)n` suffix counts from 1 (`BL)1` is the first word of its
    block). J states no rule for the count. Its one example, `ANA
    TS)1`, is consistent with ours.

  These are the rules of the scope:

  - A SET, one ADD clause, one ADD CORRESPONDING pair, and one numeric
    comparison each open a scope. The clause scope converts the source
    once for all its targets, as the edited source of statement 221
    parks once (amended 2026-10-25). A DO FOR increment block also
    opens a scope (amended 2026-10-25, the DO FOR decision below).
    All the fetches of the scope come before its first word, so no
    convert can overwrite a live accumulator or MQ.
  - One field read two times in a scope converts once and takes one
    cell.
  - A truth function's comparison is inside the scope of its statement,
    so it reads the cells of that statement.
  - The next scope converts again. A field can change between two
    clauses, so a cell never outlives its scope.

  The rejected options:

  - *SYS)181.* Its calling sequence carries the source address in line.
    No listing shows the form, the runtime has no handler for it, and
    the generator declines it at all thirteen sites the manual permits
    (RT-3).
  - *A convert in place.* Where the operand is a `CLA`, the convert
    could leave the value in the accumulator and save two words. Every
    other operand needs a cell all the same. A second form also needs
    an order rule at each site, because a convert overwrites the
    accumulator. One form has no such rule.
  - *A result-storage cell.* The edited ADD source of statement 221
    parks in `RS)n` (catalogue 4.7). [J 90.02.03] gives result storage
    to "the results of a CT statement", and the chain numbers its own
    parks in those cells. The section-0 reservation is 3 cells, a
    constant fitted to the sample. A fetch in `RS)` would share those
    cells with the chain.

  The generator refuses five shapes on this path:

  - `an external-decimal store (M6-9)`, for an external target. The
    store decision below withdraws it.
  - `a subscripted external-decimal operand (M6-9)`. The fetch sets
    SYS)132 from a fixed descriptor, and no sample operand is both
    subscripted and converted.
  - `a temporary cell past the TS) reservation (M4-4)`. An eighth
    field in one scope has no cell.
  - `an external-decimal convert of more than 10 digits (RT-4)`, as
    for the MOVE. The park is one `STO`.
  - `a numeric comparison of unequal scales (no sample instance)`.
    Before it, every unequal pair compiled wrong: `IF FRAC GT NUM`, at
    `9V9` against `999`, compiled to `CLA FRAC / CAS NUM`. The decision
    below withdraws this refusal.

  The tests:

  - `test/codegen_test.dart` asserts the words of a fetch in SET, in a
    product, in ADD, and on each side of a comparison. It also asserts
    the located pointer form, two cells, the reuse of a cell, and the
    reuse in a truth function.
  - `test/codegen_refusal_test.dart` pins the five refusals.
  - `test/runtime/machine_test.dart` runs a program over an
    external-decimal field that holds 4.25. `SET TOT = EXT + 1.50`
    stores 5.75. `EXT GT 4.00` is true, and `EXT GT 4.25` is false.
  - `test/f_corpus_test.dart` moved the pin to the comparison of
    statement 141,00.

  **Decided 2026-10-25: the comparison of unequal scales. A design
  decision under D0.4; Jack can overturn it.** This is the ninth item
  of the list above, and the fourth item done. When the two sides of a
  numeric comparison have different scales, the side of lesser scale
  goes into the accumulator, upscaled by the difference `d`:

  ```
  LDQ    low
  MPY    CP)+n          10**d
  XCA
  CAS    high
  ```

  The skip vector mirrors when the upscaled side is the right operand.
  For example, `IF HRS GT 40` with HRS an external `99V9` compiles to
  the fetch into `TS)1`, then `LDQ` the pooled 40, `MPY` the pooled 10,
  `XCA` and `CAS TS)1`. The less slot is the true outcome. The rule
  covers every pair of names and literals, so `IF FRAC GT NUM` now
  compiles to `LDQ NUM`, `MPY` the pooled 10, `XCA` and `CAS FRAC`. The
  evidence:

  - [J 02.04.07]: "Numeric fields are compared arithmetically without
    regard to length." `CAS` compares two words as integers, so the
    integers must have one scale.
  - The form is the zero build of the 1962 sample, LOC 00656 to 00660
    and 01241 to 01243. Each site upscales the literal 0 into the
    accumulator against a field of scale 2, and the vector reads
    against the literal (catalogue 4.8). Only the `LDQ` operand
    changes.
  - Catalogue 4.7: "A literal enters the pool as its keyed digits,
    never pre-multiplied by an alignment factor", and every site of
    the sample obeys it. The 40 pools as 40 and the 10 as its own
    word.
  - `LDQ` of a field is attested at LOC 00641, `LDQ 1)RATE,1`. A
    field of lesser scale takes the same three words.
  - The sample has no unequal pair because statement 203 keys its
    literal as `40.0`. The 1960 program keys `40`.

  The rejected options:

  - *Fold the literal.* A pool word of 400 saves three words and emits
    no multiply. Catalogue 4.7 and M4-10 reject a folded alignment at
    every attested site.
  - *Downscale the other side.* A divide loses the fraction, and the
    sample never downscales before the store (M4-10).
  - *Refuse a field of lesser scale.* The words are the same words,
    each one attested, and the 1962 processor compiled the shape
    (Jack's rule of 2026-09-14).

  The generator refuses two shapes on this path:

  - `a subscripted comparand that needs upscaling (no sample
    instance)`, for a subscripted side of lesser scale on either side.
  - `an aligned comparand of more than 10 digits (no sample instance)`.
    The `XCA` keeps one word of the product. Past ten digits the value
    needs the AC-MQ pair, which has no comparison form (§8.5 Open
    Question 28).

  The tests:

  - `test/codegen_test.dart` asserts the words for a literal on each
    side, a field against a literal, two fields, and a fetched field.
  - `test/codegen_refusal_test.dart` pins the two refusals.
  - `test/runtime/machine_test.dart` runs `4.5 GT 4`, `4.5 GT 5`,
    `40.0 = 40`, `40.0 GT 40` and `4.5 LT 5`. Without the alignment,
    four of the five give the wrong value.
  - `test/f_corpus_test.dart` moved the pin to the product of
    statement 141,00.

  **Amended 2026-10-25, after the PR 143 review.** The alignment
  admitted a nonzero literal in the accumulator when the scales differ,
  so `IF 4 GT FRAC` compiled and `IF 4 GT NUM` refused. Both compiled in
  1962. A nonzero literal of equal scale now loads with `CLA` of its
  pool word, then `CAS`. The load is the one-term chain of LOC 01215,
  `CLA CP)+10`. M4-11's refusal `a nonzero literal comparand` is
  withdrawn. `test/codegen_test.dart` asserts the words, and
  `test/runtime/machine_test.dart` runs `5 GT NUM`, `5 LT NUM` and
  `4 LT 5`.

  **Decided 2026-10-25: the product of a product. A design decision
  under D0.4; Jack can overturn it.** This is the fifth item of the
  list above, and the fifth item done. When the complex factor of a
  product is itself a product, the inner product finishes in the MQ.
  The next factor then multiplies it with one word and no `XCA`:

  ```
  ...                   the inner product, in the MQ
  MPY    factor
  ```

  For example, `SET FRAC = (FRAC - 4) * NUM * 1.5`, with FRAC at `9V9`,
  compiles to the aligned difference, `XCA`, `MPY NUM`, `MPY` the pooled
  15, and the scaling store tail. The product is at scale 1 + 0 + 1 = 2,
  so the tail divides by 10 with the half-adjust 5. The evidence:

  - [J 02.04.05.01] b: "the expression A*B*C will be taken to mean
    (A*B)*C". F p. 107, rule 4, states the same. So the inner product
    comes first.
  - The one-word step is the step at LOC 01224 to 01225 of the 1962
    sample, `MPY EXEMPTIONS,1` then `MPY CP)+31`. Catalogue 4.7 counts
    the multiplicative step as "1 when the left value is already the MQ
    half". At that site the second word is a scale alignment and not a
    source factor. The word is the same `MPY` onto the MQ.
  - The scale of a product is the sum of the scales of its factors, as
    at every attested product. The value rescales once, at the store,
    through the attested tail with the half-adjust of D4.1. Nothing
    rescales between the two multiplies.

  **The precision.** The second `MPY` reads the MQ alone, so the inner
  product keeps one word, and the high half in the accumulator drops.
  The generator refuses an inner product that can pass 10 digits, with
  the shape `a product of a product past 10 digits (no sample
  instance)`. The count is ours:

  - a field: its declared digits;
  - a literal: the digits of its value;
  - a product: the sum of its factors;
  - a chain of n terms: its widest integer part, plus the chain scale,
    plus the digits of n - 1 for the carry.

  At statement 141,00 the inner product holds at most 4 + 5 = 9 digits.
  The outer product takes no new check, because the store tail also
  keeps one word, as at every attested product. Open Question 28 stays
  open.

  The rejected options:

  - *Park the inner product.* `STQ` to a cell and `LDQ` back costs two
    words and a cell, and the MQ already holds the value.
  - *The `XCA` step of a computed factor.* `XCA` moves the product's
    low half into the accumulator and its high half into the MQ. The
    `MPY` then reads the high half, which is 0, and the result is
    wrong.
  - *Carry the AC-MQ pair.* The double-precision routines of
    [J 90.02.12] and [J 90.02.13] have no call in any listing, and ten
    digits cover the deck.

  The refusal `a product of two computed factors (no sample instance)`
  stays. The deck does not reach it.

  The tests:

  - `test/codegen_test.dart` asserts the words of a nested product, a
    parenthesised one, the shape of statement 141,00, and a truth
    function inside the inner product.
  - `test/codegen_refusal_test.dart` pins the refusal past 10 digits.
  - `test/runtime/machine_test.dart` runs `(HRS - 40) * RATE * 1.5` with
    HRS an external field that holds 45.0. A RATE of 2.505 stores
    18.79, and a RATE of 2.500 stores 18.75. A product that dropped the
    scale of 1.5 would store 187.88.
  - `test/f_corpus_test.dart` moved the pin to the store of statement
    141,00.

  **Decided 2026-10-25: the external-decimal store. A design decision
  under D0.4; Jack can overturn it.** This is the second item of the
  list above, and the sixth item done. A SET or ADD target of external
  decimal takes the SYS)180 skeleton of the edited store (catalogue
  4.6), with one convert step in place of the edit words:

  ```
  ...                   the value, in the accumulator
  TSX    SYS)180,4
  PZE    target,,byte
  TXI    SYS)186,1,digits
  ```

  A value in the MQ takes `XCA` first, in place of the `STQ`. A field
  of a located record takes `MZE BL)n,,CP)+k`, with `CP)+k` the
  displacement constant of the fetch. An ADD target reads the cell of
  its fetch. The evidence:

  - [J 90.02.15]: under SYS)180 the source "is in a machine register",
    and the target pointer is set "in the same manner as SYS)179". The
    sample attests the pair at its 25 edited stores. [J 90.02.14] Case
    2 gives the `MZE` form for a located item; no listing shows it.
  - [J 90.02.18]: each step converts "from internal decimal in the AC
    or AC-MQ".
  - SYS)186 is "unsigned", SYS)187 "overpunch minus" and SYS)188
    "overpunch plus". An external field signs by overpunch alone
    ([J 02.05.05] note 1), and SYS)183 numbers the same three
    conventions. So a pictorial with no sign takes SYS)186, a final J
    to R letter SYS)187, and a final A to I letter SYS)188.

  The two open items: a value of more digits drops its high-order
  digits and arms nothing, as SYS)267 does (RT-5; D4.2), because
  [J 90.02.18] gives no test step. The value rounds in the tail of D4.1
  before the store, and §8.5.4-a stays open.

  The rejected options:

  - *Preset SYS)133, then SYS)182.* [J 90.02.11] permits it, but the
    located preset overwrites the accumulator, so it would have to
    come before the arithmetic. SYS)180 has a located form of its own.
  - *A handler that reads the MQ.* No word of the call names the
    register, and RT-5 reads the accumulator alone.
  - *Park and reload.* Two words and a cell, where `XCA` is one word.

  The refusals: `an external-decimal DO FOR index (M6-9)` and `an
  external-decimal subscript variable (M6-9)`, because the store
  changes the fitted run of M4-6; `an ADD clause that names an
  external-decimal field twice (no sample instance)`, because a cell
  would go stale; `an external-decimal store of more than 10 digits
  (RT-4)`; and `an external-decimal store into an S position (RT-4)`.
  The DO FOR decision below withdraws the first.

  The tests: `test/codegen_test.dart` asserts the words,
  `test/codegen_refusal_test.dart` pins the five refusals, and
  `test/runtime/movpak_test.dart` runs each step and the `MZE` sum.
  `test/runtime/machine_test.dart` runs the shape of statement 141,00,
  then `ADD GROSS TO GROSS`: the field reads `0003758`. A minus field
  reads `27N`, a plus field `52E`, and a fetch reads -2.75 back. A
  located field, read from a tape, takes the `MZE` store and reads
  `07P` in the buffer.
  `test/f_corpus_test.dart` moved the pin to the store of statement
  142,00, which the next decision takes.

  **Decided 2026-10-25: the scaling store of a chain value. A design
  decision under D0.4; Jack can overturn it.** This is the tenth item
  of the list above, and the seventh item done. A value in the
  accumulator at a scale above the target's takes the scaling tail of
  D4.1 without its `XCA`:

  ```
  ...                   the chain, in the accumulator
  ACL    half           omitted under TRUNCATED
  LRS    35
  DVP    10**d
  STQ    target         or XCA and the SYS)180 store
  ```

  Statement 142,00 divides by 10 with the half-adjust 5. A one-term
  chain takes the same words. The evidence:

  - The `XCA` of LOC 00631 moves the product's low half into the
    accumulator. A chain already ends there (M4-10), as `CLA RS)1 /
    SUB RS)0` at LOC 00625 to 00626 shows.
  - `LRS 35 / DVP` on a value in the accumulator, with no `XCA`, is
    attested at LOC 00423 to 00425 on `CLA 5)NETPAY`.
  - D4.1: a SET rounds and TRUNCATED drops the `ACL` alone. `ACL` adds
    to the magnitude, so a negative chain rounds away from zero, as a
    product does.
  - The four words are the product's words after its `XCA`, so the
    tail adds no bound the product path lacks.

  The rejected options:

  - *`ADD half`.* It moves a negative value toward zero, so -2.485
    stores -2.48. Every attested half-adjust is `ACL`.
  - *`XCA`, then the tail as printed.* Two words that cancel.
  - *Rescale each term before the sum.* Each divide loses fraction
    digits. [F p. 115] defines ROUND on "a number", and we read that
    number as the result, not its terms.

  The refusal `a store below the target scale (no sample instance)`
  stays.

  The tests: `test/codegen_test.dart` asserts the words.
  `test/runtime/machine_test.dart` stores 3.505 as 3.51, 3.504 as 3.50
  and -2.485 as -2.49, internal and external. `test/f_corpus_test.dart`
  pins the next stop: statement 144,00, `DO SEARCH FOR INDEX = 1(1)12`,
  refuses `an external-decimal DO FOR index (M6-9)`.

  **Decided 2026-10-25: the external-decimal DO FOR index. A design
  decision under D0.4; Jack can overturn it.** This is the eleventh item
  of the list above, and the eighth item done. The loop of M4-13 keeps
  every word that does not touch the index. The four that do change,
  and one word is added:

  - Each `STO` of the index becomes the external-decimal store.
  - The `CLA` of the index becomes a fetch into `TS)1`, then
    `CLA TS)1`.
  - The `SUB` of the index reads `TS)1`.
  - The added word is the park, `STO TS)1`.

  ```
  AXT    GN)a,4
  SXA    P,4
  CLA    CP)+p
  TSX    SYS)180,4      the store of p
  PZE    index,,byte
  TXI    SYS)186,1,digits
  CLA    table-base
  STO    PI)1
  TRA    P+1
  GN)a   LDI CP)+n      the fetch of the index
  STI    SYS)132
  TSX    SYS)182,4
  TXI    SYS)184,1,digits
  STO    TS)1
  CLA    TS)1
  ADD    CP)+q
  STO    TS)1           the park of i + q
  TSX    SYS)180,4      the store of i + q
  PZE    index,,byte
  TXI    SYS)186,1,digits
  CLA    stride
  ADD    PI)1
  STO    PI)1
  CLA    CP)+r
  SUB    TS)1
  TPL    GN)b
  ```

  The loop holds 21 + 5·M words, where the internal loop holds 11 + 5·M.
  A minus or plus overpunch takes SYS)187 or SYS)188, as for every
  store. The evidence:

  - The loop is LOC 00702 to 00721 of the 1962 sample. Only the words
    that read or write the index change, and the park is added.
  - The fetch and the store are the two decisions above, unchanged. The
    increment block is one fetch scope. The scope opens at the block's
    head, so the back edge enters on the convert.
  - [J 02.04.05] #6 converts operands of any format "in all cases",
    and message 206,00 calls the format inefficient, not illegal. The
    converts are that inefficiency.
  - The M4-6 name run does not change. The table-base EQU heads the
    block, and the body-entry EQU stands before the `TRA`, so both
    fitted placements hold. Only the words between them grow.

  **The park.** The stride words use the accumulator between the store
  and the exit test. So the stepped value parks in `TS)1` before the
  store, and the test reads the cell. Without the park, the `SUB`
  would read the field's characters as a binary word.

  The rejected options:

  - *A fetch before the exit test.* Five words where one does, and the
    field cannot change between the store and the test.
  - *A convert in place.* It saves two words. The fetch decision keeps
    one form at every site.
  - *A cell that lives across passes.* The body can write the index,
    and a cell never outlives its scope.
  - *Keep the refusal.* The 1962 processor compiled the shape (Jack's
    rule of 2026-09-14).

  The open item: SYS)186 has no test step, so a `99` index that steps
  past 99 drops its high digit in the field. The test reads the cell
  and exits all the same.

  The refusal `an external-decimal subscript variable (M6-9)` stays. It
  fires on a MOVE into the index, inside the loop body or outside it,
  and the deck has none. A SET or ADD into the index does not reach it,
  because neither recomputes an indicator (codegen defect 9,
  `docs/HANDOVER.md`). The loop checks the index as a store target
  first, so an index of more than 10 digits refuses before the loop's
  first word.

  The tests: `test/codegen_test.dart` asserts the words, the convert
  under the increment label, and SYS)187 for a `9R` index.
  `test/codegen_refusal_test.dart` pins the long index.
  `test/runtime/machine_test.dart` runs a loop 1(1)12 over an
  external `99` index. The body runs 12 times, and the index reads
  `13`. `test/f_corpus_test.dart` pins the next stop. Statement 144,00
  refuses `a DO FOR driving two indicators (M4-6; no sample
  instance)`, because statement 166,00 subscripts RATE,
  INSURANCE.PREM and RETIREMENT.PREM by INDEX.

  **Decided 2026-10-25: the DO FOR driving several indicators. A
  design decision under D0.4; Jack can overturn it.** This is the
  twelfth item of the list above, and the ninth item done. A loop
  whose index subscripts M names now steps M indicators. Each
  indicator takes the sample's words for its one indicator, repeated
  in indicator order. For M = 2, internal index:

  ```
  GN)b1  EQU CP)+x       the base of the first indicator
  GN)b2  EQU CP)+y       the base of the second
  AXT    GN)a,4
  SXA    P,4
  CLA    CP)+p
  STO    index
  CLA    GN)b1
  STO    PI)1
  CLA    GN)b2
  STO    PI)2
  GN)e   EQU P+1
  TRA    P+1
  GN)a   CLA index
  ADD    CP)+q
  STO    index
  CLA    stride1
  ADD    PI)1
  STO    PI)1
  CLA    stride2
  ADD    PI)2
  STO    PI)2
  CLA    CP)+r
  SUB    index
  TPL    GN)e
  ```

  The loop holds 11 + 5·M words, the count of the notes. The rules:

  - **The words.** Each indicator takes `CLA base / STO PI)n` in the
    prologue and `CLA stride / ADD PI)n / STO PI)n` in the increment
    block, the attested 00706 to 00707 and 00714 to 00716. M = 1 is
    unchanged.
  - **The order.** Indicator order is `PI)` order, the order of first
    reference. The prologue, the increment block and the EQU lines
    follow it.
  - **The names.** The run is 3 + 2·M names:
    - one unbound name;
    - the body-entry EQU;
    - the increment block;
    - one pair per indicator, the first name unbound and the second
      bound to the base.

    For M = 1 that is the fitted run 084 to 088 of M4-6. Both
    groupings of the notes give the same DO FOR run, so the extension
    does not choose between them.
  - **The EQU lines.** Every table-base EQU heads the block, as the
    subscript store prints its two EQUs ahead of its blocks.
  - **The pool.** Each indicator takes its own base, `PZE NAME+0`.
    Fields of one table share one stride entry (the keying rule).

  The evidence: [J 02.04.07] gives each unique subscripted name its own
  positional indicator, and [J 02.04.07.01] updates every indicator
  whose subscript changes. M4-13 already adds "the stride to each
  affected positional indicator". Only the name run was open.

  The rejected options:

  - *Reverse first-reference order,* as the subscript store walks its
    indicators (M4-6). That order is fitted to one site. Both orders
    give correct code.
  - *One name per extra base, with no unbound name.* The run then
    differs in shape from the attested pair of the subscript store.
  - *A direct `CLA CP)+n` for each extra base.* All three attested base
    references go through an EQU name.
  - *Keep the refusal.* The 1962 processor compiled the shape (Jack's
    rule of 2026-09-14), and [J 02.04.07] states the indicators.

  **The stride of part of a word is refused, not built.** Codegen
  defect 7 stepped an 11-character element by one word and gave no
  message. `_strideWords` now refuses `a table stride of 11
  characters, not a whole number of words (M6-9)`, in the loop and in
  the subscript store. Wrong code becomes a refusal. The design of the
  stride needs its own decision, for three reasons:

  - [J 02.04.07] says a positional indicator holds "the location (word
    and byte)". The attested step is one `ADD` of a word count. An
    11-character stride is one word and five bytes, and an `ADD` of a
    byte count into the decrement carries nothing into the address. A
    test-and-adjust sequence has no attested form.
  - The internal comparison form `LAC PI)n,r / CAS 0,r` reads a
    whole word. The external comparand of 166,00 still refuses.
  - The one attested base of a field inside a word is `PZE RETPREM-2`.
    Its zero decrement is the 1962 defect of M6-4 finding 1, so the
    only evidence on the byte of a base is wrong code.
    INSURANCE.PREM sits at byte 5 and RETIREMENT.PREM at byte 2.

  The rejected options for the stride:

  - *Round the stride up to two words.* [J 02.05.04] D.2 packs an
    unjustified field "immediately to the right" of the one before, so
    element 2 starts at word 1, byte 5. Two words would read the wrong
    characters from element 2 on.
  - *Keep the truncation.* It is defect 7: silent wrong code.

  No refusal is added for a base inside a word: it would fire on
  `PZE RETPREM-2` in the sample.

  **Amended 2026-10-25.** The stride decision below builds the stride
  in the loop. The refusal stays for the subscript store.

  The tests: `test/codegen_test.dart` asserts the words for two
  tables, and for three fields of one table with one stride entry.
  `test/codegen_refusal_test.dart` pins the stride refusal in a loop
  and in a subscript store. `test/runtime/machine_test.dart` loops
  1(1)12 over a table of three whole-word external fields, k, 100 + k
  and 200 + k. Each pass reads element k through each indicator, so
  each count reads 12 and the sums read 78, 1278 and 2478.
  `test/f_corpus_test.dart` pins the next stop. Statement 144,00 now
  refuses the stride of TABLE.ITEM, 11 characters.

  **Decided 2026-10-25: the stride of part of a word. A design
  decision under D0.4; Jack can overturn it.** This is the seventh item
  of the list above, and the tenth item done. A DO FOR now steps an
  indicator by a stride that is not a whole number of words. The step
  carries the byte into the word. Each such indicator takes six words
  in the increment block, where a whole-word stride takes three:

  ```
  CLA    stride         PZE 1,,5 for 11 characters
  ADD    PI)n
  SUB    CP)+k          OCT 000005777777, 6·2^18 − 1
  TPL    *+2
  ADD    CP)+k
  STO    PI)n
  ```

  The prologue sets the indicator from a base that carries the field's
  byte. For TABLE.ITEM the bases are `PZE RATE+0,,0`,
  `PZE INSURANCE.PREM+0,,5` and `PZE RETIREMENT.PREM+0,,2`. A
  whole-word stride keeps the sample's words and its `NAME+0` base.

  **The indicator form.** An indicator is the MOVPAK pointer itself:
  the word in the address field and the byte in the decrement. The
  evidence:

  - [J 02.04.07] says a positional indicator holds "the location (word
    and byte)".
  - LOC 01445 to 01446 of the 1962 sample copy `PI)2` into SYS)132
    with `LDI` and `STI`, and add nothing. So the indicator has the
    form of the pointer.
  - [J 90.02.11] gives SYS)132 as `PZE LOC,,BYTE`, and the sample's
    `PZE INS.PREM,,3` prints the byte in the decrement.

  **The carry.** The decrement sits above the address, so the word is
  `byte·2^18 + word`. The rules:

  - The `ADD` of `PZE 1,,5` adds 5 to the byte and 1 to the word. Only
    the carry is missing.
  - The `SUB` of k leaves `(byte − 6)·2^18 + word + 1`. The address is
    below 2^15, so the value is positive exactly when the byte reached
    6. It is then the carried pointer: the byte less 6, the word plus 1.
  - When the value is negative, the `ADD` of k restores the sum. The
    value is never zero, so the sign of zero does not matter.
  - The byte stays below 11, so one carry is always enough.

  The sequence uses only attested opcodes: `TPL` at the exit test of
  LOC 00721, `*+n` at LOC 01413. The sequence itself has no listing.

  **The readers.** A subscripted external-decimal operand of a
  comparison or an ADD now converts through its indicator into a
  temporary cell:

  ```
  LDI    PI)n
  STI    SYS)132
  TSX    SYS)182,4
  TXI    SYS)184,1,digits
  STO    TS)k
  ```

  These are the words of LOC 01445 to 01450, the subscripted MOVE
  source, with the park of the fetch decision in place of the store.
  The handler reads characters from the pointer's byte, so a reader
  through a descriptor reads any stride. The arithmetic then reads the
  cell. The fetch decision's refusal `a subscripted external-decimal
  operand (M6-9)` stays for SET, because the chain has no subscripted
  operand form.

  These answer the three reasons of the DO FOR decision above:

  - The step carries in three words of attested opcodes.
  - The external comparand reads through a descriptor, not through
    `LAC PI)n,r / CAS 0,r`.
  - The base carries its byte. The 1962 subscript store drops it
    (M6-4 finding 1), and that site keeps its words.

  The rejected options:

  - *Recompute the indicator from the index.* `LDQ`, `MPY` by 11,
    `DVP` by 6, `ALS 18` and `ORS` give the same pointer in 11 words.
    The loop then gives up the attested step of LOC 00714 to 00716.
  - *A `CAS` vector for the carry.* It takes four words more for the
    same pointer.
  - *A runtime that takes a byte past 5.* [J 90.02.11] gives the byte of
    SYS)132 as "(0-5)".
  - *Drop the base byte, as the 1962 subscript store does.* That is a
    defect at one site, and the DO FOR has no listing that repeats it.
    INSURANCE.PREM would then read RATE's last character.

  The open items: the prologue sets each indicator to element 1 for any
  p, and the step adds one stride for any q. The deck is `1(1)12`, so
  neither changes its code. Both are older than this decision.

  The refusals:

  - `a whole-word read of an element whose stride is 11 characters
    (M6-9)`, for an internal comparand through `LAC PI)n,r`. The `CAS
    0,r` reads the word and drops the byte.
  - `a table stride of 11 characters, not a whole number of words
    (M6-9)` stays for the subscript store, which multiplies a word
    count. The deck has no MOVE into INDEX.
  - `an external-decimal field read with and without its subscript (no
    sample instance)`, because one cell serves an item in a scope.

  The tests:

  - `test/codegen_test.dart` asserts the step words, the pool words
    and the reader words, and gives two tables different strides.
  - `test/codegen_refusal_test.dart` pins the three refusals.
  - `test/runtime/machine_test.dart` loops 1(1)12 over the deck's six
    TABLE rows. Each pass compares RATE, INSURANCE.PREM and
    RETIREMENT.PREM of item k with a whole-word copy, so each count
    reads 12. The bytes run 0, 5, 4, 3, 2, 1, so the carry fires at
    exactly 6 and past it. The two ADD sums read the row totals.
  - `test/f_corpus_test.dart` pins the next stop. Statement 145,00
    refuses `an arithmetic operand of edited (no sample instance)`,
    because its SET target PAYRECORD NETPAY is edited. Statement
    166,00, the readers above, comes later in the text.

  **The run.** Chunk 2b runs the applied deck over two tapes written
  from the sample's own source table in the corpus's layouts (M6-1 as
  amended). It diffs values and not bytes, and M6-1 as amended names
  the columns that can be compared.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 21]: ../../comtran-manuals/F28-8043/02-language-structure.md#arithmetic-expressions
[F p. 42]: ../../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F p. 43]: ../../comtran-manuals/F28-8043/03-procedure-description.md#editing-feature
[F p. 54]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-named-end
[F p. 65]: ../../comtran-manuals/F28-8043/04-data-description.md#data-description-format
[F p. 76]: ../../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 87]: ../../comtran-manuals/F28-8043/a1-programming-example.md#appendix-1-programming-example
[F p. 100]: ../../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F p. 101]: ../../comtran-manuals/F28-8043/a1-programming-example.md#sample-payroll-program---machine-listing
[F p. 107]: ../../comtran-manuals/F28-8043/a2-supplementary-information.md#rules-for-forming-arithmetic-expressions
[F p. 115]: ../../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[J 02.01.01]: ../../comtran-manuals/J28-6169/02-compiler.md#0200-introduction
[J 02.01.02]: ../../comtran-manuals/J28-6169/02-compiler.md#a-cmple-card
[J 02.02.01]: ../../comtran-manuals/J28-6169/02-compiler.md#b-finish-card
[J 02.03.03.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-effect-of-data-storage-mode-on-arithmetic-efficiency
[J 02.04.05]: ../../comtran-manuals/J28-6169/02-compiler.md#4-corresponding-option-with-move-and-add
[J 02.04.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.06]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.07]: ../../comtran-manuals/J28-6169/02-compiler.md#c-conditional-statements
[J 02.04.07.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.02]: ../../comtran-manuals/J28-6169/02-compiler.md#1-record
[J 02.05.04]: ../../comtran-manuals/J28-6169/02-compiler.md#6-param-and-funct
[J 02.05.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.06.07]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.07.04]: ../../comtran-manuals/J28-6169/02-compiler.md#6-record-types
[J 02.07.08]: ../../comtran-manuals/J28-6169/02-compiler.md#1-forms-of-the-command
[J 05.06.01]: ../../comtran-manuals/J28-6169/05-systems-operation.md#d-file-maintenance
[J 05.06.04]: ../../comtran-manuals/J28-6169/05-systems-operation.md#b-loader-1
[J 90.01.02]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.03]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.03]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.04]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.10]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.11]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.12]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.13]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.15]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.16]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.18]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.19]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.30]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.04]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.04.01]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#error-messages-and-severity-codes
[J 90.04.02]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#a-error-messages
[J 90.05.02]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description
[J 90.05.03]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description-1
