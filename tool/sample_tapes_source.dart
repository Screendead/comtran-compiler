/// The two input tapes of the J Appendix 90.05 payroll sample, as the
/// records behind its printed report (PDF p. 217). The manual prints the
/// report and not the tapes, so every field below is derived from the
/// report or chosen; `test/fixtures/90.05-tapes-notes.md` holds the
/// derivation of each one and the evidence for the reading of the page.
///
/// `tool/generate_sample_tapes.dart` writes the two images from here and
/// `test/sample_tapes_test.dart` compares them with the committed files.
library;

import 'package:comtran/comtran_io.dart';

/// One INPUTMASTER record. [rate] is in mills and every other amount in
/// cents, the way the internal fields hold them. A field the report
/// never prints is zero.
final class Master {
  const Master(
    this.number,
    this.name, [
    this.rate = 0,
    this.exemptions = 0,
    this.ficaYtd = 0,
    this.bondDeduction = 0,
    this.bondAccumulation = 0,
    this.bondDenomination = 0,
  ]);

  final String number;
  final String name;
  final int rate;
  final int exemptions;
  final int ficaYtd;
  final int bondDeduction;
  final int bondAccumulation;
  final int bondDenomination;
}

/// One DETAILFILE record. [hours] is three characters, tenths implied.
final class Detail {
  const Detail(this.number, this.hours);

  final String number;
  final String hours;
}

/// The 25 master records, in employee-number order. Fourteen of them
/// reach no detail and print on ERRORFILE, so they carry a number and a
/// name alone.
const List<Master> masters = <Master>[
  Master('011001', 'AJAX T'),
  Master('011010', 'BLUT H', 3400, 2, 14400),
  Master('011011', 'BLOODSOE F'),
  Master('021021', 'CASPERIAN J', 5333, 1),
  Master('031721', 'CATLETT H', 7000, 1, 14400),
  Master('041722', 'DICK M'),
  Master('041723', 'DORR D', 9000, 2, 14199),
  Master('041791', 'SMITH J'),
  Master('051792', 'JONES F'),
  Master('061793', 'CABAN R', 2350, 0, 14400),
  Master('071794', 'MANDELI A'),
  Master('071801', 'FUNGE T'),
  Master('071802', 'SMITH B', 2900, 1, 14400),
  Master('071803', 'SOBEK W', 3000, 2, 14400, 400, 0, 1875),
  Master('081921', 'CRAMER P'),
  Master('081922', 'BAKER B'),
  Master('081923', 'WICKIWICZ J'),
  Master('091924', 'REYNOLDS J', 9990, 1, 14400, 500, 0, 1875),
  Master('091925', 'MOCRE J'),
  Master('091926', 'MOCRE D'),
  Master('091976', 'WUFFE T'),
  Master('091977', 'WILLIAMS P', 9990, 3, 14400, 1000, 0, 1875),
  Master('091978', 'RICHARD D', 11000, 4, 14400),
  Master('091980', 'WOO J', 12000, 1, 14400, 1700, 2050, 3750),
  Master('091981', 'ZUGEE W'),
];

/// The 14 detail records. Three of them match no master: 061500, 071899
/// and 091983, each of which prints whole on its ERRORFILE line.
const List<Detail> details = <Detail>[
  Detail('011010', '400'),
  Detail('021021', '200'),
  Detail('031721', '310'),
  Detail('041723', '325'),
  Detail('061500', '400'),
  Detail('061793', '400'),
  Detail('071802', '300'),
  Detail('071803', '400'),
  Detail('071899', '400'),
  Detail('091924', '400'),
  Detail('091977', '370'),
  Detail('091978', '400'),
  Detail('091980', '390'),
  Detail('091983', '400'),
];

/// The date every detail record carries.
const String detailDate = '100661';

/// The INPUTMASTER image: the records of [masters] in 300-word blocks of
/// twenty, so the 25 make a block of 20 and a block of 5 ([J 90.05.02]).
List<int> masterImage() => <int>[
  for (var i = 0; i < masters.length; i += 20)
    ...tapeRecord(<int>[
      for (final Master master in masters.skip(i).take(20))
        ..._masterWords(master),
    ]),
  ...tapeField(0),
];

/// The DETAILFILE image: one 14-word block for each record of [details],
/// which "occupies the first portion" of it ([J 90.05.03]). The other
/// eleven words are blank, as a card-to-tape pass leaves them.
List<int> detailImage() => <int>[
  for (final Detail detail in details)
    ...tapeRecord(<int>[
      _characters(detail.number),
      _characters(detailDate),
      _characters(detail.hours),
      ...List<int>.filled(11, _characters('')),
    ]),
  ...tapeField(0),
];

/// The 15 words of one master record ([J 90.05.02]): the number, three
/// words of name and triggers, then RATE, DATE, EXEMPTIONS, GROSS,
/// RETIREMENT, INSURANCE, FICA, WHT, BONDEDUCTION, BONDACCUMULATION and
/// BONDENOMINATION. Statement 209 overwrites DATE before anything
/// prints it, and the report prints none of the other four totals, so
/// each of those is blank or zero.
List<int> _masterWords(Master master) {
  final String name = master.name.padRight(18);
  return <int>[
    _characters(master.number),
    for (var i = 0; i < 18; i += 6) _characters(name.substring(i, i + 6)),
    master.rate,
    _characters(''),
    master.exemptions,
    0,
    0,
    0,
    master.ficaYtd,
    0,
    master.bondDeduction,
    master.bondAccumulation,
    master.bondDenomination,
  ];
}

/// The word of the six Set H glyphs [text], blank-padded (D0.6).
int _characters(String text) {
  var word = 0;
  for (final String glyph in text.padRight(6).split('')) {
    word = (word << 6) | bcdFromGlyph(glyph)!;
  }
  return word;
}
