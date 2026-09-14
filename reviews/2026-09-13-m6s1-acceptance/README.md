# 2026-09-13 · M6 stage 1, the sample's acceptance

Stage 1 of M6 runs the 1962 payroll sample end to end and diffs its report
against PDF p. 217. The record holds the reconstruction of the two input tapes,
the reading of the printed page, the four differences and what each one is. The
date of the evidence is 2026-09-13. Every repository link points at commit
`d5dd932`, the head of branch `m6s1-sample`.

Seven items. Four are SETTLED: the result and its four findings, the RET.PREM
defect of the 1962 processor, the grand-total net pay the page disagrees with
itself about, and the scan measurement of every column claim. Two are DECIDED
under the CLAUDE.md section 12 standing rule: the chosen values of the
reconstruction, and the MOVPAK rule that preserves index register 1. One is
YOUR CALL: the authorization to correct the transcription's stagger note on
PDF p. 217.

| Item | Status |
|---|---|
| 1. The run reproduces the page up to four findings | SETTLED |
| 2. Authorize the erratum: the stagger note on PDF p. 217 | YOUR CALL |
| 3. RET.PREM equals INS.PREM: the 1962 processor's own defect | SETTLED |
| 4. The grand-total net pay: the page says 2180.63, its own columns say 2183.83 | SETTLED |
| 5. The reconstruction's chosen values | DECIDED |
| 6. MOVPAK preserves index register 1 and consumes the trailing `AXT` | DECIDED |
| 7. The columns were measured on the scan | SETTLED |

Item 2 waits for Jack. It asks an authorization only he can give: the manual
conversions are read-only (CLAUDE.md section 9). It blocks nothing. The reading
of the page is settled by the scan, and no file of the pull request touches a
conversion. Silence lets items 5 and 6 stand, and he can overturn either.

The record was built after the code landed. The design entries M6-1 to M6-5
were written first. A worker then implemented the code against them. This
record was built from both, in one autonomous run. No review document existed
before the code, which is the route CLAUDE.md section 12 opens for a decision
with one viable option.

Stage 1 lands as one pull request on branch `m6s1-sample`. It changes files
under `lib/`, under `test/goldens/` and under `test/fixtures/`, so it merges on
external-review convergence. Opening it is under Jack's standing authorization
of 2026-08-16.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone: the fifteen crops are embedded, so it needs no network and no server. Open it anywhere. |
| `tools/build_doc.py` | Writes `index.html`. Edit this, not the HTML. |
| `tools/cut_crops.py` | Cuts the eleven page crops from the J28-6169 scans. |
| `tools/scan/` | The five scripts that fitted the deskew angle and the column grids, and drew the four overlay plates. |
| `crops/` | The fifteen images the record shows. |
| `evidence/` | The content brief, the measurement residuals, the reading of the page and the report golden. `evidence/README.md` says what each one is. |

`tools/build_doc.py` builds every repository link from one commit hash at the
top of the file, commit `d5dd932`. Set `RECORD_HEAD` in the environment to
rebuild against another. A record outlives the branch it was written beside, so
no link may point at a branch.

There are fifteen crops. Eleven are cut by `tools/cut_crops.py`. Seven come from
`comtran-manuals/J28-6169/images/page-217.png`, the printed report:
`payfile-raw.png` and `payfile-deskewed.png` are the same box of the same page,
before and after one rotation of −1.83°, and item 2 rests the erratum on the
pair; `prem-columns.png` is the premium pair of item 3; `gt-net.png` is the
grand-total cell of item 4 at 6×; `errorfile-mocre.png`, `check-bond-woo.png`
and `payfile-woo.png` carry the two keying decisions of item 5, and
`mocre-glyphs.png` shows the two disputed names at 6×. Three come from
the object listing: `lookup-p213.png` from PDF p. 213 and `pool-p216.png` from
PDF p. 216, both for item 3, and `sys267-p169.png` from PDF p. 169, the
SYS)267 calling sequence of item 6. The remaining four —
`pay-l1-wholeline.png`, `check-294.png`, `bond-left.png` and
`error-M-line.png` — are the overlay plates `tools/scan/overlays.py` drew, and
item 7 rests the column measurement on them.

## Answer

Answer, 2026-09-14. Jack authorized item 2, in these words: "Both errata
authorised". The answer takes option 1, both parts, and it also authorizes the
page-100 candidate of the record of 2026-09-14. The correction landed the same
day, in commit `c023111` on branch `errata-p217-table`, pull request 136. The
note about the printer's practice is deleted, and both report blocks are
reflowed on their own baselines. The reflow opened a new erratum candidate: the
deskewed page prints `0.00` in the FICA column of the DEPARTMENT 09 TOTALS line
and `5.21` and `36.00` in the GT line's FICA and bond-deduction columns, which
the transcription does not hold. To key the three cells changes values, so that
candidate is open in `docs/HANDOVER.md` and waits for Jack. Item 2 keeps its
YOUR CALL chip, and the answer is appended under it.
