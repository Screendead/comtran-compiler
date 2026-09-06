# Adversarial review of the survey

Two reviewers were asked to attack the provisional conclusion and make the
strongest case for adopting a third-party emulator. Their own text, unedited.


## Reviewer 1

**The conclusion survives against replacement and fails only against the hybrid the research already half-recommended.** Full adoption of a third-party core is dead on four independent grounds, three of which the research did not weight correctly. But the research's central rhetorical move — "SIMH supplies nothing toward the lost runtime, therefore it does not help" — appears in all seven candidate reports and is a non-sequitur every time.

## The two named questions

**Does "the runtime library is lost" rule out adoption? No. It is orthogonal, and its repeated use as a debit is the convenient reasoning in this file.**

The lost SYS)/IOC) runtime costs the same under either CPU. The ~90 Dart compute handlers (M4-17) get written from J28-6169 whether the surrounding instructions are executed by 424 lines of Dart or 4,460 lines of Cornwell's C. That makes the runtime gap a **zero** on the ledger. Every report instead banks it as a mark against the candidate — "it buys you nothing on the milestone you are actually blocked on", "SIMH shortens none of that work", "adopting SIMH would not reduce the M4 stage 4 work by one line". All true, all irrelevant, all deployed as if they were arguments. Strike the runtime gap entirely and the decision rests on CPU-specific merits alone: correctness confidence, integration cost, and governance. That is a materially different question from the one the research answered, and it is the one that has to be answered honestly.

I considered and reject the stronger form of this attack — that the runtime gap actually *favours* adoption because trapping-before-an-address is exotic and SIMH ships it debugged. It is not exotic. Our dispatch is `if (table[m.ic] != null) handler(m); else cpu.step();` over a surface that already exists (`Cpu.step()`, `MachineState.ic`). SIMH's version halts the entire simulator to a console prompt and needs poll-parse-deposit-continue per trap. Neutral, not a credit.

**Is a hybrid possible? Yes, and the research reached the right shape for the wrong-adjacent reason.** But the survivors are all evidence-harvesting, not code-sharing. Nothing that puts foreign code in the execution path or in CI survives.

## The strongest case for adoption, made properly

**The emulator has no independent-implementation oracle and no execution-level oracle at all.** This is the real argument and the research never states it plainly. The 90.05 golden is a *compilation* oracle: it proves the compiler emits the right octal words, byte for byte. Nothing in the repository proves the CPU *executes* those words correctly. The emulator's only checks are 1,412 lines of tests written by the same author, from the same reading of the same manual, in the same sitting. Where A22-6528-4 prints a worked example (Figure 21 for ADD, Figure 26 for the shift flow charts, the seven CVR steps) that is a genuine manual-derived oracle and the tests encode it. Where the manual is silent — every `ED-n` label, seven of them — there is nothing at all.

**And the silence is load-bearing, because decision records read the emulator's own behaviour as their evidence.** `docs/opportunities.md:511-517` admits it in Jack's own framing: "Several decision records read the emulator's behaviour as their own decision — D4.1 on the ACL sign path, the DO record on non-termination, the MOVPAK communication cells." `docs/design/decisions.md:537` is blunter: the ACL sign path "is an inference from 709/7090 instruction semantics, external to both manuals (Open Question 26); neither manual states it". So a compiler decision is justified by the emulator, and the emulator's behaviour there is justified by nothing. That is a closed circle in a repository whose §9 evidence rules exist to prevent exactly this, and which twice corrected itself by measuring a page scan rather than trusting a reading.

The research treats breaking that circle as a *cost* of adoption — each record "would have to become an observation of somebody else's simulator instead". That is backwards on the merits. Cornwell's i7090 has period IBM customer-engineering diagnostic decks run against it in an automated suite with a byte-compared golden log, and has booted CTSS, IBSYS and Lisp 1.5. Our core has one author's reading. Between two circles, the better-informed one wins.

**The cost numbers are also framed to favour the conclusion.** The 42,000-line vendoring figure counts `scp.c` (18,128 lines) and the whole SCP framework, which you need only if you drive SIMH as a program. It is honest for the in-process-FFI shape and is then rhetorically applied to every shape, including the ones that vendor nothing at all.

## What kills it anyway

Four things, in order of weight. The first two are structural, not cost.

