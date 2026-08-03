import 'dart:io';
import 'dart:typed_data';

import '../cards/canon_codec.dart';
import '../cards/card_image.dart';
import '../cards/deck_files.dart';
import '../cards/text_codec.dart';
import '../chars/char_code.dart';

/// The operations behind the deck MCP tools.
///
/// Each function reads or writes deck files through the library codecs and
/// returns a JSON-ready map. Bad input raises a [DeckToolException], which the
/// server turns into a structured tool error. Nothing here writes a file
/// before all of its input is valid.

/// A tool failure with a machine-readable [kind].
final class DeckToolException implements Exception {
  /// Makes a failure of category [kind] with the text [message].
  const DeckToolException(this.kind, this.message);

  /// The failure category, e.g. `not_found`, `format`, `invalid_argument`.
  final String kind;

  /// A one-line explanation for the caller.
  final String message;

  /// The failure as a JSON-ready map.
  Map<String, Object?> toJson() => {
    'error': {'kind': kind, 'message': message},
  };

  @override
  String toString() => '$kind: $message';
}

/// Reads the canon deck at [path].
///
/// Reports the card count and the mirror text of the deck. Set [includeCards]
/// to add the per-card structured form for [maxCards] cards from [startCard]
/// (1-based); this output is large, so ask for a range on a long deck.
Map<String, Object?> readDeck(
  String path, {
  bool includeCards = false,
  int startCard = 1,
  int? maxCards,
}) {
  final List<CardImage> deck = _readCanonFile(path);
  final String mirrorPath = _mirrorPathOf(path);
  final String text = deckToMirror(deck);
  final result = <String, Object?>{
    'path': path,
    'mirror_path': mirrorPath,
    'card_count': deck.length,
    'mirror_status': _mirrorStatus(mirrorPath, text),
    'mirror': text,
  };
  if (!includeCards) {
    return result;
  }
  if (startCard < 1) {
    throw const DeckToolException(
      'invalid_argument',
      'start_card is 1-based and must be 1 or more',
    );
  }
  if (maxCards != null && maxCards < 1) {
    throw const DeckToolException(
      'invalid_argument',
      'max_cards must be 1 or more',
    );
  }
  if (deck.isEmpty) {
    result['cards'] = const <Map<String, Object?>>[];
    return result;
  }
  if (startCard > deck.length) {
    throw DeckToolException(
      'out_of_range',
      'start_card $startCard is past the last card (${deck.length}) of $path',
    );
  }
  final int first = startCard - 1;
  final int last = maxCards == null
      ? deck.length
      : (first + maxCards).clamp(first, deck.length);
  result['cards'] = <Map<String, Object?>>[
    for (var i = first; i < last; i++) _cardJson(deck[i], i + 1),
  ];
  return result;
}

/// Writes normal-form mirror [text] to the canon file [path], then
/// regenerates the sibling mirror so that the pair stays fresh.
///
/// Parses and encodes everything before it touches the disk, so bad input
/// leaves both files unchanged.
Map<String, Object?> writeDeck(String path, String text) {
  final String mirrorPath = _mirrorPathOf(path);
  final List<CardImage> deck;
  try {
    deck = mirrorToDeck(text);
  } on FormatException catch (e) {
    throw DeckToolException('format', e.message);
  }
  final Uint8List bytes = encodeCanon(deck);
  final String mirror = deckToMirror(deck);
  if (mirror != text) {
    // mirrorToDeck accepts normal form only, so this cannot normally happen.
    throw const DeckToolException(
      'format',
      'mirror text is not in normal form (spec §3.3)',
    );
  }
  final Directory parent = File(path).parent;
  if (!parent.existsSync()) {
    throw DeckToolException('not_found', 'no such directory: ${parent.path}');
  }
  try {
    writeAtomic(path, (File f) => f.writeAsBytesSync(bytes));
    writeAtomic(mirrorPath, (File f) => f.writeAsStringSync(mirror));
  } on FileSystemException catch (e) {
    throw DeckToolException('io', '${e.message}: ${e.path}');
  }
  return {
    'path': path,
    'mirror_path': mirrorPath,
    'card_count': deck.length,
    'canon_bytes': bytes.length,
    'mirror': mirror,
  };
}

/// Describes card [cardIndex] (1-based) of the canon deck at [path].
Map<String, Object?> readCard(String path, int cardIndex) {
  final List<CardImage> deck = _readCanonFile(path);
  if (cardIndex < 1 || cardIndex > deck.length) {
    throw DeckToolException(
      'out_of_range',
      'card_index $cardIndex is outside 1..${deck.length} for $path',
    );
  }
  return {
    'path': path,
    'card_count': deck.length,
    ..._cardJson(deck[cardIndex - 1], cardIndex),
  };
}

