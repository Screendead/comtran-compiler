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
  2 was (Jack's call of 2026-08-09), and M6-6 to M6-8 hold the chunks.
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
     then adds 40 hours of pay to whatever the detail record carried
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
  the date, the hours and the bond deduction. Every ERRORFILE line and
  the BONDORDERFILE line check too. Gross pay, the
  withholding tax and the FICA deduction check on the five lines where
  the hours are exactly 40.0 and on no other line. No department total
  and no grand total checks, because each one sums the lines above it.

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

  The transcription's note is an erratum candidate. It describes a
  printer practice that does not exist, and a later reader who trusts
  it will misread the page. The conversion is read-only, so the note
  waits for Jack's authorization (`docs/HANDOVER.md`).

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
  listing at [F p. 101] to p. 104: 187 source cards and two division
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
    quote marks and an empty continuation column, on the form (F p.
    100) and in the listing alike. The §9.8 row that read them as one
    continued literal is corrected. The conversion's note that reads
    them the same way is an erratum candidate (`docs/HANDOVER.md`).

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
  INDEX in the SEARCH sentence, statement 165,00, and no other message,
  and it closes SEVERITY LIMIT WAS NOT REACHED. Two details of the
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
  2. The CALL row is demanded. [J 02.04.05] #5: "The (old.name) in a
     CALL statement must be unique and may not be subscripted."
  3. The STOP row was wrong, and the deck is corrected. `STOP n` is
     attested legal: [J 05.06.04] a says the computer stops, and the
     START key resumes the object program. SYS)178 carries "the type of
     STOP (STOP NNN or STOP RUN)" ([J 90.02.14]), and D2.7 implements
     both forms. Message 175,00 fires on the absence of STOP RUN, which
     [J 02.04.06] #9 requires in each program. The 1962 repair
     therefore adds `STOP RUN` after `STOP 1234`. It replaces nothing.
     `test/fixtures/f-payroll-j.ctd` punches both cards and holds 216
     cards, and the three 206,00 messages move to statement 166,00.
  4. The COPY row is demanded. [J 90.01.03] b.i defers COPY. The hand
     expansion reconstructs the 1960 intent under the [F p. 76] rule,
     and it matches what the 1962 sample wrote out. No 1962 program
     equals it.
  5. The REDEF row is demanded. [J 02.05.02]: "When the REDEF type code
     is used, it should appear on a line with no additional coding
     except a serial number and the name of the item being redefined."
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
     register through SYS)181 or SYS)182 ([J 90.02.14]). SYS)184
     converts it ([J 90.02.16]). A store writes it back through
     SYS)180 with SYS)186, 187 or 188 ([J 90.02.18]). The sample
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
     REORDER.POINT`. F pp. 105 and 106 formalise it. [J 02.04.06]
     states six field rules and no grammar, and [J 02.04.05.01] b heads
     its precedence table with TR, a condition inside an expression.
     Definition §5.3.2 lists J's tightenings, and operand shape is not
     among them. The sites are statements 152,00 and 156,00 of the
     applied deck, and the refusal is the default arm of the numeric
     comparison.
  5. **A product of a product.** [J 02.04.05.01] b: "the expression
     A*B*C will be taken to mean (A*B)*C". F p. 107 rule 4 states the
     same. The site is statement 141,00. Above 40 hours the 1962 sample's
     `(WORKING HOURS * 1.5 - 20) * MASTER RATE` folds the 1960
     program's two sentences (definition §9.8). It avoids no shape.
     Open Question 28 asks about intermediate precision in the
     generated code, not about legality.
  6. **An edit run that drops high-order digits.** [F p. 42]: "Such
     alignment may involve the dropping of leading digits or low-order
     digits". F p. 43 works a row: `99999` holding `01234` into
     `999V9` gives `2340`. SYS)190's package counts characters to test
     for overflow and characters to bypass ([J 90.02.19]). At run time
     SYS)130 records "the truncation of significant high order values
     (i.e. overflow)" ([J 90.02.10]). Definition §8.5.4-b holds
     the same reading. The site is statement 146,00, `$88889.99-` into
     `$***9.99`. The refusal is the edit-step builder, and its comment
     says the manual's two bypass counts cannot be told apart. The
     SYS)190 notes on
     `comtran-manuals/J28-6169/images/page-158.png` may distinguish
     them, and nobody has measured that page. The code and the comment
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
  so nothing in the repository waits on the answer.

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
  - `STOP n` at run time: the halt and the resume (Open Question 69).

  **The run.** Chunk 2b runs the applied deck over two tapes written
  from the sample's own source table in the corpus's layouts (M6-1 as
  amended). It diffs values and not bytes, and M6-1 as amended names
  the columns that can be compared.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 21]: ../../comtran-manuals/F28-8043/02-language-structure.md#arithmetic-expressions
[F p. 42]: ../../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F p. 65]: ../../comtran-manuals/F28-8043/04-data-description.md#data-description-format
[F p. 76]: ../../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 87]: ../../comtran-manuals/F28-8043/a1-programming-example.md#appendix-1-programming-example
[F p. 101]: ../../comtran-manuals/F28-8043/a1-programming-example.md#sample-payroll-program---machine-listing
[J 02.01.01]: ../../comtran-manuals/J28-6169/02-compiler.md#0200-introduction
[J 02.01.02]: ../../comtran-manuals/J28-6169/02-compiler.md#a-cmple-card
[J 02.02.01]: ../../comtran-manuals/J28-6169/02-compiler.md#b-finish-card
[J 02.03.03.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-effect-of-data-storage-mode-on-arithmetic-efficiency
[J 02.04.05]: ../../comtran-manuals/J28-6169/02-compiler.md#4-corresponding-option-with-move-and-add
[J 02.04.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.06]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.02]: ../../comtran-manuals/J28-6169/02-compiler.md#1-record
[J 02.07.04]: ../../comtran-manuals/J28-6169/02-compiler.md#6-record-types
[J 02.07.08]: ../../comtran-manuals/J28-6169/02-compiler.md#1-forms-of-the-command
[J 05.06.01]: ../../comtran-manuals/J28-6169/05-systems-operation.md#d-file-maintenance
[J 05.06.04]: ../../comtran-manuals/J28-6169/05-systems-operation.md#b-loader-1
[J 90.01.02]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.03]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.10]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.16]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.18]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.19]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.30]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.04]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.04.01]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#error-messages-and-severity-codes
[J 90.04.02]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#a-error-messages
[J 90.05.02]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description
[J 90.05.03]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description-1
