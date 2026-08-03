/// Test helpers: build 7090 instruction words field by field.
///
/// Field layout per `docs/design/emulator.md` §4 and 22-6528-4 pp. 8-10
/// (external).
library;

/// A type-B word from its 12-bit operation field (the listing's four-digit
/// signed octal, e.g. `0o4500` for −0500), address, tag, and flag.
int typeB(int operation, {int address = 0, int tag = 0, bool flag = false}) =>
    (operation << 24) | (flag ? 3 << 22 : 0) | (tag << 15) | address;

/// A type-A word from its three-bit prefix (S, 1, 2), decrement, tag, and
/// address.
int typeA(int prefix, {int decrement = 0, int tag = 0, int address = 0}) =>
    (prefix << 33) | (decrement << 18) | (tag << 15) | address;

/// A sign-magnitude data word.
int data(int magnitude, {bool negative = false}) =>
    (negative ? 1 << 35 : 0) | magnitude;
