# Runtime call inventory — every SYS)/IOC) the generator can emit

Scope note on the golden: `test/goldens/90.05-payroll.listing` is the **front-end** listing and contains no `SYS)`/`IOC)` text (`grep -c 'SYS' test/goldens/90.05-payroll.listing` → `0`). The object text golden is `test/goldens/90.05-payroll.code` (`--emit-code`); every "sample" column below is counted from it.

Four scratch compiles under `/private/tmp/claude-501/-Users-jacklusher-development-comtran-compiler/cadf54f4-2c29-4220-94f3-c2a2e481bd2c/scratchpad/` (`nofile.ct` … `nofile5.ct`) drove the generator past the sample's shapes. `git status --porcelain` is empty; no repository file was touched.

---

## 1. REACHABLE SET

**No number is computed by arithmetic.** Every `SYS)nnn` and `IOC)nnn` the generator emits comes from a Dart integer literal at the call site, or from a two-way ternary between two literals. There is no `179 + n` and no table lookup. The three name-building sites interpolate a variable, but every value that reaches them is a literal argument:

- `lib/src/codegen/procedure.dart:540` — `_name('SYS)$sys');` … `:544` — `` () => 'SYS)$sys,4', ``
- `lib/src/codegen/procedure.dart:552` — `_name('IOC)$entry');` … `:556` — `` () => 'IOC)$entry,4', ``
- `lib/src/codegen/procedure.dart:566` — `_name('SYS)$sys');` … `:570` — `` () => 'SYS)$sys,1,$decrement', ``
- `lib/src/codegen/procedure.dart:631` — `_name('SYS)$number');` (operand form, `_sys(int number)`)

31 distinct `SYS)` numbers and 5 distinct `IOC)` numbers. Split by role: **27 SYS entry points** (5 reached by `TSX`, 21 by `TXI`, 1 by `TXL`), **4 SYS non-entry references** (2 cells, 2 exit addresses carried as data), **3 IOC entry points**, **2 IOC cells**.

### SYS entry points reached by `TSX SYS)nnn,4`

| # | Verb / site | How chosen | Kind | In 90.05? |
|---|---|---|---|---|
| 175 | `OPEN ALL FILES` — `procedure.dart:1338` `_tsx(175); // [J 90.02.14].` | literal at the `OpenClause(:final allFiles)` arm | literal | yes, 1× (LOC 00165) |
| 177 | `CLOSE ALL FILES` — `:1345` `_tsx(177);` **and** STOP RUN's implicit close — `:1412` `_tsx(177); // The close-all of [J 90.02.14] rides inside STOP RUN.` | literal, two independent sites | literal | yes, 2× (00517, 00524) |
| 178 | `STOP RUN` — `:1409` `_tsx(178); // The halt entry ([J 90.02.14]).` | literal | literal | yes, 1× (00521) |
| 180 | edited store, register source — `:2124` `_tsx(180);` in `_editedStore` | literal | literal | yes, 25× |
| 182 | MOVPAK both-preset dispatch — `:2004`, `:2026`, `:2247`, `:2430`, `:2513` (five call sites: XD→ID move, edit run, figurative fill, alphameric mover, edited ADD fetch) | literal at each site | literal | yes, 26× |

`SYS)179` and `SYS)181` are **never emitted**, by design: `test/fixtures/90.05-object-code-notes.md:945` — "The dispatch selection rule: `SYS)180` when the source is a register, `SYS)182` otherwise, and never `SYS)179` or `SYS)181`. The manual permits the two cheaper entries at thirteen sites, and the compiler pays 29 extra words to decline them." `SYS)174` (open one file) and `SYS)176` (close one file) are unreachable: `procedure.dart:1336` refuses first — `_unruled('an OPEN naming files (notes section 7)');` — and `:1343` likewise for CLOSE.

### SYS entry points reached by `TXI SYS)nnn,1,d` (MOVPAK step words)

