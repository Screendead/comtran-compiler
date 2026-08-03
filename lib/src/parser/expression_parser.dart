/// The expression parsers (M2): arithmetic (definition §4.1;
/// J 02.04.05) and conditional (§5.3; F pp. 21–24, 105–106), over a
/// shared token cursor the clause parsers also use.
///
/// Precedence (J 02.04.05.01): unary negation, ABS, and TR bind
/// tightest — above `**` (D4.4) — then `**`, then `* /`, then `+ -`,
/// left-associative within a level. `A**B**C` is rejected and grouped
/// left for recovery only (D4.10). Two successive operators are illegal
/// unless the second is TR or ABS (F p. 27 rule 6).
library;

import '../ast/procedure_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/reserved_words.dart';
import '../lexer/source_card.dart';
import '../lexer/token.dart';
import 'parser_messages.dart';

/// The figurative constants (F pp. 19–20).
const Set<String> figurativeConstants = {
  'ZERO', 'ZEROS', 'BLANK', 'BLANKS', //
  'HIGH.VALUE', 'HIGH.VALUES', 'LOW.VALUE', 'LOW.VALUES',
};

/// Whether [word] can never form part of a data or procedure name:
/// J's list 1 (barred everywhere) and list 2 (barred as Data or
/// Procedure names). List-3 words are legal names and never end a name
/// run (J 02.03.02–03).
bool isNameStopWord(String word) {
  final KeyWordClass? keyWordClass = keyWordClassOf(word);
  return keyWordClass == KeyWordClass.alwaysKey ||
      keyWordClass == KeyWordClass.notDataOrProcedureName;
}

/// A cursor over one sentence's tokens.
final class TokenCursor {
  /// Creates the cursor over [tokens], anchored to [sentenceCard] for
  /// diagnostics at end-of-sentence positions.
  TokenCursor(this.tokens, this.sentenceCard);

  /// The sentence's tokens.
  final List<Token> tokens;

  /// The card diagnostics anchor to when the cursor is at the end.
  final SourceCard sentenceCard;

  /// The current position.
  int position = 0;

  /// Whether every token is consumed.
  bool get atEnd => position >= tokens.length;

  /// The token at the cursor plus [offset], or `null` past the end.
  Token? peek([int offset = 0]) =>
      position + offset < tokens.length ? tokens[position + offset] : null;

  /// Consumes and returns the current token.
  Token take() => tokens[position++];

  /// Whether the current token is the symbol [text].
  bool isSymbol(String text, [int offset = 0]) {
    final Token? token = peek(offset);
    return token != null &&
        token.kind == TokenKind.symbol &&
        token.text == text;
  }

  /// Whether the current token is the word [text].
  bool isWord(String text, [int offset = 0]) {
    final Token? token = peek(offset);
    return token != null && token.kind == TokenKind.word && token.text == text;
  }

  /// Consumes the symbol [text] when it is next; reports success.
  bool takeSymbol(String text) {
    if (isSymbol(text)) {
      position++;
      return true;
    }
    return false;
  }

  /// Consumes the word [text] when it is next; reports success.
  bool takeWord(String text) {
    if (isWord(text)) {
      position++;
      return true;
    }
    return false;
  }

  /// The card a diagnostic at the cursor anchors to.
  SourceCard get card => peek()?.card ?? sentenceCard;

  /// The column a diagnostic at the cursor anchors to.
  int? get column => peek()?.column;
}

