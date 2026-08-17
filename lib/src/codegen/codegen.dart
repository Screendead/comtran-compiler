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

/// The words result storage reserves: [resultStorageCells], two words a
/// cell (D4.8). Chunk B3 addresses the same list section by section, so
/// the reservation and the addressing cannot disagree.
final int resultStorageWords =
    2 * resultStorageCells.reduce((int a, int b) => a + b);

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
      ...outOfLineBlocks(image, text.poolUnits),
      // The end-of-text line ([J 90.03.04]): the word's address field
      // holds the relative program entry point — `GN)000`, the name
      // the procedure walk binds to its first text word (D2.1). The
      // manual leaves the prefix open; the attested word 500000000165
      // carries the `MON` prefix, printed solid.
      AssemblyUnit(
        operation: 'START',
        operand: 'GN)000',
        location: dataWords,
        word: counterWord(CounterOp.relativeOrigin, dataWords),
        control: ControlGroup.endOfText,
      ),
    ],
    image: image,
  );
}
