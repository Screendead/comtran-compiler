/// The control groups of a text card ([J 90.03.04]; M4-16): the 5-bit
/// group of each object word, which the deck writer punches, the loader
/// reads, and the listing prints as M4-8's CNTRL column.
///
/// The file imports nothing. The loader is the runtime's, so an import
/// here would carry the code generator into every run of a compiled
/// program.
library;

/// A field's relocation class in a standard word's control group
/// `1 AB CD` ([J 90.03.04]). The enum index is the two-bit code. The
/// fourth code, `11` a complex expression, no generator emits.
enum Relocation {
  /// `00`: the field is a constant the loader leaves alone.
  constant,

  /// `01`: the field is a relative location the loader relocates.
  relative,

  /// `10`: the field is a system reference number.
  system,
}

/// The 5-bit control groups of [J 90.03.04].
abstract final class ControlGroup {
  /// A standard data word `1 AB CD` with a constant decrement and a
  /// constant address; the CNTRL column prints `10000`.
  static const int constantWord = 0x10;

  /// A location counter control entry, whose word reads `OP A`; the
  /// CNTRL column prints `00001`.
  static const int locationCounter = 0x01;

  /// The end-of-text entry, whose address field holds the relative
  /// program entry point; the CNTRL column prints `01111`.
  static const int endOfText = 0x0F;
}

/// The control group of a standard word `1 AB CD`: [decrement] fills AB
/// and [address] CD ([J 90.03.04]).
int standardControl(Relocation decrement, Relocation address) =>
    ControlGroup.constantWord | (decrement.index << 2) | address.index;

/// The `OP` of a location counter control entry ([J 90.03.04]), named by
/// the prefix digit the OCTAL column prints.
///
/// [J 90.03.04] defines four: `PZE` 0 an absolute origin, `PTW` 2, `PTH`
/// 3 a variable-length reservation, and `MON` 5. Only the two the
/// storage map emits are declared here.
abstract final class CounterOp {
  /// `PTW`: a fixed-length reservation whose address holds the length.
  static const int fixedReservation = 2;

  /// `MON`: the address is a relative origin — what `USE` and `ORG`
  /// emit.
  static const int relativeOrigin = 5;
}

/// The word of a location counter control entry: [op] in the prefix,
/// [address] in the address field.
int counterWord(int op, int address) => (op << 33) | (address & 0x7FFF);

/// The CNTRL column's text for the 5-bit group [control].
String controlColumn(int control) => control.toRadixString(2).padLeft(5, '0');
