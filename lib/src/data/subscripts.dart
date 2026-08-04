/// Subscript reference checks (M3-20) and the D9.7 subscript counters.
///
/// The checks hang off the resolver's triage rather than a walk of
/// their own: `NameResolver` calls [SubscriptChecker.check] on every
/// reference it resolves, so the site set is exactly the resolved data
/// references and the clause number of the `n,cc` form comes from that
/// walk (M2-6; M3-17).
library;

import '../ast/data_ast.dart';
import '../ast/procedure_ast.dart';
import '../lexer/messages.dart';
import '../lexer/token.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'mapper.dart';

/// Reports one diagnostic — `NameResolver.report`, which stamps the
/// clause number.
typedef SubscriptReporter =
    void Function(Message message, Token at, {List<String> operands});

/// Checks the subscripts of every resolved data reference and tallies
/// the two D9.7 subscript tables.
final class SubscriptChecker {
  SubscriptChecker(
    this.mapper,
    this.resolutions,
    this.report, {
    required this.tableLimits,
  });

  final DataMapper mapper;

  /// The resolver's resolutions, read for the subscript variables the
  /// enclosing reference already resolved.
  final Map<NameReference, DataItem> resolutions;

  final SubscriptReporter report;

  /// False under `--no-table-limits` (D9.7): the counters stay silent.
  final bool tableLimits;

  /// One entry per unique array-and-notation pair — `A (J, K)`,
  /// `A (J, K+1)` and `A (2, 3)` are three positional indicators
  /// (J 02.04.07; the CRYPT Symbolic Register, J 02.08).
  final Set<(DataItem, String)> _indicators = {};

  /// One entry per distinct `a * VARIABLE ± b` subscript.
  final Set<String> _indexExpressions = {};

  /// Checks [reference], which resolved to [array].
  void check(NameReference reference, DataItem array) {
    if (reference.subscripts.isEmpty) {
      return; // A whole-array reference is legal (M3-20).
    }
    final int dimensions = _dimensionsOf(array);
    if (dimensions == 0) {
      report(
        msgArrayDescriptionCheck,
        reference.anchor,
        operands: [reference.text],
      );
    } else if (reference.subscripts.length != dimensions) {
      report(
        msgArrayDimensionCheck,
        reference.anchor,
        operands: [reference.text],
      );
    }
    for (final ArithExpr subscript in reference.subscripts) {
      _checkTerm(subscript, reference);
      _countIndexExpression(subscript);
    }
    _countIndicator(array, reference);
  }

  /// The quantity-bearing ancestors-or-self of [item] (M3-20).
  int _dimensionsOf(DataItem item) {
    var dimensions = 0;
    for (DataItem? each = item; each != null; each = each.parent) {
      final ItemSemantics? sem = mapper.semantics[each];
      if (sem != null && (sem.quantity > 1 || sem.variableLength)) {
        dimensions++;
      }
    }
    return dimensions;
  }

  void _checkTerm(ArithExpr term, NameReference array) {
    switch (term) {
      case NameOperand(:final name):
        _checkVariable(name, array);
      case LiteralOperand(:final literal):
        _checkLiteral(literal, negated: false);
      case UnaryExpr(:final operator, operand: LiteralOperand(:final literal)):
        _checkLiteral(literal, negated: operator.text == '-');
      case BinaryExpr(:final left, :final right):
        _checkTerm(left, array);
        _checkTerm(right, array);
      case UnaryExpr(:final operand):
        _checkTerm(operand, array);
      case TruthExpr() || FigurativeOperand() || FunctionCall():
        break;
    }
  }

  void _checkLiteral(Token literal, {required bool negated}) {
    if (literal.kind == TokenKind.alphamericLiteral) {
      return; // Not an index term; the legality tables own it.
    }
    final num? value = num.tryParse(literal.text);
    // Arrays are 1-origin and address whole elements, so a term below
    // one or with a fraction reaches nothing (J 02.04.07.01).
    if (value == null || negated || value < 1 || value != value.truncate()) {
      report(msgImproperDataFormat, literal);
    }
  }

