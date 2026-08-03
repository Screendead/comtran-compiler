import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

SourceCard _card(String line) => SourceCard(mirrorToDeck('$line\n').single, 1);

void main() {
  test('the 90.05 *COMPILE card parses per D7.12', () {
    final FrontEndResult result = runFrontEnd(loadPayrollDeck());
    final diagnostics = <Diagnostic>[];
    final CompileCard card = parseCompileCard(
      result.program.compileCard,
      diagnostics,
    )!;
    expect(diagnostics, isEmpty);
    expect(card.historicalSpelling, isTrue);
    expect(card.deckName, isEmpty);
    expect(card.options, ['LIST']);
    expect(card.secondaryIdentifier, 'CT PUBLICATIONS');
  });

  test(r'a $CMPLE card parses deck.name and its option list', () {
    final diagnostics = <Diagnostic>[];
    final CompileCard card = parseCompileCard(
      _card(r'$CMPLE PAYROL  LIST,DICT,NOGO'),
      diagnostics,
    )!;
    expect(diagnostics, isEmpty);
    expect(card.historicalSpelling, isFalse);
    expect(card.deckName, 'PAYROL');
    expect(card.options, ['LIST', 'DICT', 'NOGO']);
  });

  test('the first blank terminates the option list (J 02.01.01)', () {
    final diagnostics = <Diagnostic>[];
    final CompileCard card = parseCompileCard(
      _card(r'$CMPLE DECK   LIST DICT'),
      diagnostics,
    )!;
    expect(card.options, ['LIST']);
    expect(diagnostics, isEmpty);
  });

  test('an unknown option draws 909 and stays listed', () {
    final diagnostics = <Diagnostic>[];
    final CompileCard card = parseCompileCard(
      _card(r'$CMPLE DECK   LIST,FOO'),
      diagnostics,
    )!;
    expect(card.options, ['LIST', 'FOO']);
    expect(diagnostics.single.message, msgUnknownCompileOption);
    expect(diagnostics.single.operands, ['FOO']);
    expect(diagnostics.single.severity, 1);
  });

  test('a deck.name with imbedded blanks is accepted silently (D7.11)', () {
    final diagnostics = <Diagnostic>[];
    final CompileCard card = parseCompileCard(
      _card(r'$CMPLE PA ROL LIST'),
      diagnostics,
    )!;
    expect(card.deckName, 'PA ROL');
    expect(diagnostics, isEmpty);
  });

  test('no compile card parses to null', () {
    expect(parseCompileCard(null, []), isNull);
  });
}
