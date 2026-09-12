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

The 1962 sample stopped at its first GET when M5 opened. M5 moves that
stop. The
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

  The stage boundary is the file, not the verb. Stage 1 builds open-all
  and close-all, and reads no file. The sample reaches open-all only,
  because it still stops at its first GET when stage 1 lands. The
  boundary test reads a file list of seven.

  **Amended 2026-09-12.** Stage 2 is done. The sample now reads a
  master record and a detail record, and stops at IOC)9, its first
  FILE. It needs the `--tapes` directory to run at all.

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

  **Amended 2026-09-12, M5 stage 2.** A read past the end of the tape
  takes the IOCS error exit SYS)283 (M5-8). An image that ends with no
  file mark therefore fails visibly, and the run stops.

## The file table

- **M5-3. The loader's file cards become the run's file table.** Our
  loader already reads the `*FILE` and `*SPEC` cards into
  `LoadedProgram.files` (`lib/src/loader/loader.dart`; LD-3), and
  `Machine` ignored them before stage 1. Stage 1 gives each `LoaderFile` a
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
  `D1.tap`. An empty path is a usage error, and a directory that is not
  there is an error the compiler names before it compiles. With no
  directory named, a file has no host image. It opens, it closes
  without writing, and the run behaves as it did before stage 1. With a
  directory named, a declared input file whose image is absent ends the
  run with a message. A silent empty tape would print a wrong report.

  **Amended 2026-09-12, M5 stage 2. Jack's ruling.** An input file in a
  run that named no directory is refused at open-all, before any word
  of the program runs. The paragraph above therefore holds for an
  output file only. Both alternatives mislead: an empty tape prints a
  wrong report, and a fault at the first GET arrives after the run has
  begun. The refusal names the file and asks for `--tapes=DIR`. It is
  the check open-all already makes for an absent image, with one more
  case.

  **Three file shapes have no run, and open-all refuses each one.
  Ours.** A file whose direction column is not `I`, `T` or `P` is the
  first. Our generator punches that column blank for CHECKPOINT
  ([J 02.06.03]), and no record says what a checkpoint file opens. A
  file with no unit is the second. Its image path would be the bare
  suffix, and two such files would share one image. Two files on one
  unit is the third. Open-all opens the whole list at once, so the two
  files take one image, and the second open truncates what the first
  wrote. The card gives one file two units, UNIT1 and UNIT2
  ([J 90.08.01]). No card gives one unit two files. Open-all refuses the
  second shape and the third only in a run that named a tape directory.
  Without a directory a file has no host image, and no two files
  collide.

## Open all and close all

- **M5-4. Close-all runs twice, so a closed file closes quietly.** The
  sample compiles `CLOSE ALL FILES` and then STOP RUN, and STOP RUN
  emits its own close-all ([J 02.04.06]). Both calls stand in the object
  text (`test/goldens/90.05-payroll.code`:315 to 322). The second finds
  seven closed files and must do nothing.

  `SYS)175` opens every file the list counts and `SYS)177` closes every
  one ([J 90.02.14]). Before stage 1, `SYS)177` threw on any non-zero
  count, so the count was the first thing the file table broke
  (`lib/src/runtime/monitor.dart`).

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

  **Amended 2026-09-12, M5 stage 2.** M5-7 takes that decision.

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

## The GET

- **M5-7. Each input file takes one buffer above the program. Ours.**
  The object program reserves no buffer. The storage map prints no area
  for the two input records, and the only I/O cells the compiler
  allocates are the three `BL)` words. The Loader "reserves a portion
  of core storage for use by the I/O system as operating storage"
  ([J 02.07.02]), and the execution-time core chart puts the file blocks
  below the program and the buffer pools above it ([J 03.03.01]). Our
  file table is Dart's and stands below the program (M5-3), so the
  buffer goes above.

  The loader therefore reports the program's extent: the first address
  above every word the text placed or reserved. Reservations move the
  location counter and place no word, so the extent is not the count of
  placed words. For the sample the extent is 5114, one above the
  constant pool's last word at relative 01771.

  At load, each input file takes a buffer of BLOCKSIZE words from the
  extent upward, in `*FILE` card order. The sample needs 303 words: 300
  for INPUTMASTER and 3 for DETAILFILE. BLOCKSIZE is "the maximum
  number of words which can be read from an input block" (external:
  C28-6100-2, printed p. 75). A block therefore enters the buffer
  BLOCKSIZE words deep, and the rest of the block is discarded.

  Four rules close the entry:

  - An output file takes no buffer. Nothing reads one before stage 3
    (CLAUDE.md section 11).
  - A buffer is never reassigned. It belongs to its file until the run
    ends.
  - A program whose buffers do not fit below 32768 is refused at load,
    with a message that names the file.
  - **ponytail: no pool sharing and no second buffer; add them when a
    program needs them.**

  Three placements were rejected. Below the program contradicts the
  [J 03.03.01] order. A block held in Dart, with each record copied to a
  fixed area per file, is transmit mode wearing locate mode's numbers,
  and the printed report would hide the lie. The top of core has no
  evidence. Two buffers a file, after [J 02.06.14]'s "at least 2 buffers
  to each file", is read-ahead, which a sequential emulation never
  observes.

  IOCS suspends buffering at the end of a file, and its pool may
  reassign the buffer (external: C28-6100-2, printed p. 16). The sample
  writes `HIGH.VALUE` through BL)2 after that exit, at LOC 00342 to
  00346, and the 1962 run printed a correct report. That buffer was not
  reused. Our design reproduces the result by being safer than IOCS
  was.

