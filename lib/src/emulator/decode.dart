import 'word.dart';

/// The instructions of the harvested COMTRAN subset, plus [Op.unknown].
///
/// Membership and citations: §5 of `docs/design/emulator.md`. Octal codes
/// are attested by the J 90.05 listing's opcode column and by 22-6528-4
/// (external); page numbers appear at each execute case in `cpu.dart`.
enum Op {
  // Fixed point (22-6528-4 pp. 20-24).
  cla,
  cal,
  add,
  sub,
  acl,
  mpy,
  dvp,
  // Word transmission (pp. 33-34).
  sto,
  slw,
  stq,
  ldq,
  xca,
  // Logical (pp. 48-49).
  ana,
  ans,
  ors,
  com,
  // Compares (p. 43).
  cas,
  las,
  // Control (pp. 35-39).
  tra,
  tpl,
  tsx,
  nop,
  // Type A (pp. 39-40).
  txi,
  txh,
  txl,
  // Index transmission (pp. 45-47).
  axt,
  sxa,
  lxa,
  lac,
  pxa,
  pdx,
  // Sense indicators (pp. 51-55).
  ldi,
  sti,
  sir,
  rir,
  rft,
  // Shifts (pp. 31-32).
  als,
  ars,
  lrs,
  lgl,
  lgr,
  rql,
  // Convert (p. 56).
  cvr,
  // Anything outside the subset; executing it throws.
  unknown,
}

/// One decoded instruction word.
///
/// Field accessors delegate to [Word36]; which fields are meaningful depends
/// on [op] (§4 of `docs/design/emulator.md`).
final class Instruction {
  /// Decodes [word] (36 bits). Never throws: words outside the subset decode
  /// to [Op.unknown] and fail only on execution (decision ED-4).
  Instruction.decode(this.word) : op = _decodeOp(word & Word36.wordMask);

  /// The raw 36-bit instruction word.
  final int word;

  /// The decoded operation.
  final Op op;

  /// The decrement field (type A).
  int get decrement => Word36.decrement(word);

  /// The tag field.
  int get tag => Word36.tag(word);

  /// The address field.
  int get address => Word36.address(word);

  /// Whether positions 12 and 13 both hold 1 (indirect addressing).
  bool get flagged => Word36.flagged(word);

  /// The convert count field (positions 10–17).
  int get count => Word36.count(word);

  /// The sense-indicator mask (positions 18–35).
  int get rightHalf => Word36.rightHalf(word);

  /// The signed-octal operation code, for diagnostics: `+0500`, `-0500`,
  /// or `+1`/`+3`/`-3` for the type-A prefixes.
  String get operationOctal {
    final int prefix = Word36.prefix(word);
    if (prefix & 3 != 0) {
      final String sign = prefix & 4 != 0 ? '-' : '+';
      return '$sign${prefix & 3}';
    }
    return Word36.operationOctal(Word36.operationField(word));
  }

  static Op _decodeOp(int word) {
    // Type A: a non-zero value in prefix positions 1-2 (22-6528-4 pp. 8, 18,
    // external). TIX (+2), TNX (-2), and STR (-1) are outside the subset.
    final int prefix = Word36.prefix(word);
    if (prefix & 3 != 0) {
      return switch (prefix) {
        1 => Op.txi, // +1
        3 => Op.txh, // +3
        7 => Op.txl, // -3
        _ => Op.unknown,
      };
    }
    // Convert sub-format: the operation is positions S,1-9 and the count is
    // positions 10-17, so the count's top bits overlap the 12-bit field
    // (22-6528-4 p. 56, external). CVR = +0114 with count bits masked off.
    final int operation = Word36.operationField(word);
    if (operation & ~3 == 0x04C /* +0114 */ ) {
      return Op.cvr;
    }
    return switch (operation) {
      0x140 /* +0500 */ => Op.cla,
      0x940 /* -0500 */ => Op.cal,
      0x100 /* +0400 */ => Op.add,
      0x102 /* +0402 */ => Op.sub,
      0x0F1 /* +0361 */ => Op.acl,
      0x080 /* +0200 */ => Op.mpy,
      0x091 /* +0221 */ => Op.dvp,
      0x181 /* +0601 */ => Op.sto,
      0x182 /* +0602 */ => Op.slw,
      0x980 /* -0600 */ => Op.stq,
      0x170 /* +0560 */ => Op.ldq,
      0x059 /* +0131 */ => Op.xca,
      0x1F0 /* +0760 */ => Op.com, // Sub-operation checked at execution.
      0x8D0 /* -0320 */ => Op.ana,
      0x0D0 /* +0320 */ => Op.ans,
      0x982 /* -0602 */ => Op.ors,
      0x0E0 /* +0340 */ => Op.cas,
      0x8E0 /* -0340 */ => Op.las,
      0x010 /* +0020 */ => Op.tra,
      0x050 /* +0120 */ => Op.tpl,
      0x03C /* +0074 */ => Op.tsx,
      0x1F1 /* +0761 */ => Op.nop,
      0x1FC /* +0774 */ => Op.axt,
      0x19C /* +0634 */ => Op.sxa,
      0x15C /* +0534 */ => Op.lxa,
      0x15D /* +0535 */ => Op.lac,
      0x1EC /* +0754 */ => Op.pxa,
      0x9DC /* -0734 */ => Op.pdx,
      0x121 /* +0441 */ => Op.ldi,
      0x184 /* +0604 */ => Op.sti,
      0x02D /* +0055 */ => Op.sir,
      0x02F /* +0057 */ => Op.rir,
      0x02C /* +0054 */ => Op.rft,
      0x1F7 /* +0767 */ => Op.als,
      0x1F9 /* +0771 */ => Op.ars,
      0x1F5 /* +0765 */ => Op.lrs,
      0x9F3 /* -0763 */ => Op.lgl,
      0x9F5 /* -0765 */ => Op.lgr,
      0x9FB /* -0773 */ => Op.rql,
      _ => Op.unknown,
    };
  }
}
