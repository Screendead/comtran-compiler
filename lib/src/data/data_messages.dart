/// The data mapper's diagnostic vocabulary (M3 stage 1).
///
/// Catalog messages are referenced from `messageCatalog` — one source,
/// no restated text to drift (the catalog itself is golden-tested
/// byte for byte, D9.5). Messages of ours carry ids from 930,00 up in
/// one sequence (design note M3-13) and close with `(NON-HISTORICAL.)`
/// (D9.7); each has a row in `severities.dart`.
library;

import '../lexer/message_catalog.dart';
import '../lexer/messages.dart';

/// `5,00` — a record longer than its file's BLOCKSIZE with neither
/// HOLD nor SPANS (J 02.06.04). The catalog text prints the numbers
/// 24 and 12 as captured; D9.5 keeps the bytes.
final Message msgRecordExceedsBlocksize = messageCatalog['5,00']!;

/// `8,00` — a GET or FILE operand that names nothing at all, or names
/// a statement, a section, or a condition (M3-18). A name that reaches
/// a file or a plain field takes msg 16 instead.
final Message msgNeitherRecordNorFile = messageCatalog['8,00']!;

/// `9,00` — a GET operand that names a record on no FILE card
/// (M3-18).
final Message msgRecordNotOnFileCard = messageCatalog['9,00']!;

/// `10,00` — a GET operand that names a record on FILE cards, none of
/// them input (M3-18).
final Message msgRecordNotOnInputFile = messageCatalog['10,00']!;

/// `11,00` — a record named on more than one input FILE card.
final Message msgRecordOnTwoInputFiles = messageCatalog['11,00']!;

/// `12,00` — a GET RECORD FROM on a file that meets none of the
/// J 02.07.04 preconditions, so no record length can be determined.
/// PATTERN, the fifth precondition, waits for its M5 syntax (D9.12).
final Message msgGetRecordFromLength = messageCatalog['12,00']!;

/// `13,00` — a FILE card that names no record at all. The 13/15 split
/// is ours: both catalog texts are identical, so 13 takes the
/// no-names-at-all case and 15 the none-resolve case, following the
/// M1-8 precedent of splitting overlapping ids by trigger.
final Message msgFileCardLacksRecord = messageCatalog['13,00']!;

/// `14,00` — a GET RECORD FROM naming a file that is not an input
/// file (M3-18).
final Message msgGetRecordFromNotInput = messageCatalog['14,00']!;

/// `15,00` — a FILE-card record name with no corresponding Data
/// Description entry (the other half of the 13/15 split above).
final Message msgFileRecordUndeclared = messageCatalog['15,00']!;

/// `16,00` — a FILE-card record name that resolves to a data item
/// without the RECORD type code, or a GET or FILE operand that names a
/// file or a plain field (M3-18: the FILE-verb non-record case, which
/// leaves msg 17 without a trigger).
final Message msgFileNameNotRecord = messageCatalog['16,00']!;

/// `19,00` — a FILE operand that names a record on no output FILE
/// card (M3-18).
final Message msgRecordNotOnOutputFile = messageCatalog['19,00']!;

/// `20,00` — an output file in BCD form carrying a record with
/// binary contents — an internal-mode or floating field
/// (J 02.05.04: internal means binary).
final Message msgBinaryDataOnBcdTape = messageCatalog['20,00']!;

/// `21,00` — a name that must be a file and is not: a SPECIF card's
/// first option (J 02.06.08), a POOL or GROUP variable-field file name
/// (J 02.06.13–14), or an OPEN, CLOSE, or FILE IN operand (M3-18).
final Message msgNameIsNotFile = messageCatalog['21,00']!;

/// `22,00` — a FILE IN operand that names a file open for input or
/// checkpoint use (M3-18).
final Message msgFileIsNotOutput = messageCatalog['22,00']!;

/// `23,00` — a GET RECORD FROM operand that names no file (M3-18).
final Message msgGetRecordFromNotFile = messageCatalog['23,00']!;

/// `25,00` — an operand whose data format is improper for its use: a
/// condition or environment name at a data site, a non-condition where
/// only a condition may stand (M3-17), or an alphameric-class operand
/// inside a true arithmetic expression (M3-21).
final Message msgImproperFormatForUse = messageCatalog['25,00']!;

