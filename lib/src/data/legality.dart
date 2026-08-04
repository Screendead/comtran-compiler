/// Reference legality (M3-10; M3-21): with names and types resolved,
/// the MOVE, ADD, SET, comparison, and figurative-constant tables of
/// J 02.04 become checks over the procedure clauses.
///
/// The checker classifies and diagnoses only; the code shapes stay M4's
/// (M3-10). Its one product for M4 is [LegalityChecker.correspondingPairs].
library;

import '../ast/data_ast.dart';
import '../ast/procedure_ast.dart';
import '../lexer/token.dart';
import '../parser/parser_messages.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'mapper.dart';
import 'resolver.dart';

/// An operand's class for the MOVE and comparison tables. A group field
/// "has no format characteristics of its own and is assumed to be
/// alphameric" (J 02.04.04; D3.3), and an edited field compares as
/// numeric (J 02.04.07 rule 3).
enum OperandClass { alphameric, numeric, unknown }

/// Checks every procedure clause against the J 02.04 legality tables.
final class LegalityChecker extends ClauseWalk {
  LegalityChecker(
    super.diagnostics,
    this.mapper,
    this.resolver, {
    this.pedantic = false,
  });

  final DataMapper mapper;
  final NameResolver resolver;
  final bool pedantic;

  /// The CORRESPONDING pairs of each clause, source first, in
  /// data-description order — M4 generates one move or add sequence per
  /// pair (D4.12).
  final Map<Clause, List<(DataItem, DataItem)>> correspondingPairs =
      Map.identity();

  @override
  Set<Sentence> get deletedSentences => resolver.deletedSentences;

  void check(List<List<Sentence>> procedureGroups) {
    walkClauses(procedureGroups, _checkClause);
  }

