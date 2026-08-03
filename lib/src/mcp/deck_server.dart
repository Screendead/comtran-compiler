import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';

import '../version.dart';
import 'deck_tools.dart';

/// The COMTRAN deck MCP server.
///
/// Gives an agent structured read and write access to card decks:
/// `deck_read`, `deck_write`, `deck_edit_cards`, `deck_card`,
/// `card_code_info`, and `deck_check`. The formats are in
/// `docs/design/deck-format.md`. Canon files (`.ctdeck`) are authoritative;
/// `deck_write` and `deck_edit_cards` regenerate the sibling mirror
/// (`.deck`) on every write, so no tool ever hand-edits a mirror.
///
/// Every path argument must resolve inside a workspace root the client
/// declares (the `RootsTrackingSupport` mixin); with no client-declared
/// roots, the server's own working directory is the only allowed root.

const String _instructions = '''
Read and write COMTRAN card decks at punch level.

A deck has two files. The canon file (.ctdeck) is a binary punch-level card
image and is authoritative. The mirror file (.deck) is generated text, one
line per card, committed for review and diffs.

Rules:
- Never hand-edit a .deck mirror. Write the deck with deck_write or
  deck_edit_cards, which rewrite the canon file and regenerate the mirror
  together.
- Address every deck by its .ctdeck path, inside a declared workspace root.
- Mirror text must be in normal form: one line per card, LF endings, no
  trailing spaces, a final LF. A glyph line gives the Set H characters of the
  card. A card that punches anything else uses a punch line, "!" followed by
  "<column>:<rows>" fields in ascending column order, e.g. "! 1:12-5-8 72:9".
- deck_read's include_cards form pages: it returns at most 100 cards per
  call, 25 by default, and reports next_start_card for the next page.
- Give expected_mirror to deck_write or deck_edit_cards to fail with a
  conflict instead of overwriting a change made since you last read the deck.
- deck_check reports the same freshness and round-trip verification that
  "dart run comtran:deckconv check" does.
''';

