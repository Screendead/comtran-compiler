/// MOVPAK (`docs/design/runtime.md` RT-3, RT-4): the two dispatch
/// entries, the step-list protocol under them, and the members that
/// convert and move characters ([J 90.02.14] to [J 90.02.30]).
///
/// One move is one session. The entry captures the calling sequence and
/// the two pointer cells, the CPU executes each `TXI SYS)nnn,1,count`
/// word in turn, and the member's handler takes the count from index
/// register 1 and advances the session's cursor past the words it owns.
library;

import '../chars/char_code.dart';
import '../emulator/machine_state.dart';
import '../emulator/word.dart';
import 'machine.dart';

/// The MOVPAK entries [machine] dispatches, by system reference number
/// (M4-17).
Map<int, RuntimeEntry> movpak(Machine machine) => _Movpak(machine).entries;

/// The MOVPAK source pointer and target pointer ([J 90.02.11]).
const int _sourceCell = 132;
const int _targetCell = 133;

/// The improper-data condition cell (D4.3). Nothing reads or clears it.
const int _conditionCell = 131;

/// The character `0` that SYS)244 moves ([J 90.02.26]), which is not a
/// zero word.
final int _bcdZero = bcdFromGlyph('0')!;

/// A protected digit position, printed as an asterisk. The target
/// control word counts it beside the 8's and 9's ([J 90.02.17] Note 2),
/// so a reader takes it for a digit worth zero (RT-4).
final int _bcdAsterisk = bcdFromGlyph('*')!;

/// The characters an edited image carries between its digits
/// ([J 02.05.05]'s edited row). SYS)269 steps over them and counts none
/// of them (RT-4).
final Set<int> _insertions = <int>{
  for (final String glyph in <String>['.', ',', r'$', '+', '-'])
    bcdFromGlyph(glyph)!,
};

final class _Movpak {
  _Movpak(this._machine);

  final Machine _machine;

  /// The move in hand, or `null` between moves.
  _Session? _session;

  Map<int, RuntimeEntry> get entries => <int, RuntimeEntry>{
    180: () => _enter(setsTarget: true),
    182: () => _enter(setsTarget: false),
    184: _externalToInternal,
    239: () => _move(239, ends: true),
    240: () => _move(240, ends: false),
    241: () => _fill(241, bcdBlank, head: 240),
    243: () => _fill(243, bcdBlank),
    244: () => _fill(244, _bcdZero),
    245: _fillCharacters,
    268: _editedEntry,
    269: _editedDigits,
    275: _editedLength,
  };

  /// SYS)180 and SYS)182, the two dispatch entries the generator emits
  /// ([J 90.02.15]). SYS)180 carries one in-line `PZE LOC,,BYTE` for the
  /// target and resumes at `2,4`; SYS)182 carries none and resumes at
  /// `1,4`. Both leave the instruction counter on the family head, which
  /// the CPU then executes.
  RunOutcome? _enter({required bool setsTarget}) {
    if (_session != null) {
      throw StateError('a MOVPAK entry inside a move');
    }
    final MachineState state = _machine.state;
    if (setsTarget) {
      state.write(_targetCell, _machine.parameter(1));
    }
    state.xrWrite(1, 0);
    _machine.resume(setsTarget ? 2 : 1);
    // Both cells are copied uninterpreted: under SYS)180 the source is a
    // register and SYS)132 is stale (RT-4).
    _session = _Session(
      cursor: state.ic,
      source: _Bytes(state, state.read(_sourceCell)),
      target: _Bytes(state, state.read(_targetCell)),
    );
    return null;
  }

  /// The step discipline of RT-3. The cursor sits on the handler's own
  /// word, so the check reads that word's address field; the advance
  /// then clears the word and the [owned] data words behind it.
  (_Session, int) _step(int entry, {int owned = 0}) {
    final _Session? session = _session;
    if (session == null) {
      throw StateError('SYS)$entry outside a move');
    }
    final int named = Word36.address(_machine.state.read(session.cursor));
    if (named != entry) {
      throw StateError('SYS)$entry reached from a word naming $named');
    }
    final int count = _machine.state.xrRead(1);
    _machine.state.xrWrite(1, 0);
    session.cursor += 1 + owned;
    return (session, count);
  }

  /// Returns to the calling sequence for the next step.
  void _next(_Session session) {
    _machine.state.ic = session.cursor;
  }

  /// Returns past the call and closes the move.
  void _end(_Session session) {
    _machine.state.ic = session.cursor;
    _session = null;
  }

  /// SYS)184 converts NUMBER-OF-CHARACTERS-TO-CONVERT external-decimal
  /// characters and leaves the binary value in the accumulator
  /// ([J 90.02.16]).
  RunOutcome? _externalToInternal() {
    final (_Session session, int count) = _step(184);
    _singlePrecision(184, count);
    _convert(session, count, edited: false);
    _toAccumulator(session);
    _end(session);
    return null;
  }

  /// SYS)268 opens the edited-field convert ([J 90.02.30]). Its
  /// decrement is the literal 1 at the one attested site and no source
  /// says what it means, so the handler reads it and ignores it (RT-4).
  RunOutcome? _editedEntry() {
    final (_Session session, _) = _step(268);
    _next(session);
    return null;
  }

  /// SYS)269 converts NUMBER-OF-CHARACTERS-TO-CONVERT digit positions of
  /// the edited source ([J 90.02.30]).
  RunOutcome? _editedDigits() {
    final (_Session session, int count) = _step(269);
    _convert(session, count, edited: true);
    _next(session);
    return null;
  }

