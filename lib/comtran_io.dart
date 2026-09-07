/// The whole package, including the three exported libraries that need
/// `dart:io`: `src/cards/deck_files.dart` reads and writes deck files,
/// `src/mcp/deck_server.dart` speaks MCP over stdio, and
/// `src/runtime/machine.dart` opens a tape file per unit.
///
/// The barrel splits because `web/main.dart` compiles to WebAssembly
/// (roadmap W1, `docs/HANDOVER.md`). A browser build of `dart:io`
/// compiles, and its file-system operations throw when they run, so a
/// browser bundle must not carry these three libraries. `comtran.dart`
/// holds everything a browser can run, and `test/web_compile_test.dart`
/// holds the guard. Import this file instead wherever the program touches
/// the file system.
library;

export 'comtran.dart';
export 'src/cards/deck_files.dart';
export 'src/mcp/deck_server.dart';
export 'src/runtime/machine.dart';