- **M5-8. The read rules of IOC)8. Ours.** The manuals delegate them:
  "A knowledge of the 7090 IOCS is necessary in understanding most of
  the IOC Numbers" ([J 90.02.08]). Each rule follows a sentence of the
  published IOCS manual (external: C28-6100-2), which the definition
  cites under Open Questions 45, 46 and 50.

  The entry reads three parameter words (M5-5). Word 1 names the file:
  its address field is 2048 plus the ordinal. Word 2 holds the AT END
  exit in its address field. Word 3 holds the base locator and, in its
  decrement, the record's extent in words. The rules run in this order:

  1. A GET on a file that is not open takes the AT END exit and prints
     nothing (D6.5).
  2. With no unread word in the buffer, the GET reads the next frame
     first. A record fills the buffer. A file mark takes the AT END
     exit, leaves the base locator as it was, and leaves the buffer
     spent, so that the next GET on the file reads on past the mark. A
     frame that is no record takes SYS)283.
  3. A buffer that holds fewer unread words than the extent takes
     SYS)260. The record would straddle two blocks, and "one cannot
     locate a logical record that overlaps a physical block" (external:
     C28-6100-2, printed p. 13).
  4. Otherwise the GET writes the address of the next unread word into
     the address field of the base locator, as a simple `PZE LOC`
     ([J 90.02.05]), and resumes four words on. The program does byte
     arithmetic on the whole cell, so the prefix, the tag and the
     decrement stay zero.

  Index register 4 survives every exit, so a terminator reads the same
  calling sequence. Index registers 1 and 2 and the accumulator keep
  what the program left in them. IOCS leaves a history word in the
  accumulator and no compiled word reads it.

  **A frame that is no record takes the error exit. Jack's ruling of
  2026-09-12.** Three conditions present one face to the reader, and
  all three take SYS)283: a frame whose two lengths disagree, or whose
  data the image is too short to hold; a length that is no whole number
  of words; and a read past the end of the tape, which is an image that
  ends with no file mark. The alternative was a run fault outside the
  emulation, which leaves SYS)283 unbuilt. The line between a problem
  found before the run and one found during it is the line stage 1 drew
  (M5-3).

  **Both message texts are ours.** No manual prints either one.
  [J 90.02.28] says that SYS)260 "prints an error message indicating
  processing terminated due to record length error", J 90.02.32 that
  SYS)283 "prints a message concerning the GET error", and [J 05.06.04]
  says only that a message goes to the on-line printer. Ours name the
  file and the frame:

  - `RECORD LENGTH ERROR ON INPUTMASTER, BLOCK 3`
  - `GET ERROR ON INPUTMASTER, BLOCK 3`

  The ordinal counts the frames the file has read, file marks included.
  The line therefore names the frame the reader stopped on, which is
  what a hand-made image needs.

  The words of a record stay in the buffer until the next GET on that
  file refills it. That is our answer to Open Question 54 for the
  emulation: the sample always files a master record before the next
  GET on the master file. The definition holds no design, so the answer
  lives here.

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
[J 02.06.03]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.14]: ../../comtran-manuals/J28-6169/02-compiler.md#f-group-environment-card
[J 02.07.02]: ../../comtran-manuals/J28-6169/02-compiler.md#3-the-block
[J 03.03.01]: ../../comtran-manuals/J28-6169/03-loader.md#k-ctext-and-ctend-cards
[J 05.06.04]: ../../comtran-manuals/J28-6169/05-systems-operation.md#b-loader-1
[J 90.02.04]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.05]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.08]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ct-system-subroutines-and-communication-cells
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.28]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.32]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.05.03]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description-1
[J 90.08.01]: ../../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008
