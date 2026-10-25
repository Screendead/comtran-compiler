// Prints the word and byte of RATE, INSPREM and RETPREM inside the 1962
// sample's TABLE.ITEM, from our data map. Copy it to `probe/` in a
// checkout and run `dart run probe/bytes.dart`.
import 'dart:io';

import 'package:comtran/comtran_io.dart';

void main() {
  final job = compileDeck(
    decodeCanon(
      File('test/fixtures/90.05-payroll-job.ctd').readAsBytesSync(),
    ),
  ).jobs.first;
  for (final e in job.semantics!.semantics.entries) {
    final n = e.key.entry.name;
    if (n == 'RATE' || n == 'INSPREM' || n == 'RETPREM' || n == 'TABLE.ITEM') {
      print('$n word=${e.value.word} byte=${e.value.byte}');
    }
  }
}
