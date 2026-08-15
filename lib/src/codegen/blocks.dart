/// The counter heads and the out-of-line blocks (M4-4).
///
/// The transmitted data areas and the procedure text run on Location
/// Counter 0. Everything here is what the listing prints around them:
/// the two head rows that carry Location Counter 1's origin, the
/// Location Counter 2 block that initializes the pointer words, and the
/// five reservations of Location Counter 1.
///
/// A column stays blank where B1 has no rule for it. `USE 2` is the one
/// such column: the sample prints its address as 01671, and no entry of
/// [J 90.02] states what a location counter's origin is beyond counter
/// 1's, so the OCTAL word of that one row waits for chunk B7.
library;

import 'image.dart';
import 'text_model.dart';

/// The `USE N` row: a location counter discontinuity, whose control word
/// carries the counter's origin ([J 90.02.02]).
AssemblyUnit _use(int counter, {int? origin}) => AssemblyUnit(
  operation: 'USE',
  operand: '$counter',
  word: origin == null ? null : counterWord(CounterOp.relativeOrigin, origin),
  control: origin == null ? null : ControlGroup.locationCounter,
  form: WordForm.prefix,
);

/// One `SYM) BSS n` reservation of Location Counter 1.
AssemblyUnit _reservation(String symbol, int words, int origin) => AssemblyUnit(
  operation: 'BSS',
  operand: '$words',
  location: origin,
  labels: <String>[symbol],
  word: counterWord(CounterOp.fixedReservation, words),
  control: ControlGroup.locationCounter,
  form: WordForm.prefix,
);

/// The two rows the listing opens with, ahead of the storage map: the
/// counter-1 origin, and the program's `BGN` (M4-7.1). The storage map
/// itself opens with `USE 0`.
///
/// Both carry an address that follows the procedure text, so stage 1
/// could compute neither.
List<AssemblyUnit> counterHead(ProgramImage image) => <AssemblyUnit>[
  _use(1, origin: image.counterOneOrigin),
  AssemblyUnit(
    operation: 'BGN',
    operand: '2,PI)1',
    location: image.symbolAddress(StorageBlock.pi, 1),
  ),
];

/// Location Counter 2: an `ORG` to the pointer block, then one
/// pre-determined constant per base locator (M4-4; [J 90.02.01]).
List<AssemblyUnit> pointerInitialization(ProgramImage image) {
  final int origin = image.symbolAddress(StorageBlock.bl, 1);
  return <AssemblyUnit>[
    _use(2),
    AssemblyUnit(
      operation: 'ORG',
      operand: 'BL)1',
      location: origin,
      word: counterWord(CounterOp.relativeOrigin, origin),
      control: ControlGroup.locationCounter,
      form: WordForm.prefix,
    ),
    for (var i = 0; i < (image.blockWords[StorageBlock.bl] ?? 0); i++)
      AssemblyUnit(operation: '', operand: '', location: origin + i),
  ];
}

/// Location Counter 1: the four reservations and the constant pool, in
/// the frozen [StorageBlock] order (M4-4).
///
/// The pool prints one line per entry, and the entries themselves are
/// the verb generators' (B2 to B6), so B1 prints their locations alone.
List<AssemblyUnit> outOfLineBlocks(ProgramImage image) {
  int words(StorageBlock block) => image.blockWords[block] ?? 0;
  return <AssemblyUnit>[
    _use(1, origin: image.counterOneOrigin),
    for (final StorageBlock block in const <StorageBlock>[
      StorageBlock.rs,
      StorageBlock.ts,
      StorageBlock.bl,
      StorageBlock.pi,
    ])
      _reservation(block.symbol, words(block), image.originOf(block)),
    for (var i = 0; i < words(StorageBlock.cp); i++)
      AssemblyUnit(
        operation: '',
        operand: '',
        location: image.poolAddress(i),
        labels: i == 0 ? const <String>['CP)'] : const <String>[],
      ),
  ];
}
