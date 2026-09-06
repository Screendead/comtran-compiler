/// The run frame (`docs/design/runtime.md` RT-2): the SYS)/IOC) entries
/// an I/O-free program reaches — open all, close all, the STOP display,
/// the base-locator guard, and the monitor's end-of-job return point
/// ([J 90.02.10]; [J 90.02.14]; [J 90.02.33]).
///
/// The communication cells SYS)132, SYS)133, IOC)1 and IOC)29 need no
/// handler: they are memory, and generated code reads and writes them
/// with ordinary instructions ([J 90.02.10]).
library;

import '../chars/char_code.dart';
import '../emulator/word.dart';
import 'machine.dart';

/// The run-frame entries [machine] dispatches, by system reference
/// number (M4-17).
Map<int, RuntimeEntry> runFrame(Machine machine) => <int, RuntimeEntry>{
  // "The end of job return point in the CT Monitor communication area
  // for all CT jobs" ([J 90.02.10]), entered by `TXI IOC)40,0`.
  40: () => RunOutcome.endOfJob,
  175: () => _files(machine, 175),
  177: () => _files(machine, 177),
  178: () => _stop(machine),
  294: () => _baseLocator(machine),
};

/// SYS)175 open-all and SYS)177 close-all ([J 90.02.14]). The one
/// parameter word locates IOC)1, the cell `PZE L,,N` whose decrement
/// counts the files ([J 90.02.10]). An empty list has nothing to open
/// and nothing to close.
RunOutcome? _files(Machine machine, int number) {
  final int header = machine.state.read(Word36.address(machine.parameter(1)));
  final int count = Word36.decrement(header);
  if (count != 0) {
    throw UnimplementedRuntimeEntry(number, 'a file list of $count (M5)');
  }
  machine.resume(2);
  return null;
}

/// SYS)178, the STOP display ([J 90.02.14]). Two parameter words carry
/// four constant-pool references, two to a word: the statement stamp
/// first, then the STOP type (M4-14).
RunOutcome? _stop(Machine machine) {
  final text = StringBuffer();
  for (var k = 1; k <= 2; k++) {
    final int reference = machine.parameter(k);
    text
      ..write(_characters(machine, Word36.address(reference)))
      ..write(_characters(machine, Word36.decrement(reference)));
  }
  machine
    ..display(_stopLine(text.toString()))
    ..resume(3);
  return null;
}

/// SYS)294, the base-locator guard ([J 90.02.33]). `TXL SYS)294,N,0`
/// reaches it with no calling sequence when index register N is zero,
/// which is when the base locator the preceding `LAC` read has an
/// address field of zero. Control does not return.
RunOutcome _baseLocator(Machine machine) {
  machine.display('BASE LOCATOR NOT LOADED');
  return RunOutcome.errorExit;
}

/// The display line of a STOP: [J 05.06.04]'s "AT xxxxx,yy STOP
/// nnnnnn". The manual prints no rule for the pool words' blank
/// padding, so RT-2 drops it and joins what is left with one blank.
String _stopLine(String text) =>
    'AT ${text.split(' ').where((String part) => part.isNotEmpty).join(' ')}';

/// The six BCD characters of the word at [address] (D0.6), high-order
/// character first.
String _characters(Machine machine, int address) {
  final int word = machine.state.read(address);
  final out = StringBuffer();
  for (var i = 5; i >= 0; i--) {
    // The generator builds every pool word from Set H glyphs
    // (`lib/src/codegen/procedure.dart`), so the inverse is total.
    final String glyph = glyphFromBcd((word >> (i * 6)) & 0x3F)!;
    out.write(glyph);
  }
  return out.toString();
}