/// `30,00` — a function reference with fewer arguments than its
/// owning section's BEGIN SECTION USING clause declares (M3-19).
final Message msgFunctionArgumentsMissing = messageCatalog['30,00']!;

/// `31,00` — a subscript variable with fraction positions; a scaled
/// integer (a trailing `S` run) counts as one (M3-20).
final Message msgSubscriptVariableNotInteger = messageCatalog['31,00']!;

/// `32,00` — a mode-versus-pictorial conflict the J 02.05.05 chart
/// does not define: edit characters or FF under the wrong mode, an
/// overpunch under mode I. The pictorial's format is used (M3-4).
final Message msgModeDescriptionConflict = messageCatalog['32,00']!;

/// `33,00` — an illegal combination of format characters: A or X
/// mixed with edit characters, V, S, or F. The field is treated as
/// alphameric over the storage-reserving positions (M3-4).
final Message msgIllegalFormatCombination = messageCatalog['33,00']!;

/// `34,00` — a repetition count over `Pictorial.maxCount`, which the
/// clamped format replaces. The 1962 maximum is unstated; 99999 sits
/// above every field a blocksize can hold (M3-16 as amended
/// 2026-08-04).
final Message msgFormatCharacterCountExceeded = messageCatalog['34,00']!;

/// `35,00` — a numeric length past what the field form can hold: a
/// scientific decimal fraction over the attested 16-digit maximum
/// (J 02.05.05 note 4; 16 kept), or a right-justified internal
/// field over the 21 digits two register words hold (derived bound,
/// M3-16; 21 kept).
final Message msgNumericLengthExceededInField = messageCatalog['35,00']!;

/// `36,00` — sub-organization under a formatted field; only COND may
/// appear below one (J 02.05.06). The subordinate entries are
/// dropped from storage.
final Message msgFormatLevelSubOrganization = messageCatalog['36,00']!;

/// `37,00` — a COND entry under a variable without an explicitly
/// described format, or a COND constant that cannot match the
/// variable's format (J 02.05.02; M3-17).
final Message msgConditionalVariableFormat = messageCatalog['37,00']!;

/// `38,00` — a COND entry carrying a Quantity: a condition names a
/// value, never storage (F pp. 71–72).
final Message msgCondCannotHaveQuantity = messageCatalog['38,00']!;

/// `39,00` — right justification on a group entry; R is effective
/// only with an explicitly described format (J 02.05.04; D3.5), so
/// the group stays unjustified.
final Message msgGroupCannotJustifyRight = messageCatalog['39,00']!;

/// `40,00` — a REDEF naming a target that appears only later in the
/// program (J 02.05.02: assignment proceeds over an already-allocated
/// area).
final Message msgRedefBeforeDefinition = messageCatalog['40,00']!;

/// `41,00` — a REDEF or QUANTITY IN name that matches no Data
/// Description entry.
final Message msgRedefTargetUndefined = messageCatalog['41,00']!;

/// `42,00` — an item that reserves no storage: a leaf with neither
/// pictorial nor constant, or a record whose length no field supplies
/// (J 02.05.01: redefinition of a record area gives it no length).
final Message msgDataItemWithoutLength = messageCatalog['42,00']!;

/// `43,00` — a constant inside a REDEF's extent, in a located input
/// record, or after a variable length field (J 02.05.06; D3.6 as
/// amended 2026-08-04: this catalog text covers all three). The
/// constant is not stored.
final Message msgConstantPlacementIllegal = messageCatalog['43,00']!;

/// `44,00` — QUANTITY IN with a blank Quantity field: storage for one
/// occurrence is reserved (J 02.05.07).
final Message msgQuantityAssumedOne = messageCatalog['44,00']!;

/// `45,00` — a REDEF or QUANTITY IN name that resolves to a COND
/// entry.
final Message msgRedefTargetIsCond = messageCatalog['45,00']!;

/// `46,00` — a REDEF or QUANTITY IN name that resolves to something
/// other than a data name — an Environment name in stage 1.
final Message msgRedefTargetNotDataName = messageCatalog['46,00']!;

/// `47,00` — QUANTITY IN on an entry without an explicitly described
/// format (J 02.05.05; the variable field must be a formatted
/// leaf).
final Message msgQuantityInOnGroup = messageCatalog['47,00']!;

