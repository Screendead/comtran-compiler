/// 36-bit sign-magnitude word operations for the 7090 CPU core.
///
/// Implements §2 of `docs/design/emulator.md` (decision ED-1). A word is one
/// Dart `int` in `0 .. 2^36 - 1`. Position S (the sign) is bit 35; position
/// *n* (1–35) is bit `35 - n` (22-6528-4 p. 7, external).
// ignore: avoid_classes_with_only_static_members, reason: Word36 is a namespace of bit-field helpers over a plain int word (LNT-10); converting it to an extension type or top-level functions touches 102 call sites across lib/ and test/ for a low-severity, judgment-call finding, and top-level names this generic (sign, tag, count, address) risk colliding with local identifiers in the emulator. Deferred to a dedicated refactor.
abstract final class Word36 {
  /// Bits per storage word.
  static const int bits = 36;

  /// Mask of a full 36-bit word (S, 1–35).
  static const int wordMask = (1 << 36) - 1;

  /// Mask of the 35-bit magnitude (positions 1–35).
  static const int magnitudeMask = (1 << 35) - 1;

  /// The S-position bit.
  static const int signBit = 1 << 35;

  /// Mask of a 15-bit address or decrement field.
  static const int fieldMask15 = (1 << 15) - 1;

  /// The sign of [word]: 0 = plus, 1 = minus (position S).
  static int sign(int word) => (word >> 35) & 1;

  /// The 35-bit magnitude of [word] (positions 1–35).
  static int magnitude(int word) => word & magnitudeMask;

  /// A word from a sign (0 or 1) and a 35-bit magnitude.
  static int fromSignMagnitude(int sign, int magnitude) {
    if (sign < 0 || sign > 1) {
      throw ArgumentError.value(sign, 'sign', 'must be 0 (plus) or 1 (minus)');
    }
    if (magnitude < 0 || magnitude > magnitudeMask) {
      throw ArgumentError.value(magnitude, 'magnitude', 'must fit in 35 bits');
    }
    return (sign << 35) | magnitude;
  }

  /// The prefix of [word]: positions S, 1, 2 (three bits).
  ///
  /// Type-A instructions carry a non-zero value in positions 1–2
  /// (22-6528-4 pp. 8, 39, external).
  static int prefix(int word) => (word >> 33) & 7;

  /// The decrement field of [word]: positions 3–17 (22-6528-4 p. 10).
  static int decrement(int word) => (word >> 18) & fieldMask15;

  /// The tag field of [word]: positions 18–20 (22-6528-4 p. 9).
  static int tag(int word) => (word >> 15) & 7;

  /// The address field of [word]: positions 21–35 (22-6528-4 p. 8).
  static int address(int word) => word & fieldMask15;

  /// Whether [word] carries the indirect-addressing flag: 1-bits in both
  /// positions 12 and 13 (22-6528-4 p. 11).
  static bool flagged(int word) => (word >> 22) & 3 == 3;

  /// The type-B operation field: positions S, 1–11 as one 12-bit value.
  ///
  /// Equal to the four-digit signed octal code as the compilation listing
  /// prints it (the sign folds into the first digit: `4500` = −0500).
  static int operationField(int word) => (word >> 24) & 0xFFF;

  /// The convert-instruction count field: positions 10–17 (22-6528-4 p. 56).
  static int count(int word) => (word >> 18) & 0xFF;

  /// The sense-indicator right-half mask: positions 18–35 (22-6528-4 p. 52).
  static int rightHalf(int word) => word & ((1 << 18) - 1);

  /// [word] as twelve octal digits, the manuals' rendering of a full word.
  static String octal(int word) =>
      (word & wordMask).toRadixString(8).padLeft(12, '0');

  /// A 12-bit operation field as the listing's signed octal (`+0500`,
  /// `-0500` for `4500`).
  static String operationOctal(int operationField) {
    final int signed = operationField & 0xFFF;
    if (signed >= 0x800) {
      return '-${(signed - 0x800).toRadixString(8).padLeft(4, '0')}';
    }
    return '+${signed.toRadixString(8).padLeft(4, '0')}';
  }
}
