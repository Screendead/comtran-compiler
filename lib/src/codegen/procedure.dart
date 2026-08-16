/// The procedure text (M4-1 chunks B1 and B2): every word the procedure
/// division generates, sized and placed, and — for the move family —
/// written.
///
/// Chunk B1 laid the address spine: how many words each clause takes and
/// where each one sits. Chunk B2 fills the move family's mnemonics,
/// operands and object words: every shape the MOVE verb reaches, the
/// MOVPAK descriptor prologue, and the base-locator guard pair wherever
/// it fires. Every other family still emits a bare word, and B3 to B6
/// fill them.
/// The sizing rules are the shape catalogue of
/// `test/fixtures/90.05-object-code-notes.md`; each family below names
/// its catalogue section.
///
/// The text continues Location Counter 0 straight on from the
/// transmitted data areas, so a word's location is its position in the
/// stream and needs no forward reference. Three things do need one: an
/// `EQU` prints an equated value in its LOC column, and that value can
/// be a pool address, which follows the whole text, or a procedure
/// address the walk has not reached. The caller therefore runs the
/// generator twice, passing the image the second time, and the
/// generator patches every deferred value after its walk ends (M4-4).
library;

import '../ast/data_ast.dart';
import '../ast/procedure_ast.dart';
import '../chars/char_code.dart';
import '../data/data_map.dart';
import '../data/dictionary.dart';
import '../data/pictorial.dart';
import '../emulator/decode.dart';
import '../emulator/word.dart';
import '../lexer/procedure_lexer.dart';
import '../lexer/token.dart';
import '../parser/parser.dart';
import 'encode.dart';
import 'image.dart';
import 'pool.dart';
import 'text_model.dart';

/// What the procedure division generates.
final class ProcedureText {
  const ProcedureText({
    required this.units,
    required this.words,
    required this.poolWords,
  });

  /// The assembly units, program order.
  final List<AssemblyUnit> units;

  /// Words the text takes on Location Counter 0.
  final int words;

  /// The constant pool's entry count after layout (M4-4).
  final int poolWords;
}

/// Generates the procedure text of [semantics], the first word at
/// [origin].
///
/// [image] is `null` on the measuring pass, when no address past the
/// text is known yet.
ProcedureText generateProcedure(
  SemanticResult semantics, {
  required int origin,
  ProgramImage? image,
}) {
  final text = _Text(semantics, origin: origin, image: image);
  var entry = true;
  for (final ParsedGroup group in semantics.parse.groups) {
    if (group is ParsedProcedureGroup) {
      if (entry) {
        text.label('GN)000'); // The entry word's name (D2.1; M3-8).
        entry = false;
      }
      text.sentences(group.sentences);
    }
  }
  return text.result();
}

/// A refusal of this recovery, not a diagnostic of the program.
///
/// The sample never reaches the refusing site, so no generated shape
/// is attested and none is invented (the notes, section 7). The 1962
/// compiler had code for the shape, so no [J 90.04] message and no
/// severity fits: the refusal rides outside the D10.2 stream, enters
/// no sink and no listing. The driver catches it per job, and a later
/// job still compiles (J 90.04.02's shape; M4-2 as amended).
final class UnrecoveredShape implements Exception {
  UnrecoveredShape(this.shape);

  /// The unattested shape, named for the report.
  final String shape;

  @override
  String toString() => 'unrecovered shape: $shape';
}

/// A rule this chunk has no ground for. The sample never reaches these
/// sites, so no shape is attested and none is invented (CLAUDE.md §11;
/// notes section 7).
Never _unruled(String what) => throw UnrecoveredShape(what);

/// The three outcomes of a skip vector, in slot order ([J 90.02.12]).
enum _Outcome { greater, equal, less }

/// One symbolic address: the text the operand column prints and the
/// value the address field punches.
///
/// Both are thunks because a pool entry has no index until the whole
/// text has run — the pool is not in first-need order, and its address
/// follows the text (M4-4).
final class _Sym {
  const _Sym(this.text, this.value);

  final String Function() text;
  final int Function() value;
}

/// One reference to a data item: the name the listing prints, the
/// address field, and the index register the reference is tagged with.
///
/// An item inside a located record is addressed relative to its record
/// and reached through a base register; every other item carries the
/// absolute address of its transmitted area (M4-9).
typedef _Ref = ({String text, int address, int tag});

/// The emitter: one word at a time, in program order.
final class _Text {
  _Text(this.semantics, {required int origin, this.image})
    : _origin = origin,
      _location = origin,
      _generated = semantics.allocation?.generatedCount ?? 0 {
    for (final ParsedGroup group in semantics.parse.groups) {
      if (group is! ParsedProcedureGroup) {
        continue;
      }
      for (final Sentence sentence in group.sentences) {
        for (final Clause clause in clauseTree(sentence.clauses)) {
          if (clause case DoClause(:final procedure)) {
            _doTargets.add(procedure.text);
          }
          if (clause case GetClause(atEnd: AtEndClause(:final bareName?))) {
            _doTargets.add(bareName.text);
          }
        }
      }
    }
    var bl = 2; // BL)1 is the IOCS label area (M3-11).
    for (final RecordInfo record in semantics.records) {
      if (record.located) {
        _baseLocators[record.item] = bl++;
      }
    }
  }

  final SemanticResult semantics;

  /// The address layout, on the placing pass only.
  final ProgramImage? image;

  final int _origin;
  final List<AssemblyUnit> _units = <AssemblyUnit>[];
  final ConstantPool _pool = ConstantPool();

  /// Deferred LOC values: an `EQU` prints an address the walk has not
  /// reached, or a pool address that follows the whole text. Each entry
  /// patches one unit after the walk ends.
  final List<(int, int Function())> _fixups = <(int, int Function())>[];

  /// Deferred operand text and object words, one entry per written
  /// unit, patched with [_fixups] after the walk ends (M4-4).
  final List<(int, String Function(), int Function())> _text =
      <(int, String Function(), int Function())>[];

  /// Procedure names at least one DO (or bare-name AT END) calls: these
  /// paragraphs carry a return cell (catalogue 4.1 — call-site-driven).
  final Set<String> _doTargets = <String>{};

  /// The base locator serving each located record, `BL)2` on (M4-4).
  final Map<DataItem, int> _baseLocators = <DataItem, int>{};

  /// The index-register cache: which locator each register holds. A
  /// label or a section entry clears the whole cache, a subroutine call
  /// (DO, GET, FILE, OPEN, CLOSE, STOP) clears it, and a MOVPAK
  /// sequence clears register 1 alone — its trailing `AXT n,1` is the
  /// only register write. The two readings of notes question 2 are not
  /// equally viable after all: statement 203's `MASTER RATE` takes no
  /// guard at 00627 across the two MOVPAK sequences of statement 202,
  /// and takes one at 00637 where only a label intervenes, so a full
  /// post-MOVPAK reload contradicts the listing and the register-write
  /// reading is the one implemented.
  final Map<int, int> _registerHolds = <int, int>{};

  /// Registers assigned this statement, in operand order (M4-9).
  final Map<int, int> _statementRegisters = <int, int>{};

  int _location;
  int _generated;

  /// The label of the open DO-called paragraph, closed by a terminal
  /// return at the next labelled sentence (catalogue 4.1).
  bool _openParagraph = false;

  /// Whether a section is open; its END emits the terminal return.
  bool _openSection = false;

  /// Names waiting for the next word. Two of them print one per line,
  /// the word on the last (M4-8).
  List<String> _pending = <String>[];

  // --- The emitter core ---------------------------------------------------

  List<String> _take() {
    final List<String> names = _pending;
    _pending = <String>[];
    for (final name in names) {
      _labelled[name] = _location;
    }
    return names;
  }

  /// Puts [name] on the next word emitted. A label ends the straight
  /// run, so the register cache clears.
  void label(String name) {
    _pending.add(name);
    _registerHolds.clear();
  }

  /// Emits one object word, its columns left to a later chunk.
  void word() {
    final List<String> names = _take(); // Before the location advances.
    _units.add(
      AssemblyUnit(
        operation: '',
        operand: '',
        location: _location++,
        labels: names,
      ),
    );
  }

  /// Emits [count] object words.
  void words(int count) {
    for (var i = 0; i < count; i++) {
      word();
    }
  }

  /// Emits one written object word: [operation] now, the operand text
  /// and the 36-bit word after the walk (M4-4).
  void _emit(
    String operation,
    WordForm form,
    String Function() operand,
    int Function() word,
  ) {
    final List<String> names = _take();
    _text.add((_units.length, operand, word));
    _units.add(
      AssemblyUnit(
        operation: operation,
        operand: '',
        location: _location++,
        labels: names,
        form: form,
      ),
    );
  }

  /// A type-B instruction against [address], tagged with [tag]. A zero
  /// tag prints nothing: the attested `CAL BL)2` against `CAL BL)2,1`.
  void _op(Op op, _Sym address, {int tag = 0}) => _emit(
    mnemonic(op),
    formOf(op),
    () => tag == 0 ? address.text() : '${address.text()},$tag',
    () => typeBWord(op, tag: tag, address: address.value()),
  );

  /// A type-B instruction against [item], guarded by the caller.
  void _opItem(Op op, DataItem item, {int plus = 0}) {
    final _Ref ref = _ref(item, plus: plus);
    _emit(
      mnemonic(op),
      formOf(op),
      () => ref.tag == 0 ? ref.text : '${ref.text},${ref.tag}',
      () => typeBWord(op, tag: ref.tag, address: ref.address),
    );
  }

  /// A shift: the distance rides in the address field and prints
  /// decimal (the attested `ARS 18` against octal `00022`).
  void _shift(Op op, int distance) => _emit(
    mnemonic(op),
    formOf(op),
    () => '$distance',
    () => typeBWord(op, address: distance),
  );

