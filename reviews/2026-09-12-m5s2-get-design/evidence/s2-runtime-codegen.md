## 1. The machine: dispatch, parameters, resume

**Dispatch rule.** `lib/src/runtime/machine.dart:281-300` — the run loop tests the IC before every step; anything below `programOrigin` (4096) is a Dart handler, everything else is the CPU:

```dart
if (state.ic < programOrigin) {
  final RuntimeEntry? entry = _handlers[state.ic];
  if (entry == null) { throw UnimplementedRuntimeEntry(state.ic); }
  outcome = entry();
} else { _cpu.step(); }
```

- `programOrigin = 0x1000` at `machine.dart:175`; the rule is documented at `docs/design/runtime.md:36-60`.
- Handler type: `typedef RuntimeEntry = RunOutcome? Function();` (`machine.dart:40`) — return `null` to give control back to the program.
- Registration is a map merge, `machine.dart:186-189`: `{...runFrame(this), ...movpak(this)}`. Stage 2 adds a third spread (e.g. `...iocs(this)`).
- Handler addresses **are** the reference numbers: the loader is called with `resolve: (reference) => reference.code` (`machine.dart:162-170`), so `IOC)8` dispatches at address 8.

**Parameter words and resume.** `machine.dart:191-200`:

```dart
int parameter(int k) => state.read((k - state.xrRead(4)) & Word36.fieldMask15);
void resume(int k) { state.ic = (k - state.xrRead(4)) & Word36.fieldMask15; }
```

`TSX` writes the link `(0x8000 - location) & 0x7FFF` into XR4 (`test/runtime/runtime_support.dart:104`), so `k - link ≡ tsxLocation + k`. Hence `parameter(1)` is the word right after the TSX, and **`resume(n)` = parameter-word count plus one** (`runtime.md:53-56`, `RT-3 "The off-by-one"` at `runtime.md:286-302`). GET has 3 parameter words → `resume(4)`; FILE has 2 → `resume(3)` (`docs/design/m5-io.md:184-189`).

**Core and registers.** `MachineState` (`lib/src/emulator/machine_state.dart`): `read(loc)` :97, `write(loc, word)` :103, `xrRead(tag)` :68, `xrWrite(tag, value)` :86, `ic` :46, `acWord` :60, `acMagnitude`/`acSign` :33-36. Field helpers in `lib/src/emulator/word.dart`: `prefix` :48, `decrement` :51, `tag` :54, `address` :57, `fieldMask15` :21, and the builder `pzeWord({decrement, tag, address})` :92.

**Template handler — SYS)175/177 open-all/close-all**, `lib/src/runtime/monitor.dart:29-43` (complete):

```dart
RunOutcome? _files(Machine machine, {required bool open}) {
  final int header = machine.state.read(Word36.address(machine.parameter(1)));
  final int count = Word36.decrement(header);
  if (open) { machine.openFiles(count); } else { machine.closeFiles(count); }
  machine.resume(2);
  return null;
}
```

Registered at `monitor.dart:19-27`. A second template, a MOVPAK member that reads a data word and resumes past it, is `_editedHead` at `movpak.dart:200-209`; the step-discipline helper is `_step` at `movpak.dart:119-136`, with `_next`/`_end` at :140-149.

## 2. What happens at IOC)8 today

Nothing is registered at 8, so the dispatcher throws before any I/O runs: `machine.dart:287-290` → `UnimplementedRuntimeEntry(8)`, whose message is `'unimplemented runtime entry IOC)8'` (`machine.dart:47-65`; the `SYS)`/`IOC)` name split at :59). `comtranc --run` catches `RunFault`, prints the display, then `error: job N: <fault>` (`bin/comtranc.dart:366-369`). The sample stops at the **first** GET, LOC 00200 (`docs/design/runtime.md:87-90`).

The pinning test is `test/runtime/machine_test.dart:173-200`:

```dart
test('loads at the origin and stops at the first entry M4 lacks', () {
  final JobCompilation job = compileDeck(loadJobDeck()).jobs.single;
  final subject = Machine.load(jobDeck(job, _options)!.cards);
  expect(subject.program.words, hasLength(936));
  expect(subject.program.entry, Machine.programOrigin + octal('165'));
  expect(Word36.decrement(subject.state.read(1)), 7);
  expect(() => subject.run(maxSteps: 1000),
      throwsA(isA<UnimplementedRuntimeEntry>()
          .having((e) => e.number, 'number', 8)));
  expect(subject.files, hasLength(7));
  expect(subject.files.map((f) => f.open), everyElement(isTrue));
});
```

Two more tests move when stage 2 lands: the unit dispatch case `machine_test.dart:128-140` (asserts the exact string `unimplemented runtime entry IOC)8` from a bare `TSX IOC)8,4` — it will keep passing only if no handler is registered, so it must be retargeted), and `machine_test.dart:218-222` (`comtranc --run fails on the entry M4 lacks`), which after stage 2 will fail on **IOC)9** instead.

