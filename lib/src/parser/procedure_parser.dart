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
  'LOAD', 'OVERLAP', 'INCLUDE', 'COPY', 'LIBRARY', 'IF',
};

/// The deferred verbs (J 90.01.02–03; design note M2-11). LIBRARY
/// rides with COPY and INCLUDE: all three refuse with msg 110 (D9.8).
const Set<String> _deferredVerbs = {
  'LOAD',
  'OVERLAP',
  'INCLUDE',
  'COPY',
  'LIBRARY',
};

/// Word tokens counted against the 60-operator sentence cap
/// (J 90.04.01 msg 171; the exact 1962 counting is unattested — this
/// counts arithmetic, relational, and logical operators).
const Set<String> _operatorWords = {
  'AND', 'OR', 'NOT', 'GT', 'LT', 'GREATER', 'LESS', 'EQUAL', 'ABS', 'TR', //
};

/// Symbol tokens counted against the cap: the arithmetic operators and
/// `=` — relational or assignment, indistinguishable before parsing.
/// Parentheses and commas are not operators and do not count.
const Set<String> _operatorSymbols = {'+', '-', '*', '/', '**', '='};

/// Thrown to delete the sentence being parsed (design note M2-13).
final class _DeleteSentence implements Exception {
  _DeleteSentence(this.message, this.card, this.column);

  /// Anchors the deletion at [cursor]'s current position (or its
  /// sentence card, at end-of-sentence).
  _DeleteSentence.at(TokenCursor cursor, Message message)
    : this(message, cursor.card, cursor.column);

  /// Anchors the deletion at [token].
  _DeleteSentence.atToken(Token token, Message message)
    : this(message, token.card, token.column);

  final Message message;
  final SourceCard card;
  final int? column;
}

/// The procedure parser. One instance parses every `*PROCEDURE` group
/// of a program in deck order, carrying the section stack and the
/// whole-program facts (STOP RUN, PROGRAM.START, DO targets) across
/// groups; [finishProgram] runs the end-of-text checks.
final class ProcedureParser {
  /// Every diagnostic appends to [diagnostics]. [pedantic] adds
  /// non-historical written-language-strictness diagnostics (decision
  /// D0.8, D11.4) without changing any parsed clause.
  ProcedureParser(this.diagnostics, {this.pedantic = false});

  /// The sink for every diagnostic.
  final List<Diagnostic> diagnostics;

