/// The semantic layer's entry point (M3-2): `runSemantics` over the
/// parse, a separate phase that never re-reads cards — except literal
/// values, re-read from the card images per M1-9.
library;

import '../ast/data_ast.dart';
import '../ast/environment_ast.dart';
import '../lexer/diagnostic.dart';
import '../parser/parser.dart';
import 'binder.dart';
import 'data_map.dart';
import 'images.dart';
import 'mapper.dart';

/// Runs the M3 semantic layer over [parse].
///
/// Diagnostics go to [sink] when one is given — the compilation's one
/// [DiagnosticSink] (D9.1), shared with the earlier phases by the
/// driver; [SemanticResult.semanticDiagnostics] holds only this
/// phase's rows either way. Unlike the earlier phases the function
/// catches [StopCompilation] itself and returns the partial result
/// with its `stopped` flag set (D10.2). [pedantic] adds diagnostics
/// and changes nothing else (D11.4).
SemanticResult runSemantics(
  ParseResult parse, {
  DiagnosticSink? sink,
  bool pedantic = false,
}) {
  final DiagnosticSink diagnostics = sink ?? DiagnosticSink();
  final int first = diagnostics.length;
  final dataGroups = <List<DataItem>>[];
  final environmentCards = <EnvironmentCard>[];
  for (final ParsedGroup group in parse.groups) {
    switch (group) {
      case ParsedDataGroup(:final List<DataItem> items):
        dataGroups.add(items);
      case ParsedEnvironmentGroup(:final List<EnvironmentCard> cards):
        environmentCards.addAll(cards);
      case ParsedProcedureGroup():
        break;
    }
  }
  final environmentNames = <String>{
    for (final EnvironmentCard card in environmentCards)
      if (card.spec.name.isNotEmpty) card.spec.name,
  };
  final mapper = DataMapper(diagnostics, environmentNames, pedantic: pedantic);
  var records = const <RecordInfo>[];
  var areas = const <AreaInfo>[];
  var stopped = false;
  try {
    mapper.map(dataGroups);
    final binder = EnvironmentBinder(diagnostics, mapper)
      ..bind(environmentCards);
    records = binder.records;
    areas = ImageBuilder(diagnostics, mapper, records).build();
  } on StopCompilation {
    // A severity-5 diagnostic stops the phase at the point of
    // detection (D9.1); everything mapped and diagnosed so far stands.
    // No stage-1 message reaches C5 — stage 2's capacity checks
    // (D9.7, C5) are what this path waits for.
    stopped = true;
  }
  return SemanticResult(
    parse: parse,
    semantics: mapper.semantics,
    areas: areas,
    records: records,
    semanticDiagnostics: List.unmodifiable(diagnostics.sublist(first)),
    stopped: stopped,
  );
}
