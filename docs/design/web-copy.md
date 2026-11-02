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
- **A3. Define each term the reader needs in order to follow the sentence,** in
  the prose, at first use on each page. A reader arrives from a search engine,
  not from page 1. "Deck", "listing" and "object code" are terms of this kind.
- **A3.1. A word that only needs disambiguating takes a gloss marker instead**
  (section G). The reader follows the sentence without it and wants it only on
  a stumble. "Alphameric" is a word of this kind.
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
  *Clarified 2026-08-10.* This rule sets a condition, not a ban. A lineage
  claim with a period source named in the reader's view satisfies it. R1 in
  `docs/opportunities.md`, as amended 2026-08-07, admits a period source that
  is itself comparative, and J28-6310 is one. What stays out is the
  comparative argument, which R1 rejects for the whole repository and the site
  is part of the repository. State the record; do not argue from it.
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
- **D5. Use no em dash.** *Jack's call, 2026-08-10.* The mark stays out of the
  copy, out of a caption, out of a page title, and out of a comment in a site
  file. Where a sentence seems to need one, write the sentence again. A colon,
  a full stop, a comma pair or a pair of parentheses does the same work.
  `test/web_copy_test.dart` enforces the rule. It reads each committed file in
  `web/` that its extension list names as text, and rejects the character and
  its three HTML forms, `&mdash;`, `&#8212;` and `&#x2014;`. A site file in a
  new text format adds its extension to that list in the same pull request.

  The en dash stays legal, because it is Jack's own register. *His call,
  2026-08-10: keep it minimal.* It is not the replacement for the mark this
  rule removes. A rewrite that turns each em dash into an en dash obeys the
  letter of D5 and defeats it. The test therefore counts the en dash in all
  its forms and caps the total across `web/`. To raise the cap, raise it in
  the pull request that needs the room and give the reason in the commit
  message.

  **A quotation is always verbatim.** *Jack's call, 2026-08-10.* E2 outranks
  this rule wherever the two meet. The transcribed title of F28-8043 holds an
  em dash, and the test names that title as an exception.

  **The generated pages.** *Jack's ruling, 2026-11-02, call 6 of
  `review/2026-11-02-pitch-rulings`.* D5 reaches the language reference that
  W2 builds under `web/sources/reference/`. The em dashes came out of
  `docs/comtran-language-definition.md`, and its reading copy in
  `docs/definition/` follows it. The reference keeps the mark in five places
  only:

  - a quotation, because E2 keeps it verbatim;
  - code;
  - a heading and the contents entry that repeats it, because the heading
    text sets an anchor that other files link to;
  - a parenthesis that holds a citation, because a change of punctuation
    there can move what the citation attaches to;
  - a table cell that holds the mark alone, as "none".

  `test/web_copy_test.dart` builds the reference pages in memory and enforces
  this list. It caps the dashes in citation parentheses at their count, 42.
  Lower the cap when one goes. D5 does not reach the manual transcriptions
  under `web/sources/`, because each of them is a quotation.

### E — What the site never rewrites

- **E1.** Every line the compiler prints: the listing, the diagnostics, the
  storage map.
