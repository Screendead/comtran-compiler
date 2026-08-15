# Review criteria

Rules for every code review of this repository. A real defect outranks a
style point.

## Severity

- **Blocker:** a real defect. Examples: wrong behavior, a broken
  invariant, a test that cannot fail, code that is neither exercised nor
  tested (CLAUDE.md section 11), a diff that touches `comtran-manuals/`
  without a quoted authorization from Jack, a hand edit to a generated
  file (CLAUDE.md section 10), a hand edit to a `.ct` mirror.
- **Advisory:** a humanness finding from the list below, a style point, a
  nit. Cap nits at five per review; keep the most useful ones.

Every finding must cite `file:line` and quote the text it concerns. Drop
a finding that cannot.

## Humanness

A humanness finding marks code or prose that reads as machine output, not
as the work of a careful person. Flag these seven. They are advisory, not
blocking.

1. A ghost abstraction: a helper, class, or layer with one caller and no
   likely second caller.
2. A comment or doc comment that restates the symbol's name or the next
   line.
3. Dead weight that the section 11 blocker does not already catch: code a
   test asserts on but no run reaches, or commented-out code.
4. Repeated ceremony: the same multi-line pattern at many sites that one
   local helper would remove.
5. Document weight: a markdown file larger than its audience or its
   purpose needs.
6. Test slop: duplicate coverage, a test that asserts the mock, setup
   that restates the implementation.
7. Idiom mismatch: code whose naming, comment density, or shape does not
   match the file around it.

## Repository specifics

- `comtran-manuals/` is read-only. The page scan is ground truth; a
  conversion is a transcription of it. Never settle a disputed reading or
  a column claim from a transcription — measure the scan. Any change
  under `comtran-manuals/` is a blocker unless the pull request quotes
  Jack's authorization.
- Never ask for a fix to 1960s spelling or to a genuine typo in manual
  text. Fidelity is by design.
- A `.ct` file is the generated mirror of its `.ctd` canon. A diff
  that edits one without the other is a blocker.
- The golden listing, `test/goldens/90.05-payroll.listing`, is the
  acceptance oracle of the front end. A change to it needs an explanation
  in the pull request.
- Cite the manuals as `J 02.03.02` (an IBM section code) or `F p. 42` (a
  printed page). J28-6169 outranks F28-8043 where they diverge.
- Repository prose follows ASD-STE100 Simplified Technical English
  (CLAUDE.md section 13). Verbatim manual quotes are exempt.

## External review

Two reviewers from two model families review every pull request from M4
stage 2 on. Jack named the reviewers and their configurations on
2026-08-16:

- **Grok**, on grok.com, Expert mode.
- **The Anthropic reviewer**, model Fable 5, maximum reasoning. Jack
  calls this reviewer Cowork; the chat surface that carries this model
  and effort is the one that counts.

The rules:

1. The orchestrator — Claude Code, the pull request's author — types
   only the fixed lines below into a reviewer chat, and never edits
   reviewer text. It relays each review to the pull request verbatim,
   as a comment, with the chat's share URL and the head it reviewed.
2. Round 1 is blind. Each reviewer starts a fresh chat and fetches the
   pull request, its branch, and the repository itself. It does not
   see the author's rationale or the other reviewer.
3. Re-reviews continue in the same chat (Jack's call, 2026-08-16). All
   substance between rounds lives on the pull request: the verbatim
   reviews and the author's adjudications.
4. The author answers each round with one commit and one adjudication
   comment. The adjudication verifies every finding empirically.
   Confirmed findings are fixed; refuted findings carry the trace that
   refutes them.
5. A review ends with one line — `VERDICT: LGTM at <sha>` or
   `VERDICT: FINDINGS at <sha>` — naming the head it reviewed.
6. **Convergence authorizes the merge.** When both reviewers give
   `VERDICT: LGTM` at the same head, the orchestrator checks CI and
   merges without asking. Jack's standing authorization, 2026-08-16:
   "if both Grok on Expert mode AND Cowork using Fable 5 with Max
   reasoning converge on a LGTM verdict after 1 or multiple rounds of
   re-reviewing \[…\] then a merge without my approval is explicitly
   approved by me." A new commit voids both verdicts.
7. A finding that stays open after two adjudication rounds — the
   author refutes, the reviewer re-asserts — is a peer collision under
   CLAUDE.md section 6. Build a review record for Jack.
8. The pull request is the record of the loop. An orphan-branch
   archive of the trail (the review-records institution) is a future
   option, not a current step.

The fixed lines:

- Round 1, one per reviewer, in a fresh chat:

  > Review pull request #\<N\> of
  > https://github.com/Screendead/comtran-compiler per REVIEW.md at the
  > repository root. Fetch the pull request, its branch, and the
  > repository yourself. The pull-request description is the author's
  > claim, not evidence. End with one line — VERDICT: LGTM at \<sha\>,
  > or VERDICT: FINDINGS at \<sha\> — naming the head you reviewed.

- Round 2 on, in the same chat:

  > Re-review pull request #\<N\> at head \<sha\> per REVIEW.md. The
  > author's adjudication and the other reviewer's latest review are
  > comments on the pull request. End with the VERDICT line.

- The one recovery line, when a reviewer stalls or asks a question:

  > Fetch the pull request and the repository yourself, then review per
  > REVIEW.md.

  Nothing else. Two failures in one chat end the run; report to Jack.