  /// `COM`, whose `+0760` sub-operation rides in the address field and
  /// prints nothing ([J 90.02.02]; the emulator's decision ED-3).
  void _com() => _emit(
    mnemonic(Op.com),
    formOf(Op.com),
    () => '',
    () => typeBWord(Op.com, address: comSubOperation),
  );

  /// `AXT n,1` — the digit count an edited store converts
  /// ([J 90.02.30]).
  void _axt(int count, int register) => _emit(
    mnemonic(Op.axt),
    formOf(Op.axt),
    () => '$count,$register',
    () => typeBWord(Op.axt, tag: register, address: count),
  );

  /// A MOVPAK entry, `TSX SYS)nnn,4` ([J 90.02.15]).
  void _tsx(int sys) => _emit(
    mnemonic(Op.tsx),
    formOf(Op.tsx),
    () => 'SYS)$sys,4',
    () => typeBWord(Op.tsx, tag: 4, address: sys),
  );

  /// A MOVPAK step or fill call, `TXI SYS)nnn,1,count`
  /// ([J 90.02.16]). The decrement prints decimal, as the listing
  /// does at LOC 01146 for the octal `00014`.
  void _txi(int sys, int decrement) => _emit(
    mnemonic(Op.txi),
    formOf(Op.txi),
    () => 'SYS)$sys,1,$decrement',
    () => typeAWord(Op.txi, tag: 1, decrement: decrement, address: sys),
  );

  /// The in-line address word `PZE LOC,,BYTE` ([J 90.02.14]). All 25
  /// attested sites name a fixed location, so the word takes no tag and
  /// the located form has none (catalogue 4.3).
  void _pze(DataItem item) {
    final _Ref ref = _ref(item);
    if (ref.tag != 0) {
      _unruled('an in-line address word for a located item (catalogue 4.3)');
    }
    final int byte = _sem(item).byte;
    _emit(
      'PZE',
      WordForm.prefix,
      () => '${ref.text},,$byte',
      () => pzeWord(decrement: byte, address: ref.address),
    );
  }

  /// An in-line constant word, printed as its twelve octal digits.
  void _oct(int value) =>
      _emit('OCT', WordForm.solid, () => Word36.octal(value), () => value);

  /// `SYS)nnn` — a communication cell or a subroutine entry.
  _Sym _sys(int number) => _Sym(() => 'SYS)$number', () => number);

  /// `CP)+n` — a pool entry, by index and by address.
  _Sym _cp(PoolHandle handle) =>
      _Sym(() => 'CP)+${_layout.indexOf(handle)}', () => _poolAddress(handle));

  /// `BL)n` or `PI)n` — one word of a Location Counter 1 block.
  _Sym _blockWord(StorageBlock block, int number) => _Sym(
    () => '${block.symbol}$number',
    () => image?.symbolAddress(block, number) ?? 0,
  );

  /// Emits an `EQU` line at the head of the machinery block that needs
  /// it, printing [value] in the LOC column and taking no word of its
  /// own (M4-8).
  ///
  /// The line interrupts the stream, so a name still waiting for the
  /// next word prints alone ahead of it, at the location that word will
  /// take: the attested `GN)075` at LOC 00702, which the `GN)088 EQU`
  /// line separates from its `AXT`.
  void equ(String name, int Function() value) {
    if (_pending.isNotEmpty) {
      _units.add(
        AssemblyUnit(
          operation: '',
          operand: '',
          location: _location,
          labels: _take(),
        ),
      );
    }
    _fixups.add((_units.length, value));
    _units.add(AssemblyUnit(operation: 'EQU', operand: '', labels: [name]));
  }

  /// The next later-pass generated name (M4-6 — the sample's GN)084 on).
  String _mint() => 'GN)${(++_generated).toString().padLeft(3, '0')}';

  /// The pool address of [handle], or zero on the measuring pass.
  int _poolAddress(PoolHandle handle) {
    final ProgramImage? layout = image;
    return layout == null ? 0 : layout.poolAddress(_layout.indexOf(handle));
  }

  late final PoolLayout _layout;

  ProcedureText result() {
    _layout = _pool.layout();
    for (final (int index, String Function() operand, int Function() word)
        in _text) {
      final AssemblyUnit unit = _units[index];
      _units[index] = AssemblyUnit(
        operation: unit.operation,
        operand: operand(),
        location: unit.location,
        labels: unit.labels,
        word: word(),
        form: unit.form,
      );
    }
    for (final (int index, int Function() value) in _fixups) {
      final AssemblyUnit unit = _units[index];
      _units[index] = AssemblyUnit(
        operation: unit.operation,
        operand: unit.operand,
        location: value(),
        labels: unit.labels,
        word: unit.word,
        form: unit.form,
      );
    }
    return ProcedureText(
      units: _units,
      words: _location - _origin,
      poolWords: _layout.length,
    );
  }

  // --- Data accessors -----------------------------------------------------

  DataItem? _item(NameReference name) => semantics.dataResolutions[name];

  ItemSemantics _sem(DataItem item) => semantics.semantics[item]!;

  /// The record entry [item] lies under, or `null` outside one.
  DataItem? _recordOf(DataItem item) {
    for (DataItem? each = item; each != null; each = each.parent) {
      if (each.typeCode == DataTypeCode.record) {
        return each;
      }
    }
    return null;
  }

  bool _located(DataItem item) {
    final DataItem? record = _recordOf(item);
    return record != null && _baseLocators.containsKey(record);
  }

  /// The first word of each transmitted area, on Location Counter 0.
  /// The areas run from word zero in declaration order, and the
  /// procedure text follows them (M3-6; M4-4).
  late final Map<DataItem, int> _areaOrigins = () {
    final origins = Map<DataItem, int>.identity();
    var origin = 0;
    for (final AreaInfo area in semantics.areas) {
      origins[area.root] = origin;
      origin += area.extentWords;
    }
    return origins;
  }();

  /// One reference to [item], [plus] words on from its first word.
  ///
  /// A located item is addressed from its record's base register, so its
  /// address is the record-relative word; every other item carries its
  /// area's origin. The `+n` suffix is the attested printed form at
  /// `3)EMPLOYEE.NUMBER+1` (M4-9).
  _Ref _ref(DataItem item, {int plus = 0}) {
    final ItemSemantics sem = _sem(item);
    final String text = plus == 0
        ? _printedName(item)
        : '${_printedName(item)}+$plus';
    final DataItem? record = _recordOf(item);
    final int? locator = record == null ? null : _baseLocators[record];
    if (locator != null) {
      return (text: text, address: sem.word + plus, tag: _registerOf(locator));
    }
    final int? origin = _areaOrigins[sem.spaceRoot];
    if (origin == null) {
      _unruled('a reference to an item with no transmitted area (M4-9)');
    }
    return (text: text, address: origin + sem.word + plus, tag: 0);
  }

  /// The index register holding [locator]. Every located reference is
  /// guarded before it is emitted, so the cache always holds one.
  int _registerOf(int locator) {
    for (final MapEntry<int, int> held in _registerHolds.entries) {
      if (held.value == locator) {
        return held.key;
      }
    }
    throw StateError('BL)$locator is referenced with no register loaded');
  }

  /// The `PI)n` of a subscripted reference to [array].
  ///
  /// The indicator list keys on the array and the written subscript
  /// notation together, and codegen holds no copy of the notation, so
  /// two indicators over one array have no rule here (M3-20; M4-9).
  int _indicator(DataItem array) {
    final numbers = <int>[
      for (var i = 0; i < semantics.positionalIndicators.length; i++)
        if (identical(semantics.positionalIndicators[i].$1, array)) i + 1,
    ];
    if (numbers.length != 1) {
      _unruled('two positional indicators over one array (no sample instance)');
    }
    return numbers.single;
  }

  /// A group moves and compares as an alphameric field (D3.3).
  FieldClass _moveClass(DataItem item) {
    final FieldClass fieldClass = _sem(item).fieldClass;
    return fieldClass == FieldClass.group ? FieldClass.alphameric : fieldClass;
  }

  /// Every attested arithmetic operand, SET target, ADD operand,
  /// numeric-compare operand and DO index is internal decimal; the one
  /// attested non-binary fetch is the edited ADD source of statement
  /// 221 (catalogue 4.7), handled at its own site. Any other class has
  /// no attested arithmetic form and refuses.
  DataItem _decimal(DataItem item) {
    final FieldClass fieldClass = _sem(item).fieldClass;
    if (fieldClass != FieldClass.internalDecimal) {
      _unruled(
        'an arithmetic operand of ${fieldClass.name} (no sample instance)',
      );
    }
    return item;
  }

  // --- The register cache (notes question 2, settled above) ---------------

  /// Emits the guard pair `LAC BL)n,i / TXL SYS)294,i,0` when no
  /// register holds that locator, and records the load. A register
  /// already holding it is reused with no words ([J 90.02.23]).
  void _loadBase(DataItem record) {
    final int locator = _baseLocators[record]!;
    if (_registerHolds.containsValue(locator)) {
      return;
    }
    final int register = _statementRegisters.putIfAbsent(locator, () {
      // The lowest free register, not the lowest unused this statement:
      // statement 208 takes XR2 for `BL)3` at 00772 because the NET
      // sentence left `BL)2` live in XR1.
      for (var candidate = 1; candidate <= 2; candidate++) {
        if (!_registerHolds.containsKey(candidate) &&
            !_statementRegisters.containsValue(candidate)) {
          return candidate;
        }
      }
      // M4-9 assigns XR1 and XR2 and stops; no rule covers a third.
      _unruled('a third base register in one statement (M4-9)');
    });
    _registerHolds[register] = locator;
    _op(Op.lac, _blockWord(StorageBlock.bl, locator), tag: register);
    // The guard itself: `TXL SYS)294,i,0` traps an unset locator
    // ([J 90.02.23]).
    _emit(
      mnemonic(Op.txl),
      formOf(Op.txl),
      () => 'SYS)294,$register,0',
      () => typeAWord(Op.txl, tag: register, address: 294),
    );
  }

