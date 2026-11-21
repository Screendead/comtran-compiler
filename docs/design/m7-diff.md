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