/// A stdio MCP server for COMTRAN card decks.
base class DeckMcpServer extends MCPServer
    with LoggingSupport, ToolsSupport, RootsTrackingSupport {
  /// Serves the deck tools over [channel], a line-delimited JSON-RPC channel.
  DeckMcpServer(super.channel)
    : super.fromStreamChannel(
        implementation: Implementation(
          name: 'comtran-decks',
          version: comtranVersion,
        ),
        instructions: _instructions,
      ) {
    registerTool(readTool, _read);
    registerTool(writeTool, _write);
    registerTool(editCardsTool, _editCards);
    registerTool(cardTool, _card);
    registerTool(codeTool, _code);
    registerTool(checkTool, _check);
  }

  /// Serves the deck tools over this process's standard input and output.
  factory DeckMcpServer.overStdio() =>
      DeckMcpServer(stdioChannel(input: stdin, output: stdout));

  /// Reads a canon deck.
  static final Tool readTool = Tool(
    name: 'deck_read',
    description:
        'Read a COMTRAN canon deck (.ctdeck). Reports the card count, the '
        'mirror text of the deck, and whether the committed .deck mirror is '
        'fresh. Set include_cards for the per-card structured form; the '
        'response then omits the full mirror text and reports '
        'cards_returned and next_start_card instead, so page with '
        'start_card on a long deck.',
    inputSchema: Schema.object(
      properties: {
        'path': Schema.string(
          description: 'Path to the canon file. Must end with .ctdeck.',
        ),
        'include_cards': Schema.bool(
          description:
              'Add a structured entry per card: form, mirror line, punch '
              'notation, and the punched columns with card codes and glyphs. '
              'Defaults to false because the output is large.',
        ),
        'start_card': Schema.int(
          description: 'First card of the structured range, 1-based.',
          minimum: 1,
        ),
        'max_cards': Schema.int(
          description:
              'How many cards the structured range holds. Defaults to '
              '$defaultMaxCards when omitted; the most any one call returns '
              'is $_maxMaxCards — page with start_card and the returned '
              'next_start_card for more.',
          minimum: 1,
          maximum: _maxMaxCards,
        ),
      },
      required: ['path'],
      additionalProperties: false,
    ),
    annotations: ToolAnnotations(readOnlyHint: true),
    outputSchema: ObjectSchema(
      properties: {
        'path': Schema.string(),
        'mirror_path': Schema.string(),
        'card_count': Schema.int(),
        'mirror_status': Schema.string(),
        'mirror': Schema.string(),
        'cards': Schema.list(items: Schema.object(additionalProperties: true)),
        'cards_returned': Schema.int(),
        'next_start_card': Schema.int(),
      },
      required: ['path', 'mirror_path', 'card_count', 'mirror_status'],
    ),
  );

  /// Writes a canon deck and its mirror.
  static final Tool writeTool = Tool(
    name: 'deck_write',
    description:
        'Write mirror text to a COMTRAN canon deck (.ctdeck) and regenerate '
        'the sibling .deck mirror, so the pair stays fresh. The text must be '
        'in normal form; bad text is rejected and no file changes. Give '
        'expected_mirror (from an earlier deck_read) to fail with a '
        'conflict instead of overwriting a change made since you last read '
        'the deck.',
    inputSchema: Schema.object(
      properties: {
        'path': Schema.string(
          description:
              'Path to the canon file to write. Must end with .ctdeck.',
        ),
        'mirror': Schema.string(
          description:
              'Normal-form mirror text: one line per card, LF endings, a '
              'final LF, no trailing spaces. Empty text writes an empty deck.',
        ),
        'expected_mirror': Schema.string(
          description:
              'Optional. The mirror text an earlier deck_read reported for '
              'this deck. If the deck changed since then, the call fails '
              'with a conflict and writes nothing.',
        ),
      },
      required: ['path', 'mirror'],
      additionalProperties: false,
    ),
    annotations: ToolAnnotations(destructiveHint: true, idempotentHint: true),
    outputSchema: ObjectSchema(
      properties: {
        'path': Schema.string(),
        'mirror_path': Schema.string(),
        'card_count': Schema.int(),
        'canon_bytes': Schema.int(),
        'mirror': Schema.string(),
      },
      required: ['path', 'mirror_path', 'card_count', 'canon_bytes', 'mirror'],
    ),
  );

  /// Replaces a range of cards without sending the whole mirror.
  static final Tool editCardsTool = Tool(
    name: 'deck_edit_cards',
    description:
        'Replace a range of cards in a canon deck without sending or '
        'returning the whole mirror. Deletes delete_count cards starting '
        'at start_card, then inserts insert_lines (each a normal-form '
        'mirror line) in their place. Give delete_count 0 to insert only, '
        'or insert_lines empty to delete only. Give expected_mirror to fail '
        'with a conflict instead of overwriting a change made since you '
        'last read the deck.',
    inputSchema: Schema.object(
      properties: {
        'path': Schema.string(
          description: 'Path to the canon file. Must end with .ctdeck.',
        ),
        'start_card': Schema.int(
          description:
              'First card of the range, 1-based. Give card_count + 1 to '
              'append.',
          minimum: 1,
        ),
        'delete_count': Schema.int(
          description:
              'How many existing cards to remove, starting at start_card. '
              'Defaults to 0.',
          minimum: 0,
        ),
        'insert_lines': Schema.list(
          description:
              'Normal-form mirror lines to put in their place, in order. '
              'Defaults to none.',
          items: Schema.string(),
        ),
        'expected_mirror': Schema.string(
          description:
              'Optional. The mirror text an earlier deck_read reported for '
              'this deck. If the deck changed since then, the call fails '
              'with a conflict and writes nothing.',
        ),
      },
      required: ['path', 'start_card'],
      additionalProperties: false,
    ),
    annotations: ToolAnnotations(destructiveHint: true, idempotentHint: false),
    outputSchema: ObjectSchema(
      properties: {
        'path': Schema.string(),
        'mirror_path': Schema.string(),
        'card_count': Schema.int(),
        'canon_bytes': Schema.int(),
        'start_card': Schema.int(),
        'deleted_count': Schema.int(),
        'inserted_count': Schema.int(),
      },
      required: [
        'path',
        'mirror_path',
        'card_count',
        'canon_bytes',
        'start_card',
        'deleted_count',
        'inserted_count',
      ],
    ),
  );

  /// Describes one card of a deck.
  static final Tool cardTool = Tool(
    name: 'deck_card',
    description:
        'Describe one card of a canon deck: its glyph line, its punch '
        'notation, and the card code, BCD code, glyph, and name of every '
        'punched column.',
    inputSchema: Schema.object(
      properties: {
        'path': Schema.string(
          description: 'Path to the canon file. Must end with .ctdeck.',
        ),
        'card_index': Schema.int(
          description: 'Which card to describe, 1-based.',
          minimum: 1,
        ),
      },
      required: ['path', 'card_index'],
      additionalProperties: false,
    ),
    annotations: ToolAnnotations(readOnlyHint: true),
    outputSchema: ObjectSchema(
      properties: {
        'path': Schema.string(),
        'card_count': Schema.int(),
        'card_index': Schema.int(),
        'form': Schema.string(),
        'blank': Schema.bool(),
        'mirror_line': Schema.string(),
        'glyph_line': Schema.string(),
        'punch_notation': Schema.string(),
        'punched_columns': Schema.int(),
        'columns': Schema.list(
          items: Schema.object(additionalProperties: true),
        ),
      },
      required: [
        'path',
        'card_count',
        'card_index',
        'form',
        'blank',
        'mirror_line',
        'punched_columns',
        'columns',
      ],
    ),
  );

  /// Looks a character up in the code table.
  static final Tool codeTool = Tool(
    name: 'card_code_info',
    description:
        'Look up one character of the COMTRAN code table. Give exactly one '
        'of glyph, card_code, or bcd_octal. Reports the BCD octal code, the '
        'canonical punches, the Set H glyph, and the name.',
    inputSchema: Schema.object(
      properties: {
        'glyph': Schema.string(
          description: 'One Set H character, e.g. "A", "5", "\$", or a space.',
        ),
        'card_code': Schema.string(
          description:
              'Punch rows in top-to-bottom order, joined with hyphens, e.g. '
              '"12-5-8". Rows are 12, 11, 0, and 1 to 9.',
        ),
        'bcd_octal': Schema.string(
          description: 'A BCD core-storage code in octal, 00 to 77.',
        ),
      },
      additionalProperties: false,
    ),
    annotations: ToolAnnotations(readOnlyHint: true),
    outputSchema: ObjectSchema(
      properties: {'query': Schema.object(additionalProperties: true)},
      required: ['query'],
      additionalProperties: true,
    ),
  );

  /// Verifies canon–mirror pairs.
  static final Tool checkTool = Tool(
    name: 'deck_check',
    description:
        'Verify deck files: every canon file must decode and round-trip, '
        'every canon file must have a fresh mirror, and every mirror must '
        'have a canon file. This is the check that "deckconv check" runs.',
    inputSchema: Schema.object(
      properties: {
        'paths': Schema.list(
          description:
              'Files or directories to check. A directory is searched.',
          items: Schema.string(),
        ),
      },
      required: ['paths'],
      additionalProperties: false,
    ),
    annotations: ToolAnnotations(readOnlyHint: true),
    outputSchema: ObjectSchema(
      properties: {
        'ok': Schema.bool(),
        'checked': Schema.int(),
        'failure_count': Schema.int(),
        'results': Schema.list(
          items: Schema.object(additionalProperties: true),
        ),
      },
      required: ['ok', 'checked', 'failure_count', 'results'],
    ),
  );

  Future<CallToolResult> _read(CallToolRequest request) => _guard(() async {
    final Map<String, Object?> args = request.arguments ?? const {};
    final String path = args['path']! as String;
    await _requireWithinRoots(path);
    return readDeck(
      path,
      includeCards: args['include_cards'] as bool? ?? false,
      startCard: args['start_card'] as int? ?? 1,
      maxCards: args['max_cards'] as int?,
    );
  });

  Future<CallToolResult> _write(CallToolRequest request) => _guard(() async {
    final Map<String, Object?> args = request.arguments ?? const {};
    final String path = args['path']! as String;
    await _requireWithinRoots(path);
    return writeDeck(
      path,
      args['mirror']! as String,
      expectedMirror: args['expected_mirror'] as String?,
    );
  });

  Future<CallToolResult> _editCards(CallToolRequest request) =>
      _guard(() async {
        final Map<String, Object?> args = request.arguments ?? const {};
        final String path = args['path']! as String;
        await _requireWithinRoots(path);
        return editDeckCards(
          path,
          startCard: args['start_card']! as int,
          deleteCount: args['delete_count'] as int? ?? 0,
          insertLines: (args['insert_lines'] as List<Object?>? ?? const [])
              .cast<String>(),
          expectedMirror: args['expected_mirror'] as String?,
        );
      });

  Future<CallToolResult> _card(CallToolRequest request) => _guard(() async {
    final Map<String, Object?> args = request.arguments ?? const {};
    final String path = args['path']! as String;
    await _requireWithinRoots(path);
    return readCard(path, args['card_index']! as int);
  });

  Future<CallToolResult> _code(CallToolRequest request) => _guard(() {
    final Map<String, Object?> args = request.arguments ?? const {};
    return describeCardCode(
      glyph: args['glyph'] as String?,
      cardCode: args['card_code'] as String?,
      bcdOctal: args['bcd_octal'] as String?,
    );
  });

  Future<CallToolResult> _check(CallToolRequest request) => _guard(() async {
    final Map<String, Object?> args = request.arguments ?? const {};
    final List<Object?> given = args['paths']! as List<Object?>;
    final List<String> paths = given.cast<String>();
    for (final String path in paths) {
      await _requireWithinRoots(path);
    }
    return checkDecks(paths);
  });

  // Rejects [path] when it resolves outside every root the client declared
  // (MCP-6). With no client-declared roots capability, or an empty root
  // list, the server's own working directory is the only allowed root.
  Future<void> _requireWithinRoots(String path) async {
    final String canonical = _canonicalPath(path);
    final List<String> allowed = await _allowedRoots();
    if (allowed.any((String root) => _isWithinRoot(root, canonical))) {
      return;
    }
    throw DeckToolException(
      'forbidden_path',
      '$path is outside the declared workspace root(s)',
    );
  }

  Future<List<String>> _allowedRoots() async {
    if (!supportsRoots) {
      return [_canonicalPath(Directory.current.path)];
    }
    final List<Root> currentRoots = await roots;
    if (currentRoots.isEmpty) {
      return [_canonicalPath(Directory.current.path)];
    }
    return [
      for (final Root root in currentRoots)
        _canonicalPath(Uri.parse(root.uri).toFilePath()),
    ];
  }
}

