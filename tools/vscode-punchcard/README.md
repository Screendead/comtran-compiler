# COMTRAN Punchcard Editor

A VS Code custom editor for canon card decks (`*.ctdeck`). It shows each card as
a 12-row by 80-column punch grid, reads every column with the COMTRAN character
code, and writes the deck back in the frozen binary format.

The format is `docs/design/deck-format.md`. Read it first: §2 defines the binary
container, §4 defines the character code. This extension is a port of the Dart
reference in `lib/src/chars/char_code.dart` and `lib/src/cards/canon_codec.dart`.
Those files stay authoritative. Change neither side alone.

## What you see

- **Card list** on the left: one line per card with its read-out, in deck order.
- **Field ruler**: the four card fields — serial 1-6, name margin 7-12, text
  13-72, identification 73-80 (definition §1.9.1, F p. 37).
- **Interpreted row**: the Set H glyph of each column. Three markers stand for
  columns that have no glyph:
  - `¤` a machine special (plus zero, minus zero, record mark, group mark),
  - `~` a code that the sources do not attest,
  - `!` a punch pattern with no read-out at all.
  Point at a column to see its card code, its octal code, and its name. The
  status line below the card shows the same for the current column.
- **Punch grid**: rows 12, 11, 0, 1 to 9 from top to bottom. A punched hole is a
  filled rectangle. The three zone rows have a shaded background.

## How you edit

- Click a cell to punch or unpunch it.
- Arrow keys move the cursor. Space or Enter punches the current cell. Home and
  End go to column 1 and column 80. PageUp and PageDown change card.
- **Type to punch**: turn the checkbox on, then type. Each Set H character
  punches its canonical card code into the current column and moves right.
  Space punches a blank column. Backspace moves left and clears. Delete clears
  the current column. A character outside the 48-character source set does
  nothing and reports itself in the status line.
- **Add card**, **Duplicate** and **Delete** work on the current card.
- The `-` and `+` buttons change the column width.
- Undo, redo, save, revert and hot exit all use VS Code's own machinery. A save
  writes a whole canon file: the 12-byte header and 120 bytes per card.

## How to run it

```
cd tools/vscode-punchcard
npm install
npm run compile
npm test
```

To try the editor, open **this folder** (`tools/vscode-punchcard`) in VS Code and
press <kbd>F5</kbd>. VS Code compiles the extension and starts an Extension
Development Host on the repository root. Open `tests/90.05-payroll.ctdeck` there.

`npm test` compiles first, then runs the unit tests with `node --test`. The
tests cover the header, the two-columns-per-three-bytes packing, the read rules,
the 48-character source set, and two checks against the committed 90.05 deck: a
byte-for-byte round trip, and a read-out that matches the committed mirror line
for line.

## Limits

- The editor reads and writes canon files only. It never touches the `.deck`
  mirrors; `deckconv` generates those.
- The webview has no dependencies. All CSS and JavaScript is inlined under a
  nonce with a strict Content Security Policy.
- `out/` and `node_modules/` are build products. Do not commit them.
