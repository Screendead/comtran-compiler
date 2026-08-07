# How to reconstruct a language from its manuals

*Started 2026-08-06. Audience: a reader who wants to judge this
reconstruction, or a person who wants to recover a different extinct
language.*

## 1. What this document is

This document states the method. It says how this project decides a question
about COMTRAN when the sources are thin, silent, or in conflict.

**It binds nothing.** Three files bind:

| File | What it binds |
|---|---|
| `CLAUDE.md` | The house rules for all work in this repository |
| `docs/design/decisions.md` | The compiler, through the D-number records |
| `docs/comtran-language-definition.md` | The recovered language |

This document describes what those three files do. If it disagrees with one of
them, the other file is right and this document is stale. Correct this
document.

The method has one goal. **A reader must be able to tell IBM's COMTRAN from
this project's decisions, at every point in the code.** Every rule below
serves that goal.

## 2. The shape of the problem

COMTRAN ran on IBM 709 and 7090 machines between 1959 and 1962. No compiler is
known to survive, and no program source outside the manuals. Two manuals
survive:

| Manual | Date | What it is |
|---|---|---|
| F28-8043 | June 1960 | The language as designed |
| J28-6169-1 | January 1962 | The language the field-test processor accepted |

One printed program survives with it: the compiled sample in J28-6169 Appendix
90.05. It holds the source listing, the generated code, and the report the
program printed. That sample is the only place where a claim about this
compiler meets a known-correct output.

Three properties of this evidence set drive everything below:

- **It is small and fixed.** No experiment can add to it. You cannot run the
  1962 compiler and see what it does.
- **It is layered.** A paper page becomes a scan, the scan becomes text, and
  the text becomes a claim. Each layer can lose something.
- **It disagrees with itself.** The two manuals were written 19 months apart,
  and the later one deletes, defers, and corrects parts of the earlier one.

## 3. Rank the sources before you start

Most conflicts are not decisions. They are already settled, because the
sources have a rank. Write the rank down first, once, and then obey it without
further argument.

This project's rank, highest first:

| Higher | Lower | Why |
|---|---|---|
| The page scan | The text conversion | The conversion is a reading of the scan |
| J28-6169 | F28-8043 | J describes what the processor accepted; F describes an intent |
| The manuals | The language definition | The definition is a reading of the manuals |
| A design record | The code | The code implements the record |

Two rules complete it:

1. **Amend the lower source to match the higher one.** Cite the rank in the
   amendment. Never amend the higher source to agree with the lower one.
2. **Where no rank covers the two sources, they are peers.** Stop. A peer
   conflict is a decision, and a person must make it. `CLAUDE.md` section 6
   gives the form: name the two things, quote each, state what each demands,
   list every option with its cost, and recommend one.

A worked case. F28-8043 says the serial-number field "will be sequence-checked
by the processor". J28-6169 says serial numbers "are not sequence checked by
the compiler". The rank settles it: J governs, the compiler does no sequence
check, and F is recorded as the intent of processors in general. See §8.5.2-d
of the language definition.

## 4. Grade the evidence

Give every claim a grade. This project uses four:

| Grade | Meaning |
|---|---|
| Attested | A manual states it, or the printed sample shows it |
| Determined | Two or more sources leave one possible reading |
| Inferred | The sources constrain the answer but do not state it |
| Our decision | The sources are silent, and this project chose |

The grade is not a quality score. An "our decision" record is not weaker work
than an "attested" one. It carries a different promise to the reader, and the
reader must be able to see which promise applies.

Grade the claim, not the document. One decision record can hold all four
grades in its parts. D4.1, the rounding record, does: the rounding threshold
is attested from [F p. 115], the emitted instruction shape is attested from the
sample listing, the accumulator sign behaviour is inferred from 709/7090
instruction semantics, and the handler internals are our decision because no
evidence survives.

**Never publish a percentage without its denominator.** "92% attested" is
worthless unless the reader can see what was counted. Count rules, and say
that you counted rules. This project has not yet built that count; see O3 in
`docs/opportunities.md`.

## 5. State a rule only at the grade its evidence supports

The test for "enough evidence" changes with the grade.

