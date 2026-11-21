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
}
