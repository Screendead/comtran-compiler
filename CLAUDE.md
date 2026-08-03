# CLAUDE.md

## 1. Purpose

This file gives Claude Code (claude.ai/code) the rules for working in this
repository. It holds the rules, not the project state. `docs/HANDOVER.md` holds
the state. **If this file and HANDOVER disagree about state, HANDOVER wins.**

## 2. What this repository is

This project builds a compiler for COMTRAN (IBM Commercial Translator, 1959 to
1962), the pre-COBOL business programming language. The language is recovered
from its two surviving IBM manuals; the compiler is written from that recovery.

State, in one line: the card reader, the three division scanners, the listing,
and the parsers for all three divisions work; no code generation exists yet.
Read `docs/HANDOVER.md` for the live state and the next task.

## 3. Repository map

| Path | What it holds |
|---|---|
| `lib/src/` | The compiler: `cards`, `chars`, `lexer`, `parser`, `ast`, `listing`, `emulator`, and `mcp` |
| `bin/` | The executables: `comtranc.dart` (the compiler), `deckconv.dart` (the deck CLI), `deckmcp.dart` (the MCP server) |
| `test/` | The Dart tests, plus `test/goldens/`, `test/emulator/`, and `test/fixtures/` (the 90.05 canon deck, its mirror, and the keying notes) |
| `tool/` | Dart generators for this package |
| `editors/vscode-punchcard/` | The VS Code punchcard extension (TypeScript, npm) |
| `docs/` | The language definition, HANDOVER, and `docs/design/` |
| `comtran-manuals/` | The two manual conversions and their page scans. **Read-only.** |

## 4. Commands

