/// The committed input tapes of the 90.05 sample (M6-3): the generator
/// rebuilds both images and the bytes must match, and each image carries
/// the blocking the manual describes.
library;

import 'dart:io';

import 'package:test/test.dart';

import '../tool/sample_tapes_source.dart';
import 'runtime/runtime_support.dart';
import 'support/deck_fixtures.dart';

List<List<int>> blocksOf(String unit) =>
    tapeBlocks(File('$sampleTapesPath/$unit.tap').readAsBytesSync());

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