/// Describes one character of the code table (spec §4.3).
///
/// Give exactly one of [glyph], [cardCode], or [bcdOctal].
Map<String, Object?> describeCardCode({
  String? glyph,
  String? cardCode,
  String? bcdOctal,
}) {
  final List<String> given = [
    if (glyph != null) 'glyph',
    if (cardCode != null) 'card_code',
    if (bcdOctal != null) 'bcd_octal',
  ];
  if (given.length != 1) {
    throw DeckToolException(
      'invalid_argument',
      'give exactly one of glyph, card_code, bcd_octal '
          '(got ${given.isEmpty ? 'none' : given.join(', ')})',
    );
  }
  if (glyph != null) {
    if (glyph.length != 1) {
      throw const DeckToolException(
        'invalid_argument',
        'glyph must be one character',
      );
    }
    final int? bcd = bcdFromGlyph(glyph);
    if (bcd == null) {
      throw DeckToolException(
        'unknown_glyph',
        '"$glyph" is not one of the 48 source-set characters',
      );
    }
    return _codeJson(bcd, query: {'kind': 'glyph', 'value': glyph});
  }
  if (cardCode != null) {
    final int? punches = punchesFromCardCode(cardCode);
    if (punches == null) {
      throw DeckToolException(
        'bad_card_code',
        '"$cardCode" is not a card code: give punch rows from 12, 11, 0, 1-9 '
            'in top-to-bottom order, joined with hyphens',
      );
    }
    final int? bcd = bcdFromPunches(punches);
    final query = <String, Object?>{'kind': 'card_code', 'value': cardCode};
    if (bcd == null) {
      return {
        'query': query,
        'card_code': cardCodeFromPunches(punches),
        'punch_rows': _rowList(punches),
        'readable': false,
        'attested': false,
        'bcd_octal': null,
        'bcd_decimal': null,
        'glyph': null,
        'name': null,
        'canonical_card_code': null,
        'canonical_punch_rows': null,
        'is_canonical': false,
        'note': 'this punch combination has no BCD readout (spec §4.1)',
      };
    }
    final Map<String, Object?> json = _codeJson(bcd, query: query);
    json['card_code'] = cardCodeFromPunches(punches);
    json['punch_rows'] = _rowList(punches);
    json['is_canonical'] = punchesFromBcd(bcd) == punches;
    return json;
  }
  final int? bcd = int.tryParse(bcdOctal!, radix: 8);
  if (bcd == null || bcd < 0 || bcd > 0x3F) {
    throw DeckToolException(
      'invalid_argument',
      '"$bcdOctal" is not a BCD code: give two octal digits, 00 to 77',
    );
  }
  return _codeJson(bcd, query: {'kind': 'bcd_octal', 'value': bcdOctal});
}

/// Runs the `deckconv check` verification over [paths] and reports it as
/// structured results.
Map<String, Object?> checkDecks(List<String> paths) {
  if (paths.isEmpty) {
    throw const DeckToolException('invalid_argument', 'give at least one path');
  }
  final List<DeckCheckResult> results;
  try {
    results = checkDeckPaths(paths);
  } on FileSystemException catch (e) {
    throw DeckToolException('not_found', '${e.message}: ${e.path}');
  }
  if (results.isEmpty) {
    throw DeckToolException(
      'not_found',
      'no canon or mirror files found under: ${paths.join(' ')}',
    );
  }
  final int failures = results.where((DeckCheckResult r) => !r.passed).length;
  return {
    'ok': failures == 0,
    'checked': results.length,
    'failure_count': failures,
    'results': <Map<String, Object?>>[
      for (final DeckCheckResult r in results)
        {
          'path': r.path,
          'mirror_path': r.mirrorPath,
          'status': _statusName(r.status),
          'passed': r.passed,
          'message': r.message,
        },
    ],
  };
}

List<CardImage> _readCanonFile(String path) {
  if (!path.endsWith(canonExtension)) {
    throw DeckToolException(
      'bad_extension',
      'a canon file path must end with $canonExtension: $path',
    );
  }
  final FileSystemEntityType type = FileSystemEntity.typeSync(path);
  if (type == FileSystemEntityType.notFound) {
    throw DeckToolException('not_found', 'no such file: $path');
  }
  if (type == FileSystemEntityType.directory) {
    throw DeckToolException('not_a_file', 'path is a directory: $path');
  }
  final Uint8List bytes;
  try {
    bytes = File(path).readAsBytesSync();
  } on FileSystemException catch (e) {
    throw DeckToolException('io', '${e.message}: $path');
  }
  try {
    return decodeCanon(bytes);
  } on FormatException catch (e) {
    throw DeckToolException('format', '$path: ${e.message}');
  }
}

