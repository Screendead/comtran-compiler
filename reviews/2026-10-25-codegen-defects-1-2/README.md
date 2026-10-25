# Review record: codegen defects 1 and 2 (2026-10-25)

Asks Jack, for each defect, refuse or align: defect 1, a MOVE that ignores
the decimal point on two paths, and defect 2, an edited ADD source that is
not scale-aligned (`docs/HANDOVER.md`, "Codegen defects the runtime
exposed"). Master at ace4ee0. The align prototype is on branch
`defects-1-2-align` at 0223ddfbf0e4e943f5ca27eae2d2bbaf4678ddc4.

- `index.html`: the standalone record. Open it in a browser.
- `crops/`: the F28-8043 scan crops (F pp. 42, 43, 47), as separate files.
- `evidence/`: the probe captures, the prototype diff, the golden excerpts,
  the site excerpts and the corpus inspection. `evidence/README.md` lists them.
- `tools/`: `build_doc.py` writes `index.html`; `probe.dart` compiles and
  runs the probe programs.
