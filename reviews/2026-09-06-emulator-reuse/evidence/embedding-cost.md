# What replacing lib/src/emulator with a C core would cost

Measured against this repository. The agent's own text, unedited.

**Bottom line: replacing `lib/src/emulator/` with a C emulator deletes 424 lines of Dart, keeps everything else, adds roughly 42,000–47,000 lines of vendored C plus a hand-written shim, forfeits the browser build, and breaks the single-authority opcode table the byte-exact codegen golden rests on. It is also barred by a Locked decision.**

---

## 1. The interface M4 stage 4 needs from the CPU

The dispatch layer described in `docs/design/m4-codegen.md:893-900` is: "before each step at an address registered as a SYS)/IOC) entry, the dispatcher runs the Dart handler instead of the CPU… a TSX-linked handler reads its calling sequence through XR4, honors the resume convention (parameter-word count plus one), and returns control."

That is a five-line loop over an existing surface. The whole CPU-side contract:

`lib/src/emulator/cpu.dart:36-47`
```dart
final class Cpu {
  Cpu(this.state);
  final MachineState state;
  void step() { … }
}
```

`lib/src/emulator/cpu.dart:10-11`
```dart
final class UnimplementedOpcode7090 implements Exception {
  UnimplementedOpcode7090(this.operation, this.location, this.word);
```
(fields: `String operation`, `int location`, `int word` — cpu.dart:16, 20, 23.)

`lib/src/emulator/machine_state.dart:12-107` — everything a handler touches:
```dart
static const int memoryWords = 32768;          // :14
final Uint64List memory = Uint64List(memoryWords); // :31
int acSign = 0; int acMagnitude = 0;           // :34, :37
int mq = 0; int si = 0; int ic = 0;            // :40, :44, :47
bool overflow = false; bool divideCheck = false; // :50, :53
int get acWord;  int get acLogicalWord;        // :60, :64
int xrRead(int tag);  void xrWrite(int tag, int value); // :68, :85
int read(int location);  void write(int location, int word); // :100, :106
```

The loader hands off through `LoadedProgram` (`lib/src/loader/loader.dart:95-120`): `final int origin`, `final int entry`, `final Map<int, int> words`. `docs/design/loader.md` LD-3 states the plan in one sentence: "The machine assembly stage writes the words into `MachineState` and runs."

So the dispatch layer is `while (true) { final h = table[m.ic]; if (h != null) { h(m); continue; } cpu.step(); }`. Nothing in it is hard. The whole M4 stage 4 cost is in the ~90 SYS)/IOC) compute handlers (M4-17), which a C CPU does not write for you.

## 2. Trapping through dart:ffi — what crosses, and how often

Two shapes, both bad in a different way.

**Per-step.** C executes one instruction and returns; Dart compares `state.ic` to the entry table. One boundary crossing per instruction. I measured both sides on this machine (Dart 3.12.2, macos_arm64): a non-leaf FFI call costs 7.79 ns against 2.64 ns for a plain Dart call, so ~5.2 ns of marginal overhead — and one Dart `Cpu.step()` today costs 15.66 ns (TXI self-loop) to 31.26 ns (CLA with an IC reset). The crossing eats a third of the instruction. C's speed advantage is gone before it starts.

**Run-until-trap.** Hand C a set of entry addresses and let it run until the IC hits one. Better, but the trap is not rare: the sample's object program has 67 `TSX` sites into SYS)/IOC) entries (`test/goldens/90.05-payroll.code`) among ~771 procedure words (procedure text starts at 00165 of 936 total). That is one runtime entry every ~11.5 words *statically* — and the hot targets are the move package (SYS)182 ×26, SYS)267 ×25, SYS)180 ×25, SYS)133 ×22), which is what a COMTRAN loop body is made of. Dynamically the density gets worse, not better, because MOVE and arithmetic verbs are the loop and each one is a TSX. C would run for roughly a dozen instructions between crossings.

**What crosses.** Memory need not copy: `Pointer<Uint64>.asTypedList(32768)` gives Dart a zero-copy view, so `MachineState.memory` stays a `Uint64List` and `read`/`write` keep their signatures. Registers cannot ride along. No third-party core represents the AC as this repo does — sign plus a 37-bit magnitude with Q at bit 36 and P at bit 35 (`machine_state.dart:18-37`, `docs/design/emulator.md` §2) — so `acSign`, `acMagnitude`, `mq`, `si`, `ic`, `overflow`, `divideCheck`, `xrRead`, `xrWrite` all become shim accessors over an FFI `Struct`, converting layout on every touch. Every handler in M4-17 is register-heavy by construction: it reads its calling sequence through XR4 and returns results in the AC.

**And C cannot throw.** `UnimplementedOpcode7090` becomes a status code plus a Dart rethrow. The guarantee that goes with it does not survive the trip — see §6.

