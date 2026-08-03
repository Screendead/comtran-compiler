# M2 — Parser design and decisions

*Updated 2026-08-03. This document records the M2-specific design decisions the
way `m1-front-end.md` records M1's. The language facts come from
`docs/comtran-language-definition.md` (cited by §), the manuals (cited as
`(F p. N)` / `(J xx.xx.xx)`), and the locked decision slate
(`docs/design/decisions.md`, cited as D-numbers). This document adds no
language claims; where the sources leave a surface-syntax gap, the entry below
closes it and says so.*

*Entry IDs are append-only. A new entry takes the next free number and goes in
the section it belongs to, so the entries do not read in numeric order. The code
cites these IDs, so no entry is ever renumbered. Use the index below to find one.*

| Entry | Section |
|---|---|
| M2-1, M2-2 | Pipeline position |
| M2-3 | Scope: what M2 checks, what it hands on |
| M2-4, M2-5 | The AST |
| M2-6 | Statement and clause numbering |
| M2-7 | Word classification |
| M2-8 to M2-12, M2-16, M2-17 | Procedure grammar decisions |
| M2-13 | Error recovery |
| M2-14 | Diagnostics |
| M2-15 | The job stream |

## Charter

M2 parses the scanned output of the M1 front end into an abstract syntax tree
for all three divisions plus the control cards, with diagnostics drawn from
the [J 90.04] message catalog and statement numbers of the full `n,cc` form
(HANDOVER roadmap; [J 02.02.01]). M1 guarantees its side of the boundary: the
parser always receives terminated sentences (D9.4), assembled data entries and
environment specifications (column-72 rule), and unclassified `word` tokens —
"classification is the parser's job" (`lib/src/lexer/token.dart`).

## Pipeline position

- **M2-1. A separate phase over `FrontEndResult`.** The parser is
  `runParser(FrontEndResult) → ParseResult` in `lib/src/parser/`. It never
  re-reads cards; every input comes from the M1 scan structures
  (`ProcedureSentence`, `DataEntry`, `EnvironmentSpec`, `SourceProgram`).
  `ParseResult` carries the front-end result, the AST, the parser's own
  diagnostics, and the clause-number table. `bin/comtranc.dart` becomes
  deck → `runFrontEnd` → `runParser` → `writeListing`, and the exit code
  gates on the combined maximum severity.
- **M2-2. One merged diagnostic block.** The listing prints front-end and
  parser diagnostics as one block, ordered by card number (stable within one
  card). The 1962 ordering is unattested — the only surviving listing is
  clean — so the ordering is a recorded presentation decision,
  non-historical. The golden 90.05 listing is unchanged: the sample parses
  with zero diagnostics, which is itself the M2 acceptance test.

## Scope: what M2 checks, what it hands on

- **M2-3. Division of labor per division.** D9.3's component taxonomy names
  the "procedure parser", "data description", and "environment description"
  as separate components. M2 builds all three as separate parser units over
  one shared AST, because all three are pure syntax; M3 starts where a check
  needs the data-description hierarchy's *meaning* (types, lengths, storage).
  Concretely:
  - **Procedure:** full grammar — sentences, clauses, verbs, arithmetic and
    conditional expressions, sections, labels. Everything in the definition
    §4/§5/§6 marked parser-enforceable (token shape, adjacency, arity,
    clause order) is M2. Format-legality tables, CORRESPONDING matching,
    name resolution, and argument-count checks are M3 ([J 02.04.03]–06).
  - **Data:** entry structure. One check per line:
    - Level hierarchy, by the nearest-lower-preceding rule ([F p. 68]).
    - Type-code recognition: one of the eight J codes, or blank
      ([J 02.05.02]–03).
    - RECORD forbids a Quantity field ([J 02.05.01]).
    - A REDEF line carries only the target name ([J 02.05.02]).
    - RCDMRK needs no pictorial, but accepts an explicit one. The sample's
      own RCDMRK punches `A` (statement 42,00; [J 02.05.03]).
    - A COND entry carries exactly one quoted constant ([F pp. 71–72]).
    - The description field keeps its ordered shape ([F p. 79]):
      `[pictorial] [constant] [name] [QUANTITY IN name] [BLANK WHEN ZERO]`,
      split by the non-format-character rule ([J 02.05.06]).

    The pictorial's *content* — character classes, the six-way field-type
    chart, sizing — is M3 (HANDOVER M3; `data_lexer.dart`'s own deferral
    comment).
  - **Environment:** the per-type option grammars for all seven card types
    ([J 02.06.02]–17), including the FILE card's record-scope rule
    (options attach to the preceding record.name, [J 02.06.04]) and the
    SPECIF unit-literal forms ([J 02.06.09]–11). Cross-card checks (SPECIF
    names its FILE card, POOL buffer counts) are M3 name resolution.
    CONTRL is the precedent that pure syntax checking with no downstream
    effect is historically right (msg 176 with no object-deck effect,
    [J 90.01.04]).
  - **Control cards:** the $CMPLE field grammar with the blank-terminated
    option list ([J 02.01.01]), *COMPILE as a synonym (D7.12), deck.name
    blanks accepted silently (D7.11), and *FINISH placement ([J 02.01.02]).

