# 2026-09-12 · M5 stage 2, GET: the design and the delivery plan

Stage 2 gives the 1962 payroll sample its GET. The record holds the design of
the IOC)8 handler, the buffer it reads into, the read rules that govern it, and
the plan that delivers them. The date of the evidence is 2026-09-12. Every
repository link points at commit `aebcc3b` on master.

Seven items. Four are DECIDED under the CLAUDE.md section 12 standing rule, and
silence lets them stand: IOC)8 as the IOCS READ routine, one buffer per input
file above the program, the read rules, and the delivery plan. Two are YOUR
CALL: what an unreadable tape record does, and what a GET does with no
`--tapes` directory. One is SETTLED and asks nothing: what stage 2 does not
build, and the provenance of the evidence.

Stage 2 lands as one pull request on branch `m5s2-get`. It changes files under
`lib/`, so it merges on external-review convergence. Opening it waits for Jack's
answer to items 4 and 5, and that answer authorizes the opening.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone: the one crop is embedded, so it needs no network and no server. Open it anywhere. |
| `tools/build_doc.py` | Writes `index.html`. Edit this, not the HTML. |
| `crops/` | The one image the record shows. |
| `evidence/` | The three reports the design was built from, left as written. `evidence/README.md` says what each one is. |

`tools/build_doc.py` builds every repository link from one commit hash at the top
of the file, commit `aebcc3b`. Set `RECORD_HEAD` in the environment to rebuild
against another. A record outlives the branch it was written beside, so no link
may point at a branch.

There is one crop, `crops/j-03-03-01-core-layout.png`. It is the core layout at
execution time, cut from `comtran-manuals/J28-6169/images/page-081.png`, the scan
of J 03.03.01. Item 2 rests its buffer placement on the row order of that chart.