| # | Verb / site | How chosen | Kind | In 90.05? |
|---|---|---|---|---|
| 184 | XD→ID move — `:2005` `_txi(184, _sem(source).digits); // The complete call ([J 90.02.16]).` | literal; decrement is the source digit count | literal | yes, 3× |
| 185 / 190 | edit-run head — `:2027` `_txi(fromEdited ? 190 : 185, _editControl(target));` | ternary on source class (edited → 190, external decimal → 185) | literal pair | 185 yes 3×; 190 yes 1× |
| 193 / 198 | edit-run move step — `:2056` `_txi(fromEdited ? 198 : 193, s.digits);` | same ternary | literal pair | 193 yes 3×; 198 yes 1× |
| 211 / 216 | trailing-zeros step — `:2058` `_txi(fromEdited ? 216 : 211, t.fractionDigits - s.fractionDigits);` | same ternary, guarded by `t.fractionDigits > s.fractionDigits` | literal pair | **neither**; 211 reached empirically (`nofile2.code:41` `TXI SYS)211,1,2`), 216 by inspection only |
| 212 / 214 | leading-zeros step — `:2054` `_txi(fromEdited ? 214 : 212, targetInteger - sourceInteger);` | same ternary, guarded by `targetInteger > sourceInteger` | literal pair | 212 yes 3×; 214 yes 1× |
| 225 / 226 | edit-run terminator — `:2030` `_txi(fromEdited ? 226 : 225, _sem(target).digits);` | same ternary | literal pair | 225 yes 3×; 226 yes 1× |
| 239 | equal-length alphameric mover — `:2434` `_txi(239, from);` | literal, taken when `from == to` | literal | yes, 2× |
| 240 + 241 | shorter-source alphameric mover — `:2436` `_txi(240, from);` `:2437` `_txi(241, to - from);` | literal pair, taken when `from < to`; a longer source refuses (`:2439`) | literal | yes, 3× each |
| 243 | BLANK fill — `:2259` `_txi(_zero(figurative) ? 244 : 243, extent);` (false arm) | ternary on the figurative token | literal | yes, 8× |
| 244 | ZERO fill — `:2259` (true arm) | same ternary | literal | yes, 3× |
| 245 | HIGH.VALUE / LOW.VALUE fill — `:2252` `_txi(245, extent);` then `:2253` `_oct(_fillWord(figurative));` | literal, taken when `_highOrLow(figurative)` | literal | yes, 2× |
| 267 | edited-store step — `:2141` `_txi(267, control);` | literal; decrement is the target edit control | literal | yes, 25× |
| 268 | edited ADD source fetch, head — `:2514` `_txi(268, 1);` | literal | literal | yes, 1× |
| 269 | edited fetch move step — `:2515` `_txi(269, digits);` | literal | literal | yes, 1× |
| 275 | edited fetch terminator — `:2516` `_txi(275, digits);` | literal | literal | yes, 1× |

Empirical confirmation that all of these are reachable in a program with **no FILE cards at all**: `nofile2.code` and `nofile3.code` in the scratchpad emit 175, 177, 178, 180, 182, 184, 185, 190, 193, 198, 211, 212, 214, 225, 226, 239, 240, 241, 243, 244, 245, 267, 268, 269, 275 with `NO ERRORS WERE DETECTED DURING COMPILATION`.

### SYS entry point reached by a conditional `TXL SYS)294,r,0`

| # | Site | How chosen | Kind | In 90.05? |
|---|---|---|---|---|
| 294 | `procedure.dart:1004-1013` `_trap(int register)`, called from `:1027` (base-locator load) and `:2984` (positional-indicator prologue) | literal | literal | yes, 20× |

### SYS numbers emitted as operands, never as a call target

| # | Site | Role | In 90.05? |
|---|---|---|---|
| 132 | `procedure.dart:1115` `static const int _sourceCell = 132;`, used through `_sys(...)` at `:1122` | MOVPAK source pointer; written by `STI SYS)132` or `SLW SYS)132` | yes, 13× |
| 133 | `:1116` `static const int _targetCell = 133;` | MOVPAK target pointer | yes, 22× |
| 260 | `:1815` `_pzePair(_fileSym(file), _sys(260));` | decrement of GET's first parameter word — the record-length-error exit | yes, 4× |
| 283 | `:1816` `_pzePair(_labelSym(names[0]), _sys(283));` | decrement of GET's second parameter word — the error-procedure exit | yes, 4× |

