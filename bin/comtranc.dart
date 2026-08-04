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
Usage: dart run comtran:comtranc <deck.ctdeck> [options]

  Compiles every job on the deck ($CMPLE ... *FINISH) and prints one
  compilation listing per job.
  (M1-M3 stage 1: front end, parser, data mapper — no code generation
  yet.)

  --date=mm/dd/yy    page-head date (default: today)
  --time=h.hh        page-head time, decimal hours (default: now)
  --account=TEXT     page-head ACCOUNT field (default: blank)
  --title=TEXT       title line above page 1 (default: none)
  --lines-per-page=N content lines per page (default: 55)
  --pedantic         add non-historical written-language-strictness
                      diagnostics (D0.8); changes no parse result or
                      generated value
  --explain          after compiling, print each job's diagnostics to
                      stderr, one per line; the listing on stdout is
                      unchanged
  --version          print the version and exit
''';

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
  var explain = false;
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
    } else if (argument == '--explain') {
      explain = true;
    } else if (argument.startsWith('--')) {
      stderr.write(_usage);
      return 2;
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
    final DeckCompilation deck = compileDeck(
      decodeCanon(File(deckPath).readAsBytesSync()),
      pedantic: pedantic,
    );
    final options = ListingOptions(
      date: date,
      time: time,
      account: account,
      title: title,
      linesPerPage: linesPerPage,
    );
    for (final JobCompilation job in deck.jobs) {
      stdout.write(
        writeListing(job.frontEnd, options, diagnostics: job.diagnostics),
      );
      if (explain) {
        job.diagnostics.forEach(stderr.writeln);
      }
    }
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
