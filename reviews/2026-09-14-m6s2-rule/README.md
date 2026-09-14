# 2026-09-14 · M6 stage 2: what would have compiled in 1962

Jack ruled on 2026-09-14: "if it would compile in 1962, it should compile. If it
wouldn't, it shouldn't. If it's ambiguous, I need to see it with argumentation
both ways and a recommendation, and I'll make a call." This record applies that
rule to the six shapes the code generator refuses in the second corpus, the 1960
payroll program of F28-8043 Appendix 1. The date of the evidence is 2026-09-14.

Six items. Three are DECIDED under the CLAUDE.md section 12 standing rule: the
reading rule with its six verdicts, the partial overturn of M6-8, and the three
causes that separate the corpus's report from the 1962 sample's. Two are
SETTLED: the STOP correction, and the restatement of M6-7's premise. One is
YOUR CALL: item 2 asks whether "compile" in the rule means the diagnostic
listing or the object deck.

No work waits on that answer. Chunk 2b works on the applied deck, whose GET
binds to a file, so the answer changes a label and a design entry and not a line
of the compiler.

The record was built after the design entries landed on branch `m6s2-rule`:
M6-9 new, M6-1 and M6-7 amended, M6-8 overturned in part, with
`docs/HANDOVER.md`, the definition's §9.8 table and
`test/fixtures/f-payroll-deck-notes.md` beside them. Jack gave the rule in
conversation, not through a review document, and no review document existed at
the time.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone: the five crops are embedded, so it needs no network and no server. Open it anywhere. |
| `tools/build_doc.py` | Writes `index.html`. Edit this, not the HTML. |
| `crops/` | The five scan crops the record shows. |
| `evidence/` | The three primary files the record draws on. `evidence/README.md` says where each came from. |

## No repository links

This record carries no hyperlink into the repository. A record may not point at
a branch name, because the branch is deleted when its pull request merges, and
the tip of `m6s2-rule` was not fixed when the record was built. Every path is
given as a path, and every quotation is printed in full, so the record stands
without the repository.

## The crops

| File | Source page | Pixel box | What it shows |
|---|---|---|---|
| `crops/j-p015-data-desc.png` | `comtran-manuals/J28-6169/images/page-015.png` | (220, 1200, 830, 1445) | The data description of J's arithmetic-efficiency example. A to E carry bare pictorials; X alone is `IR999`. |
| `crops/j-p016-set-sequences.png` | `comtran-manuals/J28-6169/images/page-016.png` | (370, 235, 1130, 835) | The two SET sequences. The improved form of example 2 still stores into A, an external field. |
| `crops/j-p157-sys186-188.png` | `comtran-manuals/J28-6169/images/page-157.png` | (110, 220, 1140, 610) | SYS)186, SYS)187 and SYS)188, the internal-to-external store converters. None carries an overflow test step. |
| `crops/f-p101-overtime.png` | `comtran-manuals/F28-8043/images/page-106.png` | (370, 1015, 1130, 1125) | Serials 02012 to 02015 of the 1960 machine listing: the two overtime sentences. That image is printed page 101. |
| `crops/j-p196-stmt203.png` | `comtran-manuals/J28-6169/images/page-196.png` | (505, 546, 1295, 626) | Statements 202,00 and 203,00 of the 1962 sample listing: the overtime sentence with its OTHERWISE arm. |

Every crop is enlarged two times with Lanczos resampling, so it stays legible at
the record's width. Each keeps a white ground in both themes, because the scans
are black ink on white paper.

## Correction

Correction, 2026-09-14, appended as the second commit of this branch. It changes
no argument and no verdict. The crop of the 1962 sample listing was cut too wide
and too deep. Its box was (470, 548, 1440, 634), which left a third of the frame
empty on the right and clipped the first line of statement 204,00 at the foot,
so the crop displayed at about three quarters of the scan's own scale and was
hard to read. The box in the table above is the new one. Both listing figures of
item 6 also carry a monospace plate of the same lines as text, taken from the
conversions.

## One correction to the task as given

The task named `images/page-107.png` for the overtime crop and asked that the
page be confirmed first. The confirmation moves it. In
`comtran-manuals/F28-8043/a1-programming-example.md` the marker `page 101 | PDF
106` precedes serials 02012 to 02015, and the marker `page 102 | PDF 107`
follows them, so the sentences print on PDF page 106. The rendered scan confirms
it: `page-106.png` carries the printed page number 101 at its foot and the
serials in question. The definition's new overtime row cites F p. 101, which
agrees.
