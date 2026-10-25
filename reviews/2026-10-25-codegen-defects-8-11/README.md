# Review record: codegen defects 8 to 11 (2026-10-25)

Asks Jack, for each of codegen defects 8 to 11 (`docs/HANDOVER.md`, "Codegen
defects the runtime exposed"), refuse or handle, and asks one combined
question that would settle every open refuse-or-handle defect: handle
wherever attested words exist, refuse only where none do. Master at fca3157.
The handle prototype is on branch `defects-8-11-handle` at
8eb359a4aae938ae4db64acd12b28370b08435bb.

- `index.html`: the standalone record. Open it in a browser.
- `crops/`: the J28-6169 scan crops (J 02.04.07, J 02.04.07.01, J 90.02.05),
  as separate files.
- `evidence/`: the probe captures, the prototype diff and the golden
  excerpts. `evidence/README.md` lists them.
- `tools/`: `build_doc.py` writes `index.html` from `evidence/`, `crops/`
  and `house.css` (the house style, copied from the defects 1 and 2
  record); `probe.dart` compiles and runs the probe programs;
  `bytes.dart` measures the sample's TABLE.ITEM bytes.
