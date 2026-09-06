# Candidate profiles — the SIMH family

One section per profiled candidate. Every field is the profiling agent's own
text, unedited.


## Classic SIMH (simh/simh), I7094 module

`https://github.com/simh/simh`

### sevenOhNineZero

YES — a genuine 7090 model, not a 7094 with a flag. Three pieces of source evidence, plus a measured run.

1. The model is a first-class CPU option. `I7094/i7094_cpu.c:335`:
```
MTAB cpu_mod[] = {
    { MTAB_XTD | MTAB_VDV, I_9X|I_94|I_CT, "MODEL", "CTSS",
      &cpu_set_model, &cpu_show_model, NULL },
    { MTAB_XTD | MTAB_VDV, I_9X|I_94, NULL, "7094",
      &cpu_set_model, NULL, NULL },
    { MTAB_XTD | MTAB_VDV, I_9X, NULL, "7090",
      &cpu_set_model, NULL, NULL },
```
`i7094_defs.h:199` defines `#define I_9X 0x02 /* 7090, 7094, CTSS */` and `#define I_94 0x04 /* 7094, CTSS */`, and there is a per-opcode flag table `const uint8 op_flags[1024]` (i7094_cpu.c:357) marking every 7094-only instruction.

2. The gate is enforced in the fetch path, i7094_cpu.c:798:
```
        fl = op_flags[op];                              /* get flags */
        if (fl & I_MODEL & ~cpu_model) {                /* invalid for model? */
            if (stop_illop)                             /* possible stop */
                reason = STOP_ILLEG;
            continue;
            }
```

3. Index registers are modelled correctly, not just counted. `SET CPU 7090` forces multi-tag mode on (i7094_cpu.c:2233 `if (cpu_model & (I_94|I_CT)) mode_multi = 0; else mode_multi = 1;`), and `get_xri()` at i7094_cpu.c:1997 then implements the real 7090 three-register OR:
```
    if (mode_multi) {
        uint32 r = 0;
        if (tag & 1) r = r | XR[1];
        if (tag & 2) r = r | XR[2];
        if (tag & 4) r = r | XR[4];
        return r & EAMASK;
        }
    return XR[tag] & EAMASK;
```
The official doc agrees: "7090 uses only XR1, XR2, XR4" and memory is "32KW on a 7090 or 7094 CPU, 64KW on a CTSS CPU" (opensimh.org/simdocs/i7094_doc.html).

MEASURED: I built the simulator and ran it. Depositing DFAD (double-precision float add, opcode 0301, a 7094 instruction) at location 101 and running:
- `set cpu 7090` → `Undefined instruction, PC: 00102` (PC has already advanced past the offending word at 101).
- `set cpu 7094`, identical memory → no such stop; the program ran to the halt.

One caveat that matters for your "silent divergence" concern: `stop_illop` is a settable register (`{ FLDATA (STOP_ILL, stop_illop, 0) }`, i7094_cpu.c:330) defaulting to 1. If anyone clears it, the illegal instruction is skipped by the `continue` with no diagnostic — the silent divergence comes back. Leave it set.

### embeddable

Both, with a wrinkle: an interactive CLI, plus a real documented C embedding API (`sim_frontpanel`) that drives the simulator as a SEPARATE PROCESS over a socket. Nothing links the CPU core in-process out of the box.

The trap semantics are exactly what you need. i7094_cpu.c:688, at the top of the fetch loop, before the instruction at PC is executed:
```
        if (sim_brk_summ && sim_brk_test (PC, SWMASK ('E'))) {  /* breakpoint? */
            reason = STOP_IBKPT;                        /* stop simulation */
            break;
            }
```
`sim_brk_test (t_addr bloc, uint32 btyp)` is declared in scp.h:226; `extern t_stat sim_instr (void);` in scp.h:365; memory is a plain non-static global `t_uint64 *M` (i7094_cpu.c:162) with `cpu_ex`/`cpu_dep` (i7094_cpu.c:2258/2270) as the examine/deposit hooks.

MEASURED, the whole intercept-compute-resume cycle on the binary I built:
```
break 102
go 100
  Breakpoint, PC: 00102 (ADD 200)     <- stopped BEFORE executing 102
e AC        -> AC: 0000000000002      <- host reads machine state
d AC 7777                             <- host writes the handler's result
d PC 103                              <- host skips the intercepted routine
cont
  HALT instruction, PC: 00104
e AC        -> AC: 0000000007777
```
That is your runtime-entry-point dispatch, working today.

The C API, from `sim_frontpanel.h` (647 lines, backed by 105 KB of `sim_frontpanel.c`): `sim_panel_start_simulator`, `sim_panel_break_set` / `_clear`, `sim_panel_exec_run` / `_halt` / `_step` / `_boot` / `_start`, `sim_panel_halt_text`, `sim_panel_gen_examine` / `_gen_deposit`, `sim_panel_mem_examine` / `_mem_deposit` / `_mem_deposit_instruction`, `sim_panel_set_register_value`, `sim_panel_add_register` / `_get_registers`.

Two limits to be clear about. First, it is not in-process: the header's own parameter is "`sim_path` the path to the simulator binary", and it warns "The simulator binary must be built from the same version simh source code that the frontpanel API was acquired from". Second, there is no breakpoint callback — a hit halts the simulator and the host discovers it; `sim_panel_halt_text` returns "the simulator output immediately prior to the most recent transition to the Halt state". You poll and parse, you do not get called back.

Linking the core directly is possible but is a fork: `int main (int argc, char *argv[])` sits at scp.c:3011, so a shared library needs that removed — and see the license field for why touching scp.c specifically is the one edit with a licensing consequence.

### battleTested

Weaker than the project's reputation suggests, and I want to be precise about which SIMH module the famous evidence belongs to.

What does NOT exist: there is no test suite for this CPU. `find . -type d -name tests` on the clone returns `PDP8/tests`, `VAX/tests`, `I650/tests`, `SEL32/tests`, `PDP11/tests`, `PDP18B/tests`, `linc/tests`, `imlac/tests`, `tt2500/tests` — and no `I7094/tests`, no `I7000/tests`. There are no CI workflows either: `.github/` contains exactly one file, `ISSUE_TEMPLATE.md`. The only automated check my build ran was the framework-generic `RegisterSanityCheck` ("Running internal register sanity checks on IBM 7094 simulator. *** Good Registers in IBM 7094 simulator."), which validates REG-table declarations, not instruction semantics.

What DOES exist, and it is real. The strongest single line is in `I7094/i7094_defs.h:27`:
```
   This simulator incorporates prior work by Paul Pierce, Dave Pitts, and Rob
   Storey.  Tom Van Vleck, Stan Dunten, Jerry Saltzer, and other CTSS veterans
   helped to reconstruct the CTSS hardware RPQ's.  Dave Pitts gets special
   thanks for patiently coaching me through IBSYS debug.
```
So Supnik debugged it against IBSYS. `I7094/i7094_bug_history.txt` records 67 numbered bugs "Found and Fixed During Simulator Debug", and they are the kind only real software surfaces — "21. CPU: Multi-tag mode stores OR'd value of tags on any index read except normal effective address", "25. CPU: Floating add with unlike signs and equal magnitudes, result sign is sign of SR rather than sign of AC". Three opcodes carry `case 00205: /* for diagnostic */` comments (i7094_cpu.c:1045, 1064, 1074), implemented because period diagnostics used them.

The important disambiguation: the publicly documented, still-running CTSS is on a DIFFERENT simulator. multicians.org/thvv/7094.html says "Dave Pitts has created a version of CTSS running on a 7094 simulator written by Paul Pierce" and does not name SIMH. And the FORTRAN-II-under-IBSYS result reported by McJones (mcjones.org/dustydecks, 2006) is Rich Cornwell's separate I7000 module — which does also ship in this same repository, as `I7000/i7090_cpu.c`. So the repo contains two independent 7090 implementations with different pedigrees, and the widely cited validation belongs to the one that is NOT Supnik's I7094.

I found no tape, script, or published run in the repository that boots anything end to end.

### maintenance

The repository is alive; the 7090/7094 CPU itself is frozen and has been for over a decade.

Repository (via `gh api repos/simh/simh`): `pushed_at=2026-08-31T18:30:26Z`, 1878 stars, not archived, default branch `master`. My build stamped "git commit id is 22b6926ea6f90a07d7182b5b274f8f9bb69c4f2c" / "git commit time is 2026-08-31T11:29:57-0700".

The `I7094` directory, most recent first: 2026-05-13 "I1401, I7094, ID16, ID32, ND100, PDP10, SAGE, VAX780, SCP: Declaration Hygiene" (Mark Pizzolato); 2023-12-04 "ALL simulators with instruction history support: Minor history enhancements"; 2022-09-21, 2022-06-16, 2022-03-17, 2022-03-15, 2022-03-14 (all Coverity and cross-cutting cleanups).

`I7094/i7094_cpu.c` alone: 2023-12-04 (the cross-cutting history change), 2020-10-19 "I7094: Compiler warning cleanup", 2018-03-09 "CONST compatibility", 2017-09-07 "Coverity singleton errors", 2016-05-15 "ALL: Massive 'const' cleanup". Every one is hygiene. The file's own change log names the last functional CPU change as "31-Dec-11 RMS Select traps have priority over protect traps / Added SRI, SPI". So: fourteen years since a semantic change, and roughly five years of janitorial commits since.

Which fork is alive: both. `simh/simh` — pushed 2026-08-31, 1878 stars, not archived. `open-simh/simh` — pushed 2026-07-03, 700 stars, not archived. This is the well-known 2021 governance split; on push recency and stars, `simh/simh` is the more active one, and it is the one that carries this LICENSE.txt. The doc pages I cited are served from opensimh.org, so the fork publishes the documentation.

For contrast, Cornwell's I7000 module in the same repo is warmer: 2024-05-19 "I7000: Updated general card reader, printer and magtape", 2023-12-31 "I7000: Group update for IBM 7000 series simulators."

### license

MIT-style, plus a no-advertising clause, plus one genuinely unusual restriction. GitHub cannot classify it and reports `license=NOASSERTION`. `LICENSE.txt` (75 lines) opens:

"This file summarizes below the general simh license (indented) which is essentially stated at the top of all source code files with the respective authors mentioned there.  Pay particular attention to the paragraphs (beyond the indented section) which add some specific constraints."

The grant:
"   Copyright (c) 1993-2022, Robert M Supnik, Mark Pizzolato and others
   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software."
Plus: "the name of Robert M Supnik, Mark Pizzolato or anyone else shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from all those parties."

`I7094/i7094_cpu.c` carries its own header with the same MIT text under "Copyright (c) 2003-2017, Robert M. Supnik".

So vendoring and FFI-linking are both permitted, with the notice preserved. Now the unusual part:

"Any use of this codebase that changes the code to influence the behavior of the disk access activities provided by sim_disk.c and scp.c is free to do that as long as anyone doing this is explicitly not licensed to any subsequent changes to any part of the codebase in the master branch of the git repository ... made by Mark Pizzolato after the LICENSE.txt was added ... Changes that qualify for this restriction at least include: changing the behavior or default of SET AUTOSIZE/NOAUTOSIZE, or any code in scp.c and sim_disk.c or any simulator components that use the sim_disk routines."

And the clarification: "Group 2: Any person using a simulator that has no devices which use sim_disk and that doesn't modify scp.c is licensed to use all of 'Mark Pizzolato's future changes'."

This lands directly on the design choice. `grep -n "sim_disk" I7094/*.c` returns nothing — the i7094 uses `sim_tape` only, and implements its 7631/1301 disk in `i7094_dsk.c` itself. So you are cleanly Group 2 and fully licensed, PROVIDED you do not modify scp.c. The one edit that would put you outside it is precisely the one an in-process library needs: deleting or renaming `int main` at scp.c:3011. The clause "or any code in scp.c" reads broadly enough to cover that, and I am not confident it does not. Use the subprocess or frontpanel model and the question never arises. Also note: "there exist some binary files in the repository which may not have formal copyright releases ... those are certainly not granted a license" — do not vendor the repo wholesale, take the source files you need.

### buildCost

C99 with a hand-written 143 KB GNU makefile. I built it, so this is measured rather than estimated.

`make i7094` on macOS arm64 (Darwin 25.5.0, Apple clang 21.0.0) produced `BIN/i7094`, 1,036,408 bytes, in about 30 seconds wall from a warm clone. The target is small: `I7094 = i7094_cpu.c i7094_cpu1.c i7094_io.c i7094_cd.c i7094_clk.c i7094_com.c i7094_drm.c i7094_dsk.c i7094_sys.c i7094_lp.c i7094_mt.c i7094_binloader.c` with `I7094_OPT = -DUSE_INT64 -I ${I7094D}`, linked against the SCP framework (scp.c is 740 KB on its own).

The CI trap you must know about: my FIRST `make i7094` built the binary successfully and then exited NON-ZERO. The makefile detects a GNU-make version below its wants, re-invokes itself, and then prints
```
Enter:    $ sudo brew install pcre libedit make zlib
re-enter: $ .../make i7094 BUILD_SEPARATE=1 QUIET=1
makefile:1624: *** .  Stop.
```
which is a bare `$(error )` at makefile:1623. The second, plain invocation exited 0 with the binary present. `make --version` on this machine is GNU Make 3.81 (Apple's), while the successful build reported "built by GNU Make version 4.4.1" — the self-re-invocation is finding homebrew's gmake. A CI job that treats a non-zero make as failure will fail on a cold runner.

What a macOS + Linux CI job would have to add to your currently pure-Dart gate:
- A C toolchain step (clang or gcc). You have none today.
- GNU make 4.x explicitly. macOS runners ship 3.81; `brew install make` and invoke `gmake`.
- The packages the makefile calls "useful" so it does not take the error path: macOS `brew install pcre libedit make zlib`; Debian/Ubuntu `apt-get install build-essential libpcre3-dev libedit-dev`. The makefile itself lists these per platform at lines 391-402.
- A 151 MB `git clone --depth 1` (measured), or a vendored subset, plus a build cache or you pay ~30 s per job.
- You cannot copy SIMH's own CI, because it has none — `.github/` holds only `ISSUE_TEMPLATE.md`.

For an interactive Dart driver you would additionally build `sim_frontpanel.c` + `sim_sock.c` into a dylib/so and link libpthread — the header's steps 2 and 3.

### dartInterop

Yes, but every interactive path needs a native build step. I tested three, and the differences are sharp.

PATH A — batch `.ini` script, PROVEN, no FFI, no native code beyond the prebuilt binary. Dart writes a command file and runs `BIN/i7094 script.ini` with `Process.run`, then reads the output. This is exactly how I got the 7090/7094 result above. It cannot host your runtime handlers, because Dart never computes anything mid-run.

PATH B — subprocess pipe, DOES NOT WORK as-is. I drove the binary with `Process.start`-shaped pipes (stdin and stdout both pipes) and got ZERO bytes back in 180 seconds while the simulator sat happily at its breakpoint. The cause is ordinary C stdio: when stdout is not a tty it is block-buffered, and SIMH's `sim> ` prompt never carries a newline anyway, so a line-oriented reader blocks forever. Dart's `Process.start` gives you pipes, not a pty. This path is a dead end without a pty.

PATH C — pty, PROVEN AND FAST. Over a real pty the same loop works perfectly and the numbers are good:
```
initial: '\r\nIBM 7094 simulator V4.0-0 ...\r\n\r\nBreakpoint, PC: 00101 (TRA 100)\r\nsim> '
200 trap cycles (examine AC + deposit AC + continue) in 0.028s = 138 us/cycle
final:   'examine AC\r\nAC:\t0000000000001\r\nsim> '
```
138 microseconds per full intercept-read-write-resume round trip, about 7,200 traps per second. That is comfortably enough for a payroll program calling SYS) per record. The read must be read-until-`sim> `, not read-line. Dart has no core-library pty, so this needs `forkpty`/`openpty` through `dart:ffi` — a small C shim, but still a C build in CI.

PATH D — `sim_frontpanel` through `dart:ffi`. The intended embedding route: compile `sim_frontpanel.c` + `sim_sock.c` into a dylib, FFI-bind `sim_panel_start_simulator`, `sim_panel_break_set`, `sim_panel_exec_run`, `sim_panel_gen_examine`, `sim_panel_gen_deposit`, `sim_panel_set_register_value`. Structs are opaque (`typedef struct PANEL PANEL;`) so the binding is thin. I did NOT test this.

I also tried speaking the remote-console socket directly from Dart-shaped code, hoping to skip C entirely. It half-works and then stops: `set console telnet=2778` + `set remote telnet=2777` + `set remote master` does start the listener and accept a connection ("Connected to the IBM 7094 simulator REM-CON device"), but my raw client got empty responses to every command. The master remote console is not a plain line protocol — the "^E multiple command mode" handshake and telnet negotiation are why `sim_frontpanel.c` is 105 KB. Reimplementing it in pure Dart is possible and would give you a genuinely native-free path, but it is a real reverse-engineering project, not an afternoon.

Bottom line: no interactive Dart path today that leaves your CI pure Dart.

### runtimeGap

No. Plainly: SIMH supplies nothing that closes the lost SYS)/IOC) runtime gap, and nothing in the project could have.

There is no COMTRAN runtime here, no SYS) or IOC) machine code, no knowledge of the CT Loader, and no reader for the [J 90.03] object-deck format. `i7094_binloader.c` (217 lines) reads a different, unrelated binary card format. The IBSYS connection in the acknowledgements is IBSYS the operating system, which is not your runtime and does not contain it. Your Dart handlers must still be written from J28-6169, exactly as planned, whatever CPU executes the surrounding instructions.

What it does supply, and it is the only thing worth wanting from it, is the PLUMBING for the intercept — not the semantics. Specifically: an execution breakpoint that halts before the instruction at PC (`sim_brk_test (PC, SWMASK ('E'))` at i7094_cpu.c:688), plus host-side examine and deposit of every register and memory word, plus resume. I demonstrated the whole cycle: break at the entry address, read AC, write AC, set PC past the routine, continue. That is the shape of your dispatch layer, already built and debugged by someone else.

But your Dart emulator already has to grow that dispatch layer as M4 stage 4 anyway, and adding it to 889 lines of your own code you fully control is a smaller job than adding a C toolchain to CI, an FFI or pty shim, and a second CPU whose 7090 gate you would then have to audit against the manual yourself. The gap is where all the real work is, and SIMH does not touch it.

### verdict

Test oracle only, and I would not even take it as a dependency — I would use it as a developer-run cross-check that lives outside CI. It cannot replace your CPU core: doing so means adding a C toolchain, GNU make 4.x, four system packages and a 151 MB clone to a gate that today is three Dart commands, and then either an FFI shim or a pty shim to talk to it, and the payoff is a CPU whose 7090 gate you would still have to audit yourself and whose semantics nobody has changed since 2011. Your 889 lines already cover exactly the 43 opcodes your codegen emits and throw a typed exception on everything else, which is a stronger correctness posture for this project than a 2,481-line general 7094 with no test suite. Where it IS genuinely valuable: `SET CPU 7090` is a real, enforced 7090 — three index registers with correct multi-tag OR semantics, 32KW, and a per-opcode model gate that stopped a DFAD for me when I asked it to — which makes it a legitimate differential oracle. Load the same object deck into both, single-step or breakpoint at each runtime entry, and diff AC, MQ, XR, PC and the touched memory words. At 138 microseconds per intercept over a pty that is fast enough to diff a whole payroll run instruction by instruction. Build it as a `tool/` script a developer runs deliberately, keep it out of the CI gate, and let it earn its keep by catching the one carry or overflow bit your handwritten core gets wrong. One caution if you do: run the oracle with `stop_illop` at its default of 1, or a 7094-only opcode is silently skipped instead of trapped, and you lose the only thing the model gate buys you.

