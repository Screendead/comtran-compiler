# COMTRAN compiler — design decisions (M0)

*Created 2026-08-02. This document records the binding design decisions for the
compiler. The language definition (`docs/comtran-language-definition.md`) stays
design-free; design lives here. Each decision carries an ID. Amend a decision by
an explicit edit to this file, never silently. Citation style follows the
definition: (F p. N) / (J xx.xx.xx) / ([J 90.05] listing, PDF p. NNN).*

## Status

- **D0 (top-level slate): locked with Jack, 2026-08-02.**
- **D1–D9 (the §8.5 walk + the §8.4 severity/conformance decisions): recorded
  2026-08-02**, adversarially verified; 84 records. Jack's calls, 2026-08-02:
  PATTERN (D6.1/D9.12 — bind rules now, syntax at M5), deck.name blanks
  (D7.11 — accept silently, --pedantic warns), and table capacities
  (D9.7/D9.6 — hard-enforce the printed numbers) are **resolved**; D4.1
  (MOVPAK round-step emission), deferred 2026-08-02, was **locked by Jack's
  call 2026-08-04**: a SET store through a step-list package rounds, a MOVE
  store truncates. No M0 deferral remains. D4.14 back-fills entry 8.5.4-n,
  which joined the catalog after the walk: Jack's call of 2026-08-04,
  recorded 2026-08-16. The slate now holds 85 records.
- **D10 (correctness-review decisions): recorded 2026-08-03**, during the
  remediation of the 2026-08-03 correctness review.
- **D11 (M2 stage 3, the job stream): recorded 2026-08-03**, before the
  stage-3 implementation. D11.1 amends D10.4 and clarifies D9.14.

## Contents

Every decision carries an ID, and every other document cites it by that ID. This
index holds one row per decision. Each record repeats its status on a
**Status.** line of its own. The four statuses are:

| Status | What it means |
|---|---|
| **Locked** | The record binds the compiler. No amendment stands against it. |
| **Jack's call** | Jack decided the open point. The record carries his dated note, and it binds the same way. |
| **Amended** | A later record, or a later review, changed part of it. The record states the change. |
| **Deferred** | The named part binds nothing yet. The record names the milestone that must decide it. |

Two maintenance rules:

1. Add a row here in the same commit that adds a record.
2. Change a **Status.** line and its row together. They must always agree.

The D0 items are bullets in one section, so their rows point at that section.
Every other row points at its own record.

