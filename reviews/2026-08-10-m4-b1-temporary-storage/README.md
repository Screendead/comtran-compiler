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
| `block-usage.txt` | The 2026-08-10 correction: distinct words addressed inside each Location Counter 1 block, against the addressing-line counts the record first printed |

### tools

| File | What it does |
|---|---|
| `spine.py` | Reads the object-listing target's LOC column back into the units it prints |
| `crops.py` | Deskews PDF p. 215, deletes the form rules, and cuts the two plates |
| `build_doc.py` | Assembles `index.html` and embeds the plates |

Run `spine.py` and `crops.py` from the repository root; `build_doc.py` runs from
anywhere.

## Jack ruled on 2026-08-10: option A

`TS)` takes the attested 7 as a constant, and no rule is invented for it. The
banner at the head of `index.html` carries the ruling and its basis, and
`docs/design/m4-codegen.md` M4-4 as amended binds the code. The per-item chip
below is left as it was: the record shows the question as well as the answer.

## The one thing that needed Jack

Section "What the compiler does with a block it cannot size" holds it, with
three options and a recommendation. Nothing is blocked on the answer: B1
proceeds either way, and what the answer changes is what the design record and
the code claim about the number 7.

## Corrected 2026-08-10, before any ruling

The record's first version contrasted temporary storage's zero references
against result storage's 14, and those 14 are *addressing lines*. By distinct
words, result storage reaches 5 of the 30 it reserves, so 25 of its words are
addressed by nothing either. Temporary storage is the undocumented end of a
documented spectrum rather than an anomaly, and the corrected table is ordered
by how well the manual documents each block's rule. The recommendation does not
change; it never rested on temporary storage being unique.
