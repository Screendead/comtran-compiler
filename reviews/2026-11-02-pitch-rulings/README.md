# 2026-11-02 pitch rulings (retrofit record)

No review record existed when these eleven questions were put. They were put
to Jack on the interactive pitch page
https://claude.ai/artifact/VF2SjodMseA7aQMekdqRqw on 2026-11-02, and he
answered there. This record was built afterwards to hold the questions and
the answers permanently.

| Path | What it holds |
|---|---|
| `index.html` | The record. Standalone; no images, no network. |
| `evidence/pitch-page.html` | The pitch page source, from local branch `archive/pitch-2026-11-02` at `48136be` (eleven calls). |
| `evidence/pitch-page-3dea94e.html` | The same page one commit earlier, with nine calls: the numbering the record uses. |
| `evidence/calls.json` | The page's `CALLS` literal, evaluated by `tools/extract_calls.js`. |
| `tools/extract_calls.js` | Extracts `calls.json` from the page source. |
| `tools/build_doc.py` | Writes `index.html`. |
| `tools/house.css` | The house style, copied from `review/2026-10-25-codegen-defects-8-11`. |

There are no crops: no manual page bears on these calls directly. The
records each call points to hold their own evidence.
