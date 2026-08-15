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
/// Chunk B1 sizes every unit of the program and binds it to an address.
/// It fills no other column: the verb generators B2 to B6 do that.
library;

import '../data/data_map.dart';
import 'blocks.dart';
import 'image.dart';
import 'procedure.dart';
import 'storage_map.dart';
import 'text_model.dart';

export 'procedure.dart' show UnrecoveredShape;

/// The words temporary storage reserves.
///
/// A constant, and deliberately not a rule. The manuals hold no sizing
/// rule for `TS)`, the sample reserves 7 words and addresses none of
/// them, and an eleven-agent hunt over both manuals left two readings
/// one sample cannot separate. M4-4 as amended 2026-08-10 takes the
/// attested 7 and forbids inventing a rule that returns it. For any
/// program but the sample this size is unverifiable, which is stated
/// rather than hidden.
const int temporaryStorageWords = 7;

/// The words result storage reserves.
///
/// A constant, and deliberately not a rule — the `TS)` precedent again
/// (Jack's ruling, 2026-08-15, the chunk B1 review record). The sample
/// attests sections 0 to 2 reserving 3, 2 and 3 cells while referencing
/// 2, 1 and 1, no tested rule reproduces those heads, and the 7-cell
/// tail the remaining sections share is unobservable — the program
/// addresses none of it, and contradictory closures fit. The ruling
/// pins the attested reservation as constants of the sample: 3, 2 and
/// 3 cells, then the tail as one undivided block, two words a cell
/// (D4.8), 30 words. For any program but the sample this size is
/// unverifiable, which is stated rather than hidden.
const int resultStorageWords = 2 * (3 + 2 + 3 + 7);

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
/// The phase takes no diagnostic sink, because the one failure it can
/// detect is not a diagnostic: a valid source shape the sample never
/// reaches has no attested generated form, and none is invented. The
/// sizers throw [UnrecoveredShape] at such a shape and the driver
/// scopes the refusal to the job (M4-2 as amended 2026-08-15). The
/// diagnostic sink arrives with chunk B8 (M4-1).
CodegenResult runCodegen(SemanticResult semantics) {
  final List<AssemblyUnit> data = storageMapUnits(semantics);
  final int dataWords = semantics.areas.fold(
    0,
    (int total, AreaInfo area) => total + area.extentWords,
  );

  // Two passes over the procedure text. The text's own addresses need
  // nothing but its order, but an `EQU` line prints an equated value in
  // the LOC column, and the values it equates are pool addresses, which
  // follow the whole text. Pass one measures; pass two places.
  ProcedureText text = generateProcedure(semantics, origin: dataWords);
  final image = ProgramImage(
    inlineWords: dataWords + text.words,
    blockWords: <StorageBlock, int>{
      StorageBlock.rs: resultStorageWords,
      StorageBlock.ts: temporaryStorageWords,
      StorageBlock.bl: baseLocatorWords(semantics),
      StorageBlock.pi: semantics.positionalIndicators.length,
      StorageBlock.cp: text.poolWords,
    },
  );
  text = generateProcedure(semantics, origin: dataWords, image: image);

  return CodegenResult(
    units: <AssemblyUnit>[
      ...counterHead(image),
      ...data,
      ...text.units,
      ...pointerInitialization(image),
      ...outOfLineBlocks(image),
      // The end-of-text line: the entry point the object deck's 01111
      // control group carries (D2.1). Its word and its operand are the
      // object deck's, which is stage 3's (M4-16); the `START` pseudo-op
      // itself is structural, and the line prints no offset.
      AssemblyUnit(operation: 'START', operand: '', location: dataWords),
    ],
    image: image,
  );
}
