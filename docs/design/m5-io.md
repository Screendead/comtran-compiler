# M5 — The I/O runtime design and decisions

*Drafted 2026-09-07. This document records the M5-specific design decisions
the way `m4-codegen.md` records M4's. The language facts come from
`docs/comtran-language-definition.md` (cited by §), the manuals (cited as
`(F p. N)` / `(J xx.xx.xx)`), and the locked decision slate
(`docs/design/decisions.md`, cited as D-numbers). This document adds no
language claims; where the sources leave a shape gap, the entry below closes
it and says so. Every unattested choice is labeled ours and is amendable by
an explicit edit.*

*Entry IDs are append-only. A new entry takes the next free number and goes
in the section it belongs to, and the section headings below are the index.
The code cites these IDs, so no entry is ever renumbered.*

## Charter

M5 makes the input-output verbs run. M4 emitted their calling sequences so
that the listing and the addresses reproduced (M4-15). M5 builds the IOCS
entries those sequences call.

The 1962 sample stops at its first GET today. M5 moves that stop. The
sample must read its master file and its detail file, file its records,
and reach end of job. M6 then diffs the printed report against PDF p. 217.

Input-output is emulated at the IOCS level (D0.7). A tape file is a binary
tape image. The card reader, the card punch and the printer surface as
files at the emulator boundary. No channel instruction enters the CPU. A
handler moves words between core and a host file, in the way a MOVPAK
handler moves words inside core (`runtime.md` RT-1).

## Scope and stages

- **M5-1. The milestone charters a set; the stages build what a program
  reaches.** The roadmap gives M5 the IOCS entries M4-17 left:

  - IOC)2 to 17, 29, 46, 53 and 54;
  - SYS)260 to 266, 283, and 286 to 296 less the landed 294.

  That is the charter, and it is unchanged.

  The stages below build fewer. `runtime.md` RT-1 holds the rule: each
  remaining entry lands with the code-generator shape that first emits it.
  CLAUDE.md section 11 bans a handler that no test asserts on and no run
  reaches. It permits a tested handler with no caller on a recorded plan.
  RT-1 is that plan, and this entry keeps to it.

  Our generator emits four of the chartered entries. IOC)8 is the READ
  subroutine and IOC)9 the WRITE subroutine ([J 90.02.08]). SYS)260 and
  SYS)283 stand in the two decrement fields of the GET sequence
  ([J 90.02.28]; [J 90.02.32]). The generator refuses OPEN and CLOSE of
  named files (M4-15 as amended), so IOC)6 and IOC)7 have no emitter. The
  whole-file-set forms reach the run frame's SYS)175 and SYS)177 instead.
  The rest of the charter waits for the shape that emits it.

  Three stages, one pull request each, each green alone:

  | Stage | What it delivers |
  |---|---|
  | 1 | The file model: the tape container and its tape mark, the file table from the `*FILE` and `*SPEC` cards, the attachment at `comtranc --run`, and open-all and close-all over a file list that is not empty. |
  | 2 | GET: IOC)8, the buffer, the locate-mode pointer the `IOCTN*` word names, AT END, and the two error entries the sequence names. |
  | 3 | FILE: IOC)9, the `IOST` word, blocking, and the printer file. The sample reaches end of job and prints its report. |

  The stage boundary is the file, not the verb. Stage 1 opens and closes
  every file the sample declares and reads none of them. The sample still
  stops at its first GET when stage 1 lands. The boundary test then reads
  a file list of seven where it reads empty today.

## The tape image

- **M5-2. A tape file is a SIMH `.tap` image, six bytes to the word.
  Ours.** The sample declares seven files and every one is a tape
  ([J 90.05.03]; the FILE cards at `test/fixtures/90.05-payroll.ct`:181
  to 195). No card file and no printer file exists in it, so stage 1
  builds one device.

  D0.7 makes a tape file a binary tape image and leaves the format to
  M5. The manuals give none. IOCS's own format survives, and it is
  sealed until M7 (D0.9).

  The format is therefore ours. It takes the container the public 7090
  emulators read (external: the SIMH magnetic-tape specification; the
  `I7000` simulator of the same family):

  - a record is a 4-byte little-endian length, that many data bytes
    padded to an even count, then the same length again;
  - a length of zero is a tape mark, which ends a file;
  - the value `0xFFFFFFFF`, or the end of the host file, ends the tape;
  - one 36-bit word is six bytes, most significant six bits first, and
    each byte holds its six bits in its low end.

  The frame order is ours. Stage 1 writes the container and the tape
  mark, which need no word. The encoding lands with the first record
  written and the decoding with the first record read.

  The high bits of a data byte stay zero. The `I7000` simulator carries
  a parity bit there. It would read a tape of ours with a parity error
  on every character, and it must recompute parity to take one.
  Nothing in this project reads the bit. **ponytail: parity is not
  written; compute it if a tape must feed another emulator.**

  A block is a record, and blocks vary in length. A file's BLOCKSIZE is
  not the block length on tape. DETAILFILE declares BLOCKSIZE 3 and its
  records sit "in the first portion of tape blocks 14 words long"
  ([J 90.05.03]). A reader takes the record extent from the file, not
  from the block it arrives in.

## The file table

