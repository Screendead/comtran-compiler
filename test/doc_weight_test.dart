import 'dart:io';

import 'package:test/test.dart';

/// The word budget of one file under `docs/`. A file the map does not name
/// gets [defaultBudget]. The guard checks weight, not quality: when a
/// document needs more room, raise its budget in the same pull request and
/// give the reason in the commit message.
const int defaultBudget = 8000;

/// The two reference documents that grow with the project.
const Map<String, int> budgets = <String, int>{
  'docs/comtran-language-definition.md': 120000,
  'docs/design/decisions.md': 60000,
};

int wordCount(String text) =>
    text.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).length;

void main() {
  test('every docs file stays inside its word budget', () {
    final List<File> files = Directory('docs')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.md'))
        .toList();
    expect(files, isNotEmpty);
    for (final file in files) {
      final String path = file.path.replaceAll(r'\', '/');
      final int words = wordCount(file.readAsStringSync());
      final int budget = budgets[path] ?? defaultBudget;
      expect(
        words,
        lessThanOrEqualTo(budget),
        reason: '$path holds $words words; the budget is $budget',
      );
    }
  });
}