  /// Whether `--pedantic` diagnostics are on (D11.4).
  final bool pedantic;

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
      diagnostics.reportAt(msgSectionsNotClosed, at);
    }
    if (!_sawStopRun) {
      diagnostics.reportAt(msgNoStopRun, at);
    }
    if (_programStartLabels.isNotEmpty) {
      for (final NameReference target in _doTargets) {
        if (target.text == programStartName) {
          diagnostics.report(msgProgramStartDoAddressed, target.anchor);
        }
      }
    }
  }

  Sentence _parseSentence(ProcedureSentence scan) {
    final SourceCard card = scan.cards.first;
    final String? label = scan.label;
    if (label != null && isNameStopWord(label)) {
      // A list-1/list-2 key word defined as a Procedure name
      // (J 02.03.02): msg 192, and parsing continues with the label
      // kept (D1.5; design note M2-7).
      diagnostics.reportAt(
        msgSentenceStructureError,
        card,
        column: scan.labelColumn,
      );
    }
    if (label == programStartName) {
      if (_programStartLabels.isNotEmpty) {
        diagnostics.reportAt(msgDuplicateProgramStart, card);
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
      diagnostics.reportAt(msgTooManyOperators, card);
      return Sentence(scan, const [], deleted: true);
    }
    final cursor = TokenCursor(scan.tokens, card);
    final int diagnosticsFrom = diagnostics.length;
    try {
      final List<Clause> clauses = _parseSentenceClauses(cursor, scan);
      if (diagnostics
          .skip(diagnosticsFrom)
          .any((Diagnostic d) => d.message == msgSubscriptedConditionName)) {
        // D5.6: a subscripted condition-name rejects the sentence — the
        // element semantics stay unimplemented rather than invented.
        // Msg 910's own text announces the deletion.
        return Sentence(scan, const [], deleted: true);
      }
      _checkVerbMixing(clauses);
      _numberClauses(clauses, diagnosticsFrom);
      _sectionWalk(clauses, scan);
      _commitSentenceFacts(clauses);
      return Sentence(scan, clauses, deleted: false);
    } on _DeleteSentence catch (deletion) {
      diagnostics.reportAt(
        deletion.message,
        deletion.card,
        column: deletion.column,
      );
      return Sentence(scan, const [], deleted: true);
    }
  }

  /// Every clause of [clauses], including those nested in IF arms, ON
  /// OVERFLOW slots, and AT END slots.
  Iterable<Clause> _clauseTree(List<Clause> clauses) sync* {
    for (final clause in clauses) {
      yield clause;
      switch (clause) {
        case IfClause(:final thenArm, :final otherwiseArm):
          yield* _clauseTree(thenArm);
          yield* _clauseTree(otherwiseArm);
        case SetClause(:final onOverflow?):
          yield* _clauseTree([onOverflow]);
        case AddClause(:final onOverflow?):
          yield* _clauseTree([onOverflow]);
        case GetClause(atEnd: AtEndClause(:final statement?)):
          yield* _clauseTree([statement]);
        default:
          break;
      }
    }
  }

  /// F p. 60: program and processor commands cannot be intermixed in
  /// one sentence — such a sentence is meaningless and is deleted with
  /// msg 196 (design note M2-12). END is exempt: its own attested rule,
  /// msg 179 in [_sectionWalk], governs an END that is not alone.
  void _checkVerbMixing(List<Clause> clauses) {
    var sawProgram = false;
    var sawProcessor = false;
    for (final Clause clause in _clauseTree(clauses)) {
      if (clause is EndClause) {
        continue;
      }
      final bool processor = switch (clause) {
        CallClause() || EnterClause() || NoteClause() => true,
        BeginSectionClause() => true,
        // OVERLAP, INCLUDE, COPY, and LIBRARY are processor verbs;
        // LOAD is a program verb (F p. 35, §2.7).
        DeferredVerbClause(:final verb) => verb.text != 'LOAD',
        _ => false,
      };
      if (processor) {
        sawProcessor = true;
      } else {
        sawProgram = true;
      }
      if (sawProgram && sawProcessor) {
        throw _DeleteSentence.atToken(
          clause.anchor,
          msgIllegalSentenceStructure,
        );
      }
    }
  }

  /// Commits the whole-program facts a sentence contributes — STOP RUN,
  /// DO targets, CRYPT mode — only after the sentence has parsed. A
  /// deleted sentence contributes nothing (design note M2-13): its
  /// clauses generate no code (M2-5), so a STOP RUN inside one must
  /// still leave msg 175 to fire.
  void _commitSentenceFacts(List<Clause> clauses) {
    for (final Clause clause in _clauseTree(clauses)) {
      switch (clause) {
        case StopClause(run: true):
          _sawStopRun = true;
        case DoClause(:final procedure):
          _doTargets.add(procedure);
        case EnterClause(:final crypt):
          _cryptMode = crypt;
        default:
          break;
      }
    }
  }

  bool _isEnterSentence(ProcedureSentence scan) =>
      scan.tokens.isNotEmpty &&
      scan.tokens.first.kind == TokenKind.word &&
      scan.tokens.first.text == 'ENTER';

  int _operatorCount(List<Token> tokens) {
    var count = 0;
    for (final token in tokens) {
      if (token.kind == TokenKind.symbol &&
              _operatorSymbols.contains(token.text) ||
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
      throw _DeleteSentence.at(cursor, msgSentenceStartsOtherwise);
    }
    if (cursor.isWord('IF')) {
      final Token word = cursor.take();
      final CondExpr condition = parseCondExpr(cursor, diagnostics);
      if (!cursor.takeWord('THEN')) {
        throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
      throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
      final Token? comma = cursor.peek();
      if (cursor.takeSymbol(',')) {
        if (cursor.atEnd) {
          // A trailing comma before the period is accepted silently —
          // a recorded leniency, not an attestation (D10.5c; the
          // sample's statement 188 comma is a mid-sentence separator
          // before a continuation card, not one before the period).
          // --pedantic warns (msg 928; D11.4).
          if (pedantic) {
            diagnostics.report(msgTrailingCommaBeforePeriod, comma!);
          }
          return clauses;
        }
        if (stopAtOtherwise && cursor.isWord('OTHERWISE')) {
          // A comma before OTHERWISE is accepted silently, a recorded
          // leniency (D10.5a). --pedantic warns (msg 926; D11.4).
          if (pedantic) {
            diagnostics.report(msgCommaBeforeOtherwise, comma!);
          }
          return clauses;
        }
        continue;
      }
      final Token? next = cursor.peek();
      if (next != null &&
          next.kind == TokenKind.word &&
          _verbs.contains(next.text)) {
        // A second verb with no separating comma (msg 126).
        throw _DeleteSentence.atToken(next, msgStatementTwoVerbs);
      }
      return clauses;
    }
  }

  /// One imperative clause: a verb and its operands.
  Clause _parseClause(TokenCursor cursor) {
    final Token? token = cursor.peek();
    if (token == null) {
      throw _DeleteSentence.at(cursor, msgIncompleteStatement);
    }
    if (token.kind != TokenKind.word) {
      throw _DeleteSentence.atToken(token, msgStatementWithoutVerb);
    }
    switch (token.text) {
      case 'RUN':
        // RUN outside STOP RUN: the word is deleted, compilation
        // continues (msg 2; D2.7).
        diagnostics.report(msgRunDeleted, token);
        cursor.take();
        return _parseClause(cursor);
      case 'CORRESPONDING':
        // CORRESPONDING must directly follow ADD or MOVE (msg 63).
        diagnostics.report(msgCorrespondingMisplaced, token);
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
          throw _DeleteSentence.atToken(token, msgSentenceStructureError);
        }
        // A name where a verb belongs (msg 125).
        throw _DeleteSentence.atToken(token, msgStatementWithoutVerb);
    }
  }

  /// A name expected at the cursor; [onMissing] is thrown otherwise.
  NameReference _expectName(TokenCursor cursor, Message onMissing) {
    final Token? token = cursor.peek();
    if (token == null ||
        token.kind != TokenKind.word ||
        isNameStopWord(token.text) ||
        figurativeConstants.contains(token.text)) {
      throw _DeleteSentence.at(cursor, onMissing);
    }
    return parseNameReference(cursor, diagnostics);
  }

  /// Whether a comma at the cursor continues a list, rather than
  /// closing it before the next clause's verb: a comma before a verb
  /// ends the list (first-match-wins list, F p. 48). [allowFigurative]
  /// exempts a figurative constant from the stop-word check, for a
  /// list whose items are source operands rather than names (DO
  /// USING).
  bool _commaContinuesList(Token? next, {required bool allowFigurative}) {
    if (next == null) {
      return false;
    }
    if (next.kind != TokenKind.word) {
      return allowFigurative;
    }
    if (_verbs.contains(next.text)) {
      return false;
    }
    if (isNameStopWord(next.text)) {
      return allowFigurative && figurativeConstants.contains(next.text);
    }
    return true;
  }

  /// A comma-separated series of names, stopping before a verb.
  List<NameReference> _parseNameSeries(TokenCursor cursor, Message onMissing) {
    final names = <NameReference>[_expectName(cursor, onMissing)];
    while (cursor.isSymbol(',')) {
      if (!_commaContinuesList(cursor.peek(1), allowFigurative: false)) {
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
      throw _DeleteSentence.at(cursor, msgIncompleteMove);
    }
    final List<NameReference> targets = _parseNameSeries(
      cursor,
      msgIncompleteMove,
    );
    return MoveClause(verb, source, targets, corresponding: corresponding);
  }

  /// A verb's source operand: a name, a figurative constant (design
  /// note M2-8), a function reference (F p. 34's `MOVE MINIMUM
  /// ((CALCULATED.PRICE, MARKET.PRICE, HIGH.VALUES)) TO PRICE.LIST.`),
  /// or a literal where the verb takes one — numeric, optionally signed
  /// (F p. 18, rule 2), for ADD (F p. 47); MOVE also takes an
  /// alphameric literal, attested by the sample's `MOVE 'M' TO
  /// ERRORTYPE` and `MOVE 'GT' TO PAYRECORD DEPARTMENT` (J 90.05
  /// listing, statements 193, 196, 199), which F p. 42's data.name-only
  /// general form does not show.
  ArithExpr _parseSourceOperand(
    TokenCursor cursor,
    Message onMissing, {
    bool allowLiteral = false,
    bool allowAlphameric = false,
  }) {
    final Token? token = cursor.peek();
    if (token == null) {
      throw _DeleteSentence.at(cursor, onMissing);
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
    if (allowLiteral &&
        token.kind == TokenKind.symbol &&
        (token.text == '-' || token.text == '+')) {
      // The literal's own sign (F p. 18, rule 2), scanned as its own
      // token; mirrors the expression parser's reading.
      final Token? next = cursor.peek(1);
      if (next != null &&
          (next.kind == TokenKind.numericLiteral ||
              next.kind == TokenKind.floatingLiteral)) {
        final Token sign = cursor.take();
        final literal = LiteralOperand(cursor.take());
        return sign.text == '-' ? UnaryExpr(sign, literal) : literal;
      }
    }
    if (allowAlphameric && token.kind == TokenKind.alphamericLiteral) {
      return LiteralOperand(cursor.take());
    }
    if (token.kind == TokenKind.word && !isNameStopWord(token.text)) {
      final NameReference name = parseNameReference(cursor, diagnostics);
      if (cursor.isSymbol('(') && cursor.isSymbol('(', 1)) {
        return parseFunctionCall(name, cursor, diagnostics);
      }
      return NameOperand(name);
    }
    throw _DeleteSentence.atToken(token, onMissing);
  }

  /// `SET target, … = expression [TRUNCATED] [, ON OVERFLOW clause]`
  /// (F pp. 44, 109) or `SET condition.name` (F p. 46; D5.6).
  Clause _parseSet(TokenCursor cursor) {
    final Token verb = cursor.take();
    // A comma continues the target list only when a further target
    // name follows; a verb after it belongs to the next clause
    // (`SET MARRIED, GO TO X.`).
    final List<NameReference> targets = _parseNameSeries(
      cursor,
      msgIncompleteStatement,
    );
    if (!cursor.takeSymbol('=')) {
      if (targets.length == 1) {
        // The condition-name form (F p. 46; D5.6). A subscript on it
        // is rejected (J 90.01.03; msg 910).
        final NameReference first = targets.first;
        if (first.subscripts.isNotEmpty) {
          diagnostics.report(msgSubscriptedConditionName, first.anchor);
        }
        return SetConditionClause(verb, first);
      }
      throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
  /// design note M2-8), a sole alphameric literal (F p. 46: `SET
  /// MARITAL.STATUS = 'M'.`; J 02.04.05: legal "since no arithmetic
  /// expression is specified"), or an arithmetic expression.
  ArithExpr _parseValueExpression(TokenCursor cursor) {
    final Token? token = cursor.peek();
    if (token != null &&
        token.kind == TokenKind.word &&
        figurativeConstants.contains(token.text)) {
      return FigurativeOperand(cursor.take());
    }
    if (token != null && token.kind == TokenKind.alphamericLiteral) {
      final Token? after = cursor.peek(1);
      final bool inExpression =
          after != null &&
          after.kind == TokenKind.symbol &&
          const {'+', '-', '*', '/', '**'}.contains(after.text);
      if (!inExpression) {
        // The sole-operand form; a literal inside a larger arithmetic
        // expression still draws msg 912 below (F p. 45).
        return LiteralOperand(cursor.take());
      }
    }
    final ArithExpr value = parseArithExpr(cursor, diagnostics);
    rejectNestedFigurative(value, diagnostics, sole: true);
    return value;
  }

  /// `, ON OVERFLOW imperative-clause` — legal only with exactly one
  /// result field (F pp. 44, 47).
  Clause _parseOnOverflow(TokenCursor cursor, Token verb, int targetCount) {
    cursor.take();
    if (!cursor.takeWord('OVERFLOW')) {
      throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
    }
    if (targetCount != 1) {
      diagnostics.report(msgSentenceStructureError, verb);
    }
    return _parseClause(cursor);
  }

  /// `ADD` `[CORRESPONDING]` source TO target, … `[TRUNCATED]`
  /// `[, ON OVERFLOW clause]` (F pp. 47, 108; design note M2-9).
  Clause _parseAdd(TokenCursor cursor) {
    final Token verb = cursor.take();
    final bool corresponding = cursor.takeWord('CORRESPONDING');
    final ArithExpr source = _parseSourceOperand(
      cursor,
      msgIncompleteStatement,
      allowLiteral: true,
    );
    if (!cursor.takeWord('TO')) {
      throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
      throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
        throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
    if (!cursor.isWord('WHEN') && !cursor.isWord('IF')) {
      return GoToClause(verb, [GoToTarget(first, null)]);
    }
    _takeWhen(cursor);
    final targets = <GoToTarget>[
      GoToTarget(first, parseCondExpr(cursor, diagnostics)),
    ];
    // `, name WHEN condition` continues the form. IF is not counted as
    // the verb here: in this position it takes the WHEN repair.
    while (cursor.isSymbol(',')) {
      if (!_commaContinuesList(cursor.peek(1), allowFigurative: false)) {
        break;
      }
      cursor.take();
      final NameReference name = parseNameReference(cursor, diagnostics);
      if (!cursor.isWord('WHEN') && !cursor.isWord('IF')) {
        throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
      }
      _takeWhen(cursor);
      targets.add(GoToTarget(name, parseCondExpr(cursor, diagnostics)));
    }
    return GoToClause(verb, targets);
  }

  /// Consumes the conditional GO TO's WHEN, or an IF in its place: the
  /// attested repair parses the IF as a WHEN and issues msg 170 (D9.11:
  /// the repair is attested, this one placement is our criterion).
  void _takeWhen(TokenCursor cursor) {
    final Token word = cursor.take();
    if (word.text == 'IF') {
      diagnostics.report(msgWhenSubstitutedForIf, word);
    }
  }

  /// `DO procedure [EXACTLY n TIMES | FOR index = p(q)r, …]
  /// [USING …] [GIVING …]` (F p. 108; D5.2).
  Clause _parseDo(TokenCursor cursor) {
    final Token verb = cursor.take();
    final NameReference procedure = _expectName(cursor, msgInvalidDoForm);
    ArithExpr? exactlyTimes;
    var indices = const <DoIndex>[];
    if (cursor.takeWord('EXACTLY')) {
      exactlyTimes = _parseDoParameter(cursor);
      if (!cursor.takeWord('TIMES')) {
        diagnostics.reportAt(
          msgInvalidDoForm,
          cursor.card,
          column: cursor.column,
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
        diagnostics.report(msgInvalidDoForm, verb);
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
        if (!_commaContinuesList(cursor.peek(1), allowFigurative: true)) {
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

  /// A DO control parameter — the n of EXACTLY, or p, q, r of the
  /// indexed form: an integer literal or a field name (F pp. 50–51).
  /// The name parses without subscripts: a parenthesis after p is
  /// always the `(q)` group of `p(q)r`, never a subscript, so a
  /// subscripted parameter cannot be written (design note M2-16).
  ArithExpr _parseDoParameter(TokenCursor cursor) {
    final Token? token = cursor.peek();
    if (token == null) {
      throw _DeleteSentence.at(cursor, msgInvalidDoForm);
    }
    if (token.kind == TokenKind.numericLiteral) {
      return LiteralOperand(cursor.take());
    }
    if (token.kind == TokenKind.symbol &&
        (token.text == '-' || token.text == '+')) {
      // A signed integer parameter: the sign is the literal's own
      // (F p. 18, rule 2; D10.7).
      final Token? next = cursor.peek(1);
      if (next != null && next.kind == TokenKind.numericLiteral) {
        final Token sign = cursor.take();
        final literal = LiteralOperand(cursor.take());
        return sign.text == '-' ? UnaryExpr(sign, literal) : literal;
      }
    }
    if (token.kind == TokenKind.word && !isNameStopWord(token.text)) {
      final words = <Token>[cursor.take()];
      while (true) {
        final Token? next = cursor.peek();
        if (next == null ||
            next.kind != TokenKind.word ||
            isNameStopWord(next.text) ||
            figurativeConstants.contains(next.text)) {
          break;
        }
        words.add(cursor.take());
      }
      return NameOperand(NameReference(words));
    }
    throw _DeleteSentence.atToken(token, msgInvalidDoForm);
  }

  /// `index = p(q)r` (F pp. 50–51).
  DoIndex _parseDoIndex(TokenCursor cursor) {
    final NameReference index = _expectName(cursor, msgInvalidDoForm);
    if (!cursor.takeSymbol('=')) {
      throw _DeleteSentence.at(cursor, msgInvalidDoForm);
    }
    final ArithExpr from = _parseDoParameter(cursor);
    if (!cursor.takeSymbol('(')) {
      throw _DeleteSentence.at(cursor, msgInvalidDoForm);
    }
    final ArithExpr by = _parseDoParameter(cursor);
    if (!cursor.takeSymbol(')')) {
      throw _DeleteSentence.at(cursor, msgInvalidDoForm);
    }
    final ArithExpr to = _parseDoParameter(cursor);
    return DoIndex(index, from, by, to);
  }

  /// `STOP n` or `STOP RUN` — the operand is required (D2.7).
  Clause _parseStop(TokenCursor cursor) {
    final Token verb = cursor.take();
    if (cursor.takeWord('RUN')) {
      // _sawStopRun is set in _commitSentenceFacts, only once the
      // whole sentence has parsed (design note M2-13).
      return StopClause(verb, run: true);
    }
    final Token? token = cursor.peek();
    if (token != null && token.kind == TokenKind.numericLiteral) {
      if (token.text.length > 6) {
        // n is at most 6 digits (J 05.06.04).
        diagnostics.report(msgSentenceStructureError, token);
      }
      return StopClause(verb, number: cursor.take(), run: false);
    }
    // A bare STOP. is a syntax error (D2.7).
    throw _DeleteSentence.atToken(verb, msgIncompleteStatement);
  }

  /// `OPEN|CLOSE file, …` or `… ALL FILES` (F pp. 39, 41).
  Clause _parseOpenClose(TokenCursor cursor, {required bool open}) {
    final Token verb = cursor.take();
    if (cursor.isWord('ALL') && cursor.isWord('FILES', 1)) {
      cursor
        ..take()
        ..take();
      return open
          ? OpenClause(verb, const [], allFiles: true)
          : CloseClause(verb, const [], allFiles: true);
    }
    final Token? token = cursor.peek();
    if (token == null ||
        token.kind != TokenKind.word ||
        isNameStopWord(token.text)) {
      // Msgs 139/138: a file name must follow (J 90.04.01).
      throw _DeleteSentence.at(
        cursor,
        open ? msgOpenNeedsFileName : msgCloseNeedsFileName,
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
      cursor
        ..take()
        ..take();
      recordFrom = true;
    }
    final NameReference name = _expectName(cursor, msgIncompleteStatement);
    AtEndClause? atEnd;
    final bool commaAtEnd = cursor.isSymbol(',') && cursor.isWord('AT', 1);
    if (commaAtEnd || cursor.isWord('AT')) {
      if (commaAtEnd) {
        cursor.take();
      } else if (pedantic) {
        // AT END without its preceding comma is accepted silently, a
        // recorded leniency (D10.5b). --pedantic warns (msg 927;
        // D11.4); the clause parses the same either way.
        final Token peeked = cursor.peek()!;
        diagnostics.report(msgAtEndWithoutComma, peeked);
      }
      final Token at = cursor.take();
      if (!cursor.takeWord('END')) {
        throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
      diagnostics.reportAt(
        msgAtEndNeedsName,
        cursor.card,
        column: cursor.column,
        operands: [token?.text ?? ''],
      );
      return AtEndClause(at);
    }
    if (!_verbs.contains(token.text) && !isNameStopWord(token.text)) {
      // The bare-name form (D6.6, non-historical: compiled as DO name).
      return AtEndClause(at, bareName: parseNameReference(cursor, diagnostics));
    }
    if (isNameStopWord(token.text) && !_verbs.contains(token.text)) {
      diagnostics.report(msgAtEndNeedsName, token, operands: [token.text]);
      cursor.take();
      return AtEndClause(at);
    }
    final Clause statement = _parseClause(cursor);
    if (statement is! DoClause && statement is! GoToClause) {
      // A non-transfer clause is accepted at low severity (D6.6).
      // --pedantic issues 922 in place of 911 (D11.4); the clause is
      // kept as parsed either way.
      diagnostics.report(
        pedantic ? msgAtEndNotTransferRejected : msgAtEndNotTransfer,
        token,
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
        diagnostics.report(msgInvalidDisplay, token);
        cursor.take();
        continue;
      }
      break;
    }
    if (items.isEmpty) {
      diagnostics.report(msgInvalidDisplay, verb);
    }
    return DisplayClause(verb, items);
  }

  /// `CALL (old) new, …` (F p. 59; J 02.04.05).
  Clause _parseCall(TokenCursor cursor) {
    final Token verb = cursor.take();
    final pairs = <CallPair>[];
    while (true) {
      if (!cursor.takeSymbol('(')) {
        throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
      }
      final NameReference oldName = _expectName(
        cursor,
        msgIllegalSentenceStructure,
      );
      if (!cursor.takeSymbol(')')) {
        throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
      }
      final Token? newName = cursor.peek();
      if (newName == null ||
          newName.kind != TokenKind.word ||
          isNameStopWord(newName.text)) {
        throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
  /// pass-through until the reverse command; the switch is committed
  /// in _commitSentenceFacts, so a deleted ENTER sentence leaves the
  /// mode unchanged (design note M2-13).
  Clause _parseEnter(TokenCursor cursor) {
    final Token verb = cursor.take();
    if (cursor.takeWord('CRYPT')) {
      return EnterClause(verb, crypt: true);
    }
    if (cursor.takeWord('COMMERCIAL') && cursor.takeWord('TRANSLATOR')) {
      return EnterClause(verb, crypt: false);
    }
    throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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
      throw _DeleteSentence.at(cursor, msgIllegalSentenceStructure);
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

  /// A deferred verb: msg 110 for COPY/LIBRARY/INCLUDE (D9.8), the
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
      if (cursor.isWord('OTHERWISE')) {
        // A clause-series boundary (F p. 25): the word belongs to the
        // enclosing IF, never to the operand list.
        break;
      }
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
  /// source order through the arms and the nested ON OVERFLOW and AT
  /// END imperative clauses ([_clauseTree] walks exactly that order);
  /// then stamps the sentence's parser diagnostics with the clause they
  /// were raised in.
  void _numberClauses(List<Clause> clauses, int diagnosticsFrom) {
    var next = 1;
    for (final Clause clause in _clauseTree(clauses)) {
      clause.clause = next++;
    }
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

  /// The section bookkeeping over one sentence's clauses — nested ones
  /// included, so an END inside an IF arm is seen: BEGIN SECTION
  /// pushes (caps: 35 sections, msg 149; depth 18, msg 915 — D9.7,
  /// both severity 5, which stops compilation at the point of
  /// detection, D9.1), END pops (msgs 64, 65) and must be the
  /// sentence's only clause (msg 179).
  void _sectionWalk(List<Clause> clauses, ProcedureSentence scan) {
    final bool endAlone = clauses.length == 1 && clauses.first is EndClause;
    for (final Clause clause in _clauseTree(clauses)) {
      if (clause is BeginSectionClause) {
        _sectionCount++;
        if (_sectionCount > 35) {
          diagnostics.reportAt(msgTooManySections, scan.cards.first);
          throw const StopCompilation();
        }
        _openSections.add(scan.label ?? '');
        if (_openSections.length > 18) {
          diagnostics.reportAt(msgSectionsTooDeep, scan.cards.first);
          throw const StopCompilation();
        }
      } else if (clause is EndClause) {
        if (!endAlone) {
          diagnostics.report(msgEndNotAlone, clause.verb);
        }
        final String named = clause.sectionName?.text ?? '';
        if (_openSections.isEmpty) {
          diagnostics.report(msgEndWithoutSection, clause.verb);
        } else if (_openSections.last != named) {
          diagnostics.report(
            msgEndWrongSection,
            clause.verb,
            operands: [named, _openSections.last],
          );
          _openSections.removeLast();
        } else {
          _openSections.removeLast();
        }
      }
    }
  }
}