  /// The guard for [item] when its record is located.
  void _loadBaseOf(DataItem item) {
    final DataItem? record = _recordOf(item);
    if (record != null && _baseLocators.containsKey(record)) {
      _loadBase(record);
    }
  }

  /// Every MOVPAK sequence ends in an `AXT` that writes index register
  /// 1, so that one register empties (notes question 2). Inside a
  /// CORRESPONDING expansion the kill is deferred to the expansion's
  /// end: statement 221's two-word chain at 01332 reuses the register
  /// across the edit tail at 01331, where statement 220's compare at
  /// 01301 reloads across the same tail at statement distance — the
  /// expander planned its addressing once.
  void _movpakClears() {
    if (_inCorresponding) {
      _killPending = true;
      return;
    }
    _registerHolds.remove(1);
  }

  bool _inCorresponding = false;
  bool _killPending = false;

  void _correspondingUnits(
    List<NameReference> targets,
    List<(DataItem, DataItem)> pairs,
  ) {
    _inCorresponding = true;
    _killPending = false;
    for (final (DataItem source, DataItem target) in _emissionOrder(
      targets,
      pairs,
    )) {
      _moveUnit(source, target);
    }
    _inCorresponding = false;
    if (_killPending) {
      _registerHolds.remove(1);
    }
  }

  /// A subroutine call (DO, GET, FILE, OPEN, CLOSE, STOP) runs code the
  /// generator cannot see, so the whole cache empties.
  void _callClears() => _registerHolds.clear();

  // --- Pool keys (catalogue 5.1, 5.2) -------------------------------------

  /// The name the listing prints for [item]: bare when unique,
  /// `n)NAME` by encounter otherwise ([J 90.02.02]).
  String _printedName(DataItem item) {
    final String name = item.entry.name;
    final List<DictionaryEntry> siblings = semantics.dictionary.named(name);
    final data = <DictionaryEntry>[
      for (final DictionaryEntry each in siblings)
        if (each.item != null) each,
    ];
    if (data.length <= 1) {
      return name;
    }
    for (final each in data) {
      if (identical(each.item, item)) {
        return '${each.encounter})$name';
      }
    }
    return name;
  }

  /// The descriptor key `NAME,,byte` — the printed symbolic operand,
  /// which is what a `PZE` entry keys on (catalogue 5.2).
  PoolHandle _descriptor(DataItem item) =>
      _pool.descriptor('${_printedName(item)},,${_sem(item).byte}');

  /// The MOVPAK source pointer and target pointer ([J 90.02.11]).
  static const int _sourceCell = 132;
  static const int _targetCell = 133;

  /// Emits the descriptor prologue of one memory operand — the words
  /// that set its `SYS)132`/`SYS)133` cell (catalogue 4.3). The located
  /// form's `CAL BL)n` carries no guard and touches no register.
  void _setup(DataItem item, {required bool target, bool subscripted = false}) {
    final _Sym cell = _sys(target ? _targetCell : _sourceCell);
    if (subscripted) {
      _op(Op.ldi, _blockWord(StorageBlock.pi, _indicator(item)));
      _op(Op.sti, cell);
      return;
    }
    if (_located(item)) {
      // A located record never holds a variable-length item: an input
      // record containing one transmits instead (J 02.07.03;
      // J 90.01.01, the binder's record classification), so this
      // descriptor's byte offset is a compile-time constant.
      assert(!_sem(item).variableLength, 'the binder bars this shape');
      final PoolHandle descriptor = _descriptor(item);
      _op(
        Op.cal,
        _blockWord(StorageBlock.bl, _baseLocators[_recordOf(item)!]!),
      );
      _op(Op.acl, _cp(descriptor));
      _op(Op.slw, cell);
      return;
    }
    _op(Op.ldi, _cp(_descriptor(item)));
    _op(Op.sti, cell);
  }

  /// A numeric literal's pool word: the written digits with the point
  /// dropped (catalogue 5.3), and its scale in fraction digits. The
  /// keying rule covers decimal digits only, so any other literal kind
  /// has no attested pool form and refuses. A sign is never in the
  /// token: the parser carries it as [UnaryExpr], and every such path
  /// refuses.
  (int, int) _literalValue(Token literal) {
    if (literal.kind != TokenKind.numericLiteral) {
      final kind = literal.kind == TokenKind.floatingLiteral
          ? 'a floating'
          : 'an alphameric';
      _unruled('$kind literal operand (no sample instance)');
    }
    final String text = literal.text;
    final int point = text.indexOf('.');
    final String digits = text.replaceFirst('.', '');
    return (int.parse(digits), point < 0 ? 0 : text.length - point - 1);
  }

  PoolHandle _numericLiteral(Token literal) {
    final (int value, _) = _literalValue(literal);
    return _pool.literal(
      value,
      card: literal.card.cardNumber,
      column: literal.column,
    );
  }

  bool _alphameric(Token literal) =>
      literal.kind == TokenKind.alphamericLiteral;

  /// An alphameric literal's word: characters materialised at the
  /// target's byte [offset], BCD blanks elsewhere (catalogue 5.3), which
  /// makes the mask insert's shift distance zero by construction.
  PoolHandle _alphamericLiteral(Token literal, {int offset = 0}) {
    final String text = literal.text;
    assert(
      offset + text.length <= 6,
      'the caller guards the word boundary before pooling',
    );
    var word = 0;
    for (var i = 0; i < 6; i++) {
      final int j = i - offset;
      final bool filled = j >= 0 && j < text.length;
      word = (word << 6) | (filled ? bcdFromGlyph(text[j])! : 0x30);
    }
    return _pool.literal(
      word,
      card: literal.card.cardNumber,
      column: literal.column,
    );
  }

  /// The statement stamp's two pool words (M4-14): the statement number
  /// in BCD, and the comma-digits-blanks word under the fitted clause
  /// rule (M4-14 as amended 2026-08-15).
  void _stamp(int statement, int clauseOrdinal) {
    _pool.machineWord(_bcdWord('$statement'.padLeft(6)));
    final String digits = '$clauseOrdinal'.padLeft(2, '0');
    _pool.machineWord(_bcdWord(',$digits   '));
  }

  int _bcdWord(String six) {
    var word = 0;
    for (var i = 0; i < 6; i++) {
      word = (word << 6) | bcdFromGlyph(six[i])!;
    }
    return word;
  }

  /// The clear mask over character positions [from] to [to]: zeros at
  /// the cleared characters, sixes of sevens elsewhere (catalogue 4.5).
  int _clearMask(int from, int to) {
    var word = 0;
    for (var i = 0; i < 6; i++) {
      word = (word << 6) | (i >= from && i <= to ? 0 : 0x3F);
    }
    return word;
  }

  int _extractMask(int from, int to) => _clearMask(from, to) ^ 0xFFFFFFFFF;

  int _pow10(int power) {
    var value = 1;
    for (var i = 0; i < power; i++) {
      value *= 10;
    }
    return value;
  }

  // --- The walk -----------------------------------------------------------

  void sentences(List<Sentence> group) {
    for (final sentence in group) {
      if (semantics.capacityDeletedSentences.contains(sentence)) {
        continue; // Msg 177 deleted the text (M3-20).
      }
      _statementRegisters.clear();
      final ProcedureSentence scan = sentence.scan;
      final String? name = scan.label;
      if (name != null) {
        if (_openParagraph) {
          word(); // The previous paragraph's terminal return.
          _openParagraph = false;
        }
        label(name);
        if (_doTargets.contains(name) && !_beginsSection(sentence)) {
          word(); // The call-site-driven return cell (catalogue 4.1).
          _openParagraph = true;
        }
      }
      _statement = _statementNumberOf(scan);
      _ordinals = _clauseOrdinals(sentence.clauses);
      sentence.clauses.forEach(_clause);
    }
  }

  bool _beginsSection(Sentence sentence) =>
      sentence.clauses.any((Clause clause) => clause is BeginSectionClause);

  int _statement = 0;
  Map<Clause, int> _ordinals = const <Clause, int>{};

  int _statementNumberOf(ProcedureSentence scan) {
    final String? number = semantics
        .parse
        .frontEnd
        .statementNumberByCard[scan.cards.first.cardNumber];
    return number == null ? 0 : int.parse(number.split(',').first);
  }

  /// The fitted clause-ordinal rule (M4-14 as amended 2026-08-15):
  /// zero-based, each target of a multi-target MOVE its own clause,
  /// `OPEN ALL FILES` not counted, `CLOSE ALL FILES` counted.
  Map<Clause, int> _clauseOrdinals(List<Clause> clauses) {
    final ordinals = <Clause, int>{};
    var next = 0;
    for (final Clause clause in clauseTree(clauses)) {
      if (clause case OpenClause(allFiles: true)) {
        continue;
      }
      ordinals[clause] = next;
      next += clause is MoveClause ? clause.targets.length : 1;
    }
    return ordinals;
  }

  // --- Clause dispatch ----------------------------------------------------