### IOC numbers

| # | Site | Role | Kind | In 90.05? |
|---|---|---|---|---|
| 1 | `procedure.dart:618-626` `_pzeIoc1()` — `` () => 'IOC)1', `` `` () => pzeWord(address: 1), `` ; called at `:1339`, `:1346`, `:1413` | `PZE IOC)1` parameter word of OPEN/CLOSE/STOP. Manual: `90.02-generated-code.md:318-322` "A cell in the CT Monitor communications area which locates (L) a list of files, and designates the number (N) of files in the list." | literal | yes, 3× |
| 8 | `:1814` `_tsxIoc(8);` in `_get` | IOCS READ entry | literal | yes, 4× |
| 9 | `:1858` and `:1863` `_tsxIoc(9);` in `_file` (located and transmitted arms) | IOCS WRITE entry | literal | yes, 8× |
| 29 | `lib/src/codegen/blocks.dart:74` `operand: i == 0 ? 'IOC)29' : '0',` `:76` `word: i == 0 ? pzeWord(address: 29) : 0,` | the constant loaded into `BL)1`, the IOCS label area (M3-11). Emitted by **every** program, including one with no files. | literal | yes, 1× |
| 40 | `:1414-1422` `_name('IOC)40');` … `` () => 'IOC)40,0', `` `` () => typeAWord(Op.txi, address: 40), `` | the monitor return that closes STOP RUN | literal | yes, 1× |

---

## 2. CALLING SEQUENCES

M4-17's governing rule, `docs/design/m4-codegen.md:896-900`:

> a TSX-linked handler reads its calling sequence through XR4, honors the resume convention (parameter-word count plus one), and returns control — SYS)294 alone breaks the pattern: the guard's conditional `TXL` reaches it with no calling sequence, and it exits to the monitor instead of returning.

The MOVE-section statement of the offsets, `docs/design/m4-codegen.md:479-482`:

> The MOVPAK dispatch entries and their return-skip convention: SYS)179 (both descriptors in the calling sequence, resume 3,4), SYS)180 (target only, 2,4), SYS)181 (source only, 2,4), SYS)182 (both preset, 1,4) — resume offset is parameter-word count plus one ([J 90.02.14]–15).

### Shape A — `TSX SYS)nnn,4`

Emitter, `procedure.dart:536-548`:

```dart
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
```

The machine effect, `lib/src/emulator/cpu.dart:219-223`: `case Op.tsx: // M p. 39: XR(T) <- 2's complement of the TSX location; IC <- Y.` → `state.xrWrite(inst.tag, (0x8000 - location) & Word36.fieldMask15);` So the handler recovers the TSX's own location as `0x8000 - XR4`, and `n,4` addresses the word `n` past it.

Per site:

| Entry | Parameter words emitted, in order | Resume |
|---|---|---|
| `SYS)175` | `PZE IOC)1` (`:1339`) | 2,4 |
| `SYS)177` | `PZE IOC)1` (`:1346` for the source CLOSE, `:1413` inside STOP) | 2,4 |
| `SYS)178` | `PZE CP)+a,,CP)+b` (statement stamp), `PZE CP)+c,,CP)+d` (the words `' STOP '` / `' RUN  '`) — `:1410-1411` | 3,4 |
| `SYS)180` | `PZE target,,byte` (`:2125` `_pze(target);`) — one word | 2,4 **into the step list, not past it** |
| `SYS)182` | none | 1,4 **into the step list** |

The parameter word forms come from `procedure.dart:601-614` (`_pzePair`, `PZE first,,second`) and `:576-595` (`_pze`, `PZE LOC,,BYTE`; a located item refuses at `:580`). The pair's control group is `standardControl(second.relocation, first.relocation)` — the golden shows `11010` for `PZE INPUTMASTER,,SYS)260` (`90.05-payroll.code:109`), i.e. system decrement over file address.

**The resume offset for 180 and 182 lands inside the run, not after it.** For `SYS)182` word 1,4 is the first `TXI SYS)nnn,1,d` step; for `SYS)180` word 2,4 is the `TXI SYS)267,1,control`. The run's end is per-family and not derivable from the entry:

| Family | Words after the entry |
|---|---|
| `SYS)184` | one word, complete call — `90.02-generated-code.md:797` `TXI SYS)184,1,NUMBER-OF-CHARACTERS-TO-CONVERT` |
| `SYS)239` / `243` / `244` | one step word |
| `SYS)240` + `241` | two step words |
| `SYS)245` | step word + one in-line `OCT` (`:2253`); manual `:1427-1431` `TXI SYS)245, 1, NUMBER-OF-CHARACTERS-TO-INSERT` / `OCT CHARACTERS` |
| `SYS)185` / `190` | head + `OCT` control word (`:2028`) + 1–3 steps + terminator `225`/`226`. Manual `:766-770`: "This type of MOVPAK call is always terminated by the instruction `TXI SYS)223, 1, TARGET-NUMERIC-LENGTH`" (223 is the XD-to-XD family's terminator; 225/226 are ours) |
| `SYS)268` | head + `269` + `275` (`:2514-2516`) |
| `SYS)180` route | `PZE`, then `267` (or the `TRA` substitute), then `OCT` (`:2143`), then `AXT digits,1` (`:2144`) |

The run's word count is fixed in `test/fixtures/90.05-object-code-notes.md:585-586`:

```
run   = 2 + steps + 1          an edited target: head, control word, terminator
run   = 1 + steps + 1          a register target: head and terminator, no OCT
```

### Shape B — `TXI SYS)nnn,1,d` (the step word)

Emitter, `procedure.dart:562-573`:

```dart
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
```

`cpu.dart:228-234`: `case Op.txi: // M p. 39: XR(T) <- XR(T) + D; IC <- Y.` → `state.xrWrite(inst.tag, (state.xrRead(inst.tag) + inst.decrement) & Word36.fieldMask15);` So a step word **adds its count into XR1 and transfers**. The count is the parameter; there is no return-skip — the step transfers into the routine, which comes back to the next word by its own means.

### Shape C — `TRA SYS)267,0,0`, the zero-edit-control substitute

`procedure.dart:2129-2138`:

```dart
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
```

`test/fixtures/90.05-object-code-notes.md:983` — "`TRA SYS)267,0,0` replaces the `TXI` when the edit control computes to 0. One site, confirmed by the punched opcode." **SYS)267 therefore has two arrival shapes**: with XR1 incremented by the control bits, and with XR1 untouched.

### Shape D — the guard `TXL SYS)294,r,0` — see section 3.

### Shape E — `TSX IOC)n,4`

Emitter, `procedure.dart:550-559`: `` () => 'IOC)$entry,4', `` / `` () => typeBWord(Op.tsx, tag: 4, address: entry), ``.

**GET** (`procedure.dart:1795-1817`), 5 words, preceded by the statement stamp:

```dart
    _emit(
      // The stamp rides ahead of the call, prefixed TXH (M4-14).
      mnemonic(Op.txh), … () => '${_cp(number).text()},0,${_cp(comma).text()}',
```
```dart
    _tsxIoc(8);
    _pzePair(_fileSym(file), _sys(260));
    _pzePair(_labelSym(names[0]), _sys(283));
    _ioctn(locator, _recordWords(info.item));
    _op(Op.tra, _labelSym(names[1])); // Over the block, to the join.
```

The file operand's address is `04000 + k`, `procedure.dart:637-638`: `_Sym(() => name, () => 0x800 + _fileOrdinals[name]!, Relocation.system)`. The buffer descriptor is `IOCTN* BL)n,,words`, `:1739-1746`, word `(5 << 33) | (length << 18) | (6 << 15) | cell.value()`. Attested at `90.05-payroll.code:108-111`. Three parameter words → **resume 4,4**.

**FILE** (`:1855-1871`), transmitted record: `TSX IOC)9,4 / PZE file,,0 / IOST record,,len`; located record: `LXA BL)n,4 / SXA GN)a,4` first, then the same three, with `GN)a` labeling the `IOST` word so its zero address field is patched at run time (`:1849-1861`). Two parameter words → **resume 3,4**.

