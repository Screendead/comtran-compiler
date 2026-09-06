# Rules binding M4 stage 4 — the dispatch layer, the compute handlers, and their tests

Method note: every quote below is verbatim from the file and line cited. Where I state a count or a set membership that no file states in words, I say how I measured it.

---

## 1. D0.3 VERBATIM

`docs/design/decisions.md:184-204`, the whole record including its one amendment:

> **D0.3 Backend: real 709/7090 object code, run on our own emulator.**
>
> - The compiler emits 7090 object programs in the documented object deck format
>   ([J 90.03]), loaded by our implementation of the CT Loader (J 03, [J 90.03]).
> - A word-exact 36-bit 7090 CPU core executes the generated code. Instruction
>   semantics come from the period reference manual (external: 22-6528-4).
> - The SYS)/IOC) runtime library is **high-level-emulated**: the original
>   machine code is lost, so Dart handlers sit at the documented entry points,
>   each implementing its [J 90.02] interface contract — calling sequence, results,
>   and documented register/memory side effects — and each unit-tested against
>   that contract. Any routine is individually replaceable by real 7090 code if
>   authentic code ever surfaces; the contracts and tests then validate the find.
>   *Amended 2026-09-06 (Jack's call). The "machine code is lost" premise is
>   false for the July 1963 version, which survives. D0.9 records the find. This
>   decision is unchanged: the reconstruction continues from the manuals, and the
>   surviving code is sealed until M7 opens.*
> - Codegen conformance oracle: our compilation of `test/fixtures/90.05-payroll.ct`
>   is diffed against the 1962 compilation listing ([J 90.05], PDF pp. 198–216).
> - Rejected: LLVM and emit-C backends (nothing 1962-observable in their output);
>   interpreter-first (superseded by this route).

Also in the D0 heading block, `docs/design/decisions.md:171-173`: "Every item in this section is locked. … D0.9 was added on 2026-09-06 and is locked from that date".

### What "the per-handler D0.3 contract tests" must look like

No single text defines the phrase. Three texts jointly fix it, and a fourth defines the oracle vocabulary they use.

1. **D0.3 fixes the asserted content and the source.** `docs/design/decisions.md:190-194`: "Dart handlers sit at the documented entry points, each implementing its [J 90.02] interface contract — **calling sequence, results, and documented register/memory side effects** — and **each unit-tested against that contract**." The source is `comtran-manuals/J28-6169/90.02-generated-code.md`, the per-entry appendix.
2. **M4-17 repeats it for the stage-4 set.** `docs/design/m4-codegen.md:909-910`: "Each handler implements its [J 90.02] contract and is unit-tested against it (D0.3)."
3. **The Oracles section names two kinds of stage-4 test, not one.** `docs/design/m4-codegen.md:1055-1056`: "Stage 4: per-handler D0.3 contract tests; end-to-end runs of constructed I/O-free decks with storage assertions." And `1059-1060`: "Decision conformance: each M4-N and D-slate call above gets a test that cites it."
4. **The reading key defines what "decision-conformance only" means as a test source.** `docs/design/decisions.md:371-375`: "**Oracle** names the evidence that tests it ('listing-diff' = the 1962 compilation listing, 'report' = the printed payroll register, **'decision-conformance only' = no surviving oracle — the decision itself is the spec**)."

So, stated only from those four texts, a stage-4 handler carries tests of three provenances:

| Test | Asserts | Against |
|---|---|---|
| Contract test (per handler) | The calling sequence it consumes, the results it produces, and its documented register and memory side effects | That handler's entry in [J 90.02] |
| Decision-conformance test (per D-slate / M4-N call the handler implements) | The behavior the record decided where the manual is silent, with the record cited in the test | The decision record itself — "the decision itself is the spec" (`decisions.md:373-374`) |
| End-to-end run | Storage after a run of a constructed I/O-free deck | The deck's expected storage image |

HANDOVER states the same pair as stage 4's oracles, `docs/HANDOVER.md:90-92`: "Its oracles are the per-handler D0.3 contract tests and end-to-end runs of constructed decks with storage assertions."

The dispatch-layer mechanics a contract test must exercise are M4-17's, `docs/design/m4-codegen.md:896-900`: "a TSX-linked handler reads its calling sequence through XR4, honors the resume convention (parameter-word count plus one), and returns control — SYS)294 alone breaks the pattern: the guard's conditional `TXL` reaches it with no calling sequence, and it exits to the monitor instead of returning."

**No text fixes** the test file location, the naming convention, the fixture format, or whether a contract test drives the handler directly or through the dispatcher. See section 7.

---

## 2. D0.7 and D0.9

### D0.7 — the I/O model and the M4/M5 boundary

`docs/design/decisions.md:253-258`, whole record:

> **D0.7 Files, tape, labels, PATTERN.** I/O is emulated at the IOCS level
> (external: C28-6100-2). Tape files are binary tape-image files (canonical);
> the card reader, card punch, and printer surface as deck and print files at
> the emulator boundary. Labels and PATTERN are modeled inside the emulated
> IOCS per the definition's Q41/Q45/Q46 annotations and §8.5.6. Detailed
> decisions land in D6 (I/O) and at M5.

The boundary itself is set in M4-17, not in D0.7. `docs/design/m4-codegen.md:901-909`:

> M4 lands the compute set — the cells and flags SYS)128–134, the
> scaling, exponent, and comparison routines SYS)155–173 (SYS)161 among
> them is the 709-to-705 collating table the compare path reads — data,
> not code), MOVPAK entire (SYS)179–258, 267–282), the base-locator
> guard SYS)294 — plus the run-frame stubs SYS)174–178 (open and close,
> one file and all, and the display routine) and IOC)1, IOC)40, enough
> to run an I/O-free program to its STOP. M5 lands
> IOCS: IOC)2–17, 29, 46, 53, 54 and SYS)260–266, 283, and 286–296
> less the already-landed 294.

Corroborated at `docs/design/m4-codegen.md:24-25`: "The 90.05 sample first runs at M6, after M5 lands the IOCS handlers; **M4 executes I/O-free programs**." And `m4-codegen.md:33-35`: "the I/O verbs (OPEN, CLOSE, GET, FILE) get their attested calling-sequence shapes only (M4-15), and their runtime lands at M5."

D0.7's IOCS is inside the seal — `docs/design/decisions.md:305-307`: "The seal covers the whole recovered archive. … IOCS is inside the seal, and **D0.7 does not exempt it**."