## 3. The stage-1 file model

**`LoaderFile`** — `lib/src/loader/loader.dart:59-92`. Parsed from the `*FILE` card at `loader.dart:181-193`:

| field | source | line |
|---|---|---|
| `deckName` | cols 1-6 | :179 |
| `number` | cols 14-15 | :385 |
| `name` | cols 55-72 | :185 |
| `type` | col 28 (`I`/`T`/`P`) | :186 |
| `mode` | col 31 (`D`/`B`) | :187 |
| `density` | col 30 (`H`/`L`) | :188 |
| `unit1` | cols 18-21 | :190 |
| `unit2` | cols 22-25 | :191 |

From the `*SPEC` card (`loader.dart:194-205`), matched on deckName + number: `blocksize` cols 17-20, `open` col 25, `close` col 27. **`blocksize` has no runtime consumer** — grep shows only the parser, `control_cards.dart:147-171` (punching) and `binder.dart:79-81, 213-225`. `M5-2` says so explicitly: "A file's BLOCKSIZE is not the block length on tape" (`docs/design/m5-io.md:104-107`).

**Control block** — `RuntimeFile`, `machine.dart:100-110`, exactly two fields:

```dart
final class RuntimeFile {
  RuntimeFile(this.host);
  final File? host;          // null when no --tapes directory
  bool open = false;
}
```

No read position, no buffer, no record count. `m5-io.md:113-116`: "The buffer and the read position arrive with IOC)8."

**Table build and tape attachment** — `machine.dart:147-158`: one `RuntimeFile` per `*FILE` card, host = `File('${tapes.path}/${file.unit1}.tap')`. File ordinal *k* is `files[k-1]` (`machine.dart:180-182`). Open/close: `openFiles` :211-245 (validates the whole list first, truncates output images, refuses three shapes), `closeFiles` :251-263.

**SIMH `.tap` code: there is none.** The only tape artefact in `lib/` is:

```dart
/// A tape mark, the record length zero that ends a file (M5-2).
const List<int> _tapeMark = <int>[0, 0, 0, 0];   // machine.dart:113
```

written by `host.writeAsBytesSync(_tapeMark, mode: FileMode.append)` (`machine.dart:259`), and truncation by `host.writeAsBytesSync(const <int>[])` (:241). **No reader, no writer, no record encoder, no word↔bytes codec, no API.** The format spec exists only as prose in `docs/design/m5-io.md:84-94`: 4-byte little-endian length, data padded to even, the same length again; length 0 = tape mark; `0xFFFFFFFF` or EOF ends the tape; one 36-bit word = six bytes, most significant six bits first, each byte holding its six bits in its low end. `m5-io.md:95-101`: "The encoding lands with the first record written and the decoding with the first record read." No test pins the encoding — the only record bytes in the suite are 2-byte payloads (`test/runtime/monitor_test.dart:99, 143`).

## 4. The GET emission

**The emitter** — `lib/src/codegen/procedure.dart:1780-1846`. The refusals first (:1781-1813), then the words:

```dart
final (PoolHandle number, PoolHandle comma) = _stamp(_statement, _ordinals[clause] ?? 0);
final List<String> names = semantics.allocation?.clauseNames[clause] ?? const <String>[];
_emit(mnemonic(Op.txh), ... );            // the statement stamp, TXH CP)+n,0,CP)+m
_tsxIoc(8);
_pzePair(_fileSym(file), _sys(260));
_pzePair(_labelSym(names[0]), _sys(283));
_ioctn(locator, _recordWords(info.item));
_op(Op.tra, _labelSym(names[1]));          // Over the block, to the join.
label(names[0]);
if (atEnd.bareName != null) { _doEdge(...); _callTriple(atEnd.bareName!); }
else if (atEnd.statement != null) { _clause(atEnd.statement!); }
_callClears();
label(names[1]);                            // The join, on the resume word.
```

**The words emitted for one GET** (the stamp rides ahead of the call and is not a parameter word):

| word | emitter | address field | decrement | prefix/tag |
|---|---|---|---|---|
| stamp | `procedure.dart:1820-1831` | `CP)+n` (pool, relative) | `CP)+m` | TXH |
| `TSX IOC)8,4` | `_tsxIoc` :563-573 | `8`, system reloc | — | tag 4 |
| p1 `PZE file,,SYS)260` | `_pzePair` :620-627 + `_fileSym` :650-651 | `0x800 + ordinal`, system reloc | `260` | PZE |
| p2 `PZE atEnd,,SYS)283` | `_pzePair` + `_labelSym` :655-656 | GN) label of the AT END block, relative | `283` | PZE |
| p3 `IOCTN* BL)n,,words` | `_ioctn` :1754-1766 | `BL)n` cell, relative | record extent in **words** | prefix 5, tag 6 |

