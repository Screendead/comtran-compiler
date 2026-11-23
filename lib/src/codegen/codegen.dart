/// The code generator (M4-2): a separate phase over `SemanticResult`.
///
/// The phase re-resolves nothing. Data references come from
/// `dataResolutions`, storage facts from `ItemSemantics`, initial words
/// from `AreaInfo.words`, and label words from the M3 allocator. It
/// generates no code from a node flagged `recovered` (M2-5; D4.10),
/// from a deleted sentence, or from a sentence in
/// `capacityDeletedSentences` (M3-20): those units keep their statement
/// numbers and emit nothing.
library;

import '../data/data_map.dart';
import '../lexer/diagnostic.dart';
import '../loader/control_group.dart';
import '../parser/parser.dart';
import 'blocks.dart';
import 'control_cards.dart';
import 'image.dart';
import 'procedure.dart';
import 'storage_map.dart';
import 'text_model.dart';

export 'procedure.dart' show UnrecoveredShape;

/// The code generator's result over one job.
final class CodegenResult {
  CodegenResult({
    required this.units,
    required ProgramImage this.image,
    required this.controlCards,
    required this.undefinedSymbol,
  }) : stopped = false;

  /// The result of a phase a severity-5 diagnostic stopped (D10.2): no
  /// text and no layout. The 1962 compiler produced no object program
  /// past a severity 5 ([J 90.04.02]), and the words placed before the
  /// stop are not one either.
  const CodegenResult.stopped()
    : units = const <AssemblyUnit>[],
      image = null,
      controlCards = const <String>[],
      undefinedSymbol = false,
      stopped = true;

  /// The assembly text, program order.
  final List<AssemblyUnit> units;

  /// The `*FILE` and `*SPEC` cards, columns 1 to 72, deck order
  /// (M4-16; [J 90.08]).
  final List<String> controlCards;

  /// The address layout the text is bound against, or `null` when the
  /// phase stopped.
  final ProgramImage? image;

  /// Whether a severity-5 diagnostic stopped the phase (D10.2).
  final bool stopped;

  /// Whether the text holds an undefined symbol (M6-11 a). It bars the
  /// run on its own, whatever the severity ([J 02.01.02]; D9.1; D9.13).
  final bool undefinedSymbol;
}

/// Generates the object text of [semantics].
///
/// Diagnostics go to [sink] when one is given — the compilation's one
/// [DiagnosticSink] (D9.1), shared with the earlier phases by the
/// driver. The function catches [StopCompilation] itself and returns
/// [CodegenResult.stopped] (D10.2; M4-2). [pedantic] adds the D5.1
/// and D5.7 notes and changes nothing else (D11.4); [tableLimits]
/// false is the non-historical `--no-table-limits` switch, which
/// silences the name tally and the pool counter (D9.7).
///
/// A refusal is not a diagnostic: a valid source shape the sample
/// never reaches has no attested generated form, and none is invented.
/// The sizers throw [UnrecoveredShape] at such a shape and the driver
/// scopes the refusal to the job (M4-2 as amended 2026-08-15).
CodegenResult runCodegen(
  SemanticResult semantics, {
  DiagnosticSink? sink,
  bool pedantic = false,
  bool tableLimits = true,
}) {
  final int dataWords = semantics.areas.fold(
    0,
    (int total, AreaInfo area) => total + area.extentWords,
  );
  // Location Counter 0 holds the procedure text and the transmitted
  // areas in the relative position of their divisions in the deck
  // ([J 90.02.01]; M4-4 as amended by M7-12). The 90.05 sample puts
  // `*DATA` first; the 1960 program puts `*PROCEDURE` first, and its
  // code starts at word zero.
  final bool codeFirst = _procedureFirst(semantics);
  final textOrigin = codeFirst ? 0 : dataWords;

  // Two passes over the procedure text. The text's own addresses need
  // nothing but its order, but an `EQU` line prints an equated value in
  // the LOC column, and the values it equates are pool addresses, which
  // follow the whole text. Pass one measures and diagnoses; pass two
  // places.
  final checks = CodegenChecks(
    sink ?? DiagnosticSink(),
    pedantic: pedantic,
    tableLimits: tableLimits,
    nameCount: semantics.nameCount,
  );
  ProcedureText text;
  try {
    // The word count does not depend on where the areas sit, so the
    // measuring pass takes any data origin.
    text = generateProcedure(
      semantics,
      origin: textOrigin,
      dataOrigin: 0,
      checks: checks,
    );
  } on StopCompilation {
    // A severity-5 diagnostic stops the phase at the point of
    // detection (D9.1); the capacity checks (D9.7, C5) are this
    // path's producers.
    return const CodegenResult.stopped();
  }
  // The loader cards refuse an option with no attested column character
  // the way the walk refuses a shape (M4-2 as amended), after the
  // measuring pass so its rows are already in the sink.
  final List<String> cards = controlCards(semantics.parse);
  final image = ProgramImage(
    inlineWords: dataWords + text.words,
    blockWords: <StorageBlock, int>{
      // Two words a cell (D4.8). The second pass addresses the cells the
      // first pass counted, so the reservation and the addressing cannot
      // disagree.
      StorageBlock.rs: 2 * text.resultCells.fold(0, (int a, int b) => a + b),
      StorageBlock.ts: temporaryStorageWords,
      StorageBlock.bl: baseLocatorWords(semantics),
      StorageBlock.pi: semantics.positionalIndicators.length,
      StorageBlock.cp: text.poolWords,
    },
    resultCells: text.resultCells,
  );
  final int dataOrigin = codeFirst ? text.words : 0;
  text = generateProcedure(
    semantics,
    origin: textOrigin,
    dataOrigin: dataOrigin,
    image: image,
  );
  final List<AssemblyUnit> data = storageMapUnits(semantics, dataOrigin);

  return CodegenResult(
    units: <AssemblyUnit>[
      ...counterHead(image),
      counterZeroHead,
      if (codeFirst) ...<AssemblyUnit>[...text.units, ...data],
      if (!codeFirst) ...<AssemblyUnit>[...data, ...text.units],
      ...pointerInitialization(image, text.constantIndicators),
      ...outOfLineBlocks(image, text.poolUnits),
      // The end-of-text line ([J 90.03.04]): the word's address field
      // holds the relative program entry point, and the LOC column
      // echoes it (D2.1 as amended 2026-09-06). The manual leaves the
      // prefix open; the attested word 500000000165 carries the `MON`
      // prefix, printed solid.
      AssemblyUnit(
        operation: 'START',
        operand: text.entry.name,
        location: text.entry.location,
        word: counterWord(CounterOp.relativeOrigin, text.entry.location),
        control: ControlGroup.endOfText,
      ),
    ],
    image: image,
    controlCards: cards,
    undefinedSymbol: text.undefinedSymbol,
  );
}

/// Whether the job's first `*PROCEDURE` group comes before its first
/// `*DATA` group. A job with no `*DATA` group has no areas, so either
/// answer places the same words.
bool _procedureFirst(SemanticResult semantics) {
  for (final ParsedGroup group in semantics.parse.groups) {
    if (group is ParsedProcedureGroup) {
      return true;
    }
    if (group is ParsedDataGroup) {
      return false;
    }
  }
  return false;
}
