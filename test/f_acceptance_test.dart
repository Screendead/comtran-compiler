/// M6 stage 2, the run of the applied 1960 deck against its oracle: the
/// reports `f-payroll-j.ctd` prints over its tapes, against the report
/// the 1962 sample prints over the same employees (M6-9 of
/// `docs/design/m6-acceptance.md`, the run). The golden's own test in
/// `test/runtime/machine_test.dart` proves the run prints it; this test
/// pins every column that matches and every difference with its cause.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../tool/sample_tapes_source.dart';
import 'support/deck_fixtures.dart';

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

/// One TABLE item of the applied deck: RATE in mills, INSURANCE.PREM
/// and RETIREMENT.PREM in cents.
typedef _Item = ({int rate, int insurance, int retirement});

/// The deck's TABLE, read from its six 22-character constants
/// (statements 102,00 to 107,00), two 11-character items to a constant.
List<_Item> _table() => <_Item>[
  for (final Match constant in RegExp(r"'(\d{22})'").allMatches(
    deckToMirror(decodeCanon(File(fAppliedDeckPath).readAsBytesSync())),
  ))
    for (final int at in <int>[0, 11])
      (
        rate: int.parse(constant[1]!.substring(at, at + 5)),
        insurance: int.parse(constant[1]!.substring(at + 5, at + 8)),
        retirement: int.parse(constant[1]!.substring(at + 8, at + 11)),
      ),
];

/// [numerator] / [denominator], rounded half up: a SET rounds (D4.1).
int _round(int numerator, int denominator) =>
    (numerator + denominator ~/ 2) ~/ denominator;

/// The net pay in cents of [master] for [hoursTenths], as the procedure
/// of either program computes it. [fortyHourWeek] pays 40 hours, as the
/// 1960 program does below 40 (statement 142,00); otherwise the hours
/// worked are paid, as statement 203,00 of the 1962 sample does.
/// [retirementIsInsurance] reads INS.PREM for RET.PREM, the 1962
/// processor's defect (M6-4 finding 1).
int _net(
  Master master,
  int hoursTenths,
  List<_Item> table, {
  required bool fortyHourWeek,
  required bool retirementIsInsurance,
}) {
  // Mills times tenths of an hour is a hundred-thousandth of a dollar.
  final int gross = _round(
    master.rate * (fortyHourWeek ? 400 : hoursTenths),
    100,
  );
  // Both FICA sentences pay 3 percent up to 144.00 a year.
  final int fica = master.ficaYtd * 100 + 3 * gross < 1440000
      ? _round(3 * gross, 100)
      : 14400 - master.ficaYtd;
  final int taxable = gross - 1300 * master.exemptions;
  final int wht = taxable > 0 ? _round(18 * taxable, 100) : 0;
  // SEARCH stops on the first item whose rate is not below the master's.
  final _Item item = table.firstWhere((item) => master.rate <= item.rate);
  final int retirement = retirementIsInsurance
      ? item.insurance
      : item.retirement;
  return gross -
      fica -
      wht -
      item.insurance -
      retirement -
      master.bondDeduction;
}

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

  test('a model of both programs gives every net pay to the cent', () {
    final List<_Item> table = _table();
    expect(table, hasLength(12));
    final byNumber = <String, Master>{
      for (final master in masters) master.number: master,
    };
    final paid = <(Master, int)>[
      for (final detail in details)
        if (byNumber[detail.number] case final Master master)
          (master, int.parse(detail.hours)),
    ];
    expect(paid, hasLength(11));
    for (var i = 0; i < 11; i++) {
      final (Master master, int hours) = paid[i];
      // No line exceeds 40 hours, so neither overtime arm fires.
      expect(hours, lessThanOrEqualTo(400));
      final int ours1960 = _net(
        master,
        hours,
        table,
        fortyHourWeek: true,
        retirementIsInsurance: false,
      );
      final int sample1962 = _net(
        master,
        hours,
        table,
        fortyHourWeek: false,
        retirementIsInsurance: true,
      );
      expect(mine[i].net, ours1960, reason: master.name);
      expect(theirs[i].net, sample1962, reason: master.name);
      // Cause 1: the page prints RET.PREM equal to INS.PREM, and our
      // lookup through the 11-character item reads the true premium.
      expect(theirs[i].retirement, theirs[i].insurance);
      final int hoursWorked = _net(
        master,
        hours,
        table,
        fortyHourWeek: false,
        retirementIsInsurance: false,
      );
      expect(hoursWorked - sample1962, isNot(0));
      // Cause 2: the 40-hour week (M6-1 cause 2) moves exactly the
      // lines below 40 hours.
      expect(ours1960 - hoursWorked != 0, hours < 400, reason: master.name);
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
    final bondOrder = '${'0' * 12}03750${'0' * 15}';
    expect(errors.indexOf(bondOrder), 15);
    errors.remove(bondOrder);
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
