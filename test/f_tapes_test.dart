/// The committed input tapes of the applied 1960 deck: the generator
/// rebuilds both images and the bytes must match, each image carries the
/// BLOCKSIZE 14 the deck declares, and the lister prints each record as
/// its 80 characters.
library;

import 'dart:io';

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

import '../tool/f_tapes_source.dart';
import '../tool/sample_tapes_source.dart' show characterWord;
import 'support/deck_fixtures.dart';

List<int> imageOf(String unit) =>
    File('$fTapesPath/$unit.tap').readAsBytesSync();

/// The blocks of the image [unit] holds. The reader throws for an image
/// that ends with no file mark, so a listing of blocks proves one.
List<List<int>> blocksOf(String unit) {
  final reader = TapeReader(imageOf(unit));
  final blocks = <List<int>>[];
  for (List<int>? block = reader.read(); block != null; block = reader.read()) {
    blocks.add(block);
  }
  return blocks;
}

/// The field of [line] at the 1-based record columns [from] to [to].
String field(String line, int from, int to) =>
    line.padRight(recordChars).substring(from - 1, to);

void main() {
  test('the committed images are the ones the generator writes', () {
    // Run `dart run tool/generate_f_tapes.dart` after any edit to either
    // source table.
    expect(imageOf('D1'), fMasterImage());
    expect(imageOf('C2'), fDetailImage());
  });

  test(
    'D1 holds 25 masters and C2 14 details, in blank-filled 14-word blocks',
    () {
      final List<List<int>> masters = blocksOf('D1');
      final List<List<int>> details = blocksOf('C2');
      expect(masters, hasLength(25));
      expect(details, hasLength(14));
      for (final block in <List<int>>[...masters, ...details]) {
        expect(block, hasLength(blockWords));
        // The four characters after the 80 of the record are blank.
        expect(block.last & 0xFFFFFF, characterWord('') & 0xFFFFFF);
      }
    },
  );

  group('the lister prints each record', () {
    final List<String> masters = listTape(imageOf('D1')).toList();
    final List<String> details = listTape(imageOf('C2')).toList();

    test('one line a record, none past 80 characters', () {
      expect(masters, hasLength(25));
      expect(details, hasLength(14));
      for (final line in <String>[...masters, ...details]) {
        expect(line.length, lessThanOrEqualTo(recordChars));
      }
    });

    test('a master carries the sample values in the 1960 columns', () {
      final String woo = masters[23];
      expect(field(woo, 1, 1), ' ');
      expect(field(woo, 2, 7), '091980');
      expect(field(woo, 8, 22), 'WOO J          ');
      expect(field(woo, 23, 27), '12000');
      expect(field(woo, 28, 33), '      ');
      expect(field(woo, 34, 35), '01');
      expect(field(woo, 36, 52), '0' * 17);
      expect(field(woo, 53, 57), '14400');
      expect(field(woo, 58, 63), '000000');
      expect(field(woo, 64, 67), '1700');
      expect(field(woo, 68, 72), '02050');
      expect(field(woo, 73, 77), '03750');
      expect(field(masters[0], 2, 22), '011001AJAX T         ');
      expect(field(masters[0], 23, 77), '00000${' ' * 6}${'0' * 44}');
    });

    test('a matched detail carries its master name and deduction', () {
      final String woo = details[12];
      expect(field(woo, 1, 4), ' 390');
      expect(field(woo, 5, 10), '091980');
      expect(field(woo, 11, 25), 'WOO J          ');
      expect(field(woo, 26, 31), '100661');
      expect(field(woo, 32, 33), '01');
      expect(field(woo, 34, 61), '0' * 28);
      expect(field(woo, 62, 65), '1700');
      expect(field(woo, 66, 75), '0' * 10);
    });

    test('an unmatched detail carries a blank name and zeros', () {
      expect(details[4], ' 400061500${' ' * 15}100661${'0' * 44}');
    });
  });
}
