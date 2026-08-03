/// The reserved-word and key-word tables.
///
/// J28-6169 classifies its key words in three lists (J 02.03.02–02.03.03);
/// the table keeps each word's list number so the scope of each bar is
/// enforced correctly (decision D1.5). F28-8043's flat 73-word list
/// (F p. 110, Appendix 2) is kept for reference and for `--pedantic`
/// checks against the 1960 language. Reservation under J is contextual,
/// not global: only list 1 is barred in every division.
library;

/// How strongly a J key word is reserved (J 02.03.02–02.03.03).
enum KeyWordClass {
  /// List 1: "always interpreted as Key words and may not be used as
  /// programmer names in any division."
  alwaysKey,

  /// List 2: "may not be used as Data or Procedure names."
  notDataOrProcedureName,

  /// List 3: "may be used as Procedure and Data names providing it is
  /// not necessary to reference the procedure or data items in the
  /// Environment Division."
  environmentConditional,
}

/// The 118 J key words with their list classification.
const Map<String, KeyWordClass> jKeyWords = {
  // List 1 (J 02.03.02) — 13 words.
  'BEGIN': KeyWordClass.alwaysKey,
  'FILE': KeyWordClass.alwaysKey,
  'FOR': KeyWordClass.alwaysKey,
  'HIGH.VALUE': KeyWordClass.alwaysKey,
  'HIGH.VALUES': KeyWordClass.alwaysKey,
  'IN': KeyWordClass.alwaysKey,
  'LOW.VALUE': KeyWordClass.alwaysKey,
  'LOW.VALUES': KeyWordClass.alwaysKey,
  'ON': KeyWordClass.alwaysKey,
  'RECORD': KeyWordClass.alwaysKey,
  'WHEN': KeyWordClass.alwaysKey,
  'ZERO': KeyWordClass.alwaysKey,
  'ZEROS': KeyWordClass.alwaysKey,
  // List 2 (J 02.03.02) — 56 words.
  'ABS': KeyWordClass.notDataOrProcedureName,
  'ADD': KeyWordClass.notDataOrProcedureName,
  'ALL': KeyWordClass.notDataOrProcedureName,
  'AND': KeyWordClass.notDataOrProcedureName,
  'AT': KeyWordClass.notDataOrProcedureName,
  'BLANK': KeyWordClass.notDataOrProcedureName,
  'BLANKS': KeyWordClass.notDataOrProcedureName,
  'CALL': KeyWordClass.notDataOrProcedureName,
  'CLOSE': KeyWordClass.notDataOrProcedureName,
  'COMMERCIAL': KeyWordClass.notDataOrProcedureName,
  'CORRESPONDING': KeyWordClass.notDataOrProcedureName,
  'CRYPT': KeyWordClass.notDataOrProcedureName,
  'DISPLAY': KeyWordClass.notDataOrProcedureName,
  'DO': KeyWordClass.notDataOrProcedureName,
  'END': KeyWordClass.notDataOrProcedureName,
  'ENTER': KeyWordClass.notDataOrProcedureName,
  'EQUAL': KeyWordClass.notDataOrProcedureName,
  'EQUALS': KeyWordClass.notDataOrProcedureName,
  'EXACTLY': KeyWordClass.notDataOrProcedureName,
  'FILES': KeyWordClass.notDataOrProcedureName,
  'FROM': KeyWordClass.notDataOrProcedureName,
  'GET': KeyWordClass.notDataOrProcedureName,
  'GIVING': KeyWordClass.notDataOrProcedureName,
  'GO': KeyWordClass.notDataOrProcedureName,
  'GREATER': KeyWordClass.notDataOrProcedureName,
  'GT': KeyWordClass.notDataOrProcedureName,
  'HERE': KeyWordClass.notDataOrProcedureName,
  'IF': KeyWordClass.notDataOrProcedureName,
  'INCLUDE': KeyWordClass.notDataOrProcedureName,
  'IS': KeyWordClass.notDataOrProcedureName,
  'LESS': KeyWordClass.notDataOrProcedureName,
  'LIBRARY': KeyWordClass.notDataOrProcedureName,
  'LOAD': KeyWordClass.notDataOrProcedureName,
  'LT': KeyWordClass.notDataOrProcedureName,
  'MOVE': KeyWordClass.notDataOrProcedureName,
  'NOT': KeyWordClass.notDataOrProcedureName,
  'NOTE': KeyWordClass.notDataOrProcedureName,
  'OPEN': KeyWordClass.notDataOrProcedureName,
  'OR': KeyWordClass.notDataOrProcedureName,
  'OTHERWISE': KeyWordClass.notDataOrProcedureName,
  'OVERFLOW': KeyWordClass.notDataOrProcedureName,
  'OVERLAP': KeyWordClass.notDataOrProcedureName,
  'QUANTITY': KeyWordClass.notDataOrProcedureName,
  'RUN': KeyWordClass.notDataOrProcedureName,
  'SECTION': KeyWordClass.notDataOrProcedureName,
  'SET': KeyWordClass.notDataOrProcedureName,
  'STOP': KeyWordClass.notDataOrProcedureName,
  'THAN': KeyWordClass.notDataOrProcedureName,
  'THEN': KeyWordClass.notDataOrProcedureName,
  'TIMES': KeyWordClass.notDataOrProcedureName,
  'TO': KeyWordClass.notDataOrProcedureName,
  'TR': KeyWordClass.notDataOrProcedureName,
  'TRANSLATOR': KeyWordClass.notDataOrProcedureName,
  'TRUNCATED': KeyWordClass.notDataOrProcedureName,
  'USING': KeyWordClass.notDataOrProcedureName,
  'WITH': KeyWordClass.notDataOrProcedureName,
  // List 3 (J 02.03.03) — 49 words.
  'ACTIVITY': KeyWordClass.environmentConditional,
  'BCD': KeyWordClass.environmentConditional,
  'BINARY': KeyWordClass.environmentConditional,
  'BLOCK': KeyWordClass.environmentConditional,
  'BLOCKSIZE': KeyWordClass.environmentConditional,
  'BUFFERCOUNT': KeyWordClass.environmentConditional,
  'CARD': KeyWordClass.environmentConditional,
  'CHECKC': KeyWordClass.environmentConditional,
  'CHECKF': KeyWordClass.environmentConditional,
  'CHECKPOINT': KeyWordClass.environmentConditional,
  'CKSUMS': KeyWordClass.environmentConditional,
  'CLOSER': KeyWordClass.environmentConditional,
  'CLOSEW': KeyWordClass.environmentConditional,
  'COLLATE': KeyWordClass.environmentConditional,
  'COM': KeyWordClass.environmentConditional,
  'CONSERVE': KeyWordClass.environmentConditional,
  'CONTROL': KeyWordClass.environmentConditional,
  'DEFER': KeyWordClass.environmentConditional,
  'ERROR': KeyWordClass.environmentConditional,
  'FIND': KeyWordClass.environmentConditional,
  'HIGH': KeyWordClass.environmentConditional,
  'HOLD': KeyWordClass.environmentConditional,
  'INPUT': KeyWordClass.environmentConditional,
  'KEYS': KeyWordClass.environmentConditional,
  'LABEL': KeyWordClass.environmentConditional,
  'LABELN': KeyWordClass.environmentConditional,
  'LABELS': KeyWordClass.environmentConditional,
  'LENGTH': KeyWordClass.environmentConditional,
  'LOW': KeyWordClass.environmentConditional,
  'MULTI': KeyWordClass.environmentConditional,
  'NO': KeyWordClass.environmentConditional,
  'OPENCOUNT': KeyWordClass.environmentConditional,
  'OPENF': KeyWordClass.environmentConditional,
  'OPENW': KeyWordClass.environmentConditional,
  'OUTPUT': KeyWordClass.environmentConditional,
  'PLACE': KeyWordClass.environmentConditional,
  'PRIMARY': KeyWordClass.environmentConditional,
  'REEL': KeyWordClass.environmentConditional,
  'RETAIN': KeyWordClass.environmentConditional,
  'SEQ': KeyWordClass.environmentConditional,
  'SERIAL': KeyWordClass.environmentConditional,
  'SPACE': KeyWordClass.environmentConditional,
  'SPANS': KeyWordClass.environmentConditional,
  'TAPE': KeyWordClass.environmentConditional,
  'THROUGH': KeyWordClass.environmentConditional,
  'TIME': KeyWordClass.environmentConditional,
  'UNIT1': KeyWordClass.environmentConditional,
  'UNIT2': KeyWordClass.environmentConditional,
  'WORD': KeyWordClass.environmentConditional,
};

