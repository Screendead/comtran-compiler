# M1 front end — recorded design decisions

*Status: current as of M1 (2026-08-03). Governs `lib/src/lexer/` and
`lib/src/listing/`. This file records the decisions M1 had to make where
the sources are silent or where a D-record deferred the choice to M1
(decisions.md D0.6, D9.4, D9.10, D7.13, D2.3, D2.4). Every entry below
is a design decision under the D0.4 fidelity rule unless it carries a
source citation. Amend by updating this file and `decisions.md` together.*

## Deck structure

- **M1-1. Division-header recognition.** A header card is `*DATA`,
  `*ENVIRONMENT`, or `*PROCEDURE` with the asterisk anywhere in the name
  margin (columns 7–12) and nothing else in the body. F puts the
  asterisk in column 7 (F p. 65); the compiled sample punches
  `*PROCEDURE` from column 8 and compiled clean (J 90.05 listing, PDF
  p. 195), so the whole margin is accepted.
- **M1-2. Single job.** The M1 driver compiles one job per deck file and
  does not require a `*FINISH` card; the job stream, the `$CMPLE` option
  scan, and message 132 land at M2 with the job loop (D9.14). Cards
  after `*FINISH` are ignored with our message 903. A second compile
  control card is ignored with our message 904.
- **M1-3. Blank cards** carry no text and are skipped by the scanners
  but still echoed, unnumbered, in the listing. Neither manual defines
  them (definition §1.9.4).
- **M1-4. Cards before the first division header** are ignored with our
  message 902 at severity 3 (D2.3 required this decision).

## Scanners

- **M1-5. Message 62 triggers** (D9.4 defines the invented criterion) at:
  a margin name while the previous sentence is open, or the end of a
  division group or the deck with the sentence open. The recovery closes
  the sentence unterminated.
- **M1-6. The character gate** (D9.10) runs inside the scanners, so only
  scanned text is gated: commentary after a sentence terminator is
  echoed but never scanned and never draws message 134. Inside a
  literal, a column with a BCD read-out keeps its value; a column with
  no read-out draws 134 even there.
- **M1-7. The dollar sign** is a source character (Set H), so it is not
  an illegal character under D9.10 layer (b). In procedure text it is
  emitted as a symbol token for the parser to judge at M2.
- **M1-8. Messages 167 vs 168** (both attested; the split is ours,
  per D1.1): an unclosed literal in procedure text draws 168 (the
  statement continues past the card, so the literal "would extend
  across cards"); an unclosed constant at the end of a data entry draws
  167; an unclosed environment literal draws 167. The Data Description
  cross-card constant continuation is accepted silently, joined in card
  order with no assumed blanks (D1.1; Open Question 6).
- **M1-9. Token text placeholders.** A legal in-literal machine
  character with no Set H glyph appears as `?` in token text and in the
  listing (the D0.6 display-glyph choice deferred to M1). `?` is not a
  Set H character, so it cannot be mistaken for source text. The data
  mapper re-reads literal values from the card images at M3.
- **M1-10. Message 194 fires for a NAMED entry with no valid level.**
  An unnamed entry without a level is accepted: the sample's unnamed
  `REDEF TABLE` entry (statement 168,00) has a blank level field and
  compiled with no errors (J 90.05 listing).
- **M1-11. Over-long description runs.** A run over 30 characters of
  pure format characters draws 100,00; a name-like run over 30 draws
  our message 901. Constants over 120 characters draw 148,00 (D7.9);
  literals over 50 draw 150,00; numerics over 50 draw 52,00 (D1.2).
- **M1-12. Environment continuation cards** may carry only options:
  content in columns 7–30 draws 186,00 and is ignored (J 02.06.01.01
  says a type code there is ignored; the message is our addition). A
  first card without a legal type code is deleted with 144,00 and its
  continuation cards fall with it.

## Statement numbering (D7.13)

- **M1-13.** One number per procedure sentence, data entry, or
  environment card group, continuous across all divisions, headers
  unnumbered — the sample's scheme (J 90.05 listing; J 02.02.01 read
  per the sample). A deleted environment card still consumes its number
  (the D9.8 analogue). The number prints on the unit's first card;
  continuation lines print blank. Diagnostics on unnumbered cards print
  9999,99 (J 02.02.01).
- **M1-14. Page 197 number attribution.** The listing conversion
  misattributes statements 218–221 and 228 by one line (printer
  half-line stagger); the page scan (`images/page-197.png`) is
  authoritative and our tests assert the scan's grouping. The
  transcription itself is an erratum candidate for Jack; the conversion
  stays untouched.

## The listing

- **M1-15. Line geometry** (measured; the manual states no print
  columns): serial columns 1–6 at print 1–6; statement number
  right-justified at 8–14; the five-octal-digit name-address column of
  the 1962 listing (undocumented; a compile-time dictionary address by
  our analysis) stays blank at 18–22 — we do not fabricate values; card
  body columns 7–72 echoed verbatim at print column+18 (25–90). Data
  and Environment lines echo with column 72 blanked (J 02.03.01, §2.c);
  procedure lines echo through 72.
- **M1-16. Page head** template per the sample:
  `DATE mm/dd/yy   TIME  h.hh   ACCOUNT …ID. <identifier>  PAGE n`,
  the identifier from control-card columns 55–72 (J 02.01.02). The
  title line is the operator's, not compiler-fixed: an option, off by
  default. Date and time are injected options so golden tests are
  stable. 50 content lines per page — our reading of the sample's six
  pages; the exact 1962 value is not recoverable at M1.
- **M1-17. Control-card echo** prints card columns 1–72 at the far-left
  margin (two columns in from position 1), with the phase letters CTC
  under it and CTD/CTE before the diagnostic block (J 05.06.01; the
  letters print in the listing at the left margin per the page scans).
  The `*FINISH` card is not echoed (the sample stops at the last source
  card).
- **M1-18. The diagnostic block** follows the source listing
  (J 02.02.01: source, then error messages). Clean: the attested
  `NO ERRORS WERE DETECTED DURING COMPILATION` line. Otherwise the
  attested header and `NUMBER   CODE   MESSAGE` columns; each row
  prints the statement number, the severity, and the message text —
  never the message id (D9.5). The trailer
  `SEVERITY LIMIT WAS NOT REACHED` prints when diagnostics were issued
  and no severity-5 stop occurred; no trailer otherwise (D9.1).
- **M1-19. Severities** come only from the table in
  `lib/src/lexer/severities.dart` (D9.2); every value is non-historical
  and carries its class justification. Our own messages take ids in the
  900 range (D9.7) and close with `(NON-HISTORICAL.)`.

## Deferred out of M1

- `--pedantic` mode (D0.8): the repairs it warns on are recorded in the
  scan results (for example `ProcedureSentence.labelHadPeriod`); the
  flag itself lands with the M2 driver.
- The full 210-message table, its D9.5 golden byte-comparison, message
  132, and non-zero clause digits: M2.
- `GN)nnn` generated names in the listing name field: they need the
  dictionary allocator (M2/M3); the M1 listing leaves unnamed entries'
  name fields as punched.