/// `51,00` — a numeric constant whose length conflicts with its
/// pictorial: external must match exactly, internal larger than the
/// pictorial is left-truncated, converted, and stored (J 02.05.07).
final Message msgConstantLengthConflict = messageCatalog['51,00']!;

/// `54,00` — a character in a constant that its field type cannot
/// store.
final Message msgIllegalConstantCharacter = messageCatalog['54,00']!;

/// `55,00` — floating point overflow converting a constant.
final Message msgFloatingOverflow = messageCatalog['55,00']!;

/// `56,00` — floating point underflow converting a constant.
final Message msgFloatingUnderflow = messageCatalog['56,00']!;

/// `57,00` — a constant on an edited field (J 02.05.06 i). The
/// constant is not stored.
final Message msgConstantOnEditedField = messageCatalog['57,00']!;

/// `58,00` — an external decimal constant whose sign convention does
/// not match its pictorial (J 02.05.07: `999̅` takes `123̅`, never
/// `123`).
final Message msgExternalConstantInError = messageCatalog['58,00']!;

/// `59,00` — an alphameric constant longer than its pictorial: filled
/// from the left, the remainder discarded (J 02.05.06).
final Message msgAlphabeticConstantConflict = messageCatalog['59,00']!;

/// `60,00` — a `(0)` repetition count, replaced by one.
final Message msgZeroCountInPictorial = messageCatalog['60,00']!;

/// `61,00` — a statement label or section name that is a J key word:
/// an operation found in the name field (M3-17).
final Message msgOperationAsName = messageCatalog['61,00']!;

/// `67,00` — a non-numeric character in a numeric field's constant.
final Message msgNonNumericInNumericField = messageCatalog['67,00']!;

/// `68,00` — a function reference with more arguments than its owning
/// section's BEGIN SECTION USING clause declares (M3-19).
final Message msgFunctionTooManyArguments = messageCatalog['68,00']!;

/// `70,00` — a subscript count above zero that differs from the
/// referenced item's dimension count (M3-20).
final Message msgArrayDimensionCheck = messageCatalog['70,00']!;

/// `71,00` — a subscript whose variable carries subscripts of its own
/// or names a condition; F p. 31 admits a name or an index expression
/// only. NAME.1 is the array (M3-20).
final Message msgInvalidSubscriptVariable = messageCatalog['71,00']!;

/// `72,00` — a DO carrying more USING arguments than its target
/// section declares; a statement target declares none (M3-19).
final Message msgTooManyUsingParameters = messageCatalog['72,00']!;

/// `73,00` — a DO carrying fewer USING arguments than its target
/// section declares (M3-19).
final Message msgTooFewUsingParameters = messageCatalog['73,00']!;

/// `74,00` — a DO carrying more GIVING results than its target
/// section declares (M3-19).
final Message msgTooManyGivingParameters = messageCatalog['74,00']!;

/// `75,00` — a DO carrying fewer GIVING results than its target
/// section declares (M3-19).
final Message msgTooFewGivingParameters = messageCatalog['75,00']!;

/// `76,00` — a FOR index variable of alphameric, edited, or group
/// class (F pp. 49–53; M3-20).
final Message msgLoopVariableFormat = messageCatalog['76,00']!;

/// `77,00` — a named p, q, or r loop parameter of alphameric,
/// edited, or group class (M3-20). NAME.1 is the parameter.
final Message msgLoopParameterFormat = messageCatalog['77,00']!;

/// `78,00` — a literal p, q, or r loop parameter that is not a whole
/// number (M3-20). NAME.1 is the loop control variable.
final Message msgLoopLiteralParameterFormat = messageCatalog['78,00']!;

/// `79,00` — a subscript variable of alphameric, edited, or group
/// class (M3-20).
final Message msgSubscriptVariableNotNumeric = messageCatalog['79,00']!;

/// `80,00` — the first redefining entry's justification differs from
/// the redefined item's (J 02.05.02).
final Message msgRedefJustificationConflict = messageCatalog['80,00']!;

/// `81,00` — the first redefining entry's level differs from the
/// redefined item's (J 02.05.02: "must have the same level
/// number").
final Message msgRedefLevelConflict = messageCatalog['81,00']!;

