/// The Procedure Division AST (M2).
///
/// Sentences, clauses, and the two expression families — arithmetic
/// (definition §4.1; J 02.04.05) and conditional (§5.3; F pp. 21–24,
/// 105–106). Every node carries its source tokens; name resolution and
/// format legality are M3's (design note M2-3).
library;

import '../lexer/procedure_lexer.dart';
import '../lexer/token.dart';

/// A reference to a data or procedure item: one or more blank-separated
/// qualifier words (§1.5; D2.5 — qualification is blank-separated,
/// never dotted) and optional subscripts.
final class NameReference {
  /// [words] runs most significant first.
  NameReference(this.words, [this.subscripts = const []]);

  final List<Token> words;

  /// The subscript expressions; at most three (D3.1). The restriction
  /// of subscript shape to name / integer / index expression (F p. 31)
  /// needs name kinds and is M3's.
  final List<ArithExpr> subscripts;

  /// The reference as written, blank-joined.
  String get text => words.map((Token t) => t.text).join(' ');

  /// The first token, for provenance.
  Token get anchor => words.first;
}

// --- Arithmetic expressions (§4.1) -----------------------------------------

/// An arithmetic expression node.
sealed class ArithExpr {
  /// The token the node anchors to, for provenance.
  Token get anchor;
}

/// A (possibly qualified, possibly subscripted) name operand.
final class NameOperand extends ArithExpr {
  NameOperand(this.name);

  final NameReference name;

  @override
  Token get anchor => name.anchor;
}

/// A literal operand — numeric, floating, or alphameric (the last is
/// legal only in comparisons and inside TR; the parser rejects it as a
/// bare arithmetic operand, F p. 45).
final class LiteralOperand extends ArithExpr {
  LiteralOperand(this.literal);

  final Token literal;

  @override
  Token get anchor => literal;
}

/// A figurative constant — ZERO(S), BLANK(S), HIGH.VALUE(S),
/// LOW.VALUE(S) (F pp. 19–20). Legal as a MOVE/SET source and as a
/// comparison operand, never inside a larger arithmetic expression
/// (design note M2-8).
final class FigurativeOperand extends ArithExpr {
  FigurativeOperand(this.word);

  final Token word;

  @override
  Token get anchor => word;
}

/// A binary operation `+ - * / **`, left-associative within its
/// precedence level (J 02.04.05.01).
final class BinaryExpr extends ArithExpr {
  BinaryExpr(this.left, this.operator, this.right, {this.recovered = false});

  final ArithExpr left;

  /// The operator token (`**` is one token).
  final Token operator;

  final ArithExpr right;

  /// True on a recovery-only grouping — `A**B**C` grouped left for
  /// error recovery; no code may be generated from it (D4.10).
  final bool recovered;

  @override
  Token get anchor => operator;
}

/// A unary operation — negation or ABS (J 02.04.05.01: they bind
/// tightest, above `**`, with TR; D4.4).
final class UnaryExpr extends ArithExpr {
  UnaryExpr(this.operator, this.operand);

  /// The operator token (`-` or `ABS`).
  final Token operator;

  /// The operand: a primary or a parenthesized expression (F p. 45).
  final ArithExpr operand;

  @override
  Token get anchor => operator;
}

/// A truth function `TR (conditional expression)`, contributing 1 or 0
/// (F p. 45).
final class TruthExpr extends ArithExpr {
  TruthExpr(this.word, this.condition);

  final Token word;

  final CondExpr condition;

  @override
  Token get anchor => word;
}

/// A function call `name ((argument, ...))` — double parentheses,
/// bare-name arguments (F p. 28 rule 15, p. 34).
final class FunctionCall extends ArithExpr {
  FunctionCall(this.function, this.arguments);

  final NameReference function;

  final List<NameReference> arguments;

  @override
  Token get anchor => function.anchor;
}

// --- Conditional expressions (§5.3) ----------------------------------------

/// A conditional expression node.
sealed class CondExpr {
  /// The token the node anchors to, for provenance.
  Token get anchor;
}

/// The three relations; NOT is carried separately (F p. 21).
enum RelationOp {
  /// IS `[NOT]` GREATER THAN / `[NOT]` GT.
  greater,

  /// IS `[NOT]` LESS THAN / `[NOT]` LT.
  less,

  /// IS `[NOT]` EQUAL TO / `[NOT]` =.
  equal,
}

/// A relation `operand relational-operator operand`; both operands
/// always written in full — no elliptical forms (F p. 23 rule 3).
final class Relation extends CondExpr {
  Relation(this.left, this.op, this.right, {required this.negated});