**Attested** needs a citation to a page or a section, and the citation must
survive a check against the scan. Nothing else.

**Determined** needs the sources listed and the exhaustion shown. Say why no
other reading fits. §8.5.3-e is one. [J 02.05.01] says that fields "of level
equal to the highest level in a source program" are left justified, and
"highest" can mean the deepest level or the smallest level number. J's own
worked example uses levels 05 and 10, and says the level-05 fields are the
left-justified ones. One reading survives.

**Inferred** needs the constraint named. State what the sources fix, and state
the step you took beyond them.

**Our decision** needs three things: the choice, the reason, and the word
*amendable* if later evidence could overturn it.

One more rule holds across all four. **A silence is not a permission.** When
neither manual answers a question, the question goes on the Open Questions
list at the end of the language definition. It does not quietly become a
feature.

## 6. Mark every inference where it lands

An inference marked in one file and lost in the next is not marked. This
project marks it three times, in the three places a reader can arrive.

- **In the catalog.** §8.5 of the language definition catalogs every known
  ambiguity. Each entry states the problem, then a paragraph that opens
  *Resolution:*. Every resolution is a labeled judgment call, and the file
  says so.
- **In the decision record.** Each D-record carries a **Status.** line, a
  **Decision.**, a **Rationale.**, an **Implementation.**, an **Oracle.**, and
  its citations. An unattested part names itself: "design decision under D0.4,
  amendable".
- **In the state document.** `docs/HANDOVER.md` holds a "Residual caveats"
  section. It states the standing weaknesses in plain words, including the two
  passes that never got an independent second look.

Two conventions keep the marks honest over time:

1. **Annotate in place. Never delete an entry.** §8.5 and the Open Questions
   list are living lists. When later work resolves an item, the entry gains
   the evidence and the date. It does not disappear.
2. **Amend a record by an explicit edit, and cite the evidence.** A record
   that changes silently teaches a later reader nothing.

## 7. Carry the uncertainty into the code, not around it

A compiler must choose. The manuals leave gaps, and a gap cannot stop the
build. The method's answer is to make each gap visible at the point where the
code depends on it.

Four devices do that here:

- **A bounded fidelity commitment.** D0.4 commits to bit-faithfulness *bounded
  by the evidence*. Where no evidence exists, the project chooses and labels
  the choice. It does not claim to reproduce what it cannot know.
- **A named oracle per decision.** Every D-record states what would prove it
  wrong. Most name the listing diff against the 1962 printed object code.
  Where no oracle exists, the record says "decision-conformance only" — the
  test can check that the code follows the decision, and nothing more.
- **A separate channel for our own notes.** The compiler's `--pedantic` flag
  carries diagnostics this project believes are useful but cannot attest to
  the 1962 compiler. The default run reproduces the historical behaviour. The
  sample program compiles with zero diagnostics by default and draws exactly
  three pedantic notes.
- **A record for what is unrecoverable.** The per-message severity values are
  an example. The 1962 manual documents the severity-code system and prints
  all 210 diagnostic messages, but it prints the severity code `0` against
  every one of them, because "the value may vary". No per-message severity
  survives. Every severity value in this project is therefore its own design
  decision, and `docs/design/severity-notes.md` says that in its first lines.

## 8. Take a doubtful character to the scan

A transcription is a reading. It can be wrong, and it can be wrong in a way
that changes a rule. The method sends every doubtful character back to the
image.

The rules:

1. **The page scan decides.** Each manual directory holds a 150-dpi image of
   every page. Check the image before you conclude anything about a doubtful
   reading.
2. **For any claim about card columns, measure the image.** Never read a
   column position from the indentation of a transcription. Indentation in a
   text file records the transcriber, not the punch.
3. **A change to a conversion needs an explicit authorization.** The
   conversions are read-only by default. Nine changes have been authorized so
   far, each with the measurement that justified it.

Measurement is the part people skip, so do it concretely. Compute the cell
width from a known ruler on the page, overlay it on the image, and read the
character positions against it. Calibrate for every page: registration differs
between pages of the same book.

