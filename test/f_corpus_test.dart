/// The second corpus (M6-6, M6-7): the 1960 sample payroll program of
/// F28-8043 Appendix 1, keyed as printed, and the same program with the
/// five §9.8 divergences of M6-7 as amended. No 1962 listing of
/// either one survives, so each golden is decision-conformance,
/// not an oracle. Each deck punches an object deck, and a test pins its
/// card count. The verbatim deck is above severity 1 and does not run
/// (M6-11, `docs/design/m6-verbatim-deck.md`); the applied deck's tests pin
/// the reports it prints over its tapes.
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
  test('the verbatim deck prints its golden and does not run', () async {
    // The job punches a deck at severity 4 (J 02.01.01). The severity
    // bars the run, and so does the undefined symbol in the text, each
    // on its own (J 02.01.02; D7.6; D9.1). Only severity 5 changes the
    // exit status (D11.2).
    final ProcessResult run = await _comtranc(fVerbatimDeckPath, ['--run']);
    expect(run.exitCode, 0, reason: '${run.stderr}');
    expect(run.stdout, _golden('f-payroll.listing'));
    expect(
      run.stderr,
      'job 1: not run: maximum severity 4\n'
      'job 1: not run: undefined symbol in the generated code\n',
    );
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

  test('the verbatim deck compiles to an object deck', () {
    // Jack's ruling of 2026-11-21: punch the deck as 1962 did. The
    // forms are our design, with no oracle (M6-11).
    final JobCompilation job = _job(fVerbatimDeckPath);
    expect(job.unrecovered, isNull);
    // Each operand that names no data item is one undefined symbol in
    // the text (M6-11 a), so the words count as the 108,00 and 101,00 rows.
    expect(
      job.codegen!.units.where(
        (AssemblyUnit u) =>
            u.operation == 'PZE' &&
            u.control == ControlGroup.constantWord &&
            u.operand.endsWith(',,0'),
      ),
      hasLength(
        job.diagnostics
            .where(
              (Diagnostic d) =>
                  const ['108,00', '101,00'].contains(d.message.number),
            )
            .length,
      ),
    );
    const options = ListingOptions(date: '06/01/60', time: '1.00');
    expect(jobDeck(job, options)!.cards, hasLength(35));
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
