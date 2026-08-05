/// The code generator (M4-2): a separate phase over `SemanticResult`.
///
/// The phase re-resolves nothing. Data references come from
/// `dataResolutions`, storage facts from `ItemSemantics`, initial words
/// from `AreaInfo.words`, and label words from the M3 allocator. It
/// generates no code from a node flagged `recovered` (M2-5; D4.10),
/// from a deleted sentence, or from a sentence in
/// `capacityDeletedSentences` (M3-20): those units keep their statement
/// numbers and emit nothing.
///
/// Stage 1 builds the transmitted-data region only. The verb
/// generators, and with them the procedure text that fixes Location
/// Counter 1's origin, land in stage 2.
library;

import '../data/data_map.dart';
import '../lexer/diagnostic.dart';
import 'image.dart';
import 'storage_map.dart';
import 'text_model.dart';

/// The code generator's result over one job.
final class CodegenResult {
  CodegenResult({
    required this.semantics,
    required this.units,
    required this.image,
    required this.codegenDiagnostics,
    required this.stopped,
  });

  /// The semantics the text was generated over.
  final SemanticResult semantics;

  /// The assembly text, program order.
  final List<AssemblyUnit> units;

  /// The address layout the text is bound against.
  final ProgramImage image;

  /// The generator's own diagnostics, in detection order.
  final List<Diagnostic> codegenDiagnostics;

  /// Whether a severity-5 diagnostic stopped the phase (D10.2).
  final bool stopped;
}

/// Generates the object text of [semantics].
///
/// Like the semantic layer, the function catches `StopCompilation`
/// itself and returns the partial result with its [CodegenResult.stopped]
/// flag set (D10.2).
CodegenResult runCodegen(SemanticResult semantics, {DiagnosticSink? sink}) {
  final DiagnosticSink diagnostics = sink ?? DiagnosticSink();
  final int first = diagnostics.length;
  var units = const <AssemblyUnit>[];
  var stopped = false;
  try {
    units = storageMapUnits(semantics);
  } on StopCompilation {
    stopped = true;
  }
  // Result storage, temporary storage, the positional indicators, and
  // the constant pool are all sized by the verb generators, so they
  // stay empty until stage 2.
  final image = ProgramImage(
    inlineWords: semantics.areas.fold(
      0,
      (int total, AreaInfo area) => total + area.extentWords,
    ),
    blockWords: <StorageBlock, int>{
      StorageBlock.bl: baseLocatorWords(semantics),
    },
  );
  return CodegenResult(
    semantics: semantics,
    units: units,
    image: image,
    codegenDiagnostics: List.unmodifiable(diagnostics.sublist(first)),
    stopped: stopped,
  );
}
