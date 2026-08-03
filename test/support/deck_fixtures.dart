/// Shared test fixtures: the 90.05 sample deck, and card builders for the
/// fixed-form Data Description and Environment Description divisions.
///
/// TSTC-10 found this material duplicated across five test files, with the
/// Data Description builder split into two divergent copies. This library
/// gives every test file one definition to import instead.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';

/// Path to the 90.05 canon deck fixture (J Appendix 90.05's compiled
/// payroll sample program), relative to the repository root.
const String payrollDeckPath = 'tests/90.05-payroll.ctdeck';

/// Decodes the 90.05 canon deck fixture into its punch-level card images.
List<CardImage> loadPayrollDeck() =>
    decodeCanon(File(payrollDeckPath).readAsBytesSync());

/// Numbers [lines] as a one-based [SourceCard] list: joins them with a
/// trailing newline, reads them through [mirrorToDeck], then wraps each
/// resulting [CardImage] with its 1-based deck position. This is the shape
/// every lexer and parser test builds its inline fixtures from.
///
/// Named `sourceCards`, not `cards`, because several call sites already use
/// `cards` as a local variable name for a parsed `List<...Card>` result.
List<SourceCard> sourceCards(List<String> lines) {
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return [for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1)];
}

/// Builds one Data Description Division card at its documented columns.
///
/// Column layout (definition §1.9.2; F p. 65; see
/// `lib/src/lexer/data_lexer.dart`): name 7–22, level 23–24, type 25–30,
/// quantity 31–35, mode 36, justification 37, description 38–71,
/// continuation flag 72.
String dataCard({
  String name = '',
  String level = '',
  String type = '',
  String quantity = '',
  String mode = '',
  String justify = '',
  String description = '',
  bool continued = false,
}) {
  final line =
      '${' ' * 6}${name.padRight(16)}${level.padLeft(2)}${type.padRight(6)}'
      '${quantity.padLeft(5)}${mode.padRight(1)}${justify.padRight(1)}'
      '${description.padRight(34)}${continued ? 'X' : ' '}';
  return line.trimRight();
}

/// Builds one Environment Description Division card at its documented
/// columns.
///
/// Column layout (definition §1.9.3; J 02.06.01;
/// `lib/src/lexer/environment_lexer.dart`): name 7–22, columns 23–24 belong
/// to no field, type 25–30, options 31–71, continuation flag 72.
///
/// [options] longer than 41 characters is not an error here — it silently
/// overruns the field: the excess lands on column 72 (read as a spurious
/// continuation flag) and beyond (never scanned, per J 02.03.01, §2.c).
/// Split a longer option list across two cards with `continued: true`.
String environmentCard({
  String name = '',
  String type = '',
  String options = '',
  bool continued = false,
}) {
  final line =
      '${' ' * 6}${name.padRight(16)}${' ' * 2}${type.padRight(6)}'
      '${options.padRight(41)}${continued ? 'X' : ' '}';
  return line.trimRight();
}

/// A blank 80-column punch array, ready for [punchGlyphs] and for direct
/// pokes of a punch code that carries no Set H glyph — an unreadable
/// "machine special" such as the record mark, or a punch combination with
/// no BCD readout at all. Character-gate tests (decision D9.10) build a
/// card this way because no [String] can express an unreadable punch.
List<int> blankColumns() => List<int>.filled(CardImage.columnCount, 0);

/// Punches [text] into [columns] as Set H glyphs, starting at 1-based
/// [column]. A blank character in [text] leaves its column unpunched, so
/// several fields can be painted onto one [columns] array in turn.
void punchGlyphs(List<int> columns, int column, String text) {
  for (var i = 0; i < text.length; i++) {
    if (text[i] != ' ') {
      columns[column - 1 + i] = punchesFromBcd(bcdFromGlyph(text[i])!)!;
    }
  }
}