**1. The wasm forfeit is real and roadmapped, not speculative.** `dart compile wasm` refuses `dart:ffi` outright ("'dart:ffi' can't be imported when compiling to Wasm"), and `dart:io`'s `Process` is equally unavailable, so both the FFI and the subprocess shape are dead in the browser. `docs/HANDOVER.md:585` names the casualty by name: "Any later browser work inherits this finding, the M4 emulator most of all." This is not a hypothetical — `docs/HANDOVER.md:599` schedules it ("M6 fills the run output") and W4 is "teach and run" with a run button that "waits for M5 and M6". CI runs `dart run tool/build_web.dart` on every push. Adoption trades a roadmapped feature for a correctness second-opinion that a one-time audit delivers without paying it.

**2. The single-authority octal table, which survives even a full replacement.** `lib/src/codegen/procedure.dart:32-33` and `lib/src/codegen/encode.dart:12-13` both import `emulator/decode.dart`; 206 `Op.`/`Instruction.` references live in codegen. `encode.dart:3-9` states the rule: "a second copy of it would be a second authority for the octal codes the OCTAL column prints… the two directions cannot drift." A C core cannot use that table, so it carries its own — a second authority for the same octal digits, on the far side of a language boundary, unverifiable by `test/encode_test.dart`. The byte-exact listing reproduction is what makes this project's central claim credible, and this puts a second opcode table underneath it.

**3. `CLAUDE.md` §11, in bulk.** Vendoring i7090 imports ~160 instructions no COMTRAN program reaches and 68 KB of channel-level I/O that D0.7 exists to avoid — `chan_proc()` is called from inside the instruction loop and cannot be lifted out. Unexercised and untested is the banned quadrant, and this is thousands of lines of it.

**4. Governance, which is binding but not an argument.** D0.3 is Locked and says "our own emulator"; `docs/opportunities.md` records Jack raising this exact option on 2026-08-05 and closes with "**Do not amend D0.3 without Jack's explicit instruction.**" Under §12's one-viable-option rule this is not a decision an agent takes.

Also real, and enough on its own to reject SIMH as the *execution engine* even if the four above vanished: trap density. `test/goldens/90.05-payroll.code` has 67 `TSX` sites into runtime entries among ~771 procedure words, and the hot targets are the move package (SYS)182 ×26, SYS)267 ×25, SYS)180 ×25, SYS)133 ×22) — the body of every COMTRAN loop. A poll-parse-deposit-continue round trip per trap makes the ~90 handlers, which are the actual remaining work, harder to write and far harder to test than against an in-process Dart function call.

## What survives: harvest the evidence, never the code

**The strongest survivor is the one every report undersells — the period diagnostic decks.** `rcornwell/sims/I7000/tests/i7090/` holds ~50 genuine IBM 709/7090 customer-engineering diagnostic decks (`9m03a.dck` is the indexing test). These are **period IBM artifacts**, not a modern author's reading, so under §9 they outrank any simulator and sit alongside the manuals. Two things make them cheaper than the research assumed:

- Diagnostics signal their verdict by *halt address*, and HTR/HPR are not in `decode.dart` — I checked; `axt` (0774) and `tsx` (0074) are harvested, the halts are not. So our `UnimplementedOpcode7090` throw reports the location and hands us the diagnostic's verdict for free, with no subset widening.
- Run each deck until its first throw and harvest only what actually ran. 9M03A exercises subtractive indexing and the multi-tag OR — the corners `emulator.md:65-71` and `:90` describe — before it reaches anything unharvested.

Two guards, both mandatory. **Never widen the subset to make a diagnostic pass**: that is the head-on collision with `docs/opportunities.md:504`, Jack's instruction that "this project does not build a historically accurate 7090 emulator". And the `.dck` files are SIMH's binary card format, not [J 90.03], so a small reader is needed — which lands in §11's "not exercised, tested" quadrant and needs a recorded plan in the design record that asks for it.