  /// SYS)275 ends the edited-field convert ([J 90.02.30]). Its
  /// TARGET-DECIMAL-NUMERIC-LENGTH is the digit count of the value
  /// delivered, which selects the accumulator against the AC-MQ pair
  /// (RT-4).
  RunOutcome? _editedLength() {
    final (_Session session, int count) = _step(275);
    _singlePrecision(275, count);
    _toAccumulator(session);
    _end(session);
    return null;
  }

  /// SYS)239 moves NUMBER-OF-CHARACTERS-TO-MOVE characters and ends the
  /// move; SYS)240 moves them and leaves SYS)241 to fill the target's
  /// excess ([J 90.02.25]).
  RunOutcome? _move(int entry, {required bool ends}) {
    final (_Session session, int count) = _step(entry);
    for (var i = 0; i < count; i++) {
      session.target.write(session.source.read());
    }
    if (ends) {
      _end(session);
    } else {
      session.head = entry;
      _next(session);
    }
    return null;
  }

  /// SYS)241, SYS)243 and SYS)244 each write [character] as many times
  /// as the count, then end the move ([J 90.02.25], [J 90.02.26]).
  /// SYS)241 completes the SYS)240 pair, so it refuses any other [head].
  RunOutcome? _fill(int entry, int character, {int? head}) {
    final (_Session session, int count) = _step(entry);
    if (head != null && session.head != head) {
      throw StateError('SYS)$entry without SYS)$head');
    }
    for (var i = 0; i < count; i++) {
      session.target.write(character);
    }
    _end(session);
    return null;
  }

  /// SYS)245 fills the target from the six characters of its in-line
  /// `OCT` word, cycling them when the count runs past six
  /// ([J 90.02.26]; RT-4).
  RunOutcome? _fillCharacters() {
    final (_Session session, int count) = _step(245, owned: 1);
    // The `OCT` word lies between the step and the resume, so the
    // advanced cursor has just passed it.
    final int characters = _machine.state.read(session.cursor - 1);
    for (var i = 0; i < count; i++) {
      session.target.write((characters >> (6 * (5 - i % 6))) & 0x3F);
    }
    _end(session);
    return null;
  }

  /// Reads [count] digit positions from the source and accumulates them
  /// into the session's binary value. An [edited] source carries
  /// insertion characters, which are stepped over and not counted
  /// (RT-4).
  void _convert(_Session session, int count, {required bool edited}) {
    var taken = 0;
    while (taken < count) {
      final int bcd = session.source.read();
      if (edited && _insertions.contains(bcd)) {
        continue;
      }
      taken++;
      final (int digit, int sign) = _character(
        bcd,
        last: taken == count,
        edited: edited,
      );
      session.value = session.value * 10 + digit;
      if (taken == count) {
        session.sign = sign;
      }
    }
  }

  /// The digit and the sign one character contributes (0 plus, 1 minus).
  /// Only the [last] position carries an overpunch sign ([J 02.05.05]
  /// note 1). Anything else is an improper data condition (D4.3): the
  /// low four bits are the digit and the run continues.
  (int, int) _character(int bcd, {required bool last, required bool edited}) {
    if (bcd == bcdBlank || (edited && bcd == _bcdAsterisk)) {
      return (0, 0);
    }
    if (bcd <= 9) {
      return (bcd, 0);
    }
    final int zone = bcd >> 4;
    final int part = bcd & 0xF;
    // Zone 1 is the 12 punch and zone 2 the 11 punch; part 10 is row 0
    // read as the digit zero.
    if (last && (zone == 1 || zone == 2) && part >= 1 && part <= 10) {
      return (part == 10 ? 0 : part, zone == 2 ? 1 : 0);
    }
    _machine.state.write(_conditionCell, 1);
    return (part, 0);
  }

  void _toAccumulator(_Session session) {
    _machine.state
      ..acSign = session.sign
      ..acMagnitude = session.value;
  }

  /// More than ten digits is the AC-MQ pair, whose radix no unsealed
  /// source fixes (RT-4; D0.9). Codegen refuses the shape, so no program
  /// run reaches this.
  void _singlePrecision(int entry, int count) {
    if (count > 10) {
      throw UnimplementedRuntimeEntry(entry, 'a $count-digit AC-MQ value (M5)');
    }
  }
}

/// One move, from the entry that opened it to the member that ends it.
final class _Session {
  _Session({required this.cursor, required this.source, required this.target});

  /// The calling-sequence word the CPU runs next, or the word the
  /// handler in hand was reached from.
  int cursor;

  final _Bytes source;
  final _Bytes target;

  /// The member that opened a two-word run, read by the member that
  /// ends it.
  int? head;

  /// The digits converted so far, and their sign (0 plus, 1 minus).
  int value = 0;
  int sign = 0;
}

/// A character cursor over core storage: a word address and a byte 0 to
/// 5, byte 0 being the word's high-order character ([J 90.02.14]).
/// Reading and writing each step it on, across the word boundary.
final class _Bytes {
  _Bytes(this._state, int pointer)
    : _word = Word36.address(pointer),
      _byte = Word36.decrement(pointer);

  final MachineState _state;
  int _word;
  int _byte;

  int get _shift => 6 * (5 - _byte);

  int read() {
    final int character = (_state.read(_word) >> _shift) & 0x3F;
    _advance();
    return character;
  }

  void write(int character) {
    final int word = _state.read(_word);
    _state.write(_word, (word & ~(0x3F << _shift)) | (character << _shift));
    _advance();
  }

  void _advance() {
    _byte++;
    if (_byte == 6) {
      _byte = 0;
      _word++;
    }
  }
}