/// Parses a possibly qualified, possibly subscripted name reference
/// (§1.5; D2.5). The cursor must stand on a name word. Subscripts are
/// written after the final word or per level, interleaved with the
/// qualifier words — `PAGE (150) LINE (10) WORD (4)` and
/// `PAGE LINE WORD (150, 10, 4)` are equivalent (F p. 30) — and the
/// groups flatten in word order. At most three subscripts in total
/// (F p. 30; D3.1 — msg 914 beyond).
NameReference parseNameReference(
  TokenCursor cursor,
  List<Diagnostic> diagnostics,
) {
  final words = <Token>[cursor.take()];
  final subscripts = <ArithExpr>[];
  while (true) {
    if (cursor.isSymbol('(') && !cursor.isSymbol('(', 1)) {
      // A subscript group (a double parenthesis is a function call).
      cursor.take();
      subscripts.add(parseArithExpr(cursor, diagnostics));
      while (cursor.takeSymbol(',')) {
        subscripts.add(parseArithExpr(cursor, diagnostics));
      }
      if (!cursor.takeSymbol(')')) {
        diagnostics.add(
          Diagnostic(msgRedundantLeftParen, cursor.card, column: cursor.column),
        );
        break;
      }
      continue;
    }
    final Token? next = cursor.peek();
    if (next == null ||
        next.kind != TokenKind.word ||
        isNameStopWord(next.text) ||
        figurativeConstants.contains(next.text)) {
      break;
    }
    words.add(cursor.take());
  }
  if (subscripts.length > 3) {
    diagnostics.add(
      Diagnostic(
        msgTooManySubscripts,
        words.first.card,
        column: words.first.column,
      ),
    );
  }
  for (final subscript in subscripts) {
    // A subscript is a name, a literal, or `a * VARIABLE ± b` — never a
    // figurative constant (F p. 31; design note M2-8).
    rejectNestedFigurative(subscript, diagnostics, sole: false);
  }
  return NameReference(words, subscripts);
}

/// Diagnoses a figurative constant inside a larger expression with
/// msg 192 — a key word misused (design note M2-8; D1.5). With [sole]
/// a whole-expression figurative is legal (a SET value, J 02.04.01, or
/// a comparison operand); nested ones never are.
void rejectNestedFigurative(
  ArithExpr expr,
  List<Diagnostic> diagnostics, {
  required bool sole,
}) {
  switch (expr) {
    case FigurativeOperand(:final word) when !sole:
      diagnostics.add(
        Diagnostic(msgSentenceStructureError, word.card, column: word.column),
      );
    case FigurativeOperand():
      break;
    case BinaryExpr(:final left, :final right):
      rejectNestedFigurative(left, diagnostics, sole: false);
      rejectNestedFigurative(right, diagnostics, sole: false);
    case UnaryExpr(:final operand):
      rejectNestedFigurative(operand, diagnostics, sole: false);
    case NameOperand():
    case LiteralOperand():
    case TruthExpr():
    case FunctionCall():
      break;
  }
}

/// Parses an arithmetic expression (lowest precedence: `+ -`).
ArithExpr parseArithExpr(TokenCursor cursor, List<Diagnostic> diagnostics) {
  ArithExpr left = _parseTerm(cursor, diagnostics);
  while (cursor.isSymbol('+') || cursor.isSymbol('-')) {
    final Token operator = cursor.take();
    final ArithExpr right = _parseTerm(
      cursor,
      diagnostics,
      afterOperator: true,
    );
    left = BinaryExpr(left, operator, right);
  }
  return left;
}

/// `* /` level.
ArithExpr _parseTerm(
  TokenCursor cursor,
  List<Diagnostic> diagnostics, {
  bool afterOperator = false,
}) {
  ArithExpr left = _parsePower(
    cursor,
    diagnostics,
    afterOperator: afterOperator,
  );
  while (cursor.isSymbol('*') || cursor.isSymbol('/')) {
    final Token operator = cursor.take();
    final ArithExpr right = _parsePower(
      cursor,
      diagnostics,
      afterOperator: true,
    );
    left = BinaryExpr(left, operator, right);
  }
  return left;
}

