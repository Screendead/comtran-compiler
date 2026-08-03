/// The Procedure Division parser (M2).
///
/// Parses the M1 scanner's sentences into clauses per the verb grammar
/// (definition §2.3–2.7, §4–§6; the D-slate calls named in place).
/// Recovery follows design note M2-13: an unrepairable sentence is
/// deleted whole (msgs 122, 125, 126, 171) and parsing resumes at the
/// next sentence; auto-repairs keep the construct. Clause numbers for
/// `n,cc` diagnostics follow design note M2-6.
library;

import '../ast/procedure_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/messages.dart';
import '../lexer/procedure_lexer.dart';
import '../lexer/reserved_words.dart';
import '../lexer/source_card.dart';
import '../lexer/token.dart';
import 'expression_parser.dart';
import 'parser_messages.dart';

/// The verbs the parser dispatches on (§2.7). GO covers GO TO; BEGIN
/// covers BEGIN SECTION.
const Set<String> _verbs = {
  'MOVE', 'SET', 'ADD', 'GO', 'DO', 'STOP', //
  'OPEN', 'GET', 'FILE', 'CLOSE', 'DISPLAY',
  'CALL', 'ENTER', 'NOTE', 'BEGIN', 'END',
  'LOAD', 'OVERLAP', 'INCLUDE', 'COPY', 'IF',
};

/// The deferred verbs (J 90.01.02–03; design note M2-11).
const Set<String> _deferredVerbs = {'LOAD', 'OVERLAP', 'INCLUDE', 'COPY'};

/// Word tokens counted against the 60-operator sentence cap
/// (J 90.04.01 msg 171; the exact 1962 counting is unattested — this
/// counts arithmetic, relational, and logical operators).
const Set<String> _operatorWords = {
  'AND', 'OR', 'NOT', 'GT', 'LT', 'GREATER', 'LESS', 'EQUAL', 'ABS', 'TR', //
};

/// Thrown to delete the sentence being parsed (design note M2-13).
final class _DeleteSentence implements Exception {
  _DeleteSentence(this.message, this.card, this.column);

  final Message message;
  final SourceCard card;
  final int? column;
}

/// The procedure parser. One instance parses every `*PROCEDURE` group
/// of a program in deck order, carrying the section stack and the
/// whole-program facts (STOP RUN, PROGRAM.START, DO targets) across
/// groups; [finishProgram] runs the end-of-text checks.
final class ProcedureParser {
  /// Creates the parser, appending to [diagnostics].
  ProcedureParser(this.diagnostics);

  /// The sink for every diagnostic.
  final List<Diagnostic> diagnostics;

  final List<String> _openSections = [];
  int _sectionCount = 0;
  bool _sawStopRun = false;
  bool _cryptMode = false;
  final List<Token> _programStartLabels = [];
  final List<NameReference> _doTargets = [];
  SourceCard? _lastCard;

  /// Parses one group's [scan] into sentences.
  List<Sentence> parseGroup(ProcedureScan scan) {
    final sentences = <Sentence>[];
    for (final ProcedureSentence sentence in scan.sentences) {
      sentences.add(_parseSentence(sentence));
      _lastCard = sentence.cards.last;
    }
    return sentences;
  }

  /// The end-of-text checks: unclosed sections (msg 66), the mandatory
  /// STOP RUN (msg 175, D2.7), and the PROGRAM.START rules that need
  /// the whole program (D2.1: msg 141 on a duplicate — issued in
  /// place — and msg 143 when a DO addresses it). [anchor] is the card
  /// program-level diagnostics attach to.
  void finishProgram(SourceCard anchor) {
    final SourceCard at = _lastCard ?? anchor;
    if (_openSections.isNotEmpty) {
      diagnostics.add(Diagnostic(msgSectionsNotClosed, at));
    }
    if (!_sawStopRun) {
      diagnostics.add(Diagnostic(msgNoStopRun, at));
    }
    if (_programStartLabels.isNotEmpty) {
      for (final NameReference target in _doTargets) {
        if (target.text == programStartName) {
          diagnostics.add(
            Diagnostic(
              msgProgramStartDoAddressed,
              target.anchor.card,
              column: target.anchor.column,
            ),
          );
        }
      }
    }
  }

  Sentence _parseSentence(ProcedureSentence scan) {
    final SourceCard card = scan.cards.first;
    final String? label = scan.label;
    if (label == programStartName) {
      if (_programStartLabels.isNotEmpty) {
        diagnostics.add(Diagnostic(msgDuplicateProgramStart, card));
      }
      _programStartLabels.add(
        Token(TokenKind.word, label!, card, scan.labelColumn ?? 7),
      );
    }
    if (_cryptMode && !_isEnterSentence(scan)) {
      // CRYPT text passes through unparsed; the CRYPT assembler is its
      // own component (D9.3), out of M2's scope.
      return Sentence(scan, const [], deleted: false);
    }
    if (scan.tokens.isEmpty) {
      // A bare labeled sentence (F p. 51's `NEXT.   .` idiom).
      return Sentence(scan, const [], deleted: false);
    }
    if (_operatorCount(scan.tokens) > 60) {
      // "SENTENCE DELETED FROM TEXT" (msg 171; J 90.01.05).
      diagnostics.add(Diagnostic(msgTooManyOperators, card));
      return Sentence(scan, const [], deleted: true);
    }
    final cursor = TokenCursor(scan.tokens, card);
    final int diagnosticsFrom = diagnostics.length;
    try {
      final List<Clause> clauses = _parseSentenceClauses(cursor, scan);
      _numberClauses(clauses, diagnosticsFrom);
      _sectionWalk(clauses, scan);
      return Sentence(scan, clauses, deleted: false);
    } on _DeleteSentence catch (deletion) {
      diagnostics.add(
        Diagnostic(deletion.message, deletion.card, column: deletion.column),
      );
      return Sentence(scan, const [], deleted: true);
    }
  }

