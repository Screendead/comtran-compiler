/// The second corpus (M6-6, M6-7): the 1960 sample payroll program of
/// F28-8043 Appendix 1, keyed as printed, and the same program with the
/// five §9.8 divergences of M6-7 as amended. No 1962 listing of
/// either one survives, so each golden is decision-conformance,
/// not an oracle. The listing cannot carry a refusal, so the verbatim
/// deck's refusal test pins what the generator stopped on, and the
/// applied deck's test pins the object deck it now punches.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The page head needs a date and a time, and the 1960 listing prints
/// neither. These fix them so the golden is reproducible; they claim
/// nothing (`test/fixtures/f-payroll-deck-notes.md`).
const List<String> _pageHead = <String>['--date=06/01/60', '--time=1.00'];

void _printsGolden(String deck, String golden, {required int exitCode}) {
  final ProcessResult run = Process.runSync(Platform.resolvedExecutable, [
    'run',
    'comtran:comtranc',
    deck,
    ..._pageHead,
  ]);
  expect(run.exitCode, exitCode, reason: '${run.stderr}');
  expect(run.stdout, File(golden).readAsStringSync());
}

JobCompilation _job(String deck) =>
    compileDeck(decodeCanon(File(deck).readAsBytesSync())).jobs.single;

void main() {
  test('the verbatim deck prints its golden', () {
    // The generator refuses the deck, so the run ends in a refusal.
    _printsGolden(
      fVerbatimDeckPath,
      'test/goldens/f-payroll.listing',
      exitCode: 1,
    );
  });

  test('the applied deck prints its golden', () {
    _printsGolden(
      fAppliedDeckPath,
      'test/goldens/f-payroll-j.listing',
      exitCode: 0,
    );
  });

  test('the verbatim deck refuses its first GET', () {
    // No FILE card lists MASTER, so statement 3,00 has no input file.
    expect(
      _job(fVerbatimDeckPath).unrecovered!.shape,
      'a GET record on 0 input files (no sample instance)',
    );
  });

  test('the applied deck compiles to an object deck', () {
    // Statement 162,00, `MOVE CORRESPONDING MASTER TO BONDORDER`, was
    // the last refusal (M6-9). It moves BONDENOMINATION alone, because
    // MASTER holds EMPLOYEE.NUMBER, NAME and DATE under DATA
    // (J 02.04.04 b).
    final JobCompilation job = _job(fAppliedDeckPath);
    expect(job.unrecovered, isNull);
    final List<String> words = [
      for (final AssemblyUnit u in job.codegen!.units)
        '${u.operation} ${u.operand}',
    ];
    expect(words.where((String w) => w.startsWith('TXI SYS)183')), [
      'TXI SYS)183,1,0',
    ]);
    const options = ListingOptions(date: '06/01/60', time: '1.00');
    // Six comparands across a word boundary each take an
    // `LDQ` and an `ANA` (codegen defect 12), past one card.
    expect(jobDeck(job, options)!.cards, hasLength(68));
  });
}