/// `82,00` — HIGH.VALUE or LOW.VALUE moved to an internal decimal or
/// floating point field — the J 02.04.02 chart's two Illegal cells —
/// or HIGH.VALUE, LOW.VALUE, or BLANK compared to a field that is not
/// alphameric (J 02.04.01 b). The starred BLANK moves are doubtful,
/// not illegal, and take msg 943 (D4.11; M3-21).
final Message msgIncorrectFigurativeUsage = messageCatalog['82,00']!;

/// `84,00` — an alphameric-class source moved to a target that is
/// neither alphameric nor a group (J 02.04.03 c), including a
/// CORRESPONDING pair whose group source is assumed alphameric
/// (J 02.04.04 c; D4.12).
final Message msgIllegalMove = messageCatalog['84,00']!;

/// `97,00` — a MOVE or ADD CORRESPONDING operand that resolves to
/// nothing or to a field with no subordinates: correspondence is
/// sought below the operand (J 02.04.04; M3-21).
final Message msgInvalidCorresponding = messageCatalog['97,00']!;

/// `98,00` — a subscripted reference to an item no Quantity gives a
/// dimension (M3-20).
final Message msgArrayDescriptionCheck = messageCatalog['98,00']!;

/// `101,00` — a reference whose final word is declared but whose
/// qualifier chain matches no declaration, or a qualified reference
/// ending in a CALL synonym (M3-17; D4.13).
final Message msgImproperlyQualified = messageCatalog['101,00']!;

/// `102,00` — a QUANTITY IN name that resolves to a non-numeric
/// field.
final Message msgQuantityInNotNumeric = messageCatalog['102,00']!;

/// `103,00` — a Quantity on a LABEL entry. RECORD and REDEF carry
/// M2's card-coding conflict instead; COND takes msg 38 (the split
/// is ours).
final Message msgLabelCannotHaveQuantity = messageCatalog['103,00']!;

/// `104,00` — a REDEF or LABEL between a non-format entry and
/// format-described levels; the criterion is the message's own
/// (D9.11: criterion attested, severity ours).
final Message msgRedefBetweenLevels = messageCatalog['104,00']!;

/// `105,00` — a QUANTITY IN count field defined after the variable
/// field that depends on it.
final Message msgQuantityItemFollowsVariable = messageCatalog['105,00']!;

/// `108,00` — a reference whose final word is declared nowhere
/// (M3-17).
final Message msgUndefinedSymbol = messageCatalog['108,00']!;

/// `111,00` — a FIND LENGTH IN name that is not an external or
/// internal decimal field without fraction positions. The proper
/// format is ours (M3-18).
final Message msgFindLengthFormat = messageCatalog['111,00']!;

/// `112,00` — a PLACE LENGTH IN name of the same improper format
/// (M3-18).
final Message msgPlaceLengthFormat = messageCatalog['112,00']!;

/// `117,00` — FIND LENGTH IN on some but not all of the records of a
/// file a GET RECORD FROM names (M3-18).
final Message msgFindLengthNotUniform = messageCatalog['117,00']!;

/// `118,00` — PLACE LENGTH IN on some but not all of those records
/// (M3-18).
final Message msgPlaceLengthNotUniform = messageCatalog['118,00']!;

/// `120,00` — an alphameric-class source or target in an ADD; that
/// operand is eliminated and the rest of the ADD proceeds (M3-21).
final Message msgEliminatedFromAdd = messageCatalog['120,00']!;

/// `121,00` — BLOCK CONTROL on some but not all of those records
/// (M3-18).
final Message msgBlockControlNotUniform = messageCatalog['121,00']!;

/// `123,00` — a variable-length item as a comparison operand
/// (J 02.04.07 rule 5).
final Message msgVariableLengthComparison = messageCatalog['123,00']!;

/// `127,00` — a GO TO target that names no statement and no section
/// under the D2.5 scope rules (M3-20).
final Message msgTransferTargetNotProcedure = messageCatalog['127,00']!;

/// `128,00` — a GO TO target that a DO addresses, the AT END bare-name
/// form included (D6.6); such a procedure is not re-entrant
/// (Open Question 40; M3-20).
final Message msgTransferToDoAddressed = messageCatalog['128,00']!;

