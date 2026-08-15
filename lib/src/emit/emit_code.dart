/// The `--emit-code` dump (M4-19, `docs/design/emit-stages.md`): the
/// assembly text model of every job, as a labeled reconstruction.
///
/// One `* TEXT` section per job, one row per [AssemblyUnit], in program
/// order. Each row holds exactly six tab-separated fields — LOC, the
/// labels, the operation, the operand, the word, and the control group
/// — with an empty field where the unit's value is null, so every row
/// keeps its five tabs and the columns line up. LOC is five octal
/// digits, the word twelve solid octal digits (`WordForm.solid`, not
/// the listing's spaced OCTAL forms), and the control group prints
/// through [controlColumn]. A job whose code generator never ran
/// prints [stageNotReached].
library;

import '../codegen/codegen.dart';
import '../codegen/text_model.dart';
import '../driver/driver.dart';
import 'common.dart';

/// Renders the assembly text of every job on [deck], in deck order.
String emitCode(DeckCompilation deck) {
  final out = StringBuffer()..writeln(reconstructionLabel);
  for (final (int index, JobCompilation job) in deck.jobs.indexed) {
    if (index > 0) {
      out.writeln();
    }
    out.writeln(jobHeader(index + 1));
    final CodegenResult? codegen = job.codegen;
    if (codegen == null) {
      // A refused job reached this stage and declined the shape, so its
      // marker names the shape rather than claiming an earlier stop.
      final UnrecoveredShape? refusal = job.unrecovered;
      out.writeln(
        refusal == null ? stageNotReached : '* NOT RECOVERED: ${refusal.shape}',
      );
      continue;
    }
    out.writeln('* TEXT');
    for (final AssemblyUnit unit in codegen.units) {
      out.writeln(_row(unit));
    }
  }
  return out.toString();
}

String _octal(int? value, int digits) =>
    value == null ? '' : value.toRadixString(8).padLeft(digits, '0');

String _row(AssemblyUnit unit) => <String>[
  _octal(unit.location, 5),
  unit.labels.join(' '),
  unit.operation,
  unit.operand,
  _octal(unit.word, 12),
  if (unit.control case final int control) controlColumn(control) else '',
].join('\t');
