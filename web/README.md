# The public website

This directory holds the W1 phase of the web track. `docs/HANDOVER.md`
holds the track; `docs/design/web-copy.md` holds the register the copy
obeys.

The page runs this repository's compiler in a browser and prints all six
stage dumps of whatever the reader types, with the compiler's own
diagnostics under the deck.

Above them it draws the card the caret sits on. That card is editable: a
click cuts or fills one hole, and the deck text becomes whatever the punch
now says. A hole combination no character matches puts that card into the
`!` punch form, which is the deck format's answer to exactly this case.

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
| `index.html` | The compiler page. Committed. |
| `reading-the-scans.html` | How a page scan becomes text. Static; it loads no compiler. Committed. |
| `styles.css`, `app.js` | Shared style, and the compiler page's behaviour. Committed. |
| `images/` | Scan crops used as evidence. Committed. |
| `main.dart` | The browser entry point. Committed. |
| `main.wasm`, `main.mjs`, `main.support.js`, `sample.js` | Build output. Not committed. |

### Where the crops came from

`images/` holds four crops copied from the chunk A4 review record, which is
orphan-committed on branch `review/2026-08-09-m4s2-chunk-a4`. That record's
`tools/crops.py` cut them from the page scans in `comtran-manuals/`.

They are copied rather than regenerated for two reasons. They are the exact
images the reviewer saw when the ruling was made, which is what makes them
evidence. And regenerating them would put Python and an imaging library into
the site build, which nothing else there needs.

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

## How it publishes

`.github/workflows/pages.yml` builds this directory and deploys it to GitHub
Pages, on a push to master and on demand. Nobody commits the build output.

The workflow runs `dart test` before it builds. The site claims it reproduces
the 1962 listing byte for byte, and the golden test is what proves that claim,
so nothing publishes without it.

## What holds this to the goldens

`test/web_compile_test.dart` compiles the sample program through the same
library the browser calls, and compares all six stages against the
committed goldens. It runs in the normal `dart test` gate.

The test runs on the Dart VM, so it proves the library and not the
WebAssembly build. To check the build itself, load the page and compare the
listing panel against `test/goldens/90.05-payroll.listing`.

## Not built yet

W1 does not yet include the deck download, the share link, or the
golden-diff panel.

W2 to W4 add the manual pages, the stage-by-stage walk, and the tutorial.
