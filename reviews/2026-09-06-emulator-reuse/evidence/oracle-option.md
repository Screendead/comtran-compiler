# The differential-oracle option, assessed on its own

The agent's own text, unedited. Its claim that PDF p. 217 is absent from the
plan is wrong; see the record.

FIRST, A CORRECTION TO THE TASK'S PREMISE.

The minus-zero paths are not our interpretation. They are the one part of section 6 that the design record marks as attested and followed literally. `docs/design/emulator.md:167` (ADD/SUB minus zero) says "The implementation follows that algorithm literally", citing M p. 20 and its Figure 21. `docs/design/emulator.md:180` (MPY with a zero factor) says "Implemented exactly", citing M p. 22. `docs/design/emulator.md:183` (DVP divide check) states the rule from M p. 24 with no hedge. None of these three carries an ED-n label, and the labels are the record's own marker for an unattested choice ("Every unattested choice is labeled `ED-n`", `docs/design/emulator.md:9`). Grouping minus zero with ED-2 overstates what is open.

THE RULES ACTUALLY MARKED AS OURS, BY NAME.

Section 6 holds nine bullets (`docs/design/emulator.md:165-208`). Seven ED labels exist in the whole document: ED-1 through ED-6 plus ED-2a. The genuinely unattested set is:

- ED-2, overflow gating (`emulator.md:172`). The manual's trigger is "a carry from position 1 to position P"; in the unlike-signs complement path internal carries ripple through P even when the algebraic result is small. We set overflow only when effective signs are alike. The record itself says "Recorded as a decision, not as attested fact."
- ED-2a, the LGL overflow trigger (`emulator.md:190`). "Into or through position P" (M p. 32) is read as: a 1 moved from position 1 into P. A 1 that starts in P and leaves toward Q does not trigger.
- ED-5, stepwise shifts (`emulator.md:186`). The results are attested; the one-step-per-count mechanism is ours.
- ED-6, memory starts at +0 (`emulator.md:60`). "Recorded as a decision because no source attests a power-on value."
- ED-3, 0760-family dispatch (`emulator.md:194`), and ED-4, fail-loud decode (`emulator.md:199`). Both are scoping choices, not semantic claims.
- CVR's two corners (`emulator.md:204`): that an initial 1 in Q survives in position 5 regardless of the table word, and the tag-bit-20 XR1 update on completion.
- Indirect addressing honored on every instruction whose manual diagram carries the flag (`emulator.md:93-98`), where generated code only ever uses it on TRA.
- The ACL sign path. Not an ED label and not in `emulator.md`, but `docs/design/decisions.md:537` (decision D4.1(a)) says plainly: "This ACL reading is an inference from 709/7090 instruction semantics, external to both manuals (Open Question 26); neither manual states it, and the sample exercises no negative value." `docs/opportunities.md:514` names it as one of the records that reads the emulator's own behaviour as its decision.

WHAT A DIFFERENTIAL TEST WOULD DISCRIMINATE.

The right filter is the repository's own standing rule, `docs/opportunities.md:500`: "Spend on emulator work only where it decides a question about the compiler's output." Applied item by item:

Passes — worth testing:
- ED-1's consequences. The 70-bit MPY product and the 72-bit DVP dividend go through BigInt and back (`emulator.md:36-42`). This is not a reading of anything; it is arithmetic that can simply be wrong, and DVP sits in the D4.1 scaling tail `XCA / ACL / LRS 35 / DVP / STQ` that the object listing prints four times. A width bug changes stored money values.
- Subtractive indexing: effective address = address minus the OR of tagged index registers, mod 2^15 (`emulator.md:90`). The 709x subtracts where almost every other machine adds. Cheap to check, catastrophic if wrong, and every indexed instruction in the sample depends on it.
- Multiple-tag OR on read, load-all on write, tag 0 stores zeros (`emulator.md:65-71`). Observable: `AXT *+3,7` loads XR 1, 2 and 4 at END.OF.RUN in the sample listing.
- Shift counts mod 400 octal, and counts of 36 or more (`emulator.md:161`). A classic bug farm, and ALS/ARS/LRS/LGL/LGR/RQL are 30-plus sites in the sample.
- Minus-zero results (not the gating, the results). Whether ADD of equal magnitudes and unlike signs leaves the original AC sign, whether MPY by zero with unlike signs yields minus zero, what LRS does to the MQ sign, whether CAS ranks +0 above −0, whether TPL transfers on minus zero. A minus zero reaching a stored data field is visible in object-program output.
- ACL mechanics: adds into AC(P,1-35), end-around carry P into 35, S and Q untouched (`lib/src/emulator/cpu.dart:104-111`). Worth separating from the D4.1 question below.
- DVP's register results after a check: dividend unchanged, what AC and MQ hold, and that the machine proceeds.

