# The external-review charter

Two reviewers from two model families review every pull request from M4
stage 2 on. Jack can waive the review for one pull request; his
instruction to merge is such a waiver. He named the reviewers and their
configurations on 2026-08-16:

- **Grok**, on grok.com, Expert mode.
- **The Anthropic reviewer**, model Fable 5, maximum reasoning. Jack
  calls this reviewer Cowork. Any chat surface that carries this model
  and this effort satisfies the charter.

The reviewers apply the criteria of `REVIEW.md`. This file governs the
process around them, and the orchestrator alone acts on it.

The rules:

1. The orchestrator is Claude Code, the pull request's author. It
   types only the fixed lines below into a reviewer chat. It never
   edits reviewer text. It relays each review to the pull request
   verbatim, as a comment, with the chat's share URL and the head the
   review names.
2. Round 1 is isolated. Each reviewer starts a fresh chat and fetches
   the pull request, its branch, and the repository itself. It does
   not see the author's rationale or the other reviewer.
3. Re-reviews continue in the same chat (Jack's call, 2026-08-16). All
   substance between rounds lives on the pull request: the verbatim
   reviews and the author's adjudications.
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
   approved by me." The record of this authorization is his merge of
   the pull request that adopted this charter. A new commit voids both
   verdicts.
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

The fixed lines:

- Round 1, one per reviewer, in a fresh chat:

  > Review pull request #\<N\> of
  > https://github.com/Screendead/comtran-compiler per REVIEW.md on
  > master, not on the branch. Fetch the pull request, its branch, and
  > the repository yourself. The pull-request description is the
  > author's claim, not evidence. End with one line — VERDICT: LGTM at
  > \<sha\>, or VERDICT: FINDINGS at \<sha\> — naming the head you
  > reviewed.

- Round 2 on, in the same chat:

  > Re-review pull request #\<N\> at head \<sha\> per REVIEW.md on
  > master. The author's adjudication and the other reviewer's latest
  > review are comments on the pull request. End with the VERDICT
  > line.

- The one recovery line, when a reviewer stalls or asks a question:

  > Fetch the pull request and the repository yourself, then review per
  > REVIEW.md on master.

  Nothing else. Two failures in one chat end the run; report to Jack.
