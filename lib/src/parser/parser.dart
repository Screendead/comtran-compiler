/// The M2 parser: `runParser` over the M1 front end's result.
///
/// Design: `docs/design/m2-parser.md`. At this stage the fixed-form
/// divisions and the control cards parse; procedure groups carry their
/// scan through unparsed until the procedure parser lands (staging
/// entry, design note).
library;

import '../ast/control_ast.dart';
import '../ast/data_ast.dart';
import '../ast/environment_ast.dart';
import '../ast/procedure_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/front_end.dart';
import 'control_parser.dart';
import 'data_parser.dart';
import 'environment_parser.dart';
import 'procedure_parser.dart';

/// One division group after parsing.
sealed class ParsedGroup {
  ParsedGroup._(this.scan);

  /// The M1 scan the parse consumed.
  final GroupScan scan;
}

/// A parsed `*DATA` group.
final class ParsedDataGroup extends ParsedGroup {
  ParsedDataGroup._(super.scan, this.items) : super._();

  /// The items, flat, in source order, hierarchy wired.
  final List<DataItem> items;

  /// The hierarchy roots.
  Iterable<DataItem> get roots =>
      items.where((DataItem item) => item.parent == null);
}

/// A parsed `*ENVIRONMENT` group.
final class ParsedEnvironmentGroup extends ParsedGroup {
  ParsedEnvironmentGroup._(super.scan, this.cards) : super._();

  /// The parsed cards, source order. A specification the M1 scan
  /// deleted (bad type code) appears here as no card.
  final List<EnvironmentCard> cards;
}

/// A parsed `*PROCEDURE` group.
final class ParsedProcedureGroup extends ParsedGroup {
  ParsedProcedureGroup._(super.scan, this.sentences) : super._();

  /// The sentences, source order; a sentence recovery deleted is
  /// present with [Sentence.deleted] set.
  final List<Sentence> sentences;
}

/// The parser's result over one job.
final class ParseResult {
  ParseResult._({
    required this.frontEnd,
    required this.compileCard,
    required this.groups,
    required this.parserDiagnostics,
    required this.stopped,
  });

  /// The M1 result the parse consumed.
  final FrontEndResult frontEnd;

  /// The parsed compile control card, when the deck has one.
  final CompileCard? compileCard;

  /// One parsed group per division group, deck order.
  final List<ParsedGroup> groups;

  /// The parser's own diagnostics, in detection order.
  final List<Diagnostic> parserDiagnostics;

  /// Whether a severity-5 diagnostic stopped the parse at the point of
  /// detection (D9.1): later sentences and groups are unparsed.
  final bool stopped;

  /// Front-end and parser diagnostics as one block, ordered by card
  /// number, stable within one card (design note M2-2; the 1962
  /// ordering is unattested).
  late final List<Diagnostic> diagnostics = _merged();

  List<Diagnostic> _merged() {
    // A whole-program diagnostic (no card; D11.3) sorts after every
    // carded one.
    int key(Diagnostic d) => d.card?.cardNumber ?? 1 << 30;
    final all =
        <(int, int, Diagnostic)>[
          for (final (int i, Diagnostic d) in frontEnd.diagnostics.indexed)
            (key(d), i, d),
          for (final (int i, Diagnostic d) in parserDiagnostics.indexed)
            (key(d), frontEnd.diagnostics.length + i, d),
        ]..sort(
          ((int, int, Diagnostic) a, (int, int, Diagnostic) b) =>
              a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2,
        );
    return List.unmodifiable([for (final (_, _, Diagnostic d) in all) d]);
  }

  /// The highest severity across both phases, or 0 with no diagnostics.
  int get maxSeverity => diagnostics.isEmpty
      ? 0
      : diagnostics
            .map((Diagnostic d) => d.severity)
            .reduce((int a, int b) => a > b ? a : b);
}

/// Runs the M2 parser over [frontEnd].
///
/// Diagnostics go to [sink] when one is given — the compilation's one
/// [DiagnosticSink] (D9.1), shared with the front end by the driver;
/// [ParseResult.parserDiagnostics] holds only the parser's rows either
/// way. [pedantic] adds non-historical written-language-strictness
/// diagnostics (decision D0.8, D11.4) without changing any parse
/// result.
ParseResult runParser(
  FrontEndResult frontEnd, {
  DiagnosticSink? sink,
  bool pedantic = false,
}) {
  final DiagnosticSink diagnostics = sink ?? DiagnosticSink();
  final int first = diagnostics.length;
  CompileCard? compileCard;
  final procedureParser = ProcedureParser(diagnostics, pedantic: pedantic);
  // The 63-file limit spans every environment group of the job
  // (J 90.01.04; D10.8).
  final fileTally = FileCardTally();
  final groups = <ParsedGroup>[];
  var stopped = false;
  try {
    compileCard = parseCompileCard(
      frontEnd.program.compileCard,
      diagnostics,
      pedantic: pedantic,
    );
    for (final GroupScan scan in frontEnd.groupScans) {
      groups.add(switch (scan) {
        DataGroupScan(scan: final data) => ParsedDataGroup._(
          scan,
          parseDataGroup(data, diagnostics, pedantic: pedantic),
        ),
        EnvironmentGroupScan(scan: final environment) =>
          ParsedEnvironmentGroup._(
            scan,
            parseEnvironmentGroup(
              environment,
              diagnostics,
              fileTally: fileTally,
              pedantic: pedantic,
            ),
          ),
        ProcedureGroupScan(scan: final procedure) => ParsedProcedureGroup._(
          scan,
          procedureParser.parseGroup(procedure),
        ),
      });
    }
    if (frontEnd.program.groups.isNotEmpty) {
      // The end-of-text checks anchor to the program's last source card.
      procedureParser.finishProgram(frontEnd.program.cards.last);
    }
  } on StopCompilation {
    // A severity-5 condition stops compilation at the point of
    // detection (D9.1; design note M2-13). The groups parsed so far
    // and every diagnostic issued — the severity-5 one last — stand;
    // the end-of-text checks do not run.
    stopped = true;
  }
  return ParseResult._(
    frontEnd: frontEnd,
    compileCard: compileCard,
    groups: List.unmodifiable(groups),
    parserDiagnostics: List.unmodifiable(diagnostics.sublist(first)),
    stopped: stopped,
  );
}
