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
