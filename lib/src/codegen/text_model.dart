/// The assembly text model (M4-3): the 1962 symbolic form, one unit per
/// object word or pseudo-operation.
///
/// The vocabulary is the listing's SYMBOLIC column ([J 90.02.02]) plus
/// the two forms only the [J 90.02] calling sequences attest. No modern
/// intermediate form stands behind it: `docs/design/emit-stages.md` bars
/// one without a design record, and M4-3 is the record that declines to
/// have one.
library;

/// How the OCTAL column spaces a word's twelve octal digits (M4-8).
///
/// The four forms print one 36-bit word and differ only in where the
/// spaces fall, so the word is the single source the deck, the listing,
/// and the memory image all render (M4-3).
enum WordForm {
  /// Twelve solid digits: an `OCT` word.
  solid,

  /// `OOOO FF T AAAAA`: a type-B instruction.
  typeB,

  /// `P DDDDD T AAAAA`: PZE, MZE, TXI, TXH, TXL, IOST, BSS, USE, ORG.
  prefix,

  /// `OOOO FF AAAAAA`: a sense-indicator instruction, whose 18-bit mask
  /// runs across the tag and address fields — the attested
  /// `0057 00 777777` at LOC 01240.
  indicator,
}

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

/// The OCTAL column's text for [word] under [form].
String octalColumn(int word, WordForm form) {
  final String digits = word.toRadixString(8).padLeft(12, '0');
  return switch (form) {
    WordForm.solid => digits,
    WordForm.typeB =>
      '${digits.substring(0, 4)} ${digits.substring(4, 6)} '
          '${digits[6]} ${digits.substring(7)}',
    WordForm.prefix =>
      '${digits[0]} ${digits.substring(1, 6)} '
          '${digits[6]} ${digits.substring(7)}',
    WordForm.indicator =>
      '${digits.substring(0, 4)} ${digits.substring(4, 6)} '
          '${digits.substring(6)}',
  };
}

/// The CNTRL column's text for the 5-bit group [control].
String controlColumn(int control) => control.toRadixString(2).padLeft(5, '0');

/// One assembly unit: an object word, or a pseudo-operation.
///
/// Every nullable field is a column the printed line leaves blank.
/// `USE` prints no LOC; `BGN` prints neither OCTAL nor CNTRL (M4-8).
final class AssemblyUnit {
  const AssemblyUnit({
    required this.operation,
    required this.operand,
    this.location,
    this.labels = const <String>[],
    this.word,
    this.control,
    this.form = WordForm.solid,
  });

  /// Words from the first word of the object program.
  final int? location;

  /// Names on this word. Two labels print one per line, the word on the
  /// last (M4-8).
  final List<String> labels;

  final String operation;
  final String operand;

  /// The 36-bit object word.
  final int? word;

  /// The word's 5-bit control group.
  final int? control;

  final WordForm form;
}

/// Operations whose line prints no `+n` offset, and so resets the
/// counter, beyond the labelled lines that reset it for their own
/// reason (M4-8).
const Set<String> resettingOperations = <String>{
  'BSS',
  'USE',
  'ORG',
  'BGN',
  'EQU',
  'START',
};
