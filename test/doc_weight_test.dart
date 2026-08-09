import 'dart:io';

import 'package:test/test.dart';

/// Words allowed in a markdown file under `docs/` that [budgets] does not
/// name. The guard checks weight, not quality: to give a document more
/// room, raise its budget in the same pull request and give the reason in
/// the commit message.
const int defaultBudget = 8000;

/// The reference documents that grow with the project.
const Map<String, int> budgets = <String, int>{
  'docs/comtran-language-definition.md': 115000,
  'docs/design/decisions.md': 50000,
  'docs/design/m3-data.md': 9000,
  'docs/design/m4-codegen.md': 9000,
};

/// The generated mirror of the language definition, which the guard skips.
/// Canon already carries the budget for that text, so a budget per part
/// would count the same words a second time and would move whenever a
/// section grows.
const String generatedMirror = 'docs/definition/';

int wordCount(String text) =>
    text.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).length;

void main() {
  test('every docs markdown file stays inside its word budget', () {
    final List<File> files = Directory('docs')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (File f) =>
              f.path.endsWith('.md') && !f.path.startsWith(generatedMirror),
        )
        .toList();
    expect(files, isNotEmpty);
    for (final file in files) {
      final int words = wordCount(file.readAsStringSync());
      final int budget = budgets[file.path] ?? defaultBudget;
      expect(
        words,
        lessThanOrEqualTo(budget),
        reason: '${file.path} holds $words words; the budget is $budget',
      );
    }
  });
}