// The most cards any one deck_read call returns, regardless of max_cards
// (MCP-1). defaultMaxCards (25, from deck_tools.dart) is the default when
// max_cards is omitted; this is the schema ceiling on an explicit value.
const int _maxMaxCards = 100;

const JsonEncoder _json = JsonEncoder.withIndent('  ');

/// Runs [body] and reports its map, or the failure, as a tool result.
Future<CallToolResult> _guard(
  FutureOr<Map<String, Object?>> Function() body,
) async {
  try {
    final Map<String, Object?> result = await body();
    return CallToolResult(
      content: [Content.text(text: _json.convert(result))],
      structuredContent: result,
    );
  } on DeckToolException catch (e) {
    return _failure(e);
  } on FormatException catch (e) {
    return _failure(DeckToolException('format', e.message));
  } on FileSystemException catch (e) {
    return _failure(DeckToolException('io', '${e.message}: ${e.path}'));
  }
}

CallToolResult _failure(DeckToolException e) => CallToolResult(
  isError: true,
  content: [Content.text(text: _json.convert(e.toJson()))],
  structuredContent: e.toJson(),
);

// Resolves [path] to an absolute path with `.` and `..` segments collapsed,
// without requiring the path to exist (a deck_write target may not exist
// yet). Uri.normalizePath never climbs above the filesystem root, so `..`
// cannot escape further than the root even when [path] tries to.
String _canonicalPath(String path) =>
    Uri.file(File(path).absolute.path).normalizePath().toFilePath();

bool _isWithinRoot(String root, String path) {
  if (path == root) {
    return true;
  }
  final String prefix = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  return path.startsWith(prefix);
}
