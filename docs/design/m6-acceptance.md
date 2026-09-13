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

  The columns were measured on the scan, not read off the
  transcription (CLAUDE.md section 9). The page was rotated 1.83
  degrees to take the skew out, and the character pitch was fitted per
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
  2.01 fixes 141.99. The rest is chosen, and each choice is the least
  value that prints the page: 0.00 for a FICA year to date the cap
  never reaches, 20.50 for WOO's accumulation, 18.75 and 0.00 for the
  denomination and accumulation of the three who deduct and order
  nothing, and zero or blank for every field the report never prints.
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
     so 01333 read address zero. The page prints the number, so the
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

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02.30]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.05.02]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description
[J 90.05.03]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description-1