  bool _isEnterSentence(ProcedureSentence scan) =>
      scan.tokens.isNotEmpty &&
      scan.tokens.first.kind == TokenKind.word &&
      scan.tokens.first.text == 'ENTER';

  int _operatorCount(List<Token> tokens) {
    var count = 0;
    for (final Token token in tokens) {
      if (token.kind == TokenKind.symbol && token.text != ',' ||
          token.kind == TokenKind.word && _operatorWords.contains(token.text)) {
        count++;
      }
    }
    return count;
  }

  /// The sentence's top-level clause structure: an IF clause first when
  /// present — at most one, first only (F p. 25) — else the imperative
  /// clause series.
  List<Clause> _parseSentenceClauses(
    TokenCursor cursor,
    ProcedureSentence scan,
  ) {
    if (cursor.isWord('OTHERWISE')) {
      throw _DeleteSentence(
        msgSentenceStartsOtherwise,
        cursor.card,
        cursor.column,
      );
    }
    if (cursor.isWord('IF')) {
      final Token word = cursor.take();
      final CondExpr condition = parseCondExpr(cursor, diagnostics);
      if (!cursor.takeWord('THEN')) {
        throw _DeleteSentence(
          msgIllegalSentenceStructure,
          cursor.card,
          cursor.column,
        );
      }
      final List<Clause> thenArm = _parseClauseSeries(
        cursor,
        stopAtOtherwise: true,
      );
      var otherwiseArm = const <Clause>[];
      if (cursor.takeWord('OTHERWISE')) {
        otherwiseArm = _parseClauseSeries(cursor, stopAtOtherwise: false);
      }
      _expectSentenceEnd(cursor);
      return [IfClause(word, condition, thenArm, otherwiseArm)];
    }
    final List<Clause> clauses = _parseClauseSeries(
      cursor,
      stopAtOtherwise: false,
    );
    _expectSentenceEnd(cursor);
    return clauses;
  }

  void _expectSentenceEnd(TokenCursor cursor) {
    if (!cursor.atEnd) {
      throw _DeleteSentence(
        msgIllegalSentenceStructure,
        cursor.card,
        cursor.column,
      );
    }
  }

  /// A comma-separated series of imperative clauses (F p. 27 rule 5).
  /// OTHERWISE closes the series without punctuation (F p. 25).
  List<Clause> _parseClauseSeries(
    TokenCursor cursor, {
    required bool stopAtOtherwise,
  }) {
    final clauses = <Clause>[];
    while (true) {
      clauses.add(_parseClause(cursor));
      if (cursor.atEnd) {
        return clauses;
      }
      if (stopAtOtherwise && cursor.isWord('OTHERWISE')) {
        return clauses;
      }
      if (cursor.takeSymbol(',')) {
        if (cursor.atEnd) {
          // A trailing comma before the period, as the sample's
          // `OPEN ALL FILES,` (statement 188) writes.
          return clauses;
        }
        if (stopAtOtherwise && cursor.isWord('OTHERWISE')) {
          return clauses;
        }
        continue;
      }
      final Token? next = cursor.peek();
      if (next != null &&
          next.kind == TokenKind.word &&
          _verbs.contains(next.text)) {
        // A second verb with no separating comma (msg 126).
        throw _DeleteSentence(msgStatementTwoVerbs, next.card, next.column);
      }
      return clauses;
    }
  }