Fails the filter — discriminable but decides nothing:
- ED-2 and ED-2a. Both concern the overflow indicator, and nothing in generated code reads it. `emulator.md:178` states the reason: "no TOV, TNO, or DCT is harvested". The codegen plan confirms it independently — ON OVERFLOW is implemented as an inline object-time magnitude test against a pool constant, not a hardware indicator read, and `docs/design/m4-codegen.md:576` says "SYS)130 is not used for this: nothing may clear it (D4.2), so a sticky cell cannot carry a per-statement test." A disagreement on either would be a real finding about the 7090 and a non-event for this compiler.
- CVR. Under D0.3, the CVR word is the OP word of the SYS)162 alphabetic-compare calling sequence and is read as a parameter by a Dart handler; `emulator.md:163` says "the CPU itself may never execute a CVR". The simulator does implement it (`OP_CVR` at i7090_cpu.c:3055), so the comparison is technically available, but it tests code that has no caller.
- Indirect addressing on non-TRA instructions. Generated code carries the flag on TRA only, six sites (`emulator.md:97`). Whether the real machine honors indirect on ACL decides nothing here.
- The DVC indicator itself, for the same reason as ED-2: no DCT is harvested.

Not discriminable at all:
- ED-3 and ED-4. Our throw on an out-of-subset word is a deliberate scoping decision; the simulator executes those words. Every such case is a false disagreement and the harness has to filter them before comparing, or the report is noise.
- ED-6. The harness sets the initial state on both sides, so power-on contents never arise.

The shape of that list is the finding: the differential test is most useful on the instructions we are already most confident about, and least useful on the four the task named.

WHAT IT WILL NOT TOUCH AT ALL.

Every COMTRAN-language question. D4.1's rounding polarity, whether TRUNCATED suppresses only the `ACL` word (`decisions.md:539`), the MOVPAK round-step emission rule (`decisions.md:543`), ON OVERFLOW, DO termination. These are questions about what IBM's compiler emitted, and a CPU simulator is silent on all of them. The ACL split matters here: the instruction's mechanics are plainly stated on M pp. 21-22 and a differential check confirms them cheaply, but what D4.1 flags as external inference is whether the compiler *meant* away-from-zero rounding for negative values. Confirming the first is not evidence for the second, and it would be easy to let it look like it was.

Also untouched: the SYS)/IOC) handler semantics, which are the actual remaining M4 stage 4 work. The runtime library is lost for the simulator's authors too. And the loader, the deck format, and the listing — none of which the CPU sees.

THE HARNESS, MECHANICALLY.

Use Open SIMH's `i7090` (Richard Cornwell and Robert Supnik), not mainline simh's `I7094`. Documentation: https://opensimh.org/simdocs/i7090_doc.html. Source: https://github.com/rcornwell/sims.

The register mapping is unusually clean — every element of our `MachineState` has a named console register. The documented table gives IC 15 bits, AC 38 bits, MQ 36 bits, ID (indicators) 36 bits, XR1 through XR7 at 15 bits each, ACOVF 1 bit, MQOVF 1 bit, DVC 1 bit, plus MTM (multiple tag mode). AC at 38 bits is exactly our sign plus 37-bit magnitude, so the conversion is `(sign << 37) | magnitude`. ID at 36 bits is our SI, and because we chose position 0 = bit 35 so LDI/STI are bit-for-bit word moves (`emulator.md:50`), it should compare directly. Confirm all of this on the first run rather than trusting my reading of a doc page.

The loop, per case:
1. Write a simulator command file: `set cpu 7090` first — this one matters, see below — then `deposit` for each memory word and each register, then `go <entry>` or `step n`, then `examine state` to dump every register in one parseable block, then `examine <range>` for the memory cells under test, then `quit`.
2. Run the simulator as a subprocess with `set console -n -q log=out.txt` (the shipped test script uses exactly that form) and parse the log.
3. Run the same initial state through our `Cpu` and compare.

Three specific traps:
- **Set the CPU model explicitly; do not rely on the default.** The 7094 has seven index registers and, outside multiple-tag mode, three tag bits select one register rather than OR-ing several. Every tag-3/5/6/7 case would disagree spuriously, and the disagreement would look like a real finding. Note also that the simulator's own shipped test script runs the diagnostics under `set cpu 709`, not 7090; fixed-point semantics are the same, but it is worth knowing which model a given result came from.
- **Filter ED-4 cases before comparing.** Our `UnimplementedOpcode7090` versus the simulator executing the word is not a disagreement, it is our scope.
- **Watch the AC's Q and P.** Our layout puts Q at bit 36 and P at bit 35 of the magnitude (`emulator.md:31`). Get this wrong and half the arithmetic cases will disagree for a reason that has nothing to do with either implementation's reading of the manual.