## The AST

- **M2-4. Sealed Dart classes in `lib/src/ast/`.** One node family per
  division plus expressions, every node carrying provenance (the tokens or
  cards it came from) so diagnostics and later phases can point back to
  columns. Procedure: `Sentence` (label, clause list, sentence number),
  clause nodes per verb (`MoveClause`, `SetClause`, `AddClause`,
  `GoToClause`, `DoClause`, `StopClause`, `OpenClause`, `GetClause`,
  `FileClause`, `CloseClause`, `DisplayClause`, `CallClause`, `EnterClause`,
  `NoteClause`, `BeginSectionClause`, `EndClause`), and `IfClause`
  (condition, THEN arm, OTHERWISE arm — arms are clause lists).
  Expressions: arithmetic (`BinaryOp`, `UnaryOp`, `NameReference` with
  qualifier words and subscripts, `LiteralOperand`, `FunctionCall`,
  `TruthFunction`) and conditional (`Relation`, `ConditionReference`,
  `AndExpr`, `OrExpr`, `NotExpr`). Data: `DataItem` (fixed fields, parsed
  description clauses, children) in a per-group tree. Environment: one node
  per card type. Control: `CompileCard`, `FinishCard`.
- **M2-5. Recovery nodes are marked, not dropped.** Following D4.10's
  precedent (`A**B**C` grouped left-to-right "for error recovery only"),
  a node built during repair carries a `recovered` flag; later phases run
  their checks over it but generate no code from it. A sentence deleted
  whole (msgs 122, 125, 126, 171, 177) is kept as a `DeletedSentence` node
  so numbering and the listing stay aligned.

## Statement and clause numbering

- **M2-6. What `cc` counts.** J attests only the form: the digits after the
  comma "tell which clause is being referenced" ([J 02.02.01]). No non-zero
  value survives in any listing (D7.13). Recorded decision, non-historical:
  - Number the clauses of a procedure sentence in source order from 01. The
    conditional clause (IF…THEN) takes 01 when present. Each imperative
    clause takes the next number.
  - `n,00` refers to the unit as a whole.
  - Data entries and environment specifications have no clause structure.
    They always reference `,00`.
  - A parser diagnostic cites `n,cc` when the error stays inside one
    clause, and `n,00` otherwise. `9999,99` keeps its M1 role: a diagnostic
    on an unnumbered card.
  - The two-digit field cannot overflow. The 60-operator sentence cap
    (msg 171) bounds a real sentence far below 99 clauses.
  - The count behind that cap covers the arithmetic symbols, `=` (either
    relational or assignment — the two are indistinguishable before
    parsing), and the relational and logical operator words. Parentheses
    and commas are not operators and do not count. The exact 1962 counting
    is unattested.

## Word classification

