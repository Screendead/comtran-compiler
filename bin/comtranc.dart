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
  -A, --emit-all      write every stage dump
  -c -s -p -S -l      the short emit flags, one letter per stage above,
                      bundleable: -cpsSl is the full set. A dump without
                      PATH lands next to the deck, the deck's extension
                      replaced by the stage name: `payroll.ctd -p`
                      writes `payroll.parse`.
  --version          print the version and exit
''';

/// The stage names `--emit-<stage>[=<path>]` accepts
/// (`docs/design/emit-stages.md`).
const List<String> _emitStages = [
  'cards',
  'scan',
  'parse',
  'semantics',
  'listing',
];

/// The one-letter emit flags. A short flag always takes the default
/// path; a custom path needs the long form.
const Map<String, String> _emitLetters = {
  'c': 'cards',
  's': 'scan',
  'p': 'parse',
  'S': 'semantics',
  'l': 'listing',
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
  if (deckPath == null) {
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
    for (final JobCompilation job in deck.jobs) {
      final String page = writeListing(
        job.frontEnd,
        options,
        diagnostics: job.diagnostics,
        annotations: job.semantics?.allocation?.annotations,
      );
      listing?.write(page);
      stdout.write(page);
      if (explain) {
        job.diagnostics.forEach(stderr.writeln);
      }
    }
    // A stopped job still dumps every stage it reached (D10.2): the
    // renderers print the stopped line for the stages it did not.
    _emit(emitPaths['cards'], () => deckToMirror(cards));
    _emit(emitPaths['scan'], () => emitScan(deck));
    _emit(emitPaths['parse'], () => emitParse(deck));
    _emit(emitPaths['semantics'], () => emitSemantics(deck));
    _emit(emitPaths['listing'], () => listing!.toString());
    // Severity 5 stops a job (J 90.04.02); lower severities still
    // produce output.
    return deck.maxSeverity >= 5 ? 1 : 0;
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
