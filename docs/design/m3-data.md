# M3 — Data semantics design and decisions

*Updated 2026-08-04. This document records the M3-specific design decisions
the way `m2-parser.md` records M2's. The language facts come from
`docs/comtran-language-definition.md` (cited by §), the manuals (cited as
`(F p. N)` / `(J xx.xx.xx)`), and the locked decision slate
(`docs/design/decisions.md`, cited as D-numbers). This document adds no
language claims; where the sources leave a semantics gap, the entry below
closes it and says so.*

*Entry IDs are append-only. A new entry takes the next free number and goes in
the section it belongs to. The code cites these IDs, so no entry is ever
renumbered. Use the index below to find one.*

| Entry | Section |
|---|---|
| M3-1 | Scope and stages |
| M3-2, M3-3 | Pipeline position and the data map |
| M3-4, M3-5 | Field types and pictorial measurement |
| M3-6, M3-7 | The storage allocator and initial images |
| M3-8 | The dictionary, GN)nnn, and the LOC column |
| M3-9, M3-10 | Name resolution and reference legality |
| M3-11 | Record classification and the environment binder |
| M3-12 | Capacity checks |
| M3-13 | Diagnostics |
| M3-14 | The storage oracle |
| M3-15 | Open Question dispositions |
| M3-16 | Diagnostics |

## Charter

M3 is the semantic layer between the parser and code generation. It gives the
parsed program meaning: field types, lengths, storage offsets, initial
contents, a program dictionary, resolved names, and reference legality. The
90.04 catalog's data and resolution messages become live diagnostics. M4
starts from a fully resolved program and generates code only.

## Scope and stages

- **M3-1. Full semantic layer, staged (Jack's call, 2026-08-04).** M3
  delivers the data mapper, the dictionary, name resolution, reference
  legality, and the environment binder. The narrower reading — data division
  only — was rejected: M2-3 hands name resolution and the legality tables to
  M3 by name; D11.4 assigns D4.13's sites to M3; the message checklist tags
  its reserved rows "M3"; and storage mapping is wrong without the
  environment binder, because located records take no program storage
  (M3-11). Three stages, one pull request each, each green alone:
  1. **The data mapper** — field typing, pictorial measurement, the storage
     allocator, initial images, data-division diagnostics, the environment
     binder, and the storage oracle (M3-14).
  2. **The dictionary and resolution** — the dictionary, procedure and
     environment name resolution, CALL synonyms, reference legality,
     CORRESPONDING pairing, capacity checks, and their diagnostics.
  3. **The listing extension** — GN)nnn names and the LOC column, with the
     golden rewrite (M3-8).

## Pipeline position and the data map

- **M3-2. A separate phase over `ParseResult`.** The semantic layer is
  `runSemantics(ParseResult) → SemanticResult` in a new `lib/src/data/`
  component — the directory STR-006 anticipated. It never re-reads cards,
  with one recorded exception: literal values are re-read from the card
  images, because M1 token text uses display placeholders (M1-9 directs
  this). `bin/comtranc.dart` becomes deck → `runFrontEnd` → `runParser` →
  `runSemantics` → `writeListing`, per job. `runSemantics` follows D10.2:
  it catches `StopCompilation` itself and returns a partial result with a
  `stopped` flag, and the driver skips it when an earlier phase stopped.
  The exit code keeps D11.2's meaning — 0 unless a job reaches severity
  5. The D11.4 invariant holds: `--pedantic` adds diagnostics and changes
  nothing else.
- **M3-3. The data map.** `SemanticResult` carries, per job: the annotated
  data tree (each `DataItem` gains a semantic record — resolved field type,
  character length, digit count, scale, sign convention, precision, word and
  byte offset within its area, replication stride, initial image), the area
  table (one entry per top-level item: extent in words, storage class,
  initial words), the record table (fixed or variable, located or
  transmitted, owning files), the dictionary (M3-8), and the diagnostics.
  Nodes flagged `recovered` are mapped but generate no oracle claims (M2-5
  precedent).

