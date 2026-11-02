/// The website's run (roadmap W4): the sample over its reconstructed
/// tapes, and what the site says when a run does not reach its end.
///
/// The sample's assertion is the byte comparison `machine_test.dart`
/// makes of `comtranc --run --list-tapes`, so the report a reader sees
/// on the site is the report the golden carries.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

String _sample() =>
    File('test/fixtures/90.05-payroll-job.ct').readAsStringSync();

/// The sample's two input tapes, as the site embeds them.
Map<String, List<int>> _sampleTapes() => {
  for (final unit in <String>['D1', 'C2'])
    unit: File('$sampleTapesPath/$unit.tap').readAsBytesSync(),
};

/// An image that holds a file mark and nothing else.
final List<int> _emptyTape = tapeField(0);

/// One job: [statements] over one internal-decimal field.
String _job(List<String> statements) => <String>[
  '      *DATA',
  dataCard(name: 'NUM', level: '1', mode: 'I', justify: 'R', description: '9'),
  '      *PROCEDURE',
  ...statements,
  '      *FINISH',
].join('\n');

void main() {
  group('the sample program in the browser', () {
    late WebRun result;

    setUpAll(() => result = runText(_sample(), _sampleTapes()));

    test('prints the report of test/goldens/90.05-payroll.report', () {
      expect(result.error, isNull);
      expect(
        result.output,
        'AT 199,14 STOP RUN\n'
        '${File('test/goldens/90.05-payroll.report').readAsStringSync()}',
      );
    });

    test('reaches its end of job with nothing to say', () {
      expect(result.ended, isTrue);
      expect(result.notes, isEmpty);
    });

    test('leaves the tapes it was handed as they were', () {
      final Map<String, List<int>> tapes = _sampleTapes();
      runText(_sample(), tapes);
      expect(tapes, _sampleTapes());
    });

    test('the browser payload holds four keys', () {
      expect(result.toJson().keys, ['error', 'output', 'notes', 'ended']);
    });
  });

  group('a run that does not reach its end', () {
    test('a missing input tape names where the site looked', () {
      final WebRun result = runText(_sample(), {'D1': _sampleTapes()['D1']!});
      expect(result.ended, isFalse);
      expect(result.output, isEmpty);
      expect(
        result.notes.single,
        'Job 1 stopped: No tape image for input file DETAILFILE at C2.tap.',
      );
    });

    test('an output tape with no file mark is reported, then named', () {
      // Two empty input tapes take the run to the base-locator guard,
      // which exits before close-all writes any file mark (M5-11).
      final WebRun result = runText(_sample(), {
        'D1': _emptyTape,
        'C2': _emptyTape,
      });
      expect(result.ended, isFalse);
      expect(result.output, contains('BASE LOCATOR NOT LOADED'));
      expect(result.output, contains('ERRORFILE REPORT\n\n'));
      expect(
        result.notes,
        contains(
          'Job 1 wrote a tape for ERRORFILE that cannot be read back: '
          'Unreadable tape record: the tape ends with no file mark.',
        ),
      );
    });

    test('a loop is stopped at the step budget', () {
      final WebRun result = runText(
        _job(['      START.  GO TO START.', '            STOP RUN.']),
        const {},
      );
      expect(result.ended, isFalse);
      expect(
        result.notes.single,
        'Job 1 was still running after 1000000 steps, so the site stopped '
        'it. A program that never ends is a result the machine '
        'reproduces, not a fault in it.',
      );
    });

    test('a job above severity 1 does not run', () {
      final WebRun result = runText(
        _job(['      START.  FROB NUM.', '            STOP RUN.']),
        const {},
      );
      expect(result.ended, isFalse);
      expect(result.output, isEmpty);
      expect(
        result.notes.single,
        'Job 1 did not run. Its worst diagnostic has severity 3, and only '
        'a job whose worst is 1 or less runs.',
      );
    });

    test('a job with no object program is passed over, and the next runs', () {
      // A Data Description constant over 120 characters draws 148,00
      // at severity 5 (D7.9).
      final WebRun result = runText(
        <String>[
          r'$CMPLE BAD',
          '      *DATA',
          dataCard(level: '2', description: "'${'A' * 33}", continued: true),
          dataCard(description: 'B' * 34, continued: true),
          dataCard(description: 'C' * 34, continued: true),
          dataCard(description: "${'D' * 25}'"),
          '      *FINISH',
          r'$CMPLE GOOD',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
        ].join('\n'),
        const {},
      );
      expect(
        result.notes.single,
        'Job 1 made no object program, so there is nothing to run. The '
        'listing says why.',
      );
      expect(result.output, contains('STOP RUN'));
      expect(result.ended, isTrue);
    });

    test('an empty deck is refused', () {
      expect(
        runText('', const {}).error,
        'There is no program to run. Type a program, or load the sample.',
      );
    });
  });
}