Emulator scope defers to D0.7 the same way, `docs/design/emulator.md:220-223`: "**Data channels, tapes, card units, printer, all I/O instructions** … D0.7 emulates I/O at the IOCS level; generated CPU code reaches I/O only through SYS)/IOC) entry points, and none of these opcodes appears in the harvest."

### D0.9 — what a handler record may and may not cite

The seal has **two homes with differently numbered rule lists**. The task's "rule 3" and "rule 5" are CLAUDE.md's five-rule list; `decisions.md` has four rules and numbers them differently. Both bind.

**CLAUDE.md §9, `CLAUDE.md:220-242`:**

> The 1963 Commercial Translator survives, compiler and runtime library both, in
> a recovered IBSYS archive. **Do not read it, and do not search it, for any
> answer to any question in this repository.** The seal ends when M7 opens.
>
> Five rules follow:
>
> 1. The seal covers the whole archive. Source, listings, object files, and every
>    sibling subsystem directory are inside it. IOCS is inside it too.
> 2. Before M7, cite nothing from the archive. This binds design records, Open
>    Questions, emulator rules, and **runtime handler contracts**.
> 3. To name the seal is not to read it. Write "evidence exists and is sealed
>    until M7" where a record would otherwise say that no evidence survives.
> 4. Downloading and checksumming for M7 tooling is permitted. Reading content is
>    not.
> 5. If a task appears to need the archive, it does not. Use the manuals, and
>    record the gap as an Open Question.

Rule 2 names runtime handler contracts explicitly — it is the sentence that binds stage 4 most directly.

**decisions.md D0.9, `docs/design/decisions.md:303-313`** — same content, four rules, "to name the seal" is rule **4**, not 3:

> **Scope of the seal.** Four rules:
>
> 1. The seal covers the whole recovered archive. It covers source, assembly
>    listings, object files, and every sibling subsystem directory. IOCS is
>    inside the seal, and D0.7 does not exempt it.
> 2. Read nothing in the archive for any answer to any question in this
>    repository. This holds until M7 opens.
> 3. Download and checksum work for M7 tooling is permitted. Reading content is
>    not.
> 4. To name the seal is not to read it. A record may say that evidence exists
>    and is sealed until M7. That sentence is required where a record would
>    otherwise assert that no evidence survives.

Note "That sentence is **required**" — a stage-4 handler record that would say "no evidence survives" must instead say the evidence is sealed until M7. Two D4 records already use the required form and are the template: `decisions.md:646` (D4.1(e)) "design decision under D0.4, **no unsealed evidence survives (MOVPAK survives in the sealed 1963 archive; D0.9, and read it at M7, not before)**"; `decisions.md:674` (D4.3) "fixed by design decision (**no unsealed evidence survives; the 1963 movers are in the sealed archive, D0.9**)".

**The contamination boundary is stage 4's problem specifically.** `docs/design/decisions.md:323-347` lists what the 2026-09-06 survey saw before the seal existed. Four of the entries name stage-4 handlers:

> - the names of the 40 object-time subroutine decks;
> - 28 lines of MOVPAK, which include a prologue, a loop entry, and a
>   conditional error transfer;
> - one assembled line of MOVPAK from the listing;
> - the cross-reference lines that give names to `SYS)130`, `SYS)131`, `SYS)177`,
>   `SYS)178`, `SYS)180` and `SYS)294`;
> - occurrence counts for twelve `SYS)` cells;

And `decisions.md:341-346`: "The seal is intact for the compiler and for 39 of the 40 runtime decks. Two things are not intact. **MOVPAK is partly contaminated**: 28 lines of its logic were read. Open Question 31 has had a hint, because the occurrence count for `SYS)131` bears on whether anything reads that cell. Treat both as contaminated at M7, and say so in the diff pass. Do not present either as a blind result."

`decisions.md:348-349`: "**If the seal breaks again**, add to the list above and say why. Do not remove an entry."

`decisions.md:354-357`: "**The review record is inside the boundary, not outside it.** … it is the evidence for this decision and it is not a breach." CLAUDE.md:214-215 adds: "**A quotation from the archive anywhere else is a broken seal: stop and tell Jack.**"

---

## 3. SEMANTIC RULES — what a runtime routine does at object time

### D4.1 — Rounding (`docs/design/decisions.md:631-656`)

Status, `decisions.md:633`: "Jack's call. Parts (a) to (c), (e) and (f) were recorded 2026-08-02 and bind. Part (d) was deferred 2026-08-02; Jack locked it 2026-08-04. **Every part now binds.**"

The resolution blockquote, `decisions.md:634`, in the part that fixes the emission rule: "(i) A SET store through a step-list package rounds; a MOVE store truncates. … **Jack chose reading (i). Reading (ii) stays on record in (d) as the amendment.**"

Decision, `decisions.md:636`: "Default SET rounding is a half-adjust away from zero, applied at the store only."

Handler-relevant parts:

- **(c), the SYS)267 pre-edit split — `decisions.md:642`:** "The divide splits the value for SYS)267: the digits that fit remain as the remainder in the AC, the excess becomes the quotient in the MQ, matching the MQ-high/AC-low layout SYS)166 documents. … **our runtime performs the split as described and takes no action on the excess quotient.**"
- **(d), which round steps exist and when codegen calls them — `decisions.md:644`:** "J supplies five round step-subroutines and no algorithm: SYS)219 (with SYS)183), SYS)220 (with SYS)185), SYS)221 (with SYS)189), SYS)222 (with SYS)190), SYS)274 (with SYS)268). Our rule: codegen emits the serving package's round step when a SET store routed through one of those five step-list packages must discard low-order digits and TRUNCATED is not written; a MOVE store emits no round step and no `ACL`, so a MOVE truncates. … we emit the round step at the position of the rounding character." Amendment on record in the same paragraph: "the round step is emitted whenever any step-list package must discard low-order digits, MOVE included."
- **(e), the round-step handler internals — `decisions.md:646`, verbatim, this is the handler algorithm:** "MOVPAK round-step handler internals — design decision under D0.4, no unsealed evidence survives (MOVPAK survives in the sealed 1963 archive; D0.9, and read it at M7, not before). The rule at the rounding character position. If the digit being discarded is 5 or greater, add 1 into the retained low-order digit of the target magnitude, and propagate the decimal carry leftward through the target digit positions. The sign is neither read nor changed, so the adjustment is away from zero. A carry out of the high-order digit position is dropped. The appendix gives the step no repetition count and does not state whether its effect is confined to one position, and [J 90.02.18] prints 'Round current characters' (plural) for SYS)221 — the one place the manual hints at a wider scope. **The single-position choice is amendable on that hint.**"
- **(f), round-step overflow — `decisions.md:648`:** "For a MOVPAK round step, a rounding carry out of the high-order digit position **does not set SYS)130 in our runtime** — design decision under D0.4, because SYS)130's wording is scoped by subroutine rather than by cause, so the case is 'neither asserted nor excluded'."

