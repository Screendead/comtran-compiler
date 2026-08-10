/// Builds the object-listing target of the 90.05 sample — the M4 stage 2
/// oracle under construction (M4-1 chunk A1).
///
/// The target holds the transcription's *content* in the M4-8 *geometry*.
/// The transcription renders these pages in two column conventions, and
/// both are artifacts of its own passes, so this library reads the fields
/// out of them and places each at its scan-measured column. It changes
/// spacing and nothing else.
///
/// The target is scaffolding, not a second oracle: chunk B7 deletes it
/// once the golden carries the whole object listing (M4-8 as amended).
library;

import 'package:comtran/src/codegen/object_listing.dart';

/// The transcription this library reads.
const String objectListingSource =
    'comtran-manuals/J28-6169/90.05-sample-program.md';

/// The target `tool/generate_object_listing_target.dart` writes.
const String objectListingTarget = 'test/fixtures/90.05-object-listing.target';

/// Where the transcription puts each field, once a block's own left
/// margin is removed. Neither set is print geometry; both are the
/// transcription artifacts M4-8 records. The label and operation columns
/// separate a label from a mnemonic; the rest locate a token's field.
typedef _Anchors = ({int octal, int control, int label, int operation});

/// Listing pages 8 to 16, PDF pp. 199 to 207.
const _Anchors _earlyPages = (octal: 11, control: 29, label: 38, operation: 54);

/// Listing pages 17 to 25, PDF pp. 208 to 216.
const _Anchors _latePages = (octal: 7, control: 25, label: 32, operation: 44);

final RegExp _fence = RegExp(r'^\s*```\s*$');
final RegExp _pageHead = RegExp(r'^DATE \d\d/\d\d/\d\d.*PAGE +(\d+)$');
final RegExp _offset = RegExp(r'^\+\d+$');

/// The three closing lines (M4-8). They sit off the object grid, and the
/// conversion already carries the card columns measured for `*CTEND`.
final RegExp _trailer = RegExp(r'^(THE |\*CTEND|DONE$)');

/// A token is a run of non-blanks that may hold single blanks, so each
/// spaced OCTAL form — `OOOO FF T AAAAA` and `P DDDDD T AAAAA` — is one
/// token. Two blanks separate two fields.
final RegExp _token = RegExp(r'\S(?:\S| (?! ))*');

/// The blank lines a page prints between its head and its first content
/// line, for each page a scan pass has measured (M4-1 chunks A2 to A8).
///
/// The transcription's own counts are not evidence. M4-8 records that it
/// holds one blank on every object page but PDF p. 208, and every page
/// measured since holds more. A page absent from this map is not
/// verified yet and keeps the count the transcription holds.
/// `test/fixtures/90.05-object-listing-notes.md` holds each measurement.
///
/// Listing page 8 is the one page that prints the column header, and it
/// is the one page whose head is followed by three blanks, not two.
const Map<int, int> _measuredBlanksAfterHead = <int, int>{
  8: 3,
  9: 2,
  10: 2,
  11: 2,
  12: 2,
  13: 2,
  14: 2,
  15: 2,
  16: 2,
  17: 2,
  18: 2,
  19: 2,
  21: 2,
};

/// The 18 object pages of [sourceLines], every field at its measured
/// column.
List<String> buildObjectListingTarget(List<String> sourceLines) {
  final Map<int, List<String>> pages = _objectPages(sourceLines);
  return <String>[
    for (final page in pages.keys.toList()..sort())
      ..._render(
        _blanks(_dedent(pages[page]!), _measuredBlanksAfterHead[page]),
        page <= 16 ? _earlyPages : _latePages,
      ),
  ];
}

/// Sets the run of blank lines after [page]'s head to [measured]. A page
/// with no measurement keeps what the transcription holds.
List<String> _blanks(List<String> page, int? measured) {
  if (measured == null) {
    return page;
  }
  var first = 1;
  while (first < page.length && page[first].trim().isEmpty) {
    first++;
  }
  return <String>[
    page.first,
    ...List<String>.filled(measured, ''),
    ...page.sublist(first),
  ];
}