  /// One imperative clause: a verb and its operands.
  Clause _parseClause(TokenCursor cursor) {
    final Token? token = cursor.peek();
    if (token == null) {
      throw _DeleteSentence(msgIncompleteStatement, cursor.card, cursor.column);
    }
    if (token.kind != TokenKind.word) {
      throw _DeleteSentence(msgStatementWithoutVerb, token.card, token.column);
    }
    switch (token.text) {
      case 'RUN':
        // RUN outside STOP RUN: the word is deleted, compilation
        // continues (msg 2; D2.7).
        diagnostics.add(
          Diagnostic(msgRunDeleted, token.card, column: token.column),
        );
        cursor.take();
        return _parseClause(cursor);
      case 'CORRESPONDING':
        // CORRESPONDING must directly follow ADD or MOVE (msg 63).
        diagnostics.add(
          Diagnostic(
            msgCorrespondingMisplaced,
            token.card,
            column: token.column,
          ),
        );
        cursor.take();
        return _parseClause(cursor);
      case 'MOVE':
        return _parseMove(cursor);
      case 'SET':
        return _parseSet(cursor);
      case 'ADD':
        return _parseAdd(cursor);
      case 'GO':
        return _parseGoTo(cursor);
      case 'DO':
        return _parseDo(cursor);
      case 'STOP':
        return _parseStop(cursor);
      case 'OPEN':
        return _parseOpenClose(cursor, open: true);
      case 'CLOSE':
        return _parseOpenClose(cursor, open: false);
      case 'GET':
        return _parseGet(cursor);
      case 'FILE':
        return _parseFile(cursor);
      case 'DISPLAY':
        return _parseDisplay(cursor);
      case 'CALL':
        return _parseCall(cursor);
      case 'ENTER':
        return _parseEnter(cursor);
      case 'NOTE':
        return _parseNote(cursor);
      case 'BEGIN':
        return _parseBeginSection(cursor);
      case 'END':
        return _parseEnd(cursor);
      default:
        if (_deferredVerbs.contains(token.text)) {
          return _parseDeferredVerb(cursor);
        }
        if (isNameStopWord(token.text)) {
          throw _DeleteSentence(
            msgSentenceStructureError,
            token.card,
            token.column,
          );
        }
        // A name where a verb belongs (msg 125).
        throw _DeleteSentence(
          msgStatementWithoutVerb,
          token.card,
          token.column,
        );
    }
  }

  /// A name expected at the cursor; [onMissing] is thrown otherwise.
  NameReference _expectName(TokenCursor cursor, Message onMissing) {
    final Token? token = cursor.peek();
    if (token == null ||
        token.kind != TokenKind.word ||
        isNameStopWord(token.text) ||
        figurativeConstants.contains(token.text)) {
      throw _DeleteSentence(onMissing, cursor.card, cursor.column);
    }
    return parseNameReference(cursor, diagnostics);
  }

  /// A comma-separated series of names, stopping before a verb.
  List<NameReference> _parseNameSeries(TokenCursor cursor, Message onMissing) {
    final names = <NameReference>[_expectName(cursor, onMissing)];
    while (cursor.isSymbol(',')) {
      final Token? next = cursor.peek(1);
      if (next == null ||
          next.kind != TokenKind.word ||
          _verbs.contains(next.text) ||
          isNameStopWord(next.text)) {
        break;
      }
      cursor.take();
      names.add(parseNameReference(cursor, diagnostics));
    }
    return names;
  }

  /// `MOVE [CORRESPONDING] source TO target, …` (F pp. 42–43).
  Clause _parseMove(TokenCursor cursor) {
    final Token verb = cursor.take();
    final bool corresponding = cursor.takeWord('CORRESPONDING');
    final ArithExpr source = _parseSourceOperand(
      cursor,
      msgIncompleteMove,
      allowLiteral: true,
      allowAlphameric: true,
    );
    if (!cursor.takeWord('TO')) {
      throw _DeleteSentence(msgIncompleteMove, cursor.card, cursor.column);
    }
    final List<NameReference> targets = _parseNameSeries(
      cursor,
      msgIncompleteMove,
    );
    return MoveClause(verb, source, targets, corresponding: corresponding);
  }

  /// A verb's source operand: a name, a figurative constant (design
  /// note M2-8), or a literal where the verb takes one — numeric for
  /// ADD (F p. 47); MOVE also takes an alphameric literal, attested by
  /// the sample's `MOVE 'M' TO ERRORTYPE` and `MOVE 'GT' TO PAYRECORD
  /// DEPARTMENT` (J 90.05 listing, statements 193, 196, 199), which
  /// F p. 42's data.name-only general form does not show.
  ArithExpr _parseSourceOperand(
    TokenCursor cursor,
    Message onMissing, {
    bool allowLiteral = false,
    bool allowAlphameric = false,
  }) {
    final Token? token = cursor.peek();
    if (token == null) {
      throw _DeleteSentence(onMissing, cursor.card, cursor.column);
    }
    if (token.kind == TokenKind.word &&
        figurativeConstants.contains(token.text)) {
      return FigurativeOperand(cursor.take());
    }
    if (allowLiteral &&
        (token.kind == TokenKind.numericLiteral ||
            token.kind == TokenKind.floatingLiteral)) {
      return LiteralOperand(cursor.take());
    }
    if (allowAlphameric && token.kind == TokenKind.alphamericLiteral) {
      return LiteralOperand(cursor.take());
    }
    if (token.kind == TokenKind.word && !isNameStopWord(token.text)) {
      return NameOperand(parseNameReference(cursor, diagnostics));
    }
    throw _DeleteSentence(onMissing, token.card, token.column);
  }

