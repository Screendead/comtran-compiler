# Handover — state of the COMTRAN language-definition work

*Written 2026-08-01, at the close of the session that produced the language definition. Audience: the next agent (or Jack) picking this repository up.*

## Where things stand

| Commit | What it is |
|---|---|
| `6aaf8e1` | Original repo: the manual conversions (`comtran-manuals/`) |
| `d5ad2a2` | **`docs/comtran-language-definition.md`** (the deliverable) + `CLAUDE.md` — *pushed to origin* |
| `083fd79` | Scan-resolution pass: six disputed readings settled from the page scans — **local, unpushed** |
| `2331242` | Cross-reference cleanup — **local, unpushed** |

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

### 1. Decisions waiting on Jack
- **Amend the manual conversions?** `CLAUDE.md` marks them read-only, so five verified defects were recorded in the definition (§8.5.8) but *not* fixed in the conversion files: the item-k note's "(CP)+NN" conjecture (refuted — it's a hyphen + `CP)+NN`); the "nj." note's bleed-through guess (it's real type) and its phantom period (dust); the IR999 note's "1/I identical" premise (false — the face distinguishes them); the editorial closing `)` appended to 90.01.05 item h; and the unflagged "CHKS" token in 90.08.
- **Push** the two local commits.

### 2. Optional deepening passes (would resolve more Open Questions)
- **Mine J Appendix 90.02 systematically.** The generated-code appendix was consulted only opportunistically. A dedicated pass could settle or narrow Q26–28 (rounding of negatives, overflow interaction, intermediate precision), Q31 (SYS)131 behaviour), Q40 (DO return linkage), Q42 (constant folding).
- **Read the untranscribed 90.05 pages.** PDF 198–217 (storage maps and object-code dumps) exist only as images with one-line descriptions. They may settle Q12 (default transfer address / *CTEND contents), Q40, and buffer/pool layout questions.
- **External period sources** (needs web or library work, none done yet): the 709/7090 IOCS manual **C28-6100-2** (label formats — Q45, 46, 50), 9PAC J28-6168 (report generation context), 7090 BCD/BCDIC references (confirm the five collating glyph names), and period literature (Bemer, Goldfinger, CACM ~1960–62) for the history behind CHKS, PATTERN, and the *COMPILE→$CMPLE rename.
- Everything else in Open Questions is either an implementation decision (severity values, unstated limits) or genuinely unrecoverable.

### 3. The actual mission: the compiler (not started)
The definition was deliberately design-free. Next steps when design begins: commit to the target language (the definition recommends **J**, the 1962 field-test language, with F-only features as documented-but-unimplemented); then architecture, in new documents — never inside the definition. The §8.5 catalog doubles as the semantic-decision checklist, and §8.4's diagnostic-implied rules as a de-facto conformance list.

## Pointers

- Definition: `docs/comtran-language-definition.md` — §8.5 (ambiguity catalog), §8.5.8 (scan-resolved transcription issues), end-of-file Open Questions (74 items; 23 and 73 resolved).
- Manuals: `comtran-manuals/{F28-8043,J28-6169}/`, scans in each `images/` (`page-NNN.png` = PDF page NNN); citation and fidelity conventions in `comtran-manuals/README.md`.
- All intermediate artifacts (extraction drafts, verification findings, scan-agent pixel evidence) lived in the session scratchpad and are gone; everything load-bearing was folded into the committed documents.