`_ioctn` in full (`procedure.dart:1757-1766`):

```dart
void _ioctn(int locator, int length) {
  final _Sym cell = _blockWord(StorageBlock.bl, locator);
  _emit('IOCTN*', WordForm.prefix,
    () => '${cell.text()},,$length',
    () => (5 << 33) | (length << 18) | (6 << 15) | cell.value(),
    control: standardControl(Relocation.constant, cell.relocation));
}
```

- **Address is bound to the `BL)n` cell**, one base locator per located record: `_baseLocators` assigned at `procedure.dart:280-284` starting at `bl = 2` because "BL)1 is the IOCS label area (M3-11)"; the block is sized `1 + located-record count` at `lib/src/codegen/image.dart:50-52`.
- **Decrement is `_recordWords(info.item)`** (`procedure.dart:1741-1752`): "never the BLOCKSIZE"; for a located record it is the character extent rounded up, `(storageChars + 5) ~/ 6`.
- Prefix 5 and tag 6 are hard constants. The mnemonic spelling `IOCTN*` vs the appendix's `IOCDN*` is settled at `docs/design/m4-codegen.md:1006-1010` and `test/fixtures/90.05-object-code-notes.md:356-362`.

**AT END layout.** `TRA names[1]` jumps over the block; the block is labelled `names[0]` (which is what parameter 2's address field holds) and lies immediately after the descriptor; `names[1]` labels the join, which is the normal-return word, i.e. `resume(4)`. `AT END DO`/bare name emits the plain DO triple `AXT *+3,7 / SXA name,4 / TRA name+1` (`_callTriple`, `procedure.dart:1491-1496`) → 3 words; `AT END GO TO` emits 1 word. Word counts by shape: `test/fixtures/90.05-object-code-notes.md:334-345`. The decision record is D6.6 (`docs/design/decisions.md:1008-1015`), which also fixes that with no AT END, `SYS)265` goes in the **address** field — a shape our generator refuses (`procedure.dart:1784-1789`).

**Field-extraction map a stage-2 `IOC)8` handler needs** (from `parameter(k)`):

- p1: `Word36.address(p1) - 0x800` = 1-based file ordinal → `machine.files[ordinal - 1]`; `Word36.decrement(p1)` = 260.
- p2: `Word36.address(p2)` = absolute AT END address → set `state.ic` to it directly (do **not** `resume`); `Word36.decrement(p2)` = 283 (ON ERROR).
- p3: `Word36.address(p3)` = absolute `BL)n` cell; `Word36.decrement(p3)` = extent in words; prefix 5 / tag 6 are ignorable.
- normal return: `resume(4)`.

No handler exists at 260, 283 or 265 today, so any transfer to them throws `UnimplementedRuntimeEntry`.

## 5. Every I/O site in `test/goldens/90.05-payroll.code`

Four GETs. Golden line numbers, then LOC/octal.

**GET #1 — statement 188, `GET MASTER, AT END DO END.OF.MASTERS` (lines 107-116):**

```
107  00177	TXH	CP)+14,0,CP)+15	301713001712	10101
108  00200	TSX	IOC)8,4	        007400400010	10010
109  00201	PZE	INPUTMASTER,,SYS)260	000404004001	11010
110  00202	PZE	GN)058,,SYS)283	        000433000205	11001
111  00203	IOCTN*	BL)2,,15	        500017601667	10001
112  00204	TRA	GN)059	                002000000210	10001
113  00205 GN)058  AXT  *+3,7	        077400700210	10001
114  00206	SXA	END.OF.MASTERS,4	063400400331	10001
115  00207	TRA	END.OF.MASTERS+1	002000000332	10001
116  00210 GN)059  CAL  CP)+16          450000001714	10001
```

then, **how the record is addressed** (lines 118-120): `00212 LAC BL)2,1` → `00213 TXL SYS)294,1,0` → `00214 CAL 1)DEPARTMENT,1` (`450000100000`, address field **zero**, control `10000` = constant). The `LAC` loads `2^15 − c(BL)2)address` into XR1; the indexed reference then resolves to base+offset. Field offsets are literal word offsets inside the record, not program addresses.

**GET #2 — statement 190, `GET.MASTER` (lines 125-134):** `00221 TXH CP)+18,0,CP)+19` / `00222 TSX IOC)8,4` / `00223 PZE INPUTMASTER,,SYS)260` / `00224 PZE GN)060,,SYS)283` / `00225 IOCTN* BL)2,,15` / `00226 TRA GN)061` / GN)060 block `00227-00231` (`AXT *+3,7` / `SXA END.OF.MASTERS,4` / `TRA END.OF.MASTERS+1`). Join `GN)061` is at 00232, which is the next GET's stamp.

**GET #3 — statement 191, `GET DETAIL, AT END GO TO END.OF.DETAILS` (lines 134-141):**

```
134  00232 GN)061 GET.DETAIL  TXH  CP)+20,0,CP)+19  301717001720  10101
135  00233	TSX	IOC)8,4	         007400400010	10010
136  00234	PZE	DETAILFILE,,SYS)260	000404004003	11010
137  00235	PZE	GN)062,,SYS)283	         000433000240	11001
138  00236	IOCTN*	BL)3,,3	                 500003601670	10001
139  00237	TRA	GN)063	                 002000000241	10001
140  00240 GN)062  TRA  END.OF.DETAILS	 002000000351	10001
141  00241 GN)063 COMPARE.EMPLOYEE.NUMBERS LAC BL)3,1  053500101670  10001
```

followed by `00242 TXL SYS)294,1,0` / `00243 CAL 2)EMPLOYEE.NUMBER,1`, then `00244 LAC BL)2,2` / `00245 TXL SYS)294,2,0` / `00246 LAS 1)EMPLOYEE.NUMBER,2` — both records live simultaneously through two index registers.

**GET #4 — statement 194, inside HIGH.DETAIL (lines 170-179):** `00276 TXH CP)+22,0,CP)+19` / `00277 TSX IOC)8,4` / `00300 PZE INPUTMASTER,,SYS)260` / `00301 PZE GN)064,,SYS)283` / `00302 IOCTN* BL)2,,15` / `00303 TRA GN)065` / GN)064 block `00304-00306` / `00307 GN)065 TRA COMPARE.EMPLOYEE.NUMBERS`.

**Decrement `SYS)260` is 00404 octal = 260; `SYS)283` is 00433 octal = 283. File 1 = `04001` = 2049, file 3 = `04003` = 2051.**

**OPEN / CLOSE / STOP RUN (lines 97-98, 315-322):**

```
 97  00165 GN)000 START  TSX  SYS)175,4   007400400257  10010
 98  00166	PZE	IOC)1	          000000000001	10010
315  00517	TSX	SYS)177,4	  007400400261	10010   (CLOSE ALL FILES)
316  00520	PZE	IOC)1	          000000000001	10010
317  00521	TSX	SYS)178,4	  007400400262	10010   (STOP display)
318  00522	PZE	CP)+26,,CP)+27
319  00523	PZE	CP)+28,,CP)+29
320  00524	TSX	SYS)177,4	  007400400261	10010   (STOP RUN's own close-all)
321  00525	PZE	IOC)1	          000000000001	10010
322  00526	TXI	IOC)40,0	  100000000050	10010
```

The double close-all is why `closeFiles` skips an already-closed file (`machine.dart:251-253`; `m5-io.md:161-170`).

**FILE (IOC)9) sites, for the flow:** 00273-00275 `IOST ERROROUT,,4`; 00325-00327 same; 00514-00516 `IOST PAYRECORD,,20`; 01151-01153 `IOST CHECK,,16`; 01154-01156 `IOST PAYRECORD,,20`; 01157-01163 the **located-record** form `LXA BL)2,4 / SXA GN)089,4 / TSX IOC)9,4 / PZE OUTPUTMASTER,,0 / GN)089 IOST MASTER,,15` (address field `000000`, patched at run time); 01400-01402 `IOST BONDORDER,,6`; 01562-01564 `IOST DEPARTMENT.TOTAL,,20`.

