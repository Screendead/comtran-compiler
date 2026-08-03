/// The parser's diagnostic vocabulary (M2).
///
/// Catalog messages are referenced from `messageCatalog` — one source,
/// no restated text to drift (the catalog itself is golden-tested
/// byte for byte, D9.5). Messages of ours carry ids from 905,00 up and
/// close with `(NON-HISTORICAL.)` (D9.7); each has a row in
/// `severities.dart`.
library;

import '../lexer/message_catalog.dart';
import '../lexer/messages.dart';

/// `3,00` — a malformed OPTION card.
final Message msgOptionCardFormatError = messageCatalog['3,00']!;

/// `4,00` — a malformed COND environment card.
final Message msgCondCardFormatError = messageCatalog['4,00']!;

/// `6,00` — a COND key setting longer than 12 digits; the rightmost 12
/// are used (J 02.06.17).
final Message msgCondKeysTooLong = messageCatalog['6,00']!;

/// `7,00` — a COND key setting with a non-octal digit; the setting `1`
/// is substituted (J 02.06.17).
final Message msgCondKeysNotOctal = messageCatalog['7,00']!;

/// `89,00` — a malformed FILE card.
final Message msgFileCardFormatError = messageCatalog['89,00']!;

/// `90,00` — an environment type with no effect on the object deck;
/// CONTRL is the documented case (D7.8; J 90.01.04).
final Message msgEnvironmentTypeNotProcessed = messageCatalog['90,00']!;

/// `91,00` — BLOCKSIZE on a FILE card without a following integer.
final Message msgBlocksizeNeedsInteger = messageCatalog['91,00']!;

/// `92,00` — ON ERROR without a following statement name.
final Message msgOnErrorNeedsName = messageCatalog['92,00']!;

/// `93,00` — FOR LABEL without a following statement name.
final Message msgForLabelNeedsName = messageCatalog['93,00']!;

/// `94,00` — PLACE LENGTH IN without a following data name.
final Message msgPlaceLengthNeedsName = messageCatalog['94,00']!;

/// `95,00` — FIND LENGTH IN without a following data name.
final Message msgFindLengthNeedsName = messageCatalog['95,00']!;

/// `96,00` — an unrecognized word among a FILE card's options.
final Message msgIllegalWordInFileCard = messageCatalog['96,00']!;

/// `110,00` — COPY, LIBRARY, or INCLUDE used; deferred in J
/// (J 90.01.02–03; D9.8 — which supersedes D7.4's plan of a separate
/// INCLUDE message).
final Message msgCopyNotHandled = messageCatalog['110,00']!;

/// `153,00` — a malformed SPECIF card; the fallback for SPECIF faults
/// that no dedicated message 154,00–160,00 covers (D10.1).
final Message msgSpecifCardFormatError = messageCatalog['153,00']!;

/// `154,00` — a SPECIF card whose first description item is not a file
/// name (J 02.06.08).
final Message msgSpecifFileNameNotFirst = messageCatalog['154,00']!;

/// `155,00` — UNIT1 or UNIT2 on a SPECIF card without a following
/// alphameric literal (J 02.06.08: "the Quote Marks are mandatory").
final Message msgUnitNeedsLiteral = messageCatalog['155,00']!;

/// `156,00` — SERIAL without a following alphameric literal
/// (J 02.06.12).
final Message msgSerialNeedsLiteral = messageCatalog['156,00']!;

/// `157,00` — REEL without a following alphameric literal (J 02.06.12).
final Message msgReelNeedsLiteral = messageCatalog['157,00']!;

/// `158,00` — RETAIN without a following numeric integer (J 02.06.12).
final Message msgRetainNeedsInteger = messageCatalog['158,00']!;

/// `159,00` — ACTIVITY without a following numeric integer
/// (J 02.06.11).
final Message msgActivityNeedsInteger = messageCatalog['159,00']!;

/// `160,00` — an over-length literal after a SPECIF key word; the
/// operand is dropped (D10.1: the enforced bound is the option's own —
/// 6 for UNIT1/UNIT2, 5 for SERIAL, 4 for REEL).
final Message msgKeyWordLiteralTooLong = messageCatalog['160,00']!;

/// `161,00` — a malformed POOL card.
final Message msgPoolCardFormatError = messageCatalog['161,00']!;

/// `162,00` — BLOCKSIZE on a POOL card without a following integer.
final Message msgPoolBlocksizeNeedsInteger = messageCatalog['162,00']!;

/// `163,00` — BUFFERCOUNT without a following integer.
final Message msgBuffercountNeedsInteger = messageCatalog['163,00']!;

/// `164,00` — a malformed GROUP card.
final Message msgGroupCardFormatError = messageCatalog['164,00']!;

/// `165,00` — OPENCOUNT without a following integer.
final Message msgOpencountNeedsInteger = messageCatalog['165,00']!;

/// `176,00` — a malformed CONTRL card.
final Message msgContrlCardFormatError = messageCatalog['176,00']!;

