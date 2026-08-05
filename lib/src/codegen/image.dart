/// The object program's location counters and storage blocks (M4-4).
///
/// The compiler uses three pseudo location counters ([J 90.02.01]), and
/// the LOC column prints displacements from the first word of the object
/// program — never the compile-time dictionary addresses of M3-8, which
/// are a different address space entirely.
library;

import '../data/data_map.dart';

/// The out-of-line blocks of Location Counter 1, in the reservation
/// order [J 90.02.03]–06 attests (M4-4).
enum StorageBlock {
  /// Result storage: the sum over sections of the maximum each section
  /// uses ([J 90.02.03]), two words per cell (D4.8, inferred from the
  /// listing's LOC values, not stated by J).
  rs,

  /// Temporary storage. Its sizing rule is unrecovered: the 90.05
  /// sample reserves 7 words and references none of them. M4-4 leaves
  /// the rule open for the stage-2 listing diff to reveal.
  ts,

  /// Base locators: one word each (M4-4).
  bl,

  /// Positional indicators: one word each (M3-20's counter).
  pi,

  /// The constant pool, allocated in first-need order during
  /// generation, one entry per distinct constant as written (M4-4).
  cp,
}

/// Base locators the program needs: one for the IOCS label area, plus
/// one buffer pointer per located record (M4-4; M3-11).
int baseLocatorWords(SemanticResult semantics) =>
    1 + semantics.records.where((RecordInfo record) => record.located).length;

/// The object program's address layout (M4-4).
final class ProgramImage {
  ProgramImage({required this.inlineWords, required this.blockWords});

  /// Location Counter 0: the transmitted data areas at M3-6's offsets,
  /// then the procedure text continuing on the same counter.
  final int inlineWords;

  /// Words reserved for each block of Location Counter 1.
  final Map<StorageBlock, int> blockWords;

  /// Location Counter 1 begins where Location Counter 0 ends.
  int get counterOneOrigin => inlineWords;

  /// The first word of [block].
  int originOf(StorageBlock block) {
    int origin = counterOneOrigin;
    for (final StorageBlock each in StorageBlock.values.take(block.index)) {
      origin += blockWords[each] ?? 0;
    }
    return origin;
  }

  /// The word `SYM)n` names. The generated-name suffix counts from one,
  /// so `BL)1` is the block's first word.
  int symbolAddress(StorageBlock block, int number) =>
      originOf(block) + number - 1;

  /// The word `CP)+n` names. The pool alone is written as an offset, so
  /// its suffix counts from zero (D8.8).
  int poolAddress(int offset) => originOf(StorageBlock.cp) + offset;
}
