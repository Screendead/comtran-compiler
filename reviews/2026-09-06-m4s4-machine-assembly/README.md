# 2026-09-06 · M4 stage 4, the machine assembly

Stage 4 is commit 842649e on branch `m4s4-machine-assembly`. It builds the
machine that runs a loaded object program, and the SYS)/IOC) library handlers
that stand under it. The 1962 payroll sample now loads its 936 words at address
4096, enters at 4213, opens an empty file list, fills its work areas through the
move package, and stops at its first GET, which M5 owns. `comtranc --run` is the
flag that carries a run to the command line. `docs/design/runtime.md`, entries
RT-1 to RT-5, is the design record the decisions landed in.

Nine sections. Four are DECIDED under the CLAUDE.md section 12 standing rule,
and silence lets them stand: the narrow handler set, fifteen runtime design
decisions, six record amendments with one word-budget raise, and the findings
of the three internal reviews with their dispositions. Two are YOUR CALL: five
code-generator defects the runtime made visible, and a program with two
PROGRAM.START labels that compiles to nothing. Three are SETTLED and ask
nothing.

Neither YOUR CALL item blocks the stage-4 pull request. Both defect sets predate
this branch. The branch changes files under `lib/`, so its pull request needs
the two-family review loop of `EXTERNAL-REVIEW.md` and merges on convergence.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone: no images, no network, no server. Open it anywhere. |
| `tools/build_doc.py` | Writes `index.html`. Edit this, not the HTML. |
| `evidence/` | The nine working documents the stage was built from, left as written. `evidence/README.md` says what each one is. |

`tools/build_doc.py` builds every repository link from one commit hash at the
top of the file, commit 842649e. Set `RECORD_HEAD` in the environment to
rebuild against another. A record outlives the branch it was written beside,
so no link may point at a branch.

There is no `crops/` directory. Stage 4 puts no question to a page scan: every
measurement the record cites comes from a repository file or from a compiler
run.
