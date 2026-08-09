/// Generates `test/fixtures/90.05-object-listing.target`. Run from the
/// repository root:
///
///     dart run tool/generate_object_listing_target.dart
///
/// `tool/object_listing_target_source.dart` states what the target is and
/// how it is built, and `test/object_listing_target_test.dart`
/// regenerates it and compares it byte for byte.
library;

import 'dart:io';

import 'object_listing_target_source.dart';

void main() {
  final List<String> lines = File(objectListingSource).readAsLinesSync();
  final List<String> target = buildObjectListingTarget(lines);
  File(objectListingTarget).writeAsStringSync('${target.join('\n')}\n');
  stdout.writeln('wrote $objectListingTarget: ${target.length} lines');
}