Two cases show why this matters. In one, the print holds a single blank after
a comma where the keyed card held two, so the card was one column out of true
from that point rightward; the fix changed a golden test. In another, an
overpunch glyph chart in [J 02.05.05] was read from the scan and corrected,
which settled the polarity order the compiler uses.

## 9. Choose between readings, and keep the loser

When two readings both fit the evidence, the choice is a decision and it gets
recorded as one. The record must hold the reading that lost.

The form this project uses:

1. State every reading that the evidence permits.
2. State what each one costs. Name the feature it strands, the manual sentence
   it contradicts, and the test it makes impossible.
3. Name the chooser and the date.
4. **Keep the losing reading in the record as the amendment.** A later reader
   who wants to overturn the choice should find the alternative already
   written, with the evidence that failed to settle it.

D4.1 part (d) is the model. Three readings of the rounding emission rule
survived a full evidence pass. The sample program cannot separate them: none
of its 51 calls into the move-and-convert package discards a low-order digit,
so the printed listing is identical under all three. Jack chose the first
reading, on four stated grounds. The second stays in the record as the
amendment, and the third is refuted in place.

Note the shape of that outcome. The evidence pass did not decide the question.
It did something more useful: it proved that the question is undecidable from
the surviving sources, and it bounded what a wrong choice costs.

## 10. Know what the method cannot do

State the ceiling in print, where the reader will meet it. A method that hides
its limit is worth less than a weaker method that states one.

This project's ceiling has one cause. **Every claim passes through one scanned
copy of each manual, read by one person.** Three consequences follow, and none
of them is fixable from inside the repository:

- **Two derivations from one source cannot corroborate each other.** This
  project holds the 90.05 program twice: as a punch-level card deck and as a
  text conversion of the same printed listing. A test compares the two and
  fails on any divergence in word spacing. That test is a regression gate. It
  is **not** evidence. If the print is faint and the reader misreads it, the
  same reader misreads it in both artifacts, and the test passes.
- **Internal review raises rigour and not confidence.** This project runs
  adversarial review of its own diffs, and the reviews find real defects. A
  reviewer who reads the same scan cannot tell you that the scan was read
  right.
- **A single copy hides a copy defect.** A stain, a broken type slug, or a
  print-run difference is invisible until a second physical copy is compared
  against the first.

The repairs are known and they are outside the repository: a second physical
scan of each manual, a second reader with a different tool, a surviving
program from another site, and an independent domain expert. They are entries
O12, O2, O6, and O7 in `docs/opportunities.md`. **If the search for a second
copy returns nothing, print that too.** "No second copy was located" is a
result, and the reader needs it in order to weigh everything else.

## 11. Disclose the machine, and what it cannot witness

This reconstruction was built with heavy use of large language models. A
reader must know that. A reader must also be able to see exactly where the
machine's work stops and a person's judgment starts.

**What the machine did.** The mechanical work, and most of the drafting. It
converted the manual pages to text, wrote the compiler and its tests, drafted
the decision records, and searched the sources.

The scale, measured from the session transcripts on 2026-08-06 and not revised
since: about 30 sessions, 20,000 model calls, 19 million tokens of generated
text, and 600 subagents, in a little under five days. The author typed about
180 instructions in that time, with a median length near 100 characters. Read
every figure as a floor at that date. Later work only adds to it.

**What the author did.** Every judgment call, and every irreversible act.
Four practices carried that, and each one is visible in the transcripts:

- **He read the disputed characters himself.** Before any correction to a
  read-only source, he asked for the evidence in a form he could check —
  "everything I need to make the call on that judgement you made, including
  page scans, code snippets, and blown-up screenshots if appropriate" — and he
  answered against the images, not against the argument: "I reviewed the page,
  and the literal text is 100% manually confirmed"; "I have seen the evidence.
  I authorise the change."
- **He held the read-only sources shut.** The manual conversions cannot change
  without his explicit authorization. Nine changes have been authorized, and
  each one followed a measurement he checked.
- **He decided every open point.** The decision records carry a **Jack's call**
  status for exactly this reason. Where the evidence ran out, a person chose,
  and the record names them and the date.
