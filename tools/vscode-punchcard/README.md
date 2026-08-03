# COMTRAN Punchcard Editor

A VS Code custom editor for canon card decks (`*.ctdeck`). It shows each card as
a 12-row by 80-column punch grid, reads every column with the COMTRAN character
code, and writes the deck back in the frozen binary format. The extension also
gives `.deck` text mirrors syntax highlighting by card column.

The format is `docs/design/deck-format.md`. Read it first: §2 defines the binary
container, §4 defines the character code. This extension is a port of the Dart
reference in `lib/src/chars/char_code.dart` and `lib/src/cards/canon_codec.dart`.
Those files stay authoritative. Change neither side alone.

`test/fixtures/char-code-*-vectors.csv` are the golden character-code vectors
(every punch pattern, every BCD code) that a Dart-side consumer compares
against the reference to enforce that rule; see `test/fixtures/README.md` for
the file format and `npm run vectors` to regenerate them after a change to
`src/charCode.ts`.

## What you see

- **Card list** on the left: one line per card with its read-out, in deck
  order, colored by card field. The extension classifies each card by the
  division headers (the compiler's deck-splitting rules) and colors the fields
  of that division: name, level, type, quantity, mode, justification,
  description, and the continuation column 72. Header and control cards,
  and cards with non-glyph punches, get their own colors.
- **Field ruler**: the card fields of the current card's division — the
  generic form serial 1-6, name margin 7-12, text 13-72, identification 73-80
  (definition §1.9.1, F p. 37); the data description fields (F p. 65) or the
  environment fields (J 02.06.01) when the card sits in those divisions.
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
  writes a whole canon file: the 12-byte header and 120 bytes per card. Typed
  characters in one run coalesce into a single undo step.
- Run **COMTRAN: New Punch Card Deck** from the Command Palette to start a
  fresh `.ctdeck` file. Opening an existing but empty (0-byte) `.ctdeck` also
  works: it opens as a deck with no cards, and the first save writes the
  header.

## Syntax highlighting for `.deck` mirrors

The extension contributes a `comtran-deck` language for `.deck` files with a
TextMate grammar (`syntaxes/comtran-deck.tmLanguage.json`). The grammar colors
by card column: serial, the division-specific fields above, literals and the
period-blank sentence terminator (commentary after it is scoped as a comment),
`!` punch-notation lines, and the `*`-header and control cards. Division
context crosses lines; the grammar tracks it with begin/end regions that open
on a header line.

The grammar file is **generated**. One table in `src/columns.ts` holds the
column boundaries for the grammar, the card list, and the field ruler, so the
views cannot drift. The same table drives the `[comtran-deck]` editor
defaults in `package.json` (`editor.rulers` at the field boundaries,
`editor.wordWrap` off, a monospace font), so a `.deck` file opens with its
columns already lined up and never soft-wraps mid-card. After a change to
`src/columns.ts` or `src/grammar.ts`, regenerate both with:

```
npm run grammar
```

`test/grammar.test.js` fails while either the committed grammar file or the
committed `configurationDefaults` is stale. One known limit: a literal that
continues across cards is highlighted per line, so its continuation card
shows plain text.

A `.deck` file is a read-only mirror: `deckconv` generates it from the
matching `.ctdeck` file, and this extension never writes it. Editing a
`.deck` file in VS Code looks like a normal edit, but the next regeneration
discards it. The extension shows a one-time notice the first time a `.deck`
file is opened in a session.

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
for line. `npm run compile` also type-checks `media/punchcard.js` under
`tsconfig.media.json` (`allowJs`/`checkJs`), so the webview script gets the
same catch as the rest of the extension.

`test/webview.test.js` runs `media/punchcard.js` itself, not just the
extension host's side of it: it loads the webview's own generated HTML into a
real DOM (the `jsdom` devDependency), sends it `state`/`status` messages the
same shape `punchcardEditor.ts` sends, and drives its keyboard and mouse
handlers to check the grid, the card list, type-to-punch mode, zoom, and
`vscode.getState`/`setState` persistence.

## How to package it

```
cd tools/vscode-punchcard
npm run package
```

This runs `vsce package` after compiling, and writes a `.vsix` file to this
directory (gitignored, not committed). `.vscodeignore` keeps `src/`, `test/`,
build maps and declaration files out of the package; only `out/`, `media/`,
`syntaxes/` and the manifest files ship. The extension stays private
(`"private": true` in `package.json`): it is not published to a marketplace.
`vsce package` still warns about the missing `license` field; the repository
has not settled on a license, and adding one is a project-wide decision
outside this extension's scope. Install a packaged build with
`code --install-extension comtran-punchcard-<version>.vsix`.

## Limits

- The editor reads and writes canon files only. It never touches the `.deck`
  mirrors; `deckconv` generates those.
- The webview has no dependencies. All CSS and JavaScript is inlined under a
  nonce with a strict Content Security Policy.
- `out/` and `node_modules/` are build products. Do not commit them.
