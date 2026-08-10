# Temporary storage has no rule left to find — review record, 10 August 2026

M4 stage 2, chunk B1. The record asks Jack one question: what the compiler does
with `TS)`, a storage block the 1962 compiler sized to 7 words and then never
used.

`index.html` is standalone. Every plate is embedded as a data URI, so the file
renders from any location with no network and no server.

## What each directory holds

| Path | What it holds |
|---|---|
| `index.html` | The record. Open it first. |
| `crops/` | The two plates, as separate PNG files |
| `evidence/` | The measurements the record argues from |
| `tools/` | The scripts that measured and built it |

### crops

| File | What it shows |
|---|---|
| `a1-reservations.png` | The five Location Counter 1 reservations on PDF p. 215, at 3× |
| `a2-reservations-in-place.png` | The same block at 2× with fifteen lines of context |

### evidence

| File | What it holds |
|---|---|
| `spine-derivation.txt` | Full output of `tools/spine.py`: the procedure text's span, the five block origins, all 45 units and their word counts, the wrapped labels, the EQU lines, and the printed `GN)` set |
| `ts-references.txt` | Reservation and reference counts for `RS)`, `TS)`, `BL)`, `PI)` and `CP)` |

### tools

| File | What it does |
|---|---|
| `spine.py` | Reads the object-listing target's LOC column back into the units it prints |
| `crops.py` | Deskews PDF p. 215, deletes the form rules, and cuts the two plates |
| `build_doc.py` | Assembles `index.html` and embeds the plates |

Run `spine.py` and `crops.py` from the repository root; `build_doc.py` runs from
anywhere.

## The one thing that needs Jack

Section "What the compiler does with a block it cannot size" holds it, with
three options and a recommendation. Nothing is blocked on the answer: B1
proceeds either way, and what the answer changes is what the design record and
the code claim about the number 7.
