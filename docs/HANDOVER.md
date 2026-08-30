# Handover — COMTRAN project state

*Updated 2026-08-30. Audience: the next agent, or Jack. This file is the
state document for the project. It holds what the next stretch of work needs.
Update it in the same commit that closes a milestone or a task, and update
`README.md` with it. Git holds the project history.*

## Glossary of the codenames

Every document in this repository uses these prefixes. This table is their one
home.

| Prefix | What it names | Where the series lives |
|---|---|---|
| `M0` to `M6` | A compiler milestone | The roadmap below |
| `T1` to `T4` | A parallel tooling task | The tooling track below |
| `W1` to `W4` | A phase of the public website | The web track below |
| `Dn` and `Dn.n` | A binding design decision record | `docs/design/decisions.md` |
| `M1-n`, `M2-n` | A design entry inside one milestone's note | `docs/design/m1-front-end.md`, `docs/design/m2-parser.md` |
| `ED-n` | An emulator design decision | `docs/design/emulator.md` |
| `LD-n` | A deck-writer or loader design decision | `docs/design/loader.md` |
| `C1` to `C5` | A diagnostic severity class from D9.2 | `docs/design/severity-notes.md` |
| `Qn` | An Open Question number | The Open Questions list in `docs/comtran-language-definition.md` |
| `On` and `Rn` | An improvement candidate, and a rejected one | `docs/opportunities.md`. Binding on nothing. |
| `§n` and `§8.5.n` | A section of the language definition | `docs/comtran-language-definition.md` |

Terms that appear without expansion:

| Term | What it means |
|---|---|
| `Set H` | The IBM character set whose card codes COMTRAN uses ([F p. 12]) |
| `n,cc` | A statement number: the statement `n`, then the clause digits `cc` ([J 02.02.01]) |
| `IOCS` | The 709/7090 Input/Output Control System ([J 02.07.01]) |
| `SYS)`, `IOC)` | Name prefixes of the runtime library entry points that generated code calls ([J 90.02]) |
| `MOVPAK` | The runtime move-and-convert subroutine package ([J 90.02.10]) |
| `90.05` | J28-6169 Appendix 90.05, the compiled sample program |

## Where things stand

