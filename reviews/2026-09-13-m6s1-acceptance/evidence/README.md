# The evidence directory

Four files. Two are the primary sources the acceptance diff compares, one holds
the scan measurements, and one is the brief the record was written from.

## `90.05-report-page-217.txt`

Our reading of the printed report, PDF p. 217, copied from
`test/fixtures/90.05-report-page-217.txt` at commit `d5dd932`. It holds the four
reports the page prints, in the form `comtranc --run --list-tapes` prints them
and in the order of the `*FILE` cards. The page pastes the four blocks in a
layout of its own, two of them side by side, and that layout is no print order.

The reading follows the baselines of the skewed print, not the rows of the
transcription. Item 2 of the record holds the evidence and the erratum request.
Its CHECKFILE block holds the three checks the page prints. Nothing in it stands
for the eight the page omits.

## `90.05-payroll.report`

The report our run prints, copied from `test/goldens/90.05-payroll.report` at
commit `d5dd932`. `test/runtime/machine_test.dart` proves the run prints it,
byte for byte. `test/acceptance_test.dart` compares it with the reading above.

The two files differ in exactly two places, and the record holds both: the
grand-total net pay (item 4) and one letter of the bond order (item 5). The
golden also holds the eight checks the page omits.

## `results.txt`

The residuals of the column measurement, written by `tools/scan/measure.py`.
Each line names a block, an item on the page, the ink run in pixels, the column
that run measures to, the column the record layout gives it, and the difference.

The file holds the residuals only. The fitted pitch and origin of each block
come from the grid fit in `tools/scan/measure.py`, and item 7 of the record
prints them. Run the scripts to reproduce the fit.

## `brief.md`

The content brief the record was built from, left exactly as written on
2026-09-13. It carries the title, the provenance rule, the seven items with
their statuses, the evidence for each, the rejected options with their
consequences, and the recommendations. It uses agent-to-agent phrasing and it
was not tidied for a reader.

One of its page references is wrong, and the record corrects it. The brief puts
the compiled lookup at LOC 01421 to 01432 on "PDF p. 214 or 215". The listing
prints it on PDF p. 213, under the page marker at
`comtran-manuals/J28-6169/90.05-sample-program.md:1614`. The crop and the
caption of item 3 name p. 213.
