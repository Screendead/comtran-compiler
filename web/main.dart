/// The website's browser entry point (roadmap W1, `docs/HANDOVER.md`).
///
/// `tool/build_web.dart` compiles this file to `web/main.dart.js`. It
/// crosses the JavaScript boundary and does nothing else: every decision
/// about what to compile and what to print lives in
/// `lib/src/web/web_compile.dart`, which `test/web_compile_test.dart` holds
/// to the same goldens the command-line compiler answers to.
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:comtran/src/version.dart';
import 'package:comtran/src/web/web_compile.dart';

/// Compiles the typed text and returns the [WebCompilation] as JSON. JSON
/// keeps the boundary to one string in and one string out.
@JS('comtranCompile')
external set _comtranCompile(JSFunction value);

/// Punches one line as one card and returns its rows as JSON, or `null`
/// when the line is not a card the punch could cut.
@JS('comtranPunch')
external set _comtranPunch(JSFunction value);

/// Cuts or fills one hole on a card and returns the card that results, so
/// the reader can punch by hand and watch the text follow.
@JS('comtranToggle')
external set _comtranToggle(JSFunction value);

/// The compiler version the page prints, so a reader can tell which build
/// produced the listing on the screen.
@JS('comtranVersion')
external set _comtranVersion(JSString value);

void main() {
  _comtranCompile = ((JSString typed) => jsonEncode(
    compileText(typed.toDart).toJson(),
  ).toJS).toJS;
  _comtranPunch = ((JSString typed) {
    final WebCard? card = punchCard(typed.toDart);
    return card == null ? null : jsonEncode(card.toJson()).toJS;
  }).toJS;
  _comtranToggle = ((JSString typed, JSNumber row, JSNumber column) {
    final WebCard? card = togglePunch(
      typed.toDart,
      row.toDartInt,
      column.toDartInt,
    );
    return card == null ? null : jsonEncode(card.toJson()).toJS;
  }).toJS;
  _comtranVersion = comtranVersion.toJS;
}