  final ArithExpr left;

  final RelationOp op;

  /// Whether the relation is negated (NOT GT, NOT =, NOT LT, IS NOT …).
  final bool negated;

  final ArithExpr right;

  @override
  Token get anchor => left.anchor;
}

/// A bare name in condition position: a condition-name test (F p. 22).
/// Whether the name is in fact a condition-name is M3's; a subscript
/// here is rejected at parse time (J 90.01.03; D5.6).
final class ConditionReference extends CondExpr {
  ConditionReference(this.name);

  final NameReference name;

  @override
  Token get anchor => name.anchor;
}

/// `left AND right` — binds tighter than OR (F p. 105 rule 3).
final class AndExpr extends CondExpr {
  AndExpr(this.left, this.right);

  final CondExpr left;

  final CondExpr right;

  @override
  Token get anchor => left.anchor;
}

/// `left OR right` — inclusive (F p. 23).
final class OrExpr extends CondExpr {
  OrExpr(this.left, this.right);

  final CondExpr left;

  final CondExpr right;

  @override
  Token get anchor => left.anchor;
}

/// `NOT condition` — NOT may precede only a condition or a left
/// parenthesis; `NOT NOT` is illegal (F p. 106 rule 4).
final class NotExpr extends CondExpr {
  NotExpr(this.word, this.operand);

  final Token word;

  final CondExpr operand;

  @override
  Token get anchor => word;
}

// --- Clauses ---------------------------------------------------------------

/// One clause of a sentence. [clause] is its two-digit position for
/// `n,cc` statement numbers: the conditional clause takes 01 when
/// present and each imperative clause takes the next number, in source
/// order through the THEN and OTHERWISE arms (design note M2-6,
/// non-historical).
sealed class Clause {
  /// The clause number within the sentence, 1-based; 0 until assigned.
  int clause = 0;

  /// The token the clause anchors to, for provenance.
  Token get anchor;
}

/// The conditional clause `IF condition THEN … [OTHERWISE …]` — at most
/// one per sentence, first when present (F p. 25).
final class IfClause extends Clause {
  IfClause(this.word, this.condition, this.thenArm, this.otherwiseArm);

  final Token word;

  final CondExpr condition;

  /// The THEN arm's imperative clauses, in order.
  final List<Clause> thenArm;

  /// The OTHERWISE arm's imperative clauses; empty without OTHERWISE.
  final List<Clause> otherwiseArm;

  @override
  Token get anchor => word;
}

/// `MOVE [CORRESPONDING] source TO target, …` (F pp. 42–43). No
/// TRUNCATED or ON OVERFLOW clause exists on MOVE (§8.5.4).
final class MoveClause extends Clause {
  MoveClause(
    this.verb,
    this.source,
    this.targets, {
    required this.corresponding,
  });

  final Token verb;

  /// Whether CORRESPONDING is present (J 02.04.04).
  final bool corresponding;

  /// The source: a name, a literal — the sample attests alphameric
  /// literal sources (statements 193, 196, 199) — or a figurative
  /// constant (design note M2-8).
  final ArithExpr source;

  final List<NameReference> targets;

  @override
  Token get anchor => verb;
}

/// `SET target, … = expression [TRUNCATED] [, ON OVERFLOW clause]`
/// (F pp. 44, 109).
final class SetClause extends Clause {
  SetClause(
    this.verb,
    this.targets,
    this.value, {
    required this.truncated,
    this.onOverflow,
  });

  final Token verb;

  final List<NameReference> targets;

  /// The right-hand side: an arithmetic expression or a figurative
  /// constant (design note M2-8).
  final ArithExpr value;

  final bool truncated;

  /// The ON OVERFLOW imperative clause; legal only with exactly one
  /// target (F p. 44).
  final Clause? onOverflow;

  @override
  Token get anchor => verb;
}

/// `SET condition.name` — the switch-setting form (F p. 46; D5.6).
final class SetConditionClause extends Clause {
  SetConditionClause(this.verb, this.conditionName);

  final Token verb;

  /// The condition-name; never subscripted (J 90.01.03; D5.6).
  final NameReference conditionName;

  @override
  Token get anchor => verb;
}

/// `ADD` `[CORRESPONDING]` source TO target, … `[TRUNCATED]`
/// `[, ON OVERFLOW clause]` (F pp. 47, 108; design note M2-9).
final class AddClause extends Clause {
  AddClause(
    this.verb,
    this.source,
    this.targets, {
    required this.corresponding,
    required this.truncated,
    this.onOverflow,
  });

