/// Writes the two input tapes of the 90.05 payroll sample. Run from the
/// repository root:
///
///     dart run tool/generate_sample_tapes.dart
///
/// The images are committed, because `comtranc --run --tapes=DIR` reads
/// a directory and a reader of the repository runs the sample with no
/// generator step (M6-3).
library;

import 'dart:io';

import 'sample_tapes_source.dart';

void main() {
  final tapes = Directory('test/fixtures/90.05-tapes')
    ..createSync(recursive: true);
  File('${tapes.path}/D1.tap').writeAsBytesSync(masterImage());
  File('${tapes.path}/C2.tap').writeAsBytesSync(detailImage());
  stdout.writeln(
    'wrote ${masters.length} master records and ${details.length} details',
  );
}