Implementation, `decisions.md:652`: "Lands in codegen (…), the emulator (bit-exact ACL, XCA, LRS, DVP, STQ), and **the SYS/IOC runtime (the five MOVPAK round handlers)**."

Oracle, `decisions.md:654`: "…**Decision-conformance only** for negative values, for TRUNCATED codegen, for the round-step emission rule, and for the MOVPAK round-step internals."

### D4.2 — Overflow with no ON OVERFLOW clause (`decisions.md:658-669`)

Status `660`: "Locked." Decision, `decisions.md:661`, the handler-binding sentences verbatim:

> With no ON OVERFLOW clause the truncated result is stored and execution continues; no transfer and no object-time message occurs. This part is attested. … SYS)186–188 (external decimal), SYS)267 (edited) and SYS)246 (internal decimal not justified) each carry no test step. No entry in [J 90.02.00]–90.02.33 reads, tests or clears SYS)130. The fixed-point scaling and arithmetic handlers SYS)163–171 lie outside MOVPAK altogether and set no cell; this too is attested, not chosen. **Arming rule for SYS)130 — design decision under D0.4, amendable. Our MOVPAK handlers for the five character-source families SYS)183, 185, 189, 190 and 268 carry the counted overflow-test step (SYS)195, 196, 199, 201, 203, 204, 270, 277, 281). Each of those handlers sets SYS)130 non-zero when its step finds a non-zero significant character in the positions tested. The handlers with no step list — SYS)184, 186, 187, 188, 246, 247, 267 — do not set the cell.** … Nothing reads, tests or clears SYS)130; **our runtime never clears it, so it is a sticky, statement-wide flag readable only through the emulator** (design decision — no clearing is documented anywhere). MOVE high-order dropping stays silent and defined.

Implementation, `decisions.md:665`: "Lands in the SYS/IOC runtime (MOVPAK handler contracts and the SYS)130 cell), codegen (…), and the emulator (communication-cell storage). **The narrow-versus-wide arming choice changes no emitted object code — only handler behavior — so listing-diff cannot decide it and an amendment is confined to the runtime.** Note the printed inconsistency preserved in J: SYS)231–234 occupy the test slot in the family lists but their own entries print NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH; **our handlers follow the individual entries (overpunch)** and the calling-sequence position is recorded as a printed defect. No diagnostic. … --pedantic delta: none at object time; **--pedantic may not add object-time checks, since that would change emitted code.**"

M4-17 repeats the overpunch rule as a general handler doctrine, `docs/design/m4-codegen.md:910-913`: "Handlers keep the printed inconsistencies as recorded defects, not silent fixes: SYS)231–234 follow their own entries (overpunch test), not the family lists' overflow naming (D4.2's note)."

### D4.3 — Invalid characters in a numeric field at object time (`decisions.md:671-682`)

Status `673`: "Locked." Decision, `decisions.md:674`, verbatim in the handler-binding part:

> There is no program-level reaction and no object-time message. **Arming set: the numeric MOVPAK members — SYS)183–238, SYS)246–258 and SYS)267–282 — set communication cell SYS)131 non-zero when they meet an improper data condition, and then continue; the alphabetic and figurative-constant movers SYS)239–245 do not set it.** What counts as "an improper data condition" is unresolved, so the trigger is a design decision under D0.4 and is amendable: for external-decimal and edited sources, a character that is not a valid digit — or, in a sign position, not a valid overpunch sign — arms the cell. **Scientific-decimal sources are exempt from that test.** … Our scientific-decimal converts therefore parse by that free-form rule. **They arm the cell only when the field cannot be parsed at all under it.** The value used for an invalid character is fixed by design decision (no unsealed evidence survives; the 1963 movers are in the sealed archive, D0.9): **the low-order four bits of the 6-bit BCD character are taken as the digit value, and zone bits that are not a documented overpunch sign are ignored.** Nothing reads, prints from, or clears SYS)131; **the cell stays sticky.** … The GET-path length-control-word check SYS)261/263 keeps its own separate behavior — it prints its message and exits to the CT Monitor — and is never used as the MOVE/arithmetic reaction.

Implementation, `decisions.md:678`: "Lands in the SYS/IOC runtime (numeric convert handlers, SYS)131) and in the emulator (cell storage). **The scientific-decimal free-form parser is a separate code path from the external-decimal and edited digit scanners; do not share the validity test between them.** Diagnostics: none at object time; **do not raise a Dart exception and do not stop the run.** … An optional, clearly non-historical emulator switch may report SYS)131 transitions to the host log; **it must not change emitted code or program-visible state.**"

Oracle `680`: "decision-conformance only".

### D4.9 — Edited source moved to an alphameric target (`decisions.md:749-760`)

Status `751`: "Locked." Decision `752`: "An edited source moved to an alphameric target transmits the converted numeric form, not the edited character image. Codegen compiles the move as edited-to-external-decimal conversion (the SYS)189 family, with its counted overflow-test step) followed by an alphameric transfer of the resulting external-decimal characters into the target; the editing characters `$ , . * 8 + -` never reach the target. Target justification and blank fill follow the ordinary alphameric rules for the target's level."

Implementation `756`, the one line that scopes stage 4's work: "Lands in the MOVE legality/routing table and codegen (two-step route through external decimal); **the SYS/IOC runtime needs no new handler.** … Record as evidence-supported inference, not attested code." Oracle `758`: "decision-conformance only".

### D4.11 — MOVE BLANKS into edited/external fields (`decisions.md:775-788`)

Status `777`: "Amended." Decision `778`: "MOVE BLANKS to an edited field or to an external-decimal field is accepted and produces blanks. Codegen emits the attested figurative-constant call, not an inline fill: set the target pointer inline (`LDI CP)+nn / STI SYS)133`), enter MOVPAK at `TSX SYS)182,4`, then `TXI SYS)243,1,<target character count>` — SYS)243 being the MOVPAK subroutine that 'moves blanks to an alphabetic field' ([J 90.02.25]). No numeric convert is called and no overflow test is emitted. … A BLANK move to an external-decimal target is not exercised by the sample; our codegen routes it through the same SYS)243 sequence with the target's full character count, which is a design decision under D0.4."

