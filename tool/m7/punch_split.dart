// Splits s709 punch tapes into programs at each transfer card, and writes
// chosen programs, in a chosen order, to a new tape for the System Editor.
//
// List:  dart run tool/m7/punch_split.dart A.bin B.bin ...
// Write: dart run tool/m7/punch_split.dart A.bin B.bin ... -o OUT.bin 0:0 1:3
//   Each N:M names program M of input tape N, both counted from 0.
import 'dart:io';
import 'dart:typed_data';

// One column-binary card is a 162-character record. Its first word holds
// the word count in bits 13 to 17; a count of 0 is a transfer card. The
// first data word, the third word of the first card, is the record name.
const _cardChars = 162;
const _bcd =
    r'0123456789#=@:>? ABCDEFGHI&.)[<]-JKLMNOPQR-$*];^ /STUVWXYZ+,(~\!';

class Program {
  Program(this.name, this.cards);
  final String name;
  final List<Uint8List> cards;
}

List<Uint8List> _records(Uint8List bytes) {
  final starts = <int>[
    for (var i = 0; i < bytes.length; i++)
      if (bytes[i] & 0x80 != 0) i,
  ];
  return [
    for (var k = 0; k < starts.length; k++)
      Uint8List.sublistView(
        bytes,
        starts[k],
        k + 1 < starts.length ? starts[k + 1] : bytes.length,
      ),
  ];
}

int _word(Uint8List r, int w) {
  var v = 0;
  for (var i = 0; i < 6; i++) {
    v = (v << 6) | (r[w * 6 + i] & 0x3f);
  }
  return v;
}

String _name(Uint8List r) =>
    [for (var i = 12; i < 18; i++) _bcd[r[i] & 0x3f]].join();

List<Program> programs(String path) {
  final result = <Program>[];
  var cards = <Uint8List>[];
  for (final Uint8List r in _records(File(path).readAsBytesSync())) {
    if (r.length != _cardChars) {
      continue;
    }
    cards.add(r);
    if ((_word(r, 0) >> 18) & 0x1f == 0) {
      result.add(Program(_name(cards.first), cards));
      cards = [];
    }
  }
  return result;
}

void main(List<String> args) {
  final int o = args.indexOf('-o');
  final List<String> inputs = o < 0 ? args : args.sublist(0, o);
  final List<List<Program>> tapes = [for (final p in inputs) programs(p)];
  if (o < 0) {
    for (var t = 0; t < tapes.length; t++) {
      for (var m = 0; m < tapes[t].length; m++) {
        final Program p = tapes[t][m];
        stdout.writeln('$t:$m  ${p.name}  ${p.cards.length} cards');
      }
    }
    return;
  }
  final out = BytesBuilder();
  for (final String spec in args.sublist(o + 2)) {
    final List<int> tm = spec.split(':').map(int.parse).toList();
    final Program p = tapes[tm[0]][tm[1]];
    p.cards.forEach(out.add);
    stdout.writeln('$spec  ${p.name}');
  }
  File(args[o + 1]).writeAsBytesSync(out.toBytes());
}
