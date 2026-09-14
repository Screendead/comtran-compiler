/// The second corpus (M6-6, M6-7): the 1960 sample payroll program of
/// F28-8043 Appendix 1, keyed as printed, and the same program with the
/// five §9.8 divergences the 1962 front end demands. The 1962 processor
/// never compiled either one, so each golden is decision-conformance,
/// not an oracle. The listing cannot carry a refusal, so the two
/// refusal tests pin what the generator stopped on.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The page head needs a date and a time, and the 1960 listing prints
/// neither. These fix them so the golden is reproducible; they claim
/// nothing (`test/fixtures/f-payroll-deck-notes.md`).
const List<String> _pageHead = <String>['--date=06/01/60', '--time=1.00'];

void _printsGolden(String deck, String golden) {
  final ProcessResult run = Process.runSync(Platform.resolvedExecutable, [
    'run',
    'comtran:comtranc',
    deck,
    ..._pageHead,
  ]);
  // Both decks stop the generator, so the run ends in a refusal.
  expect(run.exitCode, 1, reason: '${run.stderr}');
  expect(run.stdout, File(golden).readAsStringSync());
}

String _refusal(String deck) => compileDeck(
  decodeCanon(File(deck).readAsBytesSync()),
).jobs.single.unrecovered!.shape;

void main() {
  test('the verbatim deck prints its golden', () {
    _printsGolden(fVerbatimDeckPath, 'test/goldens/f-payroll.listing');
  });

  test('the applied deck prints its golden', () {
    _printsGolden(fAppliedDeckPath, 'test/goldens/f-payroll-j.listing');
  });

  test('the verbatim deck refuses its first GET', () {
    // No FILE card lists MASTER, so statement 3,00 has no input file.
    expect(
      _refusal(fVerbatimDeckPath),
      'a GET record on 0 input files (no sample instance)',
    );
  });

  test('the applied deck refuses the first FILE ... IN', () {
    // The environment division carries the GETs, so generation reaches
    // HIGH.DETAIL, statement 131,00, and stops at `FILE MASTER IN
    // ERROR.FILE`.
    expect(
      _refusal(fAppliedDeckPath),
      'FILE record IN file (no sample instance)',
    );
  });
}
