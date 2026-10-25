// Compiles each probe program, prints the words of its procedure,
// runs it on the machine assembly, and prints each named field.
import 'dart:convert';
import 'dart:io';

import 'package:comtran/comtran_io.dart';

import '../test/runtime/runtime_support.dart' show glyphsAt, addressOf;
import '../test/support/deck_fixtures.dart' show dataCard;

const ListingOptions _listing = ListingOptions(date: '10/18/61', time: '2.45');

String _i(String name, String pic) =>
    dataCard(name: name, level: '1', mode: 'I', justify: 'R', description: pic);

/// name -> (source lines, fields to report: name -> chars or -1 for a word)
final Map<String, (List<String>, Map<String, int>)> probes = {
  'P1a-up': ([
    '      *DATA', _i('NUM', '999'),
    dataCard(name: 'EDT', level: '1', description: r'$8889.99'),
    '      *PROCEDURE',
    '      START.  SET NUM = 123.',
    '            MOVE NUM TO EDT.',
    '            STOP RUN.', '      *FINISH',
  ], {'NUM': -1, 'EDT': 8}),
  'P1a-up-split': ([
    '      *DATA', _i('BIG', '9(5)'),
    dataCard(name: 'ED5', level: '1', description: '889.9'),
    '      *PROCEDURE',
    '      START.  SET BIG = 1234.',
    '            MOVE BIG TO ED5.',
    '            STOP RUN.', '      *FINISH',
  ], {'BIG': -1, 'ED5': 5}),
  'P1a-down': ([
    '      *DATA', _i('AMT', '99V99'),
    dataCard(name: 'EDS', level: '1', description: '89.9'),
    '      *PROCEDURE',
    '      START.  SET AMT = 12.34.',
    '            MOVE AMT TO EDS.',
    '            STOP RUN.', '      *FINISH',
  ], {'AMT': -1, 'EDS': 4}),
  'P1b-up': ([
    '      *DATA',
    dataCard(name: 'AREA', level: '1'),
    dataCard(level: '2', description: "'040'"),
    dataCard(type: 'REDEF', description: 'AREA'),
    dataCard(name: 'VIEW', level: '1'),
    dataCard(name: 'EXT', level: '2', mode: 'E', description: '999'),
    _i('INT', '99V99'),
    '      *PROCEDURE',
    '      START.  MOVE EXT TO INT.',
    '            STOP RUN.', '      *FINISH',
  ], {'INT': -1}),
  'P1b-down': ([
    '      *DATA',
    dataCard(name: 'AREA', level: '1'),
    dataCard(level: '2', description: "'1234'"),
    dataCard(type: 'REDEF', description: 'AREA'),
    dataCard(name: 'VIEW', level: '1'),
    dataCard(name: 'EXT', level: '2', mode: 'E', description: '99V99'),
    _i('INT', '99V9'),
    '      *PROCEDURE',
    '      START.  MOVE EXT TO INT.',
    '            STOP RUN.', '      *FINISH',
  ], {'INT': -1}),
  'P2-up': ([
    '      *DATA',
    dataCard(name: 'G3', level: '1'),
    dataCard(name: 'ED3', level: '2', description: '899'),
    _i('TOT', '999V99'),
    '      *PROCEDURE',
    "      START.  MOVE '037' TO G3.",
    '            SET TOT = 1.25.',
    '            ADD ED3 TO TOT.',
    '            STOP RUN.', '      *FINISH',
  ], {'TOT': -1}),
  'P2-down': ([
    '      *DATA',
    dataCard(name: 'G3', level: '1'),
    dataCard(name: 'ED3', level: '2', description: '899V99'),
    _i('TOT', '9999'),
    '      *PROCEDURE',
    "      START.  MOVE '03750' TO G3.",
    '            SET TOT = 100.',
    '            ADD ED3 TO TOT.',
    '            STOP RUN.', '      *FINISH',
  ], {'TOT': -1}),
  'P2-plain-up': ([
    '      *DATA', _i('SRC', '999'), _i('TOT', '999V99'),
    '      *PROCEDURE',
    '      START.  SET SRC = 37, SET TOT = 1.25.',
    '            ADD SRC TO TOT.',
    '            STOP RUN.', '      *FINISH',
  ], {'TOT': -1}),
  'S1-set-ext-up': ([
    '      *DATA',
    dataCard(name: 'AREA', level: '1'),
    dataCard(level: '2', description: "'040'"),
    dataCard(type: 'REDEF', description: 'AREA'),
    dataCard(name: 'VIEW', level: '1'),
    dataCard(name: 'EXT', level: '2', mode: 'E', description: '999'),
    _i('INT', '99V99'),
    '      *PROCEDURE',
    '      START.  SET INT = EXT.',
    '            STOP RUN.', '      *FINISH',
  ], {'INT': -1}),
  'S2-set-int-up': ([
    '      *DATA', _i('NUM', '999'), _i('INT', '99V99'),
    '      *PROCEDURE',
    '      START.  SET NUM = 40, SET INT = NUM.',
    '            STOP RUN.', '      *FINISH',
  ], {'INT': -1}),
  'S3-set-add-up': ([
    '      *DATA', _i('SRC', '999'), _i('TOT', '999V99'),
    '      *PROCEDURE',
    '      START.  SET SRC = 37, SET TOT = 1.25.',
    '            SET TOT = TOT + SRC.',
    '            STOP RUN.', '      *FINISH',
  ], {'TOT': -1}),
  'S4-set-add-down': ([
    '      *DATA', _i('SRC', '99V99'), _i('TOT', '9999'),
    '      *PROCEDURE',
    '      START.  SET SRC = 37.50, SET TOT = 100.',
    '            SET TOT = TOT + SRC.',
    '            STOP RUN.', '      *FINISH',
  ], {'TOT': -1}),
  'S5-set-ed-add-up': ([
    '      *DATA',
    dataCard(name: 'G3', level: '1'),
    dataCard(name: 'ED3', level: '2', description: '899'),
    _i('TOT', '999V99'),
    '      *PROCEDURE',
    "      START.  MOVE '037' TO G3.",
    '            SET TOT = 1.25.',
    '            SET TOT = TOT + ED3.',
    '            STOP RUN.', '      *FINISH',
  ], {'TOT': -1}),
  'P2-plain-down': ([
    '      *DATA', _i('SRC', '99V99'), _i('TOT', '9999'),
    '      *PROCEDURE',
    '      START.  SET SRC = 37.50, SET TOT = 100.',
    '            ADD SRC TO TOT.',
    '            STOP RUN.', '      *FINISH',
  ], {'TOT': -1}),
};

