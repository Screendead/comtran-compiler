import 'decode.dart';
import 'machine_state.dart';
import 'word.dart';

/// Thrown when the CPU is asked to execute a word outside the harvested
/// instruction subset (decision ED-4, `docs/design/emulator.md` §7).
///
/// Carries the signed octal operation code, the instruction's location, and
/// the full word. The CPU throws before it changes any state.
final class UnimplementedOpcode7090 implements Exception {
  UnimplementedOpcode7090(this.operation, this.location, this.word);

  /// The signed octal operation code (`+0522`, `-2`, or a 0760-family
  /// sub-operation such as `+0760 address 00007`).
  final String operation;

  /// The location (IC value) of the instruction.
  final int location;

  /// The full 36-bit instruction word.
  final int word;

  @override
  String toString() =>
      'Unimplemented 7090 operation $operation at '
      '${location.toRadixString(8).padLeft(5, '0')} '
      '(word ${Word36.octal(word)})';
}

/// The 7090 CPU core: fetch, decode, and execute for the harvested subset.
///
/// Implements `docs/design/emulator.md`. Each execute case cites the
/// instruction description in 22-6528-4 (external, "M p. N") that defines
/// its behavior; the J citations for *why* each instruction is in the subset
/// are in the design document's §5 table.
final class Cpu {
  Cpu(this.state);

  /// The machine state the CPU reads and writes.
  final MachineState state;

  /// Executes one instruction at the current IC.
  ///
  /// Fetches, advances the IC by one (mod 2^15; M p. 9), and executes.
  /// Throws [UnimplementedOpcode7090] — before any state change — for a
  /// word outside the subset.
  void step() {
    final int location = state.ic;
    final int word = state.read(location);
    final inst = Instruction.decode(word);
    if (inst.op == Op.unknown) {
      throw UnimplementedOpcode7090(inst.operationOctal, location, word);
    }
    if (inst.op == Op.com) {
      // The +0760 family selects its sub-operation by the modified address;
      // only 00006 = COM is in the subset (M p. 49; decision ED-3).
      final int sub = _effectiveAddress(inst, indirectable: false);
      if (sub != 6) {
        throw UnimplementedOpcode7090(
          '+0760 address ${sub.toRadixString(8).padLeft(5, '0')}',
          location,
          word,
        );
      }
    }
    state.ic = (location + 1) & Word36.fieldMask15;
    _execute(inst, location);
  }

  /// The effective address: instruction address minus the OR of the tagged
  /// index registers, mod 2^15 (M p. 10). With [indirectable] and the flag
  /// set (1-bits in positions 12 and 13), one level of indirection applies:
  /// the tag and address parts of the indirectly addressed word give the
  /// direct effective address (M p. 11).
  int _effectiveAddress(Instruction inst, {required bool indirectable}) {
    int ea = (inst.address - state.xrRead(inst.tag)) & Word36.fieldMask15;
    if (indirectable && inst.flagged) {
      final int indirectWord = state.read(ea);
      ea =
          (Word36.address(indirectWord) -
              state.xrRead(Word36.tag(indirectWord))) &
          Word36.fieldMask15;
    }
    return ea;
  }

