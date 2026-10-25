// Compiles each probe program for codegen defects 8 to 11, prints the
// words of its procedure, runs it on the machine assembly, and prints
// each named field. Run from the repository root:
//   dart run probe/probe.dart > out.json
import 'dart:convert';
import 'dart:io';

import 'package:comtran/comtran_io.dart';

import '../test/runtime/runtime_support.dart' show glyphsAt, addressOf;
import '../test/support/deck_fixtures.dart' show dataCard;

const ListingOptions _listing = ListingOptions(date: '10/18/61', time: '2.45');

String _i(String name, String pic, {String level = '1'}) => dataCard(
  name: name,
  level: level,
  mode: 'I',
  justify: 'R',
  description: pic,
);

/// One field to report: a label, a word offset from it, and a character
/// count, or -1 to read the word as a sign-magnitude binary integer.
typedef Field = (String label, int plus, int chars);

/// Two words ahead of every table, so a base `NAME-n` stays at or
/// above address zero.
final List<String> _pad = [_i('PAD1', '9'), _i('PAD2', '9')];

/// Three elements of one word each, CELL internal decimal.
final List<String> _cellTable = [
  dataCard(name: 'TAB', level: '1', quantity: '3'),
  _i('CELL', '999', level: '2'),
];

/// Three elements of one word each, A external decimal, holding 1, 2, 3.
final List<String> _aTable = [
  dataCard(name: 'TABLE', level: '1'),
  for (var k = 1; k <= 3; k++)
    dataCard(level: '2', description: "'${'$k'.padLeft(6, '0')}'"),
  dataCard(type: 'REDEF', description: 'TABLE'),
  dataCard(name: 'TAB', level: '1', quantity: '3'),
  dataCard(name: 'A', level: '2', mode: 'E', description: '9(6)'),
];

/// Twelve items of two words: A `99`, B `9999` at byte 2, C `9(6)`.
/// Item k holds A = k, B = k, C = 100 + k (the machine test's table).
final List<String> _byteTable = [
  dataCard(name: 'TABLE', level: '1'),
  for (var k = 1; k <= 12; k++)
    dataCard(
      level: '2',
      description:
          "'${'$k'.padLeft(2, '0')}${'$k'.padLeft(4, '0')}"
          "${'${100 + k}'.padLeft(6, '0')}'",
    ),
  dataCard(type: 'REDEF', description: 'TABLE'),
  dataCard(name: 'TAB', level: '1', quantity: '12'),
  dataCard(name: 'A', level: '2', description: '99'),
  dataCard(name: 'B', level: '2', description: '9999'),
  dataCard(name: 'C', level: '2', description: '9(6)'),
];

/// The sample's TABLE.ITEM shape: RATE one word, INSPREM and RETPREM
/// `9V99` packed in the second word at bytes 0 and 3. Item k holds
/// INSPREM = k·1.00 + .11 and RETPREM = k·1.00 + .22, so the two differ.
final List<String> _premTable = [
  dataCard(name: 'TABLE', level: '1'),
  for (var k = 1; k <= 3; k++)
    dataCard(level: '2', description: "'000000${k}11${k}22'"),
  dataCard(type: 'REDEF', description: 'TABLE'),
  dataCard(name: 'TABLE.ITEM', level: '1', quantity: '3'),
  dataCard(name: 'RATE', level: '2', description: '9(6)'),
  dataCard(name: 'INSPREM', level: '2', description: '9V99'),
  dataCard(name: 'RETPREM', level: '2', description: '9V99'),
];

