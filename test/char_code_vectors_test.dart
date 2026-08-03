import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

/// The cross-language parity gate for the character code (CI-01; VSC-5).
///
/// The VS Code extension carries a TypeScript port of
/// `lib/src/chars/char_code.dart`. Both codecs must agree on every punch
/// pattern and every BCD code. The committed fixtures
/// `tools/vscode-punchcard/test/fixtures/char-code-*-vectors.csv` are the
/// shared contract: the extension's `charCodeVectors.test.js` checks the
/// TypeScript side, and this test checks the Dart side, against the same
/// bytes. A change to either codec that is not reflected in a regenerated
/// fixture (`npm run vectors` in `tools/vscode-punchcard/`) fails one side.
///
/// The fixture format is documented in
/// `tools/vscode-punchcard/test/fixtures/README.md`: every field is
/// double-quoted, `""` escapes an internal quote, an empty field means the
/// source function returned null.

const String _fixtures = 'tools/vscode-punchcard/test/fixtures';

List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  var i = 0;
  while (i < line.length) {
    if (line[i] != '"') {
      throw FormatException('field ${fields.length} of $line is not quoted');
    }
    i++;
    final field = StringBuffer();
    while (i < line.length) {
      if (line[i] == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          field.write('"');
          i += 2;
        } else {
          i++;
          break;
        }
      } else {
        field.write(line[i]);
        i++;
      }
    }
    fields.add(field.toString());
    if (i < line.length && line[i] == ',') {
      i++;
    }
  }
  return fields;
}

List<Map<String, String>> _readCsv(String path) {
  final List<String> lines = File(
    path,
  ).readAsLinesSync().where((String line) => line.isNotEmpty).toList();
  final List<String> header = _parseCsvLine(lines.first);
  return [
    for (final String line in lines.skip(1))
      Map.fromIterables(header, _parseCsvLine(line)),
  ];
}

void main() {
  test('the committed punch-pattern vectors match the Dart codec', () {
    final List<Map<String, String>> rows = _readCsv(
      '$_fixtures/char-code-punch-vectors.csv',
    );
    expect(rows, hasLength(4096), reason: 'run: npm run vectors');
    for (var i = 0; i < rows.length; i++) {
      final Map<String, String> row = rows[i];
      final int punches = int.parse(row['punches']!);
      expect(punches, i, reason: 'the fixture is sorted by ascending punches');
      final int? bcd = bcdFromPunches(punches);
      expect(row['bcd'], bcd?.toString() ?? '', reason: 'punches $punches');
      expect(
        row['card_code'],
        cardCodeFromPunches(punches),
        reason: 'punches $punches',
      );
      expect(
        row['is_glyph_column'],
        isGlyphColumn(punches) ? 'true' : 'false',
        reason: 'punches $punches',
      );
    }
  });

  test('the committed BCD vectors match the Dart codec', () {
    final List<Map<String, String>> rows = _readCsv(
      '$_fixtures/char-code-bcd-vectors.csv',
    );
    expect(rows, hasLength(64), reason: 'run: npm run vectors');
    for (var i = 0; i < rows.length; i++) {
      final Map<String, String> row = rows[i];
      final int bcd = int.parse(row['bcd']!);
      expect(bcd, i, reason: 'the fixture is sorted by ascending bcd');
      final int? punches = punchesFromBcd(bcd);
      expect(row['punches'], punches?.toString() ?? '', reason: 'bcd $bcd');
      expect(row['glyph'], glyphFromBcd(bcd) ?? '', reason: 'bcd $bcd');
      expect(
        row['machine_special'],
        machineSpecialName(bcd) ?? '',
        reason: 'bcd $bcd',
      );
    }
  });

  test('the BCD vectors carry the literal comma glyph correctly quoted', () {
    final List<Map<String, String>> rows = _readCsv(
      '$_fixtures/char-code-bcd-vectors.csv',
    );
    final Map<String, String> commaRow = rows.firstWhere(
      (Map<String, String> row) => row['glyph'] == ',',
      orElse: () => fail('no row has glyph ","'),
    );
    expect(int.parse(commaRow['bcd']!), 59);
  });
}
