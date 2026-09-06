/// The compiler driver. It splits the deck into jobs (D11.1), runs the
/// front end — card reader, scanners, statement numbering — the M2
/// parser, and the M3 semantic layer once per job, and prints one
/// compilation listing per job with the merged diagnostic block
/// (roadmap M1–M3, `docs/HANDOVER.md`; design notes M2-1, M2-15, and
/// M3-2).
library;

import 'dart:io';

import 'package:comtran/comtran.dart';

const String _usage = r'''
Usage: dart run comtran:comtranc <deck.ctd> [options]

  Compiles every job on the deck ($CMPLE ... *FINISH) and prints one
  compilation listing per job.
  (M1-M3 stage 2: front end, parser, data mapper, dictionary, name
  resolution, and the semantic checks — no code generation yet.)

  --date=mm/dd/yy    page-head date (default: today)
  --time=h.hh        page-head time, decimal hours (default: now)
  --account=TEXT     page-head ACCOUNT field (default: blank)
  --title=TEXT       title line above page 1 (default: none)
  --lines-per-page=N content lines per page (default: 55)
  --pedantic         add non-historical written-language-strictness
                      diagnostics (D0.8); changes no parse result or
                      generated value
  --no-table-limits  lift the 1962 internal-table capacity limits
                      (non-historical; D9.7)
  --explain          after compiling, print each job's diagnostics to
                      stderr, one per line; the listing on stdout is
                      unchanged
  --run              load each job's object deck and run it, printing
                      the object program's display lines after its
                      listing (D0.3)
  --emit-cards[=PATH]
                      write the whole deck's card images, in the .ct
                      mirror form (D0.5)
  --emit-scan[=PATH]  write the front end's dump
  --emit-parse[=PATH]
                      write the parse tree's dump
  --emit-semantics[=PATH]
                      write the semantic layer's dump
  --emit-listing[=PATH]
                      write the listing; stdout is unchanged
  --emit-code[=PATH]
                      write the assembly text model's dump
  --emit-object[=PATH]
                      write the printed object listing, loader-card
                      page and closing lines included
  --emit-deck[=PATH]
                      write the object deck, punch level, in the canon
                      container (J 90.03; D0.5)
  --emit-loader[=PATH]
                      write the loader symbolic control cards as text
  -A, --emit-all      write every stage dump
  -c -s -p -S -l -g -o -d -L
                      the short emit flags, one letter per stage above,
                      bundleable: -cpsSlgodL is the full set. A dump without
                      PATH lands next to the deck, the deck's extension
                      replaced by the stage name: `payroll.ctd -p`
                      writes `payroll.parse`.
  --version          print the version and exit
''';

/// The `--run` step budget: instructions and runtime entries together.
/// A program still running here is looping, which is a reproduced
/// result and not a diagnostic (D5.1 as amended;
/// `docs/design/runtime.md` RT-1).
const int _stepBudget = 1000000;

/// The stage names `--emit-<stage>[=<path>]` accepts
/// (`docs/design/emit-stages.md`).
const List<String> _emitStages = [
  'cards',
  'scan',
  'parse',
  'semantics',
  'listing',
  'code',
  'object',
  'deck',
  'loader',
];

/// The one-letter emit flags. A short flag always takes the default
/// path; a custom path needs the long form.
const Map<String, String> _emitLetters = {
  'c': 'cards',
  's': 'scan',
  'p': 'parse',
  'S': 'semantics',
  'l': 'listing',
  'g': 'code',
  'o': 'object',
  'd': 'deck',
  'L': 'loader',
};

void main(List<String> arguments) {
  // Dart discards main's return value; the exit status must be set
  // explicitly.
  exitCode = _run(arguments);
}