  /// `SET target, … = expression [TRUNCATED] [, ON OVERFLOW clause]`
  /// (F pp. 44, 109) or `SET condition.name` (F p. 46; D5.6).
  Clause _parseSet(TokenCursor cursor) {
    final Token verb = cursor.take();
    final NameReference first = _expectName(cursor, msgIncompleteStatement);
    final targets = <NameReference>[first];
    while (cursor.isSymbol(',')) {
      // A comma continues the target list only when a further target
      // name follows; a verb after it belongs to the next clause
      // (`SET MARRIED, GO TO X.`).
      final Token? next = cursor.peek(1);
      if (next == null ||
          next.kind != TokenKind.word ||
          _verbs.contains(next.text) ||
          isNameStopWord(next.text)) {
        break;
      }
      cursor.take();
      targets.add(parseNameReference(cursor, diagnostics));
    }
    if (!cursor.takeSymbol('=')) {
      if (targets.length == 1) {
        // The condition-name form (F p. 46; D5.6). A subscript on it
        // is rejected (J 90.01.03; msg 910).
        if (first.subscripts.isNotEmpty) {
          diagnostics.add(
            Diagnostic(
              msgSubscriptedConditionName,
              first.anchor.card,
              column: first.anchor.column,
            ),
          );
        }
        return SetConditionClause(verb, first);
      }
      throw _DeleteSentence(
        msgIllegalSentenceStructure,
        cursor.card,
        cursor.column,
      );
    }
    final ArithExpr value = _parseValueExpression(cursor);
    final bool truncated = cursor.takeWord('TRUNCATED');
    Clause? onOverflow;
    if (cursor.isSymbol(',') && cursor.isWord('ON', 1)) {
      cursor.take();
      onOverflow = _parseOnOverflow(cursor, verb, targets.length);
    }
    return SetClause(
      verb,
      targets,
      value,
      truncated: truncated,
      onOverflow: onOverflow,
    );
  }

  /// A SET right-hand side: a sole figurative constant (J 02.04.01;
  /// design note M2-8) or an arithmetic expression.
  ArithExpr _parseValueExpression(TokenCursor cursor) {
    final Token? token = cursor.peek();
    if (token != null &&
        token.kind == TokenKind.word &&
        figurativeConstants.contains(token.text)) {
      return FigurativeOperand(cursor.take());
    }
    final ArithExpr value = parseArithExpr(cursor, diagnostics);
    _rejectNestedFigurative(value, sole: true);
    return value;
  }

  /// Figurative constants never sit inside a larger expression (design
  /// note M2-8); a nested one draws msg 192 — a key word misused.
  void _rejectNestedFigurative(ArithExpr expr, {required bool sole}) {
    switch (expr) {
      case FigurativeOperand(:final word) when !sole:
        diagnostics.add(
          Diagnostic(msgSentenceStructureError, word.card, column: word.column),
        );
      case FigurativeOperand():
        break;
      case BinaryExpr(:final left, :final right):
        _rejectNestedFigurative(left, sole: false);
        _rejectNestedFigurative(right, sole: false);
      case UnaryExpr(:final operand):
        _rejectNestedFigurative(operand, sole: false);
      case NameOperand():
      case LiteralOperand():
      case TruthExpr():
      case FunctionCall():
        break;
    }
  }

  /// `, ON OVERFLOW imperative-clause` — legal only with exactly one
  /// result field (F pp. 44, 47).
  Clause _parseOnOverflow(TokenCursor cursor, Token verb, int targetCount) {
    cursor.take();
    if (!cursor.takeWord('OVERFLOW')) {
      throw _DeleteSentence(
        msgIllegalSentenceStructure,
        cursor.card,
        cursor.column,
      );
    }
    if (targetCount != 1) {
      diagnostics.add(
        Diagnostic(msgSentenceStructureError, verb.card, column: verb.column),
      );
    }
    return _parseClause(cursor);
  }

  /// `ADD [CORRESPONDING] source TO target, … [TRUNCATED]
  /// [, ON OVERFLOW clause]` (F pp. 47, 108; design note M2-9).
  Clause _parseAdd(TokenCursor cursor) {
    final Token verb = cursor.take();
    final bool corresponding = cursor.takeWord('CORRESPONDING');
    final ArithExpr source = _parseSourceOperand(
      cursor,
      msgIncompleteStatement,
      allowLiteral: true,
    );
    if (!cursor.takeWord('TO')) {
      throw _DeleteSentence(
        msgIllegalSentenceStructure,
        cursor.card,
        cursor.column,
      );
    }
    final List<NameReference> targets = _parseNameSeries(
      cursor,
      msgIncompleteStatement,
    );
    final bool truncated = cursor.takeWord('TRUNCATED');
    Clause? onOverflow;
    if (cursor.isSymbol(',') && cursor.isWord('ON', 1)) {
      cursor.take();
      onOverflow = _parseOnOverflow(cursor, verb, targets.length);
    }
    return AddClause(
      verb,
      source,
      targets,
      corresponding: corresponding,
      truncated: truncated,
      onOverflow: onOverflow,
    );
  }

