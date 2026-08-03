/// The compilation listing — the first observable compiler output (M1).
///
/// The layout follows the compiled sample (J 90.05 listing, PDF
/// pp. 192–197) as measured from the page scans: the page head with
/// DATE/TIME/ACCOUNT/ID./PAGE; the control-card echo printed from card
/// column 1 at the far-left margin with the phase letters under it
/// (J 05.06.01); source cards echoed verbatim with scan-anchored
/// geometry (M1-15): with D = the page head's DATE column, the serial
/// field sits at D+0..D+5, the statement number ends at D+14, and card
/// column 7 prints at D+24. The
/// five-octal-digit name-address column of the 1962 listing is
/// undocumented and stays blank — a recorded M1 decision. Diagnostics
/// form a separate block after the source listing (J 02.02.01; J 90.04),
/// cross-referenced by statement number; the message id itself is never
/// printed (decision D9.5).
library;

import '../lexer/diagnostic.dart';
import '../lexer/front_end.dart';
import '../lexer/source_card.dart';
import '../lexer/source_program.dart';

/// Options for one listing run. Date and time are the compiling run's
/// own; golden tests inject fixed values.
final class ListingOptions {
  /// Creates options; [date] as `mm/dd/yy`, [time] as decimal hours
  /// `h.hh` (the 1962 head prints `TIME  2.45`), both as printed in the
  /// page head.
  const ListingOptions({
    required this.date,
    required this.time,
    this.account = '',
    this.title = '',
    this.linesPerPage = 55,
  });

  /// The DATE field of the page head.
  final String date;

  /// The TIME field of the page head.
  final String time;

  /// The ACCOUNT field; blank in the sample.
  final String account;

  /// An optional title line above page 1 (the sample's operator title is
  /// `COMPILATION OF SAMPLE PROBLEM`; it is not compiler-fixed).
  final String title;

  /// Content lines per page. Every page of the 1962 listing carries 55
  /// content lines after the head (counted across all 25 printer pages
  /// of the sample).
  final int linesPerPage;
}

/// Renders the listing for [result]. When [diagnostics] is given it
/// replaces `result.diagnostics` as the printed block — the M2 driver
/// passes the merged front-end-plus-parser list (`ParseResult`,
/// design note M2-2); with `null` the front end's own list prints.
String writeListing(
  FrontEndResult result,
  ListingOptions options, {
  List<Diagnostic>? diagnostics,
}) => _ListingWriter(result, options, diagnostics).write();

final class _ListingWriter {
  _ListingWriter(this.result, this.options, List<Diagnostic>? diagnostics)
    : diagnostics = diagnostics ?? result.diagnostics {
    for (final Diagnostic d in this.diagnostics) {
      final SourceCard? card = d.card;
      if (d.message.number == '134,00' && d.column != null && card != null) {
        _repaired.putIfAbsent(card.cardNumber, () => <int>{}).add(d.column!);
      }
    }
  }

  final FrontEndResult result;
  final ListingOptions options;

  /// The diagnostics the listing prints.
  final List<Diagnostic> diagnostics;

  /// The highest severity in [diagnostics], or 0 with none.
  int get _maxSeverity => diagnostics.isEmpty
      ? 0
      : diagnostics
            .map((Diagnostic d) => d.severity)
            .reduce((int a, int b) => a > b ? a : b);

  /// Columns replaced by the character gate, per card — printed as `$`
  /// in the external text (decision D9.10).
  final Map<int, Set<int>> _repaired = {};

  final StringBuffer _out = StringBuffer();
  int _page = 0;
  int _linesOnPage = 0;

  String write() {
    _newPage();
    final SourceCard? compileCard = result.program.compileCard;
    if (compileCard != null) {
      // The control card is echoed from card column 1 at the far-left
      // margin, and the phase letters print under it (J 05.06.01).
      _line('  ${_externalBody(compileCard, 1, 72).trimRight()}');
      _line('  CTC');
    }
    final Map<int, Division> divisionOf = {
      for (final DivisionGroup group in result.program.groups)
        for (final SourceCard card in group.cards)
          card.cardNumber: group.division,
    };
    for (final SourceCard card in result.program.cards) {
      if (identical(card, compileCard)) {
        // The compile card is echoed above. The *FINISH card never
        // reaches the front end — the job splitter consumes it — so
        // the listing stops at the last source card, as the sample
        // listing does (D11.1).
        continue;
      }
      _line(_sourceLine(card, divisionOf[card.cardNumber]));
    }
    _line('');
    _line('  CTD');
    _line('  CTE');
    _line('');
    _diagnosticBlock();
    return _out.toString();
  }

