/// The semantic layer's entry point (M3-2): `runSemantics` over the
/// parse, a separate phase that never re-reads cards — except literal
/// values, re-read from the card images per M1-9.
library;

import '../ast/data_ast.dart';
import '../ast/environment_ast.dart';
import '../ast/procedure_ast.dart';
import '../lexer/diagnostic.dart';
import '../parser/parser.dart';
import 'binder.dart';
import 'capacities.dart';
import 'data_map.dart';
import 'images.dart';
import 'legality.dart';
import 'mapper.dart';
import 'resolver.dart';
import 'transfers.dart';
import 'verb_binder.dart';

/// Runs the M3 semantic layer over [parse].
///
/// Diagnostics go to [sink] when one is given — the compilation's one
/// [DiagnosticSink] (D9.1), shared with the earlier phases by the
/// driver; [SemanticResult.semanticDiagnostics] holds only this
/// phase's rows either way. Unlike the earlier phases the function
/// catches [StopCompilation] itself and returns the partial result
/// with its `stopped` flag set (D10.2). [pedantic] adds diagnostics
/// and changes nothing else (D11.4). [tableLimits] false is the
/// non-historical `--no-table-limits` switch: the D9.7 capacity
/// counters stay silent (M3-12).
///
/// The phase order is M3-17's: mapper, dictionary, the CALL pass, the
/// environment binder, images, then reference resolution — the CALL
/// pass precedes the binder because CALL exists to give the
/// Environment Description one-word names (J 02.03.02).
SemanticResult runSemantics(
  ParseResult parse, {
  DiagnosticSink? sink,
  bool pedantic = false,
  bool tableLimits = true,
}) {
  final DiagnosticSink diagnostics = sink ?? DiagnosticSink();
  final int first = diagnostics.length;
  final dataGroups = <List<DataItem>>[];
  final environmentCards = <EnvironmentCard>[];
  final procedureGroups = <List<Sentence>>[];
  for (final ParsedGroup group in parse.groups) {
    switch (group) {
      case ParsedDataGroup(:final List<DataItem> items):
        dataGroups.add(items);
      case ParsedEnvironmentGroup(:final List<EnvironmentCard> cards):
        environmentCards.addAll(cards);
      case ParsedProcedureGroup(:final List<Sentence> sentences):
        procedureGroups.add(sentences);
    }
  }
  final environmentNames = <String>{
    for (final EnvironmentCard card in environmentCards)
      if (card.spec.name.isNotEmpty) card.spec.name,
  };
  final mapper = DataMapper(diagnostics, environmentNames, pedantic: pedantic);
  final resolver = NameResolver(
    diagnostics,
    mapper,
    pedantic: pedantic,
    tableLimits: tableLimits,
  );
  var records = const <RecordInfo>[];
  var areas = const <AreaInfo>[];
  var pairs = <Clause, List<(DataItem, DataItem)>>{};
  var stopped = false;
  try {
    mapper.map(dataGroups);
    if (tableLimits) {
      CapacityCounter(diagnostics, mapper).count();
    }
    resolver
      ..buildDictionary(dataGroups, environmentCards, procedureGroups)
      ..callPass(procedureGroups);
    final binder = EnvironmentBinder(diagnostics, mapper)
      ..bind(environmentCards);
    records = binder.records;
    areas = ImageBuilder(diagnostics, mapper, records).build();
    resolver.resolve(procedureGroups);
    final legality = LegalityChecker(
      diagnostics,
      mapper,
      resolver,
      pedantic: pedantic,
    )..check(procedureGroups);
    pairs = legality.correspondingPairs;
    TransferChecker(diagnostics, mapper, resolver).check(procedureGroups);
    VerbBinder(
      diagnostics,
      mapper,
      resolver,
      binder,
      tableLimits: tableLimits,
    ).check(environmentCards, procedureGroups);
  } on StopCompilation {
    // A severity-5 diagnostic stops the phase at the point of
    // detection (D9.1); everything mapped and diagnosed so far stands.
    // The capacity checks (D9.7, C5) are this path's producers.
    stopped = true;
  }
  return SemanticResult(
    parse: parse,
    semantics: mapper.semantics,
    areas: areas,
    records: records,
    dictionary: resolver.dictionary,
    dataResolutions: resolver.dataResolutions,
    correspondingPairs: pairs,
    keysConditions: resolver.keysConditions,
    capacityDeletedSentences: resolver.deletedSentences,
    semanticDiagnostics: List.unmodifiable(diagnostics.sublist(first)),
    stopped: stopped,
  );
}
