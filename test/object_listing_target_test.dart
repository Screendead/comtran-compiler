import 'dart:io';

import 'package:test/test.dart';

import '../tool/object_listing_target_source.dart';

/// A line's content, with every run of blanks reduced to one separator.
List<String> _words(String line) {
  final String trimmed = line.trim();
  return trimmed.isEmpty ? const <String>[] : trimmed.split(RegExp(r'\s+'));
}

/// The lines that carry an object word or a pseudo-operation. The page
/// heads, the column header, the blanks, and the three closing lines
/// carry none.
List<String> _units(List<String> target) => target
    .where((l) => l.trim().isNotEmpty)
    .where((l) => !l.startsWith('DATE ') && !l.contains('SYMBOLIC'))
    .where((l) => !RegExp(r'^(THE |\*CTEND|DONE$)').hasMatch(l))
    .toList();

/// A line's [start] to [end] columns. A line that ends before a column
/// prints nothing there.
String _column(String line, int start, int end) => start >= line.length
    ? ''
    : line.substring(start, end.clamp(0, line.length)).trim();

/// The four OCTAL renderings (M4-8 as amended). The fourth prints an
/// 18-bit mask as one group, where the others split a tag from an
/// address.
final List<RegExp> _octalForms = <RegExp>[
  RegExp(r'^[0-7]{12}$'),
  RegExp(r'^[0-7]{4} [0-7]{2} [0-7] [0-7]{5}$'),
  RegExp(r'^[0-7] [0-7]{5} [0-7] [0-7]{5}$'),
  RegExp(r'^[0-7]{4} [0-7]{2} [0-7]{6}$'),
];

void main() {
  final List<String> source = File(objectListingSource).readAsLinesSync();
  final List<String> committed = File(objectListingTarget).readAsLinesSync();

  group('the object-listing target (M4-1 chunk A1)', () {
    test('is fresh', () {
      expect(buildObjectListingTarget(source), committed);
    });

    test("changes the transcription's spacing and nothing else", () {
      final List<String> original = objectListingSourceLines(
        source,
      ).where((l) => l.trim().isNotEmpty).toList();
      final List<String> printed = committed
          .where((l) => l.trim().isNotEmpty)
          .toList();
      expect(printed.length, original.length);
      for (var i = 0; i < original.length; i++) {
        expect(
          _words(printed[i]),
          _words(original[i]),
          reason: 'line ${i + 1}',
        );
      }
    });

    // The transcription holds one blank line after every page head. Every
    // page measured against its scan holds more. Page 8 is the one page
    // that prints the column header, and it holds three.
    const measured = <int, (int, String)>{
      8: (3, ' LOC '),
      9: (2, '00060'),
      10: (2, '00200'),
      11: (2, '00264'),
      13: (2, '00441'),
      21: (2, '01324'),
    };

    int headOf(int page) =>
        committed.indexWhere((l) => l.endsWith('PAGE  $page'));

    test('carries the measured blank count on each verified page', () {
      for (final MapEntry<int, (int, String)> entry in measured.entries) {
        final (int blanks, String first) = entry.value;
        final int head = headOf(entry.key);
        expect(
          committed.sublist(head + 1, head + 1 + blanks),
          List<String>.filled(blanks, ''),
          reason: 'page ${entry.key}',
        );
        expect(
          committed[head + 1 + blanks],
          startsWith(first),
          reason: 'page ${entry.key}',
        );
      }
    });

    // The frame, not the content-line count, is what the four scans hold
    // in common (M4-8 as amended, chunk A3).
    test('ends every verified page in line slot 57', () {
      for (final int page in measured.keys) {
        final int head = headOf(page);
        expect(committed[head + 57].trim(), isNotEmpty, reason: 'page $page');
        expect(committed[head + 58], startsWith('DATE '), reason: 'page $page');
      }
    });

    test('holds all 18 object pages, 8 through 25', () {
      final List<String> heads = committed
          .where((l) => l.startsWith('DATE '))
          .toList();
      expect(heads, hasLength(18));
      expect(heads.first, endsWith('PAGE  8'));
      expect(heads.last, endsWith('PAGE  25'));
    });

    test('prints the column header once, at its measured columns', () {
      final List<String> headers = committed
          .where((l) => l.contains('SYMBOLIC'))
          .toList();
      expect(headers, hasLength(1));
      expect(headers.single.indexOf('LOC'), 1);
      expect(headers.single.indexOf('OCTAL'), 12);
      expect(headers.single.indexOf('CNTRL'), 25);
      expect(headers.single.indexOf('SYMBOLIC'), 58);
    });
  });

  // A field the generator put in the wrong column still holds the right
  // words, so the spacing test above cannot catch a misassignment. These
  // four read each field back out of its measured column and check what
  // the field is allowed to hold.
  group('the target decodes at its measured columns (M4-8)', () {
    final List<String> units = _units(committed);

    test('LOC holds five octal digits', () {
      for (final line in units) {
        final String loc = _column(line, 0, 5);
        if (loc.isNotEmpty) {
          expect(loc, matches(RegExp(r'^[0-7]{5}$')), reason: line);
        }
      }
    });

    test('CNTRL holds a five-digit control group', () {
      for (final line in units) {
        final String control = _column(line, 25, 34);
        if (control.isNotEmpty) {
          expect(control, matches(RegExp(r'^[01]{5}$')), reason: line);
        }
      }
    });

    test('OCTAL holds one of the four renderings', () {
      for (final line in units) {
        final String octal = _column(line, 7, 25);
        if (octal.isNotEmpty) {
          expect(
            _octalForms.any((f) => f.hasMatch(octal)),
            isTrue,
            reason: line,
          );
        }
      }
    });

    // The strongest check here: an offset misread as a label, or a label
    // misread as an offset, breaks the chain at once.
    test('the +n offset counts up and restarts after a line without one', () {
      int? previous;
      for (final line in units) {
        final String zone = _column(line, 34, 49);
        final int? offset = zone.startsWith('+')
            ? int.tryParse(zone.substring(1))
            : null;
        if (offset != null) {
          expect(offset, (previous ?? 0) + 1, reason: line);
        }
        previous = offset;
      }
    });
  });
}