/// `**` level: one application only; a second unparenthesized `**` is
/// rejected and grouped left for recovery (F p. 107; D4.10).
ArithExpr _parsePower(
  TokenCursor cursor,
  List<Diagnostic> diagnostics, {
  bool afterOperator = false,
}) {
  ArithExpr left = _parseUnary(
    cursor,
    diagnostics,
    afterOperator: afterOperator,
  );
  var applications = 0;
  while (cursor.isSymbol('**')) {
    final Token operator = cursor.take();
    final ArithExpr right = _parseUnary(
      cursor,
      diagnostics,
      afterOperator: true,
    );
    applications++;
    if (applications > 1) {
      diagnostics.add(
        Diagnostic(
          msgUnparenthesizedPower,
          operator.card,
          column: operator.column,
        ),
      );
    }
    left = BinaryExpr(left, operator, right, recovered: applications > 1);
  }
  return left;
}

/// The unary level: negation, ABS, TR (J 02.04.05.01; D4.4). A unary
/// minus directly after a binary operator violates F p. 27 rule 6
/// (`A * -B` must be written `A * (-B)`); TR and ABS are the stated
/// exceptions.
ArithExpr _parseUnary(
  TokenCursor cursor,
  List<Diagnostic> diagnostics, {
  bool afterOperator = false,
}) {
  if (cursor.isSymbol('-')) {
    final Token operator = cursor.take();
    if (afterOperator && !_isLiteral(cursor.peek())) {
      diagnostics.add(
        Diagnostic(
          msgSentenceStructureError,
          operator.card,
          column: operator.column,
        ),
      );
    }
    if (_isLiteral(cursor.peek()) && afterOperator) {
      // A signed literal after an operator is the literal's own sign
      // (F p. 18), not a second operator.
      return UnaryExpr(operator, LiteralOperand(cursor.take()));
    }
    return UnaryExpr(operator, _parseUnaryOperand(cursor, diagnostics));
  }
  if (cursor.isSymbol('+') && _isLiteral(cursor.peek(1))) {
    // A leading plus sign on a literal (F p. 18).
    cursor.take();
    return LiteralOperand(cursor.take());
  }
  if (cursor.isWord('ABS')) {
    final Token operator = cursor.take();
    return UnaryExpr(operator, _parseUnaryOperand(cursor, diagnostics));
  }
  if (cursor.isWord('TR')) {
    return _parseTruthFunction(cursor, diagnostics);
  }
  return _parsePrimary(cursor, diagnostics);
}

bool _isLiteral(Token? token) =>
    token != null &&
    (token.kind == TokenKind.numericLiteral ||
        token.kind == TokenKind.floatingLiteral);

/// A unary operator's operand: a primary, or a parenthesized
/// expression (F p. 45).
ArithExpr _parseUnaryOperand(TokenCursor cursor, List<Diagnostic> diagnostics) {
  if (cursor.isSymbol('(')) {
    cursor.take();
    final ArithExpr inner = parseArithExpr(cursor, diagnostics);
    if (!cursor.takeSymbol(')')) {
      diagnostics.add(
        Diagnostic(msgRedundantLeftParen, cursor.card, column: cursor.column),
      );
    }
    return inner;
  }
  return _parsePrimary(cursor, diagnostics);
}

/// `TR (conditional expression)` (F p. 45).
ArithExpr _parseTruthFunction(
  TokenCursor cursor,
  List<Diagnostic> diagnostics,
) {
  final Token word = cursor.take();
  if (!cursor.takeSymbol('(')) {
    diagnostics.add(
      Diagnostic(msgIllegalComparison, word.card, column: word.column),
    );
    return TruthExpr(word, ConditionReference(NameReference([word])));
  }
  final CondExpr condition = parseCondExpr(cursor, diagnostics);
  if (!cursor.takeSymbol(')')) {
    diagnostics.add(
      Diagnostic(msgRedundantLeftParen, cursor.card, column: cursor.column),
    );
  }
  return TruthExpr(word, condition);
}

