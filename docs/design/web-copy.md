# Copy rules for the public website

*Recorded 2026-08-10, from two calls Jack made that day. This record governs
the words on the website (the W track in `docs/HANDOVER.md`). It governs no
other document. It settles no language fact and no compiler behaviour.*

*Status: proposed. Jack set the register and the tiebreak below. The rules that
follow are this project's reading of them, and he has not yet approved the
list.*

## 1. Why the site needs its own rules

Section 13 of `CLAUDE.md` puts every document under `docs/` in Simplified
Technical English. STE serves a maintenance manual. It does not serve a front
page, and Jack already exempted `README.md` and `CONTRIBUTING.md` for that
reason on 2026-08-07.

Jack extended the exemption to the site on 2026-08-10: the site copy "has to
have a whole different register". This record holds that register. Note the
split: this record is itself a repository document, so it is written in STE,
and the rules it states are not.

## 2. The readers

The site serves three groups at once, on one surface.

| Reader | What they came for | What loses them |
|---|---|---|
| A historian or an archivist | Whether the reconstruction can be trusted | An unsourced claim, or a number with no stated base |
| A software professional | How the compiler works, and where the code is | Marketing words, or a page that does not link the source |
| A curious young reader | A machine to press buttons on | A wall of prose before the first thing they can touch |

One surface can serve all three, because what loses each group is different
from what serves the other two. Nothing that serves the young reader costs the
historian anything, as long as rule C1 holds.

## 3. The tiebreak

**Jack's call, 2026-08-10.** Where simple and precise pull against each other,
choose simple, and link the repository artifact that holds the precise form.
The repository is the academic artifact. The site is the door.

This rule arbitrates between every rule below it, with one exception, which is
C1.

## 4. The rules

### A — Structure

- **A1. One surface, three depths.** Write the visible text for the youngest
  reader. Put the rigour one link below it. Never write the same sentence twice
  at two levels of difficulty.
- **A2. A link names what is on the other side.** Write "the decision record
  for the MOVE verb", not "learn more".
- **A3. Define each term at first use, on each page.** A reader arrives from a
  search engine, not from page 1.
- **A4. Cap the length.** A front-page paragraph takes three sentences. A
  tutorial step takes five. Longer material becomes a link.

### B — Voice

- **B1.** Use the second person, the active voice, and the present tense. "Type
  a program. The compiler prints the listing."
- **B2.** Vary the sentence length. STE's flat rhythm is correct for a
  maintenance manual and wrong for a front page.
- **B3.** Keep one idea in one sentence.
- **B4. Lead with the object the reader can touch.** The card, the hole, the
  printed page. The concept comes after it, or it does not come at all.
- **B5.** Use British spelling in this project's own voice. American spelling
  stays in every quotation, every manual title, and every line the compiler
  prints.

### C — Honesty

- **C1. Simplification changes how the site states the difference between an
  attested fact and this project's decision. It never removes the
  difference.** This rule outranks the tiebreak in section 3. A simpler
  sentence that hides a decision is not a simpler sentence. It is a false one.
- **C2. Three phrases carry that difference,** and the site uses them in place
  of the O3 evidence tiers:
  - "The manual says…" — a manual states it.
  - "We worked this out from…" — the sources constrain it but do not state it.
  - "Nobody knows. We chose…" — the sources are silent.
- **C3. Every number links to where it comes from.** 293 cards. 345 page
  scans. January 1962. R4 in `docs/opportunities.md` rejects a figure with no
  stated base, and that rejection reaches the site.
- **C4. Make no lineage claim and no priority claim** without a period source
  on the page. "The ancestor of COBOL" and "the first business language" are
  both banned in that form. Neither manual even uses the word COMTRAN.
- **C5. Invent no history.** No anecdote about an IBM programmer that a source
  does not carry.
- **C6. Define "we" once,** on the about page, which links
  `docs/reconstruction-method.md`. Section 11 of that document states how far
  large language models did this work, and the site inherits that duty.

### D — Register

- **D1. Use no marketing word.** Banned: revolutionary, powerful, seamless,
  unlock, journey, effortless, blazing, magic.
- **D2. Make no joke about the age of the technology.** This was serious work
  by serious people. Condescension to 1962 reads as condescension to the
  reader.
- **D3. Explain COMTRAN in its own terms, and compare it to no modern
  language.** Section 7 of `CLAUDE.md` forbids correcting the definition
  against COBOL knowledge. The same contamination reaches a reader through an
  analogy.
- **D4. Dates, form numbers and machine names carry the weight.** Write
  "January 1962", "the IBM 7090", "F28-8043". Vague period language such as
  "the early days of computing" loses all three groups at once.

### E — What the site never rewrites

- **E1.** Every line the compiler prints: the listing, the diagnostics, the
  storage map.
- **E2.** Every quotation from a manual, and its spelling.
- **E3. Mark a genuine typo `[sic]`.** Jack's call, 2026-08-10. Put the mark
  immediately after the word, inside the quotation. The word itself never
  changes. J28-6169 prints "at lease", "lables", "dinsity", "Parentheis" and
  "Appox-Max Size"; each keeps its spelling and takes the mark.
- **E4. Never mark an authentic period spelling `[sic]`.** "Alphameric" and
  "imbedded" are IBM's own words of the period, not errors. The mark would tell
  the reader that IBM made a mistake, which is a false claim and the one a
  historian catches first. Gloss the word at first use instead, under A3. Rule
  5 of section 8 of `CLAUDE.md` draws this line, and the fidelity policy in
  `comtran-manuals/README.md` states it.
- **E5.** The measured 1962 listing geometry.

E3 has two limits, and both hold outside this record. The manual conversions in
`comtran-manuals/` never carry the mark: they are the transcription of the
page, and an editorial mark inside them breaks ground truth. The documents
under `docs/` keep the form they already use, which puts `sic` in the citation
parenthesis after the quoted word. `docs/comtran-language-definition.md` holds
five of these. The site uses the inline form instead, because its reader has no
citation parenthesis to look in.

### F — Interface text

- **F1.** A control names its verb: "Compile", "Load the sample program",
  "Download the deck".
- **F2.** The site states its own failures plainly and says what to do next. It
  never paraphrases a 1962 diagnostic into one of its own.

## 5. The three statements the site must carry

W1 requires these on the site, in the reader's path. Write them under the rules
above, not in small print.

1. The reconstruction rests on one scanned copy of each manual, and one reader
   (`docs/opportunities.md`, O12).
2. Every resolution in §8.5 of the language definition is a labelled judgment
   call, not a fact.
3. Every per-message severity value is this project's own decision (Open
   Question 65).

## 6. Open items

- Jack has approved the register and the tiebreak. He has not approved the rule
  list.
- The site needs an about page for C6. Nothing specifies it yet.