/// F28-8043's flat reserved-word list, 73 words (F p. 110, Appendix 2):
/// "All those words which are a fixed part of the Commercial Translator
/// vocabulary."
const Set<String> fReservedWords = {
  'ABS', 'ADD', 'ALL', 'AND', 'AS', 'AT', 'BEGIN', 'BLANK', 'BLANKS',
  'CALL', 'CLOSE', 'COMMERCIAL', 'COND', 'COPY', 'CORRESPONDING',
  'DISPLAY', 'DO', 'END', 'ENTER', 'EQUAL', 'EXACTLY', 'FILE', 'FILES',
  'FOR', 'FROM', 'FUNCT', 'GET', 'GIVING', 'GO', 'GREATER', 'GT', 'HERE',
  'HIGH.VALUE', 'HIGH.VALUES', 'IF', 'IN', 'INCLUDE', 'IS', 'LABEL',
  'LESS', 'LIBRARY', 'LOAD', 'LOW.VALUE', 'LOW.VALUES', 'LT', 'MOVE',
  'NOT', 'NOTE', 'ON', 'OPEN', 'OR', 'OTHERWISE', 'OVERFLOW', 'OVERLAP',
  'PARAM', 'QUANTITY', 'RECORD', 'REDEF', 'SECTION', 'SET', 'STOP',
  'THAN', 'THEN', 'TIMES', 'TO', 'TR', 'TRANSLATOR', 'TRUNCATED',
  'USING', 'WHEN', 'WITH', 'ZERO', 'ZEROS', //
};

/// F's daggered subset: "These words have a restricted usage only in
/// data description; they may be used freely in procedure description"
/// (F p. 110).
const Set<String> fRestrictedInDataDescription = {
  'COND', 'COPY', 'FUNCT', 'LABEL', 'LIBRARY', 'PARAM', 'QUANTITY',
  'REDEF', //
};

/// PROGRAM.START is a reserved procedure-name in the 7090 implementation
/// (J 90.04, messages 141,00–143,00; decision D2.1). It appears in no
/// key-word list.
const String programStartName = 'PROGRAM.START';

/// PATTERN is registered as a reserved FILE-card word so the illegal-word
/// check cannot claim it, pending its M5 syntax (decision D9.12).
const String patternFileCardWord = 'PATTERN';

/// The J classification of [word], or `null` when it is not a J key word.
KeyWordClass? keyWordClassOf(String word) => jKeyWords[word];
