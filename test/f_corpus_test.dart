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

/// Runs comtranc over [deck] with the fixed page head and [options].
Future<ProcessResult> _comtranc(
  String deck, [
  List<String> options = const [],
]) => Process.run(Platform.resolvedExecutable, [
  'run',
  'comtran:comtranc',
  deck,
  ..._pageHead,
  ...options,
]);

String _golden(String name) => File('test/goldens/$name').readAsStringSync();

JobCompilation _job(String deck) =>
    compileDeck(decodeCanon(File(deck).readAsBytesSync())).jobs.single;

void main() {
  test('the verbatim deck prints its golden', () async {
    // The generator refuses the deck, so the run ends in a refusal. It
    // is the listing reading's, per Jack's ruling of 2026-11-02 (M6-9).
    final ProcessResult run = await _comtranc(fVerbatimDeckPath);
    expect(run.exitCode, 1, reason: '${run.stderr}');
    expect(run.stdout, _golden('f-payroll.listing'));
  });

  test('the applied deck prints its listing, then over its tapes its '
      'reports', () async {
    // The golden reports are our output; test/f_acceptance_test.dart
    // classifies their distance from the 1962 sample's report (M6-9,
    // the run).
    final Directory tapes = Directory.systemTemp.createTempSync(
      'comtran-f-tapes',
    );
    addTearDown(() => tapes.deleteSync(recursive: true));
    for (final unit in <String>['D1', 'C2']) {
      File('$fTapesPath/$unit.tap').copySync('${tapes.path}/$unit.tap');
    }
    final ProcessResult run = await _comtranc(fAppliedDeckPath, [
      '--run',
      '--tapes=${tapes.path}',
      '--list-tapes',
    ]);
    expect(run.exitCode, 0, reason: '${run.stderr}');
    expect(
      run.stdout,
      '${_golden('f-payroll-j.listing')}'
      'AT 139,00 STOP 1234\n'
      'AT 140,00 STOP RUN\n'
      '${_golden('f-payroll-j.report')}',
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