## 3. A subprocess boundary instead

Worse on every axis. There is no shared memory, so per trap you either ship the whole core — 32,768 × 8 = 262,144 bytes — or run a request/response protocol in which each handler's `read()` is a pipe round trip. Handlers read many words each (calling sequence, descriptors, result cells), so it is the latter: microseconds per word against the ~31 ns a `MachineState.read` costs inside `step()` today. Three orders of magnitude, in the inner loop of every handler.

Two extras: `dart:io`'s `Process` does not exist in a wasm build either, so the browser is dead down this road too; and every one of the 1179 tests that touches execution would need the built binary present on the machine, which reintroduces exactly the build problem the subprocess was meant to dodge.

## 4. What CI has to grow

Today `.github/workflows/ci.yml` is 39 lines: one job, `runs-on: ubuntu-latest` (ci.yml:17), a pinned SDK, a pub cache, and six commands — `dart pub get`, `dart format` over `lib bin test tool web` (ci.yml:29), `dart analyze --fatal-infos`, `dart test`, `deckconv check .`, `dart run tool/build_web.dart`. `pages.yml` is the same runner, and runs `dart test` plus the web build before deploying. `vscode-ext.yml` is npm, for the extension only. **There is no macOS runner anywhere in the repository, and no C toolchain step.**

To build a C library on macOS and Linux the gate grows:
- a `strategy.matrix` over `ubuntu-latest` and `macos-latest`, doubling every job — and macOS minutes bill at ten times the Linux rate;
- `hook/` added to the `dart format` path list (ci.yml:29), or the hook silently escapes the format gate; `dart analyze` already covers it;
- three new direct dependencies pulling 20 packages into the lockfile (`hooks` 2.2.0, `code_assets` 2.0.0, `native_toolchain_c` 0.19.4 plus 17 transitive — measured by `dart pub add` in a scratch package). `native_toolchain_c`'s own README says: "**Status: Experimental**… published under the labs.dart.dev publisher… These packages have a much higher expected rate of API and breaking changes." The pub cache on this machine already holds six `hooks` versions and five `code_assets` versions, which is that churn in evidence;
- the 10-minute timeout (ci.yml:19) now has to absorb a C compile on both runners.

## 5. What gets deleted, and what gets written

**The emulator directory is not a module. It is the repository's shared instruction vocabulary.** Four files outside it import it:

- `lib/src/codegen/procedure.dart:32-33` — `import '../emulator/decode.dart'; import '../emulator/word.dart';` (164 `Op.`/`Instruction.` references)
- `lib/src/codegen/encode.dart:12-13` — same two imports (42 references)
- `lib/src/loader/loader.dart:18-19` — `machine_state.dart` and `word.dart`
- `lib/src/loader/object_deck.dart:18` — `word.dart`

63 `Word36.` references live outside `lib/src/emulator/`. `loader.dart:359` reads `MachineState.memoryWords`.

So the deletion ledger is small and the retained coupling is large:

| | Lines | Fate |
|---|---|---|
| `cpu.dart` | 424 | The only file a C core replaces |
| `decode.dart` | 264 | **Stays** — codegen encodes through this table |
| `word.dart` | 88 | **Stays** — deck writer and codegen bit fields |
| `machine_state.dart` | 113 | Stays as an FFI shim; `memoryWords` still has a reader |

Tests: `test/emulator/` is 1614 lines and 139 `test()` cases (of 1179 in the suite). The 115 CPU cases and 9 `machine_state` cases are **not deleted** — if the FFI wrapper preserves the `Cpu`/`MachineState` surface (and it must, because codegen, the loader and the tests bind to it) those 1412 lines become the conformance suite that proves the foreign core matches the manual. `decode_test.dart` (9 cases) and `word_test.dart` (6) are untouched.

Written new: `hook/build.dart` (~20 lines), FFI bindings and the register `Struct` shim (~150–250 Dart), and a C shim that gates opcodes, exposes `step`, holds the trap-address set and adapts register layout (realistically 300–600 lines of C you own and must test). Plus the vendored C itself — see the SIMH numbers below.

**There is no packaged 7090 CPU library.** The only serious candidate I know of is SIMH's I7000 family, which I cloned and measured: `I7000/i7090_cpu.c` is **4,460 lines**, `i7090_chan.c` 1,710, `i7090_sys.c` 1,056, `i7090_defs.h` 438, `i7000_defs.h` 641, plus card reader/punch/printer/drum at 346/308/708/283/253. It is MIT-licensed (Richard Cornwell, 2005-2016), so licensing is fine. It is not a library: it declares its own global `t_uint64 M[MAXMEMSIZE]` at `i7090_cpu.c:227`, decrements SIMH's `sim_interval` inside the instruction loop, and **calls `chan_proc()` from inside that loop** (`i7090_cpu.c:933, 959`). Its minimum SCP dependency set is `scp.c` (18,128 lines), `sim_console.c` (4,537), `sim_fio.c` (3,232), `sim_timer.c` (3,936), `sim_sock.c` (1,384), `sim_tmxr.c` (5,847), `sim_tape.c` (5,173) — about **42,000 lines** before you write a line of your own. Using it means forking it, not linking it.

