# COMTRAN severity table — draft for D9.2 (all 210 messages)

**Every value in this file is OUR design decision. It is not recovered history.**
The 1962 appendix prints CODE `0` for all 210 messages because "the value may
vary" (J 90.04.01), and no surviving source assigns per-message severities
(Open Question 65). Each row below is an assignment made by the D9.2 consequence
rule and must carry `non-historical: true` when it becomes a machine-readable
row.

## Method applied

D9.2 gives five classes and one precedence rule. The rule: **the consequence
stated in a message's own text wins over its class heading.** Inside classes
2-4: **take the largest source unit whose intended object code is lost.**

Two sub-rules were necessary to apply D9.2 uniformly. Both are ours, and both
are stated here so a reviewer can reject them in one place:

1. **The lost unit is the unit the message names, not the transitive damage.**
   Message 25 (`OPERATION IGNORED`) is a D9.2 C2 example even though a lost
   operation makes the program run wrong. So downstream damage does not raise a
   class; the downstream condition carries its own diagnostic. Without this rule
   almost every message collapses into C4.
2. **Environment cards split by unit.** A message that kills the whole card
   (missing name, card format error, illegal card type, illegal word) is a
   statement-level loss = C3. A message that kills one option operand of a card
   (`NUMERIC INTEGER MUST FOLLOW -BLOCKSIZE-`) is a clause-level loss = C2,
   because D9.2 says "operand or clause gives 2". A message that states a
   property of a whole file or record (blocking, record membership, mode,
   uniform option use) is a file/record-level loss = C4, because D9.2's tie-break
   names "record, file" at level 4.

Classes: C1 advisory or auto-repair = 1; C2 operand-level loss = 2; C3
statement/sentence-level loss = 3; C4 program-level loss or a program that
cannot run correctly = 4; C5 unrecoverable, internal, or capacity = 5.

## The table

The machine-readable table itself is `lib/src/lexer/severities.dart` — one row
per message id with its class and deciding words. This file keeps the method,
the counts, the uncertain calls, and the anchors for review.

## Counts

| class | severity | count | ids |
|---|---|---|---|
| C1 | 1 | 30 | 6, 7, 27, 28, 32, 33, 34, 35, 37, 44, 49, 60, 62, 86, 104, 116, 130, 134, 141, 152, 170, 174, 178, 186, 189, 190, 198, 199, 206, 209 |
| C2 | 2 | 57 | 2, 25, 26, 30, 31, 38, 39, 43, 48, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 67, 68, 70, 71, 79, 80, 82, 91, 92, 93, 94, 95, 98, 100, 101, 106, 111, 112, 113, 114, 120, 127, 128, 133, 150, 155, 156, 157, 158, 159, 160, 162, 163, 165, 167, 168, 182, 185 |
| C3 | 3 | 69 | 1, 3, 4, 8, 12, 14, 16, 21, 22, 23, 36, 40, 41, 42, 45, 46, 47, 61, 63, 64, 72, 73, 74, 75, 76, 77, 78, 81, 83, 84, 88, 89, 96, 97, 102, 103, 105, 107, 115, 119, 122, 123, 125, 126, 129, 131, 138, 139, 144, 145, 146, 147, 153, 154, 161, 164, 166, 171, 176, 177, 179, 187, 188, 192, 194, 195, 196, 207, 208 |
| C4 | 4 | 29 | 5, 9, 10, 11, 13, 15, 17, 19, 20, 65, 66, 87, 90, 99, 108, 110, 117, 118, 121, 142, 143, 151, 169, 175, 180, 181, 191, 193, 197 |
| C5 | 5 | 25 | 0, 18, 24, 29, 69, 85, 109, 124, 132, 135, 136, 137, 140, 148, 149, 172, 173, 183, 184, 200, 201, 202, 203, 204, 205 |

Total 210. Every id 0-209 appears exactly once.

## Uncertain calls

Each entry gives the alternatives and the reason for the pick. All of them are
reversible in one table row.