### uncertainties

Things I could not confirm, stated plainly.

I verified the 7090 instruction gate with exactly ONE 7094-only opcode — DFAD, 0301. I did not audit the whole 1024-entry `op_flags` table against the IBM 7090 manual, so I cannot tell you the gate is COMPLETE. It is real and it fires; whether it fires on every 7094-only instruction is unverified, and that is precisely the "silent divergence" risk your question names.

I could not confirm that anyone has booted IBSYS or CTSS end to end on `simh/simh`'s I7094 module. The acknowledgement quotes "Dave Pitts gets special thanks for patiently coaching me through IBSYS debug" and names the CTSS veterans who reconstructed the RPQs, and the 67-entry bug history is consistent with heavy real-software debugging — but there is no tape, script, or published run in the repository, and multicians.org credits the running CTSS to Paul Pierce's simulator, not this one. I did not attempt a boot myself; I had no period tape image.

I did not test the `sim_frontpanel` C API. I read its 647-line header and confirmed the remote-console listener starts and accepts a TCP connection, but my raw socket client got empty command responses, so I cannot report the frontpanel's actual behaviour or latency — only the pty number, which is a different channel.

I did not benchmark raw instruction throughput, only the trap round trip.

I did not diff `simh/simh`'s I7094 against `open-simh/simh`'s. I confirmed both forks are alive and unarchived, but if the sources have diverged since 2021 I do not know how.

The LICENSE clause "or any code in scp.c" is ambiguous about whether removing `main()` to build a shared library forfeits Pizzolato's future changes. My read is that it plausibly does, which is why I steered toward the subprocess model — but that is a reading, not legal advice, and the `i7094` simulator using no `sim_disk` devices puts you in Group 2 as long as scp.c stays untouched.

Finally, the two 7090 implementations in this one repository — Supnik's `I7094` and Cornwell's `I7000/i7090_cpu.c`, 4,460 lines — are separate codebases with separate pedigrees. I evaluated Supnik's. Cornwell's is the one carrying the published FORTRAN-II-under-IBSYS result and has warmer commits (2024-05-19), and I did not examine its 7090 model, its embedding surface, or its licence header beyond confirming it is MIT-style under "Copyright (c) 2005-2016, Richard Cornwell". If the oracle idea goes forward, it may be the better of the two and it deserves its own look.


## i7094 module (classic SIMH)

`https://github.com/simh/simh/tree/master/I7094 (docs: https://opensimh.org/simdocs/i7094_doc.html)`

### sevenOhNineZero

Yes — a real, enforced 7090 model, and I proved it rather than inferring it. The doc lists exactly three: "SET CPU 7090   7090 / SET CPU 7094   Standard 7094 / SET CPU CTSS   7094 with CTSS RPQ's." and it names the index-register difference: "XR1..XR7  15  index registers 1 to 7 [7090 uses only XR1, XR2, XR4]". The gate is a per-opcode model flag. i7094_defs.h:197-201 defines `I_4X` (7040/7044), `I_9X` (7090, 7094, CTSS), `I_94` (7094, CTSS), `I_CT` (CTSS), `I_MODEL 0x0F`. i7094_cpu.c:799 reads `if (fl & I_MODEL & ~cpu_model) {  /* invalid for model? */  if (stop_illop)  reason = STOP_ILLEG;  continue; }` and i7094_cpu.c:200 sets the default `uint32 stop_illop = 1;` — so it halts, it does not silently execute. 25 opcodes carry `I_94` (the double-precision floating point block at +300/-300 and others). The 7090 index behaviour is also modelled, not just documented: i7094_cpu.c:631 `if (!(cpu_model & (I_94|I_CT)))  mode_multi = 1;  /* ~7094? MTM always on */`, and get_xri/get_xrx/put_xr (i7094_cpu.c:1997-2060) then OR and store across XR1/XR2/XR4 the way a 7090 tag does. Empirical check I ran on a binary I built: `set cpu 7090 / d 100 DFAD 200 / d 101 HTR 0 / d PC 100 / go` gives "Undefined instruction, PC: 00101 (HTR 0)"; the identical words under `set cpu 7094` execute DFAD and fall through to the halt, "HALT instruction, PC: 00102". A 7094-only opcode on the 7090 model is a hard stop, not a divergence.

### embeddable

There is no in-process C library API, but the trap/inspect/resume loop you need exists and I ran it. In-tree the pieces are: `sim_instr()` (i7094_cpu.c:619) as the run loop; `if (sim_brk_summ && sim_brk_test (PC, SWMASK ('E'))) { reason = STOP_IBKPT; break; }` (i7094_cpu.c:688) which fires BEFORE the instruction at PC is fetched — exactly "intercept before the CPU enters a runtime entry address"; `cpu_ex`/`cpu_dep` (i7094_cpu.c:2259/2273) for memory; and a `cpu_reg` REG table exposing PC, AC, MQ, SI, KEYS, XR1..XR7, SS1..SS6, SL1..4, OVF, MQO, DVC, IOC and the trap-mode flags by name to SCP's EXAMINE/DEPOSIT. The globals themselves (`t_uint64 *M`, `AC`, `MQ`, `PC`, `uint32 XR[8]`, ...) are non-static at i7094_cpu.c:162-201. Console commands proven working: `BREAK <addr>`, `GO`, `CONT`, `E <reg|addr>`, `D <reg|addr> <value>`, `STEP`, plus `SET CPU HISTORY`. My actual transcript: after `break 101 / d PC 100 / go` it printed "Breakpoint, PC: 00101 (ADD 201)" and "AC: 0000000000005"; I then wrote `d AC 100` and `cont`, and the ADD produced "AC: 0000000000107" (0o100 + 0o7). Host read, host write, resume, and the machine used the written value. There is also a documented C client API, sim_frontpanel.h (present in both forks): sim_panel_break_set, sim_panel_exec_run/step/halt, sim_panel_gen_examine/gen_deposit, sim_panel_mem_examine/mem_deposit, sim_panel_set_register_value, sim_panel_get_state, sim_panel_get_history. It is not in-process — sim_panel_start_simulator takes "the path to the simulator binary" and talks to it over SIMH's remote console socket. CMakeLists.txt builds `add_simulator(i7094 ...)`, an executable; there is no library target, and scp.c owns main().

### battleTested

Weaker than the module's reputation suggests, and there is no automated test in the tree. What is real: i7094_defs.h's header credits "Tom Van Vleck, Stan Dunten, Jerry Saltzer, and other CTSS veterans helped to reconstruct the CTSS hardware RPQ's" and says "Dave Pitts gets special thanks for patiently coaching me through IBSYS debug" — the author's own statement that he debugged against IBSYS. i7094_bug_history.txt lists 67 numbered defects found and fixed during that debug, and they are the kind you only find by running real software: "25. CPU: Floating add with unlike signs and equal magnitudes, result sign is sign of SR rather than sign of AC", "63. IO: 7607 channel modeled incorrectly, could stall". The build runs an internal register sanity check ("*** Good Registers in IBM 7094 simulator."), which validates REG table declarations, not semantics. What is missing: the repository tree has test .ini scripts for I650, PDP8, PDP18B, VAX, SEL32, linc and tt2500, and none for I7094 — I listed the full tree to confirm. And I found no independent boot report. Dave Pitts's own page claims IBSYS/FORTRAN II/CTSS for HIS simulator s709, and mentions simh only for utilities. mcjones.org's Dusty Decks (2006-04-03) draws the line explicitly: SIMH would ship two IBM 709x simulators, and Supnik's is "specifically optimized for running CTSS while Rich's is aimed more toward IBSYS and older 704/709 software." So: real period software drove the debugging, especially CTSS, but I could not confirm from any source outside the project that this module boots IBSYS, CTSS or FORTRAN II from a surviving tape today. Note also that the published doc is dated 01-Dec-2008 and is stale — it says "The LOAD command is not implemented", yet i7094_sys.c:132 defines sim_load calling Dave Pitts's binloader.

### maintenance

Both forks are alive; the 7094 emulation logic itself has been frozen for over a decade. simh/simh (Mark Pizzolato, 1878 stars) last pushed 2026-08-31; its most recent I7094 commit is 2026-05-13 "I1401, I7094, ID16, ID32, ND100, PDP10, SAGE, VAX780, SCP: Declaration Hygiene". open-simh/simh (700 stars) last pushed 2026-07-03; its most recent I7094 commits are 2023-05-18 "CMake build infrastructure II (#53)" and 2023-01-31 Bob Supnik "I7094: Changed structures to arrays for display". Everything in both lists since 2020 is hygiene: Coverity fixes, REG macro corrections, compiler-warning cleanup, writelock standardisation. The semantic history is in the file itself — i7094_cpu.c's revision log ends "07-Sep-17 RMS Fixed sim_eval declaration in history routine (COVERITY)" and before that "31-Dec-11 RMS Select traps have priority over protect traps / Added SRI, SPI / Fixed user mode and relocation from CTSS RPQ documentation". So the last change to how the CPU actually computes is 31-Dec-2011. I diffed i7094_cpu.c between the two forks' master branches: byte-identical, zero differing lines. I did not diff the other eleven module files, so "which fork is alive" does not appear to matter for the CPU core, but I cannot say that about the channel and device files.

### license

MIT text with one extra clause, applied both repo-wide and per file. LICENSE.txt verbatim: "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND... Except as contained in this notice, the names of The Authors shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from the Authors." Each source file repeats it naming its own author: i7094_cpu.c is "Copyright (c) 2003-2017, Robert M. Supnik"; i7094_defs.h is "Copyright (c) 2003-2011, Robert M Supnik"; i7094_binloader.c is "Copyright (c) 2008, David G. Pitts" — a second copyright holder to carry if you vendor. Vendoring and FFI-linking are both permitted without restriction. The only obligations are retaining the notice in copies and not using the authors' names to promote your project without written permission. GitHub classifies the repo as NOASSERTION / "Other" because that final advertising clause takes it outside canonical SPDX MIT.

### buildCost

Language is C89-flavoured C. Two build systems: the top-level GNU makefile (`make i7094`, with `I7094_OPT = -DUSE_INT64 -I ${I7094D}`) and CMake (`add_simulator(i7094 ... FEATURE_INT64)`). `USE_INT64` is mandatory; the doc says "To compile the IBM 7094, you must define USE_INT64 as part of the compilation command line." Sources are the twelve I7094 .c files plus the SCP framework: scp.c, sim_console.c, sim_fio.c, sim_timer.c, sim_sock.c, sim_tmxr.c, sim_ether.c, sim_tape.c, sim_disk.c, sim_serial.c, sim_video.c, sim_imd.c, sim_card.c. Measured on this machine (macOS 26.5 arm64, Apple clang 21.0.0, GNU make 4.4.1): `git clone --depth 1 https://github.com/simh/simh.git` is 151 MB, and `make i7094` completed in 7.8 s wall with zero errors and no warnings shown, ending in the register sanity check. So a macOS CI job needs Xcode command line tools and GNU make and nothing else I had to install. Caveat I must state: the makefile auto-detected and linked my Homebrew libpcre, libedit, libpng and zlib, so I did not prove a build on a bare toolchain — the makefile treats those as optional but I have not tested that. I did not test Linux at all; the makefile's package lists suggest gcc plus optionally libpcap-dev/libedit-dev there, and libpcap and SDL are for other simulators, not this one. For your CI the real cost is not the 7.8 s — it is that a pure-Dart pipeline (`dart format`, `dart analyze`, `dart test`) gains a C compile step and either a 151 MB clone or roughly 1.4 MB of vendored C carrying two copyright notices.

### dartInterop

Subprocess, not FFI — and the buffering detail decides which subprocess mode works. Three mechanisms, in the order I would try them. (1) Batch: Dart writes a SIMH .ini script, runs `i7094 script.ini` via Process.run, parses stdout. Fully proven — this is how I ran every test above. Its limit is that the whole interaction must be known in advance, so it cannot serve a Dart handler that computes a result from machine state. (2) Interactive over a pseudo-terminal: proven working, but needs a pty. I measured that SIMH's stdout is block-buffered when stdout is a pipe — piping `e AC`, sleeping 2 s, then `quit` produced all four output lines stamped with the same second, i.e. nothing emerged until exit, which would stall a naive Dart request/response loop. Under `script -q /dev/null` the same sequence returned "AC: 0000000000000" at t and "Goodbye" at t+3, and SIMH emits a `sim> ` prompt as a clean synchronisation token. Dart core has no pty, so this needs a native pty package — which reintroduces the native dependency FFI would have. (3) Remote console over TCP, driven from dart:io Socket: this is what sim_frontpanel does internally, and scp.c:1408 documents "SET REMOTE TELNET=port      specify remote console telnet port". I got partway: the listener started ("%SIM-INFO: Listening on port 17094"), my socket connected, and SIMH sent telnet negotiation plus "Connected to the IBM 7094 simulator REM-CON device". Master mode additionally requires the primary console to be redirected ("Console port must be Telnet or Serial with Master Remote Console"), fixed by `SET CONSOLE TELNET=<other port>`. I did not get a command/response round trip over the socket within my time budget, so I am calling this path real but unverified by me. dart:ffi to a .dylib is the fourth option and the worst: `add_simulator` produces an executable and scp.c owns main(), so you would hand-write a C shim and a build for it, entirely unsupported upstream.

### runtimeGap

No. It supplies nothing that closes the lost SYS)/IOC) runtime gap, and there is no reason it would — SIMH models hardware, and the runtime library sat above the hardware. What it supplies instead is the layer below: a 7607 data channel model, 729 magnetic tape controllers on channels A through H, a 711 card reader, a 721 card punch, a 716 line printer, a 7631 file control, a 7289 drum and a 7750 communications controller, plus channel command decoding (IOCP/IOCT/IOSP/IOST) and channel traps. The sharp point is that decision D0.7 is precisely the decision not to emulate that layer: I/O is intercepted at the IOCS level and no RDS/WRS or channel opcode ever appears in generated code. So the module's largest asset — years of channel and device debugging, and most of the 67 entries in its bug history — is the part of it your design has already ruled out. The Dart handlers at the documented runtime entry points must be written either way; SIMH shortens none of that work. All it could contribute is the thing you already have, a word-exact CPU that stops at an address and lets a host read and write state.

### verdict

Not a core replacement; a credible test oracle for the CPU core, cheap enough to consider even in CI, but it buys you nothing on the milestone you are actually blocked on. Replacing lib/src/emulator is a bad trade: D0.3 is locked, the repository is pure Dart with a three-command CI gate, and you would be retiring 889 lines whose 43-opcode subset is exactly what the compiler emits and which are already green under about 1600 lines of test, in exchange for a C toolchain step, a second copyright notice to carry, and a subprocess protocol whose interactive mode needs either a pty or an unverified telnet path. The oracle case is genuinely good and I would not dismiss it: SIMH implements the full instruction set where you implement a subset, `SET CPU 7090` really rejects 7094-only opcodes rather than silently executing them, and I demonstrated the exact loop an oracle harness needs — break before an address, read AC, write AC, continue, correct arithmetic — from a plain script in one command. Deposit the same words in both machines, single-step, compare AC/MQ/XR/memory, and any divergence in your core surfaces immediately. Build cost is 7.8 s on macOS, so this can live in CI rather than only on a laptop. But be clear about what it does not touch: M4 stage 4 is the dispatch layer, the Dart compute handlers at the runtime entry points, and end-to-end execution tests, and SIMH supplies no part of any of those. Use it, if you use it, as a differential check on instruction semantics you already implement — not as a step toward the machine assembly.

### uncertainties

Six things I could not confirm. First, no independent report that this module boots IBSYS, CTSS or FORTRAN II from a surviving tape — the evidence is the author's own acknowledgment lines in i7094_defs.h, the 67-item bug history, and the doc's CTSS configuration section; Dave Pitts's page credits his own s709, not this. Second, there is no test .ini for I7094 in the tree (I checked the full recursive listing; I650, PDP8, PDP18B, VAX, SEL32, linc and tt2500 have one), so there is no in-repo regression suite to point at. Third, I did not verify the remote-console round trip — the listener starts, the socket connects, SIMH negotiates telnet, but I never got a command answered over it, and I cannot say whether that was my telnet client or a configuration I got wrong. Fourth, my macOS build linked Homebrew libpcre, libedit, libpng and zlib that the makefile found on its own, so a truly bare-toolchain build is unproven, and I did not test Linux at all. Fifth, I diffed only i7094_cpu.c between simh/simh and open-simh/simh (byte-identical); the other eleven module files may have diverged, so my "either fork" claim is safe for the CPU and unverified for channels and devices. Sixth, I verified the 7090 model gate on one instruction, DFAD — I read the flag table and counted 25 I_94-marked opcodes but did not test each, and I did not check whether any 7090/7094 difference exists that the flag table does not encode.


## i7090 / I7000 module (Richard Cornwell)

`https://github.com/rcornwell/sims (I7000/); docs https://opensimh.org/simdocs/i7090_doc.html`

### sevenOhNineZero

Yes — a genuine, separately-coded 7090, not a 7094 wearing a label. `I7000/i7090_cpu.c:176-179` defines four models: `#define CPU_704 0`, `#define CPU_709 1`, `#define CPU_7090 2`, `#define CPU_7094 3`, selected by `SET CPU 704|709|7090|7094` and read back as `#define CPU_MODEL ((cpu_unit.flags >> UNIT_V_CPUMODEL) & 0x3)` (line 169). The decoder actively withholds 7094 instructions from every lower model: `i7090_cpu.c:1102` reads `if (opinfo & I_94 && CPU_MODEL != CPU_7094) break;` where `#define I_94 0x0400 /* 7094 only */` (line 409) tags seven rows of the opcode-flag tables. Indexing is model-correct: the effective-address macro at line 661 is `(((t)) ? ((MTM) ? (XR[(t)&04] | XR[(t)&02] | XR[(t)&01]) : XR[(t)]) : 0)` — with multi-tag mode on, the three tag bits OR three index registers together, which is 7090 behaviour, and `cpu_reset` sets `MTM = 1` (line 4192), so multi-tag is the power-on default. Three further branches are 7090-specific: `CPU_MODEL < CPU_7090` (divide-check MQ sign, line 1969), `CPU_MODEL == CPU_7090` (zero-MQ multiply shortcut, line 2185), `CPU_MODEL >= CPU_7090` (ENB interrupt hold, line 3353). I ran the CPU diagnostic decks under `set cpu 7090` and the halt program-counters matched the project's own 709 golden exactly, including 9M03A, the indexing test (halt at IC 00001, `AXT 00300,1`). One honest wart: LMTM and EMTM (lines 1344, 1420) are gated only on `CPU_MODEL != CPU_704`, so a 7090 model would still honour them rather than treating them as absent — harmless here, since COMTRAN-generated code never emits them.

### embeddable

