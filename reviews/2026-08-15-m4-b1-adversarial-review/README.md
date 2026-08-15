# 2026-08-15 · chunk B1 adversarial review

The record of the independent adversarial review of commit c077c28
(chunk B1, the address spine) and the fixes that answered it, commit
52e32c1 on `m4s2-chunk-b1`. One item is DECIDED under the CLAUDE.md
section 12 standing rule — the refusal boundary — and silence lets it
stand. The rest are SETTLED.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone; open it anywhere. |
| `evidence/reviewer-findings.md` | The reviewer's verbatim report on c077c28. |
| `evidence/display-deck.ct` | The two-job deck that reproduced the crash. |
| `evidence/display-crash-pre-fix.txt` | The crash at c077c28: exit 255, job 2 starved. |
| `evidence/display-fixed-post-fix.txt` | The same deck at 52e32c1: refusal scoped, job 2 compiles. |
| `tools/build_doc.py` | Builds `index.html` from this directory. |
