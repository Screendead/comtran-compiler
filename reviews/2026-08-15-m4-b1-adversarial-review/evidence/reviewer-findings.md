# The adversarial reviewer's report, verbatim

An independent agent with fresh context reviewed commit c077c28 (chunk
B1) against the repository on 2026-08-15, reading the diff and the
repository only, never the author's plan or rationale. Its final report
follows, unedited.

---

Review of c077c28 (m4s2-chunk-b1) complete. Five findings survived verification; the commit's three headline claims (spine passes, goldens hold, record under budget) all check out empirically.

**Verification:** `dart test test/object_spine_test.dart` passes; `dart analyze --fatal-infos` clean; the full suite passes 1024/1024; `wc -w docs/design/m4-codegen.md` = 9,994 (six words under the 10,000 budget); the sample deck compiles (exit 0); the stage-1 storage-map rows sit unchanged inside the new golden (0 changed rows); Jack's rulings cited by the amendments exist in the orphan review-record chain (6cfde74 → 7add767 → 1238337), and the result-storage ruling there — "3, 2 and 3 cells, the 7-cell tail as one undivided block, 30 words" — matches `resultStorageWords = 2 * (3 + 2 + 3 + 7)`.

---

**1. BLOCKER — an unruled clause crashes the compiler and kills the whole deck; the test that would have caught it was edited away, and no test covers any of the ~25 throw sites.**

`lib/src/codegen/procedure.dart:83-84`: `Never _unruled(String what) => throw StateError('no attested shape: $what ...)` — ~25 call sites (DISPLAY, assigned GO TO, SET of a condition name, subscripted moves, ADD of a literal, …), all reachable from semantically valid source. Reproduced: a deck with `DISPLAY 'HI'.` compiles cleanly at the parent (`jobs=1 maxSeverity=0`) and at c077c28 dies with `Unhandled exception: Bad state: no attested shape: DISPLAY` out of `compileDeck` — nothing between `lib/src/driver/driver.dart:121` and `bin/comtranc.dart:235` catches it, so one unruled clause in job 1 starves every later job, the exact invariant driver_test elsewhere asserts ("a severity-5 job never starves the next job (J 90.04.02)").

Two texts overclaim it away. `lib/src/codegen/codegen.dart:60-67`: "It sizes and places units from facts the semantic layer already validated… no input can enter a `catch`, so D10.2's stop shape would be unreachable code" — false; `_unruled` *is* error detection on validated input, and M4-2 as amended (`docs/design/m4-codegen.md:129-131`) says "The stop shape… binds stage 2, whose verb generators are the first code here that can detect an error; it arrives with them, sink and all" — B1 is that code, and the sink did not arrive. `test/driver_test.dart:28-30` replaced the DISPLAY input with `STOP 7.` under the comment "codegen… refuses to invent one" — "refuses" is a euphemism for an unhandled StateError. No test asserts the throw, so every `_unruled` branch is neither exercised nor tested (CLAUDE.md §11; REVIEW.md blocker list).

**2. BLOCKER (§11) — unread field.** `lib/src/codegen/procedure.dart:50` `final int entry;`, set at :254 (`entry: _origin`). No reader anywhere: `runCodegen` reads `units`/`words`/`poolWords` and rebuilds the START location from `dataWords` itself (codegen.dart:97); no test reads it. One-line deletion.

**3. HIGH — the register-cache elision rule sizes ~20 guard sites and no design record carries it.** `procedure.dart:291-302` (`_loadBase`): "A register already holding it is reused with no words" — this decides whether 2 words are emitted, twenty times, so the spine depends on it. M4-9's record text (m4-codegen.md ~560-568) carries the guard and register assignment only; the composite kill rule (register-1 write at statement distance, deferred inside a CORRESPONDING expansion) lives in a fixture addendum — `test/fixtures/90.05-object-code-notes.md`: "lib/src/codegen/procedure.dart carries the composite the oracle confirmed" — while that same file declares "This file changes no design record… The parent routes them" (notes §8). Under §6, the record binds the code; here the code and a fixture bind themselves. The 9,994/10,000 budget is visibly why the rule got routed to the notes.

**4. MEDIUM — the `(M4-6)` citations claim an authority the entry does not hold, and its own amendment demand is unmet.** `procedure.dart:653` "The first name of the run is never bound (M4-6)" (also :656, :736, :907) cite M4-6 for positional skip rules, but M4-6 still reads "Working rule (ours, provisional)… whichever mapping reproduces 084–093 exactly amends this entry with the rule and the evidence" — unamended. The mapping is in fact correct: I compared the label field of all 977 content lines of the golden against the scan-verified target — 0 mismatches — but no committed test does this (the spine test strips labels; the goldens are self-generated). Cheap fix: extend `_spineField` to the label zone, which also converts my one-off check into the durable oracle.

**5. LOW — STOP n pools no statement stamp, against M4-14's own words.** `procedure.dart:588-589`: `words(3); // STOP n: the SYS)178 call alone` with no `_stamp` call, while M4-14 as amended says the stamp is a pool pair and "SYS)178's parameters carry it" — STOP n emits the SYS)178 call. Word count (3) is unaffected; the pool count would differ for a STOP n program. Caveat: notes §7 lists `STOP <n>` as unexercised, so no site attests either way.

**Advisory nits:** (a) codegen.dart:97 `semantics.areas.isEmpty ? 0 : dataWords` — both arms identical (the fold over empty areas is 0); the condition decides nothing. (b) The notes' Question 2 still ends "**The question is open.**" directly above the 2026-08-15 addendum that settles it. (c) The spine oracle's offset check is extraction-based (`_offsetDigits.stringMatch`), so it cannot see offset alignment; I verified the raw offset-zone bytes (cols 34–49) match the target on every offset-carrying line — 0 mismatches — but only the self-generated golden locks those bytes in a test.

One housekeeping note: an untracked `REPO-REVIEW.md` sits on master; I did not create it and left it alone.
