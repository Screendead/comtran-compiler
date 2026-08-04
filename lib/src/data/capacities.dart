/// The mapper's capacity counters (M3-12; M3-21's capacity homes).
///
/// One source-order walk over the mapped items, after the mapper and
/// before the dictionary. Each counter sits at the printed "Appox-Max"
/// number of J 90.01.05 and fires on the entry that crosses it (D9.7:
/// the threshold is checked on the increment, so the diagnostic names
/// the crossing entry). Every row is C5, so the first one stops the
/// phase. `--no-table-limits` silences all four.
library;

import '../ast/data_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/messages.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'mapper.dart';

/// Counts the four data-division tables of one job.
final class CapacityCounter {
  CapacityCounter(this.diagnostics, this.mapper);

  final List<Diagnostic> diagnostics;
  final DataMapper mapper;

  void count() {
    var variableFields = 0;
    var dimensions = 0;
    final editedFormats = <String>{};
    for (final DataItem item in mapper.items) {
      final ItemSemantics sem = mapper.semantics[item]!;
      if (sem.variableLength && ++variableFields == 26) {
        _report(msgVariableFieldCapacity, item);
      }
      if ((sem.quantity > 1 || sem.variableLength) && ++dimensions == 86) {
        _report(msgArrayDimensionCapacity, item);
      }
      final String? format = (item.pictorial ?? item.targetName)?.text;
      if (sem.fieldClass == FieldClass.edited &&
          format != null &&
          editedFormats.add(format) &&
          editedFormats.length == 36) {
        _report(msgEditedFormatCapacity, item);
      }
      if (_depthOf(item) == 24) {
        _report(msgHierarchyDepthCapacity, item, named: true);
      }
    }
  }

  /// The entry's own level counted in: the hierarchy is the chain of
  /// entries above it (J 90.01.05 item j).
  int _depthOf(DataItem item) {
    var depth = 1;
    for (DataItem? each = item.parent; each != null; each = each.parent) {
      depth++;
    }
    return depth;
  }

  void _report(Message message, DataItem item, {bool named = false}) {
    diagnostics.reportAt(
      message,
      item.entry.cards.first,
      operands: named ? [item.entry.name] : const [],
    );
  }
}