## Field types and pictorial measurement

- **M3-4. The six-way chart is the classifier.** Every formatted field takes
  one of the six [J 02.05.05] types: alphameric, external decimal, internal
  decimal, edited, floating point, scientific decimal. The 90.02 appendix
  corroborates the same classes as MOVPAK's field kinds, and adds the
  attested split of internal decimal into right-justified (register form,
  whole words) and not-justified (character-counted area) — [J 90.02.10],
  [J 90.02.26]. Classification rules, in order:
  - A field with no pictorial is a group ("non-format") field: alphameric,
    length the sum of its subfields (D3.3; [J 02.05.06]). The only legal lower
    level under a formatted field is a COND entry ([J 02.05.06]).
  - Any of `8 * . , $ + -` in the pictorial, or BLANK WHEN ZERO, makes the
    field edited ([J 02.05.05]; D3.2). Note 2 of the chart gives edited fields
    both sign forms: a reserved sign position or a rightmost overpunch.
  - `F` with mode I is floating point (`FF` double precision); `F` with mode
    E is scientific decimal, maximum 16 fraction digits ([J 02.05.05] notes).
  - Digits only (with `V`, `S`, `(n)`, an optional rightmost overpunch):
    external decimal under mode E, internal decimal under mode I
    ([J 02.05.04]–05). External decimal admits no free-standing sign
    character (chart note 1).
  - `A` and `X` are synonymous; both make the field alphameric
    ([J 02.05.04]).
  - Mixed A/9 pictorials are treated as alphameric ([J 90.01.03]). The manual
    names no message; the silent downgrade is reproduced by default and
    `--pedantic` notes it (M3-13).
  - A mode-versus-pictorial conflict the chart does not define — edit
    characters under mode I, `FF` under mode E — draws msg 32 ("MODE AND
    DATA DESCRIPTION CONFLICT. 'NAME.1' FORMAT USED."); an illegal
    combination of format characters draws msg 33. Both ids are the
    checklist's reserved M3 rows for exactly these checks (M3-13).
- **M3-5. Pictorial measurement.** From the pictorial the mapper computes:
  character length (each format character one position; `(n)` expands;
  `V` and `F` reserve nothing, [F p. 80] states both, and `S` likewise per
  [F p. 80]'s `999SSS` example; `. , $ + -` and digits reserve one each),
  digit count, scale (from `V` position and trailing `S`
  run; internal decimal realizes `V` as a scale factor on a binary integer,
  [J 90.02.27]), sign convention (90.02's attested codes: external decimal 0
  none / 1 overpunch minus / 2 overpunch plus, [J 90.02.15]; edited fields the
  seven-valued set, [J 90.02.17]), and precision (more than 10 digits is
  double precision, `FF` is floating double — [J 02.05.06]; the 10-digit
  boundary matches the 10¹⁰ scaling constants of [J 90.02.12]–13).

  **The overpunch is a zone letter at punch level.** A minus overpunch over
  digit d punches the same holes as the letter J–R for d = 1–9; a plus
  overpunch punches A–I (`lib/src/chars/char_code.dart` zone rules; D8.2
  resolved the chart row by scan). A pictorial written `999̅` therefore
  reaches the scanner as `99R`, and a constant `123̅` as `12L`. Recorded
  decision: in the description field's leading run, a single trailing
  character from the overpunch letter sets, following characters that are
  all numeric format characters, reads as an overpunched digit — a sign
  convention plus a digit position — not as a name character. Anywhere else
  a zone letter makes the run a name ([J 02.05.06]). M2's format-run
  recognizer (`data_parser.dart`, `data_lexer.dart`) is amended to match in
  stage 1, and M2-3 carries the dated amendment; the sample exercises no
  signed field, so the golden is unaffected. Constants are checked against the pictorial's sign convention
  the same way ([J 02.05.07]'s `999̅` / `123̅` example).

## The storage allocator and initial images

- **M3-6. The allocator.** Storage is words of six 6-bit characters; the
  character is the smallest describable unit ([J 90.05.01]). Addresses are
  (word, byte 0–5) pairs — the attested descriptor form of every pointer
  word ([J 90.02.05], 90.02.10–11). The allocator walks each data group in
  source order and assigns offsets with these rules:
  - **No justification:** the item packs immediately after the previous
    reservation, within the same word where possible ([J 02.05.04]). Fields
    pack across level boundaries with no padding — MASTER's TRIGGERS fills
    the half word NAME leaves ([J 90.05] listing PDF p. 192, statements
    6,00–7,00, against the [J 90.05.02] word table; [J 90.02.05]'s
    two-field example).
  - **Left justification:** reservation restarts at the leftmost byte of a
    new word ([J 02.05.04]). Always effective; the default at the highest
    level in the program, so every top-level item starts a new word (D3.5;
    [J 02.05.01]).
  - **Right justification:** effective only with an explicit format (D3.5).
    External mode: a new word, the last character in the final byte
    ([J 02.05.04]). Internal mode: one whole word, two if double precision,
    sign in the sign bit ([J 02.05.04]) — one word per field regardless of
    digit count, as the sample's three `BSS 9` areas attest ([J 90.05]
    listing, storage section).
  - **Internal, left or unjustified:** the least multiple of 6 bits holding
    the digits and a sign bit at the field's leftmost bit ([J 02.05.04]).
  - **Quantity replication:** the entry and its subordinates lay out once,
    then repeat; the stride is the element's (word, byte) extent. TABLE's
    twelve 2-word pairs attest whole-structure repetition ([J 90.05] listing,
    statements 143–172 against words 00135–00164).
  - **REDEF:** save the counter at the REDEF line, allocate the redefinition
    over the target's origin, restore on termination (D3.4, D3.6;
    [J 02.05.02]). The redefinition allocates no new storage; TABLE.ITEM has
    no area of its own in the dump.
  - **Record end:** a partial final word is blank-filled automatically
    ([J 90.05.02] and 90.05.04: "3 blanks (supplied automatically)").
  - **Area extents** round up to whole words; each transmitted top-level
    item is one area, allocated in source order (Location Counter 0 holds
    "storage reservation for fixed location Data areas" in source position —
    [J 90.02.01]). M3 assigns area-relative and program-order offsets; M4
    binds them to object addresses.
- **M3-7. Initial images and constants.** The mapper computes each area's
  initial words: constants converted to their stored form, automatic blank
  fill, and no image for wholly uninitialized words. Conversion follows
  [J 02.05.06]–07:
  - Alphameric: no pictorial needed; the literal's length is the field's.
    With a longer pictorial, left-justify and blank-fill; with a shorter
    one, fill from the left, discard the rest, msg 59 — the reserved
    alphabetic-constant row; msg 51 covers the numeric conflicts below
    (M3-13).
  - A literal-only entry with no pictorial and no type is an alphameric
    constant of the literal's length — the attested form of TABLE's
    external words (GN)034's `'080060'`, [J 90.05] listing).
  - Blank shorthand: when the pictorial gives the length, the quoted blanks
    need not fill it ([J 90.05.04]).
  - External decimal: pictorial length must equal the constant exactly, and
    the sign conventions must match ([J 02.05.07]); a violation draws
    msg 51 (M3-13).
  - Internal decimal: right-justify into the pictorial's capacity; a larger
    constant is left-truncated, converted, stored, and diagnosed with
    msg 51 ([J 02.05.07]; M3-13). Signs: leading, trailing, or none.
  - Forbidden: in an edited field (msg 57), in a located input area, after
    a variable length field, inside a REDEF's extent ([J 02.05.06]; D3.6).
  The stored forms are testable words: TABLE's internal words hold binary
  rates, its external words BCD characters, and CHECK's constant words the
  attested octal images (M3-14). Word images bind to the emulator's ED-1
  36-bit word model and the D0.6 BCD tables — no parallel representation.

## The dictionary, GN)nnn, and the LOC column

- **M3-8. The dictionary allocator prints (Jack's call, 2026-08-04).** The
  1962 listing prints two things M1 deliberately left blank: generated
  names and the five-octal-digit address field (M1-15, amended this date).
  Both are M3's, and both print from one model:
  - **GN)nnn.** Every unnamed data entry takes the next generated name in
    source order — GN)001 through GN)056 in the sample, GN)057 for the
    REDEF line — and prints it in the name field. The number 000 is
    reserved for the program entry: it prints on the first procedure
    sentence (statement 187), which the object listing labels GN)000 at
    the entry word, and later generated procedure labels continue the
    counter (GN)058 on, [J 90.05] symbolic listing). The 000 numbering is
    out of source order; the dictionary-word allocation below is strictly
    source order. An unnamed entry with a generated name is addressable
    by nothing: GN names never enter the programmer dictionary and
    resolve no reference.
  - **The LOC column is the dictionary address.** The counter starts at
    the base the print shows (71175 in the sample) and allocates in
    source order: one word per data-division entry, named or generated —
    a GN-named entry consumes its word without printing it — two words
    per RECORD name, and one word per CALL synonym and per procedure
    name. Environment entries take no word: the sample's seven file
    names print no LOC and consume none. The value prints on the line
    where the name completes: a continued data name prints it on the
    continuation line (statements 3,00, 21,00, 22,00, 103,00, 107,00),
    and each CALL line prints the word of the synonym it defines
    (statement 187,00's five lines, 71461–71465). What is attested is
    the printed column; its reading as a dictionary address and every
    allocation rule here are non-historical reconstructions, verified
    against the full data division — base 71175 (MASTER's own two
    words) through GN)000's word 71460, every printed value predicted.
    The stage-3 golden rewrite re-checks all pages against the scans.
    Fallback, recorded: if the model fails to reproduce any page, the
    column ships blank (GN names only) and this entry takes a dated
    amendment.
  - The golden listing is rewritten once, in stage 3, against
    scan-measured pages 192–197. The M1-15 geometry (field positions) is
    unchanged.
