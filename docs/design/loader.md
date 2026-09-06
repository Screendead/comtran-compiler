# The object deck and the CT Loader

*Recorded 2026-08-30, M4 stage 3. This record holds the byte-level
decisions of the deck writer and of our CT Loader. `m4-codegen.md`
M4-16 charters both, M4-8 holds the print geometry, and M4-19 holds the
emit flags. The prefix is `LD-n`. Every entry binds the code.*

## LD-1. The symbolic control cards

The compiler punches a `*FILE` card and a `*SPEC` card for every FILE
card, in declaration order. A repeated name gets cards for its first FILE
card only. The file number is the card's one-based ordinal, the `k` of
the calling sequences' `04000 + k` (`test/fixtures/90.05-object-code-notes.md`,
section 2.6). `lib/src/codegen/control_cards.dart` holds the one rule.

The fields follow [J 90.08.01] and [J 90.08.02]. This record settles nine points the manuals leave open:

- **The file name starts at column 55.** [J 90.08.01] says 54 and
  [J 03.02.02] says 55. The page scan (PDF p. 198) puts `INPUTMASTER` at
  print column 48, with `*FILE` at print column 0 and the page head's
  DATE and PAGE fields at columns 0 and 83 as the ruler. Card column 7
  prints at column 0, so the name is at card column 55. The artifact
  decides the manual's own divergence.
- **A quoted literal punches left-aligned; a number punches
  right-aligned.** UNIT1, UNIT2, SERIAL and REEL are literals; the
  blocksize, ACTIVITY and RETAIN are numbers. The print attests both
  alignments: `D1` at columns 18 to 19 and `300` at 18 to 20 (D7.1). A
  blocksize past 9999, which msg 931 rejects at severity 4, leaves its
  field blank: the job goes on, and the field cannot hold the value.
- **Where [J 90.08.02] allows "R or blank", the compiler punches `R`.**
  The sample's CLOSER punches `R` where the same words allow a blank.
  The open column takes the same reading. A file with no SPECIF card
  takes every default, this one included.
- **SEQ and CKSUMS refuse.** [J 90.08.01] names their columns, 33 and 34,
  and no character. The sample uses neither. The compiler refuses the
  job (M4-2 as amended) and invents no character.
- **A CHECKPOINT file has no type character.** [J 90.08.01] lists `I`,
  `T` and `P` for INPUT, OUTPUT with SPANS, and OUTPUT. Column 28 stays
  blank, and column 35 marks the file (D7.2). One character reverses
  this.
- **Column 30 prints `L` for LOW and `H` otherwise.** The table sources
  both characters from HIGH, an original printing error the conversion
  notes record. The sample's `LD` files attest LOW as `L`.
- **A unit literal longer than four characters refuses.** The SPECIF
  parser accepts six characters. The card fields hold four
  ([J 03.02.02]), and every unit form of [J 03.02.03] fits four. A longer
  literal has no field, and the compiler refuses the job.
- **A file name longer than eighteen characters refuses.** A name holds
  up to 30 characters (definition section 1). The name field, columns
  55 to 72, holds 18. No manual says what the compiler punched for a
  longer name, and the compiler refuses the job.
- **The `*SPEC` blocksize field holds four digits.** [J 03.02.05] calls
  the blocksize "normally a number (0-999)"; [J 02.06.04] allows 9999,
  and D7.1 reads the loader manual's range as a slip. The four columns
  hold 9999.

The `*CTEXT` and `*CTEND` cards follow [J 03.02.09], which gives columns
26 to 54 to "date.and.time" and no form. The print attests the form on
PDF pp. 198 and 216: `DATE 101861 TIME   2.45`. Measured: `DATE` at
column 26, the six date digits at 31, `TIME` at 38, and the time
right-aligned to end at column 48. The deck.name in columns 1 to 6 is the
$CMPLE card's, verbatim (D7.11), and blank for a *COMPILE card.

## LD-2. The relative binary deck

The deck writer punches the text section only (D7.10), at 19 data words
a card ([J 90.03.03]). The print gives one cross-check of the card count.
`*CTEXT` is serial 15 and `*CTEND` is serial 67, so 51 text cards lie
between them. The sample's 961 deck words at 19 a card are 51 cards. At 18 a
card they are 54; at 20, 49.

Word 1 follows [J 90.03.01]. The word count is the count from word 3. A
full card counts 22, the "22 word" of the card's name. The
checksum-control bit is clear: the loader verifies.

**The checksum sums word 1 and words 3 through 2 + count, the control
words included.** [J 90.03.01] says "word 1 and all data words on the
card", and J 90.03.03 calls words 6 on the "data words" of a text card.
Two readings follow. This record takes the wider one. A loader has one
checksum routine for every section, and it sums the words the count
names. The narrower reading skips words 3 to 5 and needs section-specific
loader code. The trailing zero words make "3 to 24" and "3 to 2 + count"
the same sum. The logical sum is the `ACL` rule: 36-bit addition, the
carry out of position S returned to position 35.

The control groups pack seven to a word from position 1, the sign bits
unused, and the group after the last data word is `00000`
([J 90.03.03] to 04). A word punches in three columns, position S in row
12 of its first column (`deck-format.md` section 2.3). The section
sequence in word 1 counts from zero.

**One serial counts every card of the deck, symbolic and binary alike,
and punches as decimal digits ending at column 80.** The print attests
15 and 67 at card columns 79 to 80, measured. The 67 proves that the
counter advances across the 51 binary cards. It does not prove that the
1962 compiler punched the digits on those cards. No byte image survives
to settle it. The deck writer punches them. The loader reads columns 1
to 72 of a binary card, so the choice costs it nothing. One line
reverses it.