/// The same pages as the transcription holds them, in the same order.
List<String> objectListingSourceLines(List<String> sourceLines) {
  final Map<int, List<String>> pages = _objectPages(sourceLines);
  return <String>[
    for (final page in pages.keys.toList()..sort()) ...pages[page]!,
  ];
}

/// The fenced blocks holding listing pages 8 to 25, keyed by the page
/// number their own head prints. Pages 1 to 6 are the source listing, and
/// page 7 is the loader control cards, which carry no LOC/OCTAL/CNTRL
/// grid and which stage 3 generates (M4-1).
Map<int, List<String>> _objectPages(List<String> lines) {
  final pages = <int, List<String>>{};
  List<String>? open;
  for (final line in lines) {
    if (_fence.hasMatch(line)) {
      if (open == null) {
        open = <String>[];
      } else {
        final int? page = _pageNumber(open);
        if (page != null && page >= 8 && page <= 25) {
          pages[page] = open;
        }
        open = null;
      }
      continue;
    }
    open?.add(line);
  }
  if (pages.length != 18) {
    throw StateError('expected 18 object pages, found ${pages.length}');
  }
  return pages;
}

int? _pageNumber(List<String> block) {
  for (final line in block) {
    final RegExpMatch? head = _pageHead.firstMatch(line.trim());
    if (head != null) {
      return int.parse(head.group(1)!);
    }
  }
  return null;
}

/// Removes a block's common left margin. The transcription flattens the
/// head-to-body margin (M1-15), so the margin carries no print fact and
/// the block's own grid starts at its first column.
List<String> _dedent(List<String> block) {
  final int margin = block
      .where((line) => line.trim().isNotEmpty)
      .map((line) => line.length - line.trimLeft().length)
      .reduce((a, b) => a < b ? a : b);
  return block
      .map((line) => line.trim().isEmpty ? '' : line.substring(margin))
      .toList();
}

List<String> _render(List<String> page, _Anchors anchors) =>
    page.map((line) => _line(line, anchors)).toList();

String _line(String line, _Anchors anchors) {
  if (line.trim().isEmpty) {
    return '';
  }
  if (_pageHead.hasMatch(line)) {
    return line.trimRight();
  }
  if (line.trimLeft().startsWith('LOC ')) {
    return objectListingHeader();
  }
  if (_trailer.hasMatch(line)) {
    return line.trimRight();
  }
  return _unit(line, anchors);
}

String _unit(String line, _Anchors anchors) {
  final List<({int column, String text})> tokens = _token
      .allMatches(line)
      .map((m) => (column: m.start, text: m.group(0)!))
      .toList();

  var loc = '';
  var octal = '';
  var control = '';
  var next = 0;
  if (tokens[next].column < anchors.octal - 1) {
    loc = tokens[next++].text;
  }
  if (next < tokens.length && _near(tokens[next].column, anchors.octal)) {
    octal = tokens[next++].text;
  }
  if (next < tokens.length && _near(tokens[next].column, anchors.control)) {
    control = tokens[next++].text;
  }

  final List<({int column, String text})> tail = tokens.sublist(next);
  var label = '';
  var offset = '';
  var rest = 0;
  if (tail.isNotEmpty) {
    if (_offset.hasMatch(tail[0].text)) {
      offset = tail[rest++].text;
    } else if (_closerToLabel(tail[0].column, anchors)) {
      label = tail[rest++].text;
    }
  }
  final String operation = rest < tail.length ? tail[rest++].text : '';
  final String operand = rest < tail.length ? tail[rest++].text : '';
  if (rest != tail.length) {
    throw StateError('unassigned field in: $line');
  }

  return objectListingLine(
    loc: loc,
    octal: octal,
    control: control,
    label: label,
    offset: offset,
    operation: operation,
    operand: operand,
  );
}

/// The transcription's own columns drift by up to half a character cell
/// (M4-20 item g), so a field is recognised within one column of its
/// anchor.
bool _near(int column, int anchor) => (column - anchor).abs() <= 1;

bool _closerToLabel(int column, _Anchors anchors) =>
    (column - anchors.label).abs() <= (column - anchors.operation).abs();
