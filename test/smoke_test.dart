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
      'test/fixtures/90.05-payroll.ct',
    ).readAsLinesSync();
    expect(lines, hasLength(293));
    for (final line in lines) {
      expect(line.length, lessThanOrEqualTo(72));
    }
    // Columns 73-80 are blank on every card of this deck (identification
    // field, F p. 37, F p. 84; also pinned in text_codec_test.dart), so
    // 72 is not a loose guess: a line reaches it exactly, at least once.
    expect(
      lines.map((String l) => l.length).reduce((a, b) => a > b ? a : b),
      72,
    );
  });
}