  void _clause(Clause clause) {
    switch (clause) {
      case CallClause() || NoteClause() || EnterClause():
        break; // No object word (F p. 59; J 02.04.02.01).
      case BeginSectionClause():
        _openSection = true;
        word(); // Every section carries a return cell (catalogue 4.1).
      case EndClause():
        _endClause(clause);
      case OpenClause(:final allFiles, :final files):
        words(allFiles ? 2 : 2 * files.length); // [J 90.02.13].
        _callClears();
      case CloseClause(:final allFiles, :final files):
        words(allFiles ? 2 : 2 * files.length); // [J 90.02.14].
        _callClears();
      case StopClause(:final run):
        _stop(clause, run: run);
      case GoToClause():
        _goTo(clause);
      case DoClause():
        _do(clause);
      case GetClause():
        _get(clause);
      case FileClause():
        _file(clause);
      case MoveClause():
        _move(clause);
      case SetClause():
        _set(clause);
      case SetConditionClause():
        _unruled('SET of a condition name');
      case AddClause():
        _add(clause);
      case IfClause():
        _if(clause);
      case DisplayClause():
        _unruled('DISPLAY ([J 90.01.01])');
      case DeferredVerbClause():
        break; // Diagnosed at parse time; no text.
    }
  }

  void _endClause(EndClause clause) {
    final List<String>? names = semantics.allocation?.clauseNames[clause];
    if (names != null) {
      label(names.single); // GN)077, GN)078, GN)083 (M3-8).
    }
    if (_openSection || _openParagraph) {
      word(); // The terminal return (catalogue 4.1).
      _openSection = false;
      _openParagraph = false;
    }
  }

  // --- The program frame (catalogue 4.1) ----------------------------------

  void _stop(StopClause clause, {required bool run}) {
    if (!run) {
      // STOP n: the SYS)178 call alone, no close-all and no monitor
      // transfer (M4-14; D2.7). SYS)178's parameters carry the
      // statement stamp, so the pair pools here too (M4-14).
      _stamp(_statement, _ordinals[clause] ?? 0);
      words(3);
      _callClears();
      return;
    }
    _stamp(_statement, _ordinals[clause] ?? 0);
    _pool
      ..machineWord(_bcdWord(' STOP '))
      ..machineWord(_bcdWord(' RUN  '));
    words(6); // TSX SYS)178 / two PZE / TSX SYS)177 / PZE / TXI IOC)40.
    _callClears();
  }

  void _goTo(GoToClause clause) {
    if (clause.index != null) {
      _unruled('the assigned GO TO (M4-12; no sample instance)');
    }
    for (final GoToTarget target in clause.targets) {
      final CondExpr? condition = target.when;
      if (condition == null) {
        word(); // The TRA.
      } else {
        // The target's TRA is the true slot of the vector itself.
        _compare(condition, trueFalls: false, falseFalls: true);
      }
    }
  }

  void _do(DoClause clause) {
    if (clause.exactlyTimes != null ||
        clause.usingArguments.isNotEmpty ||
        clause.givingResults.isNotEmpty) {
      _unruled('DO EXACTLY / USING / GIVING (notes section 7)');
    }
    if (clause.indices.isEmpty) {
      words(3); // AXT *+3,7 / SXA cell,4 / TRA proc+1.
      _callClears();
      return;
    }
    _doFor(clause);
  }

  /// DO FOR (catalogue 4.1): 11 + 5·M words, M the positional
  /// indicators the loop index drives; a five-name later-pass run,
  /// binding the body-entry EQU, the increment block, and the
  /// table-base EQU (M4-6, the fitted grouping).
  void _doFor(DoClause clause) {
    if (clause.indices.length > 1) {
      _unruled('a multi-index DO (notes section 7)');
    }
    final DoIndex index = clause.indices.single;
    final DataItem? indexItem = _item(index.index);
    if (indexItem != null) {
      _decimal(indexItem);
    }
    final driven = <(DataItem, String)>[
      for (final (DataItem, String) each in semantics.positionalIndicators)
        if (each.$2 == index.index.text) each,
    ];
    final int m = driven.length;
    for (final bound in <ArithExpr>[index.from, index.by, index.to]) {
      if (bound case LiteralOperand(:final literal)) {
        _numericLiteral(literal);
      } else {
        // A field-name or signed bound is legal (F pp. 50-51; D10.7)
        // but the sample's bounds are all plain literals, so neither
        // prologue form is attested.
        _unruled('a DO FOR bound of ${bound.runtimeType} (no sample instance)');
      }
    }
    for (final (DataItem item, _) in driven) {
      _tableStride(item);
      _pool.base('${_printedName(item)}+0');
    }
    _generated += 1; // The first name of the run is never bound (M4-6).
    final String bodyEntry = _mint();
    final String increment = _mint();
    _generated += 1; // The fourth is never bound either (M4-6).
    final String tableBase = _mint();
    final PoolHandle base = _pool.base(_tableBaseKey(driven));
    equ(tableBase, () => _poolAddress(base));
    words(4 + 2 * m); // The prologue, to its transfer into the body.
    equ(bodyEntry, () => _procedureEntry(clause.procedure) + 1);
    word(); // The transfer the EQU line precedes (the attested 00710).
    label(increment);
    words(6 + 3 * m); // The increment block.
    _callClears();
  }

  String _tableBaseKey(List<(DataItem, String)> driven) => driven.isEmpty
      ? _unruled('a DO FOR driving no indicator')
      : '${_printedName(driven.first.$1)}+0';

  /// The stride: the repeated ancestor's element words (catalogue 5.3,
  /// the STR entry). A positional indicator names the referenced field,
  /// and the repetition can sit on an enclosing group — `RATE` under
  /// the twelve-element `TABLE.ITEM`.
  int _strideWords(DataItem table) {
    for (DataItem? each = table; each != null; each = each.parent) {
      final ItemSemantics sem = _sem(each);
      if (sem.quantity > 1) {
        return sem.strideChars ~/ 6;
      }
    }
    return _unruled('a positional indicator with no repeated ancestor');
  }

  PoolHandle _tableStride(DataItem table) => _pool.stride(_strideWords(table));

  /// The object entry word of the procedure [name] labels — the return
  /// cell, which `TRA proc+1` skips.
  int _procedureEntry(NameReference name) => _labelled[name.text] ?? 0;

  /// Where each label landed. Filled as the walk binds names, read only
  /// by the post-walk fixups, so a forward reference resolves on both
  /// passes.
  final Map<String, int> _labelled = <String, int>{};

  // --- Input and output (catalogue 4.2) -----------------------------------

  void _get(GetClause clause) {
    _stamp(_statement, _ordinals[clause] ?? 0);
    final AtEndClause? atEnd = clause.atEnd;
    words(5); // Stamp, TSX IOC)8, two PZE, the buffer descriptor.
    if (atEnd == null) {
      _callClears();
      return; // E = 0: SYS)265 rides in the fourth word ([J 90.02.29]).
    }
    final List<String> names =
        semantics.allocation?.clauseNames[clause] ?? const <String>[];
    word(); // The TRA over the block.
    if (names.isNotEmpty) {
      label(names.first);
    }
    if (atEnd.bareName != null) {
      words(3); // The plain-DO triple, unchanged.
    } else if (atEnd.statement != null) {
      _clause(atEnd.statement!);
    }
    _callClears();
    if (names.length > 1) {
      label(names[1]); // The join, on the resume word.
    }
  }

  void _file(FileClause clause) {
    // A FILE's record reference resolves through the environment binder,
    // not the data resolver, so the roster is matched by name (M3-11).
    DataItem? record;
    for (final RecordInfo each in semantics.records) {
      if (each.name == clause.record.text) {
        record = each.item;
        break;
      }
    }
    if (record != null && _baseLocators.containsKey(record)) {
      final String patched = _mint();
      _generated += 1; // The pair's second name is never bound (M4-6).
      words(2); // LXA BL)n,4 / SXA GN)a,4.
      words(2); // TSX IOC)9,4 / PZE file.
      label(patched);
      word(); // The IOST word the pair patches, GN)a on it.
    } else {
      words(3); // TSX IOC)9,4 / PZE file / IOST record,,len.
    }
    _callClears();
  }

  // --- Moves (catalogue 4.3 to 4.6) ---------------------------------------

  void _move(MoveClause clause) {
    if (clause.corresponding) {
      _correspondingUnits(
        clause.targets,
        semantics.correspondingPairs[clause] ?? const [],
      );
      return;
    }
    for (final NameReference target in clause.targets) {
      switch (clause.source) {
        case FigurativeOperand(:final Token word):
          _figurativeFill(target, word);
        case LiteralOperand(:final Token literal) when _alphameric(literal):
          _literalInsert(_item(target)!, literal);
        case NameOperand(:final NameReference name):
          _moveUnit(
            _item(name)!,
            _item(target)!,
            sourceSubscripted: name.subscripts.isNotEmpty,
            targetSubscripted: target.subscripts.isNotEmpty,
          );
        default:
          _unruled('a MOVE of a numeric literal (no sample instance)');
      }
      _subscriptRecomputation(target);
    }
  }

