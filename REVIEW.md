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
