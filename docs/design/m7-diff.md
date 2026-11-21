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

The method for part 1 comes from `EDITOR/editor.map`. Its entry
follows when the cloud reads that file.
