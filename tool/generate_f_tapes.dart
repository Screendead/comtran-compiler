/// Writes the two input tapes of the 1960 applied payroll deck. Run from
/// the repository root:
///
///     dart run tool/generate_f_tapes.dart
///
/// The images are committed, because `comtranc --run --tapes=DIR` reads
/// a directory and a reader of the repository runs the deck with no
/// generator step.
library;

import 'dart:io';

import 'f_tapes_source.dart';
import 'sample_tapes_source.dart';

void main() {
  final tapes = Directory('test/fixtures/f-payroll-tapes')
    ..createSync(recursive: true);
  File('${tapes.path}/D1.tap').writeAsBytesSync(fMasterImage());
  File('${tapes.path}/C2.tap').writeAsBytesSync(fDetailImage());
  stdout.writeln(
    'wrote ${masters.length} master records and ${details.length} details',
  );
}
