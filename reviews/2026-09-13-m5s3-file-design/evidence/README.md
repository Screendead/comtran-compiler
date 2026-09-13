# The evidence directory

Three files. Two are pages of a published manual, and one is the brief the
record was written from.

## `c28-6100-2-printed-p16.png` and `c28-6100-2-printed-p17.png`

Two pages of the published 7090 IOCS manual, C28-6100-2, at PDF pages 24 and 25.
The printed page number is the PDF number less 8. The manual has no text layer,
so the record quotes these pages from the images.

Printed page 16 carries the WRITE calling sequence and the three numbered rules
of the READ discussion. Rule 3a is the end-of-buffer sentence that item 4
records as an open gap: a zero switch truncates the buffer and moves to the next
one, which would split a record. The two crops of the record are cut from this
page.

Printed page 17 is the HISTORY RECORDS page. It is the evidence for one sentence
of item 1: at each exit from the READ or WRITE routines the accumulator holds a
history word. No compiled word of the sample reads it, so the runtime does not
write it.

The manual is an external period source. It was downloaded from bitsavers, and
the language definition already cites it under Open Questions 45, 46 and 50. It
is **not** the sealed 1963 archive of D0.9, which is the recovered Commercial
Translator source and runtime library. Nothing from that archive was read for
this record.

## `brief.md`

The content brief the record was built from, left exactly as written on
2026-09-13. It carries the opening block, the five items with their statuses,
the evidence for each, the rejected options with their consequences, and the
recommendations. It uses agent-to-agent phrasing and it was not tidied for a
reader. It was corrected once, on 2026-09-13, after an adversarial review of
the branch: SYS)296 is a pointer word inside SYS)292 rather than a second
card-file terminator, the compiler's diagnostic for a record longer than
BLOCKSIZE is message 5,00 at severity 4, and the lister prints only a file the
run opened. The record carries all three.
