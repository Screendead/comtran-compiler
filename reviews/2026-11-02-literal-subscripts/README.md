# Review record: literal and expression subscripts (2026-11-02)

Explains a decision taken under the section 12 standing rule (status
DECIDED): codegen defect 9's open sentence in `docs/HANDOVER.md`. A
literal subscript (`CELL (2)`) and an index expression (`CELL (I + 1)`)
compiled with no message and stopped the run at the base-locator guard.
The branch `literal-subscripts` sets a literal subscript's indicator at
load time under Location Counter 2, and moves an index expression's
indicator with its variable. Master at dba709d; code at 1378b8c; records
at e7a95d7 (M6-10).

- `index.html`: the standalone record. Open it in a browser.
- `crops/`: J 02.04.07 (PDF p. 25), J 02.04.07.01 (PDF p. 26),
  J 90.02.01 (PDF p. 139), J 90.02.05 (PDF p. 143), F p. 31 (PDF p. 37).
- `evidence/`:
  - `<probe>-master-dba709d.txt`, `<probe>-branch-1378b8c.txt`: listing and
    run of the four probes (literal, expression, step, do-for).
  - `literal-*.code`, `step-*.code`: the `--emit-code` dumps.
  - `code-dba709d..1378b8c.diff`: the code change under `lib/`.
- `tools/`: `build_doc.py` writes `index.html`; `crops.py` cuts the crops
  (run from the repository root); `probe.dart` writes the probe decks
  (copy to `probe/` in a checkout, `dart run probe/probe.dart OUTDIR`);
  `house.css` is the house style.
