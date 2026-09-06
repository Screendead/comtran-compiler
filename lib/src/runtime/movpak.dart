/// MOVPAK (`docs/design/runtime.md` RT-3 to RT-5): the two dispatch
/// entries, the step-list protocol under them, the members that convert
/// and move characters, and the edited-field renderer
/// ([J 90.02.14] to [J 90.02.30]).
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
/// ([J 02.05.05]'s edited row).
final int _bcdPoint = bcdFromGlyph('.')!;
final int _bcdComma = bcdFromGlyph(',')!;
final int _bcdDollar = bcdFromGlyph(r'$')!;
final int _bcdPlus = bcdFromGlyph('+')!;
final int _bcdMinus = bcdFromGlyph('-')!;

/// SYS)269 and SYS)198 step over an insertion character and count none
/// of them (RT-4, RT-5).
final Set<int> _insertions = <int>{
  _bcdPoint,
  _bcdComma,
  _bcdDollar,
  _bcdPlus,
  _bcdMinus,
};

/// TARGET-EDIT-CONTROL, the decrement of an edited family head
/// ([J 90.02.17] Note 1).
const int _editAsterisk = 0x01;
const int _editComma = 0x02;
const int _editPoint = 0x04;
const int _editDollar = 0x08;
const int _editBlankWhenZero = 0x10;

final class _Movpak {
  _Movpak(this._machine);

  final Machine _machine;

  /// The move in hand, or `null` between moves.
  _Session? _session;

  Map<int, RuntimeEntry> get entries => <int, RuntimeEntry>{
    180: () => _enter(setsTarget: true),
    182: () => _enter(setsTarget: false),
    184: _externalToInternal,
    185: () => _editedHead(185),
    190: () => _editedHead(190),
    193: () => _moveDigits(193, edited: false),
    198: () => _moveDigits(198, edited: true),
    211: () => _zeroDigits(211),
    212: () => _zeroDigits(212),
    214: () => _zeroDigits(214),
    216: () => _zeroDigits(216),
    225: () => _terminate(225),
    226: () => _terminate(226),
    239: () => _move(239, ends: true),
    240: () => _move(240, ends: false),
    241: () => _fill(241, bcdBlank, head: 240),
    243: () => _fill(243, bcdBlank),
    244: () => _fill(244, _bcdZero),
    245: _fillCharacters,
    267: _editedStore,
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
    if (session.digits.length != count) {
      throw StateError(
        'SYS)275 over ${session.digits.length} digits of $count',
      );
    }
    _toAccumulator(session);
    _end(session);
    return null;
  }

  /// SYS)185 and SYS)190 open an edited-target move ([J 90.02.17],
  /// [J 90.02.19]). The head's decrement is TARGET-EDIT-CONTROL and the
  /// `OCT` word behind it TARGET-CONTROL-WORD; the terminator renders
  /// from both.
  RunOutcome? _editedHead(int entry) {
    final (_Session session, int edit) = _step(entry, owned: 1);
    session
      ..edit = edit
      ..control = _machine.state.read(session.cursor - 1);
    _next(session);
    return null;
  }

  /// SYS)211, SYS)212, SYS)214 and SYS)216 each append the count in
  /// zero digits, ahead of the moved digits or behind them
  /// ([J 90.02.17], [J 90.02.19]).
  RunOutcome? _zeroDigits(int entry) {
    final (_Session session, int count) = _step(entry);
    session.digits.addAll(List.filled(count, 0));
    _next(session);
    return null;
  }

  /// SYS)193 moves the count in external-decimal digits and SYS)198 the
  /// count in digit positions of an edited source ([J 90.02.17],
  /// [J 90.02.19]). Neither carries a sign note, so neither reads the
  /// source's sign (RT-5).
  RunOutcome? _moveDigits(int entry, {required bool edited}) {
    final (_Session session, int count) = _step(entry);
    _convert(session, count, edited: edited, readsSign: false);
    _next(session);
    return null;
  }

  /// SYS)225 and SYS)226 render the digits the steps built and end the
  /// move ([J 90.02.17], [J 90.02.19]). TARGET-NUMERIC-LENGTH counts
  /// them all, so a step list that misses it is a broken object
  /// program.
  RunOutcome? _terminate(int entry) {
    final (_Session session, int count) = _step(entry);
    if (session.digits.length != count) {
      throw StateError(
        'SYS)$entry over ${session.digits.length} digits of $count',
      );
    }
    _render(
      session.target,
      edit: session.edit,
      control: session.control,
      digits: session.digits,
      sign: 0,
    );
    _end(session);
    return null;
  }