  /// The matched pairs in emission order. Two rules, both from the
  /// sample.
  ///
  /// A pair matched at a receiver's own level emits before every pair
  /// matched inside a matched group. Statement 221 attests it — `DATE`
  /// and `BONDENOMINATION` emit ahead of `DAT`'s `EMPLOYEE.NUMBER` and
  /// `NAME` — and it is load-bearing there: the `NAME` pair dispatches
  /// through MOVPAK, and any pair after a dispatch would re-guard.
  ///
  /// Within one receiver the matched groups emit in reverse description
  /// order. Statement 208 attests it: `PAYRECORD DATE` fills 01006 to
  /// 01025 ahead of `PAYRECORD EMPLOYEE.NUMBER` at 01026, though
  /// `EMPLOYEE.NUMBER` is described first. The receivers themselves
  /// keep the clause's order (M4-9).
  List<(DataItem, DataItem)> _emissionOrder(
    List<NameReference> targets,
    List<(DataItem, DataItem)> pairs,
  ) {
    int depth(DataItem item) {
      var steps = 0;
      for (
        DataItem? each = item.parent;
        each != null && each.typeCode != DataTypeCode.record;
        each = each.parent
      ) {
        steps++;
      }
      return steps;
    }

    final receiver = <int>[
      for (final (_, DataItem target) in pairs) _receiverIndex(targets, target),
    ];
    // A matched group's pairs are consecutive and share a source
    // parent, so the run's first index names the group.
    final group = List<int>.filled(pairs.length, 0);
    for (var i = 0; i < pairs.length; i++) {
      group[i] =
          i > 0 &&
              receiver[i] == receiver[i - 1] &&
              identical(pairs[i].$1.parent, pairs[i - 1].$1.parent)
          ? group[i - 1]
          : i;
    }

    final List<int> order = [for (var i = 0; i < pairs.length; i++) i]
      ..sort((a, b) {
        final int byDepth = depth(pairs[a].$2).compareTo(depth(pairs[b].$2));
        if (byDepth != 0) {
          return byDepth;
        }
        if (receiver[a] != receiver[b]) {
          return receiver[a].compareTo(receiver[b]);
        }
        return group[a] != group[b]
            ? group[b].compareTo(group[a])
            : a.compareTo(b);
      });
    return [for (final int i in order) pairs[i]];
  }

  /// Which of [targets] holds [item].
  int _receiverIndex(List<NameReference> targets, DataItem item) {
    for (var i = 0; i < targets.length; i++) {
      final DataItem? receiver = _item(targets[i]);
      if (receiver != null &&
          ancestorsOf(item).any((DataItem each) => identical(each, receiver))) {
        return i;
      }
    }
    // The matcher builds each pair under one receiver, so a pair under
    // none would sort by an index that names no receiver at all.
    _unruled('a matched pair outside every receiver (M4-9)');
  }

  /// One source-to-target unit, selected by the two field classes
  /// ([J 90.02.15] to [J 90.02.19], [J 90.02.30]).
  void _moveUnit(
    DataItem source,
    DataItem target, {
    bool sourceSubscripted = false,
    bool targetSubscripted = false,
  }) {
    final FieldClass from = _moveClass(source);
    final FieldClass to = _moveClass(target);
    if (from == FieldClass.alphameric && to == FieldClass.alphameric) {
      if (sourceSubscripted || targetSubscripted) {
        _unruled('a subscripted alphameric move (notes section 7)');
      }
      _alphamericMove(source, target);
      return;
    }
    switch ((from, to)) {
      case (FieldClass.internalDecimal, FieldClass.edited):
        _editedStore(source, target, subscripted: sourceSubscripted);
      case (FieldClass.internalDecimal, FieldClass.internalDecimal):
        _internalMove(source, target, sourceSubscripted: sourceSubscripted);
      case (FieldClass.externalDecimal, FieldClass.edited) ||
          (FieldClass.edited, FieldClass.edited):
        _editRun(
          source,
          target,
          fromEdited: from == FieldClass.edited,
          sourceSubscripted: sourceSubscripted,
          targetSubscripted: targetSubscripted,
        );
      case (FieldClass.externalDecimal, FieldClass.internalDecimal):
        _setup(source, subscripted: sourceSubscripted, target: false);
        _tsx(182);
        _txi(184, _sem(source).digits); // The complete call ([J 90.02.16]).
        _loadBaseOf(target);
        _opItem(Op.sto, target);
        _movpakClears();
      default:
        _unruled('a move of ${from.name} to ${to.name} (notes section 7)');
    }
  }

  /// The memory-to-edited move: the two pointers, the MOVPAK entry, the
  /// head with its control word, one step per stretch of target digits,
  /// and the terminator ([J 90.02.16] to [J 90.02.19]; catalogue 4.6).
  void _editRun(
    DataItem source,
    DataItem target, {
    required bool fromEdited,
    required bool sourceSubscripted,
    required bool targetSubscripted,
  }) {
    _setup(target, subscripted: targetSubscripted, target: true);
    _setup(source, subscripted: sourceSubscripted, target: false);
    _tsx(182);
    _txi(fromEdited ? 190 : 185, _editControl(target));
    _oct(_controlWord(target));
    _editSteps(source, target, fromEdited: fromEdited);
    _txi(fromEdited ? 226 : 225, _sem(target).digits);
    _movpakClears();
  }

  /// The steps between the head and the terminator: leading zeros, the
  /// move itself, then trailing zeros ([J 90.02.17]).
  ///
  /// A source wider than the target on either side needs the overflow
  /// test and the bypass steps, and no site emits either, so the two
  /// step numbers the manual offers cannot be told apart (catalogue 4.6;
  /// M4-2 as amended).
  void _editSteps(
    DataItem source,
    DataItem target, {
    required bool fromEdited,
  }) {
    final ItemSemantics s = _sem(source);
    final ItemSemantics t = _sem(target);
    final int sourceInteger = s.digits - s.fractionDigits;
    final int targetInteger = t.digits - t.fractionDigits;
    if (sourceInteger > targetInteger || s.fractionDigits > t.fractionDigits) {
      _unruled('an edit run that bypasses source digits (no sample instance)');
    }
    if (targetInteger > sourceInteger) {
      _txi(fromEdited ? 214 : 212, targetInteger - sourceInteger);
    }
    _txi(fromEdited ? 198 : 193, s.digits);
    if (t.fractionDigits > s.fractionDigits) {
      _txi(fromEdited ? 216 : 211, t.fractionDigits - s.fractionDigits);
    }
  }

  /// The TARGET-EDIT-CONTROL bits of [target] ([J 90.02.17] Note 1).
  int _editControl(DataItem target) {
    final Pictorial shape = _editedShape(target);
    return (shape.hasAsterisk ? 0x01 : 0) |
        (shape.hasComma ? 0x02 : 0) |
        (shape.hasPoint ? 0x04 : 0) |
        (shape.hasDollar ? 0x08 : 0) |
        (target.blankWhenZero ? 0x10 : 0);
  }

  /// The TARGET-CONTROL-WORD of [target] ([J 90.02.17] Note 2).
  int _controlWord(DataItem target) {
    final Pictorial shape = _editedShape(target);
    if (shape.digitsBeforeComma > 7) {
      // The prefix is three bits wide, so a longer group ahead of the
      // first comma has no word to punch.
      _unruled('an edited field with eight digits before its first comma');
    }
    return (shape.digitsBeforeComma << 33) |
        (shape.digitsBeforePoint << 18) |
        (_signCode(shape.sign) << 15) |
        shape.leadingProtected;
  }

  Pictorial _editedShape(DataItem target) =>
      _sem(target).shape ??
      _unruled('an edited target with no pictorial (M4-9)');

  /// TARGET-SIGN-CONVENTION, the control word's tag ([J 90.02.17]
  /// Note 2's seven values).
  int _signCode(SignConvention sign) => switch (sign) {
    SignConvention.none => 0,
    SignConvention.overpunchMinus => 1,
    SignConvention.overpunchPlus => 2,
    SignConvention.minusTrailing => 3,
    SignConvention.plusTrailing => 4,
    SignConvention.minusLeading => 5,
    SignConvention.plusLeading => 6,
  };

  /// The register-source edited store (catalogue 4.6): the 25 `SYS)180`
  /// sites, a load and the constant five-word call, with the digit-split
  /// divide when the source represents more digits than the target.
  void _editedStore(
    DataItem source,
    DataItem target, {
    bool subscripted = false,
  }) {
    if (subscripted) {
      _unruled('a subscripted edited-store source (no sample instance)');
    }
    _loadBaseOf(source);
    _opItem(Op.cla, source);
    final ItemSemantics s = _sem(source);
    final ItemSemantics t = _sem(target);
    if (s.digits > t.digits) {
      // The split divisor is 10 to the target's digit count — the one
      // value all three attested sites share, `CP)+24`.
      final PoolHandle divisor = _pool.machineWord(_pow10(t.digits));
      _shift(Op.lrs, 35);
      _op(Op.dvp, _cp(divisor));
    }
    _tsx(180);
    _pze(target);
    final int control = _editControl(target);
    if (control == 0) {
      // The one site whose edit control computes to zero punches a real
      // transfer where every other punches the step's `TXI`, and prints
      // the three-field operand either way (notes 6.2 item 15, LOC
      // 01327).
      _emit(
        mnemonic(Op.tra),
        formOf(Op.tra),
        () => 'SYS)267,0,0',
        () => typeBWord(Op.tra, address: 267),
      );
    } else {
      _txi(267, control);
    }
    _oct(_controlWord(target));
    _axt(t.digits, 1);
    _movpakClears();
  }

  /// The internal-to-internal move: two words at its one site, equal
  /// scale and single precision (catalogue 4.6).
  void _internalMove(
    DataItem source,
    DataItem target, {
    bool sourceSubscripted = false,
  }) {
    if (sourceSubscripted) {
      _unruled('a subscripted internal-decimal move (no sample instance)');
    }
    final ItemSemantics s = _sem(source);
    final ItemSemantics t = _sem(target);
    if (s.fractionDigits != t.fractionDigits ||
        s.doublePrecision ||
        t.doublePrecision) {
      _unruled('an internal-decimal move off its trigger (catalogue 4.6)');
    }
    _loadBaseOf(source);
    _opItem(Op.cla, source);
    _loadBaseOf(target);
    _opItem(Op.sto, target);
  }