  /// The three GO TO forms (F pp. 48–49).
  Clause _parseGoTo(TokenCursor cursor) {
    final Token verb = cursor.take();
    if (!cursor.takeWord('TO')) {
      throw _DeleteSentence(
        msgIllegalSentenceStructure,
        cursor.card,
        cursor.column,
      );
    }
    if (cursor.takeSymbol('(')) {
      // `GO TO (name, …) ON index` — the parentheses are part of the
      // syntax (F p. 49).
      final names = <NameReference>[
        _expectName(cursor, msgIllegalSentenceStructure),
      ];
      while (cursor.takeSymbol(',')) {
        names.add(_expectName(cursor, msgIllegalSentenceStructure));
      }
      if (!cursor.takeSymbol(')') || !cursor.takeWord('ON')) {
        throw _DeleteSentence(
          msgIllegalSentenceStructure,
          cursor.card,
          cursor.column,
        );
      }
      final NameReference index = _expectName(
        cursor,
        msgIllegalSentenceStructure,
      );
      return GoToClause(verb, [
        for (final NameReference name in names) GoToTarget(name, null),
      ], index: index);
    }
    final NameReference first = _expectName(
      cursor,
      msgIllegalSentenceStructure,
    );
    if (!cursor.isWord('WHEN')) {
      return GoToClause(verb, [GoToTarget(first, null)]);
    }
    cursor.take();
    final targets = <GoToTarget>[
      GoToTarget(first, parseCondExpr(cursor, diagnostics)),
    ];
    // `, name WHEN condition` continues the form; a comma before a
    // verb ends it (first-match-wins list, F p. 48).
    while (cursor.isSymbol(',')) {
      final Token? next = cursor.peek(1);
      if (next == null ||
          next.kind != TokenKind.word ||
          _verbs.contains(next.text) ||
          isNameStopWord(next.text)) {
        break;
      }
      cursor.take();
      final NameReference name = parseNameReference(cursor, diagnostics);
      if (!cursor.takeWord('WHEN')) {
        throw _DeleteSentence(
          msgIllegalSentenceStructure,
          cursor.card,
          cursor.column,
        );
      }
      targets.add(GoToTarget(name, parseCondExpr(cursor, diagnostics)));
    }
    return GoToClause(verb, targets);
  }

  /// `DO procedure [EXACTLY n TIMES | FOR index = p(q)r, …]
  /// [USING …] [GIVING …]` (F p. 108; D5.2).
  Clause _parseDo(TokenCursor cursor) {
    final Token verb = cursor.take();
    final NameReference procedure = _expectName(cursor, msgInvalidDoForm);
    _doTargets.add(procedure);
    ArithExpr? exactlyTimes;
    var indices = const <DoIndex>[];
    if (cursor.takeWord('EXACTLY')) {
      exactlyTimes = _parseDoOperand(cursor);
      if (!cursor.takeWord('TIMES')) {
        diagnostics.add(
          Diagnostic(msgInvalidDoForm, cursor.card, column: cursor.column),
        );
      }
    } else if (cursor.takeWord('FOR')) {
      final list = <DoIndex>[];
      while (true) {
        list.add(_parseDoIndex(cursor));
        if (cursor.isSymbol(',') &&
            cursor.peek(1) != null &&
            cursor.peek(1)!.kind == TokenKind.word &&
            !_verbs.contains(cursor.peek(1)!.text) &&
            !isNameStopWord(cursor.peek(1)!.text) &&
            cursor.isSymbol('=', 2)) {
          cursor.take();
          continue;
        }
        break;
      }
      if (list.length > 3) {
        // At most three indices (F p. 51; D5.2: msg 83 beyond).
        diagnostics.add(
          Diagnostic(msgInvalidDoForm, verb.card, column: verb.column),
        );
      }
      indices = list;
    }
    var usingArguments = const <ArithExpr>[];
    if (cursor.takeWord('USING')) {
      final list = <ArithExpr>[
        _parseSourceOperand(
          cursor,
          msgInvalidDoForm,
          allowLiteral: true,
          allowAlphameric: true,
        ),
      ];
      while (cursor.isSymbol(',')) {
        final Token? next = cursor.peek(1);
        if (next == null ||
            next.kind == TokenKind.word &&
                (_verbs.contains(next.text) ||
                    isNameStopWord(next.text) &&
                        !figurativeConstants.contains(next.text))) {
          break;
        }
        cursor.take();
        list.add(
          _parseSourceOperand(
            cursor,
            msgInvalidDoForm,
            allowLiteral: true,
            allowAlphameric: true,
          ),
        );
      }
      usingArguments = list;
    }
    var givingResults = const <NameReference>[];
    if (cursor.takeWord('GIVING')) {
      givingResults = _parseNameSeries(cursor, msgInvalidDoForm);
    }
    return DoClause(
      verb,
      procedure,
      exactlyTimes: exactlyTimes,
      indices: indices,
      usingArguments: usingArguments,
      givingResults: givingResults,
    );
  }

  /// A DO control operand: an integer literal or a field name
  /// (F pp. 50–51).
  ArithExpr _parseDoOperand(TokenCursor cursor) {
    final Token? token = cursor.peek();
    if (token == null) {
      throw _DeleteSentence(msgInvalidDoForm, cursor.card, cursor.column);
    }
    if (token.kind == TokenKind.numericLiteral) {
      return LiteralOperand(cursor.take());
    }
    if (token.kind == TokenKind.word && !isNameStopWord(token.text)) {
      return NameOperand(parseNameReference(cursor, diagnostics));
    }
    throw _DeleteSentence(msgInvalidDoForm, token.card, token.column);
  }