/// A primary: literal, name (with subscripts or a double-parenthesis
/// function call), figurative constant, or parenthesized expression.
ArithExpr _parsePrimary(TokenCursor cursor, List<Diagnostic> diagnostics) {
  final Token? token = cursor.peek();
  if (token == null) {
    return _missingOperand(cursor, diagnostics);
  }
  switch (token.kind) {
    case TokenKind.numericLiteral:
    case TokenKind.floatingLiteral:
      return LiteralOperand(cursor.take());
    case TokenKind.alphamericLiteral:
      // Legal only inside TR or as a comparison operand (F p. 45);
      // comparison call sites consume it before reaching here.
      diagnostics.add(
        Diagnostic(msgAlphamericArithOperand, token.card, column: token.column),
      );
      return LiteralOperand(cursor.take());
    case TokenKind.symbol:
      if (token.text == '(') {
        cursor.take();
        final ArithExpr inner = parseArithExpr(cursor, diagnostics);
        if (!cursor.takeSymbol(')')) {
          diagnostics.add(
            Diagnostic(
              msgRedundantLeftParen,
              cursor.card,
              column: cursor.column,
            ),
          );
        }
        return inner;
      }
      if (token.text == ')') {
        // A right parenthesis with nothing open (msg 113): eliminated.
        diagnostics.add(
          Diagnostic(msgRedundantRightParen, token.card, column: token.column),
        );
        cursor.take();
        return _parsePrimary(cursor, diagnostics);
      }
      return _missingOperand(cursor, diagnostics);
    case TokenKind.word:
      if (figurativeConstants.contains(token.text)) {
        // Whether a figurative constant is legal here is the caller's
        // judgment (design note M2-8).
        return FigurativeOperand(cursor.take());
      }
      if (isNameStopWord(token.text)) {
        return _missingOperand(cursor, diagnostics);
      }
      final NameReference name = parseNameReference(cursor, diagnostics);
      if (cursor.isSymbol('(') && cursor.isSymbol('(', 1)) {
        return parseFunctionCall(name, cursor, diagnostics);
      }
      return NameOperand(name);
    case TokenKind.noteText:
    case TokenKind.descriptionItem:
      return _missingOperand(cursor, diagnostics);
  }
}

/// A missing operand: msg 116, zero assumed (its stated repair); the
/// cursor does not move.
ArithExpr _missingOperand(TokenCursor cursor, List<Diagnostic> diagnostics) {
  diagnostics.add(
    Diagnostic(msgMissingOperand, cursor.card, column: cursor.column),
  );
  return LiteralOperand(
    Token(TokenKind.numericLiteral, '0', cursor.card, cursor.column ?? 72),
  );
}

/// `name ((argument, ...))` — double parentheses, single-comma
/// data-names, figurative constants included: two of F p. 34's three
/// examples pass HIGH.VALUES as an argument (F p. 28 rule 15). The
/// cursor stands on the first `(`. Shared with the verb source-operand
/// path, which recognizes the same form (F p. 34's MOVE example).
ArithExpr parseFunctionCall(
  NameReference function,
  TokenCursor cursor,
  List<Diagnostic> diagnostics,
) {
  cursor
    ..take()
    ..take();
  final arguments = <NameReference>[];
  while (true) {
    final Token? token = cursor.peek();
    if (token == null) {
      diagnostics.add(
        Diagnostic(msgRedundantLeftParen, cursor.card, column: cursor.column),
      );
      break;
    }
    if (token.kind == TokenKind.word &&
        figurativeConstants.contains(token.text)) {
      // "Note the use of the figurative constant HIGH.VALUES as a
      // data-name" (F p. 34): a one-word reference.
      arguments.add(NameReference([cursor.take()]));
    } else if (token.kind == TokenKind.word && !isNameStopWord(token.text)) {
      arguments.add(parseNameReference(cursor, diagnostics));
    } else {
      // Not a data-name (F p. 28 rule 15): the token is dropped, and
      // the message states that recovery (D10.6).
      diagnostics.add(
        Diagnostic(
          msgFunctionArgumentDropped,
          token.card,
          column: token.column,
        ),
      );
      cursor.take();
    }
    if (cursor.takeSymbol(',')) {
      continue;
    }
    if (cursor.takeSymbol(')')) {
      if (!cursor.takeSymbol(')')) {
        diagnostics.add(
          Diagnostic(msgRedundantLeftParen, cursor.card, column: cursor.column),
        );
      }
      break;
    }
    diagnostics.add(
      Diagnostic(msgRedundantLeftParen, cursor.card, column: cursor.column),
    );
    break;
  }
  return FunctionCall(function, arguments);
}

