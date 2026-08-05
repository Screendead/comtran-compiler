# Improvement opportunities

*Started 2026-08-05.*

## 1. What this file is

This file holds a backlog of ways to make the project stronger as a piece of
research. It is **not an authority**. It binds no code and settles no question.
`docs/HANDOVER.md` holds the project state and the next task.
`docs/design/decisions.md` binds the code. This file only holds candidates.

Each entry has an `On` number. An entry stays in this file after it is done.
Mark it done and give the date. Never delete an entry.

## 2. How to use it

Read the ranked table first. Then read the entry for the item you want.

Each entry answers four questions:

- What is it?
- What does it buy?
- What does it cost?
- What blocks it?

Two rules keep the list honest:

1. An entry that is already on the roadmap does not belong here. Section 6 of
   this file records the ones that were proposed and rejected for that reason.
2. An entry must say what it buys in research terms, not in effort terms. "It
   would be tidier" is not a reason.

## 3. Where these came from

Two sources so far:

| Source | Date | What it gave |
|---|---|---|
| An external language-model review of the public repository | 2026-08-05 | O3, O4, O5, O6, O7, O8, O9, and the four rejections |
| This project's own work | 2026-08-05 | O1 and O2 |

The external review had no access to the working history. It graded the project
8.5 out of 10 as a research reconstruction. Its central claim is sound: nearly
all confidence in this project comes from one person, and that is the ceiling.
Its weaker claims are recorded in section 6.

## 4. The ranked list

Rank is by research value divided by cost, with readiness as the tie-break.

| Id | Opportunity | Cost | Ready? |
|---|---|---|---|
| O1 | Machine-check the canon deck against the manual conversion | Small | Yes |
| O2 | Re-read the scans with a second tool and diff the result | Medium | Yes |
| O3 | Tag every semantic rule with its evidence tier | Large | No — needs a unit of account |
| O4 | Give the project one reproducibility entry point | Small | Yes |
| O5 | Add citation and preservation metadata | Small | No — needs Jack's ORCID |
| O6 | Find more surviving COMTRAN artifacts | Unbounded | Yes |
| O7 | Get an independent domain expert to review the reconstruction | Unbounded | No — needs O9 or a public write-up |
| O8 | Link a generated instruction back to its page scan | Medium | No — needs O3 |
| O9 | Write a citable technical report | Large | No — needs M6 |

## 5. The entries

### O1 — Machine-check the canon deck against the manual conversion

**What.** `test/fixtures/90.05-payroll.ctd` and
`comtran-manuals/J28-6169/90.05-sample-program.md` transcribe the same printed
program twice, independently. A test can compare them card by card and fail on
any divergence in word spacing. Match a deck card to the conversion line whose
trailing words are identical. Then compare the blank runs between the words.

Two exclusions are necessary, and both are already settled:

- Skip the first gap when the card body opens with a label. The conversion pads
  the label field to a fixed column.
- Skip the Data Division. The listing prints those entries in its own fixed
  columns, so a difference there is not a spacing claim.

**What it buys.** It turns the project's strongest correctness claim from a
human judgment into a reproducible check. Two independent transcriptions of one
source, cross-checked on every commit, is a much better sentence in a paper than
"the transcription was checked carefully".

**Cost.** Small. One helper and one test. The method already exists as a
throwaway script and needs a proper home.

**What blocks it.** Nothing.

**Evidence it works.** On 2026-08-05 this comparison found two errors in
statement 193 that a scan-measurement pass had already declared complete. See
`test/fixtures/90.05-payroll-deck-notes.md` item 4.

### O2 — Re-read the scans with a second tool and diff the result

**What.** Convert the page scans to text a second time, with a different tool
from the one that made the current conversions. Then diff that output against
`comtran-manuals/*/*.md`. Treat every difference as a question, not as an error.
Most will be tool noise. A few will be real.

**What it buys.** It attacks the project's real single point of failure. Every
claim in this repository rests on two manual conversions that one person
produced and that get corrected one site at a time. O1 covers only the 293 cards
of the sample program. This covers both manuals end to end.

**Cost.** Medium. The diff will be noisy, and triage is the work.

**What blocks it.** Nothing, but it needs a large token budget. Do not start it
inside a rationing window.

### O3 — Tag every semantic rule with its evidence tier

**What.** Give every behavioural rule a tier:

| Tier | Meaning |
|---|---|
| Attested | A manual states it |
| Determined | Two or more independent sources leave one possible reading |
| Inferred | The sources constrain it but do not state it |
| Our decision | The sources are silent; this project chose |

Make the tags machine-readable, so a tool can count them.

