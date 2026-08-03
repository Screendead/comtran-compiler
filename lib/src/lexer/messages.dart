/// The J 90.04 error-message catalog — the diagnostic vocabulary.
///
/// Message numbers and texts are verbatim from Appendix 90.04 ("ERROR
/// MESSAGES AND SEVERITY CODES"), stored byte for byte as printed,
/// including continuation-line indentation (decision D9.5). Severity
/// values live in the separate severity table (`severities.dart`,
/// decision D9.2); no severity constant appears in compiler code. This
/// file holds the messages the M1 scanners can issue; M2 grows it toward
/// the full catalog with the golden byte-comparison of D9.5.
///
/// Messages of ours — conditions the 1962 catalog has no entry for —
/// carry ids outside the 0–209 range (decision D9.7) and close with
/// `(NON-HISTORICAL.)` so no listing line can pass as a 1962 artifact.
library;

/// One catalog entry.
final class Message {
  /// Creates the catalog entry [number] with verbatim [text].
  const Message(this.number, this.text) : nonHistorical = false;

  /// Creates a message of ours, with an id outside the 0–209 catalog
  /// range (decision D9.7).
  const Message.ours(this.number, this.text) : nonHistorical = true;

  /// The catalog id, e.g. `62,00`. Never printed in a listing (decision
  /// D9.5: the NUMBER column carries the statement number).
  final String number;

  /// The MESSAGE column text with `'NAME.1'`-style parameters. Verbatim
  /// for catalog entries; ours are marked `(NON-HISTORICAL.)`.
  final String text;

  /// Whether this message is our invention rather than a 90.04 entry.
  final bool nonHistorical;

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

/// `1,00` — a FILE environment card without a name.
const Message msgFileCardLacksName = Message(
  '1,00',
  '-FILE- CARD LACKS NAME IN COLUMNS 7 THROUGH 22.',
);

/// `52,00` — an over-long numeric literal or constant.
const Message msgNumericLengthExceeded = Message(
  '52,00',
  'MAXIMUM NUMERIC LENGTH EXCEEDED FOR CONSTANT OR LITERAL.',
);

/// `53,00` — a malformed numeric or floating point form.
const Message msgIncorrectNumericForm = Message(
  '53,00',
  'INCORRECT USAGE OF PERIOD, SIGN, OR F FOR CONSTANT OR LITERAL.',
);

/// `62,00` — a new statement began while the previous sentence was open.
const Message msgPeriodAssumed = Message(
  '62,00',
  'PREVIOUS CARD NOT PROPERLY TERMINATED. PERIOD ASSUMED.',
);

/// `88,00` — a COND environment card without a name.
const Message msgCondCardLacksName = Message(
  '88,00',
  '-COND- CARD LACKS NAME IN COLUMNS 7 THROUGH 22.',
);

/// `100,00` — a pictorial longer than 30 characters.
const Message msgPictorialTooLong = Message(
  '100,00',
  'DATA DESCRIPTION CONTAINS PICTORIAL WHICH EXCEEDS LEGAL LIMIT OF 30 '
      'CHARACTERS.',
);

/// `134,00` — a source column that does not read to a source character
/// (decision D9.10: the character gate; one message per illegal column,
/// digit zero in the internal text, dollar sign in the external text).
const Message msgIllegalCharacterReplaced = Message(
  '134,00',
  r'ILLEGAL CHARACTER REPLACED IN INTERNAL TEXT BY 0, AND IN EXTERNAL '
      r'TEXT BY $.',
);

/// `144,00` — an environment card whose type field holds no legal code.
const Message msgIllegalEnvironmentType = Message(
  '144,00',
  'ILLEGAL ENVIRONMENT CARD TYPE.',
);

/// `148,00` — a Data Description alphabetic constant longer than our
/// 120-character limit (decision D7.9; the 1962 capacity is unstated).
const Message msgConstantTooLong = Message(
  '148,00',
  'LENGTH OF ALPHABETIC CONSTANT EXCEEDS INTERNAL TABLE CAPACITY AND '
      'SHOULD BE SUBDIVIDED.',
);

/// `150,00` — an alphameric literal longer than 50 characters.
const Message msgLiteralTooLong = Message(
  '150,00',
  'ALPHABETIC LITERAL EXCEEDS 50 CHARACTERS.',
);

/// `167,00` — a literal with no closing quotation mark (decision D1.1:
/// issued when nothing follows for the literal to extend into).
const Message msgSecondQuoteMissing = Message(
  '167,00',
  'SECOND QUOTE MARK MISSING.',
);

/// `168,00` — a literal still open at its card's end with more of the
/// statement to come (decision D1.1).
const Message msgLiteralAcrossCards = Message(
  '168,00',
  'ALPHABETIC LITERAL EXTENDS ACROSS CARDS.',
);

/// `186,00` — fixed-field content on a continuation card. The stored
/// text keeps the printed continuation line and its indentation
/// (decision D9.5).
const Message msgFixedFieldOnContinuation = Message(
  '186,00',
  'DATA OR ENVIRONMENT FIXED FIELD INFORMATION SHOULD BE PUNCHED IN ONLY '
      'THE FIRST CARD\n'
      '                    OF A MULTIPLE CARD GROUP. POSSIBLE CONTINUATION '
      'CHARACTER ERROR.',
);

/// `189,00` — an illegal Mode character.
const Message msgIllegalMode = Message(
  '189,00',
  'EXTERNAL MODE SUBSTITUTED FOR ILLEGAL MODE CHARACTER.',
);

/// `190,00` — an illegal Justification character.
const Message msgIllegalJustification = Message(
  '190,00',
  'FIELD IS NOT JUSTIFIED BECAUSE OF ILLEGAL JUSTIFICATION CHARACTER.',
);

/// `194,00` — a data description entry without a level number.
const Message msgDataNameLacksLevel = Message(
  '194,00',
  'DATA NAME LACKS LEVEL.',
);

/// Ours — a period that neither terminates the sentence nor joins a word
/// or number. No 90.04 entry covers the condition.
const Message msgStrayPeriod = Message.ours(
  '900,00',
  'PERIOD NOT FOLLOWED BY BLANK AND NOT PART OF A WORD IS IGNORED. '
      '(NON-HISTORICAL.)',
);

/// Ours — a word longer than the 30-character name maximum (F p. 15,
/// rule 3). No 90.04 entry covers the condition.
const Message msgNameTooLong = Message.ours(
  '901,00',
  "'NAME.1' EXCEEDS 30 CHARACTERS. (NON-HISTORICAL.)",
);

/// Ours — source text before the first division header (decision D2.3:
/// no J diagnostic covers the case; message text and severity are a
/// recorded design decision).
const Message msgTextBeforeHeader = Message.ours(
  '902,00',
  'CARD PRECEDES THE FIRST DIVISION HEADER AND IS IGNORED. '
      '(NON-HISTORICAL.)',
);
