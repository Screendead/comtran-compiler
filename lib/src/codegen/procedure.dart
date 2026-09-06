/// The procedure text (M4-1 chunks B1 to B6): every word the procedure
/// division generates, sized, placed and written.
///
/// Chunk B1 laid the address spine: how many words each clause takes and
/// where each one sits. Chunks B2 to B6 filled the mnemonics, operands
/// and object words of every family the spine sized — the last of them
/// the input-output frame and the STOP RUN close-down.
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

import 'dart:math' as math;

import '../ast/data_ast.dart';
import '../ast/environment_ast.dart';
import '../ast/procedure_ast.dart';
import '../chars/char_code.dart';
import '../data/data_map.dart';
import '../data/dictionary.dart';
import '../data/name_tally.dart';
import '../data/pictorial.dart';
import '../emulator/decode.dart';
import '../emulator/word.dart';
import '../lexer/diagnostic.dart';
import '../lexer/messages.dart';
import '../lexer/procedure_lexer.dart';
import '../lexer/reserved_words.dart';
import '../lexer/source_card.dart';
import '../lexer/token.dart';
import '../parser/parser.dart';
import 'codegen_messages.dart';
import 'control_cards.dart';
import 'encode.dart';
import 'image.dart';
import 'pool.dart';
import 'text_model.dart';

/// What the procedure division generates.
final class ProcedureText {
  const ProcedureText({
    required this.units,
    required this.words,
    required this.entry,
    required this.poolWords,
    required this.poolUnits,
  });

  /// The assembly units, program order.
  final List<AssemblyUnit> units;

  /// Words the text takes on Location Counter 0.
  final int words;

  /// The object program's entry point, which the end-of-text word names
  /// and addresses (D2.1): the statement or section labelled
  /// `PROGRAM.START`, or `GN)000` on the first procedure word where the
  /// program carries no such label.
  final ({String name, int location}) entry;

  /// The constant pool's entry count after layout (M4-4).
  final int poolWords;

  /// The pool's printed lines in layout order, one per entry, placed at
  /// their `CP)` addresses — empty on the measuring pass, which has no
  /// addresses to place them at.
  final List<AssemblyUnit> poolUnits;
}

/// What the measuring pass diagnoses (M4-18): the sink the notes and
/// the capacity stops enter, and the name tally continued from the
/// semantic layer (M4-5). The placing pass carries none — it repeats
/// the walk, and a diagnostic reported twice would print twice — and
/// nothing diagnosed needs an address.
final class CodegenChecks {
  CodegenChecks(
    this.diagnostics, {
    required this.pedantic,
    required this.tableLimits,
    required int nameCount,
  }) : names = NameTally(
         diagnostics,
         tableLimits: tableLimits,
         count: nameCount,
       );

  final List<Diagnostic> diagnostics;
  final bool pedantic;
  final bool tableLimits;
  final NameTally names;
}

