/// The second corpus (M6-6, M6-7): the 1960 sample payroll program of
/// F28-8043 Appendix 1, keyed as printed, and the same program with the
/// five §9.8 divergences of M6-7 as amended. No 1962 listing of
/// either one survives, so each golden is decision-conformance,
/// not an oracle. The verbatim deck punches an object deck but is above
/// severity 1 and does not run (M6-11, `docs/design/m6-verbatim-deck.md`);
/// the applied deck's test pins the reports it prints over its tapes.
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

void main() {
  late Directory tapes;
  late Future<ProcessResult> verbatimRun;
  late Future<ProcessResult> appliedRun;

  setUpAll(() {
    // Both runs start here, so the processes overlap.
    tapes = Directory.systemTemp.createTempSync('comtran-f-tapes');
    for (final unit in <String>['D1', 'C2']) {
      File('$fTapesPath/$unit.tap').copySync('${tapes.path}/$unit.tap');
    }
    verbatimRun = _comtranc(fVerbatimDeckPath, ['--run']);
    appliedRun = _comtranc(fAppliedDeckPath, [
      '--run',
      '--tapes=${tapes.path}',
      '--list-tapes',
    ]);
  });

  tearDownAll(() async {
    await Future.wait([verbatimRun, appliedRun]);
    tapes.deleteSync(recursive: true);
  });

  test('the verbatim deck prints its golden and does not run', () async {
    // The job punches a deck at severity 4 (J 02.01.01). The severity
    // bars the run, and so does the undefined symbol in the text, each
    // on its own (J 02.01.02; D7.6; D9.1). Only severity 5 changes the
    // exit status (D11.2).
    final ProcessResult run = await verbatimRun;
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
    final ProcessResult run = await appliedRun;
    expect(run.exitCode, 0, reason: '${run.stderr}');
    expect(
      run.stdout,
      '${_golden('f-payroll-j.listing')}'
      'AT 139,00 STOP 1234\n'
      'AT 140,00 STOP RUN\n'
      '${_golden('f-payroll-j.report')}',
    );
  });

  test('each undefined operand of the verbatim deck is one word of text', () {
    final JobCompilation job = compileDeck(
      decodeCanon(File(fVerbatimDeckPath).readAsBytesSync()),
    ).jobs.single;
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
  });
}