- **M3-9. Resolution rules.** The dictionary holds every programmer name
  with its level, position, and kind. Rules:
  - Qualification follows level and position only, REDEF-blind
    ([J 02.05.02]–03). Qualified names are barred from the Environment
    division and CRYPT ([J 02.03.03]; [J 02.08]).
  - Duplicate simple names are legal across structures; references
    disambiguate by left-qualification, and unresolvably ambiguous
    references draw msg 101/166 per site ([J 90.04]). Encounter order
    numbers duplicates, as the object listing's `1)C` / `2)C` attests
    ([J 90.02.02]).
  - A RECORD name must be unique, is never subscripted, and when defined
    in a section is not qualified by the section name (D2.5;
    [J 90.01.03]).
  - CALL synonyms follow D4.13 whole: unique old.name, no subscript, no
    qualification of a synonym; each synonym is a dictionary entry.
  - COND names bind to the nearest preceding formatted entry ([J 02.05.02]);
    the constant is checked against that field's format, and a mismatch
    draws msg 37 ("FORMAT ERROR FOR CONDITIONAL VARIABLE." — the
    checklist's reserved row; M3-13). Condition names resolve only where
    a condition may stand (D5.6 unchanged).
  - List-3 reserved words (M2-7's deferral) are barred as names only where
    the Environment division uses the word; the bar is resolved here.
  - CONTRL common areas stay unimplemented: the card parses, msg 176
    covers only a format error (D9.8), and a well-formed specification
    has no object effect and draws nothing ([J 90.01.04]).
- **M3-10. Reference legality.** With types resolved, the legality tables
  become checks: the MOVE/SET figurative and field-type charts
  ([J 02.04.01]–05; D4.6, D4.7, D4.9, D4.11), comparison rules including the
  non-format fold ([J 02.04.06]–07; D3.3), CORRESPONDING pairing (D4.12),
  function argument counts (msg 30), subscript count against declared
  dimensions (msgs 70, 71, 98; the three-subscript cap D3.1), variable
  length fields never compared ([J 02.04.07]), and edited-versus-alphameric
  comparison bans. Checks classify and diagnose only; code shapes stay
  M4's.

## Record classification and the environment binder

- **M3-11. Records bind to files before storage is final.** The binder
  resolves the environment division against the data division:
  - Every record on a FILE card must be a declared RECORD, and every
    filed/gotten record must be on a FILE card ([J 02.06]; [F p. 71]); SPECIF
    names its FILE card ([J 02.06.08]), POOL names its files, and buffer
    counts satisfy the stated minimums ([J 02.06.13]–14). Violations draw
    the checklist's reserved binder rows — msg 9 ("RECORD 'NAME.2' MUST
    BE ON A -FILE- CARD."), msg 16 ("'NAME.2' IS NOT A RECORD."), and
    their companions (msgs 13, 15, 17, 21, 195, 198) — never the M2
    card-format set, which is already enforced per card.
  - **Fixed or variable:** a record containing any QUANTITY IN field is
    variable length ([J 02.07.03]; §6.3). Consequences already bound:
    storage on maximum size; no fields after a variable array in the same
    hierarchy; no constants after a variable field; no REDEF involvement;
    control-word accounting stays with M5 I/O.
  - **Located or transmitted:** input records are located in buffers
    unless forced out — REDEF sharing with non-file data transmits the
    file's records ([J 02.07.05]); arrays force transmit under the field
    test ([J 90.01.01]). A record on any input file is located even when
    it is also filed to an output file — the sample's MASTER, updated in
    place, has no area. Records on output files only are assembled in
    program storage (CHECK at 00000 in the dump). A located record's
    fields get base-locator-relative offsets, byte 0 at the record head
    ([J 90.02.05]); it takes no BSS.
    *Amended 2026-08-04 (review): the sharer that forces transmit is
    data other than a record. Records REDEF'd together stay located
    whatever their files: the same-file case is [J 02.07.05] c-iii, and
    the cross-file case is deferred — "Records from different files
    which have been REDEF'd together will not be automatically
    transmitted by the field test processor ... SPANS or HOLD must be
    used." ([J 90.01.01]). SPANS or HOLD there is the programmer's
    duty; the binder adds no message for it.*
  - BLOCKSIZE range checks land here (D10.8(b) assigns both to the M3
    data mapper): record-fit draws the attested msgs 5 and 209; the
    over-9999 value has no attested message and takes a 930-range id
    per D7.1 (M3-13). Object-time checks (SYS)264) are M5's.

## Capacity checks

- **M3-12.** Capacity enforcement follows D9.7, Jack's binding call: each
  threshold sits at the printed "Appox-Max" number, over-rejecting in the
  unknown band above it, and the non-historical `--no-table-limits`
  switch is the only relaxation. The M3 tables ([J 90.01.05]): ~23
  hierarchy levels, ~85 array dimensions, ~90 positional indicators (one
  per unique subscripted reference, [J 02.04.07] — the CRYPT "Symbolic
  Register", [J 02.08]), ~25 QUANTITY IN specifications (msg 200, D9.7's
  reading of Q67), ~35 edited formats, ~3500 dictionary names. The
  three-level QUANTITY-nesting cap and three-subscript cap are language
  rules per D3.1 and take a 930-range id (M3-13).

## Diagnostics

- **M3-13. The message inventory.** Stage by stage, the checklist's
  reserved M3 rows flip to enforced, each with a test naming its message
  and severity (severities stay `severities.dart`-only, D9.2; the
  provisional calls in `severity-notes.md` stand unless a check proves one
  wrong, and any change edits that record first). New non-historical ids
  allocate from one sequence, 930,00 up — 900,00 through 929,00 are
  taken — one id per check, text tagged `(NON-HISTORICAL.)` (D9.7;
  D11.4's own-id rule). Default-mode checks in the sequence: the
  quantity-nesting/subscript caps (D3.1), a constant inside a REDEF
  extent (D3.6), the over-9999 BLOCKSIZE (D7.1), and any capacity
  overflow with no 1962 number. New `--pedantic` sites, D11.4 pattern,
  in the same sequence: the mixed-pictorial silent downgrade
  ([J 90.01.03]), a Quantity on an unnamed entry without named
  subordinates (Q18), D3.5's ineffective-R candidate, and
  D4.11/D4.12/D4.13's deferred notes. The 90.05 job deck stays clean in
  both modes.
  *Amended 2026-08-04 (stage 1): a constant inside a REDEF extent takes
  the attested msg 43,00, per D3.6 as amended the same day — it takes no
  930-series id. The sequence as allocated: 930 quantity nesting over
  three (D3.1); 931 BLOCKSIZE over 9999 (D7.1); 932 the REDEF-sharing
  forced transmit ([J 02.07.05] attests the transmit and a message, the
  id is ours); 933 the mixed-pictorial downgrade; 934 Quantity on an
  unnamed entry (Q18); 935 ineffective R on a formatless leaf (D3.5) —
  msg 39 covers the group case in default mode. Ids 933 to 935 issue
  under `--pedantic` only. See M3-16 for the other stage-1 message
  choices.*

- **M3-16. Stage-1 message choices (2026-08-04).** The splits,
  thresholds, and deferrals stage 1 fixed, recorded so stage 2 does not
  re-derive them:
  - Msgs 13, 15, and 16 print one catalog text. The split follows the
    M1-8 precedent: 13 for a FILE card that names no record; 15 for a
    name that resolves to nothing; 16 for a name that resolves to a
    non-record item.
  - Msg 209 covers an input card file with BLOCKSIZE under 24, and the
    binder repairs the value to 24. Msg 5 covers a bound record longer
    than its file's blocksize without HOLD or SPANS.
  - A blank Mode with a digit pictorial reads as external decimal.
    Attested: DETAIL HOURS `99V9` takes one character per digit in the
    90.05 storage section.
  - Msg 35 fires at the attested bound — a scientific fraction over 16
    digits — and at one derived bound: a right-justified internal field
    over 21 digits, the most the two register words hold. Msg 34 stays
    reserved; stage 1 attests no check for it.
  - Only a leading blank in a numeric constant reads as zero
    ([J 02.05.05] note 3); an imbedded blank draws msg 67.
  - Msg 36 recovery: the subordinate entries drop, and the formatted
    entry keeps its pictorial. COND children, REDEF markers, and
    redefinition heads are exempt.
  - Deferred to stage 2: the binder rows 8, 9, 10, 17, 19, 195, and
    198; the POOL and GROUP buffer minimums; the capacity counters
    (M3-12); the COND-value msg 37; the `DataItem.extras` judgment; the
    LABEL 14-word cap; and the no-fields-after-a-variable-array rule,
    which has no attested id.

## The storage oracle

- **M3-14. The `*DATA` section is the stage-1 acceptance test (Jack's
  call, 2026-08-04).** The 1962 object listing's storage section (printer
  pages 8–9, PDF pp. 199–200) attests, for every transmitted area of the
  sample: its word offset, its extent, and the initial octal value of
  every constant-bearing word. The extent prints directly only for the
  four bare `BSS` areas; a constant-bearing record's extent is derived
  from the next area's offset, and its interior unlabelled `BSS` runs
  are part of the image the fixture models — the fixture marks derived
  values as derived. A fixture transcribed from the page scans —
  offsets, extents, BSS runs, and OCT word values — is committed with
  stage 1, and a test asserts the data mapper reproduces all three for the
  90.05 deck: CHECK at 00000 through TABLE's 24 constant words ending
  00164. The print formatting of that section (BSS/OCT line selection,
  column geometry) stays M4's; the fixture holds values, not lines.
  Transcription follows the scan-measurement rule; the fixture cites the
  page images.

## Open Question dispositions

- **M3-15.** Decided by this walk and annotated in place in the
  definition's list: Q18 (Quantity on an unnamed entry without named
  subordinates — accepted silently, the manuals say "should not",
  `--pedantic` notes it) and Q20's L half (justification on a group
  entry — L is honored, per [J 02.05.04]'s "Left justification is always
  effective"; F Appendix 1's TABLE `L` is consistent but nonprobative,
  since TABLE sits at the highest level, where L is the default anyway).
  Q20's R half was already locked by D3.5, and Q67 was already read by
  D9.7 (msg 200 as the QUANTITY IN capacity) — both annotations point at
  those records, not at this walk. Q19's absolute length ceilings are
  implementation capacities under M3-12, not language rules. Q21, Q22,
  Q24, Q25, and Q33 stay open; none blocks M3 — Q22's COND value forms
  follow the M2 parse (one quoted constant) until evidence says
  otherwise, and Q24/Q33 are object-time questions for M4/M5.

