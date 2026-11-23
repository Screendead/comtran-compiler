/// The mapper capacity counters (M3-12; M3-21's capacity
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
    // Each table, its deck at the limit and one past it, and the message.
    final cases = <(String, List<String> Function(int), int, String)>[
      ('QUANTITY IN', _variableFields, 25, '200,00'),
      ('hierarchy level', _hierarchy, 23, '201,00'),
      ('array dimension', _arrays, 85, '203,00'),
      ('distinct edited format', _editedFormats, 35, '204,00'),
    ];
    for (final (
          String table,
          List<String> Function(int) deck,
          int max,
          String id,
        )
        in cases) {
      test('one $table past $max draws $id and stops; '
          '--no-table-limits lifts it', () {
        expect(ids(runJob(data: deck(max))), isEmpty);
        final SemanticResult result = runJob(data: deck(max + 1));
        expect(ids(result), [id]);
        expect(result.stopped, isTrue);
        final SemanticResult lifted = runJob(
          data: deck(max + 1),
          tableLimits: false,
        );
        expect(ids(lifted), isEmpty);
        expect(lifted.stopped, isFalse);
      });
    }

    test('201,00 names the entry', () {
      expect(
        runJob(data: _hierarchy(24)).semanticDiagnostics.single.text,
        contains("'FOOT'"),
      );
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
  });
}