Implementation `782`, the handler sentence: "The blank character is the 6-bit BCD blank code from the D0.6 tables; **the fill itself lives in the SYS)243 handler, not in emitted inline code.**"

Amendment `786`: "**Amended (M3 stage 2, 2026-08-04).** The Decision's 'these two cases' is widened to five. The [J 02.04.02] chart stars every non-alphameric cell of the BLANK row: external decimal, internal decimal, edited, floating point, and scientific decimal. … **The chart's stored value differs by class: blanks for external decimal, edited and scientific decimal; 0's for internal decimal and floating point.** The SYS)243 sequence above is the blanks case, and **M4 codegen follows the chart column by column.** Open, not done: the same chart stars six more doubtful cells, HIGH.VALUE and LOW.VALUE into external decimal, edited and scientific decimal."

### D4.14 — "Integer" against a trailing-S scaled field (`decisions.md:818-832`)

Status `820`: "Jack's call." Blockquote `822`: "**Resolved by Jack, 2026-08-04** … It changes no decision: it binds what the 2026-08-04 call decided and what M3 stage 2 already implements."

Decision `824`, the object-time half: "The assigned GO TO index takes the value sense: a trailing-S field passes, because its values are whole; msg 130 fires only on true fraction positions, and the integral part serves. **Code generation indexes by the raw stored digits and never adds a scaling step.**"

Implementation `828`: "Landed with M3 stage 2 (M3-20 …). **M4 code generation must index by the stored digits and never invent a scaling step.**" Oracle `830`: "decision-conformance only: no field in the 90.05 sample carries `S`, so the listing-diff is silent on every branch."

### Other decisions that fix object-time runtime behavior in the stage-4 set

- **D2.7 — the STOP handlers.** `decisions.md:539`: "Recorded design decisions, flagged internally per the fidelity policy: the encoding of the STOP-type Constant Pool words (M4-14 as amended holds it); **that the halt for STOP type NNN occurs inside the SYS)178 runtime handler** (no STOP n appears in the sample, and no instruction-level evidence survives); and STOP n's display of n and resume-at-next-instruction on restart per [F p. 54] (Open Question 69)." The generated sequence is fixed at `decisions.md:535`: STOP RUN is "`TSX SYS)178,4` / `PZE CP)+26,,CP)+27` / `PZE CP)+28,,CP)+29` … then a second `TSX SYS)177,4` / `PZE IOC)1` … then `TXI IOC)40,0`", and "**No halt instruction is generated.**"
- **D3.2 — BLANK WHEN ZERO is a handler parameter.** `decisions.md:567`: "a move into it is performed by the MOVPAK edited-target move subroutines. These are SYS)185 (external decimal to edited), SYS)190 (edited to edited) and SYS)267 (internal decimal to edited), with the round step-subroutines SYS)220 and SYS)222 where a step list applies. **Their documented parameter set includes Blank When Zero** ([J 90.02.17]). … **The compiler emits the documented calling sequence, not an inline blank-fill loop.**"
- **D5.3 — the SYS)162 compare handler's length rule.** `decisions.md:871`: "Apply right truncation of the longer field to all four magnitude operators — GT, LT, NOT GT and NOT LT — when the two compared alphameric fields have unequal lengths." Implementation `875`: "codegen of the compare sequence and **any SYS) compare helper**." Oracle `877`: "decision-conformance only … **with SYS)162 never called in the program**, so no listing evidence exists for this rule."
- **D8.1 — the two collating tables the compare and figurative-constant handlers read.** `decisions.md:1221` gives both sequences in full and fixes the endpoints: "thus LOW.VALUE = `0` and HIGH.VALUE = `(`" natively; "thus LOW.VALUE = blank and HIGH.VALUE = `9`" under COM; "**Comparison, collation and figurative-constant logic select the table from whether COM is in effect.**" Implementation `1224`: "**Emulator and runtime: two comparison tables, selected by the COM option; figurative constants HIGH.VALUE/LOW.VALUE take their values from the sequence in effect** (§1.7.4)." M4-17 names the table's cell: `m4-codegen.md:902-904` "SYS)161 among them is the 709-to-705 collating table the compare path reads — **data, not code**". M4-11 fixes the OP word: `m4-codegen.md:658-661` "anything longer calls SYS)162 with its collate-table OP word (`CVR` under COLLATE COM, `NOP` otherwise — [J 90.02.12]; D8.1). **The sample never calls SYS)162, so the boundary is exercised only by constructed decks.**" And `emulator.md:158-163`: "Under D0.3 the Dart handler for SYS)162 reads that word as a parameter, so the CPU itself may never execute a CVR; both are implemented anyway … which keeps the core correct if a future runtime routine executes its OP word."
- **D5.4 and D5.7 — behavior the emulator must reproduce, not guard.** `decisions.md:884`: "A transfer out abandons the planted return and leaves the head cell stale; the next DO of P overwrites the cell with its own `SXA`, **so no cleanup code and no runtime guard are generated.**" `decisions.md:923`: "**The emulator reproduces that behavior exactly — a loop or a wild transfer — with no runtime message. Generate no stack, save area or activation record**; all working storage stays in the fixed `RS)`, `TS)`, `PI)` and constant-pool blocks."
- **D5.1 as amended — a non-terminating loop must be reproduced.** `decisions.md:849`: "Overshoot and p > r now terminate; **a zero or wrong-signed q with p ≤ r still never terminates, and the emulator reproduces that.**"
- **D5.5 — the assigned-GO-TO range test is generated code, with an off switch.** `decisions.md:897`: "implemented as a generated object-time range test. Record that test as a design decision, not as attested field-test behavior … **provide a documented compiler option that omits it**, so a future find of period object code can be matched without a language change."
- **M5-scoped, listed so stage 4 does not build them:** D6.3 (named CLOSE path), D6.4 (print-image FILE and record marks), D6.5 (GET on an unopened file; SYS)265 "prints the message and exits to the CT Monitor", `decisions.md:998`), D6.6 (SYS)265/SYS)283 exit words), D6.7 (blocking/deblocking), D6.2 (label vector), D7.3 (BUFFERCOUNT fallback), D8.6 (tape density). Each names "SYS-IOC runtime" in its Implementation line and each falls in M4-17's M5 half.

---

## 4. TEST AND CODE RULES

### CLAUDE.md section 11, verbatim (`CLAUDE.md:273-302`)

