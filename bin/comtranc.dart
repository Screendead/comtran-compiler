/// The compiler driver. At M1 it runs the front end — card reader,
/// scanners, statement numbering — and prints the compilation listing,
/// the first observable compiler output (roadmap M1, `docs/HANDOVER.md`).
library;

import 'dart:io';

import 'package:comtran/comtran.dart';

const String _usage = '''
Usage: dart run comtran:comtranc <deck.ctdeck> [options]

  Compiles one job's source deck and prints the compilation listing.
  (M1: the front end only — no parse, no code generation yet.)

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
    print('comtranc $comtranVersion');
    return 0;
  }
  String? deckPath;
  String? date;
  String? time;
  var account = '';
  var title = '';
  var linesPerPage = 55;
  for (final String argument in arguments) {
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
  final DateTime now = DateTime.now();
  date ??=
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.day.toString().padLeft(2, '0')}/'
      '${(now.year % 100).toString().padLeft(2, '0')}';
  time ??= (now.hour + now.minute / 60).toStringAsFixed(2);
  try {
    final FrontEndResult result = runFrontEnd(
      decodeCanon(File(deckPath).readAsBytesSync()),
    );
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
      ),
    );
    // Severity 5 stops compilation (J 90.04.02); lower severities still
    // produce output at M1.
    return result.maxSeverity >= 5 ? 1 : 0;
  } on FormatException catch (e) {
    stderr.writeln('error: ${e.message}');
    return 1;
  } on FileSystemException catch (e) {
    stderr.writeln('error: ${e.message}: ${e.path}');
    return 1;
  }
}
