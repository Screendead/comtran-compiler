# Emulator reuse — review record, 2026-09-06

Jack asked, before M4 stage 4 begins, whether an existing battle-tested and
maintained 7090 emulator could replace the work and the maintenance of our own.
This record answers that, and reports what the search found instead.

`index.html` is the document. It is standalone and needs no server.

## What is here

| Path | What it holds |
|---|---|
| `index.html` | The record. Four items: three need Jack, one is settled. |
| `tools/build_doc.py` | Builds `index.html`. Run it from anywhere. |
| `evidence/candidate-profiles.md` | Ten candidate profiles, unedited agent text |
| `evidence/embedding-cost.md` | What replacing `lib/src/emulator/` would cost, measured against this repository |
| `evidence/oracle-option.md` | The differential-oracle option assessed on its own |
| `evidence/adversarial-review.md` | Two reviewers attacking the conclusion |
| `evidence/verification-notes.md` | My own checks, including the two claims that did not survive |
| `evidence/ct-tape-find.md` | The Commercial Translator excerpts, pulled from the tarball directly |
| `evidence/survey-raw.json` | The whole survey return value |

## The four items

1. **Adopt someone else's 7090?** No. Keep ours — but not for the reasons given
   mid-search. `YOUR CALL`
2. **The 1963 Commercial Translator survives** on a recovered IBSYS tape, with
   its object-time subroutine library assembled and listed. `YOUR CALL`
3. **Where a differential harness would live**, if we build one. `YOUR CALL`
4. **Two corrections and one observation.** `SETTLED`

Nothing is committed and nothing is blocked. Stage 4 can start on the current
plan.

## Provenance note

The tarball holding the Commercial Translator is not redistributed here.
`evidence/ct-tape-find.md` quotes only the passages the record argues from, and
names the source URL and the byte count so the find is reproducible.