/// `129,00` — an assigned GO TO index of alphameric, edited, or group
/// class (M3-20).
final Message msgTransferIndexFormat = messageCatalog['129,00']!;

/// `130,00` — an assigned GO TO index with fraction positions; the
/// integral part serves (M3-20).
final Message msgTransferIndexNotInteger = messageCatalog['130,00']!;

/// `133,00` — a repetition count with no closing right parenthesis;
/// the digits through the end of the run are read as the count.
final Message msgNoRightParenthesis = messageCatalog['133,00']!;

/// `142,00` — PROGRAM.START declared as a data, environment, or
/// synonym name; it may only label a statement or section (D2.1).
final Message msgProgramStartMisdeclared = messageCatalog['142,00']!;

/// `152,00` — a name equal to a list-3 key word that an environment
/// card of the job uses (J 02.03.03; M2-7; M3-17). The name stands.
final Message msgListThreeWordAsName = messageCatalog['152,00']!;

/// `166,00` — a name that resolution cannot make unique: an ambiguous
/// reference, a duplicate label within one section scope, a duplicate
/// RECORD name, a CALL old.name naming more than one field, or a
/// synonym equal to an existing name (M3-17; D2.5; D4.13).
final Message msgNameNotUnique = messageCatalog['166,00']!;

/// `177,00` — the 101st distinct data reference of one sentence. The
/// 100-name table size is invented (D9.7; Open Question 9); the
/// sentence leaves the text (M3-20).
final Message msgSentenceTableCapacity = messageCatalog['177,00']!;

/// `180,00` — a figurative constant moved to a field whose length a
/// QUANTITY IN fixes at execution time; a subscripted element of that
/// array is proper (J 02.04.01 c-i).
final Message msgFigurativeToVariableField = messageCatalog['180,00']!;

/// `181,00` — a figurative constant moved to a field of 32767
/// characters or more. J's prose says 2^15 - 1; the implemented
/// maximum is the message text's 32766 (D4.6).
final Message msgFigurativeToLongField = messageCatalog['181,00']!;

/// `182,00` — a literal subscript term that is zero, negative, or
/// fractional; arrays are 1-origin (J 02.04.07.01; M3-20). The catalog
/// text takes no operand.
final Message msgImproperDataFormat = messageCatalog['182,00']!;

/// `183,00` — the 51st distinct `a * VARIABLE ± b` index expression
/// (D9.7's "Appox-Max" 50; J 90.01.05).
final Message msgIndexExpressionCapacity = messageCatalog['183,00']!;

/// `184,00` — the 91st distinct positional indicator: one per unique
/// array-and-subscript-notation pair (J 02.04.07; D9.7's "Appox-Max"
/// 90). Msg 205 names the same table and stays reserved (M3-20).
final Message msgSubscriptedNameCapacity = messageCatalog['184,00']!;

/// `185,00` — a description run read as a name that is not a data,
/// key, or procedure name (J 02.05.06 e), or description tokens no
/// clause claimed (M3-17).
final Message msgPictorialError = messageCatalog['185,00']!;

/// `188,00` — a DO target, or an AT END bare name (D6.6), that names
/// no statement and no section under the D2.5 scope rules (M3-20).
final Message msgDoTargetNotProcedure = messageCatalog['188,00']!;

/// `191,00` — a name improper for its defining use: a SET of a name
/// that is no settable condition, or a function reference to a name no
/// GIVING clause lists (M3-17; M3-19).
final Message msgNotProperlyDefined = messageCatalog['191,00']!;

/// `195,00` — a FILE IN whose file card does not name the record. The
/// text prints NAME.2 before NAME.1: the operands stay file, record.
final Message msgFileCardLacksThisRecord = messageCatalog['195,00']!;

/// `197,00` — a RECORD entry after a higher-numbered top-level entry
/// in the same portion: description punched before its record name
/// (M3-17).
final Message msgRecordNameMustPrecede = messageCatalog['197,00']!;

/// `198,00` — a file no GET and no FILE verb processes. Checkpoint
/// files are exempt: they carry no record (J 02.06.03; M3-18).
final Message msgNoRecordsProcessed = messageCatalog['198,00']!;

