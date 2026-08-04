/// The M3 stage-2 mapper capacity counters (M3-12; M3-21's capacity
/// homes): the four data-division tables of J 90.01.05, each rejecting
/// at its printed "Appox-Max" number (D9.7).
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// [entries] variable-length fields, each with its own count field.
List<String> _variableFields(int entries) => [
  for (var i = 0; i < entries; i++) ...[
    dataCard(name: 'C$i', level: '1', description: '99'),
    dataCard(
      name: 'V$i',
      level: '1',
      quantity: '2',
      description: 'A QUANTITY IN C$i',
    ),
  ],
];

/// [entries] one-dimensional arrays.
List<String> _arrays(int entries) => [
  for (var i = 0; i < entries; i++)
    dataCard(name: 'A$i', level: '1', quantity: '2', description: 'A'),
];

/// A hierarchy [levels] deep: one group per level, a field at the foot.
List<String> _hierarchy(int levels) => [
  for (var level = 1; level < levels; level++)
    dataCard(name: 'G$level', level: '$level'),
  dataCard(name: 'FOOT', level: '$levels', description: 'A'),
];

/// [entries] distinct edited formats: `$9(1)`, `$9(2)`, and so on.
List<String> _editedFormats(int entries) => [
  for (var i = 0; i < entries; i++)
    dataCard(name: 'E$i', level: '1', description: '\$9(${i + 1})'),
];

void main() {
  group('the capacity counters (M3-12; D9.7)', () {
    test('the 26th QUANTITY IN draws 200,00 and stops', () {
      final SemanticResult result = runJob(data: _variableFields(26));
      expect(ids(result), ['200,00']);
      expect(result.stopped, isTrue);
      expect(ids(runJob(data: _variableFields(25))), isEmpty);
    });

    test('the 24th hierarchy level draws 201,00 and names the entry', () {
      final SemanticResult result = runJob(data: _hierarchy(24));
      expect(ids(result), ['201,00']);
      expect(result.stopped, isTrue);
      expect(result.semanticDiagnostics.single.text, contains("'FOOT'"));
      expect(ids(runJob(data: _hierarchy(23))), isEmpty);
    });

    test('the 86th array dimension draws 203,00 and stops', () {
      final SemanticResult result = runJob(data: _arrays(86));
      expect(ids(result), ['203,00']);
      expect(result.stopped, isTrue);
      expect(ids(runJob(data: _arrays(85))), isEmpty);
    });

    test('the 36th distinct edited format draws 204,00 and stops', () {
      final SemanticResult result = runJob(data: _editedFormats(36));
      expect(ids(result), ['204,00']);
      expect(result.stopped, isTrue);
      expect(ids(runJob(data: _editedFormats(35))), isEmpty);
    });

    test('a repeated edited format counts once (J 90.01.05 item c)', () {
      final SemanticResult result = runJob(
        data: [
          ..._editedFormats(35),
          dataCard(name: 'AGAIN', level: '1', description: r'$9(1)'),
        ],
      );
      expect(ids(result), isEmpty);
    });

    test('--no-table-limits lifts all four counters', () {
      for (final List<String> data in [
        _variableFields(26),
        _hierarchy(24),
        _arrays(86),
        _editedFormats(36),
      ]) {
        final SemanticResult lifted = runJob(data: data, tableLimits: false);
        expect(ids(lifted), isEmpty);
        expect(lifted.stopped, isFalse);
      }
    });
  });
}
