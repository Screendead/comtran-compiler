/// Shared fixtures for the MOVPAK tests: a machine over hand-built
/// words, and the calling-sequence words the generator emits.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

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

/// `AXT n,1`, the digit count that closes a SYS)267 call ([J 90.02.30]).
int axt(int count) => typeB(0x1FC, address: count, tag: 1);

/// The three MOVPAK cells at the addresses the resolver gives them: the
/// source pointer, the target pointer ([J 90.02.11]) and the
/// improper-data condition (D4.3).
const int sourceCell = 132;
const int targetCell = 133;
const int conditionCell = 131;

/// The source and target areas every case below reads and writes.
const int sourceArea = start + 0x100;
const int targetArea = start + 0x110;

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

/// The BCD code of character [i] of the field starting at [word], byte 0
/// being the word's high-order character ([J 90.02.14]).
int codeAt(Machine subject, int word, int i) =>
    (subject.state.read(word + i ~/ 6) >> (6 * (5 - i % 6))) & 0x3F;

/// [count] characters of the field starting at [word], as Set H glyphs.
/// A code with no glyph — an overpunched zero, say — reads `?`.
String glyphsAt(Machine subject, int word, int count) => <String>[
  for (var i = 0; i < count; i++) glyphFromBcd(codeAt(subject, word, i)) ?? '?',
].join();

const ListingOptions _listing = ListingOptions(date: '10/18/61', time: '2.45');

/// Compiles one I/O-free program from its source lines, punches its deck,
/// loads it, and runs it to the end of the job.
(JobCompilation, Machine) compiled(List<String> source) {
  final JobCompilation job = compileDeck(
    mirrorToDeck('${source.join('\n')}\n'),
  ).jobs.single;
  final subject = Machine.load(jobDeck(job, _listing)!.cards);
  expect(subject.run(maxSteps: 5000).outcome, RunOutcome.endOfJob);
  return (job, subject);
}

/// The absolute address of the storage [label] reserves.
int addressOf(JobCompilation job, String label) =>
    Machine.programOrigin +
    job.codegen!.units
        .firstWhere((AssemblyUnit unit) => unit.labels.contains(label))
        .location!;
