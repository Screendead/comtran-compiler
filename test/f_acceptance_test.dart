/// M6 stage 2, the run of the applied 1960 deck against its oracle: the
/// reports `f-payroll-j.ctd` prints over its tapes, against the report
/// the 1962 sample prints over the same employees
/// (`docs/design/m6-f-tapes.md`, the run). The golden's own test in
/// `test/runtime/machine_test.dart` proves the run prints it; this test
/// pins every column that matches and every difference with its cause.
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

/// The amount in cents that [text] prints, or 0 for a blank field.
int _cents(String text) {
  final String digits = text.replaceAll(RegExp(r'[ $*.]'), '');
  return digits.isEmpty ? 0 : int.parse(digits);
}

/// One PAYRECORD line of ours: the fields at their record columns
/// (statements 58,00 to 80,00).
final class _Ours {
  _Ours(String line) : text = line.padRight(115);

  final String text;
  String get identification => text.substring(0, 32);
  String get hours => text.substring(32, 39).trim();
  String get amounts => text.substring(39, 95);
  String get insuranceAndRetirement => text.substring(77, 95);
  int get net => _cents(text.substring(95, 105));
  String get bonds => text.substring(105, 115).trim();
}

/// One PAYFILE line of the 1962 sample's report, by its print columns.
final class _Theirs {
  _Theirs(String line) : text = line.padRight(117);

  final String text;
  String get hours => text.substring(33, 41).trim();
  int get insurance => _cents(text.substring(79, 88));
  int get retirement => _cents(text.substring(88, 97));
  int get net => _cents(text.substring(97, 107));
  int get bonds => _cents(text.substring(107, 117));
}

/// The rate in mills of each matched employee, in tape order
/// (`tool/sample_tapes_source.dart`).
const List<int> _rates = <int>[
  3400, 5333, 7000, 9000, 2350, 2900, 3000, 9990, 9990, 11000, 12000, //
];

/// The deck's TABLE (statements 102,00 to 107,00): each item's RATE in
/// mills and its RETIREMENT.PREM in cents.
const List<(int, int)> _table = <(int, int)>[
  (999, 60), (1499, 60), (1999, 90), (2499, 90), (2999, 120), (3499, 120),
  (3999, 150), (4499, 150), (4999, 180), (6499, 250), (7999, 350),
  (99999, 500), //
];

/// The retirement premium of the first item whose rate is not below
/// [rate], the item SEARCH stops on (statement 166,00).
int _retirement(int rate) => _table.firstWhere((item) => rate <= item.$1).$2;

