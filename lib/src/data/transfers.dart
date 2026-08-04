/// Transfer targets, DO substitution, loop control, and function
/// references (M3-19; M3-20).
///
/// The checker runs after the resolver, so every data reference it
/// reads is already triaged: it looks its operands up in
/// `NameResolver.dataResolutions` rather than resolving them again.
/// Procedure names are its own, because no other site resolves them
/// (D2.5).
library;

import '../ast/data_ast.dart';
import '../ast/procedure_ast.dart';
import '../lexer/messages.dart';
import '../lexer/token.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'dictionary.dart';
import 'mapper.dart';
import 'resolver.dart';

/// Checks the transfer, DO, loop-control, and function sites of the
/// procedure division.
final class TransferChecker extends ClauseWalk {
  TransferChecker(super.diagnostics, this.mapper, this.resolver);

  final DataMapper mapper;
  final NameResolver resolver;

  /// Every procedure a DO addresses. Built before the GO TO checks,
  /// because a DO may follow the transfer it forbids (Open Question
  /// 40).
  final Set<DictionaryEntry> _doAddressed = Set.identity();

  /// The section that declares each function — the BEGIN SECTION whose
  /// GIVING clause lists the name (M3-19).
  final Map<DataItem, BeginSectionClause> _functions = Map.identity();

  @override
  Set<Sentence> get deletedSentences => resolver.deletedSentences;

  void check(List<List<Sentence>> procedureGroups) {
    walkClauses(procedureGroups, _collect);
    walkClauses(procedureGroups, _checkClause);
  }

  /// The two forward-looking facts: what a DO addresses, and what a
  /// GIVING clause declares a function.
  void _collect(Clause clause) {
    switch (clause) {
      case DoClause(:final procedure):
        _addDoTarget(procedure);
      case GetClause(atEnd: AtEndClause(bareName: final NameReference name?)):
        _addDoTarget(name);
      case final BeginSectionClause section:
        for (final NameReference function in section.givingFunctions) {
          final DataItem? item = resolver.dataResolutions[function];
          if (item != null) {
            _functions[item] = section;
          }
        }
      default:
        break;
    }
  }

  void _addDoTarget(NameReference reference) {
    final DictionaryEntry? target = _resolveProcedure(reference, quiet: true);
    if (target != null) {
      _doAddressed.add(target);
    }
  }

  void _checkClause(Clause clause) {
    switch (clause) {
      case IfClause(:final condition):
        _checkCondition(condition);
      case MoveClause(:final source, :final targets):
        _checkExpression(source);
        targets.forEach(_checkReference);
      case SetClause(:final targets, :final value):
        targets.forEach(_checkReference);
        _checkExpression(value);
      case AddClause(:final source, :final targets):
        _checkExpression(source);
        targets.forEach(_checkReference);
      case DisplayClause(:final items):
        items.forEach(_checkExpression);
      case GetClause(atEnd: AtEndClause(bareName: final NameReference name?)):
        // An AT END bare name is compiled as `DO name` (D6.6).
        _resolveProcedure(name, absent: msgDoTargetNotProcedure);
      case final GoToClause transfer:
        _checkGoTo(transfer);
      case final DoClause loop:
        _checkDo(loop);
      case SetConditionClause() ||
          BeginSectionClause() ||
          CallClause() ||
          OpenClause() ||
          CloseClause() ||
          GetClause() ||
          FileClause() ||
          StopClause() ||
          EnterClause() ||
          NoteClause() ||
          EndClause() ||
          DeferredVerbClause():
        break;
    }
  }

  // ── Transfers (M3-20) ────────────────────────────────────────────

  void _checkGoTo(GoToClause clause) {
    for (final GoToTarget target in clause.targets) {
      final CondExpr? when = target.when;
      if (when != null) {
        _checkCondition(when);
      }
      final DictionaryEntry? entry = _resolveProcedure(
        target.name,
        absent: msgTransferTargetNotProcedure,
      );
      if (entry != null && _doAddressed.contains(entry)) {
        // A DO-addressed procedure returns to its caller, so a
        // transfer into it has no exit (Open Question 40).
        report(
          msgTransferToDoAddressed,
          target.name.anchor,
          operands: [target.name.text],
        );
      }
    }
    final NameReference? index = clause.index;
    if (index != null) {
      _checkTransferIndex(index);
    }
  }

