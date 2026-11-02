/// Shared text conventions for the `--emit` stage dumps
/// (`docs/design/emit-stages.md`): the reconstruction label, the
/// per-job header, and the stopped-stage line.
library;

/// The first line of every reconstruction dump. The attested dumps
/// (cards, listing) never print it: their bytes must match the
/// attested form.
const String reconstructionLabel =
    '* RECONSTRUCTION - NO 1962 ARTIFACT ATTESTS THIS FORM';

/// The line that opens job [number]'s section of a dump.
String jobHeader(int number) => '* JOB $number';

/// The line a dump prints for a stage that an earlier stop kept from
/// running (D10.2).
const String stageNotReached = '* STOPPED BEFORE THIS STAGE';

/// The last line of a job's section when the stage itself stopped
/// mid-run (D10.2): the section above it is truncated, not complete.
const String stageStopped = '* STOPPED IN THIS STAGE';

/// The one marker line for a job that reached code generation and got
/// no text: [stageNotReached] when an earlier stop kept the generator
/// from running, the refused [shape] when the generator declined one.
String codeStageMarker(String? shape) =>
    shape == null ? stageNotReached : '* NOT RECOVERED: $shape';

/// A stage dump that also records, for each line, the statement the line
/// prints (roadmap W3, `docs/design/emit-stages.md`).
///
/// A mark reads `j:n,cc`: the job, then the statement number the 1962
/// compiler printed and keyed its diagnostics to (J 02.02.01). Every
/// line written while [mark] holds a value takes that value; a line
/// written while it is `null` belongs to no statement. The text is the
/// dump unchanged, so the marks never alter a golden.
final class MarkedText {
  final StringBuffer _text = StringBuffer();
  final List<String?> _marks = <String?>[];

  /// The mark the next line takes.
  String? mark;

  /// One entry per line of [text], in order.
  List<String?> get marks => List.unmodifiable(_marks);

  String get text => _text.toString();

  /// Writes [object] and ends the line. Text that holds a line break
  /// writes several lines, and each one takes [mark].
  void writeln([Object? object = '']) {
    for (final String line in '$object'.split('\n')) {
      _text
        ..write(line)
        ..write('\n');
      _marks.add(mark);
    }
  }
}

/// The mark of statement [number] in job [job], or `null` for the
/// `9999,99` number that confines a row to no statement (J 02.02.01).
String? statementMark(int job, String? number) =>
    number == null || number == '9999,99' ? null : '$job:$number';
