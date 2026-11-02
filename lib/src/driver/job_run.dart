/// One job's run: its object deck loaded on the machine and run to its
/// end (D0.3; `docs/design/runtime.md` RT-1). `comtranc --run` and the
/// website's run both come here, so the two cannot differ on which job
/// runs or on what a run prints.
library;

import '../emit/emit_deck.dart';
import '../listing/listing.dart';
import '../runtime/machine.dart';
import '../runtime/tape_store.dart';
import 'driver.dart';

/// What one job's run produced.
final class JobRun {
  const JobRun._({
    this.barredBy,
    this.display = const [],
    this.outcome,
    this.fault,
    this.reports = const [],
  });

  /// The job's maximum severity, when it is above 1 and so bars the run
  /// (D7.6; D11.2). Every other field is then empty.
  final int? barredBy;

  /// The on-line printer's lines, up to a fault if one ended the run.
  final List<String> display;

  /// How the run ended, or `null` when a [fault] ended it.
  final RunOutcome? outcome;

  final RunFault? fault;

  /// The report of each output file (M5-11), empty when the load
  /// faulted.
  final List<TapeReport> reports;
}

/// Runs [job]'s object program over [tapes], or returns `null` when the
/// job punched no deck. [options] stamp the deck as the listing does.
JobRun? runObjectProgram(
  JobCompilation job,
  ListingOptions options, {
  TapeStore? tapes,
}) {
  final JobDeck? punched = jobDeck(job, options);
  if (punched == null) {
    return null;
  }
  final int severity = job.sink.maxSeverity;
  if (severity > 1) {
    return JobRun._(barredBy: severity);
  }
  // The load allocates every file's buffer, so it faults on a program
  // with no room for them and leaves no machine to print from (M5-10).
  Machine? machine;
  try {
    machine = Machine.load(punched.cards, tapes: tapes);
    final RunResult result = machine.run(maxSteps: runStepBudget);
    return JobRun._(
      display: result.display,
      outcome: result.outcome,
      reports: tapeReports(machine),
    );
  } on RunFault catch (e) {
    return JobRun._(
      display: machine?.printed ?? const [],
      fault: e,
      reports: machine == null ? const [] : tapeReports(machine),
    );
  }
}