**187 — C3/3, alternative C5/5. The most arguable row in the table.**
The message is a capacity message and states no recovery, which points at C5.
Three reasons pick C3. (a) D9.2's C5 enumeration is explicit — "namely 148, 149,
172, 183, 184 and 200-205" — and 187 is not in it. (b) D9.6 establishes that the
printed text truncates mid-phrase after "EACH WITH", so the absence of a recovery
clause is not evidence; the clause may be among the lost words. (c) D9.7 pairs
177 and 187 as the two sentence-scoped capacities with invented numbers, and 177
is C3 by D9.2's own worked example. A sentence-scoped limit is recoverable by
dropping the sentence, so it is not "unrecoverable". C5 would abort the whole
compilation for one oversized conditional, which contradicts the pattern of 171
and 177.

**85, 135, 136, 137, 140 — C5/5 kept, alternative C1-C3.**
"COMPILATION SUSPECT" and "DUBIOUS COMPILATION" both imply the compilation
continued, which argues against 5. D9.2 and D9.15 order severity 5 anyway, from
§8.5.7's grouping of read and dictionary errors. Kept at 5 per the decision
record. All five are unreachable by construction (D9.15), so the value is never
exercised. Each row must carry the D9.15 tension note verbatim.

**The card-option-operand family (91-95, 106, 111, 112, 155-159, 162, 163, 165,
48, 50) — C2/2, alternative C3/3 or C4/4.**
These messages reject one option operand of an environment card. D9.2 says
"operand or clause gives 2", and an option is a clause of the card, so C2. The
C3 reading treats the card as one statement and says the statement is lost. The
C4 reading says a file without a valid BLOCKSIZE cannot do I/O at all. C2 is
picked because sub-rule 1 keeps transitive damage out of the class, and because
the whole-card messages (1, 3, 4, 88, 89, 96, 144, 153, 154, 161, 164, 176, 207)
already occupy C3. If the family moves, all 17 ids must move together.

**The record and file consistency family — split, and the split is arguable.**
C4: 5, 9, 10, 11, 13, 15, 17, 19, 20 (each states a property of a whole file or
record). C3: 8, 12, 14, 16, 21, 22, 23, 195 (each states that one statement's
operand is the wrong kind of object; the file itself stays well formed). B.2
puts all of them in one row, so a reviewer may prefer one uniform class. The
split follows D9.2's tie-break, which names "record, file" at level 4 and
"statement" at level 3.

**117, 118, 121 — C4/4, alternative C2/2.**
"SOME BUT NOT ALL OF THE RECORDS BELONGING TO THE FILE" is a file-wide property,
so C4. The C2 reading says the compiler simply drops the option.

**3, 4 (OPTION and COND card format) — C3/3, alternative C4/4.**
An OPTION card governs the whole compilation, so losing it could count as a
whole-program property. C3 is picked for consistency with every other
"CARD FORMAT ERROR" message; no text states that the compiler abandons the card's
effect on the program.

**39 — C2/2, alternative C1/1.**
Message 190 states its repair ("FIELD IS NOT JUSTIFIED") and is C1. Message 39
describes the same outcome but states no repair, so the precedence rule does not
apply and the unit rule gives C2. A reviewer may hold that the two messages
describe one behavior and should share a class.

**64 and 65 — C3/3 and C4/4.**
64 (stray END, nothing open) loses only the sentence. 65 (END out of order)
loses the section nesting. 66 is C4 by D9.2. The three form a rising sequence of
structural damage. A uniform C3 or a uniform C4 for 64 and 65 is defensible.

**61 — C3/3, alternative C2/2.**
"OPERATION DEFINED AS NAME OR FOUND IN NAME FIELD" may lose only the name
(C2) or the whole sentence, because the verb was consumed by the name field
(C3). C3 is picked because a sentence whose verb sits in the name field has no
verb left.

**72-78 — C3/3, alternative C2/2.**
Parameter and loop-control format errors could be read as operand losses. C3 is
picked because none of them can produce a correct DO or loop, so the statement
is the largest unit lost.

**80 vs 81 — C2/2 and C3/3.**
A justification conflict loses one attribute (C2). A level conflict loses the
entry's place in the hierarchy (C3), which matches M1's C3 for 194.

**98 — C2/2, alternative C3/3.**
"CHECK DATA DESCRIPTION OF ARRAY OF ELEMENTS" may point at the array's
description (C3) or at the reference (C2). C2 is picked because B.2 groups 98
with 70 and 71, which are reference-side rules.