  void _execute(Instruction inst, int location) {
    switch (inst.op) {
      // ----- Fixed point -------------------------------------------------
      case Op.cla: // M p. 20: AC(S,1-35) <- C(Y); P and Q to zero.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        state.acSign = Word36.sign(y);
        state.acMagnitude = Word36.magnitude(y);
      case Op.cal: // M p. 20: AC(P,1-35) <- C(Y), S of Y in P; S,Q zero.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        state.acSign = 0;
        state.acMagnitude = y; // Bit layout matches: S of Y lands in P.
      case Op.add: // M pp. 20-21: algebraic add.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        _addSigned(Word36.magnitude(y), Word36.sign(y));
      case Op.sub: // M p. 21: sign of Y reversed, then the ADD procedure.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        _addSigned(Word36.magnitude(y), 1 - Word36.sign(y));
      case Op.acl: // M pp. 21-22: logical add to AC(P,1-35), end-around
        // carry from P into position 35; S and Q are not affected.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        int sum = (state.acMagnitude & Word36.wordMask) + y;
        if (sum > Word36.wordMask) {
          sum = (sum & Word36.wordMask) + 1;
        }
        state.acMagnitude = (state.acMagnitude & MachineState.acQBit) | sum;
      case Op.mpy: // M p. 22: 70-bit product of C(Y) and C(MQ); the signs
        // of AC and MQ take the algebraic sign of the product, so a zero
        // product with unlike factor signs yields minus zero.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        final int productSign = Word36.sign(y) ^ Word36.sign(state.mq);
        final BigInt product =
            BigInt.from(Word36.magnitude(y)) *
            BigInt.from(Word36.magnitude(state.mq));
        final int high = (product >> 35).toInt();
        final int low = (product & BigInt.from(Word36.magnitudeMask)).toInt();
        state.acSign = productSign;
        state.acMagnitude = high; // Q and P are cleared: high < 2^35.
        state.mq = Word36.fromSignMagnitude(productSign, low);
      case Op.dvp: // M p. 24: divide or proceed. Division requires
        // |C(Y)| > |AC| over the full 37-bit AC magnitude; otherwise the
        // divide-check indicator turns on and the dividend is unchanged.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        final int divisor = Word36.magnitude(y);
        if (divisor <= state.acMagnitude) {
          state.divideCheck = true;
          return;
        }
        final BigInt dividend =
            (BigInt.from(state.acMagnitude) << 35) |
            BigInt.from(Word36.magnitude(state.mq));
        final big = BigInt.from(divisor);
        final int quotient = (dividend ~/ big).toInt();
        final int remainder = (dividend % big).toInt();
        // MQ sign: the algebraic sign of the quotient; AC sign: the sign
        // of the dividend (unchanged).
        state.mq = Word36.fromSignMagnitude(
          state.acSign ^ Word36.sign(y),
          quotient,
        );
        state.acMagnitude = remainder;

      // ----- Word transmission -------------------------------------------
      case Op.sto: // M p. 33: C(Y) <- AC(S,1-35).
        state.write(_effectiveAddress(inst, indirectable: true), state.acWord);
      case Op.slw: // M p. 33: C(Y) <- AC(P,1-35).
        state.write(
          _effectiveAddress(inst, indirectable: true),
          state.acLogicalWord,
        );
      case Op.stq: // M p. 33: C(Y) <- C(MQ).
        state.write(_effectiveAddress(inst, indirectable: true), state.mq);
      case Op.ldq: // M p. 33: MQ <- C(Y).
        state.mq = state.read(_effectiveAddress(inst, indirectable: true));
      case Op.xca: // M p. 34: AC(S,1-35) and MQ exchanged; P and Q cleared.
        final int newMq = state.acWord;
        state.acSign = Word36.sign(state.mq);
        state.acMagnitude = Word36.magnitude(state.mq);
        state.mq = newMq;

      // ----- Logical ------------------------------------------------------
      case Op.ana: // M p. 48: AC(P,1-35) AND C(Y)(S,1-35); S and Q cleared.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        state.acMagnitude = (state.acMagnitude & Word36.wordMask) & y;
        state.acSign = 0;
      case Op.ans: // M p. 48: C(Y) <- AC(P,1-35) AND C(Y); AC unchanged.
        final int ea = _effectiveAddress(inst, indirectable: true);
        state.write(ea, (state.acMagnitude & Word36.wordMask) & state.read(ea));
      case Op.ors: // M p. 48: C(Y) <- AC(P,1-35) OR C(Y); AC unchanged.
        final int ea = _effectiveAddress(inst, indirectable: true);
        state.write(ea, (state.acMagnitude & Word36.wordMask) | state.read(ea));
      case Op.com: // M p. 49: AC(Q,P,1-35) complemented; sign unchanged.
        state.acMagnitude = ~state.acMagnitude & MachineState.acMagnitudeMask;

      // ----- Compares -----------------------------------------------------
      case Op.cas: // M p. 43: algebraic compare, skip 0/1/2 for >/=/<.
        // Equal requires equal magnitudes and equal signs; a plus zero is
        // algebraically greater than a minus zero.
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        final int ySign = Word36.sign(y);
        final int yMagnitude = Word36.magnitude(y);
        final int skip;
        if (state.acSign == ySign) {
          if (state.acMagnitude == yMagnitude) {
            skip = 1;
          } else {
            final bool greater =
                (state.acMagnitude > yMagnitude) ^ (state.acSign == 1);
            skip = greater ? 0 : 2;
          }
        } else {
          skip = state.acSign == 0 ? 0 : 2;
        }
        state.ic = (state.ic + skip) & Word36.fieldMask15;
      case Op.las: // M p. 43: AC(Q,P,1-35) unsigned against C(Y)(S,1-35).
        final int y = state.read(_effectiveAddress(inst, indirectable: true));
        final int skip;
        if (state.acMagnitude > y) {
          skip = 0;
        } else if (state.acMagnitude == y) {
          skip = 1;
        } else {
          skip = 2;
        }
        state.ic = (state.ic + skip) & Word36.fieldMask15;

      // ----- Control ------------------------------------------------------
      case Op.tra: // M p. 36: IC <- Y.
        state.ic = _effectiveAddress(inst, indirectable: true);
      case Op.tpl: // M p. 38: transfer when the AC sign is plus.
        if (state.acSign == 0) {
          state.ic = _effectiveAddress(inst, indirectable: true);
        }
      case Op.tsx: // M p. 39: XR(T) <- 2's complement of the TSX location;
        // IC <- Y. The tag names the target register (M p. 10), so the
        // address takes no modification.
        state.xrWrite(inst.tag, (0x8000 - location) & Word36.fieldMask15);
        state.ic = inst.address;
      case Op.nop: // M p. 35.
        break;

      // ----- Type A -------------------------------------------------------
      case Op.txi: // M p. 39: XR(T) <- XR(T) + D; IC <- Y. Carries out of
        // the fifteenth bit are lost (M p. 10).
        state.xrWrite(
          inst.tag,
          (state.xrRead(inst.tag) + inst.decrement) & Word36.fieldMask15,
        );
        state.ic = inst.address;
      case Op.txh: // M p. 39: transfer when XR(T) > D.
        if (state.xrRead(inst.tag) > inst.decrement) {
          state.ic = inst.address;
        }
      case Op.txl: // M p. 40: transfer when XR(T) <= D.
        if (state.xrRead(inst.tag) <= inst.decrement) {
          state.ic = inst.address;
        }

      // ----- Index transmission -------------------------------------------
      case Op.axt: // M p. 45: XR(T) <- the instruction's own address field.
        state.xrWrite(inst.tag, inst.address);
      case Op.sxa: // M p. 46: C(Y)(21-35) <- XR(T); rest unchanged; a tag
        // of 0 stores zeros.
        final int old = state.read(inst.address);
        state.write(
          inst.address,
          (old & ~Word36.fieldMask15) | state.xrRead(inst.tag),
        );
      case Op.lxa: // M p. 45: XR(T) <- C(Y)(21-35).
        state.xrWrite(inst.tag, Word36.address(state.read(inst.address)));
      case Op.lac: // M p. 45: XR(T) <- 2's complement of C(Y)(21-35).
        state.xrWrite(
          inst.tag,
          (0x8000 - Word36.address(state.read(inst.address))) &
              Word36.fieldMask15,
        );
      case Op.pxa: // M p. 47: AC cleared, XR(T) into AC(21-35).
        state.acSign = 0;
        state.acMagnitude = state.xrRead(inst.tag);
      case Op.pdx: // M p. 46: XR(T) <- AC(3-17); AC unchanged.
        state.xrWrite(
          inst.tag,
          ((state.acMagnitude & Word36.magnitudeMask) >> 18) &
              Word36.fieldMask15,
        );

      // ----- Sense indicators ---------------------------------------------
      case Op.ldi: // M p. 51: SI <- C(Y), bit for bit.
        state.si = state.read(_effectiveAddress(inst, indirectable: true));
      case Op.sti: // M p. 51: C(Y) <- SI.
        state.write(_effectiveAddress(inst, indirectable: true), state.si);
      case Op.sir: // M p. 52: SI(18-35) OR the right half of the word.
        state.si |= inst.rightHalf;
      case Op.rir: // M p. 52: reset SI(18-35) positions selected by R.
        state.si &= ~inst.rightHalf;
      case Op.rft: // M p. 55: skip one when every SI position selected by
        // R holds zero.
        if (state.si & inst.rightHalf == 0) {
          state.ic = (state.ic + 1) & Word36.fieldMask15;
        }

      // ----- Shifts (stepwise per the flow charts; decision ED-5) ---------
      case Op.als: // M p. 31: AC(Q,P,1-35) left; overflow when a 1 moves
        // from position 1 into P.
        final int n = _shiftCount(inst);
        int accumulator = state.acMagnitude;
        for (var i = 0; i < n; i++) {
          if (accumulator & (1 << 34) != 0) {
            state.overflow = true;
          }
          accumulator = (accumulator << 1) & MachineState.acMagnitudeMask;
        }
        state.acMagnitude = accumulator;
      case Op.ars: // M p. 32: AC(Q,P,1-35) right; bits past 35 are lost;
        // no indicators (stepwise, like the other shifts; decision ED-5).
        final int n = _shiftCount(inst);
        int accumulator = state.acMagnitude;
        for (var i = 0; i < n; i++) {
          accumulator >>= 1;
        }
        state.acMagnitude = accumulator;
      case Op.lrs: // M p. 32: AC and MQ(1-35) as one register, right; the
        // MQ sign is made to agree with the AC sign.
        final int n = _shiftCount(inst);
        int accumulator = state.acMagnitude;
        int mqMagnitude = Word36.magnitude(state.mq);
        for (var i = 0; i < n; i++) {
          mqMagnitude = (mqMagnitude >> 1) | ((accumulator & 1) << 34);
          accumulator >>= 1;
        }
        state.acMagnitude = accumulator;
        state.mq = Word36.fromSignMagnitude(state.acSign, mqMagnitude);
      case Op.lgl: // M p. 32: AC(Q,P,1-35) and MQ(S,1-35) as one register,
        // left; MQ(S) enters AC(35); overflow when a 1 passes into P.
        final int n = _shiftCount(inst);
        int accumulator = state.acMagnitude;
        int mq = state.mq;
        for (var i = 0; i < n; i++) {
          if (accumulator & (1 << 34) != 0) {
            state.overflow = true;
          }
          accumulator =
              ((accumulator << 1) & MachineState.acMagnitudeMask) |
              ((mq >> 35) & 1);
          mq = (mq << 1) & Word36.wordMask;
        }
        state.acMagnitude = accumulator;
        state.mq = mq;
      case Op.lgr: // M p. 32: the same register pair, right; AC(35) enters
        // MQ(S); bits past MQ(35) are lost; no indicators.
        final int n = _shiftCount(inst);
        int accumulator = state.acMagnitude;
        int mq = state.mq;
        for (var i = 0; i < n; i++) {
          mq = (mq >> 1) | ((accumulator & 1) << 35);
          accumulator >>= 1;
        }
        state.acMagnitude = accumulator;
        state.mq = mq;
      case Op.rql: // M p. 32: rotate MQ(S,1-35) left, circular.
        final int n = _shiftCount(inst);
        int mq = state.mq;
        for (var i = 0; i < n; i++) {
          mq = ((mq << 1) & Word36.wordMask) | ((mq >> 35) & 1);
        }
        state.mq = mq;

      // ----- Convert ------------------------------------------------------
      case Op.cvr: // M p. 56, the seven numbered steps. The instruction
        // starts in the SR, so the SR's address part is Y (step 1); each
        // table fetch replaces the whole SR (step 4b).
        int storageRegister = inst.word;
        int count = inst.count;
        while (count != 0) {
          // Step 4b: X = SR(21-35) + AC(30-35); the address registers are
          // 15 bits wide, higher bits drop (M p. 13).
          final int x =
              (Word36.address(storageRegister) + (state.acMagnitude & 0x3F)) &
              Word36.fieldMask15;
          storageRegister = state.read(x);
          // Step 5: AC(Q,P,1-35) right six; an initial 1 in Q lands in
          // position 5 and remains regardless of the table word.
          final qWasSet = state.acMagnitude & MachineState.acQBit != 0;
          int magnitude = state.acMagnitude >> 6;
          // Step 6: SR(S,1-5) replace AC(P,1-5).
          magnitude =
              (magnitude & ~(0x3F << 30)) |
              (((storageRegister >> 30) & 0x3F) << 30);
          if (qWasSet) {
            magnitude |= 1 << 30;
          }
          state.acMagnitude = magnitude;
          count--;
        }
        // Step 4a: with a 1 in position 20, SR(21-35) replaces XR 1.
        if (inst.tag & 1 != 0) {
          state.xrWrite(1, Word36.address(storageRegister));
        }

      case Op.unknown:
        // Unreachable: step() throws before execution.
        throw StateError('unknown op reached _execute');
    }
  }

