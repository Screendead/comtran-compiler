// Writes CT files 5 and 6, the subroutine library, on an s709 system tape
// (M7-7 in docs/design/m7-diff.md). The System Editor cannot write the
// dictionary and text records, so this tool writes the tape image directly.
//
// Seed:   dart run tool/m7/ct_lib.dart seed IN.BIN OUT.BIN
//   File 5 becomes SRDLOC and an empty dictionary; file 6 becomes empty.
// Splice: dart run tool/m7/ct_lib.dart splice IN.BIN SUBUP.BIN OUT.BIN
//   File 5 becomes SRDLOC and file 1 of the SUBUP output tape (the
//   dictionary); file 6 becomes file 2 of that tape (the subroutine text).
//
// CT file 0 is the file whose first record is named CT. Every other record
// and file mark of IN.BIN is copied unchanged. The tool prints the records
// of CT files 5 and 6 as it writes them.
import 'dart:io';
import 'dart:typed_data';

// s709 BIN images hold one 6-bit character per byte. Bit 0200 marks the
// first character of a record, bit 0100 is the parity bit, and the byte
// 0217 alone is a file mark.
const _bcd =
    r'0123456789#=@:>? ABCDEFGHI&.)[<]-JKLMNOPQR-$*];^ /STUVWXYZ+,(~\!';

/// One record of a tape: its 6-bit characters, without marks or parity.
class Record {
  Record(this.chars);

  Record.words(List<String> octal)
    : chars = [
        for (final o in octal)
          for (var i = 5; i >= 0; i--) (int.parse(o, radix: 8) >> 6 * i) & 63,
      ];

  final List<int> chars;

  int get words => chars.length ~/ 6;

  int word(int w) {
    var v = 0;
    for (var i = 0; i < 6; i++) {
      v = (v << 6) | chars[w * 6 + i];
    }
    return v;
  }

  String get name =>
      chars.length >= 12 ? chars.sublist(6, 12).map((c) => _bcd[c]).join() : '';
}

/// Reads a tape as its files, each a list of records, and the parity rule
/// of its binary records.
(List<List<Record>>, bool) _read(String path) {
  final Uint8List bytes = File(path).readAsBytesSync();
  final files = <List<Record>>[[]];
  final odd = <bool>{};
  List<int>? current;
  void end() {
    final done = current;
    if (done != null) {
      files.last.add(Record(done));
    }
    current = null;
  }

  for (var i = 0; i < bytes.length; i++) {
    final int b = bytes[i];
    final bool alone = i + 1 == bytes.length || bytes[i + 1] & 0x80 != 0;
    if (b == 0x8f && alone) {
      end();
      files.add([]);
      continue;
    }
    if (b & 0x80 != 0) {
      end();
      current = [];
    }
    current!.add(b & 0x3f);
    odd.add(_ones(b & 0x7f).isOdd);
  }
  end();
  if (odd.length != 1) {
    throw StateError('$path: records mix odd and even parity');
  }
  return (files, odd.single);
}

int _ones(int v) => v == 0 ? 0 : (v & 1) + _ones(v >> 1);

void _write(String path, List<List<Record>> files, bool odd) {
  final out = BytesBuilder();
  for (var f = 0; f < files.length; f++) {
    for (final Record r in files[f]) {
      for (var i = 0; i < r.chars.length; i++) {
        final int c = r.chars[i];
        final int p = _ones(c).isOdd == odd ? c : c | 0x40;
        out.addByte(p | (i == 0 ? 0x80 : 0));
      }
    }
    if (f + 1 < files.length) {
      out.addByte(0x8f);
    }
  }
  File(path).writeAsBytesSync(out.toBytes());
}

// A record that the IBSYS loader reads is a chain of IOCP L,,N control
// words, each followed by its N words, and ends with IOCT 0,,0 (editor.map,
// "SYSTEM TAPE FORMAT"). True if the record has this form.
bool _scatter(Record r) {
  var i = 0;
  while (i < r.words) {
    final int w = r.word(i);
    if (w == 5 << 33) {
      return i == r.words - 1;
    }
    if (w >> 33 != 4) {
      return false;
    }
    i += 1 + ((w >> 18) & 0x7fff);
  }
  return false;
}

// SRDLOC, the record before the dictionary: ct.job SDL00010 to SDL00360,
// with the words of ct.lst. On a tape system it returns at once, but the
// monitor loads and runs it before each read of file 5 (CT004510).
final _srdloc = Record.words([
  '400001000102', '625124434623', // 00102  BCI 1,SRDLOC
  '400001000100', '002100003745', // 00100  TTR START
  '400012003745', // 03745, ten words
  '452000003743', '002060003721', '053500403735', '056000000127',
  '477300000004', '075400000000', '476300000016', '062100400003',
  '060000003745', '002060003721',
  '500000000000', // IOCT 0,,0
]);

// An empty dictionary, as SUBUP writes it for no subroutines (SU030840 to
// SU030990): IORTN 0, BCI 1,SRDICT, no system references (N = 0), and no
// subroutines (3S = 0).
final _emptyDictionary = Record.words([
  '300000200000',
  '625124312363',
  '000000000000',
  '000000000000',
]);

void main(List<String> args) {
  final bool seed = args.length == 3 && args[0] == 'seed';
  if (!seed && !(args.length == 4 && args[0] == 'splice')) {
    stderr
      ..writeln('usage: ct_lib.dart seed IN.BIN OUT.BIN')
      ..writeln('       ct_lib.dart splice IN.BIN SUBUP.BIN OUT.BIN');
    exit(64);
  }
  final (List<List<Record>> tape, bool odd) = _read(args[1]);
  final int ct = tape.indexWhere(
    (f) => f.isNotEmpty && f.first.name == 'CT    ',
  );
  if (ct < 0 || ct + 10 > tape.length) {
    throw StateError('${args[1]}: no CT file 0 with nine files after it');
  }
  if (!_scatter(tape[ct].first) || !_scatter(_srdloc)) {
    throw StateError('${args[1]}: the CT record is not IOCP ... IOCT 0,,0');
  }
  if (seed) {
    tape[ct + 5] = [_srdloc, _emptyDictionary];
    tape[ct + 6] = [];
  } else {
    final (List<List<Record>> library, _) = _read(args[2]);
    if (library.length < 3) {
      throw StateError('${args[2]}: fewer than two files');
    }
    tape[ct + 5] = [_srdloc, ...library[0]];
    tape[ct + 6] = library[1];
  }
  for (final f in [5, 6]) {
    for (var k = 0; k < tape[ct + f].length; k++) {
      final Record r = tape[ct + f][k];
      stdout.writeln('$f.$k  ${r.words}  ${r.name}');
    }
    stdout.writeln('$f  -- file mark');
  }
  _write(args.last, tape, odd);
}
