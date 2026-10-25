// Writes the defect 6 probe decks as canon files. Run from the
// repository root: dart run probe/probe.dart OUTDIR
import 'dart:io';

import 'package:comtran/comtran_io.dart';

import '../test/support/deck_fixtures.dart' show dataCard, environmentCard;

List<String> program(List<String> procedure) => <String>[
  '      *DATA',
  dataCard(name: 'OREC', level: '1', type: 'RECORD'),
  dataCard(name: 'OFLD', level: '2', description: 'AAA'),
  dataCard(name: 'WORDS', level: '1'),
  dataCard(name: 'ONE', level: '2', description: "'ONE'"),
  dataCard(name: 'TWO', level: '2', description: "'TWO'"),
  '      *ENVIRONMENT',
  environmentCard(
    name: 'TAPE1',
    type: 'FILE',
    options: 'OUTPUT,BCD,TAPE,OREC,BLOCKSIZE 1',
  ),
  environmentCard(type: 'SPECIF', options: "TAPE1,UNIT1 'D1'"),
  '      *PROCEDURE',
  ...procedure,
  '      *FINISH',
];

final Map<String, List<String>> probes = {
  // The fired case: a reopen in the straight run after CLOSE ALL FILES.
  'reopen': program([
    '      START.  OPEN ALL FILES, MOVE ONE TO OFLD, FILE OREC.',
    '            CLOSE ALL FILES.',
    '            OPEN ALL FILES, MOVE TWO TO OFLD, FILE OREC.',
    '            STOP RUN.',
  ]),
  // A label between the two: rule (i) is silent.
  'labelled': program([
    '      START.  OPEN ALL FILES, MOVE ONE TO OFLD, FILE OREC.',
    '            CLOSE ALL FILES.',
    '      AGAIN.  OPEN ALL FILES, MOVE TWO TO OFLD, FILE OREC.',
    '            STOP RUN.',
  ]),
  // The sample's shape: CLOSE ALL FILES, STOP RUN. Silent.
  'sample-shape': program([
    '      START.  OPEN ALL FILES, MOVE ONE TO OFLD, FILE OREC.',
    '            CLOSE ALL FILES, STOP RUN.',
  ]),
};

void main(List<String> args) {
  final out = Directory(args.single)..createSync(recursive: true);
  for (final MapEntry<String, List<String>> probe in probes.entries) {
    final List<CardImage> cards = mirrorToDeck('${probe.value.join('\n')}\n');
    File('${out.path}/${probe.key}.ctd').writeAsBytesSync(encodeCanon(cards));
  }
}
