import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';

import '../version.dart';
import 'deck_tools.dart';

/// The COMTRAN deck MCP server.
///
/// Gives an agent structured read and write access to card decks:
/// `deck_read`, `deck_write`, `deck_card`, `card_code_info`, and
/// `deck_check`. The formats are in `docs/design/deck-format.md`. Canon files
/// (`.ctdeck`) are authoritative; `deck_write` regenerates the sibling mirror
/// (`.deck`) on every write, so no tool ever hand-edits a mirror.

const String _instructions = '''
Read and write COMTRAN card decks at punch level.

A deck has two files. The canon file (.ctdeck) is a binary punch-level card
image and is authoritative. The mirror file (.deck) is generated text, one
line per card, committed for review and diffs.

Rules:
- Never hand-edit a .deck mirror. Write the deck with deck_write, which
  rewrites the canon file and regenerates the mirror together.
- Address every deck by its .ctdeck path.
- Mirror text must be in normal form: one line per card, LF endings, no
  trailing spaces, a final LF. A glyph line gives the Set H characters of the
  card. A card that punches anything else uses a punch line, "!" followed by
  "<column>:<rows>" fields in ascending column order, e.g. "! 1:12-5-8 72:9".
- deck_check reports the same freshness and round-trip verification that
  "dart run comtran:deckconv check" does.
''';

/// A stdio MCP server for COMTRAN card decks.
base class DeckMcpServer extends MCPServer with ToolsSupport {
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
        'fresh. Set include_cards for the per-card structured form.',
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
          description: 'How many cards the structured range holds.',
          minimum: 1,
        ),
      },
      required: ['path'],
    ),
  );

  /// Writes a canon deck and its mirror.
  static final Tool writeTool = Tool(
    name: 'deck_write',
    description:
        'Write mirror text to a COMTRAN canon deck (.ctdeck) and regenerate '
        'the sibling .deck mirror, so the pair stays fresh. The text must be '
        'in normal form; bad text is rejected and no file changes.',
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
      },
      required: ['path', 'mirror'],
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
    ),
  );

  CallToolResult _read(CallToolRequest request) => _guard(() {
    final Map<String, Object?> args = request.arguments!;
    return readDeck(
      args['path']! as String,
      includeCards: args['include_cards'] as bool? ?? false,
      startCard: args['start_card'] as int? ?? 1,
      maxCards: args['max_cards'] as int?,
    );
  });

  CallToolResult _write(CallToolRequest request) => _guard(() {
    final Map<String, Object?> args = request.arguments!;
    return writeDeck(args['path']! as String, args['mirror']! as String);
  });

  CallToolResult _card(CallToolRequest request) => _guard(() {
    final Map<String, Object?> args = request.arguments!;
    return readCard(args['path']! as String, args['card_index']! as int);
  });

  CallToolResult _code(CallToolRequest request) => _guard(() {
    final Map<String, Object?> args = request.arguments!;
    return describeCardCode(
      glyph: args['glyph'] as String?,
      cardCode: args['card_code'] as String?,
      bcdOctal: args['bcd_octal'] as String?,
    );
  });

  CallToolResult _check(CallToolRequest request) => _guard(() {
    final List<Object?> given = request.arguments!['paths']! as List<Object?>;
    final paths = <String>[];
    for (final Object? path in given) {
      if (path is! String) {
        throw const DeckToolException(
          'invalid_argument',
          'paths must hold strings',
        );
      }
      paths.add(path);
    }
    return checkDecks(paths);
  });
}

const JsonEncoder _json = JsonEncoder.withIndent('  ');

/// Runs [body] and reports its map, or the failure, as a tool result.
CallToolResult _guard(Map<String, Object?> Function() body) {
  try {
    final Map<String, Object?> result = body();
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
