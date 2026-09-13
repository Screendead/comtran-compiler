# Brief for the stage 3 review record — 2026-09-13-m5s3-file-design

Directory: `reviews/2026-09-13-m5s3-file-design/`. Branch: `review/2026-09-13-m5s3-file-design`.
Title: "M5 stage 3, FILE: the design and the delivery plan". Date of the evidence: 2026-09-13.
Every repository link points at commit RECORD_HEAD (set at build time; a commit on branch m5s3-file).

Status of every item: DECIDED or SETTLED. No item waits for Jack. Silence lets each stand; he can overturn any one.
The record was built after the design entries were written and the code landed, in one autonomous run while Jack slept. Say that plainly in the opening block: this is the section 12 one-viable-option route, and the record is the explanation of decisions made, not a question.

## Opening block (numbered, short)

1. IOC)9 is the IOCS WRITE routine word for word: two parameter words, an unopened file is a NOP (attested, J 02.07.08), a record that does not fit the block writes the block first (D6.7), a record longer than BLOCKSIZE ends the run with a fault. DECIDED.
2. Every file now takes one BLOCKSIZE buffer above the program, in *FILE card order; close-all writes the last block, then the tape mark. DECIDED.
3. The lister prints a BCD tape as the 1962 off-line printer did: one block per line, a record mark splits a line, the carriage-control character prints, trailing blanks trimmed; `comtranc --run --list-tapes` prints each BCD output file under a `NAME REPORT` heading. DECIDED.
4. The end-of-buffer gap: the sample's FILE sequence passes EOB zero, which under the published IOCS manual splits a record; J's own worked example keeps records whole. Recorded as sealed until M7, not raised as a collision. SETTLED.
5. What stage 3 does not build (BEGIN, SPANS, the card-file terminators SYS)291 and SYS)296, direct printer output), the five Cowork advisories from PR #130 folded in, and the delivery plan (one pull request on `m5s3-file`, merges on external-review convergence). SETTLED.

## Item 1 — IOC)9, the WRITE subroutine (DECIDED)

Evidence first:
- Plate: the manual's own FILE sequence (J 90.02.33 shows `TSX IOC)9,4 / PZE FILENAME,,SYS)291 / IOCDN* *+1,,24` for the card form) and the sample's tape form from the object golden, `test/goldens/90.05-payroll.code` lines 606–611 (`LXA BL)2,4 / SXA GN)089,4 / TSX IOC)9,4 / PZE OUTPUTMASTER,,0 / GN)089 IOST MASTER,,15`) and 167–169 (`TSX IOC)9,4 / PZE ERRORFILE,,0 / IOST ERROROUT,,4`).
- Crop `iocs-p16-write.png`: C28-6100-2 printed p. 16, the WRITE sequence `TSX WRITE,4 / PZE FILE,,EOB / IOxY A,,m`. Our `PZE FILE,,0` and `IOST record,,words` are that sequence with one command. (external)
- Quote J 02.07.08 §2b: "If a file has not been OPENed or has been CLOSEd when a FILE command is encountered at execution time, the command acts as a NOP. No error message is given."
- Quote J 90.02.08: "IOC)9 The entry point to the IOCS WRITE subroutine."
- Crop `j-90-05-04-payfile-blocking.png`: "The shorter records, DEPARTMENT.TOTAL, will be written with proper length, and will always begin a new buffer. If this short record was only 10 words long, it would be necessary to specify BEGIN in the File Card to avoid grouping of the short records."

The decision (m5-io.md M5-9), rules in order:
1. file not open → resume three words on, nothing written (J 02.07.08).
2. extent > BLOCKSIZE → a RunFault that names the file. The sequence carries no exit for it (the decrement of word 1 is zero at every tape site; SYS)291/296 are card-file exits with no emitter). The compiler never draws message 209, so a compiled program can reach the rule.
3. unused words in the block < extent → write the block as one frame, empty it (D6.7; J 02.07.09–10 Example 1; J 90.05.04).
4. copy extent words from the IOST address into the block; resume(3). A block filled exactly waits for the next FILE or the close.
Index register 4 survives; XR1, XR2 and AC untouched (IOCS leaves a history word in AC at every WRITE exit, C28-6100-2 printed p. 17; no compiled word reads it).
The order of rules 2 and 3 matters: testing the fit first on an empty block would write a zero-length frame, which in our format is a tape mark, and then overrun the buffer into the next file's.