There is no C library API, but the console command language is a complete trap-inspect-resume interface, and I drove it. On the binary I built: `set cpu 7090`; `d 100 050000000200` deposits a word; `e 100-102` examines memory; `break 102` arms an execution breakpoint; `go 100` runs; `e ic` / `e ac` / `e mq` read registers; `d ac 000000000077` writes one; `nobreak 102` then `cont` resumes. The breakpoint fires BEFORE the instruction at the address executes — `i7090_cpu.c` tests `sim_brk_test(((bcore & 2)? CORE_B:0)|IC, SWMASK('E'))` at the top of the fetch loop and sets `reason = STOP_IBKPT` — which is exactly the "intercept control before the CPU enters a runtime entry address" semantic the plan needs. My run printed `Breakpoint, IC: 00102` with AC holding 0000000000010, the correct 5+3. The C-level entry points exist too: `t_stat sim_instr(void)`, `t_stat cpu_ex(t_value *vptr, t_addr addr, UNIT *uptr, int32 sw)`, `t_stat cpu_dep(t_value val, t_addr addr, UNIT *uptr, int32 sw)`, and a `REG cpu_reg[]` table exposing IC, AC, MQ, XR[8], ID, MA, SL, SW, KEYS, MTM, TM, STM, CTM, FTM; `M[]`, `AC`, `MQ`, `XR[]`, `IC` are non-static globals. A typed out-of-process API also ships: `sim_frontpanel.h` declares `sim_panel_start_simulator`, `sim_panel_break_set`, `sim_panel_break_clear`, `sim_panel_mem_examine`, `sim_panel_mem_deposit`, `sim_panel_set_register_value`, `sim_panel_get_registers`, `sim_panel_exec_run`, `sim_panel_exec_step`, `sim_panel_exec_halt`, `sim_panel_get_history`. One extra: `set cpu history=N` plus `show cpu history=n` prints a per-instruction trace of IC, AC, MQ, EA, SR, XR1, XR2, XR4 with the word and its disassembly.

### battleTested

Real IBM customer-engineering diagnostic decks, run as part of the build, and I reproduced the pass. `I7000/tests/i7090/` holds about fifty period decks: 9M01B, 9M03A (indexing), 9C01A/9C02A (card reader), 9D01A, 9IOTA, 9T01A–9T11A (tape), 9P01C/9P02A (printer), 9B01A, 9EFPA, 9ESLA, 9SY1A, XCOMC, 9S01–9S05 (stress), 9DAP, 9DRSA, 9MLTA. `make i7090` builds the simulator and then runs `I7000/tests/i7090_test.ini`, which boots each deck and compares the captured console log against a checked-in golden, `good.test.bin`. On my machine (macOS 15.5, arm64, Apple clang 21) it matched byte for byte and exited 0. Two honest qualifications. First, that golden log CONTAINS known ERROR lines — the 9IOT channel-trap sequencing failures print into it — so "passes" means "reproduces the recorded reference output", not "every diagnostic is clean". Second, the shipped script runs `set cpu 709`, not 7090; I re-ran the CPU and card-reader block under `set cpu 7090` myself and got zero error lines and halt points identical to the golden. The full script under `set cpu 7090` looped indefinitely in the 9P01C printer section (a 9.4 MB log of repeated "OPN SPACE" errors), but that script's halt-point sequencing is written for the 709, so I cannot attribute the loop to a CPU-model bug. The README additionally claims CTSS works, IBSYS works, the stand-alone assembler works, and Lisp 1.5 works; I did not verify any of those, as none of the tapes ship with the repository. The README also lists known bugs: DFDP/DFMP off by 1–2 in the least significant part, EAD sign of -0, 9P01C channel skips, HTx, DKx.

### maintenance

The repository is alive; the 7090 sources are quiet but not abandoned. In `rcornwell/sims`, `git log` on `I7000/i7090_cpu.c i7090_sys.c i7090_chan.c i7090_defs.h` gives 2024-03-19 `b83faa7 "I7000: Clean up compiler warning from CMake"` as the last touch and 2023-11-27 `127e615 "I7000: Fixed channel issues to allow I7090 to run Stress"` as the last functional change. The whole `I7000/` directory last changed 2024-05-10. Repository HEAD is 2026-03-08 `9510a91 "KA10: Fixed DP seek done to not move uptr"` — Cornwell is actively committing, just to his PDP-10 simulators. Three copies exist and all three are current: `rcornwell/sims` is the author's own and the one I built; `open-simh/simh` last changed `I7000/` on 2024-05-21; `simh/simh` last changed `I7000/i7090_cpu.c` on 2023-12-31. The documentation lives on opensimh.org and the binary I built reports "Open SIMH V4.1-0", so Open SIMH is the mainline downstream. The quiet period reads as maturity, not rot: a machine whose diagnostics pass and whose golden log is checked in does not need weekly commits.

### license

MIT, asserted per file — there is no LICENSE file anywhere in the repository (`find . -maxdepth 2 -iname "*license*"` returns nothing). `I7000/i7090_cpu.c` lines 1-20 read: "Copyright (c) 2005-2016, Richard Cornwell / Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL RICHARD CORNWELL BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE." No advertising clause on the Cornwell files. Building the simulator also pulls in the SimH core; `scp.c` lines 1-24 carry "Copyright (c) 1993-2022, Robert M Supnik" with the same MIT text plus one extra sentence: "Except as contained in this notice, the name of Robert M Supnik shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from Robert M Supnik." `sim_frontpanel.h` carries the identical clause naming Mark Pizzolato (2015). Vendoring and FFI-linking are both permitted; the only obligation is carrying the notices, and the name clauses restrict advertising, not use.

### buildCost

Cheap on macOS, measured; plausible on Linux, untested. `make TESTS=0 i7090` from a clean tree took 6 seconds on macOS 15.5 arm64 with Apple clang 21 and produced a 928 KB `BIN/i7090`, with no Homebrew package, no SDL, no X11, no libpcap. The flags are `-I I7000 -DUSE_INT64 -DI7090 -DUSE_SIM_CARD`; the sources are ten `I7000/` files plus the SimH core (`scp.c` and about fifteen `sim_*.c`). Without `TESTS=0`, `make i7090` also runs the roughly 30-second diagnostic suite — the switch is `makefile:240`, `ifneq (0,$(TESTS))`. The repository's own `dependencies.sh` installs SDL2 and X11 only for display-capable simulators, and its `install_osx()` body is literally `true`. So a CI job would add: a C toolchain (already present on both GitHub-hosted runners), a checkout or submodule of the simulator tree, and one `make TESTS=0 i7090` step — but that is exactly the C toolchain step the project currently does not have. I did not build on Linux; the `.travis.yml` and CMake infrastructure suggest it works, and nothing in the i7090 target looks platform-specific, but that is inference, not evidence.

### dartInterop

Subprocess, but it needs a pseudo-terminal, not a plain pipe — I proved both halves. Driving the binary through ordinary `Process.start`-style pipes FAILS turn-by-turn: SimH block-buffers stdout when it is not a terminal, so nothing came back within a 5-second wait at any step, and the whole session's output only arrived at process exit. Under a pty the same script works perfectly and every round trip is under a millisecond: I trapped at address 102, read AC, deposited `d ac 000000000123`, read back the literal `AC:\t0000000000123`, cleared the breakpoint, and resumed to HALT. `dart:io` has no pty, so Dart would need `dart:ffi` to `forkpty`/`openpty` (libSystem on macOS, libutil on Linux) or a pty package — a small, contained piece of glue. Two alternatives. The typed route is `dart:ffi` against `sim_frontpanel.c` and `sim_sock.c` compiled as a shared library, giving `sim_panel_break_set`, `sim_panel_mem_examine`, `sim_panel_mem_deposit`, `sim_panel_set_register_value` and `sim_panel_exec_run` as real function calls; that module exists precisely because the raw text channel lacks framing. The route that does NOT work as-is is speaking the remote console straight from a Dart socket: I got `set remote master` to accept commands over TCP, but every response came back empty, and I did not resolve why. Linking the simulator itself into the Dart process via FFI is not realistic — it is a program with `main()` in `scp.c`, a console, and process-global machine state.

### runtimeGap

No. It supplies nothing that closes the lost SYS)/IOC) runtime gap, and it never could — the COMTRAN runtime library was IBM compiler-vendor code that does not survive anywhere, so no simulator can contain it. What i7090 supplies instead is the layer below: a 36-bit 7090 CPU, the data channels, and device models for card reader, card punch, printer, tape, drum and disk. Its strongest asset — that it boots real operating systems from real tapes — is orthogonal to the plan by construction, because decision D0.7 emulates I/O at the IOCS level and generated code contains no RDS, WRS, or channel opcode at all. The claim "IBSYS works" means a user-supplied IBSYS tape boots on it, not that any runtime is shipped. The Dart handlers at the documented runtime entry points remain entirely the project's own work either way; i7090 changes only what executes the machine instructions between those entry points.

### verdict

Test oracle, not a replacement — and a very good one. As a replacement it fails on cost rather than quality: the existing Dart core is 889 lines, word-exact on the 43 opcodes the compiler actually generates, backed by 1600 lines of green tests and a design record citing A22-6528-4 page by page, and it throws a typed exception on anything outside that subset. Swapping it for i7090 would add a C toolchain step to a pure-Dart CI, put a pty and a text protocol on the production trap path that today is a Dart function call, and buy no correctness the harvested subset lacks. As an oracle it is close to ideal. `set cpu history=N` emits a per-instruction trace of IC, AC, MQ, EA, SR, XR1, XR2, XR4 with the disassembled word — a ready-made differential-comparison format. Load the same object program into both, step both, and diff the traces; any divergence in a 7090 opcode is a bug in one of them, and the one with fifty period CE diagnostic decks behind it is probably right. The genuine `SET CPU 7090` is what makes this worth doing: a 7094-only simulator would silently accept 7094 index behaviour and quietly bless wrong answers. Run it out of CI, or as an optional non-gating job, so the pure-Dart gate stays pure.

### uncertainties

Five things I could not confirm. (1) The CTSS, IBSYS, stand-alone assembler and Lisp 1.5 claims are README text only — no tapes ship with the repository and I did not source any, so I have no first-hand evidence for the strongest validation claim. (2) Running the full shipped diagnostic script under `set cpu 7090` instead of `set cpu 709` loops forever in the 9P01C printer section; I cannot say whether that is a 7090-model defect or simply that the script's halt-point sequencing is written for the 709, because the script drives the diagnostics by expected halt addresses. (3) Driving the remote console directly from a socket in master mode accepted every command but returned no output, and I did not find the cause within the time I spent — sim_frontpanel's ^E multi-command handshake is the likely missing piece, but that is a guess. (4) I built and ran only on macOS 15.5 arm64; the Linux build is inference from the CMake and Travis configuration, not a measurement. (5) I did not benchmark instruction throughput, so I cannot say what a trap-heavy COMTRAN program would cost per runtime entry beyond the sub-millisecond pty round trip I measured for a single command. Separately, the README's known DFDP/DFMP and EAD sign bugs are stated by the author and unverified by me; both are floating-point and so irrelevant to COMTRAN's fixed-point and character work, but I note them rather than dismiss them.


## Open SIMH (open-simh/simh)

`https://github.com/open-simh/simh`

### sevenOhNineZero

Yes — and unusually, the repository ships two independent 7090 implementations, both with a real 7090 model, not a 7094 wearing a label.

(A) `I7094/` — Robert M. Supnik, "Copyright (c) 2003-2017". `I7094/i7094_cpu.c` `MTAB cpu_mod[]`, quoted exactly:

    { MTAB_XTD | MTAB_VDV, I_9X|I_94|I_CT, "MODEL", "CTSS",
      &cpu_set_model, &cpu_show_model, NULL },
    { MTAB_XTD | MTAB_VDV, I_9X|I_94, NULL, "7094",
      &cpu_set_model, NULL, NULL },
    { MTAB_XTD | MTAB_VDV, I_9X, NULL, "7090",
      &cpu_set_model, NULL, NULL },

`I7094/i7094_defs.h:199-202` defines the gate bits: `#define I_9X 0x02 /* 7090, 7094, CTSS */`, `#define I_94 0x04 /* 7094, CTSS */`, `#define I_MODEL 0x0F /* option mask */`. Every opcode carries these flags, and the decode loop enforces them at `i7094_cpu.c:799-802`:

    if (fl & I_MODEL & ~cpu_model) {                /* invalid for model? */
        if (stop_illop)                             /* possible stop */
            reason = STOP_ILLEG;
        continue;
        }

The 7094-only behaviour you were worried about is handled explicitly. `i7094_cpu.c:631`: `if (!(cpu_model & (I_94|I_CT))) /* ~7094? MTM always on */ mode_multi = 1;` — selecting 7090 forces multi-tag mode on, which is exactly the 7090's index-register semantics (tag 3 = XR1|XR2, and no LMTM/EMTM escape). Reset repeats it at line 2232 and `cpu_set_model` at line 2301.

Two cautions on this one. Its default at startup is 7094 — `uint32 cpu_model = I_9X|I_94;` (line 187) — so you must issue `SET CPU 7090` explicitly. And `stop_illop` defaults to 1 (line 200) but is an exposed register `{ FLDATA (STOP_ILL, stop_illop, 0) }` (line 330); if it is cleared, a 7094-only instruction becomes a silent no-op via that `continue`. Leave it at 1.

(B) `I7000/` — Richard Cornwell, "Copyright (c) 2005-2016". `I7000/i7090_cpu.c:179-182`:

    #define CPU_704         0
    #define CPU_709         1
    #define CPU_7090        2
    #define CPU_7094        3

with `MTAB cpu_mod[]` rows `"704"`, `"709"`, `"7090"`, `"7094"` (lines 358-362), and roughly 30 `CPU_MODEL` tests scattered through the decode. This one is the finer-grained of the two. Line 1090: `if (opinfo & I_94 && CPU_MODEL != CPU_7094)`. Line 1951: `if (CPU_MODEL < CPU_7090)`. It even carries a 7090-only floating-point quirk at line 2167: `if (CPU_MODEL == CPU_7090 && (MQ & PMASK) == 0)`. Double-precision FP, significance mode, and CTSS dual core are separate switches (`OPTION_EFP`, `OPTION_FPSM`, `UNIT_DUALCORE`), so a bare `SET CPU 7090` does not quietly hand you 7094 hardware.

This matters directly for our 43-opcode subset. Ten of the opcodes in `lib/src/emulator/decode.dart` are index instructions — TXI, TIX, TNX, TXH, TXL, TSX, LXA, SXA, PXA, PDX — and those are precisely where 7090 and 7094 diverge, through multi-tag mode and the 3-vs-7 index register count. Running our generated code on a 7094 model is the silent-divergence scenario, and both simulators give you a real switch to avoid it.

### embeddable

There is no linkable library, but there is a documented out-of-process control API that does everything on our list except the per-instruction hook.

SIMH is a program, not a library: `scp.c:2745` is `int main (int argc, char *argv[])`, and each simulator (`i7090`, `i7094`) is a separate executable with an SCP command REPL. There is no `libsimh`, no CMake library target, and no reentrant instance handle.

The embedding path is `sim_frontpanel.h` (22.5 KB, repository root). Its actual functions:

- `PANEL *sim_panel_start_simulator (const char *sim_path, const char *sim_config, size_t device_panel_count)` — spawns the simulator binary and attaches to it.
- `int sim_panel_break_set (PANEL *panel, const char *condition)` / `sim_panel_break_clear` — set and clear breakpoints. The condition string is SCP `BREAK` syntax, so an address is a valid condition.
- `sim_panel_exec_run`, `sim_panel_exec_start`, `sim_panel_exec_step`, `sim_panel_exec_halt`, `sim_panel_exec_boot` — run, single-step, stop, resume.
- `sim_panel_gen_examine` / `sim_panel_gen_deposit` — read and write a register or a memory location by name.
- `sim_panel_mem_examine` / `sim_panel_mem_deposit` / `sim_panel_mem_deposit_instruction`.
- `sim_panel_add_register`, `sim_panel_get_registers`, `sim_panel_set_register_value`.
- `sim_panel_halt_text (PANEL *panel)` — "Returns the simulator output immediately prior to the most recent transition to the Halt state", i.e. why it stopped.
- `sim_panel_get_history`, `sim_panel_set_display_callback_interval`.

The header states a hard constraint: "The simulator binary must be built from the same version simh source code that the frontpanel API was acquired from (the API and the simh framework must speak the same language)." The transport is the SCP remote console over a socket — `SET REMOTE TELNET=port` (`scp.c:1355`), `sim_frontpanel.c` plus `sim_sock.c`. It is not built as a library by the makefile; the only target that compiles it is `frontpaneltest` (`makefile:3058-3063`).