> ### No untested and unexercised code
>
> Code that no test asserts on **and** that no program run reaches must not
> enter the repository. Delete it. This is a hard rule, not a preference.
>
> Two words carry the rule, and they are not the same test:
>
> - **Exercised** — a normal run of the compiler or a tool reaches the code.
> - **Tested** — a test asserts on what the code does.
>
> Four cases follow. Only the last one is banned:
>
> | Exercised | Tested | Verdict |
> |---|---|---|
> | yes | yes | Good. Nothing to do. |
> | yes | no | Permitted, with caution. The code has a caller, so a change to it can break the program silently. Prefer to add the test. |
> | no | yes | Permitted. Keep watch: the code needs a concrete plan to get a caller. Record the plan in the design record that asks for the code. |
> | no | no | **Banned. Delete it.** |
>
> The rule binds a whole symbol and each of its parts: an unread field, an
> unused parameter, an unreachable branch, and a constant with no reader are
> each dead on their own, inside a class that is otherwise alive.
>
> Two consequences to expect:
>
> - **Do not write scaffolding for a later milestone.** Where nothing yet
>   asks for the shape, do not write it, and say so in the pull request.
> - **A design record that requires banned code is a peer collision.** No
>   rank in section 6 covers this file against a design record. Do not
>   delete the code, and do not amend the record. Stop and bring it to Jack
>   under the section 6 collision rule.

### REVIEW.md criteria that will be applied to emulator and handler code

- Severity, `REVIEW.md:8-14`: "**Blocker:** a real defect. Examples: wrong behavior, a broken invariant, a test that cannot fail, **code that is neither exercised nor tested (CLAUDE.md section 11)**, a diff that touches `comtran-manuals/` without a quoted authorization from Jack, a hand edit to a generated file (CLAUDE.md section 10), a hand edit to a `.ct` mirror."
- `REVIEW.md:15-16`: "**Advisory:** a humanness finding from the list below, a style point, a nit. Cap nits at five per review; keep the most useful ones."
- `REVIEW.md:18-19`: "Every finding must cite `file:line` and quote the text it concerns. Drop a finding that cannot."
- Humanness finding 1, `REVIEW.md:26-27`: "A ghost abstraction: a helper, class, or layer with one caller and no likely second caller." — one dispatcher, one CPU wrapper.
- Humanness finding 3, `REVIEW.md:31-33`: "Dead weight that the section 11 blocker does not already catch: **code a test asserts on but no run reaches**, or commented-out code." — this is the advisory that lands on every contract-tested-but-unemitted handler.
- Humanness finding 4, `REVIEW.md:34-35`: "Repeated ceremony: the same multi-line pattern at many sites that one local helper would remove." — 130 handlers of similar shape.
- Humanness finding 6, `REVIEW.md:38-39`: "Test slop: duplicate coverage, a test that asserts the mock, setup that restates the implementation."
- Humanness finding 7, `REVIEW.md:40-41`: "Idiom mismatch: code whose naming, comment density, or shape does not match the file around it."
- `REVIEW.md:55-56`: "Cite the manuals as `J 02.03.02` (an IBM section code) or `F p. 42` (a printed page). J28-6169 outranks F28-8043 where they diverge."
- `REVIEW.md:57-58`: "Repository prose follows ASD-STE100 Simplified Technical English (CLAUDE.md section 13). Verbatim manual quotes are exempt."

### HANDOVER "Rules that bind future work" (`docs/HANDOVER.md:291-419`) that touch stage 4

- `HANDOVER.md:297`: "**J28-6169 outranks F28-8043** wherever they diverge."
- `HANDOVER.md:298-299`: "§8.5 and Open Questions are living lists. Annotate an entry in place with the evidence and the date. **Never delete an entry.**"
- `HANDOVER.md:300`: "The definition stays design-free. Compiler design goes in `docs/design/`."
- `HANDOVER.md:301-303`: "The conversions stay read-only. A change needs Jack's explicit authorization. **No candidate is open.**"
- `HANDOVER.md:414-415`: "The page scans (`comtran-manuals/*/images/page-NNN.png`) are ground truth for any disputed reading."
- `HANDOVER.md:416-418`: "For any claim about card columns, measure the page scan. Never trust the indentation of a transcription."
- `HANDOVER.md:409-413`, on the deck/conversion test — the pattern a stage-4 test must not repeat: "It is a regression gate, and **it is not evidence**: both artifacts derive from one scanned copy, so agreement between them is not corroboration."

### Residual caveats (`docs/HANDOVER.md:421-434`) that bind handler semantics

- `HANDOVER.md:423-424`: "Every §8.5 'Resolution' is a labeled judgment call. **It is a default to design against, not a fact.**"
- `HANDOVER.md:425-427`: "Per-message severity values (§8.4) are unrecoverable. Every value we assign is our own design decision (Open Question 65)."
- `HANDOVER.md:428-430`: "Four of the five collating specials carry period-confirmed names. 'Lozenge' remains an inference (§8.5.8). **The Q26 and Q28 residuals are annotated in place.**" — Q26 and Q28 are the two Open Questions D4.1 rests on.

### Other test-and-code rules that bind stage 4

- Test baseline, `HANDOVER.md:68-70`: "Test baseline: 1179 Dart tests pass, measured 2026-08-30 … **Both suites must stay green; re-measure the counts, do not trust them.**"
- The gate, `CLAUDE.md:41-48`: `dart format --set-exit-if-changed`, `dart analyze --fatal-infos`, `dart test`, `deckconv check .`. `CLAUDE.md:54-56`: "`--fatal-infos` is strict. One info-level lint or one unformatted file fails the build."
- Constructed I/O-free decks are decks, so `CLAUDE.md:69-89` binds them: "`X.ctd` — **canon** … It is authoritative"; "The compiler and every tool read canon only"; "**Never hand-edit a `.ct` mirror outside VS Code**"; "Change a deck through `deckconv`, the MCP deck tools, or a VS Code save of either file."
- The emulator's own widening rule, `docs/design/emulator.md:235-236`: "Widening the subset later is additive: **one decode-table entry, one execute case, one manual citation, one test group.**"
- The refusal doctrine handlers inherit from M4-2 as amended, `m4-codegen.md:88-93`: "The stage 2 refusals are not diagnostics: a valid shape the sample never attests fails in the recovery, not in the program — no [J 90.04] message covers it — so the refusal bypasses the sink. **The generator throws `UnrecoveredShape`**, the driver scopes it to the job, and later jobs compile."
- The emulator's fail-loud rule, `emulator.md:19-22`: "Inside generated code, the calling-sequence parameter words … are data for those handlers; the CPU never executes them. **If the instruction counter ever reaches one, the CPU throws (§7) — there is no silent wrong path.**"