void main() {
  final Map<String, List<String>> ours = _reports(
    'test/goldens/f-payroll-j.report',
  );
  final Map<String, List<String>> sample = _reports(
    'test/goldens/90.05-payroll.report',
  );
  final List<String> report = ours['REPORT.FILE REPORT']!;
  final mine = <_Ours>[
    for (final line in report.sublist(0, report.length - 1)) _Ours(line),
  ];
  final List<String> payfile = sample['PAYFILE REPORT']!;
  final theirs = <_Theirs>[
    for (final line in payfile)
      if (!line.startsWith(' ') && !line.startsWith('GT')) _Theirs(line),
  ];

  test('the deck writes three reports, and the employees pair', () {
    expect(ours.keys, <String>[
      'REPORT.FILE REPORT',
      'CHECK.FILE REPORT',
      'ERROR.FILE REPORT',
    ]);
    expect(mine, hasLength(11));
    expect(theirs, hasLength(11));
  });

  test('the hours match on every employee line', () {
    for (var i = 0; i < 11; i++) {
      expect(mine[i].hours, theirs[i].hours);
    }
  });

  test('no statement writes the identification or six amounts', () {
    // The CORRESPONDING finding: DETAIL holds these fields under DATA,
    // and PAYRECORD has no DATA group, so `MOVE CORRESPONDING DETAIL TO
    // PAYRECORD` pairs HOURS and BONDENOMINATION alone ([J 02.04.04]).
    // The number, name, date, gross pay, WHT, FICA, bond deduction,
    // insurance and retirement keep the record area's first value, a
    // zero word, which lists as zero characters (ED-6).
    for (final line in mine) {
      expect(line.identification, '0' * 32);
      expect(line.amounts, '0' * 56);
    }
  });

  test('net pay differs by the 1962 RET = INS defect, and by the 40-hour '
      'week below 40 hours', () {
    // Cause 1: the 1962 page prints RET.PREM equal to INS.PREM (M6-4
    // finding 1). Our 11-character lookup reads the true premium, so
    // ours = theirs + their RET.PREM - the table's RET.PREM.
    // Cause 2: below 40 hours the 1960 program pays a 40-hour week
    // (M6-1 cause 2), so six lines add the pay of the hours not worked,
    // less its FICA and WHT (D4.1 rounding).
    const fortyHourWeek = <int, int>{
      1: 8426, // CASPERIAN J, 20.0 hours
      2: 5166, // CATLETT H, 31.0 hours
      3: 5535, // DORR D, 32.5 hours
      5: 2378, // SMITH B, 30.0 hours
      8: 2457, // WILLIAMS P, 37.0 hours
      10: 984, // WOO J, 39.0 hours
    };
    for (var i = 0; i < 11; i++) {
      expect(theirs[i].retirement, theirs[i].insurance);
      final int lookup = theirs[i].retirement - _retirement(_rates[i]);
      expect(lookup, isNot(0));
      expect(mine[i].net, theirs[i].net + lookup + (fortyHourWeek[i] ?? 0));
    }
  });

  test('the bond column prints the tape zero, so WOO differs', () {
    // F-T4: `MOVE CORRESPONDING DETAIL TO PAYRECORD` moves the tape's
    // zero over the bond that statement 162,00 moved there.
    for (var i = 0; i < 11; i++) {
      expect(mine[i].bonds, r'$00.00');
      expect(theirs[i].bonds, i == 10 ? 3750 : 0);
    }
  });

  test('no department total prints', () {
    // The CORRESPONDING finding again: no statement fills PAYRECORD
    // DEPARTMENT or CURRENT DEPARTMENT, so the break test of statement
    // 148,00 compares zero with zero and never passes. The sample prints
    // seven department lines.
    expect(report, hasLength(12));
    expect(payfile.where((l) => l.contains('TOTALS')), hasLength(7));
  });

  test('the grand total checks the hours alone', () {
    final grand = _Ours(report.last);
    expect(payfile.last, startsWith('GT'));
    expect(grand.hours, _Theirs(payfile.last).hours);
    // A 1960-program difference: END.OF.RUN moves no identification
    // (definition section 9.8), so the line keeps the zero characters.
    expect(grand.identification, '0' * 32);
    // CORRESPONDING: statement 149,00 adds HOURS alone into GRAND.TOTAL,
    // so gross pay, WHT, FICA and bond deduction move as zero.
    expect(
      grand.text.substring(39, 77),
      r'    $0.00     $0.00    $0.00    $0.00 ',
    );
    // M6-1 cause 3: INSURANCE.PREM and RETIREMENT.PREM pair with nothing.
    expect(grand.insuranceAndRetirement, '0' * 18);
    // 1960-program defects: no statement adds a net pay into a totals
    // record, and BONDPURCHASES pairs with no PAYRECORD field, so the
    // bond column keeps WOO's line.
    expect(grand.net, 0);
    expect(grand.bonds, r'$00.00');
  });

  test('each check carries the net pay and no identification', () {
    final List<String> checks = ours['CHECK.FILE REPORT']!;
    expect(checks, hasLength(11));
    // The 1962 check is two lines and holds the date (a 1960-program
    // layout difference).
    expect(sample['CHECKFILE REPORT'], hasLength(22));
    for (var i = 0; i < 11; i++) {
      // CORRESPONDING: CHECK EMPLOYEE.NUMBER and NAME pair with nothing.
      expect(checks[i].substring(0, 21), '0' * 21);
      expect(_cents(checks[i].substring(21)), mine[i].net);
    }
  });

  test('ERROR.FILE holds the sample errors in order, and the bond order', () {
    final List<String> errors = ours['ERROR.FILE REPORT']!;
    final List<String> page = sample['ERRORFILE REPORT']!;
    expect(errors, hasLength(page.length + 1));
    // The 1960 program files the bond order in ERROR.FILE (definition
    // section 9.8). CORRESPONDING pairs BONDENOMINATION alone, so the
    // number, the date and the name stay zero.
    expect(errors.removeAt(15), '${'0' * 12}03750${'0' * 15}');
    expect(sample['BONDORDERFILE REPORT']!.single, contains(' 3750 '));
    for (var i = 0; i < page.length; i++) {
      final String line = errors[i];
      // The whole 1960 record prints. A detail holds its hours before
      // its number.
      final String values = line.startsWith('M')
          ? line.substring(0, page[i].length)
          : '${line[0]}${line.substring(4, 10)}${line.substring(25, 31)}'
                '${line.substring(1, 4)}';
      expect(values, page[i]);
    }
  });
}
