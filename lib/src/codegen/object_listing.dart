/// The object listing's symbolic pages (M4-8).
///
/// The geometry is the one the page scans carry: M4-20 item (g) records
/// it, and a second pass confirmed every column 2026-08-05 against the
/// character grid of PDF pp. 199–200. The 90.05 transcription renders
/// these pages in two other column conventions, and both are artifacts
/// of the transcription passes. The transcription therefore supplies
/// content here and never geometry.
library;

import '../listing/listing.dart';
import 'text_model.dart';

/// Print columns, counted from the LOC column's first digit as zero.
const int _loc = 0;
const int _octal = 7;
const int _control = 25;
const int _label = 34;
const int _operation = 49;
const int _operand = 56;

/// The `+n` offset is right-aligned, its last character here.
const int _offsetEnd = 42;

/// The label field spans [_label] through [_offsetEnd] and on to the
/// column before [_operation]. A name that fills it leaves no space
/// before the operation, and so prints alone (M4-8).
const int _labelWidth = _operation - _label;

/// [value] as the five octal digits a LOC or address column prints.
String _octal5(int value) => value.toRadixString(8).padLeft(5, '0');

/// One line with every field at its measured column. An omitted field
/// prints nothing and takes no column.
///
/// The caller decides when a long label pushes the instruction to its own
/// line, and calls this twice.
String _objectListingLine({
  String loc = '',
  String octal = '',
  String control = '',
  String label = '',
  String offset = '',
  String operation = '',
  String operand = '',
}) => _line([
  (_loc, loc),
  (_octal, octal),
  (_control, control),
  (_label, label),
  (_offsetEnd - offset.length + 1, offset),
  (_operation, operation),
  (_operand, operand),
]).trimRight();

/// The `LOC OCTAL CNTRL SYMBOLIC` header, which prints once on the first
/// object page (M4-8 as amended 2026-08-09).
String _objectListingHeader() => _line([
  (1, 'LOC'),
  (12, 'OCTAL'),
  (25, 'CNTRL'),
  (58, 'SYMBOLIC'),
]).trimRight();

/// One line with each text placed at its column. A field that has
/// already run past the next column is separated from it by one space.
String _line(List<(int, String)> fields) {
  final out = StringBuffer();
  for (final (int column, String text) in fields) {
    if (text.isEmpty) {
      continue;
    }
    out
      ..write(out.length > column ? ' ' : ' ' * (column - out.length))
      ..write(text);
  }
  return out.toString();
}

/// Renders [units] as object-listing lines.
///
/// The `+n` offset counts units since the last unit that prints none,
/// so it is a listing artifact and never an address offset (M4-20 item
/// d): the word after an unlabelled `BSS 2` prints `+1`.
List<String> renderObjectLines(Iterable<AssemblyUnit> units) {
  final out = <String>[];
  var offset = 0;
  for (final unit in units) {
    final bool resets =
        unit.labels.isNotEmpty || resettingOperations.contains(unit.operation);
    if (resets) {
      offset = 0;
    } else {
      offset++;
    }
    out.addAll(_unit(unit, resets ? '' : '+$offset'));
  }
  return out;
}

/// Renders the printed document that follows the source pages (M4-8;
/// M4-16), numbered from [firstPage] — page 7 in the sample, after six
/// source pages: the loader-card page, the object pages, and the
/// closing lines.
///
/// Every page holds 58 print lines (measured across pages 7 to 25 of
/// the scan): the head, two blank lines, and 55 content lines; the
/// first object page spends three of its content lines on a blank, the
/// column header, and a blank. The loader-card page's content is its
/// message line, a blank, and one line per card in [loaderCards]. The
/// object pages end at the end-of-text line, then one blank and the
/// three closing lines: the deck writer's, not the listing
/// formatter's, which is why they leave its margin — the message lines
/// and the cards print from six columns left of the LOC column, `DONE`
/// from five (M4-8 as amended). The pagination is mechanical — no row
/// breaks a page early.
String writeObjectListing(
  List<AssemblyUnit> units, {
  required List<String> loaderCards,
  required String lastCard,
  required ListingOptions options,
  required String id,
  required int firstPage,
}) {
  const margin = '        ';
  const cardMargin = '  ';
  final loader = <String>[
    '${cardMargin}THE FOLLOWING LOADER CONTROL CARDS PRECEDE THE BINARY DECK.',
    '',
    for (final String card in loaderCards) '$cardMargin$card',
  ];
  final object = <String>[
    for (final String line in renderObjectLines(units)) '$margin$line',
    '',
    '${cardMargin}THE LAST LOADER CONTROL CARD PUNCHED IS',
    '$cardMargin$lastCard',
    '   DONE',
  ];
  final out = StringBuffer();
  final int page = _pages(out, loader, options, id, firstPage, header: '');
  _pages(
    out,
    object,
    options,
    id,
    page,
    header: '$margin${_objectListingHeader()}',
  );
  return out.toString();
}

/// Writes [lines] as pages from [firstPage] and returns the page number
/// after the last. A non-empty [header] prints on the first page,
/// between two blank lines.
int _pages(
  StringBuffer out,
  List<String> lines,
  ListingOptions options,
  String id,
  int firstPage, {
  required String header,
}) {
  var line = 0;
  var page = firstPage;
  for (; line < lines.length; page++) {
    out
      ..writeln(listingPageHead(options, id: id, page: page))
      ..writeln()
      ..writeln();
    var slots = 55;
    if (header.isNotEmpty && page == firstPage) {
      out
        ..writeln()
        ..writeln(header)
        ..writeln();
      slots = 52;
    }
    for (var n = 0; n < slots && line < lines.length; n++, line++) {
      out.writeln(lines[line].trimRight());
    }
  }
  return page;
}

List<String> _unit(AssemblyUnit unit, String offset) {
  final int? location = unit.location;
  final int? word = unit.word;
  final int? control = unit.control;
  final String loc = location == null ? '' : _octal5(location);
  final String octal = word == null ? '' : octalColumn(word, unit.form);
  final String cntrl = control == null ? '' : controlColumn(control);

  final out = <String>[];
  // Every label but the last prints alone against the LOC, the word
  // falling to the last (M4-8; the attested GN)000 over START).
  for (var i = 0; i + 1 < unit.labels.length; i++) {
    out.add(_objectListingLine(loc: loc, label: unit.labels[i]));
  }
  final String label = unit.labels.isEmpty ? '' : unit.labels.last;
  if (label.length >= _labelWidth) {
    out
      ..add(
        _objectListingLine(
          loc: loc,
          octal: octal,
          control: cntrl,
          label: label,
          offset: offset,
        ),
      )
      ..add(
        _objectListingLine(operation: unit.operation, operand: unit.operand),
      );
  } else {
    out.add(
      _objectListingLine(
        loc: loc,
        octal: octal,
        control: cntrl,
        label: label,
        offset: offset,
        operation: unit.operation,
        operand: unit.operand,
      ),
    );
  }
  return out;
}
