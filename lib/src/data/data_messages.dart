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

/// `11,00` — a record named on more than one input FILE card.
final Message msgRecordOnTwoInputFiles = messageCatalog['11,00']!;

/// `13,00` — a FILE card that names no record at all. The 13/15 split
/// is ours: both catalog texts are identical, so 13 takes the
/// no-names-at-all case and 15 the none-resolve case, following the
/// M1-8 precedent of splitting overlapping ids by trigger.
final Message msgFileCardLacksRecord = messageCatalog['13,00']!;

/// `15,00` — a FILE-card record name with no corresponding Data
/// Description entry (the other half of the 13/15 split above).
final Message msgFileRecordUndeclared = messageCatalog['15,00']!;

/// `16,00` — a FILE-card record name that resolves to a data item
/// without the RECORD type code.
final Message msgFileNameNotRecord = messageCatalog['16,00']!;

/// `20,00` — an output file in BCD form carrying a record with
/// binary contents — an internal-mode or floating field
/// (J 02.05.04: internal means binary).
final Message msgBinaryDataOnBcdTape = messageCatalog['20,00']!;

/// `21,00` — a SPECIF card whose first option names no FILE card
/// (J 02.06.08).
final Message msgNameIsNotFile = messageCatalog['21,00']!;

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

/// `67,00` — a non-numeric character in a numeric field's constant.
final Message msgNonNumericInNumericField = messageCatalog['67,00']!;

/// `80,00` — the first redefining entry's justification differs from
/// the redefined item's (J 02.05.02).
final Message msgRedefJustificationConflict = messageCatalog['80,00']!;

/// `81,00` — the first redefining entry's level differs from the
/// redefined item's (J 02.05.02: "must have the same level
/// number").
final Message msgRedefLevelConflict = messageCatalog['81,00']!;

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

/// `133,00` — a repetition count with no closing right parenthesis;
/// the digits through the end of the run are read as the count.
final Message msgNoRightParenthesis = messageCatalog['133,00']!;

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
