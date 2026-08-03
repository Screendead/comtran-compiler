# Cross-language parity fixtures

These two files are the golden vectors for the character code
(`docs/design/deck-format.md` §4). They are generated from the TypeScript
port (`src/charCode.ts`) by `src/generateCharCodeVectors.ts`
(`npm run vectors`), and `test/charCodeVectors.test.js` fails the build while
either committed file is stale.

Today these files guard only against the TypeScript port drifting from
itself between commits. They exist so that a Dart-side consumer can compare
`lib/src/chars/char_code.dart` against the exact same data without either
side calling into the other at build time (see review finding `VSC-5`, and
`CI-01`/`MCP-8` for the CI gate that consumes them). **Whichever side adds
that consumer must treat this file format as a contract**: if a column's
meaning ever needs to change, regenerate both files and update this
document in the same change.

## File format, both files

- Plain text, UTF-8, `\n` line endings, one line per row.
- Comma-separated. **Every field is wrapped in double quotes, with no
  exception** — including the header row, and including fields that hold a
  plain integer. This is deliberate: `char-code-bcd-vectors.csv`'s `glyph`
  column holds a literal comma character for BCD code 59 (Set H glyph
  `,`), which would otherwise split a naive comma-separated line in two. A
  literal double quote inside a field (none occur today) would be escaped by
  doubling it, per normal CSV quoting; a parser only needs to implement
  that one escape rule.
- The first line is a header row naming each column, in the order the data
  rows use.
- No comment lines, no blank lines, no trailing blank line after the last
  row.
- An empty field (`""`) means the underlying function returned `null` for
  that input — never the empty string `""` used as real data. The one
  exception is `card_code`, whose real value is legitimately the empty
  string for a blank column (`punches` `0`); that case is distinguishable
  because `card_code` never returns `null` in the first place (it always
  returns a string, so `bcd`/`is_glyph_column` on the same row carry the
  "did this fail" signal, not `card_code` itself).
- All integers are decimal, unprefixed (`"27"`, not `"0x1B"` or `"033"`).

## `char-code-punch-vectors.csv`

One row per punch pattern, `punches` = 0 to 4095 (`0xFFF`, all 4096 possible
12-bit values), in ascending order. Columns:

| Column             | Type          | Source function                          |
|---------------------|---------------|-------------------------------------------|
| `punches`           | integer       | the row index itself                       |
| `bcd`               | integer or "" | `bcdFromPunches(punches)`; "" for `null`   |
| `card_code`         | string        | `cardCodeFromPunches(punches)`             |
| `is_glyph_column`   | `"true"`/`"false"` | `isGlyphColumn(punches)`               |

## `char-code-bcd-vectors.csv`

One row per BCD code, `bcd` = 0 to 63 (`0x3F`, all 64 possible 6-bit codes),
in ascending order. Columns:

| Column             | Type          | Source function                          |
|---------------------|---------------|-------------------------------------------|
| `bcd`               | integer       | the row index itself                       |
| `punches`           | integer or "" | `punchesFromBcd(bcd)`; "" for `null` (the one case is `bcd` 29, octal 35) |
| `glyph`             | string or ""  | `glyphFromBcd(bcd)`; "" for `null`         |
| `machine_special`   | string or ""  | `machineSpecialName(bcd)`; "" for `null`   |

## Regenerating

```
npm run vectors
```

This recompiles the extension and reruns the generator; both files rewrite
in under a second. Run it after any change to `src/charCode.ts`, then run
`npm test` — `test/charCodeVectors.test.js` deep-checks every row against a
fresh call into the same functions, so a stale file fails loudly rather than
silently drifting.
