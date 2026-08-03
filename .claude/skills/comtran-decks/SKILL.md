---
name: comtran-decks
description: Read, write, and check COMTRAN card decks (.ctdeck canon files and their .deck text mirrors) with deckconv and the comtran-decks MCP server.
---

# COMTRAN card decks

A COMTRAN program is a deck of punched cards. This repository keeps each deck
in two files:

| File | Role |
|---|---|
| `X.ctdeck` | **Canon.** A binary punch-level card image. Authoritative. |
| `X.deck` | **Mirror.** Generated text, one line per card. For review and diffs. |

The format is frozen. Read `docs/design/deck-format.md` before you change any
deck. Decisions D0.5 and D0.6 govern it.

## The rules

1. **The canon file is the authority.** The compiler and every tool read canon
   only. Address a deck by its `.ctdeck` path. The MCP server rejects a path
   outside your declared workspace root.
2. **Never hand-edit a `.deck` mirror.** A mirror is a generated artifact. An
   edited mirror is lost at the next regeneration, and CI fails it.
3. **Change a deck through the tools.** `deckconv`, `deck_write`, and
   `deck_edit_cards` rewrite the canon file and regenerate the mirror
   together, so the pair stays fresh. **Exception:** the VS Code punchcard
   editor writes only the canon file. Run `deckconv regen` after an editor
   save, or use the opt-in pre-commit hook below, before you trust the
   mirror.
4. **Keep pairs complete.** A canon file with no mirror, a mirror with no canon
   file, or a stale mirror all fail `deckconv check`.

## Mirror text (normal form)

One line per card, in deck order. ASCII, LF endings, a final LF, no trailing
spaces. Each line has one of two forms:

- **Glyph line** — the Set H characters of columns 1–80, trailing blanks
  removed. Used when every column is blank or one of the 48 source-set
  characters (`A–Z 0–9 blank + - * / ( ) , . $ = '`). A blank card is an empty
  line.
- **Punch line** — `!` and then one `<column>:<rows>` field per punched column,
  in ascending column order, e.g. `! 1:12-5-8 72:9`. Used for every other card:
  machine specials, object decks, and illegal punch patterns.

The tools reject text that is not in normal form and name the offending card.

## The `deckconv` CLI

```
dart run comtran:deckconv to-canon <in.deck> <out.ctdeck>   # text to canon
dart run comtran:deckconv to-text  <in.ctdeck> [<out.deck>] # canon to text
dart run comtran:deckconv regen    <path>...                # rewrite mirrors
dart run comtran:deckconv check    <path>...                # verify freshness
```

A path may name a file or a directory. A directory is searched. `check` exits
non-zero on any failure; CI runs it.

Two optional local settings:

- Pre-commit hook that regenerates mirrors for staged canon files:
  `git config core.hooksPath .githooks`
- Readable binary diffs:
  `git config diff.ctdeck.textconv 'dart run comtran:deckconv to-text'`

## The MCP server

`bin/deckmcp.dart` serves the same operations over the Model Context Protocol,
with structured JSON results. Register it once:

```
claude mcp add comtran-decks -- dart run comtran:deckmcp
```

Then use these tools:

| Tool | What it does |
|---|---|
| `deck_read` | Reads a canon deck: card count, mirror text, mirror freshness. Set `include_cards` (with `start_card` and `max_cards`, up to 100, 25 by default) for the per-card structured form; that form reports `cards_returned` and `next_start_card` instead of the full mirror text, so page through a long deck. |
| `deck_write` | Writes normal-form mirror text to a canon path and regenerates the sibling mirror. Rejects bad text and writes nothing. Give `expected_mirror` to fail with a conflict instead of overwriting a change made since you last read the deck. |
| `deck_edit_cards` | Replaces a range of cards (`start_card`, `delete_count`, `insert_lines`) without sending or returning the whole mirror. Also takes `expected_mirror`. |
| `deck_card` | Describes one card: glyph line, punch notation, and the card code, BCD code, glyph, and name of every punched column. |
| `card_code_info` | Looks one character up. Give exactly one of `glyph`, `card_code` (e.g. `12-5-8`), or `bcd_octal`. |
| `deck_check` | Runs the `deckconv check` verification and reports structured results. |

A failed call always sets `isError`. The shape of the failure depends on where
it was caught:

- **A tool's own check fails.** The call returns `{"error": {"kind": ...,
  "message": ...}}` in `structuredContent`. The kinds are `not_found`,
  `not_a_file`, `bad_extension`, `format`, `out_of_range`,
  `invalid_argument`, `unknown_glyph`, `bad_card_code`, `conflict`,
  `forbidden_path`, and `io`.
- **Argument validation fails, or an internal error is not one of the tool's
  own checks.** The call returns plain text in `content[0].text` — no
  `structuredContent`, no `error` object, and none of the kinds above. This
  is the shape of a misspelled or out-of-range argument, and of an unknown
  tool name.

Prefer the MCP tools when you work inside an agent session; prefer `deckconv`
in scripts, hooks, and CI.

## Where to look next

- `docs/design/deck-format.md` — the frozen formats, the read rules, and the
  64-code table.
- `docs/design/decisions.md` — D0.5 (deck format and authority) and D0.6 (the
  character code).
- `tests/90.05-payroll.ctdeck` — the reference deck, from J28-6169 Appendix
  90.05.
