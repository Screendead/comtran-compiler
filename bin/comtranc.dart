/// The compiler driver. It runs the front end — card reader, scanners,
/// statement numbering — and the M2 parser, and prints the compilation
/// listing with the merged diagnostic block (roadmap M1–M2,
/// `docs/HANDOVER.md`; design note M2-1).
library;

import 'dart:io';

import 'package:comtran/comtran.dart';

const String _usage = '''
Usage: dart run comtran:comtranc <deck.ctdeck> [options]

  Compiles one job's source deck and prints the compilation listing.
  (M1+M2: front end and parser — no code generation yet.)

  --date=mm/dd/yy    page-head date (default: today)
  --time=h.hh        page-head time, decimal hours (default: now)
  --account=TEXT     page-head ACCOUNT field (default: blank)
  --title=TEXT       title line above page 1 (default: none)
  --lines-per-page=N content lines per page (default: 55)
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
  // The compilation's one diagnostic sink (D9.1): both phases record
  // into it, and its severity-5 throw stops each phase at the point of
  // detection.
  final sink = DiagnosticSink();
  try {
    final FrontEndResult result = runFrontEnd(
      decodeCanon(File(deckPath).readAsBytesSync()),
      sink: sink,
    );
    // A front-end stop skips the parser: the compilation stopped at
    // the point of detection (D9.1; D10.2).
    final ParseResult? parse = result.stopped
        ? null
        : runParser(result, sink: sink);
    stdout.write(
      writeListing(
        result,
        ListingOptions(
          date: date,
          time: time,
          account: account,
          title: title,
          linesPerPage: linesPerPage,
        ),
        diagnostics: parse?.diagnostics ?? result.diagnostics,
      ),
    );
    // Severity 5 stops compilation (J 90.04.02); lower severities still
    // produce output.
    return sink.maxSeverity >= 5 ? 1 : 0;
  } on StopCompilation {
    // Both phases catch their own stop and return partial results; this
    // net keeps a stop from any future phase on the same sink from
    // crashing the driver (D9.1's job rule: stop, go to the next job).
    return 1;
  } on FormatException catch (e) {
    stderr.writeln('error: ${e.message}');
    return 1;
  } on FileSystemException catch (e) {
    stderr.writeln('error: ${e.message}: ${e.path}');
    return 1;
  }
}