  void _checkTransferIndex(NameReference index) {
    final ItemSemantics? sem = _semanticsOf(index);
    if (sem == null) {
      return; // The triage diagnosed the reference already.
    }
    if (_nonNumeric(sem)) {
      report(msgTransferIndexFormat, index.anchor);
    } else if (sem.fractionDigits != 0) {
      report(msgTransferIndexNotInteger, index.anchor);
    }
  }

  /// The D2.5 target model. A one-word target is a statement label of
  /// the referencing sentence's own section, else a section name, else
  /// a statement label of the outermost scope; `A B` is section A's
  /// label B. [absent] speaks for a target that names none of these.
  DictionaryEntry? _resolveProcedure(
    NameReference reference, {
    Message? absent,
    bool quiet = false,
  }) {
    final List<DictionaryEntry> named = resolver.dictionary.named(
      reference.words.last.text,
    );
    List<DictionaryEntry> labelsOf(String? section) => [
      for (final DictionaryEntry entry in named)
        if (entry.kind == NameKind.statement && entry.section == section) entry,
    ];
    var candidates = const <DictionaryEntry>[];
    if (reference.words.length == 2) {
      candidates = labelsOf(reference.words.first.text);
    } else if (reference.words.length == 1) {
      candidates = labelsOf(resolver.sectionScopes[currentSentence]);
      if (candidates.isEmpty) {
        candidates = [
          for (final DictionaryEntry entry in named)
            if (entry.kind == NameKind.section) entry,
        ];
      }
      if (candidates.isEmpty) {
        candidates = labelsOf(null);
      }
    }
    if (candidates.length == 1) {
      return candidates.single;
    }
    if (quiet) {
      return null;
    }
    if (candidates.length > 1) {
      report(msgNameNotUnique, reference.anchor, operands: [reference.text]);
    } else if (absent != null) {
      report(absent, reference.anchor, operands: [reference.text]);
    }
    return null;
  }

  // ── DO substitution and loop control (M3-19; M3-20) ──────────────

  void _checkDo(DoClause clause) {
    final DictionaryEntry? target = _resolveProcedure(
      clause.procedure,
      absent: msgDoTargetNotProcedure,
    );
    if (target != null) {
      _checkSubstitution(clause, target);
    }
    final ArithExpr? times = clause.exactlyTimes;
    if (times != null) {
      _checkExpression(times);
    }
    for (final DoIndex index in clause.indices) {
      _checkLoopVariable(index.index);
      for (final ArithExpr parameter in [index.from, index.by, index.to]) {
        _checkLoopParameter(parameter, index.index);
      }
    }
    clause.usingArguments.forEach(_checkExpression);
    clause.givingResults.forEach(_checkReference);
  }

  /// The USING and GIVING counts against the target's declaration. A
  /// statement target declares neither, so every argument on it is an
  /// excess (M3-19). An absent clause substitutes nothing and is
  /// legal: the values already in the parameter or function fields
  /// serve (F p. 33).
  void _checkSubstitution(DoClause clause, DictionaryEntry target) {
    final BeginSectionClause? section = target.kind == NameKind.section
        ? target.sentence!.clauses.whereType<BeginSectionClause>().firstOrNull
        : null;
    final int using = section?.usingParameters.length ?? 0;
    final int giving = section?.givingFunctions.length ?? 0;
    if (clause.usingArguments.isNotEmpty) {
      if (clause.usingArguments.length > using) {
        report(msgTooManyUsingParameters, clause.verb);
      } else if (clause.usingArguments.length < using) {
        report(msgTooFewUsingParameters, clause.verb);
      }
    }
    if (clause.givingResults.isNotEmpty) {
      if (clause.givingResults.length > giving) {
        report(msgTooManyGivingParameters, clause.verb);
      } else if (clause.givingResults.length < giving) {
        report(msgTooFewGivingParameters, clause.verb);
      }
    }
  }

