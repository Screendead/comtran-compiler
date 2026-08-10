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

1. **One directory per review**, at `reviews/YYYY-MM-DD-<name>/`, where the name
   says what the work was: `reviews/2026-08-09-m4s2-chunk-a4/`. The date is the
   date of the evidence, not of the writing. **The branch is `review/` followed
   by that same directory name**, so `review/2026-08-09-m4s2-chunk-a4`. One name
   identifies the record everywhere.
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
- **Point every repository link at a commit, never a branch.** A topic branch is
  deleted when its pull request merges, and a `blob/<branch>/…` link 404s from
  that moment on. The record outlives the branch it was written beside.
- **Never ask Jack to confirm something the evidence settles.** His attention is
  the scarcest input in this project.

A record built after the fact carries a **provenance** block instead of a
rulings banner, and says plainly that no review document existed at the time and
where the decision was actually put to Jack. Never dress a retrofit as a review
that happened. Where such a record replaces an older branch, carry that branch's
README into it verbatim as `evidence/original-README.md`: deleting the old
branch destroys the only copy.

## The house style

The document's visual identity is fixed, so records stay comparable across
years. `tools/build_doc.py` on branch `review/2026-08-09-m4s2-chunk-a4` is the
reference implementation; copy it and replace the content.

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
COMMIT=$(git commit-tree -S "$TREE" -m "<dir> review record

<what it holds, and the date of Jack's rulings>")
git branch review/<dir> "$COMMIT"
rm -f "$IDX"
git push origin review/<dir>
rm -rf reviews/<dir>
```

`-S` is not optional. `commit.gpgsign` governs `git commit` only, so plumbing
produces an unsigned commit, and the ruleset below rejects it.

Verify four things before you push:

| Check | Expect |
|---|---|
| `git ls-tree -r --name-only review/<dir>` | the review directory and nothing else |
| `git log -1 --format='%P' review/<dir>` | empty: no parent |
| `git log -1 --format='%G?' review/<dir>` | anything but `N` |
| `git status` | unchanged from before you started |

**The pushed branch is what makes the record permanent.** An unreferenced commit
is garbage-collected, on GitHub as well as locally. Never delete a `review/`
branch.

## You get one push, and only one

The repository ruleset `review-lock` targets `refs/heads/review/**/*` and
restricts updates, deletions and force-pushes, and requires a signed commit. It
does not restrict creations. A `review/` branch is therefore free to create and
frozen from the moment it lands.

Two consequences bind the work:

- **Finish the record before you push it.** There is no amending a typo, a
  wrong number, or a missing file. Render `index.html` and read it first.
- **No one can repair a bad record**, Jack included: the ruleset lists no bypass
  actor. The only route is for him to edit the ruleset, which should stay a
  deliberate act. A record that turns out wrong is superseded by a new branch
  that says what it replaces, not rewritten.

If a second push to a `review/` branch ever succeeds, the lock is not doing its
job. Read `gh api repos/Screendead/comtran-compiler/rulesets` and check that
`review-lock` reports `"enforcement": "active"`.