## 6. Where the INPUTMASTER and DETAILFILE records live

**They have no address in the object program. Locate mode, fully.**

- `test/fixtures/90.05-storage-section.tsv:23` (the transcription of the 1962 `*DATA` storage map, PDF pp. 199-200): *"MASTER and DETAIL are located records and print no area (J 02.07.05)."*
- The `*DATA` section of the golden listing (`test/goldens/90.05-payroll.storage-map:24-135`) runs `CHECK 00000`, `PAYRECORD 00020`, `DEPARTMENT.TOTAL 00044`, `BONDORDER 00070`, `ERROROUT 00076`, `WORKING 00102`, `INTERNAL.TOTALS 00113`, `GRAND.TOTALS 00124`, `TABLE 00135`-`00164` — **no MASTER row and no DETAIL row anywhere in it**. The first occurrence of "MASTER" in that file after the `*FILE` cards is the calling-sequence word at :141.
- `RecordInfo.located` is set for every record on an input file: `lib/src/data/data_map.dart:229-231`, assigned at `lib/src/data/binder.dart:143` (`..located = record.inputFiles.isNotEmpty`). "A located record takes no area."
- Field references carry offset-only addresses: `00214 CAL 1)DEPARTMENT,1  450000100000  10000` and `00243 CAL 2)EMPLOYEE.NUMBER,1  450000100000  10000` — address 0, control `10000` (constant, unrelocated).

**The locator cells.** `test/goldens/90.05-payroll.code:898-907`:

