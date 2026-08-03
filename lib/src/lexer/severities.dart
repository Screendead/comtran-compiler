/// The severity table (decision D9.2) — all 210 catalog messages plus
/// our 900-series ids.
///
/// Per-message severity values are historically unrecoverable — the
/// 90.04 catalog prints code 0 throughout because "the value may vary"
/// (J 90.04.01; Open Question 65) — so EVERY value here is OUR
/// assignment, non-historical, made by the D9.2 consequence rule: the
/// consequence stated in the message's own text wins over its class
/// heading; inside classes 2-4, take the largest source unit whose
/// intended object code is lost. Classes: C1 advisory or auto-repair
/// = 1; C2 operand- or clause-level loss = 2; C3 statement- or
/// card-level loss = 3; C4 program-, file-, or record-level loss = 4;
/// C5 unrecoverable, internal, or capacity = 5.
///
/// Two sub-rules applied uniformly (both ours; review notes and the
/// full uncertain-call list in `docs/design/severity-notes.md`):
/// (1) the lost unit is the unit the message names, not the transitive
/// damage; (2) environment-card messages split by unit — whole card
/// C3, one option operand C2, whole-file or record property C4.
///
/// The compiler reads severities from this table only; no severity
/// constant appears in compiler code (D9.2). The build check that every
/// catalog id has exactly one row lives in `test/severities_test.dart`.
library;