The critical property for our design holds: SIMH execution breakpoints fire *before* the instruction executes. `I7094/i7094_cpu.c:688`, inside the fetch loop and before decode:

    if (sim_brk_summ && sim_brk_test (PC, SWMASK ('E'))) {  /* breakpoint? */

and `I7000/i7090_cpu.c:803-807`:

    if (iowait == 0 && sim_brk_summ &&
             sim_brk_test(((bcore & 2)? CORE_B:0)|IC, SWMASK('E'))) {
        reason = STOP_IBKPT;
        break;
    }

Both set `sim_brk_types = sim_brk_dflt = SWMASK('E')`. So "trap before the CPU enters a runtime entry address" is directly supported. SCP `BREAK` also takes inline actions — the help text example is `BREAK 100;EX AC;D MQ 0` — which lets a breakpoint dump machine state without a host round-trip.

What does *not* exist: a per-instruction callback into host code. Nothing in `sim_instr()` invites a hook. The nearest facilities are `SET CPU HISTORY=n` (a ring buffer of executed instructions, readable via `sim_panel_get_history`) and single-stepping, which costs a socket round-trip per instruction.

The lower-level C entry points, if you linked rather than spawned: `extern t_stat sim_instr (void);` (`scp.h:351`), `t_stat sim_brk_set (t_addr loc, int32 sw, int32 ncnt, CONST char *act)` (`scp.h:518`), `uint32 sim_brk_test (t_addr bloc, uint32 btyp)` (`scp.h:222`).

### battleTested

Real period software has been run on it, but the evidence is a maintainer's README claim, not a runnable artifact in the repository, and there is no automated instruction-level test for either 7090 target.

`I7000/README.md`, the i7090 section, verbatim and complete:

    ## i7090
       * Working with exceptions.
       * Known bugs:
          * DFDP/DFMP     Sometimes off by +/-1 or 2 in least signifigant part of result.
          * EAD           +n + -n should be -0 is +0
          * Not all channel skips working for 9P01C.
          * HTx	Not sure what problems are, does not quite work.
          * DKx	Sometimes fails diagnostics with missing inhibit of interrupt.
       * CTSS    works.
       * IBSYS   works.
       * Stand alone assembler works.
       * Lisp 1.5 works.
       * Signifigence mode Not tested, Test Code Needed.

That is the strongest single line of evidence — CTSS and IBSYS both booting is exactly the bar you named — but nothing in the repository lets you re-run it. There is no tape image, no boot script, no CI job. The reference to "9P01C" and "diagnostics" indicates period IBM diagnostic decks were used during development, off-repository.

Independent corroboration for the other simulator: `I7094/i7094_bug_history.txt` is a numbered list of 67 fixed defects, each specific enough to have come from running real software rather than reading a manual — for example "63. IO: 7607 channel modeled incorrectly, could stall", "64. IO: All 7607 'effective NOP' conditions must be tested when a new command is decoded (wc == 0 for IOCx and IOSx, EOR set for IOSx and IORx)", and "67. CPU: Storage nullification mask not recalculated at all points needed; replaced with macro." Separately, `I7094/i7094_binloader.c` is "Copyright (c) 2008, David G. Pitts" — Pitts maintains the IBM 7094 IBSYS/CTSS restoration distribution, and his loader being upstreamed into the simulator is real evidence that the 7094 target ran his period software.

The negative finding is firm. I checked for the CTest scripts by URL:

    404  I7000/tests/i7090_test.ini
    404  I7094/tests/i7094_test.ini
    200  I650/tests/i650_test.ini

`cmake/add_simulator.cmake:286-296` shows why that matters:

    list(APPEND test_cmd "${_targ}" "RegisterSanityCheck")
    ...
    if (DEFINED SIMH_TEST)
        string(APPEND test_fname ${CMAKE_CURRENT_SOURCE_DIR} "/tests/${SIMH_TEST}_test.ini")
        IF (EXISTS "${test_fname}")
            list(APPEND test_cmd "${test_fname}" "-v")
        ENDIF ()
    endif ()

Both `I7000/CMakeLists.txt` and the 7094 equivalent declare `TEST i7090` / `TEST i7094`, but since the `.ini` files do not exist, `ctest` for these two simulators runs only `RegisterSanityCheck` — a generic SCP check that the register declarations match their backing variables. Nothing verifies an instruction result. The i650 target proves the mechanism exists and that 7090/7094 simply do not use it.

One point in our favour that I confirmed locally: the 43 opcodes in `lib/src/emulator/decode.dart` are fixed-point, word-transmission, logical, shift, control-transfer and index instructions — ACL, ADD, ALS, ANA, ARS, CAL, CAS, CLA, COM, DVP, LAS, LDQ, LGL, LGR, LRS, LXA, MPY, NOP, ORS, PDX, PXA, RQL, SLW, STO, STQ, SUB, SXA, TIX, TNX, TPL, TRA, TSX, TXH, TXI, TXL and the rest. No floating point. Every known bug Cornwell lists is in double-precision FP (DFDP/DFMP), floating add (EAD), channel skips, hypertape or disk — none of them touches our subset.

### maintenance

The project is alive; the 7090 and 7094 CPU sources are effectively frozen and have been for about two years.

Open SIMH repository metadata (GitHub API): 700 stars, 150 forks, default branch `master`, `pushed_at` 2026-07-03, `updated_at` 2026-09-01.

Commits touching `I7000/i7090_cpu.c` specifically, newest first:

    2023-12-31  1a1396d0  I7000: Group update for IBM 7000 series simulators.
    2020-10-31  a9500f56  I7000: Remove redundant include of time.h.
    2020-10-14  4057374c  I7000: Removed compiler warnings.
    2020-06-24  1035aa3e  I7000: B5500: Set output only devices to default to append mode.
    2018-08-06  124ca0ea  I7000: Second release of IBM 7000 simulators.
    2017-12-29  8aa6c9fd  I7000: Fixed coverity warnings.
    2017-12-28  b5ea9ec3  I7000: Initial release of a set of simulators for IBM 7000 series mainframes.

Seven commits in eight years, the last two of them mechanical. The wider `I7000/` directory is slightly warmer — last touched 2024-05-19, `95152012` "I7000: Updated general card reader, printer and magtape".

`I7094/` is colder still. Its last commit is 2023-05-18, `8b14bb69` "CMake build infrastructure II (#53)", which is build plumbing. The last actual code change is 2022-09-29, `8bc5b0b1` "I7094: Changed structures to arrays for display". Before that, a run of Coverity-driven fixes in March 2022.

On which fork is alive: both are. The classic `simh/simh` tree (Mark Pizzolato) is not archived, has 1878 stars, and `pushed_at` 2026-08-31 — more recent overall activity than Open SIMH's 2026-07-03. But for the sources we care about the two are the same code: `simh/simh`'s `I7000/i7090_cpu.c` was last changed on the same day, 2023-12-31, commit `e8cf41bd`, with the same message "I7000: Group update for IBM 7000 series simulators." Its only extra touch is 2023-12-04 `6d376b2f`, a cross-simulator instruction-history enhancement.

So the fork question does not actually discriminate here. Open SIMH is the community-governed one — its README says the code "was taken from a code base maintained by Mark Pizzolato as of 12 May 2022. From that point onward there is no connection between that source and the Open SIMH code base", and it explicitly asks contributors not to port material from `github.com/simh/simh`. That governance split is a reason to prefer Open SIMH for provenance hygiene, not a difference in 7090 code quality.

Interpretation: frozen is not the same as abandoned. A 1962 machine does not acquire new instructions. Two years of quiet on a CPU decoder that has booted CTSS is closer to "settled" than to "rotting". But it does mean nobody is standing by to fix a divergence you report.

### license

MIT, plus a names clause. `LICENSE.txt` in full, quoted exactly:

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
    THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Except as contained in this notice, the names of The Authors shall not be
    used in advertising or otherwise to promote the sale, use or other dealings
    in this Software without prior written authorization from the Authors.

Every source file we care about repeats the same terms with an individual author substituted for "The Authors": `I7000/i7090_cpu.c` — "Copyright (c) 2005-2016, Richard Cornwell"; `I7094/i7094_cpu.c` — "Copyright (c) 2003-2017, Robert M. Supnik"; `I7094/i7094_binloader.c` — "Copyright (c) 2008, David G. Pitts". Their clauses name the individual: "the name of Robert M Supnik shall not be used in advertising".

Both vendoring and FFI-linking are permitted without restriction. The only obligations are (1) reproduce the copyright and permission notice in copies or substantial portions, and (2) do not use the authors' names to promote the project without their written authorization. There is no copyleft, no source-disclosure trigger, no linking exception needed.

One filing note: GitHub's API reports the license as `key: "other"`, `spdx_id: "NOASSERTION"` rather than MIT, because of the trailing names clause. That is a classification artefact, not a restriction. Practically it means a licence-scanning CI step would flag it as unrecognised and need an explicit allowance.

Vendoring a subset also carries a courtesy obligation Open SIMH states in its README: "**Do not** contribute material taken from `github.com/simh/simh` unless you are the author of the material in question." That governs contributions back, not our use, but it signals the project cares about provenance — so a vendored copy should record which fork and which commit it came from.

### buildCost

C99, two parallel build systems, and both 7090 targets are already proven green on exactly our two CI platforms — but adding any of it to a pure-Dart repository is a permanent new axis of CI.

Language and build systems. Portable C. The repository root carries both a GNU `makefile` and a CMake tree (`CMakeLists.txt` plus `cmake/`, with `README-CMake.md`). Per-simulator CMake files are generated: `I7000/CMakeLists.txt` opens "This is an automagically generated file. Do NOT EDIT."

The i7090 target needs 14 translation units plus the SCP core. From `I7000/CMakeLists.txt`:

    add_simulator(i7090
        SOURCES
            i7090_cpu.c i7090_sys.c i7090_chan.c i7090_cdr.c i7090_cdp.c
            i7090_lpr.c i7000_chan.c i7000_mt.c i7090_drum.c i7090_hdrum.c
            i7000_chron.c i7000_dsk.c i7000_com.c i7000_ht.c
        INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}
        DEFINES I7090
        FEATURE_INT64
        LABEL I7000
        PKG_FAMILY ibm_family
        TEST i7090)

`FEATURE_INT64` is required — the 7090 is a 36-bit machine held in 64-bit words. `i7090_cpu.c` alone is 167 KB.

What upstream CI already proves. `.github/workflows/build.yml` has a `makefile` job with `matrix: os: [macos-latest, ubuntu-latest]`, and its simulator list includes both `i7094` (line 3 of the list) and `i7090` (last line), built with `make LTO=1 OPTIMIZE=-O3 $SIM`. So the exact two platforms our CI runs on are already green for the exact two targets we would want. That is a genuinely strong data point — it removes most of the "will it even compile on macOS" risk.

Dependencies. `.travis/deps.sh` installs, for macOS via Homebrew: `pkg-config pcre libpng libedit sdl2 freetype2 sdl2_ttf vde cmake gnu-getopt coreutils zlib`. For Linux via apt: `pkg-config libpcre3-dev libpng-dev libedit-dev libegl1-mesa-dev libgles2-mesa-dev libsdl2-dev libfreetype6-dev libsdl2-ttf-dev libpcap-dev libvdeplug-dev libpcre2-dev cmake ninja-build`.

Almost none of that is needed for i7090. The makefile header states it auto-detects features and honours `NOVIDEO=1` (skip SDL2) and `NONETWORK=1` (skip libpcap). A minimal i7090 build wants a C compiler, GNU make, and libc. Realistically: `make NOVIDEO=1 NONETWORK=1 i7090`.

What our CI would actually have to add:
1. A C toolchain step. On `ubuntu-latest` and `macos-latest` the compiler is preinstalled, so this is a `make` invocation, not a package install — but it is a new job stage where today there is none.
2. Vendoring or checkout of ~500 KB of C for the i7090 target plus the SCP core (`scp.c` alone is 674 KB), or a git submodule, or a cached prebuilt binary per platform.
3. A build-artifact story. Dart tests that shell out to `i7090` need the binary present. Either build it in CI every run (tens of seconds with `-O3`, more with `LTO=1`), or cache it, or check in per-platform binaries — which nobody should do.
4. If FFI rather than subprocess: a shared-library target that does not exist upstream. `scp.c:2745` defines `main`, so you would have to exclude or rename it, and add your own init entry point. That is a patch you then carry forever against a frozen upstream.
5. A licence-scanner allowance for the `NOASSERTION` classification, if we ever add one.
6. Developer-machine friction: a fresh clone stops being `dart pub get && dart test`.

The honest summary is that the compile is easy and the integration is not. The cost is not the build; it is that a pure-Dart repository with a three-command CI gate acquires a second toolchain, a platform matrix, and a binary artefact.

### dartInterop

Three mechanisms, in increasing cost. The cheapest is pure Dart with no FFI and no C in CI, and it is the one I would actually use.

**1. Subprocess driving the SCP REPL — pure Dart, no FFI.** Build `i7090` once by hand. From Dart, `Process.start` it with a generated `.ini`, or feed SCP commands on stdin and parse stdout. The command vocabulary is `SET CPU 7090`, `SET CPU 32K`, `DEPOSIT <addr> <octal>` to load words, `DEPOSIT PC <addr>`, `BREAK <addr>`, `GO`, `EXAMINE AC`, `EXAMINE MQ`, `EXAMINE XR[0:7]`, `EXAMINE <lo>-<hi>`, `CONTINUE`. Breakpoint actions let one command do a state dump: `BREAK 100;EX AC;D MQ 0`. Everything is line-oriented text, so the Dart side is a small writer and a small parser. This gives us trap-at-address, read and write of registers and memory, and resume — the exact three operations the task names — for the price of a text round-trip per trap. No `dart:ffi`, no C in the CI gate, no shared library, no patch carried against upstream.

**2. Remote console socket — also pure Dart, better for interactive control.** Start the simulator with `SET REMOTE TELNET=<port>` (`scp.c:1355`) and connect a Dart `Socket`. This is the same transport `sim_frontpanel.c` uses; we would be reimplementing its client side in Dart rather than binding to it. It buys asynchronous halt and inspection while the simulator runs, which mechanism 1 does not. Same text-protocol cost. It is strictly more work than mechanism 1 for a batch oracle, and only pays off if we want to poke a running machine.

**3. `dart:ffi` against a shared library — possible, and the one I would avoid.** It is genuinely feasible, more so than I expected, because all the CPU state in `I7000/i7090_cpu.c` is plain non-static globals (lines 228-232):

    t_uint64            M[MAXMEMSIZE] = { 0 };      /* memory */
    t_uint64            AC, MQ;                     /* registers */
    uint16              XR[8];                      /* Index registers */
    uint16              IC;                         /* program counter */
    uint16              IR;                         /* Instruction register */

So a Dart `DynamicLibrary.lookup<Pointer<Uint64>>('M')` reads and writes 7090 core directly, and `AC`, `MQ`, `XR`, `IC` the same way. `sim_instr()` is `extern t_stat sim_instr (void);` (`scp.h:351`) — call it, it runs until a stop, and returns `STOP_IBKPT` when a breakpoint fires. Set breakpoints with `t_stat sim_brk_set (t_addr loc, int32 sw, int32 ncnt, CONST char *act)` (`scp.h:518`). Resume by setting `IC` and calling `sim_instr()` again. That is a clean trap-inspect-resume loop with no text parsing and no socket.

The catch is what it costs to get there. `scp.c:2745` defines `int main`, so a `.dylib`/`.so` build means excluding or renaming it and writing our own initialisation entry point that does what `main` does — device reset, memory sizing, `sim_brk_init`. Upstream has no library target and is frozen, so that patch is ours forever. Add per-platform shared-library builds to CI, `ffigen` or hand-written bindings, and a `NativeFinalizer` story. Against a 889-line Dart core that already passes, that is a lot of machinery.

**What none of them gives us: a per-instruction hook.** Mechanism 3 could get one only by patching `sim_instr()` to call a Dart callback, which means an FFI callback on the simulator's own thread inside the hot loop. Mechanism 1 or 2 could approximate it with `sim_panel_exec_step`-style single-stepping, at a text round-trip per instruction — unusable for anything but a few hundred instructions. Our design does not need one; it needs trap-at-address, which all three provide.

### runtimeGap

No. It supplies nothing whatsoever toward the lost SYS)/IOC) runtime, and the gap is not the kind of thing SIMH could ever close.

The distinction is between hardware and software. SIMH emulates IBM 709x *hardware* — the CPU, the 7607 and 7909 data channels, tape drives, card reader, printer, drum, disk. The SYS)/IOC) library was IBM *software*: object code produced by the Commercial Translator processor's own runtime, shipped on a distribution tape, and lost. No hardware emulator can regenerate it, any more than an accurate x86 emulator can regenerate a deleted DLL. There is no COMTRAN artefact anywhere in the repository — I checked the full `I7000/` and `I7094/` file listings, and every file is a device, CPU, or SCP module.

Worse, SIMH's I/O model is the opposite of decision D0.7. Our generated code contains no RDS, no WRS, no channel opcode; I/O is intercepted at the IOCS entry points and handled in Dart. SIMH's 7090 support is built the other way round: `I7000/i7090_chan.c` is 68 KB of 7607/7909 channel emulation, `I7000/i7000_mt.c` is 50 KB of tape drive, `I7094/i7094_io.c` likewise. Using SIMH means either carrying all of that dead — it never executes, because our object programs never issue a channel command — or trapping above it, at which point the channel code was irrelevant to us from the start.

What SIMH does supply, and it is not nothing:

- A second, independent, period-validated implementation of the 7090 instruction set, with a real `SET CPU 7090` model. That is a differential oracle for our 43 opcodes, and a good one.
- Two such implementations, in fact, written by different authors from the same IBM manuals. Where Cornwell and Supnik agree and we disagree, we are wrong.
- Instruction history (`SET CPU HISTORY=n`) and a symbolic disassembler (`i7090_sys.c`, 32 KB) for reading a trace.
- David Pitts' object-deck binary loader (`I7094/i7094_binloader.c`), which handles a related but different deck format — `#define IBSYSSYM '$' /* Marks end of object file */`, `#define WORDPERREC 5`, `#define LOADADDR 0200`. Not the J 90.03 format, so not directly reusable, but a period-format reference point.

The thing to be clear about: adopting SIMH would not reduce the M4 stage 4 work by one line. The dispatch layer, the Dart compute handlers at the documented runtime entry points, and the end-to-end execution tests are all still ours to write. SIMH would only replace the 889 lines of CPU that are already written and already green.

### verdict

Test oracle only, and only as a developer-machine tool that never touches CI. Open SIMH is a genuinely strong candidate on the two questions that usually kill these — it has a real `SET CPU 7090` model in both of its independent 7090 implementations, with the 7094 divergence gated instruction-by-instruction and multi-tag mode forced on for the 7090, and Cornwell's has booted CTSS, IBSYS and Lisp 1.5. Its MIT licence permits anything we would want. Its i7090 and i7094 targets are already built green by upstream CI on `macos-latest` and `ubuntu-latest`, the exact platforms we use. But it cannot replace our CPU core, for a reason that has nothing to do with quality: it is a program, not a library, its entire I/O model is channel-level emulation that D0.7 rules out, and it supplies nothing at all toward the lost SYS)/IOC) runtime — the actual remaining work in M4 stage 4 would be unchanged, while a pure-Dart repository with a three-command gate would acquire a C toolchain, a platform matrix, a binary artefact, and a patch carried forever against a frozen upstream. That is a large, permanent cost to displace 889 lines of Dart that already pass 1179 tests and that throw a typed exception rather than guess. The oracle case is the one worth taking. Build `i7090` once by hand, drive it from Dart with `Process.start` and generated SCP scripts — `SET CPU 7090`, `DEPOSIT` the words, `BREAK`, `GO`, `EXAMINE` — and diff AC, MQ, XR, IC and memory against our core over the same instruction sequences. That is pure Dart, no FFI, no CI change, and one afternoon's work. It is worth doing because the 43-opcode subset is fixed-point only, and every known bug Cornwell documents lives in double-precision floating point, floating add, channel skips, hypertape and disk — none of them in our subset. Where our sign-magnitude arithmetic, the AC's Q and P bits, or the ten index instructions (TXI, TIX, TNX, TXH, TXL, TSX, LXA, SXA, PXA, PDX) diverge from two independently written period-validated implementations, we would learn something real.

### uncertainties

Six things I could not confirm, stated plainly.

**I never built or ran either simulator.** Every claim above comes from reading the fetched source, headers, README, CMake files and CI workflow. I did not compile `i7090`, did not execute one instruction, and did not verify that the `SET CPU 7090` model is bit-exact against A22-6528-4 for our 43 opcodes. Establishing that is precisely what the differential run I recommend would do, and it should be done before trusting the oracle.

**"CTSS works / IBSYS works" is unverified by me.** It is Richard Cornwell's own README claim. I found no tape image, boot script, `.ini`, or CI job in the repository that demonstrates it, and no independent write-up that I fetched. The corroborating evidence I do have is circumstantial: 67 numbered fixed defects in `I7094/i7094_bug_history.txt` that read like they came from running real software, and David Pitts' object-deck loader having been upstreamed into `I7094/`.

**GitHub's API rate-limited me partway through.** I got Open SIMH's repository metadata and its `I7000`, `I7000/i7090_cpu.c` and `I7094` path histories, and `simh/simh`'s metadata and `I7000/i7090_cpu.c` history, all before the limit. I did not get `simh/simh`'s `I7094` path history or either fork's latest overall commit list. So "the 7090/7094 sources are frozen in both forks" rests on the `i7090_cpu.c` comparison — same date, same message, 2023-12-31 — and not on a full diff of the two trees.

**I did not verify the frontpanel library builds on current macOS.** `sim_frontpanel.c` is compiled only by the `frontpaneltest` makefile target (`makefile:3058-3063`) and upstream CI does not build it. Since I recommend the pure-Dart subprocess path over FFI, this matters little, but I should not be read as having confirmed it works.

**I did not confirm the SCP text output formats.** The subprocess oracle depends on `EXAMINE AC` and friends printing something a Dart parser can read reliably across versions. I read the command list and the `BREAK` help text in `scp.c`, but not the output-formatting code, and I did not see a sample transcript. This is a small risk and would surface in the first hour of building the oracle.

**I did not read `docs/design/emulator.md` or `lib/src/emulator/cpu.dart`.** I read `decode.dart` far enough to extract the opcode set and confirm it is fixed-point only. Whether our core's semantics for the AC's Q and P bits, end-around carry on ACL, or multi-tag indexing already match SIMH's is exactly the open question, and I have not looked. One further thing I noticed but could not pursue: Supnik's `stop_illop` is an exposed register, so a script that clears `STOP_ILL` turns a 7094-only instruction on a 7090 model into a silent no-op via `continue` — any oracle harness must leave it at its default of 1.


## Richard Cornwell's sims (rcornwell/sims), I7000/i7090

`https://github.com/rcornwell/sims`

### sevenOhNineZero