  /// A store into a subscript variable recomputes every positional
  /// indicator it drives, five words and a two-name later-pass run
  /// each, in reverse first-reference order — fitted to the one site,
  /// where `RETPREM-2` takes `CP)+38` ahead of `INSPREM-2` though
  /// INSPREM is declared and referenced first (M4-6).
  void _subscriptRecomputation(NameReference target) {
    final driven = <DataItem>[
      for (final (DataItem item, String notation)
          in semantics.positionalIndicators.reversed)
        if (notation == target.text) item,
    ];
    // Both EQU lines print ahead of the update blocks — the attested
    // 01742 and 01743, back to back before LOC 01421.
    for (final table in driven) {
      _tableStride(table);
      final PoolHandle base = _pool.base(
        '${_printedName(table)}-${_strideWords(table)}',
      );
      final String bound = _mint();
      _generated += 1; // The pair's second name is never bound (M4-6).
      equ(bound, () => _poolAddress(base));
    }
    words(5 * driven.length);
  }

  // --- The figurative and literal fills (catalogue 4.4, 4.5) --------------

  bool _highOrLow(Token figurative) =>
      figurative.text.startsWith('HIGH') || figurative.text.startsWith('LOW');

  /// One fill unit per target: the descriptor prologue, `TSX SYS)182,4`,
  /// and the fill call — one `TXI`, plus the in-line `OCT` word that
  /// `SYS)245` alone carries ([J 90.02.25], [J 90.02.26]).
  void _figurativeFill(NameReference target, Token figurative) {
    if (target.subscripts.isNotEmpty) {
      _unruled('a subscripted figurative target (notes section 7)');
    }
    final DataItem item = _item(target)!;
    _setup(item, target: true);
    _tsx(182);
    // The count is the target's storage extent, not its digit count
    // (notes 6.1 item 22).
    final int extent = _sem(item).storageChars;
    if (_highOrLow(figurative)) {
      _txi(245, extent);
      _oct(_fillWord(figurative));
      _movpakClears();
      return;
    }
    if (_zero(figurative)) {
      _txi(244, extent);
    } else if (figurative.text.startsWith('BLANK')) {
      _txi(243, extent);
    } else {
      _unruled('a fill of ${figurative.text} (notes section 7)');
    }
    _movpakClears();
  }

  /// The six characters `SYS)245` inserts ([J 90.02.26]). HIGH.VALUE in
  /// the native sequence is the attested `747474747474`; the other
  /// three fill words of the collating table have no site and no rule
  /// reproduces them (notes 6.1 item 20).
  int _fillWord(Token figurative) {
    if (!figurative.text.startsWith('HIGH')) {
      _unruled('the LOW.VALUE fill word (notes 6.1 item 20)');
    }
    return _highValueWord;
  }

  /// The literal insert: the mask insert with a pool cell for a source,
  /// in line, no dispatch (catalogue 4.5).
  void _literalInsert(DataItem target, Token literal) {
    final ItemSemantics t = _sem(target);
    final int length = literal.text.length;
    if (t.byte + length > 6) {
      _unruled('an in-line literal past one word (notes section 7)');
    }
    final PoolHandle clear = _pool.machineWord(
      _clearMask(t.byte, t.byte + length - 1),
    );
    final PoolHandle word = _alphamericLiteral(literal, offset: t.byte);
    _op(Op.cal, _cp(clear));
    _loadBaseOf(target);
    _opItem(Op.ans, target);
    _com();
    _op(Op.ana, _cp(word));
    _opItem(Op.ors, target);
  }

  /// The in-line boundary (catalogue 4.5): equal storage lengths, the
  /// source wholly inside one word, the target inside two. Everything
  /// else dispatches.
  void _alphamericMove(DataItem source, DataItem target) {
    final ItemSemantics s = _sem(source);
    final ItemSemantics t = _sem(target);
    final int length = s.storageChars;
    if (length != t.storageChars ||
        s.byte + length > 6 ||
        t.byte + length > 12) {
      _dispatch(source, target);
      return;
    }
    final int sB = s.byte;
    final int tB = t.byte;
    if (length % 6 == 0 && sB == 0 && tB == 0) {
      // The gate above caps the source inside one word, so the
      // whole-word move is always exactly one: CAL / SLW. The
      // multi-word form has no site (notes section 7).
      _loadBaseOf(source);
      _opItem(Op.cal, source);
      _loadBaseOf(target);
      _opItem(Op.slw, target);
    } else if (tB + length <= 6) {
      if (sB == tB) {
        _maskInsert(source, target, length);
      } else if (tB == 0 && sB + length == 6) {
        _accumulatorChain(source, target, length);
      } else if (tB + length == 6) {
        _mqChain(source, target);
      } else if (tB > 0) {
        _shiftedMaskInsert(source, target, length);
      } else {
        _unruled('an in-line move outside the four triggers (notes 4.5)');
      }
    } else {
      _twoWordChain(source, target, length);
    }
  }

  /// The mask insert: clear the target's characters, complement the
  /// mask to select them, and OR the source's in (catalogue 4.5).
  ///
  /// The source is the field itself, which is an addition to M4-9 —
  /// attested twice and stated nowhere (notes 6.2 item 13).
  void _maskInsert(DataItem source, DataItem target, int length) {
    final int tB = _sem(target).byte;
    final PoolHandle clear = _pool.machineWord(_clearMask(tB, tB + length - 1));
    _op(Op.cal, _cp(clear));
    _loadBaseOf(target);
    _opItem(Op.ans, target);
    _com();
    _loadBaseOf(source);
    _opItem(Op.ana, source);
    _opItem(Op.ors, target);
  }

  /// The shifted mask insert: the mask insert with the source aligned
  /// to the target's byte position first, which costs a second pool
  /// word because `COM` no longer makes the select mask (catalogue 4.5).
  void _shiftedMaskInsert(DataItem source, DataItem target, int length) {
    final int sB = _sem(source).byte;
    final int tB = _sem(target).byte;
    final PoolHandle clear = _pool.machineWord(_clearMask(tB, tB + length - 1));
    final PoolHandle extract = _pool.machineWord(
      _extractMask(tB, tB + length - 1),
    );
    _op(Op.cal, _cp(clear));
    _loadBaseOf(target);
    _opItem(Op.ans, target);
    _loadBaseOf(source);
    _opItem(Op.cal, source);
    final int distance = 6 * (tB - sB);
    _shift(distance > 0 ? Op.ars : Op.als, distance.abs());
    _op(Op.ana, _cp(extract));
    _opItem(Op.ors, target);
  }

  /// The accumulator shift chain: the target's kept characters ride in
  /// the MQ across the source load, then shift back (catalogue 4.5).
  void _accumulatorChain(DataItem source, DataItem target, int length) {
    final int kept = 6 * (6 - length);
    _loadBaseOf(target);
    _opItem(Op.cal, target);
    _shift(Op.lgr, kept);
    _loadBaseOf(source);
    _opItem(Op.cal, source);
    _shift(Op.lgl, kept);
    _opItem(Op.slw, target);
  }

  /// The MQ shift chain: the target's characters run low in the word,
  /// so the assembly happens in the MQ and the kept characters ride in
  /// the accumulator (catalogue 4.5).
  void _mqChain(DataItem source, DataItem target) {
    final int kept = 6 * _sem(target).byte;
    _loadBaseOf(target);
    _opItem(Op.ldq, target);
    _shift(Op.lgl, kept);
    _loadBaseOf(source);
    _opItem(Op.ldq, source);
    _shift(Op.rql, 6 * _sem(source).byte);
    _shift(Op.lgr, kept);
    _opItem(Op.stq, target);
  }

  /// The two-word chain: the target spans a word boundary, so each of
  /// its words is rebuilt in turn (catalogue 4.5). The six shift
  /// distances follow from the two byte positions and the length, and
  /// three sites with three distinct geometries confirm them.
  void _twoWordChain(DataItem source, DataItem target, int length) {
    final int head = 6 - _sem(target).byte; // Characters in the first word.
    final int tail = length - head;
    _loadBaseOf(target);
    _opItem(Op.cal, target);
    _loadBaseOf(source);
    _opItem(Op.ldq, source);
    _shift(Op.rql, 6 * _sem(source).byte);
    _shift(Op.ars, 6 * head);
    _shift(Op.lgl, 6 * head);
    _opItem(Op.slw, target);
    _shift(Op.lgl, 6 * tail);
    _opItem(Op.ldq, target, plus: 1);
    _shift(Op.rql, 6 * tail);
    _shift(Op.lgl, 6 * (6 - tail));
    _opItem(Op.slw, target, plus: 1);
  }

  /// The MOVPAK dispatch, target cell before source cell, then the
  /// mover run of notes section 3.3: `SYS)239` alone on equal storage
  /// lengths, `SYS)240` then `SYS)241` on a shorter source — an
  /// observation over five sites, not a derivation, and the notes say
  /// not to promote it silently (M4-9 as amended).
  void _dispatch(DataItem source, DataItem target) {
    _setup(target, target: true);
    _setup(source, target: false);
    _tsx(182);
    final int from = _sem(source).storageChars;
    final int to = _sem(target).storageChars;
    if (from == to) {
      _txi(239, from);
    } else if (from < to) {
      _txi(240, from);
      _txi(241, to - from);
    } else {
      _unruled('an alphameric mover with the longer source (notes 3.3)');
    }
    _movpakClears();
  }

  // --- SET, ADD and the chains (catalogue 4.7) ----------------------------

  void _set(SetClause clause) {
    if (clause.onOverflow != null) {
      _unruled('ON OVERFLOW (notes section 7)');
    }
    if (clause.targets.length != 1) {
      _unruled('SET with a target list (no sample instance)');
    }
    final NameReference target = clause.targets.single;
    if (clause.value case FigurativeOperand(:final word)) {
      _figurativeFill(target, word);
      return;
    }
    final int scale = _chain(clause.value);
    _store(target, scale, truncated: clause.truncated);
  }

