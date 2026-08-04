/// The M3-14 storage oracle: the data mapper must reproduce the 1962
/// object listing's `*DATA` section — every transmitted area's offset,
/// extent, and initial word images — for the 90.05 sample deck
/// (J 90.05, printer pages 8-9, PDF pp. 199-200; the fixture is
/// transcribed from the page scans).
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// One fixture row: an initialized word, or an uninitialized run.
final class _Row {
  _Row(this.loc, this.value, this.count, this.symbol);

  final int loc;
  final int? value; // null for a BSS row
  final int count; // BSS word count; 1 for an OCT row
  final String symbol;
}

List<_Row> _readFixture() {
  final rows = <_Row>[];
  for (final String line in File(
    'test/fixtures/90.05-storage-section.tsv',
  ).readAsLinesSync()) {
    if (line.startsWith('#') || line.isEmpty) {
      continue;
    }
    final List<String> fields = line.split('\t');
    final int loc = int.parse(fields[0], radix: 8);
    final String symbol = fields.length > 3 ? fields[3] : '';
    if (fields[1] == 'bss') {
      rows.add(_Row(loc, null, int.parse(fields[2]), symbol));
    } else {
      rows.add(_Row(loc, int.parse(fields[2], radix: 8), 1, symbol));
    }
  }
  return rows;
}

void main() {
  late final SemanticResult semantics;
  late final List<_Row> fixture;

  setUpAll(() {
    final DeckCompilation deck = compileDeck(loadJobDeck());
    semantics = deck.jobs.single.semantics!;
    fixture = _readFixture();
  });

  group('the *DATA storage section (M3-14)', () {
    test('the transmitted areas appear in the printed order at the '
        'printed offsets', () {
      final expected = <(String, int)>[];
      for (final row in fixture) {
        if (row.symbol.isNotEmpty) {
          expected.add((row.symbol, row.loc));
        }
      }
      final actual = <(String, int)>[];
      var base = 0;
      for (final AreaInfo area in semantics.areas) {
        actual.add((area.name, base));
        base += area.extentWords;
      }
      expect(actual, expected);
    });

    test('every initial word matches the printed octal value, and '
        'every BSS word has no image', () {
      final expectedWords = <int, int?>{};
      for (final row in fixture) {
        if (row.value != null) {
          expectedWords[row.loc] = row.value;
        } else {
          for (var i = 0; i < row.count; i++) {
            expectedWords[row.loc + i] = null;
          }
        }
      }
      final actualWords = <int, int?>{};
      var base = 0;
      for (final AreaInfo area in semantics.areas) {
        for (var i = 0; i < area.words.length; i++) {
          actualWords[base + i] = area.words[i];
        }
        base += area.extentWords;
      }
      expect(actualWords.length, expectedWords.length);
      for (final MapEntry<int, int?> entry in expectedWords.entries) {
        expect(
          actualWords[entry.key],
          entry.value,
          reason:
              'word ${entry.key.toRadixString(8).padLeft(5, '0')} '
              'must hold '
              '${entry.value?.toRadixString(8).padLeft(12, '0') ?? 'no image'}',
        );
      }
    });

    test('the section ends after TABLE at word 00164 (24 constant '
        'words)', () {
      final int total = semantics.areas.fold(
        0,
        (int sum, AreaInfo area) => sum + area.extentWords,
      );
      expect(total.toRadixString(8), '165');
      expect(semantics.areas.last.name, 'TABLE');
      expect(semantics.areas.last.extentWords, 24);
    });

    test('MASTER and DETAIL are located and take no area '
        '(J 02.07.05; M3-11)', () {
      final Map<String, RecordInfo> records = {
        for (final RecordInfo record in semantics.records) record.name: record,
      };
      expect(records['MASTER']!.located, isTrue);
      expect(records['MASTER']!.inputFiles, ['INPUTMASTER']);
      expect(records['MASTER']!.outputFiles, ['OUTPUTMASTER']);
      expect(records['DETAIL']!.located, isTrue);
      for (final AreaInfo area in semantics.areas) {
        expect(area.name, isNot(anyOf('MASTER', 'DETAIL')));
      }
      expect(records.values.where((RecordInfo r) => r.variable), isEmpty);
    });
  });

  group('sample allocation attestations (M3-6)', () {
    ItemSemantics named(String name) => semantics.semantics.entries
        .firstWhere(
          (MapEntry<DataItem, ItemSemantics> e) => e.key.entry.name == name,
        )
        .value;

    test('TRIGGERS fills the half word NAME leaves (J 90.05.02)', () {
      final ItemSemantics triggers = named('TRIGGERS');
      expect(triggers.word, 3);
      expect(triggers.byte, 3);
    });

    test('RATE takes a whole word after TRIGGERS (J 02.05.04)', () {
      final ItemSemantics rate = named('RATE');
      expect(rate.word, 4);
      expect(rate.byte, 0);
      expect(rate.storageChars, 6);
    });

    test('TABLE.ITEM redefines TABLE in twelve 2-word pairs and takes '
        'no area (D3.4; M3-6)', () {
      final ItemSemantics item = named('TABLE.ITEM');
      expect(item.spaceRoot!.entry.name, 'TABLE');
      expect(item.strideChars, 12);
      expect(item.quantity, 12);
      expect(item.extentChars, 144);
    });

    test('MASTER lays out in 15 words, DETAIL in 3 (J 90.05.02)', () {
      // Extents in characters; a record rounds to words (90 makes 15;
      // 15 makes 3, the partial third word blank-filled).
      expect(named('MASTER').extentChars, 90);
      expect(named('DETAIL').extentChars, 15);
    });
  });
}