COST.

About 8 to 16 hours for a first pass: roughly 1 hour to build (C toolchain, no unusual dependencies for this target); 1 to 2 hours confirming the register round-trip in both directions, which is the real risk and where a silent mapping error would poison every result; 2 to 3 hours for the harness itself; 2 to 4 hours generating cases — hand-picked boundaries per instruction plus randomized fuzzing across the 43 opcodes; 2 to 6 hours triaging disagreements, each of which means re-reading a manual page and deciding.

One-off, not ongoing. The subset is frozen and grows one entry at a time — `emulator.md:242` says "Widening the subset later is additive: one decode-table entry, one execute case, one manual citation, one test group." Re-running against a widened subset is cheap once the harness exists. But nothing catches it when the build rots or the simulator's console output format shifts, because nothing in CI touches it. Treat it as an audit you run twice, not a standing gate.

WHERE THE FINDINGS GO — the loop matters as much as the harness.

A simulator answer cannot become a test assertion in this repository. Under the section 9 evidence rules the page scan is ground truth and a third-party implementation is a secondary source below the manual; under section 11 a `tool/` script that no test asserts on and no program run reaches is banned outright. So: the harness lives outside the repository — scratchpad or a personal checkout. Each disagreement is re-derived from the manual page, M p. N. Only the manual-derived rule enters, as an explicit amendment to the ED entry in `docs/design/emulator.md` plus a unit test citing the page. The simulator's name never appears in a test file. That satisfies "nothing enters CI, nothing is vendored" structurally rather than by discipline.

THE EPISTEMIC CAVEAT, PLAINLY.

A disagreement proves one thing only: two implementations read the same sentence differently. It is a question generator, never a verdict. Under this repository's own ranking the manual outranks any reading of it, so a disagreement sends you to the page scan and the page scan decides.

Agreement proves less than it feels like. Two implementations reading the same ambiguous sentence and landing in the same place is correlated error, not independent confirmation. This bites hardest on ED-2 and ED-2a, where the ambiguity is in the manual's own wording and any author faces it identically.

There is a real upgrade to the simulator's standing that I want to state carefully, because it partly defeats the "another programmer's reading" objection. The IBM 709/7090 customer-engineering diagnostic decks survive and ship inside the simulator's own test directory — 40-plus binary decks named `9a01a.dck`, `9b01a.dck`, `9m01b.dck` and so on, at github.com/rcornwell/sims under `I7000/tests/i7090/`, with a script that loads and runs them. What I can state is that the author runs IBM's period diagnostics against the simulator. What I cannot state is that it passes them: the repository's own `STATUS.txt` says "i7090: Working with exceptions" and lists "DKx sometimes fails diagnostics with missing inhibit of interupt". So where a diagnostic exercises an instruction, the simulator's behaviour carries evidence beyond one person's reading — it is behaviour that period IBM test programs, plus CTSS and SHARE LISP 1.5 (both listed as working), would break on if it were wrong.

Two things blunt that. The author's candour about known bugs is a credibility signal rather than a warning for us: the named arithmetic bug, "DFDP/DFMP sometimes off by +/- 1 or 2 in least significant part of result", is double-precision floating point, outside the 7090 and outside our subset entirely. Nothing listed touches fixed point. But the deeper limit stands — a diagnostic tests what IBM chose to test, and the corners we labeled ED-n are precisely the ones no period program exercises. That is why ED-2's complement-path overflow and ED-2a's P-to-Q case are the weakest candidates: the simulator's author met the same silence and guessed too, and his guess was never exercised either.

CHEAPER SOURCES OF THE SAME CONFIDENCE.

Two, and the second is the one I would act on.

1. The manual's own worked examples and flow charts. A22-6528-4 prints Figure 21 for the ADD algorithm, Figure 26 for the shift flow charts, and the seven numbered steps for CVR — the design record already cites all three (`emulator.md:169`, `emulator.md:187`, `emulator.md:204`). Encoding those figures as test cases costs hours, needs no C toolchain, runs in CI, and is higher-ranked evidence than any simulator under this repository's rules. Some of this is already done; a deliberate sweep to close the gap is strictly cheaper than the harness and answers the same questions where the manual answers them at all.

