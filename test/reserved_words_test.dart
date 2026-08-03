import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  test('the J lists carry 13, 56, and 49 words — 118 in all', () {
    expect(jKeyWords.length, 118);
    expect(
      jKeyWords.values.where((KeyWordClass c) => c == KeyWordClass.alwaysKey),
      hasLength(13),
    );
    expect(
      jKeyWords.values.where(
        (KeyWordClass c) => c == KeyWordClass.notDataOrProcedureName,
      ),
      hasLength(56),
    );
    expect(
      jKeyWords.values.where(
        (KeyWordClass c) => c == KeyWordClass.environmentConditional,
      ),
      hasLength(49),
    );
  });

  test('the F list carries 73 words with its 8 daggered words', () {
    expect(fReservedWords, hasLength(73));
    expect(fRestrictedInDataDescription, hasLength(8));
    expect(fRestrictedInDataDescription.every(fReservedWords.contains), isTrue);
  });

  test('the union of both vocabularies is 124 words', () {
    expect({...jKeyWords.keys, ...fReservedWords}, hasLength(124));
  });

  test('documented F/J divergences hold', () {
    // Dropped by J: AS, COND, COPY, FUNCT, PARAM, REDEF.
    for (final word in [
      'AS', 'COND', 'COPY', 'FUNCT', 'PARAM', //
      'REDEF',
    ]) {
      expect(fReservedWords, contains(word));
      expect(keyWordClassOf(word), isNull, reason: word);
    }
    // New in J: CRYPT, EQUALS, RUN (list 2; decision D1.5 for EQUALS).
    for (final word in ['CRYPT', 'EQUALS', 'RUN']) {
      expect(keyWordClassOf(word), KeyWordClass.notDataOrProcedureName);
      expect(fReservedWords, isNot(contains(word)));
    }
    // Demoted: LABEL (F daggered, J list 3). Promoted: LIBRARY and
    // QUANTITY (F daggered, J list 2).
    expect(keyWordClassOf('LABEL'), KeyWordClass.environmentConditional);
    expect(keyWordClassOf('LIBRARY'), KeyWordClass.notDataOrProcedureName);
    expect(keyWordClassOf('QUANTITY'), KeyWordClass.notDataOrProcedureName);
  });

  test('reservation scope is contextual, not global', () {
    expect(keyWordClassOf('RECORD'), KeyWordClass.alwaysKey);
    expect(keyWordClassOf('MOVE'), KeyWordClass.notDataOrProcedureName);
    expect(keyWordClassOf('TAPE'), KeyWordClass.environmentConditional);
    expect(keyWordClassOf('PAYROLL'), isNull);
    expect(programStartName, 'PROGRAM.START');
    expect(patternFileCardWord, 'PATTERN');
  });
}
