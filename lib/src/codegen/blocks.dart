/// The counter heads and the out-of-line blocks (M4-4).
///
/// The transmitted data areas and the procedure text run on Location
/// Counter 0. Everything here is what the listing prints around them:
/// the two head rows that carry Location Counter 1's origin, the
/// Location Counter 2 block that initializes the pointer words, and the
/// five reservations of Location Counter 1.
library;

import 'encode.dart';
import 'image.dart';
import 'text_model.dart';

/// The `USE N` row: a location counter discontinuity, whose control word
/// carries the counter's origin ([J 90.02.02]).
AssemblyUnit _use(int counter, {required int origin}) => AssemblyUnit(
  operation: 'USE',
  operand: '$counter',
  word: counterWord(CounterOp.relativeOrigin, origin),
  control: ControlGroup.locationCounter,
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
///
/// The `USE 2` word carries the counter's origin, `PI)1` — where the
/// counter's text ends, since counter 2 holds exactly the `BL)` block,
/// whose end is `PI)`'s origin under the frozen block order (M4-4 as
/// amended, chunk B7). `BL)1` points the input-output system at its
/// label area, `IOC)29` (M3-11); every later cell starts empty for the
/// OPEN that fills it at run time.
List<AssemblyUnit> pointerInitialization(ProgramImage image) {
  final int origin = image.symbolAddress(StorageBlock.bl, 1);
  return <AssemblyUnit>[
    _use(2, origin: image.symbolAddress(StorageBlock.pi, 1)),
    AssemblyUnit(
      operation: 'ORG',
      operand: 'BL)1',
      location: origin,
      word: counterWord(CounterOp.relativeOrigin, origin),
      control: ControlGroup.locationCounter,
      form: WordForm.prefix,
    ),
    for (var i = 0; i < (image.blockWords[StorageBlock.bl] ?? 0); i++)
      AssemblyUnit(
        operation: 'PZE',
        operand: i == 0 ? 'IOC)29' : '0',
        location: origin + i,
        word: i == 0 ? pzeWord(address: 29) : 0,
        control: i == 0
            ? standardControl(Relocation.constant, Relocation.system)
            : ControlGroup.constantWord,
        form: WordForm.prefix,
      ),
  ];
}

/// Location Counter 1: the four reservations and the constant pool, in
/// the frozen [StorageBlock] order (M4-4). [poolUnits] is the pool's
/// printed lines, already placed at their `CP)` addresses.
List<AssemblyUnit> outOfLineBlocks(
  ProgramImage image,
  List<AssemblyUnit> poolUnits,
) {
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
    ...poolUnits,
  ];
}
