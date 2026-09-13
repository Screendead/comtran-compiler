/// The committed input tapes of the 90.05 sample (M6-3): the generator
/// rebuilds both images and the bytes must match, and each image carries
/// the blocking the manual describes.
library;

import 'dart:io';

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

import '../tool/sample_tapes_source.dart';
import 'support/deck_fixtures.dart';

/// The blocks of the image [unit] holds. The reader throws for an image
/// that ends with no file mark, so a listing of blocks proves one.
List<List<int>> blocksOf(String unit) {
  final reader = TapeReader(
    File('$sampleTapesPath/$unit.tap').readAsBytesSync(),
  );
  final blocks = <List<int>>[];
  for (List<int>? block = reader.read(); block != null; block = reader.read()) {
    blocks.add(block);
  }
  return blocks;
}

void main() {
  test('the committed images are the ones the generator writes', () {
    // Run `dart run tool/generate_sample_tapes.dart` after any edit to
    // the reconstruction table.
    expect(File('$sampleTapesPath/D1.tap').readAsBytesSync(), masterImage());
    expect(File('$sampleTapesPath/C2.tap').readAsBytesSync(), detailImage());
  });

  test('D1 blocks 25 master records 20 to a block ([J 90.05.02])', () {
    expect(blocksOf('D1').map((List<int> block) => block.length), <int>[
      300,
      75,
    ]);
  });

  test('C2 gives each detail record a 14-word block ([J 90.05.03])', () {
    final List<List<int>> blocks = blocksOf('C2');
    expect(blocks, hasLength(14));
    expect(blocks.map((List<int> block) => block.length), everyElement(14));
  });
}