String _mirrorPathOf(String canonPath) {
  try {
    return mirrorPathFor(canonPath);
  } on FormatException catch (e) {
    throw DeckToolException('bad_extension', e.message);
  }
}

String _mirrorStatus(String mirrorPath, String text) {
  final mirror = File(mirrorPath);
  if (!mirror.existsSync()) {
    return 'missing';
  }
  return mirror.readAsStringSync() == text ? 'fresh' : 'stale';
}

Map<String, Object?> _cardJson(CardImage card, int index) {
  final columns = <Map<String, Object?>>[];
  final fields = <String>[];
  var isGlyphCard = true;
  for (var column = 1; column <= CardImage.columnCount; column++) {
    final int punches = card.punchesAt(column);
    if (!isGlyphColumn(punches)) {
      isGlyphCard = false;
    }
    if (punches == 0) {
      continue;
    }
    final String code = cardCodeFromPunches(punches);
    final int? bcd = bcdFromPunches(punches);
    fields.add('$column:$code');
    columns.add({
      'column': column,
      'card_code': code,
      'punch_rows': _rowList(punches),
      'readable': bcd != null,
      'bcd_octal': bcd == null ? null : _octal(bcd),
      'glyph': bcd == null ? null : glyphFromBcd(bcd),
      'name': bcd == null ? null : _bcdName(bcd),
    });
  }
  // One card renders through the mirror codec, so the line is the same text
  // the mirror file holds. Drop the line feed that deckToMirror appends.
  final String rendered = deckToMirror([card]);
  final String line = rendered.substring(0, rendered.length - 1);
  return {
    'card_index': index,
    'form': isGlyphCard ? 'glyph' : 'punch',
    'blank': card.isBlank,
    'mirror_line': line,
    'glyph_line': isGlyphCard ? line : null,
    'punch_notation': fields.isEmpty ? '!' : '! ${fields.join(' ')}',
    'punched_columns': columns.length,
    'columns': columns,
  };
}

Map<String, Object?> _codeJson(int bcd, {required Map<String, Object?> query}) {
  final int? punches = punchesFromBcd(bcd);
  final String? glyph = glyphFromBcd(bcd);
  final String? name = _bcdName(bcd);
  return {
    'query': query,
    'bcd_octal': _octal(bcd),
    'bcd_decimal': bcd,
    'glyph': glyph,
    'name': name,
    'attested': name != null,
    'machine_special': machineSpecialName(bcd),
    'canonical_card_code': punches == null
        ? null
        : cardCodeFromPunches(punches),
    'canonical_punch_rows': punches == null ? null : _rowList(punches),
    'readable': true,
  };
}

List<String> _rowList(int punches) {
  final String code = cardCodeFromPunches(punches);
  return code.isEmpty ? const <String>[] : code.split('-');
}

String _octal(int bcd) => bcd.toRadixString(8).padLeft(2, '0');

String _statusName(DeckCheckStatus status) => switch (status) {
  DeckCheckStatus.ok => 'ok',
  DeckCheckStatus.roundTripFailed => 'round_trip_failed',
  DeckCheckStatus.mirrorMissing => 'mirror_missing',
  DeckCheckStatus.mirrorStale => 'mirror_stale',
  DeckCheckStatus.orphanMirror => 'orphan_mirror',
  DeckCheckStatus.unreadable => 'unreadable',
};

const List<String> _digitNames = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
];

const Map<String, String> _specialNames = {
  '+': 'plus sign',
  '-': 'minus sign',
  '*': 'multiplication sign',
  '/': 'division sign',
  '(': 'left parenthesis',
  ')': 'right parenthesis',
  ',': 'comma',
  '.': 'period',
  r'$': 'dollar sign',
  '=': 'equal sign',
  "'": 'quotation mark',
};

/// The §4.3 name of BCD code [bcd], or `null` for an unattested row.
String? _bcdName(int bcd) {
  if (bcd == bcdBlank) {
    return 'blank';
  }
  final String? special = machineSpecialName(bcd);
  if (special != null) {
    return special;
  }
  final String? glyph = glyphFromBcd(bcd);
  if (glyph == null) {
    return null;
  }
  final int unit = glyph.codeUnitAt(0);
  if (unit >= 0x30 && unit <= 0x39) {
    return 'digit ${_digitNames[unit - 0x30]}';
  }
  if (unit >= 0x41 && unit <= 0x5A) {
    return 'letter $glyph';
  }
  return _specialNames[glyph];
}
