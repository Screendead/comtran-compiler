## 1. LOADED PROGRAM

`loadDeck` returns `LoadedProgram`, declared at `/Users/jacklusher/development/comtran-compiler/lib/src/loader/loader.dart:94-123`:

```dart
/// A loaded program: its words by address, and the entry point.
final class LoadedProgram {
  const LoadedProgram({
    required this.deckName,
    required this.origin,
    required this.entry,
    required this.words,
    required this.files,
    required this.cardsRead,
  });

  final String deckName;

  /// The address of relative location zero.
  final int origin;

  /// The absolute entry point (D2.1).
  final int entry;

  /// Every word the text placed, by absolute address. Reservations
  /// place nothing.
  final Map<int, int> words;

  /// The files in `*FILE` card order.
  final List<LoaderFile> files;

  /// The cards consumed, `*CTEND` included; a second deck starts at
  /// the next card.
  final int cardsRead;
}
```

Field by field:

| Field | Dart type | Meaning |
|---|---|---|
| `deckName` | `String` | Columns 1-6 of the `*CTEXT` card, `loader.dart:213` `_deckName = deckName;`. Blank for a `*COMPILE` job — `loader_test.dart:72` `expect(program.deckName, '');` |
| `origin` | `int` | The caller's `origin` argument echoed back; `loader.dart:138` `_Loader(cards, origin, resolve).load()` |
| `entry` | `int` | **Absolute**, already origin-added: `loader.dart:246` `return _relative(Word36.address(word));`, and `loader.dart:343` `int _relative(int field) => _fits(field + _origin);` |
| `words` | `Map<int, int>` **keyed by absolute address**, value = the 36-bit word | Built at `loader.dart:147` `final Map<int, int> _words = {};`, filled at `loader.dart:365-367` `void _place(int location, int word) { _words[_fits(location)] = word; }`. Not a `List`; sparse. A reservation (`PTW`) advances the counter and places nothing — `loader.dart:306-311` handles `2 => location + address`. Handed out live, not copied and not unmodifiable (`loader.dart:165` `words: _words,`) |
| `files` | `List<LoaderFile>` | `*FILE`/`*SPEC` data for M5's IOCS; `LoaderFile` at `loader.dart:59-92` |
| `cardsRead` | `int` | Cards consumed including `*CTEND`; `loader.dart:168` `cardsRead: _index,` |

The signature: `loader.dart:134-138`

```dart
LoadedProgram loadDeck(
  List<CardImage> cards, {
  required SystemReferenceResolver resolve,
  int origin = 0,
}) => _Loader(cards, origin, resolve).load();
```

Failure mode is `LoadError` (`loader.dart:23-36`), carrying a message and a one-based card number.

## 2. SYSTEM REFERENCES

**The 90.03 word form.** The control group of a data word is `1 AB CD` — `comtran-manuals/J28-6169/90.03-object-deck-format.md:186-197`:

```
AB = 00   constant decrement
   = 01   relative decrement
   = 10   the decrement is a system reference
   = 11   the decrement is represented by a complex expression
```
> "CD has the corresponding code values describing the address. The prefix and tag of a standard word are constant."

The field so marked is a 15-bit code — `90.03-object-deck-format.md:205-215`:

> "Each of these references is a 15-bit code. The high-order bits are used to distinguish between types of reference, while the low-order part of the field gives the reference number."
> `0000   system reference (11-bit system reference number follows).`
> `0001   file reference (11-bit file index number follows).`
> `0010 ⎫ 0011 ⎬  these codes are not assigned. 10 ⎭`

So: **bits 14-11 carry the type, bits 10-0 the number.** The loader decodes exactly that, `loader.dart:345-356`:

```dart
  int _system(int code) {
    final SystemReference reference = switch (code >> 11) {
      0 => SystemReference(file: false, number: code & 0x7FF),
      1 => SystemReference(file: true, number: code & 0x7FF),
      _ => throw LoadError(
        'system reference type '
        '${(code >> 11).toRadixString(2).padLeft(4, '0')}',
        card: _card,
      ),
    };
    return _fits(_resolve(reference));
  }
```

**The resolver interface**, `loader.dart:38-55`:

```dart
/// A system reference ([J 90.03.05]): the 15-bit code's type in its
/// high four bits — `0000` a system reference, `0001` a file reference
/// — and the number in the low eleven.
final class SystemReference {
  const SystemReference({required this.file, required this.number});

  /// Whether the reference names a file rather than a system routine.
  final bool file;

  /// The system reference number, or the file number.
  final int number;

  /// The 15-bit code as the text carries it.
  int get code => (file ? 0x800 : 0) | number;
}

/// Maps a system reference to the 15-bit address it stands for.
typedef SystemReferenceResolver = int Function(SystemReference reference);
```

**The round-trip test's two resolvers**, `test/loader_test.dart:16-21`:

```dart
/// The raw 15-bit code, so a loaded word at origin zero is the listing's.
int _raw(SystemReference reference) => reference.code;

/// System routines at 70000 octal, file blocks at 60000 octal.
int _table(SystemReference reference) =>
    (reference.file ? _octal('60000') : _octal('70000')) + reference.number;
```

`_raw` is an identity that lets the origin-0 load reproduce the listing byte for byte. `_table` is the only existing example of a real dispatch table: system routines based at 0o70000, file blocks at 0o60000.

**What stage 4 must supply, precisely.** Not a `(type, code)` pair — a single-argument `int Function(SystemReference)`. The argument is one bool (`file`) plus one 11-bit `number` (0-2047). The return must be an absolute machine address that survives `_fits`, `loader.dart:358-363`:

```dart
  int _fits(int address) {
    if (address < 0 || address >= MachineState.memoryWords) {
      throw LoadError('address $address is outside core', card: _card);
    }
    return address;
  }
```

`MachineState.memoryWords = 32768` (`lib/src/emulator/machine_state.dart:14`), so the return is effectively a 15-bit address. The resolver runs eagerly, once per occurrence, at load time; `loader.dart:355` calls it with no try/catch, so an exception the resolver throws escapes `loadDeck` un-wrapped rather than becoming a `LoadError`.

**The load-bearing fact for stage 4: `SYS)n` and `IOC)n` are indistinguishable at the resolver.** Both punch as type `0000` with the raw number in the low bits. Compare `lib/src/codegen/procedure.dart:539-548` (`TSX SYS)nnn,4`):

```dart
      () => typeBWord(Op.tsx, tag: 4, address: sys),
      control: standardControl(Relocation.constant, Relocation.system),
```

with `procedure.dart:551-560` (`TSX IOC)n,4`):

```dart
      () => typeBWord(Op.tsx, tag: 4, address: entry),
      control: standardControl(Relocation.constant, Relocation.system),
```

and `lib/src/codegen/blocks.dart:74-79` (the `PZE IOC)29` pointer word):

```dart
      operand: i == 0 ? 'IOC)29' : '0',
      ...
      word: i == 0 ? pzeWord(address: 29) : 0,
      control: i == 0
          ? standardControl(Relocation.constant, Relocation.system)
```

`test/fixtures/90.05-object-code-notes.md:110` states the rule: "`SYS)n` and `IOC)n` each assemble to absolute address `n`." Only a *file* name carries type `0001` — `procedure.dart:638-639`:

```dart
  _Sym _fileSym(String name) =>
      _Sym(() => name, () => 0x800 + _fileOrdinals[name]!, Relocation.system);
```

So the dispatch table is a **single shared number space** keyed on `number` when `file` is false. The M4-17 ranges are disjoint in practice — IOC)1-54 and SYS)128-296, `docs/design/m4-codegen.md:901-908` — but nothing in the loader, in `loader.md`, or in `m4-codegen.md` enforces or even names that disjointness.

## 3. WHERE THE RESOLVED ADDRESS LANDS

**In whichever of the two 15-bit fields the group's AB/CD marks `10` — independently, and never in the prefix or tag.** `loader.dart:324-341`:

```dart
  /// A standard word `1 AB CD` with its decrement and address relocated
  /// by their classes ([J 90.03.04]).
  int _relocated(int word, int group) {
    final int decrement = _field15(Word36.decrement(word), (group >> 2) & 3);
    final int address = _field15(Word36.address(word), group & 3);
    const int fields = (Word36.fieldMask15 << 18) | Word36.fieldMask15;
    return (word & ~fields) | (decrement << 18) | address;
  }

  int _field15(int field, int relocation) => switch (relocation) {
    0 => field,
    1 => _relative(field),
    2 => _system(field),
    _ => throw LoadError(
      'a complex expression, which the compiler never punches',
      card: _card,
    ),
  };
```

