import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

SourceCard _card(String line) => SourceCard(mirrorToDeck('$line\n').single, 1);

void main() {
  test(r'a $CMPLE card parses deck.name and its option list', () {
    final diagnostics = <Diagnostic>[];
    final CompileCard card = parseCompileCard(
      _card(r'$CMPLE PAYROL  LIST,DICT,NOGO'),
      diagnostics,
      pedantic: true,
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

  test(
    'a deck.name with imbedded blanks draws 923 under --pedantic (D7.11)',
    () {
      final SourceCard source = _card(r'$CMPLE PA ROL LIST');
      final plainDiagnostics = <Diagnostic>[];
      final CompileCard plainCard = parseCompileCard(source, plainDiagnostics)!;
      expect(plainDiagnostics, isEmpty);
      final pedanticDiagnostics = <Diagnostic>[];
      final CompileCard pedanticCard = parseCompileCard(
        source,
        pedanticDiagnostics,
        pedantic: true,
      )!;
      expect(pedanticDiagnostics.single.message, msgDeckNameImbeddedBlanks);
      expect(pedanticDiagnostics.single.operands, ['PA ROL']);
      // The stored deck.name is unchanged (D11.4).
      expect(pedanticCard.deckName, plainCard.deckName);
    },
  );
}
