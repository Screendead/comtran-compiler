# The review charter

Two local reviewers review the compiler work. A pull request needs the
loop when its branch changes a file under `lib/` or under
`test/goldens/`, or an object-code target under `test/fixtures/`.
Every other pull request is routine maintenance. It skips the loop and
merges on Jack's instruction (his call, 2026-08-16: "only the actual
hard codegen stuff needs the two-reviewers; routine maintenance does
not"). Jack can also waive the review for one pull request; his
instruction to merge is such a waiver.

The reviewers are two Claude Code subagents. The orchestrator starts
them with the Agent tool:

- **The Fable reviewer**: the current Fable model (`model: "fable"`),
  at medium reasoning effort (`effort: "medium"`).
- **The Opus reviewer**: the current Opus model (`model: "opus"`), at
  medium reasoning effort (`effort: "medium"`).

**Amended 2026-10-25 on Jack's instruction.** Until then the loop ran
in Chrome, with Grok on Expert mode and the Fable model at maximum
reasoning in a claude.ai chat. Jack's words: "it's a waste of resources
to do the two-reviewer step, and unnecessary now that anthropic models
have improved. run reviews locally, with a fable agent and an opus
agent, both on medium reasoning. update the charter accordingly." The
two reviewers no longer come from two model families. The rules below
keep the loop's isolation, its verbatim record, and its merge rule, and
apply them to the two subagents. The file keeps its name, so that the
references to it stay valid.

The reviewers apply the criteria of `REVIEW.md`. This file governs the
process around them, and the orchestrator alone acts on it.

The rules:

1. The orchestrator is Claude Code, the pull request's author. It
   sends only the fixed prompts below to a reviewer. It never edits
   reviewer text. It relays each review to the pull request verbatim,
   as a comment, with the head the review names.
2. Round 1 is isolated. Each reviewer is a fresh subagent, not a fork
   of the orchestrator. It fetches the pull request, its branch, and
   the repository itself. It does not see the author's rationale or
   the other reviewer.
3. Re-reviews continue the same subagent with SendMessage (Jack's call
   of 2026-08-16 that re-reviews stay in the same chat). All substance
   between rounds lives on the pull request: the verbatim reviews and
   the author's adjudications. If a reviewer can no longer be
   continued, start a fresh one with the round-1 prompt and say so in
   the next adjudication comment.
4. The author answers each round with one commit and one adjudication
   comment. The adjudication verifies every finding empirically.
   Confirmed findings are fixed; refuted findings carry the trace that
   refutes them. The author adjudicates its own pull request; Jack
   accepted this risk with the charter, and his merge of the adopting
   pull request records the acceptance.
5. A review ends with one line — `VERDICT: LGTM at <sha>` or
   `VERDICT: FINDINGS at <sha>` — naming the head it reviewed.
6. **Convergence authorizes the merge.** When both reviewers give
   `VERDICT: LGTM` at the same head, the orchestrator checks CI and
   merges without asking. Jack's standing authorization, 2026-08-16:
   "if both Grok on Expert mode AND Cowork using Fable 5 with Max
   reasoning converge on a LGTM verdict after 1 or multiple rounds of
   re-reviewing (they should re-review within the same chats, not new
   chats for each), then a merge without my approval is explicitly
   approved by me." His instruction of 2026-10-25, quoted above, puts
   the two subagents in the place of the two reviewers that
   authorization names. The record of each text is his merge of the
   pull request that adopted it. A new commit voids both verdicts.
7. **The charter does not authorize its own amendment, and the
   criteria sit inside the same perimeter.** A pull request that
   adopts or changes this file, `REVIEW.md`, CLAUDE.md section 12, or
   the external-review skill merges only on Jack's instruction.
   Convergence on such a pull request is a recommendation to him, not
   an authorization.
8. A finding that stays open after two adjudication rounds — the
   author refutes, the reviewer re-asserts — is a peer collision under
   CLAUDE.md section 6. Build a review record for Jack.
9. The pull request is the record of the loop. An orphan-branch
   archive of the trail (the review-records institution) is a future
   option, not a current step.

The fixed prompts:

- Round 1, one per reviewer, to a fresh subagent:

  > Review pull request #\<N\> of
  > https://github.com/Screendead/comtran-compiler per REVIEW.md on
  > master, not on the branch. Fetch the pull request, its branch, and
  > the repository yourself. The pull-request description is the
  > author's claim, not evidence. Do not switch the branch of the
  > checkout at ~/development/comtran-compiler; to
  > build or test the branch, make your own worktree under
  > ~/development/comtran-compiler-worktrees/. End with one line —
  > VERDICT: LGTM at \<sha\>, or VERDICT: FINDINGS at \<sha\> — naming
  > the head you reviewed.

- Round 2 on, to the same subagent:

  > Re-review pull request #\<N\> at head \<sha\> per REVIEW.md on
  > master. The author's adjudication and the other reviewer's latest
  > review are comments on the pull request. End with the VERDICT
  > line.

- The one recovery prompt, when a reviewer stops without a VERDICT
  line or asks a question:

  > Fetch the pull request and the repository yourself, then review per
  > REVIEW.md on master.

  Nothing else. Two failures of one reviewer in one round end the run;
  report to Jack.