`Word36.decrement(word) => (word >> 18) & fieldMask15` and `Word36.address(word) => word & fieldMask15` (`lib/src/emulator/word.dart:51,57`); the `~fields` mask preserves prefix (bits 33-35) and tag (bits 15-17).

`TSX SYS)nnn,4` carries control group `10010`: AB=`00` constant decrement, CD=`10` system address. **Address field only.** The round-trip test proves it, `test/loader_test.dart:89-90`:

```dart
      // LOC 00165 `TSX SYS)175,4`, control 10010: the table's address.
      expect(program.words[_octal('10165')], _octal('007400470257'));
```

Decoding `0074 00 4 70257`: opcode 0074 (TSX), tag 4 intact, address 0o70257 = 0o70000 + 175. The tag survived the rewrite.

Both fields relocate when both are marked. `test/loader_test.dart:91-93`:

```dart
      // LOC 00201 `PZE INPUTMASTER,,SYS)260`, control 11010: a file
      // reference in the address, a system reference in the decrement.
      expect(program.words[_octal('10201')], _octal('070404060001'));
```

Group `11010` is AB=`10` (system decrement), CD=`10` (system address): decrement 0o70404 = 0o70000 + 260, address 0o60001 = 0o60000 + file 1.

## 4. ENTRY POINT

**The 01111 group.** `lib/src/codegen/text_model.dart:56-58`:

```dart
  /// The end-of-text entry, whose address field holds the relative
  /// program entry point; the CNTRL column prints `01111`.
  static const int endOfText = 0x0F;
```

The loader consumes it at `loader.dart:241-247`:

```dart
        if (group == ControlGroup.endOfText) {
          if (i + 1 != count) {
            throw LoadError('words follow the end-of-text entry', card: _card);
          }
          _index++;
          return _relative(Word36.address(word));
        }
```

Note: the loader reads the **address field only and ignores the word's prefix**. Codegen's choice of the `MON` prefix is therefore cosmetic to the loader.

**Where the end-of-text entry is generated** — `lib/src/codegen/codegen.dart:145-156`, the last unit of every program:

```dart
      // The end-of-text line ([J 90.03.04]): the word's address field
      // holds the relative program entry point — `GN)000`, the name
      // the procedure walk binds to its first text word (D2.1). The
      // manual leaves the prefix open; the attested word 500000000165
      // carries the `MON` prefix, printed solid.
      AssemblyUnit(
        operation: 'START',
        operand: 'GN)000',
        location: dataWords,
        word: counterWord(CounterOp.relativeOrigin, dataWords),
        control: ControlGroup.endOfText,
      ),
```

`dataWords` is hard-coded as the entry: the first word after the data areas, i.e. the first procedure word. The name `GN)000` is bound by the procedure walk at `lib/src/codegen/procedure.dart:111`: `text.label('GN)000'); // The entry word's name (D2.1; M3-8).`

**The gap, stated in the design record** — `docs/design/loader.md:155-157`:

> "**One gap stays open.** The code generator's end-of-text entry names `GN)000` for every program. D2.1 asks for a labeled PROGRAM.START to name the entry instead. Stage 4, the first stage to run a program, lands it."

**What D2.1 says.** `docs/design/decisions.md:452-455`:

> "### D2.1 — PROGRAM.START — an undocumented entry-point facility
> **Status.** Locked.
> **Decision.** PROGRAM.START is implemented as a reserved procedure-name. Labeling a statement or section with it designates the object-program entry point. At most one PROGRAM.START is allowed per program (msg 141 "MORE THAN ONE -PROGRAM.START-. FIRST USED." on a second occurrence, first one wins, compilation continues); it must label a statement or section (msg 142 otherwise) and is never DO-addressable (msg 143 otherwise). Absent PROGRAM.START, codegen itself resolves the entry point to the LOC of the first \*PROCEDURE sentence. In both cases codegen punches that LOC in the object deck's end-of-text special entry, control group 01111, whose data-word address "contains the relative program entry point" ([J 90.03.04]). The Loader's own default start point — first program of combined segments, overridable by a \*START card ([J 03.02.08]) — is a distinct mechanism and is not relied on for this."

And its amendment, `decisions.md:465`:

> "*Amended 2026-08-30 (M4 stage 3, `docs/design/loader.md` LD-3).* The loader consumes the 01111 entry as decided. The generator names the first \*PROCEDURE sentence as the entry point of every program. It does not yet honor a labeled PROGRAM.START; that path waits for stage 4, where a program first runs."

