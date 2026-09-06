/// The machine assembly (M4-17; `docs/design/runtime.md` RT-1): the CPU
/// core, one loaded object program, and the SYS)/IOC) dispatch table
/// under both.
///
/// The runtime library is not object code here. Every entry is a Dart
/// handler at the address the loader resolved its reference to (D0.3),
/// so the dispatcher decides before each instruction: an address below
/// [Machine.programOrigin] is a runtime entry, and every address above
/// it is the program's own text.
library;

import '../cards/card_image.dart';
import '../emulator/cpu.dart';
import '../emulator/machine_state.dart';
import '../emulator/word.dart';
import '../loader/loader.dart';
import 'monitor.dart';
import 'movpak.dart';

/// How a run ended.
enum RunOutcome {
  /// `TXI IOC)40,0` reached the monitor's end-of-job return point
  /// ([J 90.02.10]).
  endOfJob,

  /// A handler exited back to the CT Monitor ([J 90.02.33]).
  errorExit,

  /// The caller's step budget ran out. Non-termination is a designed
  /// outcome (D5.1 as amended), so the budget is the caller's and the
  /// run returns rather than throwing.
  stepLimit,
}

/// One runtime entry: the Dart handler that stands in for one SYS)/IOC)
/// routine (D0.3). It returns the outcome that ends the run, or `null`
/// to give control back to the program.
typedef RuntimeEntry = RunOutcome? Function();

/// A runtime entry the machine assembly does not implement.
final class UnimplementedRuntimeEntry implements Exception {
  UnimplementedRuntimeEntry(this.number, [this.detail]);

  /// The system reference number the entry resolved from.
  final int number;

  /// What the entry was asked to do, or `null` when nothing at all is
  /// registered at [number].
  final String? detail;

  /// `SYS)` above 127 and `IOC)` at or below it: the Type 2 and Type 1
  /// number ranges ([J 90.02.10]).
  String get name => number > 127 ? 'SYS)$number' : 'IOC)$number';

  @override
  String toString() => detail == null
      ? 'unimplemented runtime entry $name'
      : 'unimplemented runtime entry $name: $detail';
}

/// What one run produced.
final class RunResult {
  const RunResult({required this.outcome, required this.display});

  final RunOutcome outcome;

  /// The on-line printer's lines, in order ([J 05.06.04]).
  final List<String> display;
}

/// One loaded program and the machine that runs it.
final class Machine {
  /// Writes [program] into a fresh [MachineState] and enters at its
  /// entry point (D2.1). A cell no word was placed in reads +0 (ED-6).
  Machine(this.program) {
    program.words.forEach(state.write);
    state.ic = program.entry;
  }

  /// Loads [objectDeck] at [programOrigin], resolving every system
  /// reference to its own 15-bit code (RT-1).
  factory Machine.load(List<CardImage> objectDeck) => Machine(
    loadDeck(
      objectDeck,
      resolve: (SystemReference reference) => reference.code,
      origin: programOrigin,
    ),
  );

  /// The first address above the runtime area. The 15-bit codes run 0
  /// to 4095: a system reference at its own number, a file reference at
  /// 2048 plus its ordinal ([J 90.03.05]).
  static const int programOrigin = 0x1000;

  final LoadedProgram program;
  final MachineState state = MachineState();

  final List<String> _display = [];
  late final Cpu _cpu = Cpu(state);
  late final Map<int, RuntimeEntry> _handlers = {
    ...runFrame(this),
    ...movpak(this),
  };

  /// Parameter word [k] of the calling sequence in hand: the word at
  /// `k,4`, read as the CPU reads it (M4-17).
  int parameter(int k) =>
      state.read((k - state.xrRead(4)) & Word36.fieldMask15);

  /// Returns to `k,4`, where [k] is the parameter-word count plus one
  /// (M4-17).
  void resume(int k) {
    state.ic = (k - state.xrRead(4)) & Word36.fieldMask15;
  }

  /// Prints one line on the on-line printer ([J 05.06.04]).
  void display(String line) {
    _display.add(line);
  }

  /// Runs until a handler ends the job or [maxSteps] is reached. A
  /// runtime entry counts as one step, so a program that only calls
  /// handlers is bounded too.
  ///
  /// Throws [UnimplementedRuntimeEntry] when control reaches a runtime
  /// address with no handler, and every exception the CPU throws (§7 of
  /// `docs/design/emulator.md`).
  RunResult run({required int maxSteps}) {
    RunOutcome? outcome;
    var steps = 0;
    while (outcome == null && steps < maxSteps) {
      steps++;
      if (state.ic < programOrigin) {
        final RuntimeEntry? entry = _handlers[state.ic];
        if (entry == null) {
          throw UnimplementedRuntimeEntry(state.ic);
        }
        outcome = entry();
      } else {
        _cpu.step();
      }
    }
    return RunResult(
      outcome: outcome ?? RunOutcome.stepLimit,
      display: List.unmodifiable(_display),
    );
  }
}