**What it buys.** A defensible answer to the first question any historian asks:
how much of this is IBM's COMTRAN, and how much is this project's? The material
is already half-written. §8.5 of the language definition labels each resolution
a judgment call. `docs/HANDOVER.md` holds a residual-caveats section. Every
D-record cites its manual evidence. What is missing is a machine-readable form.

**Cost.** Large.

**What blocks it.** A decision on the unit of account. **Choose the denominator
before you publish any percentage.** A figure such as "92.7% directly attested"
is worthless, and in review it is worse than no figure, unless the reader can
see what was counted. Count rules, and say so. Never count lines.

### O4 — Give the project one reproducibility entry point

**What.** One documented command that rebuilds every generated artifact from
the sources and checks it. Then one plain sentence that says what a green run
proves.

**What it buys.** A reader can verify the project without reading the build.
Most of the work is already done: `dart test` runs the goldens, and CI runs
format, analyze, test and the deck freshness check. What is missing is a front
door and a claim.

**Cost.** Small.

**What blocks it.** Nothing.

### O5 — Add citation and preservation metadata

**What.** Three items:

- `CITATION.cff`, so the repository states how to cite it.
- A Zenodo deposit on each release, which mints a DOI.
- Software Heritage archival, which is free and needs one submission.

**What it buys.** Researchers can cite a version, not a moving branch. The work
survives the loss of the hosting account.

**Cost.** Small.

**What blocks it.** Jack's ORCID, and a decision on how to name versions.

### O6 — Find more surviving COMTRAN artifacts

**What.** Search for COMTRAN source decks, listings, or object decks beyond the
90.05 sample. Places to try:

- bitsavers, and the SHARE Secretary's Distribution tapes
- the Computer History Museum collection
- university archives that ran a 709 or 7090
- the IBM corporate archive
- private collectors, through the classic-computing lists

**What it buys.** The strongest validation available to this project. One more
recovered program that compiles correctly is worth more than any amount of
internal review. Five would be persuasive to a sceptic.

**Cost.** Unbounded, and the result may be nothing. Budget the search, not the
outcome. Record what was searched and found empty; that record is itself a
contribution.

**What blocks it.** Nothing.

### O7 — Get an independent domain expert to review the reconstruction

**What.** Ask a computing historian, an IBM 709x specialist, or a museum
volunteer to check the reconstruction against the sources.

**What it buys.** The one form of confidence this project cannot supply itself.
Note what is *not* missing: the project already runs adversarial review of its
own diffs. The gap is outside expertise, not more rigour.

**Cost.** Unbounded, and it depends on other people.

**What blocks it.** Something readable for a reviewer to react to. O9, or a
shorter public write-up.

### O8 — Link a generated instruction back to its page scan

**What.** A chain from one generated instruction, through the compiler rule and
the design decision and the language definition, to the manual page and the
scan.

**What it buys.** A reader can audit any single behaviour without trusting the
whole. Most links already exist: D-records cite manual sections, and
`tool/linkify_manual_refs.dart` already resolves a citation to a conversion
anchor. The missing link is from the code to the D-record.

**Cost.** Medium.

**What blocks it.** O3. The tier tags and the code-to-record link want one
scheme, not two.

### O9 — Write a citable technical report

**What.** A paper that states the method, the evidence rules, what was
recovered, and what was decided.

**What it buys.** A citable object. Researchers cite a report, not a repository.

**Cost.** Large.

**What blocks it.** M6. Write it when the compiler reproduces the sample
program's printed output.

## 6. Rejected, with reasons

Do not re-open these without new evidence.

### R1 — A COMTRAN-to-COBOL comparative analysis inside this repository

Section 7 of `CLAUDE.md` forbids correcting the language definition against
COBOL knowledge. A comparative study held in the same repository invites exactly
the contamination that rule prevents. The analysis is worth doing. Do it as a
separate work that cites this one.

### R2 — "Improve emulator fidelity"

This is the roadmap, not an opportunity. M4 stage 4 hardens the emulator, and
`docs/design/emulator.md` holds its decisions.

### R3 — Product-readiness and adoption metrics

Stars, forks and issue counts measure a different kind of project. The
repository was five days old when they were counted. Track nothing here.

### R4 — A headline percentage with no stated denominator

See O3. A precise-looking figure with an undefined base is a liability in
review, not an asset.

### R5 — "The README and HANDOVER are out of sync"

Checked on 2026-08-05 and not supported. `README.md` defers to
`docs/HANDOVER.md` for state, and the two status paragraphs agree. Re-open this
only with a quoted mismatch.
