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
the parsers for all three divisions, and the job-stream driver work; code
generation fills every word of the object program, prints the whole object
listing of the 1962 sample byte for byte, and issues its diagnostics; the
deck writer punches the object deck and the loader cards, and our loader
reads them back; the machine assembly comes next. Read `docs/HANDOVER.md`
for the live state and the next task.

## 3. Repository map

| Path | What it holds |
|---|---|
| `lib/src/` | The compiler: `cards`, `chars`, `lexer`, `parser`, `ast`, `data`, `codegen`, `loader`, `driver`, `listing`, `emit`, `emulator`, and `mcp` |
| `bin/` | The executables: `comtranc.dart` (the compiler), `deckconv.dart` (the deck CLI), `deckmcp.dart` (the MCP server) |
| `test/` | The Dart tests, plus `test/goldens/`, `test/emulator/`, and `test/fixtures/` (the 90.05 canon deck, its mirror, and the keying notes) |
| `tool/` | Dart generators for this package |
| `editors/vscode-punchcard/` | The VS Code punchcard extension (TypeScript, npm) |
| `docs/` | The language definition and its generated browser mirror `docs/definition/`, HANDOVER, and `docs/design/` |
| `comtran-manuals/` | The two manual conversions and their page scans. **Read-only.** |

## 4. Commands

