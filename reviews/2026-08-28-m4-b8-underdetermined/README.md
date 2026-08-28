# 2026-08-28 · chunk B8, the seven underdetermined rules

Chunk B8 is the diagnostics of the M4 stage 2 code generator, at commit
8219b6f on `m4s2-chunk-b8`, with the internal review's correction of
item 1's fixed-name count at f38ea63. It widens msg 942 to the generated names
(M4-5) and counts the constant pool for msg 172 (D9.7). It adds the two
`--pedantic` notes 946 (D5.1) and 947 (D5.7), and gives the phase the
D10.2 stop shape (M4-2). The 1962 sample draws none of them, so no
listing decides their shape. Seven rules were left open by the records
that ask for the chunk, and each had one viable reading.

All seven items are DECIDED under the CLAUDE.md section 12 standing rule.
Silence lets them stand. The record asks nothing and authorizes nothing;
the B8 pull request waits for Jack.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone; open it anywhere. |
| `evidence/1-name-tally.diff` | The hunks of 8219b6f that define one generated name: `name_tally.dart`, the resolver, and the `_name` sites of `procedure.dart`. |
| `evidence/1b-fixed-names-fix.diff` | The whole diff of f38ea63 for `procedure.dart`, the test file and `m4-codegen.md`: the tenth fixed name, `PI)1`, and the pinned numbers moved by one. |
| `evidence/2-pool-counter.diff` | The hunks that count the pool: `pool.dart`, `codegen_messages.dart`, and `_poolEntry`. |
| `evidence/3-msg-946.diff` | The hunks of the D5.1 note: `_noteConstantParameters` and `_constantBound`. |
| `evidence/4-msg-947.diff` | The hunks of the D5.7 note: `_DoEdge`, `_doEdge`, `_noteReentrantCalls`, and the `AT END DO` edge. |
| `evidence/5-stop-shape.diff` | The hunks of the stop: `codegen.dart`, the driver, `emit_code.dart`, and `bin/comtranc.dart`. |
| `evidence/6-measuring-pass.diff` | The hunks that put the checks on pass one: `CodegenChecks`, `generateProcedure`, and `runCodegen`. |
| `evidence/7-allocator-crossing.diff` | The hunks of the allocator's tally: `allocator.dart` and `semantics.dart`. |
| `evidence/d5.1-amended-2026-08-05.md` | The D5.1 record of `docs/design/decisions.md`, with its amendment of 2026-08-05. |
| `evidence/d5.7.md` | The D5.7 record of `docs/design/decisions.md`. |
| `evidence/m4-5.md` | Entry M4-5 of `docs/design/m4-codegen.md`. |
| `evidence/m4-18.md` | Entry M4-18 of `docs/design/m4-codegen.md`. |
| `evidence/j-90.01.05-rows-a-k.md` | The 90.01.05 table head and rows a) and k) of `comtran-manuals/J28-6169/90.01-deferred-features.md`. |
| `tools/extract_hunks.py` | Writes the eight `evidence/*.diff` files from commits 8219b6f and f38ea63. |

Every file under `evidence/` names the commit it is taken from in its
first line. The tests that pin every number the record quotes are in
`test/codegen_diagnostics_test.dart` at f38ea63; all 18 pass.
