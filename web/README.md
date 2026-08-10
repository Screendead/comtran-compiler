# The public website

This directory holds the W1 phase of the web track. `docs/HANDOVER.md`
holds the track; `docs/design/web-copy.md` holds the register the copy
obeys.

The page does one thing: it runs this repository's compiler in a browser
and prints all six stage dumps of whatever the reader types.

## Build and run

From the repository root:

```sh
dart run tool/build_web.dart
python3 -m http.server 8000 --directory web
```

Then open `http://localhost:8000/`.

**A server is necessary.** The page loads a WebAssembly module, and a
browser refuses to fetch one from a `file://` URL. Any static server does.

## The files

| File | What it is |
|---|---|
| `index.html`, `styles.css`, `app.js` | The page. Committed. |
| `main.dart` | The browser entry point. Committed. |
| `main.wasm`, `main.mjs`, `main.support.js`, `sample.js` | Build output. Not committed. |

`app.js` holds no compiler knowledge. It sends the typed text to the
compiled compiler and prints what comes back, so a later milestone fills
these panels with no change to this directory.

## Why WebAssembly and not JavaScript

A Dart `int` compiled to JavaScript is a double, and its bitwise operators
truncate to 32 bits. A 7090 word is 36 bits. The JavaScript build therefore
drops the top four bits of every packed word without an error: the
semantics dump prints `006060606060` where the machine held
`606060606060`.

WebAssembly gives a true 64-bit `int`. Measured on 2026-08-10, it
reproduces all six goldens byte for byte, and it compiles the sample deck
faster than the JavaScript build did.

The same trap waits for any later browser work, the M4 emulator most of
all.

## What holds this to the goldens

`test/web_compile_test.dart` compiles the sample program through the same
library the browser calls, and compares all six stages against the
committed goldens. It runs in the normal `dart test` gate.

The test runs on the Dart VM, so it proves the library and not the
WebAssembly build. To check the build itself, load the page and compare the
listing panel against `test/goldens/90.05-payroll.listing`.

## Not built yet

W1 does not yet include the punched-card view, the deck download, the share
link, or the golden-diff panel. W2 to W4 add the manual pages, the
stage-by-stage walk, and the tutorial.