2. **J28-6169 PDF p. 217, "REPORT OUTPUT FOR SAMPLE PROBLEM"** (`comtran-manuals/J28-6169/90.05-sample-program.md:1875`). The manual prints the actual report the sample program produced — PAYFILE, CHECKFILE, ERRORFILE and BONDORDERFILE, with per-employee detail lines and department totals. That is a behavioural end-to-end oracle on the exact program we already reproduce byte for byte at compile time. It exercises every instruction the compiler emits in exactly the combinations it emits them, which dominates any per-instruction differential test on the things that matter.

   It is not currently in the plan. `docs/HANDOVER.md:88-91` scopes stage 4's oracles as "the per-handler D0.3 contract tests and end-to-end runs of constructed decks with storage assertions" for "I/O-free programs". Page 217 is named nowhere. I think that is a real gap and worth raising on its own, separately from this assessment.

   Two honest costs. It needs the IOCS-level I/O handlers — INPUTMASTER is a binary tape file and DETAILFILE is BCD tape (`90.05-sample-program.md:445-449`) — so it lands after stage 4 as currently scoped, at the end of M4 or in M5. And the input data is not printed anywhere in the appendix; it would have to be reconstructed from the report itself. For the payroll fields that is tractable (40.0 hours against 136.00 gross fixes the rate at 3.40), but the MASTER record's bond accumulation and year-to-date fields may be underdetermined by what page 217 shows. It complements the per-handler tests rather than replacing them.

3. Period diagnostics run directly against us: no. They survive and are available, but they exercise the full roughly 200-instruction set plus traps, channels and halts, every one of which we throw on by design (`emulator.md:218-240`). Running one would mean abandoning the harvested-subset scope — which is exactly what `docs/opportunities.md:504` forbids: "This project does not build a historically accurate 7090 emulator, and no wording here may be read as asking for one." The differential harness is in fact the cheapest way to *consume* those diagnostics' authority without implementing the machine they test.

ONE GOVERNANCE NOTE.

This proposal is not the thing `docs/opportunities.md:511-517` warns about. That entry records Jack's 2026-08-05 option of using someone else's emulator *instead of* ours, and says it "is a real change to D0.3" that must not be amended without his explicit instruction. An offline test oracle that never ships, never enters CI, and never appears in a test file leaves D0.3 untouched — D4.1 and the DO record still read our emulator's behaviour, not the simulator's. Worth saying out loud in whatever record carries this, so a later reader does not mistake one for the other.

## Numbers

Our emulator: 889 lines of Dart in `lib/src/emulator/` (cpu.dart 424, decode.dart 264, machine_state.dart 113, word.dart 88). Tests: 1,614 lines in `test/emulator/` across 10 files, holding 139 test cases (cpu_fixed_point 29, cpu_transfer_index 29, cpu_shift 27, cpu_sense_convert 14, cpu_word_logic 10, decode 9, machine_state 9, cpu_edge_cases 6, word 6; asm.dart is a 19-line helper with no tests). Opcode subset: 43, confirmed by counting the `Op` enum in decode.dart (44 members minus `unknown`), matching the section 5 table.

Recorded interpretations: 7 ED labels total (ED-1, ED-2, ED-2a, ED-3, ED-4, ED-5, ED-6); `ED-n` in the header is the template, not a label. Section 6 holds 9 bullets, at `docs/design/emulator.md:165-208`. Of the 9, three are marked attested and followed literally (ADD/SUB minus zero at :167, MPY zero factor at :180, DVP divide check at :183) and six carry an unattested choice.

Split under the "decides a question about the compiler's output" filter: 7 candidates pass (ED-1's arithmetic widths, subtractive indexing, multiple-tag OR, shift counts, minus-zero results, ACL mechanics, DVP register results); 4 discriminable but decide nothing (ED-2, ED-2a, CVR, indirect-on-non-TRA); 3 not discriminable at all (ED-3, ED-4, ED-6).

Third-party oracle: Open SIMH `i7090`, exposing 8 CPU registers that map one-to-one onto our machine state (IC 15 bits, AC 38, MQ 36, ID 36, XR1-7 at 15 each, ACOVF 1, MQOVF 1, DVC 1). Its test directory ships 40-plus IBM 709/7090 customer-engineering diagnostic decks and a script that runs them; its `STATUS.txt` lists 3 known i7090 bugs, none in fixed point.

Cost: 8 to 16 hours for a first pass (1 build, 1-2 register round-trip, 2-3 harness, 2-4 case generation, 2-6 triage). One-off, with cheap re-runs and no CI protection against rot.

Sample-program oracle: 1 printed page, J28-6169 PDF p. 217, covering 4 report files, currently named in 0 places in the M4 stage 4 plan.

## Verdict

Worth building, but for different instructions than the ones the task names — roughly one day, one-off, run outside the repository. A differential harness against the Open SIMH i7090 simulator is strongest exactly where our emulator is already well attested (multi-word arithmetic, subtractive indexing, multiple-tag OR, shift counts, minus-zero results) and weakest on the four items the task asked about (ED-2, ED-2a, CVR, and the minus-zero paths), because three of those four are unobservable in our system and the fourth is not actually an interpretation. Two cheaper sources exist and one of them — the printed report output of the sample program, J28-6169 PDF p. 217 — is a genuine end-to-end oracle that the M4 stage 4 plan does not currently name.