The Dart SDK constraint is `^3.12.0`. Run these from the repository root:

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib bin test tool web
dart analyze --fatal-infos
dart test
dart run comtran:deckconv check .
dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctd   # compile the sample
```

CI runs the same gate on every pull request. `.github/workflows/` is the
authority on what CI runs. Two notes:

- `--fatal-infos` is strict. One info-level lint or one unformatted file fails
  the build. The gate covers `lib`, `bin`, `test`, `tool`, and `web`.
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

- `X.ctd` — **canon**, a binary punch-level card image. It is authoritative.
- `X.ct` — **mirror**, generated text, one line per card, for review and
  diffs.

The rules:

1. The compiler and every tool read canon only. Address a deck by its `.ctd`
   path.
2. **Never hand-edit a `.ct` mirror outside VS Code.** The next regeneration
   discards the edit, and CI rejects a stale pair. In VS Code, a mirror save
   runs `deckconv to-canon`: the edit becomes the deck, or the tool rejects
   the text and the pair stays stale until you fix it.
3. Change a deck through `deckconv`, the MCP deck tools, or a VS Code save
   of either file. Each rewrites the canon file and regenerates the mirror
   together.
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
| `REVIEW.md` | The criteria for every code review. `/code-review` injects the file into each review agent. |
| `EXTERNAL-REVIEW.md` | The external-review charter: the two-family review loop and the merge rule |

Two rules keep these apart:

- The definition holds language facts only. It holds no design.
- The design records hold design only. They add no language claims. Where a
  source leaves a gap, the record closes it and says so.

Amend a decision by an explicit edit to its record, never silently. Cite the
manual evidence in the amendment.

### Collisions

A collision is any case where two authorities in this repository require
different things, and satisfying one breaks the other.

Most collisions are already settled, because this repository ranks its
sources. Where a rank applies, obey it and do not ask:

| Higher | Lower | Stated in |
|---|---|---|
| the page scan | a manual conversion | sections 8 and 9 |
| J28-6169 | F28-8043 | section 8 |
| the manuals | the language definition | section 7 |
| `docs/HANDOVER.md` | this file, on project state | section 1 |
| a design record | the code | section 6 |

Amend the lower source to match the higher one, and cite the rank in the
amendment. A change to a manual conversion is the exception: it needs
Jack's authorization first (section 9).

**Where no rank covers the two sources, they are peers. Stop and bring a
peer collision to Jack. Never settle one alone.** Present it this way, in
plain English, with no jargon and no internal shorthand:

1. Name the two things that collide, and quote the text of each.
2. State what each one would have you do.
3. Give every option, including the option to change one of the two
   documents. For each, state the concrete consequence: what breaks, what
   is left unbuilt, what a later reader is misled about, and what it costs
   to reverse.
4. Recommend one, and say why.

Build it as a review record, not as a chat message. Section 12 holds the rule
and `.claude/skills/review-records/SKILL.md` holds the how.

Then wait. This holds even when one option is obviously better, and even
when the work is already done — if a collision surfaces after the fact,
flag it with the same four parts and say plainly that it is already
committed.

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

### The sealed source (D0.9)

The 1963 Commercial Translator survives, compiler and runtime library both, in
a recovered IBSYS archive. **Do not read it, and do not search it, for any
answer to any question in this repository.** The seal ends when M7 opens.

The seal is not a doubt about the archive. The archive is genuine, and it is
the best evidence this project will ever hold. The seal exists because the
result depends on it. The project reconstructs COMTRAN from the manuals, and M7
then measures the distance between that reconstruction and the surviving
processor. One lookup before M7 destroys the measurement, for every later
reader as well as for us.

Five rules follow:

1. The seal covers the whole archive. Source, listings, object files, and every
   sibling subsystem directory are inside it. IOCS is inside it too.
2. Before M7, cite nothing from the archive. This binds design records, Open
   Questions, emulator rules, and runtime handler contracts.
3. To name the seal is not to read it. Write "evidence exists and is sealed
   until M7" where a record would otherwise say that no evidence survives.
4. Downloading and checksumming for M7 tooling is permitted. Reading content is
   not.
5. If a task appears to need the archive, it does not. Use the manuals, and
   record the gap as an Open Question.

`docs/design/decisions.md` D0.9 holds the find, the decision, and the boundary
list of what was read before the seal. The review record
`review/2026-09-06-emulator-reuse` is the evidence for D0.9 and quotes those
excerpts. It is inside the boundary and it is not a breach. **A quotation from
the archive anywhere else is a broken seal: stop and tell Jack.**

## 10. Generated files

Do not edit these by hand:

| File | Generator |
|---|---|
| `lib/src/lexer/message_catalog.dart` | `dart run tool/generate_message_catalog.dart` |
| every file in `docs/definition/` | `dart run tool/generate_definition_mirror.dart` |
| `editors/vscode-punchcard/manual-map.json` | `dart run tool/generate_manual_map.dart` |
| `editors/vscode-punchcard/syntaxes/comtran-deck.tmLanguage.json` | `npm run grammar` |
| every `*.ct` mirror | `dart run comtran:deckconv regen <path>` |
| the manual-link block at the end of a markdown file | `dart run tool/linkify_manual_refs.dart` |

A golden test guards each one. A hand edit fails that test with no obvious
cause.

The link block holds one definition per manual citation. Write a citation in
its plain form, `J 02.03.02` or `F p. 42`, and run the linkifier. It adds the
brackets and rewrites the block. It never touches a citation inside a code
span, a code block, a blockquote or a quotation.

## 11. Code standards

### No untested and unexercised code

Code that no test asserts on **and** that no program run reaches must not
enter the repository. Delete it. This is a hard rule, not a preference.

Two words carry the rule, and they are not the same test:

- **Exercised** — a normal run of the compiler or a tool reaches the code.
- **Tested** — a test asserts on what the code does.

Four cases follow. Only the last one is banned:

| Exercised | Tested | Verdict |
|---|---|---|
| yes | yes | Good. Nothing to do. |
| yes | no | Permitted, with caution. The code has a caller, so a change to it can break the program silently. Prefer to add the test. |
| no | yes | Permitted. Keep watch: the code needs a concrete plan to get a caller. Record the plan in the design record that asks for the code. |
| no | no | **Banned. Delete it.** |

The rule binds a whole symbol and each of its parts: an unread field, an
unused parameter, an unreachable branch, and a constant with no reader are
each dead on their own, inside a class that is otherwise alive.

Two consequences to expect:

- **Do not write scaffolding for a later milestone.** Where nothing yet
  asks for the shape, do not write it, and say so in the pull request.
- **A design record that requires banned code is a peer collision.** No
  rank in section 6 covers this file against a design record. Do not
  delete the code, and do not amend the record. Stop and bring it to Jack
  under the section 6 collision rule.

## 12. Workflow

- Branch off master with a topic slug, for example `m2-procedure`. Do not commit
  to master.
- One pull request per topic. The remote is `Screendead/comtran-compiler`.
- CI must pass before a merge. Run the section 4 gate before you push.
- Do not ask permission to make a branch, to commit to it, or to push it. Do
  ask before you open a pull request: that call is Jack's. Two merge rules
  govern. A pull request that changes a file under `lib/` or under
  `test/goldens/`, or an object-code target under `test/fixtures/`, merges
  on external-review convergence — both reviewers, `VERDICT: LGTM`, the
  same head, under the EXTERNAL-REVIEW.md charter. Every other pull
  request is routine maintenance: it skips the loop and merges on Jack's
  instruction. His instruction to merge is also a waiver of the
  convergence requirement. A pull request that changes REVIEW.md, the
  charter, this section, or the external-review skill merges only on his
  instruction. The charter quotes his standing authorization of
  2026-08-16 in full.
- **A question for Jack is a review record, not a chat message.** Whenever work
  stops and waits for him — a human-OCR request, a peer collision under section
  6, an authorization to change a conversion, a choice between designs — build
  the record first. It is a standalone HTML document with the crops, the
  evidence, an argument and a recommendation per item. His answer goes into the
  same document, the directory is orphan-committed, and the pull request
  references the orphan. Read `.claude/skills/review-records/SKILL.md` before
  you build one. His answer is also the authorization to open that pull
  request, so the review cycle satisfies the rule above.
- **A decision with one viable option does not stop and wait.** Standing rule,
  Jack's call of 2026-08-15. When rank, precedent, and the evidence leave one
  course open, take it. Build the same record, in the same format, but as the
  explanation of a decision made — the `DECIDED` status of the review-records
  skill — with the rejected options and their costs still written out. Jack
  can overturn it; silence lets it stand. The rule never covers a section 6
  peer collision, a change to a manual conversion, or the pull-request and
  merge calls above. Opening waits for Jack; a merge waits for the merge
  rule above.
- Write short, imperative, jargonless commit messages.
- Make atomic commits. Each component must work in each commit. Never split a
  working component across two commits.
- Ultracode mode (Jack's multi-agent workflow mode): hand-pick the model for
  every worker. Pick the least powerful model that can do the job. A cheap
  model does search and mechanical edits; design and review need a top-tier
  model. Do not spawn a workflow of 15 top-tier agents.
- In a workflow worker prompt, never pipe `dart test` through `head` — the
  test runner hangs when `head` exits early. Pipe through `tail -40`, check
  that the output ends with "All tests passed!", and set a 300-second
  timeout.
- A multi-agent refactor gets an independent adversarial review before merge.
  The reviewer starts with fresh context and reads the diff and the
  repository, never the author's plan or rationale. Every finding must cite
  file:line and quote the text.

## 13. Prose style: ASD-STE100 Simplified Technical English (Issue 9)

**Scope.** STE governs repo prose documents only. It does not govern assistant
responses; those follow the Density rules below. Exempt: verbatim manual quotes
and citations, code, code comments, commit messages, the two front-door
documents, `README.md` and `CONTRIBUTING.md`, and the website copy. Never
rewrite exempt text to fit STE — a rewritten transcription breaks ground truth.

The front-door exemption is Jack's call, made 2026-08-07. Those two documents
have one job: to bring in a reader who does not yet know what COMTRAN was or
why the project exists. STE's ban on metaphor and its one-word-one-meaning rule
serve a maintenance manual, not a first page, and the flatness they produce
costs a reader this project needs. The exemption covers those two files by
name. Every other document under `docs/` follows STE.

The website exemption is Jack's call, made 2026-08-10: the site copy "has to
have a whole different register". `docs/design/web-copy.md` holds that register
and the rules that carry it, and the site follows that record in place of this
section. The record itself is a repository document, so STE governs it.

The catalog exemption is Jack's call, made 2026-08-16. It covers the §8.5
ambiguity catalog and the final Open Questions list of the language
definition. Their entries chain inference between quoted fragments, and some
entries of the Open Questions list run past two thousand words. A reflow into short sentences risks a silent
change to an evidentiary claim, which the section 9 evidence rules exist to
prevent. The sentence-length and list-preference rules do not bind those
entries; every other rule of this section still does.

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

### Density

These rules govern assistant responses, at the paragraph and response level:

- Open every response with the point, in one sentence that stands alone.
- One new idea per paragraph. Two to four sentences per paragraph.
- Give the short answer by default. Name what you left out in one line; do
  not include it.
- Do not use invented shorthand that points at an earlier label. Restate the
  thing in place.
- Prefer one concrete example to one abstraction.
