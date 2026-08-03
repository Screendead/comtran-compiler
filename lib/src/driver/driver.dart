/// The job loop — the driver above the compiler (D9.14; D11.1–D11.3).
///
/// [compileDeck] splits the deck at its job boundaries and compiles
/// each job independently: one fresh [DiagnosticSink], one front-end
/// run, one parse, and one listing's worth of diagnostics per job
/// (D11.2). Message 132 lands here when the deck ends mid-job (D11.3);
/// message 903 lands here for the single-job tail (D11.1 rule d).
library;

import '../cards/card_image.dart';
import '../lexer/diagnostic.dart';
import '../lexer/front_end.dart';
import '../lexer/messages.dart';
import '../lexer/source_card.dart';
import '../parser/parser.dart';
import 'job_splitter.dart';

/// One job's compilation.
final class JobCompilation {
  JobCompilation._(this.frontEnd, this.parse, this.sink, this.diagnostics);

  /// The front-end result — the listing renders from it.
  final FrontEndResult frontEnd;

  /// The parse, or `null` when the front end stopped (D10.2).
  final ParseResult? parse;

  /// The job's diagnostic sink (D11.2): its `maxSeverity` decides the
  /// job's severity.
  final DiagnosticSink sink;

  /// The diagnostics the job's listing prints: the merged front-end and
  /// parser block (M2-2), then any tail 903s, then 132 when the deck
  /// ended inside this job.
  final List<Diagnostic> diagnostics;
}

/// A whole deck's compilation, one entry per job, in deck order.
final class DeckCompilation {
  DeckCompilation._(this.jobs);

  /// The jobs, in deck order.
  final List<JobCompilation> jobs;

  /// The worst severity across every job, or 0 with none (D11.2: the
  /// exit code reflects it).
  int get maxSeverity {
    var worst = 0;
    for (final JobCompilation job in jobs) {
      if (job.sink.maxSeverity > worst) {
        worst = job.sink.maxSeverity;
      }
    }
    return worst;
  }
}

/// Compiles every job on [deck] (D11.1–D11.3).
DeckCompilation compileDeck(List<CardImage> deck) {
  final List<JobSlice> slices = splitJobs(deck);
  final jobs = <JobCompilation>[];
  for (var i = 0; i < slices.length; i++) {
    final JobSlice slice = slices[i];
    // One fresh sink per job (D10.2; D11.2): a stopped job never
    // starves the next one (J 90.04.02).
    final sink = DiagnosticSink();
    final FrontEndResult frontEnd = runFrontEnd(slice.cards, sink: sink);
    // A front-end stop skips the parser: the compilation stopped at
    // the point of detection (D9.1; D10.2).
    final ParseResult? parse = frontEnd.stopped
        ? null
        : runParser(frontEnd, sink: sink);
    final diagnostics = <Diagnostic>[
      ...parse?.diagnostics ?? frontEnd.diagnostics,
    ];
    for (var j = 0; j < slice.ignoredTail.length; j++) {
      // The single-job tail (D11.1 rule d). Card numbers continue past
      // the job's own, so the block keeps card order (M2-2); the cards
      // are unnumbered, so the rows print at 9999,99.
      final tail = Diagnostic(
        msgCardAfterFinish,
        SourceCard(slice.ignoredTail[j], slice.cards.length + j + 1),
      );
      sink.add(tail);
      diagnostics.add(tail);
    }
    if (i == slices.length - 1 && !slice.terminated) {
      // End of input inside an open job: message 132 at severity 5,
      // at statement 9999,99 (D11.3; D9.14; J 02.02.01). The job is
      // already compiled as read — nothing remains to stop.
      final endOfFile = Diagnostic.wholeProgram(msgEndOfFileWithoutFinish);
      diagnostics.add(endOfFile);
      try {
        sink.add(endOfFile);
      } on StopCompilation {
        // The attested severity-5 stop; detection is at end of input.
      }
    }
    jobs.add(
      JobCompilation._(frontEnd, parse, sink, List.unmodifiable(diagnostics)),
    );
  }
  return DeckCompilation._(List.unmodifiable(jobs));
}