## 6. Does dart:ffi work here — and the two things that break

**Yes, mechanically, and I proved it.** I built a scratch package with `hook/build.dart` using `CLibrary` from `native_toolchain_c`, a one-function C file, and a `@Native`/`@DefaultAsset` binding. With the repository's own SDK (3.12.2), `dart test` printed "Running build hooks…" and passed with no experiment flag; `dart run` did the same. The mechanism is a build hook that compiles from source at build time and registers a `CodeAsset` — **not** a prebuilt `.dylib`/`.so` committed to the repo. The SDK has a `dart build` command for bundling code assets into a CLI application. So the plumbing is real and no longer experimental at the SDK level, even though the toolchain package it depends on still is.

**But the wasm build rejects it.** I compiled a file importing `dart:ffi` with `dart compile wasm` on 3.12.2 and got:
```
Error: 'dart:ffi' can't be imported when compiling to Wasm.
```
`ci.yml:35` runs `dart run tool/build_web.dart`, which runs `dart compile wasm` (`tool/build_web.dart:41-48`), and `pages.yml` deploys from it. Today the web closure reaches `decode.dart` and `word.dart` (web/main.dart → `web_compile.dart:21-22` → `driver.dart:12` → `codegen/codegen.dart` → `procedure.dart:32-33`) but **not** `cpu.dart` — I checked, and nothing under `driver/`, `codegen/`, `emit_code.dart` or `web/` imports `loader/` or `cpu.dart`. So an FFI-backed `cpu.dart` would not break CI *today*. It would permanently forfeit running an object program in the browser, which `docs/HANDOVER.md:585` names explicitly: "Any later browser work inherits this finding, **the M4 emulator most of all**." The alternative is keeping the Dart CPU as a second implementation — two emulators, both owing the same 124 conformance tests.

**And the fail-loud guarantee cannot cross.** `cpu.dart:47-66` throws before the IC advances for anything outside the 43 harvested opcodes; `docs/design/emulator.md` §7: "The CPU throws it before any state change, so a failed step never half-executes," and §8: "every one decodes to a typed throw, never to silence." A general 7090 core executes all ~200 instructions and would happily run an unharvested opcode whose behavior no citation in this repository covers. Restoring ED-4 means a pre-execution opcode filter in the C shim — a second copy of the octal table. `lib/src/codegen/encode.dart:3-9` refuses that in as many words:

> "`lib/src/emulator/decode.dart` holds the attested opcode table and reads a word back to an `Op`. Codegen needs the same table forwards, and **a second copy of it would be a second authority for the octal codes the OCTAL column prints.** So this file states no code of its own… the two directions cannot drift."

That single table is what makes the byte-exact 90.05 listing reproduction trustworthy. A C-side copy is a second authority for the same octal digits, on the far side of a language boundary, unverifiable by `test/encode_test.dart`.

## 7. Two repository rules it collides with

- **`CLAUDE.md` §11, the no-untested-and-unexercised-code rule.** Vendoring i7090 brings ~160 unharvested instructions plus channel and device code that no COMTRAN program reaches and no test asserts on. That is the banned quadrant, in bulk. And `chan_proc()` inside the CPU loop is channel-level I/O, which `docs/design/decisions.md` D0.7 forbids: "I/O is emulated at the IOCS level."
- **D0.3 is Locked** (`docs/design/decisions.md:53`) and says at :181-186: "Backend: real 709/7090 object code, run on **our own emulator**… A word-exact 36-bit 7090 CPU core executes the generated code." A design record outranks the code (`CLAUDE.md` §6). Swapping the core is not an engineering call; it is an amendment to a locked Jack-level decision.

## Numbers

**Existing Dart, measured with wc -l:**
- `lib/src/emulator/`: 889 lines — `cpu.dart` 424, `decode.dart` 264, `machine_state.dart` 113, `word.dart` 88.
- `test/emulator/`: 1614 lines, 139 `test()` cases — cpu_fixed_point 359 lines/29 cases, cpu_transfer_index 306/29, cpu_shift 273/27, cpu_sense_convert 180/14, cpu_word_logic 133/10, decode 128/9, cpu_edge_cases 89/6, machine_state 72/9, word_test 55/6, asm.dart 19 (helpers).
- Whole suite: **1179** `test()` calls across `test/`.
- `lib/src/loader/`: 613 lines (loader.dart 390, object_deck.dart 223).
- `lib/src/codegen/encode.dart` 114, `test/encode_test.dart` 109.

