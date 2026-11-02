// Writes the literal and expression subscript probe decks as canon
// files. Run from the repository root: dart run probe/probe.dart OUTDIR
// Each program stops at its last STOP RUN when the subscripted store or
// read reached the right element, and at an earlier one when it did not.
import 'dart:io';

import 'package:comtran/comtran_io.dart';

import '../test/support/deck_fixtures.dart' show dataCard, internalCard;

List<String> program(List<String> procedure) => <String>[
  '      *DATA',
  internalCard('P1', '9'),
  internalCard('P2', '9'),
  dataCard(name: 'TAB', level: '1', quantity: '3'),
  internalCard('CELL', '999', level: '2'),
  dataCard(type: 'REDEF', description: 'TAB'),
  dataCard(name: 'VIEW', level: '1'),
  for (final String name in ['C1', 'C2', 'C3'])
    internalCard(name, '999', level: '2'),
  dataCard(name: 'TABLE', level: '1'),
  for (var k = 1; k <= 5; k++)
    dataCard(level: '2', description: "'${'$k'.padLeft(6, '0')}'"),
  dataCard(type: 'REDEF', description: 'TABLE'),
  dataCard(name: 'ROWS', level: '1', quantity: '5'),
  dataCard(name: 'A', level: '2', mode: 'E', description: '9(6)'),
  for (final String name in ['I', 'K', 'NUM', 'W', 'S'])
    internalCard(name, '9(6)'),
  '      *PROCEDURE',
  ...procedure,
  '      *FINISH',
];

final Map<String, List<String>> probes = {
  // A literal subscript: element 2.
  'literal': program([
    '      START.  SET NUM = 7, MOVE NUM TO CELL (2).',
    '            IF C2 = 7 THEN GO TO PASS.',
    '            STOP RUN.',
    '      PASS.  STOP RUN.',
  ]),
  // An index expression after a SET of its variable: element 2.
  'expression': program([
    '      START.  SET NUM = 7, SET I = 1.',
    '            MOVE NUM TO CELL (I + 1).',
    '            IF C2 = 7 THEN GO TO PASS.',
    '            STOP RUN.',
    '      PASS.  STOP RUN.',
  ]),
  // J 02.04.07.01: SET K = K + 2 updates the indicator of K + 1.
  'step': program([
    '      START.  SET NUM = 7, SET K = 0.',
    '            SET K = K + 2.',
    '            MOVE NUM TO CELL (K + 1).',
    '            IF C3 = 7 THEN GO TO PASS.',
    '            STOP RUN.',
    '      PASS.  STOP RUN.',
  ]),
  // A DO FOR from 3: A (3) + A (4) + A (5) is 12.
  'do-for': program([
    '      START.  DO RTN FOR I = 3(1)5.',
    '            IF S = 12 THEN GO TO PASS.',
    '            STOP RUN.',
    '      PASS.  STOP RUN.',
    '      RTN.  BEGIN SECTION.',
    '            MOVE A (I) TO W, SET S = S + W.',
    '            END RTN.',
  ]),
};

void main(List<String> args) {
  final out = Directory(args.single)..createSync(recursive: true);
  for (final MapEntry<String, List<String>> probe in probes.entries) {
    final List<CardImage> cards = mirrorToDeck('${probe.value.join('\n')}\n');
    File('${out.path}/${probe.key}.ctd').writeAsBytesSync(encodeCanon(cards));
  }
}