- **E2.** Every quotation from a manual, and its spelling.
- **E3. Mark a genuine typo `[sic]`.** Jack's call, 2026-08-10. Put the mark
  immediately after the word, inside the quotation. The word itself never
  changes. J28-6169 prints "at lease", "lables", "dinsity", "Parentheis" and
  "Appox-Max Size"; each keeps its spelling and takes the mark.

  E3 reaches the manual transcriptions that W2 builds under `web/sources/`.
  *Jack's ruling, 2026-11-02, call 6 of `review/2026-11-02-pitch-rulings`.*
  The list `typos` in `tool/web_sources_source.dart` names the typos, and
  the build marks each occurrence on the page that prints it. A word goes on
  the list when all three of these hold:
  - the page scan prints it that way;
  - a conversion note, `comtran-manuals/README.md` or the language
    definition calls it a typo or a printing error;
  - it is not a period spelling (E4).

  The list holds eleven entries, all in J28-6169: "throught", "at lease",
  "lables", "dinsity", "Parentheis", "alwyas", "Mimimum", "standart",
  "Appox-Max", "depending of" and "bu" (for "but"). Each was checked on its
  scan. In "Appox-Max Size" the mark follows "Appox-Max", the word that holds
  the error. F28-8043 has no entry, because no conversion note records a
  typo in it.

  The list is not a proofreading pass of the manuals. A typo that no note
  records stays unmarked until a record adds it. These words wait for
  Jack's call, and stay unmarked until he decides:
  - "synonomous" and "indicies" (PDF page 116). The conversion note calls
    them "apparent period typos/spelling variants", so E4 can apply.
  - "in not used" (PDF page 171). It can be a print defect, and "not" is
    underlined.
  - "MIMIMUM" (PDF page 72). It is an option word on the `$LOAD` card. The
    spelling that the 1962 loader accepted is a fact about the processor.
  - "a fixed number or words" (PDF page 54). The note says "appears to be" a
    typo.
  - "if of the following form" (PDF page 124). No note records it.

  The mark is generated content on an empty element, so a copy of the text
  leaves it out (G3). `test/web_sources_test.dart` checks that each
  occurrence of a listed word carries the mark and that no other text does.
- **E4. Never mark an authentic period spelling `[sic]`.** "Alphameric" and
  "imbedded" are IBM's own words of the period, not errors. The mark would tell
  the reader that IBM made a mistake, which is a false claim and the one a
  historian catches first. Give the word a gloss marker in place instead
  (section G). Rule 5 of section 8 of `CLAUDE.md` draws this line, and the
  fidelity policy in `comtran-manuals/README.md` states it.
- **E5.** The measured 1962 listing geometry.

E3 has two limits, and both hold outside this record. The manual conversions in
`comtran-manuals/` never carry the mark: they are the transcription of the
page, and an editorial mark inside them breaks ground truth. The documents
under `docs/` keep the form they already use, which puts `sic` in the citation
parenthesis after the quoted word. `docs/comtran-language-definition.md` holds
five of these. The site copy uses the inline form instead, because its reader
has no citation parenthesis to look in. The language reference pages print the
`docs/` form, because they are the reading copy of a `docs/` file.

### F — Interface text

- **F1.** A control names its verb: "Compile", "Load the sample program",
  "Download the deck".
- **F2.** The site states its own failures plainly and says what to do next. It
  never paraphrases a 1962 diagnostic into one of its own.

### G — The gloss marker

*Jack's call, 2026-08-10: define a word in place rather than at a first use
further up the page.*

A gloss marker explains one word where the word stands. It carries a visible
affordance, and it opens on hover, on keyboard focus, and on tap.

- **G1. Do not carry the definition in a `title` attribute.** A `title` tooltip
  does not open on a touch screen, and screen readers treat it inconsistently.
  Those are the two readers the marker exists for.
- **G2. The definition is text in the page.** It reads correctly with
  JavaScript off and in a screen reader.
- **G3. Copying the text gives the original characters and nothing else.** A
  reader who copies a quotation gets IBM's words, without this project's gloss
  inside them. This rule bars the parenthetical form for any quoted word.
- **G4. Keep a gloss to one sentence.** A word that needs two sentences is a
  term under A3, not a gloss.
- **G5. The gloss marker and the "go deeper" link look different,** because
  they do different things. The gloss stays on the page. The link leaves it for
  the repository.

One note on the element. `<abbr>` is the familiar choice and its meaning is
wrong here, because a period spelling is not an abbreviation. Build one marker
component from a focusable element, and use it for both cases.

### H — When a project change reaches the site

*Recorded 2026-08-10, from a requirement Jack stated. He approved all six the
same day.*