/// Generates the procedure text of [semantics], the first word at
/// [origin].
///
/// [image] is `null` on the measuring pass, when no address past the
/// text is known yet; [checks] rides on that pass alone.
ProcedureText generateProcedure(
  SemanticResult semantics, {
  required int origin,
  ProgramImage? image,
  CodegenChecks? checks,
}) {
  final text = _Text(semantics, origin: origin, image: image, checks: checks);
  var entry = true;
  try {
    for (final ParsedGroup group in semantics.parse.groups) {
      if (group is ParsedProcedureGroup) {
        if (entry) {
          // The first procedure word's generated name (M3-8), which is
          // the entry point too unless PROGRAM.START names another word
          // (D2.1 as amended 2026-09-06).
          text.label('GN)000');
          entry = false;
        }
        text.sentences(group.sentences);
      }
    }
    return text.result();
  } on UnrecoveredShape {
    // The DO edges gathered before a refusal are real edges of the
    // program, so the re-entries they close still note, as a 946
    // recorded before a refusal does (D11.4).
    text.noteReentrantCalls();
    rethrow;
  }
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

/// The result-storage cells each section reserves, section 0 first, the
/// last entry the undivided tail every later section shares.
///
/// Constants, and deliberately not a rule — the `TS)` precedent (Jack's
/// ruling, 2026-08-15, the chunk B1 review record). The sample attests
/// sections 0 to 2 reserving 3, 2 and 3 cells while referencing 2, 1 and
/// 1, no tested rule reproduces those heads, and the 7-cell tail is
/// unobservable: the program addresses one cell of it, at statement 221,
/// and contradictory closures fit the rest. Section 3 therefore takes
/// the tail's first word and a fourth section refuses. For any program
/// but the sample this reservation is unverifiable, which is stated
/// rather than hidden.
const List<int> resultStorageCells = <int>[3, 2, 3, 7];

/// The three outcomes of a skip vector, in slot order ([J 90.02.12]).
enum _Outcome { greater, equal, less }

/// One continuation of a comparison outcome: a transfer to [name] when
/// the generator holds one, else the word [extra] words past the
/// vector's end (catalogue 4.8; M4-11 as amended, chunk B1).
final class _Cont {
  const _Cont.falls([this.extra = 0]) : name = null;
  const _Cont.named(String this.name) : extra = 0;

  /// The label the slot transfers to, `null` when the generator holds
  /// none and the slot prints the relative form.
  final String? name;

  /// Words past the vector the fall lands: 0 for the next word, 1 when
  /// the truth function's `SIR` intervenes.
  final int extra;
}

/// Where a computed value waits: `MPY` leaves it in the MQ and a chain
/// leaves it in the accumulator, and the store, the park and the
/// multiplicative step each choose their word by which it is
/// (catalogue 4.7).
enum _Register { ac, mq }

/// One computed value: its compile-time scale in powers of ten, and the
/// register holding it.
typedef _Value = ({int scale, _Register register});

/// One symbolic address: the text the operand column prints and the
/// value the address field punches.
///
/// Both are thunks because a pool entry has no index until the whole
/// text has run — the pool is not in first-need order, and its address
/// follows the text (M4-4).
final class _Sym {
  const _Sym(this.text, this.value, this.relocation);

  final String Function() text;
  final int Function() value;

  /// What the loader does to a field holding this address
  /// ([J 90.03.04]): a class is fixed at the reference, never
  /// address-dependent, so it is a value and not a thunk.
  final Relocation relocation;
}

/// One reference to a data item: the name the listing prints, the
/// address field, and the index register the reference is tagged with.
///
/// An item inside a located record is addressed relative to its record
/// and reached through a base register; every other item carries the
/// absolute address of its transmitted area (M4-9). A located address
/// is a displacement the loader leaves alone, so its relocation class
/// is constant; a transmitted address is relative ([J 90.03.04]).
typedef _Ref = ({String text, int address, int tag, Relocation relocation});

/// One DO call site: the procedures open around it, the procedure it
/// names, and where to report a re-entry (D5.7).
typedef _DoEdge = ({List<String> callers, String target, Token at, int clause});

/// The emitter: one word at a time, in program order.
final class _Text {
  _Text(this.semantics, {required int origin, this.image, this.checks})
    : _origin = origin,
      _location = origin,
      _generated = semantics.allocation?.generatedCount ?? 0 {
    _pool = ConstantPool(onEntry: _poolEntry);
    // Every program's fixed names: the five block heads, printed at
    // `BSS 0` too, the head row's `PI)1`, and the pointer block's
    // `BL)1` and `IOC)29` (M4-4).
    for (final StorageBlock block in StorageBlock.values) {
      _name(block.symbol);
    }
    _name('PI)1');
    _name('BL)1');
    _name('IOC)29');
    for (final ParsedGroup group in semantics.parse.groups) {
      if (group is! ParsedProcedureGroup) {
        continue;
      }
      for (final Sentence sentence in group.sentences) {
        if (!semantics.capacityDeletedSentences.contains(sentence)) {
          final String? label = sentence.scan.label;
          if (label != null) {
            _labels.add(label);
          }
        }
        if (_beginsSection(sentence)) {
          final String? label = sentence.scan.label;
          if (label != null) {
            _sections.add(label);
          }
        }
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
    for (final FileCard card in numberedFiles(semantics.parse)) {
      _fileOrdinals[card.spec.name] = _fileCards.length + 1;
      _fileCards[card.spec.name] = card;
    }
    _duplicateFiles = fileCards(semantics.parse).length > _fileCards.length;
  }

  final SemanticResult semantics;

  /// The address layout, on the placing pass only.
  final ProgramImage? image;

  /// The diagnostics and the name tally, on the measuring pass only.
  final CodegenChecks? checks;

  final int _origin;
  final List<AssemblyUnit> _units = <AssemblyUnit>[];
  late final ConstantPool _pool;

  /// The first card of the sentence the walk is in, the anchor of a
  /// diagnostic no token owns; `null` ahead of the first sentence.
  SourceCard? _card;

  /// The M2-6 clause number of the clause the walk is in, 0 outside one.
  int _clauseNumber = 0;

  /// The distinct generated symbols entered so far (M4-5): a SYS) or
  /// IOC) number counts once, not per use.
  final Set<String> _names = <String>{};

  int _poolEntries = 0;

  /// Every DO call site with the procedures open around it, for the
  /// D5.7 re-entry check after the walk.
  final List<_DoEdge> _doEdges = <_DoEdge>[];

  bool _reentryNoted = false;

  /// Deferred LOC values: an `EQU` prints an address the walk has not
  /// reached, or a pool address that follows the whole text. Each entry
  /// patches one unit after the walk ends.
  final List<(int, int Function())> _fixups = <(int, int Function())>[];

  /// Deferred operand text and object words, one entry per written
  /// unit, patched with [_fixups] after the walk ends (M4-4).
  final List<(int, String Function(), int Function())> _text =
      <(int, String Function(), int Function())>[];

  /// Deferred operand text with no object word: an `EQU` prints a
  /// symbol in the operand column and leaves the OCTAL column blank.
  final List<(int, String Function())> _operands = <(int, String Function())>[];

  /// Procedure names at least one DO (or bare-name AT END) calls: these
  /// paragraphs carry a return cell (catalogue 4.1 — call-site-driven).
  final Set<String> _doTargets = <String>{};

  /// Section names: every section carries a return cell whether or not
  /// a DO addresses it (catalogue 4.1).
  final Set<String> _sections = <String>{};

  /// Every label the walk will bind, gathered before it: the deferred
  /// binder resolves an unbound name to address 0, so a reference must
  /// refuse ahead of it.
  final Set<String> _labels = <String>{};

  /// The base locator serving each located record, `BL)2` on (M4-4).
  final Map<DataItem, int> _baseLocators = <DataItem, int>{};

  /// Each file's one-based declaration ordinal `k`, whose calling
  /// sequences address the file as `04000 + k` (the notes, section
  /// 2.6).
  final Map<String, int> _fileOrdinals = <String, int>{};

  /// Each file's FILE card, for the options the calls depend on.
  final Map<String, FileCard> _fileCards = <String, FileCard>{};

  /// Whether two FILE cards declare one name. No diagnostic bars the
  /// duplicate upstream, and a second card makes every later ordinal
  /// ambiguous, so any GET or FILE in such a program refuses (M4-2 as
  /// amended).
  late final bool _duplicateFiles;

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

  /// The open DO-called paragraph, closed by a terminal return at the
  /// next labelled sentence or at its END (catalogue 4.1). The return
  /// transfers through the paragraph's own cell, so the name rides
  /// here from the label that opened it.
  String? _openParagraph;

  /// The open section; its END emits the terminal return through the
  /// section's cell.
  String? _openSection;

  /// Which section the walk is in, counting from 1 at the first BEGIN
  /// SECTION. Sections are sequential, never nested, so the counter never
  /// falls: the main program before the first one is section 0. It names
  /// the result-storage block a park addresses (catalogue 4.7).
  int _section = 0;

  /// Names waiting for the next word. Two of them print one per line,
  /// the word on the last (M4-8).
  List<String> _pending = <String>[];

  // --- The emitter core ---------------------------------------------------

  List<String> _take() {
    final List<String> names = _pending;
    _pending = <String>[];
    for (final name in names) {
      if (_labelled.containsKey(name)) {
        // Rebinding keeps only the later address, against D2.5's
        // section scoping, and no sample label repeats.
        _unruled('a procedure name defined twice (no sample instance)');
      }
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

  /// Emits one written object word: [operation] and [control] now, the
  /// operand text and the 36-bit word after the walk (M4-4). Every
  /// caller knows each field's relocation class at the reference, so
  /// the control group alone needs no thunk.
  void _emit(
    String operation,
    WordForm form,
    String Function() operand,
    int Function() word, {
    required int control,
  }) {
    final List<String> names = _take();
    _text.add((_units.length, operand, word));
    _units.add(
      AssemblyUnit(
        operation: operation,
        operand: '',
        location: _location++,
        labels: names,
        control: control,
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
    control: standardControl(Relocation.constant, address.relocation),
  );

  /// A type-B instruction through [address] indirectly: the starred
  /// mnemonic, and the two flag bits in the word — the attested
  /// `TRA*   END.OF.MASTERS` against octal `0020 60 0 00331`.
  void _opIndirect(Op op, _Sym address) => _emit(
    '${mnemonic(op)}*',
    formOf(op),
    address.text,
    () => typeBWord(op, address: address.value(), indirect: true),
    control: standardControl(Relocation.constant, address.relocation),
  );

  /// A type-B instruction against [item], guarded by the caller.
  void _opItem(Op op, DataItem item, {int plus = 0}) {
    final _Ref ref = _ref(item, plus: plus);
    _emit(
      mnemonic(op),
      formOf(op),
      () => ref.tag == 0 ? ref.text : '${ref.text},${ref.tag}',
      () => typeBWord(op, tag: ref.tag, address: ref.address),
      control: standardControl(Relocation.constant, ref.relocation),
    );
  }

  /// A shift: the distance rides in the address field and prints
  /// decimal (the attested `ARS 18` against octal `00022`).
  void _shift(Op op, int distance) => _emit(
    mnemonic(op),
    formOf(op),
    () => '$distance',
    () => typeBWord(op, address: distance),
    control: ControlGroup.constantWord,
  );

  /// `XCA`, which exchanges the accumulator and the MQ whole and so
  /// prints no operand.
  void _xca() => _emit(
    mnemonic(Op.xca),
    formOf(Op.xca),
    () => '',
    () => typeBWord(Op.xca),
    control: ControlGroup.constantWord,
  );

  /// `PXA 0,0` — the truth function's clear of the accumulator, which
  /// prints both fields though both are zero (catalogue 4.7).
  void _pxa() => _emit(
    mnemonic(Op.pxa),
    formOf(Op.pxa),
    () => '0,0',
    () => typeBWord(Op.pxa),
    control: ControlGroup.constantWord,
  );

  /// `RIR`, `SIR` or `RFT`: one 18-bit mask over the sense indicators,
  /// printed as six octal digits — the attested `RIR 777777` at LOC
  /// 01240.
  void _senseIndicator(Op op, int mask) => _emit(
    mnemonic(op),
    formOf(op),
    () => mask.toRadixString(8).padLeft(6, '0'),
    () => indicatorWord(op, mask),
    control: ControlGroup.constantWord,
  );

  /// `COM`, whose `+0760` sub-operation rides in the address field and
  /// prints nothing ([J 90.02.02]; the emulator's decision ED-3).
  void _com() => _emit(
    mnemonic(Op.com),
    formOf(Op.com),
    () => '',
    () => typeBWord(Op.com, address: comSubOperation),
    control: ControlGroup.constantWord,
  );

  /// `AXT n,1` — the digit count an edited store converts
  /// ([J 90.02.30]).
  void _axt(int count, int register) => _emit(
    mnemonic(Op.axt),
    formOf(Op.axt),
    () => '$count,$register',
    () => typeBWord(Op.axt, tag: register, address: count),
    control: ControlGroup.constantWord,
  );

  /// A system-subroutine entry, `TSX SYS)nnn,4`: the MOVPAK entries
  /// and the open, close and STOP entries ([J 90.02.14] and
  /// [J 90.02.15]).
  void _tsx(int sys) {
    _name('SYS)$sys');
    _emit(
      mnemonic(Op.tsx),
      formOf(Op.tsx),
      () => 'SYS)$sys,4',
      () => typeBWord(Op.tsx, tag: 4, address: sys),
      control: standardControl(Relocation.constant, Relocation.system),
    );
  }

  /// An input-output package entry, `TSX IOC)n,4` (catalogue 4.2).
  void _tsxIoc(int entry) {
    _name('IOC)$entry');
    _emit(
      mnemonic(Op.tsx),
      formOf(Op.tsx),
      () => 'IOC)$entry,4',
      () => typeBWord(Op.tsx, tag: 4, address: entry),
      control: standardControl(Relocation.constant, Relocation.system),
    );
  }

  /// A MOVPAK step or fill call, `TXI SYS)nnn,1,count`
  /// ([J 90.02.16]). The decrement prints decimal, as the listing
  /// does at LOC 01146 for the octal `00014`.
  void _txi(int sys, int decrement) {
    _name('SYS)$sys');
    _emit(
      mnemonic(Op.txi),
      formOf(Op.txi),
      () => 'SYS)$sys,1,$decrement',
      () => typeAWord(Op.txi, tag: 1, decrement: decrement, address: sys),
      control: standardControl(Relocation.constant, Relocation.system),
    );
  }

  /// The in-line address word `PZE LOC,,BYTE` ([J 90.02.14]). All 25
  /// attested sites name a fixed location, so the word takes no tag and
  /// the located form has none (catalogue 4.3).
  void _pze(DataItem item) {
    // The test precedes [_ref]: a located reference reads its record's
    // base register, and no caller guards one for this word.
    if (_located(item)) {
      _unruled('an in-line address word for a located item (catalogue 4.3)');
    }
    final _Ref ref = _ref(item);
    final int byte = _sem(item).byte;
    _emit(
      'PZE',
      WordForm.prefix,
      () => '${ref.text},,$byte',
      () => pzeWord(decrement: byte, address: ref.address),
      control: standardControl(Relocation.constant, ref.relocation),
    );
  }

  /// An in-line constant word, printed as its twelve octal digits.
  void _oct(int value) => _emit(
    'OCT',
    WordForm.solid,
    () => Word36.octal(value),
    () => value,
    control: ControlGroup.constantWord,
  );

  /// A calling-sequence parameter pair, `PZE first,,second`: the first
  /// operand in the address field, the second in the decrement
  /// ([J 90.02.14]; [J 90.02.28]; the notes, section 2.6).
  void _pzePair(_Sym first, _Sym second) => _emit(
    'PZE',
    WordForm.prefix,
    () => '${first.text()},,${second.text()}',
    () => pzeWord(decrement: second.value(), address: first.value()),
    control: standardControl(second.relocation, first.relocation),
  );

  /// The whole-file-set parameter of OPEN and CLOSE, `PZE IOC)1`
  /// ([J 90.02.08]; [J 90.02.14]).
  void _pzeIoc1() {
    _name('IOC)1');
    _emit(
      'PZE',
      WordForm.prefix,
      () => 'IOC)1',
      () => pzeWord(address: 1),
      control: standardControl(Relocation.constant, Relocation.system),
    );
  }

  /// `SYS)nnn` — a communication cell or a subroutine entry.
  _Sym _sys(int number) {
    _name('SYS)$number');
    return _Sym(() => 'SYS)$number', () => number, Relocation.system);
  }

  /// A file as an operand: the punched name over the address
  /// `04000 + k` octal, `k` the file's one-based declaration ordinal
  /// (the notes, section 2.6).
  _Sym _fileSym(String name) =>
      _Sym(() => name, () => 0x800 + _fileOrdinals[name]!, Relocation.system);

  /// A procedure label as an operand: the written name, its location
  /// read after the walk so a forward transfer binds (M4-4).
  _Sym _labelSym(String name) =>
      _Sym(() => name, () => _labelled[name] ?? 0, Relocation.relative);

  /// Refuses a target the deferred binder cannot resolve: an undefined
  /// name and a two-word D2.5 reference each fall to address 0, where
  /// msgs 127 and 188 record the 1962 bypass instead.
  void _checkTarget(NameReference name) {
    if (name.words.length > 1) {
      _unruled('a two-word procedure reference (D2.5; no sample instance)');
    }
    if (!_labels.contains(name.text)) {
      _unruled(
        'a transfer or call to an undefined procedure '
        '(behind msgs 127 and 188)',
      );
    }
  }

  /// `CP)+n` — a pool entry, by index and by address.
  _Sym _cp(PoolHandle handle) => _Sym(
    () => 'CP)+${_layout.indexOf(handle)}',
    () => _poolAddress(handle),
    Relocation.relative,
  );

  /// `BL)n` or `PI)n` — one word of a Location Counter 1 block.
  _Sym _blockWord(StorageBlock block, int number) {
    _name('${block.symbol}$number');
    return _Sym(
      () => '${block.symbol}$number',
      () => image?.symbolAddress(block, number) ?? 0,
      Relocation.relative,
    );
  }

  /// `RS)n` or `k.RS)n` — one result-storage cell of the section the
  /// walk is in, two words a cell (D4.8).
  ///
  /// Section 0 prints the bare symbol and every later section qualifies
  /// it with its number. [offset] prints the `+0` word suffix, which
  /// LOC 00621 carries and no other reference does (M4-10).
  _Sym _resultCell(int cell, {bool offset = false}) {
    final int section = _section;
    if (section >= resultStorageCells.length) {
      _unruled('result storage in section $section (no sample instance)');
    }
    if (cell >= resultStorageCells[section]) {
      _unruled('result-storage cell $cell of section $section (M4-10)');
    }
    var word = 0;
    for (var i = 0; i < section; i++) {
      word += 2 * resultStorageCells[i];
    }
    final name =
        '${section == 0 ? '' : '$section.'}${StorageBlock.rs.symbol}$cell';
    _name(name);
    final text = '$name${offset ? '+0' : ''}';
    final int address =
        (image?.originOf(StorageBlock.rs) ?? 0) + word + 2 * cell;
    return _Sym(() => text, () => address, Relocation.relative);
  }

  /// Emits an `EQU` line at the head of the machinery block that needs
  /// it, printing [value] in the LOC column and taking no word of its
  /// own (M4-8). [operand] fills the symbolic column, which carries no
  /// object word of its own.
  ///
  /// The line interrupts the stream, so a name still waiting for the
  /// next word prints alone ahead of it, at the location that word will
  /// take: the attested `GN)075` at LOC 00702, which the `GN)088 EQU`
  /// line separates from its `AXT`.
  void equ(String name, int Function() value, {String Function()? operand}) {
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
    if (operand != null) {
      _operands.add((_units.length, operand));
    }
    _fixups.add((_units.length, value));
    _units.add(AssemblyUnit(operation: 'EQU', operand: '', labels: [name]));
  }

  /// The next later-pass generated name (M4-6 — the sample's GN)084 on).
  String _mint() {
    final name = 'GN)${(++_generated).toString().padLeft(3, '0')}';
    _name(name);
    return name;
  }

  /// Enters [symbol] in the name tally the first time the text writes
  /// it (M4-5): every generated class counts once per distinct name.
  void _name(String symbol) {
    final CodegenChecks? checks = this.checks;
    if (checks != null && _names.add(symbol)) {
      checks.names.enter(_card);
    }
  }

  /// One new pool entry: a `CP)+NN` name for the tally (M4-5; D8.8),
  /// and the 501st draws msg 172 ([J 90.01.05] item k; D9.7).
  void _poolEntry() {
    final CodegenChecks? checks = this.checks;
    if (checks == null) {
      return;
    }
    checks.names.enter(_card);
    _poolEntries += 1;
    if (checks.tableLimits && _poolEntries == constantPoolCapacity + 1) {
      // The seeds are entries 1 and 2, so the 501st is created inside
      // a sentence, after the walk anchored one.
      _report(msgConstantPoolOverflow, card: _card, clause: _clauseNumber);
    }
  }

  /// Reports [message] on the measuring pass, at [at] when a token
  /// anchors it and at [card] otherwise, carrying the M2-6 clause
  /// number [clause] when the site is inside one.
  void _report(
    Message message, {
    Token? at,
    SourceCard? card,
    int clause = 0,
    List<String> operands = const <String>[],
  }) {
    final diagnostic = Diagnostic(
      message,
      at?.card ?? card!,
      column: at?.column,
      operands: operands,
    );
    if (clause > 0) {
      diagnostic.clause = clause;
    }
    checks!.diagnostics.add(diagnostic);
  }

  /// The pool address of [handle], or zero on the measuring pass.
  int _poolAddress(PoolHandle handle) {
    final ProgramImage? layout = image;
    return layout == null ? 0 : layout.poolAddress(_layout.indexOf(handle));
  }

  late final PoolLayout _layout;

  ProcedureText result() {
    noteReentrantCalls();
    if (_pending.isNotEmpty) {
      // A trailing label on a no-word sentence (NOTE, CALL, ENTER)
      // never reaches the binder: no attested print, and a reference
      // to it would punch address 0 past the _labels guard.
      _unruled('a label bound to no word (no sample instance)');
    }
    if (_openParagraph != null || _openSection != null) {
      // The two attested closes are the next label and a written END
      // (GN)067; catalogue 4.1); no sample procedure runs to the end
      // of the text still open.
      _unruled('a procedure open at the end of the text (no sample instance)');
    }
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
        control: unit.control,
        form: unit.form,
      );
    }
    for (final (int index, String Function() operand) in _operands) {
      final AssemblyUnit unit = _units[index];
      _units[index] = AssemblyUnit(
        operation: unit.operation,
        operand: operand(),
        location: unit.location,
        labels: unit.labels,
        word: unit.word,
        control: unit.control,
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
        control: unit.control,
        form: unit.form,
      );
    }
    final ProgramImage? placed = image;
    final int? start = _labelled[programStartName];
    return ProcedureText(
      units: _units,
      words: _location - _origin,
      // `GN)000` binds before the first word the text emits, so it
      // always names `_origin` (D2.1; M3-8).
      entry: start == null
          ? (name: 'GN)000', location: _origin)
          : (name: programStartName, location: start),
      poolWords: _layout.length,
      poolUnits: <AssemblyUnit>[
        if (placed != null)
          // An `OCT` entry echoes its word as its operand; a `PZE` entry
          // prints the operand it keys on. The head entry carries the
          // block's `CP)` name and every later line prints `+NN` alone.
          for (final (int index, PoolRow row) in _layout.rows.indexed)
            AssemblyUnit(
              operation: row.key is int ? 'OCT' : 'PZE',
              operand: row.key is int ? Word36.octal(row.word) : '${row.key}',
              location: placed.poolAddress(index),
              labels: index == 0 ? const <String>['CP)'] : const <String>[],
              word: row.word,
              control: row.control,
              form: row.key is int ? WordForm.solid : WordForm.prefix,
            ),
      ],
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

  /// The address field a reference to [item] punches, [plus] words on
  /// from its first word, with its relocation class.
  ///
  /// A located item's address is the record-relative word, a
  /// displacement the loader leaves alone; every other item carries its
  /// area's origin, a relative location. Every root outside a located
  /// record that reserves a character is a transmitted area, so the
  /// origin is there.
  (int, Relocation) _dataAddress(DataItem item, {int plus = 0}) {
    final ItemSemantics sem = _sem(item);
    if (_located(item)) {
      return (sem.word + plus, Relocation.constant);
    }
    return (
      _areaOrigins[sem.spaceRoot]! + sem.word + plus,
      Relocation.relative,
    );
  }

  /// One reference to [item], [plus] words on from its first word.
  ///
  /// A located item is addressed from its record's base register, whose
  /// tag the caller guards before emitting. The `+n` suffix is the
  /// attested printed form at `3)EMPLOYEE.NUMBER+1` (M4-9).
  _Ref _ref(DataItem item, {int plus = 0}) {
    final String text = plus == 0
        ? _printedName(item)
        : '${_printedName(item)}+$plus';
    final DataItem? record = _recordOf(item);
    final int? locator = record == null ? null : _baseLocators[record];
    final (int address, Relocation relocation) = _dataAddress(item, plus: plus);
    return (
      text: text,
      address: address,
      tag: locator == null ? 0 : _registerOf(locator),
      relocation: relocation,
    );
  }

  /// The index register holding [locator]. Every located reference is
  /// guarded before it is emitted, so the cache always holds one.
  int _registerOf(int locator) => _registerHolds.entries
      .firstWhere((MapEntry<int, int> held) => held.value == locator)
      .key;

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

  /// The lowest free index register, bound to [key] for the statement.
  ///
  /// The lowest free register, not the lowest unused this statement:
  /// statement 208 takes XR2 for `BL)3` at 00772 because the NET
  /// sentence left `BL)2` live in XR1.
  int _assignRegister(int key) => _statementRegisters.putIfAbsent(key, () {
    for (var candidate = 1; candidate <= 2; candidate++) {
      if (!_registerHolds.containsKey(candidate) &&
          !_statementRegisters.containsValue(candidate)) {
        return candidate;
      }
    }
    // M4-9 assigns XR1 and XR2 and stops; no rule covers a third.
    _unruled('a third base register in one statement (M4-9)');
  });

  /// The trap on an unset word: `TXL SYS)294,r,0` ([J 90.02.23]).
  void _trap(int register) {
    _name('SYS)294');
    _emit(
      mnemonic(Op.txl),
      formOf(Op.txl),
      () => 'SYS)294,$register,0',
      () => typeAWord(Op.txl, tag: register, address: 294),
      control: standardControl(Relocation.constant, Relocation.system),
    );
  }

  /// Emits the guard pair `LAC BL)n,i / TXL SYS)294,i,0` when no
  /// register holds that locator, and records the load. A register
  /// already holding it is reused with no words ([J 90.02.23]).
  void _loadBase(DataItem record) {
    final int locator = _baseLocators[record]!;
    if (_registerHolds.containsValue(locator)) {
      return;
    }
    final int register = _assignRegister(locator);
    _registerHolds[register] = locator;
    _op(Op.lac, _blockWord(StorageBlock.bl, locator), tag: register);
    _trap(register);
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
  /// which is what a `PZE` entry keys on (catalogue 5.2). The entry's
  /// word carries the byte in the decrement and the item's address in
  /// the address field.
  PoolHandle _descriptor(DataItem item) {
    final int byte = _sem(item).byte;
    final (int address, Relocation relocation) = _dataAddress(item);
    return _pool.descriptor(
      '${_printedName(item)},,$byte',
      word: pzeWord(decrement: byte, address: address),
      control: standardControl(Relocation.constant, relocation),
    );
  }

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
  /// rule (M4-14 as amended 2026-08-15). The frame words carry the
  /// number in their address field and the comma word in their
  /// decrement (the attested `TXH CP)+14,0,CP)+15`).
  (PoolHandle, PoolHandle) _stamp(int statement, int clauseOrdinal) {
    final PoolHandle number = _pool.machineWord(
      _bcdWord('$statement'.padLeft(6)),
    );
    final String digits = '$clauseOrdinal'.padLeft(2, '0');
    return (number, _pool.machineWord(_bcdWord(',$digits   ')));
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
      _card = scan.cards.first;
      final String? name = scan.label;
      _sentenceLabel = name;
      if (name != null) {
        final String? open = _openParagraph;
        if (open != null) {
          // The previous paragraph's terminal return: the attested
          // GN)067, named by the IF join label still pending when
          // END.OF.DETAILS's label closes END.OF.MASTERS.
          _opIndirect(Op.tra, _labelSym(open));
          _openParagraph = null;
        }
        label(name);
        if (_doTargets.contains(name) && !_beginsSection(sentence)) {
          // The call-site-driven return cell (catalogue 4.1).
          _op(Op.axt, _Sym(() => '0', () => 0, Relocation.constant));
          _openParagraph = name;
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

  /// The label of the sentence the walk is in, which names the section
  /// a `BEGIN SECTION` clause opens.
  String? _sentenceLabel;

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
    _clauseNumber = clause.clause;
    switch (clause) {
      case CallClause() || NoteClause() || EnterClause():
        break; // No object word (F p. 59; J 02.04.02.01).
      case BeginSectionClause():
        if (_sentenceLabel == null) {
          _unruled('an unnamed section (no sample instance)');
        }
        if (_openSection != null) {
          // Overwriting the open name would drop its return; every
          // sample section ends before the next begins.
          _unruled(
            'a section beginning inside an open section '
            '(no sample instance)',
          );
        }
        _openSection = _sentenceLabel;
        _section += 1;
        // Every section carries a return cell (catalogue 4.1).
        _op(Op.axt, _Sym(() => '0', () => 0, Relocation.constant));
      case EndClause():
        _endClause(clause);
      case OpenClause(:final allFiles):
        if (!allFiles) {
          _unruled('an OPEN naming files (notes section 7)');
        }
        _tsx(175); // [J 90.02.14].
        _pzeIoc1();
        _callClears();
      case CloseClause(:final allFiles):
        if (!allFiles) {
          _unruled('a CLOSE naming files (notes section 7)');
        }
        _tsx(177); // [J 90.02.14].
        _pzeIoc1();
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
    if (_openParagraph != null && _openSection != null) {
      // The one return this END sizes cannot name both cells.
      _unruled(
        'an END inside an open paragraph and an open section '
        '(no sample instance)',
      );
    }
    final String? open = _openParagraph ?? _openSection;
    if (open != null) {
      // The terminal return (catalogue 4.1), indirect through the
      // cell of the procedure the END closes.
      _opIndirect(Op.tra, _labelSym(open));
      _openSection = null;
      _openParagraph = null;
    }
  }

  // --- The program frame (catalogue 4.1) ----------------------------------

  void _stop(StopClause clause, {required bool run}) {
    if (!run) {
      _unruled('STOP n (notes section 7)');
    }
    final (PoolHandle number, PoolHandle comma) = _stamp(
      _statement,
      _ordinals[clause] ?? 0,
    );
    final PoolHandle stopWord = _pool.machineWord(_bcdWord(' STOP '));
    final PoolHandle runWord = _pool.machineWord(_bcdWord(' RUN  '));
    _tsx(178); // The halt entry ([J 90.02.14]).
    _pzePair(_cp(number), _cp(comma));
    _pzePair(_cp(stopWord), _cp(runWord));
    _tsx(177); // The close-all of [J 90.02.14] rides inside STOP RUN.
    _pzeIoc1();
    _name('IOC)40');
    _emit(
      // The monitor return; a zero decrement prints none.
      mnemonic(Op.txi),
      formOf(Op.txi),
      () => 'IOC)40,0',
      () => typeAWord(Op.txi, address: 40),
      control: standardControl(Relocation.constant, Relocation.system),
    );
    _callClears();
  }

  void _goTo(GoToClause clause) {
    if (clause.index != null) {
      _unruled('the assigned GO TO (M4-12; no sample instance)');
    }
    for (final GoToTarget target in clause.targets) {
      _checkTarget(target.name);
      if (_doTargets.contains(target.name.text) ||
          _sections.contains(target.name.text)) {
        // A celled target: no rule picks the cell against the word
        // after it, and every attested target is cell-less.
        _unruled('a GO TO naming a celled procedure (M4-12)');
      }
      final CondExpr? condition = target.when;
      if (condition == null) {
        _op(Op.tra, _labelSym(target.name.text));
      } else {
        // The target's TRA is the true slot of the vector itself, and
        // the false outcomes fall to the next clause or past the last.
        _compare(
          condition,
          trueTo: _Cont.named(target.name.text),
          falseTo: const _Cont.falls(),
        );
      }
    }
  }

  void _do(DoClause clause) {
    _doEdge(clause.procedure, clause.clause);
    if (checks?.pedantic ?? false) {
      clause.indices.forEach(_noteConstantParameters);
    }
    if (clause.exactlyTimes != null ||
        clause.usingArguments.isNotEmpty ||
        clause.givingResults.isNotEmpty) {
      _unruled('DO EXACTLY / USING / GIVING (notes section 7)');
    }
    if (clause.indices.isEmpty) {
      _callTriple(clause.procedure);
      _callClears();
      return;
    }
    _doFor(clause);
  }

  /// The call `AXT *+3,7 / SXA P,4 / TRA P+1` (the attested 00370):
  /// return address into 7, through the cell, into the body.
  void _callTriple(NameReference procedure) {
    _checkTarget(procedure);
    final int here = _location;
    _op(Op.axt, _Sym(() => '*+3', () => here + 3, Relocation.relative), tag: 7);
    _op(Op.sxa, _labelSym(procedure.text), tag: 4);
    _op(Op.tra, _entrySym(procedure));
  }

  /// `P+1` — a called procedure's first instruction, one word past its
  /// return cell (catalogue 4.1).
  _Sym _entrySym(NameReference procedure) => _Sym(
    () => '${procedure.text}+1',
    () => _procedureEntry(procedure) + 1,
    Relocation.relative,
  );

  /// DO FOR (catalogue 4.1): 11 + 5·M words, M the positional
  /// indicators the loop index drives; a five-name later-pass run,
  /// binding the body-entry EQU, the increment block, and the
  /// table-base EQU (M4-6, the fitted grouping).
  void _doFor(DoClause clause) {
    if (clause.indices.length > 1) {
      _unruled('a multi-index DO (notes section 7)');
    }
    _checkTarget(clause.procedure);
    final DoIndex index = clause.indices.single;
    final DataItem? indexItem = _item(index.index);
    if (indexItem == null) {
      _unruled('a DO FOR index with no data definition (no sample instance)');
    }
    _decimal(indexItem);
    if (_located(indexItem)) {
      // The expansion reads and stores the index with no base load
      // in its word count.
      _unruled('a located DO FOR index (no sample instance)');
    }
    final driven = <(DataItem, String)>[
      for (final (DataItem, String) each in semantics.positionalIndicators)
        if (each.$2 == index.index.text) each,
    ];
    if (driven.length > 1) {
      // The M4-6 name run is fitted to one driven indicator; no rule
      // derives the run for two.
      _unruled('a DO FOR driving two indicators (M4-6; no sample instance)');
    }
    final bounds = <PoolHandle>[];
    for (final bound in <ArithExpr>[index.from, index.by, index.to]) {
      if (bound case LiteralOperand(:final literal)) {
        bounds.add(_numericLiteral(literal));
      } else {
        // A field-name or signed bound is legal (F pp. 50-51; D10.7)
        // but the sample's bounds are all plain literals, so neither
        // prologue form is attested.
        _unruled('a DO FOR bound of ${bound.runtimeType} (no sample instance)');
      }
    }
    final strides = <PoolHandle>[];
    for (final (DataItem item, _) in driven) {
      strides.add(_tableStride(item));
      _subscriptBase(item);
    }
    _generated += 1; // The first name of the run is never bound (M4-6).
    final String bodyEntry = _mint();
    final String increment = _mint();
    _generated += 1; // The fourth is never bound either (M4-6).
    final String tableBase = _mint();
    final PoolHandle base = driven.isEmpty
        ? _unruled('a DO FOR driving no indicator')
        : _subscriptBase(driven.first.$1);
    final _Sym baseCell = _cp(base);
    equ(tableBase, baseCell.value, operand: baseCell.text);
    // The prologue (the attested 00702): patch the cell to the
    // increment block, then set the index and each indicator off.
    _op(Op.axt, _labelSym(increment), tag: 4);
    _op(Op.sxa, _labelSym(clause.procedure.text), tag: 4);
    _op(Op.cla, _cp(bounds[0]));
    _opItem(Op.sto, indexItem);
    for (final (DataItem item, _) in driven) {
      _op(Op.cla, _Sym(() => tableBase, baseCell.value, Relocation.relative));
      _op(Op.sto, _blockWord(StorageBlock.pi, _indicator(item)));
    }
    final _Sym entry = _entrySym(clause.procedure);
    equ(bodyEntry, entry.value, operand: entry.text);
    // The transfer the EQU line precedes (the attested 00710), in the
    // `P+1` print; the back edge below prints the EQU name against
    // the same address.
    _op(Op.tra, entry);
    label(increment);
    // The increment block: step the index, step each indicator by its
    // stride, and take the D5.1 magnitude exit.
    _opItem(Op.cla, indexItem);
    _op(Op.add, _cp(bounds[1]));
    _opItem(Op.sto, indexItem);
    for (var i = 0; i < driven.length; i++) {
      final _Sym indicator = _blockWord(
        StorageBlock.pi,
        _indicator(driven[i].$1),
      );
      _op(Op.cla, _cp(strides[i]));
      _op(Op.add, indicator);
      _op(Op.sto, indicator);
    }
    _op(Op.cla, _cp(bounds[2]));
    _opItem(Op.sub, indexItem);
    _op(Op.tpl, _Sym(() => bodyEntry, entry.value, Relocation.relative));
    _callClears();
  }

  /// Records a DO of [procedure] from the paragraph and section open
  /// around it (D5.7): the ones whose returns this call could lose.
  void _doEdge(NameReference procedure, int clause) {
    _doEdges.add((
      callers: <String>[?_openParagraph, ?_openSection],
      target: procedure.text,
      at: procedure.anchor,
      clause: clause,
    ));
  }

  /// The D5.1 note (msg 946; M4-13): constant p, q and r whose index
  /// never steps from p to r exactly. Under the decoded magnitude exit
  /// that is every triple but q > 0, p ≤ r, and q dividing r − p: a
  /// zero or negative q with p ≤ r never terminates, p > r runs the
  /// body once, and an overshooting q exits past r.
  void _noteConstantParameters(DoIndex index) {
    final (int, int)? p = _constantBound(index.from);
    final (int, int)? q = _constantBound(index.by);
    final (int, int)? r = _constantBound(index.to);
    if (p == null || q == null || r == null) {
      return;
    }
    final int scale = [p.$2, q.$2, r.$2].reduce(math.max);
    int scaled((int, int) bound) =>
        bound.$1 * math.pow(10, scale - bound.$2).toInt();
    final int from = scaled(p);
    final int by = scaled(q);
    final int to = scaled(r);
    if (by > 0 && from <= to && (to - from) % by == 0) {
      return;
    }
    _report(
      msgLoopParametersDoNotStep,
      at: index.index.anchor,
      clause: _clauseNumber,
      operands: <String>[index.index.text],
    );
  }

  /// A compile-time constant bound as digits and scale: a numeric
  /// literal, or one under a minus. A name or any other form is not
  /// constant, and the note leaves it alone (D5.1).
  (int, int)? _constantBound(ArithExpr bound) => switch (bound) {
    LiteralOperand(:final literal)
        when literal.kind == TokenKind.numericLiteral =>
      _literalValue(literal),
    UnaryExpr(:final operator, operand: LiteralOperand(:final literal))
        when operator.text == '-' && literal.kind == TokenKind.numericLiteral =>
      switch (_literalValue(literal)) {
        (final int digits, final int scale) => (-digits, scale),
      },
    _ => null,
  };

  /// The D5.7 note (msg 947; M4-13), after the walk: a DO whose
  /// procedure can reach, through the DO chain, a procedure still open
  /// around the call — itself included — would overwrite that
  /// procedure's pending return. Static, over the text's own nesting.
  /// Runs once: the walk's end and a refusal both call it.
  void noteReentrantCalls() {
    if (!(checks?.pedantic ?? false) || _reentryNoted) {
      return;
    }
    _reentryNoted = true;
    final calls = <String, Set<String>>{};
    for (final _DoEdge edge in _doEdges) {
      for (final String caller in edge.callers) {
        calls.putIfAbsent(caller, () => <String>{}).add(edge.target);
      }
    }
    for (final _DoEdge edge in _doEdges) {
      final reachable = <String>{edge.target};
      final queue = <String>[edge.target];
      while (queue.isNotEmpty) {
        for (final String target in calls[queue.removeLast()] ?? const {}) {
          if (reachable.add(target)) {
            queue.add(target);
          }
        }
      }
      if (edge.callers.any(reachable.contains)) {
        _report(
          msgDoReentersActiveProcedure,
          at: edge.at,
          clause: edge.clause,
          operands: <String>[edge.target],
        );
      }
    }
  }

  /// The subscript base `NAME+0`, the entry a positional indicator is
  /// set from: the item's own first word.
  PoolHandle _subscriptBase(DataItem item) {
    final (int address, Relocation relocation) = _dataAddress(item);
    return _pool.base(
      '${_printedName(item)}+0',
      word: pzeWord(address: address),
      control: standardControl(Relocation.constant, relocation),
    );
  }

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

  /// The roster record [name] references. A GET or FILE record
  /// resolves through the environment binder, not the data resolver,
  /// so the roster is matched by name (M3-11).
  RecordInfo? _rosterRecord(String name) {
    for (final RecordInfo each in semantics.records) {
      if (each.name == name) {
        return each;
      }
    }
    return null;
  }

  /// The record's extent in whole words — the length the transmitting
  /// calls carry, never the BLOCKSIZE (the notes, section 2.6): its
  /// area's for a transmitted record, its character extent rounded up
  /// for a located one, which takes no area.
  int _recordWords(DataItem record) {
    for (final AreaInfo area in semantics.areas) {
      if (identical(area.root, record)) {
        return area.extentWords;
      }
    }
    return (_sem(record).storageChars + 5) ~/ 6;
  }

  /// The input buffer descriptor, `IOCTN* BL)n,,words`: prefix 5, the
  /// extent in the decrement, tag 6, the base locator in the address
  /// (the attested `5 00017 6 01667`; M4-20 item f).
  void _ioctn(int locator, int length) {
    final _Sym cell = _blockWord(StorageBlock.bl, locator);
    _emit(
      'IOCTN*',
      WordForm.prefix,
      () => '${cell.text()},,$length',
      () => (5 << 33) | (length << 18) | (6 << 15) | cell.value(),
      control: standardControl(Relocation.constant, cell.relocation),
    );
  }

  /// The output record descriptor, `IOST record,,words`: prefix 7, the
  /// extent in the decrement, the record's first word in the address —
  /// zero for a located record, whose word the LXA/SXA pair patches at
  /// run time (the attested `7 00017 0 00000` under GN)089).
  void _iost(String name, int length, int Function() address) => _emit(
    'IOST',
    WordForm.prefix,
    () => '$name,,$length',
    () => (7 << 33) | (length << 18) | address(),
    control: standardControl(Relocation.constant, Relocation.relative),
  );

  void _get(GetClause clause) {
    if (clause.recordFrom) {
      _unruled('GET RECORD FROM (no sample instance)');
    }
    final AtEndClause? atEnd = clause.atEnd;
    if (atEnd == null) {
      // E = 0: SYS)265 rides in the exit word ([J 90.02.29]), which no
      // sample site attests filled.
      _unruled('a GET with no AT END (notes section 7)');
    }
    final RecordInfo? info = _rosterRecord(clause.name.text);
    if (info == null) {
      _unruled('a GET of a name no FILE card lists (no sample instance)');
    }
    if (_duplicateFiles) {
      _unruled('a GET where two FILE cards share a name (no sample instance)');
    }
    if (info.inputFiles.length != 1) {
      // Zero files, or the two-input-file program behind msg 11.
      _unruled(
        'a GET record on ${info.inputFiles.length} input files '
        '(no sample instance)',
      );
    }
    final int? locator = _baseLocators[info.item];
    if (locator == null) {
      _unruled('a GET of a transmitted record (no sample instance)');
    }
    final String file = info.inputFiles.single;
    if (_fileCards[file]!.onError != null) {
      // ON ERROR replaces the SYS)283 exit with an unknown word (the
      // notes, section 7).
      _unruled('a GET from a file declaring ON ERROR (notes section 7)');
    }
    final (PoolHandle number, PoolHandle comma) = _stamp(
      _statement,
      _ordinals[clause] ?? 0,
    );
    final List<String> names =
        semantics.allocation?.clauseNames[clause] ?? const <String>[];
    _emit(
      // The stamp rides ahead of the call, prefixed TXH (M4-14).
      mnemonic(Op.txh),
      formOf(Op.txh),
      () => '${_cp(number).text()},0,${_cp(comma).text()}',
      () => typeAWord(
        Op.txh,
        decrement: _cp(comma).value(),
        address: _cp(number).value(),
      ),
      control: standardControl(Relocation.relative, Relocation.relative),
    );
    _tsxIoc(8);
    _pzePair(_fileSym(file), _sys(260));
    _pzePair(_labelSym(names[0]), _sys(283));
    _ioctn(locator, _recordWords(info.item));
    _op(Op.tra, _labelSym(names[1])); // Over the block, to the join.
    label(names[0]);
    if (atEnd.bareName != null) {
      _doEdge(atEnd.bareName!, clause.clause);
      _callTriple(atEnd.bareName!); // D6.6: compiled as DO name.
    } else if (atEnd.statement != null) {
      _clause(atEnd.statement!);
    }
    _callClears();
    label(names[1]); // The join, on the resume word.
  }

  void _file(FileClause clause) {
    if (clause.inFile != null) {
      _unruled('FILE record IN file (no sample instance)');
    }
    final RecordInfo? info = _rosterRecord(clause.record.text);
    if (info == null) {
      _unruled('a FILE of a name no FILE card lists (no sample instance)');
    }
    if (_duplicateFiles) {
      _unruled('a FILE where two FILE cards share a name (no sample instance)');
    }
    if (info.outputFiles.length != 1) {
      _unruled(
        'a FILE record on ${info.outputFiles.length} output files '
        '(no sample instance)',
      );
    }
    final String file = info.outputFiles.single;
    final int length = _recordWords(info.item);
    final int? locator = _baseLocators[info.item];
    if (locator != null) {
      // A located record's descriptor takes its address at run time:
      // the LXA/SXA pair writes the buffer word over the IOST's zero
      // address field (catalogue 4.2).
      final String patched = _mint();
      _generated += 1; // The pair's second name is never bound (M4-6).
      _op(Op.lxa, _blockWord(StorageBlock.bl, locator), tag: 4);
      _op(Op.sxa, _labelSym(patched), tag: 4);
      _tsxIoc(9);
      _pzePair(_fileSym(file), _Sym(() => '0', () => 0, Relocation.constant));
      label(patched);
      _iost(_printedName(info.item), length, () => 0);
    } else {
      _tsxIoc(9);
      _pzePair(_fileSym(file), _Sym(() => '0', () => 0, Relocation.constant));
      final _Ref ref = _ref(info.item);
      _iost(ref.text, length, () => ref.address);
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

  /// Which of [targets] holds [item]. The matcher builds every pair
  /// under one receiver, so the search always finds one.
  int _receiverIndex(List<NameReference> targets, DataItem item) =>
      Iterable<int>.generate(targets.length).firstWhere((int i) {
        final DataItem? receiver = _item(targets[i]);
        return receiver != null &&
            ancestorsOf(item).any((DataItem each) => identical(each, receiver));
      });

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

  /// The pictorial of an edited target. A field is edited because its
  /// pictorial holds an edit character, so the measurement is there.
  Pictorial _editedShape(DataItem target) => _sem(target).shape!;

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
      _name('SYS)267');
      _emit(
        mnemonic(Op.tra),
        formOf(Op.tra),
        () => 'SYS)267,0,0',
        () => typeBWord(Op.tra, address: 267),
        control: standardControl(Relocation.constant, Relocation.system),
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
    if (driven.isEmpty) {
      return; // Most moves drive no indicator at all.
    }
    // Both EQU lines print ahead of the update blocks — the attested
    // 01742 and 01743, back to back before LOC 01421.
    final blocks = <(PoolHandle stride, _Sym base, DataItem table)>[];
    for (final table in driven) {
      final PoolHandle stride = _tableStride(table);
      final int strideWords = _strideWords(table);
      final (int address, Relocation relocation) = _dataAddress(
        table,
        plus: -strideWords,
      );
      if (address < 0) {
        // The 15-bit address field would wrap a negative base to a
        // wrong word, silently.
        _unruled('a table base ahead of address zero (no sample instance)');
      }
      final PoolHandle base = _pool.base(
        '${_printedName(table)}-$strideWords',
        word: pzeWord(address: address),
        control: standardControl(Relocation.constant, relocation),
      );
      final String bound = _mint();
      _generated += 1; // The pair's second name is never bound (M4-6).
      equ(
        bound,
        () => _poolAddress(base),
        // The equate prints the pool entry and the update block prints
        // the name, which is what makes the name worth minting (notes
        // 6.2 item 32).
        operand: () => _cp(base).text(),
      );
      blocks.add((
        stride,
        _Sym(() => bound, () => _poolAddress(base), Relocation.relative),
        table,
      ));
    }
    // The subscript variable is the value; the block scales it by the
    // table's stride and offsets it by the table's base.
    final DataItem variable = _decimal(_item(target)!);
    for (final (PoolHandle stride, _Sym base, DataItem table) in blocks) {
      _opItem(Op.ldq, variable);
      _op(Op.mpy, _cp(stride));
      _xca();
      _op(Op.add, base);
      _op(Op.sto, _blockWord(StorageBlock.pi, _indicator(table)));
    }
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
    // The parser admits four figurative families (`figurativeConstants`),
    // and HIGH and LOW are above, so the rest is ZERO or BLANK.
    _txi(_zero(figurative) ? 244 : 243, extent);
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
    _store(target, _chain(clause.value), truncated: clause.truncated);
  }

  void _add(AddClause clause) {
    if (clause.truncated || clause.onOverflow != null) {
      _unruled('ADD TRUNCATED / ON OVERFLOW (notes section 7)');
    }
    if (clause.corresponding) {
      final List<(DataItem, DataItem)> pairs = _addOrder(
        clause.targets,
        semantics.correspondingPairs[clause] ?? const [],
      );
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
        // The non-binary operand fetch (catalogue 4.7): the register
        // convert of catalogue 4.6, then one word to park it. The
        // convert leaves its result in the accumulator, so the park is
        // `STO`, and the source is the one operand the targets follow.
        _setup(source, target: false);
        _editedFetch(source);
        final _Sym park = _resultCell(clause.targets.length);
        _op(Op.sto, park);
        _movpakClears();
        for (final NameReference target in clause.targets) {
          _addBody(_item(target)!, () => _op(Op.add, park));
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

  /// The edited-field-to-register convert ([J 90.02.30]): the MOVPAK
  /// entry, the fixed head, one step, and the terminator.
  ///
  /// A register target takes every source character, so the step list of
  /// catalogue 4.6 reduces to the move alone. Both counts are the
  /// source's digits: `NUMBER-OF-CHARACTERS-TO-CONVERT` as the edited
  /// runs already read it, and `TARGET-DECIMAL-NUMERIC-LENGTH` because
  /// the register receives exactly those digits (notes 6.2 item 18).
  void _editedFetch(DataItem source) {
    final int digits = _sem(source).digits;
    _tsx(182);
    _txi(268, 1);
    _txi(269, digits);
    _txi(275, digits);
  }

  /// The CORRESPONDING pairs in emission order: the target list runs
  /// backwards and each target keeps the matcher's order within it.
  ///
  /// Statement 208 attests the reversal — `INTERNAL.TOTALS` fills 00733
  /// to 00757 ahead of `MASTER TOTALS` at 00760, though MASTER is
  /// written first — and statement 218's plain ADD keeps its target
  /// order, so the reversal belongs to CORRESPONDING alone (M4-10).
  List<(DataItem, DataItem)> _addOrder(
    List<NameReference> targets,
    List<(DataItem, DataItem)> pairs,
  ) => <(DataItem, DataItem)>[
    for (var i = targets.length - 1; i >= 0; i--)
      for (final (DataItem, DataItem) pair in pairs)
        if (_receiverIndex(targets, pair.$2) == i) pair,
  ];

  /// One ADD unit: `CLA target / ADD source / STO target` with the
  /// guards the operands force. Every attested pair has equal scale;
  /// the store tail on an ADD has no site (notes section 7).
  void _addPair(DataItem source, DataItem target) {
    if (_sem(source).fractionDigits != _sem(target).fractionDigits) {
      _unruled('an ADD pair of unequal scales (notes section 7)');
    }
    final DataItem addend = _decimal(source);
    _loadBaseOf(addend);
    _addBody(target, () => _opItem(Op.add, addend));
  }

  void _addBody(DataItem target, void Function() addend) {
    final DataItem item = _decimal(target);
    _loadBaseOf(item);
    _opItem(Op.cla, item);
    addend();
    _opItem(Op.sto, item);
  }

  /// Emits the chain of [value] and returns what it computed and where.
  _Value _chain(ArithExpr value) {
    final List<(ArithExpr, Token?)> terms = _additiveTerms(value);
    if (terms.length == 1) {
      final ArithExpr term = terms.single.$1;
      switch (term) {
        case NameOperand(:final name):
          if (name.subscripts.isNotEmpty) {
            _unruled('a subscripted chain operand (no sample instance)');
          }
          final DataItem item = _decimal(_item(name)!);
          _loadBaseOf(item);
          _opItem(Op.cla, item);
          return (scale: _naturalScale(term), register: _Register.ac);
        case LiteralOperand(:final literal):
          // The one-term chain (notes 3.3).
          _op(Op.cla, _cp(_numericLiteral(literal)));
          return (scale: _naturalScale(term), register: _Register.ac);
        case BinaryExpr():
          return (scale: _product(term), register: _Register.mq);
        default:
          _unruled('a chain of ${term.runtimeType} (no sample instance)');
      }
    }
    var chainScale = 0;
    for (final (ArithExpr term, _) in terms) {
      final int scale = _naturalScale(term);
      chainScale = scale > chainScale ? scale : chainScale;
    }
    // One entry per term: the word the assembly emits for it, with the
    // guard that word must carry. The NET sentence pins the placement:
    // the guard for `1)BONDEDUCTION` sits at 00727, between the fifth
    // `SUB` and its own, not ahead of the `CLA` at 00722.
    final assembly = <void Function(Op op)>[];
    for (var i = 0; i < terms.length; i++) {
      final ArithExpr term = terms[i].$1;
      // The sample's chains never subscript a term, so the multi-term
      // arms refuse one exactly as the single-term arm above does.
      if (term case NameOperand(:final name) when name.subscripts.isNotEmpty) {
        _unruled('a subscripted chain operand (no sample instance)');
      }
      final int deficit = chainScale - _naturalScale(term);
      // The cell a computed term parks in: the count of the chain's
      // operands that follow it in source order (M4-10).
      final int cell = terms.length - 1 - i;
      switch (term) {
        case NameOperand(:final name) when deficit == 0:
          final DataItem item = _decimal(_item(name)!);
          assembly.add((Op op) {
            _loadBaseOf(item);
            _opItem(op, item);
          });
        case LiteralOperand(:final literal) when deficit == 0:
          final _Sym at = _cp(_numericLiteral(literal));
          assembly.add((Op op) => _op(op, at));
        case NameOperand() || LiteralOperand():
          // The scale alignment: a run-time multiply against a separate
          // pool word, never a folded literal (catalogue 4.7), parked.
          if (term case LiteralOperand(:final literal)) {
            _op(Op.ldq, _cp(_numericLiteral(literal)));
          } else if (term case NameOperand(:final name)) {
            final DataItem item = _decimal(_item(name)!);
            _loadBaseOf(item);
            _opItem(Op.ldq, item);
          }
          _op(Op.mpy, _cp(_pool.machineWord(_pow10(deficit))));
          assembly.add(_park(cell, _Register.mq));
        case BinaryExpr() when _additive(term):
          final _Value inner = _chain(term); // The sub-chain, then its park.
          if (inner.scale < chainScale) {
            // An additive sub-chain finishes in the accumulator, which
            // no one word aligns: `MPY` reads the MQ half. The sample
            // never writes one (M4-10).
            _unruled('a scale alignment of a sub-chain (no sample instance)');
          }
          assembly.add(_park(cell, inner.register));
        case BinaryExpr():
          _product(term); // The product, then its alignment and park.
          if (deficit > 0) {
            // The product is in the MQ, so one more multiply aligns it.
            _op(Op.mpy, _cp(_pool.machineWord(_pow10(deficit))));
          }
          assembly.add(_park(cell, _Register.mq));
        default:
          _unruled('a chain of ${term.runtimeType} (no sample instance)');
      }
    }
    // The assembly: one CLA, then ADD or SUB each.
    for (var i = 0; i < assembly.length; i++) {
      final Token? operator = terms[i].$2;
      assembly[i](
        operator == null
            ? Op.cla
            : operator.text == '-'
            ? Op.sub
            : Op.add,
      );
    }
    return (scale: chainScale, register: _Register.ac);
  }

  /// Parks a computed term in result-storage cell [cell] and returns the
  /// word the assembly reads it back with. The park names the register
  /// the value sits in: `STQ` after a multiply, `STO` after a chain.
  void Function(Op op) _park(int cell, _Register register) {
    _op(
      register == _Register.mq ? Op.stq : Op.sto,
      _resultCell(cell, offset: cell != 0 && register == _Register.mq),
    );
    final _Sym read = _resultCell(cell);
    return (Op op) => _op(op, read);
  }

  bool _additive(BinaryExpr expr) =>
      expr.operator.text == '+' || expr.operator.text == '-';

  /// Flattens the left-associative additive spine into its terms, each
  /// with the operator that joins it. The first term has none.
  List<(ArithExpr, Token?)> _additiveTerms(ArithExpr expr) {
    if (expr is BinaryExpr && _additive(expr)) {
      return <(ArithExpr, Token?)>[
        ..._additiveTerms(expr.left),
        (expr.right, expr.operator),
      ];
    }
    return <(ArithExpr, Token?)>[(expr, null)];
  }

  /// A `*` node: the complex side first, then the two-word step
  /// (catalogue 4.7). Returns the product's scale, the factor sum. A
  /// product always finishes in the MQ.
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
      final void Function(Op) first = _leafOperand(left);
      final void Function(Op) second = _leafOperand(right);
      // `MPY` takes a name wherever one factor is a literal, so the
      // `LDQ` takes the literal — `LDQ CP)+12 / MPY EXEMPTIONS,1` at
      // 01221 — and the right factor when neither is one, as
      // `LDQ 1)RATE,1 / MPY 3)HOURS` at 00641 shows.
      final leftLoads = left is LiteralOperand;
      (leftLoads ? first : second)(Op.ldq);
      (leftLoads ? second : first)(Op.mpy);
      return _naturalScale(left) + _naturalScale(right);
    }
    if (!leftLeaf && !rightLeaf) {
      _unruled('a product of two computed factors (no sample instance)');
    }
    final complex = leftLeaf ? right : left;
    final leaf = leftLeaf ? left : right;
    final int scale = switch (complex) {
      TruthExpr() => _truthFunction(complex),
      BinaryExpr() => _accumulated(_chain(complex)),
      _ => _unruled('a factor of ${complex.runtimeType}'),
    };
    final void Function(Op) factor = _leafOperand(leaf);
    // The step onto the finished value: `XCA` moves it to the MQ half,
    // then the factor's own word multiplies.
    _xca();
    factor(Op.mpy);
    return scale + _naturalScale(leaf);
  }

  /// The scale of a complex factor, which the `XCA` step requires in the
  /// accumulator. A chain of one product finishes in the MQ instead, and
  /// the sample never writes one (M4-10).
  int _accumulated(_Value value) => value.register == _Register.ac
      ? value.scale
      : _unruled('a product of a product (no sample instance)');

  /// Prepares [leaf] as a factor and returns the emitter of the word
  /// that addresses it, guard and all. A literal takes a pool entry and
  /// needs no guard.
  void Function(Op op) _leafOperand(ArithExpr leaf) {
    switch (leaf) {
      case LiteralOperand(:final literal):
        final _Sym at = _cp(_numericLiteral(literal));
        return (Op op) => _op(op, at);
      case NameOperand(:final name):
        if (name.subscripts.isNotEmpty) {
          _unruled('a subscripted factor (no sample instance)');
        }
        final DataItem item = _decimal(_item(name)!);
        return (Op op) {
          _loadBaseOf(item);
          _opItem(op, item);
        };
      default:
        _unruled('a factor of ${leaf.runtimeType}');
    }
  }

  /// The truth function (catalogue 4.7): one head word, the comparison
  /// with its true outcome falling through, and the four-word tail that
  /// ends on `CLA` of the true value. Eleven words at its one site.
  ///
  /// The frame works in the lowest sense indicator. `RIR` clears every
  /// indicator, the true outcome falls past the `SIR` that sets that
  /// one, `PXA 0,0` clears the accumulator, and `RFT` skips the `CLA`
  /// when the indicator is still off. The value is 0 or 1 in the
  /// accumulator, so the caller's `XCA` step reads it there.
  int _truthFunction(TruthExpr expr) {
    final _Sym one = _cp(_pool.seed(1));
    _senseIndicator(Op.rir, _everyIndicator);
    // The true outcome falls into the `SIR`; the false outcomes land
    // one word past the vector, on the `PXA` beyond it.
    _compare(
      expr.condition,
      trueTo: const _Cont.falls(),
      falseTo: const _Cont.falls(1),
    );
    _senseIndicator(Op.sir, _truthIndicator);
    _pxa();
    _senseIndicator(Op.rft, _truthIndicator);
    _op(Op.cla, one);
    return 0;
  }

  /// The eighteen sense indicators, and the one the truth function uses.
  static const int _everyIndicator = 0x3FFFF;
  static const int _truthIndicator = 0x1;

  /// The store: one word on equal scale, the five-word scaling tail
  /// otherwise — `XCA / ACL half / LRS 35 / DVP scale / STQ`, the
  /// half-adjust suppressed under TRUNCATED (catalogue 4.7; D4.1).
  void _store(NameReference target, _Value value, {required bool truncated}) {
    if (target.subscripts.isNotEmpty) {
      _unruled('a subscripted SET target (no sample instance)');
    }
    final DataItem item = _decimal(_item(target)!);
    final int targetScale = _sem(item).fractionDigits;
    if (value.scale == targetScale) {
      _loadBaseOf(item);
      _opItem(value.register == _Register.mq ? Op.stq : Op.sto, item);
      return;
    }
    if (value.scale < targetScale) {
      _unruled('a store below the target scale (no sample instance)');
    }
    if (value.register != _Register.mq) {
      // The tail opens on `XCA`, which reads the MQ half, so it scales a
      // product and nothing else. Every attested site is one (M4-10).
      _unruled('a scaling store of a chain value (no sample instance)');
    }
    final int divisor = _pow10(value.scale - targetScale);
    // The half-adjust is referenced first, so it pools first.
    final _Sym? half = truncated ? null : _cp(_pool.machineWord(divisor ~/ 2));
    final _Sym scale = _cp(_pool.machineWord(divisor));
    _loadBaseOf(item);
    _xca();
    if (half != null) {
      _op(Op.acl, half);
    }
    _shift(Op.lrs, _storeShift);
    _op(Op.dvp, scale);
    _opItem(Op.stq, item);
  }

  /// `LRS 35` leaves the whole product in the MQ half, which is what
  /// `DVP` divides.
  static const int _storeShift = 35;

  // --- IF and the comparisons (catalogue 4.8) -----------------------------

  void _if(IfClause clause) {
    final List<String> names =
        semantics.allocation?.clauseNames[clause] ?? const <String>[];
    final bool otherwise = clause.otherwiseArm.isNotEmpty;
    _compare(
      clause.condition,
      trueTo: const _Cont.falls(),
      // The false outcomes go to the OTHERWISE arm's own label, not to
      // the join (notes 4.8).
      falseTo: _Cont.named(otherwise ? names.first : names.last),
    );
    clause.thenArm.forEach(_clause);
    if (otherwise) {
      if (!_endsInGoTo(clause.thenArm)) {
        // The THEN-arm join transfer (notes 3.3).
        _op(Op.tra, _labelSym(names.last));
      }
      label(names.first); // The OTHERWISE arm's own label (M3-8).
      clause.otherwiseArm.forEach(_clause);
    }
    label(names.last); // The join, on whatever word follows.
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
  /// skip vector. [trueTo] and [falseTo] carry each outcome's
  /// continuation into the vector's slots (catalogue 4.8).
  void _compare(
    CondExpr condition, {
    required _Cont trueTo,
    required _Cont falseTo,
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
        trueTo: trueTo,
        falseTo: falseTo,
      );
    } else {
      _numericComparison(
        acc,
        storage,
        relation,
        rightInAccumulator,
        trueTo: trueTo,
        falseTo: falseTo,
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
    required _Cont trueTo,
    required _Cont falseTo,
  }) {
    switch (acc) {
      case LiteralOperand(:final literal) when _literalValue(literal).$1 != 0:
        _unruled('a nonzero literal comparand (no sample instance)');
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
          _unruled('a subscripted accumulator comparand (no sample instance)');
        }
        _loadBaseOf(item);
        _opItem(Op.cla, item);
      default:
        _unruled('a comparison of ${acc.runtimeType}');
    }
    switch (storage) {
      case LiteralOperand(:final literal):
        _op(Op.cas, _cp(_numericLiteral(literal)));
      case NameOperand(:final name):
        final DataItem item = _decimal(_item(name)!);
        if (name.subscripts.isNotEmpty) {
          final int register = _indicatorPrologue(item);
          // The element the indicator addresses: `CAS 0,r`, the word
          // the register alone reaches (the attested 01412).
          _op(
            Op.cas,
            _Sym(() => '0', () => 0, Relocation.constant),
            tag: register,
          );
        } else {
          _loadBaseOf(item);
          _opItem(Op.cas, item);
        }
      default:
        _unruled('a comparison of ${storage.runtimeType}');
    }
    _vector(relation, mirrored, trueTo: trueTo, falseTo: falseTo);
  }

  /// The positional-indicator prologue of a subscripted comparand:
  /// `LAC PI)n,r / TXL SYS)294,r,0` (the attested 01410–01411). The
  /// register map keys the indicator negated, so it never collides
  /// with a locator, and the register leaves the cache: it holds the
  /// element address now, not a base.
  int _indicatorPrologue(DataItem array) {
    final int indicator = _indicator(array);
    final int register = _assignRegister(-indicator);
    _registerHolds.remove(register);
    _op(Op.lac, _blockWord(StorageBlock.pi, indicator), tag: register);
    _trap(register);
    return register;
  }

  bool _zero(Token figurative) => figurative.text.startsWith('ZERO');

  /// The zero side of a numeric comparison, built and scaled to the
  /// storage operand: `LDQ` the pooled zero, `MPY` the scale, `XCA`
  /// (the attested 00656–00660 and 01241–01243). Both attested sites
  /// scale, so the unscaled variant has no generated form.
  void _zeroBuild(ArithExpr storage) {
    final int deficit = _operandScale(storage);
    if (deficit == 0) {
      _unruled('an unscaled zero comparand (no sample instance)');
    }
    final _Sym zero = _cp(_pool.seed(0));
    final _Sym scale = _cp(_pool.machineWord(_pow10(deficit)));
    _op(Op.ldq, zero);
    _op(Op.mpy, scale);
    _xca();
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
    required _Cont trueTo,
    required _Cont falseTo,
  }) {
    // Both attested operands are alphameric (statement 200); a class
    // mix rides in below the stop severity (msg 107,00) and refuses.
    for (final operand in <ArithExpr>[acc, storage]) {
      if (operand case NameOperand(:final name)) {
        if (name.subscripts.isNotEmpty) {
          _unruled('a subscripted alphameric comparand (no sample instance)');
        }
        final FieldClass fieldClass = _moveClass(_item(name)!);
        if (fieldClass != FieldClass.alphameric) {
          _unruled(
            'an alphameric comparison of ${fieldClass.name} '
            '(no sample instance)',
          );
        }
      }
    }
    // Every attested pair compares equal lengths inside one word. The
    // D3.3 fold and the D5.3 truncation each wait for a site, and the
    // longer field takes the SYS)162 path M4-11 leaves to a later
    // chunk, the compound-condition precedent.
    if (_compareChars(acc) != _compareChars(storage)) {
      _unruled('an unequal-length alphameric comparison (no sample instance)');
    }
    if (_compareChars(acc) > 6) {
      _unruled('a comparison past one word (M4-11, the SYS)162 boundary)');
    }
    switch (acc) {
      case FigurativeOperand(word: final figurative):
        if (!figurative.text.startsWith('HIGH')) {
          _unruled('this figurative comparison (no sample instance)');
        }
        _op(Op.cal, _cp(_pool.machineWord(_highValueWord)));
      case NameOperand(:final name):
        _loadBaseOf(_item(name)!);
        _opItem(Op.cal, _item(name)!);
        _emitExtraction(name);
      default:
        _unruled('a comparison of ${acc.runtimeType}');
    }
    var flip = mirrored;
    if (!_extracted(storage)) {
      if (storage case NameOperand(:final name)) {
        _loadBaseOf(_item(name)!);
        _opItem(Op.las, _item(name)!);
      } else {
        // A literal or figurative here would need a pool word no
        // sample site attests.
        _unruled('a comparison of ${storage.runtimeType}');
      }
    } else {
      final operand = storage as NameOperand;
      _op(Op.slw, _resultCell(0)); // The spill (the attested RS)0).
      _loadBaseOf(_item(operand.name)!);
      _opItem(Op.cal, _item(operand.name)!);
      _emitExtraction(operand.name);
      _op(Op.las, _resultCell(0));
      // The spill swaps the machine's sides: the accumulator now holds
      // the storage operand and the cell the spilled one, so the
      // outcomes mirror (LAS reads the accumulator against storage —
      // 22-6528-4, external).
      flip = !flip;
    }
    _vector(relation, flip, trueTo: trueTo, falseTo: falseTo);
  }

  /// `OCT 747474747474` — the attested HIGH.VALUE word, `CP)+23`.
  static const int _highValueWord = 0xF3CF3CF3C;

  /// The character length a comparand compares: its field's, or the
  /// full word of a figurative constant.
  int _compareChars(ArithExpr operand) => switch (operand) {
    NameOperand(:final name) => _sem(_item(name)!).storageChars,
    _ => 6,
  };

  bool _extracted(ArithExpr operand) {
    if (operand case NameOperand(:final name)) {
      final ItemSemantics sem = _sem(_item(name)!);
      return sem.byte != 0 || sem.storageChars < 6;
    }
    return false;
  }

  /// The extraction: `LGL` six bits a character brings the field to
  /// character 0, and the mask extracts characters 0 on (the attested
  /// `LGL 18` and `CP)+30`, shared by both operands of statement 200).
  void _emitExtraction(NameReference name) {
    final ItemSemantics sem = _sem(_item(name)!);
    if (sem.byte != 0) {
      _shift(Op.lgl, 6 * sem.byte);
    }
    if (sem.storageChars < 6) {
      _op(
        Op.ana,
        _cp(_pool.machineWord(_extractMask(0, sem.storageChars - 1))),
      );
    }
  }

  /// The vector: one `TRA` slot per outcome in greater, equal, less
  /// order ([J 90.02.12]), each printing its continuation's symbol
  /// when the generator holds one and the relative form otherwise
  /// (M4-11 as amended, chunk B1). Only the trailing slot can drop —
  /// when the less continuation is the next word to be emitted
  /// (catalogue 4.8).
  void _vector(
    Relation relation,
    bool mirrored, {
    required _Cont trueTo,
    required _Cont falseTo,
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
    final slots = <_Cont>[
      for (final _Outcome outcome in _Outcome.values)
        trueSet.contains(outcome) ? trueTo : falseTo,
    ];
    final _Cont less = slots.last;
    final count = less.name == null && less.extra == 0 ? 2 : 3;
    for (var i = 0; i < count; i++) {
      final String? name = slots[i].name;
      if (name != null) {
        _op(Op.tra, _labelSym(name));
        continue;
      }
      final int distance = count + slots[i].extra - i;
      final int target = _location + distance;
      _op(Op.tra, _Sym(() => '*+$distance', () => target, Relocation.relative));
    }
  }

  int _naturalScale(ArithExpr expr) => switch (expr) {
    NameOperand(:final name) => _sem(_item(name)!).fractionDigits,
    LiteralOperand(:final literal) => _literalValue(literal).$2,
    TruthExpr() => 0,
    BinaryExpr(:final left, :final right) when expr.operator.text == '*' =>
      _naturalScale(left) + _naturalScale(right),
    BinaryExpr() when _additive(expr) =>
      _additiveTerms(expr)
          .map(((ArithExpr, Token?) term) => _naturalScale(term.$1))
          .reduce((int a, int b) => a > b ? a : b),
    _ => _unruled('the scale of ${expr.runtimeType}'),
  };
}