  /// The shift magnitude: the effective address modulo 400 octal (M p. 31).
  int _shiftCount(Instruction inst) =>
      _effectiveAddress(inst, indirectable: false) & 0xFF;

  /// The shared ADD/SUB/algebraic-add path (M pp. 20-21, Figure 21).
  ///
  /// Signs alike: true addition of magnitudes; the overflow indicator turns
  /// on when the sum carries out of position 1 into P (M pp. 9, 20). Signs
  /// unlike: ones-complement subtraction with end-around Q carry; with a Q
  /// carry the AC sign reverses, without one the adder output is
  /// recomplemented and the sign stands — so equal magnitudes of unlike
  /// sign leave a zero with the original AC sign (M p. 20). Overflow in the
  /// unlike-signs path is never set: decision ED-2.
  void _addSigned(int yMagnitude, int ySign) {
    final int acMagnitude = state.acMagnitude;
    if (ySign == state.acSign) {
      if ((acMagnitude & Word36.magnitudeMask) + yMagnitude >
          Word36.magnitudeMask) {
        state.overflow = true;
      }
      state.acMagnitude =
          (acMagnitude + yMagnitude) & MachineState.acMagnitudeMask;
    } else {
      final int complement = ~acMagnitude & MachineState.acMagnitudeMask;
      final int sum = complement + yMagnitude;
      if (sum > MachineState.acMagnitudeMask) {
        state.acMagnitude = (sum & MachineState.acMagnitudeMask) + 1;
        state.acSign = ySign;
      } else {
        state.acMagnitude = ~sum & MachineState.acMagnitudeMask;
      }
    }
  }
}