/// Severity value per message id; every row is a non-historical D9.2
/// assignment with its class and deciding words.
const Map<String, int> messageSeverities = {
  // C5: Fallback row. "ERROR MESSAGE NOT YET IN FILE." — the table holds no
  // text for the requested id, an internal inconsistency (D9.15). Assigned
  // C5/5 by decision, not by text.
  '0,00': 5,
  // C3: "-FILE- CARD LACKS NAME IN COLUMNS 7 THROUGH 22." — the card cannot
  // bind; the whole card is lost.
  '1,00': 3,
  // C2: "-RUN- DELETED." — only the offending word is removed, not the
  // sentence.
  '2,00': 2,
  // C3: "-OPTION- CARD FORMAT ERROR." — the whole card is unusable.
  '3,00': 3,
  // C3: "-COND- CARD FORMAT ERROR." — the whole card is unusable.
  '4,00': 3,
  // C4: "-FILE- CARD MUST HAVE -SPANS-." — no repair stated; the file's
  // blocking is wrong, so the file's I/O cannot be generated.
  '5,00': 4,
  // C1: "RIGHTMOST 12 DIGITS USED." — the text states the repair (D9.16).
  '6,00': 1,
  // C1: "KEY SETTING '1' USED." — the text states the substitution (D9.16).
  '7,00': 1,
  // C3: "IS NEITHER A RECORD NOR A FILE." — the statement that names it
  // cannot be compiled.
  '8,00': 3,
  // C4: "RECORD 'NAME.2' MUST BE ON A -FILE- CARD." — the record has no
  // file, so all I/O for that record is lost.
  '9,00': 4,
  // C4: "MUST BE ON AN INPUT -FILE- CARD." — the record-to-file binding is
  // lost.
  '10,00': 4,
  // C4: "CANNOT BE ON MORE THAN ONE INPUT -FILE- CARD." — the record's file
  // binding is ambiguous.
  '11,00': 4,
  // C3: "INCORRECT USE OF -GET RECORD FROM-. CANNOT DETERMINE RECORD
  // LENGTH." — the statement is lost; the file stays well formed.
  '12,00': 3,
  // C4: "FILE LACKS RECORD NAME IN -FILE- CARD" — the file's record set is
  // incomplete; file-level.
  '13,00': 4,
  // C3: "INCORRECT USE OF -GET RECORD FROM-. 'NAME.1' IS NOT AN INPUT FILE."
  // — the statement is lost.
  '14,00': 3,
  // C4: Same text as 13 — the file's record set is incomplete; file-level.
  '15,00': 4,
  // C3: "'NAME.2' IS NOT A RECORD." — the referring statement is lost.
  '16,00': 3,
  // C4: "MUST BE RECORD NAME IN -FILE- CARD." — the FILE card's record list
  // is wrong; file-level.
  '17,00': 4,
  // C5: "ILLEGAL INTERNAL CONDITION. NOTHING DONE. POSSIBLE COMPILER ERROR."
  // — internal (D9.15 group a).
  '18,00': 5,
  // C4: "MUST BE ON AN OUTPUT -FILE- CARD." — the record-to-file binding is
  // lost.
  '19,00': 4,
  // C4: "BINARY DATA CANNOT BE OUTPUT ON BCD TAPE." — the file's mode is
  // wrong; the file cannot be written.
  '20,00': 4,
  // C3: "'NAME.1' IS NOT A FILE." — the referring statement is lost.
  '21,00': 3,
  // C3: "'NAME.1' IS NOT AN OUTPUT FILE." — the referring statement is lost.
  '22,00': 3,
  // C3: "INCORRECT USE OF -GET RECORD FROM-." — the statement is lost.
  '23,00': 3,
  // C5: "ILLEGAL INTERNAL CONDITION … POSSIBLE COMPILER ERROR." — internal
  // (D9.15 a).
  '24,00': 5,
  // C2: "OPERATION IGNORED" — D9.2 names this message as a C2 example.
  '25,00': 2,
  // C2: "OPERATION IGNORED BECAUSE 'NAME.1' IS ILLEGAL TRANSFER ADDRESS." —
  // same deciding words as 25.
  '26,00': 2,
  // C1: "DOWNSCALE GENERATED WHICH LOSES ALL SIGNIFICANT FIGURES." — the
  // code is generated; the message warns only.
  '27,00': 1,
  // C1: "BYPASSED. RESULT TAKEN TO BE ZERO." — the text states the repair.
  '28,00': 1,
  // C5: "ILLEGAL INTERNAL CONDITION … POSSIBLE COMPILER ERROR." — internal
  // (D9.15 a).
  '29,00': 5,
  // C2: "LACKS EXPLICIT SPECIFICATION OF ALL ARGUMENTS." — the function
  // reference is lost; same unit as 68, a D9.2 C2 example.
  '30,00': 2,
  // C2: "SUBSCRIPT VARIABLE 'NAME.1' MUST BE AN INTEGER." — the subscript
  // operand is lost.
  '31,00': 2,
  // C1: "'NAME.1' FORMAT USED." — the text states the substitution.
  '32,00': 1,
  // C1: "'NAME.1' FORMAT USED." — the text states the substitution.
  '33,00': 1,
  // C1: "'NAME.1' FORMAT USED." — the text states the substitution.
  '34,00': 1,
  // C1: "'NAME.1' FORMAT USED." — the text states the substitution.
  '35,00': 1,
  // C3: "CANNOT HAVE SUB-ORGANIZATION." — no repair stated; the entry and
  // its subordinate entries are lost.
  '36,00': 3,
  // C1: "'NAME.1' FORMAT USED." — the text states the substitution.
  '37,00': 1,
  // C2: "CONDITIONAL VARIABLE CANNOT HAVE -QUANTITY-." — the QUANTITY clause
  // is rejected.
  '38,00': 2,
  // C2: "CANNOT BE SPECIFIED AS RIGHT JUSTIFIED." — the justification
  // attribute is rejected; unlike 190, this text states no repair.
  '39,00': 2,
  // C3: "-REDEF- TO 'NAME.1' CANNOT OCCUR BEFORE DEFINITION." — the entry
  // cannot be allocated.
  '40,00': 3,
  // C3: "NAME ASSOCIATED WITH -REDEF- OR -QUANTITY IN- IS UNDEFINED." — the
  // entry cannot be allocated.
  '41,00': 3,
  // C3: "DATA ITEM WITHOUT LENGTH." — the entry gets no storage.
  '42,00': 3,
  // C2: "CONSTANT CANNOT BE ASSOCIATED WITH -REDEF- OR INPUT RECORD" — the
  // constant operand is rejected.
  '43,00': 2,
  // C1: "ASSUMED TO BE 1 FOR STORAGE ALLOCATION." — D9.2 names this as a C1
  // example.
  '44,00': 1,
  // C3: "CANNOT BE ASSOCIATED WITH -REDEF- OR -QUANTITY IN-." — the entry
  // cannot be allocated.
  '45,00': 3,
  // C3: "CANNOT BE ASSOCIATED WITH -REDEF- OR -QUANTITY IN-." — the entry
  // cannot be allocated.
  '46,00': 3,
  // C3: "CANNOT BE ASSOCIATED WITH -QUANTITY IN-." — the entry cannot be
  // allocated.
  '47,00': 3,
  // C2: "NO RECORDS SPECIFIED IN -PATTERN- ON -FILE- CARD" — the PATTERN
  // clause of the card is lost. Disposition "reserved until D6" (D9.12).
  '48,00': 2,
  // C1: "INEFFICIENT PROGRAM PRODUCED." — the program is produced. D9.11
  // fixes severity 1; criterion attested.
  '49,00': 1,
  // C2: "NUMBER OF RECORDS IN -PATTERN- CANNOT EXCEED 16." — the PATTERN
  // clause is lost. Reserved until D6 (D9.12).
  '50,00': 2,
  // C2: "CONFLICT BETWEEN LENGTH OF CONSTANT AND PICTORIAL" — the constant
  // operand is lost.
  '51,00': 2,
  // C2: "MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL." — the
  // literal operand is lost.
  '52,00': 2,
  // C2: "INCORRECT USAGE OF PERIOD, SIGN, OR F FOR CONSTANT OR LITERAL." —
  // the literal operand is lost.
  '53,00': 2,
  // C2: "ILLEGAL CHARACTER FOR CONSTANT OR LITERAL." — the literal operand
  // is lost.
  '54,00': 2,
  // C2: "FLOATING POINT OVERFLOW IN CONVERTING CONSTANT OR LITERAL." — the
  // converted constant is lost.
  '55,00': 2,
  // C2: "FLOATING POINT UNDERFLOW IN CONVERTING CONSTANT OR LITERAL." — the
  // converted constant is lost.
  '56,00': 2,
  // C2: "CONSTANT CANNOT BE GIVEN FOR EDITED TYPE FIELD." — the constant
  // operand is rejected.
  '57,00': 2,
  // C2: "CONSTANT OF EXTERNAL DECIMAL TYPE IN ERROR." — the constant operand
  // is lost.
  '58,00': 2,
  // C2: "CONFLICT BETWEEN LENGTH OF ALPHABETIC CONSTANT AND PICTORIAL." —
  // the constant operand is lost.
  '59,00': 2,
  // C1: "ZERO COUNT IN PICTORIAL REPLACED BY ONE." — D9.2 names this as a C1
  // example.
  '60,00': 1,
  // C3: "OPERATION DEFINED AS NAME OR FOUND IN NAME FIELD." — the sentence's
  // name and verb structure fails.
  '61,00': 3,
  // C1: "PERIOD ASSUMED." — the compiler repairs and carries on (D9.4).
  '62,00': 1,
  // C3: "NEITHER -ADD- NOR -MOVE- PRECEDES -CORRESPONDING-" — the statement
  // has no verb; the sentence is lost.
  '63,00': 3,
  // C3: "CANNOT -END- SECTION WHEN NONE ARE OPEN." — the stray END sentence
  // is dropped; the section structure is unchanged.
  '64,00': 3,
  // C4: "CANNOT -END- SECTION 'NAME.1' BEFORE SECTION 'NAME.2'." — the
  // section nesting cannot be resolved; section-level.
  '65,00': 4,
  // C4: "ONE OR MORE SECTIONS NOT CLOSED." — D9.2 names this as a C4
  // example.
  '66,00': 4,
  // C2: "ILLEGAL NON-NUMERIC CHARACTER IN THE NUMERIC FIELD." — the field's
  // value is lost.
  '67,00': 2,
  // C2: "EVALUATION IGNORED" — D9.2 names this as a C2 example.
  '68,00': 2,
  // C5: "ILLEGAL INTERNAL CODE 'NAME.1' SENT TO ASSEMBLY. POSSIBLE COMPILER
  // ERROR." — internal (D9.15 a).
  '69,00': 5,
  // C2: "CHECK ARRAY OF ELEMENTS … FOR NUMBER OF DIMENSIONS." — the
  // subscripted reference is lost.
  '70,00': 2,
  // C2: "INVALID FORMAT FOR SUBSCRIPT VARIABLE IN ARRAY OF ELEMENTS" — the
  // reference is lost.
  '71,00': 2,
  // C3: "TOO MANY -USING- PARAMETERS IN -DO- STATEMENT." — the DO statement
  // cannot link.
  '72,00': 3,
  // C3: "TOO FEW -USING- PARAMETERS IN -DO- STATEMENT." — the DO statement
  // cannot link.
  '73,00': 3,
  // C3: "TOO MANY -GIVING- PARAMETERS IN -DO- STATEMENT" — the DO statement
  // cannot link.
  '74,00': 3,
  // C3: "TOO FEW -GIVING- PARAMETERS IN -DO- STATEMENT" — the DO statement
  // cannot link.
  '75,00': 3,
  // C3: "FORMAT ERROR FOR LOOP CONTROL VARIABLE" — the loop cannot be
  // generated; the statement is lost.
  '76,00': 3,
  // C3: "FORMAT ERROR FOR PARAMETER 'NAME.1' OF LOOP CONTROL VARIABLE." —
  // the loop cannot be generated.
  '77,00': 3,
  // C3: "FORMAT ERROR FOR LITERAL PARAMETER OF LOOP CONTROL VARIABLE" — the
  // loop cannot be generated.
  '78,00': 3,
  // C2: "SUBSCRIPT VARIABLE 'NAME.1' MUST BE OF NUMERIC TYPE." — the
  // subscript operand is lost.
  '79,00': 2,
  // C2: "CONFLICT BETWEEN JUSTIFICATION AS GIVEN BY ORIGINAL DEFINITION AND
  // -REDEF-." — one attribute is lost.
  '80,00': 2,
  // C3: "CONFLICT BETWEEN LEVEL … AND -REDEF-." — without a level the entry
  // has no place in the hierarchy; same unit as 194.
  '81,00': 3,
  // C2: "INCORRECT USAGE OF FIGURATIVE CONSTANT." — the constant operand is
  // rejected.
  '82,00': 2,
  // C3: "INVALID FORM OF -DO- STATEMENT." — the statement is lost.
  '83,00': 3,
  // C3: "ILLEGAL MOVE … NOTHING DONE ." — D9.2 names this as a C3 example.
  '84,00': 3,
  // C5: "PERMANENT READ ERROR IN PHASE 2. COMPILATION SUSPECT." Text implies
  // the compilation continued, but §8.5.7 groups read errors at 5 and D9.2
  // keeps 5. Unreachable by construction, D9.15, so the value is never
  // exercised.
  '85,00': 5,
  // C1: "DIFFICULT TO PROGRAM KEY SETTING." — advisory only. D9.11 fixes
  // severity 1; criterion invented.
  '86,00': 1,
  // C4: "PROBABLE PROGRAM CONTINUITY ERROR. PROGRAM FLOWS INTO *DATA." —
  // D9.2 C4 example.
  '87,00': 4,
  // C3: "-COND- CARD LACKS NAME IN COLUMNS 7 THROUGH 22." — the card cannot
  // bind.
  '88,00': 3,
  // C3: "-FILE- CARD FORMAT ERROR." — the whole card is unusable.
  '89,00': 3,
  // C4: "NOT YET PROCESSED BY COMPILER." — deferred construct; D9.8 fixes
  // severity 4. No B.2 row (D9.3).
  '90,00': 4,
  // C2: "NUMERIC INTEGER MUST FOLLOW -BLOCKSIZE- IN THE -FILE- CARD." — one
  // card option operand is lost.
  '91,00': 2,
  // C2: "STATEMENT OR SECTION NAME MUST FOLLOW -ONERROR-" — one card option
  // operand is lost.
  '92,00': 2,
  // C2: "STATEMENT OR SECTION NAME MUST FOLLOW -FORLABEL-" — one card option
  // operand is lost.
  '93,00': 2,
  // C2: "DATA NAME MUST FOLLOW -PLACE LENGTH IN-" — one card option operand
  // is lost.
  '94,00': 2,
  // C2: "DATA NAME MUST FOLLOW -FIND LENGTH IN-" — one card option operand
  // is lost.
  '95,00': 2,
  // C3: "THERE IS AN ILLEGAL WORD IN THE -FILE- CARD." — the card cannot be
  // parsed.
  '96,00': 3,
  // C3: "INVALID -CORRESPONDING- STATEMENT." — the text names the statement.
  '97,00': 3,
  // C2: "CHECK DATA DESCRIPTION OF ARRAY OF ELEMENTS" — the subscripted
  // reference is lost; B.2 groups it with 70 and 71.
  '98,00': 2,
  // C4: "PROBABLE PROGRAM CONTINUITY ERROR." — D9.2 C4 example.
  '99,00': 4,
  // C2: "PICTORIAL WHICH EXCEEDS LEGAL LIMIT OF 30 CHARACTERS." — the
  // pictorial operand is lost.
  '100,00': 2,
  // C2: "'NAME.1' IS AN IMPROPERLY QUALIFIED NAME." — the name operand
  // cannot resolve.
  '101,00': 2,
  // C3: "NAME OF NUMERIC TYPE MUST FOLLOW -QUANTITY IN-." — the entry cannot
  // be allocated.
  '102,00': 3,
  // C3: "CANNOT BE -QUANTITY- ITEM." — the entry cannot be allocated.
  '103,00': 3,
  // C1: "MAY AFFECT POSITIONING ADVERSELY." — advisory only. D9.11 fixes
  // severity 1; criterion attested.
  '104,00': 1,
  // C3: "CANNOT FOLLOW VARIABLE FIELD WHICH DEPENDS ON THE -QUANTITY- ITEM
  // ITSELF." — the entry's association is lost.
  '105,00': 3,
  // C2: "STATEMENT OR SECTION NAME MUST FOLLOW -AT END-." — one card option
  // operand is lost.
  '106,00': 2,
  // C3: "ILLEGAL COMPARISON STRUCTURE." — the conditional sentence cannot
  // compile.
  '107,00': 3,
  // C4: "'NAME.1' IS AN UNDEFINED SYMBOL." — D9.2 C4 example; an undefined
  // symbol also blocks compile-and-go (J 02.01.02).
  '108,00': 4,
  // C5: "PROCESSOR UNABLE TO FIND VARIABLE USED AS SUBSCRIPT. POSSIBLE
  // COMPILER ERROR." — internal (D9.15 a).
  '109,00': 5,
  // C4: "-COPY- AND -LIBRARY- ARE NOT YET HANDLED BY SYSTEM." — D9.8 fixes
  // severity 4. No B.2 row (D9.3).
  '110,00': 4,
  // C2: "IMPROPER DATA FORMAT FOR THIS USE IN THE -FIND LENGTH IN- OPTION."
  // — one option operand is lost.
  '111,00': 2,
  // C2: "IMPROPER DATA FORMAT FOR THIS USE IN THE -PLACE LENGTH IN- OPTION."
  // — one option operand is lost.
  '112,00': 2,
  // C2: "REDUNDANT RIGHT PARENTHESIS ELIMINATED ." — D9.2 names this as a C2
  // example.
  '113,00': 2,
  // C2: "REDUNDANT LEFT PARENTHESIS." — same unit as 113.
  '114,00': 2,
  // C3: "INVALID MACHINE OPERATION." — the CRYPT instruction is lost; one
  // instruction is one statement.
  '115,00': 3,
  // C1: "MISSING OPERAND ASSUMED TO BE ZERO." — D9.2 names this as a C1
  // example.
  '116,00': 1,
  // C4: "SOME BUT NOT ALL OF THE RECORDS BELONGING TO THE FILE" — a file-
  // wide consistency property fails.
  '117,00': 4,
  // C4: "SOME BUT NOT ALL OF THE RECORDS BELONGING TO THE FILE" — a file-
  // wide consistency property fails.
  '118,00': 4,
  // C3: "INCOMPLETE -MOVE- EXPRESSION." — the MOVE statement is lost.
  '119,00': 3,
  // C2: "'NAME.1' ELIMINATED FROM ADD" — D9.2 names this as a C2 example.
  '120,00': 2,
  // C4: "SOME BUT NOT ALL OF THE RECORDS BELONGING TO THE FILE" — a file-
  // wide consistency property fails.
  '121,00': 4,
  // C3: "INCOMPLETE STATEMENT DELETED FROM TEXT." — D9.2 C3 example.
  '122,00': 3,
  // C3: "CANNOT USE VARIABLE LENGTH ITEMS FOR COMPARISON." — the comparison
  // sentence is lost.
  '123,00': 3,
  // C5: "ILLEGAL INTERNAL CONDITION … POSSIBLE COMPILER ERROR." — internal
  // (D9.15 a).
  '124,00': 5,
  // C3: "STATEMENT WITHOUT PROPER VERB DELETED FROM TEXT." — D9.2 C3
  // example.
  '125,00': 3,
  // C3: "STATEMENT WITH MORE THAN ONE VERB DELETED FROM TEXT." — D9.2 C3
  // example.
  '126,00': 3,
  // C2: "TRANSFER BYPASSED" — one clause is dropped; the same shape as 25
  // OPERATION IGNORED.
  '127,00': 2,
  // C2: "TRANSFER BYPASSED" — one clause is dropped.
  '128,00': 2,
  // C3: "FORMAT ERROR FOR TRANSFER INDEX. NOTHING DONE." — "NOTHING DONE"
  // makes the transfer statement the lost unit.
  '129,00': 3,
  // C1: "INTEGRAL PART TAKEN AS VALUE." — the text states the repair.
  '130,00': 1,
  // C3: "INVALID DISPLAY STATEMENT." — the text names the statement.
  '131,00': 3,
  // C5: "END OF FILE ON JOB TAPE WITHOUT *FINISH CARD." — D9.14 fixes
  // severity 5; the job has no terminator and no next job can exist.
  '132,00': 5,
  // C2: "NO RIGHT PARENTHESIS IN FORMAT PICTORIAL." — the pictorial operand
  // is lost.
  '133,00': 2,
  // C1: "REPLACED IN INTERNAL TEXT BY 0, AND IN EXTERNAL TEXT BY $." — the
  // text states the repair (D9.10).
  '134,00': 1,
  // C5: "PERMANENT READ ERROR FOR INPUT. DUBIOUS COMPILATION." Text implies
  // continuation; §8.5.7 and D9.2 keep 5. Unreachable, D9.15.
  '135,00': 5,
  // C5: "REDUNDANCY WHILE WRITING EXTERNAL DICTIONARY. DUBIOUS COMPILATION."
  // Unreachable, D9.15; same tension note as 135.
  '136,00': 5,
  // C5: "REDUNDANCY WHILE READING EXTERNAL DICTIONARY. DUBIOUS COMPILATION."
  // Unreachable, D9.15; same tension note as 135.
  '137,00': 5,
  // C3: "FILE NAME SHOULD FOLLOW -CLOSE-." — the CLOSE statement is lost.
  '138,00': 3,
  // C3: "FILE NAME SHOULD FOLLOW -OPEN-." — the OPEN statement is lost.
  '139,00': 3,
  // C5: "INTERNAL TEXT SYNCHRONIZATION FAILURE. DUBIOUS COMPILATION."
  // Unreachable, D9.15; same tension note as 135.
  '140,00': 5,
  // C1: "MORE THAN ONE -PROGRAM.START-. FIRST USED." — the text states the
  // repair.
  '141,00': 1,
  // C4: "-PROGRAM.START- MUST BE A STATEMENT OR SECTION NAME." — the
  // program's entry point is lost; whole-program property.
  '142,00': 4,
  // C4: "-PROGRAM.START- CANNOT BE … ADDRESSED BY A -DO-." — the program's
  // entry point is lost.
  '143,00': 4,
  // C3: "ILLEGAL ENVIRONMENT CARD TYPE." — the card is deleted (J
  // 02.06.01.01).
  '144,00': 3,
  // C3: "MISSING ADDRESS." — the CRYPT instruction cannot be assembled; no
  // repair stated.
  '145,00': 3,
  // C3: "MISSING TAG." — the CRYPT instruction cannot be assembled.
  '146,00': 3,
  // C3: "MISSING DECREMENT." — the CRYPT instruction cannot be assembled.
  '147,00': 3,
  // C5: "EXCEEDS INTERNAL TABLE CAPACITY AND SHOULD BE SUBDIVIDED." — a
  // capacity condition with no stated recovery; D9.2 lists it at 5.
  '148,00': 5,
  // C5: "NUMBER OF SECTIONS IN PROGRAM EXCEEDS INTERNAL TABLE CAPACITY." —
  // D9.2 lists it at 5 (D9.7 map: 35 sections).
  '149,00': 5,
  // C2: "ALPHABETIC LITERAL EXCEEDS 50 CHARACTERS." — the literal operand is
  // lost.
  '150,00': 2,
  // C4: "VFD IS NOT YET HANDLED BY SYSTEM." — deferred construct; D9.8 fixes
  // severity 4.
  '151,00': 4,
  // C1: "'NAME.1' SHOULD NOT BE USED AS DATA NAME." — "SHOULD NOT" is
  // advisory; the name is still used (compare 178).
  '152,00': 1,
  // C3: "-SPECIF- CARD FORMAT ERROR." — the whole card is unusable.
  '153,00': 3,
  // C3: "FILE NAME MUST BE FIRST ITEM IN VARIABLE FIELD." — without it the
  // SPECIF card cannot bind; whole card.
  '154,00': 3,
  // C2: "ALPHAMERIC LITERAL MUST FOLLOW -UNIT-." — one card option operand
  // is lost.
  '155,00': 2,
  // C2: "ALPHAMERIC LITERAL MUST FOLLOW -SERIAL-." — one card option operand
  // is lost.
  '156,00': 2,
  // C2: "ALPHAMERIC LITERAL MUST FOLLOW -REEL-." — one card option operand
  // is lost.
  '157,00': 2,
  // C2: "NUMERIC INTEGER MUST FOLLOW -RETAIN-." — one card option operand is
  // lost.
  '158,00': 2,
  // C2: "NUMERIC INTEGER MUST FOLLOW -ACTIVITY-." — one card option operand
  // is lost.
  '159,00': 2,
  // C2: "ALPHABETIC LITERAL … CANNOT EXCEED 6 CHARACTERS." — the literal
  // operand is rejected.
  '160,00': 2,
  // C3: "-POOL- CARD FORMAT ERROR." — the whole card is unusable.
  '161,00': 3,
  // C2: "NUMERIC INTEGER MUST FOLLOW -BLOCKSIZE- ON -POOL- CARD." — one card
  // option operand is lost.
  '162,00': 2,
  // C2: "NUMERIC INTEGER MUST FOLLOW -BUFFERCOUNT-." — one card option
  // operand is lost.
  '163,00': 2,
  // C3: "-GROUP- CARD FORMAT ERROR." — the whole card is unusable.
  '164,00': 3,
  // C2: "NUMERIC INTEGER MUST FOLLOW -OPENCOUNT-." — one card option operand
  // is lost.
  '165,00': 2,
  // C3: "'NAME.1' IS NOT UNIQUE IN THIS SECTION." — the duplicate definition
  // loses its binding; the entry is the lost unit.
  '166,00': 3,
  // C2: "SECOND QUOTE MARK MISSING." — the literal operand is lost.
  '167,00': 2,
  // C2: "ALPHABETIC LITERAL EXTENDS ACROSS CARDS." — the literal operand is
  // lost.
  '168,00': 2,
  // C4: "PROGRAM FLOWS INTO GENERATED CONSTANTS." — D9.2 C4 example.
  '169,00': 4,
  // C1: "-WHEN- SUBSTITUTED FOR -IF-" — the text states the repair. D9.11
  // fixes severity 1; criterion invented.
  '170,00': 1,
  // C3: "SENTENCE DELETED FROM TEXT." — D9.2 C3 example.
  '171,00': 3,
  // C5: "CONSTANT POOL OVERFLOW." — capacity, no stated recovery; D9.2 lists
  // it at 5 (D9.7 map: 500 constants).
  '172,00': 5,
  // C5: "REFERENCE MADE TO NON-EXISTENT SYSTEM GENERATED NAME." — internal
  // inconsistency; D9.13 fixes C5.
  '173,00': 5,
  // C1: "ZERO ASSUMED." — the text states the repair; D9.13 fixes C1.
  '174,00': 1,
  // C4: "NO -STOP RUN- IN PROGRAM." — D9.2 C4 example; a whole-program
  // property.
  '175,00': 4,
  // C3: "-CONTRL- CARD FORMAT ERROR." — the whole card is unusable. D9.8
  // states this is not a deferral.
  '176,00': 3,
  // C3: "SENTENCE DELETED FROM TEXT." — D9.2's worked example of the
  // precedence rule: the text beats the capacity heading.
  '177,00': 3,
  // C1: "INTERPRETED AS A DATA NAME." — the text states the interpretation.
  '178,00': 1,
  // C3: "-END- SECTION MUST BE THE ONLY CLAUSE IN THE SENTENCE." — the
  // sentence is malformed.
  '179,00': 3,
  // C4: "NOT YET HANDLED BY SYSTEM." — deferred construct; D9.8 fixes
  // severity 4.
  '180,00': 4,
  // C4: "NOT YET HANDLED BY SYSTEM." — deferred construct; D9.8 fixes
  // severity 4 (ceiling 32766, D9.9).
  '181,00': 4,
  // C2: "IMPROPER DATA FORMAT." — one operand's format is unusable; no
  // statement-level word in the text.
  '182,00': 2,
  // C5: "EXCEEDS INTERNAL TABLE CAPACITY." — D9.2 lists it at 5 (D9.7 map:
  // 50 index expressions).
  '183,00': 5,
  // C5: "EXCEEDS INTERNAL TABLE CAPACITY." — D9.2 lists it at 5 (D9.7 map:
  // 90 positional indicators).
  '184,00': 5,
  // C2: "DATA DESCRIPTION PICTORIAL ERROR." — the pictorial operand is lost.
  '185,00': 2,
  // C1: "SHOULD BE PUNCHED … POSSIBLE CONTINUATION CHARACTER ERROR." —
  // advisory; the entry still assembles from its first card.
  '186,00': 1,
  // C3: "CONDITIONAL EXPRESSION TEST CAPACITY EXCEEDED. REWRITE …, EACH
  // WITH" — the printed text truncates (D9.6), so its recovery clause may be
  // among the lost words. Sentence-scoped capacity, the same unit as 177.
  // See Uncertain calls.
  '187,00': 3,
  // C3: "IS NEITHER A STATEMENT NOR A SECTION NAME." — the DO statement
  // cannot link.
  '188,00': 3,
  // C1: "EXTERNAL MODE SUBSTITUTED" — the text states the substitution.
  '189,00': 1,
  // C1: "FIELD IS NOT JUSTIFIED" — the text states the repair.
  '190,00': 1,
  // C4: "'NAME.1' IS NOT PROPERLY DEFINED." — B.2 puts it under the same
  // rule as 108, which D9.2 fixes at C4.
  '191,00': 4,
  // C3: "SENTENCE STRUCTURE ERROR." — the sentence is the named unit.
  '192,00': 3,
  // C4: "LIMIT OF 63 FILES EXCEEDED." — an attested language limit (J
  // 90.01.04), not an internal table (not in the D9.7 map); the extra file's
  // I/O is lost.
  '193,00': 4,
  // C3: "DATA NAME LACKS LEVEL." — the entry cannot take its place in the
  // hierarchy.
  '194,00': 3,
  // C3: "CANNOT FILE RECORD 'NAME.2' IN THIS FILE" — the FILE statement is
  // lost; the file itself stays well formed.
  '195,00': 3,
  // C3: "ILLEGAL SENTENCE STRUCTURE NOTHING DONE." — D9.2 C3 example.
  '196,00': 3,
  // C4: "RECORD NAME MUST PRECEDE DESCRIPTION OF RECORD." — the record
  // cannot be built; record-level.
  '197,00': 4,
  // C1: "NO RECORDS PROCESSED IN FILE 'NAME.1'" — advisory: the file is
  // declared and never used, and no object code is lost.
  '198,00': 1,
  // C1: "UPSCALE MAY CAUSE HIGH ORDER TRUNCATION" — "MAY CAUSE" is advisory;
  // the store is generated.
  '199,00': 1,
  // C5: "EXCEEDS INTERNAL TABLE CAPACITY." — D9.2 lists it at 5 (D9.7 map:
  // 25 QUANTITY IN specifications; Open Question 67 note).
  '200,00': 5,
  // C5: "EXCEEDS INTERNAL TABLE CAPACITY." — D9.2 lists it at 5 (D9.7 map:
  // 23 hierarchy levels).
  '201,00': 5,
  // C5: "EXCEEDS INTERNAL TABLE CAPACITY." — D9.2 lists it at 5 (D9.7 map:
  // 127 base locators).
  '202,00': 5,
  // C5: "EXCEEDS INTERNAL TABLE CAPACITY." — D9.2 lists it at 5 (D9.7 map:
  // 85 array dimensions).
  '203,00': 5,
  // C5: "EXCEEDS INTERNAL TABLE CAPACITY." — D9.2 lists it at 5 (D9.7 map:
  // 35 edited field formats).
  '204,00': 5,
  // C5: "INTERNAL TABLE OVERFLOW." — D9.2 lists it at 5 (D9.7 map: 90
  // positional indicators).
  '205,00': 5,
  // C1: "HAS INEFFICIENT FORMAT" — D9.2 names this as a C1 example; D9.11
  // fixes severity 1, criterion invented.
  '206,00': 1,
  // C3: "-CONTRL- NAME MUST BE UNIQUE AND 6 CHARACTERS OR LESS." — the card
  // cannot bind; whole card.
  '207,00': 3,
  // C3: "SENTENCE CANNOT START WITH -OTHERWISE-" — the sentence is the named
  // unit.
  '208,00': 3,
  // C1: "BLOCKSIZE USED IS" + value — the text states the substitution (D9.5
  // value slot).
  '209,00': 1,
  // Ours, outside the 0-209 range (D9.7):
  // C1 (ours): the stray period is ignored and scanning continues.
  '900,00': 1,
  // C2 (ours): the over-long name operand cannot resolve.
  '901,00': 2,
  // C3 (ours, D2.3): the card is ignored - statement-level loss.
  '902,00': 3,
  // C3 (ours, D9.14): the card is ignored - statement-level loss.
  '903,00': 3,
  // C1 (ours): the duplicate card is ignored and compilation carries on.
  '904,00': 1,
};
