import 'dart:io';

import 'package:test/test.dart';

import '../tool/object_listing_target_source.dart';

/// A line's content, with every run of blanks reduced to one separator.
List<String> _words(String line) {
  final String trimmed = line.trim();
  return trimmed.isEmpty ? const <String>[] : trimmed.split(RegExp(r'\s+'));
}

void main() {
  final List<String> source = File(objectListingSource).readAsLinesSync();
  final List<String> committed = File(objectListingTarget).readAsLinesSync();

  group('the object-listing target (M4-1 chunk A1)', () {
    test('is fresh', () {
      expect(buildObjectListingTarget(source), committed);
    });

    test('changes the spacing of the transcription and nothing else', () {
      final List<String> original = objectListingSourceLines(source);
      expect(committed.length, original.length);
      for (var i = 0; i < original.length; i++) {
        expect(
          _words(committed[i]),
          _words(original[i]),
          reason: 'line ${i + 1}',
        );
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
}
