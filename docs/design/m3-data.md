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
| M3-16 | Stage-1 message choices |
| M3-17 | The dictionary, the resolution triage, and the stage-2 pipeline |
| M3-18 | The I/O verb binding map |
| M3-19 | Functions and DO substitution under J |
| M3-20 | Subscript reference checks |
| M3-21 | Stage-2 message allocations and adopted opens |

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
    *Amended 2026-08-04 (review): the allocator measures that length as the
    group's physical extent, not as an arithmetic sum (M3-6). The two agree
    on [J 02.05.06]'s worked example — its A is 12 characters either way — and
    diverge in two cases. An arithmetic sum counts a redefinition head on top
    of the fields it redefines, against "redefinition of a record area does
    not give it length" ([J 02.05.01]), and it drops interior alignment
    padding. The extent is the length a compare or a move over the group must
    use, so D3.3's length is the extent. D3.3 carries a matching dated
    amendment, and `ItemSemantics.storageChars` carries the value.*
  - Any of `8 * . , $ + -` in the pictorial, or BLANK WHEN ZERO, makes the
    field edited ([J 02.05.05]; D3.2). Note 2 of the chart gives edited fields
    both sign forms: a reserved sign position or a rightmost overpunch.
    *Amended 2026-08-04 (review): an overpunched 8 is an 8 in the format
    field, so it makes the field edited. The chart's rightmost-character list
    admits an overpunched 8 in the Edited Field row only; the External Decimal
    row admits an overpunched 9 alone. Read on the scan `images/page-031.png`,
    2026-08-04: the Edited row lists minus 8, minus 9, plus 8 and plus 9, and
    the External row lists minus 9 and plus 9. The conversion and the
    definition transcribed the Edited row as "8 or 9 or 8̅ or 9̅", which drops
    the marks on the first pair; Jack authorized the correction and it was
    made 2026-08-04 (§8.5.8-b records the reading). See M3-5 for the
    measurement.*
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
  the same way ([J 02.05.07]'s `999⁺` / `123⁺` example).

  *Amended 2026-08-04 (review): the measurement keeps the overpunched digit,
  not the sign alone. The zone letters run A–I for plus 1 to plus 9 and J–R
  for minus 1 to minus 9, so `99Q` and `99R` are the minus 8 and minus 9
  pictorials and `99H` and `99I` are their plus twins. An overpunched 8
  therefore makes the field edited (M3-4). Two consequences: a constant on
  such a field draws msg 57 in place of the
  external-decimal check (msg 58), and under mode I the conflict takes the
  edited branch — the id stays msg 32, and the recorded class changes from
  external decimal to edited. The digit position, the storage character, and
  the sign convention are unchanged. Open: the chart admits an overpunched 8
  or 9 only, while the scanner reads any zone letter, so an overpunched 1 to 7
  draws no diagnostic. Msg 33 is the candidate id if stage 2 wants one.
  Resolved 2026-08-04: stage 2 adopts msg 33 for it (M3-21).*

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
    *Amended 2026-08-04 (review): the mapper obtains that bit count from the
    closed form `floor(n * log2 10) + 2` for n digits, then rounds up to a
    multiple of 6. The form is exact for every digit count a deck can punch —
    checked against a big-integer oracle for every n up to 50000 and at 99999,
    799992 and 8000000 — and it costs the same at any n. [J 02.05.04]'s rule is
    unchanged; only the way the count is obtained is new.*
  - **Quantity replication:** the entry and its subordinates lay out once,
    then repeat; the stride is the element's (word, byte) extent. TABLE's
    twelve 2-word pairs attest whole-structure repetition ([J 90.05] listing,
    statements 143–172 against words 00135–00164).
  - **REDEF:** save the counter at the REDEF line, allocate the redefinition
    over the target's origin, restore on termination (D3.4, D3.6;
    [J 02.05.02]). The redefinition allocates no new storage; TABLE.ITEM has
    no area of its own in the dump.
    *Amended 2026-08-04 (review): three points the allocator now implements.
    (a) The overlay restarts at the target's reservation start, not at its
    first character. The two differ only for a right justified field, whose
    reservation begins at the word boundary before its first character
    ([J 02.05.04]). (b) An entry with no level number terminates nothing. A
    record ends only at "a level number equal to or less than the one
    associated with RECORD" ([J 02.05.01]), and [J 02.05.02]'s EXAMPLE 1 keeps
    H inside A G after two REDEFs. A REDEF marker, and any level-less entry a
    diagnostic left in place, therefore close no enclosing group. (c) The
    termination order is ours, because J states no repetition mechanics: the
    frames opened inside the overlay close on the overlay counter, then the
    counter is restored ([J 02.05.02]), then the enclosing frames close. So a
    repeated group inside the overlay grows the redefined area, and a repeated
    group that ends at the terminating item advances from the restored
    counter.*
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
    *Amended 2026-08-04 (review): the overpunch may fall on a zero. The chart
    admits "an overpunch with the rightmost digit" ([J 02.05.05]) and zero is a
    digit, so `120̅` is a legal constant for `999̅`. Plus zero punches 12-0 and
    minus zero 11-0; neither has a Set H glyph, so no listing line and no
    `.deck` mirror can print one, and a test for one punches the column
    directly.*
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
    *Amended 2026-08-04 (review), the trigger set: transmit is triggered by
    SPANS, HOLD or CARD on the Environment FILE card, and "'Locate' is assumed
    when none of these options have been selected" ([J 02.07.03], scan
    `images/page-054.png`). This record cited [J 02.07.05] alone, whose
    opening recap names HOLD and SPANS only. Both statements sit in J, so the
    J-over-F precedence rule does not decide between them. The definition
    governs the recap. [J 02.07.03] stands inside the manual's
    locate-and-transmit block ("5. Locate and Transmit"). The recap is passing
    prose: on the scans it closes subsection a), "File characteristics and
    processing requirements", of the GET-command discussion
    (`images/page-055.png`, `images/page-056.png`). No message is attested for
    the CARD trigger and the binder emits none.*
    *Amended 2026-08-04 (review), the scope: the mode belongs to the file, not
    to the record. A file transmits on any of three triggers. Its FILE card
    selects SPANS, HOLD or CARD ([J 02.07.03]). A record it binds holds an
    array ([J 90.01.01]). A record it binds shares its area by REDEF with data
    other than records ([J 02.07.05] c-ii, scan `images/page-056.png`).
    Otherwise the file locates. A record transmits if any input file that
    names it transmits. Every trigger is a FILE-card fact, and c-ii forces
    "all records of the file". One file therefore holds one mode. Msg 932
    prints once per forced file, on the file name, and only where the file
    would otherwise have located — c-ii reports a change. A file already
    transmitting for an option or an array draws nothing. Two readings here
    are ours. (a) A file's mode comes from its own options and its own
    records, in one pass. A transmit that reaches a record by propagation
    does not travel on into that record's other files. [J 02.07.04] allows a
    record.name on one input file only, and msg 11 diagnoses the violation.
    In every legal program the one-pass rule and a transitive closure agree.
    (b) [J 90.01.01] states the array rule per record; the file-wide reading
    follows from the file-scoped mode above, not from that sentence. The
    [J 90.01.01] carve-out above is untouched, because propagation follows
    file membership and never a REDEF link.*
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
  *Amended 2026-08-04 (stage 2): the sequence extends to 946. M3-21
  records the stage-2 allocations and their severities.*