The Dart SDK constraint is `^3.12.0`. Run these from the repository root:

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib bin test tool
dart analyze --fatal-infos
dart test
dart run comtran:deckconv check .
dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctdeck   # compile the sample
```

CI runs the same gate on every pull request. `.github/workflows/` is the
authority on what CI runs. Two notes:

- `--fatal-infos` is strict. One info-level lint or one unformatted file fails
  the build. The gate covers `lib`, `bin`, `test`, and `tool`.
- The golden listing test (`test/listing_test.dart` against
  `test/goldens/90.05-payroll.listing`) is the acceptance oracle for the front
  end. It compares byte for byte.

For the extension, run these in `editors/vscode-punchcard/`:

```sh
npm ci
npm run compile
npm run grammar        # regenerate the TextMate grammar
node --check media/punchcard.js
node --test "test/**/*.test.js"
```

## 5. Card decks

A COMTRAN program is a deck of punched cards. Each deck is a pair of files:

- `X.ctdeck` — **canon**, a binary punch-level card image. It is authoritative.
- `X.deck` — **mirror**, generated text, one line per card, for review and
  diffs.

The rules:

1. The compiler and every tool read canon only. Address a deck by its `.ctdeck`
   path.
2. **Never hand-edit a `.deck` mirror.** The next regeneration discards the
   edit, and CI rejects a stale pair.
3. Change a deck through `deckconv` or the MCP deck tools. They rewrite the
   canon file and regenerate the mirror together.
4. Read `.claude/skills/comtran-decks/SKILL.md` before you touch a deck.

The format is frozen. An amendment needs a new format version byte.
`docs/design/deck-format.md` holds the formats, the workflow, and the two
one-time git settings — the hook path and the textconv diff driver. A fresh
clone does not have them.

## 6. Documents and authority

| Document | What it governs |
|---|---|
| `docs/HANDOVER.md` | Project state, the roadmap, and the next task |
| `docs/design/decisions.md` | The D-number decision slate. Every record binds the code. |
| the other files in `docs/design/` | The per-milestone and per-component design records |
| `docs/comtran-language-definition.md` | The source language |

Two rules keep these apart:

- The definition holds language facts only. It holds no design.
- The design records hold design only. They add no language claims. Where a
  source leaves a gap, the record closes it and says so.

Amend a decision by an explicit edit to its record, never silently. Cite the
manual evidence in the amendment.

## 7. The language definition

`docs/comtran-language-definition.md` is the working language reference for all
compiler work. Consult it first. Fall back to the manuals for anything it does
not settle. Four rules:

- It defines the source language only. Never add compiler architecture, an
  intermediate representation, grammar files, or implementation material to it.
- **J28-6169 is authoritative over F28-8043** wherever they diverge. Its
  "Sources and authority" section states this rule in full, with the fidelity
  conventions and the citation style. That section is their one home. §8.3
  catalogs the divergences and §8.5 the ambiguities.
- §8.5 and the final Open Questions list are living lists. When design work
  resolves or refutes an item, update the entry. Do not delete it. Keep the
  citation trail.
- Correct it only against the manuals or their page scans. Never correct it
  against modern expectations or COBOL knowledge.

## 8. The manuals

| Manual | Index file | What it is |
|---|---|---|
| **F28-8043** (June 1960) | `comtran-manuals/F28-8043/F28-8043.md` | *General Information Manual* — the 1960 language design |
| **J28-6169-1** (Jan 1962) | `comtran-manuals/J28-6169/J28-6169.md` | *709/7090 Processor Preliminary Reference Manual* — the implemented language |

Five rules to hold in memory:

1. The conversions are read-only. Do not edit them, and do not edit the source
   PDFs.
2. J28-6169 outranks F28-8043 wherever they diverge.
3. Cite F by printed page (`F p. 42`) and J by IBM section code
   (`J 02.05.05`).
4. The page scan decides a disputed reading.
5. Do not "fix" the 1960s text. Authentic spellings ("alphameric", "imbedded")
   and genuine typos are preserved by design.

`comtran-manuals/README.md` holds the rest: the marker forms, the fidelity
examples, and the page-offset rule.

Where to look for language-definition material:

- **Compiler control cards:** J28-6169 02.01.
- **Core language spec:** J28-6169 02.04 Procedure, 02.05 Data, 02.06
  Environment, 02.07 Input/Output, plus F28-8043 chapters 2 to 4.
- **Machine symbolic language (CRYPT):** J28-6169 02.08.
- **Reserved words:** F28-8043 Appendix 2.
- **Generated code:** J28-6169 Appendix 90.02. **Object deck format:** 90.03.
- **Error messages and severity codes:** J28-6169 Appendix 90.04.
- **Complete compiled sample program:** J28-6169 Appendix 90.05.
- **Loader symbolic cards:** J28-6169 Appendix 90.08.
- **Deferred features and restrictions:** J28-6169 Appendix 90.01.

## 9. Evidence rules

- The page scan is ground truth. Each manual directory holds a 150-dpi scan of
  every page at `images/page-NNN.png`, where NNN is the zero-padded PDF page
  number. Check the scan before you conclude anything about a doubtful reading.
- **For any claim about card columns, measure the page scan.** Never read a
  column position out of the indentation of a transcription. Two corrections
  came only from a scan measurement (`docs/HANDOVER.md`).
- Label external period evidence `(external: …)`. It is admissible for what the
  manuals delegate.
- A change to a conversion needs Jack's explicit authorization. HANDOVER lists
  the erratum candidates that wait for it.

## 10. Generated files

Do not edit these by hand:

| File | Generator |
|---|---|
| `lib/src/lexer/message_catalog.dart` | `dart run tool/generate_message_catalog.dart` |
| `editors/vscode-punchcard/syntaxes/comtran-deck.tmLanguage.json` | `npm run grammar` |
| every `*.deck` mirror | `dart run comtran:deckconv regen <path>` |

A golden test guards each one. A hand edit fails that test with no obvious
cause.

## 11. Workflow

- Branch off master with a topic slug, for example `m2-procedure`. Do not commit
  to master.
- One pull request per topic. The remote is `Screendead/comtran-compiler`.
- CI must pass before a merge. Run the section 4 gate before you push.
- Write short, imperative, jargonless commit messages.
- Make atomic commits. Each component must work in each commit. Never split a
  working component across two commits.
- Ultracode mode (Jack's multi-agent workflow mode): hand-pick the model for
  every worker. Pick the least powerful model that can do the job. Do not spawn
  a workflow of 15 top-tier agents.

## 12. Response style: ASD-STE100 Simplified Technical English (Issue 9)

**Scope.** STE governs repo prose documents and assistant responses. Exempt:
verbatim manual quotes and citations, code, code comments, and commit messages.
Never rewrite exempt text to fit STE — a rewritten transcription breaks ground
truth.

Within that scope:

- Write short, simple sentences. One main idea per sentence. Descriptive
  sentences stay at or below 25 words; procedural sentences at or below 20.
- Use active voice, and the imperative for procedures. Use passive voice only
  when the agent is unknown.
- Prefer a direct verb over a nominalization: "remove the unit", not "perform
  the removal of the unit".
- Use simple tenses only: infinitive, imperative, simple present, simple past,
  simple future, and the past participle as an adjective. Avoid progressive and
  perfect forms.
- Keep a multi-word noun to three words at most.
- Use one word for one meaning. Avoid synonyms, metaphors, and figurative
  language.
- Prefer a vertical list to a run-on sentence, and a table to dense prose.
- Explain a technical term at first use, then use it consistently.

If a concept does not fit these constraints, state the limitation in one
sentence and give the clearest approximation.