  /// `index = p(q)r` (F pp. 50–51).
  DoIndex _parseDoIndex(TokenCursor cursor) {
    final NameReference index = _expectName(cursor, msgInvalidDoForm);
    if (!cursor.takeSymbol('=')) {
      throw _DeleteSentence(msgInvalidDoForm, cursor.card, cursor.column);
    }
    final ArithExpr from = _parseDoOperand(cursor);
    if (!cursor.takeSymbol('(')) {
      throw _DeleteSentence(msgInvalidDoForm, cursor.card, cursor.column);
    }
    final ArithExpr by = _parseDoOperand(cursor);
    if (!cursor.takeSymbol(')')) {
      throw _DeleteSentence(msgInvalidDoForm, cursor.card, cursor.column);
    }
    final ArithExpr to = _parseDoOperand(cursor);
    return DoIndex(index, from, by, to);
  }

  /// `STOP n` or `STOP RUN` — the operand is required (D2.7).
  Clause _parseStop(TokenCursor cursor) {
    final Token verb = cursor.take();
    if (cursor.takeWord('RUN')) {
      _sawStopRun = true;
      return StopClause(verb, run: true);
    }
    final Token? token = cursor.peek();
    if (token != null && token.kind == TokenKind.numericLiteral) {
      if (token.text.length > 6) {
        // n is at most 6 digits (J 05.06.04).
        diagnostics.add(
          Diagnostic(
            msgSentenceStructureError,
            token.card,
            column: token.column,
          ),
        );
      }
      return StopClause(verb, number: cursor.take(), run: false);
    }
    // A bare STOP. is a syntax error (D2.7).
    throw _DeleteSentence(msgIncompleteStatement, verb.card, verb.column);
  }

  /// `OPEN|CLOSE file, …` or `… ALL FILES` (F pp. 39, 41).
  Clause _parseOpenClose(TokenCursor cursor, {required bool open}) {
    final Token verb = cursor.take();
    if (cursor.isWord('ALL') && cursor.isWord('FILES', 1)) {
      cursor.take();
      cursor.take();
      return open
          ? OpenClause(verb, const [], allFiles: true)
          : CloseClause(verb, const [], allFiles: true);
    }
    final Token? token = cursor.peek();
    if (token == null ||
        token.kind != TokenKind.word ||
        isNameStopWord(token.text)) {
      // Msgs 139/138: a file name must follow (J 90.04.01).
      throw _DeleteSentence(
        open ? msgOpenNeedsFileName : msgCloseNeedsFileName,
        cursor.card,
        cursor.column,
      );
    }
    final List<NameReference> files = _parseNameSeries(
      cursor,
      open ? msgOpenNeedsFileName : msgCloseNeedsFileName,
    );
    return open
        ? OpenClause(verb, files, allFiles: false)
        : CloseClause(verb, files, allFiles: false);
  }

  /// `GET record [, AT END …]` or `GET RECORD FROM file [, AT END …]`
  /// (J 02.07.04–06; D6.6).
  Clause _parseGet(TokenCursor cursor) {
    final Token verb = cursor.take();
    var recordFrom = false;
    if (cursor.isWord('RECORD') && cursor.isWord('FROM', 1)) {
      cursor.take();
      cursor.take();
      recordFrom = true;
    }
    final NameReference name = _expectName(cursor, msgIncompleteStatement);
    AtEndClause? atEnd;
    final bool commaAtEnd = cursor.isSymbol(',') && cursor.isWord('AT', 1);
    if (commaAtEnd || cursor.isWord('AT')) {
      if (commaAtEnd) {
        cursor.take();
      }
      final Token at = cursor.take();
      if (!cursor.takeWord('END')) {
        throw _DeleteSentence(
          msgIllegalSentenceStructure,
          cursor.card,
          cursor.column,
        );
      }
      atEnd = _parseAtEnd(cursor, at);
    }
    return GetClause(verb, name, recordFrom: recordFrom, atEnd: atEnd);
  }

  /// The AT END slot (D6.6): `DO name`, `GO TO name`, a bare procedure
  /// name (compiled as DO), or any other single imperative clause with
  /// the non-historical msg 911; an empty or non-name-headed slot draws
  /// msg 106.
  AtEndClause _parseAtEnd(TokenCursor cursor, Token at) {
    final Token? token = cursor.peek();
    if (token == null || token.kind != TokenKind.word) {
      diagnostics.add(
        Diagnostic(
          msgAtEndNeedsName,
          cursor.card,
          column: cursor.column,
          operands: [token?.text ?? ''],
        ),
      );
      return AtEndClause(at);
    }
    if (!_verbs.contains(token.text) && !isNameStopWord(token.text)) {
      // The bare-name form (D6.6, non-historical: compiled as DO name).
      return AtEndClause(at, bareName: parseNameReference(cursor, diagnostics));
    }
    if (isNameStopWord(token.text) && !_verbs.contains(token.text)) {
      diagnostics.add(
        Diagnostic(
          msgAtEndNeedsName,
          token.card,
          column: token.column,
          operands: [token.text],
        ),
      );
      cursor.take();
      return AtEndClause(at);
    }
    final Clause statement = _parseClause(cursor);
    if (statement is! DoClause && statement is! GoToClause) {
      // A non-transfer clause is accepted at low severity (D6.6;
      // --pedantic raises it).
      diagnostics.add(
        Diagnostic(msgAtEndNotTransfer, token.card, column: token.column),
      );
    }
    return AtEndClause(at, statement: statement);
  }

