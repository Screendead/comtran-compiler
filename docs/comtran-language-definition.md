# COMTRAN Language Definition

**A structured definition of IBM Commercial Translator (COMTRAN) as it existed historically, prepared for compiler construction.**

This document is the working language reference for this repository's compiler project. It defines the *source language only* — it deliberately contains no compiler architecture, intermediate representations, grammars, or implementation strategy. It is a living reference: correct it against the manuals, never against modern expectations.

## Sources and authority

Everything here is extracted from the two surviving IBM manuals, converted to Markdown in [`comtran-manuals/`](../comtran-manuals/README.md):

| Cited as | Manual | Status |
|---|---|---|
| **(F p. *N*)** | F28-8043, *General Information Manual* (June 1960) — [index](../comtran-manuals/F28-8043/F28-8043.md) | The 1960 **language vision**. Cited by printed page number. |
| **(J *xx.xx.xx*)** | J28-6169-1, *709/7090 Commercial Translator Processor, Preliminary Reference Manual* (Jan 1962) — [index](../comtran-manuals/J28-6169/J28-6169.md) | The **implemented language** (field-test 709/7090 processor). Cited by IBM section code. **Authoritative wherever the two disagree.** |

Conventions inherited from the conversions: 1960s spellings ("alphameric", "imbedded") and genuine typos are preserved verbatim in quotations; the 1960s literal-delimiting quotation mark (card code 4-8) is rendered as a straight apostrophe `'`; overpunched digits are rendered with a combining overline (e.g. `9̅`). Paths like `images/page-050.png` refer to the 150-dpi page scans inside each manual's directory — the ground truth for any disputed reading.

**The F/J rule.** F28-8043 describes the full language as designed; J28-6169 describes what the January 1962 field-test processor actually accepted, and explicitly defers, restricts, or corrects many F features. Divergences are flagged **F/J divergence** where they arise and are catalogued in §8. A compiler writer must decide early which language is being implemented — the 1960 design (F) or the 1962 processor language (J); this document treats **J as definitive** and presents F material as design context and as the base text that J amends.

## Where to look

- Ambiguity catalog with resolutions, 68 entries: [§8.5](#85-consolidated-ambiguity-catalog-with-plausible-resolutions), lines 3960–4059.
- Severity codes and message-implied rules: [§8.4](#84-the-severity-code-system-and-rules-implied-by-the-diagnostics-j-appendix-9004), lines 3736–3959.
- F28-8043 vs J28-6169 conflicts: [§8.3](#83-f28-8043-vs-j28-6169-contradictions-and-divergences), lines 3598–3735.
- Deferred and removed features (F→J digest): [§8.2](#82-the-fj-delta-complete-digest-of-j-appendix-9001-deferred-features-restrictions-limitations), lines 3482–3597.
- Questions the manuals do not answer: [Open questions](#open-questions), lines 4280–4514.

## Contents

1. [Character set and lexical conventions](#1-character-set-and-lexical-conventions)
    - [1.1 Character set](#11-character-set)
    - [1.2 The literal-delimiting quotation mark](#12-the-literal-delimiting-quotation-mark)
    - [1.3 Words and name formation](#13-words-and-name-formation)
    - [1.4 Kinds of names](#14-kinds-of-names)
    - [1.5 Compound names (qualification)](#15-compound-names-qualification)
    - [1.6 Reserved words: the fixed vocabulary](#16-reserved-words-the-fixed-vocabulary)
    - [1.7 Constants and literals](#17-constants-and-literals)
    - [1.8 Operators, punctuation characters, and spacing](#18-operators-punctuation-characters-and-spacing)
    - [1.9 Coding forms, card columns, and continuation](#19-coding-forms-card-columns-and-continuation)
    - [1.10 Summary table of lexical limits](#110-summary-table-of-lexical-limits)
    - [1.11 Conversion caveats relevant to this section](#111-conversion-caveats-relevant-to-this-section)
2. [Overall program structure and procedure organisation](#2-overall-program-structure-and-procedure-organisation)
    - [2.1 The three descriptions (divisions) of a complete program](#21-the-three-descriptions-divisions-of-a-complete-program)
    - [2.2 Source deck structure: how a program reaches the compiler](#22-source-deck-structure-how-a-program-reaches-the-compiler)
    - [2.3 The structural hierarchy: expressions → clauses → sentences → sections → divisions](#23-the-structural-hierarchy-expressions-clauses-sentences-sections-divisions)
    - [2.4 Procedure-names: how statements are labeled](#24-procedure-names-how-statements-are-labeled)
    - [2.5 Sections: BEGIN SECTION … END](#25-sections-begin-section-end)
    - [2.6 Default flow of control and program termination](#26-default-flow-of-control-and-program-termination)
    - [2.7 Verbs: program verbs vs processor verbs, and the complete inventory](#27-verbs-program-verbs-vs-processor-verbs-and-the-complete-inventory)
    - [2.8 How procedures connect to the data and environment descriptions](#28-how-procedures-connect-to-the-data-and-environment-descriptions)
    - [2.9 Program size and structural limits (7090 implementation)](#29-program-size-and-structural-limits-7090-implementation)
    - [2.10 Ambiguities affecting this section (summary)](#210-ambiguities-affecting-this-section-summary)
3. [Data description and storage model](#3-data-description-and-storage-model)
    - [3.1 Files, records, and fields — the data hierarchy](#31-files-records-and-fields-the-data-hierarchy)
    - [3.2 The *DATA division and the data description card](#32-the-data-division-and-the-data-description-card)
    - [3.3 Type codes in detail](#33-type-codes-in-detail)
    - [3.4 The Description field in detail](#34-the-description-field-in-detail)
    - [3.5 Signed-number representation and overpunch](#35-signed-number-representation-and-overpunch)
    - [3.6 Mode, justification, and the machine storage model](#36-mode-justification-and-the-machine-storage-model)
    - [3.7 Lists, tables, and subscripts (declaration side)](#37-lists-tables-and-subscripts-declaration-side)
    - [3.8 Record length: fixed vs. variable (storage view)](#38-record-length-fixed-vs-variable-storage-view)
    - [3.9 Storage areas](#39-storage-areas)
    - [3.10 Numeric limits and defaults — summary](#310-numeric-limits-and-defaults-summary)
    - [3.11 F/J divergences in data description — summary](#311-fj-divergences-in-data-description-summary)
4. [Arithmetic and data-manipulation statements](#4-arithmetic-and-data-manipulation-statements)
    - [4.1 Arithmetic expressions](#41-arithmetic-expressions)
    - [4.2 Modes, precision, and mixed-mode evaluation (709/7090)](#42-modes-precision-and-mixed-mode-evaluation-7097090)
    - [4.3 The SET command — arithmetic assignment](#43-the-set-command-arithmetic-assignment)
    - [4.4 SET used with condition-names](#44-set-used-with-condition-names)
    - [4.5 The ADD command](#45-the-add-command)
    - [4.6 The ADD CORRESPONDING command](#46-the-add-corresponding-command)
    - [4.7 The MOVE command](#47-the-move-command)
    - [4.8 The MOVE CORRESPONDING command and CORRESPONDING matching rules](#48-the-move-corresponding-command-and-corresponding-matching-rules)
    - [4.9 Functions in arithmetic and data-manipulation statements](#49-functions-in-arithmetic-and-data-manipulation-statements)
    - [4.10 Restrictions and limits affecting this section (consolidated)](#410-restrictions-and-limits-affecting-this-section-consolidated)
    - [4.11 Cross-references](#411-cross-references)
5. [Control-flow statements](#5-control-flow-statements)
    - [5.1 Default sequential flow and sentence boundaries](#51-default-sequential-flow-and-sentence-boundaries)
    - [5.2 The conditional statement (IF ... THEN ... OTHERWISE)](#52-the-conditional-statement-if-then-otherwise)
    - [5.3 Conditional expressions](#53-conditional-expressions)
    - [5.4 The GO TO command](#54-the-go-to-command)
    - [5.5 The DO command](#55-the-do-command)
    - [5.6 The STOP command; STOP RUN](#56-the-stop-command-stop-run)
    - [5.7 Sections, procedure-names, and structural constraints on transfer targets](#57-sections-procedure-names-and-structural-constraints-on-transfer-targets)
    - [5.8 Numeric limits and restrictions bearing on control flow (J)](#58-numeric-limits-and-restrictions-bearing-on-control-flow-j)
    - [5.9 Flagged ambiguities (summary)](#59-flagged-ambiguities-summary)
6. [Input/output and report-generation facilities](#6-inputoutput-and-report-generation-facilities)
    - [6.1 The file model: record, file, block, buffer](#61-the-file-model-record-file-block-buffer)
    - [6.2 Locate and Transmit modes](#62-locate-and-transmit-modes)
    - [6.3 Record types and variable-length record options](#63-record-types-and-variable-length-record-options)
    - [6.4 The OPEN command](#64-the-open-command)
    - [6.5 The GET command](#65-the-get-command)
    - [6.6 The FILE command](#66-the-file-command)
    - [6.7 The CLOSE command and CLOSE ALL FILES](#67-the-close-command-and-close-all-files)
    - [6.8 Labels and non-standard label processing](#68-labels-and-non-standard-label-processing)
    - [6.9 The DISPLAY command](#69-the-display-command)
    - [6.10 The LOAD command (and OVERLAP) — deferred](#610-the-load-command-and-overlap-deferred)
    - [6.11 The worked examples of J 02.07.F](#611-the-worked-examples-of-j-0207f)
    - [6.12 Report generation: what exists and what does not](#612-report-generation-what-exists-and-what-does-not)
    - [6.13 Environment-card summary for I/O (cross-reference to §7)](#613-environment-card-summary-for-io-cross-reference-to-7)
    - [6.14 Ambiguities flagged in this section](#614-ambiguities-flagged-in-this-section)
7. [Special facilities and library conventions](#7-special-facilities-and-library-conventions)
    - [7.1 The Environment Description (J 02.06)](#71-the-environment-description-j-0206)
    - [7.2 Compiler control cards ($CMPLE, *FINISH) (J 02.01)](#72-compiler-control-cards-cmple-finish-j-0201)
    - [7.3 The library system — COPY, LIBRARY, INCLUDE (F design; deferred in J)](#73-the-library-system-copy-library-include-f-design-deferred-in-j)
    - [7.4 Program segmentation — OVERLAP and LOAD (F design; deferred in J)](#74-program-segmentation-overlap-and-load-f-design-deferred-in-j)
    - [7.5 Renaming and linkage — CALL, ENTER, CONTRL](#75-renaming-and-linkage-call-enter-contrl)
    - [7.6 Commentary conventions — NOTE and the period-blank rule](#76-commentary-conventions-note-and-the-period-blank-rule)
    - [7.7 The CRYPT facility — 709/7090 machine symbolic language (J 02.08)](#77-the-crypt-facility-7097090-machine-symbolic-language-j-0208)
    - [7.8 F/J divergence summary for this section](#78-fj-divergence-summary-for-this-section)
8. [Known ambiguities, underspecified behaviour, and plausible resolutions](#8-known-ambiguities-underspecified-behaviour-and-plausible-resolutions)
    - [8.1 Status of the sources](#81-status-of-the-sources)
    - [8.2 The F→J delta: complete digest of J Appendix 90.01 (deferred features, restrictions, limitations)](#82-the-fj-delta-complete-digest-of-j-appendix-9001-deferred-features-restrictions-limitations)
    - [8.3 F28-8043 vs J28-6169: contradictions and divergences](#83-f28-8043-vs-j28-6169-contradictions-and-divergences)
    - [8.4 The severity-code system and rules implied by the diagnostics (J Appendix 90.04)](#84-the-severity-code-system-and-rules-implied-by-the-diagnostics-j-appendix-9004)
    - [8.5 Consolidated ambiguity catalog, with plausible resolutions](#85-consolidated-ambiguity-catalog-with-plausible-resolutions)
9. [Sample-program observations that illuminate the language](#9-sample-program-observations-that-illuminate-the-language)
    - [9.1 Program-level structure as practiced](#91-program-level-structure-as-practiced)
    - [9.2 Coding-form usage in practice](#92-coding-form-usage-in-practice)
    - [9.3 Data description in practice](#93-data-description-in-practice)
    - [9.4 Environment description as actually written (J only)](#94-environment-description-as-actually-written-j-only)
    - [9.5 Procedure idioms, verb by verb](#95-procedure-idioms-verb-by-verb)
    - [9.6 What the compilation listing reveals about the source language](#96-what-the-compilation-listing-reveals-about-the-source-language)
    - [9.7 What the execution output reveals](#97-what-the-execution-output-reveals)
    - [9.8 Consolidated F-sample vs J-sample divergence table](#98-consolidated-f-sample-vs-j-sample-divergence-table)
    - [9.9 Flagged ambiguities (details in §8.5)](#99-flagged-ambiguities-details-in-85)
- [Open questions](#open-questions)
    - [Lexical](#lexical)
    - [Program structure and control cards](#program-structure-and-control-cards)
    - [Data description and storage model](#data-description-and-storage-model)
    - [Arithmetic and data manipulation](#arithmetic-and-data-manipulation)
    - [Control flow](#control-flow)
    - [Input/output](#inputoutput)
    - [Environment, library, and system](#environment-library-and-system)
    - [Sample-program loose ends](#sample-program-loose-ends)

---

---

## 1. Character set and lexical conventions

Sources: F28-8043 (June 1960 *General Information Manual*, cited "F p. N") and J28-6169-1 (Jan 1962 *709/7090 Processor Preliminary Reference*, cited "J xx.xx.xx"). Where they disagree, J describes the implemented language and is authoritative; divergences are flagged **F/J divergence**.

### 1.1 Character set

The basic character set of the source language consists of the 26 letters of the alphabet, the ten numerals 0–9, and twelve special characters ([F p. 12]). The Commercial Translator uses the card codes of IBM character **Set H**; all IBM sets use the same card codes, but a given special-character code prints differently in different sets (e.g. the 12 punch is a plus sign in Set H but an ampersand in certain other sets) ([F p. 12], note 1).

**Special characters (Set H)** ([F p. 12]):

| Name | Character | Card code |
|---|---|---|
| blank | (blank) | (blank) |
| plus sign | `+` | 12 |
| minus sign | `-` | 11 |
| multiplication sign | `*` | 11-4-8 |
| division sign | `/` | 0-1 |
| left parenthesis | `(` | 0-4-8 |
| right parenthesis | `)` | 12-4-8 |
| comma | `,` | 0-3-8 |
| period / decimal point | `.` | 12-3-8 |
| dollar sign | `$` | 11-3-8 |
| equal sign | `=` | 3-8 |
| quotation mark | `'` | 4-8 |

Rules about the blank:

- The blank **is a character**. A series of blanks is regarded as a single blank, *except* in alphameric literals or other constants, where each blank is a separate character ([F p. 12]; [F p. 27], rule 2). Numeric literals cannot contain any blanks ([F p. 27], rule 2).
- In numeric external (BCD) data fields, leading blanks are treated as leading zeros ([J 02.05.05], note 3) — a data-representation fact, see §3 (Data description and storage model).

**Machine character set vs. source character set.** Constants defined in the data description "may include any of the characters in the machine's character set" ([F p. 19]), which is larger than the twelve source special characters. The J manual exhibits the full machine set via the two collating sequences ([J 02.06.16]). The 709/7090 native sequence, lowest to highest, is:

```
0 through 9   =   '   +   A through I   ⟨+0⟩   .   )   −   J through R   ⟨−0⟩   $   *   blank   /   S through Z   ⟨rm⟩   ,   (
```

and the Commercial (705) sequence, selected by `COLLATE COM` on an Environment OPTION card, is:

```
Blank   .   ⟨loz⟩   ⟨gm⟩   &   $   *   −   /   ,   %   #   @   ⟨+0⟩   A through I   ⟨−0⟩   J through R   ⟨rm⟩   S through Z   0 through 9
```

(both [J 02.06.16] — **scan-resolved reading**, 2026-08-01: both displays re-read from the source scan at 600 dpi and independently verified; each prints as one logical line — the second physical line in each is a plain wrap. Glyph legend, shapes certain, BCDIC names inferred: `⟨+0⟩` = full-size zero with a plus above it, the 12-0 "plus zero" zone punch; `⟨−0⟩` = zero with a plain bar above it, the 11-0 "minus zero"; `⟨rm⟩` = two-bar double-dagger form, the IBM record mark (0-8-2); `⟨gm⟩` = three-bar form, the IBM group mark; `⟨loz⟩` = the IBM lozenge, a hollow squarish ring with corner spurs. Each letter zone group is followed by its own zone special — A–I by ⟨+0⟩, J–R by ⟨−0⟩, S–Z by ⟨rm⟩ — and the `=` after the digits is a listed collating character, not prose. The conversion's earlier best-effort rendering (`0̅` for both zero forms, `×` and `‡` for the others) under-differentiated these glyphs; see §8.5.8.) Note that `&`, `%`, `#`, `@` and the record/group-mark-type characters exist in the machine set (and hence can occur in data) but are not part of the source-language special-character list. The figurative constants HIGH.VALUE/LOW.VALUE take their values from whichever collating sequence is in effect — see §1.7.4.

**Overpunched digits.** The sign of an external-decimal field is carried as an overpunch (a 12- or 11-zone punch combined with a digit punch in one column). In the manual conversions an overpunched digit is rendered with a combining overline, e.g. `9̅`, `8̅`, `123̅` (see conversion notes to [J 02.05.05]–02.05.07). **F/J divergence:** F allows the `+`/`-` sign to be "entered as an 'overpunch' with either of the format characters 8 or 9, in either the units or high-order position of a field" ([F p. 80]); J restricts it: "The only sign specification which may be used for an external decimal field is an overpunched + or - in the rightmost position of the field. A + and - may not appear in the character by itself." ([J 02.05.05], note 1). Details of pictorials belong to §3.

**Illegal characters.** At compile time, "ILLEGAL CHARACTER REPLACED IN INTERNAL TEXT BY 0, AND IN EXTERNAL TEXT BY $" ([J 90.04], message 134,00); "ILLEGAL CHARACTER FOR CONSTANT OR LITERAL" is message 54,00 ([J 90.04]).

There is no lower case anywhere in the language: card codes define a single (upper-case) alphabet. Examples in F are "written completely in capital letters" ([F p. 38]).

### 1.2 The literal-delimiting quotation mark

The Set H "quotation mark" (card code 4-8) is the single delimiter for non-numeric literals and for all named constants ([F p. 12]; [F p. 19]). It is a single character — there is no distinct open/close quote. In the Markdown conversions of both manuals it is rendered throughout as a straight apostrophe `'` (conversion note, F ch. 2; repo conventions). Every quoted item in this reference, e.g. `'M'`, `'05'`, `'LOS ANGELES        15342 28516 21287'`, uses that rendering of the 4-8 punch.

- An alphabetic or alphameric literal may contain **any character of the basic set except the quotation mark itself** ([F p. 19], rule 1).
- Named constants "may include any of the characters in the machine's character set, including the quotation mark and the blank" ([F p. 19], rule 3) — but no representation (escape) for an embedded quotation mark is ever defined; see Ambiguity A1.
- A missing closing delimiter is diagnosed: "SECOND QUOTE MARK MISSING." ([J 90.04], message 167,00).

### 1.3 Words and name formation

**Word separation.** "All words are separated by blanks, or by any character which cannot legally be used in a word, such as an arithmetic operator" ([F p. 27], rule 1). Multiple blanks are treated as single blanks except within alphameric literals ([F p. 27], rule 2).

**Formation of names** ([F p. 15]): names are formed from the alphabetic characters, the numerals, and the period, subject to:

1. Names must not contain blanks.
2. Names must always begin with an alphabetic character.
3. They may contain from 1 to 30 characters.
4. They may neither begin nor end with a period; "imbedded" periods may be used within the name for readability.
5. They may be "qualified" (compounded) by other names to make them unique (§1.5).

J confirms the 30-character maximum ("names in the variable field may contain up to 30 characters", [J 02.08.02]; "Printing of names up to 30 characters in length", [J 90.02]) and applies "the same rules which are applied to Commercial Translator names" to CRYPT symbols, explicitly barring the quotation mark, left parenthesis, right parenthesis, and dollar sign from symbols, and the period as first or last character ([J 02.08.01]).

**The imbedded period** (a period surrounded by non-blank characters) has exactly two roles, by context: (1) in a "word" consisting wholly of numerals, or in a floating point number, it is a decimal point; (2) in any other context except within a literal it is the equivalent of a hyphen, connecting parts of a simple name ([F p. 27], rule 4). A period *followed by a blank* is a sentence terminator (§1.9.4).

**Names on cards.** A data-name longer than the 16-column Data Name field (columns 7–22) is continued onto the next card with a non-blank character in column 72; the processor closes up any blanks in the Data Name columns and combines the parts into one name ([F p. 67]). J generalizes: "All imbedded and leading blanks in the name fields of cards associated with an entry are eliminated and the non-blank characters are compressed to form a single name" ([J 02.03.01]). Names in the Data Name columns may be indented; indentation is ignored ([F p. 67]).

### 1.4 Kinds of names

Most names fall into three categories ([F p. 13]):

| Kind | Names | Notes |
|---|---|---|
| **Data-names** | kinds of data (storage areas), not specific values | Sub-categories: record-names, field-names, function-names, parameter-names, named constants, "and so on" ([F p. 13–14]). Every data-name and condition-name used in the procedure description must be defined in the data description ([F p. 16]; [J 02.05.01]). |
| **Procedure-names** | sentences or sections of procedure | Also called sentence-names or section-names ([F p. 14]). Written in the name margin before the statement they name (§1.9.1). Referenced by DO, GO TO, INCLUDE, OVERLAP, BEGIN SECTION, END ([F p. 14]). |
| **Condition-names** | a named value ("condition") of a conditional variable | Equivalent to a relational expression, e.g. MARRIED ≡ MARITAL.STATUS = 'M' ([F p. 22]). Assigned in the data description with type code COND ([F p. 71–72]). Condition-names may not be used in subscripts ([F p. 31]) and may not themselves be subscripted ([J 90.01.03]). |

Other name-like entities a compiler must recognize:

- **Division headers** `*PROCEDURE`, `*DATA`, `*ENVIRONMENT` — the division name preceded by an asterisk, written with the asterisk in the left-most name column (column 7); every entry following a header belongs to that division until the next header ([F p. 27]; [F p. 37], rule 1; [F p. 65]). Division headers must begin with single asterisks ([F p. 28], rule 12). Omission of a division header is a catastrophic compile error ([J 05.06.01]).
- **`deck.name`** on the $CMPLE compiler control card: "six or less characters chosen from the set appropriate for use in CT names", no imbedded blanks, leading blanks ignored ([J 02.01.01]). The compiler accepts an imbedded-blank deck.name without comment but the Loader then rejects it ([J 90.01.05], B.5).
- **PROGRAM.START** — a distinguished statement/section name recognized by the 7090 compiler as the execution starting point: "MORE THAN ONE -PROGRAM.START-. FIRST USED."; it "MUST BE A STATEMENT OR SECTION NAME" and "CANNOT BE A STATEMENT OR SECTION NAME ADDRESSED BY A -DO-" ([J 90.04], messages 141,00–143,00; also [J 90.02]). It appears nowhere in F.
- **Compiler-generated names** contain a right parenthesis, which no programmer name can contain — e.g. `GN)nnn` for unnamed statements/entries in the listing ([J 02.02.01]), `SYS)294` ([J 02.08.03]), constant-pool names `CP)+NN` (the "SYM)NNN" generated-name form, [J 90.02.03]; the leading hyphen printed at [J 90.01.05] item k is a dash introducing the notation, not part of the name — see §8.5.8), `SRAIJ`-style symbolic registers ([J 02.08.02]). Also duplicate source names are printed as `1)C`, `2)C` in listings ([J 90.02]).
- **Synonyms** created by the CALL verb are names in the ordinary sense; a synonym must always be a single name rather than a compound name, though it may be applied to a compound name ([F p. 59]). The (old.name) in CALL must be unique (or made unique by qualifiers) and may not be subscripted ([J 02.04.05] §5; [J 90.01.01]).
- **F/J divergence:** function-names and parameter-names (with type codes FUNCT and PARAM) are part of the 1960 language ([F p. 32–34], p. 72–73); "These two type codes described in the General Information Manual are no longer in the language" ([J 02.05.03], §6). See §3.

**Uniqueness.** Names need not be globally unique if qualification can make references unique (§1.5), but: a name associated with the RECORD type code must be unique, and a record defined within a section may not use the section.name as qualifier ([J 90.01.03]); a name must be unique within its section — "'NAME.1' IS NOT UNIQUE IN THIS SECTION." ([J 90.04], message 166,00), which by inference covers statement/section names, though the manual never says which name class the message addresses; a CONTRL name "MUST BE UNIQUE AND 6 CHARACTERS OR LESS" ([J 90.04], message 207,00).

### 1.5 Compound names (qualification)

A non-unique name is "qualified," or "compounded," by prefixing the name of a larger data item of which it is a part, e.g. `INPUT.MASTER ORDER.DATE` ([F p. 15]). There is no OF/IN connective — qualification is by juxtaposition. Rules ([F p. 15–16]):

1. Each name must be separated from the next by at least one blank (this is what distinguishes compound from simple names, since simple names may not contain blanks).
2. The names must be written in increasing order from the general to the specific, i.e. from the lowest to the highest level number.
3. No qualifying names are required that do not contribute to uniqueness (intermediate levels may be skipped, e.g. `INPUT.MASTER MONTH`).

Compounding is not limited to two levels; e.g. `INPUT.MASTER ORDER.DATE MONTH` ([F p. 15]). Section names can be used as parts of compound names ([F p. 26]).

J refinements and restrictions:

- Compound names are formed "without regard to REDEFs (or other type codes) and as a function of the level and position within the program of the simple names only" ([J 02.05.02], with worked examples in which the completely qualified name of H is `A G H`).
- For the CORRESPONDING option, "All qualifiers must be present and identical through the level of the name itself to meet the criteria of correspondence" ([J 02.04.04]).
- Qualified names may not be used in the Environment Description or in CRYPT instructions; names there must be one word only; CALL reduces a qualified name to a one-word name ([J 02.03.03], §C; [J 90.01.01]; [J 90.01.04]).
- Improper qualification is diagnosed: "'NAME.1' IS AN IMPROPERLY QUALIFIED NAME." ([J 90.04], message 101,00).
- Parsing hazard: in a DISPLAY statement, "Data names not intended to be used as qualifiers must be separated by commas; otherwise all but the last will be disregarded" ([J 90.01.01]) — i.e. juxtaposed names are always read as one qualified reference.

**Subscripts and compound names.** Subscripts are written in parentheses; either each level is subscripted individually — `PAGE (150) LINE (10) WORD (4)` — or all subscripts are collected after the (possibly compounded) final name — `PAGE LINE WORD (150, 10, 4)`; the two are equivalent ([F p. 30]). Multiple subscripts within one pair of parentheses are separated by single commas; as many as three subscripts may appear ([F p. 30]; [F p. 28], rule 10). Subscripts are written in descending order of level ([F p. 78]). A subscript is a name, a literal, or an arithmetic expression of the restricted form `a * VARIABLE ± b` (a, b literals; VARIABLE simple or compound but itself unsubscripted); it must represent a positive integral value ([F p. 31]). Arrays begin at element 1: "The initial value of an array is A(1) and not A(0)" ([J 02.04.07.01]). See §2 for expression semantics and §3 for storage layout.

### 1.6 Reserved words: the fixed vocabulary

#### 1.6.1 F28-8043 list (1960)

"All those words which are a fixed part of the Commercial Translator vocabulary are listed below... to assist the programmer in avoiding the use of any of them when choosing data-names and procedure-names" ([F p. 110]). Reproduced in full (73 words; † per the source footnote: "These words have a restricted usage only in data description; they may be used freely in procedure description"):

| | | | |
|---|---|---|---|
| ABS | FILE | LOW.VALUE | SECTION |
| ADD | FILES | LOW.VALUES | SET |
| ALL | FOR | LT | STOP |
| AND | FROM | MOVE | THAN |
| AS | †FUNCT | NOT | THEN |
| AT | GET | NOTE | TIMES |
| BEGIN | GIVING | ON | TO |
| BLANK | GO | OPEN | TR |
| BLANKS | GREATER | OR | TRANSLATOR |
| CALL | GT | OTHERWISE | TRUNCATED |
| CLOSE | HERE | OVERFLOW | USING |
| COMMERCIAL | HIGH.VALUE | OVERLAP | WHEN |
| †COND | HIGH.VALUES | †PARAM | WITH |
| †COPY | IF | †QUANTITY | ZERO |
| CORRESPONDING | IN | RECORD | ZEROS |
| DISPLAY | INCLUDE | †REDEF | |
| DO | IS | | |
| END | †LABEL | | |
| ENTER | LESS | | |
| EQUAL | †LIBRARY | | |
| EXACTLY | LOAD | | |

([F p. 110]; the source prints one alphabetical list flowing down three columns — the blank grid cells are the source's own vertical spacing between letter groups. Scan-checked against images/page-115.png, 2026-08-03.)

#### 1.6.2 J28-6169 key-word classification (1962, authoritative)

"Many of the reserved Commercial Translator words are usable as Procedure, Data and Environment names in certain situations as shown in the following key word lists. However, it is strongly recommended that the entire group be avoided altogether." ([J 02.03.02]).

**Group 1 — always Key words, never usable as programmer names in any division** ([J 02.03.02]):

| | | |
|---|---|---|
| BEGIN | IN | WHEN |
| FILE | LOW.VALUE | ZERO |
| FOR | LOW.VALUES | ZEROS |
| HIGH.VALUE | ON | |
| HIGH.VALUES | RECORD | |

**Group 2 — may not be used as Data or Procedure names** ([J 02.03.02]):

| | | | |
|---|---|---|---|
| ABS | END | INCLUDE | QUANTITY |
| ADD | ENTER | IS | RUN |
| ALL | EQUAL | LESS | SECTION |
| AND | EQUALS | LIBRARY | SET |
| AT | EXACTLY | LOAD | STOP |
| BLANK | FILES | LT | THAN |
| BLANKS | FROM | MOVE | THEN |
| CALL | GET | NOT | TIMES |
| CLOSE | GIVING | NOTE | TO |
| COMMERCIAL | GO | OPEN | TR |
| CORRESPONDING | GREATER | OR | TRANSLATOR |
| CRYPT | GT | OTHERWISE | TRUNCATED |
| DISPLAY | HERE | OVERFLOW | USING |
| DO | IF | OVERLAP | WITH |

**Group 3 — usable as Procedure and Data names providing the procedure or data item need not be referenced in the Environment Division** ([J 02.03.03]):

| | | | |
|---|---|---|---|
| ACTIVITY | COM | LOW | SEQ |
| BCD | CONSERVE | MULTI | SERIAL |
| BINARY | CONTROL | NO | SPACE |
| BLOCK | DEFER | OPENCOUNT | SPANS |
| BLOCKSIZE | ERROR | OPENF | TAPE |
| BUFFERCOUNT | FIND | OPENW | THROUGH |
| CARD | HIGH | OUTPUT | TIME |
| CHECKC | HOLD | PLACE | UNIT1 |
| CHECKF | INPUT | PRIMARY | UNIT2 |
| CHECKPOINT | KEYS | REEL | WORD |
| CKSUMS | LABEL | RETAIN | |
| CLOSER | LABELN | | |
| CLOSEW | LABELS | | |
| COLLATE | LENGTH | | |

**F/J divergences in the word lists:**

- New in J: **CRYPT**, **RUN** (STOP RUN is mandatory in every J program, [J 02.04.06] §9), **EQUALS** (all group 2), and the entire group-3 Environment vocabulary.
- In F but absent from all J lists: **AS** (INCLUDE, which uses AS, is deferred in J — [J 90.01.02], A.1.a.v), and the type codes **COND, COPY, FUNCT, PARAM, REDEF** (in J these are recognized positionally in the Type columns of the Data/Environment forms rather than listed as key words; FUNCT/PARAM are gone from the language entirely, [J 02.05.03] §6).
- Reclassified between F and J: **LABEL** (daggered in F — restricted usage in data description — becomes a J group-3 word, usable as a Data or Procedure name unless the item must be referenced in the Environment Division); **LIBRARY** and **QUANTITY** (daggered in F, i.e. free in procedure description, become J group-2 words, barred as Data or Procedure names) ([F p. 110]; [J 02.03.02]–02.03.03; scan-checked 2026-08-03).
- Misuse diagnostics: "'NAME.1' SHOULD NOT BE USED AS DATA NAME." (152,00); "PROCEDURE KEY WORD USED IN DATA OR ENVIRONMENT, INTERPRETED AS A DATA NAME." (178,00); "SENTENCE STRUCTURE ERROR. POSSIBLE ILLEGAL USE OF A KEY WORD." (192,00); "OPERATION DEFINED AS NAME OR FOUND IN NAME FIELD." (61,00) (all [J 90.04]).

#### 1.6.3 Notation of general forms (how the manuals mark fixed vs. programmer words)

In F's command "general forms," words fixed in the language appear in boldface capitals; programmer-supplied names/clauses appear in lower-case italics; `data.name.1, data.name.2, ... data.name.n` indicates a variable number of operands; "except for imbedded periods within italicized words, any punctuation shown in the general form of a command is a fixed and necessary part of the command" ([F p. 38]). In F Appendix 2, brackets `[ ]` enclose optional words and phrases and the brace `{` indicates a choice of variant forms ([F p. 108]). J uses the same bracket/brace conventions on its card formats (e.g. [J 02.01.01], [J 02.06.16]). The language has no separate category of ignorable "noise" words: every word shown in a general form outside brackets is required.

### 1.7 Constants and literals

A *constant* is any value or group of symbols used in the program without alteration; written directly in a procedure statement it is a *literal*; defined and named in the data description it is a *named constant*; pre-named in the processor it is a *figurative constant* ([F p. 17]).

#### 1.7.1 Numeric literals

Rules ([F p. 18]):

1. All literals are limited to **50 characters** in length and may not be carried over from one line to the next on the procedure form.
2. Numeric literals may contain only numerals, not more than one decimal point, and a plus or minus sign. The decimal point is required except where it would be the last character of the literal; in that case it must **not** be used. The decimal point is noted for alignment but occupies no storage and is not counted in the literal's length.
3. If the literal is to be operated on arithmetically, it must contain **not more than 20 digits**.
4. Floating point form: the fraction, the symbol F, then the exponent; fraction and exponent may each carry a plus or minus sign; F occupies no storage and is not counted in the length; base 10 only. F's examples: `1.5F3`, `15F2`, `.15F4`, `2F-3` ([F p. 18]).
5. Numeric literals must **not** be enclosed in quotation marks.

**F/J divergence — floating point literals.** J tightens the form to "the standard scientific decimal form" `fraction F±exponent` with these rules ([J 02.04.02]):

- a) Both fraction and exponent may be signed or unsigned (positive assumed).
- b) **A decimal point must be present in the fraction** (`20.F+01` is a floating point literal, but `20F+01` is interpreted as an arithmetic expression). This invalidates F's point-free examples `15F2`, `2F-3`.
- c) The F must be followed by at least one digit, signed or unsigned (`20.F0`).
- d) `F` converts to single precision floating point; `FF` signals **double precision** floating point (new in J).

Related J diagnostics: "INCORRECT USAGE OF PERIOD, SIGN, OR F FOR CONSTANT OR LITERAL." (53,00); "MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL." (52,00 — the limit value is not stated; see Ambiguity A2); floating overflow/underflow in conversion (55,00; 56,00) (all [J 90.04]).

#### 1.7.2 Alphabetic and alphameric literals

Rules ([F p. 19]):

1. May contain any character of the basic character set **except the quotation mark**; the blank counts as a character.
2. Limited to **50 characters**; may not be carried from one line to another on the procedure form. J: an alphameric literal "may not exceed fifty characters in length and must be complete upon a single line" ([J 02.04.02.01] §B.2, in the DISPLAY discussion); "ALPHABETIC LITERAL EXCEEDS 50 CHARACTERS." (150,00) and "ALPHABETIC LITERAL EXTENDS ACROSS CARDS." (168,00) ([J 90.04]).
3. All non-numeric literals must be enclosed in quotation marks to distinguish them from names — even when they contain characters (arithmetic symbols, blank) that could not occur in names.

The rules of punctuation and spacing do not apply within literals ([F p. 28], rule 7). In the Environment description an "ALPHABETIC LITERAL FOLLOWING KEY WORD CANNOT EXCEED 6 CHARACTERS." ([J 90.04], message 160,00); the COND Environment card takes a 12-octal-digit alphameric literal `'nn'` ([J 02.06.17]).

#### 1.7.3 Named constants

Defined in the data description (see §3 for the entry format); referred to in procedure statements like any data-name, but should not be used so as to change the value ([F p. 19]). All the literal-formation rules apply except ([F p. 19]):

1. Named constants are **not limited as to length**; on the data description form they may be carried over line to line, written as a series of *complete* constants, one per line, at a level lower than that of the name given to the total constant; the processor reassembles them ([F p. 19]; worked table example, [F p. 74]). The General Note restates the mechanism: if a constant is carried over, the portion on each line must be a complete constant enclosed in quotation marks; the continuation-indication column is **not** used, and no blanks are assumed between successive lines ([F p. 83]).
2. All named constants, **including wholly numeric ones, must be enclosed in quotation marks** ([F p. 19]; [F p. 81]: "Constants, unlike literals, must always be enclosed in quotation marks, even though they may be wholly numeric").
3. May include any character of the machine's character set, including the quotation mark and the blank; a blank in an otherwise numeric constant makes it alphameric ([F p. 19]). (On the embedded quotation mark, see Ambiguity A1.)

In the data description entry the constant's value is written in the Description columns after the field pictorial, separated by at least one blank ([F p. 81], example `V99 '05'`). **J note:** literals in the Data Description continued on multiple lines *in violation of* the [F p. 83] rules "are handled correctly" by the 7090 processor, but "use of this characteristic ... should not be made if compatibility with other processors is desired" ([J 02.03.01], §2.c). An over-long alphabetic constant draws "LENGTH OF ALPHABETIC CONSTANT EXCEEDS INTERNAL TABLE CAPACITY AND SHOULD BE SUBDIVIDED." ([J 90.04], message 148,00). Constant/pictorial length-matching and sign conventions for external/internal decimal constants (e.g. pictorial `999̅` requires constant `123̅`; internal decimal constants take leading +/-, trailing +/-, or no sign) are given at [J 02.05.06]–02.05.07 — see §3.

#### 1.7.4 Figurative constants

Constants whose names are pre-assigned in the processor; no data description entry is needed ([F p. 19]). The complete list ([F p. 19]):

```
ZERO or ZEROS
BLANK or BLANKS
LOW.VALUE or LOW.VALUES
HIGH.VALUE or HIGH.VALUES
```

LOW.VALUE and HIGH.VALUE refer to the lowest and highest characters in the collating sequence of the system in use ([F p. 20]). J fixes the values: "HIGH.VALUE will be considered to be the left parenthesis, (, and LOW.VALUE the zero, 0, unless the Commercial collating sequence (COM) is specified in the Environment Description. The Commercial HIGH.VALUE is 9 and the LOW.VALUE is blank." ([J 02.04.01]).

A figurative constant fills the entire target area with the named character ([F p. 20]: MOVE ZEROS TO COUNTER, MOVE BLANKS TO AMOUNT). Figurative constants may also be used as data-names, e.g. as operands in a DO ... USING list ([F p. 33–34]).

J restrictions ([J 02.04.01]):

- In comparisons: ZERO may be compared to either numeric or alphameric fields; HIGH.VALUE, LOW.VALUE and BLANK may be compared to alphameric fields only.
- With MOVE and SET: figurative constants may be used as source fields, but (i) may not be moved to variable length arrays (fields carrying QUANTITY IN) — though they may be moved to a particular element of one — and (ii) may not be moved to fields longer than 2¹⁵ − 1 characters ([J 02.04.01]; message 181,00 says "FIELD LONGER THAN 32766 CHARACTERS", [J 90.04] — see Ambiguity A6).
- Result-by-target-type chart ([J 02.04.02]; \* = an error message is given for each doubtful or illegal usage; # = value dependent on the collating sequence specified, Commercial or 709):

| Figurative Constant | Alphameric | External Decimal | Internal Decimal | Edited Field | Floating Point | Scientific Decimal |
|---|---|---|---|---|---|---|
| BLANK or BLANKS | blanks | blanks\* | 0's\* | blanks\* | 0's\* | blanks\* |
| ZERO or ZEROS | 0's | 0's | 0's | 0's Edited | 0's | 0's Edited |
| LOW.VALUE or LOW.VALUES | 0's# or blanks | 0's #\* or blanks | Illegal\* | 0's #\* or blanks | Illegal\* | 0's #\* or blanks |
| HIGH.VALUE or HIGH.VALUES | ('s# or 9's | ('s #\* or 9's | Illegal\* | ('s #\* or 9's | Illegal\* | ('s #\* or 9's |

### 1.8 Operators, punctuation characters, and spacing

#### 1.8.1 Operator inventory

Arithmetic operators ([F p. 21]; [F p. 45]): binary `+` (addition), `-` (subtraction), `*` (multiplication), `/` (division), `**` (exponentiation); unary `-` (negation), `ABS` (absolute value), `TR` (truth value). If the operand of a unary operator is an expression it must be enclosed in parentheses ([F p. 45]). Relational expressions, each with full and abbreviated form ([F p. 21]):

| Relational expression | Abbreviated form |
|---|---|
| IS GREATER THAN | GT |
| IS NOT GREATER THAN | NOT GT |
| IS EQUAL TO | = |
| IS NOT EQUAL TO | NOT = |
| IS LESS THAN | LT |
| IS NOT LESS THAN | NOT LT |

Logical connectives: AND, OR, NOT ([F p. 23]). Precedence, symbol-pair legality tables, and evaluation order are covered in §2 (see [F p. 105–107]; [J 02.04.05]); a J-specific lexical bound: "NUMBER OF OPERATORS IN THIS SENTENCE EXCEEDS MAXIMUM OF 60. SENTENCE DELETED FROM TEXT." ([J 90.04], message 171,00).

#### 1.8.2 Punctuation and spacing rules

The complete F rule set ([F p. 27–28]), all of which a scanner must honor:

1. All words are separated by blanks or by any character which cannot legally be used in a word (rule 1).
2. Multiple blanks = one blank, except within alphameric literals; numeric literals cannot contain blanks (rule 2).
3. Each sentence is terminated by a period **followed by a blank**. If the blank is omitted the period is treated as an imbedded period — "except where the period is found in Column 72 of the procedure description form" (rule 3; a blank is assumed to follow column 72, rule 14).
4. The imbedded period is a decimal point in all-numeral words and floating point numbers; elsewhere (outside literals) it connects parts of a simple name (rule 4).
5. Successive imperative clauses in a sentence must be separated by **single commas**; extra blanks are permitted and ignored (rule 5; also [F p. 25]).
6. Arithmetic operators may be written with or without surrounding blanks (`A + B * C` ≡ `A+B*C`). Two successive arithmetic operators are illegal **unless the second is TR or ABS**; `A * -B` is illegal, write `A * (-B)` (rule 6).
7. Punctuation/spacing rules do not apply within literals (no quotation mark allowed inside) or within data-description constants (any character allowed); non-numeric literals and all named constants are quote-enclosed (rule 7).
8. Floating point numbers are written as numeric literals (rule 8).
9. Parentheses must group multiple terms acted on by a single operator, per the rule that operators act on the next named item or next parenthetical expression (rule 9).
10. Subscripts must be enclosed in parentheses; multiple subscripts within one pair are separated by single commas (rule 10).
11. Parentheses may be used freely for clarity in arithmetic and compound conditional expressions; where ambiguity would result from omission they **must** be used (rule 11).
12. Division headers must begin with single asterisks (rule 12).
13. Punctuation and spacing peculiar to a verb is given in the verb's general format (rule 13; e.g. the parentheses in the assigned GO TO and in CALL are fixed parts of those commands — [F p. 49], [F p. 59]).
14. Line carry-over must follow the break-point rules of the respective form; a blank is assumed to follow Column 72 of the procedure form and Column 71 of the data description form (rule 14).
15. When a function is named as an operand in a procedure statement, the substituted data-names are placed in **double parentheses** immediately after the function-name, separated by single commas, e.g. `MINIMUM ((RAIL.EXPRESS, AIR.FREIGHT, PARCEL.POST))` (rule 15; [F p. 34]). (Function references are absent from J — see §1.4 and §3.)

Additional J parser facts: redundant right parentheses are eliminated with a message (113,00), a redundant left parenthesis is diagnosed (114,00), and "-WHEN- SUBSTITUTED FOR -IF- BECAUSE OF IMPROPER USE." (170,00) (all [J 90.04]).

The DO indexing notation `FOR index.name = p(q)r` (initial value, increment in parentheses, terminal value, no intervening blanks shown in any example) is a fixed notation of the DO command ([F p. 50]; [F p. 109]); see §2.

### 1.9 Coding forms, card columns, and continuation

Source programs are read as a deck of punched cards (or card images on tape); each line of a form is one card ([F p. 37]). The compiler listing reproduces "body of source program cards (columns 7-72)" ([J 02.02.01]) — columns 1–6 and 73–80 are never part of the language text.

#### 1.9.1 Procedure Description form (free-form text)

Fields ([F p. 37]):

| Columns | Field | Content |
|---|---|---|
| 1–3 | Ctl. | With Serial, one six-column sequence field; first three positions common to all lines of a page |
| 4–6 | Serial | Card sequence; column 6 usually blank or zero so inserts 011…019 can go between 010 and 020 |
| 7–12 | Procedure Name | The "name margin"; procedure-names "stick out" into it |
| 13–72 | Text | Procedure statements in free form |
| 73–80 | Identification | Optional; same for all lines of a page |

Procedure-name rules ([F p. 37]):

1. The procedure header `*PROCEDURE` is a special name that must appear on a separate line preceding each procedural portion of a source program.
2. Procedure-names, like data-names, may contain up to thirty characters; unlike data-names "they must be followed by a period and a blank."
3. Procedure-names are written left-justified in the name margin and, if longer than six characters, extend into the Text area.

Text layout rules ([F p. 37]):

1. A named sentence follows its name on the same line, to the right of the name margin.
2. An unnamed sentence must begin on a separate line, to the right of the name margin.
3. Succeeding lines of a sentence must begin to the right of the name margin (indentation for readability is allowed).
4. When a section is begun, only the BEGIN SECTION command may appear on the same line as the section name.
5. `END section.name` is written as a sentence on a separate line.

Continuation is implicit: "Continuation of Procedure text on successive lines is determined by the nature of the text; no continuation character is used" ([J 02.03.01], §2.a). Each word or literal must be complete upon a line, "since the processor assumes a blank following column 72 of Procedure lines" ([J 02.03.01], §2.c; [F p. 28], rule 14). Literals in particular may never be carried over ([F p. 18–19]; [J 90.04], message 168,00).

**F/J divergence — procedure-name period:** F requires the period-and-blank after a procedure-name ([F p. 37]); the 7090 compiler is lenient: "Procedure.names not followed by a period (.) and blank are handled properly; no diagnostic message is given" ([J 90.01.03], A.1.a.ix). See Ambiguity A3.

#### 1.9.2 Data Description form (fixed columnar format)

The data description "is more rigid; it does not allow 'free form' description" ([F p. 65]). Column layout ([F p. 65]):

| Columns | Number of columns | Use |
|---|---|---|
| 1–6 | 6 | Card Serial Number (Ctl. 1–3 + Serial 4–6) |
| 7–22 | 16 | Name |
| 23–24 | 2 | Level Indication |
| 25–30 | 6 | Type |
| 31–35 | 5 | Quantity |
| 36 | 1 | Mode |
| 37 | 1 | Justification |
| 38–71 | 34 | Description |
| 72 | 1 | Continuation Indication |
| 73–80 | 8 | Identification |

Lexical facts per field (semantics in §3):

- **Division header:** `*DATA` must precede the first entry of each consecutive group of data description cards, asterisk in column 7, the only entry on the card apart from serial and identification ([F p. 65]).
- **Name (7–22):** any assigned name, left margin assumed just left of column 7, indentation ignored; blank if no name; >16-character names continue to the next card via a non-blank column 72, with blanks in the name columns closed up ([F p. 67]).
- **Level (23–24):** every entry must have a level number; any number 1–99; numbers need not be consecutive ([F p. 68]). J: "Any numbers 01-99 may be used ... Leading zeros are optional and all level numbers less than 10 are right justified by the compiler" ([J 02.05.01]); "DATA NAME LACKS LEVEL." ([J 90.04], message 194,00).
- **Type (25–30):** blank, or one of the type codes `RECORD COND FUNCT PARAM REDEF COPY LABEL` ([F p. 71]). J adds `RCDMRK` ([J 02.05.03]) and removes FUNCT/PARAM ([J 02.05.03], §6); COPY is deferred ([J 90.01.03]; "-COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM.", [J 90.04], message 110,00).
- **Quantity (31–35):** repetition count for the entry; blank ⇒ 1 ([F p. 77]; [J 02.05.04]). Maximum Quantity 2¹⁵ − 1 ([J 02.05.04]). Quantity may be nested to as many as three levels in F's account ([F p. 77]).
- **Mode (36):** `I` internal (binary), `E` external (BCD) ([F p. 78]; [J 02.05.04]). Illegal mode character ⇒ external substituted ([J 90.04], message 189,00).
- **Justify (37):** `L`, `R`, or blank (= packed) ([F p. 78–79]). Illegal justification character ⇒ not justified ([J 90.04], message 190,00).
- **Description (38–71):** may contain, in order when combined on one line and separated by one or more blanks: format characters (field pictorial), constants, data-names for REDEF/COPY, the word LIBRARY plus a library data description name, or QUANTITY IN plus a field name ([F p. 79]). A pictorial is limited to 30 characters ("DATA DESCRIPTION CONTAINS PICTORIAL WHICH EXCEEDS LEGAL LIMIT OF 30 CHARACTERS.", [J 90.04], message 100,00). Any non-format character in a pictorial makes the whole pictorial be interpreted as a name ([J 02.05.06], §1.e). Format-character inventory (`A X 9 8 * V . S $ , + - F (n)`) and semantics are §3 material ([F p. 80]; [J 02.05.05]).
- **Cont. (72):** any non-blank character marks the next card as a consecutive part of this entry; applies to overflow from the Name or the Description columns only ([F p. 84]). J: "The name and description fields only of Data Description entries may be continued. All other specifications ... must be made on the first card of that entry since these fields are not scanned on continuation cards" ([J 02.03.01], §2.d; also "DATA OR ENVIRONMENT FIXED FIELD INFORMATION SHOULD BE PUNCHED IN ONLY THE FIRST CARD OF A MULTIPLE CARD GROUP. POSSIBLE CONTINUATION CHARACTER ERROR.", [J 90.04], message 186,00). Break points must fall between words: a blank is assumed at the end of each line (the processor "replaces the contents of column 72 with a blank in Data and Environment lines", [J 02.03.01], §2.c; [F p. 83], General Note). Constants are the exception — continued as complete quote-enclosed constants per line without the continuation column, and with no assumed blanks between lines ([F p. 83]).
- **Identification (73–80):** optional program-identifying code, any characters of the basic set, no effect on processor or object program ([F p. 84]).

**Entry termination.** "Data and Environment entries are considered complete when column 72 is blank. The period (.) must not be used to signal completion. In these sections, a period is considered part of the previous word, thus creating an undefined name." ([J 02.03.02], §3.b; likewise for Environment specifications, [J 02.06.02].) F does not state a data-entry terminator; J is authoritative.

#### 1.9.3 Environment Description form and compiler control cards

The Environment form (see §5/§6 for semantics) has: Serial 4–6 (Ctl. 1–3), Name 7–22, Type 25–30, Description (options) 31–71, Cont. 72, Identification 73–80 (J 02.06.01, form facsimile). The first card of each specification group may carry a name in columns 7–22 and must carry one of the type codes FILE, SPECIF, POOL, GROUP, CONTRL, OPTION, COND in columns 25–30; continuation is by non-blank column 72; a card that should begin a new specification (i.e. one following a card whose column 72 is blank) but lacks a type code is deleted with an error message; a type code appearing on a continuation card is ignored ([J 02.06.01.01]). "A period (.) must not be used to signal the end of a specification" ([J 02.06.02]).

Compiler control cards (J only): a `$CMPLE` card must precede each source program — `$CMPLE` in columns 1–6, `deck.name` in columns 8–13 (any position, no imbedded blanks, leading blanks ignored), options from column 16 separated only by commas (the first blank terminates the option list), and an optional `secondary.identifier` in columns 55–72 (any characters) ([J 02.01.01]–02.01.02). The `*FINISH` card, punched from column 7, delimits the extent of the source statements and must be followed by an end of file ([J 02.01.02]).

#### 1.9.4 Statement termination and commentary

- "Procedure statements are terminated by the first period (.) followed by a blank. Any information following this period blank is considered to be commentary." ([J 02.03.01], §3.a). Likewise: "A period (.) followed by a blank in a procedure statement terminates analysis of the statement except when they appear within an alphabetic literal; any information in the same card which follows the period is assumed to be commentary. No diagnostic comment is made." ([J 90.01.03], A.1.a.ix). A card not properly terminated draws "PREVIOUS CARD NOT PROPERLY TERMINATED. PERIOD ASSUMED." ([J 90.04], message 62,00).
- The NOTE command is the deliberate commentary mechanism — "terminated by the first period that is followed by a blank" and permitted to contain "any combination of characters from the allowable character set" ([F p. 59]); it affects only the listing. See §7 (the NOTE command).
- The DISPLAY command's operand scan runs "up to, but not including, a comma or period not enclosed in quotation marks" ([F p. 54]).
- Neither manual defines the treatment of entirely blank cards (see Open questions).

#### 1.9.5 Serialization, sequence checking, identification

- **F/J divergence — sequence checking.** F: the serial field "will be sequence-checked by the processor" on the procedure form ([F p. 37]), and data description serial numbers "will be checked for correctness of sequence"; blank collates before 0, so a blank column 6 permits later insertions (numeric collating sequence: blank, then 0–9) ([F p. 67]). J: "Card serial numbers in columns 1-6 of source decks are not sequence checked by the compiler." ([J 02.03.01], §A.1).
- Serial numbers do appear as the first column of the J source listing; the second column is a compiler-assigned statement number of the form `xxxxx,00` — three to six digits, the two digits after the comma identifying the clause, the digits before it the line; `9999,99` references errors not confined to a single statement ([J 02.02.01]). These statement numbers cross-reference the error-message list ([J 02.02.01]; Appendix 90.04).
- Identification columns 73–80 are optional and inert on both forms ([F p. 37]; [F p. 84]).

### 1.10 Summary table of lexical limits

| Item | Limit | Citation |
|---|---|---|
| Name length (all names; also CRYPT variable-field names) | 1–30 characters | [F p. 15]; [J 02.08.02] |
| Data Name card field / continuation | 16 columns (7–22), continue via col 72 | [F p. 67] |
| Literal length (numeric or alphameric), one line only | 50 characters | [F p. 18–19]; [J 02.04.02.01]; [J 90.04] msgs 150, 168 |
| Numeric literal used arithmetically | ≤ 20 digits | [F p. 18] |
| Field pictorial length | 30 characters | [J 90.04] msg 100,00 |
| Level numbers | 1–99 (J: 01–99, leading zeros optional) | [F p. 68]; [J 02.05.01] |
| Quantity (repetition count) | ≤ 2¹⁵ − 1 | [J 02.05.04] |
| Subscripts per reference | ≤ 3 | [F p. 30] |
| Indices controlled by one DO | ≤ 3 | [F p. 51] |
| Operators per sentence | ≤ 60 | [J 90.04] msg 171,00 |
| deck.name / CONTRL name | ≤ 6 characters | [J 02.01.01]; [J 90.04] msg 207,00 |
| Alphabetic literal after an Environment key word | ≤ 6 characters | [J 90.04] msg 160,00 |
| Files described | ≤ 63 | [J 90.01.04] |
| Internal dictionary (all names, programmer + generated) | ≈ 3500 | [J 90.01.05] |
| Number of sections | ≈ 35 | [J 90.01.05] |
| Depth of nested sections | ≈ 18 | [J 90.01.05] |
| Levels in a data hierarchy | ≈ 23 | [J 90.01.05] |
| Index expressions `a * VARIABLE ± b` | ≈ 50 | [J 90.01.05] |
| Positional indicators (unique subscripted names) | ≈ 90 | [J 90.01.05] |
| Array dimensions (explicit or implicit Quantity) | ≈ 85 | [J 90.01.05] |
| QUANTITY IN specifications | ≈ 25 | [J 90.01.05] |
| Generated constants in constant pool | ≈ 500 | [J 90.01.05] |
| Figurative-constant move target | ≤ 2¹⁵ − 1 chars (msg says 32766) | [J 02.04.01]; [J 90.04] msg 181,00 |
| Scientific-decimal fractional portion | ≤ 16 digits | [J 02.05.05] note 4 |

### 1.11 Conversion caveats relevant to this section

- The Set H quotation mark (4-8 punch) is rendered `'` throughout both conversions (F ch. 2 conversion note).
- Overpunched digits are rendered with a combining overline (`9̅`, `8̅`, `123̅`); in the J source the overpunch is printed as a small raised +/− above the digit on 02.05.07 but as an overline on 02.05.05 (J ch. 02.05 conversion note).
- The two collating-sequence displays at [J 02.06.16] contain print-train glyphs the conversion transcribed only approximately (`0̅`, `×`, `‡`); the identities are now scan-resolved — see the legend in §1.1 and §8.5.8.
- F's subtraction/negation dash is rendered `−` (minus sign) in some F chunks and `-` in others; the `±` in the subscript form `a * VARIABLE ± b` is a distinct glyph in the source (F ch. 2/3 conversion notes).
- The J example mode indicator "IR999" ([J 02.03.03]) was flagged best-effort by the conversion note; scan-resolved as the letter I — the face distinguishes 1 (flagged) from I (bare stem). See §8.5.8.

---

## 2. Overall program structure and procedure organisation

This section defines what a complete COMTRAN (Commercial Translator) program *is*: its three descriptions (divisions), the physical source-deck structure that delivers them to the processor, the expression → clause → sentence → section hierarchy of the procedure text, procedure-names and sectioning, the default flow of control, and the full verb inventory divided into program verbs and processor verbs. F28-8043 (June 1960) gives the language design; J28-6169-1 (Jan 1962) is authoritative for the implemented 709/7090 language. Divergences are flagged inline.

### 2.1 The three descriptions (divisions) of a complete program

"All Commercial Translator programs are composed of three divisions, the *Procedure Description*, the *Data Description*, and the *Environment Description*. The first of these contains the procedure statements of which the program is composed. The second provides the processor with information about the data to be used in the object program. The third is used to make certain technical connections between the program and the machine system on which it will be run" ([F p. 26]). Informally, "A Commercial Translator program consists primarily of *procedure description* and *data description*" ([F p. 16]); the environment description is machine-dependent and in 1960 was deferred to the individual processor publications ([F p. 26]). For the 709/7090, the compiler "analyzes Commercial Translator Data, Procedure and Environment Descriptions and CRYPT symbolic machine language instructions and produces a relative binary object program deck" ([J 02.00]).

Division roles, in brief:

| Division | Header | Contents | Detailed in |
|---|---|---|---|
| Procedure Description | `*PROCEDURE` | Procedure statements — clauses, sentences, sections; both program and processor commands ([F p. 16], p. 37) | see the Procedure verbs/commands section of this reference |
| Data Description | `*DATA` | Entries reserving storage and describing organization, format, level structure of every named datum, named constant, and condition-name ([F p. 16], p. 26) | see §3 (Data description and storage model) |
| Environment Description | `*ENVIRONMENT` | External physical factors: FILE, SPECIF, POOL, GROUP, CONTRL, OPTION, COND cards ([J 02.06.01.01], 02.06.01.01–02.06.02) | see the Environment description section of this reference |

Key architectural principles the manuals state explicitly:

- The procedure description is *machine-independent*; the data description "is not entirely machine independent" ([F p. 3]). The environment description exists precisely so that machine-dependent factors "may usually be changed without affecting the logical description of the problem, as contained in the Procedure and Data Description parts" ([J 02.06.01.01]).
- Separation of procedure and data descriptions is deliberate: either may be changed without modifying the other ([F p. 3]).
- Every data-name and condition-name used in the procedure description "must be properly accounted for in the data description" ([F p. 16]). J restates and hardens this: "The name of each data field referenced in Procedure statements or Environment Descriptions must appear in the name field of a Data Description entry. Neither storage allocation nor assignment of data characteristics is made for data fields not so named" ([J 02.05.01]).

#### Division headers and interleaving

"It is not necessary that these three divisions appear as separate entities. If appropriate, the programmer may write a portion of one, then a portion of another, and so on. However, each such portion must be properly labeled with a *division header*. Each header consists of the name of the division, preceded by an asterisk" ([F p. 27]). The three headers are, verbatim:

```
*PROCEDURE
*DATA
*ENVIRONMENT
```
([F p. 27])

- Headers are written "in the 'name margin' of the form used for the procedure description ... or in the name columns of the form used for the data description. In other words, the asterisk always appears in the left-most name column, followed immediately by the remainder of the header" ([F p. 27]). Division headers must begin with single asterisks ([F p. 28], punctuation rule 12).
- "All entries following a division header are assumed to be a part of the specified division" ([F p. 27]).
- "The procedure header, \*PROCEDURE, is a special name that must appear on a separate line preceding each procedural portion of a source program to distinguish it from data description or environment description" ([F p. 37]).

**F/J divergence / confirmation:** J never restates the interleaving rule, but its diagnostic list presupposes it: compiler message 87,00 reads `PROBABLE PROGRAM CONTINUITY ERROR. PROGRAM FLOWS INTO *DATA.` ([J 90.04.01]), which can only arise if a `*DATA` portion may physically follow procedure text. The compiled sample program uses one portion of each division in the order `*DATA`, `*ENVIRONMENT`, `*PROCEDURE` ([J 90.05], listing PDF pp. 192–197) — treat that as the canonical ordering, with interleaving permitted (see Ambiguity register). Within the environment division, "The SPECIF card(s) may appear anywhere within the environment division" ([J 02.06.07]).

CRYPT (709/7090 symbolic machine language) portions may additionally be embedded "at any logical point in his program" via `ENTER CRYPT`, terminated by `ENTER COMMERCIAL TRANSLATOR` ([J 02.08.01], 02.08.03); see §2.7 under ENTER.

### 2.2 Source deck structure: how a program reaches the compiler

Source programs are read "in the form of a deck of punched cards or their equivalent on tape; each line of the programming form becomes one card in the source program deck" ([F p. 37]).

#### 2.2.1 The $CMPLE card

"A $CMPLE card must precede each source language program. It is recognized by the Commercial Translator Monitor (CTM) for purposes of operational control and interpreted by the Commercial Translator compiler to initiate processing of source language statements" ([J 02.01.01]). Its general form, verbatim:

```
1  -  6      8  -  13       16
$CMPLE       deck.name      [NODECK]        [,LIST]         [,DICT]
                            [,LOAD]         [,LOGIC]        [,FILES]
                            [,MAP]          [,NOGO]

             55        -        72
             [secondary.identifier]
```
([J 02.01.01])

Rules a compiler writer needs:

- `deck.name` is "the primary deck identifier composed of six or less characters chosen from the set appropriate for use in CT names. The name may begin in any of the positions but must not include imbedded blanks. Leading blanks are ignored by the compiler" ([J 02.01.01]). The complete deck.name is punched in columns 1-6 of all Loader symbolic control cards in the object deck ([J 02.01.01]). Caution: "The Compiler accepts without comment a deck.name containing imbedded blanks and punches it in Loader symbolic control cards. A deck.name of this form is not acceptable to the Loader and will prevent execution of the object program" ([J 90.01.05]).
- "The options used must not be separated by blanks as the first blank terminates the list of options. The options must be separated only by commas" ([J 02.01.01]).
- Option meanings (compile-time behaviour, summarized): NODECK — omit punching the object deck (a deck is also suppressed automatically when a severity-5 error occurs); LIST — symbolic listing of generated instructions; DICT — list the dictionary of relative locations of all names; LOAD — write object program on a utility tape and pass control to the Loader (execution suppressed if NOGO taken, or a source error of severity code greater than 1, or an undefined generated symbol); LOGIC — Loader lists origin/extent of "all program sections", system subroutines and buffer assignments (implies LOAD); FILES — list I/O unit assignments; MAP — "an option yet to be specified"; NOGO — load but do not execute ([J 02.01.01]–02.01.02).
- `secondary.identifier` (cols 55–72, any characters) is printed in the output-listing heading and punched into the \*CTEND Loader card ([J 02.01.02]).

#### 2.2.2 The *FINISH card and end-of-file

"The \*FINISH card delimits the extent of the source language statements to be compiled. The form of the card is:"

```
7
*FINISH
```
"Note that this card must be followed by an end of file" ([J 02.01.02], referring to [J 04.02] and 05.03). "Each Commercial Translator job must be followed by an end-of-file" ([J 04.02.01]). The end-of-file card "should be thought of as an integral part of every job deck" ([J 05.03.01], which gives its physical punch format — operator-procedure detail outside this definition's scope). A missing \*FINISH is diagnosed: `132,00 END OF FILE ON JOB TAPE WITHOUT *FINISH CARD.` ([J 90.04.01]).

A complete compile job deck on the system input, from the manual's own stacked-input example ([J 05.03.02]):

```
$ID            JOB1                Accounting card is optional
$CMPLE
                BCD
                Source
                Program
                Cards
        *FINISH                    This card precedes end-of-file on COMPILE jobs.
End-of-file-card
```
([J 05.03.02]; $ID is optional. The "Source Program Cards" are the division portions of §2.1, each introduced by its division header.)

If the object program itself reads SYSIN, "the input cards must be placed in a separate file immediately following the job to be run" ([J 05.03.01]).

#### 2.2.3 Compiler output (as it reveals source structure)

Normal output is a relocatable column-binary deck — Symbolic Control cards, \*CTEXT, Relative Binary Program Deck (Control Break Table, File Check Table, Text), \*CTEND ([J 02.02]; deck format in Appendix 90.03 — see the object-deck section of this reference). Note the 90.01 deferrals: no control break table and no file check table are actually punched ([J 90.01.04]). The list tape carries the source listing with, per line: (a) source card sequence number; (b) "statement number assigned by the Compiler to the Procedure sentence, Data Description entry or Environment card. It is of the form xxxxx,00"; (c) card body, columns 7–72, in which "In some cases, names generated by the Compiler, i.e., GN)nnn, are shown in the name field of Procedure statements or Data entries unnamed by the programmer" ([J 02.02]). Statement numbers have three to six digits; "The last two are separated from the preceding digit(s) by a comma and they tell which clause is being referenced. The digit(s) preceding the comma tell which line is being referenced. The statement number 9999,99 is an exception. It is used to reference errors which are not confined to a single source statement" ([J 02.02]). This confirms that the compiler tracks structure to the granularity of individual clauses within a sentence.

#### 2.2.4 The procedure coding form (card columns)

The procedure description is written "in 'free-form' text on a programming form ... it has just four fields" ([F p. 37]):

| Field | Columns | Rules |
|---|---|---|
| Ctl. + Serial | 1–6 | One field; the first three spaces are "the same for all lines on one page"; used for card sequence via numbers and/or alphabetics; column 6 usually blank or zero so inserts 011…019 can go between 010 and 020 ([F p. 37]) |
| Procedure Name | 7–12 | The "name margin"; procedure-names written left-justified here, "sticking out" into the margin ([F p. 37]) |
| Text | 13–72 | Free-form procedure statements ([F p. 37]) |
| Identification | 73–80 | Optional program identification, same for all lines of a page ([F p. 37]) |

**F/J divergence — sequence checking:** F states the Ctl./Serial information "will be sequence-checked by the processor" ([F p. 37]); J states flatly "Card serial numbers in columns 1-6 of source decks are not sequence checked by the compiler" ([J 02.03.01]). J governs.

Line-placement rules for text ([F p. 37], verbatim in substance):

1. "A named sentence follows its name. That is, it begins to the right of the name margin, on the same line as its name."
2. "An unnamed sentence must begin on a separate line and to the right of the name margin."
3. "Succeeding lines of a sentence must begin to the right of the name margin. (If desired, they may be indented to facilitate reading the text.)"
4. "When a section of procedure is begun, only the BEGIN SECTION command may appear on the same line as the name of the section."
5. "To end a section, the command 'END section.name' is written as a sentence, i.e., on a separate line."

Continuation and break-point rules ([J 02.03.01]):

- Data and Environment entries needing more than one card put "a non-blank character in column 72" to signal continuation; "Continuation of Procedure text on successive lines is determined by the nature of the text; no continuation character is used."
- "In all sections each word or literal must be complete upon a line since the processor assumes a blank following column 72 of Procedure lines and replaces the contents of column 72 with a blank in Data and Environment lines." (F states the equivalent rule: "a blank is assumed to follow Column 72 of the procedure description form and Column 71 of the data description form", [F p. 28] — the same behaviour, not a divergence: the data form's text ends at column 71 because column 72 is its continuation-indication column ([F p. 66]), so F's "blank after column 71" and J's "column 72 replaced with a blank" describe the same rule.) The 7090 processor tolerates Data Description literals continued across lines in violation of the F rules, but "Use of this characteristic of the 7090 processor should not be made if compatibility with other processors is desired" ([J 02.03.01]).
- Only the name and description fields of Data Description entries may be continued; "All other specifications to be made for an entry must be made on the first card of that entry since these fields are not scanned on continuation cards" ([J 02.03.01]). Imbedded and leading blanks in continued name fields are eliminated and the characters compressed into a single name ([J 02.03.01]).

Statement/entry termination ([J 02.03.01]–02.03.02):

- "Procedure statements are terminated by the first period (.) followed by a blank. Any information following this period blank is considered to be commentary." (No diagnostic is issued for such commentary: [J 90.01.03].)
- "Data and Environment entries are considered complete when column 72 is blank. The period (.) must not be used to signal completion. In these sections, a period is considered part of the previous word, thus creating an undefined name." The same applies to Environment specifications: "A period (.) must not be used to signal the end of a specification" ([J 02.06.02]).

For files read from the on-line card reader, "only columns 1 through 72 are read" ([J 02.06.04]) — relevant to object-time data, not source decks, but stated on the Environment FILE card.

### 2.3 The structural hierarchy: expressions → clauses → sentences → sections → divisions

The language "may be helpful to think of ... as existing on two different levels": the *elements* (characters, fixed words, punctuation, names, literals — see the language-elements section of this reference) and the *syntax*, "how to fit elements together properly" ([F p. 7]).

#### Expressions

"[O]ne basic structural building block is an *expression;* this is defined as any grouping of elements which always establishes a unique value. An arithmetic expression can take on any numeric value whereas a conditional expression may only be true or false" ([F p. 7]). Expressions are components of clauses; their formation rules (operators, relations, AND/OR/NOT, truth functions, subscripts, functions) are covered in the expressions section of this reference ([F pp. 20–24]; operator hierarchy [J 02.04.05.01]).

#### Clauses

"Sentences ... are composed of one or more shorter units, known as *clauses*. There are two kinds of clauses: imperative and conditional" ([F p. 24]).

- **Imperative clause** — "a group of words that expresses a complete command. ... It always begins with a verb and may contain one or more operands of the verb" ([F p. 25]). Operands may be data-names, procedure-names, condition-names, literals, figurative constants, and arithmetic expressions ([F p. 25]). "Commands are independent clauses which may stand alone" ([F p. 7]). A command "normally consists of a verb followed by one or more operands and may be written as an imperative clause or as a sentence" ([F p. 35]).
- **Conditional clause** — "consists of a conditional expression introduced by the word IF and terminated by the word THEN. ... The word THEN defines the limit of the conditional expression to be tested; it will always be followed by an imperative clause" ([F p. 25]). "Conditional clauses are dependent clauses and must always be followed by at least one command" ([F p. 8]).

#### Sentences

"A Commercial Translator sentence ... expresses a complete and independent thought. It must contain at least one imperative clause and may contain, in addition, one conditional clause and one or more additional imperative clauses. It is terminated by a period, which must be followed by a blank ... Imperative clauses within the same sentence must be separated by commas" ([F p. 25]).

Structural/punctuation semantics of the sentence:

- "When a conditional clause is used in a sentence, it must begin the sentence, and it must be followed by one or more imperative clauses to be executed if the prescribed condition is met" ([F p. 25]). At most one conditional clause per sentence ([F p. 25]).
- Alternative action: the word OTHERWISE (written "without intervening punctuation") followed by one or more imperative clauses; "If the conditional expression should prove false, and if the sentence does not contain the word OTHERWISE, the conditional sentence will cause no action and the system will proceed to the next sentence in the program" ([F p. 25]; also [F p. 7]).
- The terminating period must be followed by a blank "to distinguish it from the 'imbedded period' used in names and from the decimal point used in numeric literals" ([F p. 25]). "Should the blank be omitted, the period will be treated as an 'imbedded period,' except where the period is found in Column 72 of the procedure description form" ([F p. 27], rule 3 — because a blank is assumed after column 72, [F p. 28] rule 14).
- The imbedded period (a period surrounded by non-blank characters) is a decimal point in an all-numeral word or floating point number, and otherwise (outside literals) "the equivalent of a hyphen" joining parts of a simple name ([F p. 27], rule 4).
- "Successive imperative clauses in a sentence must be separated by single commas"; extra blanks are permitted but ignored ([F p. 27], rule 5). Multiple blanks are treated as single blanks except inside alphameric literals ([F p. 12], p. 27 rule 2). All words are separated by blanks or by any character that cannot legally appear in a word ([F p. 27], rule 1).
- J diagnostics enforce sentence structure: an unterminated card yields `62,00 PREVIOUS CARD NOT PROPERLY TERMINATED. PERIOD ASSUMED.`; a statement without a proper verb, or with more than one verb where one is expected, is deleted from text (125,00; 126,00); an incomplete statement is deleted (122,00) ([J 90.04.01]).

Sample sentences ([F p. 25]):

```
ADD 1 TO COUNTER.
GO TO TAX.CALCULATION.
STOP.
IF MARRIED THEN MOVE NAME TO MAILING.LIST.M,
    ADD 1 TO COUNTER.
IF GROSS.PAY LT NET.PAY THEN GO TO ERROR.ROUTINE.
IF OUT.OF.ZONE THEN DO BILLING.ROUTINE.A OTHERWISE
    DO BILLING.ROUTINE.B.
```

#### Sections and divisions

Sections group successive sentences under one name (§2.5); divisions are the three descriptions (§2.1). "Sentences are *not* grouped into sections for the purpose of clarifying the logic or the structure of the program for the benefit of the system ... Sectioning, in the Commercial Translator, is used for the purpose of naming portions of procedure" ([F p. 26]).

### 2.4 Procedure-names: how statements are labeled

"Procedure-names are names assigned to individual portions of the program so that one procedure can refer to another" ([F p. 14]). "Procedure-names may be assigned to any sentence or section of the program. (A section consists of one or more successive sentences.) ... Procedure-names may also be referred to as sentence-names or section-names, as appropriate" ([F p. 14]). "A procedure-name identifies a fixed set of procedure statements" — unlike a data-name, which identifies a storage area with varying contents ([F p. 16]). Assignment "consists merely of writing the procedure-name before the statement or statements to which it refers" ([F p. 16]).

Formation and placement rules:

1. General name-formation rules apply (letters, digits, imbedded periods; begin with a letter; no blanks; see the names/elements section of this reference, [F p. 15]).
2. "Procedure-names, like data-names, may contain up to thirty characters. Unlike data-names, however, they must be followed by a period and a blank" ([F p. 37]).
3. "Procedure-names are written left-justified in the name margin and, if longer than six characters, extend into the 'Text' area" ([F p. 37]).
4. A named sentence begins on the same line as its name; see the line rules in §2.2.4 ([F p. 37]).

**F/J divergence — the trailing period:** J notes "Procedure.names not followed by a period (.) and blank are handled properly; no diagnostic message is given" ([J 90.01.03]). The period-blank is thus mandatory in the language definition but not enforced by the 7090 compiler.

J-side behaviours:

- Unnamed procedure statements (and unnamed data entries) are assigned compiler-generated names of the form `GN)nnn`, which appear in the name field of the listing ([J 02.02]). The sample program shows an unnamed CALL sentence listed as `GN)000` and unnamed `END` sentences as `GN)077`, `GN)078`, `GN)083` ([J 90.05], listing PDF pp. 195–197).
- Names must be resolvable: a transfer to something that is not a statement or section name is bypassed with a diagnostic (`127,00`), as is a transfer into a DO-addressed procedure (`128,00`) ([J 90.04.01]).
- Sections interact with name uniqueness: message `166,00 'NAME.1' IS NOT UNIQUE IN THIS SECTION.` ([J 90.04.01]); "Where necessary, the names of sections can be used as parts of compound names" ([F p. 26]); but "If the record is defined within a section the section.name may not be used as a qualifier of the record.name" ([J 90.01.03]). See Ambiguity register on section scoping.
- Qualified (compound) names are legal in procedure statements but "may not be used in the Environment Description or in CRYPT instructions. Data and Procedure names used in these sections must be of one word only. The verb CALL enables the programmer to reduce a qualified name to a one-word name to fulfill this requirement" ([J 02.03.03]).

### 2.5 Sections: BEGIN SECTION … END

"A section consists of one sentence, or a group of successive sentences, which has been given a name for reference purposes" ([F p. 26]). BEGIN SECTION and END "are used to delimit sections of procedure and thus extend the range of a procedure-name. ... Unless BEGIN SECTION and END are used, a procedure-name applies only to the sentence which follows it" ([F p. 56]). "If a procedure consists of more than one sentence, it must be defined as a section in order to be named" ([F p. 49]).

General form, verbatim:

```
procedure.name.  BEGIN SECTION.
     any sentence.
     .
     .
     .
     any sentence.
END procedure.name.
```
([F p. 57])

Rules:

- "The beginning of a section must be identified by a procedure-name, followed by a period. The name must then be followed by the words BEGIN SECTION" ([F p. 26]). Only BEGIN SECTION may share the line with the section name; `END section.name` is written as a sentence on a separate line ([F p. 37]).
- The name appears at both ends; "The second occurrence is required because sections of procedure may be 'nested,' i.e., one section may be contained within a larger one" ([F p. 57]). "Sections may be 'nested' ... but each such section must be wholly contained—it cannot overlap another section" ([F p. 26]). J enforces proper nesting and closure: `64,00 CANNOT -END- SECTION WHEN NONE ARE OPEN.`, `65,00 CANNOT -END- SECTION 'NAME.1' BEFORE SECTION 'NAME.2'.`, `66,00 ONE OR MORE SECTIONS NOT CLOSED.` ([J 90.04.01]).
- The END sentence must stand alone: `179,00 -END- SECTION MUST BE THE ONLY CLAUSE IN THE SENTENCE.` ([J 90.04.01]).
- "Normally the terminating sentence, 'END procedure.name,' is not itself named. There is one exception to this rule: The END sentence in a procedure associated with a DO command may be named in order to provide a reference point at the end of the procedure" ([F p. 57]; mechanism explained at [F p. 53] — a conditional early exit does `GO TO EXIT.` where `EXIT.   END procedure.name.` preserves the DO's loop-control linkage). The sample program uses exactly this (`BOND.END. END BOND.ROUTINE.`, `SEARCH.END. END SEARCH.`, [J 90.05] listing PDF p. 197).
- A section addressed by a DO "becomes a closed subroutine; it can be entered only through the use of one or more DO commands" ([F p. 57]; also [F p. 50]: entry "not by any other means such as transfer of control to a sentence within the procedure or through the normal passage of control to the first sentence of the procedure"; multiple DOs addressing one procedure are allowed). J diagnoses violation of the fall-through half of the rule: `99,00 PROBABLE PROGRAM CONTINUITY ERROR. PROGRAM FLOWS INTO STATEMENT OR SECTION 'NAME.1' ADDRESSED BY A -DO-.` ([J 90.04.01]), and refuses a GO TO whose target is a DO-addressed name (`128,00`; the analogous entry-point rule is `143,00` — PROGRAM.START may not be DO-addressed).
- Data substitution form: sections used as parameterised procedures are opened with

```
BEGIN SECTION USING parameter.1, parameter.2, ...
     parameter.n GIVING function.1, function.2, ... function.n
```
([F p. 57]). The parameters are replaced at object time by the data of the DO command's USING phrase; the functions are results delivered to the DO's GIVING phrase; function-names may also be invoked directly in arithmetic expressions with arguments in double parentheses ([F pp. 57–58]; details in the DO/functions coverage of the verbs section of this reference). **F/J divergence:** the Data Description type codes PARAM and FUNCT that F requires for these names ([F p. 34]) "are no longer in the language" ([J 02.05.03]); the J compiler still processes USING/GIVING and function references (diagnostics 30,00; 68,00; 72,00–75,00, [J 90.04.01]) — see Ambiguity register.

Significance of sections beyond naming (things a compiler writer must support):

- DO, LOAD and OVERLAP operate on sections: "The usefulness of these commands would be seriously impaired if they could not operate on pieces of procedure larger than sentences" ([F p. 57]). (LOAD/OVERLAP are deferred in J; §2.7.)
- Environment OPTION cards can scope compilation modes to a section: `[IN section.name]` "enables the programmer to limit the modal specification [COLLATE COM or CONSERVE SPACE/TIME] to a particular section. ... the mode of generation reverts to the normal mode at the end of the specified section. There is no restriction on the number of times these modes may be altered" ([J 02.06.17]).
- Environment CONTRL cards may define common areas by `section.name` or `sentence.name.1 TO sentence.name.2` (exclusive of sentence.name.2) for merging separately compiled programs ([J 02.06.15]) — mechanization deferred ([J 90.01.04]).
- The Loader's LOGIC option lists "the origin and extent of all program sections" ([J 02.01.02]).

Numeric limits on sections (approximate maxima, [J 90.01.05]): number of SECTIONS 35; depth of nested sections 18. Exceeding the section table gives `149,00 NUMBER OF SECTIONS IN PROGRAM EXCEEDS INTERNAL TABLE CAPACITY.` ([J 90.04.01]).

### 2.6 Default flow of control and program termination

- "During the execution of the object program the procedure is normally executed in the order in which it appears in the source program. The control commands are used primarily to specify a departure from this sequence" ([F p. 48]). Object code position is determined "by the relative position of items in the source deck" (Location Counter 0, [J 90.02.01]).
- A false conditional sentence with no OTHERWISE proceeds to the next sentence ([F p. 25]). A conditional GO TO whose conditions are all false, and an assigned GO TO whose index is outside 1…n, both pass control "to the next clause or sentence in sequence" ([F pp. 48–49]).
- DO transfers to the named sentence/section and returns control to the clause or sentence following the DO ([F pp. 49–50]). J caveat: "A DO section will always be performed at least once regardless of the values of the loop control variables" ([J 90.01.02]).
- Sequential flow must never run into a DO-addressed procedure (message 99,00) nor into a `*DATA` portion (message 87,00) ([J 90.04.01]) — the programmer must route around both with GO TO.
- STOP: "The STOP command is used to specify a halt in the object program. ... STOP n ... Restarting the machine causes execution of the object program to be resumed beginning with the next command in sequence" ([F p. 54]). A dead-end halt is made by following STOP with an unconditional GO TO back to it ([F p. 54]).
- **J requirement — STOP RUN:** "A STOP RUN instruction must be included in each program to provide for transfer of control to the CT Supervisor at conclusion of execution of the object program. All open files are closed prior to this transfer of control as if a CLOSE ALL FILES had been supplied" ([J 02.04.06]). Its absence is diagnosed: `175,00 NO -STOP RUN- IN PROGRAM.` ([J 90.04.01]). The sample program ends its main line `CLOSE ALL FILES, STOP RUN.` ([J 90.05], listing PDF p. 196).
- Entry point: the manuals never define it in the language sections. The J error messages imply a distinguished name `PROGRAM.START` ("MORE THAN ONE -PROGRAM.START-. FIRST USED."; "-PROGRAM.START- MUST BE A STATEMENT OR SECTION NAME."; "-PROGRAM.START- CANNOT BE A STATEMENT OR SECTION NAME ADDRESSED BY A -DO-.", [J 90.04.01]), and [J 90.02.01] notes the first word of the object program is "not necessarily PROGRAM.START". At load time "The Loader will normally use the starting point of the first program of combined segments as the starting point for the combined deck", modifiable by the \*START Loader card ([J 03.02]). See Ambiguity register.
- Memory model: "An object program produced by the Commercial Translator system is organized as one loading of storage unless the programmer specifies otherwise by means of the OVERLAP command" ([F p. 55]). In J, OVERLAP/LOAD are deferred, so "programs may not be segmented into separate memory loads at this time" ([J 90.01.05]) — the whole object program must fit one core load.

### 2.7 Verbs: program verbs vs processor verbs, and the complete inventory

"In the Commercial Translator language, a verb is a word that prescribes an action. Verbs are not used in a declarative sense" ([F p. 12]). Two categories:

- **Program verbs** — "Verbs which act at object time" ([F p. 13]); commands built on them "state the data processing steps to be carried out by the object program" ([F p. 8]).
- **Processor verbs** — "Verbs which act on the processor when the source program is translated" ([F p. 12]). "The processor commands ... tell the processor *how* to organize the object program rather than *what* the object program is to do" ([F p. 8]). "In general, the processor commands do not generate instructions in the object program" ([F p. 55]).

Verbs are distinct from *operators* (IF, THEN, arithmetic symbols, relations, etc.), which also cause operations but are not verbs ([F p. 13]). "Commercial Translator verbs may be easily recognized by the fact that all of them are words which serve also as verbs in the English language" ([F p. 13]). The system is "open-ended": "the list of verbs and associated commands is never closed" ([F p. 35]).

The complete F verb inventory, verbatim ([F p. 35]):

```
OPEN     \
GET       |  Input/Output
FILE      |
CLOSE    /

MOVE        Data Transmission

SET      \
ADD      /  Arithmetic

GO TO    \
DO        |  Control
STOP     /

LOAD      \
DISPLAY   /  Miscellaneous
```

```
OVERLAP
BEGIN SECTION
END
INCLUDE
CALL
NOTE
ENTER
```

#### Program verbs

| Verb | Category ([F p. 35]) | One-line purpose | Where detailed |
|---|---|---|---|
| OPEN | Input/Output | Initiates handling of one or more files (`OPEN file.name...` / `OPEN ALL FILES`); required before GET/FILE ([F p. 39]) | I/O section of this reference; [J 02.07] |
| GET | Input/Output | Makes the next record of an open file available (`GET RECORD FROM file.name` / `GET record.name`), optional `AT END` clause ([F pp. 39–40]; J replaces F's definition of the second form — [J 02.07.04]) | I/O section; [J 02.07.04]–02.07.06 |
| FILE | Input/Output | Places a record in an output file (`FILE record.name` / `FILE record.name IN file.name`); record remains available ([F pp. 40–41]) | I/O section; [J 02.07.08] |
| CLOSE | Input/Output | Terminates use of files (`CLOSE file.name...` / `CLOSE ALL FILES`); every opened file must ultimately be closed ([F p. 41]); J: CLOSE ALL FILES'd files may not be reopened ([J 02.04.06]) | I/O section; [J 02.04.06] |
| MOVE | Data Transmission | Moves data (with automatic editing) from one storage area to one or more others; MOVE CORRESPONDING moves same-named fields of groups ([F pp. 42–43]; [J 02.04.03]–02.04.05) | verbs section; §3 for editing/pictorials |
| SET | Arithmetic | `SET variable(s) = arithmetic expression` (replacement; TRUNCATED, ON OVERFLOW options); also `SET condition.name` to set a conditional variable ([F pp. 44–46]; [J 02.04.05]) | verbs section |
| ADD | Arithmetic | Adds a quantity to one or more variables; ADD CORRESPONDING adds same-named fields ([F p. 47]) | verbs section |
| GO TO | Control | Transfer of control: unconditional, conditional (`...WHEN...`), and assigned (`GO TO (p1,...,pn) ON index`) forms ([F pp. 48–49]) | verbs section |
| DO | Control | Executes a closed subroutine (sentence or section) and returns; EXACTLY n TIMES, up-to-3-index looping `FOR i = p(q)r`, and USING…GIVING data substitution ([F pp. 49–53]) | verbs section |
| STOP | Control | Halts the object program displaying n; restart resumes in sequence ([F p. 54]); J adds mandatory STOP RUN terminator ([J 02.04.06]) | verbs section; §2.6 |
| LOAD | Miscellaneous | Brings an overlapped procedure from external storage into the shared area ([F p. 54]). **Deferred in J** ([J 90.01.03]) | verbs section |
| DISPLAY | Miscellaneous | Presents low-volume information/messages on the display device (on-line 716 printer for 709/7090) ([F pp. 54–55]; [J 02.04.02.01]) | verbs section |

#### Processor verbs

| Verb | One-line purpose | J status | Where detailed |
|---|---|---|---|
| OVERLAP | Assigns two or more procedures to the same storage area for LOAD-time alternation ([F pp. 55–56]) | **Deferred**: "Implementation of these verbs [LOAD and OVERLAP] has been deferred" ([J 90.01.03]); no program segmentation ([J 90.01.05]) | verbs section |
| BEGIN SECTION | Opens a named section; optional USING…GIVING for parameterised procedures ([F pp. 56–57]) | Implemented ([J 90.05] passim); PARAM/FUNCT data type codes removed ([J 02.05.03]) | §2.5 |
| END | Closes the named section; sentence must contain nothing else ([F p. 57]; [J 90.04.01] message 179,00) | Implemented | §2.5 |
| INCLUDE | Extracts a library procedure into the program (`INCLUDE` at end / `INCLUDE HERE` in place), with AS and WITH…FOR name substitution ([F p. 58]) | **Deferred**: "Mechanization of the INCLUDE verb has been deferred, and consequently no library facilities are currently available" ([J 90.01.02]) | verbs section |
| CALL | Declares synonyms: `CALL (old.name.1) new.name.1, ...`; synonyms must be single names; may rename compound names ([F p. 59]) | Implemented; (old.name) must be unique, may not be subscripted; avoid record.names ([J 02.04.05]; [J 90.01.01]); needed to give one-word names for Environment/CRYPT use ([J 02.03.03]) | verbs section |
| NOTE | Places explanatory commentary in the listing only; "will not produce instructions in the object program"; terminated by the first period followed by a blank ([F p. 59]) | Implemented | verbs section |
| ENTER | Switches source language: `ENTER coding.language` / `ENTER COMMERCIAL TRANSLATOR` ([F p. 59]) | Restricted: "There are only two forms which this command may take: ENTER CRYPT and ENTER COMMERCIAL TRANSLATOR" ([J 02.04.02.01]); CRYPT rules at [J 02.08] | verbs section; CRYPT coverage |

#### Relationship between program and processor commands

"they cannot be intermixed in source program sentences. For example, it is meaningless to write sentences such as: IF A = B THEN GO TO C OTHERWISE OVERLAP SECTION.1, SECTION.2." ([F p. 60]). "Processor commands, with the exception of BEGIN SECTION and END, should be written as unnamed sentences. This rule makes it impossible for a program command to transfer control to a processor command. ... This is not to say, however, that the two types of commands cannot appear in sequence in a source program" ([F p. 60]). The sample program's first `*PROCEDURE` statement is an unnamed CALL sentence, listed under generated name GN)000 ([J 90.05], listing PDF p. 195).

Presentation convention used throughout both manuals (and this reference): each command has a "general form" in which fixed words are boldface capitals and programmer-supplied items lower-case; "except for imbedded periods within italicized words, any punctuation shown in the general form of a command is a fixed and necessary part of the command" ([F p. 38]). The concise collected forms are in F Appendix 2. In J, `[ ]` denotes an option, `{ }` a choice, upper case must appear as shown, lower case is generic, and "The order in which options are exercised on the various cards is not critical unless otherwise specified" ([J 01.01.01]).

### 2.8 How procedures connect to the data and environment descriptions

- **Names**: every data-name and condition-name used in a procedure statement must have a Data Description entry ([F p. 16]; [J 02.05.01]). Procedure-names, by contrast, are defined by their position in the procedure description itself ([F p. 16]).
- **Condition-names** are defined in the Data Description (type code COND) as named values of a conditional variable; they are usable both in conditional expressions and as the object of SET ([F pp. 21–22], p. 46; see §3). The Environment COND card separately defines console-entry-key settings testable as condition-names in procedure statements — "Note that Data Description condition.names are tested differently, i.e., for absolute equivalence to the specified value" ([J 02.06.17]).
- **Files and records**: files exist only via Environment FILE cards; "All records associated with the file must be named on the FILE card" ([J 02.06.05]), and each record so named must be a RECORD-type Data Description entry (diagnostics 8,00–17,00, [J 90.04.01]). OPEN/GET/FILE/CLOSE reference these names ([F pp. 39–41]).
- **Environment → procedure references**: the FILE card options `ON ERROR statement.name.1` and `FOR LABEL statement.name.2` name procedure statements to receive control on unrecoverable input errors and on open/close/reel-switch label processing respectively ([J 02.06.04]–02.06.05); enforcement via messages 92,00 and 93,00 ([J 90.04.01]). GET's AT END likewise requires a statement or section name where a transfer is implied (message 106,00, [J 90.04.01]).
- **One-word-name rule**: qualified names are banned in the Environment Description and CRYPT; use CALL to create one-word synonyms ([J 02.03.03], [J 90.01.01]).
- **Reserved words**: the F reserved-word list is F Appendix 2; J refines it into three classes — words never usable as programmer names in any division; words unusable as Data or Procedure names; and words usable as Procedure/Data names only if never referenced in the Environment Division ([J 02.03.02]–02.03.03; full lists in the elements section of this reference). "it is strongly recommended that the entire group be avoided altogether" ([J 02.03.02]).

### 2.9 Program size and structural limits (7090 implementation)

Internal table size limitations, "Appox-Max Size" ([J 90.01.05], reproduced in full):

| Item | Approx. max |
|---|---:|
| Internal dictionary including all program names whether defined by the programmer or generated by the Compiler | 3500 |
| Number of SECTIONS | 35 |
| Number of different edited field formats | 35 |
| Number of base locators (for the field test version this is the number of located records) | 127 |
| Number of QUANTITY IN specifications | 25 |
| Depth of nested sections | 18 |
| Number of index expressions (a * VARIABLE ± b) | 50 |
| Number of positional indicators (each unique combination of array and subscript notation, e.g., A(I), A(I + 1) B(I) requires 3 positional indicators) | 90 |
| Number of array dimensions (explicit or implicit Quantity specifications) | 85 |
| Number of levels in a data hierarchy | 23 |
| Number of generated constants in the constant pool -CP)+NN | 500 |

Other structural limits and constraints:

- "A maximum of 63 files may be described" ([J 90.01.04]).
- One core load: no OVERLAP segmentation ([J 90.01.05]; §2.6).
- deck.name: six or fewer characters, no imbedded blanks ([J 02.01.01], 90.01.05).
- Names (data-, procedure-, condition-): 1–30 characters ([F p. 15], p. 37); pictorials limited to 30 characters ([J 90.04.01], message 100,00); literals 50 characters, complete on one line ([F p. 18]; [J 90.04.01] message 150,00); alphabetic constants exceeding internal table capacity must be subdivided (message 148,00).
- A single sentence has a bounded (unquantified) internal size: `177,00 THIS SENTENCE EXCEEDS INTERNAL TABLE CAPACITY. SENTENCE DELETED FROM TEXT.` ([J 90.04.01]). DISPLAY sentences are checked against an internal form of 255 words of storage (printing then splits across physical records; [J 02.04.02.01]).
- Severity codes 1–5 attach to every diagnostic; severity 5 suppresses the object deck, severity >1 suppresses immediate execution under the LOAD option ([J 02.01.01]–02.01.02; the full message/severity list is J Appendix 90.04 — see the diagnostics section of this reference).

### 2.10 Ambiguities affecting this section (summary)

Recorded in detail in the ambiguity register accompanying this reference: (1) the undefined PROGRAM.START entry-point mechanism; (2) division ordering/interleaving under the J compiler; (3) treatment of cards preceding the first division header; (4) the F-vs-J sequence-checking contradiction; (5) GO TO out of a DO-addressed section (used by IBM's own sample program despite the closed-subroutine rule); (6) parameter/function declaration after removal of PARAM/FUNCT; (7) survival of the `STOP n` form alongside J's mandatory STOP RUN; (8) section-scoped name uniqueness.

---

## 3. Data description and storage model

This section defines the Data Description division of a COMTRAN source program: the file/record/field hierarchy, the fixed-column data description card, every type code, the pictorial (format-character) repertoire, constants, modes, justification and word-boundary rules, tables and subscript declaration, and every stated numeric limit. F28-8043 chapter 4 is the 1960 language description; J28-6169 section 02.05 (with 02.03 and 90.01) is authoritative for the implemented 709/7090 language. Divergences are flagged throughout and summarized in §3.11.

### 3.1 Files, records, and fields — the data hierarchy

The manuals define the three units of data by the verbs that may operate on them ([F p. 63]):

| Unit | Defined by | Description |
|---|---|---|
| **File** | Operable only by OPEN and CLOSE | "a body of data stored in some external medium which can be made accessible to the system by the use of the verb OPEN" ([F p. 63]). A file is never itself brought into storage ([F p. 64]). There may be more than one file on a tape, and a file may extend over a number of tapes ([F p. 63]). |
| **Record** | Operable by GET and FILE | "a portion of a file which can be made accessible to the system by the verb GET, assuming the file has previously been 'opened'" ([F p. 64]). Its size and position in storage are determined by the data description; a record is an "internal" body of data ([F p. 64]). |
| **Field** | Operable by arithmetic and data-movement commands (other than GET/FILE) | "a block of data which can be operated on as a unit by the arithmetic commands and by the commands that control the movement of data within the system" ([F p. 64]). A record may contain only one field; parts of several records may be regrouped in storage to form a new field. "Fields must always be defined in the data description." ([F p. 64]) |

- Distinctions among "subfields," "fields," and "groups of fields" are not made by separate terms; they are handled entirely by **level numbers** ([F p. 64]). See §3.2, Level.
- Files may contain **label** records at beginning and end; most labeling is handled by the input-output package and the environment description, but the programmer may prescribe label details with the LABEL type code ([F p. 63–64]; see §3.3 LABEL).
- J tightens the record definition: "A record is a data hierarchy which may not be part of any data organization except a file or a section." ([J 02.05.01])
- **Declaration is mandatory:** "The name of each data field referenced in Procedure statements or Environment Descriptions must appear in the name field of a Data Description entry. Neither storage allocation nor assignment of data characteristics is made for data fields not so named." ([J 02.05.01])
- Files and groups of files are **not** entered as such in a data description — the hierarchy of data description entries begins at the record level ([F p. 69], Figure 2 footnote). Records are tied to files in the Environment Description (see the Environment description section; also [F p. 71]: "Each record named in the data description must also be named in the environment description").

### 3.2 The *DATA division and the data description card

A "division header" must be placed immediately before the first entry of each consecutive group of data description cards: "The name `*DATA`, placed so that the asterisk is in Column 7, should be the only entry on the line (i.e., card), except for the serial number and identification entries in Columns 1-6 and 73-80." ([F p. 65]) The `*DATA` header appears as such in the 7090 compiler's symbolic listings ([J 90.02.02], 90.05).

One card is used per kind of data item. The card format is fixed-column — unlike the procedure description, it "does not allow 'free form' description" ([F p. 65]). Column layout ([F p. 65]):

| Columns | Width | Use |
|---|---|---|
| 1–6 | 6 | Card Serial Number |
| 7–22 | 16 | Name |
| 23–24 | 2 | Level Indication |
| 25–30 | 6 | Type |
| 31–35 | 5 | Quantity |
| 36 | 1 | Mode |
| 37 | 1 | Justification |
| 38–71 | 34 | Description |
| 72 | 1 | Continuation Indication |
| 73–80 | 8 | Identification |

#### Ctl. and Serial (Col. 1–6)

- Sequence matters: "the sequence controls the internal position of the data" ([F p. 65]). The serial number is normally numeric; the first three digits ("CTL") are common to a page, Columns 4–6 carry the rest. Normally only Columns 4–5 are used initially, leaving Column 6 blank so that correction cards can be collated in later — the blank is first in the collating sequence, so `23_` < `235` < `24_` ([F p. 65–67]).
- F states serial numbers "will be checked for correctness of sequence" when read in; the numeric collating sequence in all IBM machines is blank first, then 0–9 ([F p. 67]).
- **F/J divergence:** the 7090 compiler does *not* check: "Card serial numbers in columns 1-6 of source decks are not sequence checked by the compiler." ([J 02.03.01])

#### Data Name (Col. 7–22)

- Any name assigned to the data described; names may contain up to 30 characters (rules for forming names, [F p. 15] — see §2, Language structure). Since only 16 columns are available, longer names continue in the Data Name columns of the next card, flagged by any non-blank character in Column 72; the processor closes up any blanks in the Data Name columns, so the carryover may be indented ([F p. 67]). J states the same: "All imbedded and leading blanks in the name fields of cards associated with an entry are eliminated and the non-blank characters are compressed to form a single name." ([J 02.03.01])
- Names are written with an assumed left margin immediately to the left of Column 7; indentation is permitted for visual level-structure display and is ignored by the processor ([F p. 67–68]).
- If no name is assigned, Columns 7–22 are left blank ([F p. 67]). Names may be given to any item of data or to any group of items stored consecutively; any such name may be used as an operand in a procedure statement ([F p. 67]).
- **No overlapping named groups:** "Data-names must not overlap. ... the same field may not be included as a part of each of two overlapping named groups of fields." E.g., with successive fields A, B, C: if X names the pair A and B, then Y may not name the pair B and C. To refer to B and C together, the group must be redefined via REDEF; redefinition does not delete the original names ([F p. 67]).
- Name qualification (compound names) resolves non-unique names via higher-level names, e.g. EASTERN REGION SALES FORCE PAY RECORD ([F p. 70–71]); see §2. Qualified names may not be used in the Environment Description or in CRYPT instructions ([J 02.03.03]; [J 90.01.04]).

#### Level (Col. 23–24)

- "Any number from 1 to 99 can be used. All data description entries must be assigned level numbers." ([F p. 68]) J: "Any numbers 01-99 may be used to specify the level of fields. Leading zeros are optional and all level numbers less than 10 are right justified by the compiler." ([J 02.05.01])
- Hierarchy rule: "each item is considered to be a subdivision of the last item preceding it which has a lower number" ([F p. 68]). Data is organized "vertically" — no item is related directly to another at the same level except through a higher-level item ([F p. 68]).
- Level numbers need not be consecutive; any number greater than that of the next higher classification serves, and skipping numbers is recommended to allow later insertions ([F p. 68]).
- The highest level (i.e., the numerically smallest level number) in a program need not be 01 ([J 02.05.01]). All data fields at the level equal to the highest level in a source program are **left justified** unless explicitly specified as right justified — even if no justification is specified and previous fields do not complete full words ([J 02.05.01], with worked example at level 05).
- Level numbers describe structure only; "Level numbers are not actually attached to the data" ([F p. 71]).
- Limit: number of levels in a data hierarchy — approximately **23** maximum ([J 90.01.05]).

#### Type (Col. 25–30)

If blank, the entry describes an ordinary data field or group of fields ([F p. 71]). Type codes:

| Type code | F28-8043 (1960) | J28-6169 (1962 implementation) |
|---|---|---|
| RECORD | yes ([F p. 71]) | yes ([J 02.05.01]) |
| COND | yes ([F p. 71–72]) | yes ([J 02.05.02]) |
| FUNCT | yes ([F p. 73]) | **"no longer in the language"** ([J 02.05.03]) |
| PARAM | yes ([F p. 73]) | **"no longer in the language"** ([J 02.05.03]) |
| REDEF | yes ([F p. 73–76]) | yes, with restrictions ([J 02.05.02], 90.01.03) |
| COPY | yes ([F p. 76–77]) | **"Implementation of COPY has been deferred."** ([J 90.01.03]) |
| LABEL | yes ([F p. 77]) | yes, 14-word IOCS label area ([J 02.05.03]) |
| RCDMRK | — (not in F) | **new in J** ([J 02.05.03]) |

Full semantics of each code: §3.3.

#### Quantity (Col. 31–35)

- Specifies "the total number of times the data description is required," for consecutive items of identical description; "This number must refer to data items occurring in sequence." ([F p. 77])
- Default: columns usually blank; "In that case, it will be assumed that they contain a value of 1" ([F p. 77]; [J 02.05.04]: "If no value is specified, 1 is assumed").
- Maximum: "The maximum Quantity which may be specified is 2¹⁵ - 1." ([J 02.05.04]) [= 32767]
- "No check against this value is made at execute time." ([J 02.05.04])
- "quantity numbers should not be assigned to data items not having names, unless these items include named items at a lower level" ([F p. 77]; repeated verbatim [J 02.05.04]).
- Nesting (F): "Quantity numbers may be specified for as many as three levels in a single 'nested' group" — e.g. STATE quantity 5, DISTRICT 4, CITY 7 reserves 5 STATE, 20 DISTRICT, 140 CITY items ([F p. 77]). **J is silent on a three-level cap** (see ambiguity note, §3.11); its program-wide limit is ~85 array dimensions ([J 90.01.05]).
- A quantity entry applies its multiplication to the entry *and its subordinate fields* (the RATE example, [F p. 75]: 30 in Quantity opposite RATE lays out RATE with its four subfields 30 times).
- Quantity may **not** be used at the record level: "The 'Quantity columns' ... use of these columns with a data hierarchy, such as RECORD, is unacceptable." ([J 02.05.01]) Hence "record.names may not be subscripted" ([J 90.01.03]).
- Storage effect: "An entry in this field is used by the compiler to reserve storage for sequential data of the same format." ([J 02.05.04])

#### Mode (Col. 36)

- `I` = internal mode, `E` = external mode ([F p. 78]). J gives the 7090 meanings: "Internal mode (I) designates that the associated numeric field is to contain data in binary form. External mode (E) designates that the stored form is BCD." ([J 02.05.04])
- Mode is specified at the *lowest* level of data organization — the level where the field pictorial is shown; the mode of a larger unit is a consequence of the modes of its components ([F p. 78]).
- Storage-model consequence: "Arithmetic operations are performed only in the internal (binary) mode." ([J 02.03.03]) External-mode fields are unpacked and converted every time they enter arithmetic ([J 02.03.03]; see §3.6).

#### Justify (Col. 37)

- `L` = left justified, `R` = right justified, blank = packed ([F p. 78–79]).
- Justification for an *input* item describes the item as it already exists (tells the system where to look); for other items it controls placement ([F p. 78]).
- Left justification: left-hand character goes in the left-hand position of the next available machine word, possibly leaving the right portion of the preceding word unoccupied. Right justification: item stored to the right in the next available machine word. No justification: data is packed, "there will be no blank spaces between successive items" ([F p. 78–79]).
- Alignment of alphameric information cannot be specified in the field pictorial; it is done with the Justify column ([F p. 79]).
- J word-boundary rules and the restriction "Specification of right justification is effective only for data items with explicitly described formats. Left justification is always effective." ([J 02.05.04]) — full detail in §3.6.

#### Description (Col. 38–71)

Five kinds of information may appear, and when several are needed on one line they are written **in this order**, separated by one or more blanks ([F p. 79]):

1. Format characters (the "field pictorial").
2. Constants.
3. Data names associated with the type codes REDEF and COPY.
4. The word LIBRARY, followed by the name of a data description stored in the library.
5. The words QUANTITY IN, followed by the name of a field which will contain a quantity at object time.

J adds a sixth kind of Description-field content not in F: the **BLANK WHEN ZERO** clause ([J 02.05.07]; see §3.4). Full detail on all of these: §3.4.

#### Cont. (Col. 72)

- Any non-blank character in Column 72 marks the next card as a consecutive part of the entry. A continued name continues in the Data Name columns; an overflowing description continues in the Description columns ([F p. 84]).
- Description continuation: the break must occur between words, "since the processor will assume a blank at the end of each line. Multiple blanks, however, are treated as single blanks." ([F p. 83], General Note)
- Constants carried over to a new line: "the portion on each line must be treated as a complete constant (i.e., enclosed in quotation marks); the continuation indication is not used in this case, and no blanks will be assumed between successive lines" ([F p. 83]). **J deviation:** the 7090 processor happens to handle Data Description literals continued in violation of this rule correctly, but "Use of this characteristic of the 7090 processor should not be made if compatibility with other processors is desired." ([J 02.03.01])
- J restrictions: "The name and description fields only of Data Description entries may be continued. All other specifications to be made for an entry must be made on the first card of that entry since these fields are not scanned on continuation cards." ([J 02.03.01]) The processor "replaces the contents of column 72 with a blank in Data and Environment lines"; each word or literal must be complete upon a line ([J 02.03.01]).
- Entry termination: "Data and Environment entries are considered complete when column 72 is blank. The period (.) must not be used to signal completion. In these sections, a period is considered part of the previous word, thus creating an undefined name." ([J 02.03.02])

#### Identification (Col. 73–80)

Optional program-identification code; any characters from the basic character set; "the characters in these columns have no effect on either the processor or the object program" ([F p. 84]).

### 3.3 Type codes in detail

#### RECORD

- Marks the data as a record, "accessible by GET and FILE instructions"; each record so named must also be named in the environment description ([F p. 71]).
- J amplifications ([J 02.05.01]):
  - A record is a data hierarchy that may not be part of any data organization except a file or a section.
  - Quantity columns may not be used on a RECORD entry.
  - "When the type code RECORD is recognized the previous data organization is always terminated. Record definition is terminated by specification of a level number equal to or less than the one associated with RECORD."
  - "A record must have length, and redefinition of a record area does not give it length." The compiler considers no length specified for REC1 in:

    ```
    Name    Level    Type      Description
    REC1    01       RECORD
                      REDEF     REC1
    AREA    01                  A(40)
    ```
    ([J 02.05.01])
  - "The length of a record is normally determined on the basis of fields defined within it. Length may also be given to a record through use of a pictorial with the RECORD entry itself." ([J 02.05.02])
- Restrictions ([J 90.01.03]): "A name associated with the RECORD type code must be unique. If the record is defined within a section the section.name may not be used as a qualifier of the record.name." "Since a quantity specification may not be made at the record level, record.names may not be subscripted."
- Records are fixed length unless a QUANTITY IN option appears within them (then variable length — [J 02.07.03]; see §3.8 and the Input/Output section).

#### COND

- Declares that the entry names one of the possible **conditions** (values) a **conditional variable** (a field) may assume ([F p. 71–72]). The condition-name is "the name of the value which can be placed in a field; it is not the name of the field itself" ([F p. 72]).
- Binding: condition-name entries are given a lower level (higher number) than the conditional variable's field entry and immediately follow it in the data description; the actual value is written in the Description columns as a constant in quotation marks ([F p. 72]). Worked example ([F p. 72]):

  ```
  SERIAL  DATA NAME                    LEVEL  TYPE     QUANTITY  MODE JUST  DESCRIPTION
          MARITAL.STATUS               0  6                                 A
          SINGLE                       0  7  COND                           'S'
          MARRIED                      0  7  COND                           'M'
          DIVORCED                     0  7  COND                           'D'
  ```
- Semantics: MARRIED ≡ MARITAL.STATUS = 'M'; SET MARRIED and IF MARRIED are interpreted as SET MARITAL.STATUS='M' and IF MARITAL.STATUS='M' ([F p. 72]). See §2 (condition-names) and the procedure section (SET, IF).
- COND entries are optional — a programmer who writes only full-form conditional expressions (IF MARITAL.STATUS = 'M' ...) need not declare condition-names ([F p. 72]).
- J rules: "Normally this type code is associated with several entries naming and describing the values a particular field may have. These entries must be preceded by a higher level entry defining the format of the fields and must all have the same level number and include the COND type code." ([J 02.05.02])
- Restrictions: "Neither a data item (literal) nor a condition.name may be subscripted. However, a conditional variable may be subscripted." ([J 90.01.03])
- There is also a COND *Environment* card ([J 02.06.17]) — separate mechanism; see the Environment description section.

#### REDEF

- Purpose: redefine an area or item previously defined — for time-shared use of storage, renaming, regrouping with new level structures, and setting up tables ([F p. 73]). "Use of the REDEF code does not erase data in storage, unless an attempt is made to place two or more different constants in the same area; however, it does superimpose a new format upon the data already present." ([F p. 73]) "Redefinition does not cancel the previous definition. ... Once an area has been defined, all names associated with the definition may be used at any time, regardless of subsequent redefinitions." ([F p. 73])
- F card usage: the REDEF entry carries the type code REDEF, has "the same level number as the entry being redefined," and the name of the area being redefined is written in the Description columns (F p. 73, 81). In F's example the REDEF line itself is unnamed "but the programmer could assign one if he wished" ([F p. 75]).
- **F/J divergence on the REDEF card:** J requires the REDEF line to be bare: "When the REDEF type code is used, it should appear on a line with no additional coding except a serial number and the name of the item being redefined. The first item appearing thereafter must have the same level number as the item referenced by the REDEF." ([J 02.05.02]) Under J the redefinition's structure begins with the *following* entries; F's optional name-on-the-REDEF-line does not fit J's rule (see ambiguities).
- J storage-assignment semantics: "When a REDEF is first encountered, the contents of the storage assignment counter are saved by the compiler, and assignment proceeds according the REDEF. The effect of a REDEF is terminated upon encountering an item of a level above or equal to the level of the item referenced by the REDEF or upon encountering another REDEF. Termination of the former type causes the storage assignment counter to be restored and assignment proceeds in the normal manner." ([J 02.05.02])
- Name qualification ignores REDEFs: "Compound names are formed without regard to REDEFs (or other type codes) and as a function of the level and position within the program of the simple names only." ([J 02.05.02], with two worked examples in which the completely qualified name of H is A G H.)
- Restrictions:
  - "An area involved in a REDEF must not contain subscript variables or a QUANTITY.IN value." ([J 90.01.03])
  - "Whenever an input record containing an array is involved in a REDEF, the record containing the array should precede the REDEF in order to get optimum results." ([J 90.01.03])
  - Constants "cannot be defined ... as part or all of the redefinition of an area." ([J 02.05.06]) (Plausible resolution, not stated by J: the F table technique — constants first, REDEF second — appears unaffected, since the constants belong to the original definition rather than the redefinition. See §3.7 and §8.5.)
  - Redefinition of a record area does not give the record length ([J 02.05.01]).
  - I/O interaction: if a record is REDEF'd to share an area with data other than records of the same file, all records of the file are automatically 'transmitted' (with a message if they were to be located); all records related through REDEF are made available when any one is requested by GET ([J 02.07.05]). Records from different files REDEF'd together are not automatically transmitted by the field test processor — SPANS or HOLD must be used ([J 90.01.01]). See the Input/Output section.

#### COPY and library data descriptions

- F semantics: COPY copies a data description previously defined in the program under a new name and, optionally, a new level. New name in Data Name columns, COPY in Type, original name in Description; "This description must already have been read into the system for the COPY code to be able to operate on it." ([F p. 76]) The copy replaces the original name with the new name, and if a new level number is given, all subordinate level numbers are adjusted to retain their original relationship — original 01, 03, 04 copied at level 05 becomes 05, 07, 08 ([F p. 76], with the PAY.RCD.MASTER → PAY.RCD.DETAIL worked example on [F p. 76–77]).
- Library form: "The word LIBRARY, followed by the name of a data description stored in the library, designates a data description which is to be copied. ... When a library data description is prescribed, the type code COPY must be used." ([F p. 81]) Library conventions: see §7.
- **F/J divergence — both deferred in J:** "Implementation of COPY has been deferred." ([J 90.01.03]) "Mechanization of the INCLUDE verb has been deferred, and consequently no library facilities are currently available." ([J 90.01.02])

#### LABEL

- F: "The type code LABEL identifies a data description as that of a label record. This will cause a redefinition of the label area in the input-output control system." Details deferred to processor publications ([F p. 77]).
- J implementation: LABEL "allows the programmer to redefine with the indicated data description entries, the single 14 word label area in the Input/Output Control System from which all labels for output files are written and into which all input labels are read." The area may only be processed via the FOR LABEL option on Environment FILE cards, which transfers control to the specified procedure.name at open, close, or reel switch (implementation in Appendix 90.07). Labels processed this way are limited to **14 words**, and portions of the FOR LABEL coding must be done in CRYPT; the manual notes the alternative of "defining labels as records and processing with the GET and FILE verbs." ([J 02.05.03])

#### RCDMRK (J only)

"The RCDMRK type code causes insertion of a single character record mark constant in the indicated position. No description field specification is required since the compiler automatically provides a pictorial with a single A. Information may be freely moved into or out of this position subject only to the restriction imposed by its single character alphameric format." ([J 02.05.03]) Not present in F.

#### PARAM and FUNCT (F only — removed)

- F: FUNCT identifies a function-name — a data-name specified in the GIVING clause of a BEGIN SECTION command — which "must be fully described in accordance with the provisions of this chapter" ([F p. 73]). PARAM identifies a parameter — each data-name listed in the USING clause of a BEGIN SECTION command ([F p. 73]). See F's functions discussion ([F p. 32]) and the procedure section.
- **F/J divergence:** "These two type codes described in the General Information Manual are no longer in the language." ([J 02.05.03])

### 3.4 The Description field in detail

#### Format characters (the field pictorial)

Format characters serve two functions: they show the number of character spaces a field occupies, and the kind of character occupying each space; the result is a "field pictorial" ([F p. 79]). For data brought in at object time, the pictorial must reflect the data as it already exists — "changes in input data cannot be effected by the field pictorial"; for data produced by the program, the pictorial directly controls how the data is handled ([F p. 79]). With the stated exceptions (V, S, F, overpunched signs, (n)), one format character is required per data character of reserved storage ([F p. 79]).

The complete repertoire ([F p. 80]):

| Character | Meaning and use (condensed from [F p. 80]) |
|---|---|
| `A` | "Any non-numeric character, including the blank." |
| `X` | "Alphameric character (any character in the machine's character set)." (A and X "are considered to be synonymous by the 7090 CT Compiler" — [J 02.05.04].) |
| `9` | "Any numeric character." |
| `8` | "Numeric character, to be replaced automatically by a blank whenever it is a non-significant zero." |
| `*` | "Numeric character, to be replaced automatically by an asterisk whenever it is a non-significant zero." |
| `V` | "Assumed decimal point. ... The symbol is not required for integers. The symbol V will not reserve an actual space in storage." |
| `.` | "True decimal point. This character will reserve an actual space in storage." |
| `S` | "Scale factor. ... used as a 'filler' or 'spacer' when the input data does not show the position of the decimal point. E.g., a field containing percentages from 1 to 9 would be represented by the notation `VS9`; this would assure that the values 1 to 9 would be interpreted as .01 to .09. Similarly, if a field contains values that represent thousands, each unspecified digit must be represented by an S; thus, the notation `999SSS` would provide for values from 000,000 to 999,000, even though the three right-hand zeros would not appear as input." |
| `$` | "Dollar sign. An actual dollar sign will be placed in the indicated position, provided it is not followed by the symbol 8. In the latter case, the dollar sign will 'float' — i.e., it will be placed immediately to the left of the first significant digit remaining." |
| `,` | "True comma. This symbol will reserve an actual space in storage, to be occupied by the comma. The comma itself may be replaced by a blank, asterisk, or dollar sign, if the operation of a preceding 8 or * has resulted in the elimination of non-significant zeros to the left." |
| `+` | "Plus or minus sign, one of which will always be placed in the space reserved for it, depending on whether the value is positive or negative. ... This sign may be placed in a column by itself, in which case it will reserve an actual space in storage. Alternatively, it may be entered as an 'overpunch' with either of the format characters 8 or 9, in either the units or high-order position of a field; in this case, a special space will not be reserved, and the sign of the field will be indicated in accordance with the operating characteristics of the particular system." |
| `-` | "Minus sign, to be placed in the space reserved for it when the value is negative; when the value is positive, the space will be left blank. If punched in a space by itself, this symbol will reserve a space in memory; otherwise, it may be 'overpunched' and will act as described in the rules for the symbol +." |
| `F` | "Floating point number. This symbol does not reserve an actual space in storage; it informs the processor that the number being described is a floating point number. It is placed between the format characters representing the fraction and those representing the exponent. E.g., `+99V9F+99`." |
| `(n)` | "A number placed in parentheses immediately following one of the other format characters instructs the processor to allow for that number of the character specified. E.g., `9(4)A(12)` is equivalent to `9999AAAAAAAAAAAA`." |

Worked examples of pictorial ranges ([F p. 81]):

| Notation | Range of Characters Provided For |
|---|---|
| `AAA` | All characters in the machine's character set except numerals. |
| `88999` | All numeric values from 000 to 99999. |
| `****.99` | All numeric values from \*\*\*\*.00 to 9999.99. |
| `$888,888.99` | All numeric values from $.00 to $999,999.99. |

#### Field types on the 7090 (J chart)

The implemented compiler classifies every field into one of six types (chart, [J 02.05.05]; overpunched digits shown with combining overline per the conversions):

| Type of Field | Characterized By | Legitimate Format Characters in Description | Legitimate Information in Field |
|---|---|---|---|
| Alphameric | A or X in format field | A X (n) | all characters |
| External Decimal (1)(3) | E in Mode Column | 9 (n) S V 9̅ or 9̅ in rightmost character (two distinct overpunched-9 glyphs in the scan — minus- and plus-overpunch — both rendered 9̅; see §8.5.8) | digits and leading blanks; an overpunch with the rightmost digit |
| Internal Decimal | I in Mode Column | 9 (n) V S | binary |
| Edited Field (2) | 8 * . , $ + - in format field or BLANK WHEN ZERO clause | 9 8 * . , $ + - S V (n); 8 or 9 or 8̅ or 9̅ in rightmost character | digits and leading blanks; an overpunch with the rightmost digit |
| Floating Point | I in Mode Column and F or FF in format field | F is single precision; FF if double precision | floating binary |
| Scientific Decimal (4) | E in Mode Column and F in format field | 9 (n) F . V + - | digits . + - |

Chart notes ([J 02.05.05]):

1. "The only sign specification which may be used for an external decimal field is an overpunched + or - in the rightmost position of the field. A + and - may not appear in the character by itself."
2. "An edited field may have a character position reserved for the sign or may have the sign over the rightmost digit."
3. "Numeric external fields may contain leading blanks which are treated as leading zeros."
4. "Scientific decimal is the edited form of the floating point. The maximum fractional portion of a scientific decimal field is 16 digits."

#### Rules and restrictions on pictorials (J)

- **Group fields ("non-format" fields):** "A field for which no pictorial is given is treated as alphameric with length equal to the length of its subfields." ([J 02.05.06]) Conversely, "No subfields may be specified for the field whose format is described. The only entry which may legitimately appear at a lower level is a COND definition." ([J 02.05.06]) In J's example, A (subfields B, C: internal `99` each) and D (subfields E, F: `A(6)` each) are each treated as alphameric fields of length 12 ([J 02.05.06]). Such fields without pictorials are the "non-format fields" of [J 02.04.07], which "are compared alphamerically" ([J 02.04.07]; see procedure section).
- **Mixed pictorials illegal:** "A field may not be described as a mixed numeric and alphameric field, i.e., both A's and 9's in a pictorial. If this specification is made the field is treated as alphameric." ([J 90.01.03])
- **Non-format characters:** "Any non-format character appearing in the pictorial will result in the pictorial being interpreted as a name. An error message will be produced if the pictorial is not a data, key, or a procedure name." ([J 02.05.06]) (This is how REDEF/COPY target names and QUANTITY IN clauses coexist with pictorials in the same columns.)
- **Precision:** "Fixed point double precision numbers are denoted in the Data Description by formats representing more than 10 digits. Double precision internal floating point numbers are specified by 'FF' in the Data Description." ([J 02.05.06])
- Edited fields are converted to pure numeric fields for comparison; they may not be compared to alphameric fields ([J 02.04.07]). Comparisons between numeric and alphameric fields are invalid ([J 02.04.06]). See procedure section.

#### Constants in data descriptions

- A constant is "a value, or a group of symbols, placed in the program for use without alteration" ([F p. 81]). It is declared by writing a field pictorial followed, after at least one blank, by the actual value **enclosed in quotation marks** on the same line ([F p. 81]). Example ([F p. 81]):

  ```
  SERIAL   DATA NAME              LEVEL  TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION
           PERCENT.CONST                                                            V99 '05'
  ```
- Constants vs. literals ([F p. 81]): literals are written in procedure statements, constants in data description entries; "Constants, unlike literals, must always be enclosed in quotation marks, even though they may be wholly numeric."
- Constants "may contain any character" — the punctuation/spacing rules do not apply inside them ([F p. 28]). (The 1960s literal-delimiting quote is rendered as `'` in the conversions.)
- Decimal points are not normally required in table constants; the decimal location is specified by the later pictorial ([F p. 74]).
- Continuation: each line's portion must be a complete quoted constant; no continuation punch; no blanks assumed between successive lines ([F p. 83]; see §3.2 Cont.).
- J restrictions — "Constants cannot be defined.
  i in a field whose pictorial characterizes it as an edited field.
  ii as a part of a located input area. (see section 02.07).
  iii following a variable length field.
  iv as part or all of the redefinition of an area." (J 02.05.06)
- J sizing rules:
  - Alphameric constants: "No format specification is required in the definition of alphameric constants. The length of the literal is assumed as the length of the field." If a pictorial is furnished and its length is greater than the constant, the constant is left-justified and blank-filled; if less, characters are placed from the left until the field is full, the remainder discarded, and an error message produced ([J 02.05.06]).
  - External decimal constants: "the length specified by the pictorial must be exactly equal to the length of the constant. Also, the constant must utilize the sign convention given in the pictorial e.g., If the pictorial is 999̅, the number 123̅ would be correct whereas 123 would not be correct" ([J 02.05.07]).
  - Internal decimal constants: pictorial length may be larger than the constant (constant right-justified); if the constant is larger it is truncated at the left end to the pictorial's size, converted, stored, and an error message produced. "The appropriate sign conventions for internal decimal constants are: i leading + or - ; ii trailing + or - ; iii no sign" ([J 02.05.07]).

#### QUANTITY IN data.name

- F mechanics ([F p. 82–83]): an "advanced" facility to regroup an already-reserved area at object time. A quantity value is placed in a named field, and the entry refers to it by "QUANTITY IN" plus the field's name in the Description columns. Values found in the named fields at object time **override** any values in the Quantity columns. Storage is reserved by the compiler from the ordinary Quantity value (in F's example, 100 items of `999V99` = 500 character spaces, reusable as a 10×10, 20×5, or 4×25 table by storing new values in COLUMN.QTY / ITEM.QTY) ([F p. 82–83]). Worked entries ([F p. 83]):

  ```
  SERIAL   DATA NAME              LEVEL  TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION
           TABLE                    01
           COLUMN                   02                                              QUANTITY IN COLUMN.QTY
           ITEM                     03               100                            QUANTITY IN ITEM.QTY
  ```
- J: "Use of this option indicates that the associated entry(s) is to be repeated a variable number of times as determined at execute time by the value in the indicated 'data.name'. The compiler reserves sufficient storage for the maximum number of times the field may be present on the basis of the value entered in the Quantity Field." ([J 02.05.07])
- Consequences in the implemented language:
  - A field using QUANTITY IN is a **variable length field**; variable length fields may not be compared ([J 02.04.07]).
  - A record containing any QUANTITY IN field is a **variable length record** ([J 02.07.03]; see §3.8).
  - "Fields may not be defined following a variable length array as part of the same data hierarchy." ([J 90.01.04])
  - Constants may not be defined following a variable length field ([J 02.05.06]).
  - An area involved in a REDEF must not contain a QUANTITY.IN value ([J 90.01.03]).
  - Figurative constants may not be moved to variable length arrays (they may be moved to fixed length arrays or to array elements) ([J 90.01.02]; [J 02.04.01], ARRAY/FIELD example: MOVE BLANKS TO ARRAY illegal, MOVE BLANKS TO FIELD(3) proper).
  - Limit: number of QUANTITY IN specifications ≈ **25** ([J 90.01.05]).
  - The dimensions of an array must be set before subscript values for the array are calculated; failure "causes invalid object code" ([J 90.01.02]; see §3.7).

#### BLANK WHEN ZERO (J only)

"When associated with an output field this clause indicates that the field is to be replaced with blanks when it becomes zero. Since leading blanks in numeric input fields are automatically treated as zeros, the use of this clause is redundant [for input]. In some cases it may even result in decreased efficiency in the object program as these fields are treated as edited types." ([J 02.05.07]) The clause by itself characterizes a field as an edited field ([J 02.05.05] chart). Not present in F. Neither manual shows its exact written form or position on the card (see ambiguities).

### 3.5 Signed-number representation and overpunch

- F: `+` and `-` may reserve an actual character position, or may be entered as an overpunch with format character 8 or 9, "in either the units or high-order position of a field," in which case no space is reserved ([F p. 80]).
- **F/J divergence:** on the 7090, "The only sign specification which may be used for an external decimal field is an overpunched + or - in the rightmost position of the field. A + and - may not appear in the character by itself." ([J 02.05.05] note 1) An edited field may have either a reserved sign position or the sign over the rightmost digit ([J 02.05.05] note 2). The conversions render an overpunched digit with a combining overline: `9̅`, `8̅`, and constants such as `123̅` ([J 02.05.05], 02.05.07).
- Numeric external fields may contain leading blanks, which are treated as leading zeros ([J 02.05.05] note 3).
- Internal-mode sign: for a right-justified internal field, "the sign value in the sign bit of the word"; for left/no-justify internal fixed point fields, the sign occupies the "leftmost bit of the field" ([J 02.05.04]; see §3.6).
- Zero: "For comparison purposes zero is considered an unsigned number, even though computational sequences generated by the compiler may produce negative or positive zeros." ([J 02.04.07])

### 3.6 Mode, justification, and the machine storage model

The 709/7090 storage model, as stated by J:

- **Arithmetic is binary only:** "Arithmetic operations are performed only in the internal (binary) mode." ([J 02.03.03]) External (BCD) fields entering arithmetic are unpacked and converted each time; the manual's remedy is MOVE-ing them once to an internal-mode area ([J 02.03.03] — e.g., the `IR999` field X in the worked example, [J 02.03.03]/02.03.03.01; the `I` is scan-confirmed as the letter I, see §8.5.8).
- **Internal mode, right justified (R):** the numeric field "appears by itself in the low order positions of a full word (two if double precision) with the sign value in the sign bit of the word." ([J 02.05.04])
- **Internal mode, left justified (L) or unjustified (blank):** "The length of a numeric internal mode fixed point field designated as left justified or without justification specification is the least multiple of 6 bits sufficient to contain the number and its sign (leftmost bit of the field so designated)." ([J 02.05.04])
- **Left justification (any mode):** "reserves storage beginning with the leftmost bit of a new word and extending through as many words and bits as necessary." **No justification** "differs only in that storage reservation begins immediately to the right (within the same word if possible) of the preceding storage reservation" — i.e., packing ([J 02.05.04]; [F p. 79]).
- **External mode, right justified:** "storage is reserved beginning in a new word so that the field's last character is also the rightmost character of its final word." ([J 02.05.04])
- **Effectivity rule:** "Specification of right justification is effective only for data items with explicitly described formats. Left justification is always effective." ([J 02.05.04])
- **Default at top level:** all fields at the highest (numerically smallest) level used in the program are left justified unless explicitly right justified ([J 02.05.01]).
- **Precision:** fixed point double precision = pictorials of more than 10 digits; floating point double precision = `FF`; a double-precision right-justified internal field occupies two words ([J 02.05.06], 02.05.04). Mixed-mode expression evaluation rules (floating/double forcing) are procedure-side: [J 02.04.05.01]; see the procedure section.
- **Addressing granularity:** a positional indicator for an array element "contains the location (word and byte) of the particular element" ([J 02.04.07]) — storage is word-organized with character (6-bit) resolution within words. (Neither manual states the 36-bit word size explicitly in these sections; the 6-bit-multiple rule and "six (6) BCD characters" control word ([J 02.07.03]) imply six characters per word.)
- F's machine-independent framing: data is always identified by its position; the processor assigns each named item an initial location from the length and relative position given in the data description, and tracks all changes of position ([F p. 62]). Packing trade-offs (space vs. unpacking cost) are discussed at [F p. 78–79].

### 3.7 Lists, tables, and subscripts (declaration side)

#### Concept and layout

- A list or table is "an ordered grouping of data"; fixed data is usually entered as a series of constants, variable data arrives with input records or is produced by the program ([F p. 28]). A printed table is stored row by row as "one long 'string' of data"; two- or three-dimensional structure is preserved by level numbers ([F p. 29]). Every line must consist of exactly the same number of character spaces, with each item in corresponding position ([F p. 29]).
- Placement requires two steps: "(1) establishing the structure and format of the table, and (2) making provisions to enter the required data in that structure" ([F p. 28]).

#### The canonical F technique: constants + REDEF

Step 1 — enter the data as constants ([F p. 74]):

```
SERIAL   DATA NAME                      LEVEL   DESCRIPTION
         RATE.TABLE                      01
                                          02     'LOS ANGELES        15342 28516 21287'
                                          02     'MIAMI              07860 14163 11892'
```

Step 2 — superimpose structure by redefinition ([F p. 75]):

```
SERIAL   DATA NAME              LEVEL   TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION
                                  01     REDEF                                    RATE.TABLE
         RATE                     02                30
         CITY                     03                                             AAAAAAAAAAAAAA
         ONE.WAY                  03                                             999V99
         ROUND.TRIP               03                                             999V99
         EXCURSION                03                                             999V99
```

The 30 in Quantity opposite RATE reserves the RATE group (with its four subfields) 30 times; ONE.WAY (17) then obtains the one-way rate on the 17th line, and MOVE ONE.WAY (DESTINATION) TO BILL.AMOUNT uses the value found in the DESTINATION field at object time ([F p. 75–76]). Code values used as subscripts "must be assigned in a sequence corresponding to the lines of the table" ([F p. 76]). A city name can be bound to a line number by declaring, e.g., MIAMI as the name of the constant value '17' ([F p. 30]).

#### Subscript rules

- Subscripts are written in parentheses after the data-name; multiple subscripts in one pair of parentheses are separated by single commas ([F p. 28], rule 10; [F p. 30]).
- "as many as three subscripts may be used within the same pair of parentheses" ([F p. 30]); the number of subscripts used must correspond to the number of levels of the table required to obtain the item ([F p. 30–31]). PAGE (150) LINE (10) WORD (4) and PAGE LINE WORD (150, 10, 4) are equivalent; a unique name may be subscripted directly: WORD (150, 10, 4) ([F p. 30]). "Subscripts are always written in descending order of level." ([F p. 78]) Example: with quantities 5, 4, 7 on STATE/DISTRICT/CITY, CITY (3,2,6) obtains the sixth CITY of the second DISTRICT of the third STATE ([F p. 77–78]).
- General form of a subscript ([F p. 31]):

  ```
  a * VARIABLE ± b
  ```

  "in which the quantities a and b are literals and the name VARIABLE is the name of a field which may contain a variable quantity. This name may be a compound name, but, whether simple or compound, it must not have a subscript. Condition-names may not be used in subscripts. A name, literal, or arithmetic expression used as a subscript must represent a positive integral value." ([F p. 31]) A subscript may also be a single data-name or a literal (F p. 31, 75).
- Origin: "The initial value of an array is A(1) and not A(0)." ([J 02.04.07.01])
- "No object time check is made to insure that subscript references conform to the limits specified by the array dimensions in the Data Description." ([J 90.01.02])
- "The dimensions of an array must be set before calculation of subscript values associated with the array is performed. Presently, failure to observe this restriction causes invalid object code." ([J 90.01.02], with the SET I/SET J/SET Q example.) When an array follows a variable length array, subscripts must be set prior to a subscripted reference ([J 90.01.02]).
- Each unique subscripted name (A(J,K), A(J,K+1), A(2,3), ...) causes generation of one positional indicator, re-evaluated when its subscripts change value ([J 02.04.07]); details and CRYPT "Symbolic Registers" belong to the procedure/CRYPT sections.
- Restrictions: record.names may not be subscripted ([J 90.01.03]); a data item (literal) or condition.name may not be subscripted, a conditional variable may ([J 90.01.03]); the (old.name) in CALL may not be subscripted ([J 90.01.01], 02.04.05).
- Field-test caveat: "All input records containing arrays will be processed in the transmit mode by the field test processor." ([J 90.01.01])

### 3.8 Record length: fixed vs. variable (storage view)

Primary treatment in the Input/Output section; the data-description-relevant facts:

- "There are two record types, fixed length and variable length." A fixed length record "cannot vary from the length specified by the data description." ([J 02.07.03])
- "The QUANTITY IN clause, by designating that the length of a field within a record is variable in length, identifies the record as being a variable length record." The number of words processed on read/write is defined at object time by the current QUANTITY IN data.name value(s); "Storage, if the record is transmitted, is always allocated on the basis of the maximum size of the record." ([J 02.07.03])
- The standard variable length record is preceded by a control word containing the record length — "Although this control word is not described as part of the record in the Data Description and may not be addressed by the programmer, it must be considered in specifying block size" ([J 02.07.03]). BCD form: six BCD characters giving the length in words ([J 02.07.03]).
- Located records: all references to fields of a located record initially specify location zero and are adjusted upon GET; referencing before the first GET destroys low memory ([J 02.07.05]). Constants cannot be part of a located input area ([J 02.05.06]).

### 3.9 Storage areas

F chapter 4 closes with the storage-areas doctrine ([F p. 84–85]):

- Programmers conventionally distinguish an **input area** (space reserved for the original record before processing), **working storage** (e.g., intermediate results needed later but never output), an **output area** (where the output record is assembled), and areas for **reference data** "such as constants, literals, and tables" ([F p. 84]).
- COMTRAN erases the distinction: "Storage areas are automatically reserved when the data description is written, regardless of how the area is to be used." ([F p. 84–85]) All areas are addressed by location and governed by the same instructions ([F p. 84]).
- Obligations on the programmer: all data-names required for input and output, as specified in the processor manual, must be properly described; "every item of data used in the program, whether as input, output, or for intermediate operations" must be described ([F p. 85]). J's converse: no storage is allocated for fields not named in a Data Description entry ([J 02.05.01]).
- On the 7090, buffer storage for I/O is reserved by the Loader and assigned dynamically ([J 02.07.02]); located records live in buffers, transmitted records get their own storage — see the Input/Output section.

### 3.10 Numeric limits and defaults — summary

| Item | Limit / default | Citation |
|---|---|---|
| Data name length | up to 30 characters | [F p. 67] (rules on [F p. 15]) |
| Name field on card | 16 columns (7–22), continuable | F p. 65, 67 |
| Description field on card | 34 columns (38–71), continuable | [F p. 65] |
| Level numbers | 1–99; leading zeros optional (J) | [F p. 68]; [J 02.05.01] |
| Levels in a data hierarchy | ≈ 23 max | [J 90.01.05] |
| Quantity default | 1 | [F p. 77]; [J 02.05.04] |
| Quantity maximum | 2¹⁵ − 1 | [J 02.05.04] |
| Quantity nesting | 3 levels per nested group (F) | [F p. 77] |
| Subscripts per reference | up to 3 (F) | [F p. 30] |
| Array origin | A(1), not A(0) | [J 02.04.07.01] |
| Fixed point single precision | formats up to 10 digits; > 10 digits = double precision | [J 02.05.06] |
| Scientific decimal fraction | max 16 digits | [J 02.05.05] note 4 |
| LABEL area | 14 words | [J 02.05.03] |
| QUANTITY IN specifications | ≈ 25 | [J 90.01.05] |
| Array dimensions (explicit or implicit Quantity specs) | ≈ 85 | [J 90.01.05] |
| Positional indicators (unique array/subscript combinations) | ≈ 90 | [J 90.01.05] |
| Index expressions (a * VARIABLE ± b) | ≈ 50 | [J 90.01.05] |
| Internal dictionary (all program names) | ≈ 3500 | [J 90.01.05] |
| Different edited field formats | ≈ 35 | [J 90.01.05] |
| Base locators (field test: number of located records) | ≈ 127 | [J 90.01.05] |
| Generated constants in constant pool | ≈ 500 | [J 90.01.05] |
| Files describable (Environment) | 63 max | [J 90.01.04] |
| Internal fixed-point field length (L or blank justify) | least multiple of 6 bits holding number + sign | [J 02.05.04] |
| Internal right-justified field | one full word (two if double precision), sign in sign bit | [J 02.05.04] |

(Values from [J 90.01.05] are headed "Appox-Max Size" — approximate maxima of compiler internal tables.)

### 3.11 F/J divergences in data description — summary

| Topic | F28-8043 (1960) | J28-6169 (1962, authoritative) |
|---|---|---|
| PARAM / FUNCT type codes | defined ([F p. 73]) | "no longer in the language" ([J 02.05.03]) |
| COPY type code | defined ([F p. 76–77]) | implementation deferred ([J 90.01.03]) |
| LIBRARY descriptions / INCLUDE | defined ([F p. 81]) | no library facilities; INCLUDE deferred ([J 90.01.02]) |
| RCDMRK type code | absent | added ([J 02.05.03]) |
| BLANK WHEN ZERO clause | absent | added ([J 02.05.07]) |
| Serial number sequence check | checked on read-in ([F p. 67]) | not sequence checked ([J 02.03.01]) |
| Sign overpunch position | units **or** high-order position ([F p. 80]) | external decimal: rightmost position only; free-standing + or − illegal in such fields ([J 02.05.05] note 1) |
| REDEF card contents | may carry a new name for the redefined area ([F p. 75]) | no coding on the REDEF line except serial number and target name ([J 02.05.02]) |
| Quantity at record level | not addressed | unacceptable; record.names not subscriptable ([J 02.05.01], 90.01.03) |
| Constant continuation across cards | each line a complete quoted constant ([F p. 83]) | 7090 also accepts single literal split across cards — nonportable ([J 02.03.01]) |
| A vs X pictorial characters | distinct (non-numeric vs any character) ([F p. 80]) | synonymous on 7090 ([J 02.05.04]) |
| Mixed A/9 pictorials | not addressed | illegal; treated as alphameric ([J 90.01.03]) |
| Mode meanings | machine-dependent, deferred to processor manuals ([F p. 78]) | I = binary, E = BCD ([J 02.05.04]) |

Open flags for the compiler writer (detailed in the §8.5 catalog): the maximum subscript/quantity-nesting depth under J; the exact written form and card position of BLANK WHEN ZERO; the meaning of "non-format field"; and whether a named REDEF line is accepted. (The exact reading of the External Decimal row of the [J 02.05.05] chart, formerly flagged here, has been scan-resolved — see §8.5.8.)

---

## 4. Arithmetic and data-manipulation statements

COMTRAN's data-manipulation vocabulary is deliberately small. Two verbs — SET and ADD — "are used for arithmetic" and "form the basis for the three types of arithmetic commands" (SET, ADD, ADD CORRESPONDING) ([F p. 44]). One verb — MOVE, with its alternate form MOVE CORRESPONDING — "has as its primary function the transmission, or movement, of data from one area of storage to one or more other areas"; data transmission is also implicit in other verbs, e.g. "the SET verb requires the transmission of result data after the computation has been performed" ([F p. 41]). All other arithmetic (subtraction, multiplication, division, exponentiation) is expressed through the arithmetic expression on the right side of a SET; the SET command "can be used for all arithmetic" ([F p. 44]).

Statement-level syntax (imperative clauses, sentences, period-blank termination, the Col. 13–72 text area) is covered in the sections on language structure and procedure format; data-description matters (pictorials, modes, levels) in §3 (Data description and storage model). This section covers the arithmetic/transmission verbs themselves, the expression language they share, the mixed-mode conversion rules, and the editing feature.

### 4.1 Arithmetic expressions

"An arithmetic expression is a combination of data-names, conditional expressions, and/or literals, joined together by one or more arithmetic operators in such a way that the entire expression can be reduced to a single numeric value" ([F p. 20]). Both simple and compound names may be used in an arithmetic expression ([F p. 20]). Per the formal rules: "Arithmetic expressions may contain the names of variables, constants and functions, also literals and conditional expressions, joined by arithmetic operators. Subexpressions may be contained in parentheses as required" ([F p. 105–106]).

#### 4.1.1 Operator inventory

Binary operators (each "relates two quantities", [F p. 45]):

| Operator | Written as | Citation |
|---|---|---|
| Addition | `+` | ([F p. 21], p. 45, p. 106) |
| Subtraction | `−` | ([F p. 21], p. 45, p. 106) |
| Multiplication | `*` | ([F p. 21], p. 45, p. 106) |
| Division | `/` | ([F p. 21], p. 45, p. 106) |
| Exponentiation | `**` | ([F p. 21], p. 45, p. 106) |

Unary operators ("affect only the quantity or expression which follows", [F p. 45]):

| Operator | Written as | Citation |
|---|---|---|
| Negation | `−` | ([F p. 21], p. 45, p. 106) |
| Absolute value | `ABS` | ([F p. 21], p. 45, p. 106) |
| Truth value | `TR` | ([F p. 21], p. 45, p. 106) |

ABS yields "the value of a number treated as if the sign were positive" ([F p. 21]). TR is described in §4.1.4 below. All operator words (TR, ABS) and the option words TRUNCATED and OVERFLOW are reserved and may not be used as Data or Procedure names in the 7090 system ([J 02.03.02]; see the reserved-words section).

"If the operand of a unary operator is an expression it must be enclosed in parentheses" ([F p. 45]), as in:

```
... + ABS (A + B)
... * (−(ON.HAND + ON.ORDER))
... TR (A IS LESS THAN B)
```

([F p. 45])

#### 4.1.2 Precedence, associativity, parenthesization

The implemented (J) rule, quoted in full:

```
TR or ABS or - (Negation)
**
* or /
+ or -
```

"When the hierarchy of arithmetic operations in an expression is not explicitly specified by the use of parentheses, operators are honored in the following order [above] ... When there are two operators of the same hierarchy, ordering proceeds from left to right" ([J 02.04.05.01]). Worked examples from the same page:

- `A+B/C+D**E*F` is taken to mean `(A+(B/C)) + ((D**E)*F)` ([J 02.04.05.01])
- `A*B*C` is taken to mean `(A*B)*C`; `A*(B*C)` is taken to mean `(A*(B*C))` ([J 02.04.05.01])

The F statement agrees for the binary operators: "the order of operations (working from inside to outside) is assumed to be exponentiation, then multiplication and division, and finally addition and subtraction" ([F p. 107]), with left-to-right grouping for equal levels, so that "expressions ordinarily considered ambiguous, e.g., A/B · C and A/B/C, are permitted"; `A*B/C*D` is taken to mean `((A*B)/C)*D` ([F p. 107]).

Additional rules a compiler writer must observe:

1. **Repeated exponentiation must be parenthesized.** "The expression Aᴮᶜ, which is sometimes considered meaningful, cannot be written as A**B**C; it should be written as (A**B)**C or A**(B**C), whichever is intended" ([F p. 107]). J does not restate this rule; the J left-to-right rule for equal hierarchy would read `A**B**C` as `(A**B)**C`, but F flatly forbids the form — treat it as illegal (see the §8.5 catalog).
2. **No two successive binary operators.** "The programmer must not write two successive arithmetic operators unless the second of them is either the operator TR or the operator ABS. Where the effect of two successive operators is required, one term may be enclosed in parentheses; thus, while the expression A * -B is illegal, the same value may be written A * (-B)" ([F p. 27], rule 6).
3. **Operators bind to the next item.** "All operators act on the next named item, or the next parenthetical expression, following the operator" ([F p. 28], rule 9). Parentheses "may be used wherever needed ... for the sake of clarity; where ambiguity would result from their omission, they *must* be used" ([F p. 28], rule 11).
4. **Blanks around operators are optional** and ignored: `A + B * C` may be written `A+B*C` ([F p. 27], rule 6).

The legal symbol-pair table from F Appendix 2 ("1" = permissible pair, "0" = not permissible) — note that it admits a leading unary minus only after `(`, and ABS/TR after a binary operator or `(` ([F p. 106]):

| First Symbol ↓ / Second Symbol → | Variable | + − * / ** | ABS, TR | Negation − | ( | ) |
|---|---|---|---|---|---|---|
| Variable | 0 | 1 | 0 | 0 | 0 | 1 |
| + − * / ** | 1 | 0 | 1 | 0 | 1 | 0 |
| ABS, TR | 1 | 0 | 0 | 0 | 1 | 0 |
| Negation − | 1 | 0 | 0 | 0 | 1 | 0 |
| ( | 1 | 0 | 1 | 1 | 1 | 0 |
| ) | 0 | 1 | 0 | 0 | 0 | 1 |

([F p. 106]. Note the table permits "Negation − Variable" and "Negation − (" but no operator directly after negation, and forbids "ABS ABS", "TR TR", "ABS TR" chains.)

**F/J divergence (negation precedence):** J places unary negation in the *highest* group ("TR or ABS or - (Negation)" honored before `**`), so under a literal reading `-A**2` would mean `(-A)**2`, not `-(A**2)` ([J 02.04.05.01]). F is compatible: the "next named item" rule ([F p. 28], rule 9) has negation act on the immediately following item only. This differs from later-language conventions; see the §8.5 catalog.

#### 4.1.3 Operands: variables, constants, literals

- "Data-names which represent numeric variables or constants may appear anywhere in arithmetic expressions. Those which represent alphameric variables and constants, however, may appear only within truth functions" ([F p. 45]).
- J restates and sharpens this for SET: "The operands of a SET instruction which are used in an arithmetic expression may be fields of any format except alphameric" ([J 02.04.05]); any of the field formats of §3 — external decimal, internal decimal, edited, floating point, scientific decimal — is acceptable, with automatic conversion (see §4.2).
- Literals may be used as needed in arithmetic expressions ([F p. 45]). Numeric-literal rules (see also the constants/literals section): maximum 50 characters, no continuation across lines; only numerals, at most one decimal point, and a sign; the decimal point "is required except where it would be the last character of the literal; in that case it must *not* be used"; numeric literals must not be enclosed in quotation marks ([F p. 18]). **"If the literal is to be operated on arithmetically, it must contain not more than 20 digits"** ([F p. 18]).
- Floating point literals take "the standard scientific decimal form" `fraction F±exponent` ([J 02.04.02]): fraction and exponent may each be signed or unsigned (positive assumed); **a decimal point must be present in the fraction** ("20.F+01 is interpreted as a floating point literal, but 20F+01 is interpreted as an arithmetic expression"); the F must be followed by at least one digit, which may be signed (`20.F0`); `F` yields a single precision floating point number, `FF` double precision ([J 02.04.02]). F's earlier statement of the same form: the fraction, the symbol F, then the exponent, base 10 only, e.g. `1.5F3`, `15F2`, `.15F4`, `2F-3`; F and the decimal point occupy no storage and are not counted in the literal's length ([F p. 18]). **F/J divergence:** F's examples include point-less fractions (`15F2`, `2F-3`); J requires the decimal point in the fraction and reads the point-less form as an arithmetic expression. J governs.
- Figurative constants (ZERO/ZEROS, BLANK/BLANKS, HIGH.VALUE(S), LOW.VALUE(S)) may be used as source fields by SET as well as MOVE — see the chart in §4.7.4 ([J 02.04.01]–02).
- Subscripted operands are permitted; a subscript is a name, a literal, or an expression of the form `a * VARIABLE ± b` with a and b literals, and must represent "a positive integral value" ([F p. 31]). Arrays index from 1: "The initial value of an array is A(1) and not A(0)" ([J 02.04.07.01]). See §3 and the indexing discussion for positional-indicator behavior and limits.
- Function-names may appear as operands (see §4.9).
- A compile-time diagnostic exists for a missing operand: "MISSING OPERAND ASSUMED TO BE ZERO." ([J 90.04.01], message 116,00).

#### 4.1.4 Truth functions (TR)

"A conditional expression enclosed in parentheses preceded by the truth operator TR is known as a truth function. A truth function always has one of two values, 1 or 0, depending on whether the conditional expression is true or false" ([F p. 45]). "Accordingly, a truth function can be manipulated arithmetically in the same manner as any other quantity" ([F p. 45–46]). The conditional expression is tested at object time; "It is generally used to multiply one or more terms in an arithmetic expression ... it can be used to cancel a term ... if a condition exists in which the term is not wanted" ([F p. 20]; mechanism restated [F p. 24]).

```
SET DISCOUNT = ORDER.AMOUNT * .05 * TR
    (ORDER.AMOUNT IS GREATER THAN 1000).
```

([F p. 24])

```
SET REORDER = ORDER.AMT * TR (STOCK.LEVEL LT
    ORDER.POINT).
```

([F p. 44]; explained [F p. 46]: REORDER receives the order amount if stock level is below order point, otherwise zero.)

"The truth operator may be used with relational expressions, as in the example given, or with condition-names" ([F p. 24]). This is the sole channel by which alphameric data participates in arithmetic ([F p. 45]). The conditional expression inside TR is subject to the J comparison restrictions (numeric may not be compared with alphameric; unequal-length alphameric `=`/`NOT =` comparisons always compare unequal; edited fields are converted to pure numeric for comparison; variable length fields may not be compared; zero is considered unsigned) — see the conditional-statements section ([J 02.04.06], 02.04.07).

### 4.2 Modes, precision, and mixed-mode evaluation (709/7090)

#### 4.2.1 Where arithmetic is performed

"Arithmetic operations are performed only in the internal (binary) mode. For this reason it is advantageous to have fields used in arithmetic operations in the internal mode when the programmer has a choice. If the fields are in the external mode and reoccur in different arithmetic statements, it is generally more efficient to MOVE this data to an area which has been defined with the mode as internal" ([J 02.03.03]). The manual's worked example (Data Description: A `999`, B `99`, C `99`, D `999`, E `99`, all external; X internal right-justified `IR999`):

```
SET A = B+C
SET D = A+E
```

is improved (fewer conversions) by

```
SET X = B+C
SET D = X+E
```

and

```
SET A = B+C
SET D = B+E
```

by

```
MOVE B to X
SET A = X+C
SET D = X+E
```

([J 02.03.03.01]). Every reference to an external-mode operand implies an unpack-and-convert at object time; every store into an external or edited target implies a convert-and-edit. "Appropriate conversion is performed in all cases although arithmetic operations are considerably less efficient when performed on fields having dissimilar formats. Generally, fields frequently referenced in arithmetic expressions should be converted to internal form right justified for most efficient operation" ([J 02.04.05]); "Numeric external fields to be involved in extensive computation should be converted to this internal right justified by a preliminary SET or MOVE in order to prevent repetitive unpacking and converting" ([J 02.05.04]).

#### 4.2.2 Arithmetic modes and precision

"The 709/7090 Commercial Translator System allows single or double precision arithmetic in either the floating or fixed point modes. Floating point arithmetic is the 709/7090 floating binary arithmetic. Fixed point arithmetic is a binary integer arithmetic with decimal scaling" ([J 02.04.05]).

Precision is declared through the pictorial: "Fixed point double precision numbers are denoted in the Data Description by formats representing more than 10 digits. Double precision internal floating point numbers are specified by 'FF' in the Data Description" ([J 02.05.06]). Correspondingly, `F` vs `FF` in a literal selects single vs double precision floating point ([J 02.04.02]). The maximum fractional portion of a scientific decimal field is 16 digits ([J 02.05.05], note 4).

**Mode-promotion (mixed-mode) rule, quoted in full:** "If a floating point or double precision number is encountered in the evaluation of an arithmetic expression, all remaining operations in the expression will be performed in floating point or double precision mode, as appropriate. Once the mode of evaluation is thus changed, the appearance of a number in the other of these modes will force subsequent evaluation to be performed in double precision-floating point mode" ([J 02.04.05.01]). I.e. evaluation starts in single-precision fixed point; encountering a floating point operand promotes the *remainder* of the evaluation to floating; encountering a double precision operand promotes to double precision; encountering both promotes to double-precision floating point. Promotion is one-way and applies to "all remaining operations", not retroactively.

Observed processor semantics consistent with this (phrased from the generated-code appendix, not as guidance): fixed-point evaluation uses double-precision binary integer work registers with explicit decimal upscale/downscale steps by constants and by 10**10 ([J 90.02.12], 90.02.13); exponentiation is performed by floating point exponential routines in all four single/double combinations of base and power ([J 90.02.11], 90.02.13); a dedicated sign-adjustment subroutine exists for double precision fixed point numbers ([J 90.02.11.01]).

Compile-time scale diagnostics: "DOWNSCALE GENERATED WHICH LOSES ALL SIGNIFICANT FIGURES." (27,00), "ATTEMPTED DIVISION BY ZERO BYPASSED. RESULT TAKEN TO BE ZERO." (28,00), "UPSCALE MAY CAUSE HIGH ORDER TRUNCATION FOR STORE INTO 'NAME.1'" (199,00) ([J 90.04.01]).

#### 4.2.3 Legal operand/target formats — summary

| Context | Rule | Citation |
|---|---|---|
| Operand of an arithmetic expression | Any field format **except alphameric** | ([J 02.04.05]) |
| Alphameric data in arithmetic | Only within a truth function | ([F p. 45]) |
| Result field of SET | Any format, **including alphameric**; `SET alpha.field.1 = alpha.field.2` is allowed "since no arithmetic expression is specified" | ([J 02.04.05]) |
| Comparison operands (inside TR) | Numeric may not be compared to alphameric | ([J 02.04.06]) |

A statement operating on a field whose format is improper draws "OPERATION IGNORED BECAUSE 'NAME.1' HAS IMPROPER DATA FORMAT ( E  A(2) ) FOR THIS USE." ([J 90.04.01], message 25,00).

### 4.3 The SET command — arithmetic assignment

General form:

```
SET variable.1, variable.2, ... variable.n = arithmetic expression
```

([F p. 44]). The concise Appendix-2 form shows the two optional phrases (brackets = optional):

```
SET variable.1, variable.2, ... variable.n = arithmetic expression
    [TRUNCATED][, ON OVERFLOW any imperative clause]
```

([F p. 109])

"The equal sign in the SET command is used in the sense of replacement. It means, 'replace the value of the variable(s) on the left side of the equal sign with the value of the expression on the right'" ([F p. 44]).

Examples from the manual ([F p. 44]):

```
SET GROSS.PAY = BASE.RATE * 40.
SET NET.PAY = GROSS.PAY − (FICA + STATE.TAX +
    DEDUCTIONS).
SET A= B * (C + D), ON OVERFLOW GO TO ERROR.
SET REORDER = ORDER.AMT * TR (STOCK.LEVEL LT
    ORDER.POINT).
SET APPROX = 2 * SQUARE.ROOT ((X)) TRUNCATED.
SET A, B, C =D.
```

These examples collectively use every element that may appear in an arithmetic expression: "arithmetic operators, names of variables and constants, literals, truth functions, and function-names" ([F p. 45]).

#### 4.3.1 Result editing and multiple results

- "If required, the result of a computation will be edited automatically according to the format of a receiving field as specified in the data description. For example, if a result represents an amount of money, editing appropriate to the defined format of the money field will be performed" ([F p. 44]).
- Multiple result fields are permitted (`SET A, B, C = D.`); the expression is written once and each named variable is replaced by its value ([F p. 44]). The manuals do not state the order of the stores nor whether each store draws on the full-precision intermediate (see the §8.5 catalog; the natural reading of "replace the value of the variable(s) ... with the value of the expression" is that each target independently receives the expression value, edited/aligned to its own format).

#### 4.3.2 Rounding and TRUNCATED

"Ordinarily the result of the SET operation will be rounded to the number of places indicated by the format description of the result field or fields. If the dropping of digits (instead of rounding) is desired, the arithmetic expression is followed by

```
... TRUNCATED
```

" (F p. 44). So rounding-on-store is the *default*; TRUNCATED suppresses it. TRUNCATED is a reserved word in J (J 02.03.02). The rounding rule is stated in F's glossary (ROUND): the least significant remaining digit "is increased by 1 when the part removed is greater than or equal to one-half", with worked examples rounding 126.5027 to 127, to 126.503 (six positions), and to 13 "understood to be 130" (two positions) (F p. 115); the companion TRUNCATED entry contrasts 2063.78 → 2063.7 truncated vs 2063.8 rounded (F p. 116). Negative-value handling and rounding-induced overflow remain unstated (see §8.5). The generated-code appendix shows explicit "Round current character" subroutine steps (SYS)219–222) inside the numeric move/convert packages (J 90.02.16, 90.02.17), confirming rounding is applied character-wise at store/convert time.

#### 4.3.3 Overflow and ON OVERFLOW

"In the process of storing the final result of a SET command it is possible for a loss of significant high-order digits to occur. For example, if a result field has been defined as having three places to the left of the decimal point and a result such as 1001 is developed, the high-order '1' will be lost. This situation is known as 'overflow.' If the SET command specifies just one result field (i.e., if it has only one variable-name to the left of the equal sign), the programmer may anticipate and provide for an overflow by appending

```
..., ON OVERFLOW any imperative clause
```

at the end of the SET command. In the event of an overflow, the object program will execute the command thus specified instead of storing the erroneous result" (F p. 44). Key points:

- ON OVERFLOW is legal **only when there is a single result field** ([F p. 44]; same restriction for ADD, [F p. 47]).
- With ON OVERFLOW present, the erroneous result is **not stored**; the imperative clause executes instead ([F p. 44]).
- Behavior when overflow occurs and no ON OVERFLOW clause was written is not stated in either manual. Observed processor mechanism: communication cell SYS)130 "is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects the truncation of significant high order values (i.e. overflow)" ([J 90.02.10]); there is also SYS)131 for "an improper data condition" and SYS)134 for floating point underflow resulting from a Move ([J 90.02.10], 90.02.11). See the §8.5 catalog.
- OVERFLOW is a reserved word in J ([J 02.03.02]).

#### 4.3.4 SET side effects on subscripting

Executing a SET that changes a subscript variable updates the positional indicators of subscripted names using that variable: "In general, positional indicators are evaluated when their subscripts change value. Execution of the code generated for SET K=K+2 would cause the positional indicators for 3 of the subscripted names shown above to be updated: A(J, K), A(2, K), and A(J, K+1)" ([J 02.04.07.01]). Two consequences for correctness (from the deferred-features appendix):

- "The dimensions of an array must be set before calculation of subscript values associated with the array is performed. Presently, failure to observe this restriction causes invalid object code." The erroneous ordering example given is `SET I = 3, SET J = 5.` / `SET Q = 10.` (where Q is the QUANTITY IN variable) / `MOVE A (I,J) TO R.` — the positional indicator for A(I,J) is computed when I and J are set and is *not* updated when Q is set ([J 90.01.02]).
- Reuse of one subscript name for many purposes causes unnecessary re-evaluation of all positional indicators containing it (correct, but wasteful); "No object time check is made to insure that subscript references conform to the limits specified by the array dimensions" ([J 90.01.02]).

### 4.4 SET used with condition-names

"The SET command has a second function that is not strictly arithmetic. It provides a convenient way of changing the status of a conditional variable, i.e., a variable which has one or more conditions associated with it. When SET is used for this purpose it takes the general form:

```
SET condition.name
```

As a result of this command, the variable with which 'condition.name' is associated (in the data description) is assigned the status, or value, of the specified condition" (F p. 46). Example: if MARITAL.STATUS is currently SINGLE, `SET MARRIED.` "is the equivalent of writing: `SET MARITAL.STATUS = 'M'.`" (F p. 46).

"It is important to recognize the distinction between testing and setting the value of a conditional variable. Testing the value provides a basis for a decision but does not change the value; the testing is accomplished by using a conditional clause, IF . . . THEN. Setting a value ... causes the current value to be replaced by another of the possible values and is effected by means of the SET command" ([F p. 46]).

Condition-names and their values are declared with the COND type code in the data description (see §3; [J 02.05.02]). J restriction: "Neither a data item (literal) nor a condition.name may be subscripted. However, a conditional variable may be subscripted" ([J 90.01.03]) — so `SET condition.name` cannot designate one element of a subscripted conditional variable (open question below). The compiler has a generic diagnostic "INCORRECT USAGE OF FIGURATIVE CONSTANT." ([J 90.04.01], message 82,00), whose triggering contexts are not documented; a badly formatted conditional variable draws "FORMAT ERROR FOR CONDITIONAL VARIABLE. 'NAME.1' FORMAT USED." ([J 90.04.01], message 37,00).

### 4.5 The ADD command

General form:

```
ADD data.name TO variable.1, variable.2, ... variable.n
```

([F p. 47]). "The effect of the ADD command is to increment the one or more named variables by the quantity represented by 'data.name.' In this context, 'data.name' may be a literal or the name of a variable, constant or function" ([F p. 47]).

"The optional phrases TRUNCATED and ON OVERFLOW described above in conjunction with the SET command are equally applicable to the ADD command. As in the case of SET, the ON OVERFLOW option is permitted only if the command specifies a single result field" ([F p. 47]).

Examples ([F p. 47]):

```
ADD GROSS.PAY TO YR.TO.DATE.GROSS.
ADD 1 TO COUNTER, ON OVERFLOW GO TO BEGIN.
ADD ADJUST.FACTOR TO RATE TRUNCATED.
```

The Appendix-2 concise form folds ADD and ADD CORRESPONDING together:

```
ADD [CORRESPONDING] data.name.1 TO data.name.2, data.name.3,
    ... data.name.n
```

([F p. 108]). Note the Appendix-2 form does not repeat the TRUNCATED/ON OVERFLOW phrases for ADD, but the body text grants them explicitly ([F p. 47]). J adds no ADD-specific amplification; the mixed-mode conversion rules of §4.2 and the operand-format rules of §4.2.3 apply to each addition.

### 4.6 The ADD CORRESPONDING command

General form:

```
ADD CORRESPONDING data.name.1 TO data.name.2, data.name.3,
    ... data.name.n
```

([F p. 47]). "Each 'data.name' in an ADD CORRESPONDING command must represent an area of storage which is composed of smaller units or fields. The effect of the command is to cause each field in 'data.name.1' to be added to its corresponding field (i.e., a field with the same name) in the 'to' area(s). Non-corresponding fields in 'data.name.1' and in the 'to' areas are not affected by the command" ([F p. 47]).

The manual's totals-accumulation example: with detail-record fields GROSS.PAY, FICA, FED.TAX, STATE.TAX, DEDUCTIONS and records DEPT.TOTALS and GRAND.TOTALS containing corresponding fields,

```
ADD CORRESPONDING DETAIL.RECORD TO DEPT.TOTALS,
    GRAND.TOTALS.
```

has the same effect as five explicit ADDs of qualified names (`ADD DETAIL.RECORD GROSS.PAY TO DEPT.TOTALS GROSS.PAY, GRAND.TOTALS GROSS.PAY.` etc.) ([F p. 47]).

Matching rules are those of §4.8 (shared by MOVE and ADD; [J 02.04.04]). Diagnostics: "NEITHER -ADD- NOR -MOVE- PRECEDES -CORRESPONDING-" (63,00); "INVALID -CORRESPONDING- STATEMENT." (97,00) ([J 90.04.01]).

### 4.7 The MOVE command

General form:

```
MOVE data.name.1 TO data.name.2, data.name.3, ... data.name.n
```

([F p. 42]). "The data specified by 'data.name.1' is moved to the area of storage designated by 'data.name.2' and to any other area(s) mentioned in the command ... As used in this command 'data.name' may represent data at any level defined in the data description" ([F p. 42]). "Note that in each case the data in the sending area remains unaltered after the MOVE has been executed" ([F p. 43]).

#### 4.7.1 Legality: what may move to what

F's 1960 statement:

1. "Information from numeric fields may be moved to other numeric fields, to alphameric fields, and to report fields."
2. "Information from alphabetic or alphameric fields may be moved only to other alphabetic or alphameric fields." ([F p. 42])

("Report fields" is F's term for fields carrying editing symbols; J's term is "edited field" — see the §8.5 catalog.)

J's 1962 statement, in terms of the six 7090 field types (alphameric, external decimal, internal decimal, edited, floating point, scientific decimal — see §3 and [J 02.05.05]): "all types of data may be moved into an alphameric field but the contents of an alphameric field may only be moved to another alphameric field" ([J 02.04.03]). Combined with the F rules, every numeric-to-numeric combination is legal, with automatic conversion; alphameric is a universal sink and an alphameric-only source.

Group items behave as alphameric: "A field for which no pictorial is given is treated as alphameric with length equal to the length of its subfields" ([J 02.05.06]); this drives the CORRESPONDING error case in §4.8. An illegal move is diagnosed at compile time: "ILLEGAL MOVE - FROM 'NAME.1' ( E  A(2) ) TO 'NAME.2' ( IR  999 ). NOTHING DONE ." ([J 90.04.01], message 84,00 — i.e. alphameric to internal-decimal is rejected). Also "INCOMPLETE -MOVE- EXPRESSION." (119,00) ([J 90.04.01]).

#### 4.7.2 Conversion routing between field types (J)

The J chart (a boxes-and-arrows schematic, [J 02.04.03]; page image `J28-6169/images/page-020.png` is ground truth) shows *internal decimal (right justified)* as the hub, with a two-way arrow to *internal decimal (not right justified)* and two-way spokes to *edited field*, *external decimal*, *scientific decimal*, and *floating point*; there are also direct two-way arrows *edited field* ↔ *external decimal* and *scientific decimal* ↔ *floating point*; *alphameric field* is reached by three arrows — from edited field, external decimal, and scientific decimal. Every box except *internal decimal (not right justified)* has a self-directed arrow (an IDnj→IDnj move goes via internal decimal right justified, matching prose exception a below). The governing prose:

- a) "When source and target fields have the same format no intermediate form is necessary (except for edited fields and internal decimal fields not right justified) and transmission is direct as indicated by the self-directed arrows" ([J 02.04.03]).
- b) "When source and target fields of unlike format are involved the conversion steps are defined by the diagram arrows where the route requiring least intermediate steps is used", e.g.: floating point → external decimal requires an intermediate conversion to internal decimal; floating point → alphameric requires conversion to scientific decimal form first; internal decimal → alphameric requires a conversion to external decimal form ([J 02.04.03]).
- c) The alphameric sink/source rule quoted in §4.7.1 ([J 02.04.03]).
- d) "Subroutines are normally used to perform the requisite conversion and transmission except where arrows have associated an \*. These moves are normally performed by in-line instructions" ([J 02.04.04]). (Starred in the chart: the internal-decimal (rt. justified) self-move, the floating-point self-move, the alphameric self-move, and the three arrows into alphameric — edited-field→alphameric, external-decimal→alphameric, scientific-decimal→alphameric. The external-decimal, edited-field, and scientific-decimal self-loops are unstarred, i.e. subroutine moves — consistent with MOVPAK's XD→XD subroutine SYS)183, [J 90.02.15].)
- e) **Scientific decimal sources are free-form:** "For the source fields of the scientific decimal type, a free form of data is allowed within the limits of the field. For example, a field with the pictorial -99V-99 may contain the value 1 in any of the following ways, (b represents a space):

```
b.01b2b        (i.e.   01 x 10^2)
1bb+01b        (note above scale applies when no point)
.001bb3
b1bbbbb        (note above scale applies when no point)
1000.-3
etc.
```

" (J 02.04.04).

The runtime move/convert machinery is a packaged subroutine set, MOVPAK, whose entries cover XD→XD, XD→ID, ID→XD (unsigned, overpunch-minus, overpunch-plus variants), XD→EF, EF→XD, and EF→EF moves, with per-call instruction words for characters-to-move, characters-to-test-for-overflow, characters-to-bypass, leading/trailing zeros to insert, "Round current character", and target numeric length ([J 90.02.10], 90.02.15–90.02.19) — observed semantics: numeric moves are character-serial with in-flight rounding, overflow testing, and zero insertion.

#### 4.7.3 The editing feature

"Editing of the data in the sending area to conform to the format of the receiving area is a feature of the MOVE command. Such editing occurs automatically if an explicit format definition, i.e., a field pictorial, is given in the data description for both the 'from' and the 'to' areas" ([F p. 42]). The conventions, quoted in full ([F p. 42]):

**Numeric information:** "The data from the sending area is aligned with respect to the decimal point (assumed or actual) in the receiving area. Such alignment may involve the dropping of leading digits or low-order digits (or both if the sending field is larger than the receiving one). If the 'from' area is smaller than the 'to' area, the excess positions of the receiving area will be replaced by zeros."

**Alphameric information:** "If the sending area is larger than the receiving area, the data being moved will be left-justified and truncated; i.e., low-order characters will be dropped as may be necessary to make the data fit into the receiving area. If the sending area is the smaller, the data will be left-justified in its new location. The low-order positions of the receiving area, i.e., the excess positions, will be filled with blanks."

The manual's worked examples ([F p. 43]; verified against the page scan). In the pictorials, 9 = any digit, A = any non-numeric character, X = any character, V = assumed decimal point:

| Sending Pictorial | Sending data before/after MOVE | Receiving Pictorial | Receiving before | Receiving after |
|---|---|---|---|---|
| 99V99 | 1234 | 99V99 | 8765 | 1234 |
| 99V99 | 1234 | 99V9 | 876 | 123 |
| 9V9 | 12 | 99V99 | 8765 | 0120 |
| AAAAA | JONES | AAAAA | VWXYZ | JONES |
| 99999 | 01234 | 999V9 | 7777 | 2340 |
| AAA | RUN | AAAXX | JOB #2 | RUN␢␢ |
| AAAAA | BLACK | AAA | RED | BLA |

(Sixth example: "the information in the two excess positions of the receiving area is replaced by blanks", [F p. 43]. In the fifth, integer 01234 aligned into 999V9 keeps digits 234 and zero-fills the fraction place; in the third, 1.2 into 99V99 gives 01.20.)

**Editing/format characters.** Editing behavior on output is entirely driven by the receiving field's pictorial, declared in the data description (declaration side: §3). The complete F table of format characters ([F p. 80]):

| Format Character | Meaning and use |
|---|---|
| `A` | Any non-numeric character, including the blank. |
| `X` | Alphameric character (any character in the machine's character set). |
| `9` | Any numeric character. |
| `8` | Numeric character, "to be replaced automatically by a blank whenever it is a non-significant zero" (zero suppression). |
| `*` | Numeric character, "to be replaced automatically by an asterisk whenever it is a non-significant zero" (check protection). |
| `V` | Assumed decimal point; used for calculation/alignment; reserves no storage space; not required for integers. |
| `.` | True decimal point; reserves an actual space in storage. |
| `S` | Scale factor — a "filler"/"spacer" when input data does not show the decimal position. `VS9` makes values 1–9 read as .01–.09; `999SSS` provides for 000,000–999,000 with the three low-order zeros absent from input. |
| `$` | Dollar sign, placed in the indicated position, "provided it is not followed by the symbol 8. In the latter case, the dollar sign will 'float'—i.e., it will be placed immediately to the left of the first significant digit remaining." |
| `,` | True comma; reserves a space; "may be replaced by a blank, asterisk, or dollar sign, if the operation of a preceding 8 or * has resulted in the elimination of non-significant zeros to the left." |
| `+` | Plus **or** minus sign, one of which is always placed in the reserved space according to the value's sign. May occupy a column by itself (reserving a space), or be an "overpunch" with a format character 8 or 9 "in either the units or high-order position of a field", in which case no space is reserved. |
| `-` | Minus sign, placed when the value is negative; **blank when positive**. Same by-itself/overpunch placement rules as `+`. |
| `F` | Floating point indicator; reserves no space; placed between the fraction's and the exponent's format characters, e.g. `+99V9F+99`. |
| `(n)` | Repetition: a parenthesized number after a format character multiplies it; `9(4)A(12)` ≡ `9999AAAAAAAAAAAA`. |

Range examples ([F p. 81]): `AAA` — all non-numeric; `88999` — 000 to 99999; `****.99` — \*\*\*\*.00 to 9999.99; `$888,888.99` — $.00 to $999,999.99.

The J field-type chart classifies a field as an **Edited Field** when its pictorial contains any of `8 * . , $ + -` or when the BLANK WHEN ZERO clause is used; legitimate format characters for an edited field are `9 8 * . , $ + - S V (n)`, with `8 or 9 or 8̅ or 9̅ in rightmost character` (overpunched sign); the field content is "digits and leading blanks; an overpunch with the rightmost digit" ([J 02.05.05]). "An edited field may have a character position reserved for the sign or may have the sign over the rightmost digit" ([J 02.05.05], note 2). "Numeric external fields may contain leading blanks which are treated as leading zeros" ([J 02.05.05], note 3).

**BLANK WHEN ZERO:** "When associated with an output field this clause indicates that the field is to be replaced with blanks when it becomes zero. Since leading blanks in numeric input fields are automatically treated as zeros, the use of this clause is redundant [for input]. In some cases it may even result in decreased efficiency in the object program as these fields are treated as edited types" ([J 02.05.07]).

**J restrictions touching edited fields and pictorials:**

- Constants cannot be defined "in a field whose pictorial characterizes it as an edited field" ([J 02.05.06]; "CONSTANT CANNOT BE GIVEN FOR EDITED TYPE FIELD.", [J 90.04.01] message 57,00).
- "A field may not be described as a mixed numeric and alphameric field, i.e., both A's and 9's in a pictorial. If this specification is made the field is treated as alphameric" ([J 90.01.03]).
- Pictorial characters A and X are synonymous in the 7090 compiler ([J 02.05.04]).
- Any non-format character in a pictorial causes it to be interpreted as a name ([J 02.05.06]).
- Internal-table limit: at most approximately **35 "different edited field formats"** per program ([J 90.01.05]; overrun draws "NUMBER OF DIFFERENT EDIT FIELDS EXCEEDS INTERNAL TABLE CAPACITY.", [J 90.04.01] message 204,00).
- For comparisons, "edited fields ... are converted to pure numeric fields. They may not be compared to alphameric fields" ([J 02.04.07]).

Observed processor semantics for edited targets ([J 90.02.17]): each edited-target move is parameterized by which editing characters the pictorial contains (asterisks, commas, decimal point, dollar sign, Blank When Zero), by the counts of leading `*`/`8` positions and of positions left of the real or implied decimal point, and by a target sign convention distinguishing no sign, overpunch minus/plus, right minus/plus, and left minus/plus — confirming the full sign-placement matrix implied by the F `+`/`-` format-character rules (sign by itself at either end, or overpunched).

#### 4.7.4 Figurative constants as MOVE/SET sources

"Figurative constants may be used as source fields by both MOVE and SET" ([J 02.04.01]). E.g. `MOVE ZEROS TO COUNTER`, `MOVE BLANKS TO AMOUNT` — "the specified area will be completely filled with characters of the value named" ([F p. 20]); `MOVE ZEROS TO MONTH.TOTAL, YEAR.TOTAL, CUMUL.TOTAL.` ([F p. 42]).

Values on the 7090: "HIGH.VALUE will be considered to be the left parenthesis, (, and LOW.VALUE the zero, 0, unless the Commercial collating sequence (COM) is specified in the Environment Description. The Commercial HIGH.VALUE is 9 and the LOW.VALUE is blank" ([J 02.04.01]).

Result of MOVEing/SETting figurative constants into each target type ([J 02.04.02]; \* = "An error message is given for each doubtful or illegal usage", # = "Value dependent upon collating sequence order specified (Commercial or 709)"):

| Figurative Constant | Alphameric | External Decimal | Internal Decimal | Edited Field | Floating Point | Scientific Decimal |
|---|---|---|---|---|---|---|
| BLANK or BLANKS | blanks | blanks\* | 0's\* | blanks\* | 0's\* | blanks\* |
| ZERO or ZEROS | 0's | 0's | 0's | 0's Edited | 0's | 0's Edited |
| LOW.VALUE or LOW.VALUES | 0's# or blanks | 0's #\* or blanks | Illegal\* | 0's #\* or blanks | Illegal\* | 0's #\* or blanks |
| HIGH.VALUE or HIGH.VALUES | ('s# or 9's | ('s #\* or 9's | Illegal\* | ('s #\* or 9's | Illegal\* | ('s #\* or 9's |

Restrictions:

- "Figurative constants may not be moved to variable length arrays, i.e., to fields with which QUANTITY IN is associated ... However, figurative constants may be moved to a particular element of a variable length array" ([J 02.04.01]); with the illustrated data description, "the sentence MOVE BLANKS TO ARRAY is illegal, whereas MOVE BLANKS TO FIELD(3) is proper" ([J 02.04.01]). Restated in the deferred-features appendix: "Figurative constants may not be moved to variable length arrays; they may, however, be moved to fixed length arrays or to array elements" ([J 90.01.02]). Diagnostic: "MOVE OF FIGURATIVE CONSTANT TO VARIABLE LENGTH FIELD NOT YET HANDLED BY SYSTEM." ([J 90.04.01], message 180,00).
- "Figurative constants may not be moved to fields which are longer than 2^15 - 1 characters" ([J 02.04.01]). The corresponding diagnostic reads "MOVE OF FIGURATIVE CONSTANT TO FIELD LONGER THAN 32766 CHARACTERS NOT YET HANDLED BY SYSTEM." ([J 90.04.01], message 181,00) — an off-by-one against 2^15−1 = 32767; see the §8.5 catalog.
- In comparisons (relevant inside TR): "ZERO may be compared to either numeric or alphameric fields. HIGH.VALUE, LOW.VALUE and BLANK may be compared to alphameric fields only" ([J 02.04.01]).

#### 4.7.5 Other MOVE facts and limits

- Multiple receiving areas are permitted; the sending area is unchanged, so a value may be distributed to several areas in one command ([F p. 42–43]).
- A record obtained by GET may be operated on by SET and MOVE; MOVE operations on a record are "based upon the 80 characters specified in the Data Description of the record rather than the 84 characters appearing on tape" for the card-image case discussed there ([J 02.07.14]; record/file interaction is covered in the input/output section).
- Records whose fields are referenced only infrequently "in arithmetic, MOVE, or indexing operations" may be processed in locate mode; "In general, a record should be transmitted if the number of words in the record is less than three times the total number of arithmetic and MOVE references to fields of the record" ([J 02.07.05]; see the input/output section for locate/transmit mode).
- MOVE to/from subscripted operands is legal (e.g. `MOVE RATE (DESTINATION) TO LIST.A`, `MOVE ONE.WAY (MIAMI) TO BILL.AMOUNT`, [F p. 30]); subscript-order caveats of §4.3.4 apply.

### 4.8 The MOVE CORRESPONDING command and CORRESPONDING matching rules

General form:

```
MOVE CORRESPONDING data.name.1 TO data.name.2, data.name.3,
    ... data.name.n
```

([F p. 43]). "This command can be thought of as a series of MOVE commands, each of which is governed by the rules for MOVE. It is assumed, however, that each 'data.name' represents an area of storage which is subdivided into smaller areas such as fields. The effect of MOVE CORRESPONDING is to move each field for which a corresponding field (i.e., a field having the same name) exists in the receiving area(s). The order of the corresponding fields need not be the same in the sending and the receiving areas" ([F p. 43]). "Non-corresponding fields in the sending area are *not* moved. Non-corresponding fields in the receiving area remain unaltered" ([F p. 43]).

**Editing feature:** "Automatic editing of data to conform to the format of the receiving areas is done in essentially the same manner as in the MOVE command. Such editing, however, operates on subdivisions, or fields, of the data specified in the command. Accordingly, in order for editing to occur, the corresponding fields or smaller units must have explicit format definitions in the data description" ([F p. 43]).

#### 4.8.1 Matching rules (J, definitive)

"Correspondence is determined at the lowest possible level on the basis of name only. All qualifiers must be present and identical through the level of the name itself to meet the criteria of correspondence. Note, however, that the resultant MOVE or ADD may be affected since the rules governing these commands are the same whether or not the CORRESPONDING option is exercised" ([J 02.04.04]). The three worked cases, for `MOVE CORRESPONDING DATA.1 to DATA.2.`:

a) Absolute level numbers are irrelevant — only the name hierarchy matters:

```
DATA.1          01      DATA.2          04
  GROUP         02        GROUP         05
    ITEM        03          ITEM        06
      FIELD.1   04            FIELD.1   08
      FIELD.2   04            FIELD.2   08
```

"correspondence would be found at FIELD.1 and FIELD.2 level, and instructions would be generated to

```
MOVE DATA.1 GROUP ITEM FIELD.1 TO DATA.2 GROUP ITEM FIELD.1.
MOVE DATA.1 GROUP ITEM FIELD.2 TO DATA.2 GROUP ITEM FIELD.2.
```

" (J 02.04.04).

b) A missing intermediate qualifier defeats correspondence entirely:

```
DATA.1          01      DATA.2          01
  GROUP         02
    ITEM        03          ITEM        03
      FIELD.1   04            FIELD.1   04
      FIELD.2   04            FIELD.2   04
```

"no fields would be found to correspond due to the absence of the qualifier GROUP in DATA.2" ([J 02.04.04]).

c) Correspondence may be found at a group level; the group then moves as an (assumed-alphameric) unit, and the ordinary MOVE legality rules apply:

```
DATA.1          05      DATA.2          01
  GROUP         06        GROUP         02
    ITEM        07          ITEM        03
      FIELD.1   08
      FIELD.2   08
```

"correspondence would be determined at the ITEM level, and an attempt would be made to generate the instructions to `MOVE DATA.1 GROUP ITEM TO DATA.2 GROUP ITEM.` Since the field DATA.1 GROUP ITEM has sub-fields, it has no format characteristics of its own and is assumed to be alphameric. If DATA.2 GROUP ITEM is a field into which alphameric information may not be legally moved, an error will be noted" ([J 02.04.04]–02.04.05).

#### 4.8.2 Subscripting with CORRESPONDING

"Data items referenced in a MOVE or ADD CORRESPONDING clause may be subscripted. The compiler simply appends the designated subscript to the generated instructions." For example a) above, `MOVE CORRESPONDING DATA.1 TO DATA.2 (I)` (with appropriate quantity values in the Data Description) generates

```
MOVE DATA.1 GROUP ITEM FIELD.1 TO DATA.2 GROUP ITEM FIELD.1(I)
MOVE DATA.1 GROUP ITEM FIELD.2 TO DATA.2 GROUP ITEM FIELD.2(I)
```

([J 02.04.05]).

### 4.9 Functions in arithmetic and data-manipulation statements

#### 4.9.1 The F (1960) function mechanism

"The term *function* is used in the Commercial Translator to mean a *result* obtained as a consequence of some procedure. More precisely, it means a result obtained from a procedure specified by a BEGIN SECTION command, and, in particular, it is a result named in the GIVING clause of that command" ([F p. 32]). The data named in the USING clause are *parameters* ([F p. 32]). Full mechanics of BEGIN SECTION USING ... GIVING and DO ... USING ... GIVING (data substitution by positional order, values moved into parameter fields before execution and out of function fields after) belong to the control-statements section ([F p. 32–33], p. 52–53, p. 57–58).

On the statement side, a function-name may be written **directly in a procedure statement** in place of a DO: "the programmer may write the name of a function directly in a procedure statement, together with the names of the data items to be substituted for the parameters, and the system will carry out the BEGIN SECTION procedure just as if the DO command had been written. In order to achieve this result, the programmer must specify the data to be used by placing the data-names in double parentheses immediately after the function-name. These names must be separated by single commas" ([F p. 34]; rule restated as punctuation rule 15, [F p. 28]). When this form is used the result is obtainable only from the function field itself (no GIVING redirection) ([F p. 34]). Examples ([F p. 34]; the period after MARKET.PRICE in the first example is a printing inconsistency preserved from the source):

```
MOVE MINIMUM ((CALCULATED.PRICE, MARKET.PRICE.
    HIGH.VALUES)) TO PRICE.LIST.
SET SHIPPING.COST = MINIMUM ((RAIL.EXPRESS, AIR.FREIGHT,
    PARCEL.POST)) * QUANTITY.
SET RATE.FACTOR = MINIMUM ((FLAT.RATE, QUANTITY.RATE,
    HIGH.VALUES)) * 1.15.
```

In arithmetic expressions "a function-name is treated as a quantity, as in the fifth of the preceding examples of the SET command, where the square root of X is multiplied by 2 and truncated to obtain the result ... Function-names ... imply an evaluation process at object time. The evaluation is carried out by procedural statements identified by a BEGIN SECTION command ... These procedure statements deliver a value to be used in computing the value of the arithmetic expression" ([F p. 46]). ADD's data.name may likewise be the name of a function ([F p. 47]).

**There is no built-in function library.** Neither manual defines any predefined function; MINIMUM and SQUARE.ROOT appear only as programmer-written examples ([F p. 32–34], p. 44). The only built-in value-producing operators are ABS and TR ([F p. 21], p. 45). The library mechanism that might have supplied stock routines (INCLUDE) is deferred: "Mechanization of the INCLUDE verb has been deferred, and consequently no library facilities are currently available" ([J 90.01.02]).

Declaration side (1960): "All function-names and all parameter-names used in the program must be written in the data description ... they must be identified by the type codes FUNCT or PARAM, as appropriate" ([F p. 34]; type-code definitions [F p. 73]; see §3).

#### 4.9.2 F/J divergence: PARAM and FUNCT type codes withdrawn

**F/J divergence:** "These two type codes [PARAM and FUNCT] described in the General Information Manual are no longer in the language" ([J 02.05.03]). The function *machinery* itself nevertheless survives in the 1962 processor: the compiler's error-message file includes "FUNCTION 'NAME.1' LACKS EXPLICIT SPECIFICATION OF ALL ARGUMENTS." (30,00), "EVALUATION IGNORED FOR FUNCTION 'NAME.1'. TOO MANY ARGUMENTS SPECIFIED." (68,00), and TOO MANY/TOO FEW -USING-/-GIVING- PARAMETERS IN -DO- STATEMENT (72,00–75,00) ([J 90.04.01]); USING and GIVING remain reserved words ([J 02.03.02]). The most plausible reading is that in J, parameters and functions are declared as ordinary data description entries (no special type code), while the reference forms — function-name with double-parenthesized arguments, DO/BEGIN SECTION with USING/GIVING — are unchanged; see the §8.5 catalog. Message 30,00 additionally implies that a J function reference must specify **all** arguments explicitly.

### 4.10 Restrictions and limits affecting this section (consolidated)

| Restriction / limit | Value / rule | Citation |
|---|---|---|
| Literal length (all literals) | ≤ 50 characters, complete on one line | ([F p. 18]; alphameric literal limit reconfirmed for DISPLAY, [J 02.04.02.01]) |
| Literal operated on arithmetically | ≤ 20 digits | ([F p. 18]) |
| Scientific decimal fractional portion | ≤ 16 digits | ([J 02.05.05], note 4) |
| Fixed point double precision threshold | pictorial representing more than 10 digits | ([J 02.05.06]) |
| Maximum Quantity (array repetition) | 2¹⁵ − 1; no execute-time check | ([J 02.05.04]) |
| Figurative constant target length | ≤ 2¹⁵ − 1 characters (diagnostic text says "longer than 32766") | ([J 02.04.01]; [J 90.04.01] message 181,00) |
| Figurative constant → variable length array | Illegal (element reference legal) | ([J 02.04.01]; [J 90.01.02]) |
| Different edited field formats per program | approx. max 35 | ([J 90.01.05]) |
| Generated constants in constant pool | approx. max 500 | ([J 90.01.05]) |
| Index expressions (`a * VARIABLE ± b`) | approx. max 50 | ([J 90.01.05]) |
| Positional indicators (unique array+subscript combinations) | approx. max 90 | ([J 90.01.05]) |
| ON OVERFLOW | only with a single result field (SET and ADD) | ([F p. 44], p. 47) |
| Alphameric operand in arithmetic expression | illegal (TR contexts excepted); alphameric result field legal | ([J 02.04.05]; [F p. 45]) |
| Alphameric source field | may move only to alphameric | ([F p. 42]; [J 02.04.03]) |
| Constants in edited fields | cannot be defined | ([J 02.05.06]) |
| Mixed A and 9 pictorial | illegal; treated as alphameric | ([J 90.01.03]) |
| Array dimensions | must be set before subscript values are calculated, else invalid object code | ([J 90.01.02]) |
| Subscript bounds | no object-time check | ([J 90.01.02]) |
| Condition-name | may not be subscripted (conditional variable may be) | ([J 90.01.03]) |
| A**B**C | must be parenthesized | ([F p. 107]) |
| Two successive operators | illegal unless second is TR or ABS | ([F p. 27]) |

### 4.11 Cross-references

- Field types, pictorials, modes (I/E), justification, COND/RECORD/REDEF/QUANTITY IN, constants: §3 (Data description and storage model) ([J 02.05]; F Ch. 4).
- Conditional expressions, relational operators, AND/OR/NOT, comparison-mode rules that also govern TR operands: conditional-statements section ([F p. 21–24]; [J 02.04.06]–07).
- DO ... USING ... GIVING, BEGIN SECTION, indexing loops (which interact with SET-driven subscript updates): control-statements section ([F p. 49–53], p. 56–58).
- GET/FILE record availability for MOVE/SET, locate vs transmit mode: input/output section ([J 02.07]).
- Reserved words that block use of SET/ADD/MOVE/CORRESPONDING/TRUNCATED/OVERFLOW/TR/ABS etc. as names: reserved-words section ([J 02.03.02]; [F p. 110]).
- Generated-code and object-time subroutine details (MOVPAK, scaling, exponential routines): J Appendix 90.02 (cited above only where they settle semantics).

---

## 5. Control-flow statements

COMTRAN control flow is built from four elements: the default sequential execution of sentences; the conditional sentence (IF ... THEN ... OTHERWISE); the three control commands GO TO, DO, and STOP ([F p. 48]); and the sectioning apparatus (BEGIN SECTION / END) that creates the named units to which control can be transferred ([F pp. 56–57]). This section covers all of these, together with the conditional expressions (relations, condition-names, AND/OR/NOT, truth functions) that drive the conditional constructs, and the J-processor's comparison semantics, restrictions, and limits.

Throughout: F = F28-8043 (June 1960 General Information Manual, the language vision); J = J28-6169-1 (Jan 1962 709/7090 Processor manual, authoritative for the implemented language).

### 5.1 Default sequential flow and sentence boundaries

- "During the execution of the object program the procedure is normally executed in the order in which it appears in the source program. The control commands are used primarily to specify a departure from this sequence" ([F p. 48]).
- The basic complete unit of meaning is the *sentence*; sentences are composed of *clauses*, of which there are two kinds: imperative and conditional ([F p. 24]).
- An **imperative clause** "always begins with a verb and may contain one or more operands"; operands may include data-names, procedure-names, condition-names, literals, figurative constants, and arithmetic expressions ([F p. 25]).
- A **sentence** "must contain at least one imperative clause and may contain, in addition, one conditional clause and one or more additional imperative clauses. It is terminated by a period, which must be followed by a blank ... Imperative clauses within the same sentence must be separated by commas" ([F p. 25]). Blanks may be used in addition to the comma but are ignored ([F p. 27], rule 5).
- Period-blank termination: "Each sentence must be terminated by a period, followed by a blank. Should the blank be omitted, the period will be treated as an 'imbedded period,' except where the period is found in Column 72 of the procedure description form" ([F p. 27], rule 3). A blank is assumed to follow column 72 of the procedure form ([F p. 28], rule 14).
- **J commentary rule:** "Procedure statements are terminated by the first period (.) followed by a blank. Any information following this period blank is considered to be commentary" ([J 02.03.01]). Also: "A period (.) followed by a blank in a procedure statement terminates analysis of the statement except when they appear within an alphabetic literal; any information in the same card which follows the period is assumed to be commentary. No diagnostic comment is made" ([J 90.01.03]). Procedure.names not followed by a period and blank "are handled properly; no diagnostic message is given" ([J 90.01.03]).
- Each clause has exactly one verb: the compiler deletes a "STATEMENT WITHOUT PROPER VERB" and a "STATEMENT WITH MORE THAN ONE VERB" from the text ([J 90.04.01], messages 125,00 and 126,00).
- The compiler assigns statement numbers of the form `xxxxx,yy` — the digits before the comma identify the line (sentence), the two after the comma identify the *clause* within it ([J 02.02.01]). Statement number 9999,99 references errors not confined to a single statement ([J 02.02.01]).
- **Per-sentence capacity limits (J):** "NUMBER OF OPERATORS IN THIS SENTENCE EXCEEDS MAXIMUM OF 60. SENTENCE DELETED FROM TEXT." (message 171,00); "THIS SENTENCE EXCEEDS INTERNAL TABLE CAPACITY. SENTENCE DELETED FROM TEXT." (177,00); "CONDITIONAL EXPRESSION TEST CAPACITY EXCEEDED. REWRITE AS TWO OR MORE SEPARATE EXPRESSIONS..." (187,00) (all [J 90.04.01]).
- **Continuity checks (J):** the compiler diagnoses program flow that runs off the end of a division or into non-executable material: "PROBABLE PROGRAM CONTINUITY ERROR. PROGRAM FLOWS INTO \*DATA." (87,00); "... PROGRAM FLOWS INTO GENERATED CONSTANTS." (169,00); "... PROGRAM FLOWS INTO STATEMENT OR SECTION 'NAME.1' ADDRESSED BY A -DO-." (99,00) ([J 90.04.01]). The last is the compiled form of the closed-subroutine rule (§5.5.5).
- **Program entry point (J):** error messages reveal a reserved name -PROGRAM.START-: "MORE THAN ONE -PROGRAM.START-. FIRST USED." (141,00); "-PROGRAM.START- MUST BE A STATEMENT OR SECTION NAME." (142,00); "-PROGRAM.START- CANNOT BE A STATEMENT OR SECTION NAME ADDRESSED BY A -DO-." (143,00) ([J 90.04.01]); Appendix 90.02 refers in passing to "the first word of the object program (not necessarily PROGRAM.START)" ([J 90.02.01]). Nowhere in either manual is PROGRAM.START formally defined; the Loader "will normally use the starting point of the first program of combined segments as the starting point for the combined deck", modifiable by a \*START card ([J 03.02.08]). See the ambiguities register.
- Physical placement of procedure text (needed because control transfers target names written in the name margin): procedure-names go in columns 7–12 ("name margin"), text in columns 13–72; a named sentence follows its name on the same line; an unnamed sentence must begin on a separate line to the right of the name margin; succeeding lines of a sentence begin right of the name margin; only BEGIN SECTION may appear on the same line as a section name; "END section.name" is written as a sentence on a separate line ([F p. 37]). Procedure-names may contain up to thirty characters and "must be followed by a period and a blank" ([F p. 37]). Serial numbers in columns 1–6 are *not* sequence checked by the J compiler ([J 02.03.01]) — F said they would be sequence-checked ([F p. 37]); **F/J divergence**.

### 5.2 The conditional statement (IF ... THEN ... OTHERWISE)

Neither manual gives a boxed "general form" for the conditional statement (it is not a verb command); its shape is defined by prose rules in F Chapter 2:

- A **conditional clause** "consists of a conditional expression introduced by the word IF and terminated by the word THEN. The conditional expression may be simple or compound. The word IF is an operator ... The word THEN defines the limit of the conditional expression to be tested; it will always be followed by an imperative clause" ([F p. 25]).

```
IF OUT.OF.ZONE THEN
IF AMOUNT GT 200 THEN
IF MARRIED AND OVER.21 THEN
IF A = B OR A = C AND A GT D THEN
```
([F p. 25] — examples of conditional clauses)

- Placement and scope: "When a conditional clause is used in a sentence, it must begin the sentence, and it must be followed by one or more imperative clauses to be executed if the prescribed condition is met. If the programmer wishes to prescribe alternative action to be taken if the conditional expression proves false, he may specify it by writing next (without intervening punctuation) the word OTHERWISE, followed by one or more imperative clauses. If the conditional expression should prove false, and if the sentence does not contain the word OTHERWISE, the conditional sentence will cause no action and the system will proceed to the next sentence in the program" ([F p. 25]). Likewise: "if OTHERWISE is absent the program continues with the succeeding sentence" ([F p. 7]).

```
IF MARRIED THEN MOVE NAME TO MAILING.LIST.M,
    ADD 1 TO COUNTER.
IF GROSS.PAY LT NET.PAY THEN GO TO ERROR.ROUTINE.
IF OUT.OF.ZONE THEN DO BILLING.ROUTINE.A OTHERWISE
    DO BILLING.ROUTINE.B.
```
([F p. 25] — example sentences)

Consequences a compiler writer must observe:

- **At most one conditional clause per sentence** and it must be the first clause ([F p. 25]). There is no nested IF, no ELSE-IF chain, and no multi-sentence conditional scope: both the THEN arm (all comma-separated imperative clauses up to OTHERWISE or the terminating period) and the OTHERWISE arm (all clauses from OTHERWISE to the period) end at the sentence period, and both arms rejoin at the next sentence (F pp. 7, 25).
- OTHERWISE may not begin a sentence: "SENTENCE CANNOT START WITH -OTHERWISE-" ([J 90.04.01], message 208,00).
- Sentence-structure violations are diagnosed and the statement dropped: "ILLEGAL SENTENCE STRUCTURE NOTHING DONE." (196,00); "SENTENCE STRUCTURE ERROR. POSSIBLE ILLEGAL USE OF A KEY WORD." (192,00); and the recovery message "-WHEN- SUBSTITUTED FOR -IF- BECAUSE OF IMPROPER USE." (170,00) (all [J 90.04.01]). The last implies the compiler repairs an IF written where the conditional-GO TO's WHEN belongs (see ambiguities).
- Multi-clause arms in real code (J sample program): `IF MASTER FICA GT 144.00 THEN SET WORKING FICA = WORKING FICA - (MASTER FICA - 144.00), SET MASTER FICA = 144.00.` and `IF M.EMP.NO = HIGH.VALUE THEN GO TO END.OF.RUN OTHERWISE SET D.EMP.NO = HIGH.VALUE, GO TO HIGH.DETAIL.` ([J 90.05], listing PDF p. 196).
- Program commands and processor commands cannot be intermixed in a sentence; e.g. `IF A = B THEN GO TO C OTHERWISE OVERLAP SECTION.1, SECTION.2.` is meaningless ([F p. 60]). Processor commands (except BEGIN SECTION and END) should be written as unnamed sentences, which "makes it impossible for a program command to transfer control to a processor command" ([F p. 60]).
- Testing vs. setting: "Testing the value provides a basis for a decision but does not change the value; the testing is accomplished by using a conditional clause, IF . . . THEN. Setting a value of a conditional variable ... is effected by means of the SET command" ([F p. 46]); see §5.4.4.

### 5.3 Conditional expressions

A conditional expression "may be either true or false, depending on conditions existing when the expression is examined"; it may contain data-names, condition-names, arithmetic expressions, and relational expressions, and expressions may be joined by AND and OR into compound conditional expressions ([F p. 21]). The two principal types are (1) relations and (2) condition-names ([F p. 21]).

Conditional expressions appear in exactly these control contexts: the IF clause ([F p. 25]), the WHEN clauses of the conditional GO TO ([F p. 48]), and inside truth functions TR( ) in arithmetic expressions (F pp. 20, 24; see §5.3.5). SET's ON OVERFLOW and GET's AT END phrases are *not* conditional expressions but appended event clauses (F pp. 40, 44; see the SET/arithmetic and Input/Output sections).

#### 5.3.1 Relations

"Six basic relational expressions may be used in conditional expressions, each of which may be written in a full form or in an abbreviated form" ([F p. 21]):

| Relational expression | Abbreviated form |
|---|---|
| IS GREATER THAN | GT |
| IS NOT GREATER THAN | NOT GT |
| IS EQUAL TO | = |
| IS NOT EQUAL TO | NOT = |
| IS LESS THAN | LT |
| IS NOT LESS THAN | NOT LT |

([F p. 21])

- Relations "may be used to connect data-names, literals, and arithmetic expressions" ([F p. 21]). Examples ([F p. 21]): `BEGINNING.ON.HAND + RECEIPTS - SHIPMENTS IS LESS THAN REORDER.POINT`, `AGE GT 21`, `A * (B + C) - (D / E) = 500`, `DEPENDENTS NOT = 0`, `A GT B OR A = C`.
- There is no "greater than or equal" / "less than or equal" spelling; those are expressed as NOT LT / NOT GT ([F p. 21]). Note [F p. 2]'s admonition on precision: "We must not say 'less than 30' if we mean 'less than or equal to 30.'"
- Each relational expression must be completely stated — `HOURLY.RATE IS GREATER THAN 3.50 AND LESS THAN 5.00` is not accepted; both operands must be repeated ([F p. 23], rule 3).
- Reserved-word inventory relevant to relations: F Appendix 2 lists IS, GREATER, LESS, THAN, EQUAL, GT, LT, NOT ([F p. 110]). J's key-word list additionally reserves **EQUALS** ([J 02.03.02]) although no manual documents an "EQUALS" relational form — see open questions. The sample program uses `IS NOT EQUAL TO`, `NOT GT`, `GT`, `LT`, and `=` ([J 90.05], listing PDF pp. 195–197).

#### 5.3.2 Comparison semantics (J 02.04.C — authoritative)

[J 02.04.06]–02.04.07, "C. Conditional Statements", gives the implemented comparison rules:

1. "Comparisons may not be made between numeric and alphameric fields." Given ABC alphameric (AAA) and DEF numeric (999), `IF ABC = DEF THEN ---` is an invalid comparison; "The implied or explicit specification of DEF as an external decimal field does not affect the validity of the comparison" ([J 02.04.06]).
2. **Fields of unequal length** ([J 02.04.07]):
   - a) "Numeric fields are compared arithmetically without regard to length."
   - b) Alphameric fields of unequal length are treated on the basis of the operator:
     - i. "In tests for an = or NOT = condition the fields will always be found to be unequal." For unequal-length alphameric A and B, given `IF A = B THEN GO TO C OTHERWISE GO TO D.` "the only code generated will be a transfer to D"; for `IF A NOT = B THEN GO TO D OTHERWISE GO TO C.` likewise ([J 02.04.07]). I.e. the compiler folds the comparison at compile time.
     - ii. "In tests for NOT greater or less conditions the lengths are made equal by right truncation of the longer field" ([J 02.04.07]). (On the reading of this phrase see the ambiguities register; the plausible sense is: for the relative-magnitude operators — GT, LT, NOT GT, NOT LT — as opposed to =/NOT =.)
3. "For purposes of comparison edited fields (see 02.05 for definition) are converted to pure numeric fields. They may not be compared to alphameric fields" ([J 02.04.07]).
4. "All non-format fields (see 02.05 for definition) are compared alphamerically, subject to rules stated in 2b above" ([J 02.04.07]). (A field with no pictorial is treated as alphameric with length equal to its subfields, [J 02.05.06]; group items in a MOVE/ADD CORRESPONDING are likewise assumed alphameric, [J 02.04.05].)
5. "Variable length fields may not be compared. (A variable length field is a field which uses the QUANTITY IN option)" ([J 02.04.07]); enforced by "CANNOT USE VARIABLE LENGTH ITEMS FOR COMPARISON." ([J 90.04.01], message 123,00).
6. "For comparison purposes zero is considered an unsigned number, even though computational sequences generated by the compiler may produce negative or positive zeros" ([J 02.04.07]).
7. Structural errors are reported as "ILLEGAL COMPARISON STRUCTURE." ([J 90.04.01], message 107,00).

**Figurative constants in comparisons** ([J 02.04.01]): "ZERO may be compared to either numeric or alphameric fields. HIGH.VALUE, LOW.VALUE and BLANK may be compared to alphameric fields only."

**Collating sequence.** The compiler "normally generates comparison type instructions based on the 709/7090 collating sequence"; the Environment OPTION card `COLLATE COM` selects the Commercial (705) collating sequence instead, optionally limited to one section by `IN section.name` (reverting to normal at the end of that section; the modes may be altered any number of times) ([J 02.06.16]–02.06.17). The OPTION card general form:

```
Name   Type     Description

       OPTION   [COLLATE COM]                 [IN section.name]

                [, CONSERVE {SPACE}]           [IN section.name]
                            {TIME }
```
([J 02.06.16])

The 709/7090 sequence runs (lowest to highest) `0 through 9 = ' + A–I ⟨+0⟩ . ) − J–R ⟨−0⟩ $ * blank / S–Z ⟨rm⟩ , (` — digits lowest, `(` highest — and the Commercial (705) sequence runs from `Blank` (lowest) through the specials and letters to `0 through 9` (highest) ([J 02.06.16]; scan-resolved reading — full displays and glyph legend in §1.1). Note the operational consequence: under the native 709/7090 sequence *digits collate low and letters high*; under COM, blank collates lowest and digits highest.

Consistently, the figurative-constant extremes depend on the sequence chosen: "HIGH.VALUE will be considered to be the left parenthesis, (, and LOW.VALUE the zero, 0, unless the Commercial collating sequence (COM) is specified in the Environment Description. The Commercial HIGH.VALUE is 9 and the LOW.VALUE is blank" ([J 02.04.01]). F defines LOW.VALUE/HIGH.VALUE only abstractly as "the lowest and highest characters in the collating sequence of the system for which the program is written" ([F p. 20]).

Object code: alphabetic comparison of two fields is performed by generated subroutine SYS)162, using conversion table SYS)161; "OP is a CVR or NOP depending of the need to adjust the collating sequence before the comparison" ([J 90.02.12] — "depending of" is the original's typo).

**F/J divergence:** F never restricts comparisons by type or length ([F pp. 21–24] are silent); all of the above type/length/collating machinery is J's implemented tightening and must be treated as the language definition.

#### 5.3.3 Condition-name tests

- A condition-name "defines a condition which can be used to control an operation" ([F p. 14]) and "actually serves as an abbreviation of a relational expression": MARRIED defined for the conditional variable MARITAL.STATUS with value 'M' is "exactly equivalent to MARITAL.STATUS = 'M' and it may be substituted for it wherever the programmer wishes" ([F p. 22]); `IF MARRIED THEN DO TABULATION.ROUTINE.A` ≡ `IF MARITAL.STATUS = 'M' THEN DO TABULATION.ROUTINE.A` ([F p. 22]). "The condition-name itself is a conditional expression in the full meaning of that term" ([F p. 22]).
- Condition-names are declared in the Data Description with type code COND, immediately following the conditional variable's entry, at a lower level (higher level number), one entry per value ([F pp. 71–72]; see §3, Data description and storage model). If the programmer confines himself to full relational forms he need not declare condition-names at all ([F p. 72]).
- **J test semantics:** "Data Description condition.names are tested ... for absolute equivalence to the specified value" ([J 02.06.17]). The COND type entries "must be preceded by a higher level entry defining the format of the fields and must all have the same level number and include the COND type code" ([J 02.05.02]). A conditional variable has format restrictions ("FORMAT ERROR FOR CONDITIONAL VARIABLE", [J 90.04.01] message 37,00) and "CONDITIONAL VARIABLE CANNOT HAVE -QUANTITY-." (38,00).
- **Subscripting:** "Neither a data item (literal) nor a condition.name may be subscripted. However, a conditional variable may be subscripted" ([J 90.01.03]). Condition-names may not be used *in* subscripts ([F p. 31]).
- **Console-key conditions (J only):** an Environment COND card defines a condition-name over the 36 console entry keys:

```
Name             Type    Description

condition.name   COND    KEYS 'nn'
```
([J 02.06.17])

'nn' is 12 octal digits giving "on" settings; "When the condition.name is tested in a procedure statement only the keys specified in 'nn' are tested for 'on' setting. The specified console keys must all be 'on' for the condition to be true. No 'off' or 'on' test is made for the non-specified keys" ([J 02.06.17]). This gives the object program an operator-controlled switch testable by IF — a facility absent from F. **F/J divergence.**

#### 5.3.4 AND, OR, and NOT — combination rules and precedence

Compound conditions are formed with AND and OR, with parentheses where needed; "The negative form of a conditional expression may also be used; this is obtained by placing the word NOT before the expression" ([F p. 23]). The four interpretation rules ([F p. 23]):

1. OR is inclusive — "either or both".
2. AND means "both"; both conditions must be true.
3. Each conditional expression must be completely stated (no elliptical second operand).
4. "When a compound conditional expression contains both the word OR and the word AND, it will be interpreted as if the terms connected by AND were enclosed in parentheses. ... If a contrary sense is intended, parentheses must be used to show it."

Thus AND binds tighter than OR: "The conditional expression 'C1 OR C2 AND C3' is identical with 'C1 OR (C2 AND C3)' but is not the same as '(C1 OR C2) AND C3.' ... conditional expressions are grouped first according to AND and subsequently by OR. However, the programmer's use of parentheses will affect the order of grouping" ([F p. 105], rule 3).

Truth-table statement of the operators ([F p. 105], rule 1):

| The Conditional Expression | Is True If |
|---|---|
| C1 | C1 is true |
| NOT C1 | C1 is false |
| C1 AND C2 | Both C1 and C2 are true |
| C1 OR C2 | Either C1 is true, C2 is true, or both are true |
| NOT (C1 AND C2) | C1 is false, C2 is false, or both are false |
| NOT (C1 OR C2) | C1 and C2 are both false |

Closure rule: if C1, C2 are conditional expressions then so are "C1 AND C2", "C1 OR C2" and NOT-forms, reducible by successive substitution, e.g. `C1 AND (C2 OR NOT (C3 OR C4))` ([F p. 105], rule 2).

Legal symbol pairs (1 = permissible, 0 = not) ([F p. 106], rule 4):

| First Symbol \ Second | C | OR | AND | NOT | ( | ) |
|---|---|---|---|---|---|---|
| C | 0 | 1 | 1 | 0 | 0 | 1 |
| OR | 1 | 0 | 0 | 1 | 1 | 0 |
| AND | 1 | 0 | 0 | 1 | 1 | 0 |
| NOT | 1 | 0 | 0 | 0 | 1 | 0 |
| ( | 1 | 0 | 0 | 1 | 1 | 0 |
| ) | 0 | 1 | 1 | 0 | 0 | 1 |

"Thus, the pair 'OR NOT' is permissible, while 'NOT OR' is not permissible" ([F p. 106]). Note in particular: NOT NOT is not permissible; NOT may be followed by a condition or by "(" but not by another NOT. NOT before a relation is built into the relation spellings themselves (NOT GT, NOT =, NOT LT) ([F p. 21]), and NOT before a condition-name or parenthesized compound negates it (F pp. 23, 105). Parentheses "may be used wherever needed ... in compound conditional expressions for the sake of clarity; where ambiguity would result from their omission, they *must* be used" ([F p. 28], rule 11).

Worked interpretations of mixed AND/OR expressions are tabulated at [F pp. 23–24] (e.g. `MARRIED OR OVER.21 AND HOURLY.RATE IS GREATER THAN 3.50` = MARRIED, or the AND-pair, or both; the parenthesized variant regroups it).

J adds no separate AND/OR/NOT rules; its only related capacity note is message 187,00 (conditional expression test capacity; rewrite as two or more expressions) and the 60-operator sentence limit (171,00) ([J 90.04.01]).

#### 5.3.5 Truth functions (TR)

- "A conditional expression enclosed in parentheses preceded by the truth operator TR is known as a truth function. A truth function always has one of two values, 1 or 0, depending on whether the conditional expression is true or false" ([F p. 45]); it "can be manipulated arithmetically in the same manner as any other quantity" ([F pp. 45–46]).
- The conditional expression is placed in parentheses with TR immediately in front ([F p. 24]). Example ([F p. 24]):

```
SET DISCOUNT = ORDER.AMOUNT * .05 * TR
    (ORDER.AMOUNT IS GREATER THAN 1000).
```

- "The truth operator may be used with relational expressions ... or with condition-names" ([F p. 24]). TR is a unary arithmetic operator alongside ABS and negation; a unary operator's expression operand must be parenthesized ([F p. 45]). Two successive arithmetic operators are illegal unless the second is TR or ABS ([F p. 27], rule 6).
- Alphameric variables and constants may appear in arithmetic expressions *only* within truth functions ([F p. 45]) — i.e. TR( ) is the one bridge from alphameric comparison into arithmetic.
- **Precedence (J):** in the absence of parentheses, operators are honored in the order `TR or ABS or - (Negation)`, then `**`, then `* or /`, then `+ or -`; equal-precedence operators associate left to right ([J 02.04.05.01]). This makes TR bind most tightly — but since its operand is always parenthesized the practical effect is on the product/power context around it.
- Object-time example in the field-test compiler: `SET WORKING WHT = WORKING WHT * TR(WORKING WHT GT 0)` ([J 90.05], listing PDF p. 196) — a max(x, 0) idiom.
- F also lists TR among "arithmetic operators" with meaning "Truth Value" ([F p. 21]) and demonstrates conditional expressions used inside arithmetic expressions solely via TR ([F p. 20]).

### 5.4 The GO TO command

"The GO TO command is used to specify transfer-type operations. It has three forms" ([F p. 48]).

Legal targets, all three forms: "The 'procedure.name' may be the name of either a sentence or a section in the procedural part of the source program" ([F p. 48]). J enforces this: "TRANSFER BYPASSED BECAUSE 'NAME.1' IS NOT A STATEMENT OR SECTION NAME." (127,00); "OPERATION IGNORED BECAUSE 'NAME.1' IS ILLEGAL TRANSFER ADDRESS." (26,00); and transfers into DO-addressed procedures are rejected: "TRANSFER BYPASSED BECAUSE 'NAME.1' IS A STATEMENT OR SECTION NAME ADDRESSED BY A -DO-." (128,00) (all [J 90.04.01]). Since processor commands (other than BEGIN SECTION/END) are unnamed, control cannot be transferred to them ([F p. 60]).

#### 5.4.1 Unconditional GO TO

```
GO TO procedure.name
```
([F p. 48])

"It provides a transfer of control, or branching, to the item of procedure named in the command" ([F p. 48]). Examples: `GO TO MAIN.ROUTINE.`, `GO TO CALC.ORDER.POINT.` ([F p. 48]). An unconditional GO TO placed immediately after a STOP yields a "dead-end" halt ([F p. 54]; §5.6). All overlapped procedures should end with an unconditional GO TO ([F p. 56] — LOAD/OVERLAP deferred in J, see §5.7).

#### 5.4.2 Conditional GO TO (WHEN)

"essentially a multiple branch or switching point" ([F p. 48]):

```
GO TO procedure.name.1 WHEN conditional expression 1,
     procedure.name.2 WHEN conditional expression 2, ...
     procedure.name.n WHEN conditional expression n
```
([F p. 48])

Semantics: "each conditional expression is evaluated in turn until one is found to be true. Thereupon, control is transferred to the 'procedure.name' associated with that conditional expression. Any remaining conditional expressions are left unevaluated. If none of the conditional expressions in the command is found to be true, control passes to the next clause or sentence in sequence" ([F p. 48]). I.e. first-match wins, evaluation is short-circuited, and no-match falls through.

```
GO TO ERROR.RTN WHEN DETAIL IS LESS THAN MASTER,
     PROCESSING WHEN DETAIL IS EQUAL TO MASTER,
     NO.ACTIVITY WHEN DETAIL IS GREATER THAN MASTER.
```
([F p. 48])

WHEN is one of the words "always interpreted as Key words" and may never be a programmer name ([J 02.03.02]). Real usage with fall-through ([J 90.05], listing PDF p. 195):

```
COMPARE.EMPLOYEE.NUMBERS.  GO TO CHECK.NEW.DEPT WHEN D.EMP.NO =
                            M.EMP.NO,  LOW.DETAIL WHEN D.EMP.NO LT M.EMP.NO.
HIGH.DETAIL.    ...
```
— when neither WHEN condition holds, control falls into the next sentence (HIGH.DETAIL).

#### 5.4.3 Assigned GO TO (ON index)

"also serves as a multiple branch point ... the transfer of control depends upon the prior setting of an index rather than on the truth or falsity of conditional expressions. The setting of the index may have occurred in one of two ways: 1. Through bringing the index into storage as a constant or file variable. 2. As a result of computation involving the index" ([F pp. 48–49]).

```
GO TO ( procedure.1, procedure.2, ... procedure.n ) ON index.name
```
([F p. 49])

- "A transfer of control will be made according to the value of the index at the time the GO TO is executed. If the value of the index is 1, control will pass to the first sentence or section of procedure named in the command; if 2, the second item named; and so on" ([F p. 49]).
- Range rule: "The functioning of the assigned GO TO command assumes that the value of the index will always be an integer in the range 1 to n. If the index has any other value, no transfer will occur; instead, control will pass to the next clause or sentence in sequence" ([F p. 49]).
- "Note that the parentheses shown in both the general form and the example are a fixed part of the command and must always be included" ([F p. 49]). ON is an always-reserved key word ([J 02.03.02]).

```
GO TO (PIECE.WORK, INCENTIVE, HOURLY.RATE, SALARY) ON
     PAY.TYPE.
```
([F p. 49] — PAY.TYPE is a field in each employee record containing 1, 2, 3, or 4)

- **How the "switch" is set:** there is no special assign-verb; the index is an ordinary integer data field set by input data, by MOVE, or by SET arithmetic ([F pp. 48–49]). (SET condition.name — §5.4.4 — changes a *conditional variable*, which is the switch mechanism for IF-type tests, not for the assigned GO TO.)
- **J diagnostics for the index:** "FORMAT ERROR FOR TRANSFER INDEX. NOTHING DONE." (129,00) and "TRANSFER INDEX NOT AN INTEGER. INTEGRAL PART TAKEN AS VALUE." (130,00) ([J 90.04.01]). J is silent on whether an object-time range check (the F fall-through rule) is actually generated — see open questions.

#### 5.4.4 SET condition.name (switch setting for conditional tests)

For completeness of the "switch" picture (full SET coverage belongs with arithmetic/assignment):

```
SET condition.name
```
([F p. 46])

"the variable with which 'condition.name' is associated (in the data description) is assigned the status, or value, of the specified condition" ([F p. 46]). `SET MARRIED.` ≡ `SET MARITAL.STATUS = 'M'.` ([F p. 46]). J's SET discussion ([J 02.04.05], "6. SET") covers only the arithmetic form and never re-states the condition-name form; nothing in [J 90.01] defers it, and conditional variables remain fully supported ([J 02.05.02]; [J 90.04.01] messages 37,00/38,00). Presume it implemented as per F (flagged in the ambiguities register).

### 5.5 The DO command

"The DO command provides a means of departing from the normal sequence of program steps in order to execute some procedure ... and then return to the original sequence. In other words, the DO is used to execute subroutines which, in the Commercial Translator system, are either named sentences or sections" ([F p. 49]). "The DO command may take one of several forms. In the simplest form ... the procedure is executed once each time the DO is encountered. Expanded forms of the command permit repetitive execution, or 'looping,' of the subroutine and control of subscripts. Data substitution, which is an optional feature, is also provided" ([F p. 49]).

Consolidated general forms ([F p. 108], Appendix 2 — brackets denote optional phrases):

```
DO procedure.name [EXACTLY n TIMES] [USING data.name.1, data.name.2, ..
    data.name.n] [GIVING result.name.1, result.name.2, ... result.name.n]

DO procedure.name FOR index.name.1 = p.1(q.1)r.1 [, index.name.2 =
    p.2(q.2)r.2, index.name.3 = p.3(q.3)r.3] [USING data.name.1, data.name.2,
    ... data.name.n] [GIVING result.name.1, result.name.2, ... result.name.n]
```

#### 5.5.1 Simple DO and DO ... EXACTLY n TIMES

```
DO procedure.name
DO procedure.name EXACTLY n TIMES
```
([F p. 49])

- "where 'procedure.name' represents the name of a sentence or section. (If a procedure consists of more than one sentence, it must be defined as a section in order to be named ...)" ([F p. 49]).
- First form: "the 'procedure.name' subroutine is executed only once and control passes to the sentence or clause following the DO" ([F p. 50]).
- Second form: "the 'procedure.name' procedure is executed the specified number of times. The number of repetitions, n, may be stated as a literal or as a data-name, but in either case the value of n must be a positive integer" ([F p. 50]). Example: `DO BOND.ORDER.RTN EXACTLY NO.OF.BONDS TIMES.` ([F p. 50]).
- **J at-least-once rule:** "A DO section will always be performed at least once regardless of the values of the loop control variables" ([J 90.01.02]). This applies to all repetitive forms (presumably even EXACTLY 0 TIMES — itself an invalid value per [F p. 50], which requires n to be a positive integer — would execute once; not stated). **F/J divergence** in the sense that F never states it.
- EXACTLY and TIMES are reserved ([J 02.03.02]; [F p. 110]).

#### 5.5.2 DO with indexing (FOR index = p(q)r)

```
DO procedure.name FOR index.name = p(q)r
```
([F p. 50])

- "'index.name' represents a field which has been defined in the data description as an integer" ([F p. 50]).
- Semantics, quoted in full because they are the precise loop contract ([F p. 50]): "The effect of this DO command (in the object program) is to set the index to the initial value p and transfer control to the first sentence of the named procedure. After the last sentence of the procedure has been reached and executed, control is returned to the DO command which increments the index by the quantity q and causes control to return to the 'loop.' This process is repeated until the value of the index equals r; at this point, control is no longer returned to the loop but instead passes to the sentence or clause which follows the DO."
- F gives the exact equivalence — the loop is test-after-body with an *equality* test:

```
        SET i = p.
START.  DO rtn.
        IF i = r THEN GO TO NEXT.
        ADD q TO i.
        GO TO START.
NEXT.   .
        .
        .
```
([F p. 51] — "the command, 'DO rtn FOR i = p(q)r' is the equivalent of" this expansion)

  Consequences: the body executes with i = p first and executes *for* i = r (termination is checked after the body); the index equals r on exit; the body always runs at least once (consistent with [J 90.01.02]); if the step never makes i exactly equal r the expansion never terminates (see ambiguities).
- "Each of the loop control parameters p, q and r may be either of the following: 1. A literal having an integer value. 2. The name of a field defined as an integer" ([F p. 51]).
- Example and subscript interaction ([F p. 51]): `DO RATE.UPDATE.CALC FOR STATE = 1(1)50.` with body `RATE.UPDATE.CALC.  SET RATE (STATE) = RATE (STATE) * ADJUST.FACTOR + FLAT.AMT.` — "the variable RATE is said to be subscripted by the index STATE". Field-test example: `DO SEARCH FOR INDEX = 1(1)12.` ([J 90.05], listing PDF p. 196).
- **Two indices** ([F p. 51]): "'index.name.1' and 'index.name.2' are initially set to p.1 and p.2 respectively. Each time the inner loop is executed, index.name.2 is incremented by q.2 until it equals r.2; thereupon, index.name.2 is reset to p.2 and index.name.1 is set to p.1 + q.1. Control is returned to the inner loop and the process is repeated. When index.name.1 is equal to r.1, control passes to the clause or sentence which follows the DO." (On the literal "set to p.1 + q.1" wording see the ambiguities register.)

```
DO procedure.name FOR index.name.1 = p.1(q.1)r.1, index.name.2 = p.2(q.2)r.2
```
([F p. 51])

- **Three indices maximum:** "A maximum of three indices may be controlled with the DO command. Again, the rightmost index is the one which varies most rapidly" ([F p. 51]). Example `DO COMPUTATION FOR HOURS = 1(1)12, MINUTES = 1(1)60, SECONDS = 1(1)60.` executes the subroutine 60x60x12 times ([F p. 51]).
- **J diagnostics:** "FORMAT ERROR FOR LOOP CONTROL VARIABLE 'NAME.1'." (76,00); "FORMAT ERROR FOR PARAMETER 'NAME.1' OF LOOP CONTROL VARIABLE." (77,00); "FORMAT ERROR FOR LITERAL PARAMETER OF LOOP CONTROL VARIABLE 'NAME.1'." (78,00); "INVALID FORM OF -DO- STATEMENT." (83,00) (all [J 90.04.01]).
- **J indexing interactions** (see also §on subscripting): each unique subscripted name gets a compiler-generated positional indicator locating the element; "In general, positional indicators are evaluated when their subscripts change value" ([J 02.04.07]–02.04.07.01); "The initial value of an array is A(1) and not A(0)" ([J 02.04.07.01]). Restrictions bearing on loops ([J 90.01.02]): repeated use of the same subscript name for multiple purposes causes unnecessary recalculation ("it will not be incorrect"); "The dimensions of an array must be set before calculation of subscript values associated with the array is performed. Presently, failure to observe this restriction causes invalid object code"; "No object time check is made to insure that subscript references conform to the limits specified by the array dimensions in the Data Description." A DO index used as a subscript must be an integer ([J 90.04.01], message 31,00) and numeric (79,00); inefficient formats are flagged (206,00).

#### 5.5.3 DO with data substitution (USING ... GIVING ...)

Procedures to be used with data substitution "are always defined by the two processor commands 'BEGIN SECTION USING . . . GIVING . . .' and 'END'" ([F p. 52]). The simplest substituting DO:

```
DO procedure.name USING data.name.1, data.name.2, ...
     data.name.n GIVING result.name.1, result.name.2 ...
     result.name.n
```
([F p. 52])

"if data substitution is desired in the other forms of the DO command, the 'USING . . . GIVING . . .' option is simply appended to the command" ([F p. 52]). The matching section header:

```
BEGIN SECTION USING parameter.1, parameter.2, ...
     parameter.n GIVING function.1, function.2, ... function.n
```
([F p. 57])

Semantics (F pp. 32–33, 52–53): at object time, data named in the DO's USING phrase is moved *positionally* into the parameter fields named in the BEGIN SECTION's USING phrase ("items of data named in a DO command will be placed in the parameter fields named in the BEGIN SECTION command in the order in which they are named", [F p. 33]); the procedure executes; then results are moved from the function fields (BEGIN SECTION GIVING) to the fields named in the DO's GIVING phrase ([F p. 33]). `DO MIN.ROUT USING R.RATE, E.RATE, M.RATE GIVING MIN.RATE.` is equivalent to three MOVEs in, `DO MIN.ROUT.`, and one MOVE out ([F pp. 52–53]). Literals may be substituted: `DO MIN.ROUT USING INSURED.AGE, BENEFIC.AGE, 70 GIVING LOW.AGE.` ([F p. 53]), as may figurative constants such as HIGH.VALUES ([F pp. 33–34]).

- USING and GIVING are each optional on the DO; omitting USING reuses whatever values are in the parameter fields, omitting GIVING leaves results in the function fields for direct reference ([F p. 33]).
- A function-name may also be invoked directly in an expression, without a DO, by writing the function-name followed by its argument names in **double parentheses**, comma-separated — e.g. `SET APPROX = 2 * SQUARE.ROOT ((X)) TRUNCATED.` ([F p. 44]); `MOVE MINIMUM ((CALCULATED.PRICE, MARKET.PRICE. HIGH.VALUES)) TO PRICE.LIST.` ([F p. 34] — the period after MARKET.PRICE is an original printing inconsistency preserved by the conversion); rules at F pp. 33–34, 46, 58, and [F p. 28] rule 15. When this technique is used the result can be obtained only from the function field ([F p. 34]).
- Data substitution (object time) must not be confused with name substitution (INCLUDE, processing time) ([F p. 52]) — and INCLUDE is deferred in J ([J 90.01.02]), so no library facilities exist.
- **F/J divergence — PARAM/FUNCT:** F requires every parameter-name and function-name to be declared in the data description with type codes PARAM and FUNCT (F pp. 34, 73). J: "These two type codes described in the General Information Manual are no longer in the language" ([J 02.05.03]). The USING/GIVING mechanism itself survives in J — the compiler checks argument counts: "TOO MANY -USING- PARAMETERS IN -DO- STATEMENT." (72,00), "TOO FEW -USING- ..." (73,00), "TOO MANY -GIVING- ..." (74,00), "TOO FEW -GIVING- ..." (75,00); and functions: "FUNCTION 'NAME.1' LACKS EXPLICIT SPECIFICATION OF ALL ARGUMENTS." (30,00), "EVALUATION IGNORED FOR FUNCTION 'NAME.1'. TOO MANY ARGUMENTS SPECIFIED." (68,00) (all [J 90.04.01]). In J, parameters and functions are therefore described as ordinary data items.

#### 5.5.4 DO with named END (early exit from an iteration)

"When a DO command is compiled, the processor places appropriate instructions in the object program to effect transfer of control between the DO and the associated procedure and to perform any indexing operations specified in the DO. For correct functioning of the DO, these control instructions must be executed each time an iteration of the associated procedure is executed. The control instructions are performed following the last program command specified in the procedure." When the logic requires a conditional exit before the last command, "The solution ... is to name the 'END procedure.name' sentence which terminates the procedure and to use this name as an exit point. (Normally the END sentence is not named; this is the only exception to the rule.) This provides the necessary linkage with the control instructions" ([F p. 53]). Illustration ([F p. 53]):

```
DO REORDER.RTN FOR PART.NO = 1001(1)1499.
        .
        .
        .
REORDER.RTN.  BEGIN SECTION.
        IF QTY.ON.HAND(PART.NO) IS GREATER THAN ORDER.POINT
             (PART.NO) THEN GO TO EXIT.
        SET REORDER.AMT(PART.NO) = ORDER.AMT(PART.NO) -
             QTY.ON.HAND(PART.NO).
EXIT.   END REORDER.RTN.
```

I.e. GO TO the named END sentence terminates the *current iteration* while preserving the loop/return linkage. The same pattern appears in the field-test sample program: BOND.ROUTINE contains `... GO TO BOND.END.` with `BOND.END.  END BOND.ROUTINE.`, and SEARCH has `SEARCH.END.  END SEARCH.` as the target of its in-loop GO TO ([J 90.05], listing PDF pp. 196–197).

#### 5.5.5 The closed-subroutine rule, entry, and exits

- "Any procedure ... that is referred to by a DO command must be what is known technically as a 'closed' or 'linked' subroutine. That is, it must be entered only through the use of a DO command, and not by any other means such as transfer of control to a sentence within the procedure or through the normal passage of control to the first sentence of the procedure. It should be noted, however, that this rule permits the addressing of a procedure by more than one DO command" ([F p. 50]). Also: "a section of procedure that is addressed by a DO becomes a closed subroutine; it can be entered only through the use of one or more DO commands" ([F p. 57]).
- J enforces the entry half of this rule diagnostically: flowing into a DO-addressed name is a "PROBABLE PROGRAM CONTINUITY ERROR" (99,00); a GO TO to a DO-addressed name is bypassed (128,00); PROGRAM.START may not be DO-addressed (143,00); and the DO target must exist: "'NAME.1', ADDRESSED BY A -DO-, IS NEITHER A STATEMENT NOR A SECTION NAME." (188,00) (all [J 90.04.01]).
- **Exits out of a DO'd procedure:** neither manual states a rule against a GO TO that leaves a DO'd procedure for a target outside it, and the J sample program does exactly that: inside DO-addressed SEARCH, `... GO TO NET.` transfers permanently out of the section (and out of the active `DO SEARCH FOR INDEX = 1(1)12` loop) into the main body ([J 90.05], listing PDF pp. 196–197); the DO'd sentence END.OF.MASTERS likewise executes `GO TO END.OF.RUN` out of its DO ([J 90.05], listing PDF p. 196). The pending return linkage is simply abandoned. See the ambiguities register.
- The normal completion of a DO'd sentence, or execution of the END sentence of a DO'd section, returns control "to the command following the DO instruction" ([F p. 33]) / "to the sentence or clause following the DO" ([F p. 50]).
- A DO may appear as one clause among others in a sentence, including inside IF arms: `IF CURRENT.DEPT IS NOT EQUAL TO D.DEPT THEN DO DEPARTMENT.END OTHERWISE GO TO COMPUTE.PAY.` and `END.OF.RUN. DO DEPARTMENT.END, MOVE CORRESPONDING ... , CLOSE ALL FILES, STOP RUN.` ([J 90.05], listing PDF pp. 195–196). GET's AT END phrase may also invoke DO: `GET MASTER, AT END DO END.OF.MASTERS.` ([J 90.05], listing PDF p. 195) — but note the J restriction that "The AT END clause ... may consist of a single imperative statement only" ([J 02.07.05]) and message 106,00 "STATEMENT OR SECTION NAME MUST FOLLOW -AT END-." ([J 90.04.01]); see the Input/Output section.
- Manuals are silent on DO-from-within-a-DO'd-procedure (nested calls) and on recursion; the sample program only issues DOs from the main body. See open questions.

### 5.6 The STOP command; STOP RUN

**F form:**

```
STOP n
```
([F p. 54]) — "where n is an integer. The number n will be displayed when the command is executed, i.e., when the machine halts. Restarting the machine causes execution of the object program to be resumed beginning with the next command in sequence. For a 'dead-end' halt, an unconditional GO TO command placed immediately following the STOP can be used to effect a transfer back to the STOP command" ([F p. 54]). ([F p. 25] also shows the bare example sentence `STOP.` with no operand, and the F payroll example uses `STOP 1234.` (F pp. 92, 101, Appendix 1); see ambiguities.)

**J forms and semantics:** the STOP display subroutine SYS)178 records "the Statement Number of the Stop (in BCD), and the type of STOP (STOP NNN or STOP RUN)" ([J 90.02.14]). At execution ([J 05.06.04]):

- "STOP nnnnnn where nnnnnn is any number 6 digits or less. The computer will stop, and hitting the START key will cause the object program to continue in execution. (It is hoped that the programmer uses this instruction sparingly, if at all)."
- "STOP RUN — This message means that object-time processing of the job is completed and control has returned to the CTM supervisor."
- "The STOP messages will be accompanied by the source language statement number at which the STOP occurred, i.e. AT xxxxx,yy STOP nnnnnn where xxxxx,yy is the statement number" ([J 05.06.04]). The field-test processor prints DISPLAY/STOP messages on the on-line printer ([J 05.06.04]).

**STOP RUN is mandatory in J:** "A STOP RUN instruction must be included in each program to provide for transfer of control to the CT Supervisor at conclusion of execution of the object program. All open files are closed prior to this transfer of control as if a CLOSE ALL FILES had been supplied" ([J 02.04.06], "9. STOP RUN"). Diagnostic: "NO -STOP RUN- IN PROGRAM." ([J 90.04.01], message 175,00). Files closed by CLOSE ALL FILES (hence by STOP RUN) "may not be subsequently reopened by the program" ([J 02.04.06], "8. CLOSE ALL FILES"). Sample usage: `CLOSE ALL FILES, STOP RUN.` ([J 90.05], listing PDF p. 196).

**F/J divergence:** F has only `STOP n` (halt-and-resume); STOP RUN — normal program termination returning control to the supervisor — is a J addition (RUN is reserved in J: key-word list [J 02.03.02]; message 2,00 "-RUN- DELETED. ITS USE IS RESTRICTED TO PROCESSOR."). J bounds n at 6 digits ([J 05.06.04]); F gives no bound.

### 5.7 Sections, procedure-names, and structural constraints on transfer targets

Control transfers are defined in terms of named sentences and sections, so the sectioning rules are part of control flow:

- "A section consists of one sentence, or a group of successive sentences, which has been given a name ... Sectioning, in the Commercial Translator, is used for the purpose of naming portions of procedure" ([F p. 26]). "Unless BEGIN SECTION and END are used, a procedure-name applies only to the sentence which follows it" ([F p. 56]).

```
procedure.name.  BEGIN SECTION.
     any sentence.
     .
     .
     .
     any sentence.
END procedure.name.
```
([F p. 57])

- "The beginning of a section must be identified by a procedure-name, followed by a period. The name must then be followed by the words BEGIN SECTION ... Following the last sentence in the routine, the programmer must write the word END, followed by the procedure-name used originally" ([F p. 26]).
- **Nesting:** "Sections may be 'nested,' that is, one or more sections may be contained within a larger section, but each such section must be wholly contained—it cannot overlap another section" ([F p. 26]; nesting diagram [F p. 57]). J enforces proper nesting: "CANNOT -END- SECTION WHEN NONE ARE OPEN." (64,00); "CANNOT -END- SECTION 'NAME.1' BEFORE SECTION 'NAME.2'." (65,00); "ONE OR MORE SECTIONS NOT CLOSED." (66,00); "-END- SECTION MUST BE THE ONLY CLAUSE IN THE SENTENCE." (179,00) (all [J 90.04.01]).
- The END sentence is normally unnamed; the single exception is the named END of a DO'd procedure ([F p. 57]; §5.5.4).
- "Where necessary, the names of sections can be used as parts of compound names" ([F p. 26]). J qualifies name uniqueness by section: "'NAME.1' IS NOT UNIQUE IN THIS SECTION." ([J 90.04.01], message 166,00); but a record defined within a section may *not* use the section.name as qualifier ([J 90.01.03]). Sections may contain data as well as procedure: "A record is a data hierarchy which may not be part of any data organization except a file or a section" ([J 02.05.01]); see §3 (Data description and storage model).
- The commands that "take advantage of" sections are DO, LOAD and OVERLAP ([F p. 57]). **LOAD and OVERLAP are deferred in J** — "Implementation of these verbs has been deferred" ([J 90.01.03]) and "programs may not be segmented into separate memory loads at this time" ([J 90.01.05], Loader item B.2) — so their control-flow behavior ([F pp. 54–56]: initial loading includes all non-overlapped parts plus the first procedure of each OVERLAP; loading does not execute — a GO TO or DO must transfer control; a LOAD must not appear within the procedure it obliterates; overlapped procedures should end in an unconditional GO TO) is F-only, unimplemented language.
- Sections in generated code: section numbers begin with 0 for the main body and increase by 1 for each BEGIN SECTION; result-storage cells are section-qualified ([J 90.02.03]).
- CONTRL areas (multiple-deck combination — mechanization deferred, [J 90.01.04]): "Indices inside a CONTRL area must not be referenced or modified outside of that area in any of the programs to be merged" ([J 02.06.16]).
- Control-flow-relevant reserved words: always-key words include BEGIN, FOR, IN, ON, WHEN ([J 02.03.02], list 1); never usable as data/procedure names include DO, GO, IF, THEN, OTHERWISE, STOP, RUN, SECTION, END, EXACTLY, TIMES, USING, GIVING, NOT, AND, OR, GT, LT, IS, GREATER, LESS, THAN, EQUAL, EQUALS, TR ([J 02.03.02], list 2; [F p. 110]). F's full word list is at [F p. 110].

### 5.8 Numeric limits and restrictions bearing on control flow (J)

| Item | Limit / rule | Citation |
|---|---|---|
| Operators per sentence | max 60, sentence deleted if exceeded | [J 90.04.01] (171,00) |
| Conditional expression tests per expression | internal capacity; "rewrite as two or more separate expressions" | [J 90.04.01] (187,00) |
| Number of SECTIONS | approx. max 35 | [J 90.01.05] |
| Depth of nested sections | approx. max 18 | [J 90.01.05] |
| Number of index expressions (a * VARIABLE ± b) | approx. max 50 | [J 90.01.05] |
| Number of positional indicators (unique array+subscript combinations) | approx. max 90 | [J 90.01.05] |
| Internal dictionary (all names, programmer + generated) | approx. max 3500 | [J 90.01.05] |
| Generated constants in constant pool | approx. max 500 | [J 90.01.05] |
| DO loop body executions | always at least once, regardless of loop-control values | [J 90.01.02] |
| DO indices per command | max 3; rightmost varies fastest | [F p. 51] |
| Assigned GO TO index | integer 1..n, else fall through | [F p. 49] |
| Subscript range at object time | no object-time check against array dimensions | [J 90.01.02] |
| Array origin | A(1), not A(0) | [J 02.04.07.01] |
| STOP operand | ≤ 6 digits | [J 05.06.04] |
| STOP RUN | required once per program; implies CLOSE ALL FILES | [J 02.04.06]; 90.04.01 (175,00) |
| Procedure-name length | 1–30 characters, followed by period + blank | [F p. 37] |
| Statement numbering | xxxxx,yy — line , clause | [J 02.02.01] |
| Severity codes | 1 = still runnable; >1 no compile-and-go; 5 stops compilation, no deck | [J 90.04.02]; [J 02.01.01] |
| INCLUDE (library procedures) | deferred — no library facilities | [J 90.01.02] |
| LOAD / OVERLAP (segmentation) | deferred | [J 90.01.03]; 90.01.05 (B.2) |
| PARAM / FUNCT type codes | "no longer in the language" (USING/GIVING remain) | [J 02.05.03] |
| AT END clause | single imperative statement only; must name a statement/section | [J 02.07.05]; 90.04.01 (106,00) |

### 5.9 Flagged ambiguities (summary)

The following points, developed above, are recorded in full in the ambiguities register accompanying this document: (1) the DO ... FOR equality-termination test and non-reaching step values; (2) the "index.name.1 is set to p.1 + q.1" wording in the two-index DO; (3) the phrase "tests for NOT greater or less conditions" in the unequal-length comparison rule; (4) legality/semantics of GO TO out of a DO'd procedure; (5) bare `STOP.` vs `STOP n`; (6) whether an object-time range check is generated for the assigned GO TO; (7) the undocumented PROGRAM.START facility; (8) the reserved word EQUALS; (9) SET condition.name in J; (10) nested/recursive DO.

---

## 6. Input/output and report-generation facilities

Input/output in COMTRAN is a record-processing system built on four program verbs — OPEN, GET, FILE, CLOSE — plus the low-volume DISPLAY verb and the (deferred) LOAD/OVERLAP segmentation pair. F chapter 3 gives the 1960 language vision (F pp. 38–41, 54–56); J section 02.07 ("Input/Output Facilities of the 709/7090 Commercial Translator") is the definitive implemented behavior, and J *explicitly corrects* F's description of GET ([J 02.07.04]). All I/O operations "are handled within the Commercial Translator system by the 709/7090 Input/Output Control System" (IOCS) ([J 02.07.01]). File characteristics are declared on Environment Description FILE and SPECIF cards ([J 02.06.02]); the full card-by-card field detail belongs to §7 (Environment description) — this section covers only what is needed to understand I/O semantics.

The programmer initiates "the movement of data into buffers or internal storage, the checking of the validity of the file itself, the checking of the validity of the input or output operation … and finally, the making available or filing away of data"; the I/O control system provides data-flow control and, where feasible, a "look ahead" ([F p. 38]). The system is "a record processing system": the unit made available each cycle is the record; if more than one record of a file must be available at once, the programmer must provide working storage and MOVE additional records there ([F p. 38]) — but see the HOLD option (§6.3) for the implemented alternative. The initial version handles tape and card files; error detection is implicit, and correction "where feasible, is handled automatically" ([F p. 38]).

### 6.1 The file model: record, file, block, buffer

J's definitions ([J 02.07.01]):

| Term | J definition |
|---|---|
| **Record** | "A record is a logical grouping of fields." Made available from an input file by GET; placed in an output file by FILE ([J 02.07.01]). |
| **File** | "A Commercial Translator file is a collection of logically related records stored in an external medium, such as tape or cards." Characteristics are specified in the Environment Description (02.06). "A file is referenced by the commands OPEN and CLOSE to initiate and complete file activity" ([J 02.07.01]). |
| **Block** | "Physical segments of data in a file are called blocks. A block may consist of any combination of records or parts of records." Four factors determine block/record relations: specified block size, whether records span block boundaries, whether every record begins a block, and whether each record *is* the block on tape — see SPANS, HOLD, BEGIN, BLOCK CONTROL and BLOCKSIZE on the Environment FILE card ([J 02.07.01]). |
| **Buffers** | "The Loader reserves a portion of core storage for use by the I/O system as operating storage. This storage area is subdivided into buffers into which all input blocks of data are read and from which all output blocks of data are written. Since the IOCS routine attempts dynamic optimization of buffer assignments, data blocks of a particular file may be located within any of the buffers associated with this or several files" ([J 02.07.02]). |

F defines the same three data terms operationally: OPEN and CLOSE "can operate only on files"; GET and FILE "can operate only on records"; fields are the subordinate units operated on by arithmetic and data-movement verbs ([F pp. 63–64]). A file "is a body of data stored in some external medium which can be made accessible to the system by the use of the verb OPEN"; there may be more than one file on a tape, and a file may extend over a number of tapes ([F p. 63]). A record "is a portion of a file which can be made accessible to the system by the verb GET"; a file, as such, is never actually brought into storage ([F p. 64]). Records in a file are usually, but not necessarily, similar in content, size and format; when differing records are grouped in one file "the programmer must make provisions for distinguishing among them" ([F pp. 63–64]).

Blocking guidance: the greater the block length, the better the tape utilization, but large blocks need large storage allocations; "Blocks of 200 to 500 words will probably provide for the optimum processing of master records" ([J 02.07.02]).

Buffer allocation may be steered by POOL cards (files sharing a common buffer area) and GROUP cards (buffer sharing within a pool); absent these, "files will be grouped automatically by IOCS", and absent GROUP specifications "the compiler will attempt to assign at least 2 buffers to each file" ([J 02.06.13], 02.06.14). Pool BLOCKSIZE should be at least the largest file BLOCKSIZE in the pool (defaulting to it when omitted); GROUP BUFFERCOUNT ≥ OPENCOUNT (maximum concurrently open files in the group) ([J 02.06.13], 02.06.14). Full card detail: see §7.

Numeric limits touching the file model:

| Limit | Value | Citation |
|---|---|---|
| Maximum number of files described (FILE cards) | 63 | ([J 90.01.04]) |
| Maximum BLOCKSIZE (Environment FILE card) | 9999 words | ([J 02.06.04]) |
| Minimum block size, input card files | 24 words ("at lease 24 words", typo in source) | ([J 02.06.04]) |
| Card input columns read (CARD option) | 1–72 only | ([J 02.06.04]) |
| Loader \*SPEC 'blocksize' field | "normally a number (0-999)", cols 17–20 | ([J 03.02.05]) |
| Records in a PATTERN | ≤ 16 | ([J 90.04.01], message 50) |
| ACTIVITY (relative file activity) | 1–99 | ([J 02.06.11]) |
| Number of base locators (= number of located records, field test) | 127 approx. max | ([J 90.01.05]) |
| Number of QUANTITY IN specifications | 25 approx. max | ([J 90.01.05]) |

F's "Storage Areas" discussion ([F pp. 84–85]) establishes that the programmer does not manage input areas, working storage, or output areas explicitly: "Storage areas are automatically reserved when the data description is written, regardless of how the area is to be used. Certain special provisions, especially those governing input and output, are built into the processor for each system" ([F pp. 84–85]). See §3 (Data description and storage model).

### 6.2 Locate and Transmit modes

Records of an input file may be processed **in the buffers** ("locate" mode) or **in an area reserved outside the buffer area** ("transmit" mode); "all records in a file must be processed in the same manner" ([J 02.07.02]).

- **Locate mode:** GET "'locates' the next record in the file, i.e., determines the position of the record within the buffer area, and … adjusts all program references to data within the record to reflect the new base reference address of the record within the buffer area" ([J 02.07.02]).
- **Transmit mode:** GET locates the next record and "'transmits' the record to its assigned area. As the area assignment is fixed no adjustment of references to data within the record is necessary" ([J 02.07.02]).

Mode selection: "The 'transmit' mode is triggered by the selection of the SPANS, HOLD or CARD options on the Environment FILE card. 'Locate' is assumed when none of these options have been selected" ([J 02.07.03]). On the FILE card, HOLD/SPANS force transmit; "The compiler does not differentiate between the words HOLD and SPANS. They produce the same effect and are both included in the vocabulary for mnemonic convenience" ([J 02.06.05]). SPANS is the mnemonic for records that may span block boundaries; HOLD for the requirement "that each named record of the file be available until another of the same name is input" ([J 02.06.05], 02.07.05). For an output file, HOLD/SPANS mean records are written in blocks of the specified length, permitting partial records in blocks for compactness; "Files written in this manner must be processed in the transmit mode when input" ([J 02.06.05]). If neither is selected, an input file is processed in locate mode and an output file is created with all records complete within blocks ([J 02.06.05]).

Consequences and hazards a compiler writer must reproduce:

1. **Base-address adjustment / aliasing.** In locate mode every reference to the record's fields is relative to a base locator updated by GET. "If the locate mode is being used, no references can be made to the record or its fields until after execution of a GET command for that record. All references to fields of a located record initially specify location zero. Upon a GET these references are adjusted to reflect the location of the data within the buffer area. If references are made to located fields prior to the first automatic GET adjustment the low order portions of memory (the monitor) will be irreparably damaged" ([J 02.07.05]). (The base-locator mechanism and the generated LAC/TXL/CLA reference sequence appear at [J 02.08.03] and [J 90.02.04]; see the generated-code section of this reference.)
2. **Efficiency rule.** "The locate mode allows for more efficient utilization of memory … In general, a record should be transmitted if the number of words in the record is less than three times the total number of arithmetic and MOVE references to fields of the record" ([J 02.07.05]).
3. **REDEF forces transmit.** "When through use of the type code REDEF a record is specified to share an area with data other than records within the same file, all records of the file are automatically 'transmitted'. If the records of the file were originally to be located a message is printed indicating this change" ([J 02.07.05]). *Field-test restriction:* "Records from different files which have been REDEF'd together will not be automatically transmitted by the field test processor … SPANS or HOLD must be used" ([J 90.01.01]).
4. **REDEF joint availability.** "All records of a file (whether located or transmitted) which are related through use of the Data Description type code REDEF are made available for processing when any one of the records is requested with the GET command" ([J 02.07.05]).
5. **Arrays force transmit (field test).** "All input records containing arrays will be processed in the transmit mode by the field test processor. This is true for both fixed and variable length records" ([J 90.01.01]).
6. **Constants may not be defined "as a part of a located input area"** ([J 02.05.06]; cross-ref §3).

### 6.3 Record types and variable-length record options

"There are two record types, fixed length and variable length" ([J 02.07.03]).

- **Fixed length:** "A fixed length record cannot vary from the length specified by the data description. When it is read or written, a fixed number or words are always made available or output from the buffer" ([J 02.07.03]; "or words" is a preserved source typo for "of words").
- **Variable length:** length is defined at object time via the QUANTITY IN option; "the current value of the data.name(s) specified by the QUANTITY IN option(s) defines the number of words to be processed. Storage, if the record is transmitted, is always allocated on the basis of the maximum size of the record. The QUANTITY IN clause, by designating that the length of a field within a record is variable in length, identifies the record as being a variable length record" ([J 02.07.03]). (QUANTITY IN mechanics: see §3. Note also: variable-length fields may not be compared ([J 02.04.07]), figurative constants may not be moved to variable-length arrays ([J 02.04.01], 90.01.02), and fields may not be defined following a variable-length array in the same hierarchy ([J 90.01.04]).)

**Standard variable-length record format.** On tape or in a buffer the record "is always immediately preceded by a control word containing the record length. Although this control word is not described as part of the record in the Data Description and may not be addressed by the programmer, it must be considered in specifying block size for a file." It is automatically supplied for records generated by the system, and must be supplied for records generated outside the system ([J 02.07.03]). The binary form is quoted:

```
IOCTN 0,,length.of.record.in.words.
```

([J 02.07.03]; the conversion notes flag that the mnemonic "IOCTN" is clear in the scan but unverified against other IBM documentation.) "Standard variable length BCD records must be immediately preceded by six (6) BCD characters specifying the length of the record in words" ([J 02.07.03]).

**Expansion caution:** "if a variable length record is to be processed in the buffer area (located) it cannot be expanded unless each record in the file begins a new block. No check is made for violation of this rule either at compile time or at execute time" ([J 02.07.03]).

**Options** (declared per record on the Environment FILE card): "They may be elected selectively when only the GET record.name form of the GET command is used to obtain records in the file; the options must be specified for all records if the GET RECORD FROM file.name form is used" ([J 02.07.08]).

| Option | Direction | Effect | Citation |
|---|---|---|---|
| FIND LENGTH IN data.name | input | For a non-standard variable-length record (no control word on tape) whose length is already in storage when the record is obtained, its location is indicated to the I/O system ([J 02.07.08]). | ([J 02.07.08]) |
| BLOCK CONTROL | input | Non-standard variable-length record whose length "is always equal to the size of the block in which it appears"; logical record length = block length ([J 02.07.08], 02.06.05). If both BLOCK CONTROL and FIND LENGTH IN are specified for a record, "only BLOCK CONTROL will be effective" ([J 02.06.06]). | ([J 02.07.08]) |
| PLACE LENGTH IN data.name | input | The length of the record obtained is placed in the specified data.name after completion of the GET; the data.name need not be in the record; may be used with either of the two options above ([J 02.07.08]). | ([J 02.07.08]) |
| NO CONTROL WORD | output | Suppresses generation and output of the standard control word for a variable-length record ([J 02.07.09], 02.06.07). | ([J 02.07.09]) |
| FIND LENGTH IN data.name | output | When the record is filed its length is taken from the data.name "rather than calculated on the basis of the length of the fields of the record"; the data.name need not be in the record; usable whether or not control words are prepared ([J 02.07.09]). | ([J 02.07.09]) |
| PLACE LENGTH IN data.name | output | "prior to filing the record referenced, the length of the record is to be placed in the location, data.name, which is not required to be in the record" ([J 02.07.09]). | ([J 02.07.09]) |

If neither BLOCK CONTROL nor FIND LENGTH IN is selected for a variable-length input record, "it is assumed that the variable length record is preceded on tape by the standard control word" ([J 02.06.05]). "For special purposes, the programmer may employ in connection with a fixed length record any of the variable length record options explained above. NO CONTROL WORD will produce no effect" ([J 02.07.09]).

### 6.4 The OPEN command

General forms ([F p. 39]):

```
OPEN file.name.1, file.name.2, ... file.name.n
OPEN ALL FILES
```

The first form opens only the named file(s); the second opens all files specified in the environment description. "A given file must be opened, of course, before it can be addressed by a GET or FILE command" ([F p. 39]). J does not restate OPEN semantics; it refers the reader back to the General Information manual for OPEN and CLOSE ([J 02.07.01]), so F's object-time description stands, as modified by the SPECIF options below.

*Implementation attested.* The field-test processor compiled `OPEN ALL FILES` — statement 188 of the sample — into `TSX SYS)175,4` / `PZE IOC)1`, the routine that "opens all files in the file list located by IOC)1", and it carries a companion `SYS)174` that "opens the file designated FILENAME" for the named form, whose parser is attested by diagnostic 139,00 "FILE NAME SHOULD FOLLOW -OPEN-." ([J 90.02.13]–14; [J 90.04.01]; [J 90.05] listing, PDF pp. 195, 200)

Opening an **input** file ([F p. 39]):

1. "The label record, if any, is read into storage and checked for validity according to the standard label-handling conventions."
2. Subsequent records are brought into the storage governed by the I/O control system, filling the area allocated to the file.
3. "Checking is performed, and a record count is initiated."

Opening an **output** file ([F p. 39]):

1. "If specified by the programmer, a label record is created and written."
2. Preparation is made to file data records as they become available.
3. Checking is performed and a record count is initiated.

Implemented modifiers (SPECIF card; full detail in §7):

- The file is rewound before opening unless **OPENW** is specified ([J 02.06.10]).
- **OPENF** searches forward on a multi-file reel for a standard-labeled file; without OPENW the tape is rewound before searching; with both, the programmer must ensure the tape is positioned before a header label and the sought file lies further down the tape ([J 02.06.10]).
- **DEFER** exempts a file from the requirement of being mounted before processing commences ([J 02.06.10]).
- Label checking occurs only if **LABELS** (standard, checked/written automatically by IOCS) or **LABELN** (non-standard, ≤ 14 words, checked by the programmer through the FOR LABEL linkage) is stated; "If neither option is exercised the file is considered to be unlabeled" ([J 02.06.11]). Standard input labels are checked against **SERIAL 'ser.no'** (≤ 5 characters, if non-blank) and the reel sequence number from **REEL 'reel.no'** (≤ 4 numeric characters, assumed 1 if absent, adjusted at object time on reel switch) ([J 02.06.12]). **RETAIN days** (≤ 3 numeric characters) protects a written tape: "An attempt to write a labeled file on this tape before the end of the period has expired will result in an on-line error message from IOCS" ([J 02.06.12]).
- The **FOR LABEL statement.name** option on the FILE card "provides transfer of control to statement.name.2 whenever a file is opened or closed or whenever a reel switch occurs" ([J 02.06.05]). See §6.8.

Failure interactions: a GET against a file that is not open takes the end-of-file exit with no error message ([J 02.07.04]); a FILE against a file not OPENed acts as a NOP with no error message ([J 02.07.08]).

### 6.5 The GET command

General forms ([J 02.07.04]; identically [F p. 39]):

```
GET RECORD FROM file.name
GET record.name
```

with the optional end-of-file phrase appended to either form ([F p. 40]):

```
..., AT END any imperative clause
```

"The GET command makes available for processing the next record of an open file. If the file is not open and a GET command is given, the end of file exit is taken. No error message is given" ([J 02.07.04]).

**F/J divergence — meaning of the two forms.** J states: "The verb is described incorrectly in the Commercial Translator General Information manual and the definition given in the last paragraph on page 39 of the manual should be replaced with:

> "The first form of the command assumes that the system has at its disposal sufficient information to obtain the next record. When using a GET of the second form the programmer supplies the system with the name of the next record in the file. Regardless of what record is next in the file, it will be obtained by the GET in accordance with the characteristics associated with the specified 'record.name'. The 'record.name' must be associated with only one input file in the Environment Description."

([J 02.07.04]). F's superseded reading was that the first form is for multi-record-type files (programmer must identify the type) and the second form "implies an input file containing only one type of data record" ([F p. 39]). Under J, `GET record.name` is an *assertion* by the programmer about what is next: no identity check is performed, and a wrong assertion silently misinterprets the data.

**Preconditions for `GET RECORD FROM file.name`** — at least one of the following must hold ([J 02.07.04]):

- a) "All records in the file are of a fixed and equal length."
- b) "The beginning of each record in the file corresponds with the beginning of a tape block (indicated by the BEGIN option of the Environment Description FILE card)."
- c) "All records in the file are in the standard variable length form."
- d) "Each tape block in the file consists of one complete record whose length is equal to the length of the block (signalled by the Environment BLOCK CONTROL)."
- e) "All records in the file which will be obtained by this form of the command are included in a PATTERN in the Environment Description."

(On PATTERN, see the ambiguity note in §6.14: the option is invoked here and policed by compiler diagnostics — "NO RECORDS SPECIFIED IN -PATTERN- ON -FILE- CARD FOR 'NAME.1'.", "SINGLE RECORD IN THE -PATTERN- … INEFFICIENT PROGRAM PRODUCED", "NUMBER OF RECORDS IN -PATTERN- CANNOT EXCEED 16" ([J 90.04.01]) — but no PATTERN syntax appears in the 02.06.C FILE-card general forms.)

**Object-time behavior.** Either form makes the next record available so the entire record or any part may be used; "the previous record of the file is no longer addressable after the execution of a GET command" ([F p. 40]; subject to the HOLD option, under which each named record remains available until another of the same name is input — [J 02.06.05], demonstrated in Example 4, §6.11). Automatically provided auxiliary input operations: unblocking, tape alternation, tape identification, error checking, reading ahead ([F p. 39]). At end of tape, "the end-of-tape label is read, and checks are made. The input tape is rewound, and provision is made for an alternate tape unit to be substituted" ([F p. 40]); the secondary unit comes from the SPECIF UNIT2 assignment ([J 02.06.08]).

**End-of-file processing.** "The AT END clause which may be used with the GET command may consist of a single imperative statement only. The clause is used to specify the action to be taken when the end of a file is reached" ([J 02.07.05]–02.07.06). **F/J divergence:** F allows "any imperative clause" and says the clause is performed "after the last record of a file has been made available for processing and a subsequent GET command has been encountered" ([F p. 40]); J restricts the clause to a *single* imperative statement. If the clause is omitted and an end condition is discovered in attempting to GET a record, the result is "immediate termination of execution of the object program; an error message is printed on-line indicating the cause" ([J 02.07.06]). F's advice: "The programmer should always use the AT END option if the possibility exists of reaching end of file upon execution of the GET" ([F p. 40]).

**Input-error processing** ([J 02.07.06]–02.07.07). "IOCS automatically attempts to correct most input errors discovered in processing." Errors uncorrectable by IOCS:

| Error class | Cause / condition | Notes |
|---|---|---|
| Unrecoverable redundancy errors | "typically caused by permanent tape defects and attempts to read tapes in the wrong mode" | ([J 02.07.06]) |
| Block checksum errors | checksum written with block disagrees with checksum calculated on read | "Block checksums are not checked unless the Environment SPECIF card option CKSUMS is selected" ([J 02.07.06]) |
| Block sequence errors | out-of-sequence block number | checked only if SPECIF option SEQ selected ([J 02.07.06]) |
| Record length errors ("EOB errors" in the IOCS manual) | "information in a block does not conform with the blocking conventions described by the programmer in the Environment Description" — e.g. records spanning blocks without SPANS | "totally unrecoverable by IOCS or the programmer and cause immediate termination of object program execution. An error message is given on the on-line printer" ([J 02.07.06]) |

For the first three classes, the **ON ERROR statement.name** option of the Environment FILE card "provides for communication between IOCS and the programmer" ([J 02.07.07]; card syntax [J 02.06.03], described [J 02.06.04]). "In certain simple error situations such as an unrecoverable redundancy error discovered in a file whose records are complete within the block, the programmer may elect to return directly to the GET command ignoring the error(s) in the unreadable record. This is accomplished by specifying in the ON ERROR clause of the FILE card the procedure.name associated with the GET command" ([J 02.07.07]). More complex recovery requires obtaining and analyzing the error via IOCS facilities ("primarily pages 17 and 18" of the IOCS manual) ([J 02.07.07]). If no ON ERROR provision exists and an IOCS-unrecoverable error occurs, "the system prints an on-line message describing the type of error and the name and certain characteristics of the offending file. Control is then returned to the Commercial Translator Supervisor for processing the next job" ([J 02.07.07]).

**Field-test GET restrictions** ([J 90.01.01]): "Card files processed on-line may only be in BCD and fixed length for field test." Records containing arrays are transmitted; REDEF'd records from different files are not auto-transmitted (SPANS/HOLD required).

F examples ([F p. 40]):

```
GET RECORD FROM INVOICE.FILE.
GET MASTER, AT END GO TO END.OF.MASTERS.
```

### 6.6 The FILE command

General forms ([F p. 40]; [J 02.07.07]–02.07.08):

```
FILE record.name
FILE record.name IN file.name
```

"The FILE command transmits a record from a reserved memory area or an input buffer to an output buffer area for automatic processing onto tape or cards" ([J 02.07.07]). (F additionally lists "the printer" as a FILE target — "The FILE command is used to place records on tape (for subsequent on-line or off-line processing), on cards, or on the printer" ([F p. 40]); J's 02.07 text mentions only tape and cards, though the SPECIF unit assignments include 'PRX' printer and 'OU' system-output designations ([J 02.06.09], 02.06.10). See ambiguity note.)

Semantics:

1. `FILE record.name` "causes a record to be filed in the output file(s) with which it has been associated through the Environment Description. A record so filed is still available for further processing. However, if the record carries the option PRIMARY in one or more of the output files to which it is associated with in the Environment Description, it is only filed in those files wherein it is so classified" ([J 02.07.07]). The PRIMARY option: "The 'FILE record.name' command will file records belonging to more than one output file only in those files where PRIMARY has been specified for that record.name. If PRIMARY is not used with the record.name in any file, the record will be filed in all output files with which it is associated" ([J 02.06.07]).
2. `FILE record.name IN file.name` "provides a means of filing a record in a specific file when the record.name is associated with several output files" ([J 02.07.08]). F's motivating case: "Creating new records in working storage and then merging them into a master file" ([F p. 40]).
3. "In using either form of the FILE command the record.name must be associated in the Environment Description with the name(s) of the file(s) into which it is to be filed" ([J 02.07.08]) — i.e., even the `IN file.name` form requires prior Environment association (**F/J divergence:** F said the second form files the record "even though that record may not have been hitherto associated with that file", [F p. 40]).
4. "If a file has not been OPENed or has been CLOSEd when a FILE command is encountered at execution time, the command acts as a NOP. No error message is given" ([J 02.07.08]).
5. A filed record remains available; "It is entirely possible … to file a record in each of several files by means of a succession of FILE commands" ([F p. 41]).

Automatically provided operations: blocking, tape alternation, file identification, error checking, setting checkpoints ([F p. 40]). Object-time events ([F pp. 40–41]): the record is added to the list awaiting write-out and written when "the proper number of records has been accumulated"; at physical end of reel "the end-of-reel label is prepared and written, arrangements are made for alternation of tape units, and the tape is rewound"; a count of records written is maintained. Checkpoints on reel switch are controlled by the SPECIF options CHECKC (checkpoint written on the checkpoint file upon reel switch of this file) and CHECKF (written on this file; the file must be a labeled output file); "No check point will be written if neither option is exercised" ([J 02.06.11]). A checkpoint file is declared `file.name FILE CHECKPOINT` and "may have no other usage" ([J 02.06.04]).

F examples ([F p. 41]):

```
FILE MASTER.
FILE PAY.RECORD.
FILE DETAIL IN ERROR.FILE.
```

### 6.7 The CLOSE command and CLOSE ALL FILES

General forms ([F p. 41]):

```
CLOSE file.name.1, file.name.2, ... file.name.n
CLOSE ALL FILES
```

"Each file which has been opened must ultimately be closed" ([F p. 41]). F's object-time description (J defers to it for the named-file form, [J 02.07.01]):

Input file ([F p. 41]):

1. "The record count is compared with the count in the end-of-file label if label records are present and if end of file has been reached. If the count does not agree, notification is given through external display. If the tape is not at end of file the record count is ignored."
2. If on tape, a rewind is initiated.
3. "The storage area allocated to the file is released for the use of other files."

Output file ([F p. 41]):

1. "Any remaining information belonging to that file is written."
2. If specified, an end-of-file label containing the record count is written.
3. The tape is rewound (if on tape).
4. The storage area is released.

**CLOSE ALL FILES (implemented behavior).** "This command causes each open file to be closed in accordance with the close options exercised on the Loader \*SPEC card. Section 03.02 describes the options as they appear on the \*SPEC card which may be supplied by the programmer or generated by the Compiler from an Environment SPECIF card (Section 02.07). In the absence of specification, closing includes a rewind and unload of the unit. Files closed by this form of the CLOSE command may not be subsequently reopened by the program" ([J 02.04.06]; the parenthetical "(Section 02.07)" is as printed — the SPECIF card is actually described in 02.06.D). The \*SPEC open/close option codes ([J 03.02.05]):

| \*SPEC 'open' | Meaning | \*SPEC 'close' | Meaning |
|---|---|---|---|
| N | No rewind | U | Rewind and unload |
| R or blank | Rewind | R or blank | Rewind |
| | | N | No Rewind |
| | | S | No file mark or trailers, no rewind |

On the SPECIF card the corresponding programmer choices are CLOSER ("the file is only to be rewound upon closing") and CLOSEW ("the file is not to be rewound upon closing"); either avoids the default rewind-and-unload ([J 02.06.10]).

**STOP RUN.** "A STOP RUN instruction must be included in each program to provide for transfer of control to the CT Supervisor at conclusion of execution of the object program. All open files are closed prior to this transfer of control as if a CLOSE ALL FILES had been supplied" ([J 02.04.06]).

F examples ([F p. 41]):

```
CLOSE INVENTORY.FILE, STATISTICS.
CLOSE ALL FILES.
```

### 6.8 Labels and non-standard label processing

F background: labels are special records identifying a file and its contents, normally one at the beginning and one at the end; "Many of the details of labeling are handled automatically by the 'input-output package'" and most labeling procedures are prescribed per machine system ([F p. 63]). The programmer "has the option of prescribing certain details of a label by the use of the LABEL type code" ([F p. 64]); F's LABEL type code "identifies a data description as that of a label record. This will cause a redefinition of the label area in the input-output control system", with actual use deferred to the processor publications ([F p. 77]).

J's implemented mechanism ([J 02.05.03]): "The type code LABEL allows the programmer to redefine with the indicated data description entries, the single 14 word label area in the Input/Output Control System from which all labels for output files are written and into which all input labels are read. This area may only be processed by the Commercial Translator programmer by using the FOR LABEL option on the Environment FILE cards. Use of the FOR LABEL option with a file causes IOCS to transfer control to the procedure.name specified with the option when the file is opened or closed, or when a reel switch occurs." The LABEL type code plus FOR LABEL "provide the programmer with an IOCS oriented method of checking and forming non-standard labels. The restrictions limiting the length of labels processed in this manner to 14 words and dictating that portions of the FOR LABEL coding must be done in CRYPT may make an alternate method desireable; i.e., defining labels as records and processing with the GET and FILE verbs" ([J 02.05.03]). The 14-word label area corresponds to IOC)29, "a 14 word area within IOCS which is used to process all labels" ([J 90.02.08]).

Both [J 02.05.03] and [J 02.06.12] refer to Appendix 90.07 for implementation of FOR LABEL processing, but the table of contents lists "APPENDIX 90.07: SAMPLE NON STANDARD LABEL PROCESSING **(Not Currently Available)**" (J contents page) — the appendix does not exist in this edition. J's own note: "careful study of the IOCS manual and Appendix 90.07 of this bulletin is essential for understanding standard and non-standard labels" ([J 02.06.12]).

Label-related SPECIF facts needed for I/O semantics (detail in §7): LABELS = standard labels checked/written automatically by IOCS; LABELN = non-standard label of 14 words or less checked by the programmer via the FOR LABEL linkage; neither ⇒ unlabeled file ([J 02.06.11]). SERIAL/REEL/RETAIN information "is kept in the IOCS file block and is printed on-line in certain error situations. It is used by IOCS in checking and preparing standard labels (but not non-standard labels) and may be used by the programmer in checking and preparing non-standard labels" ([J 02.06.12]). Standard output labels take their serial number from the label already on the first reel unless REEL specifies a 'reel.no' greater than 1 ([J 02.06.12]). Label density defaults to the file's density; a trailing HIGH/LOW after LABELS/LABELN overrides it ("Label dinsity", typo preserved) ([J 02.06.12]). Which IOCS module is loaded depends on these features: "Normally the MINIMUM module of IOCS is used with the object program. If checkpoints are desired or specified BASIC IOCS is used. If labeling exists the LABELS version of IOCS is necessary" ([J 90.01.05]).

### 6.9 The DISPLAY command

General form ([F p. 54]):

```
DISPLAY 'any message' data.name 'any message'
```

"The DISPLAY command causes the object program to present such low-volume information on an appropriate output device or display medium" ([F p. 54]). "The DISPLAY command displays all the information that follows the word DISPLAY up to, but not including, a comma or period not enclosed in quotation marks" ([F p. 54]). Material inside quotation marks is displayed exactly; a data-name written *outside* quotation marks is replaced by its current value ([F pp. 54–55]). "The name of the variable outside the parentheses may be subscripted. It must represent a defined field, however, and not an arithmetic combination of fields" ([F p. 55]; "parentheses" is as printed and evidently means the quotation marks).

Implemented specifics ([J 02.04.02.01]):

- "The display device for the 709/7090 processor is the on-line 716 printer."
- "the portion of the material to be displayed which is written enclosed in quotation marks actually is an alphameric literal, which may not exceed fifty characters in length and must be complete upon a single line."
- "A check is made to determine whether the internal form of the sentence to be displayed is more than 255 words of storage. If it is, the entire literal will be printed but it will be printed as more than one physical record."

Field-test restriction ([J 90.01.01]): "Data names not intended to be used as qualifiers must be separated by commas; otherwise all but the last will be disregarded." **F/J divergence:** under F's rule an unquoted comma *terminates* the displayed material, while J's field-test rule *requires* commas between successive data-names (adjacent unseparated names are treated as one qualified name and "all but the last will be disregarded"). See ambiguity note.

F worked example ([F p. 55]): `DISPLAY 'VALUE OF WAGES LESS DEDUCTIONS IS' NET.PAY.` prints `VALUE OF WAGES LESS DEDUCTIONS IS $67.75` when NET.PAY's edited value is $67.75.

The alphabetized command list also records the general shape ([F p. 108]):

```
DISPLAY  { 'any message'
         { data.name
         { any combination of the above
```

### 6.10 The LOAD command (and OVERLAP) — deferred

General form ([F p. 54]):

```
LOAD procedure.name
```

LOAD, used with the processor command OVERLAP (`OVERLAP procedure.name.1, procedure.name.2, ... procedure.name.n`, [F p. 55]), brings a unit of procedure waiting in external storage into the storage area shared by the procedures named in the associated OVERLAP; the displaced portion "can be retrieved later by another LOAD command"; "Any unit of procedure addressed by a LOAD command must be named in an OVERLAP command" ([F p. 54]). Object-program organization under OVERLAP: initial loading includes everything not mentioned in any OVERLAP plus the first procedure named in each OVERLAP command; loading does not execute the procedure (a GO TO or DO must follow); overlapped procedures should end with an unconditional GO TO because a shorter procedure loaded over a longer one does not erase all of it; a LOAD must not appear within the procedure it obliterates ([F pp. 55–56]).

**Not implemented:** "Implementation of these verbs has been deferred" ([J 90.01.03]), and on the Loader side, "Deferred implementation of the LOAD-OVERLAP verbs implies that programs may not be segmented into separate memory loads at this time" ([J 90.01.05]).

### 6.11 The worked examples of J 02.07.F

J closes its I/O section with four examples; a compiler writer should treat them as acceptance tests for blocking/mode logic.

| # | File setup | Demonstrates | Citation |
|---|---|---|---|
| 1 | Three fixed lengths (REC1 64, REC2 128, REC3 192 words), unknown order, BLOCKSIZE 256, no SPANS/HOLD, no BEGIN | Output blocking packs records into 256-word blocks without splitting: block J = REC1+REC1+REC2 (256), J+1 = REC1+REC2 only (192 — REC3 would overflow and may not span), J+2 = REC3+REC1 (256). Input is processed in **locate** mode; only `GET record.name` may be used "since the records have differing fixed lengths and no pattern has been supplied". Output written per the same specifications automatically produces the illustrated tape. | ([J 02.07.09]–02.07.10) |
| 2 | Same three record lengths, unknown order, BLOCKSIZE 128, SPANS and BEGIN both taken | Blocks are truncated to honor BEGIN (64-word blocks for REC1) and REC3 spans two blocks (128 + 62 words — 62 as printed). Input processed in **transmit** mode "since they may span block boundaries"; `GET record.name` still required (same reason as Example 1). | ([J 02.07.11]) |
| 3 | 85-character records written by card-to-tape equipment as two cards (72 + 13 chars); one record type; BLOCKSIZE 12 ("BLOCKSIZE12" as printed); SPANS and BEGIN taken | Salvaging useful data from a hardware-forced block structure: BLOCKSIZE 12 reads only 12 words per tape block, "discarding the last 2 words of each block"; SPANS transmits the first 12 words of block J plus the first 3 words of block J+1 into a 15-word reserved memory area; BEGIN discards the remainder of J+1 by "direct[ing] system attention to a new block when a GET command is issued". "Either form of the GET command may be used to obtain records from this file." | ([J 02.07.12]–02.07.13) |
| 4 | Two 80-character card-image record types (REC1, REC2), unknown order, BLOCKSIZE 14, HOLD and BEGIN taken | The HOLD option: each `GET REC1` / `GET REC2` transmits 14 words from the buffer to that record's own area; "The information at REC1 is still available after this second command and will continue to be available until replaced by another 'GET REC1'." Also: the 4 pad characters card-to-tape equipment adds to make 84 characters are transmitted but ignored — "other Commercial Translator operations, such as the MOVE, will be based upon the 80 characters specified in the Data Description of the record rather than the 84 characters appearing on tape." | ([J 02.07.13]–02.07.14) |

### 6.12 Report generation: what exists and what does not

**Finding: neither manual contains a report-writer facility.** There is no report-writer verb, no report section or division, and no report-description entry in either F or J. F's verb list ([F p. 35]) and command list ([F pp. 108–109]) contain no report verb; J's deferred-features appendix ([J 90.01]) lists no deferred report writer — it is simply absent from the language. Confirming context: the J manual's own Publications list refers readers to a *separate, non-COMTRAN* product for report generation — "J28-6168 | SHARE 7090 9PAC: Part 3 - The Reports Generator" (J Publications page, PDF p. 221).

What "report generation" amounts to in the implemented language:

1. **Edited MOVEs/SETs into output records.** "Editing of the data in the sending area to conform to the format of the receiving area is a feature of the MOVE command", driven by field pictorials in the data description ([F p. 42]); MOVE rule 1 permits numeric data to be moved "to report fields" ([F p. 42]) — F's term for what J calls **edited fields**, characterized by the pictorial characters `8 * ., $ + -` or the BLANK WHEN ZERO clause ([J 02.05.05]; see §3 for the full pictorial/editing rules, e.g. `$888,888.99`, [F pp. 80–81]). SET results are likewise edited to the result field's format: "if a result represents an amount of money, editing appropriate to the defined format of the money field will be performed" ([F p. 44]).
2. **FILE-ing edited records to output files.** Print-image records are assembled (constants, blanks, edited fields) and FILE'd to BCD output files — on tape for off-line listing, on cards, or (per F) on the printer ([F p. 40]). The sample program's "Output Report Files" (CHECKFILE, BONDORDERFILE, PAYFILE, ERRORFILE) are exactly this: e.g. the CHECKFILE record is "a 2-line check to be printed under carriage control on a 720 printer", the two print lines grouped in one record "separated by a record mark (signalled by type RCDMRK) for printer control", with carriage-control characters occupying the first character position of each line ([J 90.05.03]). "In output report records blanks may be specified as a constant. If the format specification indicates the length of the field, it is unnecessary to provide the proper number of blanks between quote marks" ([J 90.05.04]). The RCDMRK type code inserts "a single character record mark constant in the indicated position", automatically given a single-`A` pictorial, freely movable into/out of ([J 02.05.03]; see §3). The actual printed output of these files appears as "REPORT OUTPUT FOR SAMPLE PROBLEM" ([J 90.05], PDF p. 217).
3. **Control-break logic written by hand.** Department totals and grand totals in the sample program are accumulated by ordinary ADD/ADD CORRESPONDING into internally-formatted working areas and moved out as "external edited versions" on a change in department number ([J 90.05.04]); F's ADD CORRESPONDING example is exactly the accumulation of department and grand totals ([F p. 47]).
4. **DISPLAY for low-volume output** to the on-line 716 printer ([J 02.04.02.01]; [F p. 54]) — operator messages and debugging values, not reports.

F's payroll example likewise treats reporting as an output file: among its four output tape files is "(2) A payroll report file, which will be used to produce a printed report" ([F p. 87]).

### 6.13 Environment-card summary for I/O (cross-reference to §7)

The FILE card "must be included to describe the file characteristics which affect compilation" and "must be made for each file processed by the program" ([J 02.06.02]); the general forms are quoted verbatim below because every option named in this section appears in them. Full field-by-field treatment (columns, continuation rules, SPECIF/POOL/GROUP/CONTRL/OPTION/COND cards, unit-assignment notation): see §7.

Input files ([J 02.06.03]):

```
Name        Type    Description

file.name   FILE    INPUT    [ ,{BCD}    ]    [ ,{CARD} ]
                              [  {BINARY} ]    [  {TAPE} ]

                     ,BLOCKSIZE nn

                     [ ,ON ERROR statement.name.1 ]
                     [ ,FOR LABEL statement.name.2 ]
                     [ ,{HOLD}  ]    [ ,BEGIN ]
                        {SPANS}

                     ,record.name.1

                     [ ,{BLOCK CONTROL}               ]
                     [  {FIND LENGTH IN data.name.1}  ]
                     [ ,PLACE LENGTH IN data.name.2   ]

                     [ record.name.2 . . . ]
```

Output files ([J 02.06.03]):

```
Name        Type    Description

file.name   FILE    OUTPUT   [ ,{BCD}    ]    [ ,{CARD} ]
                              [  {BINARY} ]    [  {TAPE} ]

                     ,BLOCKSIZE nn

                     [ ,FOR LABEL statement.name.2 ]

                     [ ,BEGIN ]    [ ,SPANS ]

                     ,record.name.1

                     [ ,FIND LENGTH IN data.name.1  ]
                     [ ,PLACE LENGTH IN data.name.2 ]
                     [ ,PRIMARY ]    [ ,NO CONTROL WORD ]

                     [ ,record.name.2 . . . ]
```

Checkpoint files ([J 02.06.04]):

```
Name        Type    Description

file.name   FILE    CHECKPOINT
```

Rules and defaults with direct I/O consequences:

- One of INPUT/OUTPUT/CHECKPOINT is mandatory; a CHECKPOINT file "may have no other usage" ([J 02.06.04]).
- Mode defaults to **BCD**; medium defaults to **TAPE** ([J 02.06.04]).
- **CARD**: on-line card reader/punch; "When CARD is specified BEGIN is assumed"; only columns 1–72 are read; "For the most efficient handling of card input a GROUP card should be used when more than two cards constitute a record" ([J 02.06.04]). CARD also triggers transmit mode ([J 02.07.03]).
- **BLOCKSIZE nn is mandatory**: "the size of the largest block to be output or the maximum number of words to be input from an input block" — note the input reading *truncates* larger physical blocks (exploited in Example 3, and by the sample program's DETAILFILE — BLOCKSIZE 3 against 14-word blocks, [J 90.05.03]). Card input files ≥ 24 words; maximum 9999 ([J 02.06.04]).
- **All records associated with the file "must be" named on the FILE card** ([J 02.06.05]); "The order in which options are exercised on the FILE card is critical only in that the options exercised for a particular record must be listed following the record.name and prior to the introduction of another record.name" ([J 02.06.04]).
- **BEGIN**: "each record to be read or written by the program starts at the beginning of a physical block" ([J 02.06.05]).
- Per-record options: BLOCK CONTROL / FIND LENGTH IN / PLACE LENGTH IN (input); FIND LENGTH IN / PLACE LENGTH IN / PRIMARY / NO CONTROL WORD (output) — semantics in §6.3, §6.6.
- A period must **not** terminate an Environment specification ("it will be treated as part of the previous word thus creating an undefined symbol", [J 02.06.02]); qualified names may not be used in the Environment Description ([J 90.01.04]).
- SPECIF cards are optional (load-time \*SPEC/\*FILE cards may be hand-punched instead) and may appear anywhere within the environment division ([J 02.06.07]).
- Deferred/restricted: maximum 63 FILE cards; "No file check table is produced in the object deck"; absolute tape assignment cannot be made (symbolic/relative only) ([J 90.01.04]).

### 6.14 Ambiguities flagged in this section

(Recorded in full in §8.5; summarized here so the reader of this document sees them in place.)

- The **PATTERN** Environment option is required reading for `GET RECORD FROM` ([J 02.07.04] e) and enforced by diagnostics 48–50 ([J 90.04.01]) but its card syntax is nowhere given.
- **Appendix 90.07** (non-standard label processing) is cited normatively ([J 02.05.03], 02.06.12) but marked "Not Currently Available" in the contents.
- Whether a file closed by the **named-file CLOSE** form may be reopened is unstated (J prohibits reopening only after CLOSE ALL FILES, [J 02.04.06]).
- **DISPLAY's comma** is both a terminator ([F p. 54]) and a required separator between data-names ([J 90.01.01]).
- **On-line printer as a FILE target**: [F p. 40] lists the printer; J's 02.07 lists only tape and cards, while 'PRX'/'OU' unit assignments exist ([J 02.06.09], 02.06.10) and the sample program prints via off-line listing of BCD tapes ([J 90.05.03]).
- \*SPEC 'blocksize' "(0-999)" ([J 03.02.05]) vs Environment maximum 9999 ([J 02.06.04]).
- `GET` against an unopened file ("the end of file exit is taken. No error message is given", [J 02.07.04]) vs termination-with-message when no AT END clause exists ([J 02.07.06]).

---

## 7. Special facilities and library conventions

This section covers everything in COMTRAN outside the Data and Procedure descriptions proper: the Environment Description (all seven card types, every field and default), the compiler control cards ($CMPLE, *FINISH) as source-visible language surface, the library system (COPY, LIBRARY, INCLUDE) as designed in 1960 and its deferral in 1962, program segmentation (OVERLAP/LOAD), renaming and linkage (CALL, ENTER, CONTRL), commentary (NOTE), and the CRYPT symbolic machine language facility. Throughout, J28-6169 (the 709/7090 processor manual) is authoritative for the implemented language; F28-8043 material is included where it defines features J defers or omits.

### 7.1 The Environment Description ([J 02.06])

#### 7.1.1 Purpose and position in the source program

The Environment Description "allows the programmer to specify the external physical factors which relate to the compilation and execution of the program … including physical characteristics of data, machine configurations, and programmer-elected features." These factors may usually be changed without affecting the logical description of the problem in the Procedure and Data Description parts ([J 02.06.01.01]).

A source program is divided into three divisions, each portion introduced by a *division header* — the division name preceded by an asterisk: `*PROCEDURE`, `*DATA`, `*ENVIRONMENT`. The divisions need not appear as separate entities; portions may be interleaved, but each portion must be labeled with its header, and all entries following a header belong to that division ([F p. 27]). (Division headers and overall program structure: see §2, Language structure.)

**F/J divergence:** F28-8043 reserves the environment division but does not define its content — it states only that each record must "also be named in the environment description, as specified in the publication covering the processor for each particular system" ([F p. 71]). The full card-level definition below exists only in J.

Appendix 90.08 of J describes the effect of Environment specifications on the Loader symbolic control cards generated by the Compiler ([J 02.06.01.01]); a summary is in §7.1.11 below.

#### 7.1.2 Coding form, card layout, and continuation rules

The Environment Description coding form (Figure 1, [J 02.06.01.02]) has these fields:

| Columns | Field |
|---|---|
| 1–3 | CTL. |
| 4–6 | Serial |
| 7–22 | Name |
| 25–30 | Type |
| 31–71 | Description (options) |
| 72 | Continuation |
| 73–80 | Identification |

Rules ([J 02.06.01.01], [J 02.06.02], [J 02.03.01]–02.03.03):

- The first card of each specification group *may* contain an appropriate name in the Name field (columns 7–22) and *must* contain one of the seven type codes in the Type field (columns 25–30) ([J 02.06.01.01]). A FILE card lacking a name in columns 7–22 draws error 1,00; likewise a COND card, error 88,00 ([J 90.04]).
- **Continuation:** when multiple cards are required, continuation of the options (columns 31–71) or Name on subsequent cards is indicated by a non-blank character in column 72. A blank column 72 signals that the next card initiates a new specification; if that next card contains no type specification "the card is deleted and an error message given." If a card carrying the continuation signal is followed by one containing a type specification, "the type is ignored and the options specified are considered to be part of the previous specification" ([J 02.06.01.01]).
- Entries are considered complete when column 72 is blank. The processor replaces the contents of column 72 with a blank, so each word or literal must be complete upon a line ([J 02.03.01]–02.03.02).
- All imbedded and leading blanks in the name fields of cards associated with an entry are eliminated and the non-blank characters compressed to form a single name ([J 02.03.01]).
- **A period (.) must not be used to signal the end of a specification** — it is treated as part of the previous word, "thus creating an undefined symbol" ([J 02.06.02]; also [J 02.03.02]).
- **Qualified names may not be used in the Environment Description.** Data and Procedure names used here must be of one word only; the verb CALL (§7.5.1) reduces a qualified name to a one-word name ([J 02.03.03]; restated at [J 90.01.04]).
- Many key words (ACTIVITY, BCD, BINARY, BLOCKSIZE, CARD, CHECKC, …) may be used as Procedure/Data names only if the item need never be referenced in the Environment Division ([J 02.03.03]); see §2 (reserved words / key words) for the full three-tier lists.

#### 7.1.3 The seven card types

Seven type codes may appear in columns 25–30 ([J 02.06.01.01]): FILE, SPECIF, POOL, GROUP, CONTRL, OPTION, COND. Their general functions ([J 02.06.02]):

| Card | General function |
|---|---|
| FILE | "must be included to describe the file characteristics which affect compilation, such as use for input or output and the type of blocking utilized." |
| SPECIF | "describes such file characteristics as symbolic input/output unit assignments, density, relative activity, labeling conventions and other programmer choices which are to be punched during compilation into load-time control cards. SPECIF cards may be omitted if the programmer prefers to provide his own cards containing the appropriate information at load-time." |
| POOL | "may be used by the programmer to direct the processor in the allocation of buffer storage for several files. In the absence of POOL cards, the processor will automatically make pool and buffer assignments." |
| GROUP | "may be used by the programmer to specify buffer allocation for files belonging to a particular buffer POOL." |
| CONTRL | "If several separately compiled programs are to be combined and executed as one program, any joint procedure or data description areas must be defined for the compiler by CONTRL environment cards." |
| OPTION | "used when the programmer wants the processor to depart from its standard use of 709/7090 collating sequence, or when he wishes special emphasis placed on minimizing either storage or running time requirements in his object program." |
| COND | "names and defines a computer console key setting which the programmer may want to test by procedure statements in his program." |

#### 7.1.4 FILE card

A FILE specification "must be made for each file processed by the program" ([J 02.06.02]). **A maximum of 63 files may be described** ([J 90.01.04]). No file check table is produced in the object deck ([J 90.01.04]).

General form — input files ([J 02.06.03]):

```
Name        Type    Description

file.name   FILE    INPUT    [ ,{BCD}    ]    [ ,{CARD} ]
                             [  {BINARY} ]    [  {TAPE} ]

                     ,BLOCKSIZE nn

                     [ ,ON ERROR statement.name.1 ]
                     [ ,FOR LABEL statement.name.2 ]
                     [ ,{HOLD}  ]    [ ,BEGIN ]
                        {SPANS}

                     ,record.name.1

                     [ ,{BLOCK CONTROL}               ]
                     [  {FIND LENGTH IN data.name.1}  ]
                     [ ,PLACE LENGTH IN data.name.2   ]

                     [ record.name.2 . . . ]
```

(The mark "nj" following `record.name.1` on the source page is real typed characters — scan-resolved: not bleed-through, with the apparent trailing period a dust speck; it corresponds to no defined syntax element and is ignored. See §8.5.8.)

General form — output files ([J 02.06.03]):

```
Name        Type    Description

file.name   FILE    OUTPUT   [ ,{BCD}    ]    [ ,{CARD} ]
                             [  {BINARY} ]    [  {TAPE} ]

                     ,BLOCKSIZE nn

                     [ ,FOR LABEL statement.name.2 ]

                     [ ,BEGIN ]    [ ,SPANS ]

                     ,record.name.1

                     [ ,FIND LENGTH IN data.name.1  ]
                     [ ,PLACE LENGTH IN data.name.2 ]
                     [ ,PRIMARY ]    [ ,NO CONTROL WORD ]

                     [ ,record.name.2 . . . ]
```

General form — checkpoint files ([J 02.06.04]):

```
Name        Type    Description

file.name   FILE    CHECKPOINT
```

**Option ordering rule:** "The order in which options are exercised on the FILE card is critical only in that the options exercised for a particular record must be listed following the record.name and prior to the introduction of another record.name" ([J 02.06.04]).

Option-by-option ([J 02.06.04] – 02.06.07):

- **INPUT / OUTPUT / CHECKPOINT** — one of the three must be specified. "If a file is designated as CHECKPOINT it may have no other usage" ([J 02.06.04]).
- **BCD / BINARY** — mode in which an input file is read or an output file written. Default: **BCD** ([J 02.06.04]).
- **CARD / TAPE** — CARD if the on-line card reader or card punch is the processing unit. "When CARD is specified BEGIN is assumed, i.e., each record starts at the beginning of a physical block. With this option only columns 1 through 72 are read. For the most efficient handling of card input a GROUP card should be used when more than two cards constitute a record." Default: **TAPE** ([J 02.06.04]). Restriction: "Card files processed on-line may only be in BCD and fixed length for field test" ([J 90.01.01]).
- **BLOCKSIZE nn** — *mandatory.* nn is "the size of the largest block to be output or the maximum number of words to be input from an input block. … All input card files must have a block size of at lease 24 words. Maximum blocksize is 9999 words" ([J 02.06.04]; "at lease" sic). A numeric integer must follow BLOCKSIZE (error 91,00, [J 90.04]).
- **ON ERROR statement.name.1** (input only) — a procedure statement name "to which transfer will be made if the system is unable to recover from an input error" ([J 02.06.04]); the programmer's hook for unrecoverable redundancy, block-checksum and block-sequence errors ([J 02.07.07]). Record length errors are "totally unrecoverable by IOCS or the programmer" and terminate execution ([J 02.07.06]). Without ON ERROR, an IOCS-unrecoverable error prints an on-line message and returns control to the CT Supervisor ([J 02.07.07]). A statement or section name must follow ON ERROR (error 92,00, [J 90.04]).
- **FOR LABEL statement.name.2** — "provides transfer of control to statement.name.2 whenever a file is opened or closed or whenever a reel switch occurs" ([J 02.06.05]), for programmer processing of non-standard labels via the 14-word IOCS label area redefined with the Data Description type code LABEL ([J 02.05.03]; see §3). Portions of FOR LABEL coding must be done in CRYPT ([J 02.05.03]). The referenced worked example, Appendix 90.07, is listed in J's own table of contents as "Not Currently Available" (J 00 contents). A statement or section name must follow FOR LABEL (error 93,00, [J 90.04]).
- **record.name** — "All records associated with the file **must be** named on the FILE card" ([J 02.06.05]). A record used with GET must be associated with only one input file ([J 02.07.04]; errors 9,00–11,00, [J 90.04]).
- **HOLD / SPANS** — for an input file, forces the *transmit* mode of processing: required if records overrun block boundaries (SPANS) or if each named record must remain available until another of the same name is input (HOLD). For an output file, "specifies that output records are to be written in blocks of the specified length," permitting partial records in blocks for compactness (SPANS); such files must be processed in the transmit mode when input. "The compiler does not differentiate between the words HOLD and SPANS. They produce the same effect and are both included in the vocabulary for mnemonic convenience." Default ("If neither HOLDS or SPANS is selected" — sic): input processed in the *locate* mode; output created with all records complete within blocks ([J 02.06.05]). Locate/transmit semantics: see the Input/output facilities section ([J 02.07.02]–02.07.05).
- **BEGIN** — "each record to be read or written by the program starts at the beginning of a physical block" ([J 02.06.05]).
- **BLOCK CONTROL / FIND LENGTH IN data.name.1** — BLOCK CONTROL: input record is variable length with no standard control word preceding it; logical record length equals block length. FIND LENGTH IN: the length of an input or output record is obtained from data.name.1 rather than from the data description. Default (neither): "it is assumed that the variable length record is preceded on tape by the standard control word" ([J 02.06.05]). "If both options are specified for a record, only BLOCK CONTROL will be effective" ([J 02.06.06]). A data name must follow FIND LENGTH IN (error 95,00, [J 90.04]).
- **PLACE LENGTH IN data.name.2** — on input, makes the length of the current record available in data.name.2; on output, the length is placed there "prior to filing the record" ([J 02.06.06]). The data.name need not be in the referenced record ([J 02.07.08]–02.07.09). A data name must follow PLACE LENGTH IN (error 94,00, [J 90.04]). Any of the variable-length options may be applied to fixed-length records; NO CONTROL WORD then has no effect ([J 02.07.09]).
- **PRIMARY** (output only) — enables selective filing of a record associated with more than one output file: `FILE record.name` files such a record only in files where PRIMARY was specified for that record.name; if PRIMARY is not used with the record.name in any file, the record is filed in all associated output files ([J 02.06.07]).
- **NO CONTROL WORD** (output only) — "notifies the system not to produce the standard control word for the variable length output record" ([J 02.06.07]).

The standard variable-length record control word — one word, `IOCTN 0,,length.of.record.in.words.` for binary, six BCD characters of length for BCD records — precedes each standard variable-length record on tape and in the buffer, is not describable or addressable by the programmer, but must be counted in BLOCKSIZE ([J 02.07.03]; see the Input/output section).

Further field-test restrictions folded in from [J 90.01.01]: all input records containing arrays are processed in the transmit mode; records from different files REDEF'd together are not automatically transmitted (SPANS or HOLD must be used).

**Checkpoint files:** designating a FILE CHECKPOINT (with SPECIF CHECKC/CHECKF on data files, §7.1.5) is the language surface of the checkpoint facility. IOCS module choice follows: "Normally the MINIMUM module of IOCS is used with the object program. If checkpoints are desired or specified BASIC IOCS is used. If labeling exists the LABELS version of IOCS is necessary" ([J 90.01.05]). Restart is an operator procedure ([J 05.04]), not a language feature.

**The PATTERN puzzle:** the GET verb discussion allows `GET RECORD FROM file.name` when "All records in the file which will be obtained by this form of the command are included in a PATTERN in the Environment Description" ([J 02.07.04]), and three compiler diagnostics govern it — "NO RECORDS SPECIFIED IN -PATTERN- ON -FILE- CARD FOR 'NAME.1'.", "SINGLE RECORD IN THE -PATTERN- ON -FILE- CARD … INEFFICIENT PROGRAM PRODUCED", and "NUMBER OF RECORDS IN -PATTERN- CANNOT EXCEED 16" (errors 48,00–50,00, [J 90.04]) — yet no PATTERN option appears in the FILE card general forms ([J 02.06.03]). See ambiguities.

#### 7.1.5 SPECIF card

"The SPECIF card is used to describe load time I/O options for the designated file. SPECIF cards are not necessary for correct compilation … the user may elect to punch the required load time cards himself. … The SPECIF card(s) may appear anywhere within the environment division" ([J 02.06.07]).

General form ([J 02.06.07]):

```
Name    Type      Description

        SPECIF    file.name  [ ,UNIT1 'unit.1' ]  [ ,UNIT2 'unit.2' ]

                  [ ,{LOW}  ]   [ ,DEFER ]   [ ,OPENW ]   [ ,OPENF ]
                     {HIGH}

                  [ ,{CLOSER} ]   [ ,ACTIVITY nn ]   [ ,{CHECKC} ]   [ ,MULTI ]
                     {CLOSEW}                            {CHECKF}

                  [ ,SEQ ]   [ ,CKSUMS ]

                  [ ,{LABELS} ]   [ ,SERIAL 'ser.no' ]   [ ,REEL 'reel.no' ]
                     {LABELN}

                                [ ,RETAIN days ]   [ ,{HIGH} ]
                                                       {LOW}
```

- **file.name** — "must be the first item of the SPECIF card description field. It must be identical with the file.name in the FILE card" ([J 02.06.08]).

**UNIT1 'unit.1' / UNIT2 'unit.2'** — "Note that the Quote Marks are mandatory." The alphameric literals specify symbolically the I/O units (card or tape) to which the file is attached: relative unit assignment, symbolic channels, and tape transport model type. UNIT2 assigns the secondary reel of a multi-reel file, automatically referenced upon a reel switch; "If UNIT2 is left blank, the secondary unit assignment will be the same as the primary unit" ([J 02.06.08]). Notation ([J 02.06.08]):

| Symbol | Meaning |
|---|---|
| X | one of the real channels A,B,…,H |
| P | a symbolic (unspecified physical) channel S,T,…,Z |
| k | one of the numbers 1,…,9,0 |
| m | a tape transport model number, II or IV |

Allowable unit specifications ([J 02.06.08]–02.06.09):

| Form | Meaning |
|---|---|
| *(none)* | any available unit is assigned |
| `'m'` | any available unit of this model type |
| `'X'` | any available unit on this physical channel |
| `'P'` | all files in the job with this symbolic channel designation are assigned to the same channel |
| `'X(k)'` | the kth available unit on the specified channel; "the parenthesis are required" |
| `'Pm'` | any available unit of this model type on the symbolic channel |
| `'Pkm'` | an available unit on the symbolic channel, having this model number; *k* without parenthesis is the order of preference for the channel (lower numbers assigned to the same channel first when units are scarce) |
| `'IN'` | the current system Input unit contains the file |
| `'OU'` | the current system Output unit, for a printed output file |
| `'PP'` | the current system Peripheral Punch unit, for a punch output file |
| `'UTk'` | System utility tape k (non-parenthesized k = 1–4) |
| `'RDX'` | card reader, channel X |
| `'PRX'` | printer, channel X |
| `'PUX'` | card punch, channel X |
| `*` in UNIT2 | secondary unit is any unit on the same channel and of the same model type available after all other assignments; at load time a different-model unit may be substituted, or no secondary unit assigned if none available ([J 02.06.09]) |

Examples: first available unit on channel A: `, UNIT1 'A(1)'`; system output tape: `, UNIT1 'OU'` — "Note, that in this case (also for 'IN') included options for density, opening and closing are non-effective" ([J 02.06.10]). Further unit-assignment information is in Loader section 03 ([J 02.06.10]).

Restrictions ([J 90.01.04]): "Absolute tape assignment cannot be made; symbolic and relative assignment techniques are used." "Unless system utility tapes (UTk) are explicitly designated the drives assigned to them are not used at execution time as object program units."

Remaining options ([J 02.06.10] – 02.06.12):

| Option | Meaning | Default if absent |
|---|---|---|
| LOW / HIGH (first occurrence) | density of the tape | **HIGH** ([J 02.06.10]) |
| DEFER | file not required when processing begins | file must be mounted before program processing commences ([J 02.06.10]) |
| OPENW | do not rewind before opening | file rewound prior to being opened ([J 02.06.10]) |
| OPENF | this standard labeled file is found on a multi-file reel by searching forward on labels; without OPENW the tape is rewound before searching. With OPENW+OPENF the programmer must insure (1) the tape is positioned before a header label and (2) the labeled file sought is further down the tape ([J 02.06.10]) | no forward search |
| CLOSER / CLOSEW | CLOSER: file only rewound upon closing; CLOSEW: file not rewound upon closing ([J 02.06.10]) | rewind **and unload** on close ([J 02.04.06]; [J 90.08.02] codes this default "U") |
| ACTIVITY nn | nn = 1–99, relative activity (usage) of this file, used by the loading-time program in allocating buffer areas ([J 02.06.11]) | — |
| CHECKC / CHECKF | CHECKC: checkpoint written on the checkpoint file upon reel switch of this file. CHECKF: checkpoint written on this file upon reel switch — "the file must be a labeled output file for this option to be operative" ([J 02.06.11]) | "No check point will be written if neither option is exercised" |
| MULTI | tape file contained in more than one reel | "A single reel file is assumed" ([J 02.06.11]) |
| SEQ | each block contains a block sequence number to be checked by the I/O system ([J 02.06.11]) | no sequence check ([J 02.07.06]) |
| CKSUMS | each block carries a checksum of data to be checked by the I/O system ([J 02.06.11]) | no checksum check ([J 02.07.06]) |
| LABELS / LABELN | LABELS: standard label, "checked or written automatically by IOCS." LABELN: non-standard label — "a label of 14 words or less which is to be checked by the programmer using a linkage supplied by the FOR LABEL option of the Environment FILE card." "Either LABELS or LABELN must be explicitly stated if labels are to be recognized by IOCS" ([J 02.06.11]) | "the file is considered to be unlabeled" |
| SERIAL 'ser.no' | alphameric literal of 5 or less characters. Standard input labels checked against it if non-blank; standard output labels contain it only if REEL specifies a 'reel.no' greater than 1 — "output serial numbers are normally taken from the label already present on the tape on which the first reel of the file is written" ([J 02.06.12]; "lables" sic) | — |
| REEL 'reel.no' | alphameric literal of 4 or less numeric characters: reel sequence number of the first reel; "adjusted at object time to reflect reel switching, and is checked in standard input labels" ([J 02.06.12]) | assumed to be **1** |
| RETAIN days | numeric literal of 3 or less numeric characters: days the tape is retained from the date written. Writing a labeled file on the tape before expiry produces an on-line IOCS error. "Unless a labeled file is to be written on a tape, the system assumes that no label is present on the tape" ([J 02.06.12]) | — |
| HIGH / LOW (after LABELS/LABELN) | density of the label. "Label dinsity is assumed to be that of the file if no specification is made" ([J 02.06.12]; "dinsity" sic) | file density |

SERIAL, REEL and RETAIN may be given for standard or non-standard labels; the information is kept in the IOCS file block, printed on-line in certain error situations, used by IOCS for standard labels only, and available to the programmer for non-standard label handling ([J 02.06.12]).

#### 7.1.6 POOL card

The POOL card lets certain files share a common buffer area; optional. "If POOL specifications are not provided at all, files will be grouped automatically by IOCS," and the information may alternatively be entered on an object-time loading card ([J 02.06.13]).

General form ([J 02.06.13]):

```
Name        Type    Description

pool.name   POOL    file.name.1   [file.name.2.....]

                    [, BUFFERCOUNT nn]

                    [, BLOCKSIZE nn]
```

- **BUFFERCOUNT nn** — nn buffers assigned to the files in the pool by the loading program. "nn must be equal to or greater than the number of files in the pool"; when GROUP cards are used, nn must be equal to or greater than the total number of buffers assigned to groups within the pool. Default: "it will be assigned automatically by the compiler" ([J 02.06.13]).
- **BLOCKSIZE nn** — words allocated to each buffer in the POOL; "should be equal to or greater than the largest BLOCKSIZE specified for any file in the pool." Default: "the POOL BLOCKSIZE used will be the same as the BLOCKSIZE of the largest file in the POOL" ([J 02.06.13]). A numeric integer must follow BLOCKSIZE (error 162,00, [J 90.04]).

#### 7.1.7 GROUP card

Used in conjunction with a POOL card to specify how buffers within a POOL are shared; optional. "If GROUP specifications are not made at all, the compiler will attempt to assign at least 2 buffers to each file" ([J 02.06.13]–02.06.14).

General form ([J 02.06.14]):

```
Name    Type     Description

        GROUP    [pool.name]

                 [, OPENCOUNT nn]

                 [, BUFFERCOUNT nn]

                 , file.name.1   [, file.name.2.....]
```

- **pool.name** — "The POOL to which a particular GROUP of files belongs must be specified by listing the pool.name as the first item in the variable field" ([J 02.06.14]).
- **OPENCOUNT nn** — maximum number of files within the group that may be open concurrently during execution; determines the minimum buffer count for the GROUP. Default: "assumed equal to the number of files in the GROUP" ([J 02.06.14]).
- **BUFFERCOUNT nn** — buffers assigned by the loader to this GROUP; must be ≥ the GROUP's OPENCOUNT. Default: "the loader will attempt to assign at least twice the OPENCOUNT number of buffers to the GROUP." If POOL BUFFERCOUNT or storage limitations prevent this, buffers beyond the minimum are allocated "on the basis of the activity of the files in the GROUP" ([J 02.06.14]) — cf. SPECIF ACTIVITY (§7.1.5).

#### 7.1.8 CONTRL card — inter-program areas (deferred)

"The CONTRL cards define procedure and/or data areas common to two or more Commercial Translator programs. These programs may be compiled and checked out independently and then merged at object loading time into one running program" ([J 02.06.15]).

General form ([J 02.06.15]):

```
Name     Type      Description

loadnm   CONTRL    { section.name
                     sentence.name.1   TO   sentence.name.2
                     record.name }
```

- **loadnm** — "a name of 6 characters or less which is used at object load time to equate areas in various programs. … This load time reference name must have been specified on a CONTRL card in each program referring to the area. The body of the CONTRL area may contain entirely different names in the various programs being combined" ([J 02.06.15]; also error 207,00: "-CONTRL- NAME MUST BE UNIQUE AND 6 CHARACTERS OR LESS", [J 90.04]).
- In the form `sentence.name.1 TO sentence.name.2`, "the area defined will not include any of sentence.name.2" ([J 02.06.15]).

Restrictions ([J 02.06.15]–02.06.16):

- a) CONTRL areas defined by the Data Description must begin with left justification.
- b) References from outside a CONTRL area to names inside it are valid only if the referenced name has the same bit displacement from the beginning of the area in all programs merged, and the same format in all programs merged. Hence data-defined areas "should be identical in organization and format up to and including the last externally referenced item," and procedure-defined areas identical up to and including the last externally referenced statement name; if only the section/beginning sentence name is referenced externally, no internal correspondence is necessary.
- c) "Indices inside a CONTRL area must not be referenced or modified outside of that area in any of the programs to be merged."

**Deferral ([J 90.01.04]):** "Mechanization of multiple deck combination has been deferred. CONTRL specifications will have no effect on the object deck produced by the Compiler, i.e., no control break table is punched." Correspondingly, "The control break table is not processed by the loader. This implies that multiple program loading with cross references by means of control breaks is not available" ([J 90.01.05]). (The object-deck layout still reserves a Control Break Table position — [J 02.02]; see the object-deck section.) The compiler nonetheless diagnoses CONTRL card format errors (176,00, [J 90.04]).

#### 7.1.9 OPTION card — collating sequence and space/time conservation

"OPTION cards may be used to set compilation mode switches within the compiler" ([J 02.06.16]). The compiler normally generates comparison instructions based on the 709/7090 collating sequence and an object program "conservative of time rather than space"; the OPTION card selects the Commercial (705) collating sequence and/or a time- or space-conservative object program ([J 02.06.16]).

General form ([J 02.06.16]):

```
Name   Type     Description

       OPTION   [COLLATE COM]                 [IN section.name]

                [, CONSERVE {SPACE}]           [IN section.name]
                            {TIME }
```

- **COLLATE COM** — "instructs the compiler to generate comparison type instructions on the basis of the Commercial collating sequence" ([J 02.06.16]).
- **CONSERVE SPACE** — object program uses as few storage locations as possible; subroutines are generated once for operations such as scaling and double-precision arithmetic, with in-line calling sequences ([J 02.06.16]).
- **CONSERVE TIME** — minimum execution time via in-line instructions. "This is the normal mode of operation" ([J 02.06.17]).
- **IN section.name** — usable with either CONSERVE or COLLATE; limits the modal specification to a particular section, reverting to the normal mode at the section's end. "There is no restriction on the number of times these modes may be altered" ([J 02.06.17]).

The two collating sequences, lowest to highest ([J 02.06.16]; scan-resolved reading — glyph legend and details in §1.1):

```
709/7090:    0 through 9   =   '   +   A through I   ⟨+0⟩   .   )   −   J through R   ⟨−0⟩   $   *   blank   /   S through Z   ⟨rm⟩   ,   (
```

```
Commercial (705):  Blank   .   ⟨loz⟩   ⟨gm⟩   &   $   *   −   /   ,   %   #   @   ⟨+0⟩   A through I   ⟨−0⟩   J through R   ⟨rm⟩   S through Z   0 through 9
```

COLLATE COM also changes the figurative constants: HIGH.VALUE is `(` and LOW.VALUE is `0` under the 709/7090 sequence; under COM, HIGH.VALUE is `9` and LOW.VALUE is blank ([J 02.04.01]; see §2/§4 on figurative constants).

#### 7.1.10 COND card — console entry keys

"The COND card defines a computer console entry keys setting which may be interrogated by procedure statements" ([J 02.06.17]).

General form ([J 02.06.17]):

```
Name             Type    Description

condition.name   COND    KEYS 'nn'
```

"The alphameric literal 'nn' is composed of 12 octal digits representing 'on' settings of the 36 console entry keys. When the condition.name is tested in a procedure statement only the keys specified in 'nn' are tested for 'on' setting. The specified console keys must all be 'on' for the condition to be true. No 'off' or 'on' test is made for the non-specified keys. Note that Data Description condition.names are tested differently, i.e., for absolute equivalence to the specified value" ([J 02.06.17]).

Compiler behavior on malformed COND cards ([J 90.04]): key setting exceeding 12 digits — rightmost 12 digits used (error 6,00); non-octal key setting — key setting '1' used (error 7,00); format error — 4,00; missing name in columns 7–22 — 88,00.

Do not confuse this Environment COND card with the Data Description type code COND (condition values of a conditional variable; see §3).

#### 7.1.11 Environment cards → Loader symbolic control cards ([J 90.08])

The Compiler turns Environment FILE/SPECIF information into Loader \*FILE and \*SPEC symbolic control cards ([J 90.08.01]–90.08.02). Key mappings a compiler writer needs (full field tables at [J 90.08.01]/90.08.02):

- \*FILE card, by option (the card's column-by-column layout is deck-format detail left to [J 90.08.01]): deck.name from $CMPLE; tape-mounting indicator blank if DEFER specified, `*` if not; unit1/unit2 from SPECIF UNIT1/UNIT2; file type I = input, T = total block output (OUTPUT,SPANS), P = partial block output (OUTPUT); reel control L = label searched on labeled open file (OPENF + LABELS/LABELN), M = multi-reel unlabeled (MULTI); density H/L; file mode D (BCD) / B (binary); label density H/L/S (same as file); SEQ; CKSUMS; checkpoint conventions C on the checkpoint file (source printed as "FILE CHECKPOINT AND SPECIF CHKS") or F on a specified file (FILE OUTPUT + SPECIF CHECKF + LABELS/LABELN); first reel sequence (REEL); file serial (SERIAL); retention days (RETAIN); file name ([J 90.08.01]).
- \*SPEC card, by option: blocksize from FILE BLOCKSIZE; activity from SPECIF ACTIVITY; opening conventions N without rewind (OPENW), R or blank with rewind otherwise; closing conventions N (CLOSEW), R or blank (CLOSER), **U — with rewind and unload — when neither CLOSEW nor CLOSER specified** ([J 90.08.02]).

CLOSE ALL FILES closes each open file according to these \*SPEC close options; "In the absence of specification, closing includes a rewind and unload of the unit. Files closed by this form of the CLOSE command may not be subsequently reopened by the program" ([J 02.04.06] — note that page cites the SPECIF card as "Section 02.07"; it is actually defined at [J 02.06.07]). STOP RUN closes all open files as if CLOSE ALL FILES had been supplied ([J 02.04.06]).

### 7.2 Compiler control cards ($CMPLE, *FINISH) ([J 02.01])

These cards are part of every source deck and are the compiler's source-visible control surface. They exist only in J; F has no counterpart.

#### 7.2.1 $CMPLE card

"A $CMPLE card must precede each source language program. It is recognized by the Commercial Translator Monitor (CTM) for purposes of operational control and interpreted by the … compiler to initiate processing of source language statements" ([J 02.01.01]).

General form ([J 02.01.01]):

```
1  -  6      8  -  13       16
$CMPLE       deck.name      [NODECK]        [,LIST]         [,DICT]
                            [,LOAD]         [,LOGIC]        [,FILES]
                            [,MAP]          [,NOGO]

             55        -        72
             [secondary.identifier]
```

- **deck.name** — "the primary deck identifier composed of six or less characters chosen from the set appropriate for use in CT names. The name may begin in any of the positions but must not include imbedded blanks. Leading blanks are ignored by the compiler." The complete deck.name is punched in columns 1–6 of all Loader symbolic control cards in the generated object deck for cross-referencing when multiple decks are combined at load time ([J 02.01.01]). Pitfall: "The Compiler accepts without comment a deck.name containing imbedded blanks and punches it in Loader symbolic control cards. A deck.name of this form is not acceptable to the Loader and will prevent execution of the object program" ([J 90.01.05]).
- **Option list syntax** — "The options used must not be separated by blanks as the first blank terminates the list of options. The options must be separated only by commas" ([J 02.01.01]).
- **NODECK** — omit punching of an object deck. "Normally, an output deck is produced except when a severe error has been encountered during compilation. … If the severity code is 5, a deck will not be produced" ([J 02.01.01]; severity codes: see J Appendix 90.04 / the diagnostics section).
- **LIST** — produce a symbolic listing of the generated instructions. "Normal compiler action produces no symbolic list" ([J 02.01.01]).
- **DICT** — "list the dictionary giving the relative locations of all names used in the object program. Normally a dictionary is not listed" ([J 02.01.01]).
- **LOAD** — write the object program on a system utility tape and turn control over to the Loader after compilation. A map is produced if LOGIC was specified. "The program will be executed unless the NOGO option has been taken, or the Compiler has encountered a source program error with a severity code greater than 1 or an undefined symbol in the code which it has generated" ([J 02.01.02]).
- **LOGIC** — Loader lists "the origin and extent of all program sections, system subroutines required for execution (including IOCS) and buffer assignments." LOGIC automatically initiates LOAD; unless NOGO is specified the program is also executed ([J 02.01.02]).
- **FILES** — a list of the I/O unit assignments made by the Loader is output on SYSOU1 "whether or not the program is to be executed" ([J 02.01.02]).
- **MAP** — "an option yet to be specified for obtaining additional load-time information" ([J 02.01.02]).
- **NOGO** — Loader does not allow execution after loading; "does not inhibit the LOGIC and FILES options" ([J 02.01.02]).
- **secondary.identifier** (columns 55–72) — identifying information printed in the heading of the output listing on SYSOU1 and punched in the \*CTEND Loader control card. "Any character may be used in any of the positions" ([J 02.01.02]).

#### 7.2.2 *FINISH card

"The *FINISH card delimits the extent of the source language statements to be compiled" ([J 02.01.02]):

```
7
*FINISH
```

"Note that this card must be followed by an end of file (see 04.02 and 05.03)" ([J 02.01.02]). In the stacked-job deck, "This card precedes end-of-file on COMPILE jobs" ([J 05.03]).

Related deck-level facts a compiler writer should know ([J 02.02], [J 02.03.01]): normal output is a relocatable column-binary deck (symbolic control cards, \*CTEXT, relative binary program deck with Control Break Table / File Check Table / Text, \*CTEND — see the object-deck section, [J 90.03]); the listing assigns statement numbers of the form xxxxx,00 (clause number after the comma; 9999,99 references errors not confined to a single statement); and "Card serial numbers in columns 1-6 of source decks are not sequence checked by the compiler" ([J 02.03.01]). **F/J divergence:** F states serial numbers "will be sequence-checked by the processor" ([F p. 37]).

### 7.3 The library system — COPY, LIBRARY, INCLUDE (F design; deferred in J)

#### 7.3.1 The library concept (F)

F envisions a program library holding both procedure and data descriptions. On the procedure side: "If such a routine has been stored in a 'library,' the programmer may be able to call for it by using the verb INCLUDE … This verb, therefore, may be used in building the object program, but it will not be used as a part of the object program itself" ([F p. 12]). On the data side: "the data description can actually be stored in the library, on tape or in cards, so that it can be called for when needed" ([F p. 62]). No physical library format or maintenance utility is defined in either manual.

**J status:** "Mechanization of the INCLUDE verb has been deferred, and consequently no library facilities are currently available" ([J 90.01.02]). "Implementation of COPY has been deferred" ([J 90.01.03]). The compiler diagnoses: "-COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM." (error 110,00, [J 90.04] — the listing's CODE column prints 0 only as a placeholder; the actual severity 1–5 printed with the message is unspecified) — so the 1962 compiler *recognizes* these constructs and diagnoses them, rather than treating them as undefined. INCLUDE and LIBRARY remain reserved (they may not be used as Data or Procedure names, [J 02.03.02]).

#### 7.3.2 The INCLUDE command (F only)

"The INCLUDE command causes the processor to extract a unit of procedure from the library and to insert it in the present program" ([F p. 58]). Basic forms ([F p. 58]):

```
INCLUDE library.procedure
INCLUDE HERE library.procedure
```

- The "library.procedure" may be either a sentence or a section of procedure filed in the library under that name. The first form places the procedure "at the end of the present program" — normally used for closed subroutines addressed by DO commands, which must be set off from the main flow. INCLUDE HERE inserts the procedure "wherever the command appears" — for procedures used in line ([F p. 58]).
- **Renaming the procedure:** appending `. . . AS procedure.name` replaces all occurrences of the library procedure-name with the indicated name ([F p. 58]).
- **Name substitution within the procedure:** appending

```
. . . WITH new.name.1 FOR old.name.1, new.name.2 FOR
     old.name.2, ... new.name.n FOR old.name.n
```

replaces all occurrences of the old.names with the new.names, "done by the processor at the time the procedure is included" ([F p. 58]). Full consolidated general form ([F p. 109]):

```
INCLUDE [HERE] library.procedure [AS procedure.name] [WITH new.name.1 FOR
    old.name.1, new.name.2 FOR old.name.2, ... new.name.n FOR old.name.n]
```

- Name substitution (processing-time, via INCLUDE) is distinct from *data substitution* (object-time, via DO … USING/GIVING) ([F p. 52]).
- Placement rule: INCLUDE, like other processor commands, should be written as an unnamed sentence; "It is perfectly logical … to use INCLUDE HERE following a program command as long as the preceding sentence logically leads to the first sentence of the procedure being included" ([F p. 60]).

#### 7.3.3 The COPY type code ([F pp. 76–77]; deferred in J)

"This type code is used to copy a data description previously defined in the program so that it can be used again elsewhere," with a new name and, if desired, new level numbers ([F p. 76]). Usage: the new name goes in the Data Name columns, COPY in the Type columns, and the original name in the Description columns. "This description must already have been read into the system for the COPY code to be able to operate on it" ([F p. 76]).

The processor copies the original description in its entirety except: (1) the original name is replaced by the new name; (2) if a new level number is specified, all subordinate level numbers are adjusted to retain their original relationship — e.g. an original sequence 01, 03, 04 copied at level 05 becomes 05, 07, 08 ([F p. 76]). Worked example ([F pp. 76–77]): `PAY.RCD.DETAIL  02  COPY  … PAY.RCD.MASTER` expands the whole PAY.RCD.MASTER hierarchy under the new name with levels 02/03/04.

#### 7.3.4 Library names in the Description columns (F only)

The Description columns (38–71) of a data description entry may contain, among other things, "Data names associated with the type codes REDEF and COPY" and "The word LIBRARY, followed by the name of a data description stored in the library"; when several kinds of information appear on one line they must be written in the prescribed order, separated by one or more blanks ([F p. 79]). "The word LIBRARY, followed by the name of a data description stored in the library, designates a data description which is to be copied. … When a library data description is prescribed, the type code COPY must be used" ([F p. 81]).

In F's reserved-word list, COND, COPY, FUNCT, LABEL, LIBRARY, PARAM, QUANTITY and REDEF are daggered: "These words have a restricted usage only in data description; they may be used freely in procedure description" ([F p. 110]). In J, LIBRARY (but not COPY) appears in the key-word list of words that "may not be used as Data or Procedure names" ([J 02.03.02]); type codes are recognized positionally in the Type columns.

### 7.4 Program segmentation — OVERLAP and LOAD (F design; deferred in J)

**J status:** "Implementation of these verbs [LOAD and OVERLAP] has been deferred" ([J 90.01.03]); "Deferred implementation of the LOAD-OVERLAP verbs implies that programs may not be segmented into separate memory loads at this time" ([J 90.01.05]). Both remain reserved words in J ([J 02.03.02]). The following is the F design.

#### 7.4.1 OVERLAP (processor command)

"An object program … is organized as one loading of storage unless the programmer specifies otherwise by means of the OVERLAP command. This command designates portions of the program that are to occupy (at different times) the same area in internal storage" ([F p. 55]). General form ([F p. 55]):

```
OVERLAP procedure.name.1, procedure.name.2, ...
     procedure.name.n
```

Rules and object-program organization ([F pp. 55–56]):

- The processor sets aside an area large enough to accommodate the longest named procedure; when a shorter procedure is loaded over a longer one, not all of the earlier procedure is erased — "Accordingly, all overlapped procedures should have an unconditional GO TO as the last command."
- Loading an overlapped procedure does not execute it; a GO TO or DO must transfer control to it. "Also, care should be taken to insure that a LOAD command does not appear within the procedure it obliterates."
- 1. The initial loading of storage includes all parts of the program not mentioned in any OVERLAP, plus *the first procedure named in each OVERLAP command*. 2. Procedures not in the initial loading may be called in by a LOAD command. 3. An obliterated procedure may be retrieved *in its original form* by another LOAD command.
- A procedure named in OVERLAP may be a named sentence; procedures of more than one sentence must be made sections with BEGIN SECTION/END in order to be named ([F p. 56]; see §2 and [F p. 56]'s HOUSEKEEPING/MAIN.ROUTINE example, in which `SUPERVISOR.1. LOAD MAIN.ROUTINE, GO TO MAIN.ROUTINE.` sits outside the overlapped sections and `OVERLAP HOUSEKEEPING, MAIN.ROUTINE.` is written elsewhere, "probably included with the other processor commands").
- DO, LOAD and OVERLAP are the commands that exploit the BEGIN SECTION/END facility ([F p. 57]).

#### 7.4.2 LOAD (program command)

General form ([F p. 54]):

```
LOAD procedure.name
```

"procedure.name" is a portion of the program which, at object time, will be waiting in external storage; LOAD brings it into the area shared by the procedures of the associated OVERLAP command, replacing (retrievably) the previous occupant. "Any unit of procedure addressed by a LOAD command must be named in an OVERLAP command" ([F p. 54]).

Note the F/J structural distinction: LOAD is a *program* verb (miscellaneous category, with DISPLAY), OVERLAP a *processor* verb ([F p. 35]).

### 7.5 Renaming and linkage — CALL, ENTER, CONTRL

#### 7.5.1 CALL (processor command)

"The CALL command is used to specify alternate names, or synonyms, for previously defined names" ([F p. 59]). General form ([F p. 59]):

```
CALL (old.name.1) new.name.1, (old.name.2) new.name.2, ...
     (old.name.n) new.name.n
```

- "Synonyms are useful as abbreviations for often used names and as a means of communication between parts of a program, written by different programmers, that must refer to common areas of data. Data, work areas, and constants are capable of being named and thus may be renamed by means of this command" ([F p. 59]).
- "Synonyms must always be single names rather than compound names. A synonym may be applied to a compound name, however," e.g. `CALL (DEPARTMENT.TOTAL HOURS) DEPT.HRS.` ([F p. 59]).

J amplifications and restrictions:

- "The (old.name) in a CALL statement must be unique and may not be subscripted. This requirement is met if the (old.name) appears only once in the Data Description or if sufficient qualifiers are used to identify it uniquely. The use of record.names should be avoided in CALL statements" ([J 02.04.05]).
- Subscripts in the (old.name) are erroneous: both `CALL (A(J))B.` and `CALL (A(3))B.` are given as incorrect ([J 90.01.01]).
- CALL's principal implemented role: reducing a qualified (compound) name to a one-word name so it can be referenced in the Environment Description or in CRYPT instructions, where qualified names are forbidden ([J 02.03.03]; [J 90.01.01]; [J 02.08.02]).

#### 7.5.2 ENTER — entering another language

F design: "The ENTER command instructs the processor to accept statements in another language" ([F p. 59]):

```
ENTER coding.language
```

"To revert to the Commercial Translator language, another ENTER command is required, specifically: ENTER COMMERCIAL TRANSLATOR." Details of the particular symbolic languages were left to the processor publications ([F p. 59]).

**F/J divergence — implemented forms:** "There are only two forms which this command may take: ENTER CRYPT and ENTER COMMERCIAL TRANSLATOR. The first form signals the processor that the following instructions are to be processed by CRYPT, the SCAT-like machine symbolic assembler of Commercial Translator. The second form … terminates the processing of CRYPT instructions and signals that Commercial Translator statements follow" ([J 02.04.02.01]). No other coding language can be entered in the 709/7090 implementation; there is no other inter-language linkage facility at the language level. (System subroutines such as IOCS are linked automatically by the Loader — cf. the LOGIC option, [J 02.01.02].)

The returning form is punched with ENTER as an operation code and COMMERCIAL TRANSLATOR as a variable-field entry beginning in column 16 of the SHARE coding form ([J 02.08.03]).

#### 7.5.3 Inter-program linkage

Language-level linkage between separately compiled COMTRAN programs is the CONTRL card mechanism (§7.1.8) — common procedure/data areas equated at load time via a 6-character loadnm — and it is deferred in J ([J 90.01.04]). Parameter passing at the language level exists only *within* a program, via DO … USING/GIVING and BEGIN SECTION USING … GIVING ([F pp. 57–58]; see §4, Procedure description). The associated Data Description type codes PARAM and FUNCT "are no longer in the language" in J ([J 02.05.03]) — a further F/J divergence.

### 7.6 Commentary conventions — NOTE and the period-blank rule

"The NOTE command enables the programmer to place explanatory information in the listing of the program" ([F p. 59]). General form ([F p. 59]):

```
NOTE any sentence.
```

- "This command affects only the program listing, not the program itself. The sentence introduced by NOTE will not produce instructions in the object program. Any combination of characters from the allowable character set may be placed after the verb NOTE. … The NOTE command is terminated by the first period that is followed by a blank" ([F p. 59]). Examples: `NOTE START OF MERGE 1.` ([F p. 59]), `NOTE INVENTORY RECORD MAINTENANCE.` ([F p. 8]).
- Like other processor commands (except BEGIN SECTION and END), NOTE should be written as an unnamed sentence, so no program command can transfer control to it ([F p. 60]). Processor and program commands may not be intermixed within one sentence — `IF A = B THEN … OTHERWISE OVERLAP …` is meaningless ([F p. 60]).
- NOTE is reserved: it may not be used as a Data or Procedure name ([J 02.03.02]; [F p. 110]).

Additional commentary channel in J: "Procedure statements are terminated by the first period (.) followed by a blank. Any information following this period blank is considered to be commentary" ([J 02.03.01]); a period-blank "terminates analysis of the statement except when they appear within an alphabetic literal; any information in the same card which follows the period is assumed to be commentary. No diagnostic comment is made" ([J 90.01.03]). The period-blank terminator is *not* used in the Data and Environment divisions ([J 02.03.02]; [J 02.06.02]).

### 7.7 The CRYPT facility — 709/7090 machine symbolic language ([J 02.08])

CRYPT exists only in J; F merely promises access to "the symbolic 'one-for-one' language of the particular machine system" via ENTER ([F p. 59]).

#### 7.7.1 What it is and where it may appear

"The 709/7090 Commercial Translator System provides the programmer with the ability to include symbolic machine language instructions and data description at any logical point in his program. The procedure command, 'ENTER CRYPT' signals the System that the ensuing source statements are in symbolic machine language form. The object instructions generated from these statements will be located immediately following the last word generated from the preceding Commercial Translator statement. The symbolic machine language acceptable to the system is similar to SCAT, with several restrictions and some additional flexibility. The standard SHARE 709/7090 coding form is used for CRYPT statements" ([J 02.08.01]). Compilation of CRYPT is part of the compiler's normal input alongside the three divisions ([J 02.00.00]). Processing of CRYPT instructions is terminated by ENTER COMMERCIAL TRANSLATOR ([J 02.08.03]; §7.5.2).

#### 7.7.2 CRYPT rules (restrictions relative to SCAT) ([J 02.08.01]–02.08.02)

1. The Commercial Translator special characters cannot be used as part of symbols; "The same rules which are applied to Commercial Translator names are applied to CRYPT names." Examples of illegal or specialized usage: `L(5)` is interpreted as the fifth element of array L; `.AB.` — a period may not be the first or last character of a symbol; `A'B)$` — quotation mark, left parenthesis, right parenthesis and dollar sign may not be part of a symbol ([J 02.08.01]).
2. "No SCAT macros are acceptable" ([J 02.08.01]).
3. Pseudo-ops usable: `OCT`, `PZE, etc. (both MZE and FOR sets)`, `EQU`, `BSS`, `BES`, `BCI` ([J 02.08.01]).
4. Pseudo-ops not usable: `HEAD`, `VFD`, `DEC`, `DUP`, `ORG`, `SYN`, `END` ([J 02.08.02]).
5. "Literals are not presently permitted in machine language" ([J 02.08.02]).
6. Qualified names may not be referenced by CRYPT instructions (`CLA MASTER NAME` is incorrect); CALL may be used to reduce a qualified name to a single unique name ([J 90.01.01]; [J 02.03.03]).

#### 7.7.3 Flexibility above SCAT ([J 02.08.02])

1. Names defined in the Commercial Translator sections may be referenced in the variable field, so variable-field names may contain up to 30 characters (compound names excepted — rename via CALL outside the CRYPT section).
2. Array elements are addressed through "Symbolic Registers": `CLA A(I,J)` is replaced by `CLA* SRAIJ`, where the Symbolic Register always contains the address of the element for the *present* values of I and J. "The system will not check for changes in component variables while in the machine language mode" — the Symbolic Register is not updated if the programmer changes I or J in CRYPT. "Also, indirect addressing is not permitted on the original operation."
3. Arithmetic expressions in the variable field may contain parentheses, e.g. `AXT A*(B + C),4`.
4. The Commercial Translator Data Description form serves for describing data and entering constants (no DEC/VFD needed).

#### 7.7.4 Generated-code caveats ([J 02.08.03])

References to fields of records processed in *locate* mode do not expand one-for-one. For `CLA DATE` where DATE is a field of a located record, the system generates:

```
LAC     BASE.LOCATOR.OF.DATE,4
TXL     SYS)294,4,0
CLA     DATE.DISP,4
```

where BASE.LOCATOR.OF.DATE holds the current origin of the record, SYS)294 is an error routine reporting an unset base locator, and DATE.DISP is the field's displacement within the record. "Note that the contents of index register 4 are destroyed, and that instructions have been inserted in the program. Care must be taken to avoid incorrect referencing when relative addressing using * to signify the location counter is used" ([J 02.08.03]). (Generated-code details: see the generated-code section, [J 90.02].)

### 7.8 F/J divergence summary for this section

| Feature | F28-8043 (June 1960) | J28-6169 (Jan 1962) — authoritative |
|---|---|---|
| Environment Description content | Division reserved (`*ENVIRONMENT`, [F p. 27]) but undefined; deferred to processor manuals ([F p. 71]) | Fully defined: FILE, SPECIF, POOL, GROUP, CONTRL, OPTION, COND cards ([J 02.06]) |
| Library facilities | INCLUDE, COPY, LIBRARY defined (F pp. 58, 76, 81) | All deferred; "no library facilities are currently available" ([J 90.01.02]–03; error 110,00, [J 90.04]) |
| LOAD / OVERLAP segmentation | Defined ([F pp. 54–56]) | Deferred; no segmented memory loads ([J 90.01.03], 90.01.05) |
| Multi-program combination (CONTRL) | Not in F | Defined ([J 02.06.15]) but mechanization deferred; no control break table punched or processed ([J 90.01.04]–05) |
| ENTER | `ENTER coding.language`, open-ended ([F p. 59]) | Exactly two forms: ENTER CRYPT, ENTER COMMERCIAL TRANSLATOR ([J 02.04.02.01]) |
| CRYPT | Not defined (implied by ENTER) | Fully defined SCAT-like assembler ([J 02.08]) |
| PARAM / FUNCT type codes | Defined ([F pp. 73]) | "no longer in the language" ([J 02.05.03]) |
| CALL | Synonyms for previously defined names ([F p. 59]) | Same, plus: old.name unique, no subscripts, avoid record.names ([J 02.04.05], 90.01.01) |
| NOTE | Defined ([F p. 59]) | Unchanged in substance; period-blank commentary rule amplified ([J 02.03.01], 90.01.03) |
| Serial-number sequence checking | "will be sequence-checked by the processor" ([F p. 37]) | "not sequence checked by the compiler" ([J 02.03.01]) |
| Compiler control cards | Not in F | $CMPLE, *FINISH ([J 02.01]) |
| Checkpoint facility | Not in F | FILE CHECKPOINT + SPECIF CHECKC/CHECKF ([J 02.06.04], 02.06.11) |

---

## 8. Known ambiguities, underspecified behaviour, and plausible resolutions

This section is the compiler writer's risk register. It collects (§8.2) the complete digest of J Appendix 90.01 — the master list of features deferred, removed, or restricted between the 1960 language and the 1962 processor; (§8.3) the direct contradictions between F28-8043 and J28-6169; (§8.4) the severity-code system and the language rules that can only be recovered from the compiler's error messages; and (§8.5) the consolidated catalog of genuine ambiguities and underspecified behaviour, each with the most historically plausible resolution. Questions the manuals cannot answer at all are listed at the end of the document under **Open questions**.

**Contents of this section**

- [8.1 Status of the sources](#81-status-of-the-sources)
- [8.2 The F→J delta: complete digest of J Appendix 90.01 (deferred features, restrictions, limitations)](#82-the-fj-delta-complete-digest-of-j-appendix-9001-deferred-features-restrictions-limitations)
  - [A.1 Procedure-language restrictions (J 90.01.01–90.01.03)](#a1-procedure-language-restrictions-j-900101900103)
  - [A.2 Data Description restrictions (J 90.01.03–90.01.04)](#a2-data-description-restrictions-j-900103900104)
  - [A.3 Environment Description restrictions (J 90.01.04)](#a3-environment-description-restrictions-j-900104)
  - [A.4 Internal table size limitations (J 90.01.05)](#a4-internal-table-size-limitations-j-900105)
  - [A.5 Loader restrictions (J 90.01.05, part B)](#a5-loader-restrictions-j-900105-part-b)
  - [A.6 Deferrals and removals recorded outside Appendix 90.01](#a6-deferrals-and-removals-recorded-outside-appendix-9001)
- [8.3 F28-8043 vs J28-6169: contradictions and divergences](#83-f28-8043-vs-j28-6169-contradictions-and-divergences)
- [8.4 The severity-code system and rules implied by the diagnostics (J Appendix 90.04)](#84-the-severity-code-system-and-rules-implied-by-the-diagnostics-j-appendix-9004)
  - [B.1 The severity-code system](#b1-the-severity-code-system)
  - [B.2 Implied language rules, message by message](#b2-implied-language-rules-message-by-message)
- [8.5 Consolidated ambiguity catalog, with plausible resolutions](#85-consolidated-ambiguity-catalog-with-plausible-resolutions)
  - [8.5.1 Lexical](#851-lexical)
  - [8.5.2 Program structure](#852-program-structure)
  - [8.5.3 Data description](#853-data-description)
  - [8.5.4 Arithmetic and data manipulation](#854-arithmetic-and-data-manipulation)
  - [8.5.5 Control flow](#855-control-flow)
  - [8.5.6 Input/output](#856-inputoutput)
  - [8.5.7 Environment, control cards, and processor surface](#857-environment-control-cards-and-processor-surface)
  - [8.5.8 Transcription and printing artifacts (conversion-level cautions)](#858-transcription-and-printing-artifacts-conversion-level-cautions)

### 8.1 Status of the sources

F28-8043's Preface states that environment-description rules and processor operation are deferred to "separate publications" (F Preface, PDF p. 6) — so for the Environment Description, J is not merely authoritative but the *only* source. J28-6169-1 documents the *field test* version of the 709/7090 processor: several restrictions in its Appendix 90.01 are explicitly scoped "for field test" / "by the field test processor" ([J 90.01.01]), its promised Appendix 90.07 (Sample Non Standard Label Processing) is marked "(Not Currently Available)" in its own contents (J 00.00), and its sample listing was produced by an October 1961 system whose control card (`*COMPILE`) differs from the documented `$CMPLE` (see §8.5). Both manuals therefore describe moving targets; J is the later and operationally definitive snapshot.

F Appendix 3 (Glossary, [F pp. 111–116]) was swept for this definition. It is definitional and largely redundant, with these normative exceptions folded in where relevant: ROUND and TRUNCATED ([F pp. 115–116] — the rounding rule, see §8.5.4), ALPHAMERIC ([F p. 111] — "an alphameric literal may not contain a quotation mark"), OPEN SUBROUTINE / CLOSED SUBROUTINE (F pp. 112, 114 — the terminology §5.5.5 relies on), SUBSCRIPT ([F p. 115] — the three legal subscript forms), and FLOATING POINT ([F p. 113]).

---

### 8.2 The F→J delta: complete digest of J Appendix 90.01 (deferred features, restrictions, limitations)

Everything below is from J Appendix 90.01 unless another citation is given. Section
90.01 is organized as: A. Compiler (1. Language — Procedure / Data Description /
Environment Description; 2. Internal table sizes) and B. Loader.

#### A.1 Procedure-language restrictions ([J 90.01.01]–90.01.03)

**Statements / verbs**

| Item | Restriction or deferral | Citation |
|---|---|---|
| CALL verb | Subscripts may not be used in specifying the (old.name). Both `CALL (A(J))B.` and `CALL (A(3))B.` are erroneous. | ([J 90.01.01]) |
| CRYPT | Qualified names may not be referenced by CRYPT instructions (e.g. `CLA MASTER NAME` is incorrect). "The verb CALL may be used to reduce a qualified name to a single unique name." | ([J 90.01.01]) |
| DISPLAY verb | "Data names not intended to be used as qualifiers must be separated by commas; otherwise all but the last will be disregarded." (Cross-ref §8.3 item 4 — this diverges from F's DISPLAY rules.) | ([J 90.01.01]) |
| GET verb | Card files processed on-line may only be BCD and fixed length **for field test**. | ([J 90.01.01]) |
| GET verb | All input records containing arrays are processed in the **transmit** mode by the field test processor — true for both fixed and variable length records. | ([J 90.01.01]) |
| GET verb | Records from different files which have been REDEF'd together will **not** be automatically transmitted by the field test processor (the automatic feature is described at [J 02.07.05] c-ii). SPANS or HOLD must be used. | ([J 90.01.01]) |
| INCLUDE verb | **Deferred.** "Mechanization of the INCLUDE verb has been deferred, and consequently no library facilities are currently available." | ([J 90.01.02]) |
| Indexing / DO | Repeated use of one subscript name for multiple purposes causes unnecessary re-evaluation of all positional indicators containing that subscript when it changes value — inefficient but "it will not be incorrect". | ([J 90.01.02]) |
| Indexing / DO | **The dimensions of an array must be set before calculation of subscript values associated with the array. "Presently, failure to observe this restriction causes invalid object code."** Worked example: `SET I = 3, SET J = 5. / SET Q = 10. / MOVE A (I,J) TO R.` is incorrect where Q holds the QUANTITY of A — the positional indicator for A(I,J) is computed when I and J are set and not updated when Q is set. When an array follows a variable-length array, the positional indicator is not updated when the base is determined; subscripts must be set prior to a subscripted reference to the array. | ([J 90.01.02]) |
| DO verb | "A DO section will always be performed at least once regardless of the values of the loop control variables." | ([J 90.01.02]) |
| Subscripting | "No object time check is made to insure that subscript references conform to the limits specified by the array dimensions in the Data Description." | ([J 90.01.02]) |
| MOVE verb | Figurative constants may not be moved to variable length arrays; they may be moved to fixed length arrays or to array elements. (Amplified at [J 02.04.01] c: MOVE BLANKS TO ARRAY illegal where ARRAY has QUANTITY IN; MOVE BLANKS TO FIELD(3) proper; also may not be moved to fields longer than 2^15 − 1 characters — see the catalog in §8.5 re messages 180/181.) | ([J 90.01.02]; [J 02.04.01]) |
| LOAD, OVERLAP verbs | **Deferred.** "Implementation of these verbs has been deferred." (Consequence for loader at B.2 below: no program segmentation into separate memory loads.) | ([J 90.01.03]) |
| Statement termination (misc.) | Procedure.names not followed by period-blank "are handled properly; no diagnostic message is given." A period followed by a blank in a procedure statement terminates analysis of the statement except within an alphabetic literal; anything on the same card after the period is assumed commentary — **no diagnostic comment is made**. | ([J 90.01.03]) |

#### A.2 Data Description restrictions ([J 90.01.03]–90.01.04)

| Item | Restriction or deferral | Citation |
|---|---|---|
| COPY type code | **Deferred.** "Implementation of COPY has been deferred." (Diagnostic 110 also covers LIBRARY: "-COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM.") | ([J 90.01.03]; [J 90.04.01]) |
| RECORD type code | A name with the RECORD type code must be unique. If the record is defined within a section, the section.name may not be used as a qualifier of the record.name. | ([J 90.01.03]) |
| RECORD type code | Since a quantity specification may not be made at the record level, record.names may not be subscripted. | ([J 90.01.03]) |
| REDEF type code | Whenever an input record containing an array is involved in a REDEF, the record containing the array should precede the REDEF for optimum results. "An area involved in a REDEF must not contain subscript variables or a QUANTITY.IN value." | ([J 90.01.03]) |
| Pictorials | A field may not be described as mixed numeric and alphameric (both A's and 9's in one pictorial). "If this specification is made the field is treated as alphameric." | ([J 90.01.03]) |
| Subscripting of data entries | Neither a data item (literal) nor a condition.name may be subscripted. A conditional variable **may** be subscripted. | ([J 90.01.03]) |
| Hierarchy layout | "Fields may not be defined following a variable length array as part of the same data hierarchy." | ([J 90.01.04]) |

#### A.3 Environment Description restrictions ([J 90.01.04])

| Item | Restriction or deferral | Citation |
|---|---|---|
| CONTRL card | **Deferred.** "Mechanization of multiple deck combination has been deferred. CONTRL specifications will have no effect on the object deck produced by the Compiler, i.e., no control break table is punched." (CONTRL syntax/rules remain documented at [J 02.06.15]–16.) | ([J 90.01.04]) |
| FILE card | "A maximum of 63 files may be described." (Enforced by diagnostic 193.) | ([J 90.01.04]; [J 90.04.01]) |
| FILE card | "No file check table is produced in the object deck." (The object-deck layout at [J 02.02.01] nonetheless lists a File Check Table slot; see 90.03 for deck format.) | ([J 90.01.04]) |
| FILE card | CARD, BINARY and locate/transmit mode restrictions are those given with the GET verb (A.1 above). | ([J 90.01.04]) |
| SPECIF card | "Absolute tape assignment cannot be made; symbolic and relative assignment techniques are used (see section 02.06)." | ([J 90.01.04]) |
| SPECIF card | Unless system utility tapes (UTk) are explicitly designated, the drives assigned to them are not used at execution time as object program units. | ([J 90.01.04]) |
| Environment generally | "Qualified names may not be used in the Environment Description." (Restated at [J 02.03.03] C: names in Environment and CRYPT must be one word; CALL reduces a qualified name to one word.) | ([J 90.01.04]; [J 02.03.03]) |

#### A.4 Internal table size limitations ([J 90.01.05])

Reproduced from the 90.01.05 table (header reads "Appox-Max Size" — sic; note these
are stated as *approximate* maxima):

| # | Limited quantity | Approx-max size |
|---|---|---:|
| a | Internal dictionary including all program names whether defined by the programmer or generated by the Compiler | 3500 |
| b | Number of SECTIONS | 35 |
| c | Number of different edited field formats | 35 |
| d | Number of base locators (for the field test version this is the number of located records) | 127 |
| e | Number of QUANTITY IN specifications | 25 |
| f | Depth of nested sections | 18 |
| g | Number of index expressions (a * VARIABLE ± b) | 50 |
| h | Number of positional indicators (each unique combination of array and subscript notation, e.g., A(I), A(I + 1) B(I) requires 3 positional indicators) | 90 |
| i | Number of array dimensions (explicit or implicit Quantity specifications) | 85 |
| j | Number of levels in a data hierarchy | 23 |
| k | Number of generated constants in the constant pool `-CP)+NN` | 500 |

(Item k's `-CP)+NN` is printed exactly so; scan check 2026-08-01 resolves it — the
mark is a plain hyphen, a dash introducing the notation `CP)+NN`, the manual's own
generated-name form ("SYM)NNN", [J 90.02.03]), which has no opening parenthesis.
See §8.5.8.) ([J 90.01.05])

Overflow of these tables is reported at compile time by diagnostics 148, 149, 172,
177, 183, 184, 200–205 (see §8.4).

#### A.5 Loader restrictions ([J 90.01.05], part B)

1. The control break table is not processed by the loader — multiple program loading
   with cross references by means of control breaks is not available. ([J 90.01.05])
2. Deferred implementation of the LOAD-OVERLAP verbs implies that programs may not be
   segmented into separate memory loads at this time. ([J 90.01.05])
3. "No debugging facilities are currently available." ([J 90.01.05])
4. Normally the MINIMUM module of IOCS is used with the object program; if checkpoints
   are desired or specified, BASIC IOCS is used; if labeling exists, the LABELS version
   of IOCS is necessary. ([J 90.01.05])
5. **Trap for the compiler writer:** "The Compiler accepts without comment a deck.name
   containing imbedded blanks and punches it in Loader symbolic control cards. A
   deck.name of this form is not acceptable to the Loader and will prevent execution of
   the object program." (Contrast the $CMPLE rule that deck.name "must not include
   imbedded blanks", J 02.01.01.) (J 90.01.05)

#### A.6 Deferrals and removals recorded outside Appendix 90.01

These belong in the same master delta list but appear elsewhere in J:

| Item | Statement | Citation |
|---|---|---|
| PARAM and FUNCT type codes | "These two type codes described in the General Information Manual are no longer in the language." (Removal, not deferral — see §8.3 item 1.) | ([J 02.05.03]) |
| CRYPT VFD pseudo-op | Listed among pseudo-ops which "may not be used" (with HEAD, DEC, DUP, ORG, SYN, END); diagnostic 151 phrases it as "VFD IS NOT YET HANDLED BY SYSTEM." (only-permitted pseudo-ops: OCT, PZE etc. (both MZE and FOR sets), EQU, BSS, BES, BCI) | ([J 02.08.02], forbidden list; [J 02.08.01], permitted list; [J 90.04.01]) |
| CRYPT literals | "Literals are not presently permitted in machine language." | ([J 02.08.02]) |
| CRYPT macros | "No SCAT macros are acceptable." | ([J 02.08.01]) |
| $CMPLE MAP option | "[,MAP] is an option yet to be specified for obtaining additional load-time information." | ([J 02.01.02]) |
| Appendix 90.07 | "SAMPLE NON STANDARD LABEL PROCESSING (Not Currently Available)" — the appendix that both the LABEL type code ([J 02.05.03]) and the FOR LABEL FILE option ([J 02.06.05]) refer the reader to does not exist in this edition. | (J 00.00, contents) |
| Environment types | Diagnostic 90 "THIS ENVIRONMENT TYPE NOT YET PROCESSED BY COMPILER." implies at least one of the seven environment card types was unimplemented at field test (CONTRL is the documented case, per A.3). | ([J 90.04.01]; [J 90.01.04]) |
| GET on unopened file | "If the file is not open and a GET command is given, the end of file exit is taken. No error message is given." (Silent runtime behavior.) | ([J 02.07.04]) |
| FILE on unopened/closed file | "the command acts as a NOP. No error message is given." | ([J 02.07.08]) |
| Located records before first GET | References to fields of a located record before the first GET address location zero; "the low order portions of memory (the monitor) will be irreparably damaged." No compile- or run-time check. | ([J 02.07.05]) |
| Variable-length located records | A located variable-length record cannot be expanded unless each record begins a new block; "No check is made for violation of this rule either at compile time or at execute time." | ([J 02.07.03]) |

---

---

### 8.3 F28-8043 vs J28-6169: contradictions and divergences

Each item gives both readings. J is authoritative for the implemented language.

1. **PARAM and FUNCT type codes removed.** F defines FUNCT and PARAM as required Data
   Description type codes for the GIVING/USING names of a BEGIN SECTION command
   ([F pp. 72–73]; type-code list [F p. 71] area; word list marks them † restricted,
   [F p. 110]). J: "These two type codes described in the General Information Manual are
   no longer in the language." (J 02.05.03). Functions themselves survive — J
   diagnostics 30 and 68 still police function-argument counts ([J 90.04.01]) and DO
   USING/GIVING parameter matching is checked (msgs 72–75) — only the special
   data-description marking is gone.

2. **GET verb definition corrected by J.** J states outright: "The verb is described
   incorrectly in the Commercial Translator General Information manual and the
   definition given in the last paragraph on page 39 of the manual should be replaced
   with:" followed by replacement text — GET record.name obtains the *next* record in
   the file regardless of what record is actually next, in accordance with the
   characteristics of the named record; the record.name must be associated with only
   one input file ([J 02.07.04], correcting [F p. 39]). J also adds the five preconditions
   (a–e) for using GET RECORD FROM file.name (fixed equal lengths / BEGIN / standard
   variable-length / BLOCK CONTROL / PATTERN) ([J 02.07.04]).

3. **STOP RUN.** F documents only `STOP n` — halt displaying n, resumable by restart
   ([F p. 54]; command list [F p. 109] area shows "STOP n"). RUN is absent from F's word
   list ([F p. 110]). J requires a STOP RUN in every program to return control to the CT
   Supervisor, closing all open files as if CLOSE ALL FILES had been given
   ([J 02.04.06] #9), enforces it with diagnostic 175 ([J 90.04.01]), and reserves RUN
   (key-word list 2, [J 02.03.02]; diagnostic 2). J's operator documentation shows both
   forms: "STOP nnnnnn where nnnnnn is any number 6 digits or less" and STOP RUN
   (J 05, systems operation).

4. **DISPLAY comma semantics.** F: "The DISPLAY command displays all the information
   that follows the word DISPLAY up to, but not including, a comma or period not
   enclosed in quotation marks." — a bare comma *terminates* the displayed material
   ([F p. 54]). J: within DISPLAY, "Data names not intended to be used as qualifiers
   must be separated by commas; otherwise all but the last will be disregarded" — the
   comma is an operand *separator* ([J 90.01.01]). Also, J fixes the display device as
   the on-line 716 printer and caps the quoted material at a 50-character alphameric
   literal complete on a single line ([J 02.04.02.01]), where F speaks generally of "an
   appropriate output device or display medium" (F p. 54).

5. **Pictorial characters A vs X.** F distinguishes them: A = "Any non-numeric
   character, including the blank"; X = "Alphameric character (any character in the
   machine's character set)" (F p. 80). J collapses the distinction: "The pictorial
   characters A and X are considered to be synonymous by the 7090 CT Compiler."
   ([J 02.05.04]).

6. **Sign-overpunch position.** F allows the +/− overpunch "with either of the format
   characters 8 or 9, in either the units or high-order position of a field"
   ([F p. 80]). J restricts external decimal fields to "an overpunched + or - in the
   rightmost position of the field. A + and - may not appear in the character by
   itself." (J 02.05.05, note 1; the field-type chart allows the overpunch only in the
   rightmost character).

7. **Continuation of Data Description literals across lines.** F's rule: a constant
   carried onto a new line must have the portion on each line "treated as a complete
   constant (i.e., enclosed in quotation marks)"; no continuation indication, no
   assumed blanks ([F p. 83], General Note). J: "Literals in this section which are
   continued on multiple lines **in violation of the rules given on page 83 of the
   General Information Manual** are handled correctly. Use of this characteristic of
   the 7090 processor should not be made if compatibility with other processors is
   desired." (J 02.03.01 A.2.c). I.e., the 7090 processor tolerates plain
   continuation of literals that F declares illegal.

8. **Mixed alphameric/numeric pictorials.** F's format-character table and examples
   never address a pictorial mixing A's and 9's ([F pp. 80–81], silent). J explicitly
   forbids it and defines the fallback: the field is treated as alphameric
   ([J 90.01.03]).

9. **Reserved-word lists restructured.** F gives one flat list of "Commercial
   Translator Words" to avoid, with † marking words restricted only in data
   description (COND, COPY, FUNCT, LABEL, LIBRARY, PARAM, QUANTITY, REDEF)
   ([F p. 110]). J replaces this with a three-tier key-word system: (1) thirteen words
   never usable as programmer names in any division (BEGIN, FILE, FOR, HIGH.VALUE,
   HIGH.VALUES, IN, LOW.VALUE, LOW.VALUES, ON, RECORD, WHEN, ZERO, ZEROS); (2) words
   not usable as Data or Procedure names (56 words incl. RUN and CRYPT, neither in
   F's list); (3) words usable as Procedure/Data names if not referenced in the
   Environment Division (ACTIVITY, BCD, BINARY, BLOCKSIZE, … 49 words, 48 of them
   absent from F — LABEL is the one F carries) ([J 02.03.02]–02.03.03). Compiler
   writers need both lists; J governs.

10. **LOAD / OVERLAP presented as available in F, deferred in J.** F describes the
    LOAD command ([F p. 54]) and OVERLAP processor command with object-program overlay
    organization ([F pp. 55–56]). J defers both verbs ([J 90.01.03]) and notes the loader
    consequence: no segmentation into separate memory loads ([J 90.01.05] B.2).

11. **INCLUDE / library facilities.** F describes the INCLUDE command with name
    substitution from library procedures ([F p. 58]; cross-referenced at [F p. 52], cf. p. 12) and
    the LIBRARY description-field code for copying stored data descriptions
    ([F p. 81]). J defers INCLUDE entirely — "no library facilities are currently
    available" (J 90.01.02) — and diagnostic 110 rejects both COPY and LIBRARY
    ([J 90.04.01]).

12. **COPY type code.** Defined in F (type list [F p. 71] area; description-field usage
    [F p. 81]). Deferred in J ([J 90.01.03]; diagnostic 110).

13. **HIGH.VALUE / LOW.VALUE made concrete.** F defines them abstractly as the highest
    and lowest characters in the collating sequence of the target system ([F p. 20]).
    J instantiates: HIGH.VALUE is the left parenthesis "(" and LOW.VALUE the zero "0"
    under the native 709/7090 sequence; under COLLATE COM (Commercial/705 sequence)
    HIGH.VALUE is 9 and LOW.VALUE is blank ([J 02.04.01]; collating sequences displayed
    at [J 02.06.16]). J also adds comparison restrictions (ZERO vs numeric or
    alphameric; HIGH.VALUE/LOW.VALUE/BLANK vs alphameric only) and the MOVE/SET
    target-field legality chart with "Illegal" cells ([J 02.04.01]–02.04.02) — none of
    which appear in F.

14. **DO loop semantics — agreement, with a shared gap.** F's expansion of
    `DO rtn FOR i = p(q)r` executes the body before the test (`SET i = p. / START. DO
    rtn. / IF i = r THEN GO TO NEXT. / ADD q TO i. / GO TO START.`) (F pp. 50–51);
    J confirms "A DO section will always be performed at least once regardless of the
    values of the loop control variables" (J 90.01.02). Note both manuals terminate on
    *equality* with r, not on exceeding it — see the catalog in §8.5.

15. **Figurative-constant MOVE limits added by J.** F places no length limits on
    figurative-constant moves ([F pp. 19–20]). J forbids moves to variable-length
    arrays and to fields longer than 2^15 − 1 characters ([J 02.04.01]; [J 90.01.02];
    diagnostics 180/181).

16. **Environment Description documented only in J.** F's Preface expressly omits
    environment-description rules, deferring them to processor publications
    (F Preface, PDF p. 6). [J 02.06] is therefore the sole source for FILE / SPECIF /
    POOL / GROUP / CONTRL / OPTION / COND card rules; there is no F baseline to
    diverge from. (J 02.06.01–02.06.17)

17. **Period as terminator differs by division.** F's punctuation rules ([F p. 27] area)
    describe the period sentence-terminator generally. J sharpens: in Procedure, the
    first period-followed-by-blank terminates the statement, remainder is commentary
    ([J 02.03.01] A.3.a; [J 90.01.03] — no diagnostic given); in Data and Environment,
    entries end when column 72 is blank and "The period (.) must not be used to signal
    completion. In these sections, a period is considered part of the previous word,
    thus creating an undefined name." (J 02.03.02 A.3.b; restated for Environment at
    [J 02.06.02]).

---

---

### 8.4 The severity-code system and rules implied by the diagnostics (J Appendix 90.04)

#### B.1 The severity-code system

- Severity codes (values) run **1 through 5**; 1 least severe, 5 most severe; 2, 3, 4
  indicate intermediate degrees. ([J 90.04.02])
- "An error severity code of 1 does not prevent the running of the object program
  immediately after compilation. Any code above 1 does prevent running of the object
  program immediately after compilation. That is, the compiler will not compile and
  go." (J 90.04.02)
- "An error severity code of 5 causes the compiler to stop compiling. It then proceeds
  to the next job." (J 90.04.02)
- Object-deck production: an output deck is produced "except when a severe error has
  been encountered during compilation. The severity value (code) is used to determine
  whether a deck will be produced when NODECK is not specified. If the severity code is
  5, a deck will not be produced." (So severities 2–4: deck punched, but no automatic
  execution.) ([J 02.01.01])
- Under the LOAD option, "The program will be executed unless the NOGO option has been
  taken, or the Compiler has encountered a source program error with a severity code
  greater than 1 **or an undefined symbol in the code which it has generated**."
  ([J 02.01.02])
- The assembly listing is produced only "if LIST was selected and no severe error was
  encountered during compilation." (J 02.02.01)
- Message-listing mechanics: in the Appendix 90.04 listing the CODE column shows 0
  because "the value may vary. One of the severity values 1 through 5 will actually be
  printed with the error message." **The per-message severity assignment is nowhere
  tabulated** (see the catalog in §8.5). ([J 90.04.01])
- Error messages are cross-referenced to the source through compiler-assigned statement
  numbers of the form xxxxx,yy — three to six digits; the last two digits (after the
  comma) reference the clause, the digits before the comma reference the line.
  Statement number **9999,99** references errors "not confined to a single source
  statement." (J 02.02.01)
- The sample listing ends with the trailer line `SEVERITY LIMIT WAS NOT REACHED` —
  evidence of a settable severity limit whose control is not documented in 02.01 (see
  open questions). ([J 90.04.01])

#### B.2 Implied language rules, message by message

All message texts below are from the compiler error-message listing ([J 90.04.01],
messages 0–209); abbreviated where marked "…", and with intra-message spacing normalized (the listing prints e.g. "( E  A(2) )" with double spaces and occasional space-before-period). `'NAME.1'`/`'NAME.2'` are compiler
substitution placeholders; numeric values inside message texts (24, 12, 999, 16, etc.)
are representative sample values from the fixed text, not variables (per transcriber
note at [J 90.04.01]). The citation for every row is ([J 90.04.01]); the msg number is
given so the row can be traced.

**Numeric limits revealed by diagnostics**

| Implied rule / limit | Msg # — text (abbrev.) |
|---|---|
| COND-card key setting max 12 octal digits; excess keeps rightmost 12; non-octal setting replaced by '1' | 6 — "-COND- CARD KEY SETTING EXCEEDS 12 DIGITS. RIGHTMOST 12 DIGITS USED."; 7 — "…MUST BE OCTAL. KEY SETTING '1' USED." (matches [J 02.06.17]: 'nn' is 12 octal digits for 36 console keys) |
| Max 16 records in a PATTERN on a FILE card | 50 — "NUMBER OF RECORDS IN -PATTERN- CANNOT EXCEED 16." |
| Pictorial max 30 characters | 100 — "DATA DESCRIPTION CONTAINS PICTORIAL WHICH EXCEEDS LEGAL LIMIT OF 30 CHARACTERS." |
| Alphabetic literal max 50 characters | 150 — "ALPHABETIC LITERAL EXCEEDS 50 CHARACTERS." (matches [F p. 18] and [J 02.04.02.01] DISPLAY rule) |
| Alphabetic literal after a SPECIF key word max 6 characters | 160 — "ALPHABETIC LITERAL FOLLOWING KEY WORD CANNOT EXCEED 6 CHARACTERS." |
| Max 60 operators per sentence | 171 — "NUMBER OF OPERATORS IN THIS SENTENCE EXCEEDS MAXIMUM OF 60. SENTENCE DELETED FROM TEXT." |
| Max 63 files | 193 — "LIMIT OF 63 FILES EXCEEDED." (matches [J 90.01.04]) |
| Figurative constant move: target field length capped (32766 chars per message; 2^15−1 per [J 02.04.01] — see ambiguities) | 181 — "MOVE OF FIGURATIVE CONSTANT TO FIELD LONGER THAN 32766 CHARACTERS NOT YET HANDLED…" |
| CONTRL load name unique, ≤ 6 characters | 207 — "-CONTRL- NAME MUST BE UNIQUE AND 6 CHARACTERS OR LESS." (matches [J 02.06.15] "loadnm is a name of 6 characters or less") |

**Lexical / card-format / statement-structure rules**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| Every Procedure statement must end with period(+blank); an unterminated card gets a period assumed | 62 — "PREVIOUS CARD NOT PROPERLY TERMINATED. PERIOD ASSUMED." |
| Alphabetic literals need a closing quote and must be complete on one card | 167 — "SECOND QUOTE MARK MISSING."; 168 — "ALPHABETIC LITERAL EXTENDS ACROSS CARDS." (cf. [J 02.03.01] A.2.c and [F p. 18] rule 1) |
| Source characters outside the language character set are invalid; replaced by 0 internally / $ externally | 134 — "ILLEGAL CHARACTER REPLACED IN INTERNAL TEXT BY 0, AND IN EXTERNAL TEXT BY $." |
| Data/Environment fixed-field info (level, type, quantity, mode, justify) belongs only on the first card of a multi-card group | 186 — "DATA OR ENVIRONMENT FIXED FIELD INFORMATION SHOULD BE PUNCHED IN ONLY THE FIRST CARD OF A MULTIPLE CARD GROUP. POSSIBLE CONTINUATION CHARACTER ERROR." (matches [J 02.03.01] A.2.d) |
| A sentence may not begin with OTHERWISE | 208 — "SENTENCE CANNOT START WITH -OTHERWISE-" |
| Every statement must contain exactly one verb | 125 — "STATEMENT WITHOUT PROPER VERB DELETED FROM TEXT."; 126 — "STATEMENT WITH MORE THAN ONE VERB DELETED…" |
| Incomplete statements are deleted, not repaired | 122 — "INCOMPLETE STATEMENT DELETED FROM TEXT." |
| General sentence-structure validity; key words cannot appear in arbitrary positions | 192 — "SENTENCE STRUCTURE ERROR. POSSIBLE ILLEGAL USE OF A KEY WORD."; 196 — "ILLEGAL SENTENCE STRUCTURE NOTHING DONE." |
| Parentheses must balance; extras diagnosed | 113 — "REDUNDANT RIGHT PARENTHESIS ELIMINATED."; 114 — "REDUNDANT LEFT PARENTHESIS." |
| The job deck must end with *FINISH before end-of-file | 132 — "END OF FILE ON JOB TAPE WITHOUT *FINISH CARD." (matches [J 02.01.02] *FINISH rule) |

**Name rules**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| RUN is reserved to the processor and may not be a programmer name | 2 — "-RUN- DELETED. ITS USE IS RESTRICTED TO PROCESSOR." (cf. key-word list 2, [J 02.03.02]) |
| An operation (verb/key word) may not be defined as a name or appear in a name field | 61 — "OPERATION DEFINED AS NAME OR FOUND IN NAME FIELD." |
| Key words should not be used as data names; Procedure key words in Data/Environment are demoted to data names | 152 — "'NAME.1' SHOULD NOT BE USED AS DATA NAME."; 178 — "PROCEDURE KEY WORD USED IN DATA OR ENVIRONMENT, INTERPRETED AS A DATA NAME." |
| Qualification must be well-formed | 101 — "'NAME.1' IS AN IMPROPERLY QUALIFIED NAME." |
| All referenced names must be defined | 108 — "'NAME.1' IS AN UNDEFINED SYMBOL."; 191 — "'NAME.1' IS NOT PROPERLY DEFINED." |
| Names must be unique within a section | 166 — "'NAME.1' IS NOT UNIQUE IN THIS SECTION." |
| System-generated (GN)nnn / SYS) style) names are not user-referable | 173 — "REFERENCE MADE TO NON-EXISTENT SYSTEM GENERATED NAME."; 174 — "REFERENCE TO SYSTEM SUBROUTINE LACKS PROPER NUMBER. ZERO ASSUMED." |

**Section structure and control flow**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| END must match an open section; sections nest strictly and must all be closed | 64 — "CANNOT -END- SECTION WHEN NONE ARE OPEN."; 65 — "CANNOT -END- SECTION 'NAME.1' BEFORE SECTION 'NAME.2'."; 66 — "ONE OR MORE SECTIONS NOT CLOSED." |
| An END section clause must stand alone in its sentence | 179 — "-END- SECTION MUST BE THE ONLY CLAUSE IN THE SENTENCE." |
| Control must not flow off the end of procedure text into data, generated constants, or into a DO-addressed procedure | 87 — "PROBABLE PROGRAM CONTINUITY ERROR. PROGRAM FLOWS INTO *DATA."; 169 — "…FLOWS INTO GENERATED CONSTANTS."; 99 — "…FLOWS INTO STATEMENT OR SECTION 'NAME.1' ADDRESSED BY A -DO-." (i.e., DO subroutines are closed/linked — [F p. 50]) |
| GO TO targets must be statement or section names, and must not be DO-addressed procedures | 127 — "TRANSFER BYPASSED BECAUSE 'NAME.1' IS NOT A STATEMENT OR SECTION NAME."; 128 — "TRANSFER BYPASSED BECAUSE 'NAME.1' IS A STATEMENT OR SECTION NAME ADDRESSED BY A -DO-." |
| Assigned GO TO index must be a proper integer; non-integer truncated | 129 — "FORMAT ERROR FOR TRANSFER INDEX. NOTHING DONE."; 130 — "TRANSFER INDEX NOT AN INTEGER. INTEGRAL PART TAKEN AS VALUE." |
| DO targets must be statement/section names | 188 — "'NAME.1', ADDRESSED BY A -DO-, IS NEITHER A STATEMENT NOR A SECTION NAME." |
| There is a PROGRAM.START facility: at most one, must name a statement/section, must not be DO-addressed | 141 — "MORE THAN ONE -PROGRAM.START-. FIRST USED."; 142 — "-PROGRAM.START- MUST BE A STATEMENT OR SECTION NAME."; 143 — "-PROGRAM.START- CANNOT BE A STATEMENT OR SECTION NAME ADDRESSED BY A -DO-." |
| Every program must contain STOP RUN | 175 — "NO -STOP RUN- IN PROGRAM." (matches [J 02.04.06] #9; see §8.3 item 3) |

**DO / functions / subscripting**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| DO … USING/GIVING parameter lists must match the target procedure's parameter/function counts exactly | 72–75 — "TOO MANY / TOO FEW -USING- / -GIVING- PARAMETERS IN -DO- STATEMENT" |
| DO statements have a fixed set of valid forms | 83 — "INVALID FORM OF -DO- STATEMENT." |
| Loop control variables and their parameters (p, q, r) must have integer-compatible formats; literal parameters checked too | 76 — "FORMAT ERROR FOR LOOP CONTROL VARIABLE 'NAME.1'."; 77 — "…FOR PARAMETER 'NAME.1' OF LOOP CONTROL VARIABLE."; 78 — "…FOR LITERAL PARAMETER OF LOOP CONTROL VARIABLE 'NAME.1'." |
| Function references must specify all arguments, and not more than declared | 30 — "FUNCTION 'NAME.1' LACKS EXPLICIT SPECIFICATION OF ALL ARGUMENTS."; 68 — "EVALUATION IGNORED FOR FUNCTION 'NAME.1'. TOO MANY ARGUMENTS SPECIFIED." (note: functions survive in J even though the PARAM/FUNCT type codes were removed — see §8.3 item 1) |
| Subscript variables must be integers of numeric type | 31 — "SUBSCRIPT VARIABLE 'NAME.1' MUST BE AN INTEGER."; 79 — "SUBSCRIPT VARIABLE 'NAME.1' MUST BE OF NUMERIC TYPE." |
| Subscripted references must match the array's declared number of dimensions and use valid subscript-variable formats | 70 — "CHECK ARRAY OF ELEMENTS, 'NAME.1', FOR NUMBER OF DIMENSIONS."; 71 — "INVALID FORMAT FOR SUBSCRIPT VARIABLE IN ARRAY OF ELEMENTS, 'NAME.1'."; 98 — "CHECK DATA DESCRIPTION OF ARRAY OF ELEMENTS, 'NAME.1'." |
| Inefficient (but legal) subscript formats are warned about | 206 — "'NAME.1' HAS INEFFICIENT FORMAT FOR SUBSCRIPT VARIABLE." |

**Conditionals / comparisons**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| Comparison structures have a fixed grammar | 107 — "ILLEGAL COMPARISON STRUCTURE." |
| Variable length items may not be compared | 123 — "CANNOT USE VARIABLE LENGTH ITEMS FOR COMPARISON." (matches [J 02.04.07] C.5) |
| Conditional expressions have a bounded internal test capacity | 187 — "CONDITIONAL EXPRESSION TEST CAPACITY EXCEEDED. REWRITE AS TWO OR MORE SEPARATE EXPRESSIONS, EACH WITH ILLEGAL SENTENCE STRUCTURE NOTHING DONE." (text as printed; see the catalog in §8.5 — appears garbled) |
| IF and WHEN are distinct; the compiler substitutes WHEN for improper use of IF | 170 — "-WHEN- SUBSTITUTED FOR -IF- BECAUSE OF IMPROPER USE." |

**MOVE / ADD / SET / arithmetic**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| Data formats constrain each operation; illegal source/target format combinations are rejected with the field's format echoed | 25 — "OPERATION IGNORED BECAUSE 'NAME.1' HAS IMPROPER DATA FORMAT ( E A(2) ) FOR THIS USE."; 84 — "ILLEGAL MOVE - FROM 'NAME.1' ( E A(2) ) TO 'NAME.2' ( IR 999 ). NOTHING DONE."; 182 — "IMPROPER DATA FORMAT." (mode/format compatibility chart at [J 02.04.03]) |
| MOVE requires a complete expression | 119 — "INCOMPLETE -MOVE- EXPRESSION." |
| ADD operands of improper format are dropped from the sum | 120 — "'NAME.1' ELIMINATED FROM ADD BECAUSE OF IMPROPER DATA FORMAT ( E A(2) )." |
| CORRESPONDING is only valid immediately after ADD or MOVE, and must be structurally valid | 63 — "NEITHER -ADD- NOR -MOVE- PRECEDES -CORRESPONDING-"; 97 — "INVALID -CORRESPONDING- STATEMENT." |
| Scaling can silently destroy significance; the compiler warns | 27 — "DOWNSCALE GENERATED WHICH LOSES ALL SIGNIFICANT FIGURES."; 199 — "UPSCALE MAY CAUSE HIGH ORDER TRUNCATION FOR STORE INTO 'NAME.1'" |
| Compile-time division by zero is bypassed with result zero | 28 — "ATTEMPTED DIVISION BY ZERO BYPASSED. RESULT TAKEN TO BE ZERO." |
| A missing operand in an expression is taken as zero | 116 — "MISSING OPERAND ASSUMED TO BE ZERO." |
| Figurative constants have restricted usages | 82 — "INCORRECT USAGE OF FIGURATIVE CONSTANT."; 180 — "MOVE OF FIGURATIVE CONSTANT TO VARIABLE LENGTH FIELD NOT YET HANDLED BY SYSTEM."; 181 (see limits table above). (chart at [J 02.04.02]) |
| Transfer addresses must be legal | 26 — "OPERATION IGNORED BECAUSE 'NAME.1' IS ILLEGAL TRANSFER ADDRESS." |

**Data Description rules**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| Every data name needs a level | 194 — "DATA NAME LACKS LEVEL." |
| Mode column and pictorial must agree | 32 — "MODE AND DATA DESCRIPTION CONFLICT. 'NAME.1' FORMAT USED." |
| Format (pictorial) characters combine only in legal ways; counts bounded | 33 — "ILLEGAL COMBINATION OF FORMAT CHARACTERS…'NAME.1' FORMAT USED."; 34 — "MAXIMUM FORMAT CHARACTER COUNT EXCEEDED…"; 35 — "MAXIMUM NUMERIC LENGTH EXCEEDED…"; 185 — "DATA DESCRIPTION PICTORIAL ERROR."; 133 — "NO RIGHT PARENTHESIS IN FORMAT PICTORIAL." |
| A field on the format-description level may not have sub-organization | 36 — "DATA ON FORMAT DESCRIPTION LEVEL CANNOT HAVE SUB-ORGANIZATION. CHECK 'NAME.1'." (matches [J 02.05.06] c) |
| Conditional variables have format restrictions and may not carry QUANTITY | 37 — "FORMAT ERROR FOR CONDITIONAL VARIABLE…"; 38 — "CONDITIONAL VARIABLE CANNOT HAVE -QUANTITY-." |
| Right justification is only valid on format-description-level data | 39 — "DATA NOT ON FORMAT DESCRIPTION LEVEL CANNOT BE SPECIFIED AS RIGHT JUSTIFIED." (matches [J 02.05.04] D.3) |
| REDEF/QUANTITY IN targets must be already-defined data names, not COND entries or constants | 40 — "-REDEF- TO 'NAME.1' CANNOT OCCUR BEFORE DEFINITION."; 41 — "NAME ASSOCIATED WITH -REDEF- OR -QUANTITY IN- IS UNDEFINED."; 45 — "'NAME.1' IS -COND- TYPE AND CANNOT BE ASSOCIATED WITH -REDEF- OR -QUANTITY IN-."; 46 — "'NAME.1' IS NOT DATA NAME AND CANNOT BE ASSOCIATED WITH…" |
| REDEF preserves justification and level of the original definition | 80 — "CONFLICT BETWEEN JUSTIFICATION AS GIVEN BY ORIGINAL DEFINITION AND -REDEF-."; 81 — "CONFLICT BETWEEN LEVEL AS GIVEN BY ORIGINAL DEFINITION AND -REDEF-." |
| REDEF or LABEL between nonformat and format levels endangers positioning (warning) | 104 — "-REDEF- OR -LABEL- OCCURRING BETWEEN NONFORMAT AND FORMAT DESCRIBED LEVELS MAY AFFECT POSITIONING ADVERSELY." |
| Every data item must have length | 42 — "DATA ITEM WITHOUT LENGTH. CHECK 'NAME.1'." (cf. record-length rule [J 02.05.01] B.1.b) |
| Constants may not be part of a REDEF, an input record, an edited field, or follow a variable-length field | 43 — "CONSTANT CANNOT BE ASSOCIATED WITH -REDEF- OR INPUT RECORD, OR PRECEDED BY VARIABLE LENGTH FIELD."; 57 — "CONSTANT CANNOT BE GIVEN FOR EDITED TYPE FIELD." (matches [J 02.05.06] E.2.a) |
| Constant/pictorial length agreement enforced; sign convention enforced; character legality enforced; conversion over/underflow diagnosed | 51 — "CONFLICT BETWEEN LENGTH OF CONSTANT AND PICTORIAL OF 'NAME.1'."; 52 — "MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL."; 53 — "INCORRECT USAGE OF PERIOD, SIGN, OR F FOR CONSTANT OR LITERAL."; 54 — "ILLEGAL CHARACTER FOR CONSTANT OR LITERAL."; 55/56 — "FLOATING POINT OVERFLOW / UNDERFLOW IN CONVERTING CONSTANT OR LITERAL."; 58 — "CONSTANT OF EXTERNAL DECIMAL TYPE IN ERROR. CHECK 'NAME.1'."; 59 — "CONFLICT BETWEEN LENGTH OF ALPHABETIC CONSTANT AND PICTORIAL." (rules at [J 02.05.06]–07 E.2) |
| A zero repetition count in a pictorial is corrected to one | 60 — "ZERO COUNT IN PICTORIAL REPLACED BY ONE." |
| Numeric fields may not contain non-numeric characters | 67 — "THERE IS AN ILLEGAL NON-NUMERIC CHARACTER IN THE NUMERIC FIELD." |
| Unspecified maximum QUANTITY defaults to 1 for storage allocation | 44 — "UNSPECIFIED MAXIMUM QUANTITY ASSUMED TO BE 1 FOR STORAGE ALLOCATION." (matches [J 02.05.04] C) |
| QUANTITY IN name must be numeric and on the format-description level | 102 — "NAME OF NUMERIC TYPE MUST FOLLOW -QUANTITY IN-. 'NAME.1' IS ALPHABETIC TYPE."; 47 — "DATA NOT ON FORMAT DESCRIPTION LEVEL CANNOT BE ASSOCIATED WITH -QUANTITY IN-." |
| RECORD, COND, REDEF, LABEL entries cannot themselves be QUANTITY items | 103 — "DATA NAME HAVING -RECORD-, -COND-, -REDEF- OR -LABEL- CANNOT BE -QUANTITY- ITEM." |
| A QUANTITY item may not follow a variable field that depends on that same item | 105 — "-QUANTITY- ITEM 'NAME.1' CANNOT FOLLOW VARIABLE FIELD WHICH DEPENDS ON THE -QUANTITY- ITEM ITSELF." |
| Mode column accepts only legal mode characters; illegal ones default to External | 189 — "EXTERNAL MODE SUBSTITUTED FOR ILLEGAL MODE CHARACTER." |
| Justify column accepts only legal justification characters; illegal ones ignored | 190 — "FIELD IS NOT JUSTIFIED BECAUSE OF ILLEGAL JUSTIFICATION CHARACTER." |
| A record's description must be preceded by its record name | 197 — "RECORD NAME MUST PRECEDE DESCRIPTION OF RECORD." |

**Environment Description rules**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| FILE and COND cards require a name in columns 7–22 | 1 — "-FILE- CARD LACKS NAME IN COLUMNS 7 THROUGH 22."; 88 — "-COND- CARD LACKS NAME IN COLUMNS 7 THROUGH 22." |
| Each environment card type has a fixed format | 3 — "-OPTION- CARD FORMAT ERROR."; 4 — "-COND- CARD FORMAT ERROR."; 89 — "-FILE- CARD FORMAT ERROR."; 153 — "-SPECIF- CARD FORMAT ERROR."; 161 — "-POOL- CARD FORMAT ERROR."; 164 — "-GROUP- CARD FORMAT ERROR."; 176 — "-CONTRL- CARD FORMAT ERROR."; 144 — "ILLEGAL ENVIRONMENT CARD TYPE."; 96 — "THERE IS AN ILLEGAL WORD IN THE -FILE- CARD." |
| FILE-card option operands are typed: BLOCKSIZE needs a numeric integer; ONERROR/FORLABEL/AT END need statement or section names; PLACE/FIND LENGTH IN need data names | 91 — "NUMERIC INTEGER MUST FOLLOW -BLOCKSIZE- IN THE -FILE- CARD."; 92 — "STATEMENT OR SECTION NAME MUST FOLLOW -ONERROR-…"; 93 — "…-FORLABEL-…"; 94 — "DATA NAME MUST FOLLOW -PLACE LENGTH IN-…"; 95 — "…-FIND LENGTH IN-…"; 106 — "STATEMENT OR SECTION NAME MUST FOLLOW -AT END-. CHECK 'NAME.1'." |
| SPECIF operands typed: UNIT/SERIAL/REEL take alphameric literals; RETAIN/ACTIVITY take numeric integers; file name is first item in the variable field | 154 — "FILE NAME MUST BE FIRST ITEM IN VARIABLE FIELD."; 155–157 — "ALPHAMERIC LITERAL MUST FOLLOW -UNIT- / -SERIAL- / -REEL-."; 158/159 — "NUMERIC INTEGER MUST FOLLOW -RETAIN- / -ACTIVITY-." |
| POOL/GROUP operands typed | 162 — "NUMERIC INTEGER MUST FOLLOW -BLOCKSIZE- ON -POOL- CARD."; 163 — "…-BUFFERCOUNT-."; 165 — "…-OPENCOUNT-." |
| Record/file consistency: every referenced entity must be a record or file; records must appear on (exactly one input) FILE card; records FILEd must be on that file's FILE card; GET RECORD FROM needs an input file with determinable record length | 8 — "'NAME.1' IS NEITHER A RECORD NOR A FILE…"; 9/10 — "RECORD 'NAME.2' MUST BE ON A[N INPUT] -FILE- CARD…"; 11 — "RECORD 'NAME.2' CANNOT BE ON MORE THAN ONE INPUT -FILE- CARD…"; 12 — "INCORRECT USE OF -GET RECORD FROM-. CANNOT DETERMINE RECORD LENGTH…"; 13/15 — "'NAME.1' FILE LACKS RECORD NAME IN -FILE- CARD OR NO CORRESPONDING RECORD NAME IS IN DATA DESCRIPTION."; 14 — "INCORRECT USE OF -GET RECORD FROM-. 'NAME.1' IS NOT AN INPUT FILE…"; 16 — "'NAME.2' IS NOT A RECORD…"; 17 — "'NAME.2' MUST BE RECORD NAME IN -FILE- CARD."; 19 — "RECORD 'NAME.2' MUST BE ON AN OUTPUT -FILE- CARD…"; 21 — "'NAME.1' IS NOT A FILE…"; 22 — "'NAME.1' IS NOT AN OUTPUT FILE…"; 23 — "INCORRECT USE OF -GET RECORD FROM-…"; 195 — "CANNOT FILE RECORD 'NAME.2' IN THIS FILE, 'NAME.1', BECAUSE ENVIRONMENT FILE CARD LACKS THIS RECORD NAME."; 198 — "NO RECORDS PROCESSED IN FILE 'NAME.1'" |
| Mode consistency: binary data cannot go to a BCD tape | 20 — "BINARY DATA CANNOT BE OUTPUT ON BCD TAPE." |
| Record length must not exceed blocksize unless SPANS given; blocksize adequacy checked | 5 — "RECORD LENGTH 24 OF 'NAME.2' EXCEEDS 'NAME.1' -BLOCKSIZE- 12. -FILE- CARD MUST HAVE -SPANS-."; 209 — "'NAME.1' HAS INSUFFICIENT BLOCKSIZE. BLOCKSIZE USED IS" (value appended at run time; message ends without period as printed) |
| PATTERN must name records; a single-record pattern is legal but inefficient | 48 — "NO RECORDS SPECIFIED IN -PATTERN- ON -FILE- CARD FOR 'NAME.1'."; 49 — "SINGLE RECORD IN THE -PATTERN-… INEFFICIENT PROGRAM PRODUCED." (note: PATTERN is referenced by [J 02.07.04] e but has no printed general form on the FILE card at [J 02.06.03] — see the catalog in §8.5) |
| FIND/PLACE LENGTH IN and BLOCK CONTROL must be applied uniformly to all records of a file referenced by GET RECORD FROM | 117/118/121 — "-FIND LENGTH IN- / -PLACE LENGTH IN- / -BLOCK CONTROL- OPTION USED WITH SOME BUT NOT ALL OF THE RECORDS BELONGING TO THE FILE 'NAME.1' REFERENCED BY A -GET RECORD FROM-." (matches [J 02.07.08] E: options may be elected selectively only with GET record.name) |
| FIND/PLACE LENGTH IN data names must have proper formats | 111/112 — "'NAME.1' HAS IMPROPER DATA FORMAT FOR THIS USE IN THE -FIND LENGTH IN- / -PLACE LENGTH IN- OPTION." |
| OPEN/CLOSE take file names | 138 — "FILE NAME SHOULD FOLLOW -CLOSE-."; 139 — "…-OPEN-." |
| Console-key settings that are hard to code get a warning | 86 — "DIFFICULT TO PROGRAM KEY SETTING. CHECK ENVIRONMENT DESCRIPTION." |

**CRYPT / assembly-level rules**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| CRYPT operations must be valid machine operations | 115 — "INVALID MACHINE OPERATION." |
| CRYPT instructions require address/tag/decrement fields where the operation demands them | 145 — "MISSING ADDRESS."; 146 — "MISSING TAG."; 147 — "MISSING DECREMENT." |
| VFD pseudo-op unavailable | 151 — "VFD IS NOT YET HANDLED BY SYSTEM." |

**DISPLAY**

| Implied rule | Msg # — text (abbrev.) |
|---|---|
| DISPLAY statements have a checked structure | 131 — "INVALID DISPLAY STATEMENT." |

**Capacity-overflow diagnostics (enforce the A.4 table)**

| Table limit enforced | Msg # — text (abbrev.) |
|---|---|
| Alphabetic-constant table | 148 — "LENGTH OF ALPHABETIC CONSTANT EXCEEDS INTERNAL TABLE CAPACITY AND SHOULD BE SUBDIVIDED." |
| Sections (≈35) | 149 — "NUMBER OF SECTIONS IN PROGRAM EXCEEDS INTERNAL TABLE CAPACITY." |
| Constant pool (≈500) | 172 — "CONSTANT POOL OVERFLOW." |
| Sentence size | 177 — "THIS SENTENCE EXCEEDS INTERNAL TABLE CAPACITY. SENTENCE DELETED FROM TEXT." |
| Index expressions (≈50) | 183 — "NUMBER OF SUBSCRIPT EXPRESSIONS USED EXCEEDS INTERNAL TABLE CAPACITY." |
| Positional indicators (≈90) | 184 — "NUMBER OF SUBSCRIPTED NAMES USED EXCEEDS INTERNAL TABLE CAPACITY."; 205 — "INTERNAL TABLE OVERFLOW. REDUCE DUPLICATE USAGE OF SUBSCRIPT VARIABLE NAMES." |
| Variable-length fields | 200 — "NUMBER OF VARIABLE LENGTH FIELDS EXCEEDS INTERNAL TABLE CAPACITY." |
| Hierarchy depth (≈23) | 201 — "NUMBER OF NESTED LEVELS IN 'NAME.1' EXCEEDS INTERNAL TABLE CAPACITY." |
| Base locators (≈127) | 202 — "NUMBER OF DATA GROUPS ASSOCIATED WITH BASE LOCATOR EXCEEDS INTERNAL TABLE CAPACITY." |
| Array dimensions (≈85) | 203 — "NUMBER OF ARRAYS EXCEEDS INTERNAL TABLE CAPACITY." |
| Edited field formats (≈35) | 204 — "NUMBER OF DIFFERENT EDIT FIELDS EXCEEDS INTERNAL TABLE CAPACITY." |

**Compiler self-diagnostics (no language rule implied; listed for completeness)**

| Msg # — text (abbrev.) |
|---|
| 0 — "ERROR MESSAGE NOT YET IN FILE." |
| 18, 24, 29, 124 — "ILLEGAL INTERNAL CONDITION. NOTHING DONE. POSSIBLE COMPILER ERROR." |
| 69 — "ILLEGAL INTERNAL CODE 'NAME.1' SENT TO ASSEMBLY. POSSIBLE COMPILER ERROR." |
| 85 — "PERMANENT READ ERROR IN PHASE 2. COMPILATION SUSPECT."; 135 — "PERMANENT READ ERROR FOR INPUT. DUBIOUS COMPILATION." |
| 109 — "PROCESSOR UNABLE TO FIND VARIABLE USED AS SUBSCRIPT. POSSIBLE COMPILER ERROR." |
| 136/137 — "REDUNDANCY WHILE WRITING / READING EXTERNAL DICTIONARY. DUBIOUS COMPILATION." |
| 140 — "INTERNAL TEXT SYNCHRONIZATION FAILURE. DUBIOUS COMPILATION." |

---

---

### 8.5 Consolidated ambiguity catalog, with plausible resolutions

Every genuine ambiguity, contradiction, or underspecification flagged anywhere in §§1–7 and §9, deduplicated and grouped by language area. Items that are plain F/J divergences with a clear J-side answer live in §8.3 and are not repeated here. Format: the problem, then *Resolution:* the most historically plausible reading and why. Transcription-level doubts (where the uncertainty is in the scan/conversion, not the language) are separated into §8.5.8.

#### 8.5.1 Lexical

- <a id="8.5.1-a"></a>**Quotation mark inside a quoted constant.** F says named constants "may include any of the characters in the machine's character set, including the quotation mark and the blank", yet constants are delimited by quotation marks and neither manual defines an escape or doubling convention; J's scanner diagnostic "SECOND QUOTE MARK MISSING." implies a plain scan-to-next-quote. *Resolution:* in the implemented language the quotation mark is unrepresentable inside a quoted constant; read F's sentence as describing the abstract machine repertoire, not a punching convention. A compiler should scan to the next 4-8 punch and diagnose a missing closer. ([F p. 19]; [F p. 28] rule 7; [F p. 111], ALPHAMERIC: "an alphameric literal may not contain a quotation mark"; [J 90.04.01] msg 167)
- <a id="8.5.1-b"></a>**Maximum numeric constant/literal length under J.** F gives 50 characters overall and 20 digits for anything operated on arithmetically; J's msg 52 ("MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL.") names no number and J never restates the 20-digit rule. *Resolution:* adopt F's limits (50 / 20) as still in force — [J 02.05.06] ties double-precision fixed point to formats of more than 10 digits, consistent with a 20-digit two-word ceiling, and J reaffirms the 50-character literal limit elsewhere. ([F p. 18]; [J 90.04.01] msgs 52, 150; [J 02.05.06] d; [J 02.04.02])
- <a id="8.5.1-c"></a>**Procedure-name terminating period.** F requires every procedure-name to be followed by a period and a blank; J states that names not so punctuated "are handled properly; no diagnostic message is given", without saying how the name/text boundary is then found (names longer than 6 characters overflow the columns 7–12 name margin into the text area). *Resolution:* period+blank is the defined syntax (F); the 7090 compiler additionally accepts its omission, most plausibly taking the boundary at the first blank after the name token that begins in the name margin (simple names cannot contain blanks). A faithful compiler accepts both; one enforcing the written language warns. ([F p. 37] rule 2; [J 90.01.03] A.1.a.ix; [F p. 15] rule 1)
- <a id="8.5.1-d"></a>**"Alphabetic" vs "alphameric" literal.** F distinguishes the two but gives identical formation rules; J's diagnostics say "ALPHABETIC LITERAL" (msgs 150, 168) while [J 02.04.02.01] calls the same object an "alphameric literal". *Resolution:* one lexical class (quote-delimited non-numeric literal); the split is a content classification, not a lexical one. Scan them identically. ([F p. 19]; [J 02.04.02.01] B.2; [J 90.04.01] msgs 150, 168)
- <a id="8.5.1-e"></a>**Reserved word EQUALS.** J's key-word list reserves both EQUAL and EQUALS, but no relational form spelled EQUALS is documented anywhere; F lists only EQUAL. *Resolution:* reserve EQUALS in the word list (as J requires) but implement no EQUALS relational spelling — most plausibly a defensive reservation. The documented equality forms are `IS EQUAL TO` and `=`. ([J 02.03.02]; F pp. 21, 110)

#### 8.5.2 Program structure

- <a id="8.5.2-a"></a>**PROGRAM.START — an undocumented entry-point facility.** Three diagnostics govern a name -PROGRAM.START- (msg 141 "MORE THAN ONE -PROGRAM.START-. FIRST USED."; 142 must be a statement or section name; 143 cannot be DO-addressed), and [J 90.02] mentions the first object word is "not necessarily PROGRAM.START" — but no language section defines the facility. F is silent; the sample program's first labeled sentence is plain `START.`. *Resolution:* PROGRAM.START is a reserved procedure-name: labeling a statement or section with it designates the object-program entry point; absent it, execution begins at the physically first procedure statement (consistent with the Loader "normally" using "the starting point of the first program", and with the sample). At most one per program; not DO-addressable. ([J 90.04.01] msgs 141–143; [J 90.02.01]–02; [J 03.02.08]; [J 90.05] listing PDF p. 195)
- <a id="8.5.2-b"></a>**Division ordering and interleaving.** F explicitly allows portions of the three divisions to be interleaved, each introduced by its header; J never restates the rule or requires an order; the sample deck runs *DATA, *ENVIRONMENT, *PROCEDURE once each. *Resolution:* accept interleaved portions (the F rule) — J's diagnostic 87 "PROGRAM FLOWS INTO *DATA." only makes sense if a *DATA portion can follow procedure text — and treat DATA → ENVIRONMENT → PROCEDURE as the canonical demonstrated order. ([F p. 27]; [J 90.04.01] msg 87; [J 90.05] listing PDF pp. 192–197)
- <a id="8.5.2-c"></a>**Cards before the first division header.** F: "All entries following a division header are assumed to be a part of the specified division" — but nothing says what governs source cards *preceding* the first header. *Resolution:* require a division header as the first non-control source card; every exhibited deck begins with one immediately after `$CMPLE`, and no text supplies a default division. ([F p. 27]; [J 02.01.01]; [J 90.05] listing PDF p. 192)
- <a id="8.5.2-d"></a>**Serial-number sequence checking.** F says the Ctl./Serial field "will be sequence-checked by the processor"; J says serial numbers "are not sequence checked by the compiler." *Resolution:* J governs: no sequence checking; F describes intended behaviour of eventual processors generally. ([F p. 37]; [J 02.03.01])
- <a id="8.5.2-e"></a>**Extent of section-scoped name uniqueness.** F says section names "can be used as parts of compound names" where necessary; diagnostic 166 ("'NAME.1' IS NOT UNIQUE IN THIS SECTION.") implies sections scope uniqueness for at least some names; yet [J 90.01.03] forbids qualifying a RECORD defined inside a section by the section.name. *Resolution:* sections provide qualification context and a uniqueness scope for procedure-side names (per [F p. 26]), while RECORD names must be program-unique and never section-qualified (per [J 90.01.03]) — the only reading consistent with both texts, though it rests on inference from a diagnostic. ([F p. 26]; [J 90.04.01] msg 166; [J 90.01.03])
- <a id="8.5.2-f"></a>**Column 72 vs column 71 blank assumption on the data form.** F (rule 14) assumes a blank after column 72 of the procedure form and column 71 of the data form; J says the processor "replaces the contents of column 72 with a blank in Data and Environment lines" (column 72 being the continuation column). *Resolution:* use J's mechanism for the 7090: Data/Environment text ends at column 71, column 72 is the continuation flag and is blanked before scanning — functionally F's rule, stated operationally. ([F p. 28]; [J 02.03.01]; J 02.06.01–02)
- <a id="8.5.2-g"></a>**STOP n, bare STOP., and STOP RUN.** F defines only `STOP n` (halt, display n, resume on restart) yet shows a bare `STOP.` in a Chapter-2 illustration; J requires a STOP RUN in every program (msg 175) without saying whether STOP n survives, and its operator documentation shows both `STOP nnnnnn` (n ≤ 6 digits) and STOP RUN. *Resolution:* both forms exist in the implemented language — STOP n for resumable operator halts, STOP RUN (mandatory, once-reachable) as program terminator; treat the operand as required (the bare `STOP.` is an informal illustration predating the general form). (F pp. 25, 54; [J 02.04.06] #9; [J 90.04.01] msgs 2, 175; [J 90.02.14]; [J 05.06.04])

#### 8.5.3 Data description

- <a id="8.5.3-a"></a>**Subscript / quantity-nesting depth under J.** F caps quantity nesting at three levels per nested group and three subscripts per reference; J restates no per-array cap, giving only program-wide table limits (≈85 array dimensions, ≈90 positional indicators) and the 23-level hierarchy limit. *Resolution:* retain F's three-level/three-subscript limit for the implemented language — J defers to F for the base language and no J example exceeds two subscripts. ([F p. 30], p. 77; [J 90.01.05]; [J 02.04.07])
- <a id="8.5.3-b"></a>**Written form of BLANK WHEN ZERO.** J introduces the clause and says it characterizes an edited field, but neither manual shows where or how it is written on the data description card. *Resolution:* Description-column (38–71) content after any pictorial, blank-separated — by analogy with the other Description-field clauses (QUANTITY IN, LIBRARY, REDEF/COPY names) in F's ordered list of Description contents; J 02.05.06(e)'s rule that non-format text in the pictorial columns is scanned as names supports free-text clauses there. ([J 02.05.05], 02.05.07; [F p. 79])
- <a id="8.5.3-c"></a>**"Non-format field".** [J 02.04.07] rule 4 compares "all non-format fields (see 02.05 for definition)" alphamerically — but 02.05 never uses the term. *Resolution:* non-format field = a field with no pictorial (a group field), which J 02.05.06(c) says is "treated as alphameric with length equal to the length of its subfields" — the only 02.05 definition matching the comparison rule. ([J 02.04.07]; [J 02.05.06])
- <a id="8.5.3-d"></a>**The REDEF line: name and layout.** F allows the REDEF entry to be given a name; J says the type code "should appear on a line with no additional coding except a serial number and the name of the item being redefined", and requires the first following entry to match the redefined item's level. The F sample writes `1REDEF TABLE` at level 1 with TABLE.ITEM at level 2; the J sample writes a bare `REDEF TABLE` then TABLE.ITEM at level 1. *Resolution:* follow the J convention for the implemented language (bare REDEF line; first following entry at the redefined item's level) — J restructured the identical program to comply. J's "should" makes lenient acceptance (warn, don't reject) defensible, but the storage-assignment semantics J gives never use a name on the REDEF line. ([F p. 75], pp. 100, 104; [J 02.05.02]; [J 90.01.03] b.iii; [J 90.05] listing PDF p. 195)
- <a id="8.5.3-e"></a>**"Highest level" in the justification default.** [J 02.05.01]: fields "of level equal to the highest level in a source program will be left justified" — highest number (deepest) or highest rank (smallest number)? *Resolution:* the numerically smallest level number: J's own example (levels 05 and 10) states the level-05 fields are the left-justified ones "since 05 is the highest level used in the program". ([J 02.05.01])
- <a id="8.5.3-f"></a>**Does the constants-then-REDEF table technique survive?** J forbids constants "as part or all of the redefinition of an area", while F's canonical table-building places constants in an area and REDEFs structure over them. *Resolution:* the F technique remains legal — the constants belong to the *original* definition, not the redefinition; J's restriction bars constants among the entries *following* a REDEF. The constants-first ordering also matches [J 90.01.03]'s advice that a record containing an array precede the REDEF. ([F pp. 74–75]; [J 02.05.06]; [J 90.01.03])

#### 8.5.4 Arithmetic and data manipulation

- <a id="8.5.4-a"></a>**Rounding: threshold stated, edge cases not.** F says SET results are "rounded to the number of places indicated by the format description of the result field" unless TRUNCATED ([F p. 44]), and F's glossary states the rule: the least significant remaining digit "is increased by 1 when the part removed is greater than or equal to one-half" ([F p. 115], ROUND, with worked examples; TRUNCATED contrasts 2063.78 → 2063.7 vs 2063.8, [F p. 116]). What remains unstated: behaviour for negative values, and whether rounding itself can raise overflow. *Resolution:* half-adjust applied to the absolute value with sign restored, matching the glossary rule and contemporaneous IBM practice; [J 90.02]'s packages show per-character "Round current character" subroutine steps, i.e. rounding happens character-serially at store/convert time. (F pp. 44, 115–116; [J 90.02.16]–17) **Narrowed (90.02 + 90.05 mining, 2026-08-01; adversarially verified 2026-08-02):** the full appendix yields the inventory — rounding is a per-position step, invoked by a bare `TRA` carrying no count, in exactly the five MOVPAK packages that are built from a step list: SYS)219 (with SYS)183, external to external decimal), SYS)220 (with SYS)185, external decimal to edited), SYS)221 (with SYS)189, edited to external decimal), SYS)222 (with SYS)190, edited to edited) and SYS)274 (with SYS)268, edited to internal decimal) ([J 90.02.16]–19, 90.02.23, 90.02.30–31). The packages called with a fixed one-to-three-word sequence (SYS)184, 186–188, 246–247, 267) have no steps at all, so their lack of a round step proves nothing about those paths; and no text in [J 90.02] states the algorithm or mentions sign or carry. The compiled sample emits no MOVPAK round step but does round the SET path inline: `XCA / ACL CP)+34 / LRS 35 / DVP CP)+31 / STQ 4)FICA` for "SET WORKING FICA = .03 * WORKING GROSS," and the same tail at three further sites, with the added constant tracking the divisor and TRUNCATED never written in the program ([J 90.05] listing, PDF pp. 196, 206, 210–211). **Inference (7090 architecture, external to both manuals):** `ACL` adds into the magnitude with the sign untouched, so the half-adjust is applied to the absolute value and the carry runs in binary into the integer part before the scaling divide — which is what the *Resolution* above asserted from period practice, now at least corroborated by emitted code, though the constant-pool values are not printed and no negative case is exercised. On overflow, nothing links rounding to SYS)130: the cell's definition is scoped to "any one of the numeric move or convert subroutines of MOVPAK", it occurs exactly once in the whole manual, no subroutine is described as testing or clearing it, and on the sample's SET path the rounded result is stored by a bare `STQ` with no MOVPAK call at all. ([J 90.02.10], 90.02.16–19, 90.02.23, 90.02.30–32; [J 90.05] listing, PDF pp. 196, 203, 206, 209–211; images/page-148.png, page-157.png, page-162.png, page-169.png, page-206.png, page-210.png)
- <a id="8.5.4-b"></a>**Overflow with no ON OVERFLOW clause.** F defines overflow and the ON OVERFLOW reaction (erroneous result not stored), but is silent on what happens without the clause — and MOVE has no ON OVERFLOW at all. *Resolution:* the truncated result is stored and execution continues; the processor records the event in communication cell SYS)130 ("truncation of significant high order values (i.e. overflow)") with no program-visible transfer. F's MOVE editing rules already make high-order dropping defined, silent behaviour. ([F p. 42], p. 44; [J 90.02.10]) **Amended (90.02 re-mining + 90.05 listing evidence, 2026-08-01; adversarially verified 2026-08-02):** the "recorded in SYS)130" half of this resolution needs narrowing. No routine is individually documented to set the cell; SYS)130's entry names a class — "any one of the numeric move or convert subroutines of MOVPAK" ([J 90.02.10]) — and the only routines carrying an explicit `NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` step are the five character-source families SYS)183, 185, 189, 190 and 268 ([J 90.02.15]–21, 90.02.30–32). Nothing outside MOVPAK can arm it at all: the fixed-point scaling and arithmetic routines SYS)163–171 are never called MOVPAK subroutines and are never said to set any cell ([J 90.02.12]–13). On the store side, an arithmetic result held in the AC/AC-MQ reaches its target either by a bare `STQ`/`STO` (internal decimal right justified — `SET WORKING FICA = .03 * WORKING GROSS` into an `IR9(4)V99` field compiles as `LDQ CP)+9 / MPY 4)GROSS / XCA / ACL CP)+34 / LRS 35 / DVP CP)+31 / STQ 4)FICA`, [J 90.05] listing, PDF p. 210, verified on images/page-210.png; likewise `STQ 4)GROSS` at PDF p. 206) or by a MOVPAK convert that carries no test step — SYS)186–188 for external decimal ([J 90.02.18]), SYS)267 for edited fields ([J 90.02.30], exhibited at PDF p. 203 as `CLA 6)GROSS / TSX SYS)180,4 / PZE 2)GROSS,,1 / TXI SYS)267,1,4`), SYS)246 for internal decimal not justified ([J 90.02.26]). The behaviour is unchanged — the truncated result is stored and execution continues — but whether the flag cell records it on the store at all is undetermined: for an internal-decimal target no MOVPAK routine runs, and for the other targets the routine that runs is a MOVPAK numeric convert with no documented test. ([J 90.02.10], 90.02.12–13, 90.02.15–21, 90.02.26, 90.02.30; [J 90.05] listing, PDF pp. 203, 206, 210; images/page-210.png)
- <a id="8.5.4-c"></a>**Invalid characters in a numeric field at object time.** Neither manual defines any program-level reaction, and no verb option can request one. *Resolution:* there is none — the MOVPAK numeric move/convert subroutines set communication cell SYS)131 non-zero when they detect "an improper data condition" ([J 90.02.10]) and carry on; nothing in the generated-code appendix reads, prints from, or clears that cell, the only condition options in the language are ON OVERFLOW (SET/ADD, single result field) and the FILE-card ON ERROR (unrecoverable redundancy, block checksum, block sequence only, [J 02.07.07]), and the field-test sample converts a card-punched external-decimal field (DETAIL HOURS, `99V9`) straight into pay arithmetic through SYS)184 with no check, while emitting two base-locator traps on the same twelve words ([J 90.05] listing, PDF pp. 192, 196, 205). The compile-time diagnostics (msgs 25, 67, 111, 112, 120, 182) and the fatal GET-path conversion check SYS)261/263, which validates a variable-length record's length control word and exits to the CT Monitor, are separate mechanisms and must not be read as the MOVE/arithmetic reaction. ([F p. 44], p. 47, p. 109; [J 02.07.07]; [J 90.01.02]; [J 90.02.07], 90.02.10, 90.02.16, 90.02.29; [J 90.04.01]–02; [J 90.05.02]; [J 90.05] listing, PDF pp. 192, 196, 205)
- <a id="8.5.4-d"></a>**Negation vs exponentiation.** J's operator hierarchy places negation in the top group (with TR and ABS), honored before `**` — so `-A**2` = `(-A)**2`, contrary to modern convention; F never states negation's precedence. *Resolution:* follow J literally: negation binds tightest. F corroborates: "all operators act on the next named item, or the next parenthetical expression, following the operator", and its symbol-pair table only admits negation at expression/parenthesis start. ([J 02.04.05.01]; [F p. 28], p. 106)
- <a id="8.5.4-e"></a>**Parameter/function declaration after the removal of PARAM and FUNCT.** F requires parameter- and function-names to carry the PARAM/FUNCT type codes; J removes both codes ("no longer in the language") yet still processes BEGIN SECTION USING…GIVING, DO USING…GIVING, and function references (msgs 30, 68, 72–75). How to declare them in J is never restated. *Resolution:* parameters and function results are declared as ordinary data fields; only the special type codes were dropped, and the USING/GIVING machinery of F carries over unchanged. Msg 30 implies all function arguments must be explicitly specified. ([F p. 34], pp. 52–53, 57–58, p. 73; [J 02.05.03]; [J 90.04.01] msgs 30, 68, 72–75)
- <a id="8.5.4-f"></a>**Figurative-constant target maximum: 32766 vs 2¹⁵−1.** [J 02.04.01] forbids moving figurative constants to fields "longer than 2^15 - 1 characters" (32767); msg 181 says "…FIELD LONGER THAN 32766 CHARACTERS NOT YET HANDLED…". *Resolution:* an off-by-one in the prose; the message most plausibly reflects the coded check, so the safe implemented maximum is 32766 characters. ([J 02.04.01] c.ii; [J 90.04.01] msg 181)
- <a id="8.5.4-g"></a>**"Report field" (F) = "edited field" (J).** F's MOVE legality rule permits numeric moves "to report fields" but never defines the term; J defines the Edited Field type (pictorial containing `8 * . , $ + -` or BLANK WHEN ZERO). *Resolution:* the identification is effectively certain — F's editing characters are exactly J's edited-field format characters. Use J's term. ([F p. 42], p. 80; [J 02.05.05])
- <a id="8.5.4-h"></a>**Multi-result SET.** For `SET A, B, C = expression` neither manual says whether each target receives the full-precision expression value or a value chained through an earlier (already edited/rounded) target, nor the store order, nor whether TRUNCATED is per-target. *Resolution:* the expression is evaluated once to an intermediate value; each target is stored from that intermediate independently, edited/aligned to its own pictorial; TRUNCATED governs every store in the command. Store order is most plausibly left-to-right, observable only if targets overlap. ([F p. 44], p. 109)
- <a id="8.5.4-i"></a>**Edited source moved to an alphameric target.** J allows every type to move into alphameric fields, but its conversion chart routes edited fields through external decimal, and nothing states whether edited→alphameric transmits the edited character image ($ , . etc.) or the converted numeric form. *Resolution:* the converted (unedited) numeric form — matching the least-intermediate-steps routing used for comparisons ("edited fields... are converted to pure numeric fields"), and the chart (images/page-020.png) shows arrows into alphameric only from external and scientific decimal. ([J 02.04.03], 02.04.04, 02.04.07)
- <a id="8.5.4-j"></a>**A\*\*B\*\*C.** F forbids the unparenthesized form outright; J states a general left-to-right rule for equal-hierarchy operators and never repeats the prohibition. *Resolution:* treat the form as illegal per F — J is a "clarification and amplification" document that overrides F only where it says so. If accepted anyway, left-to-right grouping `(A**B)**C` is the only reading consistent with J. ([F p. 107]; [J 02.04.05.01])
- <a id="8.5.4-k"></a>**MOVE BLANKS into edited/external fields — "doubtful" yet compiles clean.** J's figurative-constant chart stars BLANK→external-decimal and BLANK→edited with the note "An error message is given for each doubtful or illegal usage", yet the J sample blanks edited and external fields and ends "NO ERRORS WERE DETECTED DURING COMPILATION." *Resolution:* the note applies literally only to the "Illegal\*" entries, or such messages carried severities too low to count as errors in the closing summary. Accept BLANK into edited/external fields, produce blanks, at most warn. ([J 02.04.02] chart; [J 90.05] listing PDF pp. 196–197)
- <a id="8.5.4-l"></a>**CORRESPONDING matching: F name-only vs J qualifier-chain.** F defines correspondence as "a field having the same name" in the receiving area, and the F payroll sample depends on that loose rule; J requires all qualifiers below the moved roots to be present and identical — under which several F-sample moves match nothing. The J sample renames fields and adds explicit MOVEs to compensate. *Resolution:* [J 02.04.04] is authoritative: implement the qualifier-chain rule with lowest-level matching and group-as-alphameric fallback; read the F sample's unreachable moves as latent defects of 1960 code written against the looser definition. ([F p. 43], p. 93; [J 02.04.03]–05; [J 90.05] listing PDF pp. 195–196)
- <a id="8.5.4-m"></a>**CALL: non-unique old.name and qualified synonyms.** The F sample CALLs a five-way homonym `(EMPLOYEE.NUMBER) EMPLOYNO` and later *qualifies the synonym* (`DETAIL EMPLOYNO`); J requires the (old.name) to be unique and its sample never qualifies a synonym. *Resolution:* implement J: reject CALL of a non-unique old.name; each synonym is a new unique simple name for one field, never needing qualification — diagnose F-style shared renaming. ([F p. 59], pp. 91–94; [J 02.04.04]–05; [J 90.01.01] i; [J 90.05] listing PDF p. 195)

#### 8.5.5 Control flow

- <a id="8.5.5-a"></a>**DO … FOR termination is an equality test.** F's expansion of `DO rtn FOR i = p(q)r` tests `IF i = r` *after* the body; J confirms at-least-once execution "regardless of the values of the loop control variables". Nothing addresses overshoot (steps that skip r), non-positive steps, or p > r. *Resolution:* take the expansion literally — body first, strict equality exit, index equals r at normal exit; an unreachable r is an unterminating programmer error. 1960 practice defined loops by their macro-expansion, not by a range invariant. ([F pp. 50–51]; [J 90.01.02])
- <a id="8.5.5-b"></a>**Two-index DO: "index.name.1 is set to p.1 + q.1".** Read literally, the outer index would be *assigned* p.1+q.1 on every inner-loop completion, freezing after the second outer pass. *Resolution:* the phrase describes only the first increment — the outer index is incremented by q.1 each time the inner loop completes, consistent with the single-index expansion (`ADD q TO i`) and with F's worked HOURS/MINUTES/SECONDS example requiring 60×60×12 executions. ([F p. 51])
- <a id="8.5.5-c"></a>**"Tests for NOT greater or less conditions" (unequal-length comparison).** [J 02.04.07] rule 2.b.ii: "In tests for NOT greater or less conditions the lengths are made equal by right truncation of the longer field." Grammatically this could mean only the negated operators. *Resolution:* read it as "tests for conditions other than = or NOT =", i.e. all four magnitude operators — rule 2.b.i disposes of =/NOT= explicitly, and truncating only for negated operators would leave plain GT/LT undefined. ([J 02.04.07])
- <a id="8.5.5-d"></a>**GO TO out of a DO-addressed (closed) procedure.** F requires DO'd procedures to be closed subroutines entered only via DO; J diagnoses flowing or transferring *into* one (msgs 99, 128) — but neither manual addresses transferring *out*, and both flagship samples do it (`GO TO NET.` from inside DO'd SEARCH; `GO TO END.OF.RUN` from DO'd END.OF.MASTERS), compiling clean. *Resolution:* the closed-subroutine rule constrains entry only; a GO TO out abandons the pending return linkage, which is simply never resumed. A compiler must ensure a later DO of the same procedure re-establishes linkage correctly. (F pp. 50, 53, 57; [J 90.04.01] msgs 99, 128; [J 90.05] listing PDF pp. 195–197)
- <a id="8.5.5-e"></a>**Assigned GO TO: object-time range behaviour.** F: if the index is not an integer in 1..n, "no transfer will occur; instead, control will pass to the next clause or sentence" — implying a generated range check. J documents only compile-time index diagnostics (msgs 129, 130) and elsewhere adopts a no-object-time-checks policy for subscripts. *Resolution:* F's fall-through semantics stand as the language definition (J nowhere contradicts them), but note the real possibility that the field-test compiler omitted the check. ([F p. 49]; [J 90.04.01] msgs 129–130; [J 90.01.02])
- <a id="8.5.5-f"></a>**SET condition.name under J.** J's SET write-up covers only the arithmetic form and never mentions F's `SET condition.name`; 90.01 does not defer it, and conditional variables remain fully supported. *Resolution:* implemented per F (setting a condition-name stores the associated value into the conditional variable): [J 02.04] is explicitly "Clarification and Amplification", deferring features only via 90.01, and the COND machinery (format checks, subscriptable conditional variables) is intact. ([F p. 46]; [J 02.04.05]; [J 02.05.02]; [J 90.01.03]; [J 90.04.01] msgs 37, 38)
- <a id="8.5.5-g"></a>**Nested and recursive DO.** Neither manual says whether a DO'd procedure may itself issue DOs, or what recursion does; the samples DO only from the main body. *Resolution:* nested non-recursive DO is legal (nothing forbids it; sections nest to depth 18); recursion is unsupported — 1962-era linkage stored a return address per procedure, which re-entry would overwrite. Treat recursion as undefined/erroneous. (F pp. 50, 53; [J 90.01.05] f) **Corroboration (90.02 mining, 2026-08-01; adversarially verified 2026-08-02):** the generated-code appendix supports the non-reentrancy premise independently of the object listing. It contains no stack, save area or activation record of any kind — all generated storage is fixed blocks (`RS) BSS N`, with "N is the sum of maximum Result Storage used in each section"; `TS) BSS N`, "not section-qualified"; `PI) BSS N`; and a Constant Pool block) laid down under three static location counters ([J 90.02.01]–06), so a section's working cells are shared by every activation of that section. And index register 4, in which a `TSX name,4` call leaves the return — the convention used even for the compiler's own generated labels, `TSX GN)019,4` / `GN)019 CLA PI)3` ([J 90.02.06]) — is simultaneously the data-addressing register of generated code (`LAC BL)2,4` / `CAL DATANAME,4`, [J 90.02.04]) and in-line scratch (`PDX 0,4` / `TXL *2,4,5`, [J 90.02.11]); J states the consequence explicitly of the code it generates for a locate-mode reference, "Note that the contents of index register 4 are destroyed" ([J 02.08.03]). No return can therefore survive a procedure body in a register. 90.02 itself never mentions DO — it documents no control-flow code templates at all, only the IOC)/SYS) runtime library — so it constrains the mechanism without attesting the DO sequence itself. ([J 90.02.01]–06, 90.02.11; [J 02.08.03])

#### 8.5.6 Input/output

- <a id="8.5.6-a"></a>**The PATTERN option — used but never defined.** [J 02.07.04] makes `GET RECORD FROM file.name` legal when the file's records "are included in a PATTERN in the Environment Description", and msgs 48–50 police "-PATTERN- ON -FILE- CARD" (max 16 records; single-record patterns "INEFFICIENT"), yet the FILE-card general forms and option text in [J 02.06] contain no PATTERN keyword. *Resolution:* PATTERN is a real but undocumented FILE-card option declaring the repeating sequence of record.names on the file (2–16 of them), letting the compiler know each record's successor without control words; the 02.06 write-up evidently lagged the implementation. The exact keyword syntax is unrecoverable from the manuals. ([J 02.07.04]; [J 90.04.01] msgs 48–50; [J 02.06.03]–07)
- <a id="8.5.6-b"></a>**FOR LABEL / LABELN linkage documented only by a missing appendix.** The non-standard-label mechanism (FILE-card FOR LABEL exit, LABEL type code redefining the 14-word IOCS label area, portions of the FOR LABEL coding "must be done in CRYPT") defers repeatedly to Appendix 90.07 — which J's own contents mark "(Not Currently Available)". The IOCS calling convention (how open/close/reel-switch is distinguished, how control returns) is therefore nowhere specified. *Resolution:* take the language surface as defined (FOR LABEL statement.name + SPECIF LABELN + LABEL type code over area IOC)29) and treat the runtime linkage as IOCS-defined (manual C28-6100-2); J itself recommends the safer alternative of defining labels as records processed with GET/FILE. ([J 02.05.03]; [J 02.06.05], 02.06.12; J 00.00 contents; [J 90.02.08]; J publications p. PDF 221)
- <a id="8.5.6-c"></a>**Reopening a file after a named CLOSE.** J forbids reopening only after CLOSE ALL FILES; for `CLOSE file.name` it is silent, while F says CLOSE releases the file's storage area, and FILE after CLOSE is a defined NOP. *Resolution:* reopening after any CLOSE is at best undefined — the named CLOSE runs the same IOCS close path, and the only J statement on the subject is the ALL FILES prohibition. Do not rely on reopen. ([J 02.04.06]; [F p. 41]; [J 02.07.08], 02.07.01)
- <a id="8.5.6-d"></a>**The printer as a direct FILE target.** F says FILE places records on tape, cards, "or on the printer"; [J 02.07.07] says tape or cards only — yet J's unit vocabulary includes PRX (printer, channel X) and OU ("for a printed output file"), and the sample routes all report files to BCD tape for off-line listing with RCDMRK carriage control. *Resolution:* the implemented, demonstrated path is print-image BCD records FILE'd to tape or the system output unit, listed off-line; direct on-line printing existed at the unit-assignment level but J defines no COMTRAN-level semantics (carriage control, line length) for it. Implement FILE to tape/card/system-output and treat printer files as print-image files per unit assignment. ([F p. 40]; [J 02.07.07]; [J 02.06.09]–10; [J 90.05.03]; [J 02.05.03])
- <a id="8.5.6-e"></a>**GET on an unopened file: silent exit vs terminate-with-message.** [J 02.07.04]: if the file is not open, "the end of file exit is taken. No error message is given." [J 02.07.06]: with no AT END clause, an end condition on GET terminates the program with an on-line message. *Resolution:* "the end of file exit" means whatever that GET's end-of-file disposition is — the AT END statement if present (silently), otherwise the standard no-AT-END termination; the "No error message" sentence denies a specific unopened-file diagnostic, not the generic termination message. ([J 02.07.04]; [J 02.07.06])
- <a id="8.5.6-f"></a>**AT END: "any imperative clause" (F) vs "a single imperative statement only" (J).** *Resolution:* J governs the parse — exactly one imperative statement after AT END (msg 106 further suggests the field-test compiler wanted a statement or section name there; the sample uses both `AT END DO x` and `AT END GO TO x`). F's timing rule — the clause fires on the GET *after* the last record was delivered — is the only timing statement in either manual and carries over. ([F p. 40]; [J 02.07.05]–06; [J 90.04.01] msg 106) *Amended 2026-08-01; adversarially verified 2026-08-02:* the generated code settles the mechanism. J's GET calling sequence carries the end-of-file exit in the address of its third word — `PZE END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE`, filled with SYS)265, the no-AT-END terminator, only "whenever the 'AT END' option is not used with the GET verb" ([J 90.02.04], 90.02.29) — and a coded clause is compiled as an ordinary out-of-line block placed after the calling sequence, its label planted in that word, the block jumped over by a normal-return transfer to the code of the following sentence ([J 90.05] listing, PDF pp. 201–202). `AT END DO x` compiles the same three-instruction DO linkage an in-line DO uses (compare statement 199's plain `DO DEPARTMENT.END` at END.OF.RUN, [J 90.05] listing, PDF pp. 196, 203) and therefore resumes at the sentence after the GET; `AT END GO TO x` compiles a one-instruction block. Both attested forms designate a procedure, and msg 106,00 "STATEMENT OR SECTION NAME MUST FOLLOW -AT END-. CHECK 'NAME.1'." — distinct from the transfer diagnostics 127,00 and 128,00 and from the DO-operand diagnostic 188,00 "'NAME.1', ADDRESSED BY A -DO-, IS NEITHER A STATEMENT NOR A SECTION NAME." — *suggests (inference)* that the field-test parser wanted a designated procedure in that slot; a non-transfer imperative is nowhere attested. F's timing rule stands as before. ([F p. 40], p. 109; [J 02.07.05]–06; [J 90.02.04], 90.02.29; [J 90.04.01] msgs 106, 127, 128, 188; [J 90.05] listing, PDF pp. 195–196, 201–203)
- <a id="8.5.6-g"></a>**Short-record blocking and the BEGIN threshold.** [J 90.05.04] says the 20-word-blocked PAYFILE's shorter DEPARTMENT.TOTAL records "will always begin a new buffer", but a 10-word short record would need `BEGIN` "to avoid grouping" — a threshold no 02.06 rule states. *Resolution:* pure arithmetic, not a special rule: records pack into BLOCKSIZE-word blocks, complete within a block; a record longer than half the blocksize can never share one, while shorter records group unless BEGIN forbids it. ([J 90.05.04]; [J 02.06.03]–04; [J 02.07.01])

#### 8.5.7 Environment, control cards, and processor surface

- <a id="8.5.7-a"></a>***SPEC blocksize "(0-999)" vs Environment maximum 9999.** The Environment FILE card allows BLOCKSIZE up to 9999 words; the Loader *SPEC card the compiler generates from it is described as "normally a number (0-999)" — in a four-column field (17–20). *Resolution:* a typographical slip for (0-9999): the field is four columns and the compiler must punch Environment blocksizes up to 9999 into it. Honor 9999. ([J 03.02.05]; [J 02.06.04])
- <a id="8.5.7-b"></a>**"SPECIF CHKS" in Appendix 90.08.** The *FILE-card table sources checkpoint code C from "FILE CHECKPOINT AND SPECIF CHKS"; no SPECIF option CHKS exists. Scan check (2026-08-01): the printed token is certainly the four glyphs C-H-K-S — not CHECKC, CKSUMS, or CHKPT, and not truncated (the line ends at the normal right margin with clean paper beyond) — so the error is in the original text, not the transcription. *Resolution:* read CHKS as CHECKC (checkpoint at reel switch on the checkpoint file), which exactly matches code C's meaning; CKSUMS (block checksums) already feeds a different column. ([J 90.08.01]; [J 02.06.11]; [J 02.06.04]; images/page-219.png)
- <a id="8.5.7-c"></a>**Who assigns the default BUFFERCOUNT.** The POOL text says an unspecified BUFFERCOUNT "will be assigned automatically by the compiler"; the GROUP text says "the loader will attempt to assign at least twice the OPENCOUNT number of buffers to the GROUP"; 02.06.13/02.07.02 credit IOCS/the Loader (02.06.02 says "the processor"). *Resolution:* agency shorthand, not a conflict — the compiler computes and punches default counts into the generated Loader control cards; the loader/IOCS performs the actual allocation. ([J 02.06.13]–14; [J 02.06.02]; [J 90.08.01]–02)
- <a id="8.5.7-d"></a>**INCLUDE placement "at the end of the present program".** F never anchors "end of program" (relative to STOP RUN, later divisions, or other INCLUDEs). *Resolution:* moot for the implemented language (INCLUDE deferred); for an F-faithful implementation, append in encounter order after the last procedure sentence — consistent with its stated use for closed subroutines "set off from the main flow". ([F p. 58]; [J 90.01.02])
- <a id="8.5.7-e"></a>**Per-message severity codes are nowhere specified.** The 90.04 listing prints CODE 0 for every message "because the value may vary", and no table assigns the 210 messages their actual severities 1–5 — though severity determines deck production, compile-and-go, and abort. *Resolution:* severities must be assigned by consequence stated in each message's text: auto-repair warnings ("PERIOD ASSUMED", "ZERO COUNT… REPLACED BY ONE") plausibly 1; deletions/"NOTHING DONE" 2–4; unrecoverable conditions (internal errors, table overflow, read errors) 5. "May vary" may even mean one message carries different severities in different contexts. ([J 90.04.01]–02; [J 02.01.01])
- <a id="8.5.7-f"></a>**"SEVERITY LIMIT WAS NOT REACHED".** The sample error listing's trailer implies a severity threshold governing something, but no control card sets one. *Resolution:* most plausibly the fixed built-in threshold (severity 5 stops compilation); the trailer reports that no severity-5 error occurred — not a user-settable knob. ([J 90.04.01]–02; [J 02.01.01]–02)
- <a id="8.5.7-g"></a>**Internal-table limits are approximate.** The 90.01.05 table is headed "Appox-Max Size" (sic), so exact enforcement thresholds are unspecified. *Resolution:* take the printed numbers as guaranteed-safe capacities, with overflow diagnosed (msgs 148, 149, 172, 177, 183, 184, 200–205) at whatever the true internal capacity is. ([J 90.01.05]; [J 90.04.01])
- <a id="8.5.7-h"></a>**Which environment types msg 90 covers.** "THIS ENVIRONMENT TYPE NOT YET PROCESSED BY COMPILER." confirms unimplemented types, but only CONTRL's ineffectiveness is documented. *Resolution:* CONTRL is the documented case; POOL/GROUP/OPTION/COND/SPECIF each have dedicated format diagnostics and so were at least parsed. Read msg 90 as covering CONTRL-like deferred types. ([J 90.04.01] msg 90; [J 90.01.04]; [J 02.06.02])
- <a id="8.5.7-i"></a>**Maximum alphabetic-constant length.** Msg 148 says an alphabetic constant exceeding "INTERNAL TABLE CAPACITY… SHOULD BE SUBDIVIDED", but unlike literals (50 chars) no numeric limit for Data Description alphabetic constants is stated. *Resolution:* constants live in the constant pool, whose capacity is ≈500 generated constants ([J 90.01.05] k), so the practical cap is a share of that 500-entry table; impose a documented generous limit and diagnose overflow as msg 148 does. ([J 90.04.01] msgs 148, 150; [J 90.01.05]; [F p. 18])
- <a id="8.5.7-j"></a>**File Check Table: listed in the deck format, never produced.** [J 02.02.01] lists a File Check Table in the object deck; 90.01.04 says none is produced (likewise the control break table). *Resolution:* 02.02/90.03 describe the designed deck format; 90.01 records field-test reality — the slots exist, empty. ([J 02.02.01]; [J 90.01.04]–05)
- <a id="8.5.7-k"></a>**Deck.name with imbedded blanks.** [J 02.01.01] forbids them; [J 90.01.05] B.5 says the compiler "accepts without comment" such a name and punches it into Loader cards, where it "will prevent execution". *Resolution:* the language rule is that imbedded blanks are illegal; the field-test compiler simply failed to diagnose it. At minimum warn. ([J 02.01.01]; [J 90.01.05])
- <a id="8.5.7-l"></a>***COMPILE vs $CMPLE.** The October 1961 sample listing echoes `*COMPILE LIST` as the compilation-initiating card; the manual documents only `$CMPLE`. *Resolution:* *COMPILE is the earlier spelling of the same card (its LIST option behaves identically); implement per $CMPLE, optionally accepting *COMPILE as a historical synonym. ([J 02.01.01]; [J 90.05] listing PDF p. 192)
- <a id="8.5.7-m"></a>**Statement-number placement.** [J 02.02] says statement numbers (xxxxx,00) attach per Procedure sentence / Data entry / Environment card, yet also says the digits before the comma reference a *line*; the sample listing shows a number appearing mid-sentence and two sentences sharing one number. *Resolution:* the number identifies the source card the compiler's scan stood on (clause digits after the comma subdivide for diagnostics); the per-sentence phrasing is loose. ([J 02.02.01]; [J 90.05] listing PDF pp. 196–197)

#### 8.5.8 Transcription and printing artifacts (conversion-level cautions)

These are uncertainties in the *scans or the printed originals*, not in the language. A scan-resolution pass was run on 2026-08-01 — the disputed pages were re-read at 400–600 dpi from the source PDF, with the two most load-bearing results independently verified — and each entry below records its outcome. Following that pass — and under a one-time authorization — the affected conversion notes in `comtran-manuals/` were corrected on the same date and the `nj` mark added verbatim to the transcribed Input FILE form; entries below that quote a conversion note describe it as originally written.

- <a id="8.5.8-a"></a>**Collating-sequence special characters — resolved by scan (2026-08-01).** The page-050 displays were re-read at 600 dpi and independently verified; the full sequences and glyph legend are now in §1.1. The conversion's `0̅` stood for two *distinct* glyphs (the 12-0 "plus zero" and 11-0 "minus zero" zone specials); its `×` for the IBM lozenge (a hollow ring with corner spurs, not a multiplication sign); and the commercial line's first `‡` for a *three*-bar group mark, distinct from the two-bar record mark. Glyph shapes are certain; only the BCDIC names are inference. Confirmed: `(` highest and `0` lowest natively; blank lowest and `9` highest under COM. The specials cannot appear in legal source text outside literals/constants. ([J 02.06.16]; images/page-050.png) **Resolved in part (external sources, 2026-08-02):** Three period IBM sources settle four of the five names and, between them, print card codes for all five glyphs. The *IBM 705 Reference Manual*'s Figure 2, "IBM 705 Character Code Chart," prints the English names "Plus Zero" (705 code `0 11 1010`), "Minus Zero" (`1 10 1010`), "Record Mark" (`1 01 1010`) and "Group Mark" (`0 11 1111`), and leaves one further character, `0 11 1100`, inside a block bracketed only "SPECIAL CHAR" with no name of its own (external: A22-6506-0, © 1959, PDF p. 8 / printed p. 8). Note that this chart gives 705 internal codes only — its columns are `CHAR. | C | BA | 8421` — so card codes must come from elsewhere; the zone table on the same page equates BA = 11/10/01/00 with the 12/11/0/no zone. The undated IBM pocket card "TYPE 705 EDPM—CODE CHART" supplies the missing card-code column, and its Ch.-column glyphs are COMTRAN's exactly: zero-with-plus-above = `0 11 1010` = card **12-0**; zero-with-overbar = `1 10 1010` = **11-0**; two-bar double dagger = `1 01 1010` = **0-2-8**; hollow ring with four corner spurs = `0 11 1100` = **12-4-8**; three-bar mark = `0 11 1111` = **12-5-8** (external: Form 22-6642-0, undated, front panel). Its back panel also prints "Group mark prints □ … Record mark prints Blank / ‡" for the 717 printer and the typewriter respectively. Pen annotations on the front panel reading "Record Storage Mark" and "GROUP" are a prior owner's hand, not IBM print, and carry no evidential weight. The *IBM 1401 Reference Manual*'s Figure 267, "IBM 1401 Character Code Chart in Collating Sequence," independently names "(Plus Zero)" at card 12-0, "(Minus Zero)" at 11-0, "Record Mark" at 0-2-8 and "Group Mark" at 12-7-8 — the record mark a two-bar and the group mark a three-bar glyph, as in COMTRAN — and likewise leaves 12-4-8 with only a bare □ in both its "PRINTS AS" and "DEFINED CHARACTER" columns. Its Note 1 reads: "If specified, this code can be made compatible with 705 Group Mark Code (12-5-8)." (external: A24-1403-5, Apr 1962, printed p. 170 / PDF p. 184.) Outcome for §1.1's legend: `⟨+0⟩` = **Plus Zero**, card 12-0; `⟨−0⟩` = **Minus Zero**, card 11-0; `⟨rm⟩` = **Record Mark**, card 0-2-8 (the card prints the punches as "0-2-8") — name and code both confirmed, no longer inference. `⟨gm⟩` = **Group Mark** is confirmed by name, but its 705 card code is **12-5-8**, not the 12-7-8 that the bit pattern `1111` would naively suggest; 12-7-8 is the *1401's* group-mark code, and IBM's own Note 1 distinguishes the two, so any card code for `⟨gm⟩` in COMTRAN's 705 context must be 12-5-8. `⟨loz⟩` is confirmed as the character at 705 code `0 11 1100` / card 12-4-8 by code and by glyph shape — the pocket card prints it as a hollow ring with four corner spurs, matching the shape read from J's scan — but no period IBM source found names it; "lozenge" therefore remains *inference*. One divergence worth recording: the pocket card's own printed COLLATING SEQUENCE reads "Blank & . □ ≡ … − $ * … / , % # @ ⁺0 A through I ō J through R ‡ S through Z 0 through 9" (two pen blots obscure one position each). It places the three zone specials exactly where COMTRAN's Commercial (705) line does — ⟨+0⟩ before A–I, ⟨−0⟩ between A–I and J–R, ⟨rm⟩ between J–R and S–Z — and ends identically, but it orders the leading specials differently from COMTRAN's `Blank . ⟨loz⟩ ⟨gm⟩ & $ * −` ([J 02.06.16]): '&' precedes the period on the card, and '−' stands where COMTRAN has '&'. Same character set, different order. *Inference:* this is a genuine difference between the machine chart's ordering and the COM sequence as printed in J, not a transcription error in J — the COMTRAN reading was independently scan-verified on 2026-08-01 and the divergent positions on the card are unblotted and legible.
- <a id="8.5.8-b"></a>**External Decimal row of the J field-type chart.** The transcribed "Legitimate Format Characters" cell reads `9 (n) SV9̅ or 9̅ in rightmost character` — a run-together reading of a ruled chart. Read as: characters 9, (n), S, V, with "9̅ or 9̅" being the minus- and plus-overpunched 9 (distinct glyphs in the scan, both rendered `9̅` under the conversion's overline convention), permitted only in the rightmost character — consistent with chart note 1 and the parallel Edited-field cell. ([J 02.05.05] and conversion note; images/page-031.png)
- <a id="8.5.8-c"></a>**The "IR999" mode example — resolved by scan.** The disputed first character is the letter I, settled visually: in this face (proportional, not typewriter) the digit 1 carries a top-left flag and runs 11–13 px wide at 400 dpi, while the letter I is a bare 9-px stem; the disputed glyph is a bare 9-px stem, and the reserved word UNIT1 on the same page shows both forms side by side as an internal control. The conversion note's premise that the face renders 1 and I identically is false for this page. The internal-mode semantics (I = internal, R = right justify, pictorial 999 — cf. "converted to internal form right justified", [J 02.04.05], and "converted to this internal right justified", [J 02.05.04]) are corroboration, not the basis. ([J 02.03.03]; [J 02.04.05]; [J 02.05.04]; images/page-015.png)
- <a id="8.5.8-d"></a>**Stray "nj." in the Input FILE general form — resolved by scan.** Not bleed-through: the mark is two full-strength, right-reading, baseline-locked lowercase letters `nj`, really typed on the page (show-through and set-off print mirrored, and the 1-bit scan cannot carry faint ghosts); the transcribed trailing "." is an 8-pixel dust speck, a fraction of the ink of a real period on the same line. Why "nj" was typed is unrecoverable (stray keystroke, abandoned annotation, or erasure remnant); it corresponds to no syntax element and is ignored for syntax. ([J 02.06.03]; images/page-037.png)
- <a id="8.5.8-e"></a>**Missing comma before record.name.2 in the Input FILE form — print confirmed by scan.** The asymmetry is exactly as transcribed: the Input form's bracket contains no comma (nothing of comma size inside it at 400 dpi), while the Output form's `[ ,record.name.2 . . . ]` comma is full-size. Treat the comma as required (or at least accepted) in both — every other 02.06 option is comma-separated; almost certainly a layout accident of the printed box. ([J 02.06.03]–04; images/page-037.png)
- <a id="8.5.8-f"></a>**90.08 density table sources both H and L from "HIGH" — print confirmed by scan.** The two source cells are geometrically identical impressions of HIGH (0.87 pixel overlap after 1-px alignment; the correctly printed LOW elsewhere on the page is visibly narrower and differently shaped), excluding a faint or damaged LOW — a genuine original printing error. L derives from SPECIF LOW (default HIGH). ([J 90.08.01]; [J 02.06.10]; images/page-219.png)
- <a id="8.5.8-g"></a>**Message 187's garbled tail — resolved by scan: a defect of the original 1962 listing, not the conversion.** Message 187 spans two print lines; its continuation is one unbroken 95-character line on a continuous character grid — `REWRITE AS TWO OR MORE SEPARATE EXPRESSIONS, EACH WITH ILLEGAL SENTENCE STRUCTURE NOTHING DONE.` — with a normal single-space word gap at the "WITH|ILLEGAL" junction (no splice, no overprint). 187's own wording truncates mid-phrase after "EACH WITH", and the appended 40 characters are byte-identical to message 196's text — evidently the message-print routine ran on into 196's stored text. The implied rule stands: conditional expressions have bounded test capacity and oversized ones must be split. ([J 90.04.01] msgs 187, 196; images/page-185.png)
- <a id="8.5.8-h"></a>**90.01.05 item k `-CP)+NN` — prior conjecture refuted by scan (independently verified).** The mark before CP is a plain hyphen (23×8 px at 400 dpi, metrically identical to the "Appox-Max" hyphen; every parenthesis on the page runs ~14–16×49–56 px), and `(CP)+NN` is not a form this manual uses anywhere: the compiler-generated-name form is "SYM)NNN" with a bare right parenthesis — "In the case of constants (CP references), the designation CP)+NN is used" ([J 90.02.03]) — used throughout the 90.05 listing. Read item k as "Number of generated constants in the constant pool — CP)+NN", the dash introducing the notation. Same scan check: the closing ")" the transcription prints at the end of item h is editorial — the original never closes the parenthesis opened at "(each unique combination". ([J 90.01.05]; [J 90.02.03]; images/page-137.png)
- <a id="8.5.8-i"></a>**Cross-reference errata.** [J 02.04.06] refers to the SPECIF card as "(Section 02.07)" — read 02.06. ([J 02.04.06]; [J 02.06.07])
- <a id="8.5.8-j"></a>**The *CTEND card's date field — transcription artifact, resolved by scan (2026-08-02).** The 90.05 transcription prints `*CTEND ... DATE 10/18/61` at PDF p. 216, but the card image on the page prints the date unpunctuated, `DATE 101861`, exactly as the sibling *CTEXT card does at PDF p. 198 — which the transcription renders correctly, so the file contradicts itself. The slashed form belongs only to the listing's running page head (`DATE 10/18/61 TIME 2.45 ACCOUNT ... ID. CT PUBLICATIONS PAGE nn`), which the conversion notes record as retained; the *CTEND line was silently normalized to it, which also pushed that line's DATE from card column 26 to 29. Read the compiler-punched date.and.time field ([J 03.02.09], cols 26-54) as unpunctuated `101861` on both cards. ([J 90.05] listing PDF pp. 198, 216; [J 03.02.09]; images/page-198.png, page-216.png)

---

## 9. Sample-program observations that illuminate the language

*Citation note: this section sometimes pinpoints sub-items with the manuals' internal letter-coded structure (e.g. J 02.02.B.1.b = section 02.02, heading B, item 1.b); the leading numeric part is always the page-marker section code of the "(J xx.xx.xx)" convention.*

Both manuals close with the same simplified payroll application, and the pair is the single best window into COMTRAN as actually written. F28-8043 Appendix 1 gives the 1960 version: a process chart, a flow chart, ten pages of hand-completed coding forms, and a typeset "machine listing" of the identical text ([F pp. 87–104]). J28-6169 Appendix 90.05 gives the 1962 version: prose describing the files, then the *actual printer listing of a real compilation* (dated 10/18/61, ID "CT PUBLICATIONS") ending "NO ERRORS WERE DETECTED DURING COMPILATION", plus loader cards, an object listing, and the run's report output ([J 90.05.00]–90.05.04; [J 90.05] listing, PDF pp. 192–217). The J version is "essentially the example described in the Commercial Translator General Information Manual", modified in "two types … those which were necessary for operation on the 7090, and those which improved the organization and efficiency of the problem" ([J 90.05.01]). Every difference between the two versions is therefore diagnostic: it shows either a language change between 1960 and 1962 or an implementation-driven idiom. This section records what the samples *demonstrate*, not what they compute.

The observations below cite the F sample by printed page and the J sample by prose section code (J 90.05.0x) or, for the listing pages that carry no section code, by PDF page ("J 90.05 listing, PDF p.19x").

### 9.1 Program-level structure as practiced

- **Division order is flexible; F even omits a division.** The F sample is written `*PROCEDURE` first, then `*DATA` — "the actual procedure statements … in this case are written before the data description entries" ([F p. 87]) — and contains **no environment description at all**, even though its procedure FILEs records "IN ERROR.FILE", a file that is never defined anywhere ([F p. 91]). The J sample deck is ordered `*DATA`, `*ENVIRONMENT`, `*PROCEDURE` ([J 90.05] listing, PDF pp. 192, 195). A compiler writer should not assume a fixed division order from either sample alone.
- **Design artifacts precede code.** F presents the methodology as flow chart + process chart ("how data should be grouped for input … and what data groupings are to be obtained") before the source program ([F p. 87]). This is doctrine, not language, but it explains the record-per-report-line data-description style seen in both samples.
- **Deck framing (J only):** the source deck is preceded by a control card echoed at the top of the listing as `*COMPILE LIST` followed by the on-line phase letters `CTC`, with `CTD` and `CTE` printed at the end ([J 90.05] listing, PDF pp. 192, 197). The phase letters are compiler progress markers, not source (J 05, "The letters CTC are printed on-line when this phase is entered"). Note the control card discrepancy against the documented `$CMPLE` card ([J 02.01.01]) — see Ambiguities.

### 9.2 Coding-form usage in practice

- **Serialization encodes page + line.** F's machine listing shows serials of the form *ppnnn*: procedure pages carry 01001–04022, data pages 05001–10015 ([F pp. 101–104]), matching the form's rule that the first three columns of the Ctl./Serial field (cols. 1–6) "is the same for all lines on one page" and that the low-order column is left for inserts ([F p. 37]). Serial 07006 is skipped between the BONDORDER and CHECK records on both the form and the listing (F pp. 97, 104) — gaps for insertion are normal practice.
- **F/J divergence — sequence checking.** F: serials "will be sequence-checked by the processor" ([F p. 37]). J: "Card serial numbers in columns 1-6 of source decks are not sequence checked by the compiler" (J 02.03.A.1). Consistently, the J compilation listing prints **no card serial column at all** for this deck — only the compiler-assigned statement number and a location field ([J 90.05] listing, PDF p. 192; cf. J 02.02.B.1, which reserves a first column for "source program card sequence numbers").
- **Procedure-name margin.** Labels sit in cols. 7–12 and "stick out" into the margin, extending into the text area when longer than six characters ([F p. 37]). In the F sample, long labels are written **alone on a line with the sentence starting on the next line** (`COMPARE.EMPLOYEE.NUMBERS.`, `WITHOLDING.TAX.ROUTINE.`, `BOND.CALCULATION.`, F pp. 91, 94), which strains F's own rule 1 that "a named sentence follows its name … on the same line as its name" ([F p. 37]). The J listing always re-joins label and sentence on one print line ([J 90.05] listing, PDF p. 195). A parser must accept the label-on-its-own-line layout.
- **Continuation.** Data/environment entries continue via a non-blank column 72; the F machine listing actually shows the mark: serial 09008/09009 splits the data-name `RETIREMENT.`/`PREM` across two cards with `X` printed in the CONT column ([F p. 104]; rule at J 02.03.A.2.a–b, including the rule that name-field blanks are squeezed out when rejoining). Procedure text needs no continuation character (J 02.03.A.2.a); every sample sentence simply flows across lines.
- **Literal continuation.** The F TABLE's initial value is a single 132-character literal carried across six cards, with opening/closing quote marks repeated on each line ([F p. 100] and its facsimile note). J 02.03.A.2.c pointedly notes that literals "continued on multiple lines in violation of the rules given on page 83 of the General Information Manual are handled correctly" by the 7090 processor but that this leniency should not be relied on for compatibility.
- **Statement termination.** Procedure sentences end with period-blank; anything after it on the card is commentary (J 02.03.A.3.a, [J 90.01.03] A.1.a.ix). Data and environment entries must **not** use a period — "a period is considered part of the previous word, thus creating an undefined name" (J 02.03.A.3.b; also [J 02.06.02]). The samples obey this exactly: every J environment entry is period-free while every procedure sentence is period-terminated ([J 90.05] listing, PDF p. 195).
- **Spelling is verbatim.** The section name `WITHOLDING.TAX.ROUTINE` (single H) is spelled that way on the F form, in the F machine listing, and by the J compiler's echo ([F p. 94]; [J 90.05] listing, PDF p. 196) — names are arbitrary strings; nothing normalizes them.

### 9.3 Data description in practice

#### 9.3.1 Level structure and layout

- Hierarchies run 1–4 levels deep in both samples (limit: 23 levels, J 90.01.05.j). The J listing echoes the programmer's leading-zero style inconsistently within one deck — MASTER's fields use `1/2/3/4`, DETAIL's use `01/02/03` ([J 90.05] listing, PDF p. 192) — consistent with "leading zeros are optional" (J 02.05.A.1). Indentation of names on the forms and listing is cosmetic; only the level number governs (e.g. level-2 `NETPAY` at the margin, level-2 `WHT` indented, [F p. 98]).
- **RECORD type marks only filed records.** In J, MASTER, DETAIL, CHECK, PAYRECORD, DEPARTMENT.TOTAL, BONDORDER, ERROROUT are `RECORD`; the working areas WORKING, INTERNAL.TOTALS, GRAND.TOTALS, and TABLE are plain level-1 hierarchies with no type code ([J 90.05] listing, PDF pp. 192–194). F likewise leaves TABLE without RECORD but marks CURRENT as a RECORD though it is never filed ([F p. 100]).
- **Justification.** In the J listing only the MASTER record prints an `L` in the MJ column; the other six RECORD entries carry no mark and rely on the default that fields of the highest level are left justified unless specified otherwise ([J 90.05] listing, PDF pp. 192–194; default rule [J 02.05.01]). The F form's hand tick under JUSTIFY (transcribed `[JUSTIFY: <]`, [F p. 95]) corresponds to `L` in F's machine listing, which prints it for every record except CURRENT ([F pp. 103–104]). Arithmetic fields are internal right-justified: "right justification is specified for increased operating efficiency" ([J 90.05.01]; rule at J 02.05.D.2).
- **Storage model made concrete.** [J 90.05.01]–90.05.02 spells out the model the descriptions imply: the six-bit character is the smallest describable/addressable unit ("Individual bits may not be described or referenced"); the 9's of an internal field tell the processor the largest magnitude and "the number of words (when R is specified) or the number of characters (when L or no justification is specified)"; MASTER occupies exactly words 1–15 with NAME's odd 15 characters padded by the 3-character field TRIGGERS; DETAIL's word 3 holds HOURS "in the first three characters; 3 blanks (supplied automatically)" ([J 90.05.02]). F achieves the same word alignment with **unnamed filler fields** — a nameless level-2 `AAA` at the end of MASTER and `AAAAA` at the end of DETAIL ([F pp. 95–96]) — where J prefers a named field (`TRIGGERS`) or automatic padding. Both filler idioms must be supported. See §3 (Data description and storage model).

#### 9.3.2 Type codes and pictorials actually exercised

| Feature | F sample | J sample | Rule / note |
|---|---|---|---|
| Numeric external | `99`, `9999`, `99V999`, `9(5)V99`, `9(6)` | `99V9` (DETAIL HOURS), `9V99` (TABLE.ITEM INSPREM, RETPREM, st. 171–172) | J types the detail-record fields alphameric except HOURS: "HOURS is the only field … specified as numeric" — a rationale scoped to the DETAIL records ([J 90.05.02]) |
| Alphameric | `A`, `AAA`, `A(15)` | `AA`, `AAAA`, `A(6)`, `A(15)`, `A(18)`, `A(23)`, `A(30)` | fields F typed `99` (DEPARTMENT, MONTH…) are `AA` in J — see 9.5.3 (HIGH.VALUE) |
| Internal mode | none written | `IR99V999`, `IR9(4)V99`, `IR99` … | mode+justify written as prefix letters of the pictorial, as in J 02.03.D's own example `X 01 IR999` |
| Edited | `$***9.99`, `8889.9-`, `$8889.99-`, `$88889.99-`, `$88899.99-` (non-exhaustive) | `$8889.99`, `8889.99`, `8889.9`, `88889.99`, `899V99` (non-exhaustive) | `8` = zero-suppress digit, `$` before `8`s floats, `*` = check-protect fill, trailing `-` = sign position ([F p. 80]) |
| RCDMRK | — | `ENDFRSTLINE 02RCDMRK A` (listing st. 42) | inserts a one-character record-mark constant; pictorial `A` supplied automatically (J 02.05.B.4) |
| COPY | `GRAND.TOTAL 1COPY DEPARTMENT.TOTAL` (F pp. 99, 104) | **absent** — GRAND.TOTALS written out field-by-field (listing st. 133–142) | **F/J divergence:** "Implementation of COPY has been deferred" (J 90.01.03.b.i) |
| REDEF | unnamed entry `1REDEF TABLE`, then `TABLE.ITEM 2 12` ([F p. 100]/104) | bare line `REDEF TABLE` (compiler names it `GN)057`), then `TABLE.ITEM 1 12` (listing st. 168–169) | J's rule: the REDEF line carries "no additional coding except a serial number and the name of the item being redefined", and the first following item must have **the same level** as the redefined item (J 02.05.B.3.a) — the F sample violates both halves; see Ambiguities |
| Constants (initial values) | TABLE = one 132-char alphameric literal over 6 cards ([F p. 100]) | per-field constants: `A '1'`, `A '-'`, `A(30) ' '`, `A(21) '          DEPARTMENT '`, `IR9(5) '00999'`, `'080060'` … | J 02.05.E.2; [J 90.05.04]: for blank constants, "If the format specification indicates the length of the field, it is unnecessary to provide the proper number of blanks between quote marks" |

- **The TABLE rewrite is a lesson in modes.** F initializes the whole rate table as one alphameric literal and redefines it into twelve 11-character `TABLE.ITEM`s of `99V999`/`9V99`/`9V99` ([F p. 100]). J instead writes twenty-four constants — for each entry an internal `IR9(5)` rate constant plus one 6-character external constant packing both premiums — then redefines to `TABLE.ITEM … RATE IR99V999, INSPREM 9V99, RETPREM 9V99` ([J 90.05] listing, PDF pp. 193–195, st. 143–172). The reason is doctrinal: "Arithmetic operations are performed only in the internal (binary) mode" (J 02.03.D), and the searched key RATE must compare against internal MASTER RATE.
- **Print records are described character-by-character.** The J CHECK record is a two-print-line image: carriage-control constant `'1'`, date with `'-'` constants between MONTH/DAY/YEAR, a RCDMRK separating the lines, second-line control constant `'2'`, NAME, and edited AMOUNT ([J 90.05.03]–90.05.04; listing st. 32–46). DEPARTMENT.TOTAL likewise embeds its own report wording as constants (`'          DEPARTMENT '`, `' TOTALS     '`) around the live fields (listing st. 79–99). PAYRECORD interleaves one-, two- and three-blank constant fields between every column (listing st. 48–78); F does the same with unnamed `A` fields ([F p. 98]). Report formatting in COMTRAN lives in the data description, not in the procedure.
- **State inside an output record.** J keeps the "current department" comparand as `CURRENT.DEPT`, a live field **inside** the DEPARTMENT.TOTAL print record (listing st. 81), tested by `IF CURRENT.DEPT IS NOT EQUAL TO D.DEPT` (st. 200). F kept an equivalent separate record CURRENT with fields DEPARTMENT and INDEX ([F p. 100]).
- **Name reuse and near-collision management.** The same simple names (DATE, MONTH, DAY, YEAR, GROSS, NAME, EMPLOYEE.NUMBER, …) recur across records and are disambiguated by left-qualification (`MASTER DATE`, `DETAIL EMPLOYNO`; rules [F pp. 15–16]). Where the J programmer wanted a field *excluded* from CORRESPONDING traffic or from qualification requirements he chose a *different* name: PAYRECORD's `HRS`, `INS.PREM`, `RET.PREM` (listing st. 62, 72, 74) against WORKING `HOURS` and TABLE.ITEM `INSPREM`/`RETPREM`. J's MASTER also holds both a group `DAT` (EMPLOYEE.NUMBER + NAME, used whole for error reporting: `MOVE MASTER DAT TO ERROROUT INFO`, st. 193) and a field `DATE` — three letters versus four; the conversion notes confirm `DAT` is genuinely the source name ([J 90.05] listing, PDF pp. 192, 195). Sample names freely use imbedded periods (`D.EMP.NO`, `INTERNAL.TOTALS`) — a period-containing name is still one "simple" name ([F p. 15]).
- **None of the sample's data names collide with reserved words** (list at [F p. 110]; key-word classes at J 02.03.B), including apparently risky choices like DATA (an F group name, [F p. 95]), CHECK, TABLE, INDEX, DATE, and AMOUNT. The reserved list is small and the samples exploit that; only the always-key words (FILE, RECORD, BEGIN, FOR, IN, ON, WHEN, ZERO(S), HIGH.VALUE(S), LOW.VALUE(S) — J 02.03.B.1) are truly untouchable.

### 9.4 Environment description as actually written (J only)

The complete environment division is fourteen entries ([J 90.05] listing, PDF p. 195, st. 173–186):

```
173,00           INPUTMASTER      FILE   INPUT,BINARY,TAPE,MASTER,BLOCKSIZE 300
174,00                            SPECIFINPUTMASTER, UNIT1 'D1',OPENW,CLOSER
...
181,00           PAYFILE          FILE   OUTPUT,BCD,TAPE,PAYRECORD,
                                           DEPARTMENT.TOTAL,BLOCKSIZE 20
182,00                            SPECIFPAYFILE, UNIT1 'D3',OPENW,CLOSER,LOW
```

- **Option order is looser than the general form.** The published FILE-card form places `,BLOCKSIZE nn` *before* `,record.name.1` ([J 02.06.03]); every sample FILE card writes it *after* the record names. The stated ordering constraint is only that per-record options follow their record name (J 02.06.04.a) — the sample is the proof that file-level options may trail.
- **Fixed columns show through the listing.** The FILE/SPECIF type code occupies cols. 25–30 and the description begins at col. 31, so `SPECIF` abuts the file name (`SPECIFINPUTMASTER`); the file.name "must be the first item of the SPECIF card description field" (J 02.06.D.1). FILE entries carry their name in the Name field (cols. 7–22); SPECIF entries carry none.
- **One record, two files.** MASTER is named on both INPUTMASTER and OUTPUTMASTER FILE cards; procedure-division `FILE MASTER` (st. 208) then files it into the output file it is associated with (J 02.07.07.D.1.a) — the master is updated in place in the input buffer (locate mode, no HOLD/SPANS specified; [J 02.07.02]–03) and rewritten. "Twenty 15-word records are grouped to form 300-word blocks … each record complete within a block, since it is desired to process input records in the buffer area, in the locate mode" ([J 90.05.02]).
- **BLOCKSIZE as an input truncator.** DETAILFILE's tape blocks are physically 14 words, but `BLOCKSIZE 3` reads only the 3-word record: "Alternatively, BEGIN and BLOCKSIZE 14 might have been specified … which would have enabled correct processing but allowed the full 14-word block to enter core" ([J 90.05.03]; BLOCKSIZE = "maximum number of words to be input from an input block", J 02.06.04.b).
- **Multi-record output file.** PAYFILE names two record types (PAYRECORD, DEPARTMENT.TOTAL) on one FILE card continued onto a second card; `BLOCKSIZE 20` fits the larger record, and "the shorter records … will be written with proper length, and will always begin a new buffer. If this short record was only 10 words long, it would be necessary to specify BEGIN … to avoid grouping of the short records" ([J 90.05.04]) — an under-documented boundary rule; see Open questions.
- **SPECIF idioms:** symbolic unit assignment (`UNIT1 'D1'` … `'D4'`, `'C1'`–`'C3'`), `OPENW` (no rewind before open), `CLOSER` (rewind only on close), and low density (`LOW`) on every BCD tape destined for peripheral card/print equipment but not on the binary master tapes ([J 90.05] listing, PDF p. 195; option meanings at J 02.06.D).
- The compiler punched matching Loader `*FILE`/`*SPEC` cards ([J 90.05] listing, PDF p. 198); note the original 1961 print reads `*SPEC 05` where `*SPEC 06` (for BONDORDERFILE, `*FILE 06`) is expected — flagged in the conversion notes as a keying anomaly of the original listing.
- **F/J divergence:** the F sample simply assumes files exist (`OPEN ALL FILES.` with no environment; `FILE MASTER IN ERROR.FILE` against an undeclared file, [F p. 91]). Under J, "All records associated with the file must be named on the FILE card" and every file needs a FILE card (J 02.06.C, 02.07.08); qualified names are barred from the environment division (J 02.03.C).

### 9.5 Procedure idioms, verb by verb

#### 9.5.1 CALL — and a real F/J semantic divergence

Both programs open with CALL as their first statement, defining abbreviations before any executable flow ([F p. 91]; J listing st. 187):

```
F:  CALL (EMPLOYEE.NUMBER) EMPLOYNO, ... (DEPARTMENT.TOTAL) DPT.
J:  CALL (MASTER EMPLOYEE.NUMBER) M.EMP.NO, (DETAIL EMPLOYEE.NUMBER) D.EMP.NO, ...
```

- F renames the *shared* simple name EMPLOYEE.NUMBER (it occurs in MASTER, DETAIL, CHECK, PAYRECORD, BONDORDER) and afterwards **qualifies the synonym**: `DETAIL EMPLOYNO`, `MASTER EMPLOYNO`, `DPT INSPREM`, `TABLE.ITEM INSPREM (INDEX)` ([F pp. 91–94]). F's CALL description permits synonyms for compound names and requires synonyms to be single names, but never requires old.name uniqueness ([F p. 59]) — indeed [F p. 59]'s own example is `CALL (INSURANCE.PREM) INSPREM`, the very rename this sample uses against *two* INSURANCE.PREM fields.
- J's rule: "The (old.name) in a CALL statement must be unique … or if sufficient qualifiers are used to identify it uniquely. The use of record.names should be avoided" ([J 02.04.05]); subscripted old.names are barred (J 90.01.01.i). The J sample complies: each old.name is a qualified unique field, and each synonym (`M.EMP.NO`, `D.DEPT`, `M.BND.DED`, `M.BND.ACC`) is thereafter used **unqualified**. CALL is also the sanctioned device for reducing qualified names to the single words demanded by the environment division and CRYPT (J 02.03.C, J 90.01.01.ii).

#### 9.5.2 The GET/FILE matching loop

The balanced-line skeleton is identical in both versions ([F pp. 91–92]; J listing st. 190–198):

```
GET.MASTER.  GET MASTER, AT END DO END.OF.MASTERS.
GET.DETAIL.  GET DETAIL, AT END GO TO END.OF.DETAILS.
COMPARE.EMPLOYEE.NUMBERS.  GO TO CHECK.NEW.DEPT WHEN D.EMP.NO =
             M.EMP.NO,  LOW.DETAIL WHEN D.EMP.NO LT M.EMP.NO.
HIGH.DETAIL. ...
```

- Only the `GET record.name` form is ever used, never `GET RECORD FROM file.name` (whose GIM description J explicitly corrects and restricts, [J 02.07.04]). A comma precedes `AT END` in every sample GET although the general form shows none ([F p. 109]).
- The `AT END` clause is exercised in both allowed flavors — an imperative `DO` and an imperative `GO TO` — and is limited to "a single imperative statement only" ([J 02.07.05]/06). The asymmetry is semantic: masters exhausting must *return* to keep draining details (`DO END.OF.MASTERS`), details exhausting need not (`GO TO END.OF.DETAILS`).
- The multi-destination conditional `GO TO … WHEN …, … WHEN …` relies on documented fall-through: "If none of the conditional expressions … is found to be true, control passes to the next clause or sentence in sequence" ([F p. 48]) — HIGH.DETAIL is placed immediately after and is reached by fall-through; in F that is its only entry, while J's END.OF.DETAILS also enters it by an explicit `GO TO HIGH.DETAIL` (st. 198).
- Unmatched-record handling shows both FILE forms: F files the same record into alternate files (`FILE MASTER IN ERROR.FILE`, `FILE BONDORDER IN ERROR.FILE`, F pp. 91, 94 — the `IN` form for a record "associated with several output files", J 02.07.08.D.1.b); J instead builds a dedicated ERROROUT record (`MOVE 'M' TO ERRORTYPE, MOVE MASTER DAT TO ERROROUT INFO, FILE ERROROUT`, st. 193) so every FILE is the plain form.
- End-of-run: `MOVE CORRESPONDING …, FILE PAYRECORD, CLOSE ALL FILES` then **F: `STOP 1234.`** (the `STOP n` general form, F pp. 92, 109) versus **J: `STOP RUN.`** (st. 199) — "A STOP RUN instruction must be included in each program"; it closes all open files itself ([J 02.04.06] #9). **F/J divergence:** F's Appendix 2 knows no STOP RUN; a 7090 compiler must accept STOP RUN and treat it as mandatory.

#### 9.5.3 The HIGH.VALUE sentinel idiom — and the typing change it forced

Both versions equalize the merge with figurative sentinels ([F p. 92]; J listing st. 197–198):

```
END.OF.MASTERS.  IF D.EMP.NO = HIGH.VALUE THEN GO TO END.OF.RUN
                  OTHERWISE SET M.EMP.NO = HIGH.VALUE.
```

- HIGH.VALUE is one of the four pre-defined figurative constants ([F p. 112] glossary; values: `(` in the 709 sequence, `9` under COM — J 02.04.01.a). The J deck selects no COM OPTION card, so the sentinel is `(`'s.
- **F/J divergence:** J rules that "HIGH.VALUE, LOW.VALUE and BLANK may be compared to alphameric fields only" (J 02.04.01.b), and its figurative-constant chart marks HIGH.VALUE into external-decimal targets as doubtful (starred) and into internal decimal as "Illegal*" ([J 02.04.02]). F's EMPLOYNO fields are numeric `99`/`9999` ([F p. 95]) — the 1960 sample would draw diagnostics from the 1962 compiler. The J sample re-types every employee-number field as `AA`/`AAAA` alphameric (listing st. 4–5, 25–26), exactly what the rule requires. Group-level `SET M.EMP.NO = HIGH.VALUE` also leans on two other rules: a group without a pictorial is alphameric (J 02.05.E.1.c) and `SET alpha.1 = alpha.2` is the one non-arithmetic SET allowed ([J 02.04.05]).
- The equality tests compare 6-character non-format groups; non-format fields "are compared alphamerically" (J 02.04.C.4), and the routing comparisons (`=`, `LT`) are alphameric-vs-alphameric as J 02.04.C.1 requires.

#### 9.5.4 DO, sections, and control flow

- **DO of a one-sentence procedure.** `AT END DO END.OF.MASTERS` targets a *named sentence*, not a section — legal because a DO-able procedure is "either named sentences or sections", with sections required only for multi-sentence bodies ([F p. 49], p. 50).
- **DO'd code that never returns.** END.OF.MASTERS, entered by DO, exits via `GO TO END.OF.RUN` on the final pass (both versions). Likewise SEARCH, entered by `DO SEARCH FOR INDEX = 1(1)12`, escapes its own loop with `GO TO NET` ([F p. 94]; J st. 225). Both strain the closed-subroutine doctrine — a DO'd procedure "must be entered only through the use of a DO command" and implicitly returns to its caller ([F p. 50]) — by abandoning the return path mid-execution. The compiled sample proves the implementation tolerates it. See Ambiguities.
- **The indexed DO.** `DO SEARCH FOR INDEX = 1(1)12.` ([F p. 92]; J st. 206) matches the general form `DO procedure.name FOR index.name = p(q)r` (F pp. 50, 108), the index being "a field which has been defined in the data description as an integer" ([F p. 50]): F declares INDEX as external `99` in the CURRENT record ([F p. 100]); J moves it to WORKING as `IR99` (listing st. 121) per the internal-mode efficiency doctrine (J 02.03.D). Relevant implemented semantics: a DO section is "always … performed at least once regardless of the values of the loop control variables", and no object-time subscript-bounds check exists ([J 90.01.02]). Arrays are 1-origin: "The initial value of an array is A(1) and not A(0)" ([J 02.04.07.01]).
- **The subscript-copy idiom.** Inside SEARCH, J tests `TABLE.ITEM RATE (INDEX)` but then executes `MOVE INDEX TO POS, MOVE INSPREM (POS) TO …, MOVE RETPREM (POS) TO …` (st. 225). This is a direct application of the published advice: every unique array/subscript combination costs a positional indicator, and "when a subscript changes value, all positional indicators containing that subscript will be re-evaluated. Use of the same subscript names for multiple purposes generally causes unnecessary calculations … but it will not be incorrect" ([J 90.01.02]; mechanism at J 02.04.D). By subscripting the premiums with POS, only the RATE indicator recomputes on each loop step. F's original uses INDEX for all three references ([F p. 94]). Subscripts are written space-separated after a qualified name: `TABLE.ITEM RATE (INDEX)`.
- **Sections in practice.** F defines four (`FICA.ROUTINE`, `WITHOLDING.TAX.ROUTINE`, `BOND.ROUTINE`, `SEARCH`), J five (adding `DEPARTMENT.END`) — far under the limit of 35 sections (J 90.01.05.b). All follow the pattern `name. BEGIN SECTION.` … `END name.` ([F pp. 56–57]); the closing END may itself be labeled to give the section an internal exit point (`BOND.END. END BOND.ROUTINE.`, `SEARCH.END. END SEARCH.` — [F p. 94]; J st. 223, 226), the target of forward `GO TO`s from inside the section. BOND.ROUTINE also loops internally by backward `GO TO BOND.CALCULATION` ([F p. 94]). DEPARTMENT.END is DO'd from two different callers (J st. 199, 200), the explicitly permitted "addressing of a procedure by more than one DO command" ([F p. 50]).
- **Conditional DO-then-continue.** `CHECK.NEW.DEPT. IF CURRENT.DEPT IS NOT EQUAL TO D.DEPT THEN DO DEPARTMENT.END OTHERWISE GO TO COMPUTE.PAY.` followed by a sentence that runs only after the DO returns (J st. 200–201) — the standard idiom for "call on condition, else skip the post-processing".

#### 9.5.5 Conditional sentences and relational spellings

The samples freely mix every documented spelling of the relations, all in ordinary IF … THEN … OTHERWISE sentences whose branches are comma-chained imperative clauses:

| Spelling | Sample instance |
|---|---|
| `IS EQUAL TO` / `IS NOT EQUAL TO` | [F p. 91]; J st. 200, 205 |
| `=` (in a condition) | `IF D.EMP.NO = HIGH.VALUE` (J st. 197; [F p. 92]) |
| `IS LESS THAN` / `IS GREATER THAN` | [F pp. 91–93] |
| `LT` / `GT` | `D.EMP.NO LT M.EMP.NO` (J st. 192); `IF MASTER RATE GT …` ([F p. 94]; J st. 225) |
| `IS NOT GREATER THAN` / `NOT GT` | [F p. 94]; `IF MASTER BONDENOMINATION NOT GT M.BND.ACC` (J st. 219) |

An OTHERWISE branch may itself end in `GO TO`, and a THEN branch may carry several commands ending the sentence (`… THEN SET …, SET MASTER FICA = 144.00.`, J st. 212).

#### 9.5.6 SET, arithmetic, and the TR truth function

- Expressions rely on documented precedence (unary TR/ABS/−, then `**`, then `*` `/`, then `+` `-`, left-to-right within a level — [F p. 107]; J 02.04.05.01.b): `SET DETAIL GROSS = DETAIL GROSS + MASTER RATE * 40` ([F p. 92]); parentheses used only where needed: `(DETAIL HOURS - 40) * MASTER RATE * 1.5` ([F p. 92]), `(WORKING HOURS * 1.5 - 20) * MASTER RATE` (J st. 203, an algebraic refactoring of F's two-step overtime computation).
- Numeric literals appear with and without a leading integer digit: `0.03`, `1.5`, `144.00` ([F pp. 92–94]; `1.5` is on p. 92), `.03` (J st. 211), `40.0` (J st. 203).
- **The TR clamp.** J replaces F's IF/OTHERWISE zero-floor on withholding tax with a single statement (J st. 215):

  ```
  SET WORKING WHT = WORKING WHT * TR(WORKING WHT GT 0),
  ```

  TR converts the parenthesized conditional to arithmetic 1 or 0 (truth functions, [F p. 24]; TR listed as a unary operator, [F p. 106]; in J's operator hierarchy at J 02.04.05.01.b but otherwise barely mentioned). This is the only TR usage in either manual's sample program — and the only *compiled* one; [F p. 24] gives the defining worked example `SET DISCOUNT = ORDER.AMOUNT * .05 * TR (ORDER.AMOUNT IS GREATER THAN 1000).` — confirming the operator survived into the implemented language.
- **Staged arithmetic.** F computes directly into record fields (`SET DETAIL GROSS = …`); J stages everything through the internal right-justified WORKING area and only MOVEs results outward (st. 202–208) — the practice J 02.03.D recommends ("fields frequently referenced in arithmetic expressions should be converted to internal form right justified", [J 02.04.05]).
- `ADD a TO b` with multiple targets in one command: `ADD M.BND.DED TO M.BND.ACC,INTERNAL.TOTALS BONDEDUCTION.` (J st. 217).

#### 9.5.7 MOVE in practice

- **One source, many destinations:** `MOVE DETAIL HOURS TO WORKING HOURS, PAYRECORD HRS.` (J st. 202); `MOVE INSPREM (POS) TO INS.PREM, WORKING INSURANCE` (J st. 225) — a single MOVE feeding an edited report field and an internal accumulator, exercising automatic conversion (numeric → edited and external → internal; [J 02.04.03]).
- **Whole records and groups as operands:** `MOVE DETAIL TO ERROROUT INFO` (a 3-word record into an `A(23)` field, J st. 196) and `MOVE MASTER DAT TO ERROROUT INFO` (a group, st. 193) — groups without pictorials are alphameric, and "all types of data may be moved into an alphameric field but the contents of an alphameric field may only be moved to another alphameric field" (J 02.04.03.c).
- **Figurative sources:** `MOVE ZEROS TO INTERNAL.TOTALS, GRAND.TOTALS` bulk-clears entire level-1 hierarchies at start of run (J st. 188); `MOVE BLANKS TO PAYRECORD EMPLOYNO, PAYRECORD NAME` ([F p. 93]); `MOVE BLANKS TO PAYRECORD BONDEDUCTION,PAYRECORD BONDENOMINATION` blanks *edited* fields (J st. 205) — see Ambiguities on the chart's starred "blanks*" entry ([J 02.04.02]).
- **Alphameric literals as data:** `MOVE 'M' TO MASTER ERRORCODE` ([F p. 91]), `MOVE 'D' TO ERRORTYPE` (J st. 196), and `MOVE 'GT' TO PAYRECORD DEPARTMENT` (J st. 199) — the reserved abbreviation GT is harmless inside quotes.

#### 9.5.8 MOVE/ADD CORRESPONDING in practice — including the sharpest F/J rule divergence

- Multi-target CORRESPONDING is routine: `MOVE CORRESPONDING DETAIL TO PAYRECORD, CHECK` ([F p. 93]; J st. 208), `ADD CORRESPONDING DETAIL TO DEPARTMENT.TOTAL, GRAND.TOTAL` ([F p. 93]), `ADD CORRESPONDING WORKING TO MASTER TOTALS, INTERNAL.TOTALS` (J st. 208 — note the *qualified group* `MASTER TOTALS` as a target; similarly `ADD CORRESPONDING DETAIL TOTALS TO MASTER TOTALS`, [F p. 93]).
- The J sample is engineered around the implemented matching rule — "correspondence is determined at the lowest possible level on the basis of name only. All qualifiers must be present and identical through the level of the name itself" ([J 02.04.04]): WORKING's FICA/WHT deliberately do *not* land in MASTER TOTALS (they are handled inside the FICA/withholding sections), because TOTALS has no children by those names; PAYRECORD's HRS/INS.PREM/RET.PREM names keep those fields out of CORRESPONDING traffic and are loaded explicitly (st. 199, 202, 225). `MOVE CORRESPONDING MASTER TO BONDORDER` (st. 220–221) exercises the group-to-elementary case of J 02.04.04.c: MASTER's EMPLOYEE.NUMBER group corresponds to BONDORDER's elementary `A(6)` EMPLOYEE.NUMBER and moves as alphameric.
- **F-sample reliance on name-only matching.** F defines correspondence merely as "a field having the same name" in the receiving area ([F p. 43]). Its `MOVE CORRESPONDING DETAIL TO PAYRECORD, CURRENT` ([F p. 93]) expects DETAIL's DEPARTMENT — buried at level 4 under DATA EMPLOYEE.NUMBER — to reach CURRENT's level-2 DEPARTMENT. Under the implemented qualifier-chain rule that pair does **not** correspond (missing qualifiers; J 02.04.04.b), and the J rewrite replaces it with an explicit `MOVE D.DEPT TO CURRENT.DEPT` (st. 201). Likewise F's `MOVE CORRESPONDING DEPARTMENT.TOTAL TO PAYRECORD` ([F p. 93]) can never transfer INSURANCE.PREM/RETIREMENT.PREM/BONDPURCHASES (PAYRECORD's fields are named INSURANCE/RETIREMENT/BONDENOMINATION), under either edition's rule — an apparent latent defect of the F sample; J instead prints department totals from their own record. Gold for a compiler writer: implement [J 02.04.04], and expect 1960-vintage code to have assumed less.

### 9.6 What the compilation listing reveals about the source language

(Source-level observations only; for generated code see Appendix 90.02 material.)

- **Statement numbering.** The compiler assigns numbers of the form `xxxxx,00` to every "Procedure sentence, Data Description entry or Environment card" (J 02.02.B.1.b), one continuous series across the whole program: data 1,00–172,00, environment 173,00–186,00, procedure 187,00–229,00 ([J 90.05] listing, PDF pp. 192–197). Error messages address `line,clause` — "The last two [digits] … tell which clause is being referenced. The digit(s) preceding the comma tell which line" — with `9999,99` reserved for errors "not confined to a single source statement" (J 02.02.B.2). Because this compilation is clean, only `,00` forms appear. The placement of numbers 217–221 does not align one-to-one with sentences (a number appears mid-sentence at 220,00; `BEGIN SECTION.` shares 217,00 with the following sentence) — see Ambiguities.
- **Generated names for unnamed source constructs.** "In some cases, names generated by the Compiler, i.e., GN)nnn, are shown in the name field of Procedure statements or Data entries unnamed by the programmer" (J 02.02.B.1.c). In the sample: `GN)001`–`GN)056` for unnamed data constants, `GN)057` for the bare REDEF entry, `GN)000` for the opening CALL sentence, and `GN)077`, `GN)078`, `GN)083` for the *unnamed END sentences* of FICA.ROUTINE, WITHOLDING.TAX.ROUTINE and DEPARTMENT.END — while the programmer-labeled `BOND.END.`/`SEARCH.END.` END sentences keep their own names ([J 90.05] listing, PDF pp. 192–197). Generated names print abutting the following keyword (`GN)077END FICA.ROUTINE.`). The `)` in generated names cannot occur in programmer names, so the two name spaces cannot collide; the dictionary budget covers "all program names whether defined by the programmer or generated" (3500 max, J 90.01.05.a).
- **Name width vs. listing width.** 30-character names are legal ([F p. 15]); the listing's name column is narrower, so `BONDACCUMULATION` prints wrapped (`BONDACCUMULATI` / `ON`) with the location value only on the completing line ([J 90.05] listing, PDF p. 192 and conversion notes) — a display convention, not a language limit.
- **Echo fidelity.** The listing reproduces the source's own level-number style (`1` vs `01`), its spelling (`WITHOLDING`), its mode/justify prefixes (`IR99V999`), and the fixed-column abutments (`1RECORD`, `SPECIFINPUTMASTER`) — the listing is a reformatted echo of cards, and the columns of the coding form (name 7–22, type 25–30, description 31–71, continuation 72 for data/environment) remain visible through it (J 02.06.B.1; J 02.03.A.2).
- **Diagnostic summary.** A clean run ends with the single line `NO ERRORS WERE DETECTED DURING COMPILATION` after the CTD/CTE phase letters ([J 90.05] listing, PDF p. 197). Severity codes and the message catalog are in Appendix 90.04.
- **Deck identity.** The running head `DATE 10/18/61 TIME 2.45 ACCOUNT … ID. CT PUBLICATIONS PAGE n` is compiler output built from the control card's identifier, which is also punched into the `*CTEXT`/`*CTEND` loader cards ([J 90.05] listing, PDF pp. 192, 198, 216; cf. secondary.identifier, [J 02.01.01]).

### 9.7 What the execution output reveals

The run's reports ([J 90.05] listing, PDF p. 217) close the loop on the editing rules of §3:

- **Edited-field behavior in the flesh:** floating dollar signs hug the first significant digit (`$294.12`, `$364.16` under picture `$8889.99`); `8` positions zero-suppress to blanks (HOURS `40.0` under `8889.9`; GROSS ` 94.00` under `88889.99`); constant fields embedded in the record always print (the `-` date separators appear even on the grand-total line, whose date fields were blanked: `GT … - - 389.5 2730.39 449.35`); fields blanked by `MOVE BLANKS` print empty (bond columns for employees without bond deductions).
- **The CHECKFILE is a print-image tape:** its listing shows the carriage-control characters `1` and `2` as leading data characters of the two lines of each check, exactly as described in the record (`CNTRLCHAR A '1'`, `CNTRLCHARSECLINE … A '2'`; [J 90.05.03]).
- **ERRORFILE records are single-character-code + image:** `M011001AJAX T` (ERRORTYPE `M` + MASTER DAT), `D061500100661400` (ERRORTYPE `D` + the 18-character DETAIL record image inside `A(23)` INFO) — confirming the group/record-to-alphameric MOVEs of 9.5.7.
- The transcription preserves printer artifacts of the original (half-line staggering of trailing columns; `WCO J` where other reports print `WOO J`, and `MOCRE` where the expected name would be MOORE per the conversion notes' inference) — these are print/test-data anomalies of the 1961 run, not language phenomena (file conversion notes, [J 90.05]).

### 9.8 Consolidated F-sample vs J-sample divergence table

| Topic | F sample (1960) | J sample (compiled 1961/62) | Authority |
|---|---|---|---|
| Divisions present/order | `*PROCEDURE`, `*DATA`; no environment | `*DATA`, `*ENVIRONMENT`, `*PROCEDURE` | [J 90.05] listing; [F p. 87] |
| Serial sequence checking | checked ([F p. 37]) | not checked; sample deck prints none | J 02.03.A.1 |
| CALL old.name | shared simple name; synonym later qualified | must be unique (qualified old.name); synonym used unqualified | [J 02.04.05] |
| Employee-number typing for HIGH.VALUE | numeric `99`/`9999` | alphameric `AA`/`AAAA` | J 02.04.01.b, 02.04.02 |
| STOP | `STOP 1234` (`STOP n`) | `STOP RUN` (mandatory) | [J 02.04.06] #9 |
| COPY type code | `GRAND.TOTAL 1COPY DEPARTMENT.TOTAL` | not used — COPY deferred | J 90.01.03.b.i |
| REDEF coding | level-1 unnamed `1REDEF TABLE`; TABLE.ITEM level 2 | bare `REDEF TABLE` (GN-named); TABLE.ITEM level 1 = level of TABLE | J 02.05.B.3.a |
| Table initialization | one 132-char alphameric literal, 6 continuation cards | 24 per-field constants, internal + external, no continuations | J 02.03.D (internal arithmetic) |
| CORRESPONDING reliance | name-only matching assumed (`… TO PAYRECORD, CURRENT`) | qualifier-chain rule respected; explicit MOVEs where chains differ | [J 02.04.04] |
| Arithmetic staging | in record fields (external) | in WORKING (IR fields) | J 02.03.D |
| Error output | error code inside master/detail records, `FILE … IN ERROR.FILE` | dedicated ERROROUT record, plain FILE | [J 02.07.08] |
| WHT zero-floor | IF/OTHERWISE `SET … = ZEROS` | `* TR(WORKING WHT GT 0)` | F pp. 24, 106 |
| Subscript use in search | `INDEX` for all three arrays | `INDEX` for probe, copied to `POS` for fetches | [J 90.01.02]; J 02.04.D |

### 9.9 Flagged ambiguities (details in §8.5)

1. Statement-number placement at listing statements 217–221 vs the per-sentence numbering rule (J 02.02.B.1.b vs B.2).
2. F's name-only CORRESPONDING vs J's qualifier-chain rule; F sample moves that match nothing under J semantics.
3. F's CALL of a non-unique old.name with later-qualified synonyms vs J's uniqueness rule; J is silent on whether a synonym may be qualified at all.
4. `MOVE BLANKS` into edited/external fields is starred "doubtful" in J's chart yet compiles with no errors in the sample.
5. `*COMPILE LIST` on the sample listing vs the documented `$CMPLE` control card.
6. REDEF coding convention (F's leveled, named-line REDEF vs J's bare line + same-level first item).
7. GO TO exits from DO'd procedures vs the closed-subroutine doctrine.
8. The PAYFILE short-record/BEGIN boundary rule quoted in [J 90.05.04] has no stated general form.

---

## Open questions

Questions that remain after studying both manuals end to end — things neither manual answers and §8's plausible resolutions cannot fully settle. Grouped by area. Where a question grew out of a §8.5 catalog entry, the entry holds the working assumption; the question records what would confirm or refute it.

### Lexical

1. How does the compiler treat entirely blank cards in each division? Both manuals are silent; the only adjacent rules are the blank-column-72 entry terminator ([J 02.03.02]) and the assumed blank after column 72 ([F p. 28] rule 14).
2. What happens when text erroneously begins in the procedure-name margin (columns 7–12) of a continuation card — diagnosed, read as a name, or read as text? ([F p. 37] states the layout; no failure behaviour is defined.)
3. Is the word AS still reserved in J? F reserves it for `INCLUDE … AS`; INCLUDE is deferred and AS appears in none of J's three key-word lists. ([F p. 110]; [J 02.03.02]; [J 90.01.02])
4. What is the exact numeric ceiling behind msg 52 ("MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL.") — is F's 20-digit arithmetic-literal rule enforced verbatim? ([J 90.04.01]; [F p. 18])
5. Does the series-of-blanks-equals-one-blank rule ([F p. 27], rule 2; restated for the data form at [F p. 83]: "Multiple blanks, however, are treated as single blanks.") hold specifically between a pictorial and a constant in the Description columns under J, which never restates it?
6. When a named constant is continued across lines (each line a complete quoted constant, no assumed blanks), how are the parts laid out in storage — any padding or alignment between them? ([F p. 83]; [J 02.03.01] A.2.c says rule-violating continuations are "handled correctly" without defining the layout.)
7. May procedure-names be qualified by section names in ordinary procedure text ([F p. 26] allows section names "as parts of compound names"; [J 90.01.04] restricts qualified names only in Environment/CRYPT contexts), and how would a reference like `DO A B` be resolved?

### Program structure and control cards

8. What follows "END OF FILE ON JOB TAPE WITHOUT *FINISH CARD." (msg 132) — what severity, and is the partial compilation completed or abandoned? ([J 90.04.01])
9. What quantitative limit triggers "THIS SENTENCE EXCEEDS INTERNAL TABLE CAPACITY." (msg 177) — no maximum sentence length in cards, clauses, or internal words is stated anywhere.
10. Are multiple *PROCEDURE portions concatenated strictly in source-deck order into one contiguous stream (implied by [J 90.02.01]), and may a section be split across two portions separated by *DATA/*ENVIRONMENT material?
11. May a division header card carry serial numbers, identification, or continuation, and is the number of repeated headers of one division unlimited? ([F p. 27]; J is silent.)
12. When no PROGRAM.START appears, what transfer address does the compiler punch for the Loader — mechanically, what does *CTEND carry? ([J 90.02.01]–02; [J 90.03]; [J 03.02.08]) 

    **Resolved (90.05 listing evidence, 2026-08-01; scan-verified 2026-08-02):** the compiler defaults the transfer address to the first sentence of the Procedure Division. The sample (which has no PROGRAM.START) ends its text deck with the end-of-text special entry `00165 500000000165 01111 START GN)000`; control group 01111 means "end of text; the address of the corresponding data word contains the relative program entry point" ([J 90.03.04]), and the Text deck "corresponds exactly" to the listing's OCTAL/CNTRL columns ([J 90.03.03]) — so the punched entry point is 00165. In that record the tag column is blank: START prints in the operation column (column-aligned with the PZE above it) and `GN)000` in the variable field, so the punched transfer symbol is GN)000 — the compiler-generated name of statement 187,00, the first *PROCEDURE sentence (an unnamed CALL, which generates no code) and hence resolving to the same LOC as the source procedure-name START of statement 188,00 (written `START.` in the source name field). On PDF p. 200 both symbols do label LOC 00165, the `TSX SYS)175,4` / `PZE IOC)1` open-all-files sequence ([J 90.02.14]) that is the object program's first instruction. The listing then prints "THE LAST LOADER CONTROL CARD PUNCHED IS" (no period) and the *CTEND card image, which carries no transfer address: only *CTEND (cols 7-12), date.and.time (`DATE 101861 TIME 2.45`, cols 26-54) and secondary.identifier (`CT PUBLICATIONS`, cols 55-72) per [J 03.02.09], plus an undocumented sequence number (67; 15 on the matching *CTEXT) in the cols 73-80 region. deck.name (cols 1-6) prints blank on the sample's *CTEXT, *CTEND and every *FILE/*SPEC card, although [J 02.01.01] says the complete deck.name is punched in cols 1-6 of all Loader symbolic control cards — cf. the `CTC` token at cols ~1-3 under the *COMPILE card (Q70). The Loader's own default start point (first program of combined segments, variable by *START card) is [J 03.02.08]. ([J 90.05] listing, PDF pp. 195, 198, 200, 216; [J 90.03.03]-04; [J 90.02.14]; [J 03.02.08]-09; [J 02.01.01]; [J 90.04.01] msg 142; images/page-195.png, page-198.png, page-200.png, page-216.png)
13. Is the F rule that processor commands "should be written as unnamed sentences" enforced or merely advisory in J? ([F p. 60]; no corresponding diagnostic in [J 90.04].)
14. Are the "Appox-Max" internal table sizes hard failures or soft limits — most have matching diagnostics, but nested-section depth (18) and the internal dictionary (3500) have no visible message. ([J 90.01.05]; [J 90.04.01])
15. May external code GO TO an interior label of a non-DO'd section? Entry restrictions are stated only for DO-addressed procedures. ([F p. 50]; [J 90.04.01] msgs 99, 128)
16. What does the compiler do after "SENTENCE DELETED FROM TEXT" recoveries — is program continuity (fall-through into the next sentence) re-checked after deletions? ([J 90.04.01])

### Data description and storage model

17. The machine word size (36 bits / 6 BCD characters) is never stated in the language sections — it must be imported from 709/7090 architecture knowledge. Confirm every place the definition relies on it. ([J 02.05.04]; [J 02.07.03])
18. Is assigning a Quantity to an unnamed item without named subordinates an error, a warning, or silently accepted? Both manuals say only that it "should not" be done. ([F p. 77]; [J 02.05.04])
19. What are the absolute maximum field and record lengths for external decimal, internal decimal, and alphameric data? J defines the 10-digit single/double fixed-point boundary and a 16-digit scientific-decimal fraction cap, but no absolute maxima. ([J 02.05.05]–06)
20. What does Justify = L or R on a group (non-format-level) entry do — honored, ignored, or applied to the group as an alphameric whole? ([J 02.05.04] D.3; msg 39)
21. May V and the true decimal point `.` coexist in one pictorial, and how do S, V, and `.` interact in edited output? Each character is defined separately; no combination rules are given. ([F p. 80]; [J 02.05.05])
22. How are COND values other than quoted one-character constants handled (figurative constants, unquoted values)? All examples show quoted single characters. ([F p. 72]; [J 02.05.02])
23. What collating sequence governs alphameric comparison of *data* under the native option — F gives only blank-then-digits for serial checking and defers alphabetics to "the particular machine system" ([F p. 67]). **Resolved (scan check, 2026-08-01):** the native [J 02.06.16] display, now fully read (§1.1), governs on the 7090 — digits lowest (0 = LOW.VALUE) rising through the letters to `(` (HIGH.VALUE) highest; only the BCDIC names of the zone specials remain inferred. ([F p. 67]; [J 02.06.16]; images/page-050.png)
24. What happens at object time when a QUANTITY IN value exceeds the compile-time Quantity reservation? J says no execute-time check is made against the Quantity value, implying silent overrun — nowhere confirmed for this case. ([J 02.05.04])
25. Do editing characters (`8 $ * ,` …) have any meaning on input-describing pictorials, or only when the field is a target of MOVE/SET editing? ([F p. 80]; [J 02.05.05]; [J 02.04.06]–07)

### Arithmetic and data manipulation

26. How does rounding treat negative values and carry into the integer part (the round-half-up threshold itself is stated at [F p. 115]), and can rounding raise the overflow condition recorded in SYS)130? ([F p. 115]; [J 90.02.16]–17; [J 90.02.10]) 

    **Narrowed (90.02 + 90.05 mining, 2026-08-01; adversarially verified 2026-08-02):** mining the generated-code appendix together with the compiled sample fixes exactly where rounding happens, and shows that the only rounding either manual ever exhibits is object code that neither manual explains. 

    *In MOVPAK.* Rounding appears as five step-subroutines, one in each of the five — and only five — MOVPAK packages that are built from a step list ("two or more of the following instructions"): SYS)219 with SYS)183 (external decimal to external decimal), SYS)220 with SYS)185 (external decimal to edited), SYS)221 with SYS)189 (edited to external decimal), SYS)222 with SYS)190 (edited to edited), and SYS)274 with SYS)268 (edited to internal decimal in the AC-MQ) ([J 90.02.16]–19, 90.02.23, 90.02.30–31). Each is invoked by a bare transfer carrying no count — "TRA SYS)219 Round current character", "TRA SYS)221 Round current characters" (plural, as printed at 90.02.18), "TRA SYS)274 Round Current Character" — alone among the step instructions, every one of which is otherwise a `TXI SYS)nnn,1,<count>`; and each standalone entry says nothing beyond which package it serves ("This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields."). No line in [J 90.02.00]–90.02.33 describes what the round routine does, mentions sign, or mentions carry. The remaining numeric packages — SYS)184 (external to internal decimal), SYS)186/187/188 (internal decimal to external decimal: unsigned, overpunch minus, overpunch plus), SYS)246–247 (internal decimal to and from unjustified internal decimal) and SYS)267 (internal decimal to edited) — are called with a fixed one-to-three-word sequence and have no step list at all, so their lack of a round step shows only that they have no step vocabulary; it is *not* evidence that those paths do not round. The appendix labels the operation as acting on the "current character" and gives it no repetition count, but whether its effect is confined to that position is not stated — and the plural "Round current characters" at 90.02.18 is the one place the manual hints otherwise. 

    *In the compiled sample.* The sample emits no MOVPAK round step — its system references are 132, 133, 175, 177, 178, 180, 182, 184, 185, 190, 193, 198, 212, 214, 225, 226, 239–241, 243–245, 260, 267–269, 275, 283 and 294, none of them 219–222 or 274 — but it does emit rounding, inline, on the SET path, and it never writes TRUNCATED anywhere. All four of its multiply-then-store SET sequences end with the same tail; for "SET WORKING FICA = .03 * WORKING GROSS," (statement 211,00, [J 90.05] listing PDF p. 196) the generated code is ``` 01166 LDQ CP)+9 01167 MPY 4)GROSS 01170 XCA 01171 ACL CP)+34 01172 LRS 35 01173 DVP CP)+31 01174 STQ 4)FICA ``` ([J 90.05] listing, PDF p. 210), and the identical `XCA / ACL / LRS 35 / DVP / STQ` tail closes both GROSS branches of statement 203,00 at LOC 00632–00635 and 00644–00647 (PDF p. 206) and the withholding computation of 215,00 at LOC 01234–01237 (PDF pp. 210–211). The added constant tracks the *divisor*, not the statement: CP)+34 is added wherever the divide is by CP)+31, CP)+32 wherever it is by CP)+33. 

    **Inference (not stated in either manual; requires 709/7090 architecture knowledge):** that `ACL` — Add and Carry Logical, which adds into the accumulator's magnitude with the sign position untouched — is the half-adjust that [F p. 44] makes the SET default, added to the scaled product before the truncating `DVP` by the scale factor. On that reading two thirds of this question answer themselves for the arithmetic path: the carry propagates in binary through the whole accumulator before the divide, so carry into the integer part needs no separate mechanism; and because the addend goes into the magnitude with the sign untouched, the adjustment is away from zero — which is exactly the "half-adjust applied to the absolute value with sign restored" that §8.5.4 had inferred from period practice alone. Two caveats keep this short of proof: the constant pool's contents are not printed in the listing, so "CP)+34 is half of CP)+31" is an inference from the code's shape (nothing else explains a constant added immediately before the scaling divide in a program that never writes TRUNCATED), and every value in the sample is non-negative, so no negative case is actually exercised. 

    *Overflow.* Nothing connects rounding to SYS)130. "SYS)130" occurs exactly once in the whole manual, in its own definition — "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects the truncation of significant high order values (i.e. overflow)." ([J 90.02.10]) — which is scoped by subroutine rather than by cause, so a rounding carry out of the high-order position is neither asserted nor excluded; no subroutine anywhere in the appendix is described as testing or clearing the cell; and overflow detection is a separately counted step acting at the other end of the field ("TXI SYS)199, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW", with siblings SYS)195, 196, 201, 203, 204, 270, 277, 281). 

    **Inference:** on the sample's SET path the question cannot arise at all — the rounded quotient is stored by a bare `STQ` with no MOVPAK call anywhere in the sequence, so no rounding carry there can reach SYS)130; the cell is only at stake when a result is stored *through* a move/convert package. *F.* F's own rule stays a bare threshold: the least significant remaining digit "is increased by 1 when the part removed is greater than or equal to one-half", with 126.5027 rounding to 127, to 126.503 for a 6-position field and to 13 "which would be understood to be 130" for a 2-position field ([F p. 115]), and 2063.78 giving 2063.7 truncated against 2063.8 rounded ([F p. 116]). Every example is positive, none carries past the rounded position, and none produces a result that outgrows its field. 

    **Still open:**   
    (1) whether the MOVPAK round steps use the same half-adjust as the inline arithmetic path, and what they do with the sign — nothing in J says, and their internals are entered by a bare `TRA`;   
    (2) whether a rounding carry out of the high-order digit of a MOVPAK target sets SYS)130 or is dropped silently;   
    (3) whether plain MOVE rounds at all — F promises only that alignment "may involve the dropping of leading digits or low-order digits" ([F p. 42]) and none of its p. 43 examples discriminates rounding from truncation (99V99 1234 to 99V9 gives 123 either way; 99999 01234 to 999V9 gives 2340, a pure high-order drop), yet the four MOVE-serving packages are precisely the ones carrying round steps. 

    **Inference on (3):** the sample's three scale-changing MOVE stores — `CLA 5)NETPAY / LRS 35 / DVP CP)+24` feeding `TSX SYS)180,4` and `TXI SYS)267,1,4`, at LOC 00423–00425, 01112–01114 and 01141–01143 (PDF pp. 203, 209) — carry no `ACL`, i.e. they drop low-order digits with no half-adjust, in contrast with the four SET stores; that contrast is the strongest indication either manual offers that MOVE truncates where SET rounds, but the statements those sequences belong to are identified from the record/field names, since the object listing prints no statement numbers. What is newly settled is the inventory and the division of labour: rounding is a step-subroutine of the five step-list MOVPAK packages *and* an inline binary half-adjust before the scaling divide on the arithmetic path, and neither manual states the algorithm of either. (F pp. 42–44, 115–116; [J 90.02.10], 90.02.16–19, 90.02.23–24, 90.02.30–32; [J 90.05] listing, PDF pp. 196, 203, 206, 209–211; images/page-148.png, page-155.png, page-157.png, page-162.png, page-169.png, page-170.png, page-203.png, page-206.png, page-210.png; F images/page-120.png) ---
27. Does SET's ON OVERFLOW trigger only on the final store (F: "in the process of storing the final result") or also on intermediate upscale/downscale truncation, which the compiler separately warns about (msgs 27, 199)? ([F p. 44]; [J 90.04.01]) 

    **Narrowed further (90.02 re-mining + 90.05 listing evidence, scan-verified, 2026-08-01; adversarially verified 2026-08-02):** Reading the generated-code appendix entry by entry confirms the object-time mechanism, hardens the ground it stands on, and widens one gap. (i) SYS)130 is the processor's only documented object-time overflow indicator (its siblings are SYS)131 for "an improper data condition" and SYS)134 for floating point underflow), and it is armed from a single package: "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects the truncation of significant high order values (i.e. overflow)" ([J 90.02.10], verified on images/page-148.png), MOVPAK being the packaged object-time field-moving subroutines — "Many of the SYS Reference numbers are concerned with subroutines to move fields at object time. The interaction of various of these 'MOVE' subroutine made it desirable to package several of them together into one subroutine (called MOVPAK)." Note the wording names a *class*, not a list: no individual SYS) entry in [J 90.02.00]–90.02.33 is said to set the cell. (ii) Where MOVPAK's detection is made explicit, it is a compile-time-planned, character-counted step of a move/convert call — "TXI SYS)199, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW" ([J 90.02.16], verified on images/page-155.png) — and every such step (SYS)195, 196, 199, 201, 203, 204, 270, 277, 281) is documented only as "used in conjunction with" one of five families whose *source* is a character field: SYS)183 external→external decimal, SYS)185 external decimal→edited, SYS)189 edited→external decimal, SYS)190 edited→edited, SYS)268 edited→internal decimal ([J 90.02.15]–21, 90.02.30–32). (iii) The fixed-point scaling and arithmetic routines SYS)163–166 (upscale), SYS)167–168 (downscale), SYS)169 (divide) and SYS)170–171 (multiply with product downscale) are never called MOVPAK subroutines, are never said to set SYS)130 or any other cell, and are each invoked by a bare `TSX SYS)nnn,4` plus at most one `PZE CP)+NN` parameter word with a single normal return — none of the alternate or error exits the appendix does spell out where they exist ("HIGH RETURN from comparison / EQUAL RETURN from comparison / LOW RETURN from comparison" for SYS)162; "If an error is detected during conversion, return is 1,4 to routine SYS)263 which prints an error message." for SYS)261) ([J 90.02.12]–13, 90.02.29; verified on images/page-151.png and page-152.png). (iv) No entry in [J 90.02.00]–90.02.33 tests, branches on, or clears SYS)130, and the compiled sample never references it. 

    **Inference (not stated in either manual):** the overflow condition belongs to the move/convert path alone — matching F's "In the process of storing the final result of a SET command" ([F p. 44], verified on F28-8043 images/page-050.png) — and intermediate upscale/downscale/multiply/divide truncation cannot raise it. This rests on SYS)163–171 lying outside MOVPAK altogether, not merely on their lacking a test step, and it is exactly why the compiler diagnoses the scaling losses statically, where they are computable from the declared pictorials: "DOWNSCALE GENERATED WHICH LOSES ALL SIGNIFICANT FIGURES." (27,00) and "UPSCALE MAY CAUSE HIGH ORDER TRUNCATION FOR STORE INTO 'NAME.1'" (199,00), the latter itself attributing the loss to the store, both under the heading "THE FOLLOWING ERRORS WERE DETECTED DURING COMPILATION-" ([J 90.04.01]). 

    **Added qualification (new, from the compiled sample and the ID-source converts):** *no* store of an arithmetic result emits a documented overflow test, whatever the target format — the gap is universal, not peculiar to internal-decimal targets. A SET's result reaches the store as internal decimal in the AC/AC-MQ, and each of the four store paths open to it is testless. 

    **Internal decimal right justified:** no MOVPAK call at all. `SET WORKING GROSS = (WORKING HOURS * 1.5 - 20) * MASTER RATE` (statement 203,00) into a field declared `IR9(5)V99` compiles to inline machine arithmetic ending `MPY 1)RATE,2 / XCA / ACL CP)+32 / LRS 35 / DVP CP)+33 / STQ 4)GROSS`, and `SET WORKING FICA = .03 * WORKING GROSS` (211,00) into `IR9(4)V99` compiles as `LDQ CP)+9 / MPY 4)GROSS / XCA / ACL CP)+34 / LRS 35 / DVP CP)+31 / STQ 4)FICA` — multiplication, inline downscaling by `LRS 35` and `DVP`, and a bare store, with no MOVPAK call, no SYS)163–171 call and no overflow test anywhere ([J 90.05] listing, PDF pp. 206, 210; verified on images/page-210.png; the `AXT 0` word preceding the FICA sequence is the BEGIN SECTION linkage cell for statement 210,00, loaded by `SXA FICA.ROUTINE,4` on PDF p. 206, not part of the SET). 

    **External decimal:** SYS)186/187/188, "a MOVPAK subroutine which converts from internal decimal in the AC or AC-MQ to unsigned external decimal" (and the two overpunch-sign variants) — a single `TXI SYS)18n,1,NUMBER-OF-CHARACTERS-TO-DEVELOP` word with no follow-on instruction list and so no test step ([J 90.02.18]). 

    **Edited:** SYS)267, "This MOVPAK subroutine converts from internal decimal in the AC-MQ to form an edited field" — three words (`TXI` / `OCT TARGET-CONTROL-WORD-BITS` / `AXT NUMBER-OF-DIGITS-TO-CONVERT, 1`), again no test step ([J 90.02.30]); the sample exhibits it, `MOVE CORRESPONDING GRAND.TOTALS TO PAYRECORD` (statement 199,00) storing internal-decimal totals into the `88889.99` print fields as `CLA 6)GROSS / TSX SYS)180,4 / PZE 2)GROSS,,1 / TXI SYS)267,1,4 / OCT 000005000004` ([J 90.05] listing, PDF p. 203). 

    **Internal decimal not justified:** SYS)246, one word, no test step ([J 90.02.26]). The five families that do carry a TEST-FOR-OVERFLOW step are all character-source routines — the no-arithmetic case (`SET alpha.field.1 = alpha.field.2` and field-to-field moves) and operand-side conversions. 

    **Inference:** two readings survive and the manuals decide between them nowhere. Either   
    (a) detection is intrinsic to MOVPAK's numeric converts — which is what SYS)130's class-wide wording most naturally says, the explicit `TXI` steps then being required only by the character-scripted families that need an instruction per character group; or (b) ON OVERFLOW compiles inline code the appendix never exhibits. Reading   
    (b) is not architecturally implausible: the compiler demonstrably implements SET's *other* store-time option inline in the fixed-point path — MOVPAK rounds with a scripted step ("TRA SYS)219 Round current character", [J 90.02.16], 90.02.23) whereas the fixed-point sequences round by the `ACL CP)+nn` that precedes `LRS 35 / DVP CP)+nn` (absent from the plain rescale at `CLA 5)NETPAY / LRS 35 / DVP CP)+24` on PDF p. 203) — though that reading of the `ACL` constant is inference from the object code, not stated anywhere. Three residuals keep this short of resolved. First, the generated ON OVERFLOW sequence is nowhere shown: J's own SET write-up never mentions the clause ([J 02.04.05]), OVERFLOW survives only in the key-word list ([J 02.03.02]), the deferred-features appendix does not defer it ([J 90.01]), and the compiled sample uses no ON OVERFLOW — so how the object program suppresses the store, as F promises ("instead of storing the erroneous result"), is unrecoverable, and MOVPAK detecting overflow *while* moving characters sits awkwardly with a store that never happens. Second, and consequently, it is unknown whether an arithmetic SET could raise the condition at all under any target format, since none of its four store paths is documented to test. Third, the same MOVPAK families also run on the *operand* side of a statement — the sample converts a 5-character edited field to internal decimal with `TSX SYS)182,4 / TXI SYS)268,1,1 / TXI SYS)269,1,5 / TXI SYS)275,1,5` before accumulating it, for `ADD BONDORDER BONDENOMINATION TO INTERNAL.TOTALS BONDPURCHASES` (statement 221,00; [J 90.05] listing, PDF p. 212) — and 

    **inference:** since SYS)130 is described as one cell set by any MOVPAK numeric move or convert, it must be a statement-wide flag rather than a store-only one, even though only stores are documented as raising the language-level condition; "final store only" is therefore established against the arithmetic scaling routines SYS)163–171, not against every MOVPAK call the statement makes. Also unresolved: whether the 7090's own AC-overflow indicator plays any role in the inline fixed-point arithmetic (the manuals never mention it, nor any divide check). (Not counted among the overflow-test steps above: SYS)231–234 occupy that slot in the family calling-sequence lists at [J 90.02.16]–19 but their own entries print "NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH", verified on images/page-163.png — a genuine printed inconsistency, preserved.) ([F p. 44]; [J 02.03.02]; [J 02.04.05]; [J 90.01]; [J 90.02.10], 90.02.12–13, 90.02.15–21, 90.02.24, 90.02.26, 90.02.29–32; [J 90.04.01] msgs 27, 199; [J 90.05] listing, PDF pp. 203, 206, 210, 212; images/page-148.png, page-151.png, page-152.png, page-155.png, page-163.png, page-210.png; F28-8043 images/page-050.png)
28. What is the intermediate working precision of fixed-point expression evaluation — how many decimal digits are carried, and when does downscaling occur mid-expression? ([J 90.02] shows double-precision work registers and 10¹⁰ scaling steps; no language-level rule.) 

    **Narrowed (90.02 mining + 90.05 listing evidence, 2026-08-01; adversarially re-verified against the page scans, 2026-08-02):** No prose rule exists anywhere — neither manual states a working digit count for intermediates or says where scaling steps fall, and F's only precision language is expressly about the endpoint: "Ordinarily the result of the SET operation will be rounded to the number of places indicated by the format description of the result field or fields" and "In the process of storing the final result of a SET command it is possible for a loss of significant high-order digits to occur" ([F p. 44]); the word "precision" does not occur in F at all. The appendix and the compiled sample together nevertheless fix the machine model. **Working width.** Fixed point is "a binary integer arithmetic with decimal scaling" ([J 02.04.05]) whose unit is the machine word: a right-justified internal numeric field "appears by itself in the low order positions of a full word (two if double precision) with the sign value in the sign bit of the word" ([J 02.05.04]), and "Fixed point double precision numbers are denoted in the Data Description by formats representing more than 10 digits" ([J 02.05.06] d). 90.02 carries that one-word/two-word split into the registers, and — contrary to a first reading of the appendix, and to the present §4.2.2 wording — the fixed-point routines are *not* uniformly double precision: SYS)163 "upscales the single precision AC by 10\*\*10", SYS)164 "upscales the number in the MQ by 10\*\*10", while SYS)165–171 work on the AC-MQ pair and SYS)160 is "a subroutine for sign adjustment for double precision fixed point numbers … entered with the number in the AC-MQ", the second multi-precision operand living in two dedicated cells — "SYS)128, SYS)129 These two cells serve as storage for multi precision arithmetic operations" ([J 90.02.10]–13, 90.02.11.01; verified on images/page-148.png, page-151.png, page-152.png). So the attested working width is **one 35-bit word for single precision and the AC-MQ pair for double** — a register statement, not a digit count. *Inference (not manual text):* a 709/7090 word is a sign bit plus 35 magnitude bits and 2³⁵−1 = 34,359,738,367, so one word holds every 10-digit decimal integer and not every 11-digit one — which is why the declared field boundary is 10 digits, and why 10¹⁰ is the largest power of ten a one-word constant-pool scale factor can hold. 

    **The double-precision digit capacity is nowhere stated and must not be guessed:** "more than 10 digits" is all J says; 20 would follow only if the pair is a decimal split at 10¹⁰, whereas 70 magnitude bits would carry about 21. The recurring 10\*\*10 step is best read the same way rather than as a promotion quantum. SYS)163 and SYS)164 each "upscale … by 10\*\*10 and then upscale by the constant located at CP)+NN"; SYS)168 "downscales the double precision AC-MQ by 10\*\*10 and then downscales by the constant located at CP)+NN leaving the result in the MQ"; SYS)171 multiplies AC-MQ by SYS)128 SYS)129 and "scales the product down by 10\*\*10, and then downscales by the constant located at CP)+NN" — but their partners do the same jobs without it: SYS)165 and SYS)166 "upscale … by the constant located at CP)+NN", SYS)167 "downscales … by the constant located at CP)+NN and leaves the result in the AC-MQ", SYS)170 "scales the product down by the constant located at CP)+NN" ([J 90.02.12]–13). *Inference, and the correction of this question's own premise:* the 10\*\*10 is not the mode-promotion step — promotion is triggered by an operand's declared format ([J 02.05.06] d) under the rule of [J 02.04.05.01] — but the two-step form of a scale change whose factor exceeds one word's largest power of ten; its coincidence with the 10-digit boundary is the same word-size fact seen twice. Consistently, the routine that sheds ten digits delivers one register: SYS)168 leaves "the result in the MQ". Two double-precision layouts are documented, distinguished only by which half is high — SYS)165 takes the AC-MQ plain, SYS)166 takes it "On entry to the routine, the high order part of the number is in the MQ and the low order in the AC" — *inference:* respectively what an MPY leaves and what a DVP leaves, the machine placing a double-length product high-half-in-AC but a quotient in the MQ with the remainder in the AC. Division stages its operands the opposite way from multiplication: SYS)169 "divides the double precision fixed point number in SYS)128 and SYS)129 by the AC-MQ. The result is left in the AC-MQ" — dividend in the cells, divisor in the registers ([J 90.02.13]). **Where the scaling falls.** Scale is a compile-time attribute computed from the pictorials before any code is emitted: hence the compile-time diagnostics "DOWNSCALE GENERATED WHICH LOSES ALL SIGNIFICANT FIGURES." (27,00) and "UPSCALE MAY CAUSE HIGH ORDER TRUNCATION FOR STORE INTO 'NAME.1'" (199,00), the latter itself attributing the loss to a store ([J 90.04.01]), and hence the compiler's own conversion parameter block, whose fields are "**Address** — = Scale applied to internal decimal value", "**Prefix** — is the sign of the scale" and "**Decrement** — = Numeric length of value" — scale and digit count carried as an explicit pair ([J 90.02.27], CONTROL-WORD-TYPE-ID; the scientific-decimal CONTROL-WORD-TYPE-SD likewise pairs "Scale applied to mantissa in pictorial" with "Total length in characters, of the field", [J 90.02.26]). The compiled sample exhibits the placement directly. It carries no OPTION card — its ENVIRONMENT division holds only FILE and SPECIF cards ([J 90.05] listing, PDF p. 195) — so it was compiled in the default mode: "The compiler normally generates comparison type instructions based on the 709/7090 collating sequence and an object program which is conservative of time rather than space" ([J 02.06.16]), i.e. "CONSERVE TIME requests an object program which will be executed in a minimum amount of time; this is achieved by the generation of in-line instructions to perform the operations. This is the normal mode of operation" ([J 02.06.17]), as against CONSERVE SPACE, in which "subroutines are generated once for operations such as scaling, double precision arithmetic, etc., in-line calling sequences to the subroutines are used to perform the operations" ([J 02.06.16]). *Caution against a tempting inference:* the sample calls none of SYS)163–171, but that is **not** evidence about the mode — no routine in that range performs an ordinary single-precision scale by a constant (each involves either the 10\*\*10 step or the AC-MQ pair), so the set cannot be the whole CONSERVE SPACE scaling package, and the sample needs none of them, its largest scale factor being 10⁶ and its widest field `IR9(5)V99`. Statement 203,00, `IF WORKING HOURS GT 40.0 THEN SET WORKING GROSS = (WORKING HOURS * 1.5 - 20) * MASTER RATE OTHERWISE SET WORKING GROSS = WORKING HOURS * MASTER RATE` ([J 90.05] listing, PDF p. 196), over `3)HOURS IR99V9` and `4)GROSS IR9(5)V99` (PDF p. 194) and `1)RATE IR99V999` (PDF p. 192) — scales 10¹, 10², 10³ — compiles to `LDQ CP)+6` / `MPY 3)HOURS` / `STQ RS)1+0` / `LDQ CP)+7` / `MPY CP)+31` / `STQ RS)0` / `CLA RS)1` / `SUB RS)0` / `XCA` / `MPY 1)RATE,2` / `XCA` / `ACL CP)+32` / `LRS 35` / `DVP CP)+33` / `STQ 4)GROSS`, the constants being CP)+6 = 15 (the literal 1.5 as a scaled integer), CP)+7 = 20, CP)+31 = 100, CP)+32 = 500, CP)+33 = 1000 ([J 90.05] listing, PDF pp. 206, 215–216; images/page-206.png, page-216.png). Three rules read straight off it and off the other two SETs: **(i)** additive operands are brought to a common scale by *upscaling the lesser-scaled one* mid-expression — the literal 20 is multiplied by 100 before the subtract, and emitted as a runtime `LDQ CP)+7` / `MPY CP)+31` rather than folded to the constant 2000, i.e. as a generic alignment step; likewise in `SET WORKING WHT = 0.18 * (WORKING GROSS - 13 * MASTER EXEMPTIONS)` (215,00) the integer product `MPY EXEMPTIONS,1` is followed immediately by `MPY CP)+31` to reach GROSS's two decimal places before the `SUB` ([J 90.05] listing, PDF pp. 196, 210–211; images/page-210.png); **(ii)** products merely accumulate scale and are *never* downscaled mid-expression — `LDQ CP)+6` / `MPY 3)HOURS` / `STQ RS)1+0` parks 1.5×HOURS in a Result Storage cell at its full accumulated scale, and the expression reaches 10⁵ before its single scaling step even though every operand and the result have at most three decimal places; **(iii)** the one downscale is generated at the store, as a single `DVP` by the accumulated excess power of ten immediately preceding the `STQ` into the result field — by 1000 for statement 203,00's overtime branch, by 100 for its straight-time branch, for `SET WORKING FICA = .03 * WORKING GROSS` (211,00) and for statement 215,00. Rounding is folded into that same divide as an `ACL` of exactly half the divisor beforehand — CP)+32 = 500 against divisor 1000, CP)+34 = 50 against divisor 100 — the machine form of F's rule that the retained digit "is increased by 1 when the part removed is greater than or equal to one-half" ([F p. 115], ROUND), applied where F says it is applied, at the store and not to intermediates. *Two inferences from 7090 instruction semantics, not manual text:* the `STQ` of a product keeps only the MQ, discarding the AC half, and a chained `MPY` re-multiplies the MQ, so a single-precision intermediate really is one 35-bit word and the high half of every single-precision product is dropped; and `LRS 35` / `DVP` is the idiom for a divide with a properly positioned double-length dividend, the `ACL` carry surviving across the shift. Result Storage is nevertheless sized for the wider case: 90.02.03 says only that RS cells "temporarily store the results of a CT statement" and that "N is the sum of maximum Result Storage used in each section", but in the sample RS)0 and RS)1 lie two words apart (01621 and 01623) and each section's block begins at an even offset from `RS) BSS 30` (01621, 01627, 01633, and 3.RS)1 at 01643) — *inference from the listing's LOC values*: two words per cell, i.e. every expression intermediate is allocated storage able to hold a double-precision value even where the code stores one word into it. 

    **Still open:** the rule is reconstructed from one compiled program plus routine descriptions and is nowhere stated. The sample exercises no source-level division (every `DVP` in it is compiler-generated scaling), no `TRUNCATED` clause, and no field wider than 10 digits (its widest is `IR9(5)V99`), so double precision — SYS)128–129, SYS)160, SYS)165–171 — is attested only by the 90.02 prose and never seen in generated code; nothing shows the circumstances in which the compiler would prefer a mid-expression *downscale* to an upscale, although msg 27,00 proves it generates them; whether `TRUNCATED` merely suppresses the `ACL` half-divisor or changes the scaling plan is unattested; and the ceiling behind "MAXIMUM NUMERIC LENGTH EXCEEDED. 'NAME.1' FORMAT USED." (35,00), and behind msg 52,00's "MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL.", is never given. One further store-side mechanism observed but not explained by any text: when the value stored has more digits than the target pictorial can hold, the compiler splits it with a divide by 10 raised to the target's digit count before the edit — `CLA 3)NETPAY` / `LRS 35` / `DVP CP)+24` (CP)+24 = 1,000,000) preceding `TSX SYS)180,4` / `PZE 1)NETPAY,,4` / `TXI SYS)267,1,4` / `OCT 000004000003` / `AXT 6,1`, where the source `WORKING NETPAY IR9(5)V99` has seven digits and the target edited pictorial `8889.99` six, while the seven-digit-to-seven-digit moves on the same listing page (`4)GROSS` → `2)GROSS 88889.99`, `OCT 000005000004`, `AXT 7,1`) carry no divide at all ([J 90.05] listing, PDF pp. 193, 203, 209; [J 90.02.15], 90.02.17, 90.02.30) — *inference:* since SYS)267 "converts from internal decimal in the AC-MQ to form an edited field", the divide isolates the digits that fit as the remainder in the AC and the excess as the quotient in the MQ, matching the MQ-high/AC-low layout SYS)166 documents; but neither the purpose nor the overflow consequence is stated. (F pp. 44, 115; [J 02.04.05], 02.04.05.01; [J 02.05.04], 02.05.06 d; [J 02.06.16]–17; [J 90.02.03], 90.02.10–13, 90.02.11.01, 90.02.15, 90.02.17, 90.02.26–27, 90.02.30; [J 90.04.01] msgs 27, 35, 52, 199; [J 90.05] listing, PDF pp. 192–196, 203, 206, 209–211, 215–216; images/page-148.png, page-151.png, page-152.png, page-206.png, page-210.png, page-216.png)
29. How is one element of a *subscripted* conditional variable set, given SET condition.name is the only setting form and condition-names may not be subscripted? ([F p. 46]; [J 90.01.03])
30. What is the mode/precision of a truth function's 1-or-0 value, and can a TR term trigger mode promotion? ([F p. 24]; [J 02.04.05])
31. What happens at object time when a numeric field contains invalid characters during MOVE or arithmetic — SYS)131 records "an improper data condition", but no program-level reaction or verb option is defined. ([J 90.02.10]) 

    **Narrowed (90.02 mining, 2026-08-01; scan-verified 2026-08-02):** SYS)131 is a flag cell, not a mechanism. J defines it in one sentence — "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects an improper data condition." ([J 90.02.10], verified on images/page-148.png) — and gives it no calling sequence, unlike the SYS) routines and unlike the pointer cells SYS)132/133, which are shown with a `PZE LOC,,BYTE` format word; its siblings SYS)130 (overflow) and SYS)134 (floating-point underflow from a Move) are bare cells in the same way ([J 90.02.10]–11; images/page-148.png, page-149.png). It is a Type 2 entry, "Type 2 entries received a number greater than 127" and Type 2 communication cells being "those communication cells which are a part of a particular object program"; J states CT-Loader placement of Type 2 *subroutines* and says the cells are "categorized in the same manner", so loader placement of the cell follows by that categorization rather than being stated of cells ([J 90.02.07]). The setting side is bounded though not pinpointed: MOVPAK is entered at SYS)179–182 and its members run SYS)183–258 and SYS)267–282 (no SYS)259 exists; each member is identified in its own entry as a MOVPAK subroutine), and the cell's own wording confines it to the *numeric* members — SYS)183–238 (character-serial external-decimal and edited-field moves), SYS)246–258 (internal-decimal / scientific-decimal / floating-point converts) and SYS)267–282 (internal-decimal↔edited converts) — excluding the alphabetic and figurative-constant movers SYS)239–245 ([J 90.02.14]–16, 90.02.25–28, 90.02.30–32). Within a generated MOVPAK call the only step kinds the appendix names are move, convert, develop, bypass, insert leading/trailing zeros, develop decimal zeros, test for overflow, test for overpunch, scan for sign, "Round current character", and the terminating target-numeric-length word ("This type of MOVPAK call is always terminated by the instruction TXI SYS)223, 1, TARGET-NUMERIC-LENGTH", [J 90.02.16]); none is a validity test. 

    **Inference (not stated in either manual):** improper-data detection is therefore internal to the subroutines' own character loop rather than a separately generated step, which is why no compiled listing can display it. The appendix is itself inconsistent about the four character-examining steps SYS)231–234: the collected step lists print them as OVERFLOW — "TXI SYS)231, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW" under SYS)183, and SYS)232, SYS)233, SYS)234 identically under SYS)185, SYS)189 and SYS)190 — each flagged with the note "The last character processed under control of this instruction is examined for source field sign." ([J 90.02.16]–19; images/page-155.png), whereas the four standalone entries for the same subroutines all print "NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH" ([J 90.02.24]; images/page-163.png). Both readings verified on the scans: a genuine print inconsistency in the 1962 manual, not an OCR artifact. **Nothing reads it.** Across the whole of [J 90.02.00]–90.02.33 no SYS) or IOC) entry is documented as testing, branching on, printing from, initialising or clearing SYS)131 or its two siblings; the three cells occur exactly three times in the appendix, in their own definitions. The field-test sample's object listing never names them either: its complete set of SYS references is 132, 133, 175, 177, 178, 180, 182, 184, 185, 190, 193, 198, 212, 214, 225, 226, 239, 240, 241, 243, 244, 245, 260, 267, 268, 269, 275, 283 and 294 ([J 90.05] listing, PDF pp. 198–216). The decisive demonstration is statement 202,00, "COMPUTE.PAY. MOVE DETAIL DATE TO MASTER DATE, MOVE DETAIL HOURS TO WORKING HOURS, PAYRECORD HRS." ([J 90.05] listing, PDF p. 196; printed across two lines). DETAIL HOURS is declared `99V9` — three characters, external decimal ([J 90.05] listing, PDF p. 192) — in a record the sample's own narrative describes as punched: "Data Description entries specify that all fields of the detail records are in external mode since they are generated on a card punch. HOURS is the only field upon which arithmetic operations are performed, and consequently, is the only field specified as numeric (9's in description)." ([J 90.05.02]). It is thus precisely the field most exposed to a blank or a stray punch. Its generated code (symbolic columns of the listing; the octal location and instruction-word columns are elided here) is `COMPUTE.PAY LAC BL)3,1` / `TXL SYS)294,1,0` / `CAL 2)DATE,1` / `LAC BL)2,2` / `TXL SYS)294,2,0` / `SLW 1)DATE,2` / `CAL BL)3` / `ACL CP)+52` / `SLW SYS)132` / `TSX SYS)182,4` / `TXI SYS)184,1,3` / `STO 3)HOURS`, followed by the same source field's second move `TSX SYS)182,4` / `TXI SYS)185,1,4` into the edited PAYRECORD HRS (`8889.9`), and then at +23 straight into statement 203's arithmetic, `CLA 3)HOURS` / `CAS CP)+5` ([J 90.05] listing, PDF p. 205) — SYS)184 being the MOVPAK routine that "converts from external decimal to internal decimal leaving results in the AC or AC-MQ. The sign is assumed over the low order digit." ([J 90.02.16]), and WORKING HOURS being `IR99V9`, internal ([J 90.05] listing, PDF p. 194). The converted value goes straight to store and thence into the pay arithmetic with nothing tested, while those same twelve words carry two instances of the one inline object-time trap the compiler *does* emit, `TXL SYS)294,n,0`, which "prints an error message whenever a reference is made to a Base Locator before the locator has been loaded, and exits back to the CT Monitor" ([J 90.02.33]) — so the absence of a data check is a design decision, not a gap in the listing. The pattern repeats at the edited-to-internal-decimal convert `TSX SYS)182,4` / `TXI SYS)268,1,1` / `TXI SYS)269,1,5` / `TXI SYS)275,1,5` / `STO 3.RS)1`, which runs straight into `CLA 2)BONDPURCHASES` / `ADD 3.RS)1` ([J 90.05] listing, PDF p. 212). **Nor can a program name the condition.** The only condition options in the language are ON OVERFLOW, restricted to SET and ADD with a single result field ([F p. 44], p. 47) — F's complete verb-format summary gives MOVE no option whatever, "MOVE [CORRESPONDING] data.name.1 TO data.name.2, data.name.3, ... data.name.n" ([F p. 109], in the command list of [F pp. 108–109]) — and the Environment FILE-card ON ERROR, which J confines to three I/O conditions: "IOCS cannot continue processing after discovering an unrecoverable redundancy error, a block checksum error or a block sequence error without direction from the programmer. The ON ERROR option of the Environment FILE card provides for communication between IOCS and the programmer in these three error situations." ([J 02.07.07]). J's key-word lists hold OVERFLOW and ERROR — the two conditions that do have options — and no word naming an improper-data condition ([J 02.03.02]–03). CRYPT cannot even write the symbol — "The characters, 'Quotation Mark,' 'Left Parenthesis,' 'Right Parentheis,' 'Dollar Sign' may not be used as part of a symbol" ([J 02.08.01]; "Parentheis" sic) — and "No debugging facilities are currently available." ([J 90.01.05] B.3). 

    **Reading (inference from the stated facts):** the move or arithmetic runs to completion, MOVPAK stores whatever its character loop produced, execution continues silently, and the event survives only as a non-zero cell that no documented code reads, prints from, or resets — of a piece with J's stated policy elsewhere, "No object time check is made to insure that subscript references conform to the limits specified by the array dimensions in the Data Description." ([J 90.01.02]). **This is a different mechanism from the GET-path conversion check it is easily confused with.** SYS)261 is not a MOVPAK subroutine and does not operate on programmer data: "Subroutine SYS)261 converts the logical accumulator from a BCD number to binary, checking for non-numeric characters and/or imbedded or trailing blanks; and leaves the result in the decrement of the AC. This routine is used in conjunction with getting a variable length BCD record from tape where the first word of the record gives the remaining length of the record. If an error is detected during conversion, return is 1,4 to routine SYS)263 which prints an error message." ([J 90.02.29], verified on images/page-168.png). Four differences: its subject is the record's own length control word, not a described data field; its calling sequence is `TSX SYS)261,4` / `TSX SYS)263,6` / `(Normal Return)`, i.e. an explicit alternate error exit, which no MOVPAK numeric call has; its reaction is fatal, SYS)263 being the routine that "prints an error message in conjunction with SYS)261 upon GET error condition (see SYS)261) and exits to the CT monitor" ([J 90.02.29]); and it sets no cell. *Inference:* since the appendix does spell out alternate exits where the design has them — SYS)162's "HIGH RETURN / EQUAL RETURN / LOW RETURN from comparison" ([J 90.02.12]) and SYS)292's "(Partial Conversion Exit)" and "(Total Conversion Exit)" ([J 90.02.33]) — the single-exit MOVPAK sequence, always closed by its target-numeric-length word, is most likely a real fact about the interface rather than an abbreviation. Every object-time error printer in 90.02 (SYS)260 record length, 263 GET conversion, 264 record exceeding BLOCKSIZE, 265 unexpected end-of-file, 283 GET error, 291 FILE to card equipment in locating mode, 294 base locator not loaded) is I/O- or addressing-related and terminates the run, matching J's own inventory of object-time on-line messages: "Object program error messages, usually concerning I/O errors. Object-time processing will terminate and control will revert back to the CT Monitor." ([J 05.06.04]). None concerns numeric data validity. The compiler's improper-data diagnostics are not object-time reactions either: messages 25,00 "OPERATION IGNORED BECAUSE 'NAME.1' HAS IMPROPER DATA FORMAT ( E A(2) ) FOR THIS USE.", 67,00 "THERE IS AN ILLEGAL NON-NUMERIC CHARACTER IN THE NUMERIC FIELD.", 111,00, 112,00, 120,00 and 182,00 all stand under the heading "THE FOLLOWING ERRORS WERE DETECTED DURING COMPILATION-" and carry compilation severity codes, "numbered 1 through 5" ([J 90.04.01]–02); message 67 is the compile-time namesake of the object-time condition, not its handler. 

    **Still open:** what MOVPAK counts as an "improper data condition" — it cannot simply be "any non-digit", since J allows scientific-decimal *source* fields free-form content, "For the source fields of the scientific decimal type, a free form of data is allowed within the limits of the field", with worked examples containing embedded blanks ([J 02.04.04] e) — and the class matters, since "Arithmetic operations are performed only in the internal (binary) mode" ([J 02.03.03]), so every external field feeding arithmetic passes through one of these converts; which individual subroutine sets the cell; what the target field or accumulator holds afterwards; and whether the cell is ever cleared — all three flag cells are described only as "set non-zero", and no initialisation, reset or per-statement clearing is stated anywhere in [J 90.02], [J 90.03], or the Loader chapter J 03. ([F p. 44], p. 47, pp. 108–109; [J 02.03.02]–03; [J 02.04.04]; [J 02.07.07]; [J 02.08.01]; [J 05.06.04]; [J 90.01.02], 90.01.05; [J 90.02.07], 90.02.10–12, 90.02.14–19, 90.02.24, 90.02.25–33; [J 90.04.01]–02; [J 90.05.02]; [J 90.05] listing, PDF pp. 192, 194, 196, 198–216; images/page-148.png, page-149.png, page-155.png, page-163.png, page-168.png)
32. Is there a maximum count of receiving fields in MOVE or result fields in SET/ADD (beyond sentence capacity, msg 177)?
33. When multiple receiving/result fields overlap in storage (via REDEF), what is the store order and are later stores affected by earlier ones?
34. Do the data movements of DO … USING … GIVING and of function references obey full MOVE editing (decimal alignment, justification), or are they raw transmissions? F says values are "moved". (F pp. 52–53, 57–58)
35. For repeated `ADD x TO accumulator` into an edited or scaled field, is the addition performed on the stored (already rounded/edited) value each time? ([F p. 47])

### Control flow

36. If the loop body modifies the DO index variable or the p/q/r parameter fields, is F's expansion (which re-reads q and r each pass and keeps i programmer-visible) binding? ([F pp. 50–51])
37. Does the index of a completed DO … FOR loop retain the value r afterward, and what is its value after a GO TO abandons the loop? (The J sample copies INDEX to POS before exiting — suggesting "unreliable".) ([F pp. 50–51]; [J 90.05])
38. What exactly triggers msg 170 "-WHEN- SUBSTITUTED FOR -IF- BECAUSE OF IMPROPER USE." — which improper IF placements does the compiler silently repair? ([J 90.04.01])
39. Is there any bound on n in the conditional GO TO's WHEN list or the assigned GO TO's procedure list, other than the 60-operator sentence limit and table capacities? ([J 90.04.01] msg 171)
40. How is DO return linkage physically established (per-procedure return cell vs index register) — determining whether simultaneously active DOs of different procedures interact? ([J 90.02] describes generated subroutines but not DO linkage.) 

    **Resolved (90.05 listing evidence + 90.02 mining, 2026-08-01; adversarially re-verified against 400-dpi page renders, 2026-08-02):** a per-procedure return cell, not a live index register. The word *at* the procedure label is a placeholder `AXT 0` (`0774 00 0 00000`); each DO plants its return address in that word's address field with `SXA P,4`; entry is at `P+1`; and the procedure's terminal instruction is `TRA* P` — octal flag field `60`, i.e. bits 12-13 set = indirect — returning through the head word. Six procedures, six such returns: END.OF.MASTERS `00331`/`00350` (PDF p. 202), FICA.ROUTINE `01165`/`01217` (p. 210), WITHOLDING.TAX.ROUTINE `01220`/`01261` (p. 211), BOND.ROUTINE `01262`/`01403` (p. 212), SEARCH `01404`/`01472` (p. 213), DEPARTMENT.END `01473`/`01620` (p. 215). Nine call sites occupy pp. 201-203 and 205-207, in **two** code shapes, not one:   
    (i) plain `DO P` — 8 of the 9 — compiles `AXT *+3,7` / `SXA P,4` / `TRA P+1`, e.g. p. 205 `00542 0774 00 7 00545 AXT *+3,7` / `00543 0634 00 4 01473 SXA DEPARTMENT.END,4` / `00544 0020 00 0 01474 TRA DEPARTMENT.END+1` (tag digits 7 and 4 read independently in the octal and the symbolic column of the page render), the AT END DO clause compiling the identical triple (p. 201, `00205` GN)058); (ii) `DO P FOR i = p(q)r` — the single instance, statement 206,00 `DO SEARCH FOR INDEX = 1(1)12.` — compiles `00702 0774 00 4 00711 AXT GN)086,4` / `00703 0634 00 4 01404 SXA SEARCH,4` / four instructions of loop initialisation (`00704`-`00707`) / `00710 0020 00 0 01405 TRA SEARCH+1` (pp. 206-207): the planted return is the generated loop-increment label GN)086 rather than `*+3`, the AXT tag is 4 rather than 7, and the TRA need not adjoin the SXA. The loop back-edge `00721 TPL GN)085` re-enters `SEARCH+1` on each of the 12 iterations *without* re-executing the SXA, so one planted return serves the whole loop — direct confirmation that the linkage lives in storage rather than in a register. Consequences: simultaneously active DOs of different procedures cannot interact (each procedure owns its cell), while re-DOing an already-active procedure overwrites its pending return — confirming the §8.5.5 nested/recursive reading. 90.02 corroborates the static model: all compiler-generated storage is fixed blocks reserved by `BSS` (`RS)`, `TS)`, `PI)`, plus the constant pool) with no stack or save-area chain, and IR4 — the TSX linkage register — is reused both as the data base register (`LAC BL)2,4` / `CAL DATANAME,4`) and as scratch (`PDX 0,4` / `TXL *2,4,5`), so a surviving return must live in storage ([J 90.02.03]-06, 90.02.11). ([J 90.05] listing, PDF pp. 195-196, 201-203, 205-207, 210-213, 215; images/page-203.png, page-205.png, page-206.png, page-207.png, page-211.png, page-213.png, page-215.png) Corroborating stated text (90.02 re-mining, adversarially verified 2026-08-02): [J 02.08.03] shows the located-data reference sequence as the compiler emits it — `LAC BASE.LOCATOR.OF.DATE,4` / `TXL SYS)294,4,0` / `CLA DATE.DISP,4` — and states "Note that the contents of index register 4 are destroyed, and that instructions have been inserted in the program"; so a DO'd procedure's first reference to a located data item destroys any return held in IR4, and a return that survives an arbitrary body must be planted in storage — exactly the head-word cell the listing exhibits. ([J 02.08.03]; [J 90.02.11], 90.02.33)
41. Does J accept F's `AT END any-imperative-clause` with a non-transfer clause, given [J 02.07.05] ("a single imperative statement only") and msg 106 ("STATEMENT OR SECTION NAME MUST FOLLOW -AT END-"), while the sample uses both `AT END DO x` and `AT END GO TO x`? 

    **Narrowed (90.02 mining, 2026-08-01):** the generated code settles the mechanism, not the parse. J's generic GET calling sequence is `TSX IOC)8,4` / `PZE FILENAME,,SYS)260` / `PZE END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE` / `IOCDN* BL)2,,14` ([J 90.02.04]); the address field of the third word holds the AT END exit — occupied by SYS)265, which "appears as part of the GET calling sequence to the IOCS Read routine whenever the 'AT END' option is not used with the GET verb" and "prints a message concerning the unexpected end-of-file and exits to the CT Monitor" ([J 90.02.29]) — while its decrement holds the ON ERROR exit, defaulting to SYS)283 ([J 90.02.32]). In the sample, `GET MASTER, AT END DO END.OF.MASTERS.` compiles that word as `PZE GN)058,,SYS)283`, and the clause becomes a compiler-generated out-of-line block placed after the calling sequence and jumped over by the normal-return `TRA GN)059`: `GN)058 AXT *+3,7` / `SXA END.OF.MASTERS,4` / `TRA END.OF.MASTERS+1` ([J 90.05] listing, PDF p. 201). `*+3` is GN)059, which is the code of the *next source sentence* (statement 189, `MOVE MASTER DEPARTMENT TO CURRENT.DEPT, GO TO GET.DETAIL`) — so an AT END clause that returns resumes at the statement following the GET, exactly the continuation a non-transfer imperative would need. `GET DETAIL, AT END GO TO END.OF.DETAILS.` likewise receives its own generated block, `GN)062 TRA END.OF.DETAILS`, although the bare target address would have served in the calling-sequence word — *inference:* the AT END clause is emitted through ordinary statement code generation rather than being planted as a name, and nothing in the IOCS interface confines it to a transfer. Pulling the other way, msg 106,00 "STATEMENT OR SECTION NAME MUST FOLLOW -AT END-. CHECK 'NAME.1'." is worded from the same template as 92,00 and 93,00 ("STATEMENT OR SECTION NAME MUST FOLLOW -ONERROR- / -FORLABEL- IN THE -FILE- CARD."), whose operands are literally bare names, and J's own template calls the slot END-OF-FILE-PROCEDURE. 

    **Still open:** whether the field-test parser accepted a clause such as `AT END MOVE ...`; both surviving samples use only `DO` and `GO TO`. Recommended implementation: accept any single imperative statement ([F p. 40]; [J 02.07.05]), compile it out-of-line with a return to the statement after the GET as the DO case demonstrates, and diagnose non-transfer clauses at low severity. ([F p. 40], p. 109; [J 02.07.05]–06; [J 90.02.04], 90.02.28–29, 90.02.32; [J 90.04.01] msgs 92, 93, 106; [J 90.05] listing, PDF pp. 195, 201; images/page-142.png, page-183.png, page-201.png) 

    **Verified and further narrowed (independent re-derivation + scan check, 2026-08-02):** the generated-code reading holds on re-checking — `PZE END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE` in the generic GET sequence ([J 90.02.04]), SYS)265 supplied "whenever the 'AT END' option is not used with the GET verb" ([J 90.02.29]), SYS)283 supplied "whenever the 'ON ERROR' option in not used in the Environment description of the file" ([J 90.02.32], printed "in not used"), SYS)260 by contrast said only to "may appear" in a GET calling sequence, with no source option named ([J 90.02.28]) — *inference:* it is therefore not a programmer-replaceable slot — and in the sample `00202 0 00433 0 00205 11001 +13 PZE GN)058,,SYS)283` / `00204 … TRA GN)059` / `00205 … GN)058 AXT *+3,7` / `SXA END.OF.MASTERS,4` / `TRA END.OF.MASTERS+1`, verified on images/page-201.png (no FILE card in the sample codes ON ERROR, so SYS)283 stands in every GET). Three findings sharpen the entry. (i) The shape is uniform: all four GETs in the sample (statements 188, 190, 191, 194, at object locations 00200–00207, 00222–00231, 00233–00240 and 00277–00306) put the AT END clause in a generated block placed immediately after the calling sequence and jumped over by a normal-return `TRA` to a generated label that begins the *next* sentence's code — GN)059, GN)061, GN)063, GN)065 respectively ([J 90.05] listing, PDF pp. 201–202). (ii) The `AT END DO x` block is not an AT-END-specific construct: an ordinary in-line DO — statement 199, `199,00 71512 END.OF.RUN. DO DEPARTMENT.END,` ([J 90.05] listing, PDF p. 196) — compiles to the identical triple, `00370 0774 00 7 00373 10001 END.OF.RUN AXT *+3,7` / `SXA DEPARTMENT.END,4` / `TRA DEPARTMENT.END+1` ([J 90.05] listing, PDF p. 203), and the DO'd procedure returns indirectly through its head cell, `00350 0020 60 0 00331 10001 GN)067 TRA* END.OF.MASTERS` against `00331 0774 00 0 00000 10000 END.OF.MASTERS AXT 0` ([J 90.05] listing, PDF p. 202). *Inference:* the return address planted by `SXA` is the `*+3` operand, which in the AT END case is the very label the normal path transfers to, so the end-of-file and not-end paths converge on the sentence after the GET and a returning, non-transfer AT END clause would have needed no new machinery. (iii) Pulling the other way harder than previously recorded: msg 106,00 belongs to a larger family than msgs 92,00/93,00 — J also carries `127,00 0 TRANSFER BYPASSED BECAUSE 'NAME.1' IS NOT A STATEMENT OR SECTION NAME.` and `128,00 … IS A STATEMENT OR SECTION NAME ADDRESSED BY A -DO-.` for ill-formed transfer targets, and, specific to the DO verb's own operand, `188,00 0 'NAME.1', ADDRESSED BY A -DO-, IS NEITHER A STATEMENT NOR A SECTION NAME.` ([J 90.04.01], PDF pp. 183, 185). *Inference:* a bad name inside `AT END DO x` would already be caught by 188,00 (and inside `AT END GO TO x` by 127,00), leaving 106,00 to police the AT END slot itself; no manual sentence says which diagnostic the compiler actually issues for a malformed AT END clause. On balance the field-test parser is best read as requiring the AT END clause to *designate a procedure* — `GO TO name` and `DO name` both attested in the sample, a bare name plausible — with a non-transfer imperative unattested and probably rejected even though the code generator would plainly have handled one. 

    **Still open:** whether `AT END MOVE …` (or SET, FILE, ADD) was accepted; no surviving sample exercises it and no manual sentence settles it. Recommended implementation unchanged: accept any single imperative statement ([F p. 40], p. 109; [J 02.07.05]), compile it out-of-line with a return to the sentence following the GET as the DO case demonstrates, and diagnose the non-transfer case at low severity for J compatibility. Fidelity aside, not bearing on the question: the appendix template prints the buffer-pointer line as `IOCDN* BL)2,,14` while the sample listing prints the mnemonic as `IOCTN*` in all four GET sequences (`IOCTN* BL)2,,15` for the three MASTER GETs at 00203, 00225 and 00302, `IOCTN* BL)3,,3` for the DETAIL GET at 00236); both spellings are reproduced as printed. ([J 02.07.05]–06; [J 90.02.04], 90.02.28–29, 90.02.32; [J 90.04.01] msgs 92, 93, 106, 127, 128, 188; [J 90.05] listing, PDF pp. 195–196, 201–203; images/page-183.png, page-201.png, page-202.png)
42. Are WHEN conditions and IF sentences subject to the compile-time constant-folding J describes for unequal-length alphameric `=` comparisons (only the false-branch transfer generated)? ([J 02.04.07]) 

    **Narrowed (90.02 mining, 2026-08-01; adversarially verified against page scans 2026-08-02):** The rule is written operator-scoped, not construct-scoped. [J 02.04.07] rule 2.b reads "Alphameric fields of unequal length are treated on the basis of the operator used in the comparison", and sub-rule i "In tests for an = or NOT = condition the fields will always be found to be unequal. In the following example where fields A and B are of alphameric type with unequal length the only code generated will be a transfer to D." (verified character-for-character against images/page-025.png). The subsection is headed "C. Conditional Statements" ([J 02.04.06]) and its six rules speak throughout of "comparisons" and "tests"; no rule names a construct as its scope, and constructs appear only inside worked examples — rule 1's "the following IF statement represents an invalid comparison" and rule 2.b.i's pair "IF A = B THEN GO TO C OTHERWISE GO TO D." / "IF A NOT = B THEN GO TO D OTHERWISE GO TO C." The semantic half of the rule ("the fields will always be found to be unequal") therefore binds every context that evaluates such a condition — conditional sentences ([F p. 25]), the conditional GO TO's WHEN clauses ([F p. 48]) and TR operands ([F p. 24]) alike — the more so because J's language chapter documents no conditional construct's syntax at all: across [J 02.00]–02.08 the string "GO TO" appears only inside those two examples, and WHEN only in the key-word list ([J 02.03.02]) and in the Data Description clause BLANK WHEN ZERO ([J 02.05.05], 02.05.07), [J 02.04] being by its own title "Procedure Description Clarification and Amplification" of the F language. Only the code-shape half is exhibited, and only on IF sentences. Note that "a transfer to D" names the branch the constant outcome *selects*, not specifically the false branch: in the first example D is the OTHERWISE target of an always-false `=`, in the second it is the THEN target of an always-true `NOT =`, so for IF both directions of the fold are attested. Neither appendix that could exhibit a fold does so. [J 90.02] has nothing on the subject — it "explains the format and content of the instruction listing" ([J 90.02.00]) and then catalogues listing conventions and the IOC)/SYS) runtime library, with no per-construct code templates; an exhaustive search of it finds no occurrence of fold, optimiz-, eliminat-, suppress-, "only code", "no code", conditional, relation, branch, false or unequal, its one "truncation" being SYS)130's overflow flag ([J 90.02.10]), and its two nearest items are irrelevant to the point: SYS)162, a *run-time* routine that "performs an alphabetic comparison on two fields" whose calling sequence carries independent LENGTH(1)/LENGTH(2) operands ([J 90.02.12]), and the MOVPAK routine SYS)242, which "moves alphabetic fields to alphabetic fields where some information was unknown at compile time" ([J 90.02.25]) — the appendix's sole occurrence of the phrase "compile time". The sample program cannot settle it either, because it contains no unequal-length alphameric `=`/`NOT =` comparison: its entire inventory of alphameric relations is the WHEN pair `GO TO CHECK.NEW.DEPT WHEN D.EMP.NO = M.EMP.NO, LOW.DETAIL WHEN D.EMP.NO LT M.EMP.NO.` — both operands pictorial-less groups of `AA` + `AAAA`, hence 6-character alphameric fields of equal length by [J 02.05.06] c) with rule 4 of [J 02.04.07] (*inference*: J nowhere defines the term "non-format field", and 02.05.06 c) is the only candidate definition) — the two `= HIGH.VALUE` sentinel tests, and `CURRENT.DEPT IS NOT EQUAL TO D.DEPT` (both `AA`); every other relation in the program is numeric ([J 90.05] listing, PDF pp. 192–193, 195–197). All five of those alphameric relations produced object code: the listing contains exactly five `LAS` three-way logical compares, one per relation, and SYS)162 is never called anywhere in the program ([J 90.05] listing, PDF pp. 201–203, 204–205). The shape is an inline load-and-compare followed by a transfer decode of LAS's three skip slots — three `TRA`s where all three outcomes branch away (`LAS 1)EMPLOYEE.NUMBER,2` / `TRA *+3` / `TRA *+2` / `TRA LOW.DETAIL`, PDF p. 201), two where one outcome falls through into the following code (`LAS 1)EMPLOYEE.NUMBER,2` / `TRA *+2` / `TRA CHECK.NEW.DEPT`, the third slot falling into the next WHEN clause's `CAL`, PDF p. 201; `LAS RS)0` / `TRA *+2` / `TRA GN)070`, the third slot falling into the `AXT`/`SXA`/`TRA` triple that performs DO DEPARTMENT.END, PDF p. 205). Two things follow. First, IF and WHEN demonstrably share one comparison code generator — the WHEN pair at COMPARE.EMPLOYEE.NUMBERS (`CAL 2)EMPLOYEE.NUMBER,1` … `LAS 1)EMPLOYEE.NUMBER,2` plus decode, PDF p. 201) and the IF at CHECK.NEW.DEPT (`CAL CURRENT.DEPT` / `LGL 18` / `ANA CP)+30` / `SLW RS)0` … `CAL 2)DEPARTMENT,1` / `ANA CP)+30` / `LAS RS)0` plus decode, PDF pp. 204–205) emit the same skeleton, differing only in the shift, mask and scratch-word store needed for a 2-character field held mid-word — which, together with msg 170,00 "-WHEN- SUBSTITUTED FOR -IF- BECAUSE OF IMPROPER USE." showing a shared front-end path ([J 90.04.01]), makes it likely — *inference*, nowhere stated — that the fold applies to WHEN clauses identically. Second, a figurative constant does not create an unequal-length case: `IF D.EMP.NO = HIGH.VALUE` compiles to a full run-time compare against `CP)+23`, generated as `OCT 747474747474` — six left-parenthesis characters, HIGH.VALUE in the 709/7090 collating sequence ([J 02.04.01]) — materialised at exactly the length of the field it is compared with ([J 90.05] listing, PDF pp. 202, 216). (That observation says nothing about constant folding in general: only one operand of such a test is known at compile time, so its outcome is not.) The fold rests solely on the statically known field lengths, there being no blank padding of the shorter field. 

    **Still open:** the emitted form of a folded WHEN clause — presumably no code for an always-false `=` clause and an unconditional transfer for an always-true `NOT =` one, which would strand every later clause of the same conditional GO TO, since "Any remaining conditional expressions are left unevaluated" ([F p. 48]) — and whether folding is diagnosed at all, which J's message list suggests it is not, carrying only "ILLEGAL COMPARISON STRUCTURE." (msg 107,00) and "CANNOT USE VARIABLE LENGTH ITEMS FOR COMPARISON." (msg 123,00) ([J 90.04.01]).
43. May the assigned GO TO's parenthesized procedure-name list be split across cards at any word boundary per the general continuation rule, or are there additional restrictions? (F pp. 28, 49)

### Input/output

44. What is the exact card syntax and placement of the PATTERN option on the FILE card (keyword form, delimiters, interaction with per-record options)? Only its existence, purpose, and 16-record limit are recoverable. ([J 02.07.04]; [J 90.04.01] msgs 48–50)
45. What is the field layout of the standard 14-word tape label (header and trailer) that IOCS checks and writes? It lives in the IOCS manual (C28-6100-2) and the unavailable Appendix 90.07. 

    **Resolved (external source, 2026-08-01; scan-verified 2026-08-02):** The IOCS manual gives the layout in full and confirms the length three independent ways: "IOCS will automatically process 14-word labels of the following formats:", heading the Standard Label Formats section (external: C28-6100-2, PDF p. 29 / printed p. 21); "The standard label area at symbolic locations IOCS + 43 (see page 39) will be used; its length is 14 words." (external: C28-6100-2, PDF p. 32 / printed p. 24 — item 3 of the list of procedures executed when a NON-standard label package is specified — the manual: "If the decrement is zero, standard images are assumed; if it is non-zero, the following procedures will be executed:" — i.e. even a user label package still works through the standard 14-word area; erratum applied 2026-08-02); and the entry "LAREA | IOCS + 43 to IOCS + 56 | Label area (14 words)" in the table of quantities "located near the beginning of IOCS" under References to System Subroutines (external: C28-6100-2, PDF p. 47 / printed p. 39), 43–56 inclusive being exactly 14 words. LAREA is almost certainly the area J calls IOC)29, "a 14 word area within IOCS which is used to process all labels" ([J 90.02.08]), and the area the LABEL type code redefines ([J 02.05.03]) — *inference*, from the matching size and role; neither manual states the equation. The label is 14 words = 84 BCD characters, and the IOCS tables index it by BCD position 1–84 (only the blank-reel table is dimensioned in card columns). Header label — word (BCD positions) content, meaning (external: C28-6100-2, PDF p. 30 / printed p. 22): 1 (1–6) `1HDRbb`, label identifier; 2 (7–12) `bXXXXX`, tape serial number; 3 (13–18) `bXXXXX`, file serial number; 4 (19–24) `bXXXXb`, reel sequence number ("the first reel of a file is reel 0001, the second is reel 0002"); 5 (25–30) `XXbYYY`, creation date ("XX — Year", "YYY — Day of year (001-365)"); 6 (31–36) `bbbXXX`, retention days; 7 (37–42), a packed flag word the table breaks into five rows — 37–38 `bX` file density, position 37 blank and the digit in 38 (0 low, 1 high); 39 file mode (0 BCD, 1 binary); 40 block check sum indicator (binary files only); 41 block sequence indicator (binary files only); 42 "Checkpoint record indicator / 0 – No checkpoint record / 1 – Checkpoint record follows label"; 8–10 (43–60) BCD file name; 11–12 (61–72) "Not used, but reserved for 709/90 Sort compatibility"; 13–14 (73–84) not used. Words 3, 4 and 8–10 are the fields IOCS validates when the file is opened and at the beginning of each new reel of a multi-reel file: file serial number against the FILE card; reel sequence number against the FILE card "unless, of course, reel switching has occurred, in which case IOCS will have advanced the reel sequence number stored in the File Control Block"; and file name against the FILE card, except that "If no file name is given on the FILE card, this test is bypassed." Failure gives `LABEL ERROR, INPUT REEL INVALID` (external: C28-6100-2, PDF p. 31 / printed p. 23). Two of these are the object-time counterpart of COMTRAN's SERIAL and REEL options, whose 5- and 4-character limits match the label's `bXXXXX` and `bXXXXb`; COMTRAN's RETAIN (3 characters) corresponds instead to header word 6 and is never checked on input, only on the output side ([J 02.06.12], which says the SERIAL/REEL/RETAIN information "is kept in the IOCS file block" and "is used by IOCS in checking and preparing standard labels"). The File Control Block keeps all four separately, as words 7, 8, 9 and 10–12: file serial number, reel sequence number, retention days, file name (external: C28-6100-2, PDF p. 73 / printed p. 65). Trailer label — same 14 words, only three defined (external: C28-6100-2, PDF p. 31 / printed p. 23): 1 (1–6) `1EORbb` "End of reel trailer" or `1EOFbb` "End of file trailer"; 2 (7–12) `bXXXXX` block count; 3 (13–18) `bXXXXX` unit control word, "the location in storage of the first word of the Unit Control Block which specifies the tape unit the reel was prepared on, and the logical number it was assigned"; 4–14 (19–84) not used. Header and trailer therefore share only their length and the convention that word 1 is a six-character identifier beginning `1`. "During writing, an EOR label is prepared by IOCS when the end of a reel is encountered. An EOF label is prepared when the file is closed." The only count in either label is a **block** count, in the trailer. Its table gloss reads "Number of blocks in file", but the accompanying prose defines it per reel: "BLOCK COUNT is the number of data blocks on this reel. This is checked for every input reel. If it differs from the number of blocks actually read in, a sequence error is given" (external: C28-6100-2, PDF p. 31 / printed p. 23); the running value is held in File Control Block word 4 bits 3–17, "Counter for block sequence checking" (external: C28-6100-2, PDF p. 75 / printed p. 67). No *record* count appears in any standard label — see open question 50. The third standard format, the blank-reel label, is dimensioned in card columns because it is written card-to-tape: word 1 (cols 1–6) `1BLANK`, word 2 (7–12) `bXXXXX` tape serial number, words 3–14 (13–80) not used (external: C28-6100-2, PDF p. 29 / printed p. 21). A reel accepted for labeled output must carry either a `1BLANK` label or a `1HDR` label on which (creation date + retention days) has been reached; if not, "either or both" of `LABEL ERROR, OUTPUT REEL INVALID` and `LABEL ERROR, RETENTION NOT EXPIRED` are printed (external: C28-6100-2, PDF p. 32 / printed p. 24).
46. What is the IOCS-to-programmer calling convention for the FOR LABEL exit (distinguishing open/close/reel-switch; returning control)? 

    **Resolved (external source, 2026-08-02):** the IOCS manual prints the linkage in full, and it is not a single exit but a **five-entry transfer vector** — which is precisely why one COMTRAN `FOR LABEL statement.name` cannot express it and why "portions of the FOR LABEL coding must be done in CRYPT" ([J 02.05.03]). 

    *Where the routine's address lives.* "If the non-standard labels to be processed adhere to the general IOCS labeling scheme, non-standard label images may be easily handled by IOCS, using different routines to check and prepare label images. For this purpose, IOCS allows a non-standard label image package to be specified for each file. The location of the first cell of this package can be specified in the decrement of each entry in the list of files used for the ATTACH routine. If the decrement is zero, standard images are assumed; if it is non-zero, the following procedures will be executed: 1. All labels, both headers and trailers, will be read and written by the system. 2. All EOF marks associated with labels will also be read and written by the system. 3. The standard label area at symbolic locations IOCS + 43 (see page 39) will be used; its length is 14 words. 4. All the system actions and messages will apply." (external: C28-6100-2, PDF p. 32 / printed p. 24). The address is then held in the File Control Block as word 3 bits 3–17, "Location of entry point for standard or non-standard label image routines" (external: C28-6100-2, PDF p. 75 / printed p. 67), the FCB diagram labelling the same field "Entry point for non-standard label image routines" (external: C28-6100-2, PDF p. 73 / printed p. 65). That field carries **no asterisk**, and the appendix's key reads "Items marked with an asterisk are generated in the File Control Block by the Preprocessor. The remaining positions are initially zero." (external: C28-6100-2, PDF p. 73 / printed p. 65) — so the Preprocessor never fills it, and the zero it is left holding is exactly the "decrement is zero, standard images are assumed" default (*inference*, from the two statements together). *(Errata for the open-question-45 entry, which glosses the 14-word sentence as "item 3 of the list of what happens when standard label images are assumed": the list is the **non-zero-decrement** case — what happens when a non-standard package **is** supplied. The 14-word figure it cites is unaffected; only the framing needs correcting.)* 

    *There is no control-card route to it, in either system.* The IOCS Preprocessor's \*FILE card carries only column 32, "Labeling conventions: H—High density label / L—Low density label / S—Standard density convention / blank—No label" (external: C28-6100-2, PDF p. 52 / printed p. 44). Decisively for COMTRAN, J's own Appendix 90.08 tabulates every field of the Loader \*FILE card **as generated by the Compiler** from Environment FILE and SPECIF options — columns 17, 18-21, 22-25, 27, 28, 29, 30, 31, 32, 33, 34, 35, 38-41, 44-48, 51-53 and 54-72 — and none of them is a label-routine entry point ([J 90.08.01]). The address can therefore only be planted at object time by generated code, by one of two routes J's runtime already has: the ATTACH file-list decrement, IOC)5 being "The entry point to the IOCS ATTACH subroutine", or a direct store into FCB word 3 through IOC)2, "A cell in the CT Monitor communication area which locates (L) a number (N) of IOCS file blocks. I/O information is kept in each of the 12 word blocks for every file in the CT program" ([J 90.02.08]). *Inference*: neither manual says which the field-test compiler used. 

    *Register and parameter conventions.* Two rules precede the vector: "5. At each TSX, index register 2 will contain the 2's complement of the location of the first word of the File Control Block for the file being processed." and "6. The contents of all index registers used must be saved and restored." (external: C28-6100-2, PDF p. 33 / printed p. 25). There are **no parameter words**: the label image is the parameter and it is passed in storage — the 14-word area "LAREA | IOCS + 43 to IOCS + 56 | Label area (14 words)" (external: C28-6100-2, PDF p. 47 / printed p. 39), which is the area COMTRAN's LABEL type code redefines ([J 02.05.03]) and which is almost certainly J's IOC)29, "a 14 word area within IOCS which is used to process all labels" ([J 90.02.08]) — *inference* from matching size and role, as flagged at open question 45; neither manual states the equation. Everything else the routine needs is reachable off index register 2: file serial number (FCB word 7), reel sequence number (word 8), retention days (word 9), file name (words 10–12), the block-sequence counter (word 4 bits 3–17), and the label / multi-reel / density / end-of-tape flags (word 2) (external: C28-6100-2, PDF pp. 74–76 / printed pp. 66–68). J confirms the programmer is expected to work from exactly those cells: the SERIAL, REEL and RETAIN information "is kept in the IOCS file block ... It is used by IOCS in checking and preparing standard labels (but not non-standard labels) and may be used by the programmer in checking and preparing non-standard labels" ([J 02.06.12]). 

    *The vector, verbatim.* "Assuming that the non-standard label package begins at symbolic location MYLBLS, then the following actions will occur as indicated: 1. `TSX MYLBLS, 1` — To check header label input file. The routine must return by means of: `TRA 1, 1` if label is correct / `TRA 2, 1` if the input label is invalid. Bit 35 of the 7th word of the label area must be 1 upon either return if a checkpoint record is to be skipped. 2. `TSX MYLBLS + 1, 1` — To check trailer label, input file. Return must always be: `TRA 1, 1`. Upon return, the sign of the MQ must be: + if EOR; tape switching will occur / − if EOF; an EOF exit will be taken. 3. `TSX MYLBLS + 2, 1` — To check label on tapes to be used for output. Return must be: `TRA 1, 1` if the reel may be used / `TRA 2, 1` if (creation date + retention days) has *not* been reached / `TRA 3, 1` if it is not possible to use the reel. 4. `TSX MYLBLS + 3, 1` — To prepare output trailer label. Return must always be: `TRA 1, 1`. Upon return, bits P, 1-35 of the AC must contain: `1EORbb` if an EOR trailer is to be prepared / `1EOFbb` if an EOF trailer is to be prepared. 5. `TSX MYLBLS + 4, 1` — To prepare output header label. Return is: `TRA 1, 1`." (external: C28-6100-2, PDF p. 33 / printed p. 25, the manual setting each alternative return on its own line.) Item 1's checkpoint bit is consistent with the standard header layout, where BCD position 42 — the last character of word 7, i.e. bit 35 — is the "Checkpoint record indicator" (external: C28-6100-2, PDF p. 30 / printed p. 22). *How the routine learns which event applies:* **by entry point — there is no event code and no parameter.** The five cells are one word each and IOCS enters the one appropriate to the event, so both the event and its direction are implicit in the entry chosen. Mapping onto J's three COMTRAN events ("when the file is opened or closed, or when a reel switch occurs", [J 02.05.03]): opening an input file → entry 1; opening an output file → entry 3, vetting the reel already mounted, then entry 5, writing the new header; reel switch on input → entry 2 for the exhausted reel's trailer, then entry 1 for the new reel's header; reel switch on output → entry 4 with AC = `1EORbb`, then entries 3 and 5 for the new reel; closing an output file → entry 4 with AC = `1EOFbb`; closing an *input* file → no call at all, the trailer having been checked when it was read. That mapping is *inference* — the manual nowhere tabulates events against entries — drawn from the entry descriptions plus IOCS's standard-label timing, "Note: During writing, an EOR label is prepared by IOCS when the end of a reel is encountered. An EOF label is prepared when the file is closed." (external: C28-6100-2, PDF p. 31 / printed p. 23), and the glossary's CLOSE, "The IOCS routine used to terminate file usage, prepare end of file trailer labels, and rewind the file" (external: C28-6100-2, PDF p. 83 / printed p. 75). 

    *Two returns are decisions, not merely status.* At entry 2 the **user routine, not IOCS**, decides whether the reel just finished is the last: the MQ sign it leaves determines whether IOCS switches reels or raises end of file — the same discrimination the standard trailer's `1EORbb`/`1EOFbb` identifier makes for standard labels (external: C28-6100-2, PDF p. 31 / printed p. 23). At entry 4 the routine announces in the AC which trailer kind it has built. How it is expected to *know* which is wanted is not stated; the natural sources are FCB word 2 bit 15 ("End-of-tape: 1 – No / 0 – Yes") or bit 16 ("File permanently closed"), both reachable off index register 2 (external: C28-6100-2, PDF p. 75 / printed p. 67) — *inference*, supported by no text. *What the routine may do:* only inspect and fill the 14-word image. All tape motion stays with IOCS ("All labels, both headers and trailers, will be read and written by the system"; "All EOF marks associated with labels will also be read and written by the system"), and the system's own reactions are unchanged ("All the system actions and messages will apply") — so the standard label-error apparatus remains in force: `UNIT XXXXX (file name) LABEL ERROR` with its cause line, `IF SSWX DOWN IGNORED`, `OPERATOR ACTION PAUSE`, and Label Control Sense Switch handling (external: C28-6100-2, PDF p. 68 / printed p. 60; PDF p. 63 / printed p. 55). *Inference*, and unstated: that entry 1's `TRA 2, 1` is what raises `INPUT REEL INVALID` and entry 3's `TRA 2, 1` / `TRA 3, 1` what raise `RETENTION NOT EXPIRED` / `OUTPUT REEL INVALID`; the manual says only that the system messages apply, never which return triggers which. A hard length constraint also survives into the non-standard case: IOCS rejects any label record that is not exactly fourteen words, "(file name) NO LABEL, BLANK CREATED — The record read as the label of an input file was not fourteen words in length" and "(file name) NO TRAILER — The record read as the trailer label of an input file was not fourteen words in length. The end of file condition is assumed. There is no stop associated with this error." (external: C28-6100-2, PDF p. 69 / printed p. 61) — so J's "a label of 14 words or less" ([J 02.06.11]) must mean the programmer may *use* fewer than 14 words of the area, not write a shorter record (*inference*). Finally, the mechanism reaches only labels that "adhere to the general IOCS labeling scheme"; "Non-standard labels may be either a mere arrangement of the standard format or an entirely different labeling procedure. If non-standard labeling procedures are desired, the IOCS labeling routines must be entirely replaced. However, if only changes in label formats are desired, the IOCS label handling routines will still apply." (external: C28-6100-2, PDF p. 32 / printed p. 24) — the second case being beyond anything COMTRAN can express. Note also "Labeling is not available for files processed on any on-line card equipment." (external: C28-6100-2, PDF p. 29 / printed p. 21), so FOR LABEL is inoperative on a card file. *How control returns:* by **skip return through index register 1**. TSX leaves in the index register the 2's complement of its own location — "TSX — Transfer and Set Index ... This instruction places the 2's complement of the core address of the TSX(IC) in the specified index register (T). The computer takes its next instruction from location Y." (external: 22-6528-4, PDF p. 39 / printed p. 39) — and "Effective addresses are always formed in the computer by the addition of the 2's complement of the contents of the index register." (external: 22-6528-4, PDF p. 10 / printed p. 10). So `TRA 1, 1` returns to the word immediately following the TSX, `TRA 2, 1` to the second word after it and `TRA 3, 1` to the third: at entries 1 and 3 the caller must reserve one and two words respectively after the TSX for the alternate returns. This settles J's otherwise unmotivated CRYPT requirement three times over. (i) No COMTRAN statement can execute `TRA 2, 1`, set the MQ sign, or load the AC with a BCD identifier. (ii) The machine has only three index registers — "Three index registers (XR) are used in the computer. These registers are called A, B, and C or 1, 2, and 4." (external: 22-6528-4, PDF p. 9 / printed p. 9) — and IOCS commandeers two of them at every entry, IR1 as the return link and IR2 as the FCB pointer, while COMTRAN object code uses IR1 and IR2 freely as record base registers (`LAC BL)2,1` / `CLA 1)FICA,1`, [J 90.05] listing, PDF p. 210; `CAL 1)DATE,1`, PDF p. 211; `SLW 1)DATE,2`, PDF p. 205) and IR4 as its TSX linkage and data base register (`LAC BL)2,4` / `CAL DATANAME,4`, [J 90.02.04]–05). A COMTRAN procedure entered at a label exit would destroy the return address in IR1 at its first based data reference (*inference*). (iii) Item 6 obliges the routine to save and restore whatever it uses, which no COMTRAN-level construct does. 

    *Still open — the COMTRAN surface.* `FOR LABEL statement.name` names **one** procedure while IOCS wants **five** entry points, and neither manual says how the compiler bridges the two: whether it emits a five-word vector all of whose entries funnel into the named procedure after setting a discriminator, and if so what cell the programmer is to test. No such cell is named anywhere in J (02.05.03, 02.06.05, 02.06.12, 90.02, 90.04, 90.08), and Appendix 90.07, "SAMPLE NON STANDARD LABEL PROCESSING (Not Currently Available)", which would have shown it, does not exist in this edition. Recommendation for the compiler: generate the five-word vector, plant its address in the ATTACH file-list decrement (equivalently FCB word 3 bits 3–17), reserve the alternate-return words after each TSX, and define a documented event code the FOR LABEL procedure can test — a design choice, not a recovered fact. **Confidence: certain** on the IOCS calling convention (printed in full, verified against the page images) and on the return arithmetic (7090 principles of operation); **tentative** on the COMTRAN-to-IOCS glue. §8.5.6's "FOR LABEL / LABELN linkage documented only by a missing appendix" should accordingly be **narrowed** — the runtime linkage is now fully specified, and only the compiler's surface-to-vector mapping is unrecovered — rather than closed. ([J 02.05.03]; [J 02.06.05], 02.06.11–12; J 00.00 contents; [J 90.02.04]–05, 90.02.08; [J 90.05] listing, PDF pp. 205, 210–211; [J 90.08.01]; external: C28-6100-2, PDF pp. 29–34 / printed pp. 21–26, PDF p. 47 / printed p. 39, PDF p. 52 / printed p. 44, PDF p. 63 / printed p. 55, PDF pp. 68–69 / printed pp. 60–61, PDF pp. 73–76 / printed pp. 65–68, PDF p. 83 / printed p. 75; external: 22-6528-4, PDF/printed pp. 9, 10, 39)
47. Does OPEN ALL FILES exist in the implemented language? J discusses only CLOSE ALL FILES and records no deferral of the OPEN form — presumably yes per [F p. 39], but unverifiable from J. **Resolved (90.02 mining, 2026-08-01): yes — `OPEN ALL FILES` is in the implemented language.** The field-test sample's first procedure statement is `188,00 71466 START. OPEN ALL FILES,` ([J 90.05] listing, PDF p. 195), the listing closes with "NO ERRORS WERE DETECTED DURING COMPILATION" ([J 90.05] listing, PDF p. 197), and the object code generated at that label is `START TSX SYS)175,4` / `+1 PZE IOC)1` ([J 90.05] listing, PDF p. 200) — SYS)175 being the routine of which J says "This routine opens all files in the file list located by IOC)1" ([J 90.02.14]), and IOC)1 being "A cell in the CT Monitor communications area which locates (L) a list of files, and designates the number (N) of files in the list. This List is used in Opening and Closing files" ([J 90.02.08]). The processor in fact carries the complete four-way OPEN/CLOSE runtime that F's two forms of each verb require: SYS)174 "opens the file designated FILENAME" ([J 90.02.13]), SYS)175 opens all, SYS)176 "closes the file designated FILENAME" and SYS)177 "closes all files in the file list located by IOC)1" ([J 90.02.14]). The named-file OPEN is independently attested by diagnostic 139,00 "FILE NAME SHOULD FOLLOW -OPEN-." ([J 90.04.01]), and ALL, FILES, OPEN and CLOSE are all J reserved key words ([J 02.03.02]). The CLOSE side corroborates the reading: `CLOSE ALL FILES, STOP RUN.` ([J 90.05] listing, PDF p. 196) compiles to `TSX SYS)177,4` / `PZE IOC)1`, then the STOP display call `TSX SYS)178,4` with its two constant-pool words, then a *second* `TSX SYS)177,4` / `PZE IOC)1` immediately before the end-of-job return `TXI IOC)40,0` ([J 90.05] listing, PDF p. 204) — the implicit close-all that [J 02.04.06] ascribes to STOP RUN ("All open files are closed prior to this transfer of control as if a CLOSE ALL FILES had been supplied"). J's silence about OPEN ALL FILES in 02.04.06 is therefore an omission of prose, not of the feature; [F p. 39] stands as its definition. ([F p. 39]; [J 02.03.02]; [J 02.04.06]; [J 90.02.08], 90.02.13–14; [J 90.04.01] msgs 138–139; [J 90.05] listing, PDF pp. 195–197, 200, 204; images/page-153.png, page-195.png, page-200.png) 

    **Verified (independent re-derivation + scan check, 2026-08-02):** every link in the chain was re-read from the sources and checked against the page images, and each holds character for character: `TSX SYS)174,4` / `PZE FILENAME` with "This routine opens the file designated FILENAME." ([J 90.02.13], images/page-152.png); `TSX SYS)175,4` / `PZE IOC)1` with "This routine opens all files in the file list located by IOC)1.", followed on the same page by the matching `SYS)176` "closes the file designated FILENAME" and `SYS)177` "closes all files in the file list located by IOC)1" ([J 90.02.14], images/page-153.png); the source line `188,00 71466 START. OPEN ALL FILES,` (images/page-195.png); the object pair `00165 0074 00 4 00257 10010 START TSX SYS)175,4` / `00166 0 00000 0 00001 10010 +1 PZE IOC)1` (images/page-200.png); the two `TSX SYS)177,4` / `PZE IOC)1` pairs at 00517/00520 and 00524/00525 straddling the STOP display call `TSX SYS)178,4` and ending at `TXI IOC)40,0` — IOC)40 being "the end of job return point in the CT Monitor communication area for all CT jobs" ([J 90.02.08]) — (images/page-204.png); and the diagnostic pair `138,00 0 FILE NAME SHOULD FOLLOW -CLOSE-.` / `139,00 0 FILE NAME SHOULD FOLLOW -OPEN-.` ([J 90.04.01], PDF p. 184, images/page-184.png). Two supports are added. First, beneath the SYS) wrappers the runtime carries the IOCS primitive itself — "IOC)7 The entry point to the IOCS OPEN subroutine.", listed immediately after "IOC)6 The entry point to the IOCS CLOSE subroutine." ([J 90.02.08]) — so the open path exists at both levels of the object-time library. Second, J's single sentence on the verb, "A file is referenced by the commands OPEN and CLOSE to initiate and complete file activity. (See Commercial Translator General Information manual)." ([J 02.07.01]), is an explicit deferral to F rather than a restriction, and Appendix 90.01 defers no part of OPEN, so nothing in J qualifies F's second form. ([J 02.07.01]; [J 90.01]; [J 90.02.08]; [J 90.04.01] msgs 138–139; images/page-152.png, page-153.png, page-184.png, page-195.png, page-200.png, page-204.png)
48. What happens at object time when a FILE'd record exceeds the file's BLOCKSIZE and SPANS was not specified for the *output* file? Input-side violations are defined; output-side behaviour is not. ([J 02.07.06]; [J 90.04.01] msg 5)
49. Is there a maximum record length independent of BLOCKSIZE 9999, or a limit on record.names per FILE card (beyond 63 files total and 16 per PATTERN)?
50. How does the record-count comparison at CLOSE ([F p. 41]) behave for unlabeled or LABELN files — is any count check performed outside standard labels? **Resolved (external source, 2026-08-02): no reel- or file-level count check exists outside standard labels**, and [F p. 41]'s record-count comparison has no IOCS counterpart even inside them. 

    *What IOCS checks on a standard-labeled input file.* Word 2 of the trailer is a **block** count, verified for every reel, not only the last: "BLOCK COUNT is the number of data blocks on this reel. This is checked for every input reel. If it differs from the number of blocks actually read in, a sequence error is given. In this case it should be noted that a sequence error for the reel can occur even though each block is not being checked for sequence" (external: C28-6100-2, PDF p. 31 / printed p. 23), restated under Input File Trailer Labels as "The Block Count which appears in every trailer written by the system is checked and a sequence error exit is taken if it does not agree with the number of blocks 'read.'" (external: C28-6100-2, PDF p. 32 / printed p. 24). The running total is File Control Block word 4 bits 3–17, "Counter for block sequence checking" (external: C28-6100-2, PDF p. 75 / printed p. 67): "Every File Control Block carries a block sequence number for the current reel of the file. On a labeled file, this sequence number is always written in a trailer label at the end of each reel and checked when it is read" (external: C28-6100-2, PDF p. 41 / printed p. 33). 

    **Note the consequence for J:** [J 02.07.06] says "If block sequence checking is desired the Environment SPECIF card option SEQ must be selected", but the trailer check is automatic on any labeled file whatever SEQ says — the italicised IOCS sentence above exists precisely to make that point. A COMTRAN file with LABELS and no SEQ can therefore still take a block sequence error. 

    *What a mismatch does — and where.* Not a message: a program exit. The condition is a "sequence error", one of the three ERR conditions of the READ routine — "ERR is the location to which transfer is made when any of three types of error conditions occur:   
    (a) a redundancy which cannot be corrected;   
    (b) check sum error (binary file); and   
    (c) sequence error. The condition is recognized at the first reference to a buffer in which it occurs. The error encountered may be ignored by continuing to 'read' the file" (external: C28-6100-2, PDF p. 24 / printed p. 16). The abnormal-conditions table gives "READ | Block sequence error | ERROR exit MQ(S-2) = 1" (external: C28-6100-2, PDF p. 79 / printed p. 71, MQ subscripted S-2 as printed), matching the history-record convention "1—if a sequence error occurred" (external: C28-6100-2, PDF p. 25 / printed p. 17) and the glossary's ERR, "An address, specified in the calling sequence of the READ routine, which is used as an exit upon recognition of an uncorrectable redundancy, or a block sequence or check sum error" (external: C28-6100-2, PDF p. 84 / printed p. 76). **No block-count or sequence-error text appears anywhere in the IOCS System Messages and Halts list** (external: C28-6100-2, PDF pp. 66–70 / printed pp. 58–62) or in the restart messages (PDF pp. 71–72 / printed pp. 63–64). In COMTRAN this is the file's ON ERROR exit, and J says so in its own words: "IOCS cannot continue processing after discovering an unrecoverable redundancy error, a block checksum error or a block sequence error without direction from the programmer. The ON ERROR option of the Environment FILE card provides for communication between IOCS and the programmer in these three error situations" (J 02.07.07) — the identical triple, reached through the identical calling-sequence slot, IOCS's READ being "`TSX READ,4` / `PZE FILE,,EOB` / `PZE EOF,,ERR` / `IOXY A,,m`" where "FILE is the file designation, EOB is the end of buffer switch, EOF is the end of file exit, and ERR is the error exit" (external: C28-6100-2, PDF p. 23 / printed p. 15) against J's `TSX IOC)8,4` / `PZE FILENAME,,SYS)260` / `PZE END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE` / `IOCDN* BL)2,,14` (J 90.02.04). The correspondence is word for word, so SYS)260 is the EOB switch and the COMTRAN ON ERROR procedure is IOCS's ERR exit, defaulting to SYS)283 when no ON ERROR is coded (J 90.02.32) — *inference* from the two templates, corroborated by J's own remark that record length errors are "referred to as EOB errors in the IOCS manual" (J 02.07.06). The error is resumable: "The error encountered may be ignored by continuing to 'read' the file." 

    *And it does not fire at CLOSE.* The check is described inside READ, at the moment the trailer is read; CLOSE's label work is output-side only — "For a regular output file, a close other than the MON type, causes writing of   
    (1) an EOF mark, a trailer label, and another EOF mark, if the file is labeled, or   
    (2) an EOF mark only, if the file is unlabeled" (external: C28-6100-2, PDF p. 27 / printed p. 19) — and the glossary defines CLOSE as "The IOCS routine used to terminate file usage, prepare end of file trailer labels, and rewind the file" (external: C28-6100-2, PDF p. 83 / printed p. 75). *Inference* (the manual states no negative): nothing at close compares anything on an input file. 

    *Unlabeled files: nothing at all.* With no labels there is no trailer and hence no count, and IOCS makes end-of-data the programmer's problem. Single-reel: "It is the programmer's responsibility, in this case, to determine which EOF mark signifies the actual end of the file. No reel switching is possible for input files of this type." Multi-reel: "An EOF exit is given once per reel for each EOF encountered and if the file is again referenced by a READ operation, reel switching will occur and buffering will be resumed. For this type of file, the user must have a recognizable data record to indicate that the end of the file has been reached." (external: C28-6100-2, PDF p. 34 / printed p. 26.) *This also settles open question 53*, and the J-to-IOCS bridge is explicit: the compiler generates Loader \*FILE column 29 = "M - multi-reel unlabeled file" from "MULTI, neither LABELS nor LABELN" ([J 90.08.01]), which is exactly IOCS's Multi-Reel Unlabeled Files case. Nothing substitutes for the end-of-reel label check — a sentinel data record is the only recourse, which is the HIGH.VALUE idiom the J sample uses. 

    *The one check independent of labeling — and its unstated restriction.* "In addition, for a binary file, a block sequence word can be appended to the end of each block, regardless of whether the file is labeled or unlabeled. This word contains the sequence number of the block in its address and may also contain an 18-bit folded check sum of the block in the left half of the word." (external: C28-6100-2, PDF p. 41 / printed p. 33). This is a per-block sequence check, not a file- or reel-level count, and it is the *only* labeling-independent sequence check IOCS has; uncorrectable-redundancy detection, the other labeling-independent integrity mechanism, checks no counts. These are the object-time counterparts of COMTRAN's SPECIF SEQ and CKSUMS: the compiler generates \*FILE column 33 "block sequence numbers to be checked | SPECIF - SEQ" and column 34 "block checksums to be checked | SPECIF - CKSUMS" ([J 90.08.01]), and IOCS's own definition of those columns restricts them — column 33 "Block sequence numbering flag (**significant for binary files only**): S—Sequencing words provided", column 34 "Check sum flag (**available for binary sequence numbered files only**): C—Check sums included" (external: C28-6100-2, PDF p. 52 / printed p. 44). The FCB encoding admits no other combination: word 2 bits 10–11 are "00 – No block sequence words / 10 – Block sequence word is present, no check sums. / 11 – Block sequence word is present, check sums are present (input) or are to be computed (output)" — there is no state for check sums without a sequence word (external: C28-6100-2, PDF p. 74 / printed p. 66). J mentions neither restriction, saying only "Block checksums are not checked unless the Environment SPECIF card option CKSUMS is selected" ([J 02.07.06]). Since "If no specification is made the file is assumed to be BCD" ([J 02.06.04]), and every file in the J sample is BCD, the practical conclusion is that on a normal COMTRAN file SEQ and CKSUMS are inoperative and the compiler passes them through unchecked — *inference*, from the card mapping plus the IOCS column definitions. Worth recording in §7 alongside the option table. 

    *LABELN / non-standard labels.* IOCS still reads and writes the labels and their EOF marks and still maintains the block counter, but the **content** check passes to the user: entry `MYLBLS + 1` "To check trailer label, input file" is the routine that sees the trailer image (external: C28-6100-2, PDF p. 33 / printed p. 25; see open question 46). *Inference:* IOCS cannot itself perform the block-count comparison on a non-standard trailer, because it does not know where in the image the count lies; the manual scopes the check to "every trailer **written by the system**" (external: C28-6100-2, PDF p. 32 / printed p. 24), and checking is exactly the half of the labeling routines the package replaces ("using different routines to check and prepare label images", same page). J corroborates the general delegation: the SERIAL/REEL/RETAIN information "is used by IOCS in checking and preparing standard labels (but not non-standard labels) and may be used by the programmer in checking and preparing non-standard labels" ([J 02.06.12]) — a statement about those three fields rather than the block count, but the same division of labour. What IOCS still supplies is the running counter in FCB word 4 bits 3–17, reachable off index register 2 at every entry, so a FOR LABEL routine can do the comparison itself. Countervailing evidence, which the manual never disambiguates: item 4 of the non-standard-package list, "All the system actions and messages will apply", could be read as retaining it. **Confidence on this sub-point: probable.** *Can [F p. 41] be mapped onto IOCS at all?* F says "The record count is compared with the count in the end-of-file label if label records are present and if end of file has been reached. If the count does not agree, notification is given through external display. If the tape is not at end of file the record count is ignored" ([F p. 41]), the count having been started at OPEN ("Checking is performed, and a record count is initiated", [F p. 39], for input and output alike) and maintained at FILE ("A count of the number of records written is maintained", [F p. 41]). Four of its five elements fail against IOCS, and the failure of the first is definitional. 

    **Unit:** IOCS's glossary fixes "record" in the physical sense — "BLOCK — A physical record; that is, a tape record, a card, or a line of print"; "BLOCK COUNT — The number of blocks processed on the current reel of a file, kept in the corresponding File Control Block"; against "LOGICAL RECORD — Data which, as a group, has some logical significance to the user" (external: C28-6100-2, PDF pp. 83, 85 / printed pp. 75, 77). Every count IOCS keeps is of physical records, and **no logical-record count appears in any standard label**. The only two other places IOCS counts "records" are tape-repositioning data — "If the Unit Control Block is for a tape unit, it also contains counts which specify the current position of the tape (file count, and record count within the file)" (external: C28-6100-2, PDF p. 49 / printed p. 41) — and the reel-removal printout "UNIT XXXXX (file name) REEL XXXX – XXXXX RECORDS" (external: C28-6100-2, PDF p. 67 / printed p. 59); neither is a label field and neither is compared with anything. *Inference:* F's record count coincides with IOCS's block count only on an unblocked file, one logical record per block; for any COMTRAN file whose BLOCKSIZE holds more than one record, F's quantity denotes nothing IOCS keeps. 

    **Timing:** F at CLOSE, IOCS inside READ when the trailer is read. 

    **Reporting:** F "notification … through external display", IOCS a sequence-error ERR exit with MQ prefix 1 and no printed message at all. 

    **Scope:** F only at end of file, IOCS every input reel. What *does* survive is F's conditional "if label records are present" — precisely right, since outside standard labels there is nothing to compare — and F's output-side clause "If specified by the programmer, an end-of-file label containing the record count is written", which is structurally right: IOCS writes the `1EOFbb` trailer at close with a count in word 2 at exactly that point, only it counts blocks. 

    *Resolution for the language definition.* Answer to the question as put: **no** — under LABELN the check is whatever the FOR LABEL routine performs, and unlabeled files get none. [F p. 41]'s input-side close-time record-count comparison should be recorded not as an F/J divergence proper — J diverges from nothing, it defers, "A file is referenced by the commands OPEN and CLOSE to initiate and complete file activity. (See Commercial Translator General Information manual)." ([J 02.07.01]), leaving F's text as J's only prose on the verb — but as **an F description the object-time system cannot honour**, and dropped from the implemented semantics. The compiled sample bears that out: the GET calling sequence is four words with no counter increment (`00200 TSX IOC)8,4` / `PZE INPUTMASTER,,SYS)260` / `PZE GN)058,,SYS)283` / `IOCTN* BL)2,,15`) and `CLOSE ALL FILES` compiles to `TSX SYS)177,4` / `PZE IOC)1` with no comparison anywhere ([J 90.05] listing, PDF pp. 201, 204) — *inference*: the field-test compiler maintained no record count at all. What a COMTRAN compiler must document instead is that a labeled input file's per-reel **block** count is verified automatically by IOCS, whatever SEQ says, and that a mismatch is delivered to the file's ON ERROR exit, resumable, with no message. **Confidence: certain** on the main claim, on the ON ERROR routing and on the block-versus-record finding; **probable** on the LABELN delegation; the record ↔ block identification and the non-implementation of F's count are *inference*. ([F p. 39], p. 41; [J 02.06.04], 02.06.12; [J 02.07.01], 02.07.06–07; [J 90.02.04], 90.02.32; [J 90.05] listing, PDF pp. 201, 204; [J 90.08.01]; external: C28-6100-2, PDF p. 23 / printed p. 15, PDF pp. 24–25 / printed pp. 16–17, PDF p. 27 / printed p. 19, PDF pp. 31–34 / printed pp. 23–26, PDF p. 41 / printed p. 33, PDF p. 49 / printed p. 41, PDF p. 52 / printed p. 44, PDF pp. 66–72 / printed pp. 58–64, PDF pp. 74–75 / printed pp. 66–67, PDF p. 79 / printed p. 71, PDF pp. 83–85 / printed pp. 75–77)
51. What are the semantics of an output file assigned to OU (system output unit) with respect to interleaving with compiler/loader listing output? ([J 02.06.10]; J 05)
52. For DISPLAY, what exactly does the 255-word internal-form check count, and how are physical records split on the 716 printer? ([J 02.04.02.01])
53. What substitutes for the end-of-reel label check on an unlabeled MULTI input file? ([F p. 40]; [J 02.06.04]–05) **Narrowed (external source, 2026-08-02):** IOCS offers no substitute check — see Q50's resolution: outside standard labels there is no count check of any kind, and on an unlabeled file the end of data must be signalled by the programmer's own recognizable sentinel record; reel switching on unlabeled MULTI files is likewise uncounted (external: C28-6100-2; full inventory and citations under Q50).
54. In the update-in-place idiom (`FILE MASTER` followed by `GET MASTER` on locate-mode files, as the sample uses), when is the input buffer considered released to the output side? J describes each verb separately; the idiom is never walked through. ([J 02.07]; [J 90.05])

### Environment, library, and system

55. What is the physical library format and how is it built or maintained? F says only that data descriptions and procedures can be stored "in the library, on tape or in cards"; J drops the facility. ([F p. 12], p. 62; [J 90.01.02])
56. Can a CALL synonym be used everywhere its old.name could (Data Description, Environment, CRYPT), and what is the synonym's scope relative to the CALL's position in the source? May it be qualified at all? ([F p. 59]; [J 02.04.04]–05)
57. Where exactly may ENTER CRYPT appear ("at any logical point") — inside a section, inside a DO-subroutine, between divisions — and may the ENTER sentence be named? ([J 02.08.01])
58. Does OPTION COLLATE COM affect only comparisons and HIGH.VALUE/LOW.VALUE, or other behaviour as well? ([J 02.06.16]; [J 02.04.01]) 

    **Narrowed (90.02 mining + 90.05 listing evidence, 2026-08-01; adversarially verified 2026-08-02):** two effects are documented, and the generated-code appendix plus the compiled sample show that the whole object-time apparatus behind them is one table, one switch word, and constants planted at compile time — enough to bound the answer, not to prove a negative. Effect 1 is comparison-instruction selection: the compiler "normally generates comparison type instructions based on the 709/7090 collating sequence", and "Use of this option instructs the compiler to generate comparison type instructions on the basis of the Commercial collating sequence" ([J 02.06.16]). Effect 2 is the figurative-constant extremes — "HIGH.VALUE will be considered to be the left parenthesis, (, and LOW.VALUE the zero, 0, unless the Commercial collating sequence (COM) is specified in the Environment Description. The Commercial HIGH.VALUE is 9 and the LOW.VALUE is blank" ([J 02.04.01]) — and this one reaches past comparison into stored data, since the MOVE/SET result chart flags the HIGH.VALUE and LOW.VALUE rows "#", "Value dependent upon collating sequence order specified (Commercial or 709)" ([J 02.04.02]): `MOVE HIGH.VALUE TO X` deposits `(` natively and `9` under COM. Against a strictly comparison-only reading stands J's own summary of the card, which is worded far more broadly — "OPTION cards are used when the programmer wants the processor to depart from its standard use of 709/7090 collating sequence, or when he wishes special emphasis placed on minimizing either storage or running time requirements in his object program" ([J 02.06.02]) — and that sentence, not any positive evidence of a third effect, is what keeps this entry short of resolved. 

    **Observed in the compiled sample (native mode):** both halves of effect 2 are planted constants, not run-time decisions. `197,00 71504 END.OF.MASTERS. IF D.EMP.NO = HIGH.VALUE THEN GO TO END.OF.RUN` / `OTHERWISE SET M.EMP.NO = HIGH.VALUE.` ([J 90.05] listing, PDF p. 196) compiles its SET as the generic MOVPAK character fill with the character in an in-line word — `TSX SYS)182,4` / `TXI SYS)245,1,6` / `OCT 747474747474` (PDF p. 202, repeated for statement 198,00 at PDF p. 203) — and compiles its comparison against constant-pool word `CP)+23`, whose definition is the identical word `01723 747474747474 ... +23 OCT 747474747474` (PDF pp. 202, 216). The word is six copies of one character, which [J 02.04.01] fixes as `(` for the native sequence (*external corroboration, not from the manuals:* 74 octal is `(` in 709/7090 BCD). Under COM the same two sites would carry `9`s; nothing in either sequence consults a mode at object time. The runtime library likewise contains exactly one collating artifact and exactly one consumer of it — SYS)161, "This is a conversion table used in converting from 709 to 705 collating sequence", used by SYS)162, whose calling sequence is `TSX SYS)162,4` / `OP SYS)161` / `PZE LOC(1), T(1), LOCATOR(1)` / `PZE LENGTH(1), ,6*BYTE(1)` / `PZE LOC(2), T(2), LOCATOR(2)` / `PZE LENGTH(2), ,6*BYTE(2)` / `HIGH RETURN from comparison` / `EQUAL RETURN from comparison` / `LOW RETURN from comparison`, and of which J says "This subroutine performs an alphabetic comparison on two fields. OP is a CVR or NOP depending of the need to adjust the collating sequence before the comparison" ([J 90.02.12]; "depending of" is the original's typo, and the dropped "y" in the same paragraph's "the field is located b the 'pointer' word" is a defect of the printed page — both confirmed on images/page-151.png, which is also the page the 90.02 conversion note misdates as PDF p.153). *Inference from code shape, not a stated rule:* four properties of that mechanism make COLLATE COM look comparison-only at object time. (i) The collate switch is a word of the *call site*, not a mode cell the routine interrogates, so it is fixed per comparison at compile time — precisely what per-section scoping requires ("limit the modal specification to a particular section … the mode of generation reverts to the normal mode at the end of the specified section", [J 02.06.17]) — and no communication cell listed in the appendix holds a collating mode ([J 90.02.08]–11, which run to monitor cells, date/time, move source/target pointers and overflow flags). (ii) The adjustment is made "before the comparison" inside a routine that has no target operand and only three exits, HIGH/EQUAL/LOW, so it can only re-rank operand characters transiently; stored records, buffers and files keep their 709 representation. (iii) Nothing else in the appendix mentions collation, translation or the 705 sequence: the MOVPAK alphabetic movers SYS)239–242 copy or insert characters with no translate step, and every figurative-constant fill takes its character from the generated code — blanks and zeros have dedicated routines ("This MOVPAK subroutine moves blanks to an alphabetic field", SYS)243; "…moves zeros to an alphabetic field", SYS)244), while HV compiles, as the sample shows, into SYS)245, "This MOVPAK subroutine moves characters to an alphabetic field. The second word contains 6 characters of the type to be moved" ([J 90.02.25]–26); J classes HV and LV as move source types alongside BL and ZE ([J 90.02.10]), but which routine carries LV is unrecorded — natively `0` and under COM blank are exactly the values SYS)244 and SYS)243 already provide, and the point is unaffected either way, since all three fills are given their character by the caller. (iv) SYS)161 is a Type 2 item, one of the "Subroutines contained on the system tape which are placed in core by the CT Loader as required by the particular object program being loaded" ([J 90.02.07]), so a program with no COM comparison never loads the table; and COLLATE leaves no trace outside generated instructions — the appendix on "Compiler Use of Environment Description Options in Generation of Loader Symbolic Control Cards" fills those cards "on the basis of options exercised on Environment FILE and SPECIF cards" only ([J 90.08.00]–02), the object-deck format defines no collating flag ([J 90.03]), the loader has no collate control card (J 03), COLLATE appears nowhere among the deferred features or restrictions ([J 90.01]), and the sole -OPTION- card diagnostic in the 210-message list is "-OPTION- CARD FORMAT ERROR." ([J 90.04.01] msg 3). The blast radius is further bounded by the comparison rules themselves — "Numeric fields are compared arithmetically without regard to length" and edited fields "are converted to pure numeric fields" for comparison, so neither can be affected, while "All non-format fields … are compared alphamerically" and therefore do fall under the mode ([J 02.04.07]) — and by the fact that neither manual defines a SORT verb or any other ordering operation a collating sequence could govern (the single occurrence of the word, "In sorting problems, a programmer may use many tapes", J 06.05.02, is about tape-channel assignment for sort *applications*). 

    **Still open:**   
    (a) what a COM comparison physically looks like — no compilation with an OPTION card survives (the sample's Environment Description carries only FILE and SPECIF cards, [J 90.05] listing, PDF p. 195), and under the default mode its alphameric comparisons, including the two `= HIGH.VALUE` sentinel tests, compile as an inline `CAL`/`LAS` three-way compare followed by a TRA decode, with CVR, SYS)161 and SYS)162 absent from the entire object listing ([J 90.05] listing, PDF pp. 198–216; compares at pp. 201–203), so whether COM forces such compares through SYS)162 or instead emits inline CVRs is unrecorded;   
    (b) the cross-mode question, since [J 02.04.01] words the HIGH.VALUE/LOW.VALUE rule program-wide ("specified in the Environment Description") while [J 02.06.17] lets COLLATE be scoped to one section — a sentinel planted as `9` inside a COM section and later compared under the native sequence is undefined (see open question 60);   
    (c) strictly, the evidence bounds the *object-time* footprint and cannot exclude a compile-time-only effect that leaves no runtime trace, which is what [J 02.06.02]'s broader wording would have to mean if it means anything more than 02.06.16 does. Recommended implementation: treat COLLATE COM as affecting exactly   
    (1) the ordering used by alphameric and non-format comparisons and   
    (2) the character value of HIGH.VALUE/LOW.VALUE wherever those constants are compiled, with no effect on stored representation, I/O, moves of other data, or arithmetic. ([J 02.04.01]; [J 02.04.02]; [J 02.04.07]; [J 02.06.02]; [J 02.06.16]–17; [J 90.01]; [J 90.02.07], 90.02.08–11, 90.02.10, 90.02.12, 90.02.25–26; [J 90.03]; [J 90.04.01] msg 3; [J 90.08.00]–02; [J 90.05] listing, PDF pp. 195–196, 198–216, 201–203, 216; images/page-151.png)
59. How is a COND (console-key) condition.name used syntactically — only as `IF condition.name`, or also with NOT and in compound conditions? ([J 02.06.17])
60. What happens when OPTION cards conflict (repeated global specifications, COLLATE COM mid-program without IN)? ([J 02.06.16]–17)
61. Is SPECIF UNIT2 meaningful for single-reel (non-MULTI) files? Its semantics are stated only for reel switching. ([J 02.06.08])
62. What happens when a GROUP lists a file absent from the named POOL, and may a file belong to more than one POOL or GROUP? Only format errors are diagnosed. ([J 90.04.01] msgs 161–165)
63. What ordering constraints hold among Environment cards — must a FILE card precede SPECIF/POOL/GROUP cards referencing its file.name? (Only SPECIF's "may appear anywhere within the environment division" is stated, [J 02.06.07].)
64. What does the compiler do with a recognized-but-deferred construct (INCLUDE, COPY/LIBRARY, LOAD, OVERLAP, CONTRL) beyond the diagnostic — is the statement skipped, and does it consume a statement number? ([J 90.04.01] msgs 108, 110, 176)
65. What actual severity (1–5) does each of the 210 messages carry? The listing prints 0 throughout; no assignment table survives. ([J 90.04.01])
66. Does a severity 2–4 error make the punched object deck unreliable, or merely suppress automatic execution? ([J 02.01.01] says only severity 5 suppresses the deck.)
67. What limit triggers msg 200 (variable-length fields) — is it the 25-item QUANTITY IN table or a distinct counter? ([J 90.04.01]; [J 90.01.05] e)
68. Are shorter-than-12-digit COND key settings legal (padded) or an error? ([J 90.04.01] msg 6; [J 02.06.17])
69. What is STOP n's restart behaviour on the field-test processor — does it preserve [F p. 54]'s resume-with-next-command semantics? ([J 05.06.04])
70. What was the *COMPILE card's full option set in the 1961 system, and when was it renamed $CMPLE? ([J 90.05] listing PDF p. 192; [J 02.01.01]) 

    **Narrowed (90.05 listing evidence, 2026-08-01; scan-verified 2026-08-02):** the Oct 18 1961 run compiled under `*COMPILE LIST` — verified glyph by glyph at 400 dpi — with identification field `CT PUBLICATIONS`, which reappears on the `*CTEXT` and `*CTEND` loader cards. Column measurement puts LIST at card column ≈16 and the identification at ≈55 on all three cards, i.e. the same option and secondary.identifier columns the 1962 $CMPLE card uses, so those two fields' mechanics carry over ([J 02.01.01] for the option set and for the identifier on *CTEND; [J 03.02.09] for the identifier on *CTEXT as well, which 02.01.01 does not mention). The verb field does not carry over: `*COMPILE` occupies columns 7-14, so the 1961 card cannot have held deck.name in $CMPLE's columns 8-13; a three-letter token `CTC` prints at columns ≈1-3 on the print line immediately below the card image and is probably that deck.name, but since it prints on a separate line this is unresolved. The full 1961 option set remains unrecovered — LIST is the only option observable. The rename is bounded by the two artifacts alone: *COMPILE in use on the 18 Oct 1961 run, $CMPLE documented in the Jan 1962 manual — a bracketing inference that assumes the reprinted listing is contemporaneous with its printed date and that the two forms did not coexist. ([J 90.05] listing, PDF pp. 192, 198, 216; [J 02.01.01]; [J 03.02.09]; images/page-192.png, page-198.png, page-216.png)

### Sample-program loose ends

71. What do non-zero clause digits in statement numbers (e.g. 219,03) look like in a real error listing? The sample compiles clean, so only ,00 forms appear. ([J 02.02.01]; [J 90.05])
72. What was the MASTER field TRIGGERS (pictorial AAA) for? Declared, pads NAME to a word boundary, never referenced — presumably reserved switch positions. ([J 90.05] listing PDF p. 192) 

    **Narrowed (90.05 listing evidence, 2026-08-01; adversarially re-verified against page renders, 2026-08-02):** `TRIGGERS` occurs exactly once in the surviving corpus — its declaration `7,00 71204 TRIGGERS 2 AAA`, level 2, a sibling of DAT and RATE rather than a member of DAT ([J 90.05] listing, PDF p. 192; verified on the page render) — and appears nowhere in the object listing (PDF pp. 198-216) nor anywhere in the source Procedure Division. Its allocation is not *printed* — MASTER is a locate-mode record, so its fields surface only as displacements from BL)2 — but it is fixed by arithmetic and independently confirmed by those displacements: DAT = EMPLOYEE.NUMBER (AA + AAAA = 6 characters) + NAME A(15) = 21 characters, TRIGGERS' AAA carries that to 24 = exactly 4 words, and the object code's MASTER displacements (`1)DATE,1` word 5, `EXEMPTIONS,1` 6, `1)FICA,1` 10, `1)WHT,1` 11, `1)BONDEDUCTION,1` 12, `BONDACCUMULATION,1` 13, `1)BONDENOMINATION,1` 14) reproduce exactly the layout that follows, totalling the 15 words the program reads and writes (`IOCTN* BL)2,,15`; `IOST MASTER,,15`). TRIGGERS therefore occupies characters 22-24 = bytes 3-5 of word 3, and is precisely the padding that word-aligns RATE. Two qualifications on "never referenced":   
    (i) name-absence is strong but not formally conclusive — the constant pool does name its data pointers symbolically (`CP)+37`-`+61` are all `PZE name,,byte`, PDF p. 216), so a move or arithmetic touching TRIGGERS would have surfaced the name there, yet the same pool also names storage by offset from a *different* symbol (`PZE RETPREM-2`, `PZE INSPREM-2`, `PZE 2)RATE+0`), so a reference need not carry a field's own name; what settles it is that TRIGGERS is absent from the source Procedure Division too, so no source construct can generate one — the nearest group move, statement 193,00 `MOVE MASTER DAT TO ERROROUT INFO`, is emitted as a 21-character move (`TXI SYS)240,1,21`, PDF p. 202), stopping exactly at the TRIGGERS boundary; (ii) the field's *bytes* are nevertheless transferred wholesale, since statement 208,00's `FILE MASTER` writes the entire 15-word record image from the input buffer (`LXA BL)2,4` / `SXA GN)089,4` / `GN)089 IOST MASTER,,15`, PDF p. 210) — on this locate-mode update-in-place file TRIGGERS is copied from input reel to output reel unchanged, never read and never set. The reserved-switch-positions reading stands, as inference. ([J 90.05] listing, PDF pp. 192, 195-196, 198-216; images/page-192.png, page-202.png, page-210.png, page-216.png)
73. Does the native 709 collating sequence place `(` (HIGH.VALUE) above the digits, as the sample's sentinel less-than routing requires? **Resolved (scan check, 2026-08-01): yes** — `(` is the final, highest character of the native sequence, above all letters and digits (independently verified on the page-050 scan); the sentinel idiom is sound. ([J 02.04.01]; [J 02.06.16]; images/page-050.png)
74. Was F's serial-number sequence-checking claim ever true of any processor, given J disclaims it and the sample deck carries no serials? ([F p. 37]; [J 02.03.01]; [J 90.05])
75. What construct used the group-3 key word THROUGH? It appears in J's Environment-conditional key-word list ([J 02.03.03]) but in no command form, option, or example in either manual; F does not list it. Possibly reserved for a planned range form that never shipped. ([J 02.03.03]; noted during the M1 reserved-word extraction, 2026-08-03)

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[F p. 2]: ../comtran-manuals/F28-8043/01-general-description.md#what-is-a-data-processing-system
[F p. 3]: ../comtran-manuals/F28-8043/01-general-description.md#communication-with-a-data-processing-machine
[F p. 7]: ../comtran-manuals/F28-8043/01-general-description.md#example-3
[F p. 8]: ../comtran-manuals/F28-8043/01-general-description.md#construction-of-the-commercial-translator-language
[F p. 12]: ../comtran-manuals/F28-8043/02-language-structure.md#underlying-principles
[F p. 13]: ../comtran-manuals/F28-8043/02-language-structure.md#verbs
[F p. 13–14]: ../comtran-manuals/F28-8043/02-language-structure.md#verbs
[F p. 14]: ../comtran-manuals/F28-8043/02-language-structure.md#data-names
[F p. 15]: ../comtran-manuals/F28-8043/02-language-structure.md#condition-names
[F p. 15–16]: ../comtran-manuals/F28-8043/02-language-structure.md#condition-names
[F pp. 15–16]: ../comtran-manuals/F28-8043/02-language-structure.md#condition-names
[F p. 16]: ../comtran-manuals/F28-8043/02-language-structure.md#compound-names
[F p. 17]: ../comtran-manuals/F28-8043/02-language-structure.md#placing-names-in-the-program
[F p. 18]: ../comtran-manuals/F28-8043/02-language-structure.md#constants
[F p. 18–19]: ../comtran-manuals/F28-8043/02-language-structure.md#constants
[F p. 19]: ../comtran-manuals/F28-8043/02-language-structure.md#numeric-literals
[F pp. 19–20]: ../comtran-manuals/F28-8043/02-language-structure.md#numeric-literals
[F p. 20]: ../comtran-manuals/F28-8043/02-language-structure.md#figurative-constants
[F pp. 20–24]: ../comtran-manuals/F28-8043/02-language-structure.md#figurative-constants
[F p. 21]: ../comtran-manuals/F28-8043/02-language-structure.md#arithmetic-expressions
[F pp. 21–22]: ../comtran-manuals/F28-8043/02-language-structure.md#arithmetic-expressions
[F p. 21–24]: ../comtran-manuals/F28-8043/02-language-structure.md#arithmetic-expressions
[F pp. 21–24]: ../comtran-manuals/F28-8043/02-language-structure.md#arithmetic-expressions
[F p. 22]: ../comtran-manuals/F28-8043/02-language-structure.md#relations
[F p. 23]: ../comtran-manuals/F28-8043/02-language-structure.md#condition-names-1
[F pp. 23–24]: ../comtran-manuals/F28-8043/02-language-structure.md#condition-names-1
[F p. 24]: ../comtran-manuals/F28-8043/02-language-structure.md#and-or-and-not
[F p. 25]: ../comtran-manuals/F28-8043/02-language-structure.md#clauses
[F p. 26]: ../comtran-manuals/F28-8043/02-language-structure.md#sentences
[F p. 27]: ../comtran-manuals/F28-8043/02-language-structure.md#divisions
[F p. 27–28]: ../comtran-manuals/F28-8043/02-language-structure.md#divisions
[F p. 28]: ../comtran-manuals/F28-8043/02-language-structure.md#punctuation-and-spacing
[F p. 29]: ../comtran-manuals/F28-8043/02-language-structure.md#lists-tables-and-subscripts
[F p. 30]: ../comtran-manuals/F28-8043/02-language-structure.md#lists-tables-and-subscripts
[F p. 30–31]: ../comtran-manuals/F28-8043/02-language-structure.md#lists-tables-and-subscripts
[F p. 31]: ../comtran-manuals/F28-8043/02-language-structure.md#subscripts
[F p. 32]: ../comtran-manuals/F28-8043/02-language-structure.md#subscripts
[F p. 32–33]: ../comtran-manuals/F28-8043/02-language-structure.md#subscripts
[F p. 32–34]: ../comtran-manuals/F28-8043/02-language-structure.md#subscripts
[F p. 33]: ../comtran-manuals/F28-8043/02-language-structure.md#functions
[F p. 33–34]: ../comtran-manuals/F28-8043/02-language-structure.md#functions
[F pp. 33–34]: ../comtran-manuals/F28-8043/02-language-structure.md#functions
[F p. 34]: ../comtran-manuals/F28-8043/02-language-structure.md#functions
[F p. 35]: ../comtran-manuals/F28-8043/03-procedure-description.md#chapter-3-procedure-description
[F p. 37]: ../comtran-manuals/F28-8043/03-procedure-description.md#commands
[F p. 38]: ../comtran-manuals/F28-8043/03-procedure-description.md#identification-col-73-80
[F p. 39]: ../comtran-manuals/F28-8043/03-procedure-description.md#inputoutput-commands
[F pp. 39–40]: ../comtran-manuals/F28-8043/03-procedure-description.md#inputoutput-commands
[F pp. 39–41]: ../comtran-manuals/F28-8043/03-procedure-description.md#inputoutput-commands
[F p. 40]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-get-command
[F pp. 40–41]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-get-command
[F p. 41]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-file-command
[F p. 42]: ../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F p. 42–43]: ../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F pp. 42–43]: ../comtran-manuals/F28-8043/03-procedure-description.md#data-transmission-commands
[F p. 43]: ../comtran-manuals/F28-8043/03-procedure-description.md#editing-feature
[F p. 44]: ../comtran-manuals/F28-8043/03-procedure-description.md#editing-feature-1
[F pp. 44–46]: ../comtran-manuals/F28-8043/03-procedure-description.md#editing-feature-1
[F p. 45]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-set-command
[F p. 45–46]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-set-command
[F pp. 45–46]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-set-command
[F p. 46]: ../comtran-manuals/F28-8043/03-procedure-description.md#truth-functions
[F p. 47]: ../comtran-manuals/F28-8043/03-procedure-description.md#set-used-with-condition-names
[F p. 48]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-add-corresponding-command
[F pp. 48–49]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-add-corresponding-command
[F p. 49]: ../comtran-manuals/F28-8043/03-procedure-description.md#assigned
[F pp. 49–50]: ../comtran-manuals/F28-8043/03-procedure-description.md#assigned
[F p. 49–53]: ../comtran-manuals/F28-8043/03-procedure-description.md#assigned
[F pp. 49–53]: ../comtran-manuals/F28-8043/03-procedure-description.md#assigned
[F p. 50]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command
[F pp. 50–51]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command
[F p. 51]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-indexing
[F p. 52]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-indexing
[F pp. 52–53]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-indexing
[F p. 53]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-data-substitution
[F p. 54]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-named-end
[F pp. 54–55]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-named-end
[F pp. 54–56]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-do-command-with-named-end
[F p. 55]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-display-command
[F pp. 55–56]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-display-command
[F p. 56]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-overlap-command
[F pp. 56–57]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-overlap-command
[F p. 57]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-begin-section-and-end-commands
[F pp. 57–58]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-begin-section-and-end-commands
[F p. 58]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-begin-section-and-end-commands
[F p. 59]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-include-command
[F p. 60]: ../comtran-manuals/F28-8043/03-procedure-description.md#the-enter-command
[F p. 62]: ../comtran-manuals/F28-8043/04-data-description.md#the-purpose-of-a-data-description
[F p. 63]: ../comtran-manuals/F28-8043/04-data-description.md#files-records-and-fields
[F p. 63–64]: ../comtran-manuals/F28-8043/04-data-description.md#files-records-and-fields
[F pp. 63–64]: ../comtran-manuals/F28-8043/04-data-description.md#files-records-and-fields
[F p. 64]: ../comtran-manuals/F28-8043/04-data-description.md#files
[F p. 65]: ../comtran-manuals/F28-8043/04-data-description.md#data-description-format
[F p. 65–67]: ../comtran-manuals/F28-8043/04-data-description.md#data-description-format
[F p. 66]: ../comtran-manuals/F28-8043/04-data-description.md#ctl-and-serial-col-1-6
[F p. 67]: ../comtran-manuals/F28-8043/04-data-description.md#ctl-and-serial-col-1-6
[F p. 67–68]: ../comtran-manuals/F28-8043/04-data-description.md#ctl-and-serial-col-1-6
[F p. 68]: ../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F p. 69]: ../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F p. 70–71]: ../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F p. 71]: ../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F p. 71–72]: ../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F pp. 71–72]: ../comtran-manuals/F28-8043/04-data-description.md#level-col-23-24
[F p. 72]: ../comtran-manuals/F28-8043/04-data-description.md#cond
[F pp. 72–73]: ../comtran-manuals/F28-8043/04-data-description.md#cond
[F p. 73]: ../comtran-manuals/F28-8043/04-data-description.md#funct
[F pp. 73]: ../comtran-manuals/F28-8043/04-data-description.md#funct
[F p. 73–76]: ../comtran-manuals/F28-8043/04-data-description.md#funct
[F p. 74]: ../comtran-manuals/F28-8043/04-data-description.md#redef
[F pp. 74–75]: ../comtran-manuals/F28-8043/04-data-description.md#redef
[F p. 75]: ../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 75–76]: ../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 76]: ../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 76–77]: ../comtran-manuals/F28-8043/04-data-description.md#tables
[F pp. 76–77]: ../comtran-manuals/F28-8043/04-data-description.md#tables
[F p. 77]: ../comtran-manuals/F28-8043/04-data-description.md#copy
[F p. 77–78]: ../comtran-manuals/F28-8043/04-data-description.md#copy
[F p. 78]: ../comtran-manuals/F28-8043/04-data-description.md#quantity-col-31-35
[F p. 78–79]: ../comtran-manuals/F28-8043/04-data-description.md#quantity-col-31-35
[F p. 79]: ../comtran-manuals/F28-8043/04-data-description.md#justify-col-37
[F p. 80]: ../comtran-manuals/F28-8043/04-data-description.md#format-characters
[F pp. 80–81]: ../comtran-manuals/F28-8043/04-data-description.md#format-characters
[F p. 81]: ../comtran-manuals/F28-8043/04-data-description.md#format-characters
[F p. 82–83]: ../comtran-manuals/F28-8043/04-data-description.md#library-names
[F p. 83]: ../comtran-manuals/F28-8043/04-data-description.md#quantities-specified-in-named-fields
[F p. 84]: ../comtran-manuals/F28-8043/04-data-description.md#quantities-specified-in-named-fields
[F p. 84–85]: ../comtran-manuals/F28-8043/04-data-description.md#quantities-specified-in-named-fields
[F pp. 84–85]: ../comtran-manuals/F28-8043/04-data-description.md#quantities-specified-in-named-fields
[F p. 85]: ../comtran-manuals/F28-8043/04-data-description.md#storage-areas
[F p. 87]: ../comtran-manuals/F28-8043/a1-programming-example.md#appendix-1-programming-example
[F pp. 87–104]: ../comtran-manuals/F28-8043/a1-programming-example.md#appendix-1-programming-example
[F p. 91]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F pp. 91–92]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F pp. 91–93]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F pp. 91–94]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F p. 92]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F pp. 92–94]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F p. 93]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F p. 94]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F p. 95]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F pp. 95–96]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F p. 98]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F p. 100]: ../comtran-manuals/F28-8043/a1-programming-example.md#flow-chart--payroll-example
[F pp. 101–104]: ../comtran-manuals/F28-8043/a1-programming-example.md#sample-payroll-program---machine-listing
[F pp. 103–104]: ../comtran-manuals/F28-8043/a1-programming-example.md#sample-payroll-program---machine-listing
[F p. 104]: ../comtran-manuals/F28-8043/a1-programming-example.md#sample-payroll-program---machine-listing
[F p. 105]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#appendix-2-supplementary-information
[F p. 105–106]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#appendix-2-supplementary-information
[F p. 105–107]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#appendix-2-supplementary-information
[F p. 106]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#rules-for-forming-conditional-expressions
[F p. 107]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#rules-for-forming-arithmetic-expressions
[F p. 108]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#rules-for-forming-arithmetic-expressions
[F pp. 108–109]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#rules-for-forming-arithmetic-expressions
[F p. 109]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#list-of-commercial-translator-commands
[F p. 110]: ../comtran-manuals/F28-8043/a2-supplementary-information.md#list-of-commercial-translator-commands
[F p. 111]: ../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[F pp. 111–116]: ../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[F p. 112]: ../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[F p. 113]: ../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[F p. 115]: ../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[F pp. 115–116]: ../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[F p. 116]: ../comtran-manuals/F28-8043/a3-glossary.md#appendix-3-glossary
[J 01.01.01]: ../comtran-manuals/J28-6169/01-documentation.md#introduction
[J 02.00]: ../comtran-manuals/J28-6169/02-compiler.md#0200-introduction
[J 02.00.00]: ../comtran-manuals/J28-6169/02-compiler.md#section-02-compiler
[J 02.01]: ../comtran-manuals/J28-6169/02-compiler.md#0201-compiler-control-cards
[J 02.01.01]: ../comtran-manuals/J28-6169/02-compiler.md#0200-introduction
[J 02.01.02]: ../comtran-manuals/J28-6169/02-compiler.md#a-cmple-card
[J 02.02]: ../comtran-manuals/J28-6169/02-compiler.md#0202-compiler-output
[J 02.02.01]: ../comtran-manuals/J28-6169/02-compiler.md#b-finish-card
[J 02.03.01]: ../comtran-manuals/J28-6169/02-compiler.md#0202-compiler-output
[J 02.03.02]: ../comtran-manuals/J28-6169/02-compiler.md#a-use-of-coding-forms
[J 02.03.03]: ../comtran-manuals/J28-6169/02-compiler.md#b-key-words
[J 02.03.03.01]: ../comtran-manuals/J28-6169/02-compiler.md#d-effect-of-data-storage-mode-on-arithmetic-efficiency
[J 02.04]: ../comtran-manuals/J28-6169/02-compiler.md#0204-procedure-description-clarification-and-amplification
[J 02.04.01]: ../comtran-manuals/J28-6169/02-compiler.md#d-effect-of-data-storage-mode-on-arithmetic-efficiency
[J 02.04.02]: ../comtran-manuals/J28-6169/02-compiler.md#1-figurative-constants
[J 02.04.02.01]: ../comtran-manuals/J28-6169/02-compiler.md#2-literals
[J 02.04.03]: ../comtran-manuals/J28-6169/02-compiler.md#2-display
[J 02.04.04]: ../comtran-manuals/J28-6169/02-compiler.md#3-move
[J 02.04.05]: ../comtran-manuals/J28-6169/02-compiler.md#4-corresponding-option-with-move-and-add
[J 02.04.05.01]: ../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.06]: ../comtran-manuals/J28-6169/02-compiler.md#6-set
[J 02.04.07]: ../comtran-manuals/J28-6169/02-compiler.md#c-conditional-statements
[J 02.04.07.01]: ../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05]: ../comtran-manuals/J28-6169/02-compiler.md#0205-data-description-amplification-and-clarification
[J 02.05.01]: ../comtran-manuals/J28-6169/02-compiler.md#d-subscripting-and-indexing
[J 02.05.02]: ../comtran-manuals/J28-6169/02-compiler.md#1-record
[J 02.05.03]: ../comtran-manuals/J28-6169/02-compiler.md#3-redef-see-iii-under-data-description-on-page-900103-for-limitation
[J 02.05.04]: ../comtran-manuals/J28-6169/02-compiler.md#6-param-and-funct
[J 02.05.05]: ../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.06]: ../comtran-manuals/J28-6169/02-compiler.md#1-pictorials
[J 02.05.07]: ../comtran-manuals/J28-6169/02-compiler.md#2-constants
[J 02.06]: ../comtran-manuals/J28-6169/02-compiler.md#0206-environment-description
[J 02.06.01.01]: ../comtran-manuals/J28-6169/02-compiler.md#4-blank-when-zero
[J 02.06.01.02]: ../comtran-manuals/J28-6169/02-compiler.md#b-environment-types
[J 02.06.02]: ../comtran-manuals/J28-6169/02-compiler.md#b-environment-types
[J 02.06.03]: ../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.04]: ../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.05]: ../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.06]: ../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.07]: ../comtran-manuals/J28-6169/02-compiler.md#c-file-environment-card
[J 02.06.08]: ../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.09]: ../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.10]: ../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.11]: ../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.12]: ../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.13]: ../comtran-manuals/J28-6169/02-compiler.md#d-specif-environment-card
[J 02.06.14]: ../comtran-manuals/J28-6169/02-compiler.md#f-group-environment-card
[J 02.06.15]: ../comtran-manuals/J28-6169/02-compiler.md#f-group-environment-card
[J 02.06.16]: ../comtran-manuals/J28-6169/02-compiler.md#g-contrl-environment-card
[J 02.06.17]: ../comtran-manuals/J28-6169/02-compiler.md#h-option-environment-cards
[J 02.07]: ../comtran-manuals/J28-6169/02-compiler.md#0207-inputoutput-facilities-of-the-7097090-commercial-translator
[J 02.07.01]: ../comtran-manuals/J28-6169/02-compiler.md#i-cond-environment-card
[J 02.07.02]: ../comtran-manuals/J28-6169/02-compiler.md#3-the-block
[J 02.07.03]: ../comtran-manuals/J28-6169/02-compiler.md#5-locate-and-transmit
[J 02.07.04]: ../comtran-manuals/J28-6169/02-compiler.md#6-record-types
[J 02.07.05]: ../comtran-manuals/J28-6169/02-compiler.md#1-factors-affecting-choice-and-use-of-locate-or-transmit-mode
[J 02.07.06]: ../comtran-manuals/J28-6169/02-compiler.md#2-end-of-file-processing
[J 02.07.07]: ../comtran-manuals/J28-6169/02-compiler.md#3-input-error-processing
[J 02.07.08]: ../comtran-manuals/J28-6169/02-compiler.md#1-forms-of-the-command
[J 02.07.09]: ../comtran-manuals/J28-6169/02-compiler.md#1-non-standard-variable-length-input-records
[J 02.07.11]: ../comtran-manuals/J28-6169/02-compiler.md#c-problem-explanation
[J 02.07.12]: ../comtran-manuals/J28-6169/02-compiler.md#c-problem-explanation-1
[J 02.07.13]: ../comtran-manuals/J28-6169/02-compiler.md#c-explanation-of-problem
[J 02.07.14]: ../comtran-manuals/J28-6169/02-compiler.md#b-illustration-of-tape-3
[J 02.08]: ../comtran-manuals/J28-6169/02-compiler.md#0208-the-7097090-machine-symbolic-language---crypt
[J 02.08.01]: ../comtran-manuals/J28-6169/02-compiler.md#c-explanation-of-problem-1
[J 02.08.02]: ../comtran-manuals/J28-6169/02-compiler.md#b-crypt-rules
[J 02.08.03]: ../comtran-manuals/J28-6169/02-compiler.md#c-flexibility-above-that-of-scat
[J 03.02]: ../comtran-manuals/J28-6169/03-loader.md#0302-loader-control-cards
[J 03.02.05]: ../comtran-manuals/J28-6169/03-loader.md#d-spec-card
[J 03.02.08]: ../comtran-manuals/J28-6169/03-loader.md#h-retains-card
[J 03.02.09]: ../comtran-manuals/J28-6169/03-loader.md#j-start-card
[J 04.02]: ../comtran-manuals/J28-6169/04-monitor-and-supervisor.md#0402-function-of-the-commercial-translator-supervisor---ctm
[J 04.02.01]: ../comtran-manuals/J28-6169/04-monitor-and-supervisor.md#-card
[J 05.03]: ../comtran-manuals/J28-6169/05-systems-operation.md#0503-system-set-up-procedure
[J 05.03.01]: ../comtran-manuals/J28-6169/05-systems-operation.md#0502-peripheral-equipment-assignment
[J 05.03.02]: ../comtran-manuals/J28-6169/05-systems-operation.md#a-preparing-the-system-input----sysin1-and-sysin2
[J 05.04]: ../comtran-manuals/J28-6169/05-systems-operation.md#0504-system-restart-procedure
[J 05.06.01]: ../comtran-manuals/J28-6169/05-systems-operation.md#d-file-maintenance
[J 05.06.04]: ../comtran-manuals/J28-6169/05-systems-operation.md#b-loader-1
[J 90.01]: ../comtran-manuals/J28-6169/06-systems-maintenance.md#appendix-9001
[J 90.01.01]: ../comtran-manuals/J28-6169/90.01-deferred-features.md#appendix-9001-deferred-features-restrictions-and-limitations
[J 90.01.02]: ../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.03]: ../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.04]: ../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.01.05]: ../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02]: ../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.02.00]: ../comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002-generated-code
[J 90.02.01]: ../comtran-manuals/J28-6169/90.02-generated-code.md#introduction
[J 90.02.02]: ../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.03]: ../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.04]: ../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.06]: ../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.07]: ../comtran-manuals/J28-6169/90.02-generated-code.md#symbolic-listing
[J 90.02.08]: ../comtran-manuals/J28-6169/90.02-generated-code.md#ct-system-subroutines-and-communication-cells
[J 90.02.10]: ../comtran-manuals/J28-6169/90.02-generated-code.md#ioc-reference-numbers
[J 90.02.11]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.11.01]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.12]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.13]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.14]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.15]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.16]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.17]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.18]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.24]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.25]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.26]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.27]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.28]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.29]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.30]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.32]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.02.33]: ../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.03]: ../comtran-manuals/J28-6169/90.03-object-deck-format.md#appendix-9003
[J 90.03.03]: ../comtran-manuals/J28-6169/90.03-object-deck-format.md#3-file-check-entry-specifications
[J 90.03.04]: ../comtran-manuals/J28-6169/90.03-object-deck-format.md#1-format
[J 90.04]: ../comtran-manuals/J28-6169/90.04-error-messages.md#appendix-9004
[J 90.04.01]: ../comtran-manuals/J28-6169/90.04-error-messages.md#error-messages-and-severity-codes
[J 90.04.02]: ../comtran-manuals/J28-6169/90.04-error-messages.md#a-error-messages
[J 90.05]: ../comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
[J 90.05.00]: ../comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005-sample-program
[J 90.05.01]: ../comtran-manuals/J28-6169/90.05-sample-program.md#introduction
[J 90.05.02]: ../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description
[J 90.05.03]: ../comtran-manuals/J28-6169/90.05-sample-program.md#1-data-description-1
[J 90.05.04]: ../comtran-manuals/J28-6169/90.05-sample-program.md#a-data-description
[J 90.08]: ../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008
[J 90.08.00]: ../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008-compiler-use-of-environment-descriptions-in-generation-of-loader-symbolic-control-cards
[J 90.08.01]: ../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#appendix-9008
[J 90.08.02]: ../comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md#a-the-file-card
