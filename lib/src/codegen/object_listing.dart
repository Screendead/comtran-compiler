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

/// Renders [units] as the printed object pages, numbered from
/// [firstPage] — page 8 in the sample, after six source pages and the
/// loader-card page.
///
/// Every page holds 58 print lines (measured across pages 8 to 25 of
/// the scan): the head, three blank lines, the column header and one
/// more blank on the first page, two blank lines on every later one,
/// and content in the rest. The LOC column prints at the head's DATE
/// column, eight columns in (M4-8). The pagination is mechanical — no
/// row breaks a page early. The document ends at the end-of-text line:
/// the three closing lines under it are the loader's, not this
/// formatter's, and land with the deck writer (M4-8 as amended).
String writeObjectListing(
  List<AssemblyUnit> units, {
  required ListingOptions options,
  required String id,
  required int firstPage,
}) {
  final List<String> lines = renderObjectLines(units);
  const margin = '        ';
  final out = StringBuffer();
  var line = 0;
  for (var page = firstPage; line < lines.length; page++) {
    out
      ..writeln(listingPageHead(options, id: id, page: page))
      ..writeln()
      ..writeln();
    var slots = 55;
    if (page == firstPage) {
      out
        ..writeln()
        ..writeln('$margin${_objectListingHeader()}')
        ..writeln();
      slots = 52;
    }
    for (var n = 0; n < slots && line < lines.length; n++, line++) {
      out.writeln('$margin${lines[line]}'.trimRight());
    }
  }
  return out.toString();
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