### Shape F — `TXI IOC)40,0`, the monitor return

`procedure.dart:1414-1422`:

```dart
    _name('IOC)40');
    _emit(
      // The monitor return; a zero decrement prints none.
      mnemonic(Op.txi),
      formOf(Op.txi),
      () => 'IOC)40,0',
      () => typeAWord(Op.txi, address: 40),
```

Tag 0 and decrement 0. `machine_state.dart:68-76` `xrRead` with tag 0 ORs nothing and returns 0; `xrWrite` with tag 0 writes nothing. So the word is a **bare unconditional transfer to IOC)40** with no index effect — not a call, no return. `90.02-generated-code.md:365`: "**IOC)40** This is the end of job return point in the CT Monitor communication area for all CT jobs."

### The register contract every handler must honour

`procedure.dart:355-359`:

> The index-register cache: which locator each register holds. A label or a section entry clears the whole cache, a subroutine call (DO, GET, FILE, OPEN, CLOSE, STOP) clears it, and a MOVPAK sequence clears register 1 alone — its trailing `AXT n,1` is the only register write.

Consequences the handlers are bound by:

- A MOVPAK entry (`SYS)180`, `SYS)182`) and every step it runs may clobber **XR1 only**. `procedure.dart:1045-1052` `_movpakClears()` removes register 1 from the cache and leaves register 2 live, so generated code addresses `NAME,2` across a dispatch and will read the wrong word if a handler touches XR2. XR4 is the linkage register (`:1076` `_callClears()`), so a MOVPAK handler must also leave XR4 as it found it — an intra-statement `LAC BL)n,i` load is not re-emitted after a dispatch.
- `SYS)175`, `SYS)177`, `SYS)178`, `IOC)8`, `IOC)9` are followed by `_callClears()` (`:1340`, `:1347`, `:1424`, `:1820`, `:1870`), so they may clobber XR1, XR2 and XR4 freely.

---

## 3. THE GUARD

Emission, `procedure.dart:1004-1013`:

```dart
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
```

Two callers, each pairing it with the register load it guards.

**Base-locator load**, `procedure.dart:1016-1029`:

```dart
  /// Emits the guard pair `LAC BL)n,i / TXL SYS)294,i,0` when no
  /// register holds that locator, and records the load. A register
  /// already holding it is reused with no words ([J 90.02.23]).
  void _loadBase(DataItem record) {
    …
    _op(Op.lac, _blockWord(StorageBlock.bl, locator), tag: register);
    _trap(register);
  }
```

**Positional-indicator prologue**, `procedure.dart:2975-2986`:

```dart
  /// `LAC PI)n,r / TXL SYS)294,r,0` (the attested 01410–01411). The
  /// register map keys the indicator negated, so it never collides
  /// with a locator, and the register leaves the cache: it holds the
  /// element address now, not a base.
  int _indicatorPrologue(DataItem array) {
    …
    _op(Op.lac, _blockWord(StorageBlock.pi, indicator), tag: register);
    _trap(register);
```

**What the machine does.** `cpu.dart:256-261`:

```dart
      case Op.lac: // M p. 45: XR(T) <- 2's complement of C(Y)(21-35).
        state.xrWrite(
          inst.tag,
          (0x8000 - Word36.address(state.read(inst.address))) &
              Word36.fieldMask15,
        );
```

`cpu.dart:239-242`:

```dart
      case Op.txl: // M p. 40: transfer when XR(T) <= D.
        if (state.xrRead(inst.tag) <= inst.decrement) {
          state.ic = inst.address;
        }
```

The decrement is 0 (`typeAWord(Op.txl, tag: register, address: 294)` passes no `decrement`), so **the TXL tests `XR(r) == 0`** — `xrRead` returns an unsigned 15-bit value, so `<= 0` is `== 0`.

`XR(r) == 0` happens exactly when the pointer word's address field was zero: `(0x8000 - 0) & 0x7FFF == 0`. Every base-locator cell but `BL)1` is initialized to zero — `blocks.dart:74-79`:

```dart
        operand: i == 0 ? 'IOC)29' : '0',
        location: origin + i,
        word: i == 0 ? pzeWord(address: 29) : 0,
```

