/// The chunk B1 oracle (M4-1): the address spine of the whole object
/// listing, matched line for line against the verified target.
///
/// B1 sizes every unit of the program and binds it to an address. It
/// fills no other column, so this test reads the two columns B1 decides
/// on its own. The rest arrive with the verb generators, B2 to B6, and
/// the golden is what holds them (M4-8).
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The scan-verified target: listing pages 8 to 25, PDF pp. 199 to 216,
/// the transcription's content in the M4-8 geometry.
const String _targetPath = 'test/fixtures/90.05-object-listing.target';

/// Page furniture, which chunk B7 lays out and B1 does not emit: the
/// page head, the blank lines under it, the column header, and the three
/// closing lines the loader writes rather than the listing formatter
/// (M4-8 as amended, chunk A8).
bool _isFurniture(String line) =>
    line.trim().isEmpty ||
    line.startsWith('DATE ') ||
    line.startsWith(' LOC ') ||
    line.startsWith('THE ') ||
    line.startsWith('*CTEND') ||
    line == 'DONE';

/// The `+n` offset lives between the label column and column 42. An
/// operand can hold a `+` of its own and every operand prints past that
/// zone, so the search must not run over the whole line.
final RegExp _offsetDigits = RegExp(r'\+\d+');

/// The LOC field of [line] and its `+n` offset.
///
/// LOC is five octal digits, or empty where the line prints none: a
/// `USE` discontinuity, or the second line of a wrapped over-long label
/// (M4-8.1). The offset counts printed lines since the last line that
/// carried a name, so it tests where the labels landed, which the LOC
/// column alone cannot (M4-20 item d).
String _spineField(String line) {
  final String loc = line.length < 5 ? '' : line.substring(0, 5).trim();
  final int end = line.length < 43 ? line.length : 43;
  final String zone = line.length < 34 ? '' : line.substring(34, end);
  return '$loc ${_offsetDigits.stringMatch(zone) ?? ''}';
}

/// Our own lines carry no furniture, so every one of them is content. A
/// wrapped label's second line is blank in B1, because the mnemonic it
/// will carry is B2's, and it must still count as a line here.
List<String> _spine(Iterable<String> lines) => lines.map(_spineField).toList();

void main() {
  group('the address spine (M4-1 chunk B1)', () {
    late List<String> generated;
    late List<String> target;

    setUpAll(() {
      final SemanticResult semantics = compileDeck(
        loadJobDeck(),
      ).jobs.single.semantics!;
      generated = _spine(renderObjectLines(runCodegen(semantics).units));
      target = _spine(
        File(
          _targetPath,
        ).readAsLinesSync().where((String line) => !_isFurniture(line)),
      );
    });

    test('every line carries the location the 1962 listing printed', () {
      // The addresses are continuous, so the first divergence localises
      // the wrong unit and every later one is its consequence. Report
      // that line alone, with the target's neighbours for context.
      for (var i = 0; i < generated.length && i < target.length; i++) {
        if (generated[i] != target[i]) {
          final int from = i < 4 ? 0 : i - 4;
          fail(
            'line ${i + 1}: generated "${generated[i]}", '
            'target "${target[i]}"\n'
            'target context: ${target.sublist(from, i + 1).join(' | ')}',
          );
        }
      }
      expect(generated, hasLength(target.length));
    });
  });
}
