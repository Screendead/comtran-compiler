# 2026-09-13 · M5 stage 3, FILE: the design and the delivery plan

Stage 3 gives the 1962 payroll sample its FILE. The record holds the design of
the IOC)9 handler, the buffer every file now takes, the lister that prints a BCD
tape as the 1962 printer did, and the plan that delivers them. The date of the
evidence is 2026-09-13. Every repository link points at commit `b9e95a4`, the
head of branch `m5s3-file`.

Five items. Three are DECIDED under the CLAUDE.md section 12 standing rule:
IOC)9 as the IOCS WRITE routine, one buffer per file above the program with the
close writing the last block, and the lister. Two are SETTLED: the end-of-buffer
gap between the published IOCS manual and J's own blocking, and what stage 3
does not build with the delivery plan. No item waits for Jack. Silence lets each
one stand, and he can overturn any of them.

The record was built after the code landed. The design entries were written
first, the code was implemented against them by a worker, and the record was
built from both in one autonomous run. No review document existed before the
code, which is the route section 12 opens for a decision with one viable option.

Stage 3 lands as one pull request on branch `m5s3-file`. It changes files under
`lib/`, so it merges on external-review convergence. Opening it is under Jack's
standing authorization of 2026-08-16.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone: the four crops are embedded, so it needs no network and no server. Open it anywhere. |
| `tools/build_doc.py` | Writes `index.html`. Edit this, not the HTML. |
| `crops/` | The four images the record shows. |
| `evidence/` | The two IOCS manual pages the record cites, and the content brief it was built from. `evidence/README.md` says what each one is. |

`tools/build_doc.py` builds every repository link from one commit hash at the top
of the file, commit `b9e95a4`. Set `RECORD_HEAD` in the environment to rebuild
against another. A record outlives the branch it was written beside, so no link
may point at a branch.

There are four crops. `crops/j-90-05-report-checkfile.png` is the CHECKFILE part
of the printed report, cut from
`comtran-manuals/J28-6169/images/page-217.png`; item 3 rests the
carriage-control rule on it. `crops/j-90-05-04-payfile-blocking.png` is the
PAYFILE blocking note, cut from `comtran-manuals/J28-6169/images/page-191.png`,
the scan of J 90.05.04; items 1 and 4 rest the packing rule on it.
`crops/iocs-p16-write.png` and `crops/iocs-p16-eob.png` are both from printed
page 16 of C28-6100-2, PDF page 24: the WRITE calling sequence and the three
rules of the READ discussion, whose rule 3a is the end-of-buffer sentence item 4
records as an open gap.

The stage 2 record holds the J 03.03.01 core-layout crop that item 2 rests its
buffer placement on. This record links it rather than repeating it:
<https://github.com/Screendead/comtran-compiler/tree/6492c9a/reviews/2026-09-12-m5s2-get-design>.