**How much of D2.1 is already built.** The parser recognises the label and issues all three diagnostics: `lib/src/lexer/reserved_words.dart:178` `const String programStartName = 'PROGRAM.START';`; `lib/src/parser/procedure_parser.dart:148-155` records the label and reports msg 141 on a duplicate; `procedure_parser.dart:126-132` reports msg 143 for a DO target; `lib/src/data/resolver.dart:116-117` carries msg 142 ("PROGRAM.START may only label a statement or section (D2.1)."). But `_programStartLabels` (`procedure_parser.dart:99`) is a private parser field consumed only for diagnostics — grep for `programStart` across `lib/src` hits only `lexer/reserved_words.dart`, `parser/procedure_parser.dart` and `data/resolver.dart`. Nothing carries the labeled statement's location to codegen, and `codegen.dart:153` unconditionally writes `location: dataWords`. Stage 4 must plumb the resolved location from the parse to that one `AssemblyUnit`.

## 5. THE ROUND-TRIP TEST

`test/loader_test.dart`. Fixtures come from `test/support/deck_fixtures.dart:24-28`:

```dart
const String jobDeckPath = 'test/fixtures/90.05-payroll-job.ctd';

/// Loads the canon 90.05 job deck (294 cards).
List<CardImage> loadJobDeck() =>
    decodeCanon(File(jobDeckPath).readAsBytesSync());
```

Setup, `loader_test.dart:55-58` — compile in process, then punch the object deck:

```dart
    setUpAll(() {
      job = compileDeck(loadJobDeck()).jobs.single;
      deck = jobDeck(job, _options)!;
    });
```

**At origin 0**, `loader_test.dart:60-74`:

```dart
    test("at origin zero memory is the listing's word image", () {
      final LoadedProgram program = loadDeck(deck.cards, resolve: _raw);
      final image = <int, int>{
        for (final AssemblyUnit unit in job.codegen!.units)
          if (unit.control case final int control
              when control >= ControlGroup.constantWord)
            unit.location!: unit.word!,
      };
      expect(program.words, image);
      expect(program.words, hasLength(936));
      expect(program.entry, _octal('165'));
      expect(program.origin, 0);
      expect(program.deckName, '');
      expect(program.cardsRead, 67);
    });
```

The oracle is the generator's own units filtered to `control >= ControlGroup.constantWord` (0x10), i.e. only standard data words. The 936 is not the whole deck: `docs/design/loader.md:69` says "the sample's 961 deck words at 19 a card are 51 cards". The 25-word difference is the entries the loader never places — the `00001` location-counter entries and the one `01111` end-of-text entry (`loader.dart:248-259` places only when `group & 0x10 != 0`). Exact split of the 25 between the two kinds: unverified.

**At origin 0o10000 (4096 decimal)**, `loader_test.dart:76-99`: entry moves to 0o10165, relative fields shift by the origin, and `_table`'s addresses land in the system fields. The four word assertions are quoted in section 3 above, plus `loader_test.dart:96-98`:

```dart
      // The pointer words under `ORG BL)1`: `PZE IOC)29` at 01666.
      expect(program.words[_octal('11666')], _octal('70035'));
      expect(program.words[_octal('11667')], 0);
```

0o70035 = 0o70000 + 29 — confirming `IOC)29` came through the resolver as `file: false, number: 29`, the same shape a `SYS)29` would take.

**Can stage 4 reuse the fixture?** Loading, yes. Running, no.

- The load half needs no new plumbing: the deck is built in process (`compileDeck` → `jobDeck` → `loadDeck`), so an execution test can reach a `LoadedProgram` in three lines.
- The run half is blocked. The sample's first text word is `START TSX SYS)175,4` (OPEN ALL FILES) — `decisions.md:457` quotes the end-of-text line `00165 500000000165 01111 START GN)000`, and `test/fixtures/90.05-object-code-notes.md` statement 188 at 00165 is "OPEN ALL FILES (2) … GET with `AT END DO` (9)". `test/fixtures/90.05-object-code-notes.md:341` gives the GET's shape: "**The GET's five fixed words** are the statement stamp, `TSX IOC)8,4`". M4-17 lands "the run-frame stubs SYS)174–178 (open and close, one file and all, and the display routine) and IOC)1, IOC)40, enough to run an I/O-free program to its STOP" and defers "IOC)2–17, 29, 46, 53, 54" to M5 (`m4-codegen.md:905-908`). `IOC)8` is in the M5 set, so the payroll sample cannot reach its STOP in stage 4.

