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
import 'image.dart';
import 'storage_map.dart';
import 'text_model.dart';

/// The code generator's result over one job.
final class CodegenResult {
  CodegenResult({required this.units, required this.image});

  /// The assembly text, program order.
  final List<AssemblyUnit> units;

  /// The address layout the text is bound against.
  final ProgramImage image;
}

/// Generates the object text of [semantics].
///
/// Stage 1 reports no diagnostic of its own, so the phase takes no
/// diagnostic sink and cannot stop. D10.2's stop shape — catch
/// `StopCompilation`, return the partial text with a `stopped` flag —
/// arrives with the stage-2 verb generators, which are the first code
/// here that can detect an error (M4-2, amended; CLAUDE.md section 11).
CodegenResult runCodegen(SemanticResult semantics) {
  final List<AssemblyUnit> units = storageMapUnits(semantics);
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
  return CodegenResult(units: units, image: image);
}
