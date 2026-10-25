# Review record: codegen defect 6 (2026-10-25)

Asks Jack three questions on codegen defect 6 (`docs/HANDOVER.md`, "Codegen
defects the runtime exposed"): a reopen after CLOSE ALL FILES draws no
diagnostic, though D6.3 asks for one where the text shows it. The id,
948,00, is settled. The text, the severity and the detection scope are his
call. Master at fca3157. The prototype is commit
6cda03b6b10e3c2132c0d3d0f03652b6a3a34fbb on the local branch
`defect-6-proto`, not pushed.

- `index.html`: the standalone record. Open it in a browser.
- `crops/`: two J28-6169 scan crops, J 02.04.06 (PDF p. 24) and
  J 90.04.01 messages 135 to 140 (PDF p. 184).
- `evidence/`:
  - `reopen-today-fca3157.txt`: the reopen probe on master, listing and run.
  - `reopen-sev1.txt`, `reopen-sev3.txt`, `reopen-sev4.txt`: the same probe
    on the prototype with message 948 at severity 1, 3 (OPEN deleted) and 4.
  - `labelled-sev4.txt`, `sample-shape-sev4.txt`: the two silent probes.
  - `prototype-fca3157..6cda03b.diff`: the whole prototype.
  - `severity-3-delete-variant.diff`: the code-generator change behind the
    severity 3 capture (OPEN deleted), before the tests were added.
- `tools/`: `build_doc.py` writes `index.html`; `crops.py` cuts the crops
  (run from the repository root); `probe.dart` writes the probe decks
  (copy to `probe/` in a checkout, `dart run probe/probe.dart OUTDIR`);
  `house.css` is the house style, copied from the defects 8 to 11 record.