```
898		USE	2	500000001671	00001
899  01666	ORG	BL)1	500000001666	00001
900  01666	PZE	IOC)29	000000000035	10010
901  01667	PZE	0	000000000000	10000
902  01670	PZE	0	000000000000	10000
903		USE	1	500000001621	00001
904  01621	RS)	BSS	30	200000000036	00001
905  01657	TS)	BSS	7	200000000007	00001
906  01666	BL)	BSS	3	200000000003	00001
907  01671	PI)	BSS	3	200000000003	00001
```

- `BL)1` = relative 01666 = **absolute 5046**, initialized `PZE IOC)29` (address 35 octal = 29) — the IOCS label area.
- `BL)2` = 01667 = **absolute 5047**, `PZE 0` — INPUTMASTER's MASTER record. IOCS fills it.
- `BL)3` = 01670 = **absolute 5048**, `PZE 0` — DETAILFILE's DETAIL record.

Because both start at zero, the first GET on each file must write the cell before any `LAC BL)n,i / TXL SYS)294,i,0` pair runs — otherwise the guard fires and prints `BASE LOCATOR NOT LOADED` (`monitor.dart:62-69`).

**Constraint on the word IOC)8 writes into `BL)n`:** it must be a clean `PZE bufferAddress` — prefix, tag and decrement all zero. The program uses the cell three different ways:

1. `LAC BL)2,1` (complement into an index register) — LOC 00212, 00241, 00244, 00333, 00352, 00533, 00555, 00563, 00566, 00637, 00661, 00727, 00772, 01175.
2. **`CAL BL)2` then `ACL CP)+43` then `SLW SYS)132`** — LOC 00265-00267, 00312-00314, 00342, 00361, 00571, 00601, 01124, 01133. The cell's *contents* are added to a `PZE field,,byte` pool word and stored as a MOVPAK byte pointer, so any non-zero prefix/decrement corrupts the byte cursor.
3. `LXA BL)2,4` at LOC 01157, whose `SXA GN)089,4` patches the located-record `IOST` address field.

**Record extents:** MASTER 15 words (`IOCTN* BL)2,,15`), DETAIL 3 words (`IOCTN* BL)3,,3`). Source descriptions at `test/fixtures/90.05-payroll.ct:3-25` (MASTER, marked `L` in the located column) and :28-35 (DETAIL). BLOCKSIZE on the cards is 300 for INPUTMASTER and 3 for DETAILFILE (`storage-map:7, 11`) — unrelated to the extent.

**Is there any BUFFER / IOCTN / file-block area in the object program? No.** The only cells the compiler allocates for I/O are the three `BL)` words above. `IOC)2`, the cell that would locate the 12-word IOCS file blocks, "has no emitter and stays unbuilt" (`docs/design/m5-io.md:131-133`). The buffer itself has no home: `m5-io.md:205-210` — *"That is locate mode, and it is why the buffer must live in core. Where the buffer lives is stage 2's first decision, and this record does not take it."*

## 7. File references, IOC)1, and the low-core map

**File reference resolution.** `lib/src/loader/loader.dart:41-52`:

```dart
int get code => (file ? 0x800 : 0) | number;
```

Type dispatch at `loader.dart:345-356` (`code >> 11`: 0 = system, 1 = file), resolved through the caller's table at `loader.dart:355` and `machine.dart:166` (`resolve: (reference) => reference.code`). So `INPUTMASTER` → 04001 octal → 2049, and the table index is `2049 - 0x800 - 1 = 0` (`machine.dart:180-182`). The generator side is `_fileSym` (`procedure.dart:650-651`) with the ordinal off the `*FILE` cards.

**IOC)1 seeding.** `machine.dart:147-158`, after the program words are written:

```dart
program.words.forEach(state.write);
state
  ..write(1, pzeWord(decrement: program.files.length))
  ..ic = program.entry;
```

Address field stays 0 deliberately — "the file list itself is Dart's, and no compiled word dereferences it" (`machine.dart:144-146`; `m5-io.md:125-133`).

**Low core (absolute addresses 0-4095) already claimed:**

| range | what | source |
|---|---|---|
| 1 | IOC)1, `PZE 0,,N` | `machine.dart:156` |
| 29-42 | IOC)29 label area, 14 words — **overlaps dispatch address 40** | `m5-io.md:232-235`, `monitor.dart:6-10`; `BL)1 = PZE IOC)29` at `.code:900` |
| 40 | IOC)40 dispatch (end of job) | `monitor.dart:22` |
| 131 | improper-data cell (D4.3) | `movpak.dart:26` |
| 132, 133 | MOVPAK source / target pointers | `movpak.dart:22-23`, `runtime.md:378-391` |
| 175, 177, 178, 294 | run-frame dispatch | `monitor.dart:19-27` |
| 180, 182, 184, 185, 190, 193, 198, 211, 212, 214, 216, 225, 226, 239, 240, 241, 243, 244, 245, 267, 268, 269, 275 | MOVPAK dispatch | `movpak.dart:71-94` |
| 2049-2055 | the sample's seven file references (`0x800 + k`) | `loader.dart:51` |
| (chartered, unbuilt) 2-17, 29, 46, 53, 54; 260-266, 283, 286-296 | the M5 IOCS charter | `m5-io.md:36-39` |

