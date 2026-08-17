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