**The differential audit the research recommends is the right shape, and the reason is evidentiary, not laziness.** I tried to argue for something better — freeze SIMH-generated (initial state, instruction, final state) vectors into a checked-in Dart golden, pure-Dart CI forever, no C anywhere. It does not hold. Where SIMH agrees with the manual, the manual is the citation and the vector adds nothing. Where they disagree, the page scan decides. Where the manual is silent — precisely the ED-n corners, which is the only place a second opinion was wanted — a SIMH-derived assertion encodes Cornwell's guess as our test, which D0.4 forbids presenting as fact and which is the "observation of somebody else's simulator" that opportunities.md warns against. It collapses back to: run once, triage each disagreement against M p. N, cite the manual, delete the harness. Set `set cpu 7090` explicitly, and filter our ED-4 throws before comparing or the report is noise.

**And the research's own best finding is not a hybrid at all: J28-6169 PDF p. 217.** The manual prints the report the sample program actually produced. That is a behavioural, execution-level oracle on the exact program we already reproduce byte for byte at compile time, and it is the only thing on the table that breaks the D4.1 circularity rather than re-informing it. It is named nowhere in the stage 4 scope. That gap is worth more than the entire emulator-adoption question and should be raised on its own.

One branch killed for completeness: compiling i7090 to WebAssembly with emscripten to save the browser story. The trap boundary would then be JS/wasm while our compiler is Dart/WasmGC, so every trap crosses two runtimes instead of one — strictly worse than the FFI shape it was meant to rescue.


## Reviewer 2

The conclusion survives, but three of the arguments holding it up do not, and the follow-through it recommends is too weak to be worth the analysis that produced it.

## The strongest case for adoption, made properly

**The CPU is the least-evidenced component in a repository that applies an unusually strict evidence standard everywhere else.** `/Users/jacklusher/development/comtran-compiler/CLAUDE.md` §9 makes the page scan ground truth and requires a scan measurement for any card-column claim — a rule that exists because two M1 corrections came only from measuring. `docs/comtran-language-definition.md` may not be corrected against modern expectations. Every unattested emulator choice is supposed to carry an `ED-n` label (`docs/design/emulator.md:9`). Against that standard, 36-bit arithmetic is held to a weaker one than card columns: one reader, one pass through A22-6528-4, and tests written by the same author from the same reading at the same sitting.

**Two in-subset instructions already carry unrecorded readings, and I found them by reading the code rather than the design record.** `lib/src/emulator/cpu.dart:381` implements LAS as `state.acMagnitude > y` — a 37-bit accumulator magnitude compared as a plain integer against a 36-bit storage word. The manual's sentence is "AC(Q,P,1-35) compared with C(Y)(S,1-35)", 37 bits against 36, and the alignment that makes the Dart comparison correct (Y's sign bit against the accumulator's P, the Q bit outranking everything) is an inference from CAL's documented layout, not a stated rule. It carries no `ED-n` label. LAS appears five times in the sample object program. The ACL sign path is the second: `docs/design/decisions.md:537` says plainly that the reading "is an inference from 709/7090 instruction semantics, external to both manuals (Open Question 26); neither manual states it, and the sample exercises no negative value." A third candidate, cheap to check: `cpu.dart` LRS sets the MQ sign from the accumulator sign unconditionally, including at a shift count of zero. Whether the hardware forces the sign on a null shift is exactly the micro-corner a second implementation settles in one run.

**"1179 tests, all green" is self-consistency, not correctness.** The 1,614 lines under `test/emulator/` encode the implementation's interpretation of the manual, because the same person wrote both from the same reading. They will catch a typo. They cannot catch a misreading, which is the failure mode that matters here and the one this repository has already been burned by twice. The research treats green tests as a correctness posture and compares them favourably to a third-party core "with no test suite" — but Richard Cornwell's `i7090` ships 51 genuine IBM customer-engineering diagnostic decks under `I7000/tests/i7090/` with a byte-compared golden log that `make i7090` runs. On any honest ranking of oracle provenance, period IBM CE diagnostics outrank self-authored unit tests written yesterday. The research found this and filed it under "oracle only" without letting it move the assessment.

**A reviewer in five years asks one question: how do you know the CPU is right?** Today the answer is "we read the manual carefully." That answer is weaker than every other answer this project gives about every other component, and it is weakest precisely where a freely-licensed, period-diagnostic-validated second implementation exists and was considered and set aside.

## Three pieces of reasoning that do not survive