---

## 5. THE UNEXERCISED-HANDLER QUESTION

I quote and measure; I do not decide.

### 5a. The two sets, side by side

**M4-17's M4 set**, `docs/design/m4-codegen.md:901-909` (quoted in full in section 2 above): SYS)128–134, SYS)155–173, SYS)179–258, SYS)267–282, SYS)294, SYS)174–178, IOC)1, IOC)40. Counted from those ranges: **130 entries** (7 + 19 + 80 + 16 + 1 + 5 + 2). The count is mine, arithmetic on the record's printed ranges.

**The generator-reachable set**, measured by grepping every call site of the emitting helpers in `lib/src/codegen/procedure.dart` — `_tsx` (defined at `procedure.dart:539`), `_tsxIoc` (`:551`), `_txi` (`:565`), `_sys` (`:630`), `_pzeIoc1` (`:617`) — plus `lib/src/codegen/blocks.dart:74`. This is a static grep of call sites, **not a run**:

| Entry | Call site |
|---|---|
| SYS)132, SYS)133 (MOVPAK pointers) | `procedure.dart:1115-1116`, `:1122` |
| SYS)175 (open all) | `procedure.dart:1338` |
| SYS)177 (close all) | `procedure.dart:1345`, `:1412` |
| SYS)178 (display/STOP) | `procedure.dart:1409` |
| SYS)180 (register-source entry) | `procedure.dart:2124` |
| SYS)182 (memory-source entry) | `procedure.dart:2004`, `:2026`, `:2247`, `:2430`, `:2513` |
| SYS)184, 185, 190, 193, 198, 211, 212, 214, 216, 225, 226 (converts and steps) | `procedure.dart:2005`, `:2027`, `:2030`, `:2054`, `:2056`, `:2058` |
| SYS)239, 240, 241 (alphabetic movers) | `procedure.dart:2434`, `:2436`, `:2437` |
| SYS)243, 244, 245 (figurative fills) | `procedure.dart:2252`, `:2259` |
| SYS)260, SYS)283 (GET exit words) | `procedure.dart:1815`, `:1816` |
| SYS)267 (internal decimal to edited) | `procedure.dart:2141` |
| SYS)268, 269, 275 (edited-to-register) | `procedure.dart:2514`, `:2515`, `:2516` |
| SYS)294 (base-locator guard) | `procedure.dart:1006` |
| IOC)1, IOC)8, IOC)9, IOC)29, IOC)40 | `procedure.dart:619`, `:1814`, `:1858`/`:1863`, `:240` and `blocks.dart:74`, `:1414` |

That is **31 distinct SYS entries and 5 IOC entries** the generator can emit. Two of them — SYS)260 and SYS)283 — M4-17 assigns to M5 (`m4-codegen.md:907-909`), and IOC)29 likewise, though `blocks.dart:74` already emits `IOC)29` as a data operand.

**Named by a D-slate decision but not in the generator's set** (measured the same way): the five round steps SYS)219, 220, 221, 222, 274 (`decisions.md:644`); the nine counted overflow-test steps SYS)195, 196, 199, 201, 203, 204, 270, 277, 281 (`decisions.md:661`); the families SYS)183, 189 (`decisions.md:661`, `:752`); the no-step-list handlers SYS)186, 187, 188, 246, 247 (`decisions.md:661`); all of SYS)155–173 including SYS)161 and SYS)162.

### 5b. Every text that bears on which set stage 4 builds

**Section 11's scaffolding consequence** — `CLAUDE.md:298-299`:

> - **Do not write scaffolding for a later milestone.** Where nothing yet
>   asks for the shape, do not write it, and say so in the pull request.

**Section 11's tested-but-unexercised row** — `CLAUDE.md:289`:

> | no | yes | Permitted. Keep watch: the code needs a concrete plan to get a caller. Record the plan in the design record that asks for the code. |

**Section 11's collision clause** — `CLAUDE.md:300-302`:

> - **A design record that requires banned code is a peer collision.** No
>   rank in section 6 covers this file against a design record. Do not
>   delete the code, and do not amend the record. Stop and bring it to Jack
>   under the section 6 collision rule.

**M4-17 itself** — `docs/design/m4-codegen.md:901-910`: "M4 lands the compute set — the cells and flags SYS)128–134, the scaling, exponent, and comparison routines SYS)155–173 … **MOVPAK entire (SYS)179–258, 267–282)**, the base-locator guard SYS)294 — plus the run-frame stubs SYS)174–178 … and IOC)1, IOC)40, **enough to run an I/O-free program to its STOP**. … Each handler implements its [J 90.02] contract and is unit-tested against it (D0.3)."

**D0.3** — `docs/design/decisions.md:190-195`: "Dart handlers sit at the documented entry points, each implementing its [J 90.02] interface contract … and each unit-tested against that contract. **Any routine is individually replaceable by real 7090 code if authentic code ever surfaces; the contracts and tests then validate the find.**"

**The HANDOVER roadmap M4 row** — `docs/HANDOVER.md:488-494`, in full:

> - **M4 — Core-verb code generation** (stage 1 done 2026-08-05, the
>   assembly model and the storage-map print): MOVE, SET, IF, WHEN, GO TO, and DO. DO
>   follows the verified Q40 return-cell semantics, non-reentrancy included.
>   Arithmetic follows §4.3 and the Q26–Q28 annotations. The emulator core
>   (`docs/design/emulator.md`) hardens here. The msg 942 dictionary counter
>   took the compiler-generated names at stage 2, chunk B8: [J 90.01.05]
>   item a) counts them with the programmer names (M3-21; M4-5).

**emulator.md section 1 and the harvested-subset idea** — `docs/design/emulator.md:8-10`: "**The instruction subset comes from the code that the COMTRAN compiler generates, harvested from [J 90.02] and the [J 90.05] compilation listing.**" `emulator.md:15-22`, section 1 in full:

> The core executes the CPU instructions that appear in COMTRAN-generated
> object code. It does not execute the SYS)/IOC) runtime: those routines are
> high-level Dart handlers at the documented entry points (D0.3). The caller
> (the M4 machine assembly) intercepts control before the CPU enters a runtime
> entry address. Inside generated code, the calling-sequence parameter words
> (PZE, MZE, OCT, IOST, IOCTN data words) are data for those handlers; the CPU
> never executes them. If the instruction counter ever reaches one, the CPU
> throws (§7) — there is no silent wrong path.