Yes — a genuine, separately-selectable 7090 model, and it is the default. `I7000/i7090_cpu.c:178-181` defines four models: "#define CPU_704         0", "#define CPU_709         1", "#define CPU_7090        2", "#define CPU_7094        3". Line 365 registers the SET option: `{UNIT_MODEL, MODEL(CPU_7090), "7090", "7090", NULL, NULL, NULL},` alongside line 366's 7094 entry. Line 302 makes 7090 the default unit: `{ UDATA(rtc_srv, UNIT_BINK | MODEL(CPU_7090) | MEMAMOUNT(4),`. I built the binary and confirmed live: `set cpu 7090` then `show cpu` prints "7090, 32K".

The model split is real, not cosmetic. Line 409 defines `#define I_94    0x0400          /* 7094 only */`, the opcode-flag tables tag ~12 opcodes with it (e.g. line 472 `/* 0300 */ T_B, I_94|T_B,  T_B,  I_94|T_B, ...`), and the decode loop gates them at lines 1099-1102:
```
            /* If proc does not support this opcode, just skip it */
            if (opinfo & I_9 && CPU_MODEL == CPU_704)
                break;
            if (opinfo & I_94 && CPU_MODEL != CPU_7094)
                break;
```
Index-register behaviour is also modelled. Line 660-661: `#define get_xr(t) (((t)) ? ((MTM) ? (XR[(t)&04] | XR[(t)&02] | XR[(t)&01]) : XR[(t)]) : 0)` — multi-tag mode ORs XR1/XR2/XR4, which is the 7090 rule; 7094 single-tag selects one of seven. `cpu_reset` at line 4192 sets `MTM = 1`, so a fresh machine starts in 7090-compatible indexing. I confirmed live: after a `TSX 400,4`, `ex xr[4]` returned `77677` (the correct 15-bit two's complement link to 0101) and `ex mtm` returned `1`.

Two honest caveats, both mild for our use. First, that "just skip it" comment is literal: on a 7090 config a 7094-only opcode becomes a silent no-op, not a trap. Our Dart core throws a typed exception naming the octal opcode — a strictly better failure mode. Second, `OP_LMTM` at lines 1345-1347 clears MTM for any model except the 704, so a "7090" config still honours LMTM/EMTM, instructions a real 7090 does not have. Neither matters for code our compiler emits, but both mean the 7090 model is "7094 with 7090 defaults", not a hardware-accurate 7090.

### embeddable

Interactive SCP console only. There is no C entry point that takes a per-instruction callback, no library API you link against, and no way for a host to register a handler at an address. What exists is SimH's standard breakpoint machinery plus EXAMINE/DEPOSIT, driven from a console.

The trap point is one line in the fetch loop, `I7000/i7090_cpu.c:805`:
```
                 sim_brk_test(((bcore & 2)? CORE_B:0)|IC, SWMASK('E'))) {
```
That is checked before the instruction at IC executes. `scp.c` supplies the commands (`BREAK`, `EXAMINE`, `DEPOSIT`, `GO`, `CONTINUE`, `STEP`) and breakpoint actions (`sim_brk_act[]`, scp.c:619, so a breakpoint can carry a `;`-separated command list executed on hit).

I built the simulator and ran the exact loop the task describes. Script:
```
set cpu 7090
dep -m 101 TSX 400,4     ; call a "runtime entry"
dep -m 400 HTR 0
break 400
go 100
```
Output: `Breakpoint, IC: 00400 (  000000000000   HTR 00000)`. At that stop, `ex ic` gave `00400`, `ex ac` gave `0000000000007` (the value the pre-call CLA left), `ex xr[4]` gave `77677` (the TSX return link). I then wrote the handler's answer back — `dep ac 66`, `dep -m 400 TRA 1,4` — and `go` resumed; the following `ADD` produced `AC: 0000000000076`. The whole intercept-inspect-inject-resume cycle works.

The host-visible state is the REG table at `i7090_cpu.c:310-357`: IC, IR, AC (38 bits), MQ, `BRDATAD(XR, XR, 8, 15, 8, "Index registers")` addressed as `XR[n]`, ID, MA, SL, SW, KEYS, MTM, TM, STM, CTM, FTM, NMODE, ACOVF, MQOVF, IOC, DVC, RELOC, BASE, LIMIT, ENB. Memory is `ex`/`dep` by octal address, symbolically with `-m`.

Two out-of-process control paths exist beyond typing at the console. `sim_frontpanel.h` at the repo root declares a client library: `sim_panel_start_simulator`, `sim_panel_break_set`, `sim_panel_gen_examine`, `sim_panel_gen_deposit`, `sim_panel_set_register_value`, `sim_panel_exec_run/step/halt`, `sim_panel_get_registers` — but it spawns the simulator binary as a subprocess and speaks the remote-console protocol, so it is a client, not an embedding. `scp.c:1354` provides `SET REMOTE TELNET=port`. I started the simulator with that and a plain TCP socket connected and received the banner ("Connected to the IBM 7090 simulator REM-CON device"), but no command output came back; master mode was refused with "Console port must be Telnet or Serial with Master Remote Console". I did not verify the remote console further — see uncertainties.

### battleTested

Real IBM period diagnostic decks, run automatically by the build, with a byte-for-byte log comparison. This is the strongest evidence any candidate could offer short of a tape boot, and I reproduced it.

`I7000/tests/i7090_test.ini` boots 23 genuine 709/7090 customer-engineer diagnostic decks in sequence — 9M01B, 9M02A, 9M03A, 9M04A, 9M05B, 9M21A, XCOMC, 9SY1A, 9EFPA, 9ESLA, 9COMB, 9C01A, 9C02A, 9R01A, 9B01A, 9P01C, 9P02A, 9T01A, 9T02B, 9T03A, 9T04A, 9D01A, 9IOTA — logging console output, and ends with:
```
if -F "test.log" == "good.test.bin" delete test.log ; exit 0
exit 1
```
The `.dck` files are checked into `I7000/tests/i7090/` (53 decks, more than the .ini runs). `makefile:1688-1689` wires this into the build target, so `make i7090` builds and then runs the suite. On my machine `make i7090` returned `EXIT=0` — the log matched `good.test.bin` byte for byte.

Two things sharpen that. The suite opens with `set cpu 709`, not `set cpu 7090`, so it validates the 709 path; the 7090-specific branches (`i7090_cpu.c:1969` `CPU_MODEL < CPU_7090`, `:2185` `CPU_MODEL == CPU_7090`, `:3353` `CPU_MODEL >= CPU_7090`) are not covered by it. And the suite is not clean-pass in the naive sense — it is a *golden log*, so known diagnostic errors are baked into the expected output (the run prints lines like "ERROR - -  TRP LOC 00014   TYPE 3 ...").

The 7090 path rests on README claims I did not reproduce: "CTSS    works.", "IBSYS   works.", "Stand alone assembler works.", "Lisp 1.5 works." The same README is candid about defects: "DFDP/DFMP     Sometimes off by +/-1 or 2 in least signifigant part of result.", "EAD           +n + -n should be -0 is +0", "Not all channel skips working for 9P01C.", "HTx	Not sure what problems are, does not quite work.", "DKx	Sometimes fails diagnostics with missing inhibit of interrupt.", "Signifigance mode Not tested, Test Code Needed." Note the floating-point and channel defects; the arithmetic ones would surface in a differential test against our core.

### maintenance

The repository is alive; the 7090 sources are stable rather than active. rcornwell/sims HEAD is `9510a91f4c7cb001293a57682de62102d6b07437`, dated 2026-03-08, "KA10: Fixed DP seek done to not move uptr." — but that is PDP-10 work. The I7000 directory last changed 2024-05-10 (`7021c77`, "I7000: Updated 7010, 7070, 7080 for EOF handling."). The 7090 files specifically: `i7090_cpu.c` last touched 2024-03-12 (`3f579ed`, "I7000: Minor fixes."), `i7090_chan.c` 2024-03-19, `i7090_sys.c` 2020-09-13. Recent I7000 commits are compiler-warning cleanups and CMake support, not emulation changes — a module in maintenance, which for a 1962 target is what you want.

On which fork is alive: both, and rcornwell is upstream for this module. open-simh/simh HEAD is `a1f57fa`, 2026-07-03 — more active overall — and it carries an I7000 directory whose last commit is 2024-05-19 (`9515201`, the same "Updated general card reader, printer and magtape" change that landed in rcornwell on 2024-05-10). But open-simh's `I7000/i7090_cpu.c` last changed 2023-12-31 (`1a1396d`), while rcornwell's changed 2024-03-12. So for the 7090 CPU file specifically, rcornwell/sims is ahead of open-simh. The binary I built announces itself as "IBM 7090 simulator Open SIMH V4.1-0" because rcornwell's tree rides on the Open SIMH SCP core.

### license

MIT, per file, with no LICENSE file at the repository root — I checked, there is none. Every one of the 27 sources the i7090 link line pulls in carries an MIT permission grant; none mentions GPL or LGPL.

The 7090 CPU header, `I7000/i7090_cpu.c:3-21`, verbatim:
"Copyright (c) 2005-2016, Richard Cornwell

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
   RICHARD CORNWELL BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
   IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."

The SCP core, `scp.c:3`, is "Copyright (c) 1993-2022, Robert M Supnik" with the same MIT text plus one extra paragraph (scp.c:22-24):
"Except as contained in this notice, the name of Robert M Supnik shall not be
   used in advertising or otherwise to promote the sale, use or other dealings
   in this Software without prior written authorization from Robert M Supnik."

That is a no-endorsement clause, not a use restriction. Other holders in the link set: David T. Hittner (sim_ether.c), Mark Pizzolato (sim_disk.c), J. David Bryan + Mark Pizzolato (sim_serial.c), Matt Burke (sim_video.c), Howard M. Harte (sim_imd.c) — all MIT.

Vendoring and FFI-linking are both permitted, provided the copyright notices and permission text ship with any copy or substantial portion. Practically: if we vendor, we must carry the headers, and we must not use Supnik's name promotionally. There is no copyleft obligation on our Dart code.

### buildCost

Low, and I proved it — but "low" still means adding a C toolchain step the repository currently does not have.

I ran `make i7090` on this machine (macOS 15.5, arm64, Apple clang 21). Result: `EXIT=0`, `BIN/i7090` a 928 KB Mach-O arm64 executable, in about one minute, with a single linker warning ("reducing alignment of section __DATA,__common"). The compile is one command, no configure, no object files:
```
gcc -std=c99 -U__STRICT_ANSI__ -O2 -DNDEBUG=1 -fno-strict-overflow -finline-functions
  ... -Werror -D_GNU_SOURCE -DHAVE_SYS_IOCTL -DSIM_HAVE_DLOPEN=dylib -DHAVE_EDITLINE
  -DHAVE_UTIME -DHAVE_LIBPNG -DHAVE_GLOB -DHAVE_SHM_OPEN
  ./I7000/i7090_cpu.c ... ./scp.c ./sim_console.c ... ./sim_card.c
  -I ./I7000 -DUSE_INT64 -DI7090 -DUSE_SIM_CARD -o BIN/i7090 -lpthread -ledit -lpng
```
Dependencies are thin: pthreads (system), libedit (system on macOS, `libedit-dev` on Linux), libpng (optional, only for screenshot support — it auto-detects and would drop out cleanly). No SDL, no libpcap needed for this target; the makefile probes for them and proceeds without. A CMake path also exists (`CMakeLists.txt`, added 2024-03-12).

What a CI job would have to add: a C compiler (both GitHub runners already have one), `libedit-dev` on ubuntu-latest, a checkout or submodule of ~4 MB of C sources, and roughly one to two minutes of build plus about a minute of diagnostic-suite runtime. Non-trivial but not hard.

The real cost is not the minutes. It is that `dart format` / `dart analyze --fatal-infos` / `dart test` is currently the entire gate, and adding a native build makes CI bimodal — the Dart gate can no longer be the single source of truth about whether the tree is good. That argues for keeping any use of this simulator out of CI entirely: a local `tool/` script a developer runs, or an optional non-blocking job.

### dartInterop

Subprocess only, and it needs a pseudo-terminal — plain pipes do not work. I tested both.

Driving `BIN/i7090` from a process with `stdin=PIPE, stdout=PIPE` fails: every command was accepted but produced no output, because C stdio fully buffers stdout when it is not a terminal. `ex ac` sat in the buffer; nothing came back until an unrelated flush. A request/response loop over `Process.start` with default pipes will simply hang.

Over a pty the same session works perfectly:
```
>> go 100   => Breakpoint, IC: 00101 (  000000000000   HTR 00000) | sim>
>> ex ac    => AC:	0000000000007 | sim>
>> dep ac 66
>> ex ac    => AC:	0000000000066 | sim>
```
Dart has no pty in the SDK. Closing that gap means `dart:ffi` to `forkpty`/`openpty`, or a pub package, or wrapping the binary in `script`. All are real work and all are platform-specific.

`dart:ffi` directly into the simulator is not available. SimH is a program, not a library: `scp.c` owns `main()`, state is file-scope globals (`M[]`, `AC`, `MQ`, `XR[]`, `IC`), and there is no exported entry that runs N instructions and returns. You could compile it `-shared`, rename `main`, and call `sim_instr()` — but you would be maintaining a private fork of the build for the privilege, and you would still have no per-instruction callback. `sim_frontpanel.c` is FFI-able as a shared library, but it spawns the simulator binary underneath, so it buys you the pty problem solved by someone else, at the cost of a C library in the loop.

The mechanism that works today with no pty and no FFI is batch scripting, which is exactly what I used for every experiment above: generate a `.ini` file from Dart, run `Process.run('i7090', ['job.ini'])`, parse the octal text output. One process per test case, no interactivity. That is more than enough for a differential oracle (deposit a program and its inputs, run to HTR, examine AC/MQ/XR/memory, diff against our Dart core word for word) and useless for interactive Dart runtime handlers, which need a live conversation.

### runtimeGap

No. Nothing in this repository closes the lost-SYS)/IOC)-runtime gap, and nothing could — the gap is that IBM's COMTRAN runtime library machine code does not survive, which is a software-archaeology problem, not an emulation problem. Cornwell's tree contains no COMTRAN anything: no reference to the language, no runtime entry points, no 90.03-format deck reader, no CT Loader.

What it supplies instead is the layer below ours: a 709/704/7090/7094 CPU, the data and I/O channels (`i7090_chan.c`, `i7000_chan.c`), and period peripherals — card reader, card punch, printer, magnetic tape, drum, high-speed drum, disk, chronolog clock, and a communications adapter. Its I/O is modelled at the channel and device level, which is the opposite of D0.7's IOCS-level choice: the diagnostic decks exercise RDS/WRS and channel commands throughout, and generated COMTRAN code emits none of that.

So even a hypothetical version of this project that solved the embedding problem would leave the entire M4 stage 4 deliverable untouched. The dispatch layer, the Dart compute handlers at the documented runtime entry addresses, and the end-to-end execution tests all still have to be written. Adopting the simulator would replace 889 lines of Dart we already have and already trust, and remove none of the work that remains.

### verdict

Test oracle only — and a genuinely excellent one, which is worth saying clearly, because it is the best differential reference we are likely to find. Replacement is ruled out three times over. D0.3 is locked on a Dart core; the CI gate is three Dart commands and adding a native build makes it bimodal; and the embedding story is a pty-driven subprocess with text parsing, which is a worse foundation for the M4 stage-4 dispatch layer than the in-process Dart core we already have. There is also a concrete property we would lose: `i7090_cpu.c:1102` skips an unsupported opcode ("just skip it"), where our core throws a typed exception naming the octal opcode — the repository has a hard rule against silent wrong paths, and this would install one. As an oracle it is strong for exactly the reasons replacement fails: it has a real 7090 model that is the default and is not merely a relabelled 7094, it passes 23 genuine IBM diagnostic decks against a byte-compared golden log, and it has seen code — IBSYS, CTSS, Lisp 1.5 — that our 43-opcode subset never will. The shape I would recommend is a `tool/` script, outside CI, that emits a `.ini` per test case, runs `Process.run` on the built binary, and diffs AC/MQ/XR/memory against our core word for word; the pty problem never arises, no C step touches the gate, and the first divergence it finds pays for the whole exercise. Two known-defect areas to keep off the diff list: the README's own DFDP/DFMP and EAD floating-point bugs, and anything channel-related.

### uncertainties

Five things I could not confirm, stated plainly.

I did not reproduce the IBSYS, CTSS, Lisp 1.5 or standalone-assembler claims. Those are README assertions; the tapes are not in the repository and I did not go looking for them. They are the only evidence for the 7090-and-above code paths, since the automated suite runs `set cpu 709`.

I could not get the remote console to answer commands. The listener works — `SET REMOTE TELNET=45999` printed "%SIM-INFO: Listening on port 45999" and a raw socket received the REM-CON banner — but no command produced output, and master mode refused with "Console port must be Telnet or Serial with Master Remote Console". I did not negotiate telnet options, and non-master remote console may only be serviced while instructions execute, so this is very likely my test's fault rather than the simulator's. I stopped there because the pty path already worked and is simpler.

I did not test on Linux. The build evidence is macOS 15.5 / arm64 / Apple clang 21 only. The makefile has extensive Linux handling and Travis history, so I expect it to work, but I did not run it.

I did not audit the 7090 model for fidelity against A22-6528. I confirmed the model exists, is the default, gates 7094-only opcodes, and defaults to multi-tag indexing. I found one gap on inspection (LMTM/EMTM honoured on a 7090 config, lines 1345-1347 and 1421-1424) and did not look for others. There may be more.

I did not measure how fast a differential-oracle round trip is. One process launch per test case is clearly fine for a few hundred cases and clearly wrong for a few hundred thousand; I did not find where that line falls.

One point that is not uncertainty but is worth flagging: the licence rests entirely on per-file headers, because there is no LICENSE file in the repository. I read the copyright line of all 27 sources in the i7090 link set and confirmed every one carries an MIT grant with none mentioning GPL or LGPL. If we vendor, someone should assemble those notices deliberately rather than assume a single root licence exists.


## SimH_cpanel (rsanchovilla fork)

`https://github.com/rsanchovilla/SimH_cpanel`

### sevenOhNineZero

Yes — a genuine 7090 model, and it is the default. The candidate summary given to me was wrong: the fork does carry the IBM 7000 series, in `sims-master/i7000/`, which the README calls out ("IBM 7090/7094 control panel", "Source code in sims-master folder").

`sims-master/i7000/i7090_defs.h` defines four distinct models: `#define CPU_704 0`, `#define CPU_709 1`, `#define CPU_7090 2`, `#define CPU_7094 3`. `i7090_cpu.c` exposes them as SCP modifiers — `{UNIT_MODEL, MODEL(CPU_7090), "7090", "7090", NULL, NULL, NULL}` — so `SET CPU 7090` selects it, and the CPU unit is declared `UDATA(rtc_srv, UNIT_BINK | MODEL(CPU_7090) | MEMAMOUNT(4), ...)`, i.e. 7090 is the power-on default. Cycle timing is per-model: `case CPU_7090: cycle_time = 22; break;` against `case CPU_7094: cycle_time = 18; break;`.

The separation is real but not exhaustive, and both gaps are exactly the "silent divergence" Q1 warns about:

1. A 7094-only opcode running on the 7090 model is silently skipped, not trapped. The opcode tables flag them (`#define I_94 0x0400 /* 7094 only */`) and the decode loop reads, verbatim: "/* If proc does not support this opcode, just skip it */" followed by `if (opinfo & I_94 && CPU_MODEL != CPU_7094) break;`. No `STOP_UUO`, no diagnostic. Our compiler emits only 7090 opcodes, so it should never fire, but if it does it fires quietly.