Dispatch reads the IC, not the cell contents, so a data cell may sit at a dispatch address (that is why IOC)29's overlap of 40 is harmless today, `m5-io.md:232-235`) — but the label area and the pointer cells are read *as memory*, so they are genuinely occupied. Unclaimed low core: roughly 0, 2-28, 43-130, 134-174, 179, 181, 183, 186-189, ..., 300-2047 and 2056-4095. The address table in prose is `docs/design/runtime.md:20-42`; there is no address-table constant in `machine.dart` beyond `programOrigin`.

**Where the sample program itself sits** (so a buffer can be placed above it):

| block | relative | absolute |
|---|---|---|
| `*DATA` counter 0 | 00000-00164 | 4096-4212 |
| procedure text | 00165-01620 | 4213-5008 |
| `RS)` 30 words | 01621-01656 | 5009-5038 |
| `TS)` 7 words | 01657-01665 | 5039-5045 |
| `BL)` 3 words | 01666-01670 | **5046-5048** |
| `PI)` 3 words | 01671-01673 | 5049-5051 |
| `CP)` pool | 01674-01771 | 5052-**5113** |

⚠️ `docs/design/runtime.md:41-42` says "the 90.05 sample then holds addresses 4096 to 5031". That conflates the placed-word **count** (936, `machine_test.dart:176`) with the address **span**: `BSS` reservations advance the location counter without placing a word. The golden's last placed word is relative `01771` (`.code:969`) = absolute **5113**. Treat the golden as authoritative and fix the doc line.

## 8. Test infrastructure

`test/runtime/runtime_support.dart` — helper signatures:

```dart
const int start = Machine.programOrigin;                       // :14
Machine machine(Map<int,int> words,
    {List<LoaderFile> files = const [], Directory? tapes});    // :29-33
Directory tempDirectory(String prefix);                        // :53
LoaderFile loaderFile(int number, {required String type, required String unit}); // :62-66
int tsx(int entry);                                            // :78
int txi(int entry, int count);                                 // :82
int pze(int location, int byte);                               // :86
int axt(int count);                                            // :89
int link(int location);                                        // :104
int octal(String digits);                                      // :107
final int endOfJob;                                            // :111  TXI IOC)40,0
int bcdWord(List<int> codes); int characters(String glyphs);   // :114, :123
int codeAt(Machine subject, int word, int i);                  // :129
String glyphsAt(Machine subject, int word, int count);         // :134
Machine dispatch({required List<int> words, int sourceByte = 0, int targetByte = 0,
    List<int> sourceImage = const [], List<int> targetImage = const [],
    int maxSteps = 30});                                       // :140-147
(JobCompilation, Machine) compiled(List<String> source);       // :165
int addressOf(JobCompilation job, String label);               // :175
```

- **Hand-built object program:** `machine({address: word, ...})` builds a `LoadedProgram` directly at `programOrigin` and preloads junk into XR1/XR2 (:45-48). Word builders come from `test/emulator/asm.dart:9` (`typeB(operation, {address, tag, flag})`) and `:14` (`typeA(prefix, {decrement, tag, address})`).
- **Feeding a tape directory:** `tempDirectory('comtran-tapes')` then `machine(..., files: [loaderFile(1, type:'I', unit:'D1')], tapes: tapes)` — see `test/runtime/monitor_test.dart:93-115`, which writes raw bytes with `File('${tapes.path}/D1.tap').writeAsBytesSync(...)` and asserts the post-run bytes with `readAsBytesSync()`.
- **Compiling and running the sample:** `compiled(source)` (`:165-172`) compiles, punches, loads and asserts `endOfJob` at `maxSteps: 5000`; the sample path is `compileDeck(loadJobDeck()).jobs.single` then `Machine.load(jobDeck(job, _options)!.cards)` (`machine_test.dart:174-175`).
- **Asserting core after a run:** `subject.state.read(addressOf(job, 'NUM'))` (`machine_test.dart:255, 269`), `subject.state.read(targetArea)` compared to `characters('ABCDEF')` (`movpak_test.dart:157-158`), `glyphsAt`/`codeAt` for character fields, and `subject.printed` / `result.display` for the on-line printer.
- **End-to-end CLI:** `_compileSample(options)` and `_compileAndRun(source)` at `machine_test.dart:106-124` shell out to `dart run comtran:comtranc … --run [--tapes=DIR]` and assert on exit code, stdout and stderr.
- Other runtime tests: `monitor_test.dart` (run frame, one group per entry, tape-mark and refused-open cases), `movpak_protocol_test.dart` (one case per word shape, asserting resume address, XR1, XR2, the XR4 link and session state — `:17-40`), `movpak_test.dart` (decision conformance per member, plus two whole compiled programs), `movpak_edit_test.dart` (the eight attested renderings).

