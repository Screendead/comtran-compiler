---
name: external-review
description: Run the two-family external review loop on a pull request — invoke Grok and the Anthropic reviewer in Chrome with the fixed REVIEW.md lines, relay each review to the PR verbatim, adjudicate each round, and merge on convergence.
---

# External review

The charter is `EXTERNAL-REVIEW.md` at the repository root. This skill
is the procedure that runs it. Read the charter first. Where this file
and the charter disagree, the charter wins.

## Preconditions

1. The pull request is open, the section 4 gate passed locally, and CI
   is green on the head.
2. Chrome runs on this machine with logged-in sessions for grok.com and
   the Anthropic reviewer's surface. Start it with
   `open -a "Google Chrome"` if it is not running.
3. Load the Claude-in-Chrome tools in one ToolSearch batch.

## A round

1. Call `tabs_context_mcp` first. Round 1: create one fresh tab per
   reviewer. Round 2 on: reuse each reviewer's chat tab from round 1.
2. Configure before you send, and verify visually: Grok on Expert
   mode; the Anthropic reviewer on Fable 5 with maximum reasoning. A
   review on the wrong configuration is void.
3. Type the charter's fixed line. Type nothing else. Do not record the
   session. Make no GIF, and keep no image of a reviewer tab. A
   reviewer tab shows the titles of Jack's other chats. The audit trail
   is the verbatim review and its share URL on the pull request.
4. Wait. A review takes minutes. Poll the tab with `read_page` no more
   than once each minute.
5. If a reviewer stalls or asks a question, send the charter's one
   recovery line. The charter sets the failure limit.
6. Copy each finished review verbatim, and take the chat's share URL.
   Post one PR comment per review:

       ## External review — round <N> — <reviewer>

       Head reviewed: `<sha>`. Share URL: <url>.

       <the verbatim review>

## Adjudication

1. Adjudicate per charter rule 4: verify each finding empirically —
   probe programs, traces, measurements — then fix or refute.
2. Run the section 4 gate, push, and post one adjudication comment:
   `## Author adjudication — round <N>`, the per-finding record, and
   the new head.
3. Open the next round in the same chats with the charter's re-review
   line.

## Convergence

The charter defines convergence, the failure limit, the escalation,
and the charter-amendment exception. On convergence for an ordinary
pull request: check CI, then merge with
`gh pr merge <N> --merge --delete-branch`. On convergence for a
charter-amendment pull request: report the recommendation to Jack and
wait.