- **M2-7. Contextual keyword recognition.** A `word` token is a key word
  only where the grammar expects one; recognition uses
  `keyWordClassOf` (`reserved_words.dart`) plus parse position. The
  reservation bars follow J's three tiers ([J 02.03.02]–03): list 1 rejected
  as a name in every division; list 2 rejected as a Data or Procedure name
  (EQUALS misuse per D1.5: msg 178 in Data/Environment, msg 192 in
  Procedure); list 3 deferred to M3, because its bar depends on whether the
  Environment Division references the word. No name may contain a right
  parenthesis (D9.13) — M1's tokenizer already cannot produce one.
  PROGRAM.START is an attachable reserved label (D2.1, msgs 141–143; the
  DO-addressed check runs as a post-pass over the parsed DO targets).

## Procedure grammar decisions

The grammar itself is the definition's: sentence structure §2.3/§5.1–5.2,
expressions §4.1 with [J 02.04.05.01] precedence (negation above `**`, D4.4;
`A**B**C` rejected, D4.10), conditions §5.3 (AND above OR, [F p. 105]; the
[F p. 106] adjacency tables), verbs §4/§5/§6 with the D-slate calls (D2.7 STOP,
D5.2 DO indices, D5.6 SET condition-name, D6.6 AT END, D8.5 FILE-card comma).
The entries below close the surface-syntax gaps the sources leave open:

- **M2-8. Figurative constants are verb-level alternatives, not expression
  operands.** F's operand inventories for arithmetic expressions never list
  figurative constants (F pp. 45, 105–106); J grants them as the source of
  SET or MOVE ([J 02.04.01]). Recorded decision: the SET right-hand side is
  `arithmetic-expression | figurative-constant`, and MOVE's source likewise;
  a figurative constant inside a larger expression is a syntax error.
  Comparison operands keep them ([J 02.04.01] defines their comparison
  behavior). *Corrected against the sample (2026-08-03):* MOVE's source
  also accepts a literal — [F p. 42]'s general form shows `data.name.1`
  only, but the compiled sample writes `MOVE 'M' TO ERRORTYPE` and
  `MOVE 'GT' TO PAYRECORD DEPARTMENT` (statements 193, 196, 199) and
  compiled clean, so the literal alternative is attested language.
- **M2-9. ADD CORRESPONDING accepts TRUNCATED and ON OVERFLOW.** F's body
  text grants both clauses to ADD without qualification ([F p. 47]); the
  Appendix-2 concise form omits them while folding `[CORRESPONDING]` into
  one production ([F p. 108]). The omission is read as abridgment, not
  prohibition: the clauses parse on both ADD forms. MOVE has neither clause
  — their presence on MOVE is a syntax error ([F pp. 42–43]; §8.5.4).
- **M2-10. DISPLAY commas follow J.** F reads an unquoted comma as the
  operand-list terminator ([F p. 54]); J's field-test restriction reads it as
  the required separator between data-names, juxtaposed words forming one
  qualified reference ([J 90.01.01]). J governs: the operand list is
  literals and name references in any order, comma-separated between name
  references; `DISPLAY A B` parses as one qualified name. Msg 131 covers
  the malformed remainder. No sample uses DISPLAY, so the listing oracle
  cannot arbitrate — this entry is the recorded resolution of the §8.3
  divergence.
- **M2-11. Deferred verbs parse and diagnose.** COPY/LIBRARY/INCLUDE are
  recognized and refused with the attested msg 110 (D9.8 — the locked
  call, which supersedes D7.4's earlier plan of a separate non-historical
  INCLUDE message). LOAD and OVERLAP parse per F's forms ([F pp. 54–56])
  and draw a non-historical recognized-but-deferred diagnostic
  ([J 90.01.03] defers them; no J message id exists), following the
  PATTERN pattern (D9.12). ENTER accepts exactly its two J forms
  ([J 02.04.02.01]).