// --- Conditional expressions ---------------------------------------------

/// Parses a conditional expression (lowest precedence: OR; AND binds
/// tighter, F p. 105 rule 3).
CondExpr parseCondExpr(TokenCursor cursor, List<Diagnostic> diagnostics) {
  CondExpr left = _parseCondAnd(cursor, diagnostics);
  while (cursor.isWord('OR')) {
    cursor.take();
    left = OrExpr(left, _parseCondAnd(cursor, diagnostics));
  }
  return left;
}

CondExpr _parseCondAnd(TokenCursor cursor, List<Diagnostic> diagnostics) {
  CondExpr left = _parseCondNot(cursor, diagnostics);
  while (cursor.isWord('AND')) {
    cursor.take();
    left = AndExpr(left, _parseCondNot(cursor, diagnostics));
  }
  return left;
}

CondExpr _parseCondNot(TokenCursor cursor, List<Diagnostic> diagnostics) {
  if (cursor.isWord('NOT')) {
    final Token word = cursor.take();
    if (cursor.isWord('NOT')) {
      // `NOT NOT` is illegal token adjacency (F p. 106 rule 4).
      diagnostics.add(
        Diagnostic(msgIllegalComparison, word.card, column: word.column),
      );
    }
    return NotExpr(word, _parseCondPrimary(cursor, diagnostics));
  }
  return _parseCondPrimary(cursor, diagnostics);
}

/// A condition primary: a parenthesized condition, a relation, or a
/// condition-name.
CondExpr _parseCondPrimary(TokenCursor cursor, List<Diagnostic> diagnostics) {
  if (cursor.isSymbol('(') && _parenGroupsCondition(cursor)) {
    cursor.take();
    final CondExpr inner = parseCondExpr(cursor, diagnostics);
    if (!cursor.takeSymbol(')')) {
      diagnostics.add(
        Diagnostic(msgRedundantLeftParen, cursor.card, column: cursor.column),
      );
    }
    return inner;
  }
  return _parseRelationOrConditionName(cursor, diagnostics);
}

/// Whether the parenthesis at the cursor groups a whole condition
/// rather than an arithmetic left operand: after its matching close,
/// a relational-operator starter or AND/OR means the parenthesis was
/// an operand; a condition connective or the end means it grouped a
/// condition.
bool _parenGroupsCondition(TokenCursor cursor) {
  var depth = 0;
  int i = cursor.position;
  while (i < cursor.tokens.length) {
    final Token token = cursor.tokens[i];
    if (token.kind == TokenKind.symbol && token.text == '(') {
      depth++;
    } else if (token.kind == TokenKind.symbol && token.text == ')') {
      depth--;
      if (depth == 0) {
        final Token? after = i + 1 < cursor.tokens.length
            ? cursor.tokens[i + 1]
            : null;
        if (after == null) {
          return true;
        }
        if (after.kind == TokenKind.symbol &&
            const {'=', '+', '-', '*', '/', '**'}.contains(after.text)) {
          return false;
        }
        if (after.kind == TokenKind.word &&
            const {
              'IS', 'NOT', 'GT', 'LT', 'GREATER', 'LESS', 'EQUAL', //
            }.contains(after.text)) {
          return false;
        }
        return true;
      }
    }
    i++;
  }
  return true;
}

/// A comparison operand: an alphameric literal or figurative constant
/// directly (J 02.04.01), else an arithmetic expression. A figurative
/// constant is kept only as the whole operand, never as a sub-term
/// (design note M2-8).
ArithExpr _parseComparisonOperand(
  TokenCursor cursor,
  List<Diagnostic> diagnostics,
) {
  final Token? token = cursor.peek();
  if (token != null && token.kind == TokenKind.alphamericLiteral) {
    return LiteralOperand(cursor.take());
  }
  final ArithExpr operand = parseArithExpr(cursor, diagnostics);
  rejectNestedFigurative(operand, diagnostics, sole: true);
  return operand;
}