Options rejected, with consequences:
- Split a record across blocks as IOCS's own EOB-zero rule says (C28-6100-2 printed p. 16). Contradicts D6.7 (locked) and J's own worked example; the DEPARTMENT.TOTAL records would not "always begin a new buffer"; the printed report would differ from p. 217 wherever a block boundary fell inside a record. Reversal cost: one branch in IOC)9 and a lister that joins split records.
- Truncate a too-long record silently. Prints a wrong report with no message. Reversal cost: nil, but the wrong report is the cost.
- An IOCS-style error exit for the too-long record. The sequence has no field for it; inventing one changes the attested object text.
- Read a base locator inside IOC)9 for a located record. The CPU already patches the IOST word through the LXA/SXA pair the generator emits (statement 208); a second path would duplicate it and could disagree.

Recommendation: as decided. Overturn cost: the four rules are one function in `lib/src/runtime/iocs.dart`; the tests in `test/runtime/iocs_test.dart` pin each rule, including D6.7's oracle from J's Example 1 (REC1 64 / REC2 128 / REC3 192, BLOCKSIZE 256).

## Item 2 — one buffer per file above the program; close writes the last block (DECIDED)

Evidence: stage 2's M5-7 and the J 03.03.01 core chart (the stage 2 record's crop; cite the stage 2 record by its branch and commit 6492c9a rather than re-embedding). M5-7's own first rule said "An output file takes no buffer. Nothing reads one before stage 3 (CLAUDE.md section 11)." Stage 3 is the reader.

Decision (M5-10): every file takes BLOCKSIZE words above the extent in *FILE card order; the sample's seven buffers take 655 words from 5114 up; DETAILFILE's buffer moves from 5414 to 5714. NoBlocksize and NoBufferRoom now cover every file. The block is the first `fill` words of the buffer; IOC)9 writes a full block, close-all writes the held block then the tape mark; an empty block writes nothing anywhere (a zero-length frame is a tape mark, M5-2). With no host image every write is dropped, so a run with no --tapes and no input file still opens, closes and writes nothing (M5-3 as amended). The library owns the one frame encoder; one test pins its bytes; the test support calls it.

Options rejected:
- Hold an output block in Dart, outside core. Nothing in the program reads an output buffer, so it is unobservable — but it makes two rules where one serves, and it departs from the J 03.03.01 chart that stage 2 rested its placement on. Reversal cost: small; nothing observable changes.
- Output buffers at a fixed area per file below the program, or at the top of core. Rejected at stage 2 for the same reasons (M5-7).
- Keep the input-only rule and add a separate output-buffer allocator. Two allocators for one idea.

Overturn cost: one conditional in `_fileTable` and the two address assertions in `test/runtime/machine_test.dart`.

## Item 3 — the lister and `--list-tapes` (DECIDED)

Evidence first:
- Crop `j-90-05-report-checkfile.png`: PDF p. 217, the CHECKFILE report. The lines read `110-06-61` and `2WILLIAMS P`: the carriage-control characters that words 1 and 8 of the CHECK record carry (J 90.05.03: "Word 1 — carriage control character; 2 characters for MONTH; ..."; "Word 8 — last 3 characters of EMPLOYEE.NUMBER; record mark; carriage control character; first character of NAME") were printed as text.
- Quote D6.4: "One record is one or more print lines. RCDMRK-type one-character record marks delimit the lines inside a record." and "Line length and carriage behavior beyond that come from the emulator's printer device, not from the language."
- Quote J 90.05.03: "The two check lines are grouped in one record, separated by a record mark (signalled by type RCDMRK) for printer control."
- Show what would mislead: the same crop shows `091977` on the print line above `110-06-61`, and the conversion note on p. 217 says the printer carried the last fields of a line on the position above. That stagger is the 1962 printer's, not the record's; the lister prints the record's line as one line, and M6 decides how to diff the stagger.