**D0.3's locked status is used as engineering evidence, and it is not.** Nearly every candidate profile closes on it. A lock says who decides, not which choice is better, and Jack opened this exact option himself on 2026-08-05 — `docs/opportunities.md:511` records it as live and awaiting his instruction. Citing the lock in an analysis commissioned to inform whether the lock should be lifted is circular.

**Line counts are used as a validation argument.** "889 lines of ours versus 2,481 lines of theirs" says nothing about which reads the manual correctly. Smaller is a maintenance virtue, not an evidence one.

**"Pure Dart repository with a three-command gate" is overstated.** `.github/workflows/vscode-ext.yml` is already a second toolchain with its own npm gate. The argument has real force about the compiler's own CI gate and none about the repository as a whole.

## What actually defeats replacement

**Embedding the simulator forfeits the validation that was the only reason to adopt it.** This is the crux, and no profile states it. Cornwell's diagnostic decks validate the whole binary: they load through the card reader, run through `i7090_chan.c`, and are compared against a checked-in golden log. `sim_instr` cannot be lifted out — it calls `chan_proc()` from inside the instruction loop and decrements SCP's `sim_interval`. Stub those to build a shared library and the decks can no longer run against what you shipped; you now hold a new, untested artifact whose pedigree you are still citing. Keep the binary intact and it is a subprocess: a text round trip per runtime-entry trap, and each handler's internal memory read a further round trip, against a program whose static density is one `TSX` into a SYS)/IOC) entry every ~11.5 procedure words. So: embed it and lose the validation, or keep the validation and it cannot be the production CPU. The obvious escape — keep both and diff them — reproduces exactly today's situation, with C nobody here wrote standing in for Dart that someone did.

**It forfeits a stated future, not a present capability.** `dart compile wasm` rejects `dart:ffi`; `ci.yml:35` builds the web target and `pages.yml` deploys it. `cpu.dart` is not in the web closure today, so nothing breaks now — but `docs/HANDOVER.md:585` names the ambition explicitly: "Any later browser work inherits this finding, the M4 emulator most of all." Running a 1962 payroll object deck in a browser is not available through a subprocess or an FFI binding, ever.

**Maintenance genuinely favours the Dart core, and I am not manufacturing a disagreement here.** The subset is bounded by the compiler's own output and grows one opcode at a time (`docs/design/emulator.md:242`). There is no upstream, no platform matrix, no pinned tree, no carried patch. The C alternative is frozen upstream — Supnik's last semantic CPU change was 2011, Cornwell's 2024 — which means low churn and nobody to fix a bug you report. Over five years, 424 lines of Dart nobody needs to touch costs less than a vendored tree, a build hook, per-platform artifacts and an FFI shim.

One middle option, considered and rejected: transliterate `i7090_cpu.c`'s fixed-point paths into Dart. It inverts the repository's evidence ranking by putting an implementation above the manual, and the diagnostic validation does not survive a rewrite anyway.

## Where the "keep ours" side is itself convenient

**The oracle-only verdict misreads two rules to justify the weakest possible commitment.** It concludes the harness must live in the scratchpad, never enter the repository, and be run twice — citing §11 as banning a `tool/` script outright and §9 as barring the simulator. Both readings are wrong. §11's own table permits exercised-but-untested code, and a developer running a tool is a normal run of a tool. §9 bars the simulator as ground truth, not as a question generator whose every finding is re-derived from the manual page before anything enters a test. An offline harness that runs twice decays to zero the first time M4-17 widens the subset — and widening is expected and additive by design.

**Two changes make the analysis worth what it cost.** First, the differential harness belongs in `tool/`, checked in and pinned, run on demand at each subset widening — not in the CI gate, where the pure-Dart argument does hold. Second, `J28-6169` PDF p. 217, the printed report the sample program actually produced, belongs in the M4 plan by name. It is a period end-to-end behavioural oracle on the exact program already reproduced byte for byte at compile time, it outranks any simulator under this repository's own evidence ranking, and `docs/HANDOVER.md:88-91` does not mention it. It lands after the IOCS-level I/O handlers, which is precisely why the harness is still needed for stage 4's gap.

**Verdict: keep the Dart core.** Not because it is small, not because the tests are green, and not because D0.3 is locked — but because the validation you would be adopting cannot be embedded without being destroyed, and the browser target cannot survive FFI. Fix the reasoning, fix the follow-through, and stop citing the lock.