Stage 4's execution tests therefore need I/O-free source decks of their own. `test/loader_test.dart:36-40` shows the minimal-deck idiom already in the repository:

```dart
final List<CardImage> _minimal = [
  ..._symbolic(['      *CTEXT']),
  _text(0, [(word: 7, control: ControlGroup.constantWord), _endOfText]),
  ..._symbolic(['      *CTEND']),
];
```

`test/emit_test.dart:397` is the one other call site: `expect(loadDeck(punched, resolve: (SystemReference r) => r.code).entry, 0);`

## 6. GAPS

Things stage 4 needs that no record settles, each with the evidence that it is open.

1. **No production caller exists.** `loadDeck` and `LoadedProgram` are reached only from `test/loader_test.dart` and `test/emit_test.dart:397` (grep over `lib bin test tool`). `docs/design/loader.md:137-140` states it: "No program run reads the result yet: stage 4 reads `origin`, `entry` and `words`". Stage 4 writes the first caller.

2. **Nothing writes `words` into `MachineState`.** The only memory API is one word at a time — `lib/src/emulator/machine_state.dart:105-112` `void write(int location, int word)`, with a 36-bit range check. `loader.md:144-146`: "The machine assembly stage writes the words into `MachineState` and runs; that is the plan CLAUDE.md section 11 asks for." The loop is stage 4's to write.

3. **No record fixes the execution origin, or the address range the dispatch entries occupy.** `loader.md:135-137`: "The dispatch table is M4-17's and the file blocks are M5's, so no address is fixed here." M4-17 (`m4-codegen.md:893-913`) names the SYS)/IOC) *entries* and never an address. The only concrete numbers anywhere are the test's `_table` (`loader_test.dart:19-21`), 0o70000 for system routines and 0o60000 for file blocks — a test fixture, not a decision. Stage 4 must choose both the program origin and the dispatch base, and must guarantee they do not overlap; `_fits` (`loader.dart:358-363`) checks only that each address is inside 32K core, never that a resolved dispatch address falls outside the loaded program.

4. **`SYS)n` and `IOC)n` share one number space with no discriminator.** Detailed in section 2. `SystemReference` exposes only `file` and `number`; a caller cannot tell `SYS)29` from `IOC)29`. The M4-17 ranges happen to be disjoint (IOC 1-54, SYS 128-296, `m4-codegen.md:901-908`) but no record states that the disjointness is load-bearing, and nothing asserts it.

5. **`LoadedProgram` carries no program extent.** `words` holds only placed cells — `loader.dart:113-115` "Every word the text placed, by absolute address. Reservations place nothing." A stage-4 caller computing the footprint from `max(words.keys)` under-reports whenever a `PTW` reservation follows the last placed word. The frozen block order emits the four `BSS` reservations before the constant pool (`lib/src/codegen/blocks.dart:95-102`), and the reservations are emitted unconditionally regardless of size (`blocks.dart:101`), so a program whose constant pool is empty ends on a `PI)` reservation and does under-report. Whether any real program has an empty pool: unverified.

6. **A resolver exception is not wrapped.** `loader.dart:355` `return _fits(_resolve(reference));` — an unregistered SYS)/IOC) number gives whatever the stage-4 resolver throws, escaping `loadDeck` outside the `LoadError` contract that `loader.dart:128-133` documents. No record says what an unregistered entry should do at load time.

7. **`words` is handed out live and mutable.** `loader.dart:147` `final Map<int, int> _words = {};` and `loader.dart:165` `words: _words,` — no `Map.unmodifiable`, no copy. Harmless today (the `_Loader` is discarded), but a stage-4 caller that mutates the map mutates the loader's result.

8. **The labeled PROGRAM.START path is unbuilt.** Section 4 above: the parser diagnoses it, nothing carries the location to `codegen.dart:153`. `decisions.md:465` and `loader.md:155-157` both assign it to stage 4.

9. **No I/O-free execution fixture exists.** Section 5 above: the 90.05 sample calls `IOC)8` at statement 188, which M5 owns. No record names what an I/O-free stage-4 test program looks like or where it lives.