## 9. M4-15 in full, plus every open item touching GET / buffers / blocking / locate mode

**M4-15** — `docs/design/m4-codegen.md:844-863`, verbatim:

```
- **M4-15. Attested shapes, deferred runtime.** M4 emits the I/O verbs'
  calling sequences so the listing and addresses reproduce; M5 makes them
  run. The shapes: the run frame opens with `TSX SYS)175,4 / PZE IOC)1`
  (open all) at the entry word GN)000; GET is the stamp word, then
  `TSX IOC)8,4 / PZE file,,SYS)260 / PZE atEnd,,SYS)283 /` the buffer
  descriptor word `BL)n,,len`, then the AT END out-of-line block per
  D6.6; FILE of a working-storage record is
  `TSX IOC)9,4 / PZE file,,0 / IOST record,,len`;
  FILE of a located record patches its own IOST word first —
  `LXA BL)n,4 / SXA GN)a,4` then the call, GN)a labeling the IOST word
  (attested, statement 208). CLOSE ALL FILES is the SYS)177 pair. The
  record's file lists are public since M3-11; the `04000 + k` ordinal
  reads off the FILE cards: no new binder exposure.
  **Amended 2026-08-17, chunk B6.** Every other I/O form refuses (M4-2
  as amended): OPEN or CLOSE naming files (notes section 7), GET RECORD
  FROM, GET with no AT END (SYS)265 unattested), GET from a file
  declaring ON ERROR (the SYS)283 replacement is unknown), GET of a
  transmitted record, and FILE record IN file. A GET or FILE refuses
  off the roster, on other than one matching file, or where two FILE
  cards share a name.
```

**`ponytail:` comments.** Exactly one in the repository, and it is not in `lib/src/runtime/` — `docs/design/m5-io.md:99-101`:

> Nothing in this project reads the bit. **ponytail: parity is not written; compute it if a tape must feed another emulator.**

**Open items and decisions bearing on stage 2:**

- `m5-io.md:205-210` (M5-5) — the `IOCTN*` word names a base locator and a record extent; "the handler writes the address of the record into that locator … That is locate mode, and it is why the buffer must live in core. **Where the buffer lives is stage 2's first decision, and this record does not take it.**"
- `m5-io.md:190-203` (M5-5) — the four GET exits table (normal four words on / AT END = address of p2 / ON ERROR = decrement of p2 = SYS)283 / record length = decrement of p1 = SYS)260), and "A GET on a file that is not open takes this GET's own AT END exit and prints nothing (D6.5)."
- `m5-io.md:113-116` (M5-3) — "The buffer and the read position arrive with IOC)8, because no word of stage 1 reads them."
- `m5-io.md:104-107` (M5-2) — "A block is a record, and blocks vary in length. A file's BLOCKSIZE is not the block length on tape. DETAILFILE declares BLOCKSIZE 3 and its records sit 'in the first portion of tape blocks 14 words long'. **A reader takes the record extent from the file, not from the block it arrives in.**"
- `m5-io.md:224-238` open items — the sample's input tapes do not survive (M6 must reconstruct them); IOC)29 overlaps IOC)40; SYS)284, 285, 289, 290, 293, 295 are undefined.
- `m5-io.md:131-133` — "IOC)2, the cell that locates the 12-word IOCS file blocks, has no emitter and stays unbuilt."
- `runtime.md:87-90` (RT-1) — "It then fills its work areas through MOVPAK (RT-3) and reaches IOC)8, the GET, which throws. **M5 stage 2 lands that entry.**" Also `runtime.md:120-130` — each remaining entry lands with the codegen shape that first emits it.
- `runtime.md:352-357` (RT-3, the register contract) — "**The run frame of RT-2 and the IOCS calls take a full cache clear after them, so they may write any register.**" IOC)8 is free to clobber XR1, XR2 and (with care) XR4; `_callClears()` at `procedure.dart:1094, 1844` is the generator side.
- **D6.5** (`docs/design/decisions.md:995-1006`) — GET on an unopened file takes that GET's own end-of-file exit, no message. Implementation note at :1002: "the IOC)8 read entry tests the FCB open flag and branches to the end-of-file exit held in the address field of the third calling-sequence word." ⚠️ that says "third"; the AT END word is parameter **2** (the third word counting the TSX).
- **D6.6** (`decisions.md:1008-1019`) — AT END placement, the out-of-line block, the DO triple, SYS)265/SYS)283 planting, and "the clause fires on the GET **after** the last record was delivered."
- **D6.7** (`decisions.md:1021-1032`) — "Implement blocking as arithmetic, with no threshold rule. Pack records into BLOCKSIZE-word blocks in order. A record must be complete within one block… A record described with BEGIN always starts a new block." Implementation explicitly names "SYS-IOC runtime (blocking on output, **deblocking on input**), and the compiler's buffer sizing and base locators (BL)n)". Oracle: J's Example 1 (REC1 64 / REC2 128 / REC3 192, BLOCKSIZE 256).
- **D6.3** (`decisions.md:969-980`) — the close path releases "the storage area allocated to the file", i.e. the buffer, and flushes partial blocks. Stage 3's concern but it constrains where the buffer may live.
- **D6.4** (`decisions.md:982-993`) — the report path: BCD print-image records on tape, one record = one or more print lines, RCDMRK one-character record marks.
- `docs/design/emulator.md:20, 105` — `PZE, MZE, OCT, IOST, IOCTN` data words "are data for those handlers; the CPU" never decodes them.

