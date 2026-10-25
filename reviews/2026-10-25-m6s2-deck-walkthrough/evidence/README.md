# Evidence

Every file was taken from the repository at commit `f1dc820` on 2026-10-25.
Each is either a copy, an excerpt, or the output of one compiler run.

## The run

One command, run from the repository root at `f1dc820`:

```sh
dart run comtran:comtranc test/fixtures/f-payroll.ctd --date=06/01/60 --time=1.00 \
    --explain --emit-code=run.code --emit-object=run.object --emit-deck=run.deck.ctd
```

The verbatim deck is its own job deck. It carries `*COMPILE LIST` and
`*FINISH` (`test/fixtures/f-payroll-deck-notes.md`). No separate
`f-payroll-job.ctd` exists.

| File | What it is |
|---|---|
| `run.stderr` | Standard error: the 55 `--explain` lines (id, our severity, text, card, column), then the refusal line |
| `run.exit` | The exit status, 1 |
| `run.code` | The `--emit-code` dump: three comment lines, no instructions |
| `run.object` | The `--emit-object` dump: one line |
| `run.deck.ctd` | The `--emit-deck` output: a 12-byte header with a card count of 0 |
| `run.deck.xxd.txt` | `run.deck.ctd` through `xxd` |

Standard output was compared with `cmp` against `test/goldens/f-payroll.listing`
and matched byte for byte, so it is not stored twice.

## Copies and excerpts

| File | Source at `f1dc820` |
|---|---|
| `f-payroll.ctd` | `test/fixtures/f-payroll.ctd`, the canon deck |
| `f-payroll.ct` | `test/fixtures/f-payroll.ct`, its mirror. `deckconv to-text` on the canon matched it. |
| `f-payroll.listing` | `test/goldens/f-payroll.listing` |
| `procedure-get-guard.dart.txt` | `lib/src/codegen/procedure.dart` lines 1905 to 1925, the GET refusal |
| `procedure-file-guard.dart.txt` | `lib/src/codegen/procedure.dart` lines 1968 to 1993, the FILE and FILE IN refusals |
| `procedure-unrecovered-shape.dart.txt` | `lib/src/codegen/procedure.dart` lines 139 to 155, the refusal class |
| `codegen-refusal-file-in.dart.txt` | `test/codegen_refusal_test.dart` lines 1105 to 1116, the FILE IN refusal test |
| `f-corpus-test-excerpt.dart.txt` | `test/f_corpus_test.dart` lines 38 to 60, the two corpus refusal tests |
| `m6-acceptance-M6-9-excerpt.md` | `docs/design/m6-acceptance.md` lines 664 to 775: the severity finding, the question for Jack, and the FILE IN decision |
| `severities-rows.dart.txt` | The rows of `lib/src/lexer/severities.dart` for the 12 message kinds and for 195,00 and 22,00, with their comments |

## Checks in the build

`tools/build_doc.py` stops unless all of these hold:

- the canon has 191 cards, and every column agrees with the mirror text;
- each character has one punch pattern, and `A` is rows 12 and 1;
- the 55 `--explain` lines match the 55 listing lines in order, text and
  severity;
- there are 12 kinds, counted 26, 7, 6, 4, 3, 3, 1, 1, 1, 1, 1, 1;
- the highest severity is 4, and the listing closes `SEVERITY LIMIT WAS NOT REACHED`;
- the run exits 1 with the one refusal line, and the deck has 0 cards.