final Map<String, (List<String>, List<Field>)> probes = {
  // Defect 8: a subscripted MOVE target.
  'D8-int-int': ([
    '      *DATA', ..._pad, ..._cellTable, _i('I', '9'), _i('TWO', '9'), _i('NUM', '999'),
    '      *PROCEDURE',
    '      START.  SET TWO = 2, MOVE TWO TO I.',
    '            SET NUM = 7.',
    '            MOVE NUM TO CELL (I).',
    '            STOP RUN.', '      *FINISH',
  ], [('TAB', 0, -1), ('TAB', 1, -1), ('TAB', 2, -1)]),
  'D8-ext-int': ([
    '      *DATA', ..._pad, ..._cellTable, _i('I', '9'), _i('TWO', '9'),
    dataCard(name: 'AREA', level: '1'),
    dataCard(level: '2', description: "'007'"),
    dataCard(type: 'REDEF', description: 'AREA'),
    dataCard(name: 'VIEW', level: '1'),
    dataCard(name: 'EXT', level: '2', mode: 'E', description: '999'),
    '      *PROCEDURE',
    '      START.  SET TWO = 2, MOVE TWO TO I.',
    '            MOVE EXT TO CELL (I).',
    '            STOP RUN.', '      *FINISH',
  ], [('TAB', 0, -1), ('TAB', 1, -1), ('TAB', 2, -1)]),
  'D8-int-edited': ([
    '      *DATA', ..._pad,
    dataCard(name: 'ETAB', level: '1', quantity: '3'),
    dataCard(name: 'EDT', level: '2', description: '888889'),
    _i('I', '9'), _i('TWO', '9'), _i('NUM', '999'),
    '      *PROCEDURE',
    '      START.  SET TWO = 2, MOVE TWO TO I.',
    '            SET NUM = 7.',
    '            MOVE NUM TO EDT (I).',
    '            STOP RUN.', '      *FINISH',
  ], [('ETAB', 0, 6), ('ETAB', 1, 6)]),
  // Defect 9: a SET or ADD into a subscript variable.
  'D9-set': ([
    '      *DATA', ..._pad, ..._aTable, _i('I', '9'), _i('ONE', '9'), _i('WA', '9(6)'),
    '      *PROCEDURE',
    '      START.  SET ONE = 1, MOVE ONE TO I.',
    '            SET I = 3.',
    '            MOVE A (I) TO WA.',
    '            STOP RUN.', '      *FINISH',
  ], [('I', 0, -1), ('WA', 0, -1)]),
  'D9-add': ([
    '      *DATA', ..._pad, ..._aTable, _i('I', '9'), _i('ONE', '9'), _i('TWO', '9'),
    _i('WA', '9(6)'),
    '      *PROCEDURE',
    '      START.  SET ONE = 1, SET TWO = 2, MOVE ONE TO I.',
    '            ADD TWO TO I.',
    '            MOVE A (I) TO WA.',
    '            STOP RUN.', '      *FINISH',
  ], [('I', 0, -1), ('WA', 0, -1)]),
  'D9-increment': ([
    '      *DATA', ..._pad, ..._aTable, _i('I', '9'), _i('ONE', '9'), _i('WA', '9(6)'),
    '      *PROCEDURE',
    '      START.  SET ONE = 1, MOVE ONE TO I.',
    '            SET I = I + 2.',
    '            MOVE A (I) TO WA.',
    '            STOP RUN.', '      *FINISH',
  ], [('I', 0, -1), ('WA', 0, -1)]),
  // Defect 10: the subscript store's base drops the field's byte.
  'D10-one': ([
    '      *DATA', ..._pad, ..._byteTable, _i('IDX', '99'), _i('THREE', '99'),
    _i('NB', '9(6)'),
    '      *PROCEDURE',
    '      START.  SET THREE = 3, MOVE THREE TO IDX.',
    '            MOVE B (IDX) TO NB.',
    '            STOP RUN.', '      *FINISH',
  ], [('NB', 0, -1)]),
  'D10-two': ([
    '      *DATA', ..._pad, ..._premTable, _i('POS', '9'), _i('THREE', '9'),
    _i('WI', '9V99'), _i('WR', '9V99'),
    '      *PROCEDURE',
    '      START.  SET THREE = 3, MOVE THREE TO POS.',
    '            MOVE INSPREM (POS) TO WI.',
    '            MOVE RETPREM (POS) TO WR.',
    '            STOP RUN.', '      *FINISH',
  ], [('WI', 0, -1), ('WR', 0, -1)]),
  // Defect 11: a sub-chain inside a chain.
  'D11-sum': ([
    '      *DATA', _i('NUM', '999'), _i('X', '9(5)'),
    '      *PROCEDURE',
    '      START.  SET NUM = 5.',
    '            SET X = NUM * 2 + (NUM * 3 + 1).',
    '            STOP RUN.', '      *FINISH',
  ], [('X', 0, -1)]),
  'D11-product': ([
    '      *DATA', _i('NUM', '999'), _i('X', '9(5)'),
    '      *PROCEDURE',
    '      START.  SET NUM = 5.',
    '            SET X = NUM * 2 + (NUM * 3 + 1) * 2.',
    '            STOP RUN.', '      *FINISH',
  ], [('X', 0, -1)]),
};

void main(List<String> args) {
  final out = <String, Object>{};
  for (final MapEntry(key: String name, value: (List<String> src, List<Field> fields))
      in probes.entries) {
    if (args.isNotEmpty && !args.contains(name)) continue;
    final report = <String, Object>{'source': src};
    final job = compileDeck(mirrorToDeck('${src.join('\n')}\n')).jobs.single;
    final codegen = job.codegen;
    report['diagnostics'] = [for (final d in job.diagnostics) d.toString()];
    if (job.unrecovered != null) report['refusal'] = job.unrecovered.toString();
    if (codegen == null) {
      out[name] = report;
      continue;
    }
    final words = [
      for (final u in codegen.units)
        '${u.labels.isEmpty ? '' : '${u.labels.join(' ')}  '}${u.operation} ${u.operand}'.trimRight(),
    ];
    final start = words.indexWhere((w) => w.contains('START  '));
    final end = words.indexWhere((w) => w.endsWith('TSX SYS)178,4'));
    report['words'] = words.sublist(start < 0 ? 0 : start, end + 1);
    // The pool's address words (PZE), with their octal: the bases.
    report['pool'] = [
      for (final u in codegen.units.skip(end + 1))
        if (u.operation == 'PZE')
          '${u.operation} ${u.operand}  ${u.word!.toRadixString(8).padLeft(12, '0')}',
    ];
    final deck = jobDeck(job, _listing);
    if (deck == null) {
      report['run'] = 'no object deck';
      out[name] = report;
      continue;
    }
    final m = Machine.load(deck.cards);
    final r = m.run(maxSteps: 20000);
    report['outcome'] = r.outcome.name;
    report['display'] = r.display;
    final values = <String, Object>{};
    for (final (String label, int plus, int chars) in fields) {
      final int a = addressOf(job, label) + plus;
      final key = plus == 0 ? label : '$label+$plus';
      if (chars < 0) {
        final w = m.state.read(a);
        values[key] = (w >> 35) == 1 ? -(w & 0x7FFFFFFFF) : w;
      } else {
        values[key] = glyphsAt(m, a, chars);
      }
    }
    report['values'] = values;
    out[name] = report;
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(out));
}