- **M2-12. Program and processor verbs do not mix in one sentence.**
  [F p. 60] states it; the parser deletes a mixed sentence with msg 196 —
  no 1962 message is attested for the rule, and 196's "ILLEGAL SENTENCE
  STRUCTURE NOTHING DONE." matches F's "meaningless" verdict. The check
  walks nested clauses (IF arms, ON OVERFLOW, AT END), so a processor
  verb inside an arm — [F p. 60]'s own illegal example — is caught. Verb
  classes follow [F p. 35] (definition §2.7): LOAD is a program verb;
  OVERLAP, INCLUDE, COPY, LIBRARY, CALL, ENTER, NOTE, BEGIN SECTION,
  and END are processor verbs. END is exempt from the mixing deletion:
  its own attested rule, msg 179, governs an END that is not the
  sentence's only clause — nested in an IF arm or not — and that END
  still pops its section. *Corrected (2026-08-03, review):* the entry's
  earlier claim that BEGIN SECTION also "stands alone" has no source —
  [F p. 60]'s exception for BEGIN SECTION and END concerns naming, not
  clause count — so BEGIN SECTION may share a sentence with other
  processor commands; mixing with program verbs is what deletes it.
- **M2-16. DO parameters parse without subscripts.** [F p. 51]: p, q, and
  r are each an integer literal or the name of an integer field. When p
  is a name, `p(q)r` is lexically identical to a subscripted name, and
  no manual resolves the ambiguity. Recorded decision: in a DO control
  position the parenthesis is always the `(q)` group — the parameter
  name parses without subscripts, so every name-valued p works and a
  subscripted parameter cannot be written. EXACTLY's n follows the same
  rule.
- **M2-17. Relation spellings are the closed [F p. 21] set.** Six
  relations, each with one full form (`IS [NOT] GREATER THAN / LESS
  THAN / EQUAL TO`) and one abbreviation (`[NOT] GT / LT / =`). A
  hybrid — an abbreviation after IS, a full-form word without IS, or a
  missing THAN/TO — draws msg 107, and the relation is kept as a
  repair. The sample program uses only attested spellings ([J 90.05]).

## Error recovery

- **M2-13. The recovery unit is the sentence.** Every attested deletion
  message discards a whole sentence and resumes at the next one (msgs 122,
  125, 126, 171, 177). That is the recovery model:
  - On an unrepairable parse error, the sentence becomes a
    `DeletedSentence` carrying the fitting message. Parsing resumes at the
    next sentence.
  - The C1 auto-repairs keep the construct and continue: redundant
    parentheses 113 and 114, missing operand 116.
  - The fixed-form divisions recover the same way, per entry or per
    specification.
  - A deletion also rolls back everything the sentence would have
    contributed. STOP RUN, the DO targets, and the CRYPT-mode switch commit
    only after the sentence parses. So a deleted STOP RUN leaves msg 175 to
    fire, and a deleted ENTER CRYPT leaves the parser in normal mode.
    *(Amended 2026-08-03, review.)*
  - A subscripted condition-name (D5.6) deletes the sentence too. Msg 910
    at severity 3 announces the deletion in its own text. This replaces the
    earlier ignore-and-compile reading, which invented the semantics D5.6
    forbids. *(Amended 2026-08-03, review.)*
  - The severity-5 conditions (msgs 149, 915) throw `StopCompilation`, and
    `runParser` catches it. Parsing stops at the point of detection (D9.1),
    and each such message prints at most once.

## Diagnostics

- **M2-14. Growing the message set.** Parser messages are added to
  `messages.dart` as named constants drawing their text from
  `message_catalog.dart`, each with its `severities.dart` row already in
  place (all 227 rows exist — 210 catalog ids plus 900,00 through 916,00;
  the parser never inlines a severity, D9.2).
  The parse-phase inventory starts from the survey of decisions.md:
  sentence structure 122/125/126/192/196/208, sections 64/65/66/179/149,
  expressions 113/114/171/187, CORRESPONDING 63, DO 83, AT END 106,
  DISPLAY 131, OPEN/CLOSE 138/139, PROGRAM.START 141/142/143, environment
  types 90/176 and the per-card format messages (FILE 91–95, POOL 162,
  CONTRL 207, COND 4/6/7), RUN misuse 2. Non-historical conditions take
  ids from 905,00 up, text tagged `(NON-HISTORICAL.)` (D9.7 pattern).

