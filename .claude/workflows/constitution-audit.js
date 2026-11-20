export const meta = {
  name: 'constitution-audit',
  description: 'Audit the COMTRAN compiler against CONSTITUTION.md: each owner brings one area into line and commits; nothing is only reported',
  whenToUse: 'Between waves, when no other worker edits the code: e.g. every few waves, or when the suite or the code has grown. Args: {base: "<branch or ref>", tag: "<short id, e.g. a1>"}.',
  phases: [{ title: 'Audit', detail: 'nine owners, one area each, fixing in their own worktree' }],
}
const base = (args && args.base) || 'origin/master'
const tag = (args && args.tag) || 'a1'
const REPO = '/Users/jacklusher/development/comtran-compiler'
const ROOT = '/Users/jacklusher/development/comtran-compiler-worktrees'
const common = (name) => `
You are a senior owner at the studio making the COMTRAN compiler, a Dart compiler for IBM's 1959-62 Commercial Translator, recovered from two IBM manuals. Read CONSTITUTION.md first. Then the code rule: comments state constraints the code cannot show, and nothing else; an abstraction exists only to remove a repeated idea; notes and analysis stay out of tracked files unless they are a document someone asked for.

Your piece: bring one area of the repository into line with the constitution and that rule. You fix what you find and commit it; nothing is only reported. You are not reviewing anyone: you own this area's fitness now.

Set up: run, with the Bash sandbox disabled, git -C ${REPO} worktree add -b audit/${name} ${ROOT}/${name} ${base}. Work only in ${ROOT}/${name}; run dart pub get there. Commit as you go (short imperative messages, no attribution, no model names); do not push. Other owners audit other areas at the same time: stay in yours.

Hard limits:
- Never read or search the sealed 1963 archive (CLAUDE.md section 9, D0.9).
- Do not edit CONSTITUTION.md, CLAUDE.md, REVIEW.md, EXTERNAL-REVIEW.md, docs/HANDOVER.md, docs/design/*.md, docs/comtran-language-definition.md, comtran-manuals/, test/goldens/, test/fixtures/, any *.ct or *.ctd deck, or a generated file of CLAUDE.md section 10.
- A comment that cites a manual (J 02.05.05, F p. 42), a page scan, a decision record (D4.1, M4-12, ED-3, LD-2) or an Open Question states a constraint: keep it. Cut only the prose around a citation that narrates or records history.
- CLAUDE.md section 11: never leave code that no test asserts on and no run reaches. Code that only a test reaches is permitted; leave it. If a change would make code in another owner's area dead, do not make it.

Behaviour must not change. Prove it with the project's own gate in your worktree: dart format --output=none --set-exit-if-changed lib bin test tool web; dart analyze --fatal-infos; and the tests named in your area. Pipe dart test through tail -40, never head, with a 300-second timeout, and check the output ends with "All tests passed!". The golden tests (test/listing_test.dart, test/emit_test.dart, test/acceptance_test.dart) compare the compiler's output byte for byte with the 1962 print: they are the eye's reading kept, so they never change and they must pass. Trash, never rm.

Hand-in: fill every field. summary is at most 150 words: what you removed or changed and why, what you judged should stay against first appearance and why.
`
const testOwner = (files) => `YOUR AREA: these test files: ${files}. The constitution: "The eye is the test." Time your files first: dart test -r json <files> and sum the test durations per file, then note the count and wall time. For each test decide: does it guard something the eye cannot see that would be costly to break unnoticed? In this compiler that is a page of the 1962 print, a language rule that cites the manual and that no sample program reaches (a refusal, a diagnostic, a character code, a severity), a guard for a generated file, the deck format or the import graph, or a crash. Keep those, made fast. Delete tests that only prove a piece was done, pin internal structure or numbers no manual gives, duplicate another test or what a golden already holds, or are stale; merge near-duplicates into one table-driven test where that removes a repeated idea; cut the cost of slow ones (one shared compile per file instead of one per test, a smaller deck) without losing what they guard. Do not delete the only test of code that no run reaches (section 11 would then ban that code). Helpers used only by deleted tests go too. Time your files again at the end; report count and seconds before and after.`
const codeOwner = (area) => `YOUR AREA: ${area}. Read every file. Remove comments that narrate, restate the code, record history ("was", "before", "now", "used to", "PR #", "chunk", "stage"), or hold analysis; keep and sharpen those stating a constraint the code cannot show. Remove dead code (unused functions, parameters, fields, constants, flags, branches no caller reaches: prove each with a search over lib, bin, tool, web and test), and abstractions that wrap one use. Leave formatting to dart format; do not rename for taste. Run the whole suite (dart test, about 25 seconds) at the end: the goldens are the proof your area still prints the same object program. Report lines removed (git diff --shortstat ${base}).`
const parts = {
  [`${tag}-tests-codegen`]: testOwner('test/codegen_test.dart, codegen_refusal_test.dart, codegen_diagnostics_test.dart, subscript_checks_test.dart, transfer_checks_test.dart, legality_test.dart, allocator_test.dart, capacities_test.dart'),
  [`${tag}-tests-front`]: testOwner('test/ data_lexer, environment_lexer, procedure_lexer, parser, control_parser, data_parser, environment_parser, expression_parser, procedure_parser, resolver, verb_binder, data_mapper, pictorial, reserved_words, storage_section, control_cards, job_splitter, source_program, severities, message_catalog, message_checklist, char_code, char_code_vectors, encode, text_codec, card_image, canon_codec, deck_conversion (each *_test.dart)'),
  [`${tag}-tests-run`]: testOwner('test/runtime/ (all, with runtime_support.dart), test/emulator/ (all, with asm.dart), and test/ emit, driver, listing, acceptance, f_acceptance, f_corpus, f_tapes, sample_tapes, loader, object_deck, smoke (each *_test.dart). runtime/machine_test.dart (9 s), emit_test.dart (6 s) and driver_test.dart (2 s) are most of the suite time: find what each compile or run is for and share it'),
  [`${tag}-tests-tools`]: testOwner('test/ deckconv, deckmcp, definition_mirror, manual_links, manual_map, decisions_index, doc_weight, layering, web_compile, web_copy, web_sources (each *_test.dart), and editors/vscode-punchcard/test (run with npm ci then node --test "test/**/*.test.js" in editors/vscode-punchcard). deckconv_test.dart takes 7 s: find what makes it slow (a process per test, a dart run per test) and cut it without losing what it guards'),
  [`${tag}-codegen`]: codeOwner('lib/src/codegen'),
  [`${tag}-data`]: codeOwner('lib/src/data'),
  [`${tag}-front`]: codeOwner('lib/src/ast, cards, chars, lexer (not message_catalog.dart, which is generated), parser, listing and driver, and bin/'),
  [`${tag}-run`]: codeOwner('lib/src/emit, emulator, loader, runtime, mcp, web and version.dart'),
  [`${tag}-tools`]: `YOUR AREA: tool/, web/ (only main.dart, app.js, sample.js and the HTML and CSS; never main.wasm, main.mjs, main.support.js or their maps, which the build writes), editors/vscode-punchcard/src and its README, and the documents that describe code: web/README.md and docs/design/README.md. Delete scripts nothing uses any more (search the repo, .github/workflows, the docs and the tests for callers). Apply the comment and dead-code rule to the Dart in tool/ and the TypeScript in the extension. Make the README files in your area match the code; cut what is wrong or stale where git holds the history. Prove it: the Dart gate above, dart test test/manual_map_test.dart test/definition_mirror_test.dart test/message_catalog_test.dart test/web_sources_test.dart test/web_compile_test.dart test/sample_tapes_test.dart test/f_tapes_test.dart, dart run tool/build_web.dart, and in editors/vscode-punchcard npm ci, npm run compile and node --test "test/**/*.test.js". Report lines removed (git diff --shortstat ${base}).`,
}
const picks = {
  // Opus: which test guards a manual rule the eye cannot see is judgement, and a plausible wrong deletion hides; medium: one bounded list each.
  [`${tag}-tests-codegen`]: ['opus', 'medium'],
  [`${tag}-tests-front`]: ['opus', 'medium'],
  [`${tag}-tests-run`]: ['opus', 'medium'],
  [`${tag}-tests-tools`]: ['opus', 'medium'],
  // Opus: codegen and data comments carry the manual evidence for each choice; telling a constraint from narration there is judgement no test checks; medium: one directory each.
  [`${tag}-codegen`]: ['opus', 'medium'],
  [`${tag}-data`]: ['opus', 'medium'],
  // Sonnet: front-end and runtime comments are mostly citations or plain narration, and the analyzer, a search and the goldens check the edits; medium: many files.
  [`${tag}-front`]: ['sonnet', 'medium'],
  [`${tag}-run`]: ['sonnet', 'medium'],
  // Sonnet: unused scripts and stale READMEs are found by searching and proved by the build; medium: broad but shallow.
  [`${tag}-tools`]: ['sonnet', 'medium'],
}
const HANDIN = {
  type: 'object',
  properties: {
    branch: { type: 'string' },
    commits: { type: 'array', items: { type: 'string' } },
    tests_before: { type: 'number' },
    tests_after: { type: 'number' },
    seconds_before: { type: 'number' },
    seconds_after: { type: 'number' },
    lines_added: { type: 'number' },
    lines_removed: { type: 'number' },
    gate_passed: { type: 'boolean' },
    summary: { type: 'string' },
  },
  required: ['branch', 'commits', 'lines_added', 'lines_removed', 'gate_passed', 'summary'],
}
phase('Audit')
const results = await parallel(Object.keys(parts).map(name => () =>
  agent(common(name) + parts[name], { label: name, phase: 'Audit', model: picks[name][0], effort: picks[name][1], schema: HANDIN })
    .then(r => ({ name, ...r }))))
return results.filter(Boolean)
