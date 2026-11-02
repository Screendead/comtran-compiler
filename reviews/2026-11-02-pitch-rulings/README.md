# 2026-11-02 pitch rulings (retrofit record)

No review record existed when these eleven questions were put. They were put
to Jack on the interactive pitch page
https://claude.ai/artifact/VF2SjodMseA7aQMekdqRqw on 2026-11-02, and he
answered there. This record was built afterwards to hold the questions and
the answers permanently. A second round of six calls was put on the same
page later that day; the record holds it in its own section.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone: the crops are embedded as `data:` URIs; no network. |
| `evidence/pitch-page.html` | The pitch page source, from local branch `archive/pitch-2026-11-02` at `48136be` (eleven calls). |
| `evidence/pitch-page-3dea94e.html` | The same page one commit earlier, with nine calls: the numbering the record uses. |
| `evidence/calls.json` | The page's `CALLS` literal, evaluated by `tools/extract_calls.js`. |
| `evidence/picks.json` | Jack's saved picks, read back from the page's database on 2026-11-02 (added with the rulings). |
| `evidence/dns-check.txt` | The DNS and Pages check that bears on call 9 (added with the rulings). |
| `evidence/pitch-page-round2.html` | The pitch page source for the second round, from `archive/pitch-2026-11-02` at `33cc8a8` (six calls and a free-text box; added with round two). |
| `evidence/calls-round2.json` | The round-two `CALLS` literal, evaluated by `tools/extract_calls.js`. |
| `evidence/dash-counts.txt` | The em-dash counts behind round-two call 4, written by `tools/count_dashes.sh`. |
| `crops/` | Three crops of J28-6169 PDF pages 116 and 171, for round-two call 3. |
| `tools/extract_calls.js` | Extracts `calls.json` and `calls-round2.json` from the page sources. |
| `tools/make_crops.py` | Cuts `crops/` from the page scans; takes the repository root. |
| `tools/count_dashes.sh` | Counts the em dashes W2 left in the language definition; takes the repository root. |
| `tools/build_doc.py` | Writes `index.html`. |
| `tools/house.css` | The house style, copied from `review/2026-10-25-codegen-defects-8-11`. |

Round one has no crops: no manual page bears on its calls directly. The
records each call points to hold their own evidence. Round two, put on the
same page later the same day, has three: call 3 turns on what two scan
pages print.
