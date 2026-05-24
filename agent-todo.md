# Agent TODO: TELNET Fuzzer Active Backlog

Purpose: track only active, incomplete fuzzer-improvement work for this MoonBit TELNET protocol library. Completed tasks, historical run notes, and closed reproduction details should not be kept in this file; they belong in git history, commit messages, tests, or docs.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Backlog policy

- Only active todo tasks should be placed in this file.
- Remove a task from this backlog once it is completed and committed.
- Keep entries concise, actionable, and independently reviewable.
- If a fuzz case exposes a bug, reduce it into a named regression test and keep any long-term follow-up here only if work remains.

## Latest completed slice

- Completed slice 20, regression backlog cleanup, on 2026-05-24.
- Audited fuzzer TODOs, skipped/xfail markers, deferred fuzz comments, and possible unused helper definitions in `telnet_fuzz_test.mbt`, `cmd/fuzz`, and `cmd/fuzz-native`.
- No unexplained skipped fuzz tests, known fuzz failures, dead experiments, or unused fuzz helpers were found; no production parser bug was exposed in this slice.
- Refined remaining helper-sharing follow-up to cover `cmd/fuzz-native` as well as `telnet_fuzz_test.mbt` and `cmd/fuzz`.
- Remaining follow-ups: continue with slice 21 (helper deduplication research) and slice 22 (native coverage-guided fuzzer validation/persistent or file-input modes).
- Reproduction seeds/details:
  - No new fuzz failure seed was discovered.
  - No generated reproduction wire was added.
  - Audit-only cleanup used no new randomized fuzz seed.
- Commands run:
  - `git status --short && printf '\n--- recent commits ---\n' && git log --oneline -8`
  - `git grep -n -Ei 'TODO|FIXME|HACK|skip(ped)?|xfail|expected failure' -- ':!agent-todo.md' ':!docs/wiki/api-contract.md' ':!docs/wiki/conformance-matrix.md' ':!docs/wiki/09-verification-corpus.md' || true`
  - `git grep -n -Ei 'fuzz.*(defer|limit|future|todo|skip|disabled)|fuzzer.*(defer|limit|future|todo|skip|disabled)' -- ':!agent-todo.md' ':!docs/wiki/10-fuzzing.md' || true`
  - `python3 - <<'PY' ... PY`: checked fuzz helper definitions in `telnet_fuzz_test.mbt`, `cmd/fuzz/main.mbt`, and `cmd/fuzz-native/main.mbt` for possible single-reference unused helpers.
  - `moon info && moon fmt`: passed.
  - `moon test`: passed with 876 tests.
  - `git status --short && printf '\n--- diff stat ---\n' && git diff --stat && printf '\n--- mbti diff ---\n' && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti && printf '\n--- whitespace ---\n' && git diff --check`: whitespace check failed because `moon info` regenerated blank EOF lines in generated `.mbti` files.
  - `python3 - <<'PY' ... PY && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti && git diff --check`: normalized generated `.mbti` EOF whitespace and passed whitespace check.
  - `moon info && moon fmt && moon test`: final verification passed with 876 tests after the todo update.
  - `git status --short && printf '\n--- diff stat ---\n' && git diff --stat && printf '\n--- mbti diff ---\n' && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti && printf '\n--- whitespace ---\n' && git diff --check`: final whitespace check again found regenerated blank EOF lines in generated `.mbti` files.
  - `python3 - <<'PY' ... PY && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti && git diff --check`: normalized generated `.mbti` EOF whitespace again and passed final whitespace check.

## Active work slices

### 21. Shared fuzzer helper research

- Investigate whether deterministic RNG, TELNET-biased input generation, observation normalization, and failure formatting can be shared between `telnet_fuzz_test.mbt`, `cmd/fuzz`, and `cmd/fuzz-native` without exposing test-only API from the public package.
- Inspection on 2026-05-24 confirmed intentional helper duplication across the fast tests and both runnable harnesses; document exactly which duplication should remain and why if package boundaries make sharing awkward.
- Preserve fast default tests and keep `cmd/fuzz` and `cmd/fuzz-native` runnable.

Acceptance criteria:

- Helper drift risk is reduced or explicitly documented.
- No public TELNET API is added solely for fuzz internals.

### 22. Native coverage-guided fuzzer validation

- Run the `cmd/fuzz-native` harness with an installed coverage-guided engine, preferably AFL++ via `CC=afl-clang-fast tools/build-fuzz-native.sh`, and record any required command refinements.
- If honggfuzz support is worthwhile, add a file-path input mode or checked wrapper rather than relying on undocumented shell redirection.
- Consider a persistent/in-process C shim only if it can stay isolated from the public TELNET API and normal tests.

Acceptance criteria:

- At least one coverage-guided engine command is validated end-to-end or blockers are documented.
- Any crash is reduced to a named deterministic regression test.
- Default `moon test` behavior remains fast and deterministic.

## Suggested recurring-agent loop

For each cron run:

1. Read this file and `AGENTS.md`.
2. Inspect repository state and recent changes.
3. Add or refine only active todo tasks when new meaningful fuzzer work is discovered.
4. Pick the highest-value incomplete slice that can be finished in one run.
5. Implement tests first when practical.
6. Fix discovered bugs or document limitations.
7. Run `moon info && moon fmt` and `moon test`.
8. Remove completed tasks from this file; keep only remaining active work.
9. Commit the completed work.
