# 2026-11-02 pitch rulings (retrofit record)

No review record existed when these eleven questions were put. They were put
to Jack on the interactive pitch page
https://claude.ai/artifact/VF2SjodMseA7aQMekdqRqw on 2026-11-02, and he
answered there. This record was built afterwards to hold the questions and
the answers permanently. A second round of six calls was put on the same
page later that day; the record holds it in its own section. A third round of
nine calls followed the same afternoon, in a third section.

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
| `evidence/pitch-page-round3.html` | The pitch page source for the third round, from `archive/pitch-2026-11-02` at `09ceda9` (nine calls and a free-text box; round three entered at `5f22c54`; added with round three). |
| `evidence/calls-round3.json` | The round-three `CALLS` literal, evaluated by `tools/extract_calls.js`. |
| `evidence/dash-counts.txt` | The em-dash counts behind round-two call 4, written by `tools/count_dashes.sh`. |
| `crops/` | Three crops of J28-6169 PDF pages 116 and 171, for round-two call 3. |
| `tools/extract_calls.js` | Extracts `calls.json`, `calls-round2.json` and `calls-round3.json` from the page sources. |
| `tools/make_crops.py` | Cuts `crops/` from the page scans; takes the repository root. |
| `tools/count_dashes.sh` | Counts the em dashes W2 left in the language definition; takes the repository root. |
| `tools/build_doc.py` | Writes `index.html`. |
| `tools/house.css` | The house style, copied from `review/2026-10-25-codegen-defects-8-11`. |

Round one has no crops: no manual page bears on its calls directly. The
records each call points to hold their own evidence. Round two, put on the
same page later the same day, has three: call 3 turns on what two scan
pages print. Round three adds no crops: its evidence is the draft pull
requests each call names.

## The rulings of 2026-11-21

The nine calls of round three stayed unanswered on the first page. On
2026-11-20 they moved to a new page,
https://claude.ai/artifact/MU65CGChwwxR6517WYckra. The new page gives
each call its own tab and a narrated explainer video. The cards and the
video storyboards are on local branch `archive/pitch-2026-11-20` at
`94a0b06`. Jack answered all nine on 2026-11-21.
`evidence/picks-2026-11-21.json` holds the picks as read back.

| Call | Pick | Against the recommendation? |
|---|---|---|
| confirm4, the M6-9 listing ruling | `deck`: punch the object deck as 1962 did | Yes. It overturns the 2026-11-02 listing ruling |
| subscripts2, messages 912,00 and 192,00 | `keep` | No |
| typos3, three doubtful words | `all`: mark all three `[sic]` | No. The new page recommended `all`, not `none` as before. "synonymous" prints correctly at J 02.05.04, and the scan shows "in" printed clean |
| headdash, the definition headings | `change` (draft PR #192) | No |
| defect5, a run that mixes 8 and * | `A`: the 1962 words, message 950,00 under `--pedantic` (draft PR #185) | No |
| nameless, a BEGIN SECTION with no name | `196`: delete the sentence (draft PR #183) | No |
| d21, two PROGRAM.START labels | `first`: compile with the first (draft PR #184) | No |
| w3, the stages | `A`: the compiler sends the marks (draft PR #189) | No |
| w4, the tutorial | `A`: a separate tutorial page with the same editor (draft PR #188) | No |

`index.html` does not yet show this section. `docs/HANDOVER.md`,
"Rulings of 2026-11-21", holds the next step for each ruling.
