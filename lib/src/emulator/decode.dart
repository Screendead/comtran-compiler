import 'word.dart';

/// The instructions of the harvested COMTRAN subset, plus [Op.unknown].
///
/// Membership and citations: §5 of `docs/design/emulator.md`. Octal codes
/// are attested by the J 90.05 listing's opcode column and by 22-6528-4
/// (external); page numbers appear at each execute case in `cpu.dart`.
enum Op {
  // Fixed point (22-6528-4 pp. 20-24).
  /// CLA. AC(S,1–35) ← C(Y); P,Q ← 0. Octal +0500 (M p. 20).
  cla,

  /// CAL. AC(P,1–35) ← C(Y) with S of Y in P; S,Q ← 0. Octal −0500 (M p. 20).
  cal,

  /// ADD. AC ← AC + C(Y) algebraically; overflow on carry into P. Octal
  /// +0400 (M pp. 20–21).
  add,

  /// SUB. AC ← AC − C(Y) algebraically (ADD with Y sign reversed). Octal
  /// +0402 (M p. 21).
  sub,

  /// ACL. AC(P,1–35) ← AC(P,1–35) + C(Y) logically, end-around carry
  /// P→35; S,Q untouched. Octal +0361 (M pp. 21–22).
  acl,

  /// MPY. AC,MQ ← C(Y) × C(MQ), 70-bit product; signs algebraic. Octal
  /// +0200 (M p. 22).
  mpy,

  /// DVP. If |C(Y)| > |AC|: MQ ← quotient, AC ← remainder; else
  /// divide-check on, proceed. Octal +0221 (M p. 24).
  dvp,
  // Word transmission (pp. 33-34).
  /// STO. C(Y) ← AC(S,1–35). Octal +0601 (M p. 33).
  sto,

  /// SLW. C(Y) ← AC(P,1–35). Octal +0602 (M p. 33).
  slw,

  /// STQ. C(Y) ← C(MQ). Octal −0600 (M p. 33).
  stq,

  /// LDQ. MQ ← C(Y). Octal +0560 (M p. 33).
  ldq,

  /// XCA. AC(S,1–35) ↔ MQ(S,1–35); P,Q ← 0. Octal +0131 (M p. 34).
  xca,
  // Logical (pp. 48-49).
  /// ANA. AC(P,1–35) ← AC AND C(Y); S,Q ← 0. Octal −0320 (M p. 48).
  ana,

  /// ANS. C(Y) ← AC(P,1–35) AND C(Y); AC unchanged. Octal +0320 (M p. 48).
  ans,

  /// ORS. C(Y) ← AC(P,1–35) OR C(Y); AC unchanged. Octal −0602 (M p. 48).
  ors,

  /// COM. AC(Q,P,1–35) ← ones-complement; sign unchanged. Octal +0760…06
  /// (M p. 49).
  com,
  // Compares (p. 43).
  /// CAS. Algebraic compare AC : C(Y); >, =, < → skip 0, 1, 2; +0 > −0.
  /// Octal +0340 (M p. 43).
  cas,

  /// LAS. Unsigned compare AC(Q,P,1–35) : C(Y)(S,1–35); skip 0, 1, 2.
  /// Octal −0340 (M p. 43).
  las,
  // Control (pp. 35-39).
  /// TRA. IC ← Y (indexable; indirect attested as `TRA*`). Octal +0020
  /// (M p. 36).
  tra,

  /// TPL. If AC sign plus: IC ← Y. Octal +0120 (M p. 38).
  tpl,

  /// TSX. XR(T) ← 2^15 − (location of TSX); IC ← Y. Octal +0074 (M p. 39).
  tsx,

  /// NOP. No operation. Octal +0761 (M p. 35).
  nop,
  // Type A (pp. 39-40).
  /// TXI. XR(T) ← XR(T) + D; IC ← Y. Octal +1, type A (M p. 39).
  txi,

  /// TXH. If XR(T) > D: IC ← Y. Octal +3, type A (M p. 39).
  txh,

  /// TXL. If XR(T) ≤ D: IC ← Y. Octal −3, type A (M p. 40).
  txl,
  // Index transmission (pp. 45-47).
  /// AXT. XR(T) ← instruction address (no address modification). Octal
  /// +0774 (M p. 45).
  axt,

  /// SXA. C(Y)(21–35) ← XR(T); rest of Y unchanged; tag 0 stores zeros.
  /// Octal +0634 (M p. 46).
  sxa,

  /// LXA. XR(T) ← C(Y)(21–35). Octal +0534 (M p. 45).
  lxa,

  /// LAC. XR(T) ← 2^15 − C(Y)(21–35). Octal +0535 (M p. 45).
  lac,

  /// PXA. AC ← 0, then AC(21–35) ← XR(T). Octal +0754 (M p. 47).
  pxa,

  /// PDX. XR(T) ← AC(3–17). Octal −0734 (M p. 46).
  pdx,
  // Sense indicators (pp. 51-55).
  /// LDI. SI ← C(Y). Octal +0441 (M p. 51).
  ldi,

  /// STI. C(Y) ← SI. Octal +0604 (M p. 51).
  sti,

  /// SIR. SI(18–35) ← SI(18–35) OR R. Octal +0055 (M p. 52).
  sir,

  /// RIR. SI(18–35) ← SI(18–35) AND NOT R. Octal +0057 (M p. 52).
  rir,

  /// RFT. If all SI positions selected by R are 0: skip 1. Octal +0054
  /// (M p. 55).
  rft,
  // Shifts (pp. 31-32).
  /// ALS. Shift AC(Q,P,1–35) left; overflow if a 1 moves from 1 into P.
  /// Octal +0767 (M p. 31).
  als,

  /// ARS. Shift AC(Q,P,1–35) right; no indicators. Octal +0771 (M p. 32).
  ars,

  /// LRS. Shift AC+MQ(1–35) right; MQ sign ← AC sign. Octal +0765
  /// (M p. 32).
  lrs,

  /// LGL. Shift AC(Q,P,1–35)+MQ(S,1–35) left; overflow into/through P.
  /// Octal −0763 (M p. 32).
  lgl,

  /// LGR. Shift AC(Q,P,1–35)+MQ(S,1–35) right; no indicators. Octal
  /// −0765 (M p. 32).
  lgr,

  /// RQL. Rotate MQ(S,1–35) left, circular; no bits lost. Octal −0773
  /// (M p. 32).
  rql,
  // Convert (p. 56).
  /// CVR. Convert by replacement from the AC, count C, table at Y. Octal
  /// +0114 (M p. 56).
  cvr,

  /// Anything outside the subset; executing it throws.
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
      final sign = prefix & 4 != 0 ? '-' : '+';
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