  void _checkLoopVariable(NameReference index) {
    _checkReference(index);
    final ItemSemantics? sem = _semanticsOf(index);
    if (sem != null && _nonNumeric(sem)) {
      report(msgLoopVariableFormat, index.anchor, operands: [index.text]);
    }
  }

  /// p, q, and r take an integer literal or a field name (F pp. 50–51);
  /// the parser admits no other shape.
  void _checkLoopParameter(ArithExpr parameter, NameReference index) {
    switch (parameter) {
      case NameOperand(:final name):
        final ItemSemantics? sem = _semanticsOf(name);
        if (sem != null && _nonNumeric(sem)) {
          report(msgLoopParameterFormat, name.anchor, operands: [name.text]);
        }
      case LiteralOperand(:final literal):
        _checkLoopLiteral(literal, index);
      case UnaryExpr(operand: LiteralOperand(:final literal)):
        _checkLoopLiteral(literal, index);
      default:
        break;
    }
  }

  void _checkLoopLiteral(Token literal, NameReference index) {
    final num? value = literal.kind == TokenKind.alphamericLiteral
        ? null
        : num.tryParse(literal.text);
    if (value == null || value != value.truncate()) {
      report(msgLoopLiteralParameterFormat, literal, operands: [index.text]);
    }
  }

  // ── Functions (M3-19) ────────────────────────────────────────────

  void _checkFunction(FunctionCall call) {
    call.arguments.forEach(_checkReference);
    final DataItem? item = resolver.dataResolutions[call.function];
    if (item == null) {
      return; // The triage diagnosed the name already.
    }
    final BeginSectionClause? section = _functions[item];
    if (section == null) {
      // A function is a data name a BEGIN SECTION GIVING clause lists;
      // nothing else may be evaluated (M3-19).
      report(
        msgNotProperlyDefined,
        call.function.anchor,
        operands: [call.function.text],
      );
      return;
    }
    final int declared = section.usingParameters.length;
    if (call.arguments.length < declared) {
      report(
        msgFunctionArgumentsMissing,
        call.function.anchor,
        operands: [call.function.text],
      );
    } else if (call.arguments.length > declared) {
      report(
        msgFunctionTooManyArguments,
        call.function.anchor,
        operands: [call.function.text],
      );
    }
  }

  // ── The expression walk ──────────────────────────────────────────

  void _checkReference(NameReference reference) =>
      reference.subscripts.forEach(_checkExpression);

  void _checkExpression(ArithExpr expression) {
    switch (expression) {
      case final FunctionCall call:
        _checkFunction(call);
      case NameOperand(:final name):
        _checkReference(name);
      case BinaryExpr(:final left, :final right):
        _checkExpression(left);
        _checkExpression(right);
      case UnaryExpr(:final operand):
        _checkExpression(operand);
      case TruthExpr(:final condition):
        _checkCondition(condition);
      case LiteralOperand() || FigurativeOperand():
        break;
    }
  }

  void _checkCondition(CondExpr condition) {
    switch (condition) {
      case Relation(:final left, :final right):
        _checkExpression(left);
        _checkExpression(right);
      case AndExpr(:final left, :final right):
        _checkCondition(left);
        _checkCondition(right);
      case OrExpr(:final left, :final right):
        _checkCondition(left);
        _checkCondition(right);
      case NotExpr(:final operand):
        _checkCondition(operand);
      case ConditionReference():
        break;
    }
  }

  ItemSemantics? _semanticsOf(NameReference reference) {
    final DataItem? item = resolver.dataResolutions[reference];
    return item == null ? null : mapper.semantics[item];
  }

  /// Whether the field holds no index value: an alphameric, edited, or
  /// group field (M3-20).
  bool _nonNumeric(ItemSemantics sem) =>
      sem.fieldClass == FieldClass.alphameric ||
      sem.fieldClass == FieldClass.edited ||
      sem.fieldClass == FieldClass.group;
}
