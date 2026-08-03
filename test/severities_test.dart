import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  test('every catalog id has exactly one severity row (D9.2)', () {
    // The build check D9.2 requires: ids 0-209 all present, no strays.
    for (var i = 0; i < 210; i++) {
      expect(messageSeverities.containsKey('$i,00'), isTrue, reason: '$i,00');
    }
    final Iterable<String> strays = messageSeverities.keys.where(
      (String id) => !messageCatalog.containsKey(id),
    );
    expect(strays, [
      '900,00', '901,00', '902,00', '903,00', '904,00', //
      '905,00', '906,00', '907,00', '908,00', '909,00',
      '910,00', '911,00', '912,00', '913,00', '914,00', '915,00',
      '916,00',
    ]);
  });

  test('every severity value is in 1-5', () {
    for (final MapEntry<String, int> row in messageSeverities.entries) {
      expect(row.value, inInclusiveRange(1, 5), reason: row.key);
    }
  });

  test('the D9.2 anchor rows hold', () {
    // D9.7's capacity messages are C5.
    for (final String id in [
      '148,00', '149,00', '172,00', '183,00', //
      '184,00', '200,00', '201,00', '202,00', '203,00', '204,00', '205,00',
    ]) {
      expect(messageSeverities[id], 5, reason: id);
    }
    // D9.2's worked example: message 177 is C3 by the precedence rule.
    expect(messageSeverities['177,00'], 3);
    // The M1 anchors.
    expect(messageSeverities['62,00'], 1);
    expect(messageSeverities['134,00'], 1);
    expect(messageSeverities['194,00'], 3);
  });

  test('class distribution matches the reviewed draft', () {
    final counts = <int, int>{};
    for (final MapEntry<String, int> row in messageSeverities.entries) {
      if (messageCatalog.containsKey(row.key)) {
        counts[row.value] = (counts[row.value] ?? 0) + 1;
      }
    }
    expect(counts, {1: 30, 2: 57, 3: 69, 4: 29, 5: 25});
  });
}