with the comment at `blocks.dart:57-58`: "`BL)1` points the input-output system at its label area, `IOC)29` (M3-11); every later cell starts empty for the OPEN that fills it at run time."

So the guard fires precisely when a located reference runs before the GET (or OPEN) that filled its locator. The manual's contract, `comtran-manuals/J28-6169/90.02-generated-code.md:1880-1888`:

```
**SYS)294**

LAC     BL)NN, N
TXL     SYS)294, N, 0
```
> This subroutine prints an error message whenever a reference is made to a Base Locator before the locator has been loaded, and exits back to the CT Monitor.

**SYS)294 takes no calling sequence and never returns.** It is entered by a conditional transfer, not a `TSX`, so XR4 still holds whatever the last `TSX` left there. M4-17 (`docs/design/m4-codegen.md:898-900`) states the exception explicitly: "SYS)294 alone breaks the pattern: the guard's conditional `TXL` reaches it with no calling sequence, and it exits to the monitor instead of returning."

**What surrounds it.** The generated code after a surviving guard addresses the record relative to the loaded register — `90.05-payroll.code` LOC 00203 `IOCTN* BL)2,,15` fills BL)2, then later references print `NAME,1` / `NAME,2`. Manual `:200-206`: "by first loading an index register with the 2's complement of the location of the first word (the base) … and then referencing any data item within that block by using the relative word position." Empirical: scratchpad `nofile5.code` LOC 00017–00021 —

```
00017		LAC	PI)1,1	053500100102
00020		TXL	SYS)294,1,0	700000100446
00021		CAS	0,1	034000100000
```

— the `CAS 0,1` reads the element the register alone reaches.

---

## 4. END OF TEXT

The 01111 entry is emitted once per job, last, in `lib/src/codegen/codegen.dart:145-156`:

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

`ControlGroup.endOfText` is `0x0F` (`text_model.dart:56-58`, "The end-of-text entry, whose address field holds the relative program entry point; the CNTRL column prints `01111`"). The address is `dataWords` — the first word of the procedure text, computed at `codegen.dart:97-100` as the sum of the transmitted areas' extents. The loader consumes it at `loader.dart:241` (`if (group == ControlGroup.endOfText) {`).

`GN)000` is bound unconditionally to the first procedure sentence's first word, `procedure.dart:107-114`:

```dart
      if (group is ParsedProcedureGroup) {
        if (entry) {
          text.label('GN)000'); // The entry word's name (D2.1; M3-8).
          entry = false;
        }
```

**The generator does not know a labeled PROGRAM.START.** `grep -rn 'programStartName\|PROGRAM.START' lib/src` returns hits only in `lib/src/lexer/`, `lib/src/parser/`, and `lib/src/data/` — **zero hits under `lib/src/codegen/`**. `codegen.dart` computes the entry address from `dataWords` alone and never consults `semantics`. Nor does it read the allocator's `programEntryWord` (`lib/src/data/allocator.dart:66-67`, "The program entry's word — the word the object listing labels GN)000"), which is a compile-time dictionary word, a different address space (`image.dart:3-6`).

`docs/design/decisions.md:466` records this as a known deferral:

> *Amended 2026-08-30 (M4 stage 3, `docs/design/loader.md` LD-3).* The loader consumes the 01111 entry as decided. The generator names the first *PROCEDURE sentence as the entry point of every program. It does not yet honor a labeled PROGRAM.START; that path waits for stage 4, where a program first runs.

One naming trap for a stage-4 reader: `90.05-payroll.code:97` prints `GN)000 START TSX SYS)175,4`. `START` there is the **user's own paragraph label** — `test/fixtures/90.05-payroll-job.ct:202` `      START.          OPEN ALL FILES,` — not `PROGRAM.START` and not the `START` pseudo-operation of the end-of-text line.

---

## 5. WHAT AN I/O-FREE PROGRAM LOOKS LIKE

**Yes — the generator compiles a program with no FILE cards, no records, no GET, no FILE, and no OPEN, to a complete object text with `NO ERRORS WERE DETECTED DURING COMPILATION`.** Proved by compiling, not inferred.