int _run(List<String> arguments) {
  if (arguments.contains('--version')) {
    stdout.writeln('comtranc $comtranVersion');
    return 0;
  }
  String? deckPath;
  String? date;
  String? time;
  var account = '';
  var title = '';
  var linesPerPage = 55;
  var pedantic = false;
  var tableLimits = true;
  var explain = false;
  var run = false;
  // A null path means the default, resolved once the deck path is
  // known.
  final emitPaths = <String, String?>{};
  for (final argument in arguments) {
    if (argument.startsWith('--date=')) {
      date = argument.substring(7);
    } else if (argument.startsWith('--time=')) {
      time = argument.substring(7);
    } else if (argument.startsWith('--account=')) {
      account = argument.substring(10);
    } else if (argument.startsWith('--title=')) {
      title = argument.substring(8);
    } else if (argument.startsWith('--lines-per-page=')) {
      final int? value = int.tryParse(argument.substring(17));
      if (value == null || value < 1) {
        stderr.write(_usage);
        return 2;
      }
      linesPerPage = value;
    } else if (argument == '--pedantic') {
      pedantic = true;
    } else if (argument == '--no-table-limits') {
      tableLimits = false;
    } else if (argument == '--explain') {
      explain = true;
    } else if (argument == '--run') {
      run = true;
    } else if (argument == '--emit-all') {
      for (final String stage in _emitStages) {
        emitPaths[stage] = null;
      }
    } else if (argument.startsWith('--emit-')) {
      final int equals = argument.indexOf('=');
      final String stage = equals < 0
          ? argument.substring(7)
          : argument.substring(7, equals);
      final String? path = equals < 0 ? null : argument.substring(equals + 1);
      // An unknown stage and an explicit empty path are the same usage
      // error; no `=` at all means the default path.
      if (!_emitStages.contains(stage) || (path != null && path.isEmpty)) {
        stderr.write(_usage);
        return 2;
      }
      emitPaths[stage] = path;
    } else if (argument.startsWith('--')) {
      stderr.write(_usage);
      return 2;
    } else if (argument.length > 1 && argument.startsWith('-')) {
      for (final String letter in argument.substring(1).split('')) {
        if (letter == 'A') {
          for (final String stage in _emitStages) {
            emitPaths[stage] = null;
          }
        } else if (_emitLetters.containsKey(letter)) {
          emitPaths[_emitLetters[letter]!] = null;
        } else {
          stderr.write(_usage);
          return 2;
        }
      }
    } else if (deckPath == null) {
      deckPath = argument;
    } else {
      stderr.write(_usage);
      return 2;
    }
  }
  // The `*CTEXT` card holds six date digits and a five-column time
  // (J 03.02.09; LD-1), so the head's forms are the only ones accepted.
  if (deckPath == null ||
      date != null && !RegExp(r'^\d\d/\d\d/\d\d$').hasMatch(date) ||
      time != null && !RegExp(r'^\d{1,2}\.\d\d$').hasMatch(time)) {
    stderr.write(_usage);
    return 2;
  }
  for (final String stage in emitPaths.keys.toList()) {
    final String path = emitPaths[stage] ?? _defaultDumpPath(deckPath, stage);
    // A deck named like a stage dump (`oops.cards`) derives a default
    // that is the deck itself; refuse rather than overwrite the canon
    // (D0.5). An explicit path stays the user's instruction.
    if (emitPaths[stage] == null && path == deckPath) {
      stderr.writeln(
        'error: the default --emit-$stage path is the deck itself; '
        'give --emit-$stage=PATH',
      );
      return 2;
    }
    emitPaths[stage] = path;
  }
  final now = DateTime.now();
  date ??=
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.day.toString().padLeft(2, '0')}/'
      '${(now.year % 100).toString().padLeft(2, '0')}';
  time ??= (now.hour + now.minute / 60).toStringAsFixed(2);
  try {
    // The job loop (D11.1–D11.3): one sink, one parse, and one listing
    // per job; the exit code reflects the worst severity of the whole
    // deck (D11.2).
    final List<CardImage> cards = decodeCanon(File(deckPath).readAsBytesSync());
    final DeckCompilation deck = compileDeck(
      cards,
      pedantic: pedantic,
      tableLimits: tableLimits,
    );
    final options = ListingOptions(
      date: date,
      time: time,
      account: account,
      title: title,
      linesPerPage: linesPerPage,
    );
    final StringBuffer? listing = emitPaths.containsKey('listing')
        ? StringBuffer()
        : null;
    final StringBuffer? object = emitPaths.containsKey('object')
        ? StringBuffer()
        : null;
    var failed = false;
    for (final (int index, JobCompilation job) in deck.jobs.indexed) {
      final ({String text, int pages}) page = writeListing(
        job.frontEnd,
        options,
        diagnostics: job.diagnostics,
        annotations: job.semantics?.allocation?.annotations,
      );
      listing?.write(page.text);
      stdout.write(page.text);
      if (object != null) {
        final CodegenResult? codegen = job.codegen;
        if (codegen == null) {
          // The attested dump takes no job headers — each section opens
          // with its own page head — so a dead job prints its one
          // marker line in sequence (D10.2; M4-2 as amended).
          object.writeln(codeStageMarker(job.unrecovered?.shape));
        } else if (codegen.stopped) {
          // A severity 5 in the generator: no object program, so no
          // object pages (J 90.04.02; D10.2).
          object.writeln(stageStopped);
        } else {
          // The loader-card page follows the job's source pages, and
          // the deck writer's lines come from the deck it punches, so
          // the print and the cards cannot differ.
          final JobDeck punched = jobDeck(job, options)!;
          object.write(
            writeObjectListing(
              codegen.units,
              loaderCards: punched.cardsBeforeText,
              lastCard: punched.lastCard,
              options: options,
              id: listingId(job.frontEnd),
              firstPage: page.pages + 1,
            ),
          );
        }
      }
      if (explain) {
        job.diagnostics.forEach(stderr.writeln);
      }
      if (job.unrecovered != null) {
        // The refusal is this compiler's, not the program's, so it
        // prints as an error of the tool and never as a line of the
        // 1962 listing (M4-2 as amended).
        failed = true;
        stderr.writeln('error: job ${index + 1}: ${job.unrecovered}');
      }
      if (run) {
        failed |= !_runObjectProgram(job, options, index + 1);
      }
    }
    // A stopped job still dumps every stage it reached (D10.2): the
    // renderers print the stopped line for the stages it did not.
    _emit(emitPaths['cards'], () => deckToMirror(cards));
    _emit(emitPaths['scan'], () => emitScan(deck));
    _emit(emitPaths['parse'], () => emitParse(deck));
    _emit(emitPaths['semantics'], () => emitSemantics(deck));
    _emit(emitPaths['listing'], () => listing!.toString());
    _emit(emitPaths['code'], () => emitCode(deck));
    _emit(emitPaths['object'], () => object!.toString());
    _emit(emitPaths['loader'], () => emitLoader(deck, options));
    if (emitPaths['deck'] case final String path) {
      File(path).writeAsBytesSync(emitDeck(deck, options));
    }
    // Severity 5 stops a job (J 90.04.02); lower severities still
    // produce output. A refusal fails the run the same way.
    return deck.maxSeverity >= 5 || failed ? 1 : 0;
  } on StopCompilation {
    // Every phase catches its own stop and returns partial results;
    // this net keeps a stop from any future phase from crashing the
    // driver (D9.1's job rule: stop, go to the next job).
    return 1;
  } on FormatException catch (e) {
    stderr.writeln('error: ${e.message}');
    return 1;
  } on FileSystemException catch (e) {
    stderr.writeln('error: ${e.message}: ${e.path}');
    return 1;
  }
}