## LD-3. Our loader

`lib/src/loader/loader.dart` makes one pass. The 1962 loader's second
pass over its 2TEXT file served subroutine, control-break and
external-name references, and the compiler punches none of them
([J 90.01.04]). The loader reads no 2TEXT form and refuses its groups: the
immediate operator `01110` and the complex-expression code `11`.

The loader reads the symbolic cards through `*CTEXT`. It refuses
`*POOL`, `*GROUP`, `*RETAINS`, `*DELETES`, `*FILEQU`, `*START` and
`$LOAD`: the compiler punches none of them, and the pool cards wait for
M5 under D7.3. A `*SPEC` card without a `*FILE` card of the same
deck.name and file number is ignored ([J 03.02.05]). The loader refuses a deck.name with an imbedded
blank: it "will prevent execution of the object
program" ([J 90.01.05] B.5; D7.11).

The loader verifies every text card: the header marks, the deck type,
the word count, the section sequence, and the checksum unless word 1
bit 2 waives it. The loader refuses a card of deck type `001`, `010` or `011`.
D7.10 accepts the absence of those sections, and a silent skip of an
unpunched section would be untestable acceptance. The control groups
follow [J 90.03.04]:

- `00000` ends the card.
- `00001` takes `PZE` as an absolute origin, `MON` as a relative
  origin, and `PTW` as a reservation. It refuses `PTH`.
- `01111` names the entry point (D2.1).
- A standard word relocates its decrement and its address by their
  classes: a constant as is, a relative field by the origin, and a
  system reference through the caller's table. The `00010` system reference point is a SYS
pseudo-op the compiler never punches, and the loader refuses it.

A system reference resolves through a resolver the caller supplies. The
type `0000` is a system reference and `0001` a file reference
([J 90.03.05]); the other types are refused. The dispatch table is M4-17's
and the file blocks are M5's, so no address is fixed here. The loader
returns the words by absolute address, the entry point, the files it
read, and the cards it consumed. **Amended 2026-09-06 (M4 stage 4,
`runtime.md` RT-1). A program run reads the result.** `Machine` writes
`words` into `MachineState` and enters at `entry`. It gives `origin` as
4096, the first address above the runtime area; M5's IOCS reads `deckName`
and the `LoaderFile` fields, the number, name, type, mode, density,
units, blocksize and open and close options; a caller that loads a
second deck reads `cardsRead`; a resolver that keeps the raw code, as
the round-trip test's does, reads `SystemReference.code`. The tests
read them all. `runtime.md` RT-1 holds the machine assembly that runs
the result.

The round trip is the stage-3 oracle. At origin zero, with the raw
15-bit code as each resolved address, memory equals the listing's word
image: 936 words, entry 00165. At origin 10000 the relative fields move
by the origin and the table's addresses land in the system fields.

**One gap stays open.** The code generator's end-of-text entry names
`GN)000` for every program. D2.1 asks for a labeled PROGRAM.START to
name the entry instead. Stage 4, the first stage to run a program, lands
it.

*Amended 2026-09-06 (M4 stage 4).* The gap is closed. The end-of-text
entry names a labeled PROGRAM.START and holds that word's address. A
program without the label keeps `GN)000` and the first procedure word.
D2.1 as amended holds the evidence.

## LD-4. The printed document and the dumps

`--emit-object` writes the whole document after the source pages: the
loader-card page, the object pages, and the closing lines — PDF
pp. 198 to 216 of the sample, the span D0.3 names. The loader-card page
is measured on PDF p. 198. The message line
`THE FOLLOWING LOADER CONTROL CARDS PRECEDE THE BINARY DECK.` prints six
columns left of the LOC column, and each card prints from that column
too, card column 1 at print column −6. The page holds the head in slot
0, the message in slot 3, and the cards from slot 5. The page frame is
the object pages' frame: the head, two blank lines, and 55 content lines.
A program with more cards than one page holds continues on a page with
its own head. No artifact attests the overflow, and the pagination is
mechanical. The closing lines follow the end-of-text line after one
blank: the message at −6, the `*CTEND` card from −6, and `DONE` at −5
(M4-8 as amended). They paginate with the object lines.

The twelfth card of PDF p. 198 is file 6's `*SPEC` card. The scan reads
`06`: the `*FILE  06` line above it prints the same glyph, a 6 whose top
stroke is weak, and the transcriber read it as 6 on one line and 5 on the
other. The golden prints `06`. The transcription read `*SPEC  05` until
2026-09-06, when Jack authorized the correction; it now reads `06`. The
review record of 2026-08-30 holds the crop.

`--emit-loader` writes one `* JOB n` section per job with the symbolic
cards' text, serials included, or the job's marker line. `--emit-deck`
writes the canon bytes of every job's cards, in deck order, and a job
that produced no object program adds no cards: the container holds no
marker line. `emit-stages.md` holds the conventions.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 02.06.04]: ../../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 03.02.02]: ../../comtran-manuals/J28-6169/03-loader.md#b-load-card
[J 03.02.03]: ../../comtran-manuals/J28-6169/03-loader.md#c-file-card
[J 03.02.05]: ../../comtran-manuals/J28-6169/03-loader.md#d-spec-card
[J 03.02.09]: ../../comtran-manuals/J28-6169/03-loader.md#j-start-card
[J 90.01.04]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.05]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.03.01]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#introduction
[J 90.03.03]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#3-file-check-entry-specifications
[J 90.03.04]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#1-format
[J 90.03.05]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#3-standard-word
[J 90.08.01]: ../../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008
[J 90.08.02]: ../../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#a-the-file-card
