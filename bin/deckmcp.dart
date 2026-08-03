/// Deck MCP server — the T3 tool of `docs/HANDOVER.md`.
///
/// Serves structured read and write access to COMTRAN card decks over stdio,
/// with the Model Context Protocol. Register it with:
///
///     claude mcp add comtran-decks -- dart run comtran:deckmcp
///
/// Formats: `docs/design/deck-format.md`; authority rules: D0.5. The server
/// writes JSON-RPC to standard output only, so it must print nothing else.
library;

import 'package:comtran/comtran.dart';

void main() {
  DeckMcpServer.overStdio();
}