/// Runs job [number]'s object program and prints its display lines
/// (D0.3; `docs/design/runtime.md` RT-1). Returns false unless the run
/// reached the end of the job. A job with no punched deck runs nothing
/// and fails nothing.
bool _runObjectProgram(JobCompilation job, ListingOptions options, int number) {
  final JobDeck? punched = jobDeck(job, options);
  if (punched == null) {
    return true;
  }
  try {
    final RunResult result = Machine.load(
      punched.cards,
    ).run(maxSteps: _stepBudget);
    result.display.forEach(stdout.writeln);
    if (result.outcome == RunOutcome.stepLimit) {
      stderr.writeln(
        'error: job $number: still running after $_stepBudget steps',
      );
    }
    // An error exit has already printed the monitor's own message on
    // the display (RT-2), so the tool adds none of its own.
    return result.outcome == RunOutcome.endOfJob;
  } on UnimplementedRuntimeEntry catch (e) {
    stderr.writeln('error: job $number: $e');
    return false;
  }
}

/// Writes one `--emit` dump. [render] runs only for a requested dump, so
/// an unasked-for stage costs nothing.
void _emit(String? path, String Function() render) {
  if (path != null) {
    File(path).writeAsStringSync(render());
  }
}

/// The default dump path (`docs/design/emit-stages.md`): the deck's
/// path with its extension replaced by the stage name, next to the
/// deck.
String _defaultDumpPath(String deckPath, String stage) {
  final int dot = deckPath.lastIndexOf('.');
  final int slash = deckPath.lastIndexOf(RegExp(r'[/\\]'));
  final String stem = dot > slash ? deckPath.substring(0, dot) : deckPath;
  return '$stem.$stage';
}
