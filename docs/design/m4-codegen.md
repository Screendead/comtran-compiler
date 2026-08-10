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
the section it belongs to. The code cites these IDs, so no entry is ever
renumbered. Use the index below to find one.*

| Entry | Section |
|---|---|
| M4-1 | Scope and stages |
| M4-2, M4-3 | Pipeline position and the text model |
| M4-4 | The program image |
| M4-5, M4-6 | Generated names and msg 942 |
| M4-7 | The storage-map print |
| M4-8 | The symbolic listing pages |
| M4-9 | MOVE |
| M4-10 | SET and arithmetic |
| M4-11 | IF and WHEN |
| M4-12 | GO TO |
| M4-13 | DO |
| M4-14 | STOP and the statement stamps |
| M4-15 | The I/O shapes at M4 |
| M4-16 | The object deck and the loader cards |
| M4-17 | The machine assembly and the runtime boundary |
| M4-18 | Diagnostics |
| M4-19 | Emit stages |
| M4-20 | Scan readings and erratum candidates |
| M4-21 | Open Question dispositions |

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
     (M4-4), the storage-map print (M4-7), and `--emit-code`. Oracle: the
     storage-map region of the 1962 listing, lines for LOC 00000–00164,
     byte for byte (M4-7).
  2. **Core-verb text** — the verb generators (M4-9 to M4-15), the
     generated-name pass (M4-6), and the symbolic listing pages (M4-8).
     Oracle: the full listing diff, PDF pp. 198–216, byte for byte, after a
     scan verification pass (M4-8; M3-22 pattern).
  3. **The object deck and loader cards** — the 90.03 text encoding, the
     *FILE/*SPEC/*CTEXT/*CTEND cards, `--emit-deck`, `--emit-loader`, and
     our loader (M4-16). Oracle: the loader-card page (PDF p. 198) inside
     the listing diff; a load-and-verify round trip against the listing's
     word image.
  4. **The machine assembly** — the runtime dispatch layer and the compute
     handlers (M4-17), and execution tests for I/O-free programs. Oracle:
     D0.3 contract tests per handler; storage assertions after emulated
     runs.

  **Amended 2026-08-09, stage 2 (Jack's call). Stage 2 is not one pull
  request.** Its oracle needs a blind pass over nineteen page scans, the
  most expensive evidence work on the roadmap. One pull request puts that
  whole pass at risk of a usage limit. Stage 2 therefore splits into
  chunks. Each chunk is green alone, and each is worth merging alone.
  Stages 1, 3, and 4 do not change.

  Phase A builds the target listing, before any generator runs:

  | Chunk | What it delivers |
  |---|---|
  | A0 | This amendment, and the M4-8 amendment it names. |
  | A1 | The tool and the target file — the transcription's object-listing content, re-rendered in the M4-8 geometry. |
  | A2 | One page verified blind against its scan, PDF p. 212, to measure the cost of the rest. It brings the corrections table, which the first correction needs. |
  | A3 to A8 | The other seventeen pages, three to a pull request. |

  The target holds listing pages 8 to 25, PDF pp. 199 to 216. Page 7,
  PDF p. 198, carries the loader control cards on no LOC/OCTAL/CNTRL
  grid, and stage 3 both generates that page and takes it as its own
  oracle, so its verification goes with stage 3.

  Phase B generates, and it sizes before it fills:

  | Chunk | What it delivers |
  |---|---|
  | B1 | The address spine — the word count of every verb shape (the [J 90.02] calling sequences, the M4-15 I/O shapes included), the constant-pool allocator, the `RS)` and `TS)` cell scheme, and the later-pass names GN)084 on (M4-6). |
  | B2 | MOVE (M4-9). |
  | B3 | SET and arithmetic (M4-10). |
  | B4 | IF and WHEN (M4-11). |
  | B5 | GO TO and DO (M4-12, M4-13). |
  | B6 | STOP with the statement stamps (M4-14), and the I/O shapes (M4-15). |
  | B7 | The close-out — the `USE 1` and `BGN 2,PI)1` head rows, the four block sizes, the constant pool, the page furniture, and the full listing diff. |
  | B8 | The diagnostics — msg 942 widened (M4-5), ids 946 and 947 reserved (M4-18), and the D10.2 stop shape M4-2 defers to here. |

  B1 comes first because the listing's addresses are continuous. A verb
  site references `CP)+n`, `n.RS)m`, and absolute LOC values, so no site
  matches byte for byte until every unit before it carries the right word
  count. B1's oracle is therefore the LOC column of the whole target,
  matched line for line, with the other columns still empty. B2 to B6
  then each match their own attested sites, LOC included.

## Pipeline position and the text model

- **M4-2. A separate phase over `SemanticResult`.** The code generator is
  `runCodegen(SemanticResult) → CodegenResult` in a new `lib/src/codegen/`
  component. `bin/comtranc.dart` becomes deck → `runFrontEnd` → `runParser`
  → `runSemantics` → `runCodegen` → `writeListing`, per job. `runCodegen`
  follows D10.2 exactly: it catches `StopCompilation` itself, returns a
  partial result with a `stopped` flag, and the driver skips it when an
  earlier phase stopped.
  **Amended 2026-08-05, stage 1.** Stage 1 builds the storage map from
  facts the semantic layer already validated, so it detects no error and
  reports no diagnostic. Its stop shape was therefore unreachable: no
  input could enter the `catch`, the `stopped` flag was always false, and
  the diagnostic list was always empty. CLAUDE.md section 11 bans code
  that is neither exercised nor tested, and it outranks this record, so
  stage 1 ships without the shape. `runCodegen(SemanticResult) →
  CodegenResult` takes no diagnostic sink. The stop shape above binds
  stage 2, whose verb generators are the first code here that can detect
  an error; it arrives with them, sink and all. The driver's skip of a
  stopped earlier phase is unaffected and still holds.
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
    then `PZE IOC)29 / PZE 0 / PZE 0`).
  Block sizing rules: `RS)` is the sum over sections of the maximum result
  storage each section uses ([J 90.02.03]) — cells two words each, D4.8's
  inference from the listing's LOC values, not stated by J;
  `BL)` is one word per base locator — BL)1 for the IOCS label area, one
  per located-record buffer pointer (M3-11); `PI)` is one word per
  positional indicator (M3-20's counter). The `TS)` sizing rule is
  unrecovered: the sample reserves 7 words and references none of them.
  Stage 1 carries `TS) BSS 7` as a recorded constant; the listing diff
  either reveals the rule or this sentence stands as the decision.
  **Amended 2026-08-05, stage 1.** Stage 1 does not carry `TS) BSS 7`.
  Jack's call: build the layout rule, and leave each size to the stage
  that can derive it. The verb generators size result storage, temporary
  storage, the positional indicators, and the constant pool, so stage 1
  leaves all four empty and stage 2 fills them. Stage 1 derives `BL)`
  alone, and gets the sample's attested 3.
  Arithmetic confirms the block order against three attested addresses.
  Location Counter 1 starts at 01621. RS 30 words and TS 7 words put
  `BL)1` at 01666, which the `ORG BL)1` line prints. BL 3 words put
  `PI)1` at 01671, which the `BGN 2,PI)1` line prints. PI 3 words put
  the pool at 01674, where the listing shows it.
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
  pool (62 entries, LOC 01674–01771) is the conformance check:
  statements 203 and 215 share the literal CP)+31, while the
  bit-identical pointer pair CP)+38/CP)+39 and the four zero-valued
  pointer words CP)+43 to CP)+46 stay separate entries; D4.1 already
  pins CP)+24, CP)+31 to CP)+34 by index.
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
  `EQU SEARCH+1` (loop-body entry), GN)086 (the increment block), GN)088
  `EQU CP)+37` (the table-base initializer) for statement 206's
  `DO SEARCH FOR`; GN)089 on the `IOST` word FILE MASTER patches at run
  time; GN)091 `EQU CP)+38` and GN)093 `EQU CP)+39` for the RETPREM (POS)
  and INSPREM (POS) subscript bases. Working rule (ours, provisional):
  each machinery site allocates the fixed label group its shape needs, and
  a label lands unprinted when its word either falls through (a loop exit)
  or takes an in-line form that needs no name (a pointer-update routine
  absorbed into counter-0 text). Stage 2 pins the exact rule
  instruction by instruction during the listing diff, the D5.1 decode
  method; whichever mapping reproduces 084–093 exactly amends this entry
  with the rule and the evidence. A design that assumes a dense counter is
  wrong by construction.

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
  and `BSS` lines is pinned against the region golden in stage 1; this
  entry records the principles, and the golden records the answer. The
  region golden is transcription-checked against the page scans before it
  is committed (the M3-22 discipline, two pages).
- **M4-7.1. The stage-1 golden holds 91 rows** (Jack's call,
  2026-08-05). The golden runs from `USE 0` through LOC 00164. It does
  not hold `USE 1` or `BGN 2,PI)1`. Both carry Location Counter 1's
  origin, which follows the procedure text, so no stage without verb
  generation can compute them. Stage 2 prepends the two rows.
  Before the golden was committed, the 89 body rows were diffed against
  the 90.05 transcription. The M3 storage output already reproduces
  every LOC value, every `OCT` and `BSS` row, and every label, with no
  mismatch. The storage map is therefore a print problem at M4, not a
  derivation problem.

## The symbolic listing pages

- **M4-8. One geometry, scan-measured.** The 90.05 transcription renders
  the object listing in two incompatible column conventions (lines
  669–1258 versus 1279–1851 of the transcription) — label at column 38
  versus 36, the `+n` offset left-aligned at 46 versus right-aligned
  ending at 44, mnemonic at 54 versus 48, and a four-space page indent in
  the second range only. These are artifacts of two transcription passes
  over one continuous printout, not compiler behavior: the M4-20 item (g)
  measurement finds one printed geometry on pages from both ranges,
  constant to half a character cell. Measured from the LOC column's first
  digit as print column 0: LOC at 0 (five digits), the OCTAL word at
  7–21, CNTRL at 25–29, labels at 34, the `+n` offset right-aligned
  ending at column 42, the mnemonic at 49, the operand at 56. A labeled
  line prints no `+n`, and a long label overruns the offset zone. The
  page head prints on the same grid — DATE at 0, PAGE at 83. The golden
  is therefore built from the transcription's *content* and the scans'
  *geometry*: stage 2 renders every page in the measured geometry and
  verifies the result with a blind transcription pass (M3-22 pattern)
  before the golden is committed. The transcription
  itself is never edited (it is read-only), and the golden is not
  "regularised" against it — the scan measurement decides.
  Line-form rules the transcription attests and the printer implements:
  - Three OCTAL renderings: twelve solid digits for `OCT` words;
    `OOOO FF T AAAAA` for type-B instructions; `P DDDDD T AAAAA` for
    prefix-type words (PZE, MZE, TXI, TXH, TXL, IOST, BSS, USE, ORG).
    *Amended 2026-08-09, stage 2: a fourth rendering, `OOOO FF DDDDDD`,
    prints the low 18 bits as one group where the type-B form splits a
    tag from an address. Three sites carry it, all on listing page 20:
    `RIR 777777` at LOC 01240, `SIR 000001` at 01247, and `RFT 000001`
    at 01251. Their operand is one 18-bit sense-indicator mask, not a
    tag and an address, and the print does not split it.*
    *Confirmed 2026-08-10, chunk A7. Two readers transcribed PDF p. 211
    independently, neither knowing of the other, and both print all
    three sites in this form. The rendering is a scan reading, and stage
    2 may depend on it.*
  - The CNTRL column prints the word's 5-bit object-deck control group
    (M4-16). `USE`, `BSS`, and `ORG` lines print CNTRL 00001 with their
    control word in the OCTAL column (the `OP A` form of [J 90.03.03]);
    `BGN` prints its LOC only — no OCTAL, no CNTRL; the end-of-text line
    prints 01111.
  - A name of 15 or more characters prints alone and pushes the
    instruction to the next line: the 15-character INTERNAL.TOTALS
    breaks while 14-character names print inline, matching the
    15-column label field. [J 90.02.02] says "exceeds 15" of statement
    names; the attested break is at 15 exactly, and the print governs.
    Two labels on one word print one label per
    line, the word on the last (six attested sites).
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
  - `SYS)n` and `IOC)n` print the decimal n in the address field, flagged
    external in CNTRL. A file name prints as 04000 plus its loader-card
    file number.
  **Amended 2026-08-05, stage 1.** A second scan pass measured the
  character grid of PDF pp. 199–200 and confirmed every column above.
  It confirmed on ink one reading this entry already recorded, and
  settled the two it left open:
  - The `+n` offset is right-aligned, as recorded above. Page 200 holds
    the only discriminating evidence, the two-digit offsets `+10` to `+23`.
    Each starts one column to the left of a single-digit offset. The
    transcription prints them left-aligned, which is an artifact.
  - A broken long-label line prints its instruction at the normal
    columns, the mnemonic at 49 and the operand at 56. The LOC, OCTAL,
    CNTRL, and label fields stay blank. Both attested sites give the
    same result: DEPARTMENT.TOTAL on p. 199 and INTERNAL.TOTALS on
    p. 200. The transcription indents the second line two columns,
    which is an artifact.
  - The column header centers each of its first three names over its
    field. The reading held to one column, so the stage-1 golden
    excludes the header; the 2026-08-09 amendment measures it.
  The two page scans differ in horizontal registration. Measure each
  page against its own LOC column, never against the other page.
  - Page furniture: the `LOC OCTAL CNTRL SYMBOLIC` column header prints
    once, on the first object page. The transcription recorded one blank
    line after each page head and one after the column header; the M4-20
    item (e) measurement resolves two blank lines on PDF p. 208, so the
    per-page blank counts are
    still taken from the scans during the stage-2 verification pass.
    **Amended 2026-08-09, chunks A2 to A4.** Seven measured pages are now
    corrected in the conversion itself, under Jack's option B: each chunk
    authorizes its own pages. Listing pages 9 to 13 and 21 hold two blanks
    after the head, and listing page 8 holds three.
    **Amended 2026-08-10, chunk A5.** Listing pages 14, 15 and 16 hold two
    blanks as well, under the same option B.
    **Amended 2026-08-10, chunk A6.** Listing pages 18 and 19 hold two, and
    listing page 17 already held two from a 2026-08-05 measurement, which
    its reader confirmed without knowing of it. The five unverified
    pages still hold one, so a page's blank count remains a scan
    measurement and never a read of the conversion.
    **Amended 2026-08-10, chunk A7.** Listing pages 20, 22 and 23 hold two,
    and the conversion now carries all three, under the same option B. Two
    pages are left unmeasured, 24 and 25, and both still hold one.
    No blank line separates routines, the storage map
    from the code, or the pool from the end-of-text line. The
    listing closes with that line, one blank line,
    `THE LAST LOADER CONTROL CARD PUNCHED IS`, the `*CTEND` card, and
    `DONE`.
  **Amended 2026-08-09, stage 2. The page frame is pinned to the byte,**
  on the scans, field by field. Item (g)'s one geometry is unchanged;
  this adds precision to it. The column header prints `LOC` at 1,
  `OCTAL` at 12, `CNTRL` at 25 and `SYMBOLIC` at 58, which is the
  stage-1 reading; the transcription held 0, 11, 26 and 54, wrong at all
  four, and is corrected 2026-08-09 under Jack's authorization. The
  header's grid origin is the LOC column's first digit, so `LOC` sits one
  column right of the digits below it; the correction adds that column
  and does not restore the flattened left margin, which M1-15 records.
  The page head is the source listing's head unchanged, so stage 2
  calls the builder in `lib/src/listing/listing.dart` and writes no
  second template; `m1-front-end.md` M1-16 as amended holds the measured
  columns and the evidence. It also refuted the head this project
  printed, and the golden listing carries the correction. The per-page
  blank counts stay with the verification pass.
  **Amended again 2026-08-09, stage 2. The target is verified before any
  code generates against it** (Jack's call, with M4-1's chunking). This
  entry had stage 2 render the listing and then verify that render blind.
  That order spends the nineteen-page pass again each time a generator is
  wrong. The order is now: build the target from the transcription's
  content and this entry's geometry; verify it page by page against the
  scans; then generate against the committed file. The formula does not
  change. The transcription supplies content, the scans supply geometry,
  and a scan measurement still decides a disagreement.
  The target file is `test/fixtures/90.05-object-listing.target`. It is
  scaffolding, not a second oracle. Jack's ruling of 2026-08-09: the
  golden stays the oracle of record, and the target buys resumability
  alone. B7 deletes it, once `test/goldens/90.05-payroll.storage-map` has
  grown into the whole object listing.
  A disagreement takes one of two routes, and this is what makes the page
  chunks independent. A wrong target line is ours to correct, in the
  corrections table. A wrong conversion line becomes an erratum candidate
  in HANDOVER; it waits for Jack and blocks no other page. The pass also
  settles each page's own blank-line count, which this entry leaves open.
  **Amended 2026-08-09, chunk A3. The page body is a frame of 57 line
  slots.** On each of the four verified pages — listing 8, 9, 10 and 21 —
  the last content line sits in slot 57, with the head as slot 0. A page
  that prints no furniture blanks slots 1 and 2 and prints 55 content
  lines. Page 8 prints the column header: it blanks slots 1 to 3, prints
  the header at 4 and a blank at 5, and prints 52. Stage 2 lays out a
  page by the frame, not by a line count. Four pages of eighteen carry
  this, and chunks A4 to A8 test it. Listing page 19, PDF p. 210, is the
  one page whose transcription would break it: it holds 54 content lines.
  `test/fixtures/90.05-object-listing-notes.md` holds the measurements.
  **Amended 2026-08-09, chunk A4.** Seven pages of eighteen now carry the
  frame. Listing pages 11, 12 and 13 each print two blank slots and 55
  content lines, and each ends in slot 57. Their 165 content lines carry
  no content correction. Chunks A5 to A8 test the remaining eleven.
  **Amended 2026-08-10, chunk A5.** Ten pages of eighteen now carry the
  frame. Listing pages 14, 15 and 16 each print two blank slots and 55
  content lines, and each ends in slot 57. Their 165 content lines carry
  no content correction. Chunks A6 to A8 test the remaining eight.
  These three pages add one check no per-page reader could run: their
  location ranges are contiguous with each other and with chunk A4's last
  page, so six pages run unbroken from 00264 to 00771.
  **Amended 2026-08-10, chunk A6, and the frame now has no exception.**
  Thirteen pages of eighteen carry it. Listing page 19, the one page whose
  transcription said 54 content lines, prints 55: the transcription had
  joined two printed lines into one. Stage 2 therefore lays out every
  object page by the frame and never by a line count. Chunks A7 and A8
  test the remaining five, and listing page 25 is the last page of the
  listing, where a short count is expected.

- **M4-8.1. An over-long label pushes its instruction to the next line.**
  *Recovered from the print 2026-08-10, chunk A6; Jack's ruling the same
  day.* The label field ends at print column 48 and the mnemonic column is
  49. Where a label reaches column 49, the 1962 printer put the
  instruction on the following line, at the ordinary mnemonic and operand
  columns, and left the label alone on its own. Stage 2 must do the same,
  or the listing diff fails on that page.

  One site in the program exercises the rule: `WITHOLDING.TAX.ROUTINE` at
  LOC 01220 on listing page 19, which is 22 characters. Three other labels
  reach column 49 and each stands alone on its line with no instruction to
  displace, so they settle nothing about the wrap and are consistent with
  it.

  Nothing in either manual states this behaviour. It is read off the
  artifact, which makes it an M4-8 geometry fact and not a language fact:
  it stays out of the definition. The line count is the visible
  consequence, and it is what makes the frame hold on all thirteen
  measured pages.

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
     character count. Attested: the three SYS)243 statements and the
     SYS)244 zero-fills of statement 188; the SYS)245 HIGH.VALUE store of
     statement 197.
  2. **Alphameric class to alphameric class, in-line forms.** A one-word
     literal into a word-resident field: the mask-insert five-word shape
     `CAL mask / ANS target / COM / ANA literal / ORS target` (statements
     193 and 196). Whole-word fields of equal extent: word moves,
     `CAL source / SLW target` per word (statement 202). The general
     in-line bound is ours, pinned at the diff: in-line when both fields
     are word-addressable and the move is word-whole or single-word
     masked; otherwise the SYS)239–242 character movers through a MOVPAK
     dispatch entry.
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
     per the SYS)185 feature table; the digit count rides in the `AXT`
     (the sample varies `edit` between 4 and 12 while the `AXT`
     holds 6).
  4. **CORRESPONDING**: expand `correspondingPairs` in data-description
     order, one ordinary move per pair, the written subscript appended on
     its side (D4.12). Attested: statements 199, 208, 220, 227;
     statement 199's expansion inside END.OF.RUN runs 32 words
     (LOC 00373–00432).
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
  The MOVPAK dispatch entries and their return-skip convention: SYS)179
  (both descriptors in the calling sequence, resume 3,4), SYS)180 (target
  only, 2,4), SYS)181 (source only, 2,4), SYS)182 (both preset, 1,4) —
  resume offset is parameter-word count plus one ([J 90.02.14]–15).

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
  - Parenthesized subexpressions park in section-qualified `RS)` cells,
    two words each (D4.8; [J 90.02.03]).
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
    digits, no scaling step (M3-20). The exact in-line lookup and update
    shapes are pinned
    against the sample's subscript sites during the diff.
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
    proceeds silently — that silence is attested (D4.2). Non-historical,
    amendable; the first ON OVERFLOW evidence found amends this entry.

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
    continuation. Elide the trailing slot — at most one — when its
    target is the word immediately after the vector; an interior slot
    with that target prints the relative form instead (`TRA *+1` at
    statement 219, LOC 01306; `TRA *+3` at statement 203). GT with both
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

## GO TO

- **M4-12. Transfers.** An unconditional GO TO is one `TRA` word. A GO TO
  that is a statement's whole content and coincides with a generated join
  folds onto the join label (attested: GN)065 carries statement 195's
  `TRA`). The conditional form is M4-11's WHEN machinery in source order,
  fall-through after the last clause. The assigned form
  `GO TO (p1,…,pn) ON index` (ours; no sample instance): take the index's
  integral part per its declared scale, run the D5.5 range test — emitted
  object-time bounds check, 1 through n, out of range falls through to
  the next clause with no message — then transfer through an n-word `TRA`
  vector indexed by an index register. D5.5's documented omit option is
  the non-historical flag `--no-goto-range-check`, recorded here; it
  removes the bounds test only.

## DO

- **M4-13. The DO generator, and the D5.1 decode.** The linkage is the
  verified Q40 return-cell shape:
  - Every procedure any DO addresses gets a one-word return cell as its
    first word, the placeholder `AXT 0`; the decision is call-site-driven
    — a plain unlabeled paragraph gets a cell when a DO names it
    (attested: END.OF.MASTERS), and a GO TO-only target gets none
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
    ADD PI)1 / STO PI)1 / CLA CP)+8 / SUB INDEX / TPL GN)085` — it forms
    r − i and branches on sign, exactly the shape D5.1 named as the
    magnitude exit ("an equality exit would branch on zero"). The loop
    runs while i ≤ r after each increment; a +0 result (i = r) transfers,
    so the body runs for i = r; normal exit leaves i at the first value
    past r — r + q when q divides r − p exactly. D5.1's
    pre-committed amendment is applied in `decisions.md` with this
    citation, and the codegen switch keeps the equality alternative one
    line away. Consequences: the at-least-once rule holds (entry precedes
    any test, [J 90.01.02]); an overshooting step terminates (first i > r
    exits), so the equality reading's non-termination hazard is gone; a
    zero or wrong-signed q with p ≤ r still never terminates (with
    p > r the first test already exits), and the emulator reproduces
    both faithfully.
  - Literal p, q, r bake into pool constants; a named parameter is read
    from its field where the expansion reads it (initialization reads p at
    entry; the increment block reads q and r each pass — F's expansion
    order; §8.5 Open Question 36 disposition, M4-21).
  - `DO … EXACTLY n TIMES` (no sample instance, ours): the same
    patch-once machinery with a generated counter cell, counting down from
    n with the magnitude exit.
  - Multi-index DO: nested increment-and-test blocks, innermost first,
    rightmost index varying fastest; the outer index increments, never
    reassigns (D5.2).
  - USING and GIVING lower as MOVEs around the bare DO — parameters in
    before the call, results out after it, full MOVE editing per pair
    (M3-19; [F p. 53]'s expansion).
  - Recursion is not guarded: a second activation overwrites the cell,
    and the emulator reproduces the wild return (D5.7). Nested
    non-recursive DO is unrestricted.
  - `--pedantic` sites (D11.4; ids from M4-18): constant p, q, r whose
    (r − p) is not a whole multiple of q, or q zero or wrong-signed
    (D5.1); a static cycle in the DO call graph (D5.7).

## STOP and the statement stamps

- **M4-14. STOP and the number stamps.** STOP RUN emits the D2.7 shape,
  three parts in order: the message call `TSX SYS)178,4` with two
  `PZE CP)+a,,CP)+b` words carrying the BCD statement number and the
  words ` STOP ` / ` RUN  `; the implicit close-all pair
  `TSX SYS)177,4 / PZE IOC)1`; then `TXI IOC)40,0` — no halt
  instruction. The sample's leading SYS)177 pair at LOC 00517/00520
  belongs to the source's separate `CLOSE ALL FILES` clause (M4-15's
  shape), not to STOP RUN (D2.7). STOP n emits the
  SYS)178 call with type NNN and no close-all and no monitor transfer;
  the halt lives in the SYS)178 handler (D2.7). The statement-number
  stamps: each GET sequence opens with a `TXH CP)+a,0,CP)+b` word — a
  tag-0 no-op holding the statement number in BCD (four attested sites,
  statements 188, 190, 191, 194). The stamp is part of the GET calling
  sequence and of SYS)178's parameters only; no other statement emits one
  (attested silence elsewhere). Omitting them would shift every following
  address, so they are not optional.

## The I/O shapes at M4

- **M4-15. Attested shapes, deferred runtime.** M4 emits the I/O verbs'
  calling sequences so the listing and addresses reproduce; M5 makes them
  run. The shapes: the run frame opens with `TSX SYS)175,4 / PZE IOC)1`
  (open all) at the entry word GN)000; GET is the stamp word, then
  `TSX IOC)8,4 / PZE file,,SYS)260 / PZE atEnd,,SYS)283 /` the buffer
  descriptor word `BL)n,,len`, then the AT END out-of-line block per D6.6
  (SYS)265 in place of the AT END exit when the clause is absent; the
  ON ERROR decrement per the file's environment); FILE of a
  working-storage record is `TSX IOC)9,4 / PZE file,,0 / IOST record,,len`;
  FILE of a located record patches its own IOST word first —
  `LXA BL)n,4 / SXA GN)a,4` then the call, GN)a labeling the IOST word
  (attested, statement 208). CLOSE ALL FILES is the SYS)177 pair. The
  per-file bindings codegen needs (which BL serves which file, record
  lengths) come from the environment binder; `SemanticResult` exposes what
  M4 needs (the binder's per-file maps are internal today — stage 2 adds
  the exposure).

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
    00003), so the zeros are deliberate ink. Consequence, recorded: the
    EQU'd subscript-base words are byte-blind — the byte selection for
    the RETPREM (POS) and INSPREM (POS) lookups lives in the generated
    lookup code, not in the base word — and the reproduced pool prints
    the two identical words. This closes the review backlog's RETPREM
    pointer anomaly: nothing is mis-transcribed.
  - **(b) LOC 01612 (PDF p. 215) — a transcription error, corrected
    2026-08-05 under Jack's authorization.** The print reads
    `CLA 5)NETPAY`; the transcription's `4)NETPAY` misread the 5. The
    octal address 00133 is transcribed correctly, and the line is the
    regular grand-total accumulation shape. The listing corroborates the
    scan on its own: 00133 pairs with `5)NETPAY` at both other sites
    that reference it, LOC 00423 and LOC 01614. The golden prints
    `5)NETPAY`.
  - **(c) LOC 01327 (PDF p. 212) — confirmed as printed.** The word is
    `TRA SYS)267,0,0`, octal `0020 00 0 00413`, inside a SYS)180
    sequence where every parallel site prints `TXI SYS)267,1,n`. The
    1962 ink is unambiguous, so the listing reproduces it byte for byte.
    The execution reading is deferred: the word sits in a parameter
    position the SYS)180 handler decodes, and what the 1962 runtime made
    of it is discovered when the sample first runs (M6); the finding
    amends this entry.
  - **(d) LOC 00702 (PDF p. 206) — confirmed verbatim.** The label-only
    `GN)075` line, the out-of-order `GN)088 EQU CP)+37` line between it
    and the instruction, and the unlabeled `AXT GN)086,4` word printing
    `+1`: all as transcribed. The EQU-resets-the-offset-counter rule
    (M4-8) is attested ink, and the first word after a reset prints
    `+1`.
  - **(e) The PDF p. 208 page head — a transcription error, corrected
    2026-08-05 under Jack's authorization.** The print is one head line
    in the normal order (`DATE … ID. CT PUBLICATIONS … PAGE 17`),
    followed by two blank lines; the page is scanned with a one-degree
    tilt that drops the right half of the line by two thirds of a line
    pitch, and the transcription split it into two transposed lines. The
    golden prints one line. The correction gives the line PDF p. 209's
    field grid, per item (g). It restores a reading, not a column: take
    columns from the scans (M1-15), and read its two blank lines as this
    page's alone.
  - **(f) The GET descriptor mnemonic — the two artifacts genuinely
    differ.** The listing prints `IOCTN*` (read at three sites on PDF
    p. 201; the fourth glyph is a T at 40×, against a D control glyph
    from GET.DETAIL); the typeset [J 90.02.04] prints `IOCDN*`. Each
    transcription is faithful to its own source, so neither is an
    erratum. The compiler emits the listing's `IOCTN*` — the listing is
    the codegen oracle — and this divergence is recorded here, not in
    the definition, because it is a print fact, not a language fact.
  - **(g) The column geometry (PDF pp. 203 and 212) — one geometry.**
    Pages from both transcription ranges print identical grids, the
    M4-8 table, constant to half a character cell; the apparent two
    conventions came from opposite scan distortions on the two pages,
    and the pasted listing block sits at a different offset on each
    manual page — page furniture, not print.

## Open Question dispositions

- **M4-21.** Decided by this walk and annotated in place in the
  definition's list:
  - **Q37** (the index after a completed loop): the M4-13 decode gives
    the generated answer — normal exit leaves i at the first value past
    r (r + q when q divides r − p exactly); a GO TO out
    leaves whatever the last increment stored. Annotated with the decode
    citation; §8.5.5-a takes the matching dated annotation (the compiled
    exit is a magnitude test; F's printed expansion stays the manual's
    text).
  - **Q26 residue**: the ACL half-adjust runs away from zero for
    negatives by 7090 semantics; no negative case is attested, and the
    reading stays flagged inference (D4.1(a) unchanged). Rounding cannot
    arm SYS)130 on the arithmetic path (D4.1(f)).
  - **Q27 / Q28 residues**: closed for implementation by M4-10's recorded
    model (store-site-only downscale, ON OVERFLOW as an inline pre-store
    test); the language questions stay open in the list, pointing here.
  - **Q31**: SYS)131 is set by the numeric movers and read by nothing;
    reproduced exactly (D4.3).
  - **Q33**: multi-target stores run left to right in written order
    (D4.8); observable only on REDEF overlap; annotated as our decision.
  - **Q34**: DO USING/GIVING transfers are MOVEs (M3-19), so they take
    full MOVE editing; annotated.
  - **Q36**: named q and r are re-read each pass by the increment block;
    literals bake into the pool (M4-13); annotated as the generated
    behavior.
  - **Q24**: no object-time check exists on a QUANTITY IN value against
    its reservation ([J 90.01.02]'s policy); the emulator reproduces the
    silent overrun. Annotated.
  - **Q38, Q39, Q42 residue, Q43**: Q42's WHEN fold shapes are decided
    (M4-11); Q38 (msg 170's trigger), Q39, and Q43 stay open and block
    nothing in M4.

## Staging

Four pull requests, each green alone (M4-1): the assembly model with the
storage-map print; the verb generators with the full listing; the object
deck, loader cards, and loader; the machine assembly with the compute
handlers.

*Amended 2026-08-09: stage 2 is chunked into A0 to A8 and B1 to B8, so it
takes more than one pull request. M4-1 holds the chunks and the reason.*

## Oracles

- Stage 1: the storage-map region of the 1962 listing, byte for byte,
  scan-checked before commit.
- Stage 2: the full listing diff, PDF pp. 198–216, byte for byte, after
  the M3-22-pattern blind scan verification; the 90.05 job deck compiles
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
[J 90.03.03]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#3-file-check-entry-specifications
[J 90.08]: ../../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008