- **M5-3. The loader's file cards become the run's file table.** Our
  loader already reads the `*FILE` and `*SPEC` cards into
  `LoadedProgram.files` (`lib/src/loader/loader.dart`; LD-3), and
  `Machine` ignores them today. Stage 1 gives each `LoaderFile` a
  control block of two fields: its host file, and whether it is open.
  The buffer and the read position arrive with IOC)8, because no word of
  stage 1 reads them (CLAUDE.md section 11).

  A file operand is its ordinal. The generator punches `04000 + k` for
  the k-th FILE card (`lib/src/codegen/control_cards.dart`), the loader
  resolves a file reference to `0x800 | number`, and the object word
  carries that address. `PZE INPUTMASTER,,SYS)260` assembles as
  `000404004001`, and `04001` is file 1
  (`test/goldens/90.05-payroll.code`:109). The table is therefore an
  index, not a name lookup.

  **IOC)1 is seeded at load. Ours.** The cell holds `PZE L,,N`: L
  locates the file list and N counts it ([J 90.02.08]). No word of the
  object deck writes it, and the manual does not say who does. Our
  machine writes `PZE 0,,N` into the cell when it loads a deck, where N
  is the number of FILE cards. The list itself stays in Dart, because no
  compiled word dereferences L: open-all and close-all pass the cell,
  and the handlers read the count. IOC)2, the cell that locates the
  12-word IOCS file blocks, has no emitter and stays unbuilt.

  A host file attaches by unit. `comtranc --run` takes a directory and
  looks in it for one image per unit, so UNIT1 `D1` reads and writes
  `D1.tap`. With no directory named, a file has no host image: it opens,
  it closes without writing, and the run behaves as it does today. With
  a directory named, a declared
  input file whose image is absent ends the run with a message. A silent
  empty tape would print a wrong report.

## Open all and close all

- **M5-4. Close-all runs twice, so a closed file closes quietly.** The
  sample compiles `CLOSE ALL FILES` and then STOP RUN, and STOP RUN
  emits its own close-all ([J 02.04.06]). Both calls stand in the object
  text (`test/goldens/90.05-payroll.code`:315 to 322). The second finds
  seven closed files and must do nothing.

  `SYS)175` opens every file the list counts and `SYS)177` closes every
  one ([J 90.02.14]). Today `SYS)177` throws on any non-zero count
  (`lib/src/runtime/monitor.dart`), so the count is the first thing that
  breaks when the table lands.

  D6.3 holds the four close codes: U unloads, R or blank rewinds, N
  does neither, and S writes no file mark. The sample punches one open
  option and one close option on all seven files, so no branch on either
  code is reachable. Stage 1 therefore reads neither code. Close writes
  one tape mark to each open output file, which three of the four codes
  ask for. The codes land with the first program that punches two. **No file
  in the sample carries a label.** Column 32 of every `*FILE` card is
  blank. [J 90.05.03] says the detail file is "a non-labeled, ungrouped,
  BCD tape file". D6.2's label handling therefore has no site
  here, and it waits for the shape that needs it.

## What stages 2 and 3 must respect

- **M5-5. The calling sequences are fixed, and the resume counts with
  them.** GET carries three parameter words and FILE carries two
  (`lib/src/codegen/procedure.dart`; M4-15). The machine's `resume` takes
  the parameter count plus one, as it does for the MOVPAK entries
  (`runtime.md` RT-3, "The off-by-one"). GET therefore resumes four words
  on, and FILE three.

  GET has four exits and the sequence names three of them:

  | Exit | Where it is | What the sample plants |
  |---|---|---|
  | normal | four words on | a `TRA` over the AT END block |
  | AT END | address of parameter 2 | the out-of-line clause (D6.6) |
  | ON ERROR | decrement of parameter 2 | SYS)283 at every site |
  | record length | decrement of parameter 1 | SYS)260 at every site |

  SYS)265 stands in the AT END field where the source gives no clause.
  Our generator refuses that shape, so no site plants it (M4-15 as
  amended). A GET on a file that is not open takes this GET's own AT END
  exit and prints nothing (D6.5).

  The `IOCTN*` word names a base locator and a record extent. The handler
  writes the address of the record into that locator, and the program
  then reads the record through it ([J 90.02.04]). That is locate mode,
  and it is why the buffer must live in core. Where the buffer lives is
  stage 2's first decision, and this record does not take it.

- **M5-6. A FILE writes a record the IOST word locates.** The word
  carries the record's address and its extent. For a record in a buffer
  the generator emits the address as zero. An `LXA`/`SXA` pair ahead of
  the call patches it (attested, statement 208; M4-15).

  The four report files are BCD tapes, listed off line. PDF p. 217 prints
  four reports, one for each: PAYFILE, CHECKFILE, ERRORFILE and
  BONDORDERFILE. One record holds one or more print lines, and a
  one-character record mark separates them (D6.4). Stage 3 needs a lister
  that renders a BCD tape as print lines, because that is the artifact
  M6 diffs.

## Open items

- **The sample's input data does not survive.** The manual prints the
  report, not the master and detail tapes that produced it. M6 must
  reconstruct both from the printed report and from the record
  descriptions. The report gives every employee's department, number,
  name, date, hours and amounts, and the ERRORFILE report gives the
  records that failed. The reconstruction is M6's work, and stage 1's
  tape writer is what makes it possible.
- **IOC)29 overlaps IOC)40.** The label area is 14 words at cell 29, so
  it covers cell 40, which is IOC)40's dispatch address. Dispatch reads
  the instruction counter and not the cell, so nothing breaks today. It
  becomes real when D6.2's label handling writes a label image.
- **Six numbers in the charter are undefined.** SYS)284, 285, 289, 290,
  293 and 295 appear nowhere in J28-6169. They cannot land until a shape
  names them.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 02.04.06]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 90.02.04]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.08]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ct-system-subroutines-and-communication-cells
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.28]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.32]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.05.03]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description-1
