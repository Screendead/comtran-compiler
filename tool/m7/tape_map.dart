// Prints the record map of an s709 binary tape image: file number, record
// number, word count, and the record name (the second word, in BCD).
//
// Usage: dart run tool/m7/tape_map.dart TAPE.BIN
import 'dart:io';
import 'dart:typed_data';

// s709 BIN images hold one 6-bit character per byte. Bit 0200 marks the
// first character of a record, and the byte 0217 alone is a file mark.
// Bit 0100 is even parity and carries no data.
const _bcd =
    r'0123456789#=@:>? ABCDEFGHI&.)[<]-JKLMNOPQR-$*];^ /STUVWXYZ+,(~\!';

void main(List<String> args) {
  final Uint8List bytes = File(args.single).readAsBytesSync();
  final records = <List<int>>[];
  for (final b in bytes) {
    if (b & 0x80 != 0) {
      records.add([]);
    }
    records.last.add(b & 0x3f);
  }
  var file = 0;
  var rec = 0;
  for (final r in records) {
    if (r.length == 1 && r[0] == 0x0f) {
      stdout.writeln('$file  -- file mark');
      file++;
      rec = 0;
      continue;
    }
    final int words = r.length ~/ 6;
    final String name = r.length >= 12
        ? r.sublist(6, 12).map((c) => _bcd[c]).join()
        : '';
    stdout.writeln('$file.$rec  $words  $name');
    rec++;
  }
}