## The job stream

- **M2-15. The driver owns the job loop (D9.14).** A deck may hold several
  jobs, each `$CMPLE … *FINISH`. `bin/comtranc.dart` gains the loop: split
  the deck at *FINISH cards, run front end + parser per job, print one
  listing per job, exit on the worst severity. Msg 132 and the $CMPLE
  option scan land here. M1's msg 903 (card after *FINISH) becomes the
  single-job tail case only.

## Staging

Three pull requests, each green on its own:

1. **AST + fixed-form parsers** — `lib/src/ast/`, the data, environment,
   and control-card parsers, `runParser` with the listing merge, tests
   (90.05 clean; per-card error cases against the 90.04 messages).
2. **Procedure parser** — expressions, conditions, verbs, sections,
   clause numbering, recovery; the 90.05 procedure division parses clean
   and the golden listing is byte-identical.
3. **Job stream** — the driver loop, $CMPLE option scan, msg 132.

## Oracles

- The 90.05 deck: 172 + 14 + 43 statements parse with zero diagnostics;
  the golden listing is unchanged byte for byte.
- Error paths: constructed decks per message, asserting message id,
  severity, statement number (including non-zero `cc`), and recovery
  behavior (deleted vs repaired).
- Decision conformance: each M2-N and each D-slate call named above gets a
  test that cites it.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 21]: ../../comtran-manuals/F28-8043/02-language-structure.md#arithmetic-expressions
[F p. 35]: ../../comtran-manuals/F28-8043/03-procedure-description.md#chapter-3-procedure-description
[F p. 42]: ../../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F pp. 42–43]: ../../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F p. 47]: ../../comtran-manuals/F28-8043/03-procedure-description.md#set-used-with-condition-names
[F p. 51]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-indexing
[F p. 54]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-named-end
[F pp. 54–56]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-named-end
[F p. 60]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-enter-command
[F p. 68]: ../../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F pp. 71–72]: ../../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F p. 79]: ../../comtran-manuals/F28-8043/04-data-description.md#justify-col-37
[F p. 105]: ../../comtran-manuals/F28-8043/a2-supplementary-information.md#appendix-2-supplementary-information
[F p. 106]: ../../comtran-manuals/F28-8043/a2-supplementary-information.md#rules-for-forming-conditional-expressions
[F p. 108]: ../../comtran-manuals/F28-8043/a2-supplementary-information.md#rules-for-forming-arithmetic-expressions
[J 02.01.01]: ../../comtran-manuals/J28-6169/02-compiler.md#0200-introduction
[J 02.01.02]: ../../comtran-manuals/J28-6169/02-compiler.md#a-cmple-card
[J 02.02.01]: ../../comtran-manuals/J28-6169/02-compiler.md#b-finish-card
[J 02.03.02]: ../../comtran-manuals/J28-6169/02-compiler.md#a-use-of-coding-forms
[J 02.04.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-effect-of-data-storage-mode-on-arithmetic-efficiency
[J 02.04.02.01]: ../../comtran-manuals/J28-6169/02-compiler.md#2-literals
[J 02.04.03]: ../../comtran-manuals/J28-6169/02-compiler.md#2-display
[J 02.04.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.02]: ../../comtran-manuals/J28-6169/02-compiler.md#1-record
[J 02.05.03]: ../../comtran-manuals/J28-6169/02-compiler.md#3-redef-see-iii-under-data-description-on-page-900103-for-limitation
[J 02.05.06]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.06.02]: ../../comtran-manuals/J28-6169/02-compiler.md#b-environment-types
[J 02.06.04]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.09]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 90.01.01]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#appendix-9001-deferred-features-restrictions-and-limitations
[J 90.01.03]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.04]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.04]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.05]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
