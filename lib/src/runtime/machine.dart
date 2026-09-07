/// The machine assembly (M4-17; `docs/design/runtime.md` RT-1): the CPU
/// core, one loaded object program, the run's file table, and the
/// SYS)/IOC) dispatch table over all three.
///
/// The runtime library is not object code here. Every entry is a Dart
/// handler at the address the loader resolved its reference to (D0.3),
/// so the dispatcher decides before each instruction: an address below
/// [Machine.programOrigin] is a runtime entry, and every address above
/// it is the program's own text.
library;

import 'dart:io';

import '../cards/card_image.dart';
import '../codegen/encode.dart';
import '../emulator/cpu.dart';
import '../emulator/machine_state.dart';
import '../emulator/word.dart';
import '../loader/loader.dart';
import 'monitor.dart';
import 'movpak.dart';

/// How a run ended.
enum RunOutcome {
  /// `TXI IOC)40,0` reached the monitor's end-of-job return point
  /// ([J 90.02.09]).
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
  /// number ranges ([J 90.02.07]).
  String get name => number > 127 ? 'SYS)$number' : 'IOC)$number';

  @override
  String toString() => detail == null
      ? 'unimplemented runtime entry $name'
      : 'unimplemented runtime entry $name: $detail';
}

/// A tape image an input file needs and the host directory does not
/// hold. The fault is the environment's and not the program's, so no
/// [J 90.04] diagnostic covers it (M5-3).
final class MissingTapeImage implements Exception {
  MissingTapeImage(this.file, this.path);

  /// The name on the `*FILE` card.
  final String file;

  /// Where the machine looked.
  final String path;

  @override
  String toString() => 'no tape image for input file $file at $path';
}

/// One file of the run's file table: the control block open-all and
/// close-all keep for one `*FILE` card (M5-3).
final class RuntimeFile {
  RuntimeFile(this.host);

  /// The host tape image, or `null` when the run named no tape
  /// directory.
  final File? host;

  bool open = false;
}

/// A tape mark, the record length zero that ends a file (M5-2).
const List<int> _tapeMark = <int>[0, 0, 0, 0];

/// Whether [file] is an input file. Column 28 of the `*FILE` card holds
/// `I` for input, and `T` or `P` for output ([J 90.08.01]).
bool _input(LoaderFile file) => file.type == 'I';

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
  ///
  /// The file table takes one control block per `*FILE` card, and a
  /// file's host image is `<tapes>/<UNIT1>.tap`. With no [tapes]
  /// directory every file runs with no host image (M5-3).
  ///
  /// Cell 1 is IOC)1, and the machine seeds it because no word of the
  /// object deck writes it. The address field stays zero: the file list
  /// itself is Dart's, and no compiled word dereferences it (M5-3).
  Machine(this.program, {Directory? tapes})
    : files = <RuntimeFile>[
        for (final LoaderFile file in program.files)
          RuntimeFile(
            tapes == null ? null : File('${tapes.path}/${file.unit1}.tap'),
          ),
      ] {
    program.words.forEach(state.write);
    state
      ..write(1, pzeWord(decrement: program.files.length))
      ..ic = program.entry;
  }

  /// Loads [objectDeck] at [programOrigin], resolving every system
  /// reference to its own 15-bit code (RT-1).
  factory Machine.load(List<CardImage> objectDeck, {Directory? tapes}) =>
      Machine(
        loadDeck(
          objectDeck,
          resolve: (SystemReference reference) => reference.code,
          origin: programOrigin,
        ),
        tapes: tapes,
      );

  /// The first address above the runtime area. The 15-bit codes run 0
  /// to 4095: a system reference at its own number, a file reference at
  /// 2048 plus its ordinal ([J 90.03.05]).
  static const int programOrigin = 0x1000;

  final LoadedProgram program;
  final MachineState state = MachineState();

  /// The run's files, in `*FILE` card order, so file ordinal k is
  /// `files[k - 1]` (M5-3).
  final List<RuntimeFile> files;

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

  /// Opens the first [count] files of the table, which SYS)175 reads
  /// from IOC)1 (RT-2). An output file's host image is created or
  /// truncated, and an input file's host image must already exist.
  ///
  /// Throws [MissingTapeImage] for an input file the host directory
  /// does not hold.
  void openFiles(int count) {
    for (var i = 0; i < count; i++) {
      final LoaderFile declaration = program.files[i];
      final RuntimeFile file = files[i];
      final File? host = file.host;
      if (host != null) {
        if (_input(declaration)) {
          if (!host.existsSync()) {
            throw MissingTapeImage(declaration.name, host.path);
          }
        } else {
          host.writeAsBytesSync(const <int>[]);
        }
      }
      file.open = true;
    }
  }

  /// Closes the first [count] files, which SYS)177 reads from IOC)1
  /// (RT-2). Each open output file takes one tape mark. A file that is
  /// already closed closes quietly, because the sample's STOP RUN emits
  /// a second close-all after its own (M5-4).
  void closeFiles(int count) {
    for (var i = 0; i < count; i++) {
      final RuntimeFile file = files[i];
      if (!file.open) {
        continue;
      }
      final File? host = file.host;
      if (host != null && !_input(program.files[i])) {
        host.writeAsBytesSync(_tapeMark, mode: FileMode.append);
      }
      file.open = false;
    }
  }

  /// Prints one line on the on-line printer ([J 05.06.04]).
  void display(String line) {
    _display.add(line);
  }

  /// The on-line printer's lines so far.
  List<String> get printed => List.unmodifiable(_display);

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
      display: printed,
    );
  }
}