- **M3-16. Stage-1 message choices (2026-08-04).** The splits,
  thresholds, and deferrals stage 1 fixed, recorded so stage 2 does not
  re-derive them:
  - Msgs 13,00 and 15,00 print one catalog text; msg 16,00 prints its
    own, "'NAME.2' IS NOT A RECORD. CHECK DATA DESCRIPTION."
    ([J 90.04], scan `images/page-181.png`, read 2026-08-04 — this entry first
    said all three shared one text). The 13-versus-15 split is the only
    choice here, and it follows the M1-8 precedent: 13 for a FILE card
    that names no record, 15 for a name that resolves to nothing.
    Msg 16 covers a name that resolves to a non-record item.
  - Msg 209 covers an input card file with BLOCKSIZE under 24, and the
    binder repairs the value to 24. Msg 5 covers a bound record longer
    than its file's blocksize without HOLD or SPANS.
  - A blank Mode with a digit pictorial reads as external decimal.
    Attested: DETAIL HOURS prints a blank Mode against pictorial `99V9`
    ([J 90.05] listing, statement 31,00, PDF p. 192), and [J 90.05.02]'s
    word table puts HOURS "in the first three characters" of the record's
    third word — one character per digit. DETAIL is located and takes no
    area, so the storage section holds no DETAIL row; this entry first
    cited that section.
  - Msg 35 fires at the attested bound — a scientific fraction over 16
    digits — and at one derived bound: a right-justified internal field
    over 21 digits, the most the two register words hold. Msg 34 stays
    reserved; stage 1 attests no check for it.
    *Amended 2026-08-04 (review): msg 34 is enforced. A pictorial
    repetition count over 99999 clamps to 99999 and draws msg 34,00,
    "MAXIMUM FORMAT CHARACTER COUNT EXCEEDED. 'NAME.1' FORMAT USED."
    ([J 90.04]) — the attested text for an expanded count over the
    maximum with the clamped format used, and it also covers an
    alphameric count, which msg 35 does not. The cap is a keying-error
    repair, not a capacity check: a BLOCKSIZE holds at most 9999 words,
    that is 59994 characters ([J 02.06.04]), so no readable field reaches
    99999 positions. Capacity proper stays M3-12. The clamp also bounds
    the allocator, because the msg 100 pictorial-length check diagnoses a
    long run without truncating it. The checklist row for 34,00 moves
    from reserved to enforced. No 930-series id is allocated.*
  - Only a leading blank in a numeric constant reads as zero
    ([J 02.05.05] note 3); an imbedded blank draws msg 67.
    *Amended 2026-08-04 (review): that rule now binds all four numeric
    converters. Floating point and scientific decimal followed it only
    after this repair; both discard the image on the first misplaced
    blank, so a repeated entry draws one diagnostic. Any non-blank
    character ends the leading run, a sign included, in all four paths. The split the four
    share: msg 67 for a blank out of place, msg 54 for a character the
    field type cannot store. A sign inside a floating constant is of the
    second kind. The chart lists `+` and `-` as scientific-decimal
    content, and note 4 makes scientific decimal the edited form of
    floating point, but [J 02.04.02] puts a sign only in front of the
    fraction or on the exponent of a `fraction F±exponent` literal, and
    this converter reads no F exponent — so the front is the one position
    a sign may hold, and a later sign draws msg 54. Msg 53,00, "INCORRECT
    USAGE OF PERIOD, SIGN, OR F FOR CONSTANT OR LITERAL.", is the closer
    1962 id. The procedure lexer already issues it for a procedure
    literal (an F with no following digit; a second decimal point). If
    stage 2 adopts it here, the data path joins that existing use and
    must share its reading. Resolved 2026-08-04: stage 2 adopts msg 53
    for the misplaced sign (M3-21). Open, unattested and unpinned: an all-blank floating
    constant draws msg 54, where note 3 read literally would make it
    zero.*
  - Msg 36 recovery: the subordinate entries drop, and the formatted
    entry keeps its pictorial. COND children, REDEF markers, and
    redefinition heads are exempt.
  - Deferred to stage 2: the binder rows 8, 9, 10, 17, 19, 195, and
    198; the POOL and GROUP buffer minimums; the capacity counters
    (M3-12); the COND-value msg 37; the `DataItem.extras` judgment; the
    LABEL 14-word cap; and the no-fields-after-a-variable-array rule,
    which has no attested id.

