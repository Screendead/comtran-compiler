---
name: review-records
description: Build a review record when a task needs Jack's eyes — a human-OCR request, or any question that ends a turn and waits for his answer. Produces a standalone HTML document with crops and evidence, then orphan-commits the directory.
---

# Review records

A **review record** is what this repository produces whenever work stops and
waits for Jack. It replaces a question typed into chat.

Build one for either trigger:

- **A human-OCR request.** A glyph, a column, or a mark that the ink does not
  settle, where a human eye is the last authority.
- **Any end-of-turn question that needs Jack's answer** before work continues:
  a peer collision under `CLAUDE.md` section 6, an authorization to change a
  read-only conversion, a choice between designs.

The record is not a summary written after the fact. It is the artifact that
carries the question, and then, after Jack answers, the artifact that carries
the answer. It exists because this project will be written up academically, and
a later reader needs the evidence and the reasoning, not a conclusion.

## The rules

1. **One directory per review**, at `reviews/YYYY-MM-DD-<slug>/`. The slug names
   the work, for example `2026-08-09-m4s2-chunk-a4`.
2. **`index.html` is standalone.** Full boilerplate — `<!DOCTYPE html>`,
   `<html lang="en">`, `<head>` with charset and viewport, `<body>`. Every image
   embedded as a `data:` URI, so the file renders from any location with no
   network and no server.
3. **Ship the materials beside it**: `crops/` for the images as separate files,
   `evidence/` for the primary sources the document draws on, `tools/` for the
   scripts that measured and built it. A `README.md` says what each holds.
4. **The process ends with Jack's response.** Add his rulings to `index.html` as
   a dated banner. Leave the per-item chips as they were: the record must show
   the question as well as the answer.
5. **Then orphan-commit the directory** and push the branch. It never enters the
   working tree of any other branch.
6. **The pull request references the orphan** by branch name, commit, and a
   `tree/` link.
7. **Jack's response settles the pull request too.** The answer that closes the
   questions is the authorization to open it, so the standing rule of section 12
   — ask before opening — is satisfied by the review cycle itself. Say in the
   description that you read it that way.

`/reviews/` is in `.gitignore`, so a record cannot ride into a topic branch by
accident.

## Writing it

Density and honesty rules from `CLAUDE.md` bind this document. Beyond them:

- **Open with the answer**, in a short numbered block. A reader who stops after
  it should still know what happened.
- **One section per item.** Each carries its own status: what it asks of Jack.
  Use three, and no more: `HUMAN OCR` for a reading only a human can settle,
  `YOUR CALL` for a judgment made that he can overturn, `SETTLED` for something
  recorded for the account and needing nothing.
- **Show the evidence before the argument.** The crop first, then the
  measurements, then the reading.
- **Show what would mislead.** Where a low magnification argues the other way,
  print that plate too, and say so. A record that only shows the persuasive view
  is not a record.
- **Give a recommendation on every item**, and give the alternative its fair
  statement. Where there are options, state each one's concrete consequence:
  what breaks, what is left unbuilt, what a later reader is misled about, and
  what it costs to reverse. That is the section 6 collision format, and it fits
  every review.
- **Never ask Jack to confirm something the evidence settles.** His attention is
  the scarcest input in this project.

## The house style

The document's visual identity is fixed, so records stay comparable across
years. `reviews/2026-08-09-m4s2-chunk-a4/tools/build_doc.py` on branch
`review/m4s2-a4` is the reference implementation; copy it and replace the
content.

| Token | Light | Dark | Role |
|---|---|---|---|
| `--paper` | `#F7F8F6` | `#141715` | The ground, a green-grey ledger stock |
| `--ink` | `#14171A` | `#E7EBE5` | Body text |
| `--muted` | `#5C6560` | `#9AA69D` | Captions and consequences |
| `--rule` | `#C9CFC8` | `#3A423C` | Dividers, the form rule of the listing |
| `--stamp` | `#B3261E` | `#FF7A6B` | The one accent. Anything needing Jack |
| `--settled` | `#40685A` | `#7FB8A2` | Resolved items and the rulings banner |

Typography: a Palatino or Iowan serif for reading, the system monospace for
every listing excerpt, measurement and label, and uppercase letter-spaced
monospace for the status chips. Numbers in tables take
`font-variant-numeric: tabular-nums`.

Define the light palette on bare `:root`, redefine the tokens under
`@media (prefers-color-scheme: dark)` guarded as
`:root:not([data-theme="light"])`, and again under `:root[data-theme="dark"]`.
Scan plates keep a white ground in both themes: the scans are black ink on white
paper, and inverting them lies about the artifact.

## Orphan-committing

Never use `git checkout --orphan`. It rewrites the working tree, and this
repository always has uncommitted work in flight. Build the commit with
plumbing, which touches neither the index nor the tree:

```sh
IDX=$(mktemp -u /tmp/orphan-idx.XXXXXX)
TREE=$(GIT_INDEX_FILE=$IDX sh -c 'git add -f reviews/<dir> && git write-tree')
COMMIT=$(git commit-tree "$TREE" -m "<slug> review record

<what it holds, and the date of Jack's rulings>")
git branch review/<slug> "$COMMIT"
rm -f "$IDX"
git push origin review/<slug>
rm -rf reviews/<dir>
```

Verify three things before you push: `git ls-tree -r --name-only` shows the
review directory and nothing else, `git log --format='%P' -1` shows no parent,
and `git status` is unchanged from before you started.

**The pushed branch is what makes the record permanent.** An unreferenced commit
is garbage-collected, on GitHub as well as locally. Never delete a `review/`
branch.
