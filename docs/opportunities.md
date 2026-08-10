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
| An external language-model review of the public repository | 2026-08-05 | O3 to O9, and R1 to R4 |
| This project's own work | 2026-08-05 | O1, O2, and R5 |
| A second pass by the same external reviewer | 2026-08-05 | O10, O11, and the first amendment to R2 |
| Jack, refusing O1's original claim | 2026-08-05 | O12, the demotion of O1, and the second amendment to R2 |
| Halpern's memoir, and Jack's enquiry to the Computer History Museum | 2026-08-07 | The search records under O6 and O12, and the amendment to R1 |

The external review had no access to the working history. It graded the project
8.5 out of 10 as a research reconstruction. Its central claim is sound: nearly
all confidence in this project comes from one person, and that is the ceiling.
Its weaker claims are recorded in section 6.

## 4. The ranked list

Rank is by research value divided by cost, with readiness as the tie-break.

Ids are permanent. Rank is the row order, and a row may move.

| Id | Opportunity | Cost | Ready? |
|---|---|---|---|
| O12 | Find a second scan of each manual, or record that none exists | Small to attempt | Part done 2026-08-06 |
| O2 | Read the scans again with a different reader | Medium | Yes |
| O10 | State the reconstruction method as a method | Medium | Done 2026-08-06 |
| O11 | Keep a first-class record of refuted readings | Small | Yes |
| O1 | Hold the deck and the conversion consistent, mechanically | Small | Done 2026-08-06 |
| O4 | Give the project one reproducibility entry point | Small | Yes |
| O5 | Add citation and preservation metadata | Small | Part done |
| O3 | Tag every semantic rule with its evidence tier | Large | No — needs a unit of account |
| O6 | Find more surviving COMTRAN artifacts | Unbounded | Yes |
| O7 | Get an independent domain expert to review the reconstruction | Unbounded | No — needs O9 or a public write-up |
| O8 | Link a generated instruction back to its page scan | Medium | No — needs O3 |
| O9 | Write a citable technical report | Large | No — needs M6 |

## 5. The entries

### O1 — Hold the deck and the conversion consistent, mechanically

**Done 2026-08-06.** `test/deck_conversion_test.dart` holds the comparison.
It reaches all 112 Environment and Procedure cards, compares 438 blank runs,
and finds no divergence. The paragraphs below are the entry as written, with
the outcome recorded at the end.

**Read this first.** An earlier form of this entry called the two artifacts
independent transcriptions and claimed the check was a form of validation. Jack
refused that claim on 2026-08-05, and he was right. Both artifacts derive from
one scanned copy of one manual, and the same reader settled the text in each.
Two derivations from one source can show that they agree. They cannot show that
either is correct. **This entry is a regression gate. It is not evidence.** O12
and O2 are the entries that attack the underlying problem.

**What.** `test/fixtures/90.05-payroll.ctd` and
`comtran-manuals/J28-6169/90.05-sample-program.md` hold the same printed program
twice. A test can compare them card by card and fail on any divergence in word
spacing. Match a deck card to the conversion line whose trailing words are
identical. Then compare the blank runs between the words.

Two exclusions are necessary, and both are already settled:

- Skip the first gap when the card body opens with a label. The conversion pads
  the label field to a fixed column.
- Skip the Data Division. The listing prints those entries in its own fixed
  columns, so a difference there is not a spacing claim.

**What it buys.** Two things, both modest.

It stops drift. Every future correction touches one artifact and may not touch
the other. The 2026-08-05 pass corrected six sites in the conversion and one in
the deck, and nothing structurally stopped the two from parting company. A
standing check makes that class of divergence impossible to merge.

It catches a slip in one artifact but not the other, because the two derivations
put different pressure on the reader. Keying a card forces a decision about
every column. Transcribing a line of text does not, because gap width carries no
meaning. That asymmetry is why the check found the statement 193 errors.

**What it does not buy.** It cannot corroborate a reading. If the print is
faint or ambiguous and the reader gets it wrong, the same reader gets it wrong
in both artifacts, and the check passes. State this plainly wherever the check
is described. A consistency gate presented as evidence is worse than no gate.

**Evidence it works, and the size of that evidence.** On 2026-08-05 the
comparison found two errors in statement 193 that a scan-measurement pass had
declared complete. See `test/fixtures/90.05-payroll-deck-notes.md` item 4. That
is one divergence in 112 cards: a real catch, and a small sample. Do not build a
claim on it.

**Cost.** Small. One helper and one test. The method already exists as a
throwaway script and needs a proper home.

**What blocks it.** Nothing.