/// `200,00` — the 26th QUANTITY IN specification, "Appox-Max" 25
/// (J 90.01.05 item e; D9.7's reading of Open Question 67).
final Message msgVariableFieldCapacity = messageCatalog['200,00']!;

/// `201,00` — the 24th level of one data hierarchy, "Appox-Max" 23
/// (J 90.01.05 item j; D9.7). NAME.1 is the crossing entry.
final Message msgHierarchyDepthCapacity = messageCatalog['201,00']!;

/// `202,00` — the 128th located record. One base locator serves one
/// located record, "Appox-Max" 127 (J 90.01.05 item d; D9.7).
final Message msgBaseLocatorCapacity = messageCatalog['202,00']!;

/// `203,00` — the 86th array dimension: one per explicit or implicit
/// Quantity, "Appox-Max" 85 (J 90.01.05 item i; D9.7).
final Message msgArrayDimensionCapacity = messageCatalog['203,00']!;

/// `204,00` — the 36th distinct edited format, "Appox-Max" 35
/// (J 90.01.05 item c; D9.7).
final Message msgEditedFormatCapacity = messageCatalog['204,00']!;

/// `206,00` — a subscript variable of a legal format that is not
/// right-justified internal decimal, the one form the generator
/// indexes with directly. The criterion is invented (D9.11); C1.
final Message msgInefficientSubscriptFormat = messageCatalog['206,00']!;

/// `209,00` — an input card file's BLOCKSIZE under the stated
/// 24-word minimum (J 02.06.04); 24 is used. The catalog text ends
/// at "IS" as printed (D9.5).
final Message msgInsufficientBlocksize = messageCatalog['209,00']!;

/// Ours — a Quantity nested deeper than three levels (D3.1). The
/// quantity in excess is replaced by one.
const Message msgQuantityNestedTooDeep = Message.ours(
  '930,00',
  'QUANTITY NESTED DEEPER THAN THREE LEVELS. QUANTITY OF ONE USED. '
      '(NON-HISTORICAL.)',
);

/// Ours — a BLOCKSIZE over the Environment maximum of 9999 words;
/// the manuals attest no message for the case (D7.1).
const Message msgBlocksizeOverMaximum = Message.ours(
  '931,00',
  '-BLOCKSIZE- EXCEEDS THE ENVIRONMENT MAXIMUM OF 9999 WORDS. '
      '-FILE- CARD REJECTED. (NON-HISTORICAL.)',
);

/// Ours — an input file's records forced out of locate mode by a
/// REDEF that shares their area with other data. J 02.07.05 attests
/// the transmit and that a message accompanied it; the id and text
/// are ours.
const Message msgRecordsForcedTransmit = Message.ours(
  '932,00',
  "RECORDS OF FILE 'NAME.1' ARE TRANSMITTED BECAUSE A -REDEF- SHARES "
      'THEIR AREA. (NON-HISTORICAL.)',
);

/// Ours — `--pedantic` only: the attested silent downgrade of a mixed
/// alphabetic-and-numeric pictorial (J 90.01.03; D11.4).
const Message msgMixedPictorialDowngraded = Message.ours(
  '933,00',
  'MIXED ALPHABETIC AND NUMERIC PICTORIAL IS TREATED AS ALPHAMERIC. '
      '(NON-HISTORICAL.)',
);

/// Ours — `--pedantic` only: a Quantity on an unnamed entry without
/// named subordinates, which the manuals say "should not" be written
/// (F p. 77; J 02.05.04; Open Question 18).
const Message msgQuantityOnUnnamedEntry = Message.ours(
  '934,00',
  '-QUANTITY- ON AN UNNAMED ENTRY WITHOUT NAMED SUBORDINATES. '
      'ACCEPTED. (NON-HISTORICAL.)',
);

/// Ours — `--pedantic` only: an explicit R on a formatless leaf, where
/// right justification is not effective (J 02.05.04; D3.5). A group
/// with R draws the attested msg 39 instead.
const Message msgIneffectiveRightJustification = Message.ours(
  '935,00',
  'RIGHT JUSTIFICATION IGNORED FOR A FIELD WITHOUT AN EXPLICITLY '
      'DESCRIBED FORMAT. (NON-HISTORICAL.)',
);

