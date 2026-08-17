/// The chunk B1 and B2 oracle (M4-1, M4-9): the object listing matched
/// column by column against the verified target.
///
/// The comparison is monotone. B1 sizes every unit and binds it to an
/// address, so the LOC column and the label zone are read on every line.
/// A verb generator then fills the OCTAL, operation and operand columns
/// of the lines it owns, and those columns are read on exactly those
/// lines. Each later chunk adds lines to the second test and raises its
/// count; no chunk relaxes a column an earlier one won (M4-8).
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The scan-verified target: listing pages 8 to 25, PDF pp. 199 to 216,
/// the transcription's content in the M4-8 geometry.
const String _targetPath = 'test/fixtures/90.05-object-listing.target';

/// Page furniture, which chunk B7 lays out and B1 does not emit: the
/// page head, the blank lines under it, the column header, and the three
/// closing lines the loader writes rather than the listing formatter
/// (M4-8 as amended, chunk A8).
bool _isFurniture(String line) =>
    line.trim().isEmpty ||
    line.startsWith('DATE ') ||
    line.startsWith(' LOC ') ||
    line.startsWith('THE ') ||
    line.startsWith('*CTEND') ||
    line == 'DONE';

String _slice(String line, int from, [int? to]) {
  if (line.length <= from) {
    return '';
  }
  final int end = to == null || to > line.length ? line.length : to;
  return line.substring(from, end);
}

/// Whether [line] is an over-long name, which fills the 15-column label
/// field and pushes its instruction to the next line (M4-8.1). The LOC
/// and OCTAL columns stay with the name.
bool _wrapped(String line) {
  final String zone = _slice(line, 34, 49);
  return zone.length == 15 && !zone.endsWith(' ');
}

/// The LOC field of line [i], then the name zone verbatim.
///
/// LOC is five octal digits, or empty where the line prints none: a
/// `USE` discontinuity, or the second line of a wrapped name. The zone
/// is the 15-column label field, which holds every name B1 binds and
/// every `+n` offset, byte for byte — so it tests which name each word
/// took and how the offset is aligned, which the LOC column alone
/// cannot (M4-20 item d; M4-6).
String _spineField(List<String> lines, int i) =>
    '${_slice(lines[i], 0, 5).trim()} ${_slice(lines[i], 34, 49).trimRight()}';

/// The mnemonic line [i] prints, empty where it prints none. What
/// follows a wrapped name is the rest of the name, not an operation.
String _operation(List<String> lines, int i) =>
    _wrapped(lines[i]) ? '' : _slice(lines[i], 49, 56).trim();

/// The symbolic columns of line [i]: the mnemonic and the operand
/// together, from the operation column to the end of the line (M4-8).
String _symbolicField(List<String> lines, int i) =>
    _slice(lines[i], 49).trimRight();

/// The OCTAL zone of line [i]'s instruction, read from the line above
/// where a wrapped name took it. The zone stops at column 25, where
/// CNTRL begins: the loader control field is stage 3's (M4-16).
String _octalField(List<String> lines, int i) => _slice(
  lines[i > 0 && _wrapped(lines[i - 1]) ? i - 1 : i],
  7,
  25,
).trimRight();

/// Operations B1 places whose operand a later chunk fills: the entry
/// point belongs to stage 3.
///
/// An `EQU` carries no object word, so its operand is the only column a
/// chunk can fill, and the filter reads one only once it is filled: B3
/// owns the two subscript equates and B5 the loop and DO equates.
const Set<String> _laterChunks = <String>{'START'};

List<String> _generate() {
  final SemanticResult semantics = compileDeck(
    loadJobDeck(),
  ).jobs.single.semantics!;
  return renderObjectLines(runCodegen(semantics).units);
}

List<String> _target() => File(
  _targetPath,
).readAsLinesSync().where((String line) => !_isFurniture(line)).toList();

void main() {
  late List<String> generated;
  late List<String> target;

  setUpAll(() {
    generated = _generate();
    target = _target();
  });

  /// Reports the first divergence alone: the listing is continuous, so
  /// every later one is its consequence. Returns the lines it read.
  int compare(
    String Function(List<String>, int) field, {
    required bool Function(List<String>, int) filled,
  }) {
    var read = 0;
    for (var i = 0; i < generated.length && i < target.length; i++) {
      if (!filled(generated, i)) {
        continue;
      }
      read++;
      if (field(generated, i) != field(target, i)) {
        final int from = i < 4 ? 0 : i - 4;
        final List<String> context = [
          for (var j = from; j <= i; j++) field(target, j),
        ];
        fail(
          'line ${i + 1}: generated "${field(generated, i)}", '
          'target "${field(target, i)}"\n'
          'target context: ${context.join(' / ')}',
        );
      }
    }
    expect(generated, hasLength(target.length));
    return read;
  }

  test('every line carries the location the 1962 listing printed', () {
    compare(_spineField, filled: (_, _) => true);
  });

  // The two counts below rise with each verb chunk and can never fall,
  // so a column that stops being generated fails here rather than
  // passing unread.

  test('every mnemonic and operand is the one the 1962 listing printed', () {
    expect(
      compare(
        _symbolicField,
        filled: (List<String> lines, int i) {
          final String operation = _operation(lines, i);
          if (operation.isEmpty || _laterChunks.contains(operation)) {
            return false;
          }
          return operation != 'EQU' || _symbolicField(lines, i) != 'EQU';
        },
      ),
      900,
    );
  });

  test('every generated word is the one the 1962 listing printed', () {
    expect(
      compare(
        _octalField,
        filled: (List<String> lines, int i) =>
            _octalField(lines, i).isNotEmpty && !_wrapped(lines[i]),
      ),
      894,
    );
  });
}