2. `LMTM` and `EMTM` — the 7094 instructions that switch between multiple-tag and single-tag index mode — execute on every model except the 704: `case OP_LMTM: if (CPU_MODEL != CPU_704) MTM = 0; break;`. So the 7090 model can be put into single-tag mode and address index registers 3, 5, 6, 7, which real 7090 hardware does not have. Reset does set `MTM = 1` (correct 7090 multiple-tag default), and `get_xr` ORs the tag bits in that mode: `(((t)) ? ((MTM) ? (XR[(t)&04] | XR[(t)&02] | XR[(t)&01]) : XR[(t)]) : 0)`.

Net: as a 7090 oracle it is meaningfully configured, and considerably better than "7094 only". It will not police a 7090/7094 boundary violation for you.

### embeddable

There is no in-process embedding API. It is a SimH simulator: one executable with `main()` in `scp.c`, one global `sim_instr(void)` in `i7090_cpu.c` (line 709), and file-scope machine state (`uint16 XR[8]`, `t_uint64 M[]`, AC, MQ, IC). No shared-library target, no callback hook, no per-instruction plug-in point.

What it does give you is SimH's full SCP console, which is genuinely scriptable and covers trap/read/write/resume:

- **Trap at an address.** `sim_brk_test(((bcore & 2)? CORE_B:0)|IC, SWMASK('E'))` runs at the top of the fetch loop and sets `reason = STOP_IBKPT`. The `BREAK` and `NOBREAK` commands are in the SCP table, and breakpoints carry action strings — `t_stat sim_brk_set (t_addr loc, int32 sw, int32 ncnt, CONST char *act)` — so `BREAK 4000;EXAMINE AC` is a supported form.
- **Read and write registers and memory.** `EXAMINE` / `DEPOSIT` / `IEXAMINE` / `IDEPOSIT` are in the command table. Every 7090 register is published in the `cpu_reg` REG array, including `{ORDATAD(MTM, MTM, 1, "Multi Index registers"), REG_FIT}`.
- **Resume.** `CONTINUE`, `STEP`, `NEXT`, `GO`, `RUN`, `BOOT`. `STEP` is honoured inside the loop (`if (sim_step != 0) instr_count = sim_step;`).
- **Drive it from outside the process.** `SET REMOTE CONSOLE` is in the SET table (`{ "REMOTE", &sim_set_remote_console, 0, HLP_SET_REMOTE }`) and `sim_console.c` implements it (`sim_rem_con_poll_svc`, `sim_rem_con_data_svc`). That opens the SCP console on a TCP port.
- `sims-master/sim_frontpanel.h` documents a C client for that port: `sim_panel_start_simulator`, `sim_panel_break_set`, `sim_panel_exec_run`, `sim_panel_exec_step`, `sim_panel_exec_halt`, `sim_panel_mem_examine`, `sim_panel_mem_deposit`, `sim_panel_set_register_value`, `sim_panel_get_registers`. It is a convenience wrapper over the remote-console protocol, not a linkable simulator core.

So: trap-and-resume with a Dart handler is possible only as a text round trip per trap, out of process. There is no path where Dart code runs inside the fetch-execute loop without writing an FFI shim around `sim_instr()` and SimH's globals.

### battleTested

Mixed, and the strongest evidence is a self-assessment of known bugs rather than a test suite. There is no automated test suite for the 7090 anywhere in the fork.

The real evidence is `sims-master/i7000/STATUS.txt`, Cornwell's own status file, quoted exactly:

```
i7090:          Working with exceptions.

                Known bugs:

                DFDP/DFMP     Sometimes off by +/-1 or 2 in least signifigant
                                 part of result.

                HTx     Not sure what problems are, does not quite work.

                DKx     Sometimes fails diagnostics with missing inhibit of
                        interupt.

                CTSS    works.

                Share Lisp 1.5 does not boot.

                Signifigence mode Not tested Need.
```

"CTSS works" is strong: CTSS is a demanding 7094 workload that exercises relocation, protection and interrupts. "Sometimes fails diagnostics" tells you period IOMC diagnostics were run, and the file lists the console key settings for them.

The README's claims are the weaker half. It links downloadable kits under `test_run/i7000/`: `IBM7090_IBSYS_Build.zip` ("Build IBSYS from source files"), `IBM7090_IBSYS_Fortran_II_cobol.zip` ("IBSYS Fortran II and COBOL test run"), `IBM7090_Edit_Map_IBSYS.zip`, `IBM7090_Lisp_1.5.zip`, `IBM7094_IBSYS_Fortran_IV.zip`, `IBM7094_with_CTSS.zip`. I did not download or run any of them, and the README itself says the ready-to-run kits are Windows-only. Note the direct contradiction: the README ships a Lisp 1.5 kit while the STATUS.txt in the same tree says Lisp 1.5 does not boot. One of the two is stale, and I cannot tell you which.

For our purposes the DFDP/DFMP defect (double-precision floating multiply and divide off by one or two in the low-order part) is the one to remember. COMTRAN business arithmetic is fixed-point, so it likely never bites — but it is a documented word-inexactness in a tool we would be using precisely for word-exactness.

### maintenance

The fork is alive; its 7090 is not. Those are two different facts and the distinction decides the recommendation.

The fork: last push 2026-08-13, 298 commits, 82 stars, created 2017-10-14, not archived. The August 2026 commits are all Motorola 6800 and iCOM work — "iCOM EDOS-I Operating System", "Add support for iCOM FD-360 floppy drive", "Added recovered Motorola Assembler 1.0". Earlier 2026 and 2025 commits are Ferranti Mark I, IBM 650 and documentation. The `Original_SoftWare_Recovered.md` page, the maintainer's showcase of active recovery work, contains no mention of 7090, 7094, IBSYS, COBOL or CTSS at all.

The 7090 sources specifically, from `gh api .../commits?path=...`:

| file | last commit |
|---|---|
| `sims-master/i7000/i7090_cpu.c` | 2017-12-06, "Sync with rcornwell repo" |
| `sims-master/i7000/i7090_sys.c` | 2017-10-14, "Add files via upload" |
| `sims-master/i7000/i7090_chan.c` | 2017-10-14, "Add files via upload" |
| `sims-master/i7000/i7000_defs.h` | 2017-10-14, "Add files via upload" |
| `sims-master/i7000/STATUS.txt` | 2017-10-14, "Add files via upload" |
| `sims-master/i7000/i7090_cpanel.c` | 2017-12-08 (the fork's own contribution) |

So the CPU is a nine-year-old snapshot of somebody else's work, taken once and never resynced.

Which fork is alive for the 7090 itself:

- **rcornwell/sims** — the origin of this code. `I7000/i7090_cpu.c` last changed **2024-03-12** ("I7000: Minor fixes."), with "I7000: Fixed channel issues to allow I7090 to run Stress." on 2023-11-27. Repo pushed 2026-03-08, 114 stars, not archived. This is the freshest 7090 CPU.
- **open-simh/simh** — also carries `I7000/i7090_cpu.c`, last changed 2023-12-31 ("I7000: Group update for IBM 7000 series simulators."). Repo pushed 2026-07-03, so the project is more active overall but its 7090 copy is three months behind rcornwell's.

The rsanchovilla fork is therefore the worst of the three places to take a 7090 CPU from. Its contribution is the control panels, which are Windows-only and irrelevant to us.

### license

**There is no LICENSE file in this repository.** GitHub's API returns `"license": null` for it, and a code search for a licence file over the whole fork returns only two unrelated vendored ones: `simh-master/IBM360/sw/OSVS1R67/wc3270/LICENSE.txt` and `simh-master/I650/tools/OCR/pdf/NConvert/license.txt`. Licensing is per source file, in the header comment.

`sims-master/i7000/i7090_cpu.c`, verbatim:

```
/* i7090_cpu.c: IBM 7090 CPU simulator

   Copyright (c) 2005-2016, Richard Cornwell

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, ...
```

`sims-master/i7000/i7090_doc.txt` adds the joint notice and the one clause beyond plain MIT:

```
   Original code published in 1993-2005, written by Robert M Supnik
   Copyright (c) 1993-20054, Robert M Supnik
   IBM 7090 simulator written by Richard Cornwell
   ...
   Except as contained in this notice, the name of Robert M Supnik or Richard
   Cornwell shall not be used in advertising or otherwise to promote the sale,
   use or other dealings in this Software without prior written authorization
   from both Robert M Supnik and Richard Cornwell.
```

The fork's own files carry the same form — `sims-master/i7000/i7090_cpanel.c` and `sims-master/display/cpanel.c` both open "Copyright (c) 2017, Roberto Sancho" under identical MIT terms (with a copy-paste artefact: the liability and advertising clauses still name Robert M Supnik).

**Vendoring and FFI-linking are both permitted.** MIT with an advertising-name restriction. The only obligation is to reproduce the copyright notice and permission text in any copy or substantial portion — so a vendored `third_party/` copy must carry the headers, which it would anyway if you copy whole files. The name clause costs nothing: don't put Supnik's or Cornwell's name in marketing copy. Note that the absence of a repository-level LICENSE means anything in this fork *without* a header is unlicensed by default; check the header of every file you take.

### buildCost

C89-ish C, hand-written GNU makefile, and a CI job would have to add a C toolchain step this repository does not have.

The build path is `sims-master/i7000/makefile`, target `${BIN}i7090${EXE}`:

```
CC=gcc -g -D_GNU_SOURCE -I. -DUSE_SIM_CARD
LDFLAGS = -lm -lrt

I7090_OPT = -I.. -DUSE_INT64 -DI7090

${BIN}i7090${EXE} : ${I7090} ${SIM}
	${CC} ${I7090} ${SIM} ${I7090_OPT} -o $@ ${LDFLAGS}
```

That is about 30 translation units: 14 `i7090_*.c` / `i7000_*.c` files plus 13 SimH core files (`../scp.c ../sim_console.c ../sim_fio.c ../sim_timer.c ../sim_tape.c ../sim_sock.c ../sim_tmxr.c ../sim_ether.c ../sim_card.c ../sim_video.c ../sim_serial.c ../sim_disk.c`). `-DUSE_INT64` is mandatory — `i7090_doc.txt`: "To compile the IBM 7090, you must define USE_INT64 as part of the compilation command line."

What macOS + Linux CI would have to add:

1. **A C toolchain and make step.** Today CI is `dart format --set-exit-if-changed`, `dart analyze --fatal-infos`, `dart test`. This adds a compile stage, its cache, and a second class of build failure.
2. **A macOS fix for `-lrt`.** `librt` does not exist on Darwin; the link fails outright. Either patch `LDFLAGS` per platform or override it on the make command line. The makefile has commented-out Unix branches that were never finished — the live `LDFLAGS` line is Linux-only.
3. **Nothing for SDL2, if you skip the panels.** The i7000 makefile does not define `HAVE_LIBSDL`, so `sim_video.c` compiles to stubs. Good: the fork's whole selling point, the control panel, is not in the makefile at all. `i7090_cpanel.c` builds only through `sims-master/Visual Studio Projects/I7090.vcproj`, which pulls `..\display\cpanel.c`, `..\display\sim_ws.c` and `..\display\nanojpeg.c`. Windows only.
4. **A way to avoid a ~3.2 GB checkout.** The GitHub API reports `size: 3386991` (KB). That is the tape images, disk packs and panel artwork for a dozen machines. A CI job cannot clone this on every run. You would sparse-checkout `sims-master/i7000/` plus the ~13 `sims-master/sim_*.c`/`.h` files and `scp.c`/`scp.h`, or vendor those ~45 files under `third_party/` with their MIT headers intact.

Point 4 is the one that decides it. If the answer is "vendor 45 C files", there is no reason to vendor them from a 2017 snapshot inside a 3 GB repository rather than from rcornwell/sims where the same files are seven years newer.

### dartInterop

Subprocess or TCP socket, speaking SimH's SCP console protocol as text. `dart:ffi` is not realistically available, and there is no third option.

**The mechanism that works, concretely.** Build `i7090`, launch it with `Process.start`, and drive its console over stdin/stdout with `dart:io` — or issue `SET REMOTE CONSOLE TELNET=<port>` and attach a `Socket`, which keeps your control channel clear of the simulator's own console output. The trap-and-resume cycle per runtime entry point is:

1. Dart writes `BREAK 4000` (the entry address, octal) before the run.
2. Dart writes `CONTINUE`. The fetch loop reaches `sim_brk_test(...)`, sets `reason = STOP_IBKPT`, and SCP prints the stop and returns to the prompt.
3. Dart writes `EXAMINE AC`, `EXAMINE MQ`, `EXAMINE XR[1]`, `EXAMINE 1000-1010`, and parses the octal text back.
4. Dart runs the handler, then writes `DEPOSIT AC <octal>`, `DEPOSIT 1000 <octal>`, `DEPOSIT IC <return-address>`.
5. Dart writes `CONTINUE`.

Every step is a text round trip through a pipe. That is fine for a few hundred I/O calls in an acceptance test and unusable as the execution substrate for a program that calls the runtime in a loop.

**Why FFI is not on the table.** There is no library target — `scp.c` owns `main()`, and the makefile emits an executable. `sim_instr()` is `t_stat sim_instr(void)` with all machine state in file-scope globals (`XR[8]`, `M[]`, `bcore`, `MTM`), driven by SimH's own event queue via `sim_process_event()`. To call it from Dart you would fork SimH: build the ~30 files as a `.dylib`/`.so` with `-fPIC`, write a C shim exposing init / deposit / set-breakpoint / run / examine, and then keep that shim working against SimH's globals forever. That is a native build step, a vendored C fork, and a maintenance burden — against a Dart CPU core that already exists here and already passes 1600 lines of tests.

**`sim_frontpanel` does not change this.** `sim_frontpanel.h` (`sim_panel_break_set`, `sim_panel_mem_examine`, `sim_panel_mem_deposit`, `sim_panel_exec_step`) looks like the embedding API you want, but it is a **C client library that speaks the remote-console protocol over a socket**. Binding Dart to it via FFI would add a native dependency to reach a protocol Dart can speak directly with `dart:io`. If you go this route, skip `sim_frontpanel` and write the socket client in Dart.

One practical wrinkle for oracle use: our loader consumes a [J 90.03] object deck, which SimH's `i7090_sys.c` load routine knows nothing about. You would stage the core image into the simulator with a generated file of `DEPOSIT <addr> <octal>` lines fed through `DO`, then single-step both machines and diff AC, MQ, IC, the index registers and the touched memory words.

### runtimeGap

No. It supplies nothing for the lost SYS)/IOC) runtime, and nothing in the SimH world can, because the gap is not a hardware gap.

The missing artefact is the machine code of one particular compiler's runtime library — the object modules that the 1962 COMTRAN processor linked behind each `SYS)` and `IOC)` entry. A CPU simulator faithfully executes whatever words are in memory. If those words do not exist, no simulator invents them. SimH would sit at the runtime entry address, fetch whatever happens to be there, and either halt on `STOP_UUO` or run garbage. The Dart-handler-at-the-entry-point design in D0.3 remains the only way to close it.

What the fork supplies instead, in descending order of usefulness to this project:

1. **A second opinion on 7090 instruction semantics.** `i7090_cpu.c` is 4,435 lines implementing the full 704/709/7090/7094 opcode set, with per-model guards. Our Dart core implements 43 opcodes — the subset our own code generator emits. Running the same object image on both and diffing register and memory state after each instruction would catch a misread of the A22-6528-4 manual in our core. That is the one genuine offer.
2. **A period software corpus that is adjacent to, but not, the thing we need.** `test_run/i7000/IBM7090_IBSYS_Fortran_II_cobol.zip` is billed as an IBSYS FORTRAN II and COBOL run on the 7090. IBM's 7090 COBOL is COMTRAN's direct successor and would have used IBSYS IOCS conventions. As *external period evidence* about what 1962 runtime calling sequences looked like on this machine, that is worth a look. It is not the COMTRAN runtime, it carries no weight against the manuals under the section 9 evidence rules, and I have not opened it.
3. **Control panel visuals.** Windows-only, and irrelevant.

Note also that D0.7 puts I/O at the IOCS level with no channel opcodes in generated code. That deletes most of what the i7000 tree actually is — `i7090_chan.c`, `i7000_mt.c`, `i7090_cdr.c`, `i7090_cdp.c`, `i7090_lpr.c`, `i7000_dsk.c` — from any use we would make of it. We would be taking the CPU and discarding the machine.

### verdict

Neither replacement nor, in this form, the right oracle: the 7090 CPU inside this fork is real and genuinely 7090-configured, but it is a 2017 snapshot of somebody else's simulator sitting in a 3.2 GB repository whose maintainer works on other machines. It cannot replace our CPU core — it is C with `main()` in `scp.c` and all machine state in file-scope globals, so trap-and-resume from Dart means either a text round trip per trap over a pipe, or forking SimH into a shared library and maintaining a C shim; either way a pure-Dart CI gains a C toolchain, a `-lrt` macOS patch, `-DUSE_INT64`, and a vendored `third_party/` tree of about 45 files, to replace a 889-line Dart core that already passes 1600 lines of tests. It supplies nothing at all for the lost SYS)/IOC) runtime, which is the actual hard part of M4 stage 4, and D0.7's IOCS-level I/O deletes the channel and device half of the i7000 tree from any use we would make of it. What it could honestly do is serve as a differential oracle for the 43 opcodes we implement: build `i7090`, stage a core image via `DO` and `DEPOSIT`, then `BREAK`/`STEP`/`EXAMINE` both machines and diff AC, MQ, IC, XR and memory — a one-off confidence check against our reading of A22-6528-4, run on a developer's machine and never in CI. But if that is the use, take the sources from **rcornwell/sims**, where `i7090_cpu.c` last changed 2024-03-12 rather than 2017-12-06, where the 2023 channel fixes landed, and where you are not cloning gigabytes of tape images and panel photographs to get 45 C files. The rsanchovilla fork's contribution is control panels built only by a Visual Studio project on Windows. For this project it is strictly the worse copy of a thing we would use sparingly, if at all.

### uncertainties

Five things I did not confirm.

**I ran nothing.** I did not compile the simulator on macOS or Linux, and I did not download or execute any of the `test_run/i7000/` kits. Every claim about behaviour comes from reading the C source, the makefile, `STATUS.txt` and the README. The `-lrt` link failure on macOS is inferred from `librt` not existing on Darwin, not observed.

**The README and STATUS.txt contradict each other on Lisp 1.5.** `STATUS.txt` says "Share Lisp 1.5 does not boot"; the README links `IBM7090_Lisp_1.5.zip` as a working test run. Both files are in the same tree. I cannot tell which is stale, and that uncertainty extends to the other test-run claims — "IBSYS Fortran II and COBOL test run" may be equally out of date, or the STATUS file may simply never have been updated after the panels work fixed things.

**The IBSYS and COBOL kit contents are unverified.** I did not open `IBM7090_IBSYS_Fortran_II_cobol.zip`. Whether it contains a genuine period 7090 COBOL compiler, and whether it runs under the 7090 model rather than the 7094, I do not know. If that corpus matters as period evidence, someone should open it.

**How far the 2017 snapshot has actually diverged.** I compared commit dates, not code. Upstream's `i7090_cpu.c` has moved through at least five commits since 2017-12-06, including "Fixed channel issues to allow I7090 to run Stress" (2023-11-27) and "Minor fixes" (2024-03-12). I did not diff the two files, so I cannot say whether the CPU semantics we would care about changed at all, or only the channel code that D0.7 makes irrelevant to us.

**Whether the remote-console path actually works on this build.** `sim_set_remote_console` is in the SET table and `sim_console.c` implements the service routines, but `scp.c` in this 2017 snapshot has only six occurrences of "REMOTE" and there is no separate `sim_remote_console.c`. I believe the feature is present and complete, but I verified its declarations, not a live session on the `i7090` binary.


## SimH — I7094 module (Robert M. Supnik)

`https://github.com/simh/simh/tree/master/I7094`