**105 — C3/3, alternative C4/4.**
A circular QUANTITY dependency can be read as breaking the whole record's
layout (C4). C3 is picked because the message names one entry.

**145, 146, 147 — C3/3, alternative C2/2.**
A missing CRYPT address, tag, or decrement is a field of the instruction (C2),
but no repair is stated, so the instruction cannot be assembled (C3).

**152 — C1/1, alternative C2/2.**
"SHOULD NOT BE USED AS DATA NAME" reads as advisory, like 186, and pairs with
178, which states its interpretation. If the compiler in fact rejected the name,
C2 would be right.

**166 — C3/3, alternative C4/4.**
A duplicate name inside a section may break every reference to it (C4). C3 is
picked because the message names one definition.

**188 — C3/3, alternative C4/4.**
A DO whose target is the wrong kind of name loses the DO statement (C3), but the
addressed procedure is then never entered (C4). C3 is picked; 108, the true
undefined-symbol case, holds C4.

**191 — C4/4, alternative C2/2.**
"IS NOT PROPERLY DEFINED" is weaker than "UNDEFINED SYMBOL". C4 is picked
because B.2 puts 191 and 108 under one rule.

**193 — C4/4, alternative C5/5.**
"LIMIT OF 63 FILES EXCEEDED" is a capacity condition, but the limit is an
attested language limit (J 90.01.04), not an internal table, and it is absent
from the D9.7 capacity map. C4 is picked.

**197 — C4/4, alternative C3/3.**
A record description with no record name may lose only the first entry (C3) or
the whole record (C4). C4 is picked because no record can be built at all.

**198 — C1/1, alternative C4/4.**
"NO RECORDS PROCESSED IN FILE 'NAME.1'" is read as an advisory about an unused
file, so nothing is lost. The C4 reading takes it as a report that the file's
I/O could not be generated. C1 is picked because the text states no failure and
no repair.

**209 — C1/1, alternative C4/4.**
"'NAME.1' HAS INSUFFICIENT BLOCKSIZE. BLOCKSIZE USED IS" + value. The trailing
value slot (D9.5) makes this a stated substitution, so the precedence rule gives
C1. Message 5, the near neighbor, states a requirement and no substitution and
stays C4.

**36 — C3/3, alternative C4/4.**
"CANNOT HAVE SUB-ORGANIZATION" loses the entry and every entry subordinate to
it, which is more than one statement but less than a record. C3 is picked.

## M1 rows check

`lib/src/lexer/severities.dart` now holds 227 rows: all 210 catalog ids in the
0-209 range, plus 17 non-historical ids from 900,00 through 916,00. Every
in-range row agrees with this table. No change is proposed.

M1 was the first milestone to need severities. It set 16 of the in-range rows.
The table below lists those 16 with their agreement check.

| id | M1 severity | this table | agree |
|---|---|---|---|
| 1,00 | 3 | C3 / 3 | yes |
| 52,00 | 2 | C2 / 2 | yes |
| 53,00 | 2 | C2 / 2 | yes |
| 62,00 | 1 | C1 / 1 | yes |
| 88,00 | 3 | C3 / 3 | yes |
| 100,00 | 2 | C2 / 2 | yes |
| 134,00 | 1 | C1 / 1 | yes |
| 144,00 | 3 | C3 / 3 | yes |
| 148,00 | 5 | C5 / 5 | yes |
| 150,00 | 2 | C2 / 2 | yes |
| 167,00 | 2 | C2 / 2 | yes |
| 168,00 | 2 | C2 / 2 | yes |
| 186,00 | 1 | C1 / 1 | yes |
| 189,00 | 1 | C1 / 1 | yes |
| 190,00 | 1 | C1 / 1 | yes |
| 194,00 | 3 | C3 / 3 | yes |

Two M1 rows set the anchors that this table then applies to the whole catalog,
so they are worth naming:

- **1,00 and 88,00 at C3** fix the rule that a card whose name is missing is a
  statement-level loss, not a file-level loss. This table extends the anchor to
  3, 4, 89, 96, 144, 153, 154, 161, 164, 176 and 207, and it forces the C2
  treatment of card *option* operands, because C3 is already taken by the whole
  card. Sub-rule 2 above states this.
