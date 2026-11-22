// Moves a tape between our frame and the s709 BIN image, so that the 1963
// object program reads our input tapes and we read its output tapes (M7-11
// in docs/design/m7-diff.md).
//
// Usage:
//   dart run tool/m7/tape_conv.dart to-bin [--bcd] IN.tap OUT.bin
//   dart run tool/m7/tape_conv.dart list IN.bin
//
// to-bin writes each record of IN.tap (the M5-2 frame) to OUT.bin, and each
// file mark as the byte 0217. s709 checks the parity bit 0100 of each
// character it reads (chan7607.c): odd in binary mode, even in BCD mode. Our
// frame holds no parity bit (M5-2), so to-bin adds it: even with --bcd, for a
// file that the program reads in BCD mode, and odd without. Bit 0200 marks
// the first character of a record. An image mounted without the s flag of
// s709 holds the core code of a BCD character, so to-bin translates nothing.
//
// list prints the BCD image IN.bin one print line a record mark, as
// --list-tapes prints an output tape of ours (M5-11). It drops bits 0300 of
// each character and reads to the first file mark.
import 'dart:io';
import 'dart:typed_data';

import 'package:comtran/src/runtime/tape.dart';

const _usage =
    'usage: tape_conv.dart to-bin [--bcd] IN.tap OUT.bin\n'
    '       tape_conv.dart list IN.bin';

void main(List<String> args) {
  if (args.length == 3 && args[0] == 'to-bin') {
    _toBin(args[1], args[2], bcd: false);
  } else if (args.length == 4 && args[0] == 'to-bin' && args[1] == '--bcd') {
    _toBin(args[2], args[3], bcd: true);
  } else if (args.length == 2 && args[0] == 'list') {
    _list(args[1]);
  } else {
    stderr.writeln(_usage);
    exitCode = 64;
  }
}

/// The character [c] with the parity bit 0100 that makes its count of
/// one bits odd, or with [even] set, even.
int _parity(int c, {required bool even}) {
  var ones = 0;
  for (var b = c; b != 0; b >>= 1) {
    ones += b & 1;
  }
  final bool add = even ? ones.isOdd : ones.isEven;
  return add ? c | 0x40 : c;
}

void _toBin(String inPath, String outPath, {required bool bcd}) {
  final Uint8List tap = File(inPath).readAsBytesSync();
  final out = BytesBuilder();
  var at = 0;
  var records = 0;
  var marks = 0;
  int field(int i) =>
      tap[i] | tap[i + 1] << 8 | tap[i + 2] << 16 | tap[i + 3] << 24;
  while (at + 4 <= tap.length) {
    final int length = field(at);
    at += 4;
    if (length == 0xFFFFFFFF) {
      break;
    }
    if (length == 0) {
      out.addByte(0x8F);
      marks++;
      continue;
    }
    final List<int> data = tap.sublist(at, at + length);
    at += length + length % 2 + 4;
    final List<int> chars = [
      for (final int c in data) _parity(c & 0x3F, even: bcd),
    ];
    // s709 reads a record that opens 0217, 0000 as a file mark, and one
    // that opens 0217, 0017 with other characters (chan7607.c).
    if (chars.length > 1 &&
        chars[0] == 0x0F &&
        (chars[1] == 0 || chars[1] == 0x0F)) {
      throw StateError('s709 misreads record ${records + 1}');
    }
    chars[0] |= 0x80;
    out.add(chars);
    records++;
  }
  File(outPath).writeAsBytesSync(out.takeBytes());
  stdout.writeln('$outPath: $records records, $marks file marks');
}

void _list(String inPath) {
  final Uint8List bin = File(inPath).readAsBytesSync();
  final frames = <int>[];
  var start = 0;
  void frame(int end) {
    if (end > start) {
      final List<int> data = [
        for (final int c in bin.sublist(start, end)) c & 0x3F,
      ];
      final bool mark = data.length == 1 && data[0] == 0x0F;
      frames.addAll(mark ? tapeField(0) : _record(data));
    }
    start = end;
  }

  for (var i = 1; i < bin.length; i++) {
    if (bin[i] & 0x80 != 0) {
      frame(i);
    }
  }
  frame(bin.length);
  listTape(frames).forEach(stdout.writeln);
}

/// The frame of one record of six-bit [data].
List<int> _record(List<int> data) {
  if (data.length % bytesPerWord != 0) {
    throw StateError('a record of ${data.length} characters is no whole word');
  }
  final List<int> length = tapeField(data.length);
  return [...length, ...data, ...length];
}