  final Token verb;

  final bool corresponding;

  /// The addend: a name or a literal (F p. 47).
  final ArithExpr source;

  final List<NameReference> targets;

  final bool truncated;

  /// The ON OVERFLOW imperative clause; single-target only.
  final Clause? onOverflow;

  @override
  Token get anchor => verb;
}

/// One target of a GO TO, with its WHEN condition in the conditional
/// form (F p. 48).
final class GoToTarget {
  GoToTarget(this.name, this.when);

  /// The procedure name.
  final NameReference name;

  /// The WHEN condition; `null` in the unconditional and assigned
  /// forms.
  final CondExpr? when;
}

/// `GO TO name`, `GO TO name WHEN cond, …`, or
/// `GO TO (name, …) ON index` (F pp. 48–49).
final class GoToClause extends Clause {
  GoToClause(this.verb, this.targets, {this.index});

  final Token verb;

  final List<GoToTarget> targets;

  /// The index name of the assigned form, or `null`.
  final NameReference? index;

  @override
  Token get anchor => verb;
}

/// One `index = p(q)r` specification of an indexed DO (F pp. 50–51).
final class DoIndex {
  DoIndex(this.index, this.from, this.by, this.to);

  final NameReference index;

  /// p — the starting value: an integer literal or field name.
  final ArithExpr from;

  /// q — the increment.
  final ArithExpr by;

  /// r — the terminal value (strict-equality exit, D5.1).
  final ArithExpr to;
}

/// `DO procedure [EXACTLY n TIMES | FOR index = p(q)r, …]
/// [USING …] [GIVING …]` (F p. 108; D5.2: at most three indices).
final class DoClause extends Clause {
  DoClause(
    this.verb,
    this.procedure, {
    this.exactlyTimes,
    this.indices = const [],
    this.usingArguments = const [],
    this.givingResults = const [],
  });

  final Token verb;

  /// The procedure or section name.
  final NameReference procedure;

  /// The count of `EXACTLY n TIMES`, or `null`.
  final ArithExpr? exactlyTimes;

  /// The `FOR` index specifications, at most three (D5.2).
  final List<DoIndex> indices;

  /// The USING arguments: names, literals, figurative constants
  /// (F p. 52).
  final List<ArithExpr> usingArguments;

  final List<NameReference> givingResults;

  @override
  Token get anchor => verb;
}

/// `STOP n` or `STOP RUN` — the operand is required; a bare `STOP.` is
/// a syntax error (D2.7).
final class StopClause extends Clause {
  StopClause(this.verb, {required this.run, this.number});

  final Token verb;

  /// The halt number, at most 6 digits (J 05.06.04), or `null` for
  /// STOP RUN.
  final Token? number;

  /// Whether the clause is STOP RUN (J 02.04.06).
  final bool run;

  @override
  Token get anchor => verb;
}

/// `OPEN file, …` or `OPEN ALL FILES` (F p. 39).
final class OpenClause extends Clause {
  OpenClause(this.verb, this.files, {required this.allFiles});

  final Token verb;

  final bool allFiles;

  /// The file names; empty in the ALL FILES form.
  final List<NameReference> files;

  @override
  Token get anchor => verb;
}

/// `CLOSE file, …` or `CLOSE ALL FILES` (F p. 41).
final class CloseClause extends Clause {
  CloseClause(this.verb, this.files, {required this.allFiles});

  final Token verb;

  final bool allFiles;

  /// The file names; empty in the ALL FILES form.
  final List<NameReference> files;

  @override
  Token get anchor => verb;
}

/// The AT END clause of a GET (J 02.07.05; D6.6): one imperative
/// statement, a bare procedure name, or nothing.
final class AtEndClause {
  AtEndClause(this.anchor, {this.statement, this.bareName});

  /// The `AT` token.
  final Token anchor;

  /// The single imperative clause, when one is written.
  final Clause? statement;

  /// The bare procedure name form, compiled as `DO name` (D6.6,
  /// non-historical).
  final NameReference? bareName;
}

/// `GET record` or `GET RECORD FROM file`, with an optional AT END
/// (J 02.07.04; F pp. 39–40).
final class GetClause extends Clause {
  GetClause(this.verb, this.name, {required this.recordFrom, this.atEnd});

  final Token verb;

  /// Whether the `GET RECORD FROM file` form is used.
  final bool recordFrom;

  /// The record name, or the file name in the RECORD FROM form.
  final NameReference name;

  final AtEndClause? atEnd;

  @override
  Token get anchor => verb;
}