  /// `FILE record [IN file]` (F pp. 40–41; J 02.07.07–08).
  Clause _parseFile(TokenCursor cursor) {
    final Token verb = cursor.take();
    final NameReference record = _expectName(cursor, msgIncompleteStatement);
    NameReference? inFile;
    if (cursor.takeWord('IN')) {
      inFile = _expectName(cursor, msgIncompleteStatement);
    }
    return FileClause(verb, record, inFile: inFile);
  }

  /// `DISPLAY item …` — literals and comma-separated name references;
  /// juxtaposed words form one qualified name (J 90.01.01; design note
  /// M2-10).
  Clause _parseDisplay(TokenCursor cursor) {
    final Token verb = cursor.take();
    final items = <ArithExpr>[];
    while (true) {
      final Token? token = cursor.peek();
      if (token == null) {
        break;
      }
      if (token.kind == TokenKind.alphamericLiteral) {
        items.add(LiteralOperand(cursor.take()));
        continue;
      }
      if (token.kind == TokenKind.word &&
          !_verbs.contains(token.text) &&
          !isNameStopWord(token.text)) {
        items.add(NameOperand(parseNameReference(cursor, diagnostics)));
        continue;
      }
      if (token.kind == TokenKind.symbol && token.text == ',') {
        final Token? next = cursor.peek(1);
        if (next != null &&
            (next.kind == TokenKind.alphamericLiteral ||
                next.kind == TokenKind.word &&
                    !_verbs.contains(next.text) &&
                    !isNameStopWord(next.text))) {
          cursor.take();
          continue;
        }
        break;
      }
      if (token.kind == TokenKind.numericLiteral ||
          token.kind == TokenKind.floatingLiteral) {
        // An unquoted number in the item list (msg 131): displayed
        // values are quoted literals or fields (F p. 54).
        diagnostics.add(
          Diagnostic(msgInvalidDisplay, token.card, column: token.column),
        );
        cursor.take();
        continue;
      }
      break;
    }
    if (items.isEmpty) {
      diagnostics.add(
        Diagnostic(msgInvalidDisplay, verb.card, column: verb.column),
      );
    }
    return DisplayClause(verb, items);
  }

  /// `CALL (old) new, …` (F p. 59; J 02.04.05).
  Clause _parseCall(TokenCursor cursor) {
    final Token verb = cursor.take();
    final pairs = <CallPair>[];
    while (true) {
      if (!cursor.takeSymbol('(')) {
        throw _DeleteSentence(
          msgIllegalSentenceStructure,
          cursor.card,
          cursor.column,
        );
      }
      final NameReference oldName = _expectName(
        cursor,
        msgIllegalSentenceStructure,
      );
      if (!cursor.takeSymbol(')')) {
        throw _DeleteSentence(
          msgIllegalSentenceStructure,
          cursor.card,
          cursor.column,
        );
      }
      final Token? newName = cursor.peek();
      if (newName == null ||
          newName.kind != TokenKind.word ||
          isNameStopWord(newName.text)) {
        throw _DeleteSentence(
          msgIllegalSentenceStructure,
          cursor.card,
          cursor.column,
        );
      }
      pairs.add(CallPair(oldName, cursor.take()));
      if (cursor.isSymbol(',') && cursor.isSymbol('(', 1)) {
        cursor.take();
        continue;
      }
      break;
    }
    return CallClause(verb, pairs);
  }

  /// `ENTER CRYPT` or `ENTER COMMERCIAL TRANSLATOR` — the only two
  /// forms (J 02.04.02.01). ENTER CRYPT switches the parser into
  /// pass-through until the reverse command.
  Clause _parseEnter(TokenCursor cursor) {
    final Token verb = cursor.take();
    if (cursor.takeWord('CRYPT')) {
      _cryptMode = true;
      return EnterClause(verb, crypt: true);
    }
    if (cursor.takeWord('COMMERCIAL') && cursor.takeWord('TRANSLATOR')) {
      _cryptMode = false;
      return EnterClause(verb, crypt: false);
    }
    throw _DeleteSentence(
      msgIllegalSentenceStructure,
      cursor.card,
      cursor.column,
    );
  }

  /// `NOTE any text.` — the rest of the sentence is raw text (F p. 59).
  Clause _parseNote(TokenCursor cursor) {
    final Token verb = cursor.take();
    final text = <Token>[];
    while (!cursor.atEnd) {
      text.add(cursor.take());
    }
    return NoteClause(verb, text);
  }

