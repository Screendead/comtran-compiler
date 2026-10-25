# 2026-10-25 · The deck reading, walked through

Item 2 of the record on branch `review/2026-09-14-m6s2-rule` (tip `ef57893`)
asks whether "compile" in Jack's rule of 2026-09-14 means the diagnostic
listing or the object deck. On 2026-09-15 Jack kept that item open. That
record's banner says he asked for a walkthrough of the deck reading before he
decides. This record is that walkthrough. It carries one item, YOUR CALL.

The page walks the verbatim 1960 deck, `test/fixtures/f-payroll.ctd`, through
what J28-6169 says the 1962 processor would have done with it. The 1962
processor never saw this deck. The six steps:

1. The deck goes in. All 191 cards, each one shown punched from the canon file.
2. The compile prints the listing. 55 messages of 12 kinds, grouped by kind.
   Click a message to see its card and column.
3. The severity gate. J 90.04.02, J 02.01.01 and J 02.01.02 with their scans.
   Under our severity table (highest code 4), J punches a deck and does not run
   it. No 1962 severity value survives (J 90.04.01).
4. What the deck would hold. The sites the listing names, none of which any
   evidence describes, and the real output of our generator: one refusal and an
   empty deck.
5. The fork. "Compile = listing" against "compile = object deck", with
   options 1 to 3 and the recommendation (option 1). The FILE-IN refusal
   (195,00 and 22,00) is the second case under the same answer.
6. The answer box.

Since 2026-09-15 one thing changed. The FILE-IN decision of 2026-10-24 (M6-9)
added a second refusal, and M6-9 says Jack's answer decides both. No work is
blocked.

All repository paths are at commit `f1dc820` (master, 2026-10-25). The record
carries no repository hyperlink.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone: the crops and all data are embedded. Open it anywhere, offline. |
| `tools/build_doc.py` | Writes `index.html` from `evidence/` and `crops/`. It stops if the canon deck, the mirror, the listing and the run disagree. Edit it, not the HTML. |
| `tools/measure.py` | Prints the ink box inside each rough crop region. |
| `tools/make_crops.py` | Cuts the crops and enlarges each one two times. |
| `crops/` | The seven scan crops. |
| `evidence/` | The primary files the page draws on. `evidence/README.md` says where each came from. |

## The crops

All from `comtran-manuals/J28-6169/images/`. Each one is enlarged two times
with Lanczos resampling, and each keeps a white ground in both themes.

| File | Page | Pixel box | What it shows |
|---|---|---|---|
| `j-p186-severity.png` | `page-186.png` | (225, 256, 1082, 605) | J 90.04.02, the severity codes |
| `j-p010-nodeck.png` | `page-010.png` | (290, 1028, 1062, 1260) | J 02.01.01, NODECK: only a 5 stops the deck |
| `j-p011-load.png` | `page-011.png` | (274, 240, 1120, 492) | J 02.01.02, LOAD: the two bars to a run |
| `j-p181-may-vary.png` | `page-181.png` | (228, 230, 1082, 370) | J 90.04.01: the code is printed as 0 "because the value may vary" |
| `j-p185-trailer.png` | `page-185.png` | (120, 542, 388, 570) | `SEVERITY LIMIT WAS NOT REACHED` |
| `j-p185-msg195.png` | `page-185.png` | (148, 301, 820, 344) | Message 195,00 |
| `j-p181-msg21-22.png` | `page-181.png` | (268, 932, 935, 961) | Messages 21,00 and 22,00 |

The message-list pages are skewed, so the two message crops show slivers of
the rows next to them.

## How to rebuild

```sh
python3 -I tools/measure.py <repo root>
python3 -I tools/make_crops.py <repo root>
python3 -I tools/build_doc.py
```