/// `FILE record [IN file]` (F pp. 40–41; J 02.07.07–08). No clause of
/// its own — error handling is Environment-card-declared (§6.6).
final class FileClause extends Clause {
  FileClause(this.verb, this.record, {this.inFile});

  final Token verb;

  final NameReference record;

  /// The file name after IN, or `null`.
  final NameReference? inFile;

  @override
  Token get anchor => verb;
}

/// `DISPLAY item …` — quoted literals and comma-separated name
/// references; juxtaposed words form one qualified name (J 90.01.01;
/// design note M2-10).
final class DisplayClause extends Clause {
  DisplayClause(this.verb, this.items);

  final Token verb;

  /// The items, in order: [LiteralOperand]s and [NameOperand]s.
  final List<ArithExpr> items;

  @override
  Token get anchor => verb;
}

/// One `(old.name) new.name` pair of a CALL (F p. 59).
final class CallPair {
  CallPair(this.oldName, this.newName);

  /// The existing (possibly compound) name.
  final NameReference oldName;

  /// The new single-word synonym.
  final Token newName;
}

/// `CALL (old) new, …` (F p. 59; J 02.04.05).
final class CallClause extends Clause {
  CallClause(this.verb, this.pairs);

  final Token verb;

  final List<CallPair> pairs;

  @override
  Token get anchor => verb;
}

/// `ENTER CRYPT` or `ENTER COMMERCIAL TRANSLATOR` — the only two J
/// forms (J 02.04.02.01).
final class EnterClause extends Clause {
  EnterClause(this.verb, {required this.crypt});

  final Token verb;

  /// True for ENTER CRYPT, false for ENTER COMMERCIAL TRANSLATOR.
  final bool crypt;

  @override
  Token get anchor => verb;
}

/// `NOTE any text.` — listing-only commentary (F p. 59).
final class NoteClause extends Clause {
  NoteClause(this.verb, this.text);

  final Token verb;

  /// The raw text tokens, one per card.
  final List<Token> text;

  @override
  Token get anchor => verb;
}

/// `BEGIN SECTION [USING …] [GIVING …]` (F p. 57).
final class BeginSectionClause extends Clause {
  BeginSectionClause(
    this.verb, {
    this.usingParameters = const [],
    this.givingFunctions = const [],
  });

  final Token verb;

  final List<NameReference> usingParameters;

  final List<NameReference> givingFunctions;

  @override
  Token get anchor => verb;
}

/// `END section.name` — the only clause of its sentence (msg 179).
final class EndClause extends Clause {
  EndClause(this.verb, this.sectionName);

  final Token verb;

  /// The named section, or `null` when missing (diagnosed).
  final NameReference? sectionName;

  @override
  Token get anchor => verb;
}

/// A verb the field-test compiler defers — LOAD, OVERLAP, INCLUDE,
/// COPY, LIBRARY (J 90.01.02–03; D9.8; design note M2-11). Parsed as
/// its verb plus raw operand tokens; diagnosed at parse time.
final class DeferredVerbClause extends Clause {
  DeferredVerbClause(this.verb, this.operands);

  final Token verb;

  final List<Token> operands;

  @override
  Token get anchor => verb;
}

// --- Sentences -------------------------------------------------------------

/// One parsed sentence.
final class Sentence {
  Sentence(this.scan, this.clauses, {required this.deleted});

  /// The M1 scan sentence: label, tokens, cards.
  final ProcedureSentence scan;

  /// The top-level clauses: `[IfClause]` alone for a conditional
  /// sentence, else the imperative clauses in order. Empty when
  /// [deleted].
  final List<Clause> clauses;

  /// Whether recovery deleted the sentence from the text (msgs 122,
  /// 125, 126, 171; design note M2-13). A deleted sentence keeps its
  /// statement number.
  final bool deleted;
}

// --- Clause traversal ------------------------------------------------------

/// Every clause of [clauses], nested ones included: IF arms, ON
/// OVERFLOW slots, and AT END slots.
Iterable<Clause> clauseTree(List<Clause> clauses) sync* {
  for (final clause in clauses) {
    yield clause;
    switch (clause) {
      case IfClause(:final thenArm, :final otherwiseArm):
        yield* clauseTree(thenArm);
        yield* clauseTree(otherwiseArm);
      case SetClause(:final onOverflow?):
        yield* clauseTree([onOverflow]);
      case AddClause(:final onOverflow?):
        yield* clauseTree([onOverflow]);
      case GetClause(atEnd: AtEndClause(:final statement?)):
        yield* clauseTree([statement]);
      default:
        break;
    }
  }
}
