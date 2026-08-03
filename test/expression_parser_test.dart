import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

// Scans `text` as one unlabeled procedure sentence and returns its
// tokens (the terminator period excluded by the scanner).
List<Token> _tokens(String text) {
  final List<CardImage> deck = mirrorToDeck('${' ' * 12}$text.\n');
  final ProcedureScan scan = scanProcedure([SourceCard(deck.single, 1)]);
  expect(scan.diagnostics, isEmpty, reason: 'scan must be clean');
  return scan.sentences.single.tokens;
}

(ArithExpr, List<Diagnostic>) _arith(String text) {
  final diagnostics = <Diagnostic>[];
  final List<Token> tokens = _tokens(text);
  final cursor = TokenCursor(tokens, tokens.first.card);
  final ArithExpr expr = parseArithExpr(cursor, diagnostics);
  expect(cursor.atEnd, isTrue, reason: 'all tokens consumed');
  return (expr, diagnostics);
}

(CondExpr, List<Diagnostic>) _cond(String text) {
  final diagnostics = <Diagnostic>[];
  final List<Token> tokens = _tokens(text);
  final cursor = TokenCursor(tokens, tokens.first.card);
  final CondExpr expr = parseCondExpr(cursor, diagnostics);
  expect(cursor.atEnd, isTrue, reason: 'all tokens consumed');
  return (expr, diagnostics);
}

// Renders an expression tree as a parenthesized string for shape
// assertions.
String _shape(ArithExpr expr) => switch (expr) {
  NameOperand(:final name) => name.text,
  LiteralOperand(:final literal) => literal.text,
  FigurativeOperand(:final word) => word.text,
  BinaryExpr(:final left, :final operator, :final right) =>
    '(${_shape(left)}${operator.text}${_shape(right)})',
  UnaryExpr(:final operator, :final operand) =>
    '(${operator.text}${_shape(operand)})',
  TruthExpr() => 'TR(...)',
  FunctionCall(:final function, :final arguments) =>
    '${function.text}((${arguments.map((NameReference a) => a.text).join(',')}))',
};