- **194,00 at C3** fixes the rule that a data-description entry which cannot take
  its place in the hierarchy is a statement-level loss. This table extends the
  anchor to 40, 41, 42, 45, 46, 47, 81, 102, 103 and 105.

## The 900-series rows (ours)

The 900-series ids sit outside the attested 0-209 range, so they are not part of
the 210-row count above. D9.7 assigns them. Every one is our own message for a
condition the 1962 catalog does not cover. Their classes follow the same D9.2
rule, and `lib/src/lexer/severities.dart` carries the same justifications
inline. `lib/src/parser/parser_messages.dart` holds the message texts.

M1 set 900 to 904. M2 added 905 to 916. No change is proposed to any row.

| id | class | severity | what it reports | justification |
|---|---|---|---|---|
| 900,00 | C1 | 1 | a stray period | the period is ignored and scanning continues |
| 901,00 | C2 | 2 | an over-long name operand | the name operand cannot resolve |
| 902,00 | C3 | 3 | a card before the first division header (D2.3) | the card is ignored — statement-level loss |
| 903,00 | C3 | 3 | a card after `*FINISH` (D9.14) | the card is ignored — statement-level loss |
| 904,00 | C1 | 1 | a second compile control card | the duplicate card is ignored and compilation carries on |
| 905,00 | C4 | 4 | PATTERN recognized but not implemented (D9.12) | the file property is lost; calibrated against msg 110, the recognized-but-unimplemented COPY, at 4 |
| 906,00 | C2 | 2 | data-card coding that its type code forbids | the conflicting coding is ignored — clause-level loss |
| 907,00 | C3 | 3 | a type code the 7090 language does not have | the entry cannot bind to a type — entry-level loss |
| 908,00 | C2 | 2 | a Quantity field outside 1 to 32767 | the quantity specification is lost — clause-level loss |
| 909,00 | C1 | 1 | an unknown compile-card option | the option is ignored and compilation carries on |
| 910,00 | C3 | 3 | a subscripted condition-name (D5.6) | the construct is rejected and the sentence is deleted, matching the attested deletion messages 122, 125, and 126 |
| 911,00 | C1 | 1 | an AT END clause that is not a transfer (D6.6) | the clause is accepted; advisory only |
| 912,00 | C2 | 2 | an alphameric literal as an arithmetic operand outside TR | the operand is lost — clause-level loss |
| 913,00 | C3 | 3 | `A**B**C` without parentheses (D4.10) | no code is generated for the statement |
| 914,00 | C2 | 2 | more than three subscripts in one reference (D3.1) | the subscripted reference is lost |
| 915,00 | C5 | 5 | section nesting deeper than 18 (D9.7) | a compiler table capacity, hard-enforced |
| 916,00 | C4 | 4 | LOAD or OVERLAP, deferred (M2-11) | the verb's whole effect is lost; calibrated against msg 110, the deferred COPY, at 4 |

Three rows carry an alternative worth naming:

- **905,00 and 916,00 — C4/4, alternative C3/3.** Both report a construct that
  parses and generates nothing. The C3 reading calls that a statement-level
  loss. C4 is picked because msg 110, the attested message for the same
  situation, holds C4.
- **910,00 — C3/3, alternative C1/1.** The construct could be ignored with an
  advisory. D5.6 forbids that reading: it would invent element semantics that no
  source attests. The sentence is deleted, so C3.
- **915,00 — C5/5, alternative C3/3.** A capacity limit that a sentence cannot
  cause and a program can, so it is not recoverable by dropping one sentence.
  D9.7 fixes it at 5. Compare 187, which stays C3 because its limit is
  sentence-scoped.

## Build checks this table must pass (per D9.2 and D9.3)

1. All 210 ids 0-209 present, one row each.
2. C1 gives 1, C5 gives 5, and C2-C4 give 2-4 and match the largest-lost-unit
   rule.
3. 177 resolves to 3; 148, 149, 172, 183, 184 and 200-205 resolve to 5.
4. Every row carries `non-historical: true` and its one-line justification.
5. `--pedantic` changes no severity value.
