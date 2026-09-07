/// The whole package, including the three exported libraries that need
/// `dart:io`: `src/cards/deck_files.dart` reads and writes deck files,
/// `src/mcp/deck_server.dart` speaks MCP over stdio, and
/// `src/runtime/machine.dart` opens a tape file per unit.
///
/// The barrel splits because `web/main.dart` compiles to WebAssembly
/// (roadmap W1, `docs/HANDOVER.md`), and `dart:io` has no browser build.
/// `comtran.dart` holds everything that compiles for a browser. Import
/// this file instead wherever the program touches the file system.
library;

export 'comtran.dart';
export 'src/cards/deck_files.dart';
export 'src/mcp/deck_server.dart';
export 'src/runtime/machine.dart';
