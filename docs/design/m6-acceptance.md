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
  listing at [F p. 101] to p. 104: 187 source cards between `*COMPILE LIST`
  and `*FINISH`. That listing prints card columns 7 to 72 the way the
  1962 listing does, and every column was measured on the scan
  (CLAUDE.md section 9). `test/fixtures/f-payroll-deck-notes.md` holds
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

  Three observations, none a defect:

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

- **M6-7. The applied deck takes the rows of §9.8 that the front end
  requires, and no other. Ours.** `test/fixtures/f-payroll-j.ctd` is
  the 1960 program with five divergences applied. Each is a row of the
  §9.8 table, and each is a change the 1962 front end demands. The
  five:

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
    WORKING area of internal fields, the way the 1962 sample does; a
    dedicated error record and plain FILE; 24 per-field constants;
    explicit MOVEs where the qualifier chains differ; INDEX in WORKING.
    The 1960 records and flow stay. Two shapes stay unbuilt even so:
    the year-to-date fields of the 1960 master are external, so their
    update from WORKING needs the internal-to-external move, SYS)186;
    and the check amount's edit run. The course inside B that needs
    neither is the sample's own: retype the master's numerics IR and
    make MASTER.FILE binary. The check amount then comes from an
    internal source, the attested shape.

  B is the course, in the sample's own form. Three facts leave one
  option open (CLAUDE.md section 12). The roadmap's words are B, "with
  the documented F/J divergences applied". The 1962 sample applied the
  same rows to the same program, so every replacement is attested. And
  A has no oracle for any of its shapes: each is a design with no
  listing behind it, and it belongs to a stage of its own, which
  `docs/HANDOVER.md` parks. Two rows still need adding to §9.8 when
  chunk 2b applies them: the overtime formula, which the sample
  rearranged to `(HOURS * 1.5 - 20) * RATE`, and the master's typing,
  IR fields in a binary file. Under B the table items are two whole
  words, so the RET = INS defect reproduces by the same word-granular
  rule, and the sample's report becomes a value-level oracle for the
  corpus (M6-4). Under A the 11-character items meet defect 7 instead.
  The review record holds the rejected courses and their costs.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 76]: ../../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 87]: ../../comtran-manuals/F28-8043/a1-programming-example.md#appendix-1-programming-example
[F p. 101]: ../../comtran-manuals/F28-8043/a1-programming-example.md#sample-payroll-program---machine-listing
[J 05.06.01]: ../../comtran-manuals/J28-6169/05-systems-operation.md#d-file-maintenance
[J 90.01.03]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.30]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.05.02]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description
[J 90.05.03]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description-1