**Coupling out of the emulator directory:**
- 63 `Word36.` references outside `lib/src/emulator/` (18 in `lib/`, rest in tests).
- 224 `Op.`/`Instruction.` references in lib/bin/tool/web outside the emulator: procedure.dart 164, encode.dart 42, expression_parser.dart 8, storage_map.dart 3, blocks.dart 3, emit_parse.dart 3, codegen.dart 1.
- 5 import sites: procedure.dart:32-33, encode.dart:12-13, loader.dart:18-19, object_deck.dart:18, comtran.dart:64-67.
- 1 `MachineState` reference outside the emulator: loader.dart:359 (`memoryWords`).

**Benchmarks (this machine, Dart 3.12.2 stable, macos_arm64, 20M iterations after 2M warm-up):**
- `Cpu.step()` TXI self-loop: **15.66 ns/instruction**.
- `Cpu.step()` CLA + IC reset: **31.26 ns/instruction**.
- Plain Dart call: **2.64 ns**. Non-leaf FFI call into a hook-built C library: **7.79 ns** → ~5.2 ns marginal per boundary crossing.

**Trap density (static, from `test/goldens/90.05-payroll.code`):**
- 67 `TSX` sites into SYS)/IOC) entries; 936 object words; procedure text from 00165 → ~771 words → one runtime entry per ~11.5 procedure words.
- Hottest targets: SYS)182 ×26, SYS)267 ×25, SYS)180 ×25, SYS)133 ×22, SYS)294 ×20, SYS)132 ×13, IOC)9 ×8, IOC)8 ×4.
- Core image if copied per trap: 32768 × 8 = **262,144 bytes**.

**CI today:**
- `ci.yml` 39 lines, 1 job, `ubuntu-latest`, 10-min timeout, 6 run steps; format path = `lib bin test tool web`.
- `pages.yml` 51 lines, `ubuntu-latest`, runs `dart test` + `dart run tool/build_web.dart`.
- macOS runners in the repository: **0**. C toolchain steps: **0**. Matrix jobs: **0**.
- `dart pub add hooks native_toolchain_c` resolves **20 packages** (hooks 2.2.0, code_assets 2.0.0, native_toolchain_c 0.19.4 + 17 transitive).

**SIMH I7000, cloned and counted:**
- `i7090_cpu.c` **4,460**, `i7090_chan.c` 1,710, `i7090_sys.c` 1,056, `i7090_defs.h` 438, `i7000_defs.h` 641, cdr 346, cdp 308, lpr 708, drum 283, hdrum 253.
- SCP core needed to link: scp.c 18,128 + sim_console 4,537 + sim_fio 3,232 + sim_timer 3,936 + sim_sock 1,384 + sim_tmxr 5,847 + sim_tape 5,173 = **~42,200 lines**.
- Total vendored C, low estimate: **~47,000 lines**. License MIT (R. Cornwell 2005-2016).

**Net Dart ledger for the swap:**
- Deleted: **424** lines (cpu.dart execute cases). Nothing else — decode.dart (264) and word.dart (88) are load-bearing for codegen and the deck writer.
- Retained-but-retargeted: **1,412** test lines / **124** test cases become the C core's conformance suite.
- Written: ~20 lines hook, ~150–250 lines FFI/Struct shim in Dart, ~300–600 lines of hand-written C shim, on top of ~47,000 vendored.

**Empirical SDK probes (Dart 3.12.2):**
- `dart compile wasm` on a file importing `dart:ffi`: fails — "'dart:ffi' can't be imported when compiling to Wasm."
- `dart test` and `dart run` execute `hook/build.dart` automatically, no experiment flag; a `CLibrary`-compiled C function called via `@Native` returned correctly.

## Verdict

Don't do it. The swap deletes 424 lines of Dart and adds ~47,000 lines of vendored C plus a shim you own, pays a boundary crossing every ~11 instructions against a Dart step that already costs 15-31 ns, adds a macOS matrix and an experimental labs-publisher toolchain to a CI gate that today has no native step, forfeits browser execution outright (dart:ffi cannot compile to wasm, proven on this SDK), and forces a second copy of the octal opcode table in C — the exact thing `lib/src/codegen/encode.dart:3-9` refuses, and the table the byte-exact 90.05 golden depends on. It also cannot be decided here: D0.3 is Locked at `docs/design/decisions.md:53` and says "our own emulator". The remaining M4 stage 4 work — the dispatch loop and ~90 Dart runtime handlers — is not work a C CPU does for you; the CPU is the part that is already finished.
