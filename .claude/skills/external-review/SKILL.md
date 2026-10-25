---
name: external-review
description: Run the two-reviewer loop on a pull request — start a Fable and an Opus subagent at medium effort with the fixed REVIEW.md prompts, relay each review to the PR verbatim, adjudicate each round, and merge on convergence.
---

# The review loop

The charter is `EXTERNAL-REVIEW.md` at the repository root. This skill
is the procedure that runs it. Read the charter first. Where this file
and the charter disagree, the charter wins.

## Preconditions

1. The pull request needs the loop. Run
   `git diff --name-only master...HEAD`. The loop runs only when a path
   starts with `lib/` or `test/goldens/`, or is a `.target` file under
   `test/fixtures/`. Any other pull request is routine maintenance:
   report it to Jack and wait for his merge.
2. The pull request is open, the section 4 gate passed locally, and CI
   is green on the head.

## A round

1. Round 1: start two fresh subagents in one message, so that they run
   at the same time. Use the Agent tool with
   `subagent_type: "general-purpose"` and `run_in_background: true`.
   Give one `model: "fable"` and the other `model: "opus"`, and give
   both `effort: "medium"`. Never use `subagent_type: "fork"`: a fork
   inherits the author's context, and round 1 must be isolated.
2. Send the charter's fixed prompt and nothing else. Round 2 on:
   continue each subagent with SendMessage and the charter's re-review
   prompt.
3. Wait for the completion notifications. Do not poll.
4. If a reviewer ends without a VERDICT line, or asks a question, send
   the charter's one recovery prompt. The charter sets the failure
   limit.
5. Post one PR comment per review, with the review text exactly as the
   subagent returned it:

       ## Review — round <N> — <Fable|Opus> reviewer

       Head reviewed: `<sha>`.

       <the verbatim review>

## Adjudication

1. Adjudicate per charter rule 4: verify each finding empirically —
   probe programs, traces, measurements — then fix or refute.
2. Run the section 4 gate, push, and post one adjudication comment:
   `## Author adjudication — round <N>`, the per-finding record, and
   the new head.
3. Open the next round with the charter's re-review prompt to each
   reviewer.

## Convergence

The charter defines convergence, the failure limit, the escalation,
and the charter-amendment exception. On convergence for an ordinary
pull request: check CI, then merge with
`gh pr merge <N> --merge --delete-branch`. On convergence for a
charter-amendment pull request: report the recommendation to Jack and
wait.