  String _sourceLine(SourceCard card, Division? division) {
    final String serial = card.serial.trimRight();
    final String number = result.numberedCards.contains(card.cardNumber)
        ? result.statementNumberByCard[card.cardNumber]!
        : '';
    // Data and Environment lines print with column 72 blanked — the
    // processor "replaces the contents of column 72 with a blank"
    // (J 02.03.01, §2.c), which is why the sample listing never shows a
    // continuation character. Procedure text reads through column 72.
    final lastColumn =
        division == Division.data || division == Division.environment ? 71 : 72;
    final String body = _externalBody(card, 7, lastColumn).trimRight();
    // Scan-anchored geometry (see m1-front-end.md M1-15): with D = the
    // page head's DATE column, a statement number ends at D+14, the
    // octal name-address field sits at D+18..D+22 (blank at M1), and
    // card column 7 prints at D+24. The serial field's position is a
    // reconstruction — every serial in the sample is blank.
    final line =
        '${' ' * 8}${serial.padRight(6)}  ${number.padLeft(7)}'
        '${' ' * 9}$body';
    return line.trimRight();
  }

  /// The external text of [card] columns [from]..[to]: the Set H glyph,
  /// `$` for a column the character gate repaired, `?` for any other
  /// machine character with no Set H glyph — in-literal specials,
  /// unscanned commentary, and unscanned fixed fields — the M1
  /// display-glyph choice of D0.6.
  String _externalBody(SourceCard card, int from, int to) {
    final Set<int> repaired = _repaired[card.cardNumber] ?? const <int>{};
    final buffer = StringBuffer();
    for (var column = from; column <= to; column++) {
      final String? glyph = card.glyphAt(column);
      if (glyph != null) {
        buffer.write(glyph);
      } else if (!card.isPunched(column)) {
        buffer.write(' ');
      } else {
        buffer.write(repaired.contains(column) ? r'$' : '?');
      }
    }
    return buffer.toString();
  }

  void _diagnosticBlock() {
    if (diagnostics.isEmpty) {
      // The line starts at the phase-letter margin (scan: it aligns
      // with CTD/CTE on page 197).
      _line('  NO ERRORS WERE DETECTED DURING COMPILATION');
      return;
    }
    _line('THE FOLLOWING ERRORS WERE DETECTED DURING COMPILATION-');
    _line('');
    _line('NUMBER   CODE   MESSAGE');
    _line('');
    for (final Diagnostic d in diagnostics) {
      // The NUMBER column carries the statement number; 9999,99 marks a
      // diagnostic not confined to a numbered statement — an unnumbered
      // card, or no card at all (J 02.02.01; decisions D9.5 and D11.3).
      // A clause-confined diagnostic prints the clause digits after the
      // comma (design note M2-6).
      final SourceCard? card = d.card;
      String number = card == null
          ? '9999,99'
          : result.statementNumberByCard[card.cardNumber] ?? '9999,99';
      if (d.clause != null && number.endsWith(',00')) {
        number =
            '${number.substring(0, number.length - 2)}'
            '${d.clause.toString().padLeft(2, '0')}';
      }
      final List<String> lines = d.text.split('\n');
      _line('${number.padLeft(7)}    ${d.severity}    ${lines.first}');
      lines.skip(1).forEach(_line);
    }
    if (_maxSeverity < 5) {
      _line('');
      _line('SEVERITY LIMIT WAS NOT REACHED');
    }
  }

  void _line(String text) {
    if (_linesOnPage >= options.linesPerPage) {
      _newPage();
    }
    _out.writeln(text.trimRight());
    _linesOnPage++;
  }

  void _newPage() {
    _page++;
    if (_page == 1 && options.title.isNotEmpty) {
      _out
        ..writeln('${' ' * 36}${options.title}')
        ..writeln();
    }
    _out
      ..writeln(_pageHead())
      ..writeln();
    _linesOnPage = 0;
  }

  String _pageHead() {
    final String id = result.program.compileCard == null
        ? ''
        : result.program.compileCard!.textRange(55, 72).trim();
    return '        DATE ${options.date}   TIME  ${options.time}   '
        'ACCOUNT ${options.account.padRight(19)}ID. ${id.padRight(23)}'
        'PAGE${'$_page'.padLeft(4)}';
  }
}