`emulator.md:102-108`, the harvest method — the precedent for building only what the generator emits: "Harvest method: **every executed line of the [J 90.05] compilation listing was parsed by its octal opcode column** … and every inline-code shape in [J 90.02] was collected. Pseudo-operations and data words … are loader/runtime data, not CPU instructions, and are excluded." `emulator.md:232-236`: "**Convert CRQ/CAQ, and the rest of the ~200-instruction set**: not harvested; every one decodes to a typed throw, never to silence. … Widening the subset later is additive."

But the harvest was **not** purely generator-reachable — `emulator.md:158-163` records the one exception, and it is a runtime-handler case: "NOP and CVR are attested as the OP word of the SYS)162 alphabetic-compare calling sequence ([J 90.02.12]). Under D0.3 the Dart handler for SYS)162 reads that word as a parameter, so the CPU itself may never execute a CVR; **both are implemented anyway because they are attested in generated code and fully documented** (M pp. 35, 56), which keeps the core correct if a future runtime routine executes its OP word."

**The repository's one worked precedent for "tested, not exercised, with a recorded plan"** — `docs/design/loader.md:137-147`: "**No program run reads the result yet**: stage 4 reads `origin`, `entry` and `words`; M5's IOCS reads `deckName` and the `LoaderFile` fields … a caller that loads a second deck reads `cardsRead`; a resolver that keeps the raw code, as the round-trip test's does, reads `SystemReference.code`. **The tests read them all.** The machine assembly stage writes the words into `MachineState` and runs; **that is the plan CLAUDE.md section 11 asks for.**"

**The one time section 11 beat a design record's ask** — `docs/design/m4-codegen.md:82-86`: "**Amended 2026-08-05 and 2026-08-15, stages 1 and 2.** Stage 1 built the map from validated semantic facts and could detect no error, so **under CLAUDE.md section 11, which outranks this record**, it shipped without the stop shape. Chunk B8 (2026-08-28) added the sink and the stop".

**The one time a record deliberately left a documented shape unbuilt** — `docs/design/m4-codegen.md:711-718`: "Six unattested variants refuse (M4-2 as amended): … **a comparand past one word: the SYS)162 boundary stays unbuilt** beside AND, OR and NOT, the compound-condition precedent." The refusal is live in the code at `lib/src/codegen/procedure.dart:3048`: `_unruled('a comparison past one word (M4-11, the SYS)162 boundary)')`. M4-11 says the same at `m4-codegen.md:660-661`: "The sample never calls SYS)162, so the boundary is **exercised only by constructed decks**."

**Why SYS)265 is never emitted** — `m4-codegen.md:849-856`: "**Amended 2026-08-17, chunk B6.** Every other I/O form refuses (M4-2 as amended): … **GET with no AT END (SYS)265 unattested)**, GET from a file declaring ON ERROR (the SYS)283 replacement is unknown)". D6.5 nevertheless fixes SYS)265's object-time behavior (`decisions.md:994`, `:998`).

**Records that already say the sample never exercises a handler** — D5.3's Oracle, `decisions.md:877`: "**with SYS)162 never called in the program**, so no listing evidence exists for this rule." D4.1(d), `decisions.md:644`: "**it keeps the five round steps reachable** … this rule keeps the round steps live there, where reading (iii) kills all five." D4.1's resolution blockquote, `decisions.md:634`: reading (iii) was rejected in part because "it **strands** the five round steps".

**M4-10 names four more unemitted compute routines** — `m4-codegen.md:546-551`: "Double-precision work uses SYS)128/129 and the SYS)163–171 scaling and divide routines by their [J 90.02] calling sequences; **no double-precision or source-level divide appears in the sample, so these shapes are reconstructions labeled by this entry.** … exponentiation routes through SYS)155/156/172/173."

**And REVIEW.md's standing advisory on exactly this shape** — `REVIEW.md:31-33`: "Dead weight that the section 11 blocker does not already catch: **code a test asserts on but no run reaches**".

---

## 6. ROADMAP

`docs/HANDOVER.md:488-506`, the four rows verbatim:

> - **M4 — Core-verb code generation** (stage 1 done 2026-08-05, the
>   assembly model and the storage-map print): MOVE, SET, IF, WHEN, GO TO, and DO. DO
>   follows the verified Q40 return-cell semantics, non-reentrancy included.
>   Arithmetic follows §4.3 and the Q26–Q28 annotations. The emulator core
>   (`docs/design/emulator.md`) hardens here. The msg 942 dictionary counter
>   took the compiler-generated names at stage 2, chunk B8: [J 90.01.05]
>   item a) counts them with the programmer names (M3-21; M4-5).
> - **M5 — I/O runtime**: OPEN, CLOSE, GET, and FILE; buffering and locate mode;
>   AT END and ON ERROR per Q41; labels per Q45 and Q46 at the M0-chosen fidelity;
>   DISPLAY and report output.
> - **M6 — Acceptance**: compile and run the 90.05 payroll sample end to end, and
>   reproduce its printed report output (PDF p. 217). Then take a second corpus —
>   F's payroll example with the documented F/J divergences applied (§9.8).
> - **M7 — The diff pass**: the seal ends when this milestone opens. Assemble the
>   1963 processor, and diff our reconstruction against it. Each difference is one
>   of two findings: a real change between January 1962 and July 1963, or an error
>   in our recovery. Treat MOVPAK and Open Question 31 as contaminated; D0.9 says
>   why. That result is the project's headline finding (D0.9).

**The M4 row states no acceptance criterion.** It names scope only; the acceptance sentence lives in the M6 row ("compile and run the 90.05 payroll sample end to end, and reproduce its printed report output"). The closest thing M4 has to an acceptance criterion is in two other files:

- The charter, `docs/design/m4-codegen.md:22-25`: "M4 also hardens the emulator into a machine: a loader places the deck in core, and a dispatch layer runs the SYS)/IOC) handlers the core verbs call. The 90.05 sample first runs at M6, after M5 lands the IOCS handlers; **M4 executes I/O-free programs.**"
- The stage-4 oracle, `docs/design/m4-codegen.md:1055-1056`: "Stage 4: per-handler D0.3 contract tests; end-to-end runs of constructed I/O-free decks with storage assertions."