  void _add(AddClause clause) {
    if (clause.truncated || clause.onOverflow != null) {
      _unruled('ADD TRUNCATED / ON OVERFLOW (notes section 7)');
    }
    if (clause.corresponding) {
      final List<(DataItem, DataItem)> pairs =
          semantics.correspondingPairs[clause] ?? const [];
      for (final (DataItem source, DataItem target) in pairs) {
        _addPair(source, target);
      }
      return;
    }
    if (clause.source case NameOperand(:final name)) {
      if (name.subscripts.isNotEmpty) {
        _unruled('a subscripted ADD source (no sample instance)');
      }
      final DataItem source = _item(name)!;
      if (_sem(source).fieldClass == FieldClass.edited) {
        // The non-binary operand fetch: the register convert of
        // catalogue 4.6, plus one word to park (catalogue 4.7).
        _setup(source, target: false);
        words(1 + 3);
        word(); // The park.
        _movpakClears();
        for (final NameReference target in clause.targets) {
          _addBody(_item(target)!);
        }
        return;
      }
      for (final NameReference target in clause.targets) {
        _addPair(source, _item(target)!);
      }
      return;
    }
    _unruled('an ADD of a literal (no sample instance)');
  }

  /// One ADD unit: `CLA source / ADD target / STO target` with the
  /// guards the operands force. Every attested pair has equal scale;
  /// the store tail on an ADD has no site (notes section 7).
  void _addPair(DataItem source, DataItem target) {
    if (_sem(source).fractionDigits != _sem(target).fractionDigits) {
      _unruled('an ADD pair of unequal scales (notes section 7)');
    }
    _loadBaseOf(_decimal(source));
    _addBody(target);
  }

  void _addBody(DataItem target) {
    _loadBaseOf(_decimal(target));
    words(3);
  }

  /// Emits the chain of [value] and returns the accumulator's scale.
  int _chain(ArithExpr value) {
    final List<ArithExpr> terms = _additiveTerms(value);
    if (terms.length == 1) {
      final ArithExpr term = terms.single;
      switch (term) {
        case NameOperand(:final name):
          if (name.subscripts.isNotEmpty) {
            _unruled('a subscripted chain operand (no sample instance)');
          }
          _loadBaseOf(_decimal(_item(name)!));
          word(); // CLA.
          return _naturalScale(term);
        case LiteralOperand(:final literal):
          _numericLiteral(literal);
          word(); // CLA CP)+nn — the one-term chain (notes 3.3).
          return _naturalScale(term);
        case BinaryExpr():
          return _product(term);
        default:
          _unruled('a chain of ${term.runtimeType} (no sample instance)');
      }
    }
    var chainScale = 0;
    for (final term in terms) {
      final int scale = _naturalScale(term);
      chainScale = scale > chainScale ? scale : chainScale;
    }
    // One entry per term: the item whose base register that term's own
    // word must load, `null` where the assembly reads a parked value or
    // a pool word. The NET sentence pins the placement: the guard for
    // `1)BONDEDUCTION` sits at 00727, between the fifth `SUB` and its
    // own, not ahead of the `CLA` at 00722.
    final fetched = <DataItem?>[];
    for (final term in terms) {
      // The sample's chains never subscript a term, so the multi-term
      // arms refuse one exactly as the single-term arm above does.
      if (term case NameOperand(:final name) when name.subscripts.isNotEmpty) {
        _unruled('a subscripted chain operand (no sample instance)');
      }
      final int deficit = chainScale - _naturalScale(term);
      fetched.add(
        term is NameOperand && deficit == 0
            ? _decimal(_item(term.name)!)
            : null,
      );
      switch (term) {
        case NameOperand() when deficit == 0:
          break; // Fetched in place, guarded at its own word below.
        case LiteralOperand(:final literal) when deficit == 0:
          _numericLiteral(literal);
        case NameOperand() || LiteralOperand():
          // The scale alignment: a run-time multiply against a separate
          // pool word, never a folded literal (catalogue 4.7), parked.
          if (term case LiteralOperand(:final literal)) {
            _numericLiteral(literal);
          } else if (term case NameOperand(:final name)) {
            _loadBaseOf(_decimal(_item(name)!));
          }
          _pool.machineWord(_pow10(deficit));
          words(3);
        case BinaryExpr() when _additive(term):
          final int scale = _chain(term); // The sub-chain, then its park.
          if (chainScale > scale) {
            _pool.machineWord(_pow10(chainScale - scale));
            word();
          }
          word();
        case BinaryExpr():
          _product(term); // The product, its alignment, and its park.
          if (deficit > 0) {
            _pool.machineWord(_pow10(deficit));
            word();
          }
          word();
        default:
          _unruled('a chain of ${term.runtimeType} (no sample instance)');
      }
    }
    // The assembly: one CLA, then ADD or SUB each.
    for (final item in fetched) {
      if (item != null) {
        _loadBaseOf(item);
      }
      word();
    }
    return chainScale;
  }

  bool _additive(BinaryExpr expr) =>
      expr.operator.text == '+' || expr.operator.text == '-';

  /// Flattens the left-associative additive spine into its terms.
  List<ArithExpr> _additiveTerms(ArithExpr expr) {
    if (expr is BinaryExpr && _additive(expr)) {
      return <ArithExpr>[..._additiveTerms(expr.left), expr.right];
    }
    return <ArithExpr>[expr];
  }

  /// A `*` node: the complex side first, then the two-word step
  /// (catalogue 4.7). Returns the product's scale, the factor sum.
  int _product(BinaryExpr expr) {
    // Both call sites take an additive node before this runs, so any
    // operator here but `*` is unruled.
    if (expr.operator.text != '*') {
      _unruled('the operator ${expr.operator.text} (notes section 7)');
    }
    final ArithExpr left = expr.left;
    final ArithExpr right = expr.right;
    final bool leftLeaf = left is NameOperand || left is LiteralOperand;
    final bool rightLeaf = right is NameOperand || right is LiteralOperand;
    if (leftLeaf && rightLeaf) {
      final DataItem? first = _leafOperand(left);
      final DataItem? second = _leafOperand(right);
      // `MPY` takes a name wherever one factor is a literal, so the
      // `LDQ` takes the literal — `LDQ CP)+12 / MPY EXEMPTIONS,1` at
      // 01221 — and the right factor when neither is one, as
      // `LDQ 1)RATE,1 / MPY 3)HOURS` at 00641 shows.
      final leftLoads = left is LiteralOperand;
      _guarded(leftLoads ? first : second);
      word(); // LDQ.
      _guarded(leftLoads ? second : first);
      word(); // MPY.
      return _naturalScale(left) + _naturalScale(right);
    }
    if (!leftLeaf && !rightLeaf) {
      _unruled('a product of two computed factors (no sample instance)');
    }
    final complex = leftLeaf ? right : left;
    final leaf = leftLeaf ? left : right;
    final int scale = switch (complex) {
      TruthExpr() => _truthFunction(complex),
      BinaryExpr() => _chain(complex),
      _ => _unruled('a factor of ${complex.runtimeType}'),
    };
    final DataItem? item = _leafOperand(leaf);
    // The step onto the finished value: `XCA`, then the factor's word.
    word();
    _guarded(item);
    word();
    return scale + _naturalScale(leaf);
  }

  /// Prepares [leaf] as a factor and returns the item its own word
  /// addresses, `null` for a literal — the pool word needs no guard.
  DataItem? _leafOperand(ArithExpr leaf) {
    switch (leaf) {
      case LiteralOperand(:final literal):
        _numericLiteral(literal);
        return null;
      case NameOperand(:final name):
        if (name.subscripts.isNotEmpty) {
          _unruled('a subscripted factor (no sample instance)');
        }
        return _decimal(_item(name)!);
      default:
        _unruled('a factor of ${leaf.runtimeType}');
    }
  }

  /// The guard [item] needs at the word that addresses it.
  void _guarded(DataItem? item) {
    if (item != null) {
      _loadBaseOf(item);
    }
  }

  /// The truth function (catalogue 4.7): one head word, the comparison
  /// with its true outcome falling through, and the four-word tail that
  /// ends on `CLA` of the true value. Eleven words at its one site.
  int _truthFunction(TruthExpr expr) {
    _pool.seed(1);
    word();
    _compare(expr.condition, trueFalls: true, falseFalls: false);
    words(4);
    return 0;
  }

  /// The store: one word on equal scale, the five-word scaling tail
  /// otherwise — `XCA / ACL half / LRS 35 / DVP scale / STQ`, the
  /// half-adjust suppressed under TRUNCATED (catalogue 4.7; D4.1).
  void _store(NameReference target, int scale, {required bool truncated}) {
    if (target.subscripts.isNotEmpty) {
      _unruled('a subscripted SET target (no sample instance)');
    }
    final DataItem item = _decimal(_item(target)!);
    final int targetScale = _sem(item).fractionDigits;
    if (scale == targetScale) {
      _loadBaseOf(item);
      word();
      return;
    }
    if (scale < targetScale) {
      _unruled('a store below the target scale (no sample instance)');
    }
    final int divisor = _pow10(scale - targetScale);
    if (!truncated) {
      _pool.machineWord(divisor ~/ 2); // The half-adjust, referenced first.
    }
    _pool.machineWord(divisor);
    _loadBaseOf(item);
    words(truncated ? 4 : 5);
  }

  // --- IF and the comparisons (catalogue 4.8) -----------------------------

  void _if(IfClause clause) {
    final List<String> names =
        semantics.allocation?.clauseNames[clause] ?? const <String>[];
    _compare(clause.condition, trueFalls: true, falseFalls: false);
    clause.thenArm.forEach(_clause);
    if (clause.otherwiseArm.isNotEmpty) {
      if (!_endsInGoTo(clause.thenArm)) {
        word(); // The THEN-arm join transfer (notes 3.3).
      }
      if (names.isNotEmpty) {
        label(names.first); // The OTHERWISE arm's own label (M3-8).
      }
      clause.otherwiseArm.forEach(_clause);
    }
    if (names.isNotEmpty) {
      label(names.last); // The join, on whatever word follows.
    }
  }

