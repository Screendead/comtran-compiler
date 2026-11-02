/// The two input tapes of the 1960 payroll program, F28-8043 Appendix 1,
/// as the applied deck `test/fixtures/f-payroll-j.ctd` declares them. The
/// employees and their values are the 90.05 sample's, from
/// `tool/sample_tapes_source.dart` (M6-1 as amended); the record layouts
/// are the 1960 program's own. `test/fixtures/f-payroll-tapes-notes.md`
/// derives every field.
///
/// `tool/generate_f_tapes.dart` writes the two images from here and
/// `test/f_tapes_test.dart` compares them with the committed files.
library;

import 'package:comtran/comtran_io.dart';

import 'sample_tapes_source.dart';

/// The characters of one record: MASTER and DETAIL are each 80.
const int recordChars = 80;

/// The words of one block: BLOCKSIZE 14 on MASTER.FILE and DETAIL.FILE.
/// A record fills 13 words and two characters of the 14th, and the last
/// four characters are blank, as a card-to-tape pass leaves them.
const int blockWords = 14;

/// The 80 characters of the MASTER record of [master], field by field in
/// the order the data division declares them.
String masterCard(Master master) => <String>[
  ' ', // ERRORCODE
  master.number, // DEPARTMENT, EMPLOYEE
  master.name.padRight(15), // NAME
  _digits(master.rate, 5), // RATE 99V999
  ' ' * 6, // DATE
  _digits(master.exemptions, 2), // EXEMPTIONS 99
  _digits(0, 7), // GROSS 99999V99
  _digits(0, 5), // RETIREMENT 999V99
  _digits(0, 5), // INSURANCE 999V99
  _digits(master.ficaYtd, 5), // FICA 999V99
  _digits(0, 6), // WHT 9999V99
  _digits(master.bondDeduction, 4), // BONDEDUCTION 99V99
  _digits(master.bondAccumulation, 5), // BONDACCUMULATION 999V99
  _digits(master.bondDenomination, 5), // BONDENOMINATION 999V99
  ' ' * 3, // the unnamed AAA
].join();

/// The 80 characters of the DETAIL record of [detail]. A detail that
/// matches a master carries that master's name, exemptions and bond
/// deduction; one that matches none carries blanks and zeros there.
String detailCard(Detail detail) {
  final Master? master = _masterOf(detail.number);
  return <String>[
    ' ', // ERRORCODE
    detail.hours, // HOURS 99V9
    detail.number, // DEPARTMENT, EMPLOYEE
    (master?.name ?? '').padRight(15), // NAME
    detailDate, // MONTH, DAY, YEAR
    _digits(master?.exemptions ?? 0, 2), // EXEMPTIONS 99
    _digits(0, 7), // GROSS 99999V99
    _digits(0, 5), // RETIREMENT 999V99
    _digits(0, 5), // INSURANCE 999V99
    _digits(0, 5), // FICA 999V99
    _digits(0, 6), // WHT 9999V99
    _digits(master?.bondDeduction ?? 0, 4), // BONDEDUCTION 99V99
    _digits(0, 5), // BONDACCUMULATION 999V99
    _digits(0, 5), // BONDENOMINATION 999V99
    ' ' * 5, // the unnamed AAAAA
  ].join();
}

/// The MASTER.FILE image, unit D1: one block for each of the 25 masters.
List<int> fMasterImage() => _image(masters.map(masterCard));

/// The DETAIL.FILE image, unit C2: one block for each of the 14 details.
List<int> fDetailImage() => _image(details.map(detailCard));

List<int> _image(Iterable<String> cards) => <int>[
  for (final String card in cards) ...tapeRecord(_blockWords(card)),
  ...tapeField(0),
];

/// The [blockWords] words of one block that holds [card].
List<int> _blockWords(String card) {
  if (card.length != recordChars) {
    throw StateError('a record of ${card.length} characters: $card');
  }
  final String block = card.padRight(blockWords * 6);
  return <int>[
    for (var i = 0; i < block.length; i += 6)
      characterWord(block.substring(i, i + 6)),
  ];
}

/// [value] as [width] decimal digits. No picture of either record carries
/// an S, so a field holds no sign.
String _digits(int value, int width) {
  final String text = '$value'.padLeft(width, '0');
  if (value < 0 || text.length != width) {
    throw StateError('$value does not fit $width digits');
  }
  return text;
}

Master? _masterOf(String number) {
  for (final Master master in masters) {
    if (master.number == number) {
      return master;
    }
  }
  return null;
}
