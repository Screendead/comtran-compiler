/// The job loop — the driver above the compiler (D9.14; D11.1–D11.3).
///
/// [compileDeck] splits the deck at its job boundaries and compiles
/// each job independently: one fresh [DiagnosticSink], one front-end
/// run, one parse, one semantic pass, and one listing's worth of
/// diagnostics per job (D11.2). Message 132 lands here when the deck
/// ends mid-job (D11.3); message 903 lands here for the single-job
/// tail (D11.1 rule d).
library;

import '../cards/card_image.dart';
import '../codegen/codegen.dart';
import '../data/data_map.dart';
import '../data/semantics.dart';
import '../lexer/diagnostic.dart';
import '../lexer/front_end.dart';
import '../lexer/messages.dart';
import '../lexer/source_card.dart';
import '../parser/parser.dart';
import 'job_splitter.dart';

/// One job's compilation.
final class JobCompilation {
  JobCompilation._(
    this.frontEnd,
    this.parse,
    this.semantics,
    this.codegen,
    this.unrecovered,
    this.sink,
    this.diagnostics,
  );

  /// The front-end result — the listing renders from it.
  final FrontEndResult frontEnd;

  /// The parse, or `null` when the front end stopped (D10.2).
  final ParseResult? parse;

  /// The semantic layer's result, or `null` when an earlier phase
  /// stopped (D10.2: the driver skips the phase).
  final SemanticResult? semantics;

  /// The generated object text, or `null` when an earlier phase
  /// stopped (M4-2; D10.2) or code generation refused ([unrecovered]).
  final CodegenResult? codegen;

  /// The code generator's refusal, or `null`. A refusal is this
  /// recovery's gap, not a 1962 diagnostic: it enters no sink and no
  /// listing, the job keeps every earlier stage's result, and the next
  /// job still compiles (M4-2 as amended; J 90.04.02).
  final UnrecoveredShape? unrecovered;

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

/// Compiles every job on [deck] (D11.1–D11.3). [pedantic] adds
/// non-historical written-language-strictness diagnostics (decision
/// D0.8, D11.4) without changing any parse result or generated value.
/// [tableLimits] false is the non-historical `--no-table-limits`
/// switch: the D9.7 capacity counters, plus the parser's section caps
/// (msgs 149, 915), stay silent (M3-12).
DeckCompilation compileDeck(
  List<CardImage> deck, {
  bool pedantic = false,
  bool tableLimits = true,
}) {
  final List<JobSlice> slices = splitJobs(deck);
  final jobs = <JobCompilation>[];
  for (var i = 0; i < slices.length; i++) {
    final JobSlice slice = slices[i];
    // One fresh sink per job (D10.2; D11.2): a stopped job never
    // starves the next one (J 90.04.02).
    final sink = DiagnosticSink();
    final FrontEndResult frontEnd = runFrontEnd(
      slice.cards,
      sink: sink,
      pedantic: pedantic,
    );
    // A front-end stop skips the parser: the compilation stopped at
    // the point of detection (D9.1; D10.2).
    final ParseResult? parse = frontEnd.stopped
        ? null
        : runParser(
            frontEnd,
            sink: sink,
            pedantic: pedantic,
            tableLimits: tableLimits,
          );
    // A parser stop skips the semantic layer the same way (D10.2).
    final SemanticResult? semantics = parse == null || parse.stopped
        ? null
        : runSemantics(
            parse,
            sink: sink,
            pedantic: pedantic,
            tableLimits: tableLimits,
          );
    // A semantic stop skips code generation the same way (M4-2; D10.2).
    // A refusal — a valid shape with no attested generated form — stops
    // this job's code generation only: the refusal is this recovery's
    // gap, not a 1962 diagnostic, so it enters no sink and the next job
    // still compiles (M4-2 as amended; J 90.04.02).
    CodegenResult? codegen;
    UnrecoveredShape? unrecovered;
    if (semantics != null && !semantics.stopped) {
      try {
        codegen = runCodegen(semantics);
      } on UnrecoveredShape catch (refusal) {
        unrecovered = refusal;
      }
    }
    final diagnostics = <Diagnostic>[
      ...semantics?.diagnostics ?? parse?.diagnostics ?? frontEnd.diagnostics,
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
    if (pedantic && i != slices.length - 1 && !slice.terminated) {
      // A job closed by a following compile card, not its own
      // *FINISH (D11.1 rule e). --pedantic warns (msg 929; D11.4); the
      // job is accepted exactly as in default mode.
      final closedByCompile = Diagnostic.wholeProgram(
        msgJobClosedByCompileCard,
      );
      sink.add(closedByCompile);
      diagnostics.add(closedByCompile);
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
      JobCompilation._(
        frontEnd,
        parse,
        semantics,
        codegen,
        unrecovered,
        sink,
        List.unmodifiable(diagnostics),
      ),
    );
  }
  return DeckCompilation._(List.unmodifiable(jobs));
}