/// `207,00` — a CONTRL load name over 6 characters or not unique.
final Message msgContrlNameInvalid = messageCatalog['207,00']!;

/// `2,00` — RUN outside STOP RUN; the word is deleted (D2.7).
final Message msgRunDeleted = messageCatalog['2,00']!;

/// `63,00` — CORRESPONDING not directly after ADD or MOVE.
final Message msgCorrespondingMisplaced = messageCatalog['63,00']!;

/// `64,00` — END with no section open.
final Message msgEndWithoutSection = messageCatalog['64,00']!;

/// `65,00` — END naming a section that is not the innermost open one.
final Message msgEndWrongSection = messageCatalog['65,00']!;

/// `66,00` — sections still open at the end of the text.
final Message msgSectionsNotClosed = messageCatalog['66,00']!;

/// `83,00` — a malformed DO statement (also a fourth index, D5.2).
final Message msgInvalidDoForm = messageCatalog['83,00']!;

/// `106,00` — an AT END slot that is empty or not headed by a
/// statement or section name (D6.6).
final Message msgAtEndNeedsName = messageCatalog['106,00']!;

/// `107,00` — a malformed comparison.
final Message msgIllegalComparison = messageCatalog['107,00']!;

/// `113,00` — a right parenthesis with nothing open; eliminated.
final Message msgRedundantRightParen = messageCatalog['113,00']!;

/// `114,00` — a left parenthesis never closed.
final Message msgRedundantLeftParen = messageCatalog['114,00']!;

/// `116,00` — a missing operand; zero assumed.
final Message msgMissingOperand = messageCatalog['116,00']!;

/// `119,00` — a malformed MOVE operand list.
final Message msgIncompleteMove = messageCatalog['119,00']!;

/// `122,00` — an incomplete statement; the sentence is deleted.
final Message msgIncompleteStatement = messageCatalog['122,00']!;

/// `125,00` — a statement with no verb; deleted.
final Message msgStatementWithoutVerb = messageCatalog['125,00']!;

/// `126,00` — more than one verb where one was expected; deleted.
final Message msgStatementTwoVerbs = messageCatalog['126,00']!;

/// `131,00` — a malformed DISPLAY statement (design note M2-10).
final Message msgInvalidDisplay = messageCatalog['131,00']!;

/// `138,00` — CLOSE not followed by a file name.
final Message msgCloseNeedsFileName = messageCatalog['138,00']!;

/// `139,00` — OPEN not followed by a file name.
final Message msgOpenNeedsFileName = messageCatalog['139,00']!;

/// `141,00` — more than one PROGRAM.START; the first is used (D2.1).
final Message msgDuplicateProgramStart = messageCatalog['141,00']!;

/// `143,00` — PROGRAM.START addressed by a DO (D2.1).
final Message msgProgramStartDoAddressed = messageCatalog['143,00']!;

/// `149,00` — more than 35 sections (D9.7 hard cap).
final Message msgTooManySections = messageCatalog['149,00']!;

/// `170,00` — an IF where the conditional GO TO's WHEN belongs; parsed
/// as WHEN (the repair is attested, the criterion is ours — D9.11).
final Message msgWhenSubstitutedForIf = messageCatalog['170,00']!;

/// `171,00` — more than 60 operators in one sentence; deleted.
final Message msgTooManyOperators = messageCatalog['171,00']!;

/// `175,00` — no STOP RUN in the program (D2.7).
final Message msgNoStopRun = messageCatalog['175,00']!;

/// `179,00` — an END that is not the only clause in its sentence.
final Message msgEndNotAlone = messageCatalog['179,00']!;

/// `178,00` — a key word used as a Data or Environment name; it is
/// interpreted as a data name and parsing continues (D1.5; D10.8
/// applies it to J's list 1 and list 2 alike).
final Message msgKeyWordAsDataName = messageCatalog['178,00']!;

/// `192,00` — a sentence-structure error, possibly a key word misused
/// (D1.5).
final Message msgSentenceStructureError = messageCatalog['192,00']!;

/// `193,00` — a 64th FILE card: "A maximum of 63 files may be
/// described" (J 90.01.04).
final Message msgTooManyFiles = messageCatalog['193,00']!;

/// `196,00` — an illegal sentence structure; nothing done.
final Message msgIllegalSentenceStructure = messageCatalog['196,00']!;

/// `208,00` — a sentence starting with OTHERWISE.
final Message msgSentenceStartsOtherwise = messageCatalog['208,00']!;

/// Ours — the PATTERN option on a FILE card: the key word is reserved
/// and its rules are bound, but the card syntax is adopted only at M5
/// (D9.12, D6.1). D9.12 forbids msgs 89 and 96 for this word.
const Message msgPatternNotImplemented = Message.ours(
  '905,00',
  '-PATTERN- OPTION RECOGNIZED BUT NOT IMPLEMENTED. SEE DECISION D6. '
      '(NON-HISTORICAL.)',
);

