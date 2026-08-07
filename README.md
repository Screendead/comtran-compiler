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
end, its parsers for all three divisions, and the job-stream driver work; code
generation prints the storage map and generates no procedure text yet.

## What is here

| Path | What it is |
|---|---|
| `lib/` | The compiler source. `lib/src/` holds `cards`, `chars`, `lexer`, `parser`, `ast`, `data`, `codegen`, `driver`, `listing`, `emit`, `emulator`, and `mcp`. |
| `bin/` | The executables: `comtranc.dart` (the compiler), `deckconv.dart` (the deck CLI), and `deckmcp.dart` (the MCP deck server). |
| `test/` | The Dart test suite, with `test/goldens/` (the 1962 listing oracle), `test/emulator/`, and `test/fixtures/` (the 90.05 canon deck, its text mirror, and the keying notes). |
| `tool/` | Dart generators for this package. |
| `editors/vscode-punchcard/` | A VS Code extension: a punch-level editor for `*.ctd` decks, and highlighting for `.ct` mirrors. |
| `docs/design/` | The design records: the D0–D11 decision log (`decisions.md`), one document per milestone (`m1-front-end.md`, `m2-parser.md`, `m3-data.md`, `m4-codegen.md`), plus `deck-format.md`, `emit-stages.md`, `emulator.md`, and `severity-notes.md`. |
| `docs/comtran-language-definition.md` | The working language reference (~4,250 lines): a structured, fully cited definition of COMTRAN extracted from the manuals. §8.3 catalogs the F/J divergences and §8.5 every ambiguity with a plausible resolution. The end-of-file **Open Questions** list tracks what the sources cannot settle, and states its own item count. |
| `docs/HANDOVER.md` | Project state, the roadmap, and the next task. |
| `docs/reconstruction-method.md` | How this project decides a question from thin, silent, or conflicting sources, what the method cannot do, and how far large language models did the work. Written so that a person recovering a different extinct language can follow it. It describes the practice; it binds nothing. |
| `comtran-manuals/` | Faithful Markdown conversions of both manuals, with a 150-dpi scan of every page as ground truth. **Read-only.** Citation and fidelity conventions in `comtran-manuals/README.md`. |
| `comtran-manuals/F28-8043/` | *General Information Manual* (June 1960) — the 1960 language design. |
| `comtran-manuals/J28-6169/` | *709/7090 Processor Preliminary Reference Manual* (Jan 1962) — the implemented field-test language. |

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
dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctd
```

The job deck is the 293-card artifact plus one reconstructed *FINISH card. The
listing is numbered exactly as the 1962 compile numbered it. A golden test
compares it byte for byte.

The VS Code extension has its own npm project. Run `npm ci`, `npm run compile`,
and `npm test` in `editors/vscode-punchcard/`.

## Working with card decks

Program sources are punch-level card-image files (`*.ctd`, binary). Each one
has a generated text mirror (`*.ct`) committed beside it for review and diffs.
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
generated-code appendix ([J 90.02]), the compiled sample-program listing ([J 90.05],
pixel-verified), and external period sources — the 709/7090 IOCS manual
C28-6100-2, and the IBM 705 and 1401 references — to settle questions the
manuals delegate.

## Ground rules

- **J28-6169 outranks F28-8043** wherever they diverge. F is the 1960 design; J
  is the implemented 1962 language.
- The manual conversions are ground truth and read-only. When a transcription is
  doubted, the page scan decides.
- The definition stays design-free. Compiler architecture and implementation
  decisions live in `docs/design/`.

The definition's
[Sources and authority](docs/comtran-language-definition.md#sources-and-authority)
section is the one home for the first two rules. It states the F/J rule in full,
the fidelity conventions, and the citation style. Read it there; no other
document repeats the detail.

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
  reproduce its printed report output ([J 90.05], PDF p. 217).

## License

The code and the documents written for this project are copyright © 2026 Jack
Lusher, and licensed under the GNU General Public License, version 3 only. A
later version of that license does not apply. `CITATION.cff` records the same
choice as `GPL-3.0-only`; change the two together. The full text is in
[LICENSE](LICENSE).

The license does not cover the IBM material. `comtran-manuals/` holds page
scans and conversions of two IBM publications from 1960–1962: F28-8043 and
J28-6169-1. Those works belong to IBM, and this repository includes them for
preservation and scholarship. The same applies to material transcribed from
them: the 90.05 sample deck and mirror in `test/fixtures/`, and the golden
listing in `test/goldens/`.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02]: comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.05]: comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