## Staging

Three pull requests, each green alone (M3-1): the data mapper with the
storage oracle; the dictionary and resolution; the listing extension with
the golden rewrite.

## Oracles

- The 90.05 job deck compiles clean in both modes at every stage.
- Stage 1: the M3-14 fixture — offsets, extents, and initial words match
  the 1962 storage section.
- Stage 3: the rewritten golden matches the scan-measured 1962 listing,
  GN names and LOC column included.
- Error paths: constructed decks per message, asserting id, severity,
  statement number, and recovery, per the M2 oracle pattern.
- Decision conformance: each M3-N and each D-slate call named above gets a
  test that cites it.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 71]: ../../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F p. 80]: ../../comtran-manuals/F28-8043/04-data-description.md#format-characters
[J 02.03.03]: ../../comtran-manuals/J28-6169/02-compiler.md#b-key-words
[J 02.04.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-effect-of-data-storage-mode-on-arithmetic-efficiency
[J 02.04.06]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.07]: ../../comtran-manuals/J28-6169/02-compiler.md#c-conditional-statements
[J 02.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.02]: ../../comtran-manuals/J28-6169/02-compiler.md#1-record
[J 02.05.04]: ../../comtran-manuals/J28-6169/02-compiler.md#6-param-and-funct
[J 02.05.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.06]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.07]: ../../comtran-manuals/J28-6169/02-compiler.md#2-constants
[J 02.06]: ../../comtran-manuals/J28-6169/02-compiler.md#0206-environment-description
[J 02.06.08]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.13]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.07.03]: ../../comtran-manuals/J28-6169/02-compiler.md#5-locate-and-transmit
[J 02.07.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-factors-affecting-choice-and-use-of-locate-or-transmit-mode
[J 02.08]: ../../comtran-manuals/J28-6169/02-compiler.md#0208-the-7097090-machine-symbolic-language---crypt
[J 90.01.01]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#appendix-9001-deferred-features-restrictions-and-limitations
[J 90.01.03]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.04]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.05]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02.01]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#introduction
[J 90.02.02]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.05]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.10]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.12]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.15]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.17]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.26]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.27]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.04]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.05]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
[J 90.05.01]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#introduction
[J 90.05.02]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description
[J 90.05.04]: ../../comtran-manuals/J28-6169/90.05-sample-program.md#a-data-description
