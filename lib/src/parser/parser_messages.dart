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

/// `110,00` — COPY or LIBRARY used; deferred in J (J 90.01.03; D7.4).
final Message msgCopyNotHandled = messageCatalog['110,00']!;

/// `153,00` — a malformed SPECIF card.
final Message msgSpecifCardFormatError = messageCatalog['153,00']!;

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

/// Ours — the PATTERN option on a FILE card: the key word is reserved
/// and its rules are bound, but the card syntax is adopted only at M5
/// (D9.12, D6.1). D9.12 forbids msgs 89 and 96 for this word.
final Message msgPatternNotImplemented = Message.ours(
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
final Message msgDataCardCodingConflict = Message.ours(
  '906,00',
  'DATA DESCRIPTION CARD CODING CONFLICTS WITH ITS TYPE CODE. '
      '(NON-HISTORICAL.)',
);

/// Ours — a type code the 7090 language does not have: F's withdrawn
/// FUNCT and PARAM (J 02.05.03) or an unrecognized code.
final Message msgTypeCodeNotInLanguage = Message.ours(
  '907,00',
  "TYPE CODE 'NAME.1' IS NOT IN THE 7090 LANGUAGE. (NON-HISTORICAL.)",
);

/// Ours — a Quantity field outside 1–32767 or not a number
/// (J 02.05.04 states the maximum; no diagnostic is attested).
final Message msgQuantityOutOfRange = Message.ours(
  '908,00',
  'QUANTITY MUST BE A NUMBER FROM 1 TO 32767. (NON-HISTORICAL.)',
);

/// Ours — an unrecognized option word on the compile control card
/// (J 02.01.01 lists the eight options; no diagnostic is attested).
final Message msgUnknownCompileOption = Message.ours(
  '909,00',
  "COMPILE CARD OPTION 'NAME.1' IS NOT RECOGNIZED AND IS IGNORED. "
      '(NON-HISTORICAL.)',
);
