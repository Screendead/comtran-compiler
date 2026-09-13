/// M6 stage 1, the acceptance diff: the report the 90.05 sample prints
/// over its reconstructed tapes against our reading of the printed
/// report, PDF p. 217 (`docs/design/m6-acceptance.md` M6-4). The
/// golden's own test proves the run prints it; this test measures the
/// distance from the page and pins every difference.
library;

import 'dart:io';

import 'package:test/test.dart';

/// The lines of each report in [path], keyed by the heading line.
Map<String, List<String>> _reports(String path) {
  final reports = <String, List<String>>{};
  late List<String> current;
  for (final String line in File(path).readAsLinesSync()) {
    if (line.endsWith(' REPORT')) {
      current = reports[line] = <String>[];
    } else if (line.isNotEmpty) {
      current.add(line);
    }
  }
  return reports;
}

void main() {
  final Map<String, List<String>> ours = _reports(
    'test/goldens/90.05-payroll.report',
  );
  final Map<String, List<String>> page = _reports(
    'test/fixtures/90.05-report-page-217.txt',
  );

  test('the four reports are the four on the page', () {
    expect(ours.keys, page.keys);
  });

  test('PAYFILE differs at the grand-total net pay alone', () {
    final List<String> mine = ours['PAYFILE REPORT']!;
    final List<String> theirs = page['PAYFILE REPORT']!;
    expect(mine, hasLength(theirs.length));
    for (var i = 0; i < mine.length - 1; i++) {
      expect(mine[i], theirs[i]);
    }
    // The page's GT line prints 2180.63 where its own department totals
    // sum to 2183.83 (M6-4, finding 2).
    expect(mine.last, contains('2183.83'));
    expect(theirs.last, contains('2180.63'));
    expect(mine.last.replaceFirst('2183.83', '2180.63'), theirs.last);
  });

  test('CHECKFILE ends with the three checks the page prints', () {
    final List<String> mine = ours['CHECKFILE REPORT']!;
    final List<String> theirs = page['CHECKFILE REPORT']!;
    expect(mine, hasLength(22));
    expect(mine.sublist(mine.length - theirs.length), theirs);
  });

  test('BONDORDERFILE differs in the one letter the print chain bent', () {
    // WCO on the page is the same NAME field that prints WOO twice
    // elsewhere on it (M6-4, finding 3).
    final String mine = ours['BONDORDERFILE REPORT']!.single;
    final String theirs = page['BONDORDERFILE REPORT']!.single;
    expect(mine, ' 091980 WOO J            3750 100661');
    expect(mine.replaceFirst('WOO', 'WCO'), theirs);
  });

  test('ERRORFILE is the page', () {
    expect(ours['ERRORFILE REPORT'], page['ERRORFILE REPORT']);
  });
}