  /// The four format rows of M3-20, in cascade: the first that applies
  /// speaks for the variable.
  void _checkVariable(NameReference variable, NameReference array) {
    final DataItem? item = resolutions[variable];
    if (variable.subscripts.isNotEmpty || item?.typeCode == DataTypeCode.cond) {
      // A subscript is a name or an index expression (F p. 31);
      // neither form admits a subscripted name or a condition.
      report(
        msgInvalidSubscriptVariable,
        variable.anchor,
        operands: [array.text],
      );
      return;
    }
    final ItemSemantics? sem = item == null ? null : mapper.semantics[item];
    if (sem == null) {
      return; // The triage diagnosed the reference already.
    }
    if (sem.fieldClass == FieldClass.alphameric ||
        sem.fieldClass == FieldClass.edited ||
        sem.fieldClass == FieldClass.group) {
      report(
        msgSubscriptVariableNotNumeric,
        variable.anchor,
        operands: [variable.text],
      );
      return;
    }
    if (sem.fractionDigits != 0) {
      report(
        msgSubscriptVariableNotInteger,
        variable.anchor,
        operands: [variable.text],
      );
      return;
    }
    if (sem.fieldClass != FieldClass.internalDecimal ||
        sem.justification != Justification.right) {
      // D9.11's invented criterion: the generator indexes with a
      // right-justified internal decimal field directly, and converts
      // every other legal format first.
      report(
        msgInefficientSubscriptFormat,
        variable.anchor,
        operands: [variable.text],
      );
    }
  }

  void _countIndicator(DataItem array, NameReference reference) {
    if (!tableLimits) {
      return;
    }
    _indicators.add((array, reference.subscripts.map(_notation).join(',')));
    if (_indicators.length == 91) {
      // The "Appox-Max" 90 positional indicators (J 90.01.05; D9.7
      // rejects the unknown band above the printed number).
      report(msgSubscriptedNameCapacity, reference.anchor);
    }
  }

  void _countIndexExpression(ArithExpr subscript) {
    if (!tableLimits ||
        subscript is! BinaryExpr ||
        !_namesAnything(subscript)) {
      return;
    }
    _indexExpressions.add(_notation(subscript));
    if (_indexExpressions.length == 51) {
      // The "Appox-Max" 50 index expressions (J 90.01.05; D9.7).
      report(msgIndexExpressionCapacity, subscript.anchor);
    }
  }

  bool _namesAnything(ArithExpr expr) => switch (expr) {
    NameOperand() => true,
    BinaryExpr(:final left, :final right) =>
      _namesAnything(left) || _namesAnything(right),
    UnaryExpr(:final operand) => _namesAnything(operand),
    LiteralOperand() ||
    FigurativeOperand() ||
    TruthExpr() ||
    FunctionCall() => false,
  };

  /// The written form of a subscript, blank-free, for the uniqueness
  /// counts of both tables.
  String _notation(ArithExpr expr) => switch (expr) {
    NameOperand(:final name) =>
      name.subscripts.isEmpty
          ? name.text
          : '${name.text}(${name.subscripts.map(_notation).join(',')})',
    LiteralOperand(:final literal) => literal.text,
    FigurativeOperand(:final word) => word.text,
    BinaryExpr(:final left, :final operator, :final right) =>
      '${_notation(left)}${operator.text}${_notation(right)}',
    UnaryExpr(:final operator, :final operand) =>
      '${operator.text}${_notation(operand)}',
    TruthExpr(:final word) => word.text,
    FunctionCall(:final function, :final arguments) =>
      '${function.text}((${_joined(arguments)}))',
  };

  String _joined(List<NameReference> references) =>
      references.map((NameReference each) => each.text).join(',');
}