Minimal case (`scratchpad/nofile.ct`: two internal-decimal fields, `START. SET TOT = NUM + 1.` / `STOP RUN.`) produced `scratchpad/nofile.code` entire:

```
00002	GN)000 START	CLA	NUM	050000000000	10001
00003		ADD	CP)+1	040000000062	10001
00004		STO	TOT	060100000001	10001
00005		TSX	SYS)178,4	007400400262	10010
00006		PZE	CP)+2,,CP)+3	000064000063	10101
00007		PZE	CP)+4,,CP)+5	000066000065	10101
00010		TSX	SYS)177,4	007400400261	10010
00011		PZE	IOC)1	000000000001	10010
00012		TXI	IOC)40,0	100000000050	10010
…
00060		PZE	IOC)29	000000000035	10010
…
00002		START	GN)000	500000000002	01111
```

That run exited 1 only because the scratch deck had no `*FINISH` card (`9999,99 5 END OF FILE ON JOB TAPE WITHOUT *FINISH CARD.`); the object text was still generated. `nofile2` through `nofile5` carry `*FINISH` and exit 0.

### The unconditional floor

**STOP RUN emits SYS)178, SYS)177, IOC)1 and IOC)40 every time, with no dependence on files.** `procedure.dart:1405-1424`:

```dart
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
```

`_stop` reads nothing about files. `STOP n` refuses first (`:1406-1408` `_unruled('STOP n (notes section 7)');`), so this is the only STOP shape stage 4 must run.

`IOC)29` is likewise unconditional: `image.dart:51-52` `baseLocatorWords` returns `1 + <located records>`, so the `BL)` block is one word even with no files, and `blocks.dart:71-81` fills it with `PZE IOC)29`.

So **the minimum stage-4 runtime table for an I/O-free program is: SYS)178, SYS)177, IOC)1, IOC)40, IOC)29** — plus SYS)132, SYS)133 and whichever MOVPAK entries the program's verbs reach. `SYS)177` is called with `IOC)1` naming a file list of length zero (`PZE L,,N`, manual `:318-322`), so the close-all stub must tolerate N = 0.

### OPEN is source-driven, not a run-frame prologue

`docs/design/m4-codegen.md:840-841` says "the run frame opens with `TSX SYS)175,4 / PZE IOC)1` (open all) at the entry word GN)000". That describes the sample, **not a generator rule.** `SYS)175` is emitted only from the `OpenClause(:final allFiles)` arm at `procedure.dart:1336-1340`; `nofile.code` shows `GN)000 START CLA NUM` — the entry word is whatever the first sentence's first clause generates. A stage-4 author reading M4-15 alone would wrongly expect an automatic open at entry.

### Which shapes an I/O-free program still needs

Empirically reached with no FILE cards (scratchpad runs): 175, 177, 178, 180, 182, 184, 185, 190, 193, 198, 211, 212, 214, 225, 226, 239, 240, 241, 243, 244, 245, 267, 268, 269, 275, 294, plus cells 132, 133 and IOC)1, IOC)29, IOC)40. `SYS)294` is reachable file-free through the positional-indicator prologue (`nofile5.code:00017-00020`), even though a *base locator* is not: `lib/src/data/binder.dart:143` `..located = record.inputFiles.isNotEmpty;` makes a located record impossible without an input FILE card.

Unreachable without files: `IOC)8`, `IOC)9`, `SYS)260`, `SYS)283`, and the located-record `SYS)294` route.

---

## 6. GAPS

Things stage 4 needs that no record in the repository settles.

1. **Who walks the MOVPAK step list.** M4-17's resume convention (`m4-codegen.md:897-898`, "parameter-word count plus one") puts the `SYS)182` handler's return at 1,4 — the *first step word*, not past the run. Two readings survive and nothing chooses between them: (a) the 182 handler reads the whole step list through XR4 and returns past the terminator; (b) 182 returns to 1,4, the CPU executes that `TXI`, XR1 accumulates the count, and control dispatches into the step's own handler, which chains. They differ in whether XR1 accumulates across a run and in what `SYS)225`/`226` must do at the terminator. `procedure.dart:355-359` assumes only that XR1 is dead after the run, which both readings satisfy.