| Record | Subject | Status |
|---|---|---|
| **[D0 — Top-level slate](#d0--top-level-slate-jacks-calls-locked-2026-08-02)** | Jack's calls, locked 2026-08-02 | |
| [D0.1](#d0--top-level-slate-jacks-calls-locked-2026-08-02) | Target language: J | Locked |
| [D0.2](#d0--top-level-slate-jacks-calls-locked-2026-08-02) | Implementation language: Dart | Locked |
| [D0.3](#d0--top-level-slate-jacks-calls-locked-2026-08-02) | Backend: real 709/7090 object code on our own emulator | Locked |
| [D0.4](#d0--top-level-slate-jacks-calls-locked-2026-08-02) | Fidelity: evidence-bounded bit-faithfulness | Locked |
| [D0.5](#d0--top-level-slate-jacks-calls-locked-2026-08-02) | Canonical formats: card images are canon | Locked |
| [D0.6](#d0--top-level-slate-jacks-calls-locked-2026-08-02) | Character set and collating | Locked |
| [D0.7](#d0--top-level-slate-jacks-calls-locked-2026-08-02) | Files, tape, labels, PATTERN | Locked |
| [D0.8](#d0--top-level-slate-jacks-calls-locked-2026-08-02) | Reconstruction target: the field-test compiler as attested | Locked |
| **[D1 — Lexical (§8.5.1)](#d1--lexical-851)** | | |
| [D1.1](#d11--quotation-mark-inside-a-quoted-constant) | Quotation mark inside a quoted constant | Locked |
| [D1.2](#d12--maximum-numeric-constantliteral-length-under-j) | Maximum numeric constant/literal length under J | Locked |
| [D1.3](#d13--procedure-name-terminating-period) | Procedure-name terminating period | Locked |
| [D1.4](#d14--alphabetic-vs-alphameric-literal) | "Alphabetic" vs "alphameric" literal | Locked |
| [D1.5](#d15--reserved-word-equals) | Reserved word EQUALS | Locked |
| **[D2 — Program structure (§8.5.2)](#d2--program-structure-852)** | | |
| [D2.1](#d21--programstart--an-undocumented-entry-point-facility) | PROGRAM.START — an undocumented entry-point facility | Locked |
| [D2.2](#d22--division-ordering-and-interleaving) | Division ordering and interleaving | Locked |
| [D2.3](#d23--cards-before-the-first-division-header) | Cards before the first division header | Locked |
| [D2.4](#d24--serial-number-sequence-checking) | Serial-number sequence checking | Locked |
| [D2.5](#d25--extent-of-section-scoped-name-uniqueness) | Extent of section-scoped name uniqueness | Locked |
| [D2.6](#d26--column-72-vs-column-71-blank-assumption-on-the-data-form) | Column 72 vs column 71 blank assumption on the data form | Locked |
| [D2.7](#d27--stop-n-bare-stop-and-stop-run) | STOP n, bare STOP., and STOP RUN | Locked |
| **[D3 — Data description (§8.5.3)](#d3--data-description-853)** | | |
| [D3.1](#d31--subscript--quantity-nesting-depth-under-j) | Subscript / quantity-nesting depth under J | Locked |
| [D3.2](#d32--written-form-of-blank-when-zero) | Written form of BLANK WHEN ZERO | Locked |
| [D3.3](#d33--non-format-field) | "Non-format field" | Locked |
| [D3.4](#d34--the-redef-line-name-and-layout) | The REDEF line: name and layout | Locked |
| [D3.5](#d35--highest-level-in-the-justification-default) | "Highest level" in the justification default | Locked |
| [D3.6](#d36--does-the-constants-then-redef-table-technique-survive) | Does the constants-then-REDEF table technique survive? | Locked |
| **[D4 — Arithmetic and data manipulation (§8.5.4)](#d4--arithmetic-and-data-manipulation-854)** | | |
| [D4.1](#d41--rounding-threshold-stated-edge-cases-not) | Rounding: threshold stated, edge cases not | Jack's call (part d) |
| [D4.2](#d42--overflow-with-no-on-overflow-clause) | Overflow with no ON OVERFLOW clause | Locked |
| [D4.3](#d43--invalid-characters-in-a-numeric-field-at-object-time) | Invalid characters in a numeric field at object time | Locked |
| [D4.4](#d44--negation-vs-exponentiation) | Negation vs exponentiation | Locked |
| [D4.5](#d45--parameterfunction-declaration-after-the-removal-of-param-and-funct) | Parameter/function declaration after the removal of PARAM and FUNCT | Locked |
| [D4.6](#d46--figurative-constant-target-maximum-32766-vs-21) | Figurative-constant target maximum: 32766 vs 2¹⁵−1 | Locked |
| [D4.7](#d47--report-field-f--edited-field-j) | "Report field" (F) = "edited field" (J) | Locked |
| [D4.8](#d48--multi-result-set) | Multi-result SET | Locked |
| [D4.9](#d49--edited-source-moved-to-an-alphameric-target) | Edited source moved to an alphameric target | Locked |
| [D4.10](#d410--abc) | A**B**C | Locked |
| [D4.11](#d411--move-blanks-into-editedexternal-fields--doubtful-yet-compiles-clean) | MOVE BLANKS into edited/external fields — "doubtful" yet compiles clean | Amended |
| [D4.12](#d412--corresponding-matching-f-name-only-vs-j-qualifier-chain) | CORRESPONDING matching: F name-only vs J qualifier-chain | Amended |
| [D4.13](#d413--call-non-unique-oldname-and-qualified-synonyms) | CALL: non-unique old.name and qualified synonyms | Locked |
| [D4.14](#d414--integer-against-a-trailing-s-scaled-field) | "Integer" against a trailing-S scaled field | Jack's call |
| **[D5 — Control flow (§8.5.5)](#d5--control-flow-855)** | | |
| [D5.1](#d51--do--for-termination-is-an-equality-test) | DO … FOR termination is an equality test | Locked |
| [D5.2](#d52--two-index-do-indexname1-is-set-to-p1--q1) | Two-index DO: "index.name.1 is set to p.1 + q.1" | Locked |
| [D5.3](#d53--tests-for-not-greater-or-less-conditions-unequal-length-comparison) | "Tests for NOT greater or less conditions" (unequal-length comparison) | Locked |
| [D5.4](#d54--go-to-out-of-a-do-addressed-closed-procedure) | GO TO out of a DO-addressed (closed) procedure | Locked |
| [D5.5](#d55--assigned-go-to-object-time-range-behaviour) | Assigned GO TO: object-time range behaviour | Locked |
| [D5.6](#d56--set-conditionname-under-j) | SET condition.name under J | Locked |
| [D5.7](#d57--nested-and-recursive-do) | Nested and recursive DO | Locked |
| **[D6 — Input/output (§8.5.6)](#d6--inputoutput-856)** | | |
| [D6.1](#d61--the-pattern-option--used-but-never-defined) | The PATTERN option — used but never defined | Jack's call |
| [D6.2](#d62--for-label--labeln-linkage-documented-only-by-a-missing-appendix) | FOR LABEL / LABELN linkage documented only by a missing appendix | Locked |
| [D6.3](#d63--reopening-a-file-after-a-named-close) | Reopening a file after a named CLOSE | Locked |
| [D6.4](#d64--the-printer-as-a-direct-file-target) | The printer as a direct FILE target | Locked |
| [D6.5](#d65--get-on-an-unopened-file-silent-exit-vs-terminate-with-message) | GET on an unopened file: silent exit vs terminate-with-message | Locked |
| [D6.6](#d66--at-end-any-imperative-clause-f-vs-a-single-imperative-statement-only-j) | AT END: "any imperative clause" (F) vs "a single imperative statement only" (J) | Locked |
| [D6.7](#d67--short-record-blocking-and-the-begin-threshold) | Short-record blocking and the BEGIN threshold | Locked |
| **[D7 — Environment, control cards, and processor surface (§8.5.7)](#d7--environment-control-cards-and-processor-surface-857)** | | |
| [D7.1](#d71--spec-blocksize-0-999-vs-environment-maximum-9999) | *SPEC blocksize "(0-999)" vs Environment maximum 9999 | Locked |
| [D7.2](#d72--specif-chks-in-appendix-9008) | "SPECIF CHKS" in Appendix 90.08 | Locked |
| [D7.3](#d73--who-assigns-the-default-buffercount) | Who assigns the default BUFFERCOUNT | Locked |
| [D7.4](#d74--include-placement-at-the-end-of-the-present-program) | INCLUDE placement "at the end of the present program" | Amended |
| [D7.5](#d75--per-message-severity-codes-are-nowhere-specified) | Per-message severity codes are nowhere specified | Locked |
| [D7.6](#d76--severity-limit-was-not-reached) | "SEVERITY LIMIT WAS NOT REACHED" | Locked |
| [D7.7](#d77--internal-table-limits-are-approximate) | Internal-table limits are approximate | Locked |
| [D7.8](#d78--which-environment-types-msg-90-covers) | Which environment types msg 90 covers | Locked |
| [D7.9](#d79--maximum-alphabetic-constant-length) | Maximum alphabetic-constant length | Locked |
| [D7.10](#d710--file-check-table-listed-in-the-deck-format-never-produced) | File Check Table: listed in the deck format, never produced | Locked |
| [D7.11](#d711--deckname-with-imbedded-blanks) | Deck.name with imbedded blanks | Jack's call |
| [D7.12](#d712--compile-vs-cmple) | *COMPILE vs $CMPLE | Locked |
| [D7.13](#d713--statement-number-placement) | Statement-number placement | Amended |
| **[D8 — Transcription and printing artifacts (§8.5.8)](#d8--transcription-and-printing-artifacts-858)** | | |
| [D8.1](#d81--collating-sequence-special-characters--resolved-by-scan-2026-08-01) | Collating-sequence special characters — resolved by scan (2026-08-01) | Locked |
| [D8.2](#d82--external-decimal-row-of-the-j-field-type-chart) | External Decimal row of the J field-type chart | Locked |
| [D8.3](#d83--the-ir999-mode-example--resolved-by-scan) | The "IR999" mode example — resolved by scan | Locked |
| [D8.4](#d84--stray-nj-in-the-input-file-general-form--resolved-by-scan) | Stray "nj." in the Input FILE general form — resolved by scan | Locked |
| [D8.5](#d85--missing-comma-before-recordname2-in-the-input-file-form--print-confirmed-by-scan) | Missing comma before record.name.2 in the Input FILE form — print confirmed by scan | Locked |
| [D8.6](#d86--9008-density-table-sources-both-h-and-l-from-high--print-confirmed-by-scan) | 90.08 density table sources both H and L from "HIGH" — print confirmed by scan | Locked |
| [D8.7](#d87--message-187s-garbled-tail--resolved-by-scan-a-defect-of-the-original-1962-listing-not-the-conversion) | Message 187's garbled tail — resolved by scan: a defect of the original 1962 listing, not the conversion | Locked |
| [D8.8](#d88--900105-item-k--cpnn--prior-conjecture-refuted-by-scan-independently-verified) | 90.01.05 item k `-CP)+NN` — prior conjecture refuted by scan (independently verified) | Locked |
| [D8.9](#d89--cross-reference-errata) | Cross-reference errata | Locked |
| [D8.10](#d810--the-ctend-cards-date-field--transcription-artifact-resolved-by-scan-2026-08-02) | The *CTEND card's date field — transcription artifact, resolved by scan (2026-08-02) | Locked |
| **[D9 — Severity system and conformance list (§8.4)](#d9--severity-system-and-conformance-list-84)** | | |
| [D9.1](#d91--severity-system-b1) | Severity system (B.1) | Locked |
| [D9.2](#d92--severity-assignment-policy-q65) | Severity assignment policy (Q65) | Amended |
| [D9.3](#d93--conformance-list-binding) | Conformance list binding | Locked |
| [D9.4](#d94--b2-msg-62-vs-the-attested-missing-period-leniency) | B.2 msg 62 vs the attested missing-period leniency | Locked |
| [D9.5](#d95--diagnostic-message-realization-substitution-slots-and-listing-format) | Diagnostic message realization: substitution slots and listing format | Locked |
| [D9.6](#d96--message-187-the-garbled-tail) | Message 187: the garbled tail | Jack's call |
| [D9.7](#d97--internal-table-capacity-diagnostics-msgs-148-149-172-177-183-184-200-205) | Internal-table capacity diagnostics (msgs 148, 149, 172, 177, 183, 184, 200-205) | Jack's call |
| [D9.8](#d98--recognized-but-deferred-constructs-msgs-151-180-181-110-90) | Recognized-but-deferred constructs (msgs 151, 180, 181, 110, 90) | Locked |
| [D9.9](#d99--figurative-constant-target-ceiling-32766-or-32767) | Figurative-constant target ceiling: 32766 or 32767 | Locked |
| [D9.10](#d910--message-134-what-counts-as-an-illegal-character) | Message 134: what counts as an illegal character | Locked |
| [D9.11](#d911--advisory-diagnostics-with-unrecoverable-trigger-criteria-msgs-170-206-86-49-104) | Advisory diagnostics with unrecoverable trigger criteria (msgs 170, 206, 86, 49, 104) | Locked |
| [D9.12](#d912--pattern-rules-with-no-recoverable-syntax-msgs-48-49-50) | PATTERN rules with no recoverable syntax (msgs 48, 49, 50) | Jack's call |
| [D9.13](#d913--system-generated-names-msgs-173-174-against-the-crypt-symbol-rules) | System-generated names (msgs 173, 174) against the CRYPT symbol rules | Locked |
| [D9.14](#d914--job-stream-and-message-132-finish) | Job stream and message 132 (*FINISH) | Locked |
| [D9.15](#d915--compiler-self-diagnostics-disposition-of-msgs-0-18-24-29-69-85-109-124-135-137-140) | Compiler self-diagnostics: disposition of msgs 0, 18, 24, 29, 69, 85, 109, 124, 135-137, 140 | Locked |
| [D9.16](#d916--cond-key-setting-length-msgs-6-7--the-under-length-case) | COND key setting length (msgs 6, 7) — the under-length case | Locked |
| **[D10 — Correctness-review decisions (2026-08-03)](#d10--correctness-review-decisions-2026-08-03)** | | |
| [D10.1](#d101--specif-operand-diagnostics-routing-of-msgs-153-160) | SPECIF operand diagnostics: routing of msgs 153-160 | Locked |
| [D10.2](#d102--the-diagnostic-sink-and-the-severity-5-stop-in-every-phase) | The diagnostic sink and the severity-5 stop in every phase | Locked |
| [D10.3](#d103--numeric-literal-length-what-the-50-character-limit-counts) | Numeric-literal length: what the 50-character limit counts | Locked |
| [D10.4](#d104--compile-control-cards-after-the-first-are-ignored-at-any-deck-position) | Compile control cards after the first are ignored at any deck position | Amended |
| [D10.5](#d105--clause-separator-leniencies-the-parser-accepts-silently) | Clause-separator leniencies the parser accepts silently | Locked |
| [D10.6](#d106--message-917-a-function-argument-that-is-not-a-data-name) | Message 917: a function argument that is not a data-name | Locked |
| [D10.7](#d107--verb-source-operands-the-function-reference-and-the-signed-literal-m2-8-cross-reference) | Verb source operands: the function reference and the signed literal (M2-8 cross-reference) | Locked |
| [D10.8](#d108--data-and-environment-name-bars-the-mandatory-blocksize-and-the-63-file-tally) | Data and environment name bars, the mandatory BLOCKSIZE, and the 63-file tally | Locked |
| **[D11 — M2 stage 3: the job stream (2026-08-03)](#d11--m2-stage-3-the-job-stream-2026-08-03)** | | |
| [D11.1](#d111--the-job-splitter-card-level-job-boundaries) | The job splitter: card-level job boundaries | Locked |
| [D11.2](#d112--per-job-compilation-state-numbering-listings-and-the-exit-code) | Per-job compilation state, numbering, listings, and the exit code | Locked |
| [D11.3](#d113--message-132-at-end-of-input-and-the-9005-job-deck) | Message 132 at end of input, and the 90.05 job deck | Locked |
| [D11.4](#d114--the---pedantic-flag-mechanism-and-the-m2-site-set) | The --pedantic flag: mechanism and the M2 site set | Amended |

## D0 — Top-level slate (Jack's calls, locked 2026-08-02)

**Status.** Every item in this section is locked.
**D0.1 Target language: J.** The implemented language is J28-6169 (January 1962
field-test language). F-only features are documented-but-unimplemented. Where F
and J diverge, J governs (definition §8.3).

**D0.2 Implementation language: Dart.** Chosen for reviewer-auditability (Dart
is Jack's home language) together with Dart 3's sealed class hierarchies,
exhaustive pattern matching, 64-bit integers (sufficient to model 36-bit
words), and test tooling. Code style: a plain, readable subset; golden-file
tests as the primary oracle mechanism.

**D0.3 Backend: real 709/7090 object code, run on our own emulator.**

- The compiler emits 7090 object programs in the documented object deck format
  ([J 90.03]), loaded by our implementation of the CT Loader (J 03, [J 90.03]).
- A word-exact 36-bit 7090 CPU core executes the generated code. Instruction
  semantics come from the period reference manual (external: 22-6528-4).
- The SYS)/IOC) runtime library is **high-level-emulated**: the original
  machine code is lost, so Dart handlers sit at the documented entry points,
  each implementing its [J 90.02] interface contract — calling sequence, results,
  and documented register/memory side effects — and each unit-tested against
  that contract. Any routine is individually replaceable by real 7090 code if
  authentic code ever surfaces; the contracts and tests then validate the find.
- Codegen conformance oracle: our compilation of `test/fixtures/90.05-payroll.ct`
  is diffed against the 1962 compilation listing ([J 90.05], PDF pp. 198–216).
- Rejected: LLVM and emit-C backends (nothing 1962-observable in their output);
  interpreter-first (superseded by this route).

**D0.4 Fidelity: evidence-bounded bit-faithfulness.** Bit-faithful wherever the
manuals, the 90.05 listing, or period hardware documents specify behavior
(collating, word arithmetic, truncation/rounding, overflow, DO non-reentrancy,
deck formats). Where no evidence survives, the behavior is a recorded design
decision in this document — stated as a decision, never presented as historical
fact. Modern convenience must not leak into observable behavior.

**D0.5 Canonical formats: card images are canon; text mirrors are derived.**

- Canonical deck files are binary card images. Default (amendable):
  **column-punch level** — 80 columns × 12 punch rows per card — because
  (a) the punched card is the physical artifact, so this is the evidence-bounded
  canon; (b) object decks per [J 90.03] are column-binary cards, which 6-bit BCD
  cannot represent, so one container format serves source decks and object
  decks alike; (c) illegal punch combinations ([J 90.04] msg 134) become
  representable, which the lexer tests need. The 6-bit BCD code of a column is
  the defined read-out of a BCD-mode card.
- Text mirrors (the format of today's `test/fixtures/90.05-payroll.ct`) are
  **generated artifacts**: committed for review, grep, and GitHub diffs;
  regenerated by a pre-commit hook; CI fails if a mirror is stale; no build
  step ever reads a mirror. The compiler reads canon only. A git textconv
  driver renders canon decks as text in local `git diff`/`git log -p`.
- Sequencing: until the converter exists (an M1 exit criterion), the text deck
  remains the working authority; at M1 the 90.05 canon file is generated from
  it once, verified by round-trip, and the relationship inverts.
- Tooling: a VS Code punchcard editor edits canon directly (webview custom
  editor; holes are bits); MCP/CLI tools give agents structured read/write of
  the same files. Post-M1 side track; does not block the compiler.
- Amended 2026-08-05 (Jack's call): the file extensions are `.ctd` (canon)
  and `.ct` (mirror), renamed from `.ctdeck` and `.deck`, and the git diff
  driver follows them as `ctd`. Naming only: the format bytes and every
  rule above are unchanged. `docs/design/deck-format.md` §7 records the
  boundaries.
- Amended 2026-08-05 (Jack's call): the VS Code punchcard extension is a
  `deckconv` front end. A deck save runs `regen`; a mirror save runs
  `to-canon`, so a mirror edit in VS Code is legitimate once the round
  trip accepts it. The extension holds no second format implementation,
  and a committed mirror stays a generated artifact.
  `docs/design/deck-format.md` §6 records the workflow.

**D0.6 Character set and collating.** The internal character is a 6-bit BCD
code. Both [J 02.06.16] collating sequences are implemented as tables; the
Environment `OPTION COLLATE COM` card selects the Commercial (705) sequence,
the native 7090 sequence is the default (definition §1.1). Card-code ↔ BCD ↔
display-glyph tables follow §1.1 and the §8.5.8 scan-resolved legend, including
the five machine specials (⟨+0⟩ card 12-0, ⟨−0⟩ 11-0, ⟨rm⟩ 0-2-8, ⟨gm⟩ 12-5-8,
⟨loz⟩ 12-4-8). Display glyphs for mirrors and listings are chosen at M1.

**D0.7 Files, tape, labels, PATTERN.** I/O is emulated at the IOCS level
(external: C28-6100-2). Tape files are binary tape-image files (canonical);
the card reader, card punch, and printer surface as deck and print files at
the emulator boundary. Labels and PATTERN are modeled inside the emulated
IOCS per the definition's Q41/Q45/Q46 annotations and §8.5.6. Detailed
decisions land in D6 (I/O) and at M5.

**D0.8 Reconstruction target: the field-test compiler as attested.** Where J
documents lenient compiler behavior (e.g. accepting an omitted procedure-name
period with "no diagnostic message", [J 90.01.03]), the default mode reproduces
it. Written-language strictness beyond attested behavior lives behind an
optional `--pedantic` mode, clearly marked non-historical.

## D1–D9 — the §8.5 walk and the §8.4 conformance decisions

*Recorded 2026-08-02. Method: one decision record per §8.5 catalog entry plus
the §8.4 severity/conformance decisions, drafted per subsection, independently
and adversarially verified against the definition and the page scans, then
repaired — every blocker and correction applied and re-verified against the
manuals and the 90.05 listing before adoption. The walk recorded 84: D1–D8
mirror §8.5.1–§8.5.8, which then held 68 entries; D9 covers §8.4. Entry 8.5.4-n
(2026-08-04) grew the catalog to 69, and D4.14 (recorded 2026-08-16)
back-fills its record: 85 records now.*

*Reading key. A record's **Decision** states what our compiler, emulator, or
runtime does; **Oracle** names the evidence that tests it ("listing-diff" =
the 1962 compilation listing, "report" = the printed payroll register,
"decision-conformance only" = no surviving oracle — the decision itself is the
spec). Anything labelled a "design decision", "D0.4 decision", or
"non-historical" is unattested and amendable; it is our choice, not history.
Records opening with a **Resolved by Jack** note carry his dated call; a
record marked **OPEN — deferred** binds nothing yet and names the milestone
by which it must be decided.
The definition's §8.5 remains the evidence record; this section is the design
record built on it.*

## D1 — Lexical (§8.5.1)

### D1.1 — Quotation mark inside a quoted constant

**Status.** Locked.
**Decision.** The lexer scans a quoted constant as a run of characters up to the next quotation-mark (4-8) punch; the quotation mark is not representable inside a quoted constant and always closes it. There is no escape or doubling convention in either mode. The scan for the closing quote ends at the card boundary. Procedure text runs through column 72; the processor assumes a blank following column 72. Data and Environment text runs through column 71; column 72 is the continuation flag and is blanked before scanning. Sources: [J 02.03.01] A.2.c; [F p. 18] rule 1 ("All literals are limited to 50 characters in length, and, when written on the columnar form used for writing procedure statements, they may not be carried over from one line to the next"). A literal not closed on its card is diagnosed: msg 167 ("SECOND QUOTE MARK MISSING.") when no second quote mark is present, msg 168 ("ALPHABETIC LITERAL EXTENDS ACROSS CARDS.") when the literal would extend across cards. One attested exception is reproduced in default mode: literals in the Data Description continued on multiple lines "in violation of the rules given on page 83 of the General Information Manual are handled correctly" ([J 02.03.01] A.2.c), so default mode accepts such continuations silently and joins the parts in card order. --pedantic warns on that continuation, enforcing [F p. 83]'s rule that each line's portion be a complete quoted constant.

**Rationale.** J's scanner diagnostic for a missing closing quote only makes sense under a plain scan-to-next-quote rule, and neither manual defines an escape or doubling convention, so F's statement about the machine's character repertoire is read as describing the abstract character set, not a punching convention. The card boundary is stated directly by J ("each word or literal must be complete upon a line") and by [F p. 18] rule 1, and J itself names the single Data-Description exception, which the field-test-default rule requires us to reproduce.

**Implementation.** Lands in the lexer (quoted-constant scanner), with the card-boundary column set by the current division. Diagnostic severity for msgs 167 and 168 follows [J 90.04.01] (the printed severity column is 0 throughout; the real severity assignment is Open Question 65, unresolved). The storage layout of a continued Data-Description literal is Open Question 6, unresolved: our design decision is to concatenate the parts in card order with no assumed blanks and no padding or alignment between them ([F p. 83] General Note supplies the no-assumed-blanks half). --pedantic delta: warning on rule-violating Data-Description continuation only; the quote/escape rule itself is a hard lexical fact of the implemented language in both modes.

**Oracle.** decision-conformance only (the clean sample exercises no unclosed literal)

*Citations:* [F p. 19]; [F p. 28] rule 7; [F p. 111], ALPHAMERIC: "an alphameric literal may not contain a quotation mark"; [J 90.04.01] msgs 167, 168; [J 02.03.01] A.2.c; [F p. 18] rule 1; [F p. 83] General Note

### D1.2 — Maximum numeric constant/literal length under J

**Status.** Locked.
**Decision.** Enforce F's limits under J: 50 characters maximum for any literal ([F p. 18] rule 1) and 20 digits maximum for a literal or constant operated on arithmetically ([F p. 18] rule 3). Message mapping: an alphabetic literal longer than 50 characters raises the equivalent of msg 150 ("ALPHABETIC LITERAL EXCEEDS 50 CHARACTERS."); a numeric constant or literal that exceeds the arithmetic ceiling raises the equivalent of msg 52 ("MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL."). Which message a numeric literal longer than 50 characters takes is unattested: our compiler emits msg 52, a recorded design decision.

**Rationale.** J never restates a number for msg 52 or the 20-digit rule, but [J 02.05.06]'s double-precision fixed-point boundary (formats of more than 10 digits) is consistent with a 20-digit two-word ceiling, and J reaffirms the 50-character literal limit elsewhere, so F's numbers are read as still in force. Msg 150's text names alphabetic literals only, so it cannot be extended to the numeric side without inventing evidence.

**Implementation.** Lands in the lexer/data mapper (constant and literal length checks). Flagged internally as an evidence-bounded design decision (the exact numeric ceiling is inferred, not stated by J) per the fidelity policy, not presented as directly attested. Open Question 4 asks the same question and remains unresolved, so no stronger evidence narrows this further. No --pedantic delta — the limit is a hard compile-time check in both modes.

**Oracle.** decision-conformance only

*Citations:* [F p. 18]; [J 90.04.01] msgs 52, 150; [J 02.05.06] d; [J 02.04.02]

### D1.3 — Procedure-name terminating period

**Status.** Locked.
**Decision.** Both forms are accepted in default mode: period+blank (the defined F syntax) and its omission, in which case the name/text boundary is taken at the first blank after the name token beginning in the columns 7-12 name margin (simple names cannot contain blanks), with no diagnostic. --pedantic mode emits a warning when the period+blank is omitted, enforcing the written F syntax.

**Rationale.** F requires period+blank, but J explicitly states that names not so punctuated "are handled properly; no diagnostic message is given," so a faithful reconstruction of the field-test compiler must accept the omission silently while a stricter mode can still flag it.

**Implementation.** Lands in the lexer/parser boundary between the procedure-name field and statement text. Default mode: silent acceptance of both forms (no diagnostic). --pedantic mode: non-fatal warning diagnostic when the period+blank is missing.

**Oracle.** listing-diff: the period+blank form appears throughout the sample deck, e.g. the card `      START.          OPEN ALL FILES,` — `START.` in columns 7-12, statement text from column 23 (test/fixtures/90.05-payroll.ct line 202); that card prints as statement 188,00 in the listing ([J 90.05] listing, PDF p. 195). Decision-conformance only for the omission-tolerance path, which the clean sample never exercises.

*Citations:* [F p. 37] rule 2; [J 90.01.03] A.1.a.ix; [F p. 15] rule 1; [J 90.05] listing, PDF p. 195

### D1.4 — "Alphabetic" vs "alphameric" literal

**Status.** Locked.
**Decision.** Treat ALPHABETIC and alphameric literals as one lexical class: a quote-delimited non-numeric literal, scanned identically regardless of which term a diagnostic or context uses. "Alphabetic" vs "alphameric" is a content/semantic classification applied downstream (e.g. in picture-clause validation), never a separate lexical rule.

**Rationale.** F gives identical formation rules for the two, and J's own diagnostics ("ALPHABETIC LITERAL", msgs 150/168) and prose ("alphameric literal", [J 02.04.02.01]) refer to the same object under two names, so a single lexical token class is the only reading consistent with both.

**Implementation.** Lands in the lexer (single literal-scanning rule); no separate alphabetic-literal scan path. No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* [F p. 19]; [J 02.04.02.01] B.2; [J 90.04.01] msgs 150, 168

### D1.5 — Reserved word EQUALS

**Status.** Locked.
**Decision.** EQUALS joins the reserved key-word table as a member of [J 02.03.02] list 2 — "The following words may not be used as Data or Procedure names" — not list 1 ("always interpreted as Key words and may not be used as programmer names in any division"), so the bar is scoped to Data and Procedure names. The parser implements no relational-condition spelling EQUALS; the only documented equality forms accepted are IS EQUAL TO and =. Default mode does not reject a program that uses the word as a name: where a Procedure key word appears as a name in the Data or Environment Division, the compiler emits the equivalent of msg 178 ("PROCEDURE KEY WORD USED IN DATA OR ENVIRONMENT, INTERPRETED AS A DATA NAME."), interprets it as a data name, and continues.

**Rationale.** J's key-word list reserves EQUALS alongside EQUAL, but no relational form spelled EQUALS is documented anywhere and F lists only EQUAL, so the most plausible reading is a defensive reservation with no corresponding grammar production. Msg 178 attests the field-test compiler's recovery for exactly this class of misuse — diagnose and accept, not reject — and the slate's field-test-default rule requires the default mode to reproduce that leniency.

**Implementation.** Lands in the lexer (reserved-word table, tagged with its [J 02.03.02] list number so the scope of each bar is enforced correctly) and the parser (relational-condition grammar, which accepts only EQUAL / IS EQUAL TO / =). Data or Environment use as a name: msg 178, interpret as a data name, continue (attested). Use as a Procedure name: no J message covers this case; our recorded design decision is to emit msg 192 ("SENTENCE STRUCTURE ERROR. POSSIBLE ILLEGAL USE OF A KEY WORD.") and continue — flagged internally as a decision, not attested behavior. Using EQUALS where a relational connective is expected is unrecognized syntax, since no grammar rule covers it. No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* [J 02.03.02]; F pp. 21, 110; [J 90.04.01] msgs 178, 192

## D2 — Program structure (§8.5.2)

### D2.1 — PROGRAM.START — an undocumented entry-point facility

**Status.** Locked.
**Decision.** PROGRAM.START is implemented as a reserved procedure-name. Labeling a statement or section with it designates the object-program entry point. At most one PROGRAM.START is allowed per program (msg 141 "MORE THAN ONE -PROGRAM.START-. FIRST USED." on a second occurrence, first one wins, compilation continues); it must label a statement or section (msg 142 otherwise) and is never DO-addressable (msg 143 otherwise). Absent PROGRAM.START, codegen itself resolves the entry point to the LOC of the first *PROCEDURE sentence. In both cases codegen punches that LOC in the object deck's end-of-text special entry, control group 01111, whose data-word address "contains the relative program entry point" ([J 90.03.04]). The Loader's own default start point — first program of combined segments, overridable by a *START card ([J 03.02.08]) — is a distinct mechanism and is not relied on for this.

**Rationale.** No language section defines the facility, but the three diagnostics (msgs 141-143), [J 90.02]'s note that the first object word is "not necessarily PROGRAM.START", and Open Question 12 (Resolved) together fix both the labeled and default behavior. Open Question 12 shows the compiler always punches the transfer address itself: the sample, which has no PROGRAM.START, ends its text deck with `00165 500000000165 01111 START GN)000`, GN)000 being the compiler-generated name of statement 187,00, the first *PROCEDURE sentence, resolving to LOC 00165.

**Implementation.** Lands in the parser (recognizing PROGRAM.START as an attachable reserved label), codegen (entry-point resolution — labeled PROGRAM.START if present, otherwise the first *PROCEDURE sentence — and writing the 01111 end-of-text entry per [J 90.03.03]-04), and the loader (consuming the 01111 entry). Diagnostics per [J 90.04.01] msgs 141-143. No --pedantic delta — this is core object-format behavior, not a leniency question.

**Oracle.** listing-diff: the default-entry-point path is directly verified by Open Question 12's re-derivation against test/fixtures/90.05-payroll.ct ([J 90.05] listing, PDF pp. 195, 198, 200, 216). Decision-conformance only for the explicit-PROGRAM.START-labeled path, which the sample does not exercise.

*Citations:* [J 90.04.01] msgs 141-143; [J 90.02.01]-02; [J 90.03.03]-04; [J 03.02.08]; [J 90.05] listing PDF p. 195

*Amended 2026-08-30 (M4 stage 3, `docs/design/loader.md` LD-3).* The loader consumes the 01111 entry as decided. The generator names the first *PROCEDURE sentence as the entry point of every program. It does not yet honor a labeled PROGRAM.START; that path waits for stage 4, where a program first runs.

### D2.2 — Division ordering and interleaving

**Status.** Locked.
**Decision.** The parser accepts interleaved division portions — any number of *DATA, *ENVIRONMENT, and *PROCEDURE portions in any order. DATA → ENVIRONMENT → PROCEDURE once each (the sample's layout) is treated as the canonical demonstrated order for our own generated test fixtures. Two sub-rules are recorded design decisions, not attested facts, because Open Question 10 is unresolved. (a) Portions of one division are concatenated into that division's material in source-deck order (only implied by [J 90.02.01]). (b) A section may be split across two *PROCEDURE portions separated by *DATA/*ENVIRONMENT material. Our parser accepts that split. Source-order concatenation makes the section's text contiguous in the procedure stream, and the field-test default is leniency where no diagnostic is attested.

**Rationale.** F explicitly permits interleaving portions, and J's diagnostic 87 ("PROBABLE PROGRAM CONTINUITY ERROR. PROGRAM FLOWS INTO *DATA.") only makes sense if a *DATA portion can legally follow procedure text, so J is read as continuing to allow the F rule rather than silently dropping it. Neither manual states the concatenation order or rules on split sections, so both are recorded decisions under the evidence-bounded fidelity policy.

**Implementation.** Lands in the parser/division scanner, which tracks the current division across repeated headers rather than assuming one portion per division. Msg 87 is a control-flow continuity check, not a header check: it fires when control flow reaches the end of a *PROCEDURE portion that is followed by a *DATA portion, i.e. the object program would fall through into data. Its family confirms the reading — msg 99 "PROGRAM FLOWS INTO STATEMENT OR SECTION" and msg 169 "PROGRAM FLOWS INTO GENERATED CONSTANTS". No --pedantic delta, since interleaving is the resolved default behavior, not extra leniency.

**Oracle.** listing-diff for the canonical single-portion order against test/fixtures/90.05-payroll.ct ([J 90.05] listing, PDF pp. 192-197); decision-conformance only for multi-portion interleaving and split sections, which the sample does not exercise

*Citations:* [F p. 27]; [J 90.04.01] msgs 87, 99, 169; [J 90.02.01]; [J 90.05] listing PDF pp. 192-197

### D2.3 — Cards before the first division header

**Status.** Locked.
**Decision.** A division header (*DATA, *ENVIRONMENT, or *PROCEDURE) is required as the first non-control source card following the compile control card; no default division is assumed. The compiler accepts both attested control-card forms: the 1961 form `*COMPILE` with its option field (as in the sample deck, `*COMPILE LIST`) and the J-documented `$CMPLE` ([J 02.01.01]). Source text appearing before the first division header is diagnosed as an error.

**Rationale.** F states that entries following a division header belong to that division but says nothing about cards preceding the first header, and no text supplies a default, so requiring the header is the only reading with textual support. Both control-card forms must be accepted because Open Question 70 (Narrowed) brackets the rename: the Oct 18 1961 run — our top-ranked conformance oracle — compiled under `*COMPILE LIST`, while $CMPLE is attested only in the Jan 1962 manual. A $CMPLE-only check would reject the oracle's own deck.

**Implementation.** Lands in the parser (control-card reader plus division-header check at the start of the source stream). The 1961 option set is unrecovered — LIST is the only option observable (Open Question 70) — so our reader accepts LIST on *COMPILE and the documented $CMPLE option set otherwise. No J diagnostic covers text preceding the first division header: the message text and severity for that case are a recorded design decision, not attested behavior. No --pedantic delta.

**Oracle.** listing-diff for the positive case: test/fixtures/90.05-payroll.ct line 1 is the control card `*COMPILE LIST` (identification `CT PUBLICATIONS`) and line 2 is the division header `*DATA` ([J 90.05] listing, PDF p. 192). Decision-conformance only for the error path, which the clean sample never triggers.

*Citations:* [F p. 27]; [J 02.01.01]; [J 90.05] listing PDF p. 192

### D2.4 — Serial-number sequence checking

**Status.** Locked.
**Decision.** No sequence checking of the Ctl./Serial field in either mode. Serial numbers are read and may be shown in listings, but are never validated for ordering — in default mode and in --pedantic mode alike.

**Rationale.** F and J directly conflict (F says the field "will be sequence-checked by the processor"; J says "Card serial numbers in columns 1-6 of source decks are not sequence checked by the compiler"), and under the locked slate J outranks F, so J's stated absence of checking governs. --pedantic adds no check either: --pedantic enforces the written language where J is merely lenient, but here J disclaims the rule outright, and Open Question 74 asks whether F's claim was ever true of any processor — so there is no rule for a strict mode to enforce.

**Implementation.** Lands in the lexer/parser (serial-field reader): the field is read and retained for listing output only; no ordering-validation logic exists in either mode. The sample deck carries no serial numbers, so no oracle constrains the field's listing treatment.

**Oracle.** decision-conformance only

*Citations:* [F p. 37]; [J 02.03.01]

### D2.5 — Extent of section-scoped name uniqueness

**Status.** Locked.
**Decision.** Sections provide a qualification context and a uniqueness scope for procedure-side names (statements, paragraphs, section-internal labels). RECORD names remain program-unique and are never section-qualified, even when the RECORD is defined inside a section. A name collision within a section's procedure-side scope raises the equivalent of msg 166 ("'NAME.1' IS NOT UNIQUE IN THIS SECTION."). A qualified reference is written as a blank-separated compound name — `section-name procedure-name` — never in a dotted form. The period is an ordinary character inside a single name (`START.`, `CHECK.NEW.DEPT`). "Each name must be separated from the next by at least one blank space" ([F p. 15] rule 1), as in `INPUT.MASTER ORDER.DATE MONTH` ([F p. 15]) and `MASTER EMPLOYEE.NUMBER` in the sample deck. "section.name" and "record.name" in [J 90.01.03] are metavariables meaning "the name of the section/record", not a syntax.

**Rationale.** F allows section names as parts of compound names, and msg 166 implies a section-level uniqueness scope for at least some names. [J 90.01.03] states that if a record is defined within a section "the section.name may not be used as a qualifier of the record.name". A split namespace — procedure-side section-scoped, data-side program-global — is therefore the only reading consistent with both texts. It rests on inference from a diagnostic, and that hedge is retained. Whether procedure-names may be qualified by section names in ordinary procedure text is Open Question 7, unresolved: [F p. 26] permits section names as parts of compound names, while J restricts qualified names only in Environment and CRYPT contexts ([J 02.03.03]: "Qualified names may not be used in the Environment Description or in CRYPT instructions. Data and Procedure names used in these sections must be of one word only").

**Implementation.** Lands in the symbol table / semantic analysis (name resolver): two namespaces — one program-global for RECORD and data names, one per-section for procedure-side names — with qualified references parsed as blank-separated name sequences. The qualifier parser must never treat a period as a qualification connector; a period inside a name is an ordinary name character, and a period followed by a blank terminates a procedure statement ([J 02.03.02] A.3.a). Section-qualified procedure references in ordinary procedure text are Open Question 7 and unresolved: our recorded design decision is to read `DO A B` as procedure-name B qualified by section-name A, and to diagnose an unresolved or ambiguous compound reference. Qualified names are rejected in Environment Description and CRYPT text ([J 02.03.03], attested). Msg 166 on collision. No --pedantic delta.

**Oracle.** decision-conformance only for the scoping and qualification rules; the sample deck constrains only the surface form of compound names (blank-separated, e.g. `MASTER EMPLOYEE.NUMBER`)

*Citations:* [F p. 26]; [F p. 15] rule 1; [J 90.04.01] msg 166; [J 90.01.03]; [J 02.03.03]

### D2.6 — Column 72 vs column 71 blank assumption on the data form

**Status.** Locked.
**Decision.** For Data and Environment division lines, the compiler's card-image reader uses J's mechanism: text is read through column 71, and column 72 is treated purely as the continuation-column flag (J 02.06.01-02) — its contents are blanked before the text is scanned, so column 72 never contributes to Data/Environment text. Procedure division text is unaffected and still reads through column 72, per [J 02.03.01] A.2.c ([F p. 28] rule 14 agrees).

**Rationale.** J states both halves in one sentence: the processor "assumes a blank following column 72 of Procedure lines and replaces the contents of column 72 with a blank in Data and Environment lines" ([J 02.03.01] A.2.c). F's rule 14 states the same functional outcome for the two coding forms; under J-over-F, J is the stated authority for both sides and its operational mechanism is adopted for the 7090 implementation.

**Implementation.** Lands in the lexer/card reader, with the text-end column selected by division: column 72 for *PROCEDURE lines, column 71 for *DATA and *ENVIRONMENT lines (with column 72 read first as the continuation flag, then blanked). No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* [F p. 28]; [J 02.03.01]; J 02.06.01-02

### D2.7 — STOP n, bare STOP., and STOP RUN

**Status.** Locked.
**Decision.** Both STOP n (resumable operator halt, operand required, n up to 6 digits) and STOP RUN (mandatory, once-reachable program terminator) are implemented. The operand after STOP is required in default mode; bare STOP. (no operand) is a syntax error, since it is an informal Chapter-2 illustration predating the general form rather than a documented lenient form. A missing STOP RUN raises the equivalent of msg 175 ("NO -STOP RUN- IN PROGRAM."). Generated code for STOP RUN, attested by the sample, runs in three parts. First the SYS)178 display call: `TSX SYS)178,4` followed by its two words `PZE CP)+NN1,,CP)+NN2` and `PZE CP)+NN3,,CP)+NN4`, whose four Constant Pool entries carry "the Statement Number of the Stop (in BCD), and the type of STOP (STOP NNN or STOP RUN)" ([J 90.02.14]). Then the implicit close-all `TSX SYS)177,4` / `PZE IOC)1` ([J 02.04.06]: all open files are closed "as if a CLOSE ALL FILES had been supplied"). Then `TXI IOC)40,0`, the CT Monitor end-of-job return point. No halt instruction is generated. STOP n generates the same SYS)178 call with STOP type NNN carrying n, and no close-all and no end-of-job transfer.

**Rationale.** F defines only STOP n but shows a bare STOP. once informally; J requires STOP RUN in every program (msg 175) and its operator documentation shows both STOP nnnnnn and STOP RUN, so both general forms are implemented with an operand required. The code sequence is read directly off the sample rather than inferred: `CLOSE ALL FILES, STOP RUN.` compiles to `TSX SYS)177,4` / `PZE IOC)1` at 00517/00520 (the explicit CLOSE ALL FILES), then `TSX SYS)178,4` / `PZE CP)+26,,CP)+27` / `PZE CP)+28,,CP)+29` at 00521-00523, then a second `TSX SYS)177,4` / `PZE IOC)1` at 00524/00525, then `TXI IOC)40,0` at 00526 (LOCs octal). STOP n's restart behavior stays a design decision: [J 05.06.04] states only that the computer stops and "hitting the START key will cause the object program to continue in execution", while [F p. 54]'s resume-with-the-next-command wording is unconfirmed for the field-test processor — Open Question 69, unresolved.

**Implementation.** Lands in the parser (STOP grammar requiring an operand), codegen (the SYS)178-then-SYS)177-then-TXI IOC)40,0 sequence for STOP RUN, exactly in that order and word count; SYS)178 alone for STOP n), diagnostics (msg 175 if STOP RUN is missing), and the SYS)/IOC) runtime handlers plus emulator. The word RUN outside STOP RUN is deleted with msg 2 ("-RUN- DELETED. ITS USE IS RESTRICTED TO PROCESSOR.") and compilation continues — attested parser behavior. Recorded design decisions, flagged internally per the fidelity policy: the encoding of the STOP-type Constant Pool words (M4-14 as amended holds it); that the halt for STOP type NNN occurs inside the SYS)178 runtime handler (no STOP n appears in the sample, and no instruction-level evidence survives); and STOP n's display of n and resume-at-next-instruction on restart per [F p. 54] (Open Question 69). No --pedantic delta beyond what is already required-vs-decision.

**Oracle.** listing-diff for STOP RUN's generated code: attested at [J 90.05] listing, PDF p. 204, LOC 00521-00526 (`TSX SYS)178,4` / `PZE CP)+26,,CP)+27` / `PZE CP)+28,,CP)+29` / `TSX SYS)177,4` / `PZE IOC)1` / `TXI IOC)40,0`), re-derived and scan-checked under Open Question 47. Decision-conformance only for STOP n's generated code shape and its restart/resume semantics, since Open Question 69 remains open.

*Citations:* F pp. 25, 54; [J 02.04.06] #9; [J 90.04.01] msgs 2, 175; [J 90.02.14]; [J 90.02.08]; [J 05.06.04]; [J 90.05] listing, PDF p. 204

## D3 — Data description (§8.5.3)

### D3.1 — Subscript / quantity-nesting depth under J

**Status.** Locked.
**Decision.** The compiler enforces a maximum of three levels of nested QUANTITY specifications (QUANTITY IN ... QUANTITY IN ... QUANTITY IN) and a maximum of three subscripts per data-name reference; either limit exceeded is a compile-time error. This cap applies to quantity nesting only. Plain data-hierarchy (group) nesting is not capped at three: it is governed by J's approximate ~23-level data-hierarchy limit ([J 90.01.05]). J's whole-program table limits are approximate values (~85 array dimensions, ~90 positional indicators, ~25 QUANTITY IN specifications, ~23 hierarchy levels; [J 90.01.05]), so we do not enforce them as language rules. Our compiler tables are sized at or above these values; if a table overflows, the compiler reports a capacity diagnostic. The exact table sizes are a recorded design decision, not an attested rule.

**Rationale.** F states the three-level quantity-nesting cap and the three-subscript cap explicitly. J never restates or lifts them, and gives only approximate whole-program table limits. No J example exceeds two subscripts, so nothing in J contradicts retaining F's per-reference cap. F's cap is worded about quantity nesting -- "Quantity numbers may be specified for as many as three levels in a single 'nested' group" ([F p. 77]). It is not worded about plain group depth, which J allows to about 23 levels; conflating the two would reject legal programs. J's limits carry "approximately" in the manual, so an exact error threshold at 85 or 90 would turn an approximation into a stated rule.

**Implementation.** Data mapper: checked when the DATA division symbol table is built -- depth of nested QUANTITY specifications only. Plain group-hierarchy depth is checked against the ~23-level table capacity, not against three. Parser: subscript count checked when a subscripted procedure-division reference is resolved. Violation of the three-level/three-subscript cap raises a compiler-internal diagnostic (no J message number is attested for this check, since J never states the rule). Table-capacity overflow raises a separate capacity diagnostic, not a language-rule error. Applies identically in default and --pedantic modes, since the cap is retained, not added strictness.

**Oracle.** decision-conformance only

*Citations:* ([F p. 30], p. 77; [J 90.01.05]; [J 02.04.07])

### D3.2 — Written form of BLANK WHEN ZERO

**Status.** Locked.
**Decision.** The compiler accepts BLANK WHEN ZERO as free-text in the Description field (columns 38-71) of the data description card, written after any pictorial and separated from it by a blank, using the same placement rule as the other Description-field clauses (QUANTITY IN, LIBRARY, REDEF/COPY names).

**Rationale.** Neither manual gives a worked example of the clause's placement; the resolution reasons by analogy with F's ordered list of Description-field contents and with J 02.05.06(e)'s rule that non-format text in the pictorial columns is scanned as names, which together point to the Description field as the only consistent location.

**Implementation.** Lexer/parser: recognized as a Description-field keyword clause during data-description card scanning, alongside QUANTITY IN/LIBRARY/REDEF/COPY. Data mapper: the clause by itself sets the field type to Edited Field per the [J 02.05.05] field-type chart, with all consequences of that type. No constant may be defined in the field ([J 02.05.06]; msg 57,00 "CONSTANT CANNOT BE GIVEN FOR EDITED TYPE FIELD."). For comparison the field is converted to a pure numeric field, and may not be compared to an alphameric field ([J 02.04.07] rule 3). Codegen: because the field is an edited target, a move into it is performed by the MOVPAK edited-target move subroutines. These are SYS)185 (external decimal to edited), SYS)190 (edited to edited) and SYS)267 (internal decimal to edited), with the round step-subroutines SYS)220 and SYS)222 where a step list applies. Their documented parameter set includes Blank When Zero ([J 90.02.17]). [J 02.04.04] states "Subroutines are normally used to perform the requisite conversion and transmission". Under the slate these SYS) entry points are high-level-emulated Dart handlers. The compiler emits the documented calling sequence, not an inline blank-fill loop.

**Oracle.** decision-conformance only for the written form and card placement; the generated calling sequence for an edited-target move is testable against the 1962 listing where the sample exercises one (listing-diff)

*Citations:* ([J 02.05.05], 02.05.07; [F p. 79]; [J 02.04.04]; [J 02.04.07]; [J 02.05.06]; [J 90.02.17]; [J 90.02.16]-19, 90.02.30-31; [J 90.04.01] msg 57,00)

### D3.3 — "Non-format field"

**Status.** Locked.
**Decision.** The compiler treats a data-description entry with no pictorial clause -- i.e. a group field -- as a 'non-format field' for [J 02.04.07] rule 4: its comparison type is alphameric and its length is the sum of its subfields' lengths. The comparison then follows [J 02.04.07] rule 2b, to which rule 4 is expressly subject. For = / NOT = between unequal-length alphameric operands the fields are always found unequal. The compiler therefore folds the test at compile time. It generates only the transfer to the branch that the constant outcome selects. For `IF A = B THEN GO TO C OTHERWISE GO TO D.` that is the transfer to D. For `IF A NOT = B THEN GO TO D OTHERWISE GO TO C.` it is D again -- the selected branch, not specifically the false branch. For the relative-magnitude operators the lengths are made equal by right truncation of the longer field.

**Rationale.** [J 02.04.07] rule 4 requires comparing 'all non-format fields' alphamerically but never defines the term in 02.05; the only 02.05 definition that fits -- an item with no pictorial, per 02.05.06(c) -- is treated there as alphameric with length equal to the sum of its subfields, matching what the comparison rule needs. Rule 4 is load-bearing in its qualifier 'subject to rules stated in 2b above': group fields are almost always of unequal length, so the 2b path is the normal case, not an edge case. Open Question 42 records that rule 2b is written operator-scoped, and that 'a transfer to D' names the branch the constant outcome selects, not specifically the false branch.

**Implementation.** Data mapper: field-type classification during DATA division processing assigns 'group / non-format' to any entry lacking a pictorial clause, with derived alphameric length. Codegen: procedure-division comparison-statement generation consults this classification to select the alphameric comparison path per [J 02.04.07] rule 4, then applies rule 2b -- constant-fold = / NOT = when the two operand lengths differ and emit only the selected transfer; for the relative-magnitude operators emit a comparison over the equalized length obtained by right truncation of the longer field. The fold is operator-scoped, so it applies in every construct that evaluates such a condition (IF sentences, conditional GO TO WHEN clauses, TR operands), per Open Question 42.

**Amended (M3, 2026-08-04).** The mapper realizes the group length as the group's physical extent, carried in `ItemSemantics.storageChars`. The Decision sentence "its length is the sum of its subfields' lengths" is superseded by the extent. The sum and the extent agree on the worked example in [J 02.05.06]. They diverge in two cases. A redefinition head adds no length: "redefinition of a record area does not give it length" ([J 02.05.01]). Interior alignment padding is part of the extent, because a comparison over the group covers the padded storage. The M3-4 amendment in `docs/design/m3-data.md` records the same ground.

**Oracle.** decision-conformance only

*Citations:* ([J 02.04.07]; [J 02.05.06]; [J 02.05.01])

### D3.4 — The REDEF line: name and layout

**Status.** Locked.
**Decision.** Default mode: storage assignment follows the J convention -- the REDEF entry's first following data-description entry must be at the same level as the redefined item, matching J's restructured sample. A name written on the REDEF line itself (F's style) is accepted without rejection and produces a non-fatal warning diagnostic, since storage-assignment semantics never use that name; the redefinition is always resolved against the REDEF operand. The name is discarded after the warning: it is not entered in the dictionary, so any procedure-division reference to it is an undefined-name error, and it never takes part in compound-name formation ([J 02.05.02]: "Compound names are formed without regard to REDEFs"). This disposal is a recorded design decision -- J states no treatment for a name on the REDEF line. --pedantic mode: a name on the REDEF line is rejected with a diagnostic, requiring the bare J form ('REDEF <item>' with only a serial number and item name).

**Rationale.** J's own sample restructures the identical F program to drop the name from the REDEF line, and J's storage-assignment description never uses such a name. J's bare form therefore governs default codegen semantics. But J states the requirement with 'should', not as a prohibition. Under the slate's rule that attested field-test leniency is reproduced by default, an F-style named REDEF line is warned rather than rejected. J supplies only half the disposal rule (the name has no qualification role); the rest is a decision, stated as such.

**Implementation.** Parser: DATA division REDEF-line grammar accepts an optional name field; presence of a name sets a diagnostics flag and the name is then discarded. Diagnostics: default mode emits a warning-severity message (no J message number is attested for this case); --pedantic mode escalates it to a rejecting error. Data mapper: on the REDEF line, save the contents of the storage-assignment counter; assign storage for the following entries over the redefined area; on termination -- an item of a level above or equal to the level of the item referenced by the REDEF, or another REDEF -- restore the counter and continue normal assignment ([J 02.05.02]). Storage assignment for the redefinition always keys off the redefined item named in the REDEF operand, never off any name on the REDEF line, in both modes.

**Oracle.** listing-diff for the bare J form (sample deck, [J 90.05] listing PDF p. 195); decision-conformance only for the lenient acceptance of an F-style named REDEF line, for its --pedantic rejection, and for the dictionary disposal of that name

*Citations:* ([F p. 75], pp. 100, 104; [J 02.05.02]; [J 90.01.03] b.iii; [J 90.05] listing PDF p. 195)

### D3.5 — "Highest level" in the justification default

**Status.** Locked.
**Decision.** The default-justification rule uses the numerically smallest level number present in the source program as the 'highest level'. Fields at that level are left justified unless explicitly specified as right justified. An explicit R is honored only for data items with an explicitly described format ([J 02.05.04]: "Specification of right justification is effective only for data items with explicitly described formats. Left justification is always effective"). On a format-less entry -- a record or group with no pictorial, which is what highest-level entries typically are -- an explicit R is ineffective and left justification applies.

**Rationale.** [J 02.05.01]'s own example states that with levels 05 and 10 present, the level-05 fields are left-justified 'since 05 is the highest level used in the program', directly resolving the numerically-smallest-vs-largest ambiguity in favor of smallest-number-as-highest-rank. [J 02.05.04]'s effectivity rule limits the exception: an explicit R does not always win, so a record that let R override on a format-less group would produce a wrong storage layout, visible in the listing diff.

**Implementation.** Data mapper: after building the DATA division level hierarchy for a program, determine the minimum level number in use and apply left-justification as the default for entries at that level. When an entry carries an explicit R, honor it only if the entry has an explicitly described format; on a format-less entry ignore the R and keep left justification. Silent default, no diagnostic implication.

**Oracle.** manual example (citation)

*Citations:* ([J 02.05.01]; [J 02.05.04])

### D3.6 — Does the constants-then-REDEF table technique survive?

**Status.** Locked.
**Decision.** Entries containing constants are legal when they belong to the original definition of an area -- i.e. when they precede the REDEF line that redefines that area. J's restriction against constants applies only inside the REDEF's extent, where the extent starts at the REDEF line and ends at the first item of a level above or equal to the level of the redefined item, or at the next REDEF ([J 02.05.02]). F's canonical constants-then-REDEF table-building technique therefore remains legal with respect to constants. Its card layout is governed separately by the REDEF-line record in this same unit: the first entry after the REDEF must be at the redefined item's level, so F's sample -- REDEF at level 01 over RATE.TABLE with RATE at level 02 -- must be restructured to J's layout, as J itself did for the identical program.

**Rationale.** J forbids constants 'as part or all of the redefinition of an area'. By its own wording that bars constants among the entries that make up the redefinition, not among the entries the REDEF is defined against. This reading is also the only one consistent with F's demonstrated technique, and with [J 90.01.03]'s advice that a record containing an array precede the REDEF. The catalog Resolution settles the constants question only; it says nothing about layout, so the layout must come from the REDEF-line decision rather than from an unqualified 'accepted unchanged'. [J 02.05.02] supplies the extent rule; without it the end of the redefinition, and so the end of the constants ban, is undefined.

**Implementation.** Data mapper: the constants restriction applies to every entry inside the REDEF's extent, computed by the level rule above ([J 02.05.02]). Entries preceding the REDEF line are the original definition and are exempt. Diagnostics: a constant entry inside the redefinition is rejected per [J 02.05.06] item iv; no message number is attested for this restriction (msg 57,00 covers only constants in an edited-type field), so the message text and number are a recorded design decision. No diagnostic for constants before the REDEF line. See the REDEF-line record for the layout and storage-counter rules that apply to the same construct.

**Amended (M3, 2026-08-04).** A message number is attested for this restriction. Catalog msg 43,00 reads "CONSTANT CANNOT BE ASSOCIATED WITH -REDEF- OR INPUT RECORD, OR PRECEDED BY VARIABLE LENGTH FIELD." (B.2 data description). The Implementation sentence "no message number is attested for this restriction" is superseded. The mapper issues msg 43,00 for a constant inside a REDEF extent, for a constant in a located input record, and for a constant after a variable length field, and does not store the constant. No 930-series number is allocated for this check.

**Oracle.** manual example (citation) for the legality of constants in the original definition ([F pp. 74-75]); decision-conformance only for the extent rule and for the diagnostic text/number

*Citations:* ([F pp. 74-75]; [J 02.05.06]; [J 02.05.02]; [J 90.01.03])

## D4 — Arithmetic and data manipulation (§8.5.4)

### D4.1 — Rounding: threshold stated, edge cases not

**Status.** Jack's call. Parts (a) to (c), (e) and (f) were recorded 2026-08-02 and bind. Part (d) was deferred 2026-08-02; Jack locked it 2026-08-04. Every part now binds.
> **Resolved by Jack, 2026-08-04.** Part (d) was presented 2026-08-02 with three open readings and deliberately deferred. (i) A SET store through a step-list package rounds; a MOVE store truncates. (ii) Any step-list store that must discard low-order digits rounds, MOVE included. (iii) The default mode never emits a round step. A 2026-08-04 evidence pass re-swept both manuals, the sample, and the period record, and adversarially verified the two claims the deferral rested on. Both held. First, J states no emission rule. The appendix writes inclusion conditions where it has them — SYS)265 "appears as part of the GET calling sequence to the IOCS Read routine whenever the 'AT END' option is not used with the GET verb" (J 90.02.29), and SYS)283 uses the same construction for ON ERROR (J 90.02.32) — and writes none for the five round steps. Scan-checked on images/page-155.png, page-156.png, page-158.png, page-162.png, page-168.png, page-169.png. Second, the sample's silence decides nothing. None of its 51 MOVPAK calls (25 through SYS)180, 26 through SYS)182; re-derived from the octal address fields, LOC 00165–01620 gapless) discards a low-order digit, so the printed listing is identical under all three readings. Reading (iii) therefore has no evidence for it, and it strands the five round steps and forfeits F p. 44's default on any SET store that discards low-order digits by the character route. Jack chose reading (i). Reading (ii) stays on record in (d) as the amendment.

**Decision.** Default SET rounding is a half-adjust away from zero, applied at the store only.

(a) Arithmetic path (internal-decimal target, right justified) — attested code shape. When the accumulated scale of the expression exceeds the target scale by 10^k, codegen emits the tail `XCA / ACL CP)+h / LRS 35 / DVP CP)+d / STQ target`, where CP)+d = 10^k and CP)+h is exactly half the divisor. Both pairs are attested in the printed constant pool: `ACL CP)+32 (500) / DVP CP)+33 (1000)` and `ACL CP)+34 (50) / DVP CP)+31 (100)` ([J 90.05] listing, PDF pp. 206, 210–211, 215–216). The emulator implements ACL so that the addend enters the accumulator magnitude and the sign position is not changed; the half-adjust is therefore away from zero for negative values, and the carry runs in binary into the integer part before the truncating DVP. No separate carry mechanism exists and no sign test is emitted. This ACL reading is an inference from 709/7090 instruction semantics, external to both manuals (Open Question 26); neither manual states it, and the sample exercises no negative value.

(b) TRUNCATED suppresses the `ACL CP)+h` word only; the scaling plan (LRS 35 / DVP CP)+d) is unchanged. Design decision under D0.4, amendable — J and F never show TRUNCATED code, and Open Question 28 records that "whether TRUNCATED merely suppresses the ACL half-divisor or changes the scaling plan is unattested".

(c) MOVE store, digit-count split — attested, and NOT a scale change. When the value stored has more digits than the target pictorial can hold, codegen emits `CLA source / LRS 35 / DVP CP)+t` before the edit convert, where CP)+t = 10^(target digit count). The sample's case is `CLA 3)NETPAY / LRS 35 / DVP CP)+24` with CP)+24 = 1,000,000. It moves source `WORKING NETPAY IR9(5)V99` (7 digits, scale 2) into target edited `8889.99` (6 digits, scale 2). The two fields have the same scale, so no scale change and no digit loss at the low end occurs. The seven-digit-to-seven-digit moves on the same listing page carry no divide at all. The divide splits the value for SYS)267: the digits that fit remain as the remainder in the AC, the excess becomes the quotient in the MQ, matching the MQ-high/AC-low layout SYS)166 documents. Neither the purpose nor the overflow consequence of the split is stated in either manual (Open Question 28, "One further store-side mechanism observed but not explained by any text"); our runtime performs the split as described and takes no action on the excess quotient. Codegen must key the divide on the digit-count comparison, never on a scale difference.

(d) Emission rule for the five MOVPAK round steps — Jack's call, 2026-08-04, under D0.4, keyed to Open Question 26 still-open item (3), amendable. J supplies five round step-subroutines and no algorithm: SYS)219 (with SYS)183), SYS)220 (with SYS)185), SYS)221 (with SYS)189), SYS)222 (with SYS)190), SYS)274 (with SYS)268). Our rule: codegen emits the serving package's round step when a SET store routed through one of those five step-list packages must discard low-order digits and TRUNCATED is not written; a MOVE store emits no round step and no `ACL`, so a MOVE truncates. The step's position in the emitted sequence is also our choice: the printed lists are menus, not orderings — "Immediately following the TXI instruction will be two or more of the following instructions" ([J 90.02.16]), and the scans print list entries after the terminator line — so we emit the round step at the position of the rounding character. Four grounds carry the rule. First, it keeps F's two statements apart: [F p. 44] makes rounding the SET default, while [F p. 42] says only that MOVE alignment "may involve the dropping of leading digits or low-order digits". Second, the opt-out fits: TRUNCATED is writable on SET and ADD only ([F p. 44], p. 47), and no ROUNDED word exists in either manual, so rounding can only be a default, and this rule puts the off-switch exactly where rounding is. Third, it keeps the five round steps reachable. Their families take character sources only, and an arithmetic result reaches its store as internal decimal in the accumulator, so the one store that can enter them is a copy-shaped SET between character-numeric fields. The copy-shaped SET is a real statement form — [J 02.04.05] shows its alphameric case, which routes through the alphabetic movers and cannot round. Whether codegen routes a numeric copy through the character families is an M4 choice; this rule keeps the round steps live there, where reading (iii) kills all five. Fourth, as period context only (external: *Report to the Conference on Data Systems Languages — Initial Specifications for COBOL*, DoD, April 1960, pp. V-15–16, V-28–29, bitsavers): COBOL-60 has the same polarity — its arithmetic verbs round unless UNROUNDED is written, and its MOVE aligns "with truncation or zero fill on either end as required", with no rounding option. ADD needs no separate rule: an ADD result always reaches its store as an internal-decimal value in the accumulator, so its stores take the arithmetic path of (a) — the inline `ACL` is its default rounding, [F p. 47] makes TRUNCATED "equally applicable to the ADD command", and (b) covers the suppression — and no ADD store enters a step-list package. The rule is consistent with the sample, vacuously: verified 2026-08-04, none of the sample's 51 MOVPAK calls discards a low-order digit, so the sample cannot separate the readings. The alternative reading stays on record as the amendment: the round step is emitted whenever any step-list package must discard low-order digits, MOVE included. Its premise — Open Question 26 called the round-carrying packages "the four MOVE-serving packages" — is a label, not a finding: the same step-list families serve move-shaped SET stores and operand-side fetches (annotated there 2026-08-04). Under the amendment, MOVE would round with no opt-out.

(e) MOVPAK round-step handler internals — design decision under D0.4, no evidence survives. The rule at the rounding character position. If the digit being discarded is 5 or greater, add 1 into the retained low-order digit of the target magnitude, and propagate the decimal carry leftward through the target digit positions. The sign is neither read nor changed, so the adjustment is away from zero. A carry out of the high-order digit position is dropped. The appendix gives the step no repetition count and does not state whether its effect is confined to one position, and [J 90.02.18] prints "Round current characters" (plural) for SYS)221 — the one place the manual hints at a wider scope. The single-position choice is amendable on that hint.

(f) Overflow. On the arithmetic path, rounding cannot raise the language-level overflow condition and cannot set SYS)130: the rounded quotient is stored by a bare `STQ` with no MOVPAK call anywhere in the sequence, so no cell can be armed there (attested). For a MOVPAK round step, a rounding carry out of the high-order digit position does not set SYS)130 in our runtime — design decision under D0.4, because SYS)130's wording is scoped by subroutine rather than by cause, so the case is "neither asserted nor excluded" (Open Question 26 still-open item (2)). See the overflow record.

**Rationale.** F fixes the threshold — the least significant remaining digit "is increased by 1 when the part removed is greater than or equal to one-half" ([F p. 115]) — and [F p. 44] makes rounding the SET default. The compiled sample shows the inline mechanism four times, always as an `ACL` of half the divisor before the scaling `DVP`, with TRUNCATED never written ([J 90.05] listing, PDF pp. 196, 206, 210–211). Open Question 26 confirms that the ACL reading is inference from emitted code, that no negative case is exercised, and that the five MOVPAK round step-subroutines are entered by a bare `TRA` with no documented algorithm, sign rule, or carry rule. Open Question 28 supplies the constant-pool values and the separate digit-split divide. The two annotations differed on one point, and this record follows Open Question 28. Open Question 26 called the three `CLA / LRS 35 / DVP CP)+24` stores "scale-changing MOVE stores", and read their missing `ACL` as the strongest indication that MOVE truncates. But Open Question 28 shows source and target at the same scale. Those stores therefore discard no low-order digits, and cannot attest anything about MOVE rounding. That is why the emission rule in (d) is recorded as a decision and not as a finding. The 2026-08-04 evidence pass verified Open Question 28's reading. The pictorials force it: a seven-digit scale-2 source stored into a six-digit scale-2 target drops the high-order seventh digit and no low-order digit, whatever the register layout. The AC/MQ split — quotient to the MQ, remainder to the AC, the edit converting the low six — stays the labeled inference of Open Question 28. Open Question 26's contrary reading was annotated in place the same day.

**Implementation.** Lands in codegen (SET store sequence, MOVE digit-split test, constant-pool allocation), the emulator (bit-exact ACL, XCA, LRS, DVP, STQ), and the SYS/IOC runtime (the five MOVPAK round handlers). The constant pool IS printed in the object listing. The pool words run from LOC 01674 (CP)) to LOC 01771 (CP)+61) on [J 90.05] listing, PDF pp. 215–216 (images/page-216.png). Pool ordering, indices and octal values are therefore all part of the listing-diff. Open Question 26's remark that "the constant pool's contents are not printed" was contradicted by Open Question 28 and by the page itself, and was corrected in place 2026-08-04. Do not carry that remark into the implementation. Allocate the pool so that CP)+24 = 1,000,000 (OCT 000003641100), CP)+31 = 100, CP)+32 = 500, CP)+33 = 1000, CP)+34 = 50 fall at those indices. Codegen must hold two distinct store-side tests apart: the scale-excess test that drives the SET tail, and the digit-count test that drives the pre-edit split of (c). No diagnostic is attached to rounding. --pedantic delta: none. Decisions (b), (d), (e) and the MOVPAK half of (f) are recorded as amendable.

**Oracle.** listing-diff against the object listing ([J 90.05] listing, PDF pp. 206, 210–211 — the four `XCA / ACL / LRS 35 / DVP / STQ` SET tails; PDF pp. 203, 209 — the three `CLA / LRS 35 / DVP CP)+24` digit-split stores at LOC 00423–00425, 01112–01114 and 01141–01143; PDF pp. 215–216 — the constant-pool words, including CP)+24, +31, +32, +33, +34). Manual example ([F p. 115] worked cases 126.5027; [F p. 116] 2063.78 truncated against rounded). Decision-conformance only for negative values, for TRUNCATED codegen, for the round-step emission rule, and for the MOVPAK round-step internals.

*Citations:* (F pp. 44, 115–116; [J 90.02.16]–17); Narrowed: ([J 90.02.10], 90.02.16–19, 90.02.23, 90.02.30–32; [J 90.05] listing, PDF pp. 196, 203, 206, 209–211; images/page-148.png, page-157.png, page-162.png, page-169.png, page-206.png, page-210.png); Open Question 26 (F pp. 42–44, 115–116; [J 90.02.10], 90.02.16–19, 90.02.23–24, 90.02.30–32; [J 90.05] listing, PDF pp. 196, 203, 206, 209–211); Open Question 28, for the digit-split divide, the constant-pool values and the TRUNCATED gap ([J 90.02.15], 90.02.17, 90.02.26–27, 90.02.30; [J 90.05] listing, PDF pp. 193, 203, 209, 215–216; images/page-216.png)

### D4.2 — Overflow with no ON OVERFLOW clause

**Status.** Locked.
**Decision.** With no ON OVERFLOW clause the truncated result is stored and execution continues; no transfer and no object-time message occurs. This part is attested. No store path open to an arithmetic result carries a documented overflow test. An internal-decimal right-justified target is stored by a bare `STQ`/`STO` with no MOVPAK call at all. SYS)186–188 (external decimal), SYS)267 (edited) and SYS)246 (internal decimal not justified) each carry no test step. No entry in [J 90.02.00]–90.02.33 reads, tests or clears SYS)130. The fixed-point scaling and arithmetic handlers SYS)163–171 lie outside MOVPAK altogether and set no cell; this too is attested, not chosen. Arming rule for SYS)130 — design decision under D0.4, amendable. Our MOVPAK handlers for the five character-source families SYS)183, 185, 189, 190 and 268 carry the counted overflow-test step (SYS)195, 196, 199, 201, 203, 204, 270, 277, 281). Each of those handlers sets SYS)130 non-zero when its step finds a non-zero significant character in the positions tested. The handlers with no step list — SYS)184, 186, 187, 188, 246, 247, 267 — do not set the cell. The alternative reading stays on record, and it is the one J's class-wide wording most naturally supports. Detection is intrinsic to MOVPAK's numeric converts. The explicit `TXI` steps are then required only by the character-scripted families that need an instruction per character group (Open Question 27, reading (a)). A package's lack of a step "shows only that they have no step vocabulary" (Open Question 26). Nothing reads, tests or clears SYS)130; our runtime never clears it, so it is a sticky, statement-wide flag readable only through the emulator (design decision — no clearing is documented anywhere). MOVE high-order dropping stays silent and defined.

**Rationale.** F defines the reaction only when the clause is present ([F p. 42], p. 44), and J scopes SYS)130 by class — "any one of the numeric move or convert subroutines of MOVPAK" ([J 90.02.10]) — while only the five character-source families carry an explicit NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW step. Open Question 27 shows every store path open to an arithmetic result is testless, so "stored and continue" is the attested behavior and the flag's participation on the store is undetermined; it also states plainly that two readings survive and that the manuals decide between them nowhere. We implement the narrow reading because it is the one the printed calling sequences exhibit, and we record the wide reading as the amendment.

**Implementation.** Lands in the SYS/IOC runtime (MOVPAK handler contracts and the SYS)130 cell), codegen (emit the counted test step only for the five families, exactly as the calling-sequence lists in [J 90.02.15]–21 and 90.02.30–32 show), and the emulator (communication-cell storage). The narrow-versus-wide arming choice changes no emitted object code — only handler behavior — so listing-diff cannot decide it and an amendment is confined to the runtime. Note the printed inconsistency preserved in J: SYS)231–234 occupy the test slot in the family lists but their own entries print NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH; our handlers follow the individual entries (overpunch) and the calling-sequence position is recorded as a printed defect. No diagnostic. Compile-time msgs 27 and 199 (scaling loss) are a separate static mechanism and stay. --pedantic delta: none at object time; --pedantic may not add object-time checks, since that would change emitted code.

**Oracle.** listing-diff against the object listing ([J 90.05] listing, PDF pp. 203, 206, 210 — the testless store sequences `STQ 4)GROSS`, `STQ 4)FICA`, and `CLA 6)GROSS / TSX SYS)180,4 / PZE 2)GROSS,,1 / TXI SYS)267,1,4`); decision-conformance only for SYS)130 arming and non-clearing.

*Citations:* ([F p. 42], p. 44; [J 90.02.10]); Amended: ([J 90.02.10], 90.02.12–13, 90.02.15–21, 90.02.26, 90.02.30; [J 90.05] listing, PDF pp. 203, 206, 210; images/page-210.png); Open Question 27 ([F p. 44]; [J 02.03.02]; [J 02.04.05]; [J 90.01]; [J 90.02.10], 90.02.12–13, 90.02.15–21, 90.02.24, 90.02.26, 90.02.29–32; [J 90.04.01] msgs 27, 199; [J 90.05] listing, PDF pp. 203, 206, 210, 212)

### D4.3 — Invalid characters in a numeric field at object time

**Status.** Locked.
**Decision.** There is no program-level reaction and no object-time message. Arming set: the numeric MOVPAK members — SYS)183–238, SYS)246–258 and SYS)267–282 — set communication cell SYS)131 non-zero when they meet an improper data condition, and then continue; the alphabetic and figurative-constant movers SYS)239–245 do not set it. What counts as "an improper data condition" is unresolved, so the trigger is a design decision under D0.4 and is amendable: for external-decimal and edited sources, a character that is not a valid digit — or, in a sign position, not a valid overpunch sign — arms the cell. Scientific-decimal sources are exempt from that test. J allows them free-form content: "For the source fields of the scientific decimal type, a free form of data is allowed within the limits of the field". Its worked examples contain embedded blanks, signs and decimal points ([J 02.04.04] e). Our scientific-decimal converts therefore parse by that free-form rule. They arm the cell only when the field cannot be parsed at all under it. The value used for an invalid character is fixed by design decision (no evidence survives): the low-order four bits of the 6-bit BCD character are taken as the digit value, and zone bits that are not a documented overpunch sign are ignored. Nothing reads, prints from, or clears SYS)131; the cell stays sticky. No verb option can request a reaction: the only condition options are ON OVERFLOW (SET/ADD, single result field) and the FILE-card ON ERROR (unrecoverable redundancy, block checksum, block sequence only). The GET-path length-control-word check SYS)261/263 keeps its own separate behavior — it prints its message and exits to the CT Monitor — and is never used as the MOVE/arithmetic reaction. Compile-time diagnostics (msgs 25, 67, 111, 112, 120, 182) are unchanged and unrelated.

**Rationale.** Neither manual defines a program-level reaction, and the field-test sample converts a card-punched external-decimal field straight into pay arithmetic through SYS)184 with no check ([J 90.05] listing, PDF pp. 192, 196, 205). SYS)131 is documented only as being set on "an improper data condition" ([J 90.02.10]), and no appendix entry reads or clears it. Open Question 31 bounds the arming set to the numeric MOVPAK members and makes the trigger its leading still-open item, stating that it "cannot simply be 'any non-digit'" because of the scientific-decimal free-form rule; the record therefore scopes the test by source class and marks the whole rule amendable.

**Implementation.** Lands in the SYS/IOC runtime (numeric convert handlers, SYS)131) and in the emulator (cell storage). The scientific-decimal free-form parser is a separate code path from the external-decimal and edited digit scanners; do not share the validity test between them. Diagnostics: none at object time; do not raise a Dart exception and do not stop the run. Both the trigger rule and the conversion rule are labelled, amendable design decisions under D0.4. --pedantic delta: none (it is a compile-time mode). An optional, clearly non-historical emulator switch may report SYS)131 transitions to the host log; it must not change emitted code or program-visible state.

**Oracle.** decision-conformance only; listing-diff confirms only the absence of any object-time check on the SYS)184 conversion path ([J 90.05] listing, PDF pp. 192, 196, 205).

*Citations:* ([F p. 44], p. 47, p. 109; [J 02.07.07]; [J 90.01.02]; [J 90.02.07], 90.02.10, 90.02.16, 90.02.29; [J 90.04.01]–02; [J 90.05.02]; [J 90.05] listing, PDF pp. 192, 196, 205); Open Question 31, for the arming set and the free-form exemption ([J 02.04.04]; [J 90.02.10]–12, 90.02.14–19, 90.02.24, 90.02.25–33)

### D4.4 — Negation vs exponentiation

**Status.** Locked.
**Decision.** Negation binds tightest. The parser puts unary negation in the top hierarchy group with TR and ABS, above `**`, so `-A**2` parses as `(-A)**2` and `-A*B` as `(-A)*B`. F's operand rule is applied as printed: "all operators act on the next named item, or the next parenthetical expression, following the operator" ([F p. 28]). Extending the same rule to a literal operand, so that `-1.5` is a legal term, is a design decision under D0.4 — F's printed form names only a named item and a parenthetical expression — and it is what the expression grammar needs in order to accept a signed literal. No warning and no note are produced; --pedantic does not change the parse.

**Rationale.** J states the hierarchy directly and J governs (D0.1); F corroborates with the operand rule quoted above, and F's symbol-pair table admits negation only at expression or parenthesis start.

**Implementation.** Lands in the parser (expression precedence table) and is visible in codegen operand order. Diagnostics: none. --pedantic delta: none. Do not import the modern convention that `**` outranks unary minus. Record the literal extension as amendable.

**Oracle.** decision-conformance against the stated hierarchy ([J 02.04.05.01]) and against F's operand rule ([F p. 28], p. 106); the 90.05 sample contains no negated exponentiation, so no listing-diff evidence exists.

*Citations:* ([J 02.04.05.01]; [F p. 28], p. 106)

### D4.5 — Parameter/function declaration after the removal of PARAM and FUNCT

**Status.** Locked.
**Decision.** Parameter names and function-result names are declared as ordinary data-description fields; no special type code exists. The type codes PARAM and FUNCT are not in the implemented language. J states only the removal and not the compiler's reaction — "These two type codes described in the General Information Manual are no longer in the language." ([J 02.05.03]) — and [J 90.04.01] carries no message about type codes, PARAM or FUNCT. Design decision under D0.4, amendable. A data description card carrying either code is diagnosed with our own message. The entry is then processed as an ordinary data description entry, with the type code ignored. This repair-and-continue shape follows the compiler's own attested pattern for a bad code in a data-description column (msg 189 "EXTERNAL MODE SUBSTITUTED FOR ILLEGAL MODE CHARACTER.", msg 190 "FIELD IS NOT JUSTIFIED BECAUSE OF ILLEGAL JUSTIFICATION CHARACTER."). Severity per the severity-assignment policy (Open Question 65). Name resolution for BEGIN SECTION USING…GIVING, DO USING…GIVING, and function references works against the ordinary data-description name table, and the USING/GIVING machinery of F carries over unchanged (argument-to-parameter correspondence by position). Every function argument must be written explicitly; a reference with fewer arguments than the declaration is diagnosed (msg 30, "FUNCTION 'NAME.1' LACKS EXPLICIT SPECIFICATION OF ALL ARGUMENTS.").

**Rationale.** J removes both type codes yet keeps the USING/GIVING forms and their diagnostics (msgs 30, 68, 72–75), so only the codes were dropped; nothing else in J supplies a declaration form. The compiler's reaction to a removed code is nowhere stated and no message exists for it, so the rejection is a decision, not a rule read off the manual.

**Implementation.** Lands in the data mapper (type-code table: reject PARAM, FUNCT with our own diagnostic, then treat the entry as untyped), the parser and the symbol table (USING/GIVING binding), and diagnostics (msgs 30, 68, 72–75, message texts per [J 90.04.01]; severity per Open Question 65). The non-attested message text must be flagged in the message table so that it can never appear in a listing used for listing-diff. --pedantic delta: none.

**Oracle.** decision-conformance only (the 90.05 sample declares no parameters or functions); manual example ([J 90.04.01] msgs 30, 68, 72–75 as the diagnostic-implied rules).

*Citations:* ([F p. 34], pp. 52–53, 57–58, p. 73; [J 02.05.03]; [J 90.04.01] msgs 30, 68, 72–75, and msgs 189, 190 for the repair-and-continue pattern)

### D4.6 — Figurative-constant target maximum: 32766 vs 2¹⁵−1

**Status.** Locked.
**Decision.** The implemented maximum target length for a figurative-constant move is 32766 characters. A move of a figurative constant to a field of 32767 characters or more is diagnosed with msg 181 ("MOVE OF FIGURATIVE CONSTANT TO FIELD LONGER THAN 32766 CHARACTERS NOT YET HANDLED BY SYSTEM.") and no code is generated for that move. The prose value 2^15-1 is treated as an off-by-one in J's text and is not implemented.

**Rationale.** The message text most plausibly reflects the coded check in the field-test compiler, and D0.8 makes the attested compiler the reconstruction target.

**Implementation.** Lands in the data mapper / semantic check for figurative-constant moves and in diagnostics (msg 181; severity per Open Question 65). The limit constant is one place in the checker. --pedantic delta: none — the same limit applies in both modes, because the limit is a property of the reconstructed compiler, not a strictness choice.

**Oracle.** decision-conformance only (the 90.05 sample has no field near the limit); the diagnostic text is fixed by [J 90.04.01] msg 181.

*Citations:* ([J 02.04.01] c.ii; [J 90.04.01] msg 181)

### D4.7 — "Report field" (F) = "edited field" (J)

**Status.** Locked.
**Decision.** There is one type, J's Edited Field, and the compiler uses J's term everywhere. The internal type set is the six types of [J 02.05.05]: alphameric, external decimal, internal decimal, edited field, floating point, scientific decimal. A field is edited when its pictorial contains one or more of `8 * . , $ + -`, or when it carries BLANK WHEN ZERO. F's term "report field" has no separate meaning and appears in no diagnostic, listing text, or internal name. F's MOVE legality rule permitting numeric moves "to report fields" is implemented as numeric-to-edited moves in the J MOVE legality table.

**Rationale.** F's editing characters are exactly J's edited-field format characters, so the identification is effectively certain, and J governs the type vocabulary (D0.1). The six-type set is J's own chart: "Alphameric | External Decimal | Internal Decimal | Edited Field | Floating Point | Scientific Decimal" ([J 02.05.05]), and the figurative-constant chart of [J 02.04.02] carries the same six columns.

**Implementation.** Lands in the data mapper (pictorial classification over all six types — floating point is characterized by I in the Mode column with F or FF in the format field, and must not be dropped from the type enum), the MOVE/compare legality tables, codegen (selection of the edited convert packages SYS)185, 189, 190, 267, 268), and listing/diagnostic wording. --pedantic delta: none.

**Oracle.** listing-diff against the object listing ([J 90.05] listing, PDF pp. 193, 203–204 — the `88889.99` and `8889.99` print fields converted by SYS)267); manual example ([J 02.05.05] six-type chart; [J 02.04.02] chart; [F p. 42], p. 80).

*Citations:* ([F p. 42], p. 80; [J 02.05.05]; [J 02.04.02])

### D4.8 — Multi-result SET

**Status.** Locked.
**Decision.** `SET A, B, C = expression` evaluates the expression once into a Result Storage intermediate at its accumulated scale, then stores that same intermediate into each target independently. Each store gets its own alignment, rounding, and convert sequence driven by that target's pictorial; no target's stored (edited or rounded) value ever feeds another target. Store order is left-to-right in written order, which is observable only when targets overlap or redefine one another. TRUNCATED governs every store in the command, not only the first. ON OVERFLOW stays restricted to SET and ADD with a single result field per F; a SET with the clause and more than one result field is diagnosed.

**Rationale.** The entry's Resolution is the only reading consistent with F's statement that rounding is to "the format description of the result field or fields" ([F p. 44]), and Open Question 28 shows the machine model already parks the intermediate in a Result Storage cell before the scaling store, which makes one evaluation with independent stores the natural code shape. The single-result-field restriction on ON OVERFLOW is stated at [F p. 44] for SET and [F p. 47] for ADD.

**Implementation.** Lands in codegen (one expression evaluation into RS)n, then one store sequence per target) and in diagnostics (ON OVERFLOW with multiple result fields; severity per Open Question 65). RS cells are allocated two words each; that width is inferred from the listing's LOC values (Open Question 28), not stated by J. Store order left-to-right is a labelled design decision. --pedantic delta: none.

**Oracle.** decision-conformance only (the 90.05 sample contains no multi-result SET); the single-target store shape is anchored by listing-diff against the object listing ([J 90.05] listing, PDF pp. 206, 210–211).

*Citations:* ([F p. 44], p. 47, p. 109); Open Question 28, for the Result Storage model and the inferred two-word RS cell ([J 90.02.03]; [J 90.05] listing, PDF pp. 206, 210–211, 215–216)

### D4.9 — Edited source moved to an alphameric target

**Status.** Locked.
**Decision.** An edited source moved to an alphameric target transmits the converted numeric form, not the edited character image. Codegen compiles the move as edited-to-external-decimal conversion (the SYS)189 family, with its counted overflow-test step) followed by an alphameric transfer of the resulting external-decimal characters into the target; the editing characters `$ , . * 8 + -` never reach the target. Target justification and blank fill follow the ordinary alphameric rules for the target's level.

**Rationale.** J's conversion chart shows arrows into alphameric only from external and scientific decimal, and J's comparison rule states that edited fields "are converted to pure numeric fields", so the least-intermediate-steps routing gives the converted form.

**Implementation.** Lands in the MOVE legality/routing table and codegen (two-step route through external decimal); the SYS/IOC runtime needs no new handler. Diagnostics: none — the move stays legal. --pedantic delta: none. Record as evidence-supported inference, not attested code.

**Oracle.** decision-conformance only (the 90.05 sample makes no edited-to-alphameric move); manual example ([J 02.04.03], 02.04.04, 02.04.07 conversion chart, images/page-020.png).

*Citations:* ([J 02.04.03], 02.04.04, 02.04.07)

### D4.10 — A\*\*B\*\*C

**Status.** Locked.
**Decision.** The unparenthesized form `A**B**C` is illegal. The parser rejects a second `**` applied to the result of a first without parentheses, and issues a diagnostic; no code is generated for the statement. For error recovery only, the parser groups the form left-to-right as `(A**B)**C` so that later checks on the statement can still run; that grouping never reaches codegen in the default mode. The diagnostic text is our own, because [J 90.04.01] lists no message for this case.

**Rationale.** F forbids the form outright, and J is a clarification-and-amplification document that overrides F only where it says so; J never repeats or withdraws the prohibition, and no attested lenient behavior exists here, so D0.8 does not apply.

**Implementation.** Lands in the parser (expression grammar) and diagnostics (non-attested message; severity per Open Question 65 — it must count as an error so the statement is not compiled). Flag the message as non-attested so that it can never appear in a listing used for listing-diff. --pedantic delta: none. If evidence of acceptance ever surfaces, the recovery grouping `(A**B)**C` becomes the emitted form.

**Oracle.** decision-conformance only ([F p. 107] prohibition; [J 02.04.05.01] left-to-right rule for equal-hierarchy operators).

*Citations:* ([F p. 107]; [J 02.04.05.01])

### D4.11 — MOVE BLANKS into edited/external fields — "doubtful" yet compiles clean

**Status.** Amended.
**Decision.** MOVE BLANKS to an edited field or to an external-decimal field is accepted and produces blanks. Codegen emits the attested figurative-constant call, not an inline fill: set the target pointer inline (`LDI CP)+nn / STI SYS)133`), enter MOVPAK at `TSX SYS)182,4`, then `TXI SYS)243,1,<target character count>` — SYS)243 being the MOVPAK subroutine that "moves blanks to an alphabetic field" ([J 90.02.25]). No numeric convert is called and no overflow test is emitted. This is attested for edited targets. Statement 205,00, `MOVE BLANKS TO PAYRECORD BONDEDUCTION, PAYRECORD BONDENOMINATION`, compiles to two such sequences with counts 7 and 8 at LOC 00672–00701; the targets are the edited fields `8889.99` and `88889.99`. Statement 220,00 repeats it with count 8 at LOC 01313–01316. Statement 199,00 blanks five alphameric fields the same way, with counts 15, 4, 2, 2, 2 at LOC 00462–00505. A BLANK move to an external-decimal target is not exercised by the sample; our codegen routes it through the same SYS)243 sequence with the target's full character count, which is a design decision under D0.4. In the default mode no message of any kind is produced, so the listing keeps the attested closing line "NO ERRORS WERE DETECTED DURING COMPILATION" (printed without a trailing period). --pedantic emits a non-historical "doubtful usage" warning for these two cases; the warning is excluded from any listing used for listing-diff.

**Rationale.** The chart's note ("An error message is given for each doubtful or illegal usage") cannot be read literally for the starred entries, because the J sample blanks edited fields and still ends with no errors detected; D0.8 makes the attested compiler behavior the default and puts added strictness behind --pedantic. [J 90.04.01] does carry msg 82, "INCORRECT USAGE OF FIGURATIVE CONSTANT.", but the field-test compiler demonstrably does not emit it for BLANK into an edited field, so msg 82 must not be wired to this case.

**Implementation.** Lands in the MOVE legality table (figurative-constant chart), codegen (target-pointer setup, MOVPAK entry SYS)182, call SYS)243 with the target's character count), the listing writer (message suppression in default mode), and diagnostics (--pedantic warning only). The blank character is the 6-bit BCD blank code from the D0.6 tables; the fill itself lives in the SYS)243 handler, not in emitted inline code.

**Oracle.** listing-diff against the object listing ([J 90.05] listing, PDF pp. 204, 206, 211 — the `LDI CP)+nn / STI SYS)133 / TSX SYS)182,4 / TXI SYS)243,1,n` sequences for statements 199,00 (n = 15, 4, 2, 2, 2), 205,00 (n = 7, 8) and 220,00 (n = 8)). The source-program listing (PDF pp. 196–197) is evidence of the absent diagnostic and of the exact closing line only. Decision-conformance only for a BLANK-to-external-decimal target and for the --pedantic warning.

**Amended (M3 stage 2, 2026-08-04).** The Decision's "these two cases" is widened to five. The [J 02.04.02] chart stars every non-alphameric cell of the BLANK row: external decimal, internal decimal, edited, floating point, and scientific decimal. Msg 943,00 fires on all five under `--pedantic`, and the default mode stays silent on all five (M3-21). The chart's stored value differs by class: blanks for external decimal, edited and scientific decimal; 0's for internal decimal and floating point. The SYS)243 sequence above is the blanks case, and M4 codegen follows the chart column by column. Open, not done: the same chart stars six more doubtful cells, HIGH.VALUE and LOW.VALUE into external decimal, edited and scientific decimal. Those six draw no message in either mode. Extending 943 to them is a separate decision.

*Citations:* ([J 02.04.02] chart; [J 90.05] listing PDF pp. 196–197); Attested codegen: ([J 90.02.10]–11, 90.02.24–25; [J 90.05] listing, PDF pp. 193, 196–197, 204, 206, 211); ([J 90.04.01] msg 82, not emitted for this case)

### D4.12 — CORRESPONDING matching: F name-only vs J qualifier-chain

**Status.** Amended.
**Decision.** MOVE CORRESPONDING and ADD CORRESPONDING implement the J rule; the section is headed "CORRESPONDING Option with MOVE and ADD" and one pairing rule governs both verbs ([J 02.04.04]). Two fields correspond when, below the two operand roots, their qualifier chains are present and identical, name by name, down to the matched field. Matching is at the lowest possible level: a pair matches only where both sides are elementary, or where both sides are group fields with no matching elementary descendants. When a matched pair is a group, the source group "has no format characteristics of its own and is assumed to be alphameric", and the pair is then subject to the ordinary MOVE (or ADD) legality table — "If DATA.2 GROUP ITEM is a field into which alphameric information may not be legally moved, an error will be noted." ([J 02.04.04]–05 c). One move or add sequence is generated per matched pair, in data-description order. A subscript written on a CORRESPONDING operand is appended to every generated instruction for that side: "Data items referenced in a MOVE or ADD CORRESPONDING clause may be subscripted. The compiler simply appends the designated subscript to the generated instructions." ([J 02.04.04]–05). A name that matches nothing generates no code and no message. F's loose name-only rule is not implemented; F-sample moves that match nothing under J compile to nothing, and are recorded as latent defects of 1960 code, not as a compatibility mode.

**Rationale.** [J 02.04.04] is authoritative over F (D0.1), and J's own restructured sample renames fields and adds explicit MOVEs precisely because the qualifier-chain rule leaves the F-style moves unmatched. The group-as-alphameric fallback, its legality check, the two-verb scope and the subscript rule are all printed in the same section and must be implemented with it.

**Implementation.** Lands in the semantic analyzer (correspondence pairing over the data-description tree; subscript propagation), codegen (one move or add sequence per matched pair, in data-description order) and diagnostics. Diagnostics: an illegal group pair after the alphameric assumption is diagnosed — J names no message, so we emit msg 84 ("ILLEGAL MOVE - FROM 'NAME.1' … TO 'NAME.2' … NOTHING DONE ."), a design decision under D0.4; severity per Open Question 65. No diagnostic for an unmatched name in the default mode. --pedantic delta: an optional non-historical note listing names that matched nothing; excluded from listing-diff output.

**Oracle.** listing-diff against the object listing ([J 90.05] listing, PDF pp. 203–204 — the generated `CLA / TSX SYS)180,4 / PZE / TXI SYS)267,1,4 / OCT / AXT` sequences for statement 199,00, `MOVE CORRESPONDING GRAND.TOTALS TO PAYRECORD`, whose source text is at PDF p. 196). Manual example ([J 02.04.04]–05 examples a, b, c and the subscripted form). Decision-conformance only for the msg 84 choice on an illegal group pair, and for ADD CORRESPONDING, which the sample does not exercise with the option.

**Amended (M3 stage 2, 2026-08-04).** The Implementation sentence "an optional non-historical note listing names that matched nothing" is concretized one level up. Msg 944,00 (`NO -CORRESPONDING- NAMES MATCH. ACCEPTED. (NON-HISTORICAL.)`) fires once per clause, and only when the clause produces no pairs at all — the Decision's "moves that match nothing." A partially matching clause draws nothing in either mode. The sample attests partial mismatch as normal J style: the 90.05 CORRESPONDING clauses leave names unmatched, and the restructured sample moves them explicitly — `MOVE CORRESPONDING GRAND.TOTALS TO PAYRECORD` is followed at once by `MOVE GRAND.TOTALS HOURS TO PAYRECORD HRS`, because PAYRECORD's field is HRS, not HOURS ([J 90.05] listing PDF p. 196). A per-name pedantic note would flag that attested style; the clause-level note flags only the F-style latent defect the Decision names. An unnamed level contributes no qualifier: correspondence sees through it to the nearest named descendants.

*Citations:* ([F p. 43], p. 93; [J 02.04.03]–05; [J 90.05] listing PDF pp. 195–196); Attested rules added: ([J 02.04.04]–05 c, subscript rule; [J 90.04.01] msg 84; [J 90.05] listing, PDF pp. 196, 203–204)

### D4.13 — CALL: non-unique old.name and qualified synonyms

**Status.** Locked.
**Decision.** CALL implements the J rule. The (old.name) written in a CALL must resolve to exactly one field: "The (old.name) in a CALL statement must be unique and may not be subscripted. This requirement is met if the (old.name) appears only once in the Data Description or if sufficient qualifiers are used to identify it uniquely." ([J 02.04.05] §5). If it names more than one field the CALL is rejected with msg 166 ("'NAME.1' IS NOT UNIQUE IN THIS SECTION.") and no synonym is created. The (old.name) may not be subscripted: both `CALL (A(J))B.` and `CALL (A(3))B.` are rejected ([J 02.04.05] §5; [J 90.01.01] i). Each synonym is a new unique simple name for exactly one field. A synonym may not be qualified: a qualified reference whose last name is a synonym is diagnosed with msg 101 ("'NAME.1' IS AN IMPROPERLY QUALIFIED NAME."). That prohibition is a design decision under D0.4, amendable — the entry's Resolution says only that a synonym is "never needing qualification", and Open Question 56 leaves the question open in terms ("May it be qualified at all?"). F-style shared renaming (one synonym covering a homonym group, later disambiguated by a qualifier) is therefore a compile-time error under this decision, not a supported form. J's advice that "The use of record.names should be avoided in CALL statements" is advisory only: no diagnostic in the default mode; it is a candidate --pedantic note.

**Rationale.** The uniqueness rule and the subscript prohibition are stated together at [J 02.04.05] §5, and [J 90.01.01] i repeats the subscript prohibition with its two erroneous examples. J's sample never qualifies a synonym, and J governs over the F sample's looser 1960 usage (D0.1). J states no reaction for a qualified synonym reference, so both the prohibition and the choice of msg 101 are decisions.

**Implementation.** Lands in the symbol table / name resolver (CALL processing, subscript rejection on the (old.name), synonym entries marked non-qualifiable) and diagnostics (msgs 101 and 166 texts per [J 90.04.01]; severity per Open Question 65). If Open Question 56 is ever resolved the other way, the change is confined to the resolver's synonym flag. --pedantic delta: an optional non-historical note for a record.name used as an (old.name); excluded from listing-diff output.

**Oracle.** listing-diff against the source-program listing ([J 90.05] listing, PDF p. 195 — the sample's CALL entries and the clean compilation); decision-conformance only for the three rejection paths (non-unique (old.name), subscripted (old.name), qualified synonym).

*Citations:* ([F p. 59], pp. 91–94; [J 02.04.04]–05; [J 90.01.01] i; [J 90.05] listing PDF p. 195); ([J 02.04.05] §5 for uniqueness and the subscript prohibition; [J 90.04.01] msgs 101, 166); Open Question 56 ([F p. 59]; [J 02.04.04]–05)

### D4.14 — "Integer" against a trailing-S scaled field

**Status.** Jack's call.

> **Resolved by Jack, 2026-08-04** (the PR #60 review round). Entry 8.5.4-n joined the catalog that day, two days after the D1–D8 walk, so the walk holds no record for it. This record back-fills the slate on 2026-08-16. It changes no decision: it binds what the 2026-08-04 call decided and what M3 stage 2 already implements.

**Decision.** "Integer" carries two senses. The subscript sense is mechanical: a subscript variable with fraction or scale positions is rejected with msg 31, and a trailing-S scale is rejected with the rest. FIND/PLACE LENGTH IN takes the same sense: msgs 111/112 name the format ("IMPROPER DATA FORMAT"), and a scaled field cannot state an arbitrary length. The assigned GO TO index takes the value sense: a trailing-S field passes, because its values are whole; msg 130 fires only on true fraction positions, and the integral part serves. Code generation indexes by the raw stored digits and never adds a scaling step.

**Rationale.** The attested lookup indexes by the raw stored digits with no scaling step (`LDQ POS / MPY CP)+13` — [J 90.05] listing, PDF p. 213, LOC 01421–01432), and [F p. 75] has the subscript "used within the system to count individual items", so the stored digits must equal the value. A trailing-S field stores a scaled fraction of its value (`999SSS`: a thousandth — [F p. 80]), so its stored digits do not. [F p. 49]'s assigned GO TO rule speaks only of the index's value ("the value of the index will always be an integer in the range 1 to n"), which a trailing-S field satisfies; msg 130's recovery clause has nothing to truncate there. No field in either manual is declared with `S`, so the case is unattested. The definition's §8.5.4-n holds the evidence trail.

**Implementation.** Landed with M3 stage 2 (M3-20, "Subscript reference checks", `docs/design/m3-data.md`): msg 31 bars a trailing-S subscript variable, and the transfers triage passes a trailing-S assigned GO TO index. M4 code generation must index by the stored digits and never invent a scaling step.

**Oracle.** decision-conformance only: no field in the 90.05 sample carries `S`, so the listing-diff is silent on every branch.

*Citations:* ([F p. 31], p. 49, p. 75, p. 80; [J 90.04.01] msgs 31, 111, 112, 129, 130; [J 90.05] listing PDF p. 213); §8.5.4-n; M3-20 (`docs/design/m3-data.md`)

## D5 — Control flow (§8.5.5)

### D5.1 — DO … FOR termination is an equality test

**Status.** Locked; amended 2026-08-05 — the pre-committed decode was performed and the magnitude exit adopted (see the amendment below).
**Decision.** Compile `DO rtn FOR i = p(q)r` as the literal F expansion. Set i = p, then transfer to the procedure, so the body always runs at least once. On each return, add q to i and test for the exit. Adopt the entry's strict-equality exit — exit only when i = r exactly — as a **provisional** decision: the one surviving compiled DO FOR cannot discriminate an equality exit from a magnitude exit, and its instruction shape points the other way (see rationale). Emit no bound test at the loop head, no object-time range check, and no diagnostic for a step that cannot reach r, a zero or negative step, or p > r. Under the equality reading such a loop does not terminate, and the emulator reproduces that non-termination. Pre-committed amendment (not hypothetical — the counter-evidence is already in hand). During listing-diff, decode the GN)085/GN)086 increment block of statement 206,00 instruction by instruction. If it forms r − i (or i − r) and branches on sign, the exit is a magnitude test. Oracle 1 then wins over F's expansion under D0.3, and this record flips to `loop while r − i >= 0`. The overshoot, zero-step and p > r cases then terminate instead of looping forever. Either way the emitted loop-head and back-edge instructions must match the 1962 listing for statement 206,00. Index value on exit: i holds r at normal exit, as a consequence of the adopted expansion. Open Question 37 covers two further points: whether the field-test object code leaves it so, and what it holds after a GO TO abandons the loop (the J sample copies INDEX to POS before exiting). Our value after an abandoned loop is whatever the last increment left — a recorded decision, not attested behavior.

**Rationale.** [F pp. 50–51] define the loop by its macro expansion with an equality test after the body, and J confirms execution "regardless of the values of the loop control variables" while recording no object-time checks. The 90.05 listing confirms the body-first shape only: the DO FOR plants its return at the generated loop-increment label GN)086, and the back edge re-enters SEARCH+1 without re-executing the SXA. It does not confirm the equality test, and pulls against it — Open Question 40 records that back edge as `00721 TPL GN)085` ([J 90.05] listing, PDF pp. 206–207), a transfer-on-plus, i.e. a sign test, which is what a magnitude exit (`loop while r − i >= 0`) compiles to; an equality exit would branch on zero. With `INDEX = 1(1)12` both readings terminate identically, so the sample cannot decide the semantics; only a full decode of the increment block can.

**Implementation.** Parser: the DO FOR form. Codegen: loop prologue (four instructions of loop initialisation in the sample), increment-and-test block at a generated label, back edge. No diagnostics in default mode. Keep the exit test behind one codegen switch so the pre-committed amendment is a one-line change. --pedantic: optional non-historical warning when p, q and r are compile-time constants and (r − p) is not a whole multiple of q, or q is zero, or q has the wrong sign — useful under either exit reading. Cross-reference the shared DO linkage record in D5 (head cell `AXT 0`, `SXA P,4`, entry at P+1, `TRA* P`).

**Oracle.** listing-diff (statement 206,00 `DO SEARCH FOR INDEX = 1(1)12.`, [J 90.05] listing, PDF pp. 206–207), which also decides the equality-vs-magnitude question; decision-conformance only for the non-reaching, zero-step and p > r cases, and for the index value after an abandoned loop.

*Citations:* ([F pp. 50–51]; [J 90.01.02]); Open Question 40 ([J 90.05] listing, PDF pp. 206–207); Open Question 37 ([F pp. 50–51]; [J 90.05])

*Amended 2026-08-05 (M4 decision walk, `docs/design/m4-codegen.md` M4-13 — the pre-committed decode).* The statement 206,00 increment block is decoded: `CLA INDEX / ADD CP)+1 / STO INDEX / CLA CP)+13 / ADD PI)1 / STO PI)1 / CLA CP)+8 / SUB INDEX / TPL GN)085` at LOC 00711–00721 ([J 90.05] listing, PDF pp. 206–207), with CP)+1 = 1, CP)+8 = 12 = r, and CP)+13 the positional-indicator stride, all read from the printed pool. The block forms r − i after the increment and branches on sign — the exact shape this record named as the magnitude exit. The record flips as pre-committed: the generated loop exits on the first i > r (`loop while r − i >= 0`). A zero difference transfers, because equal magnitudes with unlike signs keep the original accumulator sign (external: 22-6528-4 p. 20) and the accumulator holds r, plus — so the body runs for i = r. Normal exit therefore leaves i at the first value past r — r + q when q divides r − p exactly — superseding this record's "i holds r at normal exit" sentence; the abandoned-loop value stands unchanged. Overshoot and p > r now terminate; a zero or wrong-signed q with p ≤ r still never terminates, and the emulator reproduces that. The equality reading stays one line away behind the codegen switch.

*Amended 2026-08-28 (M4 stage 2 chunk B8, `docs/design/m4-codegen.md` M4-13).* The `--pedantic` note of this record's Implementation is msg 946 (C1, non-historical). It fires for constant p, q and r unless q > 0, p ≤ r, and q divides r − p. "Wrong-signed" is read against the decoded exit: a negative q never steps toward r — with p ≤ r the loop never terminates, with p > r the body runs once — so a descending loop notes whatever the direction from p to r. A field-name parameter is not constant and draws nothing. The review record `review/2026-08-28-m4-b8-underdetermined` holds the rejected direction reading.

### D5.2 — Two-index DO: "index.name.1 is set to p.1 + q.1"

**Status.** Locked; amended 2026-08-05 — the exit test follows D5.1 as amended (see below).
**Decision.** Treat the outer index as incremented, not assigned. Implement up to three indices per DO, the rightmost varying most rapidly. Each time an inner loop completes, reset the inner index to its p and add its q to the next outer index; exit when the outer index equals its r. Do not read "set to p.1 + q.1" as an assignment of that sum. A fourth index takes msg 83,00 "INVALID FORM OF -DO- STATEMENT." — the attested general DO-form diagnostic; no message names the three-index limit specifically.

**Rationale.** The literal assignment reading freezes the outer index after the second pass, which contradicts F's worked HOURS/MINUTES/SECONDS example that must execute 60×60×12 times. The single-index expansion increments (`ADD q TO i`), and the phrase describes only the first increment. For the fourth index, an attested diagnostic fits the condition, so field-test-default fidelity prefers it to an invented one; msgs 76,00–78,00 stay with loop-control-variable and parameter format faults.

**Implementation.** Parser: the multi-index DO FOR list (max 3), msg 83,00 beyond it. Codegen: nested loop-control blocks, one increment-and-test block per index, innermost first. J neither documents nor defers the multi-index form; keep it implemented per F, because [J 90.01] lists deferrals explicitly. --pedantic: no delta.

**Oracle.** manual example ([F p. 51], `DO COMPUTATION FOR HOURS = 1(1)12, MINUTES = 1(1)60, SECONDS = 1(1)60.` must execute the procedure 43,200 times); otherwise decision-conformance only; diagnostic conformance for msg 83,00.

*Citations:* ([F p. 51]; [J 90.04.01] msgs 76–78, 83)

*Amended 2026-08-05 (M4 decision walk, `docs/design/m4-codegen.md` M4-13; the same decoded evidence as D5.1's amendment — the statement 206,00 increment block, [J 90.05] listing, PDF pp. 206–207).* Each index exits by D5.1's decoded magnitude test — on the first value past its r, not on equality. The sentence "exit when the outer index equals its r" is superseded the same way D5.1's equality sentence was. The increment-not-assignment reading, the reset rule, and the three-index limit stand unchanged.

### D5.3 — "Tests for NOT greater or less conditions" (unequal-length comparison)

**Status.** Locked.
**Decision.** Apply right truncation of the longer field to all four magnitude operators — GT, LT, NOT GT and NOT LT — when the two compared alphameric fields have unequal lengths. The lengths are made equal by truncating the longer field on the right, then the comparison runs on the equal-length images. `=` and `NOT =` keep the separate treatment of rule 2.b.i and are not truncated by this rule.

**Rationale.** [J 02.04.07] rule 2.b.i disposes of `=` and `NOT =` explicitly, so rule 2.b.ii must cover the remaining relations; reading it as "only the negated operators" would leave plain GT and LT with no length rule at all.

**Implementation.** Semantic analysis of relational conditions (operand length reconciliation), then codegen of the compare sequence and any SYS) compare helper. No diagnostic. --pedantic: no delta.

**Oracle.** decision-conformance only — the 90.05 sample contains no unequal-length alphameric comparison of any operator (Open Question 42). All five of its alphameric relations are equal-length and compile to inline `LAS` three-way compares, with SYS)162 never called in the program, so no listing evidence exists for this rule.

*Citations:* ([J 02.04.07]); Open Question 42 ([J 02.04.07]; [J 90.02.12]; [J 90.05] listing, PDF pp. 192–193, 195–197, 201–203, 204–205)

### D5.4 — GO TO out of a DO-addressed (closed) procedure

**Status.** Locked.
**Decision.** Permit a transfer out of a DO'd procedure — GO TO, conditional GO TO, assigned GO TO or an AT END GO TO — with no diagnostic. The closed-subroutine rule constrains entry only. Generate the attested linkage: the word at label P is the placeholder `AXT 0`; each DO plants its return with `SXA P,4` and enters at `P+1`; the procedure's terminal instruction is `TRA* P`. A transfer out abandons the planted return and leaves the head cell stale; the next DO of P overwrites the cell with its own `SXA`, so no cleanup code and no runtime guard are generated. Keep msgs 99 and 128 for flow or transfer *into* a DO'd procedure.

**Rationale.** Both flagship samples transfer out of a DO'd procedure and compile clean, while the only prohibitions J states concern entry. Open Question 40 shows the return lives in a per-procedure head cell that every DO rewrites before transfer, so a later DO re-establishes linkage automatically.

**Implementation.** Codegen (DO call site and procedure epilogue) and diagnostics (scope of msgs 99, 128). No object-time check that a return is pending. --pedantic: no delta; do not add a modern "transfer out of subroutine" error.

**Oracle.** listing-diff (`GO TO END.OF.RUN` from the DO'd END.OF.MASTERS, and the linkage triple plus `TRA* END.OF.MASTERS`; [J 90.05] listing, PDF pp. 195–197, 201–203).

*Citations:* (F pp. 50, 53, 57; [J 90.04.01] msgs 99, 128; [J 90.05] listing PDF pp. 195–197); Open Question 40 ([J 90.05] listing, PDF pp. 195–196, 201–203, 205–207, 210–213, 215)

### D5.5 — Assigned GO TO: object-time range behaviour

**Status.** Locked.
**Decision.** Split the two fault cases, because J and F speak to different ones. **Non-integer index:** msg 130,00 "TRANSFER INDEX NOT AN INTEGER. INTEGRAL PART TAKEN AS VALUE." governs — the integral part is used and the transfer proceeds. J outranks F for this sub-case, so F's blanket "no transfer will occur" does not apply to a fractional index. (Reading msg 130,00 as firing on an index.name whose declared format carries decimal places is our inference; the message text itself is attested.) **Out-of-range index** (integral value outside 1..n): F's fall-through applies — no transfer occurs and control passes to the next clause or sentence — implemented as a generated object-time range test. Record that test as a design decision, not as attested field-test behavior, because J documents no object-time check and adopts a no-object-time-checks policy for subscripts; provide a documented compiler option that omits it, so a future find of period object code can be matched without a language change. Keep msg 129,00 "FORMAT ERROR FOR TRANSFER INDEX. NOTHING DONE." for format faults.

**Rationale.** F states the fall-through semantics explicitly and J nowhere contradicts them for an out-of-range integral value, so F stands as the language definition there. For a non-integer index J does speak, and it does not suppress the transfer: msg 130,00 says the integral part is taken as the value. Folding integrality and range into one suppressing test would suppress transfers the attested compiler performs.

**Implementation.** Codegen: take the integral part of the index, then a bound test on that integral value before indexing the transfer vector, then fall through to the next clause. Diagnostics: msgs 129, 130 unchanged and kept in their attested roles. --pedantic: no delta. The check-omitting option is a build/compile flag, marked non-historical in both directions.

**Oracle.** decision-conformance only — `test/fixtures/90.05-payroll.ct` contains no assigned GO TO, so no listing evidence exists; diagnostic conformance for msgs 129, 130.

*Citations:* ([F p. 49]; [J 90.04.01] msgs 129–130; [J 90.01.02])

### D5.6 — SET condition.name under J

**Status.** Locked.
**Decision.** Implement `SET condition.name` per F. The statement stores the value associated with that condition-name into its conditional variable. Accept it in default mode with no diagnostic. Do not treat J's silence as a deferral. `SET condition.name` carries **no subscript** — [J 90.01.03]: "Neither a data item (literal) nor a condition.name may be subscripted. However, a conditional variable may be subscripted." When the conditional variable is subscripted there is therefore no attested way to name one element in this statement; that is Open Question 29 and stays unimplemented rather than invented. Our default is to reject a subscripted condition-name with a diagnostic marked non-historical, and to leave the element-setting semantics open pending evidence. (Ordinary data-manipulation verbs still address the subscripted conditional variable as a data item; that is our reading of the general language, not a J statement about condition-name setting.) Keep msgs 37 and 38 in force for conditional-variable and condition-name format faults.

**Rationale.** [J 02.04] is "Clarification and Amplification" and defers features only through 90.01, which does not defer this form; the COND machinery stays fully supported. But [J 90.01.03] forbids subscripting a condition.name outright, and the definition draws the consequence in terms — `SET condition.name` cannot designate one element of a subscripted conditional variable — so a compiler that accepted a subscript here would contradict J.

**Implementation.** Parser: the SET statement forms; reject a subscript on the condition-name. Data mapper: condition-name to (associated value, parent conditional variable, mode, length) — no subscript path. Codegen: a store of the associated constant into the variable, with the variable's own mode and length rules. Diagnostics: msgs 37, 38 as documented, plus our non-historical subscript rejection. --pedantic: no delta.

**Oracle.** decision-conformance only.

*Citations:* ([F p. 46]; [J 02.04.05]; [J 02.05.02]; [J 90.01.03]; [J 90.04.01] msgs 37, 38); Open Question 29 ([F p. 46]; [J 90.01.03])

### D5.7 — Nested and recursive DO

**Status.** Locked.
**Decision.** Accept nested non-recursive DO with no diagnostic and impose no depth limit of our own. Do not implement recursion and do not guard against it. If a procedure is DO'd while already active, directly or indirectly, the second `SXA P,4` overwrites the pending return: the outer activation's return is lost, and the terminal `TRA* P` returns to the inner return address. The emulator reproduces that behavior exactly — a loop or a wild transfer — with no runtime message. Generate no stack, save area or activation record; all working storage stays in the fixed `RS)`, `TS)`, `PI)` and constant-pool blocks.

**Rationale.** Nothing in either manual forbids a DO from a DO'd procedure, and sections nest to depth 18. Open Question 40 shows the return lives in one per-procedure head cell, and 90.02 shows no stack or save area anywhere, with index register 4 reused as data base register and scratch, so no return can survive re-entry.

**Implementation.** Codegen (call site and epilogue) plus emulator (no guard). --pedantic: static cycle detection over the DO call graph, reported as a non-historical error, clearly marked. Default mode stays silent.

**Oracle.** listing-diff for the linkage shape (head cell `AXT 0`, `SXA P,4`, `TRA P+1`, `TRA* P`; [J 90.05] listing, PDF pp. 202–203); decision-conformance only for recursive behavior.

*Citations:* (F pp. 50, 53; [J 90.01.05] f); ([J 90.02.01]–06, 90.02.11; [J 02.08.03]); Open Question 40 ([J 90.05] listing, PDF pp. 195–196, 201–203, 205–207, 210–213, 215)

*Amended 2026-08-28 (M4 stage 2 chunk B8, `docs/design/m4-codegen.md` M4-13).* The static cycle detection of this record's Implementation is msg 947 (C2, non-historical, `--pedantic` only). A DO — an `AT END DO` included — notes when its procedure can reach, through the DO call graph, the paragraph or section open around the call, itself included; one note per such call. The graph is the generator's own nesting state, static over the text.

## D6 — Input/output (§8.5.6)

### D6.1 — The PATTERN option — used but never defined

**Status.** Jack's call, 2026-08-02. It binds.
> **Resolved by Jack, 2026-08-02:** per D9.12 — bind the attested rules now and reserve the key word with the non-historical recognized-but-not-implemented diagnostic; adopt an invented, clearly-marked FILE-card syntax at M5 (option (a), deferred to D6/M5). GET RECORD FROM becomes usable when M5 lands that syntax.

**Decision.** Implement PATTERN as a FILE-card option that declares the repeating sequence of record.names on the file, so the compiler knows each record's successor without control words. PATTERN is the precondition for `GET RECORD FROM file.name`. Accept 1 to 16 record.names, with the attested diagnostics mapped one to one: an empty PATTERN takes msg 48,00 "NO RECORDS SPECIFIED IN -PATTERN- ON -FILE- CARD FOR 'NAME.1'."; exactly one record.name is accepted and warned with msg 49,00 "SINGLE RECORD IN THE -PATTERN- ON -FILE- CARD FOR 'NAME.1'. INEFFICIENT PROGRAM PRODUCED."; more than 16 takes msg 50,00 "NUMBER OF RECORDS IN -PATTERN- CANNOT EXCEED 16.". Message severities are unknown (Open Question 65: the listing prints 0 throughout and no assignment table survives), so ours are a recorded, non-historical assignment. The exact keyword syntax is unrecoverable (Open Question 44), so our surface form is an invented, documented and amendable decision: the FILE-card option `PATTERN record.name.1, record.name.2, … record.name.n`, following the same option grammar as the other FILE-card options. Every use is marked non-historical in our documentation.

**Rationale.** J makes `GET RECORD FROM file.name` legal only for files whose records "are included in a PATTERN in the Environment Description", and msgs 48–50 police the option, so the implemented compiler had it; the 02.06 FILE-card write-up simply lagged the implementation. Msg 49,00 shows a one-record PATTERN is accepted-but-warned, not rejected, so the accepted count is 1 to 16, not 2 to 16.

**Implementation.** Lexer/parser: FILE-card option list. Environment/data mapper: per-file pattern table of record.names and their order, consumed by the GET RECORD path in the SYS-IOC runtime for successor selection. Diagnostics: msgs 48, 49, 50 in the roles above, severities ours. --pedantic: no delta, but --pedantic may report any PATTERN use as non-historical syntax.

**Oracle.** decision-conformance only; diagnostic conformance for msgs 48, 49, 50 (message text attested, severity not).

*Citations:* ([J 02.07.04]; [J 90.04.01] msgs 48–50; [J 02.06.03]–07); Open Question 44 ([J 02.07.04]; [J 90.04.01] msgs 48–50); Open Question 65 ([J 90.04.01])

### D6.2 — FOR LABEL / LABELN linkage documented only by a missing appendix

**Status.** Locked.
**Decision.** Implement the language surface as defined — FILE-card `FOR LABEL statement.name`, `SPECIF LABELN`, and the LABEL type code redefining the 14-word area IOC)29 — and implement the runtime per the IOCS manual, which Open Question 46 recovers in full. **Attested (Q46, confidence certain):** the five-entry vector at MYLBLS..MYLBLS+4, each entered by `TSX vector+k,1`. Index register 2 holds the 2's complement of the File Control Block address. The label image is passed in the 14-word area, with no parameter words. All index registers used must be saved and restored by the called code. Returns are skip returns through index register 1 (`TRA 1,1`, `TRA 2,1`, `TRA 3,1`), so the caller reserves one alternate-return word after entry 1's TSX and two after entry 3's. Entry 2 sets the MQ sign (plus = EOR, minus = EOF). Entry 4 leaves the AC identifier (`1EORbb` / `1EOFbb`). **Inference (Q46), not recovered fact — the manual nowhere tabulates events against entries:** input open = entry 1; output open = entry 3 then 5; input reel switch = entry 2 then 1; output reel switch = entry 4 (`1EORbb`) then 3 and 5; output close = entry 4 (`1EOFbb`); input close = no call. The compiler generates the five-word vector and plants its address in the **ATTACH file-list decrement through IOC)5**, which is Q46's own recommendation; a direct store into FCB word 3 bits 3–17 through IOC)2 is the equivalent alternative that neither manual settles, and it is not our route. A documented event-code cell bridges the one named COMTRAN procedure to the five entry points; the FOR LABEL procedure tests it. Label-record length. The attested IOCS errors "(file name) NO LABEL, BLANK CREATED" and "(file name) NO TRAILER" are both raised when a label record "was not fourteen words in length". Q46 infers from them that J's "a label of 14 words or less" means the programmer may *use* fewer words of the area, not write a shorter record. We implement that reading, marked as inference. Card files: "Labeling is not available for files processed on any on-line card equipment" is attested; that our runtime therefore ignores the exit, with no compile-time diagnostic in default mode, is our decision. **Fidelity marker:** the event-to-entry mapping, the event-code cell, the one-procedure-to-five-entries glue, the 14-word-record reading and the card-file no-op are recorded design decisions or inferences, not recovered fact; only the IOCS calling convention and the return arithmetic are attested (D0.4).

**Rationale.** Open Question 46 recovers the IOCS calling convention verbatim from C28-6100-2 and the return arithmetic from the 7090 principles of operation, and marks its own event mapping and COMTRAN-side glue as inference and tentative. That split is exactly why J says portions of the FOR LABEL coding must be done in CRYPT — no COMTRAN statement can execute a skip return, set the MQ sign, or load a BCD identifier into the AC.

**Implementation.** Environment parsing (FILE card FOR LABEL, SPECIF LABELN), data mapper (LABEL type code over IOC)29), codegen (five-word vector, address planted via the ATTACH file list through IOC)5, event-code store, alternate-return words, index-register save/restore), SYS-IOC runtime (ATTACH file list, FCB word 3, standard label-error messages and sense-switch handling unchanged), emulator (tape label images). Diagnostics: msgs 92, 93 template for a missing name; no attested diagnostic for a card-file FOR LABEL. --pedantic: warn that FOR LABEL is inoperative on a card file and that the event-code interface and the event mapping are reconstructions. Sequencing: not needed for the 90.05 oracle; lands with the I/O milestone. Keep J's recommended safer alternative — labels defined as records processed with GET/FILE — in our documentation.

**Oracle.** decision-conformance only (the 90.05 sample uses no FOR LABEL, and Appendix 90.07 does not exist in this edition); the IOCS-side conventions are unit-tested against the C28-6100-2 text, and the inferred event mapping is unit-tested against our own decision only.

*Citations:* ([J 02.05.03]; [J 02.06.05], 02.06.12; J 00.00 contents; [J 90.02.08]; J publications p. PDF 221); Open Question 46 ([J 02.06.11]; [J 90.02.04]–05, 90.02.08; [J 90.08.01]; external: C28-6100-2, PDF pp. 29–34 / printed pp. 21–26, PDF p. 47 / printed p. 39, PDF pp. 68–69 / printed pp. 60–61, PDF pp. 73–76 / printed pp. 65–68; external: 22-6528-4, PDF/printed pp. 9, 10, 39); Open Question 45 (external: C28-6100-2, PDF pp. 29–32 / printed pp. 21–24, PDF p. 47 / printed p. 39)

### D6.3 — Reopening a file after a named CLOSE

**Status.** Locked.
**Decision.** Run `CLOSE file.name` through the same IOCS close path as any close, in F's stated order. **Output file:** (1) write any remaining information belonging to the file — the partial block is flushed; (2) write an end-of-file label containing the record count *if labels are specified*; (3) apply the file's close disposition; (4) release the storage area allocated to the file. **Input file:** (1) compare the record count with the count in the end-of-file label if label records are present and end of file has been reached, notifying through external display on disagreement, and ignoring the count if the tape is not at end of file; (2) apply the close disposition; (3) release the storage area. The close disposition is the file's \*SPEC close code, generated from SPECIF CLOSER/CLOSEW. The codes are U rewind and unload (the default when neither is given), R or blank rewind, N no rewind, and S no file mark or trailers and no rewind. J's option set refines F's plain "the tape is rewound", and J outranks F. Marking the File Control Block closed is our design decision. Treat a later OPEN of that file as undefined. In default mode the compiler gives no diagnostic for it — none is attested — and the emulated IOCS runs the ordinary open path against the closed FCB; the observable result of that path is a recorded design decision and is documented as unreliable. Reopening after `CLOSE ALL FILES` is forbidden by J: diagnose it when it is statically determinable; otherwise no object-time message, because none is attested — a runtime message for reopen-after-CLOSE-ALL-FILES is available only under --pedantic and is marked non-historical. `FILE` after CLOSE stays a defined no-operation.

**Rationale.** J forbids reopening only after CLOSE ALL FILES and says nothing about the named form, while F gives the named form's object-time steps in full and [J 02.07.01] defers to F for it. The named CLOSE therefore runs the same close path — including the buffer flush and the storage release — so a reopen is at best undefined and must not be relied on. The \*SPEC close codes are the implemented disposition set, so rewind is not unconditional.

**Implementation.** Parser (CLOSE forms), SYS-IOC runtime (close path in the order above, buffer flush, conditional trailer, \*SPEC close-code dispositions, buffer release, FCB closed flag), diagnostics (statically determinable reopen after CLOSE ALL FILES only). --pedantic: report any OPEN of a previously closed file as a non-historical warning, and add the object-time reopen message.

**Oracle.** decision-conformance only for the reopen behavior; the close path itself is unit-tested against [F p. 41]'s four output steps and three input steps and against the \*SPEC close-code table ([J 03.02.05]; [J 90.08.02]).

*Citations:* ([J 02.04.06]; [F p. 41]; [J 02.07.08], 02.07.01; [J 02.06.10]; [J 03.02.05]; [J 90.08.02])

### D6.4 — The printer as a direct FILE target

**Status.** Locked.
**Decision.** Implement FILE to tape, to cards, and to the system output unit. The demonstrated report path is the default: print-image BCD records FILE'd to tape and listed off-line. One record is one *or more* print lines. RCDMRK-type one-character record marks delimit the lines inside a record. The sample's CHECK record is a two-line check "to be printed under carriage control on a 720 printer", its two print lines "separated by a record mark (signalled by type RCDMRK) for printer control". The carriage-control character occupies the first character position of each line, described as a constant in the Data Description. Line length comes from the record description. A file whose unit assignment is a printer (PRX) or the system output unit (OU) is handled as a print-image file; extending the RCDMRK line-delimiting and first-character carriage-control convention to such a file is our design decision, since J defines no COMTRAN-level semantics (carriage control, line length) for direct on-line printing. Line length and carriage behavior beyond that come from the emulator's printer device, not from the language.

**Rationale.** [J 02.07.07] limits FILE to tape and cards, yet J's unit vocabulary carries PRX and OU and the sample routes every report file to BCD tape with RCDMRK; so direct on-line printing exists at the unit-assignment level while J defines no COMTRAN-level semantics for it. The sample also settles the record shape: carriage control is a data constant inside the record and record marks separate print lines, so a record is not one print image.

**Implementation.** Environment (unit assignment PRX / OU), codegen (FILE calling sequence unchanged), SYS-IOC runtime (blocking, and splitting a record at its record marks into print lines), emulator (printer and punch surface as print and deck files at the emulator boundary, per D0.7). No compile-time diagnostic for a printer-assigned file. --pedantic: warn that direct on-line printing has no J-defined COMTRAN semantics.

**Oracle.** listing-diff (the sample's report files and their FILE sequences, [J 90.05.03]) and report (the printed report, [J 90.05] listing, PDF p. 217 — which exercises the multi-line CHECK record end to end); decision-conformance only for direct PRX output.

*Citations:* ([F p. 40]; [J 02.07.07]; [J 02.06.09]–10; [J 90.05.03]–04; [J 02.05.03])

### D6.5 — GET on an unopened file: silent exit vs terminate-with-message

**Status.** Locked.
**Decision.** At object time, a GET on a file that is not open takes that GET's own end-of-file disposition. If the GET carries an AT END clause, execute the clause with no message. If it does not, take the standard no-AT-END path: the terminator routine SYS)265 prints the unexpected-end-of-file message and exits to the CT Monitor. Never emit a diagnostic that is specific to the unopened-file condition, at compile time or at object time.

**Rationale.** J's "the end of file exit is taken. No error message is given." denies a specific unopened-file diagnostic, not the generic no-AT-END termination that [J 02.07.06] states; the generated GET sequence carries exactly one end-of-file exit word, which holds SYS)265 whenever AT END is absent.

**Implementation.** SYS-IOC runtime: the IOC)8 read entry tests the FCB open flag and branches to the end-of-file exit held in the address field of the third calling-sequence word. SYS)265 handler prints the message and exits to the CT Monitor. No compile-time diagnostic. --pedantic: optional non-historical warning when a GET is reachable with no preceding OPEN of that file.

**Oracle.** decision-conformance only (the sample opens every file it reads); the calling-sequence shape it depends on is covered by listing-diff.

*Citations:* ([J 02.07.04]; [J 02.07.06]); Open Question 41 ([J 90.02.04], 90.02.29)

### D6.6 — AT END: "any imperative clause" (F) vs "a single imperative statement only" (J)

**Status.** Locked.
**Decision.** Parse exactly one imperative statement after AT END, per J. Accept the two attested forms `AT END DO name` and `AT END GO TO name`. Also accept a **bare procedure name** in the slot — Open Question 41 records it as plausible, msgs 92,00/93,00 are the same message template with literally bare-name operands, and J's own calling-sequence template calls the slot END-OF-FILE-PROCEDURE. Its semantics (call-and-return vs transfer) are unrecoverable, so we decide them: compile a bare name exactly as `DO name`, which is what the code generator already does and which converges with the not-end path on the sentence after the GET; record that choice as non-historical. Msg 106,00 "STATEMENT OR SECTION NAME MUST FOLLOW -AT END-. CHECK 'NAME.1'." keeps its attested role — it fires when the AT END slot is empty or is not headed by a statement/section name — and is never used against a bare name. Msgs 127,00/128,00 stay with bad GO TO targets and 188,00 with a bad DO operand. Accept any other single imperative statement with a low-severity, non-fatal diagnostic for J compatibility; that warning is a non-historical addition to the default mode (Open Question 41 recommends it; it is not attested behavior), so mark it as such in the listing and exclude it from listing-diff comparisons. Timing follows F: the clause fires on the GET after the last record was delivered. Codegen: put the AT END exit in the address field of the third word of the GET calling sequence, `PZE END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE`; compile the clause as an out-of-line block placed immediately after the calling sequence, its label planted in that word, and jump over the block with a normal-return `TRA` to the generated label that begins the next sentence's code. `AT END DO x` emits the identical DO triple `AXT *+3,7` / `SXA x,4` / `TRA x+1`, so a returning clause resumes at the sentence after the GET; `AT END GO TO x` emits a one-instruction block. With no AT END, plant SYS)265; with no ON ERROR on the file, plant SYS)283 in the decrement.

**Rationale.** J governs the parse; the generated code settles the mechanism, and Open Question 41 shows all four sample GETs use the same out-of-line block jumped over by a normal-return transfer, so a returning non-transfer clause would need no new machinery. Msg 106,00 and its 92/93 template family read as the field-test parser wanting a *designated procedure* in the slot, which is an argument for accepting a bare name, not for rejecting it; the earlier reading inverted the message. No manual sentence settles whether `AT END MOVE …` was accepted, so we accept it and diagnose at low severity, flagged non-historical.

**Implementation.** Parser: the AT END slot (DO form, GO TO form, bare name, other imperative). Codegen: GET calling sequence word 3, out-of-line block, generated labels GN)nnn, jump-over transfer; a bare name is lowered to the DO triple. SYS-IOC runtime: the SYS)265 and SYS)283 handlers. Diagnostics: msg 106 for an empty or non-name-headed slot; a new low-severity non-historical warning for a non-transfer clause; msgs 127, 128 and 188 keep their own roles for bad names inside GO TO and DO. --pedantic: raise the non-transfer clause to an error, reproducing the best reading of the field-test parser. Note the inversion: here --pedantic reproduces a *suspected* historical strictness, not a modern one, so mark it as such. Reproduce the printed mnemonic spellings as they stand (`IOCDN*` in the appendix template, `IOCTN*` in the listing).

**Oracle.** listing-diff (statements 188, 190, 191 and 194; object locations 00200–00207, 00222–00231, 00233–00240, 00277–00306; [J 90.05] listing, PDF pp. 201–202); decision-conformance only for the bare-name and non-transfer clauses.

*Citations:* ([F p. 40]; [J 02.07.05]–06; [J 90.04.01] msg 106); ([F p. 109]; [J 90.02.04], 90.02.29; [J 90.04.01] msgs 106, 127, 128, 188; [J 90.05] listing, PDF pp. 195–196, 201–203); Open Question 41 ([J 90.02.28]–29, 90.02.32; [J 90.04.01] msgs 92, 93; images/page-183.png, page-201.png, page-202.png)

### D6.7 — Short-record blocking and the BEGIN threshold

**Status.** Locked.
**Decision.** Implement blocking as arithmetic, with no threshold rule. Pack records into BLOCKSIZE-word blocks in order. A record must be complete within one block, so if the room left in the current block is smaller than the next record, start a new block. Two records that are each longer than half the blocksize can therefore never share one block; a single record longer than half the blocksize may still sit second in a block when the room left is large enough (J's own Example 1 packs REC3, 192 words, together with a 64-word REC1 in a 256-word block). A record described with BEGIN always starts a new block. No special rule keys off the 10-word or 20-word figures in the 90.05 note.

**Rationale.** [J 90.05.04]'s two statements — that the shorter DEPARTMENT.TOTAL records "will always begin a new buffer" in a 20-word-blocked file, while a 10-word record would need BEGIN "to avoid grouping" — both follow from complete-within-a-block packing, so no 02.06 rule is missing. The entry's gloss is that two such records cannot share a block; generalising it to "a record longer than half the blocksize always begins a new block" is false against J's worked example.

**Implementation.** Data mapper and Environment (BLOCKSIZE, BEGIN per record), SYS-IOC runtime (blocking on output, deblocking on input), and the compiler's buffer sizing and base locators (BL)n). Diagnostics: none new. --pedantic: no delta. Interacts with SPANS for records that exceed BLOCKSIZE; that case is Open Question 48 and is out of this unit.

**Oracle.** manual example ([J 02.07.09]–10 Example 1: REC1 64 / REC2 128 / REC3 192, BLOCKSIZE 256, no SPANS/HOLD/BEGIN → block J = REC1+REC1+REC2, J+1 = REC1+REC2 only, J+2 = REC3+REC1; [J 02.07.11] Example 2: BLOCKSIZE 128 with SPANS and BEGIN → blocks truncated to 64 words for REC1 and REC3 spanning 128 + 62 words). The definition says a compiler writer should treat these as acceptance tests for blocking/mode logic. Also listing-diff for PAYFILE's buffer sizing and base locators. Also report (end-to-end run of the sample must produce the 1962 printed report, [J 90.05] listing, PDF p. 217). Also manual example ([J 90.05.04]) for the 20-word and 10-word cases.

*Citations:* ([J 90.05.04]; [J 02.06.03]–04; [J 02.07.01]; [J 02.07.09]–11)

## D7 — Environment, control cards, and processor surface (§8.5.7)

### D7.1 — *SPEC blocksize "(0-999)" vs Environment maximum 9999

**Status.** Locked.
**Decision.** Honor Environment FILE BLOCKSIZE values up to 9999 words. The compiler punches the actual blocksize, right-justified, into the generated Loader *SPEC card's four-column blocksize field (columns 17-20, source "FILE - BLOCKSIZE nn", [J 90.08.02]). Read the Loader manual's "normally a number (0-999)" ([J 03.02.05]) as a typographical slip for (0-9999). For a value above 9999 the manuals attest no message: recorded design decision — reject the card with a non-historical diagnostic taken from a reserved message range above the historical 0-209 catalog, so the 1962 message numbers stay intact.

**Rationale.** The *SPEC field is four columns wide, so it can hold values above 999, and the Environment FILE card's own stated maximum is 9999. The entry's Resolution reads "(0-999)" as a typographical slip and directs the compiler to punch Environment blocksizes up to 9999. The 1962 listing shows the field in use (`*SPEC  01  300`), which fixes the punching format but not the above-999 case. Neither msg 91 ("NUMERIC INTEGER MUST FOLLOW -BLOCKSIZE- IN THE -FILE- CARD.") nor msg 209 ("HAS INSUFFICIENT BLOCKSIZE") covers an over-maximum value, so the diagnostic is our decision, not recovered fact.

**Implementation.** Lands in the data mapper (Environment FILE card processing) and codegen (Loader *SPEC card punching, columns 17-20, right-justified). No diagnostic for values 1000-9999. The over-9999 diagnostic is a recorded design decision; state plainly in the diagnostics catalog that J attests no such message. No --pedantic delta, since 9999 is the J-documented Environment maximum, not a relaxed rule.

**Oracle.** listing-diff for the *SPEC punching format ([J 90.05] listing, PDF p. 198, within the deck range 198-216); decision-conformance only for blocksize values 1000-9999 and for the over-9999 diagnostic

*Citations:* ([J 03.02.05]; [J 02.06.04]; [J 90.08.02]; [J 90.05] listing, PDF p. 198)

*Amended 2026-08-30 (M4 stage 3, `docs/design/loader.md` LD-1).* The blocksize punches right-justified in columns 17 to 20, and the 90.05 pairs reproduce PDF p. 198. The over-9999 diagnostic landed earlier, at M3: msg 931 (non-historical) in the environment binder.

### D7.2 — "SPECIF CHKS" in Appendix 90.08

**Status.** Locked.
**Decision.** Implement a single SPECIF checkpoint option pair, CHECKC and CHECKF, as documented at [J 02.06.11]. Read the token "CHKS" in the Appendix 90.08 *FILE-card table as a mislabeling of CHECKC in IBM's own text, not as a second compiler keyword to accept. Punch *FILE column 35 by the full conjunction the table states. Punch C when the FILE card carries CHECKPOINT and the SPECIF card carries CHECKC (printed CHKS). Punch F when the FILE card carries OUTPUT and the SPECIF card carries CHECKF together with LABELS or LABELN. Otherwise leave it blank, because "No check point will be written if neither option is exercised" ([J 02.06.11]).

**Rationale.** A page-scan check confirms the printed token is genuinely CHKS, so the error is IBM's. The entry's Resolution matches CHKS to CHECKC by meaning (checkpoint at reel switch on the checkpoint file), which exactly matches code C; CKSUMS (block checksums) already feeds column 34. The 90.08.01 table sources code C from "FILE CHECKPOINT AND SPECIF CHKS" — both conditions — and its sibling row is equally conditional, so the SPECIF option alone must not punch code C.

**Implementation.** Lands in the parser (Environment SPECIF option table: accept CHECKC and CHECKF only) and codegen (*FILE card column 35, [J 90.08.01]). Codegen must test the FILE card type and the SPECIF option together, not the SPECIF option alone. Note that CHECKF also requires a labeled output file to be operative ([J 02.06.11]). No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* ([J 90.08.01]; [J 02.06.11]; [J 02.06.04]; images/page-219.png)

*Amended 2026-08-30 (M4 stage 3, `docs/design/loader.md` LD-1).* Column 35 lands as decided: `C` needs CHECKPOINT and CHECKC together, `F` needs OUTPUT, CHECKF and a label. A checkpoint file's type column, 28, stays blank: [J 90.08.01] gives no character for it.

### D7.3 — Who assigns the default BUFFERCOUNT

**Status.** Locked.
**Decision.** Read the manual's mixed attribution as agency shorthand: the compiler computes and punches what it can, and the loader/IOCS performs the allocation — but the loader keeps real default and fallback logic of its own. Split the rules as J states them. (a) A POOL card with no BUFFERCOUNT gets a count assigned automatically by the compiler ([J 02.06.13]). (b) When no GROUP specifications are made at all, the compiler attempts to assign at least 2 buffers to each file ([J 02.06.14]). (c) For a GROUP with no BUFFERCOUNT, the loader attempts to assign at least twice the OPENCOUNT number of buffers to the GROUP. When the POOL BUFFERCOUNT or storage limitations prevent that assignment, the loader allocates the buffers beyond the minimum on the basis of the activity of the files in the GROUP ([J 02.06.14]). Our CT Loader must implement rule (c), including the activity-based fallback.

**Rationale.** The entry's Resolution keeps "the compiler computes and punches, the loader/IOCS allocates" as the reading of the mixed attribution, and that reading holds. It does not license the stronger claim that the loader computes no defaults: [J 02.06.14] gives the twice-OPENCOUNT attempt and the activity-based fallback to the loader in plain words. A runtime built without that fallback would not match the documented behavior. Activity reaches the loader through SPECIF ACTIVITY, punched in *SPEC columns 22-23 ([J 90.08.02]).

**Implementation.** Lands in codegen (POOL default BUFFERCOUNT computation; at-least-2-buffers-per-file default when no GROUP cards exist; Loader control-card generation) and in the CT Loader / SYS-IOC runtime (GROUP default of twice OPENCOUNT, plus activity-based allocation of the excess when the POOL BUFFERCOUNT or storage prevents it). The activity value comes from *SPEC columns 22-23. No diagnostic implications. No --pedantic delta.

**Oracle.** decision-conformance only — the 90.05 sample program declares no POOL and no GROUP, and the generated Loader control cards in the 1962 listing are only *FILE, *SPEC and *CTEXT ([J 90.05] listing, PDF p. 198); neither the *FILE card ([J 90.08.01]) nor the *SPEC card ([J 90.08.02]) carries a buffer-count field, so no oracle covers default buffer counts

*Citations:* ([J 02.06.13]–14; [J 02.06.02]; [J 90.08.01]–02)

### D7.4 — INCLUDE placement "at the end of the present program"

**Status.** Amended 2026-08-03. D9.8 supersedes the diagnostic choice. The rest binds.
**Decision.** Two parts, as the entry's Resolution gives them. (1) Do not implement INCLUDE. J defers its mechanization, so under the slate it is documented-but-unimplemented: INCLUDE stays a reserved word (it is in J's key-word list, [J 02.03.02]) and the parser recognizes it, but performs no subroutine insertion. (2) Record the F-faithful placement rule for the day INCLUDE is implemented: append included subroutines in encounter order after the last procedure sentence, consistent with the stated use of INCLUDE for closed subroutines "set off from the main flow" ([F p. 58]). The diagnostic is a recorded design decision, not history: J attests no INCLUDE message anywhere in the 90.04 list; the nearest attested message is msg 110, "-COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM." We emit a stated new message in the reserved non-historical range, worded on the model of msg 110, and we record that no historical message covers INCLUDE.

**Rationale.** The entry's Resolution is two-part, and the slate makes the placement rule the part that must be recorded rather than dropped: F-only features are documented, not deleted. [J 90.01.02] states the deferral, so no placement logic is built now. What the field-test compiler actually did with a recognized-but-deferred construct is unresolved (Open Question 64 asks exactly this, and is unannotated), so any diagnostic we emit is our decision.

**Implementation.** Lands in the parser (key-word recognition, [J 02.03.02]): INCLUDE is reserved and triggers the stated unimplemented-feature diagnostic. No data mapper or codegen work. Keep the F-faithful placement rule as a comment or design note against the day the verb is implemented. Whether the statement is skipped and whether it consumes a statement number remains open (Open Question 64) — pick and record a behavior, do not present it as attested. No --pedantic delta, since this is a feature-scope decision, not a strictness one.

*Cross-reference (2026-08-03):* superseded on the diagnostic choice by D9.8, which prescribes the attested msg 110 for an INCLUDE sentence rather than the separate non-historical message planned here (and answers Open Question 64: skipped, statement number consumed). The placement rule and the do-not-implement call stand.

**Oracle.** decision-conformance only

*Citations:* ([F p. 58]; [J 90.01.02]; [J 02.03.02]; [J 90.04.01] msg 110)

### D7.5 — Per-message severity codes are nowhere specified

**Status.** Locked.
**Decision.** Build a severity assignment covering all 210 diagnostic messages, using the method the entry's Resolution states: auto-repair warnings such as "PERIOD ASSUMED" and "ZERO COUNT… REPLACED BY ONE" get severity 1; deletions and "NOTHING DONE" conditions get 2-4; unrecoverable conditions (internal errors, table overflow, read errors) get 5. Model severity as a per-occurrence value carrying a per-message default, so an individual diagnostic site can raise or lower it — the manual says the code "may vary", which may mean one message carries different severities in different contexts. Document the whole assignment as a recorded design decision, never as recovered historical fact.

**Rationale.** The 90.04 listing prints CODE 0 for every message "because the value may vary", and no severity table survives (Open Question 65 records this as unresolved), so under the slate's evidence-bounded fidelity rule the assignment must be a stated decision. A per-message-only table would foreclose the context-varying reading inside the data model, which is hard to undo later; a per-occurrence value with a per-message default keeps both readings open at no cost.

**Implementation.** Lands in the diagnostics module: a message catalog with a default severity per message, and a severity field on each emitted occurrence. The value drives the documented downstream effects — severity 5 stops compilation and suppresses the object deck and the assembly listing; any severity above 1 suppresses automatic execution after compilation (see the SEVERITY LIMIT entry, this unit). No --pedantic delta, since no stricter historical alternative survives to gate.

**Oracle.** decision-conformance only

*Citations:* ([J 90.04.01]–02; [J 02.01.01])

### D7.6 — "SEVERITY LIMIT WAS NOT REACHED"

**Status.** Locked.
**Decision.** Implement a fixed, non-configurable severity threshold; no control card sets one. Two documented thresholds apply. (1) Severity 5: "An error severity code of 5 causes the compiler to stop compiling. It then proceeds to the next job." ([J 90.04.02]). No object deck is produced ([J 02.01.01]: "If the severity code is 5, a deck will not be produced."), and no assembly listing prints, since the listing appears only "if LIST was selected and no severe error was encountered during compilation" ([J 02.02.01]). (2) Any severity above 1 prevents automatic execution after compilation — the compiler will not compile and go ([J 90.04.02]; [J 02.01.02], which also names the NOGO option and an undefined generated symbol as separate bars to execution). Print the trailer "SEVERITY LIMIT WAS NOT REACHED" when compilation completes with no severity-5 error. The wording printed when the limit IS reached is unattested: recorded design decision — print "SEVERITY LIMIT WAS REACHED".

**Rationale.** The entry's Resolution reads the trailer as reporting against a fixed built-in threshold, and [J 90.04.02] states the severity-5 stop in plain words, so the stop is attested and not merely plausible. The second threshold is equally documented and an implementer needs both. Only the "NOT REACHED" wording is attested ([J 90.04.01], at the end of the appendix message listing), so its opposite is a decision. Whether a severity 2-4 error makes the punched deck unreliable, or only suppresses execution, stays unresolved (Open Question 66).

**Implementation.** Lands in the compiler driver and the diagnostics/listing module. Track the maximum severity seen. On severity 5: stop the compilation, punch no deck, print no assembly listing, proceed to the next job. On any maximum severity above 1: punch the deck but suppress automatic execution under LOAD. Print the trailer at end of listing, with the attested wording for the not-reached case and the stated decision wording otherwise. No --pedantic delta, since this is the attested default behavior.

**Oracle.** manual example (citation) — the trailer text is printed at the end of the 90.04 message listing ([J 90.04.01])

*Citations:* ([J 90.04.01]–02; [J 02.01.01]–02; [J 02.02.01])

### D7.7 — Internal-table limits are approximate

**Status.** Locked.
**Decision.** Size internal compiler tables at least as large as the figures printed in the 90.01.05 table, whose heading reads "Appox-Max Size" (sic). Treat those figures as guaranteed-safe minimum capacities, not exact ceilings. Diagnose overflow with the documented message numbers (148, 149, 172, 177, 183, 184, 200-205) at whatever the implementation's true internal capacity is, which may exceed the printed figures.

**Rationale.** The entry's Resolution takes the printed numbers as guaranteed-safe capacities, with enforcement at the true internal capacity. The sic'd heading is the whole reason the thresholds are unspecified, so quote it as printed, per the repository fidelity policy. Item a) of that table is the "Internal dictionary including all program names whether defined by the programmer or generated by the Compiler" (3500) — use the manual's term, not "symbol table".

**Implementation.** Lands in the parser, data mapper and codegen table-management code, with overflow diagnostics wired per table type: internal dictionary (3500), SECTIONS (35), edited field formats (35), base locators (127), QUANTITY IN specifications (25), nested-section depth (18), index expressions (50), positional indicators (90), array dimensions (85), data-hierarchy levels (23), constant pool (500). State the exact chosen capacities as a recorded design decision, since the manual gives no exact enforcement thresholds. No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* ([J 90.01.05]; [J 90.04.01])

### D7.8 — Which environment types msg 90 covers

**Status.** Locked.
**Decision.** Define the msg 90 criterion by effect, not by the presence of a dedicated diagnostic: emit msg 90 ("THIS ENVIRONMENT TYPE NOT YET PROCESSED BY COMPILER.") for Environment types whose specifications have no effect on the object deck — CONTRL is the documented case ([J 90.01.04]) — plus any type we ourselves defer. Msg 90 accompanies the normal format and name checks; it does not replace them. CONTRL cards are still parsed and name-checked (msg 207, "-CONTRL- NAME MUST BE UNIQUE AND 6 CHARACTERS OR LESS.", and msg 176, "-CONTRL- CARD FORMAT ERROR."). POOL, GROUP, OPTION, COND and SPECIF each have dedicated format diagnostics and so were at least parsed; they are not msg 90 types. "At least parsed" is the limit of the evidence — it does not prove they were fully implemented.

**Rationale.** The entry's Resolution names CONTRL as the documented case and reads msg 90 as covering CONTRL-like deferred types, hedging the other five as "at least parsed". A criterion phrased as "lacks its own dedicated diagnostic" fails on its own terms, since CONTRL has msgs 207 and 176; the workable test is whether the type's specifications reach the object deck.

**Implementation.** Lands in the parser (Environment Division type dispatcher) and the diagnostics module. A deferred type still runs its format and name checks and then also raises msg 90. Implemented types raise only their own format-check messages. Reuses the deferred-construct pattern of the INCLUDE entry, this unit. No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* ([J 90.04.01] msg 90; [J 90.01.04]; [J 02.06.02])

### D7.9 — Maximum alphabetic-constant length

**Status.** Locked.
**Decision.** Limit a single Data Description alphabetic constant to 120 characters. Recorded design decision, derived as follows: msg 148 ties a constant's length to internal table capacity, and the only stated capacity is the constant pool at approximately 500 generated constants ([J 90.01.05] k); we model that pool as 500 words of 6 characters each, and cap one constant at 20 words, about 4 percent of the pool. Diagnose overflow with msg 148 only ("LENGTH OF ALPHABETIC CONSTANT EXCEEDS INTERNAL TABLE CAPACITY AND SHOULD BE SUBDIVIDED."). Msg 150 is a separate rule with different text ("ALPHABETIC LITERAL EXCEEDS 50 CHARACTERS.") and applies to alphabetic literals, which the compiler limits to 50 characters independently.

**Rationale.** No independent numeric limit for alphabetic constants is stated, unlike the 50-character literal limit, so the entry's Resolution ties the practical cap to the shared constant-pool capacity that msg 148 already governs and asks for a documented generous limit. The whole purpose of the entry is to supply the missing number, so the record states one. Whether a pool "constant" is counted as an entry or as a word is not stated; the word model is our stated modeling assumption, chosen because msg 148 speaks of length, not of count.

**Implementation.** Lands in the data mapper (Data Description alphabetic-constant handling): reject a constant longer than 120 characters with msg 148. Keep the 50-character alphabetic-literal check separate, with msg 150. State both the 120-character figure and the 6-characters-per-word pool model as recorded design decisions, since no exact figure is documented. No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* ([J 90.04.01] msgs 148, 150; [J 90.01.05]; [F p. 18])

### D7.10 — File Check Table: listed in the deck format, never produced

**Status.** Locked.
**Decision.** The object-deck writer punches no card of deck type 010 (control break table) and no card of deck type 011 (file check table) — not even empty section headers. [J 90.01.04] records the field-test reality in plain words: "CONTRL specifications will have no effect on the object deck produced by the Compiler, i.e., no control break table is punched" and "No file check table is produced in the object deck." The 90.03 format keeps both section types defined, and absence is legal at the format level: "Any section except the text can be missing under certain conditions" ([J 90.03.01]). Read the entry's "the slots exist, empty" as format-level definition, not as emitted cards. Our CT Loader must accept a deck in which both sections are absent.

**Rationale.** The entry's Resolution distinguishes the designed deck format (02.02, 90.03) from field-test reality (90.01). Fidelity to the designed format means keeping the section types defined in our deck model, not punching cards the historical compiler never punched. The 1962 listing settles it: the loader-control-card page shows only *FILE, *SPEC and *CTEXT cards, with *CTEND closing the binary deck. Punching empty 010 or 011 sections would add cards that are not in the sample and would fail oracle 1, the deck diff.

**Implementation.** Lands in codegen (object-deck writer): emit Symbolic Control cards, *CTEXT, the Relative Binary Program Deck text section, and *CTEND — no 010 and no 011 section. Lands in the CT Loader, which must load a deck with both sections absent without error. No diagnostic implications; no --pedantic delta, since this is attested field-test behavior to preserve by default.

**Oracle.** listing-diff ([J 90.05] listing, PDF p. 198 shows *FILE / *SPEC / *CTEXT only)

*Citations:* ([J 02.02.01]; [J 90.01.04]–05; [J 90.03.01]; [J 90.05] listing, PDF p. 198)

*Amended 2026-08-30 (M4 stage 3, `docs/design/loader.md` LD-2 and LD-3).* Landed: the deck writer punches the text section alone, and the loader refuses a card of deck type 001, 010 or 011 rather than skip it. It accepts the sections' absence, as this record requires, and nothing more.

### D7.11 — Deck.name with imbedded blanks

**Status.** Jack's call, 2026-08-02. It binds.
> **Resolved by Jack, 2026-08-02:** the departure is confirmed — default mode accepts silently (the attested field-test behavior, D0.8); --pedantic warns. The definition's §8.5.7 entry is deliberately left unannotated: its evidence is unchanged and the definition stays design-free, so this record is the design supersession of its "at minimum warn" sentence.

**Decision.** In default mode, reproduce the field-test compiler's attested lenient behavior exactly: accept a deck.name containing imbedded blanks with no compile-time diagnostic, and punch it verbatim into columns 1-6 of all generated Loader symbolic control cards. Our CT Loader then implements the documented downstream failure — it refuses execution of the object program for a deck.name of this form ([J 90.01.05] B.5). Leading blanks are a separate matter and are simply ignored by the compiler ([J 02.01.01]); only imbedded blanks are at issue. In --pedantic mode the parser emits a compile-time warning, since [J 02.01.01] states the name "must not include imbedded blanks".

**Rationale.** [J 90.01.05] B.5 is a directly attested instance of the pattern the slate designates for default-mode reproduction: the compiler "accepts without comment" an illegal construct and the failure appears later, at load time. This is the slate's own worked example (the omitted procedure-name period) applied to a different construct, so it takes precedence over the entry's "At minimum warn" Resolution for default mode; the warning moves to --pedantic mode. Because this is a deliberate departure from a written Resolution, the owner should see it and §8.5.7's Resolution should be amended rather than left in conflict with the decision record.

**Implementation.** Lands in the lexer/parser (deck.name scanning: strip leading blanks, keep imbedded blanks, no diagnostic in default mode), codegen (punch the name verbatim into columns 1-6 of all Loader symbolic control cards), and the CT Loader (execution-time refusal). --pedantic mode adds the compile-time warning only.

**Oracle.** manual example (citation)

*Citations:* ([J 02.01.01]; [J 90.01.05])

*Amended 2026-08-30 (M4 stage 3, `docs/design/loader.md` LD-1 and LD-3).* Landed on both sides: the cards carry the name verbatim in columns 1 to 6, and the loader refuses a deck whose `*CTEXT` deck.name has an imbedded blank.

### D7.12 — *COMPILE vs $CMPLE

**Status.** Locked.
**Decision.** Implement $CMPLE as the documented compilation-initiating control card, per [J 02.01.01]. Additionally accept *COMPILE as a historical synonym, with the limits the evidence sets. The LIST option and the identification field carry over: column measurement puts LIST at card column about 16 and the identification at about 55, the same columns the 1962 $CMPLE card uses. The verb field does not carry over. *COMPILE occupies columns 7-14, so the 1961 card cannot have held deck.name in $CMPLE's columns 8-13. Accept *COMPILE with its LIST option; where deck.name sat on the 1961 card is unresolved, so our reader takes it from the same relative position it occupies on $CMPLE and records that as a decision.

**Rationale.** The entry's Resolution identifies *COMPILE as the earlier spelling of the same card, with LIST behaving identically, and says to implement per $CMPLE while optionally accepting *COMPILE. Open Question 70 narrows this: LIST and the identifier columns carry over, the verb field does not, and the full 1961 option set is unrecovered. Treating the two cards as byte-identical would overstate the evidence.

**Implementation.** Lands in the lexer/parser (control-card recognition): *COMPILE is an alias verb token for $CMPLE with the same option processing for LIST. Record the deck.name-position choice as a design decision and mark Open Question 70 as the source of the remaining uncertainty. No --pedantic delta.

**Oracle.** manual example (citation) — the *COMPILE LIST echo is attested on the sample source-listing page ([J 90.05] listing, PDF p. 192), outside the deck range (PDF pp. 198-216) that oracle 1 diffs; accepting the card is required only if our test reproduces the sample's source listing, not by the deck diff itself

*Citations:* ([J 02.01.01]; [J 90.05] listing PDF p. 192)

### D7.13 — Statement-number placement

**Status.** Amended at M1, 2026-08-03. The amendment note holds the change.
**Decision.** Assign and print the statement number for the source card the compiler's scan is standing on, not strictly once per logical Procedure sentence, Data Description entry or Environment card. The field holds three to six digits; the last two are separated from the preceding digits by a comma and tell which clause is referenced, while the digits before the comma tell which line is referenced ([J 02.02.01]). This permits a number to appear mid-sentence, and two sentences to share one number, as the sample listing shows. One value is reserved: statement number 9999,99 references errors which are not confined to a single source statement.

**Rationale.** The entry's Resolution reconciles the manual's per-sentence phrasing, which it calls loose, with the sample listing's mid-sentence and shared numbers, by tying the number to the physical card the scan stood on. [J 02.02.01] states the digit structure and the 9999,99 exception in plain words, and a listing generator has no way to number whole-program errors without it.

**Implementation.** Lands in the lexer (per-card tokenization drives number assignment) and the listing generator (prints the number at the point the scan reaches each card, in the form xxxxx,00; three to six digits, two after the comma). Reserve 9999,99 for diagnostics not confined to a single source statement. Non-zero clause digits are unattested in a real error listing, since the sample compiles clean (Open Question 71) — record our clause-numbering rule as a decision.

**Oracle.** listing-diff

**Amended (M1, 2026-08-03).** The mid-sentence and shared numbers this record read in the sample listing were an artifact of the transcription. On PDF p. 197 the printer's half-line stagger shifted the statement numbers of 218,00–221,00 and 228,00 one line down. The scan-corrected grouping (docs/design/m1-front-end.md, M1-14) maps every statement number to exactly one Procedure sentence, Data entry, or Environment specification group. Each number is printed on the unit's first card, with continuation lines blank. M1 implements that per-unit rule; the 9999,99 reservation and the n,cc form stand unchanged.

*Citations:* ([J 02.02.01]; [J 90.05] listing PDF pp. 196–197)

## D8 — Transcription and printing artifacts (§8.5.8)

### D8.1 — Collating-sequence special characters — resolved by scan (2026-08-01)

**Status.** Locked.
**Decision.** Implement the five machine special characters with their scan-confirmed glyph shapes and their period-source card codes: ⟨+0⟩ = Plus Zero, card 12-0; ⟨−0⟩ = Minus Zero, card 11-0; ⟨rm⟩ = Record Mark, card 0-2-8; ⟨gm⟩ = Group Mark, card 12-5-8 (not 12-7-8, which is the 1401's group-mark code). The names Plus Zero, Minus Zero, Record Mark and Group Mark are confirmed by period IBM print. The fifth character is confirmed by 705 code `0 11 1100` / card 12-4-8 and by glyph shape (a hollow ring with four corner spurs), but no period IBM source found names it: "lozenge" and the legend label ⟨loz⟩ are a recorded inference of this project, not a documented IBM name. The lexer accepts these five glyphs only inside literals and constants, and rejects them elsewhere in source text. Implement two collating sequences, exactly as §1.1 prints them ([J 02.06.16]). Native 709/7090, lowest to highest: 0 through 9, =, ', +, A through I, ⟨+0⟩, ., ), −, J through R, ⟨−0⟩, $, *, blank, /, S through Z, ⟨rm⟩, ,, ( — thus LOW.VALUE = `0` and HIGH.VALUE = `(`. Commercial (705), selected by COLLATE COM on an Environment OPTION card, lowest to highest: Blank, ., ⟨loz⟩, ⟨gm⟩, &, $, *, −, /, ,, %, #, @, ⟨+0⟩, A through I, ⟨−0⟩, J through R, ⟨rm⟩, S through Z, 0 through 9 — thus LOW.VALUE = blank and HIGH.VALUE = `9` ([J 02.04.01]). Comparison, collation and figurative-constant logic select the table from whether COM is in effect. Where COM is in effect, use J's printed order, not the IBM 705 pocket card's order (which puts '&' before the period and puts '−' where J has '&').

**Rationale.** The 2026-08-01 scan pass re-read the page-050 displays at 600 dpi with independent verification, so the glyph shapes and both printed sequences are certain, as are the native and COM endpoints (`(` highest and `0` lowest natively; blank lowest and `9` highest under COM). The 2026-08-02 external pass settles four of the five names and, between the three period IBM sources, prints card codes for all five glyphs; the 12-4-8 character is left unnamed in every source found, so its name stays an inference. The J-versus-pocket-card ordering difference is recorded as an inference: J's COM reading and the divergent card positions are both scan-verified and legible, from which we infer a genuine ordering difference between the machine chart and J's printed COM sequence, not a transcription error in J. Under J-authority the printed COM order governs in either case.

**Implementation.** Treat §1.1 of the definition as the authoritative table for both sequences and for the ⟨⟩ glyph legend; do not re-transcribe the sequences from the divergence paragraph, whose glyphs (⁺0, ō, ‡) are the pocket card's, not J's. Lexer: recognize the five specials only in literal and constant contexts; emit a syntax diagnostic elsewhere. Data mapper and codegen: card-code table for these glyphs when they are punched into literals or constants; note that card code 12-4-8 is the right parenthesis `)` in Set H, which the source language uses, and the lozenge glyph in the 705 set, so card-code-to-glyph mapping must be set-relative ([F p. 12] and its note 1). Emulator and runtime: two comparison tables, selected by the COM option; figurative constants HIGH.VALUE/LOW.VALUE take their values from the sequence in effect (§1.7.4). No --pedantic delta; the resolved items here are factual, not leniency questions.

**Oracle.** decision-conformance only

*Citations:* ([J 02.06.16]; [J 02.04.01]; [F p. 12]; images/page-050.png; external: A22-6506-0, © 1959, PDF p. 8 / printed p. 8; external: Form 22-6642-0, undated, front and back panel; external: A24-1403-5, Apr 1962, printed p. 170 / PDF p. 184)

### D8.2 — External Decimal row of the J field-type chart

**Status.** Locked.
**Decision.** Implement the External Decimal "Legitimate Format Characters" set as: 9, the count specifier (n), S, V — plus the overpunched 9 (the minus- and plus-overpunch glyphs, `9̅` and `9⁺` under the conversion's zone-rendering convention, amended 2026-08-04), which J's chart permits only as the rightmost character of the field. Whether the field-test compiler diagnosed an overpunched 9 in any other position is unattested; by recorded design decision this compiler diagnoses it as a Data Description format error.

**Rationale.** The transcribed cell was a run-together reading of a ruled chart; parsed as 9, (n), S, V with the two overpunch glyphs restricted to the rightmost position, the reading is consistent with the chart's own note 1 and with the parallel Edited-field cell on the same page. The permission is documented; the diagnostic is not, so it is stated as a decision rather than as a documented rule.

**Implementation.** Data Description parser and data mapper: enforce rightmost-only placement of the overpunched 9 in External Decimal field descriptions. Cite the chart ([J 02.05.05]) as the source of the placement rule, not a message number — no 90.04.01 message has been identified for this case; if one is later identified, use it. No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* ([J 02.05.05] and conversion note; images/page-031.png)

### D8.3 — The "IR999" mode example — resolved by scan

**Status.** Locked.
**Decision.** Read the disputed first character as the letter I, not the digit 1. Concrete consequence: mode specifications take the letter I (internal), so the lexer accepts `IR999` as mode = I (internal), justification = R (right), pictorial = 999, and the digit 1 is not a mode character. No behavior changes relative to what [J 02.04.05] and [J 02.05.04] already document.

**Rationale.** Visual measurement at 400 dpi settles the reading: the digit 1 in this proportional face carries a top-left flag and runs 11-13 px wide, the letter I is a bare 9-px stem, the disputed glyph is a bare 9-px stem, and the reserved word UNIT1 on the same page supplies both forms as an internal control. The internal-mode semantics (I = internal, R = right justify, 999 pictorial) come from [J 02.04.05] and [J 02.05.04], so they are corroboration, not the basis of the reading.

**Implementation.** Lexer and Data Description parser: accept the letter I as the internal-mode prefix in a mode-plus-pictorial specification; reject the digit 1 in that position. No other module is affected.

**Oracle.** decision-conformance only

*Citations:* ([J 02.03.03]; [J 02.04.05]; [J 02.05.04]; images/page-015.png)

### D8.4 — Stray "nj." in the Input FILE general form — resolved by scan

**Status.** Locked.
**Decision.** No compiler-facing decision; recorded as a resolved transcription matter. The mark is `nj` only — the trailing "." the conversion transcribed is an 8-pixel dust speck, not type. Neither `nj` nor a period is a token of the Input FILE form: the parser's Input FILE grammar gets no token, keyword or option for either, and both are given zero representation in the lexer and the parser.

**Rationale.** The scan confirms `nj` is genuine typed ink and not bleed-through (show-through and set-off print mirrored, and the 1-bit scan cannot carry faint ghosts), but its origin is unrecoverable (stray keystroke, abandoned annotation, or erasure remnant) and it maps to no documented FILE-form option. The trailing period is a fraction of the ink of a real period on the same line.

**Implementation.** None — confirms the Input FILE grammar ([J 02.06.03]) is implemented exactly as otherwise documented, with no `nj` token and no period after `,record.name.1`.

**Oracle.** decision-conformance only

*Citations:* ([J 02.06.03]; images/page-037.png)

### D8.5 — Missing comma before record.name.2 in the Input FILE form — print confirmed by scan

**Status.** Locked.
**Decision.** In the default (field-test) mode, the Input FILE clause accepts record.name.2 with or without a leading comma, and emits no diagnostic when the comma is absent. The printed Input form shows no comma, the printed Output form shows `[ ,record.name.2 . . . ]`, and the field-test compiler's actual treatment is unattested, so the default mode accepts both. Under --pedantic, require the comma in both forms, consistent with every other 02.06 option.

**Rationale.** The scan confirms the asymmetry is exactly as transcribed: nothing of comma size inside the Input form's bracket at 400 dpi, a full-size comma in the Output form. The entry treats the comma as "required (or at least accepted)" in both and calls the asymmetry almost certainly a layout accident of the printed box. Because no evidence says whether an omitted comma was diagnosed, the lenient reading is the default per the slate's field-test rule, and the strict reading goes behind --pedantic.

**Implementation.** Parser, Environment Description FILE clause ([J 02.06.03]-04): make the leading comma before record.name.2 optional in the Input form and accepted in both forms; no new diagnostic message in default mode. Add one --pedantic diagnostic for the omitted comma. This changes the grammar definition only.

**Oracle.** decision-conformance only

*Citations:* ([J 02.06.03]-04; images/page-037.png)

### D8.6 — 90.08 density table sources both H and L from "HIGH" — print confirmed by scan

**Status.** Locked.
**Decision.** Implement the SYS)/IOC) tape-density table so that L (SPECIF LOW) sources the LOW density value and H (SPECIF HIGH, also the default when SPECIF is omitted) sources the HIGH density value — correcting the original table's printing defect rather than reproducing it bit-for-bit.

**Rationale.** The scan shows the two source cells are geometrically near-identical impressions of the word HIGH (0.87 pixel overlap after 1-px alignment), while the correctly printed LOW elsewhere on the same page is visibly narrower and differently shaped, which excludes a faint or damaged LOW and confirms a genuine 1962 printing error rather than an intended L=HIGH mapping. SPECIF LOW/HIGH semantics from [J 02.06.10] require L to mean LOW, and density is assumed HIGH if no specification is made.

**Implementation.** SYS)/IOC) runtime: density-selection logic keyed off the SPECIF card's LOW/HIGH option ([J 02.06.10]), defaulting to HIGH when SPECIF is absent. This is a case where the evidence points away from literal bit-faithfulness to the defective print, per the slate's evidence-bounded fidelity policy. No --pedantic delta.

**Oracle.** decision-conformance only

*Citations:* ([J 90.08.01]; [J 02.06.10]; images/page-219.png)

### D8.7 — Message 187's garbled tail — resolved by scan: a defect of the original 1962 listing, not the conversion

**Status.** Locked.
**Decision.** Message 187 spans two print lines. Line 1 is "CONDITIONAL EXPRESSION TEST CAPACITY EXCEEDED." Line 2 as printed is "REWRITE AS TWO OR MORE SEPARATE EXPRESSIONS, EACH WITH ILLEGAL SENTENCE STRUCTURE NOTHING DONE." — in which 187's own wording stops mid-phrase after "EACH WITH", and the last 40 characters are message 196's text, which the 1962 message-print routine ran on into. The true remainder of 187's wording is unrecoverable. The compiler therefore emits the attested printed text verbatim, run-on tail included, in the default mode. No completion is invented and no "clean" variant is supplied: any completion would be a modern invention, not the 1962 message text. The rule the message enforces is unaffected — conditional expressions have bounded test capacity, and oversized ones are diagnosed and must be split into two or more expressions.

**Rationale.** The scan shows the continuation is one unbroken 95-character line on a continuous character grid, with a normal single-space word gap at the "WITH|ILLEGAL" junction and no splice or overprint, and the appended 40 characters are byte-identical to message 196's text. That evidences an overrun in the 1962 print routine, not a message the compiler was designed to hold. Unlike the 90.08 density defect, where [J 02.06.10] pins the intended value, nothing pins 187's missing words, so the evidence-bounded choice is to reproduce what is attested rather than to reconstruct.

**Implementation.** Diagnostics module: message-catalog entry for msg 187 ([J 90.04.01]) holds the two attested print lines verbatim, including the run-on tail; message 196 keeps its own text "ILLEGAL SENTENCE STRUCTURE NOTHING DONE." Record in the catalog source a comment that 187's line 2 is a known 1962 print overrun. Compiler behavior: split-required diagnostic on oversized conditional expressions, consistent with existing bounded-test-capacity handling. No --pedantic delta.

**Oracle.** manual example ([J 90.04.01] printed message list, msgs 187 and 196; images/page-185.png) — valid only because the decision now reproduces the print verbatim

*Citations:* ([J 90.04.01] msgs 187, 196; images/page-185.png)

### D8.8 — 90.01.05 item k `-CP)+NN` — prior conjecture refuted by scan (independently verified)

**Status.** Locked.
**Decision.** Generate compiler-produced names in the documented general form SYM)NNN — a two- or three-letter symbol, a bare right parenthesis, then a number. Constants are the one exception: they use the designation CP)+NN — the base symbol `CP)`, then a plus sign, then the offset NN — exactly as [J 90.02.03] states and as the 90.05 listing prints throughout (for example `LDI CP)+40`, `CAL CP)+16`). What the scan refutes is only the leading left parenthesis: `(CP)+NN` is a form this manual never uses. Read 90.01.05 item k as "Number of generated constants in the constant pool — CP)+NN", the dash introducing the notation rather than being part of a hyphenated prefix.

**Rationale.** Scan measurement rules out a literal left parenthesis: the mark before CP is 23x8 px at 400 dpi, metrically identical to the page's "Appox-Max" hyphen, whereas every parenthesis on the page runs about 14-16 x 49-56 px. [J 90.02.03] states explicitly, "In the case of constants (CP references), the designation CP)+NN is used", and the 90.05 listing carries the plus form throughout. The plus sign was never in question; only the left parenthesis was.

**Implementation.** Codegen: synthesize the constant-pool designation as CP)+NN per [J 90.02.03] (plus sign present), and other compiler-generated names as SYM)NNN with a bare right parenthesis. These names appear in object-deck symbol tables and in listing cross-reference output, so the strongest oracle checks them directly; emitting CP)040 in place of CP)+40 would fail the listing diff on every constant reference. Separate scan result from the same entry, with no compiler consequence: the closing ")" the transcription prints at the end of 90.01.05 item h is editorial — the original never closes the parenthesis opened at "(each unique combination" — recorded so that a later quotation of item h does not treat that ")" as original print.

**Oracle.** listing-diff

*Citations:* ([J 90.01.05]; [J 90.02.03]; images/page-137.png)

### D8.9 — Cross-reference errata

**Status.** Locked.
**Decision.** No compiler-facing decision; recorded as a resolved transcription matter. [J 02.04.06]'s reference to the SPECIF card as "(Section 02.07)" is read as 02.06, the section that actually documents SPECIF.

**Rationale.** This is a cross-reference typo internal to J's own text; the SPECIF card's actual definition lives in 02.06, and no compiler behavior depends on the reference's printed section number.

**Implementation.** None — purely a documentation cross-reference fix with no lexer, parser, codegen or runtime consequence.

**Oracle.** decision-conformance only

*Citations:* ([J 02.04.06]; [J 02.06.07])

### D8.10 — The *CTEND card's date field — transcription artifact, resolved by scan (2026-08-02)

**Status.** Locked.
**Decision.** Punch the compiler-supplied date.and.time field of both the *CTEXT and the *CTEND card in the unpunctuated form, exactly as the *CTEXT card image prints it — not the slashed "10/18/61" form at column 29 that appears only in the 90.05 transcription's *CTEND line. The listing's running page head keeps its own slashed form and is a different thing: it must not be normalized to the card form, and the card form must not be normalized to it.

**Rationale.** The scan shows the *CTEND card image prints the date unpunctuated, exactly as the sibling *CTEXT card does at PDF p. 198, which the transcription already renders correctly, so the converted file contradicts itself. The slashed form belongs to the listing's running page head, which the conversion notes record as retained; the *CTEND line was silently normalized to it, which also pushed that line's DATE from card column 26 to column 29.

**Implementation.** Codegen and listing: [J 03.02.09] gives the card layout as cols 1-6 deck.name, 7-12 *CTEXT or *CTEND, 26-54 date.and.time, 55-72 secondary.identifier. The date.and.time field begins at column 26 with the literal word DATE, then the unpunctuated MMDDYY digits, then TIME and the time value — column 26 is the field start, not the position of the first digit. Take the intra-field spacing from the *CTEXT card image ([J 90.05] listing, PDF p. 198). The transcribed line's later columns drifted from the documented col-55 secondary.identifier start until the 2026-08-05 erratum measured both cards and corrected them. Listing generator: the running page head keeps the slashed form (DATE 10/18/61 TIME 2.45 ACCOUNT ... ID. CT PUBLICATIONS PAGE nn) and is produced by separate code from the card punch. Both the card and the page head appear in the compiled payroll listing and deck, so the primary conformance oracle checks them.

**Oracle.** listing-diff

*Citations:* ([J 90.05] listing, PDF pp. 198, 216; [J 03.02.09]; images/page-198.png, page-216.png)

## D9 — Severity system and conformance list (§8.4)

### D9.1 — Severity system (B.1)

**Status.** Locked.
**Decision.** Implement the 1-5 severity system as B.1 attests. Each diagnostic carries a severity value 1-5. A compilation's severity is the maximum severity of all diagnostics issued so far. Four gates follow. (a) ATTESTED. Maximum severity 1: the object deck is punched (unless NODECK) and the program runs immediately after compilation under LOAD, unless NOGO was taken or the generated code contains an undefined symbol. (b) ATTESTED. Maximum severity 2, 3 or 4: the deck is punched, but the compiler does not compile and go. (c) ATTESTED. Severity 5: the compiler stops compiling at the point of detection, punches no deck, prints no assembly listing, and goes on to the next job. (d) DESIGN DECISION (non-historical). We implement the severity limit as the fixed built-in value 5, set by no control card, following the §8.5.7 resolution ("most plausibly the fixed built-in threshold ... not a user-settable knob"). B.1 itself records the trailer as "evidence of a settable severity limit whose control is not documented in 02.01 (see open questions)", so a user-settable limit cannot be excluded; if evidence appears, only this clause changes. Diagnostic-listing behavior. ATTESTED: a clean compilation prints NO ERRORS WERE DETECTED DURING COMPILATION ([J 90.05] listing, PDF p. 197); a diagnostic listing carries the header THE FOLLOWING ERRORS WERE DETECTED DURING COMPILATION- with the column head NUMBER CODE MESSAGE, and the 90.04 appendix ends with the trailer SEVERITY LIMIT WAS NOT REACHED. DESIGN DECISION (non-historical): we print that trailer when diagnostics were issued and no severity-5 stop occurred, and we print no trailer at all on a severity-5 stop; no counterpart text survives and we invent none, because an invented trailer string would be a fabricated 1962 artifact. Open Question 66 (is a severity 2-4 deck unreliable?) is answered as a decision, not as fact: the deck is produced and is exactly the code the compiler generated; we make no reliability claim and we do not suppress it. The compile-and-go block on an undefined symbol in generated code is a separate, attested gate from severity: it blocks execution even when the maximum severity is 1.

**Rationale.** Attested, with citations. The severity range and the 1 / above-1 / 5 rules are direct quotations ([J 90.04.02]). Deck suppression at severity 5 only is stated at [J 02.01.01]. The LOAD gate, including the undefined-symbol clause, is at [J 02.01.02]. The assembly-listing gate is at [J 02.02.01]. The CODE column carrying one of the values 1 through 5 is at [J 90.04.01]. The two summary lines and the trailer are printed text ([J 90.04.01]; [J 90.05] listing, PDF p. 197). Decided, not attested: the threshold behind the trailer. §8.5.7 offers only "most plausibly the fixed built-in threshold", and B.1 reads the same trailer as evidence of a settable limit. No surviving text states a fixed threshold, and no real error listing survives (Open Question 71). Under D0.4 this is therefore a recorded design decision. Never present it as historical fact. Trailer suppression on a severity-5 stop is decided on the same footing. Both decisions sit in the default mode: they are not strictness beyond attested behavior, so D0.8 does not send them to --pedantic.

**Implementation.** One diagnostic sink object holds the running maximum severity and the ordered diagnostic list. The severity-5 path throws a control-flow exception caught by the job driver, which discards the deck writer output, suppresses the assembly listing, and advances to the next job (see the job-stream record). Deck production, compile-and-go, and listing are three separate consumers of the same maximum-severity value; do not couple them to each other. Hold the threshold value 5 as a named entry in the same reviewable decisions table as the severities, flagged non-historical, so a settable-limit finding changes one row. The host process exit status maps to the maximum severity; that mapping is outside the emulated 1962 surface and is a convenience, not a historical claim. Note that the trailer line belongs to the diagnostic listing, not to the compilation listing: the 90.05 clean run shows only the NO ERRORS line and no trailer, while the 90.04 appendix, which is a printout of the message file in error-listing form, ends with the trailer.

**Oracle.** Oracles (1) and (2): our compilation of test/fixtures/90.05-payroll.ct must issue zero diagnostics, print NO ERRORS WERE DETECTED DURING COMPILATION, print no severity trailer, and produce a deck that diffs clean against the 1962 listing ([J 90.05] listing, PDF pp. 198-216) and the printed report (PDF p. 217). Oracle (4), decision-conformance tests: four gate tests, one per severity band, each asserting deck/no-deck, go/no-go, listing/no-listing, and the exact summary line; one test asserting that an undefined symbol in generated code blocks execution at maximum severity 1; one test asserting that a severity-5 error stops compilation at the point of detection and leaves later source cards unprocessed. The trailer tests (printed when diagnostics occurred without a severity-5 stop, absent on a severity-5 stop) are decision-conformance only, since no real error listing survives.

*Citations:* ([J 90.04.01]); ([J 90.04.02]); ([J 02.01.01]); ([J 02.01.02]); ([J 02.02.01]); definition §8.4 B.1; §8.5.7 "SEVERITY LIMIT WAS NOT REACHED"; Open Question 66; Open Question 71; ([J 90.05] listing, PDF p. 197); ([J 90.05] listing, PDF pp. 198-216); ([J 90.05] listing, PDF p. 217); D0.4; D0.8

### D9.2 — Severity assignment policy (Q65)

**Status.** Amended.
> **Amended 2026-08-03 (D11.4):** the Implementation rule "do not let
> --pedantic change any severity value" binds each message id: no id's
> severity differs between modes, and no attested id is re-graded. Two
> locked escalation records (D3.4; D6.6) grade one non-historical
> condition more severely under --pedantic. D11.4 reconciles them with
> this rule by a distinct pedantic-only id (921, 922) at its own fixed
> severity, issued in place of the default-mode id (918, 911). Those two
> are the only recorded cases.

**Decision.** Per-message severity values are historically unrecoverable, so we assign them by a stated consequence rule and mark every value non-historical. Precedence rule for building the table: the consequence stated in a message's own text wins over its class heading. Five classes. C1 advisory or auto-repair, where the compiler completes the intended object code and only warns or substitutes a documented default, severity 1 (for example 62 PERIOD ASSUMED, 60 ZERO COUNT IN PICTORIAL REPLACED BY ONE, 44 UNSPECIFIED MAXIMUM QUANTITY ASSUMED TO BE 1, 116 MISSING OPERAND ASSUMED TO BE ZERO, 189 EXTERNAL MODE SUBSTITUTED, 206 INEFFICIENT FORMAT). C2 operand-level loss, severity 2 (for example 120 name ELIMINATED FROM ADD, 68 EVALUATION IGNORED, 25 OPERATION IGNORED, 113 REDUNDANT RIGHT PARENTHESIS ELIMINATED). C3 statement-level or sentence-level loss, severity 3 (for example 122, 125, 126, 171 SENTENCE DELETED FROM TEXT, 84 ILLEGAL MOVE ... NOTHING DONE, 196 ILLEGAL SENTENCE STRUCTURE NOTHING DONE, and 177 THIS SENTENCE EXCEEDS INTERNAL TABLE CAPACITY. SENTENCE DELETED FROM TEXT.). C4 program-level loss or a program that cannot run correctly, severity 4 (for example 108 UNDEFINED SYMBOL, 66 ONE OR MORE SECTIONS NOT CLOSED, 87/99/169 program-continuity errors, 175 NO -STOP RUN-, 90/110/151/180/181 recognized-but-deferred constructs). C5 unrecoverable, internal, or capacity conditions, severity 5: the compiler self-diagnostics, the permanent read and dictionary errors, and the internal-table overflow messages that state no recovery, namely 148, 149, 172, 183, 184 and 200-205. Message 177 is the worked example of the precedence rule: it is an internal-table overflow message, but its own text states its recovery (sentence deleted, compilation continues), so it takes C3 and not C5. Rule for picking a value inside the 2-4 range: take the largest source unit whose intended object code is lost. Operand or clause gives 2; statement or sentence gives 3; a procedure, section, record, file, or whole-program property gives 4. J's own words "the value may vary" permit one message to carry different severities at different sites, so the table maps (message id, context key) to a severity, with a default value per message id. All 210 values are OUR design decisions. They live in one reviewable machine-readable table produced at M2, each row marked non-historical and carrying its class and its justification.

**Rationale.** The 90.04 listing prints CODE 0 for every message because "the value may vary", and no table assigns the 210 messages their real severities, although severity controls deck production, compile-and-go, and abort. The §8.5.7 entry states exactly this and proposes assignment by the consequence stated in each message text: auto-repair warnings plausibly 1, deletions and NOTHING DONE 2-4, unrecoverable conditions 5. The precedence rule is added because §8.5.7's own grouping and the message texts collide in two places: message 177 is a table-overflow message that nonetheless states its recovery, and messages 85, 135, 136, 137 and 140 read COMPILATION SUSPECT / DUBIOUS COMPILATION, which implies the compilation continued. For 177 the text wins and it takes severity 3. For 85/135/136/137/140 we follow §8.5.7 and keep severity 5, and record the tension in the row's justification; those conditions are unreachable in our implementation (see the self-diagnostics record), so the value is never exercised. Open Question 65 stays open; nothing in the manuals narrows it. D0.4 therefore applies: the behavior is a recorded design decision, never presented as historical fact.

**Implementation.** Keep the severity table separate from the message-text table, so a reviewer can change severities without touching attested text. Each row: message id, class C1-C5, default severity, optional per-context overrides, one-line justification, and the fixed flag non-historical: true. Rows 85, 135, 136, 137 and 140 carry the note "Text implies continuation (SUSPECT / DUBIOUS), but §8.5.7 groups read and dictionary errors at severity 5; unreachable in our implementation, so the value is never exercised." Row 177 carries the note "Table-overflow message, but its own text states the recovery; the precedence rule puts it in C3." The compiler must read severities from this table only; no severity constant may appear in compiler code. Add a build check that every message id 0-209 has exactly one row. Do not let --pedantic change any severity value: --pedantic adds diagnostics for written-language strictness (D0.8) and must not re-grade attested ones, or the two modes would disagree about deck production.

**Oracle.** Oracle (4), decision-conformance only. The tests. Table completeness: all 210 ids, one row each. Class-to-range consistency: C1 gives 1, C2-C4 give 2-4 and match the largest-lost-unit rule, C5 gives 5. A precedence-rule test asserting that message 177 resolves to severity 3, and that 148, 149, 172, 183, 184 and 200-205 resolve to 5. A golden copy of the table, so any change shows in review. Per class, one end-to-end test that a representative faulty program produces the expected gate result (deck / no deck, go / no go). No manual evidence can confirm the values, and the 90.05 sample compiles clean, so no stronger oracle exists.

*Citations:* ([J 90.04.01]); ([J 90.04.02]); ([J 02.01.01]); definition §8.4 B.1-B.2; §8.4 B.2 capacity-overflow table (msg 177); §8.5.7 "Per-message severity codes are nowhere specified"; Open Question 65; D0.4; D0.8

### D9.3 — Conformance list binding

**Status.** Locked.
**Decision.** §8.4 B.2 is the conformance list for the language rules the diagnostics imply. We reference it in place and never copy its rules into design documents, so that the definition stays the single source of truth. At M2 we derive one machine-readable checklist from B.2 and from the 90.04 message listing. One row per message id 0-209, with these fields:

- id;
- the verbatim message text as printed ([J 90.04.01]);
- the B.2 row that states the implied rule, cited by its section and message number, OR the fixed value "no B.2 row" where none exists;
- disposition (enforced, reserved, or unreachable-by-construction);
- the enforcing component (card reader and lexer, name resolution, procedure parser, data description, environment description, input/output binder, CRYPT assembler, code generator, or emulated runtime);
- the severity class from the severity table;
- at least one test id.

Exactly two ids have no B.2 row, and the checklist names them explicitly: 90 (THIS ENVIRONMENT TYPE NOT YET PROCESSED BY COMPILER.) and 110 (-COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM.). Those two rows cite ([J 90.04.01]) for the text plus the governing deferral section instead of a B.2 row: ([J 90.01.04] c.i) with ([J 02.06.02]) for msg 90, and ([J 90.01.02]) with ([J 90.01.03] b.i) for msg 110. The checklist is complete only when every one of the 210 ids has a disposition, and every enforced id has a test. On the printed line: ATTESTED, the CODE column carries one of the severity values 1-5 ([J 90.04.01]), and errors are cross-referenced to source by compiler-assigned statement number ([J 02.02.01]). DESIGN DECISION (non-historical): we read the 90.04 appendix as the compiler's message file printed through the error-listing routine, so in a real listing the NUMBER column holds the statement number and the message id is an internal key that is never printed. No real error listing survives (Open Question 71), so this reading cannot be confirmed.

**Rationale.** The M0 rule for this unit is that B.2's implied rules are the conformance list. B.2 already gives, per message, the rule and the citation, so a derived checklist adds only the mapping to component and test. Copying the rules would create a second, divergent copy of cited material, which the definition's maintenance rules forbid. Keying by message id works because the id set is closed and printed (0-209). The "no B.2 row" value is required by the evidence: B.2's 13 grouped tables cover neither msg 90 nor msg 110, so a mandatory B.2-row field would be unfillable for them and would fail CI on a correct table. The never-printed-id reading is an inference from a message-file dump, not a printed rule, so it is recorded as a decision.

**Implementation.** Generate the checklist file from the two source tables at M2, and make CI fail when a message id has no disposition, when an enforced id has no passing test, or when a message text in our table differs from the transcribed 90.04.01 text. The B.2-row check accepts the literal value "no B.2 row" and then requires the two replacement citations; it must not fail on ids 90 and 110. Group the B.2 rows by their printed headings (numeric limits, lexical and card format, names, section structure and control flow, DO and functions and subscripting, conditionals, MOVE/ADD/SET arithmetic, data description, environment description, CRYPT, DISPLAY, capacity overflow, compiler self-diagnostics), because those groups map almost one-to-one onto compiler components and give the natural test-suite layout. Some B.2 rows cover several ids (for example 72-75, 117/118/121); keep one checklist row per id and let several rows point at one rule.

**Oracle.** Oracle (4) for the checklist mechanics: a build test that the checklist covers ids 0-209 exactly once; a test that exactly ids 90 and 110 carry "no B.2 row" and that both carry their replacement citations; a golden test that our message-text table equals the transcribed listing byte for byte; per-id behavior tests as listed in the checklist. Oracles (1) and (2) apply only negatively here: the 90.05 sample must trigger none of the enforced rules.

*Cross-reference (2026-08-03):* the checklist landed as `docs/design/message-checklist.tsv` (one row per id 0,00-209,00 plus the 900 series), gated by `test/message_checklist_test.dart`, which fails when an id lacks a disposition, when the enforced set differs from the compiler's message tables, when an enforced id names no live test, or when a text, class, or B.2 citation drifts. Two deltas from the Implementation paragraph above: the file is hand-maintained and machine-verified rather than generated (the gate makes drift impossible, and the dispositions are judgment, not derivation), and the B.2 column cites the group heading — the heading plus the row's own message number identify the B.2 row, so no rule text is copied.

*Citations:* ([J 90.04.01]); ([J 02.02.01]); definition §8.4 B.2 (all rows); ([J 90.01.02]); ([J 90.01.03] b.i); ([J 90.01.04] c.i); ([J 02.06.02]); Open Question 71; CLAUDE.md rule that the definition is the ground truth to be cited, not copied

### D9.4 — B.2 msg 62 vs the attested missing-period leniency

**Status.** Locked.
**Decision.** Treat the two missing periods as two different repairs. (a) Missing procedure-name terminating period: accept it silently in default mode, with no diagnostic, and take the name/text boundary at the first blank after the name token that begins in the name margin (columns 7-12). --pedantic warns. (b) Missing sentence-terminating period: insert the period, issue message 62 PREVIOUS CARD NOT PROPERLY TERMINATED. PERIOD ASSUMED. at severity 1 (class C1), and continue compiling the repaired text. Trigger criterion for (b), stated as our design decision: the scanner reaches the end of a card, the accumulated Procedure text has no closing period plus blank, and the next card starts a new sentence (it carries a name in the name margin, or it is a division or control card). This criterion is not printed anywhere and is marked non-historical.

**Rationale.** B.2 states that every Procedure statement must end with a period plus blank, and that an unterminated card gets a period assumed (msg 62). §8.5.1 states the opposite-looking fact for a different period: J says procedure names not punctuated with a period plus blank "are handled properly; no diagnostic message is given". Read together they are consistent only if the compiler diagnoses the sentence terminator and forgives the name terminator. D0.8 requires the default mode to reproduce the attested leniency and to put written-language strictness behind --pedantic. The trigger criterion must be invented because the manuals never say how the compiler decided a card was unterminated; the chosen rule is the weakest one that can fire at all.

**Implementation.** Do both repairs in the card-to-token stage, before the sentence parser, so the parser always sees terminated sentences. Record each repair in the token stream with its source card, so the listing can show the repaired text and so --pedantic can raise its own diagnostic from the same record. Keep the two repairs as separate rule objects with separate message ids, because only one of them has a message.

**Oracle.** Oracle (3): the 90.05 source deck exercises correctly punctuated procedure names, so it must produce neither repair. Oracle (4), two decks. A deck with a long procedure name that overflows the name margin and carries no period must compile silently in default mode, and must warn under --pedantic. A deck whose sentence period is missing before a new named sentence must produce message 62 once, at severity 1. That deck must compile to the same object code as the same deck with the period present.

*Citations:* ([J 90.04.01]) msg 62; definition §8.4 B.2 lexical row; §8.5.1 "Procedure-name terminating period"; ([J 90.01.03] A.1.a.ix); ([F p. 37] rule 2); ([F p. 15] rule 1); D0.8

### D9.5 — Diagnostic message realization: substitution slots and listing format

**Status.** Locked.
**Decision.** Store each message text byte for byte as printed at [J 90.04.01]. Keep the spacing as printed, including the double spaces and the space before a period. Keep the continuation lines as printed. Give no final period to the messages that end without one as printed (among the single-line messages: 63, 74, 75, 198, 199, 208, 209). Further multi-line messages may also end without one; the golden byte-comparison, not this list, is the authority. Define three substitution-slot classes, and treat the slot map as OUR design decision, marked non-historical. (i) Name slots 'NAME.1' and 'NAME.2': attested placeholders; substitute the offending source name. (ii) Format-echo slots, the parenthesized field descriptions in messages 25, 84 and 120, printed as ( E  A(2) ) and ( IR 999 ): substitute the field's mode letters and pictorial. (iii) Value slots: the record length and blocksize numerals in message 5, and the value that message 209 appends after BLOCKSIZE USED IS. Every other numeral in a message text is fixed text and is printed verbatim (30 in message 100, 50 in 150, 6 in 160, 60 in 171, 63 in 193, 16 in 50, 12 in message 6, '1' in message 7, 32766 in 181). Listing format. ATTESTED: the CODE column carries one of the severity values 1-5 ([J 90.04.01]); errors are cross-referenced to source by compiler-assigned statement number xxxxx,yy, with 9999,99 for an error not confined to a single source statement ([J 02.02.01]); the column head is NUMBER CODE MESSAGE ([J 90.04.01]). DESIGN DECISION (non-historical): we read the 90.04 appendix as the message file printed through the error-listing routine, so we print the statement number in the NUMBER column, the severity in CODE, then the message text, and we never print the message id.

**Rationale.** B.2's transcriber note says the numerals inside the message texts are representative sample values from the fixed text, not variables. That reading is right for most numerals, which are real fixed limits, but it cannot hold for message 5 (RECORD LENGTH 24 ... -BLOCKSIZE- 12) or for the parenthesized format echoes, which B.2's own MOVE/ADD rows describe as "the field's format echoed", or for message 209, whose text stops before the value. The conflict is real and must be settled now, because it fixes the shape of the message table. The three-class split keeps every attested byte and adds substitution only where the text is unusable without it. On the listing line, the CODE column and the statement-number cross-reference are printed rules; the NUMBER column's content in a real error listing is not. The 90.04 appendix's NUMBER column counts 0,00 to 209,00 because it is the message file printed through the error-listing routine; that is our reading, and no real error listing survives to confirm it (Open Question 71, which records that the sample compiles clean, so only ,00 statement numbers appear anywhere).

**Implementation.** Hold the message table as data (id, printed text, slot list), generated from the transcribed 90.04.01 listing and checked against it in CI. Represent a slot as an offset and length into the printed text plus a slot kind, so the attested text stays the single stored string and no re-typed template can drift. Where a diagnostic has no value for a slot, print the attested text unchanged. Continuation lines in the printed listing (messages 5, 9, 10 and others print a second, indented line) are part of the stored text; keep their leading spaces. Do not maintain a hand-written list of the no-final-period messages in code; the golden byte-comparison covers them all.

**Oracle.** Oracle (3): a golden test that our stored texts equal the transcribed [J 90.04.01] listing for all 210 messages, byte for byte, including spacing, continuation lines, and every missing final period. Oracle (2): the 90.05 clean run must print no diagnostic line at all, so the listing format is exercised only by decision-conformance tests: one per slot class, checking the substituted line, and one checking that statement number 9999,99 is used for a non-statement-scoped error. The NUMBER-column reading itself has no oracle stronger than (4).

*Citations:* ([J 90.04.01]); ([J 02.02.01]); definition §8.4 B.2 preamble and the MOVE/ADD and environment rows (msgs 5, 25, 84, 120, 209); §8.4 B.1 statement-number rule; Open Question 71; ([J 90.05] listing, PDF pp. 192-197)

### D9.6 — Message 187: the garbled tail

**Status.** Jack's call, 2026-08-02, tied to D9.7. It binds.
> **Tied to D9.7, resolved with it 2026-08-02:** this record follows the hard-enforcement policy.

**Decision.** Store message 187 as the truncated text that ends after EACH WITH, and do not append message 196's text when we issue the diagnostic. Record the run-on in the message table as a note about the 1962 appendix, not as behavior. Keep the implied rule: a conditional expression has a bounded internal test capacity, and an oversized one must be split into separate expressions. The capacity value is our design decision (see the internal-table record), because no number is printed.

**Rationale.** The §8.5.8 scan pass resolved the garbling: it is a defect of the original 1962 listing, not of the conversion. Message 187's own wording truncates mid-phrase after EACH WITH, and the appended 40 characters are byte-identical to message 196's text, so the message-print routine ran on into 196's stored text. The stored text is therefore the truncated string. We have no evidence that the same run-on happens when the compiler issues 187 against a source program, and reproducing a print-routine defect that was observed only in a message-file dump would assert a fact we do not have. D0.4 governs: state the choice as a decision.

**Implementation.** Put the reconstruction note in the message table row, so the checklist and any listing tooling can show it. If a future oracle ever shows a real 187 diagnostic with the run-on, only the table row changes. Do not add a flag for the run-on; one attested form is enough.

**Oracle.** Oracle (4): a test that message 187's stored text ends after EACH WITH and does not contain ILLEGAL SENTENCE STRUCTURE. Oracle (3) applies in reverse: the golden byte-comparison of the message table against the transcribed listing must carry an explicit exception for message 187, documented in the checklist row.

*Citations:* ([J 90.04.01]) msgs 187, 196; definition §8.4 B.2 conditionals row; §8.5.8 "Message 187's garbled tail — resolved by scan"; images/page-185.png; D0.4

### D9.7 — Internal-table capacity diagnostics (msgs 148, 149, 172, 177, 183, 184, 200-205)

**Status.** Jack's call, 2026-08-02. It binds.
> **Resolved by Jack, 2026-08-02:** hard-enforce — each threshold set at the printed "Appox-Max" number, diagnosed with the attested overflow messages, so a program that compiles for us would have compiled in 1962 (over-rejecting in the unknown band above the printed number); the non-historical --no-table-limits switch lifts them.

**Decision.** Enforce the 90.01.05 capacities in the default mode, with each threshold set at the printed number, and issue the matching message when a program exceeds one. Our compiler has no 1962 tables, so each limit becomes an explicit counter checked at the point where the 1962 compiler would have overflowed. Message-to-limit map, taken from 90.01.05:

| Message | 90.01.05 item | Printed limit |
|---|---|---|
| 149 | b) sections | 35 |
| 204 | c) edited field formats | 35 |
| 202 | d) base locators | 127 |
| 200 | e) QUANTITY IN specifications | 25 |
| 183 | g) index expressions | 50 |
| 184 and 205 | h) positional indicators | 90 |
| 203 | i) array dimensions | 85 |
| 201 | j) levels in a data hierarchy | 23 |
| 172 | k) generated constants in the constant pool | 500 |

Message 200 takes the printed 25 of item e: Open Question 67 asks whether msg 200 counts the 25-item QUANTITY IN table or a distinct counter, and Open Question 14 states that only nested-section depth (18) and the internal dictionary (3500) have no visible message, which leaves item e with msg 200 as its only candidate diagnostic. The distinct-counter reading is not excluded and the table row carries that note. Message 148 (alphabetic-constant length) takes a documented limit derived from the constant pool, per the §8.5.7 resolution "Maximum alphabetic-constant length": constants live in the pool whose capacity is about 500 generated constants ([J 90.01.05] k), so the cap is a share of that table; the share we pick is ours and is marked non-historical. Only two limits keep a wholly invented number, both marked non-historical: 177 (sentence capacity, Open Question 9) and 187 (conditional-expression test capacity). Two 90.01.05 limits have no 1962 message at all: f) nested-section depth 18 and a) internal dictionary 3500 (Open Question 14). For those we raise a non-historical diagnostic with a distinct id outside the 0-209 range, severity 5, flagged in the listing and in the table as having no 1962 counterpart; we do not reuse an attested id for a condition the 1962 listing never named. A non-historical switch (--no-table-limits) disables the whole class for users who want to compile larger programs; it is off by default. All invented and derived numbers live in the same reviewable table as the severities.

**Rationale.** §8.5.7 reads the printed numbers as guaranteed-safe capacities, with overflow diagnosed at whatever the true internal capacity was; the table is headed "Appox-Max Size" (sic), so no exact threshold survives. This is a decision, not a deduction: we set each threshold at the printed number, so our accepted program set is a subset of the 1962 accepted set. In the unknown band between the printed number and the true 1962 capacity we over-reject, and that is our choice, marked non-historical. We put it in the default mode rather than behind --pedantic because D0.8 defines --pedantic as written-language strictness beyond attested compiler behavior, while a table overflow is attested compiler behavior with an attested message; only the exact threshold is unrecovered. A reconstruction that accepted programs the 1962 compiler would have rejected would equally not be the field-test compiler, so neither side of the band is evidence-neutral, and the printed number is the only number we have. --no-table-limits, off by default, holds the relaxation separately, as D0.4 requires for non-historical behavior. Open Question 14 (hard versus soft limits) stays open; the two limits it names as having no message are handled above and their diagnostic is marked as ours.

**Implementation.** One counter registry, keyed by the same ids as the messages, so the checklist maps limit to counter to message to test directly. Check on increment, not at the end of a phase, so the diagnostic points at the source statement that crossed the limit. Each row records the threshold, its provenance (printed number / derived from the constant pool / invented) and the flag non-historical for the last two kinds, so a reviewer sees at once which numbers are ours. The two message-less limits (nested-section depth 18, internal dictionary 3500) get counters, a disposition in the checklist, and the non-historical diagnostic id; no attested id is reused for them.

**Oracle.** Oracle (4) only; the 90.05 sample stays far below every limit, so it can only confirm that no limit fires (oracle 2). Per limit: one test at the printed capacity that must compile, one test at capacity plus one that must produce the matching message; one test that a nested-section depth of 19 and a 3501-entry dictionary each produce the non-historical diagnostic and not an attested id; plus one test that --no-table-limits removes the diagnostics and changes nothing else.

*Citations:* ([J 90.01.05]); ([J 90.04.01]) msgs 148, 149, 172, 177, 183, 184, 200-205; definition §8.4 B.2 capacity-overflow table; §8.5.7 "Internal-table limits are approximate"; §8.5.7 "Maximum alphabetic-constant length"; Open Questions 9, 14, 67; D0.4; D0.8

### D9.8 — Recognized-but-deferred constructs (msgs 151, 180, 181, 110, 90)

**Status.** Locked.
**Decision.** Reproduce every attested deferral instead of implementing the missing feature. When a program uses a construct that the field-test compiler did not handle, issue the printed message, drop the construct, and continue:

- 151 VFD IS NOT YET HANDLED BY SYSTEM. for the CRYPT VFD pseudo-op;
- 180 MOVE OF FIGURATIVE CONSTANT TO VARIABLE LENGTH FIELD NOT YET HANDLED BY SYSTEM.;
- 181 MOVE OF FIGURATIVE CONSTANT TO FIELD LONGER THAN 32766 CHARACTERS NOT YET HANDLED BY SYSTEM.;
- 110 -COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM. for the Data Description COPY type code and for library facilities;
- 90 THIS ENVIRONMENT TYPE NOT YET PROCESSED BY COMPILER. for a deferred environment card type.

INCLUDE has no message of its own: INCLUDE and LIBRARY are both reserved in J ([J 02.03.02] key-word list 2) while INCLUDE's mechanization is deferred and "consequently no library facilities are currently available" ([J 90.01.02]), so we recognize an INCLUDE sentence, drop it, and report msg 110, the only message that names LIBRARY. That msg 110 covers INCLUDE is OUR reading and is marked non-historical. Msg 176 (-CONTRL- CARD FORMAT ERROR.) is not a deferral: the CONTRL card is still parsed for format and 176 fires on a bad one; its specification then simply has no effect on the object deck ([J 90.01.04] c.i). Assign the deferral messages severity 4 (class C4, program-level loss): the deck is punched but the program is incomplete. Answering Open Question 64 as a design decision: the statement is skipped and it still consumes a statement number, so listing line numbering is unaffected. Implementing any of these features is out of scope for the reconstruction; if it is ever wanted, it belongs behind a clearly marked non-historical option, never in the default mode.

**Rationale.** D0.1 and D0.8 fix the target as the field-test compiler as attested. A message that reports a construct as not yet handled or not yet processed is direct evidence of what the compiler did, so implementing the feature would remove attested behavior. The message-and-continue shape is required by the messages themselves, which report the omission rather than abort. Msg 90's coverage is decided elsewhere: §8.5.7 "Which environment types msg 90 covers" reads it as covering CONTRL-like deferred types, since the other environment card types have dedicated format diagnostics and so were at least parsed; that entry belongs to another unit and this record only carries its result, so the parent can dedupe. Msgs 90 and 110 have no B.2 row, which is why the conformance-list record allows the "no B.2 row" value for exactly these two ids. The statement-number decision is unrecoverable (Open Question 64, whose own citation names msgs 108, 110 and 176) and is marked as ours.

**Implementation.** Keep one deferred-feature table (construct, message id, [J 90.01] citation) so that the parser can recognize the construct fully, then refuse it at one place. The parser must still parse the construct correctly, or the recovery would cascade into unrelated diagnostics. VFD is the clean case: the CRYPT assembler recognizes the pseudo-op, then rejects it ([J 02.08.02] lists it among pseudo-ops which may not be used, while message 151 phrases it as not yet handled). COPY is a Data Description type code ([J 90.01.03] b.i), not a procedure verb, so its refusal sits in the data-description reader; INCLUDE is a Procedure key word ([J 02.03.02]), so its refusal sits in the procedure parser; both raise msg 110.

**Oracle.** Oracle (4): one test per deferred construct (VFD, figurative-constant MOVE to a variable-length field, figurative-constant MOVE to an over-long field, COPY type code, INCLUDE sentence, deferred environment type), asserting the exact message, severity 4, that the statement is dropped, that later statements still compile, and that the statement number sequence is unchanged. Oracle (2): the 90.05 sample uses none of them and must stay clean.

*Citations:* ([J 90.04.01]) msgs 90, 110, 151, 176, 180, 181; definition §8.4 B.2 CRYPT and figurative-constant rows; §8.5.7 "Which environment types msg 90 covers"; ([J 90.01.02]); ([J 90.01.03] b.i); ([J 90.01.04] c.i); ([J 02.03.02]); ([J 02.06.02]); ([J 02.08.02]); Open Question 64; D0.1; D0.8

### D9.9 — Figurative-constant target ceiling: 32766 or 32767

**Status.** Locked.
**Decision.** Use 32766 characters as the implemented maximum target length for a MOVE of a figurative constant. A target longer than 32766 characters produces message 181; a target of exactly 32766 is accepted.

**Rationale.** B.2's own limits row flags the conflict: message 181 says FIELD LONGER THAN 32766 CHARACTERS, while [J 02.04.01] forbids fields "longer than 2^15 - 1 characters", that is 32767. The §8.5.4 resolution reads the prose as an off-by-one and takes the message to reflect the coded check, so 32766 is the safe implemented maximum. The message is the closer witness to the compiler, which is what we reconstruct.

**Implementation.** Hold the constant in the same limits table as the other numeric ceilings, with a note recording the 32767 prose reading, so the choice is visible in review. Apply the check to the target field's length in characters as computed from its data description, including any QUANTITY expansion.

**Oracle.** Oracle (4): boundary tests at 32765, 32766 and 32767 characters. No manual example exercises this limit, and the 90.05 sample has no field near it.

*Citations:* ([J 90.04.01]) msg 181; ([J 02.04.01] c.ii); definition §8.4 B.2 numeric-limits row; §8.5.4 "Figurative-constant target maximum: 32766 vs 2^15-1"

### D9.10 — Message 134: what counts as an illegal character

**Status.** Locked.
**Decision.** Define the message-134 gate in three layers, because our source canon is column punches (decisions.md D0.5). (a) A card column whose punch combination has no defined BCD code is illegal everywhere. (b) Outside an alphameric literal, a column whose BCD character is not in the COMTRAN source character set is illegal; this covers the machine characters & % # @ and the record, group and lozenge specials, which exist in the machine set but are not source-language characters. (c) Inside an alphameric literal, accept any column with a defined BCD code except the quote, which terminates the literal. On any illegal character, issue message 134 once per character, replace it with the digit zero in the internal text, and replace it with the dollar sign in the external (listing) text, then continue scanning. Severity 1 (class C1: the compiler repairs and carries on). The literal-versus-non-literal split is our design decision and is marked non-historical. Scanned extent: columns 1-6 (Ctl. 1-3, Serial 4-6) and columns 73-80 (Identification) are never part of the language text and must not be gated; column 72 is the continuation column and is blanked in Data and Environment lines before scanning. The compiler listing reproduces card body columns 7-72.

**Rationale.** B.2 states the two replacements, and the message itself names both texts, so the repair is attested. What is not attested is the membership test, and it must be settled now because it is the lexer's character gate and because D0.5 makes illegal punch combinations representable on purpose (D0.5: "illegal punch combinations (J 90.04 msg 134) become representable, which the lexer tests need"). Definition §1.1 states that & % # @ and the record and group mark characters exist in the machine set but are not part of the source-language special-character list, which gives layer (b). Layer (c) follows §8.5.1: F's "any of the characters in the machine's character set" describes the abstract repertoire, and the quotation mark is unrepresentable inside a quoted constant, so the scanner runs to the next quote. The digit zero, not the blank, is the natural reading of "replaced ... by 0", because the message pairs it with the printable dollar sign. The scanned extent is attested: definition §1.9 states that the listing reproduces "body of source program cards (columns 7-72)" and that columns 1-6 and 73-80 are never part of the language text, so serial and control punches are inert and must not raise 134.

**Implementation.** Put the gate in the card-to-character stage, where the column-punch canon is decoded, so every later stage sees only legal characters. Keep two parallel texts per card, internal and external, as the message requires; the listing prints the external one. Count one diagnostic per illegal column, not one per card, so a badly punched card is fully reported. Take the gated span from one place (columns 7-72, minus column 72 where it is blanked), so the exclusion of columns 1-6 and 73-80 cannot drift. **Amended (M1, 2026-08-03):** the gate runs during scanning rather than in a context-free card pre-pass, because layer (c) makes legality depend on literal context, which only the scanner knows; consequently commentary after a sentence terminator, and fixed fields on continuation cards ("not scanned", [J 02.03.01] §2.d), are never gated. One message per illegal column holds within scanned text (docs/design/m1-front-end.md, M1-6).

**Oracle.** Oracle (4): a deck with an undefined punch combination, a deck with & outside a literal, and a deck with & inside a literal, each asserting the message count, the internal zero, and the external dollar sign; plus a deck carrying arbitrary punches in columns 1-6 and 73-80, asserting no message 134. Oracle (2): the 90.05 deck must produce no message 134, which also checks that the source character set is not too narrow.

*Citations:* ([J 90.04.01]) msg 134; definition §8.4 B.2 lexical row; definition §1.1 (character set and the five machine specials); definition §1.9 and §1.9.5 (columns 1-6 and 73-80 are never part of the language text; serialization and identification); §8.5.1 "Quotation mark inside a quoted constant"; ([J 02.02.01]); ([J 02.03.01]); D0.5; D0.6

### D9.11 — Advisory diagnostics with unrecoverable trigger criteria (msgs 170, 206, 86, 49, 104)

**Status.** Locked.
**Decision.** Hold all five at severity 1, so that none of them can change deck production or compile-and-go, and split them by whether their trigger is attested. CRITERION ATTESTED, SEVERITY OURS: 49 (SINGLE RECORD IN THE -PATTERN- ON -FILE- CARD ... INEFFICIENT PROGRAM PRODUCED.) fires exactly when a PATTERN lists one record, which the message itself states; 104 (-REDEF- OR -LABEL- OCCURRING BETWEEN NONFORMAT AND FORMAT DESCRIBED LEVELS MAY AFFECT POSITIONING ADVERSELY.) fires exactly on that structural position, which the message itself states. CRITERION INVENTED, marked non-historical, for three messages. 206 (inefficient subscript format) fires when a subscript variable's data format forces a run-time conversion before it can index, that is any format other than the one our code generator uses directly. 86 (difficult to program key setting) fires when a COND key setting names console keys that cannot be tested by a single machine test, so the generated test needs more than one instruction. 170 (WHEN substituted for IF) fires when an IF introduces a clause in a position where the conditional GO TO's WHEN belongs. The precise set of repaired placements stays open (Open Question 38). Our criterion for 170 therefore covers only that one attested case, and is recorded as a lower bound, not as the historical rule. Msg 49's checklist disposition is "reserved until D6": its criterion is attested, but no PATTERN can be parsed until the card syntax lands at D6/M5 (see the PATTERN record), so the criterion is unreachable until then and no code fires it.

**Rationale.** Three of these messages state a judgment, not a rule: the manuals never print the criterion behind "INEFFICIENT FORMAT", "DIFFICULT TO PROGRAM", or "IMPROPER USE", and Open Question 38 explicitly leaves message 170's trigger open. Two do state their own criterion in their own text, so marking them non-historical would send a later reader hunting for evidence that already exists. We cannot drop any of the five, since B.2 is the conformance list and each id needs a disposition, and we cannot recover the three lost criteria, so D0.4 makes each of those an explicit decision. Holding all five at severity 1 bounds the damage of a wrong guess: a false advisory changes only the listing, never the deck or the run. The severity values themselves are ours in all five cases (Open Question 65).

**Implementation.** Flag the three invented-criterion rows (170, 206, 86) in the checklist with "criterion invented", and the two attested-criterion rows (49, 104) with "criterion attested, severity ours", so a reviewer can find every place where our judgment stands in for a lost rule and is not misdirected to the two where it does not. Write the criterion as a single predicate function per message, next to its citation, so that new evidence changes one function. For 170, keep the repair itself (parse the IF as a WHEN) separate from the criterion, because the repair is attested and the criterion is not.

**Oracle.** Oracle (4) only. One positive and one negative test per criterion, except msg 49, whose tests wait for the D6 PATTERN syntax. Oracle (2) constrains them from above: the 90.05 sample compiles clean, so none of the five may fire on it; message 206 and message 104 in particular must stay silent on the sample's subscripted references and REDEF entries, which is a real check on an over-eager criterion.

*Citations:* ([J 90.04.01]) msgs 49, 86, 104, 170, 206; definition §8.4 B.2 subscripting, conditionals, data-description and environment rows; Open Question 38; Open Question 42 (open — the nearest adjacent text; it asks whether WHEN conditions and IF sentences share the compile-time constant folding and does not resolve it); Open Question 65; §8.5.6 "The PATTERN option — used but never defined"; Open Question 44; D0.4

### D9.12 — PATTERN rules with no recoverable syntax (msgs 48, 49, 50)

**Status.** Jack's call, 2026-08-02. It binds.
> **Resolved by Jack, 2026-08-02:** as proposed — bind the rules now, reserve the key word with the clearly non-historical "recognized but not implemented" diagnostic, defer the syntax to D6/M5 where any adopted form is marked a non-historical reconstruction.

**Decision.** Do not invent a PATTERN card syntax at M0. Bind the three rules now, and defer the syntax to D6 (input/output) at M5: a PATTERN names 2 to 16 records; a PATTERN with no record name gives message 48; a PATTERN with one record gives message 49 and compiles; more than 16 records gives message 50. Until a syntax is fixed, reserve the key word PATTERN in the FILE-card reader and emit a clearly marked non-historical diagnostic with an id outside the 0-209 range ("PATTERN option recognized but not implemented; see D6"). Do NOT emit message 96 (THERE IS AN ILLEGAL WORD IN THE -FILE- CARD.) or message 89 (-FILE- CARD FORMAT ERROR.) for the word PATTERN: §8.5.6 establishes PATTERN as a real FILE-card option, so an attested message would carry a false claim about 1962-valid source. GET RECORD FROM file.name remains unavailable for pattern files until the syntax lands. Any syntax we later adopt is a non-historical reconstruction and must be marked as such wherever it appears.

**Rationale.** §8.5.6 states that PATTERN is a real but undocumented FILE-card option and that its exact keyword syntax is unrecoverable from the manuals; Open Question 44 records the same gap. [J 02.07.04] makes GET RECORD FROM file.name legal when the file's records are included in a PATTERN, and messages 48-50 police it, so the feature and its rules are attested while the surface form is not. Inventing a card syntax now would add source-language text that no manual supports, which D0.4 forbids without an explicit decision, and nothing in M0 depends on it. Routing PATTERN to msgs 96 or 89 would be worse than inventing a syntax: it would make the reconstruction assert, in an attested 1962 message, that an attested-legal option is illegal. A non-historical id keeps the falsehood out of the attested message set. Binding the three rules now costs nothing and keeps the conformance list complete.

**Implementation.** Give messages 48, 49 and 50 a checklist disposition of "reserved until D6", with the rules recorded, so the ids are not silently missing. Register PATTERN as a reserved FILE-card word so the illegal-word check cannot claim it. Keep the record-count check in the environment binder, independent of the parse, so only the parse has to change when the syntax lands.

**Oracle.** Oracle (4) once the syntax exists: zero, one, sixteen and seventeen record names. Until then, a test that a FILE card containing PATTERN produces the non-historical "recognized but not implemented" diagnostic and neither msg 96 nor msg 89 nor any other attested message. No oracle stronger than (4) can exist here, since the 90.05 sample uses no PATTERN and [J 02.06] prints no general form.

*Citations:* ([J 90.04.01]) msgs 48, 49, 50, 89, 96; definition §8.4 B.2 environment rows; §8.5.6 "The PATTERN option — used but never defined"; ([J 02.07.04]); ([J 02.06.03]-07); Open Question 44; D0.4; D0.7

### D9.13 — System-generated names (msgs 173, 174) against the CRYPT symbol rules

**Status.** Locked.
**Decision.** Provide no source syntax for naming compiler-generated or runtime names. Treat messages 173 (REFERENCE MADE TO NON-EXISTENT SYSTEM GENERATED NAME.) and 174 (REFERENCE TO SYSTEM SUBROUTINE LACKS PROPER NUMBER. ZERO ASSUMED.) as integrity checks over the compiler's own generated references, raised in the code-generation and assembly stage, not as source-language diagnostics: 173 when a generated reference names a GN) or SYS) symbol that was never defined, 174 when a generated SYS) reference carries no number, in which case the number zero is assumed, as the message states. Severity: 173 in class C5 (severity 5, an internal inconsistency), 174 in class C1 (severity 1, the message states its own repair). No source or CRYPT name may contain a right parenthesis ([J 02.08.01]: the quotation mark, left parenthesis, right parenthesis and dollar sign "may not be used as part of a symbol"), while the right parenthesis stays a legal source character elsewhere (subscripts and arithmetic expressions, [J 02.08.01]). So no source program can write SYS)294 or GN)019 as a name.

**Rationale.** B.2's name row states that system-generated names are not user-referable, and the definition confirms that compiler-generated names contain a right parenthesis, which no programmer name can contain. The CRYPT rules close the last opening: [J 02.08.01] bars the quotation mark, left parenthesis, right parenthesis and dollar sign from CRYPT symbols. So no attested source form can produce these references, and the only remaining producer is the compiler itself, which puts these two messages next to message 69 (ILLEGAL INTERNAL CODE 'NAME.1' SENT TO ASSEMBLY. POSSIBLE COMPILER ERROR.). This reading is an inference: the two messages are not printed among the self-diagnostics in B.2's own list, so a lost source form cannot be excluded. It is recorded as a decision, and the alternative reading (that the CRYPT scanner accepted references to already-existing generated names while barring their formation) is noted for reversal if evidence appears.

**Implementation.** Wire both checks into the same pass that resolves generated symbols before deck output. Keep 174's repair (assume zero) real, so the check is testable and the pass does not abort. Note the interaction with message 108 (UNDEFINED SYMBOL) and with the compile-and-go gate at [J 02.01.02]: an undefined symbol in the code the compiler generated blocks execution independently of severity. That gate is what matters for msg 108, where a deck still exists; it adds nothing to msg 173, whose severity 5 already suppresses the deck and ends the job, so no separate not-runnable flag is needed for 173.

**Oracle.** Oracle (4) only. Inject a generated reference to an undefined GN) symbol and a numberless SYS) reference through a test hook, and assert the message, severity and repair. Also assert that no source or CRYPT name may contain a right parenthesis, per [J 02.08.01], while a subscripted reference such as L(5) still scans. Oracle (1) constrains the normal path: the 90.05 compilation generates many GN) and SYS) references and must raise neither message.

*Citations:* ([J 90.04.01]) msgs 69, 108, 173, 174; definition §8.4 B.2 name row and self-diagnostics list; definition §1 (compiler-generated names contain a right parenthesis; GN)nnn, SYS)294, CP)+NN); ([J 02.08.01]); ([J 02.01.02]); ([J 90.02.06]); D0.3

### D9.14 — Job stream and message 132 (*FINISH)

**Status.** Locked.
> **Clarified 2026-08-03 (D11.3):** the discarded deck is the object deck —
> the severity-5 suppression of J 02.01.01. The incomplete job is still
> scanned, parsed, and listed, and message 132 is recorded at end of input
> at statement 9999,99. The separate generated job-deck file this record
> provides for now exists: `test/fixtures/90.05-payroll-job.ctd` (D11.3).

**Decision.** Model a job stream, because severity 5 is defined as "stop compiling, proceed to the next job". The compiler reads a job deck: a compilation-initiating card ($CMPLE, with *COMPILE accepted as the historical synonym per §8.5.7), the source deck, and the terminating *FINISH card; several jobs may follow one another. If the input ends before a *FINISH card, issue message 132 (END OF FILE ON JOB TAPE WITHOUT *FINISH CARD.). Answering Open Question 8 as a design decision: message 132 takes severity 5, the current job's deck is discarded, and the run ends, since no next job can exist after end of file. For the 90.05 oracle, the *FINISH card is supplied by the test harness, which wraps test/fixtures/90.05-payroll.ct as one job; we do not edit the deck file. test/fixtures/90.05-payroll.ct is a provenanced 293-card artifact: card 1 is the *COMPILE control card, and cards 2-293 hold the *DATA, *ENVIRONMENT and *PROCEDURE material. Its notes restrict it to attested card content, so appending a card would change that artifact. If a canonical complete job-deck file is later wanted, it is a separate generated file whose notes mark the *FINISH card a reconstruction.

**Rationale.** The severity-5 rule at [J 90.04.02] and the *FINISH rule at [J 02.01.02] together require a job concept; without it, severity 5 cannot be implemented as attested and message 132 has no trigger. Open Question 8 asks the severity of message 132 and whether the partial compilation is completed; nothing settles it, so D0.4 makes it a decision. Discarding the deck is the conservative choice: the job never reached its terminator, so the source is known to be incomplete. On the missing *FINISH echo. The 90.05 listing echoes the compilation-initiating card (*COMPILE LIST, [J 90.05] listing, PDF p. 192) and then the source cards, and stops at the last source card. The absence of a *FINISH echo is therefore not evidence that the 1962 job lacked one. The argument is weaker than "source cards only" would suggest, because the listing does echo one control card. Supplying the card from the harness keeps the compiler free of a special case and keeps the deck artifact unaltered.

**Implementation.** Put the job loop above the compiler: it owns the control-card reader, the per-job diagnostic sink, and the severity-5 catch. The compiler proper compiles one job and knows nothing about the stream. The 90.05 test fixture concatenates test/fixtures/90.05-payroll.ct with a harness-supplied *FINISH card and marks that card a reconstruction in the fixture, not in the deck file; leave the deck notes' card table and its 293-card count untouched.

**Oracle.** Oracles (1) and (2): with the harness-supplied *FINISH card, the 90.05 job must still compile clean and diff clean. Oracle (4): a stream of two jobs where the first ends with a severity-5 error, asserting that the first produces no deck and the second compiles normally; an input ending without *FINISH, asserting message 132 at severity 5 and no deck; a test asserting that test/fixtures/90.05-payroll.ct itself is still 293 cards.

*Citations:* ([J 90.04.01]) msg 132; ([J 90.04.02]); ([J 02.01.01]); ([J 02.01.02]); definition §8.4 B.1 and B.2 statement-structure row; §8.5.7 "*COMPILE vs $CMPLE"; Open Question 8; ([J 90.05] listing, PDF p. 192); test/fixtures/90.05-payroll-deck-notes.md; D0.4; D0.5

### D9.15 — Compiler self-diagnostics: disposition of msgs 0, 18, 24, 29, 69, 85, 109, 124, 135-137, 140

**Status.** Locked.
**Decision.** Give every self-diagnostic id a disposition rather than dropping it. Two groups. (a) Internal-consistency checks that our compiler can still fail: 18, 24, 29 and 124 (ILLEGAL INTERNAL CONDITION. NOTHING DONE. POSSIBLE COMPILER ERROR.), 69 (illegal internal code sent to assembly), 109 (processor unable to find variable used as subscript) and 173. Map these onto real assertion failures in the corresponding stages, severity 5, so a compiler bug reports itself in 1962 form instead of throwing a Dart error. (b) Media and hardware failures that cannot occur in our implementation: 85 (permanent read error in phase 2), 135 (permanent read error for input), 136 and 137 (redundancy while writing or reading the external dictionary) and 140 (internal text synchronization failure). Mark these "unreachable by construction" in the checklist, keep their ids and texts reserved, and generate no code path for them. Message 0 (ERROR MESSAGE NOT YET IN FILE.) becomes the fallback our message table emits when an id has no text, which is a real check on table completeness.

**Rationale.** B.2 lists these as implying no language rule, but the conformance list keys every id 0-209, so each still needs a disposition, and half of them describe real compiler behavior we can preserve. The distinction between the two groups follows directly from D0.2: our compiler is written in Dart, so no tape read error or dictionary redundancy can arise, while internal inconsistency can. Keeping the unreachable ids reserved rather than deleted preserves the message table's completeness and the id numbering, which the checklist depends on.

**Implementation.** Implement group (a) as one internal-error reporting function that takes the message id and the current statement number, so that an assertion failure produces a normal severity-5 diagnostic and the normal severity-5 job behavior (no deck, next job). Do not catch programmer errors with it; it is for invariant violations only. Group (b) rows must carry a checklist note explaining why they are unreachable, so a later reader does not read the gap as an omission, plus the severity justification note: "Text implies continuation (COMPILATION SUSPECT / DUBIOUS COMPILATION), but §8.5.7 groups read and dictionary errors at severity 5; unreachable in our implementation, so the value is never exercised."

**Oracle.** Oracle (4): inject each group (a) condition through a test hook and assert message, severity 5, no deck, and continuation to the next job; assert that the message table's fallback for a missing id is message 0; assert that no code path references the group (b) ids. Oracles (1) to (3) cannot apply: the 90.05 sample compiles clean and no manual exhibits any of these messages in use.

*Citations:* ([J 90.04.01]) msgs 0, 18, 24, 29, 69, 85, 109, 124, 135, 136, 137, 140; definition §8.4 B.2 "Compiler self-diagnostics" table; §8.5.7 "Per-message severity codes are nowhere specified"; ([J 90.04.02]); D0.2; D0.3

### D9.16 — COND key setting length (msgs 6, 7) — the under-length case

**Status.** Locked.
**Decision.** Implement the COND card key setting as follows. ATTESTED: the setting 'nn' is an alphameric literal of 12 octal digits representing the "on" settings of the 36 console entry keys ([J 02.06.17]); a setting of more than 12 digits keeps the rightmost 12 and gives message 6 (-COND- CARD KEY SETTING EXCEEDS 12 DIGITS. RIGHTMOST 12 DIGITS USED.); a non-octal setting is replaced by key setting '1' and gives message 7 (...MUST BE OCTAL. KEY SETTING '1' USED.). DESIGN DECISION (non-historical), the under-length case, which no message covers: a setting of fewer than 12 octal digits is accepted, left-padded with octal zeros to 12 digits, and no diagnostic is issued. The excluded alternative — treating an under-length setting as a -COND- CARD FORMAT ERROR (msg 4) — is recorded in the row, so the choice is reversible if evidence appears.

**Rationale.** Open Question 68 asks exactly this: "Are shorter-than-12-digit COND key settings legal (padded) or an error?", citing msg 6 and [J 02.06.17], and nothing in either manual answers it. The compiler must do something with a 5-digit setting, so the conformance list needs a disposition and D0.4 makes it a recorded decision. We pad on the left because message 6's own recovery for the over-length case keeps the RIGHTMOST 12 digits, which treats the literal as right-aligned; left-padding with zeros is the same alignment and adds no "on" keys, so a short setting tests exactly the keys it names. We issue no diagnostic because the two printed messages cover only the over-length and non-octal cases, and inventing a diagnostic would add an unattested message to a closed set; strictness beyond attested compiler behavior belongs to --pedantic under D0.8, which may warn here.

**Implementation.** Do the length and radix checks in the environment-card reader, in the printed order: radix first (msg 7 replaces the whole setting with '1'), then length (msg 6 truncates to the rightmost 12), then the padding rule for the remaining short case. Hold the 12-digit width and the padding rule as rows in the same reviewable table as the other invented values, the padding row flagged non-historical. --pedantic may add a warning on an under-length setting; the default mode must not, and the padded value must be identical in both modes so the two never disagree about generated code.

**Oracle.** Oracle (4) only; the 90.05 sample has no COND card. Tests: a 13-digit setting gives msg 6 and keeps the rightmost 12; a setting containing 8 or 9 gives msg 7 and the value '1'; a 5-digit setting compiles silently in the default mode, warns under --pedantic, and generates the same key mask as the same setting written with five leading zeros; a 12-digit setting gives no diagnostic.

*Citations:* ([J 90.04.01]) msgs 4, 6, 7; ([J 02.06.17]); definition §8.4 B.2 numeric-limits row (msgs 6, 7); Open Question 68; D0.4; D0.8

## D10 — Correctness-review decisions (2026-08-03)

### D10.1 — SPECIF operand diagnostics: routing of msgs 153-160

**Status.** Locked.
**Decision.** Issue each dedicated SPECIF message at the site that detects its condition: 154 when the first description item is not a file name ([J 02.06.08]); 155 when no alphameric literal follows UNIT1 or UNIT2; 156 and 157 when no alphameric literal follows SERIAL or REEL; 158 when no numeric integer follows RETAIN; 159 when no numeric integer follows ACTIVITY. Issue 160 (ALPHABETIC LITERAL FOLLOWING KEY WORD CANNOT EXCEED 6 CHARACTERS.) for an over-length literal after a SPECIF key word, and enforce each option's own bound: 6 characters for UNIT1 and UNIT2 (the message's own figure; no per-option bound is documented), 5 for SERIAL and 4 for REEL ([J 02.06.12]). The over-length operand is dropped, the same operand-level recovery as the missing-operand messages. Keep 153 as the fallback for SPECIF faults that no dedicated message covers: an unknown option word, an ACTIVITY integer outside 1-99, a non-numeric REEL literal of legal length, and a RETAIN number of more than 3 digits.

**Rationale.** The 90.04 catalog attests one message per condition (154-160), and the review found all seven conflated into the generic 153, which also inflated the severity of operand-level faults from 2 to 3 (severity-notes.md puts 155-160 in the C2 operand family and 153-154 in the C3 whole-card family). The open point was whether an over-length SERIAL or REEL literal takes 160 or stays 153, because 160's printed text states a 6-character bound and [J 02.06.12] states 5 for SERIAL and 4 for REEL. We route them to 160: it sits in the SPECIF block (153-160 are all SPECIF messages); it is the only attested over-length message for SPECIF literals; and its class (C2, one operand lost) matches the fault, where 153 misnames the fault as a whole-card error. The printed 6-character figure matches no punch field — the generated *FILE card holds unit1 in 4 columns (18-21), unit2 in 4 (22-25), reel in 4 (38-41), serial in 5 (44-48) and retention days in 3 (51-53) ([J 90.08.01]) — so we read 6 as the compiler's one-word (6-character BCD) literal store, checked once for every key-word literal. We enforce the tighter documented bounds for SERIAL and REEL and accept that the printed text states the loosest bound. RETAIN keeps 153 for its over-length case because 160 names alphabetic literals and RETAIN's operand is numeric ([J 02.06.12]). The excluded alternative — 153 for a literal over its option bound but within 6 characters — is recorded here for reversal if evidence appears.

**Implementation.** `lib/src/parser/parser_messages.dart` holds the catalog references for 154,00-160,00; `_parseSpecifCard` in `lib/src/parser/environment_parser.dart` issues them. Each fallback-153 site carries a comment naming this decision.

**Oracle.** Oracle (4): one test per id in `test/environment_parser_test.dart`, plus fallback tests for the three 153 cases. Oracle (2) constrains from above: the 90.05 sample's seven SPECIF cards must keep drawing zero diagnostics.

*Citations:* ([J 90.04.01]) msgs 153-160; ([J 02.06.08]); ([J 02.06.10]-12); ([J 90.08.01]); docs/design/severity-notes.md (C2 card-option-operand family); D7.8

### D10.2 — The diagnostic sink and the severity-5 stop in every phase

**Status.** Locked.
**Decision.** Implement D9.1's "one diagnostic sink object" as `DiagnosticSink` (`lib/src/lexer/diagnostic.dart`): the ordered diagnostic list plus the running maximum severity. Recording a severity-5 diagnostic sets the sink's stopped flag and throws `StopCompilation`, so the phase that detects the condition stops at the point of detection — the front end included, which previously scanned on after a severity-5 row (review finding DIAG-2). The driver creates one sink per job and passes it to `runFrontEnd` and `runParser`; the scanners and the parser record into it directly. Each phase function catches `StopCompilation` itself and returns its partial result with a `stopped` flag; the driver skips the parser when the front end stopped, and keeps a `StopCompilation` net around both phases for any future phase that does not catch.

**Rationale.** [J 90.04.02]: "An error severity code of 5 causes the compiler to stop compiling. It then proceeds to the next job." D9.1 (c) records the rule as attested with no phase exemption, and M2-13 already gave the parser the stop path; the front end lacked one, so message 148,00 (severity 5) let the whole deck scan and parse on. The phase-internal catch, rather than a throw through to the driver, is required by the listing: a thrown exception discards the phase's return value, and the compilation listing needs the partial `FrontEndResult` (source echo, statement numbers, diagnostics up to the stop). The per-job catch D9.1 assigns to the job driver moves there when the M2-15 job loop lands; the driver's net is its placeholder.

**Implementation.** The scanners (`scanDataDescription`, `scanEnvironment`, `scanProcedure`) take an optional sink and keep their per-scan diagnostic lists as slices of it, so scan results are unchanged for direct callers; a plain list (no stop path) remains usable in unit tests of one scanner or parser function. `runParser` reads its slice the same way, so `ParseResult.parserDiagnostics` and the merged ordering (M2-2) are unchanged. The parser's explicit severity-5 throws (msgs 149, 915) stay for plain-list callers; under a sink the throw comes from the recording itself.

**Oracle.** Oracle (4): `test/parser_test.dart` "the severity-5 stop path (D9.1; D10.2)" — a front-end 148,00 stops the scan at its point (later faults undiagnosed, later groups unscanned), a parser 149,00 stops the parse on the shared sink, and a clean two-phase run keeps one sink with the running maximum. Oracle (2): the 90.05 compilation is unaffected (zero diagnostics).

*Citations:* ([J 90.04.02]); decisions.md D9.1 (c) and Implementation; docs/design/m2-parser.md M2-13, M2-15; docs/design/severity-notes.md (148 = C5)

### D10.3 — Numeric-literal length: what the 50-character limit counts

**Status.** Locked.
**Decision.** The over-50 check for numeric and floating literals counts digit characters only. Two exclusions are ATTESTED. The decimal point "will not occupy an actual place in storage, and it is not counted in determining the length of the literal" ([F p. 18], rule 2). The F "will not occupy a space in storage, and it is not counted in determining the length of the literal" ([F p. 18], rule 4); the FF double-precision marker likewise. DESIGN DECISION (non-historical): the exponent sign inside a floating literal is excluded too, and the exponent digits count. F settles neither; a sign is stored as an overpunch, not a character position, and the exponent digits are characters of the number itself. The leading sign of a literal is a separate token in this scanner, so it never enters the count.

**Rationale.** The prior check measured the raw token text, so a legal 50-digit literal written with its decimal point (51 characters) drew a false 52,00 at severity 2, which blocks compile and go (review finding LEX-3). D1.2 fixes only the limit value (50) and the message choice (52,00); the counting rule was unrecorded. Digits-only is the smallest rule that satisfies both attested exclusions and keeps the check monotone.

**Implementation.** `_scanNumber` in `lib/src/lexer/procedure_lexer.dart`: the check counts the token text's digit characters. No --pedantic delta.

**Oracle.** Oracle (4): 50 digits plus a decimal point scan clean; 51 digits draw 52,00 (`test/procedure_lexer_test.dart`). Oracle (2): the 90.05 sample is unaffected.

*Citations:* ([F p. 18], rules 1, 2, 4); definition §1.7.1 and §1.10; docs/design/decisions.md D1.2; ([J 90.04.01]) msg 52

### D10.4 — Compile control cards after the first are ignored at any deck position

**Status.** Amended.
> **Amended 2026-08-03 (D11.1):** the M2-15 job loop is in force, as this
> record anticipated. A compile card after a division header now starts the
> next job. Only the duplicate before any division header keeps message 904.
> The position-independent recognition rule — a compile card is never read
> as source text — stands unchanged.

**Decision.** The deck splitter recognizes a compile control card ($CMPLE in columns 1-6, *COMPILE from column 7) at any deck position. The first one, before any division header, is the job's compile card. Every other one — a duplicate before the headers (M1-2), or any compile card after a division header — is ignored with message 904,00. The M2-15 job loop supersedes this rule when it lands: a mid-deck $CMPLE then starts the next job (D9.14).

**Rationale.** M1-2 records "A second compile control card is ignored with our message 904", but the check ran only before the first division header, so a mid-deck $CMPLE or *COMPILE card was scanned as division source text with cascade diagnostics and 904 never fired (review finding LEX-8). One rule for every position keeps the card from ever being read as source text. A compile card that appears mid-deck with no earlier one also draws 904: its text says "duplicate", which is inexact for that degenerate deck, but the card is equally out of place and equally ignored, and a second non-historical message would add nothing.

**Implementation.** `SourceProgram.fromDeck` in `lib/src/lexer/source_program.dart`: the compile-card check runs before the group dispatch and accepts the card only when no compile card was seen and no group is open.

**Oracle.** Oracle (4): a compile card after a header draws 904,00 and joins no division group (`test/source_program_test.dart`). Oracle (2): the 90.05 deck's single *COMPILE card is unaffected.

*Citations:* docs/design/m1-front-end.md M1-2; docs/design/m2-parser.md M2-15; decisions.md D9.14; ([J 02.01.01])

### D10.5 — Clause-separator leniencies the parser accepts silently

**Status.** Locked.
**Decision.** The procedure parser accepts three punctuation forms the manuals do not show. It accepts them silently, as recorded non-historical leniencies. (a) A comma before OTHERWISE, where [F p. 25] writes OTHERWISE next "without intervening punctuation". (b) AT END without the preceding comma, where [F p. 40]'s general form and all four sample GETs write `..., AT END`. (c) A trailing comma directly before the terminating period. Each is a leniency of ours, not an attestation. The excluded alternative — a repair-and-continue C1 warning per form — is recorded here for reversal; --pedantic may raise all three later (D0.8).

**Rationale.** The review (finding PROC-10) showed all three as unrecorded, and (c) as resting on a misread citation: the 90.05 listing's statement 188 comma (`START. OPEN ALL FILES,`) is a mid-sentence separator before a continuation card, not a comma before the period — the code comment now says so. What the 1962 compiler did with these forms is unattested. Deleting a sentence for a harmless separator would be an invented severity; an invented warning would add a non-historical message for punctuation the repaired text makes unambiguous. Recording the leniency is the smallest claim.

**Implementation.** `_parseClauseSeries` and `_parseGet` in `lib/src/parser/procedure_parser.dart`, unchanged in behavior; the statement-188 comment is corrected. This entry is the record M2-11's file cannot take (m2-parser.md is owned by a parallel stream).

**Oracle.** Oracle (2): the 90.05 sample uses the attested punctuation throughout and compiles clean. No oracle covers the lenient forms; decision-conformance only.

*Citations:* ([F p. 25]); ([F p. 27], rule 5); ([F p. 40]); ([J 90.05] listing, statement 188,00); D0.8

### D10.6 — Message 917: a function argument that is not a data-name

**Status.** Locked.
**Decision.** A function-reference argument that is not a data-name (and not a figurative constant, which [F p. 34] shows used "as a data-name") draws the non-historical message 917,00 — FUNCTION ARGUMENT IS NOT A DATA NAME AND IS DROPPED. — at class C2, and the token is dropped. Message 116,00 (MISSING OPERAND ASSUMED TO BE ZERO.) no longer fires there: its text states a zero repair the argument list cannot take ([F p. 28] rule 15 types the entries as data-names), so the message misdescribed the real recovery (review finding DIAG-4).

**Rationale.** The rule is attested ([F p. 28], rule 15); no 90.04 message states the dropped-argument recovery, so the D9.7 pattern applies: a new id outside 0-209, text closing with (NON-HISTORICAL.). C2 fits D9.2's largest-lost-unit rule — one operand is lost, and the shortened list surfaces later through msg 30's argument-count check (M3).

**Implementation.** `parseFunctionCall` in `lib/src/parser/expression_parser.dart`; the severity row and checklist row carry this entry's id.

**Oracle.** Oracle (4): `test/expression_parser_test.dart` asserts the message and the dropped argument. Oracle (2): the 90.05 sample declares no functions and stays silent.

*Citations:* ([F p. 28], rule 15); ([F p. 34]); ([J 90.04.01]) msgs 30, 116; decisions.md D9.2, D9.7

### D10.7 — Verb source operands: the function reference and the signed literal (M2-8 cross-reference)

**Status.** Locked.
**Decision.** The source-operand alternative set of MOVE, ADD, and DO USING (design note M2-8's enumeration: name | literal | figurative) gains two attested alternatives. (a) The double-parenthesis function reference: [F p. 34] prints `MOVE MINIMUM ((CALCULATED.PRICE, MARKET.PRICE, HIGH.VALUES)) TO PRICE.LIST.` as a statement the programmer could write, and J retains the function machinery (msgs 30, 68). (b) The signed numeric literal: [F p. 18] rule 2 defines numeric literals as optionally signed, and [F p. 47] grants ADD a literal source; the scanner tokenizes the sign separately, so the operand parser consumes it as the literal's own sign, exactly as the expression parser already reads [F p. 18]. DESIGN DECISION (non-historical): a DO control parameter (EXACTLY n; the p, q, r of the indexed form) also accepts a signed integer, on the same [F p. 18] reading — [F pp. 50-51] say "integer" and never show a sign there.

**Rationale.** Review findings PROC-2 and PROC-9: the parser deleted both attested forms with msgs 119/122. M2-8's own correction history tracks attestations, and this entry is the cross-reference its file cannot take (m2-parser.md is owned by a parallel stream, precedent: the D7.4-to-D9.8 cross-reference).

**Implementation.** `_parseSourceOperand` and `_parseDoParameter` in `lib/src/parser/procedure_parser.dart`; the function-call form is shared with the expression parser (`parseFunctionCall`).

**Oracle.** Oracle (4): `test/procedure_parser_test.dart` covers the [F p. 34] MOVE, a DO USING function argument, `ADD -1`, and a signed DO step. Oracle (2): the 90.05 sample is unaffected.

*Citations:* ([F p. 34]); ([F p. 28], rule 15); ([F p. 18], rule 2); ([F p. 47]); ([F pp. 50-51]); ([J 90.04.01]) msgs 30, 68; docs/design/m2-parser.md M2-8

### D10.8 — Data and environment name bars, the mandatory BLOCKSIZE, and the 63-file tally

**Status.** Locked.
**Decision.** Three calls from the data/environment remediation (review findings DATA-3, DATA-6, DATA-10). (a) A J list-1 or list-2 key word declared as a Data or Environment name — a data entry name, an environment specification name, or a FILE-card record name — draws msg 178 (PROCEDURE KEY WORD USED IN DATA OR ENVIRONMENT, INTERPRETED AS A DATA NAME.), the name is kept as a data name, and parsing continues. D1.5 attests the recovery for list 2; we apply the same message to list 1: a list-1 word is a key word, the message's text covers it, and its recovery is the attested one for the misuse class — no non-historical message is needed. (b) A non-checkpoint FILE card with no BLOCKSIZE keyword draws msg 89 (-FILE- CARD FORMAT ERROR.): "This specification must be made" ([J 02.06.04]) is attested and card-local, and no dedicated absence message exists; the minimum-24 and maximum-9999 range checks stay with the M3 data mapper per D7.1. (c) The 63-file limit ([J 90.01.04]; msg 193) is a program-wide FILE-card tally: the driver threads one tally through every environment group of a job, and each FILE card past the 63rd draws 193. A group parsed alone counts its own cards only.

**Rationale.** (a) The alternative — a new 9xx message for list-1 misuse — would put an invented text next to an attested one for the same misuse class and recovery. The bar's difference (list 1 is barred in every division) matters to the Procedure division, where D1.5 already prescribes msg 192. (b) The alternative deferral to M3 has no recorded basis; presence is checkable at parse time and the whole-card message class (C3) matches a card that cannot bind I/O. (c) A per-group count would miss the limit in a program with several *ENVIRONMENT groups; the tally mirrors how the CONTRL name-uniqueness set already spans a group's cards.

**Implementation.** `_parseEntry` and `parseEnvironmentGroup`/`_parseFileCard` (msg 178, via the shared reserved-word classes); the post-loop BLOCKSIZE presence check in `_parseFileCard`; `FileCardTally` in `lib/src/parser/environment_parser.dart`, created per job in `runParser`.

**Oracle.** Oracle (4): `test/data_parser_test.dart` and `test/environment_parser_test.dart` cover the three calls, the checkpoint exemption, and the cross-group tally. Oracle (2): the 90.05 sample (7 FILE cards, no barred names, BLOCKSIZE on every card) stays clean.

*Citations:* ([J 02.03.02]-03); ([J 90.04.01]) msgs 89, 178, 193; ([J 02.06.04]); ([J 90.01.04]); decisions.md D1.5, D7.1; docs/design/m2-parser.md M2-7

## D11 — M2 stage 3: the job stream (2026-08-03)

*Recorded 2026-08-03, before the stage-3 implementation (M2-15). The
evidence pass behind these records read [J 02.01], 04.01–04.02, 05.03,
90.01, 90.04, and the 90.05 listing, and confirmed every card-format
claim against the page scans (images/page-010.png, page-011.png,
page-099.png). D11.1 amends D10.4; D11.3 clarifies D9.14.*

### D11.1 — The job splitter: card-level job boundaries

**Status.** Locked.
**Decision.** The driver splits the deck into jobs above the compiler (D9.14). The splitter models the CT monitor's compile-only job stream: the sequence [J 04.02.01] diagrams between $EXECUTE CT and $IBSYS. Its rules, applied in card order:

(a) A job starts at the deck's first card. A compile card — $CMPLE in columns 1–6, or *COMPILE from column 7 (D7.12) — starts the next job when the current job has seen a division header or a *FINISH card. After a terminated job, the next job opens at the first compile card or division header; a header opens a compile-card-less job, silently. A compile card before any division header of the current job stays the D10.4 duplicate: message 904, card ignored.
(b) A *FINISH card ([J 02.01.02]) closes the current job. The splitter consumes the card; it never reaches the front end, so the listing never echoes it. The 1962 listing echoes the compile card and no *FINISH ([J 90.05] listing, PDF pp. 192, 197), so consumption keeps the golden listing byte-identical.
(c) Between jobs, the splitter stands in for the monitor. It silently skips two attested cards. First, the end-of-file card: columns 1 and 2 punched in rows 8 and 7, columns 3 and 4 punched in rows 7, 4, 1, and 12 ([J 05.03.01], scan-checked against images/page-099.png, 2026-08-03). J calls it "an integral part of every job deck". Second, the optional $ID accounting card ([J 05.03.02]; [J 04.02.02]). The monitor zone is: before the first job's first card, and after any *FINISH up to the next job's first card, per rule (a). Wholly blank cards in the zone are skipped, per the M1 blank-card rule.
(d) Any other card between a *FINISH and a following job joins that job's leading cards, where it draws message 902 (card precedes the first division header). A card after the last *FINISH, with no job following, draws message 903. Message 903 therefore covers the single-job tail case only (M2-15). The tail diagnostics carry card numbers above the last job's cards, so the merged diagnostic block keeps card order (M2-2).
(e) A job closed by a following compile card — no *FINISH of its own — is accepted silently. This leniency is non-historical: J separates jobs with a tape end-of-file mark, never with a card scan ([J 05.03.01]), so no manual describes this boundary. --pedantic warns on it with message 929 (D11.4).
(f) The other CTM and Basic Monitor control cards — $LOAD, $SUBUP, $MAIN, $PAUSE, $ENDREEL, $IBSYS, $DATE, $EXECUTE, and the rest of [J 04.02.02]–03 and 04.01 — are outside the compile-only stream this record models. They draw message 902 or 903 by position, per rule (d). A later milestone may extend the splitter to more job types; this record binds the compile-job case only.

**Rationale.** D9.14 requires the loop above the compiler: the compiler proper compiles one job and knows nothing about the stream. J's own job separator is the tape end-of-file mark, not a card scan ([J 05.03.01]), so every card-level rule here beyond $CMPLE and *FINISH recognition is our design, and each is marked. The splitter skips the end-of-file card and $ID silently because J prints both inside the attested stacked-job example ([J 05.03.02]); a diagnostic against the attested form would punish a correct 1962 deck, against D0.8. Junk between jobs joins the next job rather than the closed one, so a stray card cannot raise a finished job's severity after its *FINISH accepted the job.

**Implementation.** `splitJobs` beside the driver. `SourceProgram.fromDeck` loses its *FINISH and message-903 path — the splitter owns both — and keeps messages 902 and 904. The `finishCard` field leaves `SourceProgram`; the 903 tests move to the splitter's test file.

**Oracle.** Oracle (4): two- and three-job decks; boundary junk in every zone; end-of-file and $ID cards at the deck head, between jobs, and at the tail; a *FINISH consumed with no echo; a duplicate compile card before headers still draws 904; a division header after a *FINISH opens a compile-card-less job. Oracle (2): the 90.05 job deck (D11.3) compiles clean and diffs clean.

*Citations:* ([J 02.01.01]); ([J 02.01.02]); ([J 04.01.01]); ([J 04.02.01]-03); ([J 05.03.01]); ([J 05.03.02]); ([J 90.05] listing, PDF pp. 192, 197); D9.14; D10.4; D7.12; D0.8; docs/design/m2-parser.md M2-15

### D11.2 — Per-job compilation state, numbering, listings, and the exit code

**Status.** Locked.
**Decision.** Each job compiles as an independent program. The driver creates one fresh `DiagnosticSink` per job (D10.2), runs the front end and the parser once per job, and prints one listing per job, in deck order, each starting at page 1. Statement numbers restart at 1,00 for each job. DESIGN DECISION (non-historical): the restart. The only numbered listing in either manual is the single-job 90.05 sample (1,00–229,00), and nothing states what a second job's numbers do. The process exit code keeps its current meaning across the whole deck: 0 when no job reaches severity 5, 1 when any job does ([J 90.04.02]), 2 for a usage error. Lower severities never change the exit code; they suppress the future object program per [J 90.04.02], not the process result.

**Rationale.** Restart is the one numbering choice that needs no cross-job state, which D9.14's locked implementation model denies the compiler proper. A fresh sink per job is D10.2's rule; a shared sink would let one job's severity-5 stop starve the next job, against "It then proceeds to the next job" ([J 90.04.02]).

**Implementation.** The job loop in `bin/comtranc.dart`; the worst severity is tracked across jobs for the exit code only.

**Oracle.** Oracle (4): a two-job deck whose first job stops at severity 5 — the second job compiles clean, numbered from 1,00, and the process exits 1; a clean two-job deck exits 0, with two listings in deck order. Oracle (2): the 90.05 job deck compiles unchanged.

*Citations:* ([J 90.04.02]); ([J 02.02.01]); ([J 90.05] listing, PDF pp. 192-197); D9.14; D10.2

### D11.3 — Message 132 at end of input, and the 90.05 job deck

**Status.** Locked.
**Decision.** When the deck ends while a job is open — no *FINISH closed it — the driver compiles the job as read, then records message 132 (END OF FILE ON JOB TAPE WITHOUT *FINISH CARD.) at severity 5 (D9.14; Open Question 8). The diagnostic references statement 9999,99, the attested number for "errors which are not confined to a single source statement" ([J 02.02.01]); it carries no source card. The job's listing prints, with 132 in its diagnostic block, and the run ends. D9.14's "the current job's deck is discarded" means the object deck: severity 5 suppresses it ([J 02.01.01]). The source is still scanned and parsed for diagnosis, because a streaming reader has processed every card by the time end of input is detectable. A dated note on D9.14 records this clarification.

Under this rule the raw 90.05 artifact (`test/fixtures/90.05-payroll.ctd`, 293 cards, no *FINISH) is an incomplete job and draws 132 by design. Its keying notes restrict it to attested card content, and D9.14 presumes the 1962 job's own *FINISH existed off-listing. The acceptance compile therefore moves to a complete job deck, `test/fixtures/90.05-payroll-job.ctd`: the same 293 cards plus one *FINISH card, generated through `deckconv`, with the *FINISH marked a reconstruction in the fixture notes. This is the separate generated file D9.14 itself provides for. The 293-card artifact stays untouched; a test asserts its count. `CLAUDE.md` and `docs/HANDOVER.md` point the acceptance command at the job deck.

**Rationale.** In J's model the tape always ends with a physical end-of-file mark, so "end of file without *FINISH" is detectable and attested as message 132's trigger ([J 90.04.01]). Our deck end is our end of file (D9.14). A 1962 run of the 293 program cards alone — no *FINISH, then the tape mark — would have drawn 132; the 1962 compile succeeded because the real job deck was complete. Compiling the job as read, rather than suppressing the listing, follows the detection point: nothing remains to stop at end of input, and the listing's diagnosis is the only value left in the job.

**Implementation.** The splitter marks the open job; the driver records 132 into that job's sink after the parse, inside its `StopCompilation` net. `Diagnostic` accepts a card-less form that renders as statement 9999,99 in the diagnostic block. The message-checklist row for 132,00 flips from `reserved` to `enforced` with its test reference.

**Oracle.** Oracle (4): a deck ending mid-job draws 132 at severity 5, statement 9999,99, exit 1, with the partial listing printed; the raw 90.05 artifact draws exactly one diagnostic, 132, and stays 293 cards. Oracle (1) and (2): the 90.05 job deck compiles with zero diagnostics and a byte-identical golden listing.

*Citations:* ([J 90.04.01]) msg 132; ([J 90.04.02]); ([J 02.01.01]); ([J 02.01.02]); ([J 02.02.01]); ([J 05.03.01]); Open Question 8; D9.14; D0.4

### D11.4 — The --pedantic flag: mechanism and the M2 site set

**Status.** Amended.
**Decision.** `bin/comtranc.dart` gains `--pedantic` (D0.8), off by default. A boolean threads as an optional parameter through `runFrontEnd`, `runParser`, and the scanners and parsers that own a site. The mode holds one invariant: **--pedantic adds diagnostics and changes nothing else.** Every parse result, repaired value, and generated value is identical in both modes, and no existing message id changes severity (D9.2; D9.16). Each pedantic diagnostic takes its own non-historical id (D9.7 pattern). The two escalation records are satisfied by grade alone: D3.4's REDEF-line name is already discarded in both modes, and D6.6's non-transfer AT END clause is kept as parsed in both modes; under --pedantic each site issues its own error-class id in place of the default-mode warning (918, 911), leaving both recoveries untouched.

The M2 site set, implemented this stage:

| Id | Class | Site | Owning record |
|---|---|---|---|
| 919,00 | C1 | A Data Description constant continued across cards against [F p. 83] | D1.1 |
| 920,00 | C1 | A procedure-name terminating period+blank omitted | D1.3; D9.4(a) |
| 921,00 | C2 | A name on the REDEF line, escalated in place of 918 | D3.4 |
| 922,00 | C3 | A non-transfer AT END clause, escalated in place of 911 | D6.6 |
| 923,00 | C1 | A deck.name with imbedded blanks ([J 02.01.01] forbids them) | D7.11 |
| 924,00 | C1 | An input FILE clause record.name.2 with no leading comma | D8.5 |
| 925,00 | C1 | A COND key setting of fewer than 12 octal digits | D9.16 |
| 926,00 | C1 | A comma before OTHERWISE | D10.5(a) |
| 927,00 | C1 | AT END without the preceding comma | D10.5(b) |
| 928,00 | C1 | A trailing comma directly before the terminating period | D10.5(c) |
| 929,00 | C1 | A job closed by a compile card instead of *FINISH | D11.1(e) |

The deferred sites stay with their owning milestones, so the flag's coverage is auditable from this table: D4.11 and D4.12 (M3/M4 move semantics), D4.13 (M3 name resolution), D5.1 (constant DO parameters), D5.7 (the DO call graph), D6.2–D6.5 and D6.3's object-time reopen message (M5 I/O), D6.1 (M5 PATTERN syntax), and D3.5's candidate (M3 justification). Each lands with its milestone and cites this record.

**Rationale.** D0.8 defines the mode: written-language strictness beyond attested compiler behavior, clearly marked non-historical. D9.2 forbids re-grading an id between modes; a pedantic-only id at its own fixed severity keeps every id's severity single-valued while following D3.4's and D6.6's explicit escalation texts. The diagnostics-only invariant generalizes D9.16's oracle — "the padded value must be identical in both modes" — to every site, and makes one global test possible.

**Implementation.** The sites and their code locations: 919 in `lib/src/lexer/data_lexer.dart` (the D1.1 continuation join); 920 in `lib/src/lexer/procedure_lexer.dart` (the `labelHadPeriod` record); 921 in `lib/src/parser/data_parser.dart` (the 918 site); 922 in `lib/src/parser/procedure_parser.dart` (the 911 site); 923 in `lib/src/parser/control_parser.dart`; 924 in `lib/src/parser/environment_parser.dart` (the D8.5 branch); 925 in `_normalizeCondKeys`; 926–928 in `_parseClauseSeries` and `_parseGet`; 929 in the job splitter. Severity rows and checklist rows land with the code.

**Oracle.** Oracle (4): one test per site — silent in default mode, the pedantic diagnostic under `--pedantic`, and the parse result identical in both modes; the two escalations additionally assert that 918 and 911 are replaced, not doubled. Oracle (2): the 90.05 job deck compiles clean in both modes.

**Amended (M3 stage 2, 2026-08-04).** Oracle (2)'s clause "clean in both modes" is superseded. The deferred D4.11 site is live from M3 stage 2, and its note fires on the sample's own doubtful moves. The 90.05 job deck compiles clean in default mode. Under `--pedantic` it draws exactly three 943,00 notes. Each note is clause-confined, so the listing's NUMBER column prints the clause digits (M2-6). Statement 205's MOVE BLANKS clause draws 205,03 twice, one note per blanked edited target. Statement 220's draws 220,03 once ([J 90.05] listing PDF pp. 196–197). D4.11 already excludes the note from any listing used for listing-diff. The diagnostics-only invariant stands.

*Citations:* D0.8; D9.2; D9.7; D9.16; D1.1; D1.3; D9.4; D3.4; D6.6; D7.11; D8.5; D10.5; ([J 02.01.01]); ([F p. 83])

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 12]: ../../comtran-manuals/F28-8043/02-language-structure.md#underlying-principles
[F p. 15]: ../../comtran-manuals/F28-8043/02-language-structure.md#condition-names
[F p. 18]: ../../comtran-manuals/F28-8043/02-language-structure.md#constants
[F p. 19]: ../../comtran-manuals/F28-8043/02-language-structure.md#numeric-literals
[F p. 25]: ../../comtran-manuals/F28-8043/02-language-structure.md#clauses
[F p. 26]: ../../comtran-manuals/F28-8043/02-language-structure.md#sentences
[F p. 27]: ../../comtran-manuals/F28-8043/02-language-structure.md#divisions
[F p. 28]: ../../comtran-manuals/F28-8043/02-language-structure.md#punctuation-and-spacing
[F p. 30]: ../../comtran-manuals/F28-8043/02-language-structure.md#lists-tables-and-subscripts
[F p. 31]: ../../comtran-manuals/F28-8043/02-language-structure.md#subscripts
[F p. 34]: ../../comtran-manuals/F28-8043/02-language-structure.md#functions
[F p. 37]: ../../comtran-manuals/F28-8043/03-procedure-description.md#commands
[F p. 40]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-get-command
[F p. 41]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-file-command
[F p. 42]: ../../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F p. 43]: ../../comtran-manuals/F28-8043/03-procedure-description.md#editing-feature
[F p. 44]: ../../comtran-manuals/F28-8043/03-procedure-description.md#editing-feature-1
[F p. 46]: ../../comtran-manuals/F28-8043/03-procedure-description.md#truth-functions
[F p. 47]: ../../comtran-manuals/F28-8043/03-procedure-description.md#set-used-with-condition-names
[F p. 49]: ../../comtran-manuals/F28-8043/03-procedure-description.md#assigned
[F pp. 50-51]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command
[F pp. 50–51]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command
[F p. 51]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-indexing
[F p. 54]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-named-end
[F p. 58]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-begin-section-and-end-commands
[F p. 59]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-include-command
[F pp. 74-75]: ../../comtran-manuals/F28-8043/04-data-description.md#redef
[F p. 75]: ../../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 77]: ../../comtran-manuals/F28-8043/04-data-description.md#copy
[F p. 79]: ../../comtran-manuals/F28-8043/04-data-description.md#justify-col-37
[F p. 80]: ../../comtran-manuals/F28-8043/04-data-description.md#format-characters
[F p. 83]: ../../comtran-manuals/F28-8043/04-data-description.md#quantities-specified-in-named-fields
[F p. 107]: ../../comtran-manuals/F28-8043/a2-supplementary-information.md#rules-for-forming-arithmetic-expressions
[F p. 109]: ../../comtran-manuals/F28-8043/a2-supplementary-information.md#list-of-commercial-translator-commands
[F p. 111]: ../../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[F p. 115]: ../../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[F p. 116]: ../../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[J 02.01]: ../../comtran-manuals/J28-6169/02-compiler.md#0201-compiler-control-cards
[J 02.01.01]: ../../comtran-manuals/J28-6169/02-compiler.md#0200-introduction
[J 02.01.02]: ../../comtran-manuals/J28-6169/02-compiler.md#a-cmple-card
[J 02.02.01]: ../../comtran-manuals/J28-6169/02-compiler.md#b-finish-card
[J 02.03.01]: ../../comtran-manuals/J28-6169/02-compiler.md#0202-compiler-output
[J 02.03.02]: ../../comtran-manuals/J28-6169/02-compiler.md#a-use-of-coding-forms
[J 02.03.03]: ../../comtran-manuals/J28-6169/02-compiler.md#b-key-words
[J 02.04]: ../../comtran-manuals/J28-6169/02-compiler.md#0204-procedure-description-clarification-and-amplification
[J 02.04.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-effect-of-data-storage-mode-on-arithmetic-efficiency
[J 02.04.02]: ../../comtran-manuals/J28-6169/02-compiler.md#1-figurative-constants
[J 02.04.02.01]: ../../comtran-manuals/J28-6169/02-compiler.md#2-literals
[J 02.04.03]: ../../comtran-manuals/J28-6169/02-compiler.md#2-display
[J 02.04.04]: ../../comtran-manuals/J28-6169/02-compiler.md#3-move
[J 02.04.05]: ../../comtran-manuals/J28-6169/02-compiler.md#4-corresponding-option-with-move-and-add
[J 02.04.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.06]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.07]: ../../comtran-manuals/J28-6169/02-compiler.md#c-conditional-statements
[J 02.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.02]: ../../comtran-manuals/J28-6169/02-compiler.md#1-record
[J 02.05.03]: ../../comtran-manuals/J28-6169/02-compiler.md#3-redef-see-iii-under-data-description-on-page-900103-for-limitation
[J 02.05.04]: ../../comtran-manuals/J28-6169/02-compiler.md#6-param-and-funct
[J 02.05.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.06]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.06]: ../../comtran-manuals/J28-6169/02-compiler.md#0206-environment-description
[J 02.06.02]: ../../comtran-manuals/J28-6169/02-compiler.md#b-environment-types
[J 02.06.03]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.04]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.05]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.07]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.08]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.09]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.10]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.11]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.12]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.13]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.14]: ../../comtran-manuals/J28-6169/02-compiler.md#f-group-environment-card
[J 02.06.16]: ../../comtran-manuals/J28-6169/02-compiler.md#g-contrl-environment-card
[J 02.06.17]: ../../comtran-manuals/J28-6169/02-compiler.md#h-option-environment-cards
[J 02.07.01]: ../../comtran-manuals/J28-6169/02-compiler.md#i-cond-environment-card
[J 02.07.04]: ../../comtran-manuals/J28-6169/02-compiler.md#6-record-types
[J 02.07.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-factors-affecting-choice-and-use-of-locate-or-transmit-mode
[J 02.07.06]: ../../comtran-manuals/J28-6169/02-compiler.md#2-end-of-file-processing
[J 02.07.07]: ../../comtran-manuals/J28-6169/02-compiler.md#3-input-error-processing
[J 02.07.08]: ../../comtran-manuals/J28-6169/02-compiler.md#1-forms-of-the-command
[J 02.07.09]: ../../comtran-manuals/J28-6169/02-compiler.md#1-non-standard-variable-length-input-records
[J 02.07.11]: ../../comtran-manuals/J28-6169/02-compiler.md#c-problem-explanation
[J 02.08.01]: ../../comtran-manuals/J28-6169/02-compiler.md#c-explanation-of-problem-1
[J 02.08.02]: ../../comtran-manuals/J28-6169/02-compiler.md#b-crypt-rules
[J 02.08.03]: ../../comtran-manuals/J28-6169/02-compiler.md#c-flexibility-above-that-of-scat
[J 03.02.05]: ../../comtran-manuals/J28-6169/03-loader.md#d-spec-card
[J 03.02.08]: ../../comtran-manuals/J28-6169/03-loader.md#h-retains-card
[J 03.02.09]: ../../comtran-manuals/J28-6169/03-loader.md#j-start-card
[J 04.01.01]: ../../comtran-manuals/J28-6169/04-monitor-and-supervisor.md#introduction
[J 04.02.01]: ../../comtran-manuals/J28-6169/04-monitor-and-supervisor.md#-card
[J 04.02.02]: ../../comtran-manuals/J28-6169/04-monitor-and-supervisor.md#0402-function-of-the-commercial-translator-supervisor---ctm
[J 05.03.01]: ../../comtran-manuals/J28-6169/05-systems-operation.md#0502-peripheral-equipment-assignment
[J 05.03.02]: ../../comtran-manuals/J28-6169/05-systems-operation.md#a-preparing-the-system-input----sysin1-and-sysin2
[J 05.06.04]: ../../comtran-manuals/J28-6169/05-systems-operation.md#b-loader-1
[J 90.01]: ../../comtran-manuals/J28-6169/06-systems-maintenance.md#appendix-9001
[J 90.01.01]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#appendix-9001-deferred-features-restrictions-and-limitations
[J 90.01.02]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.03]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.04]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.05]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.00]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002-generated-code
[J 90.02.01]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#introduction
[J 90.02.03]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.04]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.06]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.07]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.08]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ct-system-subroutines-and-communication-cells
[J 90.02.10]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.12]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.15]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.16]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.17]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.18]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.25]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.28]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.03]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#appendix-9003
[J 90.03.01]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#introduction
[J 90.03.03]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#3-file-check-entry-specifications
[J 90.03.04]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#1-format
[J 90.04]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.04.01]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#error-messages-and-severity-codes
[J 90.04.02]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#a-error-messages
[J 90.05]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
[J 90.05.02]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description
[J 90.05.03]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description-1
[J 90.05.04]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#a-data-description
[J 90.08.01]: ../../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008
[J 90.08.02]: ../../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#a-the-file-card