| Item | State | Where |
|---|---|---|
| Language definition | Complete and verified | `docs/comtran-language-definition.md` |
| M0 design decisions (85 records) | Locked 2026-08-02; D4.14 back-filled 2026-08-16 | `docs/design/decisions.md` |
| Punch-level deck format | Frozen | `docs/design/deck-format.md` |
| 90.05 canon deck (293 cards) | Authoritative; its mirror is CI-slaved | `test/fixtures/90.05-payroll.ctd` |
| M1 front end | Done 2026-08-03 | `lib/src/lexer/`, `lib/src/listing/` |
| M2 stage 1 — AST and fixed-form parsers | Merged 2026-08-03 (PR #15) | `lib/src/ast/`, `lib/src/parser/` |
| M2 stage 2 — procedure division | Merged 2026-08-03 (PR #17) | `lib/src/parser/procedure_parser.dart` |
| M2 stage 3 — job stream and --pedantic | Merged 2026-08-03 (PRs #47–#49) | `lib/src/driver/` |
| M3 — the semantic layer | Done 2026-08-05 (stages 1–2 2026-08-04; stage 3, the listing extension, 2026-08-05) | `docs/design/m3-data.md`, `lib/src/data/` |
| M4 decision walk (M4-1 to M4-21) | Done 2026-08-05 | `docs/design/m4-codegen.md` |
| M4 stage 1 — the assembly model | Done 2026-08-05 | `lib/src/codegen/` |
| M4 stage 2 — core-verb text | Done 2026-08-28. Phase A done 2026-08-10 (all 18 object pages scan-verified); Phase B chunks B1 to B7 done 2026-08-15 to 2026-08-17 — the whole printed object listing, pages 8 to 25, matches the 1962 print byte for byte, and the target is retired; B8, the diagnostics, done 2026-08-28 | `test/goldens/90.05-payroll.storage-map`, `test/fixtures/90.05-object-code-notes.md` |
| M4 stage 3 — the object deck and the loader | Done 2026-08-30: the deck writer, our loader, `--emit-deck` and `--emit-loader`, and the object golden grown to the whole of PDF pp. 198–216 | `docs/design/loader.md`, `lib/src/loader/` |
| M4 stage 4, M5, M6 | Not started | — |
| M4 emulator core (early, 43 harvested opcodes) | Draft (PR #10); hardens in M4 stage 4 | `lib/src/emulator/` |
| T1 deck CLI (`deckconv`) | Done 2026-08-03 | `bin/deckconv.dart` |
| T2 VS Code punchcard editor | Done 2026-08-03 (PR #9) | `editors/vscode-punchcard/` |
| T3 MCP server and skill | Done 2026-08-03 (PR #8) | `bin/deckmcp.dart`, `.claude/skills/comtran-decks/` |
| T4 deck syntax highlighting | Done 2026-08-03 (PR #14) | `editors/vscode-punchcard/` |
| W1 to W4, the public website | W1 merged 2026-08-10 (PR #91) and deployed from `.github/workflows/pages.yml`; W2 to W4 not started | The web track below |

The last M0 deferral closed 2026-08-04. **D4.1** part (d), the MOVPAK
round-step emission rule, is locked by Jack's call: a SET store through a
step-list package rounds, a MOVE store truncates.

Test baseline: 1177 Dart tests pass, measured 2026-08-30, and 154 extension
tests pass, measured 2026-08-06. Both suites must stay green; re-measure the
counts, do not trust them.
`dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctd` compiles the
manual's own payroll sample through the front end, the parser, and the
semantic layer. The job deck is the 293-card artifact plus one reconstructed
*FINISH card (D11.3); the raw artifact alone is an incomplete job and draws
message 132. The compile prints the listing, numbered 1,00 to 229,00 exactly
as the 1962 compile numbered it, with zero diagnostics. Under `--pedantic` it
draws exactly three non-historical 943 notes, the sample's own doubtful
blank-moves (D11.4 as amended). A golden test guards the default listing byte
for byte.

## The next task — M4 stage 4

**M4 stage 3 is complete (2026-08-30).** The deck writer punches the
`*FILE` and `*SPEC` cards, `*CTEXT`, the text section and `*CTEND`
(LD-1; LD-2); our loader reads the deck back and places it at a chosen
origin (LD-3); `--emit-object` prints the loader-card page and the
closing lines, so the object golden is the whole of PDF pp. 198 to 216
(LD-4). `docs/design/loader.md` holds the decisions. The next task is
stage 4, the machine assembly (M4-17): the dispatch layer, the compute
handlers, and execution tests for I/O-free programs. Its oracles are the
per-handler D0.3 contract tests and end-to-end runs of constructed decks
with storage assertions. Two items wait for it:

- the loader returns the words by address; stage 4 writes them into
  `MachineState` and enters at the entry point (LD-3);
- a labeled PROGRAM.START does not yet name the entry point: the
  end-of-text entry names `GN)000` for every program (D2.1; LD-3).

`lib/src/codegen/` holds the text model (M4-3), the
program image (M4-4), the object-listing writer (M4-7; M4-8), the
`--emit-code` and `--emit-object` dumps (M4-19; M4-8), the encode
table (`encode.dart`), and the generator itself (`procedure.dart`,
`pool.dart`, `blocks.dart`). The generator fills every word of the
object program: the procedure text, the block words, the constant
pool, and the end-of-text line. `lib/src/loader/` holds the control
cards (LD-1), the deck writer (LD-2) and the loader (LD-3);
`lib/src/emit/emit_deck.dart` holds the `--emit-deck` and
`--emit-loader` dumps.

The golden `test/goldens/90.05-payroll.storage-map` is now the whole
printed document, pages 8 to 25 at the head's margin, and it is the
oracle of record. B7 matched it against the scan-verified target byte
for byte: every head, blank, header and content line, all 977 content
rows and every CNTRL value. It then deleted the target, its generator,
and the spine test that carried chunks B1 to B6.

Stage 2 generates the core-verb text and the full symbolic listing.
Its oracle is the full listing diff, byte for byte, after the blind
scan verification pass (M4-8; the M3-22 pattern). Both have run: the
scan pass closed Phase A, and the pp. 199–216 diff ran clean at B7.
Page 198, the loader-card page, landed at stage 3 (LD-4).

Stage 2 is chunked, by Jack's call of 2026-08-09, so a usage limit costs
one chunk and not the stage. Phase A builds and verifies the target
listing before any generator runs. Phase B generates, and it sizes every
unit in the program before it fills any word. `docs/design/m4-codegen.md`
M4-1 as amended holds the chunks, A0 to A8 and B1 to B8; M4-8 as amended
holds the verify-first order. The target itself is retired (B7).

**Phase A is complete, and Phase B's chunks B1 to B7 are done.** All
eighteen object pages are scan-verified, the B1 generator reproduces the
listing's whole address spine, B2 fills the columns of the MOVE sites
and the guards, B3 fills the columns of the arithmetic, B4 fills
the columns of the eleven comparison sites, their skip vectors, and
the THEN-arm join transfers, B5 fills the transfer and call
sites, and B6 fills the input-output frames and STOP RUN. The
catalogue that drove the sizing is
`test/fixtures/90.05-object-code-notes.md`; the RS) reservation is
pinned as constants of the sample by Jack's ruling of 2026-08-15 (M4-4
as amended; the chunk B1 review record).

B2 added six rules to M4-9: the encode table, the guard's use-point
placement, the lowest-free-register allocation, the CORRESPONDING
emission order, the two-factor `LDQ` selection, and five refusals. Two of
them are underdetermined by the one sample program, and the record
`review/2026-08-16-m4-b2-underdetermined` holds the rejected
formulations.

B3 added six rules to M4-10: the AC-or-MQ register a value sits in, the
result-storage cell number, the section-by-section addressing of M4-4's
reserved cells, the unrecovered `+0` suffix, the ADD CORRESPONDING target
reversal, and the edited-source convert. It also records the
`RIR`/`SIR`/`RFT` word form, folds two subscript facts into M4-10's own
subscript bullet, and adds five more refusals. Three of the six are
underdetermined, and the record
`review/2026-08-16-m4-b3-underdetermined` holds the rejected
formulations.

B4 added six rules to M4-11, and six refusals. The rules:

- the three-word zero build,
- the extraction shift distance,
- the spill cell,
- the spill's outcome mirror,
- the subscripted comparand's prologue,
- and the truth function's false target.

Two of the six rules are underdetermined,
and the record `review/2026-08-16-m4-b4-underdetermined` holds the
rejected formulations.

B5 filled the transfer and call sites:

- the GO TO transfers;
- the return cells;
- the terminal returns;
- the plain DO calls, the AT END forms included;
- the DO FOR loop with its two interleaved EQU lines.

The amendments to M4-12 and M4-13 add three print rules and twelve
refusals; messages 127, 128, 188 and 108 stand in front of three of
the refusals.
The B5 spine counts were 840 symbolic and 834 octal.

B6 filled the last bare-sized sites:

- the OPEN ALL and CLOSE ALL calls;
- the four GET frames, statement stamps included (M4-14);
- the eight FILE calls, the located self-patching pair included;
- the STOP RUN close-down.

The amendments to M4-14 and M4-15 record fourteen more refusals;
messages 16, 19 and 11 stand in front of four of them. The spine
counts rose to 900 symbolic and 894 octal.

B7 closed the stage's print work: every control group under M4-16's
class rule, the `USE 2` and `BL)` pointer words, the 62 constant-pool
words, the end-of-text line, and the paginated writer behind
`--emit-object`. The acceptance diff ran clean — the whole document
against the target, byte for byte — and the target, its generator and
its tests are deleted.

B8 closed the stage with the generator's diagnostics (M4-18). The
generator takes the job's sink and stops on a severity 5 like every
earlier phase (M4-2; D10.2): no text and no image, and the rows
recorded before the stop print. Msg 942 counts the eight generated
classes with the programmer names in one tally, continued across the
resolver, the allocator and the generator (M4-5 as amended). Msg 172
counts the constant pool, seeds included (D9.7). Under `--pedantic`,
msg 946 notes constant DO FOR parameters that never step from p to r
under the decoded exit (D5.1). Msg 947 notes a DO that can re-enter a
procedure open around it (D5.7). The sample draws neither. Seven of
the chunk's calls are underdetermined by the one sample program. The
record `review/2026-08-28-m4-b8-underdetermined` holds the rejected
formulations.

Chunks A7 and A8 read each page **twice**, by two readers who did not know of each
other, and compared the two readings before either met the target. Ten
readers ran at once, over the five pages of chunks A7 and A8 together, at
2.45M tokens and 43 minutes of wall clock for the ten. One page therefore
costs about 245k tokens, which matches the 250k measured over chunk A5,
and reading it twice costs twice that and no more wall clock. The five
pages returned zero disagreements between paired readers, over 261 content
lines.

**With every page verified, the location column was walked end to end**, a
check no page reader could run. The three location counters hold 1021 words
with no gap: counter 0 runs 00000 to 01620 for 913 words, counter 1 runs
01621 to 01771 for 105, and counter 2 runs 01666 to 01670 for 3, written
over the top of the `BL)` block. Counter 1's 105 words are exactly
`RS)` 30 plus `TS)` 7 plus `BL)` 3 plus `PI)` 3 plus `CP)` 62.
`test/fixtures/90.05-object-listing-notes.md` holds the walk and the four
print forms it has to model.

Give each reader its own scratch directory: two of chunk A4's ran at
once, shared one, and collided over a working file.
`test/fixtures/90.05-object-listing-notes.md` records it, in the section
on the chunk A4 flaw. Chunks A5 to A8 gave every concurrent reader its own
directory and none collided.

What stage 2 had to add beyond the verb generators, with each item's
state:

- The two head rows stage 1 could not compute, `USE 1` and
  `BGN 2,PI)1`. Both carry Location Counter 1's origin, which follows
  the procedure text (M4-7.1). Done (B1).
- The four block sizes stage 1 leaves empty: result storage, temporary
  storage, the positional indicators, and the constant pool. The verb
  generators size three of them. Stage 1 derives `BL)` alone, and gets
  the sample's attested 3 (M4-4 as amended). **`TS)` has no rule and will
  not get one.** Jack ruled on 2026-08-10 that it takes the attested 7 as
  a constant, after an eleven-agent hunt over both manuals refuted seven
  readings and left two that one sample cannot separate. M4-4 as amended
  holds the reasoning and forbids inventing a rule that returns 7. All
  four sizes enter `blockWords` together in chunk B1, because
  `ProgramImage.originOf` sums the blocks ahead of its argument and
  sizing one alone moves every origin below it. Done (B1).

  The hunt is worth not repeating. Its central negatives: no word of the
  object program addresses any of the seven cells, which refutes
  demand-driven sizing; over-reservation tracks how well [J 90.02]
  documents each rule, so `PI)` uses all 3 of its words, `RS)` 5 of its
  30, and `TS)` none of its 7; and the `BSS` operand counts words rather
  than items, since `RS)` cell 0 sits at 01621 and cell 1 at 01623, so
  matching sevens of anything against it is doubly ungrounded. Two
  coincidence-grade sevens exist and are recorded as coincidences: the
  program declares seven files, and it has six sections. **Do not
  commission more scan work on this.** PDF p. 215 has been read
  independently twice and both readers print `TS) BSS 7`; the ink is not
  in doubt and the rule is not on the page. Only the storage map of a
  second compiled listing settles it.
- The page furniture: the per-page blank counts. The page head and the
  `LOC OCTAL CNTRL SYMBOLIC` column header are measured to the byte and
  pinned (M4-8 as amended 2026-08-09). The head is the source listing's
  own head, so stage 2 calls the existing builder in
  `lib/src/listing/listing.dart`. Done (B7).
- The later-pass GN allocation rule (GN)084 on). Stage 2 pins it
  instruction by instruction during the listing diff (M4-6). A design
  that assumes a dense counter is wrong by construction. Done (B1;
  M4-6 as amended holds the three fitted placements).
- Msg 942 widens to the eight generated-name classes with one combined
  tally (M4-5). Ids 946 and 947 are reserved for the D5.1 and D5.7
  pedantic sites, pedantic-only at C1 and C2 (M4-18); D6.1 to D6.5 stay
  deferred to M5 (D11.4). Done (B8).
- The emit surface gains `--emit-deck` (`-d`) and `--emit-loader` (`-L`)
  at stage 3, under `emit-stages.md`'s conventions, which M4-19 adopts
  unamended. Done (stage 3, 2026-08-30).

## Rules that bind future work

The definition's
[Sources and authority](definition/README.md#sources-and-authority)
section is the one home for three facts: the F/J authority rule, the fidelity
conventions, and the citation style. Read them there. This list holds only what
binds work outside the definition.

- **J28-6169 outranks F28-8043** wherever they diverge.
- §8.5 and Open Questions are living lists. Annotate an entry in place with the
  evidence and the date. Never delete an entry.
- The definition stays design-free. Compiler design goes in `docs/design/`.
- The conversions stay read-only. A change needs Jack's explicit
  authorization. **One candidate is open, since 2026-08-30:** the
  transcription of PDF p. 198 reads `*SPEC  05` on its twelfth card,
  file 6's, where the scan reads `06` — the `*FILE  06` line above it
  prints the same weak-topped 6 (`docs/design/loader.md` LD-4; the
  review record of 2026-08-30 holds the crop). Jack's call of 2026-08-09 took
  option B: each chunk authorizes its own pages as it lands, and no set
  waits for the end of the scan pass. Chunks A2 to A4 measured seven
  object pages that print more blank lines between the head and the first
  content line than the conversion held. Listing pages 9 to 13 and 21 —
  PDF pp. 200 to 204 and 212 — print two where it held one, and listing
  page 8, PDF p. 199, prints three.
  `test/fixtures/90.05-object-listing-notes.md` holds each measurement,
  and its section on what the seven pages share holds the frame: 57 line
  slots below the head, whatever furniture the page prints.
  Chunk A5 measured three more, on 2026-08-10, under the same option B:
  listing pages 14 to 16, PDF pp. 205 to 207, each printing two blanks
  where the conversion held one. Their 165 content lines carry no content
  correction between them.

  **Chunk A6 brought the first content correction of the scan pass, and
  Jack authorized it on 2026-08-10.** Listing page 19, PDF p. 210, prints
  55 content lines where the conversion held 54. The label
  `WITHOLDING.TAX.ROUTINE` is 22 characters and overruns a label field that
  ends at print column 48, so the printer put its instruction, `AXT 0`, on
  the next line, at the ordinary mnemonic and operand columns. The
  conversion had recorded the two printed lines as one. His ruling:
  fidelity to the print governs, so the conversion carries two lines.
  `test/fixtures/90.05-object-listing-notes.md` holds the measurement, and
  the review record on branch `review/2026-08-10-m4s2-chunk-a6` holds the
  plates. It is the only site of its kind in the eighteen pages: three
  other labels reach the mnemonic column and each stands alone on its
  line. Chunk A6 also corrected the blank count on listing pages 18 and
  19. Listing page 17 already held two, from a 2026-08-05 measurement, and
  its reader measured the same two without knowing that.

  **Chunk A7 measured three more, on 2026-08-10, under the same option B.**
  Listing pages 20, 22 and 23, PDF pp. 211, 213 and 214, each print two
  blanks where the conversion held one, and the conversion now carries all
  three. Their 165 content lines carry no content correction between them,
  and each page was read twice.

  **Chunk A8 closes the pass, on 2026-08-10, under the same option B.**
  Listing pages 24 and 25, PDF pp. 215 and 216, each print two blanks where
  the conversion held one, and the conversion now carries both. Their 103
  content lines carry no content correction. All eighteen object pages are
  measured, and the conversion holds no page at the one blank it held on
  every page before the pass.

  Chunk A8 also measured the three closing lines of the listing, which no
  earlier page could carry.
  `THE LAST LOADER CONTROL CARD PUNCHED IS` prints six columns left of the
  location column and `DONE` prints five columns left of it, while the
  `*CTEND` card prints at it. **This is not an erratum candidate.** The
  conversion renders all three at the location column, and its left margins
  are documented non-facts (M1-15), so a flattened offset is nothing to
  correct. `docs/design/m4-codegen.md` M4-8 as amended carries the measured
  columns; the golden ends at the end-of-text line, and the stage-3 deck
  writer takes the trailer geometry from that entry.

  Twenty-nine corrections are authorized and
  applied. The most recent two, on 2026-08-10, are chunk A8's blank counts;
  the three before those are chunk A7's blank counts, also 2026-08-10; the three before those are chunk A6's two blank counts and its
  one content correction, also 2026-08-10; the three before those are chunk
  A5's object-page blank counts, also 2026-08-10; the seven before those,
  on 2026-08-09, are the
  object-page blank counts above. The eleventh, also on 2026-08-09, corrected the
  object listing's
  column header on line 674, the only such header in the file. It held
  `LOC` at 0, `OCTAL` at 11, `CNTRL` at 26 and `SYMBOLIC` at 54; PDF
  p. 199 measures 1, 12, 25 and 58, and `docs/design/m4-codegen.md` M4-8
  as amended holds the measurement. The tenth, also on 2026-08-09,
  corrected the spacing of all 25
  page heads, which held four different spacings and no one of them the
  print's. Five page scans measure the true columns and
  `docs/design/m1-front-end.md` M1-16 as amended holds them, with the four
  spacings the conversion had. The left margin is deliberately left
  flattened, so an absolute column still must not be read out of the
  transcription. The ninth, on 2026-08-05, corrected word spacing at two sites in statement
  193, after `ERRORTYPE,` and after `DAT`, where the print and the deck both
  hold two spaces and the conversion held one. A card-by-card comparison of the
  deck against the conversion found them, and
  `test/fixtures/90.05-payroll-deck-notes.md` item 4 holds the measurements and
  the scope of that comparison. It changed no golden and no test, because the
  deck was already right. The eighth, also on 2026-08-05, corrected word
  spacing at six sites in the 90.05
  listing — statements 182, 187, 198, 199 and 220, recorded with the
  measurements in `test/fixtures/90.05-payroll-deck-notes.md` item 3. A
  seventh site in that item corrected the deck instead: the print holds one
  space after `SPECIFPAYFILE,` in statement 182 and the deck held two, so the
  card was one column out of true from `UNIT1` rightward, and
  `test/goldens/90.05-payroll.listing` was regenerated. The [J 02.05.05] chart's
  Edited-row overpunch glyphs, where the scan marks all four, were corrected
  2026-08-04; §8.5.8-b records the reading and the polarity order. Six more
  were corrected 2026-08-05: the `*CTEND` card's date (§8.5.8-j), statement
  43,00's 15-character name and statement 203's `1.5 -20)` (deck notes items 1
  and 2), the PDF p. 197 half-line stagger (`docs/design/m1-front-end.md`
  M1-14), `CLA 5)NETPAY` at LOC 01612, the PDF p. 208 transposed page head
  (`docs/design/m4-codegen.md` M4-20 items b and e), and the spacing of both
  compiler-punched control-card lines, `*CTEXT` (PDF p. 198) and `*CTEND`
  (PDF p. 216). That last one landed after Jack reviewed the measurement: the
  print puts the time value at card column 45, `CT` at 55 and the sequence
  number at 79, where the transcription had 43, 50 and 78, and column 55 is
  where the manual's own layout for these two cards starts the secondary
  identifier ([J 03.02.09]).
- `test/deck_conversion_test.dart` holds the deck and the conversion
  consistent. It compares the blank runs of all 112 Environment and Procedure
  cards against the printed listing. It is a regression gate, and it is not
  evidence: both artifacts derive from one scanned copy, so agreement between
  them is not corroboration (`docs/opportunities.md`, O1).
- The page scans (`comtran-manuals/*/images/page-NNN.png`) are ground truth for
  any disputed reading.
- For any claim about card columns, measure the page scan. Never trust the
  indentation of a transcription.

## Residual caveats (honest confidence)

- Every §8.5 "Resolution" is a labeled judgment call. It is a default to design
  against, not a fact.
- Per-message severity values (§8.4) are unrecoverable. Every value we assign
  is our own design decision (Open Question 65). See
  `docs/design/severity-notes.md`.
- Four of the five collating specials carry period-confirmed names. "Lozenge"
  remains an inference (§8.5.8). The Q26 and Q28 residuals are annotated in
  place.
- Two things never got a further independent pass: the prose-claim citations
  beyond the verified sample, and the original build's approximately 120
  correction edits. The risk is low but not zero.

## The mission: the compiler — roadmap

The first concrete task is done. The 90.05 sample deck is re-keyed as
`test/fixtures/90.05-payroll.ct` (2026-08-02): 293 cards, program lines only, with
every column layout measured from the page scans line by line.
`test/fixtures/90.05-payroll-deck-notes.md` holds the provenance, the layout facts, the
reconstruction decisions, and the residual one-space caveats. This deck is the
only surviving COMTRAN program with known-correct output — the printed report,
PDF p. 217. It makes every milestone below testable at once.

- **M0 — Commitments** (`docs/design/decisions.md`) — **DONE 2026-08-02.** The
  D0 slate is locked:
  - The target language is J.
  - The implementation language is Dart.
  - The backend emits real 7090 object code, and our own emulator runs it. The
    SYS) and IOC) runtime is emulated at a high level.
  - Bit-faithfulness is bounded by the evidence.
  - Decks are canonical at punch level, with generated text mirrors.
  - The codegen oracle is the diff against the 1962 listing.

  D1–D9 record the §8.5 walk and the §8.4 conformance and severity decisions.
  Each record was drafted, adversarially verified, and repaired. Jack's own
  calls are recorded in place: PATTERN (bind the rules now, adopt the syntax at
  M5), `deck.name` blanks (accept silently; `--pedantic` warns), and table
  capacities (hard-enforce the printed numbers).
- **M1 — Card reader, lexer, listing — DONE 2026-08-03.** It delivers:
  - the deck splitter — control cards and division headers;
  - the free-form procedure scanner — sentences, labels, literals, and the
    D9.10 character gate;
  - the fixed-form data and environment scanners — entry and specification
    assembly by column 72, name compression, and field checks;
  - the tagged reserved-word tables (D1.5);
  - statement numbering — one number per sentence, entry, or specification,
    continuous across the divisions;
  - the listing — measured 1962 geometry, with the diagnostics as a
    statement-number-referenced block.

  The 90.05 deck scans clean: 172 + 14 + 43 statements, zero diagnostics, and
  the golden listing is committed. M1's own decisions:
  `docs/design/m1-front-end.md`.
- **M2 — Parser and diagnostics — DONE 2026-08-03.** All three divisions plus
  the control cards, with statement numbers of the full `n,cc` form and the
  90.04 message catalog as the diagnostic vocabulary. Stage 3 added the job
  stream — the `lib/src/driver/` splitter and job loop, one listing per job,
  message 132, the D11 records — and the `--pedantic` flag with its eleven
  M2 sites (D11.4). M2's own decisions: `docs/design/m2-parser.md` and the
  D11 section of `docs/design/decisions.md`.
- **M3 — Data Description semantics — DONE 2026-08-05**: levels, pictorials,
  type codes, storage mapping (definition §3, corroborated by the 90.05 layout
  evidence), REDEF, QUANTITY, the dictionary and name resolution, and the
  listing's GN)nnn and LOC columns. M3's own decisions:
  `docs/design/m3-data.md`.
- **M4 — Core-verb code generation** (stage 1 done 2026-08-05, the
  assembly model and the storage-map print): MOVE, SET, IF, WHEN, GO TO, and DO. DO
  follows the verified Q40 return-cell semantics, non-reentrancy included.
  Arithmetic follows §4.3 and the Q26–Q28 annotations. The emulator core
  (`docs/design/emulator.md`) hardens here. The msg 942 dictionary counter
  took the compiler-generated names at stage 2, chunk B8: [J 90.01.05]
  item a) counts them with the programmer names (M3-21; M4-5).
- **M5 — I/O runtime**: OPEN, CLOSE, GET, and FILE; buffering and locate mode;
  AT END and ON ERROR per Q41; labels per Q45 and Q46 at the M0-chosen fidelity;
  DISPLAY and report output.
- **M6 — Acceptance**: compile and run the 90.05 payroll sample end to end, and
  reproduce its printed report output (PDF p. 217). Then take a second corpus —
  F's payroll example with the documented F/J divergences applied (§9.8).
- **Parked, unscheduled — the dangling-continuation diagnostic.** The Data
  and Environment scanners accept a dangling continuation in silence: a
  punched column 72 on a division's last card draws no diagnostic
  (`continuationGroups`, `lib/src/lexer/source_card.dart`). The Procedure
  scanner reports its analogue under D9.4. Give the other two scanners the
  same treatment. The manuals are silent on the error case, so the message
  id and severity are Jack's call at pickup.

## Parallel tooling track

The tooling track shares the compiler's card-image core. It blocks nothing in
M2 to M6.

- **T1 — Deck CLI** (`deckconv`) — **DONE 2026-08-03.** It converts canon to
  text mirror and back, regenerates mirrors, and checks freshness. It is wired
  as the pre-commit hook (`.githooks/`), the CI freshness step, and the git
  textconv driver. `docs/design/deck-format.md` holds the setup.
- **T2 — VS Code punchcard editor** — **DONE 2026-08-03** (PR #9). A custom
  binary editor for `*.ctd` in `editors/vscode-punchcard/`: punch grid,
  interpreted Set H row, field rulers, and click- or type-to-punch editing.
  To install it, package the `.vsix` and run
  `code --profile <name> --install-extension`. The profile matters.
  Amended 2026-08-05: saving either file of a pair keeps both fresh. A
  deck save runs `deckconv regen`; a mirror save runs `deckconv to-canon`
  (D0.5 as amended; `docs/design/deck-format.md` §6).
- **T3 — MCP server and skill** — **DONE 2026-08-03** (PR #8).
  `bin/deckmcp.dart` serves five deck tools on the official Dart MCP SDK. The
  `.claude/skills/comtran-decks` skill documents the deck workflow.
- **T4 — Deck syntax highlighting** — **DONE 2026-08-03** (PR #14). Both deck
  views color the card fields from one shared column table
  (`editors/vscode-punchcard/src/columns.ts`).
  - A `comtran-deck` language contribution colors `.ct` mirrors from a
    **generated** TextMate grammar (`npm run grammar`; a freshness test guards
    the committed file): column fields, literals, the period-blank terminator
    with its commentary scoped as comment, `!` punch lines, and header and
    control cards. Begin and end regions opened by the header lines track the
    division context, so no semantic-token provider was needed.
  - The punchcard editor's card-list pane colors the same fields. It classifies
    every card with the compiler's deck-splitting rules. The field ruler and the
    status line follow the current card's division.
  - Known limit: a literal that continues across cards highlights per line.

## Parallel web track

*Recorded 2026-08-10, from a requirement Jack stated. The phases, the cuts and
the risk below are recommendations. Jack has approved none of them. W1 gets a
design record in `docs/design/` when it starts; this section is the roadmap
entry only.*

The web track builds a public website. Jack asked for three things: a front
page that compiles a program and shows how the compiler works, a tutorial page,
and a documents page that holds the language reference, the manual pages and
their scans. Claude Design does the interface design.

### What the track is for

The site is the reviewer access this project cannot supply any other way.
`docs/opportunities.md` O7 wants an independent domain expert, and it names
its own blocker: something readable for a reviewer to react to. O4 wants one
reproducibility entry point. A browser that compiles the 1962 sample and prints
the 1962 listing is the strongest form of both. **It is not an adoption play.
R3 still stands: count no stars, forks or visitors.**

### Why the track is cheap

The compiler already runs in a browser. Only three of the 63 files in
`lib/src/` import `dart:io` — `cards/deck_files.dart` and the two `mcp/` files
— and the compile path touches none of them. A probe on 2026-08-10 compiled the
front end, the parser, the semantic layer and the listing to 250 KB of
JavaScript in 1.08 seconds. That bundle read the 90.05 mirror text and printed
the listing, and its 21,865 bytes are identical to
`test/goldens/90.05-payroll.listing`. The site needs no server and no sandbox.

**Amended 2026-08-10, when W1 built the other four stage dumps.** The probe
above checked the listing only, and the listing holds no machine word. A Dart
`int` compiled to JavaScript is a double, and its bitwise operators truncate to
32 bits, so the JavaScript build drops the top four bits of every packed 36-bit
word with no error of any kind: the semantics dump prints `006060606060` where
the machine held `606060606060`. The listing, cards, scan and parse dumps are
unaffected, which is why the probe passed.

**The site therefore compiles to WebAssembly, not to JavaScript.** A WasmGC
`int` is a true 64-bit integer, and the wasm build reproduces all six goldens
byte for byte, in 246 KB, faster than the JavaScript build ran. One cost
follows: a browser will not fetch a WebAssembly module from a `file://` URL, so
the page needs a static server, and a local check needs one too. Any later
browser work inherits this finding, the M4 emulator most of all.

The probe imported the `lib/src/` libraries one by one. `lib/comtran.dart`
exports `deck_files.dart`, so a web entrypoint cannot use the barrel. W1 either
imports the libraries directly or splits the barrel in two.

`editors/vscode-punchcard/media/punchcard.js` is already a browser punch grid,
in 793 lines with 11 references to the editor API. W1 ports it. The column
table `editors/vscode-punchcard/src/columns.ts` moves with it.

### The rule that keeps it cheap

**The site holds no compiler knowledge.** It calls the compiled compiler, and
it prints what the compiler returns. Each milestone then upgrades the site with
no website work: M4 stage 2 fills the object-code panel, and M6 fills the run
output. A site that knows the stages itself pays for every milestone twice.

Two consequences bind the work:

- A structured emit surface, such as source spans in JSON, is a compiler
  change. It needs an amendment to `docs/design/emit-stages.md`, and it must
  land in the milestone that also lands the site code that reads it. Section 11
  of `CLAUDE.md` bans it otherwise. W1 reads the present text dumps.
- The site takes the language reference from `docs/definition/`, which
  `tool/generate_definition_mirror.dart` generates. It never holds a third
  copy. The `.ct` mirror problem is the precedent.

**The site lives in this repository, under `web/`. Jack's call, 2026-08-10.**
The extension already brought npm into CI, so the precedent holds, and the
site's content is generated from this repository.

### The copy

The site copy does not follow Simplified Technical English.
`docs/design/web-copy.md` holds its register and its rules, and section 13 of
`CLAUDE.md` records the exemption. Two facts from that record bind the whole
track: where simple and precise collide, the site chooses simple and links the
repository artifact; and no simplification ever hides the difference between
what a manual states and what this project decided.

### Hosting

**GitHub Pages, from a GitHub Actions build. Jack's call, 2026-08-10.** It
costs nothing, and it cannot cost anything: Pages has no paid tier, so a site
above a limit draws an email from GitHub and never a charge. The published site
is about 75 MB against the 1 GB limit. A visitor who compiles a program and
reads a few manual pages pulls under 1 MB. The measurements behind that: the
compiler bundle is 250 KB, and the 345 page scans average 171 KB each, with the
largest at 323 KB.

**The build deploys the site. Nobody commits it.** Two reasons hold that rule.
A branch deploy copies 58 MB of page scans into git beside the copies already
there. And the site's content is generated, so the Actions build runs
`dart compile js` and `tool/generate_definition_mirror.dart`, and the site
cannot drift from the compiler. The `.ct` mirrors already follow this rule. The
build also needs `.nojekyll`, or Jekyll mishandles the scans.

**The deploy workflow, written 2026-08-10** (`.github/workflows/pages.yml`,
branch `w1-site`). It runs on a push to master and on demand, and it takes
five steps: `dart pub get`, `dart test`, `dart run tool/build_web.dart`,
`actions/upload-pages-artifact` over `web/`, and `actions/deploy-pages`. Four
notes on the shape:

- The test run is the gate. The site's whole claim is the byte-for-byte
  listing, and the golden test is what proves it, so nothing publishes without
  it. Format and lint stay in CI: a style failure must not stop a correct site.
- No path filter guards the workflow. The site prints what the compiler
  prints, so every push to master must redeploy.
- Jekyll never runs on a workflow artifact, which is served as uploaded. The
  build writes `.nojekyll` anyway, as a guard if the source ever moves back to
  a branch.
- CI now also runs `dart run tool/build_web.dart`. The site is built and never
  committed, so before this nothing proved that it compiles.

**The site is live. Done 2026-08-10.** Jack set the Pages source to GitHub
Actions. Three deploys have run since the W1 merge and all three succeeded.
The site is at `https://screendead.github.io/comtran-compiler/`, and that
address serves both the page and the WebAssembly module. The domain ruling
below moves it.

**Verified from a subpath on 2026-08-10**, because a project-page URL carries
one. Served under `/web/`, the WebAssembly module loads, both pages find their
styles and their four crops, no request 404s, and the listing panel holds
21,865 bytes that hash to the golden. The page fetches the module and hands
the bytes to `compile`, so the `Content-Type` of `.wasm` on the host never
matters.

Cloudflare Pages is the recorded escape hatch, if the bandwidth ever matters.
Its free tier sets no bandwidth cap, and it reads a `_headers` file, which
Pages does not. The artifact is the same, so the move costs about a day.

**The project takes a custom domain. Jack's call, 2026-08-10, and he sets it
up himself.** The likely address is `comtran.screendead.com`. He gave no
date. A custom domain costs about £10 each year, and a `github.io` address
breaks if the account is ever renamed. M6, the Zenodo deposit under O5 and
the report under O9 are the reasons to hold a stable URL.

Two things wait on that work, and this project has done neither:

- The subdomain needs a DNS record that points at `screendead.github.io`.
- Find out whether an Actions deploy also needs a `CNAME` file in the
  artifact. `tool/build_web.dart` writes `.nojekyll` and no `CNAME`. Nobody
  here has tested a custom domain against a workflow deploy, so treat the
  answer as unverified until the deploy proves it.

One consequence binds this repository, and only after the move. Every link
that names the old address becomes a redirect. Search the repository for
`screendead.github.io` at that point, and change what it finds.

### The phases

**W1 — the compiler in the browser.** Blocked on nothing. It delivers:

- the web entrypoint and the JavaScript bundle;
- one card editor, in two views: the deck text, and the punch grid of the
  selected card;
- the listing panel, in the measured 1962 geometry;
- the 90.05 sample on one click;
- the diff against `test/goldens/90.05-payroll.listing`, which shows that the
  browser output and the 1962 print agree byte for byte;
- a deck download as `.ctd`, and a share link that carries the deck;
- **the limits, on the page.** `docs/design/web-copy.md` §5 names the three
  statements. This is a requirement of W1, not an addition to it.

**W1, as built on 2026-08-10** (branch `w1-site`, `web/README.md`). It
delivers the entry point and the WebAssembly build; one card editor with a
column ruler and a card-number gutter; the punch grid of the card under the
cursor, drawn from the punch codes the compiler holds; all six `--emit` dumps
as selectable panels, each with a caption that says what attests it; the 90.05
sample on one click, and on load; and the three §5 statements in the reader's
path. Every stage and the punch grid are held to their goldens by
`test/web_compile_test.dart`, in the normal `dart test` gate.

The punch grid did not need the port this section expected.
`editors/vscode-punchcard/media/punchcard.js` stayed where it is: the site asks
the compiler for the twelve rows and prints them, which keeps the punch codes
in one place and leaves the site with no card knowledge of its own.

Three items on the W1 list above are not built: the deck download as `.ctd`,
the share link, and the golden-diff panel. The diff earns its place least: the
site now prints the listing the golden test already compares, and the test is
the stronger claim. The other two stand.

**Amended 2026-08-10.** Two of those three items are now built.

The deck download gives the reader the canon `.ctd` bytes. `canonDeck` in
`lib/src/web/web_compile.dart` encodes them, and `test/web_compile_test.dart`
holds them equal to `test/fixtures/90.05-payroll-job.ctd`, byte for byte. The
site encodes no card itself.

The share link carries the typed deck in the address fragment. It deflates the
deck where the browser has `CompressionStream`, and it writes plain bytes
where the browser does not. A page reads both forms. The site therefore stores
no deck, and it still needs no server. The address drops the link as soon as
the reader changes the deck, because a link that names another deck is false.

The golden-diff panel is the one item left.

**Amended 2026-08-10 at Jack's request.** The punch grid moved above the deck
and became editable: a click cuts or fills one hole, and the deck text becomes
the card that results. The compiler decides what that text is, so a hole
combination no character matches puts the card into the `!` punch form (D0.5)
rather than into an error. The deck also prints the compiler's own diagnostics
under it, the Compile button greys out while the panels already answer to the
typed text, and each run prints how long it took.

**Amended 2026-08-10, after the W1 merge.** Jack asked for two things: no em
dash in the site copy, and a roadmap page. `web/roadmap.html` draws the three
tracks of this file as stations, each marked finished, in progress, or not
started. A finished station carries the date it was finished and links its
design record. An unfinished one carries no date, because this file promises
no schedule and the site must not invent one.

Two rules follow, both in `docs/design/web-copy.md`, and Jack approved both on
2026-08-10. D5 bars the em dash and caps the en dash, which stays legal
because it is his own register. Section H states when a change to the project
obliges a change to a page.
Every push to master deploys, so each H rule binds the same pull request that
makes the change. `test/web_copy_test.dart` enforces D5 across the text files in `web/`, and
checks that the roadmap page carries a station for every codename in the
glossary above. Nothing compares the two states; H2 is the rule that keeps
them in step.

**W2 — the sources.** The documents page. It holds the language reference, both
manual conversions, both source PDFs (17 MB), and each of the 345 page scans
beside its transcription (58 MB; load one page at a time).

**W3 — the stages.** The step-through. The six `--emit-*` dumps become panels,
and the reader selects a statement to mark its part in each one. The join key
is the statement number `n,cc` ([J 02.02.01]): the 1962 compiler numbered the
statements itself and keyed its diagnostics to them, so the site uses the
artifact's own key and invents none. This phase needs the structured emit
surface, under the rule above.

**W4 — teach and run.** The tutorial page, with the W1 editor and no second
editor. The run button waits for M5 and M6, because no program runs before
them.

### Later, and not scheduled

Three entries in `docs/opportunities.md` have the site as their natural home.
Each stays in that file, and none is promised here: the evidence chain from a
generated instruction to its page scan (O8), the archive of decided questions,
built from the review records that already exist as HTML (O11), and the
evidence tier of a rule, shown where the compiler acts on it (O3).

### What the track cuts, and why

| Cut | Reason |
|---|---|
| The run button, before M5 and M6 | Nothing executes yet. Do not build a stub. |
| The tutorial, before W4 | It is writing, and it is the one part no artifact in this repository can generate. |
| A second editor for the tutorial page | Two editors mean two column rules, and two places to get a card column wrong. |
| The choice between the terminal and the punchcard | They are not alternatives. The punch grid shows one input card; the terminal holds the deck text and the compiler output. |

### The risk

The site becomes the most-read document in the project, and its readers never
open this file. A confident site that hides the limits oversells the
reconstruction, and this project's standing rests on doing the opposite. Three
facts go on the site itself, in the reader's way: the reconstruction rests on
one scanned copy of each manual and one reader (O12); every §8.5 resolution is
a labeled judgment call, not a fact; and every per-message severity value is
this project's own decision (Open Question 65).

## Pointers

- Definition: `docs/comtran-language-definition.md` is canon. It is above
  GitHub's 512 KB limit for Markdown, so a browser cannot render it; read it
  in a browser through the generated mirror, `docs/definition/`. Correct
  canon, then run `dart run tool/generate_definition_mirror.dart`.
  §8.3 catalogs the F/J
  divergences and §8.5 the ambiguities. §8.5.8 holds the transcription cautions.
  The Open Questions list at the end of that file is the only place that states
  its own item count and the resolved and narrowed status of each item. Read the
  count there; no other document repeats it.
- Manuals: `comtran-manuals/{F28-8043,J28-6169}/`. `comtran-manuals/README.md`
  holds the conventions. The sample program is
  `comtran-manuals/J28-6169/90.05-sample-program.md`.
- The method: `docs/reconstruction-method.md`. It states how this project
  decides a question when the sources are thin, silent, or in conflict, what
  the method cannot do, and how far large language models did the work
  (section 11, with the human gates that bound them). It describes; it binds
  nothing. `CLAUDE.md`,
  `docs/design/decisions.md` and the definition are the authorities it
  describes, and any disagreement means the method document is stale.
- Improvement candidates: `docs/opportunities.md`. It holds ways to make the
  project stronger as research, ranked, with the rejected ones and their
  reasons. It binds nothing. Read it when the question is "what should we do
  next to raise the project's standing", not "what is the next task".
- Archive provenance: commit 8f619e5 preserves the raw research output
  (`docs/research-2026-08-01-interrupted.md`). The language definition
  supersedes it.
- External period scans used, all from bitsavers and all re-downloadable:
  C28-6100-2 (709/7090 IOCS), 22-6528-4 (7090 reference), A22-6506-0 (705
  reference), 22-6642-0 (705 pocket code card), A24-1403-5 (1401 reference), and
  J28-6166 (9PAC Part 1).

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 12]: ../comtran-manuals/F28-8043/02-language-structure.md#underlying-principles
[J 02.02.01]: ../comtran-manuals/J28-6169/02-compiler.md#b-finish-card
[J 02.05.05]: ../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.07.01]: ../comtran-manuals/J28-6169/02-compiler.md#i-cond-environment-card
[J 03.02.09]: ../comtran-manuals/J28-6169/03-loader.md#j-start-card
[J 90.01.05]: ../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02]: ../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.10]: ../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