2. **SYS)267's two arrival shapes.** `procedure.dart:2129-2138` emits `TRA SYS)267,0,0` when the edit control is zero, and `:2141` emits `TXI SYS)267,1,control` otherwise. The handler is entered with XR1 incremented in one case and untouched in the other, and it must read its control from somewhere in both. No record says where.

3. **`SYS)180`'s two-word resume against its four-word tail.** `:2124-2144` emits `TSX SYS)180,4 / PZE target,,byte / TXI SYS)267,… / OCT control / AXT digits,1`. Resume 2,4 is the `TXI`; the `OCT` at 3,4 and the `AXT` at 4,4 have no stated reader. `test/fixtures/90.05-object-code-notes.md:906-909` records the `AXT` fact as pinned at the diff ("The `AXT` carries the number of digits to convert, in its address field"), not derived.

4. **The loader's system-reference table must cover the non-entry cells.** `loader.dart:345-355` `_system(int code)` resolves every `Relocation.system` field through the caller's `SystemReferenceResolver` and `_fits` throws `LoadError` on an out-of-core result. `SYS)132`, `SYS)133`, `IOC)1` and `IOC)29` are punched as system references (control groups `10010`/`11010` in the goldens) even in a file-free program, so the stage-4 table must register **memory addresses** for them, not handler entries. No design record lists the cell set separately from the handler set.

5. **`IOC)1` must exist and hold a file list of length zero.** The close-all inside STOP RUN is unconditional (`:1412-1413`) and the manual's contract is `PZE L,,N`. Nothing records what N = 0 means to the close-all stub.

6. **The labeled PROGRAM.START path is unbuilt and stage 4 owns it.** `decisions.md:466` assigns it to "stage 4, where a program first runs", but no record says how the generator should learn the label: `semantics` reaches `runCodegen`, but `codegen.dart:150-156` derives the entry address from `dataWords` alone, and the parser's `_programStartLabels` (`procedure_parser.dart:148-157`) is not exposed on `ParseResult` in any form codegen reads. That plumbing is undesigned.

7. **`SYS)216` has no exercised site.** It is emitted only at `procedure.dart:2058` (`_txi(fromEdited ? 216 : 211, …)`), needs an edited→edited move whose target has more fraction digits than its source, is absent from the 90.05 golden, and I did not reach it empirically. Reachability is by inspection only.

8. **M4-17's handler set is far wider than the reachable set — a §11 collision candidate, not one I settled.** `m4-codegen.md:901-907` asks stage 4 to land "the cells and flags SYS)128–134, the scaling, exponent, and comparison routines SYS)155–173 … MOVPAK entire (SYS)179–258, 267–282)". The generator can emit 31 SYS numbers in total. `SYS)179` and `SYS)181` are *declined by design* and can never be emitted (`90.05-object-code-notes.md:945-946`); `SYS)162` is behind a refusal (`procedure.dart:3048` `_unruled('a comparison past one word (M4-11, the SYS)162 boundary)');`); `SYS)155/156/163–173` are behind the floating/double refusals; `SYS)128–131`, `SYS)134` have no emitter at all. Under CLAUDE.md §11 the unexercised-and-untested case is banned, and §11's last bullet says "A design record that requires banned code is a peer collision. … Stop and bring it to Jack." Handlers written to M4-17's full list would be tested-but-unexercised (the permitted third row) only if each carries a recorded plan for a caller; nothing in `m4-codegen.md` or `decisions.md` D0.3 supplies one. Flagging, not deciding.

9. **The `IOCTN*` and `IOST` descriptor words are the generator's own forms.** `procedure.dart:1735-1760` builds `IOCTN* BL)n,,words` as `(5 << 33) | (length << 18) | (6 << 15) | cell` and `IOST record,,words` as `(7 << 33) | (length << 18) | address`. The manual writes the GET example's fourth word as `IOCDN* BL)2,,14` (`90.02-generated-code.md:186`), a different mnemonic. These are M5 shapes, but a stage-4 dispatcher that registers `IOC)8`/`IOC)9` at all will meet them.