Every push to master deploys the site (`docs/HANDOVER.md`, the Hosting
section). No window exists in which a page is stale but unpublished. Each rule
below therefore binds the pull request that makes the change, and none of them
is a follow-up task.

- **H1. A change to what the compiler prints needs no change to the site.**
  The site holds no compiler knowledge. It calls the compiler and prints the
  answer, and the deploy carries the new output. `docs/HANDOVER.md`, "The rule
  that keeps it cheap", states this. One exception: a new `--emit` stage needs
  a panel and a caption, which are site text.
- **H2. A milestone or a phase that changes state in the "Where things stand"
  table of `docs/HANDOVER.md` changes its station on `web/roadmap.html`,** in
  the same pull request. Both are written by hand and no tool compares them.
  `test/web_copy_test.dart` checks only that each codename appears.
- **H3. A number the site states moves with the fact behind it.** Rule C3 ties
  each number to a source, so a number that moves beside a page that does not
  is a false citation. One consequence: a number that moves each week stays
  off the site. Write "eighteen object pages", not the count verified so far.
- **H4. A capability the reader can see gets its prose in the pull request
  that ships it.** A run button, a deck download, a new stage panel: the page
  must not describe a site that no longer exists, in either direction.
- **H5. A limit that stops being true changes the sentence that states it.**
  Section 5 names three. If a second reader ever verifies the scans, the first
  statement becomes false, and a false limit costs more than no limit.
- **H6. Nothing else triggers a change to the site.** A refactor, a new design
  record, a new test and an edit to a document under `docs/` are all invisible
  here. The site records what a reader can see. It does not mirror the
  repository.

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

- Jack has approved the register, the tiebreak, rule D5 and all of section H,
  plus each call recorded in place below. He has not approved the rest of the
  rule list.
- The site needs an about page for C6. Nothing specifies it yet.
- C2's three phrases all speak about the manuals. None fits a fact that sits
  outside them and is attested elsewhere, such as the existence of J28-6310.
  The front page states one in plain prose, with no evidence box, because a
  box would file it as reconstruction evidence. A fourth register may be
  needed when there is more than one such fact.
- "We do not know" is barred wherever the truth is that this project declines
  to rule. *Jack's call, 2026-08-10.* The two are different, and the first
  states a scope decision as an evidentiary blank, which is the C1 failure
  running the other way.
- **The manual pages and rule E3.** *Closed 2026-11-02. Jack chose option 2
  (`review/2026-11-02-pitch-rulings`, call 6).* The W2 pages under
  `web/sources/` show each manual page whole, as the conversion holds it. The
  two options were:
  1. Scope E3 to the quotations in the site copy. A whole-page transcription
     then carries no mark, as the conversions carry none (section E).
  2. Mark each genuine typo on the pages. The build then needs a list of the
     typos, and G3 requires that a copy of the text leaves the mark out.

  Rule E3 now states the scope and the mechanism.
- **The generated pages and rule D5.** *Closed 2026-11-02. Jack chose option
  2 (`review/2026-11-02-pitch-rulings`, call 6).* The manual pages under
  `web/sources/` are quotations, and E2 outranks D5 for a quotation. The
  language reference is this project's own text, and `docs/definition/` held
  about 630 em dashes. The three options were:
  1. Scope D5 to the text written for the site. The reference then appears as
     the repository holds it.
  2. Remove the em dash from the language definition, and regenerate
     `docs/definition/`.
  3. Keep the reference off the site, and link the repository copy, until the
     dashes go.

  Rule D5 now states the scope and the dashes the reference keeps.
- **Headings that hold an em dash.** *Open, raised 2026-11-02. Jack
  decides.* Twenty-one headings of the language definition keep an em dash,
  and ten contents entries repeat them. A heading sets the anchor that other
  files link to, so a change to one needs a change to each link in the same
  pull request. Until Jack rules, the headings keep the mark.