/// Ours — a subscripted CALL old.name; the pair is dropped
/// (J 90.01.01; D4.13; M3-21).
const Message msgCallOldNameSubscripted = Message.ours(
  '936,00',
  'SUBSCRIPT CANNOT BE USED IN THE OLD NAME OF A -CALL-. '
      'PAIR DROPPED. (NON-HISTORICAL.)',
);

/// Ours — a POOL BUFFERCOUNT below the number of files in the pool, or
/// below the buffers its groups claim; "nn must be equal to or greater
/// than" both (J 02.06.13). The minimum is used, following msg 209's
/// substitution precedent (M3-18).
const Message msgPoolBufferCountRaised = Message.ours(
  '937,00',
  "-POOL- 'NAME.1' -BUFFERCOUNT- IS BELOW ITS MINIMUM. THE MINIMUM IS "
      'USED. (NON-HISTORICAL.)',
);

/// Ours — a GROUP BUFFERCOUNT below the group's OPENCOUNT, which
/// J 02.06.14 forbids. The OPENCOUNT is used (M3-18).
const Message msgGroupBufferCountRaised = Message.ours(
  '938,00',
  '-GROUP- -BUFFERCOUNT- IS BELOW ITS -OPENCOUNT-. THE -OPENCOUNT- IS '
      'USED. (NON-HISTORICAL.)',
);

/// Ours — a GROUP card whose first variable-field item names no pool.
/// "The POOL to which a particular GROUP of files belongs must be
/// specified by listing the pool.name as the first item"
/// (J 02.06.14).
const Message msgGroupLacksPool = Message.ours(
  '939,00',
  "-GROUP- CARD ITEM 'NAME.1' IS NOT A -POOL- NAME. THE -GROUP- IS NOT "
      'ASSIGNED. (NON-HISTORICAL.)',
);

/// Ours — a LABEL entry over "the single 14 word label area in the
/// Input/Output Control System" (J 02.05.03; M3-18).
const Message msgLabelAreaTooLong = Message.ours(
  '940,00',
  "-LABEL- AREA 'NAME.1' EXCEEDS 14 WORDS. (NON-HISTORICAL.)",
);

/// Ours — a field described after a variable length array of the same
/// hierarchy, which J 90.01.01 forbids; no catalog id covers it
/// (M3-16; M3-18).
const Message msgFieldAfterVariableArray = Message.ours(
  '941,00',
  "FIELD 'NAME.1' IS DESCRIBED AFTER A VARIABLE LENGTH ARRAY OF THE "
      'SAME HIERARCHY. (NON-HISTORICAL.)',
);

/// Ours — the dictionary past D9.7's message-less 3500-name limit
/// (J 90.01.05 item a; M3-21).
const Message msgDictionaryCapacity = Message.ours(
  '942,00',
  'NUMBER OF NAMES EXCEEDS THE 3500 NAME DICTIONARY CAPACITY. '
      '(NON-HISTORICAL.)',
);

/// Ours — `--pedantic` only: a BLANK moved or SET into an external
/// decimal, internal decimal, floating point, or scientific decimal
/// field — the J 02.04.02 chart's starred cells, accepted in the
/// default mode (D4.11; M3-21). The chart's edited cell is excluded:
/// the 90.05 sample blanks two edited fields and reports no error.
const Message msgDoubtfulFigurativeUsage = Message.ours(
  '943,00',
  'DOUBTFUL FIGURATIVE CONSTANT USAGE ACCEPTED. (NON-HISTORICAL.)',
);

/// Ours — `--pedantic` only: a CORRESPONDING clause under which no
/// pair of names matches, so the clause generates nothing. A partial
/// match draws nothing: the 90.05 sample leaves names unmatched in
/// every CORRESPONDING clause it writes (D4.12; M3-21).
const Message msgCorrespondingMatchesNothing = Message.ours(
  '944,00',
  'NO -CORRESPONDING- NAMES MATCH. ACCEPTED. (NON-HISTORICAL.)',
);

/// Ours — `--pedantic` only: a record.name as a CALL old.name, which
/// J advises against (J 02.04.05; D4.13; M3-21).
const Message msgCallOldNameIsRecord = Message.ours(
  '945,00',
  'A RECORD NAME IS USED AS THE OLD NAME OF A -CALL-. ACCEPTED. '
      '(NON-HISTORICAL.)',
);