The stage list, `docs/design/m4-codegen.md:44-45`: "4. **The machine assembly** — the runtime dispatch layer and the compute handlers (M4-17), and execution tests for I/O-free programs." And `:35-36`: "Four stages, **one pull request each, each green alone**" — with `:63-66` noting "Stages 1, 3, and 4 do not change" by the stage-2 chunking amendment.

State, `docs/HANDOVER.md:56-57`: "| M4 stage 4, M5, M6, M7 | Not started | — |" and "| M4 emulator core (early, 43 harvested opcodes) | Draft (PR #10); **hardens in M4 stage 4** | `lib/src/emulator/` |".

Two carried items, `docs/HANDOVER.md:93-97`:

> - the loader returns the words by address; stage 4 writes them into
>   `MachineState` and enters at the entry point (LD-3);
> - a labeled PROGRAM.START does not yet name the entry point: the
>   end-of-text entry names `GN)000` for every program (D2.1; LD-3).

D2.1's amendment says the same, `docs/design/decisions.md:465`: "It does not yet honor a labeled PROGRAM.START; **that path waits for stage 4, where a program first runs.**"

---

## 7. GAPS — rules stage 4 needs that no record settles

Each item below is a search I ran that found nothing, stated with the text that shows the gap is real.

1. **No record fixes the dispatch table's addresses.** `docs/design/loader.md:134-136`: "**The dispatch table is M4-17's** and the file blocks are M5's, **so no address is fixed here**." M4-17 (`m4-codegen.md:893-896`) says only "before each step at an address registered as a SYS)/IOC) entry, the dispatcher runs the Dart handler instead of the CPU" — it never says what address each entry gets, who registers them, or how they avoid the loaded program's origin. Stage 4 must choose.
2. **No record fixes the runtime component's home directory.** `CLAUDE.md:27` lists `lib/src/`'s components as "`cards`, `chars`, `lexer`, `parser`, `ast`, `data`, `codegen`, `loader`, `driver`, `listing`, `emit`, `emulator`, and `mcp`" — there is no `runtime`. `lib/src/emulator/` today holds four files (`cpu.dart`, `decode.dart`, `machine_state.dart`, `word.dart`). Whether 130 handlers go inside `emulator/` or into a new component is unsettled, and the choice edits CLAUDE.md §3.
3. **No record fixes the contract-test conventions.** The phrase "per-handler D0.3 contract tests" appears exactly twice in the repository — `m4-codegen.md:1055` and `HANDOVER.md:91` — and neither names a file layout, a naming rule, or a fixture form. `test/emulator/` holds an assembler helper (`asm.dart`) and per-opcode-group test files; nothing says handler tests follow that shape.
4. **The XR4 resume convention has one clause and no worked example.** `m4-codegen.md:896-898`: "a TSX-linked handler reads its calling sequence through XR4, honors the resume convention (parameter-word count plus one), and returns control." No record states how a handler with a *variable* parameter count (the MOVPAK step lists, which run "two or more" instructions per `decisions.md:644` quoting [J 90.02.16]) computes that count, nor how a `TXI`-linked step differs from a `TSX`-linked entry.
5. **"Exits to the monitor" is undefined as a run outcome.** M4-17 says SYS)294 "exits to the monitor instead of returning" (`m4-codegen.md:899-900`) and D2.7 makes `TXI IOC)40,0` "the CT Monitor end-of-job return point" (`decisions.md:535`). `emulator.md:227-228` says "the CT Monitor boundary is a high-level handler". No record says what the emulated run *returns* on a monitor exit, how a test distinguishes a normal STOP RUN from a base-locator-guard trap, or what exit code a run carries.
6. **SYS)178's display output has no sink.** D2.7 requires SYS)178 to display "the Statement Number of the Stop (in BCD), and the type of STOP" (`decisions.md:535`), and D2.7 puts STOP n's halt "inside the SYS)178 runtime handler" (`decisions.md:539`). D0.7 puts "the printer" at "the emulator boundary" as a print file (`decisions.md:255-256`), but no record names the stage-4 sink for a display, and D0.7 defers the detail: "Detailed decisions land in D6 (I/O) and at M5" (`decisions.md:257-258`).
7. **STOP n's resumable halt is an unresolved Open Question.** `decisions.md:537`: "STOP n's restart behavior stays a design decision: [J 05.06.04] states only that the computer stops and 'hitting the START key will cause the object program to continue in execution', while [F p. 54]'s resume-with-the-next-command wording is unconfirmed for the field-test processor — **Open Question 69, unresolved**." A stage-4 handler for SYS)178 must implement a halt whose resume semantics are open.
8. **The run-frame "stubs" have no defined content.** M4-17 lands "the run-frame stubs SYS)174–178 (open and close, one file and all, and the display routine) and IOC)1, IOC)40" (`m4-codegen.md:905-906`). No record says what SYS)175/SYS)177 do with `PZE IOC)1` in a program that opens no files, or whether "stub" means a no-op, a contract-checked no-op, or a partial implementation. The word "stub" appears in no other record.
9. **SYS)128/129 and SYS)134 have no semantic record.** SYS)130 has D4.2, SYS)131 has D4.3, SYS)132/133 are the MOVPAK pointers used in codegen (`procedure.dart:1115-1116`). M4-17 includes SYS)128–134 whole (`m4-codegen.md:901`); M4-10 says only "Double-precision work uses SYS)128/129" (`m4-codegen.md:546`). Nothing states what SYS)134 holds.
10. **No record settles the section 5 question.** No text in the repository states whether stage 4 builds all ~130 M4-17 entries or the generator-reachable subset. Section 5 above holds every text that bears on it; none decides it. The two candidate outcomes have different CLAUDE.md §11 consequences — the full set is "no / yes" (permitted with a recorded plan, `CLAUDE.md:289`), a partial build against an unamended M4-17 is potentially the §11 peer collision of `CLAUDE.md:300-302`.
11. **The constructed I/O-free test decks do not exist and no record specifies them.** `m4-codegen.md:1056` asks for "end-to-end runs of constructed I/O-free decks with storage assertions" and `m4-codegen.md:661` for constructed decks to exercise the SYS)162 boundary. `test/fixtures/` holds the 90.05 canon deck and its mirror; nothing states how many constructed decks stage 4 needs, what they assert, or where their goldens live. They are decks, so `CLAUDE.md:69-89` binds their form.

One correction to a stale note carried outside the repository: the assistant memory index says the seal lifts at M6. Both repository homes say **M7** — `CLAUDE.md:222` "The seal ends when M7 opens" and `decisions.md:302` "M7 runs the diff pass. The seal ends when M7 opens, and not before." Cite the repository.