  void _checkClause(Clause clause) {
    switch (clause) {
      case IfClause(:final condition):
        _checkCondition(condition);
      case MoveClause(:final source, :final targets, :final corresponding):
        if (corresponding) {
          _checkCorresponding(clause, source, targets, add: false);
          return;
        }
        _checkArith(source, inArithmetic: false);
        for (final target in targets) {
          _checkMove(source, target);
        }
      case SetClause(:final targets, :final value):
        _checkArith(value, inArithmetic: false);
        if (value is FigurativeOperand) {
          // The chart governs "MOVEing and SETting figurative constants"
          // alike (J 02.04.02).
          for (final target in targets) {
            _checkFigurative(value, target);
          }
        }
      case AddClause(:final source, :final targets, :final corresponding):
        if (corresponding) {
          _checkCorresponding(clause, source, targets, add: true);
          return;
        }
        _checkArith(source, inArithmetic: false);
        _checkAddOperand(_classOf(source), _nameOf(source), source.anchor);
        for (final target in targets) {
          _checkAddOperand(_classOfRef(target), target.text, target.anchor);
        }
      case GoToClause(:final targets):
        for (final target in targets) {
          final CondExpr? when = target.when;
          if (when != null) {
            _checkCondition(when);
          }
        }
      case DoClause(:final exactlyTimes, :final indices, :final usingArguments):
        if (exactlyTimes != null) {
          _checkArith(exactlyTimes, inArithmetic: false);
        }
        for (final index in indices) {
          _checkArith(index.from, inArithmetic: false);
          _checkArith(index.by, inArithmetic: false);
          _checkArith(index.to, inArithmetic: false);
        }
        for (final argument in usingArguments) {
          _checkArith(argument, inArithmetic: false);
        }
      case SetConditionClause() ||
          DisplayClause() ||
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

  // ── MOVE (J 02.04.03 c) ──────────────────────────────────────────

  void _checkMove(ArithExpr source, NameReference target) {
    if (source is FigurativeOperand) {
      _checkFigurative(source, target);
      return;
    }
    final DataItem? item = _resolved(target);
    if (item == null || _classOf(source) != OperandClass.alphameric) {
      return;
    }
    if (_classOfItem(item) != OperandClass.alphameric) {
      // "The contents of an alphameric field may only be moved to
      // another alphameric field" (J 02.04.03 c).
      report(
        msgIllegalMove,
        target.anchor,
        operands: [_nameOf(source), target.text],
      );
    }
  }

  /// The J 02.04.02 chart, plus the two target-length restrictions of
  /// J 02.04.01 c.
  void _checkFigurative(FigurativeOperand figurative, NameReference target) {
    final DataItem? item = _resolved(target);
    final ItemSemantics? sem = item == null ? null : mapper.semantics[item];
    if (item == null || sem == null) {
      return;
    }
    final Token at = target.anchor;
    if (target.subscripts.isEmpty && _isVariableLength(item)) {
      // The whole variable array is barred; one element of it is not
      // (J 02.04.01 c-i).
      report(msgFigurativeToVariableField, at);
      return;
    }
    if (sem.extentChars > 32766) {
      // The implemented maximum, against J's prose 2^15 - 1 (D4.6).
      report(msgFigurativeToLongField, at);
      return;
    }
    final String word = figurative.word.text;
    if (word.startsWith('ZERO')) {
      return; // Legal in every column of the chart.
    }
    if (word.startsWith('BLANK')) {
      // The starred BLANK cells are doubtful, not illegal (D4.11). The
      // edited one is attested-silent: the 90.05 sample blanks two
      // edited fields and reports no error.
      if (pedantic &&
          _classOfItem(item) == OperandClass.numeric &&
          sem.fieldClass != FieldClass.edited) {
        report(msgDoubtfulFigurativeUsage, at);
      }
      return;
    }
    if (sem.fieldClass == FieldClass.internalDecimal ||
        sem.fieldClass == FieldClass.floatingPoint) {
      // The chart's two Illegal cells for HIGH.VALUE and LOW.VALUE.
      report(msgIncorrectFigurativeUsage, at);
    }
  }

  // ── CORRESPONDING (D4.12; J 02.04.04) ────────────────────────────

  void _checkCorresponding(
    Clause clause,
    ArithExpr source,
    List<NameReference> targets, {
    required bool add,
  }) {
    final DataItem? root = source is NameOperand
        ? _resolved(source.name)
        : null;
    if (!_isGroup(root)) {
      // Correspondence is sought below the operand, so an operand that
      // resolves to nothing, or to a field with no subordinates, has
      // none (J 02.04.04).
      report(msgInvalidCorresponding, source.anchor);
    }
    final pairs = <(DataItem, DataItem)>[];
    var searched = false;
    for (final target in targets) {
      final DataItem? item = _resolved(target);
      if (!_isGroup(item)) {
        report(msgInvalidCorresponding, target.anchor);
        continue;
      }
      if (!_isGroup(root)) {
        continue;
      }
      searched = true;
      final List<(DataItem, DataItem)> matched = _pairBelow(root!, item!);
      pairs.addAll(matched);
      for (final (DataItem from, DataItem to) in matched) {
        final OperandClass fromClass = _classOfItem(from);
        final OperandClass toClass = _classOfItem(to);
        if (add) {
          _checkAddOperand(fromClass, _qualifiedName(from), target.anchor);
          _checkAddOperand(toClass, _qualifiedName(to), target.anchor);
        } else if (fromClass == OperandClass.alphameric &&
            toClass != OperandClass.alphameric) {
          // A matched group source "has no format characteristics of
          // its own and is assumed to be alphameric"; the pair then
          // meets the ordinary MOVE table (J 02.04.04 c; D4.12).
          report(
            msgIllegalMove,
            target.anchor,
            operands: [_qualifiedName(from), _qualifiedName(to)],
          );
        }
      }
    }
    correspondingPairs[clause] = pairs;
    if (pedantic && searched && pairs.isEmpty) {
      report(msgCorrespondingMatchesNothing, source.anchor);
    }
  }

  bool _isGroup(DataItem? item) =>
      item != null && mapper.semantics[item]?.fieldClass == FieldClass.group;

  /// The pairs below [from] and [to]: matching names, descended to the
  /// lowest level at which no descendant pair matches (D4.12;
  /// J 02.04.04 examples a and c).
  List<(DataItem, DataItem)> _pairBelow(DataItem from, DataItem to) {
    final pairs = <(DataItem, DataItem)>[];
    for (final DataItem child in from.children) {
      final String name = child.entry.name;
      if (name.isEmpty || child.nameDiscarded || !_pairable(child)) {
        continue;
      }
      final DataItem? mate = to.children
          .where(
            (DataItem c) =>
                c.entry.name == name && !c.nameDiscarded && _pairable(c),
          )
          .firstOrNull;
      if (mate == null) {
        continue;
      }
      final List<(DataItem, DataItem)> deeper = _pairBelow(child, mate);
      pairs.addAll(deeper.isEmpty ? [(child, mate)] : deeper);
    }
    return pairs;
  }

  bool _pairable(DataItem item) =>
      item.typeCode != DataTypeCode.cond && item.typeCode != DataTypeCode.redef;

  // ── ADD (J 02.04.05) ─────────────────────────────────────────────

  void _checkAddOperand(OperandClass operandClass, String name, Token at) {
    if (operandClass == OperandClass.alphameric) {
      // The operand is eliminated from the ADD; the rest proceed.
      report(msgEliminatedFromAdd, at, operands: [name]);
    }
  }

  // ── Arithmetic expressions (J 02.04.05 §6) ───────────────────────

  /// Flags every alphameric-class operand under an operator. A bare
  /// name, literal, or figurative is a copy, not an expression: "the
  /// result field may be alphameric ... since no arithmetic expression
  /// is specified" (J 02.04.05 §6).
  void _checkArith(ArithExpr expr, {required bool inArithmetic}) {
    switch (expr) {
      case NameOperand(:final name):
        if (inArithmetic && _classOfRef(name) == OperandClass.alphameric) {
          report(msgImproperFormatForUse, name.anchor, operands: [name.text]);
        }
      case BinaryExpr(:final left, :final right):
        _checkArith(left, inArithmetic: true);
        _checkArith(right, inArithmetic: true);
      case UnaryExpr(:final operand):
        _checkArith(operand, inArithmetic: true);
      case TruthExpr(:final condition):
        _checkCondition(condition);
      case LiteralOperand() || FigurativeOperand() || FunctionCall():
        break;
    }
  }

  // ── Comparisons (J 02.04.07) ─────────────────────────────────────

  void _checkCondition(CondExpr condition) {
    switch (condition) {
      case Relation(:final left, :final right):
        _checkArith(left, inArithmetic: false);
        _checkArith(right, inArithmetic: false);
        _checkComparand(left);
        _checkComparand(right);
        _checkFigurativeComparison(left, right);
        _checkFigurativeComparison(right, left);
        _checkComparisonClasses(left, right);
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

  void _checkComparand(ArithExpr operand) {
    if (operand is! NameOperand) {
      return;
    }
    final DataItem? item = _resolved(operand.name);
    if (item != null && _isVariableLength(item)) {
      // "Variable length fields may not be compared" (J 02.04.07
      // rule 5).
      report(msgVariableLengthComparison, operand.anchor);
    }
  }

  void _checkFigurativeComparison(ArithExpr figurative, ArithExpr other) {
    if (figurative is! FigurativeOperand ||
        figurative.word.text.startsWith('ZERO')) {
      return; // "ZERO may be compared to either numeric or alphameric".
    }
    if (_classOf(other) == OperandClass.numeric) {
      // "HIGH.VALUE, LOW.VALUE and BLANK may be compared to alphameric
      // fields only" (J 02.04.01 b).
      report(msgIncorrectFigurativeUsage, figurative.word);
    }
  }

  void _checkComparisonClasses(ArithExpr left, ArithExpr right) {
    final OperandClass a = _classOf(left);
    final OperandClass b = _classOf(right);
    if (a == OperandClass.unknown || b == OperandClass.unknown || a == b) {
      return;
    }
    // "Comparisons may not be made between numeric and alphameric
    // fields" (J 02.04.07 rule 1); an edited field is numeric here and
    // "may not be compared to alphameric fields" (rule 3).
    report(msgIllegalComparison, left.anchor);
  }

  // ── Classification ───────────────────────────────────────────────

  DataItem? _resolved(NameReference reference) =>
      resolver.dataResolutions[reference];

  OperandClass _classOf(ArithExpr expr) => switch (expr) {
    NameOperand(:final name) => _classOfRef(name),
    LiteralOperand(:final literal) =>
      literal.kind == TokenKind.alphamericLiteral
          ? OperandClass.alphameric
          : OperandClass.numeric,
    BinaryExpr() || UnaryExpr() || TruthExpr() => OperandClass.numeric,
    FigurativeOperand() || FunctionCall() => OperandClass.unknown,
  };

  OperandClass _classOfRef(NameReference reference) {
    final DataItem? item = _resolved(reference);
    return item == null ? OperandClass.unknown : _classOfItem(item);
  }

  OperandClass _classOfItem(DataItem item) {
    final ItemSemantics? sem = mapper.semantics[item];
    if (sem == null) {
      return OperandClass.unknown;
    }
    return switch (sem.fieldClass) {
      FieldClass.group || FieldClass.alphameric => OperandClass.alphameric,
      FieldClass.externalDecimal ||
      FieldClass.internalDecimal ||
      FieldClass.edited ||
      FieldClass.floatingPoint ||
      FieldClass.scientificDecimal => OperandClass.numeric,
      FieldClass.condition || FieldClass.redefinition => OperandClass.unknown,
    };
  }

  /// Whether [item] or anything below it carries QUANTITY IN — the
  /// length is then an execution-time value (J 02.04.01 c-i;
  /// J 02.04.07 rule 5).
  bool _isVariableLength(DataItem item) => subtreeOf(
    item,
  ).any((DataItem each) => mapper.semantics[each]?.variableLength ?? false);

  String _nameOf(ArithExpr expr) => switch (expr) {
    NameOperand(:final name) => name.text,
    LiteralOperand(:final literal) => literal.text,
    _ => '',
  };

  /// The reference that names [item] in full, general to specific — a
  /// CORRESPONDING pair has no written form to quote.
  String _qualifiedName(DataItem item) {
    final words = <String>[];
    for (DataItem? each = item; each != null; each = each.parent) {
      if (each.entry.name.isNotEmpty && !each.nameDiscarded) {
        words.insert(0, each.entry.name);
      }
    }
    return words.join(' ');
  }
}