void main(List<String> args) {
  final out = <String, Object>{};
  for (final MapEntry(key: String name, value: (List<String> src, Map<String, int> fields))
      in probes.entries) {
    if (args.isNotEmpty && !args.contains(name)) continue;
    final report = <String, Object>{'source': src};
    final job = compileDeck(mirrorToDeck('${src.join('\n')}\n')).jobs.single;
    final codegen = job.codegen;
    final diags = [for (final d in job.diagnostics) d.toString()];
    report['diagnostics'] = diags;
    if (job.unrecovered != null) report['refusal'] = job.unrecovered.toString();
    if (codegen == null) {
      out[name] = report;
      continue;
    }
    final words = [for (final u in codegen.units) '${u.operation} ${u.operand}'.trimRight()];
    final start = words.indexOf('BSS 0');
    report['words'] = words.sublist(start, words.indexOf('TSX SYS)178,4') + 1);
    final deck = jobDeck(job, _listing);
    if (deck == null) {
      report['run'] = 'no object deck';
      out[name] = report;
      continue;
    }
    final m = Machine.load(deck.cards);
    final r = m.run(maxSteps: 5000);
    report['outcome'] = r.outcome.name;
    report['display'] = r.display;
    final values = <String, Object>{};
    for (final MapEntry(key: String f, value: int n) in fields.entries) {
      final int a = addressOf(job, f);
      if (n < 0) {
        final w = m.state.read(a);
        // Sign-magnitude 36-bit word.
        values[f] = (w >> 35) == 1 ? -(w & 0x7FFFFFFFF) : w;
      } else {
        values[f] = glyphsAt(m, a, n);
      }
    }
    report['values'] = values;
    out[name] = report;
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(out));
}
