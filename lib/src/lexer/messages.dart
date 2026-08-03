/// The J 90.04 error-message catalog — the diagnostic vocabulary.
///
/// Message numbers and texts are verbatim from Appendix 90.04 ("ERROR
/// MESSAGES AND SEVERITY CODES"). The catalog prints code 0 for every
/// message "because the value may vary. One of the severity values 1
/// through 5 will actually be printed with the error message."
/// (J 90.04.01); per-message values are unrecoverable, so the severities
/// here are our assignment (Open Question 65). This file holds the
/// messages the M1 scanners can issue; M2 grows it toward the full
/// catalog.
library;

/// One catalog entry.
final class Message {
  /// Creates the catalog entry [number] with severity [severity] and
  /// verbatim [text].
  const Message(this.number, this.severity, this.text);

  /// Creates a message of ours for a condition the 90.04 catalog has no
  /// entry for; it prints without a catalog number.
  const Message.ours(this.severity, this.text) : number = null;

  /// The NUMBER column value, e.g. `62,00`, or `null` for a message of
  /// ours with no catalog entry.
  final String? number;

  /// Our assigned severity value, 1 through 5.
  final int severity;

  /// The MESSAGE column text, verbatim, with `'NAME.1'`-style parameters.
  final String text;

  /// [text] with each `'NAME.n'` parameter replaced by the matching
  /// operand, quoted as the compiler printed names.
  String substitute(List<String> operands) {
    var result = text;
    for (var i = 0; i < operands.length; i++) {
      result = result.replaceFirst("'NAME.${i + 1}'", "'${operands[i]}'");
    }
    return result;
  }
}

/// `52,00` — an over-long numeric literal or constant.
const Message msgNumericLengthExceeded = Message(
  '52,00',
  3,
  'MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL.',
);

/// `53,00` — a malformed numeric or floating point form.
const Message msgIncorrectNumericForm = Message(
  '53,00',
  3,
  'INCORRECT USAGE OF PERIOD, SIGN, OR F FOR CONSTANT OR LITERAL.',
);

/// `62,00` — a new statement began while the previous sentence was open.
const Message msgPeriodAssumed = Message(
  '62,00',
  1,
  'PREVIOUS CARD NOT PROPERLY TERMINATED. PERIOD ASSUMED.',
);

/// `150,00` — an alphameric literal longer than 50 characters.
const Message msgLiteralTooLong = Message(
  '150,00',
  3,
  'ALPHABETIC LITERAL EXCEEDS 50 CHARACTERS.',
);

/// `168,00` — an alphameric literal without a closing quotation mark on
/// its card.
const Message msgLiteralAcrossCards = Message(
  '168,00',
  3,
  'ALPHABETIC LITERAL EXTENDS ACROSS CARDS.',
);

/// `186,00` — fixed-field content on a continuation card.
const Message msgFixedFieldOnContinuation = Message(
  '186,00',
  2,
  'DATA OR ENVIRONMENT FIXED FIELD INFORMATION SHOULD BE PUNCHED IN ONLY '
      'THE FIRST CARD OF A MULTIPLE CARD GROUP. POSSIBLE CONTINUATION '
      'CHARACTER ERROR.',
);

/// `189,00` — an illegal Mode character.
const Message msgIllegalMode = Message(
  '189,00',
  2,
  'EXTERNAL MODE SUBSTITUTED FOR ILLEGAL MODE CHARACTER.',
);

/// `190,00` — an illegal Justification character.
const Message msgIllegalJustification = Message(
  '190,00',
  2,
  'FIELD IS NOT JUSTIFIED BECAUSE OF ILLEGAL JUSTIFICATION CHARACTER.',
);

/// `194,00` — a data description entry without a level number.
const Message msgDataNameLacksLevel = Message(
  '194,00',
  3,
  'DATA NAME LACKS LEVEL.',
);

/// `134,00` — a source column that does not read to a Set H character.
/// The 1962 compiler replaced such a character (by 0 in internal text and
/// by $ in external text); we substitute a blank instead — a recorded M1
/// design decision.
const Message msgUnreadableColumn = Message(
  '134,00',
  2,
  r'ILLEGAL CHARACTER REPLACED IN INTERNAL TEXT BY 0, AND IN EXTERNAL '
      r'TEXT BY $.',
);

/// `134,00` again — a Set H character that is illegal in procedure text
/// outside a literal (e.g. `$`).
const Message msgIllegalCharacter = msgUnreadableColumn;

/// Ours — a period that neither terminates the sentence nor joins a word
/// or number. No 90.04 entry covers it.
const Message msgStrayPeriod = Message.ours(
  1,
  'PERIOD NOT FOLLOWED BY BLANK AND NOT PART OF A WORD IS IGNORED.',
);

/// Ours — a word longer than the 30-character name maximum (F p. 15,
/// rule 3). No 90.04 entry covers it.
const Message msgNameTooLong = Message.ours(
  3,
  "'NAME.1' EXCEEDS 30 CHARACTERS.",
);
