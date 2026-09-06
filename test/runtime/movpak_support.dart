/// Shared fixtures for the MOVPAK tests: a machine over hand-built
/// words, and the calling-sequence words the generator emits.
library;

import 'package:comtran/comtran.dart';

import '../emulator/asm.dart';

/// Where every calling sequence below sits: the program's first word.
const int start = Machine.programOrigin;

/// Junk index register 1 carries into a call, which the entry clears.
const int junkCount = 0x29C;

/// Junk index register 2 carries through a call untouched (RT-3).
const int junkLocator = 0xFFF;

/// A machine holding [words] at absolute addresses, entered at [start],
/// with junk in the two index registers a MOVPAK call must not disturb
/// or must clear (RT-3).
Machine machine(Map<int, int> words) {
  final built = Machine(
    LoadedProgram(
      deckName: '',
      origin: Machine.programOrigin,
      entry: start,
      words: words,
      files: const <LoaderFile>[],
      cardsRead: 0,
    ),
  );
  built.state
    ..xrWrite(1, junkCount)
    ..xrWrite(2, junkLocator);
  return built;
}

/// `TSX SYS)nnn,4`, the linkage of a MOVPAK entry ([J 90.02.14]).
int tsx(int entry) => typeB(0x03C, address: entry, tag: 4);

/// `TXI SYS)nnn,1,count`, one step of a calling sequence
/// ([J 90.02.14]).
int txi(int entry, int count) =>
    typeA(1, decrement: count, tag: 1, address: entry);

/// `PZE LOC,,BYTE`, a pointer cell's contents ([J 90.02.14]).
int pze(int location, int byte) => typeA(0, decrement: byte, address: location);

/// The 15-bit link `TSX` writes into index register 4 from address
/// [location] (`lib/src/emulator/cpu.dart`).
int link(int location) => (0x8000 - location) & Word36.fieldMask15;

/// `TXI IOC)40,0`, the end-of-job return that closes every program
/// below ([J 90.02.10]). Its tag is 0, so it touches no index register.
final int endOfJob = typeA(1, address: 40);

/// One word from six BCD [codes], high-order character first (D0.6).
int bcdWord(List<int> codes) {
  var word = 0;
  for (var i = 0; i < 6; i++) {
    word |= codes[i] << (6 * (5 - i));
  }
  return word;
}

/// One word from six Set H glyphs (D0.6).
int characters(String glyphs) => bcdWord(<int>[
  for (final String glyph in glyphs.split('')) bcdFromGlyph(glyph)!,
]);
