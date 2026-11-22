// Makes SYSUT4 for SUBUP from a CT punch tape (M7-7 in
// docs/design/m7-diff.md). It drops chosen *CTEXT cards and rewrites every
// *CTEND card:
// - SUBUP reads the *CTEXT card of a typed *INSERT from the card reader,
//   and the rest of the deck from SYSUT4, so SYSUT4 must not hold that card.
// - SUBUP tests a *CTEND card on SYSUT4 with MASKS3 (SU023100, SU023160).
//   The mask is the complement of EVD, not END, so no punched *CTEND card
//   passes. Columns 10 to 12 of each *CTEND card get EVD, the characters
//   that the mask accepts.
//
// Usage: dart run tool/m7/ctext_drop.dart IN.BIN OUT.BIN K...
//   Each K is the ordinal, from 1, of a *CTEXT card on IN.BIN. Every other
//   record and file mark is copied byte for byte, except columns 10 to 12
//   of each *CTEND card. The tool prints the ordinal and the record number
//   of each *CTEXT card, and the count of *CTEND cards, and stops if a K is
//   not on the tape.
import 'dart:io';
import 'dart:typed_data';

// A punched control card is a record of 28 column-binary words, three
// columns to a word. SUBUP finds *CTEXT by columns 7 to 12 (SU022940 to
// SU023000): words 2 and 3 are the complements of MASKL3 and MASKR3
// (SU023140, SU023150).
final int _ct = int.parse('204241001100', radix: 8); // *CT
final int _ext = int.parse('402010041100', radix: 8); // EXT
final int _end = int.parse('402020204040', radix: 8); // END
final int _evd = int.parse('402020104040', radix: 8); // EVD, ~MASKS3

void main(List<String> args) {
  if (args.length < 3) {
    stderr.writeln('usage: ctext_drop.dart IN.BIN OUT.BIN K...');
    exit(64);
  }
  final Set<int> drop = {for (final a in args.skip(2)) int.parse(a)};
  final Uint8List bytes = File(args[0]).readAsBytesSync();
  // s709 BIN images hold one 6-bit character per byte, and bit 0200 marks
  // the first character of a record. A file mark is a record of one byte.
  final List<int> starts = [
    for (var i = 0; i < bytes.length; i++)
      if (bytes[i] & 0x80 != 0) i,
    bytes.length,
  ];
  int word(int start, int w) {
    var v = 0;
    for (var c = 0; c < 6; c++) {
      v = (v << 6) | (bytes[start + w * 6 + c] & 0x3f);
    }
    return v;
  }

  final out = BytesBuilder();
  var ordinal = 0;
  var ctend = 0;
  for (var r = 0; r + 1 < starts.length; r++) {
    final int s = starts[r];
    final int e = starts[r + 1];
    final bool ctext = e - s == 168 && word(s, 2) == _ct && word(s, 3) == _ext;
    if (ctext) {
      ordinal++;
      final bool gone = drop.remove(ordinal);
      stdout.writeln('$ordinal  record $r  ${gone ? 'dropped' : 'kept'}');
      if (gone) {
        continue;
      }
    }
    final Uint8List record = bytes.sublist(s, e);
    if (e - s == 168 && word(s, 2) == _ct && word(s, 3) == _end) {
      ctend++;
      // Bit 0100 is the parity bit: keep the parity of the record.
      final bool odd = _ones(record[0] & 0x7f).isOdd;
      for (var c = 0; c < 6; c++) {
        final int ch = (_evd >> (30 - 6 * c)) & 0x3f;
        record[18 + c] = _ones(ch).isOdd == odd ? ch : ch | 0x40;
      }
    }
    out.add(record);
  }
  stdout.writeln('$ctend *CTEND cards rewritten');
  if (drop.isNotEmpty) {
    stderr.writeln('${args[0]}: no *CTEXT card ${drop.join(', ')}');
    exit(1);
  }
  File(args[1]).writeAsBytesSync(out.toBytes());
}

int _ones(int v) => v == 0 ? 0 : (v & 1) + _ones(v >> 1);