- **He refused the machine's strongest overclaim.** The machine proposed that
  the card deck and the text conversion were independent transcriptions, and
  that agreement between them was a form of validation. He rejected it in one
  sentence: "If there's only one place, two passes with the same AI does not
  add any veracity." Section 10 of this document exists because of that
  refusal.

**Six controls made the machine's output usable.** They are the transferable
part:

1. **Force plain language before every decision.** He approved nothing he
   could not restate himself, and said so repeatedly: "Expand each jargon word
   into its actual meaning at least once." A decision a person cannot restate
   is a decision the machine made.
2. **Record the decision before writing the code.** Every entry in the
   ambiguity catalog was walked, and 84 decision records were locked, before
   any compiler code was written. Code generation then became execution
   against a locked specification, which is the part a machine does well.
3. **Review adversarially, with fresh context.** A reviewer reads the diff and
   the repository, never the author's plan or rationale. Several such reviews
   ran over pull requests and diffs, and two more came from language models
   outside this project, brought in as outside critics.
4. **Choose the model for the task, and write the rule down.** Cheap models do
   search and mechanical edits; design and review need the strongest available.
   Of the 600 subagents above, about 550 record which model they ran: a handful
   on the cheapest, roughly 500 on the middle tiers, and about 40 on the
   strongest — the last reserved for review and for judgment the evidence could
   not settle.
5. **Distrust a long context.** Work was cut into 30 sessions with 20 context
   restarts, on the stated rule that late-context output is less reliable than
   early-context output.
6. **Give the machine standing permission to refuse.** A machine that always
   agrees tells you only what you already think.

**What none of it buys.** Model effort does not add a witness. Six models that
read one scan are still one reading of one scan. Two passes over the same page
raise the chance of catching a slip, and they raise nothing else. Every limit
in section 10 survives the machine untouched, and heavy machine use makes one
of them sharper: the reader of the faint 1962 print was substantially a
language model, and a language model produces plausible text by construction.
That is the reason for the scan rule in section 8, for the grades in section
4, and for the human gate on every read-only source.

## 12. Admit period evidence, and fence it

Sources outside the two manuals are useful and dangerous. They are useful
where the manuals delegate. They are dangerous where a later, better-known
language fills a gap the manuals left, because the reader cannot then tell
recovery from assumption.

Two rules fence them:

1. **Label external evidence in place.** This project writes `(external: …)`
   with the full source. One record cites the April 1960 COBOL specification
   as period context for a rounding polarity, and labels it as context, not as
   evidence about COMTRAN.
2. **Never correct the recovered language against a modern expectation.** The
   language definition is corrected against the manuals or their scans, and
   against nothing else. A comparative study of COMTRAN and COBOL is worth
   doing; it belongs in a separate work that cites this one, because a
   comparison held in the same repository invites exactly the contamination
   this rule prevents.

## 13. A checklist for a different language

If you reconstruct a different extinct language, this is the method stripped
of COMTRAN:

1. **Inventory the sources, and write their rank down before you read them.**
   The rank prevents most arguments later.
2. **Find the one artifact with a known-correct output.** A compiled sample, a
   printed run, a listing with its report. Every claim you make becomes
   testable against it at once. If none exists, say so early; it changes what
   the project can promise.
3. **Scan first, convert second, and keep both.** The scan is ground truth
   forever. Never let the conversion become the thing you consult.
4. **Grade every claim, and mark the grade where the reader arrives.** Not
   once, in a preface.
5. **Keep two living lists: what is ambiguous, and what is unanswerable.**
   Annotate them in place. Never delete an entry.
6. **Give every decision an oracle, or state that it has none.**
7. **Keep the readings you rejected**, with the evidence that killed each one.
8. **State the ceiling in print**, and name the outside work that would raise
   it.
9. **Disclose your tools, and say what they cannot witness.** If a machine did
   the reading, say so, and keep a person's eyes on every irreversible edit to
   a source.

Step 7 is the one this project holds least well, and it says so. Refuted
readings survive here mostly in commit messages, not in a first-class record;
O11 in `docs/opportunities.md` is the open entry for that gap.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 115]: ../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[J 02.05.01]: ../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.05]: ../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