/// Ours — coding on a data description card that its type code forbids:
/// Quantity on a RECORD card (J 02.05.01), description content beyond
/// the target name on a REDEF card (J 02.05.02), a non-pictorial
/// description on an RCDMRK card (J 02.05.03; the sample's own RCDMRK
/// punches an explicit `A`), a COND entry without exactly one quoted
/// constant (F pp. 71–72), or a QUANTITY IN with no following name. The
/// rules are J's; no 90.04 entry covers them.
const Message msgDataCardCodingConflict = Message.ours(
  '906,00',
  'DATA DESCRIPTION CARD CODING CONFLICTS WITH ITS TYPE CODE. '
      '(NON-HISTORICAL.)',
);

/// Ours — a type code the 7090 language does not have: F's withdrawn
/// FUNCT and PARAM (J 02.05.03) or an unrecognized code.
const Message msgTypeCodeNotInLanguage = Message.ours(
  '907,00',
  "TYPE CODE 'NAME.1' IS NOT IN THE 7090 LANGUAGE. (NON-HISTORICAL.)",
);

/// Ours — a Quantity field outside 1–32767 or not a number
/// (J 02.05.04 states the maximum; no diagnostic is attested).
const Message msgQuantityOutOfRange = Message.ours(
  '908,00',
  'QUANTITY MUST BE A NUMBER FROM 1 TO 32767. (NON-HISTORICAL.)',
);

/// Ours — an unrecognized option word on the compile control card
/// (J 02.01.01 lists the eight options; no diagnostic is attested).
const Message msgUnknownCompileOption = Message.ours(
  '909,00',
  "COMPILE CARD OPTION 'NAME.1' IS NOT RECOGNIZED AND IS IGNORED. "
      '(NON-HISTORICAL.)',
);

/// Ours — a subscript on a condition-name (J 90.01.03 prohibits the
/// construct; D5.6: reject it, leaving the element semantics
/// unimplemented rather than invented). The sentence is deleted.
const Message msgSubscriptedConditionName = Message.ours(
  '910,00',
  'A CONDITION NAME CANNOT BE SUBSCRIPTED. SENTENCE DELETED FROM TEXT. '
      '(NON-HISTORICAL.)',
);

/// Ours — an AT END clause that is a single imperative but not a
/// transfer (`DO name`, `GO TO name`, or a bare name). Accepted at low
/// severity per D6.6; `--pedantic` will raise it.
const Message msgAtEndNotTransfer = Message.ours(
  '911,00',
  '-AT END- CLAUSE IS NOT A TRANSFER. ACCEPTED. (NON-HISTORICAL.)',
);

/// Ours — an alphameric literal as a bare arithmetic operand outside
/// TR (F p. 45 permits it only inside a TR conditional expression).
const Message msgAlphamericArithOperand = Message.ours(
  '912,00',
  'ALPHABETIC LITERAL CANNOT BE AN ARITHMETIC OPERAND OUTSIDE -TR-. '
      '(NON-HISTORICAL.)',
);

/// Ours — `A**B**C` without parentheses (F p. 107; D4.10: reject,
/// group left for recovery only, no code generated).
const Message msgUnparenthesizedPower = Message.ours(
  '913,00',
  'CONSECUTIVE EXPONENTIATIONS MUST BE PARENTHESIZED. '
      '(NON-HISTORICAL.)',
);

/// Ours — more than three subscripts in one reference (F p. 30; D3.1:
/// no J message number is attested for the check).
const Message msgTooManySubscripts = Message.ours(
  '914,00',
  'A REFERENCE CANNOT HAVE MORE THAN THREE SUBSCRIPTS. '
      '(NON-HISTORICAL.)',
);

/// Ours — section nesting deeper than 18 (J 90.01.05; D9.7: the limit
/// has no 1962 message and takes a non-historical id at severity 5).
const Message msgSectionsTooDeep = Message.ours(
  '915,00',
  'SECTION NESTING EXCEEDS THE DEPTH OF 18. (NON-HISTORICAL.)',
);

/// Ours — LOAD or OVERLAP, deferred in the field-test implementation
/// (J 90.01.03; design note M2-11): parsed, no code generated.
const Message msgDeferredVerb = Message.ours(
  '916,00',
  "VERB 'NAME.1' IS DEFERRED IN THE 7090 IMPLEMENTATION AND GENERATES "
      'NO CODE. (NON-HISTORICAL.)',
);

/// Ours — a function-reference argument that is not a data-name
/// (F p. 28, rule 15). The token is dropped; no 90.04 entry states
/// that recovery (D10.6).
const Message msgFunctionArgumentDropped = Message.ours(
  '917,00',
  'FUNCTION ARGUMENT IS NOT A DATA NAME AND IS DROPPED. '
      '(NON-HISTORICAL.)',
);

/// Ours — an F-style name on a REDEF line: accepted with this warning
/// and discarded, never entered in the dictionary (D3.4; no J message
/// covers the case).
const Message msgRedefNameDiscarded = Message.ours(
  '918,00',
  'NAME ON -REDEF- LINE IS DISCARDED. (NON-HISTORICAL.)',
);