  /// SYS)267 renders the accumulator into an edited target and ends the
  /// move ([J 90.02.30]). Its `OCT` word is TARGET-CONTROL-WORD and its
  /// `AXT` word's address NUMBER-OF-DIGITS-TO-CONVERT; the CPU executes
  /// that `AXT` after the handler returns (RT-3).
  RunOutcome? _editedStore() {
    final (_Session session, int edit) = _step(267, owned: 1);
    final MachineState state = _machine.state;
    final int count = Word36.address(state.read(session.cursor));
    _render(
      session.target,
      edit: edit,
      control: state.read(session.cursor - 1),
      // The source is the accumulator alone: SYS)180's `CLA` leaves the
      // MQ stale, and the divide of D4.1(c) has already dropped the
      // excess into it (RT-5).
      digits: _decimalDigits(state.acMagnitude, count),
      sign: state.acSign,
    );
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

  /// Reads [count] digit positions from the source and appends them to
  /// the session's digits. An [edited] source carries insertion
  /// characters, which are stepped over and not counted (RT-4).
  ///
  /// [readsSign] is false for a step that carries no sign note: the
  /// overpunch it would find is one digit of a longer run, not the
  /// field's last character (RT-5).
  void _convert(
    _Session session,
    int count, {
    required bool edited,
    bool readsSign = true,
  }) {
    var taken = 0;
    while (taken < count) {
      final int bcd = session.source.read();
      if (edited && _insertions.contains(bcd)) {
        continue;
      }
      taken++;
      final bool last = readsSign && taken == count;
      final (int digit, int sign) = _character(bcd, last: last, edited: edited);
      session.digits.add(digit);
      if (last) {
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
      ..acMagnitude = session.digits.fold(0, (int v, int d) => v * 10 + d);
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

/// [magnitude] as [length] decimal digits, high order first. A longer
/// value drops its high-order digits, the same discard the digit-split
/// divide performs, and arms nothing (D4.2; RT-5).
List<int> _decimalDigits(int magnitude, int length) {
  final String text = magnitude.toString().padLeft(length, '0');
  return <int>[
    for (final int unit in text.substring(text.length - length).codeUnits)
      unit - 0x30,
  ];
}

/// Writes the edited image of [digits] through [target] (RT-5).
///
/// [edit] is TARGET-EDIT-CONTROL and [control] TARGET-CONTROL-WORD:
/// prefix the digits ahead of the first comma, decrement the digits
/// ahead of the point, tag the sign convention, address the leading run
/// of protected positions ([J 90.02.17] Note 2). The image is as long
/// as the cells they call for, which is the target's declared length.
void _render(
  _Bytes target, {
  required int edit,
  required int control,
  required List<int> digits,
  required int sign,
}) {
  final int prefix = (control >> 33) & 0x7;
  final int integer = Word36.decrement(control);
  final int convention = Word36.tag(control);
  final int protected = Word36.address(control);
  final int fill = edit & _editAsterisk != 0 ? _bcdAsterisk : bcdBlank;
  if (digits.length < integer) {
    throw StateError(
      'a control word of $integer integer digits over '
      '${digits.length}',
    );
  }

  // Suppression reaches the first significant digit and no further, and
  // the protected run bounds it: a 9 outside that run prints its zero
  // ([F p. 80], [F p. 81]).
  final int significant = digits
      .take(integer)
      .takeWhile((int d) => d == 0)
      .length;
  final suppressed = protected < significant ? protected : significant;

  final image = <int>[];
  var dollarCell = -1;
  var lastDigit = -1;
  if (convention == 5 || convention == 6) {
    image.add(_signCharacter(convention, sign));
  }
  if (edit & _editDollar != 0) {
    dollarCell = image.length;
    image.add(_bcdDollar);
  }
  for (var k = 0; k < integer; k++) {
    if (edit & _editComma != 0 &&
        k > 0 &&
        k >= prefix &&
        (k - prefix) % 3 == 0) {
      // A comma ahead of a suppressed digit takes the fill ([F p. 80]).
      image.add(k <= suppressed ? fill : _bcdComma);
    }
    lastDigit = image.length;
    // D0.6 gives the digits 0 to 9 the BCD codes 0 to 9
    // (`lib/src/chars/char_code.dart`), so a digit value is its own
    // character code, here and at the `bcd <= 9` test of `_character`.
    image.add(k < suppressed ? fill : digits[k]);
  }
  if (edit & _editPoint != 0) {
    image.add(_bcdPoint);
  }
  for (var k = integer; k < digits.length; k++) {
    lastDigit = image.length;
    image.add(digits[k]);
  }
  if (convention == 3 || convention == 4) {
    image.add(_signCharacter(convention, sign));
  }

  // "It will be placed immediately to the left of the first significant
  // digit remaining" ([F p. 80]) — which is the last filled cell, comma
  // cell included. An asterisk fill leaves no room, so the dollar stays.
  if (dollarCell >= 0 && fill == bcdBlank && protected > 0 && suppressed > 0) {
    var float = dollarCell;
    while (float + 1 < image.length && image[float + 1] == fill) {
      float++;
    }
    image[float] = _bcdDollar;
    image[dollarCell] = bcdBlank;
  }
  if (convention == 1 || convention == 2) {
    image[lastDigit] = _overpunch(digits.last, convention, sign);
  }
  if (edit & _editBlankWhenZero != 0 && digits.every((int d) => d == 0)) {
    // "The field is to be replaced with blanks" ([J 02.05.07]; D3.2):
    // the whole image, its insertion characters included (RT-5).
    image.fillRange(0, image.length, bcdBlank);
  }
  image.forEach(target.write);
}

/// The character of a reserved sign position: a minus for a negative
/// value, and for a positive one a plus under the two plus conventions
/// and a blank under the two minus conventions ([F p. 80]; RT-5).
int _signCharacter(int convention, int sign) => sign == 1
    ? _bcdMinus
    : (convention == 4 || convention == 6 ? _bcdPlus : bcdBlank);

/// The last digit under an overpunch convention: the 11 punch for a
/// negative value, the 12 punch for a positive one under convention 2,
/// and the plain digit under convention 1. Row 0 carries the digit
/// zero, so an overpunched zero is octal 32 or 52 (D0.6).
int _overpunch(int digit, int convention, int sign) =>
    sign == 0 && convention == 1
    ? digit
    : ((sign == 1 ? 2 : 1) << 4) | (digit == 0 ? 10 : digit);

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

  /// TARGET-EDIT-CONTROL and TARGET-CONTROL-WORD, parked by the edited
  /// family head for its terminator ([J 90.02.17]).
  int edit = 0;
  int control = 0;

  /// The digits read or inserted so far, high order first, and their
  /// sign (0 plus, 1 minus).
  final List<int> digits = <int>[];
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