void main() {
  group('arithmetic precedence (J 02.04.05.01)', () {
    test("the manual's worked example groups as printed", () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith(
        'A+B/C+D**E*F',
      );
      expect(diagnostics, isEmpty);
      expect(_shape(expr), '((A+(B/C))+((D**E)*F))');
    });

    test('equal levels group left to right (F p. 107)', () {
      final (ArithExpr expr, _) = _arith('A*B/C*D');
      expect(_shape(expr), '(((A*B)/C)*D)');
    });

    test('negation binds above ** (D4.4)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith('-A**2');
      expect(diagnostics, isEmpty);
      expect(_shape(expr), '((-A)**2)');
    });

    test('A**B**C draws 913 and groups left for recovery (D4.10)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith('A**B**C');
      expect(diagnostics.single.message, msgUnparenthesizedPower);
      expect(_shape(expr), '((A**B)**C)');
      expect((expr as BinaryExpr).recovered, isTrue);
    });

    test('a unary minus after an operator draws 192 (F p. 27 rule 6)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith('A * -B');
      expect(diagnostics.single.message, msgSentenceStructureError);
      expect(_shape(expr), '(A*(-B))');
      final (_, List<Diagnostic> clean) = _arith('A * (-B)');
      expect(clean, isEmpty);
    });

    test('a signed literal after an operator is the sign (F p. 18)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith('1.5 -20');
      expect(diagnostics, isEmpty);
      expect(_shape(expr), '(1.5-20)');
    });
  });

  group('operands', () {
    test('a qualified name is one operand (§1.5)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith(
        'MASTER RATE + 1',
      );
      expect(diagnostics, isEmpty);
      expect(_shape(expr), '(MASTER RATE+1)');
    });

    test('subscripts parse; a fourth draws 914 (D3.1)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith(
        'TABLE.ITEM (I, J)',
      );
      expect(diagnostics, isEmpty);
      expect((expr as NameOperand).name.subscripts, hasLength(2));
      final (_, List<Diagnostic> four) = _arith('T (I, J, K, L)');
      expect(four.single.message, msgTooManySubscripts);
    });

    test('per-level subscripts interleave with qualifiers (F p. 30)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith(
        'PAGE (150) LINE (10) WORD (4) + 1',
      );
      expect(diagnostics, isEmpty);
      final BinaryExpr sum = expr as BinaryExpr;
      final NameReference name = (sum.left as NameOperand).name;
      expect(name.text, 'PAGE LINE WORD');
      expect(name.subscripts, hasLength(3));
    });

    test('a signed literal follows any operator silently (F p. 18)', () {
      final (ArithExpr minus, List<Diagnostic> onMinus) = _arith('A * -5');
      expect(onMinus, isEmpty);
      expect(_shape(minus), '(A*(-5))');
      final (ArithExpr plus, List<Diagnostic> onPlus) = _arith('A * +5');
      expect(onPlus, isEmpty);
      expect(_shape(plus), '(A*5)');
    });

    test('ABS may follow another operator (F p. 27 rule 6)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith(
        'A * ABS B',
      );
      expect(diagnostics, isEmpty);
      expect(_shape(expr), '(A*(ABSB))');
    });

    test('a redundant right parenthesis is eliminated (msg 113)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith(') A + B');
      expect(diagnostics.single.message, msgRedundantRightParen);
      expect(_shape(expr), '(A+B)');
    });

    test('a function call takes double parentheses (F p. 28 rule 15)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith(
        '2 * SQUARE.ROOT ((X))',
      );
      expect(diagnostics, isEmpty);
      expect(_shape(expr), '(2*SQUARE.ROOT((X)))');
    });

    test('TR takes a parenthesized condition (F p. 45)', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith(
        'ORDER.AMT * TR (STOCK.LEVEL LT ORDER.POINT)',
      );
      expect(diagnostics, isEmpty);
      final BinaryExpr product = expr as BinaryExpr;
      final TruthExpr tr = product.right as TruthExpr;
      final Relation relation = tr.condition as Relation;
      expect(relation.op, RelationOp.less);
    });

    test('an alphameric literal outside TR draws 912', () {
      final (_, List<Diagnostic> diagnostics) = _arith("'X' + 1");
      expect(diagnostics.first.message, msgAlphamericArithOperand);
    });

    test('a missing operand draws 116 and assumes zero', () {
      final (ArithExpr expr, List<Diagnostic> diagnostics) = _arith('A +');
      expect(diagnostics.single.message, msgMissingOperand);
      expect(_shape(expr), '(A+0)');
    });

    test('an unclosed parenthesis draws 114', () {
      final (_, List<Diagnostic> diagnostics) = _arith('(A + B');
      expect(diagnostics.single.message, msgRedundantLeftParen);
    });
  });

  group('conditional expressions (§5.3)', () {
    test('AND binds above OR (F p. 105 rule 3)', () {
      final (CondExpr expr, List<Diagnostic> diagnostics) = _cond(
        'A GT B AND C LT D OR E = F',
      );
      expect(diagnostics, isEmpty);
      final OrExpr or = expr as OrExpr;
      expect(or.left, isA<AndExpr>());
      expect(or.right, isA<Relation>());
    });

    test('the full and abbreviated relation spellings agree (F p. 21)', () {
      for (final String text in ['X IS NOT EQUAL TO Y', 'X NOT = Y']) {
        final (CondExpr expr, List<Diagnostic> diagnostics) = _cond(text);
        expect(diagnostics, isEmpty, reason: text);
        final Relation relation = expr as Relation;
        expect(relation.op, RelationOp.equal, reason: text);
        expect(relation.negated, isTrue, reason: text);
      }
    });

    test('a figurative constant is a comparison operand (J 02.04.01)', () {
      final (CondExpr expr, List<Diagnostic> diagnostics) = _cond(
        'D.EMP.NO = HIGH.VALUE',
      );
      expect(diagnostics, isEmpty);
      expect((expr as Relation).right, isA<FigurativeOperand>());
    });

    test('a bare name is a condition-name test (F p. 22)', () {
      final (CondExpr expr, List<Diagnostic> diagnostics) = _cond(
        'NOT MARRIED',
      );
      expect(diagnostics, isEmpty);
      final NotExpr not = expr as NotExpr;
      expect((not.operand as ConditionReference).name.text, 'MARRIED');
    });

    test('a subscripted condition-name draws 910 (D5.6)', () {
      final (_, List<Diagnostic> diagnostics) = _cond('MARRIED (I)');
      expect(diagnostics.single.message, msgSubscriptedConditionName);
    });

    test('the verbose relation spellings parse (F p. 21)', () {
      final (CondExpr greater, List<Diagnostic> onGreater) = _cond(
        'X IS GREATER THAN Y',
      );
      expect(onGreater, isEmpty);
      expect((greater as Relation).op, RelationOp.greater);
      expect(greater.negated, isFalse);
      final (CondExpr less, List<Diagnostic> onLess) = _cond(
        'X IS NOT LESS THAN Y',
      );
      expect(onLess, isEmpty);
      expect((less as Relation).op, RelationOp.less);
      expect(less.negated, isTrue);
    });

    test('a hybrid relation spelling draws 107 (M2-17)', () {
      for (final String text in [
        'X GREATER THAN Y',
        'X EQUAL Y',
        'X IS GT Y',
      ]) {
        final (CondExpr expr, List<Diagnostic> diagnostics) = _cond(text);
        expect(diagnostics.single.message, msgIllegalComparison, reason: text);
        expect(expr, isA<Relation>(), reason: text);
      }
    });

    test('a parenthesized left operand is not a grouped condition', () {
      final (CondExpr expr, List<Diagnostic> diagnostics) = _cond(
        '(A + B) GT C',
      );
      expect(diagnostics, isEmpty);
      expect((expr as Relation).left, isA<BinaryExpr>());
      final (CondExpr grouped, _) = _cond('(A GT B OR MARRIED) AND C LT D');
      expect((grouped as AndExpr).left, isA<OrExpr>());
    });

    test('NOT NOT draws 107 (F p. 106 rule 4)', () {
      final (_, List<Diagnostic> diagnostics) = _cond('NOT NOT MARRIED');
      expect(diagnostics.first.message, msgIllegalComparison);
    });
  });
}