**What the build found.** The entry names two exclusions. A third was
necessary, and it is the same kind of thing: the Environment card's fixed
name and type fields, columns 7 to 30 (definition §1.9.3). The printer pads
those two fields, so a blank run inside them decides nothing about a punch.

Two matching rules were also necessary, and the entry did not predict either.
The listing glues a generated name to the first punched word, as in
`GN)000CALL`, because a generated name fills the name margin exactly. And two
listing lines carry the same words as each other, so a duplicate is only
ambiguous when the candidates disagree on their blank runs.

The build also corrected a claim. The throwaway script left 14 cards to a hand
check, and `test/fixtures/90.05-payroll-deck-notes.md` item 4 read that as 14
cards that no single conversion line matches. Six are, and the two rules above
match all six. Item 4 now records the correction.

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

*Pointer, 2026-08-10.* The web track's W1 phase is the strongest form of this
entry: a browser that compiles the sample needs no Dart SDK and no clone. See
the web track in `docs/HANDOVER.md`. This entry stays open, because a command
and a website are different doors and a reader may want either.

### O5 — Add citation and preservation metadata

**What.** Three items:

- `CITATION.cff`, so the repository states how to cite it. **Done 2026-08-05**
  (PR #73). It carries Jack's ORCID.
- A Zenodo deposit on each release, which mints a DOI.
- Software Heritage archival. **Done 2026-08-07** (PR #78). The snapshot is
  `swh:1:snp:54265d5e78e0d38ed2cafa6f37c94ae1c72ec955`, taken with `master` at
  `e322f82`. `CITATION.cff` carries it, and the README carries the archive
  badge. The archive re-crawls the origin on its own, so later work needs no
  second submission.

**What it buys.** Researchers can cite a version, not a moving branch. The work
survives the loss of the hosting account.

**Cost.** Small.

**What blocks it.** Only the Zenodo deposit is left. It needs a first release
and a decision on how to name versions, and M6 is the moment for both: "the
compiler reproduces the 1961 printed report" is a citable claim in a way that
the current state is not. Software Heritage needed neither, which is why it
went first.

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

**What the search found, 2026-08-06.** Jack asked the Computer History Museum
about reproduction of four un-digitised items. No reply had arrived by
2026-08-07. The four are:

| Item | What it is |
|---|---|
| Catalogue 102664056 | "IBM Commercial Translator", 1959, 79 pages. The catalogue record gives the form number as F29-8013. It is very probably F28-8013, the 1959 first edition. F28-8043's own front matter names it: "form F28-8013, which is obsolete and should be destroyed" (`comtran-manuals/F28-8043/00-front-matter.md`). Search under both numbers. |
| J28-6310 | "COBOL and Commercial Translator: A Comparison", bound into catalogue 102663034. IBM's own account of how the two languages differ. R1 below states how to handle it. |
| Bemer preprint | R. W. Bemer, "The Status of Automatic Programming for Scientific Problems", October 1957, 12 pages, Mark I. Halpern collection, Box 1. |
| Brady memo | Burnyce Brady, "Input-Output", 9 May 1957, 9 pages, same box. It discusses CLERK, the input/output section of COMTRAN. |

**Read the result correctly.** None of the four is a COMTRAN program, so none
of them can do what this entry asks for. This entry wants a program that
compiles; these are sources about the language. The entry stays open.

**Jack's ruling, 2026-08-07.** If F28-8013 arrives it takes the lowest rank of
the three manuals, and both present manuals supersede it.

**Deferred by Jack, 2026-08-08, and deferred knowingly.** A rank decides which
source binds the compiler. Whether a divergence gets recorded is a second
question, and the two are not the same. Jack wants the 1959 edition because it
predates IBM's revision under CODASYL influence, so those divergences are the
reason to hold the manual at all.

Section 8.3 of the language definition catalogues the F-to-J divergences and
gives both readings. Three options stand for the 1959 readings: extend section
8.3 to three sources, give them a section of their own, or keep them out of the
definition under the scope rule in section 7 of `CLAUDE.md`. The conversions
themselves are safe under every option, because section 6 of `CLAUDE.md` needs
Jack's authorization before anyone changes a manual conversion.

**Settle this after retrieval and transcription, and in that order.** The number
and the kind of the divergences decide which option fits, and nobody knows
either until the pages are read. Transcribe the manual first. Then choose where
the 1959 readings live. Do not write one into the language definition before
that choice is made.

### O7 — Get an independent domain expert to review the reconstruction

**What.** Ask a computing historian, an IBM 709x specialist, or a museum
volunteer to check the reconstruction against the sources.

**What it buys.** The one form of confidence this project cannot supply itself.
Note what is *not* missing: the project already runs adversarial review of its
own diffs. The gap is outside expertise, not more rigour.

**Cost.** Unbounded, and it depends on other people.

**What blocks it.** Something readable for a reviewer to react to. O9, or a
shorter public write-up.

*Pointer, 2026-08-10.* The web track is that write-up, and this entry is the
reason the track exists. See the web track in `docs/HANDOVER.md`. W1 gives a
reviewer a program to compile and a listing to check; W2 gives the reviewer the
page scan behind any reading.

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

*Pointer, 2026-08-10.* The web track names this entry as the site's natural
home, and schedules it nowhere. The block above still holds.

### O9 — Write a citable technical report

**What.** A paper that states the method, the evidence rules, what was
recovered, and what was decided.

**What it buys.** A citable object. Researchers cite a report, not a repository.

**Cost.** Large.

**What blocks it.** M6. Write it when the compiler reproduces the sample
program's printed output.

### O10 — State the reconstruction method as a method

**Done 2026-08-06.** `docs/reconstruction-method.md` holds it, in thirteen
sections. It answers all six questions below, it discloses how far large
language models did the work, and it closes with a checklist for a different
language. The paragraphs below are the entry as written, with the outcome
recorded at the end.

**What.** One document that says how this project decides things, written so
that someone reconstructing a different extinct language could follow it. It
must answer at least these:

- How does a conflict between two manuals get resolved?
- What counts as enough evidence to state a rule?
- When is inference allowed, and how is it marked?
- How is uncertainty carried into the code?
- How does doubt about a scanned character reach a design decision?
- Why was one reading preferred over another?

**What it buys.** The method may outlast the subject. COMTRAN is one extinct
language; the procedure for recovering one from its manuals is reusable, and
that is a larger contribution than the compiler. It also answers the question a
reviewer asks first, which is not "what did you build" but "why should I believe
it".

The parts are already written and scattered. `CLAUDE.md` section 6 ranks the
authorities and section 9 states the evidence rules. The language definition's
"Sources and authority" section holds the F and J rule and the fidelity
conventions. What is missing is one document that states them as a general
method rather than as house rules.

**Cost.** Medium. Mostly assembly and generalisation, not new thinking.

**What blocks it.** Nothing. It does not wait for M6, unlike O9.

**What the build found.** Two things the entry did not predict.

The document needed a rank of its own, and it has to be the lowest one. It
restates rules that `CLAUDE.md` and the design records already bind. Without a
stated rank, a later edit to either side becomes a peer collision for no
reason. The document therefore says in its first section that it binds
nothing, and that a disagreement means the method document is stale.

The hardest section to write was section 10, on what the method cannot do, and
it is the one a sceptical reader will read first. Three limits follow from one
cause — one scanned copy, one reader — and each names the outside work that
would lift it. That section is where O12, O2, O6 and O7 earn their place in
this file.

### O11 — Keep a first-class record of refuted readings

**What.** Record the readings this project considered and rejected, with the
evidence that killed each one. For example: a reading was held on the strength
of one page, later evidence contradicted it, and a decision record changed as a
result.

**What it buys.** It shows the reasoning, not just the destination. A historian
reading only conclusions cannot tell whether alternatives were weighed. A record
of discarded readings proves they were, and it stops a later reader from
re-proposing a reading that the evidence already killed.

Some of this exists as policy. §8.5 and the Open Questions list are annotated in
place and never deleted, and this file's section 6 does the same for
opportunities. What is missing is the same treatment for readings that were once
believed and then refuted — those currently survive only in commit messages.

**Cost.** Small to start, then continuous. The habit matters more than the
backfill.

**What blocks it.** Nothing.

### O12 — Find a second scan of each manual, or record that none exists

**What.** Search for a second, physically separate scan of F28-8043 and of
J28-6169-1. A different copy of the book, scanned by different people at a
different time. Then diff the conversion against it.

`comtran-manuals/README.md` records the current position: one 400-dpi PDF per
manual, with no text layer, OCRed and then corrected page by page against the
page images. Every claim this project makes about the source text passes through
that single copy.

**What it buys.** The only true corroboration available for the transcription.
Two readers of one scan can only agree about that scan. Two scans of two
physical copies are independent witnesses to the printing, and where they agree
on a character, that character is settled. Where they disagree, the project
learns something it cannot learn any other way — a copy defect, a print-run
difference, or a scanning artifact.

**The second outcome is also worth having.** If no second copy can be found,
say so in print. "The reconstruction rests on a single scanned copy of each
manual, and no second copy was located" is an honest statement of the project's
outer limit, and a reader needs it in order to weigh everything else. A search
that returns nothing is still a result; record where you looked.

**Where to look.** bitsavers and its mirrors, the Internet Archive, the Computer
History Museum, university libraries that held IBM systems documentation, the
IBM corporate archive, and collectors through the classic-computing lists. A
microfiche or microfilm copy counts, and so does a photographed original.

**Cost.** Small to attempt. Unbounded to exhaust. Bound the search and record
what it covered.

**What blocks it.** Nothing.

**What the search found, 2026-08-06.** Jack looked for a second digitisation of
either manual and found none. He stated that result in his enquiry to the
Computer History Museum of that date. Section 10 of
`docs/reconstruction-method.md` now prints it, and `comtran-manuals/README.md`
records it beside the source PDFs.

Two limits hold on that result, and a reader needs both. The search covered
digitisations in circulation, not uncatalogued physical copies. Its coverage was
not written down at the time, so treat bitsavers, the Internet Archive, the
university libraries, the IBM corporate archive, and the classic-computing lists
as still open. **This entry is part done, not done.**

The same pass settled the origin of the two PDFs this project reads. Both carry
the producer `tumble by Eric Smith` in their metadata, with two dates in 2004:
10 July for J28-6169-1, and 29 September for F28-8043. Run `pdfinfo` on each
file to see this. They share a toolchain, so one defect of that toolchain would
appear in both manuals and no internal check could find it.

## 6. Rejected, with reasons

Do not re-open these without new evidence.

### R1 — A COMTRAN-to-COBOL comparative analysis inside this repository

Section 7 of `CLAUDE.md` forbids correcting the language definition against
COBOL knowledge. A comparative study held in the same repository invites exactly
the contamination that rule prevents. The analysis is worth doing. Do it as a
separate work that cites this one.

*Amended 2026-08-07.* This rejection covers an analysis that this project
writes. It does not cover a period source that is itself comparative. The two
are different things, and the difference decides one pending item.

J28-6310, "COBOL and Commercial Translator: A Comparison", is an IBM
publication of the period. It is evidence of what IBM said in its own time. It
is not a modern comparison of the two languages. O6 above records the request
for it. **Without this amendment, a later reader meets a rejection record that
appears to forbid a document this project deliberately asked for.**

Three rules hold if it arrives. It needs a rank of its own before anyone reads
it, and that rank is not yet decided. Cite it for facts about Commercial
Translator only. Never let a COBOL fact inside it settle a COMTRAN rule, because
section 7 of `CLAUDE.md` still forbids that. The comparative argument stays out
of this repository, which is what this entry rejects and still rejects.

### R2 — "Improve emulator fidelity"

This is the roadmap, not an opportunity. M4 stage 4 hardens the emulator, and
`docs/design/emulator.md` holds its decisions.

*Amended 2026-08-05.* Hold two goals apart, because they are not the same goal.
This project reproduces what IBM's compiler produced: the same listing, the same
object deck, the same diagnostics. The emulator is a means to test that, and
nothing more. Cycle-accurate 7090 emulation is a fine thing, but it belongs to a
different project and it does not make this reconstruction more believable.
Spend on emulator work only where it decides a question about the compiler's
output.

*Amended again 2026-08-05, on Jack's instruction.* **This project does not build
a historically accurate 7090 emulator, and no wording here may be read as asking
for one.** D0.3 does not ask for one either: it commits to running the object
code the compiler emits, with the SYS) and IOC) runtime library emulated at a
high level rather than instruction by instruction. `lib/src/emulator/` holds 43
opcodes harvested from the sample listing, and it grows only when generated code
needs an opcode it does not have.