### sevenOhNineZero

Yes — a genuine, enforced 7090 model, and this is the candidate's strongest single feature. i7094_cpu.c:335-341 defines the model table: "MTAB cpu_mod[] = { { MTAB_XTD | MTAB_VDV, I_9X|I_94|I_CT, \"MODEL\", \"CTSS\", &cpu_set_model, &cpu_show_model, NULL }, { MTAB_XTD | MTAB_VDV, I_9X|I_94, NULL, \"7094\", &cpu_set_model, NULL, NULL }, { MTAB_XTD | MTAB_VDV, I_9X, NULL, \"7090\", &cpu_set_model, NULL, NULL },". i7094_defs.h:198-201 defines the flags: "#define I_4X 0x01 /* 7040, 7044 */ ... #define I_9X 0x02 /* 7090, 7094, CTSS */ #define I_94 0x04 /* 7094, CTSS */ #define I_CT 0x08 /* CTSS */". SET CPU 7090 therefore sets cpu_model = I_9X only.

The gating is real, not decorative. The decode loop at i7094_cpu.c:799 reads: "if (fl & I_MODEL & ~cpu_model) { /* invalid for model? */ if (stop_illop) /* possible stop */ reason = STOP_ILLEG; continue; }". Seventeen entries in the 1024-entry op_flags table carry I_94; they cluster at the /* +260 */ and /* +300 */ rows, which the case labels identify as 00261 DFMP, 00301 DFAD, 00303 DFSB — the 7094 double-precision floating point set the 7090 does not have. Under SET CPU 7090 they raise STOP_ILLEG rather than executing.

Index-register semantics are also switched, which is the divergence that would silently corrupt our object code on a 7094 model. i7094_cpu.c:631: "if (!(cpu_model & (I_94|I_CT))) /* ~7094? MTM always on */ mode_multi = 1;" — the 7090 is forced into multi-tag mode. get_xri then ORs XR[1], XR[2], XR[4] for a composite tag, and get_xrx writes the OR'd value back through put_xr to every register involved (bug-history item 21: "CPU: Multi-tag mode stores OR'd value of tags on any index read except normal effective address"). That is the 7090's three-index-register behaviour modelled deliberately. Memory follows too: cpu_set_model sets "uptr->capac = STDMEMSIZE" (32KW) for non-CTSS models.

### embeddable

No embeddable API. This is an interactive SCP console program: main() lives in scp.c, and the CPU is entered only through "t_stat sim_instr (void)" (i7094_cpu.c:619), which runs until it returns a stop code. There is no callback registration, no host hook, and no shared-library target in the makefile (the i7094 rule at makefile:2941-2944 links an executable).

What does exist, named exactly:

Breakpoints. cpu_reset sets "sim_brk_types = sim_brk_dflt = SWMASK ('E');" (i7094_cpu.c:2253), and the fetch path tests "if (sim_brk_summ && sim_brk_test (PC, SWMASK ('E'))) { /* breakpoint? */ reason = STOP_IBKPT; /* stop simulation */" (i7094_cpu.c:688). So an execute-breakpoint at a runtime entry address does work — via the generic SCP command BREAK <addr> — but it stops the whole simulator and returns to the console prompt. Resumption is the SCP CONTINUE command, which calls sim_instr again.

Memory and registers. "t_stat cpu_ex (t_value *vptr, t_addr ea, UNIT *uptr, int32 sw)" and "t_stat cpu_dep (t_value val, t_addr ea, UNIT *uptr, int32 sw)" (i7094_cpu.c:2259, 2273) back the SCP EXAMINE and DEPOSIT commands; the cpu_reg REG table exposes AC, MQ, SI, KEYS, PC, XR, SSW, SLT and the mode flags by name. Underneath, all state is plain C globals (i7094_cpu.c:161-171): "t_uint64 *M = NULL; t_uint64 AC = 0; t_uint64 MQ = 0; ... uint32 PC = 0; ... uint32 XR[8] = { 0 };". A C shim could reach every one of them directly.

Per-instruction observation. There is no per-instruction hook, but there is a per-instruction trace: "tracing = ((hst_lnt != 0) || DEBUG_PRS (cpu_dev));" (i7094_cpu.c:639), and at each dispatch "if (DEBUG_PRS (cpu_dev)) cpu_fprint_one_inst (sim_deb, oldPC|HIST_PC, 0, ea, IR, AC, MQ, SI, 0);" (i7094_cpu.c:829-830). SET CPU DEBUG plus SET DEBUG <file> emits PC, effective address, instruction, AC, MQ and SI for every instruction executed. SET CPU HISTORY=n plus SHOW CPU HISTORY gives the same records from a ring buffer. That trace is the one genuinely useful embedding surface here.

### battleTested

Weaker than the SimH reputation suggests, and I had to correct two attributions to get there.

Direct evidence, from the source itself. The i7094_defs.h header (copyright 2003-2011, Robert M Supnik) states: "This simulator incorporates prior work by Paul Pierce, Dave Pitts, and Rob Storey. Tom Van Vleck, Stan Dunten, Jerry Saltzer, and other CTSS veterans helped to reconstruct the CTSS hardware RPQ's. Dave Pitts gets special thanks for patiently coaching me through IBSYS debug." That is the author's own claim that IBSYS was debugged against this simulator, and that CTSS veterans reconstructed the RPQ hardware it models.

Supporting evidence. i7094_bug_history.txt lists 67 numbered defects "Found and Fixed During Simulator Debug", many of which only surface when a real operating system is running: "11. IO: Channel output process model incorrect, extensive revision required.", "63. IO: 7607 channel modeled incorrectly, could stall.", "56. CPU: Read/write protection error not setting protection trap.", "59. CPU: Stop message reporting physical, not virtual, PC." A file like that is the fingerprint of a long system-level shakedown, not a paper design.

Two attributions that do NOT belong to this candidate. The frequently cited Dusty Decks post "IBSYS Fortran II runs on a SIMH-based simulator" (mcjones.org, 2006) is about Rich Cornwell's separate 704/709/7090/7094 simulator — the page names "Rich Cornwell" and says his simulator was "aimed more toward IBSYS and older 704/709 software". Dave Pitts's own page (cozx.com/dpitts/ibm7090.html) says "This version run all IBSYS jobs, including FORTRAN II. Lisp and CTSS are supported under this version" — but about his own s709 simulator, and "The IBSYS nucleus has been assembled with this version and run under the s709 simulator". Neither statement is evidence about SimH I7094.

No test suite. The I7094 directory in simh/simh contains fifteen source files and no tests subdirectory; open-simh/simh adds only a CMakeLists.txt. The simh makefile's test hook looks for "$(wildcard $(PRIMARY_SRC)/tests/$(1)_test.ini)" and finds nothing, so building i7094 runs only the generic RegisterSanityCheck. There is no diagnostic-tape harness and no regression corpus I could find.

### maintenance

Two live forks, neither archived, and the 7090/7094 model itself frozen since 2011.

simh/simh (Mark Pizzolato's line, the URL given): repository pushed 2026-08-31; 1,878 stars. Fifty-three commits in the project's whole history touch I7094/. The most recent to touch the directory is 2026-05-13, "I1401, I7094, ID16, ID32, ND100, PDP10, SAGE, VAX780, SCP: Declaration Hygiene". i7094_cpu.c itself last changed 2023-12-04, "ALL simulators with instruction history support: Minor history enhancements".

open-simh/simh (the community fork; opensimh.org hosts the current published doc): repository pushed 2026-07-03. I7094 last touched 2023-05-18, "CMake build infrastructure II (#53)", which added the I7094/CMakeLists.txt that simh/simh does not have.

Every commit to i7094_cpu.c after 2013 that I could see is housekeeping, not modelling: "I7094: Compiler warning cleanup" (2020-10-19), "I1401, I7094, ID16, ID32, NOVA, SDS, SIGMA: CONST compatibility with 3.10" (2018-03-09), "H316, I7094, NOVA, PDP1, PDP10, PDP8, SDS: Coverity singleton errors" (2017-09-07), "ALL: Massive 'const' cleanup" (2016-05-15). The header's own change log ends at "25-Mar-11 RMS Updated SDC mask based on 7230 documentation", and Supnik's copyright line reads "Copyright (c) 2003-2011, Robert M Supnik". Read that as stability, not abandonment: the machine has not changed since 1964, and nobody has found a CPU bug worth a commit in fifteen years. But nobody is actively improving 7090 fidelity either.

### license

Two layers, and the I7094 module lands on the safe side of the awkward one.

The module itself is plain MIT with Supnik's no-advertising clause. Verbatim from the top of i7094_defs.h (and every I7094 source file): "Copyright (c) 2003-2011, Robert M Supnik / Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: / The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. / THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND ... / Except as contained in this notice, the name of Robert M Supnik shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from Robert M Supnik."

The repository LICENSE.txt (Copyright (c) 1993-2022, Robert M Supnik, Mark Pizzolato and others) adds a restriction on top: "Any use of this codebase that changes the code to influence the behavior of the disk access activities provided by sim_disk.c and scp.c is free to do that as long as anyone doing this is explicitly not licensed to any subsequent changes to any part of the codebase in the master branch of the git repository ... made by Mark Pizzolato after the LICENSE.txt was added". It then classifies users, and we fall in the second group: "Group 2: Any person using a simulator that has no devices which use sim_disk and that doesn't modify scp.c is licensed to use all of \"Mark Pizzolato's future changes\"." I verified the premise — grep for sim_disk across every I7094 .c and .h file returns nothing; only i7094_mt.c uses sim_tape. i7094_dsk.c models the 1301/1302/2302 with its own file I/O, not sim_disk.

So: vendoring the tree and FFI-linking it are both permitted outright. The catch is that embedding is precisely what would make us modify scp.c, which drops us out of Group 2's safe harbour for Pizzolato's future commits (it does not revoke the license to code we already hold, and a subprocess approach touches nothing). One more caveat from the same file: "there exist some binary files in the repository which may not have formal copyright releases from the original copyright holders and therefore those are certainly not granted a license by this LICENSE.txt file" — vendor sources only.

### buildCost

A whole second toolchain, added to a CI that today runs three Dart commands.

The makefile target (simh makefile:2228-2233, 2941-2944) is: "I7094 = ${I7094D}/i7094_cpu.c ${I7094D}/i7094_cpu1.c ${I7094D}/i7094_io.c ${I7094D}/i7094_cd.c ${I7094D}/i7094_clk.c ${I7094D}/i7094_com.c ${I7094D}/i7094_drm.c ${I7094D}/i7094_dsk.c ${I7094D}/i7094_sys.c ${I7094D}/i7094_lp.c ${I7094D}/i7094_mt.c ${I7094D}/i7094_binloader.c" with "I7094_OPT = -DUSE_INT64 -I ${I7094D}", built by "make i7094". Those twelve files link against the SCP common set (makefile:1772): "scp.c sim_console.c sim_fio.c sim_timer.c sim_sock.c sim_tmxr.c sim_ether.c sim_tape.c sim_disk.c sim_serial.c sim_video.c sim_imd.c sim_card.c". Roughly 440KB of I7094 C plus the SCP core — you cannot take the CPU alone; i7094_cpu.c calls ch_set_map and chtr_eval on entry to sim_instr, so the channel model comes with it.

What a job would have to add. A C compiler on both runners. GNU make version 4 or later — the makefile explicitly rejects the macOS system make: "*** You can't build with separate compiles using version $(GNUMakeVERSION) *** of GNU make. A GNU make version 4 or later is required." So macOS needs "brew install make" and gmake. The README's dependency lines are for the whole package, not this target: macOS "brew install vde pcre libedit sdl2 libpng zlib sdl2_ttf make"; Linux "apt-get install gcc libpcap-dev libvdeplug-dev libpcre3-dev libedit-dev libsdl2-dev libpng-dev libsdl2-ttf-dev". I did not build it, so I cannot tell you the minimal subset — but sim_ether.c and sim_video.c are unconditionally in the common source list, which is why those libraries appear. Plus a vendored tree or submodule, a build-cache strategy, and a macOS+Linux matrix.

The cheaper route, if this is ever built: open-simh/simh ships I7094/CMakeLists.txt (added 2023-05-18), which is a far better fit for cross-platform CI than a 3,427-line GNU makefile. Set TESTS=0 either way; there is no i7094 test script to run.

### dartInterop

Two real mechanisms. One is easy and coarse; the other is a C project in disguise.

Subprocess, driven through the SCP console. This is the practical one. Build BIN/i7094, spawn it from Dart with Process.start, and write line-oriented commands to its stdin: SET CPU 7090, DEPOSIT <addr> <octal>, BREAK <addr>, RUN, EXAMINE AC, EXAMINE 0-100, CONTINUE. Everything comes back as console text that Dart parses. For our purpose the better variant is non-interactive: SET CPU DEBUG plus SET DEBUG <file> makes cpu_fprint_one_inst dump PC, effective address, instruction, AC, MQ and SI for every instruction executed to a file, so Dart can run a program once and diff the whole trace against our own core's trace. No FFI, no ABI, no memory management. It needs the binary present, so it lives outside CI or behind an opt-in flag.

dart:ffi. Possible, but nothing in the project supports it. The makefile builds an executable; there is no shared-library target and no -fPIC. main() is in scp.c. sim_instr is not a standalone function: it opens with ch_set_map and chtr_eval, calls sim_process_event through the interval counter, and depends on M having been allocated by cpu_reset ("if (M == NULL) M = (t_uint64 *) calloc (MAXMEMSIZE, sizeof (t_uint64));"). To use it from Dart you would compile the whole tree with -fPIC into a .dylib and .so, write a C shim that performs SCP's device-reset and event-queue initialisation, expose sim_instr, cpu_ex and cpu_dep plus the globals M, AC, MQ, PC and XR, and reimplement SCP's continue path so an E-breakpoint stop can be resumed. That is not "call a C function from Dart" — it is maintaining a fork of an SCP embedding, in a repository that currently contains no C at all.

Neither mechanism gives us what D0.3 actually needs: a hook that fires before the CPU enters a runtime entry address, hands machine state to a Dart handler, and resumes. The nearest thing SimH offers is a breakpoint that halts the entire simulator back to a console prompt, after which the host has to re-arm and continue by hand. Every SYS)/IOC) call in a compiled program would be a full stop-inspect-poke-continue round trip across a process boundary.

### runtimeGap

No. Nothing here closes it, and nothing here was ever meant to.

SimH has never heard of SYS) or IOC). It supplies the opposite of what decision D0.7 asks for: a complete hardware channel and device model — 7607 and 7909 channels in i7094_io.c (1,901 lines), 729 tapes, 711/721 card equipment, 716 printer, 1301/1302/2302 disk, 7320 drum, 7750 terminal concentrator, Chronolog clock. That is the layer we deliberately do not emulate, because our generated code contains no RDS, no WRS and no channel opcode at all. Taking SimH means taking that entire I/O model as dead weight, since sim_instr cannot be separated from it.

It does not even help us load our own output. i7094_binloader.c reads Dave Pitts's asm7090/lnk7090 object-card format — "#define IBSYSSYM '$' /* Marks end of object file */", "#define IDT_TAG '0'", "#define ABSENTRY_TAG '1'", through "#define RELBOTH_TAG 'C'" — not the 1962 [J 90.03] deck format. i7094_sys.c's sim_load dispatches to that binloader and returns SCPE_NOFNC for anything else. Our own CT Loader implementation stays exactly as necessary as it is today.

What SimH does supply, and it is not nothing: an independently written, thoroughly debugged reference implementation of the 7090 instruction set with a correct 7090/7094 model split, a per-instruction state trace, and 67 documented bugs someone else already found. That is oracle material, not runtime material.

### verdict

It cannot replace our CPU core, and it is worth keeping as an out-of-CI test oracle — a good one for the instruction set, useless for everything downstream of it. The replacement case fails on three independent grounds, any one of which is fatal: it is 440KB of C in a pure-Dart repository whose CI has no compiler, GNU make 4, or native build step; sim_instr is welded to the channel and device model that D0.7 says we explicitly do not want, and cannot be lifted out of it; and its only control-interception mechanism is an SCP breakpoint that halts the whole simulator back to a console prompt, which is the wrong shape for a runtime-entry hook that must fire on every SYS)/IOC) call. Set against that, we already have 889 lines of Dart covering exactly the 43 opcodes our compiler emits, with 1,600 lines of tests and a design record citing A22-6528-4 page by page — and the remaining M4 stage 4 work is the dispatch layer and the Dart runtime handlers, none of which SimH provides. The oracle case is genuinely attractive: SET CPU 7090 is a real, enforced model (17 opcodes including DFAD, DFSB and DFMP are rejected as illegal, and multi-tag index OR-ing is forced on), and SET CPU DEBUG dumps PC, effective address, instruction, AC, MQ and SI per instruction, so a Dart harness could run the same program on both and diff the traces instruction by instruction. That is real, independent validation of our 43 opcodes, obtained without trusting anybody's README. The cost is honest and bounded: a vendored tree, a locally built binary, and a test file that skips when the binary is absent. My recommendation is to take it only in that form, and only if differential validation of the instruction set is worth a manual build step to you — not as a dependency, not in CI, and never on the critical path.

### uncertainties

I did not build it. Everything about the build is read off the makefile and README, so the minimal dependency set for the i7094 target alone is unverified — I know sim_ether.c and sim_video.c are in the common source list, which is why libpcap and SDL2 appear in the README's install lines, but I cannot tell you whether the i7094 link actually needs them.

The IBSYS claim rests on the author's own word. "Dave Pitts gets special thanks for patiently coaching me through IBSYS debug" is Supnik writing about his own simulator in his own header. I looked for third-party confirmation and found none: the two obvious candidates both turned out to be about different simulators (Rich Cornwell's, and Dave Pitts's s709). I did not confirm that SimH I7094 boots IBSYS or CTSS from a surviving tape. It is plausible given the CTSS RPQ reconstruction credits and the 67-item bug history, but I have no primary source for it.

I read i7094_cpu.c, i7094_defs.h, the sim_load path in i7094_sys.c, the binloader constants, the makefile target and the license files. I did not audit i7094_io.c (1,901 lines) or any device module for fidelity, and I read i7094_cpu1.c only by name — the arithmetic helpers op_add, op_mpy, op_div, op_fad, op_fmp, op_fdv and the double-precision routines live there and I did not check them against A22-6528-4.

The published documentation is stale in at least one place. opensimh.org/simdocs/i7094_doc.html (dated 01-Dec-2008) says "The LOAD command is not implemented", but master's i7094_sys.c does dispatch LOAD to the binloader. I did not reconcile which statement is current for each fork. The same doc describes no BREAK, EXAMINE or DEPOSIT commands, but those are generic SCP facilities and the CPU source plainly wires them up, so I trusted the source over the doc.

I could not check whether either fork carries an I7094 regression corpus outside the module directory. Absence of I7094/tests/ in both is what I verified; I did not search the whole repository for a 7094 diagnostic script.


## SimH I7000 family — i7090_cpu.c (Richard Cornwell)

`https://github.com/simh/simh/tree/master/I7000 (upstream: https://github.com/rcornwell/sims/tree/master/I7000)`

### sevenOhNineZero

