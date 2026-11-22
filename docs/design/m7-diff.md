# M7 — the diff pass

*Opened 2026-11-21. Audience: the agent who runs M7, and Jack. This record
holds the M7 decisions. D0.9 in `decisions.md` holds the seal and its
reasons.*

M7 compares two things:

- **The reconstruction.** This repository as it stood when the seal ended.
  It comes from the two manuals alone.
- **The archive.** The 1963 Commercial Translator in the recovered IBSYS
  archive. D0.9 describes it.

Each difference is one of two findings: a real change between January 1962
and July 1963, or an error in our recovery. Each agreement is evidence that
the method works.

## M7-1 The reconstruction of record

**Decision.** The reconstruction of record is master at commit `a465077`.
That commit merged W4 (PR #214) on 2026-11-21. W3 merged before it, so
Jack's condition for M7 was met at that commit. Every M7 finding compares
the archive against that commit, not against a later master.

**Why one course only.** The seal exists for one reason: a measurement of
the blind reconstruction (D0.9, "Rationale"). After the seal ends, a fix
can enter master that the archive caused. A comparison against a later
master then measures a mix of blind and informed work. A fixed commit is
the only baseline that keeps the measurement. Git keeps every file of it,
so the record names the commit and copies nothing.

**What the commit holds.** 1556 Dart tests pass at it on Dart 3.12.2. Its
goldens are the files in `test/goldens/` at that commit.

**The rules that follow.**

1. Do not rewrite a record that existed at `a465077` to match the archive.
   Append an amendment, and label it "post-seal (M7)". The old text is half
   of the measurement.
2. Each change to `lib/` that an M7 finding causes cites that finding in its
   commit message and in the design record it amends.
3. A change to master after `a465077` that no M7 finding causes is still
   blind work. Its pull request says so.

## M7-2 The contaminated items

D0.9 lists what the survey of 2026-09-06 read before the seal existed. Two
results are not blind:

- **MOVPAK.** The survey read 28 lines of its logic.
- **Open Question 31.** The survey counted the uses of `SYS)131`, which
  bears on whether anything reads that cell.

Report both as contaminated in every M7 summary. Do not count them as
agreements or as differences of the blind reconstruction.

## M7-3 The archive

**Identity.** The review record `review/2026-09-06-emulator-reuse` holds the
download address. Its tarball held 9,829,802 bytes on 2026-09-06. Its `CT/`
directory holds four files: the FAP source, the assembly listing, the object
file, and a makefile.

**Decision.** The repository holds no copy of the archive. The review record
does not redistribute it, and this record follows that course. The first
fetch for M7 records the byte count and the SHA-256 of the tarball here. A
later fetch that gives a different checksum stops the work until the cause
is known.

**Status, 2026-11-21.** The cloud sessions cannot fetch the archive. Their
network refuses the host. Jack has a call for this: the cloud network can
allow the host, or the work can move to the Mac.

**Status, 2026-11-21, later.** Jack allowed the host for the cloud
(issue #216). The first M7 fetch gave these values:

| File | Bytes | SHA-256 |
|---|---|---|
| the tarball | 9,829,802 | `7442d355e0077cee6f40dc2937d22bd400d65840de7ef33564d1e90dd163bfb0` |
| `CT/ct.job` | 5,398,204 | `ec41c0a19dc09a6c2b181218761f696c9ccab25c352fcd0ce845804c1039be6b` |
| `CT/ct.lst` | 7,747,434 | `dcdadfa3d02f5dee30cbe860f7c05724b1a7c84c853502dba810039d81ff16dc` |
| `CT/ct.obj` | 927,369 | `0ba4531b4ca93e954741717281b4274aca375e54b540d9bdac30afae848113b8` |
| `CT/Makefile` | 205 | `6418076d24fe33fa7865425b3db56892231bf8bcece881a7c5df9ad97486300b` |

The tarball byte count agrees with the count of 2026-09-06. The `CT/`
directory holds the four files of the review record. Each later fetch
compares against this table.

## M7-4 The plan

The roadmap gives the method: assemble the 1963 processor, and diff our
reconstruction against it. The order:

1. **Fetch and verify** the archive (M7-3).
2. **Run the 1963 processor** on the 90.05 job and on the 1960 payroll deck.
   Our emulator runs only the instructions that generated code uses, and
   no IBSYS, so it cannot run the processor. A 7090 simulator that runs
   IBSYS jobs does that work. It is a measuring tool for M7 only, and the
   compiler does not ship it. The choice of simulator waits until the
   archive is in hand.
3. **Diff the outputs**: the listing, the object deck, and the printed
   report, against the outputs of `a465077`.
4. **Diff the runtime library** deck by deck against the handler contracts
   of `runtime.md`.
5. **Classify each difference** as a 1962-to-1963 change or a recovery
   error. Give the evidence for each class.

Each step gets its own entry in this record when it starts.

## M7-5 The simulator

**Decision.** Run the 1963 processor on `s709` 2.4.4, the 709/7090/7094
simulator of Dave Pitts (external: cozx.com, 2026-11-21). Build the
system tape with his `asm7090` 2.3.2, `lnk7090` 2.2.3 and `utils`
1.1.15 from the same host.

**Why this course.**

- The archive comes from the same author. Its `CT/Makefile` assembles
  `ct.job` with his `asm7090`.
- The `s709` kit holds IBSYS system tapes (`ASYS1.BIN`, `ASYS8.BIN`)
  and scripts that run IBSYS jobs (`runibsys`). The processor is an
  IBSYS subsystem: `ct.job` is an IBSYS job that assembles the
  "709/7090 COMMERCIAL TRANSLATOR MONITOR (VERSION 5) 07/15/63"
  under IBSFAP.
- The cloud network reaches the host, so a later fetch can repeat
  every input.

**The rejected course.** The Open SIMH `i7090` simulator also runs IBSYS.
The survey of 2026-09-06 preferred it for an instruction-level test
of our emulator, not for an IBSYS job. Its system tapes come from a
second source, and the cloud network refuses that host. It stays the
fallback if `s709` cannot run the processor.

**Where it runs.** The Mac runs every step. A cloud session must not
build or run code that it downloads, so the cloud fetches and reads
only. The simulator, its tapes and its outputs stay out of this
repository, as M7-3 requires for the archive. The Mac reports each
step in a needs-mac issue.

**The steps.**

1. Build the four tools. Check the tarball against the M7-3 table.
2. Boot IBSYS from `ASYS1.BIN` and run one sample job of the kit.
3. Assemble `CT/ct.job` with `asm7090`, and compare the object file and
   the listing against `CT/ct.obj` and `CT/ct.lst`.
4. Put the processor on a system tape, and run the 90.05 job and the
   1960 payroll deck under it.

Steps 1 to 3 have a known end. Step 4 needs a method that this record
does not hold yet. Its entry follows when step 3 is done.

**The result of steps 1 to 3 (2026-11-21, issue #219).** The Mac ran
the steps in a live session with Jack, outside the repository.

| Step | Result |
|---|---|
| Fetch | The `ibsys.tar.gz` checksum matches M7-3. |
| 1. Build | `make` builds `s709`, `asm7090`, `lnk7090` and `utils` with no error. |
| 2. Boot | `runibsys primes.job` runs the kit's FORTRAN sample to `END OF JOBS`. |
| 3. Assemble | `asm7090` reports 405 errors, all in file 9. The other ten assemblies have none. |

The errors in file 9 are not a defect of the tool. `ct.job` is an
IBSYS job of six steps, not one FAP program:

| Step | Control card | Content |
|---|---|---|
| X1 | `$EXECUTE IBSFAP` | the CT monitor, version 5, 07/15/63 |
| X2 | `$EXECUTE IBSFAP` | the CT IOCS |
| X3 | `$EXECUTE IBSFAP` | a third FAP part |
| X4 | `$EXECUTE CT` | 40 `$CMPLE` decks: the runtime library, in COMTRAN and CRYPT source |
| X5 | `$EXECUTE IBSFAP` | a last FAP part |
| X6 | `$STOP` | end of job |

`asm7090` reads X4 as FAP, so it rejects it. The archive's own
`ct.lst` shows 357 errors in the same file. Thus `asm7090` alone
cannot build the runtime library. The processor must compile the 40
decks of X4 under IBSYS.

The Mac decoded both object decks to memory images, one image for
each of the 14 segments, and compared them word by word:

- Ten segments are identical. Segments 3 to 5 add one empty record
  only.
- Segment 2, the CT IOCS, differs in three address fields of 3,597
  words. The source gives `**` for each, and the program fills them
  at run time. Version 2.3.2 assembles 1200 and version 2.2.1
  assembles 1220.
- Segment 12 comes from X4, so neither deck holds meaningful words
  there.

The listings differ in headers, column layout and mode line. The
2.3.2 listing says 7094 mode, but the object words do not change.

`ASYS1.BIN` holds no Commercial Translator. A probe job with
`$EXECUTE CT` gets `CT     UNKNOWN SYSTEM`. The kit has no job that
adds a new subsystem to a system tape. Its editor jobs change the
IBJOB libraries only. The System Editor control cards for a new
subsystem are in the archive's `EDITOR/editor.map`.

**Step 4, in two parts.**

1. Make a system tape that holds CT. Run steps X1 to X3 of `ct.job`
   under IBSYS to punch the object deck. Then run a System Editor job
   that adds it to the tape.
2. Run step X4 on the new tape, so the processor compiles its own
   runtime library.

The method for part 1 comes from `EDITOR/editor.map`. The next
entry holds it.

## M7-6 The CT system tape

*Read 2026-11-21 from `EDITOR/editor.map` and `CT/ct.job`. A second
fetch gave the checksum of the M7-3 table.*

**What the monitor needs on the tape.** The CT monitor (`ct.job`
lines CT000820 to CT001620) describes its own part of the system
tape. IBSYS positions the tape at the first file of CT. The monitor
then finds each record by a file and record displacement from that
point:

| File | Records | Content |
|---|---|---|
| 0 | `CT` | the CT monitor |
| 1 | `BASIC` | the basic IOCS |
| 2 | `CTB`, `CTC`, `CTI`, `CTD`, `CTE` | the compiler |
| 3 | `IOCS` | the label IOCS |
| 4 | `LOAD` | the loader |
| 5 | `SRDICT` and more | the subroutine dictionary |
| 6 | `CTSUBT` and more | the subroutine text |
| 7 | `IOBB`, `IOBM`, `NOBS` | the three IOCS overlays |
| 8 | `SUBUP` | the subroutine updater |
| 9 | `MAIN` | the file maintenance program |

Each file ends with a file mark. CT thus takes ten files.

**Where each record comes from.** `ct.job` punches its assemblies
to `SYSPP1` as column-binary card images. Each assembly ends with a
transfer card.

| Step | Assemblies, in order | Records for file |
|---|---|---|
| X1 | the monitor | 0 |
| X2 | the IOCS, version C | 3 and 7 |
| X3 | `CTB`, `CTC`, `CTI`, `CTD`, `CTE`, `LOAD` | 2 and 4 |
| X4 | the 40 library decks, compiled by CT | 5 and 6 |
| X5 | the dictionary locator `SRDLOC`, `SUBUP`, `MAIN` | 5, 8 and 9 |

Two facts need care:

- X2 does not give the `BASIC` record as it stands. Cards IO000140
  to IO000180 say how to make it: delete cards IO001150 to
  IO001160, card IO046000, and cards IO046310 to IO047490, then
  assemble the IOCS a second time.
- X2 splits its output with `TCD -1` cards. The record before the
  first split is the label IOCS. The three after it are `IOBB`,
  `IOBM` and `NOBS`.

**The System Editor.** IBSYS calls the editor with `$IBEDT`. The
editor reads the old system tape on `SYSLB1` and writes a new one on
`SYSUT1`. Its control cards have `*` in column 7, the operation in
columns 8 to 14, and the operand from column 16. Part 1 uses four:

| Card | Effect |
|---|---|
| `*EDIT  MAP` | starts the edit and prints a map of the new tape |
| `*PLACE CT,10,1,n` | adds CT to the IBSYS name table: 10 files, on `SYSLB1`, in order `n` |
| `*AFTER name` | copies the old tape up to and through the named record |
| `*INSERT` | reads binary cards to a transfer card, and writes one record |

`*INSERT FILEMK` writes a file mark. `TAPE` in columns 1 to 6 of an
`*INSERT` card makes the editor read the binary cards from `SYSUT2`.
The punch tape of `ct.job` can thus feed the editor directly. Each
`*PLACE` card must come before the editor copies the IBSYS nucleus,
because the name table is in that record. The control cards must
follow the order of the records on the tape.

**The method for part 1.**

1. Run steps X1, X2, X3 and X5 of `ct.job` under IBSYS, with
   `SYSPP1` on a scratch tape. Run X2 a second time with the
   `BASIC` deletions.
2. Write a modification deck that keeps the old tape to its last
   system, then inserts the ten files of the table above. Put the
   `*PLACE` card first. Give file 6 no record: a file mark only.
3. Run the deck under `$IBEDT`, with `ASYS1.BIN` on `SYSLB1` and the
   new tape on `SYSUT1`.
4. Boot the new tape, and run a job with `$EXECUTE CT`. A pass
   prints the CT sign-on, not `UNKNOWN SYSTEM`.

**The risks.**

- Files 5 and 6 hold no library before part 2 runs. Part 2 then
  compiles the library on a CT that has none. If CT refuses that,
  part 2 needs a seed library. The archive holds none in binary.
- The monitor fixes the IBSYS origin at 64, the IOEX origin at 450
  and the IOCS origin at 2480 (lines CT000080 to CT000110). The
  IBSYS of the kit may differ. If CT stops at its start, compare the
  nucleus of `ASYS1.BIN` against these origins first.
- The record names of X2 need a check in the editor map. Its
  assembly stores `BASIC`, then `IOCT`, into the name cell
  (IO001130 to IO001160).

**The result of part 1 (2026-11-21, issue #222).** The Mac ran the
method in a live session with Jack. The kit and the tapes are outside
the repository, in the tools folder beside it. `tool/m7/ct_tape.sh`
builds the tape again in about 15 seconds.

| Step | Result |
|---|---|
| 1. Punch | X1, X2, X3 and X5 punch with IBSFAP, one job for each step. |
| 2. Order | `tool/m7/punch_split.dart` writes the programs to `SYSUT2` in file order. |
| 3. Edit | The editor writes the ten CT files as files 15 to 24 of the new tape. |
| 4. Boot | `$EXECUTE CT` gives no `UNKNOWN SYSTEM`. CT compiles a library deck. |

The name table of the new tape holds `CT 10 1 15`: ten files, on
`SYSLB1`, from file 15. The editor map shows these record names:

| CT file | Records |
|---|---|
| 0 | `CT` (669 words) |
| 1 | `BASIC` (3674) |
| 2 | `CTB`, `CTC`, `CTI`, `CTD`, `CTE` |
| 3 | `BASIC` (3647) |
| 4 | `LOAD` |
| 5, 6 | file marks only |
| 7 | `IOBB`, `IOBM`, `NOBS` |
| 8 | `SUBUP` |
| 9 | `MAIN` |

The editor names a record by the first word that it reads. The label
IOCS of file 3 thus shows `BASIC`, not `IOCS`. The `IOCT` word comes
later in the deck. The monitor finds each record by its position, so
the name does not stop CT.

A job with `$EXECUTE CT` and `$STOP` returns to IBSYS with no output.
The monitor prints no sign-on: `$STOP` is one of its own control cards
(CT002070). A second probe gave CT the first deck of X4, `IOBSMP`. CT
listed it under the header `CT0500 07/15/63` and version `CT0506`,
printed `NO ERRORS WERE DETECTED DURING COMPILATION`, and punched five
loader cards. Thus CT loads its compiler and IOCS records from the new
tape. The origin check of the risks above is not necessary.

Three facts differ from the method:

- One job for all the steps stops in X5. Each step now runs as its
  own job.
- In X5, IBSFAP punches the 12-word `SRDLOC` assembly (SDL00010 to
  SDL00360) and then never returns to IBSYS. File 5 thus has no
  `SRDLOC` record. The editor refuses its octal card form after
  `*INSERT`. Part 2 must supply `SRDLOC` before CT reads file 5.
- `s709` stops with a trap when a file name is long. The scripts link
  each tape into the work folder.

Part 2 runs X4 on this tape. It needs `SRDLOC` in file 5 first.

**Amendment, 2026-11-21: what file 5 needs.** Part 2 needs `SRDLOC`
and a dictionary in file 5 before SUBUP or LOAD can run. M7-7 holds the
evidence and the method.

## M7-7 The CT subroutine library

*Read 2026-11-21 from `CT/ct.job`, `CT/ct.lst` and `EDITOR/editor.map`.
A fetch gave the checksum of the M7-3 table. The cited cards are
sequence numbers in columns 73 to 80.*

**What reads files 5 and 6.** The compiler does not read them. The
`SUB` option of `$CMPLE` (CB031850) only sets the switch `CTSUBX`. The
switch skips the `STOP RUN` test (CD008340) and the storage and constant
pool of a main program (CE047490). Two programs read the library:

| Program | Call | Effect |
|---|---|---|
| `SUBUP` | SU004770 to SU004800 | positions to file 5 and reads it |
| `LOAD` | LD059980 to LD060010 | positions to file 5 and reads it |

Both calls use the `CTSUBD` action with prefix `PZE`, "PERFORM ACTION
(INCL. POSITIONING)" (CT003730). The action reads the record at
`TP070`, record 0 of file 5, with the system loader (CT004510).

**Why file 5 starts with `SRDLOC`.** The system loader can only read a
loader record, so record 0 of file 5 must be one. That record is
`SRDLOC` (SDL00010 to SDL00360):

- The monitor keeps room for it: `BSS 26  SPACE FOR RECORD BEFORE
  SRDICT` (CT000800). `SRDLOC` assembles at that place, CT+21.
- It takes control from the loader (`ORG SYSTRA` / `TTR START`,
  SDL00220 to SDL00230).
- On tape it returns at once (SDL00250 to SDL00260). On disk it also
  sets the seek address.
- The caller sets the return point first: `FILL RETURN POINT INTO
  SYSSUT` (SU004770, LD059980).

Thus the 1963 tape held `SRDLOC`, then the dictionary records, in
file 5. The tape diagram of the monitor (CT001130 to CT001140) does not
show `SRDLOC`, but the code needs it.

**What SUBUP needs.** SUBUP makes a new library from the old library
and a modification deck. It has no path that starts a library from
nothing:

- It reads the first dictionary record before it does any change
  (SU006540 to SU006570).
- An end of file there prints `EOF IN READING SBR RECORD` and stops
  SUBUP (SU006600 to SU006620).
- After the dictionary it reads file 6, and it requires a file mark at
  the end (SU021490 to SU021530).

Thus the first run needs a seed: an empty dictionary. It is one record
of four words, as SUBUP itself writes it for no subroutines (SU030840
to SU030990):

| Word | Octal | Meaning |
|---|---|---|
| 0 | `300000200000` | `IORTN 0`, the last block of the dictionary |
| 1 | `625124312363` | `BCI 1,SRDICT` |
| 2 | `000000000000` | no system references |
| 3 | `000000000000` | no subroutines |

File 6 of the seed tape is a file mark only.

**What SUBUP writes.** SUBUP writes the new library to `SYSUT2` as two
files: the dictionary, then the subroutine text (SU030880 to SU031330).
Each record has two control words, then data. The control words are
not loader words, so the System Editor cannot copy the records with
`*INSERT`. The archive has no statement of how IBM moved the two files
to the system tape. The editor of the archive has a `*DUP` card
(ED002330 to ED002410) that can copy such records, but the editor on
`ASYS1.BIN` may not have it. Thus this record writes the tape image
directly.

**The modification deck.** The first X4 deck, `IOBSMP`, holds a table of
the 40 library routines in comment cards 00300110 to 00300890. It
gives each routine its number, name, type, fixed origin and source
file. The deck for SUBUP follows the table:

```
$SUBUP         MAP,40
TAPE  *INSERT  SR(IOEXMP),702
TAPE  *INSERT  SR(IBMAP),100
TAPE  *INSERT  SR(CTMCOM),3720
TAPE  *INSERT  SR(IOBSMP),4660
TAPE  *INSERT  SR(UNITAS),PRIMARY
TAPE  *INSERT  SR(INREAD),PRIMARY
TAPE  *INSERT  SR(PRGINT),PRIMARY
TAPE  *INSERT  SR(2CELLS)
...
```

These rules apply:

- `TAPE` in columns 1 to 4 makes SUBUP read the deck from `SYSUT4`
  (SU006180 to SU006200). Each `*INSERT` card needs it, because SUBUP
  turns it off after each deck (SU022670).
- A fixed routine gives its octal origin, a primary routine gives
  `PRIMARY`, and a secondary routine gives no type (SU020790 to
  SU021040). SUBUP refuses the word `SECONDARY`, although its own
  comment card SU001150 allows it.
- SUBUP reads `SYSUT4` in sequence. X4 compiles the decks in the order
  of their source files, which is not the order of the table. Thus the
  X4 job of this method compiles them in table order.
- The deck ends with an end of file (SU000300). `MAP,40` prints the
  dictionary and checks that SUBUP read 40 cards after the `$SUBUP` card.

**The method for part 2.** `tool/m7/ct_library.sh` runs it from the
`CTSYS1.BIN` of M7-6. `tool/m7/ct_lib.dart` writes files 5 and 6 of
the tape image.

1. Seed: write `SRDLOC` and the empty dictionary into file 5, and make
   file 6 empty.
2. Run X4 on the seed tape, with the 40 decks in table order. The
   punch tape holds 40 relative decks, each from `*CTEXT` to `*CTEND`.
3. Run `$SUBUP MAP,40` on the seed tape, with the punch tape on
   `SYSUT4`. SUBUP writes the library to `SYSUT2`.
4. Splice: write `SRDLOC` and the new dictionary into file 5, and the
   text into file 6. The result is `CTSYS2.BIN`.
5. Run `$SUBUP MAP` on `CTSYS2.BIN` with no changes. It prints the
   dictionary of the new tape.

**What a pass shows.**

- The X4 listing shows 40 compilations, each with `NO ERRORS WERE
  DETECTED DURING COMPILATION`.
- The map of step 5 shows 40 routines with the numbers, types and fixed
  origins of the table.
- The four fixed origins are the system origins: octal 702 is IOEX at
  450, 100 is IBSYS at 64, 3720 is the monitor at 2000, and 4660 is the
  IOCS at 2480 (CT000080 to CT000110).

**The risks.**

- The comment table gives `IOBSMP` a length of octal 7520. Its `BSS`
  cards give 7517. The map shows the compiled length.
- `SYSSUT` must hold the return point when the system loader runs
  `SRDLOC`. If the loader of `ASYS1.BIN` differs from the loader of the
  archive, the read of file 5 can stop. The step 3 listing then shows
  where.
- LOAD reads the text file forward only (LD036290). The table order is
  the order of the subroutine numbers, so LOAD can find each routine in
  turn.

**The result of the X4 step (2026-11-21, issues #226 and #227).** The
Mac ran step 2 of the method on `CTSYS1.BIN`. The step is not a pass.

| Count | Pass value | Result |
|---|---|---|
| `$CMPLE` cards in the job | 40 | 40 |
| `NO ERRORS WERE DETECTED DURING COMPILATION` | 40 | 37 |
| `THE LAST LOADER CONTROL CARD PUNCHED IS` | 40 | 39 |

Three compiles print `ILLEGAL INTERNAL CONDITION. NOTHING DONE.
POSSIBLE COMPILER ERROR.`:

| Deck | Statement | Severity | Card of the statement | Deck punched |
|---|---|---|---|---|
| `EXPERR` | 32 (two messages) | 4 | 15700410 `BCI 4,ERROR IN EXPONENTIAL AT` | yes |
| `BCDERR` | 24 | 4 | 26300300 `BCI 3,NUMERIC CHARACTER` | yes |
| `SYSCOL` | 68 | 5 | 16100730 `ENTER COMMERCIAL TRANSLATOR` | no |

Statement 1 of each deck is its `ENTER CRYPT.` card, and each later
card that is not a comment is one statement. The probe of issue #227
ran three more jobs. Each gave the same three faults:

| Run | Change |
|---|---|
| A | the three decks alone |
| B | all 40 decks, on the 7090 model of `s709` |
| C | the three decks alone, on the 7090 model |

Thus the faults do not come from the decks before them, and they do not
come from the 7094 mode of the simulator. `SYSCOL` stops the compile,
so the library has no `SYS)161`. Step 3, SUBUP, waits until the three
compiles are clean (issue #228, closed unrun).

**What the source shows.** Five message numbers print this text: 18,
24, 29 and 124 of the assembler phase (CE017640 to CE018700), and 182
of the compiler phase (`KMS006`, CC004120 to CC004140). The listing
does not print the number, so the source does not yet show which
check fails. The compiler phase copies the text of a `BCI` card into
the internal text as one control word and the card words (CC027880 to
CC028140). M7-5 found that the compiler words of our assembly equal the
words of `CT/ct.obj`. Thus the compiler is the 1963 compiler, and the
cause is one of these:

- the simulator runs an instruction of the compiler wrongly;
- the system of `ASYS1.BIN` differs from the system of 1963;
- the 1963 compiler gave the same faults on these decks.

Two of the three faults are on `BCI` cards, and other `BCI` cards of
the library compile clean. For example, `BCI 4,EXPONENTIAL OVERFLOW AT`
of `EXPERR` compiles clean two cards before the fault.

**The punch tape.** Each record of the punch tape holds 168
characters, 28 words. The first 24 words are a column-binary card. The
form of the last four words is not known yet. `punch_split.dart` takes
a card only at 162 characters, so it finds no program on this tape.
SUBUP reads the tape itself, so the method does not need the tool.

**The probe of the faults.** `tool/m7/ct_probe.sh` compiles 15 decks
in one job on `CTSYS1.BIN`. Each deck is one of the three, renamed, with
one change:

| Deck | Change | A clean compile shows |
|---|---|---|
| `E0`, `B0`, `S0` | none | the probe repeats the fault |
| `E1` | 15700410 gets the text `EXPONENTIAL OVERFLOW AT` | the text of the card causes the fault |
| `E2` | no card 15700410 | the fault is on this card |
| `E3` | no cards 15700420 and 15700430, the two `OCT` cards | the fault is on the cards after it |
| `E4` | `ERROR` becomes `XXXXX` | the word `ERROR` causes the fault |
| `E5` | `IN` becomes `XX` | the word `IN` causes the fault |
| `B1` | 26300300 gets the text `NUMBER OF BUFFERS` | the text of the card causes the fault |
| `B2` | no card 26300300 | the fault is on this card |
| `B3` | no card 26300320, the `BCI` of 18 periods | the fault is on that card |
| `B4` | `NUMERIC` becomes `XXXXXXX` | the word `NUMERIC` causes the fault |
| `B5` | `CHARACTER` becomes `XXXXXXXXX` | the word `CHARACTER` causes the fault |
| `S1` | no cards 16100410 to 16100720, the second half of the table | the fault is in the second half |
| `S2` | no cards 16100090 to 16100400, the first half of the table | the fault is in the first half |

Each change keeps the length of the text, so the columns of each card
do not move. The result tells which part of the compiler to read next.

**The result of the probe (2026-11-21, issue #230).** The Mac ran
`tool/m7/ct_probe.sh` on master at `175849e`. The run ended at
`END OF JOBS` and printed all 15 lines:

| Deck | Result | Messages (statement, severity) | Deck punched |
|---|---|---|---|
| `E0` | not clean | 32, 4, twice | yes |
| `E1` | clean | none | yes |
| `E2` | clean | none | yes |
| `E3` | not clean | 20 and 21, 4, `'OMAX' IS AN UNDEFINED SYMBOL.`; 32, 4, twice | yes |
| `E4` | not clean | 32, 4, twice | yes |
| `E5` | not clean | 32, 4, once | yes |
| `B0` | not clean | 24, 4, once | yes |
| `B1` | clean | none | yes |
| `B2` | clean | none | yes |
| `B3` | not clean | 17, 4, `'L3A' IS AN UNDEFINED SYMBOL.`; 24, 4, once | yes |
| `B4` | not clean | 24, 4, once | yes |
| `B5` | clean | none | yes |
| `S0` | discontinued | 68, 5, once | no |
| `S1` | clean | none | yes |
| `S2` | clean | none | yes |

Each message without a text in the table is `ILLEGAL INTERNAL CONDITION.
NOTHING DONE. POSSIBLE COMPILER ERROR.` The undefined symbols of `E3`
and `B3` are the labels that the probe removed.

These facts follow:

- The fault is on the card, and the text of the card causes it (`E1`,
  `E2`, `B1`, `B2`). The cards after it do not cause it (`E3`, `B3`).
- No single word causes it. `ERROR` (`E4`) and `NUMERIC` (`B4`) are not
  the cause. `IN` takes away one of the two messages of `EXPERR` (`E5`).
  `CHARACTER` takes away the message of `BCDERR` (`B5`).
- The fault of `SYSCOL` is in its table. Each half alone compiles clean
  (`S1`, `S2`).

**No `BCI` card gave words.** The object listing of `E0` gives these
locations:

```
      00030  4 00004 0 00031   10001    OVW            MZE    *+1,,4
      00031  4 00004 0 00032   10001    NGW            MZE    *+1,,4
      00032  377777777777      10000    OMAX           OCT    377777777777
```

`OVW`, `NGW` and `OMAX` are in sequence. Thus `BCI 4,EXPONENTIAL OVERFLOW
AT` (statement 30) took no location, and it drew no message. The same is
true of statement 32. A 1963 library routine that printed a message with
no text is not credible. Thus the fault is not three faults on three
cards. Each `BCI` card loses its text, and the lost text causes a
message only for some contents.

**What the source shows.** The `BCI` card passes through three phases:

1. The scanner of the compiler phase (CC027880 to CC028140, and the
   patch at CC10163M) enters a control word with the code 74, "BCD
   INFORMATION FOLLOWS". It puts the word count of the card in the
   decrement of that word, and six times the count in the address. It
   then copies the card words into the internal text without a scan. A
   card with no comma gets one word of blanks at its period instead
   (CC035230 to CC035310).
2. The next phase (CD010620 to CD010740) finds the code 74. It takes the
   character count from the address of the control word, and it copies
   that number of words, six characters each, with no other test.
3. The assembler phase (CE) assigns the locations.

The copy is the only thing that keeps the text words out of the scan of
the internal text. If the count in the control word is zero or lost, the
phases read the text words as internal text. Most of the words then
give nothing, so the card gets no location and no message. Some words
look like a control code, and the assembler phase prints `ILLEGAL
INTERNAL CONDITION`. This explains all four facts above. It is a
hypothesis: the source shows the path, but not which step fails.

**The next probe: the internal text.** The `COLAG` option of `$CMPLE`
(CB024540) prints every internal text buffer. `tool/m7/ct_probe.sh KIT
colag` compiles five decks with it: `E0`, `E1`, `B0`, `B5`, and `K0`,
an unchanged copy of `KAPUT`. `KAPUT` compiled clean in X4 and holds
nine `BCI 1` cards. The print shows these things:

- whether the control word with the code 74 is in the buffer, and the
  count it holds. For `BCI 4` the scanner makes the word
  `740004000030`, if the constant `SYX` holds 6 (this record derives the
  value from CD010630; the listing does not print it);
- whether the card words follow it. In octal, statement 30 of `E0`
  holds `256747464525`, `456331214360`, `466525512643` and
  `466660216360`, and statement 32 holds `255151465160`,
  `314560256747`, `464525456331` and `214360216360`;
- whether `KAPUT` gives locations for its `BCI` cards. If it does not,
  the whole library compiled in X4 has lost its message texts.

If the control word holds the right count, the next phase loses the
text, and the next probe dumps that phase with the `CHECK` option and
its dump cards (CB032530 to CB032620). If the count is wrong, the fault
is in the scanner, and the probe moves to the 18-bit constant switch
(CC027900) that reads the count.

**The result of the COLAG probe (2026-11-21, issue #232).** The Mac
ran `tool/m7/ct_probe.sh KIT colag` on master at `53cf6bc`. All five
compiles ran, with the results of the probe of issue #230: `E0` and
`B0` are not clean, and `E1`, `B5` and `K0` are clean. `colag.lst`
holds 773 lines.

The print shows these facts:

- No text word of `E0` statement 30 or 32 is in the print.
- No word is `740004000030`. Each `74` word of `E0` is `740000000000`,
  and no text word follows it.
- In `K0`, each `BCI 1` card with a label gives `740001000001` and its
  word. Each `BCI 1` card without a label gives `740000000000` and no
  word.
- The object listing of `K0` agrees. The six cards with a label take
  locations 00041 to 00045 and 00061. The three cards without a label
  (statements 43, 45 and 47) take no location.
- Each card that loses its text has no label: statements 30 and 32 of
  `EXPERR`, statement 24 of `BCDERR`, and the three cards of `KAPUT`.
  Each `BCI` card with a label keeps its text.

**What the print is.** The `COLAG` file is the input of the first pass
of the assembler phase (CB004860). Thus the print shows the internal
text after the phase of CD010620, not the output of the scanner.

**What the source shows.** The comma of a `BCI` card goes to the patch
at CC10163M (CC025060 to CC025070). The patch decides if a word count
came before the comma:

1. The comma backs the link pointer, index register 4, one word
   (CC025070). The pointer then addresses the count.
2. `TXL WBCIA,4,-2` (CC10163M) tests the pointer against a fixed
   value. If the pointer is at 77776 or lower, the scanner takes the
   count (`WBCIA`).
3. If not, the scanner takes the card as a `BCI` with no count
   (CC10163N to CC10163P). It goes to `WBCIA+4` and stores the count
   one word later than the control word.

The pointer is zero at the start of each sentence (CC035480, "IF NDX4
= 0 IGNORE TEXT"). Each text word lowers it by one. Thus the test
counts the words of the sentence:

| Card | Words before the comma | Pointer at the test | Path |
|---|---|---|---|
| label, count | label, control word, count | 77776 | count |
| no label, count | control word, count | 77777 | no count |
| label, no count | label, control word | 77777 | no count |
| no label, no count | control word | 00000 | count |

The test is right only for a card with a label. A card with no label
and a count takes the path with no count. That path leaves the control
word at `740000000000`, and the next phase copies no words. The text
words then pass as internal text. This matches each fact of the print,
and the probe of issue #230. The words that give `ILLEGAL INTERNAL
CONDITION` are the ones that look like a control code.

The compiler words of our assembly equal the words of `CT/ct.obj`
(M7-5). The path uses only `TXI` and `TXL`, and the probes of issue
#227 ran on the 7090 model too. Thus the simulator is not a likely
cause. The patch is of modification level 5. Its fault reaches every
`BCI` card with no label, so the 1963 library was probably compiled by
an earlier level. This is a hypothesis.

`SYSCOL` holds no `BCI` card. Its fault is in its table of 64 words,
and this reading does not explain it.

**The next probe: labels.** `tool/m7/ct_probe.sh KIT label` compiles
three decks with `COLAG`. Each deck gives a label to the `BCI` cards
that have none:

| Deck | Cards that get a label |
|---|---|
| `E6` (`EXPERR`) | 15700390 `XLB30`, 15700410 `XLB32` |
| `B6` (`BCDERR`) | 26300300 `XLB24` |
| `K1` (`KAPUT`) | 26600520 `XLB43`, 26600540 `XLB45`, 26600560 `XLB47` |

A pass shows these things:

- `E6` and `B6` compile clean.
- The print holds `740004000030` and the four text words of each of
  `E6` statements 30 and 32.
- The object listing of `K1` gives a location and a word to each of
  its nine `BCI 1` cards.

If the probe passes, the hypothesis holds. The library then needs one
of two changes before SUBUP can run: a label on each `BCI` card with
no label, or a correction of the patch. Each changes 1963 material, so
the choice goes to Jack.

**The result of the label probe (2026-11-21, issue #234).** The Mac
ran `tool/m7/ct_probe.sh KIT label` on master at `4ad10a1`. All three
compiles ran, and each printed `NO ERRORS WERE DETECTED DURING
COMPILATION`. No deck drew a message. `label.lst` holds 509 lines.

The print shows these facts:

- Each of the eight text words of `E6` statements 30 and 32 is in the
  print, once in the object listing and once in the buffer print.
- Each control word with the code 74 now holds a count, and that number
  of text words follows it. The words are `740004000004` (`E6`),
  `740011000011` and `740003000003` (`B6`), `740010000010` (`B6`), and
  `740001000001` (`K1`).
- The object listing gives each `BCI` card a location in sequence. In
  `E6`, `OVW` is at 00030, its text at 00031 to 00034, `NGW` at 00035,
  its text at 00036 to 00041, and `OMAX` at 00042. In `B6`, `L1` to
  `L3A` take 00021 to 00045 with no gap. In `K1`, `C06HED` to `C06IR1`
  take 00041 to 00050, one word each.

Thus the hypothesis holds. A `BCI` card with a count and no label
loses its text, and a label on the card is enough to keep it.

**A correction to this record.** The control word holds the word count
in its address, not six times the count. The pass above expected
`740004000030`, and the print shows `740004000004`. The scanner adds
`SYX` to the address once for each word (CC027990 to CC028010), so
`SYX` holds 1. The next phase takes the address as the count of words
it copies (CD010650 to CD010730). `AXT 6,1` at CD010630 is not on this
path. This changes no conclusion above.

**The cards that lose their text.** The 40 X4 decks hold 33 `BCI`
cards. Twelve of them have a count and no label:

| Deck | Cards | Text |
|---|---|---|
| `EXPERR` | 15700390, 15700410 | `EXPONENTIAL OVERFLOW AT`, `ERROR IN EXPONENTIAL AT` |
| `BCDERR` | 26300300 | `NUMERIC CHARACTER` |
| `KAPUT` | 26600520, 26600540, 26600560 | ` IR4=`, ` IR2=`, ` IR1=` |
| `WRTEOB` | 29100300, 29100320 | `NUMBER OF BUFFERS`, `FIED AS 24 WORDS` |
| `BLERR` | 29400300 | `M BEFORE THE ITEM` |
| `TRAPEM` | 29700280 to 29700300 | three cards of 30 sixes |

`EXPERR` and `BCDERR` draw a message. The other four decks compile
clean in X4, but their texts are lost all the same. Thus a clean X4
listing does not show a correct library.

**The choice for Jack.** The library needs one change before SUBUP can
run, and each change alters 1963 material:

1. Give a label to each of the twelve cards. The compiler stays as the
   archive holds it, and the decks change on twelve cards, columns 1 to
   6 only.
2. Correct the patch at CC10163M. The decks stay as the archive holds
   them, and the compiler that M7 measures changes.
3. Change nothing, and build the library with the twelve texts lost.

The call is issue #236. SUBUP waits on it.

**Jack's call (2026-11-21, issue #236).** Jack, 2026-11-21:

> **Jack's answer:** A · Name the twelve cards

Thus the compiler stays as the archive holds it. `tool/m7/ct_library.sh`
gives each of the twelve cards the label `XLBn` in columns 1 to 6, where
`n` is the statement number of the card. The labels of the label probe
keep their names. No deck holds the string `XLB`, so no label is a
duplicate. The script stops if one of the twelve cards has a label in the
archive, or if the job does not hold all twelve labels.

| Deck | Card | Label |
|---|---|---|
| `EXPERR` | 15700390, 15700410 | `XLB30`, `XLB32` |
| `BCDERR` | 26300300 | `XLB24` |
| `KAPUT` | 26600520, 26600540, 26600560 | `XLB43`, `XLB45`, `XLB47` |
| `WRTEOB` | 29100300, 29100320 | `XLB24`, `XLB26` |
| `BLERR` | 29400300 | `XLB16` |
| `TRAPEM` | 29700280, 29700290, 29700300 | `XLB15`, `XLB16`, `XLB17` |

Each M7 summary states these twelve changes. The `SYSCOL` fault below
stopped the X4 step until its cause was known (issue #248).

**What stays open.** `SYSCOL` holds no `BCI` card, so this result does
not explain its fault. Each half of its table compiles clean alone
(probe of issue #230). Its fault blocks `SYS)161` under each of the
three choices.

**What the source shows about `SYSCOL`.** The listing prints `ILLEGAL
INTERNAL CONDITION` for messages 18, 24, 29, 124 and 182. A search of
the listing finds one call that issues any of them at severity 5,
`KAPUT` (CB002250): message 18 at CC013040 to CC013050. Two paths
reach it:

- the end of file of the internal text, when the scanner reads the next
  sentence (CC012820 to CC012840);
- a new symbol whose length is 0 or more than 30 characters (CC012980
  to CC013030).

The listing does not show which path `SYSCOL` takes.

**What sets `SYSCOL` apart.** Its table makes 64 references to the one
symbol `SYSCOL`. No other library deck refers to one symbol so often.
The next is `MOVFLT`, with 48 references to `MOVT1`, and it compiles
clean. Each half of the table makes 32 references, and each half
compiles clean (`S1`, `S2`). Other decks have longer `CRYPT` blocks, so
the length of the block is not a likely cause. This is a hypothesis:
the source read so far shows no count of references.

**The next probe: the references.** `tool/m7/ct_probe.sh KIT syscol`
compiles six variants of `SYSCOL` in one job:

| Deck | Change | References to one symbol |
|---|---|---|
| `S0` | none | 64 |
| `S3` | each table address is `0`, not `SYSCOL` | 0 |
| `S4` | the first 56 table words only | 56 |
| `S5` | the first 63 table words only | 63 |
| `S6` | a second label `SYSCO2` at the same location; the second half of the table names it | 32 and 32 |
| `S7` | a 65th word, a copy of the first | 65 |

The results read as follows:

- `S3` and `S6` clean, `S0` and `S7` not: the count of references to
  one symbol causes the fault. `S4` and `S5` then bound the limit.
- `S3` clean and `S6` not: the count of symbolic references in the
  block causes it.
- `S3` not clean: the references do not cause it, and the next probe
  turns to the table words themselves.

**The result of the reference probe (2026-11-21, issue #238).** The Mac
ran `tool/m7/ct_probe.sh KIT syscol` on branch `cloud/m7-syscol` at
`e535c45`, the head of PR #237. All six compiles ran. `syscol.lst`
holds 1271 lines.

| Deck | Statements | References | Result | Deck punched |
|---|---|---|---|---|
| `S0` | 68 | 64 | 68, 5, once | no |
| `S3` | 68 | 0 | 68, 5, once | no |
| `S4` | 60 | 56 | clean | yes |
| `S5` | 67 | 63 | clean | yes |
| `S6` | 69 | 32 and 32 | clean | yes |
| `S7` | 69 | 65 | clean | yes |

The statement count is the number of the `ENTER COMMERCIAL TRANSLATOR`
card. The message of `S0` and `S3` is `ILLEGAL INTERNAL CONDITION.
NOTHING DONE. POSSIBLE COMPILER ERROR.` Each of the two compiles dumps
with `LOC 13721`, and its dump differs from the other in five lines
only.

These facts follow:

- The references do not cause the fault. `S3` names no symbol and
  fails as `S0` does. `S7` makes 65 references and compiles clean.
- The count of table words does not cause it. `S5` (63 words) and `S7`
  (65 words) compile clean.
- The two decks that fail are the two decks whose `ENTER COMMERCIAL
  TRANSLATOR` card is statement 68.

The record expected `S7` to fail if the count of references caused the
fault. `S7` compiled clean, so this record withdraws that hypothesis.

**What the source shows.** The MQ of each dump ends in `500022`. The
word at CC013050, `WMS011,KAPUT`, ends in the same digits: tag 5 and
address 22 octal, which is message 18. Thus the fault is probably that
call. It has two paths (above). The first is the end of file of the
internal text, at `PLINK` (CC012820 to CC012840). A fault at one
statement number fits that path better than the path of a symbol
length. This is a hypothesis: the source read so far does not show
where the internal text ends.

**The next probe: the position.** `tool/m7/ct_probe.sh KIT pad`
compiles four variants of `SYSCOL` in one job. Each adds `BSS 0` cards
with no label, which give no word and name no symbol:

| Deck | Change | Statement of the `ENTER` card | Table words |
|---|---|---|---|
| `S0` | none | 68 | 64 |
| `S8` | one `BSS 0` card before the table | 69 | 64 |
| `S9` | `S2`, with a `BSS 0` card for each card it drops | 68 | 32 |
| `S10` | `S5`, with a `BSS 0` card for the card it drops | 68 | 63 |

The results read as follows:

- `S8` clean, `S9` and `S10` not: the position of the `ENTER` card
  causes the fault, and the table does not. The next probe then puts
  the `ENTER` card of a clean library deck at statement 68.
- `S8` not clean, `S9` clean: the table causes the fault, and the next
  probe turns to the table words.
- Any other result: this record states the facts, and the next probe
  starts from them.

**The result of the position probe (2026-11-21, issue #240).** The Mac
ran `tool/m7/ct_probe.sh KIT pad` on master at `51b2018`. All four
compiles ran. `pad.lst` holds 831 lines.

| Deck | Statement of the `ENTER` card | Table words | Result | Deck punched |
|---|---|---|---|---|
| `S0` | 68 | 64 | dump at `LOC 13721`, severity limit | no |
| `S8` | 69 | 64 | clean | yes |
| `S9` | 68 | 32 | clean | yes |
| `S10` | 68 | 63 | clean | yes |

This is the third reading of the table above, "any other result". The
facts:

- Only the unchanged deck fails. `S9` and `S10` put the `ENTER` card at
  statement 68 and compile clean. Thus the statement number alone does
  not cause the fault.
- `S8` keeps all 64 table words and compiles clean. Thus the table alone
  does not cause it.
- In this run `S0` prints no message line. The listing goes from the
  `ENTER` card to the dump. In the probe of issue #238 the same deck
  printed `ILLEGAL INTERNAL CONDITION` (message 18) at statement 68. The dump header is the same in
  both runs.

Across the probes of issues #230, #238 and #240, one change of any kind
makes the deck clean: a card more (`S7`, `S8`), a card less (`S5`), or
a card of a different kind (`S9`, `S10`). The one change that kept the
fault, `S3`, replaced the symbol `SYSCOL` with `0` in each table word.

**What the source shows.** The definition pass reads the internal text
one sentence at a time (CC012650 to CC012850):

1. `READ` takes two words from the file `CTONEI`: the link word `CLINK`
   and `BLINK`. An end of file here goes to `EOF2`, the normal end of
   the text (CC012690 to CC012730).
2. The decrement of `CLINK` gives the length of the sentence. `PLINK`
   then reads that number of words into `BUFAA`. An end of file here
   goes to `UNDAA`, which issues message 18, `KAPUT` (CC012820 to
   CC012840, CC013040 to CC013050).

The scanner wrote the same file as `CTWOHO`, on `SYSUT1`. Each sentence
is one `WRITE` with the list `CLINK`, `BLINK` and the words of the
sentence (CC035520 to CC035580). The scanner closes `CTWOHO` with a
rewind, and the definition pass opens it again as `CTONEI` (CC004790
to CC004820). Both files are in the big buffer pool (CB004280 to
CB004290). Its buffers are of `BBFSZE`, 112 words (CB000790). The
buffered `READ` and `WRITE` of IOCS move words across the end of a
buffer without a call to the program.

`ENTER COMMERCIAL TRANSLATOR` is the last sentence of `SYSCOL`. Only
the `*FINISH` card follows it (16100730 to 16100740). Thus message 18
at that card means that the file ended inside the last sentence: the
header of the sentence was read, and its words were not.

**The hypothesis: the length of the text.** The fault depends on the
number of words in the internal text, not on the statement number or
on the table. At one length, the end of the text meets the end of a
buffer, and the last part of the text does not reach the definition
pass. Each clean variant changes the length. `S3` probably keeps it:
a symbol and the number `0` can each take one word of text. This is a
hypothesis. The source read so far does not show the step of IOCS that
loses the words.

**The next probe: labels on the table.** `tool/m7/ct_probe.sh KIT
labels` compiles 65 variants of `SYSCOL` in one job. Deck `L0` is
`S0`. Deck `Ln` gives a label to the first n table cards, `XL009` on
card 16100090 to `XL072` on card 16100720. A label adds words to the
text of its sentence. It adds no statement, and it changes no table
word. The `ENTER` card stays at statement 68 in all 65 decks.

The results read as follows:

- All 65 decks fail: the statement number, or the count of sentences,
  causes the fault. The text length does not.
- `L0` fails, and the other decks are clean: the text length causes
  it. A label then takes a number of words that does not divide the
  length of a buffer within 64 labels. The next probe uses a step of
  one word.
- `L0` fails, and a set of other decks fail at a fixed step: the text
  length causes it. The step times the words of one label gives the
  period of the fault, and the period is probably the length of a
  buffer.
- Any other result: this record states the facts, and the next probe
  starts from them.

**The result of the label sweep (2026-11-21, issue #242).** The Mac ran
`tool/m7/ct_probe.sh KIT labels` on master at `7d5c39b`. All 65
compiles ran. `labels.lst` holds 12401 lines.

| Decks | Statement of the `ENTER` card | Result | Deck punched |
|---|---|---|---|
| `L0` | 68 | `ILLEGAL INTERNAL CONDITION` at 68, severity 5; dump at `LOC 13721` | no |
| `L1` to `L64` | 68 | clean | yes |

This is the second reading of the table above. The facts:

- One label is enough to make the deck clean. Thus the statement
  number and the count of sentences do not cause the fault.
- The dump of `L0` has the same header line as the dump of `S0` in the
  probes of issues #238 and #240. The message page printed again in this
  run.

A label is one word of text: the words before the comma of a `BCI`
card are the label, the control word and the count (table above). Thus
`Ln` adds n words to the text of `L0`. If the fault comes back at a
period of P words, it comes back at `Ln` with n = P. No deck failed, so
P is more than 64. The buffer of 112 words fits this. The probe does
not yet show a period.

**What the source shows.** The scanner writes each sentence with one
`WRITE`: `CLINK`, `BLINK`, then the words at `LINK` (CC035520 to
CC035580). The definition pass reads them with two calls of `READ`.
The first reads `CLINK` and `BLINK` (CC012690 to CC012730). The second
reads the words of the sentence (CC012820 to CC012850). Message 18
comes from an end of file in the second call. Thus the writer and the
reader split each sentence at different points.

**The next probe: steps of one word.** `tool/m7/ct_probe.sh KIT steps`
compiles 455 variants of `SYSCOL` in one job. Deck `PjNn` is `Ln` with
j `BSS 0` cards with no label after card 16100080. Here j is 1, 2, 4,
8, 16, 32 or 64, and n is 0 to 64. `P1N0` is `S8`.

A `BSS 0` card with no label adds one sentence of h words, and h is not
known. Deck `PjNn` adds j·h + n words. A fault at a period P comes back
where j·h + n is a multiple of P. For each h from 1 to 112, one j of the
list gives j·h between 48 and 112. Thus if P is 112, at least one deck
fails, and n gives its step of one word. The statement number of the
`ENTER` card changes with j, and the position probe showed that it does
not cause the fault.

The results read as follows:

- Two or more decks fail: the text length causes the fault. Two
  failures give h and P. If P is 112, the next step reads the `WRITE`
  and `READ` of IOCS at the end of a buffer.
- No deck fails: the text length alone does not cause it, or no deck
  reaches a multiple of P. A label also adds a symbol to the
  dictionary, so the next probe then turns to the dictionary.
- Any other result: this record states the facts, and the next probe
  starts from them.

**The result of the step probe (2026-11-21, issue #244).** The Mac ran
`tool/m7/ct_probe.sh KIT steps` on master at `05467d1`. All 455
compiles ran. `steps.lst` holds 103343 lines. 451 decks compiled clean
and punched a deck. Each deck with j = 1, 2 or 4 is clean. Four decks
failed:

| Deck | Statement of the `ENTER` card | Result | Deck punched |
|---|---|---|---|
| `P8N63` | 76 | `ILLEGAL INTERNAL CONDITION` at 76, severity 5; dump at `LOC 13721` | no |
| `P16N15` | 84 | the same, at 84 | no |
| `P32N30` | 100 | the same, at 100 | no |
| `P64N60` | 132 | the same, at 132 | no |

The four dumps have the header line of the dumps of `S0` and `L0`. This
is the first reading of the table above: two or more decks fail, so
the length of the text causes the fault.

**The period.** Deck `PjNn` adds j·h + n words to the text of `L0`.
Each failing deck adds a multiple of P:

| Deck | Words added |
|---|---|
| `P8N63` | 8h + 63 |
| `P16N15` | 16h + 15 |
| `P32N30` | 32h + 30 |
| `P64N60` | 64h + 60 |

Two times the first line, less the second, is 111. Thus P divides 111,
which is 3 times 37. The label sweep showed that P is more than 64.
Thus P is 111. Then 16h + 15 is a multiple of 111, and h is 6: a `BSS 0`
card with no label adds six words of text. With h = 6 and P = 111 the
four decks add 111, 111, 222 and 444 words. The same values give no
other failing deck among the 455: for j = 1, 2 and 4, the first
failing n is 105, 99 and 87, which are past 64. The prediction agrees
with every line of the result.

**What the source shows.** P is not the buffer size of 112. It is the
effective size of a buffer of a file with block sequence words:

- The file blocks `CTWOHO` and `CTONEI` (CB003290 to CB003430) both
  set the indicator `BLKSEQ`, octal 000200 in the left half of their
  second word. IOCS defines that bit as "BLOCK SEQ CHECKS" (IOC40170).
- When IOCS gives an output buffer to a file, it subtracts one word
  from the size if `BLKSEQ` is set: "FORM EFFECTIVE SIZE OF BUFFER"
  (IOC57060 to IOC57090). The select routine stores the block sequence
  number in the last word of the buffer (IOC61920).
- The big buffer pool has buffers of 112 words (CB000790, CB024920 to
  CB024940). Thus each block holds 111 words of text.

Thus the fault comes back each time the text grows by one block. At
one position of the end of the text in its last block, the definition
pass reads the header of the last sentence and does not get its words.
The source read so far does not show that position, or the step of
IOCS that loses the words.

**The next probe: the edge.** `tool/m7/ct_probe.sh KIT edge` compiles
five decks of the step probe with the `COLAG` option, which prints
every internal text buffer: `L0`, `L1`, `P8N62`, `P8N63` and `P8N64`.
`L0` and `P8N63` fail. Each of the other three is one word of text away
from a deck that fails. The print shows these facts:

- the number of buffers of each deck, and the number of words in the
  last buffer;
- the position of the header words of the last sentence, the
  `ENTER COMMERCIAL TRANSLATOR` card, in those buffers;
- whether the words of that sentence are in the print.

The results read as follows:

- The words of the last sentence are in the print of `L0` and `P8N63`:
  the scanner wrote them, and the reader lost them. The next step reads
  the `READ` routine of IOCS (IOC47240 to IOC47440) at that position.
- The words are not in the print: the writer lost them. The next step
  reads the `WRITE` routine (IOC47610 to IOC47730) and the close of the
  file (CC004790 to CC004820).
- Any other result: this record states the facts, and the next probe
  starts from them.

**The result of the edge probe (2026-11-21, issue #246).** The Mac ran
`tool/m7/ct_probe.sh KIT edge` on master at `491745c`. All five compiles
ran. `edge.lst` holds 1392 lines.

| Deck | Result | `COLAG` print |
|---|---|---|
| `L0` | `ILLEGAL INTERNAL CONDITION` at 68, severity 5; dump at `LOC 13721` | none |
| `L1` | clean | 7 blocks |
| `P8N62` | clean | 9 blocks |
| `P8N63` | `ILLEGAL INTERNAL CONDITION` at 76, severity 5; dump at `LOC 13721` | none |
| `P8N64` | clean | 9 blocks |

This is the third reading of the table above, "any other result". The
facts:

- The two failing decks print no `COLAG` text. The listing goes from the
  `ENTER` card to one line of octal, then to the dump. The dump holds the
  same line. Thus the line is a buffer in core, not a `COLAG` print.
- In the three clean decks, the print ends with the sentence of card
  16100720, `SVN SYSCOL,,28672` (word `220000070000`), then zeros.
- In the failing decks, block 1 of the line holds `600701360336
  220000000001 000000000000`. In the clean decks it holds `600701360336
  220000000000 020001070676`.

**What the source shows.** The edge probe rested on a wrong premise. The
`COLAG` option does not print the internal text that the scanner writes.
It prints the file `CTCOLG`, "COLAG INTERNAL FILE" (CC002280). The
definition pass writes that file with `TSX COLAG,4` (CC004830, CC067530
and the cards after it), and the first pass of the assembly reads it
(CB004860). The final buffer goes to the printer at the end of the
compile (CB037160, CB037650 to CB037660). The definition pass stops at
message 18, so a failing deck prints no `COLAG` text. The one line before
the dump is probably the first `CTCOLG` buffer, as the definition pass
left it.

Thus the probe cannot show where the last sentence falls in the internal
text. That text is on `SYSUT1`: the scanner writes it as `CTWOHO`, and
the definition pass reads it as `CTONEI` (CB003290 to CB003430).
`run_ibsys.sh` mounts `SYSUT1` as the file `sysut1.bin` and keeps it
after the run.

**The next probe: the SYSUT1 tape.** `tool/m7/ct_probe.sh KIT ut1`
compiles `L0`, `L1`, `P8N63` and `P8N64`, each in a job of its own, with
no `COLAG` option. After each job it keeps `sysut1.bin` as
`ut1-NAME.bin`. `tool/m7/tape_map.dart --words` prints every record of
that tape in octal, into `ut1-NAME.txt`.

A failing compile stops in the definition pass. Thus the `SYSUT1` tape
of `L0` and of `P8N63` holds the internal text as the scanner wrote it.
A clean compile goes on, and a later phase can write `SYSUT1` again.
Thus the tapes of `L1` and `P8N64` show the shape of a clean tape, but
not always the internal text.

Each block of the text is a record of 112 words. The last word of each
record holds the block sequence number in its address (IOC61920). Each
sentence starts with `CLINK`, and the decrement of `CLINK` gives the
count of words that follow `BLINK` (CC012820 to CC012840).

The results read as follows:

- The tape of `L0` holds the last sentence whole: its `CLINK`, its
  `BLINK`, and the count of words that its `CLINK` gives. The scanner
  wrote the words, and the reader lost them. The next step reads the
  `READ` routine of IOCS (IOC47240 to IOC47440) at that position.
- The tape of `L0` ends inside the last sentence, or before it: the
  writer lost the words. The next step reads the `WRITE` routine
  (IOC47610 to IOC47730) and the close of the file (CC004790 to
  CC004820).
- Any other result: this record states the facts, and the next probe
  starts from them.

The tape of `P8N63` must give the same reading as the tape of `L0`. If it
does not, this record states the facts.

**The result of the SYSUT1 probe (2026-11-21, issue #248).** The Mac ran
`tool/m7/ct_probe.sh KIT ut1` on master at `dbcbb32`. All four compiles
ran:

| Deck | Result | Records of file 0 | Words of the last record | Bytes of the tape |
|---|---|---|---|---|
| `L0` | `ILLEGAL INTERNAL CONDITION` at 68, severity 5; dump at `LOC 13721` | 7 | 2 | 4046 |
| `L1` | clean | 7 | 3 | 4052 |
| `P8N63` | `ILLEGAL INTERNAL CONDITION` at 76, severity 5; dump at `LOC 13721` | 8 | 2 | 4718 |
| `P8N64` | clean | 8 | 3 | 4724 |

Each record of file 0 before the last holds 112 words. Its last word
holds the block sequence number. File 0 ends with a file mark, and
file 1 is empty.

**How the text reads.** The writer and the reader show the form of a
sentence on the tape (CC035520 to CC035580, CC012690 to CC012850):

1. `CLINK`, an `IOCT LINK,,n` command. The reader reads this word into
   the command at its own `CLINK` and executes it.
2. `BLINK`. Its address holds the statement number.
3. The n words of the sentence.

The last two sentences of `L0` are both of statement 68 (octal 104):

| Sentence | `CLINK` | `BLINK` | Words |
|---|---|---|---|
| first | `500002063622` | `500000000104` | `570000000032`, `770000000075` |
| last | `500002063622` | `500000000104` | `400001000036`, `770000000075` |

In `L0`, the `CLINK` and `BLINK` of the last sentence and its first word
are the last three data words of record 0.5. Its second word,
`770000000075`, is the one data word of record 0.6. In `L1` the label adds
one word earlier in the text. Thus record 0.5 ends after `BLINK`, and
record 0.6 holds both words of the sentence. `P8N63` and `P8N64` give the
same two shapes one record later.

This is the first reading of the probe: the tape holds the last sentence
whole. The scanner wrote the words, and the reader lost them. The tape of
`P8N63` gives the same reading.

**The rule: a failing text is 1 word past a block.** `L0` holds
6 × 111 + 1 = 667 words of text, and `P8N63` holds 7 × 111 + 1 = 778. Its
last block thus holds one data word and the block sequence word: a record
of two words. Each clean deck has a last record of three words. This agrees
with the period of 111 words of the step probe.

**What the source shows: a record of two words is noise.** The I/O
executor of IBSYS, IOEX, tests the length of each tape record when the
channel ends:

- `NRTST` takes the word count of the record. A count above 2 is not
  noise (IBB54050 to IBB54120).
- `NTEST` takes a count of 0 as no record. A count of 1 or 2 turns off
  the indicator 400000, "NOISE RECORD INDICATION" (IBB66641 to
  IBB66643).
- The select routine of IOCS then takes the second return, "DISCARD
  NOISE RECORD", for a read (IOC60680 to IOC60740).
- IOEX goes to `END11`, "STANDARD NOISE RECORD ACTION". For a read it
  prints `REC DISCRDED-NOISE` and reads the next record (IBB53280,
  IBB53460 to IBB53600, IBB61690).
- For a write it issues `WROTE SHORT REC.` and goes on (IBB53500 to
  IBB53510, IBB53610 to IBB53620, IBB61660).

These cards are from `IBSYS/ibsys.map`, version 6, modification 11. The
kit runs the nucleus of `ASYS1.BIN`, not that assembly. Thus this record
checked the nucleus too. File 0, record 1 of `ASYS1.BIN` holds the same
code: words 4557 to 4564 are `NRTST` with the test `TXH 1255,4,2`, and
words 5214 to 5216 are `NTEST` with `TXL 1255,4,0` and `RIL 400000`.
Both tests go to the same exit, 1255.

**The cause of the `SYSCOL` fault.** The chain is now complete:

1. The scanner writes the text in blocks of 111 words and a sequence
   word. When the text is 1 word past a block, the last block is a
   record of two words.
2. On the read, IOEX discards that record as noise and reads the file
   mark after it.
3. The definition pass reads the header of the last sentence from the
   block before. The read of its words then meets the end of file, at
   `UNDAA`, and issues message 18, `KAPUT` (CC012820 to CC012850,
   CC013040 to CC013050).

A record of one data word can only hold the last word of a sentence,
because each sentence starts with two words. Thus each such text loses
the end of its last sentence and draws message 18. No such text compiles
clean.

The simulator does not cause this fault. The code that discards the
record is in the system tape, and the archive holds the same code. Thus a
1963 machine would discard the record too, if its tape unit ended the
record at two words. This is a hypothesis about the real unit: the
manuals and the archive do not show it. The fault can reach any compile
under this system, the 90.05 job too, about one text in 111.

**What the library needs.** `SYSCOL` must not leave a text 1 word past a
block. A label on one card changes the length by one word, and `L1`
proves that the deck then compiles clean. That change is of the kind
that Jack chose for the twelve `BCI` cards (issue #236): the label goes in
columns 1 to 6, and the compiler and the system stay as found. Thus the
method gives card 16100090 the label `XL009`, as `L1` does.
`tool/m7/ct_library.sh` adds it with the twelve labels of issue #236, and
the X4 step then expects 40 clean compiles.

**The next step.** The four `.lst` files of the probe hold the whole
printer output. A search of them for `WROTE SHORT REC.` and
`REC DISCRDED-NOISE` checks step 2 above (issue #251). Then the library
job runs with the thirteen labels.

**The result of the search (issue #251, 2026-11-21).** The Mac searched
the probe output for `SHORT` and `NOISE`, case-insensitive. No file
holds a match:

- The four listings `ut1-L0.lst`, `ut1-L1.lst`, `ut1-P8N63.lst` and
  `ut1-P8N64.lst` hold no match.
- The other text files of `KIT/run/probe/` hold no match. These include
  `console.txt` and `printlog.lst`.
- A search for `WROTE`, `DISCRD` and `REC` found only the end-of-jobs
  lines of the unit positions, for example `SYSOU1 IS A4 REC. 000nn`.

The search does not refute step 2. It does not confirm step 2 either.
Three limits apply:

- The listings hold the `SYSOU1` output only. IOEX can print its
  messages on the online printer or the console.
- Each run of the probe overwrote `console.txt` and `printlog.lst`.
  They hold the run of `P8N64` only, a clean deck.
- The probe keeps no console output for each deck.

Thus the cause stays as the source shows it, and the tape of `L0` gives
the record of two words. The library job does not wait on this check:
the label on card 16100090 removes the record of two words. A console
capture for each deck can check step 2 later, if a later fault asks
for it.

**The result of the library job (issue #252, 2026-11-21).** The Mac ran
`tool/m7/ct_library.sh KIT` on master at `9a740fc`. The job stopped at
step 4.

| Step | Result |
|---|---|
| 2, X4 | 40 of 40 compiles print `NO ERRORS WERE DETECTED DURING COMPILATION` and `THE LAST LOADER CONTROL CARD PUNCHED IS`. |
| 3, SUBUP | `IOEXMP  SBR CONTROL CARD IS NOT FOLLOWED BY *CTEXT CARD`, then `SUBUP NOT COMPLETED BECAUSE OF ERROR.` and `SUBUP BYPASSED 367 UNUSED MODIFICATION CARDS`. |
| 4, splice | `ct_lib.dart` stopped: the partial `SYSUT2` mixes odd and even parity. |
| 5, map | not run. |

The `XLB30` and `XLB32` cards of `EXPERR` keep their text. Thus the
thirteen labels work. The punch tape holds 366 records of 28 words in
file 0.

The script went on after the SUBUP error, because `run_ibsys.sh`
returns 0 when a job fails. The script now stops when `subup.lst` holds
`NOT COMPLETED`.

**What the source shows: SUBUP never read SYSUT4.** The count of 367
shows it. After the error, SUBUP reads the rest of the modification deck
from `SYSUT4` to its end, and counts from 1 (SU007160 to SU007300).
Each read adds 1, and the end of file prints the count. Thus 366 reads
give 367. The tape holds 366 records, so SUBUP read none of them before
the error.

The cause is the `TAPE` indicator `ILTIN` (SU002400):

1. The scan of the `$SUBUP` card sets `ILTIN` in `VMODE` when columns 1
   to 4 hold `TAPE` (SU006170 to SU006210).
2. The `*INSERT` path loads the indicators from `VMODE` (SU020420), and
   keeps them to SU020510.
3. A card with a type, octal or `PRIMARY`, calls `BSCAN` for the type
   (SU020870). `BSCAN` loads the indicators with the codes of the
   characters it scans (SU013080 to SU013100, SU013900). No code of the
   table `CTBL` holds the bit of `ILTIN` (SU018090 and after).
4. `MODPRC` tests `ILTIN` in the indicators, and it does not load
   `VMODE` first (SU021950 to SU021960). Thus a typed card reads its
   `*CTEXT` card from the card reader. The next card of the reader is
   the next `*INSERT` card, and SUBUP prints message `ERM09` (SU022010
   to SU022020, SU033960).
5. The binary cards and the `*CTEND` card load `VMODE` before the test
   (SU022090 to SU022110, SU022570 to SU022590). They read `SYSUT4`.

A card with no type does not call `BSCAN` (SU020850). It keeps `ILTIN`,
and reads all of its deck from `SYSUT4`. Eight of the 40 cards have a
type: routines 1 to 7 and 34, `MOVPAK`.

**The format of the punch tape agrees with SUBUP.** The compiler punches
each control card as 28 words of column binary, three columns to a word
(`HBC`, CE066580 to CE066940; `PNCHC`, CE066960 to CE067030). SUBUP reads
records of 28 words (`BQ00`, SU019420). It finds `*CTEXT` in words 2 and
3 (SU022940 to SU023000). `MASKL3` and `MASKR3` are the complements of
`*CT` and `EXT` in column binary (SU023140 to SU023150). Thus a typed
deck fails only on the source of its `*CTEXT` card.

**The method for step 3, amended.** SUBUP stays as the archive holds it.
The job gives each typed deck its `*CTEXT` card where SUBUP reads it:

- After each typed `*INSERT` card, the card reader gets a BCD card with
  `*CTEXT` in columns 7 to 12. SUBUP tests columns 7 to 12 only
  (SU022000 to SU022010).
- `tool/m7/ctext_drop.dart` copies the punch tape to `SYSUT4` without
  the `*CTEXT` cards of the eight typed decks. The X4 job compiles the
  decks in table order, so the n-th `*CTEXT` card is the card of routine
  n.
- The `$SUBUP` card gives `MAP,48`. SUBUP counts each card that it reads
  from the card reader (SU015440 to SU015460): 40 `*INSERT` cards and
  eight `*CTEXT` cards.

The deck words do not change: the `*CTEXT` card holds no deck word. The
rejected courses:

| Course | Cost |
|---|---|
| Correct `MODPRC` to load `VMODE` | changes the 1963 SUBUP that M7 measures |
| Put every deck on the card reader | `SYSIN` then needs binary cards, and no tool of the kit writes them into `sysin.bcd` |
| Give no type to the eight routines | the four fixed origins and the four primary routines are lost |

The next step: the Mac runs the library job again.

**The result of the second library job (issue #257, 2026-11-21).** The
Mac ran `tool/m7/ct_library.sh KIT` on master at `dfe6d80`. X4 compiled
40 of 40 decks clean again, and `ctext_drop.dart` dropped the eight
`*CTEXT` cards. SUBUP read the reader `*CTEXT` card and the text of
`IOEXMP`, and then stopped:

```
      IOEXMP  4-00000   SBR TEXT IS NOT FOLLOWED BY *CTEND CARD
       SUBUP NOT COMPLETED BECAUSE OF ERROR.
       SUBUP BYPASSED     356 UNUSED MODIFICATION CARDS
```

**What the source shows: SUBUP refuses every `*CTEND` card on
`SYSUT4`.** At the end of the text, SUBUP loads `VMODE` and tests
`ILTIN` (SU022570 to SU022590). The indicator is on, so `MD011` reads
the next record of `SYSUT4` (SU023040 to SU023110). It accepts the card
only when both tests give zero:

| Word | Test | Mask | The mask accepts |
|---|---|---|---|
| 2, columns 7 to 9 | `ANA MASKL3` | `573536776677` (SU023140) | `*CT`, `204241001100` |
| 3, columns 10 to 12 | `ANA MASKS3` | `375757673737` (SU023160) | `EVD`, `402020104040` |

The compiler punches `END` as `402020204040`. Its table `HBC2` gives
`E` as `4020`, `N` as `2020` and `D` as `4040` (CE066880 to CE066940).
`N` is the punches 11 and 5. The mask accepts `1020` in that column,
the punches 0 and 5, which is `V`. Thus the test leaves `000000200000`
in the accumulator, and SUBUP goes to `ERR24` (SU023080). No punched
`*CTEND` card can pass. The masks for `*CTEXT`, `MASKL3` and `MASKR3`,
agree with the punched card, and `IOEXMP` passed them.

The `4-00000` field does not give the card. `ERMS2` prints the deck
type, 4 for a text card (`SP066`, SU021670), and five octal digits from
bits 8 to 22 of `SEQNO` (SU033090 to SU033240). The sequence number is
in bits 21 to 35 (`SP065`, SU021660). Thus the field shows 0 for each
deck shorter than 8,192 cards.

The reader path tests `*CTEND` with the BCD word `SP062` (SU022600 to
SU022650), and that word is correct. Thus the fault is in the `TAPE`
path only, as the fault of `ILTIN` is.

**The method for step 3, amended again.** SUBUP stays as the archive
holds it. `tool/m7/ctext_drop.dart` now also writes `EVD` in columns 10
to 12 of each `*CTEND` card on `SYSUT4`. That is the complement of
`MASKS3`, the one card that the 1963 test accepts. The tool keeps the
parity of the record, and it prints the count of the cards it changes.
`ct_library.sh` stops unless the count is 40. The deck words do not
change: the `*CTEND` card holds no deck word.

The rejected courses:

| Course | Cost |
|---|---|
| Correct `MASKS3` in SUBUP | changes the 1963 SUBUP that M7 measures |
| Read the `*CTEND` card from the card reader | not possible: with `ILTIN` on, SUBUP reads `*CTEND` from `SYSUT4` only (SU022590) |
| Put every deck on the card reader | `SYSIN` then needs binary cards, and no tool of the kit writes them into `sysin.bcd` |

A good `*CTEND` card turns off `ILTIN` in `VMODE` (SU022660 to
SU022680). Each `*INSERT` card of the job has `TAPE` in columns 1 to 4,
so the scan of the next card sets it again (SU006170 to SU006210).

The next step: the Mac runs the library job again.