Jack named a second option on 2026-08-05: use an emulator someone else wrote,
such as the SIMH 7090 simulator, and say plainly that it is not ours. That is a
real change to D0.3 and it is not free. Several decision records read the
emulator's behaviour as their own decision — D4.1 on the ACL sign path, the DO
record on non-termination, the MOVPAK communication cells — and each would have
to become an observation of somebody else's simulator instead. **Do not amend
D0.3 without Jack's explicit instruction.**

### R3 — Product-readiness and adoption metrics

Stars, forks and issue counts measure a different kind of project. The
repository was five days old when they were counted. Track nothing here.

*Amended 2026-08-10.* A public website is now on the roadmap, and a later
reader could take it for the adoption push this entry rejects. It is not one.
The site exists to give a reviewer access to the compiler and to the page scans
(O7 and O4). **This rejection is unchanged: measure no audience.** Judge the
site by whether a reviewer can check a reading, not by how many people visit
it.

### R4 — A headline percentage with no stated denominator

See O3. A precise-looking figure with an undefined base is a liability in
review, not an asset.

### R5 — "The README and HANDOVER are out of sync"

Checked on 2026-08-05 and not supported. `README.md` defers to
`docs/HANDOVER.md` for state, and the two status paragraphs agree. Re-open this
only with a quoted mismatch.
