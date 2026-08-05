# Emit flags — dumpable compilation stages

*Recorded 2026-08-04, from a requirement Jack stated. This record constrains
the compiler's command-line surface and its oracle discipline. It does not
decide the shape of any intermediate representation. That decision belongs to
the M4 design note. M4 must adopt this record or amend it explicitly.*

## The requirement

Every compilation stage must be dumpable behind a flag, for example
`--emit-<stage>`. Each dump is one of two things:

- a reproduction of an attested 1962 artifact, oracled against its manual
  evidence; or
- an explicitly labeled reconstruction, where the manuals are silent.

## The attested checkpoints

The 1962 evidence gives a checkpoint at almost every stage. The table names
each checkpoint, its evidence, and its oracle.

| Stage output | Evidence | Oracle |
|---|---|---|
| Card images | the 90.05 canon deck, keyed from the page scans | `deckconv check` — round-trip and freshness only (D0.5, D0.6); fidelity rests on the keying notes |
| Compilation listing | the [J 90.05] listing pages | the golden listing test, byte for byte |
| `*DATA` storage section | [J 90.05], PDF pp. 199–200 | the M3-14 stage-1 oracle, for the values; the printed lines wait for M4 (M3-14 defers them) |
| Generated code | [J 90.02]; the 90.05 object listing | the D0 listing-diff, at M4 |
| Object deck | [J 90.03] | at M4 |
| Loader cards | [J 90.08] | at M4 or M5 |

No manual attests a compiler intermediate form. CRYPT, the machine symbolic
language ([J 02.08]), is attested only as programmer input, through ENTER
CRYPT. If M4 wants a readable intermediate dump, this record suggests CRYPT's
notation as the candidate — a design decision, not an attested fact. Do not
invent a modern intermediate shape without an explicit design record.

## Binding rules

Three existing rules bind any implementation of this record:

1. A committed dump follows the mirror pattern. A generator writes it, a
   golden or freshness test slaves it to CI, and hand edits are forbidden.
   The `.deck` mirrors (D0.5, D0.6) are the precedent.
2. An invented intermediate form is design, not language. Its record lives in
   this directory, never in the language definition.
3. This record settles no codegen shape and no part of D4.1.

## Timing

M3 stage 2 does not depend on this record. Land the flag plumbing before the
M3 stage-3 listing rewrite if practical; the rewrite is cheaper on top of it.

## The implemented surface (2026-08-05)

The flag plumbing landed before the stage-3 listing rewrite. This section
records the surface and its conventions. Jack made three calls. Each flag
takes a file path, so one compile builds each stage once and serves every
requested dump. The reconstruction dumps get committed goldens. The parse
dump prints the full tree.

### Flags

The path is optional on every flag. The listing on stdout does not change.

| Flag | Short | Stage | Status | Oracle |
|---|---|---|---|---|
| `--emit-cards[=<path>]` | `-c` | card images | attested | byte-identical to the deck's mirror (D0.5) |
| `--emit-scan[=<path>]` | `-s` | front end | reconstruction | golden: `test/goldens/90.05-payroll.scan` |
| `--emit-parse[=<path>]` | `-p` | parse | reconstruction | golden: `test/goldens/90.05-payroll.parse` |
| `--emit-semantics[=<path>]` | `-S` | semantic layer | reconstruction | golden: `test/goldens/90.05-payroll.semantics`, plus the M3-14 fixture values |
| `--emit-listing[=<path>]` | `-l` | listing | attested | the golden listing |

Jack added the short surface 2026-08-05. The one-letter flags bundle:
`-cpsSl` is the full set. `-A` and `--emit-all` request every stage. A
flag without a path writes the default file: the deck's path with its
extension replaced by the stage name, next to the deck. So
`payroll.ctdeck -p` writes `payroll.parse`. A short flag always takes
the default path; a custom path needs the long form. A repeated stage
follows the driver's last-wins idiom.

### Conventions

- A reconstruction dump opens with the label line
  `* RECONSTRUCTION - NO 1962 ARTIFACT ATTESTS THIS FORM`. An attested dump
  never prints it: its bytes must match the attested form.
- A dump holds every job, in deck order. A `* JOB n` line opens each job's
  section. The cards dump is the whole deck's mirror and has no job
  sections.
- A stage that an earlier stop kept from running prints
  `* STOPPED BEFORE THIS STAGE` as its whole section (D10.2).
- A stage that stopped mid-run prints `* STOPPED IN THIS STAGE` as the
  last line of its job section: the section above it is truncated.
- The parse dump prints the full tree: one line per node, with a
  two-space indent per depth. A statement number opens each sentence,
  entry, and environment card line. Each clause line opens with its
  `n,cc` number. The compile card has no statement number.
- The storage section of the semantics dump prints the M3-14 fixture
  columns: octal LOC, `oct` or `bss`, the value or count, and the symbol.
- Each golden follows the mirror pattern (binding rule 1): the compiler
  writes it, a byte-for-byte test slaves it to CI, and hand edits are
  forbidden.

These text forms are renderings, not intermediate representations. M4 stays
free to add its own stages — for example `--emit-code`, `--emit-deck`, and
`--emit-loader` — under the same conventions.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 02.08]: ../../comtran-manuals/J28-6169/02-compiler.md#0208-the-7097090-machine-symbolic-language---crypt
[J 90.02]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.03]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#appendix-9003
[J 90.05]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
[J 90.08]: ../../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008