Yes — a genuine, separately-modelled 7090, and it is the best-differentiated 7090 of any candidate I could check. `i7090_cpu.c:178-181` declares four models: `#define CPU_704 0`, `#define CPU_709 1`, `#define CPU_7090 2`, `#define CPU_7094 3`, selected by `SET CPU 7090` (`cpu_mod[]`, line 365: `{UNIT_MODEL, MODEL(CPU_7090), "7090", "7090", NULL, NULL, NULL}`). The model is not just a clock speed. Four decode paths branch on it, and one is 7090-only: line 2166-2167, `/* 7090 checks MQ for zero before multipling */` then `if (CPU_MODEL == CPU_7090 && (MQ & PMASK) == 0) {`. Others: `if (CPU_MODEL < CPU_7090)` on the divide-check MQ sign path (line 1951), `if (CPU_MODEL == CPU_709) ihold = 1; else ihold = 2;` on the trap-hold (line 1324), and `if (CPU_MODEL >= CPU_7090) break;` on an I/O-wait path (line 3334). Index-register width is handled by multi-tag mode, which resets to the 7090 behaviour: `MTM = 1` at line 4172, and the tag macro at line 657 reads `(((t)) ? ((MTM) ? (XR[(t)&04] | XR[(t)&02] | XR[(t)&01]) : XR[(t)]) : 0)` — the OR of index registers 1, 2 and 4, which is what a real 3-index-register 7090 does. TWO CAVEATS, both real. First, 7094-only opcodes are SILENTLY SKIPPED rather than trapped. Line 1099-1103: `/* If proc does not support this opcode, just skip it */` ... `if (opinfo & I_94 && CPU_MODEL != CPU_7094) break;`. A 7094 instruction on the 7090 model is a no-op with no diagnostic. Our Dart core throws a typed exception naming the octal opcode; this is strictly weaker. Second, LMTM is not gated to the 7094 at all — line 1330-1332: `case OP_LMTM: if (CPU_MODEL != CPU_704) MTM = 0;`. A real 7090 has no LMTM; here the 7090 model will honour it, drop to single-tag mode and expose XR[3,5,6,7]. So the "7090" is a shared 7094 core with a model flag gating a handful of opcodes and four behaviour branches, not an independently-built 7090.

### embeddable

There is a real embeddable control API, but it is out-of-process, and it has no breakpoint callback. Two layers. (1) Inside the CPU loop, the breakpoint test fires BEFORE the instruction at IC is fetched — `i7090_cpu.c:803-806`: `if (iowait == 0 && sim_brk_summ && sim_brk_test(((bcore & 2)? CORE_B:0)|IC, SWMASK('E'))) { reason = STOP_IBKPT; break; }`. That satisfies "intercept control BEFORE the CPU enters a runtime entry address" exactly. But it returns out of `sim_instr()` to the SCP command loop; it does not call a host function. (2) On top of that sits `sim_frontpanel.h` (647 lines, API version 15), which is a documented C library for an external program to drive a simulator. The actual functions: `sim_panel_start_simulator(sim_path, sim_config, device_panel_count)`, `sim_panel_break_set(panel, condition)` / `sim_panel_break_clear`, `sim_panel_exec_run` / `_halt` / `_step` / `_start` / `_boot`, `sim_panel_gen_examine` / `sim_panel_gen_deposit`, `sim_panel_mem_examine` / `sim_panel_mem_deposit` / `sim_panel_mem_deposit_instruction`, `sim_panel_set_register_value`, `sim_panel_get_registers`, `sim_panel_get_state` and `sim_panel_halt_text`. Registers are addressable by name — `cpu_reg[]` at `i7090_cpu.c:305-309` declares `IC`, `IR`, `AC`, `MQ`, then `XR` as an 8-element array, plus `MTM`, `TM`, `STM`, `CTM`, `FTM`, `SL`, `SW`, `KEYS`. So depositing IC with a return address and resuming is available. THE GAP: there is no hit-callback. `sim_frontpanel.h` offers only `OperationalState sim_panel_get_state(PANEL *panel)` returning `Halt`/`Run`/`Error`, and `sim_panel_halt_text()` for the text printed at the stop. Every runtime-entry trap becomes: set breakpoint, exec_run, POLL get_state until Halt, parse halt_text to learn which breakpoint, examine registers/memory, deposit IC, exec_run again. The only callback in the header is `PANEL_DISPLAY_PCALLBACK`, a periodic display refresh, not a breakpoint event. AND it is out-of-process: `sim_frontpanel.c:912` calls `CreateProcessA` on Windows, line 922 `p->pidProcess = fork();` on POSIX, then talks to the simulator over the SCP remote console (`SET REMOTE`, implemented in `sim_console.c` — `sim_set_remote_console`, `sim_rem_con_poll_svc`, the `REM-CON` device). So even the C API is subprocess-plus-socket. In-process embedding is not offered: `scp.h:365` declares `extern t_stat sim_instr (void);` — no arguments, all state in file-scope globals, and `scp.c` owns `main()` and the console.

### battleTested

This is the strongest validation of any 7090 simulator I have evidence for, and it is a real automated regression suite, not a README claim — but the suite lives in Cornwell's own repo, NOT in the `simh/simh/I7000` tree I was pointed at. `rcornwell/sims/I7000/tests/` holds `i7090_test.ini` (2651 bytes) and a directory `tests/i7090/` with 51 files: genuine IBM 709/7090 customer-engineering diagnostic decks — `9m01b.dck`, `9m02a.dck`, `9m03a.dck`, `9m04a.dck`, `9m05b.dck`, `9m21a.dck`, `9sy1a.dck` (57 KB), `9efpa.dck`, `9esla.dck`, `9comb.dck`, `9c01a.dck`, `9c02a.dck`, `9r01a.dck`, `9b01a.dck`, `9p01c.dck`, `9p02a.dck`, `9t01a`–`9t05a`, `9d01a.dck`, `9iota.dck`, `xcomc.dck` and more — plus a checked-in expected console log `good.test.bin` (89361 bytes). The script logs the whole console to `test.log`, boots each deck from the card reader, and ends `if -F "test.log" == "good.test.bin" delete test.log ; exit 0` / `exit 1`. That is a byte-comparison regression gate over ~25 diagnostic decks. Read it honestly, though. `good.test.bin` pins KNOWN FAILURES as expected output, it does not assert the diagnostics pass: the script contains `echo expect "TEST LOC 03610, OPN EAD "` before 9efpa, `echo "expect errors here"` before 9iota, three expected failures before 9d01a (`OPN LDA`, `OPN IOT`, `OPN CPY`), and `9t05a` is commented out entirely. Cornwell's own `I7000/STATUS.txt` and the repo README list the surviving bugs: "DFDP/DFMP Sometimes off by +/-1 or 2 in least signifigant part of result.", "EAD +n + -n should be -0 is +0", "Not all channel skips working for 9P01C.", "HTx Not sure what problems are, does not quite work.", "DKx Sometimes fails diagnostics with missing inhibit of interupt." The headline claim is "i7090: Working with exceptions." Beyond diagnostics, the README asserts real system software runs: "CTSS works.", "IBSYS works.", "Stand alone assembler works.", "Lisp 1.5 works." Commit messages corroborate the work: "I7000: Updates to pass 9IOTA diagnostics." (2018-07-10), "I7000: Fixes to allow IBM 704 Fortran II to work." (2018-05-21), "I7000: Fixed channel issues to allow I7090 to run Stress." (2023-11-27). ONE MATERIAL CAVEAT FOR US: `i7090_test.ini` line 5 reads `set cpu 709` — the entire diagnostic regression runs in 709 mode. The four 7090-specific branches I quoted above, including the 7090-only multiply-MQ-zero check at line 2167, are exactly the paths the suite never exercises.

### maintenance

The project is alive; the 7090 sources specifically are dormant for about two years. Three trees, and they must be kept apart. UPSTREAM is `rcornwell/sims` — GitHub API reports it pushed 2026-03-08, 114 stars, not archived; but `I7000/i7090_cpu.c` last changed 2024-03-12 ("I7000: Minor fixes.") and the whole `I7000/` directory last changed 2024-05-11 ("I7000: Updated 7010, 7070, 7080 for EOF handling."). Recent repo activity is in his other simulators (IBM 360, PDP10, SEL32, B5500). In `simh/simh` (the URL given), `I7000/i7090_cpu.c` last changed 2023-12-31 ("I7000: Group update for IBM 7000 series simulators.") and the `I7000/` directory 2024-05-22 ("I7000: Updated general card reader, printer and magtape"). In `open-simh/simh`, `I7000/` last changed 2024-05-21, the same Cornwell commit. Every substantive I7000 commit in both simh forks is authored by Richard Cornwell; Mark Pizzolato's commits there are cross-cutting SCP housekeeping (register definitions, tape record typing, writelock standardisation, instruction-history enhancements). Full i7090_cpu.c history in simh/simh is only 8 commits, from the 2017-12-28 "Initial release of a set of simulators for IBM 7000 series mainframes" to 2023-12-31. So: rcornwell/sims is the live fork and the one to vendor from; simh/simh and open-simh both carry downstream copies that Cornwell pushes to periodically. Cadence on the 7090 itself is roughly one commit a year and falling.

### license

MIT, permissive, vendoring and linking both permitted — with one attribution obligation and one unrelated clause to be aware of. `rcornwell/sims` has NO top-level LICENSE file (GitHub API returns `license: None`), so the operative grant is the per-file header. `I7000/i7090_cpu.c` lines 1-21, verbatim: "/* i7090_cpu.c: IBM 7090 CPU simulator" / "Copyright (c) 2005-2016, Richard Cornwell" / "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:" / "The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software." / "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED... IN NO EVENT SHALL RICHARD CORNWELL BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY..." That is plain MIT: vendoring the C into our repo and FFI-linking are both permitted, provided the copyright notice and permission notice travel with it. If we instead take the copy from `simh/simh`, that tree's `LICENSE.txt` applies on top: "Copyright (c) 1993-2022, Robert M Supnik, Mark Pizzolato and others", the same MIT grant, plus a no-endorsement clause ("the name of Robert M Supnik, Mark Pizzolato or anyone else shall not be used in advertising... without prior written authorization") and a conditional carve-out: "Any use of this codebase that changes the code to influence the behavior of the disk access activities provided by sim_disk.c and scp.c is free to do that as long as anyone doing this is explicitly not licensed to any subsequent changes to any part of the codebase in the master branch of the git repository... made by Mark Pizzolato". The file's own guidance puts us in "Group 2: Any person using a simulator that has no devices which use sim_disk and that doesn't modify scp.c is licensed to use all of 'Mark Pizzolato's future changes'." We would build no sim_disk device and change no scp.c AUTOSIZE behaviour, so the carve-out does not bite. No license blocker.

### buildCost

A whole C toolchain step that our CI does not currently have. The build itself is easy; the CI change is the cost. From `simh/makefile` line 2183-2188 the target is `make i7090`, compiling 14 C files — `i7090_cpu.c`, `i7090_sys.c`, `i7090_chan.c`, `i7090_cdr.c`, `i7090_cdp.c`, `i7090_lpr.c`, `i7090_drum.c`, `i7090_hdrum.c`, `i7000_chan.c`, `i7000_mt.c`, `i7000_chron.c`, `i7000_dsk.c`, `i7000_com.c`, `i7000_ht.c` — against the SimH core (`scp.c`, `sim_console.c`, `sim_tmxr.c`, `sim_sock.c`, `sim_timer.c`, `sim_fio.c`, `sim_tape.c`, `sim_card.c`, `sim_disk.c`, `sim_video.c` and friends). Flags: `I7090_OPT = -I $(I7000D) -DUSE_INT64 -DI7090 -DUSE_SIM_CARD`. Link needs `-lm` and pthreads (`OS_LDFLAGS = -lm` on Linux; `sim_frontpanel.h` states its consumers must "link the sim_frontpanel and sim_sock object modules and libpthreads into the application"). libpcap is dynamically loaded and only serves network devices, so it is not needed for i7090 — the makefile's `PKGS_SRC_APT = gcc libpcap-dev ...` list is for the full simulator set, not this one. Cornwell's fork also ships `CMakeLists.txt` (root and `I7000/`), added 2024-03-12 "SCP: Added support for CMAKE.", which is the cleaner path. Concretely our CI would gain, on both the macOS and Linux runners: a compiler (clang is already on macOS runners; `build-essential` on Linux), a `make i7090` or `cmake --build` step, the vendored C sources or a pinned submodule, and a place to cache or stage the resulting binary. Against a repository whose entire gate is `dart format --set-exit-if-changed`, `dart analyze --fatal-infos`, `dart test`, that is a new build system, a new failure surface, and a new set of platform-specific compiler-warning problems (the I7000 history is full of "Removed compiler warnings" / "Fixed coverity errors" commits, which means warnings do appear on new compilers).

### dartInterop

Subprocess plus a TCP socket. Not dart:ffi, and not in-process. The mechanism is real and documented, but it is the SimH remote console protocol, and the C `sim_frontpanel` library is just a client for it — `sim_frontpanel.c:922` does `p->pidProcess = fork();` (and `CreateProcessA` at line 912 on Windows), then connects to the simulator's `SET REMOTE` console implemented in `sim_console.c` (`sim_set_remote_console`, the `REM-CON` device, `sim_rem_con_poll_svc`, `sim_rem_con_data_svc`). So Dart does not need FFI at all: `Process.start('i7090', ['config.ini'])` plus a `dart:io` `Socket` speaking the same line-oriented command protocol — `BREAK <addr>`, `CONT`, `EXAMINE`, `DEPOSIT IC <value>`, `STEP` — gets everything `sim_frontpanel` gets, with no C client to build or bind. dart:ffi over `sim_frontpanel.c` is possible but strictly worse: it adds a C shared-library build, and it still forks the same subprocess underneath, so it buys nothing. TRUE in-process FFI against the CPU core is NOT viable without surgery: `scp.h:365` declares `extern t_stat sim_instr (void);` — it takes no arguments, reads and writes file-scope globals (`AC`, `MQ`, `IC`, `XR[8]`, `M[]`), and `scp.c` owns `main()`, the command parser, the console and the event queue. You would be forking the codebase to extract a callable core, which is a much larger job than finishing our own dispatch layer. THE PERFORMANCE CONSEQUENCE IS THE REAL PROBLEM FOR US. Our design needs to trap at every SYS)/IOC) runtime entry, hand machine state to a Dart handler, and resume. On this architecture that is: set the breakpoint, `CONT`, poll `sim_panel_get_state()` until it returns `Halt`, parse `sim_panel_halt_text()` to work out which entry was hit, issue N examine commands to read registers and memory, issue M deposit commands to write results, deposit IC with the return address, `CONT` again. One process boundary and several socket round-trips per runtime call, with polling rather than an event. A payroll program calling the runtime a few hundred thousand times turns into a few hundred thousand round-trips. Functionally correct, operationally awful, and it makes the runtime handlers — which is the actual remaining work — harder to write and far harder to test than they are today against an in-process Dart CPU.

### runtimeGap

No. It supplies nothing that closes the lost SYS)/IOC) runtime gap, and it could not — that gap is COMTRAN-specific and this simulator has never heard of COMTRAN. Nothing in the 14 C files, the 51 diagnostic decks, or the documentation contains a COMTRAN runtime library, its entry-point addresses, its calling sequences, or its register conventions. Those exist only in J28-6169 Appendix 90.02 and the surrounding sections, and the Dart handlers this project is about to write are the only reconstruction of them anywhere. Worse for the fit: what it supplies INSTEAD is largely the layer decision D0.7 deliberately rejected. `i7090_chan.c` is 68 KB of channel-level I/O — data channels A through H, channel command decoding, EOF and parity and redundancy checks — plus device models for card reader, card punch, printer, drum, high-speed drum, tape, disk, hypertape and a communications adapter. Our generated code emits no RDS, no WRS and no channel opcode at all, so every one of those bytes is inert weight for us, and the elaborate channel machinery is precisely the thing our IOCS-level model exists to avoid simulating. What it genuinely supplies that we could use: a second, independently-written, diagnostic-validated 36-bit 7090 CPU implementation, and a corpus of 51 real IBM 709/7090 customer-engineering diagnostic decks. Those decks are the asset. They are the strongest external check available on our own arithmetic, indexing, indirect addressing and trap logic — and they are usable without adopting a single line of the C, by reading a deck, running it on our own core, and comparing behaviour.

### verdict

Test oracle only, and a bounded one — not a replacement for our CPU core, and no help at all with the actual remaining work. Adopting it would mean giving up an in-process, word-exact, 43-opcode Dart core that is already written, already covered by ~1600 lines of green tests, and already fails LOUDLY on anything outside its harvested subset, and taking in exchange a C simulator that must be driven over a socket to a forked subprocess with no breakpoint callback, that SILENTLY NO-OPS unrecognised opcodes on the 7090 model (`i7090_cpu.c:1099-1103`), and that drags in 68 KB of channel-level I/O that decision D0.7 exists to avoid. It would add a C toolchain to a pure-Dart CI, turn every runtime-entry trap into a polled socket round-trip, and make the SYS)/IOC) handlers — the one piece of M4 stage 4 that is genuinely hard and genuinely COMTRAN-specific — harder to write and much harder to test. That is a large, permanent cost paid to replace the part of the problem that is already solved. What is worth taking is the evidence, not the code. Two things specifically. First, the 51 diagnostic decks in `rcornwell/sims/I7000/tests/i7090/` are real IBM customer-engineering diagnostics and the best external validation available for our own core's arithmetic, indexing and trap behaviour; we can read them and run them against our Dart CPU without adopting any C. Second, `i7090_cpu.c` is worth reading as a second opinion whenever A22-6528-4 is ambiguous — the 7090-only multiply check at line 2166-2167 (`/* 7090 checks MQ for zero before multipling */`) is exactly the kind of edge our design record would want a second source on. Use it as a reference implementation and a source of test vectors. Do not link it, do not vendor it, and do not let it into CI.

### uncertainties

Six things I could not confirm, stated plainly. (1) I DID NOT BUILD IT. I read sources fetched with curl from raw.githubusercontent.com; I never ran `make i7090` on macOS or Linux, so the build-cost estimate is read off `simh/makefile` lines 2183-2188 and the compiler-warning history, not measured. (2) I DID NOT RUN THE DIAGNOSTICS. I read `i7090_test.ini` and listed `tests/i7090/`; I did not execute a single deck, and I did not open `good.test.bin` to see what it actually pins. My claim that the suite pins known failures rests on the `echo expect ...` lines in the script and the bug list in STATUS.txt, which is strong but indirect. (3) I could not verify the claims that CTSS, IBSYS, Lisp 1.5 and the standalone assembler run — those come from `rcornwell/sims/README.md` and `I7000/STATUS.txt`, which are author claims. They are corroborated by commit messages and by the CTSS-specific machinery I did see in the code (`UNIT_DUALCORE`, `SET CPU CTSS`, B-core handling, the protection trap at `prottrap:`), so I believe them, but I did not boot a tape. (4) I did not exhaustively audit the 7090-versus-7094 gating. I found four model branches and one ungated 7094 instruction (LMTM at line 1330); I did not read all 4460 lines, so there may be further 7094-isms reachable in 7090 mode, or further 7090 behaviours correctly modelled that I missed. (5) I did not test the `sim_frontpanel` path end to end against the i7090 binary. `sim_frontpanel.h` is generic SCP-level and the i7090 inherits `SET REMOTE` from `sim_console.c`, so it should work, but "should" is doing real work in that sentence — and `sim_frontpanel.h` warns "The simulator binary must be built from the same version simh source code that the frontpanel API was acquired from", which I could not check. (6) I did not verify the remote-console wire protocol in enough detail to promise a hand-written Dart client is straightforward. I confirmed the transport (fork plus socket) and the device (`REM-CON`); I did not read the framing, the prompt handling, or the `SET REMOTE MASTER` semantics that a Dart client would have to get right. Also worth stating: the task named `simh/simh/I7000` as the candidate, but the diagnostic test suite that carries almost all the validation weight is NOT in that tree — it exists only in `rcornwell/sims`. Any decision to harvest the decks must point at the upstream repository.