Decision (M5-11): one block = one print line; a record mark (BCD octal 72) ends a line and is not printed; every other character prints, column 1 included; trailing blanks trimmed; a code with no Set H glyph prints `?`; the list runs to the file mark; an image with no mark lists its whole frames and then the reader's fault ends the list (the lister yields lazily); a mode-B (binary) file is not listed. `comtranc --run --list-tapes` prints, after the display lines, each output file in *FILE card order: `NAME REPORT`, a blank line, the lines; one blank line between files. The flag needs --run and --tapes.

Options rejected:
- Consume column 1 as carriage control and emulate skips (blank lines for channel 1/2). Fails the p. 217 diff, which printed the characters; adds a printer model D6.4 says belongs to the emulator's device, which the sample never assigns (no PRX/OU unit). Reversal cost: one flag on the lister.
- Keep trailing blanks. Invisible on paper; makes every diff noisy. Reversal: trimRight removed.
- A separate executable or a deckconv subcommand for the lister. A new binary and a pubspec entry for one function; deckconv is the card-deck tool. Reversal: move one call.
- Throw on an image with no file mark and list nothing. Loses the lines a crashed run did write — the lines a debugging reader wants.

Overturn cost: the lister is one generator function in `lib/src/runtime/tape.dart` and its tests.

## Item 4 — the end-of-buffer gap (SETTLED)

Crop `iocs-p16-eob.png`: C28-6100-2 printed p. 16, rule 3: "If EOB = 0, truncation of the buffer and automatic transition to the next one occur; command execution continues without interruption." The sample's word 1 decrement is zero at every FILE site. Under that sentence IOCS proper would split a record across two blocks. D6.7 keeps a record whole and cites J's own Example 1 (block J+1 = REC1+REC2 only, 192 of 256 words, because REC3 does not fit); J 90.05.04 says the short records always begin a new buffer. J governs its own blocking; the IOCS text is delegated detail (J 90.02.08: "A knowledge of the 7090 IOCS is necessary"). How IOC)9 reconciled the two is inside the sealed 1963 source (D0.9). Recorded in M5-9 as an open item, not a peer collision: the rank table puts the manuals above external evidence for what J itself states. Nothing to decide; the seal ends at M7.

## Item 5 — what stage 3 does not build, the folded advisories, the delivery plan (SETTLED)

Not built, and why (CLAUDE.md section 11): BEGIN (no sample FILE card carries it), SPANS (Open Question 48), SYS)291 and SYS)296 (card-file exits, no emitter), direct printer output (no PRX/OU unit in the sample), the close dispositions of D6.3 (one close code on every sample card). Message texts: none new; the too-long-record fault is a RunFault like the stage 1 and 2 refusals, not a 90.04 diagnostic.

The five advisories Cowork left on PR #130 are taken here: (1) the HANDOVER test baseline re-measured; (2) "ordinal" for the block number in M5-8, and the two metaphors at the end of M5-7, reworded; (3) the Machine constructor's doc comment on a run with no tapes directory now says it holds for an output file only; (4) M5-8 gains the sentence that after the error exit the run ends, so the reader's position inside a bad frame is never read again; (5) machine_test.dart's comment cites statement 196, not 193.

Delivery: one pull request, branch `m5s3-file`, "Write the object program's records (M5 stage 3)". It changes `lib/`, so it merges on external-review convergence (CLAUDE.md section 12). Opening it is under Jack's standing authorization of 2026-08-16. Under the Cowork nits, the PR also re-enters the loop for the doc-comment and message changes.

Provenance line for the opening block: the design entries were written first (m5-io.md M5-9 to M5-11, D6.4 and D6.7 amendment lines), the code was implemented against them by a worker, and this record was built from both, in the same autonomous run. No review document existed before the code; that is the standing rule's route, and the record says so.
