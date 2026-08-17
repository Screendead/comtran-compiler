# M4 — Core-verb code generation design and decisions

*Drafted 2026-08-05. This document records the M4-specific design decisions
the way `m3-data.md` records M3's. The language facts come from
`docs/comtran-language-definition.md` (cited by §), the manuals (cited as
`(F p. N)` / `(J xx.xx.xx)`), and the locked decision slate
(`docs/design/decisions.md`, cited as D-numbers). This document adds no
language claims; where the sources leave a code-shape gap, the entry below
closes it and says so. Every unattested choice is labeled ours and is
amendable by an explicit edit.*

*Entry IDs are append-only. A new entry takes the next free number and goes in
the section it belongs to, and the section headings below are the index. The
code cites these IDs, so no entry is ever renumbered.*

## Charter

M4 turns a fully resolved program (M3's `SemanticResult`) into the 1962
object program: the assembly text, the printed object listing, the object
deck, and the loader cards. The oracle is the 90.05 compilation listing,
PDF pp. 198–216 — the loader-card page, the storage map, and the symbolic
listing — diffed byte for byte (D0.3). M4 also hardens the emulator into a
machine: a loader places the deck in core, and a dispatch layer runs the
SYS)/IOC) handlers the core verbs call. The 90.05 sample itself first
runs at M6, the acceptance milestone, after M5 lands the IOCS handlers;
M4 executes I/O-free programs.

## Scope and stages

