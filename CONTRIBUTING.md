# Contributing

This project recovers COMTRAN — IBM's Commercial Translator, 1959–1962 — from
the two manuals that survive it, and builds a compiler from that recovery.
[`README.md`](README.md) explains what that means and why anyone bothered.

Two things are worth knowing before you read further.

**This file is not an authority.** It describes how to work here; it settles
nothing. `CLAUDE.md` holds the rules, `docs/design/decisions.md` binds the
code, and `docs/HANDOVER.md` holds the project state. If this file disagrees
with any of them, they win and this file is stale.

**The most valuable contribution needs no code at all.** Read the next section
before the ones about Dart.

## The help this project actually needs

Everything here rests on a single scanned copy of each manual, read and
corrected by one person. That is the ceiling on how much anyone should trust
it, and no amount of internal rigour raises it. Outside evidence does.
`docs/opportunities.md` ranks these in full; these three are the ones that
need someone who is not us.

**A second scan of either manual.** A different physical copy of F28-8043 or
J28-6169-1, scanned by different people at a different time. Two readers of
one scan can only agree about that scan; two scans of two copies are
independent witnesses to the printing. Microfiche counts. A photographed
original counts. Worth trying: bitsavers and its mirrors, the Internet
Archive, the Computer History Museum, university libraries that held IBM
systems documentation, the IBM corporate archive, and collectors on the
classic-computing lists.

If you look and find nothing, **tell us that too, and say where you looked.**
"No second copy exists at these eleven places" is a real result and it belongs
in the record.

**Any other surviving COMTRAN artifact.** A source deck, a listing, an object
deck, a memo, a course handout. The compiled payroll sample in Appendix 90.05
is currently the only COMTRAN program anyone has with known-correct output.
A second one would be worth more than every internal check in this repository
put together.

**A domain reading.** If you know the IBM 709/7090, period compiler
construction, or the pre-COBOL language landscape, the useful thing is to
disagree with us in public. `docs/reconstruction-method.md` §10 lists what the
method cannot do, and the language definition's Open Questions list holds what
the sources will not settle. Both are places to start an argument.

Open an issue for any of these. Evidence beats opinion, and a citation beats
a recollection — but a recollection is still worth having, marked as one.

## How the project decides things

Read [`docs/reconstruction-method.md`](docs/reconstruction-method.md) first.
It states how a question gets settled when the sources are thin, silent, or in
conflict; how far inference is allowed and how it is marked; and how much of
the work large language models did. It is the document that answers "why
should I believe any of this".

Four rules follow from it and will shape any change you propose:

- **The page scan decides.** Every disputed reading goes to
  `comtran-manuals/*/images/page-NNN.png`. For any claim about card columns,
  measure the scan. Never read a column position out of the indentation of a
  transcription.
- **J28-6169 outranks F28-8043** wherever they diverge. F is the 1960 design;
  J is the language the field-test compiler actually accepted.
- **The manual conversions are read-only.** They are ground truth. A
  correction to one needs Jack's explicit authorization and a scan
  measurement to justify it.
- **Never present a choice as history.** Where the sources are silent, the
  project decides and says so. An unmarked invention is the one failure this
  method cannot absorb.

## Working on the compiler

You need the Dart SDK, version `^3.12.0`. `dart pub get` from the repository
root, and you are set up.

The acceptance check is one command:

```sh
dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctd
```

That compiles the manual's own payroll program and prints its listing,
numbered exactly as IBM's compiler numbered it on 18 October 1961. A golden
test compares the result to the printed page byte for byte.

Before you push, run the same gate CI runs. `.github/workflows/ci.yml` is the
authority on what that is — read the steps there rather than trusting a copy
in prose. Two of them catch people out: `dart analyze --fatal-infos` fails the
build on a single info-level lint, and `dart format` fails it on a single
unformatted file.

| Where | What it holds |
|---|---|
| `lib/src/` | The compiler: `cards`, `chars`, `lexer`, `parser`, `ast`, `data`, `codegen`, `driver`, `listing`, `emit`, `emulator`, `mcp` |
| `bin/` | `comtranc.dart` (compiler), `deckconv.dart` (deck CLI), `deckmcp.dart` (MCP deck server) |
| `test/` | The suite, plus `goldens/` (the 1962 listing oracle), `emulator/`, and `fixtures/` (the 90.05 deck and its keying notes) |
| `tool/` | Generators. Never hand-edit their output; `CLAUDE.md` §10 lists every generated file |
| `docs/design/` | The design records. `decisions.md` is the slate everything else builds on |
| `editors/vscode-punchcard/` | A VS Code punch-level card editor (TypeScript, its own npm project) |

The extension has its own gate: `npm ci`, `npm run compile`, `npm test` in
`editors/vscode-punchcard/`.

## Card decks

A COMTRAN program is a deck of punched cards, and this repository keeps them
that way. Each deck is a pair: `X.ctd` is a binary punch-level card image and
is canonical; `X.ct` is a generated text mirror committed beside it so that
diffs and reviews are readable.

Three rules, and the first one is the one people break:

1. **Never hand-edit a `.ct` mirror.** The next regeneration discards your
   edit, and CI rejects a stale pair. Change a deck through `deckconv`, the
   MCP deck tools, or a VS Code save — each rewrites canon and regenerates the
   mirror together.
2. The compiler and every tool read canon only. Address a deck by its `.ctd`
   path.
3. The format is frozen. Amending it needs a new format version byte.

[`docs/design/deck-format.md`](docs/design/deck-format.md) holds the formats,
the workflow, and two one-time git settings a fresh clone does not have — the
hook path and the readable-diff textconv driver. Set those up before your
first deck change.

## Two standards that reject code

**No untested and unexercised code.** Code that no test asserts on *and* that
no program run reaches must not enter the repository. This binds a whole
symbol and each of its parts: an unread field, an unused parameter, an
unreachable branch. The practical consequence is that scaffolding for a later
milestone does not get written. `CLAUDE.md` §11 holds the full rule and the
cases it permits.

**Documents hold one kind of thing each.** The language definition holds
language facts and no design. The design records hold design and add no
language claims. Where a source leaves a gap, the design record closes it and
says so.

## Pull requests

Branch off `master` with a topic slug. One pull request per topic. CI must
pass. Commit messages are short, imperative, and free of jargon, and each
commit leaves every component working.

Substantial changes get an adversarial review before merge, by a reviewer who
reads the diff and the repository but never the author's rationale. If you
have written something you cannot defend from the sources alone, that is where
it will surface.

## License

Code and documents written for this project are GPL-3.0-only. The IBM material
under `comtran-manuals/`, and anything transcribed from it, is not ours and is
included for preservation and scholarship — [`README.md`](README.md) states
the position in full. By contributing you agree your work goes under the same
license as the rest of the project.
