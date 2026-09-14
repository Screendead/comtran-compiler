# Evidence

Three files. Each is copied from branch `m6s2-rule` of the repository, at the
path named below, on 2026-09-14. Each is working material for one item of the
record, not an authority of its own. Every manual quotation in the record was
re-read in the conversion under `comtran-manuals/` before it was printed.

| File | Source path | What it is, and which item uses it |
|---|---|---|
| `f-payroll-listing-diagnostics.txt` | `test/goldens/f-payroll.listing`, lines 205 to 276 | The diagnostic block the verbatim 1960 deck draws: 55 messages of 12 kinds, their severities, and the closing `SEVERITY LIMIT WAS NOT REACHED`. Item 2 rests on it. No severity in the block is 5, which is the only value that suppresses an object deck (J 02.01.01). |
| `applied-deck-stop-cards.txt` | `test/fixtures/f-payroll-j.ct`, lines 150 to 162 | The generated text mirror of the applied deck around END.OF.RUN, showing `STOP 1234.` and `STOP RUN.` on consecutive cards. Item 4 rests on it. The mirror is derived from the canon deck `f-payroll-j.ctd` (decision D0.5). |
| `f-payroll-j-listing.diff` | `git diff origin/master...m6s2-rule -- test/goldens/f-payroll-j.listing` | The golden change the STOP correction causes: one new statement at 139,00, every later statement renumbered by one, and the three 206,00 messages moved from 165 to 166. Item 4 rests on it. |