  /// `BEGIN SECTION [USING …] [GIVING …]` (F p. 57).
  Clause _parseBeginSection(TokenCursor cursor) {
    final Token verb = cursor.take();
    if (!cursor.takeWord('SECTION')) {
      throw _DeleteSentence(
        msgIllegalSentenceStructure,
        cursor.card,
        cursor.column,
      );
    }
    var usingParameters = const <NameReference>[];
    if (cursor.takeWord('USING')) {
      usingParameters = _parseNameSeries(cursor, msgIllegalSentenceStructure);
    }
    var givingFunctions = const <NameReference>[];
    if (cursor.takeWord('GIVING')) {
      givingFunctions = _parseNameSeries(cursor, msgIllegalSentenceStructure);
    }
    return BeginSectionClause(
      verb,
      usingParameters: usingParameters,
      givingFunctions: givingFunctions,
    );
  }

  /// `END section.name` (F p. 57).
  Clause _parseEnd(TokenCursor cursor) {
    final Token verb = cursor.take();
    NameReference? sectionName;
    final Token? token = cursor.peek();
    if (token != null &&
        token.kind == TokenKind.word &&
        !isNameStopWord(token.text)) {
      sectionName = parseNameReference(cursor, diagnostics);
    }
    return EndClause(verb, sectionName);
  }

  /// A deferred verb: msg 110 for COPY/INCLUDE (D7.4), the
  /// non-historical msg 916 for LOAD/OVERLAP (design note M2-11). The
  /// operands stay raw, up to the next clause boundary.
  Clause _parseDeferredVerb(TokenCursor cursor) {
    final Token verb = cursor.take();
    diagnostics.add(
      verb.text == 'LOAD' || verb.text == 'OVERLAP'
          ? Diagnostic(
              msgDeferredVerb,
              verb.card,
              column: verb.column,
              operands: [verb.text],
            )
          : Diagnostic(msgCopyNotHandled, verb.card, column: verb.column),
    );
    final operands = <Token>[];
    while (!cursor.atEnd) {
      if (cursor.isSymbol(',')) {
        final Token? next = cursor.peek(1);
        if (next != null &&
            next.kind == TokenKind.word &&
            _verbs.contains(next.text)) {
          break;
        }
      }
      operands.add(cursor.take());
    }
    return DeferredVerbClause(verb, operands);
  }

  /// Assigns clause numbers (design note M2-6): the conditional clause
  /// takes 01 when present, each imperative clause the next number, in
  /// source order through the arms; then stamps the sentence's parser
  /// diagnostics with the clause they were raised in.
  void _numberClauses(List<Clause> clauses, int diagnosticsFrom) {
    var next = 1;
    void walk(Clause clause) {
      clause.clause = next++;
      if (clause is IfClause) {
        clause.thenArm.forEach(walk);
        clause.otherwiseArm.forEach(walk);
      }
    }

    clauses.forEach(walk);
    // Best-effort clause attribution for the diagnostics raised while
    // this sentence parsed: a single-clause sentence confines them all
    // to that clause; a multi-clause sentence keeps `n,00` (the parse
    // interleaves arms, so per-clause ranges are not tracked).
    if (clauses.length == 1 && clauses.first is! IfClause) {
      for (var i = diagnosticsFrom; i < diagnostics.length; i++) {
        diagnostics[i].clause ??= clauses.first.clause;
      }
    }
  }

  /// The section bookkeeping over one sentence's clauses: BEGIN
  /// SECTION pushes (caps: 35 sections, msg 149; depth 18, msg 915 —
  /// D9.7), END pops (msgs 64, 65) and must be the sentence's only
  /// clause (msg 179).
  void _sectionWalk(List<Clause> clauses, ProcedureSentence scan) {
    for (final Clause clause in clauses) {
      if (clause is BeginSectionClause) {
        _sectionCount++;
        if (_sectionCount > 35) {
          diagnostics.add(Diagnostic(msgTooManySections, scan.cards.first));
        }
        _openSections.add(scan.label ?? '');
        if (_openSections.length > 18) {
          diagnostics.add(Diagnostic(msgSectionsTooDeep, scan.cards.first));
        }
      } else if (clause is EndClause) {
        if (clauses.length != 1) {
          diagnostics.add(
            Diagnostic(
              msgEndNotAlone,
              clause.verb.card,
              column: clause.verb.column,
            ),
          );
        }
        final String named = clause.sectionName?.text ?? '';
        if (_openSections.isEmpty) {
          diagnostics.add(
            Diagnostic(
              msgEndWithoutSection,
              clause.verb.card,
              column: clause.verb.column,
            ),
          );
        } else if (_openSections.last != named) {
          diagnostics.add(
            Diagnostic(
              msgEndWrongSection,
              clause.verb.card,
              column: clause.verb.column,
              operands: [named, _openSections.last],
            ),
          );
          _openSections.removeLast();
        } else {
          _openSections.removeLast();
        }
      }
    }
  }
}