  /// A THEN arm that is itself a GO TO gets no join transfer
  /// (notes 3.3).
  bool _endsInGoTo(List<Clause> arm) =>
      arm.isNotEmpty &&
      arm.last is GoToClause &&
      (arm.last as GoToClause).index == null &&
      (arm.last as GoToClause).targets.every(
        (GoToTarget target) => target.when == null,
      );

  /// One comparison: the operand preparations, the compare, and the
  /// skip vector. [trueFalls] and [falseFalls] say which continuation
  /// is the next word to be emitted, which is what decides whether
  /// slot 3 drops (catalogue 4.8).
  void _compare(
    CondExpr condition, {
    required bool trueFalls,
    required bool falseFalls,
  }) {
    if (condition is! Relation) {
      _unruled('a compound or condition-name comparison (no sample instance)');
    }
    final Relation relation = condition;
    // A figurative constant, and a zero that must be built and scaled,
    // go into the accumulator; otherwise the left operand does.
    final bool rightInAccumulator =
        _builtInAccumulator(relation.right) &&
        !_builtInAccumulator(relation.left);
    final ArithExpr acc = rightInAccumulator ? relation.right : relation.left;
    final ArithExpr storage = rightInAccumulator
        ? relation.left
        : relation.right;
    if (_alphamericCompare(relation)) {
      _alphamericComparison(
        acc,
        storage,
        relation,
        rightInAccumulator,
        trueFalls: trueFalls,
        falseFalls: falseFalls,
      );
    } else {
      _numericComparison(
        acc,
        storage,
        relation,
        rightInAccumulator,
        trueFalls: trueFalls,
        falseFalls: falseFalls,
      );
    }
  }

  bool _builtInAccumulator(ArithExpr operand) => switch (operand) {
    FigurativeOperand() => true,
    LiteralOperand(:final literal) when !_alphameric(literal) =>
      _literalValue(literal).$1 == 0,
    _ => false,
  };

  bool _alphamericCompare(Relation relation) {
    for (final operand in <ArithExpr>[relation.left, relation.right]) {
      if (operand case NameOperand(:final name)) {
        if (_moveClass(_item(name)!) == FieldClass.alphameric) {
          return true;
        }
      }
    }
    return false;
  }

  /// P(A) + L(A) + P(B) + 1 + V (catalogue 4.8). The zero build is
  /// three words when the zero needs the storage operand's scale.
  void _numericComparison(
    ArithExpr acc,
    ArithExpr storage,
    Relation relation,
    bool mirrored, {
    required bool trueFalls,
    required bool falseFalls,
  }) {
    switch (acc) {
      case LiteralOperand(:final literal) when _literalValue(literal).$1 != 0:
        _numericLiteral(literal);
        word(); // CLA CP)+nn.
      // Only a zero figurative reaches the zero build: legality bars
      // the others against a numeric operand (msg 82,00), and one that
      // slipped through would take the default refusal below.
      case FigurativeOperand(:final word) when _zero(word):
        _zeroBuild(storage);
      case LiteralOperand():
        _zeroBuild(storage);
      case NameOperand(:final name):
        final DataItem item = _decimal(_item(name)!);
        if (name.subscripts.isNotEmpty) {
          words(2); // The positional-indicator prologue.
        } else {
          _loadBaseOf(item);
        }
        word(); // CLA.
      default:
        _unruled('a comparison of ${acc.runtimeType}');
    }
    switch (storage) {
      case LiteralOperand(:final literal):
        _numericLiteral(literal); // CAS CP)+nn.
      case NameOperand(:final name):
        final DataItem item = _decimal(_item(name)!);
        if (name.subscripts.isNotEmpty) {
          words(2); // The positional-indicator prologue.
        } else {
          _loadBaseOf(item);
        }
      default:
        _unruled('a comparison of ${storage.runtimeType}');
    }
    word(); // CAS or LAS.
    words(
      _vector(relation, mirrored, trueFalls: trueFalls, falseFalls: falseFalls),
    );
  }

  bool _zero(Token figurative) => figurative.text.startsWith('ZERO');

  /// The zero side of a numeric comparison: aligned to the storage
  /// operand's scale when they differ, one plain load otherwise.
  void _zeroBuild(ArithExpr storage) {
    final int deficit = _operandScale(storage);
    _pool.seed(0);
    if (deficit > 0) {
      _pool.machineWord(_pow10(deficit));
      words(3);
    } else {
      word();
    }
  }

  int _operandScale(ArithExpr operand) => switch (operand) {
    NameOperand(:final name) => _sem(_item(name)!).fractionDigits,
    LiteralOperand(:final literal) => _literalValue(literal).$2,
    _ => 0,
  };

  /// The alphameric comparison (catalogue 4.8): each operand costs its
  /// prologue, its load, and its extraction — `LGL` off byte zero,
  /// `ANA` under six characters — and when both need extraction the
  /// first spills to result storage and the compare reads the cell.
  void _alphamericComparison(
    ArithExpr acc,
    ArithExpr storage,
    Relation relation,
    bool mirrored, {
    required bool trueFalls,
    required bool falseFalls,
  }) {
    // Both attested operands are alphameric (statement 200); a class
    // mix rides in below the stop severity (msg 107,00) and refuses.
    for (final operand in <ArithExpr>[acc, storage]) {
      if (operand case NameOperand(:final name)) {
        final FieldClass fieldClass = _moveClass(_item(name)!);
        if (fieldClass != FieldClass.alphameric) {
          _unruled(
            'an alphameric comparison of ${fieldClass.name} '
            '(no sample instance)',
          );
        }
      }
    }
    final int storageExtraction = _extractionCost(storage);
    switch (acc) {
      case FigurativeOperand(word: final figurative):
        if (!figurative.text.startsWith('HIGH')) {
          _unruled('this figurative comparison (no sample instance)');
        }
        _pool.machineWord(_highValueWord);
        word(); // CLA CP)+nn.
      case NameOperand(:final name):
        _loadBaseOf(_item(name)!);
        word(); // CLA.
        words(_emitExtraction(name));
      default:
        _unruled('a comparison of ${acc.runtimeType}');
    }
    if (storageExtraction == 0) {
      if (storage case NameOperand(:final name)) {
        _loadBaseOf(_item(name)!);
      } else {
        // A literal or figurative here would need a pool word no
        // sample site attests.
        _unruled('a comparison of ${storage.runtimeType}');
      }
      word(); // CAS or LAS against the field itself.
    } else {
      word(); // The spill to a result-storage cell.
      final operand = storage as NameOperand;
      _loadBaseOf(_item(operand.name)!);
      word(); // CLA.
      words(_emitExtraction(operand.name));
      word(); // CAS against the spilled cell.
    }
    words(
      _vector(relation, mirrored, trueFalls: trueFalls, falseFalls: falseFalls),
    );
  }

  /// `OCT 747474747474` — the attested HIGH.VALUE word, `CP)+23`.
  static const int _highValueWord = 0xF3CF3CF3C;

  int _extractionCost(ArithExpr operand) {
    if (operand case NameOperand(:final name)) {
      final ItemSemantics sem = _sem(_item(name)!);
      return (sem.byte != 0 ? 1 : 0) + (sem.storageChars < 6 ? 1 : 0);
    }
    return 0;
  }

  /// Emits the extraction and pools its mask: the field sits at the low
  /// end after `LGL`, so the mask extracts characters 0 on (the
  /// attested `CP)+30`, shared by both operands of statement 200).
  int _emitExtraction(NameReference name) {
    final ItemSemantics sem = _sem(_item(name)!);
    var cost = 0;
    if (sem.byte != 0) {
      cost++; // LGL.
    }
    if (sem.storageChars < 6) {
      _pool.machineWord(_extractMask(0, sem.storageChars - 1));
      cost++; // ANA.
    }
    return cost;
  }

  /// The vector: three one-word slots for greater, equal and less, and
  /// only slot 3 can drop — when the less outcome's continuation is the
  /// next word to be emitted (catalogue 4.8).
  int _vector(
    Relation relation,
    bool mirrored, {
    required bool trueFalls,
    required bool falseFalls,
  }) {
    Set<_Outcome> trueSet = switch (relation.op) {
      RelationOp.greater => {_Outcome.greater},
      RelationOp.less => {_Outcome.less},
      RelationOp.equal => {_Outcome.equal},
    };
    if (mirrored) {
      trueSet = {
        for (final _Outcome outcome in trueSet)
          switch (outcome) {
            _Outcome.greater => _Outcome.less,
            _Outcome.less => _Outcome.greater,
            _Outcome.equal => _Outcome.equal,
          },
      };
    }
    if (relation.negated) {
      trueSet = _Outcome.values.toSet().difference(trueSet);
    }
    final bool lessIsTrue = trueSet.contains(_Outcome.less);
    final lessFalls = lessIsTrue ? trueFalls : falseFalls;
    return lessFalls ? 2 : 3;
  }

  int _naturalScale(ArithExpr expr) => switch (expr) {
    NameOperand(:final name) => _sem(_item(name)!).fractionDigits,
    LiteralOperand(:final literal) => _literalValue(literal).$2,
    TruthExpr() => 0,
    BinaryExpr(:final left, :final right) when expr.operator.text == '*' =>
      _naturalScale(left) + _naturalScale(right),
    BinaryExpr() when _additive(expr) => _additiveTerms(
      expr,
    ).map(_naturalScale).reduce((int a, int b) => a > b ? a : b),
    _ => _unruled('the scale of ${expr.runtimeType}'),
  };
}
