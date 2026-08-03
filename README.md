# COMTRAN Compiler

A project to build a compiler for **COMTRAN** (IBM Commercial Translator), the
1959–1962 pre-COBOL business programming language — recovered from its two
surviving manuals, and rebuilt from there.

## What COMTRAN was

Commercial Translator was IBM's business data-processing language of the
immediate pre-COBOL era. A June 1960 *General Information Manual* (F28-8043)
defined it. A field-test compiler for the IBM 709/7090 implemented it, and a
January 1962 *Preliminary Reference Manual* (J28-6169-1) documents that
compiler. Its sample listing was compiled on 18 October 1961.

A programmer writes a COMTRAN program on card forms in three portions:
Procedure, Data Description, and Environment. Procedure statements are
English-like imperative sentences — `MOVE`, `SET`, `GET`, `FILE`, `DO`,
`GO TO … WHEN …` — over period-joined compound names such as
`END.OF.MASTERS`. Data descriptions are pictorial. File handling is
tape-oriented.

Commercial Translator counts, beside FLOW-MATIC, as one of the principal inputs
to COBOL. It then disappeared: no compiler survives, and no machine-readable
source.

This repository is the recovery-and-rebuild effort. First the language,
reconstructed from primary sources under strict citation discipline. Then a
working compiler for it.

## Status

`docs/HANDOVER.md` holds the live project state, the roadmap, and the next task.
In brief: the language definition is complete and verified; the compiler's front
end and its parsers for all three divisions work; code generation does not exist
yet.

## What is here

| Path | What it is |
|---|---|
| `lib/` | The compiler source. `lib/src/` holds `cards`, `chars`, `lexer`, `parser`, `ast`, `listing`, `emulator`, and `mcp`. |
| `bin/` | Three executables: `comtranc.dart` (the compiler), `deckconv.dart` (the deck CLI), and `deckmcp.dart` (the MCP deck server). |
| `test/` | The Dart test suite, with `test/goldens/` (the 1962 listing oracle) and `test/emulator/`. |
| `tests/` | Reference deck data: the 90.05 canon deck, its text mirror, and the keying notes. |
| `tool/` | Dart generators for this package. |
| `tools/vscode-punchcard/` | A VS Code extension: a punch-level editor for `*.ctdeck` decks, and highlighting for `.deck` mirrors. |
| `docs/design/` | Six design records: the D0–D9 decision log (`decisions.md`, 84 records), one document per milestone (`m1-front-end.md`, `m2-parser.md`), plus `deck-format.md`, `emulator.md`, and `severity-notes.md`. |
| `docs/comtran-language-definition.md` | The working language reference (~4,250 lines): a structured, fully cited definition of COMTRAN extracted from the manuals. §8.3 catalogs the F/J divergences and §8.5 every ambiguity with a plausible resolution. The end-of-file **Open Questions** list tracks what the sources cannot settle, and states its own item count. |
| `docs/HANDOVER.md` | Project state, the roadmap, and the next task. |
| `docs/research-2026-08-01-interrupted.md` | **Archive, provenance only.** Raw, unverified output of the research passes. The definition supersedes it. Do not read it for current work. |
| `comtran-manuals/` | Faithful Markdown conversions of both manuals, with a 150-dpi scan of every page as ground truth. **Read-only.** Citation and fidelity conventions in `comtran-manuals/README.md`. |
| `comtran-manuals/F28-8043/` | *General Information Manual* (June 1960) — the 1960 language design. |
| `comtran-manuals/J28-6169/` | *709/7090 Processor Preliminary Reference Manual* (Jan 1962) — the implemented field-test language. **Authoritative wherever the two manuals diverge.** |

## Development

The project needs Dart SDK `^3.12.0`. Run these from the repository root:

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib bin test tool
dart analyze --fatal-infos
dart test
dart run comtran:deckconv check .
```

CI runs the same gate on every pull request. `--fatal-infos` is strict: one
info-level lint fails the build.

To compile the manual's own payroll sample through the front end and the parser,
and print its listing:

```sh
dart run comtran:comtranc tests/90.05-payroll.ctdeck
```

The listing is numbered exactly as the 1962 compile numbered it. A golden test
compares it byte for byte.

The VS Code extension has its own npm project. Run `npm ci`, `npm run compile`,
and `npm test` in `tools/vscode-punchcard/`.

## Working with card decks

Program sources are punch-level card-image files (`*.ctdeck`, binary). Each one
has a generated text mirror (`*.deck`) committed beside it for review and diffs.
The compiler and all tools read canon only. Never hand-edit a mirror; CI rejects
a stale pair. `dart run comtran:deckconv` prints the usage.

`docs/design/deck-format.md` §6 holds the deck workflow and the two one-time git
settings — the pre-commit hook path and the readable-diff textconv driver.
`.claude/skills/comtran-decks/SKILL.md` holds the same workflow for an agent
session.

## Method

Parallel extraction over both manuals built the definition. Adversarial
verification then checked it: every verbatim quote character for character,
every numeric limit and citation re-derived, and every disputed reading settled
at 400–600 dpi against the page scans. Deepening passes mined the
generated-code appendix (J 90.02), the compiled sample-program listing (J 90.05,
pixel-verified), and external period sources — the 709/7090 IOCS manual
C28-6100-2, and the IBM 705 and 1401 references — to settle questions the
manuals delegate.

## Ground rules

- The manual conversions are ground truth and read-only. When a transcription is
  doubted, the page scan decides.
- **J28-6169 outranks F28-8043** wherever they diverge. F is the 1960 design; J
  is the implemented 1962 language.
- Correct the definition only against the manuals or their scans. Never correct
  it against COBOL knowledge or modern expectations. External period evidence is
  admissible for what the manuals delegate, always labeled `(external: …)`.
- The definition stays design-free. Compiler architecture and implementation
  decisions live in `docs/design/`.

## Roadmap to a compiler

`docs/HANDOVER.md` holds the detail and the current status of every item.

- **M0** — commit to the target language (J), and walk §8.5 recording one
  semantic decision per entry.
- **M1** — column-aware card reader, lexer, and listing.
- **M2** — parser and diagnostics for all three divisions, against the 90.04
  message catalog.
- **M3** — Data Description semantics and storage mapping.
- **M4** — code generation for the core verb subset.
- **M5** — the I/O runtime.
- **M6** — acceptance: compile and run the manual's own payroll sample, and
  reproduce its printed report output (J 90.05, PDF p. 217).