CondExpr _parseRelationOrConditionName(
  TokenCursor cursor,
  List<Diagnostic> diagnostics,
) {
  final ArithExpr left = _parseComparisonOperand(cursor, diagnostics);
  var negated = false;
  RelationOp? op;
  if (cursor.takeWord('IS')) {
    negated = cursor.takeWord('NOT');
    op = _takeRelationOp(cursor, diagnostics, afterIs: true);
    if (op == null) {
      diagnostics.add(
        Diagnostic(msgIllegalComparison, cursor.card, column: cursor.column),
      );
      op = RelationOp.equal;
    }
  } else if (cursor.isWord('NOT')) {
    // `operand NOT GT/LT/= …` — the abbreviated negated relation.
    cursor.take();
    negated = true;
    op = _takeRelationOp(cursor, diagnostics, afterIs: false);
    if (op == null) {
      diagnostics.add(
        Diagnostic(msgIllegalComparison, cursor.card, column: cursor.column),
      );
      op = RelationOp.equal;
    }
  } else {
    op = _takeRelationOp(cursor, diagnostics, afterIs: false);
  }
  if (op == null) {
    // No relational operator: a condition-name test (F p. 22). The
    // name may not be subscripted (J 90.01.03; D5.6, msg 910).
    if (left is NameOperand) {
      if (left.name.subscripts.isNotEmpty) {
        diagnostics.add(
          Diagnostic(
            msgSubscriptedConditionName,
            left.anchor.card,
            column: left.anchor.column,
          ),
        );
      }
      return ConditionReference(left.name);
    }
    diagnostics.add(
      Diagnostic(
        msgIllegalComparison,
        left.anchor.card,
        column: left.anchor.column,
      ),
    );
    return Relation(
      left,
      RelationOp.equal,
      _missingOperand(cursor, diagnostics),
      negated: false,
    );
  }
  final ArithExpr right = _parseComparisonOperand(cursor, diagnostics);
  return Relation(left, op, right, negated: negated);
}

/// Consumes a relational operator at the cursor, or returns `null`.
/// F p. 21 gives a closed set of spellings: the full forms
/// `IS [NOT] GREATER THAN / LESS THAN / EQUAL TO` and the abbreviated
/// forms `[NOT] GT / LT / =`. A hybrid — an abbreviation after IS, or
/// a full-form word without IS or without its THAN/TO — draws msg 107
/// and the relation is kept as a repair (design note M2-17).
RelationOp? _takeRelationOp(
  TokenCursor cursor,
  List<Diagnostic> diagnostics, {
  required bool afterIs,
}) {
  void hybrid(Token at) {
    diagnostics.add(
      Diagnostic(msgIllegalComparison, at.card, column: at.column),
    );
  }

  if (cursor.isSymbol('=') || cursor.isWord('GT') || cursor.isWord('LT')) {
    final Token token = cursor.take();
    if (afterIs) {
      hybrid(token);
    }
    return switch (token.text) {
      'GT' => RelationOp.greater,
      'LT' => RelationOp.less,
      _ => RelationOp.equal,
    };
  }
  if (cursor.isWord('GREATER') || cursor.isWord('LESS')) {
    final Token token = cursor.take();
    final bool than = cursor.takeWord('THAN');
    if (!afterIs || !than) {
      hybrid(token);
    }
    return token.text == 'GREATER' ? RelationOp.greater : RelationOp.less;
  }
  if (cursor.isWord('EQUAL')) {
    final Token token = cursor.take();
    final bool to = cursor.takeWord('TO');
    if (!afterIs || !to) {
      hybrid(token);
    }
    return RelationOp.equal;
  }
  return null;
}