## The dictionary, the resolution triage, and the stage-2 pipeline

- **M3-17. The dictionary and the triage (2026-08-04).** Stage 2 adds the
  dictionary and the resolver to `lib/src/data/`. The dictionary holds every
  programmer name with its kind, level, position, and encounter number —
  the sequential numbering behind the object listing's `1)C` / `2)C`
  ([J 90.02.02]). The kinds: data item, record, condition (a data COND
  entry and an Environment COND card alike), CALL synonym, statement
  name, section name, and environment name. GN names never enter it
  (M3-8). A REDEF line's discarded name never enters it (D3.4).
  PROGRAM.START entered as a data or environment name draws msg 142
  (D2.1: it may only label a statement or section).
  - **Pipeline order (ours).** `runSemantics` runs: mapper → dictionary →
    CALL pass → environment binder → images → procedure resolution and
    legality → capacity totals. The CALL pass precedes the binder
    because CALL exists to give the Environment Description one-word
    names ([J 02.03.02]).
  - **Qualification ([J 02.05.02]–03; [F p. 15]–16).** A reference's words
    run general to specific, blank-separated; intermediate levels may be
    skipped. Matching follows level and position only, REDEF-blind. A
    candidate is a data item whose ancestor-name chain contains the
    reference's words in order, the last word naming the item itself.
    Subscripts written on qualifier words flatten in word order (M2) and
    count against the resolved item's dimensions (M3-20).
  - **The triage (ours).** One rule set for every data-reference site.
    The last word names nothing anywhere: msg 108. The last word names
    items, but no candidate matches the qualifier chain: msg 101. More
    than one candidate matches: msg 166. A site-specific row overrides
    the triage where one is stated (M3-18; M3-20).
  - **Procedure names (D2.5).** Two namespaces: program-global for data,
    record, synonym, and environment names; per-section for statement
    labels. A collision within a section's scope draws msg 166 at the
    second definition. `DO A B` reads as statement name B qualified by
    section name A (D2.5).
  - **CALL (D4.13).** The old.name resolves through the triage: more than
    one field draws 166, none draws 108. A subscripted old.name draws
    msg 936 and the pair is dropped. A synonym equal to an existing
    dictionary name draws 166 (ours — a synonym is "a new unique simple
    name"). A qualified reference that ends in a synonym draws 101. A
    record.name as old.name draws pedantic msg 946.
  - **COND binding (M3-9).** A COND entry binds to the nearest preceding
    formatted entry; its constant converts under that field's format,
    and a mismatch draws msg 37. An Environment COND card's name enters
    the dictionary as a condition name; a test of it is the KEYS test
    ([J 02.06.17]). Ours: a condition reference that resolves to a
    non-condition item draws msg 25; an unresolved one draws 108; a
    `SET condition.name` whose name is not a condition name draws
    msg 191.
  - **Names that shadow operations (ours).** A statement label or section
    name equal to any J key word draws msg 61 — the "found in name
    field" half of its text. A data or procedure name equal to a list-3
    word that an environment card of the job uses draws msg 152 (M2-7's
    deferral; the name stands, C1).
  - **The stray description name and `extras` ([J 02.05.06] e).** A
    `targetName` on an entry that is not REDEF or COPY is the
    pictorial-read-as-name case. It must resolve to a data, key, or
    procedure name; otherwise the entry draws msg 185. Tokens left in
    `DataItem.extras` draw msg 185 the same way, one message per entry
    (ours). The 90.05 deck punches neither.
  - **Record precedence (ours).** A RECORD entry that follows, in the
    same *DATA portion, a top-level entry with a numerically greater
    level number and no RECORD type draws msg 197: that leading group
    reads as description punched before its record name. Classification
    only; no re-parenting (M3-10).

## The I/O verb binding map

- **M3-18. The verb sites (2026-08-04).** The stage-1 binder kept every
  per-card check; these rows need the procedure walk. The site map,
  readings ours where no row's text states one:

  | Site | Condition | Id |
  |---|---|---|
  | GET x / FILE x | x resolves to nothing, or to neither a record nor a file | 8 |
  | GET x / FILE x | x resolves to a file or a non-record data item | 16 |
  | GET x | x is a record on no FILE card | 9 |
  | GET x | x is a record on no input FILE card | 10 |
  | FILE x | x is a record on no output FILE card | 19 |
  | FILE x IN f | f resolves to nothing or to a non-file | 21 |
  | FILE x IN f | f is an input-only file | 22 |
  | FILE x IN f | f's FILE card lacks x | 195 |
  | OPEN f / CLOSE f | f resolves to nothing or to a non-file | 21 |
  | GET RECORD FROM f | f is an output-only file | 14 |
  | GET RECORD FROM f | f resolves to nothing or to a non-file | 23 |
  | GET RECORD FROM f | no [J 02.07.04] precondition holds | 12 |
  | GET RECORD FROM f | FIND LENGTH IN on some, not all, of f's records | 117 |
  | GET RECORD FROM f | PLACE LENGTH IN on some, not all, of f's records | 118 |
  | GET RECORD FROM f | BLOCK CONTROL on some, not all, of f's records | 121 |
  | FILE card | FIND LENGTH IN names a field of improper format | 111 |
  | FILE card | PLACE LENGTH IN names a field of improper format | 112 |
  | job end | no GET or FILE processes any record of file f | 198 |

  Notes. Msg 12's preconditions: all records fixed and equal length; the
  BEGIN option; all records standard variable; BLOCK CONTROL. PATTERN
  cannot rescue it until its M5 syntax lands (D9.12). The proper format
  for 111/112 (ours): external or internal decimal with no fraction
  positions. An ON ERROR, FOR LABEL, FIND LENGTH IN, or PLACE LENGTH IN
  name that resolves to nothing draws msg 108 at the card. OPTION's
  section names stay unresolved in stage 2: no M3-tagged row covers
  them, and the leniency default holds where nothing is attested.
  - **POOL and GROUP ([J 02.06.13]–14).** A POOL or GROUP variable-field
    file name that resolves to no file draws msg 21. A GROUP whose first
    variable-field item names no pool draws msg 939. A POOL buffer count
    below its file count — or below the total of its groups' buffer
    counts — is raised to the minimum and draws msg 937. A GROUP buffer
    count below its OPENCOUNT is raised and draws msg 938. The repair
    reading follows msg 209's substitution precedent.
  - **LABEL ([J 02.05.03]).** A LABEL-typed entry whose extent exceeds 14
    words draws msg 940.
  - **Variable arrays (M3-11; [J 90.01.01]).** A field described after a
    variable-length array in the same hierarchy draws msg 941 (M3-16
    records that no attested id exists).
  - **Base locators (D9.7).** The 128th located record draws msg 202.

## Functions and DO substitution under J

- **M3-19. The GIVING-function reading (2026-08-04).** PARAM and FUNCT
  are out of J ([J 02.05.03]), yet msgs 30, 68, and 72–75 live. The
  definition's reading binds here: a function is a data name that a
  BEGIN SECTION GIVING clause lists; the USING names are its
  parameters; both are ordinary data items.
  - A double-parenthesis function reference resolves its name through
    the triage. A resolved name that no GIVING clause lists draws
    msg 191 (ours). Its arguments resolve as data references.
  - The argument count checks against the owning section's USING count:
    fewer draws msg 30, more draws msg 68.
  - A DO with USING or GIVING checks its list against the target
    section's declaration: more draws 72 or 74, fewer draws 73 or 75. A
    target that declares none — a plain statement included — has count
    zero, so any DO list draws 72 or 74 (ours).

## Subscript reference checks

- **M3-20. The subscript and transfer site map (2026-08-04).** An item's
  dimension count is its number of quantity-bearing ancestors-or-self —
  an explicit or implicit Quantity above one, or a variable Quantity.
  Readings ours unless a row's text states them:

  | Condition | Id |
  |---|---|
  | a subscripted reference to an item with no dimensions | 98 |
  | a subscript count above zero that differs from the dimension count | 70 |
  | a subscript's variable is itself subscripted, or is a condition name | 71 |
  | a subscript variable of alphameric, edited, or group class | 79 |
  | a subscript variable with fraction positions | 31 |
  | a literal subscript term that is zero, negative, or fractional | 182 |
  | a legal subscript variable format that is not the direct-index form | 206 |

  A reference with zero subscripts is the whole-array reference and is
  legal. Msg 206's predicate concretizes D9.11: any format other than
  right-justified internal decimal, the form our code generator indexes
  with directly; the 90.05 sample stays silent.
  - **Counters (D9.7).** Each unique pair of resolved array and flattened
    subscript notation is one positional indicator; the 91st draws
    msg 184. Msg 205 names the same 1962 table, and one event cannot
    print two rows, so 205 stays reserved with a note (ours). Each
    unique `a * VARIABLE ± b` form is one index expression; the 51st
    draws msg 183.
  - **Transfers.** A GO TO target that resolves to no statement or
    section name draws msg 127; a target that resolves to a
    DO-addressed name draws msg 128 (Q40). A DO target likewise
    unresolved draws msg 188; an AT END bare name is a DO (D6.6) and
    shares 188. An assigned GO TO index of non-numeric class draws
    msg 129; a numeric index with fraction positions draws msg 130 and
    the integral part serves.
  - **DO indexing ([F p. 49]–53).** A FOR index variable of non-numeric
    class draws msg 76. A named p, q, or r parameter of non-numeric
    class draws msg 77. A literal p, q, or r that is not a whole number
    draws msg 78.
  - **The sentence table (D9.7; Open Question 9).** The per-sentence
    reference table caps at 100 distinct data references, an invented
    number. The 101st deletes the sentence with msg 177; its text
    states the recovery.

## Stage-2 message allocations and adopted opens

- **M3-21. Allocations and the two opens (2026-08-04).**
  - **The 930-sequence continues (M3-13):** 936 CALL old.name
    subscripted, C2. 937 POOL buffer count below minimum, raised, C1.
    938 GROUP buffer count below OPENCOUNT, raised, C1. 939 GROUP names
    no pool first, C3. 940 LABEL area over 14 words, C4. 941 field
    after a variable-length array, C4. 942 dictionary over 3500 names,
    C5 — D9.7's message-less dictionary limit. Pedantic-only, D11.4
    pattern, all C1: 943 doubtful figurative move accepted (D4.11),
    944 CORRESPONDING names that match nothing (D4.12), 945
    record.name as CALL old.name (D4.13).
    *Amended 2026-08-04 (build): this entry first gave D9.7's other
    message-less limit — section nesting over 18 — an id here. The
    parser's msg 915 has enforced it since M2, so no stage-2 id
    exists and the three pedantic notes moved down one.*
  - **Msg 33 adopted (amends M3-5's open).** An overpunch on a digit
    other than 8 or 9 sits outside the chart's rightmost-character
    lists; it draws msg 33 and the measured format stands.
  - **Msg 53 adopted (amends M3-16's open).** A sign after the leading
    position of a floating or scientific constant is an incorrect sign
    usage, not a foreign character. The data converters draw msg 53 in
    place of msg 54 for it, joining the procedure lexer's reading.
    Msg 54 keeps the truly foreign characters.
  - **Legality ids (M3-10).** An alphameric-class source — alphameric or
    group (D3.3) — moved to a non-alphameric target draws msg 84; an
    illegal CORRESPONDING group pair draws 84 (D4.12); a CORRESPONDING
    operand that is not a group, or does not resolve, draws 97. A
    numeric-to-alphameric-class comparison — the edited-versus-alphameric
    ban included — draws msg 107 at a second, resolution-time site; the
    parser's structural site stands. A variable-length item in a
    comparison draws 123. An alphameric-class operand inside a true
    arithmetic expression draws 25; inside an ADD list it is eliminated
    with 120. HIGH.VALUE, LOW.VALUE, or BLANK moved to internal decimal
    or floating point, or compared to a non-alphameric field, draws 82.
    A figurative constant moved to a variable-length array draws 180;
    to a field over 32766 characters, 181 (D4.6). The doubtful starred
    chart cells — BLANK to external, edited, internal, floating, or
    scientific — stay silent in default mode per D4.11's attested
    silence and draw pedantic 944.
  - **Capacity homes (M3-12; D9.7).** In the mapper walk: msg 200 at the
    26th QUANTITY IN, 201 at the 24th hierarchy level, 203 at the 86th
    array dimension, 204 at the 36th distinct edited format. In the
    resolver: 183, 184, 942, and msg 177's sentence table; the
    section-nesting limit stays the parser's msg 915 (M2). In the
    binder: 202. The non-historical `--no-table-limits` switch lifts
    the D9.7 counters only; the D3.1 caps and msg 34's clamp stand.

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

[F p. 15]: ../../comtran-manuals/F28-8043/02-language-structure.md#condition-names
[F p. 49]: ../../comtran-manuals/F28-8043/03-procedure-description.md#assigned
[F p. 71]: ../../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F p. 80]: ../../comtran-manuals/F28-8043/04-data-description.md#format-characters
[J 02.03.02]: ../../comtran-manuals/J28-6169/02-compiler.md#a-use-of-coding-forms
[J 02.03.03]: ../../comtran-manuals/J28-6169/02-compiler.md#b-key-words
[J 02.04.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-effect-of-data-storage-mode-on-arithmetic-efficiency
[J 02.04.02]: ../../comtran-manuals/J28-6169/02-compiler.md#1-figurative-constants
[J 02.04.06]: ../../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.07]: ../../comtran-manuals/J28-6169/02-compiler.md#c-conditional-statements
[J 02.05.01]: ../../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.02]: ../../comtran-manuals/J28-6169/02-compiler.md#1-record
[J 02.05.03]: ../../comtran-manuals/J28-6169/02-compiler.md#3-redef-see-iii-under-data-description-on-page-900103-for-limitation
[J 02.05.04]: ../../comtran-manuals/J28-6169/02-compiler.md#6-param-and-funct
[J 02.05.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.06]: ../../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.07]: ../../comtran-manuals/J28-6169/02-compiler.md#2-constants
[J 02.06]: ../../comtran-manuals/J28-6169/02-compiler.md#0206-environment-description
[J 02.06.04]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.08]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.13]: ../../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.17]: ../../comtran-manuals/J28-6169/02-compiler.md#h-option-environment-cards
[J 02.07.03]: ../../comtran-manuals/J28-6169/02-compiler.md#5-locate-and-transmit
[J 02.07.04]: ../../comtran-manuals/J28-6169/02-compiler.md#6-record-types
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