- **M4-1. Full text emission, staged.** M4 generates object text for the
  whole procedure division, not the core verbs alone. The reason is the
  oracle: the listing's addresses are continuous, so omitting one GET's six
  words would shift every address after it. The core verbs (MOVE, SET, IF,
  WHEN, GO TO, DO, STOP) get their full semantics; the I/O verbs (OPEN,
  CLOSE, GET, FILE) get their attested calling-sequence shapes only (M4-15),
  and their runtime lands at M5. Four stages, one pull request each, each
  green alone:
  1. **The assembly model** — the text model (M4-3), the program image
     (M4-4), the storage-map print (M4-7), and `--emit-code`.
  2. **Core-verb text** — the verb generators (M4-9 to M4-15), the
     generated-name pass (M4-6), and the symbolic listing pages (M4-8).
  3. **The object deck and loader cards** — the 90.03 text encoding, the
     *FILE/*SPEC/*CTEXT/*CTEND cards, `--emit-deck`, `--emit-loader`, and
     our loader (M4-16).
  4. **The machine assembly** — the runtime dispatch layer and the compute
     handlers (M4-17), and execution tests for I/O-free programs.

  The Oracles section at the end of this record holds each stage's oracle.

  **Amended 2026-08-09, stage 2 (Jack's call). Stage 2 is not one pull
  request.** Its oracle needs a blind pass over nineteen page scans, too
  much to put at risk in one pull request, so stage 2 splits into
  chunks. Each chunk is green alone, and each is worth merging alone.
  Stages 1, 3, and 4 do not change.

  Phase A built the target listing before any generator ran: listing
  pages 8 to 25, PDF pp. 199 to 216, scan-verified. Page 7, PDF p. 198,
  carries the loader control cards on no LOC/OCTAL/CNTRL grid; stage 3
  generates that page and takes it as its own oracle.

  Phase B generates, and it sizes before it fills:

  | Chunk | What it delivers |
  |---|---|
  | B1 | The address spine — the word count of every verb shape (the [J 90.02] calling sequences, the M4-15 I/O shapes included), the constant-pool allocator, the `RS)` cell scheme, `TS)`'s constant 7 (M4-4 as amended), and the later-pass names GN)084 on (M4-6). |
  | B2 | MOVE (M4-9). |
  | B3 | SET and arithmetic (M4-10). |
  | B4 | IF and WHEN (M4-11). |
  | B5 | GO TO and DO (M4-12, M4-13). |
  | B6 | STOP with the statement stamps (M4-14), and the I/O shapes (M4-15). |
  | B7 | The close-out — the `USE 1` and `BGN 2,PI)1` head rows, the four block sizes, the constant pool, the page furniture, and the full listing diff. |
  | B8 | The diagnostics — msg 942 widened (M4-5), ids 946 and 947 reserved (M4-18), and the D10.2 stop shape M4-2 defers to here. |

## Pipeline position and the text model

- **M4-2. A separate phase over `SemanticResult`.** The code generator is
  `runCodegen(SemanticResult) → CodegenResult` in a new `lib/src/codegen/`
  component. `bin/comtranc.dart` becomes deck → `runFrontEnd` → `runParser`
  → `runSemantics` → `runCodegen` → `writeListing`, per job. `runCodegen`
  follows D10.2 exactly: it catches `StopCompilation` itself, returns a
  partial result with a `stopped` flag, and the driver skips it when an
  earlier phase stopped.
  **Amended 2026-08-05 and 2026-08-15, stages 1 and 2.** Stage 1 built
  the map from validated semantic facts and could detect no error, so
  under CLAUDE.md section 11, which outranks this record, it shipped
  without the stop shape. The phase takes no diagnostic sink; the
  sink arrives at chunk B8
  with the first program error this phase can detect. The stage 2
  refusals are not that error: a valid shape the sample never attests
  fails in the recovery, not in the program — no [J 90.04] message
  covers it — so the refusal bypasses the sink. The generator throws
  `UnrecoveredShape`, the driver scopes it to the job, and later jobs
  compile ([J 90.04.02]).
  The phase re-resolves nothing: data references
  come from `dataResolutions`, CORRESPONDING pairs from
  `correspondingPairs`, storage facts from `ItemSemantics`, initial words
  from `AreaInfo.words`, and label words from the M3 allocator. It
  generates no code from a node flagged `recovered` (M2-5; D4.10), from a
  deleted sentence, or from a sentence in `capacityDeletedSentences`
  (M3-20); those units keep their statement numbers and emit nothing.
  The exit code keeps D11.2's meaning, and the D11.4 invariant holds:
  `--pedantic` adds diagnostics and changes nothing else.
- **M4-3. The text model is the 1962 symbolic form (ours).** The
  intermediate form is a typed list of assembly units: label(s), operation,
  tag, and an address expression over the program's symbols, one unit per
  object word or pseudo-operation. The vocabulary is the listing's
  SYMBOLIC column ([J 90.02.02]: "a 'SAP'-like listing with a few
  modifications") plus two forms only the [J 90.02] calling sequences
  attest (MZE, [J 90.02.06]; MON, [J 90.02.15]): the harvested
  instruction mnemonics, the pseudo-operations BSS, OCT, ORG, USE, EQU,
  BGN, PZE, MZE, MON, IOST, and
  the GET descriptor word `IOCTN*` (the listing's spelling; M4-20
  item f). No modern
  intermediate form is invented; `emit-stages.md` bars one without a design
  record, and this entry is that record — the decision is to have none.
  Assembly then binds symbols to locations and renders each unit three
  ways, from one source of truth: the 36-bit object word plus its 5-bit
  control group (the deck, M4-16), the printed OCTAL and CNTRL columns
  (the listing, M4-8), and the memory image (the loader, M4-17). [J 90.03.03]
  states the identity this design rests on: the text deck "corresponds
  exactly to that shown on the assembly listing under the columns 'OCTAL'
  and 'CNTRL'".

## The program image

- **M4-4. Location counters and the address model.** The compiler uses
  three pseudo location counters ([J 90.02.01]), and the LOC column prints
  displacements from the first word of the object program:
  - **Location Counter 0** — in-line text: first the transmitted data
    areas, in source order at M3-6's offsets (the sample: `*DATA BSS 0` at
    00000 through TABLE's last word at 00164), then the procedure text
    continuing on the same counter (GN)000/START at 00165 through the last
    generated word).
  - **Location Counter 1** — begins where counter 0 ends: out-of-line
    routines and the working-storage blocks, reserved in the attested
    order `RS)`, `TS)`, `BL)`, `PI)`, then the constant pool `CP)`
    ([J 90.02.03]–06; the sample: RS 30 words at 01621, TS 7, BL 3, PI 3,
    CP at 01674).
  - **Location Counter 2** — pointer-word initialization: an `ORG` to the
    pointer block and the pre-determined constants (the sample: `ORG BL)1`,
    then `PZE IOC)29 / PZE 0 / PZE 0`). Its `USE 2` word prints `MON PI)1`:
    counter 2 holds only the `BL)` block, so its end is `PI)`'s origin —
    two readings, one value (B7).
  Block sizing rules: `RS)` is the sum over sections of the maximum result
  storage each section uses ([J 90.02.03]) — cells two words each, D4.8's
  inference from the listing's LOC values, not stated by J;
  `BL)` is one word per base locator — BL)1 for the IOCS label area, one
  per located-record buffer pointer (M3-11); `PI)` is one word per
  positional indicator (M3-20's counter).
  **Amended 2026-08-05, stage 1 (Jack's call).** Stage 1 derives `BL)`
  alone — the sample's attested 3 — and leaves each other size to the
  stage that can derive it.
  **Amended 2026-08-10, chunk B1. `TS)` takes the attested 7 as a
  constant, and no rule is invented for it. Jack's call.** The 2026-08-05
  amendment left the size "to the stage that can derive it". No stage
  can: a hunt over both manuals refuted seven readings and left two that
  one sample cannot separate, and `docs/HANDOVER.md` holds it. No word
  of the object program addresses any of the seven cells, so demand-driven
  sizing would have printed `TS) BSS 0`; over-reservation is this
  compiler's habit instead. Both surviving readings return 7, and either
  presents a guess as a derivation and then sizes every other program
  confidently and wrongly. **Do not implement either, or any other rule
  returning 7.** For any program but the sample our size is therefore
  unverifiable, and that is stated rather than hidden. One artifact
  overturns this entry: the storage map of a second compiled listing.
  **Amended 2026-08-15, chunk B1. `RS)` takes the attested reservation
  as constants of the sample. Jack's ruling, the chunk B1 review
  record.** [J 90.02.03] needs each section's maximum, and the maximum
  is unrecoverable: sections 0 to 2 reserve 3, 2 and 3 cells while
  referencing 2, 1 and 1. Two decoders refuted every constant-free
  rule. The unobservable tail admits contradictory splits. The constants:
  3, 2 and 3 cells, then a 7-cell undivided tail, 30 words. The `TS)`
  findings above apply in full.
  **Amended 2026-08-05, the block order is frozen.** Jack's call: the
  order is load-bearing, so the `StorageBlock` declaration is frozen.
  Two facts support it. First, the three addresses above do not in fact
  pin the order. `originOf` sums every block declared before the one it
  is asked for, and addition hides a swap among them, so `BL)1` lands at
  01666 whether `RS)` or `TS)` is declared first. Second, the storage map
  does pin every block, because it prints a LOC against each
  reservation: `RS)` at 01621, `TS)` at 01657, `BL)` at 01666, `PI)` at
  01671, and the pool at 01674. `test/codegen_test.dart` asserts all
  five origins, so a reordering fails a test instead of silently moving
  addresses. Add a block only at a position the listing attests.
  The constant pool allocates in first-need order during generation, one
  entry per distinct constant as written — a literal keys on its OCT
  word, a pointer or descriptor word on its symbolic operand, never on
  the assembled bits — references printed `CP)+NN` (D8.8). The attested
  pool, 62 entries at LOC 01674–01771, is the conformance check, and
  D4.1 pins CP)+24 and CP)+31 to CP)+34 by index.
  **Amended 2026-08-11, chunk B1. The pool is not in first-need order.**
  Statement 188, the first statement the compiler generates, references
  `CP)+40`, `CP)+14` and `CP)+15`; first-need allocation gives its first
  constant `CP)+0`. The pool is four sub-pools, concatenated in one
  layout pass: literals, machine words, subscript bases, descriptors.
  Only the last three fill in first-need order, and the literals fill in
  source order. Three consequences bind the generator:
  - It emits a reference as a sub-pool and a key, and a layout pass
    assigns every `CP)+NN`. An entry's index counts every entry of the
    sub-pools ahead of it, and the machine-word sub-pool is complete only
    when the text ends: `CP)+37`, the first subscript base, takes that
    index because the literals hold 14 and the machine words 23. No
    generator can number an entry as it mints it.
  - A literal or machine word keys on its 36-bit value, and a pointer or
    descriptor on its printed symbolic operand. The value key corrects
    "as written" above: statement 205 writes `ZERO`, statement 215
    writes `0`, and both take `CP)+0`.
  - The sub-pool is part of the key. No two sub-pools share a word in
    the sample, so the print never had to decide; the layout forces it.

  `test/fixtures/90.05-object-code-notes.md` holds the 62 entries, the
  evidence for each sub-pool's own order, and the two entries that rest
  on the print alone.
  **The dictionary LOC column and the object LOC column are different
  address spaces.** The listing's source-page column prints compile-time
  dictionary addresses (base 71175, M3-8); the object pages print object
  displacements from zero. Nothing relates them, and no reconciliation is
  attempted.

## Generated names and msg 942

- **M4-5. The eight classes, one tally.** Compiler-generated names take
  the eight classes of [J 90.02.03]: RS, TS, BL, PI, CP, GN, SYS, IOC, in
  the form `SYM)NNN` (constants `CP)+NN`, D8.8). M3-21's obligation lands
  here: [J 90.01.05] item a) counts "all program names whether defined by
  the programmer or generated by the Compiler" in one 3500-name table, so
  the msg 942 counter takes programmer names plus all eight generated
  classes, firing at the 3501st combined entry. Implementation: one
  combined tally that the resolver's `_enter` and every codegen minting
  site feed; the M3 allocator's separate GN counter folds into it.
  A SYS) or IOC) reference counts once per distinct number referenced, not
  per use (ours; the table is a name dictionary).
- **M4-6. The later-pass GN numbers (GN)084 on).** M3-23 allocates the
  source-order labels through GN)083 and hands the rest to M4: the
  generated-label counter continues from 084 in a later pass, in source
  order over the generated text, and **the counter is not dense in the
  print** — the sample prints 085, 086, 088, 089, 091, 093 and never
  prints 084, 087, 090, 092. The attested assignments: GN)085
  `EQU SEARCH+1`, GN)086 and GN)088 `EQU CP)+37` for statement 206's
  `DO SEARCH FOR`; GN)089 on the `IOST` word FILE MASTER patches at run
  time; GN)091 `EQU CP)+38` and GN)093 `EQU CP)+39` for the RETPREM (POS)
  and INSPREM (POS) subscript bases.
  **Amended 2026-08-11, chunk B1. The provisional gap mechanism is
  refuted; the headline stands.** The first working rule (cut, spent)
  read the unprinted names as bound but unprinted; the printer hides
  none — two names on one word print on two lines, at LOC 01217 and
  01472 — so an unprinted name was never bound. The pass walks the
  text in ascending object address and gives each machinery site one
  contiguous run; the per-site runs and bindings are in
  `test/fixtures/90.05-object-code-notes.md`. That reproduces the
  print exactly and it is **fitted, not derived**: three sites cannot
  fix four run lengths, and the roles of 084 and 087 are a guess. The
  notes hold the second grouping the print cannot separate.
  **Amended 2026-08-15, chunk B1, three fitted placements**: the
  table-base EQU heads the DO FOR block, the body-entry EQU stands
  before the prologue's last word, and a subscript store prints both
  recomputation EQUs, then the update blocks, in reverse
  first-reference order. The label field matched the target byte for
  byte.

## The storage-map print

- **M4-7. The `*DATA` section printer.** M3-14 computed the values and
  deferred the lines; M4 prints them from `AreaInfo.words` and the
  allocator, opening with the counter head the sample attests (`USE 1` /
  `BGN 2,PI)1` / `USE 0` / `*DATA BSS 0`). Line selection, from the
  attested region (LOC 00000–00164): a named item prints its name in the
  label field on its first word; a constant-bearing word prints `OCT` with
  the twelve-digit octal repeated in the operand field; an uninitialized
  run prints one `BSS n`; a right-justified internal field prints its
  `BSS` per M3-6's reservation. The exact interleaving of labels, `OCT`,
  and `BSS` lines is pinned against the region golden; this entry
  records the principles, and the golden records the answer.
- **M4-7.1. The stage-1 golden held 91 rows** (Jack's call,
  2026-08-05): `USE 0` through LOC 00164, without the two counter-1
  head rows, whose origin no stage without verb generation can compute.
  Chunk B1 prepended them. The 89 body rows were diffed against the
  90.05 transcription before commit, with no mismatch: the storage map
  is a print problem at M4, not a derivation problem.

## The symbolic listing pages

- **M4-8. One geometry, scan-measured.** The 90.05 transcription renders
  the object listing in two incompatible column conventions, an artifact
  of two transcription passes over one continuous printout; M4-20 item
  (g) below measures one printed geometry on pages from both ranges.
  Measured from the LOC column's first digit as print column 0: LOC at
  0 (five digits), the
  OCTAL word at 7–21, CNTRL at 25–29, labels at 34, the `+n` offset
  right-aligned ending at column 42, the mnemonic at 49, the operand at
  56. A labeled line prints no `+n`, and a long label overruns the
  offset zone. The page head prints on the same grid — DATE at 0, PAGE
  at 83. The golden is therefore built from the transcription's
  *content* and the scans' *geometry*, never from its columns. The
  transcription is read-only and the golden is never "regularised"
  against it: the scan measurement decides.
  Line-form rules the transcription attests and the printer implements:
  - Three OCTAL renderings: twelve solid digits for `OCT` words;
    `OOOO FF T AAAAA` for type-B instructions; `P DDDDD T AAAAA` for
    prefix-type words (PZE, MZE, TXI, TXH, TXL, IOST, BSS, USE, ORG).
    *Amended 2026-08-09, confirmed on scan 2026-08-10 in chunk A7: a
    fourth rendering, `OOOO FF DDDDDD`, prints the low 18 bits as one
    group where the type-B form splits a tag from an address. Three
    sites carry it, all on listing page 20: `RIR 777777` at LOC 01240,
    `SIR 000001` at 01247, `RFT 000001` at 01251. Their operand is one
    18-bit sense-indicator mask, which the print does not split.*
  - The CNTRL column prints the word's 5-bit object-deck control group
    (M4-16). `USE`, `BSS`, and `ORG` lines print CNTRL 00001 with their
    control word in the OCTAL column (the `OP A` form of [J 90.03.03]);
    `BGN` prints its LOC only — no OCTAL, no CNTRL; the end-of-text line
    prints 01111.
  - A name of 15 or more characters prints alone and pushes the
    instruction to the next line (M4-8.1). Two labels on one word print
    one label per line, the word on the last (six attested sites).
  - An `EQU` line prints where the assembler first needs the symbol — out
    of location order — with the equated value in the LOC column, no
    OCTAL, no CNTRL. The `+n` offset counter resets at every line that
    itself prints no `+n`: label lines, `EQU` lines, and the unlabeled
    pseudo-operation lines (`BSS`, `USE`, `ORG`, `BGN`) — the word after
    an unlabeled `BSS 2` prints `+1` (LOC 00010/00012); `+n` is a
    listing artifact, not an address
    offset (M4-20 item d).
  - A duplicate data name prints with its encounter ordinal, `n)NAME`,
    numbering declarations of that spelling in data-division source order
    ([J 90.02.02]); a unique name prints bare. `DictionaryEntry.encounter`
    already carries the ordinal.
  - `SYS)n` and `IOC)n` print the decimal n in the address field; a file
    name prints as 04000 plus its loader-card file number. Both flag
    system reference in CNTRL; labels, `CP)`, block words, `*±n`, and
    transmitted items flag relative; written values, counts, and located
    displacements flag constant (B7; 977 rows verified).
  Page scans differ in horizontal registration. Measure each page
  against its own LOC column, never against another page.
  - Page furniture: the `LOC OCTAL CNTRL SYMBOLIC` column header prints
    once, on the first object page.
    **Amended 2026-08-10, chunks A2 to A8, and this closes the blank
    count.** Seventeen object pages hold two blank lines after the head
    and listing page 8 holds three. The conversion carries all eighteen, and
    `test/fixtures/90.05-object-listing-notes.md` holds the per-page
    measurement.
    No blank line separates routines, the storage map
    from the code, or the pool from the end-of-text line. The
    listing closes with that line, one blank line,
    `THE LAST LOADER CONTROL CARD PUNCHED IS`, the `*CTEND` card, and
    `DONE`.
    **Amended 2026-08-10, chunk A8: the three closing lines do not print on
    the object grid, and two print to the left of it.** Taking the LOC
    column as print column 0, as the rest of this entry does,
    `THE LAST LOADER CONTROL CARD PUNCHED IS` prints at column −6, the
    `*CTEND` card prints at column 0, and `DONE` prints at column −5. The
    loader writes these lines, not the compiler's listing formatter, which
    is why they do not share its margin.
    **The golden ends at the end-of-text line: the loader's three
    closing lines land with the deck writer, which takes their geometry
    from this entry** (chunk B7).
  **Amended 2026-08-09, stage 2. The page frame is pinned to the byte,**
  on the scans, field by field. Item (g)'s one geometry is unchanged;
  this adds precision to it. The column header prints `LOC` at 1,
  `OCTAL` at 12, `CNTRL` at 25 and `SYMBOLIC` at 58. The header's grid
  origin is the LOC column's first digit, so `LOC` sits one column right
  of the digits below it. The page head is the source listing's head
  unchanged, so stage 2 calls the builder in
  `lib/src/listing/listing.dart` and writes no second template;
  `m1-front-end.md` M1-16 as amended holds the measured columns and the
  evidence.
  **Amended again 2026-08-09, stage 2; closed by chunk B7.** A
  scan-verified target carried the chunks (Jack's call, with M4-1's
  chunking): the golden stayed the oracle, the target bought
  resumability. B7 grew `test/goldens/90.05-payroll.storage-map` into
  the whole document at the head's margin, matched it against the
  target byte for byte, and deleted target, generator, and tests.
  **Amended 2026-08-09 to 2026-08-10, chunks A3 to A8, and this closes
  the frame. The page body is a frame of 57 line slots,** with the head
  as slot 0, and all eighteen object pages hold it. Stage 2 therefore
  lays out an object page by the frame and never by a line count;
  `test/fixtures/90.05-object-listing-notes.md` holds the per-page slot
  table, page 8's column header and page 25's closing lines included.

- **M4-8.1. An over-long label pushes its instruction to the next line.**
  *Recovered from the print 2026-08-10, chunk A6; Jack's ruling the same
  day.* The label field is fifteen columns from print column 34, and the
  mnemonic column is 49. Where a label reaches column 49, the 1962
  printer put the instruction on the following line, at the ordinary
  mnemonic and operand columns with every other field blank, and left
  the label alone on its own. [J 90.02.02] says "exceeds 15" of
  statement names; the attested break is at 15 exactly, and the print
  governs. The 15-character INTERNAL.TOTALS breaks and every
  14-character name prints inline.

  One site in the program displaces a real instruction: the
  22-character `WITHOLDING.TAX.ROUTINE` at LOC 01220 on listing page 19.
  Three other labels reach column 49 with no instruction to displace, so
  they settle nothing.

  Nothing in either manual states this behaviour. It is read off the
  artifact, which makes it an M4-8 geometry fact and not a language fact:
  it stays out of the definition. The line count is the visible
  consequence, and it is what makes the frame hold on all eighteen
  object pages.

## MOVE

- **M4-9. The move generator.** Shape selection, in order, from the
  resolved classes (M3-10 already validated legality; codegen only picks
  shapes):
  1. **Figurative constant** (D4.11, chart column by column): build the
     target descriptor, call `TSX SYS)182,4`, then the fill word —
     `TXI SYS)243,1,n` for the blanks classes, `TXI SYS)244,1,n` for the
     plain-zeros classes — the chart's two "0's Edited" cells (edited
     and scientific-decimal targets) instead store an edited zero image
     through the numeric route (ours, no sample site) — and
     `TXI SYS)245,1,n` plus an in-line `OCT` word of six
     fill characters for HIGH.VALUE and LOW.VALUE — n the target's full
     character count. The notes' section 4.4 holds every site.
  2. **Alphameric class to alphameric class, in-line forms.** A one-word
     literal into a word-resident field: the mask-insert five-word shape
     `CAL mask / ANS target / COM / ANA literal / ORS target` (statements
     193 and 196). Whole-word fields of equal extent: word moves,
     `CAL source / SLW target` per word (statement 202). The general
     in-line bound is ours, pinned at the diff: in-line when both fields
     are word-addressable and the move is word-whole or single-word
     masked; otherwise the SYS)239–242 character movers through a MOVPAK
     dispatch entry. **Amended 2026-08-15, chunk B1: the mover run is
     sized from five sites** — `SYS)239` alone on equal storage lengths,
     `SYS)240` then `SYS)241` on a shorter source (the notes' section
     3.3).
  3. **Numeric and edited classes**: route per the [J 02.04.03] chart
     through the internal-decimal hub, selecting the MOVPAK family —
     SYS)183 (XD→XD), 184 (XD→ID), 185 (XD→EF), 186/187/188 (ID→XD by
     target sign convention), 189 (EF→XD), 190 (EF→EF), 246/247 (ID
     justification), 248–258 (floating and scientific), 267 (ID→EF), 268
     (EF→ID). The step list for a step-list family is computed from the
     two pictorials (move, bypass, zero-insert, sign-scan, overflow-test
     counts per [J 90.02.15]–19); the terminator is the target-numeric-length
     word. A MOVE emits no round step (D4.1(d)); the digit-count split
     divide precedes an edited store when the value's digits exceed the
     target's (D4.1(c)); the attested edited-store shape is
     `CLA source / TSX SYS)180,4 / PZE target,,pos / TXI SYS)267,1,edit /
     OCT control / AXT digits,1` (statement 218) — `edit` the
     target-edit-control bits and `control` the control-word bits, both
     per the SYS)185 feature table; the digit count rides in the `AXT`,
     tracking the target — 5, 6 and 7 across the sites.
  4. **CORRESPONDING**: expand `correspondingPairs`, one ordinary move
     per pair, the written subscript appended on its side (D4.12).
     **Amended 2026-08-15, chunk B1: the pairs emit breadth-first** — a
     top-level pair before the pairs inside a matched group (statement
     221's attested unit order) — and a MOVPAK kill of the register
     cache defers to the expansion's end (statement 221's chain against
     statement 220's reload). **Item (d) of the chunk B2 amendment below
     replaces "breadth-first" with the full order**, because that word
     named the levels and did not say how two pairs at one level break a
     tie.
  5. **Multiple targets**: one independent sequence per target, no shared
     setup (attested at statement 188's two receivers; D4.8's store
     independence is the same rule on SET).
  Operand addressing: a working-storage field's descriptor is an `LDI
  CP)+nn / STI SYS)132|133` pair; a located-record field builds its
  descriptor at run time, `CAL BL)n / ACL CP)+nn / SLW SYS)132|133`
  ([J 90.02.11]'s case 2; case 3 with `PDX` for a byte-carrying base). Every
  load of a base locator or positional indicator into an index register
  takes the guard `TXL SYS)294,i,0` on that register — attested 20
  times: 19 `LAC BL)n,i` pairs and one `LAC PI)1,2` pair (LOC 01410). A
  word reference that reads the locator into the accumulator
  (`CAL BL)n`, the run-time descriptor build) carries no guard.
  Register use (ours, pinned at the diff): XR1 for the first buffer
  operand of a statement, XR2 for the second; XR4 stays the linkage
  register ([J 02.08.03] destroys it on located references).
  **Amended 2026-08-15, chunk B1, the liveness composite** (pinned at
  the diff; deciding sites in the notes' Question 2 addendum): a
  register already holding its locator is reused, no words. The cache
  clears whole at a labelled word, a section entry and a subroutine
  call; a register write kills that register alone, at statement
  distance, the kill deferred to a CORRESPONDING expansion's end.
  The MOVPAK dispatch entries and their return-skip convention: SYS)179
  (both descriptors in the calling sequence, resume 3,4), SYS)180 (target
  only, 2,4), SYS)181 (source only, 2,4), SYS)182 (both preset, 1,4) —
  resume offset is parameter-word count plus one ([J 90.02.14]–15).
  **Amended 2026-08-16, chunk B2, the first verb generator.** B2 fills
  the mnemonic, operand and OCTAL columns of every MOVE the sample
  compiles and of the base-register guards. Six rules, each pinned at
  the diff:

  a. **The octal comes from the emulator's table.**
     `lib/src/codegen/encode.dart` imports `decode.dart` and states no
     operation code of its own, so the OCTAL column has one authority.
     `test/encode_test.dart` asserts the two directions entry by entry.
  b. **A guard sits at the word that uses its operand**, not ahead of
     the sequence. The NET sentence pins it: the guard for
     `1)BONDEDUCTION` sits at LOC 00727, between the fifth `SUB` and
     its own word, and not before the `CLA` at LOC 00722.
  c. **A base load takes the lowest free register**, and a register an
     earlier sentence left live is not free. Statement 208 takes XR2
     for `BL)3` at LOC 00772, because the NET sentence left `BL)2` in
     XR1. A statement that needs a third base register refuses.
  d. **CORRESPONDING emits level-major.** A pair matched at a
     receiver's own level emits before every pair matched inside a
     matched group. The receivers keep the clause's order. Within one
     receiver the matched groups emit in reverse description order:
     statement 208 fills `PAYRECORD DATE` at LOC 01006 to 01025 ahead
     of `PAYRECORD EMPLOYEE.NUMBER` at 01026, although the description
     gives `EMPLOYEE.NUMBER` first. The level rule is load-bearing at
     statement 221, where the `NAME` pair dispatches through MOVPAK and
     a pair after that dispatch would re-guard.
  e. **A two-factor product loads the literal into the Q register.**
     Where neither factor is a literal, `LDQ` takes the right factor
     and `MPY` the left. Three sites attest it: `LDQ CP)+6 /
     MPY 3)HOURS`, `LDQ 1)RATE,1 / MPY 3)HOURS`, and `LDQ CP)+12 /
     MPY EXEMPTIONS,1`.
  f. **Five more shapes refuse**, each legal COMTRAN the sample never
     reaches, each throwing `UnrecoveredShape` under M4-2 as amended.
     `test/codegen_refusal_test.dart` pins one program per site. Three
     other conditions cannot arise; the code asserts them.

  Items (d) and (e) are underdetermined: one sample attests each, and
  other formulations agree with it. Both are taken under the section
  12 standing rule and recorded `DECIDED`, with the formulations they
  beat, on branch `review/2026-08-16-m4-b2-underdetermined`.

## SET and arithmetic

- **M4-10. The expression compiler.** Arithmetic runs in internal binary
  only ([J 02.03.03]). The compile-time scale model, read off the sample
  (§8.5 Open Question 28 mining) and adopted as the design:
  - Every subexpression carries a compile-time scale from the declared
    pictorials. Additive operands align by upscaling the lesser-scaled
    operand where it is used — a generic multiply is emitted, never a
    folded constant (attested: the literal 20 scales by
    `LDQ CP)+7 / MPY CP)+31` at statement 203).
  - Products accumulate scale and are never downscaled mid-expression
    (attested: `1.5 × HOURS` parks in `RS)1` at scale 10^2, and the
    expression's scale reaches 10^5 in the AC-MQ after `MPY 1)RATE,2`,
    never stored).
  - The single downscale is at the store: `XCA / ACL CP)+h / LRS 35 /
    DVP CP)+d / STQ target`, `d` the excess power of ten and `h` half of
    `d` — the rounding half-adjust (D4.1(a)). `TRUNCATED` suppresses the
    `ACL` word only (D4.1(b)).
  - Equal-scale chains compile direct: `CLA / SUB / ADD … / STO`
    (statement 207, six operands, no temporaries).
  - Mode promotion is one-way and remainder-scoped ([J 02.04.05.01]):
    floating or double promotes the rest of the expression, never
    retroactively. Double-precision work uses SYS)128/129 and the
    SYS)163–171 scaling and divide routines by their [J 90.02] calling
    sequences; no double-precision or source-level divide appears in the
    sample, so these shapes are reconstructions labeled by this entry.
  - Negation binds tightest (D4.4); `A**B**C` never reaches codegen
    (D4.10); exponentiation routes through SYS)155/156/172/173.
  - Multi-result SET: one evaluation into `RS)`, one independent store
    sequence per target, left to right; `TRUNCATED` governs every store
    (D4.8).
  - A SET whose target is a subscript variable updates the affected
    positional indicators eagerly at the store site ([J 02.04.07.01];
    [J 90.01.02]). A constant increment adds the known stride — the
    `CLA CP)+n / ADD PI)n / STO PI)n` shape of [J 90.02.05]. A general
    store recomputes from the stored value — the attested
    `LDQ var / MPY CP)+stride / XCA / ADD base / STO PI)n` sequence
    (statement 225, LOC 01421–01432) — indexing by the raw stored
    digits, no scaling step (M3-20). The base reaches the `ADD` through a
    generated-name equate, `GN)091 EQU CP)+38`; a store that drives no
    indicator emits nothing.
  - `SET condition.name` stores the COND entry's constant into the
    conditional variable under the variable's own format (D5.6) — an
    ordinary constant store, no special machinery.
  - **ON OVERFLOW (ours, unattested).** No manual and no sample line shows
    the generated form; the clause survives nowhere in 90.05. The design:
    when the clause is written, codegen emits an object-time magnitude
    test ahead of the store tail — compare the full-scale result against
    10^(target digit count) upscaled by the excess power of ten, from
    the pool, before the `ACL` half-adjust, so rounding can never raise
    the condition (D4.1(f)); on overflow, skip the tail and the store
    and run the clause; otherwise store. SYS)130 is not used for this: nothing
    may clear it (D4.2), so a sticky cell cannot carry a per-statement
    test. Without the clause, no test is emitted and the truncated store
    proceeds silently — that silence is attested (D4.2). The first
    ON OVERFLOW evidence found amends this entry.

  **Amended 2026-08-16, chunk B3, the arithmetic generator.** B3 fills the
  columns of every SET, every ADD, every truth function and every
  subscript recomputation, and both subscript `EQU` operands. Six rules
  carry it:

  a. **A value carries the register that holds it.** A product ends in
     the MQ and a chain in the accumulator, so a park writes `STQ` or
     `STO`, five sites and no exception. The store tail opens on `XCA`,
     which reads the MQ half, so a scaling store of a chain refuses.
  b. **A computed operand parks in the cell its later operands count**,
     in the section the walk is in: `RS)n` in section 0, `k.RS)n` after
     it (notes 6.2 item 21).
  c. **The generator addresses M4-4's reserved cells section by section.**
     The undivided 7-cell tail is held whole for section 3, so result
     storage in a fourth section refuses, and that refusal is what keeps
     the fitted tail from overlapping anything. A cell past its section's
     reservation refuses too.
  d. **The `+0` word suffix is unrecovered** (notes 6.3 item 4). The
     generator emits it on an `STQ` to a cell above cell 0, which prints
     LOC 00621 and the bare form everywhere else — a predicate that
     reproduces the ink, not a rule that explains it.
  e. **ADD CORRESPONDING emits its targets backwards** — statement 208
     fills INTERNAL.TOTALS before MASTER TOTALS — and keeps the matcher's
     order inside one target. Statement 218's plain ADD keeps the written
     order, so the reversal belongs to CORRESPONDING (notes 6.2 item 20).
  f. **An edited ADD source converts through MOVPAK, then parks.**
     `TSX SYS)182,4 / TXI SYS)268,1,1 / TXI SYS)269,1,d /
     TXI SYS)275,1,d`, `d` the source's digits: a register target takes
     every character, so the step list reduces to the move alone. The
     convert leaves the accumulator, so the park is `STO`.

  `RIR`, `SIR` and `RFT` print M4-8's fourth OCTAL rendering, so
  `encode.dart` gives them a word form of their own. Two shapes refuse
  beside the three named above — a scale alignment of a sub-chain, and a
  product of a product — and `test/codegen_refusal_test.dart` pins one
  program per site. Items (b), (d) and (e) are underdetermined, and
  `review/2026-08-16-m4-b3-underdetermined` holds the formulations they
  beat.
## IF and WHEN

- **M4-11. One comparison generator.** IF and the conditional GO TO's WHEN
  clauses share one generator (§8.5 Open Question 42):
  - **Numeric compare**: `CLA` one operand, `CAS` the other — the
    algebraic three-way skip (statements 203, 212).
  - **Alphameric and logical compare**: `CAL` and `LAS` — the unsigned
    three-way skip (statements 192, 197, 200). A sub-word field is
    extracted first: shift and mask into a scratch cell (`CAL / LGL n /
    ANA CP)+mask / SLW RS)n`, statement 200's two-character departments).
  - **The skip vector (ours, from the eleven attested sites — six `CAS`,
    five `LAS`):** after the compare, emit one `TRA` slot per outcome in
    the order greater, equal, less, each targeting that outcome's
    continuation. A slot prints a symbol when the generator holds a
    name for its target — the written WHEN target, an arm label — and
    the relative form `TRA *+n` otherwise (`TRA *+1` at statement 220,
    LOC 01306; `TRA *+3` at statement 203). Elide the trailing slot —
    at most one — when it falls through to the word directly after the
    vector. GT with both
    arms: three slots (`TRA *+3 / TRA otherwise / TRA otherwise` — the
    false outcomes transfer to the OTHERWISE arm's own label, GN)072 at
    statement 203, not to the join). NOT EQUAL:
    two slots, the less outcome falling through. A WHEN `=` clause: two
    slots, less falling into the next clause.
  - **Arms and labels**: the THEN arm follows the vector; with OTHERWISE,
    the THEN arm ends `TRA join`, the OTHERWISE arm carries its GN label
    and falls into the join. M3's allocator already reserved the label
    words (M3-23); codegen binds them to locations.
  - **Compile-time folds**: unequal-length alphameric `=` / `NOT =` folds
    at compile time — only the selected arm's transfer is emitted (D3.3).
    The rule is operator-scoped, so a folded WHEN clause follows it: an
    always-false clause emits nothing, an always-true clause emits one
    unconditional `TRA` and strands the clauses after it (the language
    says remaining expressions go unevaluated). No diagnostic is attested
    for either fold; none is emitted (ours).
  - **Magnitude compares of unequal length** equalize by right truncation
    of the longer field (D5.3) — by the emitted mask in-line, or by the
    length parameters on the SYS)162 path.
  - **The subroutine boundary (ours, pinned at the diff):** fields the
    compiler can compare in one word compile in-line (every sample
    compare); anything longer calls SYS)162 with its collate-table OP word
    (`CVR` under COLLATE COM, `NOP` otherwise — [J 90.02.12]; D8.1). The
    sample never calls SYS)162, so the boundary is exercised only by
    constructed decks.
  - **Condition tests**: a data condition compares the conditional
    variable against the COND constant, an equality compare as above. A
    keys condition (Environment COND) is the console-keys test
    ([J 02.06.17]); no COND card appears in the sample, so no shape is
    attested — the generated form is ours, defined at stage 2 and
    marked so.
  - **Truth functions `TR( )`** run the same compare machinery gated
    onto a sense indicator — the attested shape (statement 215,
    LOC 01240–01252): `RIR` clears the indicator, the compare's skip
    vector routes the true outcome to `SIR 000001`, then
    `PXA 0,0 / RFT 000001 / CLA CP)+1` yields 1 or 0 as the arithmetic
    factor. Only this site is attested; the general shape is pinned at
    the diff.
  - **AND, OR, NOT** compile as short-circuit chains of compare-and-branch
    to the arm labels; no boolean value is materialized. Unexercised in
    the sample; ours.
  **Amended 2026-08-11, chunk B1. The symbol rule above is this
  amendment's correction.** The first form chose the relative print by
  position — a slot printed `*+n` when its target was the word after
  the vector — and statement 215 falsifies it: the slots at LOC 01245
  and 01246 both target 01250, the word after the vector is 01247, and
  both print relative. One site discriminates, so the correction rests
  on one site. The same pass moved the `TRA *+1` citation from
  statement 219, a MOVE, to statement 220. Only the trailing slot can
  elide because the three slots sit at fixed displacements from the
  compare, in [J 90.02.12]'s own HIGH, EQUAL and LOW order.
  **Amended 2026-08-16, chunk B4. The generator fills the eleven
  sites.** Six rules the fill fixed:
  - **The zero build** (the catalogue's L(A) = 3): `LDQ` the pooled
    zero, `MPY` the power of ten that raises it to the storage
    operand's scale, `XCA` (statements 205 and 215).
  - **The extraction shift** is six bits a character (statement 200's
    `LGL 18`, one site).
  - **The spill** writes result-storage cell 0 of the walk's section
    (statement 200's `RS)0`, one site).
  - **The spill mirrors the outcomes.** `LAS` reads the accumulator
    against storage, and after the spill the accumulator holds the
    second operand (derived; external: 22-6528-4). The one site is a
    symmetric NOT EQUAL and cannot show the swap.
  - **The subscripted comparand's prologue** is `LAC PI)n,r /
    TXL SYS)294,r,0`, the register the lowest free one under M4-9's
    rule and dropped from the locator cache; the compare addresses the
    element as `0,r` (statement 225, one site).
  - **A truth function's false outcomes** land one word past the
    vector, over the `SIR` (statement 215's `*+3` and `*+2`).
  The one-site cell and register choices are underdetermined; the
  chunk B4 record holds the rejected formulations. Six unattested
  variants refuse (M4-2 as amended):
  - a nonzero literal comparand;
  - a subscripted accumulator comparand;
  - an unscaled zero;
  - a subscripted alphameric comparand;
  - an unequal-length pair — the D3.3 fold and the D5.3 truncation
    each wait for a site;
  - a comparand past one word: the SYS)162 boundary stays unbuilt
    beside AND, OR and NOT, the compound-condition precedent.

## GO TO

- **M4-12. Transfers.** An unconditional GO TO is one `TRA` word. A GO TO
  that is a statement's whole content and coincides with a generated join
  folds onto the join label (attested: GN)065 carries statement 195's
  `TRA`). The conditional form is M4-11's WHEN machinery in source order,
  fall-through after the last clause. The assigned form
  `GO TO (p1,…,pn) ON index` (ours; no sample instance): the index's
  integral part per its declared scale, the D5.5 object-time range
  test, 1 through n — out of range falls through to the next clause,
  no message — then an n-word `TRA` vector indexed by a register.
  D5.5's omit option is the non-historical flag
  `--no-goto-range-check`, recorded here; it removes the bounds test
  only.
  **Amended 2026-08-16, chunk B5. The generator fills every transfer
  site.** Refusals: the B1 assigned form stands; a GO TO naming a
  celled procedure — a DO target (behind msg 128, the 1962 bypass) or
  a section; at every transfer and call site, an undefined name
  (behind msgs 127 and 188) and a two-word D2.5 reference; and, at
  the binder, a name bound twice or bound to no word. No site shows
  any of these object forms.

## DO

- **M4-13. The DO generator, and the D5.1 decode.** The linkage is the
  verified Q40 return-cell shape:
  - Every procedure any DO addresses gets a one-word return cell as its
    first word, the placeholder `AXT 0`, call-site-driven — a
    paragraph gets a cell when a DO names it (attested:
    END.OF.MASTERS), and a GO TO-only target gets none
    (END.OF.DETAILS).
  - A plain `DO P` emits `AXT *+3,7 / SXA P,4 / TRA P+1`. The terminal
    END emits `TRA* P` — indirect through the cell — labeled by the
    written END label or the M3-23 generated name. `AT END DO x` emits the
    identical triple inside its out-of-line block (D6.6).
  - `DO P FOR i = p(q)r` patches the return cell **once**, before the
    loop, to the increment block: `AXT GN)a,4 / SXA P,4`, then the index
    and pointer initialization, then `TRA P+1`. The back edge re-enters
    `P+1` directly; the SXA never re-executes (attested, statement 206).
    The increment block: add q to i, add the stride to each affected
    positional indicator, then the exit test.
  - **The exit test is a magnitude test. This entry performs the decode
    D5.1 pre-committed to M4.** The attested block (statement 206,
    LOC 00711–00721) is `CLA INDEX / ADD CP)+1 / STO INDEX / CLA CP)+13 /
    ADD PI)1 / STO PI)1 / CLA CP)+8 / SUB INDEX / TPL GN)085` — r − i,
    branched on sign: D5.1's magnitude exit. The loop
    runs while i ≤ r after each increment; a +0 result (i = r) transfers,
    so the body runs for i = r; normal exit leaves i at the first value
    past r — r + q when q divides r − p exactly. D5.1's
    pre-committed amendment is applied in `decisions.md` with this
    citation. Consequences: the at-least-once rule holds (entry precedes
    any test, [J 90.01.02]); an overshooting step terminates, so the
    equality reading's non-termination hazard is gone; a zero or
    wrong-signed q with p ≤ r never terminates (p > r exits at the
    first test), and the emulator reproduces both faithfully.
  - Literal p, q, r bake into pool constants; a named parameter is
    read where the expansion reads it — p at entry, q and r each pass
    (F's order; §8.5 Open Question 36 disposition, M4-21).
  - `DO … EXACTLY n TIMES` (no sample instance, ours): the patch-once
    machinery with a generated counter cell, counted down to the
    magnitude exit.
  - Multi-index DO: nested increment-and-test blocks, innermost first,
    rightmost index varying fastest; the outer index increments, never
    reassigns (D5.2).
  - USING and GIVING lower as MOVEs around the bare DO — parameters in
    before the call, results out after it, full MOVE editing per pair
    (M3-19; [F p. 53]'s expansion).
  - Recursion is unguarded: a second activation overwrites the cell;
    the emulator reproduces the wild return (D5.7). Non-recursive
    nesting is unrestricted.
  - `--pedantic` sites (D11.4; ids from M4-18): constant p, q, r whose
    (r − p) is not a whole multiple of q, or q zero or wrong-signed
    (D5.1); a static cycle in the DO call graph (D5.7).
  **Amended 2026-08-16, chunk B5. The generator fills the linkage.**
  The fill added:
  - The return's flag bits print as octal group 60 (LOC 00350).
  - The loop entry prints `P+1`; the back edge prints the body-entry
    EQU name — one address, two prints (00710, 00721).
  - A paragraph with no written END closes at the next label
    (attested: GN)067) or at a bare END, both through the cell.
  Seven refusals:
  - an unnamed section;
  - a section beginning inside an open section;
  - an END inside an open paragraph and an open section;
  - a procedure open at the end of the text;
  - a DO FOR index undefined (behind msg 108) or located;
  - a DO FOR driving two indicators — the M4-6 name run fits one.

## STOP and the statement stamps

- **M4-14. STOP and the number stamps.** STOP RUN emits the D2.7 shape,
  three parts in order: the message call `TSX SYS)178,4` with two
  `PZE CP)+a,,CP)+b` words carrying the statement stamp and the
  words ` STOP ` / ` RUN  `; the implicit close-all pair
  `TSX SYS)177,4 / PZE IOC)1`; then `TXI IOC)40,0` — no halt
  instruction. The sample's SYS)177 pair at LOC 00517/00520 is
  the source's separate `CLOSE ALL FILES` clause (M4-15's shape), not
  STOP RUN's (D2.7). STOP n has no sample site and refuses (notes
  section 7); its D2.7 reading (the SYS)178 call alone, the halt in the
  handler) stands unbuilt. The statement stamp is a pool pair: the
  statement number in BCD, a comma, two digits, and three blanks. Each
  GET sequence opens with it as a tag-0 no-op,
  `TXH CP)+a,0,CP)+b`; SYS)178's parameters carry it; no other statement
  emits one (five attested sites, statements 188, 190, 191, 194 and 199).
  **Amended 2026-08-15, Jack's ruling (the chunk B1 review record). The
  two digits take a fitted rule.** They are the zero-based ordinal of the
  stamping clause within its statement, where each target of a
  multi-target MOVE counts as its own clause, `OPEN ALL FILES` does not
  count, and `CLOSE ALL FILES` does. [J 90.02.29] names STATEMENT-NUMBER
  and SUB-STATEMENT-NUMBER and defines neither, so the rule is **fitted,
  not derived**: it reproduces the five sites, and the two counting
  exceptions rest on one site each.

## The I/O shapes at M4

- **M4-15. Attested shapes, deferred runtime.** M4 emits the I/O verbs'
  calling sequences so the listing and addresses reproduce; M5 makes them
  run. The shapes: the run frame opens with `TSX SYS)175,4 / PZE IOC)1`
  (open all) at the entry word GN)000; GET is the stamp word, then
  `TSX IOC)8,4 / PZE file,,SYS)260 / PZE atEnd,,SYS)283 /` the buffer
  descriptor word `BL)n,,len`, then the AT END out-of-line block per
  D6.6; FILE of a working-storage record is
  `TSX IOC)9,4 / PZE file,,0 / IOST record,,len`;
  FILE of a located record patches its own IOST word first —
  `LXA BL)n,4 / SXA GN)a,4` then the call, GN)a labeling the IOST word
  (attested, statement 208). CLOSE ALL FILES is the SYS)177 pair. The
  record's file lists are public since M3-11; the `04000 + k` ordinal
  reads off the FILE cards: no new binder exposure.
  **Amended 2026-08-17, chunk B6.** Every other I/O form refuses (M4-2
  as amended): OPEN or CLOSE naming files (notes section 7), GET RECORD
  FROM, GET with no AT END (SYS)265 unattested), GET from a file
  declaring ON ERROR (the SYS)283 replacement is unknown), GET of a
  transmitted record, and FILE record IN file. A GET or FILE refuses
  off the roster, on other than one matching file, or where two FILE
  cards share a name.

## The object deck and the loader cards

- **M4-16. The deck writer and our loader.** The object deck is the 90.03
  relative binary form: 24-word 9L cards — word 1 the header (relative
  indicator, checksum control, CT bit, deck type, word count, sequence
  number), word 2 the logical checksum, words 3 up the payload. The text
  section (deck type 100) is the only section punched: no debugging
  dictionary (90.03 defers it), no control-break table and no file-check
  table ([J 90.01.04]; D7.10). Text cards carry up to 19 words, each with
  its 5-bit control group packed in words 3–5. The control groups are
  M4-8's CNTRL column: `1 AB CD` standard words with the decrement and
  address relocation classes (constant, relative, system reference,
  complex), and the special entries — 00000 end of card, 00001
  location-counter control (`PZE` absolute origin, `MON` relative origin,
  `PTW` fixed BSS, `PTH` variable BSS), 01111 end of text with the entry
  point in the address (D2.1: the sample ends
  `00165 500000000165 01111 START GN)000`). The 2TEXT-only forms
  (immediate operator, external-name-table reference) are loader-internal
  and never punched ([J 03.00]; the miner's-judgment reading is adopted).
  The loader cards: `*FILE` and `*SPEC` per the [J 90.08] field derivations
  (D7.1 punches the blocksize), then `*CTEXT`, the binary deck, `*CTEND`,
  with deck.name and date-and-time from the $CMPLE card; $LOAD and the
  end-of-file card are not the compiler's ([J 03.00]). Our loader (D0.3)
  reads the symbolic cards and the text section, resolves the control
  groups, places the program at a chosen origin, maps SYS)/IOC) references
  to dispatch addresses, and enters at the entry point the 01111
  end-of-text word carries in its address (D2.1); the
  round trip — emit, load, compare memory against the listing's word
  image — is the stage-3 oracle. `--emit-deck` writes the punch-level
  card file; `--emit-loader` writes the symbolic card text.

## The machine assembly and the runtime boundary

- **M4-17. The dispatch layer and the compute handlers.** The machine
  assembly wraps the CPU core: before each step at an address registered
  as a SYS)/IOC) entry, the dispatcher runs the Dart handler instead of
  the CPU (docs/design/emulator.md §1); a TSX-linked handler reads its
  calling sequence through XR4, honors the resume convention
  (parameter-word count plus one), and returns control — SYS)294 alone
  breaks the pattern: the guard's conditional `TXL` reaches it with no
  calling sequence, and it exits to the monitor instead of returning.
  M4 lands the compute set — the cells and flags SYS)128–134, the
  scaling, exponent, and comparison routines SYS)155–173 (SYS)161 among
  them is the 709-to-705 collating table the compare path reads — data,
  not code), MOVPAK entire (SYS)179–258, 267–282), the base-locator
  guard SYS)294 — plus the run-frame stubs SYS)174–178 (open and close,
  one file and all, and the display routine) and IOC)1, IOC)40, enough
  to run an I/O-free program end to end and to execute STOP. M5 lands
  IOCS: IOC)2–17, 29, 46, 53, 54 and SYS)260–266, 283, and 286–296
  less the already-landed 294. Each handler implements its [J 90.02]
  contract and is unit-tested against it (D0.3). Handlers keep the
  documented printed inconsistencies as recorded defects, not silent
  fixes: SYS)231–234 follow their own entries (overpunch test), not the
  family lists' overflow naming (D4.2's note).

## Diagnostics

- **M4-18. The message inventory.** The codegen and assembly stage
  enforces:
  - **Msg 173** (C5): a generated reference names an undefined GN) or
    SYS) symbol — an integrity check over the compiler's own output,
    wired into symbol resolution before deck output (D9.13).
  - **Msg 174** (C1): a generated SYS) reference carries no number; zero
    assumed (D9.13).
  - **Msg 69** (C5): illegal internal code reaches assembly — the
    assembly-stage assertion of D9.15, reporting a compiler bug in 1962
    form.
  - **Msg 172** (C5): the constant pool passes 500 entries (D9.7;
    [J 90.01.05] item k). `--no-table-limits` lifts it with the rest of the
    D9.7 class.
  - **Msg 942** widens to the eight-class tally (M4-5).
  - **New non-historical ids**, continuing M3's sequence from 946
    (M3-21; D9.7's pattern), both `--pedantic`-only under D11.4's
    invariant — the mode adds diagnostics and changes nothing else, and
    the 921/922 precedent shows a pedantic-only id may carry an error
    class: **946** (C1) the D5.1 constant-parameter note (q zero,
    wrong-signed, or (r − p) not a whole multiple of q); **947** (C2;
    the class is ours) the D5.7 DO-call-graph cycle, an error by that
    record's own word.
  No diagnostic attaches to rounding, to the compile-time comparison
  folds, or to the assigned GO TO's range fall-through (attested
  silences).

## Emit stages

- **M4-19. Three new stages** under `emit-stages.md`'s conventions,
  which this entry adopts unamended:

  | Flag | Short | Stage | Status | Oracle |
  |---|---|---|---|---|
  | `--emit-code[=<path>]` | `-g` | assembly text model | reconstruction | golden: `test/goldens/90.05-payroll.code` |
  | `--emit-deck[=<path>]` | `-d` | object deck | attested format, no surviving byte image | 90.03 conformance tests; the load round trip |
  | `--emit-loader[=<path>]` | `-L` | loader symbolic cards | attested | the listing's page 198 lines |

  The code dump renders the text model one unit per line and opens with
  the reconstruction label. The deck dump writes the punch-level binary
  card file; its text rendering is the listing's own OCTAL/CNTRL columns,
  so no separate text form is invented. The letters extend the existing
  bundle (`-cpsSlgdL`; `-A` takes all).

## Scan readings and erratum candidates

- **M4-20. The stage-0 scan checks (2026-08-05).** The dossier work
  behind this walk flagged readings the design depends on. Each was
  measured on the page scans before this record was committed, at 8× to
  40× magnification with per-glyph comparison against known glyphs on the
  same page. A reading that contradicts the transcription becomes an
  erratum candidate in HANDOVER, waiting for Jack's authorization; the
  transcription itself is not edited. The verdicts, all read certain:
  - **(a) CP)+38's decrement (PDF p. 216) — the transcription is right,
    and the print is the surprise.** Both descriptor words print the
    identical `0 00000 0 00134`: `PZE RETPREM-2` and `PZE INSPREM-2`,
    decrement zero on both, though RETPREM occupies characters 3–5. The
    decrement column is live on the same page (`PZE INS.PREM,,3` prints
    00003), so the zeros are deliberate ink. The EQU'd subscript-base
    words are therefore byte-blind, the byte selection lives in the
    generated lookup code, and the reproduced pool prints the two
    identical words. This closes the review backlog's RETPREM pointer
    anomaly.
  - **(b) LOC 01612 (PDF p. 215) — a transcription error, corrected
    2026-08-05 under Jack's authorization.** The print reads
    `CLA 5)NETPAY`; the transcription's `4)NETPAY` misread the 5. The
    listing corroborates the scan on its own: the correctly transcribed
    octal address 00133 pairs with `5)NETPAY` at both other sites that
    reference it, LOC 00423 and LOC 01614. The golden prints
    `5)NETPAY`.
  - **(c) LOC 01327 (PDF p. 212) — confirmed as printed.** The word is
    `TRA SYS)267,0,0`, octal `0020 00 0 00413`, inside a SYS)180
    sequence where every parallel site prints `TXI SYS)267,1,n`. The
    1962 ink is unambiguous, so the listing reproduces it byte for byte.
    The execution reading is deferred to M6, when the sample first runs;
    the finding amends this entry.
  - **(d) LOC 00702 (PDF p. 206) — confirmed verbatim.** The label-only
    `GN)075` line, the out-of-order `GN)088 EQU CP)+37` line between it
    and the instruction, and the unlabeled `AXT GN)086,4` word printing
    `+1`: all as transcribed, which is the attested ink behind M4-8's
    offset-counter reset.
  - **(e) The PDF p. 208 page head — a transcription error, corrected
    2026-08-05 under Jack's authorization.** The print is one head line
    in the normal order, followed by two blank lines. A one-degree scan
    tilt drops the right half of the line, and the transcription split
    it into two transposed lines. The golden prints one line, on
    PDF p. 209's field grid, per item (g).
  - **(f) The GET descriptor mnemonic — the two artifacts genuinely
    differ.** The listing prints `IOCTN*` (read at three sites on PDF
    p. 201; the fourth glyph is a T at 40×, against a D control glyph
    from GET.DETAIL); the typeset [J 90.02.04] prints `IOCDN*`. Each
    transcription is faithful to its own source, so neither is an
    erratum. The compiler emits the listing's `IOCTN*`, and the
    divergence is recorded here rather than in the definition because it
    is a print fact, not a language fact.
  - **(g) The column geometry (PDF pp. 203 and 212) — one geometry.**
    Pages from both transcription ranges print identical grids, the
    M4-8 table, constant to half a character cell; the apparent two
    conventions came from opposite scan distortions, and the pasted
    listing block sits at a different offset on each manual page — page
    furniture, not print.

## Open Question dispositions

- **M4-21.** Decided by this walk and annotated in place in the
  definition's list. Each disposition is the generated behavior, and the
  entry cited with it holds the shape:
  - **Q37**, the index after a completed loop: normal exit leaves i at
    the first value past r, r + q when q divides r − p exactly, and a
    GO TO out leaves the last increment's value (M4-13). §8.5.5-a takes
    the matching annotation: the compiled exit is a magnitude test, and
    F's printed expansion stays the manual's text.
  - **Q26 residue**: the ACL half-adjust runs away from zero for
    negatives by 7090 semantics, no negative case is attested, so the
    reading stays flagged inference, and rounding cannot arm SYS)130
    (D4.1(a), D4.1(f)).
  - **Q27 / Q28 residues**: closed for implementation by M4-10 —
    downscale at the store site only, ON OVERFLOW as an inline pre-store
    test. The language questions stay open, pointing here.
  - **Q31**: SYS)131 is set by the numeric movers and read by nothing,
    reproduced exactly (D4.3). **Q33**: multi-target stores run left to
    right in written order, observable only on REDEF overlap, ours
    (D4.8). **Q34**: DO USING/GIVING transfers are MOVEs, so they take
    full MOVE editing (M3-19). **Q36**: named q and r are re-read each
    pass by the increment block and literals bake into the pool (M4-13).
    **Q24**: no object-time check on a QUANTITY IN value against its
    reservation, and the emulator reproduces the silent overrun
    ([J 90.01.02]).
  - **Q42 residue**: the WHEN fold shapes are decided (M4-11). Q38
    (msg 170's trigger), Q39 and Q43 stay open and block nothing in M4.

## Oracles

- Stage 1: the storage-map region of the 1962 listing, byte for byte,
  scan-checked before commit.
- Stage 2: the full listing diff, PDF pp. 198–216, byte for byte, after
  the M3-22-pattern blind scan verification of pp. 199–216 (p. 198 is
  stage 3's, per M4-1); the 90.05 job deck compiles
  clean in default mode, and `--pedantic` adds only the three 943 notes
  (ours, non-historical — the sample's own doubtful blank-moves, D11.4
  as amended) plus any new 946/947 sites the deck triggers (it triggers
  none: statement 206's parameters divide evenly, and the DO graph is
  acyclic).
- Stage 3: the loader-card page inside the listing diff; 90.03
  conformance tests on the deck; the load round trip against the
  listing's word image.
- Stage 4: per-handler D0.3 contract tests; end-to-end runs of
  constructed I/O-free decks with storage assertions.
- Error paths: constructed decks per message, asserting id, severity,
  statement number, and recovery (the M2 oracle pattern).
- Decision conformance: each M4-N and each D-slate call named above gets
  a test that cites it.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 53]: ../../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-data-substitution
[J 02.03.03]: ../../comtran-manuals/J28-6169/02-compiler.md#b-key-words
[J 02.04.03]: ../../comtran-manuals/J28-6169/02-compiler.md#2-display
[J 02.04.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.07.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.06.17]: ../../comtran-manuals/J28-6169/02-compiler.md#h-option-environment-cards
[J 02.08.03]: ../../comtran-manuals/J28-6169/02-compiler.md#c-flexibility-above-that-of-scat
[J 03.00]: ../../comtran-manuals/J28-6169/03-loader.md#section-0300-loader
[J 90.01.02]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.04]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.05]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.01]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#introduction
[J 90.02.02]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.03]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.04]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.05]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.06]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.11]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.12]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.15]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.29]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.03.03]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#3-file-check-entry-specifications
[J 90.04]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.04.02]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#a-error-messages
[J 90.08]: ../../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008
