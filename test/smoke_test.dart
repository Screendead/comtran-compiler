import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  test('version constant matches pubspec.yaml', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final String? version = RegExp(
      r'^version:\s*(\S+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);
    expect(comtranVersion, version);
  });

  test('the re-keyed 90.05 deck is present and card-shaped', () {
    final List<String> lines = File(
      'tests/90.05-payroll.deck',
    ).readAsLinesSync();
    expect(lines, hasLength(293));
    for (final line in lines) {
      expect(line.length, lessThanOrEqualTo(72));
    }
  });
}