## 10. The `comtranc --run` driver path

**`--tapes` does not live in `lib/src/driver/`.** `lib/src/driver/driver.dart` is the compile pipeline only (front end, parse, semantics, codegen); it has no `Machine` reference. Everything runtime-facing is in `bin/comtranc.dart`:

- Usage text: `bin/comtranc.dart:34-40` (`--run`, `--tapes=DIR`, "one image per unit: UNIT1 'D1' reads and writes DIR/D1.tap").
- Flag parsing: `:126` (`Directory? tapes;`), `:152` (`--run`), `:154-160` (`--tapes=`; an empty path writes the usage and returns 2).
- Pre-flight: `:209-213` — `if (tapes != null && !tapes.existsSync())` → `error: no tape directory at <path>` and exit 2. The comment says why: "Without this the run names the first file that failed, and the directory that failed goes unnamed."
- Step budget: `:71-75`, `const int _stepBudget = 1000000`.
- Dispatch to the run: `:307` `failed |= !_runObjectProgram(job, options, index + 1, tapes);`
- The run itself, `bin/comtranc.dart:340-370`:

```dart
final machine = Machine.load(punched.cards, tapes: tapes);
try {
  final RunResult result = machine.run(maxSteps: _stepBudget);
  result.display.forEach(stdout.writeln);
  if (result.outcome == RunOutcome.stepLimit) {
    stderr.writeln('error: job $number: still running after $_stepBudget steps');
  }
  // An error exit has already printed the monitor's own message on
  // the display (RT-2), so the tool adds none of its own.
  return result.outcome == RunOutcome.endOfJob;
} on RunFault catch (e) {
  machine.printed.forEach(stdout.writeln);
  stderr.writeln('error: job $number: $e');
  return false;
}
```

Display lines go to **stdout** after the listing (`Machine.display` :266-268, `printed` :271); stop/fault messages go to **stderr** prefixed `error: job N:`. Exit-status rules and their tests: `machine_test.dart:273-289`; `runtime.md:99-104`.

---

## Could not find

- **Any SIMH `.tap` reader, writer, record encoder/decoder or word↔byte codec.** Only `_tapeMark = [0,0,0,0]` (`machine.dart:113`) and raw `writeAsBytesSync` calls. The 6-bytes-per-word frame order exists solely as prose at `m5-io.md:84-94`; no test pins it (the only test records are 2-byte payloads at `monitor_test.dart:99, 143`). Stage 2 builds the reader from nothing.
- **Any buffer, IOCTN, or file-block area in the object program.** No such reservation in `test/goldens/90.05-payroll.code` or in the `*DATA` pages of `test/goldens/90.05-payroll.storage-map`; `IOC)2` is explicitly unbuilt (`m5-io.md:131-133`).
- **Any read position, buffer field or record counter on `RuntimeFile`.** Two fields only (`machine.dart:102-110`).
- **Any handler at 260, 283 or 265**, and no `SYS)130` arming (`runtime.md:138-142`).
- **Any `ponytail:` comment in `lib/src/runtime/`** or in `docs/design/runtime.md` — the single one in the repo is `m5-io.md:99`.
- **Any `--tapes` or `Machine` reference in `lib/src/driver/`** — it is all in `bin/comtranc.dart`.
- **Any runtime consumer of `LoaderFile.blocksize`, `open` or `close`.** `m5-io.md:171-176` records that stage 1 reads neither close code.
- **Any address-table constant in code** — `Machine.programOrigin` is the only one; the low-core map exists only as prose in `runtime.md:20-42` and had to be assembled from the handler maps.
- **A doc/golden conflict:** `runtime.md:41-42` says the sample holds 4096-5031; the golden's last placed word is absolute 5113.
- **A doc/code conflict:** `decisions.md:1002` (D6.5) calls the AT END exit "the address field of the **third** calling-sequence word"; it is the address field of parameter word 2 (the third word counting the `TSX`). Worth a clarifying edit when stage 2 lands.
