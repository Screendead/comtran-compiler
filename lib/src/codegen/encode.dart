/// The encode direction of the 7090 instruction word (M4-9).
///
/// `lib/src/emulator/decode.dart` holds the attested opcode table and
/// reads a word back to an [Op]. Codegen needs the same table forwards,
/// and a second copy of it would be a second authority for the octal
/// codes the OCTAL column prints. So this file states no code of its
/// own: `operationFields` and `typeAPrefixes` are asserted against
/// `Instruction.decode` entry by entry in `test/encode_test.dart`, and
/// the two directions cannot drift.
library;

import '../emulator/decode.dart';
import '../emulator/word.dart';
import 'text_model.dart';

/// The type-B operations, each with the 12-bit operation field of
/// positions S,1–11 — the value the listing prints as four octal digits.
const Map<Op, int> operationFields = <Op, int>{
  Op.cla: 0x140,
  Op.cal: 0x940,
  Op.add: 0x100,
  Op.sub: 0x102,
  Op.acl: 0x0F1,
  Op.mpy: 0x080,
  Op.dvp: 0x091,
  Op.sto: 0x181,
  Op.slw: 0x182,
  Op.stq: 0x980,
  Op.ldq: 0x170,
  Op.xca: 0x059,
  Op.com: 0x1F0,
  Op.ana: 0x8D0,
  Op.ans: 0x0D0,
  Op.ors: 0x982,
  Op.cas: 0x0E0,
  Op.las: 0x8E0,
  Op.tra: 0x010,
  Op.tpl: 0x050,
  Op.tsx: 0x03C,
  Op.nop: 0x1F1,
  Op.axt: 0x1FC,
  Op.sxa: 0x19C,
  Op.lxa: 0x15C,
  Op.lac: 0x15D,
  Op.pxa: 0x1EC,
  Op.pdx: 0x9DC,
  Op.ldi: 0x121,
  Op.sti: 0x184,
  Op.sir: 0x02D,
  Op.rir: 0x02F,
  Op.rft: 0x02C,
  Op.als: 0x1F7,
  Op.ars: 0x1F9,
  Op.lrs: 0x1F5,
  Op.lgl: 0x9F3,
  Op.lgr: 0x9F5,
  Op.rql: 0x9FB,
};

/// The type-A operations, each with its three-bit prefix. A type-A word
/// carries no operation field: the prefix alone names it (22-6528-4
/// p. 39, external — the citation [Instruction] carries).
const Map<Op, int> typeAPrefixes = <Op, int>{Op.txi: 1, Op.txh: 3, Op.txl: 7};

/// The `+0760` sub-operation that selects COM, in the address field
/// (`cpu.dart` rejects every other value).
const int comSubOperation = 6;

/// The mnemonic the SYMBOLIC column prints for [op].
String mnemonic(Op op) => op.name.toUpperCase();

/// Whether [op] takes the type-A word layout.
bool isTypeA(Op op) => typeAPrefixes.containsKey(op);

/// The sense-indicator instructions. Each takes one 18-bit mask that
/// runs across the tag and address fields, so the listing prints six
/// unbroken octal digits where a type-B word prints `T AAAAA`.
const Set<Op> indicatorOps = <Op>{Op.rir, Op.sir, Op.rft};

/// How the OCTAL column spaces [op]'s word.
WordForm formOf(Op op) => switch (op) {
  _ when isTypeA(op) => WordForm.prefix,
  _ when indicatorOps.contains(op) => WordForm.indicator,
  _ => WordForm.typeB,
};

/// A type-B instruction word: the operation field, then tag and address.
int typeBWord(Op op, {int tag = 0, int address = 0}) =>
    (operationFields[op]! << 24) |
    ((tag & 7) << 15) |
    (address & Word36.fieldMask15);

/// A sense-indicator instruction word: the operation field, then the
/// 18-bit mask over positions 18 to 35.
int indicatorWord(Op op, int mask) =>
    (operationFields[op]! << 24) | (mask & Word36.fieldMask18);

/// A type-A instruction word: the prefix, decrement, tag and address.
int typeAWord(Op op, {int tag = 0, int decrement = 0, int address = 0}) =>
    (typeAPrefixes[op]! << 33) |
    ((decrement & Word36.fieldMask15) << 18) |
    ((tag & 7) << 15) |
    (address & Word36.fieldMask15);

/// A `PZE` address word: prefix zero, and the fields the calling
/// sequence carries ([J 90.02.14]).
int pzeWord({int decrement = 0, int tag = 0, int address = 0}) =>
    ((decrement & Word36.fieldMask15) << 18) |
    ((tag & 7) << 15) |
    (address & Word36.fieldMask15);
