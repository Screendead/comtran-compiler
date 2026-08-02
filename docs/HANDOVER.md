# Handover — state of the COMTRAN language-definition work

*Written 2026-08-01, at the close of the session that produced the language definition. Audience: the next agent (or Jack) picking this repository up.*

## Where things stand

| Commit | What it is |
|---|---|
| `6aaf8e1` | Original repo: the manual conversions (`comtran-manuals/`) |
| `d5ad2a2` | **`docs/comtran-language-definition.md`** (the deliverable) + `CLAUDE.md` — *pushed to origin* |
| `083fd79` | Scan-resolution pass: six disputed readings settled from the page scans |
| `2331242` | Cross-reference cleanup |
| `f1bd24e` → `390c0df` | **Deepening passes** (merged as PR #1, 2026-08-02): 16 Open Questions annotated with adversarially verified evidence; catalog and §8.5.8 kept in step |

The deliverable is a ~4,250-line, fully-cited definition of historical COMTRAN, structured in nine sections plus an Open Questions list. `CLAUDE.md` records the maintenance rules: **J28-6169 is authoritative over F28-8043**; §8 and Open Questions are living lists (update entries, don't delete); correct the document only against the manuals or their scans; never add implementation material to it.

## How the definition was built (what you can rely on)

1. **Extraction**: nine agents read both manuals end-to-end, one per topic section, citing every claim.
2. **Adversarial verification**: nine per-section verifiers checked every verbatim quote character-for-character, every numeric limit, and all citations attached to quotes/numbers/tables (plus >50% of prose-claim citations); a completeness critic swept both manuals' structure for gaps; a consistency checker validated cross-references, anchors, and tables. 26 errors + 54 warnings found; **all were fixed**, including one gem the critic caught: F's glossary states the rounding rule (round-half-up, F p. 115) that the draft had called unstated.
3. **Scan resolution** (commit `083fd79`): six disputed pages re-read at 400–600 dpi from the source PDFs with per-glyph measurement. The two most load-bearing results — the page-50 collating sequences and the 90.01.05 item-k glyph — were independently re-verified by the supervising agent. Outcomes are recorded per-entry in §8.5.8 and in Open Questions 23 and 73.

**Working practices to keep** (from `CLAUDE.md` and Jack's standing preferences): cite everything as `(F p. N)` / `(J xx.xx.xx)`; page scans are ground truth for disputed readings; hand-pick the model for every subagent/workflow task by complexity and correctness stakes; when a §8.5 or Open Questions item is resolved, annotate it in place with the evidence and date.

## Confidence assessment (honest)

- **Strong** — structure and coverage (near-exhaustive per the completeness sweep), quoted general forms, reserved-word lists, numeric limits, error-message texts, the F/J divergence catalog, and the six scan resolutions (pixel-level evidence; five "certain", the collating sequences certain in shape with only the BCDIC glyph *names* — plus-zero, minus-zero, record mark, group mark, lozenge — being inference).
- **Good but not exhaustively re-checked** — prose-claim citations beyond the verified >50% sample; and the ~120 correction edits themselves, which were applied from verifier-supplied text but never re-verified by a further independent pass. Risk is low (mostly citation swaps) but nonzero.
- **Labeled inference** — every "Resolution" in §8.5 is a judgment call with its reasoning stated; treat them as defaults to design against, not facts. The severity-code assignments (§8.4) are fundamentally unrecoverable from these manuals.

## What's left

### 1. Decisions waiting on Jack — both resolved 2026-08-01
- **Manual conversions amended** under a one-time authorization from Jack (who also manually re-confirmed the item-k text, the IR999 reading, and the "nj" mark against the pages): the item-k, IR999, and "nj" conversion notes corrected; `nj` added verbatim to the Input FILE form block; item h's editorial `)` retained but flagged in the note; "SPECIF CHKS" and the message-187 run-on now flagged in their files' notes. The conversions remain read-only per `CLAUDE.md` going forward.
- **Pushed** by Jack.

### 2. Optional deepening passes — COMPLETED 2026-08-02 (all three streams, adversarially verified)

Sixteen Open Questions now carry verified annotations. Newly **resolved**: Q12 (default transfer address = the first Procedure-Division sentence, punched as `GN)000` in the end-of-text record, control group 01111; `*CTEND` carries no transfer address), Q40 (DO return linkage = per-procedure return cell in the procedure's head word — `AXT/SXA/TRA P+1` call, `TRA* P` indirect return, plus the distinct `DO … FOR` call shape; J 02.08.03 corroborates that IR4 cannot hold a surviving return), Q45 (complete 14-word IOCS header/trailer label layouts), Q46 (the FOR LABEL mechanism is IOCS's five-entry `MYLBLS` non-standard-label vector — positional event discrimination, IR2 = FCB, skip-returns through IR1, MQ-sign/AC decision returns), Q47 (`OPEN ALL FILES` is implemented — sample st. 188 compiles to `TSX SYS)175,4`), and Q50 (answer NO: no count check of any kind outside standard labels — block counts not record counts, checked at trailer-read not CLOSE). Newly **narrowed** with verified evidence: Q26, Q27, Q28, Q31, Q41, Q42, Q53, Q58, Q70, Q72.

- **Catalog kept in step:** §8.5.4 rounding + overflow entries amended, a new §8.5.4 bullet (invalid characters in a numeric field at object time), §8.5.5 nested/recursive-DO corroboration, §8.5.6 AT END amendment, §6.4 gained an "Implementation attested" OPEN note, and §8.5.8 gained two entries: the transcription's silent normalization of the `*CTEND` date (card prints `101861`, transcription `10/18/61` — **a conversions erratum candidate that needs Jack's authorization** under the read-only policy), and the glyph-name confirmation below.
- **Glyph names (§8.5.8, "resolved in part"):** IBM 705 Reference Manual A22-6506-0 Fig. 2, the 705 pocket code card 22-6642-0, and IBM 1401 A24-1403-5 Fig. 267 confirm **Plus Zero** (12-0), **Minus Zero** (11-0), **Record Mark** (0-2-8) and **Group Mark** (705 card code 12-5-8, not the 1401's 12-7-8) by name; the lozenge glyph is confirmed by code and shape (12-4-8) but named by no period source found — "lozenge" remains inference. Bonus finding, recorded with the entry: the pocket card's own collating sequence orders the leading specials differently from J 02.06.16's COM line — a genuine machine-chart-vs-COMTRAN divergence, not a transcription error.
- **Not recovered (genuinely):** period literature on COMTRAN beyond the manuals (Goldfinger/Bemer papers are ACM/IFIP-paywalled; nothing freely readable found); the CHKS/PATTERN back-story; Q26/Q28 residuals as annotated in place.
- **Raw agent outputs** (drafts, adversarial verdicts, scout page-maps, 9PAC Part 1 notes): `docs/research-2026-08-01-interrupted.md`. External scans used (all bitsavers, re-downloadable): `pdf/ibm/7090/C28-6100-2_7090_IOCS.pdf`, `pdf/ibm/7090/22-6528-4_7090Manual.pdf`, `pdf/ibm/7090/J28-6166_9PAC_Part1_1961.pdf`, `pdf/ibm/705/A22-6506-0_705_Reference_Man_May59.pdf`, `pdf/ibm/1401/A24-1403-5_1401_Reference_Apr62.pdf`, plus the 705 pocket code card 22-6642-0.
- Everything else in Open Questions is either an implementation decision (severity values, unstated limits) or genuinely unrecoverable.

### 3. The actual mission: the compiler — roadmap (updated 2026-08-02, not started)

The definition stays design-free; all design work goes in new documents under `docs/` (suggested: `docs/design/`), never inside the definition. The §8.5 catalog doubles as the semantic-decision checklist, and §8.4's diagnostic-implied rules are the de-facto conformance list. Sequence:

- **M0 — Commitments** (`docs/design/decisions.md`). Target language: **J**, the 1962 field-test language, with F-only features treated as documented-but-unimplemented (the definition's recommendation). Walk §8.5 end to end recording one decision per entry, citing the entry. Up-front decisions that are Jack's to make: implementation language; backend strategy (emit C / LLVM / interpreter-first); fidelity level — behavioral decimal-and-BCD semantics vs bit-faithful 36-bit emulation (recommendation: behavioral, going bit-faithful only where the definition makes it observable, e.g. collating sequences, truncation/rounding, field overflow); character-set representation and both collating sequences (§1.1); how tape files, labels, and PATTERN map onto modern files.
- **M1 — Card reader, lexer, listing.** Column-aware source model (serials 1–6, procedure-name margin 7–12, text 13–72, continuation rules), reserved words (F App. 2 + J key-word lists), compound names, literals. First observable output: the compilation listing format. First test input: the 90.05 sample deck, re-keyed from the transcription.
- **M2 — Parser + diagnostics**, all three divisions plus control cards; statement numbering (`n,cc`); the 90.04 message catalog as the diagnostic vocabulary (severity values are ours to assign — Open Question 65).
- **M3 — Data Description semantics**: levels, pictorials, type codes, storage mapping (definition §3, corroborated by the 90.05-derived layout evidence), REDEF, QUANTITY.
- **M4 — Core-verb code generation**: MOVE/SET/IF/WHEN/GO TO/DO — DO per the verified Q40 return-cell semantics (including its non-reentrancy), arithmetic per §4.3 and the Q26–28 annotations.
- **M5 — I/O runtime**: OPEN/CLOSE/GET/FILE, buffering and locate-mode semantics, AT END/ON ERROR per Q41, labels per Q45/Q46 at the M0-chosen fidelity, DISPLAY and report output.
- **M6 — Acceptance**: compile and run the 90.05 payroll sample end to end and reproduce the manual's printed report output (PDF p. 217); second corpus, F's payroll example with the documented F/J divergences applied (§9.8).

## Pointers

- Definition: `docs/comtran-language-definition.md` — §8.5 (ambiguity catalog), §8.5.8 (scan-resolved transcription issues), end-of-file Open Questions (74 items; 12, 23, 40, 45, 46, 47, 50, 73 resolved; 26–28, 31, 41, 42, 53, 58, 70, 72 narrowed with verified annotations, 2026-08-01/02).
- Manuals: `comtran-manuals/{F28-8043,J28-6169}/`, scans in each `images/` (`page-NNN.png` = PDF page NNN); citation and fidelity conventions in `comtran-manuals/README.md`.
- All intermediate artifacts (extraction drafts, verification findings, scan-agent pixel evidence) lived in the session scratchpad and are gone; everything load-bearing was folded into the committed documents.
